CREATE TABLE [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary](
	[SummaryInterPartDRskAdjEDSPreliminaryID] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelYear] [int] NULL,
	[HICN] [varchar](12) NULL,
	[PartDRAFTProjected] [char](2) NULL,
	[MAO004ResponseID] [bigint] NULL,
	[PlanSubmissionDate] [date] NULL,
	[ServiceEndDate] [date] NULL,
	[FileImportID] [int] NULL,
	[MAO004ResponseDiagnosisCodeID] [bigint] NULL,
	[DiagnosisCode] [varchar](7) NULL,
	[DerivedPatientControlNumber] [varchar](50) NULL,
	[VoidIndicator] [int] NULL,
	[RiskAdjustable] [bit] NULL,
	[Deleted] [char](1) NULL,
	[RxHCCLabel] [varchar](50) NULL,
	[RxHCCNumber] [int] NULL
	);
