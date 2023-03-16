
CREATE PROCEDURE dbo.spr_dbt_mm_rs

AS

-- Plans per dbt_config that should be included in the client roll-up
IF OBJECT_ID('[tempdb].[dbo].[#DB]', 'U') IS NOT NULL DROP TABLE #DB
CREATE TABLE #DB (Client_DB VARCHAR(150), DBNAME VARCHAR(150), HASRUN SMALLDATETIME NULL)

INSERT #DB
SELECT Client_DB,
	   Plan_DB,
       NULL
--FROM   ClientServicesTempdb.dbo.dbt_config
FROM   [$(HRPInternalReportsDB)].dbo.dbt_config
WHERE  Db_name() = Client_DB
ORDER  BY 2

DECLARE @Client_DB VARCHAR(150) = (SELECT TOP 1 Client_DB FROM #DB)
DECLARE @Client_DB2 VARCHAR(150) = (SELECT TOP 1 Client_DB FROM #DB)
DECLARE @DBNAME VARCHAR(150)
DECLARE @SQL VARCHAR(4000)

IF Object_id('[tempdb].[dbo].[#tmp_mm_client]', 'u') IS NOT NULL
  DROP TABLE #tmp_mm_client

CREATE TABLE #tmp_mm_client
  (
     plan_id         VARCHAR(5),
     py              VARCHAR(4),
     hicn            VARCHAR(15),
     rs              DECIMAL(19, 4),
     membership_type VARCHAR(1),
     plan_type varchar(1)
  ) 

WHILE EXISTS(SELECT DBNAME FROM #DB WHERE HASRUN IS NULL)
BEGIN

	SET @DBNAME = (SELECT TOP 1 DBNAME FROM #DB WHERE HASRUN IS NULL)
	                
	SET @SQL = 

	'

DECLARE @paymstart DATETIME SET @paymstart = ''12/31/'' + CONVERT(VARCHAR(4), YEAR(Getdate()))  
DECLARE @paymstart2 DATETIME SET @paymstart2 = ''1/1/'' + CONVERT(VARCHAR(4), YEAR(Getdate())-2)   

DELETE ' + @Client_DB + '.dbo.dbt_mm_rs
WHERE plan_id = (SELECT TOP 1 PLAN_ID FROM ' + @DBNAME + '.dbo.tbl_plan_name)
or plan_id = ''CLNT''

INSERT INTO ' + @Client_DB + '.dbo.dbt_mm_rs
EXEC ' + @DBNAME + '.dbo.spr_dbt_mm_rs

INSERT INTO #tmp_mm_client
SELECT ''CLNT'', YEAR(paymstart) AS PY, HICN, AVG(rskadjfctra)  AS RS, ''C'',
	case when substring(pn.plan_id,1,1) = ''H'' then ''H'' else ''S'' end
FROM ' + @DBNAME + '.dbo.tbl_member_months a
INNER JOIN ' + @DBNAME + '.dbo.tbl_plan_name pn ON 1 = 1
WHERE paymstart BETWEEN @paymstart2 AND @paymstart
	AND NOT EXISTS (SELECT 1 FROM [$(HRPReporting)].dbo.tbl_connection c WHERE  pn.plan_id = c.plan_id AND c.part_d_only_plan = 1)
GROUP BY YEAR(paymstart), hicn, case when substring(pn.plan_id,1,1) = ''H'' then ''H'' else ''S'' end


INSERT INTO #tmp_mm_client
SELECT ''CLNT'', YEAR(paymstart) AS PY, HICN, AVG(Part_D_RA_Factor)  AS RS, ''D'',
	case when substring(pn.plan_id,1,1) = ''H'' then ''H'' else ''S'' end
FROM ' + @DBNAME + '.dbo.tbl_member_months a
INNER JOIN ' + @DBNAME + '.dbo.tbl_plan_name pn ON 1 = 1
WHERE paymstart BETWEEN @paymstart2 AND @paymstart
	AND Total_Part_D_Payment > 0
GROUP BY YEAR(paymstart), hicn, case when substring(pn.plan_id,1,1) = ''H'' then ''H'' else ''S'' end

	'
	
	EXEC(@SQL)
            
	UPDATE #DB SET HASRUN = GETDATE() WHERE DBNAME = @DBNAME

END

DROP TABLE #DB

/*NEW CLIENT LEVEL MEMBERSHIP RISK SCORE REPORTING*/

DECLARE @paymstart varchar(4) SET @paymstart = YEAR(Getdate())
DECLARE @paymstart1 varchar(4) SET @paymstart1 = YEAR(Getdate())-1
DECLARE @paymstart2 varchar(4) SET @paymstart2 = YEAR(Getdate())-2  
  
--SELECT @paymstart, @paymend, @paymstart1, @paymend1, @paymstart2, @paymend2  
  
IF Object_id('[tempdb].[dbo].[#tmp_mm]', 'u') IS NOT NULL  
  DROP TABLE #tmp_mm   
  
CREATE TABLE #tmp_mm  
  (  
     plan_id         VARCHAR(5),  
     payment_year    VARCHAR(4),  
     prior_year      VARCHAR(4),  
     member_count    INT,  
     avg_risk_score  DECIMAL(19, 4),  
     membership_type VARCHAR(1)  
  )   
  
/*PART C*/  
  
--current year only  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart     AS PY,  
       @paymstart     AS PriorYear,  
       COUNT(DISTINCT hicn) AS HICNs,  
       AVG(RS)     AS RS,  
       'C'  
FROM   #tmp_mm_client a  
WHERE  PY = @paymstart
	and a.membership_type = 'C'
	and a.plan_type = 'H'
GROUP  BY a.plan_id   
  
  
--current year and current year - 1  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart  AS PY,  
       @paymstart1 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'C'  
FROM   #tmp_mm_client a  
WHERE  PY = @paymstart
	and a.membership_type = 'C'
    and a.plan_type = 'H'
       AND EXISTS (SELECT 1  
                   FROM   #tmp_mm_client b  
                   WHERE  a.hicn = b.hicn  
                          AND b.PY = @paymstart1
                          	and b.membership_type = 'C')  
GROUP  BY a.plan_id   
  
--current year and current year - 2  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart  AS PY,  
       @paymstart2 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'C'  
FROM   #tmp_mm_client a  
WHERE  PY = @paymstart
	and a.membership_type = 'C'
	and a.plan_type = 'H'
       AND EXISTS (SELECT 1  
                   FROM   #tmp_mm_client b  
                   WHERE  a.hicn = b.hicn  
                          AND b.PY = @paymstart2
                          	and b.membership_type = 'C')  
GROUP  BY a.plan_id   
    
  
--current year - 1 only  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart1 AS PY,  
       @paymstart1 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'C'  
FROM  #tmp_mm_client a  
WHERE  PY = @paymstart1 
	and a.membership_type = 'C'
	and a.plan_type = 'H'
GROUP  BY a.plan_id   
  
--current year - 1 and current year - 2  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart1 AS PY,  
       @paymstart2 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'C'  
FROM  #tmp_mm_client a  
WHERE  PY = @paymstart1
	and a.membership_type = 'C'
	and a.plan_type = 'H'
       AND EXISTS (SELECT 1  
                   FROM   #tmp_mm_client b  
                   WHERE  a.hicn = b.hicn  
                          AND b.PY = @paymstart2
                          	and b.membership_type = 'C')  
GROUP  BY a.plan_id   
  
--current year - 2 only  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart2 AS PY,  
       @paymstart2 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'C'  
FROM   #tmp_mm_client a 
WHERE  PY = @paymstart2
	and a.membership_type = 'C'
	and a.plan_type = 'H'
GROUP  BY a.plan_id   
  
  
/*PART D*/  
  
--current year only  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart      AS PY,  
       @paymstart      AS PriorYear,  
       COUNT(DISTINCT hicn)  AS HICNs,  
       AVG(RS) AS RS,  
       'D'  
FROM   #tmp_mm_client a  
WHERE  PY = @paymstart
      	and a.membership_type = 'D'   
GROUP  BY a.plan_id   
  
  
--current year and current year - 1  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart  AS PY,  
       @paymstart1 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'D'  
FROM   #tmp_mm_client a  
WHERE  PY = @paymstart
	and a.membership_type = 'D'
       AND EXISTS (SELECT 1  
                   FROM   #tmp_mm_client b  
                   WHERE  a.hicn = b.hicn  
                          AND b.PY = @paymstart1
                          and b.membership_type = 'D')
GROUP  BY a.plan_id   
  
--current year and current year - 2  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart  AS PY,  
       @paymstart2 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'D'  
FROM   #tmp_mm_client a
WHERE  PY = @paymstart
	and a.membership_type = 'D'
       AND EXISTS (SELECT 1  
                   FROM   #tmp_mm_client b  
                   WHERE  a.hicn = b.hicn  
                          AND b.PY = @paymstart2
                          and b.membership_type = 'D')
GROUP  BY a.plan_id   
  
--current year - 1 only  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart1 AS PY,  
       @paymstart1 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'D'  
FROM   #tmp_mm_client a 
WHERE  PY = @paymstart1
	and a.membership_type = 'D'
GROUP  BY a.plan_id   
  
  
--current year - 1 and current year - 2  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart1 AS PY,  
       @paymstart2 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'D'  
FROM   #tmp_mm_client a
WHERE  PY = @paymstart1
	and a.membership_type = 'D'
       AND EXISTS (SELECT 1  
                   FROM   #tmp_mm_client b  
                   WHERE  a.hicn = b.hicn  
                          AND b.PY = @paymstart2
                          and b.membership_type = 'D')  
GROUP  BY a.plan_id   
  
--current year - 2 only  
INSERT INTO #tmp_mm  
SELECT a.plan_id,  
       @paymstart2 AS PY,  
       @paymstart2 AS PriorYear,  
       COUNT(DISTINCT hicn),  
       AVG(RS),  
       'D'  
FROM   #tmp_mm_client a  
WHERE  PY = @paymstart2
	and a.membership_type = 'D'
GROUP  BY a.plan_id   
  
  
/*Results from C and D*/  
declare @sql2 varchar(4000)
	SET @sql2 = 

'INSERT INTO ' + @Client_DB2 + '.dbo.dbt_mm_rs
SELECT *,  
       Getdate() as populated  
FROM   #tmp_mm'

exec(@sql2)

SELECT * FROM dbo.dbt_mm_rs