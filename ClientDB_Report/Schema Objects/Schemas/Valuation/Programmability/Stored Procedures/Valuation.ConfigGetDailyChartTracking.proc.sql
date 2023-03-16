CREATE PROC Valuation.ConfigGetDailyChartTracking
    (
     @ClientId INT
   , @AutoProcessRunId INT
   , @ClientReportDb VARCHAR(128)
   , @Debug BIT = 0
    )
AS
    SET STATISTICS IO OFF
    SET NOCOUNT ON

    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            SET @ET = GETDATE()
            SET @MasterET = @ET
        END

    DECLARE @DelSQL VARCHAR(1024)
    DECLARE @InsertSQL VARCHAR(4096)

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000', 0, 1) WITH NOWAIT
        END

    SET @DelSQL = '
	DELETE dct
	FROM [' + @ClientReportDb + '].[Valuation].[DailyChartTracking] dct
	WHERE [dct].[AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11))


/*B Temp for ReportingETL Environment */

    IF DB_NAME() = 'ReportingETL'
        BEGIN 
            SET @DelSQL = REPLACE(@DelSQL, '[' + @ClientReportDb + '].[HRP\mitch.casto].[DailyChartTracking]',
                                  '[ReportingETL].[HRP\mitch.casto].[DailyChartTracking]')

        END
/*E Temp for ReportingETL Environment */

	
    IF @Debug = 1
        BEGIN
            PRINT '--======================--'
            PRINT '@ClientReportDb: ' + @ClientReportDb
            PRINT '@AutoProcessRunId: ' + CAST(@AutoProcessRunId AS VARCHAR(11))
            PRINT '--======================--'
            PRINT @DelSQL
            PRINT '--======================--'
            RAISERROR('', 0, 1) WITH NOWAIT
        END

    EXEC(@DelSQL)


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('001', 0, 1) WITH NOWAIT
        END

    SET @InsertSQL = '
	INSERT INTO [Valuation].[DailyChartTracking] ( [AutoProcessRunId]
, [ClientId]
		, [ProjectID]
		, [SubprojectID]
		, [VeriskRequestID]
		, [PlanID]
		, [HICN]
		, [MemberDOB]
		, [ProviderID]
		, [SubprojectMedicalRecordID]
		, [CodingCompleteDate]
		, [LoadDate] )

	SELECT DISTINCT

		  [AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11)) + '
, [ClientId] = ' + CAST(@ClientId AS VARCHAR(11)) + '

		, [ProjectID] = cwfd.[ProjectID]
		, [SubprojectID] = cwfd.[SubprojectID]
		, [VeriskRequestID] = cwfd.[VeriskRequestID]
		, [PlanID] = cwfd.[PlanID]
		, [HICN] = cwfd.[HICN]
		, [MemberDOB] = cwfd.[MemberDOB]
		, [ProviderID] = cwfd.[ProviderID]
		, [SubprojectMedicalRecordID] = cwfd.[SubprojectMedicalRecordID]
		, [CodingCompleteDate] = MAX(cwfd.[CodingCompleteDate])
		, [LoadDate] = cwfd.[LoadDate]
	FROM [' + @ClientReportDb + '].[dbo].[CWFDetails] cwfd
	WHERE cwfd.[CurrentImageStatus] IN (''ready for release'',''cannot be coded'',''coding/review complete'')
	GROUP BY cwfd.[ProjectID]
	,        cwfd.[SubprojectID]
	,        cwfd.[PlanID]
	,        cwfd.[HICN]
	,        cwfd.[ProviderID]
	,        cwfd.[SubprojectMedicalRecordID]
	,        cwfd.[VeriskRequestID]
	,        cwfd.[LoadDate]
	,        cwfd.[MemberDOB]
'


    IF @Debug = 1
        BEGIN
            PRINT '--======================--'
            PRINT '@ClientReportDb: ' + @ClientReportDb
            PRINT '@AutoProcessRunId: ' + CAST(@AutoProcessRunId AS VARCHAR(11))
            PRINT '--======================--'
            PRINT @InsertSQL
            PRINT '--======================--'
        END
        
    EXEC (@InsertSQL)

    IF @Debug = 1
        BEGIN

            SELECT
                *
            FROM
                [Valuation].[DailyChartTracking] dct WITH (NOLOCK)
            WHERE
                [dct].[AutoProcessRunId] = @AutoProcessRunId

            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE()
                - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('002', 0, 1) WITH NOWAIT
            PRINT 'Total ET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('Done.|', 0, 1) WITH NOWAIT
        END

