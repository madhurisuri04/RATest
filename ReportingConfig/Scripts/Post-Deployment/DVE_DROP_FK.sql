IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK__CriteriaColumnMap_CriteriaGroup')
	ALTER TABLE [dve].[_CriteriaColumnMap]  DROP  CONSTRAINT [FK__CriteriaColumnMap_CriteriaGroup];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK__CriteriaTypeGroup_CriteriaGroup')
	ALTER TABLE [dve].[_CriteriaTypeGroup]  DROP  CONSTRAINT [FK__CriteriaTypeGroup_CriteriaGroup];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK__CriteriaTypeGroup_CriteriaType')
	ALTER TABLE [dve].[_CriteriaTypeGroup]  DROP  CONSTRAINT [FK__CriteriaTypeGroup_CriteriaType];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Entity_TableDefinition')
	ALTER TABLE [dve].[Entity]  DROP  CONSTRAINT [FK_Entity_TableDefinition];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_TableQualifier_TableDefinition')
	ALTER TABLE [dve].[TableQualifier]  DROP  CONSTRAINT [FK_TableQualifier_TableDefinition];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Condition_CriteriaType')
	ALTER TABLE [edt].[Condition]  DROP  CONSTRAINT [FK_Condition_CriteriaType];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Condition_Entity')
	ALTER TABLE [edt].[Condition]  DROP  CONSTRAINT [FK_Condition_Entity];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Condition_Range')
	ALTER TABLE [edt].[Condition]  DROP  CONSTRAINT [FK_Condition_Range];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Condition_TableQualifier')
	ALTER TABLE [edt].[Condition]  DROP  CONSTRAINT [FK_Condition_TableQualifier];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Edit_CriteriaType')
	ALTER TABLE [edt].[Edit]  DROP  CONSTRAINT [FK_Edit_CriteriaType];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Edit_Entity')
	ALTER TABLE [edt].[Edit]  DROP  CONSTRAINT [FK_Edit_Entity];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Edit_Range')
	ALTER TABLE [edt].[Edit]  DROP  CONSTRAINT [FK_Edit_Range];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Edit_Rule')
	ALTER TABLE [edt].[Edit]  DROP  CONSTRAINT [FK_Edit_Rule];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Edit_TableQualifier')
	ALTER TABLE [edt].[Edit]  DROP  CONSTRAINT [FK_Edit_TableQualifier];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Edit_TableQualifier2')
	ALTER TABLE [edt].[Edit]  DROP  CONSTRAINT [FK_Edit_TableQualifier2];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_EditCondition_Condition')
	ALTER TABLE [edt].[EditCondition]  DROP  CONSTRAINT [FK_EditCondition_Condition];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_EditCondition_Edit')
	ALTER TABLE [edt].[EditCondition]  DROP  CONSTRAINT [FK_EditCondition_Edit];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Range_RangeType')
	ALTER TABLE [edt].[Range]  DROP  CONSTRAINT [FK_Range_RangeType];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_RangeValue_Entity')
	ALTER TABLE [edt].[RangeValue]  DROP  CONSTRAINT [FK_RangeValue_Entity];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_RangeValue_Range')
	ALTER TABLE [edt].[RangeValue]  DROP  CONSTRAINT [FK_RangeValue_Range];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_RangeValue_TableQualifier')
	ALTER TABLE [edt].[RangeValue]  DROP  CONSTRAINT [FK_RangeValue_TableQualifier];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_RuleCondition_Condition')
	ALTER TABLE [edt].[RuleCondition]  DROP  CONSTRAINT [FK_RuleCondition_Condition];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_RuleCondition_Rule')
	ALTER TABLE [edt].[RuleCondition]  DROP  CONSTRAINT [FK_RuleCondition_Rule];
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_FailedValidationMessage_FailedValidationSeverity')
	ALTER TABLE [edt].[FailedValidationMessage]  DROP  CONSTRAINT [FK_FailedValidationMessage_FailedValidationSeverity]
GO