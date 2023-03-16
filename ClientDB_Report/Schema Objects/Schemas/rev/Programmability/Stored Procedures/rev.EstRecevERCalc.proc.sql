CREATE   PROCEDURE [rev].[EstRecevERCalc]
    (
      @Payment_Year VARCHAR(4),
	  @RowCount INT OUT
    )
AS
    BEGIN

/************************************************************************        
* Name			:	rev.[EstRecevERCalc].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	04/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Estimated Receivables into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
64919        6/12/2017         Madhuri Suri        Risk Calc
65493        6/26              Madhuri Suri        Risk Score Matches to ER1
65564        6/29              Madhuri Suri        Populate EDS/RAPS Projected Risk Score
65872        7/19              Madhuri Suri        100 % Raps and EDS
75089        2/20/2019         Mahduri Suri        ER amount fix for HFHP found issue
RRI-34/79581 09/15/20          Anand               Add Row Count Output Parameter
***********************************************************************************************/  
  
       --DECLARE @Payment_Year VARCHAR(4) = 2016
        DECLARE @PaymentYear VARCHAR(4) = @Payment_Year
      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
      
              IF OBJECT_ID('Tempdb..#RISKSCOREEDSRAPS') IS NOT NULL
            DROP TABLE #RISKSCOREEDSRAPS
            
            
        CREATE TABLE #RISKSCOREEDSRAPS
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY
                     NOT NULL ,
              HICN VARCHAR(20) ,
              RAPSRS DECIMAL (10, 3) ,
              EDSRS DECIMAL (10, 3), 
              PartCRAFTProjected VARCHAR(4), 
              PlanID INT
            )
 INSERT INTO #RISKSCOREEDSRAPS
         (  HICN, RAPSRS, EDSRS, PartCRAFTProjected, PlanID )
 
				SELECT  HICN, 
			        RAPS, 
			        EDS, 
			        PartCRAFTProjected, 
			        Planidentifier
			FROM    ( SELECT DISTINCT
								HICN ,
								SourceType AS SourceType ,
								RiskScoreCalculated,
								PartCRAFTProjected, 
								Planidentifier
					  FROM      etl.RiskScoresPartC
					  WHERE DeleteYN = 1
					) src PIVOT
			( SUM(RiskScoreCalculated) FOR sourcetype IN ( EDS, RAPS ) ) piv;
        
        
        IF OBJECT_ID('Tempdb..#RISKSCOREEDSRAPSAfterDelete')  IS NOT NULL
            DROP TABLE #RISKSCOREEDSRAPSAfterDelete
            
            
        CREATE TABLE #RISKSCOREEDSRAPSAfterDelete
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY
                     NOT NULL ,
              HICN VARCHAR(20) ,
              RAPSRS DECIMAL (10, 3) ,
              EDSRS DECIMAL (10, 3),
              PartCRAFTProjected VARCHAR(4), 
              PlanID INT
            )
    INSERT INTO #RISKSCOREEDSRAPSAfterDelete
            (  HICN, RAPSRS, EDSRS, PartCRAFTProjected, PlanID  )
			SELECT  HICN, 
			        RAPS, 
			        EDS, 
			        PartCRAFTProjected, 
			        Planidentifier
			FROM    ( SELECT DISTINCT
								HICN ,
								SourceType AS SourceType ,
								RiskScoreCalculated,
								PartCRAFTProjected, 
								Planidentifier
					  FROM      etl.RiskScoresPartC
					  WHERE DeleteYN = 0
					) src PIVOT
			( SUM(RiskScoreCalculated) FOR sourcetype IN ( EDS, RAPS ) ) piv;
        
     
        IF OBJECT_ID('Tempdb..#RISKSCOREWITHDELETES_AGG') IS NOT NULL
            DROP TABLE #RISKSCOREWITHDELETES_AGG
 
      
        SELECT  A.HICN ,
                A.PartCRAFTProjected ,
                (A.riskScoreCalculated) * split.SubmissionSplitWeight RiskScoreAgg , --Test MS
                A.DateForFactors ,
                A.PlanIdentifier,
                A.SourceType
        INTO    #RISKSCOREWITHDELETES_AGG
        FROM    etl.[RiskScoresPartC] A
                    JOIN [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit split ON split.PaymentYear = a.PaymentYear
                                                              AND split.MYUFlag = a.MYUFlag
                                                              AND split.SubmissionModel = a.SourceType     
        WHERE   a.DeleteYN = 1
        GROUP BY A.HICN ,
                A.PartCRAFTProjected ,
                A.DateForFactors ,
                A.PlanIdentifier, 
                split.SubmissionSplitWeight, 
                a.RiskScoreCalculated,
                a.SourceType

----SELECT * FROM etl.[RiskScoresPartC] A

        IF OBJECT_ID('Tempdb..#RISKSCOREWITHOUTDELETES_AGG')  IS NOT NULL
         DROP TABLE #RISKSCOREWITHOUTDELETES_AGG
        SELECT  A.HICN ,
                A.PartCRAFTProjected ,
                 (A.riskScoreCalculated) * split.SubmissionSplitWeight RiskScoreAGG ,
                A.DateForFactors ,
                A.PlanIdentifier,
                A.SourceType
        INTO    #RISKSCOREWITHOUTDELETES_AGG
        FROM    etl.[RiskScoresPartC] A
         JOIN [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit split ON split.PaymentYear = a.PaymentYear
                                                              AND split.MYUFlag = a.MYUFlag
                                                              AND split.SubmissionModel = a.SourceType
        WHERE   a.DeleteYN = 0
        GROUP BY A.HICN ,
                A.PartCRAFTProjected ,
                A.DateForFactors ,
                A.PlanIdentifier, 
                split.SubmissionSplitWeight, 
                a.RiskScoreCalculated,
                A.SourceType
             
        
 

        UPDATE  etl.EstRecvDemoCalc
        SET     RiskScoreCalculated = ( ISNULL(RSD.RiskScoreAGG, 0) ) ,
                RiskScoreNewAfterDelete =  ( ISNULL(RSAD.RiskScoreAGG, 0) )--MS Test
        FROM    etl.EstRecvDemoCalc D
                LEFT JOIN ( SELECT  Sum( ISNULL(RSD.RiskScoreAGG, 0)) RiskScoreAGG, rsd.hicn , rsd.PartCRAFTProjected, rsd.Planidentifier FROM #RISKSCOREWITHDELETES_AGG rsd
                          GROUP BY rsd.hicn , rsd.PartCRAFTProjected, rsd.Planidentifier ) RSD ON RSD.HICN = D.HICN
                                                           AND ISNULL(D.PartCRAFTProjected,
                                                              1) = ISNULL(RSD.PartCRAFTProjected,
                                                              1) AND d.PlanID = rsd.Planidentifier
                LEFT JOIN  ( SELECT  Sum( ISNULL(RSD.RiskScoreAGG, 0)) RiskScoreAGG, rsd.hicn , rsd.PartCRAFTProjected, rsd.Planidentifier  FROM #RISKSCOREWITHOUTDELETES_AGG rsd
                          GROUP BY rsd.hicn , rsd.PartCRAFTProjected, rsd.Planidentifier )   RSAD ON RSAD.HICN = D.HICN
                                                              AND ISNULL(D.PartCRAFTProjected,
                                                              1) = ISNULL(RSAD.PartCRAFTProjected,
                                                          1) AND d.PlanID = rsad.Planidentifier

/*====RAFT NULL RISK SCORE NEW TO RISK SCORE OLD====*/
        UPDATE  etl.EstRecvDemoCalc
        SET     RiskScoreCalculated = PartCRiskScoreMMR
        FROM    etl.EstRecvDemoCalc a
                JOIN etl.EstRecvDemographics D ON a.HICN = d.HICN
                                                  AND a.PaymStart = d.PaymStart
        WHERE   a.PartCRAFTProjected IS NULL

/*===DIFF TO BE NULL FOR HOSP=====*/
        UPDATE  A
        SET     RSDifference = RiskScoreCalculated - RiskScoreMMR ,
                DifferenceAfterDelete = RiskScoreNewAfterDelete - RiskScoreMMR
        FROM    etl.EstRecvDemoCalc A
        WHERE   a.PartCRAFTProjected NOT IN ( 'HOSP', 'HP' )
        
        
        
        UPDATE  etl.EstRecvDemoCalc
        SET     ProjectedRiskScore = RiskScoreMMR
        WHERE   ISNULL(ProjectedRiskScore, 0) = 0
        UPDATE  etl.EstRecvDemoCalc
        SET     ProjectedRiskScoreAfterDelete = RiskScoreMMR
        WHERE   ISNULL(ProjectedRiskScoreAfterDelete, 0) = 0


  
       
		
        IF ( SELECT ISNULL(MAX(PayMonth), '011900')
             FROM   dbo.Converted_MOR_Data_rollup
             WHERE  LEFT(PayMonth, 4) = @PaymentYear--6/6
           ) >= ( SELECT DISTINCT
                            Paymonth
                  FROM      [$(HRPReporting)].dbo.lk_dcp_dates
                  WHERE     LEFT(paymonth, 4) = @PaymentYear
                            AND mid_year_update = 'Y'
                )
            BEGIN
---The following used if MYU MOR Exists
                UPDATE  etl.EstRecvDemoCalc
                SET     EstimatedRecvAmount = ( MABID * RSDifference )
                FROM    etl.EstRecvDemoCalc a
                WHERE   RSDifference > 0
                        AND A.PartCRAFTMMR <> 'HP'
                        AND A.PartCRAFTProjected NOT IN ( 'D', 'ED' )

                UPDATE  A
                SET     EstimatedRecvAmount = ( a.RSDifference * b.Rate )
                FROM    etl.EstRecvDemoCalc a
                        JOIN ( SELECT DISTINCT
                                        Paymo ,
                                        Code ,
                                        Rate
                               FROM     [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD
                               WHERE    PayMo = @PaymentYear
                             ) b ON a.SCC = b.Code
                WHERE   a.PartCRAFTProjected IN ( 'D', 'ED' )
                        AND a.RSDifference > 0
		
-- Calculate Estimated Receivables after Delete
                UPDATE  etl.EstRecvDemoCalc
                SET     EstimatedRecvAmountAfterDelete = ( a.MABID
                                                           * ( CASE
                                                              WHEN RSDifference < 0
                                                              THEN DifferenceAfterDelete
                                                              - RSDifference
                                                              ELSE DifferenceAfterDelete
                                                              END ) )
                FROM    etl.EstRecvDemoCalc a
                WHERE   ( DifferenceAfterDelete > 0
                          OR ( DifferenceAfterDelete < 0
                               AND DifferenceAfterDelete - RSDifference <> 0
                             )
                        )
                        AND a.PartCRAFTProjected <> 'HP'
                        AND a.PartCRAFTProjected NOT IN ( 'D', 'ED' )
		
                UPDATE  A
                SET     EstimatedRecvAmountAfterDelete = ( ( CASE
                                                              WHEN RSDifference < 0
                                                              THEN DifferenceAfterDelete
                                                              - RSDifference
                                                              ELSE DifferenceAfterDelete
                                                             END ) * b.Rate )
                FROM    etl.EstRecvDemoCalc a
                        JOIN ( SELECT DISTINCT
                                        Paymo ,
                                        Code ,
                                        Rate
                               FROM     [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD
                               WHERE    PayMo = @PaymentYear
                             ) b ON a.SCC = b.Code
                WHERE   a.PartCRAFTProjected IN ( 'D', 'ED' )
                        AND ( DifferenceAfterDelete > 0
                              OR ( DifferenceAfterDelete < 0
                                   AND DifferenceAfterDelete - RSDifference <> 0
                                 )
                            ) 
		
                UPDATE  etl.EstRecvDemoCalc
                SET     AmountDeleted = -1 * ( EstimatedRecvAmount
                                               - EstimatedRecvAmountAfterDelete )
                                       
                                       
                                       
                                       
                                       
        
                UPDATE  etl.EstRecvDemoCalc
                SET     ProjectedRiskScore = RiskScoreCalculated
                FROM    etl.EstRecvDemoCalc a
                WHERE   RSDifference <> 0
        
                UPDATE  etl.EstRecvDemoCalc
                SET     ProjectedRiskScoreAfterDelete = CASE WHEN RSDifference < 0
                                                             THEN RiskScoreNewAfterDelete
                                                              - RSDifference
                                                             ELSE RiskScoreNewAfterDelete
                                                        END
                WHERE   ( DifferenceAfterDelete > 0
                          OR ( DifferenceAfterDelete < 0
                               AND DifferenceAfterDelete - RSDifference <> 0
                             )
                        )       
                        
                        
                        
                                            

            END 



        IF ( SELECT ISNULL(MAX(PayMonth), '011900')
             FROM   dbo.Converted_MOR_Data_rollup
             WHERE  LEFT(PayMonth, 4) = @PaymentYear --6/6
           ) < ( SELECT DISTINCT
                        Paymonth
                 FROM   [$(HRPReporting)].dbo.lk_dcp_dates
                 WHERE  LEFT(paymonth, 4) = @PaymentYear
                        AND mid_year_update = 'Y'
               )
            BEGIN
                UPDATE  etl.EstRecvDemoCalc
                SET     EstimatedRecvAmount = ( a.MABID * RSDifference )
                FROM    etl.EstRecvDemoCalc a
                WHERE   a.PartCRAFTProjected NOT IN ( 'D', 'ED', 'HP' )

                UPDATE  A
                SET     EstimatedRecvAmount = ( a.RSDifference * b.Rate )
                FROM    etl.EstRecvDemoCalc a
                        JOIN ( SELECT DISTINCT
                                        Paymo ,
                                        Code ,
                                        Rate
                               FROM     [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD
                               WHERE    PayMo = @PaymentYear
                             ) b ON a.SCC = b.Code
                WHERE   a.PartCRAFTProjected IN ( 'D', 'ED' )

                UPDATE  a
                SET     EstimatedRecvAmount = ( MABID * RSDifference )
                FROM    etl.EstRecvDemoCalc a
                WHERE   a.PartCRAFTProjected NOT IN ( 'D', 'ED', 'HP' )

                UPDATE  a
                SET     EstimatedRecvAmountAfterDelete = ( MABID
                                                           * DifferenceAfterDelete )
                FROM    etl.EstRecvDemoCalc a
                WHERE   a.PartCRAFTProjected NOT IN ( 'D', 'ED', 'HP' ) 

                UPDATE  A
                SET     EstimatedRecvAmountAfterDelete = ( a.DifferenceAfterDelete
                                                           * b.Rate )
                FROM    etl.EstRecvDemoCalc a
                        JOIN ( SELECT DISTINCT
                                        Paymo ,
                                        Code ,
                                        Rate
                               FROM     [$(HRPReporting)].dbo.lk_RATEBOOK_ESRD
                               WHERE    PayMo = @PaymentYear
                             ) b ON a.SCC = b.Code
                WHERE   a.PartCRAFTProjected IN ( 'D', 'ED' )

                UPDATE  etl.EstRecvDemoCalc
                SET     AmountDeleted = EstimatedRecvAmount
                        - EstimatedRecvAmountAfterDelete
                
                
                UPDATE  etl.EstRecvDemoCalc
                SET     ProjectedRiskScore = RiskScoreCalculated
                WHERE   RSDifference <> 0
                UPDATE  etl.EstRecvDemoCalc
                SET     ProjectedRiskScoreAfterDelete = RiskScoreNewAfterDelete
                WHERE   DifferenceAfterDelete <> 0
                
                
            END

		

        INSERT  INTO [etl].[EstRecvDetailPartC]
                ( [HPlanID] ,
                  [PaymentYear] ,
                  [MYUFlag] ,
                  [DateForFactors] ,
                  [HICN] ,
                  [PayStart] ,
                  [RAFTRestated] ,
                  [RAFTMMR] ,
                  [Agegrp] ,
                  [Sex] ,
                  [Medicaid] ,
                  [ORECRestated] ,
                  [MAXMOR] ,
                  [MidYearUpdateFlag] ,
                  [AgeGroupID] ,
                  [GenderID] ,
                  [SCC] ,
                  [PBP] ,
                  [Bid] ,
                  [NewEnrolleeFlagError] ,
                  [MonthsInDCP] ,
                  [ISARUsed] ,
                  [RiskScoreCalculated] ,
                  [RiskScoreMMR] ,
                  [RSDifference] ,
                  [EstimatedRecvAmount] ,
                  [ProjectedRiskScore] ,
                  [EstimatedRecvAmountAfterDelete] ,
                  [AmountDeleted] ,
                  [RiskScoreNewAfterDelete] ,
                  [DifferenceAfterDelete] ,
                  [ProjectedRiskScoreAfterDelete] ,
                  [MemberMonth] ,
                  [ActualFinalPaid] ,
                  [MARiskRevenue_A_B] ,
                  [MARiskRevenueRecalc] ,
                  [MARiskRevenueVariance] ,
                  [TotalPremiumYTD] ,
                  [MidYearUpdateActual] ,
                  [Populated] ,
                  [ESRD] ,
                  [DefaultInd] ,
                  [PlanIdentifier] ,
                  [AgedStatus] ,
                  [SourceType] ,
                  [PartitionKey], 
                  [RAPSProjectedRiskScore],
                  [RAPSProjectedRiskScoreAfterDelete],
                  [EDSProjectedRiskScore],
                  [EDSProjectedRiskScoreAfterDelete]
                )
                SELECT  rp.PlanID ,
                        a.PaymentYear ,
                        a.MYUFlag ,
                        a.DateForFactors ,
                        a.HICN ,
                        a.PaymStart ,
                        a.PartCRAFTProjected ,
                        a.PartCRAFTMMR ,
                        a.RskAdjAgeGrp ,
                        CASE WHEN a.Gender = '1' THEN 'M'
                             WHEN a.Gender = '2' THEN 'F'
                        END AS Sex ,
                        a.MedicaidRestated ,
                        a.ORECRestated ,
                        b.MaxMOR ,
                        a.MidYearUpdateFlag ,
                        a.AgeGrpID ,
                        a.Gender AS GenderID ,
                        a.SCC ,
                        a.PBP ,
                        a.MABID ,
                        b.NewEnrolleeFlagError ,
                        a.MonthsInDCP ,
                        a.ISARUsed ,
                        b.RiskScoreCalculated ,
                        a.PartCRiskScoreMMR ,
                        b.RSDifference ,
                        b.EstimatedRecvAmount ,
                        b.ProjectedRiskScore ,
                        b.EstimatedRecvAmountAfterDelete ,
                        b.AmountDeleted ,
                        b.RiskScoreNewAfterDelete ,
                        b.DifferenceAfterDelete ,
                        b.ProjectedRiskScoreAfterDelete ,
                        '1' ,
                        b.ActualFinalPaid ,
                        a.MARiskRevenue_A_B ,
                        b.MARiskRevenueRecalc ,
                        b.MARiskRevenueVariance ,
                        a.TotalPremiumYTD ,
                        a.MidYearUpdateActual ,
                        GETDATE() ,
                        a.ESRD ,
                        a.PartCDefaultIndicator ,
                        a.PlanID ,
                        b.AgedStatus ,
                        a.SourceType ,
                        a.PartitionKey,
                        rs.RAPSRS RAPSProjectedRS, 
                        rsad.RAPSRS RAPSProjectedRSAD,
                        rs.EDSRS EDSProjectedRS,
                        rsad.EDSRS EDSProjectedRSAD
                        
                FROM    etl.EstRecvDemographics a
                        JOIN etl.EstRecvDemoCalc b ON a.HICN = b.HICN
                                                      AND a.PaymStart = b.PaymStart
                        LEFT JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp ON rp.PlanIdentifier = a.PlanID 
                        LEFT JOIN #RISKSCOREEDSRAPS rs ON rs.HICN = a.HICN AND rs.PartCRAFTProjected = a.PartCRAFTProjected                     
						                                                   AND rs.PlanID = a.PlanID
                        
                        LEFT JOIN #RISKSCOREEDSRAPSAfterDelete rsad ON rsad.HICN = a.HICN AND rsad.PartCRAFTProjected = a.PartCRAFTProjected
						                                                   AND rs.PlanID = a.PlanID

SET @RowCount = @@ROWCOUNT;


		  UPDATE    a
          SET       a.LastAssignedHICN = ISNULL(b.LastAssignedHICN,
                                                CASE WHEN ssnri.fnValidateMBI(a.HICN) = 1
                                                     THEN B.HICN
                                                END)
          FROM      [etl].[EstRecvDetailPartC] a
                    CROSS APPLY ( SELECT TOP 1
                                            b.LastAssignedHICN , b.HICN 
                                  FROM      rev.tbl_Summary_RskAdj_AltHICN AS b
                                  WHERE     b.FINALHICN = a.HICN
                                  ORDER BY  LoadDateTime DESC
                                ) AS b

    
    
       
    END