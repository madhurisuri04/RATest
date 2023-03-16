CREATE TABLE [ref].[ExtractStatus]
(
	ExtractStatusID int not null identity(1,1),
	ExtractStatusCode varchar(50) not null,
	ExtractStatusDesc varchar(500) not null,
	CreatedDate datetime2(7) not null,
	CreatedUser varchar(500) not null
)