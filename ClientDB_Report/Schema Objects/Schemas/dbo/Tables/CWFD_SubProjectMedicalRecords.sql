CREATE TABLE [dbo].[CWFD_SubProjectMedicalRecords]
(
		 [ID] BIGINT IDENTITY (-10000000000000, 1) NOT NULL,
		 [SPMRID] INT NOT NULL, 
		 [SubProjectID] INT NOT NULL,	
		 [ProviderTypeID] INT NULL,
		 [ProviderType] VARCHAR(50) NULL,
		 [MemberFirstName]  VARCHAR (70)   NULL,
		 [MemberLastName]  VARCHAR (120)  NULL,
		 [MemberDOB] date,
		 [ContractID]  VARCHAR(50) NULL,
		 [PlanMemberID] VARCHAR (50)   NULL,
		 [PlanProviderID]  VARCHAR (80)   NULL,
		 [UniqueMemberIdentifierValue] VARCHAR(50)  NULL,					
		 [ProviderTypeCD] CHAR(2),
		 [RequestID] INT NULL,
		 [ProviderNPI] VARCHAR(100) NULL,
		 [ProviderTIN] VARCHAR(100) NULL,
		 [ProviderLastName] VARCHAR(120) NULL,
		 [ProviderFirstName] VARCHAR(70) NULL,
		 [LastUpdatedDate] [datetime2](7) NULL
)
