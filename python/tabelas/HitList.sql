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

-- Colunas adicionadas posteriormente (já incluídas no CREATE TABLE acima):
--alter table [HitList] add Email varchar(255)
--alter table [HitList] add ContactID varchar(50)
