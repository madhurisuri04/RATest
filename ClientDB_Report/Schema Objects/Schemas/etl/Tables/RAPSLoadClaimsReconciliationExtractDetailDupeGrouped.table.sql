CREATE TABLE etl.RAPSLoadClaimsReconciliationExtractDetailDupeGrouped (
	ID			    BIGINT IDENTITY (1,1) NOT NULL
	,Claim_ID	    INT NULL
	,Plan_ID	    VARCHAR(5) NULL
	,LineOfBusiness	VARCHAR(100) NULL
)