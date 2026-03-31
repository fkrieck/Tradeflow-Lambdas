
CREATE TABLE [dbo].[Uploads](
	[UploadId] [int] IDENTITY(1,1) NOT NULL,
	[Arquivo] [varchar](300) NOT NULL,
	[Tipo] [varchar](20) NOT NULL,
	[DataUpload] [datetime] NOT NULL,
	[AtualizadoPor] [varchar](300) NOT NULL,
	[DataProcessamento] [datetime] NULL,
	[ProcessadoPor] [varchar](300) NULL,
	[Status] [varchar](30) NOT NULL,
	[EventId] [uniqueidentifier] NULL,
 CONSTRAINT [Upload_pkey] PRIMARY KEY CLUSTERED 
(
	[UploadId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Uploads] ADD  DEFAULT ('typefile') FOR [Tipo]
GO

ALTER TABLE [dbo].[Uploads] ADD  DEFAULT (getdate()) FOR [DataUpload]
GO

ALTER TABLE [dbo].[Uploads] ADD  DEFAULT ('Pendente') FOR [Status]
GO



CREATE TABLE [dbo].[UploadDetalhes](
	[UploadDetalheId] [int] IDENTITY(1,1) NOT NULL,
	[UploadId] [int] NOT NULL,
	[DataEvento] [datetime] NOT NULL,
	[LogEvento] [varchar](max) NOT NULL,
 CONSTRAINT [UploadDetalhes_pkey] PRIMARY KEY CLUSTERED 
(
	[UploadDetalheId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[UploadDetalhes] ADD  DEFAULT (getdate()) FOR [DataEvento]
GO





CREATE TABLE [dbo].[clientes](
	[ClienteId] [int] IDENTITY(1,1) NOT NULL,
	[Nome] [varchar](200) NOT NULL,
	[Rede] [varchar](100) NULL,
	[Regional] [varchar](10) NULL,
	[Potencial] [bit] NOT NULL,
	[Compliance] [bit] NOT NULL,
	[DataInstalacaoPeca] [date] NULL,
	[Adimplente] [bit] NOT NULL,
	[Obrigacao1] [bit] NOT NULL,
	[Obrigacao2] [bit] NOT NULL,
	[CodigoSAP] [varchar](20) NOT NULL,
	[businessid] [nvarchar](100) NULL,
	[sync_time] [datetime] NULL,
	[sync_status] [int] NULL,
	[CNPJ] [nvarchar](20) NULL,
	[EnderecoRua] [nvarchar](200) NULL,
	[EnderecoNumero] [nvarchar](20) NULL,
	[EnderecoComplemento] [nvarchar](200) NULL,
	[EnderecoBairro] [nvarchar](200) NULL,
	[EnderecoCidade] [nvarchar](200) NULL,
	[PagamentoPor] [nvarchar](20) NULL,
 CONSTRAINT [clientes_pkey] PRIMARY KEY CLUSTERED 
(
	[ClienteId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [idx_clientes_codigosap] UNIQUE NONCLUSTERED 
(
	[CodigoSAP] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[clientes] ADD  CONSTRAINT [DF_clientes_Potencial]  DEFAULT ((0)) FOR [Potencial]
GO

ALTER TABLE [dbo].[clientes] ADD  CONSTRAINT [DF_clientes_Compliance]  DEFAULT ((0)) FOR [Compliance]
GO

ALTER TABLE [dbo].[clientes] ADD  CONSTRAINT [DF_clientes_Adimplente]  DEFAULT ((0)) FOR [Adimplente]
GO




CREATE TABLE [dbo].[HitList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CodigoSAP] [nvarchar](20) NULL,
	[ClienteNome] [nvarchar](255) NOT NULL,
	[Regional] [nvarchar](10) NULL,
	[Rede] [nvarchar](255) NULL,
	[Potencial] [nvarchar](3) NULL,
	[MecanicaCodigo] [varchar](20) NULL,
	[MecanicaNome] [varchar](200) NOT NULL,
	[RegraNome] [varchar](100) NULL,
	[Chave] [varchar](100) NULL,
	[Faixa1Meta] [decimal](10, 2) NULL,
	[Faixa1Pontos] [decimal](10, 2) NULL,
	[Faixa2Meta] [decimal](10, 2) NULL,
	[Faixa2Pontos] [decimal](10, 2) NULL,
	[Faixa3Meta] [decimal](10, 2) NULL,
	[Faixa3Pontos] [decimal](10, 2) NULL,
	[Faixa4Meta] [decimal](10, 2) NULL,
	[Faixa4Pontos] [decimal](10, 2) NULL,
	[Faixa5Meta] [decimal](10, 2) NULL,
	[Faixa5Pontos] [decimal](10, 2) NULL,
	[Gatilho] [varchar](255) NULL,
	[Email] [varchar](255) NULL,
	[ContactID] [varchar](50) NULL,
 CONSTRAINT [HitList_pkey] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO




CREATE TABLE [dbo].[mecanicas](
	[MecanicaId] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [varchar](20) NOT NULL,
	[Nome] [varchar](200) NOT NULL,
	[PrazoVigenciaMeses] [int] NOT NULL,
	[ComplianceObrigatoria] [bit] NULL,
	[ConsideraInstalacao] [bit] NULL,
	[ConsideraAdimplencia] [bit] NULL,
	[Obrigacao1] [bit] NULL,
	[Obrigacao2] [bit] NULL,
	[ExigeAprovacaoTrade] [bit] NULL,
	[ExigeAceiteCliente] [bit] NULL,
	[DiasAceite] [int] NULL,
	[TermosDeServico] [nvarchar](255) NULL,
 CONSTRAINT [mecanicas_pkey] PRIMARY KEY CLUSTERED 
(
	[MecanicaId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [ComplianceObrigatoria]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [ConsideraInstalacao]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [ConsideraAdimplencia]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [Obrigacao1]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [Obrigacao2]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [ExigeAprovacaoTrade]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [ExigeAceiteCliente]
GO

ALTER TABLE [dbo].[mecanicas] ADD  DEFAULT ((0)) FOR [DiasAceite]
GO




CREATE TABLE [dbo].[regras](
	[RegraId] [int] IDENTITY(1,1) NOT NULL,
	[Nome] [varchar](100) NOT NULL,
	[TipoRegraId] [int] NULL,
	[DependeDeEAN] [bit] NULL,
	[DependeDeSalesType] [bit] NULL,
	[GrupoEANId] [int] NULL,
 CONSTRAINT [regras_pkey] PRIMARY KEY CLUSTERED 
(
	[RegraId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[regras] ADD  DEFAULT ((0)) FOR [DependeDeEAN]
GO

ALTER TABLE [dbo].[regras] ADD  DEFAULT ((0)) FOR [DependeDeSalesType]
GO

ALTER TABLE [dbo].[regras]  WITH CHECK ADD  CONSTRAINT [FK_regras_GrupoEANs] FOREIGN KEY([GrupoEANId])
REFERENCES [dbo].[grupoEANs] ([GrupoEANId])
GO

ALTER TABLE [dbo].[regras] CHECK CONSTRAINT [FK_regras_GrupoEANs]
GO




CREATE TABLE [dbo].[contratos](
	[ContratoId] [int] IDENTITY(1,1) NOT NULL,
	[ClienteId] [int] NULL,
	[ClienteNome] [varchar](200) NOT NULL,
	[DataContrato] [date] NOT NULL,
	[Vigencia] [int] NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[MecanicaId] [int] NULL,
	[CriadoPor] [varchar](200) NULL,
	[DataInstalacaoPPOSM] [date] NULL,
	[DataPagarPontoPPOSM] [date] NULL,
	[MotivoNaoPotencial] [nvarchar](500) NULL,
	[MotivoRejeicao] [nvarchar](400) NULL,
	[ShoppingOwnerAccount] [nvarchar](255) NULL,
	[Obs] [nvarchar](max) NULL,
	[ShopOwnerContactId] [nvarchar](100) NULL,
	[ShopOwnerAceito] [int] NULL,
	[ShopOwnerAceitoData] [datetime] NULL,
	[MargemAprovacao] [decimal](10, 2) NULL,
	[syncAceite] [int] NULL,
	[is_active] [bit] NULL,
	[ContratoInicio] [datetime] NULL,
	[ContratoFim] [datetime] NULL,
	[PagamentoPor] [nvarchar](20) NULL,
 CONSTRAINT [contratos_pkey] PRIMARY KEY CLUSTERED 
(
	[ContratoId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[contratos] ADD  DEFAULT ((0)) FOR [is_active]
GO



CREATE TABLE [dbo].[grupoEANs](
	[GrupoEANId] [int] IDENTITY(1,1) NOT NULL,
	[Chave] [varchar](100) NOT NULL,
 CONSTRAINT [grupoEANs_pkey] PRIMARY KEY CLUSTERED 
(
	[GrupoEANId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO




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

