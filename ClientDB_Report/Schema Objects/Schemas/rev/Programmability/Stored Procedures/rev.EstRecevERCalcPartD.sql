CREATE   PROCEDURE [rev].[EstRecevERCalcPartD]
    (
      @Payment_Year VARCHAR(4),
	  @RowCount INT OUT
    )
AS
    BEGIN
/************************************************************************        
* Name			:	rev.[EstRecevERCalcPartD].proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	12/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates Estimated Receivables into etl ER tables	*

***************************************************************************/   
/********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
75091        3/4/2019         Madhuri Suri         Part D Corrections
75807    5/1/2019     Madhuri Suri      Part D Corrections for ER 2.0
RRI-229/79617 9/22/2020 Anand          Add Row Count Out Parameter
***********************************************************************************************/  
  
      --- DECLARE @Payment_Year VARCHAR(4) = 2018
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
              RAPSRS DECIMAL(10, 3) ,
              EDSRS DECIMAL(10, 3) ,
              PartDRAFTProjected VARCHAR(4) ,
              PlanID INT
            )
        INSERT  INTO #RISKSCOREEDSRAPS
                ( HICN ,
                  RAPSRS ,
                  EDSRS ,
                  PartDRAFTProjected ,
                  PlanID
                )
                SELECT  HICN ,
                        RAPS ,
                        EDS ,
                        PartDRAFTProjected ,
                        Planidentifier
                FROM    ( SELECT DISTINCT
                                    HICN ,
                                    SourceType AS SourceType ,
                                    RiskScoreCalculated ,
                                    PartDRAFTProjected ,
                                    Planidentifier
                          FROM      etl.RiskScoresPartD
                          WHERE     DeleteYN = 1
                        ) src PIVOT
			( SUM(RiskScoreCalculated) FOR sourcetype IN ( EDS, RAPS ) ) piv;
        
        
        IF OBJECT_ID('Tempdb..#RISKSCOREEDSRAPSAfterDelete') IS NOT NULL
            DROP TABLE #RISKSCOREEDSRAPSAfterDelete
            
            
        CREATE TABLE #RISKSCOREEDSRAPSAfterDelete
            (
              ID INT IDENTITY(1, 1)
                     PRIMARY KEY
                     NOT NULL ,
              HICN VARCHAR(20) ,
              RAPSRS DECIMAL(10, 3) ,
              EDSRS DECIMAL(10, 3) ,
              PartDRAFTProjected VARCHAR(4) ,
              PlanID INT
            )
        INSERT  INTO #RISKSCOREEDSRAPSAfterDelete
                ( HICN ,
                  RAPSRS ,
                  EDSRS ,
                  PartDRAFTProjected ,
                  PlanID
                )
                SELECT  HICN ,
                        RAPS ,
                        EDS ,
                        PartDRAFTProjected ,
                        Planidentifier
                FROM    ( SELECT DISTINCT
                                    HICN ,
                                    SourceType AS SourceType ,
                                    RiskScoreCalculated ,
                                    PartDRAFTProjected ,
                                    Planidentifier
                          FROM      etl.RiskScoresPartD
                          WHERE     DeleteYN = 0
                        ) src PIVOT
			( SUM(RiskScoreCalculated) FOR sourcetype IN ( EDS, RAPS ) ) piv;
        
        
        IF OBJECT_ID('Tempdb..#RISKSCOREWITHDELETES_AGG') IS NOT NULL
            DROP TABLE #RISKSCOREWITHDELETES_AGG
 
      
        SELECT  A.HICN ,
                A.PartDRAFTProjected ,
                ( A.RiskScoreCalculated ) * split.SubmissionSplitWeight RiskScoreAgg , --Test MS
                A.DateForFactors ,
                A.PlanIdentifier, 
                a.SourceType
        INTO    #RISKSCOREWITHDELETES_AGG
        FROM    etl.[RiskScoresPartD] A
                JOIN [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit split ON split.PaymentYear = a.PaymentYear
                                                              AND split.MYUFlag = a.MYUFlag
                                                              AND split.SubmissionModel = a.SourceType
        WHERE   a.DeleteYN = 1
        GROUP BY A.HICN ,
                A.PartDRAFTProjected ,
                A.DateForFactors ,
                A.PlanIdentifier ,
                split.SubmissionSplitWeight ,
                a.RiskScoreCalculated, 
                a.SourceType


        IF OBJECT_ID('Tempdb..#RISKSCOREWITHOUTDELETES_AGG') IS NOT NULL
            DROP TABLE #RISKSCOREWITHOUTDELETES_AGG
        
        SELECT  A.HICN ,
                A.PartDRAFTProjected ,
                ( A.riskScoreCalculated ) * split.SubmissionSplitWeight RiskScoreAGG ,
                A.DateForFactors ,
                A.PlanIdentifier,
                a.SourceType
        INTO    #RISKSCOREWITHOUTDELETES_AGG
        FROM    etl.[RiskScoresPartD] A
                JOIN [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit split ON split.PaymentYear = a.PaymentYear
                                                              AND split.MYUFlag = a.MYUFlag
                                                              AND split.SubmissionModel = a.SourceType
        WHERE   a.DeleteYN = 0
        GROUP BY A.HICN ,
                A.PartDRAFTProjected ,
                A.DateForFactors ,
                A.PlanIdentifier ,
                split.SubmissionSplitWeight ,
                a.RiskScoreCalculated,
                a.SourceType
          
        

        UPDATE  etl.EstRecvDemoCalcPartD
        SET     RiskScoreCalculated = ( ISNULL(RSD.RiskScoreAGG, 0) ) ,
                RiskScoreNewAfterDelete = ( ISNULL(RSAD.RiskScoreAGG, 0) )--MS Test
        FROM    etl.EstRecvDemoCalcPartD D
                LEFT JOIN ( SELECT  SUM(ISNULL(RSD.RiskScoreAGG, 0)) RiskScoreAGG ,
                                    rsd.hicn ,
                                    rsd.PartDRAFTProjected ,
                                    rsd.Planidentifier, 
									rsd.DateForFactors
                            FROM    #RISKSCOREWITHDELETES_AGG rsd
                            GROUP BY rsd.hicn ,
                                    rsd.PartDRAFTProjected ,
                                    rsd.Planidentifier,
									rsd.DateForFactors
                          ) RSD ON RSD.HICN = D.HICN
                                   AND ISNULL(D.PartDRAFTProjected, 1) = ISNULL(RSD.PartDRAFTProjected,
                                                              1)
                                   AND d.PlanID = rsd.Planidentifier
								   and d.DateForFactors = rsd.DateForFactors --02062019
                LEFT JOIN ( SELECT  SUM(ISNULL(RSD.RiskScoreAGG, 0)) RiskScoreAGG ,
                                    rsd.hicn ,
                                    rsd.PartDRAFTProjected ,
                                    rsd.Planidentifier,
									rsd.DateForFactors
                            FROM    #RISKSCOREWITHOUTDELETES_AGG rsd
                            GROUP BY rsd.hicn ,
                                    rsd.PartDRAFTProjected ,
                                    rsd.Planidentifier,
									rsd.DateForFactors
                          ) RSAD ON RSAD.HICN = D.HICN
                                    AND ISNULL(D.PartDRAFTProjected, 1) = ISNULL(RSAD.PartDRAFTProjected,
                                                              1)
                                    AND d.PlanID = rsad.Planidentifier
									and d.DateForFactors = rsad.DateForFactors --02062019

/*====RAFT NULL RISK SCORE NEW TO RISK SCORE OLD====*/
        UPDATE  etl.EstRecvDemoCalcPartD
        SET     RiskScoreCalculated = RiskScoreMMR
        FROM    etl.EstRecvDemoCalcPartD a
                JOIN etl.EstRecvDemographicsPartD D ON a.HICN = d.HICN
                                                       AND a.PaymStart = d.PaymStart
        WHERE   a.PartDRAFTProjected IS NULL

       
        UPDATE  etl.EstRecvDemoCalcPartD
        SET     RiskScoreCalculated = RiskScoreMMR
        FROM    etl.EstRecvDemoCalcPartD a
                JOIN etl.EstRecvDemographicsPartD D ON a.HICN = d.HICN
                                                       AND a.PaymStart = d.PaymStart
        WHERE   a.RiskScoreCalculated IS NULL

/*===DIFF TO BE NULL FOR HOSP=====*/
        UPDATE  A
        SET     RSDifference = RiskScoreCalculated - RiskScoreMMR ,
                DifferenceAfterDelete = RiskScoreNewAfterDelete - RiskScoreMMR
        FROM    etl.EstRecvDemoCalcPartD A
        WHERE   a.PartDRAFTProjected NOT IN ( 'HOSP', 'HP' )
        
        
        
        UPDATE  etl.EstRecvDemoCalcPartD
        SET     ProjectedRiskScore = RiskScoreMMR
        WHERE   ISNULL(ProjectedRiskScore, 0) = 0

        UPDATE   etl.EstRecvDemoCalcPartD
        SET     ProjectedRiskScoreAfterDelete = RiskScoreMMR
        WHERE   ISNULL(ProjectedRiskScoreAfterDelete, 0) = 0
		
      
       --kp 12/20 determine which members do not have low income indicator - part d ra factor type = D2    
   IF @Payment_Year >= 2011    
   BEGIN    
    IF OBJECT_ID('[tempdb].[dbo].[#non_low_income]', 'U') IS NOT NULL DROP TABLE #non_low_income    
    CREATE TABLE #non_low_income    
    (hicn VARCHAR(20))    
        
    CREATE CLUSTERED INDEX non_low_income ON #non_low_income (HICN)    
        
    INSERT INTO #non_low_income    
    SELECT DISTINCT hicn    
    FROM etl.EstRecvDemographicsPartD d
    WHERE (isnull(d.PartDLowIncomeIndicator,'0') = '0') --or PartDLowIncomeIndicator = 'N')    
    AND LowIncomeMultiplier = 0     --(Using this column LowIncomeMultiplier to populate LowIncomePremiumSubsidy from Summary MMR table tomaintain the logic)
    AND PaymStart BETWEEN '1/1/' + @Payment_Year AND '12/31/' + @Payment_Year 
          
     --- added new update statements to account for new ra factor types beginning in PY 2011    
     UPDATE results    
     SET results.PartDRAFTProjected = 'D2'     
     FROM etl.EstRecvDemoCalcPartD results   
     JOIN etl.EstRecvDemographicsPartD d on results.HICN = d.HICN
                                             AND results.PaymentYear = d.PaymentYear 
                                             AND results.PartDRAFTProjected = d.PartDRAFTProjected
                                             AND results.DateForFactors = d.DateForFactors
                                             AND d.MonthRow = 1
     WHERE results.PartDRAFTProjected in ('D4','D5','D6','D7','D8','D9') AND d.MonthsInDCP = '12' AND @Payment_Year >= 2011    
     AND NOT EXISTS (SELECT 1 FROM #non_low_income low WHERE results.HICN = low.hicn)    
    
     UPDATE results    
     SET results.PartDRAFTProjected = 'D1'     
     FROM etl.EstRecvDemoCalcPartD results   
     JOIN etl.EstRecvDemographicsPartD d on results.HICN = d.HICN
                                             AND results.PaymentYear = d.PaymentYear 
                                             AND results.PartDRAFTProjected = d.PartDRAFTProjected
                                             AND results.DateForFactors = d.DateForFactors
                                             AND d.MonthRow = 1  
     WHERE results.PartDRAFTProjected in ('D4','D5','D6','D7','D8','D9') and d.MonthsInDCP = '12' and @Payment_Year >= 2011    
     AND EXISTS (SELECT 1 FROM #non_low_income low WHERE results.HICN = low.hicn)    
    END    
    
		

        IF ( SELECT ISNULL(MAX(Payment_Month), '011900')
             FROM   dbo.Converted_MORD_Data_rollup
             WHERE  LEFT(Payment_Month, 4) = @PaymentYear
           ) >= ( SELECT DISTINCT
                            Paymonth
                  FROM      [$(HRPReporting)].dbo.lk_dcp_dates
                  WHERE     LEFT(paymonth, 4) = @PaymentYear
                            AND mid_year_update = 'Y'
                )
            BEGIN
---The following used if MYU MOR Exists
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     EstimatedRecvAmount = ( MABID * RSDifference )
               FROM    etl.EstRecvDemoCalcPartD a
                WHERE   RSDifference > 0.005  
			            AND NewEnrolleeFlagError IS NULL
                        AND A.PartDRAFTMMR <> 'HP'
                        --AND A.PartDRAFTProjected NOT IN ( 'D', 'ED' )

             		
-- Calculate Estimated Receivables after Delete
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     EstimatedRecvAmountAfterDelete = ( a.MABID
                                                           * DifferenceAfterDelete)
                FROM    etl.EstRecvDemoCalcPartD a
                WHERE   RSDifference >0.005 --02062019
				AND NewEnrolleeFlagError IS NULL
                    
		
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     AmountDeleted =  ( EstimatedRecvAmount
                                               - EstimatedRecvAmountAfterDelete ) --02062019



                
				UPDATE  etl.EstRecvDemoCalcPartD
				SET     ProjectedRiskScore = RiskScoreCalculated
				WHERE   RSDifference >0.005 --02062019
					  AND NewEnrolleeFlagError IS NULL

				UPDATE  etl.EstRecvDemoCalcPartD
				SET     ProjectedRiskScoreAfterDelete = RiskScoreCalculated
				WHERE   RSDifference >0.005
				AND NewEnrolleeFlagError IS NULL

                                       
                END 
                
		---02062019 added for without MOR		
				 IF ( SELECT ISNULL(MAX(Payment_Month), '011900')
             FROM   dbo.Converted_MORD_Data_rollup
             WHERE  LEFT(Payment_Month, 4) = @PaymentYear
           ) < ( SELECT DISTINCT
                            Paymonth
                  FROM      [$(HRPReporting)].dbo.lk_dcp_dates
                  WHERE     LEFT(paymonth, 4) = @PaymentYear
                            AND mid_year_update = 'Y'
                )
            BEGIN
			---The following used if MYU MOR not Exists
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     EstimatedRecvAmount = ( MABID * RSDifference )
                FROM    etl.EstRecvDemoCalcPartD a
                WHERE   (RSDifference NOT BETWEEN -0.005 AND  0.005  )
				       AND NewEnrolleeFlagError IS NULL --MSTEST
                        AND A.PartDRAFTMMR <> 'HP'
                        --AND A.PartDRAFTProjected NOT IN ( 'D', 'ED' )

             		
-- Calculate Estimated Receivables after Delete
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     EstimatedRecvAmountAfterDelete = ( a.MABID
                                                           * DifferenceAfterDelete)
                FROM    etl.EstRecvDemoCalcPartD a
                WHERE   (RSDifference NOT BETWEEN -0.005 AND  0.005  ) 
				       AND NewEnrolleeFlagError IS NULL--02062019
                    
		
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     AmountDeleted =  ( EstimatedRecvAmount
                                               - EstimatedRecvAmountAfterDelete ) --02062019



                    
        UPDATE  etl.EstRecvDemoCalcPartD
        SET     ProjectedRiskScore = RiskScoreCalculated
        WHERE   (RSDifference NOT BETWEEN -0.005 AND  0.005  ) --02062019
		      AND NewEnrolleeFlagError IS NULL

        UPDATE  etl.EstRecvDemoCalcPartD
        SET     ProjectedRiskScoreAfterDelete = RiskScoreCalculated
        WHERE  (RSDifference NOT BETWEEN -0.005 AND  0.005  ) 
		AND NewEnrolleeFlagError IS NULL

											   
	END 	      
        
                                                     

         


        IF ( SELECT ISNULL(MAX(Payment_Month), '011900')
             FROM   dbo.Converted_MORD_Data_rollup
             WHERE  LEFT(Payment_Month, 4) = @PaymentYear --6/6
           ) < ( SELECT DISTINCT
                        Paymonth
                 FROM   [$(HRPReporting)].dbo.lk_dcp_dates
                 WHERE  LEFT(paymonth, 4) = @PaymentYear
                        AND mid_year_update = 'Y'
               )
            BEGIN
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     EstimatedRecvAmount = ( a.MABID * RSDifference )
                FROM    etl.EstRecvDemoCalcPartD a
                WHERE   a.PartDRAFTProjected NOT IN ( 'D', 'ED', 'HP' )


                UPDATE  a
                SET     EstimatedRecvAmount = ( MABID * RSDifference )
                FROM    etl.EstRecvDemoCalcPartD a
                WHERE   a.PartDRAFTProjected NOT IN ( 'HP' )

                UPDATE  a
                SET     EstimatedRecvAmountAfterDelete = ( MABID
                                                           * DifferenceAfterDelete )
                FROM    etl.EstRecvDemoCalcPartD a
                WHERE   a.PartDRAFTProjected NOT IN ( 'HP' ) 


                UPDATE  etl.EstRecvDemoCalcPartD
                SET     AmountDeleted = EstimatedRecvAmount
                        - EstimatedRecvAmountAfterDelete
                
                
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     ProjectedRiskScore = RiskScoreCalculated
                WHERE   RSDifference <> 0
                UPDATE  etl.EstRecvDemoCalcPartD
                SET     ProjectedRiskScoreAfterDelete = RiskScoreNewAfterDelete
                WHERE   DifferenceAfterDelete <> 0
                
                
            END

		

        INSERT  INTO [etl].[EstRecvDetailPartD]
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
                  [MARiskRevenueRecalc] ,
                  [MARiskRevenueVariance] ,
                  [TotalPremiumYTD] ,
                  [MidYearUpdateActual] ,
                  [PlanIdentifier] ,
                  [AgedStatus] ,
                  [SourceType] ,
                  [PartitionKey] ,
                  [RAPSProjectedRiskScore] ,
                  [RAPSProjectedRiskScoreAfterDelete] ,
                  [EDSProjectedRiskScore] ,
                  [EDSProjectedRiskScoreAfterDelete] ,
                  [LoadDate] ,
                  [UserID]
                )
                SELECT  a.HPlanID ,
                        a.PaymentYear ,
                        a.MYUFlag ,
                        a.DateForFactors ,
                        a.HICN ,
                        a.PaymStart ,
                        a.PartDRAFTProjected ,
                        a.PartDRAFTMMR ,
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
                        b.MABID ,
                        b.NewEnrolleeFlagError ,
                        a.MonthsInDCP ,
                        a.ISARUsed ,
                        b.RiskScoreCalculated ,
                        a.PartDRiskScoreMMR ,
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
                        b.MARiskRevenueRecalc ,
                        b.MARiskRevenueVariance ,
                        a.TotalPremiumYTD ,
                        a.MidYearUpdateActual ,
                        a.PlanIdentifier ,
                        b.AgedStatus ,
                        a.SourceType ,
                        a.PartitionKey ,
                        rs.RAPSRS RAPSProjectedRS ,
                        rsad.RAPSRS RAPSProjectedRSAD ,
                        rs.EDSRS EDSProjectedRS ,
                        rsad.EDSRS EDSProjectedRSAD ,
                        GETDATE() ,
                        USER_ID()
                FROM    etl.EstRecvDemographicsPartD a
                        JOIN etl.EstRecvDemoCalcPartD b ON a.HICN = b.HICN
                                                           AND a.PaymStart = b.PaymStart
                        LEFT JOIN #RISKSCOREEDSRAPS rs ON rs.HICN = a.HICN
                                                          AND rs.PartDRAFTProjected = a.PartDRAFTProjected
                                                          AND rs.PlanID = a.PlanIdentifier
                        LEFT JOIN #RISKSCOREEDSRAPSAfterDelete rsad ON rsad.HICN = a.HICN
                                                              AND rsad.PartDRAFTProjected = a.PartDRAFTProjected
                                                              AND rs.PlanID = a.PlanIdentifier
       
SET @RowCount = Isnull(@@ROWCOUNT,0);    
	
	  UPDATE    a
          SET       a.LastAssignedHICN = ISNULL(b.LastAssignedHICN,
                                                CASE WHEN ssnri.fnValidateMBI(a.HICN) = 1
                                                     THEN B.HICN
                                                END)
          FROM      [etl].[EstRecvDetailPartD] a
                    CROSS APPLY ( SELECT TOP 1
                                            b.LastAssignedHICN , b.HICN 
                                  FROM      rev.tbl_Summary_RskAdj_AltHICN AS b
                                  WHERE     b.FINALHICN = a.HICN
                                  ORDER BY  LoadDateTime DESC
                                ) AS b

	

	END