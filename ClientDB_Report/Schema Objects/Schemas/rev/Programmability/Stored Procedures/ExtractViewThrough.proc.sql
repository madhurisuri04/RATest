/****************************************************************************************************
Author:			Rakshit Lall
Date:			8/23/2017
Purpose:		To populate ViewThrough parameter for reports used for Extracts
Test :			EXEC rev.ExtractViewThrough
Test:			[him].[sprOperationalExtractViewThrough] 
*****************************************************************************************************/

CREATE PROCEDURE rev.ExtractViewThrough
AS

BEGIN

SET NOCOUNT ON;
	
	SELECT 0 AS Value, 'Extract' AS Label
	
	UNION ALL
	
	SELECT 1 AS Value, 'Report' AS Label
	
	ORDER BY Label

END