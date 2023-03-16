CREATE  PROCEDURE [rev].[EstRecevDemoCalc]
(
@RowCount INT OUT
)
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.EstRecevDemoCalc.proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	04/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates DEMO factors in Etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
64919        6/12/2017         Madhuri Suri 
71667        6/21/2018		   Madhuri Suri        2019 Model changes 
75824        4/25/2019         Madhuri Suri      Part C ER 2.0 Minor Changes 
76279        7/25/2019         Madhuri Suri        Part C ER 2.0 EDS and RAPS MMR and MOR correction 
RRI-34/79581 09/15/20          Anand               Add Row Count Output Parameter

***********************************************************************************************/   
    --Exec rev.EstRecevDemoCalc 
 
 /*****GET POPULATED DATE FROM DETAIL TABLE*/
        DECLARE @populate_date DATETIME = GETDATE()
        

/**************************BUILDUP _ AGE/SEX and HCC*******************************************/

   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/***************************************************************
GETTING THE MAX VALUES FROM #DEMOGRAPHICS FOR FACTOR VALUES  :
****************************************************************/

/**************************
MODEL SPLITS COMBINED :
***************************/

        IF OBJECT_ID('Tempdb..[#PYMySplits]') > 0
            DROP TABLE [#PYMySplits]
        CREATE TABLE [#PYMySplits]
            (
              [PlanIdentifier] INT NULL ,
              [PaymentYear] [INT] NULL ,
              [ModelYear] [INT] NULL ,
              [HICN] [VARCHAR](12) NULL ,
              [PartCRAFTProjected] [VARCHAR](2) NULL, 
              [SubmissionModel][VARCHAR](8) NULL
            ) 


        INSERT  INTO [#PYMySplits]
                ( [PlanIdentifier] ,
                  [PaymentYear] ,
                  [ModelYear] ,
                  [HICN] ,
                  [PartCRAFTProjected],
                  [SubmissionModel]
                )
                SELECT	DISTINCT
                        [PlanIdentifier] = [a].PlanID ,
                        [PaymentYear] = [a].[PaymentYear] ,
                        [ModelYear] = [split].[ModelYear] ,
                        [HICN] = [a].HICN ,
                        [PartCRAFTProjected] = [a].PartCRAFTProjected , 
                        [SubmissionModel] = split.[SubmissionModel]
                FROM    etl.EstRecvDemographics a
                        LEFT JOIN [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] [split]
                        WITH ( NOLOCK ) ON [a].[PaymentYear] = [split].PaymentYear
                                           AND [a].PartCRAFTProjected = [split].[RAFactorType]
                WHERE   a.PartCRAFTProjected <> 'HP'
                AND split.SubmissionModel IN ( 'RAPS', 'EDS')

        CREATE NONCLUSTERED INDEX [IX_#tbl_0020_HicnPYMySplits] ON [#PYMySplits]
        (
        [HICN],
        [PaymentYear]
        )
/***********************************************************
GETTING THE FACTOR VALUES FOR DEMOGRAPHICS FOR CURRENT YEAR:
************************************************************/
--Exec tempdb..sp_help #Demofactors
        IF OBJECT_ID('tempdb..#DemoFactors') > 0
            DROP TABLE #Demofactors
        CREATE TABLE #Demofactors
            (
              HICN VARCHAR(12) ,
              AgeGrp INT ,
              Factor DECIMAL(20, 4) ,
              HCCLabel VARCHAR(19) ,
              Factor_Description VARCHAR(50) ,
              RAFTRestated VARCHAR(4) ,
              RAFTMMR VARCHAR(10) ,
              DeleteFlag INT ,
              Payment_year VARCHAR(4) ,
              ModelYear VARCHAR(4) ,
              DateForFactors DATETIME ,
              Aged INT, 
              SubmissionModel Varchar(8)
            )

        INSERT  INTO #DemoFactors
          (HICN ,
              AgeGrp ,
              Factor ,
              HCCLabel ,
              Factor_Description ,
              RAFTRestated ,
              RAFTMMR ,
              DeleteFlag  ,
              Payment_year  ,
              ModelYear  ,
              DateForFactors  ,
              Aged , 
              SubmissionModel )
/**AGE/SEX <> 'E' **/
                SELECT DISTINCT
                        d.hicn ,
                        d.RskAdjAgeGrp ,
                        B.Factor ,
                        'AGE/SEX' AS HCC ,
                        B.Factor_Description ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 AS DeleteFlag ,
                        d.PaymentYear ,
                        py.modelYear ,
                        d.DateForFactors ,
                        d.Aged, 
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        LEFT  JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender = B.Gender
                                                              AND d.RskAdjAgeGrp = B.Factor_Description
                                                              AND d.PartCRAFTProjected = b.Factor_Type
                                                              AND b.Part_C_D_Flag = 'C'
                                                              AND d.Aged = b.Aged
                                                              AND d.ORECRestated = b.OREC
                                                              AND b.Payment_Year = py.ModelYear
                WHERE   d.PartCRAFTMMR NOT IN ( 'E', 'E1', 'E2', 'ED', 'C',
                                                'I', 'CN', 'CP', 'CF' )
                        AND d.MonthRow = 1
                        
                UNION 
/**AGE/SEX = ''C', 'I', 'CN', 'CP', 'CF' **/
                SELECT DISTINCT
                        d.HICN ,
                        d.RskAdjAgeGrp ,
                        B.Factor ,
                        'AGE/SEX' ,
                        B.Factor_Description ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.modelYear ,
                        d.DateForFactors ,
                        d.Aged, 
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        LEFT  JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender = B.GENDER
                                                              AND d.RskAdjAgeGrp = B.Factor_Description
                                                              AND d.PartCRAFTProjected = b.Factor_Type
                                                              AND b.Part_C_D_Flag = 'C'
                                                              AND d.ORECRestated = b.OREC
                                                              AND b.Payment_Year = py.ModelYear
                                                              AND d.Aged = b.Aged
                WHERE   d.PartCRAFTProjected IN ( 'C', 'I', 'CN', 'CP', 'CF' )
                        AND d.MonthRow = 1
                        
                UNION 
             
/**AGE/SEX = 'E1', 'E2', 'ED' **/
                SELECT DISTINCT
                        d.HICN ,
                        d.RskAdjAgeGrp ,
                        B.Factor ,
                        'AGE/SEX' ,
                        B.Factor_Description ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.modelYear ,
                        d.DateForFactors ,
                        d.Aged, 
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        LEFT  JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender = B.GENDER
                                                              AND d.RskAdjAgeGrp = B.Factor_Description
                                                              AND d.PartCRAFTProjected = b.Factor_Type
                                                              AND b.Part_C_D_Flag = 'C'
                                                              AND d.ORECRestated = b.OREC
                                                              AND b.Payment_Year = py.ModelYear
                                                              AND d.Aged = b.Aged
                                                              AND d.MedicaidRestated = cast(B.Medicaid_Flag as varchar)
                WHERE   d.PartCRAFTProjected IN ( 'E1', 'E2', 'ED' )
                        AND d.MonthRow = 1
                        
                UNION 
             
                 
/**AGE/SEX = 'E' **/
                SELECT DISTINCT
                        d.HICN ,
                        d.RskAdjAgeGrp ,
                        B.Factor ,
                        'AGE/SEX' ,
                        B.Factor_Description ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.modelYear ,
                        d.DateForFactors ,
                        d.Aged,
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        LEFT  JOIN [$(HRPReporting)].dbo.lk_risk_models B ON d.Gender = B.GENDER
                                                              AND d.RskAdjAgeGrp = B.Factor_Description
                                                              AND d.PartCRAFTProjected = b.Factor_Type
                                                              AND b.Part_C_D_Flag = 'C'
                                                              AND d.ORECRestated = b.OREC
                                                              AND b.Payment_Year = py.ModelYear
                                                              AND d.Aged = b.Aged
                                                              AND d.MedicaidRestated = cast(B.Medicaid_Flag as varchar)
                WHERE   d.PartCRAFTProjected = 'E'
                        AND d.MonthRow = 1
                UNION 

/**DISABILITY**/
                SELECT DISTINCT
                        d.HICN ,
                        C.OREC ,
                        C.Factor ,
                        'DISABILITY' ,
                        ' ' ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.ModelYear ,
                        d.DateForFactors ,
                        d.Aged,
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        JOIN ( SELECT DISTINCT
                                        Factor_Type ,
                                        Factor ,
                                        Gender ,
                                        OREC ,
                                        ISNULL(Medicaid_Flag, 0) AS Medicaid_Flag ,
                                        Payment_Year ,
                                        c.Aged
                               FROM     [$(HRPReporting)].dbo.lk_risk_models c
                               WHERE    Factor_Description = 'Medicaid Disability'
                                        AND OREC = 1
                                        AND Medicaid_Flag = '9999'
                             ) c ON d.Gender = C.Gender
                                    AND d.PartCRAFTProjected = c.Factor_Type
                                    AND d.ORECRestated = c.OREC
                                    AND d.RskAdjAgeGrp > 6565
                                    AND c.Payment_Year = PY.ModelYear
                                    AND d.Aged = c.Aged
                                    AND d.MonthRow = 1
                UNION	

/**MEDICAID < 6565 **/
/**MEDICAID DISABILITY, MEDICAID ELSE DISABILITY**/
                SELECT DISTINCT
                        D.HICN ,
                        C.Medicaid_Flag ,
                        C.Factor ,
                        CASE WHEN d.MedicaidRestated = 'Y'
                                  AND d.ORECRestated = '1'
                             THEN 'MEDICAID DISABILITY'
                             WHEN d.MedicaidRestated = 'Y'
                                  AND d.ORECRestated = '0' THEN 'MEDICAID'
                             ELSE 'DISABILITY'
                        END ,
                        ' ' ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.ModelYear ,
                        d.DateForFactors ,
                        d.Aged,
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        JOIN [$(HRPReporting)].dbo.lk_risk_models c ON d.Gender = C.Gender
                                                              AND d.ORECRestated = c.OREC
                                                              AND  d.MedicaidRestated = cast(c.Medicaid_Flag as varchar)
                                                              AND d.PartCRAFTProjected = c.Factor_Type
                                                              AND c.Factor_Description = 'Medicaid Disability'
                                                              AND c.Payment_Year = py.ModelYear
                                                              AND d.Aged = c.Aged
                                                              AND d.RskAdjAgeGrp < 6565
                WHERE   d.MonthRow = 1
                UNION

/**MEDICAID > 6565 **/
                SELECT DISTINCT
                        d.HICN ,
                        C.Medicaid_Flag ,
                        C.Factor ,
                        'MEDICAID' ,
                        ' ' ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                       py.ModelYear ,
                        d.DateForFactors ,
                        d.Aged,
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        JOIN ( SELECT   Factor_Type ,
                                        Factor ,
                                        Gender ,
                                        ISNULL(Medicaid_Flag, 0) Medicaid_Flag ,
                                        C.Payment_Year ,
                                        c.Aged
                               FROM     [$(HRPReporting)].dbo.lk_risk_models c
                               WHERE    Medicaid_Flag = 1
                                        AND Factor_Description = 'Medicaid Disability'
                                        AND OREC = 0
                             ) c ON d.Gender = C.Gender
                                    AND d.MedicaidRestated= cast(c.Medicaid_Flag as varchar)
                                    AND d.PartCRAFTProjected = c.Factor_Type
                                    AND d.RskAdjAgeGrp > 6565
                                    AND C.Payment_Year = PY.ModelYear
                                    AND d.Aged = c.Aged
                WHERE   d.MonthRow = 1
                UNION 
/**GRAFT **/
                SELECT DISTINCT
                        D.HICN ,
                        C.Medicaid_Flag ,
                        C.Factor ,
                        'GRAFT' ,
                        ' ' ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.ModelYear ,
                        d.DateForFactors ,
                        d.aged,
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        JOIN [$(HRPReporting)].dbo.lk_risk_models c ON d.PartCRAFTProjected = c.Factor_Type
                                                              AND D.RskAdjAgeGrp = c.Factor_Description
                                                              AND d.Aged = c.Aged
                WHERE   Demo_Risk_Type = 'Graft'
                        AND C.PAYMENT_YEAR = py.ModelYear
                        AND d.MonthRow = 1
                UNION
                SELECT DISTINCT
                        d.HICN ,
                        C.Medicaid_Flag ,
                        C.Factor ,
                        'GRAFT' ,
                        ' ' ,
                        d.PartCRAFTProjected ,
                        d.PartCRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.ModelYear ,
                        d.DateForFactors ,
                        d.Aged,
                        py.SubmissionModel
                FROM    etl.EstRecvDemographics d
                        LEFT JOIN #PYMySplits py ON py.HICN = d.HICN
                                                    AND py.PaymentYear = d.PaymentYear
                                                    AND py.PartCRAFTProjected = d.PartCRAFTProjected
                        JOIN [$(HRPReporting)].dbo.lk_risk_models c ON d.PartCRAFTProjected = c.Factor_Type
                                                              AND d.Aged = c.Aged
                WHERE   Demo_Risk_Type = 'Graft'
                        AND c.Factor_Description = 9999
                        AND C.PAYMENT_YEAR = py.ModelYear
                        AND d.MonthRow = 1
--select * from #demofactors

        TRUNCATE TABLE  etl.RiskScoreFactorsPartC
           /**DEMOGRAPHIC FACTOR VALUES FROM PAYMENT YEAR**/
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
                        D.PlanID ,
                        d.HICN ,
                        ag.AgeGroupID ,
                        @populate_date ,
                        df.HCCLabel ,
                        df.Factor ,
                        df.HCCLabel HCC_hierarchy ,
                        df.Factor AS Factor_Hierarchy ,
                        df.HCCLabel AS HCC_Delete_hierarchy ,
                        df.Factor AS Factor_delete_Hierarchy ,
                        df.RAFTRestated ,
                        d.[PartCRAFTProjected] ,
                        df.ModelYear ,
                        df.DeleteFlag ,
                        df.DateForFactors ,
                        0 ,
                        df.Aged ,
                        CASE WHEN df.SubmissionModel = 'EDS' THEN 'EMMR' 
					     WHEN df.SubmissionModel = 'RAPS' THEN 'RMMR' 
						 END AS Sourcetype ,
                        d.PartitionKey
                FROM    #demofactors df
                        INNER JOIN etl.EstRecvDemographics d ON d.hicn = df.hicn
                                                              AND d.PaymStart = df.DateForFactors
                        LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.RskAdjAgeGrp = ag.Description;

SET @RowCount = @@ROWCOUNT;


    END