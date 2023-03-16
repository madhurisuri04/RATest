CREATE TABLE [Valuation].[AutoProcessRunParameter] (
    [AutoProcessRunParameterId] [INT] IDENTITY(1, 1) NOT NULL
  , [AutoProcessRunId] [INT] NOT NULL
  , [AutoProcessActionCatalogId] [INT] NULL
  , [AutoProcessActionCatalogParameterId] [INT] NULL
  , [ParameterName] [VARCHAR](131) NULL
  , [ParameterValue] [VARCHAR](4096) NULL
  , [Output] [BIT] NULL
  , [DataType] [VARCHAR](128) NULL
  , [ByPlan] [BIT] NOT NULL)