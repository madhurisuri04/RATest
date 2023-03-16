CREATE PROCEDURE [rev].[EstRecevRiskScoreCalc]
    (
      @Payment_Year VARCHAR(4),
	  @RowCount INT OUT
    )
AS

 /************************************************************************        
* Name			:	rev.[EstRecevRiskScoreCalc].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	04/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates RiskScores into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
64919       6/12/2017          Madhuri Suri
65509       6/26/2017          Madhuri Suri        EDS Implementation 
65708       7/10/2017          Madhuri Suri        EDSRAPS Split by MYUFlag 
65872       7/19              Madhuri Suri        100 % Raps and EDS
73560       11/5/2018         Madhuri Suri        Integrate EDS MOR into ER 
                                                  ER Defect coorection to Remove Duplicates 
76279        7/25/2019         Madhuri Suri        Part C ER 2.0 EDS and RAPS MMR and MOR correction 
RRI-34/79581 09/15/20          Anand               Add Row Count Output Parameter

***********************************************************************************************/  
BEGIN 
    --DECLARE @Payment_Year VARCHAR(4) = 2016
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    DECLARE @populate_date DATETIME = GETDATE()

/*******************************
RISKSCORE WITH DELETES:
*******************************/
    IF OBJECT_ID('Tempdb.dbo.#RiskScoresPartC') > 1
        DROP TABLE #RiskScoresPartC
    CREATE TABLE #RiskScoresPartC
        (
          [ID] [BIGINT] NOT NULL
                        IDENTITY(1, 1) ,
          [Planidentifier] [INT] NULL ,
          [HICN] [VARCHAR](12) COLLATE SQL_Latin1_General_CP1_CI_AS
                               NULL ,
          [PaymentYear] [VARCHAR](4) COLLATE SQL_Latin1_General_CP1_CI_AS
                                     NOT NULL ,
          [MYUFlag] [VARCHAR](1) COLLATE SQL_Latin1_General_CP1_CI_AS
                                 NOT NULL ,
          [PartCRAFTProjected] [VARCHAR](4)
            COLLATE SQL_Latin1_General_CP1_CI_AS
            NULL ,
          [RiskScoreCalculated] [DECIMAL](20, 4) NULL ,
          [ModelYear] [VARCHAR](4) COLLATE SQL_Latin1_General_CP1_CI_AS
                                   NULL ,
          [DeleteYN] [INT] NULL ,
          [DateForFactors] [DATETIME] NULL ,
          [SourceType] VARCHAR(4) NULL
        ) 

/* DeleteYN = 1 means it includes deletes */

    INSERT  INTO #RiskScoresPartC
            ( Planidentifier ,
              HICN ,
              PaymentYear ,
              MYUFlag ,
              PartCRAFTProjected ,
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
                    b.PartCRAFTProjected ,
                    CASE WHEN b.PartCRAFTProjected IN ( 'D', 'ED', 'G1', 'G2' )
                         THEN ROUND(( SUM(b.FactorHierarchy)
                                      / ModSplit.ESRDDialysisFactor ), 3)
                         WHEN b.PartCRAFTProjected IN ( 'C1', 'C2', 'I1', 'I2',
                                                        'E1', 'E2' )
                         THEN ROUND(ROUND(( SUM(b.FactorHierarchy)
                                            / ModSplit.FunctioningGraftFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                         WHEN b.PartCRAFTProjected <> b.PartCRAFTMMR
                         THEN ROUND(ROUND(ROUND(( SUM(DISTINCT B.FactorHierarchy)
                                                  / ModSplit.PartCNormalizationFactor ),
                                                3) * ( 1
                                                       - ModSplit.CodingIntensity ),
                                          3) * ModSplit.SplitSegmentWeight, 3)
                         WHEN b.PartCRAFTProjected IN ( 'C', 'E', 'I', 'CN',
                                                        'CP', 'CF' )--6/7
                              THEN ROUND(ROUND(ROUND(( SUM(B.FactorHierarchy)
                                                       / ModSplit.PartCNormalizationFactor ),
                                                     3) * ( 1
                                                            - ModSplit.CodingIntensity ),
                                               3)
                                         * ModSplit.SplitSegmentWeight, 3)
                         ELSE ROUND(ROUND(( SUM(B.FactorHierarchy)
                                            / ModSplit.PartCNormalizationFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                    END AS RiskScoreCalculate , --6/5
                    B.ModelYear ,
                    1 AS DeleteYN ,
                    b.DateForFactors ,
                    'RAPS'
            FROM    etl.RiskScoreFactorsPartC b
                    LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC ModSplit ON ModSplit.ModelYear = B.ModelYear --6/5
                                                              AND modsplit.RAFactorType = b.PartCRAFTProjected
                                                              AND ModSplit.PaymentYear = @Payment_Year
            WHERE   b.SourceType IN ( 'RMMR', 'RAPS', 'RMOR', 'INT' )
                  AND  modsplit.SubmissionModel = 'RAPS' 
            GROUP BY B.HICN ,
                    b.PaymentYear ,
                    b.MYUFlag ,
                    B.PartCRAFTProjected ,
                    b.PartCRAFTMMR ,
                    B.ModelYear ,
                    ModSplit.ESRDDialysisFactor ,
                    ModSplit.SplitSegmentWeight ,
                    ModSplit.FunctioningGraftFactor ,
                    ModSplit.CodingIntensity ,
                    ModSplit.PartCNormalizationFactor ,
                    b.DateForFactors ,
                    B.HICN ,
                    b.DeleteFlag ,
                    b.PlanIdentifier 

/* DeleteYN = 0 means it includes deletes */  
/*******************************
RISKSCORE WITHOUT DELETES:
*******************************/
    INSERT  INTO #RiskScoresPartC
            ( Planidentifier ,
              HICN ,
              PaymentYear ,
              MYUFlag ,
              PartCRAFTProjected ,
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
                    b.PartCRAFTProjected ,
                    CASE WHEN b.PartCRAFTProjected IN ( 'D', 'ED', 'G1', 'G2' )
                         THEN ROUND(( SUM(b.FactorDeleteHierarchy)
                                      / ModSplit.ESRDDialysisFactor ), 3)
                         WHEN b.PartCRAFTProjected IN ( 'C1', 'C2', 'I1', 'I2',
                                                        'E1', 'E2' )
                         THEN ROUND(ROUND(( SUM(b.FactorDeleteHierarchy)
                                            / ModSplit.FunctioningGraftFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                         WHEN b.PartCRAFTProjected <> b.PartCRAFTMMR
                         THEN ROUND(ROUND(ROUND(( SUM(DISTINCT B.FactorDeleteHierarchy)
                                                  / ModSplit.PartCNormalizationFactor ),
                                                3) * ( 1
                                                       - ModSplit.CodingIntensity ),
                                          3) * ModSplit.SplitSegmentWeight, 3)
                         WHEN b.PartCRAFTProjected IN ( 'C', 'E', 'I', 'CN',
                                                        'CP', 'CF' ) --6/7
                              THEN ROUND(ROUND(ROUND(( SUM(B.FactorDeleteHierarchy)
                                                       / ModSplit.PartCNormalizationFactor ),
                                                     3) * ( 1
                                                            - ModSplit.CodingIntensity ),
                                               3)
                                         * ModSplit.SplitSegmentWeight, 3)
                         ELSE ROUND(ROUND(( SUM(B.FactorDeleteHierarchy)
                                            / ModSplit.PartCNormalizationFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                    END AS RiskScoreCalculate ,
                    B.ModelYear ,
                    0 AS DeleteYN ,
                    b.DateForFactors ,
                    'RAPS'
            FROM    etl.RiskScoreFactorsPartC b
                    LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC ModSplit ON ModSplit.ModelYear = B.ModelYear --6/5
                                                              AND modsplit.RAFactorType = b.PartCRAFTProjected
                                                              AND ModSplit.PaymentYear = @Payment_Year
            WHERE   b.SourceType IN ( 'RMMR', 'RAPS', 'RMOR', 'INT' )
                    AND  modsplit.SubmissionModel = 'RAPS' 
            GROUP BY B.HICN ,
                    b.PaymentYear ,
                    b.MYUFlag ,
                    B.PartCRAFTProjected ,
                    b.PartCRAFTMMR ,
                    B.ModelYear ,
                    ModSplit.ESRDDialysisFactor ,
                    ModSplit.SplitSegmentWeight ,
                    ModSplit.FunctioningGraftFactor ,
                    ModSplit.CodingIntensity ,
                    ModSplit.PartCNormalizationFactor ,
                    b.DateForFactors ,
                    B.HICN ,
                    b.DeleteFlag ,
                    b.PlanIdentifier 

    INSERT  INTO #RiskScoresPartC
            ( Planidentifier ,
              HICN ,
              PaymentYear ,
              MYUFlag ,
              PartCRAFTProjected ,
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
                    b.PartCRAFTProjected ,
                    CASE WHEN b.PartCRAFTProjected IN ( 'D', 'ED', 'G1', 'G2' )
                         THEN ROUND(( SUM(b.FactorHierarchy)
                                      / ModSplit.ESRDDialysisFactor ), 3)
                         WHEN b.PartCRAFTProjected IN ( 'C1', 'C2', 'I1', 'I2',
                                                        'E1', 'E2' )
                         THEN ROUND(ROUND(( SUM(b.FactorHierarchy)
                                            / ModSplit.FunctioningGraftFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                         WHEN b.PartCRAFTProjected <> b.PartCRAFTMMR
                         THEN ROUND(ROUND(ROUND(( SUM(DISTINCT B.FactorHierarchy)
                                                  / ModSplit.PartCNormalizationFactor ),
                                                3) * ( 1
                                                       - ModSplit.CodingIntensity ),
                                          3) * ModSplit.SplitSegmentWeight, 3)
                         WHEN b.PartCRAFTProjected IN ( 'C', 'E', 'I', 'CN',
                                                        'CP', 'CF' )--6/7
                              THEN ROUND(ROUND(ROUND(( SUM(B.FactorHierarchy)
                                                       / ModSplit.PartCNormalizationFactor ),
                                                     3) * ( 1
                                                            - ModSplit.CodingIntensity ),
                                               3)
                                         * ModSplit.SplitSegmentWeight, 3)
                         ELSE ROUND(ROUND(( SUM(B.FactorHierarchy)
                                            / ModSplit.PartCNormalizationFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                    END AS RiskScoreCalculate , --6/5
                    B.ModelYear ,
                    1 AS DeleteYN ,
                    b.DateForFactors ,
                    'EDS'
            FROM    etl.RiskScoreFactorsPartC b
                    LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC ModSplit ON ModSplit.ModelYear = B.ModelYear --6/5
                                                              AND modsplit.RAFactorType = b.PartCRAFTProjected
                                                              AND ModSplit.PaymentYear = @Payment_Year
            WHERE   b.SourceType IN ( 'EDS', 'EMMR', 'EMOR')
                     AND  modsplit.SubmissionModel = 'EDS' 
            GROUP BY B.HICN ,
                    b.PaymentYear ,
                    b.MYUFlag ,
                    B.PartCRAFTProjected ,
                    b.PartCRAFTMMR ,
                    B.ModelYear ,
                    ModSplit.ESRDDialysisFactor ,
                    ModSplit.SplitSegmentWeight ,
                    ModSplit.FunctioningGraftFactor ,
                    ModSplit.CodingIntensity ,
                    ModSplit.PartCNormalizationFactor ,
                    b.DateForFactors ,
                    B.HICN ,
                    b.DeleteFlag ,
                    b.PlanIdentifier 

/* DeleteYN = 0 means it includes deletes */  
/*******************************
RISKSCORE WITHOUT DELETES:
*******************************/
    INSERT  INTO #RiskScoresPartC
            ( Planidentifier ,
              HICN ,
              PaymentYear ,
              MYUFlag ,
              PartCRAFTProjected ,
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
                    b.PartCRAFTProjected ,
                    CASE WHEN b.PartCRAFTProjected IN ( 'D', 'ED', 'G1', 'G2' )
                         THEN ROUND(( SUM(b.FactorDeleteHierarchy)
                                      / ModSplit.ESRDDialysisFactor ), 3)
                         WHEN b.PartCRAFTProjected IN ( 'C1', 'C2', 'I1', 'I2',
                                                        'E1', 'E2' )
                         THEN ROUND(ROUND(( SUM(b.FactorDeleteHierarchy)
                                            / ModSplit.FunctioningGraftFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                         WHEN b.PartCRAFTProjected <> b.PartCRAFTMMR
                         THEN ROUND(ROUND(ROUND(( SUM(DISTINCT B.FactorDeleteHierarchy)
                                                  / ModSplit.PartCNormalizationFactor ),
                                                3) * ( 1
                                                       - ModSplit.CodingIntensity ),
                                          3) * ModSplit.SplitSegmentWeight, 3)
                         WHEN b.PartCRAFTProjected IN ( 'C', 'E', 'I', 'CN',
                                                        'CP', 'CF' ) --6/7
                              THEN ROUND(ROUND(ROUND(( SUM(B.FactorDeleteHierarchy)
                                                       / ModSplit.PartCNormalizationFactor ),
                                                     3) * ( 1
                                                            - ModSplit.CodingIntensity ),
                                               3)
                                         * ModSplit.SplitSegmentWeight, 3)
                         ELSE ROUND(ROUND(( SUM(B.FactorDeleteHierarchy)
                                            / ModSplit.PartCNormalizationFactor ),
                                          3) * ( 1 - ModSplit.CodingIntensity ),
                                    3)
                    END AS RiskScoreCalculate ,
                    B.ModelYear ,
                    0 AS DeleteYN ,
                    b.DateForFactors ,
                    'EDS'
            FROM    etl.RiskScoreFactorsPartC b
                    LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC ModSplit ON ModSplit.ModelYear = B.ModelYear --6/5
                                                              AND modsplit.RAFactorType = b.PartCRAFTProjected
                                                              AND ModSplit.PaymentYear = @Payment_Year
            WHERE   b.SourceType IN ( 'EDS', 'EMMR', 'EMOR')
                    AND  modsplit.SubmissionModel = 'EDS' 
            GROUP BY B.HICN ,
                    b.PaymentYear ,
                    b.MYUFlag ,
                    B.PartCRAFTProjected ,
                    b.PartCRAFTMMR ,
                    B.ModelYear ,
                    ModSplit.ESRDDialysisFactor ,
                    ModSplit.SplitSegmentWeight ,
                    ModSplit.FunctioningGraftFactor ,
                    ModSplit.CodingIntensity ,
                    ModSplit.PartCNormalizationFactor ,
                    b.DateForFactors ,
                    B.HICN ,
                    b.DeleteFlag ,
                    b.PlanIdentifier 
  
 TRUNCATE TABLE etl.[RiskScoresPartC]
        
    INSERT  INTO etl.RiskScoresPartC
            ( Planidentifier ,
              HICN ,
              PaymentYear ,
              MYUFlag ,
              PartCRAFTProjected ,
              RiskScoreCalculated ,
              ModelYear ,
              DeleteYN ,
              DateForFactors ,
              SourceType ,
              PartitionKey ,
              Populated
            )
            SELECT  Planidentifier ,
                    HICN ,
                    a.PaymentYear ,
                    a.MYUFlag ,
                    PartCRAFTProjected ,
                    RiskScoreCalculated  ,
                    ModelYear ,
                    DeleteYN ,
                    DateForFactors ,
                    a.SourceType ,
                    b.EstRecvPartitionKeyID ,
                    @populate_date
            FROM    #RiskScoresPartC a
                    JOIN [etl].[EstRecvPartitionKey] b ON a.PaymentYear = b.PaymentYear
                                                          AND b.MYU = a.MYUFlag  
														  and a.SourceType = b.SourceType                   
                                                         

SET @RowCount = @@ROWCOUNT;                          
                          
END
