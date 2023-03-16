CREATE TABLE [dbo].[Extract]
(
	ExtractID bigint not null,
	AppCode varchar(30) null,
	ExtractName varchar(500) not null,
	ExtractGroup varchar(500) null,
	ActiveFlag bit not null,
	CreatedDate datetime2(7) not null,
	CreatedUser varchar(500) not null,
	UpdatedDate datetime2(7) not null,
	UpdatedUser varchar(500) not null
)
