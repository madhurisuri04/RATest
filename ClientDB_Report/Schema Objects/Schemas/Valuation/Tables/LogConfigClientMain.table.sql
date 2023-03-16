CREATE TABLE Valuation.LogConfigClientMain
    (
     [LogConfigClientMainId] [INT] IDENTITY(1, 1)
                                   NOT NULL
   , [Action] [CHAR](1)
   , [ConfigClientMainId] [INT] NULL
   , [ClientName] [VARCHAR](128) NULL
   , [ClientName_old] [VARCHAR](128) NULL
   , [ClientId] [INT] NULL
   , [ClientId_old] [INT] NULL
   , [ClientReportDb] [VARCHAR](130) NULL
   , [ClientReportDb_old] [VARCHAR](130) NULL
   , [ClientLevelDb] [VARCHAR](130) NULL
   , [ClientLevelDb_old] [VARCHAR](130) NULL
   , [CTRSummaryServer] [VARCHAR](130) NULL
   , [CTRSummaryServer_old] [VARCHAR](130) NULL
   , [CTRSummaryDb] [VARCHAR](130) NULL
   , [CTRSummaryDb_old] [VARCHAR](130) NULL
   , [FilteredAuditRetention] [INT] NULL
   , [FilteredAuditRetention_old] [INT] NULL
   , [MaxWorkers] [TINYINT] NULL
   , [MaxWorkers_old] [TINYINT] NULL
   , [ActiveBDate] [DATE] NULL
   , [ActiveBDate_old] [DATE] NULL
   , [ActiveEDate] [DATE] NULL
   , [ActiveEDate_old] [DATE] NULL
   , [Added] [DATETIME] NULL
   , [Added_old] [DATETIME] NULL
   , [AddedBy] [VARCHAR](257) NULL
   , [AddedBy_old] [VARCHAR](257) NULL
   , [Reviewed] [DATETIME] NULL
   , [Reviewed_old] [DATETIME] NULL
   , [ReviewedBy] [VARCHAR](257) NULL
   , [ReviewedBy_old] [VARCHAR](257) NULL
   , [Edited] [DATETIME] NULL
   , [EditedBy] [VARCHAR](257) NULL
    )