CREATE TABLE [Valuation].[AutoProcessWorkList] (
    [AutoProcessWorkListId] [INT] IDENTITY(1, 1) NOT NULL
  , [GlobalProcessRunId] [INT] NULL
  , [ClientId] [INT] NOT NULL
  , [AutoProcessRunId] [INT] NOT NULL
  , [AutoProcessId] [INT] NULL
  , [AutoProcessActionId] [INT] NULL
  , [Phase] [INT] NOT NULL
  , [Priority] [INT] NOT NULL
  , [PreRunSecs] [INT] NOT NULL
  , [DbName] [VARCHAR](130) NULL
  , [CommandDb] [VARCHAR](130) NULL
  , [CommandSchema] [VARCHAR](130) NULL
  , [CommandSTP] [VARCHAR](130) NULL
  , [Parameter] [NVARCHAR](2048) NULL
  , [BDate] [DATETIME] NULL
  , [EDate] [DATETIME] NULL
  , [AutoProcessWorkerId] [INT] NULL
  , [RowCount] [BIGINT] NULL
  , [SPID] [SMALLINT] NULL
  , [ErrorInfo] [VARCHAR](2048) NULL
  , [Result] [VARCHAR](128) NULL
  , [Retry] [SMALLINT] NULL
  , [Status] [VARCHAR](30) NULL
  , [AutoProcessActionCatalogId] [INT] NULL
  , [DependAutoProcessActionCatalogId] [INT] NULL
  , [ByPlan] [BIT] NULL
  , [StopAll] [BIT] NULL)