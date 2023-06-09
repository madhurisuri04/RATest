/*******************************************************************************************************************************
* Name			:	rpt.PartCNewHCCRAPSEDSReconciliation
* Type 			:	Stored Procedure          
* Author       	:	Rakshit Lall
* TFS#          :   73973
* Date          :	11/2/2018
* Version		:	1.0
* Project		:	SP for generating the output of PartCNewHCCRAPSEDSReconciliation table
* SP call		:	rpt.PartCNewHCCRAPSEDSReconciliation 2018, 'H1099', 'InBothRAPSAndEDS, InRAPSButNotInEDS, InEDSButNotInRAPS', 1
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
*********************************************************************************************************************************/

CREATE PROCEDURE rpt.PartCNewHCCRAPSEDSReconciliation
	@PaymentYear INT,
	@PlanID VARCHAR(200),
	@HCCStatus VARCHAR(150),
	@ViewThrough INT
AS
BEGIN

SET NOCOUNT ON

IF (@ViewThrough = 1)
BEGIN

DECLARE
	@PYear INT = @PaymentYear,
	@PID VARCHAR(200) = @PlanID,
	@Status VARCHAR(150) = @HCCStatus	

IF OBJECT_ID('TempDB..#TempPID') IS NOT NULL
DROP TABLE #TempPID

IF OBJECT_ID('TempDB..#HCCStatus') IS NOT NULL
DROP TABLE #HCCStatus

/* Fetch plans from the SSRS report and split them by commas */

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

/* Fetch HCC status selection from the SSRS report and split them by commas */

CREATE TABLE #HCCStatus
	(
		Item VARCHAR(200)
	)

INSERT INTO #HCCStatus
	(
		Item
	)
SELECT Item 
FROM dbo.fnsplit(@Status, ',')

/* Select for the final outout */
	
SELECT
	  PaymentYear
	, HICN
	, HCC
	, CASE 
		WHEN HCCStatus = 'InBothRAPSAndEDS'
		THEN 'In Both RAPS And EDS'
		WHEN HCCStatus = 'InRAPSButNotInEDS'
		THEN 'In RAPS But Not In EDS'
		WHEN HCCStatus = 'InEDSButNotInRAPS'
		THEN 'In EDS But Not In RAPS'
	  ELSE HCCStatus
	  END AS HCCStatus
	, PlanID
	, RAPSPatientControlNumber
	, ProcessedByDate
	, ThruDate
	, DiagnosisCode
	, RAPSFileID
	, EDSICN
	, EDSEncounterID
	, EDSClaimID
	, EDSRecordID
	, EDSVendorID
	, EncounterSource
	, EncounterType
	, EncounterStatus
	, ICN
	, MAO004AllowedStatus
	, MAO004ServiceStartDate
	, MAO004ServiceEndDate
FROM rev.PartCNewHCCRAPSEDSReconciliation WITH(NOLOCK)
WHERE
	PaymentYear = @PYear
AND 
	EXISTS (SELECT 1 FROM #TempPID TP WHERE PlanID = TP.Item)
AND
	EXISTS (SELECT 1 FROM #HCCStatus HS WHERE HCCStatus = HS.Item)
GROUP BY
	  PaymentYear
	, HICN
	, HCC
	, HCCStatus
	, PlanID
	, RAPSPatientControlNumber
	, ProcessedByDate
	, ThruDate
	, DiagnosisCode
	, RAPSFileID
	, EDSICN
	, EDSEncounterID
	, EDSClaimID
	, EDSRecordID
	, EDSVendorID
	, EncounterSource
	, EncounterType
	, EncounterStatus
	, ICN
	, MAO004AllowedStatus
	, MAO004ServiceStartDate
	, MAO004ServiceEndDate	

END

END