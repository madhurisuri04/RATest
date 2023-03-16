CREATE TABLE Valuation.FilteredAuditCNCompletedChart
    (
     [FilteredAuditCNCompletedChartId] [INT] IDENTITY(1, 1)
                                             NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ProjectId] [INT] NULL
   , [SubProjectId] [INT] NULL
   , [SubProjectDescription] [VARCHAR](255) NULL
   , [ReviewName] [VARCHAR](50) NULL
   , [VeriskRequestId] [VARCHAR](20) NULL
    )