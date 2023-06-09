CREATE TABLE rev.PartDNewHCCOutputMParameter
(
	PartDNewHCCOutputMParameterID BIGINT IDENTITY(1,1) NOT NULL,
	PaymentYear INT NOT NULL,
	ModelYear INT NULL,
	PaymentStartDate DATETIME NULL,
	ProcessedByStartDate DATETIME NULL,
	ProcessedByEndDate DATETIME NULL,
	ProcessedByFlag CHAR(1) NULL,
	EncounterSource VARCHAR(20) NULL,
	PlanID VARCHAR(5) NULL,
	HICN VARCHAR(15) NULL,
	RAFactorType CHAR(2) NULL,
	RxHCC VARCHAR(20) NULL,
	HCCDescription VARCHAR(255) NULL,
	RxHCCFactor DECIMAL(20,4) NULL,
	HierarchyRxHCC VARCHAR(20) NULL,
	HierarchyRxHCCFactor DECIMAL(20,4) NULL,
	PreAdjustedFactor DECIMAL(20,4) NULL,
	AdjustedFinalFactor DECIMAL(20,4) NULL,
	HCCProcessedPCN VARCHAR(50) NULL,
	HierarchyHCCProcessedPCN VARCHAR(50) NULL,
	UniqueConditions INT NULL,
	MonthsInDCP INT NULL,
	BidAmount MONEY NULL,
	EstimatedValue MONEY NULL,
	RollForwardMonths INT NULL,
	ActiveIndicatorForRollForward CHAR(1) NULL,
	PBP VARCHAR(3) NULL,
	SCC VARCHAR(5) NULL,
	ProcessedPriorityProcessedByDate DATETIME NULL,
	ProcessedPriorityThruDate DATETIME NULL,
	ProcessedPriorityDiag VARCHAR(20) NULL,
	ProcessedPriorityFileID VARCHAR(18) NULL,
	ProcessedPriorityRAC CHAR(1) NULL,
	ProcessedPriorityRAPSSourceID VARCHAR(50) NULL,
	DOSPriorityProcessedByDate DATETIME NULL,
	DOSPriorityThruDate DATETIME NULL,
	DOSPriorityPCN VARCHAR(50) NULL,
	DOSPriorityDiag VARCHAR(20) NULL,
	DOSPriorityFileID VARCHAR(18) NULL,
	DOSPriorityRAC CHAR(1) NULL,
	DOSPriorityRAPSSourceID VARCHAR(50) NULL,
	ProcessedPriorityICN BIGINT NULL,
	ProcessedPriorityEncounterID BIGINT NULL,
	ProcessedPriorityReplacementEncounterSwitch CHAR(1) NULL,
	ProcessedPriorityClaimID VARCHAR(50) NULL,
	ProcessedPrioritySecondaryClaimID VARCHAR(50) NULL,
	ProcessedPrioritySystemSource VARCHAR(30) NULL,
	ProcessedPriorityRecordID VARCHAR(80) NULL,
	ProcessedPriorityVendorID VARCHAR(100) NULL,
	ProcessedPrioritySubProjectID INT NULL,
	ProcessedPriorityMatched CHAR(1) NULL,
	DOSPriorityICN BIGINT NULL,
	DOSPriorityEncounterID BIGINT NULL,
	DOSPriorityReplacementEncounterSwitch CHAR(1) NULL,
	DOSPriorityClaimID VARCHAR(50) NULL,
	DOSPrioritySecondaryClaimID VARCHAR(50) NULL,
	DOSPrioritySystemSource VARCHAR(30) NULL,
	DOSPriorityRecordID VARCHAR(80) NULL,
	DOSPriorityVendorID VARCHAR(100) NULL,
	DOSPrioritySubProjectID INT NULL,
	DOSPriorityMatched CHAR(1) NULL,
	ProviderID VARCHAR(40) NULL,
	ProviderLast VARCHAR(55) NULL,
	ProviderFirst VARCHAR(55) NULL,
	ProviderGroup VARCHAR(80) NULL,
	ProviderAddress VARCHAR(100) NULL,
	ProviderCity VARCHAR(30) NULL,
	ProviderState CHAR(2) NULL,
	ProviderZip VARCHAR(13) NULL,
	ProviderPhone VARCHAR(15) NULL,
	ProviderFax VARCHAR(15) NULL,
	TaxID VARCHAR(55) NULL,
	NPI VARCHAR(20) NULL,
	SweepDate DATETIME NULL,
	PopulatedDate DATETIME NULL,
	AgedStatus VARCHAR(20) NULL,
	UserID VARCHAR(128) NOT NULL,
	LoadDate DATETIME NOT NULL,
	ProcessedPriorityMAO004ResponseDiagnosisCodeID BIGINT NULL,
    DOSPriorityMAO004ResponseDiagnosisCodeID BIGINT NULL,
    ProcessedPriorityMatchedEncounterICN BIGINT NULL,
    DOSPriorityMatchedEncounterICN BIGINT NULL,
	LastAssignedHICN VARCHAR (12) NULL
) ON  [pscheme_SummPY](PaymentYear)