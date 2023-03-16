CREATE TABLE Valuation.RptRetrospectiveValuationDetail
    (
     [RptRetrospectiveValuationDetailId] [INT] IDENTITY(1, 1)
                                               NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ReportType] [VARCHAR](128) NOT NULL
   , [ReportHeader] [VARCHAR](128) NOT NULL
   , [DOSPaymentYearHeader] [VARCHAR](128) NOT NULL
   , [RowDisplay] [VARCHAR](128) NOT NULL
   , [ChartsCompleted] [INT] NULL
   , [HCCTotal_PartC] [INT] NULL
   , [EstRev_PartC] [MONEY] NULL
   , [EstRevPerHCC_PartC] [MONEY] NULL
   , [HCCRealizationRate_PartC] [NUMERIC](25, 14) NULL
   , [HCCTotal_PartD] [INT] NOT NULL
   , [EstRev_PartD] [MONEY] NOT NULL
   , [EstRevPerHCC_PartD] [NUMERIC](34, 18) NULL
   , [HCCRealizationRate_PartD] [NUMERIC](25, 14) NULL
   , [EstRevPerChartsCompleted] [NUMERIC](34, 18) NULL
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
