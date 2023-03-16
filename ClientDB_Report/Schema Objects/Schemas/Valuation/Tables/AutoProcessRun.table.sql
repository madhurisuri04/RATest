CREATE TABLE Valuation.AutoProcessRun
    (
     [AutoProcessRunId] [INT] IDENTITY(1, 1)
                              NOT NULL
   , [ClientId] [INT] NOT NULL
   , [ConfigClientMainId] [INT] NOT NULL
   , [BDate] [DATETIME] NOT NULL
   , [EDate] [DATETIME] NULL
   , [FriendlyDescription] [VARCHAR](256) NULL
   , [ClientVisibleBDate] [DATE] NULL
   , [ClientVisibleEDate] [DATE] NULL
   , [GlobalProcessRunId] [INT] NULL 
    )