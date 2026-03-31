CREATE TABLE [dbo].[UploadDetalhes](
        [UploadDetalheId] [int] IDENTITY(1,1) NOT NULL,
        [UploadId] [int] NOT NULL,
        [DataEvento] [datetime] NOT NULL,
        [LogEvento] [varchar](max) NOT NULL,
 CONSTRAINT [UploadDetalhes_pkey] PRIMARY KEY CLUSTERED 
(
        [UploadDetalheId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[UploadDetalhes] ADD  DEFAULT (getdate()) FOR [DataEvento]
GO
