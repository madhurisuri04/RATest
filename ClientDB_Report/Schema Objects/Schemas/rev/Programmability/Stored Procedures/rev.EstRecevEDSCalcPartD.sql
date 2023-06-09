CREATE PROCEDURE [rev].[EstRecevEDSCalcPartD]
    (
      @Payment_Year VARCHAR(4) ,
      @MYU VARCHAR(1),
	  @RowCount INT OUT
    )
AS /************************************************************************        
* Name			:	rev.EstRecevEDSCalcPartD.proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates EDS HCCs into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
71900       7/9/2018         Madhuri Suri         2019 changes - remove estrecvmodelsplits table reference
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/  
    BEGIN 
 --EXEC  rev.EstRecevEDSCalcPartD 2017, 'N'
 
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    --DECLARE @Payment_Year VARCHAR(4)= 2017 ,
    --    @MYU VARCHAR(1) = 'N'
        DECLARE @PaymentYear VARCHAR(4) = @Payment_Year ,
            @MYUFlag VARCHAR(1) = @MYU
 
 
  IF OBJECT_ID('TEMPDB.DBO.#EDSProcessedby', 'U') IS NOT NULL
            DROP TABLE #EDSProcessedby 
        CREATE TABLE #EDSProcessedby
            (
              [ID] [BIGINT] NOT NULL
                            IDENTITY(1, 1) ,
              [PaymentYear] INT NULL ,
              [MYU] [VARCHAR](2) NULL ,
              [ProcessedBy] [DATETIME] NULL ,
              [DCPFromDate] [DATETIME] NULL ,
              [DCPThrudate] [DATETIME] NULL
            )
        INSERT  INTO #EDSProcessedby
                ( [PaymentYear] ,
                  [MYU],
				  [ProcessedBy],
                  [DCPFromDate] ,
                  [DCPThrudate]
                )
                SELECT  Payment_Year ,
                        MYU ,
						[ProcessedBy],
                        DCPFromDate ,
                        DCPThrudate
                FROM    rev.EstRecevRefreshPY a
         
         
        DECLARE @DCP_FROMDATE DATETIME ,
            @DCP_THRUDATE DATETIME ,
            @PROCESSBY DATETIME                                  
        SELECT  @DCP_FROMDATE = [DCPFromDate] ,
                @DCP_Thrudate = [DCPThrudate] ,
                @PROCESSBY = [ProcessedBy]
        FROM    #EDSProcessedby a
        WHERE   a.PaymentYear = @PaymentYear
                AND a.MYU = @MYUFlag

        DECLARE @populate_date DATETIME = GETDATE()
    
    
    
        IF OBJECT_ID('TEMPDB.DBO.#lk_Risk_Models', 'U') IS NOT NULL
            DROP TABLE #lk_Risk_Models  

        CREATE TABLE #lk_Risk_Models
            (
              [lk_Risk_ModelsID] [INT] NOT NULL ,
              [Payment_Year] [INT] NULL ,
              [Factor_Type] [VARCHAR](10) NULL ,
              [Part_C_D_Flag] [VARCHAR](1) NULL ,
              [OREC] [INT] NULL ,
              [LI] [INT] NULL ,
              [Medicaid_Flag] [INT] NULL ,
              [Demo_Risk_Type] [VARCHAR](10) NULL ,
              [Factor_Description] [VARCHAR](50) NULL ,
              [Gender] [INT] NULL ,
              [Factor] [DECIMAL](20, 4) NULL ,
              [Factor_Description_Restated] [VARCHAR](50) NULL ,
              [Aged] [INT] NULL
            )

        INSERT  INTO #lk_Risk_Models
                ( [lk_Risk_ModelsID] ,
                  [Payment_Year] ,
                  [Factor_Type] ,
                  [Part_C_D_Flag] ,
                  [OREC] ,
                  [LI] ,
                  [Medicaid_Flag] ,
                  [Demo_Risk_Type] ,
                  [Factor_Description] ,
                  [Gender] ,
                  [Factor] ,
                  [Factor_Description_Restated] ,
                  [Aged]
                )
                SELECT  [lk_Risk_ModelsID] ,
                        [Payment_Year] ,
                        [Factor_Type] ,
                        [Part_C_D_Flag] ,
                        [OREC] ,
                        [LI] ,
                        [Medicaid_Flag] ,
                        [Demo_Risk_Type] ,
                        [Factor_Description] ,
                        [Gender] ,
                        [Factor] ,
                        CASE WHEN E.Factor_Description LIKE 'HCC00%'
                             THEN REPLACE(E.Factor_Description, 'HCC00',
                                          'HCC ')
                             WHEN E.Factor_Description LIKE 'HCC0%'
                             THEN REPLACE(E.Factor_Description, 'HCC0', 'HCC ')
                             WHEN E.Factor_Description LIKE 'HCC%'
                             THEN REPLACE(E.Factor_Description, 'HCC1',
                                          'HCC 1')
                             ELSE E.Factor_Description
                        END AS Factor_Description_Restated ,
                        ISNULL(Aged, '9999') Aged  /*59973*/
                FROM    [$(HRPReporting)].dbo.lk_Risk_Models E
                WHERE    E.PAYMENT_YEAR  = @PaymentYear   
                         AND E.Part_C_D_Flag = 'D' 
        CREATE NONCLUSTERED INDEX IX_lk_Risk_Models ON #lk_Risk_Models (Factor_Description,Factor_Description_Restated, FACTOR_TYPE) 
  
  
----/**EDS FACTOR VALUES FOR EACH PAYMENT YEARS**/
        INSERT  INTO etl.RiskScoreFactorsPartD
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
                SELECT  d.PaymentYear ,
                        d.MYUFlag ,
                        d.PlanIdentifier ,
                        d.HICN ,
                        ag.AgeGroupID ,
                        a.RxHCCLabel ,
                        v.Factor AS Factor ,
                        a.RxHCCLabel HCC_hierarchy ,
                        v.Factor AS factor_Hierarchy ,
                        a.RxHCCLabel AS HCC_Delete_Hierarchy ,
                        v.Factor AS FActor_delete_hierarchy ,
                        d.PartDRAFTProjected ,
                        d.PartDRAFTMMR ,
                        a.ModelYear ,
                        '0' AS Delete_flag ,
                        D.DateForFactors ,
                        a.RxHCCNumber ,
                        d.Aged ,
                        'EDS' AS SourceType ,
                        pk.EstRecvPartitionKeyID ,
                        @populate_date ,
                        USER_ID()
                FROM    rev.SummaryPartDRskAdjEDSPreliminary a ( NOLOCK )
                        JOIN etl.EstRecvDemographicsPartD d ON d.hicn = a.hicn
                                                              AND d.MonthRow = 1
                                                              AND d.PaymentYear = a.PaymentYear
                                                              AND d.PartDRAFTProjected = a.PartDRAFTProjected
                                                       --AND d.Aged = a.Aged --tpo be determined for Part C Also
                                                              AND d.PlanIdentifier = a.PlanIdentifier
                        JOIN #lk_Risk_Models v ON cast(substring(v.Factor_Description,4,LEN(v.Factor_Description)-3) as int) = a.RxHCCNumber
                                                  AND v.Factor_Type = a.PartDRAFTProjected
                                                  AND v.Payment_Year = a.PaymentYear
                                                  AND v.Aged = d.Aged
                        LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.RskAdjAgeGrp = ag.Description
                        LEFT JOIN etl.EstRecvPartitionKey pk ON pk.MYU = d.MYUFlag
                                                              AND pk.PaymentYear = d.PaymentYear
                                                              AND pk.SourceType = 'EDS'
                WHERE   ( a.ServiceStartDate >= @DCP_FROMDATE
                          AND a.ServiceEndDate <= @DCP_THRUDATE
                        )
                        AND a.PlanSubmissionDate <= @PROCESSBY
                        AND a.RiskAdjustable = 1
                        AND a.PaymentYear = @PaymentYear
                        AND v.Part_C_D_Flag = 'D'
                        AND v.Demo_Risk_Type = 'Risk'
                        AND v.Factor_Description not LIKE 'D-HCC%'
                GROUP BY d.PaymentYear ,
                        d.MYUFlag ,
                        d.PlanIdentifier ,
                        d.HICN ,
                        v.Factor ,
                        d.PartDRAFTProjected ,
                        a.ModelYear ,
                        D.DateForFactors ,
                        a.RxHCCNumber ,
                        ag.AgeGroupID ,
                        a.RxHCCLabel ,
                        d.Aged ,
                        pk.EstRecvPartitionKeyID ,
                        d.PartDRAFTMMR

SET @RowCount = Isnull(@@ROWCOUNT,0);                 
                        
END