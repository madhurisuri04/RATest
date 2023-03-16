CREATE TABLE Valuation.CalcFilteredAuditsTotalForESRD
    (
     [CalcFilteredAuditsTotalForESRDId] [INT] IDENTITY(1, 1)
                                              NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [Model_Year] [INT] NOT NULL
   , [ReviewName] [VARCHAR](50) NOT NULL
   , [AnnualizedEstimatedValue] [MONEY] NULL
   , [HCCTotal] [INT] NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )