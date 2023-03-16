CREATE VIEW [dve].[LineOfBusinessReference] AS
SELECT
	l.LOBCode
	, l.BitValue
	, l.Descr
	, l.EnableEdits
	, l.EnableTransforms
	, e.LineOfBusinessID as ExternalID
	, e.LineOfBusinessCode as ExternalCode
	, e.LineOfBusinessDescription as ExternalDescr
FROM [dve].[_LOBCode] l WITH(NOLOCK)
	LEFT OUTER JOIN [ref].[LineOfBusiness] e WITH(NOLOCK)
		ON UPPER(l.Descr) = UPPER(e.LineOfBusinessCode)