CREATE PROC [rev].[spr_Summary_RskAdj_RAPS_Preliminary]
(
    @FullRefresh BIT = 0,
    @YearRefresh INT = NULL,
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
)
AS
/******************************************************************************************************************************** 
* Name			:	rev.spr_Summary_RskAdj_RAPS_Preliminary																		*
* Type 			:	Stored Procedure																							*																																																																																																																																																																																																																																																																																																																																																																																														
* Author       	:	Mitch Casto																									*
* Date			:	2016-03-21																									*
* Version			:																											*																																																									*
* Description		: Updates dbo.tbl_Summary_RskAdj_RAPS_Preliminary table with raw RAPS data									*	
*					Note: This stp is an adaptation from Summary 1.0 and will need further work to								*
*					optimize the sql.																							*
*																																*
* Version History :																												*
* =================================================================================================								*
* Author			Date		Version#    TFS Ticket#		Description															*																*
* -----------------	----------  --------    -----------		------------														*		
* Mitch Casto		2016-03-21	1.0			52224			Initial																*
* Mitch Casto		2016-05-18	1.1			53367			Add @ManualRun to remove requirment for								*																	
*																table ownership for Truncation when								*
*																run manually													*
*															Changed RefreshPY source to											*
*																dbo.tbl_Summary_RskAdj_RefreshPY								*
*															Added PlanIdentifier & HCC_Number									*
*																columns															*
*																																*
*  D. Waddell		2016-08-01	1.2			54208			Name Change  	[rev].[spr_Summary_RskAdj_RAPS] = >					*
*															[rev].[spr_Summary_RskAdj_RAPS_Preliminary]							*
*  D. Waddell       2016-09-08  1.3			55925			perform daily kill and fill of result                               *
*                                                           table based on the Payment Year                                     *
*                                                           by the Refresh PY   (US53053)                                       *
*  D.Waddell        2017-02-09	1.4         61874			Part C Summary 2.0: Phase 99.2.a - Synchronizing Summary 2.0 to     * 
*															current Summary                                                     *   
* Mitch Casto		2017-03-27	1.5			63302/US63790	Removed @ManualRun process and replaced	with parameterized delete	*
*															batch (Section 021 to 025)		                                    *
* Madhuri Suri      2017-06-06	1.6			65131           Addign Aged to RAPS Prelim											*
* Rakshit Lall		2018-05-29	1.7			71364			Enhancing JOIN with lk_Risk_Score_Factors_PartC						*
* D.Waddell			10/29/2019	1.8			RE-6981			Set Transaction Isolation Level Read to Uncommitted                 * 
* D. Waddell        10/31/2019  1.9         RE-6871/77179   Incorporate logic to resolve issue with Rag Diags containing Process*
*                                                           By Dates that are beyond the Final Sweep cutoff date.               *
* D. Waddell		04/14/2020	1.10		RE-7964	/78376  RAPS MOR Issue for correctng the PlanID/ContractID join             *
*********************************************************************************************************************************/

SET STATISTICS IO OFF;
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

/*****************************************************************/
/* Initialize value of local variables                           */
/*****************************************************************/

DECLARE @Min_Lagged_From_Date DATETIME = NULL;
DECLARE @Max_PY_MmrHicnList INT = NULL;
DECLARE @PY_FutureYear INT = NULL;

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
SET @DeleteBatch = ISNULL(@DeleteBatch, 300000);

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
/* B Get Refresh PY data */

CREATE TABLE [#Refresh_PY]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [Payment_Year] INT,
    [From_Date] SMALLDATETIME,
    [Thru_Date] SMALLDATETIME,
    [Lagged_From_Date] SMALLDATETIME,
    [Lagged_Thru_Date] SMALLDATETIME,
    [Final_Sweep_Date] SMALLDATETIME
) --HasanMF 10/21/2019 RE6871 10/31/2019
;

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
    [Final_Sweep_Date]
) --HasanMF RE6871 10/31/2019

SELECT [Payment_Year] = [a1].[Payment_Year],
       [From_Date] = [a1].[From_Date],
       [Thru_Date] = [a1].[Thru_Date],
       [Lagged_From_Date] = [a1].[Lagged_From_Date],
       [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date],
       [Final_Sweep_Date] = [a1].[Final_Sweep_Date] --HasanMF  RE6871 10/31/2019
FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];

/* E Get Refresh PY data */

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

IF (OBJECT_ID('tempdb.dbo.[#Vw_LkRiskModelsDiagHCC]') IS NOT NULL)
BEGIN
    DROP TABLE [#Vw_LkRiskModelsDiagHCC];
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

CREATE TABLE [#Vw_LkRiskModelsDiagHCC]
(
    [ICDCode] [NVARCHAR](255) NULL,
    [HCC_Label] [NVARCHAR](255) NULL,
    [Payment_Year] [FLOAT] NULL,
    [Factor_Type] [VARCHAR](3) NOT NULL,
    [ICDClassification] [TINYINT] NULL,
    [StartDate] [DATETIME] NOT NULL,
    [EndDate] [DATETIME] NOT NULL
);

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

INSERT INTO [#Vw_LkRiskModelsDiagHCC]
(
    [ICDCode],
    [HCC_Label],
    [Payment_Year],
    [Factor_Type],
    [ICDClassification],
    [StartDate],
    [EndDate]
)
SELECT [ICDCode] = [icd].[ICDCode],
       [HCC_Label] = [icd].[HCCLabel],
       [Payment_Year] = [icd].[PaymentYear],
       [Factor_Type] = [icd].[FactorType],
       [ICDClassification] = [icd].[ICDClassification],
       [StartDate] = [ef].[StartDate],
       [EndDate] = [ef].[EndDate]
FROM [$(HRPReporting)].[dbo].[vw_LkRiskModelsDiagHCC] [icd]
    JOIN [$(HRPReporting)].[dbo].[ICDEffectiveDates] [ef]
        ON [icd].[ICDClassification] = [ef].[ICDClassification];

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

IF (OBJECT_ID('tempdb.dbo.#AltHICNRAPS') IS NOT NULL)
BEGIN
    DROP TABLE [#AltHICNRAPS];
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

CREATE TABLE [#AltHICNRAPS]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [RAPS_DiagHCC_rollupID] [INT] NOT NULL,
    [PlanIdentifier] [SMALLINT] NOT NULL,
    [RAPSID] [INT] NOT NULL,
    [ProcessedBy] [SMALLDATETIME] NOT NULL,
    [CorrectedHICN] [VARCHAR](25) NULL,
    [Descr] [VARCHAR](255) NULL,
    [DiagnosisCode] [VARCHAR](7) NULL,
    [DiagnosisError1] [VARCHAR](3) NULL,
    [DiagnosisError2] [VARCHAR](3) NULL,
    [DOB] [DATETIME] NULL,
    [DOBError] [VARCHAR](3) NULL,
    [FileID] [VARCHAR](18) NULL,
    [Filler] [VARCHAR](75) NULL,
    [FromDate] [SMALLDATETIME] NULL,
    [HICN] [VARCHAR](12) NULL,
    [HICNError] [VARCHAR](3) NULL,
    [PatientControlNumber] [VARCHAR](40) NULL,
    [ProviderType] [VARCHAR](2) NULL,
    [SeqError] [VARCHAR](7) NULL,
    [SeqNumber] [VARCHAR](7) NULL,
    [ThruDate] [SMALLDATETIME] NULL,
    [Void_Indicator] [BIT] NULL,
    [Voided_by_RAPSID] [INT] NULL,
    [PartC_HCC] [VARCHAR](50) NULL,
    [PartD_HCC] [VARCHAR](50) NULL,
    [Accepted] [BIT] NULL,
    [Deleted] [VARCHAR](1) NULL,
    [Source_Id] [INT] NULL,
    [Provider_Id] [VARCHAR](40) NULL,
    [RAC] [VARCHAR](1) NULL,
    [RAC_Error] [VARCHAR](3) NULL,
    [ThruDateYear+1] [INT] NULL
);

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


SET @Min_Lagged_From_Date =
(
    SELECT MIN([Lagged_From_Date]) FROM [#Refresh_PY]
);


INSERT INTO [#AltHICNRAPS]
(
    [RAPS_DiagHCC_rollupID],
    [PlanIdentifier],
    [RAPSID],
    [ProcessedBy],
    [CorrectedHICN],
    [Descr],
    [DiagnosisCode],
    [DiagnosisError1],
    [DiagnosisError2],
    [DOB],
    [DOBError],
    [FileID],
    [Filler],
    [FromDate],
    [HICN],
    [HICNError],
    [PatientControlNumber],
    [ProviderType],
    [SeqError],
    [SeqNumber],
    [ThruDate],
    [Void_Indicator],
    [Voided_by_RAPSID],
    [PartC_HCC],
    [PartD_HCC],
    [Accepted],
    [Deleted],
    [Source_Id],
    [Provider_Id],
    [RAC],
    [RAC_Error],
    [ThruDateYear+1]
)
SELECT [RAPS_DiagHCC_rollupID] = [a].[RAPS_DiagHCC_rollupID],
       [PlanIdentifier] = [a].[PlanIdentifier],
       [RAPSID] = [a].[RAPSID],
       [ProcessedBy] = [a].[ProcessedBy],
       [CorrectedHICN] = [a].[CorrectedHICN],
       [Descr] = [a].[Descr],
       [DiagnosisCode] = [a].[DiagnosisCode],
       [DiagnosisError1] = [a].[DiagnosisError1],
       [DiagnosisError2] = [a].[DiagnosisError2],
       [DOB] = [a].[DOB],
       [DOBError] = [a].[DOBError],
       [FileID] = [a].[FileID],
       [Filler] = [a].[Filler],
       [FromDate] = [a].[FromDate],
       [HICN] = ISNULL([althcn].[FINALHICN], [a].[HICN]),
       [HICNError] = [a].[HICNError],
       [PatientControlNumber] = [a].[PatientControlNumber],
       [ProviderType] = [a].[ProviderType],
       [SeqError] = [a].[SeqError],
       [SeqNumber] = [a].[SeqNumber],
       [ThruDate] = [a].[ThruDate],
       [Void_Indicator] = [a].[Void_Indicator],
       [Voided_by_RAPSID] = [a].[Voided_by_RAPSID],
       [PartC_HCC] = [a].[PartC_HCC],
       [PartD_HCC] = [a].[PartD_HCC],
       [Accepted] = [a].[Accepted],
       [Deleted] = [a].[Deleted],
       [Source_Id] = [a].[Source_Id],
       [Provider_Id] = [a].[Provider_Id],
       [RAC] = [a].[RAC],
       [RAC_Error] = [a].[RAC_Error],
       [ThruDateYear+1] = YEAR([a].[ThruDate]) + 1
FROM [dbo].[RAPS_DiagHCC_rollup] [a]
    LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].[PlanIdentifier] = [althcn].[PlanID]
           AND [a].[HICN] = [althcn].[HICN]
WHERE [a].[HICN] IS NOT NULL
      AND
      (
          [a].[DiagnosisError1] IS NULL
          OR [a].[DiagnosisError1] > '500'
      )
      AND
      (
          [a].[DiagnosisError2] IS NULL
          OR [a].[DiagnosisError2] > '500'
      )
      AND [a].[DOBError] IS NULL
      AND [a].[SeqError] IS NULL
      AND [a].[RAC_Error] IS NULL
      AND
      (
          [a].[HICNError] > '499'
          OR [a].[HICNError] IS NULL
      )
      AND [a].[ThruDate] >= @Min_Lagged_From_Date; --TFS61874 1/31/2017 HasanMF -- limiting incoming dataflow during initial data gathering


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

IF (OBJECT_ID('tempdb.dbo.[#tbl_0010_MmrHicnList]') IS NOT NULL)
BEGIN
    DROP TABLE [#tbl_0010_MmrHicnList];
END;

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

CREATE TABLE [#tbl_0010_MmrHicnList]
(
    [PlanIdentifier] [INT] NULL,
    [PaymentYear] [INT] NULL,
    [HICN] [VARCHAR](12) NULL,
    [PartCRAFTProjected] [VARCHAR](2) NULL,
    [Aged] INT NULL
); --65131

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

INSERT INTO [#tbl_0010_MmrHicnList]
(
    [PlanIdentifier],
    [PaymentYear],
    [HICN],
    [PartCRAFTProjected],
    [Aged]
) --65131
SELECT DISTINCT
       [PlanIdentifier] = [mmr].[PlanID],
       [PaymentYear] = [mmr].[PaymentYear],
       [HICN] = [mmr].[HICN],
       [PartCRAFTProjected] = [mmr].[PartCRAFTProjected],
       [Aged] = [mmr].Aged --MS Fix 65131
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr] WITH (NOLOCK)
    JOIN [#Refresh_PY] [py]
        ON [mmr].[PaymentYear] = [py].[Payment_Year];


--1/31/2017 TFS61874     HasanMF
SET @PY_FutureYear =
(
    SELECT MAX([Payment_Year]) FROM [#Refresh_PY]
);
SET @Max_PY_MmrHicnList =
(
    SELECT MAX([PaymentYear]) FROM [#tbl_0010_MmrHicnList]
);


IF @PY_FutureYear > YEAR(GETDATE())
BEGIN
    INSERT INTO [#tbl_0010_MmrHicnList]
    (
        [PlanIdentifier],
        [PaymentYear],
        [HICN],
        [PartCRAFTProjected],
        [Aged]
    )
    SELECT DISTINCT
           [PlanIdentifier],
           [PaymentYear] + 1, -- US61874  1/31/2017 HasanMF -- This additional insert will allow for current year RAPS Encounters to flow through.
           [HICN],
           [PartCRAFTProjected],
           [Aged]
    FROM [#tbl_0010_MmrHicnList]
    WHERE [PaymentYear] = @Max_PY_MmrHicnList;
END;
--1/31/2017 HasanMF


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

IF (OBJECT_ID('tempdb.dbo.[#tbl_0020_HicnPYMySplits]') IS NOT NULL)
BEGIN
    DROP TABLE [#tbl_0020_HicnPYMySplits];
END;

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

CREATE TABLE [#tbl_0020_HicnPYMySplits]
(
    [PlanIdentifier] INT NULL,
    [PaymentYear] [INT] NULL,
    [ModelYear] [INT] NULL,
    [HICN] [VARCHAR](12) NULL,
    [PartCRAFTProjected] [VARCHAR](2) NULL,
    [Aged] INT NULL
); --65131

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

INSERT INTO [#tbl_0020_HicnPYMySplits]
(
    [PlanIdentifier],
    [PaymentYear],
    [ModelYear],
    [HICN],
    [PartCRAFTProjected],
    [Aged]
) --65131
SELECT DISTINCT
       [PlanIdentifier] = [a].[PlanIdentifier],
       [PaymentYear] = [a].[PaymentYear],
       [ModelYear] = [split].[ModelYear],
       [HICN] = [a].[HICN],
       [PartCRAFTProjected] = [a].[PartCRAFTProjected],
       [Aged] --65131
FROM [#tbl_0010_MmrHicnList] [a]
    JOIN [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] [split] WITH (NOLOCK)
        ON [a].[PaymentYear] = [split].[PaymentYear]
           AND [a].[PartCRAFTProjected] = [split].[RAFactorType]
           AND [split].[SubmissionModel] = 'RAPS';

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

CREATE NONCLUSTERED INDEX [IX_#tbl_0020_HicnPYMySplits]
ON [#tbl_0020_HicnPYMySplits] (
                                  [HICN],
                                  [PaymentYear]
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

IF (OBJECT_ID('tempdb.dbo.[#tbl_0030_RapsGathered]') IS NOT NULL)
BEGIN
    DROP TABLE [#tbl_0030_RapsGathered];
END;

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

CREATE TABLE [#tbl_0030_RapsGathered]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [PlanIdentifier] [INT] NULL,
    [PaymentYear] [INT] NULL,
    [ModelYear] [INT] NULL,
    [HICN] [VARCHAR](12) NULL,
    [PartCRAFTProjected] [VARCHAR](2) NULL,
    [RAPS_DiagHCC_rollupID] [INT] NOT NULL,
    [RAPSID] [INT] NOT NULL,
    [ProcessedBy] [SMALLDATETIME] NOT NULL,
    [DiagnosisCode] [VARCHAR](7) NULL,
    [FileID] [VARCHAR](18) NULL,
    [FromDate] [SMALLDATETIME] NULL,
    [PatientControlNumber] [VARCHAR](40) NULL,
    [ProviderType] [VARCHAR](2) NULL,
    [SeqNumber] [VARCHAR](7) NULL,
    [ThruDate] [SMALLDATETIME] NULL,
    [Void_Indicator] [BIT] NULL,
    [Voided_by_RAPSID] [INT] NULL,
    [Accepted] [BIT] NULL,
    [Deleted] [VARCHAR](1) NULL,
    [Source_Id] [INT] NULL,
    [Provider_Id] [VARCHAR](40) NULL,
    [RAC] [VARCHAR](1) NULL,
    [RAC_Error] [VARCHAR](3) NULL,
    [Aged] INT NULL
); --65131

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

CREATE NONCLUSTERED INDEX [IX_#HF_AltHICNRAPS_HICN__ThruDateYear+1]
ON [#AltHICNRAPS] (
                      [HICN],
                      [ThruDateYear+1]
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

INSERT INTO [#tbl_0030_RapsGathered]
(
    [PlanIdentifier],
    [PaymentYear],
    [ModelYear],
    [HICN],
    [PartCRAFTProjected],
    [RAPS_DiagHCC_rollupID],
    [RAPSID],
    [ProcessedBy],
    [DiagnosisCode],
    [FileID],
    [FromDate],
    [PatientControlNumber],
    [ProviderType],
    [SeqNumber],
    [ThruDate],
    [Void_Indicator],
    [Voided_by_RAPSID],
    [Accepted],
    [Deleted],
    [Source_Id],
    [Provider_Id],
    [RAC],
    [RAC_Error],
    [Aged]
)
SELECT ---DISTINCT	???
    [PlanIdentifier] = [raps].[PlanIdentifier],   --RE-7964 (D.Waddell - 4/15/20)
    [PaymentYear] = [a].[PaymentYear],
    [ModelYear] = [a].[ModelYear],
    [HICN] = [a].[HICN],
    [PartCRAFTProjected] = [a].[PartCRAFTProjected],
    [RAPS_DiagHCC_rollupID] = [raps].[RAPS_DiagHCC_rollupID],
    [RAPSID] = [raps].[RAPSID],
    [ProcessedBy] = [raps].[ProcessedBy],
    [DiagnosisCode] = [raps].[DiagnosisCode],
    [FileID] = [raps].[FileID],
    [FromDate] = [raps].[FromDate],
    [PatientControlNumber] = [raps].[PatientControlNumber],
    [ProviderType] = [raps].[ProviderType],
    [SeqNumber] = [raps].[SeqNumber],
    [ThruDate] = [raps].[ThruDate],
    [Void_Indicator] = [raps].[Void_Indicator],
    [Voided_by_RAPSID] = [raps].[Voided_by_RAPSID],
    [Accepted] = [raps].[Accepted],
    [Deleted] = [raps].[Deleted],
    [Source_Id] = [raps].[Source_Id],
    [Provider_Id] = [raps].[Provider_Id],
    [RAC] = [raps].[RAC],
    [RAC_Error] = [raps].[RAC_Error], --select *
    [Aged] = a.[Aged]
FROM [#tbl_0020_HicnPYMySplits] [a]
    JOIN [#AltHICNRAPS] [raps]
        ON [a].[PaymentYear] = [raps].[ThruDateYear+1]
           AND [a].[HICN] = [raps].[HICN]
    --RE6871 10/31/2019: Begin edit
    JOIN [#Refresh_PY] [py]
        ON [a].[PaymentYear] = [py].[Payment_Year]
WHERE [raps].[Deleted] IS NULL --RE6871 10/31/2019: End Edit
      AND [raps].[ProcessedBy] <= [py].[Final_Sweep_Date]
UNION ALL
SELECT [PlanIdentifier] = [raps].[PlanIdentifier],   --RE-7964 (D.Wa ddell - 4/15/20)
       [PaymentYear] = [a].[PaymentYear],
       [ModelYear] = [a].[ModelYear],
       [HICN] = [a].[HICN],
       [PartCRAFTProjected] = [a].[PartCRAFTProjected],
       [RAPS_DiagHCC_rollupID] = [raps].[RAPS_DiagHCC_rollupID],
       [RAPSID] = [raps].[RAPSID],
       [ProcessedBy] = [raps].[ProcessedBy],
       [DiagnosisCode] = [raps].[DiagnosisCode],
       [FileID] = [raps].[FileID],
       [FromDate] = [raps].[FromDate],
       [PatientControlNumber] = [raps].[PatientControlNumber],
       [ProviderType] = [raps].[ProviderType],
       [SeqNumber] = [raps].[SeqNumber],
       [ThruDate] = [raps].[ThruDate],
       [Void_Indicator] = [raps].[Void_Indicator],
       [Voided_by_RAPSID] = [raps].[Voided_by_RAPSID],
       [Accepted] = [raps].[Accepted],
       [Deleted] = [raps].[Deleted],
       [Source_Id] = [raps].[Source_Id],
       [Provider_Id] = [raps].[Provider_Id],
       [RAC] = [raps].[RAC],
       [RAC_Error] = [raps].[RAC_Error], --select *
       [Aged] = a.[Aged]
FROM [#tbl_0020_HicnPYMySplits] [a]
    JOIN [#AltHICNRAPS] [raps]
        ON [a].[PaymentYear] = [raps].[ThruDateYear+1]
           AND [a].[HICN] = [raps].[HICN]
WHERE [raps].[Deleted] IS NOT NULL
--HasanMF 10/21/2019: end edit
;



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


/*B Truncate Or Delete rows in rev.tbl_Summary_RskAdj_RAPS_Preliminary */

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

IF @Debug = 1
BEGIN
    SET STATISTICS IO OFF;
END;
-- TFS 55925 logic chg. to delete based on Refresh PY Payment YR 

WHILE (1 = 1)
BEGIN

    DELETE TOP (@DeleteBatch)
    FROM [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]
    WHERE [PaymentYear] IN
          (
              SELECT [py].[Payment_Year] FROM [#Refresh_PY] [py]
          );

    IF @@ROWCOUNT = 0
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
    EXEC [dbo].[PerfLogMonitor] '025',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                0;
END;



/*E Truncate Or Delete rows in rev.tbl_Summary_RskAdj_RAPS_Preliminary */



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

CREATE NONCLUSTERED INDEX [IX_#tbl_0030_RapsGathered]
ON [#tbl_0030_RapsGathered] (
                                [DiagnosisCode],
                                [ThruDate]
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

INSERT INTO [rev].[tbl_Summary_RskAdj_RAPS_Preliminary]
(
    [PlanIdentifier],
    [PaymentYear],
    [ModelYear],
    [HICN],
    [PartCRAFTProjected],
    [RAPS_DiagHCC_rollupID],
    [RAPSID],
    [ProcessedBy],
    [DiagnosisCode],
    [FileID],
    [FromDate],
    [PatientControlNumber],
    [ProviderType],
    [SeqNumber],
    [ThruDate],
    [Void_Indicator],
    [Voided_by_RAPSID],
    [Accepted],
    [Deleted],
    [Source_Id],
    [Provider_Id],
    [RAC],
    [RAC_Error],
    [HCC_Label],
    [HCC_Number],
    [LoadDateTime],
    [Aged]
)
SELECT [PlanIdentifier] = [a].[PlanIdentifier],
       [PaymentYear] = [a].[PaymentYear],
       [ModelYear] = [a].[ModelYear],
       [HICN] = [a].[HICN],
       [PartCRAFTProjected] = [a].[PartCRAFTProjected],
       [RAPS_DiagHCC_rollupID] = [a].[RAPS_DiagHCC_rollupID],
       [RAPSID] = [a].[RAPSID],
       [ProcessedBy] = [a].[ProcessedBy],
       [DiagnosisCode] = [a].[DiagnosisCode],
       [FileID] = [a].[FileID],
       [FromDate] = [a].[FromDate],
       [PatientControlNumber] = [a].[PatientControlNumber],
       [ProviderType] = [a].[ProviderType],
       [SeqNumber] = [a].[SeqNumber],
       [ThruDate] = [a].[ThruDate],
       [Void_Indicator] = [a].[Void_Indicator],
       [Voided_by_RAPSID] = [a].[Voided_by_RAPSID],
       [Accepted] = [a].[Accepted],
       [Deleted] = [a].[Deleted],
       [Source_Id] = [a].[Source_Id],
       [Provider_Id] = [a].[Provider_Id],
       [RAC] = [a].[RAC],
       [RAC_Error] = [a].[RAC_Error],
       [HCC_Label] = [hcc].[HCC_Label],
       /*B ??May need to confirm that text is number before casting as INT */
       [HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([hcc].[HCC_Label]), PATINDEX(
                                                                                      '%[A-Z]%',
                                                                                      REVERSE([hcc].[HCC_Label])
                                                                                  ) - 1)
                                        )
                                ) AS INT),
       /*E ??May need to confirm that text is number before casting as INT */
       [LoadDateTime] = @LoadDateTime,
       [Aged] = [a].[Aged]
FROM [#tbl_0030_RapsGathered] [a]
    JOIN [#Vw_LkRiskModelsDiagHCC] [hcc]
        ON [a].[ModelYear] = [hcc].[Payment_Year]
           AND [a].[ThruDate]
           BETWEEN [hcc].[StartDate] AND [hcc].[EndDate]
           AND [a].[PartCRAFTProjected] = [hcc].[Factor_Type]
           AND [a].[DiagnosisCode] = [hcc].[ICDCode] 		   
		   GROUP BY [a].[PlanIdentifier],       --RE-7964 (D.Waddell - 4/15/20)  Begin
        [a].[PaymentYear],
        [a].[ModelYear],
        [a].[HICN],
        [a].[PartCRAFTProjected],
        [a].[RAPS_DiagHCC_rollupID],
        [a].[RAPSID],
        [a].[ProcessedBy],
        [a].[DiagnosisCode],
        [a].[FileID],
        [a].[FromDate],
        [a].[PatientControlNumber],
        [a].[ProviderType],
        [a].[SeqNumber],
        [a].[ThruDate],
        [a].[Void_Indicator],
        [a].[Voided_by_RAPSID],
        [a].[Accepted],
        [a].[Deleted],
        [a].[Source_Id],
        [a].[Provider_Id],
        [a].[RAC],
        [a].[RAC_Error],
        [hcc].[HCC_Label],
        [a].[Aged]      --RE-7964 (D.Waddell - 4/15/20)  End
		   
		   
		   
		   ;

SET @RowCount = @@ROWCOUNT;

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '028',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;