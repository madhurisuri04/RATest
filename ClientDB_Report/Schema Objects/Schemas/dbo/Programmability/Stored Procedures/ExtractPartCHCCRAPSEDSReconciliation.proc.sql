/**********************************************************************************************     
* Name          :   dbo.ExtractPartCHCCRAPSEDSReconciliation
* Type          :   Stored Procedure
* Author        :   Rakshit Lall                      
* Date          :   11/2/2018
* Ticket        :   73973
* Version       :	1.0                           
* Description   :   Extract proc for PartC HCC RAPS And EDS Reconciliation
* SP Call       :   EXEC dbo.ExtractPartCHCCRAPSEDSReconciliation 1

* Version History :
* Author				Date		Version#    TFS Ticket#		Description
* -----------------		----------  --------    -----------		------------
***********************************************************************************************/  
CREATE PROCEDURE dbo.ExtractPartCHCCRAPSEDSReconciliation
    (
		@ExtractRequestID BIGINT
    )
    
AS
BEGIN
 
SET NOCOUNT ON

DECLARE
		@PYear INT,
		@PID VARCHAR(200),
		@Status VARCHAR(150),		
		@UID VARCHAR(50)
		      
SELECT
		@PYear = PaymentYear,
		@PID = PlanID,
		@Status = HCCStatus,
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
      PIVOT(MAX(ParameterValue) FOR ParameterName IN ([PaymentYear], [PlanID], [HCCStatus], [UserID])) AS VALUE

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

DECLARE @HCCStatus TABLE
	(
		Item VARCHAR(200)
	)

INSERT INTO @HCCStatus
	(
		Item
	)
SELECT Item 
FROM dbo.fnsplit(@Status, ',')

SELECT
	  'PaymentYear' AS PaymentYear
	, 'HICN' AS HICN
	, 'HCC' AS HCC
	, 'HCCStatus' AS HCCStatus
	, 'PlanID' AS PlanID
	, 'RAPSPatientControlNumber' AS RAPSPatientControlNumber
	, 'ProcessedByDate' AS ProcessedByDate
	, 'ThruDate' AS ThruDate
	, 'DiagnosisCode' AS DiagnosisCode
	, 'RAPSFileID' AS RAPSFileID
	, 'EDSICN' AS EDSICN
	, 'EDSEncounterID' AS EDSEncounterID
	, 'EDSClaimID' AS EDSClaimID
	, 'EDSRecordID' AS EDSRecordID
	, 'EDSVendorID' AS EDSVendorID
	, 'EncounterSource' AS EncounterSource
	, 'EncounterType' AS EncounterType
	, 'EncounterStatus' AS EncounterStatus
	, 'ICN' AS ICN
	, 'MAO004AllowedStatus' AS MAO004AllowedStatus
	, 'MAO004ServiceStartDate' AS MAO004ServiceStartDate
	, 'MAO004ServiceEndDate' AS MAO004ServiceEndDate

UNION ALL

SELECT DISTINCT
	  CONVERT(VARCHAR(4), PaymentYear) AS PaymentYear
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
	, CONVERT(VARCHAR(20), ProcessedByDate) AS ProcessedByDate
	, CONVERT(VARCHAR(20), ThruDate) AS ThruDate
	, DiagnosisCode
	, RAPSFileID
	, EDSICN
	, CONVERT(VARCHAR(20), EDSEncounterID) AS EDSEncounterID 
	, EDSClaimID
	, EDSRecordID
	, EDSVendorID
	, EncounterSource
	, EncounterType
	, EncounterStatus
	, ICN
	, MAO004AllowedStatus
	, CONVERT(VARCHAR(20), MAO004ServiceStartDate) AS MAO004ServiceStartDate
	, CONVERT(VARCHAR(20), MAO004ServiceEndDate) AS MAO004ServiceEndDate
FROM rev.PartCNewHCCRAPSEDSReconciliation WITH(NOLOCK)
WHERE
	PaymentYear = @PYear
AND 
	EXISTS (SELECT 1 FROM @TempPID TP WHERE PlanID = TP.Item)
AND
	EXISTS (SELECT 1 FROM @HCCStatus HS WHERE HCCStatus = HS.Item)
 
END