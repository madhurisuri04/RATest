CREATE PROCEDURE [rev].[EstRecevMemberDetail]
    (
      @Payment_Year VARCHAR(4) ,
      @MYU VARCHAR(1),
	  @RowCount INT OUT
    )
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	[rev].[EstRecevMemberDetail]    			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	03/03/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Demographics into etl table	*

***************************************************************************/   
/********************************************************************************************
TICKET					 DATE              NAME                DESCRIPTION
65493			        6/26              Madhuri Suri        Risk Score Matches to ER1
65862					8/7/2017          Madhuri Suri        ER 1 to ER2 Logic changes
RRI-34/79581			09/15/20          Anand               Add Row Count Output Parameter
***********************************************************************************************/   
--TESTING 
--
--EXEC [rev].[EstRecevMemberDetail] 2016, 'N'
    --DECLARE @Payment_Year VARCHAR(4) = '2016'
    --DECLARE @MYU CHAR(1) = 'N'

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

        IF OBJECT_ID('Tempdb..#MID_YEAR_UPDATE_FLAG') > 0
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
                        PAYMSTART ,--6/19
                        SUM(TOTAL_MA_PAYMENT_AMOUNT) AS MID_YEAR_UPDATE_ACTUAL
                FROM    dbo.tbl_MMR_rollup
                WHERE   ( ADJREASON = 41
                          OR ADJREASON = 26
                        )
                        AND TOTAL_MA_PAYMENT_AMOUNT <> 0
                        AND YEAR(PaymStart) = @PY
                GROUP BY Total_MA_Payment_Amount ,
                        HICN ,
                        PaymStart


  
        TRUNCATE TABLE [etl].[EstRecvDemographics]
        INSERT  INTO [etl].[EstRecvDemographics]
                ( [PlanID] ,
                  [HICN] ,
                  [PaymentYear] ,
                  [MYUFlag] ,
                  [PaymStart] ,
                  [MonthRow] ,
                  [Gender] ,
                  [RskAdjAgeGrp] ,
                  [AgeGrpID] ,
                  [PartCRAFTProjected] ,
                  [PartCRAFTMMR] ,
                  [PartCDefaultIndicator] ,
                  [ORECRestated] ,
                  [MedicaidRestated] ,
                  [PartCRiskScoreMMR] ,
                  [SCC] ,
                  [OOA] ,
                  [PBP] ,
                  [MABID] ,
                  [HOSP] ,
                  [MonthsInLaggedDCP] ,
                  [MonthsInDCP] ,
                  [TotalPayment] ,
                  [TotalMAPaymentAmount] ,
                  [ESRD] ,
                  [MARiskRevenue_A_B] ,
                  [TotalPremiumYTD] ,
                  [MidYearUpdateFlag] ,
                  [MidYearUpdateActual] ,
                  [MedicaidDualStatusCode] ,
                  [Aged] ,
                  [BeneficiaryCurrentMedicaidStatus] ,
                  [SourceType] ,
                  [PartitionKey] ,
                  [Populated]

                )
                SELECT  [PlanID] ,
                        a.HICN ,
                        a.[PaymentYear] ,
                        @MYUFlag ,
                        a.[PaymStart] ,
                        RANK() OVER ( PARTITION BY a.HICN, PLANID,
                                      PartCRAFTProjected ORDER BY a.PaymStart DESC ) AS MonthRow ,
                        [Gender] ,
                        [RskAdjAgeGrp] ,
                        ag.AgeGroupID ,
                        [PartCRAFTProjected] ,
                        [PartCRAFTMMR] ,
                        [PartCDefaultIndicator] ,
                        ORECRestated , -- Changed on 6/5/2017 MS
                        ISNULL(CAST (a.MedicaidRestated AS VARCHAR(4)), '9999') , --6/6
                        [PartCRiskScoreMMR] ,
                        [SCC] ,
                        [OOA] ,
                        [PBP] ,
                        [MABID] ,
                        [HOSP] ,
                        [MonthsInLaggedDCP] ,
                        [MonthsInDCP] ,
                        [TotalPayment] ,
                        [TotalMAPaymentAmount] ,
                        [ESRD] ,
                        SUM(RISKPYMTA) + SUM(RISKPYMTB) AS MARISKREVENUE_A_B ,
                        SUM(TOTALMAPAYMENTAMOUNT) AS TotalPremiumYTD ,
                        CASE WHEN myu.HICN IS NOT NULL THEN 'Y'
                             ELSE ''
                        END MID_YEAR_UPDATE_FLAG ,
                        myu.MID_YEAR_UPDATE_ACTUAL ,
                        [MedicaidDualStatusCode] ,
                        [Aged] ,
                        [BeneficiaryCurrentMedicaidStatus] ,
                        b.SourceType ,
                        b.EstRecvPartitionKeyID ,
                        @populate_date
                FROM    rev.[tbl_Summary_RskAdj_MMR] a
                        LEFT JOIN #MID_YEAR_UPDATE_FLAG MYU ON myu.HICN = a.HICN
                                                              AND Myu.PaymStart = A.PaymStart --6/19
                        JOIN [etl].[EstRecvPartitionKey] b ON a.PaymentYear = b.PaymentYear
                                                              AND b.MYU = @MYUFlag
                                                              AND b.SourceType = 'MMR'
                        LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON ag.Description = a.RskAdjAgeGrp
                WHERE   a.PaymentYear = @PY
                GROUP BY [PlanID] ,
                        a.hicn ,
                        a.PaymentYear ,
                        myu.myu ,
                        a.PaymStart ,
                        [Gender] ,
                        [RskAdjAgeGrp] ,
                        [PartCRAFTProjected] ,
                        [PartCRAFTMMR] ,
                        [PartCDefaultIndicator] ,
                        [ORECRestated] ,
                        [MedicaidRestated] ,
                        [PartCRiskScoreMMR] ,
                        [SCC] ,
                        [OOA] ,
                        [PBP] ,
                        [MABID] ,
                        [HOSP] ,
                        [MonthsInLaggedDCP] ,
                        [MonthsInDCP] ,
                        [TotalPayment] ,
                        [TotalMAPaymentAmount] ,
                        [ESRD] ,
                        RISKPYMTA ,
                        RISKPYMTB ,
                        TOTALMAPAYMENTAMOUNT ,
                        [MedicaidDualStatusCode] ,
                        [Aged] ,
                        [BeneficiaryCurrentMedicaidStatus] ,
                        b.EstRecvPartitionKeyID ,
                        b.SourceType ,
                        myu.HICN ,
                        myu.MID_YEAR_UPDATE_ACTUAL ,
                        ag.AgeGroupID
                              
SET @RowCount = Isnull(@@ROWCOUNT,0);
/**************************
--#DATE_FOR_FACTORS :
***************************/

 
        UPDATE  a
        SET     DateForFactors = b.PaymStart
        FROM    [etl].[EstRecvDemographics] a
                LEFT JOIN [etl].[EstRecvDemographics] b ON a.HICN = b.HICN
                                                           AND a.PlanID = b.PlanID
                                                           AND a.PartCRAFTProjected = b.PartCRAFTProjected
                                                           AND b.Monthrow = 1  
        UPDATE  a
        SET     MedicaidRestated = b.MedicaidRestated --65862 
        FROM    [etl].[EstRecvDemographics] a
                LEFT JOIN [etl].[EstRecvDemographics] b ON a.HICN = b.HICN
                                                           AND a.PlanID = b.PlanID
                                                           AND b.Monthrow = 1                                             
                                                           
                                                           
        UPDATE  a
        SET     MABID = MA_BID
        FROM    [etl].[EstRecvDemographics] a
                CROSS APPLY ( SELECT    MA_BID
                              FROM      dbo.tbl_BIDS_rollup b
                              WHERE     Bid_Year = @Payment_Year
                                        AND a.PBP = b.PBP
                                        AND a.SCC = b.SCC
                                        AND a.PlanID = b.PlanIdentifier
                            ) z   --6/15
                                               
   

        UPDATE  a
        SET     MABID = MA_BID
        FROM    [etl].[EstRecvDemographics] a
                CROSS APPLY ( SELECT    MA_BID
                              FROM      dbo.tbl_BIDS_rollup a
                              WHERE     Bid_Year = @Payment_Year
                                        AND a.PBP = a.PBP
                                        AND 'OOA' = a.SCC
                            ) z
        WHERE   a.MABID IS NULL  

        UPDATE  EstRecDet
        SET     MABID = ESRD.Rate
        FROM    [etl].[EstRecvDemographics] EstRecDet
                INNER JOIN [$(HRPReporting)].dbo.lk_Ratebook_ESRD ESRD ON EstRecDet.SCC = ESRD.Code
        WHERE   ESRD.PayMo = @Payment_Year
                AND EstRecDet.PartCRAFTProjected IN ( 'D', 'ED' )                                                             
   
   
   

/**************************
MAX MOR FROM MOR_ROLLUP :
***************************/


        IF OBJECT_ID('Tempdb..#MAX_MOR') > 0
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
                        MAX(b.PayMonth) MAX_MOR ,
                        MidYearUpdateFlag ,
                        PlanID ,
                        PartCRAFTProjected
                FROM    etl.EstRecvDemographics a
                        LEFT  JOIN dbo.tbl_MOR_Rollup b ON b.HICN = a.HICN -- MS TEST
                                                           AND a.PaymentYear = LEFT(b.PayMonth,
                                                              4)
                                                           AND a.PlanID = b.PlanIdentifier -- MS TEST
                WHERE   B.PayMonth >= @PAYMO
                        AND a.MidYearUpdateFlag = 'Y'
                        AND a.MonthRow = 1
                GROUP BY a.HICN ,
                        MidYearUpdateFlag ,
                        a.PlanID ,
                        a.PartCRAFTProjected
                UNION
                SELECT DISTINCT
                        A.Hicn ,
                        MAX(b.PayMonth) MAX_MOR ,
                        MidYearUpdateFlag ,
                        PlanID ,
                        a.PartCRAFTProjected
                FROM    etl.EstRecvDemographics a
                        LEFT  JOIN dbo.tbl_MOR_Rollup b ON b.HICN = a.HICN --MS TEST
                                                           AND a.PaymentYear = LEFT(b.PayMonth,
                                                              4)
                                                           AND a.PlanID = b.PlanIdentifier -- MS Test 
                WHERE   b.PayMonth LIKE @PY + '%'
                        AND ISNULL(a.MidYearUpdateFlag, 'N') <> 'Y'
                        AND a.MonthRow = 1
                GROUP BY a.HICN ,
                        MidYearUpdateFlag ,
                        PlanID ,
                        PartCRAFTProjected
                        
                        
                        
        TRUNCATE TABLE etl.EstRecvDemoCalc
        INSERT  INTO etl.EstRecvDemoCalc
                ( [PlanID] ,
                  [HICN] ,
                  [PaymentYear] ,
                  [MYUFlag] ,
                  [PaymStart] ,
                  [DateForFactors] ,
                  [RskAdjAgeGrp] ,
                  [Gender] ,
                  [MABID] ,
                  [SCC] ,
                  [PartCRAFTProjected] ,
                  [PartCRAFTMMR] ,
                  [MaxMOR] ,
                  [MARiskRevenueRecalc] ,
                  [MARiskRevenueVariance] ,
                  [RiskScoreMMR] ,
                  [NewEnrolleeFlagError] ,
                  [ActualFinalPaid] ,
                  [AgedStatus] ,
                  [SourceType] ,
                  [PartitionKey] ,
                  [Populated]
                )
                SELECT  a.PlanID ,
                        a.HICN ,
                        a.PaymentYear ,
                        a.MYUFlag ,
                        a.PaymStart ,
                        a.DateForFactors ,
                        a.RskAdjAgeGrp ,
                        a.Gender ,
                        a.MABID ,
                        A.SCC ,
                        a.PartCRAFTProjected ,
                        a.PartCRAFTMMR ,
                        mor.MAX_MOR ,
                        CASE WHEN a.PartCRAFTProjected <> 'HP'
                             THEN ( A.PartCRiskScoreMMR * MABID )
                             ELSE '0.00'
                        END AS [MARiskRevenueRecalc] ,
                        '0.00' AS [MARiskRevenueVariance] ,
                        a.PartCRiskScoreMMR ,
                        CASE WHEN a.PARTCRAFTProjected = 'C'
                                  AND a.PartCRAFTMMR = 'E' THEN 'Y'
                        END NewEnrolleeErrorFlag ,
                        '0.00' AS [ActualFinalPaid] ,
                        CASE WHEN a.Aged = 1 THEN 'Aged'
                             WHEN Aged = 0 THEN 'Disabled'
                             ELSE 'NA'
                        END AS Agedstatus ,
                        a.SourceType ,
                        a.PartitionKey ,
                        GETDATE()
                FROM    etl.EstRecvDemographics a
                        LEFT JOIN #MAX_MOR MOR ON mor.HICN = a.HICN
                                                  AND mor.PlanID = a.PlanID
                                                  AND a.PartCRAFTProjected = mor.RAFT
                                                  --AND a.MidYearUpdateFlag = mor.MidYearUpdateFlag --6/5 MS

SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);

        UPDATE  etl.EstRecvDemoCalc
        SET     [MARiskRevenueVariance] = ( a.MARiskRevenue_A_B
                                            - b.MARiskRevenueRecalc )
        FROM    etl.EstRecvDemographics a
                JOIN etl.EstRecvDemoCalc b ON b.HICN = a.HICN
                                              AND a.PaymStart = b.PaymStart
                                              AND a.PartCRAFTProjected = b.PartCRAFTProjected
        WHERE   a.PartCRAFTProjected <> 'HP'

   
   
   
    END