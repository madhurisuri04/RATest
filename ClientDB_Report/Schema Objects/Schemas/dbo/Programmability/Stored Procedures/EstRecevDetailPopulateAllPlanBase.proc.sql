CREATE PROCEDURE [dbo].[EstRecevDetailPopulateAllPlanBase]
AS

/************************************************************************        
* Name			:	EstRecevDetailPopulateAllPlanBase     				*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	06/09/2014											*	
* Ticket        :   19318
* Version		:        												*
* Description	:	Wrapper procedure to Run Estimated Receivables from Summary Tables	*

***************************************************************************/   
/**********************************************************************************************************************************
Ticket   Date          Author           Descrition 
26664    7/14/2014     Madhuri Suri     Added Refresh check of log tables to control the run of Estimated Receivables 
                                        after running Summary MMR, MOR, RAPS Proc and MYU Flag logic has been modified to identify 
                                        final and mid year
31532    11/10/2014    Madhuri Suri     Refresh Years change
33392    11/24/2014    Madhuri Suri     Changes to ensure Part C plans and Hplans alone run for Part C ER From Summary
                                        
*************************************************************************************************************************************/

BEGIN
	SET NOCOUNT ON
--EXEC [EstRecevDetailPopulateAllPlanBase]

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
             
--GET CLIENT ID 
DECLARE @DBName VARCHAR(100)
SELECT @DBName = DB_NAME()
DECLARE @ClientID INT = (SELECT Client_ID FROM [$(HRPReporting)].dbo.tbl_Clients WHERE Report_DB = @DBName)
DECLARE @PaymentYear VARCHAR(4)  = CAST(YEAR(GETDATE()) AS VARCHAR(4))

--33392 Adding Temp Table with Adjustment reasons
/******TBL_MMR_ROLLUP PER PLAN***/
IF OBJECT_ID('[TEMPDB].[DBO].[#tbl_MMR_rollup]', 'U') IS NOT NULL				
DROP TABLE dbo.#tbl_MMR_rollup

CREATE TABLE dbo.#tbl_MMR_rollup
(
ID INT IDENTITY(1,1),
Payment_Year INT,
Adjreason VARCHAR(2),
PlanIdentifier INT,
PlanID VARCHAR (5)
)
INSERT INTO #tbl_MMR_rollup
SELECT 
YEAR(PaymStart)PaymentYear, 
AdjReason,
PlanIdentifier, 
[Plan] PlanID
FROM DBO.tbl_MMR_rollup
WHERE RiskPymtA <> 0 
AND YEAR(PaymStart) >= @PaymentYear-1
GROUP BY YEAR(PaymStart), AdjReason, PlanIdentifier, [PLAN]


CREATE NONCLUSTERED INDEX TBL_MMR_ROLLUP_PLAN_IDX ON #tbl_MMR_rollup (PlanIdentifier, AdjReason, Payment_Year ) 

---PULL PLAN IDS CONNECTION NAMES AND CLIENT IDS TOGETHER 
IF OBJECT_ID('tempdb..#PlanID')>0
DROP TABLE #PlanID

SELECT DISTINCT  ROW_NUMBER()OVER (ORDER BY (r.PlanIdentifier)) AS Row,
                Connection_Name, 
                Database_Server_Name,
                t.Plan_ID, 
                c.Client_ID,
                r.PlanIdentifier
	INTO #PlanID			
FROM [$(HRPReporting)].dbo.tbl_Clients c
INNER JOIN [$(HRPReporting)].dbo.xref_Client_Connections xc on c.Client_ID = xc.Client_ID
INNER JOIN [$(HRPReporting)].dbo.tbl_Connection t on xc.Connection_ID = t.Connection_ID
INNER JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan r on t.Plan_ID = r.PlanID
INNER JOIN (SELECT DISTINCT  PlanIdentifier, PlanID  FROM #tbl_MMR_rollup) MMR ON MMR.PlanIdentifier = R.PlanIdentifier
WHERE Connection_Name LIKE '%[_]H%' AND R.UseForRollup = 1--33392
       AND c.client_id = @ClientID


--REFRESH CHECK FROM LOG TABLES	
--#26664
IF  ((SELECT Last_updated FROM tbl_EstRecv_Summary_tbl_Log 
       WHERE Summary_Tbl_Name = 'tbl_EstRecv_RiskFactorsRAPS') >=  (SELECT ISNULL(MAX(A.PopulatedDate),'') FROM EstRecvAllPlanLog A))--31532
BEGIN

-- LOOP AND INSERT THE YEARS TO BE REFRESHED FOR ALL PLANS
    
IF OBJECT_ID('[TEMPDB].[DBO].[#Refresh]', 'U') IS NOT NULL				
DROP TABLE dbo.#Refresh

CREATE TABLE dbo.#Refresh
(
ID INT IDENTITY(1,1),
Payment_Year INT,
MYU VARCHAR(2),
HPLANID VARCHAR (10),
PLANID INT
)


DECLARE @plan_counter INT
SET @plan_counter = (SELECT COUNT ([PlanIdentifier]) FROM #PlanID)

DECLARE @I INT
DECLARE @iplanidentifier varchar(20)   

SET @I = 1
WHILE (@I <= @plan_counter)
BEGIN
    
SELECT @iplanidentifier = PlanIdentifier from #planID where @I= row
DECLARE @PlanID INT  = @iplanidentifier
DECLARE @HPlanID VARCHAR (10) = (SELECT Plan_ID  FROM #PlanID WHERE Planidentifier = @PlanID )
DECLARE @MYU_flag VARCHAR (1) = 'Y'          --26664

 IF EXISTS (SELECT 1 FROM #tbl_MMR_rollup 
                      WHERE Payment_Year = @PaymentYear
						AND PLANIDENTIFIER = @PlanID 
						AND AdjReason IN ('26', '41'))
						BEGIN 
						SET @MYU_flag   = 'N'
						END
            
/****INSERTS FOR CURRENT YEAR****/
IF EXISTS(SELECT 1 FROM #tbl_MMR_rollup WHERE PLANIDENTIFIER = @PLANID AND Payment_Year = @PaymentYear)
BEGIN
INSERT INTO #Refresh   (Payment_Year, MYU, HPLANID , PLANID)
SELECT  @PaymentYear, @MYU_flag	 , @HPlanID, @PlanID 
END
/****INSERTS FINAL YEAR****/
IF EXISTS(SELECT 1 FROM #tbl_MMR_rollup WHERE AdjReason IN ( '25', '37') and Payment_Year = @PaymentYear-1)--33392 
		SELECT @PaymentYear = @PaymentYear
	ELSE
	BEGIN
	IF EXISTS(SELECT 1 FROM #tbl_MMR_rollup WHERE PlanIdentifier = @PlanID and Payment_Year = @PaymentYear-1) --26664 --33392
		INSERT INTO #Refresh (Payment_Year, MYU, HPLANID , PLANID)
		SELECT @PaymentYear-1,  'N',   @HPlanID, @PlanID 
	END

/****INSERTS INTITIAL FOR NEXT YEAR****/	
IF EXISTS(SELECT 1 FROM #tbl_MMR_rollup WHERE PLANIDENTIFIER = @PLANID AND Payment_Year = @PaymentYear+1) ---33392
BEGIN
	INSERT INTO #Refresh (Payment_Year, MYU, HPLANID , PLANID)
	SELECT @PaymentYear+1, 'Y',   @HPlanID, @PlanID 
	
	END

SET @I = @I  + 1

--END OF LOOPING PLANS
END

--REFRESH CHECK FROM LOG TABLES	

--LOOPING BEGINS FOR THE YEARS AND MYU FLAGS TO BE RUN
DECLARE @Refresh INT
SET @Refresh = (SELECT COUNT (ID) FROM #Refresh)
DECLARE @RefreshSP INT
SET @RefreshSP = 1
WHILE (@RefreshSP <= @Refresh)

BEGIN

DECLARE @Payment_Year  VARCHAR(4) 
DECLARE @MYU   VARCHAR(1) 

SELECT @Payment_Year = Payment_Year,
       @MYU = MYU , 
       @PlanID = PLANID, 
       @HPlanID = HPLANID
  FROM #Refresh WHERE ID = @RefreshSP

BEGIN 
	EXEC [dbo].[EstRecevDetailPopulateAllPlans]	@Payment_Year, @MYU, @PlanID , @HPlanID
END

SET NOCOUNT OFF
SET @RefreshSP = @RefreshSP  + 1
--END OF LOOPING
END


END

END