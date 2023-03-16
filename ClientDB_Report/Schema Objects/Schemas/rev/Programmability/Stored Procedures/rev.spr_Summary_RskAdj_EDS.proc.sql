Create PROC [rev].[spr_Summary_RskAdj_EDS]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS

/**************************************************************************************************************************** 
* Name				:	rev.spr_Summary_RskAdj_EDS																			*
* Type 				:	Stored Procedure																					*
* Author       		:	Mitch Casto																							*
* Date				:	2017-05-08																							*
* Version			:																										*
* Description		: Updates rev.spr_Summary_RskAdj_EDS table with raw MOR data											*
*					Note: This stp is an adaptation from Summary 2.0 rev.spr_Summary_RskAdj_RAPS and will need further work *
*					to optimize the sql.																					*
*																															*
* Version History :																											*
* ======================================================================================================================	*
* Author			Date		Version#    TFS Ticket#			Description													*	
* -----------------	----------  --------    -----------			------------												*
* Mitch Casto		2017-05-08	1.0c		62762 / US62595		Initial														*
* Rakshit Lall		2017-07-28	1.1			66133				Modification to include and load new columns	            *
* D. Waddell        2017-10-11  1.2         67449 / RE-1171     Expanding on the [RAPS_DiagHCC_rollupID] join for this      *
*                                                               section to create accurate results. (section 8 & 11)       	*
* Rakshit Lall		2017-11-14	1.3			68042/ RE-1219		Modified sec 033 and 034 to change the join to OREC			*
* D. Waddell        2018-05-28  1.4         70759/ RE-1889      Load new LastAssignedHICN column in                         *
*                                                               [rev].[tbl_Summary_RskAdj_EDS] table   (Sect. 35.5)         *
* D. Waddell        2018-06-05  1.5         70759/ RE-2127      Bug Fix: modify RE-1889 to fix join and                     *
*                                                               handle NULL LastAssignedHICN in   (Sect. 35.5)              *
* D. Waddell		2019-10-29	1.6			RE-6981				Set Transaction Isolation Level Read to Uncommitted         *
* D. Waddell        2019-12-31  1.7         RE-7316             Implement our new APCC logic for EDS sourced Diagnosis.     *
*                                                               For Payment Year 2020                                       *
* D. Waddell		2020-05-27	1.8			RE-8123/78727       Resolve Null Load Date Time issue                           * 
* Anand				2020-07-20	2.0			RRI-79/79109        Used Intermediate Prelim table. Removed Plan ID from temp table 
*															    calculation
* D. Waddell        2020-11-23  2.1         RRI-349/80114       Fix a bug reported in APCC implementation. Section 033 
*                                                               disable the where APCC is being incorrectly captured in the
*                                                               filter. At the end of the script is the inserts portion. A 
*                                                               new section will need to be added here similar to the style 
*                                                               "EDS-Interactions" insert, specifically tailored for "EDS-APCC"
* Madhuri Suri      2021-12-16  2.2          RRI-1912            Delete Changes Part C 
* Madhuri Suri      2022-05-27  2.3          RRI-2417            RAPS Priority updates
*****************************************************************************************************************************/


SET NOCOUNT ON;
SET STATISTICS IO OFF;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
    [#Refresh_PYId] [INT] IDENTITY(1, 1) NOT NULL PRIMARY KEY,
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

if (object_id('[etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary]') is not null)

BEGIN
    
   Truncate table [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary];
 
End


Insert Into [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary]
(
       [PaymentYear]
      ,[ModelYear]
      ,[HICN]
      ,[PartCRAFTProjected]
      ,[MAO004ResponseID]
	  ,[DiagnosisCode]
      ,[PlanSubmissionDate]
      ,[ServiceEndDate]
      ,[FileImportID]
      ,[MAO004ResponseDiagnosisCodeID]
      ,[DerivedPatientControlNumber]
      ,[Void_Indicator]
      ,[RiskAdjustable]
      ,[Deleted]
      ,[HCC_Label]
      ,[HCC_Number]
)
SELECT DISTINCT 
       [PaymentYear]
      ,[ModelYear]
      ,[HICN]
      ,[PartCRAFTProjected]
      ,[MAO004ResponseID]
	  ,[DiagnosisCode]
      ,[PlanSubmissionDate]
      ,[ServiceEndDate]
      ,[FileImportID]
      ,[MAO004ResponseDiagnosisCodeID]
      ,[DerivedPatientControlNumber]
      ,[Void_Indicator]
      ,[RiskAdjustable]
      ,[Deleted]
      ,[HCC_Label]
      ,[HCC_Number]

  FROM [rev].[tbl_Summary_RskAdj_EDS_Preliminary] [rps]
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

if (object_id('[rev].[tbl_Intermediate_EDS]') is not null)

BEGIN
    
   Truncate table [rev].[tbl_Intermediate_EDS];
 
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

INSERT INTO [rev].[tbl_Intermediate_EDS]
(
    [HICN],
    [RAFT],
    [HCC],
    [HCC_ORIG],
    [HCC_Number],
    [Min_Process_By],
    [Min_Thru],
    [Deleted],
    [PaymentYear],
    [ModelYear],
    [LoadDateTime]
)
SELECT DISTINCT
       [HICN] = [rps].[HICN],
       [RAFT] = [rps].[PartCRAFTProjected],
       [HCC] = [rps].[HCC_Label],
       [HCC_ORIG] = [rps].[HCC_Label],
       [HCC_Number] = [rps].[HCC_Number],
       [Min_Process_By] = MIN([rps].[PlanSubmissionDate]),
       [Min_Thru] = MIN([rps].[ServiceEndDate]),
       [Deleted] = ISNULL([rps].[Deleted], 'A'),
       [PaymentYear] = [rps].[PaymentYear],
       [ModelYear] = [rps].[ModelYear],
       [LoadDateTime] = @LoadDateTime
FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [rps]
WHERE (
          [rps].[Deleted] <> 'D' --RRI 1912
      )
      AND
      (
          [rps].[Void_Indicator] IS NULL
          OR [rps].[Void_Indicator] = 0
      )
      AND [rps].[RiskAdjustable] = 1
GROUP BY 
         [rps].[HICN],
         [rps].[PartCRAFTProjected],
         [rps].[HCC_Label],
         [rps].[HCC_Number],
         ISNULL([rps].[Deleted], 'A'),
         [rps].[PaymentYear],
         [rps].[ModelYear];

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

INSERT INTO [rev].[tbl_Intermediate_EDS]
(
    [HICN],
    [RAFT],
    [HCC],
    [HCC_ORIG],
    [HCC_Number],
    [Min_Process_By],
    [Min_Thru],
    [Deleted],
    [PaymentYear],
    [ModelYear],
    [LoadDateTime]
)
SELECT DISTINCT
       [HICN] = [rps].[HICN],
       [RAFT] = [rps].[PartCRAFTProjected],
       [HCC] = [rps].[HCC_Label],
       [HCC_ORIG] = [rps].[HCC_Label],
       [HCC_Number] = [rps].[HCC_Number],
       [Min_Process_By] = MAX([rps].[PlanSubmissionDate]),
       [Min_Thru] = MAX([rps].[ServiceEndDate]), ----NMI
       [Deleted] = [rps].[Deleted],
       [PaymentYear] = [rps].[PaymentYear],
       [ModelYear] = [rps].[ModelYear],
       [LoadDateTime] = @LoadDateTime
FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [rps]
    LEFT JOIN [rev].[tbl_Intermediate_EDS] [rpsact]
        ON [rpsact].[HICN] = [rps].[HICN]
           AND [rpsact].[RAFT] = [rps].[PartCRAFTProjected]
           AND [rpsact].[HCC] = [rps].[HCC_Label]
           AND [rpsact].[HCC_Number] = [rps].[HCC_Number]
           AND [rpsact].[Deleted] = 'A'
           AND [rpsact].[PaymentYear] = [rps].[PaymentYear]
           AND [rpsact].[ModelYear] = [rps].[ModelYear]
WHERE [rpsact].[HCC] IS NULL
      AND [rps].[Deleted] = 'D'
      AND [rps].[Void_Indicator] = 0
GROUP BY 
         [rps].[HICN],
         [rps].[PartCRAFTProjected],
         [rps].[HCC_Label],
         [rps].[HCC_Number],
         [rps].[Deleted],
         [rps].[PaymentYear],
         [rps].[ModelYear];

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


--Alter Update to negate impact of RAPS sourced HCCs being labeled as other in Valuation by prioritizing EDS
--Second Update uses RAPS if there is no EDS source

UPDATE [rps]
SET [rps].[Min_ProcessBy_SeqNum] = [drv].[MAO004ResponseID]
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN
    (
        SELECT [MAO004ResponseID] = MIN([diag].[MAO004ResponseID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[PlanSubmissionDate]
        FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        WHERE [diag].[Void_Indicator] = 0
              AND [diag].[RiskAdjustable] = 1
              AND [diag].[DerivedPatientControlNumber] IS NOT NULL ---  Prioritizing to EDS 5/31
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[PlanSubmissionDate]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Process_By] = [drv].[PlanSubmissionDate];

-----Added to pull the RAPS side of data Start 5/31
UPDATE [rps]
SET [rps].[Min_ProcessBy_SeqNum] = [drv].[MAO004ResponseID]
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN
    (
        SELECT [MAO004ResponseID] = MIN([diag].[MAO004ResponseID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[PlanSubmissionDate]
        FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        WHERE [diag].[Void_Indicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[PlanSubmissionDate]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Process_By] = [drv].[PlanSubmissionDate]
		WHERE [rps].[Min_ProcessBy_SeqNum] IS NULL;
-----Added to pull the RAPS side of data End 5/31

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

UPDATE [rps]
SET [rps].[Min_Processby_DiagID] = [drv].[MAO004ResponseDiagnosisCodeID]
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN
    (
        SELECT [MAO004ResponseDiagnosisCodeID] = MIN([diag].[MAO004ResponseDiagnosisCodeID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[PlanSubmissionDate],
               [diag].[MAO004ResponseID]
        FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        WHERE [diag].[Void_Indicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[PlanSubmissionDate],
                 [diag].[MAO004ResponseID]
    ) [drv]
        ON  [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Process_By] = [drv].[PlanSubmissionDate]
           AND [rps].[Min_ProcessBy_SeqNum] = [drv].[MAO004ResponseID];

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

UPDATE [rps]
SET [rps].[Min_Processby_DiagCD] = [diag].[DiagnosisCode],
    [rps].[Min_ProcessBy_PCN] = [diag].[DerivedPatientControlNumber],
    [rps].[Processed_Priority_Thru_Date] = [diag].[ServiceEndDate],
    [rps].[Processed_Priority_FileID] = [diag].[FileImportID],
    [rps].[Processed_Priority_RAPS_Source_ID] = 99
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        ON [diag].[MAO004ResponseDiagnosisCodeID] = [rps].[Min_Processby_DiagID]
           AND [diag].[HICN] = [rps].[HICN] -- RE - 1171 FS 67449
           AND [diag].[PaymentYear] = [rps].[PaymentYear]
WHERE [diag].[Void_Indicator] = 0
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

UPDATE [rps]
SET [rps].[Min_Thru_SeqNum] = [drv].[MAO004ResponseID]
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN
    (
        SELECT [MAO004ResponseID] = MIN([diag].[MAO004ResponseID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ServiceEndDate]
        FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        WHERE [diag].[Void_Indicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ServiceEndDate]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Thru] = [drv].[ServiceEndDate];

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

--HasanMF 10/10/2017: 
--Expanding on the [RAPS_DiagHCC_rollupID] join for this section to create accurate results. 
--This change will correct for ProcessedPriorityThruDate and ThruPriorityProcessedBy to cross over into different PaymentYear ranges.



UPDATE [rps]
SET [rps].[Min_ThruDate_DiagID] = [drv].[MAO004ResponseDiagnosisCodeID]
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN
    (
        SELECT [MAO004ResponseDiagnosisCodeID] = MIN([diag].[MAO004ResponseDiagnosisCodeID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ServiceEndDate],
               [diag].[MAO004ResponseID]
        FROM [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        WHERE [diag].[Void_Indicator] = 0
              AND [diag].[RiskAdjustable] = 1
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ServiceEndDate],
                 [diag].[MAO004ResponseID]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Thru] = [drv].[ServiceEndDate]
           AND [rps].[Min_Thru_SeqNum] = [drv].MAO004ResponseID;

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

UPDATE [rps]
SET [rps].[Min_ThruDate_DiagCD] = [diag].[DiagnosisCode],
    [rps].[Min_ThruDate_PCN] = [diag].[DerivedPatientControlNumber],
    [rps].[Thru_Priority_Processed_By] = [diag].[PlanSubmissionDate],
    [rps].[Thru_Priority_FileID] = [diag].[FileImportID],
    [rps].[Thru_Priority_RAPS_Source_ID] = 99
FROM [rev].[tbl_Intermediate_EDS] [rps]
    JOIN [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] [diag]
        ON [diag].[MAO004ResponseDiagnosisCodeID] = [rps].[Min_ThruDate_DiagID]
           AND [diag].[HICN] = [rps].[HICN] -- RE - 1171 FS 67449
           AND [diag].[PaymentYear] = [rps].[PaymentYear]
WHERE [diag].[Void_Indicator] = 0
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
FROM [rev].[tbl_Intermediate_EDS] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE [a1].[Min_Process_By] > [py].[MidYear_Sweep_Date];

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
FROM [rev].[tbl_Intermediate_EDS] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          (
              [a1].[Min_Process_By] > [py].[Initial_Sweep_Date]
              AND [a1].[Min_Process_By] <= [py].[MidYear_Sweep_Date]
          )
          OR
          (
              [a1].[Min_Process_By] <= [py].[Initial_Sweep_Date]
              AND [a1].[Processed_Priority_Thru_Date] > [py].[Lagged_Thru_Date]
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
FROM [rev].[tbl_Intermediate_EDS] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          [a1].[Min_Process_By] <= [py].[Initial_Sweep_Date]
          AND [a1].[Processed_Priority_Thru_Date] <= [py].[Lagged_Thru_Date]
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

UPDATE [rev].[tbl_Intermediate_EDS]
SET [HCC] = 'DEL-' + [HCC]
WHERE [Deleted] = 'D';

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
SET [t1].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_EDS] [t1]
    JOIN
    (
        SELECT [HCCNew] = CASE
                              WHEN [drp].[IMFFlag] >= [kep].[IMFFlag] THEN
                                  'HIER-' + [drp].[HCC]
                              ELSE
                                  [drp].[HCC]
                          END,
               [drp].[HCC],
               [drp].[HICN],
               [drp].[IMFFlag],
               [drp].[PaymentYear],
               [drp].[ModelYear],
               [drp].[Min_Process_By],
               [drp].[RAFT],
               [drp].[Min_Thru]
        FROM [rev].[tbl_Intermediate_EDS] [drp]
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                ON [hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
                   AND [hier].[Payment_Year] = [drp].[ModelYear]
                   AND [hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
                   AND [hier].[Part_C_D_Flag] = 'C'
                   AND LEFT([hier].[HCC_DROP], 3) = 'HCC'
                   AND LEFT([drp].[HCC], 3) = 'HCC'
            JOIN [rev].[tbl_Intermediate_EDS] [kep]
                ON [kep].[HICN] = [drp].[HICN]
                   AND [kep].[RAFT] = [drp].[RAFT]
                   AND [kep].[HCC_Number] = [hier].[HCC_KEEP_NUMBER]
                   AND [kep].[PaymentYear] = [drp].[PaymentYear]
                   AND [kep].[ModelYear] = [drp].[ModelYear]
                   AND LEFT([kep].[HCC], 3) = 'HCC'
        GROUP BY [drp].[HCC],
                 [drp].[HICN],
                 [drp].[IMFFlag],
                 [drp].[PaymentYear],
                 [drp].[ModelYear],
                 [drp].[Min_Process_By],
                 [drp].[RAFT],
                 [drp].[Min_Thru],
                 [kep].[IMFFlag]
    ) [t2]
        ON [t1].[HICN] = [t2].[HICN]
           AND [t1].[HCC] = [t2].[HCC]
           AND [t1].[IMFFlag] = [t2].[IMFFlag]
           AND [t1].[PaymentYear] = [t2].[PaymentYear]
           AND [t1].[ModelYear] = [t2].[ModelYear]
           AND [t1].[Min_Process_By] = [t2].[Min_Process_By]
           AND [t1].[RAFT] = [t2].[RAFT]
           AND [t1].[Min_Thru] = [t2].[Min_Thru];

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
SET [t3].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_EDS] [t3]
    JOIN
    (
        SELECT
            /* HMF Notes: ROW_NUMBER(): Answers the question How many times does this following combination occur? */
            [RowNum] = ROW_NUMBER() OVER (PARTITION BY [t1].[HCC],
                                                       [t1].[HICN],
                                                       [t1].[IMFFlag],
                                                       [t1].[PaymentYear],
                                                       [t1].[ModelYear],
                                                       [t1].[Min_Process_By],
                                                       [t1].[RAFT],
                                                       [t1].[Min_Thru]
                                          ORDER BY ([t1].[HICN])
                                         ),
            [t1].[HCC],
            [t1].[HCCNew],
            [t1].[HICN],
            [t1].[IMFFlag],
            [t1].[PaymentYear],
            [t1].[ModelYear],
            [t1].[Min_Process_By],
            [t1].[RAFT],
            [t1].[Min_Thru]
        FROM
        (
            SELECT [drp].[HCC],
                   [HCCNew] = CASE
                                  WHEN [drp].[IMFFlag] < [kep].[IMFFlag] THEN
                                      'INCR-' + [drp].[HCC]
                                  ELSE
                                      [drp].[HCC]
                              END,
                   [drp].[HICN],
                   [drp].[IMFFlag],
                   [drp].[PaymentYear],
                   [drp].[ModelYear],
                   [drp].[Min_Process_By],
                   [drp].[RAFT],
                   [drp].[Min_Thru]
            FROM [rev].[tbl_Intermediate_EDS] [drp]
                JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                    ON [hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
                       AND [hier].[Payment_Year] = [drp].[ModelYear]
                       AND [hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
                       AND [hier].[Part_C_D_Flag] = 'C'
                       AND LEFT([hier].[HCC_DROP], 3) = 'HCC'
                       AND LEFT([drp].[HCC], 3) = 'HCC'
                JOIN [rev].[tbl_Intermediate_EDS] [kep]
                    ON [kep].[HICN] = [drp].[HICN]
                       AND [kep].[RAFT] = [drp].[RAFT]
                       AND [kep].[HCC_Number] = [hier].[HCC_KEEP_NUMBER]
                       AND [kep].[PaymentYear] = [drp].[PaymentYear]
                       AND [kep].[ModelYear] = [drp].[ModelYear]
                       AND LEFT([kep].[HCC], 3) = 'HCC'
        ) [t1]
    ) [t2]
        ON [t2].[HICN] = [t3].[HICN]
           AND [t2].[IMFFlag] = [t3].[IMFFlag]
           AND [t2].[PaymentYear] = [t3].[PaymentYear]
           AND [t2].[ModelYear] = [t3].[ModelYear]
           AND [t2].[Min_Process_By] = [t3].[Min_Process_By]
           AND [t2].[RAFT] = [t3].[RAFT]
           AND [t2].[Min_Thru] = [t3].[Min_Thru]
           AND [t2].[HCC] = [t3].[HCC]
WHERE [t2].[RowNum] = 1;

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


/*  Beginning of RE-7316 Section */
--Create  #HCC_MaxProcessBy  temp table which will retain the latest occuring regular HCC per member. This table will be used to 
IF (OBJECT_ID('tempdb.dbo.#HCC_MaxProcessBy') IS NOT NULL)
BEGIN
    DROP TABLE #HCC_MaxProcessBy;
END;

CREATE TABLE #HCC_MAXPROCESSBY
(
    ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
    [PAYMENTYEAR] INT NULL,
    [MODELYEAR] INT NULL,
    [RAFT] CHAR(3) NULL,
    [HICN] VARCHAR(12) NULL,
    [HCC] VARCHAR(50) NULL,
    [MAXPROCESSBY] DATETIME NULL
);

INSERT INTO #HCC_MAXPROCESSBY
(
    [HICN],
    [PAYMENTYEAR],
    [MODELYEAR],
    [RAFT],
    [MAXPROCESSBY]
)
SELECT a.HICN,
       a.PaymentYear,
       a.ModelYear,
       a.RAFT,
       MAX(a.Min_Process_By) AS MaxProcessBy
FROM rev.tbl_Intermediate_EDS a
    JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC (NOLOCK) C --select top 1 * from [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC
        ON a.PaymentYear = C.PaymentYear
           AND a.ModelYear = C.ModelYear
           AND a.RAFT = C.RAFactorType
WHERE HCC LIKE 'HCC%'
      AND C.APCCFlag = 'Y'
      AND C.SubmissionModel = 'EDS'
GROUP BY a.hicn,
         a.PaymentYear,
         a.ModelYear,
         a.RAFT;

UPDATE a
SET a.HCC = b.HCC
FROM #HCC_MAXPROCESSBY a
    JOIN rev.tbl_Intermediate_EDS b
        ON a.HICN = b.HICN
           AND a.PAYMENTYEAR = b.PAYMENTYEAR
           AND a.MODELYEAR = b.MODELYEAR
           AND a.RAFT = b.RAFT
           AND a.MAXPROCESSBY = b.Min_Process_By
WHERE b.HCC LIKE 'HCC%';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '018.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;




--Create working space for APCC logic - Temp copy of Intermediate_EDS 
IF (OBJECT_ID('tempdb.dbo.#APCC_Insert') IS NOT NULL)
BEGIN
    DROP TABLE [#APCC_Insert];
END;

CREATE TABLE [#APCC_Insert]
(
    ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
    [PaymentYear] [INT] NULL,
    [ModelYear] [INT] NULL,
    [HICN] [VARCHAR](12) NULL,
    [RAFT] [CHAR](3) NULL,
    [HCC] [VARCHAR](50) NULL,
    [HCC_Number] [INT] NULL,
    [Min_Process_By] [DATETIME] NULL,
    [Min_Thru] [DATETIME] NULL,
    [Min_ProcessBy_SeqNum] [INT] NULL,
    [Min_Thru_SeqNum] [INT] NULL,
    [Deleted] [CHAR](1) NULL,
    [Min_Processby_DiagID] [INT] NULL,
    [Min_ThruDate_DiagID] [INT] NULL,
    [Min_Processby_DiagCD] [VARCHAR](7) NULL,
    [Min_ThruDate_DiagCD] [VARCHAR](7) NULL,
    [Min_ProcessBy_PCN] [VARCHAR](40) NULL,
    [Min_ThruDate_PCN] [VARCHAR](40) NULL,
    [Processed_Priority_Thru_Date] [DATETIME] NULL,
    [Thru_Priority_Processed_By] [DATETIME] NULL,
    [Processed_Priority_FileID] [VARCHAR](18) NULL,
    [Processed_Priority_RAPS_Source_ID] [INT] NULL,
    [Processed_Priority_Provider_ID] [VARCHAR](40) NULL,
    [Processed_Priority_RAC] [CHAR](1) NULL,
    [Thru_Priority_FileID] [VARCHAR](18) NULL,
    [Thru_Priority_RAPS_Source_ID] [INT] NULL,
    [Thru_Priority_Provider_ID] [VARCHAR](40) NULL,
    [Thru_Priority_RAC] [CHAR](1) NULL,
    [IMFFlag] [SMALLINT] NULL,
    [HCC_ORIG] [VARCHAR](50) NULL
);

--insert APCC into temp copy
INSERT INTO #APCC_Insert
(
    [PaymentYear],
    [ModelYear],
    [HICN],
    [RAFT],
    [HCC],
    [HCC_Number],
    [HCC_ORIG]
)
SELECT [PaymentYear] = a.PaymentYear,
       [ModelYear] = a.ModelYear,
       [HICN] = a.HICN,
       [RAFT] = a.RAFT,
       --APCC logic portion
       [HCC] = CASE
                   WHEN COUNT(DISTINCT a.HCC) > 9 THEN
                       'D10P'
                   ELSE
                       'D' + CAST(COUNT(DISTINCT a.HCC) AS VARCHAR)
               END,
       [HCC_Number] = COUNT(DISTINCT a.HCC),
       [HCC_ORIG] = CASE
                        WHEN COUNT(DISTINCT a.HCC) > 9 THEN
                            'D10P'
                        ELSE
                            'D' + CAST(COUNT(DISTINCT a.HCC) AS VARCHAR)
                    END
FROM rev.tbl_Intermediate_EDS a
    JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC r
        ON a.PaymentYear = r.PaymentYear
           AND a.ModelYear = r.ModelYear
           AND a.RAFT = r.RAFactorType
WHERE r.APCCFlag = 'Y'
      AND r.SubmissionModel = 'EDS'
      AND a.HCC LIKE 'HCC%'
GROUP BY a.PaymentYear,
         a.ModelYear,
         a.RAFT,
         a.HICN;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '018.2',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;




--update APCC records with MaxProcessby per HICN (#HCC_MAXPROCESSBY)
UPDATE a
SET 
    a.[Min_Process_By] = b.[Min_Process_By],
    a.[Min_Thru] = b.[Min_Thru],
    a.[Min_ProcessBy_SeqNum] = b.[Min_ProcessBy_SeqNum],
    a.[Min_Thru_SeqNum] = b.[Min_Thru_SeqNum],
    a.[Deleted] = b.[Deleted],
    a.[Min_Processby_DiagID] = b.[Min_Processby_DiagID],
    a.[Min_ThruDate_DiagID] = b.[Min_ThruDate_DiagID],
    a.[Min_Processby_DiagCD] = b.[Min_Processby_DiagCD],
    a.[Min_ThruDate_DiagCD] = b.[Min_ThruDate_DiagCD],
    a.[Min_ProcessBy_PCN] = b.[Min_ProcessBy_PCN],
    a.[Min_ThruDate_PCN] = b.[Min_ThruDate_PCN],
    a.[Processed_Priority_Thru_Date] = b.[Processed_Priority_Thru_Date],
    a.[Thru_Priority_Processed_By] = b.[Thru_Priority_Processed_By],
    a.[Processed_Priority_FileID] = b.[Processed_Priority_FileID],
    a.[Processed_Priority_RAPS_Source_ID] = b.[Processed_Priority_RAPS_Source_ID],
    a.[Processed_Priority_Provider_ID] = b.[Processed_Priority_Provider_ID],
    a.[Processed_Priority_RAC] = b.[Processed_Priority_RAC],
    a.[Thru_Priority_FileID] = b.[Thru_Priority_FileID],
    a.[Thru_Priority_RAPS_Source_ID] = b.[Thru_Priority_RAPS_Source_ID],
    a.[Thru_Priority_Provider_ID] = b.[Thru_Priority_Provider_ID],
    a.[Thru_Priority_RAC] = b.[Thru_Priority_RAC],
    a.[IMFFlag] = b.[IMFFlag]
FROM #APCC_Insert a
    JOIN rev.tbl_Intermediate_EDS b
        ON a.PaymentYear = b.PaymentYear
           AND a.ModelYear = b.ModelYear
           AND a.HICN = b.HICN
           AND a.RAFT = b.RAFT
    JOIN #HCC_MAXPROCESSBY c
        ON b.PaymentYear = c.PAYMENTYEAR
           AND b.ModelYear = c.MODELYEAR
           AND b.RAFT = c.RAFT
           AND b.HICN = c.HICN
           AND b.HCC = c.HCC
           AND b.Min_Process_By = c.MAXPROCESSBY;


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '018.3',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



--insert temp into main Intermediate_EDS
INSERT INTO rev.tbl_Intermediate_EDS
(
    [PaymentYear],
    [ModelYear],
    [HICN],
    [RAFT],
    [HCC],
    [HCC_Number],
    [Min_Process_By],
    [Min_Thru],
    [Min_ProcessBy_SeqNum],
    [Min_Thru_SeqNum],
    [Deleted],
    [Min_Processby_DiagID],
    [Min_ThruDate_DiagID],
    [Min_Processby_DiagCD],
    [Min_ThruDate_DiagCD],
    [Min_ProcessBy_PCN],
    [Min_ThruDate_PCN],
    [Processed_Priority_Thru_Date],
    [Thru_Priority_Processed_By],
    [Processed_Priority_FileID],
    [Processed_Priority_RAPS_Source_ID],
    [Processed_Priority_Provider_ID],
    [Processed_Priority_RAC],
    [Thru_Priority_FileID],
    [Thru_Priority_RAPS_Source_ID],
    [Thru_Priority_Provider_ID],
    [Thru_Priority_RAC],
    [IMFFlag],
    [HCC_ORIG],
	[LoadDateTime]
)
SELECT [PaymentYear],
       [ModelYear],
       [HICN],
       [RAFT],
       [HCC],
       [HCC_Number],
       [Min_Process_By],
       [Min_Thru],
       [Min_ProcessBy_SeqNum],
       [Min_Thru_SeqNum],
       [Deleted],
       [Min_Processby_DiagID],
       [Min_ThruDate_DiagID],
       [Min_Processby_DiagCD],
       [Min_ThruDate_DiagCD],
       [Min_ProcessBy_PCN],
       [Min_ThruDate_PCN],
       [Processed_Priority_Thru_Date],
       [Thru_Priority_Processed_By],
       [Processed_Priority_FileID],
       [Processed_Priority_RAPS_Source_ID],
       [Processed_Priority_Provider_ID],
       [Processed_Priority_RAC],
       [Thru_Priority_FileID],
       [Thru_Priority_RAPS_Source_ID],
       [Thru_Priority_Provider_ID],
       [Thru_Priority_RAC],
       [IMFFlag],
       [HCC_ORIG],
	   [LoadDateTime] = ISNULL(@LoadDateTime,GETDATE())
FROM #APCC_Insert;

/*  End of RE-7316 Section */


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '018.5',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

--REFERENCE:
--\\hrp.local\Shares\Departments\InformationSolutions\TFS Tickets\TASK36379 - Documenting dbo.spr_EstRecv_MMR_RAPS_MOR_Summary\Summary_RskAdj_Requirements_20160511_HMF.xlsx
--Tab:"RAPS INT work flow"

--HCC Interactions for RAPS MOR Combined

if (object_id('[rev].[tbl_Intermediate_EDS_INT]') is not null)

BEGIN
    
   Truncate table [rev].[tbl_Intermediate_EDS_INT];
 
End

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

INSERT INTO [rev].[tbl_Intermediate_EDS_INT]
(
    [PaymentYear],
    [ModelYear],
    [HICN],
    [RAFT],
    [HCC],
    [HCC_ORIG],
    [HCC_Number],
    [HCC_Number1],
    [HCC_Number2],
    [HCC_Number3],
    [Min_Process_By],
    [Min_Thru],
    [LoadDateTime]
)
SELECT [PaymentYear] = [hcc1].[PaymentYear],
       [ModelYear] = [hcc1].[ModelYear],
       [HICN] = [hcc1].[HICN],
       [RAFT] = [hcc1].[RAFT],
       [HCC] = [int].[Interaction_Label],
       [HCC_ORIG] = [int].[Interaction_Label],
       [HCC_Number] = CAST(RIGHT([int].[Interaction_Label], LEN([int].[Interaction_Label]) - 3) AS INT),
       [HCC_Number1] = [hcc1].[HCC_Number],
       [HCC_Number2] = [hcc2].[HCC_Number],
       [HCC_Number3] = [hcc3].[HCC_Number],
       [Min_Process_By] =
       (
           SELECT MAX([x].[date])
           FROM
           (
               VALUES
                   (MIN([hcc1].[Min_Process_By])),
                   (MIN([hcc2].[Min_Process_By])),
                   (MIN([hcc3].[Min_Process_By]))
           ) [x] ([date])
       ), --'Min_Process_By'
       [Min_Thru] =
       (
           SELECT MAX([x].[thrudate])
           FROM
           (
               VALUES
                   (MIN([hcc1].[Min_Thru])),
                   (MIN([hcc2].[Min_Thru])),
                   (MIN([hcc3].[Min_Thru]))
           ) [x] ([thrudate])
       ),
       [LoadDateTime] = ISNULL(@LoadDateTime,GETDATE())
FROM [rev].[tbl_Intermediate_EDS] [hcc1]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Interactions] [int]
        ON [hcc1].[ModelYear] = [int].[Payment_Year]
           AND [hcc1].[RAFT] = [int].[Factor_Type]
           AND [hcc1].[HCC_Number] = [int].[HCC_Number_1]
           AND [hcc1].[Deleted] = 'A'
           AND
           (
               [hcc1].[HCC] NOT LIKE 'HIER%'
               AND [hcc1].[HCC] NOT LIKE 'INCR%'
           )
    JOIN [rev].[tbl_Intermediate_EDS] [hcc2]
        ON [hcc2].[ModelYear] = [int].[Payment_Year]
           AND [hcc2].[RAFT] = [int].[Factor_Type]
           AND [hcc2].[HCC_Number] = [int].[HCC_Number_2]
           AND [hcc2].[Deleted] = 'A'
           AND [hcc2].[PaymentYear] = [hcc1].[PaymentYear]
           AND [hcc2].[HICN] = [hcc1].[HICN]
           AND
           (
               [hcc2].[HCC] NOT LIKE 'HIER%'
               AND [hcc2].[HCC] NOT LIKE 'INCR%'
           )
    JOIN [rev].[tbl_Intermediate_EDS] [hcc3]
        ON [hcc3].[ModelYear] = [int].[Payment_Year]
           AND [hcc3].[RAFT] = [int].[Factor_Type]
           AND [hcc3].[HCC_Number] = [int].[HCC_Number_3]
           AND [hcc3].[Deleted] = 'A'
           AND [hcc3].[PaymentYear] = [hcc1].[PaymentYear]
           AND [hcc3].[HICN] = [hcc1].[HICN]
           AND
           (
               [hcc3].[HCC] NOT LIKE 'HIER%'
               AND [hcc3].[HCC] NOT LIKE 'INCR%'
           )
GROUP BY [hcc1].[PaymentYear],
         [hcc1].[ModelYear],
         [hcc1].[HICN],
         [hcc1].[RAFT],
         [int].[Interaction_Label],
         [hcc1].[HCC_Number],
         [hcc2].[HCC_Number],
         [hcc3].[HCC_Number];

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

UPDATE [i]
SET [i].[Max_HCC_NumberMPD] = [t4].[HCC_Number]
FROM [rev].[tbl_Intermediate_EDS_INT] [i]
    JOIN
    (
        SELECT [t3].[RowNum],
               [t3].[HICN],
               [t3].[RAFT],
               [t3].[PaymentYear],
               [t3].[ModelYear],
               [t3].[HCC],
               [t3].[HCC_Number],
               [t3].[Min_Process_By],
               [t3].[Min_ProcessBy_SeqNum]
        FROM
        (
            SELECT [RowNum] = ROW_NUMBER() OVER (PARTITION BY [t2].[HICN],
                                                              [t2].[RAFT],
                                                              [t2].[PaymentYear],
                                                              [t2].[ModelYear],
                                                              [t2].[HCC],
                                                              [t2].[Min_Process_By]
                                                 ORDER BY [t2].[Min_ProcessBy_SeqNum] DESC
                                                ),
                   [t2].[HICN],
                   [t2].[RAFT],
                   [t2].[PaymentYear],
                   [t2].[ModelYear],
                   [t2].[HCC],
                   [t2].[HCC_Number],
                   [t2].[Min_Process_By],
                   [t2].[Min_ProcessBy_SeqNum]
            FROM
            (
                SELECT [raps].[HICN],
                       [raps].[RAFT],
                       [raps].[PaymentYear],
                       [raps].[ModelYear],
                       [t1].[HCC],
                       [raps].[HCC_Number],
                       [Min_ProcessBy_SeqNum] = MAX([raps].[Min_ProcessBy_SeqNum]),
                       [raps].[Min_Process_By]
                FROM [rev].[tbl_Intermediate_EDS] [raps]
                    JOIN [rev].[tbl_Intermediate_EDS_INT] [t1]
                        ON [t1].[HICN] = [raps].[HICN]
                           AND [t1].[RAFT] = [raps].[RAFT]
                           AND [raps].[HCC_Number] IN ( [t1].[HCC_Number1], [t1].[HCC_Number2], [t1].[HCC_Number3] )
                           AND [t1].[Min_Process_By] = [raps].[Min_Process_By]
                           AND [t1].[PaymentYear] = [raps].[PaymentYear]
                           AND [t1].[ModelYear] = [raps].[ModelYear]
                GROUP BY [raps].[HCC_Number],
                         [t1].[HCC],
                         [raps].[Min_Process_By],
                         [raps].[HICN],
                         [raps].[RAFT],
                         [raps].[PaymentYear],
                         [raps].[ModelYear]
            ) [t2]
        ) [t3]
        WHERE [t3].[RowNum] = 1
    ) [t4]
        ON [i].[HCC] = [t4].[HCC]
           AND [i].[HICN] = [t4].[HICN]
           AND [i].[RAFT] = [t4].[RAFT]
           AND [i].[PaymentYear] = [t4].[PaymentYear]
           AND [i].[ModelYear] = [t4].[ModelYear];

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

UPDATE [i]
SET [i].[Max_HCC_NumberMTD] = [t4].[HCC_Number]
FROM [rev].[tbl_Intermediate_EDS_INT] [i]
    JOIN
    (
        SELECT [t3].[RowNum],
               [t3].[HICN],
               [t3].[RAFT],
               [t3].[PaymentYear],
               [t3].[ModelYear],
               [t3].[HCC],
               [t3].[HCC_Number],
               [t3].[Min_Thru],
               [t3].[Min_Thru_SeqNum]
        FROM
        (
            SELECT [RowNum] = ROW_NUMBER() OVER (PARTITION BY [t2].[HICN],
                                                              [t2].[RAFT],
                                                              [t2].[PaymentYear],
                                                              [t2].[ModelYear],
                                                              [t2].[HCC],
                                                              [t2].[Min_Thru]
                                                 ORDER BY [t2].[Min_Thru_SeqNum] DESC
                                                ),
                   [t2].[HICN],
                   [t2].[RAFT],
                   [t2].[PaymentYear],
                   [t2].[ModelYear],
                   [t2].[HCC],
                   [t2].[HCC_Number],
                   [t2].[Min_Thru],
                   [t2].[Min_Thru_SeqNum]
            FROM
            (
                SELECT [raps].[HICN],
                       [raps].[RAFT],
                       [raps].[PaymentYear],
                       [raps].[ModelYear],
                       [t1].[HCC],
                       [raps].[HCC_Number],
                       [Min_Thru_SeqNum] = MAX([raps].[Min_Thru_SeqNum]),
                       [raps].[Min_Thru]
                FROM [rev].[tbl_Intermediate_EDS] [raps]
                    JOIN [rev].[tbl_Intermediate_EDS_INT] [t1]
                        ON [t1].[HICN] = [raps].[HICN]
                           AND [t1].[RAFT] = [raps].[RAFT]
                           AND [raps].[HCC_Number] IN ( [t1].[HCC_Number1], [t1].[HCC_Number2], [t1].[HCC_Number3] )
                           AND [t1].[Min_Thru] = [raps].[Min_Thru]
                           AND [t1].[PaymentYear] = [raps].[PaymentYear]
                           AND [t1].[ModelYear] = [raps].[ModelYear]
                GROUP BY [raps].[HCC_Number],
                         [t1].[HCC],
                         [raps].[Min_Thru],
                         [raps].[HICN],
                         [raps].[RAFT],
                         [raps].[PaymentYear],
                         [raps].[ModelYear]
            ) [t2]
        ) [t3]
        WHERE [t3].[RowNum] = 1
    ) [t4]
        ON [i].[HCC] = [t4].[HCC]
           AND [i].[HICN] = [t4].[HICN]
           AND [i].[RAFT] = [t4].[RAFT]
           AND [i].[PaymentYear] = [t4].[PaymentYear]
           AND [i].[ModelYear] = [t4].[ModelYear];

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

DELETE [i]
FROM [rev].[tbl_Intermediate_EDS_INT] [i]
    JOIN
    (
        SELECT [i].*
        FROM [rev].[tbl_Intermediate_EDS_INT] [i]
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [h]
                ON (
                       [i].[HCC_Number1] = [h].[HCC_DROP_NUMBER]
                       OR [i].[HCC_Number2] = [h].[HCC_DROP_NUMBER]
                       OR [i].[HCC_Number3] = [h].[HCC_DROP_NUMBER]
                   )
                   AND [i].[RAFT] = [h].[RA_FACTOR_TYPE]
                   AND [i].[ModelYear] = [h].[Payment_Year]
            JOIN [rev].[tbl_Intermediate_EDS] [r]
                ON [h].[HCC_KEEP_NUMBER] = [r].[HCC_Number]
                   AND [i].[HICN] = [r].[HICN]
                   AND [i].[PaymentYear] = [r].[PaymentYear]
                   AND [i].[ModelYear] = [r].[ModelYear]
                   AND [i].[RAFT] = [r].[RAFT]
        WHERE ISNUMERIC([h].[HCC_DROP_NUMBER]) = 1
              AND [h].[HCC_KEEP_NUMBER] NOT IN ( [i].[HCC_Number1], [i].[HCC_Number2], [i].[HCC_Number3] )
    ) [i1]
        ON [i].[HICN] = [i1].[HICN]
           AND [i].[RAFT] = [i1].[RAFT]
           AND [i].[HCC_Number1] = [i1].[HCC_Number1]
           AND [i].[HCC_Number2] = [i1].[HCC_Number2]
           AND [i].[HCC_Number3] = [i1].[HCC_Number3]
           AND [i].[HCC] = [i1].[HCC]
           AND [i].[Min_Process_By] = [i1].[Min_Process_By]
           AND [i].[Min_Thru] = [i1].[Min_Thru]
           AND [i].[IMFFlag] = [i1].[IMFFlag]
           AND [i].[Min_ProcessBy_SeqNum] = [i1].[Min_ProcessBy_SeqNum]
           AND [i].[Min_Thru_SeqNum] = [i1].[Min_Thru_SeqNum]
           AND [i].[Processed_Priority_FileID] = [i1].[Processed_Priority_FileID];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '023',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [u1]
SET [u1].[Min_ProcessBy_SeqNum] = [u2].[Min_ProcessBy_SeqNum],
    [u1].[Min_Processby_DiagID] = [u2].[Min_Processby_DiagID],
    [u1].[Min_Processby_DiagCD] = [u2].[Min_Processby_DiagCD],
    [u1].[Min_ProcessBy_PCN] = [u2].[Min_ProcessBy_PCN],
    [u1].[processed_priority_thru_date] = [u2].[Processed_Priority_Thru_Date],
    [u1].[Processed_Priority_FileID] = [u2].[Processed_Priority_FileID],
    [u1].[Processed_Priority_RAPS_Source_ID] = [u2].[Processed_Priority_RAPS_Source_ID],
    [u1].[Processed_Priority_Provider_ID] = [u2].[Processed_Priority_Provider_ID],
    [u1].[Processed_Priority_RAC] = [u2].[Processed_Priority_RAC]
FROM [rev].[tbl_Intermediate_EDS_INT] [u1]
    JOIN
    (
        SELECT [RowNum] = ROW_NUMBER() OVER (PARTITION BY [raps].[HICN],
                                                          [raps].[RAFT],
                                                          [raps].[Min_Process_By],
                                                          [raps].[Min_Thru],
                                                          [it].[HCC_Number1],
                                                          [it].[HCC_Number2],
                                                          [it].[HCC_Number3]
                                             ORDER BY [raps].[Min_ProcessBy_SeqNum] DESC
                                            ),
               [raps].[Min_ProcessBy_SeqNum],
               [raps].[Min_Processby_DiagID],
               [raps].[Min_Processby_DiagCD],
               [raps].[Min_ProcessBy_PCN],
               [raps].[Processed_Priority_Thru_Date],
               [raps].[Processed_Priority_FileID],
               [raps].[Processed_Priority_RAPS_Source_ID],
               [raps].[Processed_Priority_Provider_ID],
               [raps].[Processed_Priority_RAC],
               [raps].[HICN],
               [raps].[PaymentYear],
               [raps].[ModelYear],
               [raps].[RAFT],
               [raps].[Min_Process_By],
               [it].[HCC_Number],
               [it].[HCC_Number1],
               [it].[HCC_Number2],
               [it].[HCC_Number3]
        FROM [rev].[tbl_Intermediate_EDS] [raps]
            JOIN [rev].[tbl_Intermediate_EDS_INT] [it]
                ON [raps].[HICN] = [it].[HICN]
                   AND [raps].[RAFT] = [it].[RAFT]
                   AND [raps].[Min_Process_By] = [it].[Min_Process_By]
                   AND [raps].[HCC_Number] = [it].[Max_HCC_NumberMPD]
                   AND [raps].[PaymentYear] = [it].[PaymentYear]
                   AND [raps].[ModelYear] = [it].[ModelYear]
    ) [u2]
        ON [u1].[HICN] = [u2].[HICN]
           AND [u1].[RAFT] = [u2].[RAFT]
           AND [u1].[PaymentYear] = [u2].[PaymentYear]
           AND [u1].[ModelYear] = [u2].[ModelYear]
           AND [u1].[HCC_Number] = [u2].[HCC_Number]
           AND [u1].[HCC_Number1] = [u2].[HCC_Number1]
           AND [u1].[HCC_Number2] = [u2].[HCC_Number2]
           AND [u1].[HCC_Number3] = [u2].[HCC_Number3]
WHERE [u2].[RowNum] = 1;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '024',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [u1]
SET [u1].[Min_Thru_SeqNum] = [u2].[Min_Thru_SeqNum],
    [u1].[Min_ThruDate_DiagID] = [u2].[Min_ThruDate_DiagID],
    [u1].[Min_ThruDate_DiagCD] = [u2].[Min_ThruDate_DiagCD],
    [u1].[Min_ThruDate_PCN] = [u2].[Min_ThruDate_PCN],
    [u1].[thru_priority_processed_by] = [u2].[Thru_Priority_Processed_By],
    [u1].[Thru_Priority_FileID] = [u2].[Thru_Priority_FileID],
    [u1].[Thru_Priority_RAPS_Source_ID] = [u2].[Thru_Priority_RAPS_Source_ID],
    [u1].[Thru_Priority_Provider_ID] = [u2].[Thru_Priority_Provider_ID],
    [u1].[Thru_Priority_RAC] = [u2].[Thru_Priority_RAC]
FROM [rev].[tbl_Intermediate_EDS_INT] [u1]
    JOIN
    (
        SELECT [RowNum] = ROW_NUMBER() OVER (PARTITION BY [raps].[HICN],
                                                          [raps].[RAFT],
                                                          [raps].[Min_Process_By],
                                                          [raps].[Min_Thru],
                                                          [it].[HCC_Number1],
                                                          [it].[HCC_Number2],
                                                          [it].[HCC_Number3]
                                             ORDER BY [raps].[Min_Thru_SeqNum] DESC
                                            ),
               [raps].[Min_Thru_SeqNum],
               [raps].[Min_ThruDate_DiagID],
               [raps].[Min_ThruDate_DiagCD],
               [raps].[Min_ThruDate_PCN],
               [raps].[Thru_Priority_Processed_By],
               [raps].[Thru_Priority_FileID],
               [raps].[Thru_Priority_RAPS_Source_ID],
               [raps].[Thru_Priority_Provider_ID],
               [raps].[Thru_Priority_RAC],
               [raps].[HICN],
               [raps].[PaymentYear],
               [raps].[ModelYear],
               [raps].[RAFT],
               [raps].[Min_Thru],
               [it].[HCC_Number],
               [it].[HCC_Number1],
               [it].[HCC_Number2],
               [it].[HCC_Number3]
        FROM [rev].[tbl_Intermediate_EDS] [raps]
            JOIN [rev].[tbl_Intermediate_EDS_INT] [it]
                ON [raps].[HICN] = [it].[HICN]
                   AND [raps].[RAFT] = [it].[RAFT]
                   AND [raps].[Min_Thru] = [it].[Min_Thru]
                   AND [raps].[HCC_Number] = [it].[Max_HCC_NumberMTD]
                   AND [raps].[PaymentYear] = [it].[PaymentYear]
                   AND [raps].[ModelYear] = [it].[ModelYear]
    ) [u2]
        ON [u1].[HICN] = [u2].[HICN]
           AND [u1].[RAFT] = [u2].[RAFT]
           AND [u1].[PaymentYear] = [u2].[PaymentYear]
           AND [u1].[ModelYear] = [u2].[ModelYear]
           AND [u1].[HCC_Number] = [u2].[HCC_Number]
WHERE [u2].[RowNum] = 1;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '025',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [a1]
SET [a1].[IMFFlag] = 3
FROM [rev].[tbl_Intermediate_EDS_INT] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE [a1].[Min_Process_By] > [py].[MidYear_Sweep_Date];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '026',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [a1]
SET [a1].[IMFFlag] = 2
FROM [rev].[tbl_Intermediate_EDS_INT] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          (
              [a1].[Min_Process_By] > [py].[Initial_Sweep_Date]
              AND [a1].[Min_Process_By] <= [py].[MidYear_Sweep_Date]
          )
          OR
          (
              [a1].[Min_Process_By] <= [py].[Initial_Sweep_Date]
              AND [a1].[processed_priority_thru_date] > [py].[Lagged_Thru_Date]
          )
      );

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '027',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [a1]
SET [a1].[IMFFlag] = 1
FROM [rev].[tbl_Intermediate_EDS_INT] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          [a1].[Min_Process_By] <= [py].[Initial_Sweep_Date]
          AND [a1].[processed_priority_thru_date] <= [py].[Lagged_Thru_Date]
      );

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '028',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [t1]
SET [t1].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_EDS_INT] [t1]
    JOIN
    (
        SELECT [HCCNew] = 'HIER-' + [drp].[HCC],
               [drp].[HCC],
               [drp].[HICN],
               [drp].[IMFFlag],
               [drp].[PaymentYear],
               [drp].[ModelYear],
               [drp].[Min_Process_By],
               [drp].[RAFT],
               [drp].[Min_Thru]
        FROM [rev].[tbl_Intermediate_EDS_INT] [drp]
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                ON CAST(LTRIM(REVERSE(LEFT(REVERSE([hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                          '%[A-Z]%',
                                                                                          REVERSE([hier].[HCC_DROP_NUMBER])
                                                                                      ) - 1)
                                     )
                             ) AS INT) = [drp].[HCC_Number]
                   AND [hier].[Payment_Year] = [drp].[ModelYear]
                   AND [hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
                   AND [hier].[Part_C_D_Flag] = 'C'
                   AND LEFT([hier].[HCC_DROP], 3) = 'INT'
                   AND LEFT([drp].[HCC], 3) = 'INT'
            JOIN [rev].[tbl_Intermediate_EDS_INT] [kep]
                ON [kep].[HICN] = [drp].[HICN]
                   AND [kep].[RAFT] = [drp].[RAFT]
                   AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                                   '%[A-Z]%',
                                                                                                                   REVERSE([hier].[HCC_KEEP_NUMBER])
                                                                                                               ) - 1)
                                                              )
                                                      ) AS INT)
                   AND [kep].[PaymentYear] = [drp].[PaymentYear]
                   AND [kep].[ModelYear] = [drp].[ModelYear]
                   AND LEFT([kep].[HCC], 3) = 'INT'
        GROUP BY [drp].[HCC],
                 [drp].[HICN],
                 [drp].[IMFFlag],
                 [drp].[PaymentYear],
                 [drp].[ModelYear],
                 [drp].[Min_Process_By],
                 [drp].[RAFT],
                 [drp].[Min_Thru],
                 [drp].[IMFFlag]
    ) [t2]
        ON [t1].[HICN] = [t2].[HICN]
           AND [t1].[HCC] = [t2].[HCC]
           AND [t1].[IMFFlag] = [t2].[IMFFlag]
           AND [t1].[PaymentYear] = [t2].[PaymentYear]
           AND [t1].[ModelYear] = [t2].[ModelYear]
           AND [t1].[Min_Process_By] = [t2].[Min_Process_By]
           AND [t1].[RAFT] = [t2].[RAFT]
           AND [t1].[Min_Thru] = [t2].[Min_Thru];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '029',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [t3]
SET [t3].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_EDS_INT] [t3]
    JOIN
    (
        SELECT [RowNum] = ROW_NUMBER() OVER (PARTITION BY [t1].[HCC],
                                                          [t1].[HICN],
                                                          [t1].[IMFFlag],
                                                          [t1].[PaymentYear],
                                                          [t1].[ModelYear],
                                                          [t1].[Min_Process_By],
                                                          [t1].[RAFT],
                                                          [t1].[Min_Thru]
                                             ORDER BY ([t1].[HICN])
                                            ),
               [t1].[HCC],
               [t1].[HCCNew],
               [t1].[HICN],
               [t1].[IMFFlag],
               [t1].[PaymentYear],
               [t1].[ModelYear],
               [t1].[Min_Process_By],
               [t1].[RAFT],
               [t1].[Min_Thru]
        FROM
        (
            SELECT [drp].[HCC],
                   [HCCNew] = CASE
                                  WHEN [drp].[IMFFlag] < [kep].[IMFFlag] THEN
                                      'INCR-' + [drp].[HCC]
                                  ELSE
                                      'HIER-' + [drp].[HCC]
                              END,
                   [drp].[HICN],
                   [drp].[IMFFlag],
                   [drp].[PaymentYear],
                   [drp].[ModelYear],
                   [drp].[Min_Process_By],
                   [drp].[RAFT],
                   [drp].[Min_Thru]
            FROM [rev].[tbl_Intermediate_EDS_INT] [drp]
                JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                    ON CAST(LTRIM(REVERSE(LEFT(REVERSE([hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                              '%[A-Z]%',
                                                                                              REVERSE([hier].[HCC_DROP_NUMBER])
                                                                                          ) - 1)
                                         )
                                 ) AS INT) = [drp].[HCC_Number]
                       AND [hier].[Payment_Year] = [drp].[ModelYear]
                       AND [hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
                       AND [hier].[Part_C_D_Flag] = 'C'
                       AND LEFT([hier].[HCC_DROP], 3) = 'INT'
                       AND LEFT([drp].[HCC], 3) = 'INT'
                JOIN [rev].[tbl_Intermediate_EDS_INT] [kep]
                    ON [kep].[HICN] = [drp].[HICN]
                       AND [kep].[RAFT] = [drp].[RAFT]
                       AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                                       '%[A-Z]%',
                                                                                                                       REVERSE([hier].[HCC_KEEP_NUMBER])
                                                                                                                   )
                                                                                                           - 1)
                                                                  )
                                                          ) AS INT)
                       AND [kep].[PaymentYear] = [drp].[PaymentYear]
                       AND [kep].[ModelYear] = [drp].[ModelYear]
                       AND LEFT([kep].[HCC], 3) = 'INT'
        ) [t1]
    ) [t2]
        ON [t2].[HICN] = [t3].[HICN]
           AND [t2].[IMFFlag] = [t3].[IMFFlag]
           AND [t2].[PaymentYear] = [t3].[PaymentYear]
           AND [t2].[ModelYear] = [t3].[ModelYear]
           AND [t2].[Min_Process_By] = [t3].[Min_Process_By]
           AND [t2].[RAFT] = [t3].[RAFT]
           AND [t2].[Min_Thru] = [t3].[Min_Thru]
           AND [t2].[HCC] = [t3].[HCC]
WHERE [t2].[RowNum] = 1;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '030',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


if (object_id('[rev].[tbl_Intermediate_EDS_INTRank]') is not null)

BEGIN
    
   Truncate table [rev].[tbl_Intermediate_EDS_INTRank];
 
End

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '031',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

INSERT INTO [rev].[tbl_Intermediate_EDS_INTRank]
(
    [PaymentYear],
    [ModelYear],
    [HICN],
    [RAFT],
    [HCC],
    [Min_ProcessBy_SeqNum],
    [Min_Thru_SeqNum],
    [Min_Processby_DiagCD],
    [Min_ThruDate_DiagCD],
    [RankID],
    [LoadDateTime]
)
SELECT DISTINCT
       [a1].[PaymentYear],
       [a1].[ModelYear],
       [a1].[HICN],
       [a1].[RAFT],
       [a1].[HCC],
       [a1].[Min_ProcessBy_SeqNum],
       [a1].[Min_Thru_SeqNum],
       [a1].[Min_Processby_DiagCD],
       [a1].[Min_ThruDate_DiagCD],
       [RankID] = RANK() OVER (PARTITION BY [a1].[PaymentYear],
                                            [a1].[ModelYear],
                                            [a1].[HICN],
                                            [a1].[RAFT],
                                            [a1].[HCC]
                               ORDER BY [a1].[Min_ProcessBy_SeqNum],
                                        [a1].[Min_Thru_SeqNum],
                                        [a1].[Min_Processby_DiagCD],
                                        [a1].[Min_ThruDate_DiagCD]
                              ),
      [LoadDateTime] = ISNULL(@LoadDateTime,GETDATE())
FROM [rev].[tbl_Intermediate_EDS_INT] [a1]
WHERE (
          [a1].[Min_ProcessBy_SeqNum] IS NOT NULL
          AND [a1].[Min_Thru_SeqNum] IS NOT NULL
      );

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '032',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

IF @Debug = 1
BEGIN
    SET STATISTICS IO OFF;
END;

WHILE (1 = 1)
BEGIN

    DELETE TOP (@DeleteBatch)
    FROM [rev].[tbl_Summary_RskAdj_EDS]
    WHERE [PaymentYear] IN
          (
              SELECT [py].[Payment_Year] FROM [#Refresh_PY] [py]
          );

    IF @@rowcount = 0
        BREAK;
    ELSE
        CONTINUE;
END;

IF @Debug = 1
BEGIN
    SET STATISTICS IO ON;
END;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '033',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

SET @RowCount = 0;
-----update

INSERT INTO [rev].[tbl_Summary_RskAdj_EDS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [Model_Year],
    [Factor_category],
    [Factor_Desc],
    [Factor_Desc_ORIG],
    [Factor],
    [HCC_Number],
    [RAFT],
    [RAFT_ORIG],
    [Min_ProcessBy],
    [Min_ThruDate],
    [Min_ProcessBy_SeqNum],
    [Min_ThruDate_SeqNum],
    [Min_Processby_DiagCD],
    [Min_ThruDate_DiagCD],
    [Min_ProcessBy_PCN],
    [Min_ThruDate_PCN],
    [processed_priority_thru_date],
    [thru_priority_processed_by],
    [Processed_Priority_FileID],
    [Processed_Priority_RAPS_Source_ID],
    [Processed_Priority_Provider_ID],
    [Processed_Priority_RAC],
    [Thru_Priority_FileID],
    [Thru_Priority_RAPS_Source_ID],
    [Thru_Priority_Provider_ID],
    [Thru_Priority_RAC],
    [IMFFlag],
    [LoadDateTime],
    [Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
    [Min_ThruDate_MAO004ResponseDiagnosisCodeId],
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
       [HICN] = [rskfct].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [Model_Year] = [rskfct].[ModelYear],
       [Factor_category] = 'EDS',
       [Factor_Desc] = [rskfct].[HCC],
       [Factor_Desc_ORIG] = [rskfct].[HCC_ORIG],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [rskfct].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected],
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],
       [Min_Process_By] = [rskfct].[Min_Process_By],
       [Min_ThruDate] = [rskfct].[Min_Thru],
       [Min_ProcessBy_SeqNum] = [rskfct].[Min_ProcessBy_SeqNum],
       [Min_Thru_SeqNum] = [rskfct].[Min_Thru_SeqNum],
       [Min_Processby_DiagCD] = [rskfct].[Min_Processby_DiagCD],
       [Min_ThruDate_DiagCD] = [rskfct].[Min_ThruDate_DiagCD],
       [Min_ProcessBy_PCN] = [rskfct].[Min_ProcessBy_PCN],
       [Min_ThruDate_PCN] = [rskfct].[Min_ThruDate_PCN],
       [processed_priority_thru_date] = [rskfct].[Processed_Priority_Thru_Date],
       [thru_priority_processed_by] = [rskfct].[Thru_Priority_Processed_By],
       [Processed_Priority_FileID] = [rskfct].[Processed_Priority_FileID],
       [Processed_Priority_RAPS_Source_ID] = [rskfct].[Processed_Priority_RAPS_Source_ID],
       [Processed_Priority_Provider_ID] = [rskfct].[Processed_Priority_Provider_ID],
       [Processed_Priority_RAC] = [rskfct].[Processed_Priority_RAC],
       [Thru_Priority_FileID] = [rskfct].[Thru_Priority_FileID],
       [Thru_Priority_RAPS_Source_ID] = [rskfct].[Thru_Priority_RAPS_Source_ID],
       [Thru_Priority_Provider_ID] = [rskfct].[Thru_Priority_Provider_ID],
       [Thru_Priority_RAC] = [rskfct].[Thru_Priority_RAC],
       [IMFFlag] = [rskfct].[IMFFlag],
       [LoadDateTime] = @LoadDateTime,
       [Min_ProcessBy_MAO004ResponseDiagnosisCodeId] = [rskfct].[Min_Processby_DiagID],
       [Min_ThruDate_MAO004ResponseDiagnosisCodeId] = [rskfct].[Min_ThruDate_DiagID],
       [mmr].[Aged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[tbl_Intermediate_EDS] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[RAFT] = [mmr].[PartCRAFTProjected]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[ModelYear]
           AND CAST(SUBSTRING([rskmod].[Factor_Description], 4, LEN([rskmod].[Factor_Description]) - 3) AS INT) = [rskfct].[HCC_Number]
           AND [rskmod].[OREC] = CASE
                                     WHEN mmr.PartCRAFTProjected IN ( 'C', 'CN', 'CP', 'CF', 'I', 'E', 'SE' ) THEN
                                         [mmr].[ORECRestated]
                                     ELSE
                                         '9999'
                                 END
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected]
           AND [rskmod].[Aged] = [mmr].[Aged]
WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'HCC%'
	  AND rskfct.HCC LIKE '%HCC%';

---------------------------------insert
	  
INSERT INTO [rev].[tbl_Summary_RskAdj_EDS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [Model_Year],
    [Factor_category],
    [Factor_Desc],
    [Factor_Desc_ORIG],
    [Factor],
    [HCC_Number],
    [RAFT],
    [RAFT_ORIG],
    [Min_ProcessBy],
    [Min_ThruDate],
    [Min_ProcessBy_SeqNum],
    [Min_ThruDate_SeqNum],
    [Min_Processby_DiagCD],
    [Min_ThruDate_DiagCD],
    [Min_ProcessBy_PCN],
    [Min_ThruDate_PCN],
    [processed_priority_thru_date],
    [thru_priority_processed_by],
    [Processed_Priority_FileID],
    [Processed_Priority_RAPS_Source_ID],
    [Processed_Priority_Provider_ID],
    [Processed_Priority_RAC],
    [Thru_Priority_FileID],
    [Thru_Priority_RAPS_Source_ID],
    [Thru_Priority_Provider_ID],
    [Thru_Priority_RAC],
    [IMFFlag],
    [LoadDateTime],
    [Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
    [Min_ThruDate_MAO004ResponseDiagnosisCodeId],
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
       [HICN] = [rskfct].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [Model_Year] = [rskfct].[ModelYear],
       [Factor_category] = 'APCC',
       [Factor_Desc] = [rskfct].[HCC],
       [Factor_Desc_ORIG] = [rskfct].[HCC_ORIG],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [rskfct].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected],
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],
       [Min_Process_By] = [rskfct].[Min_Process_By],
       [Min_ThruDate] = [rskfct].[Min_Thru],
       [Min_ProcessBy_SeqNum] = [rskfct].[Min_ProcessBy_SeqNum],
       [Min_Thru_SeqNum] = [rskfct].[Min_Thru_SeqNum],
       [Min_Processby_DiagCD] = [rskfct].[Min_Processby_DiagCD],
       [Min_ThruDate_DiagCD] = [rskfct].[Min_ThruDate_DiagCD],
       [Min_ProcessBy_PCN] = [rskfct].[Min_ProcessBy_PCN],
       [Min_ThruDate_PCN] = [rskfct].[Min_ThruDate_PCN],
       [processed_priority_thru_date] = [rskfct].[Processed_Priority_Thru_Date],
       [thru_priority_processed_by] = [rskfct].[Thru_Priority_Processed_By],
       [Processed_Priority_FileID] = [rskfct].[Processed_Priority_FileID],
       [Processed_Priority_RAPS_Source_ID] = [rskfct].[Processed_Priority_RAPS_Source_ID],
       [Processed_Priority_Provider_ID] = [rskfct].[Processed_Priority_Provider_ID],
       [Processed_Priority_RAC] = [rskfct].[Processed_Priority_RAC],
       [Thru_Priority_FileID] = [rskfct].[Thru_Priority_FileID],
       [Thru_Priority_RAPS_Source_ID] = [rskfct].[Thru_Priority_RAPS_Source_ID],
       [Thru_Priority_Provider_ID] = [rskfct].[Thru_Priority_Provider_ID],
       [Thru_Priority_RAC] = [rskfct].[Thru_Priority_RAC],
       [IMFFlag] = [rskfct].[IMFFlag],
       [LoadDateTime] = @LoadDateTime,
       [Min_ProcessBy_MAO004ResponseDiagnosisCodeId] = [rskfct].[Min_Processby_DiagID],
       [Min_ThruDate_MAO004ResponseDiagnosisCodeId] = [rskfct].[Min_ThruDate_DiagID],
       [mmr].[Aged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[tbl_Intermediate_EDS] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[RAFT] = [mmr].[PartCRAFTProjected]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[ModelYear]
        	AND [rskmod].[Factor_Description] =[rskfct].[HCC]
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected]
           AND [rskmod].[Aged] = [mmr].[Aged]
WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] NOT LIKE 'HCC%'
	  AND [rskmod].Factor_Description  like 'D%'
	  And [rskfct].HCC  like 'D%'
---------------------
SET @RowCount = @@rowcount;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '034',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



INSERT INTO [rev].[tbl_Summary_RskAdj_EDS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [Model_Year],
    [Factor_category],
    [Factor_Desc],
    [Factor_Desc_ORIG],
    [Factor],
    [HCC_Number],
    [RAFT],
    [RAFT_ORIG],
    [Min_ProcessBy],
    [Min_ThruDate],
    [Min_ProcessBy_SeqNum],
    [Min_ThruDate_SeqNum],
    [Min_Processby_DiagCD],
    [Min_ThruDate_DiagCD],
    [Min_ProcessBy_PCN],
    [Min_ThruDate_PCN],
    [processed_priority_thru_date],
    [thru_priority_processed_by],
    [Processed_Priority_FileID],
    [Processed_Priority_RAPS_Source_ID],
    [Processed_Priority_Provider_ID],
    [Processed_Priority_RAC],
    [Thru_Priority_FileID],
    [Thru_Priority_RAPS_Source_ID],
    [Thru_Priority_Provider_ID],
    [Thru_Priority_RAC],
    [IMFFlag],
    [LoadDateTime],
    [Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
    [Min_ThruDate_MAO004ResponseDiagnosisCodeId],
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
       [HICN] = [intr].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [Model_Year] = [intr].[ModelYear],
       [Factor_category] = 'EDS-Interaction',
       [Factor_Desc] = [intr].[HCC],
       [Factor_Desc_ORIG] = [intr].[HCC_ORIG],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [intr].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected],
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],
       [Min_Process_By] = [intr].[Min_Process_By],
       [Min_ThruDate] = [intr].[Min_Thru],
       [Min_ProcessBy_SeqNum] = [intr].[Min_ProcessBy_SeqNum],
       [Min_ThruDate_SeqNum] = [intr].[Min_Thru_SeqNum],
       [Min_Processby_DiagCD] = [intr].[Min_Processby_DiagCD],
       [Min_ThruDate_DiagCD] = [intr].[Min_ThruDate_DiagCD],
       [Min_ProcessBy_PCN] = [intr].[Min_ProcessBy_PCN],
       [Min_ThruDate_PCN] = [intr].[Min_ThruDate_PCN],
       [processed_priority_thru_date] = [intr].[processed_priority_thru_date],
       [thru_priority_processed_by] = [intr].[thru_priority_processed_by],
       [Processed_Priority_FileID] = [intr].[Processed_Priority_FileID],
       [Processed_Priority_RAPS_Source_ID] = [intr].[Processed_Priority_RAPS_Source_ID],
       [Processed_Priority_Provider_ID] = [intr].[Processed_Priority_Provider_ID],
       [Processed_Priority_RAC] = [intr].[Processed_Priority_RAC],
       [Thru_Priority_FileID] = [intr].[Thru_Priority_FileID],
       [Thru_Priority_RAPS_Source_ID] = [intr].[Thru_Priority_RAPS_Source_ID],
       [Thru_Priority_Provider_ID] = [intr].[Thru_Priority_Provider_ID],
       [Thru_Priority_RAC] = [intr].[Thru_Priority_RAC],
       [IMFFlag] = [intr].[IMFFlag],
       [LoadDateTime] = @LoadDateTime,
       [Min_ProcessBy_MAO004ResponseDiagnosisCodeId] = [intr].[Min_Processby_DiagID],
       [Min_ThruDate_MAO004ResponseDiagnosisCodeId] = [intr].[Min_ThruDate_DiagID],
       [mmr].[Aged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[tbl_Intermediate_EDS_INT] [intr]
        ON [intr].[HICN] = [mmr].[HICN]
           AND [intr].[RAFT] = [mmr].[PartCRAFTProjected]
           AND [intr].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [rev].[tbl_Intermediate_EDS_INTRank] [drvintr]
        ON [intr].[HICN] = [drvintr].[HICN]
           AND [intr].[RAFT] = [drvintr].[RAFT]
           AND [intr].[HCC] = [drvintr].[HCC]
           AND [intr].[Min_ProcessBy_SeqNum] = [drvintr].[Min_ProcessBy_SeqNum]
           AND [intr].[Min_Thru_SeqNum] = [drvintr].[Min_Thru_SeqNum]
           AND [intr].[Min_Processby_DiagCD] = [drvintr].[Min_Processby_DiagCD]
           AND [intr].[Min_ThruDate_DiagCD] = [drvintr].[Min_ThruDate_DiagCD]
           AND [intr].[PaymentYear] = [drvintr].[PaymentYear]
           AND [intr].[ModelYear] = [drvintr].[ModelYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [intr].[ModelYear]
           AND CAST(RIGHT([rskmod].[Factor_Description], LEN([rskmod].[Factor_Description]) - 3) AS INT) = [intr].[HCC_Number]
           AND [rskmod].[OREC] = CASE
                                     WHEN mmr.PartCRAFTProjected IN ( 'C', 'CN', 'CP', 'CF', 'I', 'E', 'SE' ) THEN
                                         [mmr].[ORECRestated]
                                     ELSE
                                         '9999'
                                 END
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected]
           AND [rskmod].[Aged] = [mmr].[Aged]
WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'INT%'
      AND [drvintr].[RankID] = 1;

SET @RowCount = ISNULL(@RowCount, 0) + @@rowcount;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '035',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

INSERT INTO [rev].[tbl_Summary_RskAdj_EDS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [Model_Year],
    [Factor_category],
    [Factor_Desc],
    [Factor_Desc_ORIG],
    [Factor],
    [HCC_Number],
    [RAFT],
    [RAFT_ORIG],
    [Min_ProcessBy],
    [Min_ThruDate],
    [Min_ProcessBy_SeqNum],
    [Min_ThruDate_SeqNum],
    [Min_Processby_DiagCD],
    [Min_ThruDate_DiagCD],
    [Min_ProcessBy_PCN],
    [Min_ThruDate_PCN],
    [processed_priority_thru_date],
    [thru_priority_processed_by],
    [Processed_Priority_FileID],
    [Processed_Priority_RAPS_Source_ID],
    [Processed_Priority_Provider_ID],
    [Processed_Priority_RAC],
    [Thru_Priority_FileID],
    [Thru_Priority_RAPS_Source_ID],
    [Thru_Priority_Provider_ID],
    [Thru_Priority_RAC],
    [IMFFlag],
    [LoadDateTime],
    [Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
    [Min_ThruDate_MAO004ResponseDiagnosisCodeId],
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
       [HICN] = [rskfct].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [Model_Year] = [rskfct].[ModelYear],
       [Factor_category] = 'EDS-Disability',
       [Factor_Desc] = [rskmod].[Factor_Description],
       [Factor_Desc_ORIG] = [rskmod].[Factor_Description],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [rskfct].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected],
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],
       [Min_Process_By] = [rskfct].[Min_Process_By],
       [Min_ThruDate] = [rskfct].[Min_Thru],
       [Min_ProcessBy_SeqNum] = [rskfct].[Min_ProcessBy_SeqNum],
       [Min_ThruDate_SeqNum] = [rskfct].[Min_Thru_SeqNum],
       [Min_Processby_DiagCD] = [rskfct].[Min_Processby_DiagCD],
       [Min_ThruDate_DiagCD] = [rskfct].[Min_ThruDate_DiagCD],
       [Min_ProcessBy_PCN] = [rskfct].[Min_ProcessBy_PCN],
       [Min_ThruDate_PCN] = [rskfct].[Min_ThruDate_PCN],
       [Processed_Priority_Thru_Date] = [rskfct].[Processed_Priority_Thru_Date],
       [Thru_Priority_Processed_By] = [rskfct].[Thru_Priority_Processed_By],
       [Processed_Priority_FileID] = [rskfct].[Processed_Priority_FileID],
       [Processed_Priority_RAPS_Source_ID] = [rskfct].[Processed_Priority_RAPS_Source_ID],
       [Processed_Priority_Provider_ID] = [rskfct].[Processed_Priority_Provider_ID],
       [Processed_Priority_RAC] = [rskfct].[Processed_Priority_RAC],
       [Thru_Priority_FileID] = [rskfct].[Thru_Priority_FileID],
       [Thru_Priority_RAPS_Source_ID] = [rskfct].[Thru_Priority_RAPS_Source_ID],
       [Thru_Priority_Provider_ID] = [rskfct].[Thru_Priority_Provider_ID],
       [Thru_Priority_RAC] = [rskfct].[Thru_Priority_RAC],
       [IMFFlag] = [rskfct].[IMFFlag],
       [LoadDateTime] = @LoadDateTime,
       [Min_ProcessBy_MAO004ResponseDiagnosisCodeId] = [rskfct].[Min_Processby_DiagID],
       [Min_ThruDate_MAO004ResponseDiagnosisCodeId] = [rskfct].[Min_ThruDate_DiagID],
       [mmr].[Aged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[tbl_Intermediate_EDS] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[RAFT] = [mmr].[PartCRAFTProjected]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[ModelYear]
           AND CAST(SUBSTRING([rskmod].[Factor_Description], 6, LEN([rskmod].[Factor_Description]) - 5) AS INT) = [rskfct].[HCC_Number]
           AND [rskmod].[OREC] = '9999'
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected]
           AND [rskmod].[Aged] = [mmr].[Aged]
WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'D-HCC%'
      AND [rskfct].[HCC] LIKE 'HCC%'
      AND [mmr].[RskAdjAgeGrp] < '6565';

SET @RowCount = ISNULL(@RowCount, 0) + @@rowcount;


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '035.5',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;

UPDATE [ed]
SET [ed].[LastAssignedHICN] = ISNULL(   [b].[LastAssignedHICN],
                                        CASE
                                            WHEN ssnri.fnValidateMBI([ed].[HICN]) = 1 THEN
                                                [b].[HICN]
                                        END
                                    )
FROM [rev].[tbl_Summary_RskAdj_EDS] [ed]
    CROSS APPLY
(
    SELECT TOP 1
           [b].[LastAssignedHICN],
           [b].[HICN]
    FROM [rev].[tbl_Summary_RskAdj_AltHICN] AS [b]
    WHERE [b].[FINALHICN] = [ed].[HICN]
    ORDER BY [LoadDateTime] DESC
) AS [b]
    JOIN [#Refresh_PY] [py]
        ON [ed].[PaymentYear] = [py].[Payment_Year];



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '036',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;
