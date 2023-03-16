CREATE NONCLUSTERED INDEX IX_CNCoreLogic_MedicalRecordRank_SubProjectMedicalRedordStatusDescription_INC
ON [dbo].[CNCoreLogic] ([MedicalRecordRank],[SubProjectMedicalRecordStatusDescription])
INCLUDE ([ProjectID],[ProjectType],[SubProjectID],[OrganizationID],[SubProjectMedicalRecordID])
WITH (  FillFactor = 80)

