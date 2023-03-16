CREATE PROCEDURE [rev].[EstRecevEDSCalc]
    (
      @Payment_Year VARCHAR(4) ,
      @MYU VARCHAR(1),
	  @RowCount INT OUT
    )
AS /************************************************************************        
* Name			:	rev.EstRecevEDSCalc.proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	06/26/2017											*	
* Ticket        :   65509
* Version		:        												*
* Description	:	Populates EDS HCCs into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
71667        6/21/2018         Madhuri Suri        2019 Model Changes 
73840        11/05/2018        Madhuri Suri        Defects ER 2.0
RRI-34/79581 09/15/20          Anand               Add Row Count Output Parameter

***********************************************************************************************/  
    BEGIN 
 --EXEC  rev.EstRecevEDSCalc 2016, 'N'
 
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    --DECLARE @Payment_Year VARCHAR(4)= 2016 ,
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
                WHERE   ( E.PAYMENT_YEAR IN (
                          SELECT    ModelYear
                          FROM      [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC a
                          WHERE     PaymentYear = @PaymentYear                           
                               AND a.RAFactorType = e.Factor_Type 
                               AND a.SubmissionModel = 'EDS'  ) /*71667 Change 2*/
                          OR E.PAYMENT_YEAR = @PaymentYear
                        )
                        AND E.Part_C_D_Flag = 'C' 
        CREATE NONCLUSTERED INDEX IX_lk_Risk_Models ON #lk_Risk_Models (Factor_Description,Factor_Description_Restated, FACTOR_TYPE) 
  
  
----/**EDS FACTOR VALUES FOR BOTH YEARS**/
        INSERT  INTO etl.RiskScoreFactorsPartC
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
        SELECT  d.PaymentYear ,
                d.MYUFlag ,
                d.PlanID ,
                d.HICN ,
                ag.AgeGroupID ,
                @populate_date ,
                a.HCC_Label ,
                v.Factor AS Factor ,
                a.HCC_Label HCC_hierarchy ,
                v.Factor AS factor_Hierarchy ,
                a.HCC_Label AS HCC_Delete_Hierarchy ,
                v.Factor AS FActor_delete_hierarchy ,
                d.PartCRAFTProjected ,
                d.PartCRAFTMMR ,
                py.ModelYear ,
                '0' AS Delete_flag ,
                D.DateForFactors ,
                a.HCC_Number ,
                d.Aged ,
                'EDS' AS SourceType ,
                pk.EstRecvPartitionKeyID
        FROM    rev.tbl_Summary_RskAdj_EDS_Preliminary a ( NOLOCK )
                JOIN etl.EstRecvDemographics d ON d.hicn = a.hicn
                                                  AND d.MonthRow = 1
                                                  AND d.PaymentYear = a.PaymentYear
                                                  AND d.PartCRAFTProjected = a.PartCRAFTProjected
                                                       --AND d.Aged = a.Aged --6/6
                                                        AND d.PlanID = a.PlanIdentifier -- 6/7
                JOIN [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] py ON py.PaymentYear = a.PaymentYear
                                                              AND py.RAFactorType = a.PartCRAFTProjected
                                                              AND py.SubmissionModel = 'EDS' /*71667 Change 1*/
                JOIN #lk_Risk_Models v ON v.Factor_Description = a.HCC_Label
                                          AND v.Factor_Type = a.PartCRAFTProjected
                                          AND v.Payment_Year = py.ModelYear
                                          AND v.Aged = d.Aged --6/6
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
                AND v.Part_C_D_Flag = 'C'
        GROUP BY d.PaymentYear ,
                d.MYUFlag ,
                d.PlanID ,
                d.HICN ,
                ag.AgeGroupID ,
                a.HCC_Label ,
                v.Factor ,
                d.PartCRAFTProjected ,
                py.ModelYear ,
                D.DateForFactors ,
                a.HCC_Number ,
                d.Aged ,
                pk.EstRecvPartitionKeyID ,
                d.PartCRAFTMMR
                        
SET @RowCount = @@ROWCOUNT;
                        
    END