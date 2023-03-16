CREATE PROCEDURE [rev].[LoadSummaryPartDRskAdjMORD]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS
/****************************************************************************************************/
/* Name			:	rev.LoadSummaryPartDRskAdjMORD													*/
/* Type 		:	Stored Procedure																*/
/* Author       :	David Waddell																	*/
/* Date			:	2017-10-17																		*/
/* Version		:	1.0																				*/
/* Description	: Part D Summary MORD stored procedure will gather MOR-D information (CMS report 	*/
/*				  on RxHCCs currently paid on) for the entire client. currently paid on) for        */
/*                the entire client. This data will then be sorted for membership eligibility      	*/
/*				  and the Part D HCC data will have select demographic information added to them.   */
/*				  The final step of this process will insert the data into a permanent table output.*/
/*                                                                                                  */
/* Version History :																				*/
/* =================================================================================================*/
/* Author			Date		Version#    TFS Ticket#		Description								*/
/* ---------------	----------  --------    -----------		------------		     				*/
/* D. Waddell		2017-11-12	1.0			53367			Initial									*/
/* D. Waddell       2018-01-26  1.1         69226(RE-1357)	 Select for insert into summary sourced */
/*                                                         from Summary MMR [Aged] changed to       */
/*                                                          to now pick up from [PartDAged].    	*/
/*																									*/
/* D.Waddell		10/31/2019	1.2	        77159/RE-6981Set Transaction Isolation Level Read to    */
/*                                          UNCOMMITTED                                             */
/*  Anand			07/07/2021  1.3		    RRI-660			Point to New MOR Source Tables*/
/****************************************************************************************************/



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
SET @DeleteBatch = ISNULL(@DeleteBatch, 125000);


IF (OBJECT_ID('tempdb.dbo.[#AlthicnMORD]') IS NOT NULL)
BEGIN
    DROP TABLE [#AlthicnMORD];
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

CREATE TABLE [#AlthicnMORD]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [HICN] VARCHAR(12) NULL,
    [PayMonth] VARCHAR(8) NULL,
    [Month] INT,
    [NAME] VARCHAR(50) NULL,
    [RecordType] CHAR(1) NULL,
    [PlanIdentifier] SMALLINT NOT NULL,
    [COMM] DECIMAL(20, 4),
    [PayMonthStart] DATE,
    [PayMonthYear] INT
);

IF (OBJECT_ID('tempdb.dbo.[#Refresh_PY]') IS NOT NULL)
BEGIN
    DROP TABLE [#Refresh_PY];
END;


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

/* Identify Years to Refresh Data */
CREATE TABLE [#Refresh_PY]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [Payment_Year] INT,
    [From_Date] DATE,
    [Thru_Date] DATE,
    [Lagged_From_Date] DATE,
    [Lagged_Thru_Date] DATE
);


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
INSERT INTO [#Refresh_PY]
(
    [Payment_Year],
    [From_Date],
    [Thru_Date],
    [Lagged_From_Date],
    [Lagged_Thru_Date]
)
SELECT [Payment_Year] = [a1].[Payment_Year],
       [From_Date] = [a1].[From_Date],
       [Thru_Date] = [a1].[Thru_Date],
       [Lagged_From_Date] = [a1].[Lagged_From_Date],
       [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];

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

INSERT INTO [#AlthicnMORD]
(
    [HICN],
    [PayMonth],
    [Month],
    [NAME],
    [RecordType],
    [PlanIdentifier],
    [COMM],
    [PayMonthStart],
    [PayMonthYear]
)
SELECT [HICN] = ISNULL([althcn].[FINALHICN], [a].[HICN]),
       [PayMonth] = [a].[PayMonth],
       [Month] = CAST(RIGHT([a].[PayMonth], 2) AS INT),
       [Name] = [a].[HCC],
       [RecordType] = [a].[RecordType],
       [PlanIdentifier] = [rp].[PlanIdentifier],
       [Comm] = [a].[Factor],
       [PayMonthStart] = RIGHT([a].[PayMonth], 2) + '/01/' + LEFT([a].[PayMonth], 4),
       [PayMonthYear] = CAST(LEFT([a].[PayMonth], 4) AS INT)
FROM [rev].[SummaryRskAdjMORSourcePartD] [a] WITH (NOLOCK)
	LEFT JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp on rp.PlanID = a.PlanID 
    LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn] WITH (NOLOCK)
        ON [rp].[PlanIdentifier] = [althcn].[PlanID]
           AND [a].[HICN] = [althcn].[HICN]	
    JOIN [#Refresh_PY] [py]
        ON (LEFT([a].[PayMonth], 4) = [py].[Payment_Year])
WHERE [a].[HICN] IS NOT NULL
      AND CAST(RIGHT([a].[PayMonth], 2) AS INT) <= 12;

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


CREATE NONCLUSTERED INDEX [idx_#AltHICNMOR_HICN]
ON [#AlthicnMORD] (
                      [HICN],
                      [NAME],
                      [RecordType],
                      [PlanIdentifier],
                      [PayMonth]
                  )
INCLUDE ([Month]);

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

IF OBJECT_ID('tempdb..#tmp_MaxPlanID') IS NOT NULL
BEGIN
    DROP TABLE [#tmp_MaxPlanID];
END;



CREATE TABLE [#tmp_MaxPlanID]
(
    [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [PlanID] INT,
    [HICN] VARCHAR(12),
    [PaymStart] DATETIME,
    [Month] INT,
    [Year] INT,
    [OREC_CALC] VARCHAR(5),
    [HOSP] VARCHAR(1) NULL,
    [RAFT] VARCHAR(3) NULL,
    [Aged] INT
);

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







IF (OBJECT_ID('tempdb.dbo.[#tmp_MaxPaymStart]') IS NOT NULL)
BEGIN
    DROP TABLE [#tmp_MaxPaymStart];
END;




CREATE TABLE [#tmp_MaxPaymStart]
(
    [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [HICN] VARCHAR(12),
    [PaymentYear] INT,
    [PaymStart] DATETIME
);

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



INSERT INTO [#tmp_MaxPaymStart]
(
    HICN,
    [PaymentYear],
    PaymStart
)
SELECT [mi].[HICN],
       [mi].[PaymentYear],
       MAX([PaymStart]) AS MaxPaymStart
FROM [rev].[tbl_Summary_RskAdj_MMR] [mi]
GROUP BY [HICN],
         [mi].[PaymentYear];


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

INSERT INTO [#tmp_MaxPlanID]
(
    [PlanID],
    [HICN],
    [PaymStart],
    [Month],
    [Year],
    [OREC_CALC],
    [Aged]
)
SELECT DISTINCT
       [PlanId] = [mmr].[PlanID],
       [HICN] = [mmr].[HICN],
       [PaymStart] = [mmr].[PaymStart],
       [Month] = MONTH([mmr].[PaymStart]),
       [Year] = YEAR([mmr].[PaymStart]),
       [OREC_CALC] = [mmr].[ORECRestated],
       [Aged] = [mmr].[PartDAged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [#Refresh_PY] [py]
        ON [mmr].[PaymentYear] = [py].[Payment_Year]
    JOIN [#tmp_MaxPaymStart] [mxp]
        ON [mxp].[HICN] = [mmr].[HICN]
           AND [mxp].[PaymStart] = [mmr].[PaymStart]
           AND [mxp].[PaymentYear] = [mmr].[PaymentYear];

/*   temp table #tmp_CTE_mmr  */

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


IF OBJECT_ID('tempdb..#tmp_CTE_mmr') IS NOT NULL
BEGIN
    DROP TABLE [#tmp_CTE_mmr];
END;


CREATE TABLE [#tmp_CTE_mmr]
(
    [PlanId] INT,
    [HICN] VARCHAR(12),
    [PartDRAFTProjected] VARCHAR(2),
    [PaymentYear] INT,
    [PaymentMonth] INT,
    [PaymStart] DATETIME,
    [PartDRAFTMMR] VARCHAR(2),
    [OREC] VARCHAR(5),
    [OREC_CALC] VARCHAR(5),
    [HOSP] VARCHAR(1),
    [AgeGrp] VARCHAR(4),
    [PriorPaymentYear] INT,
    [Aged] INT
);

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '010.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

INSERT INTO [#tmp_CTE_mmr]
(
    [PlanId],
    [HICN],
    [PartDRAFTProjected],
    [PaymentYear],
    [PaymentMonth],
    [PaymStart],
    [PartDRAFTMMR],
    [OREC],
    [OREC_CALC],
    [HOSP],
    [AgeGrp],
    [PriorPaymentYear],
    [Aged]
)
SELECT DISTINCT
       [PlanId] = [mmr].[PlanID],
       [HICN] = [mmr].[HICN],
       [PartDRAFTProjected] = [mmr].[PartDRAFTProjected],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymentMonth] = MONTH([mmr].[PaymStart]),
       [PaymStart] = [mmr].[PaymStart],
       [PartDRAFTMMR] = [mmr].[PartDRAFTMMR],
       [OREC] = [mmr].[ORECMMR],
       [OREC_CALC] = [mmr].[ORECRestated],
       [HOSP] = [mmr].[HOSP],
       [AgeGrp] = [mmr].[RskAdjAgeGrp],
       [PriorPaymentYear] = [mmr].[PriorPaymentYear],
       [Aged] = [mmr].[PartDAged]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [#Refresh_PY] [py]
        ON [mmr].[PaymentYear] = [py].[Payment_Year];

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





CREATE NONCLUSTERED INDEX [idx_#MaxPlanID_HICN]
ON [#tmp_MaxPlanID] (
                        [HICN],
                        [PaymStart],
                        [RAFT],
                        [HOSP]
                    )
INCLUDE (
            [PlanID],
            [OREC_CALC]
        )
WHERE [HICN] IS NULL
      AND [HOSP] = 'Y'
 ;

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


IF OBJECT_ID('tempdb..#RAFTUpdate') IS NOT NULL
BEGIN
    DROP TABLE #RAFTUpdate;
END;


CREATE TABLE #RAFTUpdate
(
    [PlanId] INT,
    [HICN] VARCHAR(12),
    [PartDRAFTProjected] VARCHAR(2),
    [PaymentYear] INT,
    [PartDRAFTMMR] VARCHAR(2),
    [MaxPaymstart] DATETIME
);
INSERT INTO #RAFTUpdate
SELECT DISTINCT
       [PlanId] = [mmr].[PlanID],
       [HICN] = [mmr].[HICN],
       [PartDRAFTProjected] = [mmr].[PartDRAFTProjected],
       [PaymentYear] = [mmr].[PaymentYear],
       [PartDRAFTMMR] = [mmr].[PartDRAFTMMR],
       MaxPaymstart = MAX([PaymStart])
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [#Refresh_PY] [py]
        ON [mmr].[PaymentYear] = [py].[Payment_Year]
WHERE mmr.PartDRAFTMMR IS NOT NULL
      AND mmr.PartDRAFTProjected IS NOT NULL
GROUP BY [mmr].[PlanID],
         [mmr].[HICN],
         [mmr].[PartDRAFTProjected],
         [mmr].[PaymentYear],
         [mmr].[PartDRAFTMMR];


/* Truncate the ETL Summary PartDRskAdjMORD Table */

IF
(
    SELECT COUNT(1) FROM [etl].[SummaryPartDRskAdjMORD]
) > 0
BEGIN
    TRUNCATE TABLE [etl].[SummaryPartDRskAdjMORD];
END;

/*PlanID revist to determine how logic works*/

/* Load Data into Summary PartD Rsk Adj MORD ETL Table */
INSERT INTO [etl].[SummaryPartDRskAdjMORD]
(
    [PaymentYear],
    [PlanIdentifier],
    [HICN],
    [PaymStart],
    [ModelYear],
    [FactorCategory],
    [RxHCCLabel],
    [Factor],
    [RxHCCNumber],
    [PartDRAFT],
    [PartDRAFTMMR],
    [RecordType],
    [HOSP],
    [ORECCalc],
    [Aged],
    [LoadDate],
    [UserID]
)
SELECT DISTINCT
       [PaymentYear] = [t1].[PaymentYear],
       [PlanIdentifier] = [t1].[PlanIdentifier],
       [HICN] = [t1].[HICN],
       [PaymStart] = [t1].[PaymStart],
       [ModelYear] = [t1].[ModelYear],
       [FactorCategory] = [t1].[Factor_Category],
       [RxHCCLabel] = [t1].[RxHCCLabel],
       [Factor] = [t1].[Factor],
       [RxHCCNumber] = [t1].[RxHCCNumber],
       [PartDRAFT] = [t1].[PartDRAFT],
       [PartDRAFTMMR] = [t1].[PartDRAFTMMR],
       [RecordType] = [t1].[RecordType],
       [HOSP] = [t1].[HOSP],
       [ORECCALC] = [t1].[ORECCALC],
       [Aged] = [t1].[Aged],
       [LoadDate] = @LoadDateTime,
       [UserID] = CURRENT_USER
FROM
(
    SELECT [PaymentYear] = [m].[PayMonthYear],
           [PlanIdentifier] = COALESCE([mp].[PlanID], [e].[PlanId], [m].[PlanIdentifier]),
           [HICN] = [m].[HICN],
           [PaymStart] = [m].[PayMonthStart],
           -- This logic for gathering ModelYear is based a modernized lookup table. This lookup table will account for all different RecordTypes coming out of MOR records.
           [ModelYear] = [m].[PayMonthYear],
           [Factor_Category] = 'MORD-HCC',
           [RxHCCLabel] = [m].[NAME],
           [Factor] = 0,
           [RxHCCNumber] = LTRIM(REVERSE(LEFT(REVERSE([m].[NAME]), PATINDEX('%[A-Z]%', REVERSE([m].[NAME])) - 1))),
           [PartDRAFT] = [e].[PartDRAFTProjected],
           [PartDRAFTMMR] = [e].[PartDRAFTMMR],
           [RecordType] = [m].[RecordType],
           [HOSP] = [e].[HOSP],
           [ORECCALC] = [e].[OREC_CALC],
           [Aged] = ISNULL([e].[Aged], [mp].[Aged])
    FROM [#AlthicnMORD] [m]
        LEFT JOIN [#tmp_CTE_mmr] [e]
            ON [m].[HICN] = [e].[HICN]
               AND [m].[PayMonthYear] = [e].[PaymentYear]
               AND [m].[Month] = [e].[PaymentMonth]
        LEFT JOIN [#tmp_MaxPlanID] [mp]
            ON [m].[HICN] = [mp].[HICN]
               AND [m].[PayMonthYear] = [mp].[Year]
               AND [m].[PayMonthStart] >= [mp].[PaymStart]
               AND [m].[PayMonthYear] = [mp].[Year]
        LEFT JOIN [#tmp_MaxPlanID] [mpi]
            ON [m].[HICN] = [mpi].[HICN]
               AND [m].[PayMonthYear] = [mpi].[Year]
) [t1]
OPTION (RECOMPILE);

SET @RowCount = @@ROWCOUNT;



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

UPDATE a
SET PartDRAFT = r.PartDRAFTProjected,
    PartDRAFTMMR = r.PartDRAFTMMR
FROM [etl].[SummaryPartDRskAdjMORD] a
    JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
    JOIN #RAFTUpdate r
        ON a.HICN = r.HICN
           AND a.PaymentYear = r.PaymentYear
           AND a.PlanIdentifier = r.PlanId
WHERE (
          a.PartDRAFT IS NULL
          OR a.PartDRAFTMMR IS NULL
      );

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

/*Begin -  Update RxHCC Label value*/

UPDATE [m]
SET [m].[RxHCCLabel] = [rm].[Factor_Description]
FROM [etl].[SummaryPartDRskAdjMORD] [m]
    JOIN [#Refresh_PY] [PY] -- Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rm]
        ON [m].[PaymentYear] = [rm].[Payment_Year]
           AND [m].[PartDRAFT] = [rm].[Factor_Type]
           AND [m].[RxHCCLabel] = [rm].[Factor_Description]
           AND [rm].[Part_C_D_Flag] = 'D'
           AND [rm].[Demo_Risk_Type] = 'RISK'
           AND [rm].[OREC] = 9999
           AND [rm].[Aged] = [m].[Aged]
           AND [m].[PartDRAFT] IN ( 'D1', 'D2', 'D3' )
           AND [m].[RxHCCLabel] NOT LIKE '% %'
           AND [m].[RxHCCLabel] LIKE 'D-%';

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

UPDATE [m]
SET [m].[RxHCCLabel] = [rm].[Factor_Description]
FROM [etl].[SummaryPartDRskAdjMORD] [m]
    JOIN [#Refresh_PY] [PY] -- Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [rm]
        ON [m].[PaymentYear] = [rm].[Payment_Year]
           AND [m].[PartDRAFT] = [rm].[Factor_Type]
           AND [m].[RxHCCLabel] = [rm].[Factor_Description]
           AND [rm].[Part_C_D_Flag] = 'D'
           AND [rm].[Demo_Risk_Type] = 'RISK'
           AND [rm].[OREC] = [m].[ORECCalc]
           AND [rm].[Aged] = [m].[Aged]
           AND [m].[PartDRAFT] IN ( 'D1', 'D2', 'D3' )
           AND [m].[RxHCCLabel] NOT LIKE '% %'
           AND [m].[RxHCCLabel] NOT LIKE 'D-%';
/* End -  Update RxHCC Label value */
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
/* Begin - Update Factor Value */
UPDATE [m]
SET [m].[Factor] = 0.00
FROM [etl].[SummaryPartDRskAdjMORD] [m]
    JOIN [#Refresh_PY] [PY] -- Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
WHERE [m].[PartDRAFT] = 'HP';

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

UPDATE [m]
SET [m].[Factor] = [mdl].[Factor]
FROM [etl].[SummaryPartDRskAdjMORD] [m]
    JOIN [#Refresh_PY] [PY] -- Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [mdl]
        ON [m].[PaymentYear] = [mdl].[Payment_Year]
           AND [m].[PartDRAFT] = [mdl].[Factor_Type]
           AND [m].[RxHCCNumber] = CAST(LTRIM(REVERSE(LEFT(REVERSE([mdl].[Factor_Description]), PATINDEX(
                                                                                                            '%[A-Z]%',
                                                                                                            REVERSE([mdl].[Factor_Description])
                                                                                                        ) - 1)
                                                     )
                                             ) AS INT)
           AND LEFT([m].[RxHCCLabel], 3) = LEFT([mdl].[Factor_Description], 3)
           AND [mdl].[Aged] = [m].[Aged] -- US60182 
WHERE [m].[ORECCalc] = 9999
      AND PATINDEX('D-%', [m].[RxHCCLabel]) > 0
      AND [mdl].[Part_C_D_Flag] = 'D'
      AND [mdl].[Demo_Risk_Type] = 'Risk';


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

UPDATE [m]
SET [m].[Factor] = [mdl].[Factor]
FROM [etl].[SummaryPartDRskAdjMORD] [m]
    JOIN [#Refresh_PY] [PY] -- Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] [mdl]
        ON [m].[PaymentYear] = [mdl].[Payment_Year]
           AND [m].[PartDRAFT] = [mdl].[Factor_Type]
           AND [m].[RxHCCNumber] = CAST(LTRIM(REVERSE(LEFT(REVERSE([mdl].[Factor_Description]), PATINDEX(
                                                                                                            '%[A-Z]%',
                                                                                                            REVERSE([mdl].[Factor_Description])
                                                                                                        ) - 1)
                                                     )
                                             ) AS INT)
           AND LEFT([m].[RxHCCLabel], 3) = LEFT([mdl].[Factor_Description], 3)
           AND [m].[ORECCalc] = [mdl].[OREC]
           AND [mdl].[Aged] = [m].[Aged] -- US60182 
WHERE [mdl].[Part_C_D_Flag] = 'D'
      AND [mdl].[Demo_Risk_Type] = 'Risk';



/* End - Update Factor Value */

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

-- Update the Null Model Year to 2014 
--This update is a short-term fix specifically for 2016 payment year. This issue of NULL Model Year results will need to be researched.

/* Update Model Year  */

UPDATE [m]
SET [m].[ModelYear] = 2014
FROM [etl].[SummaryPartDRskAdjMORD] [m]
    JOIN [#Refresh_PY] [PY] -- Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
WHERE [m].[PaymentYear] = 2016
      AND [m].[ModelYear] IS NULL
      AND [m].PartDRAFT IN ( 'D1', 'D2', 'D3' );

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



IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '027',
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
                SELECT [Payment_Year] FROM [#Refresh_PY] WHERE [Id] = @I
            );

    PRINT @PaymentYear;

    BEGIN TRY

        BEGIN TRANSACTION SwitchPartitions;

        TRUNCATE TABLE [out].SummaryPartDRskAdjMORD;

        -- Switch Partition for History SummaryPartDRskAdjMORD 

        ALTER TABLE [hst].SummaryPartDRskAdjMORD SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].SummaryPartDRskAdjMORD PARTITION $Partition.[pfn_SummPY](@PaymentYear);

        -- Switch Partition for REV SummaryPartDRskAdjMORD 
        ALTER TABLE [rev].SummaryPartDRskAdjMORD SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [hst].SummaryPartDRskAdjMORD PARTITION $Partition.[pfn_SummPY](@PaymentYear);

        -- Switch Partition for ETL SummaryPartDRskAdjMORD	
        ALTER TABLE [etl].SummaryPartDRskAdjMORD SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [rev].SummaryPartDRskAdjMORD PARTITION $Partition.[pfn_SummPY](@PaymentYear);

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
    EXEC [dbo].[PerfLogMonitor] '031',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;