Create Table dbo.tbl_MemberDemographics_rollup
( 
	tbl_MemberDemographics_rollupID	int Identity NOT NULL,
	PlanIdentifier			smallint Not Null,
	MemberDemographicsID	Int Not NULL,
	HICN					varchar(15) NULL,
	MemberID				varchar(18) NULL,
	[LastName]				varchar(50) NULL,
	[FirstName]				varchar(50) NULL,
	Gender					varchar(1) NULL,
	DOB						datetime NULL,
	ProviderID				varchar(50) NULL,
	EnrollmentDate			datetime NULL,
	TerminationDate			datetime NULL,
	LastUpdated				datetime NULL,
	SourceTable				varchar(50) NULL,
	IsComplete				bit NULL,
	MemberIDReceived		varchar(12) NULL
)