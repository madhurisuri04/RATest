
BEGIN TRANSACTION;

TRUNCATE TABLE [dve].[_CriteriaTypeGroup];
GO

INSERT INTO [dve].[_CriteriaTypeGroup] (GroupID, TypeID) VALUES (1, 0);
GO

INSERT INTO [dve].[_CriteriaTypeGroup] (GroupID, TypeID)
	SELECT 2, ID FROM [dve].[_CriteriaType] WHERE ID IN (1,2) UNION ALL
	SELECT 3, ID FROM [dve].[_CriteriaType] WHERE ID IN (3,4) UNION ALL
	SELECT 4, ID FROM [dve].[_CriteriaType] WHERE ID >= 5 AND ID <= 10 UNION ALL
	SELECT 5, ID FROM [dve].[_CriteriaType] WHERE ID >= 11 AND ID <= 16 UNION ALL
	SELECT 6, ID FROM [dve].[_CriteriaType] WHERE ID >= 17 AND ID <= 19 UNION ALL
	SELECT 7, ID FROM [dve].[_CriteriaType] WHERE ID >= 20 AND ID <= 22 UNION ALL
	SELECT 8, ID FROM [dve].[_CriteriaType] WHERE ID >= 23 AND ID <= 29 UNION ALL
	SELECT 9, ID FROM [dve].[_CriteriaType] WHERE ID IN (30,31);
GO

COMMIT;