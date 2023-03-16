CREATE PROCEDURE [log].[Package_Variable_Value_Change]
   @package_name				VARCHAR(50),
   @package_log_id				BIGINT,
   @variable_name				VARCHAR(255),
   @variable_value				VARCHAR(MAX),
   @variable_change_date		DATETIME,
   @execution_guid				UNIQUEIDENTIFIER,
   @load_id						BIGINT
WITH EXECUTE AS CALLER
AS

BEGIN
   SET NOCOUNT ON

   INSERT INTO log.Package_Variable_Change
      (package_name,
       package_log_id,
       variable_name,
       variable_value,
       variable_change_date,
       execution_guid,
       load_id)
   VALUES
      (@package_name,
       @package_log_id,
       @variable_name,
       @variable_value,
       @variable_change_date,
       @execution_guid,
       @load_id)

   SET NOCOUNT OFF
END 








GO


