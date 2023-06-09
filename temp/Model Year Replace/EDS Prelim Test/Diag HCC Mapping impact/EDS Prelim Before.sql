USE [Aetna_Report]

CREATE TABLE [#Vw_LkRiskModelsDiagHCC]
(
    [ICDCode] [NVARCHAR](255) NULL,
    [HCC_Label] [NVARCHAR](255) NULL,
    [Payment_Year] [FLOAT] NULL,
    [Factor_Type] [VARCHAR](3) NOT NULL,
    [ICDClassification] [TINYINT] NULL,
    [StartDate] [DATETIME] NOT NULL,
    [EndDate] [DATETIME] NOT NULL
);

INSERT INTO [#Vw_LkRiskModelsDiagHCC]
(
    [ICDCode],
    [HCC_Label],
    [Payment_Year],
    [Factor_Type],
    [ICDClassification],
    [StartDate],
    [EndDate]
)
SELECT DISTINCT
       [ICDCode] = [icd].[ICDCode],
       [HCC_Label] = [icd].[HCCLabel],
       [Payment_Year] = [icd].[PaymentYear],
       [Factor_Type] = [icd].[FactorType],
       [ICDClassification] = [icd].[ICDClassification],
       [StartDate] = [ef].[StartDate],
       [EndDate] = [ef].[EndDate]
FROM [HRPReporting].[dbo].[Vw_LkRiskModelsDiagHCC] [icd]
    JOIN [HRPReporting].[dbo].[ICDEffectiveDates] [ef]
        ON [icd].[ICDClassification] = [ef].[ICDClassification];


CREATE NONCLUSTERED INDEX [IX_Vw_LkRiskModelsDiagHCC]
ON [#Vw_LkRiskModelsDiagHCC] (
                                 [Payment_Year],
                                 [StartDate],
                                 [EndDate],
                                 [Factor_Type],
                                 [ICDCode]
                             );

drop table [#tbl_0010_MmrHicnList]
CREATE TABLE [#tbl_0010_MmrHicnList]
(
    [PlanIdentifier] [INT] NULL,
    [PaymentYear] [INT] NULL,
    [HICN] [VARCHAR](12) NULL,
    [PartCRAFTProjected] [VARCHAR](2) NULL,
    [ModelYear] [INT] NULL
);

INSERT INTO [#tbl_0010_MmrHicnList]
(
    [PlanIdentifier],
    [PaymentYear],
    [HICN],
    [PartCRAFTProjected],
    [ModelYear]
)
SELECT DISTINCT
       [PlanIdentifier] = [mmr].[PlanID],
       [PaymentYear] = [mmr].[PaymentYear],
       [HICN] = [mmr].[HICN],
       [PartCRAFTProjected] = [mmr].[PartCRAFTProjected],
       [ModelYear] = [split].[ModelYear]
FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr] WITH (NOLOCK)
    JOIN [HRPReporting].[dbo].[lk_Risk_Score_Factors_PartC] [split] WITH (NOLOCK)
        ON [mmr].[PaymentYear] = [split].[PaymentYear]
           AND [mmr].[PartCRAFTProjected] = [split].[RAFactorType]
           AND [split].[SubmissionModel] = 'EDS'
where mmr.PaymentYear = '2021'
;



CREATE NONCLUSTERED INDEX [IX_tbl_0010_MmrHicnList]
ON [#tbl_0010_MmrHicnList] (
                               [HICN],
                               [PaymentYear],
                               [PartCRAFTProjected]
                           );



drop table [Prodsupport].dbo.[IntermediateEDSAltHicn]
SELECT DISTINCT
       [PlanIdentifier] = [b].PlanIdentifier,
       [PaymentYear] = [B].PaymentYear,
       [PartCRAFTProjected] = [B].PartCRAFTProjected,
       [ModelYear] = [B].ModelYear,
       [MAO004ResponseID] = [a].[MAO004ResponseID],
       [stgMAO004ResponseID] = [a].[stgMAO004ResponseID],
       [ContractID] = [a].[ContractID],  --RRI 799
       [HICN] = [a].[HICN],
       [SentEncounterICN] = [a].[SentEncounterICN],
       [ReplacementEncounterSwitch] = [a].[ReplacementEncounterSwitch],
       [SentICNEncounterID] = [a].[SentICNEncounterID],
       [OriginalEncounterICN] = [a].[OriginalEncounterICN],
       [OriginalICNEncounterID] = [a].[OriginalICNEncounterID],
       [PlanSubmissionDate] = [a].[PlanSubmissionDate],
       [ServiceStartDate] = [a].[ServiceStartDate],
       [ServiceEndDate] = [a].[ServiceEndDate],
       [ClaimType] = [a].[ClaimType],
       [FileImportID] = [a].[FileImportID],
       [LoadID] = [a].[LoadID],
       [LoadDate] = [a].[SrcLoadDate],
       [SentEncounterRiskAdjustableFlag] = [a].[SentEncounterRiskAdjustableFlag],
       [RiskAdjustableReasonCodes] = [a].[RiskAdjustableReasonCodes],
       [OriginalEncounterRiskAdjustableFlag] = [a].[OriginalEncounterRiskAdjustableFlag],
       [MAO004ResponseDiagnosisCodeID] = [a].[MAO004ResponseDiagnosisCodeID],
       [DiagnosisCode] = [a].[DiagnosisCode],
       [DiagnosisICD] = [a].[DiagnosisICD],
       [DiagnosisFlag] = [a].[DiagnosisFlag],
       [IsDelete] = [a].[IsDelete],
       [ClaimID] = [a].[ClaimID],
       [EntityDiscriminator] = [a].[EntityDiscriminator],
       [BaseClaimID] = [a].[BaseClaimID],
       [SecondaryClaimID] = [a].[SecondaryClaimID],
       [ClaimIndicator] = [a].[ClaimIndicator],
       [EncounterRiskAdjustable] = [a].[EncounterRiskAdjustable],
       [RecordID] = [a].[RecordID],
       [SystemSource] = [a].[SystemSource],
       [VendorID] = [a].[VendorID],
       [MedicalRecordImageID] = [a].[MedicalRecordImageID],
       [SubProjectMedicalRecordID] = [a].[SubProjectMedicalRecordID],
       [SubProjectID] = [a].[SubProjectID],
       [SubProjectName] = [a].[SubProjectName],
       [SupplementalID] = [a].[SupplementalID],
       [DerivedPatientControlNumber] = [a].[DerivedPatientControlNumber],
       [YearServiceEndDate] = YEAR([a].[ServiceEndDate]) + 1
INTO [Prodsupport].dbo.[IntermediateEDSAltHicn]
FROM [rev].[tbl_Summary_RskAdj_EDS_Source] [a] -- RE - 5112 
    JOIN [#tbl_0010_MmrHicnList] [B]
        ON [B].[HICN] = [a].[HICN]
           AND YEAR([a].[ServiceEndDate]) + 1 = [B].[PaymentYear]	
WHERE [a].[HICN] IS NOT NULL


    SELECT DISTINCT
           [PlanIdentifier] = [a].[PlanIdentifier],
           [PaymentYear] = [a].[PaymentYear],
           [ModelYear] = [a].[ModelYear],
           [HICN] = [a].[HICN],
           [PartCRAFTProjected] = [a].[PartCRAFTProjected],
           [MAO004ResponseID] = [a].[MAO004ResponseID],
           [stgMAO004ResponseID] = [a].[stgMAO004ResponseID],
           [ContractID] = [a].[ContractID],
           [SentEncounterICN] = [a].[SentEncounterICN],
           [ReplacementEncounterSwitch] = [a].[ReplacementEncounterSwitch],
           [SentICNEncounterID] = [a].[SentICNEncounterID],
           [OriginalEncounterICN] = CASE
                                        WHEN [a].[OriginalEncounterICN] = 0 THEN
                                            NULL
                                        ELSE
                                            [a].[OriginalEncounterICN]
                                    END,                                                      --TFS 65132   DW 6/1/2017
           [OriginalICNEncounterID] = [a].[OriginalICNEncounterID],
           [PlanSubmissionDate] = [a].[PlanSubmissionDate],
           [ServiceStartDate] = [a].[ServiceStartDate],
           [ServiceEndDate] = [a].[ServiceEndDate],
           [ClaimType] = [a].[ClaimType],
           [FileImportID] = [a].[FileImportID],
           [LoadID] = [a].[LoadID],
           [LoadDate] = [a].[LoadDate],
           [SentEncounterRiskAdjustableFlag] = [a].[SentEncounterRiskAdjustableFlag],         --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [SentEncounterRiskAdjustableFlag]
           [RiskAdjustableReasonCodes] = [a].[RiskAdjustableReasonCodes],                     --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [RiskAdjustableReasonCodes]
           [OriginalEncounterRiskAdjustableFlag] = [a].[OriginalEncounterRiskAdjustableFlag], --TFS 64778  HasanMF 5/9/2017: This fieldname needs to be changed to [OriginalEncounterRiskAdjustableFlag]
           [MAO004ResponseDiagnosisCodeID] = [a].[MAO004ResponseDiagnosisCodeID],
           [DiagnosisCode] = [a].[DiagnosisCode],
           [DiagnosisICD] = [a].[DiagnosisICD],
           [DiagnosisFlag] = [a].[DiagnosisFlag],
           [IsDelete] = [a].[IsDelete],
           [ClaimID] = [a].[ClaimID],
           [EntityDiscriminator] = [a].[EntityDiscriminator],
           [BaseClaimID] = [a].[BaseClaimID],
           [SecondaryClaimID] = [a].[SecondaryClaimID],
           [ClaimIndicator] = [a].[ClaimIndicator],
           [RecordID] = [a].[RecordID],
           [SystemSource] = [a].[SystemSource],
           [VendorID] = [a].[VendorID],
           [MedicalRecordImageID] = [a].[MedicalRecordImageID],
           [SubProjectMedicalRecordID] = [a].[SubProjectMedicalRecordID],
           [SubProjectID] = [a].[SubProjectID],
           [SubProjectName] = [a].[SubProjectName],
           [SupplementalID] = [a].[SupplementalID],
           [DerivedPatientControlNumber] = [a].[DerivedPatientControlNumber],
           [Void_Indicator] = 0,
           [Voided_by_MAO004ResponseDiagnosisCodeID] = 0,
           [RiskAdjustable] = a.EncounterRiskAdjustable,                        --RRI 1754 
           [Deleted] = CASE WHEN ISDelete = 1 THEN 'A'
		                    WHEN ISDelete = 0 THEN 'D'
							ELSE NULL END , ---rri 1754
           [HCC_Label] = [hcc].[HCC_Label],
           [HCC_Number] = CAST(LTRIM(REVERSE(LEFT(REVERSE([hcc].[HCC_Label]), PATINDEX(
                                                                                          '%[A-Z]%',
                                                                                          REVERSE([hcc].[HCC_Label])
                                                                                      ) - 1)
                                            )
                                    ) AS INT),
           [LoadDateTime] = getdate(),
           [MATCHED] = CASE
                           WHEN [a].[ReplacementEncounterSwitch] > 3
                                AND [a].[OriginalICNEncounterID] IS NOT NULL THEN
                               'Y'
                           WHEN [a].[ReplacementEncounterSwitch] > 3
                                AND [a].[OriginalICNEncounterID] IS NULL THEN
                               'N'
                           ELSE
                               NULL
                       END
    INTO [Prodsupport].dbo.[tbl_Summary_RskAdj_EDS_Preliminary_03032022_Before]
	FROM [Prodsupport].dbo.[IntermediateEDSAltHicn] [a]
        JOIN [#Vw_LkRiskModelsDiagHCC] [hcc]
            ON [a].[ModelYear] = [hcc].[Payment_Year]
               AND [a].[ServiceEndDate]
               BETWEEN [hcc].[StartDate] AND [hcc].[EndDate]
               AND [a].[PartCRAFTProjected] = [hcc].[Factor_Type]
               AND [a].[DiagnosisCode] = [hcc].[ICDCode]
    WHERE [a].[PaymentYear] = 2021;

