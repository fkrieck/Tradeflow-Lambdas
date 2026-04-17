USE [BRTrade]
GO

/****** Object:  Table [dbo].[STGBRTrade]    Script Date: 17/04/2026 09:51:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[STGBRTrade](
        [ID] [bigint] IDENTITY(1,1) NOT NULL,
        [Type] [nvarchar](100) NULL,
        [UserID] [nvarchar](100) NULL,
        [CNPJ] [nvarchar](100) NULL,
        [NomeEnd] [nvarchar](100) NULL,
        [String] [nvarchar](500) NULL,
        [Field1] [nvarchar](1000) NULL,
        [Field2] [nvarchar](1000) NULL,
        [Field3] [nvarchar](1000) NULL,
        [Field4] [nvarchar](1000) NULL,
        [Field5] [nvarchar](1000) NULL,
        [Field6] [nvarchar](1000) NULL,
        [Field7] [nvarchar](1000) NULL,
        [Field8] [nvarchar](1000) NULL,
        [Field9] [nvarchar](1000) NULL,
        [Field10] [nvarchar](1000) NULL,
        [Field11] [nvarchar](1000) NULL,
        [Field12] [nvarchar](1000) NULL,
        [Field13] [nvarchar](1000) NULL,
        [CodCliente] [nvarchar](10) NULL,
        [Field14] [nvarchar](1000) NULL,
        [Field15] [nvarchar](1000) NULL,
        [Field16] [nvarchar](1000) NULL,
        [Field17] [nvarchar](1000) NULL,
        [Field18] [nvarchar](1000) NULL,
        [Field19] [nvarchar](1000) NULL,
        [Field20] [nvarchar](1000) NULL,
        [Field21] [nvarchar](1000) NULL,
        [Field22] [nvarchar](1000) NULL,
        [Field23] [nvarchar](1000) NULL,
        [Field24] [nvarchar](1000) NULL,
        [Field25] [nvarchar](1000) NULL,
        [Field26] [nvarchar](1000) NULL,
        [Field27] [nvarchar](1000) NULL,
        [Field28] [nvarchar](1000) NULL,
        [Field29] [nvarchar](1000) NULL,
        [Field30] [nvarchar](1000) NULL,
        [Field31] [nvarchar](1000) NULL,
        [Field32] [nvarchar](1000) NULL,
        [Field33] [nvarchar](1000) NULL,
        [Field34] [nvarchar](1000) NULL,
        [Field35] [nvarchar](1000) NULL,
        [Field36] [nvarchar](1000) NULL,
        [Field37] [nvarchar](1000) NULL,
        [Field38] [nvarchar](1000) NULL,
        [Field39] [nvarchar](1000) NULL,
        [Field40] [nvarchar](1000) NULL,
        [Field41] [nvarchar](1000) NULL,
        [Field42] [nvarchar](1000) NULL,
        [Field43] [nvarchar](1000) NULL,
        [Field44] [nvarchar](1000) NULL,
        [Field45] [nvarchar](1000) NULL,
        [Field46] [nvarchar](1000) NULL,
        [Field47] [nvarchar](1000) NULL,
        [Field48] [nvarchar](1000) NULL,
        [Field49] [nvarchar](1000) NULL,
        [Field50] [nvarchar](1000) NULL,
 CONSTRAINT [PK_STGBRTrade] PRIMARY KEY CLUSTERED 
(
        [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
