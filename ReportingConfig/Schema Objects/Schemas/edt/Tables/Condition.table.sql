CREATE TABLE [edt].[Condition](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Descr] [varchar](250) NULL,
	[FailedValidationMessage] [int] NULL DEFAULT(1),
	[ValueEntity] [int] NULL,
	[ValueEntityQualifier] [int] NULL,
	[Value] [varchar](1024) NULL,
	[RangeID] [int] NULL,
	[TypeID] [int] NOT NULL,
	[isActive] [bit] NOT NULL,
	[ModifiedDT] [datetime] NOT NULL,
 CONSTRAINT [PK_Condition] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]