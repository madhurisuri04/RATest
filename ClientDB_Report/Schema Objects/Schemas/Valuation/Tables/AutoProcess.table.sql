CREATE TABLE [Valuation].[AutoProcess] (
    [AutoProcessId] [INT] IDENTITY(1, 1) NOT NULL
  , [AutoProcessName] [VARCHAR](128) NOT NULL
  , [ClientId] [INT] NOT NULL
  , [ClientReportDb] [VARCHAR](130) NULL
  , [ClientLevelDb] [VARCHAR](130) NULL
  , [CTRSummaryServer] [VARCHAR](130) NULL
  , [CTRSummaryDb] [VARCHAR](130) NULL
  , [ParameterDb] [VARCHAR](130) NULL
  , [ParameterSchema] [VARCHAR](130) NULL
  , [FilteredAuditRetention] [INT] NULL
  , [MaxWorkers] [TINYINT] NULL
  , [Initial_AutoProcessActionCatalogId] [INT] NULL
  , [ActiveBDate] [DATE] NULL
  , [ActiveEDate] [DATE] NULL
  , [Added] [DATETIME] NOT NULL
  , [AddedBy] [VARCHAR](257) NOT NULL
  , [Reviewed] [DATETIME] NULL
  , [ReviewedBy] [VARCHAR](257) NULL)