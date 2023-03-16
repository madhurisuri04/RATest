CREATE TABLE Valuation.LogConfigStaticParameters
    (
     [LogConfigStaticParametersId] [INT] IDENTITY(1, 1)
                                         NOT NULL
   , [Action] [CHAR](1) NULL
   , [ConfigStaticParametersId] [INT] NULL
   , [AutoProcessId] [INT] NULL 
   , [AutoProcessId_old] [INT] NULL 
   , [ClientId] [INT] NULL
   , [ClientId_old] [INT] NULL
   , [AutoProcessActionCatalogId] [INT] NULL
   , [AutoProcessActionCatalogId_old] [INT] NULL
   , [ParameterName] [VARCHAR](131) NULL
   , [ParameterName_old] [VARCHAR](131) NULL
   , [ParameterValue] [VARCHAR](8000) NULL
   , [ParameterValue_old] [VARCHAR](8000) NULL
   , [Description] [VARCHAR](512) NULL
   , [Description_old] [VARCHAR](512) NULL
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
   , [EditedBy] [VARCHAR](257) NULL
    )
