CREATE  PROCEDURE [rev].[EstRecevMORCalcPartD]
    (
      @Payment_Year VARCHAR(4),
	  @RowCount INT OUT
    )
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.[EstRecevMORCalcPartD].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017										*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates MOR factors into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
74294       12/3/2018         Madhuri Suri       Part D Defects Correction 
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/   
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    --DECLARE @Payment_Year VARCHAR(4)= 2017
    ----Exec rev.[EstRecevMORCalcPartD] 2017
        DECLARE @PaymentYear VARCHAR(4) = @Payment_Year 
        
 
	/**********************************************************************
DECLARE PAYMONTH FOR MOR DATA DYNAMICALLY COME FROM LK_DCP_DATES:
***********************************************************************/
        DECLARE @PAYMO INT = ( SELECT DISTINCT
                                        Paymonth
                               FROM     [$(HRPReporting)].dbo.lk_dcp_dates
                               WHERE    LEFT(paymonth, 4) = @PaymentYear
                                        AND mid_year_update = 'Y'
                             )

        DECLARE @populate_date DATETIME = GETDATE()   
    
    
/**MOR DATA IS CONSIDERED ONLY WHEN THE PAYMONTH IS GREATER THAN OR EQUAL TO @PAYMENT_YEAR_ '07'**/
 
  
        IF ( SELECT MAX(a.Payment_Month)
             FROM   dbo.Converted_MORD_Data_rollup a
             WHERE  LEFT(a.Payment_Month, 4) = @PaymentYear
           ) >= @PAYMO
            BEGIN 
        
        
                INSERT  INTO [etl].[RiskScoreFactorsPartD]
                        ( [PaymentYear] ,
                          [MYUFlag] ,
                          [PlanIdentifier] ,
                          [HICN] ,
                          [AgeGrpID] ,
                          [HCCLabel] ,
                          [Factor] ,
                          [HCCHierarchy] ,
                          [FactorHierarchy] ,
                          [HCCDeleteHierarchy] ,
                          [FactorDeleteHierarchy] ,
                          [PartDRAFTProjected] ,
                          [PartDRAFTMMR] ,
                          [ModelYear] ,
                          [DeleteFlag] ,
                          [DateForFactors] ,
                          [HCCNumber] ,
                          [Aged] ,
                          [SourceType] ,
                          [PartitionKey] ,
                          [LoadDate] ,
                          [UserID]
                        )
                        SELECT DISTINCT
                                d.PaymentYear ,
                                d.MYUFlag ,
                                d.PlanIdentifier ,
                                d.HICN ,
                                ag.AgeGroupID ,
                                a.RxHCCLabel HCCLabel ,
                                a.Factor ,
                                A.RxHCCLabel AS HCC_Hierarchy ,
                                a.Factor AS Factor_hierarchy ,
                                A.RxHCCLabel AS HCC_Delete_Hierarchy , -- 11162018
                                a.Factor AS Factor_Delete_hierarchy ,
                                a.PartDRAFT ,
                                a.PartDRAFTMMR ,
                                a.ModelYear ,
                                '0' AS Delete_flag ,
                                D.DateForFactors ,
                                A.RxHCCNumber ,
                                d.Aged ,
                                'MOR' AS Factortype ,
                                pk.EstRecvPartitionKeyID ,
                                @populate_date ,
                                USER_ID()
                        FROM    rev.SummaryPartDRskAdjMORD a
                                JOIN etl.EstRecvDemoCalcPartD dc ON dc.hicn = a.HICN
                                                              AND dc.MaxMOR = LEFT(CONVERT(VARCHAR(11), a.PaymStart, 112),
                                                              6)
                                JOIN etl.EstRecvDemographicsPartD d ON d.hicn = a.hicn
                                                              AND d.PartDRAFTProjected = a.PartDRAFT
                                                              AND d.PartDRAFTProjected = a.PartDRAFTMMR
                                                              AND a.Aged = d.Aged
                                                              AND MonthRow = 1
                                                              AND a.PlanIdentifier = d.PlanIdentifier
                                LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.RskAdjAgeGrp = ag.Description
                                LEFT JOIN etl.EstRecvPartitionKey pk ON pk.MYU = d.MYUFlag
                                                              AND pk.PaymentYear = d.PaymentYear
                                                              AND pk.SourceType = 'RAPS'
                        WHERE   a.PaymentYear = @Payment_Year
                                AND LEFT(CONVERT(VARCHAR(11), a.PaymStart, 112),
                                         6) >= @PAYMO
                                AND a.RxHCCLabel LIKE 'HCC%'
                                AND NOT EXISTS ( SELECT 1
                                                 FROM   etl.[RiskScoreFactorsPartD] RAPS
                                                 WHERE  RAPS.HICN = A.HICN
                                                        AND A.ModelYear = RAPS.ModelYear
                                                        AND a.PaymentYear = raps.PaymentYear
                                                        AND A.PartDRAFT = RAPS.PartDRAFTProjected
                                                        AND a.RxHCCNumber = raps.HCCNumber
                                                        AND a.Aged = raps.Aged
                                                        AND a.PlanIdentifier = raps.PlanIdentifier )
            END 

SET @RowCount = @@ROWCOUNT;

    END