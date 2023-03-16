CREATE TABLE [dbo].[ExtractFile]
(
ExtractFileID bigint not null identity(1,1) ,
ExtractID bigint not null ,
ExtractFileName varchar(500) not null,
ExtractCodeType varchar(500) not null,
ExtractCodeName varchar(128) not null,
CreatedDate datetime2(7) not null,
CreatedUser varchar(500) not null,
UpdatedDate datetime2(7) not null,
UpdatedUser varchar(500) not null,
UseClientDB tinyint not null default 0
)
