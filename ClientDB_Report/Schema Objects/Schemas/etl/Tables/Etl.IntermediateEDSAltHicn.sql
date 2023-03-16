create table [Etl].[IntermediateEDSAltHicn]
(
    [Id] int identity(1, 1)
  , [PlanIdentifier] [int] null
  , [PaymentYear] [int] null
  , [HICN] [varchar](12) null
  , [PartCRAFTProjected] [varchar](2) null
  , [ModelYear] [int] null
  , [MAO004ResponseID] [bigint] not null
  , [stgMAO004ResponseID] [bigint] not null
  , [ContractID] [varchar](5) null
  , [SentEncounterICN] [bigint] null
  , [ReplacementEncounterSwitch] [char](1) null
  , [SentICNEncounterID] [bigint] null
  , [OriginalEncounterICN] [bigint] null
  , [OriginalICNEncounterID] [bigint] null
  , [PlanSubmissionDate] [date] null
  , [ServiceStartDate] [date] null
  , [ServiceEndDate] [date] null
  , [ClaimType] [char](1) null
  , [FileImportID] [int] null
  , [LoadID] [bigint] null
  , [LoadDate] [datetime] not null
  , [SentEncounterRiskAdjustableFlag] [char](1) null
  , [RiskAdjustableReasonCodes] [char](1) null
  , [OriginalEncounterRiskAdjustableFlag] [char](1) null
  , [MAO004ResponseDiagnosisCodeID] [bigint] null
  , [DiagnosisCode] [varchar](7) null
  , [DiagnosisICD] [char](1) null
  , [DiagnosisFlag] [bit] not null
  , [IsDelete] [bit] null
  , [ClaimID] [varchar](50) null
  , [EntityDiscriminator] [varchar](2) null
  , [BaseClaimID] [varchar](50) null
  , [SecondaryClaimID] [varchar](50) null
  , [ClaimIndicator] [char](1) null
  , [EncounterRiskAdjustable] [bit] null
  , [RecordID] [varchar](80) null
  , [SystemSource] [varchar](30) null
  , [VendorID] [varchar](100) null
  , [MedicalRecordImageID] [int] null
  , [SubProjectMedicalRecordID] [int] null
  , [SubProjectID] [int] null
  , [SubProjectName] [varchar](100) null
  , [SupplementalID] [bigint] null
  , [DerivedPatientControlNumber] [varchar](50) null
  , [YearServiceEndDate] [int] null
)
 