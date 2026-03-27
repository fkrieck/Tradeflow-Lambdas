CREATE TABLE [dbo].[LambdasRunning](
	[LambdasRunningEventid] [varchar](255) NOT NULL,
	[LambdasRunningName] [varchar](255) NOT NULL,
	[LambdasPathName] [varchar](max) NOT NULL,
	[LambdasRunningStatus] [int] NOT NULL,
	[LambdasRunningDate] [datetime] NOT NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreateDate] [datetime] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[LambdasRunning] ADD  CONSTRAINT [DF_LambdasRunning_LambdasRunningEventid]  DEFAULT (newid()) FOR [LambdasRunningEventid]
GO

ALTER TABLE [dbo].[LambdasRunning] ADD  CONSTRAINT [DF_LambdasRunningDate]  DEFAULT (getdate()) FOR [LambdasRunningDate]
GO

ALTER TABLE [dbo].[LambdasRunning] ADD  CONSTRAINT [DF_LambdasRunning_CreateDate]  DEFAULT (getutcdate()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[LambdasRunning] ADD  CONSTRAINT [DF_LambdasRunning_UpdateDate]  DEFAULT (getutcdate()) FOR [UpdateDate]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'(PK) Identificador único do Evento. Default(newid())' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'LambdasRunning', @level2type=N'COLUMN',@level2name=N'LambdasRunningEventid'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nome da Lambda' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'LambdasRunning', @level2type=N'COLUMN',@level2name=N'LambdasRunningName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Path completo do arquivo Parquet' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'LambdasRunning', @level2type=N'COLUMN',@level2name=N'LambdasPathName'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Status de execução (1 - Recebido pela Lambda / 2 - Processando carga Stage / 3 - Erro ao Carregar na Stage / 4 - Disponível para processar no CIP / 5 - Em Processamento pelo CIP / 6 - Processado com Sucesso / 7 - Descartado por falta de processamento dentro do horário no CIP)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'LambdasRunning', @level2type=N'COLUMN',@level2name=N'LambdasRunningStatus'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Data/hora da ocorrência do Status' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'LambdasRunning', @level2type=N'COLUMN',@level2name=N'LambdasRunningDate'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Controle de execução das Lambdas' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'LambdasRunning'
GO
