create view vw_ClientConnection
as
	select top 100 percent l.Client_ID, l.Client_Name, l.Client_DB
		, l.DB_Server, l.Run_Import_Pickup, l.MergeRAPSsubmissions
		, c.Connection_Name, c.Run_Imports as PL_Run_Imports
		, c.Database_Server_Name, c.Server_To_Process_Windows_Services
	from	tbl_connection c WITH(NOLOCK)
	left outer join	xref_Client_Connections x WITH(NOLOCK) on c.Connection_ID = x.Connection_ID
	left outer join	tbl_clients l WITH(NOLOCK) on x.Client_ID = l.Client_ID
	where 1 = 1 and l.Client_ID is not null
	order by l.Client_Name, c.Connection_Name
GO
