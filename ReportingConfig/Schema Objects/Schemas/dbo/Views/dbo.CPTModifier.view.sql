CREATE VIEW [dbo].[CPTModifier] as
SELECT [CPTModifierID]
      ,[Modifier]
      ,[ModifierDescription]
      ,[BeginEffectiveDate]
      ,[EndEffectiveDate]
      ,[CreatedDate]
      ,[LastModifiedDate]
FROM [$(HRPReporting)].[dbo].[CPTModifier]