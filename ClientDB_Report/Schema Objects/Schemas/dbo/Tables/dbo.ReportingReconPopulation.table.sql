CREATE TABLE [dbo].[ReportingReconPopulation] (
	[LineOfBusinessID] [int] NOT NULL
	,[ReportingYear] [char](4) NULL
	,[ListChaseID] [varchar](50) NULL
	,[ProjectID] [int] NOT NULL
	,[ProjectDesc] [varchar](85) NOT NULL
	,[SubprojectID] [int] NOT NULL
	,[SubProjectDesc] [varchar](85) NOT NULL
	,[SubprojectmedicalrecordID] [int] NOT NULL
	,[MedicalrecordImageWorkflowId] [int] NOT NULL
	,[MedicalRecordImageStatusID] [int] NOT NULL
	,[ImageID] [int] NOT NULL
	,[DiagnosisID] [int] NOT NULL
	,[DiagStatusID] [tinyint] NOT NULL
	,[MedicalRecordID] [int] NOT NULL
	,[MemberNumber] [varchar](50) NOT NULL
	,[RawCode] [varchar](8) NOT NULL
	,[DOSStart] [date] NOT NULL
	,[DOSEnd] [date] NOT NULL
	,[PlanProviderID] [varchar] (80) NULL
	,[ProviderType] [char](2) NULL
	,[CodingDiagnosisID] [int] NOT NULL
	,[CodingDiagnosisStatusID] [tinyint] NOT NULL
	,[Status] [varchar](5) NULL
	,[IsValidNPI] BIT NOT NULL
	,[Loaddate] DATETIME2 NOT NULL
	)