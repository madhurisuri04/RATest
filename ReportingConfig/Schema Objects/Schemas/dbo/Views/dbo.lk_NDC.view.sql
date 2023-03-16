CREATE VIEW [dbo].[lk_NDC]	AS 
SELECT  NDC, DateObsolete, DateAdded
FROM [$(HRPReporting)].[dbo].[lk_NDC]