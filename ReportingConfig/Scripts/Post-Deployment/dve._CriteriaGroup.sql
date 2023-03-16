
BEGIN TRANSACTION;

TRUNCATE TABLE [dve].[_CriteriaGroup];
GO

INSERT INTO [dve].[_CriteriaGroup] (GroupName) VALUES
	('C# Controls'),
	('Exists Bools'),
	('RegEx Compares'),
	('Value Compares'),
	('Counts'),
	('Range Compares'),
	('String Contents'),
	('Lengths'),
	('Format Type Codes');
GO

COMMIT;