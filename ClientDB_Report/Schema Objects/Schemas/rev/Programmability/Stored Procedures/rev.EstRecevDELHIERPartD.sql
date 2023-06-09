CREATE PROCEDURE [rev].[EstRecevDELHIERPartD]
(
@RowCount INT OUT
)
AS
    BEGIN
        SET NOCOUNT ON

/************************************************************************        
* Name			:	rev.[EstRecevDELHIERPartD].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates HIER/INT into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
75091        3/4/2019         Madhuri Suri         Part D Corrections
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0 
RRI-229/79617 9/22/2020 Anand           Add Row Count Out Parameter
***********************************************************************************************/  
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        DECLARE @populate_date DATETIME = GETDATE()

/****************
UPDATE DELETES 
******************/
        UPDATE  a
        SET     DeleteFlag = 1 ,
                HCCDeleteHierarchy = 'DEL-' + HCCLabel ,
                Factor = B.Factor  ,
                FactorHierarchy = B.Factor  ,
                FactorDeleteHierarchy = 0
        FROM    etl.RiskScoreFactorsPartD a
                JOIN rev.ERPartDDeleteHCCOutput b ON a.HICN = b.HICN
                                                AND a.HCCNumber = REPLACE(REPLACE(REPLACE(REPLACE(b.RxHCC,
                                                              'DEL-HCC ', ''),
                                                              'DEL-HCC00', ''),
                                                              'DEL-HCC0', ''),
                                                              'DEL-HCC', '')
                                                AND A.ModelYear = B.Modelyear
                                                AND a.PaymentYear = b.Paymentyear --6/7
                LEFT JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp ON rp.PlanIdentifier = a.PlanIdentifier
        WHERE   b.RxHCC NOT LIKE 'INT%'
                AND b.PlanID = rp.PlanID--6/7

SET @RowCount = Isnull(@@ROWCOUNT,0);
                                            
/**********************************
RAPS HIERARCHY WITH DELETES - INTO BUILDUP 
************************************/
  ----SELECT * FROM etl.RiskScoreFactorsPartD WHERE HCCLabel LIKE 'HIER%'
        IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHY1]', 'U') IS NOT NULL
            DROP TABLE #HIERARCHY1 
        CREATE TABLE #HIERARCHY1
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY ,
              HICN VARCHAR(15) ,
              RAFTRestated VARCHAR(2) ,
              HCC1 VARCHAR(20) ,
              HCCNumber INT
            )   
        INSERT  #HIERARCHY1
                SELECT  A.HICN ,
                        A.PartDRAFTProjected ,
                        C.HCC_DROP ,
                        a.HCCNumber
                FROM    etl.RiskScoreFactorsPartD A
                        INNER JOIN etl.RiskScoreFactorsPartD B ON B.HICN = A.HICN
                                                              AND B.PaymentYear = A.PaymentYear
                                                              AND a.DateForFactors = b.DateForFactors
                                                              AND a.PlanIdentifier = b.PlanIdentifier
                                                              AND a.ModelYear = b.ModelYear
                                                              AND a.PartDRAFTProjected = b.PartDRAFTProjected
                        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C ON B.HCCLabel = C.HCC_KEEP
                                                              AND A.HCCLabel = C.HCC_DROP
                                                              AND A.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND B.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND C.Payment_Year = a.ModelYear
                                                              AND C.Part_C_D_Flag = 'D'
                WHERE   a.SourceType IN ( 'RAPS', 'MOR' ) 
     
        IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHY2]', 'U') IS NOT NULL
            DROP TABLE #HIERARCHY2 
        CREATE TABLE #HIERARCHY2
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY ,
              HICN VARCHAR(15) ,
              RAFTRestated VARCHAR(2) ,
              HCC1 VARCHAR(20) ,
              HCCNumber INT
            )   
                    
                    
                    
        INSERT  #HIERARCHY2
                SELECT  A.HICN ,
                        A.PartDRAFTProjected ,
                        C.HCC_DROP ,
                        a.HCCNumber
                FROM    etl.RiskScoreFactorsPartD A
                        INNER JOIN etl.RiskScoreFactorsPartD B ON B.HICN = A.HICN
                                                              AND B.PaymentYear = A.PaymentYear
                                                              AND a.DateForFactors = b.DateForFactors
                                                              AND a.PlanIdentifier = b.PlanIdentifier
                                                              AND a.ModelYear = b.ModelYear
                                                              AND a.PartDRAFTProjected = b.PartDRAFTProjected
                                                              AND a.SourceType = b.SourceType
                        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C ON B.HCCLabel = C.HCC_KEEP
                                                              AND A.HCCLabel = C.HCC_DROP
                                                              AND A.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND B.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND C.Payment_Year = a.ModelYear
                                                              AND C.Part_C_D_Flag = 'D'
                                                              AND A.PartDRAFTProjected = C.RA_FACTOR_TYPE
                WHERE   A.DeleteFlag = 0
                        AND B.DeleteFlag = 0
                        AND a.SourceType IN ( 'RAPS', 'MOR' ) 
   

                           
        UPDATE  A
        SET     A.HCCHierarchy = 'HIER-' + HCCLabel ,
                A.HCCDeleteHierarchy = 'HIER-' + HCCLabel ,
                A.FactorHierarchy = 0 ,
                a.FactorDeleteHierarchy = 0
        FROM    etl.RiskScoreFactorsPartD A
                JOIN #HIERARCHY1 Hier ON hier.HICN = a.HICN
                                         AND hier.RAFTRestated = a.PartDRAFTProjected
                                         AND hier.HCCNumber = a.HCCNumber
        WHERE   a.SourceType IN ( 'RAPS', 'MOR' ) 
   
 SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);
                                        
/**********************************
EDS HIERARCHY WITH DELETES - INTO BUILDUP 
************************************/
        IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHYEDS1]', 'U') IS NOT NULL
            DROP TABLE #HIERARCHYEDS1 
        CREATE TABLE #HIERARCHYEDS1
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY ,
              HICN VARCHAR(15) ,
              RAFTRestated VARCHAR(2) ,
              HCC1 VARCHAR(20) ,
              HCCNumber INT
            )   
        INSERT  #HIERARCHYEDS1
                SELECT  A.HICN ,
                        A.PartDRAFTProjected ,
                        C.HCC_DROP ,
                        a.HCCNumber
                FROM    etl.RiskScoreFactorsPartD A
                        INNER JOIN etl.RiskScoreFactorsPartD B ON B.HICN = A.HICN
                                                              AND B.PaymentYear = A.PaymentYear
                                                              AND a.DateForFactors = b.DateForFactors
                                                              AND a.PlanIdentifier = b.PlanIdentifier
                                                              AND a.ModelYear = b.ModelYear
                                                              AND a.PartDRAFTProjected = b.PartDRAFTProjected
                                                              AND a.SourceType = b.SourceType
                        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C ON B.HCCLabel = C.HCC_KEEP
                                                              AND A.HCCLabel = C.HCC_DROP
                                                              AND A.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND B.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND C.Payment_Year = a.ModelYear
                                                              AND C.Part_C_D_Flag = 'D'
                WHERE   a.SourceType = 'EDS'
     
        IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHYEDS2]', 'U') IS NOT NULL
            DROP TABLE #HIERARCHYEDS2 
        CREATE TABLE #HIERARCHYEDS2
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY ,
              HICN VARCHAR(15) ,
              RAFTRestated VARCHAR(2) ,
              HCC1 VARCHAR(20) ,
              HCCNumber INT
            )   
                    
                    
                    
        INSERT  #HIERARCHYEDS2
                SELECT  A.HICN ,
                        A.PartDRAFTProjected ,
                        C.HCC_DROP ,
                        a.HCCNumber
                FROM    etl.RiskScoreFactorsPartD A
                        INNER JOIN etl.RiskScoreFactorsPartD B ON B.HICN = A.HICN
                                                              AND B.PaymentYear = A.PaymentYear
                                                              AND a.DateForFactors = b.DateForFactors
                                                              AND a.PlanIdentifier = b.PlanIdentifier
                                                              AND a.ModelYear = b.ModelYear
                                                              AND a.PartDRAFTProjected = b.PartDRAFTProjected --6/7
                                                              AND a.SourceType = b.SourceType --6/13 
                        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C ON B.HCCLabel = C.HCC_KEEP
                                                              AND A.HCCLabel = C.HCC_DROP
                                                              AND A.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND B.PartDRAFTProjected = C.RA_FACTOR_TYPE
                                                              AND C.Payment_Year = a.ModelYear
                                                              AND C.Part_C_D_Flag = 'D'
                                                              AND A.PartDRAFTProjected = C.RA_FACTOR_TYPE
                WHERE   A.DeleteFlag = 0
                        AND B.DeleteFlag = 0
                        AND A.SourceType = 'EDS'
                       

                           
        UPDATE  A
        SET     A.HCCHierarchy = 'HIER-' + HCCLabel ,
                A.HCCDeleteHierarchy = 'HIER-' + HCCLabel ,
                A.FactorHierarchy = 0 ,
                a.FactorDeleteHierarchy = 0
        FROM    etl.RiskScoreFactorsPartD A
                JOIN #HIERARCHYEDS1 Hier ON hier.HICN = a.HICN
                                            AND hier.RAFTRestated = a.PartDRAFTProjected
                                            AND hier.HCCNumber = a.HCCNumber
        WHERE   A.SourceType = 'EDS'             
    
   
SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);      
                                                              
END