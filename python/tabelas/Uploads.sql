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
