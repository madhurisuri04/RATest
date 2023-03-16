CREATE TABLE Valuation.CalcFilteredAuditsTotalForCI
    (
     [CalcFilteredAuditsTotalForCIId] [INT] IDENTITY(1, 1)
                                            NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [Model_Year] [INT] NULL
   , [ReviewName] [VARCHAR](50) NOT NULL
   , [HCCTotal] [INT] NULL
   , [AnnualizedEstimatedValue] [MONEY] NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )