﻿
CREATE PROCEDURE dbo.spr_dbt_file_upload

AS

-- Plans per dbt_config that should be included in the client roll-up
IF OBJECT_ID('[tempdb].[dbo].[#DB]', 'U') IS NOT NULL DROP TABLE #DB
CREATE TABLE #DB (Client_DB VARCHAR(150), DBNAME VARCHAR(150), HASRUN SMALLDATETIME NULL)

INSERT #DB
SELECT Client_DB,
	   Plan_DB,
       NULL
FROM   [$(HRPInternalReportsDB)].dbo.dbt_config
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

DELETE ' + @Client_DB + '.dbo.dbt_file_upload
WHERE plan_id = (SELECT TOP 1 PLAN_ID FROM ' + @DBNAME + '.dbo.tbl_plan_name)

INSERT INTO ' + @Client_DB + '.dbo.dbt_file_upload
EXEC ' + @DBNAME + '.dbo.spr_dbt_file_upload

	'
	
	EXEC(@SQL)
            
	UPDATE #DB SET HASRUN = GETDATE() WHERE DBNAME = @DBNAME

END

DROP TABLE #DB

SELECT * FROM dbo.dbt_file_upload