CREATE PROCEDURE [dbo].[GeneratePostDeploymentScript] (
	@schema		VARCHAR(3),
  	@table		VARCHAR(120)
)
AS

/*
	RUN THIS IN LINQPAD FOR LARGE TABLES
	MAY BE FINE FOR SMALL TABLES IN SQL MANAGEMENT STUDIO
*/

DECLARE @tableID	INT				= 0
DECLARE @colNames	NVARCHAR(max)	= N''
DECLARE @cols		NVARCHAR(max)	= N''
DECLARE @sql		NVARCHAR(MAX)	= N''

SELECT @tableID = object_id FROM sys.tables 
WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = @schema) 
	AND name = @table

DECLARE @pk VARCHAR(120)
SELECT @pk = name FROM ( SELECT TOP(1) name FROM sys.columns WHERE object_id = @tableID AND is_identity = 1 ) as t

SELECT @colNames = [columns] FROM (
	SELECT DISTINCT [columns] FROM (
		SELECT STUFF((SELECT ',' + nm
			FROM (
				SELECT 
					DISTINCT
					sc.column_id,
					'[' + sc.name + ']' as nm
				FROM sys.columns sc JOIN sys.types st ON sc.system_type_id = st.system_type_id
				WHERE object_id = @tableID
			) as z
			ORDER BY column_id 
			FOR XML PATH('')),1,1,'' ) AS 'columns'
		FROM sys.columns
	) as x
) as y

SELECT @cols = [columns] FROM (
	SELECT DISTINCT [columns] FROM (
		SELECT STUFF((SELECT '|' + nm
			FROM (
				SELECT 
					DISTINCT
					sc.column_id,
					'CASE WHEN ' + sc.name + ' IS NULL THEN ''NULL'' ELSE ' + 
					CASE WHEN st.name IN ( 'int', 'bigint', 'bit', 'decimal', 'binary', 'float' ) 
					THEN 'CAST(' + sc.name + ' as VARCHAR(100))'
					ELSE REPLACE('ææ + REPLACE(' + sc.name + ', ææ, æææ) + ææ', 'æ', '''''')
					END + ' END' as nm
				FROM sys.columns sc JOIN sys.types st ON sc.system_type_id = st.system_type_id
				WHERE object_id = @tableID
			) as z
			ORDER BY column_id 
			FOR XML PATH('')),1,1,'' ) AS 'columns'
		FROM sys.columns
	) as x
) as y

DECLARE @ins NVARCHAR(max) = '''INSERT INTO [' + @schema + '].[' + @table + '] (' + @colNames + ')'''
DECLARE @go NVARCHAR(6) = '''GO'''

SET @sql = N'
DECLARE @tbl TABLE ( mod bigint, diffBefore bit, diffAfter bit, ID bigint, sqlcommand varchar(max) );

WITH sqlcommands AS (
	SELECT [' + @pk + '] / 250 as mod, [' + @pk + '] as ID, ''ÆSELECT '' + ' + REPLACE(@cols, '|', ' + '', '' + ') + ' + ''ö'' as sqlcommand FROM [' + @schema + '].[' + @table + '] UNION ALL
	SELECT 0 as mod, 0 as ID, NULL as sqlcommand
)
INSERT INTO @tbl
SELECT b.mod, CASE WHEN a.mod = b.mod THEN 0 ELSE 1 END, CASE WHEN c.mod = b.mod THEN 0 ELSE 1 END, b.ID, b.sqlcommand
FROM (SELECT * FROM sqlcommands WHERE NOT (mod = 0 AND ID = 0)) b 
FULL OUTER JOIN (SELECT * FROM sqlcommands WHERE NOT (mod = 0 AND ID = 0)) a ON a.ID = b.ID - 1 
FULL OUTER JOIN (SELECT * FROM sqlcommands WHERE NOT (mod = 0 AND ID = 0)) c ON c.ID = b.ID + 1

SELECT ''/* AUTO-GENERATED AND COPY-PASTED FROM LINQPAD, SEE END OF FILE FOR GENERATION COMMAND */'' UNION ALL
SELECT ''BEGIN TRANSACTION;'' UNION ALL
SELECT '''' UNION ALL
SELECT ''TRUNCATE TABLE [' + @schema + '].[' + @table + '];'' UNION ALL
SELECT ''GO'' UNION ALL
SELECT '''' UNION ALL
SELECT ''SET IDENTITY_INSERT [' + @schema + '].[' + @table + '] ON;'' UNION ALL
SELECT '''' UNION ALL
SELECT REPLACE( REPLACE( sqlcommand
	, ''Æ'', CASE WHEN diffBefore = 1 THEN ' + @ins + ' + CHAR(10) + ''    '' ELSE '''' END + ''    '' )
    , ''ö'', CASE WHEN diffAfter  = 1 THEN CHAR(10) + ''    '' + ' + @go + ' ELSE '' UNION ALL'' END
)
as SQL FROM @tbl WHERE mod IS NOT NULL UNION ALL
SELECT '''' UNION ALL
SELECT ''SET IDENTITY_INSERT [' + @schema + '].[' + @table + '] OFF;'' UNION ALL
SELECT '''' UNION ALL
SELECT ''COMMIT;'' UNION ALL
SELECT '''' UNION ALL
SELECT '''' UNION ALL
SELECT ''/* TO REGENERATE THIS FILE EXECUTE THE FOLLOWING STATEMENT IN LINQPAD WITH RESULTS TO GRID */'' UNION ALL
SELECT ''/* THEN COPY THE ENTIRE RESULTS GRID USING TOP LEFT CORNER AND CTRL+C AND PASTE IT OVER THIS ENTIRE FILE */'' UNION ALL
SELECT ''/*     EXEC [dbo].[GeneratePostDeploymentScript] ''''' + @schema + ''''', ''''' + @table + ''''' */'' UNION ALL
SELECT ''/* EVEN THE COMMENTS WILL BE RECREATED WHEN THIS SCRIPT IS RUN */''
'

EXEC sp_executesql @sql
