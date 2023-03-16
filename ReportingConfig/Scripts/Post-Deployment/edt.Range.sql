/* AUTO-GENERATED AND COPY-PASTED FROM LINQPAD, SEE END OF FILE FOR GENERATION COMMAND */
BEGIN TRANSACTION;

TRUNCATE TABLE [edt].[Range];
GO

SET IDENTITY_INSERT [edt].[Range] ON;

INSERT INTO [edt].[Range] ([ID],[Name],[Descr],[TypeID],[isActive],[ModifiedDT])         SELECT 1, 'Taxonomies', 'To lookup a valid Taxonomy', '2', 1, 'Jan  6 2014  4:02PM' UNION ALL
    SELECT 2, 'Length Between', '1 - 1', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 3, 'Length Between', '1 - 10', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 4, 'Length Between', '1 - 11', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 5, 'Length Between', '1 - 12', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 6, 'Length Between', '1 - 15', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 7, 'Length Between', '1 - 18', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 8, 'Length Between', '1 - 2', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 9, 'Length Between', '1 - 25', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 10, 'Length Between', '1 - 256', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 11, 'Length Between', '1 - 3', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 12, 'Length Between', '1 - 30', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 13, 'Length Between', '1 - 35', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 14, 'Length Between', '1 - 38', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 15, 'Length Between', '1 - 4', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 16, 'Length Between', '1 - 50', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 17, 'Length Between', '1 - 55', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 18, 'Length Between', '1 - 59', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 19, 'Length Between', '1 - 6', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 20, 'Length Between', '1 - 60', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 21, 'Length Between', '1 - 8', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 22, 'Length Between', '1 - 80', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 23, 'Length Between', '1 - 9', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 24, 'Length Between', '11 - 11', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 25, 'Length Between', '2 - 2', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 26, 'Length Between', '2 - 3', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 27, 'Length Between', '2 - 30', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 28, 'Length Between', '2 - 50', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 29, 'Length Between', '2 - 80', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 30, 'Length Between', '6 - 6', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 31, 'Length Between', '9 - 9', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 32, 'Numeric Value Between', '-99999999.990 - 99999999.990', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 33, 'Numeric Value Between', '0.000 - 1.000', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 34, 'Numeric Value Between', '0.000 - 99.000', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 35, 'Numeric Value Between', '0.000 - 99999999.000', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 36, 'Numeric Value Between', '0.000 - 99999999.990', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 37, 'Numeric Value Between', '0.001 - 999999.900', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 38, 'Numeric Value Between', '0.001 - 9999999.999', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 39, 'Numeric Value Between', '0.010 - 999.000', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 40, 'Numeric Value Between', '0.010 - 9999.990', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 41, 'Numeric Value Between', '0.010 - 99999.990', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 42, 'Numeric Value Between', '0.010 - 99999999.990', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 43, 'Numeric Value Between', '0.100 - 999999.900', '3', 1, 'Jan 15 2014 12:22PM' UNION ALL
    SELECT 44, 'Valid Values', 'Values must equal 1 and 2', '1', 1, 'Jan 16 2014 12:02PM' UNION ALL
    SELECT 45, 'NPI', 'To lookup a valid NPI', '2', 1, 'Jan 22 2014  3:45PM'     GO
INSERT INTO [edt].[Range] ([ID],[Name],[Descr],[TypeID],[isActive],[ModifiedDT])         SELECT 130, 'Exclusive Secondary ID', '0B', '4', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 131, 'Exclusive Secondary ID', '1G', '4', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 132, 'Exclusive Secondary ID', 'G2', '4', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 133, 'Exclusive Secondary ID', 'LU', '4', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 134, 'Common State Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 135, 'Payer Resp. Code', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 136, 'Relationship Code', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 137, 'Assign. Of Benefits', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 138, 'Release of Information', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 139, 'Remit Remarks', 'lookup table', '2', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 140, 'Line Attch Type', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 141, 'Transmission Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 142, 'DME Transmsn Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 143, 'Y/N', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 144, 'Patient Conditions', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 145, 'Order By Phys Flag', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 146, 'Contract Type Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 147, 'Service Auth.', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 148, 'Reference Types', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 149, 'Transport Reasons', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 150, 'Ptnt Cond Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 151, 'Vsn Cond Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 152, 'Homebound Flag', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 153, 'Condition Codes', NULL, '2', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 154, 'Pricing Methodology', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 155, 'Reject Rsn Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 156, 'Plcy Cmplnce Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 157, 'Exception Codes', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 158, 'Ins Type', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 159, 'Genders', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 160, 'Provider Assign Ind', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 161, 'Benefits Ind', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 162, 'Accdnt Flag', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 163, 'Spcl Prgrm Code', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 164, 'Attch Type', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 165, 'Attch Trnsmsn Code', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 166, 'Contract Types', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 167, 'PricingMethodoly', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 168, 'PolicyComplianceExplanation', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 169, 'ThirdPartyExceptionReason', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 170, 'EncounterServiceLineCOBAdjustmentsGroup', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 171, 'Indicator', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 172, 'FlagResponse', NULL, '1', 1, 'Feb  3 2014 12:17PM' UNION ALL
    SELECT 173, 'PROC Type Lookup', NULL, '2', 1, 'Mar 20 2014 11:53AM' UNION ALL
    SELECT 174, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProvideID ValueEntity with DN qualifier', '4', 1, 'Apr 17 2014 12:21PM' UNION ALL
    SELECT 175, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProvideID ValueEntity with P3 qualifier', '4', 1, 'Apr 17 2014 12:21PM' UNION ALL
    SELECT 176, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProvideID,LocationNumber ValueEntity with 82 qualifier', '4', 1, 'Apr 17 2014 12:21PM' UNION ALL
    SELECT 177, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProvideID,LocationNumber ValueEntity with DQ qualifier', '4', 1, 'Apr 17 2014 12:21PM' UNION ALL
    SELECT 178, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,PlanProvideID,LocationNumber ValueEntity with 77 qualifier', '4', 1, 'Apr 17 2014 12:21PM' UNION ALL
    SELECT 179, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- PlanProvideID,LocationNumber ValueEntity with 85 qualifier', '4', 1, 'Apr 17 2014 12:21PM' UNION ALL
    SELECT 180, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProviderID,LocationNumber ValueEntity with 71 qualifier', '4', 1, 'Apr 17 2014  2:16PM' UNION ALL
    SELECT 181, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProviderID,LocationNumber ValueEntity with 72 qualifier', '4', 1, 'Apr 17 2014  2:16PM' UNION ALL
    SELECT 182, 'EncounterCOBProvidersEntityList', 'EncounterCOBProviders- StateLicenseNumber,UPIN,PlanProviderID,LocationNumber ValueEntity with ZZ qualifier', '4', 1, 'Apr 17 2014  2:16PM' UNION ALL
    SELECT 183, 'Member Variant ID', 'Valid Member Variant IDs', '1', 1, 'Jun 25 2014 10:26AM' UNION ALL
    SELECT 184, 'HIM Product ID P', 'HIM Product or Service IDs for Professional', '1', 1, 'Jun 25 2014 10:26AM' UNION ALL
    SELECT 185, 'HIM Product ID I', 'HIM Product or Service IDs for Institutional', '1', 1, 'Jun 25 2014 10:33AM' UNION ALL
    SELECT 186, 'Bill Types', 'Bill Type Lookup', '2', 1, 'Aug 13 2014 12:34PM' UNION ALL
    SELECT 187, 'Place of Service', 'Place of Service Lookup', '2', 1, 'Aug 13 2014 12:34PM' UNION ALL
    SELECT 188, 'Revenue Code Lookup', 'Revenue Code Lookup', '5', 1, 'Oct 28 2014 10:05AM' UNION ALL
    SELECT 189, 'ICD9 Revised Code Lookup', 'ICD9 Revised Code Lookup', '2', 1, 'Oct 28 2014 10:05AM' UNION ALL
    SELECT 190, 'Discharge NUBC lookup', 'Discharge NUBC lookup', '2', 1, 'Nov  4 2014 10:16AM' UNION ALL
    SELECT 191, 'ICD9 Procedure Code', 'ICD9 Procedure Code', '2', 1, 'Nov  4 2014 10:16AM' UNION ALL
    SELECT 192, 'Value Code Lookup', 'Value Code Lookup', '2', 1, 'Nov  5 2014  1:20PM' UNION ALL
    SELECT 193, 'Occurence Span Code Lookup', 'Occurence Span Code Lookup', '2', 1, 'Nov  5 2014  1:20PM' UNION ALL
    SELECT 194, 'Occurence Code Lookup', 'Occurence Code Lookup', '2', 1, 'Nov 17 2014 12:47PM' UNION ALL
    SELECT 195, 'lk_HCPCS_Modifier Lookup', 'lk_HCPCS_Modifier Lookup', '2', 1, 'Nov 17 2014 12:47PM' UNION ALL
    SELECT 196, 'lk_TreatmentCodes Lookup', 'lk_TreatmentCodes Lookup', '2', 1, 'Nov 17 2014 12:47PM' UNION ALL    
    SELECT 197, 'ICD 10 Procedure Code Qualifiers', 'ICD 10 Procedure Code Qualifiers', '1', 1, 'Aug 28 2015 11:13AM' UNION ALL
    SELECT 198, 'ICD 9 Procedure Code Qualifiers', 'ICD 9 Procedure Code Qualifiers', '1', 1, 'Aug 28 2015 11:13AM'	UNION ALL
    SELECT 199, 'ICD 10 Diagnosis Qualifiers', 'ICD 10 Diagnosis Qualifiers', '1', 1, 'Sep 23 2015 4:26PM' UNION ALL
    SELECT 200, 'ICD 9 Diagnosis Qualifiers', 'ICD 9 Diagnosis Qualifiers', '1', 1, 'Sep 23 2015  4:26PM' UNION ALL
    SELECT 201, 'HCPCS Codes', 'HCPCS Codes', '2', 1, 'Oct 23 2015  3:26PM' UNION ALL
    SELECT 202, 'HIPPS Codes', 'HIPPS Codes', '2', 1, 'Oct 23 2015  3:26PM' UNION ALL
	SELECT 203, 'One or more Secondary ID', 'Entity list of dbo.EncounterProviders.LicenseNumber and dbo.EncounterProviders.PlanProviderID', '4', 1, 'Oct 28 2015 2:00PM' UNION ALL
    SELECT 204, 'One or more Secondary ID', 'Entity list of dbo.EncounterProviders.UPIN and dbo.EncounterProviders.PlanProviderID', '4', 1, 'Oct 28 2015 2:00PM' UNION ALL
    SELECT 205, 'One or more Secondary ID', 'Entity list of dbo.EncounterProviders.UPIN and dbo.EncounterProviders.LicenseNumber', '4', 1, 'Oct 28 2015 2:00PM' UNION ALL
	SELECT 206, 'lk_msdrg', 'lk_msdrg', '2', 1, '2016-02-09 14:00:00'
	GO

SET IDENTITY_INSERT [edt].[Range] OFF;

COMMIT;


/* TO REGENERATE THIS FILE EXECUTE THE FOLLOWING STATEMENT IN LINQPAD WITH RESULTS TO GRID */
/* THEN COPY THE ENTIRE RESULTS GRID USING TOP LEFT CORNER AND CTRL+C AND PASTE IT OVER THIS ENTIRE FILE */
/*     EXEC [dbo].[GeneratePostDeploymentScript] 'edt', 'Range' */
/* EVEN THE COMMENTS WILL BE RECREATED WHEN THIS SCRIPT IS RUN */