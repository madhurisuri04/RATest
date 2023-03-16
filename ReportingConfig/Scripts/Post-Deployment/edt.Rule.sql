	/* AUTO-GENERATED AND COPY-PASTED FROM LINQPAD, SEE END OF FILE FOR GENERATION COMMAND */
	BEGIN TRANSACTION;
	
	TRUNCATE TABLE [edt].[Rule];
	GO
	
	SET IDENTITY_INSERT [edt].[Rule] ON;
	
	INSERT INTO [edt].[Rule] ([ID],[Name],[Descr],[isActive],[ModifiedDT])
        SELECT 1, 'Required', 'Flags an Entity as a required field', 1, 'Dec 19 2013 11:08AM' UNION ALL
	    SELECT 2, 'Type', 'Verifies that an Entity''s value is of a specified type', 1, 'Dec 19 2013 11:08AM' UNION ALL
	    SELECT 3, 'Length', 'Verifies that an Entity''s value is of a certain length (singular or range)', 1, 'Dec 19 2013 11:08AM' UNION ALL
	    SELECT 4, 'Value', 'Verifies that an Entity''s value matches a ValueEntity''s value, a specified Value or is within a specified Range', 1, 'Dec 19 2013 11:08AM' UNION ALL
		SELECT 5, 'Must Be Empty', 'Verifies that an Entity does not have a value', 1, 'Dec 19 2013 11:08AM' UNION ALL
		SELECT 6, 'Exclusive Or', 'Verifies that Entity has a value OR that ValueEntity or a list of entities in a range has a value.', 1, 'Jan 27 2014  4:05PM' UNION ALL
		SELECT 7, 'One Or More', 'Verifies that Entity has a value OR that at least one ValueEntity or list of entities in a range has a value.', 1, 'Oct 28 2015 2:00PM'
    GO
	
	SET IDENTITY_INSERT [edt].[Rule] OFF;
	
	COMMIT;
	
	
	/* TO REGENERATE THIS FILE EXECUTE THE FOLLOWING STATEMENT IN LINQPAD WITH RESULTS TO GRID */
	/* THEN COPY THE ENTIRE RESULTS GRID USING TOP LEFT CORNER AND CTRL+C AND PASTE IT OVER THIS ENTIRE FILE */
	/*     EXEC [dbo].[GeneratePostDeploymentScript] 'edt', 'Rule' */
	/* EVEN THE COMMENTS WILL BE RECREATED WHEN THIS SCRIPT IS RUN */