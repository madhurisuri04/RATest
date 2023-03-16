CREATE TABLE [Valuation].[ConfigSubProjectReviewName] (
    [SubProjectReviewNameId] [INT] IDENTITY(1, 1) NOT NULL
  , [ClientId] [INT] NOT NULL
  , [ProjectId] [INT] NOT NULL
  , [SubProjectId] [INT] NOT NULL
  , [ReviewName] [VARCHAR](50) NOT NULL
  , [ActiveBDate] [DATE] NULL
  , [ActiveEDate] [DATE] NULL
  , [Added] [DATETIME] NOT NULL
  , [AddedBy] [VARCHAR](257) NOT NULL
  , [Reviewed] [DATETIME] NULL
  , [ReviewedBy] [VARCHAR](257) NULL
  , [SubGroup] VARCHAR(128) NULL)
