CREATE TABLE [Valuation].[AutoProcessActionCatalogParameter] (
    [AutoProcessActionCatalogParameterId] [INT] IDENTITY(1, 1) NOT NULL
  , [AutoProcessActionCatalogId] [INT] NULL
  , [ParameterName] [VARCHAR](129) NULL
  , [OrdPosition] [INT] NULL
  , [DataType] [VARCHAR](128) NULL
  , [MaxLength] [INT] NULL
  , [Nullable] [BIT] NULL
  , [Output] [BIT] NULL
  , [ParameterMap] [VARCHAR](133) NULL)