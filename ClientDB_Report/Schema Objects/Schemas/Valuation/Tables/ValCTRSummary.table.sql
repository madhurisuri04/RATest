CREATE TABLE Valuation.ValCTRSummary
    (
     [ValCTRSummaryId] [INT] IDENTITY(1, 1)
                             NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ProjectId] [INT] NULL
   , [SubProjectId] [INT] NULL
   , [LoadDate] [DATE] NULL
   , [ChartsRequested] [INT] NULL
   , [ChartsVHRetrieved] [INT] NULL
   , [ChartsAdded] [INT] NULL
   , [ChartsFPC] [INT] NULL
   , [ChartsComplete] [INT] NULL
   , [ClientCodingCompleteDate] [VARCHAR](25) NULL
    )
