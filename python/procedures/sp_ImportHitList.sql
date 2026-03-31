CREATE PROCEDURE [dbo].[sp_ImportHitList]
    @EventId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

        drop table #StgCLIProcessed;
        drop table #StgProcessed;

        --declare @EventId UNIQUEIDENTIFIER = '9CF2EDE7-C283-4D98-8C2D-A1738DF18CA0';

    -- Declarar Variáveis
    DECLARE
        @Arquivo NVARCHAR(300),
        @uploadid INT,
        @has_error INT = 0;

    -- Buscar nome do Arquivo
    SELECT TOP 1 
        @Arquivo = REPLACE(EventFile, 'Import-Hitlist/', '') 
    FROM STG_ImportHitList 
    WHERE Eventid = @EventId 
    ORDER BY EventDate DESC;

    SELECT @uploadid = UploadId 
    FROM Uploads 
    WHERE Tipo = 'hitlist' 
      --AND Status IN ('Pendente','Processando','Erro') 
      AND Arquivo = @Arquivo;

        --select EventId = @EventId, Arquivo = @Arquivo, uploadid = @uploadid, has_error = @has_error

        --return;

    IF @uploadid IS NOT NULL
    BEGIN
        UPDATE Uploads SET EventId = @EventId WHERE Uploadid = @uploadid;
        INSERT INTO dbo.uploaddetalhes (UploadId, LogEvento) VALUES (@uploadid, 'Inicio de processamento !');

        -- Atualizar o Status para processando
        UPDATE Uploads 
        SET Status = 'processando', 
            DataProcessamento = GETDATE(), 
            ProcessadoPor = 'System'
        WHERE UploadId = @uploadid;

        ------------------------------------------------------------------
        -- 1. Processar Clientes (usando tabela temporária)
        ------------------------------------------------------------------
        SELECT DISTINCT
            REPLACE(S.Codigo, '.0', '') AS Codigo,
            S.Nome,
            ISNULL(S.Rede, '') AS Rede,
            S.Regional,
            CONVERT(BIT, CASE 
                WHEN UPPER(COALESCE(S.Potencial, '')) IN ('SIM', 'S', 'TRUE', '1') THEN 1
                ELSE 0
            END) AS Potencial
        INTO #StgCLIProcessed
        FROM STG_ImportHitList S
        WHERE S.Eventid = @EventId 
          AND S.Codigo IS NOT NULL;

        -- Atualizar clientes existentes
        UPDATE C
        SET
            C.Nome = S.Nome,
            C.Rede = S.Rede,
            C.Regional = S.Regional,
            C.Potencial = S.Potencial
        FROM Clientes C
        INNER JOIN #StgCLIProcessed S ON C.CodigoSAP = S.Codigo
        WHERE
            C.Nome <> S.Nome OR
            C.Rede <> S.Rede OR
            C.Regional <> S.Regional OR
            C.Potencial <> S.Potencial;

        -- Inserir novos clientes
        INSERT INTO dbo.Clientes (CodigoSAP, Nome, Rede, Regional, Potencial)
        SELECT DISTINCT
            S.Codigo,
            S.Nome,
            S.Rede,
            S.Regional,
            S.Potencial
        FROM #StgCLIProcessed S
        WHERE NOT EXISTS (
            SELECT 1 FROM Clientes C WHERE C.CodigoSAP = S.Codigo
        );

        -- Atualizações adicionais
        UPDATE clientes SET businessid = 'BR-' + CodigoSAP WHERE businessid IS NULL;
        UPDATE clientes SET sync_status = 0 WHERE sync_status IS NULL;
        UPDATE clientes 
        SET sync_status = 1 
        WHERE sync_status != 1 
          AND CodigoSAP IN (SELECT CodigoSAP FROM clientes_dte);

        ------------------------------------------------------------------
        -- 2. Processar HitList (usando tabela temporária)
        ------------------------------------------------------------------
        SELECT
            REPLACE(S.Codigo, '.0', '') AS Codigo,
            S.Nome,
            S.Regional,
            S.Rede,
            S.Potencial,
            S.Mecanica,
            S.NomeMecanica,
            S.Regra,
            S.ChaveParaDetalhes,
                        Case When Meta1 is not null then Trim(Replace(Replace(Meta1,',','.'),'R$','')) End as Meta1,
                        Case When PtsPremio1 is not null then Trim(Replace(Replace(PtsPremio1,',','.'),'R$','')) End as PtsPremio1,
                        Case When Meta2 is not null then Trim(Replace(Replace(Meta2,',','.'),'R$','')) End as Meta2,
                        Case When PtsPremio2 is not null then Trim(Replace(Replace(PtsPremio2,',','.'),'R$','')) End as PtsPremio2,
                        Case When Meta3 is not null then Trim(Replace(Replace(Meta3,',','.'),'R$','')) End as Meta3,
                        Case When PtsPremio3 is not null then Trim(Replace(Replace(PtsPremio3,',','.'),'R$','')) End as PtsPremio3,
                        Case When Meta4 is not null then Trim(Replace(Replace(Meta4,',','.'),'R$','')) End as Meta4,
                        Case When PtsPremio4 is not null then Trim(Replace(Replace(PtsPremio4,',','.'),'R$','')) End as PtsPremio4,
                        Case When Meta5 is not null then Trim(Replace(Replace(Meta5,',','.'),'R$','')) End as Meta5,
                        Case When PtsPremio5 is not null then Trim(Replace(Replace(PtsPremio5,',','.'),'R$','')) End as PtsPremio5,
            TRIM(REPLACE(S.Gatilho,',','.')) AS Gatilho,
                        TRIM(REPLACE(S.Email,',','.')) AS Email,
                        TRIM(REPLACE(S.ContactID,',','.')) AS ContactID,
                        IIF(m.codigo IS NULL,'Mecanica ['+ S.Mecanica +'] inválida, ','')
                        + IIF(R.RegraId IS NULL,'Regra ['+ S.Regra +'] inválida, ','')
                        + IIF(GE.GrupoEANId IS NULL And S.ChaveParaDetalhes is not null,'Chave ['+ S.ChaveParaDetalhes +'] inválida, ','')
                        as MsgErro,
                        CASE -- Validar Mecanica
                                WHEN m.codigo IS NULL 
                                        THEN 0 
                                ELSE 1 
                        END AS Mecanica_is_valid,
            CASE -- Validar Regras
                                WHEN R.RegraId IS NULL 
                                        THEN 0 
                                ELSE 1 
                        END AS Regra_is_valid,
            CASE -- Validar GrupoEANs
                                WHEN GE.GrupoEANId IS NULL And S.ChaveParaDetalhes is not null
                                        THEN 0 
                                ELSE 1 
                        END AS GrupoEAN_is_valid,
                        S.EventID
        INTO #StgProcessed
        FROM 
                        STG_ImportHitList S
                        LEFT JOIN Mecanicas M ON (S.Mecanica = M.codigo)
                        LEFT JOIN Regras R ON (S.Regra = R.Nome)
                        LEFT JOIN grupoEANs GE ON(S.ChaveParaDetalhes = GE.Chave)
        WHERE 
                        S.Eventid = @EventId;
        

        -- Atualizar HitList existente
        UPDATE H
        SET
            H.ClienteNome = S.Nome,
            H.Regional = S.Regional,
            H.Rede = S.Rede,
            H.Potencial = S.Potencial,
            H.Chave = S.ChaveParaDetalhes,
            H.Faixa1Meta = S.Meta1,
            H.Faixa1Pontos = S.PtsPremio1,
            H.Faixa2Meta = S.Meta2,
            H.Faixa2Pontos = S.PtsPremio2,
            H.Faixa3Meta = S.Meta3,
            H.Faixa3Pontos = S.PtsPremio3,
            H.Faixa4Meta = S.Meta4,
            H.Faixa4Pontos = S.PtsPremio4,
            H.Faixa5Meta = S.Meta5,
            H.Faixa5Pontos = S.PtsPremio5,
            H.Gatilho = S.Gatilho,
                        H.Email = S.Email,
                        H.ContactID = S.ContactID
        FROM HitList H
        INNER JOIN #StgProcessed S 
            ON (H.CodigoSAP = S.Codigo
           AND H.MecanicaCodigo = S.Mecanica 
                   And H.RegraNome = S.Regra
           AND S.Mecanica_is_valid = 1
                   AND S.Regra_is_valid = 1
                   AND S.GrupoEAN_is_valid = 1)
        WHERE
            ISNULL(H.Faixa1Meta, -1) <> ISNULL(S.Meta1, -1) OR
            ISNULL(H.Faixa1Pontos, -1) <> ISNULL(S.PtsPremio1, -1) OR
            ISNULL(H.Faixa2Meta, -1) <> ISNULL(S.Meta2, -1) OR
            ISNULL(H.Faixa2Pontos, -1) <> ISNULL(S.PtsPremio2, -1) OR
            ISNULL(H.Faixa3Meta, -1) <> ISNULL(S.Meta3, -1) OR
            ISNULL(H.Faixa3Pontos, -1) <> ISNULL(S.PtsPremio3, -1) OR
            ISNULL(H.Faixa4Meta, -1) <> ISNULL(S.Meta4, -1) OR
            ISNULL(H.Faixa4Pontos, -1) <> ISNULL(S.PtsPremio4, -1) OR
            ISNULL(H.Faixa5Meta, -1) <> ISNULL(S.Meta5, -1) OR
            ISNULL(H.Faixa5Pontos, -1) <> ISNULL(S.PtsPremio5, -1) OR
            ISNULL(H.Gatilho, -1) <> ISNULL(S.Gatilho, -1);

        -- Inserir novos registros na HitList
        INSERT INTO dbo.HitList (
            CodigoSAP, ClienteNome, Regional, Rede, Potencial,
            MecanicaCodigo, MecanicaNome, RegraNome, Chave,
            Faixa1Meta, Faixa1Pontos, Faixa2Meta, Faixa2Pontos,
            Faixa3Meta, Faixa3Pontos, Faixa4Meta, Faixa4Pontos,
            Faixa5Meta, Faixa5Pontos, Gatilho, Email, ContactID
        )
        SELECT
            S.Codigo, S.Nome, S.Regional, S.Rede, S.Potencial,
            S.Mecanica, S.NomeMecanica, S.Regra, S.ChaveParaDetalhes,
            S.Meta1, S.PtsPremio1, S.Meta2, S.PtsPremio2,
            S.Meta3, S.PtsPremio3, S.Meta4, S.PtsPremio4,
            S.Meta5, S.PtsPremio5, S.Gatilho, S.Email, S.ContactID
        FROM #StgProcessed S
        WHERE 
                        S.Mecanica_is_valid = 1 and S.Regra_is_valid = 1 AND S.GrupoEAN_is_valid = 1
                        AND NOT EXISTS (
              SELECT 1 FROM HitList H 
              WHERE H.CodigoSAP = S.Codigo 
                AND H.MecanicaCodigo = S.Mecanica
                                AND H.RegraNome = S.Regra
          );

        WAITFOR DELAY '00:00:01';

        ------------------------------------------------------------------
        -- Validações de Erro
        ------------------------------------------------------------------
        -- Validar CodigoSAP nulo
        IF EXISTS (SELECT 1 FROM #StgProcessed WHERE Codigo IS NULL)
        BEGIN
            SET @has_error = 1;
            INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento)
            SELECT @uploadid,
                   'O Cliente ' + TRIM(Nome) + ' não possui Codigo SAP e não será carregado !!! '
            FROM #StgProcessed 
            WHERE Codigo IS NULL;
        END
                -- Validar Mecanicas / Regras / Chave (GrupoEANs) inválidas
        IF EXISTS (SELECT 1 FROM #StgProcessed WHERE Mecanica_is_valid = 0 or Regra_is_valid = 0 or GrupoEAN_is_valid = 0 )
        BEGIN
            SET @has_error = 1;
            INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento)
            SELECT --DISTINCT 
                                @uploadid,
                S.MsgErro + ' o cliente [' + TRIM(S.Codigo) + ' - ' + TRIM(S.Nome) + '] não será carregado !'
            FROM #StgProcessed S
            WHERE Mecanica_is_valid = 0 or Regra_is_valid = 0 or GrupoEAN_is_valid = 0;
        END

        -------------------------------------------------------------------------
        -- Criar Contratos de Mecânicas que não precisam de Aprovação nem Aceite
        -------------------------------------------------------------------------
                -- Step 1: Declare the cursor
                DECLARE 
                        @CodigoSAP Nvarchar(20)
                        ,@Mecanica Nvarchar(20)
                        ,@RC int
                        ,@UserLogin varchar(100) = 'TradeFlow'
                        ,@ContratoId int;

                DECLARE CriarContratoAtivadoCursor CURSOR FOR
                -- Ativar Contratos quem não pedem Aprovação nem Aceite
                Select distinct S.Codigo, S.Mecanica 
                From #StgProcessed S
                        Inner Join Mecanicas M ON(S.Mecanica = M.Codigo)
                WHERE 
                        S.Mecanica_is_valid = 1 and S.Regra_is_valid = 1 AND S.GrupoEAN_is_valid = 1
                        And M.ExigeAprovacaoTrade = 0 AND M.ExigeAceiteCliente = 0;

                -- Step 2: Open the cursor
                OPEN CriarContratoAtivadoCursor;

                -- Step 3: Fetch the first row
                FETCH NEXT FROM CriarContratoAtivadoCursor INTO @CodigoSAP, @Mecanica;

                -- Step 4: Loop through the rows
                WHILE @@FETCH_STATUS = 0
                BEGIN
                        -- Ativar Contratos quem não pedem Aprovação nem Aceite
                        EXECUTE @RC = [dbo].[SP_CriarContrato] @CodigoSAP, @Mecanica, @UserLogin, @ContratoId OUTPUT

                        INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento) 
                        SELECT @uploadid, 'Criar e ativar o contrato '+ cast(@ContratoId as nvarchar(10)) + ' para cliente ' + @CodigoSAP

                        -- Fetch the next row
                        FETCH NEXT FROM CriarContratoAtivadoCursor INTO @CodigoSAP, @Mecanica;
                END;

                -- Step 5: Close and deallocate the cursor
                CLOSE CriarContratoAtivadoCursor;
                DEALLOCATE CriarContratoAtivadoCursor;

        -------------------------------------------------------------------------
        -- Criar Contratos de Mecânicas que não precisam de Aprovação mas precisam de aceite
        -------------------------------------------------------------------------
                -- Step 1: Declare the cursor
                --DECLARE 
                --      @CodigoSAP Nvarchar(20)
                --      ,@Mecanica Nvarchar(20)
                --      ,@RC int
                --      ,@UserLogin varchar(100) = 'TradeFlow'
                --      ,@ContratoId int;

                DECLARE CriarContratoAtivadoCursor CURSOR FOR
                -- Ativar Contratos quem não pedem Aprovação nem Aceite
                Select distinct S.Codigo, S.Mecanica 
                From #StgProcessed S
                        Inner Join Mecanicas M ON(S.Mecanica = M.Codigo)
                WHERE 
                        S.Mecanica_is_valid = 1 and S.Regra_is_valid = 1 AND S.GrupoEAN_is_valid = 1
                        And M.ExigeAprovacaoTrade = 0 AND M.ExigeAceiteCliente = 1;

                -- Step 2: Open the cursor
                OPEN CriarContratoAtivadoCursor;

                -- Step 3: Fetch the first row
                FETCH NEXT FROM CriarContratoAtivadoCursor INTO @CodigoSAP, @Mecanica;

                -- Step 4: Loop through the rows
                WHILE @@FETCH_STATUS = 0
                BEGIN
                        -- Ativar Contratos quem não pedem Aprovação nem Aceite
                        EXECUTE @RC = [dbo].[SP_CriarContrato] @CodigoSAP, @Mecanica, @UserLogin, @ContratoId OUTPUT

                        INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento) 
                        SELECT @uploadid, 'Criar e ativar o contrato '+ cast(@ContratoId as nvarchar(10)) + ' para cliente ' + @CodigoSAP

                        execute [sp_ContratoEnviarAprovacao] @ContratoId = @ContratoId, @Login = 'Importação Hitlist'

                        -- Fetch the next row
                        FETCH NEXT FROM CriarContratoAtivadoCursor INTO @CodigoSAP, @Mecanica;
                END;

                -- Step 5: Close and deallocate the cursor
                CLOSE CriarContratoAtivadoCursor;
                DEALLOCATE CriarContratoAtivadoCursor;

        -----------------------------------------------------------------------------
        -- Hitlist Carregado com novas Metas/Pontos de um cliente com Contrato Ativo
        -----------------------------------------------------------------------------
                -- Declare the cursor
                DECLARE 
                        @Contrato int
                        ,@Cliente int

                DECLARE AlterarContratoAtivadoCursor CURSOR FOR
                -- Ativar Contratos quem não pedem Aprovação nem Aceite

                Select distinct 
                        C.contratoid, Cli.ClienteId, Cli.CodigoSAP 
                From #StgProcessed S
                        Inner Join Clientes Cli on(S.Codigo = Cli.CodigoSAP)
                        Inner Join Contratos C on(C.ClienteId = Cli.ClienteId)
                Where
                        C.Status = 'Ativo'
                        And S.Mecanica_is_valid = 1 and S.Regra_is_valid = 1 AND S.GrupoEAN_is_valid = 1

                -- Step 2: Open the cursor
                OPEN AlterarContratoAtivadoCursor;

                -- Step 3: Fetch the first row
                FETCH NEXT FROM AlterarContratoAtivadoCursor INTO @Contrato, @Cliente, @CodigoSAP;

                -- Step 4: Loop through the rows
                WHILE @@FETCH_STATUS = 0
                BEGIN
                        -- Ativar Contratos quem não pedem Aprovação nem Aceite
                        EXECUTE @RC = [dbo].[SP_AlterarContrato] @Contrato;

                        INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento) 
                        SELECT @uploadid, 'Alterar Metas/Pontos do Contrato '+ cast(@Contrato as nvarchar(10)) + ' para cliente ' + @CodigoSAP

                        -- Enviar para nova Aprovação
                        EXECUTE @RC = [dbo].[sp_ContratoEnviarAprovacao] 
                           @ContratoId = @Contrato
                          ,@Login = 'TradeFlow Carga novo HitList'

                        -- Fetch the next row
                        FETCH NEXT FROM AlterarContratoAtivadoCursor INTO @Contrato, @Cliente, @CodigoSAP;
                END;

                -- Step 5: Close and deallocate the cursor
                CLOSE AlterarContratoAtivadoCursor;
                DEALLOCATE AlterarContratoAtivadoCursor;


        ------------------------------------------------------------------
        -- Finalização
        ------------------------------------------------------------------
        IF @has_error = 0
        BEGIN
            UPDATE Uploads 
            SET Status = 'processado', DataProcessamento = GETDATE(), ProcessadoPor = 'System' 
            WHERE UploadId = @uploadid;
            INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento) 
            VALUES (@uploadid, 'Processado com Sucesso !');
        END
        ELSE
        BEGIN
            UPDATE Uploads 
            SET Status = 'Erro', DataProcessamento = GETDATE(), ProcessadoPor = 'System' 
            WHERE UploadId = @uploadid;
            INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento) 
            VALUES (@uploadid, 'Esta carga foi parcial, somente os registros de clientes sem erros foram carregados !');
        END

        WAITFOR DELAY '00:00:01';
        INSERT INTO dbo.UploadDetalhes (UploadId, LogEvento) 
        VALUES (@uploadid, 'Fim de processamento !');

        -- Limpar tabelas temporárias
        DROP TABLE IF EXISTS #StgCLIProcessed;
        DROP TABLE IF EXISTS #StgProcessed;
    END
    ELSE
    BEGIN
        PRINT 'Não Localizou o ID do Upload !';
    END
END;
