/* AUTO-GENERATED AND COPY-PASTED FROM LINQPAD, SEE END OF FILE FOR GENERATION COMMAND */
BEGIN TRANSACTION;

TRUNCATE TABLE [edt].[Condition];
GO

SET IDENTITY_INSERT [edt].[Condition] ON;

INSERT INTO [edt].[Condition] ([ID],[Name],[Descr],[FailedValidationMessage],[ValueEntity],[ValueEntityQualifier],[Value],[RangeID],[TypeID],[isActive],[ModifiedDT])         SELECT 1, 'Paper', 'C# Controlled Condition that the Encounter is a Paper claim', 10001, NULL, NULL, NULL, NULL, 0, 1, 'Dec 19 2013 11:43AM' UNION ALL
    SELECT 2, 'Manual', 'C# Controlled Condition that the Encounter is a Manual claim', 10001, NULL, NULL, NULL, NULL, 0, 1, 'Dec 19 2013 11:43AM'     GO
INSERT INTO [edt].[Condition] ([ID],[Name],[Descr],[FailedValidationMessage],[ValueEntity],[ValueEntityQualifier],[Value],[RangeID],[TypeID],[isActive],[ModifiedDT])         SELECT 4, 'FieldName Exists', 'EncounterMember.PropertyCasualtyContactName should have value', 10001, 417, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 5, 'FieldName Exists', 'EncounterHeader.AutoAccidentState should have value', 10001, 371, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 6, 'FieldName Exists', 'EncounterHeader.AccidentDate should have value', 10001, 367, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 7, 'FieldName Exists', 'EncounterHeader.ContractAmount should have value', 10001, 336, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 8, 'FieldName Exists', 'EncounterHeader.ContractPercentage should have value', 10001, 337, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 9, 'FieldName Exists', 'EncounterHeader.ContractCode should have value', 10001, 338, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 10, 'FieldName Exists', 'EncounterHeader.TermsDiscount should have value', 10001, 339, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 11, 'FieldName Exists', 'EncounterHeader.ContractVersion should have value', 10001, 340, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 12, 'FieldName Exists', 'EncounterTransportationPatientConditionCodes.Code should have value', 10001, 848, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 13, 'FieldName Exists', 'EncounterTransportation.TransportationCertificationFlag should have value', 10001, 33, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 14, 'FieldName Exists', 'EncounterHeader.SurgicalAnesthesiaSecondaryProcedure should have value', 10001, 333, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 15, 'FieldName Exists', 'EncounterHeader.PolicyComplianceCode should have value', 10001, 365, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 16, 'FieldName Exists', 'EncounterHeader.RejectReasonCode should have value', 10001, 364, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 17, 'FieldName Exists', 'EncounterHeader.RepricedAllowedAmount should have value', 10001, 355, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 18, 'FieldName Exists', 'EncounterHeader.RepricedApprovedAmbulatoryPatientGroupAmount should have value', 10001, 360, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 19, 'FieldName Exists', 'EncounterHeader.RepricedApprovedAmbulatoryPatientGroupCode should have value', 10001, 359, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 20, 'FieldName Exists', 'EncounterHeader.RepricedApprovedRevenueCode should have value', 10001, 361, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 21, 'FieldName Exists', 'EncounterHeader.RepricedSavingsAmount should have value', 10001, 356, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 22, 'FieldName Exists', 'EncounterHeader.RepricedServiceDays should have value', 10001, 363, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 23, 'FieldName Exists', 'EncounterHeader.RepricedServiceUnits should have value', 10001, 362, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 24, 'FieldName Exists', 'EncounterHeader.RepricingOrganizationIdentifier should have value', 10001, 357, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 25, 'FieldName Exists', 'EncounterHeader.RepricingPerDiemFlatRate should have value', 10001, 358, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 26, 'FieldName Exists', 'EncounterHeader.PricingMethodology should have value', 10001, 354, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 27, 'FieldName Exists', 'EncounterCOB.ESRDPaymentAmount should have value', 10001, 86, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 28, 'FieldName Exists', 'EncounterCOB.NonPayableProfessionalComponent should have value', 10001, 87, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 29, 'FieldName Exists', 'EncounterCOB.ReimbursementRate should have value', 10001, 84, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 30, 'FieldName Exists', 'EncounterServiceLineTransportationInfo.AmbulanceCertificationFlag should have value', 10001, 6, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 31, 'FieldName Exists', 'EncounterServiceLineTransportationInfo.AmbulanceRoundTripPurpose should have value', 10001, 10, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 32, 'FieldName Exists', 'EncounterServiceLineTransportationInfo.PatientWeight should have value', 10001, 7, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 33, 'FieldName Exists', 'EncounterServiceLineTransportationInfo.AmbulanceTransportDistance should have value', 10001, 9, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 34, 'FieldName Exists', 'EncounterServiceLineTransportationInfo.StretcherPurposeDescription should have value', 10001, 11, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 35, 'FieldName Exists', 'EncounterServiceLineTransportationInfo.AmbulanceTransportReason should have value', 10001, 8, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 36, 'FieldName Exists', 'EncounterServiceLineTransportationPatientCondition.PatientCondition should have value', 10001, 19, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 37, 'FieldName Exists', 'EncounterServiceLineDMEINFO.OrderedByPhysicianFlag should have value', 10001, 615, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 38, 'FieldName Exists', 'EncounterServiceLineDMEINFO.ReplacementItemFlag should have value', 10001, 616, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 39, 'FieldName Exists', 'EncounterServiceLineDMEINFO.CertificationFlag should have value', 10001, 614, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 40, 'FieldName Exists', 'EncounterServiceLine.ContractAmount should have value', 10001, 753, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 41, 'FieldName Exists', 'EncounterServiceLine.ContractPercent should have value', 10001, 754, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 42, 'FieldName Exists', 'EncounterServiceLine.ContractCode should have value', 10001, 755, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 43, 'FieldName Exists', 'EncounterServiceLine.TermsDiscountPercent should have value', 10001, 756, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 44, 'FieldName Exists', 'EncounterServiceLine.ContractVersionID should have value', 10001, 757, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 45, 'FieldName Exists', 'EncounterServiceLine.RepricedAllowedAmount should have value', 10001, 762, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 46, 'FieldName Exists', 'EncounterServiceLine.PricingMethodoly should have value', 10001, 761, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 47, 'FieldName Exists', 'EncounterServiceLine.NationalDrugGrams should have value', 10001, 795, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 48, 'FieldName Exists', 'EncounterServiceLine.NationalDrugInternationalUnits should have value', 10001, 794, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 49, 'FieldName Exists', 'EncounterServiceLine.NationalDrugMilligrams should have value', 10001, 796, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 50, 'FieldName Exists', 'EncounterServiceLine.NationalDrugMilliliters should have value', 10001, 797, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 51, 'FieldName Exists', 'EncounterServiceLine.NationalDrugUnits should have value', 10001, 798, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 52, 'FieldName Exists', 'EncounterServiceLineProviders.ContactPhone should have value', 10001, 705, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 53, 'FieldName Exists', 'EncounterServiceLineProviders.ContactEmail should have value', 10001, 707, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 54, 'FieldName Exists', 'EncounterServiceLineProviders.ContactFax should have value', 10001, 706, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 55, 'FieldName Exists', 'EncounterServiceLineCOB.OtherPayerProcedureDescription should have value', 10001, 538, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 56, 'FieldName Exists', 'EncounterServiceLineCOB.OtherABCCode should have value', 10001, 537, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 57, 'FieldName Exists', 'EncounterServiceLineCOB.OtherPayerAdjustedBundledOrUnbundledLineNumber should have value', 10001, 541, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 58, 'FieldName Exists', 'EncounterServiceLineCOB.OtherPayerPaidAmount should have value', 10001, 535, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 59, 'FieldName Exists', 'EncounterServiceLineCOB.OtherPayerPrimaryIdentifier should have value', 10001, 534, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 60, 'FieldName Exists', 'EncounterServiceLineCOBAdjustmentItems.Reason should have value', 10001, 554, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 61, 'FieldName Exists', 'EncounterServiceLineSupportingDocumentation.FlagResponse should have value', 10001, 824, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 62, 'FieldName Exists', 'EncounterServiceLineSupportingDocumentation.TextResponse should have value', 10001, 825, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 63, 'FieldName Exists', 'EncounterServiceLineSupportingDocumentation.DateResponse should have value', 10001, 826, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 64, 'FieldName Exists', 'EncounterServiceLineSupportingDocumentation.PercentageResponse should have value', 10001, 827, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 65, 'FieldName Exists', 'EncounterServiceLine.NationalDrugCode should have value', 10001, 793, NULL, NULL, NULL, 1, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 66, 'FieldName Do NotExists', 'EncounterServiceLine.NationalDrugGrams should not have value', 10001, 795, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 67, 'FieldName Do NotExists', 'EncounterServiceLine.NationalDrugInternationalUnits should not have value', 10001, 794, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 68, 'FieldName Do NotExists', 'EncounterServiceLine.NationalDrugMilligrams should not have value', 10001, 796, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 69, 'FieldName Do NotExists', 'EncounterServiceLine.NationalDrugMilliliters should not have value', 10001, 797, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 70, 'FieldName Do NotExists', 'EncounterServiceLine.NationalDrugUnits should not have value', 10001, 798, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:56PM' UNION ALL
    SELECT 71, 'Field Do Not Exists', 'EncounterVision.LensesFlag do not have value', 10001, 50, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 72, 'Field Do Not Exists', 'EncounterVision.ContactsFlag do not have value', 10001, 51, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 73, 'Field Do Not Exists', 'EncounterVision.FramesFlag do not have value', 10001, 52, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 74, 'Field Do Not Exists', 'EncounterServiceLineDMEInfo.DailyRentalPrice do not have value', 10001, 608, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 75, 'Field Do Not Exists', 'EncounterServiceLineDMEInfo.MonthlyRentalPrice do not have value', 10001, 609, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 76, 'Field Do Not Exists', 'EncounterServiceLineDMEInfo.WeeklyRentalPrice do not have value', 10001, 624, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 77, 'Field Do Not Exists', 'EncounterServiceLineDMEInfo.InitialCertificationFlag do not have value', 10001, 610, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 78, 'Field Do Not Exists', 'EncounterServiceLineDMEInfo.RevisedCertificationFlag do not have value', 10001, 611, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 79, 'Field Do Not Exists', 'EncounterServiceLineDMEInfo.RenewalCertificationFlag do not have value', 10001, 612, NULL, NULL, NULL, 2, 1, 'Mar 26 2014  2:59PM' UNION ALL
    SELECT 80, 'FieldName Exists', 'EncounterServiceLineProvider.ContactPhone should have value for Qualifier DK', 10001, 705, 27, NULL, NULL, 1, 1, 'Apr 17 2014 12:24PM' UNION ALL
    SELECT 81, 'FieldName Exists', 'EncounterServiceLineProvider.ContactEmail should have value for Qualifier DK', 10001, 707, 27, NULL, NULL, 1, 1, 'Apr 17 2014 12:24PM' UNION ALL
    SELECT 82, 'FieldName Exists', 'EncounterServiceLineProvider.ContactFax should have value for Qualifier DK', 10001, 706, 27, NULL, NULL, 1, 1, 'Apr 17 2014 12:24PM' UNION ALL
    SELECT 83, 'FieldName Exists', 'EncounterServiceLineProvider.ContactName should have value for Qualifier DK', 10001, 704, 27, NULL, NULL, 1, 1, 'Apr 17 2014 12:24PM' UNION ALL
    SELECT 84, 'FieldName Do NotExists', 'EncounterServiceLineProvider.ContactPhone should not have value for Qualifier DK', 10001, 705, 27, NULL, NULL, 2, 1, 'Apr 17 2014 12:24PM' UNION ALL
    SELECT 85, 'FieldName Do NotExists', 'EncounterServiceLineProvider.ContactEmail should not have value for Qualifier DK', 10001, 707, 27, NULL, NULL, 2, 1, 'Apr 17 2014 12:24PM' UNION ALL
    SELECT 86, 'FieldName Do NotExists', 'EncounterServiceLineProvider.ContactFax should not have value for Qualifier DK', 10001, 706, 27, NULL, NULL, 2, 1, 'Apr 17 2014 12:24PM'     GO
INSERT INTO [edt].[Condition] ([ID],[Name],[Descr],[FailedValidationMessage],[ValueEntity],[ValueEntityQualifier],[Value],[RangeID],[TypeID],[isActive],[ModifiedDT])         SELECT 88, 'COB OtherPayerPlan', 'COB OtherPayerPlan expects child condition', 10001, 130, NULL, NULL, NULL, 32, 1, 'Jun 24 2014 12:02PM' UNION ALL
    SELECT 89, 'Member LOB Plan', 'Member LOB Plan should be child condition', 10001, 420, NULL, NULL, NULL, 5, 1, 'Jun 24 2014 12:02PM' UNION ALL
    SELECT 90, 'ESLCOB OtherPayerPlan', 'ESLCOB OtherPayerPlan expects child condition', 10001, 534, NULL, NULL, NULL, 32, 1, 'Jun 24 2014 12:31PM' UNION ALL
    SELECT 91, 'FieldName Exists', 'EncounterServiceLines.ProductOrServiceIDQualifier should have a value', 10001, 724, NULL, NULL, NULL, 1, 1, 'Jun 24 2014  4:21PM' UNION ALL
    SELECT 92, 'Inpatient', 'Is Inpatient Claim', 10001, 285, NULL, 'I', NULL, 5, 1, 'Jun 25 2014 10:34AM' UNION ALL
    SELECT 93, 'ESL Procedure Code Exists', 'Encounter Service Lines Procedure Code must exist', 10001, 725, NULL, NULL, NULL, 1, 1, 'Jun 25 2014 10:59AM' UNION ALL
    SELECT 94, 'FieldName Exists', 'EncounterServiceLineCOB.OtherProcedureCode should have value', 10001, 536, NULL, NULL, NULL, 1, 1, 'Aug 13 2014 12:32PM' UNION ALL
    SELECT 95, 'DiagnosisType = 1', 'DiagnosisType = 1', 10001, 294, NULL, '1', NULL, 5, 1, 'Oct 28 2014 10:05AM' UNION ALL
    SELECT 96, 'FieldName Exists', 'EncounterValueCodes.Amount should have a value', 10001, 875, NULL, NULL, NULL, 1, 1, 'Nov  5 2014  1:20PM' UNION ALL
    SELECT 97, 'FieldName Exists', 'EncounterValueCodes.Code should have a value', 10001, 874, NULL, NULL, NULL, 1, 1, 'Nov  5 2014  1:20PM' UNION ALL
	SELECT 98, 'ClaimIndicator!=8', 'ClaimIndicator!=8', 10001, 473, NULL, '8', NULL, 6, 1, 'Apr 28 2015 10:09AM' UNION ALL
	SELECT 99, 'Encounter uses ICD10', 'Encounter uses ICD10', 10001, NULL, NULL, NULL, NULL, 35, 1, 'Aug 24 2015 02:48PM' UNION ALL
	SELECT 100, 'Encounter uses ICD9', 'Encounter uses ICD9', 10001, NULL, NULL, NULL, NULL, 36, 1, 'Aug 24 2015  2:48PM' UNION ALL
    SELECT 101, 'ProductOrServiceIDQualifier = HC', 'ProductOrServiceIDQualifier = HC', 10001, 724, NULL, 'HC', NULL, 5, 1, 'Oct 23 2015  3:26PM' UNION ALL
    SELECT 102, 'ProductOrServiceIDQualifier = HP', 'ProductOrServiceIDQualifier = HP', 10001, 724, NULL, 'HP', NULL, 5, 1, 'Oct 23 2015  3:26PM' UNION ALL
	SELECT 103, 'EncounterHeader.DRGCode != 000', 'EncounterHeader.DRGCode != 000', 10001, 374, NULL, '000', NULL, 6, 1, '2016-02-09 14:00:00'
	GO

SET IDENTITY_INSERT [edt].[Condition] OFF;

COMMIT;


/* TO REGENERATE THIS FILE EXECUTE THE FOLLOWING STATEMENT IN LINQPAD WITH RESULTS TO GRID */
/* THEN COPY THE ENTIRE RESULTS GRID USING TOP LEFT CORNER AND CTRL+C AND PASTE IT OVER THIS ENTIRE FILE */
/*     EXEC [dbo].[GeneratePostDeploymentScript] 'edt', 'Condition' */
/* EVEN THE COMMENTS WILL BE RECREATED WHEN THIS SCRIPT IS RUN */