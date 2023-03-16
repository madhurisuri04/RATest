

Create Function [dbo].[fn_AllClientDBsOnline]()
	Returns bit
As
/*********************************************************************************
Health Risk Partners
Author:			Brett A. Burnam
Date:			07/27/2011

Purpose:		To determine if all databases for a given client exist and are online.
				The return value of 1 indicates that all of the client's databases are
				online.  A zero return value can mean one of four things 1) that the 
				HRPReporting database is not online 2) that the 'ClientLevel' database
				is not online, 3) that one of the Plan level databases is not online,
				4) that the Client does not have any Plan level databases associated 
				with the client

Parameters:		none

Assumptions:	-The HRPReporting and HRPClientGlobal databases must exist, and be in the 
				'Online' status
				-That the Client has at least one Plan level database
				-That the Client has a ClientLevel database
			

Modifications:

*********************************************************************************/
Begin 

	-------------------------------------------------------------------------
	-- Declare variables
	-------------------------------------------------------------------------
	Declare @PatIndexValue				tinyint,
			@ClientName					varchar(100),
			@DatabaseCnt				tinyint,
			@PlanDatabaseCnt			smallint
			
	Declare @PlanDatabase Table
		(state	tinyint NULL)

	-------------------------------------------------------------------------
	-- Set variable values
	-------------------------------------------------------------------------
	Set @PatIndexValue = Patindex('%_Report',DB_NAME())
	
	-------------------------------------------------------------------------
	-- Determine if the function is working within a "_Report" database
	-------------------------------------------------------------------------	
	If @PatIndexValue = 0
		Return 0
		
	
	Set @ClientName = left(DB_NAME(),@PatIndexValue-1)
	
	-------------------------------------------------------------------------
	-- check that the HRPReporting and HRPClientGlobal databases are online
	-------------------------------------------------------------------------	
	Set @DatabaseCnt = (Select count(*) 
						From master.sys.databases 
						Where name In ('HRPReporting','HRPClientGlobal')
						And [state] = 0)
						
	If @DatabaseCnt <> 2
		Return 0
				
	-------------------------------------------------------------------------
	-- populate dataset of plan level databases and check that the "ClientLevel" db exists
	-------------------------------------------------------------------------	
	Insert Into @PlanDatabase
		([state])	
	Select db.[state]
	From [$(HRPReporting)].dbo.tbl_Clients c with (nolock)
	Inner Join [$(HRPReporting)].dbo.xref_Client_Connections xref with (nolock)
		On c.Client_ID = xref.Client_ID
	Inner Join  [$(HRPReporting)].dbo.tbl_Connection conn with (nolock)
		On xref.Connection_ID = conn.Connection_ID
		And Patindex('%' + @ClientName + '%',conn.Connection_Name ) <> 0		
	Left Outer Join master.sys.databases db
		On conn.Connection_Name = db.name
		And db.[state] = 0
	Where Exists (Select 1
				  From master.sys.databases db2
				  Where db2.name = c.Client_DB
				  And db2.[state] = 0)
				  			
	Set @PlanDatabaseCnt = @@ROWCOUNT	

	-------------------------------------------------------------------------
	-- Handle Clients without any Online databases
	-------------------------------------------------------------------------		
	If @PlanDatabaseCnt < 1
		Return 0

	-------------------------------------------------------------------------
	-- Determine if any of the source databases are offline or do not exist
	-------------------------------------------------------------------------
	If Exists (Select 1 From @PlanDatabase Where IsNull(state,7) <> 0)
		Return 0		
		
	-------------------------------------------------------------------------
	-- Indicate that all of the client's databases are online
	-------------------------------------------------------------------------	
	Return 1

End	

GO


