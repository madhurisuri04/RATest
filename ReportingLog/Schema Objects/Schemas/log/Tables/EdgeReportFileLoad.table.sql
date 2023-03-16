Create table [log].EdgeReportFileLoad
(
	EdgeReportFileLoadID bigint identity(1,1) not null,
	OrganizationID int not null,
	ReportType varchar(30) not null, 
	[FileName] varchar(50) not null,
	StartDateTime datetime2 not null,
	EndDateTime datetime2 null,
	DurationInMins smallint null,
	[Status] varchar (20) not null,
	IssuerID varchar(20) not null,
	LoadID bigint not null,
	ErroredOnPackage varchar(50) null,
	ErroredOnPackageTask varchar(1024) null,
	ErrorMessage varchar(2048) null,
	CreateUserID varchar(30) not null,
	CreateDateTime datetime2 not null,
	UpdateUserID varchar(30) null,
	UpdateDateTime datetime2 null
)
