CREATE TABLE [raps].[QRAPSReconciliationSummary] (
	ID											BIGINT IDENTITY (1, 1) NOT NULL
	,RowsReceivedCount							INT NULL
	,LoadedCount								INT NULL
	,FailedValidationCount						INT NULL
	,PassedValidationCount						INT NULL
	,DuplicateRowsCount							INT NULL
	,BatchCreatedCount							INT NULL
	,FileCreatedCount							INT NULL
	,SubmittedCount								INT NULL
	,FERASAcceptedCount							INT NULL
	,FERASRejectedCount							INT NULL
	,RAPSReturnRejectedDuplicateCount			INT NULL
	,RAPSReturnRejectedNonDuplicateCount		INT NULL
	,RAPSReturnAcceptedCount					INT NULL
	,OriginalFileName							VARCHAR(255) NULL
	,ReceivedDate								DATETIME NULL
	,SplitFileName								VARCHAR(255) NULL
	,LineOfBusiness								VARCHAR(20) NULL
	,PlanID										VARCHAR(5) NULL
	,Created									DATETIME NOT NULL
	,UserID										VARCHAR(50) NOT NULL
	,LoadDate									DATETIME NOT NULL
	,FileType									VARCHAR(20) NULL
)