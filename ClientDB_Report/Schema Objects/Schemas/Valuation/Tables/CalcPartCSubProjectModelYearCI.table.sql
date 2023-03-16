CREATE TABLE Valuation.CalcPartCSubProjectModelYearCI
    (
     [CalcPartCSubProjectModelYearCIId] [INT] IDENTITY(1, 1)
                                              NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [Model_Year] [INT] NULL
   , [HCCTotal] [INT] NULL
   , [AnnualizedEstimatedValue] [MONEY] NULL
   , [PMH_Attestation] [VARCHAR](255) NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )