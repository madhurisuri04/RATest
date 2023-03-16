CREATE TABLE [Valuation].[LogConfigProjectIdList] (
    [LogConfigProjectIdListId] [INT] IDENTITY(1, 1) NOT NULL
  , [Action] [CHAR](1) NULL
  , [ConfigProjectIdListId] [INT] NULL
  , [ConfigClientMainId] [INT] NULL
  , [ConfigClientMainId_old] [INT] NULL
  , [ClientId] [INT] NULL
  , [ClientId_old] [INT] NULL
  , [ProjectId] [INT] NULL
  , [ProjectId_old] [INT] NULL
  , [ProjectDescription] [VARCHAR](85) NULL
  , [ProjectDescription_old] [VARCHAR](85) NULL
  , [ProjectSortOrder] [INT] NULL
  , [ProjectSortOrder_old] [INT] NULL
  , [SuspectYR] [CHAR](4) NULL
  , [SuspectYR_old] [CHAR](4) NULL
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
         DEFAULT (GETDATE())
  , [EditedBy] [VARCHAR](257) NULL 
       DEFAULT (USER_NAME())
  , [ProjectYear] [INT] NULL
  , [ProjectYear_old] [INT] NULL
  , [RecommendedBy] [VARCHAR](128) NULL
  , [RecommendedBy_old] [VARCHAR](128) NULL)
