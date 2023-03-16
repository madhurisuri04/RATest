CREATE TABLE Valuation.CalcPMHAndAttestationTotalsESRD
    (
     [CalcPMHAndAttestationTotalsESRDId] [INT] IDENTITY(1, 1)
                                               NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [PMH_Attestation] [VARCHAR](255) NOT NULL
   , [Payment_Year] [INT] NOT NULL
   , [Model_Year] [INT] NOT NULL
   , [AnnualizedEstimatedValue] [MONEY] NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )