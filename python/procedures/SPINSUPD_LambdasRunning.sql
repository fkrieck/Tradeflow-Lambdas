CREATE PROCEDURE [dbo].[SPINSUPD_LambdasRunning]
(
    @lambda_Name      VARCHAR(255),
    @LambdasPathName  VARCHAR(MAX),
    @eventid          VARCHAR(255),
    @status           INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica se já existe registro considerando também o PathName
    IF NOT EXISTS (
        SELECT 1 
        FROM LambdasRunning 
        WHERE LambdasRunningName = @lambda_Name
          AND LambdasRunningEventid = @eventid
          AND LambdasPathName = @LambdasPathName
    )
    BEGIN
        INSERT INTO LambdasRunning
        (
            LambdasRunningName,
            LambdasPathName,
            LambdasRunningEventid,
            LambdasRunningStatus,
            LambdasRunningDate,
            CreateDate,
            UpdateDate
        )
        VALUES
        (
            @lambda_Name,
            @LambdasPathName,
            @eventid,
            @status,
            GETUTCDATE(),
            GETUTCDATE(),   -- CreateDate
            GETUTCDATE()    -- UpdateDate
        );
    END
    ELSE
    BEGIN
        UPDATE LambdasRunning
        SET 
            LambdasRunningStatus = @status,
            LambdasRunningDate   = GETUTCDATE(),
            UpdateDate           = GETUTCDATE()
        WHERE 
            LambdasRunningName    = @lambda_Name
            AND LambdasRunningEventid = @eventid
            AND LambdasPathName       = @LambdasPathName;
    END
END
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Inserir ou Atualizar status na tabela LambdasRunning' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'SPINSUPD_LambdasRunning'
GO
