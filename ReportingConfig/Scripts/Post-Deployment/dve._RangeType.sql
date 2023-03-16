BEGIN TRANSACTION;

TRUNCATE TABLE [dve].[_RangeType];
GO

SET IDENTITY_INSERT [dve].[_RangeType] ON;

INSERT INTO [dve].[_RangeType] ( [ID], [Name], [Descr] )
	SELECT  1 as ID, 'List' as Name, 'A general, hard-coded list of values' as Descr UNION ALL
	SELECT  2 as ID, 'Lookup' as Name, 'A lookup table declaration is expected in the 1st value' as Descr UNION ALL
	SELECT  3 as ID, 'Between' as Name, '2 values are expected. A LOW value and a HIGH value (number, date, etc)' as Descr UNION ALL
	SELECT  4 as ID, 'Entity List' as Name, 'A list of ValueEntities.' as Descr UNION ALL
	SELECT  5 as ID, 'LookupRevenueCode' as Name, 'Looks up Revenue Code' as Descr;
GO

SET IDENTITY_INSERT [dve].[_RangeType] OFF;

COMMIT TRANSACTION;