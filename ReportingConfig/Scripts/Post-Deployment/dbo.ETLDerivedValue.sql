-- =============================================
-- Script Template
-- =============================================

IF @@SERVERNAME <> 'HRPTRNDB01'
BEGIN

   BEGIN TRANSACTION DerivedValues_Table_Refresh

   TRUNCATE TABLE dbo.ETLDerivedValue 

   SET IDENTITY_INSERT dbo.ETLDerivedValue ON 

   --GO

	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (1, N'Conventry - Set PaperClaim equal to "1" when EncounterClaimNotes has a ReferenceType of "UPI" or "ADD" and the Text is equal to "Paper"', N'stg.ClaimStackDerivedValues', N'PaperClaim',1,(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') , 'Coventry', 1 )
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Spring') IS NOT NULL
	BEGIN	
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (2, N'Health Spring - Set PaperClaim equal to "1" when EncounterOptionalReportingIndicators has a OptionalReportingInd of "PAPER" or "PAPER CLAIM"', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Spring'), 'Health Spring', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (3, N'Independent Health - Set PaperClaim equal to "1" when EncounterClaimNotes has a ReferenceType of "TPO" and the Text is equal to "PaperClaim"', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health'), 'Independent Health', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Lovelace') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (4, N'Lovelace - Set PaperClaim equal to "1" when Encounters has a ClaimID that is numeric', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Lovelace'), 'Lovelace', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (5, N'PHP - Set PaperClaim equal to "1" when Encounters has a ClaimID with the 3rd character in the string of either 0-9,A,B,C,D,L,M,N,P', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan'), 'Presbyterian Health Plan', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (6, N'Regence - Set PaperClaim equal to "1" when EncounterOptionalReportingIndicators has a OptionalReportingInd of "PAPER" or "PAPER CLAIM"', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') , 'The Regence Group',  1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Scott and White Health Plan') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (7, N'Scott White - Set PaperClaim equal to "1" when Encounters has a ClaimID with the 8th character in the string of either Z or M', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Scott and White Health Plan'), 'Scott and White Health Plan', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (8, N'Aetna - Set Encounter Adjustment Type ID to "Incremental" when the Encounter ORI Ordiance is "6" and the OptReportInd is either "CAPTAINR", "CLAIMCPY", "MINUSADJ", or "REFUND" ', N'stg.ClaimStackDerivedValues', N'EncounterAdjustmentTypeID', 1,(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna'), 'Aetna', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (9, N'Conventry - Set SystemSource to value between the first and seconds underscores of the filename in the dbo.FileImports table', N'stg.ClaimStackDerivedValues', N'SystemSource', 1,(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') , 'Coventry', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (10, N'MVP - Set PaperClaim equal to "1" when SystemSource = "Paper"', N'stg.ClaimStackDerivedValues', N'SystemSource', 1, (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care'), 'MVP Health Care', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') IS NOT NULL
	BEGIN
	   INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
		   VALUES (11, N'HFHP - Set  PaperClaim equal to "1" When  encounterattachments.Type="OZ" and encounterattachments.TransmissionCode="AA"', N'stg.ClaimStackDerivedValues', N'SystemSource', 1,(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') , 'Health First Health Plan', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MCS') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (12, N'MCS - Set  PaperClaim equal to "1" When  encounterattachments.Type="OZ"', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1,(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MCS') , 'MCS', 1)
	END
	
	IF (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') IS NOT NULL
	BEGIN
		INSERT dbo.ETLDerivedValue (ETLDerivedValueID, DerivedValueDescription, TableName, ColumnName, GlobalLOBState, OrganizationID, OrganizationName, Active) 
			VALUES (13, N'Aetna - Set PaperClaim to "1" When (SUBSTRING(SecondaryClaimID,7,1) in ("I","K","J","G","M","P","T","V","Y") or  LEFT(ClaimID,1)="P") for C25/N10 OR( SUBSTRING(SecondaryClaimID,7,1) = "U" or  LEFT(e.ClaimID,1)="P") for C25L/C25LAL corresponding 837 OR  LEFT(e.ClaimID,1)="P" for C25L/C25LAL', N'stg.ClaimStackDerivedValues', N'PaperClaim', 1,(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna'), 'Aetna', 1)
	END

   --GO

   SET IDENTITY_INSERT dbo.ETLDerivedValue OFF 
   --GO


   COMMIT TRANSACTION DerivedValues_Table_Refresh
END