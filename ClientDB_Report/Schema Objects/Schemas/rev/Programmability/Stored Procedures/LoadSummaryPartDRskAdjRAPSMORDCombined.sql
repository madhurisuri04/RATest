CREATE PROC [rev].[LoadSummaryPartDRskAdjRAPSMORDCombined]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS /*****************************************************************************************************
* Name			:	rev.LoadSummaryPartDRskAdjRAPSMORDCombined											*
* Type 			:	Stored Procedure																	*
* Author       	:	David Waddell																		*
* Date			:	2016-12-10																			*
* Version			:																					*
* Description		: Part D Summary RAPS MORD Combined stored procedure will create a union of 		*
*					the information from Part D Summary RAPS and Part D Summary MORD for the            *
*                    entire client.                                                             		*
*																										*
* Version History :																						*
* =================================================================================================		*
* Author			Date		Version#    TFS Ticket#		Description									*
* -----------------	----------  --------    -----------		------------								*
* David Waddell		2018-01-18    1.0		68356 /Re-1208	Initial                                 	*																							*
* David Waddell     2018-05-28    1.1       70759 / RE-1889 Populate new LastAssignedHICN field in   	*
*                                                           [etl].[SummaryPartDRskAdjRAPSMORDCombined]	*
*                                                           table   (Sect. 54.5)                        *
 David Waddell     2018-06-05    1.2       70759 / RE-2127  Bug Fix: modify RE-1889 to fix join and    	*
*                                                           handle NULL LastAssignedHICN in          	*
*                                                           (Sect. 54.5)                                *
* D.Waddell			10/31/2019	1.3			77159/RE-6981	Set Transaction Isolation Level Read to     *
*                                                           UNCOMMITTED                                 *   
* Anand             5/29/2020   1.4          RRI-8/78743    Optimization                                                                                *
********************************************************************************************************/


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

SET @LoadDateTime = ISNULL(@LoadDateTime, @Today);
SET @DeleteBatch = ISNULL(@DeleteBatch, 250000);

IF (OBJECT_ID('tempdb.dbo.#Refresh_PY') IS NOT NULL)
BEGIN
    DROP TABLE [#Refresh_PY];
END;

/* Create #Refresh_PY Table */
/* #RefreshPY: Initialize Payment Years that need to be processed.*/

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

IF OBJECT_ID('[TEMPDB]..[#RAPS_MORD_DeciderPY]', 'U') IS NOT NULL
    DROP TABLE [#RAPS_MORD_DeciderPY];

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



/*Create #RAPS_MORD_DeciderPY table*/
/* This temp table is being set up as a placeholder for the latest available MMR Payment Month as well as latest available MOR Payment Month. */

IF OBJECT_ID('[TEMPDB]..[#RAPS_MORD_DeciderPY]', 'U') IS NOT NULL
    DROP TABLE [#RAPS_MORD_DeciderPY];

CREATE TABLE [#RAPS_MORD_DeciderPY]
(
    [PaymentYear] INT,
    [ModelYear] INT,
    [maxPayMStart] INT,
    [PaymonthMORD] INT
);


IF OBJECT_ID('[TEMPDB]..[#SummaryPartDRskAdjMORD]', 'U') IS NOT NULL
    DROP TABLE [#SummaryPartDRskAdjMORD];


CREATE TABLE [#SummaryPartDRskAdjMORD]
(
    [PaymentYear] INT,
    [ModelYear] INT,
    [maxPayMStart] INT
);


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '001.31',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


INSERT INTO [#SummaryPartDRskAdjMORD]
(
    [PaymentYear],
    [ModelYear],
    [maxPayMStart]
)
SELECT [MOR].[PaymentYear],
       [MOR].[ModelYear],
       [maxPayMStart] = MAX(MONTH([MOR].[PaymStart]))
FROM [rev].[SummaryPartDRskAdjMORD] [MOR] 
    JOIN [#Refresh_PY] [py]
        ON [MOR].[PaymentYear] = [py].[Payment_Year]
GROUP BY [MOR].[PaymentYear],
         [MOR].[ModelYear];
 

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

INSERT INTO [#RAPS_MORD_DeciderPY]
(
    [PaymentYear],
    [ModelYear],
    [maxPayMStart],
    [PaymonthMORD]
)
SELECT [MOR].[PaymentYear],
       [MOR].[ModelYear],
       [maxPayMStart],
       [PaymonthMORD] = RIGHT([DCP].[PayMonth], 2)
FROM [#SummaryPartDRskAdjMORD] [MOR] 
    INNER JOIN [dbo].[lk_DCP_dates_RskAdj] [DCP]
        ON [MOR].[PaymentYear] = LEFT([DCP].[PayMonth], 4)
    JOIN [#Refresh_PY] [py]
        ON [MOR].[PaymentYear] = [py].[Payment_Year]
WHERE [DCP].[MOR_Mid_Year_Update] = 'Y'
GROUP BY [MOR].[PaymentYear],
         [MOR].[ModelYear],
		 [maxPayMStart],
         RIGHT([DCP].[PayMonth], 2)
HAVING [maxPayMStart] >= RIGHT([DCP].[PayMonth], 2);

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

CREATE NONCLUSTERED INDEX [idx_#RAPS_MORD_DeciderPY]
ON [#RAPS_MORD_DeciderPY] (
                              [ModelYear],
                              [PaymonthMORD]
                          );

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '001.6',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;




IF OBJECT_ID('[TEMPDB]..[#MaxMORD]', 'U') IS NOT NULL
    DROP TABLE [#MaxMORD];

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


/*Create #maxMor Table */
/* Contains the latest available Payment Month available per HICN for each member available in Summary MORD ( [rev].[SummaryPartDRskAdjMORD] ) */

CREATE TABLE [#MaxMORD]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [RxHCCNumber] VARCHAR(5)
);


IF OBJECT_ID('[TEMPDB]..[#FinalMidMORD]', 'U') IS NOT NULL
    DROP TABLE [#FinalMidMORD];


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

CREATE TABLE [#FinalMidMORD]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [RxHCCNumber] INT
);


IF OBJECT_ID('[TEMPDB]..[#FinalInitialMidMORD]', 'U') IS NOT NULL
    DROP TABLE [#FinalInitialMidMORD];

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

CREATE TABLE [#FinalInitialMidMORD]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [RxHCCNumber] INT
);


IF OBJECT_ID('[TEMPDB]..[#FinalInitialMORD]', 'U') IS NOT NULL
    DROP TABLE [#FinalInitialMORD];

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

CREATE TABLE [#FinalInitialMORD]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [Paymstart] DATE,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [RxHCCNumber] INT
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
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [HCCNumber] INT
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
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [HCC_ORIG_ER] VARCHAR(50),
    [HCCNumber] INT
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
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [HCC_ORIG_ER] VARCHAR(50),
    [HCCNumber] INT
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
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [HCCNumber] INT
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
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [HCCNumber] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORDRAPSInitial]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSInitial];

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

CREATE TABLE [#TestMORDRAPSInitial]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [HCCNumber] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORDRAPSMid]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSMid];

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

CREATE TABLE [#TestMORDRAPSMid]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [HCCNumber] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORDRAPSFinal]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSFinal];

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

CREATE TABLE [#TestMORDRAPSFinal]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [RxHCCLabelOrig] VARCHAR(50),
    [HCCNumber] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORDRAPSFinalActual]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSFinalActual];

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

CREATE TABLE [#TestMORDRAPSFinalActual]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [RxHCCLabelOrig] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCCNumber] INT,
    [RelationFlag] VARCHAR(10)
);

IF OBJECT_ID('[TEMPDB]..[#TestMORDRAPSInitailUpdateRaps]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSInitailUpdateRaps];

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

CREATE TABLE [#TestMORDRAPSInitailUpdateRaps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(50),
    [RxHCCLabelOrig] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCCNumber] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORDRAPSMidUpdateRaps]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSMidUpdateRaps];

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

CREATE TABLE [#TestMORDRAPSMidUpdateRaps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [HCC] VARCHAR(120),
    [RxHCCLabel] VARCHAR(50),
    [RxHCCLabelOrig] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCCNumber] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinalUpdateRaps]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSFinalUpdateRaps];

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

CREATE TABLE [#TestMORDRAPSFinalUpdateRaps]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [FactorCategory] VARCHAR(50),
    [RxHCCLabel] VARCHAR(120),
    [RxHCCLabelOrig] VARCHAR(50),
    [factor] DECIMAL(20, 4),
    [HCCNumber] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSLowerHCC]', 'U') IS NOT NULL
    DROP TABLE [#TestMORDRAPSLowerHCC];

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

CREATE TABLE [#TestMORDRAPSLowerHCC]
(
    [PlanID] INT,
    [HICN] VARCHAR(20),
    [PY] INT,
    [MY] INT,
    [PartDRAFTRestated] VARCHAR(5),
    [Factor_Category] VARCHAR(50),
    [RxHCCLabel] VARCHAR(20),
    [RxHCCLabelOrig] VARCHAR(50),
    [Factor] DECIMAL(20, 4),
    [HCCNumber] INT,
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



IF (OBJECT_ID('tempdb.dbo.#MaxmStart') IS NOT NULL)
BEGIN
    DROP TABLE [#MaxmStart];
END;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '019.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;





CREATE TABLE [#MaxmStart]
(
    [PlanIdentifier] INT,
    [HICN] VARCHAR(20),
    [PaymentYear] INT,
    [ModelYear] INT,
    [maxPayMStart] DATE,
    [MofmaxPayMStart] INT
);


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '019.2',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



INSERT INTO [#MaxmStart]
(
    [PlanIdentifier],
    [HICN],
    [PaymentYear],
    [ModelYear],
    [maxPayMStart],
    [MofmaxPayMStart]
)
SELECT [a1].[PlanIdentifier],
       [a1].[HICN],
       [a1].[PaymentYear],
       [a1].[ModelYear],
       [maxPayMStart] = MAX([a1].[PaymStart]),
       [MofmaxPayMStart] = MONTH(MAX([a1].[PaymStart]))
FROM [rev].[SummaryPartDRskAdjMORD] [a1]
    INNER JOIN [#RAPS_MORD_DeciderPY] [dpy1]
        ON [a1].[PaymentYear] = [dpy1].[PaymentYear]
           AND [a1].[ModelYear] = [dpy1].[ModelYear]
GROUP BY [a1].[PlanIdentifier],
         [a1].[HICN],
         [a1].[PaymentYear],
         [a1].[ModelYear];


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '019.3',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



CREATE NONCLUSTERED INDEX [idx_#MaxmStart]
ON [#MaxmStart] (
                    [HICN],
                    [PaymentYear],
                    [ModelYear]
                );



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '019.4',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;




INSERT INTO [#MaxMORD]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [Paymstart],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxLabel],
    [factor],
    [RxHCCLabelOrig],
    [RxHCCNumber]
)
SELECT [m].[PlanIdentifier],
       [m].[HICN],
       [m].[PaymentYear],
       [m].[ModelYear],
       [m].[PaymStart],
       [m].[RxHCCNumber],
       [m].[FactorCategory],
       [m].[RxHCCLabel],
       [m].[Factor],
       [m].RxHCCLabel,
       [m].[RxHCCNumber]
FROM [rev].[SummaryPartDRskAdjMORD] [m] --NEW
    INNER JOIN [#RAPS_MORD_DeciderPY] [dpy]
        ON [m].[PaymentYear] = [dpy].[PaymentYear]
           AND [m].[ModelYear] = [dpy].[ModelYear]
    INNER JOIN [#MaxmStart] [a]
        ON [m].[HICN] = [a].[HICN]
           AND [m].[PaymentYear] = [a].[PaymentYear]
           AND [m].[ModelYear] = [a].[ModelYear]
           AND [m].[PaymStart] = [a].[maxPayMStart]
           AND [m].[PlanIdentifier] = [a].[PlanIdentifier]
           AND [a].[MofmaxPayMStart] >= [dpy].[PaymonthMORD];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '019.4',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



CREATE NONCLUSTERED INDEX [idx_#MaxMORD]
ON [#MaxMORD] (
                  [HICN],
                  [PY],
                  [MY],
                  [RxHCCNumber]
              );








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
    [PartDRAFTRestated],
    [FactorCategory],
    [RxHCCLabel],
    [factor],
    [RxHCCLabelOrig],
    [HCCNumber]
)
SELECT DISTINCT
       [a].[PlanIdentifier],
       [a].[HICN],
       [a].[PaymentYear],
       [a].[ModelYear],
       [a].[PartDRAFTRestated],
       [a].[FactorCategory],
       [a].[RxHCCLabel],
       [a].[Factor],
       [a].[RxHCCLabelOrig],
       [a].[HCCNumber]
FROM [rev].[SummaryPartDRskAdjRAPS] [a] -- NEW
    INNER JOIN [#RAPS_MORD_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[ModelYear] = [dpy].[ModelYear]
WHERE (
          [a].[RxHCCLabel] NOT LIKE ('HIER%')
          AND [a].[RxHCCLabel] NOT LIKE ('DEL%')
      ) --HasanMF 8/24/2017 (RE 1052 - For two (NOT LIKE) conditions, the operator needs to be (AND), instead of (OR)
      AND [a].[IMFFlag] = 1
OPTION (RECOMPILE);

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

CREATE NONCLUSTERED INDEX [idx_#RapsInitial]
ON [#RapsInitial] (
                      [HICN],
                      [PY],
                      [MY],
                      [RxHCCLabel],
                      [HCCNumber]
                  );

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
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxHCCLabel],
    [factor],
    [RxHCCLabelOrig],
    [HCCNumber]
)
SELECT DISTINCT
       [a].[PlanIdentifier],
       [a].[HICN],
       [a].[PaymentYear],
       [a].[ModelYear],
       [a].[PartDRAFTRestated],
       [a].[FactorCategory],
       [a].[RxHCCLabel],
       [a].[Factor],
       [a].[RxHCCLabelOrig],
       [a].[HCCNumber]
FROM [rev].[SummaryPartDRskAdjRAPS] [a]
    INNER JOIN [#RAPS_MORD_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[ModelYear] = [dpy].[ModelYear]
WHERE (
          [a].[RxHCCLabel] NOT LIKE ('HIER%')
          AND [a].[RxHCCLabel] NOT LIKE ('DEL%')
      ) --HasanMF 8/24/2017 RE 1052- For two (NOT LIKE) conditions, the operator needs to be (AND), instead of (OR)
      AND [a].[IMFFlag] = 2;


CREATE NONCLUSTERED INDEX [idx_#RapsMid]
ON [#RapsMid] (
                  [HICN],
                  [PY],
                  [MY],
                  [RxHCCLabel],
                  [HCCNumber]
              );




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
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxHCCLabel],
    [factor],
    [RxHCCLabelOrig],
    [HCCNumber]
)
SELECT DISTINCT
       [a].[PlanIdentifier],
       [a].[HICN],
       [a].[PaymentYear],
       [a].[ModelYear],
       [a].[PartDRAFTRestated],
       [a].[FactorCategory],
       [a].[RxHCCLabel],
       [a].[Factor],
       [a].[RxHCCLabelOrig],
       [a].[HCCNumber]
FROM [rev].[SummaryPartDRskAdjRAPS] [a] --NEW
    INNER JOIN [#RAPS_MORD_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[ModelYear] = [dpy].[ModelYear]
WHERE (
          [a].[RxHCCLabel] NOT LIKE ('HIER%')
          AND [a].[RxHCCLabel] NOT LIKE ('DEL%')
      )
      AND [a].[IMFFlag] = 3;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '022.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

CREATE NONCLUSTERED INDEX [idx_#RapsFinal]
ON [#RapsFinal] (
                    [HICN],
                    [PY],
                    [MY],
                    [RxHCCLabel],
                    [HCCNumber]
                );

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


INSERT INTO [#FinalMidMORD]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [Paymstart],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxLabel],
    [factor],
    [RxHCCLabelOrig],
    [RxHCCNumber]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [Paymstart],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxLabel],
       [factor],
       [RxHCCLabelOrig],
       [RxHCCNumber]
FROM [#MaxMORD]
EXCEPT
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t1].[Paymstart],
       [t].[PartDRAFTRestated],
       [t].[FactorCategory],
       [t1].[RxLabel],
       [t].[factor],
       [t].[RxHCCLabelOrig],
       [t1].[RxHCCNumber]
FROM [#MaxMORD] [t1]
    INNER JOIN [#RapsMid] [t]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PY] = [t1].[PY]
           AND [t].[MY] = [t1].[MY]
           AND [t].[HCCNumber] = [t1].[RxHCCNumber];



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '023.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

CREATE NONCLUSTERED INDEX [idx_#FinalMidMORD]
ON [#FinalMidMORD] (
                       [HICN],
                       [PY],
                       [MY],
                       [RxHCCLabelOrig],
                       [RxHCCNumber]
                   );




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







INSERT INTO [#FinalInitialMidMORD]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [Paymstart],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxLabel],
    [factor],
    [RxHCCLabelOrig],
    [RxHCCNumber]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [Paymstart],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxLabel],
       [factor],
       [RxHCCLabelOrig],
       [RxHCCNumber]
FROM [#FinalMidMORD]
EXCEPT
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t1].[Paymstart],
       [t].[PartDRAFTRestated],
       [t].[FactorCategory],
       [t1].[RxLabel],
       [t].[factor],
       [t].[RxHCCLabelOrig],
       [t1].[RxHCCNumber]
FROM [#FinalMidMORD] [t1]
    INNER JOIN [#RapsInitial] [t]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PY] = [t1].[PY]
           AND [t].[MY] = [t1].[MY]
           AND [t].[HCCNumber] = [t1].[RxHCCNumber];


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '024.2',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


CREATE NONCLUSTERED INDEX [idx_#FinalInitialMidMORD]
ON [#FinalInitialMidMORD] (
                              [HICN],
                              [PY],
                              [MY],
                              [RxHCCNumber]
                          );


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


INSERT INTO [#FinalInitialMORD]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [Paymstart],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxLabel],
    [factor],
    [RxHCCLabelOrig],
    [RxHCCNumber]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [Paymstart],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxLabel],
       [factor],
       [RxHCCLabelOrig],
       [RxHCCNumber]
FROM [#FinalInitialMidMORD]
EXCEPT
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t1].[Paymstart],
       [t].[PartDRAFTRestated],
       [t].[FactorCategory],
       [t1].[RxLabel],
       [t].[factor],
       [t].[RxHCCLabelOrig],
       [t1].[RxHCCNumber]
FROM [#FinalInitialMidMORD] [t1]
    INNER JOIN [#RapsInitial] [t]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PY] = [t1].[PY]
           AND [t].[MY] = [t1].[MY]
           AND [t].[HCCNumber] = [t1].[RxHCCNumber];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '025.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;


CREATE NONCLUSTERED INDEX [idx_#FinalInitialMORD]
ON [#FinalInitialMORD] (
                           [HICN],
                           [PY],
                           [MY],
                           [RxHCCNumber]
                       );




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








INSERT INTO [#TestMORDRAPSInitial]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxHCCLabel],
    [factor],
    [RxHCCLabelOrig],
    [HCCNumber]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       PartDRAFTRestated,
       [FactorCategory],
       RxHCCLabel,
       [factor],
       [RxHCCLabelOrig],
       [HCCNumber]
FROM [#RapsInitial]
UNION
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxLabel],
       [factor],
       [RxHCCLabelOrig],
       [RxHCCNumber]
FROM [#FinalInitialMORD];

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '026.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

CREATE NONCLUSTERED INDEX [idx_#TestMORDRAPSInitial]
ON [#TestMORDRAPSInitial] (
                              [HICN],
                              [PY],
                              [MY],
                              [PartDRAFTRestated],
                              [RxHCCLabel],
                              [RxHCCLabelOrig]
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

INSERT INTO [#TestMORDRAPSMid]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxHCCLabel],
    [factor],
    [RxHCCLabelOrig],
    [HCCNumber]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxHCCLabel],
       [factor],
       [RxHCCLabelOrig],
       [HCCNumber]
FROM [#RapsMid]
UNION
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxLabel],
       [factor],
       [RxHCCLabelOrig],
       [RxHCCNumber]
FROM [#FinalInitialMidMORD];


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '027.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



CREATE NONCLUSTERED INDEX [idx_#TestMORDRAPSMid]
ON [#TestMORDRAPSMid] (
                          [HICN],
                          [PY],
                          [MY],
                          [PartDRAFTRestated],
                          [RxHCCLabel],
                          [RxHCCLabelOrig]
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

INSERT INTO [#TestMORDRAPSFinal]
(
    [PlanID],
    [HICN],
    [PY],
    [MY],
    [PartDRAFTRestated],
    [FactorCategory],
    [RxHCCLabel],
    [factor],
    RxHCCLabelOrig,
    [HCCNumber]
)
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxHCCLabel],
       [factor],
       [RxHCCLabelOrig],
       [HCCNumber]
FROM [#RapsFinal]
UNION
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       [RxLabel],
       [factor],
       [RxHCCLabelOrig],
       [RxHCCNumber]
FROM [#MaxMORD];



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '028.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

CREATE NONCLUSTERED INDEX [idx_#TestMORDRAPSFinal]
ON [#TestMORDRAPSFinal] (
                            [HICN],
                            [PY],
                            [MY],
                            [PartDRAFTRestated],
                            [RxHCCLabel],
                            [RxHCCLabelOrig]
                        );

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
FROM [#TestMORDRAPSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCCNumber]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RxHCCLabel]
           AND [Hier].[Part_C_D_Flag] = 'D'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[RxHCCLabelOrig], 3) = 'HCC'
    INNER JOIN [#TestMORDRAPSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[PartDRAFTRestated] = [drp].[PartDRAFTRestated]
           AND [kep].[HCCNumber] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].RxHCCLabelOrig, 3) = 'HCC';

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
FROM [#TestMORDRAPSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCCNumber]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].PartDRAFTRestated
           AND [Hier].[Part_C_D_Flag] = 'D'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[RxHCCLabelOrig], 3) = 'HCC'
    INNER JOIN [#TestMORDRAPSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[PartDRAFTRestated] = [drp].[PartDRAFTRestated]
           AND [kep].[HCCNumber] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[RxHCCLabelOrig], 3) = 'HCC';

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
FROM [#TestMORDRAPSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCCNumber]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[PartDRAFTRestated]
           AND [Hier].[Part_C_D_Flag] = 'D'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[RxHCCLabelOrig], 3) = 'HCC'
    INNER JOIN [#TestMORDRAPSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[PartDRAFTRestated] = [drp].[PartDRAFTRestated]
           AND [kep].HCCNumber = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[RxHCCLabelOrig], 3) = 'HCC';

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
FROM [#TestMORDRAPSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].HCCNumber
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].PartDRAFTRestated
           AND [Hier].[Part_C_D_Flag] = 'D'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].RxHCCLabelOrig, 3) = 'HCC'
    INNER JOIN [#TestMORDRAPSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].PartDRAFTRestated = [drp].PartDRAFTRestated
           AND [kep].HCCNumber = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].RxHCCLabelOrig, 3) = 'HCC';

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



UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMORDRAPSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].HCCNumber
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].RxHCCLabel
           AND [Hier].[Part_C_D_Flag] = 'D'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].RxHCCLabelOrig, 3) = 'HCC'
    INNER JOIN [#TestMORDRAPSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].PartDRAFTRestated = [drp].PartDRAFTRestated
           AND [kep].[HCCNumber] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].RxHCCLabelOrig, 3) = 'HCC';

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


UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMORDRAPSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCCNumber]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].RxHCCLabel
           AND [Hier].[Part_C_D_Flag] = 'D'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].RxHCCLabelOrig, 3) = 'HCC'
    INNER JOIN [#TestMORDRAPSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].PartDRAFTRestated = [drp].PartDRAFTRestated
           AND [kep].[HCCNumber] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].RxHCCLabelOrig, 3) = 'HCC';




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
    SELECT PlanID,
           HICN,
           PY,
           MY,
           PartDRAFTRestated,
           FactorCategory,
           RxHCCLabel,
           factor,
           RxHCCLabelOrig,
           HCCNumber,
           RelationFlag
    FROM [#TestMORDRAPSFinal] [kep]
    WHERE [kep].[RelationFlag] = 'Same' -- <-- Source: [Factor_Category] = 'RAPS', 'RAPS-Disability', 'RAPS-Interaction'
) [a]
    INNER JOIN
    (
        SELECT PlanID,
               HICN,
               PY,
               MY,
               PartDRAFTRestated,
               FactorCategory,
               RxHCCLabel,
               factor,
               RxHCCLabelOrig,
               HCCNumber,
               RelationFlag
        FROM [#TestMORDRAPSFinal]
    ) [drp]
        ON [a].[HICN] = [drp].[HICN]
           AND [a].RxHCCLabel = [drp].RxHCCLabel
           AND [a].[HCCNumber] = [drp].[HCCNumber]
           AND [a].[PY] = [drp].[PY]
           AND [a].[MY] = [drp].[MY]
           AND LEFT([a].RxHCCLabelOrig, 3) = LEFT([drp].RxHCCLabelOrig, 3)
WHERE [drp].RxHCCLabel = 'MORD-HCC';

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


INSERT INTO [#TestMORDRAPSLowerHCC]
SELECT DISTINCT
       [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t].[PartDRAFTRestated],
       [t].[FactorCategory],
       [t].[RxHCCLabel],
       [t].[RxHCCLabelOrig],
       [t].[factor],
       [t].[HCCNumber],
       [t].[RelationFlag]
FROM [#TestMORDRAPSFinal] [t]
    INNER JOIN
    (
        SELECT DISTINCT
               [PlanID],
               [HICN],
               [PY],
               [MY],
               PartDRAFTRestated,
               [HCCNumber]
        FROM [#RapsInitial]
        UNION
        SELECT DISTINCT
               [PlanID],
               [HICN],
               [PY],
               [MY],
               [PartDRAFTRestated],
               [HCCNumber]
        FROM [#RapsMid]
    ) [a]
        ON [t].[HICN] = [a].[HICN]
           AND [t].[PY] = [a].[PY]
           AND [t].[MY] = [a].[MY]
           AND [t].[HCCNumber] = [a].[HCCNumber]
WHERE [t].RxHCCLabel = 'MORD-HCC'
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

INSERT INTO [#TestMORDRAPSFinalActual]
SELECT DISTINCT
       [t1].[PlanID],
       [t1].[HICN],
       [t1].[PY],
       [t1].[MY],
       [t1].[PartDRAFTRestated],
       [t1].[FactorCategory],
       [t1].[RxHCCLabel],
       [t1].[RxHCCLabelOrig],
       [t1].[factor],
       [t1].[HCCNumber],
       [t1].[RelationFlag]
FROM [#TestMORDRAPSFinal] [t1]
EXCEPT
SELECT [t2].PlanID,
       [t2].HICN,
       [t2].PY,
       [t2].MY,
       [t2].PartDRAFTRestated,
       [t2].Factor_Category,
       [t2].RxHCCLabel,
       [t2].RxHCCLabelOrig,
       [t2].Factor,
       [t2].HCCNumber,
       [t2].RelationFlag
FROM [#TestMORDRAPSLowerHCC] [t2];






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


UPDATE [#TestMORDRAPSFinalActual]
SET [RelationFlag] = NULL
FROM [#TestMORDRAPSFinalActual] [t]
    INNER JOIN [#TestMORDRAPSLowerHCC] [lh]
        ON [t].[HICN] = [lh].[HICN]
           AND [t].[PY] = [lh].[PY]
           AND [t].[MY] = [lh].[MY]
           AND LEFT([t].[RxHCCLabelOrig], 3) = LEFT([lh].[RxHCCLabelOrig], 3)
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


INSERT INTO [#TestMORDRAPSInitailUpdateRaps]
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       CASE
           WHEN (
                    [FactorCategory] = 'RAPS'
                    OR [FactorCategory] = 'RAPS-Disability'
                )
                AND [RelationFlag] = 'Drop' THEN
               'M-' + [RxHCCLabel]
           WHEN [FactorCategory] = 'MORD-HCC'
                AND [RelationFlag] = 'Keep' THEN
               'MOR-' + RxHCCLabel
           WHEN (
                    [FactorCategory] = 'RAPS'
                    OR [FactorCategory] = 'RAPS-Disability'
                )
                AND [RelationFlag] = 'Keep' THEN
               'M-High-' + RxHCCLabel
           WHEN [FactorCategory] = 'MORD-HCC'
                AND [RelationFlag] = 'Drop' THEN
               'MOR-INCR-' + [RxHCCLabel]
           ELSE
               [RxHCCLabel]
       END,
       [RxHCCLabelOrig],
       [factor],
       [HCCNumber]
FROM [#TestMORDRAPSInitial]
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


INSERT INTO [#TestMORDRAPSFinalUpdateRaps]
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       PartDRAFTRestated,
       [FactorCategory],
       CASE
           WHEN (
                    [FactorCategory] = 'RAPS'
                    OR [FactorCategory] = 'RAPS-Disability'
                )
                AND [RelationFlag] = 'Keep' THEN
               'M-High-' + RxHCCLabel
           WHEN (
                    [FactorCategory] = 'RAPS'
                    OR [FactorCategory] = 'RAPS-Disability'
                )
                AND
                (
                    [RelationFlag] = 'Drop'
                    OR [RelationFlag] = 'Same'
                ) THEN
               'M-' + RxHCCLabel
           WHEN [FactorCategory] = 'MORD-HCC'
                AND [RelationFlag] = 'Drop' THEN
               'MOR-INCR-' + RxHCCLabel
           WHEN [FactorCategory] = 'MORD-HCC'
                AND
                (
                    [RelationFlag] = 'Keep'
                    OR [RelationFlag] = 'Same'
                ) THEN
               'MOR-' + RxHCCLabel
           ELSE
               RxHCCLabel
       END,
       RxHCCLabelOrig,
       [factor],
       [HCCNumber]
FROM [#TestMORDRAPSFinalActual]
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


INSERT INTO [#TestMORDRAPSMidUpdateRaps]
SELECT [PlanID],
       [HICN],
       [PY],
       [MY],
       [PartDRAFTRestated],
       [FactorCategory],
       CASE
           WHEN (
                    [FactorCategory] = 'RAPS'
                    OR [FactorCategory] = 'RAPS-Disability'
                )
                AND [RelationFlag] = 'Keep' THEN
               'M-High-' + [RxHCCLabel]
           WHEN (
                    [FactorCategory] = 'RAPS'
                    OR [FactorCategory] = 'RAPS-Disability'
                )
                AND [RelationFlag] = 'Drop' THEN
               'M-' + [RxHCCLabel]
           WHEN [FactorCategory] = 'MORD-HCC'
                AND [RelationFlag] = 'Drop' THEN
               'MOR-INCR-' + [RxHCCLabel]
           WHEN [FactorCategory] = 'MORD-HCC'
                AND
                (
                    [RelationFlag] = 'Keep'
                    OR [RelationFlag] IS NULL
                ) THEN
               'MOR-' + [RxHCCLabel]
           ELSE
               [RxHCCLabel]
       END,
       [RxHCCLabel],
       [RxHCCLabelOrig],
       [factor],
       [HCCNumber]
FROM [#TestMORDRAPSMid]
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


/* Truncate the [etl].[SummaryPartDRskAdjRAPSMORDCombined] Table */

IF
(
    SELECT COUNT(1) FROM [etl].[SummaryPartDRskAdjRAPSMORDCombined]
) > 0
BEGIN
    TRUNCATE TABLE [etl].[SummaryPartDRskAdjRAPSMORDCombined];
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
/* Initial Insert into Summary RskAdj RAPS MORD CombinbedRiskFactor Table            */
/* US 53053 (TFS 55925)																*/
/************************************************************************************/
SET @RowCount = 0;

INSERT INTO [etl].[SummaryPartDRskAdjRAPSMORDCombined]
(
    [PlanIdentifier],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [ModelYear],
    [Factorcategory],
    [RxHCCLabel],
    [Factor],
    [PartDRAFTRestated],
    [RxHCCNumber],
    [MinProcessBy],
    [MinThruDate],
    [MinProcessBySeqNum],
    [MinThruDateSeqNum],
    [MinProcessbyDiagCD],
    [MinThruDateDiagCD],
    [MinProcessByPCN],
    [MinThruDatePCN],
    [ProcessedPriorityThruDate],
    [ThruPriorityProcessedBy],
    [PartDRAFTMMR],
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
    [Aged],
    [LoadDate],
    [UserID]
)
SELECT [m1].[PlanIdentifier],
       [m1].[HICN],
       [m1].[PaymentYear],
       [m1].[PaymStart],
       [m1].[ModelYear],
       [m1].[FactorCategory],
       [m1].[RxHCCLabel],
       [m1].[Factor],
       [m1].[PartDRAFTRestated],
       [m1].[HCCNumber],
       [m1].[MinProcessBy],
       [m1].[MinThruDate],
       [m1].[MinProcessBySeqNum],
       [m1].[MinThruDateSeqNum],
       [m1].[MinProcessbyDiagCD],
       [m1].[MinThruDateDiagCD],
       [m1].[MinProcessByPCN],
       [m1].[MinThruDatePCN],
       [m1].[ProcessedPriorityThruDate],
       [m1].[ThruPriorityProcessedBy],
       [m1].[PartDRAFTMMR],
       [m1].[ProcessedPriorityFileID],
       [m1].[ProcessedPriorityRAPSSourceID],
       [m1].[ProcessedPriorityProviderID],
       [m1].[ProcessedPriorityRAC],
       [m1].[ThruPriorityFileID],
       [m1].[ThruPriorityRAPSSourceID],
       [m1].[ThruPriorityProviderID],
       [m1].[ThruPriorityRAC],
       [m1].[IMFFlag],
       [m1].[RxHCCLabelOrig],
       [m1].[Aged],
       [LoadDateTime] = @LoadDateTime,
       [UserID] = CURRENT_USER
FROM [rev].[SummaryPartDRskAdjRAPS] [m1] --NEW
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
SET [t].[RxHCCLabel] = [t1].[RxHCCLabel]
FROM [etl].[SummaryPartDRskAdjRAPSMORDCombined] [t]
    INNER JOIN [#TestMORDRAPSInitailUpdateRaps] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[PartDRAFTRestated] = [t1].[PartDRAFTRestated]
           AND [t].[RxHCCNumber] = [t1].[HCCNumber]
           AND [t].[ModelYear] = [t1].[MY]
           AND [t].[Factorcategory] = [t1].[FactorCategory]
WHERE [t].[IMFFlag] = 1
      AND [t].[RxHCCLabel] NOT LIKE ('HIER%');

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
SET [t].[RxHCCLabel] = [t1].[RxHCCLabel]
FROM [etl].[SummaryPartDRskAdjRAPSMORDCombined] [t]
    INNER JOIN [#TestMORDRAPSMidUpdateRaps] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[PartDRAFTRestated] = [t1].[PartDRAFTRestated]
           AND [t].[RxHCCNumber] = [t1].[HCCNumber]
           AND [t].[ModelYear] = [t1].[MY]
           AND [t].[Factorcategory] = [t1].[FactorCategory]
WHERE [t].[IMFFlag] = 2
      AND [t].[RxHCCLabel] NOT LIKE ('HIER%');

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
SET [t].[RxHCCLabel] = [t1].[RxHCCLabel]
FROM [etl].[SummaryPartDRskAdjRAPSMORDCombined] [t]
    -- #tbl_Summary_RskAdj_RAPSMORCombined [t]
    INNER JOIN [#TestMORDRAPSFinalUpdateRaps] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[PartDRAFTRestated] = [t1].[PartDRAFTRestated]
           AND [t].[RxHCCNumber] = [t1].[HCCNumber]
           AND [t].[ModelYear] = [t1].[MY]
           AND [t].[Factorcategory] = [t1].[FactorCategory]
WHERE [t].[IMFFlag] = 3
      AND [t].[RxHCCLabel] NOT LIKE ('HIER%');

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




INSERT INTO [etl].[SummaryPartDRskAdjRAPSMORDCombined]
(
    [PlanIdentifier],
    [HICN],
    [PaymentYear],
    [ModelYear],
    [PartDRAFTRestated],
    [Factorcategory],
    [RxHCCLabel],
    [RxHCCLabelOrig],
    [Factor],
    [RxHCCNumber],
    [LoadDate]
)
SELECT [t].[PlanID],
       [t].[HICN],
       [PaymentYear] = [t].[PY],
       [ModelYear] = [t].[MY],
       [t].PartDRAFTRestated,
       [t].[FactorCategory],
       [t].RxHCCLabel,
       [t].RxHCCLabelOrig,
       [t].[factor],
       [t].HCCNumber,
       [LoadDateTime] = @LoadDateTime
FROM [#TestMORDRAPSMidUpdateRaps] [t]
    INNER JOIN [#RapsMid] [r]
        ON [t].[PlanID] = [r].[PlanID]
           AND [t].[HICN] = [r].[HICN]
           AND [t].[PY] = [r].[PY]
           AND [t].[MY] = [r].[MY]
           AND [t].PartDRAFTRestated = [r].PartDRAFTRestated
WHERE [t].[FactorCategory] = 'MORD-HCC'
UNION
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t].PartDRAFTRestated,
       [t].[FactorCategory],
       [t].RxHCCLabel,
       [t].RxHCCLabelOrig,
       [t].[factor],
       [t].HCCNumber,
       @LoadDateTime
FROM [#TestMORDRAPSFinalUpdateRaps] [t]
    INNER JOIN [#RapsFinal] [r]
        ON [t].[PlanID] = [r].[PlanID]
           AND [t].[HICN] = [r].[HICN]
           AND [t].[PY] = [r].[PY]
           AND [t].[MY] = [r].[MY]
           AND [t].PartDRAFTRestated = [r].PartDRAFTRestated
WHERE [t].[FactorCategory] = 'MORD-HCC'
UNION
SELECT [t].[PlanID],
       [t].[HICN],
       [t].[PY],
       [t].[MY],
       [t].PartDRAFTRestated,
       [t].[FactorCategory],
       [t].RxHCCLabel,
       [t].RxHCCLabelOrig,
       [t].[factor],
       [t].[HCCNumber],
       @LoadDateTime
FROM [#TestMORDRAPSInitailUpdateRaps] [t]
    INNER JOIN [#RapsInitial] [r]
        ON (
               [t].[PlanID] = [r].[PlanID]
               AND [t].[HICN] = [r].[HICN]
               AND [t].[PY] = [r].[PY]
               AND [t].[MY] = [r].[MY]
               AND [t].PartDRAFTRestated = [r].PartDRAFTRestated
           )
WHERE [t].[FactorCategory] = 'MORD-HCC';

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '054.5',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;

UPDATE [m1]
SET [m1].[LastAssignedHICN] = ISNULL(   [b].[LastAssignedHICN],
                                        CASE
                                            WHEN ssnri.fnValidateMBI([m1].[HICN]) = 1 THEN
                                                [b].[HICN]
                                        END
                                    )
FROM [etl].[SummaryPartDRskAdjRAPSMORDCombined] [m1]
    CROSS APPLY
(
    SELECT TOP 1
           [b].[LastAssignedHICN],
           [b].[HICN]
    FROM [rev].[tbl_Summary_RskAdj_AltHICN] AS [b]
    WHERE [b].[FINALHICN] = [m1].[HICN]
    ORDER BY [LoadDateTime] DESC
) AS [b];




SET @RowCount = ISNULL(@RowCount, 0) + @@rowcount;


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


/* Switch partitions for each PaymentYear */

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

        TRUNCATE TABLE [out].[SummaryPartDRskAdjRAPSMORDCombined];

        -- Switch Partition for History SummaryPartDRskAdjMORD 

        ALTER TABLE [hst].[SummaryPartDRskAdjRAPSMORDCombined] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].[SummaryPartDRskAdjRAPSMORDCombined] PARTITION $Partition.[pfn_SummPY](@PaymentYear);

        -- Switch Partition for REV SummaryPartDRskAdjMORD 
        ALTER TABLE [rev].[SummaryPartDRskAdjRAPSMORDCombined] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [hst].[SummaryPartDRskAdjRAPSMORDCombined] PARTITION $Partition.[pfn_SummPY](@PaymentYear);

        -- Switch Partition for ETL SummaryPartDRskAdjMORD	
        ALTER TABLE [etl].[SummaryPartDRskAdjRAPSMORDCombined] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [rev].[SummaryPartDRskAdjRAPSMORDCombined] PARTITION $Partition.[pfn_SummPY](@PaymentYear);

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

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '056',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;