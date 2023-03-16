CREATE TABLE Valuation.CalcPartCTotalsBySubprojectAndModelYearESRD
    (
     [CalcPartCTotalsBySubprojectAndModelYearESRDId] [INT] IDENTITY(1, 1)
                                                           NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [Model_Year] [INT] NULL
   , [AnnualizedEstimatedValue] [MONEY] NULL
   , [HCCTotal] [INT] NULL
   , [PMH_Attestation] [VARCHAR](255) NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )