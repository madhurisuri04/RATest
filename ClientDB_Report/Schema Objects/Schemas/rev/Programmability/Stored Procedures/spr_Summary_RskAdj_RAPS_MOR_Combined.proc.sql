CREATE PROC [rev].[spr_Summary_RskAdj_RAPS_MOR_Combined]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS /*****************************************************************************************************
* Name			:	rev.spr_Summary_RskAdj_RAPS_MOR_Combined											*
* Type 			:	Stored Procedure																	*
* Author       	:	Mitch Casto																			*
* Date			:	2016-03-21																			*
* Version			:																					*
* Description		: Updates dbo.tbl_Summary_RskAdj_MOR table with raw MOR data						*
*					Note: This stp is an adaptation from Summary 1.0 and will need further work to		*
*					optimize the sql.																	*
*																										*
* Version History :																						*
* =================================================================================================		*
* Author			Date		Version#    TFS Ticket#		Description									*
* -----------------	----------  --------    -----------		------------								*
* Mitch Casto		2016-05-18	1.0			53367			Initial										*
* David Waddell		2016-07-28  1.1			54208	  		Setting up RAPS-MOR Combined Summary Table	*																							*
*																										*
* David Waddell		2016-09-19  1.2			55925			Add insert statement for RAPS-MOR Combined	*
* David Waddell		2016-01-04  1.3			US60182			Add [AGED] in Insert statement	Summary		*
*															Table  US53053								* 
* Mitch Casto		2017-03-27	1.4			63302/US63790	Removed @ManualRun process and replaced	with*
*															parameterizeddelete batch (Section 049)		*
*																										*
*																										*
* David Waddell     2017-09-01	1.5			66645/RE-1052  Sect. 20,21,22 for the [#RAPS_MOR_DeciderPY] *
*                                                           inner joins, for the two a.[Factor Desc]    *
*                                                           (NOT LIKE) conditions, the operator needs to*
*                                                            be (AND), instead of (OR)                  *
* Notes: Can Section 009 & 010 be combined or added to 008?												*
*																										*
* David Waddell    2018-05-28   1.6         70759 /RE-1889  Populate the new LastAssignedHICN column in *
*                                           the rev.tbl_Summary_RskAdj_RAPS_MOR_Combined table          *   
*                                           (Sect. 54.5)                                                *
* David Waddell    2018-06-05   1.7         70759 /RE-2127  Bug Fix: modify RE-1889 to fix join and     *
*                                           handle NULL LastAssignedHICN in                             *   
*                                           (Sect. 54.5)                                                *
* Rakshit Lall		2018-07-23	1.8			Restricted data to 'RAPS' where MOR summary table is used	*
* D.Waddell			10/29/2019	1.9			RE-6981	Set Transaction Isolation Level Read to Uncommitted *
********************************************************************************************************/


SET NOCOUNT ON;
SET STATISTICS IO OFF;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF @Debug = 1
BEGIN
    SET STATISTICS IO ON;
    DECLARE @ET DATETIME;
    DECLARE @MasterET DATETIME;
    DECLARE @ProcessNameIn VARCHAR(128);
    DECLARE @Model_Year INT;
    DECLARE @Payment_Year INT;
    DECLARE @RapsInitialCountAfter INT;

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
SET @DeleteBatch = ISNULL(@DeleteBatch, 250000);

IF (OBJECT_ID('tempdb.dbo.#Refresh_PY') IS NOT NULL)
BEGIN
    DROP TABLE [#Refresh_PY];
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
    EXEC [dbo].[PerfLogMonitor] '001',
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
    EXEC [dbo].[PerfLogMonitor] '001.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

IF OBJECT_ID('[TEMPDB]..[#RAPS_MOR_DeciderPY]', 'U') IS NOT NULL
    DROP TABLE [#RAPS_MOR_DeciderPY];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '001.2',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

CREATE TABLE [#RAPS_MOR_DeciderPY]
(
    [PaymentYear] INT,
    [Model_Year] INT,
    [maxPayMStart] VARCHAR(5),
    [Paymonth_MOR] VARCHAR(6)
);

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '001.3',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

INSERT INTO [#RAPS_MOR_DeciderPY]
(
    [PaymentYear],
    [Model_Year],
    [maxPayMStart],
    [Paymonth_MOR]
)
SELECT [MOR].[PaymentYear],
       [MOR].[Model_Year],
       [maxPayMStart] = MAX(MONTH([MOR].[PaymStart])),
       [Paymonth_MOR] = RIGHT([DCP].[PayMonth], 2)
FROM [rev].[tbl_Summary_RskAdj_MOR] [MOR]
    INNER JOIN [dbo].[lk_DCP_dates_RskAdj] [DCP]
        ON [MOR].[PaymentYear] = LEFT([DCP].[PayMonth], 4)
    JOIN [#Refresh_PY] [py]
        ON [MOR].[PaymentYear] = [py].[Payment_Year]
WHERE [DCP].[MOR_Mid_Year_Update] = 'Y'
      AND [MOR].SubmissionModel = 'RAPS'
GROUP BY [MOR].[PaymentYear],
         [MOR].[Model_Year],
         RIGHT([DCP].[PayMonth], 2)
HAVING MAX(MONTH([MOR].[PaymStart])) >= RIGHT([DCP].[PayMonth], 2);

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '001.4',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;




IF OBJECT_ID('[TEMPDB]..[#MaxMOR]', 'U') IS NOT NULL
    DROP TABLE [#MaxMOR];

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

CREATE TABLE [#MaxMOR]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);


IF OBJECT_ID('[TEMPDB]..[#FinalMidMOR]', 'U') IS NOT NULL
    DROP TABLE [#FinalMidMOR];


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

CREATE TABLE [#FinalMidMOR]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);


IF OBJECT_ID('[TEMPDB]..[#FinalInitialMidMOR]', 'U') IS NOT NULL
    DROP TABLE [#FinalInitialMidMOR];

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

CREATE TABLE [#FinalInitialMidMOR]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);


IF OBJECT_ID('[TEMPDB]..[#FinalInitialMOR]', 'U') IS NOT NULL
    DROP TABLE [#FinalInitialMOR];

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

CREATE TABLE [#FinalInitialMOR]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);


IF OBJECT_ID('[TEMPDB]..[#RapsInitial]', 'U') IS NOT NULL
    DROP TABLE [#RapsInitial];

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

CREATE TABLE [#RapsInitial]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);


IF OBJECT_ID('[TEMPDB]..[#Raps]', 'U') IS NOT NULL
    DROP TABLE [#Raps];


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

CREATE TABLE [#Raps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC_ORIG_ER] VARCHAR(50),
    [HCC_Number] INT
);


IF OBJECT_ID('[TEMPDB]..[#RapsMORUnion]', 'U') IS NOT NULL
    DROP TABLE [#RapsMORUnion];

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

CREATE TABLE [#RapsMORUnion]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC_ORIG_ER] VARCHAR(50),
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#RapsMid]', 'U') IS NOT NULL
    DROP TABLE [#RapsMid];

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

CREATE TABLE [#RapsMid]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#RapsFinal]', 'U') IS NOT NULL
    DROP TABLE [#RapsFinal];

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

CREATE TABLE [#RapsFinal]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSInitial]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSInitial];

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

CREATE TABLE [#TestMORRAPSInitial]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSMid]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSMid];

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

CREATE TABLE [#TestMORRAPSMid]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinal]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSFinal];

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

CREATE TABLE [#TestMORRAPSFinal]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_ORIG] VARCHAR(50),
    [HCC_Number] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinalActual]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSFinalActual];

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

CREATE TABLE [#TestMORRAPSFinalActual]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(50),
    [HCC_ORIG] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_Number] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSInitailUpdateRaps]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSInitailUpdateRaps];

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

CREATE TABLE [#TestMORRAPSInitailUpdateRaps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    /*B TFS44158 MC */
    [HCC] VARCHAR(50),
    /*E TFS44158 MC */
    [HCC_ORIG] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSMidUpdateRaps]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSMidUpdateRaps];

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

CREATE TABLE [#TestMORRAPSMidUpdateRaps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(120),
    [HCC_ORIG] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinalUpdateRaps]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSFinalUpdateRaps];

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

CREATE TABLE [#TestMORRAPSFinalUpdateRaps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(120),
    [HCC_ORIG] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSLowerHCC]', 'U') IS NOT NULL
    DROP TABLE [#TestMORRAPSLowerHCC];

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

CREATE TABLE [#TestMORRAPSLowerHCC]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [RAFT] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [HCC] VARCHAR(20),
    [HCC_ORIG] VARCHAR(50),
    [Factor] DECIMAL(20, 4),
    [HCC_Number] INT,
    [RelationFlag] VARCHAR(10)
);

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

INSERT INTO [#MaxMOR] --truncate table [#MaxMOR]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [Paymstart],
    [RAFT],
    [Factor_Category],
    [HCC],
    [factor],
    [HCC_ORIG],
    [HCC_Number]
)
SELECT [m].[PlanID],
       [m].[HICN],
       [m].[PaymentYear],
       [m].[Model_Year],
       [m].[PaymStart],
       [m].[RAFT],
       [m].[Factor_Category],
       [m].[Factor_Description],
       [m].[Factor],
       [m].[Factor_Description],
       [m].[HCC_Number]
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    INNER JOIN [#RAPS_MOR_DeciderPY] [dpy]
        ON [m].[PaymentYear] = [dpy].[PaymentYear]
           AND [m].[Model_Year] = [dpy].[Model_Year]
    INNER JOIN
    (
        SELECT [a1].[PlanID],
               [a1].[HICN],
               [a1].[PaymentYear],
               [a1].[Model_Year],
               [maxPayMStart] = MAX([a1].[PaymStart]),
               [MofmaxPayMStart] = MONTH(MAX([a1].[PaymStart]))
        FROM [rev].[tbl_Summary_RskAdj_MOR] [a1]
            INNER JOIN [#RAPS_MOR_DeciderPY] [dpy1]
                ON [a1].[PaymentYear] = [dpy1].[PaymentYear]
                   AND [a1].[Model_Year] = [dpy1].[Model_Year]
        GROUP BY [a1].[PlanID],
                 [a1].[HICN],
                 [a1].[PaymentYear],
                 [a1].[Model_Year]
    ) [a]
        ON [m].[HICN] = [a].[HICN]
           AND [m].[PaymentYear] = [a].[PaymentYear]
           AND [m].[Model_Year] = [a].[Model_Year]
           AND [m].[PaymStart] = [a].[maxPayMStart]
           AND [m].[PlanID] = [a].[PlanID]
           AND [a].[MofmaxPayMStart] >= [dpy].[Paymonth_MOR]
WHERE m.SubmissionModel = 'RAPS';

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

INSERT INTO [#RapsInitial]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [RAFT],
    [Factor_Category],
    [HCC],
    [factor],
    [HCC_ORIG],
    [HCC_Number]
)
SELECT DISTINCT
       [a].[PlanID],
       [a].[HICN],
       [a].[PaymentYear],
       [a].[ModelYear],
       [a].[RAFT],
       [a].[Factor_category],
       [a].[Factor_Desc],
       [a].[Factor],
       [a].[Factor_Desc_ORIG],
       [a].[HCC_Number]
FROM [rev].[tbl_Summary_RskAdj_RAPS] [a]
    INNER JOIN [#RAPS_MOR_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[ModelYear] = [dpy].[Model_Year]
WHERE (
          [a].[Factor_Desc] NOT LIKE ('HIER%')
          AND [a].[Factor_Desc] NOT LIKE ('DEL%')
      ) --HasanMF 8/24/2017 (RE 1052 - For two (NOT LIKE) conditions, the operator needs to be (AND), instead of (OR)
      AND [a].[IMFFlag] = 1
OPTION (RECOMPILE);

IF @Debug = 1
BEGIN

    SELECT @RapsInitialCountAfter = COUNT(*)
    FROM [#RapsInitial];
    PRINT '[@RapsInitialCountAfter] = ' + ISNULL(CAST(@RapsInitialCountAfter AS VARCHAR(11)), 'NULL');
    PRINT '[@Payment_year         ] = ' + ISNULL(CAST(@Payment_Year AS VARCHAR(11)), 'NULL');
    PRINT '[@Model_Year           ] = ' + ISNULL(CAST(@Model_Year AS VARCHAR(11)), 'NULL');
    EXEC [dbo].[PerfLogMonitor] '021',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

INSERT INTO [#RapsMid]
SELECT DISTINCT
       [a].[PlanID],
       [a].[HICN],
       [a].[PaymentYear],
       [a].[ModelYear],
       [a].[RAFT],
       [a].[Factor_category],
       [a].[Factor_Desc],
       [a].[Factor],
       [a].[Factor_Desc_ORIG],
       [a].[HCC_Number]
FROM [rev].[tbl_Summary_RskAdj_RAPS] [a]
    INNER JOIN [#RAPS_MOR_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[ModelYear] = [dpy].[Model_Year]
WHERE (
          [a].[Factor_Desc] NOT LIKE ('HIER%')
          AND [a].[Factor_Desc] NOT LIKE ('DEL%')
      ) --HasanMF 8/24/2017 RE 1052- For two (NOT LIKE) conditions, the operator needs to be (AND), instead of (OR)
      AND [a].[IMFFlag] = 2;

IF @Debug = 1
BEGIN
    PRINT '[@Payment_year] = ' + ISNULL(CAST(@Payment_Year AS VARCHAR(11)), 'NULL');
    PRINT '[@Model_Year  ] = ' + ISNULL(CAST(@Model_Year AS VARCHAR(11)), 'NULL');
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


INSERT INTO [#RapsFinal]
SELECT DISTINCT
       [a].[PlanID],
       [a].[HICN],
       [a].[PaymentYear],
       [a].[ModelYear],
       [a].[RAFT],
       [a].[Factor_category],
       [a].[Factor_Desc],
       [a].[Factor],
       [a].[Factor_Desc_ORIG],
       [a].[HCC_Number]
FROM [rev].[tbl_Summary_RskAdj_RAPS] [a]
    INNER JOIN [#RAPS_MOR_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[ModelYear] = [dpy].[Model_Year]
WHERE (
          [a].[Factor_Desc] NOT LIKE ('HIER%')
          AND [a].[Factor_Desc] NOT LIKE ('DEL%')
      ) --HasanMF 8/24/2017 RE 1052- For two (NOT LIKE) conditions, the operator needs to be (AND), instead of (OR)
      AND [a].[IMFFlag] = 3;

IF @Debug = 1
BEGIN
    PRINT '[@Payment_year] = ' + ISNULL(CAST(@Payment_Year AS VARCHAR(11)), 'NULL');
    PRINT '[@Model_Year  ] = ' + ISNULL(CAST(@Model_Year AS VARCHAR(11)), 'NULL');
END;

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


INSERT INTO [#FinalMidMOR] --HMF 5/7/2016: contains 2nd half MOR HCCs that are not in (1st MOR or RAPS IMFFlag = 2)
SELECT *
FROM [#MaxMOR] --HMF 5/7/2016: contains the last available MOR HCCs post Midyear adjusted payment
EXCEPT
SELECT [t1].*
FROM [#MaxMOR] [t1]
    INNER JOIN [#RapsMid] [t] --HMF 5/7/2016: contains RAPS HCCs with IMFFlag = 2 
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PY] = [t1].[PY]
           AND [t].[MY] = [t1].[MY]
           AND [t].[HCC_Number] = [t1].[HCC_Number];


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

INSERT INTO [#FinalInitialMidMOR]
SELECT *
FROM [#FinalMidMOR] --HMF 5/7/2016: contains 2nd half MOR HCCs that are not in (1st MOR or RAPS IMFFlag = 2)
EXCEPT
SELECT [t1].*
FROM [#FinalMidMOR] [t1]
    INNER JOIN [#RapsInitial] [t] --HMF 5/7/2016: contains RAPS HCCs with IMFFlag = 1 
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PY] = [t1].[PY]
           AND [t].[MY] = [t1].[MY]
           AND [t].[HCC_Number] = [t1].[HCC_Number];


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


INSERT INTO [#FinalInitialMOR]
SELECT *
FROM [#FinalInitialMidMOR]
EXCEPT
SELECT [t1].*
FROM [#FinalInitialMidMOR] [t1]
    INNER JOIN [#RapsInitial] [t]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PY] = [t1].[PY]
           AND [t].[MY] = [t1].[MY]
           AND [t].[HCC_Number] = [t1].[HCC_Number];

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

-- finding hierarchy between RAPS and MOR ticket # 25703
INSERT INTO [#TestMORRAPSInitial]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [RAFT],
    [Factor_Category],
    [HCC],
    [factor],
    [HCC_ORIG],
    [HCC_Number]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       [HCC],
       [factor],
       [HCC_ORIG],
       [HCC_Number]
FROM [#RapsInitial]
UNION
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       [HCC],
       [factor],
       [HCC_ORIG],
       [HCC_Number]
FROM [#FinalInitialMOR];

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

INSERT INTO [#TestMORRAPSMid]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [RAFT],
    [Factor_Category],
    [HCC],
    [factor],
    [HCC_ORIG],
    [HCC_Number]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       [HCC],
       [factor],
       [HCC_ORIG],
       [HCC_Number]
FROM [#RapsMid]
UNION
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       [HCC],
       [factor],
       [HCC_ORIG],
       [HCC_Number]
FROM [#FinalInitialMidMOR];

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

INSERT INTO [#TestMORRAPSFinal]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [RAFT],
    [Factor_Category],
    [HCC],
    [factor],
    [HCC_ORIG],
    [HCC_Number]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       [HCC],
       [factor],
       [HCC_ORIG],
       [HCC_Number]
FROM [#RapsFinal]
UNION
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       [HCC],
       [factor],
       [HCC_ORIG],
       [HCC_Number]
FROM [#MaxMOR];

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

-- HCC Hierarchy Updates
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORRAPSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMORRAPSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

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

UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORRAPSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMORRAPSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

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

UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORRAPSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMORRAPSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

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


--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORRAPSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMORRAPSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

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


--and kep.Factor_Category = drp.Factor_Category
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORRAPSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMORRAPSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

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

--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORRAPSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMORRAPSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

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

-- Interaction updates
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORRAPSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                  '%[A-Z]%',
                                                                                  REVERSE([Hier].[HCC_DROP_NUMBER])
                                                                              ) - 1)
                             )
                     ) AS INT) = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'INT'
           AND LEFT([drp].[HCC_ORIG], 3) = 'INT'
    INNER JOIN [#TestMORRAPSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([Hier].[HCC_KEEP_NUMBER])
                                                                                                       ) - 1)
                                                      )
                                              ) AS INT)
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'INT';

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


UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORRAPSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                  '%[A-Z]%',
                                                                                  REVERSE([Hier].[HCC_DROP_NUMBER])
                                                                              ) - 1)
                             )
                     ) AS INT) = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'INT'
           AND LEFT([drp].[HCC_ORIG], 3) = 'INT'
    INNER JOIN [#TestMORRAPSInitial] [kep]
        ON [kep].[PlanID] = [drp].[PlanID]
           AND [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([Hier].[HCC_KEEP_NUMBER])
                                                                                                       ) - 1)
                                                      )
                                              ) AS INT)
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'INT';

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


UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORRAPSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                  '%[A-Z]%',
                                                                                  REVERSE([Hier].[HCC_DROP_NUMBER])
                                                                              ) - 1)
                             )
                     ) AS INT) = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'INT'
           AND LEFT([drp].[HCC_ORIG], 3) = 'INT'
    INNER JOIN [#TestMORRAPSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([Hier].[HCC_KEEP_NUMBER])
                                                                                                       ) - 1)
                                                      )
                                              ) AS INT)
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'INT';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '038',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORRAPSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                  '%[A-Z]%',
                                                                                  REVERSE([Hier].[HCC_DROP_NUMBER])
                                                                              ) - 1)
                             )
                     ) AS INT) = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'INT'
           AND LEFT([drp].[HCC_ORIG], 3) = 'INT'
    INNER JOIN [#TestMORRAPSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([Hier].[HCC_KEEP_NUMBER])
                                                                                                       ) - 1)
                                                      )
                                              ) AS INT)
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'INT';

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


--and kep.Factor_Category = drp.Factor_Category
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORRAPSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                  '%[A-Z]%',
                                                                                  REVERSE([Hier].[HCC_DROP_NUMBER])
                                                                              ) - 1)
                             )
                     ) AS INT) = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'INT'
           AND LEFT([drp].[HCC_ORIG], 3) = 'INT'
    INNER JOIN [#TestMORRAPSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([Hier].[HCC_KEEP_NUMBER])
                                                                                                       ) - 1)
                                                      )
                                              ) AS INT)
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'INT';

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


--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORRAPSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_DROP_NUMBER]), PATINDEX(
                                                                                  '%[A-Z]%',
                                                                                  REVERSE([Hier].[HCC_DROP_NUMBER])
                                                                              ) - 1)
                             )
                     ) AS INT) = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'INT'
           AND LEFT([drp].[HCC_ORIG], 3) = 'INT'
    INNER JOIN [#TestMORRAPSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([Hier].[HCC_KEEP_NUMBER]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([Hier].[HCC_KEEP_NUMBER])
                                                                                                       ) - 1)
                                                      )
                                              ) AS INT)
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'INT';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '041',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


--select * from #TestMORRAPSMid
--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Same'
FROM [#TestMORRAPSFinal] [kep]
    INNER JOIN [#MaxMOR] [drp]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [drp].[HCC_Number]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([drp].[HCC_ORIG], 3) = LEFT([kep].[HCC_ORIG], 3)
WHERE [kep].[Factor_Category] = 'RAPS'
      OR [kep].[Factor_Category] = 'RAPS-Disability'
      OR [kep].[Factor_Category] = 'RAPS-Interaction';

--OR kep.Factor_Category = 'MOR-HCC'

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '042',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


UPDATE [drp]
SET [drp].[RelationFlag] = 'Same'
FROM
(
    SELECT *
    FROM [#TestMORRAPSFinal] [kep]
    WHERE [kep].[RelationFlag] = 'Same' -- <-- Source: [Factor_Category] = 'RAPS', 'RAPS-Disability', 'RAPS-Interaction'
) [a]
    INNER JOIN
    (SELECT * FROM [#TestMORRAPSFinal]) [drp]
        ON [a].[HICN] = [drp].[HICN]
           AND [a].[RAFT] = [drp].[RAFT]
           AND [a].[HCC_Number] = [drp].[HCC_Number]
           AND [a].[PY] = [drp].[PY]
           AND [a].[MY] = [drp].[MY]
           AND LEFT([a].[HCC_ORIG], 3) = LEFT([drp].[HCC_ORIG], 3)
WHERE [drp].[Factor_Category] = 'MOR-HCC';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '043',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


INSERT INTO [#TestMORRAPSLowerHCC]
SELECT DISTINCT
       [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t].[RAFT],
       [t].[Factor_Category],
       [t].[HCC],
       [t].[HCC_ORIG],
       [t].[factor],
       [t].[HCC_Number],
       [t].[RelationFlag]
FROM [#TestMORRAPSFinal] [t]
    INNER JOIN
    (
        SELECT DISTINCT
               [PlanID],
               [HICN],
               [PY],
               [MY],
               [RAFT],
               [HCC_Number]
        FROM [#RapsInitial]
        UNION
        SELECT DISTINCT
               [PlanID],
               [HICN],
               [PY],
               [MY],
               [RAFT],
               [HCC_Number]
        FROM [#RapsMid]
    ) [a]
        ON [t].[HICN] = [a].[HICN]
           AND [t].[PY] = [a].[PY]
           AND [t].[MY] = [a].[MY]
           AND [t].[HCC_Number] = [a].[HCC_Number]
WHERE [t].[Factor_Category] = 'MOR-HCC'
      AND [t].[RelationFlag] = 'Drop';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '044',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

INSERT INTO [#TestMORRAPSFinalActual]
SELECT DISTINCT
       [t1].[PlanID],
       [t1].[HICN],
       [t1].[PY],
       [t1].[MY],
       [t1].[RAFT],
       [t1].[Factor_Category],
       [t1].[HCC],
       [t1].[HCC_ORIG],
       [t1].[factor],
       [t1].[HCC_Number],
       [t1].[RelationFlag]
FROM [#TestMORRAPSFinal] [t1]
EXCEPT
SELECT *
FROM [#TestMORRAPSLowerHCC];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '045',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


UPDATE [#TestMORRAPSFinalActual]
SET [RelationFlag] = NULL
FROM [#TestMORRAPSFinalActual] [t]
    INNER JOIN [#TestMORRAPSLowerHCC] [lh]
        ON [t].[HICN] = [lh].[HICN]
           AND [t].[PY] = [lh].[PY]
           AND [t].[MY] = [lh].[MY]
           AND LEFT([t].[HCC_ORIG], 3) = LEFT([lh].[HCC_ORIG], 3)
WHERE [t].[RelationFlag] = 'Keep';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '046',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


INSERT INTO [#TestMORRAPSInitailUpdateRaps]
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       CASE
           WHEN (
                    [Factor_Category] = 'RAPS'
                    OR [Factor_Category] = 'RAPS-Disability'
                    OR [Factor_Category] = 'RAPS-Interaction'
                )
                AND [RelationFlag] = 'Drop' THEN
               'M-' + [HCC]
           WHEN [Factor_Category] = 'MOR-HCC'
                AND [RelationFlag] = 'Keep' THEN
               'MOR-' + [HCC]
           WHEN (
                    [Factor_Category] = 'RAPS'
                    OR [Factor_Category] = 'RAPS-Disability'
                    OR [Factor_Category] = 'RAPS-Interaction'
                )
                AND [RelationFlag] = 'Keep' THEN
               'M-High-' + [HCC]
           WHEN [Factor_Category] = 'MOR-HCC'
                AND [RelationFlag] = 'Drop' THEN
               'MOR-INCR-' + [HCC]
           ELSE
               [HCC]
       END,
       [HCC_ORIG],
       [factor],
       [HCC_Number]
FROM [#TestMORRAPSInitial]
WHERE [RelationFlag] IS NOT NULL;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '047',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


INSERT INTO [#TestMORRAPSFinalUpdateRaps]
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       CASE
           WHEN (
                    [Factor_Category] = 'RAPS'
                    OR [Factor_Category] = 'RAPS-Disability'
                    OR [Factor_Category] = 'RAPS-Interaction'
                )
                AND [RelationFlag] = 'Keep' THEN
               'M-High-' + [HCC]
           WHEN (
                    [Factor_Category] = 'RAPS'
                    OR [Factor_Category] = 'RAPS-Disability'
                    OR [Factor_Category] = 'RAPS-Interaction'
                )
                AND
                (
                    [RelationFlag] = 'Drop'
                    OR [RelationFlag] = 'Same'
                ) THEN
               'M-' + [HCC]
           WHEN [Factor_Category] = 'MOR-HCC'
                AND [RelationFlag] = 'Drop' THEN
               'MOR-INCR-' + [HCC]
           WHEN [Factor_Category] = 'MOR-HCC'
                AND
                (
                    [RelationFlag] = 'Keep'
                    OR [RelationFlag] = 'Same'
                ) THEN
               'MOR-' + [HCC]
           ELSE
               [HCC]
       END,
       [HCC_ORIG],
       [factor],
       [HCC_Number]
FROM [#TestMORRAPSFinalActual]
WHERE [RelationFlag] IS NOT NULL;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '048',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


INSERT INTO [#TestMORRAPSMidUpdateRaps]
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [RAFT],
       [Factor_Category],
       CASE
           WHEN (
                    [Factor_Category] = 'RAPS'
                    OR [Factor_Category] = 'RAPS-Disability'
                    OR [Factor_Category] = 'RAPS-Interaction'
                )
                AND [RelationFlag] = 'Keep' THEN
               'M-High-' + [HCC]
           WHEN (
                    [Factor_Category] = 'RAPS'
                    OR [Factor_Category] = 'RAPS-Disability'
                    OR [Factor_Category] = 'RAPS-Interaction'
                )
                AND [RelationFlag] = 'Drop' THEN
               'M-' + [HCC]
           WHEN [Factor_Category] = 'MOR-HCC'
                AND [RelationFlag] = 'Drop' THEN
               'MOR-INCR-' + [HCC]
           WHEN [Factor_Category] = 'MOR-HCC'
                AND
                (
                    [RelationFlag] = 'Keep'
                    OR [RelationFlag] IS NULL
                ) THEN
               'MOR-' + [HCC]
           ELSE
               [HCC]
       END,
       [HCC_ORIG],
       [factor],
       [HCC_Number]
FROM [#TestMORRAPSMid]
WHERE [RelationFlag] IS NOT NULL;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '049',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/*************************************************************************************/
/* Delete records from Summary RskAdj RAPS MOR CombinbedRiskFactor Table             */
/* based on Payment Year in [#Refresh_PY]                                             */
/*************************************************************************************/

WHILE (1 = 1)
BEGIN

    DELETE TOP (@DeleteBatch)
    [m1]
    FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [m1]
        JOIN [#Refresh_PY] [py] --US53053 8/22/2016 - Deleting table upon RefreshPY  (TFS 55925)
            ON [m1].[PaymentYear] = [py].[Payment_Year];

    IF @@rowcount = 0
        BREAK;
    ELSE
        CONTINUE;
END;


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '050',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/************************************************************************************/
/* Initial Insert into Summary RskAdj RAPS MOR CombinbedRiskFactor Table            */
/* US 53053 (TFS 55925)																*/
/************************************************************************************/
SET @RowCount = 0;

INSERT INTO [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [ModelYear],
    [Factor_category],
    [Factor_Desc],
    [Factor],
    [RAFT],
    [HCC_Number],
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
    [RAFT_ORIG],
    [Processed_Priority_FileID],
    [Processed_Priority_RAPS_Source_ID],
    [Processed_Priority_Provider_ID],
    [Processed_Priority_RAC],
    [Thru_Priority_FileID],
    [Thru_Priority_RAPS_Source_ID],
    [Thru_Priority_Provider_ID],
    [Thru_Priority_RAC],
    [IMFFlag],
    [Factor_Desc_ORIG],
    [LoadDateTime],
    [Aged] --US 601821921

)
SELECT [m1].[PlanID],
       [m1].[HICN],
       [m1].[PaymentYear],
       [m1].[PaymStart],
       [m1].[ModelYear],
       [m1].[Factor_category],
       [m1].[Factor_Desc],
       [m1].[Factor],
       [m1].[RAFT],
       [m1].[HCC_Number],
       [m1].[Min_ProcessBy],
       [m1].[Min_ThruDate],
       [m1].[Min_ProcessBy_SeqNum],
       [m1].[Min_ThruDate_SeqNum],
       [m1].[Min_Processby_DiagCD],
       [m1].[Min_ThruDate_DiagCD],
       [m1].[Min_ProcessBy_PCN],
       [m1].[Min_ThruDate_PCN],
       [m1].[Processed_Priority_Thru_Date],
       [m1].[Thru_Priority_Processed_By],
       [m1].[RAFT_ORIG],
       [m1].[Processed_Priority_FileID],
       [m1].[Processed_Priority_RAPS_Source_ID],
       [m1].[Processed_Priority_Provider_ID],
       [m1].[Processed_Priority_RAC],
       [m1].[Thru_Priority_FileID],
       [m1].[Thru_Priority_RAPS_Source_ID],
       [m1].[Thru_Priority_Provider_ID],
       [m1].[Thru_Priority_RAC],
       [m1].[IMFFlag],
       [m1].[Factor_Desc_ORIG],
       [LoadDateTime] = @LoadDateTime,
       [m1].[Aged] --US 60182

FROM [rev].[tbl_Summary_RskAdj_RAPS] [m1]
    JOIN [#Refresh_PY] [py]
        ON [m1].[PaymentYear] = [py].[Payment_Year];





SET @RowCount = @@rowcount;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '051',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


UPDATE [t]
SET [t].[Factor_Desc] = [t1].[HCC]
FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [t]
    --  #tbl_Summary_RskAdj_RAPSMORCombined [t]
    INNER JOIN [#TestMORRAPSInitailUpdateRaps] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[RAFT] = [t1].[RAFT]
           AND [t].[HCC_Number] = [t1].[HCC_Number]
           AND [t].[ModelYear] = [t1].[MY]
           AND [t].[Factor_category] = [t1].[Factor_Category]
WHERE [t].[IMFFlag] = 1
      AND [t].[Factor_Desc] NOT LIKE ('HIER%');

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '052',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


UPDATE [t]
SET [t].[Factor_Desc] = [t1].[HCC]
FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [t]
    --   #tbl_Summary_RskAdj_RAPSMORCombined [t]
    INNER JOIN [#TestMORRAPSMidUpdateRaps] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[RAFT] = [t1].[RAFT]
           AND [t].[HCC_Number] = [t1].[HCC_Number]
           AND [t].[ModelYear] = [t1].[MY]
           AND [t].[Factor_category] = [t1].[Factor_Category]
WHERE [t].[IMFFlag] = 2
      AND [t].[Factor_Desc] NOT LIKE ('HIER%');

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '053',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


UPDATE [t]
SET [t].[Factor_Desc] = [t1].[HCC]
FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [t]
    -- #tbl_Summary_RskAdj_RAPSMORCombined [t]
    INNER JOIN [#TestMORRAPSFinalUpdateRaps] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[RAFT] = [t1].[RAFT]
           AND [t].[HCC_Number] = [t1].[HCC_Number]
           AND [t].[ModelYear] = [t1].[MY]
           AND [t].[Factor_category] = [t1].[Factor_Category]
WHERE [t].[IMFFlag] = 3
      AND [t].[Factor_Desc] NOT LIKE ('HIER%');

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '054',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


/* 41262 req 6 The LoadDatetime added to the insert for the MOR records. */

INSERT INTO [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [ModelYear],
    [RAFT],
    [Factor_category],
    [Factor_Desc],
    [Factor_Desc_ORIG],
    [Factor],
    [HCC_Number],
    [LoadDateTime]
)
SELECT [t].[PlanID],
       [t].[HICN],
       [PaymentYear] = [t].[PY],
       [Model_Year] = [t].[MY],
       [t].[RAFT],
       [t].[Factor_Category],
       [t].[HCC],
       [t].[HCC_ORIG],
       [t].[factor],
       [t].[HCC_Number],
       [LoadDateTime] = @LoadDateTime
FROM [#TestMORRAPSMidUpdateRaps] [t]
    INNER JOIN [#RapsMid] [r]
        ON [t].[PlanID] = [r].[PlanID]
           AND [t].[HICN] = [r].[HICN]
           AND [t].[PY] = [r].[PY]
           AND [t].[MY] = [r].[MY]
           AND [t].[RAFT] = [r].[RAFT]
WHERE [t].[Factor_Category] = 'MOR-HCC'
UNION
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t].[RAFT],
       [t].[Factor_Category],
       [t].[HCC],
       [t].[HCC_ORIG],
       [t].[factor],
       [t].[HCC_Number],
       @LoadDateTime
FROM [#TestMORRAPSFinalUpdateRaps] [t]
    INNER JOIN [#RapsFinal] [r]
        ON [t].[PlanID] = [r].[PlanID]
           AND [t].[HICN] = [r].[HICN]
           AND [t].[PY] = [r].[PY]
           AND [t].[MY] = [r].[MY]
           AND [t].[RAFT] = [r].[RAFT]
WHERE [t].[Factor_Category] = 'MOR-HCC'
UNION
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t].[RAFT],
       [t].[Factor_Category],
       [t].[HCC],
       [t].[HCC_ORIG],
       [t].[factor],
       [t].[HCC_Number],
       @LoadDateTime
FROM [#TestMORRAPSInitailUpdateRaps] [t]
    INNER JOIN [#RapsInitial] [r]
        ON (
               [t].[PlanID] = [r].[PlanID]
               AND [t].[HICN] = [r].[HICN]
               AND [t].[PY] = [r].[PY]
               AND [t].[MY] = [r].[MY]
               AND [t].[RAFT] = [r].[RAFT]
           )
WHERE [t].[Factor_Category] = 'MOR-HCC';

SET @RowCount = ISNULL(@RowCount, 0) + @@rowcount;



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '054.5',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [m1]
SET [m1].[LastAssignedHICN] = ISNULL(   [b].[LastAssignedHICN],
                                        CASE
                                            WHEN ssnri.fnValidateMBI([m1].[HICN]) = 1 THEN
                                                [b].[HICN]
                                        END
                                    )
FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [m1]
    CROSS APPLY
(
    SELECT TOP 1
           [b].[LastAssignedHICN],
           [b].[HICN]
    FROM [rev].[tbl_Summary_RskAdj_AltHICN] AS [b]
    WHERE [b].[FINALHICN] = [m1].[HICN]
    ORDER BY [LoadDateTime] DESC
) AS [b]
    JOIN [#Refresh_PY] [py]
        ON [m1].[PaymentYear] = [py].[Payment_Year];






IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '055',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;
