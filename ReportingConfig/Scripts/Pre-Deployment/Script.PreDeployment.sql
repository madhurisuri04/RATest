/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

-- BEGIN IMPORT FROM CONFIGCOMMON --

if exists (select * from sys.objects where name = 'NonPayableCPTCode' and type = 'v')
begin
	DROP VIEW NonPayableCPTCode
end


IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[lk_ProcedureCodeModifier]'))
begin
	DROP VIEW [dbo].[lk_ProcedureCodeModifier]
end

-- END IMPORT FROM CONFIGCOMMON --
