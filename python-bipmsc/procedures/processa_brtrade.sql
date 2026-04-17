USE [BRTrade]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- processa_brtrade
-- Consolida BRTRADE + STGBRTRADE em FinalBRTrade:
--   Passo 1 - Reconhecimento dinâmico de Type/Mês (Field1-Field50)
--   Passo 2 - Limpeza diferencial da STGBRTRADE
--   Passo 3 - Limpeza da FinalBRTrade por Type/Mês
--   Passo 4 - Recarga da FinalBRTrade
-- Logs registados via SPINS_LOGS. Rollback automático em erro.
-- ============================================================
CREATE PROCEDURE [dbo].[processa_brtrade]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ==================================================
        -- Passo 1: Reconhecimento dinâmico de Type e Mês
        -- ==================================================
        -- Mapeia para cada (Source, Type) qual Field contém
        -- um nome de mês em português.

        CREATE TABLE #TypeMesMap (
            Source     NVARCHAR(20)  NOT NULL,
            Type       NVARCHAR(100) NOT NULL,
            FaixaField NVARCHAR(20)  NOT NULL,
            Mes        NVARCHAR(20)  NOT NULL
        );

        DECLARE
            @Source    NVARCHAR(20),
            @Type      NVARCHAR(100),
            @FieldNum  INT,
            @FieldName NVARCHAR(20),
            @Mes       NVARCHAR(20),
            @Sql       NVARCHAR(MAX),
            @ParamDef  NVARCHAR(300),
            @msg       NVARCHAR(MAX);

        -- Iterar sobre cada combinação distinta (Source, Type)
        DECLARE cur_types CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT Source, Type
            FROM (
                SELECT 'BRTRADE'    AS Source, Type FROM BRTRADE    WHERE Type IS NOT NULL
                UNION
                SELECT 'STGBRTRADE' AS Source, Type FROM STGBRTRADE WHERE Type IS NOT NULL
            ) t;

        OPEN cur_types;
        FETCH NEXT FROM cur_types INTO @Source, @Type;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @FieldNum = 1;

            WHILE @FieldNum <= 50
            BEGIN
                SET @FieldName = 'Field' + CAST(@FieldNum AS NVARCHAR(3));
                SET @ParamDef  = N'@TypeParam NVARCHAR(100), @MesOut NVARCHAR(20) OUTPUT';

                SET @Sql = N'
                    SELECT TOP 1 @MesOut = [' + @FieldName + N']
                    FROM ' + @Source + N'
                    WHERE Type = @TypeParam
                      AND [' + @FieldName + N'] IN (
                          N''Janeiro'',  N''Fevereiro'', N''Março'',    N''Abril'',
                          N''Maio'',     N''Junho'',     N''Julho'',    N''Agosto'',
                          N''Setembro'', N''Outubro'',   N''Novembro'', N''Dezembro''
                      )';

                SET @Mes = NULL;
                EXEC sp_executesql @Sql, @ParamDef,
                    @TypeParam = @Type,
                    @MesOut    = @Mes OUTPUT;

                IF @Mes IS NOT NULL
                BEGIN
                    INSERT INTO #TypeMesMap (Source, Type, FaixaField, Mes)
                    VALUES (@Source, @Type, @FieldName, @Mes);
                END

                SET @FieldNum = @FieldNum + 1;
            END

            FETCH NEXT FROM cur_types INTO @Source, @Type;
        END

        CLOSE cur_types;
        DEALLOCATE cur_types;

        EXEC SPINS_LOGS
            @Processo = 'lambda_brtrade',
            @Detalhes = 'Passo 1 concluído: mapeamento de Type/Mês realizado';

        -- ==================================================
        -- Passo 2: Limpeza diferencial da STGBRTRADE
        -- Remove Types que já estão em BRTRADE
        -- ==================================================
        DECLARE @RowsDeleted INT;

        DELETE FROM STGBRTRADE
        WHERE Type IN (SELECT DISTINCT Type FROM BRTRADE);

        SET @RowsDeleted = @@ROWCOUNT;

        SET @msg = 'Passo 2 concluído: ' + CAST(@RowsDeleted AS NVARCHAR(20)) + ' linhas removidas da STGBRTRADE';
        EXEC SPINS_LOGS
            @Processo = 'lambda_brtrade',
            @Detalhes = @msg;

        -- ==================================================
        -- Passo 3: Limpeza da FinalBRTrade
        -- Para cada (Type, FaixaField, Mes) do mapa,
        -- apaga os registros correspondentes.
        -- ==================================================
        DECLARE
            @FaixaField   NVARCHAR(20),
            @SqlDelete    NVARCHAR(MAX),
            @TotalDeleted INT = 0;

        DECLARE cur_map CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT Type, FaixaField, Mes
            FROM #TypeMesMap;

        OPEN cur_map;
        FETCH NEXT FROM cur_map INTO @Type, @FaixaField, @Mes;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SqlDelete = N'
                DELETE FROM FinalBRTrade
                WHERE Type = @TypeParam
                  AND [' + @FaixaField + N'] = @MesParam';

            EXEC sp_executesql @SqlDelete,
                N'@TypeParam NVARCHAR(100), @MesParam NVARCHAR(20)',
                @TypeParam = @Type,
                @MesParam  = @Mes;

            SET @RowsDeleted  = @@ROWCOUNT;
            SET @TotalDeleted = @TotalDeleted + @RowsDeleted;

            SET @msg = 'Passo 3: ' + CAST(@RowsDeleted AS NVARCHAR(20)) +
                ' linhas removidas da FinalBRTrade para Type=' + @Type +
                ' / ' + @FaixaField + '=' + @Mes;
            EXEC SPINS_LOGS
                @Processo = 'lambda_brtrade',
                @Detalhes = @msg;

            FETCH NEXT FROM cur_map INTO @Type, @FaixaField, @Mes;
        END

        CLOSE cur_map;
        DEALLOCATE cur_map;

        SET @msg = 'Passo 3 concluído: total de ' + CAST(@TotalDeleted AS NVARCHAR(20)) + ' linhas removidas da FinalBRTrade';
        EXEC SPINS_LOGS
            @Processo = 'lambda_brtrade',
            @Detalhes = @msg;

        -- ==================================================
        -- Passo 4: Recarga da FinalBRTrade
        -- BRTRADE (obrigatória) + STGBRTRADE remanescente
        -- ==================================================
        INSERT INTO FinalBRTrade (
            Type, UserID, CNPJ, NomeEnd, [String],
            Field1,  Field2,  Field3,  Field4,  Field5,
            Field6,  Field7,  Field8,  Field9,  Field10,
            Field11, Field12, Field13,
            CodCliente,
            Field14, Field15, Field16, Field17, Field18,
            Field19, Field20, Field21, Field22, Field23,
            Field24, Field25, Field26, Field27, Field28,
            Field29, Field30, Field31, Field32, Field33,
            Field34, Field35, Field36, Field37, Field38,
            Field39, Field40, Field41, Field42, Field43,
            Field44, Field45, Field46, Field47, Field48,
            Field49, Field50
        )
        SELECT
            Type, UserID, CNPJ, NomeEnd, [String],
            Field1,  Field2,  Field3,  Field4,  Field5,
            Field6,  Field7,  Field8,  Field9,  Field10,
            Field11, Field12, Field13,
            CodCliente,
            Field14, Field15, Field16, Field17, Field18,
            Field19, Field20, Field21, Field22, Field23,
            Field24, Field25, Field26, Field27, Field28,
            Field29, Field30, Field31, Field32, Field33,
            Field34, Field35, Field36, Field37, Field38,
            Field39, Field40, Field41, Field42, Field43,
            Field44, Field45, Field46, Field47, Field48,
            Field49, Field50
        FROM BRTRADE
        UNION ALL
        SELECT
            Type, UserID, CNPJ, NomeEnd, [String],
            Field1,  Field2,  Field3,  Field4,  Field5,
            Field6,  Field7,  Field8,  Field9,  Field10,
            Field11, Field12, Field13,
            CodCliente,
            Field14, Field15, Field16, Field17, Field18,
            Field19, Field20, Field21, Field22, Field23,
            Field24, Field25, Field26, Field27, Field28,
            Field29, Field30, Field31, Field32, Field33,
            Field34, Field35, Field36, Field37, Field38,
            Field39, Field40, Field41, Field42, Field43,
            Field44, Field45, Field46, Field47, Field48,
            Field49, Field50
        FROM STGBRTRADE;

        DECLARE @TotalInserted INT = @@ROWCOUNT;

        SET @msg = 'Passo 4 concluído: ' + CAST(@TotalInserted AS NVARCHAR(20)) + ' linhas inseridas na FinalBRTrade';
        EXEC SPINS_LOGS
            @Processo = 'lambda_brtrade',
            @Detalhes = @msg;

        DROP TABLE IF EXISTS #TypeMesMap;

        COMMIT TRANSACTION;

        EXEC SPINS_LOGS
            @Processo = 'lambda_brtrade',
            @Detalhes = 'Processamento concluído com sucesso';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @msg = 'ERRO: ' + ERROR_MESSAGE();
        EXEC SPINS_LOGS
            @Processo = 'lambda_brtrade',
            @Detalhes = @msg;
    END CATCH;
END;
GO
