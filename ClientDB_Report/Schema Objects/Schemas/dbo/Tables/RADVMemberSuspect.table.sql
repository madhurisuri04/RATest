CREATE TABLE [dbo].[RADVMemberSuspect]
(
	ID int Identity,
	RADVMemberID int,
	TargetHCCNumber varchar (10),
	TargetICDCode1 varchar (10),
	TargetICDCode2 varchar (10),
	TargetICDCode3 varchar (10),
	TargetICDCode4 varchar (10),
	TargetICDCode5 varchar (10),
	TargetICDCode6 varchar (10),
	TargetICDCode7 varchar (10),
	TargetICDCode8 varchar (10),
	TargetICDCode9 varchar (10),
	TargetICDCode10 varchar (10),
	TargetICDCode11 varchar (10),
	TargetICDCode12 varchar (10),
	HierarchyApplied char (1),
	CreationDateTime datetime2 default getdate()
)
