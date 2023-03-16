CREATE TABLE dbo.CNOperationsDashboard
(			ID							INT		IDENTITY(1,1) NOT NULL
			,OrganizationID				INT				NULL
			,ProjectType				VARCHAR(50)		NULL
			,ProjectID					INT				NULL
			,ProjectDescription			VARCHAR(100)		NULL
			,SubProjectID				INT				NULL
			,SubProjectDescription		VARCHAR(100)		NULL
			,Identified					INT				NULL
			,Approved					INT				NULL
			,ChartsRetrieved			INT				NULL
			,FirstPassCoded				INT				NULL
			,ReleaseReviewed			INT				NULL
			,Eligible					INT				NULL
			,Submitted					INT				NULL
			,LoadDate					DATETIME		NULL
)