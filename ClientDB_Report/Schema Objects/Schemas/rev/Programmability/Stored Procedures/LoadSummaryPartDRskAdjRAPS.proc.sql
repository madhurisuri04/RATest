/*******************************************************************************************************************************
* Name			:	rev.LoadSummaryPartDRskAdjRAPS
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   67776
* Date          :	11/10/2017
* Version		:	1.0
* Project		:	SP for loading "SummaryPartDRskAdjRAPS" table
* SP call		:	Exec rev.LoadSummaryPartDRskAdjRAPS 0
* Version History :
  Author			Date		Version#	TFS Ticket#			Description
* -----------------	----------	--------	-----------			------------
	Rakshit Lall	11/10/2017	1.1			67776				Added mappings for ESRD, Hospice and HCC + Added debugging steps
	D. Waddell      01/26/2018  1.2         69226 (RE-1357)		Select for insert into summary sourced from Summary MMR [Aged] changed to to now pick up from [PartDAged].
	Rakshit Lall	02/07/2018	1.3			69421 (RE-1388)		Modified the code to remove the filter on the OREC. OREC filter is not needed for Part D
	D.Waddell		10/31/2019	1.4		    77159/RE-6981		Set Transaction Isolation Level Read to UNCOMMITTED
    Anand			2020-07-16	2.0			RRI-79/79109 		Used Intermediate Prelim table. Removed Plan ID from temp table 
															    calculation

*********************************************************************************************************************************/
Create PROCEDURE rev.LoadSummaryPartDRskAdjRAPS @Debug BIT = 0
AS
BEGIN

    SET STATISTICS IO OFF;
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @Today DATETIME = GETDATE(),
            @UserID VARCHAR(128) = SUSER_NAME(),
            @ErrorMessage VARCHAR(500),
            @ErrorSeverity INT,
            @ErrorState INT;

    IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;
        DECLARE @ET DATETIME = @Today,
                @MasterET DATETIME = @Today,
                @ProcessNameIn VARCHAR(128) = OBJECT_NAME(@@PROCID);
        EXEC [dbo].[PerfLogMonitor] @Section = '000',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
    END;

    /* Determine years to refresh the data for */

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '001',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    IF OBJECT_ID('TempDB..#RefreshPY') IS NOT NULL
        DROP TABLE #RefreshPY;

    CREATE TABLE #RefreshPY
    (
        RefreshPYId INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        PaymentYear SMALLINT NULL,
        FromDate SMALLDATETIME NULL,
        ThruDate SMALLDATETIME NULL,
        LaggedFromDate SMALLDATETIME NULL,
        LaggedThruDate SMALLDATETIME NULL,
        InitialSweepDate DATE NULL,
        MidYearSweepDate DATE NULL
    );

    INSERT INTO #RefreshPY
    (
        PaymentYear,
        FromDate,
        ThruDate,
        LaggedFromDate,
        LaggedThruDate,
        InitialSweepDate,
        MidYearSweepDate
    )
    SELECT Payment_Year,
           From_Date,
           Thru_Date,
           Lagged_From_Date,
           Lagged_Thru_Date,
           Initial_Sweep_Date,
           MidYear_Sweep_Date
    FROM rev.tbl_Summary_RskAdj_RefreshPY WITH (NOLOCK);

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '002',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Create a # version of SummaryPartDRskAdjRAPSPreliminary table */

    IF OBJECT_ID('[etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary]') IS NOT NULL

	Begin
	
        Truncate TABLE [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary];
	
	End

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '003',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

   INSERT INTO [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary]
    (
        PaymentYear,
        ModelYear,
        HICN,
        PartDRAFTProjected,
        RAPSDiagHCCRollupID,
        ProcessedBy,
        DiagnosisCode,
        FileID,
        PatientControlNumber,
        SeqNumber,
        ThruDate,
        VoidIndicator,
        Deleted,
        SourceId,
        ProviderId,
        RAC,
        RxHCCLabel,
        RxHCCNumber
    )
    SELECT R.PaymentYear,
           ModelYear,
           HICN,
           PartDRAFTProjected,
           RAPSDiagHCCRollupID,
           ProcessedBy,
           DiagnosisCode,
           FileID,
           PatientControlNumber,
           SeqNumber,
           R.ThruDate,
           VoidIndicator,
           Deleted,
           SourceId,
           ProviderId,
           RAC,
           RxHCCLabel,
           RxHCCNumber
    FROM rev.SummaryPartDRskAdjRAPSPreliminary R WITH (NOLOCK)
        JOIN #RefreshPY PY
            ON PY.PaymentYear = R.PaymentYear
    GROUP BY R.PaymentYear,
             ModelYear,
             HICN,
             PartDRAFTProjected,
             RAPSDiagHCCRollupID,
             ProcessedBy,
             DiagnosisCode,
             FileID,
             PatientControlNumber,
             SeqNumber,
             R.ThruDate,
             VoidIndicator,
             Deleted,
             SourceId,
             ProviderId,
             RAC,
             RxHCCLabel,
             RxHCCNumber;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '004',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    IF OBJECT_ID('[etl].[RAPSIntermediateForPartD]') IS NOT NULL

	Begin 

        Truncate TABLE [etl].[RAPSIntermediateForPartD];

	End

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '005',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

   
    INSERT INTO [etl].[RAPSIntermediateForPartD]
    (
        PaymentYear,
        ModelYear,
        HICN,
        RAFT,
        HCC,
        HCCORIG,
        HCCNumber,
        MinProcessBy,
        MinThru,
        Deleted,
        LoadDateTime
    )
    SELECT DISTINCT
		   RAPSPrelim.PaymentYear,
           RAPSPrelim.ModelYear,
           RAPSPrelim.HICN,
           RAPSPrelim.PartDRAFTProjected AS RAFT,
           RAPSPrelim.RxHCCLabel AS HCC,
           RxHCCLabel AS HCCORIG,
           RAPSPrelim.RxHCCNumber AS HCCNumber,
           MIN(RAPSPrelim.ProcessedBy) AS MinProcessBy,
           MIN(RAPSPrelim.ThruDate) AS MinThru,
           ISNULL(RAPSPrelim.Deleted, 'A') AS Deleted,
           @Today
    FROM [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] RAPSPrelim
    WHERE RAPSPrelim.Deleted IS NULL
          AND RAPSPrelim.VoidIndicator IS NULL
    GROUP BY RAPSPrelim.PaymentYear,
             RAPSPrelim.ModelYear,
             RAPSPrelim.HICN,
             RAPSPrelim.PartDRAFTProjected,
             RAPSPrelim.RxHCCLabel,
             RAPSPrelim.RxHCCNumber,
             ISNULL(RAPSPrelim.Deleted, 'A');

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '005',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    INSERT INTO [etl].[RAPSIntermediateForPartD]
    (
        PaymentYear,
        ModelYear,
        HICN,
        RAFT,
        HCC,
        HCCORIG,
        HCCNumber,
        MinProcessBy,
        MinThru,
        Deleted,
        LoadDateTime
    )
    SELECT RAPSPrelim.PaymentYear,
           RAPSPrelim.ModelYear,
           RAPSPrelim.HICN,
           RAPSPrelim.PartDRAFTProjected AS RAFT,
           RAPSPrelim.RxHCCLabel AS HCC,
           RxHCCLabel AS HCCORIG,
           RAPSPrelim.RxHCCNumber AS HCCNumber,
           MAX(RAPSPrelim.ProcessedBy) AS MinProcessBy,
           MAX(RAPSPrelim.ThruDate) AS MinThru,
           RAPSPrelim.Deleted AS Deleted,
           @Today
    FROM [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] RAPSPrelim
        LEFT JOIN [etl].[RAPSIntermediateForPartD] RPSACT
            ON RPSACT.PaymentYear = RAPSPrelim.PaymentYear
               AND RPSACT.ModelYear = RAPSPrelim.ModelYear
               AND RPSACT.HICN = RAPSPrelim.HICN
               AND RPSACT.RAFT = RAPSPrelim.PartDRAFTProjected
               AND RPSACT.HCC = RAPSPrelim.RxHCCLabel
               AND RPSACT.HCCNumber = RAPSPrelim.RxHCCNumber
               AND RPSACT.Deleted = 'A'
    WHERE RPSACT.HCC IS NULL
          AND RAPSPrelim.Deleted = 'D'
          AND RAPSPrelim.VoidIndicator IS NULL
    GROUP BY RAPSPrelim.PaymentYear,
             RAPSPrelim.ModelYear,
             RAPSPrelim.HICN,
             RAPSPrelim.PartDRAFTProjected,
             RAPSPrelim.RxHCCLabel,
             RxHCCLabel,
             RAPSPrelim.RxHCCNumber,
             RAPSPrelim.Deleted;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '007',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Updates in the working table - MinProcessBySeqNum */

    UPDATE RPS
    SET RPS.MinProcessBySeqNum = DRV.SeqNumber
    FROM [etl].[RAPSIntermediateForPartD] RPS
        JOIN
        (
            SELECT MIN(DIAG.SeqNumber) AS SeqNumber,
                   DIAG.HICN,
                   DIAG.PartDRAFTProjected AS RAFT,
                   DIAG.RxHCCNumber,
                   ISNULL(DIAG.Deleted, 'A') AS Deleted,
                   DIAG.PaymentYear,
                   DIAG.ModelYear,
                   DIAG.ProcessedBy
            FROM [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] DIAG
            WHERE DIAG.VoidIndicator IS NULL
            GROUP BY DIAG.HICN,
                     DIAG.PartDRAFTProjected,
                     DIAG.RxHCCNumber,
                     ISNULL(DIAG.Deleted, 'A'),
                     DIAG.PaymentYear,
                     DIAG.ModelYear,
                     DIAG.ProcessedBy
        ) DRV
            ON RPS.HICN = DRV.HICN
               AND RPS.RAFT = DRV.RAFT
               AND RPS.HCCNumber = DRV.RxHCCNumber
               AND RPS.Deleted = DRV.Deleted
               AND RPS.PaymentYear = DRV.PaymentYear
               AND RPS.ModelYear = DRV.ModelYear
               AND RPS.MinProcessBy = DRV.ProcessedBy;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '008',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Updates in the working table - MinProcessByDiagID */

    UPDATE RPS
    SET RPS.MinProcessbyDiagID = DRV.RAPSDiagHCCRollupID
    FROM [etl].[RAPSIntermediateForPartD] RPS
        JOIN
        (
            SELECT MIN(DIAG.RAPSDiagHCCRollupID) AS RAPSDiagHCCRollupID,
                   DIAG.HICN,
                   DIAG.PartDRAFTProjected AS RAFT,
                   DIAG.RxHCCNumber,
                   ISNULL(DIAG.Deleted, 'A') AS Deleted,
                   DIAG.PaymentYear,
                   DIAG.ModelYear,
                   DIAG.ProcessedBy,
                   DIAG.SeqNumber
            FROM [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] DIAG
            WHERE DIAG.VoidIndicator IS NULL
            GROUP BY DIAG.HICN,
                     DIAG.PartDRAFTProjected,
                     DIAG.RxHCCNumber,
                     ISNULL(DIAG.Deleted, 'A'),
                     DIAG.PaymentYear,
                     DIAG.ModelYear,
                     DIAG.ProcessedBy,
                     DIAG.SeqNumber
        ) DRV
            ON RPS.HICN = DRV.HICN
               AND RPS.RAFT = DRV.RAFT
               AND RPS.HCCNumber = DRV.RxHCCNumber
               AND RPS.Deleted = DRV.Deleted
               AND RPS.PaymentYear = DRV.PaymentYear
               AND RPS.ModelYear = DRV.ModelYear
               AND RPS.MinProcessBy = DRV.ProcessedBy
               AND RPS.MinProcessBySeqNum = DRV.SeqNumber;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '009',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Update other columns in the working table */

    UPDATE RPS
    SET RPS.MinProcessbyDiagCD = DIAG.DiagnosisCode,
        RPS.MinProcessByPCN = DIAG.PatientControlNumber,
        RPS.ProcessedPriorityThruDate = DIAG.ThruDate,
        RPS.ProcessedPriorityFileID = DIAG.FileID,
        RPS.ProcessedPriorityRAPSSourceID = DIAG.SourceId,
        RPS.ProcessedPriorityProviderID = DIAG.ProviderId,
        RPS.ProcessedPriorityRAC = DIAG.RAC
    FROM [etl].[RAPSIntermediateForPartD] RPS
        JOIN [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] DIAG
            ON DIAG.RAPSDiagHCCRollupID = RPS.MinProcessbyDiagID
               AND DIAG.HICN = RPS.HICN
               AND DIAG.PaymentYear = RPS.PaymentYear
    WHERE DIAG.VoidIndicator IS NULL;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '010',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Updates in the working table - MinThruSeqNum */

    UPDATE RPS
    SET RPS.MinThruSeqNum = DRV.SeqNumber
    FROM [etl].[RAPSIntermediateForPartD] RPS
        JOIN
        (
            SELECT MIN(DIAG.SeqNumber) AS SeqNumber,
                   DIAG.HICN,
                   DIAG.PartDRAFTProjected AS RAFT,
                   DIAG.RxHCCNumber,
                   ISNULL(DIAG.Deleted, 'A') AS Deleted,
                   DIAG.PaymentYear,
                   DIAG.ModelYear,
                   DIAG.ThruDate
            FROM [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] DIAG
            WHERE DIAG.VoidIndicator IS NULL
            GROUP BY DIAG.HICN,
                     DIAG.PartDRAFTProjected,
                     DIAG.RxHCCNumber,
                     ISNULL(DIAG.Deleted, 'A'),
                     DIAG.PaymentYear,
                     DIAG.ModelYear,
                     DIAG.ThruDate
        ) DRV
            ON RPS.HICN = DRV.HICN
               AND RPS.RAFT = DRV.RAFT
               AND RPS.HCCNumber = DRV.RxHCCNumber
               AND RPS.Deleted = DRV.Deleted
               AND RPS.PaymentYear = DRV.PaymentYear
               AND RPS.ModelYear = DRV.ModelYear
               AND RPS.MinThru = DRV.ThruDate;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '011',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Updates in the working table - MinProcessByDiagID */

    UPDATE RPS
    SET RPS.MinThruDateDiagID = DRV.RAPSDiagHCCRollupID
    FROM [etl].[RAPSIntermediateForPartD] RPS
        JOIN
        (
            SELECT MIN(DIAG.RAPSDiagHCCRollupID) AS RAPSDiagHCCRollupID,
                   DIAG.HICN,
                   DIAG.PartDRAFTProjected AS RAFT,
                   DIAG.RxHCCNumber,
                   ISNULL(DIAG.Deleted, 'A') AS Deleted,
                   DIAG.PaymentYear,
                   DIAG.ModelYear,
                   DIAG.ThruDate,
                   DIAG.SeqNumber
            FROM [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] DIAG
            WHERE DIAG.VoidIndicator IS NULL
            GROUP BY 
                     DIAG.HICN,
                     DIAG.PartDRAFTProjected,
                     DIAG.RxHCCNumber,
                     ISNULL(DIAG.Deleted, 'A'),
                     DIAG.PaymentYear,
                     DIAG.ModelYear,
                     DIAG.ThruDate,
                     DIAG.SeqNumber
        ) DRV
            ON RPS.HICN = DRV.HICN
               AND RPS.RAFT = DRV.RAFT
               AND RPS.HCCNumber = DRV.RxHCCNumber
               AND RPS.Deleted = DRV.Deleted
               AND RPS.PaymentYear = DRV.PaymentYear
               AND RPS.ModelYear = DRV.ModelYear
               AND RPS.MinThru = DRV.ThruDate
               AND RPS.MinThruSeqNum = DRV.SeqNumber;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '012',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Update other columns based on the join to MinThruDateDIAGID */

    UPDATE RPS
    SET RPS.MinThruDateDiagCD = DIAG.DiagnosisCode,
        RPS.MinThruDatePCN = DIAG.PatientControlNumber,
        RPS.ThruPriorityProcessedBy = DIAG.ProcessedBy,
        RPS.ThruPriorityFileID = DIAG.FileID,
        RPS.ThruPriorityRAPSSourceID = DIAG.SourceId,
        RPS.ThruPriorityProviderID = DIAG.ProviderId,
        RPS.ThruPriorityRAC = DIAG.RAC
    FROM [etl].[RAPSIntermediateForPartD] RPS
        JOIN [etl].[SummaryIntermediatePartDRskAdjRAPSPreliminary] DIAG
            ON DIAG.RAPSDiagHCCRollupID = RPS.MinThruDateDiagID
               AND DIAG.HICN = RPS.HICN
               AND DIAG.PaymentYear = RPS.PaymentYear
    WHERE DIAG.VoidIndicator IS NULL;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '013',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Updating IMFFlag - 3 = Final; 2 = MidYear; 1 = Initial */

    UPDATE a1
    SET a1.IMFFlag = 3
    FROM [etl].[RAPSIntermediateForPartD] a1
        JOIN #RefreshPY PY
            ON a1.PaymentYear = PY.PaymentYear
    WHERE a1.MinProcessBy > PY.MidYearSweepDate;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '014',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    UPDATE a1
    SET a1.IMFFlag = 2
    FROM [etl].[RAPSIntermediateForPartD] a1
        JOIN #RefreshPY PY
            ON a1.PaymentYear = PY.PaymentYear
    WHERE (
              (
                  a1.MinProcessBy > PY.InitialSweepDate
                  AND a1.MinProcessBy <= PY.MidYearSweepDate
              )
              OR
              (
                  a1.MinProcessBy <= PY.InitialSweepDate
                  AND a1.ProcessedPriorityThruDate > PY.LaggedThruDate
              )
          );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '015',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    UPDATE a1
    SET a1.IMFFlag = 1
    FROM [etl].[RAPSIntermediateForPartD] a1
        JOIN #RefreshPY PY
            ON a1.PaymentYear = PY.PaymentYear
    WHERE (
              a1.MinProcessBy <= PY.InitialSweepDate
              AND a1.ProcessedPriorityThruDate <= PY.LaggedThruDate
          );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '016',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Update DEL HCC */

    UPDATE [etl].[RAPSIntermediateForPartD]
    SET HCC = 'DEL-' + HCC
    FROM [etl].[RAPSIntermediateForPartD]
    WHERE Deleted = 'D';

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '017',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Hierarchy Logic for RAPS and MOR Combined */

    UPDATE t1
    SET t1.HCC = T2.HCCNew
    FROM [etl].[RAPSIntermediateForPartD] t1
        JOIN
        (
            SELECT CASE
                       WHEN DRP.IMFFlag >= KEP.IMFFlag THEN
                           'HIER-' + DRP.HCC
                       ELSE
                           DRP.HCC
                   END AS HCCNew,
                   DRP.HCC,
                   DRP.HICN,
                   DRP.IMFFlag,
                   DRP.PaymentYear,
                   DRP.ModelYear,
                   DRP.MinProcessBy,
                   DRP.RAFT,
                   DRP.MinThru
            FROM [etl].[RAPSIntermediateForPartD] DRP
                JOIN [$(HRPReporting)].dbo.lk_Risk_Models_HIERarchy HIER WITH (NOLOCK)
                    ON HIER.HCC_DROP_NUMBER = DRP.HCCNumber
                       AND HIER.Payment_Year = DRP.ModelYear
                       AND HIER.RA_FACTOR_TYPE = DRP.RAFT
                       AND HIER.Part_C_D_Flag = 'D'
                       AND LEFT(HIER.HCC_DROP, 3) = 'HCC'
                       AND LEFT(DRP.HCC, 3) = 'HCC'
                JOIN [etl].[RAPSIntermediateForPartD] KEP
                    ON KEP.HICN = DRP.HICN
                       AND KEP.RAFT = DRP.RAFT
                       AND KEP.HCCNumber = HIER.HCC_KEEP_NUMBER
                       AND KEP.PaymentYear = DRP.PaymentYear
                       AND KEP.ModelYear = DRP.ModelYear
                       AND LEFT(KEP.HCC, 3) = 'HCC'
            GROUP BY DRP.HCC,
                     DRP.HICN,
                     DRP.IMFFlag,
                     DRP.PaymentYear,
                     DRP.ModelYear,
                     DRP.MinProcessBy,
                     DRP.RAFT,
                     DRP.MinThru,
                     KEP.IMFFlag
        ) T2
            ON t1.HICN = T2.HICN
               AND t1.HCC = T2.HCC
               AND t1.IMFFlag = T2.IMFFlag
               AND t1.PaymentYear = T2.PaymentYear
               AND t1.ModelYear = T2.ModelYear
               AND t1.MinProcessBy = T2.MinProcessBy
               AND t1.RAFT = T2.RAFT
               AND t1.MinThru = T2.MinThru;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '018',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Applying incremental hierarchy logic */

    UPDATE T3
    SET T3.HCC = T2.HCCNew
    FROM [etl].[RAPSIntermediateForPartD] T3
        JOIN
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY T1.HCC,
                                                   T1.HICN,
                                                   T1.IMFFlag,
                                                   T1.PaymentYear,
                                                   T1.ModelYear,
                                                   T1.MinProcessBy,
                                                   T1.RAFT,
                                                   T1.MinThru
                                      ORDER BY (T1.HICN)
                                     ) AS RowNum,
                   T1.HCC,
                   T1.HCCNew,
                   T1.HICN,
                   T1.IMFFlag,
                   T1.PaymentYear,
                   T1.ModelYear,
                   T1.MinProcessBy,
                   T1.RAFT,
                   T1.MinThru
            FROM
            (
                SELECT DRP.HCC,
                       CASE
                           WHEN DRP.IMFFlag < KEP.IMFFlag THEN
                               'INCR-' + DRP.HCC
                           ELSE
                               DRP.HCC
                       END AS HCCNew,
                       DRP.HICN,
                       DRP.IMFFlag,
                       DRP.PaymentYear,
                       DRP.ModelYear,
                       DRP.MinProcessBy,
                       DRP.RAFT,
                       DRP.MinThru
                FROM [etl].[RAPSIntermediateForPartD] DRP
                    JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy HIER WITH (NOLOCK)
                        ON HIER.HCC_DROP_NUMBER = DRP.HCCNumber
                           AND HIER.Payment_Year = DRP.ModelYear
                           AND HIER.RA_FACTOR_TYPE = DRP.RAFT
                           AND HIER.Part_C_D_Flag = 'D'
                           AND LEFT(HIER.HCC_DROP, 3) = 'HCC'
                           AND LEFT(DRP.HCC, 3) = 'HCC'
                    JOIN [etl].[RAPSIntermediateForPartD] KEP
                        ON KEP.HICN = DRP.HICN
                           AND KEP.RAFT = DRP.RAFT
                           AND KEP.HCCNumber = HIER.HCC_KEEP_NUMBER
                           AND KEP.PaymentYear = DRP.PaymentYear
                           AND KEP.ModelYear = DRP.ModelYear
                           AND LEFT(KEP.HCC, 3) = 'HCC'
            ) T1
        ) T2
            ON T2.HICN = T3.HICN
               AND T2.IMFFlag = T3.IMFFlag
               AND T2.PaymentYear = T3.PaymentYear
               AND T2.ModelYear = T3.ModelYear
               AND T2.MinProcessBy = T3.MinProcessBy
               AND T2.RAFT = T3.RAFT
               AND T2.MinThru = T3.MinThru
               AND T2.HCC = T3.HCC
    WHERE T2.RowNum = 1;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '019',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Truncate ETL table if there is any data so it is a fresh load in to ETL every time */

    IF EXISTS
    (
        SELECT TOP 1
               SummaryPartDRskAdjRAPSID
        FROM etl.SummaryPartDRskAdjRAPS
    )
    BEGIN
        TRUNCATE TABLE etl.SummaryPartDRskAdjRAPS;
    END;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '020',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    INSERT INTO etl.SummaryPartDRskAdjRAPS
    (
        PlanIdentifier,
        HICN,
        PaymentYear,
        PaymStart,
        ModelYear,
        FactorCategory,
        RxHCCLabelOrig,
        Factor,
        HCCNumber,
        PartDRAFTRestated,
        PartDRAFTMMR,
        MinProcessBy,
        MinThruDate,
        MinProcessBySeqNum,
        MinThruDateSeqNum,
        MinProcessbyDiagCD,
        MinThruDateDiagCD,
        MinProcessByPCN,
        MinThruDatePCN,
        ProcessedPriorityThruDate,
        ThruPriorityProcessedBy,
        ProcessedPriorityFileID,
        ProcessedPriorityRAPSSourceID,
        ProcessedPriorityProviderID,
        ProcessedPriorityRAC,
        ThruPriorityFileID,
        ThruPriorityRAPSSourceID,
        ThruPriorityProviderID,
        ThruPriorityRAC,
        IMFFlag,
        Aged,
        LoadDate,
        UserID,
        ESRD,
        Hospice,
        RxHCCLabel
    )
    SELECT DISTINCT
           MMR.PlanID AS PlanIdentifier,
           RSKFCT.HICN,
           MMR.PaymentYear,
           MMR.PaymStart,
           RSKFCT.ModelYear,
           'RAPS' AS FactorCategory,
           RSKFCT.HCCORIG AS RxHCCLabelOrig,
           RSKMOD.Factor,
           RSKFCT.HCCNumber,
           MMR.PartDRAFTProjected,
           MMR.PartDRAFTMMR,
           RSKFCT.MinProcessBy,
           RSKFCT.MinThru AS MinThruDate,
           RSKFCT.MinProcessBySeqNum,
           RSKFCT.MinThruSeqNum AS MinThruDateSeqNum,
           RSKFCT.MinProcessbyDiagCD,
           RSKFCT.MinThruDateDiagCD,
           RSKFCT.MinProcessByPCN,
           RSKFCT.MinThruDatePCN,
           RSKFCT.ProcessedPriorityThruDate,
           RSKFCT.ThruPriorityProcessedBy,
           RSKFCT.ProcessedPriorityFileID,
           RSKFCT.ProcessedPriorityRAPSSourceID,
           RSKFCT.ProcessedPriorityProviderID,
           RSKFCT.ProcessedPriorityRAC,
           RSKFCT.ThruPriorityFileID,
           RSKFCT.ThruPriorityRAPSSourceID,
           RSKFCT.ThruPriorityProviderID,
           RSKFCT.ThruPriorityRAC,
           RSKFCT.IMFFlag,
           MMR.PartDAged AS Aged, -- TFS 69226  (RE-1357)
           @Today AS LoadDate,
           @UserID AS UserID,
           MMR.ESRD,
           MMR.HOSP,
           RSKFCT.HCC
    FROM rev.tbl_Summary_RskAdj_MMR MMR WITH (NOLOCK)
        JOIN [etl].[RAPSIntermediateForPartD] RSKFCT
            ON RSKFCT.HICN = MMR.HICN
               AND RSKFCT.RAFT = MMR.PartDRAFTProjected
               AND RSKFCT.PaymentYear = MMR.PaymentYear
        JOIN [$(HRPReporting)].dbo.lk_Risk_Models RSKMOD WITH (NOLOCK)
            ON RSKMOD.Payment_Year = RSKFCT.ModelYear
               AND CAST(SUBSTRING(RSKMOD.Factor_Description, 4, LEN(RSKMOD.Factor_Description) - 3) AS INT) = RSKFCT.HCCNumber
               AND RSKMOD.Factor_Type = MMR.PartDRAFTProjected
               AND RSKMOD.Aged = MMR.PartDAged
    WHERE RSKMOD.Part_C_D_Flag = 'D'
          AND RSKMOD.Demo_Risk_Type = 'Risk'
          AND RSKMOD.Factor_Description LIKE 'HCC%'
    UNION ALL
    SELECT DISTINCT
           MMR.PlanID AS PlanIdentifier,
           RSKFCT.HICN,
           MMR.PaymentYear,
           MMR.PaymStart,
           RSKFCT.ModelYear,
           'RAPS-Disability' AS FactorCategory,
           RSKFCT.HCCORIG AS RxHCCLabelOrig,
           RSKMOD.Factor,
           RSKFCT.HCCNumber,
           MMR.PartDRAFTProjected,
           MMR.PartDRAFTMMR,
           RSKFCT.MinProcessBy,
           RSKFCT.MinThru AS MinThruDate,
           RSKFCT.MinProcessBySeqNum,
           RSKFCT.MinThruSeqNum AS MinThruDateSeqNum,
           RSKFCT.MinProcessbyDiagCD,
           RSKFCT.MinThruDateDiagCD,
           RSKFCT.MinProcessByPCN,
           RSKFCT.MinThruDatePCN,
           RSKFCT.ProcessedPriorityThruDate,
           RSKFCT.ThruPriorityProcessedBy,
           RSKFCT.ProcessedPriorityFileID,
           RSKFCT.ProcessedPriorityRAPSSourceID,
           RSKFCT.ProcessedPriorityProviderID,
           RSKFCT.ProcessedPriorityRAC,
           RSKFCT.ThruPriorityFileID,
           RSKFCT.ThruPriorityRAPSSourceID,
           RSKFCT.ThruPriorityProviderID,
           RSKFCT.ThruPriorityRAC,
           RSKFCT.IMFFlag,
           MMR.PartDAged AS Aged,
           @Today AS LoadDate,
           @UserID AS UserID,
           MMR.ESRD,
           MMR.HOSP,
           RSKFCT.HCC
    FROM rev.tbl_Summary_RskAdj_MMR MMR WITH (NOLOCK)
        JOIN [etl].[RAPSIntermediateForPartD] RSKFCT
            ON RSKFCT.HICN = MMR.HICN
               AND RSKFCT.RAFT = MMR.PartDRAFTProjected
               AND RSKFCT.PaymentYear = MMR.PaymentYear
        JOIN [$(HRPReporting)].dbo.lk_Risk_Models RSKMOD WITH (NOLOCK)
            ON RSKMOD.Payment_Year = RSKFCT.ModelYear
               AND CAST(SUBSTRING(RSKMOD.Factor_Description, 6, LEN(RSKMOD.Factor_Description) - 5) AS INT) = RSKFCT.HCCNumber
               AND RSKMOD.Factor_Type = MMR.PartDRAFTProjected
               AND RSKMOD.Aged = MMR.PartDAged
    WHERE RSKMOD.Part_C_D_Flag = 'D'
          AND RSKMOD.Demo_Risk_Type = 'Risk'
          AND RSKMOD.Factor_Description LIKE 'D-HCC%'
          AND RSKFCT.HCC LIKE 'HCC%'
          AND MMR.RskAdjAgeGrp < '6565';

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '021',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /* Switch partitions for each PaymentYear */

    IF EXISTS (SELECT TOP 1 1 FROM [etl].SummaryPartDRskAdjRAPS)
    BEGIN

        DECLARE @I INT;
        DECLARE @ID INT =
                (
                    SELECT COUNT(DISTINCT PaymentYear) FROM #RefreshPY
                );

        SET @I = 1;

        WHILE (@I <= @ID)
        BEGIN

            DECLARE @PaymentYear SMALLINT =
                    (
                        SELECT PaymentYear FROM #RefreshPY WHERE RefreshPYId = @I
                    );

            PRINT 'Starting Partition Switch For PaymentYear : ' + CONVERT(VARCHAR(4), @PaymentYear);

            BEGIN TRY

                BEGIN TRANSACTION SwitchPartitions;

                TRUNCATE TABLE [out].SummaryPartDRskAdjRAPS;

                -- Switch Partition for History SummaryPartDRskAdjRAPS 
                ALTER TABLE hst.SummaryPartDRskAdjRAPS SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].SummaryPartDRskAdjRAPS PARTITION $Partition.[pfn_SummPY](@PaymentYear);

                -- Switch Partition for DBO SummaryPartDRskAdjRAPS 
                ALTER TABLE rev.SummaryPartDRskAdjRAPS SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO hst.SummaryPartDRskAdjRAPS PARTITION $Partition.[pfn_SummPY](@PaymentYear);

                -- Switch Partition for ETL SummaryPartDRskAdjRAPS	
                ALTER TABLE etl.SummaryPartDRskAdjRAPS SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO rev.SummaryPartDRskAdjRAPS PARTITION $Partition.[pfn_SummPY](@PaymentYear);

                COMMIT TRANSACTION SwitchPartitions;

                PRINT 'Partition Completed For PaymentYear : ' + CONVERT(VARCHAR(4), @PaymentYear);

            END TRY
            BEGIN CATCH

                SELECT @ErrorMessage = ERROR_MESSAGE(),
                       @ErrorSeverity = ERROR_SEVERITY(),
                       @ErrorState = ERROR_STATE();

                IF (XACT_STATE() = 1 OR XACT_STATE() = -1)
                BEGIN
                    ROLLBACK TRANSACTION SwitchPartitions;
                END;

                RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

                RETURN;

            END CATCH;

            SET @I = @I + 1;

        END;

    END;

    ELSE
        PRINT 'Partition switching did not run because there was no data was loaded in the ETL table';

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '022',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

END;