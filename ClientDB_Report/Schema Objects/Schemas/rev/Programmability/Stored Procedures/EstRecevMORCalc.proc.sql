CREATE PROCEDURE [rev].[EstRecevMORCalc]
    (
      @Payment_Year VARCHAR(4),
	  @RowCount INT OUT
    )
AS
BEGIN
    SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.[EstRecevMORCalc].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	04/10/2017										*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates MOR factors into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
64919        6/12/2017         Madhuri Suri  
65565        6/29              Madhuri Suri		   ER 2 to ER1 - Compare fixes
65862        8/7/2017          Madhuri Suri        ER 1 to ER2 Logic changes
67277        10/9/2017		   Madhuri Suri        MOR Paymonth Prod Issue
73560       11/5/2018          Madhuri Suri        Integrate EDS MOR into ER 
RRI-34/79581 09/15/20          Anand               Add Row Count Output Parameter
***********************************************************************************************/   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
   -- DECLARE @Payment_Year VARCHAR(4)= 2016 
    ----Exec rev.[EstRecevMORCalc] 2016
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
 
  
    IF ( SELECT MAX(PayMonth)
         FROM   dbo.Converted_MOR_Data_rollup
         WHERE  LEFT(PayMonth, 4) = @PaymentYear
       ) >= @PAYMO
        BEGIN 
        
        
                INSERT  INTO [etl].[RiskScoreFactorsPartC]
                        ( [PaymentYear] ,
                          [MYUFlag] ,
                          [PlanIdentifier] ,
                          [HICN] ,
                          [AgeGrpID] ,
                          [Populated] ,
                          [HCCLabel] ,
                          [Factor] ,
                          [HCCHierarchy] ,
                          [FactorHierarchy] ,
                          [HCCDeleteHierarchy] ,
                          [FactorDeleteHierarchy] ,
                          [PartCRAFTProjected] ,
                          [PartCRAFTMMR] ,
                          [ModelYear] ,
                          [DeleteFlag] ,
                          [DateForFactors] ,
                          [HCCNumber] ,
                          [Aged] ,
                          [SourceType] ,
                          [PartitionKey]
                        )
            SELECT DISTINCT
                    d.PaymentYear ,
                    d.MYUFlag ,
                    d.PlanID ,
                    d.HICN ,
                    ag.AgeGroupID ,
                    @populate_date ,
                    a.Factor_Description HCCLabel ,
                    a.Factor ,
                    A.Factor_Description AS HCC_Hierarchy ,
                    a.Factor AS Factor_hierarchy ,
                    A.Factor_Description AS HCC_Delete_Hierarchy ,
                    a.Factor AS Factor_Delete_hierarchy ,
                    a.RAFT ,
                    a.RAFT_ORIG ,
                    a.Model_Year ,
                    '0' AS Delete_flag ,
                    D.DateForFactors ,
                    A.HCC_Number ,
                    d.Aged ,
                    CASE WHEN a.SubmissionModel = 'EDS' THEN 'EMOR' 
					     WHEN a.SubmissionModel = 'RAPS' THEN 'RMOR' 
						 END AS Sourcetype ,
                    pk.EstRecvPartitionKeyID
            FROM    rev.tbl_Summary_RskAdj_MOR a /*MS test*/
                    JOIN etl.EstRecvDemoCalc dc ON dc.hicn = a.HICN
                                                              AND dc.MaxMOR = LEFT(CONVERT(VARCHAR(11), a.PaymStart, 112),
                                                              6)
                    JOIN etl.EstRecvDemographics d ON d.hicn = a.hicn
                                                      AND d.PartCRAFTProjected = a.RAFT
                                                      AND d.PartCRAFTMMR = a.RAFT_ORIG --Join RAFT to resolve MOR RAFT NULLS 06/05
                                                      AND a.Aged = d.Aged --6/6
                                                      AND MonthRow = 1
                                                      AND a.PlanID = d.PlanID
                    LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.RskAdjAgeGrp = ag.Description
                    LEFT JOIN etl.EstRecvPartitionKey pk ON pk.MYU = d.MYUFlag
                                                            AND pk.PaymentYear = d.PaymentYear
                                                            AND pk.SourceType = 'RAPS'
            WHERE   a.PaymentYear = @Payment_Year
                    AND LEFT(CONVERT(VARCHAR(11), a.PaymStart, 112), 6) >= @PAYMO
                    AND a.Factor_Description LIKE 'HCC%'
                                AND NOT EXISTS ( SELECT 1
                                                 FROM   etl.[RiskScoreFactorsPartC] RAPS
                                                 WHERE  RAPS.HICN = A.HICN
                                                        AND A.Model_Year = RAPS.ModelYear
                                                        AND a.PaymentYear = raps.PaymentYear
                                                        AND A.RAFT = RAPS.PartCRAFTProjected
                                                        AND a.HCC_Number = raps.HCCNumber 
                                                        AND a.Aged = raps.Aged --6/6
                                                        AND a.PlanID = raps.PlanIdentifier)--6/7

SET @RowCount = @@ROWCOUNT;

        END 
                       
END