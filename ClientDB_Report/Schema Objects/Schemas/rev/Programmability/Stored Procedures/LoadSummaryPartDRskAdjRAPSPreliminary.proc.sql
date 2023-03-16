/*******************************************************************************************************************************
* Name			:	rev.LoadSummaryPartDRskAdjRAPSPreliminary
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   
* Date          :	10/25/2017
* Version		:	1.0
* Project		:	SP for loading "SummaryPartDRskAdjRAPSPreliminary" table
* SP call		:	Exec rev.LoadSummaryPartDRskAdjRAPSPreliminary 0
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------
* D Waddell         2018-01-26   1.1         69226 (RE-1357)  Select for insert into summary sourced from Summary MMR [Aged] changed to to now pick up from [PartDAged].
* D.Waddell			10/31/2019	 1.2		 77159/RE-6981	  Set Transaction Isolation Level Read to UNCOMMITTED
* D. Waddell		04/17/2020	 1.3         78376/ RE-7964   RAPS PartD MOR Issue for correctng the PlanID/ContractID join   
* Anand				5/29/2020	 1.4		 RRI-8/78743	  Batch in Insert Statements		
* Anand				12/21/2020   1.5         RRI-318/80206    Created Intermediate table instead of temp tables 
*********************************************************************************************************************************/
CREATE PROCEDURE [rev].[LoadSummaryPartDRskAdjRAPSPreliminary]
	@Debug BIT = 0
AS

BEGIN

SET STATISTICS IO OFF;
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE
	@Today DATETIME = GETDATE(),
	@ErrorMessage VARCHAR(500),
	@ErrorSeverity INT,
	@ErrorState INT,
	@MinValue INT,
	@MaxValue INT,
	@BatchSize INT

IF @Debug = 1
	BEGIN
		SET STATISTICS IO ON
		DECLARE 
			@ET DATETIME = @Today, 
			@MasterET DATETIME = @Today,
			@ProcessNameIn VARCHAR(128) = OBJECT_NAME(@@PROCID)
		EXEC [dbo].[PerfLogMonitor] @Section = '000', @ProcessName = @ProcessNameIn, @ET = @ET, @MasterET = @MasterET, @ET_Out = @ET OUT, @TableOutput = 0, @End = 0
	END

/* Determine years to refresh the data for */

IF OBJECT_ID('TempDB..#RefreshPY') IS NOT NULL
DROP TABLE #RefreshPY

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '001', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

CREATE TABLE #RefreshPY
(
	RefreshPYId INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	PaymentYear SMALLINT,
	FromDate SMALLDATETIME,
	ThruDate SMALLDATETIME,
	LaggedFromDate SMALLDATETIME,
	LaggedThruDate SMALLDATETIME
)

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '002', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

INSERT INTO #RefreshPY 
(
	PaymentYear,
	FromDate,
	ThruDate,
	LaggedFromDate,
	LaggedThruDate
)
SELECT
	Payment_Year,
	From_Date,
	Thru_Date,
	Lagged_From_Date,
	Lagged_Thru_Date
FROM rev.tbl_Summary_RskAdj_RefreshPY WITH(NOLOCK)

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '003', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

/* ICDCodes and HCC Label */

IF OBJECT_ID('TempDB..#LkRiskModelsDiagHCC') IS NOT NULL
DROP TABLE #LkRiskModelsDiagHCC

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '004', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

CREATE TABLE #LkRiskModelsDiagHCC 
(
	LkRiskModelsDiagHCCID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	ICDCode VARCHAR(7),
	HCCLabel VARCHAR(50),
	RxHCCNumber INT Null,
	PaymentYear SMALLINT,
	FactorType CHAR(2),
	StartDate DATETIME,
	EndDate DATETIME
)

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '005', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

CREATE NONCLUSTERED INDEX IX_ICDAndHCC ON #LkRiskModelsDiagHCC (ICDCode, HCCLabel)

INSERT INTO #LkRiskModelsDiagHCC 
(
	ICDCode,
	HCCLabel,
	RxHCCNumber,
	PaymentYear,
	FactorType,
	StartDate,
	EndDate
)
SELECT
	HCC.ICDCode,
	HCC.HCCLabel,
	CAST(LTRIM(REVERSE(LEFT(REVERSE(HCC.HCCLabel), PATINDEX('%[A-Z]%', REVERSE(HCC.HCCLabel))- 1))) AS INT) AS RxHCCNumber,
	HCC.PaymentYear,	
	HCC.FactorType,
	EF.StartDate,
	EF.EndDate
FROM [$(HRPReporting)].dbo.Vw_LkRiskModelsDiagHCC HCC WITH(NOLOCK)
JOIN [$(HRPReporting)].dbo.ICDEffectiveDates EF WITH(NOLOCK)
	ON HCC.ICDClassification = EF.ICDClassification
JOIN #RefreshPY PY
	ON PY.PaymentYear = HCC.PaymentYear
	
IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '006', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END	


DECLARE @MinLaggedFromDate SMALLDATETIME = (SELECT MIN(LaggedFromDate) FROM #RefreshPY)

Set @MinValue = (SELECT MIN(RAPS_DiagHCC_rollupID) FROM dbo.RAPS_DiagHCC_rollup Where ThruDate>=@MinLaggedFromDate);

Set @MaxValue = (SELECT MAX(RAPS_DiagHCC_rollupID) FROM dbo.RAPS_DiagHCC_rollup	Where RAPS_DiagHCC_rollupID >= Isnull(@MinValue,0));

Set @BatchSize=3000000

IF OBJECT_ID('[etl].[IntermediatePartDRAPSAltHicn]') IS NOT NULL
Begin
	TRUNCATE TABLE [etl].[IntermediatePartDRAPSAltHicn]
End

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '007', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END	

WHILE (@Minvalue <= @Maxvalue)

Begin

INSERT INTO [etl].[IntermediatePartDRAPSAltHicn] WITH (TABLOCKX) 
(
	PlanIdentifier,
	RAPSDiagHCCrollupID,
	RAPSID,
	ProcessedBy,
	DiagnosisCode,
	FileID,
	FromDate,
	HICN,
	PatientControlNumber,
	ProviderType,
	SeqNumber,
	ThruDate,
	VoidIndicator,
	VoidedByRAPSID,
	Accepted,
	Deleted,
	SourceId,
	ProviderId,
	RAC,
	RACError,
	ThruDatePlusone
)
SELECT DISTINCT
	RLUP.PlanIdentifier,
	RLUP.RAPS_DiagHCC_rollupID,
	RLUP.RAPSID,
	RLUP.ProcessedBy,
	RLUP.DiagnosisCode,
	RLUP.FileID,
	RLUP.FromDate,
	ISNULL(ALTHCN.FINALHICN, RLUP.HICN),
	RLUP.PatientControlNumber,
	RLUP.ProviderType,
	RLUP.SeqNumber,
	RLUP.ThruDate,
	RLUP.Void_Indicator,
	RLUP.Voided_by_RAPSID,
	RLUP.Accepted,
	RLUP.Deleted,
	RLUP.Source_Id,
	RLUP.Provider_Id,
	RLUP.RAC,
	RLUP.RAC_Error,
	YEAR(RLUP.ThruDate) + 1

FROM dbo.RAPS_DiagHCC_rollup RLUP WITH(NOLOCK)

JOIN #RefreshPY PY
	ON YEAR(RLUP.ThruDate) + 1 = PY.PaymentYear

LEFT JOIN rev.tbl_Summary_RskAdj_AltHICN ALTHCN WITH(NOLOCK)
	ON RLUP.PlanIdentifier = ALTHCN.PlanID
	AND RLUP.HICN = ALTHCN.HICN
WHERE 
	RLUP.HICN IS NOT NULL
AND 
	(RLUP.DiagnosisError1 IS NULL OR RLUP.DiagnosisError1 > '500')
AND 
	(RLUP.DiagnosisError2 IS NULL OR RLUP.DiagnosisError2 > '500')
AND 
	RLUP.DOBError IS NULL
AND 
	RLUP.SeqError IS NULL
AND 
	RLUP.RAC_Error IS NULL
AND 
	(RLUP.HICNError > '499' OR RLUP.HICNError IS NULL)
AND 
	RLUP.ThruDate >= @MinLaggedFromDate
AND
    RLUP.[RAPS_DiagHCC_rollupID] >=  @Minvalue   
	AND RLUP.[RAPS_DiagHCC_rollupID] < @Minvalue  +  @batchSize  
	
	SET @Minvalue = @Minvalue + @batchSize

End

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '008', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END	

IF OBJECT_ID('TempDB..#MmrHicnList') IS NOT NULL
DROP TABLE #MmrHicnList

CREATE TABLE #MmrHicnList 
(
	MmrHicnListID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	PaymentYear INT NULL,
	HICN VARCHAR(12) NULL,
	PartDRAFTProjected CHAR(2) NULL,
	Aged INT NULL
)

CREATE NONCLUSTERED INDEX IdX_MmrHicnList_HICN_Paymentyear ON #MmrHicnList (HICN ,PaymentYear ,PartDRAFTProjected)

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '009', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

INSERT INTO #MmrHicnList
(
	PaymentYear,
	HICN,
	PartDRAFTProjected,
	Aged
)
SELECT 
    MMR.PaymentYear,
    MMR.HICN,
    MMR.PartDRAFTProjected,
    MMR.PartDAged                     -- TFS 69226  (RE-1357)
FROM rev.tbl_Summary_RskAdj_MMR MMR WITH(NOLOCK)
JOIN #RefreshPY PY
	ON MMR.PaymentYear = PY.PaymentYear
GROUP BY
    MMR.PaymentYear,
    MMR.HICN,
    MMR.PartDRAFTProjected,
    MMR.PartDAged
    
IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '010', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END
   
Set @MinValue = 1

Set @MaxValue = (SELECT MAX(AltHICNRAPSID) FROM [etl].[IntermediatePartDRAPSAltHicn]);

Set @BatchSize=3000000

IF OBJECT_ID('[etl].[SummaryPartDRskAdjRAPSPreliminary]') IS NOT NULL

BEGIN
	TRUNCATE TABLE etl.SummaryPartDRskAdjRAPSPreliminary
END

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '011', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END

WHILE (@Minvalue <= @MaxValue)

Begin

INSERT INTO etl.SummaryPartDRskAdjRAPSPreliminary
(
	PaymentYear,
	PlanIdentifier,
	ModelYear,
	HICN,
	PartDRAFTProjected,
	RAPSDiagHCCRollupID,
	RAPSID,
	ProcessedBy,
	DiagnosisCode,
	FileID,
	FromDate,
	PatientControlNumber,
	ProviderType,
	SeqNumber,
	ThruDate,
	VoidIndicator,
	VoidedByRAPSID,
	Accepted,
	Deleted,
	SourceId,
	ProviderId,
	RAC,
	RACError,
	RxHCCLabel,
	RxHCCNumber,
	Aged,
	UserID,
	LoadDate
)
SELECT DISTINCT 
	MMR.PaymentYear,
	RAPS.PlanIdentifier,
	MMR.PaymentYear,
	RAPS.HICN,
	MMR.PartDRAFTProjected,
	RAPS.RAPSDiagHCCrollupID,
	RAPS.RAPSID,
	RAPS.ProcessedBy,
	RAPS.DiagnosisCode,
	RAPS.FileID,
	RAPS.FromDate,
	RAPS.PatientControlNumber,
	RAPS.ProviderType,
	RAPS.SeqNumber,
	RAPS.ThruDate,
	RAPS.VoidIndicator,
	RAPS.VoidedbyRAPSID,
	RAPS.Accepted,
	RAPS.Deleted,
	RAPS.SourceId,
	RAPS.ProviderId,
	RAPS.RAC,
	RAPS.RACError,
	hcc.HCCLabel,
	HCC.RxHCCNumber,
	MMR.Aged,
	SYSTEM_USER AS UserID,
	@Today AS LoadDate	
FROM [etl].[IntermediatePartDRAPSAltHicn] RAPS 

Join #MmrHicnList MMR 
	ON  RAPS.HICN=MMR.HICN
	AND RAPS.ThrudatePlusone=MMR.PaymentYear
			
JOIN #LkRiskModelsDiagHCC HCC
	ON MMR.PaymentYear = HCC.PaymentYear
	AND (RAPS.ThruDate >= HCC.StartDate AND RAPS.ThruDate <= HCC.EndDate)
	AND MMR.PartDRAFTProjected = HCC.FactorType
	AND RAPS.DiagnosisCode = HCC.ICDCode
	
Where RAPS.[AltHICNRAPSID] >=  @Minvalue   
  AND RAPS.[AltHICNRAPSID] < @Minvalue  +  @batchSize;

SET @Minvalue = @Minvalue + @batchSize

End

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '012', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END
	
IF EXISTS (SELECT TOP 1 1 FROM [etl].SummaryPartDRskAdjRAPSPreliminary)
BEGIN
 
	DECLARE @I INT
	DECLARE @ID INT = (SELECT COUNT(DISTINCT PaymentYear) FROM #RefreshPY)

	SET @I = 1

	WHILE ( @I <= @ID )
	BEGIN

	DECLARE @PaymentYear SMALLINT = (SELECT PaymentYear	FROM #RefreshPY WHERE RefreshPYID = @I)

	PRINT 'Starting Partition Switch For PaymentYear : ' + CONVERT(VARCHAR(4), @PaymentYear)

	BEGIN TRY

		BEGIN TRANSACTION SwitchPartitions;

		TRUNCATE TABLE [out].SummaryPartDRskAdjRAPSPreliminary

		-- Switch Partition for History SummaryPartDRskAdjRAPSPreliminary 
		ALTER TABLE hst.SummaryPartDRskAdjRAPSPreliminary
		SWITCH PARTITION $Partition.[pfn_SummPY] (@PaymentYear)
		TO [out].SummaryPartDRskAdjRAPSPreliminary PARTITION $Partition.[pfn_SummPY] (@PaymentYear)

		-- Switch Partition for DBO SummaryPartDRskAdjRAPSPreliminary 
		ALTER TABLE rev.SummaryPartDRskAdjRAPSPreliminary
		SWITCH PARTITION $Partition.[pfn_SummPY] (@PaymentYear)
		TO hst.SummaryPartDRskAdjRAPSPreliminary PARTITION $Partition.[pfn_SummPY] (@PaymentYear)

		-- Switch Partition for ETL SummaryPartDRskAdjRAPSPreliminary	
		ALTER TABLE etl.SummaryPartDRskAdjRAPSPreliminary	
		SWITCH PARTITION $Partition.[pfn_SummPY] (@PaymentYear)
		TO rev.SummaryPartDRskAdjRAPSPreliminary PARTITION $Partition.[pfn_SummPY] (@PaymentYear)
			
		COMMIT TRANSACTION SwitchPartitions;
		
	PRINT 'Partition Completed For PaymentYear : ' + CONVERT(VARCHAR(4), @PaymentYear)

	END TRY

	BEGIN CATCH

		SELECT 
			@ErrorMessage = ERROR_MESSAGE() ,
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		   IF (XACT_STATE() = 1 OR XACT_STATE() = -1)
		   BEGIN
				  ROLLBACK TRANSACTION SwitchPartitions;
		   END;

		   RAISERROR 
			(
				@ErrorMessage,
				@ErrorSeverity,
				@ErrorState
			);

		   RETURN;
		
	END CATCH;

	SET @I = @I + 1

	END
	
END

ELSE 
	
	PRINT 'Partition switching did not run because there was no data was loaded in the ETL table'

IF @Debug = 1
	BEGIN
		EXEC [dbo].[PerfLogMonitor] '013', @ProcessNameIn, @ET, @MasterET, @ET OUT, 0, 0
	END
	
END