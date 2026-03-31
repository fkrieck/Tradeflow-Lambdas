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
