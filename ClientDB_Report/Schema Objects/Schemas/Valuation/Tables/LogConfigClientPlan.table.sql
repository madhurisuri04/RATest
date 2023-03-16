CREATE TABLE Valuation.LogConfigClientPlan
    (
     [LogConfigClientPlanId] [INT] IDENTITY(1, 1)
                                   NOT NULL
   , [Action] [CHAR](1) NULL
   , [ConfigClientPlanId] [INT] NULL
   , [ConfigClientMainId] [INT] NULL
   , [ConfigClientMainId_old] [INT] NULL
   , [ClientId] [INT] NULL
   , [ClientId_old] [INT] NULL
   , [PlanId] [VARCHAR](32) NULL
   , [PlanId_old] [VARCHAR](32) NULL
   , [PlanDb] [VARCHAR](130) NULL
   , [PlanDb_old] [VARCHAR](130) NULL
   , [Priority] [INT] NULL
   , [Priority_old] [INT] NULL
   , [ActiveBDate] [DATE] NULL
   , [ActiveBDate_old] [DATE] NULL
   , [ActiveEDate] [DATE] NULL
   , [ActiveEDate_old] [DATE] NULL
   , [Added] [DATETIME] NULL
   , [Added_old] [DATETIME] NULL
   , [AddedBy] [VARCHAR](257) NULL
   , [AddedBy_old] [VARCHAR](257) NULL
   , [Reviewed] [DATETIME] NULL
   , [Reviewed_old] [DATETIME] NULL
   , [ReviewedBy] [VARCHAR](257) NULL
   , [ReviewedBy_old] [VARCHAR](257) NULL
   , [Edited] [DATETIME] NULL
   , [EditedBy] [VARCHAR](257) NULL
    )