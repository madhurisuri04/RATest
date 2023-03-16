CREATE TABLE [dbo].[ExtractRequestParameter]
(
ExtractRequestParameterID bigint not null identity(1,1),
ExtractRequestID bigint not null,
ParameterName varchar(255) not null,
ParameterValue varchar(6000) null,
CreatedDate datetime2(7) not null,
CreatedUser varchar(500) not null,
UpdatedDate datetime2(7) not null,
UpdatedUser varchar(500) not null
)
 