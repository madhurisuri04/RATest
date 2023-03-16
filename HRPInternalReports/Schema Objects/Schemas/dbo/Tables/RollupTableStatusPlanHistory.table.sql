CREATE TABLE [dbo].[RollupTableStatusPlanHistory](
	[RollupTableStatusPlanHistoryID] [int] IDENTITY(1,1) NOT NULL,
	[RollupTableStatusID] [int] NOT NULL,
	[PlanIdentifier] [smallint] NOT NULL,
	[PlanRollupStart] [datetime] NOT NULL,
	[PlanRollupEnd] [datetime] NOT NULL,
	[HistoryCreateDate] [smalldatetime] NOT NULL,
	[HistoryModifiedDate] [smalldatetime] NOT NULL
)