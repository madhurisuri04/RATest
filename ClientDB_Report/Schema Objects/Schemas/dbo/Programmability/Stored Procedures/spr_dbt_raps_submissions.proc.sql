﻿
CREATE PROCEDURE dbo.spr_dbt_raps_submissions

AS

-- Plans per dbt_config that should be included in the client roll-up
IF OBJECT_ID('[tempdb].[dbo].[#DB]', 'U') IS NOT NULL DROP TABLE #DB
CREATE TABLE #DB (Client_DB VARCHAR(150), DBNAME VARCHAR(150), HASRUN SMALLDATETIME NULL)

INSERT #DB
SELECT Client_DB,
	   Plan_DB,
       NULL
FROM   HRPInternalReports.dbo.dbt_config
WHERE  Db_name() = Client_DB
ORDER  BY 2

DECLARE @Client_DB VARCHAR(150) = (SELECT TOP 1 Client_DB FROM #DB)
DECLARE @DBNAME VARCHAR(150)
DECLARE @SQL VARCHAR(4000)

WHILE EXISTS(SELECT DBNAME FROM #DB WHERE HASRUN IS NULL)
BEGIN

	SET @DBNAME = (SELECT TOP 1 DBNAME FROM #DB WHERE HASRUN IS NULL)
	                
	SET @SQL = 
	'

DELETE ' + @Client_DB + '.dbo.dbt_raps_submissions
WHERE plan_id = (SELECT TOP 1 PLAN_ID FROM ' + @DBNAME + '.dbo.tbl_plan_name)

INSERT INTO ' + @Client_DB + '.dbo.dbt_raps_submissions
EXEC ' + @DBNAME + '.dbo.spr_dbt_raps_submissions

	'
	
	EXEC(@SQL)
            
	UPDATE #DB SET HASRUN = GETDATE() WHERE DBNAME = @DBNAME

END

DROP TABLE #DB

SELECT * FROM dbo.dbt_raps_submissions