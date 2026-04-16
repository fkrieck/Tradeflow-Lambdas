/****** Object:  StoredProcedure [dbo].[SP_ContratosRegistraAceite]    Script Date: 15/04/2026 22:56:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[SP_ContratosRegistraAceite]
    @ContratoId BIGINT,
    @Aceito INT,
    @ShopOwner NVARCHAR(200),
    @Data DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Contratos WHERE Status = 'Enviado para aprovação do Cliente' AND ContratoId = @ContratoId)
        RETURN;

        Declare @EmailUsuario nvarchar(200)

        select @EmailUsuario = ShoppingOwnerAccount from Contratos where ContratoId = @ContratoId

    IF @Aceito = 1
    BEGIN
                
                declare @diasAceite int
                declare @vigencia int 
                declare @dtInicio datetime
                declare @dtFim datetime

                select @diasAceite = isnull(DiasAceite, 0), @vigencia = m.PrazoVigenciaMeses from contratos c
            inner join mecanicas m on c.mecanicaid = m.mecanicaid
            where c.contratoid = @ContratoId

                -- Obtém o dia atual
                DECLARE @diaAtual INT = DAY(GETDATE());

                -- Verifica se o dia atual é maior que @diasAceite
                IF @diaAtual > @diasAceite
                BEGIN
                        -- Define @dtInicio como o primeiro dia do próximo mês
                        SET @dtInicio = DATEADD(MONTH, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0));
                END
                ELSE
                BEGIN
                        -- Define @dtInicio como o primeiro dia do mês atual
                        SET @dtInicio = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
                END

                set @dtFim = DATEADD(DAY, -1, DATEADD(MONTH, @vigencia, @dtInicio))

        UPDATE contratos
        SET Status = 'Ativo',
            ShopOwnerAceitoData = @Data,
            is_active = 1,
                        ContratoInicio = @dtInicio,
                        ContratoFim = @dtFim
        WHERE ContratoId = @ContratoId;

                update ContratoDetalhesAprovacao 
                        set DataEvento = @Data, 
                        Aprovado = 1, 
                        Descricao = 'Aceito pelo Cliente ' + '- O contrato iniciará em ' + convert(nvarchar(100), @dtInicio),
                        Usuario = @EmailUsuario
                where 
                        [Descricao] = 'Aguardando aprovação do Cliente' and [ContratoId] = @ContratoId

        -- Guardar a Meta e Ponto Approvada
        Update crfm set
            ApprovedMeta = Meta,
            ApprovedPontos = Pontos
        From
            contratos c
            inner join contratoRegrasMetas crm on(c.ContratoId = crm.ContratoId)
            inner join contratoRegrasFaixaMetas crfm on(crm.ContratoRegraMetaId = crfm.ContratoRegraMetaId)
        where c.contratoid = @ContratoId

    END
    ELSE IF @Aceito = 0
    BEGIN
        UPDATE contratos
        SET Status = 'Rejeitado'
        WHERE ContratoId = @ContratoId;

                update ContratoDetalhesAprovacao 
                        set DataEvento = @Data, 
                        Aprovado = 0, 
                        Descricao = 'Rejeitado pelo Cliente',
                        Usuario = @EmailUsuario
                where [Descricao] = 'Aguardando aprovação do Cliente' and [ContratoId] = @ContratoId

    END
END;
GO
