CREATE VIEW [edt].[RuleConditionOverview] AS
SELECT 
	e.DVEEditID
	, e.EditEntity
	, e.EditQualifier
	, e.LOBCode
	, e.LOBState
	, e.EditTypeCode
	, e.RuleName
	, e.RuleDescr
	, e.TargetValueEntity
	, e.TargetValueQualifier
	, e.TargetValue
	, e.RangeName
	, e.CriteriaType
	, CASE WHEN isNULL(e1.TrueOnANYCondition,0) = 1 THEN 'OR' ELSE 'AND' END as EditConditionGrouping
	, isNULL(ec.ParentID,0) as ParentRuleConditionID
	, ec.ConditionID as RuleConditionID
	, CASE WHEN isNULL(ec.isMet,0) = 1 THEN 'Positive' ELSE 'Negative' END as DesiredMatchState
	, CASE WHEN isNULL(ec.TrueOnANYChildCondition,0) = 1 THEN 'OR' ELSE 'AND' END as RuleChildConditionGrouping
	, c.Name as RuleConditionName
	, c.Descr as RuleConditionDescr
	, vv.DataPath as RuleConditionEntity
	, tq1.Qualifier as RuleConditionQualifier
	, c.Value as RuleConditionValue
	, ra.Name as RuleConditionRangeName
	, ra.Descr as RuleConditionRangeDescr
	, ct.Name as RuleConditionCriteriaType
	, ct.Descr as RuleConditionCriteriaTypeDescr
	, fvm2.Message as RuleConditionDefaultErrorMessage
	, c.FailedValidationMessage as RuleConditionDefaultErrorMessageID
	, c.ID as 'edt.Condition.ID'
	, c.ValueEntity as 'edt.Condition.ValueEntity'
	, c.ValueEntityQualifier as 'edt.Condition.ValueEntityQualifier'
	, c.Value as 'edt.Condition.Value'
	, c.RangeID as 'edt.Condition.RangeID'
	, c.TypeID as 'edt.Condition.TypeID'
	, c.FailedValidationMessage as 'edt.Condition.FailedValidationMessage'
FROM (
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
	) e
	JOIN [edt].[Edit] e1 ON e.DVEEditID = e1.ID
	JOIN [edt].[RuleCondition] ec ON e.[edt.Edit.RuleID] = ec.RuleID
	JOIN [edt].[Condition] c ON c.ID = ec.ConditionID
	LEFT JOIN [edt].[FailedValidationMessage] fvm2 ON fvm2.ID = c.FailedValidationMessage
	OUTER APPLY (SELECT DISTINCT EntityID, DataPath FROM [edt].[EditEntityQualifierReference] WHERE c.ValueEntity = EntityID) vv
	LEFT JOIN [dve].[TableQualifier] tq1 ON c.ValueEntityQualifier = tq1.ID
	LEFT JOIN [edt].[Range] ra ON c.RangeID = ra.ID
	LEFT JOIN [dve].[_CriteriaType] ct ON ct.ID = c.TypeID
WHERE e.NumberOfRuleConditions > 0
	AND c.isActive = 1