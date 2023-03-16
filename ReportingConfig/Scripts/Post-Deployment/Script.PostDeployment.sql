/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

---ADMIN - Configuration Management ONLY----

-- BEGIN IMPORT FROM CONFIGCOMMON --

------------------------------------------------------------
---- Developer Scripts----------------------------------
------------------------------------------------------------

:r ref.LineOfBusiness.sql
go

:r ref.StateCode.sql
go

:r DVE_DROP_FK.sql
go

:r dve._CriteriaGroup.sql
go

:r dve._CriteriaTypeGroup.sql
go

:r dve._LOBCode.sql
go

:r dve._LOBState.sql
go

:r edt._EditTypeCode.sql
go

:r dve._CriteriaType.sql
go

:r dve._RangeType.sql
go

:r dve.TableDefinition.sql
go

:r dve.TableQualifier.sql
go

:r dve.Entity.sql
go

:r edt.Rule.sql
go

:r edt.FailedValidationSeverity.sql
go

:r edt.FailedValidationMessage.sql
go

:r edt.Condition.sql
go

:r edt.RuleCondition.sql
go

:r edt.Range.sql
go

:r edt.RangeValue.sql
go

:r edt.Edit.sql
go

:r edt.EditCondition.sql
go

:r DVE_ADD_FK.sql
go

:r dbo.OrganizationVendor.sql
go

:r dbo.ETLValidation.sql
go

:r dbo.ETLValidationLOBState.sql
go

:r dbo.ETLDerivedValue.sql
go

:r dbo.EDSPlatformInstance.sql
go

:r DropTable.sql
go

:r dbo.OrganizationContract.sql
go

:r dbo.EnvironmentIndicator_DEV.sql
go

:r dbo.EnvironmentIndicator_UAT.sql
go

:r dbo.EnvironmentIndicator_RGS.sql
go

:r dbo.EnvironmentIndicator_PRD.sql
go

:r dbo.EnvironmentIndicator_CSB.sql
go

-- END IMPORT FROM CONFIGCOMMON --

------------------------------------------------------------
---- Developer Scripts----------------------------------
------------------------------------------------------------

:r ConfigurationDefinition.sql
GO

:r Organization.sql
GO

:r ApplicationConfiguration_DEV.sql
GO

:r ApplicationConfiguration_TST.sql
GO

:r ApplicationConfiguration_UAT.sql
GO

--:r ApplicationConfiguration_CSB.sql
--GO

:r ApplicationConfiguration_PRD.sql
GO

:r FileType.sql
GO

:r FileTypeFormatRuleType.sql
GO

:r FileTypeFormat.sql
GO

:r FileTypeFormatRule.sql
GO

:r EdgeReportClientConfiguration.sql
GO
:r EdgeReportClientStatus.sql
GO
:r EdgeReportConfiguration.sql
GO
:r RiskModelControlDate.sql
Go

:r RiskModelClientMap.sql
Go

:r ReportingLogCategories.sql
Go

:r log.ReportingLogControl.sql
Go

:r BaselineClientConfiguration.sql
GO

:r RptOpsMetricsConfiguration.sql
GO

:r dbo.Organization.sql
GO
