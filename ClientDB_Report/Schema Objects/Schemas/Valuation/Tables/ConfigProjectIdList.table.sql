CREATE TABLE [Valuation].[ConfigProjectIdList] (
    [ConfigProjectIdListId] [INT] IDENTITY(1, 1) NOT NULL
  , [ConfigClientMainId] [INT] NOT NULL
  , [ClientId] [INT] NOT NULL
  , [ProjectId] [INT] NOT NULL
  , [ProjectDescription] [VARCHAR](85) NULL
  , [ProjectSortOrder] [INT] NULL
  , [SuspectYR] [CHAR](4) NULL
  , [ActiveBDate] [DATE] NULL
  , [ActiveEDate] [DATE] NULL
  , [Added] [DATETIME] NULL
        DEFAULT (GETDATE())
  , [AddedBy] [VARCHAR](257) NULL
        DEFAULT (USER_NAME())
  , [Reviewed] [DATETIME] NULL
  , [ReviewedBy] [VARCHAR](257) NULL
  , [ProjectYear] [INT] NULL
  , [RecommendedBy] [VARCHAR](128) NULL)
