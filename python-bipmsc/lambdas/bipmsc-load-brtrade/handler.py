import json
import os
import sys
sys.path.append('/opt')
import pymssql
import boto3
from botocore.exceptions import ClientError
import csv

server = os.environ['db_server']
user = os.environ['db_user']
password = os.environ['db_password']
database = os.environ['db_database']
port = os.environ['db_port']
 
conn = pymssql.connect(
    server=server,
    user=user,
    password=password,
    database=database,
    as_dict=True
)

def ajustar_array(array_original, tamanho = 30, preenchimento = None):
    if len(array_original) < tamanho:
        array_original = list(array_original) + [preenchimento] * (tamanho - len(array_original))
    elif len(array_original) > tamanho:
        array_original = array_original[:tamanho]
    return array_original


def ajustar_tamanho_linhas(data, tamanho=46, preenchimento=None):
    dados_ajustados = []
    for linha in data:
        if len(linha) < tamanho:
            linha = list(linha) + [preenchimento] * (tamanho - len(linha))
        elif len(linha) > tamanho:
            linha = linha[:tamanho]
        dados_ajustados.append(tuple(linha))
    return dados_ajustados


def execute_insert_trade(data:str):
    # quebrado... na data_as_tuples, codifica errado... ficou pra depois.
    # Remover a primeira linha (cabeçalho)
    data_without_header = data[1:]

    # Converter cada linha em uma tupla
    data_as_tuples = [tuple(row) for row in data_without_header]

    for row in data_as_tuples:
        if len(row) != 30:
            print("Erro: tupla com tamanho incorreto:", len(row), row)
    #data_as_tuples = ajustar_tamanho_linhas(data_without_header)

    cursor = conn.cursor()
    query = """
        INSERT INTO stgbrtrade (Type, CodCliente, UserID, CNPJ, NomeEnd, String, Field1, Field2, Field3, Field4, Field5, Field6, Field7, Field8, Field9, Field10, Field11, Field12, Field13, Field14, Field15, Field16, Field17, Field18, Field19, Field20, Field21, Field22, Field23, Field24) 
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    cursor.executemany(query, data_as_tuples)
    print(f"executed.")
    #print(result)
    conn.commit()

def execute_query(query:str):
    cursor = conn.cursor()
    cursor.execute(query)
    #result = cursor.fetchone()
    print(f"executed.")
    #print(result)
    conn.commit()

def finishCsv(bucket_name, s3_file_name) :
    print("finishCsv")
    print("s3_file_name", s3_file_name)
    print("bucket_name", bucket_name)
    destination = "processados/" + s3_file_name
    finishS3 = boto3.client('s3')
  
    try:
        # Copiar o arquivo para o novo diretório
        finishS3.copy_object(
            Bucket=bucket_name,
            CopySource={'Bucket': bucket_name, 'Key': s3_file_name},
            Key=destination
        )

        # Excluir o arquivo original
        finishS3.delete_object(Bucket=bucket_name, Key=s3_file_name)

        return 1
    except Exception as e:
        return 0



def getCsv(bucket_name, s3_file_name):
    print("getCsv")
    print("s3_file_name", s3_file_name)
    print("bucket_name", bucket_name)

    s3 = boto3.resource('s3')
    print("boto3 loaded")

    try:
        obj = s3.Object(bucket_name, s3_file_name)
        print("obj carregado", obj)

        raw_data = obj.get()['Body'].read()

        # Tenta múltiplas codificações
        encodings_to_try = ['utf-8', 'latin1', 'macroman', 'cp1252']
        for enc in encodings_to_try:
            try:
                print(f"Tentando decodificar com: {enc}")
                return raw_data.decode(enc)
            except UnicodeDecodeError:
                print(f"Falha ao decodificar com: {enc}")
                continue

        raise ValueError("Não foi possível decodificar o arquivo com as codificações conhecidas.")

    except ClientError as e:
        if e.response['Error']['Code'] == '404':
            print(f"O arquivo {s3_file_name} não existe no bucket {bucket_name}.")
        elif e.response['Error']['Code'] == '403':
            print(f"Você não tem permissão para acessar o arquivo {s3_file_name}.")
        else:
            print(f"Ocorreu um erro ao tentar acessar o arquivo: {e}")
        raise

def SqlStageSave(line):

    # if len(line) != 30:
    #     print(f"validação de linha falhou.")
    #     raise ValueError(f"Tupla com tamanho incorreto: {len(line)} elementos. Conteúdo: {line}")

    # print ("entrou save state", line);
    line2 = ajustar_array(line, 56);
    # print ("linha ajustada", line2);
    #line2 = ajustar_tamanho_linhas(line, 5)

    cursor = conn.cursor()

    query = cursor.execute(
        """
        INSERT INTO brtrade (Type, CodCliente, UserID, CNPJ, NomeEnd, [String], Field1, Field2, Field3, Field4, Field5, Field6, Field7, Field8, Field9, Field10, Field11, Field12, Field13, Field14, Field15, Field16, Field17, Field18, Field19, Field20, Field21, Field22, Field23, Field24,  Field25, Field26, Field27, Field28, Field29, Field30, Field31, Field32, Field33, Field34, Field35, Field36, Field37, Field38, Field39, Field40, Field41, Field42, Field43, Field44, Field45, Field46, Field47, Field48, Field49, Field50) 
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """,
    tuple(line2)

    )

    # print(f"executed.")
    conn.commit()

def createCsvObj(body):
    print("body loaded")
    test = body.splitlines()
    reader = csv.reader(test, delimiter=';')
    rows = list(reader)
    # execute_insert_trade(rows)

    i = 0
    oHeader = []
    oFields = 0

    for row in rows:
        i = i+1
        if (i == 1):
            oHeader = row
            oFields = len(row)
        else:
            SqlStageSave(row)

    # print(reader)
    return 1

def lambda_handler(event, context):
    file = event['Records'][0]['s3']['object']['key']
    bucket = event['Records'][0]['s3']['bucket']['name']
    #debug = event['Records'][0]['s3']['object']['key']

    print(f"bucket {bucket} / file {file}")

    if '/' in file:
        print(f"Ignorando arquivo em subpasta: {file}")
        return # Encerra a execução da Lambda

    # print ("inicio ===============", file)
    body = getCsv(bucket, file)
    # print (f"body {body}")

    query = 'delete from brtrade'
    execute_query(query)
    print ("limpeza stage")
    createCsvObj(body)
    print ("carga do arquivo")
    finishCsv(bucket, file)
    
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda finalizado!')
    }
