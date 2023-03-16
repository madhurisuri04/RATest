CREATE TABLE Valuation.ConfigClientMain
    (
     [ConfigClientMainId] [INT] IDENTITY(1, 1)
                                NOT NULL
   , [ClientName] [VARCHAR](128) NULL
   , [ClientId] [INT] NOT NULL
   , [ClientReportDb] [VARCHAR](130) NULL
   , [ClientLevelDb] [VARCHAR](130) NULL
   , [CTRSummaryServer] [VARCHAR](130) NULL
   , [CTRSummaryDb] [VARCHAR](130) NULL
   , [FilteredAuditRetention] [INT] NULL
   , [MaxWorkers] [TINYINT] NULL
   , [ActiveBDate] [DATE] NULL
   , [ActiveEDate] [DATE] NULL
   , [Added] [DATETIME] NOT NULL
   , [AddedBy] [VARCHAR](257) NOT NULL
   , [Reviewed] [DATETIME] NULL
   , [ReviewedBy] [VARCHAR](257) NULL
    )