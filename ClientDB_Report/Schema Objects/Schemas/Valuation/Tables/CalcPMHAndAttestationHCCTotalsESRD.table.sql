CREATE TABLE Valuation.CalcPMHAndAttestationHCCTotalsESRD
    (
     [CalcPMHAndAttestationHCCTotalsESRDId] [INT] IDENTITY(1, 1)
                                                  NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NULL
   , [PMH_Attestation] [VARCHAR](255) NOT NULL
   , [Payment_Year] [INT] NOT NULL
   , [Model_Year] [INT] NOT NULL
   , [CountOfHICN] [INT] NOT NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )