UPDATE [HRPInternalReports].[dbo].[RollupTable]
SET DateFieldForFilter = 'Populated'
WHERE RollupTableID IN (
	SELECT RollupTableID
	FROM  HRPInternalReports.dbo.RollupTable
	WHERE RollupTableName = 'tbl_Plan_Claims_rollup'
)

UPDATE [HRPInternalReports].[dbo].[RollupTableConfig]
SET RollingYearsFilter = 4
WHERE RollupTableID IN (
	SELECT RollupTableID
	FROM  HRPInternalReports.dbo.RollupTable
	WHERE RollupTableName IN ('tbl_Plan_Claims_rollup', 'tbl_RAPS_Detail_rollup')
)

UPDATE [HRPInternalReports].[dbo].[RollupTableStatus]
SET RollupState = 'OutOfDate'
WHERE RollupTableConfigID IN (
	SELECT rtc.RollupTableConfigID 
	FROM [HRPInternalReports].[dbo].[RollupTable] rt WITH (NOLOCK)
	INNER JOIN [HRPInternalReports].[dbo].[RollupTableConfig] rtc WITH (NOLOCK)
	ON rt.RollupTableID = rtc.RollupTableID
	WHERE RollupTableName IN ('tbl_Plan_Claims_rollup', 'tbl_RAPS_Detail_rollup')
)