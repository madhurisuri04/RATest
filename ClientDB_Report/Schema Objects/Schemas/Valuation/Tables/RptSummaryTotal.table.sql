CREATE TABLE Valuation.RptSummaryTotal
    (
     [RptSummaryTotalId] [INT] IDENTITY(1, 1)
                               NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [InitialAutoProcessRunId] [INT] NOT NULL
   , [ReportHeader] [VARCHAR](128) NOT NULL
   , [RowDisplay] [VARCHAR](128) NOT NULL
   , [CodingThrough] [DATE] NOT NULL
   , [ValuationDelivered] [DATE] NOT NULL
   , [ProjectCompletion] [NUMERIC](34, 18) NULL
   , [ChartsCompleted] [INT] NULL
   , [HCCTotal_PartC] [INT] NULL
   , [EstRev_PartC] [MONEY] NULL
   , [HCCRealizationRate_PartC] [NUMERIC](34, 18) NULL
   , [EstRevPerChart_PartC] [NUMERIC](34, 18) NULL
   , [EstRevPerHCC_PartC] [NUMERIC](34, 18) NULL
   , [HCCTotal_PartD] [INT] NULL
   , [EstRev_PartD] [MONEY] NULL
   , [HCCRealizationRate_PartD] [NUMERIC](34, 18) NULL
   , [EstRevPerChart_PartD] [NUMERIC](34, 18) NULL
   , [EstRevPerHCC_PartD] [NUMERIC](34, 18) NULL
   , [TotalEstRev] [MONEY] NULL
   , [TotalEstRevPerChart] [MONEY] NULL
   , [Notes] [VARCHAR](256) NULL
   , [SummaryYear] [BIT] NULL
   , [ChartsRequested] [INT] NULL
   , [IsSummary] [BIT] NOT NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   ,[Grouping] VARCHAR(10)  NULL
   ,[GroupingOrder] INT  NULL
    )