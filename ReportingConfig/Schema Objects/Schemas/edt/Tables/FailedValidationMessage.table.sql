CREATE TABLE [edt].[FailedValidationMessage](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Descr] [varchar](512) NULL,
	[Message] [varchar](512) NULL,

	[Severity] [smallint] NOT NULL,
	[isCondition] [bit] NOT NULL DEFAULT(0),

	[Edit_ID] [smallint] NULL,
	[Edit_EntityID] [smallint] NULL,
	[Edit_TableQualifierID] [smallint] NULL,
	[Edit_RuleID] [smallint] NULL,
	[Edit_ValueEntity] [smallint] NULL,
	[Edit_ValueEntityQualifier] [smallint] NULL,
	[Edit_Value] [smallint] NULL,
	[Edit_RangeID] [smallint] NULL,
	[Edit_TypeID] [smallint] NULL,
	
	[Condition_ID] [smallint] NULL,
	[Condition_Name] [smallint] NULL,
	[Condition_Descr] [smallint] NULL,
	[Condition_ValueEntity] [smallint] NULL,
	[Condition_ValueEntityQualifier] [smallint] NULL,
	[Condition_Value] [smallint] NULL,
	[Condition_RangeID] [smallint] NULL,
	[Condition_TypeID] [smallint] NULL,
 CONSTRAINT [PK_FailedValidationMessage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [edt].[FailedValidationMessage]  WITH CHECK ADD  CONSTRAINT [FK_FailedValidationMessage_FailedValidationSeverity] FOREIGN KEY([Severity])
REFERENCES [edt].[FailedValidationSeverity] ([ID])
GO