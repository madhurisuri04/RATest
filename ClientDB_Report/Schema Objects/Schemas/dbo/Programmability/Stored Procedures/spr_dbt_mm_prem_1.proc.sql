
CREATE PROCEDURE dbo.spr_dbt_mm_prem

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

--select * from #DB

DECLARE @Client_DB VARCHAR(150) = (SELECT TOP 1 Client_DB FROM #DB)
DECLARE @DBNAME VARCHAR(150)
DECLARE @SQL VARCHAR(4000)

WHILE EXISTS(SELECT DBNAME FROM #DB WHERE HASRUN IS NULL)
BEGIN


	--SELECT TOP 1 @Plan_ID = Plan_ID FROM #DB WHERE HASRUN IS NULL	
	SET @DBNAME = (SELECT TOP 1 DBNAME FROM #DB WHERE HASRUN IS NULL)
		                
	SET @SQL = 
	'

DELETE ' + @Client_DB + '.dbo.dbt_mm_prem
WHERE plan_id = (SELECT TOP 1 PLAN_ID FROM ' + @DBNAME + '.dbo.tbl_plan_name)

INSERT INTO ' + @Client_DB + '.dbo.dbt_mm_prem
EXEC ' + @DBNAME + '.dbo.spr_dbt_mm_prem

	'
	
	EXEC(@SQL)
            
	UPDATE #DB SET HASRUN = GETDATE() WHERE DBNAME = @DBNAME

END

DROP TABLE #DB

SELECT * FROM dbo.dbt_mm_prem