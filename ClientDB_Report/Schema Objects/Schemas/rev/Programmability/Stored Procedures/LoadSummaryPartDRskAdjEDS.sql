Create PROC [rev].[LoadSummaryPartDRskAdjEDS]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS

/************************************************************************************************************************ 
* Name				:	rev.LoadSummaryPartDRskAdjEDS																		*
* Type 				:	Stored Procedure																					*
* Author       		:	David Waddell																						*
* Date				:	2017-11-25																							*
* Version			:																										*
* Description		: The Part D Summary EDS stored procedure will gather Part D Summary EDS Preliminary information for	*
*					  the entire client. This data will be grouped at the HICN-RxHCC level and each record                  *
*                     will then be updated with attributing encounter level information. This output will allow the user    *
*                     to understand which single encounter led to the RxHCC in within that record.                          *
*                                                                                                                           *
*																															*
* Version History :																											*
* ======================================================================================================================	*
* Author			Date		Version#    TFS Ticket#			Description													*	
* -----------------	----------  --------    -----------			------------												*
* D. Waddell		2017-12-12	1.0		    67957 / RE-1186		Initial														*
* D. Waddell        2018-01-26  1.1         69226 /RE-1357      Select for insert into summary sourced                      *
*																from Summary MMR [Aged] changed to 							*
*                                                               to now pick up from [PartDAged].                            *
*D. Waddell         2018-02-22  1.2        69475 /RE-1402       Sections of scriptpertaining to Interaction logic removed   *
*                                                               (sections 18 - 32.1, 34). In addition, Remove OREC logic    *
*                                                               perm table insert statement join conditions (Sect. 33& 35)  * 
*D. Waddell         2018-05-28  1.3       70759 / RE-1889       Populate new LastAssignedHICN field in                      * 
*D. Waddell         2018-06-05  1.4       70759 / RE-2127       Bug Fix: modify RE-1889 to fix join and                     *
*                                                               handle NULL LastAssignedHICN in   (Sect. 034)               *
* D.Waddell			10/31/2019	1.3		 77159/	RE-6981			Set Transaction Isolation Level Read to UNCOMMITTED         *
* D. Waddell		06/12/2020	1.4		 78828/ RE- 8152        Fix Max/Min buf in section 04 of proc. Min function needs   *
*                                                               used.                                                       *
* Anand				2020-07-20	2.0		  RRI-79/79109          Used Intermediate Prelim table. Removed Plan ID from temp table 
															    calculation.
* Madhuri Suri		2021-12-16	2.1		  RRI-1912            Delete Flag Changes                          
****************************************************************************************************************************/


SET NOCOUNT ON;
SET STATISTICS IO OFF;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @Today DATETIME = GETDATE(),
        @ErrorMessage VARCHAR(500),
        @ErrorSeverity INT,
        @ErrorState INT;



IF @Debug = 1
BEGIN
    SET STATISTICS IO ON;
    DECLARE @ET DATETIME;
    DECLARE @MasterET DATETIME;
    DECLARE @ProcessNameIn VARCHAR(128);




    SET @ET = GETDATE();
    SET @MasterET = @ET;
    SET @ProcessNameIn = OBJECT_NAME(@@procid);
    EXEC [dbo].[PerfLogMonitor] @Section = '000',
                                @ProcessName = @ProcessNameIn,
                                @ET = @ET,
                                @MasterET = @MasterET,
                                @ET_Out = @ET OUT,
                                @TableOutput = 0,
                                @End = 0;
END;

SET @LoadDateTime = ISNULL(@LoadDateTime, GETDATE());
SET @DeleteBatch = ISNULL(@DeleteBatch, 150000);

IF (OBJECT_ID('tempdb.dbo.#Refresh_PY') IS NOT NULL)
BEGIN
    DROP TABLE [#Refresh_PY];
END;

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


CREATE TABLE [#Refresh_PY]
(
    [Refresh_PYId] [INT] IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    [Payment_Year] [INT] NULL,
    [From_Date] [DATE] NULL,
    [Thru_Date] [DATE] NULL,
    [Lagged_From_Date] [DATE] NULL,
    [Lagged_Thru_Date] [DATE] NULL,
    [Initial_Sweep_Date] DATE NULL,
    [Final_Sweep_Date] DATE NULL,
    [MidYear_Sweep_Date] DATE NULL
);

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

INSERT INTO [#Refresh_PY]
(
    [Payment_Year],
    [From_Date],
    [Thru_Date],
    [Lagged_From_Date],
    [Lagged_Thru_Date],
    [Initial_Sweep_Date],
    [Final_Sweep_Date],
    [MidYear_Sweep_Date]
)
SELECT [Payment_Year] = [r1].[Payment_Year],
       [From_Date] = [r1].[From_Date],
       [Thru_Date] = [r1].[Thru_Date],
       [Lagged_From_Date] = [r1].[Lagged_From_Date],
       [Lagged_Thru_Date] = [r1].[Lagged_Thru_Date],
       [Initial_Sweep_Date] = [r1].[Initial_Sweep_Date],
       [Final_Sweep_Date] = [r1].[Final_Sweep_Date],
       [MidYear_Sweep_Date] = [r1].[MidYear_Sweep_Date]
FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [r1];

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

if (object_id('[etl].[SummaryIntermediatePartDRskAdjEDSPreliminary]') is not null)

BEGIN
    
   Truncate table [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary];
 
End


Insert Into [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary]
(
	[PaymentYear],
	[ModelYear],
	[HICN],
	[PartDRAFTProjected],
	[MAO004ResponseID],
	[PlanSubmissionDate],
	[ServiceEndDate],
	[FileImportID],
	[MAO004ResponseDiagnosisCodeID],
	[DiagnosisCode],
	[DerivedPatientControlNumber],
	[VoidIndicator],
	[RiskAdjustable],
	[Deleted],
	[RxHCCLabel],
	[RxHCCNumber]
)
Select 
	Distinct 
	[PaymentYear],
	[ModelYear],
	[HICN],
	[PartDRAFTProjected],
	[MAO004ResponseID],
	[PlanSubmissionDate],
	[ServiceEndDate],
	[FileImportID],
	[MAO004ResponseDiagnosisCodeID],
	[DiagnosisCode],
	[DerivedPatientControlNumber],
	[VoidIndicator],
	[RiskAdjustable],
	[Deleted],
	[RxHCCLabel],
	[RxHCCNumber]
  From [rev].[SummaryPartDRskAdjEDSPreliminary]  [rps] WITH (NOLOCK)
   JOIN [#Refresh_PY] [py]
        ON [rps].[PaymentYear] = [py].[Payment_Year];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '003.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

/* Truncate the IntermediateEDSPartD Table */

if (object_id('[rev].[IntermediateEDSPartD]') is not null)

BEGIN
    
   Truncate table [rev].[IntermediateEDSPartD];
 
End


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



/* Insert into [rev].[IntermediateEDSPartD] table*/

INSERT INTO [rev].[IntermediateEDSPartD]
(
    [PaymentYear],
    [ModelYear],
    [HICN],
    [PartDRAFT],
    [RxHCCLabel],
    [RxHCCLabelOrig],
    [RxHCCNumber],
    [Deleted],
    [LoadDateTime],
    [MinProcessBy],
    [MinThruDate]
)
SELECT [PaymentYear] = [rps].[PaymentYear],
       [ModelYear] = [rps].[ModelYear],
       [HICN] = [rps].[HICN],
       [PartDRAFT] = [rps].[PartDRAFTProjected],
       [RxHCCLabel] = [rps].[RxHCCLabel],
       [RxHCCLabelOrig] = [rps].[RxHCCLabel],
       [RxHCCNumber] = [rps].[RxHCCNumber],
       [Deleted] = ISNULL([rps].[Deleted], 'A'),
       [LoadDateTime] = @LoadDateTime,
       [MinProcessBy] = MIN([rps].[PlanSubmissionDate]),  -- RE-8152  Modified BY D. Waddell 6/12/20
       [MinThruDate] = MIN([rps].[ServiceEndDate])       -- RE-8152  Modified BY D. Waddell 6/12/20
FROM [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [rps]

WHERE (
          [rps].[Deleted] <> 'D' ---RRI 1912 
      )
      AND
      (
          [rps].[VoidIndicator] IS NULL
          OR [rps].[VoidIndicator] = 0
      )
      AND [rps].[RiskAdjustable] = 1
GROUP BY [rps].[PaymentYear],
         [rps].[ModelYear],
         [rps].[HICN],
         [rps].[PartDRAFTProjected],
         [rps].[RxHCCLabel],
         [rps].[RxHCCNumber],
         ISNULL([rps].[Deleted], 'A');

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

INSERT INTO [rev].[IntermediateEDSPartD]
(
    [PaymentYear],
    [ModelYear],
    [HICN],
    [PartDRAFT],
    [RxHCCLabel],
    [RxHCCLabelOrig],
    [RxHCCNumber],
    [Deleted],
    [LoadDateTime],
    [MinProcessBy],
    [MinThruDate]
)
SELECT [PaymentYear] = [rps].[PaymentYear],
       [ModelYear] = [rps].[ModelYear],
       [HICN] = [rps].[HICN],
       [PartDRAFT] = [rps].[PartDRAFTProjected],
       [RxHCCLabel] = [rps].[RxHCCLabel],
       [RxHCCLabelOrig] = [rps].[RxHCCLabel],
       [RxHCCNumber] = [rps].[RxHCCNumber],
       [Deleted] = [rps].[Deleted],
       [LoadDateTime] = @LoadDateTime,
       [MinProcessBy] = MAX([rps].[PlanSubmissionDate]), 
       [MinThruDate] = MAX([rps].[ServiceEndDate])      
FROM [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [rps]
    LEFT JOIN [rev].[IntermediateEDSPartD] [rpsact]
        ON [rpsact].[HICN] = [rps].[HICN]
           AND [rpsact].[PartDRAFT] = [rps].[PartDRAFTProjected]
           AND [rpsact].[RxHCCLabel] = [rps].[RxHCCLabel]
           AND [rpsact].[RxHCCNumber] = [rps].[RxHCCNumber]
           AND [rpsact].[Deleted] = 'A'
           AND [rpsact].[PaymentYear] = [rps].[PaymentYear]
WHERE [rpsact].[RxHCCLabel] IS NULL
      AND [rps].[Deleted] = 'D'
      AND [rps].[VoidIndicator] = 0
GROUP BY [rps].[PaymentYear],
         [rps].[ModelYear],
         [rps].[HICN],
         [rps].[PartDRAFTProjected],
         [rps].[RxHCCLabel],
         [rps].[RxHCCNumber],
         [rps].[Deleted];



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '006',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/*Set value of [MinProcessBySeqNum]   */
UPDATE [rps]
SET [rps].[MinProcessBySeqNum] = [drv].[MAO004ResponseID]
FROM [rev].[IntermediateEDSPartD] [rps]
    JOIN
    (
        SELECT [MAO004ResponseID] = MIN([diag].[MAO004ResponseID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartDRAFTProjected],
               [diag].[RxHCCNumber],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[PlanSubmissionDate]
        FROM [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [diag]
        WHERE [diag].[VoidIndicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY [diag].[HICN],
                 [diag].[PartDRAFTProjected],
                 [diag].[RxHCCNumber],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[PlanSubmissionDate]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[PartDRAFT] = [drv].[RAFT]
           AND [rps].[RxHCCNumber] = [drv].[RxHCCNumber]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[MinProcessBy] = [drv].[PlanSubmissionDate];

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

/* Set value of [MinProcessbyDiagID] */

UPDATE [rps]
SET [rps].[MinProcessbyDiagID] = [drv].[MAO004ResponseDiagnosisCodeID]
FROM [rev].[IntermediateEDSPartD] [rps]
    JOIN
    (
        SELECT [MAO004ResponseDiagnosisCodeID] = MIN([diag].[MAO004ResponseDiagnosisCodeID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartDRAFTProjected],
               [diag].[RxHCCNumber],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[PlanSubmissionDate],
               [diag].[MAO004ResponseID]
        FROM [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [diag]
        WHERE [diag].[VoidIndicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY [diag].[HICN],
                 [diag].[PartDRAFTProjected],
                 [diag].[RxHCCNumber],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[PlanSubmissionDate],
                 [diag].[MAO004ResponseID]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[PartDRAFT] = [drv].[RAFT]
           AND [rps].[RxHCCNumber] = [drv].[RxHCCNumber]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[MinProcessBy] = [drv].[PlanSubmissionDate]
           AND [rps].[MinProcessBySeqNum] = [drv].[MAO004ResponseID];

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


/* Set value of [MinProcessbyDiagCD], [MinProcessByPCN],[ProcessedPriorityThruDate], [ProcessedPriorityFileID],[ProcessedPriorityRAPSSourceID]    */

UPDATE [rps]
SET [rps].[MinProcessbyDiagCD] = [diag].[DiagnosisCode],
    [rps].[MinProcessByPCN] = [diag].[DerivedPatientControlNumber],
    [rps].[ProcessedPriorityThruDate] = [diag].[ServiceEndDate],
    [rps].[ProcessedPriorityFileID] = [diag].[FileImportID],
    [rps].[ProcessedPriorityRAPSSourceID] = 99
FROM [rev].[IntermediateEDSPartD] [rps]
    JOIN [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [diag]
        ON [diag].[MAO004ResponseDiagnosisCodeID] = [rps].[MinProcessbyDiagID]
           AND [diag].[HICN] = [rps].[HICN]
           AND [diag].[PaymentYear] = [rps].[PaymentYear]
WHERE [diag].[VoidIndicator] = 0
      AND [diag].[RiskAdjustable] = 1;

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


/* Set value of [MinThruDateSeqNum]  */

UPDATE [rps]
SET [rps].[MinThruDateSeqNum] = [drv].[MAO004ResponseID]
FROM [rev].[IntermediateEDSPartD] [rps]
    JOIN
    (
        SELECT [MAO004ResponseID] = MIN([diag].[MAO004ResponseID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartDRAFTProjected],
               [diag].[RxHCCNumber],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ServiceEndDate]
        FROM [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [diag]
        WHERE [diag].[VoidIndicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY [diag].[HICN],
                 [diag].[PartDRAFTProjected],
                 [diag].[RxHCCNumber],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ServiceEndDate]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[PartDRAFT] = [drv].[RAFT]
           AND [rps].[RxHCCNumber] = [drv].[RxHCCNumber]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[MinThruDate] = [drv].[ServiceEndDate];

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



/* Set value of  [MinThruDateDiagID]  */

UPDATE [rps]
SET [rps].[MinThruDateDiagID] = [drv].[MAO004ResponseDiagnosisCodeID]
FROM [rev].[IntermediateEDSPartD] [rps]
    JOIN
    (
        SELECT [MAO004ResponseDiagnosisCodeID] = MIN([diag].[MAO004ResponseDiagnosisCodeID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartDRAFTProjected],
               [diag].[RxHCCNumber],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ServiceEndDate],
               [diag].[MAO004ResponseID]
        FROM [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [diag]
        WHERE [diag].[VoidIndicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY [diag].[HICN],
                 [diag].[PartDRAFTProjected],
                 [diag].[RxHCCNumber],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ServiceEndDate],
                 [diag].[MAO004ResponseID]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[PartDRAFT] = [drv].[RAFT]
           AND [rps].[RxHCCNumber] = [drv].[RxHCCNumber]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[MinThruDate] = [drv].[ServiceEndDate]
           AND [rps].[MinThruDateSeqNum] = [drv].MAO004ResponseID;

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

/* Set value of [Min_ThruDate_DiagCD],[Min_ThruDate_PCN], [Thru_Priority_Processed_By], [Thru_Priority_FileID],[Thru_Priority_RAPS_Source_ID],[tbl_Intermediate_EDS] in the rev.SummaryPartDRskAdjEDSPreliminary table  */

UPDATE [rps]
SET [rps].[MinThruDateDiagCD] = [diag].[DiagnosisCode],
    [rps].[MinThruDatePCN] = [diag].[DerivedPatientControlNumber],
    [rps].[ThruPriorityProcessedBy] = [diag].[PlanSubmissionDate],
    [rps].[ThruPriorityFileID] = [diag].[FileImportID],
    [rps].[ThruPriorityRAPSSourceID] = 99
FROM [rev].[IntermediateEDSPartD] [rps]
    JOIN [etl].[SummaryIntermediatePartDRskAdjEDSPreliminary] [diag]
        ON [diag].[MAO004ResponseDiagnosisCodeID] = [rps].[MinThruDateDiagID]
           AND [diag].[HICN] = [rps].[HICN]
           AND [diag].[PaymentYear] = [rps].[PaymentYear]
WHERE [diag].[VoidIndicator] = 0
      AND [diag].[RiskAdjustable] = 1;

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

UPDATE [a1]
SET [a1].[IMFFlag] = 3
FROM [rev].[IntermediateEDSPartD] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE [a1].[MinProcessBy] > [py].[MidYear_Sweep_Date];

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

UPDATE [a1]
SET [a1].[IMFFlag] = 2
FROM [rev].[IntermediateEDSPartD] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          (
              [a1].[MinProcessBy] > [py].[Initial_Sweep_Date]
              AND [a1].[MinProcessBy] <= [py].[MidYear_Sweep_Date]
          )
          OR
          (
              [a1].[MinProcessBy] <= [py].[Initial_Sweep_Date]
              AND [a1].[ProcessedPriorityThruDate] > [py].[Lagged_Thru_Date]
          )
      );

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

UPDATE [a1]
SET [a1].[IMFFlag] = 1
FROM [rev].[IntermediateEDSPartD] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          [a1].[MinProcessBy] <= [py].[Initial_Sweep_Date]
          AND [a1].[ProcessedPriorityThruDate] <= [py].[Lagged_Thru_Date]
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

UPDATE [a1]
SET [a1].[RxHCCLabel] = 'DEL-' + [a1].[RxHCCLabel]
FROM [rev].[IntermediateEDSPartD] [a1]
WHERE [a1].[Deleted] = 'D';

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

UPDATE [t1]
SET [t1].[RxHCCLabel] = [t2].[HCCNew]
FROM [rev].[IntermediateEDSPartD] [t1]
    JOIN
    (
        SELECT [HCCNew] = CASE
                              WHEN [drp].[IMFFlag] >= [kep].[IMFFlag] THEN
                                  'HIER-' + [drp].[RxHCCLabel]
                              ELSE
                                  [drp].[RxHCCLabel]
                          END,
               [drp].[RxHCCLabel],
               [drp].[HICN],
               [drp].[IMFFlag],
               [drp].[PaymentYear],
               [drp].[MinProcessBy],
               [drp].[PartDRAFT],
               [drp].[MinThruDate]
        FROM [rev].[IntermediateEDSPartD] [drp]
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                ON [hier].[HCC_DROP_NUMBER] = [drp].[RxHCCNumber]
                   AND [hier].[Payment_Year] = [drp].[PaymentYear]
                   AND [hier].[RA_FACTOR_TYPE] = [drp].[PartDRAFT]
                   AND [hier].[Part_C_D_Flag] = 'D'
                   AND LEFT([hier].[HCC_DROP], 3) = 'HCC'
                   AND LEFT([drp].[RxHCCLabel], 3) = 'HCC'
            JOIN [rev].[IntermediateEDSPartD] [kep]
                ON [kep].[HICN] = [drp].[HICN]
                   AND [kep].[PartDRAFT] = [drp].[PartDRAFT]
                   AND [kep].[RxHCCNumber] = [hier].[HCC_KEEP_NUMBER]
                   AND [kep].[PaymentYear] = [drp].[PaymentYear]
                   AND LEFT([kep].[RxHCCLabel], 3) = 'HCC'
        GROUP BY [drp].[RxHCCLabel],
                 [drp].[HICN],
                 [drp].[IMFFlag],
                 [drp].[PaymentYear],
                 [drp].[MinProcessBy],
                 [drp].[PartDRAFT],
                 [drp].[RxHCCLabel],
                 [drp].[MinThruDate],
                 [kep].[IMFFlag]
    ) [t2]
        ON [t1].[HICN] = [t2].[HICN]
           AND [t1].[RxHCCLabel] = [t2].[RxHCCLabel]
           AND [t1].[IMFFlag] = [t2].[IMFFlag]
           AND [t1].[PaymentYear] = [t2].[PaymentYear]
           AND [t1].[MinProcessBy] = [t2].[MinProcessBy]
           AND [t1].[PartDRAFT] = [t2].[PartDRAFT]
           AND [t1].[MinThruDate] = [t2].[MinThruDate];

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

UPDATE [t3]
SET [t3].[RxHCCLabel] = [t2].[HCCNew]
FROM [rev].[IntermediateEDSPartD] [t3]
    JOIN
    (
        SELECT
            /* HMF Notes: ROW_NUMBER(): Answers the question How many times does this following combination occur? */
            [RowNum] = ROW_NUMBER() OVER (PARTITION BY [t1].[RxHCCLabel],
                                                       [t1].[HICN],
                                                       [t1].[IMFFlag],
                                                       [t1].[PaymentYear],
                                                       [t1].[MinProcessBy],
                                                       [t1].[PartDRAFT],
                                                       [t1].[MinThruDate]
                                          ORDER BY ([t1].[HICN])
                                         ),
            [t1].[RxHCCLabel],
            [t1].[HCCNew],
            [t1].[HICN],
            [t1].[IMFFlag],
            [t1].[PaymentYear],
            [t1].[MinProcessBy],
            [t1].[PartDRAFT],
            [t1].[MinThruDate]
        FROM
        (
            SELECT [drp].[RxHCCLabel],
                   [HCCNew] = CASE
                                  WHEN [drp].[IMFFlag] < [kep].[IMFFlag] THEN
                                      'INCR-' + [drp].[RxHCCLabel]
                                  ELSE
                                      [drp].[RxHCCLabel]
                              END,
                   [drp].[HICN],
                   [drp].[IMFFlag],
                   [drp].[PaymentYear],
                   [drp].[MinProcessBy],
                   [drp].[PartDRAFT],
                   [drp].[MinThruDate]
            FROM [rev].[IntermediateEDSPartD] [drp]
                JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                    ON [hier].[HCC_DROP_NUMBER] = [drp].[RxHCCNumber]
                       AND [hier].[Payment_Year] = [drp].[PaymentYear]
                       AND [hier].[RA_FACTOR_TYPE] = [drp].[PartDRAFT]
                       AND [hier].[Part_C_D_Flag] = 'D'
                       AND LEFT([hier].[HCC_DROP], 3) = 'HCC'
                       AND LEFT([drp].[RxHCCLabel], 3) = 'HCC'
                JOIN [rev].[IntermediateEDSPartD] [kep]
                    ON [kep].[HICN] = [drp].[HICN]
                       AND [kep].[PartDRAFT] = [drp].[PartDRAFT]
                       AND [kep].[RxHCCNumber] = [hier].[HCC_KEEP_NUMBER]
                       AND [kep].[PaymentYear] = [drp].[PaymentYear]
                       AND LEFT([kep].[RxHCCLabel], 3) = 'HCC'
        ) [t1]
    ) [t2]
        ON [t2].[HICN] = [t3].[HICN]
           AND [t2].[IMFFlag] = [t3].[IMFFlag]
           AND [t2].[PaymentYear] = [t3].[PaymentYear]
           AND [t2].[MinProcessBy] = [t3].[MinProcessBy]
           AND [t2].[PartDRAFT] = [t3].[PartDRAFT]
           AND [t2].[MinThruDate] = [t3].[MinThruDate]
           AND [t2].[RxHCCLabel] = [t3].[RxHCCLabel]
WHERE [t2].[RowNum] = 1;


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '017.5',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/* Truncate the ETL Summary PartDRskAdjEDS Table */

if (object_id('[etl].[SummaryPartDRskAdjEDS]') is not null)

BEGIN
    
   Truncate table [etl].[SummaryPartDRskAdjEDS];
 
End


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

SET @RowCount = 0;



/* Insert into [etl].[SummaryPartDRskAdjEDS] table */

INSERT INTO [etl].[SummaryPartDRskAdjEDS]
(
    [PaymentYear],
    [HICN],
    [PaymStart],
    [ModelYear],
    [Factorcategory],
    [ESRD],
    [Hospice],
    [RxHCCLabel],
    [Factor],
    [PartDRAFTRestated],
    [PartDRAFTMMR],
    [RxHCCNumber],
    [MinProcessBy],
    [MinThruDate],
    [MinProcessBySeqNum],
    [MinThruDateSeqNum],
    [MinProcessbyDiagCD],
    [MinThruDateDiagCD],
    [MinProcessByPCN],
    [MinThruDatePCN],
    [ProcessedPriorityThrudate],
    [ThruPriorityProcessedby],
    [ProcessedPriorityFileID],
    [ProcessedPriorityRAPSSourceID],
    [ProcessedPriorityProviderID],
    [ProcessedPriorityRAC],
    [ThruPriorityFileID],
    [ThruPriorityRAPSSourceID],
    [ThruPriorityProviderID],
    [ThruPriorityRAC],
    [IMFFlag],
    [RxHCCLabelOrig],
    [MinProcessByMAO004ResponseDiagnosisCodeId],
    [MinThruDateMAO004ResponseDiagnosisCodeId],
    [Aged],
    [LoadDate],
    [UserID],
    [PlanIdentifier]
)
SELECT DISTINCT
       [PaymentYear] = [mmr].[PaymentYear],
       [HICN] = [rskfct].[HICN],
       [PaymStart] = [mmr].[PaymStart],
       [ModelYear] = [rskfct].[PaymentYear],
       [Factorcategory] = 'EDS',
       [ESRD] = [mmr].[ESRD],
       [Hospice] = [mmr].[HOSP],
       [RxHCCLabel] = [rskfct].[RxHCCLabel],
       [Factor] = [rskmod].[Factor],
       [PartDRAFTRestated] = [mmr].[PartDRAFTProjected],
       [PartDRAFTMMR] = [mmr].[PartDRAFTMMR],
       [RxHCCNumber] = [rskfct].[RxHCCNumber],
       [MinProcessBy] = [rskfct].[MinProcessBy],
       [MinThruDate] = [rskfct].[MinThruDate],
       [MinProcessBySeqNum] = [rskfct].[MinProcessBySeqNum],
       [Min_ThruDateSeqNum] = [rskfct].[MinThruDateSeqNum],
       [MinProcessbyDiagCD] = [rskfct].[MinProcessbyDiagCD],
       [MinThruDateDiagCD] = [rskfct].[MinThruDateDiagCD],
       [MinProcessByPCN] = [rskfct].[MinProcessByPCN],
       [MinThruDatePCN] = [rskfct].[MinThruDatePCN],
       [ProcessedPriorityThrudate] = [rskfct].[ProcessedPriorityThruDate],
       [ThruPriorityProcessedby] = [rskfct].[ThruPriorityProcessedBy],
       [ProcessedPriorityFileID] = [rskfct].[ProcessedPriorityFileID],
       [ProcessedPriorityRAPSSourceID] = [rskfct].[ProcessedPriorityRAPSSourceID],
       [ProcessedPriorityProviderID] = [rskfct].[ProcessedPriorityProviderID],
       [ProcessedPriorityRAC] = [rskfct].[ProcessedPriorityRAC],
       [ThruPriorityFileID] = [rskfct].[ThruPriorityFileID],
       [ThruPriorityRAPSSourceID] = [rskfct].[ThruPriorityRAPSSourceID],
       [ThruPriorityProviderID] = [rskfct].[ThruPriorityProviderID],
       [ThruPriorityRAC] = [rskfct].[ThruPriorityRAC],
       [IMFFlag] = [rskfct].[IMFFlag],
       [RxHCCLabelOrig] = [rskfct].[RxHCCLabelOrig],
       [Min_ProcessBy_MAO004ResponseDiagnosisCodeId] = [rskfct].[MinProcessbyDiagID],
       [Min_ThruDate_MAO004ResponseDiagnosisCodeId] = [rskfct].[MinThruDateDiagID],
       [Aged] = [mmr].[PartDAged], --TFS 69226    (RE- 1357)
       [LoadDateTime] = @LoadDateTime,
       [UserID] = CURRENT_USER,
       [PlanIdentifier] = [mmr].[PlanID]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[IntermediateEDSPartD] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[PartDRAFT] = [mmr].[PartDRAFTProjected]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[PaymentYear]
           AND CAST(SUBSTRING([rskmod].[Factor_Description], 4, LEN([rskmod].[Factor_Description]) - 3) AS INT) = [rskfct].[RxHCCNumber]
           AND [rskmod].[Factor_Type] = [mmr].[PartDRAFTProjected]
           AND [rskmod].[Aged] = [mmr].[PartDAged]
WHERE [rskmod].[Part_C_D_Flag] = 'D'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'HCC%';

SET @RowCount = @@rowcount;


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

INSERT INTO [etl].[SummaryPartDRskAdjEDS]
(
    [PaymentYear],
    [HICN],
    [PaymStart],
    [ModelYear],
    [Factorcategory],
    [ESRD],
    [Hospice],
    [RxHCCLabel],
    [Factor],
    [PartDRAFTRestated],
    [PartDRAFTMMR],
    [RxHCCNumber],
    [MinProcessBy],
    [MinThruDate],
    [MinProcessBySeqNum],
    [MinThruDateSeqNum],
    [MinProcessbyDiagCD],
    [MinThruDateDiagCD],
    [MinProcessByPCN],
    [MinThruDatePCN],
    [ProcessedPriorityThrudate],
    [ThruPriorityProcessedby],
    [ProcessedPriorityFileID],
    [ProcessedPriorityRAPSSourceID],
    [ProcessedPriorityProviderID],
    [ProcessedPriorityRAC],
    [ThruPriorityFileID],
    [ThruPriorityRAPSSourceID],
    [ThruPriorityProviderID],
    [ThruPriorityRAC],
    [IMFFlag],
    [RxHCCLabelOrig],
    [MinProcessByMAO004ResponseDiagnosisCodeId],
    [MinThruDateMAO004ResponseDiagnosisCodeId],
    [Aged],
    [LoadDate],
    [UserID],
    [PlanIdentifier]
)
SELECT DISTINCT
       [PaymentYear] = [mmr].[PaymentYear],
       [HICN] = [rskfct].[HICN],
       [PaymStart] = [mmr].[PaymStart],
       [ModelYear] = [rskfct].[PaymentYear],
       [Factorcategory] = 'EDS-Disability',
       [ESRD] = [mmr].[ESRD],
       [Hospice] = [mmr].[HOSP],
       [RxHCCLabel] = [rskfct].[RxHCCLabel],
       [Factor] = [rskmod].[Factor],
       [PartDRAFTRestated] = [mmr].[PartDRAFTProjected],
       [PartDRAFTMMR] = [mmr].[PartDRAFTMMR],
       [RxHCCNumber] = [rskfct].[RxHCCNumber],
       [MinProcessBy] = [rskfct].[MinProcessBy],
       [MinThruDate] = [rskfct].[MinThruDate],
       [MinProcessBySeqNum] = [rskfct].[MinProcessBySeqNum],
       [Min_ThruDateSeqNum] = [rskfct].[MinThruDateSeqNum],
       [MinProcessbyDiagCD] = [rskfct].[MinProcessbyDiagCD],
       [MinThruDateDiagCD] = [rskfct].[MinThruDateDiagCD],
       [MinProcessByPCN] = [rskfct].[MinProcessByPCN],
       [MinThruDatePCN] = [rskfct].[MinThruDatePCN],
       [ProcessedPriorityThrudate] = [rskfct].[ProcessedPriorityThruDate],
       [ThruPriorityProcessedby] = [rskfct].[ThruPriorityProcessedBy],
       [ProcessedPriorityFileID] = [rskfct].[ProcessedPriorityFileID],
       [ProcessedPriorityRAPSSourceID] = [rskfct].[ProcessedPriorityRAPSSourceID],
       [ProcessedPriorityProviderID] = [rskfct].[ProcessedPriorityProviderID],
       [ProcessedPriorityRAC] = [rskfct].[ProcessedPriorityRAC],
       [ThruPriorityFileID] = [rskfct].[ThruPriorityFileID],
       [ThruPriorityRAPSSourceID] = [rskfct].[ThruPriorityRAPSSourceID],
       [ThruPriorityProviderID] = [rskfct].[ThruPriorityProviderID],
       [ThruPriorityRAC] = [rskfct].[ThruPriorityRAC],
       [IMFFlag] = [rskfct].[IMFFlag],
       [RxHCCLabelOrig] = [rskfct].[RxHCCLabelOrig],
       [Min_ProcessBy_MAO004ResponseDiagnosisCodeId] = [rskfct].[MinProcessbyDiagID],
       [Min_ThruDate_MAO004ResponseDiagnosisCodeId] = [rskfct].[MinThruDateDiagID],
       [Aged] = [mmr].[PartDAged],
       [LoadDateTime] = @LoadDateTime,
       [UserID] = CURRENT_USER,
       [PlanIdentifier] = [mmr].[PlanID]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[IntermediateEDSPartD] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[PartDRAFT] = [mmr].[PartDRAFTProjected]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[ModelYear]
           AND CAST(SUBSTRING([rskmod].[Factor_Description], 6, LEN([rskmod].[Factor_Description]) - 5) AS INT) = [rskfct].[RxHCCNumber]
           AND [rskmod].[Factor_Type] = [mmr].[PartDRAFTProjected]
           AND [rskmod].[Aged] = [mmr].[PartDAged]
WHERE [rskmod].[Part_C_D_Flag] = 'D'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'D-HCC%'
      AND [mmr].[RskAdjAgeGrp] < '6565'
      AND [rskfct].[RxHCCLabel] LIKE 'HCC%';

SET @RowCount = ISNULL(@RowCount, 0) + @@rowcount;

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

UPDATE [ed]
SET [ed].[LastAssignedHICN] = ISNULL(   [b].[LastAssignedHICN],
                                        CASE
                                            WHEN ssnri.fnValidateMBI([ed].[HICN]) = 1 THEN
                                                [b].[HICN]
                                        END
                                    )
FROM [etl].[SummaryPartDRskAdjEDS] [ed]
    CROSS APPLY
(
    SELECT TOP 1
           [b].[LastAssignedHICN],
           [b].[HICN]
    FROM [rev].[tbl_Summary_RskAdj_AltHICN] AS [b]
    WHERE [b].[FINALHICN] = [ed].[HICN]
    ORDER BY [LoadDateTime] DESC
) AS [b];




IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '020.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/* Begin: Switch partitions for each PaymentYear */

DECLARE @I INT;
DECLARE @ID INT =
        (
            SELECT COUNT(DISTINCT Payment_Year) FROM [#Refresh_PY]
        );

SET @I = 1;

WHILE (@I <= @ID)
BEGIN

    DECLARE @PaymentYear SMALLINT =
            (
                SELECT [Payment_Year] FROM [#Refresh_PY] WHERE [Refresh_PYId] = @I
            );

    PRINT @PaymentYear;

    BEGIN TRY

        BEGIN TRANSACTION SwitchPartitions;

        TRUNCATE TABLE [out].[SummaryPartDRskAdjEDS];

        -- Switch Partition for History SummaryPartDRskAdjMORD 

        ALTER TABLE [hst].[SummaryPartDRskAdjEDS] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].[SummaryPartDRskAdjEDS] PARTITION $Partition.[pfn_SummPY](@PaymentYear);

        -- Switch Partition for REV SummaryPartDRskAdjMORD 
        ALTER TABLE [rev].[SummaryPartDRskAdjEDS] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [hst].[SummaryPartDRskAdjEDS] PARTITION $Partition.[pfn_SummPY](@PaymentYear);

        -- Switch Partition for ETL SummaryPartDRskAdjMORD	
        ALTER TABLE [etl].[SummaryPartDRskAdjEDS] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [rev].[SummaryPartDRskAdjEDS] PARTITION $Partition.[pfn_SummPY](@PaymentYear);

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

/* End: Switch partitions for each PaymentYear */


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
 
GO
