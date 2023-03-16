CREATE PROCEDURE [log].[Package_End]
	 @packageID			BIGINT
WITH EXECUTE AS CALLER
AS

BEGIN
	SET NOCOUNT ON

	UPDATE log.Package_Execution WITH(ROWLOCK)
	SET end_time = GETDATE(),
		status = CASE
			WHEN status = 'Running' THEN 'Success'	
			ELSE status					
		END, 
		error_description = CASE
			WHEN status = 'Running' THEN ''	
			ELSE error_description			
		END 
	WHERE 
		package_log_id = @packageID

	SET NOCOUNT OFF
END 


GO


