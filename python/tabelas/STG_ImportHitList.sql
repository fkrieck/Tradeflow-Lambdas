CREATE TABLE [dbo].[STG_ImportHitList](
        [EventDate] [datetime] NOT NULL,
        [Eventid] [uniqueidentifier] NOT NULL,
        [EventFile] [varchar](255) NOT NULL,
        [Codigo] [varchar](255) NULL,
        [Nome] [varchar](255) NULL,
        [Regional] [varchar](255) NULL,
        [Rede] [varchar](255) NULL,
        [Potencial] [varchar](255) NULL,
        [Mecanica] [varchar](255) NULL,
        [NomeMecanica] [varchar](255) NULL,
        [Regra] [varchar](255) NULL,
        [ChaveParaDetalhes] [varchar](255) NULL,
        [Meta1] [varchar](255) NULL,
        [PtsPremio1] [varchar](255) NULL,
        [Meta2] [varchar](255) NULL,
        [PtsPremio2] [varchar](255) NULL,
        [Meta3] [varchar](255) NULL,
        [PtsPremio3] [varchar](255) NULL,
        [Meta4] [varchar](255) NULL,
        [PtsPremio4] [varchar](255) NULL,
        [Meta5] [varchar](255) NULL,
        [PtsPremio5] [varchar](255) NULL,
        [Gatilho] [varchar](255) NULL,
        [Email] [varchar](255) NULL,
        [ContactID] [varchar](50) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[STG_ImportHitList] ADD  DEFAULT (getdate()) FOR [EventDate]
GO

-- Colunas adicionadas posteriormente (já incluídas no CREATE TABLE acima):
--alter table [STG_ImportHitList] add Email varchar(255)
--alter table [STG_ImportHitList] add ContactID varchar(50)
