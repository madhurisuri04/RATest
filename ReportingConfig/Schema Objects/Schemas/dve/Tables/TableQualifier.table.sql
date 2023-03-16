CREATE TABLE [dve].[TableQualifier](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableDefinitionID] [int] NOT NULL,
	[QualifiedFieldName] [nvarchar](128) NULL,
	[Qualifier] [varchar](1024) NOT NULL,
	[Name] [varchar](128) NOT NULL,
	[Descr] [varchar](250) NULL,
 CONSTRAINT [PK_TableQualifier] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]