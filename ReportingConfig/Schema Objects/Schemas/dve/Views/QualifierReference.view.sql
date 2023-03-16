CREATE VIEW [dve].[QualifierReference] AS
SELECT q.ID
	, q.TableDefinitionID
	, q.Name
	, q.Descr
	, CASE WHEN d.TableDatabase IS NULL THEN '' ELSE d.TableDatabase + '.' END + 
	  CASE WHEN d.TableSchema IS NULL THEN 'dbo.' ELSE d.TableSchema + '.' END +
	  d.TableName as 'TableDefinition'
	, q.QualifiedFieldName
	, q.Qualifier
FROM dve.TableQualifier q
	JOIN dve.TableDefinition d ON q.TableDefinitionID = d.ID