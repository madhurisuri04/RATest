CREATE TABLE dbo.tbl_Plan_Claims_Validation_rollup
(
	tbl_Plan_Claims_Validation_rollupID [int] identity NOT NULL,
	PlanIdentifier [smallint] NOT NULL,
	Claim_ID [int] NOT NULL,
	ClaimStatusID [Tinyint] NULL,
	ExclusionTypeID tinyint NULL,
	ExclusionID [int] NULL,
	RPCParameterLoggingID [BIGint] NULL,
	LoadDate [datetime2] NOT NULL, 
    [Provider_Type] VARCHAR(4) NULL
)