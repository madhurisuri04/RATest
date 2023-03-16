CREATE TABLE etl.RAPSLoadClaimsReconciliationDetail (
	ID BIGINT IDENTITY (1,1) NOT NULL
	,PlanIdentifier		SMALLINT NULL
	,HICN				VARCHAR(25) NULL
	,Claim_ID			INT NULL
	,From_Date1			VARCHAR(8) NULL
	,Thru_date1			VARCHAR(8) NULL
	,Delete_Ind1		CHAR(1) NULL
	,EXPORTED_FILEID	VARCHAR(10) NULL
	,RAPSStatusID		TINYINT NULL
	,OutboundFileID		VARCHAR(10) NULL
	,Plan_ID			VARCHAR(5) NULL
	,ClaimSource		VARCHAR(50) NULL
	,ImportFileName		VARCHAR(255) NULL
	,ClaimStatusID		TINYINT NULL
	,FileImportID		INT NULL
	,OriginalFileName	VARCHAR(255) NULL
	,OriginalFileDate	DATETIME NULL
    ,LineOfBusiness	    VARCHAR(100) NULL
)