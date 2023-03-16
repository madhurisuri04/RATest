create table [dbo].[ProcessLog]
(
	ID int identity(1,1),
	ProcessID int null,
	ProcessDriverID int null,
	ProcessEntityID int null,
	CreationDateTime datetime2 default getdate(),	
	ProcName varchar(100),
	LogMessage varchar(250),
	LogMessageExtended varchar(500),
	LogMessageType char(1)
)
