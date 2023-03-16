CREATE PROCEDURE [dbo].[EstRecevDetailPopulateAllPlans]
(@Payment_Year VARCHAR (4), @MYU VARCHAR(1), @PlanID INT, @HPlanID VARCHAR(10))
AS
BEGIN
SET NOCOUNT ON

/************************************************************************        
* Name			:	EstRecevDetailPopulateAllPlans     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	06/09/2014											*	
* Ticket        :   19318
* Version		:        												*
* Description	:	Populates Estimated Receivables in All plan tables from Summary Tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
31532        11/10/2014        MADHURI SURI        Incorporate changes from Summary Tables 
                                                   and fix existing issues in ER from Summary logic
***********************************************************************************************/   
--TESTING 
--EXEC [dbo].[EstRecevDetailPopulateAllPlans], 2014, 'Y', 273, 'H1304'
--DECLARE @Payment_Year VARCHAR(4) = '2014'
--DECLARE @MYU VARCHAR(1) = 'N'
--DECLARE @PlanID INT = 273
--DECLARE @HPlanID VARCHAR(10) = 'H1304'

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 DECLARE @populate_date SMALLDATETIME = GETDATE()
 DECLARE @Currentdate SMALLDATETIME = GETDATE()
 
--GET CLIENT ID 
DECLARE @DBName VARCHAR(100)
SELECT  @DBName = DB_NAME()
DECLARE @ClientID INT = (SELECT Client_ID FROM [$(HRPReporting)].dbo.tbl_Clients WHERE Report_DB = @DBName)

 /************************************************************
DECLARE VALUES FOR PROCESSEDBY AND DCP FROM AND THRU DATES :
*************************************************************/
DECLARE @PROCESSBY AS DATETIME

IF @MYU = 'Y'
BEGIN
	SET @PROCESSBY = (
	SELECT CASE WHEN MIN(a.Initial_Sweep_Date) > GETDATE() THEN MIN(a.Initial_Sweep_Date)
	                                                       ELSE MAX(a.Initial_Sweep_Date) END
	FROM [$(HRPReporting)].dbo.lk_DCP_dates a
	WHERE LEFT(PayMonth, 4) = @Payment_Year
		AND paymonth NOT LIKE '%99'
	)
END
ELSE
BEGIN
	SET @PROCESSBY = (
	SELECT CASE WHEN min(a.Initial_Sweep_Date) > GETDATE() THEN MIN(a.Initial_Sweep_Date)
	                                                       ELSE CASE WHEN max(a.Initial_Sweep_Date) > GETDATE() THEN MAX(a.Initial_Sweep_Date)
		                                                                                                        ELSE max(a.Final_Sweep_Date) END END
	FROM [$(HRPReporting)].dbo.lk_DCP_dates a
	WHERE LEFT(PayMonth, 4) = @Payment_Year
	)
END

DECLARE @DCP_FROMDATE AS DATETIME

SET @DCP_FROMDATE = (
SELECT DISTINCT dcp_start
FROM [$(HRPReporting)].dbo.lk_DCP_dates
WHERE Initial_Sweep_Date = @PROCESSBY
	OR Final_Sweep_Date = @PROCESSBY
)

DECLARE @DCP_THRUDATE AS DATETIME

SET @DCP_THRUDATE = (
SELECT DISTINCT dcp_end
FROM [$(HRPReporting)].dbo.lk_DCP_dates
WHERE Initial_Sweep_Date = @PROCESSBY
	OR Final_Sweep_Date = @PROCESSBY
)

	/**********************************************************************
DECLARE PAYMONTH FOR MOR DATA DYNAMICALLY COME FROM LK_DCP_DATES:
***********************************************************************/
DECLARE @PAYMO INT = (SELECT DISTINCT Paymonth FROM [$(HRPReporting)].dbo.lk_dcp_dates WHERE LEFT(paymonth,4)=@Payment_Year AND mid_year_update='Y')

/**********************************************************************
 MID_YEAR_UPDATE_FLAG AND TOTAL_MA_PAYMENT_AMOUNT FROM TBL_MMR_ROLLUP:
***********************************************************************/

IF OBJECT_ID('Tempdb..#MID_YEAR_UPDATE_FLAG') > 0
	DROP TABLE #MID_YEAR_UPDATE_FLAG

CREATE TABLE #MID_YEAR_UPDATE_FLAG (
	ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL
	,HICN NVARCHAR(24)
	,MYU VARCHAR(1)
	,PAYMSTART SMALLDATETIME
	,MID_YEAR_UPDATE_ACTUAL SMALLMONEY
	)

CREATE NONCLUSTERED INDEX MIDYEAR_IDX ON #MID_YEAR_UPDATE_FLAG (HICN) INCLUDE (Paymstart)

INSERT INTO #MID_YEAR_UPDATE_FLAG (
	HICN
	,MYU
	,PAYMSTART
	,MID_YEAR_UPDATE_ACTUAL
	)
SELECT HICN
	,'Y' AS MYU
	,PAYMSTART
	,SUM(TOTAL_MA_PAYMENT_AMOUNT) AS MID_YEAR_UPDATE_ACTUAL
FROM dbo.tbl_MMR_rollup
WHERE (
		ADJREASON = 41
		OR ADJREASON = 26
		)
	AND TOTAL_MA_PAYMENT_AMOUNT <> 0
	AND YEAR(PaymStart) = @Payment_Year
	AND PlanIdentifier = @PlanID
GROUP BY Total_MA_Payment_Amount
	,HICN
	,PaymStart


/**************************************************************************************
 GETTING VALUES FOR EACH COLUMN IN DETAIL FROM TBL_MEMBER_MONTHS_ROLLUP AT PLAN LEVEL:
***************************************************************************************/
		
If OBJECT_ID('Tempdb..#Tbl_Member_Months')>0  --31532
Drop Table #Tbl_Member_Months

CREATE TABLE #Tbl_Member_Months
(
		ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL
		,HICN NVARCHAR(24)
		,Hosp NVARCHAR(2)
		,DefaultInd NVARCHAR(2)
		,ESRD NVARCHAR(2)
		,MedicAddOn NVARCHAR(2)
		,Medicaid NVARCHAR(2)
		,PaymStart SMALLDATETIME
		,OOA NVARCHAR(2)
		,OREC NVARCHAR(2)
		,PlanID NVARCHAR(10)
		,PlanIdentifier SMALLINT
		,RA_Factor_Type NVARCHAR(4)
		,SCC NVARCHAR(10)
		,pbp NVARCHAR(6)
		,Total_MA_Payment_Amount SMALLMONEY
		,TotalPayment SMALLMONEY
		,RS_Old DECIMAL(19, 4)
		,MA_RISK_REVENUE_A_B MONEY
		,TOTAL_PREMIUM_YTD MONEY
		)

CREATE NONCLUSTERED INDEX TBL_MEMBER_MONTHS_IDX ON #Tbl_Member_Months (HICN) INCLUDE (Paymstart) --31532

INSERT INTO #Tbl_Member_Months
SELECT B.HICN
	,b.Hosp
	,b.DefaultInd
	,b.ESRD
	,b.MedicAddOn
	,b.Medicaid
	,b.PaymStart
	,b.OOA
	,b.OREC
	,b.[Plan] PlanID
	,b.PlanIdentifier
	,b.RA_Factor_Type
	,b.SCC
	,b.pbp
	,b.Total_MA_Payment_Amount
	,b.TotalPayment
	,b.RskadjFctrA AS RS_Old
	,SUM(RISKPYMTA) + SUM(RISKPYMTB) AS MA_RISK_REVENUE_A_B
	,SUM(TOTAL_MA_PAYMENT_AMOUNT) TOTAL_PREMIUM_YTD
FROM dbo.tbl_Member_Months_rollup b
WHERE B.PlanIdentifier = @PlanID
GROUP BY (b.paymstart)
	,HICN
	,b.Hosp
	,b.DefaultInd
	,b.ESRD
	,b.MedicAddOn
	,b.Medicaid
	,b.PaymStart
	,b.OOA
	,b.OREC
	,b.[Plan]
	,b.PlanIdentifier
	,b.RA_Factor_Type
	,b.SCC
	,b.pbp
	,b.Total_MA_Payment_Amount
	,b.TotalPayment
	,b.RskadjFctrA

/************************************
TBL_ESTRECV_MMR DATA FOR THE PLAN :
***************************************/
IF OBJECT_ID('Tempdb..#TBL_ESTRECV_MMR') > 0
	DROP TABLE #TBL_ESTRECV_MMR  --31532

CREATE TABLE #TBL_ESTRECV_MMR (
	ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL
	,PlanID INT
	,HICN VARCHAR(12)
	,PaymStart DATETIME
	,Gender VARCHAR(1)
	,AgeGrp VARCHAR(4)
	,RAFT VARCHAR(2)
	,OREC VARCHAR(5)
	,Medicaid VARCHAR(5)
	,LI INT
	,Payment_Year VARCHAR(4)
	,RS_old DECIMAL(19, 4)
	,RS_New DECIMAL(19, 4)
	,Est_Recv MONEY
	,SCC VARCHAR(10)
	,PBP VARCHAR(6)
	,HOSP VARCHAR(1)
	,PartD_RAFT VARCHAR(2)
	,OREC_CALC VARCHAR(5)
	,RAFT_ORIG VARCHAR(2)
)

CREATE NONCLUSTERED INDEX TBL_ESTRECV_MMR_IDX ON #Tbl_Member_Months (HICN) INCLUDE (Paymstart) --31532

INSERT INTO #TBL_ESTRECV_MMR
SELECT PlanID
	,HICN
	,PaymStart
	,Gender
	,AgeGrp
	,RAFT
	,OREC
	,Medicaid
	,LI
	,Payment_Year
	,RS_old
	,RS_New
	,Est_Recv
	,SCC
	,PBP
	,HOSP
	,PartD_RAFT
	,OREC_CALC
	,RAFT_ORIG
FROM dbo.TBL_ESTRECV_MMR
WHERE PlanID = @PlanID

/***********************************************************
FIND MEMBERS THAT WERE FLAGGED IN ERROR AS "NEW ENROLLEES" :
************************************************************/
  
IF OBJECT_ID('Tempdb..#NEW_ENROLLEE_ERROR_FLAG_E') > 0
	DROP TABLE #NEW_ENROLLEE_ERROR_FLAG_E

SELECT HICN  --31532
	,RS_Old
INTO #NEW_ENROLLEE_ERROR_FLAG_E
FROM #Tbl_Member_Months
WHERE YEAR(PAYMSTART) = @Payment_Year
	AND RA_FACTOR_TYPE = 'E'

IF OBJECT_ID('Tempdb..#NEW_ENROLLEE_ERROR_FLAG_C') > 0
	DROP TABLE #NEW_ENROLLEE_ERROR_FLAG_C

SELECT HICN  --31532
	,RS_Old
INTO #NEW_ENROLLEE_ERROR_FLAG_C
FROM #Tbl_Member_Months
WHERE YEAR(PAYMSTART) = @Payment_Year
	AND RA_FACTOR_TYPE = 'C'
       
       
 IF OBJECT_ID('Tempdb..#NEW_ENROLLEE_ERROR_FLAG')>0
 DROP TABLE #NEW_ENROLLEE_ERROR_FLAG

SELECT  A.HICN, 
       '0.00' RS
   INTO #NEW_ENROLLEE_ERROR_FLAG
       FROM #NEW_ENROLLEE_ERROR_FLAG_E A,
            #NEW_ENROLLEE_ERROR_FLAG_C B 
	WHERE A.HICN=B.HICN 
	      AND  A.RS_Old=B.RS_Old 
GROUP BY A.HICN

/******************************************
MONTHS INDCP PER PLAN FROM TBL_ESTRECV_MMR :
*******************************************/
IF OBJECT_ID('Tempdb..#MONTHS_IN_DCP') > 0  --31532
	DROP TABLE #MONTHS_IN_DCP
BEGIN 
CREATE TABLE #MONTHS_IN_DCP (
	HICN VARCHAR(12) NULL
	,MONTHS INT NULL
	)

  INSERT INTO #MONTHS_IN_DCP   
  SELECT HICN , 
         COUNT(DISTINCT paymstart) Months
         FROM DBO.TBL_ESTRECV_MMR
		 WHERE PaymStart BETWEEN @DCP_FROMDATE 
		                 AND @DCP_THRUDATE
         GROUP BY HICN 
  
  END
/**************************
MAX MOR FROM MOR_ROLLUP :
***************************/
IF OBJECT_ID('Tempdb..#MOR_Rollup') > 0  --31532
	DROP TABLE #MOR_Rollup
CREATE TABLE #MOR_Rollup
(
ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
PlanIdentifier	INT		,
Paymo	VARCHAR	(6)	,
HICN	VARCHAR	(12)	,
ORG_DISABLD_FEMALE	INT		,
ORG_DISABLD_MALE	INT		,
)	
CREATE NONCLUSTERED INDEX MOR_Rollup_IDX ON #MOR_Rollup (HICN) INCLUDE (paymo) --31532
INSERT INTO #MOR_Rollup

SELECT 
	PlanIdentifier, 
	Paymo,
	HICN,
	ORG_DISABLD_FEMALE,
	ORG_DISABLD_MALE

FROM dbo.MOR_rollup b
WHERE LEFT(Paymo, 4) = @Payment_Year
	AND PlanIdentifier = @PlanID

UNION

SELECT 
    PlanIdentifier, 
	Paymo,
	HICN,
	ORG_DISABLD_FEMALE,
	ORG_DISABLD_MALE
FROM dbo.MOR2012_rollup
WHERE LEFT(Paymo, 4) = @Payment_Year
	AND PlanIdentifier = @PlanID



If OBJECT_ID('Tempdb..#MAX_MOR')>0
Drop Table #MAX_MOR

CREATE TABLE #MAX_MOR
(
ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
HICN	VARCHAR	(20)	,
MAX_MOR	VARCHAR	(10)	,
Paymstart	DATETIME,
OREC	INT		,
)	
CREATE NONCLUSTERED INDEX MAX_MOR_IDX ON #MAX_MOR (HICN) INCLUDE (Paymstart) --31532

INSERT INTO #MAX_MOR
SELECT DISTINCT A.Hicn
	,MAX(b.Paymo) MAX_MOR
	,MAX(paymstart) paymstart
	,CASE 
		WHEN (
				b.ORG_DISABLD_MALE = '1'
				OR b.ORG_DISABLD_FEMALE = '1'
				)
			AND a.OREC <> '1' --31532
			THEN '1'
		ELSE a.OREC ---31532
		END AS OREC

FROM #TBL_ESTRECV_MMR a
JOIN #MOR_Rollup b ON b.HICN = a.HICN
	AND a.Payment_Year = LEFT(b.Paymo, 4)
WHERE B.Paymo >= @PAYMO
GROUP BY a.HICN
	,b.ORG_DISABLD_FEMALE
	,b.ORG_DISABLD_MALE
	,a.OREC --31532
/**************************
#DATE_FOR_FACTORS :
***************************/
If OBJECT_ID('Tempdb..#DATE_FOR_FACTORS')>0
Drop Table #DATE_FOR_FACTORS

 SELECT MAX(b.paymstart) DATE_FOR_FACTORS, 
        HICN 
 INTO #DATE_FOR_FACTORS
 FROM  #Tbl_Member_Months b
 WHERE YEAR(PaymStart) = @Payment_Year 
 AND B.PlanIdentifier = @PlanID  
 GROUP BY HICN
						

/**************************
MAX DEMOGRAPHICS :
***************************/
If OBJECT_ID('Tempdb..#DEMO')>0
Drop Table #DEMO
SELECT A.hicn
	,A.PAYMSTART
	,A.AgeGrp
	,A.Gender
	,CASE 
		WHEN A.Medicaid = 'Y'
			AND A.AgeGrp > 6469 --31532
			THEN '1'
		WHEN A.MEDICAID = 'Y'
			AND A.AGEgrp < 6565
			THEN '1'
		ELSE ISNULL(A.Medicaid, '9999')
		END AS Medicaid
	,CASE 
		WHEN M.HICN IS NOT NULL
			THEN M.OREC
		ELSE A.OREC
		END AS OREC
	,A.RAFT
INTO #DEMO
FROM #TBL_ESTRECV_MMR A
INNER JOIN #DATE_FOR_FACTORS D ON D.HICN = A.HICN
	AND D.DATE_FOR_FACTORS = A.PaymStart
LEFT JOIN #MAX_MOR M ON M.HICN = A.HICN
WHERE A.Payment_Year = @Payment_Year

UPDATE #DEMO 
SET OREC = CASE WHEN OREC = 3 THEN 1 
                WHEN OREC = 2 THEN 0
                WHEN OREC = 9 THEN 0
                ELSE OREC END
                
FROM #DEMO     
        
/**************************
DEMOGRAPHICS FOR PAYMENT YEAR :
***************************/

 If OBJECT_ID('Tempdb..#Demographics')>0
 Drop Table #Demographics
 CREATE TABLE #Demographics (
Payment_year	VARCHAR (4),
MYU	VARCHAR	(1)	,
DATE_FOR_FACTORS	DATETIME		,
HICN	VARCHAR	(12)	,
AgeGrp	VARCHAR	(10)	,
SEX	VARCHAR	(1)	,
OREC_CALC	VARCHAR	(5)	,
RAFT_ORIG	VARCHAR	(10)	,
Medicaid	VARCHAR	(5)	,
MAX_MOR	VARCHAR	(6)	,
MID_YEAR_UPDATE_FLAG	VARCHAR	(1)	,
AgeGroupID	INT		,
Gender	VARCHAR	(1)	,
PaymStart	DATETIME	,
RiskScore_New	DECIMAL	(10,3)	,
RS_old	DECIMAL	(19,4)	,
DIFF	DECIMAL	(10,3)	,
SCC	VARCHAR	(10)	,
PBP	VARCHAR	(6)	,
PlanID	VARCHAR	(5)	,
RAFT	VARCHAR	(4)	,
BID	SMALLMONEY		,
HOSP	VARCHAR	(1)	,
ESTIMATED_RECEIVABLE_AMOUNT	DECIMAL	(12,4)	,
NewEnrolleeErrorFlag	VARCHAR	(1)	,
MONTHS_IN_DCP	INT		,
ISAR_USED	VARCHAR	(1)	,
Projected_Risk_score	DECIMAL	(10,3)	,
MEMBER_MONTH	INT		,
ACTUAL_FINAL_PAID	INT		,
MA_RISK_REVENUE_A_B	money		,
MA_RISK_REVENUE_RECALC	DECIMAL	(20,3)	,
MA_RISK_REVENUE_VARIANCE	DECIMAL	(20,3)	,
TOTAL_PREMIUM_YTD	MONEY		,
MID_YEAR_UPDATE_ACTUAL	SMALLMONEY		,
EST_RECEIVABLE_AMOUNT_AFTER_DELETE	DECIMAL	(12,4)	,
AMOUNT_DELETE	DECIMAL	(12,4)	,
RISK_SCORE_NEW_AFTER_DELETE	DECIMAL	(10,3)	,
DIFF_AFTER_DELETE	DECIMAL	(19,4)	,
PROJECTED_RISK_SCORE_AFTER_DELETE	DECIMAL	(10,3)	,
ESRD	VARCHAR	(4)	,
DefaultInd	VARCHAR	(4)	,
PlanIdentifier	INT		)



CREATE NONCLUSTERED INDEX Demographics_IDX ON #Demographics  (HICN, DATE_FOR_FACTORS) INCLUDE (Paymstart) --31532

 
 INSERT INTO #Demographics 
 SELECT 
			@Payment_Year Payment_year,
			@MYU MYU,
			b.DATE_FOR_FACTORS,
			a.HICN, 
			aG.Description AgeGrp ,
			CASE WHEN DEMO.Gender = 1 THEN  'M' 
			 WHEN DEMO.Gender = 2 THEN 'F' END AS SEX,
			( CASE WHEN DEMO.Medicaid = '1' AND DEMO.AgeGrp < 6565
			THEN '1'
			WHEN DEMO.OREC = '1' AND DEMO.AgeGrp <6565  
			THEN '0'
			WHEN DEMO.OREC <> '1' 
			THEN '0'			
			ELSE DEMO.OREC 
			END  )as OREC_CALC,            
			a.RAFT_ORIG,
			DEMO.Medicaid  , --31532
			mor.MAX_MOR as MAX_MOR,
			CASE WHEN mm.HICN IS NOT NULL THEN 'Y' 
			ELSE '' END  MID_YEAR_UPDATE_FLAG,            
			ag.AgeGroupID, 
			a.Gender,
			a.PaymStart,
			CAST (NULL AS DECIMAL (10, 3)) as RiskScore_New,
			a.RS_old,
			CAST (NULL AS DECIMAL (10, 3)) AS DIFF,
			a.SCC,
			a.PBP,
			RP.PlanID,
			CASE WHEN ISNULL(DCP.Months,0) >= 12 AND A.RAFT = 'E' THEN 'C'
			ELSE  CAST (a.RAFT AS  VARCHAR (10)) END AS RAFT, 
			BID.MA_BID AS BID ,
			A.HOSP,
			CAST (NULL AS DECIMAL (12, 4)) ESTIMATED_RECEIVABLE_AMOUNT,
			CASE WHEN NF.HICN IS NOT NULL 
			THEN 'Y' ELSE '' END NewEnrolleeErrorFlag,       
			CASE WHEN ISNULL(DCP.Months,0) > 12 THEN 12 ELSE ISNULL(DCP.MONTHS,0) END  AS MONTHS_IN_DCP,         
			'' AS ISAR_USED,      
			CAST(NULL AS [decimal](10, 3) )as Projected_Risk_score,   
			1 as MEMBER_MONTH,
			0 AS ACTUAL_FINAL_PAID, ---MMS.TotalPayment, 
			MMS.MA_RISK_REVENUE_A_B,
			CAST(NULL AS [decimal](20, 3) ) AS MA_RISK_REVENUE_RECALC, 
			CAST(NULL AS [decimal](20, 3) ) AS MA_RISK_REVENUE_VARIANCE, 
			MMS.TOTAL_PREMIUM_YTD,
			mm.MID_YEAR_UPDATE_ACTUAL,  
			CAST(NULL AS [decimal](12, 4) ) AS EST_RECEIVABLE_AMOUNT_AFTER_DELETE,
			CAST(NULL AS [decimal](12, 4) )AS AMOUNT_DELETE,  
			CAST (NULL AS DECIMAL (10, 3)) RISK_SCORE_NEW_AFTER_DELETE,    
			CAST(NULL AS [decimal](19, 4) ) AS DIFF_AFTER_DELETE,
			CAST(NULL AS [decimal](10, 3) )PROJECTED_RISK_SCORE_AFTER_DELETE,    
			MMS.ESRD, 
			MMS.DefaultInd, 
			RP.PlanIdentifier  
 FROM #TBL_ESTRECV_MMR a
		 LEFT JOIN #DATE_FOR_FACTORS B ON b.hicn = a.hicn 
		 LEFT JOIN #DEMO DEMO ON DEMO.HICN = A.HICN 
		 LEFT JOIN #NEW_ENROLLEE_ERROR_FLAG NF ON NF.HICN = A.HICN 
		 LEFT JOIN #MID_YEAR_UPDATE_FLAG mm ON mm.HICN = a.HICN AND MM.PaymStart = A.PaymStart
		 LEFT JOIN #MAX_MOR mor ON mor.HICN = a.HICN and mor.PaymStart = b.DATE_FOR_FACTORS                  
		 LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON ag.Description = a.AgeGrp
		 LEFT JOIN dbo.tbl_BIDS_rollup bid on bid.Bid_Year = a.Payment_year and a.PBP = bid.PBP and a.SCC = bid.scc and bid.PlanIdentifier = a.PlanID
		 LEFT JOIN #MONTHS_IN_DCP DCP ON DCP.HICN = A.HICN 	
		 LEFT JOIN #Tbl_Member_Months MMS ON MMS.HICN = A.HICN AND MMS.PaymStart = A.PaymStart	
		 LEFT JOIN [$(HRPInternalReportsDB)].DBO.RollupPlan RP ON RP.PlanIdentifier = A.PlanID
 WHERE  a.Payment_Year = @Payment_Year 
         AND  A.PlanID = @PlanID
         

---UPDATE ISAR_USED, BID AMOUNTS FOR ESRD         

UPDATE #Demographics
SET ISAR_USED = 'Y'
WHERE BID IS NULL

UPDATE a
SET BID = MA_BID
from        #Demographics a
CROSS APPLY (SELECT MA_BID
	FROM dbo.TBL_BIDS_ROLLUP B with (nolock)
	WHERE BID_YEAR=@Payment_Year
		AND a.PBP=B.PBP
		AND A.PlanIdentifier = B.PlanIdentifier
		AND 'OOA'=B.SCC)  z
WHERE a.BID IS NULL


UPDATE ER
SET BID = ESRD.Rate
FROM       #Demographics    ER  
INNER JOIN [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD ESRD ON ER.SCC = ESRD.Code
WHERE ESRD.PayMo = @Payment_Year
	AND ER.RAFT in ('D', 'ED')

UPDATE #Demographics
SET ISAR_USED = ' '
WHERE BID IS NULL

--- THIS SETS THE MOR TO THE MAX MOR FOR MEMBERS THAT DID NOT HAVE A MID YEAR UPDATE
UPDATE A
SET MAX_MOR = Max_PayMonth
from        #Demographics                   a
cross apply (SELECT MAX(Paymo) as Max_PayMonth
	FROM dbo.MOR_rollup B with (nolock)
	WHERE a.hicn=B.HICN
		AND B.Paymo LIKE @payment_year+'%') c
WHERE isnull(MID_YEAR_UPDATE_FLAG,'N') <>'Y' AND isnull(MAX_MOR,'')<>@PAYMO
AND A.RAFT IN ('C', 'I'); ---31532


/***************************************************************
GETTING THE MAX VALUES FROM #DEMOGRAPHICS FOR FACTOR VALUES  :
****************************************************************/
--CALCULATING RISK FACTOR
IF OBJECT_ID('tempdb..#popul') > 0
	DROP TABLE #popul

SELECT (d.DATE_FOR_FACTORS) DATE_FOR_FACTORS
	,(d.HICN) HICN
	,(d.AgeGrp) AgeGrp
	,(d.sex) sex
	,(d.OREC_CALC) OREC_CALC
	,(d.Medicaid) Medicaid
	,(d.RAFT) RAFT
	, d.RAFT_ORIG 
	,MAX(d.PaymStart) PaymStart
INTO #Popul
FROM #Demographics d
GROUP BY (d.DATE_FOR_FACTORS)
	,(d.HICN)
	,(d.AgeGrp)
	,(d.sex)
	,(d.OREC_CALC)
	,(d.Medicaid)
	,(d.RAFT)
	, d.RAFT_ORIG
/***********************************************************
GETTING THE FACTOR VALUES FOR DEMOGRAPHICS FOR CURRENT YEAR:
************************************************************/
--Exec tempdb..sp_help #Demofactors
IF OBJECT_ID('tempdb..#DemoFactors')>0
DROP TABLE #Demofactors
CREATE TABLE #Demofactors
(HICN	VARCHAR	(12)	,
AgeGrp	INT		,
Factor	DECIMAL	(20,4)	,
HCC	VARCHAR	(19)	,
Factor_Description	VARCHAR	(50)	,
RAFT	VARCHAR	(4)	,
RAFT_ORIG	VARCHAR	(10)	,
DeleteFlag	INT		,
Payment_year	VARCHAR	(4)	,
DATE_FOR_FACTORS	DATETIME		
)

INSERT INTO #DemoFactors
/**AGE/SEX <> 'E' **/
SELECT DISTINCT d.hicn, 
                d.AgeGrp, 
                B.Factor, 
                'AGE/SEX' as HCC, 
                B.Factor_Description, 
                d.raft, 
                d.RAFT_ORIG, 
                0 as DeleteFlag, 
                @Payment_Year Payment_year, 
                d.DATE_FOR_FACTORS

FROM #popul p
INNER JOIN #Demographics d ON d.HICN = p.HICN   
LEFT  JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.AgeGroupID = ag.AgeGroupID
LEFT  JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender=B.GENDER 
            AND ag.Description = B.Factor_Description AND d.RAFT = b.Factor_Type
			AND b.Part_C_D_Flag = 'C'
			AND d.OREC_CALC = b.OREC 
			AND b.Payment_Year = @Payment_Year
WHERE d.raft NOT IN ( 'E', 'E1', 'E2', 'ED', 'C', 'I') --31532 added C and I to NOT IN clause

UNION 

/**AGE/SEX = 'E' **/
SELECT DISTINCT d.hicn, 
                d.AgeGrp, 
                B.Factor, 
                'AGE/SEX', 
                B.Factor_Description, 
                d.raft, 
                d.RAFT_ORIG, 
                0, 
                @Payment_Year, 
                d.DATE_FOR_FACTORS
FROM #popul p
inner join #Demographics d on d.HICN = p.HICN 
left  JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag on d.AgeGroupID = ag.AgeGroupID
left  JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender=B.GENDER AND ag.Description = B.Factor_Description and d.RAFT = b.Factor_Type
			and b.Part_C_D_Flag = 'C'
			and d.OREC_CALC = b.OREC 
			and isnull(cast(d.MEDICAID as varchar(4)), '9999') = cast(b.Medicaid_Flag as varchar(4))
			and b.Payment_Year = @Payment_Year
where d.raft IN ( 'E1', 'E2', 'ED') --31532 removed E

UNION 

/**DISABILITY**/
SELECT distinct d.HICN , 
                C.OREC, 
                C.Factor, 
                'DISABILITY',
                ' ' ,
                d.raft, 
                d.RAFT_ORIG,  
                0, 
                @Payment_Year ,
                d.DATE_FOR_FACTORS
  FROM   #popul p
  INNER JOIN #Demographics d on d.HICN = p.HICN 
  JOIN 
		(SELECT DISTINCT Factor_Type, Factor, Gender, OREC, isnull(Medicaid_Flag, 0) as Medicaid_Flag
		 FROM [$(HRPReporting)].dbo.lk_risk_models c
		 WHERE Factor_Description = 'Medicaid Disability'
		 and OREC = 1
		 and Medicaid_Flag = 9999
		 and Payment_Year = @Payment_Year) c  on d.Gender= C.Gender
	and d.raft = c.Factor_Type
	and d.OREC_CALC = c.OREC
	and d.AgeGrp > 6565	
WHERE D.raft NOT IN  ( 'E', 'C', 'I') --31532

UNION	

/**MEDICAID < 6565 **/
/**MEDICAID DISABILITY, MEDICAID ELSE DISABILITY**/
SELECT distinct p.hicn, 
        C.Medicaid_Flag, C.Factor, 
		Case 
		when d.Medicaid = '1' and d.OREC_CALC = '1' then 'MEDICAID DISABILITY'
		when d.Medicaid = '1' and d.OREC_CALC = '0' then 'MEDICAID'
		else 'DISABILITY'
		End,
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@Payment_Year, 
      d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		JOIN [$(HRPReporting)].dbo.lk_risk_models c on d.Gender= C.Gender
			AND  d.OREC_CALC = c.OREC 
			AND d.Medicaid = c.Medicaid_Flag
			AND d.raft = c.Factor_Type
			AND c.Factor_Description = 'Medicaid Disability'
			AND c.Payment_Year = @Payment_Year
			AND d.AgeGrp < 6565
      WHERE D.raft NOT IN  ( 'E', 'C', 'I') --31532

UNION

/**MEDICAID > 6565 **/
SELECT DISTINCT 
		p.hicn, 
		C.Medicaid_Flag, 
		C.Factor, 
		'MEDICAID',
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@Payment_Year, 
        d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		JOIN 
			(Select Factor_Type, Factor, Gender, isnull(Medicaid_Flag,0) Medicaid_Flag
			 from [$(HRPReporting)].dbo.lk_risk_models c
			 where Medicaid_Flag = 1
			 and Factor_Description = 'Medicaid Disability'
			 and OREC = 0
			 and Payment_Year = @Payment_Year) c
			  on d.Gender = C.Gender
		and isnull(d.Medicaid,0) = c.Medicaid_Flag
		and d.raft = c.Factor_Type
		and d.AgeGrp > 6565
  WHERE D.raft NOT IN  ( 'E', 'C', 'I') --31532


UNION 
/**GRAFT **/
SELECT DISTINCT p.hicn, C.Medicaid_Flag, C.Factor, 
		 'GRAFT',
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@Payment_Year, 
        d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		join [$(HRPReporting)].dbo.lk_risk_models c on d.RAFT = c.Factor_Type
		and D.AGEGRP = c.Factor_Description 
		WHERE Demo_Risk_Type = 'Graft'
		AND C.PAYMENT_YEAR = @Payment_Year
       AND D.raft NOT IN  ( 'E', 'C', 'I') --31532
 
UNION 

SELECT DISTINCT p.hicn, C.Medicaid_Flag, C.Factor, 
		 'GRAFT',
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@Payment_Year, 
        d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		JOIN [$(HRPReporting)].dbo.lk_risk_models c on d.RAFT = c.Factor_Type
		WHERE Demo_Risk_Type = 'Graft'
		and c.Factor_Description = 9999
		AND C.PAYMENT_YEAR = @Payment_Year
        AND  D.raft NOT IN  ( 'E', 'C', 'I') --31532


/******************************
*******************************
MODEL SPLIT FOR DEMOGRAPHICS:
*******************************
*******************************/
IF OBJECT_ID('tempdb..#DemoFactors_ModelSplit') > 0
DROP TABLE #Demofactors_ModelSplit
CREATE TABLE #Demofactors_ModelSplit
(
	HICN	VARCHAR	(12)	,
	AgeGrp	INT		,
	Factor	DECIMAL	(20,4)	,
	HCC	VARCHAR	(19)	,
	Factor_Description	VARCHAR	(50)	,
	RAFT	VARCHAR	(10)	,
	RAFT_ORIG	VARCHAR	(2)	,
	DeleteFlag	INT		,
	Payment_year	VARCHAR	(4)	,
	DATE_FOR_FACTORS	SMALLDATETIME
)
IF (SELECT COUNT(1) FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits WHERE PaymentYear = @Payment_Year) > 1
BEGIN
----DECLARE @MODELYEAR VARCHAR (4) = '2013'
IF OBJECT_ID('tempdb..#ModelYear') > 0
DROP TABLE #ModelYear
CREATE TABLE #ModelYear
(   ID INT IDENTITY(1,1),
	Paymentyear VARCHAR (4), 
	Modelyear VARCHAR (4))

INSERT INTO #ModelYear
(Paymentyear, Modelyear)
SELECT PaymentYear, ModelYear FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits WHERE PaymentYear = @Payment_Year
END


DECLARE @I INT
DECLARE @MYcount INT
DECLARE @ModelYear VARCHAR (4)
SET @MYcount = (SELECT COUNT (Modelyear) FROM #ModelYear)
SET @I = 1
WHILE (@I <= @MYcount)

BEGIN	
SELECT @ModelYear = modelyear from #ModelYear where ID = @I	
			
/****************************************************************************
GETTING THE FACTOR VALUES FOR DEMOGRAPHICS FOR PREVIOUS YEAR FOR MODEL SPLIT:
*******************************************************************************/
INSERT INTO #Demofactors_ModelSplit

SELECT DISTINCT d.hicn
	,d.AgeGrp
	,B.Factor
	,'AGE/SEX' AS HCC
	,B.Factor_Description
	,d.raft
	,d.RAFT_ORIG
	,0 AS DeleteFlag
	,@ModelYear Payment_year
	,d.DATE_FOR_FACTORS
FROM #popul p
INNER JOIN #Demographics d ON d.HICN = p.HICN
LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.AgeGroupID = ag.AgeGroupID
LEFT JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender = B.GENDER
	AND ag.Description = B.Factor_Description
	AND d.RAFT = b.Factor_Type
	AND b.Part_C_D_Flag = 'C'
	AND d.OREC_CALC = b.OREC
	AND b.Payment_Year = @ModelYear
WHERE d.raft NOT IN (
		'E'
		,'E1'
		,'E2'
		,'ED'
		)

UNION

SELECT DISTINCT d.hicn
	,d.AgeGrp
	,B.Factor
	,'AGE/SEX'
	,B.Factor_Description
	,d.raft
	,d.RAFT_ORIG
	,0
	,@ModelYear
	,d.DATE_FOR_FACTORS
FROM #popul p
INNER JOIN #Demographics d ON d.HICN = p.HICN
LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.AgeGroupID = ag.AgeGroupID
LEFT JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender = B.GENDER
	AND ag.Description = B.Factor_Description
	AND d.RAFT = b.Factor_Type
	AND b.Part_C_D_Flag = 'C'
	AND d.OREC_CALC = b.OREC
	AND isnull(cast(d.MEDICAID AS VARCHAR(4)), '9999') = cast(b.Medicaid_Flag AS VARCHAR(4))
	AND b.Payment_Year = @ModelYear
WHERE d.raft IN (
		'E'
		,'E1'
		,'E2'
		,'ED'
		)
UNION 
SELECT DISTINCT d.HICN , 
                C.OREC, 
                C.Factor, 
                'DISABILITY',
                ' ' , 
                d.raft, 
                d.RAFT_ORIG,  
                0, 
                @ModelYear  ,  
                d.DATE_FOR_FACTORS
  FROM   #popul p
  INNER JOIN #Demographics d on d.HICN = p.HICN 
  JOIN 
		(SELECT DISTINCT Factor_Type, Factor, Gender, OREC, isnull(Medicaid_Flag, 0) as Medicaid_Flag
		 FROM [$(HRPReporting)].dbo.lk_risk_models c
		 WHERE Factor_Description = 'Medicaid Disability'
		 and OREC = 1
		 and Medicaid_Flag = 9999
		 and Payment_Year =  @ModelYear ) c  on d.Gender= C.Gender
	and d.raft = c.Factor_Type
	and d.OREC_CALC = c.OREC
	and d.AgeGrp > 6565	
WHERE D.raft IN  ( 'E', 'C', 'I') --31532

UNION	
SELECT DISTINCT p.hicn, C.Medicaid_Flag, C.Factor, 
		CASE 
		WHEN d.Medicaid = '1' and d.OREC_CALC = '1' then 'MEDICAID DISABILITY'
		WHEN d.Medicaid = '1' and d.OREC_CALC = 0 then 'MEDICAID'
		ELSE 'DISABILITY'
		END,
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@ModelYear, 
        d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		join [$(HRPReporting)].dbo.lk_risk_models c on d.Gender= C.Gender
			and  d.OREC_CALC = c.OREC 
			and d.Medicaid = c.Medicaid_Flag
			and d.raft = c.Factor_Type
			and c.Factor_Description = 'Medicaid Disability'
			and c.Payment_Year =  @ModelYear
			and d.AgeGrp < 6565
WHERE D.raft IN  ( 'E', 'C', 'I') --31532

Union
SELECT DISTINCT p.hicn, C.Medicaid_Flag, C.Factor, 
		 'MEDICAID',
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@ModelYear, 
        d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		join 
			(Select Factor_Type, Factor, Gender, isnull(Medicaid_Flag,0) Medicaid_Flag
			 from [$(HRPReporting)].dbo.lk_risk_models c
			 where Medicaid_Flag = 1
			 and Factor_Description = 'Medicaid Disability'
			 and OREC = 0
			 and Payment_Year = @ModelYear) c
			  on d.Gender = C.Gender
		and isnull(d.Medicaid,0) = c.Medicaid_Flag
		and d.raft = c.Factor_Type
		and d.AgeGrp > 6565
WHERE D.raft IN  ( 'E', 'C', 'I') --31532
		
UNION 		
/**GRAFT **/
SELECT DISTINCT p.hicn, C.Medicaid_Flag, C.Factor, 
		 'GRAFT',
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@ModelYear, 
        d.DATE_FOR_FACTORS
		FROM   #popul p 
		INNER JOIN #Demographics d on d.HICN = p.HICN 
		join [$(HRPReporting)].dbo.lk_risk_models c on P.RAFT = c.Factor_Type  ---31532
		and D.AGEGRP = c.Factor_Description 
		WHERE Demo_Risk_Type = 'Graft'
		AND C.PAYMENT_YEAR = @ModelYear
        AND D.raft IN  ( 'E', 'C', 'I') --31532

UNION 

SELECT DISTINCT p.hicn, C.Medicaid_Flag, C.Factor, 
		 'GRAFT',
		' ',
		d.RAFT,
		d.RAFT_ORIG,   
		0,
		@ModelYear, 
        d.DATE_FOR_FACTORS
	FROM   #popul p 
	INNER JOIN #Demographics d on d.HICN = p.HICN 
	join [$(HRPReporting)].dbo.lk_risk_models c on P.RAFT = c.Factor_Type --31532
	where Demo_Risk_Type = 'Graft'
	and c.Factor_Description = 9999
	AND C.PAYMENT_YEAR = @ModelYear
    AND D.raft IN  ( 'E', 'C', 'I') --31532
		

SET @I = @I + 1

END

/******************************************************************************
RAPS, MOR, DEMOGRAPHIC FACTOR VALUES TOGETHER FOR PAYMENT YEAR AND MODEL YEAR:
*******************************************************************************/

IF OBJECT_ID('Tempdb..#Buildup')>0
DROP TABLE #Buildup

----/**RAPS FACTOR VALUES FOR BOTH YEARS**/
SELECT a.PlanID
	,a.HICN
	,b.Factor AS Factor
	,a.Factor_Desc_ORIG HCC_Label
	,d.AgeGroupID,
	a.PaymentYear
	,d.MYU
	,@populate_date AS populated
	,a.Factor_Desc_EstRecev HCC_hierarchy
	,CASE 
		WHEN a.Factor_Desc_EstRecev LIKE '%HIER%'
			THEN 0
		ELSE b.Factor --31532
		END AS factor_Hierarchy
	,a.Factor_Desc_EstRecev  AS HCC_Delete_Hierarchy
	,CASE 
		WHEN a.Factor_Desc_EstRecev LIKE '%DEL%'
			THEN 0
		WHEN a.Factor_Desc_EstRecev LIKE '%HIER%'
			THEN 0
		ELSE b.Factor  --31532
		END AS FActor_delete_hierarchy
	,a.RAFT
	,a.Model_Year
	,CASE 
		WHEN A.Factor_Desc_EstRecev LIKE '%DEL%'
			THEN 1
		ELSE 0
		END AS Delete_flag
	,D.DATE_FOR_FACTORS
	,A.HCC_Number
INTO #Buildup
FROM tbl_EstRecv_RiskFactorsRAPS a
JOIN [$(HRPReporting)].dbo.lk_Risk_Models b ON b.Factor_Type = a.RAFT
	AND b.Payment_Year = a.Model_Year
	AND Factor_Desc_ORIG = B.Factor_Description
 JOIN #Demographics d on d.hicn = a.hicn
WHERE a.Planid = @PlanID
	AND a.PaymentYear = @Payment_Year
	AND a.PaymStart IS NOT NULL
GROUP BY A.PlanID, A.PaymentYear, A.Factor_Desc_EstRecev, A.Factor_Desc_ORIG, A.HCC_Number, A.HICN, A.Factor, A.RAFT, a.Model_Year, b.Factor,
d.DATE_FOR_FACTORS, d.MYU, d.AgeGroupID



/**DEMOGRAPHIC FACTOR VALUES FROM PAYMENT YEAR**/
INSERT INTO #buildup
SELECT 
       d.PlanIdentifier , 
       df.hicn, 
       df.factor, 
       df.hcc, 
       d.agegroupid ,
       d.payment_year,
       D.MYU,
       @populate_date,
       df.hcc   HCC_hierarchy,
       df.factor AS Factor_Hierarchy,
       df.hcc AS HCC_Delete_hierarchy,
       df.Factor AS Factor_delete_Hierarchy,
       df.raft,
       d.Payment_year,
       df.DeleteFlag,
       D.DATE_FOR_FACTORS,
       0
   FROM #demofactors df
   INNER JOIN #demographics d  ON d.hicn = df.hicn 
                                  AND  d.paymstart =  df.DATE_FOR_FACTORS

 	

/**CONDITION APPLIES WHEN THERE IS MODEL SPLIT IT TAKES PREVIOUS YEAR DEMOGRAPHIC FACTOR VALUES**/ 		
 			
IF (SELECT COUNT(1) FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits WHERE PaymentYear = @Payment_Year) > 1

BEGIN

INSERT INTO #buildup
     SELECT 
       d.PlanIdentifier , 
       df.hicn, 
       df.factor, 
       df.hcc, 
       d.agegroupid ,
       d.payment_year,
       MYU,
      @populate_date,
       df.hcc   HCC_hierarchy,
       df.factor AS Factor_Hierarchy,
       df.HCC AS HCC_Delete_hierarchy,
       df.Factor AS Factor_delete_Hierarchy,
       df.raft,
       df.Payment_year,
       df.DeleteFlag,
       D.DATE_FOR_FACTORS,
       0
   FROM #Demofactors_ModelSplit df
   INNER JOIN #Demographics d  ON d.hicn = df.hicn AND  d.paymstart =  df.DATE_FOR_FACTORS
   WHERE DF.RAFT IN('C', 'E', 'I')
END



/**MOR DATA IS CONSIDERED ONLY WHEN THE PAYMONTH IS GREATER THAN OR EQUAL TO @PAYMENT_YEAR_ '07'**/

IF  (SELECT MAX(Paymo) FROM MOR_rollup WHERE LEFT(Paymo,4)=@Payment_Year)>= @PAYMO
BEGIN 

INSERT INTO #buildup
SELECT DISTINCT 
                a.PlanID,  
                a.HICN, 
                E.Factor  AS Factor,--31532
                CASE WHEN A.RAFT = 'HP' 
                     THEN A.Factor_Desc 
                     ELSE E.Factor_Description END Factor_Description, 
                d.AgeGroupID, 
                a.PaymentYear, 
                d.MYU, 
                @populate_date  as populated ,                  
                A.Factor_Desc AS HCC_hierarchy , 
                 CASE WHEN a.Factor_Desc LIKE '%HIER%' 
                      THEN 0
                      ELSE e.Factor END  AS factor_Hierarchy, --31532
                 A.Factor_Desc AS HCC_Delete_Hierarchy,
                 CASE WHEN a.Factor_Desc LIKE '%DEL%' 
					  THEN 0 
					  WHEN a.factor_desc LIKE '%HIER%'
					  THEN 0
					  ELSE E.Factor --31532 
					  END  AS  FActor_delete_hierarchy,  
                a.RAFT, 
                a.Model_Year,
                CASE WHEN A.Factor_Desc LIKE '%DEL%'
                     THEN 1 ELSE 0 END AS Delete_flag ,
                D.DATE_FOR_FACTORS  ,
                A.HCC_Number           
FROM tbl_EstRecv_RiskFactorsMOR a 
LEFT JOIN #Demographics d on d.hicn = a.hicn
LEFT JOIN dbo.Converted_MOR_Data_rollup B ON B.HICN = A.HICN 
LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Models E on E.Factor_Type = a.RAFT 
                    AND E.Payment_Year = a.Model_Year 
                    AND(CASE WHEN  a.Factor_Desc LIKE '%HIER%' 
                          THEN RTRIM(LTRIM(CAST(SUBSTRING(a.Factor_Desc,6,LEN(a.Factor_Desc)-3) AS VARCHAR (20))))
						  WHEN  a.Factor_Desc LIKE '%DEL%' 
					      THEN RTRIM(LTRIM(CAST(SUBSTRING(a.Factor_Desc,5,LEN(a.Factor_Desc)-3) AS VARCHAR (20)))) 
                          ELSE  a.Factor_Desc END)= E.Factor_Description 
					AND e.Part_C_D_Flag = 'C'
										
WHERE  a.PaymentYear = @Payment_Year 
		AND A.PlanID = @PlanID 
		AND PaymentYear = LEFT(B.PayMonth, 4)
		AND  b.PayMonth >= @PAYMO
		AND RIGHT(B.PayMonth,2) = MONTH(A.PaymStart)
		--and a.HICN = '518346168A'

   AND NOT EXISTS (SELECT 1 FROM #BUILDUP RAPS WHERE RAPS.HICN = A.HICN 
		                                             AND A.HCC_Number = RAPS.HCC_Number
		                                             AND A.MODEL_YEAR = RAPS.Model_Year
		                                             AND A.RAFT = RAPS.RAFT )--31532
	

INSERT INTO #buildup
SELECT DISTINCT

	a.PlanIdentifier,  
	a.HICN, 
	E.Factor AS Factor,
	E.Factor_Description, 
	a.AgeGroupID, 
	a.Payment_year, 
	a.MYU,
	@populate_date as populated ,                  
	mor.Factor_Desc as HCC_hierarchy  ,
	CASE WHEN mor.Factor_Desc LIKE '%HIER%' 
	THEN 0
	ELSE E.Factor END  AS factor_Hierarchy, --31532
	mor.Factor_Desc  as HCC_Delete_Hierarchy,
	CASE WHEN mor.Factor_Desc LIKE '%DEL%' 
	THEN 0 
	WHEN mor.factor_desc LIKE '%HIER%'
	THEN 0
	ELSE E.Factor 
	END  AS  FActor_delete_hierarchy,  
	a.RAFT, 
	mor.Model_Year,
	CASE WHEN mor.Factor_Desc LIKE '%DEL%'
	THEN 1 ELSE 0 END AS Delete_flag ,
	a.DATE_FOR_FACTORS  ,
	mor.HCC_Number        
FROM   #Demographics A 
JOIN Converted_MOR_Data_rollup B ON A.hicn=B.HICN AND A.MAX_MOR=B.PAYMONTH
JOIN [$(HRPReporting)].dbo.lk_risk_models E ON b.Name = E.Factor_Description AND a.raft = e.Factor_Type 
JOIN DBO.tbl_EstRecv_RiskFactorsMOR MOR ON MOR.HICN = A.HICN AND b.Name  = MOR.Factor_Desc
          AND  CONVERT(VARCHAR (4), YEAR(MOR.PaymStart)) + REPLACE(STR(DATEPART(MM, MOR.PAYMSTART), 2),' ','0') = A.MAX_MOR
	WHERE  e.Payment_Year = mor.Model_Year --31532
	AND e.Part_C_D_Flag = 'C'
	AND b.PlanIdentifier = @PlanID
	AND MOR.PaymentYear = @Payment_Year
	AND MOR.PlanID = @PlanID
	 AND NOT EXISTS (SELECT 1 FROM #BUILDUP RAPS WHERE RAPS.HICN = A.HICN 
                                         AND mor.HCC_Number = RAPS.HCC_Number
                                         and mor.Model_Year = RAPS.Model_Year
                                         AND A.RAFT = RAPS.RAFT)--31532
                           
				
END 

/*****************************************************  ----31532
RAFT E TO C FOR BUILDUP:
*******************************************************/

IF OBJECT_ID('Tempdb..#RAFT_E_TO_C')>0 --31532
DROP TABLE #RAFT_E_TO_C

SELECT DISTINCT b.hicn
	,b.raft
	,p.raft_orig
	, b.Model_Year
INTO #RAFT_E_TO_C	
FROM #Buildup b
JOIN #Demographics p ON p.HICN = b.HICN
	AND b.DATE_FOR_FACTORS = p.DATE_FOR_FACTORS
WHERE (b.RAFT <> p.RAFT_ORIG)
	AND (
		b.RAFT = 'C'
		AND p.RAFT_ORIG = 'E'
		)
	AND p.MONTHS_IN_DCP = 12


/*******************************
RISKSCORE WITH DELETES:
*******************************/

IF OBJECT_ID('Tempdb..#RISKSCOREWITHDELETES')>0
DROP TABLE #RISKSCOREWITHDELETES

  
  SELECT 
	b.HICN,
	b.RAFT ,
	CASE WHEN b.raft in ('D', 'ED') 
	 THEN ROUND((SUM(b.factor_Hierarchy)/norm.ESRD_Dialysis_Factor),3)
	 WHEN b.raft in ('C1', 'C2', 'G1', 'G2', 'I1', 'I2', 'E1', 'E2') 
	 THEN ROUND(ROUND((SUM(b.factor_Hierarchy)/Norm.FunctioningGraft_Factor),3)*(1-Norm.CodingIntensity),3)
	 WHEN P.HICN IS NOT NULL ---31532
	 THEN Round(ROUND(round((SUM(distinct B.factor_Hierarchy)/ModSplit.NormalizationFactor),3)*(1-Norm.CodingIntensity),3)*ModSplit.SplitSegmentWeight,3)
	 WHEN b.raft in ( 'C', 'E', 'I')
	 THEN Round(ROUND(round((SUM(B.factor_Hierarchy)/ModSplit.NormalizationFactor),3)*(1-Norm.CodingIntensity),3)*ModSplit.SplitSegmentWeight,3)	
	ELSE ROUND(round((SUM(B.factor_Hierarchy)/norm.PartC_Factor),3)*(1-Norm.CodingIntensity),3)
		END AS RISK_SCORE_NEW,
	B.Model_Year,
	b.DATE_FOR_FACTORS
INTO #RISKSCOREWITHDELETES
FROM #Buildup b		
	LEFT JOIN [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits ModSplit ON ModSplit.ModelYear = B.Model_Year
	LEFT JOIN [$(HRPReporting)].DBO.LK_NORMALIZATION_FACTORS Norm ON Norm.[Year] = ModSplit.PaymentYear
	LEFT JOIN #RAFT_E_TO_C p ON p.HICN = b.HICN and p.Model_Year = b.Model_Year	
WHERE ModSplit.PaymentYear = @Payment_Year 
    AND B.Delete_flag = 0
GROUP BY B.HICN, 
         B.RAFT,
         B.Model_Year, 
         norm.ESRD_Dialysis_Factor,  
         ModSplit.SplitSegmentWeight, 
         Norm.FunctioningGraft_Factor, 
         Norm.CodingIntensity,
         ModSplit.NormalizationFactor, 
         PartC_Factor,
         b.DATE_FOR_FACTORS, 
         P.HICN --31532


/*******************************
RISKSCORE WITHOUT DELETES:
*******************************/

IF OBJECT_ID('Tempdb..#RISKSCOREWITHOUTDELETES')>0
DROP TABLE #RISKSCOREWITHOUTDELETES

SELECT 
	b.HICN,
	b.RAFT ,
	CASE WHEN b.raft in ('D', 'ED') THEN ROUND((SUM(b.factor_Hierarchy)/norm.ESRD_Dialysis_Factor),3)
		 WHEN b.raft in ('C1', 'C2', 'G1', 'G2', 'I1', 'I2', 'E1', 'E2') 
		 THEN ROUND(ROUND((SUM(b.factor_Hierarchy)/Norm.FunctioningGraft_Factor),3)*(1-Norm.CodingIntensity),3)
		 WHEN P.HICN IS NOT NULL ---31532
		 THEN Round(ROUND(round((SUM(distinct B.factor_Hierarchy)/ModSplit.NormalizationFactor),3)*(1-Norm.CodingIntensity),3)*ModSplit.SplitSegmentWeight,3)
		 WHEN b.raft in ( 'C', 'E', 'I') 
		 THEN Round(ROUND(round((SUM(B.factor_Hierarchy)/ModSplit.NormalizationFactor),3)*(1-Norm.CodingIntensity),3)*ModSplit.SplitSegmentWeight,3)	
		 
		ELSE ROUND(round((SUM(B.factor_Hierarchy)/norm.PartC_Factor),3)*(1-Norm.CodingIntensity),3)
			END AS RISK_SCORE_NEW,
	B.Model_Year,
	b.DATE_FOR_FACTORS
INTO #RISKSCOREWITHOUTDELETES
FROM #Buildup b		
	LEFT JOIN [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits ModSplit ON ModSplit.ModelYear = B.Model_Year
	LEFT JOIN [$(HRPReporting)].DBO.LK_NORMALIZATION_FACTORS Norm ON Norm.[Year] = ModSplit.PaymentYear
	LEFT JOIN #RAFT_E_TO_C p ON p.HICN = b.HICN and p.Model_Year = b.Model_Year 
WHERE ModSplit.PaymentYear = @Payment_Year 
      
GROUP BY B.HICN, 
         B.RAFT,
         norm.ESRD_Dialysis_Factor,  
         ModSplit.SplitSegmentWeight, 
         Norm.FunctioningGraft_Factor, 
         Norm.CodingIntensity,
         ModSplit.NormalizationFactor, 
         PartC_Factor, 
         B.Model_Year,
         b.DATE_FOR_FACTORS, 
         p.RAFT_ORIG, 
         P.HICN --31532


/***********************
--RISK SCORE AGGREGATES
*************************/
       
IF OBJECT_ID('Tempdb..#RISKSCOREWITHDELETES_AGG')>0
DROP TABLE #RISKSCOREWITHDELETES_AGG
 
      
 SELECT
	A.HICN, 
	A.RAFT, 
	SUM(A.RISK_SCORE_NEW)RISK_SCORE_NEW, 
	A.DATE_FOR_FACTORS
INTO #RISKSCOREWITHDELETES_AGG
  FROM #RISKSCOREWITHDELETES A 
   GROUP BY A.HICN , 
            A.RAFT,
            A.DATE_FOR_FACTORS


IF OBJECT_ID('Tempdb..#RISKSCOREWITHOUTDELETES_AGG')>0
DROP TABLE #RISKSCOREWITHOUTDELETES_AGG
        
SELECT
	A.HICN, 
	A.RAFT, 
	SUM(A.RISK_SCORE_NEW)RISK_SCORE_NEW, 
	A.DATE_FOR_FACTORS
	INTO #RISKSCOREWITHOUTDELETES_AGG
  FROM #RISKSCOREWITHOUTDELETES A 
   GROUP BY A.HICN , 
            A.RAFT,
            A.DATE_FOR_FACTORS

---CONVERT THE MEDICAID BACK TO NULL WHERE IT IS SET TO '9999'

UPDATE #Demographics SET Medicaid = NULL
WHERE Medicaid = '9999'


/**********************************
ESTIMATED RECEIVABLES CALCULATION:
***********************************/
UPDATE #Demographics SET MA_RISK_REVENUE_RECALC = (RS_old*BID) 
WHERE MA_RISK_REVENUE_A_B <>0 
and #Demographics.RAFT <> 'HOSP'


UPDATE #Demographics SET MA_RISK_REVENUE_VARIANCE = 
(MA_RISK_REVENUE_A_B-MA_RISK_REVENUE_RECALC)
where #Demographics.RAFT <> 'HOSP'


UPDATE A SET A.RAFT = 'HOSP' 
            FROM #Demographics A 
                     INNER JOIN #TBL_Member_months B ON A.HICN=B.HICN AND A.PaymStart=B.PAYMSTART WHERE B.HOSP='Y'

UPDATE  #Demographics 
SET RiskScore_New = (ISNULL(RSAD.RISK_SCORE_NEW,0)) , 
    RISK_SCORE_NEW_AFTER_DELETE = (ISNULL(RSD.RISK_SCORE_NEW,0))
FROM #Demographics D 
LEFT JOIN #RISKSCOREWITHDELETES_AGG RSD ON RSD.HICN = D.HICN  AND ISNULL(D.RAFT, 1) = ISNULL(RSD.RAFT, 1)
LEFT JOIN #RISKSCOREWITHOUTDELETES_AGG RSAD ON   RSAD.HICN = D.HICN  AND ISNULL(D.RAFT, 1) = ISNULL(RSAD.RAFT , 1) 

/*====RAFT NULL RISK SCORE NEW TO RISK SCORE OLD====*/
UPDATE  #Demographics 
SET RiskScore_New = RS_old
FROM #Demographics D 
WHERE RAFT IS NULL ---31532
/*===DIFF TO BE NULL FOR HOSP=====*/
UPDATE A 
SET DIFF= RiskScore_New - RS_old ,
 DIFF_AFTER_DELETE = RISK_SCORE_NEW_AFTER_DELETE - RS_old 
 FROM #Demographics A
 WHERE RAFT NOT IN ('HOSP', 'HP')--31532
		
IF  (SELECT MAX(Paymo) FROM MOR_rollup WHERE LEFT(Paymo,4)=@Payment_Year)>=
	(SELECT DISTINCT Paymonth FROM [$(HRPReporting)].dbo.lk_dcp_dates WHERE LEFT(paymonth,4)=@Payment_Year AND mid_year_update='Y') 
BEGIN
---The following used if MYU MOR Exists
UPDATE #Demographics 
SET ESTIMATED_RECEIVABLE_AMOUNT = (BID*DIFF) WHERE DIFF>0 and RAFT <> 'HOSP' and RAFT not in ('D', 'ED')
UPDATE A
Set ESTIMATED_RECEIVABLE_AMOUNT = (a.DIFF * b.Rate)
FROM #Demographics a
JOIN (SELECT DISTINCT Paymo, Code, Rate FROM [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD WHERE PayMo = @Payment_Year) b ON a.SCC = b.Code
WHERE a.RAFT IN ('D', 'ED')
AND a.DIFF > 0
		
-- Calculate Estimated Receivables after Delete
UPDATE #Demographics 
SET EST_RECEIVABLE_AMOUNT_AFTER_DELETE = 
(BID*(CASE WHEN DIFF < 0 THEN DIFF_AFTER_DELETE - DIFF ELSE DIFF_AFTER_DELETE END)) 
WHERE (DIFF_AFTER_DELETE > 0 OR (DIFF_AFTER_DELETE < 0 AND DIFF_AFTER_DELETE - DIFF <> 0)) 
and RAFT <> 'HOSP' 
and RAFT not in ('D', 'ED')
		
UPDATE A
SET EST_RECEIVABLE_AMOUNT_AFTER_DELETE = ((CASE WHEN DIFF < 0 THEN DIFF_AFTER_DELETE - DIFF ELSE DIFF_AFTER_DELETE END) * b.Rate)
FROM #Demographics a
JOIN (SELECT DISTINCT Paymo, Code, Rate 
               FROM [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD 
               WHERE PayMo = @Payment_Year) b on a.SCC = b.Code
WHERE a.RAFT IN ('D', 'ED')
AND (DIFF_AFTER_DELETE > 0 OR (DIFF_AFTER_DELETE < 0 AND DIFF_AFTER_DELETE - DIFF <> 0)) 
		
UPDATE #Demographics 
SET AMOUNT_DELETE = -1*(ESTIMATED_RECEIVABLE_AMOUNT - EST_RECEIVABLE_AMOUNT_AFTER_DELETE)

END 



IF  (SELECT MAX(paymo) FROM MOR_rollup WHERE LEFT(Paymo,4)=@Payment_Year)<
	(SELECT DISTINCT Paymonth FROM [$(HRPReporting)].dbo.lk_dcp_dates WHERE LEFT(paymonth,4)=@Payment_Year AND mid_year_update='Y') 
BEGIN
UPDATE #Demographics SET ESTIMATED_RECEIVABLE_AMOUNT = (BID*DIFF) WHERE RAFT not in ('D', 'ED', 'HOSP')

UPDATE A
Set ESTIMATED_RECEIVABLE_AMOUNT = (a.DIFF * b.Rate)
from #Demographics a
	join (Select distinct Paymo, Code, Rate from [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD where PayMo = @Payment_Year) b on a.SCC = b.Code
where a.RAFT in ('D', 'ED')

UPDATE #Demographics SET EST_RECEIVABLE_AMOUNT_AFTER_DELETE = (BID*DIFF_AFTER_DELETE) WHERE RAFT not in ('D', 'ED', 'HOSP')

UPDATE A
SET EST_RECEIVABLE_AMOUNT_AFTER_DELETE = (a.DIFF_AFTER_DELETE * b.Rate)
FROM #Demographics a
JOIN (SELECT DISTINCT Paymo, Code, Rate FROM [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD WHERE PayMo = @Payment_Year) b ON a.SCC = b.Code
WHERE a.RAFT in ('D', 'ED')

UPDATE #Demographics SET AMOUNT_DELETE = ESTIMATED_RECEIVABLE_AMOUNT - EST_RECEIVABLE_AMOUNT_AFTER_DELETE
END

		
if  (select Max(Paymo) from MOR_rollup where left(Paymo,4)=@Payment_Year)>=
	(select distinct Paymonth from [$(HRPReporting)].dbo.lk_dcp_dates where left(paymonth,4)=@Payment_Year and mid_year_update='Y') 
begin

UPDATE #Demographics SET PROJECTED_RISK_SCORE = #Demographics.RiskScore_New WHERE DIFF>0
UPDATE #Demographics SET PROJECTED_RISK_SCORE_AFTER_DELETE = 
Case 
	when DIFF < 0 then #Demographics.RISK_SCORE_NEW_AFTER_DELETE - DIFF
	else #Demographics.RISK_SCORE_NEW_AFTER_DELETE
End
WHERE (DIFF_AFTER_DELETE > 0 or (DIFF_AFTER_DELETE < 0 and DIFF_AFTER_DELETE - DIFF <> 0))  --GE
end 

		
if  (select Max(Paymo) from MOR_rollup where left(Paymo,4)=@Payment_Year)<
	(select distinct Paymonth from [$(HRPReporting)].dbo.lk_dcp_dates where left(paymonth,4)=@Payment_Year and mid_year_update='Y') 
begin
	UPDATE #Demographics  SET PROJECTED_RISK_SCORE = #Demographics.RiskScore_New WHERE DIFF <> 0
	UPDATE #Demographics  SET PROJECTED_RISK_SCORE_AFTER_DELETE = #Demographics.RISK_SCORE_NEW_AFTER_DELETE WHERE DIFF_AFTER_DELETE <> 0
end

UPDATE #Demographics SET PROJECTED_RISK_SCORE = RS_old WHERE ISNULL(PROJECTED_RISK_SCORE,0)=0
UPDATE #Demographics SET PROJECTED_RISK_SCORE_AFTER_DELETE = RS_old WHERE ISNULL(PROJECTED_RISK_SCORE_AFTER_DELETE,0) = 0

/**********************
INSERT INTO DETAIL TABLE 
*************************/
IF (@Payment_Year IN (SELECT YEAR FROM [$(HRPReporting)].DBO.lk_normalization_factors WHERE Run_Receivable_Calc = 'Y')
			AND ((SELECT COUNT(*) FROM  #Demographics A, #Buildup B WHERE A.hicn=B.HICN)	
				>0))
BEGIN

INSERT INTO EstRecevDetailPartCAllPlan	
([Payment_Year] ,
	[MYU_Flag],
	[DATE_FOR_FACTORS] ,
	[hicn],
	[AGE] ,
	[SEX],
	[MEDICAID],
	[ORIG_DISAB] ,
	[RA_FACTOR_TYPE_] ,
	[MAX_MOR] ,
	[MID_YEAR_UPDATE_FLAG]  ,
	[AGEGROUPID]  ,
	[GENDERID] ,
	[PAYSTART] ,
	[RISK_SCORE_NEW] ,
	[RISK_SCORE_OLD] ,
	[DIFF],
	[SCC],
	[PBP] ,
	[PLANID] ,
	[RA_FACTOR_TYPE] ,
	[BID] ,
	[EST_RECEIVABLE_AMOUNT]  ,
	[NEW_ENROLLEE_FLAG_ERROR]  ,
	[MONTHS_IN_DCP] ,
	[ISAR_USED]  ,
	[PROJECTED_RISK_SCORE] ,
	[MEMBER_MONTH] ,
	[ACTUAL_FINAL_PAID]  ,
	[MA_RISK_REVENUE_A_B]  ,
	[MA_RISK_REVENUE_RECALC]  ,
	[MA_RISK_REVENUE_VARIANCE]  ,
	[TOTAL_PREMIUM_YTD]  ,
	[MID_YEAR_UPDATE_ACTUAL]  ,
	[Populated]  ,
	[EST_RECEIVABLE_AMOUNT_AFTER_DELETE]  ,
	[AMOUNT_DELETE]  ,
	[RISK_SCORE_NEW_AFTER_DELETE] ,
	[DIFF_AFTER_DELETE] ,
	[PROJECTED_RISK_SCORE_AFTER_DELETE]  ,
	[ESRD] ,
	[DefaultInd] ,
	[PlanIdentifier] 
)

SELECT 
	a.Payment_year, 
	a.MYU,
	A.DATE_FOR_FACTORS,
	A.HICN, 
	A.AgeGrp,
	A.SEX,
	A.Medicaid,
	A.OREC_CALC,
	A.RAFT_ORIG,
	A.MAX_MOR,
	A.MID_YEAR_UPDATE_FLAG,
	A.AgeGroupID,
	A.Gender,
	A.PaymStart,
	A.RiskScore_New,
	A.RS_old,
	A.DIFF,
	A.SCC,
	A.PBP,
	A.PlanID,
	A.RAFT,
	A.BID,
	A.ESTIMATED_RECEIVABLE_AMOUNT,
	A.NewEnrolleeErrorFlag,
	A.MONTHS_IN_DCP,
	A.ISAR_USED,
	A.Projected_Risk_score,
	A.MEMBER_MONTH,
	A.ACTUAL_FINAL_PAID,
	A.MA_RISK_REVENUE_A_B,
	A.MA_RISK_REVENUE_RECALC,
	A.MA_RISK_REVENUE_VARIANCE,
	A.TOTAL_PREMIUM_YTD,
	A.MID_YEAR_UPDATE_ACTUAL,
	@populate_date,
	A.EST_RECEIVABLE_AMOUNT_AFTER_DELETE,
	A.AMOUNT_DELETE,
	A.RISK_SCORE_NEW_AFTER_DELETE,
	A.DIFF_AFTER_DELETE,
	A.PROJECTED_RISK_SCORE_AFTER_DELETE,
	A.ESRD,
	A.DefaultInd,
	A.PlanIdentifier

FROM #Demographics a

END

ELSE 
BEGIN 
INSERT INTO EstRecevDetailPartCAllPlan	
SELECT 
@Payment_Year, 
@MYU,
NULL,
NULL, 
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
@HPlanID, --HPLANID 
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
@populate_date,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
NULL,
@PlanID


END
/*********************************
INSERT INTO BUILDUP TABLE:
**********************************/
IF (SELECT COUNT(1) FROM #Buildup) > 0
BEGIN

INSERT INTO [dbo].[EstRecevDetailBuildupPartCAllPlan] 

SELECT  
    d.[HICN],
	d.[Factor] ,
	d.HCC_Label ,
	d.[AGEGROUPID] ,
	d.paymentyear ,
	d.MYU ,
	d.Populated ,
	d.hcc_hierarchy ,
	d.[Factor_Hierarchy] ,
	d.[HCC_Delete_Hierarchy] ,
	d.[Factor_Delete_Hierarchy] ,
	d.[RAFT],
	d.[Model_Year],
	d.[PlanID]  [PlanIdentifier],
	rp.PlanID [PlanID]
FROM #Buildup d
LEFT JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp on rp.PlanIdentifier = d.PlanID

ORDER BY MODEL_YEAR DESC

END

ELSE 

BEGIN 

INSERT INTO [dbo].[EstRecevDetailBuildupPartCAllPlan] 

SELECT 
    'No Buildup' [HICN],
	NULL ,
	NULL ,
	NULL ,
	@Payment_Year ,
	@MYU ,
	@populate_date ,
	NULL ,
	NULL ,
	NULL ,
	NULL ,
	NULL,
	NULL,
	@PlanID,
	@HPlanID --HPLANID


END 

/*********************************
INSERT INTO BLENDED TABLE:
**********************************/
IF (SELECT COUNT(1) FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits WHERE PaymentYear = @Payment_Year) > 1
BEGIN         
INSERT INTO [dbo].[EstRecevDetailBlendedPartCAllPlan]  

SELECT      A.HICN,
            @Payment_Year Payment_year ,
            @MYU MYU,
            a.RAFT,
            @populate_date as Populated,
            A.Model_year ,
            A.RISK_SCORE_NEW,
            B.RISK_SCORE_NEW RiskScoreafterdelete,
            @PlanID,
            @HPlanID
      FROM #RISKSCOREWITHDELETES A 
      LEFT  JOIN #RISKSCOREWITHOUTDELETES B ON B.HICN = A.HICN and B.Model_Year = A.Model_Year and ISNULL(b.RAFT, 1) = ISNULL(A.RAFT,1)  

END
ELSE 
BEGIN
INSERT INTO [dbo].[EstRecevDetailBlendedPartCAllPlan]
 SELECT DISTINCT  B.HICN,
            @Payment_Year Payment_year ,
            @MYU MYU,
            B.RAFT ,
            @populate_date as Populated,
            B.Model_Year as ModelYear,
            popul.RiskScore_New RISK_SCORE_NEW,
            POPUL.RISK_SCORE_NEW_AFTER_DELETE RISK_SCORE_NEW_AFTER_DELETE,            
            popul.PlanIdentifier,
            popul.PlanID
           FROM #Buildup B 
           INNER JOIN #Demographics popul
           on popul.hicn = b.HICN	
           AND ISNULL(popul.RAFT,1) = ISNULL(b.RAFT,1)

END 


--UPDATE RUN LOG INTO LOG TABLE 

INSERT INTO EstRecvAllPlanLog (
	PopulatedDate
	,PlanID
	,ClientID
	,TargetTableName
	,RunDate
	,payment_year
	,myu
	)

SELECT @populate_date, @HPlanID, @ClientID,'EstRecevDetailPartCSummary',CONVERT(DATE, @populate_date) , @Payment_Year, @MYU
UNION 
SELECT @populate_date, @HPlanID, @ClientID,'EstRecevDetailBuildupPartCSummary',CONVERT(DATE, @populate_date) , @Payment_Year, @MYU 
UNION 
SELECT @populate_date, @HPlanID, @ClientID,'EstRecevDetailBlendedPartCSummary',CONVERT(DATE, @populate_date)  , @Payment_Year, @MYU

/*************************
ESTIMATED RECEIVANLES END
***************************/

END
