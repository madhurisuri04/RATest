CREATE TABLE [dbo].[RollupPlan](
	[PlanIdentifier] [smallint] IDENTITY(1,1) NOT NULL,
	[PlanID] [varchar](5) NOT NULL,
	[ClientIdentifier] [smallint] NOT NULL,
	[UseForRollup] [bit] NOT NULL,
	[Active] [bit] NOT NULL,
	[CreateDate] [smalldatetime] NOT NULL,
	[ModifiedDate] [smalldatetime] NOT NULL
)