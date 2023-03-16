/*******************************************************************************************************************************
* Name			:	rev.LoadPartCNewHCCRAPSEDSReconciliation
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   73695
* Date          :	10/28/2018
* Version		:	1.0
* Project		:	SP to load a summary table for Part C EDS vs RAPS reconciliation
* SP call		:	Exec rev.LoadPartCNewHCCRAPSEDSReconciliation 2017
* Version History :
  Author			Date		Version#	TFS Ticket#			Description
* -----------	   ----------	--------	-----------	       ------------ 
 D. Waddell	       07/01/19 	1.1		    TFS-76254		    RE-5243	modify the Part C RAPS and EDS reconciliation for the diagnosis 
																codes are the mapped to different HCCs in the same payment year under different model years.
 Anand             08/28/20     1.2      	RRI-32/79449	  	Used Etl tables Instead of temp tables.													 

*********************************************************************************************************************************/

CREATE PROCEDURE rev.LoadPartCNewHCCRAPSEDSReconciliation @PaymentYear SMALLINT
AS
BEGIN

    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @RowCount INT,
            @UserID VARCHAR(128) = SYSTEM_USER,
            @GetDate DATETIME = GETDATE();


    PRINT 'Loading data for ' + CAST(@PaymentYear AS VARCHAR(4));

     --Note: TFS 6254/RE-5243 6/19/2019 - Creating collection of HCCs for those PaymentYears that exhibit multiple Model Versions, where diag to HCC mapping changes from one version to the next.
    IF OBJECT_ID('tempdb..#HCCPreCurrentRef') IS NOT NULL
        DROP TABLE #HCCPreCurrentRef;

    CREATE TABLE [#HCCPreCurrentRef]
    (
        Payment_Year_Pre SMALLINT NULL,
        icd10cd VARCHAR(10) NULL,
        HCC_Label_Pre VARCHAR(10) NULL,
        factor_type VARCHAR(3) NULL,
        Payment_Year_Current SMALLINT  NULL,
        HCC_Label_Current VARCHAR(10) NULL
    );

    INSERT INTO [#HCCPreCurrentRef]
    (
        Payment_Year_Pre,
        icd10cd,
        HCC_Label_Pre,
        factor_type,
        Payment_Year_Current,
        HCC_Label_Current
    )
   SELECT a.Payment_Year Payment_Year_Pre,
           a.ICD10CD,
           a.HCC_Label AS HCC_Label_Pre,
           a.Factor_Type,
           b.Payment_Year AS Payment_Year_Current,
           b.HCC_Label AS HCC_Label_Current
    FROM [$(HRPReporting)].dbo.lk_Risk_Models_DiagHCC_ICD10 a
        JOIN [$(HRPReporting)].dbo.lk_Risk_Models_DiagHCC_ICD10 b
            ON a.ICD10CD = b.ICD10CD
        JOIN
        (
                    SELECT PaymentYear,
                           RAFactorType
                    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC c
                    GROUP BY PaymentYear,
                             RAFactorType
                    HAVING COUNT(DISTINCT ModelYear) > 1
      
        ) c
		   ON b.Payment_Year = c.PaymentYear
              AND b.Factor_Type = c.RAFactorType
		Join [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC d
		ON  c.PaymentYear = d.PaymentYear
           AND c.RAFactorType = d.RAFactorType
		   AND a.Payment_Year = d.ModelYear
    WHERE a.Factor_Type = b.Factor_Type      
		  AND a.HCC_Label <> b.HCC_Label
	      AND c.PaymentYear = @PaymentYear
    GROUP BY a.Payment_Year,
             a.ICD10CD,
             a.HCC_Label,
             a.Factor_Type,
             b.Payment_Year,
             b.HCC_Label;


    CREATE NONCLUSTERED INDEX [IX_#HCCPreCurrentRef_Payment_Year_Current]
    ON [#HCCPreCurrentRef] (
                               [HCC_Label_Pre],
                               [Payment_Year_Current]
                           );

IF (OBJECT_ID('[etl].[tbl_RAPSEDS_HCCDetails]') IS NOT NULL)

Truncate Table [etl].[tbl_RAPSEDS_HCCDetails];


    INSERT INTO [etl].[tbl_RAPSEDS_HCCDetails]
    (
        PaymentYear,
        PlanID,
        HICN,
        RAFactorType,
        HCC,
        HCCProcessedPCN,
        ProcessedPriorityProcessedByDate,
        ProcessedPriorityThruDate,
        ProcessedPriorityDiag,
        ProcessedPriorityFileID,
        ProcessedPriorityRAC,
        ProcessedPriorityRAPSSourceID,
        ProcessedPriorityICN,
        ProcessedPriorityEncounterID,
        ProcessedPriorityReplacementEncounterSwitch,
        ProcessedPriorityClaimID,
        ProcessedPrioritySecondaryClaimID,
        ProcessedPriorityRecordID,
        ProcessedPriorityVendorID,
        EncounterSource,
        Source,
        AnnualizedEstimatedValue,
        HCCPre,
        ModelYear
    )
    SELECT PaymentYear,
           PlanID,
           HICN,
           RAFactorType,                      --TFS 6254/RE-5243 6/19/2019
           HCC,
           HCCProcessedPCN,
           ProcessedPriorityProcessedByDate,
           ProcessedPriorityThruDate,
           ProcessedPriorityDiag,
           ProcessedPriorityFileID,
           ProcessedPriorityRAC,
           ProcessedPriorityRAPSSourceID,
           ProcessedPriorityICN,
           ProcessedPriorityEncounterID,
           ProcessedPriorityReplacementEncounterSwitch,
           ProcessedPriorityClaimID,
           ProcessedPrioritySecondaryClaimID,
           ProcessedPriorityRecordID,
           ProcessedPriorityVendorID,
           EncounterSource,
           CASE
               WHEN (
                        EncounterSource = 'RAPS'
                        AND ProcessedPriorityRAPSSourceID = 'Claims'
                    )
                    OR
                    (
                        EncounterSource = 'EDS'
                        AND ProcessedPriorityReplacementEncounterSwitch >= 1
                        AND ProcessedPriorityReplacementEncounterSwitch <= 3
                    ) THEN
                   'Claim'
               WHEN (
                        EncounterSource = 'RAPS'
                        AND ProcessedPriorityRAPSSourceID = 'QuickRAPS'
                    )
                    OR
                    (
                        EncounterSource = 'EDS'
                        AND ProcessedPriorityReplacementEncounterSwitch >= 4
                        AND ProcessedPriorityReplacementEncounterSwitch <= 9
                    ) THEN
                   'Supplemental'
               WHEN EncounterSource = 'RAPS'
                    AND ProcessedPriorityRAPSSourceID = 'Eligibility Recycle' THEN
                   'Eligibility Recycle'
               ELSE
                   'Other'
           END AS [Source],
           SUM(AnnualizedEstimatedValue) AS AnnualizedEstimatedValue,
           CAST('' AS VARCHAR(50)) AS HCCPre, --TFS 6254/RE-5243 6/19/2019 - Add for HCC comparison
           ModelYear                          --TFS 6254/RE-5243 6/19/2019 - Add for removing manual payment 2017

    FROM
    (
        SELECT PaymentYear,
               ProcessedByStartDate,
               ProcessedByEndDate,
               PlanID,
               HICN,
               RAFactorType, --TFS 6254/RE-5243 6/19/2019
               HCC,
               HCCProcessedPCN,
               ISNULL(
                         SUM(EstimatedValue) + (RollForwardMonths)
                         * (SUM(EstimatedValue) / COUNT(DISTINCT PaymentStartDate)),
                         0
                     ) AS AnnualizedEstimatedValue,
               ProcessedPriorityProcessedByDate,
               ProcessedPriorityThruDate,
               ProcessedPriorityDiag,
               ProcessedPriorityFileID,
               ProcessedPriorityRAC,
               ProcessedPriorityRAPSSourceID,
               EncounterSource,
               ProcessedPriorityICN,
               ProcessedPriorityEncounterID,
               ProcessedPriorityReplacementEncounterSwitch,
               ProcessedPriorityClaimID,
               ProcessedPrioritySecondaryClaimID,
               ProcessedPriorityRecordID,
               ProcessedPriorityVendorID,
               ModelYear     --TFS 6254/RE-5243 6/19/2019
        FROM rev.PartCNewHCCOutputMParameter
        WHERE PaymentYear = @PaymentYear
		GROUP BY PaymentYear,
                 ProcessedByStartDate,
                 ProcessedByEndDate,
                 PlanID,
                 HICN,
                 RAFactorType, --TFS 6254/RE-5243 6/19/2019
                 HCC,
                 HCCProcessedPCN,
                 RollForwardMonths,
                 ProcessedPriorityProcessedByDate,
                 ProcessedPriorityThruDate,
                 ProcessedPriorityDiag,
                 ProcessedPriorityFileID,
                 ProcessedPriorityRAC,
                 ProcessedPriorityRAPSSourceID,
                 EncounterSource,
                 ProcessedPriorityICN,
                 ProcessedPriorityEncounterID,
                 ProcessedPriorityReplacementEncounterSwitch,
                 ProcessedPriorityClaimID,
                 ProcessedPrioritySecondaryClaimID,
                 ProcessedPrioritySystemSource,
                 ProcessedPriorityRecordID,
                 ProcessedPriorityVendorID,
                 ModelYear     --TFS 6254/RE-5243 6/19/2019
    ) AS S
    GROUP BY PaymentYear,
             PlanID,
             HICN,
             RAFactorType, --TFS 6254/RE-5243 6/19/2019
             HCC,
             HCCProcessedPCN,
             ProcessedPriorityProcessedByDate,
             ProcessedPriorityThruDate,
             ProcessedPriorityDiag,
             ProcessedPriorityFileID,
             ProcessedPriorityRAC,
             ProcessedPriorityRAPSSourceID,
             ProcessedPriorityICN,
             ProcessedPriorityEncounterID,
             ProcessedPriorityReplacementEncounterSwitch,
             ProcessedPriorityClaimID,
             ProcessedPrioritySecondaryClaimID,
             ProcessedPriorityRecordID,
             ProcessedPriorityVendorID,
             EncounterSource,
             CASE
                 WHEN (
                          EncounterSource = 'RAPS'
                          AND ProcessedPriorityRAPSSourceID = 'Claims'
                      )
                      OR
                      (
                          EncounterSource = 'EDS'
                          AND ProcessedPriorityReplacementEncounterSwitch >= 1
                          AND ProcessedPriorityReplacementEncounterSwitch <= 3
                      ) THEN
                     'Claim'
                 WHEN (
                          EncounterSource = 'RAPS'
                          AND ProcessedPriorityRAPSSourceID = 'QuickRAPS'
                      )
                      OR
                      (
                          EncounterSource = 'EDS'
                          AND ProcessedPriorityReplacementEncounterSwitch >= 4
                          AND ProcessedPriorityReplacementEncounterSwitch <= 9
                      ) THEN
                     'Supplemental'
                 WHEN EncounterSource = 'RAPS'
                      AND ProcessedPriorityRAPSSourceID = 'Eligibility Recycle' THEN
                     'Eligibility Recycle'
                 ELSE
                     'Other'
             END,
             ModelYear;    --TFS 6254/RE-5243 6/19/2019

	Set @RowCount = @@ROWCOUNT;

    PRINT 'Data load completed for ' + CAST(@PaymentYear AS VARCHAR(4)) + ' with a count of : '
          + CAST(@RowCount AS VARCHAR(12));


    --TFS 6254/RE-5243 6/19/2019 - Update the HCCPre based on the reference table

    UPDATE a
    SET a.HCCPre = b.HCC_Label_Pre
    FROM [etl].[tbl_RAPSEDS_HCCDetails] a
        JOIN #HCCPreCurrentRef b
            ON RTRIM(a.ProcessedPriorityDiag) = RTRIM(b.icd10cd)
               AND a.PaymentYear = b.Payment_Year_Current
               AND a.RAFactorType = b.factor_type
    WHERE LEFT(a.HCC, 3) = 'hcc'
          AND a.HCC <> b.HCC_Label_Pre;


    INSERT INTO rev.PartCNewHCCRAPSEDSReconciliation
    (
        PaymentYear,
        HICN,
        HCC,
        HCCStatus,
        PlanID,
        RAPSPatientControlNumber,
        ProcessedByDate,
        ThruDate,
        DiagnosisCode,
        RAPSFileID,
        EDSICN,
        EDSEncounterID,
        EDSClaimID,
        EDSRecordID,
        EDSVendorID,
        EncounterSource,
        EncounterType,
        EncounterStatus,
        ICN,
        MAO004AllowedStatus,
        MAO004ServiceStartDate,
        MAO004ServiceEndDate,
        UserID,
        LoadDate
    )

    /* Insert records that are both in EDS and RAPS */

    SELECT DISTINCT
           RAPSEDS.PaymentYear,
           RAPSEDS.HICN,
           RAPSEDS.HCC,
           'InBothRAPSAndEDS' AS HCCStatus,
           RAPSEDS.PlanId,
           NULL AS RAPSPatientControlNumber,
           NULL AS ProcessedByDate,
           NULL AS ThruDate,
           NULL AS DiagnosisCode,
           NULL AS RAPSFileID,
           NULL AS EDSICN,
           NULL AS EDSEncounterID,
           NULL AS EDSClaimID,
           NULL AS EDSRecordID,
           NULL AS EDSVendorID,
           NULL AS EncounterSource,
           NULL AS EncounterType,
           NULL AS EncounterStatus,
           NULL AS ICN,
           NULL AS MAO004AllowedStatus,
           NULL AS MAO004ServiceStartDate,
           NULL AS MAO004ServiceEndDate,
           @UserID AS UserID,
           @GetDate AS LoadDate
    FROM
    (
        SELECT PaymentYear,
               HICN,
               HCC,
               MAX(PlanID) AS PlanId
        FROM [etl].[tbl_RAPSEDS_HCCDetails]
        WHERE HCC LIKE 'HCC%'
        GROUP BY PaymentYear,
                 HICN,
                 HCC
        HAVING COUNT(DISTINCT EncounterSource) >=2

    ) RAPSEDS

    UNION

    /* Insert records that are in RAPS but not in EDS */

    SELECT DISTINCT
		   HD.PaymentYear,
           HD.HICN,
           HD.HCC,
           'InRAPSButNotInEDS' AS HCCStatus,
           MAX(HD.PlanID) AS PlanID,
           HD.HCCProcessedPCN AS RAPSPatientControlNumber,
           HD.ProcessedPriorityProcessedByDate AS ProcessedByDate,
           HD.ProcessedPriorityThruDate AS ThruDate,
           HD.ProcessedPriorityDiag AS DiagnosisCode,
           HD.ProcessedPriorityFileID AS RAPSFileID,
           NULL AS EDSICN,
           NULL AS EDSEncounterID,
           NULL AS EDSClaimID,
           NULL AS EDSRecordID,
           NULL AS EDSVendorID,
           HD.EncounterSource,
           HD.[Source] AS EncounterType,
           NULL AS EncounterStatus,
           NULL AS ICN,
           NULL AS MAO004AllowedStatus,
           NULL AS MAO004ServiceStartDate,
           NULL AS MAO004ServiceEndDate,
           @UserID AS UserID,
           @GetDate AS LoadDate
    FROM [etl].[tbl_RAPSEDS_HCCDetails] HD
        LEFT JOIN
        (
           SELECT DISTINCT
                   a.PaymentYear,
                   a.HICN,
                   a.HCC,
				   b.HCC_DROP
            FROM [etl].[tbl_RAPSEDS_HCCDetails] a
                Left Join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy b
                    ON a.HCC = b.HCC_KEEP
                       AND b.Payment_Year = a.ModelYear
					   AND a.RAFactorType = b.RA_FACTOR_TYPE
            WHERE a.EncounterSource = 'EDS'
        ) b
            ON HD.PaymentYear = b.PaymentYear
               AND HD.HICN = b.HICN
               AND (HD.HCC = b.HCC or HD.hcc=b.HCC_DROP)
    WHERE HD.EncounterSource = 'RAPS'
          AND b.HICN IS NULL
          AND HD.HCC LIKE 'HCC%'
    GROUP BY HD.PaymentYear,
             HD.HICN,
             HD.HCC,
             HD.HCCProcessedPCN,
             HD.ProcessedPriorityProcessedByDate,
             HD.ProcessedPriorityThruDate,
             HD.ProcessedPriorityDiag,
             HD.ProcessedPriorityFileID,
             HD.EncounterSource,
             HD.[Source]
    UNION  

    /* Insert records that are in EDS but not in RAPS */

    SELECT DISTINCT
		   HD.PaymentYear,
           HD.HICN,
           HD.HCC,
           'InEDSButNotInRAPS' AS HCCStatus,
           MAX(HD.PlanID) AS PlanID,
           NULL AS RAPSPatientControlNumber,
           HD.ProcessedPriorityProcessedByDate AS ProcessedByDate,
           HD.ProcessedPriorityThruDate AS ThruDate,
           HD.ProcessedPriorityDiag AS DiagnosisCode,
           NULL AS RAPSFileID,
           HD.ProcessedPriorityICN AS EDSICN,
           HD.ProcessedPriorityEncounterID AS EDSEncounterID,
           HD.ProcessedPriorityClaimID AS EDSClaimID,
           HD.ProcessedPriorityRecordID AS EDSRecordID,
           HD.ProcessedPriorityVendorID AS EDSVendorID,
           HD.EncounterSource,
           HD.[Source] AS EncounterType,
           NULL AS EncounterStatus,
           NULL AS ICN,
           NULL AS MAO004AllowedStatus,
           NULL AS MAO004ServiceStartDate,
           NULL AS MAO004ServiceEndDate,
           @UserID AS UserID,
           @GetDate AS LoadDate
    FROM [etl].[tbl_RAPSEDS_HCCDetails] HD
        LEFT JOIN
        (
            SELECT DISTINCT
				   a.PaymentYear,	
                   a.HICN,
                   a.HCC,
				   b.hcc_drop
            FROM [etl].[tbl_RAPSEDS_HCCDetails] a
                Left Join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy b
                    ON a.HCC = b.HCC_KEEP
                       AND b.Payment_Year = a.ModelYear --TFS 6254/RE-5243 6/19/2019 - Remove hardcoded 2017 
                       AND a.RAFactorType = b.RA_FACTOR_TYPE --TFS 6254/RE-5243 6/19/2019 - Add RAFactorType on join condition
            WHERE EncounterSource = 'RAPS' 
        ) b
            ON HD.PaymentYear = b.PaymentYear
			   AND HD.HICN = b.HICN
               AND (HD.HCC = b.HCC or HD.hcc=b.HCC_DROP)
    WHERE HD.EncounterSource = 'EDS'
          AND b.HICN IS NULL
          AND HD.HCC LIKE 'HCC%'
    GROUP BY HD.PaymentYear,
             HD.HICN,
             HD.HCC,
             HD.ProcessedPriorityProcessedByDate,
             HD.ProcessedPriorityThruDate,
             HD.ProcessedPriorityDiag,
             HD.ProcessedPriorityICN,
             HD.ProcessedPriorityEncounterID,
             HD.ProcessedPriorityClaimID,
             HD.ProcessedPriorityRecordID,
             HD.ProcessedPriorityVendorID,
             HD.EncounterSource,
             HD.[Source];



    --TFS 6254/RE-5243 6/19/2019 
    --Update HCCStatus for different HCCs from multiple Model Versions that have the same diagnosis codes
    UPDATE a
    SET a.HCCStatus = 'InBothRAPSAndEDS',
        a.RAPSPatientControlNumber = NULL,
        a.ProcessedByDate = NULL,
        a.ThruDate = NULL,
        a.DiagnosisCode = NULL,
        a.RAPSFileID = NULL,
        a.EDSICN = NULL,
        a.EDSEncounterID = NULL,
        a.EDSClaimID = NULL,
        a.EDSRecordID = NULL,
        a.EDSVendorID = NULL,
        a.EncounterSource = NULL,
        a.EncounterType = NULL,
        a.EncounterStatus = NULL,
        a.ICN = NULL,
        a.MAO004AllowedStatus = NULL,
        a.MAO004ServiceStartDate = NULL,
        a.MAO004ServiceEndDate = NULL,
		a.UserID = @UserID,   
        a.LoadDate = @GetDate
    FROM rev.PartCNewHCCRAPSEDSReconciliation a
        JOIN
        (
               SELECT 
					   a.PaymentYear,
                       a.HICN,
                       a.HCC,
                       MAX(a.PlanID) AS PlanId
                    FROM [etl].[tbl_RAPSEDS_HCCDetails] a
                        JOIN [etl].[tbl_RAPSEDS_HCCDetails] b
                            ON a.HICN = b.HICN
                        JOIN #HCCPreCurrentRef c
                            ON a.HCC = c.HCC_Label_Current
                               AND b.HCCPre= c.HCC_Label_Pre
                    WHERE b.EncounterSource = 'EDS'
                          AND a.HCC <> a.HCCPre
						 And  a.HCC LIKE 'HCC%'
                GROUP BY a.PaymentYear,
                         a.HICN,
                         a.HCC
                ) b
            ON a.PaymentYear = b.PaymentYear
               AND a.HICN = b.HICN
               AND a.HCC = b.HCC
               AND a.PlanID = b.PlanId;

END;
 