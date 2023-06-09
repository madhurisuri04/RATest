CREATE PROCEDURE [rev].[EstRecevRiskScoreCalcPartD]
    (
      @Payment_Year VARCHAR(4),
	  @RowCount INT OUT
    )
AS
 /************************************************************************        
* Name			:	rev.[EstRecevRiskScoreCalcPartD].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates RiskScores into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/  
    BEGIN 
    --DECLARE @Payment_Year VARCHAR(4) = 2018
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        DECLARE @populate_date DATETIME = GETDATE()

/*******************************
RISKSCORE WITH DELETES:
*******************************/
        IF OBJECT_ID('Tempdb.dbo.#RiskScoresPartD') IS NOT NULL
            DROP TABLE #RiskScoresPartD
        CREATE TABLE #RiskScoresPartD
            (
              [ID] [BIGINT] NOT NULL
                            IDENTITY(1, 1) ,
              [Planidentifier] [INT] NULL ,
              [HICN] [VARCHAR](12) NULL ,
              [PaymentYear] [VARCHAR](4) NOT NULL ,
              [MYUFlag] [VARCHAR](1) NOT NULL ,
              [PartDRAFTProjected] [VARCHAR](4) NULL ,
              [RiskScoreCalculated] [DECIMAL](20, 4) NULL ,
              [ModelYear] [VARCHAR](4) NULL ,
              [DeleteYN] [INT] NULL ,
              [DateForFactors] [DATETIME] NULL ,
              [SourceType] VARCHAR(4) NULL
            ) 

/* DeleteYN = 1 means it includes deletes */

        INSERT  INTO #RiskScoresPartD
                ( Planidentifier ,
                  HICN ,
                  PaymentYear ,
                  MYUFlag ,
                  PartDRAFTProjected ,
                  RiskScoreCalculated ,
                  ModelYear ,
                  DeleteYN ,
                  DateForFactors ,
                  SourceType
                )
                SELECT  b.PlanIdentifier ,
                        b.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        b.PartDRAFTProjected ,
                        ROUND(SUM(ISNULL(b.FactorHierarchy, 0))
                              / MAX(modsplit.PARTD_FACTOR), 3) RiskScoreCalculate ,
                        B.ModelYear ,
                        1 AS DeleteYN ,
                        b.DateForFactors ,
                        'RAPS'
                FROM    etl.RiskScoreFactorsPartD b
                        LEFT JOIN [$(HRPReporting)].dbo.lk_normalization_factors ModSplit ON ModSplit.Year = @Payment_Year
                WHERE   b.SourceType IN ( 'MMR', 'RAPS', 'MOR', 'INT' )
                 
                GROUP BY B.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        B.PartDRAFTProjected ,
                        B.ModelYear ,
                        b.DateForFactors ,
                        B.HICN ,
                        b.DeleteFlag ,
                        b.PlanIdentifier ,
                        modsplit.PARTD_FACTOR 

/* DeleteYN = 0 means it includes deletes */  
/*******************************
RISKSCORE WITHOUT DELETES:
*******************************/
        INSERT  INTO #RiskScoresPartD
                ( Planidentifier ,
                  HICN ,
                  PaymentYear ,
                  MYUFlag ,
                  PartDRAFTProjected ,
                  RiskScoreCalculated ,
                  ModelYear ,
                  DeleteYN ,
                  DateForFactors ,
                  SourceType
                )
                SELECT  b.PlanIdentifier ,
                        b.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        b.PartDRAFTProjected ,
                        ROUND(SUM(ISNULL(b.FactorDeleteHierarchy, 0))
                              / MAX(modsplit.PARTD_FACTOR), 3) RiskScoreCalculate ,
                        B.ModelYear ,
                        0 AS DeleteYN ,
                        b.DateForFactors ,
                        'RAPS'
                FROM    etl.RiskScoreFactorsPartD b
                        LEFT JOIN [$(HRPReporting)].dbo.lk_normalization_factors ModSplit ON ModSplit.Year = @Payment_Year
                WHERE   b.SourceType IN ( 'MMR', 'RAPS', 'MOR', 'INT' )
                GROUP BY B.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        B.PartDRAFTProjected ,
                        B.ModelYear ,
                        b.DateForFactors ,
                        B.HICN ,
                        b.DeleteFlag ,
                        b.PlanIdentifier ,
                        modsplit.PARTD_FACTOR

        INSERT  INTO #RiskScoresPartD
                ( Planidentifier ,
                  HICN ,
                  PaymentYear ,
                  MYUFlag ,
                  PartDRAFTProjected ,
                  RiskScoreCalculated ,
                  ModelYear ,
                  DeleteYN ,
                  DateForFactors ,
                  SourceType
                )
                SELECT  b.PlanIdentifier ,
                        b.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        b.PartDRAFTProjected ,
                        ROUND(SUM(ISNULL(b.FactorHierarchy, 0))
                              / MAX(modsplit.PARTD_FACTOR), 3) RiskScoreCalculate ,
                        B.ModelYear ,
                        1 AS DeleteYN ,
                        b.DateForFactors ,
                        'EDS'
                FROM    etl.RiskScoreFactorsPartD b
                        LEFT JOIN [$(HRPReporting)].dbo.lk_normalization_factors ModSplit ON ModSplit.Year = @Payment_Year
                WHERE   b.SourceType IN ( 'EDS', 'MMR' )
                GROUP BY B.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        B.PartDRAFTProjected ,
                        B.ModelYear ,
                        b.DateForFactors ,
                        B.HICN ,
                        b.DeleteFlag ,
                        b.PlanIdentifier ,
                        modsplit.PARTD_FACTOR

/* DeleteYN = 0 means it includes deletes */  
/*******************************
RISKSCORE WITHOUT DELETES:
*******************************/
        INSERT  INTO #RiskScoresPartD
                ( Planidentifier ,
                  HICN ,
                  PaymentYear ,
                  MYUFlag ,
                  PartDRAFTProjected ,
                  RiskScoreCalculated ,
                  ModelYear ,
                  DeleteYN ,
                  DateForFactors ,
                  SourceType
                )
                SELECT  b.PlanIdentifier ,
                        b.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        b.PartDRAFTProjected ,
                        ROUND(SUM(ISNULL(b.FactorDeleteHierarchy, 0))
                              / MAX(modsplit.PARTD_FACTOR), 3) RiskScoreCalculate ,
                        B.ModelYear ,
                        0 AS DeleteYN ,
                        b.DateForFactors ,
                        'EDS'
                FROM    etl.RiskScoreFactorsPartD b
                        LEFT JOIN [$(HRPReporting)].dbo.lk_normalization_factors ModSplit ON ModSplit.Year = @Payment_Year
                WHERE   b.SourceType IN ( 'EDS', 'MMR' )
                GROUP BY B.HICN ,
                        b.PaymentYear ,
                        b.MYUFlag ,
                        B.PartDRAFTProjected ,
                        B.ModelYear ,
                        b.DateForFactors ,
                        B.HICN ,
                        b.DeleteFlag ,
                        b.PlanIdentifier ,
                        modsplit.PARTD_FACTOR 
                        
        TRUNCATE TABLE etl.[RiskScoresPartD]
        
        INSERT  INTO etl.RiskScoresPartD
                ( Planidentifier ,
                  HICN ,
                  PaymentYear ,
                  MYUFlag ,
                  PartDRAFTProjected ,
                  RiskScoreCalculated ,
                  ModelYear ,
                  DeleteYN ,
                  DateForFactors ,
                  SourceType ,
                  PartitionKey ,
                  LoadDate ,
                  UserID
                )
                SELECT  Planidentifier ,
                        HICN ,
                        a.PaymentYear ,
                        a.MYUFlag ,
                        PartDRAFTProjected ,
                        RiskScoreCalculated ,
                        ModelYear ,
                        DeleteYN ,
                        DateForFactors ,
                        a.SourceType ,
                        b.EstRecvPartitionKeyID ,
                        @populate_date ,
                        USER_ID()
                FROM    #RiskScoresPartD a
                        JOIN [etl].[EstRecvPartitionKey] b ON a.PaymentYear = b.PaymentYear
                                                              AND b.MYU = a.MYUFlag   
                                                              and a.SourceType = b.SourceType                        
                                                     
                          
SET @RowCount = @@ROWCOUNT;

END