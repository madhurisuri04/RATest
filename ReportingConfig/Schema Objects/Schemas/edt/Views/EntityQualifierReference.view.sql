CREATE VIEW [edt].[EditEntityQualifierReference] AS
SELECT
	e.ID as EntityID
	, ed.TableQualifierID
	, e.TableDefinitionID
	, d.TableDatabase as 'Database'
	, d.TableSchema as 'Schema'
	, d.TableName as 'Table'
	, e.FieldName as 'Field'
	, q.Qualifier as 'Qual'
	, CASE WHEN d.TableDatabase IS NULL THEN '' ELSE d.TableDatabase + '.' END + 
	  CASE WHEN d.TableSchema IS NULL THEN 'dbo.' ELSE d.TableSchema + '.' END +
	  d.TableName + '.' + e.FieldName as 'DataPath'
	, q.Name as 'QualifiedRow'
	, e.Name as 'QualifiedField'
	, e.isActive as EntityIsActive
	, e.ModifiedDT as EntityModifiedDT
	, q.Descr as QualifierDescr
	, e.Descr as EntityDescr
FROM edt.Edit ed WITH(NOLOCK) 
	JOIN dve.Entity e WITH(NOLOCK) ON ed.EntityID = e.ID
	JOIN dve.TableDefinition d WITH(NOLOCK) ON e.TableDefinitionID = d.ID
	LEFT OUTER JOIN dve.TableQualifier q WITH(NOLOCK) ON ed.TableQualifierID = q.ID