
CREATE PROCEDURE [log].[Package_End_Force]
		@packageID		BIGINT,
		@status		VARCHAR(10),
		@errorSource	VARCHAR(1024),
		@errorDesc		VARCHAR(2048)
WITH EXECUTE AS CALLER
AS

BEGIN
	SET NOCOUNT ON

	UPDATE log.Package_Execution WITH (ROWLOCK)
	SET end_time = GETDATE(),
		status = @status,
		error_source = @errorSource,
		error_description = @errorDesc
	WHERE package_log_id = @packageID

	SET NOCOUNT OFF
END 


GO


