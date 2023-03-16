Create table rev.IntermediarySupplemental
(
[Id] [bigint] IDENTITY(1,1) NOT NULL,
[RecordID] [varchar](80) NULL,
[SystemSource] [varchar](30) NULL,
[VendorID] [varchar](100) NULL,
[ServiceEndDate] [datetime] NULL,
[MedicalRecordImageID] [int] NULL,
[SubProjectMedicalRecordID] [int] NULL,
[SubProjectID] [int] NULL,
[SubProjectName] [varchar](100) NULL,
[SupplementalID] [bigint] NULL,
[Loaddatetime] [datetime] NOT NULL,
[LoadID] [bigint] NOT NULL
);