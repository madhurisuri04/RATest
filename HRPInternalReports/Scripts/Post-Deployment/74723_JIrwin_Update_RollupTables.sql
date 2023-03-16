-- Add tbl_RAPS_Detail to rollup process and associated config table entries

DECLARE @Today DATETIME
SET @Today = GETDATE();

WITH [a1]
AS (
       SELECT [RollupTableName] = N'tbl_Plan_Claims_Validation_rollup'
            , [SourceTableName] = N'tbl_Plan_Claims_Validation'
            , [SourceTableSchema] = N'dbo'
            , [DateFieldForFilter] = N'LoadDate'
            , [DateFieldForFilterType] = N'Day'
            , [ExecutionSequenceNumber] = N'22'
            , [FilterValuesStartWithYear] = N'1'
   )
INSERT INTO [dbo].[RollupTable]
(
    [RollupTableName]
  , [SourceTableName]
  , [SourceTableSchema]
  , [DateFieldForFilter]
  , [DateFieldForFilterType]
  , [ExecutionSequenceNumber]
  , [FilterValuesStartWithYear]
  , [CreateDate]
)
SELECT [a1].[RollupTableName]
     , [a1].[SourceTableName]
     , [a1].[SourceTableSchema]
     , [a1].[DateFieldForFilter]
     , [a1].[DateFieldForFilterType]
     , [a1].[ExecutionSequenceNumber]
     , [a1].[FilterValuesStartWithYear]
     , [CreateDate] = @Today
FROM
(
    SELECT *
    FROM [a1]
    EXCEPT
    SELECT [RollupTableName]
         , [SourceTableName]
         , [SourceTableSchema]
         , [DateFieldForFilter]
         , [DateFieldForFilterType]
         , [ExecutionSequenceNumber]
         , [FilterValuesStartWithYear]
    FROM [dbo].[RollupTable]
) [a1]

DECLARE @RollUpTableId INT

SELECT @RollUpTableId = [a1].[RollupTableID]
FROM [dbo].[RollupTable] [a1]
WHERE [a1].[RollupTableName] = 'tbl_Plan_Claims_Validation_rollup'

INSERT INTO [dbo].[RollupTableConfig]
(
    [ClientIdentifier]
  , [RollupTableID]
  , [RollingYearsFilter]
  , [DynamicRollup]
  , [Active]
  , [IncludeNullDates]
  , [IncludeInvalidDates]
  , [CreateDate]
)
SELECT [a1].[ClientIdentifier]
     , [a1].[RollupTableID]
     , [a1].[RollingYearsFilter]
     , [a1].[DynamicRollup]
     , [a1].[Active]
     , [a1].[IncludeNullDates]
     , [a1].[IncludeInvalidDates]
     , [CreateDate] = @Today
FROM
(
    SELECT DISTINCT
           [ClientIdentifier] = [a1].[ClientIdentifier]
         , [RollupTableID] = @RollUpTableId
         , [RollingYearsFilter] = 4
         , [DynamicRollup] = 1
         , [Active] = 1
         , [IncludeNullDates] = 0
         , [IncludeInvalidDates] = 0
    FROM [dbo].[RollupClient] [a1]
    EXCEPT
    SELECT [ClientIdentifier]
         , [RollupTableID]
         , [RollingYearsFilter]
         , [DynamicRollup]
         , [Active]
         , [IncludeNullDates]
         , [IncludeInvalidDates]
    FROM [HRPInternalReports].[dbo].[RollupTableConfig]
) [a1]

INSERT INTO [dbo].[RollupTableStatus]
(
    [RollupTableConfigID]
  , [RollupStatus]
  , [RollupState]
  , [CreateDate]
  , [LastStateCheckDate]
)
SELECT DISTINCT
       [b1].[RollupTableConfigID]
     , [RollupStatus] = 'Stable'
     , [RollupState] = 'OutOfDate'
     , [CreateDate] = @Today
     , [LastStateCheckDate] = @Today
FROM [dbo].[RollupTableConfig] [b1]
WHERE [b1].[RollupTableID] = @RollUpTableId
      AND [b1].[RollupTableConfigID] NOT IN ( SELECT [RollupTableConfigID] FROM [dbo].[RollupTableStatus] )

-- Update the RollupState to 'OutOfDate' for 'tbl_Plan_Claims_Validation_rollup' so that the table is refreshed the next
-- time the rollup process runs.

UPDATE [HRPInternalReports].[dbo].[RollupTableStatus]
SET RollupState = 'OutOfDate'
WHERE RollupTableConfigID IN (
	SELECT rtc.RollupTableConfigID 
	FROM [HRPInternalReports].[dbo].[RollupTable] rt WITH (NOLOCK)
	INNER JOIN [HRPInternalReports].[dbo].[RollupTableConfig] rtc WITH (NOLOCK)
	ON rt.RollupTableID = rtc.RollupTableID
	WHERE RollupTableName = 'tbl_Plan_Claims_Validation_rollup'
)

-- Update [RollingYearsFilter] to 4 
UPDATE [HRPInternalReports].[dbo].[RollupTableConfig]
SET RollingYearsFilter = 4
WHERE RollupTableID IN (
	SELECT RollupTableID 
	FROM [HRPInternalReports].[dbo].[RollupTable] rt WITH (NOLOCK)
	WHERE RollupTableName = 'tbl_Plan_Claims_Validation_rollup'
)