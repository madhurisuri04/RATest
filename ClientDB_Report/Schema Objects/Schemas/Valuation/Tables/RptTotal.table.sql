CREATE TABLE Valuation.RptTotal
    (
     [RptTotalId] [INT] IDENTITY(1, 1)
                        NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ReportHeader] [VARCHAR](128) NOT NULL
   , [ReportType] [VARCHAR](128) NOT NULL
   , [ReportSubType] [VARCHAR](128) NOT NULL
   , [Header] [VARCHAR](128) NOT NULL
   , [RowDisplay] [VARCHAR](128) NULL
   , [HCCTotal_PartC] [INT] NULL
   , [EstRev_PartC] [MONEY] NULL
   , [EstRevPerHCC_PartC] [NUMERIC](34, 18) NULL
   , [HCCTotal_PartD] [INT] NULL
   , [EstRev_PartD] [MONEY] NULL
   , [EstRevPerHCC_PartD] [NUMERIC](34, 18) NULL
   , [ProjectId] [INT] NULL
   , [ProjectDescription] [VARCHAR](85) NULL
   , [SubProjectId] [INT] NULL
   , [SubProjectDescription] [VARCHAR](255) NULL
   , [ProjectSortOrder] [SMALLINT] NULL
   , [SubProjectSortOrder] [SMALLINT] NULL
   , [OrderFlag] [SMALLINT] NOT NULL
   , [PopulatedDate] [DATETIME] NOT NULL
    )