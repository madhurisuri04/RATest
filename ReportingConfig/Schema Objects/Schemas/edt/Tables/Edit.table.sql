CREATE TABLE [edt].[Edit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EntityID] [int] NOT NULL,
	[TableQualifierID] [int] NULL,
	[LOBCode] [bigint] NULL,
	[LOBState] [bigint] NULL,
	[EditTypeCode] [bigint] NOT NULL,
	[RuleID] [int] NOT NULL,
	[FailedValidationMessage] [int] NULL DEFAULT(1),
	[ValueEntity] [int] NULL,
	[ValueEntityQualifier] [int] NULL,
	[Value] [varchar](1024) NULL,
	[RangeID] [int] NULL,
	[TypeID] [int] NULL,
	[isActive] [bit] NOT NULL,
	[ModifiedDT] [datetime] NOT NULL,
	[TrueOnANYCondition] [bit] NOT NULL,
	[Descr] [varchar](512) NULL,
 CONSTRAINT [PK_Edit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
