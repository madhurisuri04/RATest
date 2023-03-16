CREATE TABLE Valuation.CalcPartDFilteredAuditTotals
    (
     [CalcPartDFilteredAuditTotalsId] [INT] IDENTITY(1, 1)
                                            NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [PMH_Attestation] [VARCHAR](255) NULL
   , [ReviewName] [VARCHAR](50) NULL
   , [HCCTotal] [INT] NULL
   , [EstimatedValue] [MONEY] NULL
   , [Annualized_Estimated_Value] [MONEY] NULL
   , [UNQ_CONDITIONS] INT 
   , [PopulatedDate] [DATETIME] NOT NULL
   , [EncounterSource] [Varchar] (4) NULL
    )
