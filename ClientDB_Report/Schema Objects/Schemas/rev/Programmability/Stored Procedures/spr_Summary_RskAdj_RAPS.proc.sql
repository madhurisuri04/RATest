Create PROC [rev].[spr_Summary_RskAdj_RAPS]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS

/************************************************************************************************************************* 
* Name				:	rev.spr_Summary_RskAdj_RAPS																			*
* Type 				:	Stored Procedure																					*
* Author       		:	Mitch Casto																							*
* Date				:	2016-03-21																							*
* Version			:																										*
* Description		: Updates rev.spr_Summary_RskAdj_RAPS table with raw MOR data											*
*					Note: This stp is an adaptation from Summary 1.0 and will need further work to							*
*					optimize the sql.																						*
*																															*
* Version History :																											*
* ======================================================================================================================	*
* Author			Date		Version#    TFS Ticket#		Description														*	
* -----------------	----------  --------    -----------		------------													*
* Mitch Casto		2016-05-18	1.0			53367			Initial															*
* D. Waddell		2016-08-01	1.1			54208			Rename proc	[rev].[spr_Summary_RskAdj_RAPS_MOR_Combined] 		*
*															to [rev].[spr_Summary_RskAdj_RAPS]								*
* D. Waddell        2016-09-07  1.2         55925           perform their daily kill and fill of result tables based on     *
*                                                           on Payment Year determined by the Refresh PY US53053            *   
* D. Waddell        2016-12-28  1.3         US60182         Include CF,CN, and CP to any reference of Factor Type = C       *   
*                                                           added [AGED] to RAPS Summary Table                              *               
* Mitch Casto		2017-03-27	1.4			63302/US63790	Removed @ManualRun process and replaced	with parameterized		*
*															delete batch (Section 014, 020, 035 & 037)		                * 
* Madhuri Suri     2017-06-26   1.5        65510            OREC Fix for New HCC                                            *
*                                                                                                                           *
* D. Waddell       2017-10-11   1.6        RE-1171/67449    Sect. 10 &13 - Expanding on the [RAPS_DiagHCC_rollupID] join    *
*                                                           for this section to create accurate results                     *  
* Rakshit Lall		2017-11-14	1.7			68042/ RE-1219	Modified sec 033 and 034 to change the join to OREC				*

* Notes:	a.) Can Section 009 & 010 be combined or added to 008?															*
*			b.) A future enhancement may be to change the batch size of the delete process to be configurable for			*
*				rev.tbl_Intermediate_RAPS, rev.tbl_Intermediate_RAPS_INT & rev.tbl_Intermediate_RAPS_INTRank				*
*																															*
* D.Waddell			10/29/2019	1.8			RE-6981			Set Transaction Isolation Level Read to Uncommitted             *
* * Anand		    2019-11-07  1.9         RE-7056/77232   Incorporarated partiontioning Logic instead of Batch Deletes*	
* Anand				2020-07-16	2.0			RRI-79/79109    Used Intermediate Prelim table. Removed Plan ID from temp table 
															calculation
****************************************************************************************************************************/

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
    SET @ProcessNameIn = OBJECT_NAME(@@PROCID);
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

 

--DELETE TOP (@DeleteBatch)
--FROM [rev].[tbl_Intermediate_RAPS];

--RE - 7056 

if (object_id('[rev].[tbl_Intermediate_RAPS]') is not null)

BEGIN
    
   Truncate table [rev].[tbl_Intermediate_RAPS];
 
End

--RE - 7056 


if (object_id('[etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary]') is not null)

BEGIN
    
   Truncate table [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary];
 
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

Insert Into [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary]
(
       [PaymentYear]
      ,[ModelYear]
      ,[HICN]
      ,[PartCRAFTProjected]
      ,[RAPS_DiagHCC_rollupID]
      ,[RAPSID]
      ,[ProcessedBy]
      ,[DiagnosisCode]
      ,[FileID]
      ,[FromDate]
      ,[PatientControlNumber]
      ,[SeqNumber]
      ,[ThruDate]
      ,[Deleted]
      ,[Source_Id]
      ,[Provider_Id]
      ,[RAC]
      ,[HCC_Label]
      ,[HCC_Number]
      ,[Aged]
 )

SELECT 
	   Distinct
       [rps].[PaymentYear]
      ,[rps].[ModelYear]
      ,[rps].[HICN]
      ,[rps].[PartCRAFTProjected]
      ,[rps].[RAPS_DiagHCC_rollupID]
      ,[rps].[RAPSID]
      ,[rps].[ProcessedBy]
      ,[rps].[DiagnosisCode]
      ,[rps].[FileID]
      ,[rps].[FromDate]
      ,[rps].[PatientControlNumber]
      ,[rps].[SeqNumber]
      ,[rps].[ThruDate]
      ,[rps].[Deleted]
      ,[rps].[Source_Id]
      ,[rps].[Provider_Id]
      ,[rps].[RAC]
      ,[rps].[HCC_Label]
      ,[rps].[HCC_Number]
      ,[rps].[Aged]
  FROM [rev].[tbl_Summary_RskAdj_RAPS_Preliminary] [rps] WITH (NOLOCK)
   INNER JOIN [#Refresh_PY] [py]
        ON [rps].[PaymentYear] = [py].[Payment_Year]
		where [rps].[Void_Indicator] IS NULL;
		 

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '005.0',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;
/* 41262 Req 1 Loading Accpeted RAPS  */
INSERT INTO [rev].[tbl_Intermediate_RAPS] --[#tbl_EstRecv_RAPS]--[dbo].[tbl_EstRecv_RAPS]
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
       [Min_Process_By] = MIN([rps].[ProcessedBy]),
       [Min_Thru] = MIN([rps].[ThruDate]),
       [Deleted] = ISNULL([rps].[Deleted], 'A'), --HMF 5/3/2016 - setting NULL Deleted to 'A' so that it can be joined on further down.
       [PaymentYear] = [rps].[PaymentYear],
       [ModelYear] = [rps].[ModelYear],
       [LoadDateTime] = @LoadDateTime

FROM [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [rps]
WHERE [rps].[Deleted] IS NULL

GROUP BY [rps].[HICN],
         [rps].[PartCRAFTProjected],
         [rps].[HCC_Label],
         [rps].[HCC_Number],
         ISNULL([rps].[Deleted], 'A'),
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

/* 41262 Req 1 Loading Deletes  */
INSERT INTO [rev].[tbl_Intermediate_RAPS] --[#tbl_EstRecv_RAPS]
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
       [Min_Process_By] = MAX([rps].[ProcessedBy]),
       [Min_Thru] = MAX([rps].[ThruDate]),
       [Deleted] = [rps].[Deleted],
       [PaymentYear] = [rps].[PaymentYear],
       [ModelYear] = [rps].[ModelYear],
       [LoadDateTime] = @LoadDateTime
FROM [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [rps]
    LEFT JOIN [rev].[tbl_Intermediate_RAPS] [rpsact]
        ON     [rpsact].[HICN] = [rps].[HICN]
           AND [rpsact].[RAFT] = [rps].[PartCRAFTProjected]
           AND [rpsact].[HCC] = [rps].[HCC_Label]
           AND [rpsact].[HCC_Number] = [rps].[HCC_Number]
           AND [rpsact].[Deleted] = 'A'
           AND [rpsact].[PaymentYear] = [rps].[PaymentYear]
           AND [rpsact].[ModelYear] = [rps].[ModelYear]
WHERE [rpsact].[HCC] IS NULL
      AND [rps].[Deleted] = 'D'
GROUP BY [rps].[HICN],
         [rps].[PartCRAFTProjected],
         [rps].[HCC_Label],
         [rps].[HCC_Number],
         [rps].[Deleted],
         [rps].[PaymentYear],
         [rps].[ModelYear];

--UPDATE STATISTICS [dbo].[tbl_Summary_RskAdj_RAPS_Preliminary] WITH FULLSCAN;					

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

/* 41262 req 1 Update Minumum ProcessBy SeqNum this is to assign the min seq number to determine the correct hicn to process.*/
UPDATE [rps]
SET [rps].[Min_ProcessBy_SeqNum] = [drv].[SeqNumber]
FROM [rev].[tbl_Intermediate_RAPS] [rps]
    JOIN
    (
        SELECT [SeqNumber] = MIN([diag].[SeqNumber]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ProcessedBy]
        FROM [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [diag]
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ProcessedBy]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Process_By] = [drv].[ProcessedBy];

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


/* 41262 req 1 Update Minumum ProcessBy Diag ID to choose the correct record update */
UPDATE [rps]
SET [rps].[Min_Processby_DiagID] = [drv].[RAPS_DiagHCC_rollupID]
FROM [rev].[tbl_Intermediate_RAPS] [rps] -- [#tbl_EstRecv_RAPS] [rps]
    JOIN
    (
        SELECT [RAPS_DiagHCC_rollupID] = MIN([diag].[RAPS_DiagHCC_rollupID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ProcessedBy],
               [diag].[SeqNumber]
        FROM [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [diag]
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ProcessedBy],
                 [diag].[SeqNumber]
    ) [drv]
        ON [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Process_By] = [drv].[ProcessedBy]
           AND [rps].[Min_ProcessBy_SeqNum] = [drv].[SeqNumber];

/* 41262 req 1 Update Min_Processby_DiagCD, Min_ProcessBy_PCN */

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

--HasanMF 10/10/2017:  RE - 1171 TFS 67449
--Expanding on the [RAPS_DiagHCC_rollupID] join for this section to create accurate results. 
--This change will correct for ProcessedPriorityThruDate and ThruPriorityProcessedBy to cross over into different PaymentYear ranges.

UPDATE [rps]
SET [rps].[Min_Processby_DiagCD] = [diag].[DiagnosisCode],
    [rps].[Min_ProcessBy_PCN] = [diag].[PatientControlNumber],
    [rps].[Processed_Priority_Thru_Date] = [diag].[ThruDate],
    -- Ticket # 25658
    /* Ticket # 25703 Start */
    [rps].[Processed_Priority_FileID] = [diag].[FileID],
    [rps].[Processed_Priority_RAPS_Source_ID] = [diag].[Source_Id],
    [rps].[Processed_Priority_Provider_ID] = [diag].[Provider_Id],
    [rps].[Processed_Priority_RAC] = [diag].[RAC]
/* Ticket # 25703 END */
FROM [rev].[tbl_Intermediate_RAPS] [rps]
    JOIN [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [diag]
        ON [diag].[RAPS_DiagHCC_rollupID] = [rps].[Min_Processby_DiagID]
           AND [diag].[HICN] = [rps].[HICN] -- RE1171 TFS 67449
           AND [diag].[PaymentYear] = [rps].[PaymentYear];



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

/* 41262 req 1 Update Minumum ThruDate SeqNum  */
UPDATE [rps]
SET [rps].[Min_Thru_SeqNum] = [drv].[SeqNumber]
FROM [rev].[tbl_Intermediate_RAPS] [rps]
    JOIN
    (
        SELECT [SeqNumber] = MIN([diag].[SeqNumber]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ThruDate]
        FROM [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [diag]
        GROUP BY 
                 [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ThruDate]
    ) [drv]
        ON     [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Thru] = [drv].[ThruDate];

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

/* 41262 req 1 Update Minumum ThruDate Diag ID  */
UPDATE [rps]
SET [rps].[Min_ThruDate_DiagID] = [drv].[RAPS_DiagHCC_rollupID]
FROM [rev].[tbl_Intermediate_RAPS] [rps]
    JOIN
    (
        SELECT [RAPS_DiagHCC_rollupID] = MIN([diag].[RAPS_DiagHCC_rollupID]),
               [diag].[HICN],
               [RAFT] = [diag].[PartCRAFTProjected],
               [diag].[HCC_Number],
               [Deleted] = ISNULL([diag].[Deleted], 'A'),
               [diag].[PaymentYear],
               [diag].[ModelYear],
               [diag].[ThruDate],
               [diag].[SeqNumber]
        FROM [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [diag]
        GROUP BY [diag].[HICN],
                 [diag].[PartCRAFTProjected],
                 [diag].[HCC_Number],
                 ISNULL([diag].[Deleted], 'A'),
                 [diag].[PaymentYear],
                 [diag].[ModelYear],
                 [diag].[ThruDate],
                 [diag].[SeqNumber]
    ) [drv]
        ON     [rps].[HICN] = [drv].[HICN]
           AND [rps].[RAFT] = [drv].[RAFT]
           AND [rps].[HCC_Number] = [drv].[HCC_Number]
           AND [rps].[Deleted] = [drv].[Deleted]
           AND [rps].[PaymentYear] = [drv].[PaymentYear]
           AND [rps].[ModelYear] = [drv].[ModelYear]
           AND [rps].[Min_Thru] = [drv].[ThruDate]
           AND [rps].[Min_Thru_SeqNum] = [drv].[SeqNumber];

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


--HasanMF 10/10/2017: 
--RE 1171 TFS 67449  
--Expanding on the [RAPS_DiagHCC_rollupID] join for this section to create accurate results. 
--This change will correct for ProcessedPriorityThruDate and ThruPriorityProcessedBy to cross over into different PaymentYear ranges.

/*  41262 rew 1 Update Min_ThruDate_DiagCD, Min_ThruDate_PCN */
UPDATE [rps]
SET [rps].[Min_ThruDate_DiagCD] = [Diag].[DiagnosisCode],
    [rps].[Min_ThruDate_PCN] = [Diag].[PatientControlNumber],
    [rps].[Thru_Priority_Processed_By] = [Diag].[ProcessedBy],
    -- Ticket # 25658
    /* Ticket # 25703 Start */
    [rps].[Thru_Priority_FileID] = [Diag].[FileID],
    [rps].[Thru_Priority_RAPS_Source_ID] = [Diag].[Source_Id],
    [rps].[Thru_Priority_Provider_ID] = [Diag].[Provider_Id],
    [rps].[Thru_Priority_RAC] = [Diag].[RAC]
/* Ticket # 25703 END */
FROM [rev].[tbl_Intermediate_RAPS] [rps]
    JOIN [etl].[tbl_Intermediate_RskAdj_RAPS_Preliminary] [Diag]
        ON [Diag].[RAPS_DiagHCC_rollupID] = [rps].[Min_ThruDate_DiagID]
           AND [Diag].[HICN] = [rps].[HICN] --RE 1171 TFS 67449 
           AND [Diag].[PaymentYear] = [rps].[PaymentYear];


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

/* IMPLEMENTING IMF LOGIC IN RAPS TABLE Ticket # 25703 Start */
UPDATE [a1]
SET [a1].[IMFFlag] = 3
FROM [rev].[tbl_Intermediate_RAPS] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE [a1].[Min_Process_By] > [py].[MidYear_Sweep_Date];


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
SET [a1].[IMFFlag] = 2
FROM [rev].[tbl_Intermediate_RAPS] [a1]
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
    EXEC [dbo].[PerfLogMonitor] '016',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [a1]
SET [a1].[IMFFlag] = 1
FROM [rev].[tbl_Intermediate_RAPS] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          [a1].[Min_Process_By] <= [py].[Initial_Sweep_Date]
          AND [a1].[Processed_Priority_Thru_Date] <= [py].[Lagged_Thru_Date]
      );


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

/* Ticket # 25703 END */

-- Update Del HCC
UPDATE [rev].[tbl_Intermediate_RAPS]
SET [HCC] = 'DEL-' + [HCC]
WHERE [Deleted] = 'D';


--HCC Hierarchy for RAPS MOR Combined
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

UPDATE [t1]
SET [t1].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_RAPS] [t1]
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
        FROM [rev].[tbl_Intermediate_RAPS] [drp]
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                ON [hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
                   AND [hier].[Payment_Year] = [drp].[ModelYear]
                   AND [hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
                   AND [hier].[Part_C_D_Flag] = 'C'
                   AND LEFT([hier].[HCC_DROP], 3) = 'HCC'
                   AND LEFT([drp].[HCC], 3) = 'HCC'
            JOIN [rev].[tbl_Intermediate_RAPS] [kep]
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
    EXEC [dbo].[PerfLogMonitor] '019',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [t3]
SET [t3].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_RAPS] [t3]
    JOIN
    (
        SELECT
            --HMF Notes: ROW_NUMBER(): Answers the question How many times does this following combination occur?
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
            FROM [rev].[tbl_Intermediate_RAPS] [drp]
                JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [hier]
                    ON [hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
                       AND [hier].[Payment_Year] = [drp].[ModelYear]
                       AND [hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
                       AND [hier].[Part_C_D_Flag] = 'C'
                       AND LEFT([hier].[HCC_DROP], 3) = 'HCC'
                       AND LEFT([drp].[HCC], 3) = 'HCC'
                JOIN [rev].[tbl_Intermediate_RAPS] [kep]
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
    EXEC [dbo].[PerfLogMonitor] '020',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

/****************************************************************************************************************/
/*                                     INTERACTIONS                                                             */
/*                           (this could be it's own isolated script)                                           */
/****************************************************************************************************************/
--REFERENCE:
--\\hrp.local\Shares\Departments\InformationSolutions\TFS Tickets\TASK36379 - Documenting dbo.spr_EstRecv_MMR_RAPS_MOR_Summary\Summary_RskAdj_Requirements_20160511_HMF.xlsx
--Tab:"RAPS INT work flow"

--HCC Interactions for RAPS MOR Combined

--WHILE (1 = 1)
--BEGIN

--    DELETE TOP (@DeleteBatch)
--    FROM [rev].[tbl_Intermediate_RAPS_INT];


--    IF @@ROWCOUNT = 0
--        BREAK;
--    ELSE
--        CONTINUE;
--END;


--RE - 7056 

if (object_id('[rev].[tbl_Intermediate_RAPS_INT]') is not null)

BEGIN
    
   Truncate table [rev].[tbl_Intermediate_RAPS_INT];
 
End

--RE - 7056 


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


INSERT INTO [rev].[tbl_Intermediate_RAPS_INT]
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
       [LoadDateTime] = @LoadDateTime
FROM [rev].[tbl_Intermediate_RAPS] [hcc1]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Interactions] [int]
        ON [hcc1].[ModelYear] = [int].[Payment_Year]
           AND [hcc1].[RAFT] = [int].[Factor_Type]
           AND [hcc1].[HCC_Number] = [int].[HCC_Number_1]
           AND [hcc1].[Deleted] = 'A'
           AND
           (
               [hcc1].[HCC] NOT LIKE 'HIER%'
               AND [hcc1].[HCC] NOT LIKE 'INCR%'
           ) --HasanMF 3/19/2017: Interaction logic only needs to be applied to highest Hierarchical ranking HCCs. HIER HCCs/ INCR HCCs are not needed as part of this logic.

    JOIN [rev].[tbl_Intermediate_RAPS] [hcc2]
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
           ) --HasanMF 3/19/2017: Interaction logic only needs to be applied to highest Hierarchical ranking HCCs. HIER HCCs/ INCR HCCs are not needed as part of this logic.

    JOIN [rev].[tbl_Intermediate_RAPS] [hcc3]
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
           ) --HasanMF 3/19/2017: Interaction logic only needs to be applied to highest Hierarchical ranking HCCs. HIER HCCs/ INCR HCCs are not needed as part of this logic.

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
    EXEC [dbo].[PerfLogMonitor] '023',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

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

--HMF 5/5/2016 - This Update is bringing in the last HCC that triggered the Interaction based on Min_Process_By (MPB)
UPDATE [i]
SET [i].[Max_HCC_NumberMPD] = [t4].[HCC_Number]
FROM [rev].[tbl_Intermediate_RAPS_INT] [i]
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
                FROM [rev].[tbl_Intermediate_RAPS] [raps]
                    JOIN [rev].[tbl_Intermediate_RAPS_INT] [t1]
                        ON     [t1].[HICN] = [raps].[HICN]
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
    EXEC [dbo].[PerfLogMonitor] '025',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


--HMF 5/5/2016 - This Update is bringing in the last HCC that triggered the Interaction based on Min_Thru (MTD)
UPDATE [i]
SET [i].[Max_HCC_NumberMTD] = [t4].[HCC_Number]
FROM [rev].[tbl_Intermediate_RAPS_INT] [i]
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
                FROM [rev].[tbl_Intermediate_RAPS] [raps]
                    JOIN [rev].[tbl_Intermediate_RAPS_INT] [t1]
                        ON     [t1].[HICN] = [raps].[HICN]
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
    EXEC [dbo].[PerfLogMonitor] '026',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/* 41262 req 1 This Deletes interaction that have a higher HCC that does not participate in a interaction. */
DELETE [i]
FROM [rev].[tbl_Intermediate_RAPS_INT] [i]
    JOIN
    (
        SELECT [i].*
        FROM [rev].[tbl_Intermediate_RAPS_INT] [i]
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [h]
                ON (
                       [i].[HCC_Number1] = [h].[HCC_DROP_NUMBER]
                       OR [i].[HCC_Number2] = [h].[HCC_DROP_NUMBER]
                       OR [i].[HCC_Number3] = [h].[HCC_DROP_NUMBER]
                   )
                   AND [i].[RAFT] = [h].[RA_FACTOR_TYPE]
                   AND [i].[ModelYear] = [h].[Payment_Year]
            JOIN [rev].[tbl_Intermediate_RAPS] [r]
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
    EXEC [dbo].[PerfLogMonitor] '027',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/* Min Process By Interaction Update */
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
FROM [rev].[tbl_Intermediate_RAPS_INT] [u1]
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
        FROM [rev].[tbl_Intermediate_RAPS] [raps]
            JOIN [rev].[tbl_Intermediate_RAPS_INT] [it]
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
    EXEC [dbo].[PerfLogMonitor] '028',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

/* Min Thru Interaction Update */
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
FROM [rev].[tbl_Intermediate_RAPS_INT] [u1]
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
        FROM [rev].[tbl_Intermediate_RAPS] [raps]
            JOIN [rev].[tbl_Intermediate_RAPS_INT] [it]
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
    EXEC [dbo].[PerfLogMonitor] '029',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

/* IMPLEMENTING IMF LOGIC IN INTERACTIONS TABLE */
UPDATE [a1]
SET [a1].[IMFFlag] = 3
FROM [rev].[tbl_Intermediate_RAPS_INT] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE [a1].[Min_Process_By] > [py].[MidYear_Sweep_Date];

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


UPDATE [a1]
SET [a1].[IMFFlag] = 2
FROM [rev].[tbl_Intermediate_RAPS_INT] [a1]
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
    EXEC [dbo].[PerfLogMonitor] '031',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [a1]
SET [a1].[IMFFlag] = 1
FROM [rev].[tbl_Intermediate_RAPS_INT] [a1]
    JOIN [#Refresh_PY] [py]
        ON [a1].[PaymentYear] = [py].[Payment_Year]
WHERE (
          [a1].[Min_Process_By] <= [py].[Initial_Sweep_Date]
          AND [a1].[processed_priority_thru_date] <= [py].[Lagged_Thru_Date]
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

/* Interaction Heirachy Begin */
UPDATE [t1]
SET [t1].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_RAPS_INT] [t1]
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
        FROM [rev].[tbl_Intermediate_RAPS_INT] [drp]
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
            JOIN [rev].[tbl_Intermediate_RAPS_INT] [kep]
                ON     [kep].[HICN] = [drp].[HICN]
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
    EXEC [dbo].[PerfLogMonitor] '033',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


UPDATE [t3]
SET [t3].[HCC] = [t2].[HCCNew]
FROM [rev].[tbl_Intermediate_RAPS_INT] [t3]
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
            FROM [rev].[tbl_Intermediate_RAPS_INT] [drp]
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
                JOIN [rev].[tbl_Intermediate_RAPS_INT] [kep]
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
    EXEC [dbo].[PerfLogMonitor] '034',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


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

--WHILE (1 = 1)
--BEGIN

--    DELETE TOP (@DeleteBatch)
--    FROM [rev].[tbl_Intermediate_RAPS_INTRank];


--    IF @@ROWCOUNT = 0
--        BREAK;
--    ELSE
--        CONTINUE;
--END;

--RE - 7056 

if (object_id('[rev].[tbl_Intermediate_RAPS_INTRank]') is not null)

BEGIN
    
   Truncate table [rev].[tbl_Intermediate_RAPS_INTRank];
 
End

--RE - 7056 




IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '036',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


INSERT INTO [rev].[tbl_Intermediate_RAPS_INTRank]
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
       [LoadDateTime] = @LoadDateTime
FROM [rev].[tbl_Intermediate_RAPS_INT] [a1]
WHERE (
          [a1].[Min_ProcessBy_SeqNum] IS NOT NULL
          AND [a1].[Min_Thru_SeqNum] IS NOT NULL
      );

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '037',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/*****************************INTERACTIONS LOGIC COMPLETE********************************************************/
/*                           (this is where the Interaction segment could end)                                  */
/****************************************************************************************************************/



/****************************************************************************************************************/
/*                           Inserts into tbl_Summary_RskAdj_RAPS table                                                 */
/****************************************************************************************************************/

--41262 Req 6 Add Populated column to 3 summary tables (MMR, MOR, RAPS) 
-- Insert HCCs/HIER into dbo.tbl_Summary_RskAdj_RAPS_Preliminary 

 
DECLARE @C INT
DECLARE @ID INT = (SELECT COUNT([#Refresh_PYId]) FROM  [#Refresh_PY])
DECLARE @PaymentYear Int
SET @RowCount = 0;

SET @C = 1

WHILE ( @C <= @ID )

BEGIN 

	SELECT @PaymentYear = [Payment_Year]  
        FROM   [#Refresh_PY]
		WHERE  [#Refresh_PYId] = @C



ALTER TABLE [Rev].[tbl_Summary_RskAdj_RAPS] SWITCH  PARTITION $Partition.[pfn_SummPY] (@PaymentYear) TO [Out].[tbl_Summary_RskAdj_RAPS] PARTITION $Partition.[pfn_SummPY] (@PaymentYear)

--RE - 7056 

if (object_id('[Out].[tbl_Summary_RskAdj_RAPS]') is not null)

BEGIN
    
   Truncate table [Out].[tbl_Summary_RskAdj_RAPS];
 
End

--RE - 7056 



INSERT INTO [Out].[tbl_Summary_RskAdj_RAPS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [ModelYear],
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
    [LoadDateTime], --41262 Req 6 Add Populated column to 3 summary tables (MMR, MOR, RAPS) 
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
                                            -- Ticket # 25315
       [HICN] = [rskfct].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [ModelYear] = [rskfct].[ModelYear],
       [Factor_category] = 'RAPS',
       [Factor_Desc] = [rskfct].[HCC],
       [Factor_Desc_ORIG] = [rskfct].[HCC_ORIG],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [rskfct].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected], --[mmr].[RAFT]
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],  --[mmr].[RAFT_ORIG]
       [Min_Process_By] = [rskfct].[Min_Process_By],
       [Min_ThruDate] = [rskfct].[Min_Thru],
       [Min_ProcessBy_SeqNum] = [rskfct].[Min_ProcessBy_SeqNum],
       [Min_Thru_SeqNum] = [rskfct].[Min_Thru_SeqNum],
       [Min_Processby_DiagCD] = [rskfct].[Min_Processby_DiagCD],
       [Min_ThruDate_DiagCD] = [rskfct].[Min_ThruDate_DiagCD],
       [Min_ProcessBy_PCN] = [rskfct].[Min_ProcessBy_PCN],
       [Min_ThruDate_PCN] = [rskfct].[Min_ThruDate_PCN],
       [processed_priority_thru_date] = [rskfct].[Processed_Priority_Thru_Date],
                                            -- Ticket # 25658
       [thru_priority_processed_by] = [rskfct].[Thru_Priority_Processed_By],
                                            -- Ticket # 25658
       [Processed_Priority_FileID] = [rskfct].[Processed_Priority_FileID],
       [Processed_Priority_RAPS_Source_ID] = [rskfct].[Processed_Priority_RAPS_Source_ID],
       [Processed_Priority_Provider_ID] = [rskfct].[Processed_Priority_Provider_ID],
       [Processed_Priority_RAC] = [rskfct].[Processed_Priority_RAC],
       [Thru_Priority_FileID] = [rskfct].[Thru_Priority_FileID],
       [Thru_Priority_RAPS_Source_ID] = [rskfct].[Thru_Priority_RAPS_Source_ID],
       [Thru_Priority_Provider_ID] = [rskfct].[Thru_Priority_Provider_ID],
       [Thru_Priority_RAC] = [rskfct].[Thru_Priority_RAC],
       [IMFFlag] = [rskfct].[IMFFlag],
       [LoadDateTime] = @LoadDateTime,      --41262 Req 6 Add Populated column to 3 summary tables (MMR, MOR, RAPS) 
       [Aged] = [mmr].[Aged]
/* Ticket # 25703 END */
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
	
    JOIN [rev].[tbl_Intermediate_RAPS] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[RAFT] = [mmr].[PartCRAFTProjected] --[mmr].[RAFT]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[ModelYear]
           AND CAST(SUBSTRING([rskmod].[Factor_Description], 4, LEN([rskmod].[Factor_Description]) - 3) AS INT) = [rskfct].[HCC_Number]
           AND [rskmod].[OREC] = CASE
                                     WHEN mmr.PartCRAFTProjected IN ( 'C', 'CN', 'CP', 'CF', 'I', 'E', 'SE' ) THEN
                                         [mmr].[ORECRestated]
                                     ELSE
                                         '9999'
                                 END --HasanMF 6/20/2017: OREC is listed as 9999 in lk_Risk_Models for ESRD members.
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected] --[mmr].[RAFT]
           AND [rskmod].[Aged] = [mmr].[Aged] -- US60182

WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'HCC%'
	  and [mmr].PaymentYear=@PaymentYear;

SET @RowCount = ISNULL(@RowCount, 0) + @@ROWCOUNT;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '039',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


--Insert Interaction into tbl_Summary_RskAdj_RAPS_Preliminary
INSERT INTO [Out].[tbl_Summary_RskAdj_RAPS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [ModelYear],
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
    [LoadDateTime], --41262 Req 6 Add Populated column to 3 summary tables (MMR, MOR, RAPS) 
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
       [HICN] = [intr].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [ModelYear] = [intr].[ModelYear],
       [Factor_category] = 'RAPS-Interaction',
       [Factor_Desc] = [intr].[HCC],
       [Factor_Desc_ORIG] = [intr].[HCC_ORIG],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [intr].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected], --[mmr].[RAFT]
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],  --[mmr].[RAFT_ORIG]
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
       [LoadDateTime] = @LoadDateTime,      --41262 Req 6 Add Populated column to 3 summary tables (MMR, MOR, RAPS) 
       [Aged] = [mmr].[Aged]
/* Ticket # 25703 END */
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[tbl_Intermediate_RAPS_INT] [intr]
        ON [intr].[HICN] = [mmr].[HICN]
           AND [intr].[RAFT] = [mmr].[PartCRAFTProjected] --[mmr].[RAFT]
           AND [intr].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [rev].[tbl_Intermediate_RAPS_INTRank] [drvintr]
        ON [intr].[HICN] = [drvintr].[HICN]
           AND [intr].[RAFT] = [drvintr].[RAFT]
           AND [intr].[HCC] = [drvintr].[HCC]
           AND [intr].[Min_ProcessBy_SeqNum] = [drvintr].[Min_ProcessBy_SeqNum]
           AND [intr].[Min_Thru_SeqNum] = [drvintr].[Min_Thru_SeqNum] -- Ticket # 25353
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
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected] --[mmr].[RAFT]
           AND [rskmod].[Aged] = [mmr].[Aged] -- US60182
WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'INT%'
      AND [drvintr].[RankID] = 1
	  and [mmr].PaymentYear=@PaymentYear;

SET @RowCount = ISNULL(@RowCount, 0) + @@ROWCOUNT;


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '040',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

--and mmr.Payment_Year = @Payment_Year
-- Get disability interactions
INSERT INTO [Out].[tbl_Summary_RskAdj_RAPS]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [ModelYear],
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
    [LoadDateTime],
    [Aged]
)
SELECT DISTINCT
       [PlanID] = [mmr].[PlanID],
       [HICN] = [rskfct].[HICN],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymStart] = [mmr].[PaymStart],
       [Model_Year] = [rskfct].[ModelYear],
       [Factor_category] = 'RAPS-Disability',
       [Factor_Desc] = [rskmod].[Factor_Description],
       [Factor_Desc_ORIG] = [rskmod].[Factor_Description],
       [Factor] = [rskmod].[Factor],
       [HCC_Number] = [rskfct].[HCC_Number],
       [RAFT] = [mmr].[PartCRAFTProjected], --[mmr].[RAFT]
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],  --[mmr].[RAFT_ORIG]
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
       [Aged] = [mmr].[Aged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [rev].[tbl_Intermediate_RAPS] [rskfct]
        ON [rskfct].[HICN] = [mmr].[HICN]
           AND [rskfct].[RAFT] = [mmr].[PartCRAFTProjected] --[mmr].[RAFT]
           AND [rskfct].[PaymentYear] = [mmr].[PaymentYear]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rskmod]
        ON [rskmod].[Payment_Year] = [rskfct].[ModelYear]
           AND CAST(SUBSTRING([rskmod].[Factor_Description], 6, LEN([rskmod].[Factor_Description]) - 5) AS INT) = [rskfct].[HCC_Number]
           AND [rskmod].[OREC] = '9999'
           AND [rskmod].[Factor_Type] = [mmr].[PartCRAFTProjected] --[mmr].[RAFT]
           AND [rskmod].[Aged] = [mmr].[Aged] -- US60182
WHERE [rskmod].[Part_C_D_Flag] = 'C'
      AND [rskmod].[Demo_Risk_Type] = 'Risk'
      AND [rskmod].[Factor_Description] LIKE 'D-HCC%'
      AND [rskfct].[HCC] LIKE 'HCC%'
      AND [mmr].[RskAdjAgeGrp] < '6565'
	  and [mmr].PaymentYear=@PaymentYear;

SET @RowCount = ISNULL(@RowCount, 0) + @@ROWCOUNT;


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '041',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;


ALTER TABLE [Out].[tbl_Summary_RskAdj_RAPS] SWITCH  PARTITION $Partition.[pfn_SummPY] (@PaymentYear) TO [Rev].[tbl_Summary_RskAdj_RAPS] PARTITION $Partition.[pfn_SummPY] (@PaymentYear)


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '042',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;

SET @C = @C + 1

End;


/****************************************************************************************************************/
/*                           END OF Inserts into RAPSMORCombined table                                          */
/****************************************************************************************************************/