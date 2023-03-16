ALTER TABLE [dve].[_CriteriaColumnMap]  WITH CHECK ADD  CONSTRAINT [FK__CriteriaColumnMap_CriteriaGroup] FOREIGN KEY([GroupID])
REFERENCES [dve].[_CriteriaGroup] ([GroupID])
GO

ALTER TABLE [dve].[_CriteriaTypeGroup]  WITH CHECK ADD  CONSTRAINT [FK__CriteriaTypeGroup_CriteriaGroup] FOREIGN KEY([GroupID])
REFERENCES [dve].[_CriteriaGroup] ([GroupID])
GO

ALTER TABLE [dve].[_CriteriaTypeGroup]  WITH CHECK ADD  CONSTRAINT [FK__CriteriaTypeGroup_CriteriaType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_CriteriaType] ([ID])
GO

ALTER TABLE [dve].[Entity]  WITH CHECK ADD  CONSTRAINT [FK_Entity_TableDefinition] FOREIGN KEY([TableDefinitionID])
REFERENCES [dve].[TableDefinition] ([ID])
GO

ALTER TABLE [dve].[TableQualifier]  WITH CHECK ADD  CONSTRAINT [FK_TableQualifier_TableDefinition] FOREIGN KEY([TableDefinitionID])
REFERENCES [dve].[TableDefinition] ([ID])
GO

ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_CriteriaType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_CriteriaType] ([ID])
GO

ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_Entity] FOREIGN KEY([ValueEntity])
REFERENCES [dve].[Entity] ([ID])
GO

ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_Range] FOREIGN KEY([RangeID])
REFERENCES [edt].[Range] ([ID])
GO

ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_TableQualifier] FOREIGN KEY([ValueEntityQualifier])
REFERENCES [dve].[TableQualifier] ([ID])
GO

ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_CriteriaType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_CriteriaType] ([ID])
GO

ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_Entity] FOREIGN KEY([EntityID])
REFERENCES [dve].[Entity] ([ID])
GO

ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_Range] FOREIGN KEY([RangeID])
REFERENCES [edt].[Range] ([ID])
GO

ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_Rule] FOREIGN KEY([RuleID])
REFERENCES [edt].[Rule] ([ID])
GO

ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_TableQualifier] FOREIGN KEY([TableQualifierID])
REFERENCES [dve].[TableQualifier] ([ID])
GO

ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_TableQualifier2] FOREIGN KEY([ValueEntityQualifier])
REFERENCES [dve].[TableQualifier] ([ID])
GO

ALTER TABLE [edt].[EditCondition]  WITH CHECK ADD  CONSTRAINT [FK_EditCondition_Condition] FOREIGN KEY([ConditionID])
REFERENCES [edt].[Condition] ([ID])
GO

ALTER TABLE [edt].[EditCondition]  WITH CHECK ADD  CONSTRAINT [FK_EditCondition_Edit] FOREIGN KEY([EditID])
REFERENCES [edt].[Edit] ([ID])
GO

ALTER TABLE [edt].[Range]  WITH CHECK ADD  CONSTRAINT [FK_Range_RangeType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_RangeType] ([ID])
GO

ALTER TABLE [edt].[RangeValue]  WITH CHECK ADD  CONSTRAINT [FK_RangeValue_Entity] FOREIGN KEY([ValueEntity])
REFERENCES [dve].[Entity] ([ID])
GO

ALTER TABLE [edt].[RangeValue]  WITH CHECK ADD  CONSTRAINT [FK_RangeValue_Range] FOREIGN KEY([RangeID])
REFERENCES [edt].[Range] ([ID])
GO

ALTER TABLE [edt].[RangeValue]  WITH CHECK ADD  CONSTRAINT [FK_RangeValue_TableQualifier] FOREIGN KEY([ValueEntityQualifier])
REFERENCES [dve].[TableQualifier] ([ID])
GO

ALTER TABLE [edt].[RuleCondition]  WITH CHECK ADD  CONSTRAINT [FK_RuleCondition_Condition] FOREIGN KEY([ConditionID])
REFERENCES [edt].[Condition] ([ID])
GO

ALTER TABLE [edt].[RuleCondition]  WITH CHECK ADD  CONSTRAINT [FK_RuleCondition_Rule] FOREIGN KEY([RuleID])
REFERENCES [edt].[Rule] ([ID])
GO

ALTER TABLE [edt].[FailedValidationMessage]  WITH CHECK ADD  CONSTRAINT [FK_FailedValidationMessage_FailedValidationSeverity] FOREIGN KEY([Severity])
REFERENCES [edt].[FailedValidationSeverity] ([ID])
GO