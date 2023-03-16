CREATE TABLE [Valuation].[AutoProcessAction] (
    [AutoProcessActionId] [INT] IDENTITY(1, 1) NOT NULL
  , [AutoProcessId] [INT] NOT NULL
  , [AutoProcessActionCatalogId] [INT] NOT NULL
  , [ClientId] [INT] NOT NULL
  , [ByPlan] [BIT] NOT NULL
  , [Phase] [DECIMAL](18, 3) NOT NULL
  , [Priority] [INT] NOT NULL
  , [DependAutoProcessActionCatalogId] [INT] NULL
  , [PopulateParameter] [BIT] NOT NULL
  , [ActiveBDate] [DATE] NOT NULL
  , [ActiveEDate] [DATE] NULL
  , [Added] [DATETIME] NULL
  , [AddedBy] [VARCHAR](257) NULL)