CREATE TABLE Valuation.FilteredAuditCWFDetail
    (
     [FilteredAuditCWFDetailId] [BIGINT] IDENTITY(1, 1)
                                      NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ProjectId] [INT] NULL
   , [SubProjectId] [INT] NULL
   , [SubProjectDescription] [VARCHAR](255) NULL
   , [ReviewName] [VARCHAR](50) NULL
   , [CurrentImageStatus] [VARCHAR](50) NULL
   , [ImageId] [INT] NULL
   , [HICN] [VARCHAR](12) NULL
   , [DOB] [DATE] NULL
   , [ProviderId] [VARCHAR](40) NULL
   , [DOSEndDt] [DATE] NULL
   , [DiagnosisCode] [VARCHAR](20) NULL
   , [ProcessedByBegin] [DATETIME] NULL
   , [ProcessedByEnd] [DATETIME] NULL
    )