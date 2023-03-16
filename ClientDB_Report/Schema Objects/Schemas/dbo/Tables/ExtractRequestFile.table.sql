CREATE TABLE [dbo].[ExtractRequestFile]
(
ExtractRequestFileID bigint not null identity(1,1),
ExtractRequestID bigint not null,
ExtractFileID bigint not null,
RequestFileName varchar(500) not null,
CreatedDate datetime2(7) not null,
CreatedUser varchar(500) not null,
UpdatedDate datetime2(7) not null,
UpdatedUser varchar(500) not null
)