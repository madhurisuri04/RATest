CREATE TABLE Valuation.ConfigClientPlan
    (
     [ConfigClientPlanId] [INT] IDENTITY(1, 1)
                                NOT NULL
   , [ConfigClientMainId] [INT] NOT NULL
   , [ClientId] [INT] NOT NULL
   , [PlanId] [VARCHAR](32) NOT NULL
   , [PlanDb] [VARCHAR](130) NULL
   , [Priority] [INT] NOT NULL
   , [ActiveBDate] [DATE] NULL
   , [ActiveEDate] [DATE] NULL
   , [Added] [DATETIME] NOT NULL
   , [AddedBy] [VARCHAR](257) NOT NULL
   , [Reviewed] [DATETIME] NULL
   , [ReviewedBy] [VARCHAR](257) NULL
    )