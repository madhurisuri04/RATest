CREATE TABLE [dbo].[NPIImage_Info]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DiagnosisID] [int] NULL,
	[ImageID] [int] NULL,
	[MemberHICN] [varchar](50) NULL,
	[RawCode] [varchar](10) NULL,
	[DOSSTART] [date] NULL,
	[DOSEND] [date] NULL,
	[CurrentMedicalRecordID] [int] NULL,
	[OldMedicalRecordID] [int] NULL,
	[ChangedProviderID] [varchar](80) NULL,
	[OldProviderID] [varchar](80) NULL,
	[CodingUserID] [int] NULL,
	[ChangedProviderFirstName] [varchar](70) NULL,
	[ChangedProviderLastName] [varchar](120) NULL,
	[ClientID] [int] NULL,
	[CodingUserName] [varchar](50) NULL,
	[LastUpdatedDate] [date] NULL,
	[UserFirstName] [varchar](50) NULL,
	[UserLastName] [varchar](50) NULL,
	[MRIWLastUpdatedDateTime] DATETIME2 NULL

)
