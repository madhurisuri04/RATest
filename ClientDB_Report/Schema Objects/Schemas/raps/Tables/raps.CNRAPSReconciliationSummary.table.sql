CREATE TABLE [raps].[CNRAPSReconciliationSummary] (
	ID											BIGINT IDENTITY (1, 1) NOT NULL
	,LoadedCount								INT NULL
	,FailedValidationCount						INT NULL
	,PassedValidationCount						INT NULL
	,DuplicateCount								INT NULL
	,BatchCreatedCount							INT NULL
	,FileCreatedCount							INT NULL
	,SubmittedCount								INT NULL
	,FERASAcceptedCount							INT NULL
	,FERASRejectedCount							INT NULL
	,RAPSReturnRejectedDuplicateCount			INT NULL
	,RAPSReturnRejectedNonDuplicateCount		INT NULL
	,RAPSReturnAcceptedCount					INT NULL
	,CNRAPSImportID								INT NULL
	,ProcessedDate								DATETIME NULL
	,LineOfBusiness								VARCHAR(20) NULL
	,PlanID										VARCHAR(5) NULL
	,Created									DATETIME NOT NULL
	,UserID										VARCHAR(50) NOT NULL
	,LoadDate									DATETIME NOT NULL
)