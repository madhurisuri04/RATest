CREATE TABLE rev.IntermediarySupplementalEncounter
(
[Id] [bigint] IDENTITY(1,1) NOT NULL,
[ClaimID] [varchar](50) NULL,
[EntityDiscriminator] [varchar](2) NULL,
[BaseClaimID] [varchar](50) NULL,
[SecondaryClaimID] [varchar](50) NULL,
[ClaimIndicator] [char](1) NULL,
[ServiceEndDate] [datetime] NULL,
[EncounterRiskAdjustable] [bit] NULL,
[RecordID] [varchar](80) NULL,
[SystemSource] [varchar](30) NULL,
[VendorID] [varchar](100) NULL,
[MedicalRecordImageID] [int] NULL,
[SubProjectMedicalRecordID] [int] NULL,
[SubProjectID] [int] NULL,
[SubProjectName] [varchar](100) NULL,
[SupplementalID] [bigint] NULL,
[DerivedPatientControlNumber] [varchar](50) NULL,
[EncounterICN] [bigint] NULL,
[Diagnosis] [varchar](7) NULL,
[Loaddatetime] [datetime] NOT NULL,
[LoadID] [bigint] NOT NULL
);