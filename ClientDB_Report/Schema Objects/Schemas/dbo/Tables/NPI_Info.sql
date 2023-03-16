CREATE TABLE [dbo].[NPI_Info]
(
    [ID] [BIGINT] IDENTITY(1, 1) NOT NULL,
    [DiagnosisID] [INT] NULL,
    [MemberHICN] [VARCHAR](50) NULL,
    [RawCode] [VARCHAR](10) NULL,
    [DOSSTART] [DATE] NULL,
    [DOSEND] [DATE] NULL,
    [CurrentMedicalRecordID] [INT] NULL,
    [OldMedicalRecordID] [INT] NULL,
    [ChangedProviderID] [VARCHAR](80) NULL,
    [OldProviderID] [VARCHAR](80) NULL,
    [CodingUserID] [INT] NULL,
    [ChangedProviderFirstName] [VARCHAR](70) NULL,
    [ChangedProviderLastName] [VARCHAR](120) NULL,
    [ClientID] [INT] NULL,
    [CodingUserName] [VARCHAR](50) NULL,
    [LastUpdatedDate] [DATE] NULL,
    [UserFirstName] [VARCHAR](50) NULL,
    [UserLastName] [VARCHAR](50) NULL,
    [MRIWLastUpdatedDateTime] DATETIME2 NULL
)