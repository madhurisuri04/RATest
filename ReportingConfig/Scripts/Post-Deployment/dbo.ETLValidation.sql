-- =============================================
-- Script Template
-- =============================================

DECLARE @ETLValidation TABLE
(
  ETLValidationID INT NOT NULL,
  DomainCD VARCHAR(10) NULL,
  ValidationDescription VARCHAR(1000) NULL,
  TableName VARCHAR(128) NULL,
  ColumnName VARCHAR(128) NULL,
  TargetStatusID INT NULL,
  GlobalLOBState BIT NOT NULL,
  DisabledDateTime DATETIME2 NOT NULL,
  CreatedDateTime DATETIME2 NULL
);

DELETE FROM dbo.ETLValidation WHERE ETLValidationID = 411; 

INSERT INTO @ETLValidation
 (ETLValidationID,DomainCD,ValidationDescription,TableName,ColumnName,TargetStatusID,GlobalLOBState,DisabledDateTime,CreatedDateTime)
VALUES

--Medical Validations
 (1,'Medical','Professional EncounterServiceLines.ServiceStartDate values need to be valid.','stg.EncounterServiceLines','ServiceStartDate',999,0,'2014-08-01','2014-01-01')
,(2,'Medical','Institutional Outpatient Encounters must have all valid EncounterServiceLines.ServiceDate values if their EH.StatementEndDate and EH.StatementBeginDate values are invalid or not equal AND ESLRC.RevenueCode is not in 250-259.','stg.EncounterServiceLines','ServiceStartDate',999,0,'2014-08-01','2014-01-01')
,(3,'Medical','Each Encounter must have at least one EncounterServiceLine record.','stg.Encounters','ID',999,0,'2014-08-01','2014-01-01')
,(4,'Medical','Each Encounter must have a non-NULL, non-empty-string ClaimID.','stg.Encounters','ClaimID',999,0,'9999-12-31','2014-01-01')
,(5,'Medical','Each Encounter must have a ClaimIndicator of 1,7 or 8.','stg.Encounters','ClaimIndicator',999,0,'9999-12-31','2014-01-01')
,(6,'Medical','The EncounterHeader.PlaceOfService value on Professional Encounters must be valid.','stg.EncounterHeader','PlaceOfService',999,0,'2014-08-01','2014-01-01')
,(7,'Medical','The EncounterHeader.PlaceOfService value on Institutional Encounters must be valid.','stg.EncounterHeader','PlaceOfService',999,0,'2014-08-01','2014-01-01')
,(8,'Medical','Each Encounter must have at least one valid EncounterCOB.DateClaimPaidByOtherPayer or EncounterServiceLineCOB.AdjudicationDate.','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'2013-11-13','2014-01-01')
,(9,'Medical','Encounters with an EncounterHeader.ClaimIndicator of 7 or 8 need to have an EncounterHeader.PayerClaimControlNumber.','stg.EncounterHeader','PayerClaimControlNumber',999,0,'2014-08-01','2014-01-01')
,(10,'Medical','The EncounterMember.Contract must exist in EDSClientDB.ref.ClientContract.ContractNumber.','stg.EncounterMember','Contract',999,0,'2014-08-01','2014-01-01')
,(11,'Medical','The Payer Paid Amount is required and must be numeric.','stg.EncounterCOB','PayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(12,'Medical','EncounterServiceLineCOB.OtherPayerPaidAmount must be numeric.','stg.EncounterServiceLineCOB','OtherPayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(13,'Medical','Each Encounter must have a valid derived Adjudication Date.','stg.ClaimStackDerivedValues','AdjudicatedDate',999,0,'2014-08-01','2014-01-01')
,(14,'Medical','EncounterMember.Contract cannot be NULL or empty string.','stg.EncounterMember','Contract',999,0,'2014-08-01','2014-01-01')
,(15,'Medical','EncounterMember.Contract must be 5 characters long and start with H or h.','stg.EncounterMember','Contract',999,0,'2013-11-13','2014-01-01')
,(16,'Medical','An Encounter can only have two COBs.','stg.EncounterCOB','PayerResponsibilitySequenceNumber',999,0,'2014-08-01','2014-01-01')
,(17,'Medical','No duplicate EncounterCOB.OtherPayerPlanIdentificationNumber values for an Encounter.','stg.EncounterCOB','OtherPayerPlanIdentificationNumber',999,0,'2014-08-01','2014-01-01' )
,(18,'Medical','No duplicate EncounterServiceLineCOB.OtherPayerPrimaryIdentifier values for an EncounterServiceLine.','stg.EncounterServiceLineCOB','OtherPayerPrimaryIdentifier',999,0,'2014-08-01','2014-01-01')
,(19,'Medical','Non-null EncounterServiceLines.PlaceOfService values on Institutional Encounters must be valid.','stg.EncounterServiceLines','PlaceOfService',999,0,'2014-08-01','2014-01-01')
,(20,'Medical','Institutional Encounters must have a valid EncounterHeader.StatementBeginDate.','stg.EncounterHeader','StatementBeginDate',999,0,'2014-08-01','2014-01-01')
,(21,'Medical','Encounters must have a derived ServiceDate that is not less than 4/1/2014.','stg.ClaimStackDerivedValues','ServiceDate',998,0,'2014-08-01','2014-01-01')
,(22,'Medical','Professional Encounters must have a valid EncounterServiceLines.PlaceOfService value.','stg.EncounterServiceLines','PlaceOfService',999,0,'2014-08-01','2014-01-01')
,(23,'Medical','Encounters cannot have both valid and invalid EncounterServiceLineCOB.AdjudicationDate values .','stg.EncounterServiceLineCOB','AdjudicationDate',999,0,'2014-08-01','2014-01-01')
,(24,'Medical','Encounters with a valid EncounterCOB.DateClaimPaidByOtherPayer should not have any dates populated on EncounterServiceLineCOB.AdjudicationDate for the same Payer (ecob.OtherPayerPlanIdentificationNumber = eslcob.OtherPayerPrimaryIdentifier).','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'2014-08-01','2014-01-01')
,(25,'Medical','Encounters with an invalid EncounterCOB.DateClaimPaidByOtherPayer should have any dates populated on every EncounterServiceLineCOB.AdjudicationDate for the same Payer (ecob.OtherPayerPlanIdentificationNumber = eslcob.OtherPayerPrimaryIdentifier).','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'2014-08-01','2014-01-01')
,(26,'Medical','EncounterCOB records with a PayerResponsibilitySequenceNumber of P must have not have a DateClaimPaidByOtherPayer value, and must have at least one corresponding EncounterServiceLineCOB record with valid AdjudicationDate values for that same Payer (ecob.OtherPayerPlanIdentificationNumber = eslcob.OtherPayerPrimaryIdentifier).','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'2014-08-01','2014-01-01')
,(27,'Medical','EncounterCOB records with a PayerResponsibilitySequenceNumber not equal to P must have a valid DateClaimPaidByOtherPayer value and no corresponding EncounterServiceLineCOB records for that same Payer (ecob.OtherPayerPlanIdentificationNumber = eslcob.OtherPayerPrimaryIdentifier).','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'2014-08-01','2014-01-01')
,(28,'Medical','EncounterCOB records with a PayerResponsibilitySequenceNumber of P must have a corresponding EncounterServiceLineCOB records for that same Payer (ecob.OtherPayerPlanIdentificationNumber = eslcob.OtherPayerPrimaryIdentifier).','stg.EncounterCOB','OtherPayerPlanIdentificationNumber',999,0,'2014-08-01','2014-01-01')
,(29,'Medical','Coventry - Encounters must have a stg.Encounters.SecondaryClaimID value that is not NULL or an empty string.  This value should have been added by the Derived Values process.','stg.Encounters','SecondaryClaimID',999,0,'2014-08-01','2014-01-01')
,(30,'Medical','Aetna - The EncounterMember.PlanMemberID field should start with ME.','stg.Encountermember','PlanMemberID',999,0,'2014-08-01','2014-01-01')
,(31,'Medical','All Service Lines Contain Non-Medicare Procedure Codes.','stg.Encounters','ID',999,0,'2014-08-01','2014-01-01')
,(32,'Medical','At least one, but not all Service Lines contain a Non-Medicare Procedure Code.','stg.Encounters','ID',999,0,'2014-08-01','2014-01-01')
,(33,'Medical','The Encounter LOB Plan ID must exist in Client Reference Value Table.','stg.EncounterMember','LOBPlanId',999,0,'2016-02-01','2014-01-01')
,(34,'Medical','The Encounter references a member who currently does not exist in the Verscend System (as provided in the Membership data file from the client).','stg.EncounterMember','PlanMemberID & LOBPlanID & VariantID',999,0,'9999-12-31','2014-01-01')
,(35,'Medical','Each Encounter must have a Variant ID of 00, 01, 02, 03, 04, 05, or 06.','stg.EncounterMember','VariantID',1800,0,'2014-08-01','2014-01-01')
,(36,'Medical','Each Encounter must have a Claim Type Indicator of I or P.','stg.Encounters','ClaimTypeIndicator',999,0,'2014-08-01','2014-01-01')
,(37,'Medical','Each Encounter must have at least 1 valid Diagnosis, the Qualifier is missing or invalid.','stg.EncounterDiagnosis','DiagnosisQualifier',999,0,'2014-08-01','2014-01-01')
,(38,'Medical','Each Encounter must have at least 1 valid Diagnosis, the Diagnosis is missing or invalid.','stg.EncounterDiagnosis','Diagnosis',999,0,'2014-08-01','2014-01-01')
,(39,'Medical','Patient Status Code is required for inpatient claims.','stg.EncounterHeader','PatientStatusCode',1800,0,'2014-08-01','2014-01-01')
,(40,'Medical','Professional EncounterServiceLines.ServiceEndDate values need to be valid.','stg.EncounterServiceLines','serviceEnddate',999,0,'2014-08-01','2014-01-01')
,(41,'Medical','Encounters must have a valid Billing Provider NPI.','stg.EncounterProviders','NPI',1800,0,'2014-08-01','2014-01-01')
,(42,'Medical','Service Claim Line Numbers are required.','stg.EncounterServiceLines','ServiceClaimLineNumber',999,0,'2014-08-01','2014-01-01')
,(43,'Medical','Institutional Encounters must have a valid Revenue Code.','stg.EncounterServiceLineRevenueCodes','RevenueCode',1800,0,'2014-08-01','2014-01-01')
,(44,'Medical','Encounters must have a valid Service ID Qualifier.','stg.EncounterServiceLines','ProductOrServiceIDQualifier',1800,0,'2014-08-01','2014-01-01')
,(45,'Medical','Encounters must have a valid Procedure Code.','stg.EncounterServiceLines','ProcedureCode',1800,0,'2014-08-01','2014-01-01')
,(46,'Medical','Encounters must have a valid Contract Type.','stg.EncounterServiceLines','ContractType',1800,0,'2014-08-01','2014-01-01')
,(47,'Medical','Date Claim Paid must be a date and After the statement Cover To Date for Encounters.','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'2014-08-01','2014-01-01')
,(48,'Medical','Total Amount Paid for the Claim must be >= 0.','stg.EncounterCOB','PayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(49,'Medical','Total Amount Paid must be <= Total Amount allowed.','stg.EncounterCOB','PayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(50,'Medical','Service Line Amount Paid for the Claim must be >= 0. ','stg.EncounterServiceLineCOB','OtherPayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(51,'Medical','Service Line Amount Paid must be <= Service Line Amount allowed.','stg.EncounterServiceLineCOB','OtherPayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(52,'Medical','The Encounter references a member who currently does not exist in the Verscend System.','stg.EncounterMember','PlanMemberID',1800,0,'2014-08-01','2014-01-01')
,(53,'Medical','The Encounter references a patient who currently does not exist in the Verscend System.','stg.EncounterPatient','PatientMemberID',1800,0,'2014-08-01','2014-01-01')
,(54,'Medical','The total paid amount from the claim level does not match the totals from the claim line level.','stg.EncounterCOB','PayerPaidAmount',1800,0,'2014-08-01','2014-01-01')
,(55,'Medical','Institutional Only: Claims must not contain a claim indicator (frequency code) of 2, 3, 4, 5, 6 or 9.','stg.EncounterHeader','ClaimIndicator',999,0,'9999-12-31','2014-01-01')
,(56,'Medical','Claims must contain a valid bill type code','stg.EncounterHeader','PlaceOfService',999,0,'2014-08-01','2014-01-01')
,(57,'Medical','Overlapping Stays are not allowed to be submitted.','stg.ClaimStackDerivedValues','ServiceDate',999,0,'2014-08-01','2014-01-01')
,(58,'Medical','Total Amount Allowed for the Claim must be >= 0.','stg.EncounterHeader','TotalAmountAllowed',1800,0,'2014-08-01','2014-01-01')
,(59,'Medical','Service Line Amount Allowed for the Claim must be >= 0.','stg.EncounterServiceLine','AllowedAmount',1800,0,'2014-08-01','2014-01-01')
,(60,'Medical','Total allowed amount from the claim level does not match the totals from the claim line level.','stg.EncounterHeader','TotalAmountAllowed',1800,0,'2014-08-01','2014-01-01')
,(61,'Medical','The Encounter must have a single matching EncounterCOB for the plan.','stg.EncounterMember','LOBPlanId',999,0,'2014-08-01','2014-01-01')
,(62,'Medical','Each Encounter service line must have a single matching EncounterServiceLineCOB record for the plan.','stg.EncounterMember','LOBPlanId',999,0,'2014-08-01','2014-01-01')
,(63,'Medical','Encounters with a Claim Indicator (frequency code) of 7 or 8 must also contain Payer Claim Control Number (Original Plan Claim ID).','stg.EncounterHeader','PayerClaimControlNumber',999,0,'9999-12-31','2014-01-01')
,(64,'Medical','Institutional claims must contain a valid bill type.','stg.EncounterHeader','PlaceOfService',999,0,'9999-12-31','2014-01-01')
,(65,'Medical','Professional claims must contain a valid place of service.','stg.EncounterHeader','PlaceOfService',999,0,'9999-12-31','2014-01-01')
,(66,'Medical','When Place of Service is provided at the service line, it must be a valid place of service.','stg.EncounterServiceLines','PlaceOfService',999,0,'9999-12-31','2014-01-01')
,(67,'Medical','Each Encounter must have a Claim Type Indicator of I (Institutional) or P (Professional).','stg.Encounters','ClaimTypeIndicator',999,0,'9999-12-31','2014-01-01')
,(68,'Medical','The Encounter must have a single matching coordination of benefits record for the plan.','stg.EncounterMember','LOBPlanID',999,0,'9999-12-31','2014-01-01')
,(69,'Medical','A dependent medical claim must have a valid subscriber.','stg.EncounterPatient','PatientMemberID  & LOBPlanID & VariantID',999,0,'9999-12-31','2014-01-01')
,(70,'Medical','Cannot contain duplicate coordination of benefit payer plan ids within a single encounter.','stg.EncounterCOB','OtherPayerPlanIdentificationNumber',999,0,'9999-12-31','2014-01-01')
,(71,'Medical','Cannot contain duplicate coordination of benefit payer plan ids within a single service line.','stg.EncounterServiceLineCOB','OtherPayerPrimaryIdentifier',999,0,'9999-12-31','2014-01-01')
,(72,'Medical','Each Encounter must have at least one EncounterServiceLine record.','stg.Encounters','ID',999,0,'9999-12-31','2014-01-01')
,(73,'Medical','Each Encounter service line must have a single matching EncounterServiceLineCOB record for the plan.','stg.EncounterMember','LOBPlanId',999,0,'9999-12-31','2014-01-01')
,(74,'Medical','Encounters must have a derived ServiceDate that is not prior to 1/1/2014.','stg.ClaimStackDerivedValues','ServiceDate',999,0,'9999-12-31','2014-01-01')
,(75,'Medical','Cannot submit separate claims for overlapping stays.','stg.EncounterHeader','StatementDate',999,0,'9999-12-31','2014-01-01')
,(76,'Medical','Professional EncounterServiceLines.ServiceStartDate values need to be valid.','stg.EncounterServiceLines','ServiceStartDate',999,0,'9999-12-31','2014-01-01')
,(77,'Medical','Adjudication Date/Claim Processed Date is Required.','stg.ClaimStackDerivedValues','AdjudicatedDate',999,0,'9999-12-31','2014-01-01')
,(78,'Medical','Adjudication Date must be a date type and after the Statement Cover To Date for Institutional Encounters.','stg.EncounterCOB','AdjudicatedDate',999,0,'2015-04-14','2014-01-01')
,(79,'Medical','Each Encounter must have at least one valid EncounterCOB.DateClaimPaidByOtherPayer or EncounterServiceLineCOB.AdjudicationDate','stg.EncounterCOB','DateClaimPaidByOtherPayer',999,0,'9999-12-31','2014-01-01')
,(80,'Medical','Encounters cannot have both valid and invalid EncounterServiceLineCOB.AdjudicationDate values.','stg.EncounterServiceLineCOB','AdjudicationDate',999,0,'9999-12-31','2014-01-01')
,(81,'Medical','Each Encounter must have a non-NULL, non-empty-string Plan Claim ID.','stg.Encounters','ClaimID',999,0,'9999-12-31','2014-01-01')
,(82,'Medical','Each Encounter must have at least 1 valid Diagnosis (the Diagnosis Code is missing or invalid).','stg.EncounterDiagnosis','Diagnosis',999,0,'9999-12-31','2014-01-01')
,(83,'Medical','Each ESL ServiceStartDate must be BETWEEN the EncounterHeader.StatementBeginDate AND EH.StatementEndDate for Institutional claims only.','stg.EncounterServiceLines','ServiceStartDate',999,0,'9999-12-31','2014-01-01')
,(84,'Medical','Each ESL ServiceEndDate must be BETWEEN the EncounterHeader.StatementBeginDate AND EH.StatementEndDate for Institutional claims only.','stg.EncounterServiceLines','ServiceEndDate',999,0,'9999-12-31','2014-01-01')
,(85,'Medical','Each Encounter service line Cannot have a Multiple Revenue Codes.','stg.EncounterServiceLineRevenueCodes','RevenueCode',999,0,'9999-12-31','2014-01-01')
,(86,'Medical','The Medical Claims LOB Plan ID and Variant ID must exist and be active within the Client Reference Value Table which is loaded from the Plan Details file specification.','stg.EncounterMember','LineOfBusinessPlanId & VariantID',999,0,'9999-12-31','2014-01-01')
,(87,'Medical','Medical Claims are required to have at least one diagnosis that is not Admitting or Reason for Visit','stg.EncounterDiagnosis','Diagnosis',999,0,'9999-12-31','2014-01-01')
,(88,'Medical','TotalAllowedCost for the claim header must not be equal to 0','stg.EncounterHeader','TotalAmountAllowed',999,0,'9999-12-31','2014-01-01')
,(89,'Medical','Professional Encounter must have YEAR of ServiceEndDate equal to Processing Year','stg.EncounterServiceLines','ServiceEndDate',999,0,'9999-12-31','2015-08-03')
,(90,'Medical','The medical claims plan and variant must match the members plan and VariantID.','stg.EncounterMember','LOBPlanID & VariantID',999,0,'2016-01-22','2016-01-22')
,(91,'Medical','The claims Date of service must be with in the members coverage dates.','stg.ClaimStackDerivedValues','ServiceDate',999,0,'9999-12-31','2016-01-22')
,(92,'Medical','The Institutional claims date of service must be with in the members coverage dates.','stg.EncounterHeader','StatementBeginDate',999,0,'2016-02-03','2016-01-22')
,(93,'Medical','Institutional Encounter must have YEAR of ServiceEndDate equal either to Processing Year or to Previous Processing Year','stg.EncounterServiceLines','ServiceEndDate',999,0,'9999-12-31','2016-03-25')
,(94,'Medical','Allowed Amount must be greater than or equal to $1.00.','stg.EncounterHeader','TotalAmountAllowed',999,0,'9999-12-31','2016-08-17')
,(95,'Medical','Adjudication Date/Claim Processed Date is Required for Medicaid.','stg.ClaimStackDerivedValues','AdjudicatedDate',999,0,'9999-12-31','2017-01-17')


--Supplemental Validations
,(400,'SPMNTL','Diagnosis Level Edit Error; Non-Fatal for its Encounter.','stg.EncounterDiagnosis','Validated',1800,1,'9999-12-31','2014-01-01')
,(401,'SPMNTL','Each Supplemental record must have at least one valid diagnosis code.','sup.Supplemental_InitialProcessing','SupplementalID',999,1,'9999-12-31','2016-05-25')
,(402,'SPMNTL','Each Supplemental record must have a MemberHICN in the proper format.','sup.Supplemental_InitialProcessing','MemberHICN',999,1,'9999-12-31','2016-05-09')
,(403,'SPMNTL','Each Supplemental record must have a Service Start Date in the proper format.','sup.Supplemental_InitialProcessing','ServiceStartDate',999,1,'9999-12-31','2016-05-24')
,(404,'SPMNTL','Each Supplemental record with a Service End Date must have a properly formatted Service End Date that is greater than or equal to Service Start Date.','sup.Supplemental_InitialProcessing','ServiceEndDate',999,1,'9999-12-31','2016-05-24')
,(405,'SPMNTL','Each Supplemental record must have a valid Supplemental Type Code','sup.Supplemental_InitialProcessing','SupplementalTypeCd',999,1,'9999-12-31','2014-01-01')
,(406,'SPMNTL','Each Supplemental record must have a Claim Indicator of 1 or 8','sup.Supplemental_InitialProcessing','ClaimIndicator',999,1,'9999-12-31','2016-05-09')
,(407,'SPMNTL','Each Supplemental record must have a valid Member Contract.','sup.Supplemental_InitialProcessing','MemberContract',999,1,'9999-12-31','2016-05-09')
,(408,'SPMNTL','Each Supplemental record must have a Supplemental Record ID.','sup.Supplemental_InitialProcessing','RecordID',999,1,'9999-12-31','2016-05-09')
,(409,'SPMNTL','Each encounter must have a valid Rendering Provider NPI.','stg.EncounterProviders','NPI',999,1,'2016-06-06','2014-01-01')
,(410,'SPMNTL','Each Supplemental record must have a Claim Type Indicator of I or P.','sup.Supplemental_InitialProcessing','ClaimTypeIndicator',999,1,'9999-12-31','2016-05-09')
,(411,'SPMNTL','ServiceEndDate must between 1/1/2015 and 2/28/2015','sup.Supplemental_InitialProcessing','ServiceEndDate',999,1,'2016-06-03 15:00:00.0000000','2016-05-05')
,(412,'SPMNTL','Each Supplemental record must have valid PatientCareType ','sup.Supplemental_InitialProcessing','PatientCareType',999,1,'9999-12-31','2016-05-09')
,(413,'SPMNTL','ServiceEndDate year must be equal to the DCP Year and currentDate less than or equal to the Final_Sweep_Date.','sup.Supplemental_InitialProcessing','ServiceEndDate',999,1,'9999-12-31','2016-05-12')
,(414,'SPMNTL','Each Supplemental record must have valid FileCreateDate.','sup.Supplemental_InitialProcessing','FileCreateDate',999,1,'9999-12-31','2016-05-24')
,(415,'SPMNTL','Each Supplemental record must have valid DiagnosisQualifier populated when DiagnosisCode is populated.','sup.SupplementalDiagnosis_InitialProcessing','DiagnosisQualifier',999,1,'9999-12-31','2016-05-24')
,(416,'SPMNTL','Each Supplemental record must have valid ICD9 DiagnosisQualifier.','sup.SupplementalDiagnosis_InitialProcessing','DiagnosisCode',999,1,'9999-12-31','2016-05-25')
,(417,'SPMNTL','Each Supplemental record must have valid ICD10 DiagnosisQualifier.','sup.SupplementalDiagnosis_InitialProcessing','DiagnosisCode',999,1,'9999-12-31','2016-05-25')
,(418,'SPMNTL','Each Supplemental record must have valid DeleteFlag.','sup.SupplementalDiagnosis_InitialProcessing','DeleteFlag',999,1,'9999-12-31','2016-05-26')
,(419,'SPMNTL','Hold Supplemental Dual Contracts Submission.','sup.Supplemental_InitialProcessing','MemberContract',999,1,'9999-12-31','2016-05-26')
,(420,'SPMNTL','Professional - Set DME to 1 if taxonomies code exists else 0. For Institutional - Set DME to 0.','sup.Supplemental_InitialProcessing','DME',999,1,'9999-12-31','2016-06-30')
-- 411 is covered by 403   
--,(411,'SPMNTL','Each encounter must have a Date of Service in the proper format.','stg.EncounterSupplementals','DateOfServiceStart',999,1,'9999-12-31')

--Drug Validations
,(10001,'Drug','The Pharmacy Claim''s LOB Plan ID and Variant ID must exist and be active within the Client Reference Value Table, which is loaded from the Plan Details file specification.','stg.DrugHistoryClaimDetail','LOBPlanID & VariantID',999,1,'9999-12-31','2014-01-01')
,(10002,'Drug','Each Claim must have a Variant ID of 00, 01, 02, 03, 04, 05, or 06.','stg.DrugHistoryMember','VariantID',999,1,'2014-12-16','2014-01-01')
,(10003,'Drug','All Pharmacy Claims are required to have a Transaction Id (Claim Id).','stg.DrugHistoryClaim','TransactionID',999,1,'9999-12-31','2014-01-01')
,(10004,'Drug','The Pharmacy Claims Date of Service must be within the associated member’s coverage dates.','stg.DrugHistoryClaim','DateOfService',999,1,'9999-12-31','2014-01-01')
,(10005,'Drug','The Fill Date must be a valid date prior to the current date, and must be within the current submission year.','stg.DrugHistoryClaim','DateOfService',999,1,'9999-12-31','2014-01-01')
,(10006,'Drug','The Plan Paid Amount is required and must be 0 or greater for Original and Replace claims.','stg.DrugHistoryPricing','NetAmountDue',999,1,'9999-12-31','2014-01-01')
,(10007,'Drug','Total Allowed Cost must be numeric and greater than 0 for Original and Replacement pharmacy claims.','stg.DrugHistoryClaimDetail','TotalAllowedCost',999,1,'9999-12-31','2014-01-01')
,(10008,'Drug','Each Pharmacy Claim must have a Capitation Status of CC (capitated) or FF (fee for service).','stg.DrugHistoryClaim','CapitationStatus',999,1,'9999-12-31','2014-01-01')
,(10009,'Drug','Each Claim must have a valid Adjudication Date between one day prior to the Fill Date (called the Claim Date of Service on the Pharmacy Standard File spec) and the current date.','stg.DrugHistoryClaim','AdjudicationDate ',999,1,'9999-12-31','2014-01-01')
,(10010,'Drug','A Prescription/Service Reference is required for all Claim Records and must be between 7 and 12 characters in length.','stg.DrugHistoryClaim','PrescriptionService Reference Number',999,1,'9999-12-31','2014-01-01')
,(10011,'Drug','Product/Service ID is required for all Claim Records.','stg.DrugHistoryClaim','ProductServiceID',999,1,'9999-12-31','2014-01-01')
,(10012,'Drug','The Product/Service ID must be formatted as a valid NDC number.','stg.DrugHistoryClaim','ProductServiceID',999,1,'9999-12-31','2014-01-01')
,(10013,'Drug','Fill Number is required and must be an integer from 0 to 99.','stg.DrugHistoryClaim','FillNumber',999,1,'9999-12-31','2014-01-01')
,(10014,'Drug','Dispensing Status must be (P, C, or blank).','stg.DrugHistoryClaim','DispensingStatus',999,1,'9999-12-31','2014-01-01')
,(10015,'Drug','The Pharmacy Claim Indicator, called the Record Indicator on the Pharmacy Standard file specification, must be (O, P, or D).','stg.DrugHistoryClaim','DrugClaimIndicator',999,1,'9999-12-31','2014-01-01')
,(10016,'Drug','Each Claim must have a valid Check Date and it must be greater than or equal to the Fill Date and less than or equal to the date of processing.','stg.DrugHistoryClaimDetail','CheckDate',999,1,'9999-12-31','2014-01-01')
,(10017,'Drug','Each Pharmacy Claim must have a Fill Date (called Claim Date of Service on the Pharmacy Standard file specification) greater than or equal to 1/1/2014.','stg.DrugHistoryClaim.','DateOfService',999,1,'2015-08-13','2014-01-01')
,(10018,'Drug', 'The Dispensing Provider Qualifier must be XX for NPI or 99 for other forms of Provider Identification.','stg.DrugHistoryPharmacy','ServiceProviderIDQualifier',999,1,'9999-12-31','2014-01-01')
,(10019,'Drug', 'The Dispensing Provider ID cannot be blank or NULL.','stg.DrugHistoryPharmacy','ServiceProviderID',999,1,'9999-12-31','2014-01-01')
,(10020,'Drug', 'The Dispensing Provider ID must be a valid NPI if the Dispensing Provider Qualifier is XX.','stg.DrugHistoryPharmacy','ServiceProviderID',999,1,'9999-12-31','2014-01-01')
,(10021,'Drug', 'The Claim Sequence Number must either not be populated, or be populated with an integer value. Non-null, Non-integer values are not permitted.','stg.DrugHistoryClaim','ClaimSequenceNumber',999,1,'9999-12-31','2014-01-01')
,(10022,'Drug', 'TotalAllowedCost must not be equal to 0','stg.DrugHistoryClaimDetail','TotalAllowedCost',999,1,'2015-09-30','2014-01-01')
,(10023,'Drug', 'The Pharmacy Claims LOBPlanID and VariantID must be the same as the associated members LOBPlanID and VariantID.','stg.DrugHistoryClaim','LOBPlanID & VariantID',999,1,'9999-12-31','2016-01-22')
       
       
       

--Member Validations
,(20001,'Member','A Member ID is required for all Member Records.','stg.Stage_Membership','PlanMemberID',999,1,'9999-12-31','2014-01-01')
,(20002,'Member','A Date of Birth is required for all Member Records. It must be a valid date prior to the date of submission.','stg.Stage_Membership','DOB',999,1,'9999-12-31','2014-01-01')
,(20003,'Member','The Members Gender is required and must be (F, M, or U).','stg.Stage_Membership','Gender',999,1,'9999-12-31','2014-01-01')
,(20004,'Member','Unknown gender is only allowed when the Enrollment Start Date is less than or equal to 90 days from Date of Birth.','stg.Stage_Membership','Gender',999,1,'9999-12-31','2014-01-01')
,(20005,'Member','The Member LOB Plan ID and Variant ID must be populated and exist in Client Reference Value Table.','stg.Stage_Membership','LineOfBusinessPlanId & VariantID',999,1,'9999-12-31','2014-01-01')
,(20006,'Member','The Enrollment Effective Date must be a valid date.','stg.Stage_Membership','PlanCoverageEffectiveDate',999,1,'9999-12-31','2014-01-01')
,(20007,'Member','The Enrollment Termination Date must be a valid date on or after the Effective Date.','stg.Stage_Membership','PlanCoverageTerminationDate',999,1,'9999-12-31','2014-01-01')
,(20008,'Member','The Enrollment Activity Type is required and must be (I,M,R) if the member is a subscriber.  And the Enrollment Activity Type is required and must be (I,A,R) if the member is a dependent on the subscriber''s policy.','stg.Stage_Membership','EnrollmentActivityTypeCode',999,1,'9999-12-31','2014-01-01')
,(20009,'Member','The monthly Premium Amount must be greater than 0 for Subscribers for enrollment time periods greater than one month. For enrollment time periods less than or equal to one month, the monthly Premium Amount can be 0 or greater.','stg.Stage_Membership','MonthlyPremiumAmount',999,1,'9999-12-31','2014-01-01')
,(20010,'Member','Rating Area must be populated for all membership enrollment records and be 3 characters in length. Disabled as a duplicate of validation 20011.','stg.Stage_Membership','RatingArea',999,1,'2014-12-31','2014-01-01')
,(20011,'Member','The Rating Area must be a 1, 2, or 3 digit number.','stg.Stage_Membership','RatingArea',999,1,'9999-12-31','2014-01-01')
,(20012,'Member','The Subscriber Indicator must be (Y,N, or blank).','stg.Stage_Membership','SubscriberIndicator',999,1,'9999-12-31','2014-01-01')
,(20013,'Member','The Monthly Premium Amount for non-subscribers must be 0.','stg.Stage_Membership','MonthlyPremiumAmount',999,1,'9999-12-31','2014-01-01')
,(20014,'Member','Multiple membership records for the same plan contained overlapping dates.  A member cannot have overlapping coverage dates for the same policy.','stg.Stage_Membership','PlanCoverageEffectiveDate',999,1,'9999-12-31','2014-01-01')
,(20015,'Member','All Non-Subscribers must reference a valid subscriber record using the Subscriber''s Plan Member Id.','stg.Stage_Membership','SubscriberID',999,1,'9999-12-31','2014-01-01')
,(20016,'Member','Non-subscriber enrollment Plan Coverage Effective and Plan Coverage Termination dates must be equal to or between the corresponding subscriber enrollment periods.','stg.Stage_Membership','PlanCoverageTerminationDate',999,1,'9999-12-31','2014-01-01')
,(20017,'Member','If the Non-Subscriber has an Activity Indicator of I (Initial) it must match to a Subscriber''s Initial Enrollment Start Date.','stg.Stage_Membership','EnrollmentActivityTypeCode',999,1,'2015-04-14','2014-01-01')
,(20018,'Member','The Plan Coverage Effective Date of a non-subscriber must match the subscriber or be within an enrollment period of the subscriber.','stg.Stage_Membership','PlanCoverageEffectiveDate',999,1,'2015-04-14','2014-01-01')
,(20019,'Member','The Subscriber has failed validations.  Non-subscriber is being held.','stg.Stage_Membership','SubscriberID',999,1,'9999-12-31','2014-01-01')
,(20020,'Member','If any member record from a set is rejected, all member records are rejected.  This record error is a result of a different record being rejected from the set.','stg.Stage_Membership','PlanMemberID',999,1,'9999-12-31','2014-01-01')
,(20021,'Member','Each subscriber must have at least one activity type code of I (Initial).','stg.Stage_Membership','EnrollmentActivityTypeCode',999,1,'9999-12-31','2014-01-01')
,(20022,'Member','Each non-Initial (A,M,R) enrollment record must have an initial (I) enrollment record for the same Plan ID with a start date prior to the PlanCoverageEffectiveDate of the non-Initial enrollment (A,M,R) record.','stg.Stage_Membership','PlanCoverageEffectiveDate',999,1,'9999-12-31','2014-01-01')
,(20023,'Member','If the Non-Subscriber has an Activity Indicator of R (Renewal) it must match to a Subscriber''s Renewal Enrollment Start Date.','stg.Stage_Membership','EnrollmentActivityTypeCode',999,1,'9999-12-31','2014-01-01')
,(20024,'Member','If a subscriber has an M Record and a dependent record where the dependent''s Termination Date is Greater than the Subscriber''s Change (M) Effective Date, then there must exist at least one dependent record for each dependent where the Effective Date on the Dependent record = Effective Date from the Subscriber''s M record.','stg.Stage_Membership','EnrollmentActivityTypeCode',999,1,'9999-12-31','2014-01-01')
,(20025,'Member','If the Non-Subscriber has an Activity Indicator of M then the Subscriber’s must also be M for the same enrollment period.','stg.Stage_Membership','EnrollmentActivityTypeCode',999,1,'2015-04-14','2014-01-01')
,(20026,'Member','Each Master MemberID must have only one DOB.','stg.Stage_Membership','MasterMemberID',999,1,'9999-12-31','2014-01-01')
,(20027,'Member','Each Master MemberID must have only one gender.','stg.Stage_Membership','MasterMemberID',999,1,'9999-12-31','2014-01-01')
,(20028,'Member','The LOB ID must equal CI or CS or CL','stg.Stage_Membership.','LOB ID',999,1,'9999-12-31','2014-01-01')
,(20029,'Member','No duplicate Members allowed in the member file.','stg.Stage_Membership.','PlanMemberID',999,1,'9999-12-31','2015-10-1')
,(20030,'Member','Master Member ID is required for all enrollees.','stg.Stage_Membership.','MasterMemberID',999,1,'9999-12-31','2015-11-19')
,(20031,'Member','Each Master MemberID must be unique per enrollee.','stg.Stage_Membership.','MasterMemberID',999,1,'9999-12-31','2016-02-01')
,(20032,'Member','Member records cannot have overlapping coverage for a member if it has the same plan ID, variant ID, and Master Member ID.','stg.Stage_Membership','MasterMemberID',999,1,'2016-02-04','2016-02-01')
,(20033,'Member','Member records with same plan ID, variant ID, and Master Member ID cannot be both a dependent and a subscriber for the same plan with the dependent having a same member ID for the subscriber ID.','stg.Stage_Membership.','MasterMemberID',999,1,'2016-02-04','2016-02-01')
,(20034,'Member','The Master Member IDs cannot have the same values for both the dependents with same subscriberIDS.','stg.Stage_Membership','MasterMemberID',999,1,'2016-02-04','2016-02-01')
,(20035,'Member','Dependent member records cannot have overlapping coverage for a member if it has the same plan ID, variant ID, and Master Member ID.','stg.Stage_Membership','MasterMemberID',999,1,'2016-02-04','2016-02-01')
,(20036,'Member','MasterMemberID does not match existing records with same PlanMemberID.','stg.Stage_Membership','MasterMemberID',999,1,'2016-02-01','2015-11-19')
,(20037,'Member','The Members Plan Coverage Effective Date must be within the Plan Details effective dates for the VariantID and LOBPlanID.','stg.Stage_Membership','VariantID & LOBPlanID & PlanCoverageEffectiveDate',999,1,'9999-12-31','2016-02-04')
,(20038,'Member','The Members Plan Coverage Termination Date must be within the Plan Details effective dates for the VariantID and LOBPlanID.','stg.Stage_Membership','VariantID & LOBPlanID & PlanCoverageTerminationDate',999,1,'9999-12-31','2016-02-04')
,(20039,'Member','A plans Coverage Termination date must be no more than 10 years after the Coverage Begin date.','stg.Stage_Membership.','PlanCoverageTerminationDate',999,1,'9999-12-31','2016-07-29')
,(20040,'Member','Each member can only have one PlanMemberID for each enrollment period, for each plan.','stg.Stage_Membership.','PlanMemberID',999,1,'9999-12-31','2016-09-21')
,(20041,'Member','Each PlanMemberID may only tie to one MasterMemberID per plan.','stg.Stage_Membership.','PlanMemberID',999,1,'9999-12-31','2016-11-16')

--HIM Supplemental Validations
,(30001,'HIMSUPCLM','Invalid Format - the Issuer ID field is required and may not be longer than 5 characters','stg.HIMSupplementalMedical','IssuerID',999,1,'9999-12-31','2014-01-01')
,(30002,'HIMSUPCLM','Invalid Format - the LOB Plan ID field is required and may not be longer than 14 characters','stg.HIMSupplementalMedical','LOBPlanID',999,1,'9999-12-31','2014-01-01')
,(30003,'HIMSUPCLM','Invalid Format - the Variant ID field is required and may not be longer than 2 characters','stg.HIMSupplementalMedical','VariantID',999,1,'9999-12-31','2014-01-01')
,(30004,'HIMSUPCLM','Invalid Format - the Patient Member ID field is required and may not be longer than 25 characters','stg.HIMSupplementalMedical','PatientMemberID',999,1,'9999-12-31','2014-01-01')
,(30005,'HIMSUPCLM','Invalid Format - the Record Number field is required and may not be longer than 25 characters','stg.HIMSupplementalMedical','RecordNumber',999,1,'9999-12-31','2014-01-01')
,(30006,'HIMSUPCLM','Invalid Format - the Plan Claim Number field may not be longer than 20 characters','stg.HIMSupplementalMedical','PlanClaimNumber',999,1,'9999-12-31','2014-01-01')
,(30007,'HIMSUPCLM','Invalid Format - the Supplemental Diagnosis Origination Date field is required, may not be longer than 8 characters, and must be able to be converted to a date','stg.HIMSupplementalMedical','SuppDiagOrigDate',999,1,'9999-12-31','2014-01-01')
,(30008,'HIMSUPCLM','Invalid Format - the Supplemental Claim Indicator field is required and may not be longer than 1 character','stg.HIMSupplementalMedical','SuppClaimIndicator',999,1,'9999-12-31','2014-01-01')
,(30009,'HIMSUPCLM','Invalid Format - the Service From Date field is required, may not be longer than 8 characters, and must be able to be converted to a date','stg.HIMSupplementalMedical','ServiceFromDate',999,1,'9999-12-31','2014-01-01')
,(30010,'HIMSUPCLM','Invalid Format - the Service To Date field is required, may not be longer than 8 characters, and must be able to be converted to a date','stg.HIMSupplementalMedical','ServiceToDate',999,1,'9999-12-31','2014-01-01')
,(30011,'HIMSUPDIAG','Invalid Format - the Diagnosis Code Qualifier field is required and may not be longer than 2 characters','stg.HIMSupplementalDiag','DiagCodeQualifier',999,1,'9999-12-31','2014-01-01')
,(30012,'HIMSUPDIAG','Invalid Format - the Diagnosis Code field is required and may not be longer than 8 characters','stg.HIMSupplementalDiag','DiagCode',999,1,'9999-12-31','2014-01-01')
,(30013,'HIMSUPCLM','Invalid Format - the Source Code field is required and may not be longer than 3 characters','stg.HIMSupplementalMedical','SourceCode',999,1,'9999-12-31','2014-01-01')
,(30014,'HIMSUPCLM','Invalid Format - the Rendering Provider NPI field is required and may not be longer than 10 characters','stg.HIMSupplementalMedical','ProviderNPI',999,1,'2016-02-08','2014-01-01')
,(30015,'HIMSUPCLM','Invalid Format - the Rendering Provider Tax ID field is required and may not be longer than 9 characters','stg.HIMSupplementalMedical','ProviderTaxID',999,1,'2016-02-08','2014-01-01')
,(30016,'HIMSUPCLM','The combination of LOB Plan ID + Variant ID in the supplemental data does not match an active value','stg.HIMSupplementalMedical','LOBPlanID',999,1,'9999-12-31','2014-01-01')
,(30017,'HIMSUPCLM','The supplemental claims LOB Plan ID and Variant ID must match the Members LOB Plan ID and Variant ID','stg.HIMSupplementalMedical','PatientMemberID',999,1,'9999-12-31','2014-01-01')
,(30018,'HIMSUPCLM','Duplicate Record Number values exist within the file','stg.HIMSupplementalMedical','RecordNumber',999,1,'2015-05-12','2014-01-01')
,(30019,'HIMSUPCLM','The Supplemental Diagnosis Origination Date must be less than or equal to the current date','stg.HIMSupplementalMedical','SuppDiagOrigDate',999,1,'9999-12-31','2014-01-01')
,(30020,'HIMSUPCLM','The Supplemental Claim Indicator must have a value of 1 or 8','stg.HIMSupplementalMedical','SuppClaimIndicator',999,1,'9999-12-31','2014-01-01')
,(30021,'HIMSUPCLM','The Service From Date must be less than or equal to Service To Date','stg.HIMSupplementalMedical','ServiceFromDate',999,1,'9999-12-31','2014-01-01')
,(30022,'HIMSUPCLM','The Service To Date must be greater than or equal to Service From Date','stg.HIMSupplementalMedical','ServiceToDate',999,1,'9999-12-31','2014-01-01')
,(30023,'HIMSUPDIAG','The Diagnosis Code Qualifier must have a value of 01 or 02','stg.HIMSupplementalDiag','DiagCodeQualifier',999,1,'9999-12-31','2014-01-01')
,(30024,'HIMSUPDIAG','The Diagnosis Code must be a valid, no decimal format, version of the ICD-9 code that is effective during the Service From Date and Service To Date date range','stg.HIMSupplementalDiag','DiagCode',999,1,'9999-12-31','2014-01-01')
,(30025,'HIMSUPDIAG','The Diagnosis Code must be a valid, no decimal format, version of the ICD-10 code that is effective during the Service From Date and Service To Date date range','stg.HIMSupplementalDiag','DiagCode',999,1,'9999-12-31','2014-01-01')
,(30026,'HIMSUPCLM','The Source Code must have a value of MR or EDI','stg.HIMSupplementalMedical','SourceCode',999,1,'2016-01-20','2014-01-01')
,(30027,'HIMSUPCLM','The Rendering Provider NPI number must match a valid NPI number','stg.HIMSupplementalMedical','ProviderNPI',999,1,'2016-02-08','2014-01-01')
,(30028,'HIMSUPCLM','The Rendering Provider Tax ID value must be a properly formatted Provider Tax ID number','stg.HIMSupplementalMedical','ProviderTaxID',999,1,'2016-02-08','2014-01-01')
,(30029,'HIMSUPCLM','The Supplemental Issuer ID value does not match the first 5 characters of the supplemental LOB Plan ID','stg.HIMSupplementalMedical','IssuerID',999,1,'9999-12-31','2014-01-01')
,(30030,'HIMSUPCLM','The Supplemental claims date of service must be within the members coverage dates.','stg.HIMSupplementalMedical','PatientMemberID',999,1,'9999-12-31','2014-01-01')
,(30031,'HIMSUPCLM','The ICD-9 Diagnosis Code in the supplemental data could not be verified as active based on the Service From/To Dates','stg.HIMSupplementalMedical','DiagCode',999,1,'2015-09-30','2014-01-01')
,(30032,'HIMSUPCLM','The ICD-10 Diagnosis Code in the supplemental data could not be verified as active based on the Service From/To Dates','stg.HIMSupplementalMedical','DiagCode',999,1,'2015-09-30','2014-01-01')
,(30033,'HIMSUPCLM','The combination of LOB Plan ID + Variant ID in the supplemental data could not be verified as active based on the Service From/To Dates','stg.HIMSupplementalMedical','LOBPlanID',999,1,'2015-05-07','2014-01-01')
,(30034,'HIMSUPCLM','Supplemental Claim can have multiple diagnosis codes','stg.HIMSupplementalMedical','DiagCode',3503,1,'2016-01-20','2014-01-01')
,(30035,'HIMSUPCLM','Encounter must have YEAR of ServiceToDate equal to Processing Year','stg.HIMSupplementalMedical','ServiceToDate',999,1,'9999-12-31','2015-08-31')
,(30036,'HIMSUPDIAG','ICD9 diagnosis codes can only have a source code of EDI or MR','stg.HIMSupplementalDiag','SourceCode',999,1,'9999-12-31','2016-01-20')
,(30037,'HIMSUPDIAG','ICD10 diagnosis codes can only have a source code of EDI or MR','stg.HIMSupplementalDiag','SourceCode',999,1,'9999-12-31','2016-01-20')
,(30038,'HIMSUPDIAG','Supplemental claims can have either ICD9 or ICD10 diagnosis codes, but cannot have a combination of both','stg.HIMSupplementalDiag','DiagCodeQualifier',999,1,'9999-12-31','2016-01-20')
,(30039,'HIMSUPDIAG','Claim date for ICD9 codes must be prior to Oct 1st 2015.','stg.HIMSupplementalDiag','DiagCode',999,1,'9999-12-31','2016-02-25')
,(30040,'HIMSUPDIAG','Claim date for ICD10 codes must be on or after Oct 1st 2015.','stg.HIMSupplementalDiag','DiagCode',999,1,'9999-12-31','2016-02-25')


--Plan

,(40001,'Plan','Plan Identifiers must be 14 characters in length.','stg.PlanDetail','LOBPlanID',999,1,'9999-12-31','2016-05-26')
,(40002,'Plan','A plan can only have one metal level assigned to it.','stg.PlanDetail','LOBPlanID',999,1,'9999-12-31','2016-05-26')
,(40003,'Plan','If Variant ID is 04, 05, or 06 then Metal Level must be 03.','stg.PlanDetail','Metal Level',999,1,'9999-12-31','2016-05-26')
,(40004,'Plan','A Metal level of 05 can only have 00 or 01 variant ID.','stg.PlanDetail','Metal Level',999,1,'9999-12-31','2016-05-26')
,(40005,'Plan','Metal Level must be 01, 02, 03, 04, or 05.','stg.PlanDetail','Metal Level',999,1,'9999-12-31','2016-05-26')
,(40006,'Plan','A plans rating area must be 3 digits in length.','stg.PlanDetail','Rating Area',999,1,'9999-12-31','2016-05-26')
,(40007,'Plan','Effective date must be in the correct date format.','stg.PlanDetail','Effective Date',999,1,'9999-12-31','2016-05-26')
,(40008,'Plan','Effective Start date must occur before or during current submission year.','stg.PlanDetail','Effective Date',999,1,'9999-12-31','2016-05-26')
,(40009,'Plan','Effective end date must be in the correct date format.','stg.PlanDetail','Effective End Date',999,1,'9999-12-31','2016-05-26')
,(40010,'Plan','Effective End date must occur after Effective Start date.','stg.PlanDetail','Effective End Date',999,1,'9999-12-31','2016-05-26')
,(40011,'Plan','Payment year must match the CMS submission year.','stg.PlanDetail','Payment Year',999,1,'2016-07-28','2016-05-26')
,(40012,'Plan','Line of Business identifier must be CI, CS, or CL.','stg.PlanDetail','LOB',999,1,'9999-12-31','2016-05-26')
,(40013,'Plan','The Issuer identifier is not configured for the client.','stg.PlanDetail','Issuer ID',999,1,'2016-06-29','2016-05-26')
,(40014,'Plan','The issuer identifier must match to the client in the header of the data file.','stg.PlanDetail','Issuer ID',999,1,'2016-06-29','2016-05-26')
,(40015,'Plan','The issuer identifier must match the first five digits of the LOBPlanID.','stg.PlanDetail','Issuer ID',999,1,'9999-12-31','2016-05-26')
,(40016,'Plan','State code must equate to a valid state.','stg.PlanDetail','State Code',999,1,'9999-12-31','2016-05-26')
,(40017,'Plan','HIOS Product ID must match what is in the LOBPlan identifier.','stg.PlanDetail','HIOS Product ID',999,1,'9999-12-31','2016-05-26')
,(40018,'Plan','HIOS Component ID must match what is in the LOBPlan identifier.','stg.PlanDetail','HIOS Component ID',999,1,'9999-12-31','2016-05-26')
,(40019,'Plan','Market place indicator must be the value of Y or N.','stg.PlanDetail','Market Place Indicator',999,1,'9999-12-31','2016-05-26')
,(40020,'Plan','Market place indicator must be N only when Variant ID is equal to 00.','stg.PlanDetail','Market Place Indicator',999,1,'9999-12-31','2016-05-26')
,(40021,'Plan','Plan type, if provided, must be HMO, PPO, POS, HAS or SDHP.','stg.PlanDetail','Plan Type',999,1,'9999-12-31','2016-05-26')
,(40022,'Plan','PCP Assignment  indicator must be the value of Y or N.','stg.PlanDetail','PCP Assignment Required',999,1,'9999-12-31','2016-05-26')
,(40023,'Plan','Local or National Plan must be a value of 1 or 2.','stg.PlanDetail','Local or National Plan',999,1,'9999-12-31','2016-05-26')
,(40024,'Plan','Variant ID must be one of the following 00, 01, 02, 03, 04, 05, or 06 value.','stg.PlanDetail','Variant ID',999,1,'9999-12-31','2016-05-26')
,(40025,'Plan','Effective End date must occur during or after current submission year.','stg.PlanDetail','Effective End Date',999,1,'2016-07-28','2016-05-26')
;

BEGIN TRANSACTION;

SET IDENTITY_INSERT ETLValidation ON;

MERGE dbo.ETLValidation AS target
USING 
  (SELECT ETLValidationID,DomainCD,ValidationDescription,TableName,ColumnName,TargetStatusID,GlobalLOBState,DisabledDateTime,CreatedDateTime
   FROM @ETLValidation) AS source
ON (target.ETLValidationID = source.ETLValidationID)
WHEN MATCHED THEN 
  UPDATE SET
      target.DomainCD = source.DomainCD,
      target.ValidationDescription = source.ValidationDescription,
      target.TableName = source.TableName,
      target.ColumnName = source.ColumnName,
      target.TargetStatusID = source.TargetStatusID,
      target.GlobalLOBState = source.GlobalLOBState,
      target.DisabledDateTime = source.DisabledDateTime,
      target.CreatedDateTime = source.CreatedDateTime
WHEN NOT MATCHED THEN  
  INSERT (ETLValidationID,DomainCD,ValidationDescription,TableName,ColumnName,TargetStatusID,GlobalLOBState,DisabledDateTime,CreatedDateTime)
  VALUES (source.ETLValidationID,source.DomainCD,source.ValidationDescription,source.TableName,source.ColumnName,source.TargetStatusID,source.GlobalLOBState,source.DisabledDateTime,CreatedDateTime);

SET IDENTITY_INSERT ETLValidation OFF;

COMMIT TRANSACTION;


