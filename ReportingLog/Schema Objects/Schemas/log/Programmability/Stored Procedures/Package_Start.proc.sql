CREATE PROCEDURE [log].[Package_Start]
	@parentKey			BIGINT,
	@parentLoadDate		DATETIME,
	@packageGUID		UNIQUEIDENTIFIER,
	@packageName		VARCHAR(50),
	@executionGUID		UNIQUEIDENTIFIER,
	@loadId				BIGINT,
	@packageID			BIGINT = null output,
	@newLoadId			BIGINT = null output,
	@loadDate			DATETIME output
WITH EXECUTE AS CALLER
AS


BEGIN
	SET NOCOUNT ON

	SET @loadDate = GETDATE()

	INSERT INTO log.Package_Execution(
		parent_package_log_key
		,package_guid
		,package_name
		,execution_guid
		,start_time
		,end_time
		,status
		,error_source
		,error_description
		,load_id
	) VALUES (
		 @parentKey
		,@packageGUID
		,@packageName
		,@executionGUID
		,GETDATE()
		,null
		,'Running'
		,''
		,''
		,@loadId
	)
	SET @packageID = SCOPE_IDENTITY()

	--  Control package should have a null parent, -2147483600 sent by default as 
	--    can't be null and represents ~lowest int32 value
	--  @loadid is null for control packages

	IF @parentKey <= -2147483600 
		BEGIN
			UPDATE log.Package_Execution WITH (ROWLOCK)
			SET parent_package_log_key = @packageID,
				load_id = @packageID
			WHERE
				package_log_id = @packageID
			
			SET @newLoadId = @packageID
		END
	ELSE
		SET @newLoadId = @loadId
		
	IF @parentLoadDate >= '1/1/1801'
		BEGIN
			SET @loadDate = @parentLoadDate
		END

	SET NOCOUNT OFF
END 


GO


