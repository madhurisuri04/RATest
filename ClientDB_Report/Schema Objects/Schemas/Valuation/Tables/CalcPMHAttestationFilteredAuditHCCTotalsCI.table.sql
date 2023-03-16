CREATE TABLE Valuation.CalcPMHAttestationFilteredAuditHCCTotalsCI
    (
     [CalcPMHAttestationFilteredAuditHCCTotalsCIId] [INT] IDENTITY(1, 1)
                                                          NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [PMH_Attestation] [VARCHAR](255) NOT NULL
   , [ReviewName] [VARCHAR](50) NOT NULL
   , [Model_Year] [INT] NULL
   , [HCCTotal] [INT] NULL
   , [AnnualizedEstimatedValue] [MONEY] NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )