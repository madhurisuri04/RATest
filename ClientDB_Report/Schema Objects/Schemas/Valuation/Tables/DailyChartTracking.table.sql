CREATE TABLE Valuation.DailyChartTracking
    (
     [DailyChartTrackingId] [INT] IDENTITY(1, 1)
                                  NOT NULL
   , [ClientId] [INT] NOT NULL
   , [AutoProcessRunId] [INT] NOT NULL
   , [ProjectID] [INT] NULL
   , [SubProjectId] [INT] NULL
   , [VeriskRequestID] [VARCHAR](20) NULL
   , [PlanId] [CHAR](5) NULL
   , [HICN] [VARCHAR](12) NULL
   , [MemberDOB] [DATE] NULL
   , [ProviderId] [VARCHAR](40) NULL
   , [SubprojectMedicalRecordID] [INT] NULL
   , [CodingCompleteDate] [DATE] NULL
   , [LoadDate] [DATETIME] NULL
    )