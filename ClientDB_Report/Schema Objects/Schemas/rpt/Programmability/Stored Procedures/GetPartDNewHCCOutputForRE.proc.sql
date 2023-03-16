/*******************************************************************************************************************************
* Name			:	[rpt].[GetPartDNewHCCOutputForRE]
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   70246
* Date          :	3/26/2018
* Version		:	1.0
* Project		:	SP for generating the output for the Export in RE for the Part D New HCC Report
* SP call		:	Exec rpt.GetPartDNewHCCOutputForRE '2018', '1/1/2017', '12/31/2017', 'H<>', 'M', 'ALL', 'ALL', 1
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
	Rakshit Lall	4/8/2018	1.1			70246			Added PlanID parameter
	Rakshit Lall	4/10/2018	1.2			70510			Added ViewThrough parameter
*********************************************************************************************************************************/

CREATE PROCEDURE [rpt].[GetPartDNewHCCOutputForRE]
	@PaymentYear VARCHAR(4),
	@ProcessByStart DATETIME,
	@ProcessByEnd DATETIME,
	@PlanID VARCHAR(200),
	@ReportOutputByMonth CHAR(1),
	@RAPSStringAll VARCHAR(50),
	@FileStringAll VARCHAR(50),
	@ViewThrough INT
AS
BEGIN

SET NOCOUNT ON

IF (@ViewThrough = 1)
BEGIN

DECLARE
	@PYear VARCHAR(4) = @PaymentYear,
	@PStartDate DATETIME = @ProcessByStart,
	@PEndDate DATETIME = @ProcessByEnd,
	@PID VARCHAR(200) = @PlanID,
	@ROutput CHAR(1) = @ReportOutputByMonth,
	@RAPS VARCHAR(50) = @RAPSStringAll,
	@FIDString VARCHAR(50) = @FileStringAll

IF OBJECT_ID('TempDB..#TempPID') IS NOT NULL
DROP TABLE #TempPID

CREATE TABLE #TempPID
	(
		Item VARCHAR(200)
	)

INSERT INTO #TempPID
	(
		Item
	)
SELECT Item 
FROM dbo.fnsplit(@PID, ',')

-- When parameter selected is 'M'
	
IF (@ROutput = 'M')
BEGIN

	DECLARE	@RptSQL VARCHAR(7000)

	SET @RptSQL = 
	'
		SELECT
			 PaymentYear
			,ModelYear
			,PaymentStartDate
			,ProcessedByStartDate
			,ProcessedByEndDate
			,ProcessedByFlag
			,EncounterSource
			,PlanID
			,HICN
			,RAFactorType
			,RxHCC
			,HCCDescription
			,RxHCCFactor
			,HierarchyRxHCC
			,HierarchyRxHCCFactor
			,PreAdjustedFactor
			,AdjustedFinalFactor
			,HCCProcessedPCN
			,HierarchyHCCProcessedPCN
			,UniqueConditions
			,MonthsInDCP
			,BidAmount
			,EstimatedValue
			,RollForwardMonths
			,ActiveIndicatorForRollForward
			,PBP
			,SCC
			,ProcessedPriorityProcessedByDate
			,ProcessedPriorityThruDate
			,ProcessedPriorityDiag
			,ProcessedPriorityFileID
			,ProcessedPriorityRAC
			,ProcessedPriorityRAPSSourceID
			,DOSPriorityProcessedByDate
			,DOSPriorityThruDate
			,DOSPriorityPCN
			,DOSPriorityDiag
			,DOSPriorityFileID
			,DOSPriorityRAC
			,DOSPriorityRAPSSourceID
			,ProcessedPriorityICN
			,ProcessedPriorityEncounterID
			,ProcessedPriorityReplacementEncounterSwitch
			,ProcessedPriorityClaimID
			,ProcessedPrioritySecondaryClaimID
			,ProcessedPrioritySystemSource
			,ProcessedPriorityRecordID
			,ProcessedPriorityVendorID
			,ProcessedPrioritySubProjectID
			,ProcessedPriorityMatched
			,DOSPriorityICN
			,DOSPriorityEncounterID
			,DOSPriorityReplacementEncounterSwitch
			,DOSPriorityClaimID
			,DOSPrioritySecondaryClaimID
			,DOSPrioritySystemSource
			,DOSPriorityRecordID
			,DOSPriorityVendorID
			,DOSPrioritySubProjectID
			,DOSPriorityMatched
			,ProviderID
			,ProviderLast
			,ProviderFirst
			,ProviderGroup
			,ProviderAddress
			,ProviderCity
			,ProviderState
			,ProviderZip
			,ProviderPhone
			,ProviderFax
			,TaxID
			,NPI
			,SweepDate
			,AgedStatus
			,ProcessedPriorityMAO004ResponseDiagnosisCodeID
			,DOSPriorityMAO004ResponseDiagnosisCodeID
			,ProcessedPriorityMatchedEncounterICN
			,DOSPriorityMatchedEncounterICN
			,''M'' AS ReportOutput
		FROM rev.PartDNewHCCOutputMParameter WITH(NOLOCK)
		WHERE
			PaymentYear = ' + @PYear + '
		AND
			EXISTS (SELECT 1 FROM #TempPID tp WHERE PlanID = tp.Item)
		AND
			(ProcessedPriorityProcessedByDate >= ''' + CONVERT(VARCHAR(20),@PStartDate, 101) + '''
		AND 
			ProcessedPriorityProcessedByDate <= ''' + CONVERT(VARCHAR(20),@PEndDate, 101) + ''')
	'

	IF(@RAPS = 'ALL' AND @FIDString = 'ALL')
	BEGIN

		EXEC (@RptSQL)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString = 'ALL')
	BEGIN
		
		SET @RptSQL = @RptSQL + '	AND 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%'''
		
		EXEC (@RptSQL)
		
	END
	
	IF(@RAPS = 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL = @RptSQL + '	AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@RptSQL)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL = @RptSQL + '	AND 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%'''
	+ '	
		AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@RptSQL)
		
	END

END

-- When parameter selected is 'D'

IF (@ROutput = 'D')
BEGIN

	DECLARE	@RptSQL_DParam VARCHAR(7000)

	SET @RptSQL_DParam = 
	'
		SELECT
			 PaymentYear
			,ModelYear
			,COUNT(DISTINCT PaymentStartDate) AS MemberMonths
			,ProcessedByStartDate
			,ProcessedByEndDate
			,ProcessedByFlag
			,EncounterSource
			,PlanID
			,HICN
			,RAFactorType
			,RxHCC
			,HCCDescription
			,RxHCCFactor
			,HierarchyRxHCC
			,HierarchyRxHCCFactor
			,PreAdjustedFactor
			,AdjustedFinalFactor
			,HCCProcessedPCN
			,HierarchyHCCProcessedPCN
			,UniqueConditions
			,MonthsInDCP
			,BidAmount
			,ISNULL(SUM(EstimatedValue), 0) AS EstimatedValue
			,RollForwardMonths
			,ISNULL(SUM(EstimatedValue) + (RollForwardMonths) * (SUM(EstimatedValue) / COUNT(DISTINCT Paymentstartdate)), 0) AS AnnualizedEstimatedValue
			,PBP
			,SCC
			,ProcessedPriorityProcessedByDate
			,ProcessedPriorityThruDate
			,ProcessedPriorityDiag
			,ProcessedPriorityFileID
			,ProcessedPriorityRAC
			,ProcessedPriorityRAPSSourceID
			,DOSPriorityProcessedByDate
			,DOSPriorityThruDate
			,DOSPriorityPCN
			,DOSPriorityDiag
			,DOSPriorityFileID
			,DOSPriorityRAC
			,DOSPriorityRAPSSourceID
			,ProcessedPriorityICN
			,ProcessedPriorityEncounterID
			,ProcessedPriorityReplacementEncounterSwitch
			,ProcessedPriorityClaimID
			,ProcessedPrioritySecondaryClaimID
			,ProcessedPrioritySystemSource
			,ProcessedPriorityRecordID
			,ProcessedPriorityVendorID
			,ProcessedPrioritySubProjectID
			,ProcessedPriorityMatched
			,DOSPriorityICN
			,DOSPriorityEncounterID
			,DOSPriorityReplacementEncounterSwitch
			,DOSPriorityClaimID
			,DOSPrioritySecondaryClaimID
			,DOSPrioritySystemSource
			,DOSPriorityRecordID
			,DOSPriorityVendorID
			,DOSPrioritySubProjectID
			,DOSPriorityMatched
			,ProviderID
			,ProviderLast
			,ProviderFirst
			,ProviderGroup
			,ProviderAddress
			,ProviderCity
			,ProviderState
			,ProviderZip
			,ProviderPhone
			,ProviderFax
			,TaxID
			,NPI
			,SweepDate
			,AgedStatus
			,ProcessedPriorityMAO004ResponseDiagnosisCodeID
			,DOSPriorityMAO004ResponseDiagnosisCodeID
			,ProcessedPriorityMatchedEncounterICN
			,DOSPriorityMatchedEncounterICN
			,''D'' AS ReportOutput
		FROM rev.PartDNewHCCOutputMParameter WITH(NOLOCK)
		WHERE
			PaymentYear = ' + @PYear + '
		AND
			EXISTS (SELECT 1 FROM #TempPID tp WHERE PlanID = tp.Item)
		AND
			(ProcessedPriorityProcessedByDate >= ''' + CONVERT(VARCHAR(20),@PStartDate, 101) + '''
		AND 
			ProcessedPriorityProcessedByDate <= ''' + CONVERT(VARCHAR(20),@PEndDate, 101) + ''')
	'
	DECLARE @DParamGroupBy VARCHAR(7000)
	
	SET @DParamGroupBy = 
	'GROUP BY
			 PaymentYear
			,ModelYear
			,ProcessedByStartDate
			,ProcessedByEndDate
			,ProcessedByFlag
			,EncounterSource
			,PlanID
			,HICN
			,RAFactorType
			,RxHCC
			,HCCDescription
			,RxHCCFactor
			,HierarchyRxHCC
			,HierarchyRxHCCFactor
			,PreAdjustedFactor
			,AdjustedFinalFactor
			,HCCProcessedPCN
			,HierarchyHCCProcessedPCN
			,UniqueConditions
			,MonthsInDCP
			,BidAmount
			,RollForwardMonths
			,PBP
			,SCC
			,ProcessedPriorityProcessedByDate
			,ProcessedPriorityThruDate
			,ProcessedPriorityDiag
			,ProcessedPriorityFileID
			,ProcessedPriorityRAC
			,ProcessedPriorityRAPSSourceID
			,DOSPriorityProcessedByDate
			,DOSPriorityThruDate
			,DOSPriorityPCN
			,DOSPriorityDiag
			,DOSPriorityFileID
			,DOSPriorityRAC
			,DOSPriorityRAPSSourceID
			,ProcessedPriorityICN
			,ProcessedPriorityEncounterID
			,ProcessedPriorityReplacementEncounterSwitch
			,ProcessedPriorityClaimID
			,ProcessedPrioritySecondaryClaimID
			,ProcessedPrioritySystemSource
			,ProcessedPriorityRecordID
			,ProcessedPriorityVendorID
			,ProcessedPrioritySubProjectID
			,ProcessedPriorityMatched
			,DOSPriorityICN
			,DOSPriorityEncounterID
			,DOSPriorityReplacementEncounterSwitch
			,DOSPriorityClaimID
			,DOSPrioritySecondaryClaimID
			,DOSPrioritySystemSource
			,DOSPriorityRecordID
			,DOSPriorityVendorID
			,DOSPrioritySubProjectID
			,DOSPriorityMatched
			,ProviderID
			,ProviderLast
			,ProviderFirst
			,ProviderGroup
			,ProviderAddress
			,ProviderCity
			,ProviderState
			,ProviderZip
			,ProviderPhone
			,ProviderFax
			,TaxID
			,NPI
			,SweepDate
			,AgedStatus
			,ProcessedPriorityMAO004ResponseDiagnosisCodeID
			,DOSPriorityMAO004ResponseDiagnosisCodeID
			,ProcessedPriorityMatchedEncounterICN
			,DOSPriorityMatchedEncounterICN
	'
	
	IF(@RAPS = 'ALL' AND @FIDString = 'ALL')
	BEGIN
		
		EXEC (@RptSQL_DParam + @DParamGroupBy)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString = 'ALL')
	BEGIN
	
		SET @RptSQL_DParam = @RptSQL_DParam + '	AND 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%'''
		
		EXEC (@RptSQL_DParam + @DParamGroupBy)
		
	END
	
	IF(@RAPS = 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL_DParam = @RptSQL_DParam + '	AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@RptSQL_DParam + @DParamGroupBy)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL_DParam = @RptSQL_DParam + '	AND 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%''' 
	+ '	
		AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@RptSQL_DParam + @DParamGroupBy)
		
	END
	
END /* This END is for "IF (@ROutput = 'D') BEGIN" */

END /* This END is for "IF (@ViewThrough = 1) BEGIN" */

END