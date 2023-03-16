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

------------------------------------------------------------

------------------------------------------------------------
---- Developer Scripts----------------------------------
------------------------------------------------------------

--:r EstRec_Summary_Setup.sql
--GO

:r LoadExtract.sql
GO
:r LoadExtractFile.sql
GO
:r LoadExtractStatus.sql
GO