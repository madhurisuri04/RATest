CREATE TABLE [dbo].[RollupTableStatus](
	[RollupTableStatusID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableConfigID] [int] NOT NULL,
	[RollupStatus] [varchar](10) NOT NULL,
	[RollupState] [varchar](9) NOT NULL,
	[PlanIdentifierCurrentlyProcessing] [smallint] NULL,
	[PlanIDCurrentlyProcessing] [varchar](5) NULL,
	[PlanNumberCurrentlyProcessing] [smallint] NULL,
	[NumberOfPlansToProcess] [smallint] NULL,
	[RollupStart] [datetime] NULL,
	[RollupEnd] [datetime] NULL,
	[IndexBuildStart] [datetime] NULL,
	[IndexBuildEnd] [datetime] NULL,
	[LastStateCheckDate] [datetime] NOT NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
) 