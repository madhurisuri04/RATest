	/* AUTO-GENERATED AND COPY-PASTED FROM LINQPAD, SEE END OF FILE FOR GENERATION COMMAND */
	BEGIN TRANSACTION;
	
	TRUNCATE TABLE [dve].[TableDefinition];
	GO
	
	SET IDENTITY_INSERT [dve].[TableDefinition] ON;
	
	INSERT INTO [dve].[TableDefinition] ([ID],[TableDatabase],[TableSchema],[TableName])
        SELECT 1, NULL, 'dbo', 'EncounterServiceLineTransportationInfo' UNION ALL
	    SELECT 2, NULL, 'dbo', 'EncounterServiceLineTransportationPatientCondition' UNION ALL
	    SELECT 3, NULL, 'dbo', 'EncounterProviderTypes' UNION ALL
	    SELECT 4, NULL, 'dbo', 'EncounterTransportation' UNION ALL
	    SELECT 5, NULL, 'dbo', 'EncounterTransportationAddresses' UNION ALL
	    SELECT 6, NULL, 'dbo', 'EncounterVision' UNION ALL
	    SELECT 7, NULL, 'dbo', 'EncounterAttachments' UNION ALL
	    SELECT 8, NULL, 'dbo', 'EncounterClaimNotes' UNION ALL
	    SELECT 9, NULL, 'dbo', 'EncounterCOB' UNION ALL
	    SELECT 10, NULL, 'dbo', 'EncounterCOBAdjustmentItems' UNION ALL
	    SELECT 11, NULL, 'dbo', 'EncounterCOBAdjustments' UNION ALL
	    SELECT 12, NULL, 'dbo', 'EncounterCOBClaimPaymentRemarks' UNION ALL
	    SELECT 13, NULL, 'dbo', 'EncounterCOBProviders' UNION ALL
	    SELECT 14, NULL, 'dbo', 'EncounterConditions' UNION ALL
	    SELECT 15, NULL, 'dbo', 'EncounterReconciliationSummary' UNION ALL
	    SELECT 16, NULL, 'dbo', 'EncounterDental' UNION ALL
	    SELECT 17, NULL, 'dbo', 'EncounterDentalTeethDetail' UNION ALL
	    SELECT 18, NULL, 'dbo', 'EncounterDentalToothAttributes' UNION ALL
	    SELECT 19, NULL, 'dbo', 'EncounterDerivedValues' UNION ALL
	    SELECT 20, NULL, 'dbo', 'EncounterDiagnosis' UNION ALL
	    SELECT 21, NULL, 'dbo', 'EncounterHeader' UNION ALL
	    SELECT 22, NULL, 'dbo', 'EncounterMember' UNION ALL
	    SELECT 23, NULL, 'dbo', 'EncounterTransactions' UNION ALL
	    SELECT 24, NULL, 'dbo', 'EncounterOccurrences' UNION ALL
	    SELECT 25, NULL, 'dbo', 'EncounterOptionalReportingIndicators' UNION ALL
	    SELECT 26, NULL, 'dbo', 'EncounterPayToAddress' UNION ALL
	    SELECT 27, NULL, 'dbo', 'Encounters' UNION ALL
	    SELECT 28, NULL, 'dbo', 'EncounterProviders' UNION ALL
	    SELECT 29, NULL, 'dbo', 'EncounterReasonForVisit' UNION ALL
	    SELECT 30, NULL, 'dbo', 'EncounterServiceLineAttachments' UNION ALL
	    SELECT 31, NULL, 'dbo', 'EncounterServiceLineCOB' UNION ALL
	    SELECT 32, NULL, 'dbo', 'EncounterServiceLineCOBAdjustmentItems' UNION ALL
	    SELECT 33, NULL, 'dbo', 'EncounterServiceLineCOBAdjustments' UNION ALL
	    SELECT 34, NULL, 'dbo', 'EncounterServiceLineCOBLineProvider' UNION ALL
	    SELECT 35, NULL, 'dbo', 'EncounterServiceLineDentalInfo' UNION ALL
	    SELECT 36, NULL, 'dbo', 'EncounterServiceLineDentalInfoOralCavityDesignation' UNION ALL
	    SELECT 37, NULL, 'dbo', 'EncounterServiceLineDiagnosis' UNION ALL
	    SELECT 38, NULL, 'dbo', 'EncounterServiceLineDMEInfo' UNION ALL
	    SELECT 39, NULL, 'dbo', 'EncounterPatient' UNION ALL
	    SELECT 40, NULL, 'dbo', 'EncounterServiceLineOptionalReportingIndicator' UNION ALL
	    SELECT 41, NULL, 'dbo', 'EncounterPayer' UNION ALL
	    SELECT 42, NULL, 'dbo', 'EncounterServiceLineProcedureModifiers' UNION ALL
	    SELECT 43, NULL, 'dbo', 'EncounterServiceLineProviders' UNION ALL
	    SELECT 44, NULL, 'dbo', 'EncounterServiceLineReferralNumbers' UNION ALL
	    SELECT 45, NULL, 'dbo', 'EncounterServiceLines' UNION ALL
	    SELECT 46, NULL, 'dbo', 'EncounterServiceLineSupportingDocumentation' UNION ALL
	    SELECT 47, NULL, 'dbo', 'EncounterServiceLineTransportationAddressInfo' UNION ALL
	    SELECT 48, NULL, 'dbo', 'EncounterTransportationPatientConditionCodes' UNION ALL
		SELECT 49, NULL, 'dbo', 'EncounterProcedureCodes' UNION ALL
		SELECT 50, NULL, 'dbo', 'EncounterServiceLineRevenueCodes' UNION ALL
        SELECT 51, NULL, 'dbo', 'EncounterTreatmentCodes' UNION ALL
        SELECT 52, NULL, 'dbo', 'EncounterValueCodes' 
    GO
	
	SET IDENTITY_INSERT [dve].[TableDefinition] OFF;
	
	COMMIT;
	
	
	/* TO REGENERATE THIS FILE EXECUTE THE FOLLOWING STATEMENT IN LINQPAD WITH RESULTS TO GRID */
	/* THEN COPY THE ENTIRE RESULTS GRID USING TOP LEFT CORNER AND CTRL+C AND PASTE IT OVER THIS ENTIRE FILE */
	/*     EXEC [dbo].[GeneratePostDeploymentScript] 'dve', 'TableDefinition' */
	/* EVEN THE COMMENTS WILL BE RECREATED WHEN THIS SCRIPT IS RUN */