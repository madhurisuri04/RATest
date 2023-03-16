CREATE TABLE Valuation.ConfigStaticParameters
    (
     [ConfigStaticParametersId] [INT] IDENTITY(1, 1)
                                      NOT NULL
   , [AutoProcessId] [INT] NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessActionCatalogId] [INT] NULL
   , [ParameterName] [VARCHAR](131) NULL
   , [ParameterValue] [VARCHAR](8000) NULL
   , [Description] [VARCHAR](512) NULL
   , [ActiveBDate] [DATE] NULL
   , [ActiveEDate] [DATE] NULL
   , [Added] [DATETIME] NULL
                        DEFAULT (GETDATE())
   , [AddedBy] [VARCHAR](257) NULL
                              DEFAULT (USER_NAME())
   , [Reviewed] [DATETIME] NULL
   , [ReviewedBy] [VARCHAR](257) NULL
    )
