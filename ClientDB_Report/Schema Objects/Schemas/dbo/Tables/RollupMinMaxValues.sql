CREATE TABLE [dbo].[RollupMinMaxValues]
(
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](128) NOT NULL,
	[SourceDatabase] [varchar](128) NOT NULL,
	[PlanIdentifier] [varchar](20) NOT NULL,
	[SourceMinValue] [bigint] NULL,
	[SourceMaxValue] [bigint] NULL,
	[TargetMaxValue] [bigint] NULL,
	[LastUpdateDateTime] [Datetime] NULL
)

