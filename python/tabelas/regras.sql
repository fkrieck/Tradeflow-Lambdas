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
