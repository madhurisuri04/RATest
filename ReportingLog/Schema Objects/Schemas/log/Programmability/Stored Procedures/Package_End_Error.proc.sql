CREATE PROCEDURE [log].[Package_End_Error]
		@packageID		BIGINT
WITH EXECUTE AS CALLER
AS

BEGIN
	SET NOCOUNT ON
	
	DECLARE
		@errorSource		VARCHAR(1024),
		@errorDesc			VARCHAR(2048),
		@packageName		VARCHAR(64),
		@executionGUID		UNIQUEIDENTIFIER

	SELECT 
		 @packageName = UPPER(package_name),
		@executionGUID = execution_guid
	FROM log.Package_Execution WITH (NOLOCK)
	WHERE package_log_id = @packageID

	SELECT TOP 1 
		 @errorSource = source,
		 @errorDesc = message
	FROM dbo.sysssislog WITH (NOLOCK)
	WHERE executionid = @executionGUID
		and (UPPER(event) = 'ONERROR')
		and UPPER(source) <> @packageName
	ORDER BY id

	UPDATE log.Package_Execution WITH (ROWLOCK)
	SET end_time = GETDATE(),
		status = 'Failed',
		error_source = @errorSource,
		error_description = @errorDesc
	WHERE package_log_id = @packageID

	SET NOCOUNT OFF
END 


GO


