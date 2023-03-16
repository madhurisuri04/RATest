CREATE VIEW [edt].[EditOverview] AS
SELECT 
	e.ID as DVEEditID
	, v.DataPath as EditEntity
	, tq1.Qualifier as EditQualifier
	, e.LOBCode
	, e.LOBState
	, e.EditTypeCode
	, isNULL(n2.num,0) as NumberOfEditConditions
	, isNULL(n1.num,0) as NumberOfRuleConditions
	, r.[Name] as RuleName
	, r.[Descr] as RuleDescr
	, vv.DataPath as TargetValueEntity
	, tq2.Qualifier as TargetValueQualifier
	, e.Value as TargetValue
	, ra.Name as RangeName
	, ra.Descr as RangeDescr
	, ct.Name as CriteriaType
	, ct.Descr as CriteriaTypeDescr
	, fvm.Message as ErrorMessage
	, e.ID as 'edt.Edit.ID'
	, e.RuleID as 'edt.Edit.RuleID'
	, e.EntityID as 'edt.Edit.EntityID'
	, e.TableQualifierID as 'edt.Edit.TableQualifierID'
	, e.ValueEntity as 'edt.Edit.ValueEntity'
	, e.ValueEntityQualifier as 'edt.Edit.ValueEntityQualifier'
	, e.Value as 'edt.Edit.Value'
	, e.RangeID as 'edt.Edit.RangeID'
	, e.TypeID as 'edt.Edit.TypeID'
	, e.FailedValidationMessage as 'edt.Edit.FailedValidationMessage'
FROM edt.Edit e
	CROSS APPLY (SELECT DISTINCT EntityID, DataPath FROM [edt].[EditEntityQualifierReference] WHERE e.EntityID = EntityID) v
	OUTER APPLY (SELECT DISTINCT EntityID, DataPath FROM [edt].[EditEntityQualifierReference] WHERE e.ValueEntity = EntityID) vv
	JOIN [edt].[Rule] r ON e.RuleID = r.ID
	LEFT JOIN [edt].[Range] ra ON e.RangeID = ra.ID
	LEFT JOIN [dve].[_CriteriaType] ct ON ct.ID = e.TypeID
	LEFT JOIN [dve].[TableQualifier] tq1 ON e.TableQualifierID = tq1.ID
	LEFT JOIN [dve].[TableQualifier] tq2 ON e.ValueEntityQualifier = tq2.ID
	LEFT JOIN [edt].[FailedValidationMessage] fvm ON fvm.ID = e.FailedValidationMessage
	OUTER APPLY (SELECT COUNT(1) as num FROM [edt].[RuleCondition] WHERE RuleID = e.RuleID) n1
	OUTER APPLY (SELECT COUNT(1) as num FROM [edt].[EditCondition] WHERE EditID = e.ID) n2
WHERE e.isActive = 1