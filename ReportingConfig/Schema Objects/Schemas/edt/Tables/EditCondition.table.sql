CREATE TABLE [edt].[EditCondition](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ParentID] [int] NULL,
	[EditID] [int] NOT NULL,
	[ConditionID] [int] NOT NULL,
	[FailedValidationMessage] [int] NULL,
	[isMet] [bit] NOT NULL,
	[TrueOnANYChildCondition] [bit] NOT NULL,
 CONSTRAINT [PK_EditCondition] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]