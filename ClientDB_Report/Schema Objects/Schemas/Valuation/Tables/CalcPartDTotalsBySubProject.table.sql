CREATE TABLE Valuation.CalcPartDTotalsBySubProject
    (
     [CalcPartDTotalsBySubProjectId] [INT] IDENTITY(1, 1)
                                           NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [RxHCCTotal] [INT] NULL
   , [Estimated_Value] [MONEY] NULL
   , [PopulatedDate] [DATETIME] NOT NULL
   , [Annualized_Estimated_Value] [MONEY] NULL
   , [UNQ_CONDITIONS] BIT DEFAULT 1
   , [EncounterSource] [Varchar] (4) NULL
   , [ModelYear] [INT]
    )