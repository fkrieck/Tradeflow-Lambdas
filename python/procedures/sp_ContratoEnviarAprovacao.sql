Create PROCEDURE [dbo].[sp_ContratoEnviarAprovacao]
    @ContratoId int,
    @Login varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    Declare
        @ExigeAceiteCliente bit = 0,
        @ExigeAprovacaoTrade bit = 0

    Select 
        @ExigeAceiteCliente = ExigeAceiteCliente,
        @ExigeAprovacaoTrade = ExigeAprovacaoTrade
    From contratos c
        inner join mecanicas m on(c.MecanicaId = m.MecanicaId)
    Where
        c.ContratoId = @ContratoId
    
    If @ExigeAprovacaoTrade = 1
    Begin
        -- Inserir Aprovação Padrão - RTM
        Insert Into dbo.ContratoDetalhesAprovacao (ContratoId, Descricao, Usuario, Aprovado) 
            values (@ContratoId, 'Aprovação Iniciada pelo EE', @Login, 1)

                Waitfor Delay '00:00:00.05'    

        -- Inserir Aprovação Padrão - RTM
        Insert Into dbo.ContratoDetalhesAprovacao (ContratoId, Descricao, Usuario, Aprovado) 
            values (@ContratoId, 'Aguardando aprovação do RTM', @Login, null)

        update Contratos set status = 'Enviado para aprovação de Trade' where contratoid = @contratoid and status in('Draft','Rejeitado','Ativo');
    End
        -- ATUALIZADO EM 06/11/25 POR EDUARDO SGODE PARA ENVIAR CONTRATOS QUE VÃO DIRETO PRO CLIENTE ASSINAR
        Else If (@ExigeAprovacaoTrade = 0 and @ExigeAceiteCliente = 1)
    Begin
        Update Contratos set Status = 'Enviado para aprovação do Cliente', syncAceite = 0 where ContratoId = @ContratoId 

        -- Inserir Aprovação Gerente de Trade
        Insert Into dbo.ContratoDetalhesAprovacao (ContratoId, Descricao, Usuario, Aprovado) 
            values (@ContratoId, 'Aguardando aprovação do Cliente', '', null)
                Update Contratos set syncAceite = 0 where ContratoId = @ContratoId
    End

END;
GO
