CREATE VIEW [dve].[EntityReference] AS
SELECT
	e.ID as EntityID
	, e.TableDefinitionID
	, d.TableDatabase as 'Database'
	, d.TableSchema as 'Schema'
	, d.TableName as 'Table'
	, e.FieldName as 'Field'
	, CASE WHEN d.TableDatabase IS NULL THEN '' ELSE d.TableDatabase + '.' END + 
	  CASE WHEN d.TableSchema IS NULL THEN 'dbo.' ELSE d.TableSchema + '.' END +
	  d.TableName + '.' + e.FieldName as 'DataPath'
	, e.Name as 'QualifiedField'
	, e.isActive as EntityIsActive
	, e.ModifiedDT as EntityModifiedDT
	, e.Descr as EntityDescr
FROM dve.Entity e WITH(NOLOCK)
	JOIN dve.TableDefinition d WITH(NOLOCK) ON e.TableDefinitionID = d.ID