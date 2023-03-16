
BEGIN TRANSACTION;

TRUNCATE TABLE [dve].[_CriteriaType];
GO

SET IDENTITY_INSERT [dve].[_CriteriaType] ON;

INSERT INTO [dve].[_CriteriaType] ( [ID], [Name], [Descr] )
	SELECT  0 as ID, 'C#' as Name, 'C# Controlled Configuration' as Descr UNION ALL
	SELECT  1 as ID, 'Exists' as Name, 'The record / entity exists' as Descr UNION ALL
	SELECT  2 as ID, '!Exists' as Name, 'The record / entity does not exist' as Descr UNION ALL
	SELECT  3 as ID, 'Matches Pattern' as Name, 'The value of the entity matches to a supplied Regular Expression''s pattern' as Descr UNION ALL
	SELECT  4 as ID, '!Matches Pattern' as Name, 'The value of the entity does NOT match the supplied Regular Expression''s pattern' as Descr UNION ALL
	SELECT  5 as ID, '=' as Name, 'The value of the entity directly equals a supplied value' as Descr UNION ALL
	SELECT  6 as ID, '!=' as Name, 'The value of the entity does NOT equal a supplied value' as Descr UNION ALL
	SELECT  7 as ID, '<' as Name, 'The value is less than a supplied value (non-string values expected)' as Descr UNION ALL
	SELECT  8 as ID, '<=' as Name, 'The value is less than or equal to a supplied value (non-string values expected)' as Descr UNION ALL
	SELECT  9 as ID, '>' as Name, 'The value is greater than a supplied value (non-string values expected)' as Descr UNION ALL
	SELECT 10 as ID, '>=' as Name, 'The value is greater than or equal to a supplied value (non-string values expected)' as Descr UNION ALL
	SELECT 11 as ID, 'Count =' as Name, 'The number of matching entity found is equal to a specified count (value)' as Descr UNION ALL
	SELECT 12 as ID, 'Count !=' as Name, 'The number of matching entity found is NOT equal to a specified count (value)' as Descr UNION ALL
	SELECT 13 as ID, 'Count <' as Name, 'The number of matching entity found is less than a specified count (value)' as Descr UNION ALL
	SELECT 14 as ID, 'Count <=' as Name, 'The number of matching entity found is less than or equal to a specified count (value)' as Descr UNION ALL
	SELECT 15 as ID, 'Count >' as Name, 'The number of matching entity found is greater than a specified count (value)' UNION ALL
	SELECT 16 as ID, 'Count >=' as Name, 'The number of matching entity found is greater than or equal to a specified count (value)' as Descr UNION ALL
	SELECT 17 as ID, 'Between' as Name, 'Compares the value against a Range of 2 values (via RangeID)' as Descr UNION ALL
	SELECT 18 as ID, 'In' as Name, 'Compares the value to find any match within a Range of values (via RangeID)' as Descr UNION ALL
	SELECT 19 as ID, '!In' as Name, 'Compares the value to find NO matches within a Range of values (via RangeID)' as Descr UNION ALL
	SELECT 20 as ID, 'Contains' as Name, 'A string comparison with wildcard at the beginning and end of the value to be matched' as Descr UNION ALL
	SELECT 21 as ID, 'Starts With' as Name, 'A string comparison to see of the value of the entity BEGINS with the value supplied' as Descr UNION ALL
	SELECT 22 as ID, 'Ends With' as Name, 'A string comparison to see of the value of the entity ENDS with the value supplied' as Descr UNION ALL
	SELECT 23 as ID, 'Len Between' as Name, 'The length of the entity''s value is "between" two values supplied in the Value field of the Condition, | delimited. IE: 2|6' as Descr UNION ALL
	SELECT 24 as ID, 'Len =' as Name, 'The length of the entity''s value is equal to a specified number' as Descr UNION ALL
	SELECT 25 as ID, 'Len !=' as Name, 'The length of the entity''s value is not equal to a specified number' as Descr UNION ALL
	SELECT 26 as ID, 'Len <' as Name, 'The length of the entity''s value is less than a specified number' as Descr UNION ALL
	SELECT 27 as ID, 'Len <=' as Name, 'The length of the entity''s value is less than or equal to a specified number' as Descr UNION ALL
	SELECT 28 as ID, 'Len >' as Name, 'The length of the entity''s value is greater than a specified number' as Descr UNION ALL
	SELECT 29 as ID, 'Len >=' as Name, 'The length of the entity''s value is greater than or equal to a specified number' as Descr UNION ALL
	SELECT 30 as ID, 'Type Matches' as Name, 'The "data type" of the field is consistent with a pre-defined "type" code' as Descr UNION ALL
	SELECT 31 as ID, '!Type Matches' as Name, 'The "data type" of the field is NOT consistent with a pre-defined "type" code' as Descr UNION ALL
	SELECT 32 as ID, 'Nest' as Name, 'Compare To Child Condition' as Descr UNION ALL
	SELECT 33 as ID, 'String =' as Name, 'A string comparison to ensure equal values' as Descr UNION ALL 
	SELECT 34 as ID, 'String !=' as Name, 'A string comparison to ensure unequal values' as Descr UNION ALL
	SELECT 35 as ID, 'Encounter should use ICD10' as Name, 'Encounter Should use ICD10' as Descr UNION ALL
	SELECT 36 as ID, 'Encounter should use ICD9' as Name, 'Encounter Should use ICD9' as Descr
GO

SET IDENTITY_INSERT [dve].[_CriteriaType] OFF;

COMMIT;