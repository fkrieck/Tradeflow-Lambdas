import sys
sys.path.append('/opt')
import json
import boto3
from botocore.exceptions import ClientError
import awswrangler as wr
import pyodbc
from datetime import datetime
from uuid import uuid4
import os
import logging
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from typing import Union, Iterable

### LAYERS - PYTHON 3.12
#arn:aws:lambda:eu-west-1:336392948345:layer:AWSSDKPandas-Python312:20
#arn:aws:lambda:eu-west-1:770693421928:layer:Klayers-p312-numpy:11
#arn:aws:lambda:eu-west-1:770693421928:layer:Klayers-p312-SQLAlchemy:7
#
# ATENÇÃO - pyodbc NÃO está disponível no KLayers (requer unixODBC + ODBC Driver 18 nativos).
# É necessário um layer customizado contendo:
#   - unixODBC (biblioteca do sistema)
#   - Microsoft ODBC Driver 18 for SQL Server (msodbcsql18)
#   - pyodbc (wheel compilado contra o unixODBC do layer)
# Referência: https://github.com/keithrozario/Klayers (pyodbc não publicado)
# Tutorial custom layer: https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

import json
from typing import Union, Iterable

def build_insert_from_json_line(
    record: Union[str, dict],
    table_placeholder: str = os.environ["DB_NAME"],
    null_tokens: Iterable[str] = ("<NA>", "")
) -> str:
    """
    Gera um comando SQL INSERT INTO #env.TABLE_NAME# (cols) VALUES (vals)
    a partir de um JSON (string ou dict).
    
    - Converte tokens nulos para NULL (por padrão: "<NA>", "" e None).
    - Faz escape de aspas simples em textos e usa N'...' (Unicode) para SQL Server.
    - Detecta números (int/float) para emitir sem aspas.
    - Mantém a ordem dos campos conforme o JSON de entrada.

    Parâmetros:
        record: linha JSON (str no formato JSON ou dict já carregado)
        table_placeholder: placeholder do nome da tabela (default: "#env.TABLE_NAME#")
        null_tokens: valores string considerados nulos → NULL no SQL

    Retorna:
        str: comando SQL completo de INSERT.
    """
    # Aceita string JSON ou dict
    if isinstance(record, str):
        record = json.loads(record)

    if not isinstance(record, dict) or not record:
        raise ValueError("record deve ser um JSON válido (string) ou dict não vazio.")

    # Conjunto para busca O(1) nos tokens nulos
    null_tokens = set(null_tokens)

    def _is_numeric_str(s: str) -> bool:
        """True se s pode ser float, sem espaços. Não força conversão de formatos especiais."""
        if not isinstance(s, str):
            return False
        s = s.strip()
        if s == "":
            return False
        try:
            float(s)
            return True
        except Exception:
            return False

    columns_sql = []
    values_sql = []

    for key, value in record.items():
        # Colunas delimitadas por [] (SQL Server) para evitar problemas com nomes reservados
        columns_sql.append(f"[{key}]")

        # NULL handling
        if value is None or (isinstance(value, str) and value in null_tokens):
            values_sql.append("NULL")
            continue

        # Tipagem/formatos
        if isinstance(value, (int, float)):
            # numérico nativo
            values_sql.append(str(value))
        elif isinstance(value, str) and _is_numeric_str(value):
            # numérico vindo como texto → emite sem aspas
            values_sql.append(value.strip())
        else:
            # texto: escape de aspas simples + N'...' para NVARCHAR
            sanitized = str(value).replace("'", "''")
            values_sql.append(f"N'{sanitized}'")

    columns_part = ", ".join(columns_sql)
    values_part = ", ".join(values_sql)

    sql = f"INSERT INTO {table_placeholder} ({columns_part}) VALUES ({values_part});"
    return sql

# --- Detecta dinamicamente o diretório logo após o prefixo e aplica '-loaded' ---
def to_loaded_key(key: str) -> str:
    """
    Converte 'PREFIXO/<dir>/<arquivo>' para 'PREFIXO/<dir>-loaded/<arquivo>'.
    Ex.: 'DPASS/dsd_sales/dsd_sgode1_pq.parquet' -> 'DPASS/dsd_sales-loaded/dsd_sgode1_pq.parquet'
    """
    # Normaliza barras duplicadas e remove espaços acidentais
    k = key.strip()
    while '//' in k:
        k = k.replace('//', '/')

    parts = k.split('/')
    if len(parts) < 2:
        # Sem diretório para alterar; retorna original
        return k

    prefix = parts[0]         # ex.: 'DPASS'
    dir_name = parts[1]       # ex.: 'dsd_sales'

    # Evita duplicar '-loaded'
    if dir_name.endswith('-loaded'):
        return k

    needle = f'/{dir_name}/'
    replacement = f'/{dir_name}-loaded/'

    # Troca somente a primeira ocorrência para preservar o prefixo
    return k.replace(needle, replacement, 1)

# Obter dados para conexão da Base de dados (RDS)
def get_secret(secret_name, region_name):

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
 
    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
    else:
        # Decrypts secret using the associated KMS key.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])

    return json.loads(secret)


# Variáveis para Conexão com o Bnco de Dados do CIP
secrets = get_secret(os.environ["SECRET_NAME"], os.environ['AWS_REGION'])
server = secrets["host"]
user = secrets["username"]
password = secrets["password"]
database = os.environ["DB_NAME"]  # Nome do Banco "Ex: CIPBR"
port = secrets["port"]


def create_database_connection() -> Engine:
    connection_string = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server},{port};"
        f"DATABASE={database};"
        f"UID={user};"
        f"PWD={password};"
        "TrustServerCertificate=yes;"
    )
    connection_url = f"mssql+pyodbc:///?odbc_connect={connection_string}"

    return create_engine(connection_url, fast_executemany=True)

def insert_into_database(
    df: pd.DataFrame,
    table: str,
    if_exists='append',
    engine_func=create_database_connection
):

    # Converte todos os valores para string (sua tabela é quase toda NVARCHAR)
    df = df.astype(str)

    # ===============================
    # 1) Normaliza TODAS as colunas que contenham "date" no nome
    # ===============================
    date_cols = [c for c in df.columns if "date" in c.lower()]
    for c in date_cols:
        df[c] = pd.to_datetime(df[c], errors="coerce")\
                     .dt.strftime("%Y-%m-%d %H:%M:%S")

    LOGGER.info(f'SQL Database - Data inserted into "{table}"')
    
    if not df.empty:
        jsonline = df.iloc[0].to_json()
        LOGGER.info(f"total de linhas '{table}': {len(df)}")
        LOGGER.info(f"Sample row being inserted into '{table}': {jsonline}")
        insert = build_insert_from_json_line(jsonline)
        LOGGER.info(f"Sample insert into DB: {insert}")

    engine = engine_func()
    LOGGER.info(f"Iniciando carga de dados. {len(df)} registros")
    try:
        # 1) Transação explícita
        with engine.begin() as conn:
            # 2) Envie a conexão ativa para o pandas (evita que o pandas crie outra transação por trás)

            # for i in range(0, len(df), 750):
            #     chunk = df.iloc[i:i+750]
            #     chunk.to_sql(
            #         name=table,
            #         con=conn,
            #         if_exists=if_exists,
            #         index=False,
            #         method='multi'      # envia batch de INSERTs
            #     )
                # chunk.to_sql(con=conn, if_exists="append", method="multi", index=False)

            df.to_sql(
                name=table,
                con=conn,
                if_exists=if_exists,
                index=False,
                chunksize=100,   
                method='multi'      # envia batch de INSERTs
            )
        LOGGER.info(f'SQL Database - Data inserted into "{table}"')
    except Exception as ex:
        LOGGER.exception('SQL Database - Failed to insert data into the database')
        raise
    finally:
        engine.dispose()

# def insert_into_database(df: pd.DataFrame, table: str, if_exists='append', engine_func=create_database_connection):
#     LOGGER.info(f'SQL Database - Inserting data into "{table}"')
#     engine = engine_func()

#     try:
#         df.to_sql(table, engine, if_exists=if_exists, index=False)
#         LOGGER.info(f'SQL Database - Data inserted into "{table}"')

#     except Exception as ex:
#         LOGGER.error(f'SQL Database - Failed to insert data into the database {ex}')
#         raise ex
#     finally:
#         engine.dispose()


def get_dataframe_from_database(query: str) -> pd.DataFrame:
    engine = create_database_connection()

    try:
        return pd.read_sql(query, engine)
    except Exception as ex:
        LOGGER.error(f'Failed to get data from the database {ex}')
        raise ex
    finally:
        engine.dispose()



def execute_query(query: str, engine_func=create_database_connection) -> None:
    engine = engine_func()
    try:
        # Abre transação e commita automaticamente ao sair do bloco
        with engine.begin() as conn:
            conn.execute(text(query))
    except Exception as ex:
        LOGGER.error(f"Failed to execute query {query}: {ex}", exc_info=True)
        raise
    finally:
        # Fecha o pool e libera recursos
        engine.dispose()

# Manipulador da Função Lambda - ESTA FUNÇÃO DEVE SER CONFIGURADA na sessão - "Runtime settings - Handler"
def lambda_handler(event, context):
    LOGGER.info(f'Parquet Files: {path_parquet_name} - Lambda started')
    MainFunction(event)

    return {
        'statusCode': 200,
        'body': json.dumps(f'Parquet Files: {path_parquet_name} loaded sucessfull!')

    }

# Delete informações na Base de dados
def delete_data():
    execute_query(f"""EXEC SPDEL_LAMBDA_EVENTS '{eventid}','{table_name}'""")
    # cur = create_cursor()
    # scr_delete = f"""EXEC SPDEL_LAMBDA_EVENTS '{eventid}','{table_name}'"""
    # cur.execute(scr_delete)
    # cur.close()


# Inserir informações na Base de dados
'''
def insert_data(row, eventfile):
    cur = create_cursor()
    scr_insert = f"""EXEC {procedure_ins_s0_dlk} '{eventdate}','{eventid}','{eventfile}','{row.creation_date}','{row.billing_date}','{row.billing_document_number}',
                                 '{row.billing_item}','{row.invoice_number}','{row.material_code}','{row.isms_po_number.replace("'", "")}','{row.customer_order_number.replace("'", "")}','{row.billed_quantity}',
                                 '{row.unit_of_measure}','{row.price}','{row.key_transaction_type_fact}','{row.posting_date}','row.posting_date.1','{row.customer_code}',
                                 '{row.customer_id}','{row.special_date}','{row.new_quantity}','{row.new_price}','{row.qty_cigarettes}','{row.qty_sinergy}',
                                 '{row.qty_return_of_delivered_free_goods}','{row.qty_return_of_delivered_sales}','{row.qty_volume_reversal_free_goods}','{row.qty_volume_reversal_logd}',
                                 '{row.qty_volume_reversal_sales}','{row.qty_return_of_not_delivered_free_goods}','{row.qty_return_of_not_delivered_sales}',
                                 '{row.qty_sold}','{row.qty_logd}','{row.qty_free_goods}','{row.qty_sold_net}','{row.qty_free_goods_net}','{row.qty_logd_net}',
                                 '{row.qty_sold_net_with_fg_and_logd}','{row.qty_sold_with_free_goods}','{row.qty_return_of_not_delivered}','{row.qty_cigarettes_net_sales_with_free_goods}',
                                 '{row.qty_cigarettes_net_sales}','{row.qty_sinergy_net_sales_with_free_goods}','{row.qty_sinergy_net_sales}',
                                 '{row.qty_sinergy_free_goods}','{row.qty_cigarettes_free_goods}','{row.qty_sinergy_logd}','{row.qty_cigarettes_logd}',
                                 '{row.qty_sinergy_return_of_not_delivered}','{row.qty_cigarettes_return_of_not_delivered}','{row.qty_sinergy_net_with_fg_and_logd}',
                                 '{row.qty_cigarettes_net_with_fg_and_logd}','{row.sales_daily_sales_type}','{row.sales_details_returned_good_reason}',
                                 '{row.sales_other_sales_reason}'"""
    cur.execute(scr_insert)
    cur.close()
'''


# Identificador e data do Evento
eventid = str(uuid4())
eventdate = datetime.now().strftime('%Y%m%d %H:%M:%S')

# Objetos manipuladores de arquivos no S3
s3_cli = boto3.client('s3')
s3 = boto3.resource('s3')

# Variáveis para Conexão com o Bnco de Dados do CIP
'''
secrets = get_secret(os.environ["SECRET_NAME"], os.environ['AWS_REGION'] )
rds_endpoint  = secrets["host"]
username = secrets["username"]
password = secrets["password"]
db_name = os.environ["DB_NAME"] # Nome do Banco "Ex: CIPBR"
port = secrets["port"]
'''
conn = None

# Variáveis de ambiente
table_name = os.environ['TABLE_NAME'] # Nome da tabela no RDS "Ex: S0_DLK_masterfile"
path_parquet_name = os.environ['PATH_PARQUET_NAME']  # Nome da pasta com arquivos parquets "masterfile"
lambda_Name = os.environ['AWS_LAMBDA_FUNCTION_NAME']  # Nome da função para efeitos de Log "Ex: cippmbr-load-masterfile"
procedure_ins_s0_dlk = os.environ['PROCEDURE_INS_S0_DLK']  # Nome da procedure de insersão da tabela se Stage S0_DLK na Base de dados "Ex: SPINS_S0_DLK_Masterfile"


# Função principal
def MainFunction(event):
    bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    s3_file_name = event["Records"][0]["s3"]["object"]["key"]
    path_name = f"{bucket_name}/{s3_file_name}"
    s3_uri = f"s3://{bucket_name}/{s3_file_name}"
    LOGGER.info(f"path_name:{path_name}")
    s3_save_uri = to_loaded_key(s3_file_name)
    LOGGER.info(f"s3_save_uri:{s3_save_uri}")

    try:
        execute_query(f"""Exec SPINSUPD_LambdasRunning '{lambda_Name}','{path_name}','{eventid}', 1""")
        # cur = create_cursor()
        # cur.execute(f"""Exec SPINSUPD_LambdasRunning '{lambda_Name}','{path_name}','{eventid}', 1""")
        # cur.close()
    except Exception as ex:
        LOGGER.error("ERROR: Unexpected error: update status in LambdasRunning")
        LOGGER.error(ex)
        pass

    LOGGER.info(f'Iniciando abertura: {s3_uri}')
    # Ler o arquivo parquet
    # df = wr.s3.read_parquet(path=[f"s3://{path_name}"])
    df = wr.s3.read_parquet(path=s3_uri)
    LOGGER.info(f'Criando df_copy')
    df_copy = df.copy()
    df_copy['eventdate'] = eventdate
    df_copy['eventid'] = eventid
    df_copy['eventfile'] = s3_file_name
    df_copy['posting_date_1'] = ""  # df_copy['posting_date.1']
    '''
    df_copy.pop('posting_date.1')
    '''
    # Inserir do Dataframe (df) na base de dados
    try:
        insert_into_database(df_copy, table_name)
        # insert_data(row, s3_file_name)
    except Exception as e:
        try:
            delete_data()
        except Exception as ex:
            LOGGER.error(f"ERROR: Unexpected error: Unable DELETE event '{eventid}' from table '{table_name}' into RDS MSSql instance.")
            LOGGER.error(ex)
        LOGGER.error("ERROR: Unexpected error: Could not INSERT into RDS MSSql instance.")
        LOGGER.error(e)
        try:
            execute_query(f"""Exec SPINSUPD_LambdasRunning '{lambda_Name}','{path_name}','{eventid}', 3""")
            # cur = create_cursor()
            # cur.execute(f"""Exec SPINSUPD_LambdasRunning '{lambda_Name}','{path_name}','{eventid}', 3""")
            # cur.close()
        except Exception as ex:
            LOGGER.error("ERROR: Unexpected error: update status in LambdasRunning")
            LOGGER.error(ex)
            pass
        sys.exit(1)

    #### TRANSFERE ARQUIVO PARA A PASTA _LOADED
    LOGGER.info(f"Copying and Deleting the parquet files: {path_parquet_name}  from s3 bucket: {bucket_name}")
    try:

        file = s3_file_name
        # output = file.split(f'{path_parquet_name}/')
        # newfile = f'{path_parquet_name}-loaded/' + output[1]
        newfile = s3_save_uri

        LOGGER.info(f'FINAL FILE: {newfile}')

        # savefile2 = to_loaded_key(file_key)

        # LOGGER.info(f'NEW FINAL FILE: {savefile2}')

        copy_source = {
            'Bucket': f'{bucket_name}',
            'Key': f'{file}'
        }
        try:
            s3.meta.client.copy(copy_source, f'{bucket_name}', f'{newfile}')
        except Exception as e:
            LOGGER.error(f"ERROR: Unexpected error: Could not Copy the parquet {path_parquet_name}  do s3 bucket: {bucket_name}.")
            LOGGER.error(e)
        else:
            s3.Object(f'{bucket_name}', f'{file}').delete()
            LOGGER.info(f'deleted: {file}')
    #### FIM TRANSFERENCIA ARQUIVO PARA _LOADED

    except Exception as e:
        LOGGER.error(f"ERROR: Unexpected error: Could not Delete the parquet {path_parquet_name}  do s3 bucket: {bucket_name}.")
        LOGGER.errorinfo(e)

    try:
        execute_query(f"""Exec SPINSUPD_LambdasRunning '{lambda_Name}','{path_name}','{eventid}', 4""")
        # cur = create_cursor()
        # cur.execute(f"""Exec SPINSUPD_LambdasRunning '{lambda_Name}','{path_name}','{eventid}', 4""")
        # cur.close()
    except Exception as ex:
        LOGGER.error("ERROR: Unexpected error: update status in LambdasRunning")
        LOGGER.error(ex)
        pass
