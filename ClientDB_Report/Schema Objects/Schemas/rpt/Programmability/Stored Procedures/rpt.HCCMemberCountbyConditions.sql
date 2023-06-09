/************************************************************************        
* Name			:	rpt.[HCCMemberCountbyConditions].proc				*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	2/22/2022									     	*	
* Ticket        :   
* Version		:        												*
* Description	:	 Report HCC Member Count							*

*************************************************************************/   

/*************************************************************************
TICKET       DATE              NAME                DESCRIPTION
RRI 2147     2/22/22           Madhuri Suri       Report HCC Member Count 
**************************************************************************/   

CREATE  PROC [rpt].[HCCMemberCountbyConditions]
	@Paymo AS VARCHAR(6),
	@HCCFilter AS VARCHAR(4), 
	@PlanID VARCHAR(2000)

AS
    BEGIN
        SET NOCOUNT ON

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 --exec [rev].[SummaryReportHCCMemberCount]'202108', 'ALL'

--Testing Params
--DECLARE @paymo VARCHAR(6) = '201004'			-- set PayMonth
--DECLARE @HCCFilter VARCHAR(4) = 'A' 			-- C, D, A - All		
DROP TABLE IF EXISTS  #HCC_Report_spr_HCC_Member_Count
DROP TABLE IF EXISTS  #Count_HCCs_spr_HCC_Member_Count
DROP TABLE IF EXISTS  #HCCs_spr_HCC_Member_Count 

IF OBJECT_ID('TempDB..#PlanID') IS NOT NULL
DROP TABLE #PlanID

CREATE TABLE #PlanID
	(
		Item VARCHAR(200)
	)

INSERT INTO #PlanID
	(
		Item
	)
SELECT Item 
FROM dbo.fnsplit(@PlanID, ',')


CREATE TABLE #HCCs_spr_HCC_Member_Count
  (
     PayMonth VARCHAR(6),
     HICN     VARCHAR(20),
     HCC      VARCHAR(12),
     Note     VARCHAR(100),
	 PlanID VARCHAR(200)
  ) 


CREATE TABLE #Count_HCCs_spr_HCC_Member_Count
  (
     PayMonth VARCHAR(6),
     HICN     VARCHAR(20),
     HCC_Count   INT,
     Note     VARCHAR(100),
	 PlanID VARCHAR(200)
  ) 


  CREATE TABLE #HCC_Report_spr_HCC_Member_Count
  (
     PayMonth VARCHAR(6),
     HCC_Count   INT,
	 Member_Count   INT,
	 Total INT,
     Note     VARCHAR(100),
	 PlanID VARCHAR(200)
  )
--INSERT HICNS WITH HCCS PART C
INSERT INTO #HCCs_spr_HCC_Member_Count
SELECT DISTINCT PayMonth,
                HICN,
                HCC,
                'Members in MOR/MORD', 
				C.PlanID
FROM   rev.SummaryRskAdjMORSourcePartC C
WHERE  PayMonth = @paymo 
	   AND @HCCFilter <> 'D'
	   AND 
	      EXISTS (SELECT 1 FROM #PlanID tp WHERE PlanID = tp.Item)

--INSERT HICNS WITH HCCS PART D
INSERT INTO #HCCs_spr_HCC_Member_Count
SELECT DISTINCT PayMonth,
                HICN,
                HCC,
                'Members in MOR/MORD',
				PlanID
FROM   rev.SummaryRskAdjMORSourcePartD
WHERE  PayMonth = @paymo
	   AND @HCCFilter <> 'C'
	    AND 
	      EXISTS (SELECT 1 FROM #PlanID tp WHERE PlanID = tp.Item)


-- ADD HICNS WITH NO HCCS (FROM MOR DATA) PART C
INSERT INTO #HCCs_spr_HCC_Member_Count
SELECT DISTINCT @paymo,
                a.hicn,
                NULL,
                'Members in MOR/MORD',
				rp.PlanID
FROM   dbo.tbl_MOR_Rollup a
       LEFT OUTER JOIN #HCCs_spr_HCC_Member_Count b
         ON a.hicn = b.hicn
	   JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp 
	     ON rp.PlanIdentifier = a.PlanIdentifier
WHERE  a.PayMonth = @paymo
       AND b.hicn IS NULL 
	   AND @HCCFilter <> 'D'
	    AND 
	      EXISTS (SELECT 1 FROM #PlanID tp WHERE rp.PlanID = tp.Item)

-- ADD HICNS WITH NO HCCS (FROM MOR DATA) PART D
INSERT INTO #HCCs_spr_HCC_Member_Count
SELECT DISTINCT @paymo,
                a.hicn,
                NULL,
                'Members in MOR/MORD',
				rp.PlanID
FROM   dbo.tbl_MORD_Rollup a
       LEFT OUTER JOIN #HCCs_spr_HCC_Member_Count b
           ON a.hicn = b.hicn
		JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp 
		   ON rp.PlanIdentifier = a.PlanIdentifier
WHERE  a.Paymo = @paymo
       AND b.hicn IS NULL 
	   AND @HCCFilter <> 'C'
	    AND 
	      EXISTS (SELECT 1 FROM #PlanID tp WHERE rp.PlanID = tp.Item)

-- Add hicns with no HCCs (from MMR data)
INSERT INTO #HCCs_spr_HCC_Member_Count
SELECT DISTINCT @paymo,
                a.hicn,
                NULL,
                'Members NOT in MOR/MORD',
				rp.PlanID
FROM   dbo.tbl_Member_Months_rollup a
       LEFT OUTER JOIN #HCCs_spr_HCC_Member_Count b
         ON a.hicn = b.hicn
	   JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp ON rp.PlanIdentifier = a.PlanIdentifier
WHERE  ( CASE
           WHEN MONTH(a.paymstart) < 10 THEN ( CAST(YEAR(a.paymstart) AS VARCHAR(4)) + '0' + CAST(MONTH(a.paymstart) AS VARCHAR(2)) )
           ELSE ( CAST(YEAR(a.paymstart) AS VARCHAR(4)) + '' + CAST(MONTH(a.paymstart) AS VARCHAR(2)) )
         END ) = @paymo
       AND b.hicn IS NULL
	    AND 
	      EXISTS (SELECT 1 FROM #PlanID tp WHERE rp.PlanID = tp.Item)


--Count of HCCs, Grouped by hicn

INSERT INTO #Count_HCCs_spr_HCC_Member_Count
SELECT PayMonth   AS Payment_Month,
       HICN,
       COUNT(HCC) AS HCC_Count,
       Note,
	   PlanID
FROM   #HCCs_spr_HCC_Member_Count
GROUP  BY PayMonth,
          HICN,
          Note,
		  PlanID
ORDER  BY COUNT(HCC) 

-- Report Data set
INSERT INTO   #HCC_Report_spr_HCC_Member_Count
SELECT PayMonth,
       HCC_Count,
       COUNT(HICN)       AS Member_Count,
       CAST(NULL AS INT) AS Total,
       Note,
	   PlanID

FROM   #Count_HCCs_spr_HCC_Member_Count
GROUP  BY PayMonth,
          HCC_Count,
          Note,
		  PlanID
ORDER  BY HCC_Count 

UPDATE #HCC_Report_spr_HCC_Member_Count
SET    Total = (SELECT SUM(Member_Count)
                FROM   #HCC_Report_spr_HCC_Member_Count) 
                
--Final output
SELECT PayMonth                                                                                          AS 'Payment Month',
	   CASE 
	    WHEN @HCCFilter = 'C' THEN 'Part C'
	    WHEN @HCCFilter = 'D' THEN 'Part D'
	    ELSE 'Part C & D' END																				  AS 'HCC Type',
       HCC_Count                                                                                              AS 'HCC Count',
       Member_Count                                                                                           AS 'Members',
       CAST(SUM(CAST(Member_Count AS DECIMAL(19, 4))) / SUM(CAST(Total AS DECIMAL(19, 4))) AS DECIMAL(19, 5)) AS '% of Membership',
       Note                                                                                           AS 'Comments',
	   PlanID
FROM   #HCC_Report_spr_HCC_Member_Count
GROUP  BY PayMonth,
          HCC_Count,
          Member_Count,
          Note,
		  PlanID
ORDER  BY PayMonth asc,
          HCC_Count asc,
  		  Comments desc, 
		  PlanID


END