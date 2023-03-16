CREATE TABLE [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary](
	[tbl_Intermediate_RskAdj_EDS_PreliminaryId] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelYear] [int] NULL,
	[HICN] [varchar](12) NULL,
	[PartCRAFTProjected] [char](2) NULL,
	[MAO004ResponseID] [bigint] NULL,
	[DiagnosisCode] [varchar](7) NULL, 
	[PlanSubmissionDate] [date] NULL,
	[ServiceEndDate] [date] NULL,
	[FileImportID] [int] NULL,
	[MAO004ResponseDiagnosisCodeID] [bigint] NULL,
	[DerivedPatientControlNumber] [varchar](50) NULL,
	[Void_Indicator] [int] NULL,
	[RiskAdjustable] [bit] NULL,
	[Deleted] [varchar](1) NULL,
	[HCC_Label] [nvarchar](255) NULL,
	[HCC_Number] [int] NULL
	);