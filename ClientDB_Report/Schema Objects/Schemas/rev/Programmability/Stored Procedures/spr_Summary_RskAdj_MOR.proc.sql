CREATE PROC [rev].[spr_Summary_RskAdj_MOR]
(
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS
/****************************************************************************************************/
/* Name			:	rev.spr_Summary_RskAdj_MOR														*/
/* Type 		:	Stored Procedure																*/
/* Author       :	Mitch Casto																		*/
/* Date			:	2016-03-21																		*/
/* Version		:																					*/
/* Description	: Updates dbo.tbl_Summary_RskAdj_MOR table with raw MOR data						*/
/*					Note: This stp is an adaptation from Summary 1.0 and will need further work to	*/
/*					optimize the sql.																*/
/*																									*/
/* Version History :																				*/
/* =================================================================================================*/
/* Author			Date		Version#    TFS Ticket#		Description								*/
/* -----------------	----------  --------    -----------		------------						*/
/* Mitch Casto		2016-05-18	1.0			53367			Initial									*/
/* David Waddell		2016-07-22	1.1			55593           Section #19 chge logic to no longer	*/
/*															use CTE for MMR replace w/ temp table	*/
/*																									*/
/*																									*/
/* David Waddell     2016-09-07 1.2			55925			hard coding of refresh Payment Yr       */
/*                                                           removed. Update script that updates    */
/*                                                           the NULL Model Yr to "2014". Target    */
/*                                                           table Del./Insert based on Refresh PY  */
/*											                Modified Model Year Case statement for 	*/
/*															RecordType "A" and "C" logic. Hard 		*/
/*                                                           Coding of Refresh Pymnt Year removed.  */
/*	                                                        end of script that updateds the NUll    */
/*                                                           Year to "2014"   US53053				*/
/*      																							*/
/* David Waddell		2016-12-22  1.3         US60182         'E' to 'C' Conversion. include 'CF',*/
/*                                                           'CP','CN' to any ref. of Factory Type  */
/*                                                           equal 'C'                              */
/* Note: Section 019 will need to be rewritten to remove "triangle" joins and need further			*/
/*		optimization																				*/
/*                                                                                                  */
/* David Waddell     2017-03-06              62758           Synchronizing Summary 2.0 to current   */
/*                                                           Summary - MOR spr                      */
/*														    Removed redundant where clause 006      */
/*                                                           Anchor PY to PY to 019                 */
/*                                                           Add join to update only the year to    */
/*                                                           run 021 to 026                         */
/* Mitch Casto		2017-03-27	1.4			63302/US63790	Removed @ManualRun process and replaced */
/*															with parameterized delete batch			*/
/*															(Section 017 to 020)					*/
/*	David Waddell   2017-04-26	1.5         64138/US64855   correction for closed PaymentYears		*/
/*											                Sections 006,010,019					*/
/*	Madhuri Suri    2017-06-26  1.6         65493           For Corrections to OREC Restated for ER2*/
/*	Madhuri Suri    2017-08-07  1.7           65862           ER 1 to ER2 Logic changes				*/
/*																									*/
/*	David Waddell   2017-08-11  1.8         TFS65752/US67065 Modified Sections 9.1,9.2,10.0 -10.2,19*/
/*															to improve proc performance level.     	*/
/*															also modified def. for [Model Year] in	*/
/*															section 19								*/
/*	David Waddell   2017-11-08  1.9       TFS67917/RE1207	Adding PaymentYear field to             */
/*                                                          #tmp_MaxPaymStart working table			*/
/*										                    (Sect. 9.1, 9.2)    					*/
/*	Rakshit Lall	2018-05-29	2.0			71364			Enhancing JOIN with lk_Risk_Score_Factors_PartC + Replaced ModelSplit join with the "lk_Risk_Score_Factors_PartC" */
/*	Rakshit Lall	2018-07-23	2.1			72337			Added mapping to load "SubmissionModel" and "RecordType" columns */
/*  Madhuri Suri    2019-02-20  3.0         75088           Comment SubmissionModel filter to flow all records*/
/*  Madhuri Suri    2019-06-24  4.0         76224           Summary MOR Performance enhancements     */
/*  D.Waddell		10/29/2019	4.1			RE-6981		    Set Transaction Isolation Level Read to  */
/*                                                          Uncommitted                              */
/*  Anand			11/11/2019  4.2		    RE-7078/77251 	Used Partitioning tables for Summary RskAdj Mor */
/*  Anand			07/07/2021  4.3		    RRI-660			Point to New MOR Source Tables*/
/*  Anand			11/08/2021	4.4			RRI-1750		Format HCC Label */
/*****************************************************************************************************/


--declare  @LoadDateTime DATETIME = NULL ,
--        @DeleteBatch INT = NULL ,
--        @RowCount INT  ,
--        @Debug BIT = 1

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
SET @DeleteBatch = ISNULL(@DeleteBatch, 125000);

IF (OBJECT_ID('tempdb.dbo.[#AlthicnMOR]') IS NOT NULL)
BEGIN
    DROP TABLE [#AlthicnMOR];
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

CREATE TABLE [#AlthicnMOR]
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
    EXEC [dbo].[PerfLogMonitor] '001.1',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

DECLARE @ClientDb VARCHAR(50) =
        (
            SELECT TOP 1
                   C.Client_DB
            FROM [$(HRPReporting)].dbo.tbl_Clients C
            WHERE C.Report_DB = DB_NAME()
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

CREATE NONCLUSTERED INDEX IX_Refresh_PY
ON [#Refresh_PY] ([Payment_Year]);

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

INSERT INTO [#AlthicnMOR] (   [HICN] ,
                                  [PayMonth] ,
                                  [Month] ,
                                  [NAME] ,
                                  [RecordType] ,
                                  [PlanIdentifier] ,
                                  [COMM],
                                  [PayMonthStart],
                                  [PayMonthYear]
                              )
                SELECT [HICN] = ISNULL([althcn].[FINALHICN], [a].[HICN]) ,
                       [PayMonth] = [a].[PayMonth] ,
                       [Month] = RIGHT([a].[PayMonth], 2) ,
                       [Name] = [a].[HCC] ,
                       [RecordType] = [a].[RecordType] ,
                       [PlanIdentifier] = [rp].[PlanIdentifier] ,
                       [Comm] = [a].[Factor],
                       [PayMonthStart] = RIGHT([a].[PayMonth], 2) + '/01/'
                                         + LEFT([a].[PayMonth], 4) ,
                       [PayMonthYear] = LEFT([a].[PayMonth], 4)
                FROM   [rev].[SummaryRskAdjMORSourcePartC] [a] WITH ( NOLOCK )
					   
					   LEFT JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp on rp.PlanID = a.PlanID 	

                       LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn] WITH ( NOLOCK ) ON [rp].[PlanIdentifier] = [althcn].[PlanID]
                                                                                                AND [a].[HICN] = [althcn].[HICN]
                       --US 53053 adding PaymentYear for process MOR year being worked.  TFS53053


                       JOIN [#Refresh_PY] [py] ON ( LEFT([a].[PayMonth], 4) = [py].[Payment_Year] )
                WHERE  [a].[HICN] IS NOT NULL
                        AND RIGHT([a].[PayMonth], 2) <= 12;

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
ON [#AlthicnMOR] (
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

IF OBJECT_ID('TEMPDB.DBO.#lk_Risk_Models', 'U') IS NOT NULL
    DROP TABLE #lk_Risk_Models;

CREATE TABLE #lk_Risk_Models
(
    [lk_Risk_ModelsID] [INT] NOT NULL,
    [Payment_Year] [INT] NULL,
    [Factor_Type] [VARCHAR](10) NULL,
    [Part_C_D_Flag] [VARCHAR](1) NULL,
    [OREC] [INT] NULL,
    [LI] [INT] NULL,
    [Medicaid_Flag] [INT] NULL,
    [Demo_Risk_Type] [VARCHAR](10) NULL,
    [Factor_Description] [VARCHAR](50) NULL,
    [Gender] [INT] NULL,
    [Factor] [DECIMAL](20, 4) NULL,
    [Aged] [INT] NULL
);

INSERT INTO #lk_Risk_Models
SELECT [lk_Risk_ModelsID],
       [Payment_Year],
       [Factor_Type],
       [Part_C_D_Flag],
       [OREC],
       [LI],
       [Medicaid_Flag],
       [Demo_Risk_Type],
       [Factor_Description],
       [Gender],
       [Factor],
       ISNULL(Aged, '9999') Aged
FROM [$(HRPReporting)].dbo.lk_Risk_Models e
WHERE e.Payment_Year IN
      (
          SELECT DISTINCT
                 ModelYear
          FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC e
              JOIN #Refresh_PY py
                  ON py.Payment_Year = e.PaymentYear
      --AND e.[SubmissionModel] = 'EDS' -- HasanMF Change 11/4/2018 - Removing filter on SubmissionModel
      ) --65862
      AND e.Part_C_D_Flag = 'C';

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


CREATE NONCLUSTERED INDEX IX_lk_Risk_Models
ON #lk_Risk_Models (
                       Factor_Description,
                       Factor_Type
                   );

/*  Begin AltHICNMOR12Mo Temp Table */


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



IF OBJECT_ID('tempdb..#tmp_CTE_mmr') IS NOT NULL
BEGIN
    DROP TABLE [#tmp_CTE_mmr];
END;


CREATE TABLE [#tmp_CTE_mmr]
(
    [PlanId] INT,
    [HICN] VARCHAR(12),
    [RAFT] VARCHAR(2),
    [PaymentYear] INT,
    [PaymentMonth] INT,
    [PaymStart] DATETIME,
    [RAFT_ORIG] VARCHAR(2),
    [OREC] VARCHAR(5),
    [OREC_CALC] VARCHAR(5),
    [HOSP] VARCHAR(1),
    [AgeGrp] VARCHAR(4),
    [PriorPaymentYear] INT,
    [Aged] INT,
    [MaxPaymStart] DATETIME,
    [MonthRow] INT
);


IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '010.2',
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
    [RAFT],
    [PaymentYear],
    [PaymentMonth],
    [PaymStart],
    [RAFT_ORIG],
    [OREC],
    [OREC_CALC],
    [HOSP],
    [AgeGrp],
    [PriorPaymentYear],
    [Aged],
    [MonthRow]
)
SELECT DISTINCT
       [PlanId] = [mmr].[PlanID],
       [HICN] = [mmr].[HICN],
       [RAFT] = [mmr].[PartCRAFTProjected],
       [PaymentYear] = [mmr].[PaymentYear],
       [PaymentMonth] = MONTH([mmr].[PaymStart]),
       [PaymStart] = [mmr].[PaymStart],
       [RAFT_ORIG] = [mmr].[PartCRAFTMMR],
       [OREC] = [mmr].[ORECMMR],
       [OREC_CALC] = [mmr].[ORECRestated],
       [HOSP] = [mmr].[HOSP],
       [AgeGrp] = [mmr].[RskAdjAgeGrp],
       [PriorPaymentYear] = [mmr].[PriorPaymentYear],
       [Aged] = [mmr].[Aged],
       RANK() OVER (PARTITION BY mmr.HICN,
                                 PlanId,
                                 PartCRAFTProjected
                    ORDER BY mmr.PaymStart DESC
                   ) AS MonthRow
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

UPDATE a
SET a.MaxPaymStart = b.PaymStart
FROM [#tmp_CTE_mmr] a
    LEFT JOIN [#tmp_CTE_mmr] b
        ON a.HICN = b.HICN
           AND a.PlanId = b.PlanId
           AND a.RAFT = b.RAFT
           AND b.MonthRow = 1;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '011.5',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;

UPDATE [h]
SET [h].[HOSP] = 'Y'
FROM [#tmp_CTE_mmr] [h]
    JOIN [#tmp_CTE_mmr] [m]
        ON [h].[PlanId] = [m].[PlanId]
           AND [h].[HICN] = [m].[HICN]
           AND [h].[PaymStart] = [m].[PaymStart]
           AND [h].[OREC_CALC] = [m].OREC_CALC
           AND [h].[Aged] = [m].[Aged]
           AND m.MonthRow = 1
WHERE [m].[HOSP] = 'Y';

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

UPDATE [h]
SET [h].[RAFT] = [m].RAFT
FROM [#tmp_CTE_mmr] [h] --    JOIN [#tbl_EstRecv_MMR] [m]
    JOIN [#tmp_CTE_mmr] [m]
        ON [h].[PlanId] = [m].[PlanId]
           AND [h].[HICN] = [m].[HICN]
           AND [h].[PaymStart] = [m].[PaymStart]
           AND [h].[OREC_CALC] = [m].OREC_CALC
           AND m.MonthRow = 1;

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

CREATE NONCLUSTERED INDEX [idx_#MaxPlanID_HICN]
ON [#tmp_CTE_mmr] (
                      [HICN],
                      [PaymStart],
                      [RAFT],
                      [HOSP],
                      [PaymentYear],
                      [PaymentMonth] ---DBA Suggested improvements
                  )
INCLUDE (
            [PlanId],
            [OREC_CALC]
        )
--WHERE [HICN] IS NULL
--      AND [HOSP] = 'Y'
 ;


/*B Truncate Or Delete rows in rev.tbl_Summary_RskAdj_MOR */

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


IF OBJECT_ID('tempdb..#RAFTUpdate') IS NOT NULL
BEGIN
    DROP TABLE #RAFTUpdate;
END;


CREATE TABLE #RAFTUpdate
(
    [PlanId] INT,
    [HICN] VARCHAR(12),
    [PartCRAFTProjected] VARCHAR(2),
    [PaymentYear] INT,
    [PartCRAFTMMR] VARCHAR(2),
    [MaxPaymstart] DATETIME
);
INSERT INTO #RAFTUpdate
(
    [PlanId],
    [HICN],
    [PartCRAFTProjected],
    [PaymentYear],
    [PartCRAFTMMR],
    [MaxPaymstart]
)
SELECT DISTINCT
       [PlanId] = [mmr].[PlanID],
       [HICN] = [mmr].[HICN],
       [PartCRAFTProjected] = [mmr].[PartCRAFTProjected],
       [PaymentYear] = [mmr].[PaymentYear],
       [PartCRAFTMMR] = [mmr].[PartCRAFTMMR],
       MaxPaymstart = MAX([PaymStart])
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    JOIN [#Refresh_PY] [py]
        ON [mmr].[PaymentYear] = [py].[Payment_Year]
WHERE mmr.PartCRAFTMMR IS NOT NULL
      AND mmr.PartCRAFTProjected IS NOT NULL
GROUP BY [mmr].[PlanID],
         [mmr].[HICN],
         [mmr].[PartCRAFTProjected],
         [mmr].[PaymentYear],
         [mmr].[PartCRAFTMMR];

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

--WHILE (1 = 1)
--BEGIN

--    DELETE TOP (@DeleteBatch)
--    FROM [rev].[tbl_Summary_RskAdj_MOR]
--    WHERE [PaymentYear] IN
--          (
--              SELECT [py].[Payment_Year] FROM [#Refresh_PY] [py]
--          );

--    IF @@ROWCOUNT = 0
--        BREAK;
--    ELSE
--        CONTINUE;
--END;

--RE - 7078 Begin

DECLARE @C INT
DECLARE @ID INT = (SELECT COUNT([ID]) FROM  [#Refresh_PY])
DECLARE @PaymentYear Int
SET @RowCount = 0;

SET @C = 1

WHILE ( @C <= @ID )

BEGIN 

	SELECT @PaymentYear = [Payment_Year]  
        FROM   [#Refresh_PY]
		WHERE  [ID] = @C


if (object_id('[Out].[tbl_Summary_RskAdj_MOR]') is not null)

BEGIN
    
   Truncate table [Out].[tbl_Summary_RskAdj_MOR];
 
End



ALTER TABLE [Rev].[tbl_Summary_RskAdj_MOR] SWITCH  PARTITION $Partition.[pfn_SummPY] (@PaymentYear) TO [Out].[tbl_Summary_RskAdj_MOR] PARTITION $Partition.[pfn_SummPY] (@PaymentYear)


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



if (object_id('[Out].[tbl_Summary_RskAdj_MOR]') is not null)

BEGIN
    
   Truncate table [Out].[tbl_Summary_RskAdj_MOR];
 
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

/*E Truncate Or Delete rows in rev.tbl_Summary_RskAdj_MMR */
 

IF @Debug = 1
BEGIN
    SET STATISTICS XML ON;
END


/*TFS 55593  MMR CTE was removed and replaced w/ reference to [#tmp_CTE_mmr]  modified by D. Waddell 07/15/16 */
/**/;

INSERT INTO [Out].[tbl_Summary_RskAdj_MOR]
(
    [PlanID],
    [HICN],
    [PaymentYear],
    [PaymStart],
    [Model_Year],
    [Factor_Category],
    [Factor_Description],
    [Factor],
    [HCC_Number],
    [RAFT],
    [RAFT_ORIG],
    [HOSP],
    [OREC_CALC],
    [LoadDateTime],
    [Aged],
    [SubmissionModel],
    [RecordType]
)
SELECT DISTINCT
       [PlanID] = [t1].[PlanID],
       [HICN] = [t1].[HICN],
       [PaymentYear] = [t1].[PaymentYear],
       [PaymStart] = [t1].[PaymStart],
       [Model_Year] = [t1].[Model_Year],
       [Factor_Category] = [t1].[Factor_Category],
       [Factor_Description] = [t1].[Factor_Description],
       [Factor] = [t1].[Factor],
       [HCC_Number] = [t1].[HCC_Number],
       [RAFT] = [t1].[RAFT],
       [RAFT_ORIG] = [t1].[RAFT_ORIG],
       [HOSP] = [t1].[HOSP],
       [OREC_CALC] = [t1].[OREC_CALC],
       [LoadDateTime] = @LoadDateTime,
       [Aged] = [t1].[Aged],
       [t1].[SubmissionModel],
       [t1].[RecordType]
FROM
(
    SELECT [PlanID] = COALESCE([e].[PlanId], [m].[PlanIdentifier]),
           [HICN] = [m].[HICN],
           [PaymentYear] = [m].[PayMonthYear],
           [PaymStart] = [m].[PayMonthStart],
                                            -- 64138/US64855 HasanMF 4/25/2017: This logic for gathering ModelYear is based a modernized lookup table. This lookup table will account for all different RecordTypes coming out of MOR records.
           [Model_Year] = [rs].[ModelYear], -- TFS65752/US67065
           [Factor_Category] = 'MOR-HCC',
           [Factor_Description] = m.NAME,
           [Factor] = [m].[COMM],           --HasanMF 6/20/2017: This field will be updated after this section of script. 
           [HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([m].[NAME]), PATINDEX('%[A-Z]%', REVERSE([m].[NAME])) - 1))) AS INT),
           [RAFT] = ISNULL([e].[RAFT], e1.RAFT),
           [RAFT_ORIG] = ISNULL([e].[RAFT], e1.RAFT),
           [HOSP] = ISNULL(e.HOSP, e1.HOSP),
           [OREC_CALC] = ISNULL([e].[OREC_CALC], e1.[OREC_CALC]),
           [LoadDateTime] = @LoadDateTime,
           [Aged] = ISNULL(e.Aged, e1.Aged),
           [rs].[SubmissionModel],
           [rs].[RecordType]
    FROM [#AlthicnMOR] [m]
        LEFT JOIN [#tmp_CTE_mmr] [e]
            ON [m].[HICN] = [e].[HICN]
               AND [m].[PayMonthYear] = [e].[PaymentYear]
               AND [m].[Month] = [e].[PaymentMonth]
        LEFT JOIN [#tmp_CTE_mmr] [e1]
            ON [m].[HICN] = [e1].[HICN]
               AND [m].[PayMonthYear] = [e1].[PaymentYear]
               AND e1.MonthRow = 1
        LEFT JOIN [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] [rs]
            ON [rs].[RecordType] = [m].[RecordType]
               AND [rs].[PaymentYear] = [m].[PayMonthYear]
		Where [m].[PayMonthYear] = @PaymentYear

) [t1]


/* End of updated Section 19.0 per TFS65752/US567065  */
OPTION (RECOMPILE);

SET @RowCount = ISNULL(@RowCount, 0) + @@ROWCOUNT;

--IF @Debug = 1
--    BEGIN

--        SET STATISTICS XML OFF

--    END

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

ALTER TABLE [Out].[tbl_Summary_RskAdj_MOR] SWITCH  PARTITION $Partition.[pfn_SummPY] (@PaymentYear) TO [Rev].[tbl_Summary_RskAdj_MOR] PARTITION $Partition.[pfn_SummPY] (@PaymentYear)

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


SET @C = @C + 1


End;


UPDATE a
SET a.RAFT = r.PartCRAFTProjected,
    a.RAFT_ORIG = r.PartCRAFTMMR
FROM rev.[tbl_Summary_RskAdj_MOR] a
    JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
    JOIN #RAFTUpdate r
        ON a.HICN = r.HICN
           AND a.PaymentYear = r.PaymentYear
           AND a.PlanID = r.PlanId
WHERE (
          a.RAFT IS NULL
          OR a.RAFT_ORIG IS NULL
      );


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

/* End tmpMOR temp Table */

---RRI-1750 - Format HCC Label as per ESRD & Non ESRD HCC Model---

UPDATE [m]
SET 
	[m].[Factor_Description] 
		=	Case WHEN [m].[Factor_Description]  LIKE 'HCC00%' THEN
					 REPLACE([m].[Factor_Description], 'HCC00', 'HCC ')
				WHEN [m].[Factor_Description]  LIKE 'HCC0%' THEN
					 REPLACE([m].[Factor_Description], 'HCC0', 'HCC ')
				WHEN [m].[Factor_Description]  LIKE 'HCC1%' THEN
					REPLACE([m].[Factor_Description], 'HCC1', 'HCC 1')
				WHEN [m].[Factor_Description]  LIKE 'D-HCC00%' THEN
					REPLACE([m].[Factor_Description], 'D-HCC00', 'D-HCC ')
				WHEN [m].[Factor_Description]  LIKE 'D-HCC0%' THEN
					REPLACE([m].[Factor_Description], 'D-HCC0', 'D-HCC ')
				WHEN [m].[Factor_Description]  LIKE 'D-HCC1%' THEN
					REPLACE([m].[Factor_Description], 'D-HCC1', 'D-HCC 1')
				ELSE [m].[Factor_Description]
			END
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    JOIN [#Refresh_PY] [PY] 
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC [rfc]
        ON [PY].[Payment_Year] = [rfc].[PaymentYear]
           AND [m].[RAFT] = [rfc].[RAFactorType]
Where [rfc].[CMSModel]='CMS-HCC';


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

UPDATE [m]
SET 
	[m].[Factor_Description] 
		=	Case WHEN [m].[Factor_Description]  LIKE 'HCC00%' THEN
					 REPLACE([m].[Factor_Description], 'HCC00', 'HCC ')
				WHEN [m].[Factor_Description]  LIKE 'HCC0%' THEN
					 REPLACE([m].[Factor_Description], 'HCC0', 'HCC ')
				WHEN [m].[Factor_Description]  LIKE 'HCC1%' THEN
					REPLACE([m].[Factor_Description], 'HCC1', 'HCC 1')
				WHEN [m].[Factor_Description]  LIKE 'D-HCC00%' THEN
					REPLACE([m].[Factor_Description], 'D-HCC00', 'D-HCC ')
				WHEN [m].[Factor_Description]  LIKE 'D-HCC0%' THEN
					REPLACE([m].[Factor_Description], 'D-HCC0', 'D-HCC ')
				WHEN [m].[Factor_Description]  LIKE 'D-HCC1%' THEN
					REPLACE([m].[Factor_Description], 'D-HCC1', 'D-HCC 1')
				ELSE [m].[Factor_Description]
			END
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    JOIN [#Refresh_PY] [PY] 
        ON [m].[PaymentYear] = [PY].[Payment_Year]
Where [m].[RAFT] is null;



--UPDATE [m]
--SET [m].[Factor_Description] = [rm].[Factor_Description_Restated]
--FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
--    JOIN [#Refresh_PY] [PY] --HasanMF 2/28/2017: Update will only take place for PaymentYears being run.
--        ON [m].[PaymentYear] = [PY].[Payment_Year]
--    JOIN #lk_Risk_Models [rm]
--        ON [m].[Model_Year] = [rm].[Payment_Year]
--           AND [m].[RAFT] = [rm].[Factor_Type]
--           AND [m].[Factor_Description] = [rm].[Factor_Description_Restated]
--           AND [rm].[Part_C_D_Flag] = 'C'
--           AND [rm].[Demo_Risk_Type] = 'RISK'
--           AND [rm].[OREC] = 9999
--           AND [rm].[Aged] = [m].[Aged] -- US60182 
--           AND [m].[RAFT] IN ( 'C', 'I', 'CN', 'CF', 'CP' ) -- US60182
--           AND [m].[Factor_Description] NOT LIKE '% %'
--           AND [m].[Factor_Description] LIKE 'D-%';

--UPDATE [m]
--SET [m].[Factor_Description] = [rm].[Factor_Description_Restated]
--FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
--    JOIN [#Refresh_PY] [PY] --HasanMF 2/28/2017: Update will only take place for PaymentYears being run.
--        ON [m].[PaymentYear] = [PY].[Payment_Year]
--    JOIN #lk_Risk_Models [rm]
--        ON [m].[Model_Year] = [rm].[Payment_Year]
--           AND [m].[RAFT] = [rm].[Factor_Type]
--           AND [m].[Factor_Description] = [rm].[Factor_Description_Restated]
--           AND [rm].[Part_C_D_Flag] = 'C'
--           AND [rm].[Demo_Risk_Type] = 'RISK'
--           AND [rm].[OREC] = [m].[OREC_CALC]
--           AND [rm].[Aged] = [m].[Aged] -- US60182 
--           AND [m].[RAFT] IN ( 'C', 'I', 'CN', 'CF', 'CP' ) -- US60182
--           AND [m].[Factor_Description] NOT LIKE '% %'
--           AND [m].[Factor_Description] NOT LIKE 'D-%';

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
SET [m].[Factor] = 0.00
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    JOIN [#Refresh_PY] [PY] --HasanMF 2/28/2017: Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
WHERE [m].[RAFT] = 'HP';

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
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    JOIN [#Refresh_PY] [PY] --HasanMF 2/28/2017: Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN #lk_Risk_Models [mdl]
        ON [m].[Model_Year] = [mdl].[Payment_Year]
           AND [m].[RAFT] = [mdl].[Factor_Type]
           AND [m].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([mdl].[Factor_Description]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([mdl].[Factor_Description])
                                                                                                       ) - 1)
                                                    )
                                            ) AS INT)
           AND LEFT([m].[Factor_Description], 3) = LEFT([mdl].[Factor_Description], 3)
           AND [mdl].[Aged] = [m].[Aged] -- US60182 
WHERE [m].[OREC_CALC] = 9999
      AND PATINDEX('D-%', [m].[Factor_Description]) > 0
      AND [mdl].[Part_C_D_Flag] = 'C'
      AND [mdl].[Demo_Risk_Type] = 'Risk';
--AND [m].[Factor] IS NULL

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

UPDATE [m]
SET [m].[Factor] = [mdl].[Factor]
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    JOIN [#Refresh_PY] [PY] --HasanMF 2/28/2017: Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
    JOIN #lk_Risk_Models [mdl]
        ON [m].[Model_Year] = [mdl].[Payment_Year]
           AND [m].[RAFT] = [mdl].[Factor_Type]
           AND [m].[HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([mdl].[Factor_Description]), PATINDEX(
                                                                                                           '%[A-Z]%',
                                                                                                           REVERSE([mdl].[Factor_Description])
                                                                                                       ) - 1)
                                                    )
                                            ) AS INT)
           AND LEFT([m].[Factor_Description], 3) = LEFT([mdl].[Factor_Description], 3)
           AND [m].[OREC_CALC] = [mdl].[OREC]
           AND [mdl].[Aged] = [m].[Aged] -- US60182 
WHERE [mdl].[Part_C_D_Flag] = 'C'
      AND [mdl].[Demo_Risk_Type] = 'Risk';
--AND [m].[Factor] IS NULL

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

-- Update the Null Model Year to 2014 (per US53053  Hasan) 
--HasanMF 2/28/2017: This update is a short-term fix specifically for 2016 payment year. This issue of NULL Model Year results will need to be researched.

UPDATE [m]
SET [m].[Model_Year] = 2014
FROM [rev].[tbl_Summary_RskAdj_MOR] [m]
    JOIN [#Refresh_PY] [PY] --HasanMF 2/28/2017: Update will only take place for PaymentYears being run.
        ON [m].[PaymentYear] = [PY].[Payment_Year]
WHERE [m].[PaymentYear] = 2016
      AND [m].[Model_Year] IS NULL
      AND m.RAFT IN ( 'C', 'I', 'E', 'CN', 'CF', 'CP' );

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
 