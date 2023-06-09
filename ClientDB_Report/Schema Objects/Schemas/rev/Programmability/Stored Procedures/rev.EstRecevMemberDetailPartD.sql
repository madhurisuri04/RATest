CREATE PROCEDURE [rev].[EstRecevMemberDetailPartD]
    (
      @Payment_Year VARCHAR(4) ,
      @MYU VARCHAR(1),
	  @RowCount INT OUT
    )
AS
BEGIN
    SET NOCOUNT ON

/************************************************************************        
* Name			:	[rev].[EstRecevMemberDetailPartD]    			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	11/20/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Demographics into etl table for Part D from Summary MMR PartD 	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
74294        12/3/2018       Madhuri Suri         Part D Defect Correction
75091        3/4/2019        Madhuri Suri         Part D Corrections
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/   
--TESTING 
--EXEC [rev].[EstRecevMemberDetailPartD] 2017, 'N'
    --DECLARE @Payment_Year VARCHAR(4) = 2017
    --DECLARE @MYU VARCHAR(1) = 'N'
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @populate_date SMALLDATETIME = GETDATE()
    DECLARE @Currentdate SMALLDATETIME = GETDATE()
    DECLARE @PY VARCHAR(4) = @Payment_Year ,
        @MYUFlag VARCHAR(1) = @MYU
    
   	/**********************************************************************
DECLARE PAYMONTH FOR MOR DATA DYNAMICALLY COME FROM LK_DCP_DATES:
***********************************************************************/
    DECLARE @PAYMO INT = ( SELECT DISTINCT
                                    Paymonth
                           FROM     [$(HRPReporting)].dbo.lk_dcp_dates
                           WHERE    LEFT(paymonth, 4) = @PY
                                    AND mid_year_update = 'Y'
                         )
/**********************************************************************
 MID_YEAR_UPDATE_FLAG AND TOTAL_MA_PAYMENT_AMOUNT FROM TBL_MMR_ROLLUP:
***********************************************************************/

    IF OBJECT_ID('Tempdb..#MID_YEAR_UPDATE_FLAG') IS NOT NULL
        DROP TABLE #MID_YEAR_UPDATE_FLAG

    CREATE TABLE #MID_YEAR_UPDATE_FLAG
        (
          ID INT IDENTITY(1, 1)
                 PRIMARY KEY
                 NOT NULL ,
          HICN NVARCHAR(24) ,
          MYU VARCHAR(1) ,
          PAYMSTART SMALLDATETIME ,
          MID_YEAR_UPDATE_ACTUAL SMALLMONEY
        )

    CREATE NONCLUSTERED INDEX MIDYEAR_IDX ON #MID_YEAR_UPDATE_FLAG (HICN) INCLUDE (Paymstart)

    INSERT  INTO #MID_YEAR_UPDATE_FLAG
            ( HICN ,
              MYU ,
              PAYMSTART ,
              MID_YEAR_UPDATE_ACTUAL
	        )
            SELECT  HICN ,
                    'Y' AS MYU ,
                    PAYMSTART ,
                    SUM(PART_D_DIRECT_SUBSIDY_PAYMENT_AMOUNT) AS MID_YEAR_UPDATE_ACTUAL
            FROM    dbo.tbl_MMR_rollup
            WHERE   ( ADJREASON = 41
                      OR ADJREASON = 26
                    )
                    AND Total_Part_D_Payment <> 0
                    AND YEAR(PaymStart) =  @PY
            GROUP BY Total_MA_Payment_Amount ,
                    HICN ,
                    PaymStart


   
    TRUNCATE TABLE [etl].[EstRecvDemographicsPartD]
    INSERT  INTO [etl].[EstRecvDemographicsPartD]
            ( [PlanIdentifier] ,
              [HPlanID] ,
              [HICN] ,
              [PaymentYear] ,
              [MYUFlag] ,
              [PaymStart] ,
              [MonthRow] ,
              [Gender] ,
              [RskAdjAgeGrp] ,
              [AgeGrpID] ,
              [PartDRAFTProjected] ,
              [PartDRAFTMMR] ,
              [ORECRestated] ,
              [MedicaidRestated] ,
              [PartDRiskScoreMMR] ,
              [SCC] ,
              [OOA] ,
              [PBP] ,
              [MABID] ,
              [HOSP] ,
              [MonthsInLaggedDCP] ,
              [MonthsInDCP] ,
              [TotalPayment] ,
              [TotalMAPaymentAmount] ,
              [TotalPremiumYTD] ,
              [MidYearUpdateFlag] ,
              [MidYearUpdateActual] ,
              [MedicaidDualStatusCode] ,
              [Aged] ,
              [BeneficiaryCurrentMedicaidStatus] ,
              [LowIncomeMultiplier] ,
              [PartDBasicPremiumAmount] ,
              [SourceType] ,
              [PartitionKey] ,
              [LoadDate] ,
              [UserID], 
			  [PartDLowIncomeIndicator] -- added new column for Part D low income 

            )
            SELECT  a.PlanID ,
                    rp.PlanID ,
                    a.HICN ,
                    a.[PaymentYear] ,
                    @MYUFlag ,
                    a.[PaymStart] ,
                    RANK() OVER ( PARTITION BY a.HICN, a.PlanID,
                                  a.PartDRAFTProjected ORDER BY a.PaymStart DESC ) AS MonthRow ,
                    [Gender] ,
                    [RskAdjAgeGrp] ,
                    ag.AgeGroupID ,
                    [PartDRAFTProjected] ,
                    [PartDRAFTProjected] ,
                    ORECRestated ,
                    ISNULL(CAST (a.MedicaidRestated AS VARCHAR(4)), '9999') ,
                    [PartDRAFactor] ,--RiskScore PartD
                    SCC ,
                    [OOA] ,
                    [PBP] ,
                    NULL ,
                    [HOSP] ,
                    [MonthsInLaggedDCP] ,
                    [MonthsInDCP] ,
                    TotalPartDPayment ,
                    [TotalMAPaymentAmount] ,
                    SUM(a.PartDDirectSubsidyPaymentAmount) AS TotalPremiumYTD ,
                    CASE WHEN myu.HICN IS NOT NULL THEN 'Y'
                         ELSE ''
                    END MID_YEAR_UPDATE_FLAG ,
                    myu.MID_YEAR_UPDATE_ACTUAL ,
                    [MedicaidDualStatusCode] ,
                    PartDAged ,
                    [BeneficiaryCurrentMedicaidStatus] ,
                    a.LowIncomePremiumSubsidy , 
                    a.PartDBasicPremiumAmount ,
                    b.SourceType ,
                    b.EstRecvPartitionKeyID ,
                    @populate_date ,
                    USER_ID(), 
					[PartDLowIncomeIndicator]
            FROM    rev.[tbl_Summary_RskAdj_MMR] a
                    LEFT JOIN #MID_YEAR_UPDATE_FLAG MYU ON myu.HICN = a.HICN
                                                           AND Myu.PaymStart = A.PaymStart --6/19
                    JOIN [etl].[EstRecvPartitionKey] b ON a.PaymentYear = b.PaymentYear
                                                          AND b.MYU = @MYUFlag
                                                          AND b.SourceType = 'MMR'
                    LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON ag.Description = a.RskAdjAgeGrp
                    LEFT JOIN [$(HRPInternalReportsDB)].dbo.rollupPlan rp ON rp.planidentifier = a.planID
            WHERE   a.PaymentYear = @PY and a.TotalPartDPayment <> 0
            GROUP BY a.PlanID ,
                    rp.PlanID ,
                    a.hicn ,
                    a.PaymentYear ,
                    myu.myu ,
                    a.PaymStart ,
                    [Gender] ,
                    [RskAdjAgeGrp] ,
                    [PartDRAFTProjected] ,
                    [PartDRAFTMMR] ,
                    [ORECRestated] ,
                    [MedicaidRestated] ,
                    PartDRAFactor ,
                    [SCC] ,
                    [OOA] ,
                    [PBP] ,
                    [MABID] ,
                    [HOSP] ,
                    [MonthsInLaggedDCP] ,
                    [MonthsInDCP] ,
                    TotalPartDPayment ,
                    PartDDirectSubsidyPaymentAmount ,
                    [MedicaidDualStatusCode] ,
                    PartDaged ,
                    [BeneficiaryCurrentMedicaidStatus] ,
                    b.EstRecvPartitionKeyID ,
                    a.LowIncomePremiumSubsidy ,
                    a.PartDBasicPremiumAmount ,
                    b.SourceType ,
                    myu.HICN ,
                    myu.MID_YEAR_UPDATE_ACTUAL ,
                    ag.AgeGroupID,
					TotalMAPaymentAmount, 
					a.PartDLowIncomeIndicator
                              
SET @RowCount = Isnull(@@ROWCOUNT,0);                  
   
/**************************
--#DATE_FOR_FACTORS :
***************************/

 
    UPDATE  a
    SET     DateForFactors = b.PaymStart
    FROM    [etl].[EstRecvDemographicsPartD] a
            LEFT JOIN [etl].[EstRecvDemographicsPartD] b ON a.HICN = b.HICN
                                                       AND a.PlanIdentifier = b.PlanIdentifier
                                                       AND a.PartDRAFTProjected = b.PartDRAFTProjected
                                                       AND b.Monthrow = 1  
    UPDATE  a
    SET     MedicaidRestated = b.MedicaidRestated 
    FROM    [etl].[EstRecvDemographicsPartD] a
            LEFT JOIN [etl].[EstRecvDemographicsPartD] b ON a.HICN = b.HICN
                                                       AND a.PlanIdentifier = b.PlanIdentifier
                                                       AND b.Monthrow = 1                                             
                                                           
                                                           
    --UPDATE  a
    --SET     MABID = PartD_BID
    --FROM    [etl].[EstRecvDemographicsPartD] a
    --        CROSS APPLY ( SELECT    b.PartD_BID
    --                      FROM      dbo.tbl_BIDS_rollup b
    --                      WHERE     Bid_Year = @Payment_Year
    --                                AND a.PBP = b.PBP
    --                                AND a.SCC = b.SCC
    --                                AND a.PlanIdentifier = b.PlanIdentifier
    --                    ) z   
                                               
   

    --UPDATE  a
    --SET     MABID = PartD_BID
    --FROM    [etl].[EstRecvDemographicsPartD] a
    --        CROSS APPLY ( SELECT    PartD_BID
    --                      FROM      dbo.tbl_BIDS_rollup a
    --                      WHERE     Bid_Year = @Payment_Year
    --                                AND a.PBP = a.PBP
    --                                AND 'OOA' = a.SCC
    --                    ) z
    --WHERE   a.MABID IS NULL  
                                           

/**************************
MAX MOR FROM MOR_ROLLUP :
***************************/


    IF OBJECT_ID('Tempdb..#MAX_MOR') IS NOT NULL 
        DROP TABLE #MAX_MOR

    CREATE TABLE #MAX_MOR
        (
          ID INT IDENTITY(1, 1)
                 PRIMARY KEY
                 NOT NULL ,
          HICN VARCHAR(20) ,
          MAX_MOR VARCHAR(10) ,
          MidYearUpdateFlag VARCHAR(1) ,
          PlanID INT ,
          RAFT VARCHAR(4)
        )	
    CREATE NONCLUSTERED INDEX MAX_MOR_IDX ON #MAX_MOR (HICN) INCLUDE (MAX_MOR)
 

    INSERT  INTO #MAX_MOR
            ( HICN ,
              MAX_MOR ,
              MidYearUpdateFlag ,
              PlanID ,
              RAFT
            )
            SELECT DISTINCT
                    A.Hicn ,
                    MAX(b.PayMo) MAX_MOR ,
                    MidYearUpdateFlag ,
                    a.PlanIdentifier ,
                    PartDRAFTProjected
            FROM    etl.EstRecvDemographicsPartD a
                    LEFT  JOIN dbo.tbl_MORD_Rollup b ON b.HICN = a.HICN 
                                                       AND a.PaymentYear = LEFT(b.PayMo,
                                                              4)
                                                       AND a.PlanIdentifier = b.PlanIdentifier 
            WHERE   B.PayMo >= @PAYMO
                    AND a.MidYearUpdateFlag = 'Y'
                    AND a.MonthRow = 1
            GROUP BY a.HICN ,
                    MidYearUpdateFlag ,
                    a.PlanIdentifier ,
                    a.PartDRAFTProjected
            UNION
            SELECT DISTINCT
                    A.Hicn ,
                    MAX(b.PayMo) MAX_MOR ,
                    MidYearUpdateFlag ,
                    a.PlanIdentifier ,
                    a.PartDRAFTProjected
            FROM    etl.EstRecvDemographicsPartD a
                    LEFT  JOIN dbo.tbl_MORD_Rollup b ON b.HICN = a.HICN 
                                                       AND a.PaymentYear = LEFT(b.PayMo,
                                                              4)
                                                       AND a.PlanIdentifier = b.PlanIdentifier 
            WHERE   b.PayMo LIKE @PY + '%'
                    AND ISNULL(a.MidYearUpdateFlag, 'N') <> 'Y'
                    AND a.MonthRow = 1
            GROUP BY a.HICN ,
                    MidYearUpdateFlag ,
                    a.PlanIdentifier ,
                    PartDRAFTProjected
                        
                                   
    TRUNCATE TABLE etl.EstRecvDemoCalcPartD
    INSERT  INTO etl.EstRecvDemoCalcPartD
            ( [PlanID]
			  ,[HICN]
			  ,[PaymentYear]
			  ,[MYUFlag]
			  ,[PaymStart]
			  ,[DateForFactors]
			  ,[RskAdjAgeGrp]
			  ,[Gender]
			  ,[MABID]
			  ,[SCC]
			  ,[PartDRAFTProjected]
			  ,[PartDRAFTMMR]
			  ,[MaxMOR]
			  ,[MARiskRevenueRecalc]
			  ,[MARiskRevenueVariance]
			  ,[RiskScoreMMR]
			  ,[NewEnrolleeFlagError]
			  ,[ActualFinalPaid]
			  ,[AgedStatus]
			  ,[SourceType]
			  ,[PartitionKey]
			  ,[LoadDate]
			  ,[UserID]
            )
            SELECT  a.PlanIdentifier ,
                    a.HICN ,
                    a.PaymentYear ,
                    a.MYUFlag ,
                    a.PaymStart ,
                    a.DateForFactors ,
                    a.RskAdjAgeGrp ,
                    a.Gender ,
                    a.MABID ,
                    A.SCC ,
                    a.PartDRAFTProjected ,
                    a.PartDRAFTProjected ,
                    mor.MAX_MOR ,
                    CASE WHEN a.PartDRAFTProjected <> 'HP'
                         THEN ( A.PartDRiskScoreMMR * MABID )
                         ELSE '0.00'
                    END AS [MARiskRevenueRecalc] ,
                    '0.00' AS [MARiskRevenueVariance] ,
                    a.PartDRiskScoreMMR ,
                    NULL AS NewEnrolleeErrorFlag ,
                    '0.00' AS [ActualFinalPaid] ,
                    CASE WHEN a.Aged = 1 THEN 'Aged'
                         WHEN Aged = 0 THEN 'Disabled'
                         ELSE 'NA'
                    END AS Agedstatus ,
                    a.SourceType ,
                    a.PartitionKey ,
                    GETDATE(),
                    USER_ID()
            FROM    etl.EstRecvDemographicsPartD a
                    LEFT JOIN #MAX_MOR MOR ON mor.HICN = a.HICN
                                              AND mor.PlanID = a.PlanIdentifier
                                              AND a.PartDRAFTProjected = mor.RAFT

SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);                  

 --FIND MEMBERS THAT WERE FLAGGED IN ERROR AS "NEW ENROLLEES"    
    IF OBJECT_ID('[tempdb].[dbo].[#TEMP1_NewEnrol]', 'U') IS NOT NULL 
    DROP TABLE #TEMP1_NewEnrol   
    CREATE TABLE #TEMP1_NewEnrol  
     ( HICN VARCHAR (15),    
       RISK_SCORE FLOAT)    
    
    CREATE CLUSTERED INDEX TEMP1_PartDTempERD ON #TEMP1_NewEnrol  (HICN)    
       
    
    
    -- INSERT STATEMENT TO ACCOUNT FOR NEW PART D RA FACTOR AND FACTOR TYPES BEGINNING IN PY 2011    
    INSERT INTO #TEMP1_NewEnrol   
    SELECT DISTINCT HICN, 
                    PartDRiskScoreMMR 
    FROM etl.EstRecvDemographicsPartD WHERE     
       PAYMSTART =cast('01-01-'+@Payment_Year AS DATETIME) 
       AND PartDRAFTProjected in ('D4','D5','D6','D7','D8','D9') 
       AND @Payment_Year >= 2011     
    
       
    IF OBJECT_ID('[tempdb].[dbo].[#TEMP2_spr_PartD_Estimated_Receivable_Detail]', 'U') 
    IS NOT NULL DROP TABLE #TEMP2_spr_PartD_Estimated_Receivable_Detail    
    CREATE TABLE #TEMP2_spr_PartD_Estimated_Receivable_Detail    
     ( HICN VARCHAR (15),    
       RISK_SCORE FLOAT)    
    
    CREATE CLUSTERED INDEX TEMP2_PartDTempERD ON #TEMP2_spr_PartD_Estimated_Receivable_Detail  (HICN)    
    
  
    --INSERT STATEMENT TO ACCOUNT FOR NEW PART D RA FACTOR AND FACTOR TYPES BEGINNING IN PY 2011    
    INSERT INTO #TEMP2_spr_PartD_Estimated_Receivable_Detail    
    SELECT distinct HICN, PartDRiskScoreMMR FROM 
       etl.EstRecvDemographicsPartD
     WHERE year(PAYMSTART) =@Payment_Year 
		 AND PartDRAFTProjected IN ('D1','D2') 
		 AND @Payment_Year >= 2011    
    
    IF OBJECT_ID('[tempdb].[dbo].[#TEMP3_spr_PartD_Estimated_Receivable_Detail]', 'U') IS NOT NULL 
    DROP TABLE #TEMP3_spr_PartD_Estimated_Receivable_Detail    
    CREATE TABLE #TEMP3_spr_PartD_Estimated_Receivable_Detail    
     ( HICN VARCHAR (15),    
       RISK_SCORE FLOAT)    
    
    CREATE CLUSTERED INDEX TEMP3_PartDTempERD ON #TEMP3_spr_PartD_Estimated_Receivable_Detail  (HICN)    
    
    INSERT INTO #TEMP3_spr_PartD_Estimated_Receivable_Detail    
    SELECT DISTINCT A.HICN, A.RISK_SCORE    
     FROM #TEMP1_NewEnrol A, #TEMP2_spr_PartD_Estimated_Receivable_Detail B    
     WHERE A.HICN=B.HICN AND A.RISK_SCORE=B.RISK_SCORE    
     GROUP BY A.HICN, A.RISK_SCORE  

	 UPDATE etl.EstRecvDemoCalcPartD 
	 SET NewEnrolleeFlagError ='Y' 
     WHERE HICN IN (
     SELECT HICN FROM #TEMP3_spr_PartD_Estimated_Receivable_Detail)     
    
   

   --UPDATE a    
   -- SET NEW_ENROLLEE_FLAG_ERROR='Y'     
   -- from #RESULTS_spr_PartD_Estimated_Receivable_Detail  a    
   -- cross apply    
   --  (select top 1 1 as DummyCol    
   --  from  #TEMP3_spr_PartD_Estimated_Receivable_Detail b     
   --  WHERE a.HICN = b.HICN) z
END