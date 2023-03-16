Create table dbo.ReportingLogCategories
(
ReportingLogCategoriesID smallint identity(1,1) not null,
ApplicationCode	varchar(30) not null,
ProcessCode	varchar(12) not null,
Category	varchar(10) not null,
CreateUserID varchar(30) not null,  
CreatedDatetime datetime2 not null,
LastUpdateUserID	varchar(30) not null,
LastUpdateDateTime	datetime2 not null
)
