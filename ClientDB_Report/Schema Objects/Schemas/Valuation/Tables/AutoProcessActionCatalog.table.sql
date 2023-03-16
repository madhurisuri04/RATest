CREATE TABLE [Valuation].[AutoProcessActionCatalog] (
    [AutoProcessActionCatalogId] [INT] IDENTITY(1, 1) NOT NULL
  , [AutoProcessStepName] [VARCHAR](128) NULL
  , [Description] [VARCHAR](512) NULL
  , [CommandDb] [VARCHAR](130) NULL
  , [CommandSchema] [VARCHAR](130) NULL
  , [CommandSTP] [VARCHAR](130) NULL
  , [ByPlan] [BIT] NOT NULL
  , [DependAutoProcessActionCatalogId] [INT] NULL
  , [PopulateParameter] [BIT] NOT NULL
  , [ActiveBDate] [DATE] NULL
  , [ActiveEDate] [DATE] NULL
  , [Added] [DATETIME] NULL
  , [AddedBy] [VARCHAR](257) NULL)