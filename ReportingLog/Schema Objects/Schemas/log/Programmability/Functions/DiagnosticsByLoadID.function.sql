/****************************************************************************************/
/* Currently used by StarNavConsumer and DW Loader top ETL control packages to send     */
/* diagnostic information in the e-mail notification when a package failure is detected */
/****************************************************************************************/
CREATE FUNCTION [log].[DiagnosticsByLoadID]
(
   @LoadID  bigint
)
RETURNS 
@udf_table TABLE 
(
    MessageType	varchar (50),
    TableSeq	int,
    FieldSeq	int,
    MessageText	varchar (max)
)
AS


BEGIN 

DECLARE
   @DateTime1 datetime,
   @DateTime2 datetime
      
SELECT top 1
   @Datetime1 = start_time,
   @Datetime2 = end_time  
FROM 
   [log].[Package_Execution] 
WHERE 
   load_id = @LoadID
ORDER BY start_time;  

INSERT INTO @udf_table

	-- (1) PACKAGES 
	SELECT
	   'PACKAGES EXECUTED' as MessageType,
	   1 as TableSeq,
	   ROW_NUMBER() OVER (order by start_time) as FieldSeq,
	   'Package (Guid) = ' +  package_name + ' (' + convert (varchar (50), package_guid) + ')' as MessageText
	--select package_name, start_time, end_time, duration_sec, [status],  package_guid
	FROM log.Package_Execution where load_id = @loadid --order by start_time

	-- (2) SYSSSISLOG - ERROR SOURCE PATH
	UNION
	SELECT
	   'SYSSSISLOG SOURCES' as MessageType,
	   2 as TableSeq,
	   ROW_NUMBER() OVER (ORDER BY  MAX (ID) DESC) as FieldSeq,
	   'sysssislog Source = ' + [source] AS MessageText
	FROM 
	   [dbo].[sysssislog] 
	WHERE 
		starttime >= @Datetime1 and starttime <= @DateTime2 and executionid IN
		  (
		  SELECT execution_guid FROM [log].Package_Execution
		  WHERE load_id = @LoadID
		  )
		  and message not like 'Beginning of package%' and message not like 'End of package%'
	GROUP BY [source] --ORDER BY  MAX (ID) DESC

	-- (3) SYSSSISLOG - ERROR MESSAGE(S)
	UNION
	SELECT
	   'SYSSSISLOG MESSAGES' AS MessageType,
	   3 as TableSeq,
	   ROW_NUMBER() OVER (ORDER BY  MAX (ID) DESC) as FieldSeq,
	   'sysssislog Message = ' + [message] AS MesageText
	FROM 
	   [dbo].[sysssislog] 
	WHERE 
		starttime >= @Datetime1
		and starttime <= @DateTime2
		and executionid IN
		  (
		  SELECT execution_guid FROM [log].Package_Execution
		  WHERE load_id = @LoadID
		  )
		  and message not like 'Beginning of package%' and message not like 'End of package%'
	GROUP BY [message] --ORDER BY MAX (ID) DESC
	   
	-- (4) LOGGED MESSAGES
	UNION
	SELECT
	   'LOGGED MESSAGES' as MessageType,
	   4 as TableSeq,
	   ROW_NUMBER() OVER (ORDER BY message_date) as FieldSeq,
	   pe.package_name + ' Message = ' + replace ([message],'char(13)char(10)','') AS MessageText
	FROM
	   [log].Package_Debug PD
	   JOIN [log].[Package_Execution]  PE
		 ON (PD.execution_guid = PE.execution_guid)
	WHERE 
	   pe.load_id = @LoadID  --ORDER BY message_date
	      
	-- (5) LOGGED VARIABLES
	UNION
	SELECT
	   'LOGGED VARIABLES' as MessageType,
	   5 as TableSeq,
	   ROW_NUMBER() OVER (ORDER BY MAX (variable_change_date)) as FieldSeq,
	   'Count Variable ' + package_name + '.@' + variable_name
			+ ' = ' + max (variable_value) as MessageText
	FROM
	   [log].Package_Variable_Change
	WHERE 
		variable_change_date >= @Datetime1 and variable_change_date <= @DateTime2
		and variable_name like '%Count%' 
		and package_name not like '%Control%'
		and load_id = @LoadID 
	GROUP BY
		package_name, variable_name
	--ORDER BY MAX (variable_change_date)


return

END

