CREATE TABLE Valuation.RptRetrospectiveValuation
    (
     [RptRetrospectiveValuationId] [INT] IDENTITY(1, 1)
                                         NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ReportHeader] [VARCHAR](128) NOT NULL
   , [RowDisplay] [VARCHAR](128) NOT NULL
   , [TotalChartsRequested] [INT] NULL
   , [TotalChartsRetrieved] [INT] NULL
   , [TotalChartsNotRetrieved] [INT] NULL
   , [TotalChartsAdded] [INT] NULL
   , [TotalCharts1stPassCoded] [INT] NULL
   , [TotalChartsCompleted] [INT] NULL
   , [ProjectCompletion] [NUMERIC](25, 14) NULL
   , [ProjectId] [INT] NULL
   , [ProjectDescription] [VARCHAR](85) NULL
   , [SubProjectId] [INT] NULL
   , [SubProjectDescription] [VARCHAR](255) NULL
   , [ReviewName] [VARCHAR](50) NULL
   , [ProjectSortOrder] [SMALLINT] NULL
   , [SubProjectSortOrder] [SMALLINT] NULL
   , [OrderFlag] [SMALLINT] NOT NULL
   , [PopulatedDate] [DATETIME] NOT NULL
    )