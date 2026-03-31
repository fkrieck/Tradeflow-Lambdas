CREATE TABLE [dbo].[ContratoDetalhesAprovacao](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ContratoId] [int] NOT NULL,
        [Descricao] [varchar](200) NOT NULL,
        [Usuario] [varchar](200) NOT NULL,
        [Aprovado] [bit] NULL,
 CONSTRAINT [ContratoDetalhesAprovacao_pkey] PRIMARY KEY CLUSTERED 
(
        [Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
