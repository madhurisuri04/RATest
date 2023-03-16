/*
Author: Madhuri Suri 
TFS Ticket: 76879 
Descrition: Summary 2.5
*/
SET NOCOUNT ON


BEGIN TRY

BEGIN TRANSACTION SummaryProcessRunFlag
	DECLARE @Message VARCHAR(100)
	SET @Message = 'DATE : ' + CONVERT(VARCHAR(30), GETDATE(),113) + ' - Start script - [SummaryProcessRunFlag]' 
	RAISERROR(@Message, 0, 1) WITH NOWAIT

IF EXISTS 
( SELECT 1 FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id 
 WHERE t.name = 'SummaryProcessRunFlag'
 AND c.name in ('RefreshNeededDate', 'RefreshNeeded',
'LastRefreshDate'))
AND EXISTS  (SELECT 1 FROM 
 [rev].[SummaryProcessRunFlag]	
WHERE (([RefreshNeededDate] is null )
OR ([RefreshNeeded] is null )
OR ([LastRefreshDate] is null )))


BEGIN
UPDATE  [rev].[SummaryProcessRunFlag]
	SET [LastRefreshDate] = '1900-01-01', 
	[RefreshNeededDate] = '1900-01-01', 
	[RefreshNeeded] = 0
WHERE ([RefreshNeededDate] is null )
OR ([RefreshNeeded] is null )
OR ([LastRefreshDate] is null )
END 



	SET @Message = 'DATE : ' + CONVERT(VARCHAR(30), GETDATE(),113) + ' - End script' 
	RAISERROR(@Message, 0, 1) WITH NOWAIT
COMMIT TRANSACTION SummaryProcessRunFlag
END TRY

BEGIN CATCH

	If (XACT_STATE() = 1 OR XACT_STATE() = -1)
	BEGIN
		PRINT 'ROLLBACK TRANSACTION'
		ROLLBACK TRANSACTION SummaryProcessRunFlag
	END

	DECLARE @ERRORMSG VARCHAR(2000)
	SET @ErrorMsg =	'Error: ' + ISNULL(Error_Procedure(),'script') + ': ' +  Error_Message()
					+ ', Error Number: ' + CAST(Error_Number() as varchar(10))
					+ ' Line: ' + CAST(Error_Line() as varchar(50))
	
	RAISERROR (@ErrorMsg, 16, 1)

END CATCH	

SET NOCOUNT OFF