CREATE TABLE [Out].[tbl_Summary_RskAdj_EDS_Preliminary](
	[tbl_Summary_RskAdj_EDS_PreliminaryId] [bigint] IDENTITY(1,1) NOT NULL,
	[PlanIdentifier] [int] NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelYear] [int] NULL,
	[HICN] [varchar](12) NULL,
	[PartCRAFTProjected] [char](2) NULL,
	[MAO004ResponseID] [bigint] NULL,
	[stgMAO004ResponseID] [bigint] NULL,
	[ContractID] [varchar](5) NULL,
	[SentEncounterICN] [bigint] NULL,
	[ReplacementEncounterSwitch] [char](1) NULL,
	[SentICNEncounterID] [bigint] NULL,
	[OriginalEncounterICN] [bigint] NULL,
	[OriginalICNEncounterID] [bigint] NULL,
	[PlanSubmissionDate] [date] NULL,
	[ServiceStartDate] [date] NULL,
	[ServiceEndDate] [date] NULL,
	[ClaimType] [char](1) NULL,
	[FileImportID] [int] NULL,
	[LoadID] [bigint] NULL,
	[LoadDate] [datetime] NOT NULL,
	[SentEncounterRiskAdjustableFlag] [char](1) NULL,
	[RiskAdjustableReasonCodes] [char](1) NULL,
	[OriginalEncounterRiskAdjustableFlag] [char](1) NULL,
	[MAO004ResponseDiagnosisCodeID] [bigint] NULL,
	[DiagnosisCode] [varchar](7) NULL,
	[DiagnosisICD] [char](1) NULL,
	[DiagnosisFlag] [bit] NOT NULL,
	[IsDelete] [bit] NULL,
	[ClaimID] [varchar](50) NULL,
	[EntityDiscriminator] [varchar](2) NULL,
	[BaseClaimID] [varchar](50) NULL,
	[SecondaryClaimID] [varchar](50) NULL,
	[ClaimIndicator] [char](1) NULL,
	[RecordID] [varchar](80) NULL,
	[SystemSource] [varchar](30) NULL,
	[VendorID] [varchar](100) NULL,
	[MedicalRecordImageID] [int] NULL,
	[SubProjectMedicalRecordID] [int] NULL,
	[SubProjectID] [int] NULL,
	[SubProjectName] [varchar](100) NULL,
	[SupplementalID] [bigint] NULL,
	[DerivedPatientControlNumber] [varchar](50) NULL,
	[Void_Indicator] [int] NULL,
	[Voided_by_MAO004ResponseDiagnosisCodeID] [int] NULL,
	[RiskAdjustable] [bit] NULL,
	[Deleted] [varchar](1) NULL,
	[HCC_Label] [nvarchar](255) NULL,
	[HCC_Number] [int] NULL,
	[LoadDateTime] [datetime] NOT NULL,
	[Matched] [char](1) NULL
	)
ON [pscheme_SummPY](PaymentYear)