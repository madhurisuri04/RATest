CREATE TABLE [dbo].[Rollup_Log]
(
	  Rollup_logID INT IDENTITY(1, 1) Not Null
	, DatabaseName VARCHAR(128) Not Null
	, PlanIdentifier INT Not Null
	, PlanID VARCHAR(5) Not Null
	, SourceTableName VARCHAR(128) Not Null
	, Start_Time DATETIME Null
	, End_Time DATETIME Null
	, Execution_Time VARCHAR(30) Null
	, Row_Count INT Null
	, TargetTableName VARCHAR(128) Null
	, RunGroup Char(2) Null
 )
 