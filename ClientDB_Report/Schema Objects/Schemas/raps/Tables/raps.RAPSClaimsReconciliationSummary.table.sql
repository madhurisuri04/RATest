CREATE TABLE raps.RAPSClaimsReconciliationSummary (
	ID											BIGINT IDENTITY(1, 1) NOT NULL
	,RowsReceivedCount							INT NULL
	,DuplicateRowsCount							INT NULL
	,LoadedCount								INT NULL
	,LineDiag1To10Count							INT NULL
	,LineDiag11To20Count						INT NULL
	,LineDiag21To30Count						INT NULL
	,RiskAdjustableCount						INT NULL
	,PendingRiskAdjustmentReviewCount			INT NULL
	,NonRiskAdjustableCount						INT NULL
	,DuplicateCount								INT NULL
	,BatchCreatedCount							INT NULL
	,FileCreatedCount							INT NULL
	,SubmittedCount								INT NULL
	,FERASAcceptedCount							INT NULL
	,FERASRejectedCount							INT NULL
	,RAPSReturnRejectedNonDuplicateCount		INT NULL
	,RAPSReturnRejectedDuplicateCount			INT NULL
	,RAPSReturnAcceptedCount					INT NULL
	,PlanID										VARCHAR(5) NULL
	,OriginalFileName							VARCHAR(255) NULL
	,OriginalFileDate							DATETIME NULL
	,SplitFileName								VARCHAR(255) NULL
	,ClaimSource								VARCHAR(50) NULL
	,Created									DATETIME NOT NULL
	,UserID										VARCHAR(50) NOT NULL
	,LoadDate									DATETIME NOT NULL
	,LineOfBusiness								VARCHAR(100) NULL
	)