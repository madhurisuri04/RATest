CREATE TABLE etl.PartDNewHCCOutputDParameter
(
	[PartDNewHCCOutputDParameterID] BIGINT IDENTITY(1, 1) NOT NULL,
	[PaymentYear] [int] NOT NULL,
	[ModelYear] [int] NULL,
	[MemberMonths] [int] NULL,
	[ProcessedByStartDate] [datetime] NULL,
	[ProcessedByEndDate] [datetime] NULL,
	[ProcessedByFlag] [char](1) NULL,
	[EncounterSource] [varchar](20) NULL,
	[PlanID] [varchar](5) NULL,
	[HICN] [varchar](15) NULL,
	[RAFactorType] [char](2) NULL,
	[RxHCC] [varchar](20) NULL,
	[HCCDescription] [varchar](255) NULL,
	[RxHCCFactor] [decimal](20, 4) NULL,
	[HierarchyRxHCC] [varchar](20) NULL,
	[HierarchyRxHCCFactor] [decimal](20, 4) NULL,
	[PreAdjustedFactor] [decimal](20, 4) NULL,
	[AdjustedFinalFactor] [decimal](20, 4) NULL,
	[HCCProcessedPCN] [varchar](50) NULL,
	[HierarchyHCCProcessedPCN] [varchar](50) NULL,
	[UniqueConditions] [int] NULL,
	[MonthsInDCP] [int] NULL,
	[BidAmount] [money] NULL,
	[EstimatedValue] [money] NULL,
	[RollForwardMonths] [int] NULL,
	[AnnualizedEstimatedValue] [money] NULL,
	[PBP] [varchar](3) NULL,
	[SCC] [varchar](5) NULL,
	[ProcessedPriorityProcessedByDate] [datetime] NULL,
	[ProcessedPriorityThruDate] [datetime] NULL,
	[ProcessedPriorityDiag] [varchar](20) NULL,
	[ProcessedPriorityFileID] [varchar](18) NULL,
	[ProcessedPriorityRAC] [char](1) NULL,
	[ProcessedPriorityRAPSSourceID] [varchar](50) NULL,
	[DOSPriorityProcessedByDate] [datetime] NULL,
	[DOSPriorityThruDate] [datetime] NULL,
	[DOSPriorityPCN] [varchar](50) NULL,
	[DOSPriorityDiag] [varchar](20) NULL,
	[DOSPriorityFileID] [varchar](18) NULL,
	[DOSPriorityRAC] [char](1) NULL,
	[DOSPriorityRAPSSourceID] [varchar](50) NULL,
	[ProcessedPriorityICN] [bigint] NULL,
	[ProcessedPriorityEncounterID] [bigint] NULL,
	[ProcessedPriorityReplacementEncounterSwitch] [char](1) NULL,
	[ProcessedPriorityClaimID] [varchar](50) NULL,
	[ProcessedPrioritySecondaryClaimID] [varchar](50) NULL,
	[ProcessedPrioritySystemSource] [varchar](30) NULL,
	[ProcessedPriorityRecordID] [varchar](80) NULL,
	[ProcessedPriorityVendorID] [varchar](100) NULL,
	[ProcessedPrioritySubProjectID] [int] NULL,
	[ProcessedPriorityMatched] [char](1) NULL,
	[DOSPriorityICN] [bigint] NULL,
	[DOSPriorityEncounterID] [bigint] NULL,
	[DOSPriorityReplacementEncounterSwitch] [char](1) NULL,
	[DOSPriorityClaimID] [varchar](50) NULL,
	[DOSPrioritySecondaryClaimID] [varchar](50) NULL,
	[DOSPrioritySystemSource] [varchar](30) NULL,
	[DOSPriorityRecordID] [varchar](80) NULL,
	[DOSPriorityVendorID] [varchar](100) NULL,
	[DOSPrioritySubProjectID] [int] NULL,
	[DOSPriorityMatched] [char](1) NULL,
	[ProviderID] [varchar](40) NULL,
	[ProviderLast] [varchar](55) NULL,
	[ProviderFirst] [varchar](55) NULL,
	[ProviderGroup] [varchar](80) NULL,
	[ProviderAddress] [varchar](100) NULL,
	[ProviderCity] [varchar](30) NULL,
	[ProviderState] [char](2) NULL,
	[ProviderZip] [varchar](13) NULL,
	[ProviderPhone] [varchar](15) NULL,
	[ProviderFax] [varchar](15) NULL,
	[TaxID] [varchar](55) NULL,
	[NPI] [varchar](20) NULL,
	[SweepDate] [datetime] NULL,
	[AgedStatus] [varchar](20) NULL,
	[ProcessedPriorityMAO004ResponseDiagnosisCodeID] [bigint] NULL,
	[DOSPriorityMAO004ResponseDiagnosisCodeID] [bigint] NULL,
	[ProcessedPriorityMatchedEncounterICN] [bigint] NULL,
	[DOSPriorityMatchedEncounterICN] [bigint] NULL,
	[ReportOutput] CHAR(1) NULL,
	UserID VARCHAR(128) NOT NULL,
	LoadDate DATETIME NOT NULL
)