CREATE NONCLUSTERED INDEX [IDX_CNCoreCodingLogic_OrganizationID_LastUpdateDateTime_ImageStatusDescription]
    ON [dbo].[CNCoreCodingLogic]
	([OrganizationID],[LastUpdateDateTime],[ImageStatusDescription])
INCLUDE ([ProjectDescription],[ProjectID],[ProjectType],[SubProjectID],[SubProjectDescription],[HICN],[WorkflowDisplayName],[WorkflowStepName],[SubProjectMedicalRecordID],[ImageID],[CodedBy],[CoderFirstName],[CoderLastName],[DailyCodingGoal],[MedicalRecordImageStatusID])


