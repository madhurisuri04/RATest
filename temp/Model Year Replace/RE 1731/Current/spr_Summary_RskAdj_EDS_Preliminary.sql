USE [PHP_Report]
GO
/****** Object:  StoredProcedure [rev].[spr_Summary_RskAdj_EDS_Preliminary]    Script Date: 1/10/2022 3:18:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [rev].[spr_Summary_RskAdj_EDS_Preliminary]
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
* Name			:	rev.spr_Summary_RskAdj_EDS_Preliminary																		*
* Type 			:	Stored Procedure																							*																																																																																																																																																																																																																																																																																																																																																																																														
* Author       	:	Mitch Casto																									*
* Date			:	2016-03-21																									*
* Version			:																											*																																																									*
* Description		: Updates dbo.tbl_Summary_RskAdj_EDS_Preliminary table with raw EDS data									*	
*					Note: This stp is an adaptation from Summary 1.0 and will need further work to								*
*					optimize the sql.																							*
*																																*
* Version History :																												*
* =================================================================================================								*
* Author			Date		Version#    TFS Ticket#		Description															*																*
* -----------------	----------  --------    -----------		------------														*		
* D. Waddell		2017-04-07	1.0			63706			Initial																*
* D. Waddell        2017-05-12  1.1         64778           Modify the Summary 2.0 EDS Preliminary module    (Sect. 027)        *
* D.Waddell         2017-06-02  1.2         65132           Changes to EDS Preliminary (sect. 027,028,029,030                   *   
* Rakshit Lall		2018-05-29	1.7			71364			Enhancing JOIN with lk_Risk_Score_Factors_PartC						*
* D. Waddell        2018-06-27  1.8                         Supplementing EDS Data Source with RAPS Data Source    (Section 8.2)* 
* Anand				2019-07-26  1.9			RE -5112		Exlcuded the Temp table part for Source and added [rev].[tbl_Summary_RskAdj_EDS_Source]
* Anand			    2019-09-06  2.0			RE-6373         Created Internediate Table for #Althicn to [Etl].[IntermediateEDSAltHicn]
* Anand				2019-09-20	2.1			RE-6373			Used Switch - Partition logic for Deleting records.
* D.Waddell			10/29/2019	1.3			RE-6981			Set Transaction Isolation Level Read to Uncommitted
/* Madhuri Suri 	3/29/2020	3.0  	   78036       	    EDS MOR Isuue for correctng the PlanID/ContractID join   
*/Madhuri Suri      3/17/2021   3.1        80979            Join correction for Plan and Contract ID
  Madhuri Suri      11/1/2021   3.2        RRI 1754         EDS Deletes
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
DECLARE @Curr_DB VARCHAR(128) = NULL;
DECLARE @Clnt_DB VARCHAR(128) = NULL;
DECLARE @RskAdj_SourceSQL VARCHAR(MAX);
DECLARE @Summary_RskAdj_EDS_SQL VARCHAR(MAX);


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

IF (OBJECT_ID('tempdb.dbo.[#Refresh_PY]') IS NOT NULL)
BEGIN
    DROP TABLE [#Refresh_PY];
END;

/* B Get Refresh PY data */

CREATE TABLE [#Refresh_PY]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [Payment_Year] INT NOT NULL,
    [From_Date] SMALLDATETIME NULL,
    [Thru_Date] SMALLDATETIME NULL,
    [Lagged_From_Date] SMALLDATETIME NULL,
    [Lagged_Thru_Date] SMALLDATETIME NULL
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
    [Lagged_Thru_Date]
)
SELECT [Payment_Year] = [a1].[Payment_Year],
       [From_Date] = [a1].[From_Date],
       [Thru_Date] = [a1].[Thru_Date],
       [Lagged_From_Date] = [a1].[Lagged_From_Date],
       [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];

INSERT INTO [#Refresh_PY]
(
    [Payment_Year],
    [From_Date],
    [Thru_Date],
    [Lagged_From_Date],
    [Lagged_Thru_Date]
)
SELECT [Payment_Year] = 2020,
       [From_Date] = '2019-01-01',
       [Thru_Date] = '2019-12-31', 
       [Lagged_From_Date] = '2018-07-01',
       [Lagged_Thru_Date] = '2019-06-30'


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

SET @Curr_DB =
(
    SELECT [Current Database] = DB_NAME()
);

SET @Clnt_DB = SUBSTRING(@Curr_DB, 0, CHARINDEX('_Report', @Curr_DB));

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
SELECT DISTINCT
       [ICDCode] = [icd].[ICDCode],
       [HCC_Label] = [icd].[HCCLabel],
       [Payment_Year] = [icd].[PaymentYear],
       [Factor_Type] = [icd].[FactorType],
       [ICDClassification] = [icd].[ICDClassification],
       [StartDate] = [ef].[StartDate],
       [EndDate] = [ef].[EndDate]
FROM [HRPReporting].[dbo].[Vw_LkRiskModelsDiagHCC] [icd]
    JOIN [HRPReporting].[dbo].[ICDEffectiveDates] [ef]
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


CREATE NONCLUSTERED INDEX [IX_Vw_LkRiskModelsDiagHCC]
ON [#Vw_LkRiskModelsDiagHCC] (
                                 [Payment_Year],
                                 [StartDate],
                                 [EndDate],
                                 [Factor_Type],
                                 [ICDCode]
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


SET @Min_Lagged_From_Date =
(
    SELECT MIN([Lagged_From_Date]) FROM [#Refresh_PY]
);


IF (OBJECT_ID('tempdb.dbo.[#tbl_0010_MmrHicnList]') IS NOT NULL)
BEGIN
    DROP TABLE [#tbl_0010_MmrHicnList];
END;

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

CREATE TABLE [#tbl_0010_MmrHicnList]
(
    [PlanIdentifier] [INT] NULL,
    [PaymentYear] [INT] NULL,
    [HICN] [VARCHAR](12) NULL,
    [PartCRAFTProjected] [VARCHAR](2) NULL,
    [ModelYear] [INT] NULL
);

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

INSERT INTO [#tbl_0010_MmrHicnList]
(
    [PlanIdentifier],
    [PaymentYear],
    [HICN],
    [PartCRAFTProjected],
    [ModelYear]
)
SELECT DISTINCT
       [PlanIdentifier] = [mmr].[PlanID],
       [PaymentYear] = [mmr].[PaymentYear],
       [HICN] = [mmr].[HICN],
       [PartCRAFTProjected] = [mmr].[PartCRAFTProjected],
       [ModelYear] = [split].[ModelYear]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr] WITH (NOLOCK)
    JOIN [#Refresh_PY] [py]
        ON [mmr].[PaymentYear] = [py].[Payment_Year]
    JOIN [HRPReporting].[dbo].[lk_Risk_Score_Factors_PartC] [split] WITH (NOLOCK)
        ON [mmr].[PaymentYear] = [split].[PaymentYear]
           AND [mmr].[PartCRAFTProjected] = [split].[RAFactorType]
           AND [split].[SubmissionModel] = 'EDS';


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

--1/31/2017 TFS61874     HasanMF
SET @PY_FutureYear =
(
    SELECT MAX([Payment_Year]) FROM [#Refresh_PY]
);


SET @Max_PY_MmrHicnList =
(
    SELECT MAX([PaymentYear]) FROM [#tbl_0010_MmrHicnList] WITH (NOLOCK)
);

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

IF @PY_FutureYear > YEAR(GETDATE())
BEGIN
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

    INSERT INTO [#tbl_0010_MmrHicnList]
    (
        [PlanIdentifier],
        [PaymentYear],
        [HICN],
        [PartCRAFTProjected],
        [ModelYear]
    )
    SELECT DISTINCT
           [a].[PlanIdentifier],
           [a].[PaymentYear] + 1, -- US61874  1/31/2017 HasanMF -- This additional insert will allow for current year RAPS Encounters to flow through.
           [a].[HICN],
           [a].[PartCRAFTProjected],
           [split].[ModelYear]
    FROM [#tbl_0010_MmrHicnList] [a]
        JOIN [HRPReporting].[dbo].[lk_Risk_Score_Factors_PartC] [split] WITH (NOLOCK)
            ON [a].[PaymentYear] = [split].[PaymentYear]
               AND [a].[PartCRAFTProjected] = [split].[RAFactorType]
               AND [split].[SubmissionModel] = 'EDS'
    WHERE [a].[PaymentYear] = @Max_PY_MmrHicnList;



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

END; --1/31/2017 HasanMF


CREATE NONCLUSTERED INDEX [IX_tbl_0010_MmrHicnList]
ON [#tbl_0010_MmrHicnList] (
                               [HICN],
                               [PaymentYear],
                               [PartCRAFTProjected]
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

IF (OBJECT_ID('[Etl].[IntermediateEDSAltHicn]') IS NOT NULL)
BEGIN
    TRUNCATE TABLE [Etl].[IntermediateEDSAltHicn];
END;



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


INSERT INTO [Etl].[IntermediateEDSAltHicn]
(
    [PlanIdentifier],
    [PaymentYear],
    [PartCRAFTProjected],
    [ModelYear],
    [MAO004ResponseID],
    [stgMAO004ResponseID],
    [ContractID],
    [HICN],
    [SentEncounterICN],
    [ReplacementEncounterSwitch],
    [SentICNEncounterID],
    [OriginalEncounterICN],
    [OriginalICNEncounterID],
    [PlanSubmissionDate],
    [ServiceStartDate],
    [ServiceEndDate],
    [ClaimType],
    [FileImportID],
    [LoadID],
    [LoadDate],
    [SentEncounterRiskAdjustableFlag],
    [RiskAdjustableReasonCodes],
    [OriginalEncounterRiskAdjustableFlag],
    [MAO004ResponseDiagnosisCodeID],
    [DiagnosisCode],
    [DiagnosisICD],
    [DiagnosisFlag],
    [IsDelete],
    [ClaimID],
    [EntityDiscriminator],
    [BaseClaimID],
    [SecondaryClaimID],
    [ClaimIndicator],
    [EncounterRiskAdjustable],
    [RecordID],
    [SystemSource],
    [VendorID],
    [MedicalRecordImageID],
    [SubProjectMedicalRecordID],
    [SubProjectID],
    [SubProjectName],
    [SupplementalID],
    [DerivedPatientControlNumber],
    [YearServiceEndDate]
)
SELECT DISTINCT
       [PlanIdentifier] = [b].PlanIdentifier,
       [PaymentYear] = [B].PaymentYear,
       [PartCRAFTProjected] = [B].PartCRAFTProjected,
       [ModelYear] = [B].ModelYear,
       [MAO004ResponseID] = [a].[MAO004ResponseID],
       [stgMAO004ResponseID] = [a].[stgMAO004ResponseID],
       [ContractID] = [a].[ContractID],  --RRI 799
       [HICN] = [a].[HICN],
       [SentEncounterICN] = [a].[SentEncounterICN],
       [ReplacementEncounterSwitch] = [a].[ReplacementEncounterSwitch],
       [SentICNEncounterID] = [a].[SentICNEncounterID],
       [OriginalEncounterICN] = [a].[OriginalEncounterICN],
       [OriginalICNEncounterID] = [a].[OriginalICNEncounterID],
       [PlanSubmissionDate] = [a].[PlanSubmissionDate],
       [ServiceStartDate] = [a].[ServiceStartDate],
       [ServiceEndDate] = [a].[ServiceEndDate],
       [ClaimType] = [a].[ClaimType],
       [FileImportID] = [a].[FileImportID],
       [LoadID] = [a].[LoadID],
       [LoadDate] = [a].[SrcLoadDate],
       [SentEncounterRiskAdjustableFlag] = [a].[SentEncounterRiskAdjustableFlag],
       [RiskAdjustableReasonCodes] = [a].[RiskAdjustableReasonCodes],
       [OriginalEncounterRiskAdjustableFlag] = [a].[OriginalEncounterRiskAdjustableFlag],
       [MAO004ResponseDiagnosisCodeID] = [a].[MAO004ResponseDiagnosisCodeID],
       [DiagnosisCode] = [a].[DiagnosisCode],
       [DiagnosisICD] = [a].[DiagnosisICD],
       [DiagnosisFlag] = [a].[DiagnosisFlag],
       [IsDelete] = [a].[IsDelete],
       [ClaimID] = [a].[ClaimID],
       [EntityDiscriminator] = [a].[EntityDiscriminator],
       [BaseClaimID] = [a].[BaseClaimID],
       [SecondaryClaimID] = [a].[SecondaryClaimID],
       [ClaimIndicator] = [a].[ClaimIndicator],
       [EncounterRiskAdjustable] = [a].[EncounterRiskAdjustable],
       [RecordID] = [a].[RecordID],
       [SystemSource] = [a].[SystemSource],
       [VendorID] = [a].[VendorID],
       [MedicalRecordImageID] = [a].[MedicalRecordImageID],
       [SubProjectMedicalRecordID] = [a].[SubProjectMedicalRecordID],
       [SubProjectID] = [a].[SubProjectID],
       [SubProjectName] = [a].[SubProjectName],
       [SupplementalID] = [a].[SupplementalID],
       [DerivedPatientControlNumber] = [a].[DerivedPatientControlNumber],
       [YearServiceEndDate] = YEAR([a].[ServiceEndDate]) + 1
FROM [rev].[tbl_Summary_RskAdj_EDS_Source] [a] -- RE - 5112 

    JOIN [#tbl_0010_MmrHicnList] [B]
        ON [B].[HICN] = [a].[HICN]
           AND YEAR([a].[ServiceEndDate]) + 1 = [B].[PaymentYear]	
	--JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan r ON r.PlanIdentifier = b.PlanIdentifier
	--                                  AND r.PlanID = a.ContractID
WHERE [a].[HICN] IS NOT NULL
      AND [a].[ServiceEndDate] >= @Min_Lagged_From_Date; -- HasanMF limiting incoming dataflow during initial data gathering


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

INSERT INTO [Etl].[IntermediateEDSAltHicn]
(
    [PlanIdentifier],
    [PaymentYear],
    [PartCRAFTProjected],
    [ModelYear],
    [MAO004ResponseID],
    [stgMAO004ResponseID],
    [ContractID],
    [HICN],
    [PlanSubmissionDate],
    [ServiceStartDate],
    [ServiceEndDate],
    [LoadDate],
    [SentEncounterRiskAdjustableFlag],
    [MAO004ResponseDiagnosisCodeID],
    [DiagnosisCode],
    [DiagnosisFlag],
    [IsDelete],
    [DerivedPatientControlNumber],
	[EncounterRiskAdjustable],
    [YearServiceEndDate]
)
SELECT DISTINCT
       [PlanIdentifier] = [A].[PlanIdentifier],
       [PaymentYear] = [B].[PaymentYear],
       [PartCRAFTProjected] = [B].[PartCRAFTProjected],
       [ModelYear] = [B].[ModelYear],
       [MAO004ResponseID] = [a].[RAPS_DiagHCC_rollupID],
       [stgMAO004ResponseID] = [a].[RAPS_DiagHCC_rollupID],
       [ContractID] = [r].Planid,
       [HICN] = ISNULL([althcn].[FINALHICN], [a].[HICN]),
       [PlanSubmissionDate] = [a].[ProcessedBy],
       [ServiceStartDate] = [a].[FromDate],
       [ServiceEndDate] = [a].[ThruDate],
       [LoadDate] = GETDATE(),
       [SentEncounterRiskAdjustableFlag] = 'A',
       [MAO004ResponseDiagnosisCodeID] = [a].[RAPS_DiagHCC_rollupID],
       [DiagnosisCode] = [a].[DiagnosisCode],
       [DiagnosisFlag] = ISNULL([a].[Accepted], 0),
       [IsDelete] =  CASE WHEN [a].[Deleted]  = 'A' THEN  1 
						  WHEN [a].[Deleted] = 'D' THEN  0  
						  ELSE NULL END  ,   ----RRI 1754
       [DerivedPatientControlNumber] = [a].[PatientControlNumber],
	   [EncounterRiskAdjustable] = 1,
       [YearServiceEndDate] = YEAR([a].ThruDate) + 1
FROM [dbo].[RAPS_DiagHCC_rollup] [a]
    INNER JOIN [HRPReporting].[dbo].[SupplementalRAPSInpatient] [s]
        ON [a].[ProviderType] = [s].[ProviderType]
           AND YEAR([a].[ThruDate]) + 1 = [s].[PaymentYear]
    LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].[PlanIdentifier] = [althcn].[PlanID]
           AND [a].[HICN] = [althcn].[HICN]
    LEFT JOIN [HRPInternalReports].[dbo].[Rollupplan] r
        ON r.PlanIdentifier = ISNULL([althcn].[PlanID], [a].[PlanIdentifier])
    JOIN [#tbl_0010_MmrHicnList] [B]
        ON [B].[HICN] = ISNULL([althcn].[FINALHICN], [a].[HICN])
           AND YEAR([a].ThruDate) + 1 = [B].[PaymentYear]
WHERE [a].[HICN] IS NOT NULL
      AND [a].[ThruDate] >= @Min_Lagged_From_Date
      AND [a].[Accepted] = 1 AND a.Deleted IS NULL; ---RRI 1754 
      --AND 
      --(
      --    [a].[DiagnosisError1] IS NULL
      --    OR [a].[DiagnosisError1] > '500'
      --)
      --AND
      --(
      --    [a].[DiagnosisError2] IS NULL
      --    OR [a].[DiagnosisError2] > '500'
      --)
      --AND [a].[DOBError] IS NULL
      --AND [a].[SeqError] IS NULL
      --AND [a].[RAC_Error] IS NULL
      --AND
      --(
      --    [a].[HICNError] > '499'
      --    OR [a].[HICNError] IS NULL
      --)




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



DECLARE @I INT;
DECLARE @ID INT =
        (
            SELECT COUNT([Id]) FROM [#Refresh_PY]
        );

SET @I = 1;


WHILE (@I <= @ID)
BEGIN

    DECLARE @PaymentYear INT;

    SELECT @PaymentYear = Payment_Year
    FROM [#Refresh_PY]
    WHERE [Id] = @I;


    IF (OBJECT_ID('[out].[tbl_Summary_RskAdj_EDS_Preliminary]') IS NOT NULL)
    BEGIN
        TRUNCATE TABLE [out].[tbl_Summary_RskAdj_EDS_Preliminary];
    END;


    IF (OBJECT_ID('[Etl].[tbl_Summary_RskAdj_EDS_Preliminary]') IS NOT NULL)
    BEGIN
        TRUNCATE TABLE [Etl].[tbl_Summary_RskAdj_EDS_Preliminary];
    END;


    ALTER TABLE [rev].[tbl_Summary_RskAdj_EDS_Preliminary] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].[tbl_Summary_RskAdj_EDS_Preliminary] PARTITION $Partition.[pfn_SummPY](@PaymentYear);


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


    INSERT INTO [Etl].[tbl_Summary_RskAdj_EDS_Preliminary]
    (
        [PlanIdentifier],
        [PaymentYear],
        [ModelYear],
        [HICN],
        [PartCRAFTProjected],
        [MAO004ResponseID],
        [stgMAO004ResponseID],
        [ContractID],
        [SentEncounterICN],
        [ReplacementEncounterSwitch],
        [SentICNEncounterID],
        [OriginalEncounterICN],
        [OriginalICNEncounterID],
        [PlanSubmissionDate],
        [ServiceStartDate],
        [ServiceEndDate],
        [ClaimType],
        [FileImportID],
        [LoadID],
        [LoadDate],
        [SentEncounterRiskAdjustableFlag],     -- TFS 64778 HasanMF 5/9/2017: This fieldname needs to be changed to [SentEncounterRiskAdjustableFlag]
        [RiskAdjustableReasonCodes],           --   TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [RiskAdjustableReasonCodes]
        [OriginalEncounterRiskAdjustableFlag], --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [OriginalEncounterRiskAdjustableFlag]
        [MAO004ResponseDiagnosisCodeID],
        [DiagnosisCode],
        [DiagnosisICD],
        [DiagnosisFlag],
        [IsDelete],
        [ClaimID],
        [EntityDiscriminator],
        [BaseClaimID],
        [SecondaryClaimID],
        [ClaimIndicator],
        [RecordID],
        [SystemSource],
        [VendorID],
        [MedicalRecordImageID],
        [SubProjectMedicalRecordID],
        [SubProjectID],
        [SubProjectName],
        [SupplementalID],
        [DerivedPatientControlNumber],
        [Void_Indicator],
        [Voided_by_MAO004ResponseDiagnosisCodeID],
        [RiskAdjustable],                      -- TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [RiskAdjustable]
        [Deleted],
        [HCC_Label],
        [HCC_Number],
        [LoadDateTime],
        [MATCHED]                              -- US 66170   TFS 65132   added [MATCH] column by DW
    )
    SELECT DISTINCT
           [PlanIdentifier] = [a].[PlanIdentifier],
           [PaymentYear] = [a].[PaymentYear],
           [ModelYear] = [a].[ModelYear],
           [HICN] = [a].[HICN],
           [PartCRAFTProjected] = [a].[PartCRAFTProjected],
           [MAO004ResponseID] = [a].[MAO004ResponseID],
           [stgMAO004ResponseID] = [a].[stgMAO004ResponseID],
           [ContractID] = [a].[ContractID],
           [SentEncounterICN] = [a].[SentEncounterICN],
           [ReplacementEncounterSwitch] = [a].[ReplacementEncounterSwitch],
           [SentICNEncounterID] = [a].[SentICNEncounterID],
           [OriginalEncounterICN] = CASE
                                        WHEN [a].[OriginalEncounterICN] = 0 THEN
                                            NULL
                                        ELSE
                                            [a].[OriginalEncounterICN]
                                    END,                                                      --TFS 65132   DW 6/1/2017
           [OriginalICNEncounterID] = [a].[OriginalICNEncounterID],
           [PlanSubmissionDate] = [a].[PlanSubmissionDate],
           [ServiceStartDate] = [a].[ServiceStartDate],
           [ServiceEndDate] = [a].[ServiceEndDate],
           [ClaimType] = [a].[ClaimType],
           [FileImportID] = [a].[FileImportID],
           [LoadID] = [a].[LoadID],
           [LoadDate] = [a].[LoadDate],
           [SentEncounterRiskAdjustableFlag] = [a].[SentEncounterRiskAdjustableFlag],         --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [SentEncounterRiskAdjustableFlag]
           [RiskAdjustableReasonCodes] = [a].[RiskAdjustableReasonCodes],                     --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [RiskAdjustableReasonCodes]
           [OriginalEncounterRiskAdjustableFlag] = [a].[OriginalEncounterRiskAdjustableFlag], --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [OriginalEncounterRiskAdjustableFlag]
           [MAO004ResponseDiagnosisCodeID] = [a].[MAO004ResponseDiagnosisCodeID],
           [DiagnosisCode] = [a].[DiagnosisCode],
           [DiagnosisICD] = [a].[DiagnosisICD],
           [DiagnosisFlag] = [a].[DiagnosisFlag],
           [IsDelete] = [a].[IsDelete],
           [ClaimID] = [a].[ClaimID],
           [EntityDiscriminator] = [a].[EntityDiscriminator],
           [BaseClaimID] = [a].[BaseClaimID],
           [SecondaryClaimID] = [a].[SecondaryClaimID],
           [ClaimIndicator] = [a].[ClaimIndicator],
           [RecordID] = [a].[RecordID],
           [SystemSource] = [a].[SystemSource],
           [VendorID] = [a].[VendorID],
           [MedicalRecordImageID] = [a].[MedicalRecordImageID],
           [SubProjectMedicalRecordID] = [a].[SubProjectMedicalRecordID],
           [SubProjectID] = [a].[SubProjectID],
           [SubProjectName] = [a].[SubProjectName],
           [SupplementalID] = [a].[SupplementalID],
           [DerivedPatientControlNumber] = [a].[DerivedPatientControlNumber],
           [Void_Indicator] = 0,
           [Voided_by_MAO004ResponseDiagnosisCodeID] = 0,
           [RiskAdjustable] = a.EncounterRiskAdjustable,                        --RRI 1754 
           [Deleted] = CASE WHEN ISDelete = 1 THEN 'A'
		                    WHEN ISDelete = 0 THEN 'D'
							ELSE NULL END , ---rri 1754
           [HCC_Label] = [hcc].[HCC_Label],
           [HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([hcc].[HCC_Label]), PATINDEX(
                                                                                          '%[A-Z]%',
                                                                                          REVERSE([hcc].[HCC_Label])
                                                                                      ) - 1)
                                            )
                                    ) AS INT),
           [LoadDateTime] = @LoadDateTime,
           [MATCHED] = CASE
                           WHEN [a].[ReplacementEncounterSwitch] > 3
                                AND [a].[OriginalICNEncounterID] IS NOT NULL THEN
                               'Y'
                           WHEN [a].[ReplacementEncounterSwitch] > 3
                                AND [a].[OriginalICNEncounterID] IS NULL THEN
                               'N'
                           ELSE
                               NULL
                       END
    FROM [Etl].[IntermediateEDSAltHicn] [a]
        JOIN [#Vw_LkRiskModelsDiagHCC] [hcc]
            ON [a].[ModelYear] = [hcc].[Payment_Year]
               AND [a].[ServiceEndDate]
               BETWEEN [hcc].[StartDate] AND [hcc].[EndDate]
               AND [a].[PartCRAFTProjected] = [hcc].[Factor_Type]
               AND [a].[DiagnosisCode] = [hcc].[ICDCode]
    WHERE [a].[PaymentYear] = @PaymentYear;


    SET @RowCount = @@rowcount + ISNULL(@RowCount, 0);


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



    ALTER TABLE [etl].[tbl_Summary_RskAdj_EDS_Preliminary] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [rev].[tbl_Summary_RskAdj_EDS_Preliminary] PARTITION $Partition.[pfn_SummPY](@PaymentYear);



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



    SET @I = @I + 1;

END;




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

-------to be removed as Part of RRI 1754 


------TFS 65132   DW 6/1/2017
----UPDATE [a]
----SET [a].[Void_Indicator] = 1,
----    [a].[Voided_by_MAO004ResponseDiagnosisCodeID] = [b].[MAO004ResponseDiagnosisCodeID],
----    [a].[RiskAdjustable] = 0
----FROM [rev].[tbl_Summary_RskAdj_EDS_Preliminary] [a]
----    JOIN [rev].[tbl_Summary_RskAdj_EDS_Preliminary] [b]
----        ON [a].[SentEncounterICN] = [b].[OriginalEncounterICN]
----WHERE [b].[ReplacementEncounterSwitch] NOT IN ( 1, 4, 7 );

----IF @Debug = 1
----BEGIN
----    EXEC [dbo].[PerfLogMonitor] '022',
----                                @ProcessNameIn,
----                                @ET,
----                                @MasterET,
----                                @ET OUT,
----                                0,
----                                0;
----END;

----TFS 65132   DW 6/1/2017
----Void Diagnosis cluster when there is a corresponding Chart Review delete encounter

--UPDATE [a]
--SET [a].[Void_Indicator] = 1,
--    [a].[Voided_by_MAO004ResponseDiagnosisCodeID] = [b].[MAO004ResponseDiagnosisCodeID],
--    [a].[RiskAdjustable] = 0
--FROM [rev].[tbl_Summary_RskAdj_EDS_Preliminary] [a]
--    JOIN [rev].[tbl_Summary_RskAdj_EDS_Preliminary] [b]
--        ON [a].[SentEncounterICN] = [b].[OriginalEncounterICN]
--           AND [a].[DiagnosisCode] = [b].[DiagnosisCode]
--WHERE [b].[ReplacementEncounterSwitch] IN ( 7, 8, 9 );

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
--TFS 65132   DW 6/1/2017

SET @Summary_RskAdj_EDS_SQL
    = '
		Update a
Set [SystemSource] = [edv].[SystemSource]
from [rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
Join ' + @Clnt_DB
      + '.[dbo].[EncounterDerivedValues] edv
      on a.[SentICNEncounterID] = edv.[EncounterID]
where a.[SystemSource] is NULL';

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

EXEC (@Summary_RskAdj_EDS_SQL);

IF @Debug = 1
BEGIN
    EXEC [dbo].[PerfLogMonitor] '025',
                                @ProcessNameIn,
                                @ET,
                                @MasterET,
                                @ET OUT,
                                0,
                                1;
END;