/*  
	Created By:		Dianne Barba
	TFS:			17141
	Description:	Standard proc to log messages to ProcessLog
	Date:			20140106
	Notes:			Lives in CN client level and reporting DBs
	
	Input parms:
		ProcessID (can be null)
		ProcessDriverID (can be null)
		ProcessEntityID (can be null)
		ProcName (can not be null)
		LogMessage (can not be null)
		LogMessageExtended (can be null)
		LogMessageType (can be null, will default to I(nfo)
	
	Modifications:

*/

-- exec dbo.messenger null, null, null, 'ETL_RADVAssemble', 'test message', null, 'W'

--alter procedure messenger
create procedure messenger
( 
	@ProcessID int = null, 
	@ProcessDriverID int = null, 
	@ProcessEntityID int = null, 
	@ProcName varchar(100),
	@LogMessage varchar(255),
	@LogMessageExtended varchar(500),
	@LogMessageType char(1) = null
)
as

	select @LogMessageType = case when ISNULL(@logmessagetype,'') = '' then 'I' else @LogMessageType end 
		
	insert into dbo.ProcessLog (ProcessID, ProcessDriverID, ProcessEntityID, ProcName, LogMessage, LogMessageExtended, LogMessageType)
	values (@ProcessID, @ProcessDriverID, @ProcessEntityID, @ProcName, @LogMessage, @LogMessageExtended, @LogMessageType)


