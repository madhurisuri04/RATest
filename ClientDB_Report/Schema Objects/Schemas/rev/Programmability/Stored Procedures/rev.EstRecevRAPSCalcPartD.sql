CREATE   PROCEDURE [rev].[EstRecevRAPSCalcPartD]
    (
      @Payment_Year VARCHAR(4) ,
      @MYU VARCHAR(1),
	  @RowCount INT OUT
    )
AS
BEGIN
    SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.EstRecevRAPSCalcPartD.proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates RAPS in etl RiskScoreFactorsPartD tables from Summary Tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
71900       7/9/2018         Madhuri Suri         2019 changes - remove estrecvmodelsplits table reference
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    --DECLARE @Payment_Year VARCHAR(4)= 2018 ,
    --    @MYU VARCHAR(1) = 'N'
    DECLARE @PaymentYear VARCHAR(4) = @Payment_Year ,
        @MYUFlag VARCHAR(1) = @MYU
 
    DECLARE @DCP_FROMDATE DATETIME ,
        @DCP_THRUDATE DATETIME ,
        @PROCESSBY DATETIME                                  
    SELECT  @DCP_FROMDATE = [DCPFromDate] ,
            @DCP_Thrudate = [DCPThrudate] ,
            @PROCESSBY = [ProcessedBy]
    FROM    rev.EstRecevRefreshPY a
    WHERE   a.[Payment_Year] = @PaymentYear
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
                         THEN REPLACE(E.Factor_Description, 'HCC00', 'HCC ')
                         WHEN E.Factor_Description LIKE 'HCC0%'
                         THEN REPLACE(E.Factor_Description, 'HCC0', 'HCC ')
                         WHEN E.Factor_Description LIKE 'HCC%'
                         THEN REPLACE(E.Factor_Description, 'HCC1', 'HCC 1')
                         ELSE E.Factor_Description
                    END AS Factor_Description_Restated ,
                    ISNULL(Aged, '9999') Aged  /*59973*/
            FROM    [$(HRPReporting)].dbo.lk_Risk_Models E
            WHERE    E.PAYMENT_YEAR = @PaymentYear
                    AND E.Part_C_D_Flag = 'D' 
    CREATE NONCLUSTERED INDEX IX_lk_Risk_Models ON #lk_Risk_Models (Factor_Description,Factor_Description_Restated, FACTOR_TYPE) 
   IF OBJECT_ID('[TEMPDB].[DBO].[#Vw_LkRiskModelsDiagHCC]') is not null   
   DROP TABLE #Vw_LkRiskModelsDiagHCC    
    
  CREATE TABLE #Vw_LkRiskModelsDiagHCC (    
   ICDCode VARCHAR(10)    
   ,HCCLabel VARCHAR(10)    
   ,PaymentYear VARCHAR(4)    
   ,FactorType VARCHAR(3)    
   ,ICDClassification TINYINT    
   ,StartDate DATETIME    
   ,EndDate DATETIME    
   ,HCCNumber INT 
   )    
  CREATE CLUSTERED INDEX Vw_LkRiskModelsDiagHCC on #Vw_LkRiskModelsDiagHCC (ICDCode, HCCLabel)    
    
  INSERT INTO #Vw_LkRiskModelsDiagHCC (    
   ICDCode    
   ,HCCLabel    
   ,PaymentYear    
   ,FactorType    
   ,ICDClassification    
   ,StartDate    
   ,EndDate 
   ,HCCNumber   
   )    
  SELECT ICDCode    
   ,HCCLabel    
   ,PaymentYear    
   ,FactorType    
   ,ICD.ICDClassification    
   ,ef.StartDate    
   ,ef.EndDate  
   ,icd.HCCNumber  
  FROM [$(HRPReporting)].dbo.[Vw_LkRiskModelsDiagHCC] ICD    
  JOIN [$(HRPReporting)].dbo.ICDEffectiveDates ef ON icd.ICDClassification = ef.ICDClassification    
  WHERE Paymentyear = @Payment_Year    
  
----/**RAPS FACTOR VALUES FOR BOTH YEARS**/
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
              [PartitionKey], 
              [LoadDate], 
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
                    'RAPS' AS SourceType ,
                    pk.EstRecvPartitionKeyID,
                    @populate_date ,
                    USER_ID() 
     FROM    rev.SummaryPartDRskAdjRAPSPreliminary a
                    JOIN etl.EstRecvDemographicsPartD d ON d.hicn = a.hicn
                                                           AND d.MonthRow = 1
                                                           AND d.PaymentYear = a.PaymentYear
                                                           AND d.PartDRAFTProjected = a.PartDRAFTProjected
                                                           AND d.Aged = a.Aged
                                                           AND d.PlanIdentifier = a.PlanIdentifier
                    
                    JOIN #Vw_LkRiskModelsDiagHCC C on a.DIAGNOSISCODE = C.ICDCode AND a.ThruDate BETWEEN c.StartDate AND c.EndDate
                    JOIN #lk_Risk_Models v ON  v.Payment_Year = a.ModelYear
		                                     AND cast(substring(v.Factor_Description,4,LEN(v.Factor_Description)-3) as int) = a.RxHCCNumber
	                                         AND v.Factor_Type = a.PartDRAFTProjected
	                                         AND v.Aged = a.Aged
                    LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.RskAdjAgeGrp = ag.Description
                    LEFT JOIN etl.EstRecvPartitionKey pk ON pk.MYU = d.MYUFlag
                                                            AND pk.PaymentYear = d.PaymentYear
                                                            AND pk.SourceType = 'RAPS'
            WHERE   a.ThruDate BETWEEN @DCP_FROMDATE
                               AND     @DCP_THRUDATE
                    AND a.ProcessedBy <= @PROCESSBY
                    AND a.PaymentYear = @PaymentYear
                    AND v.Part_C_D_Flag = 'D'
                    AND v.Demo_Risk_Type = 'Risk'
                  
                    AND v.Factor_Description not LIKE 'D-HCC%'
                    --AND d.RskAdjAgeGrp < '6565'
                    --AND v.OREC = CASE     
                    --         WHEN d.AgeGrpID > 6 THEN 0    
                    --         WHEN d.AgeGrpID <= 6 THEN 1  
                    --         END     
                      --  AND d.PartDLowIncomeIndicator = v.LI 
                       -- and a.HICN = '1AG0JM4TR27'
                        and v.Demo_Risk_Type = 'Risk'
            GROUP BY d.PaymentYear ,
                    d.MYUFlag ,
                    d.PlanIdentifier ,
                    d.HICN ,
                    ag.AgeGroupID ,
                    a.RxHCCLabel ,
                    v.Factor ,
                    d.PartDRAFTProjected ,
                    a.ModelYear ,
                    D.DateForFactors ,
                    a.RxHCCLabel ,
                    d.Aged ,
                    pk.EstRecvPartitionKeyID ,
                    d.PartDRAFTMMR, 
                    a.RxHCCNumber
   
SET @RowCount = @@ROWCOUNT;

END