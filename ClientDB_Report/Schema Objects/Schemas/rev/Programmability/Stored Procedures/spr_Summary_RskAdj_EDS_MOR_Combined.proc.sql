/*****************************************************************************************************
Name		: rev.spr_Summary_RskAdj_EDS_MOR_Combined
Author      : Rakshit Lall
Date		: 2018-08-22
TFS			: 72714
SP Test		: EXEC rev.spr_Summary_RskAdj_EDS_MOR_Combined NULL, NULL, 0, 0
Version		: 1.0
Description	:

Version History :																					

Author			Date		Version#    TFS Ticket#		Description								
Rakshit Lall	9/24/2018	1.1			72714			Modified the code to be in sync with DBA standards
Rakshit Lall	10/31/2018	1.2			73943			Modified the SP to load 2 extra columns that were missed out
D.Waddell		10/29/2019	1.3			RE-6981			Set Transaction Isolation Level Read to Uncommitted
*******************************************************************************************************/
CREATE PROC rev.spr_Summary_RskAdj_EDS_MOR_Combined
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS
DECLARE @UserID VARCHAR(128) = SYSTEM_USER;

SET NOCOUNT ON;
SET STATISTICS IO OFF;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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

----SELECT *
----FROM [#Refresh_PY]

IF OBJECT_ID('[TEMPDB]..[#EDS_MOR_DeciderPY]', 'U') IS NOT NULL
    DROP TABLE [#EDS_MOR_DeciderPY];

CREATE TABLE [#EDS_MOR_DeciderPY]
(
    [PaymentYear] INT,
    [Model_Year] INT,
    [maxPayMStart] VARCHAR(5),
    [Paymonth_MOR] VARCHAR(6)
);
INSERT INTO [#EDS_MOR_DeciderPY]
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
      AND [MOR].SubmissionModel = 'EDS'
GROUP BY [MOR].[PaymentYear],
         [MOR].[Model_Year],
         RIGHT([DCP].[PayMonth], 2)
HAVING MAX(MONTH([MOR].[PaymStart])) >= RIGHT([DCP].[PayMonth], 2);

IF OBJECT_ID('[TEMPDB]..[#MaxMOR]', 'U') IS NOT NULL
    DROP TABLE [#MaxMOR];

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

IF OBJECT_ID('[TEMPDB]..[#EDSInitial]', 'U') IS NOT NULL
    DROP TABLE [#EDSInitial];

CREATE TABLE [#EDSInitial]
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

IF OBJECT_ID('[TEMPDB]..[#EDS]', 'U') IS NOT NULL
    DROP TABLE [#EDS];

CREATE TABLE [#EDS]
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

IF OBJECT_ID('[TEMPDB]..[#EDSMORUnion]', 'U') IS NOT NULL
    DROP TABLE [#EDSMORUnion];

CREATE TABLE [#EDSMORUnion]
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

IF OBJECT_ID('[TEMPDB]..[#EDSMid]', 'U') IS NOT NULL
    DROP TABLE [#EDSMid];

CREATE TABLE [#EDSMid]
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

IF OBJECT_ID('[TEMPDB]..[#EDSFinal]', 'U') IS NOT NULL
    DROP TABLE [#EDSFinal];

CREATE TABLE [#EDSFinal]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSInitial]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSInitial];

CREATE TABLE [#TestMOREDSInitial]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSMid]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSMid];

CREATE TABLE [#TestMOREDSMid]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSFinal]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSFinal];

CREATE TABLE [#TestMOREDSFinal]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSFinalActual]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSFinalActual];

CREATE TABLE [#TestMOREDSFinalActual]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSInitailUpdateEDS]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSInitailUpdateEDS];

CREATE TABLE [#TestMOREDSInitailUpdateEDS]
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
    [HCC_Number] INT
);

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSMidUpdateEDS]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSMidUpdateEDS];

CREATE TABLE [#TestMOREDSMidUpdateEDS]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSFinalUpdateEDS]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSFinalUpdateEDS];

CREATE TABLE [#TestMOREDSFinalUpdateEDS]
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

IF OBJECT_ID('[TEMPDB]..[#TestMOREDSLowerHCC]', 'U') IS NOT NULL
    DROP TABLE [#TestMOREDSLowerHCC];

CREATE TABLE [#TestMOREDSLowerHCC]
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
    INNER JOIN [#EDS_MOR_DeciderPY] [dpy]
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
            INNER JOIN [#EDS_MOR_DeciderPY] [dpy1]
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
WHERE m.SubmissionModel = 'EDS';

INSERT INTO [#EDSInitial]
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
       [a].[Model_Year],
       [a].[RAFT],
       [a].[Factor_category],
       [a].[Factor_Desc],
       [a].[Factor],
       [a].[Factor_Desc_ORIG],
       [a].[HCC_Number]
FROM [rev].[tbl_Summary_RskAdj_EDS] [a]
    INNER JOIN [#EDS_MOR_DeciderPY] [dpy]
        ON [a].[PaymentYear] = [dpy].[PaymentYear]
           AND [a].[Model_Year] = [dpy].[Model_Year]
WHERE (
          [a].[Factor_Desc] NOT LIKE ('HIER%')
          AND [a].[Factor_Desc] NOT LIKE ('DEL%')
      ) --HasanMF 8/24/2017 (RE 1052 - For two (NOT LIKE) conditions, the operator needs to be (AND), instead of (OR)
      AND [a].[IMFFlag] = 1
OPTION (RECOMPILE);

INSERT INTO #EDSMid
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    factor,
    HCC_ORIG,
    HCC_Number
)
SELECT DISTINCT
       a.PlanID,
       a.HICN,
       a.PaymentYear,
       a.Model_Year,
       a.RAFT,
       a.Factor_category,
       a.Factor_Desc,
       a.Factor,
       a.Factor_Desc_ORIG,
       a.HCC_Number
FROM rev.tbl_Summary_RskAdj_EDS a
    INNER JOIN #EDS_MOR_DeciderPY dpy
        ON a.PaymentYear = dpy.PaymentYear
           AND a.Model_Year = dpy.Model_Year
WHERE (
          a.Factor_Desc NOT LIKE ('HIER%')
          AND a.Factor_Desc NOT LIKE ('DEL%')
      )
      AND a.IMFFlag = 2;

INSERT INTO #EDSFinal
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    factor,
    HCC_ORIG,
    HCC_Number
)
SELECT DISTINCT
       a.PlanID,
       a.HICN,
       a.PaymentYear,
       a.Model_Year,
       a.RAFT,
       a.Factor_category,
       a.Factor_Desc,
       a.Factor,
       a.Factor_Desc_ORIG,
       a.HCC_Number
FROM rev.tbl_Summary_RskAdj_EDS a
    INNER JOIN #EDS_MOR_DeciderPY dpy
        ON a.PaymentYear = dpy.PaymentYear
           AND a.Model_Year = dpy.Model_Year
WHERE (
          a.Factor_Desc NOT LIKE ('HIER%')
          AND a.Factor_Desc NOT LIKE ('DEL%')
      )
      AND a.IMFFlag = 3;

INSERT INTO #FinalMidMOR
(
    PlanID,
    HICN,
    PY,
    MY,
    Paymstart,
    RAFT,
    Factor_Category,
    HCC,
    factor,
    HCC_ORIG,
    HCC_Number
)
SELECT PlanID,
       HICN,
       PY,
       MY,
       Paymstart,
       RAFT,
       Factor_Category,
       HCC,
       factor,
       HCC_ORIG,
       HCC_Number
FROM #MaxMOR
EXCEPT
SELECT t1.PlanID,
       t1.HICN,
       t1.PY,
       t1.MY,
       t1.Paymstart,
       t1.RAFT,
       t1.Factor_Category,
       t1.HCC,
       t1.factor,
       t1.HCC_ORIG,
       t1.HCC_Number
FROM #MaxMOR t1
    INNER JOIN #EDSMid t
        ON t.HICN = t1.HICN
           AND t.PY = t1.PY
           AND t.MY = t1.MY
           AND t.HCC_Number = t1.HCC_Number;

INSERT INTO #FinalInitialMidMOR
(
    PlanID,
    HICN,
    PY,
    MY,
    Paymstart,
    RAFT,
    Factor_Category,
    HCC,
    factor,
    HCC_ORIG,
    HCC_Number
)
SELECT PlanID,
       HICN,
       PY,
       MY,
       Paymstart,
       RAFT,
       Factor_Category,
       HCC,
       factor,
       HCC_ORIG,
       HCC_Number
FROM #FinalMidMOR
EXCEPT
SELECT t1.PlanID,
       t1.HICN,
       t1.PY,
       t1.MY,
       t1.Paymstart,
       t1.RAFT,
       t1.Factor_Category,
       t1.HCC,
       t1.factor,
       t1.HCC_ORIG,
       t1.HCC_Number
FROM #FinalMidMOR t1
    INNER JOIN #EDSInitial t
        ON t.HICN = t1.HICN
           AND t.PY = t1.PY
           AND t.MY = t1.MY
           AND t.HCC_Number = t1.HCC_Number;

INSERT INTO #FinalInitialMOR
(
    PlanID,
    HICN,
    PY,
    MY,
    Paymstart,
    RAFT,
    Factor_Category,
    HCC,
    factor,
    HCC_ORIG,
    HCC_Number
)
SELECT PlanID,
       HICN,
       PY,
       MY,
       Paymstart,
       RAFT,
       Factor_Category,
       HCC,
       factor,
       HCC_ORIG,
       HCC_Number
FROM #FinalInitialMidMOR
EXCEPT
SELECT t1.PlanID,
       t1.HICN,
       t1.PY,
       t1.MY,
       t1.Paymstart,
       t1.RAFT,
       t1.Factor_Category,
       t1.HCC,
       t1.factor,
       t1.HCC_ORIG,
       t1.HCC_Number
FROM #FinalInitialMidMOR t1
    INNER JOIN #EDSInitial t
        ON t.HICN = t1.HICN
           AND t.PY = t1.PY
           AND t.MY = t1.MY
           AND t.HCC_Number = t1.HCC_Number;

-- finding hierarchy between EDS and MOR ticket # 25703
INSERT INTO [#TestMOREDSInitial]
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
FROM [#EDSInitial]
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

INSERT INTO [#TestMOREDSMid]
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
FROM [#EDSMid]
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

INSERT INTO [#TestMOREDSFinal]
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
FROM [#EDSFinal]
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

-- HCC Hierarchy Updates
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMOREDSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMOREDSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMOREDSInitial] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMOREDSInitial] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMOREDSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMOREDSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMOREDSMid] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMOREDSMid] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

--and kep.Factor_Category = drp.Factor_Category
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMOREDSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMOREDSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMOREDSFinal] [drp]
    INNER JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
        ON [Hier].[HCC_DROP_NUMBER] = [drp].[HCC_Number]
           AND [Hier].[Payment_Year] = [drp].[MY]
           AND [Hier].[RA_FACTOR_TYPE] = [drp].[RAFT]
           AND [Hier].[Part_C_D_Flag] = 'C'
           AND LEFT([Hier].[HCC_DROP], 3) = 'HCC'
           AND LEFT([drp].[HCC_ORIG], 3) = 'HCC'
    INNER JOIN [#TestMOREDSFinal] [kep]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [Hier].[HCC_KEEP_NUMBER]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([kep].[HCC_ORIG], 3) = 'HCC';

-- Interaction updates
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMOREDSInitial] [drp]
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
    INNER JOIN [#TestMOREDSInitial] [kep]
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

UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMOREDSInitial] [drp]
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
    INNER JOIN [#TestMOREDSInitial] [kep]
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

UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMOREDSMid] [drp]
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
    INNER JOIN [#TestMOREDSMid] [kep]
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

--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMOREDSMid] [drp]
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
    INNER JOIN [#TestMOREDSMid] [kep]
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

--and kep.Factor_Category = drp.Factor_Category
UPDATE [drp]
SET [drp].[RelationFlag] = 'Drop'
FROM [#TestMOREDSFinal] [drp]
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
    INNER JOIN [#TestMOREDSFinal] [kep]
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

--and kep.Factor_Category = drp.Factor_Category
UPDATE [kep]
SET [kep].[RelationFlag] = 'Keep'
FROM [#TestMOREDSFinal] [drp]
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
    INNER JOIN [#TestMOREDSFinal] [kep]
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

UPDATE [kep]
SET [kep].[RelationFlag] = 'Same'
FROM [#TestMOREDSFinal] [kep]
    INNER JOIN [#MaxMOR] [drp]
        ON [kep].[HICN] = [drp].[HICN]
           AND [kep].[RAFT] = [drp].[RAFT]
           AND [kep].[HCC_Number] = [drp].[HCC_Number]
           AND [kep].[PY] = [drp].[PY]
           AND [kep].[MY] = [drp].[MY]
           AND LEFT([drp].[HCC_ORIG], 3) = LEFT([kep].[HCC_ORIG], 3)
WHERE [kep].[Factor_Category] = 'EDS'
      OR [kep].[Factor_Category] = 'EDS-Disability'
      OR [kep].[Factor_Category] = 'EDS-Interaction';

--OR kep.Factor_Category = 'MOR-HCC'

UPDATE drp
SET drp.RelationFlag = 'Same'
FROM
(
    SELECT PlanID,
           HICN,
           PY,
           MY,
           RAFT,
           Factor_Category,
           HCC,
           factor,
           HCC_ORIG,
           HCC_Number,
           RelationFlag
    FROM [#TestMOREDSFinal] [kep]
    WHERE [kep].[RelationFlag] = 'Same'
) a
    INNER JOIN
    (
        SELECT PlanID,
               HICN,
               PY,
               MY,
               RAFT,
               Factor_Category,
               HCC,
               factor,
               HCC_ORIG,
               HCC_Number,
               RelationFlag
        FROM #TestMOREDSFinal
    ) drp
        ON a.HICN = drp.HICN
           AND a.RAFT = drp.RAFT
           AND a.HCC_Number = drp.HCC_Number
           AND a.PY = drp.PY
           AND a.MY = drp.MY
           AND LEFT(a.HCC_ORIG, 3) = LEFT(drp.HCC_ORIG, 3)
WHERE drp.Factor_Category = 'MOR-HCC';

INSERT INTO #TestMOREDSLowerHCC
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    HCC_ORIG,
    Factor,
    HCC_Number,
    RelationFlag
)
SELECT DISTINCT
       t.PlanID,
       t.HICN,
       t.PY,
       t.MY,
       t.RAFT,
       t.Factor_Category,
       t.HCC,
       t.HCC_ORIG,
       t.factor,
       t.HCC_Number,
       t.RelationFlag
FROM #TestMOREDSFinal t
    INNER JOIN
    (
        SELECT DISTINCT
               PlanID,
               HICN,
               PY,
               MY,
               RAFT,
               HCC_Number
        FROM #EDSInitial
        UNION
        SELECT DISTINCT
               PlanID,
               HICN,
               PY,
               MY,
               RAFT,
               HCC_Number
        FROM #EDSMid
    ) a
        ON t.HICN = a.HICN
           AND t.PY = a.PY
           AND t.MY = a.MY
           AND t.HCC_Number = a.HCC_Number
WHERE t.Factor_Category = 'MOR-HCC'
      AND t.RelationFlag = 'Drop';

INSERT INTO #TestMOREDSFinalActual
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    HCC_ORIG,
    factor,
    HCC_Number,
    RelationFlag
)
SELECT DISTINCT
       t.PlanID,
       t.HICN,
       t.PY,
       t.MY,
       t.RAFT,
       t.Factor_Category,
       t.HCC,
       t.HCC_ORIG,
       t.factor,
       t.HCC_Number,
       t.RelationFlag
FROM #TestMOREDSFinal t
EXCEPT
SELECT PlanID,
       HICN,
       PY,
       MY,
       RAFT,
       Factor_Category,
       HCC,
       HCC_ORIG,
       Factor,
       HCC_Number,
       RelationFlag
FROM #TestMOREDSLowerHCC;

UPDATE [#TestMOREDSFinalActual]
SET [RelationFlag] = NULL
FROM [#TestMOREDSFinalActual] [t]
    INNER JOIN [#TestMOREDSLowerHCC] [lh]
        ON [t].[HICN] = [lh].[HICN]
           AND [t].[PY] = [lh].[PY]
           AND [t].[MY] = [lh].[MY]
           AND LEFT([t].[HCC_ORIG], 3) = LEFT([lh].[HCC_ORIG], 3)
WHERE [t].[RelationFlag] = 'Keep';

INSERT INTO #TestMOREDSInitailUpdateEDS
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    HCC_ORIG,
    factor,
    HCC_Number
)
SELECT PlanID,
       HICN,
       PY,
       MY,
       RAFT,
       Factor_Category,
       CASE
           WHEN (
                    Factor_Category = 'EDS'
                    OR Factor_Category = 'EDS-Disability'
                    OR Factor_Category = 'EDS-Interaction'
                )
                AND RelationFlag = 'Drop' THEN
               'M-' + HCC
           WHEN Factor_Category = 'MOR-HCC'
                AND RelationFlag = 'Keep' THEN
               'MOR-' + HCC
           WHEN (
                    Factor_Category = 'EDS'
                    OR Factor_Category = 'EDS-Disability'
                    OR Factor_Category = 'EDS-Interaction'
                )
                AND RelationFlag = 'Keep' THEN
               'M-High-' + HCC
           WHEN Factor_Category = 'MOR-HCC'
                AND RelationFlag = 'Drop' THEN
               'MOR-INCR-' + HCC
           ELSE
               HCC
       END,
       HCC_ORIG,
       factor,
       HCC_Number
FROM #TestMOREDSInitial
WHERE RelationFlag IS NOT NULL;

INSERT INTO #TestMOREDSFinalUpdateEDS
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    HCC_ORIG,
    factor,
    HCC_Number
)
SELECT PlanID,
       HICN,
       PY,
       MY,
       RAFT,
       Factor_Category,
       CASE
           WHEN (
                    Factor_Category = 'EDS'
                    OR Factor_Category = 'EDS-Disability'
                    OR Factor_Category = 'EDS-Interaction'
                )
                AND RelationFlag = 'Keep' THEN
               'M-High-' + HCC
           WHEN (
                    Factor_Category = 'EDS'
                    OR Factor_Category = 'EDS-Disability'
                    OR Factor_Category = 'EDS-Interaction'
                )
                AND
                (
                    RelationFlag = 'Drop'
                    OR RelationFlag = 'Same'
                ) THEN
               'M-' + HCC
           WHEN Factor_Category = 'MOR-HCC'
                AND RelationFlag = 'Drop' THEN
               'MOR-INCR-' + HCC
           WHEN Factor_Category = 'MOR-HCC'
                AND
                (
                    RelationFlag = 'Keep'
                    OR RelationFlag = 'Same'
                ) THEN
               'MOR-' + HCC
           ELSE
               HCC
       END,
       HCC_ORIG,
       factor,
       HCC_Number
FROM #TestMOREDSFinalActual
WHERE RelationFlag IS NOT NULL;

INSERT INTO #TestMOREDSMidUpdateEDS
(
    PlanID,
    HICN,
    PY,
    MY,
    RAFT,
    Factor_Category,
    HCC,
    HCC_ORIG,
    factor,
    HCC_Number
)
SELECT PlanID,
       HICN,
       PY,
       MY,
       RAFT,
       Factor_Category,
       CASE
           WHEN (
                    Factor_Category = 'EDS'
                    OR Factor_Category = 'EDS-Disability'
                    OR Factor_Category = 'EDS-Interaction'
                )
                AND RelationFlag = 'Keep' THEN
               'M-High-' + HCC
           WHEN (
                    Factor_Category = 'EDS'
                    OR Factor_Category = 'EDS-Disability'
                    OR Factor_Category = 'EDS-Interaction'
                )
                AND RelationFlag = 'Drop' THEN
               'M-' + HCC
           WHEN Factor_Category = 'MOR-HCC'
                AND RelationFlag = 'Drop' THEN
               'MOR-INCR-' + HCC
           WHEN Factor_Category = 'MOR-HCC'
                AND
                (
                    RelationFlag = 'Keep'
                    OR RelationFlag IS NULL
                ) THEN
               'MOR-' + HCC
           ELSE
               HCC
       END,
       HCC_ORIG,
       factor,
       HCC_Number
FROM #TestMOREDSMid
WHERE RelationFlag IS NOT NULL;

/*************************************************************************************/
/* Delete records from Summary RskAdj EDS MOR CombinbedRiskFactor Table             */
/* based on Payment Year in [#Refresh_PY]                                             */
/*************************************************************************************/

WHILE (1 = 1)
BEGIN

    DELETE TOP (@DeleteBatch)
    [m1]
    FROM [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined] [m1]
        JOIN [#Refresh_PY] [py] --US53053 8/22/2016 - Deleting table upon RefreshPY  (TFS 55925)
            ON [m1].[PaymentYear] = [py].[Payment_Year];

    IF @@rowcount = 0
        BREAK;
    ELSE
        CONTINUE;
END;

/************************************************************************************/
/* Initial Insert into Summary RskAdj EDS MOR CombinbedRiskFactor Table            */
/* US 53053 (TFS 55925)																*/
/************************************************************************************/
SET @RowCount = 0;

INSERT INTO [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [Model_Year],
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
    [Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
    [Min_ThruDate_MAO004ResponseDiagnosisCodeId],
    [LoadDateTime],
    [Aged],
    [UserID]
)
SELECT [m1].[PlanID],
       [m1].[HICN],
       [m1].[PaymentYear],
       [m1].[PaymStart],
       [m1].[Model_Year],
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
       [m1].[Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
       [m1].[Min_ThruDate_MAO004ResponseDiagnosisCodeId],
       [LoadDateTime] = @LoadDateTime,
       [m1].[Aged],
       @UserID AS UserID
FROM [rev].[tbl_Summary_RskAdj_EDS] [m1]
    JOIN [#Refresh_PY] [py]
        ON [m1].[PaymentYear] = [py].[Payment_Year];

SET @RowCount = @@rowcount;

UPDATE [t]
SET [t].[Factor_Desc] = [t1].[HCC]
FROM [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined] [t]
    --  #tbl_Summary_RskAdj_EDSMORCombined [t]
    INNER JOIN [#TestMOREDSInitailUpdateEDS] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[RAFT] = [t1].[RAFT]
           AND [t].[HCC_Number] = [t1].[HCC_Number]
           AND [t].[Model_Year] = [t1].[MY]
           AND [t].[Factor_category] = [t1].[Factor_Category]
WHERE [t].[IMFFlag] = 1
      AND [t].[Factor_Desc] NOT LIKE ('HIER%');

UPDATE [t]
SET [t].[Factor_Desc] = [t1].[HCC]
FROM [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined] [t]
    --   #tbl_Summary_RskAdj_EDSMORCombined [t]
    INNER JOIN [#TestMOREDSMidUpdateEDS] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[RAFT] = [t1].[RAFT]
           AND [t].[HCC_Number] = [t1].[HCC_Number]
           AND [t].[Model_Year] = [t1].[MY]
           AND [t].[Factor_category] = [t1].[Factor_Category]
WHERE [t].[IMFFlag] = 2
      AND [t].[Factor_Desc] NOT LIKE ('HIER%');

UPDATE [t]
SET [t].[Factor_Desc] = [t1].[HCC]
FROM [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined] [t]
    -- #tbl_Summary_RskAdj_EDSMORCombined [t]
    INNER JOIN [#TestMOREDSFinalUpdateEDS] [t1]
        ON [t].[HICN] = [t1].[HICN]
           AND [t].[PaymentYear] = [t1].[PY]
           AND [t].[RAFT] = [t1].[RAFT]
           AND [t].[HCC_Number] = [t1].[HCC_Number]
           AND [t].[Model_Year] = [t1].[MY]
           AND [t].[Factor_category] = [t1].[Factor_Category]
WHERE [t].[IMFFlag] = 3
      AND [t].[Factor_Desc] NOT LIKE ('HIER%');

/* 41262 req 6 The LoadDatetime added to the insert for the MOR records. */

INSERT INTO [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [Model_Year],
    [RAFT],
    [Factor_category],
    [Factor_Desc],
    [Factor_Desc_ORIG],
    [Factor],
    [HCC_Number],
    [LoadDateTime],
    [UserID]
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
       [LoadDateTime] = @LoadDateTime,
       @UserID AS UserID
FROM [#TestMOREDSMidUpdateEDS] [t]
    INNER JOIN [#EDSMid] [r]
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
       @LoadDateTime,
       @UserID AS UserID
FROM [#TestMOREDSFinalUpdateEDS] [t]
    INNER JOIN [#EDSFinal] [r]
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
       @LoadDateTime,
       @UserID AS UserID
FROM [#TestMOREDSInitailUpdateEDS] [t]
    INNER JOIN [#EDSInitial] [r]
        ON (
               [t].[PlanID] = [r].[PlanID]
               AND [t].[HICN] = [r].[HICN]
               AND [t].[PY] = [r].[PY]
               AND [t].[MY] = [r].[MY]
               AND [t].[RAFT] = [r].[RAFT]
           )
WHERE [t].[Factor_Category] = 'MOR-HCC';

SET @RowCount = ISNULL(@RowCount, 0) + @@rowcount;

UPDATE [m1]
SET [m1].[LastAssignedHICN] = ISNULL(   [b].[LastAssignedHICN],
                                        CASE
                                            WHEN ssnri.fnValidateMBI([m1].[HICN]) = 1 THEN
                                                [b].[HICN]
                                        END
                                    )
FROM [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined] [m1]
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