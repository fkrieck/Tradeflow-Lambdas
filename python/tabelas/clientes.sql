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
