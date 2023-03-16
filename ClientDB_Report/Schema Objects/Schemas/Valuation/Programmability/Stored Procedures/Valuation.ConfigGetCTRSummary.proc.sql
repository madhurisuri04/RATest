CREATE PROC [Valuation].[ConfigGetCTRSummary]
    @CTRSummaryServer VARCHAR(128)
  , @CTRSummaryDb VARCHAR(128)
  , @LoadDate DATE
  , @AutoProcessRunId INT
  , @ClientID INT
  , @Debug BIT = 0
AS

    --
    /************************************************************************************************************************ 
* Name			:	Valuation.ConfigGetCTRSummary    																	*
* Type 			:	Stored Procedure																					*
* Author       	:	Mitch Casto																							*
* Date			:	2015-04-21																							*
* Version			:																									*
* Description		:																									*
*																														*
* Version History :																										*
* =================																										*
* Author			Date			Version#    TFS Ticket#		Description												*
* -----------------	----------		--------    -----------		------------											*
* MCasto			2016-11-17		1.1			59770			Changed column name from  ChartsVHRetrieved to			*
*																ChartsRetrieved	on										*
*																@CTRSummaryServer.@CTRSummaryDb.dbo.CTR_Summary			*
*																(Section 000)											*																		*
*																														*
************************************************************************************************************************/

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

    DECLARE @GetDataSQL VARCHAR(4096)
    DECLARE @RecordCount INT = 0

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000', 0, 1) WITH NOWAIT
        END

    SET @GetDataSQL
        = '
SELECT  
[AutoProcessRunId] = ' + CAST(@AutoProcessRunId AS VARCHAR(11))
          + '
, [ClientId] = a1.[ClientId]
, [ProjectId] = a1.[ProjectId]
, [SubProjectID] = a1.[SubProjectID]
, [LoadDate] = a1.[LoadDate]
, [ChartsRequested] = ISNULL(SUM(a1.[ChartsRequested]), 0)
, [ChartsVHRetrieved] = ISNULL(SUM(a1.[ChartsRetrieved]), 0)
, [ChartsAdded] = ISNULL(SUM(a1.[ChartsAdded]), 0)
, [ChartsFPC] = ISNULL(SUM(a1.[ChartsFPC]), 0)
, [ChartsComplete] = ISNULL(SUM(a1.[ChartsComplete]), 0)
, [ClientCodingCompleteDate] = a1.[ClientCodingCompleteDate]
FROM [' + @CTRSummaryServer + '].[' + @CTRSummaryDb + '].[dbo].[CTR_Summary] a1 WITH (NOLOCK)
WHERE a1.[ClientId] = ' + CAST(@ClientID AS VARCHAR(11)) + ' AND a1.[LoadDate] = '''
          + CONVERT(CHAR(10), @LoadDate, 101)
          + ''' 

GROUP BY a1.[ClientId]
, a1.[ProjectId]
, a1.[SubProjectID]
, a1.[LoadDate]
, a1.[ClientCodingCompleteDate]
'

    IF @Debug = 1
        BEGIN
            PRINT '--======================--'
            PRINT '@AutoProcessRunId: ' + CAST(@AutoProcessRunId AS VARCHAR(11))
            PRINT '@CTRSummaryServer: ' + @CTRSummaryServer
            PRINT '@CTRSummaryDb: ' + @CTRSummaryDb
            PRINT '@ClientID: ' + CAST(@ClientID AS VARCHAR(11))
            PRINT '@LoadDate: ' + CONVERT(CHAR(10), @LoadDate, 101)

            PRINT '--======================--'
            PRINT @GetDataSQL
            PRINT '--======================--'
            RAISERROR('', 0, 1) WITH NOWAIT
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('001', 0, 1) WITH NOWAIT
        END

    DELETE [m]
      FROM [Valuation].[ValCTRSummary] [m]
     WHERE [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('002', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[ValCTRSummary] ([AutoProcessRunId]
                                           , [ClientId]
                                           , [ProjectId]
                                           , [SubProjectID]
                                           , [LoadDate]
                                           , [ChartsRequested]
                                           , [ChartsVHRetrieved]
                                           , [ChartsAdded]
                                           , [ChartsFPC]
                                           , [ChartsComplete]
                                           , [ClientCodingCompleteDate])
    EXEC(@GetDataSQL)

    SET @RecordCount = @@ROWCOUNT

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('003', 0, 1) WITH NOWAIT
        END

    /*
    UPDATE
        pwl
    SET
        pwl.[RowCount] = ISNULL(@RecordCount, 0)
    FROM
        [Valuation].[AutoProcessWorkList] pwl
    WHERE
        pwl.[AutoProcessRunId] = @AutoProcessRunId

		*/

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('004', 0, 1) WITH NOWAIT
        END



