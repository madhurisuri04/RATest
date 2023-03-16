CREATE PROCEDURE [Valuation].[ConfigInsertConfigClientPlan]
	
AS

/**************************************************************************************************************************************************************   
* Version History :                                                                                                                                           *
*  Author			Date		Version#    TFS Ticket#	      Description                                                                                     *
* -----------------	----------  --------    -----------	      ------------                                                                                    *
*                                                                                                                                                             *
*  D Waddell 		04/19/2016   1.0		   52222		  checks for new plan information and populates the Valuation.ConfigClientPlan table              *
*															                                                                                                  *
*															  	                                                                                              *
*                                                                                                                                                             *
**************************************************************************************************************************************************************/   



DECLARE @ClientCoreDbName VARCHAR(128) 
DECLARE @ConfigClientMainId INT
DECLARE @ClientId INT 


    SET NOCOUNT ON 

/*B Add new plan databases */

SET @ClientCoreDbName = LEFT(DB_NAME(), PATINDEX('%[_]Report%', DB_NAME()) - 1)

SELECT
    @ConfigClientMainId = [ConfigClientMainId]
  , @ClientId = [ClientId]
FROM
    [Valuation].[ConfigClientMain]

/* Insert into ConfigClientPlan  */;
WITH    [CTE_a1]
          AS (SELECT
                [ConfigClientMainId] = @ConfigClientMainId
              , [PlanId] = @ClientCoreDbName
              , [ClientId] = @ClientId
              , [PlanDb] = [db].[name]
              , [Priority] = 99
              , [ActiveBDate] = CAST(GETDATE() AS DATE)
              FROM
                [sys].[databases] [db] WITH (NOLOCK)
              WHERE
                [db].[name] LIKE @ClientCoreDbName + '[_][A-Z][0-9]%'
             )
    INSERT INTO [Valuation].[ConfigClientPlan] ([ConfigClientMainId]
  , [ClientId]
 , [PlanId]
  , [PlanDb]
  , [Priority]
  , [ActiveBDate])
SELECT
    [a1].[ConfigClientMainId]
  , [a1].[ClientId]
  , [a1].[PlanId]
  , [a1].[PlanDb]
  , [a1].[Priority]
  , [a1].[ActiveBDate]
FROM
    [CTE_a1] [a1]
WHERE
    NOT EXISTS ( SELECT
                    *
                 FROM
                    [Valuation].[ConfigClientPlan] [ccp]
                 WHERE
                    [a1].[ClientId] = [ccp].[ClientId]
                    AND [a1].[PlanDb] = [ccp].[PlanDb] )
     
/*E Add new plan databases */


            RETURN 0
   

