create table [dbo].[CWFDetails]
(
    [ID] [int] identity(1, 1) not null
  , [LineOfBusinessID] [int] null
  , [ProjectID] [int] not null
  , [ProjectDescription] [varchar](100) null
  , [SubprojectID] [int] null
  , [SubProjectDescription] [varchar](100) null
  , [SubprojectMedicalRecordID] [int] null
  , [HICN] [varchar](50) null  
  , [MemberID] [varchar](50) null
  , [MemberName] [varchar](100) null
  , [MemberDOB] [date] null
  , [PlanID] [char](5) null
  , [ProviderID] [varchar](40) null
  , [ProviderType] [varchar](50) null
  --[VeriskRequestID]  [varchar](20) NULL,
  , [RetrievalRequestID] [varchar](50) null
  , [ListRank] [int] null
  , [ListChaseID] [varchar](50) null
  , [Stratification] [varchar](30) null
  , [SuspectSource] [varchar](50) null
  , [LineOfBusinessPlanID] [varchar](50) null
  , [State] [varchar](15) null
  , [Plan Metal Level] [varchar](2) null
  , [Cohort] [varchar](30) null
  , [PBP] [char](3) null
  , [MedicalRecordImageID] [int] not null
  , [CurrentImageStatus] [varchar](50) null
  , [ImageType] [varchar](15) null
  , [DiagnosisID] [int] null
  , [DiagnosisCode] [varchar](8) null
  , [ICDVersion] [varchar](2) null
  , [BegPage] [int] null
  , [EndPage] [int] null
  , [DOSStartDt] [date] null
  , [DOSEndDt] [date] null
  , [CodingProviderID] [varchar](40) null
  , [CodingProviderType] [varchar](50) null
  , [RiskAssessmentCode] [varchar](1) null
  , [CNCodingDiagnosisStatus] [varchar](100) null
  , [OverallDiagnosisStatus] [varchar](100) null
  , [OldModel_PartC_HCCNumber] [int] null
  , [OldModel_PartC_HCCDescription] [varchar](255) null
  , [NewModel_PartC_HCCNumber] [int] null
  , [NewModel_PartC_HCCDescription] [varchar](255) null
  , [PartD_HCCNumber] [int] null
  , [PartD_HCCDescription] [varchar](255) null
  , [Commercial_HCCNumber] [int] null
  , [Commercial_HCCDescription] [varchar](255) null
  , [DOSFailureReason] [varchar](50) null
  , [DiagnosisFailureReason] [varchar](50) null
  , [ChartFailureReason] [varchar](50) null
  , [DateReceived] [datetime] null
  , [FirstPassCodedDate] [datetime] null
  , [FirstPassCoderID] [int] null
  , [FirstPassCoderName] [varchar](100) null
  , [SubmissionsReviewDate] [datetime] null
  , [SubmissionsReviewCoderID] [int] null
  , [SubmissionsReviewCoder] [varchar](100) null
  , [CodingCompleteDate] [datetime] null
  , [ReleasedDate] [datetime] null
  , [QAReviewDate] [datetime] null
  , [QAReviewerID] [int] null
  , [QAReviewer] [varchar](100) null
  , [AuditTypeID] [tinyint] null
  , [AuditDate] [datetime] null
  , [AuditReviewerID] [int] null
  , [AuditReviewer] [varchar](100) null
  , [CMSAcceptedDate] [date] null
  , [CMSRejectedDate] [date] null
  , [CMSDeleteAcceptedDate] [date] null
  , [CMSDeleteRejectedDate] [date] null
  , [LoadDate] [datetime] null
  , [RevenueGeneratingPartC] [int] null
  , [RevenueGeneratingPartD] [int] null
  , [RequestID] [varchar](20) null
  , [ProviderNPI] [varchar](100) null
  , [ProviderTIN] [varchar](100) null
  , [ProviderLastName] [varchar](120) null
  , [ProviderFirstName] [varchar](70) null
  , [CodingDiagRevenueGeneratingPartC] [int] null
  , [CodingDiagRevenueGeneratingPartD] [int] null
  , [ESRD_HCCNumber] [int] null
  , [ESRD_HCCDescription] [varchar](255) null
  , [RevenueGeneratingESRD] [int] null
  , [CodingDiagRevenueGeneratingESRD] [int] null
  , [CWFDClusterKey] [varbinary](8000) NULL
)

go