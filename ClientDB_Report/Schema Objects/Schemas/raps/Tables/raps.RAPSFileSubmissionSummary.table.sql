CREATE TABLE raps.RAPSFileSubmissionSummary (
	ID										BIGINT IDENTITY(1, 1) NOT NULL
	,PlanID									VARCHAR(5) NULL
	,[Source]								VARCHAR(256) NULL
	,SubmittedFileName						VARCHAR(100) NULL
	,SubmitterID							VARCHAR(6) NULL
	,SubmittedDate							SMALLDATETIME NULL
	,SubmittedFileID						VARCHAR(10) NULL
	,SubmittedFileState						VARCHAR(15) NULL
	,TotalClustersCount						INT NULL
	,InpatientCount							INT NULL
	,OutpatientCount						INT NULL
	,PhysicianCount							INT NULL
	,DuplicateStayersCount					INT NULL
	,DuplicateNewMemberCount				INT NULL
	,RAPSReturnAcceptedCount				INT NULL
	,RAPSReturnRejectedNonDuplicateCount	INT NULL
	,Created								DATETIME NOT NULL
	,UserID									VARCHAR(50) NOT NULL
	,LoadDate								DATETIME NOT NULL
)