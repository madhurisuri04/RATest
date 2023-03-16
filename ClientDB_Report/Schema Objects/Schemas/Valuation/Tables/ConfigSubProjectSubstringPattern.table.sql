CREATE TABLE Valuation.ConfigSubProjectSubstringPattern
    (
     [SubProjectSubstringPatternId] [INT] IDENTITY(1, 1)
                                          NOT NULL
   , [ClientId] [INT] NOT NULL
   , [ProjectId] [INT] NOT NULL
   , [SubProjectId] [INT] NOT NULL
   , [SubprojectDescription] [VARCHAR](255) NULL
   , [Source01] [NVARCHAR](255) NULL
   , [ProviderType] [CHAR](2) NULL
   , [Type] [VARCHAR](15) NULL
   , [ProjectCategory] [VARCHAR](85) NULL
   , [SubProjectSortOrder] [SMALLINT] NULL
   , [ActiveBDate] [DATE] NOT NULL
   , [ActiveEDate] [DATE] NULL
   , [FilteredAuditActiveBDate] [DATE] NULL
   , [FilteredAuditActiveEDate] [DATE] NULL
   , [OnShoreOffShore] [CHAR](1) NULL
   , [ID_VAN] [CHAR](1) NULL
   , [PMH] [CHAR](1) NULL
   , [MissingSignature] [CHAR](1) NULL
   , [Filler01] [CHAR](1) NULL
   , [Filler02] [CHAR](1) NULL
   , [UniquePattern] [VARCHAR](255) NULL
   , [PCNStringPattern] [VARCHAR](255) NULL
   , [FailureReason] [VARCHAR](20) NULL
   , [Added] [DATETIME] NOT NULL
   , [AddedBy] [VARCHAR](257) NOT NULL
   , [Reviewed] [DATETIME] NULL
   , [ReviewedBy] [VARCHAR](257) NULL
   , [Payment_Year] [CHAR](4) NULL
   , [SubprojectIdBPosition] [INT] NULL
   , [SubprojectIdEPosition] [INT] NULL
   , [SubprojectIdLength] [INT] NULL
   , [ProviderIdBPosition] [INT] NULL
   , [ProviderIdLength] [INT] NULL
   , [ProviderIdEPosition] [INT] NULL
  
   , [UpdateStatement] [VARCHAR](4000) NULL
      
    )
