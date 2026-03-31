CREATE TABLE [dbo].[ContratoDetalhesAprovacao](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ContratoId] [int] NOT NULL,
        [Descricao] [varchar](200) NOT NULL,
        [Usuario] [varchar](200) NOT NULL,
        [Aprovado] [bit] NULL,
        [DataEvento] [datetime] NOT NULL,
 CONSTRAINT [ContratoDetalhesAprovacao_pkey] PRIMARY KEY CLUSTERED 
(
        [Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ContratoDetalhesAprovacao] ADD  DEFAULT (getdate()) FOR [DataEvento]
GO

ALTER TABLE [dbo].[ContratoDetalhesAprovacao]  WITH CHECK ADD  CONSTRAINT [FK_ContratoDetalhesAprovacao_contratos] FOREIGN KEY([ContratoId])
REFERENCES [dbo].[contratos] ([ContratoId])
GO

ALTER TABLE [dbo].[ContratoDetalhesAprovacao] CHECK CONSTRAINT [FK_ContratoDetalhesAprovacao_contratos]
GO
