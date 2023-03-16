CREATE TABLE [dbo].[ExtractRequest]
(
	ExtractRequestID bigint not null identity(1,1),
	OrganizationID int not null,
	AppCode varchar(30) not null,
	ExtractID bigint not null,
	RequestUserID int not null,
	ExtractStatusID int not null,
	CreatedDate datetime2(7) not null,
	CreatedUser varchar(500) not null,
	UpdatedDate datetime2(7) not null,
	UpdatedUser varchar(500) not null
)
