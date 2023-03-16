CREATE TABLE [dve].[Entity](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TableDefinitionID] [int] NOT NULL,
	[FieldName] [nvarchar](128) NOT NULL,
	[Name] [varchar](128) NOT NULL,
	[Descr] [varchar](250) NULL,
	[isActive] [bit] NOT NULL,
	[ModifiedDT] [datetime] NOT NULL,
 CONSTRAINT [PK_Entity] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]