CREATE VIEW [dve].[StateCodeReference] AS
SELECT
	l.LOBStateID
	, l.BitValue
	, l.LOBState
	, l.EnableEdits
	, l.EnableTransforms
	, e.StateCodeID as ExternalStateID
	, e.StateCode as ExternalState
	, e.IsDualSplitState
FROM [dve].[_LOBState] l WITH(NOLOCK)
	LEFT OUTER JOIN [ref].[StateCode] e WITH(NOLOCK)
		ON UPPER(e.StateCode) = UPPER(l.LOBState)
