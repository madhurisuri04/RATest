CREATE  PROCEDURE [rev].[EstRecevDemoCalcPartD]
(
@RowCount INT OUT
)
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.EstRecevDemoCalcPartD.proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	011/21/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates DEMO factors in Etl ER tables for PartD	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
75091        3/4/2019          Madhuri Suri       Part D Corrections 
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0 
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/   
    --Exec rev.EstRecevDemoCalcPartD
 
 /*****GET POPULATED DATE FROM DETAIL TABLE*/
        DECLARE @populate_date DATETIME = GETDATE()
        
--SELECT * FROM etl.EstRecvDemographicsPartD
--SELECT distinct sourcetype FROM etl.RiskScoreFactorsPartD
/**************************BUILDUP _ AGE/SEX and HCC*******************************************/

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/***************************************************************
GETTING THE MAX VALUES FROM #DEMOGRAPHICS FOR FACTOR VALUES  :
****************************************************************/

/**************************
MODEL SPLITS COMBINED :
***************************/

        IF OBJECT_ID('Tempdb..[#PYMySplits]') IS NOT NULL
            DROP TABLE [#PYMySplits]
        CREATE TABLE [#PYMySplits]
            (
              [PlanIdentifier] INT NULL ,
              [PaymentYear] [INT] NULL ,
              [ModelYear] [INT] NULL ,
              [HICN] [VARCHAR](12) NULL ,
              [PartDRAFTProjected] [VARCHAR](2) NULL
            ) 


        INSERT  INTO [#PYMySplits]
                ( [PlanIdentifier] ,
                  [PaymentYear] ,
                  [ModelYear] ,
                  [HICN] ,
                  [PartDRAFTProjected]
                )
                SELECT	DISTINCT
                        [PlanIdentifier] = [a].PlanIdentifier ,
                        [PaymentYear] = [a].[PaymentYear] ,
                        [ModelYear] = a.PaymentYear ,
                        [HICN] = [a].HICN ,
                        [PartDRAFTProjected] = [a].PartDRAFTProjected
                FROM    etl.EstRecvDemographicsPartD a
                WHERE   a.PartDRAFTProjected <> 'HP' 

        CREATE NONCLUSTERED INDEX [IX_#tbl_0020_HicnPYMySplits] ON [#PYMySplits]
        (
        [HICN],
        [PaymentYear]
        )
             
/***********************************************************
GETTING THE FACTOR VALUES FOR DEMOGRAPHICS FOR CURRENT YEAR:
************************************************************/
--Exec tempdb..sp_help #Demofactors
        IF OBJECT_ID('tempdb..#DemoFactors') IS NOT NULL
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
              Aged INT
            )

        INSERT  INTO #DemoFactors
        
        
        
/**AGE/SEX  **/ SELECT DISTINCT
                        d.hicn ,
                        d.RskAdjAgeGrp ,
                        B.Factor ,
                        'AGE/SEX' AS HCC ,
                        B.Factor_Description ,
                        d.PartDRAFTProjected ,
                        d.PartDRAFTMMR ,
                        0 AS DeleteFlag ,
                        d.PaymentYear ,
                        py.PaymentYear ,
                        d.DateForFactors ,
                        d.Aged
                FROM    etl.EstRecvDemographicsPartD d
                        JOIN #PYMySplits py ON py.HICN = d.HICN
                                               AND py.PaymentYear = d.PaymentYear
                                               AND py.PartDRAFTProjected = d.PartDRAFTProjected
                        JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag     
                        ON d.AgeGrpID = ag.AgeGroupID 
                        JOIN [$(HRPReporting)].dbo.lk_risk_models B ON b.Payment_Year = py.PaymentYear
                                                             AND   d.Gender = B.Gender
                                                             AND d.RskAdjAgeGrp = B.Factor_Description
                                                             AND d.PartDRAFTProjected = b.Factor_Type
                                                             AND b.Part_C_D_Flag = 'D'
                                                              --AND d.Aged = b.Aged
                                                              AND b.OREC = CASE
                                                              WHEN d.PartDRAFTProjected IN (
                                                              'D1', 'D2', 'D3' )
                                                              AND d.AgeGrpID > 6
                                                              THEN 0
                                                              WHEN d.PartDRAFTProjected IN (
                                                              'D1', 'D2', 'D3' )
                                                              AND d.AgeGrpID <= 6
                                                              THEN 1
                                                              WHEN d.PartDRAFTProjected NOT IN (
                                                              'D1', 'D2', 'D3' )
                                                              AND d.AgeGrpID < 6
                                                              THEN 0
                                                              WHEN d.PartDRAFTProjected NOT IN (
                                                              'D1', 'D2', 'D3' )
                                                              AND d.AgeGrpID >= 6
                                                              THEN ISNULL(d.ORECRestated,
                                                              0)
                                                              END
                                                               
                                                              AND d.PartDLowIncomeIndicator = b.LI
                                                              AND d.MonthRow = 1
                                                              
                UNION 
             

/**DISABILITY**/
                SELECT DISTINCT
                        d.HICN ,
                        C.OREC ,
                        C.Factor ,
                        'DISABILITY' ,
                        ' ' ,
                        d.PartDRAFTProjected ,
                        d.PartDRAFTMMR ,
                        0 ,
                        d.PaymentYear ,
                        py.ModelYear ,
                        d.DateForFactors ,
                        d.Aged
                FROM    etl.EstRecvDemographicsPartD d
                        JOIN #PYMySplits py ON py.HICN = d.HICN
                                               AND py.PaymentYear = d.PaymentYear
                                               AND py.PartDRAFTProjected = d.PartDRAFTProjected
                        
                         JOIN [$(HRPReporting)].dbo.lk_risk_models C    
									 on d.PartDRAFTProjected = c.Factor_Type    
									 and d.Gender= C.Gender  
									 and C.OREC = isnull(d.ORECRestated,0)    
									 and d.AgeGrpID >= 6         
									 and d.PartDLowIncomeIndicator = C.LI    
									 and Factor_Description = 'Medicaid Disability'    
									 and C.Payment_Year = Py.PaymentYear    
									 and C.Part_C_D_Flag = 'D'  
                 WHERE  d.MonthRow = 1    
                        

        TRUNCATE TABLE  etl.RiskScoreFactorsPartD
           /**DEMOGRAPHIC FACTOR VALUES FROM PAYMENT YEAR**/
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
                        D.PlanIdentifier ,
                        d.HICN ,
                        ag.AgeGroupID ,
                        df.HCCLabel ,
                        df.Factor ,
                        df.HCCLabel HCC_hierarchy ,
                        df.Factor AS Factor_Hierarchy ,
                        df.HCCLabel AS HCC_Delete_hierarchy ,
                        df.Factor AS Factor_delete_Hierarchy ,
                        df.RAFTRestated ,
                        d.[PartDRAFTProjected] ,
                        df.ModelYear ,
                        df.DeleteFlag ,
                        df.DateForFactors ,
                        0 ,
                        df.Aged ,
                        d.SourceType ,
                        d.PartitionKey ,
                        @populate_date ,
                        USER_ID()
                FROM    #demofactors df
                        INNER JOIN etl.EstRecvDemographicsPartD d ON d.hicn = df.hicn
                                                              AND d.PaymStart = df.DateForFactors
                        LEFT JOIN [$(HRPReporting)].dbo.lk_AgeGroups ag ON d.RskAdjAgeGrp = ag.Description
    
    
SET @RowCount = Isnull(@@ROWCOUNT,0);  
    
    UPDATE  a
    SET     a.MABID = PartD_BID
    FROM    [etl].EstRecvDemoCalcPartD a    
       JOIN etl.EstRecvDemographicsPartD b on b.HICN = a.HICN 
                                  AND b.PaymentYear = a.PaymentYear
                                 -- AND b.MonthRow = 1
            CROSS APPLY ( SELECT    PartD_BID
                          FROM      dbo.tbl_BIDS_rollup r
                          WHERE     Bid_Year = a.PaymentYear
                                    AND r.PBP = b.PBP
                                    AND r.SCC = b.SCC
                                    AND a.PlanID = b.PlanIdentifier
                        ) z   
                                               
   

    UPDATE  a
    SET     a.MABID = PartD_BID
    FROM    [etl].EstRecvDemoCalcPartD a
            JOIN etl.EstRecvDemographicsPartD b on b.HICN = a.HICN 
                                  AND b.PaymentYear = a.PaymentYear
                                  --AND b.MonthRow = 1
            CROSS APPLY ( SELECT    PartD_BID
                          FROM      dbo.tbl_BIDS_rollup r
                          WHERE     Bid_Year = a.PaymentYear
                                    AND r.PBP = b.pbp
                                    AND 'OOA' = r.SCC
                        ) z
    WHERE   a.MABID IS NULL  
                               
    
    
    
    
    END