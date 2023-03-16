Create Table RADVMember
(
	ID int identity,
	HICN varchar (20), 
	MemberFirstName varchar (50), 
	MemberLastName varchar (100), 
	MemberDOB varchar (20), 
	RADVPlanName char (5),
	RADVYear char (4),
	CurrentPlanName char (5),
	PBP char (3),
	SCC char (5),
	RAFactorType char (2),
	BidAmount float,
	MemberMonths int,
	RBBHIC varchar (20),
	MAOrgName varchar (255), 
	MaskedH# varchar (5), 
	EnrolleeID varchar (10),
	SubProjectID int,
	SubProjectDescription varchar (255),
	CreationDateTime datetime2 default getdate()
)