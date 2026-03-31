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
