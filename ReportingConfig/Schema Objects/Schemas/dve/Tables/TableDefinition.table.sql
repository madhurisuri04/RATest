CREATE TABLE [dve].[TableDefinition](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableDatabase] [nvarchar](128) NULL,
	[TableSchema] [nvarchar](128) NOT NULL,
	[TableName] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_TableDefinition] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]