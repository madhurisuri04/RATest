/**********************************************************************************************     
* Name          :   dbo.ExtractPartDNewHCCEDSAndRAPS
* Type          :   Stored Procedure
* Author        :   Rakshit Lall                      
* Date          :   04/11/2018
* Ticket        :   70510
* Version       :	1.0                           
* Description   :   Extract proc for Part D EDS And RAPS New HCC Report
* SP Call       :   EXEC dbo.ExtractPartDNewHCCEDSAndRAPS 14

* Version History :
* Author				Date		Version#    TFS Ticket#		Description
* -----------------		----------  --------    -----------		------------
* Rakshit Lall			4/12/2018	1.1			70510			Added and used etl table for D Parameter
***********************************************************************************************/  
CREATE PROCEDURE dbo.ExtractPartDNewHCCEDSAndRAPS
    (
		@ExtractRequestID BIGINT
    )
    
AS
BEGIN
 
SET NOCOUNT ON

DECLARE
		@PYear VARCHAR(4),
		@PStartDate VARCHAR(20),
		@PEndDate VARCHAR(20),
		@PID VARCHAR(200),
		@ROutput CHAR(1),
		@RAPS VARCHAR(50),
		@FIDString VARCHAR(50),
		@UID VARCHAR(50)
		      
SELECT
		@PYear = PaymentYear,
		@PStartDate = ProcessByStart,
		@PEndDate = ProcessByEnd,
		@PID = PlanID,
		@ROutput = ReportOutputByMonth,
		@RAPS = RAPSStringAll,
		@FIDString = FileStringAll,
		@UID = UserID           
		FROM 
            (
                  SELECT 
                        ParameterName,
                        ParameterValue
                  FROM dbo.ExtractRequestParameter
                  WHERE 
                        ExtractRequestID = @ExtractRequestID
            ) a
      PIVOT(MAX(ParameterValue) FOR ParameterName IN ([PaymentYear], [ProcessByStart], [ProcessByEnd], [PlanID], [ReportOutputByMonth], [RAPSStringAll], [FileStringAll], [UserID])) AS VALUE

DECLARE @TempPID TABLE
	(
		Item VARCHAR(200)
	)

INSERT INTO @TempPID
	(
		Item
	)
SELECT Item 
FROM dbo.fnsplit(@PID, ',')

/* When parameter selected is 'M' */
	
IF (@ROutput = 'M')
BEGIN

	DECLARE @RptHeader VARCHAR(8000)

	SET @RptHeader = 
	'SELECT
		''PaymentYear'' AS PaymentYear,
		''ModelYear'' AS ModelYear,
		''PaymentStartDate'' AS PaymentStartDate,
		''ProcessedByStartDate'' AS ProcessedByStartDate,
		''ProcessedByEndDate'' AS ProcessedByEndDate,
		''ProcessedByFlag'' AS ProcessedByFlag,
		''EncounterSource'' AS EncounterSource,
		''PlanID'' AS HPlanID,
		''HICN'' AS HICN,
		''RAFactorType'' AS RAFactorType,
		''RxHCC'' AS RxHCC,
		''HCCDescription'' AS HCCDescription,
		''RxHCCFactor'' AS RxHCCFactor,
		''HierarchyRxHCC'' AS HierarchyRxHCC,
		''HierarchyRxHCCFactor'' AS HierarchyRxHCCFactor,
		''PreAdjustedFactor'' AS PreAdjustedFactor,
		''AdjustedFinalFactor'' AS AdjustedFinalFactor,
		''HCCProcessedPCN'' AS HCCProcessedPCN,
		''HierarchyHCCProcessedPCN'' AS HierarchyHCCProcessedPCN,
		''UniqueConditions'' AS UniqueConditions,
		''MonthsInDCP'' AS MonthsInDCP,
		''BidAmount'' AS BidAmount,
		''EstimatedValue'' AS EstimatedValue,
		''RollForwardMonths'' AS RollForwardMonths,		
		''ActiveIndicatorForRollForward'' AS ActiveIndicatorForRollForward,
		''PBP'' AS PBP,
		''SCC'' AS SCC,
		''ProcessedPriorityProcessedByDate'' AS ProcessedPriorityProcessedByDate,
		''ProcessedPriorityThruDate'' AS ProcessedPriorityThruDate,
		''ProcessedPriorityDiag'' AS ProcessedPriorityDiag,
		''ProcessedPriorityFileID'' AS ProcessedPriorityFileID,
		''ProcessedPriorityRAC'' AS ProcessedPriorityRAC,
		''ProcessedPriorityRAPSSourceID'' AS ProcessedPriorityRAPSSourceID,
		''DOSPriorityProcessedByDate'' AS DOSPriorityProcessedByDate,
		''DOSPriorityThruDate'' AS DOSPriorityThruDate,
		''DOSPriorityPCN'' AS DOSPriorityPCN,
		''DOSPriorityDiag'' AS DOSPriorityDiag,
		''DOSPriorityFileID'' AS DOSPriorityFileID,
		''DOSPriorityRAC'' AS DOSPriorityRAC,
		''DOSPriorityRAPSSourceID'' AS DOSPriorityRAPSSourceID,
		''ProcessedPriorityICN'' AS ProcessedPriorityICN,
		''ProcessedPriorityEncounterID'' AS ProcessedPriorityEncounterID,
		''ProcessedPriorityReplacementEncounterSwitch'' AS ProcessedPriorityReplacementEncounterSwitch,
		''ProcessedPriorityClaimID'' AS ProcessedPriorityClaimID,
		''ProcessedPrioritySecondaryClaimID'' AS ProcessedPrioritySecondaryClaimID,
		''ProcessedPrioritySystemSource'' AS ProcessedPrioritySystemSource,
		''ProcessedPriorityRecordID'' AS ProcessedPriorityRecordID,
		''ProcessedPriorityVendorID'' AS ProcessedPriorityVendorID,
		''ProcessedPrioritySubProjectID'' AS ProcessedPrioritySubProjectID,
		''ProcessedPriorityMatched'' AS ProcessedPriorityMatched,
		''DOSPriorityICN'' AS DOSPriorityICN,
		''DOSPriorityEncounterID'' AS DOSPriorityEncounterID,
		''DOSPriorityReplacementEncounterSwitch'' AS DOSPriorityReplacementEncounterSwitch,
		''DOSPriorityClaimID'' AS DOSPriorityClaimID,
		''DOSPrioritySecondaryClaimID'' AS DOSPrioritySecondaryClaimID,
		''DOSPrioritySystemSource'' AS DOSPrioritySystemSource,
		''DOSPriorityRecordID'' AS DOSPriorityRecordID,
		''DOSPriorityVendorID'' AS DOSPriorityVendorID,
		''DOSPrioritySubProjectID'' AS DOSPrioritySubProjectID,
		''DOSPriorityMatched'' AS DOSPriorityMatched,		
		''ProviderID'' AS ProviderID,
		''ProviderLast'' AS ProviderLast,
		''ProviderFirst'' AS ProviderFirst,
		''ProviderGroup'' AS ProviderGroup,
		''ProviderAddress'' AS ProviderAddress,
		''ProviderCity'' AS ProviderCity,
		''ProviderState'' AS ProviderState,
		''ProviderZip'' AS ProviderZip,
		''ProviderPhone'' AS ProviderPhone,
		''ProviderFax'' AS ProviderFax,
		''TaxID'' AS TaxID,
		''NPI'' AS NPI,
		''SweepDate'' AS SweepDate,
		''AgedStatus'' AS AgedStatus,
		''ProcessedPriorityMAO004ResponseDiagnosisCodeID'' AS ProcessedPriorityMAO004ResponseDiagnosisCodeID,
		''DOSPriorityMAO004ResponseDiagnosisCodeID'' AS DOSPriorityMAO004ResponseDiagnosisCodeID,
		''ProcessedPriorityMatchedEncounterICN'' AS ProcessedPriorityMatchedEncounterICN,
		''DOSPriorityMatchedEncounterICN'' AS DOSPriorityMatchedEncounterICN,
		''ReportOutput'' AS ReportOutput
	'

	DECLARE	@RptSQL VARCHAR(8000)

	SET @RptSQL = 
	'UNION ALL 
	SELECT
         CONVERT(VARCHAR(4), PaymentYear) AS PaymentYear
		,CONVERT(VARCHAR(4), ModelYear) AS ModelYear
		,CONVERT(VARCHAR(20), PaymentStartDate) AS PaymentStartDate
		,CONVERT(VARCHAR(20), ProcessedByStartDate) AS ProcessedByStartDate
		,CONVERT(VARCHAR(20), ProcessedByEndDate) AS ProcessedByEndDate
		,ProcessedByFlag
		,EncounterSource
		,PlanID
		,HICN
		,RAFactorType
		,RxHCC
		,REPLACE(HCCDescription, '','', '''') AS HCCDescription
		,CONVERT(VARCHAR(30), RxHCCFactor) AS RxHCCFactor
		,HierarchyRxHCC
		,CONVERT(VARCHAR(30), HierarchyRxHCCFactor) AS HierarchyRxHCCFactor
		,CONVERT(VARCHAR(30), PreAdjustedFactor) AS PreAdjustedFactor
		,CONVERT(VARCHAR(30), AdjustedFinalFactor) AS AdjustedFinalFactor
		,HCCProcessedPCN
		,HierarchyHCCProcessedPCN
		,CONVERT(VARCHAR(30), UniqueConditions) AS UniqueConditions
		,CONVERT(VARCHAR(30), MonthsInDCP) AS MonthsInDCP
		,CONVERT(VARCHAR(20), BidAmount) AS BidAmount
		,CONVERT(VARCHAR(20), EstimatedValue) AS EstimatedValue
		,CONVERT(VARCHAR(10), RollForwardMonths) AS RollForwardMonths
		,ActiveIndicatorForRollForward
		,PBP
		,SCC
		,CONVERT(VARCHAR(20), ProcessedPriorityProcessedByDate) AS ProcessedPriorityProcessedByDate
		,CONVERT(VARCHAR(20), ProcessedPriorityThruDate) AS ProcessedPriorityThruDate
		,ProcessedPriorityDiag
		,ProcessedPriorityFileID
		,ProcessedPriorityRAC
		,ProcessedPriorityRAPSSourceID
		,CONVERT(VARCHAR(20), DOSPriorityProcessedByDate) AS DOSPriorityProcessedByDate
		,CONVERT(VARCHAR(20), DOSPriorityThruDate) AS DOSPriorityThruDate
		,DOSPriorityPCN
		,DOSPriorityDiag
		,DOSPriorityFileID
		,DOSPriorityRAC
		,DOSPriorityRAPSSourceID
		,CONVERT(VARCHAR(20), ProcessedPriorityICN) AS ProcessedPriorityICN
		,CONVERT(VARCHAR(20), ProcessedPriorityEncounterID) AS ProcessedPriorityEncounterID
		,ProcessedPriorityReplacementEncounterSwitch
		,ProcessedPriorityClaimID
		,ProcessedPrioritySecondaryClaimID
		,ProcessedPrioritySystemSource
		,ProcessedPriorityRecordID
		,ProcessedPriorityVendorID
		,CONVERT(VARCHAR(20), ProcessedPrioritySubProjectID) AS ProcessedPrioritySubProjectID
		,ProcessedPriorityMatched
		,CONVERT(VARCHAR(20), DOSPriorityICN) AS DOSPriorityICN
		,CONVERT(VARCHAR(20), DOSPriorityEncounterID) AS DOSPriorityEncounterID
		,DOSPriorityReplacementEncounterSwitch
		,DOSPriorityClaimID
		,DOSPrioritySecondaryClaimID
		,DOSPrioritySystemSource
		,DOSPriorityRecordID
		,DOSPriorityVendorID
		,CONVERT(VARCHAR(20), DOSPrioritySubProjectID) AS DOSPrioritySubProjectID
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
		,CONVERT(VARCHAR(20), SweepDate) AS SweepDate
		,AgedStatus
		,CONVERT(VARCHAR(20), ProcessedPriorityMAO004ResponseDiagnosisCodeID) AS ProcessedPriorityMAO004ResponseDiagnosisCodeID
		,CONVERT(VARCHAR(20), DOSPriorityMAO004ResponseDiagnosisCodeID) AS DOSPriorityMAO004ResponseDiagnosisCodeID
		,CONVERT(VARCHAR(20), ProcessedPriorityMatchedEncounterICN) AS ProcessedPriorityMatchedEncounterICN
		,CONVERT(VARCHAR(20), DOSPriorityMatchedEncounterICN) AS DOSPriorityMatchedEncounterICN
		,''M'' AS ReportOutput
	FROM rev.PartDNewHCCOutputMParameter WITH(NOLOCK)
	WHERE
		PaymentYear = ' + @PYear + '
	AND
		(PlanID IN (SELECT Item FROM dbo.fnsplit( '''  + @PID + ''' , '','')))
	AND
		(ProcessedPriorityProcessedByDate >= ''' + CONVERT(VARCHAR(20),@PStartDate, 101) + '''
	AND 
		ProcessedPriorityProcessedByDate <= ''' + CONVERT(VARCHAR(20),@PEndDate, 101) + ''')'

	IF(@RAPS = 'ALL' AND @FIDString = 'ALL')
	BEGIN
	
	--PRINT (@RptHeader + @RptSQL)
	EXEC (@RptHeader + @RptSQL)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString = 'ALL')
	BEGIN
		
		SET @RptSQL = @RptSQL + '	AND 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%'''
		
		EXEC (@RptHeader + @RptSQL)
		
	END
	
	IF(@RAPS = 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL = @RptSQL + '	AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@RptHeader + @RptSQL)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString <> 'ALL')
	BEGIN
		
		SET @RptSQL = @RptSQL + '	AND 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%'''
	+ '	
		AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@RptHeader + @RptSQL)
		
	END

END

/* When parameter selected is 'D' */

IF (@ROutput = 'D')
BEGIN

	TRUNCATE TABLE etl.PartDNewHCCOutputDParameter

	INSERT INTO etl.PartDNewHCCOutputDParameter
	(
		 [PaymentYear]
		,[ModelYear]
		,[MemberMonths]
		,[ProcessedByStartDate]
		,[ProcessedByEndDate]
		,[ProcessedByFlag]
		,[EncounterSource]
		,[PlanID]
		,[HICN]
		,[RAFactorType]
		,[RxHCC]
		,[HCCDescription]
		,[RxHCCFactor]
		,[HierarchyRxHCC]
		,[HierarchyRxHCCFactor]
		,[PreAdjustedFactor]
		,[AdjustedFinalFactor]
		,[HCCProcessedPCN]
		,[HierarchyHCCProcessedPCN]
		,[UniqueConditions]
		,[MonthsInDCP]
		,[BidAmount]
		,[EstimatedValue]
		,[RollForwardMonths]
		,[AnnualizedEstimatedValue]
		,[PBP]
		,[SCC]
		,[ProcessedPriorityProcessedByDate]
		,[ProcessedPriorityThruDate]
		,[ProcessedPriorityDiag]
		,[ProcessedPriorityFileID]
		,[ProcessedPriorityRAC]
		,[ProcessedPriorityRAPSSourceID]
		,[DOSPriorityProcessedByDate]
		,[DOSPriorityThruDate]
		,[DOSPriorityPCN]
		,[DOSPriorityDiag]
		,[DOSPriorityFileID]
		,[DOSPriorityRAC]
		,[DOSPriorityRAPSSourceID]
		,[ProcessedPriorityICN]
		,[ProcessedPriorityEncounterID]
		,[ProcessedPriorityReplacementEncounterSwitch]
		,[ProcessedPriorityClaimID]
		,[ProcessedPrioritySecondaryClaimID]
		,[ProcessedPrioritySystemSource]
		,[ProcessedPriorityRecordID]
		,[ProcessedPriorityVendorID]
		,[ProcessedPrioritySubProjectID]
		,[ProcessedPriorityMatched]
		,[DOSPriorityICN]
		,[DOSPriorityEncounterID]
		,[DOSPriorityReplacementEncounterSwitch]
		,[DOSPriorityClaimID]
		,[DOSPrioritySecondaryClaimID]
		,[DOSPrioritySystemSource]
		,[DOSPriorityRecordID]
		,[DOSPriorityVendorID]
		,[DOSPrioritySubProjectID]
		,[DOSPriorityMatched]
		,[ProviderID]
		,[ProviderLast]
		,[ProviderFirst]
		,[ProviderGroup]
		,[ProviderAddress]
		,[ProviderCity]
		,[ProviderState]
		,[ProviderZip]
		,[ProviderPhone]
		,[ProviderFax]
		,[TaxID]
		,[NPI]
		,[SweepDate]
		,[AgedStatus]
		,[ProcessedPriorityMAO004ResponseDiagnosisCodeID]
		,[DOSPriorityMAO004ResponseDiagnosisCodeID]
		,[ProcessedPriorityMatchedEncounterICN]
		,[DOSPriorityMatchedEncounterICN]
		,[ReportOutput]
		,[UserID]
		,[LoadDate]
	)
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
		,REPLACE(HCCDescription, ',', '') AS HCCDescription
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
		,'D' AS ReportOutput
		,SYSTEM_USER AS UserID
		,GETDATE() AS LoadDate
	FROM rev.PartDNewHCCOutputMParameter WITH(NOLOCK)
	WHERE
		PaymentYear = @PYear
	AND
		EXISTS (SELECT 1 FROM @TempPID tp WHERE PlanID = tp.Item)
	AND
		(
		ProcessedPriorityProcessedByDate >= @PStartDate
		AND 
		ProcessedPriorityProcessedByDate <= @PEndDate
		)
	GROUP BY
		 [PaymentYear]
		,[ModelYear]
		,[ProcessedByStartDate]
		,[ProcessedByEndDate]
		,[ProcessedByFlag]
		,[EncounterSource]
		,[PlanID]
		,[HICN]
		,[RAFactorType]
		,[RxHCC]
		,[HCCDescription]
		,[RxHCCFactor]
		,[HierarchyRxHCC]
		,[HierarchyRxHCCFactor]
		,[PreAdjustedFactor]
		,[AdjustedFinalFactor]
		,[HCCProcessedPCN]
		,[HierarchyHCCProcessedPCN]
		,[UniqueConditions]
		,[MonthsInDCP]
		,[BidAmount]
		,[RollForwardMonths]
		,[PBP]
		,[SCC]
		,[ProcessedPriorityProcessedByDate]
		,[ProcessedPriorityThruDate]
		,[ProcessedPriorityDiag]
		,[ProcessedPriorityFileID]
		,[ProcessedPriorityRAC]
		,[ProcessedPriorityRAPSSourceID]
		,[DOSPriorityProcessedByDate]
		,[DOSPriorityThruDate]
		,[DOSPriorityPCN]
		,[DOSPriorityDiag]
		,[DOSPriorityFileID]
		,[DOSPriorityRAC]
		,[DOSPriorityRAPSSourceID]
		,[ProcessedPriorityICN]
		,[ProcessedPriorityEncounterID]
		,[ProcessedPriorityReplacementEncounterSwitch]
		,[ProcessedPriorityClaimID]
		,[ProcessedPrioritySecondaryClaimID]
		,[ProcessedPrioritySystemSource]
		,[ProcessedPriorityRecordID]
		,[ProcessedPriorityVendorID]
		,[ProcessedPrioritySubProjectID]
		,[ProcessedPriorityMatched]
		,[DOSPriorityICN]
		,[DOSPriorityEncounterID]
		,[DOSPriorityReplacementEncounterSwitch]
		,[DOSPriorityClaimID]
		,[DOSPrioritySecondaryClaimID]
		,[DOSPrioritySystemSource]
		,[DOSPriorityRecordID]
		,[DOSPriorityVendorID]
		,[DOSPrioritySubProjectID]
		,[DOSPriorityMatched]
		,[ProviderID]
		,[ProviderLast]
		,[ProviderFirst]
		,[ProviderGroup]
		,[ProviderAddress]
		,[ProviderCity]
		,[ProviderState]
		,[ProviderZip]
		,[ProviderPhone]
		,[ProviderFax]
		,[TaxID]
		,[NPI]
		,[SweepDate]
		,[AgedStatus]
		,[ProcessedPriorityMAO004ResponseDiagnosisCodeID]
		,[DOSPriorityMAO004ResponseDiagnosisCodeID]
		,[ProcessedPriorityMatchedEncounterICN]
		,[DOSPriorityMatchedEncounterICN]

	DECLARE	@DRptHeader VARCHAR(MAX)

	SET @DRptHeader = 
	'SELECT
		''PaymentYear'' AS PaymentYear,
		''ModelYear'' AS ModelYear,
		''MemberMonths'' AS MemberMonths,
		''ProcessedByStartDate'' AS ProcessedByStartDate,
		''ProcessedByEndDate'' AS ProcessedByEndDate,
		''ProcessedByFlag'' AS ProcessedByFlag,
		''EncounterSource'' AS EncounterSource,
		''PlanID'' AS HPlanID,
		''HICN'' AS HICN,
		''RAFactorType'' AS RAFactorType,
		''RxHCC'' AS RxHCC,
		''HCCDescription'' AS HCCDescription,
		''RxHCCFactor'' AS RxHCCFactor,
		''HierarchyRxHCC'' AS HierarchyRxHCC,
		''HierarchyRxHCCFactor'' AS HierarchyRxHCCFactor,
		''PreAdjustedFactor'' AS PreAdjustedFactor,
		''AdjustedFinalFactor'' AS AdjustedFinalFactor,
		''HCCProcessedPCN'' AS HCCProcessedPCN,
		''HierarchyHCCProcessedPCN'' AS HierarchyHCCProcessedPCN,
		''UniqueConditions'' AS UniqueConditions,
		''MonthsInDCP'' AS MonthsInDCP,
		''BidAmount'' AS BidAmount,
		''EstimatedValue'' AS EstimatedValue,
		''RollForwardMonths'' AS RollForwardMonths,		
		''AnnualizedEstimatedValue'' AS AnnualizedEstimatedValue,
		''PBP'' AS PBP,
		''SCC'' AS SCC,
		''ProcessedPriorityProcessedByDate'' AS ProcessedPriorityProcessedByDate,
		''ProcessedPriorityThruDate'' AS ProcessedPriorityThruDate,
		''ProcessedPriorityDiag'' AS ProcessedPriorityDiag,
		''ProcessedPriorityFileID'' AS ProcessedPriorityFileID,
		''ProcessedPriorityRAC'' AS ProcessedPriorityRAC,
		''ProcessedPriorityRAPSSourceID'' AS ProcessedPriorityRAPSSourceID,
		''DOSPriorityProcessedByDate'' AS DOSPriorityProcessedByDate,
		''DOSPriorityThruDate'' AS DOSPriorityThruDate,
		''DOSPriorityPCN'' AS DOSPriorityPCN,
		''DOSPriorityDiag'' AS DOSPriorityDiag,
		''DOSPriorityFileID'' AS DOSPriorityFileID,
		''DOSPriorityRAC'' AS DOSPriorityRAC,
		''DOSPriorityRAPSSourceID'' AS DOSPriorityRAPSSourceID,
		''ProcessedPriorityICN'' AS ProcessedPriorityICN,
		''ProcessedPriorityEncounterID'' AS ProcessedPriorityEncounterID,
		''ProcessedPriorityReplacementEncounterSwitch'' AS ProcessedPriorityReplacementEncounterSwitch,
		''ProcessedPriorityClaimID'' AS ProcessedPriorityClaimID,
		''ProcessedPrioritySecondaryClaimID'' AS ProcessedPrioritySecondaryClaimID,
		''ProcessedPrioritySystemSource'' AS ProcessedPrioritySystemSource,
		''ProcessedPriorityRecordID'' AS ProcessedPriorityRecordID,
		''ProcessedPriorityVendorID'' AS ProcessedPriorityVendorID,
		''ProcessedPrioritySubProjectID'' AS ProcessedPrioritySubProjectID,
		''ProcessedPriorityMatched'' AS ProcessedPriorityMatched,
		''DOSPriorityICN'' AS DOSPriorityICN,
		''DOSPriorityEncounterID'' AS DOSPriorityEncounterID,
		''DOSPriorityReplacementEncounterSwitch'' AS DOSPriorityReplacementEncounterSwitch,
		''DOSPriorityClaimID'' AS DOSPriorityClaimID,
		''DOSPrioritySecondaryClaimID'' AS DOSPrioritySecondaryClaimID,
		''DOSPrioritySystemSource'' AS DOSPrioritySystemSource,
		''DOSPriorityRecordID'' AS DOSPriorityRecordID,
		''DOSPriorityVendorID'' AS DOSPriorityVendorID,
		''DOSPrioritySubProjectID'' AS DOSPrioritySubProjectID,
		''DOSPriorityMatched'' AS DOSPriorityMatched,		
		''ProviderID'' AS ProviderID,
		''ProviderLast'' AS ProviderLast,
		''ProviderFirst'' AS ProviderFirst,
		''ProviderGroup'' AS ProviderGroup,
		''ProviderAddress'' AS ProviderAddress,
		''ProviderCity'' AS ProviderCity,
		''ProviderState'' AS ProviderState,
		''ProviderZip'' AS ProviderZip,
		''ProviderPhone'' AS ProviderPhone,
		''ProviderFax'' AS ProviderFax,
		''TaxID'' AS TaxID,
		''NPI'' AS NPI,
		''SweepDate'' AS SweepDate,
		''AgedStatus'' AS AgedStatus,
		''ProcessedPriorityMAO004ResponseDiagnosisCodeID'' AS ProcessedPriorityMAO004ResponseDiagnosisCodeID,
		''DOSPriorityMAO004ResponseDiagnosisCodeID'' AS DOSPriorityMAO004ResponseDiagnosisCodeID,
		''ProcessedPriorityMatchedEncounterICN'' AS ProcessedPriorityMatchedEncounterICN,
		''DOSPriorityMatchedEncounterICN'' AS DOSPriorityMatchedEncounterICN,
		''ReportOutput'' AS ReportOutput  
	'

	DECLARE	@RptSQL_DParam VARCHAR(MAX)

	SET @RptSQL_DParam = 
	'UNION ALL 
	SELECT
		 CONVERT(VARCHAR(4), PaymentYear) AS PaymentYear
		,CONVERT(VARCHAR(4), ModelYear) AS ModelYear
		,CONVERT(VARCHAR(20), MemberMonths) AS MemberMonths
		,CONVERT(VARCHAR(20), ProcessedByStartDate) AS ProcessedByStartDate
		,CONVERT(VARCHAR(20), ProcessedByEndDate) AS ProcessedByEndDate
		,ProcessedByFlag
		,EncounterSource
		,PlanID
		,HICN
		,RAFactorType
		,RxHCC
		,HCCDescription
		,CONVERT(VARCHAR(30), RxHCCFactor) AS RxHCCFactor
		,HierarchyRxHCC
		,CONVERT(VARCHAR(30), HierarchyRxHCCFactor) AS HierarchyRxHCCFactor
		,CONVERT(VARCHAR(30), PreAdjustedFactor) AS PreAdjustedFactor
		,CONVERT(VARCHAR(30), AdjustedFinalFactor) AS AdjustedFinalFactor
		,HCCProcessedPCN
		,HierarchyHCCProcessedPCN
		,CONVERT(VARCHAR(30), UniqueConditions) AS UniqueConditions
		,CONVERT(VARCHAR(30), MonthsInDCP) AS MonthsInDCP
		,CONVERT(VARCHAR(20), BidAmount) AS BidAmount
		,CONVERT(VARCHAR(20), EstimatedValue) AS EstimatedValue
		,CONVERT(VARCHAR(10), RollForwardMonths) AS RollForwardMonths
		,CONVERT(VARCHAR(20), AnnualizedEstimatedValue) AS AnnualizedEstimatedValue
		,PBP
		,SCC
		,CONVERT(VARCHAR(20), ProcessedPriorityProcessedByDate) AS ProcessedPriorityProcessedByDate
		,CONVERT(VARCHAR(20), ProcessedPriorityThruDate) AS ProcessedPriorityThruDate
		,ProcessedPriorityDiag
		,ProcessedPriorityFileID
		,ProcessedPriorityRAC
		,ProcessedPriorityRAPSSourceID
		,CONVERT(VARCHAR(20), DOSPriorityProcessedByDate) AS DOSPriorityProcessedByDate
		,CONVERT(VARCHAR(20), DOSPriorityThruDate) AS DOSPriorityThruDate
		,DOSPriorityPCN
		,DOSPriorityDiag
		,DOSPriorityFileID
		,DOSPriorityRAC
		,DOSPriorityRAPSSourceID
		,CONVERT(VARCHAR(20), ProcessedPriorityICN) AS ProcessedPriorityICN
		,CONVERT(VARCHAR(20), ProcessedPriorityEncounterID) AS ProcessedPriorityEncounterID
		,ProcessedPriorityReplacementEncounterSwitch
		,ProcessedPriorityClaimID
		,ProcessedPrioritySecondaryClaimID
		,ProcessedPrioritySystemSource
		,ProcessedPriorityRecordID
		,ProcessedPriorityVendorID
		,CONVERT(VARCHAR(20), ProcessedPrioritySubProjectID) AS ProcessedPrioritySubProjectID
		,ProcessedPriorityMatched
		,CONVERT(VARCHAR(20), DOSPriorityICN) AS DOSPriorityICN
		,CONVERT(VARCHAR(20), DOSPriorityEncounterID) AS DOSPriorityEncounterID
		,DOSPriorityReplacementEncounterSwitch
		,DOSPriorityClaimID
		,DOSPrioritySecondaryClaimID
		,DOSPrioritySystemSource
		,DOSPriorityRecordID
		,DOSPriorityVendorID
		,CONVERT(VARCHAR(20), DOSPrioritySubProjectID) AS DOSPrioritySubProjectID
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
		,CONVERT(VARCHAR(20), SweepDate) AS SweepDate
		,AgedStatus
		,CONVERT(VARCHAR(20), ProcessedPriorityMAO004ResponseDiagnosisCodeID) AS ProcessedPriorityMAO004ResponseDiagnosisCodeID
		,CONVERT(VARCHAR(20), DOSPriorityMAO004ResponseDiagnosisCodeID) AS DOSPriorityMAO004ResponseDiagnosisCodeID
		,CONVERT(VARCHAR(20), ProcessedPriorityMatchedEncounterICN) AS ProcessedPriorityMatchedEncounterICN
		,CONVERT(VARCHAR(20), DOSPriorityMatchedEncounterICN) AS DOSPriorityMatchedEncounterICN
		,ReportOutput
	FROM etl.PartDNewHCCOutputDParameter'

	IF(@RAPS = 'ALL' AND @FIDString = 'ALL')
	BEGIN

		--PRINT (@DRptHeader + @RptSQL_DParam)
		EXEC (@DRptHeader + @RptSQL_DParam)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString = 'ALL')
	BEGIN
	
		SET @RptSQL_DParam = @RptSQL_DParam + '	WHERE 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%'''
		
		EXEC (@DRptHeader + @RptSQL_DParam)
		
	END
	
	IF(@RAPS = 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL_DParam = @RptSQL_DParam + '	WHERE 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@DRptHeader + @RptSQL_DParam)
		
	END
	
	IF(@RAPS <> 'ALL' AND @FIDString <> 'ALL')
	BEGIN
	
		SET @RptSQL_DParam = @RptSQL_DParam + '	WHERE 
			HCCProcessedPCN LIKE ''%' + @RAPS + '%''' 
	+ '	
		AND 
			ProcessedPriorityFileID LIKE ''%' + @FIDString + '%'''
		
		EXEC (@DRptHeader + @RptSQL_DParam)
		
	END
	
END /* This END is for "IF (@ROutput = 'D') BEGIN" */     
 
END