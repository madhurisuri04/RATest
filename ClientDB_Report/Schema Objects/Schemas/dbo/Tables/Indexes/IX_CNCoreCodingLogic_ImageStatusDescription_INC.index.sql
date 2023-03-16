CREATE NONCLUSTERED INDEX IX_CNCoreCodingLogic_ImageStatusDescription_INC
ON [dbo].[CNCoreCodingLogic] ([ImageStatusDescription])
INCLUDE ([ProjectID],[ProjectType],[SubProjectID],[OrganizationID],[HICN],[SubProjectMedicalRecordID],[DiagnosisID],[DiagnosisStatus],[HCCNumber],[ICD9Part],[DropHCC],[DateOfServiceFailureReason],[DiagnosisFailureReason],[MedicalRecordRank])
WITH (  FillFactor = 80)
