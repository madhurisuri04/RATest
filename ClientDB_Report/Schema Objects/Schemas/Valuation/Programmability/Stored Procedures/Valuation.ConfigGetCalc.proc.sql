CREATE PROC [Valuation].[ConfigGetCalc]
    (
        @ClientId INT ,
        @AutoProcessRunId INT ,
        @AutoProcessRunIdFA INT = NULL ,
        @CTRLoadDate DATE ,
        @ModelYearA INT ,
        @ModelYearB INT ,
        @BlendedPaymentDetailHeaderA VARCHAR(128),     /*Note: Use 'REMOVE' to hide on report */
        @BlendedPaymentDetailHeaderB VARCHAR(128) ,    --= '2013 DOS/2014 Payment Year - 2014 Model (75%)'
        @BlendedPaymentDetailHeaderESRD VARCHAR(128) , --= '2013 DOS/2014 Payment Year - 2014 Model (100% ESRD)'
        @TotalsDetailHeaderA VARCHAR(128) ,            --= '2013 DOS/2014 Payment Year - 2013 Model (25%)'
        @TotalsDetailHeaderB VARCHAR(128) ,            --= '2013 DOS/2014 Payment Year - 2014 Model (75%)'
        @TotalsDetailHeaderESRD VARCHAR(128) ,         --= '2013 DOS/2014 Payment Year - 2014 Model (100% - ESRD)'
        @TotalsSummaryHeader VARCHAR(128) ,            --= 'RAPS SUBMISSIONS - REALIZED for 2014 Payment Year'
        @YearToYearSummaryRowDisplay VARCHAR(128) ,    --= '2014 Retro Projects (2013 DOS / 2014 PY)'
        @RetrospectiveValuationDetailDOSPaymentYearHeader VARCHAR(128) ,
        @OverwriteProjectId VARCHAR(4096) = NULL ,
        @OverwriteSubprojectId VARCHAR(4096) = NULL ,
        @OverwriteReviewName VARCHAR(4096) = NULL ,
        @DeliveredDate DATE ,                          --TFS 45734 Added Delivered Date Parameter
        @Debug BIT = 0
    )
AS
    --
    /********************************************************************************************************************
* Name				:	Valuation.ConfigGetCalc																			*
* Type 				:	Stored Procedure																				*
* Version			:																									*
* Description		:	This stp finalizes the data for the Retro Valuation report										*
*																														*
* Version History	:																									*
* =================																										*
* Author			Date			Version#    TFS Ticket#		Description												*
* -----------------	----------		--------    -----------		--------------------------------------------------------*
*																														*
* D Waddell 		02/04/2016		3.0			47772			Rename ClaimID fields to HCC_PROCESSED_PCN				*
*																Changed section 47 and section 50 (Filtered Audit) to	*
*																count Unq_Conditions and ANNUALIZED_ESTIMATED_VALUE		*
* D Waddell			04/20/2016		3.1			52435			Upadted proc to use annualized_estimated_value instead	*
*																of usning Estimated_Value  								*
* MCasto			2016-09-02		3.2			US54399			Updated section 076 to correct the calculation of		*
*																"Est Revenue / HCC" and "HCC Realization Rate %" for	*
*																PartC													*
* MCasto			2016-10-06		3.3							Updated section 072 to correct overstatement of Project *
*																Completion %.  Changed join from SubProject to Project	*
* MCasto			2016-10-18		3.4			58445 / US57192															*
*																														*
* MCasto			2017-01-26		3.5			US58279			Added 'Wave' data for 'Current Week Totals By Wave' tab	*
*																Section 088 to 093										*
*																~Note: a seperate config table needs to be created to	*
*																handle SubGroup by SubProjectId~						*
*																Set misssing data information warning to run only when	*
*																@Debug is set to 1 --This will eliminate false positives*
*																when run by worker stp									*
* MCasto			2017-02-23		3.6							Correct Single Model Year (Section 022)					*
* MCasto			2017-04-02		3.7			62761 / US61960 2017 Model Year has introduced three Community Factor	*
*																Types CN, CP and CF in place of current C. Change in	*
*																valuation script so that it handles CN, CP and CF when	*
*																we run for 2017 PY.										*
* MCasto			2017-07-27		3.8			RE-1040/US67184	Changed select errors to informational messages			*
*												TFS66078																*
* DWaddell			2017-0728		3.9			RE1042			Modify Section 027 Provider ID Def. to handle potential	*
*                                               TFS66129        up to 10 character (for Select statement for  INSERT    *
*                                                               INTO [#09-Filtered DATA Results]                        *
*																														*
* DWaddell          2017-08-25      4.0         TFS66435/RE1081 Fix Filtered Audit Fix for Coventry in Valuation        *
*                                                                Section 027.1    If the Provider ID contains an        *
*                                                                underscore ("_"), take the Provider ID is the substring*
*                                                                of the ID prior to the underscore.                     *
*                                                                                                                       * 
* DWaddell          2018-01-08      4.1         TFS 68849/re-1309Section 90 join logic added to address completed chart *
*                                                                Count issue for Aetna Valuation Current Week Total By  *
*                                                                Wave Report Tab                                        *
* Madhuri Suri      2020-1-9        5           TFS 78888       EDS integration into Valuation                          *          
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
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000', 0, 1) WITH NOWAIT
        END

    DECLARE @ClientName VARCHAR(128)
    DECLARE @PopulatedDate DATETIME = GETDATE()
    DECLARE @Msg VARCHAR(2048)

    DECLARE @InfoMsg VARCHAR(2048)

    SET @AutoProcessRunIdFA = ISNULL(@AutoProcessRunIdFA, @AutoProcessRunId)

    /*B Intial Data availability Checks */

    DECLARE @StopOnMissingData TINYINT = 0

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000.1', 0, 1) WITH NOWAIT
        END

    IF NOT EXISTS (   SELECT 1
                      FROM   [Valuation].[FilteredAuditCWFDetail] [fad] WITH ( NOLOCK )
                      WHERE  [fad].[AutoProcessRunId] = @AutoProcessRunIdFA
                  )
       AND @Debug = 1
        BEGIN
            SET @StopOnMissingData = @StopOnMissingData + 1
            RAISERROR(
                         '[Valuation].[FilteredAuditCWFDetail] data is missing. Process Stopped.' ,
                         16 ,
                         1
                     )
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000.2', 0, 1) WITH NOWAIT
        END

    IF NOT EXISTS (   SELECT 1
                      FROM   [Valuation].[FilteredAuditCNCompletedChart] [facc] WITH ( NOLOCK )
                      WHERE  [facc].[ClientId] = @ClientId
                             AND [facc].[AutoProcessRunId] = @AutoProcessRunIdFA
                  )
       AND @Debug = 1
        BEGIN
            SET @StopOnMissingData = @StopOnMissingData + 1
            RAISERROR(
                         '[Valuation].[FilteredAuditCNCompletedChart] data is missing. Process Stopped.' ,
                         16 ,
                         1
                     )
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000.3', 0, 1) WITH NOWAIT
        END

    IF NOT EXISTS (   SELECT *
                      FROM   [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK )
                      WHERE  [ctrs].[LoadDate] = @CTRLoadDate
                             AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId
                  )
       AND @Debug = 1
        BEGIN
            SET @StopOnMissingData = @StopOnMissingData + 1
            RAISERROR(
                         '[Valuation].[ValCTRSummary] data is missing. Process Stopped.' ,
                         16 ,
                         1
                     )
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000.4', 0, 1) WITH NOWAIT
        END

    IF NOT EXISTS (   SELECT *
                      FROM   [Valuation].[NewHCCPartC] [p] WITH ( NOLOCK )
                      WHERE  [p].[ProcessRunId] = @AutoProcessRunId
                             AND [p].[PCN_SubprojectId] IS NOT NULL
                  )
       AND @Debug = 1
        BEGIN
            SET @StopOnMissingData = @StopOnMissingData + 1
            RAISERROR(
                         '[Valuation].[NewHCCPartC] data is missing. Process Stopped.' ,
                         16 ,
                         1
                     )
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000.5', 0, 1) WITH NOWAIT
        END

    IF NOT EXISTS (   SELECT *
                      FROM   [Valuation].[NewHCCPartD] [p] WITH ( NOLOCK )
                      WHERE  [p].[ProcessRunId] = @AutoProcessRunId
                             AND [p].[PCN_SubprojectId] IS NOT NULL
                  )
       AND @Debug = 1
        BEGIN
            SET @StopOnMissingData = @StopOnMissingData + 1
            RAISERROR(
                         '[Valuation].[NewHCCPartD] data is missing. Process Stopped.' ,
                         16 ,
                         1
                     )
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('000.6', 0, 1) WITH NOWAIT
        END

    IF @StopOnMissingData > 0
        BEGIN
            RETURN
        END

    /*E Intial Data availability Checks */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('001', 0, 1) WITH NOWAIT
        END

    /*B @OverwriteProjectIdList */

    IF @OverwriteProjectId IS NOT NULL
        BEGIN

            DECLARE @OverwriteProjectIdList TABLE
                (
                    [ProjectId] INT
                );
            WITH [CTE_parse] ( [Starting_Character], [Ending_Character] ,
                               [Occurence]
                             )
            AS ( SELECT [Starting_Character] = 1 ,
                        [Ending_Character] = CAST(CHARINDEX(
                                                               ',' ,
                                                               @OverwriteProjectId
                                                               + ','
                                                           ) AS INT) ,
                        [Occurence] = 1
                 UNION ALL
                 SELECT [Starting_Character] = [CTE_parse].[Ending_Character]
                                               + 1 ,
                        [Ending_Character] = CAST(CHARINDEX(
                                                               ',' ,
                                                               @OverwriteProjectId
                                                               + ',',
                                                               [CTE_parse].[Ending_Character]
                                                               + 1
                                                           ) AS INT) ,
                        [CTE_parse].[Occurence] + 1
                 FROM   [CTE_parse]
                 WHERE  CHARINDEX(
                                     ',' ,
                                     @OverwriteProjectId + ',',
                                     [Ending_Character] + 1
                                 ) <> 0
               )
            INSERT INTO @OverwriteProjectIdList ( [ProjectId] )
                        SELECT [StringValues] = LTRIM(RTRIM(SUBSTRING(
                                                                         @OverwriteProjectId ,
                                                                         [CTE_parse].[Starting_Character],
                                                                         [CTE_parse].[Ending_Character]
                                                                         - [CTE_parse].[Starting_Character]
                                                                     )
                                                           )
                                                     )
                        FROM   [CTE_parse]
        END

    /*E @OverwriteProjectIdList */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('002', 0, 1) WITH NOWAIT
        END

    /*B @OverwriteSubProjectIdList */

    IF @OverwriteSubprojectId IS NOT NULL
        BEGIN
            DECLARE @OverwriteSubProjectIdList TABLE
                (
                    [SubProjectId] INT
                );
            WITH [CTE_parse] ( [Starting_Character], [Ending_Character] ,
                               [Occurence]
                             )
            AS ( SELECT [Starting_Character] = 1 ,
                        [Ending_Character] = CAST(CHARINDEX(
                                                               ',' ,
                                                               @OverwriteSubprojectId
                                                               + ','
                                                           ) AS INT) ,
                        [Occurence] = 1
                 UNION ALL
                 SELECT [Starting_Character] = [CTE_parse].[Ending_Character]
                                               + 1 ,
                        [Ending_Character] = CAST(CHARINDEX(
                                                               ',' ,
                                                               @OverwriteSubprojectId
                                                               + ',',
                                                               [CTE_parse].[Ending_Character]
                                                               + 1
                                                           ) AS INT) ,
                        [CTE_parse].[Occurence] + 1
                 FROM   [CTE_parse]
                 WHERE  CHARINDEX(
                                     ',' ,
                                     @OverwriteSubprojectId + ',',
                                     [Ending_Character] + 1
                                 ) <> 0
               )
            INSERT INTO @OverwriteSubProjectIdList ( [SubProjectId] )
                        SELECT [StringValues] = LTRIM(RTRIM(SUBSTRING(
                                                                         @OverwriteSubprojectId ,
                                                                         [CTE_parse].[Starting_Character],
                                                                         [CTE_parse].[Ending_Character]
                                                                         - [CTE_parse].[Starting_Character]
                                                                     )
                                                           )
                                                     )
                        FROM   [CTE_parse]
        END

    /*E @OverwriteSubProjectIdList */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('003', 0, 1) WITH NOWAIT
        END

    /*B @OverwriteReviewName */

    IF @OverwriteReviewName IS NOT NULL
        BEGIN
            DECLARE @OverwriteReviewNameList TABLE
                (
                    [ReviewName] VARCHAR(50)
                );
            WITH [CTE_parse] ( [Starting_Character], [Ending_Character] ,
                               [Occurence]
                             )
            AS ( SELECT [Starting_Character] = 1 ,
                        [Ending_Character] = CAST(CHARINDEX(
                                                               ',' ,
                                                               @OverwriteReviewName
                                                               + ','
                                                           ) AS INT) ,
                        [Occurence] = 1
                 UNION ALL
                 SELECT [Starting_Character] = [CTE_parse].[Ending_Character]
                                               + 1 ,
                        [Ending_Character] = CAST(CHARINDEX(
                                                               ',' ,
                                                               @OverwriteReviewName
                                                               + ',',
                                                               [CTE_parse].[Ending_Character]
                                                               + 1
                                                           ) AS INT) ,
                        [CTE_parse].[Occurence] + 1
                 FROM   [CTE_parse]
                 WHERE  CHARINDEX(
                                     ',' ,
                                     @OverwriteReviewName + ',',
                                     [Ending_Character] + 1
                                 ) <> 0
               )
            INSERT INTO @OverwriteReviewNameList ( [ReviewName] )
                        SELECT [StringValues] = LTRIM(RTRIM(SUBSTRING(
                                                                         @OverwriteReviewName ,
                                                                         [CTE_parse].[Starting_Character],
                                                                         [CTE_parse].[Ending_Character]
                                                                         - [CTE_parse].[Starting_Character]
                                                                     )
                                                           )
                                                     )
                        FROM   [CTE_parse]
        END

    /*E @OverwriteReviewName */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('004', 0, 1) WITH NOWAIT
        END

    /*B @FA_ReviewName */

    DECLARE @FA_ReviewName TABLE
        (
            [ProjectId] INT NOT NULL ,
            [SubProjectId] INT NOT NULL ,
            [FAReviewName] VARCHAR(128) NOT NULL ,
            [StartDate] DATE NOT NULL
        )

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('005', 0, 1) WITH NOWAIT
        END

    /*B 2015-07-30 MC */

    IF @OverwriteProjectId IS NULL
       AND @OverwriteReviewName IS NULL
       AND @OverwriteSubprojectId IS NULL
        --OR @OverwriteReviewName IS NULL
        --OR @OverwriteSubprojectId IS NULL

        /*E 2015-07-30 MC */

        BEGIN

            INSERT INTO @FA_ReviewName (   [ProjectId] ,
                                           [SubProjectId] ,
                                           [FAReviewName] ,
                                           [StartDate]
                                       )
                        SELECT DISTINCT [ProjectId] = [sprn].[ProjectId] ,
                               [SubProjectId] = [sprn].[SubProjectId] ,
                               [FAReviewName] = [sprn].[ReviewName] ,
                               [StartDate] = [sprn].[ActiveBDate]
                        FROM   [Valuation].[ConfigSubProjectReviewName] [sprn]
                               JOIN [Valuation].[ConfigProjectIdList] [pl] ON [sprn].[ClientId] = [pl].[ClientId]
                                                                              AND [sprn].[ProjectId] = [pl].[ProjectId]
                        WHERE  [sprn].[ClientId] = @ClientId
                               AND [sprn].[ActiveBDate] <= GETDATE()
                               AND ISNULL(
                                             [sprn].[ActiveEDate] ,
                                             DATEADD(dd, 1, GETDATE())
                                         ) >= GETDATE()
                               AND [pl].[ActiveBDate] <= GETDATE()
                               AND ISNULL(
                                             [pl].[ActiveEDate] ,
                                             DATEADD(dd, 1, GETDATE())
                                         ) >= GETDATE()

            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = ISNULL(@Msg, '')
                               + '005 - Notice: Zero rows loaded to @FA_ReviewName| '
                --                    RAISERROR(@Msg, 16, 1)
                --                    SET @Msg = NULL
                END
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('006', 0, 1) WITH NOWAIT
        END

    /*B Use of Overwrite */

    /*B 2015-07-30 MC */

    IF @OverwriteProjectId IS NOT NULL
       --AND @OverwriteReviewName IS NOT NULL
       --AND @OverwriteSubprojectId IS NOT NULL
       OR @OverwriteReviewName IS NOT NULL
       OR @OverwriteSubprojectId IS NOT NULL /*E 2015-07-30 MC */
        BEGIN

            INSERT INTO @FA_ReviewName (   [ProjectId] ,
                                           [SubProjectId] ,
                                           [FAReviewName] ,
                                           [StartDate]
                                       )
                        SELECT DISTINCT [ProjectId] = [sprn].[ProjectId] ,
                               [SubProjectId] = [sprn].[SubProjectId] ,
                               [FAReviewName] = [sprn].[ReviewName] ,
                               [StartDate] = [sprn].[ActiveBDate]
                        FROM   [Valuation].[ConfigSubProjectReviewName] [sprn]
                               JOIN [Valuation].[ConfigProjectIdList] [pl] ON [sprn].[ClientId] = [pl].[ClientId]
                                                                              AND [sprn].[ProjectId] = [pl].[ProjectId]

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('007', 0, 1) WITH NOWAIT
                END

            IF @OverwriteProjectId IS NOT NULL
                BEGIN
                    DELETE [m]
                    FROM  @FA_ReviewName [m]
                    WHERE [m].[ProjectId] NOT IN (   SELECT [ProjectId]
                                                     FROM   @OverwriteProjectIdList
                                                 )
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('008', 0, 1) WITH NOWAIT
                END

            IF @OverwriteSubprojectId IS NOT NULL
                BEGIN
                    DELETE [m]
                    FROM  @FA_ReviewName [m]
                    WHERE [m].[SubProjectId] NOT IN (   SELECT [SubProjectId]
                                                        FROM   @OverwriteSubProjectIdList
                                                    )
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('009', 0, 1) WITH NOWAIT
                END

            IF @OverwriteReviewName IS NOT NULL
                BEGIN
                    DELETE [m]
                    FROM  @FA_ReviewName [m]
                    WHERE [m].[FAReviewName] NOT IN (   SELECT [ReviewName]
                                                        FROM   @OverwriteReviewNameList
                                                    )
                END
        END

    /*E Use of Overwrite */

    /*E @FA_ReviewName */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('010', 0, 1) WITH NOWAIT
        END

    /*B Get Project/Subproject info */

    IF  OBJECT_ID('tempdb.dbo.#ProjectSubprojectReviewList') IS NOT NULL 
        BEGIN
            DROP TABLE #ProjectSubprojectReviewList
        END

    CREATE TABLE #ProjectSubprojectReviewList 
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
            [ProjectId] INT NOT NULL ,
            [ProjectDescription] VARCHAR(85) NULL ,
            [ProjectSortOrder] SMALLINT NULL ,
            [SubProjectId] INT NULL ,
            [SubProjectDescription] VARCHAR(85) NULL ,
            [SubProjectSortOrder] SMALLINT NULL ,
            [ProviderType] CHAR(2) NULL ,
            [Type] VARCHAR(15) NULL ,
            [PMH] CHAR(1) NULL ,
            [ReviewName] VARCHAR(50) NULL ,
            [FailureReason] VARCHAR(20) NULL ,
            [SuspectYR] CHAR(4) NULL ,
            [FilteredAuditActiveBDate] DATE NULL ,
            [FilteredAuditActiveEDate] DATE NULL, [ProjectYear]  VARCHAR(4) NULL 
        )


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('011', 0, 1) WITH NOWAIT
        END

    IF @OverwriteProjectId IS NULL
       AND @OverwriteReviewName IS NULL
       AND @OverwriteSubprojectId IS NULL
        BEGIN

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('011.1', 0, 1) WITH NOWAIT
                END

            INSERT INTO #ProjectSubprojectReviewList (   [ProjectId] ,
                                                         [ProjectDescription] ,
                                                         [ProjectSortOrder] ,
                                                         [SubProjectId] ,
                                                         [SubProjectDescription] ,
                                                         [SubProjectSortOrder] ,
                                                         [ProviderType] ,
                                                         [Type] ,
                                                         [PMH] ,
                                                         [ReviewName] ,
                                                         [FailureReason] ,
                                                         [SuspectYR] ,
                                                         [FilteredAuditActiveBDate] ,
                                                         [FilteredAuditActiveEDate]
                                                     )
                        SELECT DISTINCT [ProjectId] = [pil].[ProjectId] ,
                               [ProjectDescription] = [pil].[ProjectDescription] ,
                               [ProjectSortOrder] = [pil].[ProjectSortOrder] ,
                               [SubProjectId] = ISNULL(
                                                          [spsp].[SubProjectId] ,
                                                          -1
                                                      ) ,
                               [SubprojectDescription] = [spsp].[SubprojectDescription] ,
                               [SubProjectSortOrder] = [spsp].[SubProjectSortOrder] ,
                               [ProviderType] = [spsp].[ProviderType] ,
                               [Type] = [spsp].[Type] ,
                               [PMH] = [spsp].[PMH] ,
                               [ReviewName] = [sprn].[ReviewName] ,
                               [FailureReason] = [spsp].[FailureReason] ,
                               [pil].[SuspectYR] ,
                               [FilteredAuditActiveBDate] = [spsp].[FilteredAuditActiveBDate] ,
                               [FilteredAuditActiveEDate] = [spsp].[FilteredAuditActiveEDate]
                        FROM   [Valuation].[ConfigProjectIdList] [pil]
                               LEFT JOIN [Valuation].[ConfigSubProjectSubstringPattern] [spsp] ON [pil].[ProjectId] = [spsp].[ProjectId]
                                                                                                  AND [spsp].[ActiveBDate] <= GETDATE()
                                                                                                  AND (   [spsp].[ActiveEDate] IS NULL
                                                                                                          OR [spsp].[ActiveEDate] > GETDATE()
                                                                                                      )
                               LEFT JOIN [Valuation].[ConfigSubProjectReviewName] [sprn] ON [spsp].[SubProjectId] = [sprn].[SubProjectId]
                                                                                            AND [sprn].[ActiveBDate] <= GETDATE()
                                                                                            AND (   [sprn].[ActiveEDate] IS NULL
                                                                                                    OR [sprn].[ActiveEDate] > GETDATE()
                                                                                                )
                        WHERE  [pil].[ActiveBDate] <= GETDATE()
                               AND (   [pil].[ActiveEDate] IS NULL
                                       OR [pil].[ActiveEDate] > GETDATE()
                                   )
                               AND [pil].[ClientId] = @ClientId
                               AND [spsp].[Type] = 'Retrospective'

            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = ISNULL(@Msg, '')
                               + '011.1 - Notice: Zero rows loaded to #ProjectSubprojectReviewList| '
                --                    RAISERROR(@Msg, 16, 1)
                --                  SET @Msg = NULL
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('011.2', 0, 1) WITH NOWAIT
                END
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('012', 0, 1) WITH NOWAIT
        END


    ----IF @OverwriteProjectId IS NOT NULL
    ----   OR @OverwriteReviewName IS NOT NULL
    ----   OR @OverwriteSubprojectId IS NOT NULL
    ----    BEGIN

    ----        IF @Debug = 1
    ----            BEGIN
    ----                PRINT 'ET: '
    ----                      + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                      + ' || TET: '
    ----                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
    ----                      + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
    ----                SET @ET = GETDATE()
    ----                RAISERROR('012.1', 0, 1) WITH NOWAIT
    ----            END

    ----        INSERT INTO #ProjectSubprojectReviewList (   [ProjectId] ,
    ----                                                     [ProjectDescription] ,
    ----                                                     [ProjectSortOrder] ,
    ----                                                     [SubProjectId] ,
    ----                                                     [SubProjectDescription] ,
    ----                                                     [SubProjectSortOrder] ,
    ----                                                     [ProviderType] ,
    ----                                                     [Type] ,
    ----                                                     [PMH] ,
    ----                                                     [ReviewName] ,
    ----                                                     [FailureReason] ,
    ----                                                     [SuspectYR] ,
    ----                                                     [FilteredAuditActiveBDate] ,
    ----                                                     [FilteredAuditActiveEDate]
    ----                                                 )
    ----                    SELECT DISTINCT [ProjectId] = [pil].[ProjectId] ,
    ----                           [ProjectDescription] = [pil].[ProjectDescription] ,
    ----                           [ProjectSortOrder] = [pil].[ProjectSortOrder] ,
    ----                           [SubProjectId] = ISNULL(
    ----                                                      [spsp].[SubProjectId] ,
    ----                                                      -1
    ----                                                  ) ,
    ----                           [SubprojectDescription] = [spsp].[SubprojectDescription] ,
    ----                           [SubProjectSortOrder] = [spsp].[SubProjectSortOrder] ,
    ----                           [ProviderType] = [spsp].[ProviderType] ,
    ----                           [Type] = [spsp].[Type] ,
    ----                           [PMH] = [spsp].[PMH] ,
    ----                           [ReviewName] = [sprn].[ReviewName] ,
    ----                           [FailureReason] = [spsp].[FailureReason] ,
    ----                           [pil].[SuspectYR] ,
    ----                           [FilteredAuditActiveBDate] = [spsp].[FilteredAuditActiveBDate] ,
    ----                           [FilteredAuditActiveEDate] = [spsp].[FilteredAuditActiveEDate]
    ----                    FROM   [Valuation].[ConfigProjectIdList] [pil]
    ----                           LEFT JOIN [Valuation].[ConfigSubProjectSubstringPattern] [spsp] ON [pil].[ProjectId] = [spsp].[ProjectId]
    ----                           LEFT JOIN [Valuation].[ConfigSubProjectReviewName] [sprn] ON [spsp].[SubProjectId] = [sprn].[SubProjectId]
    ----                    WHERE  [pil].[ClientId] = @ClientId
    ----                           AND [spsp].[Type] = 'Retrospective'

    ----        IF @Debug = 1
    ----            BEGIN
    ----                PRINT 'ET: '
    ----                      + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                      + ' || TET: '
    ----                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
    ----                      + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
    ----                SET @ET = GETDATE()
    ----                RAISERROR('013', 0, 1) WITH NOWAIT
    ----            END

    ----        IF @OverwriteProjectId IS NOT NULL
    ----            BEGIN
    ----                IF @Debug = 1
    ----                    BEGIN
    ----                        PRINT 'ET: '
    ----                              + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                              + ' || TET: '
    ----                              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(
    ----                                           CHAR(12) ,
    ----                                           GETDATE() - @MasterET,
    ----                                           114
    ----                                       ) + ' || '
    ----                              + CONVERT(CHAR(23), GETDATE(), 121)
    ----                        SET @ET = GETDATE()
    ----                        RAISERROR('013.1', 0, 1) WITH NOWAIT
    ----                    END

    ----                DELETE [m]
    ----                FROM  #ProjectSubprojectReviewList [m]
    ----                WHERE [m].[ProjectId] NOT IN (   SELECT [ProjectId]
    ----                                                 FROM   @OverwriteProjectIdList
    ----                                             )

    ----                IF @Debug = 1
    ----                    BEGIN
    ----                        PRINT 'ET: '
    ----                              + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                              + ' || TET: '
    ----                              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(
    ----                                           CHAR(12) ,
    ----                                           GETDATE() - @MasterET,
    ----                                           114
    ----                                       ) + ' || '
    ----                              + CONVERT(CHAR(23), GETDATE(), 121)
    ----                        SET @ET = GETDATE()
    ----                        RAISERROR('013.2', 0, 1) WITH NOWAIT
    ----                    END
    ----            END

    ----        IF @Debug = 1
    ----            BEGIN
    ----                PRINT 'ET: '
    ----                      + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                      + ' || TET: '
    ----                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
    ----                      + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
    ----                SET @ET = GETDATE()
    ----                RAISERROR('014', 0, 1) WITH NOWAIT
    ----            END

    ----        IF @OverwriteSubprojectId IS NOT NULL
    ----            BEGIN

    ----                IF @Debug = 1
    ----                    BEGIN
    ----                        PRINT 'ET: '
    ----                              + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                              + ' || TET: '
    ----                              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(
    ----                                           CHAR(12) ,
    ----                                           GETDATE() - @MasterET,
    ----                                           114
    ----                                       ) + ' || '
    ----                              + CONVERT(CHAR(23), GETDATE(), 121)
    ----                        SET @ET = GETDATE()
    ----                        RAISERROR('014.1', 0, 1) WITH NOWAIT
    ----                    END

    ----                DELETE [m]
    ----                FROM  #ProjectSubprojectReviewList [m]
    ----                WHERE [m].[SubProjectId] NOT IN (   SELECT [SubProjectId]
    ----                                                    FROM   @OverwriteSubProjectIdList
    ----                                                )


    ----                IF @Debug = 1
    ----                    BEGIN
    ----                        PRINT 'ET: '
    ----                              + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                              + ' || TET: '
    ----                              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(
    ----                                           CHAR(12) ,
    ----                                           GETDATE() - @MasterET,
    ----                                           114
    ----                                       ) + ' || '
    ----                              + CONVERT(CHAR(23), GETDATE(), 121)
    ----                        SET @ET = GETDATE()
    ----                        RAISERROR('014.2', 0, 1) WITH NOWAIT
    ----                    END
    ----            END

    ----        IF @Debug = 1
    ----            BEGIN
    ----                PRINT 'ET: '
    ----                      + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                      + ' || TET: '
    ----                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
    ----                      + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
    ----                SET @ET = GETDATE()
    ----                RAISERROR('015', 0, 1) WITH NOWAIT
    ----            END

    ----        IF @OverwriteReviewName IS NOT NULL
    ----            BEGIN

    ----                IF @Debug = 1
    ----                    BEGIN
    ----                        PRINT 'ET: '
    ----                              + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                              + ' || TET: '
    ----                              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(
    ----                                           CHAR(12) ,
    ----                                           GETDATE() - @MasterET,
    ----                                           114
    ----                                       ) + ' || '
    ----                              + CONVERT(CHAR(23), GETDATE(), 121)
    ----                        SET @ET = GETDATE()
    ----                        RAISERROR('015.1', 0, 1) WITH NOWAIT
    ----                    END

    ----                DELETE [m]
    ----                FROM  #ProjectSubprojectReviewList [m]
    ----                WHERE [m].[ReviewName] NOT IN (   SELECT [ReviewName]
    ----                                                  FROM   @OverwriteReviewNameList
    ----                                              )
    ----                IF @Debug = 1
    ----                    BEGIN
    ----                        PRINT 'ET: '
    ----                              + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                              + ' || TET: '
    ----                              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                              + ' secs | '
    ----                              + CONVERT(
    ----                                           CHAR(12) ,
    ----                                           GETDATE() - @MasterET,
    ----                                           114
    ----                                       ) + ' || '
    ----                              + CONVERT(CHAR(23), GETDATE(), 121)
    ----                        SET @ET = GETDATE()
    ----                        RAISERROR('015.2', 0, 1) WITH NOWAIT
    ----                    END
    ----            END

    ----        IF @Debug = 1
    ----            BEGIN
    ----                PRINT 'ET: '
    ----                      + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @ET, 114)
    ----                      + ' || TET: '
    ----                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
    ----                      + ' secs | '
    ----                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
    ----                      + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
    ----                SET @ET = GETDATE()
    ----                RAISERROR('015.3', 0, 1) WITH NOWAIT
    ----            END
    ----    END

    /*E Get Project/Subproject info */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('016', 0, 1) WITH NOWAIT
        END

    /*B 02-Flagging PartC Subprojects */

    IF ( OBJECT_ID('tempdb.dbo.[#02-Flagging PartC Subprojects]') IS NOT NULL )
        BEGIN
            DROP TABLE [#02-Flagging PartC Subprojects]
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('017', 0, 1) WITH NOWAIT
        END

    CREATE TABLE [#02-Flagging PartC Subprojects]
        (
            [Id] [INT] IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
            [SubProjectId] [INT] NOT NULL ,
            [FailureReason] [VARCHAR](20) NULL ,
            [PMH_Attestation] [VARCHAR](20) NULL ,
            [Audit_Strings] [VARCHAR](20) NULL ,
            [PAYMENT_YEAR] [INT] NULL ,
            [Model_Year] [INT] NULL ,
            [PROCESSED_BY_START] [DATETIME] NULL ,
            [PROCESSED_BY_END] [DATETIME] NULL ,
            [PROCESSED_BY_FLAG] [CHAR](1) NULL ,
            [PlanId] [VARCHAR](5) NULL ,
            [HICN] [VARCHAR](15) NULL ,
            [RA_FACTOR_TYPE] [CHAR](2) NULL ,
            [Updated HCC] [VARCHAR](20) NULL ,
            [HCC_DESCRIPTION] [VARCHAR](128) NULL ,
            [FACTOR] [DECIMAL](20, 4) NOT NULL ,
            [HIER_HCC_OLD] [VARCHAR](20) NULL ,
            [HIER_FACTOR_OLD] [DECIMAL](20, 4) NOT NULL ,
            [Member_Months] [INT] NULL ,
            [BID_Amount] [MONEY] NOT NULL ,
            [Estimated_Value] [MONEY] NOT NULL ,
            [RollForward_Months] [INT] NULL ,
            [AnnualizedEstimatedValue] [MONEY] NOT NULL ,
            [MONTHS_IN_DCP] [INT] NOT NULL ,
            [PBP] [CHAR](3) NULL ,
            [SCC] [CHAR](5) NOT NULL ,
            [PROCESSED_PRIORITY_PROCESSED_BY] [DATETIME] NULL ,
            [PROCESSED_PRIORITY_THRU_DATE] [DATETIME] NULL ,
            [HCC_PROCESSED_PCN] [VARCHAR](50) NULL ,
            [PROCESSED_PRIORITY_DIAG] [VARCHAR](20) NULL ,
            [PROVIDER_ID] [VARCHAR](40) NULL ,
            [Unq_Conditions] [BIT] NULL ,
            [PCN_ProviderId] [VARCHAR](40) NULL, 
			[EncounterSource]	[VARCHAR] (4)
        )
     

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('018', 0, 1) WITH NOWAIT
        END

    /*B Check if FailureReason STP has not run then run */

    IF  (   SELECT COUNT(*)
            FROM   [Valuation].[NewHCCPartC] [crl] WITH ( NOLOCK )
            WHERE  [crl].[ProcessRunId] = @AutoProcessRunId
                   AND [crl].[PCN_SubprojectId] IS NOT NULL
        ) = 0
        OR  (   SELECT COUNT(*)
                FROM   [Valuation].[NewHCCPartD] [crl] WITH ( NOLOCK )
                WHERE  [crl].[ProcessRunId] = @AutoProcessRunId
                       AND [crl].[PCN_SubprojectId] IS NOT NULL
            ) = 0
        BEGIN

            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = ISNULL(@Msg, '')
                               + '018 - Notice: Zero rows with SubprojectIds in [Valuation].[NewHCCPartD] and/or [Valuation].[NewHCCPartD]| '
                --RAISERROR(@Msg, 16, 1)
                --SET @Msg = NULL
                END
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('019', 0, 1) WITH NOWAIT
        END

    /*E Check if FailureReason STP has not run then run */

    /*E 01-PartC Data Strings */

    INSERT INTO [#02-Flagging PartC Subprojects] (   [SubProjectId] ,
                                                     [FailureReason] ,
                                                     [PMH_Attestation] ,
                                                     [Audit_Strings] ,
                                                     [PAYMENT_YEAR] ,
                                                     [Model_Year] ,
                                                     [PROCESSED_BY_START] ,
                                                     [PROCESSED_BY_END] ,
                                                     [PROCESSED_BY_FLAG] ,
                                                     [PlanId] ,
                                                     [HICN] ,
                                                     [RA_FACTOR_TYPE] ,
                                                     [Updated HCC] ,
                                                     [HCC_DESCRIPTION] ,
                                                     [FACTOR] ,
                                                     [HIER_HCC_OLD] ,
                                                     [HIER_FACTOR_OLD] ,
                                                     [Member_Months] ,
                                                     [BID_Amount] ,
                                                     [Estimated_Value] ,
                                                     [RollForward_Months] ,
                                                     [AnnualizedEstimatedValue] ,
                                                     [MONTHS_IN_DCP] ,
                                                     [PBP] ,
                                                     [SCC] ,
                                                     [PROCESSED_PRIORITY_PROCESSED_BY] ,
                                                     [PROCESSED_PRIORITY_THRU_DATE] ,
                                                     [HCC_PROCESSED_PCN] ,
                                                     [PROCESSED_PRIORITY_DIAG] ,
                                                     [PROVIDER_ID] ,
                                                     [Unq_Conditions] ,
                                                     [PCN_ProviderId], 
													 [EncounterSource]	
                                                 )
                SELECT DISTINCT [SubProjectId] = [crl].[PCN_SubprojectId] ,
                       [FailureReason] = [crl].[FailureReason] ,
                       [PMH_Att_String] = [crl].[FailureReason] ,
                       [AuditString] = NULL ,
                       [Payment_Year] = [crl].[Payment_Year] ,
                       [Model_Year] = [crl].[Model_Year] ,
                       [Processed_By_Start] = [crl].[Processed_By_Start] ,
                       [Processed_By_End] = [crl].[Processed_By_End] ,
                       [Processed_By_Flag] = [crl].[Processed_By_Flag] ,
                       [PlanId] = [crl].[PlanId] ,
                       [HICN] = LTRIM(RTRIM([crl].[HICN])) ,
                       [Ra_Factor_Type] = [crl].[Ra_Factor_Type] ,
                       [Updated HCC] = LTRIM(RTRIM([crl].[HCC])) ,
                       [HCC_Description] = [crl].[HCC_Description] ,
                       [HCC_FACTOR] = [crl].[HCC_FACTOR] ,
                       [HIER_HCC] = [crl].[HIER_HCC] ,
                       [HIER_HCC_FACTOR] = [crl].[HIER_HCC_FACTOR] ,
                       [Member_Months] = [crl].[Member_Months] ,
                       [BID_Amount] = [crl].[Bid_Amount] ,
                       [Estimated_Value] = [crl].[Estimated_Value] ,
                       [RollForward_Months] = [crl].[Rollforward_Months] ,
                       [AnnualizedEstimatedValue] = [crl].[Annualized_Estimated_Value] ,
                       [Months_In_DCP] = [crl].[Months_In_DCP] ,
                       [PBP] = [crl].[PBP] ,
                       [SCC] = [crl].[SCC] ,
                       [Processed_Priority_Processed_By] = [crl].[Processed_Priority_Processed_By] ,
                       [Processed_Priority_Thru_Date] = [crl].[Processed_Priority_Thru_Date] ,
                       [HCC_PROCESSED_PCN] = [crl].[HCC_PROCESSED_PCN] ,
                       [Processed_Priority_Diag] = [crl].[Processed_Priority_Diag] ,
                       [Provider_Id] = [crl].[Provider_Id] ,
                       [Unq_Conditions] = [crl].[UNQ_CONDITIONS] ,
                       [PCN_ProviderId] = [crl].[PCN_ProviderId], 
					   [EncounterSource] = crl.[EncounterSource]
                FROM   [Valuation].[NewHCCPartC] [crl] WITH ( NOLOCK )
                       JOIN #ProjectSubprojectReviewList [farn] ON [crl].[PCN_SubprojectId] = [farn].[SubProjectId]
                WHERE  [crl].[ProcessRunId] = @AutoProcessRunId
                       AND [crl].[PCN_SubprojectId] IS NOT NULL

    /*E 02-Flagging PartC Subprojects */

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '019 - Notice: Zero rows loaded to [#02-Flagging PartC Subprojects]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('020', 0, 1) WITH NOWAIT
        END

    CREATE NONCLUSTERED INDEX [IX_#02-Flagging PartC Subprojects__SubProjectId__RA_FACTOR_TYPE]
        ON [#02-Flagging PartC Subprojects]
        (
            [SubProjectId] ,
            [RA_FACTOR_TYPE]
        )

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('021', 0, 1) WITH NOWAIT
        END


Declare @PaymentYear int 
set @PaymentYear = (select Distinct PAYMENT_YEAR from [#02-Flagging PartC Subprojects])

    /*B 03-PartC Totals by SubProject Model Year CI */

    DELETE [m]
    FROM  [Valuation].[CalcPartCSubProjectModelYearCI] [m]
    WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
          AND [m].[ClientId] = @ClientId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('022', 0, 1) WITH NOWAIT
        END

        --		
        /**/;
    WITH [CTE_A3]
    AS ( SELECT   [SubProjectId] = [a2].[SubProjectId] ,
                  [Model_Year] = [a2].[Model_Year] ,
                  [HCC] = SUM(CASE WHEN [a2].[Unq_Conditions] = 1 THEN 1
                           END ),
                  [AnnualizedEstimatedValue] = SUM([a2].[AnnualizedEstimatedValue]) ,
                  [PMH_Attestation] = [a2].[PMH_Attestation], 
				  a2.[EncounterSource]
         FROM     [#02-Flagging PartC Subprojects] [a2]
         WHERE    [a2].[SubProjectId] IS NOT NULL
                  AND [a2].[SubProjectId] <> ''
                  AND [a2].[RA_FACTOR_TYPE] IN ( 'C', 'I', 'CN', 'CP', 'CF' )
                  /*B Correct Single Model Year */
                  AND [a2].[Model_Year] IN ( @ModelYearA, @ModelYearB )
         /*E Correct Single Model Year */

         GROUP BY [a2].[SubProjectId] ,
                  [a2].[Model_Year] ,
                  [a2].[PMH_Attestation] ,
				  [a2].[EncounterSource]
       )
    INSERT INTO [Valuation].[CalcPartCSubProjectModelYearCI] (   [ClientId] ,
                                                                 [AutoProcessRunId] ,
                                                                 [SubProjectId] ,
                                                                 [Model_Year] ,
                                                                 [HCCTotal] ,
                                                                 [AnnualizedEstimatedValue] ,
                                                                 [PMH_Attestation] ,
                                                                 [PopulatedDate], 
																 [EncounterSource]
																 

                                                             )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a3].[SubProjectId] ,
                         [Model_Year] = [a3].[Model_Year] ,
                         [HCCTotal] = SUM([a3].HCC) ,
                         [AnnualizedEstimatedValue] = SUM([a3].[AnnualizedEstimatedValue]) ,
                         [PMH_Attestation] = [a3].[PMH_Attestation] ,
                         [PopulatedDate] = @PopulatedDate,
						 [EncounterSource]
                FROM     [CTE_A3] [a3]
                GROUP BY [a3].[SubProjectId] ,
                         [a3].[Model_Year] ,
                         [a3].[PMH_Attestation],
						 [EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '022 - Notice: Zero rows loaded to [Valuation].[CalcPartCSubProjectModelYearCI]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 03-PartC Totals by SubProject Model Year CI */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('023', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD] [m]
    WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
          AND [m].[ClientId] = @ClientId


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('024', 0, 1) WITH NOWAIT
        END

        /*B [CalcPartCTotalsBySubprojectAndModelYearESRD] */

        /**/;
    WITH [CTE_a2]
    AS ( SELECT   [ClientId] = @ClientId ,
                  [AutoProcessRunId] = @AutoProcessRunId ,
                  [SubProjectId] = [a2].[SubProjectId] ,
                  [Model_Year] = [a2].[Model_Year] ,
                  [AnnualizedEstimatedValue] = SUM([a2].[AnnualizedEstimatedValue]) ,
                  [HCC] = SUM(CASE WHEN [a2].[Unq_Conditions] = 1 THEN 1
                           END) ,
                  [PMH_Attestation] = [a2].[PMH_Attestation] ,
				  [EncounterSource] = a2.[EncounterSource]
         FROM     [#02-Flagging PartC Subprojects] [a2]
         WHERE    [a2].[RA_FACTOR_TYPE] NOT IN ( 'C', 'I', 'CN', 'CP', 'CF' )
                  AND (   [a2].[SubProjectId] IS NOT NULL
                          AND [a2].[SubProjectId] <> ''
                      )
         GROUP BY [a2].[SubProjectId] ,
                  [a2].[Model_Year] ,
                  [a2].[PMH_Attestation] ,
				  [EncounterSource]
       )
    INSERT INTO [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD] (   [ClientId] ,
                                                                              [AutoProcessRunId] ,
                                                                              [SubProjectId] ,
                                                                              [Model_Year] ,
                                                                              [AnnualizedEstimatedValue] ,
                                                                              [HCCTotal] ,
                                                                              [PMH_Attestation] ,
                                                                              [PopulatedDate],
																			  [EncounterSource]
                                                                          )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a2].[SubProjectId] ,
                         [Model_Year] = [a2].[Model_Year] ,
                         [AnnualizedEstimatedValue] = SUM([a2].[AnnualizedEstimatedValue]) ,
                         [HCCTotal] = SUM([a2].[HCC]) ,
                         [PMH_Attestation] = [a2].[PMH_Attestation] ,
                         [PopulatedDate] = @PopulatedDate, 
						 a2.[EncounterSource]
                FROM     [CTE_a2] [a2]
                GROUP BY [a2].[SubProjectId] ,
                         [a2].[Model_Year] ,
                         [a2].[PMH_Attestation],
						 [EncounterSource]


    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '024 - Notice: Zero rows loaded to [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    /*E [CalcPartCTotalsBySubprojectAndModelYearESRD] */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('025', 0, 1) WITH NOWAIT
        END

    /*B 09-Filtered Data Results */


    IF ( OBJECT_ID('tempdb.dbo.[#09-Filtered Data Results]') IS NOT NULL )
        BEGIN
            DROP TABLE [#09-Filtered DATA Results]
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('026', 0, 1) WITH NOWAIT
        END

    CREATE TABLE [#09-Filtered DATA Results]
        (
            [Id] [INT] IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
            [SubProjectId] INT NOT NULL ,
            [PMH_Attestation] [VARCHAR](255) NULL ,
            [Model_Year] [INT] NULL ,
            [HICN] [VARCHAR](15) NULL ,
            [Updated HCC] [VARCHAR](20) NULL ,
            [AnnualizedEstimatedValue] [MONEY] NULL ,
            [ThruDate] [DATE] NULL ,
            [Provider ID] [VARCHAR](40) NULL ,
            [PROCESSED_PRIORITY_DIAG] [VARCHAR](20) NULL ,
            [PROCESSED_PRIORITY_PCN] [VARCHAR](50) NULL ,
            [Unq_Conditions] BIT NULL ,
            [PROCESSED_PRIORITY_PROCESSED_BY] DATETIME NULL ,
            [FormatPROCESSED_PRIORITY_PROCESSED_BY] DATE NULL ,
            [RA_FACTOR_TYPE] [VARCHAR](2) NULL,
			[EncounterSource]	[VARCHAR] (4)
        )

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('027', 0, 1) WITH NOWAIT
        END

    INSERT INTO [#09-Filtered DATA Results] (   [SubProjectId] ,
                                                [PMH_Attestation] ,
                                                [Model_Year] ,
                                                [HICN] ,
                                                [Updated HCC] ,
                                                [AnnualizedEstimatedValue] ,
                                                [ThruDate] ,
                                                [Provider ID] ,
                                                [PROCESSED_PRIORITY_DIAG] ,
                                                [PROCESSED_PRIORITY_PCN] ,
                                                [Unq_Conditions] ,
                                                [PROCESSED_PRIORITY_PROCESSED_BY] ,
                                                [FormatPROCESSED_PRIORITY_PROCESSED_BY] ,
                                                [RA_FACTOR_TYPE],
												[EncounterSource]
                                            )
                SELECT   [SubProjectId] = [a2].[SubProjectId] ,
                         [PMH_Attestation] = [a2].[PMH_Attestation] ,
                         [Model_Year] = [a2].[Model_Year] ,
                         [HICN] = [a2].[HICN] ,
                         [Updated HCC] = [a2].[Updated HCC] ,
                         [AnnualizedEstimatedValue] = SUM([a2].[AnnualizedEstimatedValue]) ,
                         [ThruDate] = CAST([a2].[PROCESSED_PRIORITY_THRU_DATE] AS DATE) ,
                         [Provider ID] = COALESCE([a2].[PCN_ProviderId], [a2].[PROVIDER_ID], SUBSTRING(
                                                                                                          [a2].[HCC_PROCESSED_PCN] ,
                                                                                                          15 ,
                                                                                                          10
                                                                                                      )) ,
                         [PROCESSED_PRIORITY_DIAG] = [a2].[PROCESSED_PRIORITY_DIAG] ,
                         [HCC_PROCESSED_PCN] = [a2].[HCC_PROCESSED_PCN] ,
                         [Unq_Conditions] = [a2].[Unq_Conditions] ,
                         [PROCESSED_PRIORITY_PROCESSED_BY] = [a2].[PROCESSED_PRIORITY_PROCESSED_BY] ,
                         [FormatPROCESSED_PRIORITY_PROCESSED_BY] = CAST([a2].[PROCESSED_PRIORITY_PROCESSED_BY] AS DATE) ,
                         [RA_FACTOR_TYPE] = [a2].[RA_FACTOR_TYPE],
						 a2.[EncounterSource]
                FROM     [#02-Flagging PartC Subprojects] [a2]
                WHERE    [a2].[SubProjectId] IS NOT NULL
                         AND [a2].[SubProjectId] <> ''
                         AND EncounterSource = 'RAPS'
                GROUP BY [a2].[SubProjectId] ,
                         [a2].[PMH_Attestation] ,
                         [a2].[Model_Year] ,
                         [a2].[HICN] ,
                         [a2].[Updated HCC] ,
                         [a2].[RA_FACTOR_TYPE] ,
                         CAST([a2].[PROCESSED_PRIORITY_THRU_DATE] AS DATE) ,
                         SUBSTRING([a2].[HCC_PROCESSED_PCN], 15, 10) ,
                         [a2].[PROCESSED_PRIORITY_DIAG] ,
                         [a2].[HCC_PROCESSED_PCN] ,
                         [a2].[Unq_Conditions] ,
                         [a2].[PROCESSED_PRIORITY_PROCESSED_BY] ,
                         [a2].[PROVIDER_ID] ,
                         [a2].[PCN_ProviderId],
						 a2.[EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '027 - Notice: Zero rows loaded to [#09-Filtered DATA Results]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    /*E 09-Filtered Data Results */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('027.1', 0, 1) WITH NOWAIT
        END


    UPDATE [m]
    SET    [m].[Provider ID] = SUBSTRING(
                                            ( [m].[Provider ID] ) ,
                                            1 ,
                                            PATINDEX('%[_]%', [m].[Provider ID])
                                            - 1
                                        )
    FROM   [#09-Filtered DATA Results] [m]
    WHERE  PATINDEX('%[_]%', [m].[Provider ID]) - 1 > 0




    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('028', 0, 1) WITH NOWAIT
        END

    IF ( OBJECT_ID('tempdb.dbo.[#11-Filtered Data Results]') IS NOT NULL )
        BEGIN
            DROP TABLE [#11-Filtered Data Results]
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('029', 0, 1) WITH NOWAIT
        END

    CREATE TABLE [#11-Filtered Data Results]
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
            [SubProjectId] [INT] NOT NULL ,
            [PMH_Attestation] [VARCHAR](255) NULL ,
            [ReviewName] [VARCHAR](50) NULL ,
            [Model_Year] [INT] NULL ,
            [HICN] [VARCHAR](15) NULL ,
            [Updated HCC] [VARCHAR](20) NULL ,
            [AnnualizedEstimatedValue] [MONEY] NULL ,
            [ThruDate] [DATE] NULL ,
            [Provider ID] [VARCHAR](40) NULL ,
            [PROCESSED_PRIORITY_DIAG] [VARCHAR](20) NULL ,
            [HCC_PROCESSED_PCN] [VARCHAR](50) NULL ,
            [RA_FACTOR_TYPE] [VARCHAR](2) NULL ,
            [Unq_Conditions] [BIT] NULL ,
            [PROCESSED_PRIORITY_PROCESSED_BY] [DATETIME] NULL,
			[EncounterSource] [VARCHAR](4) NULL 
        )

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('030', 0, 1) WITH NOWAIT
        END

    /*B 11-Filtered Data Results */

    INSERT INTO [#11-Filtered Data Results] (   [SubProjectId] ,
                                                [PMH_Attestation] ,
                                                [ReviewName] ,
                                                [Model_Year] ,
                                                [HICN] ,
                                                [Updated HCC] ,
                                                [AnnualizedEstimatedValue] ,
                                                [ThruDate] ,
                                                [Provider ID] ,
                                                [PROCESSED_PRIORITY_DIAG] ,
                                                [HCC_PROCESSED_PCN] ,
                                                [RA_FACTOR_TYPE] ,
                                                [Unq_Conditions] ,
                                                [PROCESSED_PRIORITY_PROCESSED_BY],
												[EncounterSource]
                                            )
                SELECT   [SubProjectId] = [a10].[SubProjectId] ,
                         [PMH_Attestation] = [a10].[PMH_Attestation] ,
                         [ReviewName] = [fad].[ReviewName] ,
                         [Model_Year] = [a10].[Model_Year] ,
                         [HICN] = [a10].[HICN] ,
                         [Updated HCC] = [a10].[Updated HCC] ,
                         [AnnualizedEstimatedValue] = [a10].[AnnualizedEstimatedValue] ,
                         [ThruDate] = [a10].[ThruDate] ,
                         [Provider ID] = [a10].[Provider ID] ,
                         [PROCESSED_PRIORITY_DIAG] = [a10].[PROCESSED_PRIORITY_DIAG] ,
                         [HCC_PROCESSED_PCN] = [a10].[PROCESSED_PRIORITY_PCN] ,
                         [RA_FACTOR_TYPE] = [a10].[RA_FACTOR_TYPE] ,
                         [Unq_Conditions] = [a10].[Unq_Conditions] ,
                         [PROCESSED_PRIORITY_PROCESSED_BY] = [a10].[PROCESSED_PRIORITY_PROCESSED_BY],
						 [a10].[EncounterSource]
                FROM     [Valuation].[FilteredAuditCWFDetail] [fad]
                         JOIN [#09-Filtered DATA Results] [a10] ON [fad].[DOSEndDt] = [a10].[ThruDate]
                                                                   --              AND [fad].[ProviderId]    = [a10].[Provider ID]
                                                                   --       AND LEFT([fad].[ProviderId], PATINDEX('%[_]%', [fad].[ProviderId]) - 1) = [a10].[Provider ID]
                                                                   AND CASE WHEN PATINDEX(
                                                                                             '%[_]%' ,
                                                                                             [fad].[ProviderId]
                                                                                         )
                                                                                 - 1 <= 0 THEN
                                                                                [fad].[ProviderId]
                                                                            ELSE
                                                                                LEFT([fad].[ProviderId], PATINDEX(
                                                                                                                     '%[_]%' ,
                                                                                                                     [fad].[ProviderId]
                                                                                                                 )
                                                                                                         - 1)
                                                                       END = [a10].[Provider ID]
                                                                   AND [fad].[DiagnosisCode] = [a10].[PROCESSED_PRIORITY_DIAG]
                                                                   AND [fad].[HICN] = [a10].[HICN] /*B MC 2015-07-30 */

                         JOIN @FA_ReviewName [frnfd]
                    /*E MC 2015-07-30 */
                    ON   [fad].[ProjectId] = [frnfd].[ProjectId]
                         AND [fad].[SubProjectId] = [frnfd].[SubProjectId] /*B MC 2015-07-30 */
                         AND [fad].[ReviewName] = [frnfd].[FAReviewName]

                /*B MC 2015-07-30 */
                WHERE    [fad].[AutoProcessRunId] = @AutoProcessRunIdFA
                         AND [fad].[CurrentImageStatus] IN ( 'Ready for Release' ,
                                                             'Coding/Review Complete'
                                                           ) /*MC 2015-05-01*/
                         AND [a10].[FormatPROCESSED_PRIORITY_PROCESSED_BY] > [frnfd].[StartDate]
                GROUP BY [a10].[SubProjectId] ,
                         [a10].[PMH_Attestation] ,
                         [fad].[ReviewName] ,
                         [a10].[Model_Year] ,
                         [a10].[HICN] ,
                         [a10].[Updated HCC] ,
                         [a10].[AnnualizedEstimatedValue] ,
                         [a10].[ThruDate] ,
                         [a10].[Provider ID] ,
                         [a10].[PROCESSED_PRIORITY_DIAG] ,
                         [a10].[PROCESSED_PRIORITY_PCN] ,
                         [a10].[RA_FACTOR_TYPE] ,
                         [a10].[Unq_Conditions] ,
                         [a10].[PROCESSED_PRIORITY_PROCESSED_BY],
						 [a10].[EncounterSource]


    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '030 - Notice: Zero rows loaded to [#11-Filtered Data Results]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    /*E 11-Filtered Data Results */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('031', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[CalcFilteredAuditsTotalForCI] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('032', 0, 1) WITH NOWAIT
        END

        /*B 12-Filtered Audits Total for CI*/

        --
        /**/;
    WITH [CTE_a11]
    AS ( SELECT   [ClientId] = @ClientId ,
                  [AutoProcessRunId] = @AutoProcessRunId ,
                  [SubProjectId] = [a11].[SubProjectId] ,
                  [Model_Year] = [a11].[Model_Year] ,
                  [ReviewName] = [a11].[ReviewName] ,
                  [HCC] = CASE WHEN [a11].[Unq_Conditions] = 1 THEN 1 --[a11].[HICN]
                           END ,
                  [AnnualizedEstimatedValue] = SUM([a11].[AnnualizedEstimatedValue]) ,
                  [Updated Hcc] = [a11].[Updated HCC] ,
                  [PopulatedDate] = @PopulatedDate,
				  [a11].[EncounterSource]
         FROM     [#11-Filtered Data Results] [a11]
         WHERE    [a11].[RA_FACTOR_TYPE] IN ( 'C', 'I', 'CN', 'CP', 'CF' )
         GROUP BY [a11].[SubProjectId] ,
                  [a11].[Model_Year] ,
                  [a11].[ReviewName] ,
                  [a11].[Unq_Conditions] ,
                  --[a11].[HICN] ,
                  [a11].[Updated HCC],
				  [EncounterSource]
       )
    INSERT INTO [Valuation].[CalcFilteredAuditsTotalForCI] (   [ClientId] ,
                                                               [AutoProcessRunId] ,
                                                               [SubProjectId] ,
                                                               [Model_Year] ,
                                                               [ReviewName] ,
                                                               [HCCTotal] ,
                                                               [AnnualizedEstimatedValue] ,
                                                               [PopulatedDate],
															   [EncounterSource]
                                                           )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a11].[SubProjectId] ,
                         [Model_Year] = [a11].[Model_Year] ,
                         [ReviewName] = [a11].[ReviewName] ,
                         [HCCTotal] = SUM([a11].[HCC]), /*???????*/
                         [AnnualizedEstimatedValue] = SUM([a11].[AnnualizedEstimatedValue]) ,
                         [PopulatedDate] = @PopulatedDate,
						 [EncounterSource]
                FROM     [CTE_a11] [a11]
                GROUP BY [a11].[SubProjectId] ,
                         [a11].[Model_Year] ,
                         [a11].[ReviewName],
						 [a11].[EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '032 - Notice: Zero rows loaded to [Valuation].[CalcFilteredAuditsTotalForCI]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    /*E 12-Filtered Audits Total for CI*/

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('033', 0, 1) WITH NOWAIT
        END

    /*B 15-Filtered Audits Total for ESRD */

    DELETE [m]
    FROM  [Valuation].[CalcFilteredAuditsTotalForESRD] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('034', 0, 1) WITH NOWAIT
        END

        --
        /**/;
    WITH [CTE_a11]
    AS ( SELECT   [ClientId] = @ClientId ,
                  [AutoProcessRunId] = @AutoProcessRunId ,
                  [SubProjectId] = [a11].[SubProjectId] ,
                  [Model_Year] = [a11].[Model_Year] ,
                  [ReviewName] = [a11].[ReviewName] ,
                  [AnnualizedEstimatedValue] = SUM([a11].[AnnualizedEstimatedValue]) ,
                  [Updated HCC] = [a11].[Updated HCC] ,
                  [HCC] = CASE WHEN [a11].[Unq_Conditions] = 1 THEN 1 --[a11].[HICN]
                           END,
				  [a11].[EncounterSource]
         FROM     [#11-Filtered Data Results] [a11]
         WHERE    [a11].[RA_FACTOR_TYPE] NOT IN ( 'C', 'I', 'CN', 'CP', 'CF' )
         GROUP BY [a11].[SubProjectId] ,
                  [a11].[Model_Year] ,
                  [a11].[ReviewName] ,
                  [a11].[Updated HCC] ,
                  [a11].[Unq_Conditions] ,
                  --[a11].[HICN],
				  [a11].[EncounterSource]
       )
    INSERT INTO [Valuation].[CalcFilteredAuditsTotalForESRD] (   [ClientId] ,
                                                                 [AutoProcessRunId] ,
                                                                 [SubProjectId] ,
                                                                 [Model_Year] ,
                                                                 [ReviewName] ,
                                                                 [AnnualizedEstimatedValue] ,
                                                                 [HCCTotal] ,
                                                                 [PopulatedDate],
																 [EncounterSource]
                                                             )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a11].[SubProjectId] ,
                         [Model_Year] = [a11].[Model_Year] ,
                         [ReviewName] = [a11].[ReviewName] ,
                         [AnnualizedEstimatedValue] = SUM([a11].[AnnualizedEstimatedValue]) ,
                         [HCCTotal] = SUM([a11].[HCC]) ,
                         [PopulatedDate] = @PopulatedDate,
						 [a11].[EncounterSource]
                FROM     [CTE_a11] [a11]
                GROUP BY [a11].[SubProjectId] ,
                         [a11].[Model_Year] ,
                         [a11].[ReviewName],
						 [a11].[EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '034 - Notice: Zero rows loaded to [Valuation].[CalcFilteredAuditsTotalForESRD]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    /*E 15-Filtered Audits Total for ESRD */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('035', 0, 1) WITH NOWAIT
        END

    /*B 21-PMH and Attestation Totals ESRD */

    DELETE [m]
    FROM  [Valuation].[CalcPMHAndAttestationTotalsESRD] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('036', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[CalcPMHAndAttestationTotalsESRD] (   [ClientId] ,
                                                                  [AutoProcessRunId] ,
                                                                  [SubProjectId] ,
                                                                  [PMH_Attestation] ,
                                                                  [Payment_Year] ,
                                                                  [Model_Year] ,
                                                                  [AnnualizedEstimatedValue] ,
                                                                  [PopulatedDate], 
																  [EncounterSource]
                                                              )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a2].[SubProjectId] ,
                         [PMH_Attestation] = [a2].[PMH_Attestation] ,
                         [Payment_Year] = [a2].[PAYMENT_YEAR] ,
                         [Model_Year] = [a2].[Model_Year] ,
                         [AnnualizedEstimatedValue] = SUM([a2].[AnnualizedEstimatedValue]) ,
                         [PopulatedDate] = @PopulatedDate, 
						 [a2].[EncounterSource]
                FROM     [#02-Flagging PartC Subprojects] [a2]
                WHERE    (   [a2].[SubProjectId] IS NOT NULL
                             AND [a2].[SubProjectId] <> ''
                         )
                         AND (   [a2].[PMH_Attestation] IS NOT NULL
                                 AND [a2].[PMH_Attestation] <> ''
                             )
                         AND [a2].[RA_FACTOR_TYPE] NOT IN ( 'C', 'I', 'CN' ,
                                                            'CP' ,'CF'
                                                          )
                GROUP BY [a2].[SubProjectId] ,
                         [a2].[PMH_Attestation] ,
                         [a2].[PAYMENT_YEAR] ,
                         [a2].[Model_Year],
						 [EncounterSource]


    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '036 - Notice: Zero rows loaded to [Valuation].[CalcPMHAndAttestationTotalsESRD]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 21-PMH and Attestation Totals ESRD */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('037', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[CalcPMHAndAttestationHCCTotalsESRD] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('038', 0, 1) WITH NOWAIT
        END

        --		
        /**/;
    WITH [CTE_a22]
    AS ( /*B 22-PMH and Attestation Condition Flag ESRD */ SELECT   [SubProjectId] = [a2].[SubProjectId] ,
                                                                    [PMH_Attestation] = [a2].[PMH_Attestation] ,
                                                                    [Payment_Year] = [a2].[PAYMENT_YEAR] ,
                                                                    [Model_Year] = [a2].[Model_Year] ,
                                                                    [HICN] = [a2].[HICN] ,
                                                                    [RA_FACTOR_TYPE] = [a2].[RA_FACTOR_TYPE],
																	[a2].[EncounterSource]
                                                           FROM     [#02-Flagging PartC Subprojects] [a2]
                                                           WHERE    [a2].[Unq_Conditions] = 1
                                                                    AND (   [a2].[SubProjectId] IS NOT NULL
                                                                            AND [a2].[SubProjectId] <> ''
                                                                        )
                                                                    AND (   [a2].[PMH_Attestation] IS NOT NULL
                                                                            AND [a2].[PMH_Attestation] <> ''
                                                                        )
                                                                    AND [a2].[RA_FACTOR_TYPE] NOT IN ( 'C' ,
                                                                                                       'I' ,
                                                                                                       'CN' ,
                                                                                                       'CP' ,
                                                                                                       'CF'
                                                                                                     )
                                                           GROUP BY [a2].[SubProjectId] ,
                                                                    [a2].[PMH_Attestation] ,
                                                                    [a2].[PAYMENT_YEAR] ,
                                                                    [a2].[Model_Year] ,
                                                                    [a2].[HICN] ,
                                                                    [a2].[RA_FACTOR_TYPE], /*E 22-PMH and Attestation Condition Flag ESRD */
																	[a2].[EncounterSource]
       ) /*B 23-PMH and Attestation HCC Totals ESRD */
    INSERT INTO [Valuation].[CalcPMHAndAttestationHCCTotalsESRD] (   [ClientId] ,
                                                                     [AutoProcessRunId] ,
                                                                     [SubProjectId] ,
                                                                     [PMH_Attestation] ,
                                                                     [Payment_Year] ,
                                                                     [Model_Year] ,
                                                                     [CountOfHICN] ,
                                                                     [PopulatedDate],
																	 [EncounterSource]
                                                                 )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a22].[SubProjectId] ,
                         [PMH_Attestation] = [a22].[PMH_Attestation] ,
                         [Payment_Year] = [a22].[Payment_Year] ,
                         [Model_Year] = [a22].[Model_Year] ,
                         [CountOfHICN] = COUNT(DISTINCT [a22].[HICN]) ,
                         [PopulatedDate] = @PopulatedDate,
						 a22.[EncounterSource]
                FROM     [CTE_a22] [a22]
                GROUP BY [a22].[SubProjectId] ,
                         [a22].[PMH_Attestation] ,
                         [a22].[Payment_Year] ,
                         [a22].[Model_Year],
						 [EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '038 - Notice: Zero rows loaded to [Valuation].[CalcPMHAndAttestationHCCTotalsESRD]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 23-PMH and Attestation HCC Totals ESRD */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('039', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[CalcPMHAttestationFilteredAuditHCCTotalsCI] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('040', 0, 1) WITH NOWAIT
        END /**/;
    WITH [CTE_a25]
    AS ( /*B 25-PMH Attestation Filtered Audit Condition Flag CI */ SELECT   [SubProjectId] = [a11].[SubProjectId] ,
                                                                             [PMH_Attestation] = [a11].[PMH_Attestation] ,
                                                                             [ReviewName] = [a11].[ReviewName] ,
                                                                             [Model_Year] = [a11].[Model_Year] ,
                                                                             [HICN] = CASE WHEN [a11].[Unq_Conditions] = 1 THEN
                                                                                               1
                                                                                      END ,
                                                                             [Updated HCC] = [a11].[Updated HCC] ,
                                                                             [AnnualizedEstimatedValue] = SUM([a11].[AnnualizedEstimatedValue]), 
																			 a11.[EncounterSource]
                                                                    FROM     [#11-Filtered Data Results] [a11]
                                                                    WHERE    [a11].[PMH_Attestation] <> ''
                                                                             AND ( [a11].[RA_FACTOR_TYPE] IN ( 'C' ,
                                                                                                               'I' ,
                                                                                                               'CN' ,
                                                                                                               'CP' ,
                                                                                                               'CF'
                                                                                                             )
                                                                                 --  AND [a11].[Unq_Conditions] = 1
                                                                                 )
                                                                    GROUP BY [a11].[SubProjectId] ,
                                                                             [a11].[PMH_Attestation] ,
                                                                             [a11].[ReviewName] ,
                                                                             [a11].[Model_Year] ,
                                                                             [a11].[HICN] ,
                                                                             [a11].[Updated HCC] ,
                                                                                                    -- , [a11].[AnnualizedEstimatedValue]
                                                                             [a11].[Unq_Conditions], /*E 25-PMH Attestation Filtered Audit Condition Flag CI */
																			 [a11].[EncounterSource]
       ) /*B 26-PMH Attestation Filtered Audit HCC Totals CI */
    INSERT INTO [Valuation].[CalcPMHAttestationFilteredAuditHCCTotalsCI] (   [ClientId] ,
                                                                             [AutoProcessRunId] ,
                                                                             [SubProjectId] ,
                                                                             [PMH_Attestation] ,
                                                                             [ReviewName] ,
                                                                             [Model_Year] ,
                                                                             [HCCTotal] ,
                                                                             [AnnualizedEstimatedValue] ,
                                                                             [PopulatedDate],
																			 [EncounterSource]
                                                                         )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a25].[SubProjectId] ,
                         [PMH_Attestation] = [a25].[PMH_Attestation] ,
                         [ReviewName] = [a25].[ReviewName] ,
                         [Model_Year] = [a25].[Model_Year] ,
                         [HCCTotal] = SUM([a25].[HICN]) ,
                         [AnnualizedEstimatedValue] = SUM([a25].[AnnualizedEstimatedValue]) ,
                         [PopulatedDate] = @PopulatedDate,
						 [EncounterSource]
                FROM     [CTE_a25] [a25]
                GROUP BY [a25].[SubProjectId] ,
                         [a25].[PMH_Attestation] ,
                         [a25].[ReviewName] ,
                         [a25].[Model_Year],
						 [EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '040 - Notice: Zero rows loaded to [Valuation].[CalcPMHAttestationFilteredAuditHCCTotalsCI]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 26-PMH Attestation Filtered Audit HCC Totals CI */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('041', 0, 1) WITH NOWAIT
        END

    /*B 27-PMH Attestation Filtered Audit Totals ESRD */

    DELETE [m]
    FROM  [Valuation].[CalcPMHAttestationFilteredAuditTotalsESRD] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('042', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[CalcPMHAttestationFilteredAuditTotalsESRD] (   [ClientId] ,
                                                                            [AutoProcessRunId] ,
                                                                            [SubProjectId] ,
                                                                            [PMH_Attestation] ,
                                                                            [ReviewName] ,
                                                                            [Model_Year] ,
                                                                            [HCCTotal] ,
                                                                            [AnnualizedEstimatedValue] ,
                                                                            [PopulatedDate],
																			[EncounterSource]
                                                                        )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a11].[SubProjectId] ,
                         [PMH_Attestation] = [a11].[PMH_Attestation] ,
                         [ReviewName] = [a11].[ReviewName] ,
                         [Model_Year] = [a11].[Model_Year] ,
                         [HCCTotal] = COUNT(DISTINCT [a11].[HICN]) ,
                         [AnnualizedEstimatedValue] = SUM([a11].[AnnualizedEstimatedValue]) ,
                         [PopulatedDate] = @PopulatedDate,
						 [EncounterSource]
                FROM     [#11-Filtered Data Results] [a11]
                WHERE    [a11].[PMH_Attestation] <> ''
                         AND [a11].[RA_FACTOR_TYPE] NOT IN ( 'C', 'I', 'CN' ,
                                                             'CP' ,'CF'
                                                           )
                GROUP BY [a11].[SubProjectId] ,
                         [a11].[PMH_Attestation] ,
                         [a11].[ReviewName] ,
                         [a11].[Model_Year],
						 [EncounterSource]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '042 - Notice: Zero rows loaded to [Valuation].[CalcPMHAttestationFilteredAuditTotalsESRD]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 27-PMH Attestation Filtered Audit Totals ESRD */


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('043', 0, 1) WITH NOWAIT
        END

    IF ( OBJECT_ID('tempdb.dbo.[#36-Flagging PartD Subprojects]') IS NOT NULL )
        BEGIN
            DROP TABLE [#36-Flagging PartD Subprojects]
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('044', 0, 1) WITH NOWAIT
        END

    CREATE TABLE [#36-Flagging PartD Subprojects]
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
            [SubProjectId] [VARCHAR](32) NULL ,
            [PMH_Attestation] [VARCHAR](255) NULL ,
            [PAYMENT_YEAR] [CHAR](4) NULL ,
            [PROCESSED_BY_START] [SMALLDATETIME] NULL ,
            [PROCESSED_BY_END] [SMALLDATETIME] NULL ,
            [PLAN_ID] [VARCHAR](5) NULL ,
            [Provider ID] [VARCHAR](40) NULL ,
            [Medicare] [VARCHAR](15) NULL ,
            [HCC_PROCESSED_PCN] [VARCHAR](50) NULL ,
            [HCC_DESCRIPTION] [VARCHAR](200) NULL ,
            [TYPE] [VARCHAR](6) NULL ,
            [RxHCC_FACTOR] [MONEY] NULL ,
            [HCC] [VARCHAR](20) NULL ,
            [HIER_RxHCC] [VARCHAR](20) NULL ,
            [HIER_RxHCC_FACTOR] [MONEY] NULL ,
            [Member_Months] [INT] NULL ,
            [RollForward_Months] [INT] NULL ,
            [ESRD] [CHAR](3) NULL ,
            [HOSP] [CHAR](3) NULL ,
            [PBP] [CHAR](3) NULL ,
            [SCC] [VARCHAR](5) NULL ,
            [BID_AMOUNT] [MONEY] NULL ,
            [UNQ_CONDITIONS] BIT ,
            [Estimated_Value] [MONEY] NULL ,
            [ANNUALIZED_ESTIMATED_VALUE] [MONEY] NULL ,
            [PROCESSED_PRIORITY_DIAG] [VARCHAR](20) NULL ,
            [PROCESSED_PRIORITY_PROCESSED_BY] [DATETIME] NULL ,
            [PROCESSED_PRIORITY_THRU_DATE] [DATETIME] NULL ,
            [RA_FACTOR_TYPE] [VARCHAR](5) NULL ,
            [PRIORITY] [VARCHAR](17) NULL, 
			[EncounterSource]	[VARCHAR] (4), 
			[Model_Year] INT
        )

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('045', 0, 1) WITH NOWAIT
        END

        --
        /**/;
    WITH [CTE_a35]
    AS ( /*B 35-PartD Strings */ SELECT [AuditString] = NULL,
                                        [PMH_Att_String] = NULL,
                                        [PAYMENT_YEAR] = [pd].[Payment_Year] ,
                                        [PROCESSED_BY_START] = [pd].[PROCESSED_BY_START] ,
                                        [PROCESSED_BY_END] = [pd].[PROCESSED_BY_END] ,
                                        [PLAN_ID] = [pd].[PlanId] ,
                                        [Provider ID] = ISNULL(
                                                                  [pd].[PCN_ProviderId] ,
                                                                  SUBSTRING(
                                                                               [pd].[HCC_PROCESSED_PCN] ,
                                                                               15 ,
                                                                               10
                                                                           )
                                                              ) ,
                                        [Medicare] = LTRIM(RTRIM([pd].[HICN])) ,
                                        [HCC_PROCESSED_PCN] = [pd].[HCC_PROCESSED_PCN] ,
                                        [HCC_DESCRIPTION] = [pd].[HCC_DESCRIPTION] ,
                                        [TYPE] = [pd].[TYPE] ,
                                        [RxHCC_FACTOR] = [pd].[RxHCC_FACTOR] ,
                                        [HCC] = LTRIM(RTRIM([pd].[RxHCC])) ,
                                        [HIER_RxHCC] = [pd].[HIER_RxHCC] ,
                                        [HIER_RxHCC_FACTOR] = [pd].[HIER_RxHCC_FACTOR] ,
                                        [Member_Months] = [pd].[MEMBER_MONTHS] ,
                                        [RollForward_Months] = [pd].[ROLLFORWARD_MONTHS] ,
                                        [ESRD] = [pd].[ESRD] ,
                                        [HOSP] = [pd].[HOSP] ,
                                        [PBP] = [pd].[PBP] ,
                                        [SCC] = [pd].[SCC] ,
                                        [BID_AMOUNT] = [pd].[BID_AMOUNT] ,
                                        [UNQ_CONDITIONS] = [pd].[UNQ_CONDITIONS] ,
                                        [Estimated_Value] = [pd].[ESTIMATED_VALUE] ,
                                        [ANNUALIZED_ESTIMATED_VALUE] = [pd].[ANNUALIZED_ESTIMATED_VALUE] ,
                                        [PROCESSED_PRIORITY_DIAG] = [pd].[PROCESSED_PRIORITY_DIAG] ,
                                        [PROCESSED_PRIORITY_PROCESSED_BY] = [pd].[PROCESSED_PRIORITY_PROCESSED_BY] ,
                                        [PROCESSED_PRIORITY_THRU_DATE] = [pd].[PROCESSED_PRIORITY_THRU_DATE] ,
                                        [RA_FACTOR_TYPE] = [pd].[RA_FACTOR_TYPE] ,
                                        [PRIORITY] = [pd].[PRIORITY] ,
                                        [PCN_SubProjectId] = [pd].[PCN_SubprojectId],
                                        [EncounterSource] = pd.[EncounterSource], 
                                        pd.MODEL_YEAR
                                 FROM   [Valuation].[NewHCCPartD] [pd]
                                 WHERE  [pd].[ProcessRunId] = @AutoProcessRunId /*E 35-PartD Strings */
       ) /*B 36-Flagging PartD Subprojects */
    INSERT INTO [#36-Flagging PartD Subprojects] (   [SubProjectId] ,
                                                     [PMH_Attestation] ,
                                                     [PAYMENT_YEAR] ,
                                                     [PROCESSED_BY_START] ,
                                                     [PROCESSED_BY_END] ,
                                                     [PLAN_ID] ,
                                                     [Provider ID] ,
                                                     [Medicare] ,
                                                     [HCC_PROCESSED_PCN] ,
                                                     [HCC_DESCRIPTION] ,
                                                     [TYPE] ,
                                                     [RxHCC_FACTOR] ,
                                                     [HCC] ,
                                                     [HIER_RxHCC] ,
                                                     [HIER_RxHCC_FACTOR] ,
                                                     [Member_Months] ,
                                                     [RollForward_Months] ,
                                                     [ESRD] ,
                                                     [HOSP] ,
                                                     [PBP] ,
                                                     [SCC] ,
                                                     [BID_AMOUNT] ,
                                                     [UNQ_CONDITIONS] ,
                                                     [Estimated_Value] ,
                                                     [ANNUALIZED_ESTIMATED_VALUE] ,
                                                     [PROCESSED_PRIORITY_DIAG] ,
                                                     [PROCESSED_PRIORITY_PROCESSED_BY] ,
                                                     [PROCESSED_PRIORITY_THRU_DATE] ,
                                                     [RA_FACTOR_TYPE] ,
                                                     [PRIORITY],
                                                     [EncounterSource], 
                                                     [Model_Year]
                                                 )
                SELECT DISTINCT [SubProjectId] = [a35].[PCN_SubProjectId] ,
                       [PMH_Attestation] = farn.[FailureReason] ,
                       [PAYMENT_YEAR] = [a35].[PAYMENT_YEAR] ,
                       [PROCESSED_BY_START] = [a35].[PROCESSED_BY_START] ,
                       [PROCESSED_BY_END] = [a35].[PROCESSED_BY_END] ,
                       [PLAN_ID] = [a35].[PLAN_ID] ,
                       [Provider ID] = [a35].[Provider ID] ,
                       [Medicare] = [a35].[Medicare] ,
                       [HCC_PROCESSED_PCN] = [a35].[HCC_PROCESSED_PCN] ,
                       [HCC_DESCRIPTION] = [a35].[HCC_DESCRIPTION] ,
                       [TYPE] = [a35].[Type] ,
                       [RxHCC_FACTOR] = [a35].[RxHCC_FACTOR] ,
                       [HCC] = [a35].[HCC] ,
                       [HIER_RxHCC] = [a35].[HIER_RxHCC] ,
                       [HIER_RxHCC_FACTOR] = [a35].[HIER_RxHCC_FACTOR] ,
                       [Member_Months] = [a35].[Member_Months] ,
                       [RollForward_Months] = [a35].[RollForward_Months] ,
                       [ESRD] = [a35].[ESRD] ,
                       [HOSP] = [a35].[HOSP] ,
                       [PBP] = [a35].[PBP] ,
                       [SCC] = [a35].[SCC] ,
                       [BID_AMOUNT] = [a35].[BID_AMOUNT] ,
                       [UNQ_CONDITIONS] = [a35].[UNQ_CONDITIONS] ,
                       [Estimated_Value] = [a35].[Estimated_Value] ,
                       [ANNUALIZED_ESTIMATED_VALUE] = [a35].[ANNUALIZED_ESTIMATED_VALUE] ,
                       [PROCESSED_PRIORITY_DIAG] = [a35].[PROCESSED_PRIORITY_DIAG] ,
                       [PROCESSED_PRIORITY_PROCESSED_BY] = [a35].[PROCESSED_PRIORITY_PROCESSED_BY] ,
                       [PROCESSED_PRIORITY_THRU_DATE] = [a35].[PROCESSED_PRIORITY_THRU_DATE] ,
                       [RA_FACTOR_TYPE] = [a35].[RA_FACTOR_TYPE] ,
                       [PRIORITY] = [a35].[PRIORITY],
                       [EncounterSource] = a35.[EncounterSource], 
                       a35.[Model_Year]
                   
                FROM   [CTE_a35] [a35]
                      
                       JOIN #ProjectSubprojectReviewList [farn] ON a35.PCN_SubProjectId = [farn].[SubProjectId]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '045 - Notice: Zero rows loaded to [#36-Flagging PartD Subprojects]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 36-Flagging PartD Subprojects */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('046', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[CalcPartDTotalsBySubProject] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('047', 0, 1) WITH NOWAIT
        END /**/;
    WITH [CTE_a37]
    AS ( /*B 37-Grouping Totals */ SELECT   [SubProjectId] = [a36].[SubProjectId] ,
                                            [Medicare] = 1 , --[a36].[Medicare]
                                            [HCC] = [a36].[HCC] ,
                                            [Estimated_Value] = SUM([a36].[Estimated_Value]) ,
                                            [ANNUALIZED_ESTIMATED_VALUE] = SUM([a36].[ANNUALIZED_ESTIMATED_VALUE]) ,
                                            [UNQ_CONDITIONS] = SUM(CAST([a36].[UNQ_CONDITIONS] AS TINYINT)), 
                                            [EncounterSource] = a36.[EncounterSource], 
                                            a36.PAYMENT_YEAR
                                   FROM     [#36-Flagging PartD Subprojects] [a36]
                                   WHERE    [a36].[SubProjectId] IS NOT NULL
                                            AND [a36].[SubProjectId] <> ''
                                   GROUP BY [a36].[SubProjectId] ,
                                            [a36].[Medicare] ,
                                            [a36].[HCC], 
                                            a36.[EncounterSource], 
                                            a36.PAYMENT_YEAR /*E 37-Grouping Totals */
							
       ) /*B 38-PartD Totals by SubProject */
    INSERT INTO [Valuation].[CalcPartDTotalsBySubProject] (   [ClientId] ,
                                                              [AutoProcessRunId] ,
                                                              [SubProjectId] ,
                                                              [RxHCCTotal] ,
                                                              [Estimated_Value] ,
                                                              [Annualized_Estimated_Value] ,
                                                              [UNQ_CONDITIONS] ,
                                                              [PopulatedDate], 
                                                              [EncounterSource], 
                                                              [ModelYear]
                                                          )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a37].[SubProjectId] ,
                         [HCCTotal] = SUM([a37].UNQ_CONDITIONS) ,
                         [Estimated_Value] = SUM([a37].[Estimated_Value]) ,
                         [ANNUALIZED_ESTIMATED_VALUE] = SUM([a37].[ANNUALIZED_ESTIMATED_VALUE]) ,
                         [UNQ_CONDITIONS] = SUM([a37].[UNQ_CONDITIONS]) ,
                         [PopulatedDate] = @PopulatedDate, 
                         [EncounterSource] = a37.[EncounterSource], 
                         a37.PAYMENT_YEAR 
                FROM     [CTE_a37] [a37]
                GROUP BY [a37].[SubProjectId],
                         a37.[EncounterSource], 
                         a37.PAYMENT_YEAR

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '048 - Notice: Zero rows loaded to [Valuation].[CalcPartDTotalsBySubProject]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 38-PartD Totals by SubProject */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('049', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[CalcPartDFilteredAuditTotals] [m]
    WHERE [m].[ClientId] = @ClientId
          AND [m].[AutoProcessRunId] = @AutoProcessRunId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('050', 0, 1) WITH NOWAIT
        END

        --		
        /**/;
    WITH [CTE_a42]
    AS ( /*B 41-PartD Data for Filtered Audit */ SELECT   [SubProjectId] = [a36].[SubProjectId] ,
                                                          [PMH_Attestation] = [a36].[PMH_Attestation] ,
                                                          [HICN] = [a36].[Medicare] ,
                                                          [HCC] = LTRIM(RTRIM([a36].[HCC])) ,
                                                          [DOS] = CONVERT(
                                                                             CHAR(8) ,
                                                                             [a36].[PROCESSED_PRIORITY_THRU_DATE],
                                                                             112
                                                                         ) ,
                                                          [Provider ID] = [a36].[Provider ID] ,
                                                          [PROCESSED_PRIORITY_DIAG] = [a36].[PROCESSED_PRIORITY_DIAG] ,
                                                          [HCC_PROCESSED_PCN] = [a36].[HCC_PROCESSED_PCN] ,
                                                          [Estimated_Value] = SUM([a36].[Estimated_Value]) ,
                                                          [ANNUALIZED_ESTIMATED_VALUE] = SUM([a36].[ANNUALIZED_ESTIMATED_VALUE]) ,
                                                          [UNQ_CONDITIONS] = SUM(CAST([a36].[UNQ_CONDITIONS] AS TINYINT)) ,
                                                          [PROCESSED_PRIORITY_PROCESSED_BY] = CAST([a36].[PROCESSED_PRIORITY_PROCESSED_BY] AS DATE)
                                                 FROM     [#36-Flagging PartD Subprojects] [a36]
                                                 WHERE    [a36].[SubProjectId] <> ''
                                                          AND [a36].[SubProjectId] IS NOT NULL
                                                 GROUP BY [a36].[SubProjectId] ,
                                                          [a36].[PMH_Attestation] ,
                                                          [a36].[Medicare] ,
                                                          LTRIM(RTRIM([a36].[HCC])) ,
                                                          CONVERT(
                                                                     CHAR(8) ,
                                                                     [a36].[PROCESSED_PRIORITY_THRU_DATE],
                                                                     112
                                                                 ) ,
                                                          [a36].[Provider ID] ,
                                                          [a36].[PROCESSED_PRIORITY_DIAG] ,
                                                          [a36].[HCC_PROCESSED_PCN] ,
                                                          [a36].[PROCESSED_PRIORITY_PROCESSED_BY] /*E 41-PartD Data for Filtered Audit */
       ) ,
         [CTE_a43]
    AS ( /*B 43-Filtered Audit Data */ SELECT   [HICN] = [fad].[HICN] ,
                                                [ProviderId] = [fad].[ProviderId] ,
                                                [DOS] = CONVERT(
                                                                   CHAR(8) ,
                                                                   [fad].[DOSEndDt],
                                                                   112
                                                               ) ,
                                                [DiagnosisCode] = [fad].[DiagnosisCode] ,
                                                [ReviewName] = [fad].[ReviewName] ,
                                                [ProjectId] = [fad].[ProjectId] ,
                                                [SubProjectId] = [fad].[SubProjectId]
                                       FROM     [Valuation].[FilteredAuditCWFDetail] [fad]
                                       WHERE    [fad].[AutoProcessRunId] = @AutoProcessRunIdFA
                                                AND [fad].[CurrentImageStatus] = 'Ready for Release'
                                       GROUP BY [fad].[HICN] ,
                                                [fad].[ProviderId] ,
                                                CONVERT(
                                                           CHAR(8) ,
                                                           [fad].[DOSEndDt],
                                                           112
                                                       ) ,
                                                [fad].[DiagnosisCode] ,
                                                [fad].[ReviewName] ,
                                                [fad].[ProjectId] ,
                                                [fad].[SubProjectId] /*E 43-Filtered Audit Data */
       ) ,
         [CTE_a44]
    AS ( /*B 44-PartD Filtered Audit Values */ SELECT   [SubProjectId] = [a42].[SubProjectId] ,
                                                        [PMH_Attestation] = [a42].[PMH_Attestation] ,
                                                        [ReviewName] = [a43].[ReviewName] ,
                                                        [HICN] = 1 , --[a42].[HICN]
                                                        [HCC] = [a42].[HCC] ,
                                                        [Estimated_Value] = [a42].[Estimated_Value] ,
                                                        [ANNUALIZED_ESTIMATED_VALUE] = [a42].[ANNUALIZED_ESTIMATED_VALUE] ,
                                                        [UNQ_CONDITIONS] = [a42].[UNQ_CONDITIONS] ,
                                                        [StartDate] = [frnfd].[StartDate]
                                               FROM     [CTE_a42] [a42]
                                                        JOIN [CTE_a43] [a43] ON [a42].[HICN] = [a43].[HICN]
                                                                                AND [a42].[PROCESSED_PRIORITY_DIAG] = [a43].[DiagnosisCode]
                                                                                --                    AND [a42].[Provider ID]              = [a43].[ProviderId]

                                                                                --AND [a42].[Provider ID]              = LEFT([a43].[ProviderId], PATINDEX(
                                                                                --                                                                    '%[_]%'
                                                                                --                                                                  , [a43].[ProviderId])
                                                                                --                                                                - 1)
                                                                                AND [a43].[ProviderId] = CASE WHEN PATINDEX(
                                                                                                                               '%[_]%' ,
                                                                                                                               [a43].[ProviderId]
                                                                                                                           )
                                                                                                                   - 1 <= 0 THEN
                                                                                                                  [a43].[ProviderId]
                                                                                                              ELSE
                                                                                                                  LEFT([a43].[ProviderId], PATINDEX(
                                                                                                                                                       '%[_]%' ,
                                                                                                                                                       [a43].[ProviderId]
                                                                                                                                                   )
                                                                                                                                           - 1)
                                                                                                         END
                                                                                AND [a42].[DOS] = [a43].[DOS]
                                                        JOIN @FA_ReviewName [frnfd] ON [a43].[ProjectId] = [frnfd].[ProjectId]
                                                                                       AND [a43].[SubProjectId] = [frnfd].[SubProjectId]
                                                                                       AND LTRIM(RTRIM([a43].[ReviewName])) = [frnfd].[FAReviewName]
                                               WHERE    [a42].[PROCESSED_PRIORITY_PROCESSED_BY] > [frnfd].[StartDate]
                                               GROUP BY [a42].[SubProjectId] ,
                                                        [a42].[PMH_Attestation] ,
                                                        [a43].[ReviewName] ,
                                                        [a42].[HICN] ,
                                                        [a42].[HCC] ,
                                                        [a42].[Estimated_Value] ,
                                                        [a42].[ANNUALIZED_ESTIMATED_VALUE] ,
                                                        [a42].[UNQ_CONDITIONS] ,
                                                        [frnfd].[StartDate] /*E 44-PartD Filtered Audit Values */
       ) /*B 45-PartD Filtered Audit Totals */
    INSERT INTO [Valuation].[CalcPartDFilteredAuditTotals] (   [ClientId] ,
                                                               [AutoProcessRunId] ,
                                                               [SubProjectId] ,
                                                               [PMH_Attestation] ,
                                                               [ReviewName] ,
                                                               [HCCTotal] ,
                                                               [EstimatedValue] ,
                                                               [Annualized_Estimated_Value] ,
                                                               [UNQ_CONDITIONS] ,
                                                               [PopulatedDate]
                                                           )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [SubProjectId] = [a44].[SubProjectId] ,
                         [PMH_Attestation] = [a44].[PMH_Attestation] ,
                         [ReviewName] = [a44].[ReviewName] ,
                         [HCCTotal] = SUM(CAST([a44].[UNQ_CONDITIONS] AS TINYINT)) ,
                         [EstimatedValue] = SUM([a44].[Estimated_Value]) ,
                         [ANNUALIZED_ESTIMATED_VALUE] = SUM([a44].[ANNUALIZED_ESTIMATED_VALUE]) ,
                         [UNQ_CONDITIONS] = SUM(CAST([a44].[UNQ_CONDITIONS] AS TINYINT)) ,
                         [PopulatedDate] = @PopulatedDate
                FROM     [CTE_a44] [a44]
                GROUP BY [a44].[SubProjectId] ,
                         [a44].[PMH_Attestation] ,
                         [a44].[ReviewName]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '050 - Notice: Zero rows loaded to [Valuation].[CalcPartDFilteredAuditTotals]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E 45-PartD Filtered Audit Totals */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('051', 0, 1) WITH NOWAIT
        END

    SELECT DISTINCT @ClientName = [ClientName]
    FROM   [Valuation].[ConfigClientMain]
    WHERE  [ClientId] = @ClientId
           AND [ActiveBDate] <= GETDATE()
           AND ISNULL([ActiveEDate], DATEADD(dd, 1, GETDATE())) >= GETDATE()

    SET @ClientName = ISNULL(@ClientName, '')

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('052', 0, 1) WITH NOWAIT
        END

    /*B Blended Payment Detail */

    /*  B Report: Blended Payment Detail */

    DELETE [m]
    FROM  [Valuation].[RptPaymentDetail] [m]
    WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
          AND [m].[ReportType] = 'Blended'
          AND [m].[ReportSubType] = 'PaymentDetail'
          AND [m].[ClientId] = @ClientId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('053', 0, 1) WITH NOWAIT
        END
        --


IF OBJECT_ID('TEMPDB..#EDSRAPSSubmissionSplit' )   IS NOT NULL 
  DROP    TABLE #EDSRAPSSubmissionSplit                                  
                                  
 CREATE TABLE [dbo].#EDSRAPSSubmissionSplit
 (
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PaymentYear] [int] NULL,
	[SubmissionModel] [varchar](4) NULL,
	[SubmissionSplitWeight] [decimal](18, 2) NULL)
	INSERT INTO    #EDSRAPSSubmissionSplit
	
	(PaymentYear, SubmissionSplitWeight,SubmissionModel)     
   SELECT   a.PaymentYear,
                a.SubmissionSplitWeight,
                  a.SubmissionModel
       FROM     HRPREPORTING.dbo.EDSRAPSSubmissionSplit a
         WHERE PaymentYear = @PaymentYear   
         GROUP BY a.PaymentYear,
                a.SubmissionSplitWeight,
                  a.SubmissionModel 
    
DECLARE @RAPS [decimal](18, 2), @EDS [decimal](18, 2) 
SET @RAPS = (select SubmissionSplitWeight from #EDSRAPSSubmissionSplit WHERE SubmissionModel = 'RAPS')
SET @EDS = (select SubmissionSplitWeight from #EDSRAPSSubmissionSplit WHERE SubmissionModel = 'EDS')           
            
        
        /**/;

    INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [EstRevPerChart_A] ,
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [EstRevPerChart_B],
                                                   [HCCRealizationRate_B] ,
                                                   [HCCTotal_ESRD] ,
                                                   [EstRev_ESRD] ,
                                                   [EstRevPerHCC_ESRD] ,
                                                   [HCCRealizationRate_ESRD] ,
                                                   [HCCTotal_Non_ESRD] ,
                                                   [EstRev_Non_ESRD] ,
                                                   [EstRevPerHCC_Non_ESRD] ,
                                                   [HCCRealizationRate_Non_ESRD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate], 
                                                   [Part_C_D]
                                               )
                SELECT DISTINCT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                       [ReportHeader] = 'RAPS EDS Blended Model Part C' , --@ClientName + ' - Blended Payment Detail'
                       [ReportType] = 'Blended' ,
                       [ReportSubType] = 'PaymentDetail' ,
                       [Header_A] = 'Part C - EDS' ,                 --CAST('2013 DOS/2014 Payment Year - 2013 Model (25%)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [Header_B] = 'Part C - RAPS' ,                --CAST('2013 DOS/2014 Payment Year - 2014 Model (75%)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [Header_ESRD] = @BlendedPaymentDetailHeaderESRD ,           --CAST('2013 DOS/2014 Payment Year - 2014 Model (100% ESRD)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [RowDisplay] = [a].[RowDisplay] ,
                       [ChartsCompleted] = [a].[ChartsCompleted] ,
                       [HCCTotal_A] = [a].[HCCTotal_A] ,/*EDS ESRD _ Non ESRD*/
                       [EstRev_A] = [a].[AnnualizedEstimatedValue_A] ,
                       [EstRevPerHCC_A] = CASE WHEN [a].[HCCTotal_A] = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_A]
                                                   / ( [a].[HCCTotal_A] * 1.0 )
                                          END ,
                       [EstRevPerCHart_A] = CASE WHEN [a].ChartsCompleted = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_A]
                                                   / ( [a].ChartsCompleted * 1.0 )
                                          END ,
                       [HCCRealizationRate_A] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                         0
                                                     ELSE
                       ( [a].[HCCTotal_A] / ( [a].[ChartsCompleted] * 1.0 )
                         * 100
                       )
                                                END ,
                       [HCCTotal_B] = [a].[HCCTotal_B] ,
                       [EstRev_B] = [a].[AnnualizedEstimatedValue_B] ,
                       [EstRevPerHCC_B] = CASE WHEN [a].[HCCTotal_B] = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_B]
                                                   / ( [a].[HCCTotal_B] * 1.0 )
                                          END ,
                       [EstRevPerCHart_B] = CASE WHEN [a].ChartsCompleted = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_B]
                                                   / ( [a].ChartsCompleted * 1.0 )
                                          END ,
                       [HCCRealizationRate_B] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                         0
                                                     ELSE
                       ( [a].[HCCTotal_B]
                         / (( [a].[ChartsCompleted] ) * 1.0 ) * 100
                       )
                                                END ,
                       [HCCTotal_ESRD] = [a].[HCCTotal_ESRD] ,
                       [EstRev_ESRD] = [a].[AnnualizedEstimatedValue_ESRD] ,
                       [EstRevPerHCC_ESRD] = CASE WHEN [a].[HCCTotal_ESRD] = 0 THEN
                                                      0
                                                  ELSE
                                                      [a].[AnnualizedEstimatedValue_ESRD]
                                                      / ( [a].[HCCTotal_ESRD]
                                                          * 1.0
                                                        )
                                             END ,
                       [HCCRealizationRate_ESRD] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                            0
                                                        ELSE
																   ( [a].[HCCTotal_ESRD]
																	 / (( [a].[ChartsCompleted] ) * 1.0 ) * 100
																   )
																							   END ,
                       
                       [HCCTotal_Non_ESRD] = [a].[HCCTotal_Non_ESRD] ,
                       [EstRev_Non_ESRD] = [a].[AnnualizedEstimatedValue_Non_ESRD] ,
                       [EstRevPerHCC_Non_ESRD] = CASE WHEN [a].[HCCTotal_Non_ESRD] = 0 THEN
                                                      0
                                                  ELSE
                                                      [a].[AnnualizedEstimatedValue_Non_ESRD]
                                                      / ( [a].[HCCTotal_Non_ESRD]
                                                          * 1.0
                                                        )
                                             END ,
                       [HCCRealizationRate_Non_ESRD] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                            0
																						ELSE
													   ( [a].[HCCTotal_Non_ESRD]
														 / (( [a].[ChartsCompleted] ) * 1.0 ) * 100
													   )
																				   END ,
                       [ProjectId] = [a].[ProjectId] ,
                       [ProjectDescription] = [a].[ProjectDescription] ,
                       [SubProjectId] = [a].[SubProjectId] ,
                       [SubProjectDescription] = [a].[SubProjectDescription] ,
                       [ReviewName] = [a].[ReviewName] ,
                       [ProjectSortOrder] = [a].[ProjectSortOrder] ,
                       [SubProjectSortOrder] = [a].[SubProjectSortOrder] ,
                       [OrderFlag] = [a].[OrderFlag] ,
                       [PopulatedDate] = @PopulatedDate,
                       'C'
                FROM   (   SELECT DISTINCT [AutoProcessRunId] = @AutoProcessRunId ,
                                  [RowDisplay] = CAST(a0.[SubProjectId] AS VARCHAR(11))
                                                 + ' - '
                                                 + [a0].[SubProjectDescription] ,
                                  [ChartsCompleted] = [ctrs].[ChartsComplete] ,
                                  [ModelYear_A] = [a1].[Model_Year] ,
                                  [HCCTotal_A] = ISNULL([a1].[HCCTotal],0) + ISNULL(d1.HCCTotal,0) ,/* EDS ESRD +NON ESRD */
                                  [AnnualizedEstimatedValue_A] = (ISNULL([a1].[AnnualizedEstimatedValue],0) + ISNULL(d1.AnnualizedEstimatedValue,0)) * @EDS ,
                                  [ModelYear_B] = [b1].[Model_Year] ,
                                  [HCCTotal_B] = ISNULL([b1].[HCCTotal],0) + ISNULL(C1.HCCTotal,0) , /* RAPS ESRD +NON ESRD */
                                  [AnnualizedEstimatedValue_B] = (ISNULL([b1].[AnnualizedEstimatedValue],0) + ISNULL(c1.AnnualizedEstimatedValue,0)) * @RAPS ,
                                  [HCCTotal_ESRD] = ( ISNULL([c1].[HCCTotal], 0)) * @RAPS + ( ISNULL([d1].[HCCTotal], 0))* @EDS, /* RAPS EDS  ESRD */
                                  [AnnualizedEstimatedValue_ESRD] = (ISNULL( [c1].[AnnualizedEstimatedValue] , 0 ))* @RAPS + (ISNULL( [d1].[AnnualizedEstimatedValue] , 0 ))* @EDS ,
                                  [HCCTotal_Non_ESRD] = (ISNULL([a1].[HCCTotal], 0)) * @EDS  +  (ISNULL([b1].[HCCTotal], 0)) * @RAPS , /* RAPS EDS NON ESRD */
                                  [AnnualizedEstimatedValue_Non_ESRD] = (ISNULL( [a1].[AnnualizedEstimatedValue] , 0)) * @EDS + (ISNULL( [b1].[AnnualizedEstimatedValue] , 0)) * @RAPS,   
                                  --[HCC] = (( ISNULL([a1].[HCCTotal], 0)
                                  --           + ISNULL([b1].[HCCTotal], 0)
                                  --         ) / 2
                                  --        )
                                  --        + ISNULL([c1].[HCCTotal], 0) ,
                                  --[Tot$$$] = ISNULL(
                                  --                     [a1].[AnnualizedEstimatedValue] ,
                                  --                     0
                                  --                 )
                                  --           + ISNULL(
                                  --                       [b1].[AnnualizedEstimatedValue] ,
                                  --                       0
                                  --                   )
                                  --           + ISNULL(
                                  --                       [c1].[AnnualizedEstimatedValue] ,
                                  --                       0
                                  --                   ) ,
                                  [ProjectId] = [a0].[ProjectId] ,
                                  [ProjectDescription] = [a0].[ProjectDescription] , --CAST([pspl].[ProjectId] AS VARCHAR(11)) + ' - ' + [pspl].[ProjectDescription]
                                  [SubProjectId] = [a0].[SubProjectId] ,
                                  [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                  [ReviewName] = NULL ,
                                  [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                  [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                  [OrderFlag] = 2
                           FROM   #ProjectSubprojectReviewList [a0]
                                  LEFT JOIN [Valuation].[CalcPartCSubProjectModelYearCI] [a1] ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                                 AND [a1].[ClientId] = @ClientId
                                                                                                 AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [a1].[Model_Year] = @ModelYearA
                                                                                                 AND [a1].EncounterSource = 'EDS'
                                  LEFT JOIN [Valuation].[CalcPartCSubProjectModelYearCI] [b1] ON [a0].[SubProjectId] = [b1].[SubProjectId]
                                                                                                 AND [b1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [b1].[ClientId] = @ClientId
                                                                                                 AND [b1].[Model_Year] = @ModelYearB
                                                                                                 AND [b1].EncounterSource = 'RAPS'
                                  LEFT JOIN [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD] [c1] ON [a0].[SubProjectId] = [c1].[SubProjectId]
                                                                                                              AND [c1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                              AND [c1].[ClientId] = @ClientId /*B Why?*/
                                                                                                              AND [c1].EncounterSource = 'RAPS'

                                 LEFT JOIN [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD] [d1] ON [a0].[SubProjectId] = [d1].[SubProjectId]
                                                                                                              AND [d1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                              AND [d1].[ClientId] = @ClientId /*B Why?*/
                                                                                                              AND [d1].EncounterSource = 'EDS'


                                  JOIN [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [ctrs].[SubProjectId]
                                                                                             AND [ctrs].[LoadDate] = @CTRLoadDate /**/) a;
             
             
     --------------------------------Part D START rptpaymentdetail ---------------------------------
         /**/;

    INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [EstRevPerChart_A] ,
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [EstRevPerChart_B],
                                                   [HCCRealizationRate_B] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate], 
                                                   [Part_C_D]
                                               )
                SELECT DISTINCT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                       [ReportHeader] = 'RAPS EDS Blended Model Part D' , --@ClientName + ' - Blended Payment Detail'
                       [ReportType] = 'Blended' ,
                       [ReportSubType] = 'PaymentDetail' ,
                       [Header_A] = 'Part D -EDS' ,                 --CAST('2013 DOS/2014 Payment Year - 2013 Model (25%)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [Header_B] = 'Part D -RAPS' ,                 --CAST('2013 DOS/2014 Payment Year - 2014 Model (75%)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [Header_ESRD] = @BlendedPaymentDetailHeaderESRD ,           --CAST('2013 DOS/2014 Payment Year - 2014 Model (100% ESRD)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [RowDisplay] = [a].[RowDisplay] ,
                       [ChartsCompleted] = [a].[ChartsCompleted] ,
                       [HCCTotal_A] = [a].[HCCTotal_A] ,/*EDS ESRD _ Non ESRD*/
                       [EstRev_A] = [a].[AnnualizedEstimatedValue_A] ,
                       [EstRevPerHCC_A] = CASE WHEN [a].[HCCTotal_A] = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_A]
                                                   / ( [a].[HCCTotal_A] * 1.0 )
                                          END ,
                       [EstRevPerCHart_A] = CASE WHEN [a].ChartsCompleted = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_A]
                                                   / ( [a].ChartsCompleted * 1.0 )
                                          END ,
                       [HCCRealizationRate_A] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                         0
                                                     ELSE
                       ( [a].[HCCTotal_A] / ( [a].[ChartsCompleted] * 1.0 )
                         * 100
                       )
                                                END ,
                       [HCCTotal_B] = [a].[HCCTotal_B] ,
                       [EstRev_B] = [a].[AnnualizedEstimatedValue_B] ,
                       [EstRevPerHCC_B] = CASE WHEN [a].[HCCTotal_B] = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_B]
                                                   / ( [a].[HCCTotal_B] * 1.0 )
                                          END ,
                       [EstRevPerCHart_B] = CASE WHEN [a].ChartsCompleted = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_B]
                                                   / ( [a].ChartsCompleted * 1.0 )
                                          END ,
                       [HCCRealizationRate_B] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                         0
                                                     ELSE
                       ( [a].[HCCTotal_B]
                         / (( [a].[ChartsCompleted] ) * 1.0 ) * 100
                       )
                                                END ,
                       [ProjectId] = [a].[ProjectId] ,
                       [ProjectDescription] = [a].[ProjectDescription] ,
                       [SubProjectId] = [a].[SubProjectId] ,
                       [SubProjectDescription] = [a].[SubProjectDescription] ,
                       [ReviewName] = [a].[ReviewName] ,
                       [ProjectSortOrder] = [a].[ProjectSortOrder] ,
                       [SubProjectSortOrder] = [a].[SubProjectSortOrder] ,
                       [OrderFlag] = [a].[OrderFlag] ,
                       [PopulatedDate] = @PopulatedDate,
                       'D'
                FROM   (   SELECT DISTINCT [AutoProcessRunId] = @AutoProcessRunId ,
                                  [RowDisplay] = CAST([a0].[SubProjectId] AS VARCHAR(11))
                                                 + ' - '
                                                 + [a0].[SubProjectDescription] ,
                                  [ChartsCompleted] = [ctrs].[ChartsComplete] ,
                                  [ModelYear_A] = @PaymentYear /* No Model Year for Part D */ ,
                                  [HCCTotal_A] = ISNULL([a1].RxHCCTotal,0)  ,/* EDS ESRD +NON ESRD */
                                  [AnnualizedEstimatedValue_A] = (ISNULL([a1].Annualized_Estimated_Value,0) ) * @EDS ,
                                  [ModelYear_B] = @PaymentYear /* No Model Year for Part D */ ,
                                  [HCCTotal_B] = ISNULL([b1].RxHCCTotal,0)  , /* RAPS ESRD +NON ESRD */
                                  [AnnualizedEstimatedValue_B] = (ISNULL([b1].Annualized_Estimated_Value,0) ) * @RAPS , 
                                  [ProjectId] = [a0].[ProjectId] ,
                                  [ProjectDescription] = [a0].[ProjectDescription] , --CAST([pspl].[ProjectId] AS VARCHAR(11)) + ' - ' + [pspl].[ProjectDescription]
                                  [SubProjectId] = [a0].[SubProjectId] ,
                                  [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                  [ReviewName] = NULL ,
                                  [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                  [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                  [OrderFlag] = 2
                           FROM   #ProjectSubprojectReviewList [a0]
                                  LEFT JOIN [Valuation].[CalcPartDTotalsBySubProject] [a1] ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                                 AND [a1].[ClientId] = @ClientId
                                                                                                 AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [a1].[ModelYear] = @PaymentYear
                                                                                                 AND [a1].EncounterSource = 'EDS'
                                  LEFT JOIN [Valuation].[CalcPartDTotalsBySubProject] [b1] ON [a0].[SubProjectId] = [b1].[SubProjectId]
                                                                                                 AND [b1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [b1].[ClientId] = @ClientId
                                                                                                 AND [b1].[ModelYear] = @PaymentYear
                                                                                                 AND [b1].EncounterSource = 'RAPS'                              

                                  JOIN [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [ctrs].[SubProjectId]
                                                                                             AND [ctrs].[LoadDate] = @CTRLoadDate /**/) a;
                                                                                             
                                                                                               
     -------------------------------Part D END rpt paymentdetail ---------------------------

                                                                                             
                                                                                             
                           
    WITH [CTE_fac]
    AS ( SELECT   [facc].[AutoProcessRunId] ,
                  [facc].[SubProjectId] ,
                  [ReviewName] = LTRIM(RTRIM([facc].[ReviewName])) ,
                  [ChartsCompleted] = COUNT(DISTINCT [facc].[VeriskRequestId])
         FROM     [Valuation].[FilteredAuditCNCompletedChart] [facc] WITH ( NOLOCK )
         WHERE    [facc].[ClientId] = @ClientId
                  AND [facc].[AutoProcessRunId] = @AutoProcessRunIdFA
         GROUP BY [facc].[AutoProcessRunId] ,
                  [facc].[SubProjectId] ,
                  [facc].[ReviewName]
       )                 
       INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [HCCRealizationRate_B] ,
                                                   [HCCTotal_ESRD] ,
                                                   [EstRev_ESRD] ,
                                                   [EstRevPerHCC_ESRD] ,
                                                   [HCCRealizationRate_ESRD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate]
                                               )
                SELECT DISTINCT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                       [ReportHeader] = 'Blended Payment Detail - By Subproject' , --@ClientName + ' - Blended Payment Detail'
                       [ReportType] = 'Blended' ,
                       [ReportSubType] = 'PaymentDetail' ,
                       [Header_A] = @BlendedPaymentDetailHeaderA ,                 --CAST('2013 DOS/2014 Payment Year - 2013 Model (25%)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [Header_B] = @BlendedPaymentDetailHeaderB ,                 --CAST('2013 DOS/2014 Payment Year - 2014 Model (75%)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [Header_ESRD] = @BlendedPaymentDetailHeaderESRD ,           --CAST('2013 DOS/2014 Payment Year - 2014 Model (100% ESRD)' AS VARCHAR(128)) /*Note -Needs to be table driven */
                       [RowDisplay] = [a].[RowDisplay] ,
                       [ChartsCompleted] = [a].[ChartsCompleted] ,
                       [HCCTotal_A] = [a].[HCCTotal_A] ,
                       [EstRev_A] = [a].[AnnualizedEstimatedValue_A] ,
                       [EstRevPerHCC_A] = CASE WHEN [a].[HCCTotal_A] = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_A]
                                                   / ( [a].[HCCTotal_A] * 1.0 )
                                          END ,
                       [HCCRealizationRate_A] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                         0
                                                     ELSE
                       ( [a].[HCCTotal_A] / ( [a].[ChartsCompleted] * 1.0 )
                         * 100
                       )
                                                END ,
                       [HCCTotal_B] = [a].[HCCTotal_B] ,
                       [EstRev_B] = [a].[AnnualizedEstimatedValue_B] ,
                       [EstRevPerHCC_B] = CASE WHEN [a].[HCCTotal_B] = 0 THEN
                                                   0
                                               ELSE
                                                   [a].[AnnualizedEstimatedValue_B]
                                                   / ( [a].[HCCTotal_B] * 1.0 )
                                          END ,
                       [HCCRealizationRate_B] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                         0
                                                     ELSE
                       ( [a].[HCCTotal_B]
                         / (( [a].[ChartsCompleted] ) * 1.0 ) * 100
                       )
                                                END ,
                       [HCCTotal_ESRD] = [a].[HCCTotal_ESRD] ,
                       [EstRev_ESRD] = [a].[AnnualizedEstimatedValue_ESRD] ,
                       [EstRevPerHCC_ESRD] = CASE WHEN [a].[HCCTotal_ESRD] = 0 THEN
                                                      0
                                                  ELSE
                                                      [a].[AnnualizedEstimatedValue_ESRD]
                                                      / ( [a].[HCCTotal_ESRD]
                                                          * 1.0
                                                        )
                                             END ,
                       [HCCRealizationRate_ESRD] = CASE WHEN [a].[ChartsCompleted] = 0 THEN
                                                            0
                                                        ELSE
                       ( [a].[HCCTotal_ESRD]
                         / (( [a].[ChartsCompleted] ) * 1.0 ) * 100
                       )
                                                   END ,
                       [ProjectId] = [a].[ProjectId] ,
                       [ProjectDescription] = [a].[ProjectDescription] ,
                       [SubProjectId] = [a].[SubProjectId] ,
                       [SubProjectDescription] = [a].[SubProjectDescription] ,
                       [ReviewName] = [a].[ReviewName] ,
                       [ProjectSortOrder] = [a].[ProjectSortOrder] ,
                       [SubProjectSortOrder] = [a].[SubProjectSortOrder] ,
                       [OrderFlag] = [a].[OrderFlag] ,
                       [PopulatedDate] = @PopulatedDate
                FROM   (
                           
                           
                           SELECT DISTINCT [AutoProcessRunId] = @AutoProcessRunId ,
                                  [RowDisplay] = ISNULL(
                                                           'Filtered Audit - '
                                                           + [fac].[ReviewName] ,
                                                           '-'
                                                       ) ,
                                  [ChartsCompleted] = [fac].[ChartsCompleted] ,
                                  [ModelYear_A] = ISNULL( CAST([a1].[Model_Year] AS VARCHAR(11)) , '-' ) ,
                                  [HCCTotal_A] = ISNULL([a1].[HCCTotal], 0) ,
                                  [AnnualizedEstimatedValue_A] = ISNULL([a1].[AnnualizedEstimatedValue] , 0 ) ,
                                  [ModelYear_B] = ISNULL( CAST([b1].[Model_Year] AS VARCHAR(11)) , '-' ) ,
                                  [HCCTotal_B] = ISNULL([b1].[HCCTotal], 0) ,
                                  [AnnualizedEstimatedValue_B] = ISNULL( [b1].[AnnualizedEstimatedValue] ,  0 ) ,
                                  [HCCTotal_ESRD] = ISNULL([c1].[HCCTotal], 0) ,
                                  [AnnualizedEstimatedValue_ESRD] = ISNULL( [c1].[AnnualizedEstimatedValue] , 0 ) ,
                                  [HCC] = (( ISNULL([a1].[HCCTotal], 0)+ ISNULL([b1].[HCCTotal], 0) ) / 2 )
                                          + ISNULL([c1].[HCCTotal], 0) ,
                                  [Tot$$$] = ISNULL( [a1].[AnnualizedEstimatedValue] , 0 ) 
                                             + ISNULL( [b1].[AnnualizedEstimatedValue] , 0 ) 
                                             + ISNULL( [c1].[AnnualizedEstimatedValue] , 0 ) ,
                                  [ProjectId] = [a0].[ProjectId] ,
                                  [ProjectDescription] = [a0].[ProjectDescription] ,
                                  [SubProjectId] = [a0].[SubProjectId] ,
                                  [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                  [ReviewName] = [a0].[ReviewName] ,
                                  [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                  [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                  [OrderFlag] = 3
                           FROM   #ProjectSubprojectReviewList [a0]
                                  LEFT JOIN [Valuation].[CalcFilteredAuditsTotalForCI] [a1] ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                               AND [a0].[ReviewName] = [a1].[ReviewName]
                                                                                               AND [a1].[Model_Year] = @ModelYearA
                                                                                               AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                               AND [a1].[ClientId] = @ClientId
                                  LEFT JOIN [Valuation].[CalcFilteredAuditsTotalForCI] [b1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [b1].[SubProjectId]
                                                                                                               AND [a0].[ReviewName] = [b1].[ReviewName]
                                                                                                               AND [b1].[Model_Year] = @ModelYearB
                                                                                                               AND [b1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                               AND [b1].[ClientId] = @ClientId
                                  LEFT JOIN [Valuation].[CalcFilteredAuditsTotalForESRD] [c1] ON [a0].[SubProjectId] = [c1].[SubProjectId]
                                                                                                 AND [a0].[ReviewName] = [c1].[ReviewName]
                                                                                                 AND [c1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [c1].[ClientId] = @ClientId
                                  LEFT JOIN [Valuation].[FilteredAuditCNCompletedChart] [facc] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [facc].[SubProjectId]
                                                                                                                  AND [a0].[ReviewName] = [facc].[ReviewName]
                                                                                                                  AND [facc].[AutoProcessRunId] = @AutoProcessRunIdFA
                                                                                                                  AND [facc].[ClientId] = @ClientId
                                  LEFT JOIN [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK ) ON [a1].[SubProjectId] = [ctrs].[SubProjectId]
                                                                                                  AND [ctrs].[LoadDate] = @CTRLoadDate
                                                                                                  AND [ctrs].[ClientId] = @ClientId /*B 2015-08-12 */
                                                                                                  AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId /*E 2015-08-12 */

                                  LEFT JOIN [CTE_fac] [fac] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [fac].[SubProjectId]
                                                                               AND [a0].[ReviewName] = [fac].[ReviewName]
                           WHERE  [fac].[ChartsCompleted] IS NOT NULL
                       ) [a];

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '053 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail]| '
        --            RAISERROR(@Msg, 16, 1)
        --          SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('054', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [EstRevPerChart_A],
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [EstRevPerChart_B],
                                                   [HCCRealizationRate_B] ,
                                                   [HCCTotal_ESRD] ,
                                                   [EstRev_ESRD] ,
                                                   [EstRevPerHCC_ESRD] ,
                                                   [HCCRealizationRate_ESRD] ,
                                                   [HCCTotal_Non_ESRD] ,
                                                   [EstRev_Non_ESRD] ,
                                                   [EstRevPerHCC_Non_ESRD] ,
                                                   [HCCRealizationRate_Non_ESRD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate],
                                                   [Part_C_D]
                                               )
                SELECT   [ClientId] = [m].[ClientId] ,
                         [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                         [ReportHeader] = [m].[ReportHeader] ,
                         [ReportType] = [m].[ReportType] ,
                         [ReportSubType] = [m].[ReportSubType] ,
                         [Header_A] = [m].[Header_A] ,
                         [Header_B] = [m].[Header_B] ,
                         [Header_ESRD] = [m].[Header_ESRD] ,
                         [RowDisplay] = CAST([m].[ProjectId] AS VARCHAR(11))
                                        + ' - ' + [m].[ProjectDescription] ,
                         [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                         [HCCTotal_A] = SUM([m].[HCCTotal_A]) , /*EDS totals */
                         [EstRev_A] = SUM([m].[EstRev_A])   ,
                         [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A])  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].EstRev_A) )
                                                     / ( SUM([m].[HCCTotal_A]) 
                                                         * 1.0
                                                       )
                                            END ,
                          [EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted)  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].EstRev_A) )
                                                     / ( SUM([m].ChartsCompleted) 
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_A] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                        (( SUM([m].[HCCTotal_A]))
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) )* 100
                         
                                                  END ,
                         [HCCTotal_B] = SUM([m].[HCCTotal_B])  , /*RAPS totals */
                         [EstRev_B] = SUM([m].[EstRev_B]) ,
                         [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B])  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].[EstRev_B]))
                                                     / ( SUM([m].[HCCTotal_B])
                                                         * 1.0
                                                       )
                                            END ,
                         [EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted)  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].EstRev_B) )
                                                     / ( SUM([m].ChartsCompleted) 
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_B] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                                         ( (SUM([m].[HCCTotal_B]))
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                  END ,
                         [HCCTotal_ESRD] = SUM([m].[HCCTotal_ESRD]) ,
                         [EstRev_ESRD] = SUM([m].[EstRev_ESRD]) ,
                         [EstRevPerHCC_ESRD] = CASE WHEN SUM([m].[HCCTotal_ESRD]) = 0 THEN
                                                        0
                                                    ELSE
                                                        SUM([m].[EstRev_ESRD])
                                                        / ( SUM([m].[HCCTotal_ESRD])
                                                            * 1.0
                                                          )
                                               END ,
                         [HCCRealizationRate_ESRD] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                              0
                                                          ELSE
                         ( SUM([m].[HCCTotal_ESRD])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                     END ,
                                                     
                         [HCCTotal_Non_ESRD] = SUM([m].[HCCTotal_Non_ESRD]) ,
                         [EstRev_Non_ESRD] = SUM([m].[EstRev_Non_ESRD]) ,
                         [EstRevPerHCC_Non_ESRD] = CASE WHEN SUM([m].[HCCTotal_Non_ESRD]) = 0 THEN
                                                        0
                                                    ELSE
                                                        SUM([m].[EstRev_Non_ESRD])
                                                        / ( SUM([m].[HCCTotal_Non_ESRD])
                                                            * 1.0
                                                          )
                                               END ,
                         [HCCRealizationRate_Non_ESRD] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                              0
                                                          ELSE
                         ( SUM([m].[HCCTotal_Non_ESRD])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                     END ,                                                     
                         [ProjectId] = [m].[ProjectId] ,
                         [ProjectDescription] = [m].[ProjectDescription] ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ReviewName] = NULL ,
                         [ProjectSortOrder] = [m].[ProjectSortOrder] ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 1 ,
                         [PopulatedDate] = [m].[PopulatedDate],
                         'C'
                FROM     [Valuation].[RptPaymentDetail] [m]
                WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                         AND [m].[ClientId] = @ClientId
                         AND [m].[ReportType] = 'Blended'
                         AND [m].[ReportSubType] = 'PaymentDetail'
                         AND [m].[OrderFlag] = 2
                         AND [m].Part_C_D = 'C'
                GROUP BY [m].[ClientId] ,
                         [m].[AutoProcessRunId] ,
                         [m].[ReportHeader] ,
                         [m].[ReportType] ,
                         [m].[ReportSubType] ,
                         [m].[Header_A] ,
                         [m].[Header_B] ,
                         [m].[Header_ESRD] ,
                         [m].[ProjectId] ,
                         [m].[ProjectDescription] ,
                         [m].[ProjectSortOrder] ,
                         [m].[PopulatedDate]

---Part D Totals Rpt Payment Detail --

INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [EstRevPerChart_A],
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [EstRevPerChart_B],
                                                   [HCCRealizationRate_B] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate],
                                                   [Part_C_D]
                                               )
                SELECT   [ClientId] = [m].[ClientId] ,
                         [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                         [ReportHeader] = [m].[ReportHeader] ,
                         [ReportType] = [m].[ReportType] ,
                         [ReportSubType] = [m].[ReportSubType] ,
                         [Header_A] = [m].[Header_A] ,
                         [Header_B] = [m].[Header_B] ,
                         [Header_ESRD] = [m].[Header_ESRD] ,
                         [RowDisplay] = CAST([m].[ProjectId] AS VARCHAR(11))
                                        + ' - ' + [m].[ProjectDescription] ,
                         [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                         [HCCTotal_A] = SUM([m].[HCCTotal_A]) , /*EDS totals */
                         [EstRev_A] = SUM([m].[EstRev_A])   ,
                         [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A])  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].EstRev_A) )
                                                     / ( SUM([m].[HCCTotal_A]) 
                                                         * 1.0
                                                       )
                                            END ,
                          [EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted)  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].EstRev_A) )
                                                     / ( SUM([m].ChartsCompleted) 
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_A] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                        (( SUM([m].[HCCTotal_A]))
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) )* 100
                         
                                                  END ,
                         [HCCTotal_B] = SUM([m].[HCCTotal_B])  , /*RAPS totals */
                         [EstRev_B] = SUM([m].[EstRev_B]) ,
                         [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B])  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].[EstRev_B]))
                                                     / ( SUM([m].[HCCTotal_B])
                                                         * 1.0
                                                       )
                                            END ,
                         [EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted)  = 0 THEN
                                                     0
                                                 ELSE
                                                     (SUM([m].EstRev_B) )
                                                     / ( SUM([m].ChartsCompleted) 
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_B] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                                         ( (SUM([m].[HCCTotal_B]))
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                  END ,
                         [ProjectId] = [m].[ProjectId] ,
                         [ProjectDescription] = [m].[ProjectDescription] ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ReviewName] = NULL ,
                         [ProjectSortOrder] = [m].[ProjectSortOrder] ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 1 ,
                         [PopulatedDate] = [m].[PopulatedDate],
                         'D'
                FROM     [Valuation].[RptPaymentDetail] [m]
                WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                         AND [m].[ClientId] = @ClientId
                         AND [m].[ReportType] = 'Blended'
                         AND [m].[ReportSubType] = 'PaymentDetail'
                         AND [m].[OrderFlag] = 2
                         AND [m].Part_C_D = 'D'
                GROUP BY [m].[ClientId] ,
                         [m].[AutoProcessRunId] ,
                         [m].[ReportHeader] ,
                         [m].[ReportType] ,
                         [m].[ReportSubType] ,
                         [m].[Header_A] ,
                         [m].[Header_B] ,
                         [m].[Header_ESRD] ,
                         [m].[ProjectId] ,
                         [m].[ProjectDescription] ,
                         [m].[ProjectSortOrder] ,
                         [m].[PopulatedDate]
                         
                         
            -----Part D End Totals -----------------             
                         

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '054 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('055', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [EstRevPerChart_A],
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [EstRevPerChart_B],
                                                   [HCCRealizationRate_B] ,
                                                   [HCCTotal_ESRD] ,
                                                   [EstRev_ESRD] ,
                                                   [EstRevPerHCC_ESRD] ,
                                                   [HCCRealizationRate_ESRD] ,
                                                   [HCCTotal_Non_ESRD] ,
                                                   [EstRev_Non_ESRD] ,
                                                   [EstRevPerHCC_Non_ESRD] ,
                                                   [HCCRealizationRate_Non_ESRD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate],
                                                   [Part_C_D]
                                               )
                SELECT   [ClientId] = [m].[ClientId] ,
                         [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                         [ReportHeader] = [m].[ReportHeader] ,
                         [ReportType] = [m].[ReportType] ,
                         [ReportSubType] = [m].[ReportSubType] ,
                         [Header_A] = [m].[Header_A] ,
                         [Header_B] = [m].[Header_B] ,
                         [Header_ESRD] = [m].[Header_ESRD] ,
                         [RowDisplay] = 'Total' ,
                         [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                         [HCCTotal_A] = SUM([m].[HCCTotal_A]) ,
                         [EstRev_A] = SUM([m].[EstRev_A]) ,
                         [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A]) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_A])
                                                     / ( SUM([m].[HCCTotal_A])
                                                         * 1.0
                                                       )
                                            END ,
                         [EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_A])
                                                     / ( SUM([m].ChartsCompleted)
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_A] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                         ( SUM([m].[HCCTotal_A])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                  END ,
                         [HCCTotal_B] = SUM([m].[HCCTotal_B]) ,
                         [EstRev_B] = SUM([m].[EstRev_B]) ,
                         [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B]) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_B])
                                                     / ( SUM([m].[HCCTotal_B])
                                                         * 1.0
                                                       )
                                            END ,
                         [EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_B])
                                                     / ( SUM([m].ChartsCompleted)
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_B] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                         ( SUM([m].[HCCTotal_B])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                  END ,
                         [HCCTotal_ESRD] = SUM([m].[HCCTotal_ESRD]) ,
                         [EstRev_ESRD] = SUM([m].[EstRev_ESRD]) ,
                         [EstRevPerHCC_ESRD] = CASE WHEN SUM([m].[HCCTotal_ESRD]) = 0 THEN
                                                        0
                                                    ELSE
                                                        SUM([m].[EstRev_ESRD])
                                                        / ( SUM([m].[HCCTotal_ESRD])
                                                            * 1.0
                                                          )
                                               END ,
                         [HCCRealizationRate_ESRD] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                              0
                                                          ELSE
                         ( SUM([m].[HCCTotal_ESRD])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                     END ,
                         [HCCTotal_Non_ESRD] = SUM([m].[HCCTotal_Non_ESRD]) ,
                         [EstRev_Non_ESRD] = SUM([m].[EstRev_Non_ESRD]) ,
                         [EstRevPerHCC_Non_ESRD] = CASE WHEN SUM([m].[HCCTotal_Non_ESRD]) = 0 THEN
                                                        0
                                                    ELSE
                                                        SUM([m].[EstRev_Non_ESRD])
                                                        / ( SUM([m].[HCCTotal_Non_ESRD])
                                                            * 1.0
                                                          )
                                               END ,
                         [HCCRealizationRate_Non_ESRD] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                              0
                                                          ELSE
                         ( SUM([m].[HCCTotal_Non_ESRD])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                     END ,
                         [ProjectId] = NULL ,
                         [ProjectDescription] = NULL ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ReviewName] = NULL ,
                         [ProjectSortOrder] = NULL ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 0 ,
                         [PopulatedDate] = [m].[PopulatedDate],
                         'C'
                FROM     [Valuation].[RptPaymentDetail] [m]
                WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                         AND [m].[ClientId] = @ClientId
                         AND [m].[ReportType] = 'Blended'
                         AND [m].[ReportSubType] = 'PaymentDetail'
                         AND [m].[OrderFlag] = 1
                         AND [m].Part_C_D = 'C'
                GROUP BY [m].[ClientId] ,
                         [m].[AutoProcessRunId] ,
                         [m].[ReportHeader] ,
                         [m].[ReportType] ,
                         [m].[ReportSubType] ,
                         [m].[Header_A] ,
                         [m].[Header_B] ,
                         [m].[Header_ESRD] ,
                         [m].[PopulatedDate]



------Part D Totals 2 Start ---

 INSERT INTO [Valuation].[RptPaymentDetail] (   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [Header_A] ,
                                                   [Header_B] ,
                                                   [Header_ESRD] ,
                                                   [RowDisplay] ,
                                                   [ChartsCompleted] ,
                                                   [HCCTotal_A] ,
                                                   [EstRev_A] ,
                                                   [EstRevPerHCC_A] ,
                                                   [EstRevPerChart_A],
                                                   [HCCRealizationRate_A] ,
                                                   [HCCTotal_B] ,
                                                   [EstRev_B] ,
                                                   [EstRevPerHCC_B] ,
                                                   [EstRevPerChart_B],
                                                   [HCCRealizationRate_B] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ReviewName] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate],
                                                   [Part_C_D]
                                               )
                SELECT   [ClientId] = [m].[ClientId] ,
                         [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                         [ReportHeader] = [m].[ReportHeader] ,
                         [ReportType] = [m].[ReportType] ,
                         [ReportSubType] = [m].[ReportSubType] ,
                         [Header_A] = [m].[Header_A] ,
                         [Header_B] = [m].[Header_B] ,
                         [Header_ESRD] = [m].[Header_ESRD] ,
                         [RowDisplay] = 'Total' ,
                         [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                         [HCCTotal_A] = SUM([m].[HCCTotal_A]) ,
                         [EstRev_A] = SUM([m].[EstRev_A]) ,
                         [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A]) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_A])
                                                     / ( SUM([m].[HCCTotal_A])
                                                         * 1.0
                                                       )
                                            END ,
                         [EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_A])
                                                     / ( SUM([m].ChartsCompleted)
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_A] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                         ( SUM([m].[HCCTotal_A])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                  END ,
                         [HCCTotal_B] = SUM([m].[HCCTotal_B]) ,
                         [EstRev_B] = SUM([m].[EstRev_B]) ,
                         [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B]) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_B])
                                                     / ( SUM([m].[HCCTotal_B])
                                                         * 1.0
                                                       )
                                            END ,
                         [EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                     0
                                                 ELSE
                                                     SUM([m].[EstRev_B])
                                                     / ( SUM([m].ChartsCompleted)
                                                         * 1.0
                                                       )
                                            END ,
                         [HCCRealizationRate_B] = CASE WHEN SUM([m].[ChartsCompleted]) = 0 THEN
                                                           0
                                                       ELSE
                         ( SUM([m].[HCCTotal_B])
                           / ( SUM([m].[ChartsCompleted]) * 1.0 ) * 100
                         )
                                                  END ,                        
                         [ProjectId] = NULL ,
                         [ProjectDescription] = NULL ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ReviewName] = NULL ,
                         [ProjectSortOrder] = NULL ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 0 ,
                         [PopulatedDate] = [m].[PopulatedDate],
                         'D'
                FROM     [Valuation].[RptPaymentDetail] [m]
                WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                         AND [m].[ClientId] = @ClientId
                         AND [m].[ReportType] = 'Blended'
                         AND [m].[ReportSubType] = 'PaymentDetail'
                         AND [m].[OrderFlag] = 1
                         AND [m].Part_C_D = 'D'
                GROUP BY [m].[ClientId] ,
                         [m].[AutoProcessRunId] ,
                         [m].[ReportHeader] ,
                         [m].[ReportType] ,
                         [m].[ReportSubType] ,
                         [m].[Header_A] ,
                         [m].[Header_B] ,
                         [m].[Header_ESRD] ,
                         [m].[PopulatedDate]

------Part D Totals End
    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '055 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*  E Report: Blended Payment Detail */
    /*E Blended Payment Detail */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('056', 0, 1) WITH NOWAIT
        END


    DECLARE @FailureReasonList TABLE
        (
            [FailureReason] VARCHAR(128) NOT NULL
        )

    INSERT INTO @FailureReasonList ( [FailureReason] )
                SELECT DISTINCT [FailureReason] = [FailureReason]
                FROM   #ProjectSubprojectReviewList
                WHERE  [FailureReason] IS NOT NULL


    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '057 - Notice: Zero rows loaded to @FailureReasonList| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('058', 0, 1) WITH NOWAIT
        END

    DECLARE @FailureReason VARCHAR(128)

    WHILE EXISTS (   SELECT 1
                     FROM   @FailureReasonList
                     WHERE  [FailureReason] <> 'N/a'
                 )
        BEGIN

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('059', 0, 1) WITH NOWAIT
                END

            SELECT   TOP 1 @FailureReason = [FailureReason]
            FROM     @FailureReasonList
            WHERE    [FailureReason] <> 'N/a'
            ORDER BY [FailureReason]

            /*B Totals Detail*/

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    PRINT REPLICATE('-', LEN(@FailureReason) + 16)
                    PRINT '------- ' + @FailureReason + ' -------'
                    PRINT REPLICATE('-', LEN(@FailureReason) + 16)
                    RAISERROR('WL060', 0, 1) WITH NOWAIT
                END

            DELETE [m]
            FROM  [Valuation].[RptPaymentDetail] [m]
            WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
                  AND [m].[ReportType] = 'TotalsDetail'
                  AND [m].[ReportSubType] = @FailureReason
                  AND [m].[ClientId] = @ClientId

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL061', 0, 1) WITH NOWAIT
                END

                --
                /**/;
                
       ----Total Detail ---         
         
            INSERT INTO [Valuation].[RptPaymentDetail] (   [AutoProcessRunId] ,
                                                           [ClientId] ,
                                                           [ReportHeader] ,
                                                           [ReportType] ,
                                                           [ReportSubType] ,
                                                           [Header_A] ,
                                                           [Header_B] ,
                                                           [Header_ESRD] ,
                                                           [RowDisplay] ,
                                                           [ChartsCompleted] ,
                                                           [HCCTotal_A] ,
                                                           [EstRev_A] ,
                                                           [EstRevPerHCC_A] ,
                                                           [HCCRealizationRate_A] ,
                                                           [HCCTotal_B] ,
                                                           [EstRev_B] ,
                                                           [EstRevPerHCC_B] ,
                                                           [HCCRealizationRate_B] ,
                                                           [HCCTotal_ESRD] ,
                                                           [EstRev_ESRD] ,
                                                           [EstRevPerHCC_ESRD] ,
                                                           [HCCRealizationRate_ESRD] ,
                                                           [ProjectId] ,
                                                           [ProjectDescription] ,
                                                           [SubProjectId] ,
                                                           [SubProjectDescription] ,
                                                           [ReviewName] ,
                                                           [ProjectSortOrder] ,
                                                           [SubProjectSortOrder] ,
                                                           [OrderFlag] ,
                                                           [PopulatedDate]
                                                       )
                        SELECT DISTINCT [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                               [ClientId] = @ClientId ,
                               [ReportHeader] = @FailureReason
                                                + ' Totals - Detail' ,   --@ClientName + ' - ' + @FailureReason + ' Totals - Detail'
                               [ReportType] = 'TotalsDetail' ,
                               [ReportSubType] = @FailureReason ,
                               [Header_A] = @TotalsDetailHeaderA ,       --'2013 DOS/2014 Payment Year - 2013 Model (25%)' /*Note -Needs to be table driven */
                               [Header_B] = @TotalsDetailHeaderB ,       --'2013 DOS/2014 Payment Year - 2014 Model (75%)' /*Note -Needs to be table driven */
                               [Header_ESRD] = @TotalsDetailHeaderESRD , --'2013 DOS/2014 Payment Year - 2014 Model (100% - ESRD)' /*Note -Needs to be table driven */
                               [RowDisplay] = [a].[RowDisplay] ,
                               [ChartsCompleted] = [a].[ChartsCompleted] ,
                               [HCCCount_A] = [a].[HCCPartC_A] ,
                               [EstRev_A] = [a].[EstRecPartC_A] ,
                               [EstRevPerHCC_A] = [a].[EstRecPerHCCPartC_A] ,
                               [HCCRealizationRate_A] = NULL ,
                               [HCCCount_B] = [a].[HCCPartC_B] ,
                               [EstRev_B] = [a].[EstRecPartC_B] ,
                               [EstRevPerHCC_B] = [a].[EstRecPerHCCPartC_B] ,
                               [HCCRealizationRate_B] = NULL ,
                               [HCCCount_ESRD] = [a].[HCCPartC_ESRD] ,
                               [EstRev_ESRD] = [a].[EstRecPartC_ESRD] ,
                               [EstRevPerHCC_ESRD] = [a].[EstRecPerHCCPartC_ESRD] ,
                               [HCCRealizationRate_ESRD] = NULL ,
                               [a].[ProjectId] ,
                               [a].[ProjectDescription] ,
                               [a].[SubProjectId] ,
                               [a].[SubProjectDescription] ,
                               [ReviewName] = NULL ,
                               [a].[ProjectSortOrder] ,
                               [a].[SubProjectSortOrder] ,
                               [a].[OrderFlag] ,
                               [PopulatedDate] = @PopulatedDate
                        FROM   (   SELECT DISTINCT [AutoProcessRunId] = @AutoProcessRunId ,
                                          [ReportType] = [a0].[FailureReason] ,
                                          [RowDisplay] = CAST([a0].[SubProjectId] AS VARCHAR(11))
                                                         + ' - '
                                                         + [a0].[SubProjectDescription] ,
                                          [ChartsCompleted] = [fac].[ChartsComplete] , --[fac].[ChartsCompleted]
                                          [HCCPartC_A] = [a1].[HCCTotal] ,
                                          [EstRecPartC_A] = [a1].[AnnualizedEstimatedValue] ,
                                          [EstRecPerHCCPartC_A] = CASE WHEN [a1].[HCCTotal] = 0
                                                                            OR [a1].[HCCTotal] IS NULL THEN
                                                                           0
                                                                       ELSE
                                          ( [a1].[AnnualizedEstimatedValue]
                                            / ( [a1].[HCCTotal] * 1.0 )
                                          )
                                                                  END ,
                                          [HCCPartC_B] = [b1].[HCCTotal] ,
                                          [EstRecPartC_B] = [b1].[AnnualizedEstimatedValue] ,
                                          [EstRecPerHCCPartC_B] = CASE WHEN [b1].[HCCTotal] = 0
                                                                            OR [b1].[HCCTotal] IS NULL THEN
                                                                           0
                                                                       ELSE
                                          ( [b1].[AnnualizedEstimatedValue]
                                            / ( [b1].[HCCTotal] * 1.0 )
                                          )
                                                                  END ,
                                          [HCCPartC_ESRD] = [c1].[HCCTotal] ,
                                          [EstRecPartC_ESRD] = [c1].[AnnualizedEstimatedValue] ,
                                          [EstRecPerHCCPartC_ESRD] = CASE WHEN [c1].[HCCTotal] = 0
                                                                               OR [c1].[HCCTotal] IS NULL THEN
                                                                              0
                                                                          ELSE
                                          ( [c1].[AnnualizedEstimatedValue]
                                            / ( [c1].[HCCTotal] * 1.0 )
                                          )
                                                                     END ,
                                          [ProjectId] = [a0].[ProjectId] ,
                                          [ProjectDescription] = [a0].[ProjectDescription] ,
                                          [SubProjectId] = [a0].[SubProjectId] ,
                                          [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                          [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                          [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                          [OrderFlag] = 2
                                   FROM   #ProjectSubprojectReviewList [a0]
                  LEFT JOIN [Valuation].[CalcPartCSubProjectModelYearCI] [a1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                                 AND [a1].[Model_Year] = @ModelYearA
                                                                                                 AND [a1].[PMH_Attestation] = @FailureReason
                                                                                                 AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [a1].[ClientId] = @ClientId
                  LEFT JOIN [Valuation].[CalcPartCSubProjectModelYearCI] [b1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [b1].[SubProjectId]
                                                                                                 AND [b1].[Model_Year] = @ModelYearB
                                                                                                 AND [b1].[PMH_Attestation] = @FailureReason
                                                                                                 AND [b1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                 AND [b1].[ClientId] = @ClientId
                  LEFT JOIN [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD] [c1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [c1].[SubProjectId]
                                                                                                              AND [c1].[PMH_Attestation] = @FailureReason
                                                                                                              AND [c1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                              AND [c1].[ClientId] = @ClientId
                  LEFT JOIN [Valuation].[ValCTRSummary] [fac] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [fac].[SubProjectId]
                                                                                 AND [fac].[LoadDate] = @CTRLoadDate /*B 2015-08-12 */
                                                                                                         AND [fac].[AutoProcessRunId] = @AutoProcessRunId /*E 2015-08-12 */
                                   WHERE  [a0].[SubProjectId] IS NOT NULL /**/) a;
                                   
                                   
                                   
       
                
       ----Filtered Audit Total Detail ---         
                                     
                                   
    WITH [CTE_fac]
            AS ( SELECT   [AutoProcessRunId] = [facc].[AutoProcessRunId] ,
                          [SubProjectId] = [facc].[SubProjectId] ,
                          [ChartsCompleted] = COUNT(DISTINCT
                                                       [facc].[VeriskRequestId]
                                                   )
                 FROM     [Valuation].[FilteredAuditCNCompletedChart] [facc] WITH ( NOLOCK )
                 WHERE    [facc].[AutoProcessRunId] = @AutoProcessRunIdFA
                          AND [facc].[ClientId] = @ClientId
                 GROUP BY [facc].[AutoProcessRunId] ,
                          [facc].[SubProjectId]
               ) ,
                 [CTE_fac02]
            AS ( SELECT   [AutoProcessRunId] = [facc].[AutoProcessRunId] ,
                          [SubProjectId] = [facc].[SubProjectId] ,
                          [ReviewName] = LTRIM(RTRIM([facc].[ReviewName])) ,
                          [ChartsCompleted] = COUNT(DISTINCT
                                                       [facc].[VeriskRequestId]
                                                   )
                 FROM     [Valuation].[FilteredAuditCNCompletedChart] [facc] WITH ( NOLOCK )
                 WHERE    [facc].[AutoProcessRunId] = @AutoProcessRunIdFA
                          AND [facc].[ClientId] = @ClientId
                 GROUP BY [facc].[AutoProcessRunId] ,
                          [facc].[SubProjectId] ,
                          [facc].[ReviewName]
               )
            INSERT INTO [Valuation].[RptPaymentDetail] (   [AutoProcessRunId] ,
                                                           [ClientId] ,
                                                           [ReportHeader] ,
                                                           [ReportType] ,
                                                           [ReportSubType] ,
                                                           [Header_A] ,
                                                           [Header_B] ,
                                                           [Header_ESRD] ,
                                                           [RowDisplay] ,
                                                           [ChartsCompleted] ,
                                                           [HCCTotal_A] ,
                                                           [EstRev_A] ,
                                                           [EstRevPerHCC_A] ,
                                                           [HCCRealizationRate_A] ,
                                                           [HCCTotal_B] ,
                                                           [EstRev_B] ,
                                                           [EstRevPerHCC_B] ,
                                                           [HCCRealizationRate_B] ,
                                                           [HCCTotal_ESRD] ,
                                                           [EstRev_ESRD] ,
                                                           [EstRevPerHCC_ESRD] ,
                                                           [HCCRealizationRate_ESRD] ,
                                                           [ProjectId] ,
                                                           [ProjectDescription] ,
                                                           [SubProjectId] ,
                                                           [SubProjectDescription] ,
                                                           [ReviewName] ,
                                                           [ProjectSortOrder] ,
                                                           [SubProjectSortOrder] ,
                                                           [OrderFlag] ,
                                                           [PopulatedDate]
                                                       )
                           SELECT DISTINCT [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                               [ClientId] = @ClientId ,
                               [ReportHeader] = @FailureReason
                                                + ' Totals - Detail' ,   --@ClientName + ' - ' + @FailureReason + ' Totals - Detail'
                               [ReportType] = 'TotalsDetail' ,
                               [ReportSubType] = @FailureReason ,
                               [Header_A] = @TotalsDetailHeaderA ,       --'2013 DOS/2014 Payment Year - 2013 Model (25%)' /*Note -Needs to be table driven */
                               [Header_B] = @TotalsDetailHeaderB ,       --'2013 DOS/2014 Payment Year - 2014 Model (75%)' /*Note -Needs to be table driven */
                               [Header_ESRD] = @TotalsDetailHeaderESRD , --'2013 DOS/2014 Payment Year - 2014 Model (100% - ESRD)' /*Note -Needs to be table driven */
                               [RowDisplay] = [a].[RowDisplay] ,
                               [ChartsCompleted] = [a].[ChartsCompleted] ,
                               [HCCCount_A] = [a].[HCCPartC_A] ,
                               [EstRev_A] = [a].[EstRecPartC_A] ,
                               [EstRevPerHCC_A] = [a].[EstRecPerHCCPartC_A] ,
                               [HCCRealizationRate_A] = NULL ,
                               [HCCCount_B] = [a].[HCCPartC_B] ,
                               [EstRev_B] = [a].[EstRecPartC_B] ,
                               [EstRevPerHCC_B] = [a].[EstRecPerHCCPartC_B] ,
                               [HCCRealizationRate_B] = NULL ,
                               [HCCCount_ESRD] = [a].[HCCPartC_ESRD] ,
                               [EstRev_ESRD] = [a].[EstRecPartC_ESRD] ,
                               [EstRevPerHCC_ESRD] = [a].[EstRecPerHCCPartC_ESRD] ,
                               [HCCRealizationRate_ESRD] = NULL ,
                               [a].[ProjectId] ,
                               [a].[ProjectDescription] ,
                               [a].[SubProjectId] ,
                               [a].[SubProjectDescription] ,
                               [ReviewName] = NULL ,
                               [a].[ProjectSortOrder] ,
                               [a].[SubProjectSortOrder] ,
                               [a].[OrderFlag] ,
                               [PopulatedDate] = @PopulatedDate
                        FROM   (  SELECT DISTINCT [AutoProcessRunId] = @AutoProcessRunId ,
                                          [ReportType] = [a0].[FailureReason] ,
                                          [RowDisplay] = 'Filtered Audit - '
                                                         + ISNULL(
                                                                     [a0].[ReviewName] ,
                                                                     ''
                                                                 ) ,
                                          [ChartsCompleted] = [fac].[ChartsCompleted] ,
                                          [HCCPartC_A] = [a1].[HCCTotal] ,
                                          [EstRecPartC_A] = [a1].[AnnualizedEstimatedValue] ,
                                          [EstRecPerHCCPartC_A] = CASE WHEN [a1].[HCCTotal] = 0
                                                                            OR [a1].[HCCTotal] IS NULL THEN
                                                                           0
                                                                       ELSE
                                          ( [a1].[AnnualizedEstimatedValue]
                                            / ( [a1].[HCCTotal] * 1.0 )
                                          )
                                                                  END ,
                                          [HCCPartC_B] = [b1].[HCCTotal] ,
                                          [EstRecPartC_B] = [b1].[AnnualizedEstimatedValue] ,
                                          [EstRecPerHCCPartC_B] = CASE WHEN [b1].[HCCTotal] = 0
                                                                            OR [b1].[HCCTotal] IS NULL THEN
                                                                           0
                                                                       ELSE
                                          ( [b1].[AnnualizedEstimatedValue]
                                            / ( [b1].[HCCTotal] * 1.0 )
                                          )
                                                                  END ,
                                          [HCCPartC_ESRD] = [c1].[HCCTotal] ,
                                          [EstRecPartC_ESRD] = [c1].[AnnualizedEstimatedValue] ,
                                          [EstRecPerHCCPartC_ESRD] = CASE WHEN [c1].[HCCTotal] = 0
                                                                               OR [c1].[HCCTotal] IS NULL THEN
                                                                              0
                                                                          ELSE
                                          ( [c1].[AnnualizedEstimatedValue]
                                            / ( [c1].[HCCTotal] * 1.0 )
                                          )
                                                                     END ,
                                          [ProjectId] = [a0].[ProjectId] ,
                                          [ProjectDescription] = [a0].[ProjectDescription] ,
                                          [SubProjectId] = [a0].[SubProjectId] ,
                                          [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                          [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                          [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                          [OrderFlag] = 3
                                   FROM   #ProjectSubprojectReviewList [a0]
                                          LEFT JOIN [Valuation].[CalcPMHAttestationFilteredAuditHCCTotalsCI] [a1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                                                                     AND [a0].[ReviewName] = [a1].[ReviewName]
                                                                                                                                     AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                                     AND [a1].[ClientId] = @ClientId
                                                                                                                                     AND [a1].[Model_Year] = @ModelYearA
                                                                                                                                     AND [a1].[PMH_Attestation] = @FailureReason
                                          LEFT JOIN [Valuation].[CalcPMHAttestationFilteredAuditHCCTotalsCI] [b1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [b1].[SubProjectId]
                                                                                                                                     AND [a0].[ReviewName] = [b1].[ReviewName]
                                                                                                                                     AND [b1].[Model_Year] = @ModelYearB
                                                                                                                                     AND [b1].[PMH_Attestation] = @FailureReason
                                                                                                                                     AND [b1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                                     AND [b1].[ClientId] = @ClientId
                                          LEFT JOIN [Valuation].[CalcPMHAttestationFilteredAuditTotalsESRD] [c1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [c1].[SubProjectId]
                                                                                                                                    AND [a0].[ReviewName] = [c1].[ReviewName]
                                                                                                                                    AND [c1].[PMH_Attestation] = @FailureReason
                                                                                                                                    AND [c1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                                    AND [c1].[ClientId] = @ClientId
                                          LEFT JOIN [CTE_fac02] [fac] ON [a0].[SubProjectId] = [fac].[SubProjectId]
                                                                         AND [a0].[ReviewName] = [fac].[ReviewName]
                                   WHERE  [a0].[SubProjectId] IS NOT NULL
                               ) [a];
---      ----Filtered Audit Total Detail  ---    
            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = 'WL062 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail] for '
                               + @FailureReason + ' Totals - Detail'
                    RAISERROR(@Msg, 16, 1)
                    SET @Msg = NULL
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL063', 0, 1) WITH NOWAIT
                END

            INSERT INTO [Valuation].[RptPaymentDetail] (   [AutoProcessRunId] ,
                                                           [ClientId] ,
                                                           [ReportHeader] ,
                                                           [ReportType] ,
                                                           [ReportSubType] ,
                                                           [Header_A] ,
                                                           [Header_B] ,
                                                           [Header_ESRD] ,
                                                           [RowDisplay] ,
                                                           [ChartsCompleted] ,
                                                           [HCCTotal_A] ,
                                                           [EstRev_A] ,
                                                           [EstRevPerHCC_A] ,
                                                           [EstRevPerChart_A] ,
                                                           [HCCRealizationRate_A] ,
                                                           [HCCTotal_B] ,
                                                           [EstRev_B] ,
                                                           [EstRevPerHCC_B] ,
                                                           [EstRevPerChart_B],
                                                           [HCCRealizationRate_B] ,
                                                           [HCCTotal_ESRD] ,
                                                           [EstRev_ESRD] ,
                                                           [EstRevPerHCC_ESRD] ,
                                                           [HCCRealizationRate_ESRD] ,
                                                           [ProjectId] ,
                                                           [ProjectDescription] ,
                                                           [SubProjectId] ,
                                                           [SubProjectDescription] ,
                                                           [ReviewName] ,
                                                           [ProjectSortOrder] ,
                                                           [SubProjectSortOrder] ,
                                                           [OrderFlag] ,
                                                           [PopulatedDate],
                                                           [Part_C_D]
                                                       )
                        SELECT   [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                                 [ClientId] = [m].[ClientId] ,
                                 [ReportHeader] = [m].[ReportHeader] ,
                                 [ReportType] = [m].[ReportType] ,
                                 [ReportSubType] = [m].[ReportSubType] ,
                                 [Header_A] = [m].[Header_A] ,
                                 [Header_B] = [m].[Header_B] ,
                                 [Header_ESRD] = [m].[Header_ESRD] ,
                                 [RowDisplay] = CAST([m].[ProjectId] AS VARCHAR(11))
                                                + ' - '
                                                + [m].[ProjectDescription] ,
                                 [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                                 [HCCTotal_A] = SUM([m].[HCCTotal_A]) ,
                                 [EstRev_A] = SUM([m].[EstRev_A]) ,
                                 [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A]) = 0 THEN
                                                             0
                                                         ELSE
                                 ( SUM([m].[EstRev_A]) * 1.0 )
                                 / ( SUM([m].[HCCTotal_A]) * 1.0 )
                                                    END ,
                                 [EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
												 ( SUM([m].[EstRev_A]) * 1.0 )
												 / ( SUM([m].ChartsCompleted) * 1.0 )
																	END ,
                                 [HCCRealizationRate_A] = NULL ,
                                 [HCCTotal_B] = SUM([m].[HCCTotal_B]) ,
                                 [EstRev_B] = SUM([m].[EstRev_B]) ,
                                 [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B]) = 0 THEN
                                                             0
                                                         ELSE
                                 ( SUM([m].[EstRev_B]) * 1.0 )
                                 / ( SUM([m].[HCCTotal_B]) * 1.0 )
                                                    END ,
                                 [EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
												 ( SUM([m].[EstRev_B]) * 1.0 )
												 / ( SUM([m].ChartsCompleted) * 1.0 )
																	END ,
                                 [HCCRealizationRate_B] = NULL ,
                                 [HCCTotal_ESRD] = SUM([m].[HCCTotal_ESRD]) ,
                                 [EstRev_ESRD] = SUM([m].[EstRev_ESRD]) ,
                                 [EstRevPerHCC_ESRD] = CASE WHEN SUM([m].[HCCTotal_ESRD]) = 0 THEN
                                                                0
                                                            ELSE
                                 ( SUM([m].[EstRev_ESRD]) * 1.0 )
                                 / ( SUM([m].[HCCTotal_ESRD]) * 1.0 )
                                                       END ,
                                 [HCCRealizationRate_ESRD] = NULL ,
                                 [ProjectId] = [m].[ProjectId] ,
                                 [ProjectDescription] = [m].[ProjectDescription] ,
                                 [SubProjectId] = NULL ,
                                 [SubProjectDescription] = NULL ,
                                 [ReviewName] = NULL ,
                                 [ProjectSortOrder] = [m].[ProjectSortOrder] ,
                                 [SubProjectSortOrder] = NULL ,
                                 [OrderFlag] = 1 ,
                                 [PopulatedDate] = [m].[PopulatedDate],
                                 'C'
                        FROM     [Valuation].[RptPaymentDetail] [m]
                        WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                                 AND [m].[ReportType] = 'TotalsDetail'
                                 AND [m].[ReportSubType] = @FailureReason
                                 AND [m].[ClientId] = @ClientId
                                 AND [m].[OrderFlag] = 2
                                 AND [m].Part_C_D = 'C'
                        GROUP BY [m].[AutoProcessRunId] ,
                                 [m].[ClientId] ,
                                 [m].[ReportHeader] ,
                                 [m].[ReportType] ,
                                 [m].[ReportSubType] ,
                                 [m].[Header_A] ,
                                 [m].[Header_B] ,
                                 [m].[Header_ESRD] ,
                                 [m].[ProjectId] ,
                                 [m].[ProjectDescription] ,
                                 [m].[ProjectSortOrder] ,
                                 [m].[PopulatedDate]

-----Part D TotalS detail 
      INSERT INTO [Valuation].[RptPaymentDetail] (   [AutoProcessRunId] ,
                                                           [ClientId] ,
                                                           [ReportHeader] ,
                                                           [ReportType] ,
                                                           [ReportSubType] ,
                                                           [Header_A] ,
                                                           [Header_B] ,
                                                           [Header_ESRD] ,
                                                           [RowDisplay] ,
                                                           [ChartsCompleted] ,
                                                           [HCCTotal_A] ,
                                                           [EstRev_A] ,
                                                           [EstRevPerHCC_A] ,
                                                           [EstRevPerChart_A] ,
                                                           [HCCRealizationRate_A] ,
                                                           [HCCTotal_B] ,
                                                           [EstRev_B] ,
                                                           [EstRevPerHCC_B] ,
                                                           [EstRevPerChart_B],
                                                           [HCCRealizationRate_B] ,
                                                           [ProjectId] ,
                                                           [ProjectDescription] ,
                                                           [SubProjectId] ,
                                                           [SubProjectDescription] ,
                                                           [ReviewName] ,
                                                           [ProjectSortOrder] ,
                                                           [SubProjectSortOrder] ,
                                                           [OrderFlag] ,
                                                           [PopulatedDate],
                                                           [Part_C_D]
                                                       )
                        SELECT   [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                                 [ClientId] = [m].[ClientId] ,
                                 [ReportHeader] = [m].[ReportHeader] ,
                                 [ReportType] = [m].[ReportType] ,
                                 [ReportSubType] = [m].[ReportSubType] ,
                                 [Header_A] = [m].[Header_A] ,
                                 [Header_B] = [m].[Header_B] ,
                                 [Header_ESRD] = [m].[Header_ESRD] ,
                                 [RowDisplay] = CAST([m].[ProjectId] AS VARCHAR(11))
                                                + ' - '
                                                + [m].[ProjectDescription] ,
                                 [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                                 [HCCTotal_A] = SUM([m].[HCCTotal_A]) ,
                                 [EstRev_A] = SUM([m].[EstRev_A]) ,
                                 [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A]) = 0 THEN
                                                             0
                                                         ELSE
                                 ( SUM([m].[EstRev_A]) * 1.0 )
                                 / ( SUM([m].[HCCTotal_A]) * 1.0 )
                                                    END ,
                                 [EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
												 ( SUM([m].[EstRev_A]) * 1.0 )
												 / ( SUM([m].ChartsCompleted) * 1.0 )
																	END ,
                                 [HCCRealizationRate_A] = NULL ,
                                 [HCCTotal_B] = SUM([m].[HCCTotal_B]) ,
                                 [EstRev_B] = SUM([m].[EstRev_B]) ,
                                 [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B]) = 0 THEN
                                                             0
                                                         ELSE
                                 ( SUM([m].[EstRev_B]) * 1.0 )
                                 / ( SUM([m].[HCCTotal_B]) * 1.0 )
                                                    END ,
                                 [EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
												 ( SUM([m].[EstRev_B]) * 1.0 )
												 / ( SUM([m].ChartsCompleted) * 1.0 )
																	END ,
                                 [HCCRealizationRate_B] = NULL ,
                                 [ProjectId] = [m].[ProjectId] ,
                                 [ProjectDescription] = [m].[ProjectDescription] ,
                                 [SubProjectId] = NULL ,
                                 [SubProjectDescription] = NULL ,
                                 [ReviewName] = NULL ,
                                 [ProjectSortOrder] = [m].[ProjectSortOrder] ,
                                 [SubProjectSortOrder] = NULL ,
                                 [OrderFlag] = 1 ,
                                 [PopulatedDate] = [m].[PopulatedDate],
                                 'D'
                        FROM     [Valuation].[RptPaymentDetail] [m]
                        WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                                 AND [m].[ReportType] = 'TotalsDetail'
                                 AND [m].[ReportSubType] = @FailureReason
                                 AND [m].[ClientId] = @ClientId
                                 AND [m].[OrderFlag] = 2
                                 AND [m].Part_C_D = 'D'
                        GROUP BY [m].[AutoProcessRunId] ,
                                 [m].[ClientId] ,
                                 [m].[ReportHeader] ,
                                 [m].[ReportType] ,
                                 [m].[ReportSubType] ,
                                 [m].[Header_A] ,
                                 [m].[Header_B] ,
                                 [m].[Header_ESRD] ,
                                 [m].[ProjectId] ,
                                 [m].[ProjectDescription] ,
                                 [m].[ProjectSortOrder] ,
                                 [m].[PopulatedDate]

-----Part D Totals Details



            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = 'WL063 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail] for '
                               + @FailureReason + ' Totals - Detail'
                    RAISERROR(@Msg, 16, 1)
                    SET @Msg = NULL
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL064', 0, 1) WITH NOWAIT
                END

            INSERT INTO [Valuation].[RptPaymentDetail] (   [AutoProcessRunId] ,
                                                           [ClientId] ,
                                                           [ReportHeader] ,
                                                           [ReportType] ,
                                                           [ReportSubType] ,
                                                           [Header_A] ,
                                                           [Header_B] ,
                                                           [Header_ESRD] ,
                                                           [RowDisplay] ,
                                                           [ChartsCompleted] ,
                                                           [HCCTotal_A] ,
                                                           [EstRev_A] ,
                                                           [EstRevPerHCC_A] ,
                                                           [EstRevPerChart_A],
                                                           [HCCRealizationRate_A] ,
                                                           [HCCTotal_B] ,
                                                           [EstRev_B] ,
                                                           [EstRevPerHCC_B] ,
                                                           [EstRevPerChart_B],
                                                           [HCCRealizationRate_B] ,
                                                           [HCCTotal_ESRD] ,
                                                           [EstRev_ESRD] ,
                                                           [EstRevPerHCC_ESRD] ,
                                                           [HCCRealizationRate_ESRD] ,
                                                           [ProjectId] ,
                                                           [ProjectDescription] ,
                                                           [SubProjectId] ,
                                                           [SubProjectDescription] ,
                                                           [ReviewName] ,
                                                           [ProjectSortOrder] ,
                                                           [SubProjectSortOrder] ,
                                                           [OrderFlag] ,
                                                           [PopulatedDate],
                                                           [Part_C_D]
                                                       )
                        SELECT   [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                                 [ClientId] = [m].[ClientId] ,
                                 [ReportHeader] = [m].[ReportHeader] ,
                                 [ReportType] = [m].[ReportType] ,
                                 [ReportSubType] = [m].[ReportSubType] ,
                                 [Header_A] = [m].[Header_A] ,
                                 [Header_B] = [m].[Header_B] ,
                                 [Header_ESRD] = [m].[Header_ESRD] ,
                                 [RowDisplay] = 'Total' ,
                                 [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                                 [HCCTotal_A] = SUM([m].[HCCTotal_A]) ,
                                 [EstRev_A] = SUM([m].[EstRev_A]) ,
                                 [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A]) = 0 THEN
                                                             0
                                                         ELSE
													 ( SUM([m].[EstRev_A]) * 1.0 )
													 / ( SUM([m].[HCCTotal_A]) * 1.0 )
																		END ,
								[EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
													 ( SUM([m].[EstRev_A]) * 1.0 )
													 / ( SUM([m].ChartsCompleted) * 1.0 )
																		END ,
                                 [HCCRealizationRate_A] = NULL ,
                                 [HCCTotal_B] = SUM([m].[HCCTotal_B]) ,
                                 [EstRev_B] = SUM([m].[EstRev_B]) ,
                                 [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B]) = 0 THEN
                                                             0
                                                         ELSE
														 ( SUM([m].[EstRev_B]) * 1.0 )
														 / ( SUM([m].[HCCTotal_B]) * 1.0 )
																			END ,
								[EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
													 ( SUM([m].[EstRev_B]) * 1.0 )
													 / ( SUM([m].ChartsCompleted) * 1.0 )
																		END ,
                                 [HCCRealizationRate_B] = NULL ,
                                 [HCCTotal_ESRD] = SUM([m].[HCCTotal_ESRD]) ,
                                 [EstRev_ESRD] = SUM([m].[EstRev_ESRD]) ,
                                 [EstRevPerHCC_ESRD] = CASE WHEN SUM([m].[HCCTotal_ESRD]) = 0 THEN
                                                                0
                                                            ELSE
                                 ( SUM([m].[EstRev_ESRD]) * 1.0 )
                                 / ( SUM([m].[HCCTotal_ESRD]) * 1.0 )
                                                       END ,
                                 [HCCRealizationRate_ESRD] = NULL ,
                                 [ProjectId] = NULL ,
                                 [ProjectDescription] = NULL ,
                                 [SubProjectId] = NULL ,
                                 [SubProjectDescription] = NULL ,
                                 [ReviewName] = NULL ,
                                 [ProjectSortOrder] = NULL ,
                                 [SubProjectSortOrder] = NULL ,
                                 [OrderFlag] = 0 ,
                                 [PopulatedDate] = [m].[PopulatedDate],
                                 'C'
                        FROM     [Valuation].[RptPaymentDetail] [m]
                        WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                                 AND [m].[ReportType] = 'TotalsDetail'
                                 AND [m].[ReportSubType] = @FailureReason
                                 AND [m].[ClientId] = @ClientId
                                 AND [m].[OrderFlag] = 2
                                 AND (   [m].[HCCTotal_A] IS NOT NULL
                                         OR [m].[HCCTotal_B] IS NOT NULL
                                         OR [m].[HCCTotal_ESRD] IS NOT NULL
                                     )
                                 AND [m].Part_C_D = 'C'
                        GROUP BY [m].[AutoProcessRunId] ,
                                 [m].[ClientId] ,
                                 [m].[ReportHeader] ,
                                 [m].[ReportType] ,
                                 [m].[ReportSubType] ,
                                 [m].[Header_A] ,
                                 [m].[Header_B] ,
                                 [m].[Header_ESRD] ,
                                 [m].[PopulatedDate]

        ----Part D totals 
        
        
            INSERT INTO [Valuation].[RptPaymentDetail] (   [AutoProcessRunId] ,
                                                           [ClientId] ,
                                                           [ReportHeader] ,
                                                           [ReportType] ,
                                                           [ReportSubType] ,
                                                           [Header_A] ,
                                                           [Header_B] ,
                                                           [Header_ESRD] ,
                                                           [RowDisplay] ,
                                                           [ChartsCompleted] ,
                                                           [HCCTotal_A] ,
                                                           [EstRev_A] ,
                                                           [EstRevPerHCC_A] ,
                                                           [EstRevPerChart_A],
                                                           [HCCRealizationRate_A] ,
                                                           [HCCTotal_B] ,
                                                           [EstRev_B] ,
                                                           [EstRevPerHCC_B] ,
                                                           [EstRevPerChart_B],
                                                           [HCCRealizationRate_B] ,
                                                           [ProjectId] ,
                                                           [ProjectDescription] ,
                                                           [SubProjectId] ,
                                                           [SubProjectDescription] ,
                                                           [ReviewName] ,
                                                           [ProjectSortOrder] ,
                                                           [SubProjectSortOrder] ,
                                                           [OrderFlag] ,
                                                           [PopulatedDate],
                                                           [Part_C_D]
                                                       )
                        SELECT   [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                                 [ClientId] = [m].[ClientId] ,
                                 [ReportHeader] = [m].[ReportHeader] ,
                                 [ReportType] = [m].[ReportType] ,
                                 [ReportSubType] = [m].[ReportSubType] ,
                                 [Header_A] = [m].[Header_A] ,
                                 [Header_B] = [m].[Header_B] ,
                                 [Header_ESRD] = [m].[Header_ESRD] ,
                                 [RowDisplay] = 'Total' ,
                                 [ChartsCompleted] = SUM([m].[ChartsCompleted]) ,
                                 [HCCTotal_A] = SUM([m].[HCCTotal_A]) ,
                                 [EstRev_A] = SUM([m].[EstRev_A]) ,
                                 [EstRevPerHCC_A] = CASE WHEN SUM([m].[HCCTotal_A]) = 0 THEN
                                                             0
                                                         ELSE
													 ( SUM([m].[EstRev_A]) * 1.0 )
													 / ( SUM([m].[HCCTotal_A]) * 1.0 )
																		END ,
								[EstRevPerChart_A] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
													 ( SUM([m].[EstRev_A]) * 1.0 )
													 / ( SUM([m].ChartsCompleted) * 1.0 )
																		END ,
                                 [HCCRealizationRate_A] = NULL ,
                                 [HCCTotal_B] = SUM([m].[HCCTotal_B]) ,
                                 [EstRev_B] = SUM([m].[EstRev_B]) ,
                                 [EstRevPerHCC_B] = CASE WHEN SUM([m].[HCCTotal_B]) = 0 THEN
                                                             0
                                                         ELSE
														 ( SUM([m].[EstRev_B]) * 1.0 )
														 / ( SUM([m].[HCCTotal_B]) * 1.0 )
																			END ,
								[EstRevPerChart_B] = CASE WHEN SUM([m].ChartsCompleted) = 0 THEN
                                                             0
                                                         ELSE
													 ( SUM([m].[EstRev_B]) * 1.0 )
													 / ( SUM([m].ChartsCompleted) * 1.0 )
																		END ,
                                 [HCCRealizationRate_B] = NULL ,
                                 [ProjectId] = NULL ,
                                 [ProjectDescription] = NULL ,
                                 [SubProjectId] = NULL ,
                                 [SubProjectDescription] = NULL ,
                                 [ReviewName] = NULL ,
                                 [ProjectSortOrder] = NULL ,
                                 [SubProjectSortOrder] = NULL ,
                                 [OrderFlag] = 0 ,
                                 [PopulatedDate] = [m].[PopulatedDate],
                                 'D'
                        FROM     [Valuation].[RptPaymentDetail] [m]
                        WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                                 AND [m].[ReportType] = 'TotalsDetail'
                                 AND [m].[ReportSubType] = @FailureReason
                                 AND [m].[ClientId] = @ClientId
                                 AND [m].[OrderFlag] = 2
                                 AND [m].Part_C_D = 'D'
                                 AND (   [m].[HCCTotal_A] IS NOT NULL
                                         OR [m].[HCCTotal_B] IS NOT NULL
                                         OR [m].[HCCTotal_ESRD] IS NOT NULL
                                     )
                        GROUP BY [m].[AutoProcessRunId] ,
                                 [m].[ClientId] ,
                                 [m].[ReportHeader] ,
                                 [m].[ReportType] ,
                                 [m].[ReportSubType] ,
                                 [m].[Header_A] ,
                                 [m].[Header_B] ,
                                 [m].[Header_ESRD] ,
                                 [m].[PopulatedDate]

         
        ----Part D Totals  
         
                  
  
         
         
            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = 'WL064 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail] for '
                               + @FailureReason + ' Totals - Detail'
                    RAISERROR(@Msg, 16, 1)
                    SET @Msg = NULL
                END

            /*E Totals Detail*/

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL065', 0, 1) WITH NOWAIT
                END

            /*B Totals Summary */

            DELETE [m]
            FROM  [Valuation].[RptTotal] [m]
            WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
                  AND [m].[ReportType] = 'TotalsSummary'
                  AND [m].[ReportSubType] = @FailureReason
                  AND [m].[ClientId] = @ClientId

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL066', 0, 1) WITH NOWAIT
                END
                --
                /**/;
            WITH [CTE_a1]
            AS ( SELECT   [SubProjectId] = [a1].[SubProjectId] ,
                          [HCCTotal] = AVG([a1].[HCCTotal]) ,
                          [AnnualizedEstimatedValue] = SUM([a1].[AnnualizedEstimatedValue])
                 FROM     [Valuation].[CalcPartCSubProjectModelYearCI] [a1] WITH ( NOLOCK )
                 WHERE    [a1].[Model_Year] IN ( @ModelYearA, @ModelYearB )
                          AND [a1].[PMH_Attestation] = @FailureReason
                          AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                          AND [a1].[ClientId] = @ClientId
                 GROUP BY [a1].[SubProjectId]
               )
            INSERT INTO [Valuation].[RptTotal] (   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [Header] ,
                                                   [RowDisplay] ,
                                                   [HCCTotal_PartC] ,
                                                   [EstRev_PartC] ,
                                                   [EstRevPerHCC_PartC] ,
                                                   [HCCTotal_PartD] ,
                                                   [EstRev_PartD] ,
                                                   [EstRevPerHCC_PartD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate]
                                               )
                        SELECT [ReportType] = 'TotalsSummary' ,
                               [ReportSubType] = @FailureReason ,
                               [ClientId] = @ClientId ,
                               [AutoProcessRunId] = @AutoProcessRunId ,
                               [ReportHeader] = @FailureReason + ' Totals' , --@ClientName + ' - ' + @FailureReason + ' Totals'
                               [Header] = @TotalsSummaryHeader ,             --'RAPS SUBMISSIONS - REALIZED for 2014 Payment Year'
                               [RowDisplay] = [a].[RowDisplay] ,
                               [HCCTotal_PartC] = [a].[HCCTotalPartC] ,
                               [EstRev_PartC] = [a].[EstRev_PartC] ,
                               [EstRevPerHCC_PartC] = [a].[EstRecVsHCCPartC] ,
                               [HCCTotal_PartD] = [a].[HCCTotalPartD] ,
                               [EstRec_PartD] = [a].[AnnualizedEstimatedValuePartD] ,
                               [EstRevPerHCC_PartD] = [a].[EstRecVsHCCPartD] ,
                               [ProjectId] = [a].[ProjectId] ,
                               [ProjectDescription] = [a].[ProjectDescription] ,
                               [SubProjectId] = [a].[SubProjectId] ,
                               [SubProjectDescription] = [a].[SubProjectDescription] ,
                               [ProjectSortOrder] = [a].[ProjectSortOrder] ,
                               [SubProjectSortOrder] = [a].[SubProjectSortOrder] ,
                               [OrderFlag] = [a].[OrderFlag] ,
                               [PopulatedDate] = @PopulatedDate
                        FROM   (   SELECT   [RowDisplay] = CAST([a0].[SubProjectId] AS VARCHAR(11))
                                                           + ' - '
                                                           + [a0].[SubProjectDescription] ,
                                            [FailureReason] = @FailureReason ,
                                            [HCCTotalPartC] = ISNULL(
                                                                        AVG([a1].[HCCTotal])
                                                                        + [b2].[CountOfHICN] ,
                                                                        0
                                                                    ) ,
                                            [EstRev_PartC] = ISNULL(
                                                                       [a1].[AnnualizedEstimatedValue] ,
                                                                       0
                                                                   )
                                                             + ISNULL(
                                                                         [c3].[AnnualizedEstimatedValue] ,
                                                                         0
                                                                     ) ,
                                            [EstRecVsHCCPartC] = CASE WHEN ISNULL(
                                                                                     [a1].[HCCTotal] ,
                                                                                     0
                                                                                 ) = 0 THEN
                                                                          0
                                                                      ELSE
                                            ( ISNULL(
                                                        [a1].[AnnualizedEstimatedValue] ,
                                                        0
                                                    )
                                              + ISNULL(
                                                          [c3].[AnnualizedEstimatedValue] ,
                                                          0
                                                      )
                                            )
                                            / ( [a1].[HCCTotal]
                                                + [b2].[CountOfHICN]
                                              )
                                                                 END ,
                                            [HCCTotalPartD] = ISNULL(
                                                                        [d4].[RxHCCTotal] ,
                                                                        0
                                                                    ) ,
                                            [AnnualizedEstimatedValuePartD] = ISNULL(
                                                                                        [d4].[Annualized_Estimated_Value] ,
                                                                                        0
                                                                                    ) ,
                                            [EstRecVsHCCPartD] = ISNULL(
                                                                           CASE WHEN [d4].[RxHCCTotal] = 0 THEN
                                                                                    0
                                                                                ELSE
                                                                                    [d4].[Annualized_Estimated_Value]
                                                                                    / [d4].[RxHCCTotal]
                                                                           END ,
                                                                           0
                                                                       ) ,
                                            [ProjectId] = [a0].[ProjectId] ,
                                            [ProjectDescription] = [a0].[ProjectDescription] , --CAST([a0].[ProjectId] AS VARCHAR(11)) + ' - ' + [a0].[ProjectDescription]
                                            [SubProjectId] = [a0].[SubProjectId] ,
                                            [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                            [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                            [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                            [OrderFlag] = 2
                                   FROM     #ProjectSubprojectReviewList [a0]
                                            LEFT JOIN [CTE_a1] [a1] ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                            LEFT JOIN [Valuation].[CalcPMHAndAttestationHCCTotalsESRD] [b2] WITH ( NOLOCK ) ON [a1].[SubProjectId] = [b2].[SubProjectId]
                                                                                                                               AND [b2].[PMH_Attestation] = @FailureReason
                                            LEFT JOIN [Valuation].[CalcPMHAndAttestationTotalsESRD] [c3] WITH ( NOLOCK ) ON [a1].[SubProjectId] = [c3].[SubProjectId]
                                                                                                                            AND [c3].[PMH_Attestation] = @FailureReason
                                                                                                                            AND [c3].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                            AND [c3].[ClientId] = @ClientId
                                            LEFT JOIN [Valuation].[CalcPartDTotalsBySubProject] [d4] WITH ( NOLOCK ) ON [a1].[SubProjectId] = [d4].[SubProjectId]
                                                                                                                        AND [d4].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                        AND [d4].[ClientId] = @ClientId
                                   WHERE    [a0].[SubProjectId] IS NOT NULL
                                   GROUP BY [a0].[FailureReason] ,
                                            [b2].[CountOfHICN] ,
                                            [c3].[AnnualizedEstimatedValue] ,
                                            [d4].[RxHCCTotal] ,
                                            [d4].[Annualized_Estimated_Value] ,
                                            [a0].[ProjectId] ,
                                            [a0].[ProjectDescription] ,
                                            [a0].[SubProjectId] ,
                                            [a0].[SubProjectDescription] ,
                                            [a0].[ProjectSortOrder] ,
                                            [a0].[SubProjectSortOrder] ,
                                            [a1].[AnnualizedEstimatedValue] ,
                                            [a1].[HCCTotal] /**/
                                   UNION ALL /**/
                                   SELECT   [RowDisplay] = 'Filtered Audit - '
                                                           + ISNULL(
                                                                       [a0].[ReviewName] ,
                                                                       ''
                                                                   ) ,
                                            [FailureReason] = @FailureReason ,
                                            [HCCTotalPartC] = ISNULL(
                                                                        AVG([a1].[HCCTotal])
                                                                        + ISNULL(
                                                                                    [b2].[HCCTotal] ,
                                                                                    0
                                                                                ) ,
                                                                        0
                                                                    ) ,
                                            [EstRev_PartC] = ISNULL(
                                                                       SUM([a1].[AnnualizedEstimatedValue])
                                                                       + ISNULL(
                                                                                   [b2].[AnnualizedEstimatedValue] ,
                                                                                   0
                                                                               ) ,
                                                                       0
                                                                   ) ,
                                            [EstRecVsHCCPartC] = CASE WHEN ISNULL(
                                                                                     AVG([a1].[HCCTotal])
                                                                                     + ISNULL(
                                                                                                 [b2].[HCCTotal] ,
                                                                                                 0
                                                                                             ) ,
                                                                                     0
                                                                                 ) = 0 THEN
                                                                          0
                                                                      ELSE
                                            ( ISNULL(
                                                        SUM([a1].[AnnualizedEstimatedValue])
                                                        + ISNULL(
                                                                    [b2].[AnnualizedEstimatedValue] ,
                                                                    0
                                                                ) ,
                                                        0
                                                    )
                                            )
                                            / ( ISNULL(
                                                          AVG([a1].[HCCTotal])
                                                          + ISNULL(
                                                                      [b2].[HCCTotal] ,
                                                                      0
                                                                  ) ,
                                                          0
                                                      )
                                              )
                                                                 END ,
                                            [HCCTotalPartD] = ISNULL(
                                                                        [c3].[HCCTotal] ,
                                                                        0
                                                                    ) ,
                                            [AnnualizedEstimatedValuePartD] = ISNULL(
                                                                                        [c3].[Annualized_Estimated_Value] ,
                                                                                        0
                                                                                    ) ,
                                            [EstRecVsHCCPartD] = CASE WHEN ISNULL(
                                                                                     [c3].[HCCTotal] ,
                                                                                     0
                                                                                 ) = 0 THEN
                                                                          0
                                                                      ELSE
                                                                          ISNULL(
                                                                                    [c3].[Annualized_Estimated_Value] ,
                                                                                    0
                                                                                )
                                                                          / [c3].[HCCTotal]
                                                                 END ,
                                            [ProjectId] = [a0].[ProjectId] ,
                                            [ProjectDescription] = [a0].[ProjectDescription] , --CAST([a0].[ProjectId] AS VARCHAR(11)) + ' - ' + [a0].[ProjectDescription]
                                            [SubProjectId] = [a0].[SubProjectId] ,
                                            [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                            [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                            [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                            [OrderFlag] = 3
                                   FROM     #ProjectSubprojectReviewList [a0]
                                            LEFT JOIN [Valuation].[CalcPMHAttestationFilteredAuditHCCTotalsCI] [a1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                                                                       AND [a0].[ReviewName] = [a1].[ReviewName]
                                                                                                                                       AND [a1].[Model_Year] IN ( @ModelYearA ,
                                                                                                                                                                  @ModelYearB
                                                                                                                                                                )
                                                                                                                                       AND [a1].[PMH_Attestation] = @FailureReason
                                                                                                                                       AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                                       AND [a1].[ClientId] = @ClientId
                                            LEFT JOIN [Valuation].[CalcPMHAttestationFilteredAuditTotalsESRD] [b2] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [b2].[SubProjectId]
                                                                                                                                      AND [a0].[ReviewName] = [b2].[ReviewName]
                                                                                                                                      AND [b2].[Model_Year] IN ( @ModelYearA ,
                                                                                                                                                                 @ModelYearB
                                                                                                                                                               )
                                                                                                                                      AND [b2].[PMH_Attestation] = @FailureReason
                                                                                                                                      AND [b2].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                                      AND [b2].[ClientId] = @ClientId
                                            LEFT JOIN [Valuation].[CalcPartDFilteredAuditTotals] [c3] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [c3].[SubProjectId]
                                                                                                                         AND [a0].[ReviewName] = [c3].[ReviewName]
                                                                                                                         AND [c3].[PMH_Attestation] = @FailureReason
                                                                                                                         AND [c3].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                         AND [c3].[ClientId] = @ClientId
                                   WHERE    [a0].[SubProjectId] IS NOT NULL
                                   GROUP BY [a0].[FailureReason] ,
                                            [a0].[ReviewName] ,
                                            [b2].[HCCTotal] ,
                                            [b2].[AnnualizedEstimatedValue] ,
                                            [c3].[HCCTotal] ,
                                            [c3].[Annualized_Estimated_Value] ,
                                            [a0].[ProjectId] ,
                                            [a0].[ProjectDescription] ,
                                            [a0].[SubProjectId] ,
                                            [a0].[SubProjectDescription] ,
                                            [a0].[ProjectSortOrder] ,
                                            [a0].[SubProjectSortOrder]
                               ) [a]

            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = 'WL066 - Notice: Zero rows loaded to [Valuation].[RptPaymentDetail] for '
                               + @FailureReason + ' TotalsSummary'
                    RAISERROR(@Msg, 16, 1)
                    SET @Msg = NULL
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL067', 0, 1) WITH NOWAIT
                END

            INSERT INTO [Valuation].[RptTotal] (   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [Header] ,
                                                   [RowDisplay] ,
                                                   [HCCTotal_PartC] ,
                                                   [EstRev_PartC] ,
                                                   [EstRevPerHCC_PartC] ,
                                                   [HCCTotal_PartD] ,
                                                   [EstRev_PartD] ,
                                                   [EstRevPerHCC_PartD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate]
                                               )
                        SELECT   [ReportType] = [m].[ReportType] ,
                                 [ReportSubType] = [m].[ReportSubType] ,
                                 [ClientId] = [m].[ClientId] ,
                                 [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                                 [ReportHeader] = [m].[ReportHeader] ,
                                 [Header] = [m].[Header] ,
                                 [RowDisplay] = CAST([m].[ProjectId] AS VARCHAR(11))
                                                + ' - '
                                                + [m].[ProjectDescription] ,
                                 [HCCTotal_PartC] = SUM([m].[HCCTotal_PartC]) ,
                                 [EstRev_PartC] = SUM([m].[EstRev_PartC]) ,
                                 [EstRevPerHCC_PartC] = CASE WHEN SUM([m].[HCCTotal_PartC]) = 0 THEN
                                                                 0
                                                             ELSE
                                                                 SUM(( [m].[EstRev_PartC]
                                                                       * 1.0
                                                                     )
                                                                    )
                                                                 / SUM(( [m].[HCCTotal_PartC]
                                                                         * 1.0
                                                                       )
                                                                      )
                                                        END ,
                                 [HCCTotal_PartD] = SUM([m].[HCCTotal_PartD]) ,
                                 [EstRev_PartD] = SUM([m].[EstRev_PartD]) ,
                                 [EstRevPerHCC_PartD] = CASE WHEN SUM([m].[HCCTotal_PartD]) = 0 THEN
                                                                 0
                                                             ELSE
                                                                 SUM(( [m].[EstRev_PartD]
                                                                       * 1.0
                                                                     )
                                                                    )
                                                                 / SUM(( [m].[HCCTotal_PartD]
                                                                         * 1.0
                                                                       )
                                                                      )
                                                        END ,
                                 [ProjectId] = [m].[ProjectId] ,
                                 [ProjectDescription] = [m].[ProjectDescription] ,
                                 [SubProjectId] = NULL ,
                                 [SubProjectDescription] = NULL ,
                                 [ProjectSortOrder] = [m].[ProjectSortOrder] ,
                                 [SubProjectSortOrder] = NULL ,
                                 [OrderFlag] = 1 ,
                                 [PopulatedDate] = [m].[PopulatedDate]
                        FROM     [Valuation].[RptTotal] [m]
                        WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                                 AND [m].[ReportType] = 'TotalsSummary'
                                 AND [m].[ReportSubType] = @FailureReason
                                 AND [m].[ClientId] = @ClientId
                                 AND [m].[OrderFlag] = 2
                        GROUP BY [m].[ReportType] ,
                                 [m].[ReportSubType] ,
                                 [m].[ClientId] ,
                                 [m].[AutoProcessRunId] ,
                                 [m].[ReportHeader] ,
                                 [m].[Header] ,
                                 [m].[ProjectId] ,
                                 [m].[ProjectDescription] ,
                                 [m].[ProjectSortOrder] ,
                                 [m].[PopulatedDate]

            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = 'WL067 - Notice: Zero rows loaded to [Valuation].[RptTotal] for '
                               + @FailureReason + ' TotalsSummary'
                    RAISERROR(@Msg, 16, 1)
                    SET @Msg = NULL
                END

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL068', 0, 1) WITH NOWAIT
                END

            INSERT INTO [Valuation].[RptTotal] (   [ReportType] ,
                                                   [ReportSubType] ,
                                                   [ClientId] ,
                                                   [AutoProcessRunId] ,
                                                   [ReportHeader] ,
                                                   [Header] ,
                                                   [RowDisplay] ,
                                                   [HCCTotal_PartC] ,
                                                   [EstRev_PartC] ,
                                                   [EstRevPerHCC_PartC] ,
                                                   [HCCTotal_PartD] ,
                                                   [EstRev_PartD] ,
                                                   [EstRevPerHCC_PartD] ,
                                                   [ProjectId] ,
                                                   [ProjectDescription] ,
                                                   [SubProjectId] ,
                                                   [SubProjectDescription] ,
                                                   [ProjectSortOrder] ,
                                                   [SubProjectSortOrder] ,
                                                   [OrderFlag] ,
                                                   [PopulatedDate]
                                               )
                        SELECT   [ReportType] = [m].[ReportType] ,
                                 [ReportSubType] = [m].[ReportSubType] ,
                                 [ClientId] = [m].[ClientId] ,
                                 [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                                 [ReportHeader] = [m].[ReportHeader] ,
                                 [Header] = [m].[Header] ,
                                 [RowDisplay] = 'Total' ,
                                 [HCCTotal_PartC] = SUM([m].[HCCTotal_PartC]) ,
                                 [EstRev_PartC] = SUM([m].[EstRev_PartC]) ,
                                 [EstRevPerHCC_PartC] = CASE WHEN SUM([m].[HCCTotal_PartC]) = 0 THEN
                                                                 0
                                                             ELSE
                                                                 SUM(( [m].[EstRev_PartC]
                                                                       * 1.0
                                                                     )
                                                                    )
                                                                 / SUM(( [m].[HCCTotal_PartC]
                                                                         * 1.0
                                                                       )
                                                                      )
                                                        END ,
                                 [HCCTotal_PartD] = SUM([m].[HCCTotal_PartD]) ,
                                 [EstRev_PartD] = SUM([m].[EstRev_PartD]) ,
                                 [EstRevPerHCC_PartD] = CASE WHEN SUM([m].[HCCTotal_PartD]) = 0 THEN
                                                                 0
                                                             ELSE
                                                                 SUM(( [m].[EstRev_PartD]
                                                                       * 1.0
                                                                     )
                                                                    )
                                                                 / SUM(( [m].[HCCTotal_PartD]
                                                                         * 1.0
                                                                       )
                                                                      )
                                                        END ,
                                 [ProjectId] = NULL ,
                                 [ProjectDescription] = NULL ,
                                 [SubProjectId] = NULL ,
                                 [SubProjectDescription] = NULL ,
                                 [ProjectSortOrder] = NULL ,
                                 [SubProjectSortOrder] = NULL ,
                                 [OrderFlag] = 0 ,
                                 [PopulatedDate] = [m].[PopulatedDate]
                        FROM     [Valuation].[RptTotal] [m]
                        WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                                 AND [m].[ReportType] = 'TotalsSummary'
                                 AND [m].[ReportSubType] = @FailureReason
                                 AND [m].[ClientId] = @ClientId
                                 AND [m].[OrderFlag] = 1
                        GROUP BY [m].[ReportType] ,
                                 [m].[ReportSubType] ,
                                 [m].[ClientId] ,
                                 [m].[AutoProcessRunId] ,
                                 [m].[ReportHeader] ,
                                 [m].[Header] ,
                                 [m].[PopulatedDate]

            IF @@ROWCOUNT = 0
                BEGIN
                    SET @Msg = 'WL068 - Notice: Zero rows loaded to [Valuation].[RptTotal] for '
                               + @FailureReason + ' TotalsSummary'
                    RAISERROR(@Msg, 16, 1)
                    SET @Msg = NULL
                END

            /*E Totals Summary */

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL069', 0, 1) WITH NOWAIT
                END

            DELETE [m]
            FROM  @FailureReasonList [m]
            WHERE [m].[FailureReason] = @FailureReason

            IF @Debug = 1
                BEGIN
                    PRINT 'ET: '
                          + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                          + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                          + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114)
                          + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)
                    SET @ET = GETDATE()
                    RAISERROR('WL070', 0, 1) WITH NOWAIT
                END
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('071', 0, 1) WITH NOWAIT
        END

    /*B Add data to [RptRetrospectiveValuation] */

    DELETE [m]
    FROM  [Valuation].[RptRetrospectiveValuation] [m]
    WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
          AND [m].[ClientId] = @ClientId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('072', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptRetrospectiveValuation] (   [ClientId] ,
                                                            [AutoProcessRunId] ,
                                                            [ReportHeader] ,
                                                            [RowDisplay] ,
                                                            [TotalChartsRequested] ,
                                                            [TotalChartsRetrieved] ,
                                                            [TotalChartsNotRetrieved] ,
                                                            [TotalChartsAdded] ,
                                                            [TotalCharts1stPassCoded] ,
                                                            [TotalChartsCompleted] ,
                                                            [ProjectCompletion] ,
                                                            [ProjectId] ,
                                                            [ProjectDescription] ,
                                                            [SubProjectId] ,
                                                            [SubProjectDescription] ,
                                                            [ProjectSortOrder] ,
                                                            [SubProjectSortOrder] ,
                                                            [OrderFlag] ,
                                                            [PopulatedDate]
                                                        )
                SELECT DISTINCT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = @AutoProcessRunId ,
                       [ReportHeader] = 'Chart Retrieval And Coding - By Subproject' ,
                       [RowDisplay] = CAST([a0].[SubProjectId] AS VARCHAR(11))
                                      + ' - ' + [a0].[SubProjectDescription] ,
                       [TotalChartsRequested] = [ctrs].[ChartsRequested] ,
                       [TotalChartsRetrieved] = [ctrs].[ChartsVHRetrieved] ,
                       [TotalChartsNotRetrieved] = [ctrs].[ChartsRequested]
                                                   - [ctrs].[ChartsVHRetrieved] ,
                       [TotalChartsAdded] = [ctrs].[ChartsAdded] ,
                       [TotalCharts1stPassCoded] = [ctrs].[ChartsFPC] ,
                       [TotalChartsCompleted] = [ctrs].[ChartsComplete] ,
                       [ProjectCompletion] = CAST(CASE WHEN ISNULL(
                                                                      [ctrs].[ChartsRequested] ,
                                                                      0
                                                                  ) = 0
                                                            AND ISNULL(
                                                                          [ctrs].[ChartsAdded] ,
                                                                          0
                                                                      ) > 0 THEN
                       ( ISNULL([ctrs].[ChartsComplete], 0)
                         / ( ISNULL([ctrs].[ChartsAdded], 0) * 1.0 )
                       ) * 100
                                                       WHEN ISNULL(
                                                                      [ctrs].[ChartsRequested] ,
                                                                      0
                                                                  ) = 0 THEN
                                                           0
                                                       ELSE
                       ( [ctrs].[ChartsComplete]
                         / ( ISNULL([ctrs].[ChartsRequested], 0) * 1.0 )
                       )
                       * 100
                                                  END AS DECIMAL(10, 3)) ,
                       [ProjectId] = [a0].[ProjectId] ,
                       [ProjectDescription] = [a0].[ProjectDescription] ,
                       [SubProjectId] = [a0].[SubProjectId] ,
                       [SubProjectDescription] = [a0].[SubProjectDescription] ,
                       [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                       [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                       [OrderFlag] = 2 ,
                       [PopulatedDate] = @PopulatedDate
                FROM   #ProjectSubprojectReviewList [a0]
                       JOIN [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [ctrs].[SubProjectId]
                                                                                  AND [ctrs].[LoadDate] = @CTRLoadDate
                                                                                  AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId
                                                                                  AND [ctrs].[ClientId] = @ClientId

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '072 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuation]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('073', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptRetrospectiveValuation] (   [ClientId] ,
                                                            [AutoProcessRunId] ,
                                                            [ReportHeader] ,
                                                            [RowDisplay] ,
                                                            [TotalChartsRequested] ,
                                                            [TotalChartsRetrieved] ,
                                                            [TotalChartsNotRetrieved] ,
                                                            [TotalChartsAdded] ,
                                                            [TotalCharts1stPassCoded] ,
                                                            [TotalChartsCompleted] ,
                                                            [ProjectCompletion] ,
                                                            [ProjectId] ,
                                                            [ProjectDescription] ,
                                                            [SubProjectId] ,
                                                            [SubProjectDescription] ,
                                                            [ProjectSortOrder] ,
                                                            [SubProjectSortOrder] ,
                                                            [OrderFlag] ,
                                                            [PopulatedDate]
                                                        )
                SELECT   [ClientId] = [rv].[ClientId] ,
                         [AutoProcessRunId] = [rv].[AutoProcessRunId] ,
                         [ReportHeader] = [rv].[ReportHeader] ,
                         [RowDisplay] = CAST([rv].[ProjectId] AS VARCHAR(11))
                                        + ' - ' + [rv].[ProjectDescription] ,
                         [TotalChartsRequested] = SUM([rv].[TotalChartsRequested]) ,
                         [TotalChartsRetrieved] = SUM([rv].[TotalChartsRetrieved]) ,
                         [TotalChartsNotRetrieved] = SUM([rv].[TotalChartsNotRetrieved]) ,
                         [TotalChartsAdded] = SUM([rv].[TotalChartsAdded]) ,
                         [TotalCharts1stPassCoded] = SUM([rv].[TotalCharts1stPassCoded]) ,
                         [TotalChartsCompleted] = SUM([rv].[TotalChartsCompleted]) ,
                         [ProjectCompletion] = CAST(CASE WHEN ISNULL(
                                                                        SUM([rv].[TotalChartsRequested]) ,
                                                                        0
                                                                    ) = 0 THEN
                                                             0
                                                         ELSE
                         ( SUM([rv].[TotalChartsCompleted])
                           / ( ISNULL(SUM([rv].[TotalChartsRequested]), 0)
                               * 1.0
                             )
                         ) * 100
                                                    END AS DECIMAL(10, 3)) ,
                         [ProjectId] = [rv].[ProjectId] ,
                         [ProjectDescription] = [rv].[ProjectDescription] ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ProjectSortOrder] = NULL ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 1 ,
                         [PopulatedDate] = [rv].[PopulatedDate]
                FROM     [Valuation].[RptRetrospectiveValuation] [rv]
                WHERE    [rv].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rv].[ClientId] = @ClientId
                         AND [rv].[OrderFlag] = 2
                GROUP BY [rv].[ClientId] ,
                         [rv].[AutoProcessRunId] ,
                         [rv].[ReportHeader] ,
                         [rv].[ProjectId] ,
                         [rv].[ProjectDescription] ,
                         [rv].[ProjectSortOrder] ,
                         [rv].[PopulatedDate]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '073 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuation]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('074', 0, 1) WITH NOWAIT
        END


        --
        /**/;
    WITH [CTE_a0]
    AS ( SELECT   [SubProjectId] = [psr].[SubProjectId]
         FROM     #ProjectSubprojectReviewList [psr]
         GROUP BY [psr].[SubProjectId]
       )
    INSERT INTO [Valuation].[RptRetrospectiveValuation] (   [ClientId] ,
                                                            [AutoProcessRunId] ,
                                                            [ReportHeader] ,
                                                            [RowDisplay] ,
                                                            [TotalChartsRequested] ,
                                                            [TotalChartsRetrieved] ,
                                                            [TotalChartsNotRetrieved] ,
                                                            [TotalChartsAdded] ,
                                                            [TotalCharts1stPassCoded] ,
                                                            [TotalChartsCompleted] ,
                                                            [ProjectCompletion] ,
                                                            [ProjectId] ,
                                                            [ProjectDescription] ,
                                                            [SubProjectId] ,
                                                            [SubProjectDescription] ,
                                                            [ProjectSortOrder] ,
                                                            [SubProjectSortOrder] ,
                                                            [OrderFlag] ,
                                                            [PopulatedDate]
                                                        )
                SELECT DISTINCT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = @AutoProcessRunId ,
                       [ReportHeader] = 'Chart Retrieval And Coding - By Subproject' ,
                       [RowDisplay] = 'Totals' ,
                       [TotalChartsRequested] = SUM([ctrs].[ChartsRequested]) ,
                       [TotalChartsRetrieved] = SUM([ctrs].[ChartsVHRetrieved]) ,
                       [TotalChartsNotRetrieved] = SUM([ctrs].[ChartsRequested])
                                                   - SUM([ctrs].[ChartsVHRetrieved]) ,
                       [TotalChartsAdded] = SUM([ctrs].[ChartsAdded]) ,
                       [TotalCharts1stPassCoded] = SUM([ctrs].[ChartsFPC]) ,
                       [TotalChartsCompleted] = SUM([ctrs].[ChartsComplete]) ,
                       [ProjectCompletion] = CAST(CASE WHEN ISNULL(
                                                                      SUM([ctrs].[ChartsRequested]) ,
                                                                      0
                                                                  ) = 0
                                                            AND ISNULL(
                                                                          SUM([ctrs].[ChartsAdded]) ,
                                                                          0
                                                                      ) > 0 THEN
                       ( ISNULL(SUM([ctrs].[ChartsComplete]), 0)
                         / ( ISNULL(SUM([ctrs].[ChartsAdded]), 0) * 1.0 )
                       )
                       * 100
                                                       WHEN ISNULL(
                                                                      SUM([ctrs].[ChartsRequested]) ,
                                                                      0
                                                                  ) = 0 THEN
                                                           0
                                                       ELSE
                       ( SUM([ctrs].[ChartsComplete])
                         / ( ISNULL(SUM([ctrs].[ChartsRequested]), 0) * 1.0 )
                       )
                       * 100
                                                  END AS DECIMAL(10, 3)) ,
                       [ProjectId] = NULL ,
                       [ProjectDescription] = NULL ,    --[a0].[ProjectDescription]
                       [SubProjectId] = NULL ,          --[a0].[SubProjectId]
                       [SubProjectDescription] = NULL , --[a0].[SubProjectDescription]
                       [ProjectSortOrder] = NULL ,      --[a0].[ProjectSortOrder]
                       [SubProjectSortOrder] = NULL ,   --[a0].[SubProjectSortOrder]
                       [OrderFlag] = 0 ,
                       [PopulatedDate] = @PopulatedDate
                FROM   [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK )
                       JOIN [CTE_a0] [a0] ON [ctrs].[SubProjectId] = [a0].[SubProjectId]
                WHERE  [ctrs].[LoadDate] = @CTRLoadDate
                       AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId
                       AND [ctrs].[ClientId] = @ClientId

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '074 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuation]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E Add data to [RptRetrospectiveValuation] */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('075', 0, 1) WITH NOWAIT
        END

    /*B Add data to RptRetrospectiveValuationDetail */

    /*B Report:Retro Valuation From RAPS Subm */

    DELETE [rvd]
    FROM  [Valuation].[RptRetrospectiveValuationDetail] [rvd]
    WHERE [rvd].[AutoProcessRunId] = @AutoProcessRunId
          AND [rvd].[ClientId] = @ClientId
          AND [rvd].[ReportType] = 'RetrospectiveValuationDetail'

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('076', 0, 1) WITH NOWAIT
        END
        --		
        /**/;

/******************Part C *******/
  IF OBJECT_ID('TEMPDB..#PartCSubProjectModelYear' )   IS NOT NULL 
  DROP    TABLE #PartCSubProjectModelYear                          
 CREATE TABLE #PartCSubProjectModelYear
       (
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientId] [int] NOT NULL,
	[AutoProcessRunId] [int] NOT NULL,
	[SubProjectId] [int] NOT NULL,
	[Model_Year] [int] NULL,
	[HCCTotal] decimal(12,2) NULL,
	[AnnualizedEstimatedValue] [money] NULL,
	[PMH_Attestation] [varchar](255) NULL,
	[EncounterSource] [varchar](4) NULL ) 
	
	INSERT INTO  #PartCSubProjectModelYear
	(ClientId,	AutoProcessRunId,	SubProjectId,	Model_Year,	HCCTotal,	AnnualizedEstimatedValue	,PMH_Attestation,		EncounterSource)
	                         
		 SELECT 	ClientId,	
		           AutoProcessRunId,	SubProjectId,	Model_Year,	CASE WHEN Encountersource = 'RAPS' THEN HCCTotal * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN HCCTotal * @EDS
		                                                                  END AS   HCCTotal, 	
		                                                                  CASE WHEN Encountersource = 'RAPS' THEN AnnualizedEstimatedValue * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN AnnualizedEstimatedValue * @EDS
		                                                                  END 	AnnualizedEstimatedValue	,PMH_Attestation,		EncounterSource
		 FROM [Valuation].[CalcPartCSubProjectModelYearCI]   WHERE AutoProcessRunId = @AutoProcessRunId
		 UNION ALL 
		 SELECT 	ClientId,	AutoProcessRunId,	SubProjectId,	Model_Year,CASE WHEN Encountersource = 'RAPS' THEN HCCTotal * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN HCCTotal * @EDS
		                                                                  END AS   HCCTotal, 	CASE WHEN Encountersource = 'RAPS' THEN AnnualizedEstimatedValue * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN AnnualizedEstimatedValue * @EDS
		                                                                  END 	AnnualizedEstimatedValue	,PMH_Attestation,		EncounterSource 
		 FROM [Valuation].[CalcPartCTotalsBySubprojectAndModelYearESRD]     where AutoProcessRunId = @AutoProcessRunId      
	
      
        IF OBJECT_ID('TEMPDB..#PartCHCCtotal' )   IS NOT NULL 
		  DROP    TABLE #PartCHCCtotal                          
		 CREATE TABLE #PartCHCCtotal
			   (
			[ID] [int] IDENTITY(1,1) NOT NULL,
			[SubProjectId] [int] NOT NULL,
			[Model_Year] [int] NULL,
			[HCCTotal] [int] NULL,
			[HCCTotalrevised] int NULL, 
			[EncounterSource] [varchar](4) NULL ) 
        
        INSERT INTO #PartCHCCtotal
        
        ([SubProjectId], [Model_Year], [HCCTotal], [HCCTotalrevised], [EncounterSource] )
       SELECT   [SubProjectId] = [a2].[SubProjectId] ,
                  [Model_Year] = [a2].[Model_Year] ,
                  [HCCTotal] = COUNT([a2].[Updated HCC]),
                  [HCCTotalrevised] = CASE WHEN Encountersource = 'RAPS' THEN COUNT([a2].[Updated HCC]) * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN COUNT([a2].[Updated HCC]) * @EDS
		                                                                  END  ,  
                  EncounterSource
         FROM     [#02-Flagging PartC Subprojects] [a2]
         WHERE    [a2].[SubProjectId] IS NOT NULL
                  AND [a2].[SubProjectId] <> ''
                  AND [a2].[Unq_Conditions] = 1 
         GROUP BY [a2].[SubProjectId] ,
                  [a2].[Model_Year] ,
                  EncounterSource
                 
                    ;
-----------------Part D

  IF OBJECT_ID('TEMPDB..#PartDSubProjectModelYear' )   IS NOT NULL 
  DROP    TABLE #PartDSubProjectModelYear                          
 CREATE TABLE #PartDSubProjectModelYear
       (
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientId] [int] NOT NULL,
	[AutoProcessRunId] [int] NOT NULL,
	[SubProjectId] [int] NOT NULL,
	[Model_Year] [int] NULL,
	[HCCTotal] decimal(12,2) NULL,
	[AnnualizedEstimatedValue] [money] NULL,
	[EncounterSource] [varchar](4) NULL ) 
	
	INSERT INTO  #PartDSubProjectModelYear
	(ClientId,	AutoProcessRunId,	SubProjectId,	Model_Year,	HCCTotal,	AnnualizedEstimatedValue	,		EncounterSource)
	                         
		 SELECT 	ClientId,	
		           AutoProcessRunId,	SubProjectId,	ModelYear,	CASE WHEN Encountersource = 'RAPS' THEN RxHCCTotal * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN RxHCCTotal * @EDS
		                                                                  END AS   HCCTotal, 	
		                                                                  CASE WHEN Encountersource = 'RAPS' THEN Annualized_Estimated_Value * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN Annualized_Estimated_Value * @EDS
		                                                                  END 	AnnualizedEstimatedValue	,		EncounterSource
		 FROM [Valuation].CalcPartDTotalsBySubProject   WHERE AutoProcessRunId = @AutoProcessRunId
		 --UNION ALL 
		 --SELECT 	ClientId,	AutoProcessRunId,	SubProjectId,	Model_Year,CASE WHEN Encountersource = 'RAPS' THEN RxHCCTotal * @RAPS
		 --                                                                 WHEN Encountersource = 'EDS' THEN RxHCCTotal * @EDS
		 --                                                                 END AS   HCCTotal, 	CASE WHEN Encountersource = 'RAPS' THEN Annualized_Estimated_Value * @RAPS
		 --                                                                 WHEN Encountersource = 'EDS' THEN Annualized_Estimated_Value * @EDS
		 --                                                                 END 	AnnualizedEstimatedValue	,		EncounterSource 
		 --FROM [Valuation].CalcPartDTotalsBySubProject     where AutoProcessRunId = @AutoProcessRunId      
	
      
        IF OBJECT_ID('TEMPDB..#PartDHCCtotal' )   IS NOT NULL 
		  DROP    TABLE #PartDHCCtotal                          
		 CREATE TABLE #PartDHCCtotal
			   (
			[ID] [int] IDENTITY(1,1) NOT NULL,
			[SubProjectId] [int] NOT NULL,
			[Model_Year] [int] NULL,
			[HCCTotal] [int] NULL,
			[HCCTotalrevised] int NULL, 
			[EncounterSource] [varchar](4) NULL ) 
        
        INSERT INTO #PartDHCCtotal
        
        ([SubProjectId], [Model_Year], [HCCTotal], [HCCTotalrevised], [EncounterSource] )
       SELECT   [SubProjectId] = [a2].[SubProjectId] ,
                  [Model_Year] = [a2].[Model_Year] ,
                  [HCCTotal] = COUNT([a2].HCC),
                  [HCCTotalrevised] = CASE WHEN Encountersource = 'RAPS' THEN COUNT([a2].HCC) * @RAPS
		                                                                  WHEN Encountersource = 'EDS' THEN COUNT([a2].HCC) * @EDS
		                                                                  END  ,  
                  EncounterSource
         FROM     [#36-Flagging PartD Subprojects] [a2]
         WHERE    [a2].[SubProjectId] IS NOT NULL
                  AND [a2].[SubProjectId] <> ''
                  AND [a2].[Unq_Conditions] = 1 
         GROUP BY [a2].[SubProjectId] ,
                  [a2].[Model_Year] ,
                  EncounterSource
                            ;
-------Part D End------
    WITH
   [CTE_PartC]
    AS ( SELECT   [SubProjectId] ,
                  [HCCTotal] = SUM(HCCTotal),
                  [AnnualizedEstimatedValue] = SUM([AnnualizedEstimatedValue])                  
         FROM     #PartCSubProjectModelYear a1
         WHERE  [a1].[AutoProcessRunId] = @AutoProcessRunId                                                             
            AND [a1].[ClientId] = @ClientId
         GROUP BY [SubProjectId]
       ),
      
    [CTE_PartD]
    AS ( SELECT   [SubProjectId] ,
                  [HCCTotal] = SUM(HCCTotal),
                  [AnnualizedEstimatedValue] = SUM([AnnualizedEstimatedValue])
                  
         FROM     #PartDSubProjectModelYear a1
         WHERE  [a1].[AutoProcessRunId] = @AutoProcessRunId                                                             
            AND [a1].[ClientId] = @ClientId
         GROUP BY [SubProjectId]
       )
    INSERT INTO [Valuation].[RptRetrospectiveValuationDetail] (   [ClientId] ,
                                                                  [AutoProcessRunId] ,
                                                                  [ReportType] ,
                                                                  [ReportHeader] ,
                                                                  [DOSPaymentYearHeader] ,
                                                                  [RowDisplay] ,
                                                                  [ChartsCompleted] ,
                                                                  [HCCTotal_PartC] ,
                                                                  [EstRev_PartC] ,
                                                                  [EstRevPerHCC_PartC] ,
                                                                  [HCCRealizationRate_PartC] ,
                                                                  [HCCTotal_PartD] ,
                                                                  [EstRev_PartD] ,
                                                                  [EstRevPerHCC_PartD] ,
                                                                  [HCCRealizationRate_PartD] ,
                                                                  [EstRevPerChartsCompleted] ,
                                                                  [ProjectId] ,
                                                                  [ProjectDescription] ,
                                                                  [SubProjectId] ,
                                                                  [SubProjectDescription] ,
                                                                  [ReviewName] ,
                                                                  [ProjectSortOrder] ,
                                                                  [SubProjectSortOrder] ,
                                                                  [OrderFlag] ,
                                                                  [PopulatedDate]
                                                              )
                SELECT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                       [ReportType] = 'RetrospectiveValuationDetail' ,
                       [ReportHeader] = 'Retrospective Valuation Detail - RAPS/EDS' ,
                       [DOSPaymentYearHeader] = @RetrospectiveValuationDetailDOSPaymentYearHeader ,
                       [RowDisplay] = [a].[RowDisplay] ,
                       [ChartsCompleted] = [a].[ChartsCompleted] ,
                       [HCCTotal_PartC] = [a].[HCCTotal_PartC] ,
                       [EstRev_PartC] = [a].[EstRev_PartC] ,
                       [EstRevPerHCC_PartC] = [a].[EstRevPerHCC_PartC] ,
                       [HCCRealizationRate_PartC] = [a].[HCCRealizationRate_PartC] ,
                       [HCCTotal_PartD] = [a].[HCCTotal_PartD] ,
                       [EstRev_PartD] = [a].[EstRev_PartD] ,
                       [EstRevPerHCC_PartD] = [a].[EstRevPerHCC_PartD] ,
                       [HCCRealizationRate_PartD] = [a].[HCCRealizationRate_PartD] ,
                       [EstRevPerChartsCompleted] = [a].[EstRevPerChartsCompleted] ,
                       [ProjectId] = [a].[ProjectId] ,
                       [ProjectDescription] = [a].[ProjectDescription] ,
                       [SubProjectId] = [a].[SubProjectId] ,
                       [SubProjectDescription] = [a].[SubProjectDescription] ,
                       [ReviewName] = [a].[ReviewName] ,
                       [ProjectSortOrder] = [a].[ProjectSortOrder] ,
                       [SubProjectSortOrder] = [a].[SubProjectSortOrder] ,
                       [OrderFlag] = [a].[OrderFlag] ,
                       [PopulatedDate] = [a].[PopulatedDate]
                FROM   (   SELECT  [AutoProcessRunId] = @AutoProcessRunId ,
                                  [RowDisplay] = CAST([a0].[SubProjectId] AS VARCHAR(11))
                                                 + ' - '
                                                 + [a0].[SubProjectDescription] ,
                                  [ChartsCompleted] = [ctrs].[ChartsComplete] ,
                                  [HCCTotal_PartC] =   ISNULL(c1.[HCCTOTAL], 0 ) ,
                                  [EstRev_PartC] =    ISNULL( c1.[AnnualizedEstimatedValue], 0 )   ,
                                  [EstRevPerHCC_PartC] = CASE WHEN ISNULL( c1.[HCCTOTAL], 0 )  = 0 THEN 0 
                                                         ELSE  ISNULL( ( [c1].[AnnualizedEstimatedValue]), 0 )/ ISNULL(c1.[HCCTOTAL], 0 ) 
                                                         END  ,
                                  [HCCRealizationRate_PartC] = CASE WHEN ISNULL( [CTRS].[CHARTSCOMPLETE], 0 ) = 0 THEN 0 
                                                                       ELSE ISNULL(( c1.[HCCTOTAL]), 0 )   / ( [CTRS].[CHARTSCOMPLETE] * 1.0 ) * 100 END ,
                                  [HCCTotal_PartD] = ISNULL( [d1].HCCTotal , 0 ) ,
                                  [EstRev_PartD] = ISNULL( [d1].AnnualizedEstimatedValue, 0 ) ,
                                  [EstRevPerHCC_PartD] = CASE WHEN ISNULL( [D1].HCCTotal, 0 ) = 0 THEN 0 ELSE ( 
													ISNULL([D1].AnnualizedEstimatedValue, 0) * 1.0 ) / ( ISNULL([D1].HCCTotal, 0) * 1.0 ) END, 
								 [HCCREALIZATIONRATE_PARTD] = CASE WHEN ISNULL( [CTRS].[CHARTSCOMPLETE], 0 ) = 0 
													THEN 0 ELSE ( ISNULL([D1].HCCTotal, 0)) / ( [CTRS].[CHARTSCOMPLETE] * 1.0 ) 
													* 100 END ,
                                  [EstRevPerChartsCompleted] = CASE WHEN ISNULL( [CTRS].[CHARTSCOMPLETE], 0 ) = 0 THEN 0 
                                                                 ELSE    ( ISNULL( [c1].[AnnualizedEstimatedValue], 0 )
                                                             +   ISNULL(  [D1].AnnualizedEstimatedValue, 0 )     * 1.0 )
                                                               / ( [CTRS].[CHARTSCOMPLETE] * 1.0 ) END  ,
                                  [ProjectId] = [a0].[ProjectId] ,
                                  [ProjectDescription] = [a0].[ProjectDescription] ,
                                  [SubProjectId] = [a0].[SubProjectId] ,
                                  [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                  [ReviewName] = NULL ,
                                  [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                  [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                  [OrderFlag] = 2 ,
                                  [PopulatedDate] = @PopulatedDate
                           FROM   #ProjectSubprojectReviewList [a0]
                                  LEFT JOIN [CTE_PartD] [d1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [d1].[SubProjectId]
                                  JOIN [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [ctrs].[SubProjectId]
                                                                                             AND [ctrs].[LoadDate] = @CTRLoadDate /*B 2015-08-12 */
                                                                                             AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId /*E 2015-08-12 */
                                  LEFT JOIN [CTE_PartC] [c1] ON [a0].[SubProjectId] = [c1].[SubProjectId] /*Part C*/
								       GROUP BY 
										 [a0].SubProjectId ,
										 [a0].[ProjectId] ,
										 [a0].[ProjectDescription] ,
										 [a0].[ProjectSortOrder],
										 [a0].SubProjectDescription,
										 [ctrs].[ChartsComplete],
										 [a0].[SubProjectSortOrder] ,
										 c1.AnnualizedEstimatedValue,
										 c1.HCCTotal,
										 d1.HCCTotal,
										 d1.AnnualizedEstimatedValue
										 ) [a];
        
		
	
	
	
	
	
	
	                              
  WITH [CTE_facc]
    AS ( SELECT   [AutoProcessRunId] = [facc].[AutoProcessRunId] ,
                  [SubProjectId] = [facc].[SubProjectId] ,
                  [ReviewName] = [facc].[ReviewName] ,
                  [ChartsComplete] = COUNT([facc].[VeriskRequestId])
         FROM     [Valuation].[FilteredAuditCNCompletedChart] [facc] WITH ( NOLOCK )
         WHERE    [facc].[AutoProcessRunId] = 13
                  AND [facc].[ClientId] = 19
         GROUP BY [facc].[AutoProcessRunId] ,
                  [facc].[SubProjectId] ,
                  [facc].[ReviewName]
       ) 
     

    INSERT INTO [Valuation].[RptRetrospectiveValuationDetail] (   [ClientId] ,
                                                                  [AutoProcessRunId] ,
                                                                  [ReportType] ,
                                                                  [ReportHeader] ,
                                                                  [DOSPaymentYearHeader] ,
                                                                  [RowDisplay] ,
                                                                  [ChartsCompleted] ,
                                                                  [HCCTotal_PartC] ,
                                                                  [EstRev_PartC] ,
                                                                  [EstRevPerHCC_PartC] ,
                                                                  [HCCRealizationRate_PartC] ,
                                                                  [HCCTotal_PartD] ,
                                                                  [EstRev_PartD] ,
                                                                  [EstRevPerHCC_PartD] ,
                                                                  [HCCRealizationRate_PartD] ,
                                                                  [EstRevPerChartsCompleted] ,
                                                                  [ProjectId] ,
                                                                  [ProjectDescription] ,
                                                                  [SubProjectId] ,
                                                                  [SubProjectDescription] ,
                                                                  [ReviewName] ,
                                                                  [ProjectSortOrder] ,
                                                                  [SubProjectSortOrder] ,
                                                                  [OrderFlag] ,
                                                                  [PopulatedDate]
                                                              )
                SELECT [ClientId] = @ClientId ,
                       [AutoProcessRunId] = [a].[AutoProcessRunId] ,
                       [ReportType] = 'RetrospectiveValuationDetail' ,
                       [ReportHeader] = 'Retrospective Valuation Detail - RAPS/EDS' , -- Need to implement EDS and RAPS
                       [DOSPaymentYearHeader] = @RetrospectiveValuationDetailDOSPaymentYearHeader ,
                       [RowDisplay] = [a].[RowDisplay] ,
                       [ChartsCompleted] = [a].[ChartsCompleted] ,
                       [HCCTotal_PartC] = [a].[HCCTotal_PartC] ,
                       [EstRev_PartC] = [a].[EstRev_PartC] ,
                       [EstRevPerHCC_PartC] = [a].[EstRevPerHCC_PartC] ,
                       [HCCRealizationRate_PartC] = [a].[HCCRealizationRate_PartC] ,
                       [HCCTotal_PartD] = [a].[HCCTotal_PartD] ,
                       [EstRev_PartD] = [a].[EstRev_PartD] ,
                       [EstRevPerHCC_PartD] = [a].[EstRevPerHCC_PartD] ,
                       [HCCRealizationRate_PartD] = [a].[HCCRealizationRate_PartD] ,
                       [EstRevPerChartsCompleted] = [a].[EstRevPerChartsCompleted] ,
                       [ProjectId] = [a].[ProjectId] ,
                       [ProjectDescription] = [a].[ProjectDescription] ,
                       [SubProjectId] = [a].[SubProjectId] ,
                       [SubProjectDescription] = [a].[SubProjectDescription] ,
                       [ReviewName] = [a].[ReviewName] ,
                       [ProjectSortOrder] = [a].[ProjectSortOrder] ,
                       [SubProjectSortOrder] = [a].[SubProjectSortOrder] ,
                       [OrderFlag] = [a].[OrderFlag] ,
                       [PopulatedDate] = [a].[PopulatedDate]    
               
       
                     FROM    ( SELECT DISTINCT [AutoProcessRunId] = @AutoProcessRunId ,
                                  [RowDisplay] = 'Filtered Audit - '
                                                 + ISNULL([a0].[ReviewName], '') ,
                                  [ChartsCompleted] = [facc].[ChartsComplete] ,
                                  [HCCTotal_PartC] =CASE 
														WHEN ISNULL( [a1].[HCCTotal] , 0 ) = 0 
														  AND 
														  ISNULL( [b1].[HCCTotal] , 0 ) > 0 THEN 
														  [b1].[HCCTotal] + ISNULL( [c1].[HCCTotal] , 0 ) 
														WHEN ISNULL( [a1].[HCCTotal] , 0 ) > 0 
														  AND 
														  ISNULL( [b1].[HCCTotal] , 0 ) = 0 THEN 
														  [a1].[HCCTotal] + ISNULL( [c1].[HCCTotal] , 0 ) 
														  ELSE ROUND( ((( ISNULL( [a1].[HCCTotal] , 0 ) * 1.0 ) + ( ISNULL( [b1].[HCCTotal] , 0 ) * 1.0 ) ) / 2 )
														          + ( ISNULL( [c1].[HCCTotal] , 0 ) * 1.0 ) , 3 ) --0) 
														   END 
								, [EstRev_PartC] = ISNULL( [a1].[AnnualizedEstimatedValue] , 0 ) + ISNULL( [b1].[AnnualizedEstimatedValue] , 0 ) 
								                   + ISNULL( [c1].[AnnualizedEstimatedValue] , 0 ) , [EstRevPerHCC_PartC] = 
														CASE 
														WHEN ( (   ( ISNULL( [a1].[HCCTotal] , 0 ) + ISNULL( [b1].[HCCTotal] , 0 )  ) ) --/ 2) 
															+ ISNULL( [c1].[HCCTotal] , 0 )   ) = 0 THEN   0 
														ELSE (( ISNULL([a1].[AnnualizedEstimatedValue], 0) * 1.0 ) + ( ISNULL( [b1].[AnnualizedEstimatedValue] , 0 ) * 1.0 )
														   + ( ISNULL( [c1].[AnnualizedEstimatedValue] , 0 ) * 1.0 ) ) / ROUND( ((( ISNULL([a1].[HCCTotal], 0) * 1.0 ) 
														   + ( ISNULL([b1].[HCCTotal], 0) * 1.0 ) ) / 2 ) + ( ISNULL([c1].[HCCTotal], 0) * 1.0 ) , 0 ) 
														END 
								, [HCCRealizationRate_PartC] = 	CASE WHEN ISNULL( [facc].[ChartsComplete] , 0 ) = 0 THEN  0 
														  ELSE ( ROUND( ((( ISNULL([a1].[HCCTotal], 0) * 1.0 ) + ( ISNULL([b1].[HCCTotal], 0) * 1.0 ) ) / 2 ) 
														  + ( ISNULL([c1].[HCCTotal], 0) * 1.0 ) , 0 ) / ( [facc].[ChartsComplete] * 1.0 ) ) * 100 
														END 
								, [HCCTotal_PartD] = ISNULL([d1].[HCCTotal], 0) , [EstRev_PartD] = ISNULL( [d1].[Annualized_Estimated_Value] , 0 ) ,                                             [EstRevPerHCC_PartD] = 
														CASE 
														WHEN ISNULL( [d1].[HCCTotal] , 0 ) = 0 THEN 0 
														  ELSE ISNULL( [d1].[Annualized_Estimated_Value] , 0 ) / ( ISNULL( [d1].[HCCTotal] , 0 ) * 1.0 ) 
														END 
								 , [HCCRealizationRate_PartD] = 
														CASE 
														WHEN ISNULL( [facc].[ChartsComplete] , 0 ) = 0 THEN  0 
														  ELSE (( ISNULL([d1].[HCCTotal], 0)) / ( [facc].[ChartsComplete] * 1.0 ) ) * 100 
														END 
								, [EstRevPerChartsCompleted] = 
														CASE 
														WHEN ISNULL( [facc].[ChartsComplete] , 0 ) = 0 THEN   0 
														  ELSE ( ISNULL([a1].[AnnualizedEstimatedValue], 0) + ISNULL([b1].[AnnualizedEstimatedValue], 0) 
														  + ISNULL([d1].[EstimatedValue], 0) ) / ( [facc].[ChartsComplete] * 1.0 ) 
														END 
														,
                                  [ProjectId] = [a0].[ProjectId] ,
                                  [ProjectDescription] = [a0].[ProjectDescription] ,
                                  [SubProjectId] = [a0].[SubProjectId] ,
                                  [SubProjectDescription] = [a0].[SubProjectDescription] ,
                                  [ReviewName] = [a0].[ReviewName] ,
                                  [ProjectSortOrder] = [a0].[ProjectSortOrder] ,
                                  [SubProjectSortOrder] = [a0].[SubProjectSortOrder] ,
                                  [OrderFlag] = 3, /*Filtered Audit Level*/
                                  [PopulatedDate] = @PopulatedDate
                           FROM   #ProjectSubprojectReviewList [a0]
                                  LEFT JOIN [Valuation].[CalcFilteredAuditsTotalForCI] [a1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [a1].[SubProjectId]
                                                                                                               AND [a1].[Model_Year] = @ModelYearA
                                                                                                               AND [a0].[ReviewName] = [a1].[ReviewName]
                                                                                                               AND [a1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                               AND [a1].[ClientId] = @ClientId
                                  LEFT JOIN [Valuation].[CalcFilteredAuditsTotalForCI] [b1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [b1].[SubProjectId]
                                                                                                               AND [b1].[Model_Year] = @ModelYearB
                                                                                                               AND [a0].[ReviewName] = [b1].[ReviewName]
                                                                                                               AND [b1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                               AND [b1].[ClientId] = @ClientId
                                   LEFT JOIN [Valuation].[CalcFilteredAuditsTotalForESRD] [c1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [c1].[SubProjectId]
                                                                                                                 AND [a0].[ReviewName] = [c1].[ReviewName]
                                                                                                               AND [c1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                                 AND [c1].[ClientId] = @ClientId
                                  LEFT JOIN [Valuation].[CalcPartDFilteredAuditTotals] [d1] WITH ( NOLOCK ) ON [a0].[SubProjectId] = [d1].[SubProjectId]
                                                                                                               AND [a0].[ReviewName] = [d1].[ReviewName]
                                                                                                               AND [d1].[AutoProcessRunId] = @AutoProcessRunId
                                                                                                               AND [d1].[ClientId] = @ClientId
                                  JOIN [CTE_facc] [facc] ON [a0].[SubProjectId] = [facc].[SubProjectId]
                                                            AND [a0].[ReviewName] = [facc].[ReviewName]
                       ) [a]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '076 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuationDetail]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('077', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptRetrospectiveValuationDetail] (   [ClientId] ,
                                                                  [AutoProcessRunId] ,
                                                                  [ReportType] ,
                                                                  [ReportHeader] ,
                                                                  [DOSPaymentYearHeader] ,
                                                                  [RowDisplay] ,
                                                                  [ChartsCompleted] ,
                                                                  [HCCTotal_PartC] ,
                                                                  [EstRev_PartC] ,
                                                                  [EstRevPerHCC_PartC] ,
                                                                  [HCCRealizationRate_PartC] ,
                                                                  [HCCTotal_PartD] ,
                                                                  [EstRev_PartD] ,
                                                                  [EstRevPerHCC_PartD] ,
                                                                  [HCCRealizationRate_PartD] ,
                                                                  [EstRevPerChartsCompleted] ,
                                                                  [ProjectId] ,
                                                                  [ProjectDescription] ,
                                                                  [SubProjectId] ,
                                                                  [SubProjectDescription] ,
                                                                  [ReviewName] ,
                                                                  [ProjectSortOrder] ,
                                                                  [SubProjectSortOrder] ,
                                                                  [OrderFlag] ,
                                                                  [PopulatedDate]
                                                              )
                SELECT   [ClientId] = [rvd].[ClientId] ,
                         [AutoProcessRunId] = [rvd].[AutoProcessRunId] ,
                         [ReportType] = [rvd].[ReportType] ,
                         [ReportHeader] = [rvd].[ReportHeader] ,
                         [DOSPaymentYearHeader] = [rvd].[DOSPaymentYearHeader] ,
                         [RowDisplay] = CAST([rvd].[ProjectId] AS VARCHAR(11))
                                        + ' - ' + [rvd].[ProjectDescription] ,
                         [ChartsCompleted] = SUM([rvd].[ChartsCompleted]) ,
                         [HCCTotal_PartC] = SUM([rvd].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rvd].[EstRev_PartC]) ,
                         [EstRevPerHCC_PartC] = CASE WHEN SUM([rvd].[HCCTotal_PartC]) = 0 THEN
                                                         0
                                                     ELSE
                         ( SUM([rvd].[EstRev_PartC]) * 1.0 )
                         / ( SUM([rvd].[HCCTotal_PartC]) * 1.0 )
                                                END ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          SUM([rvd].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                         ( SUM([rvd].[HCCTotal_PartC]) * 1.0 )
                         / ( SUM([rvd].[ChartsCompleted]) * 1.0 ) * 100
                                                      END ,
                         [HCCTotal_PartD] = SUM([rvd].[HCCTotal_PartD]) ,
                         [EstRev_PartD] = SUM([rvd].[EstRev_PartD]) ,
                         [EstRevPerHCC_PartD] = CASE WHEN SUM([rvd].[HCCTotal_PartD]) = 0 THEN
                                                         0
                                                     ELSE
                         ( SUM([rvd].[EstRev_PartD]) * 1.0 )
                         / ( SUM([rvd].[HCCTotal_PartD]) * 1.0 )
                                                END ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          SUM([rvd].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                         ( SUM([rvd].[HCCTotal_PartD]) * 1.0 )
                         / ( SUM([rvd].[ChartsCompleted]) * 1.0 ) * 100
                                                      END ,
                         [EstRevPerChartsCompleted] = CASE WHEN ISNULL(
                                                                          SUM([rvd].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                         (( SUM([rvd].[EstRev_PartC])
                            + SUM([rvd].[EstRev_PartD])
                          ) * 1.0
                         )
                         / SUM([rvd].[ChartsCompleted])
                                                      END ,
                         [ProjectId] = [rvd].[ProjectId] ,
                         [ProjectDescription] = [rvd].[ProjectDescription] ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ReviewName] = NULL ,
                         [ProjectSortOrder] = [rvd].[ProjectSortOrder] ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 1 ,
                         [PopulatedDate] = [rvd].[PopulatedDate]
                FROM     [Valuation].[RptRetrospectiveValuationDetail] [rvd] WITH ( NOLOCK )
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND [rvd].[OrderFlag] = 2 /*SubProject Level*/
                         AND [rvd].[ReportType] = 'RetrospectiveValuationDetail'
                GROUP BY [rvd].[ClientId] ,
                         [rvd].[AutoProcessRunId] ,
                         [rvd].[ReportType] ,
                         [rvd].[ReportHeader] ,
                         [rvd].[DOSPaymentYearHeader] ,
                         [rvd].[ProjectId] ,
                         [rvd].[ProjectDescription] ,
                         [rvd].[ProjectSortOrder] ,
                         [rvd].[PopulatedDate]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '077 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuationDetail]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('078', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptRetrospectiveValuationDetail] (   [ClientId] ,
                                                                  [AutoProcessRunId] ,
                                                                  [ReportType] ,
                                                                  [ReportHeader] ,
                                                                  [DOSPaymentYearHeader] ,
                                                                  [RowDisplay] ,
                                                                  [ChartsCompleted] ,
                                                                  [HCCTotal_PartC] ,
                                                                  [EstRev_PartC] ,
                                                                  [EstRevPerHCC_PartC] ,
                                                                  [HCCRealizationRate_PartC] ,
                                                                  [HCCTotal_PartD] ,
                                                                  [EstRev_PartD] ,
                                                                  [EstRevPerHCC_PartD] ,
                                                                  [HCCRealizationRate_PartD] ,
                                                                  [EstRevPerChartsCompleted] ,
                                                                  [ProjectId] ,
                                                                  [ProjectDescription] ,
                                                                  [SubProjectId] ,
                                                                  [SubProjectDescription] ,
                                                                  [ReviewName] ,
                                                                  [ProjectSortOrder] ,
                                                                  [SubProjectSortOrder] ,
                                                                  [OrderFlag] ,
                                                                  [PopulatedDate]
                                                              )
                SELECT   [ClientId] = [rvd].[ClientId] ,
                         [AutoProcessRunId] = [rvd].[AutoProcessRunId] ,
                         [ReportType] = [rvd].[ReportType] ,
                         [ReportHeader] = [rvd].[ReportHeader] ,
                         [DOSPaymentYearHeader] = [rvd].[DOSPaymentYearHeader] ,
                         [RowDisplay] = 'Total' ,
                         [ChartsCompleted] = SUM([rvd].[ChartsCompleted]) ,
                         [HCCTotal_PartC] = SUM([rvd].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rvd].[EstRev_PartC]) ,
                         [EstRevPerHCC_PartC] = CASE WHEN SUM([rvd].[HCCTotal_PartC]) = 0 THEN
                                                         0
                                                     ELSE
                         ( SUM([rvd].[EstRev_PartC]) * 1.0 )
                         / ( SUM([rvd].[HCCTotal_PartC]) * 1.0 )
                                                END ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          SUM([rvd].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                         ( SUM([rvd].[HCCTotal_PartC]) * 1.0 )
                         / ( SUM([rvd].[ChartsCompleted]) * 1.0 ) * 100
                                                      END ,
                         [HCCTotal_PartD] = SUM([rvd].[HCCTotal_PartD]) ,
                         [EstRev_PartD] = SUM([rvd].[EstRev_PartD]) ,
                         [EstRevPerHCC_PartD] = CASE WHEN SUM([rvd].[HCCTotal_PartD]) = 0 THEN
                                                         0
                                                     ELSE
                         ( SUM([rvd].[EstRev_PartD]) * 1.0 )
                         / ( SUM([rvd].[HCCTotal_PartD]) * 1.0 )
                                                END ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          SUM([rvd].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                         ( SUM([rvd].[HCCTotal_PartD]) * 1.0 )
                         / ( SUM([rvd].[ChartsCompleted]) * 1.0 ) * 100
                                                      END ,
                         [EstRevPerChartsCompleted] = CASE WHEN ISNULL(
                                                                          SUM([rvd].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                         (( SUM([rvd].[EstRev_PartC])
                            + SUM([rvd].[EstRev_PartD])
                          ) * 1.0
                         )
                         / SUM([rvd].[ChartsCompleted])
                                                      END ,
                         [ProjectId] = NULL ,
                         [ProjectDescription] = NULL ,
                         [SubProjectId] = NULL ,
                         [SubProjectDescription] = NULL ,
                         [ReviewName] = NULL ,
                         [ProjectSortOrder] = NULL ,
                         [SubProjectSortOrder] = NULL ,
                         [OrderFlag] = 0 ,
                         [PopulatedDate] = [rvd].[PopulatedDate]
                FROM     [Valuation].[RptRetrospectiveValuationDetail] [rvd] WITH ( NOLOCK )
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND [rvd].[OrderFlag] = 1
                         AND [rvd].[ReportType] = 'RetrospectiveValuationDetail'
                GROUP BY [rvd].[ClientId] ,
                         [rvd].[AutoProcessRunId] ,
                         [rvd].[ReportType] ,
                         [rvd].[ReportHeader] ,
                         [rvd].[DOSPaymentYearHeader] ,
                         [rvd].[PopulatedDate]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '078 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuationDetail]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E Add data to RptRetrospectiveValuationDetail */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('079', 0, 1) WITH NOWAIT
        END

    /*B Add Data to RptSummaryTotal */

    DELETE [m]
    FROM  [Valuation].[RptSummaryTotalUnique] [m]
    WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
          AND [m].[ClientId] = @ClientId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('080', 0, 1) WITH NOWAIT
        END

        --/**/
        ;
    WITH [CTE_ctrs]
    AS ( SELECT   [ClientId] = @ClientId ,
                  [ClientCodingCompleteDate] = MAX(CAST([ctrs].[ClientCodingCompleteDate] AS DATE)) ,
                  -- TFS 45734 Changed Def. of Valuation Delivered
                  [ValuationDelivered] = @DeliveredDate ,
                  [ProjectCompletion] = CASE WHEN ISNULL(
                                                            SUM([ctrs].[ChartsRequested]) ,
                                                            0
                                                        ) = 0 THEN 0
                                             ELSE
                  ( SUM([ctrs].[ChartsComplete])
                    / ( SUM([ctrs].[ChartsRequested]) * 1.0 )
                  ) * 100
                                        END ,
                  [ChartsCompleted] = SUM([ctrs].[ChartsComplete]) ,
                  [ChartsRequested] = SUM([ctrs].[ChartsRequested])
         FROM     [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK )
         WHERE    [ctrs].[LoadDate] = @CTRLoadDate
                  AND [ctrs].[ClientId] = @ClientId
                  AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId
                  AND [ctrs].[SubProjectId] IN (   SELECT [pl].[SubProjectId]
                                                   FROM   #ProjectSubprojectReviewList [pl]
                                               )
         GROUP BY [ctrs].[LoadDate]
       )
    INSERT INTO [Valuation].[RptSummaryTotalUnique] (   [ClientId] ,
                                                        [AutoProcessRunId] ,
                                                        [ReportHeader] ,
                                                        [RowDisplay] ,
                                                        [CodingThrough] ,
                                                        [ValuationDelivered] ,
                                                        [ProjectCompletion] ,
                                                        [ChartsCompleted] ,
                                                        [HCCTotal_PartC] ,
                                                        [EstRev_PartC] ,
                                                        [HCCRealizationRate_PartC] ,
                                                        [EstRevPerChart_PartC] ,
                                                        [EstRevPerHCC_PartC] ,
                                                        [HCCTotal_PartD] ,
                                                        [EstRev_PartD] ,
                                                        [HCCRealizationRate_PartD] ,
                                                        [EstRevPerChart_PartD] ,
                                                        [EstRevPerHCC_PartD] ,
                                                        [TotalEstRev] ,
                                                        [TotalEstRevPerChart] ,
                                                        [Notes] ,
                                                        [SummaryYear] ,
                                                        [ChartsRequested] ,
                                                        [IsSummary] ,
                                                        [PopulatedDate] ,
                                                        [ReportBDate] ,
                                                        [ReportEDate] ,
                                                        [Grouping] ,
                                                        [GroupingOrder]
                                                    )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [ReportHeader] = 'Year Over Year' ,
                         [RowDisplay] = @YearToYearSummaryRowDisplay ,
                         [ClientCodingCompleteDate] = MAX(CAST([ctrs].[ClientCodingCompleteDate] AS DATE)) ,
                         [ValuationDelivered] = [ctrs].[ValuationDelivered] ,
                         [ProjectCompletion] = [ctrs].[ProjectCompletion] ,
                         [ChartsCompleted] = [ctrs].[ChartsCompleted] ,
                         [HCCTotal_PartC] = SUM([rvd].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rvd].[EstRev_PartC]) ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          [ctrs].[ChartsCompleted] ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         ( SUM([rvd].[HCCTotal_PartC])
                                                                           * 1.0
                                                                         )
                                                                         / ( [ctrs].[ChartsCompleted]
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartC] = CASE WHEN ISNULL(
                                                                      SUM([rvd].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rvd].[EstRev_PartC])
                                                                     / ( SUM([rvd].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartC] = CASE WHEN ISNULL(
                                                                    SUM([rvd].[HCCTotal_PartC]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rvd].[EstRev_PartC])
                                                                   / ( SUM([rvd].[HCCTotal_PartC])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [HCCTotal_PartD] = ISNULL(
                                                      SUM([rvd].[HCCTotal_PartD]) ,
                                                      0
                                                  ) ,
                         [EstRev_PartD] = ISNULL(SUM([rvd].[EstRev_PartD]), 0) ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          SUM([ctrs].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         SUM([rvd].[HCCTotal_PartD])
                                                                         / ( [ctrs].[ChartsCompleted]
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartD] = CASE WHEN ISNULL(
                                                                      SUM([rvd].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rvd].[EstRev_PartD])
                                                                     / ( SUM([rvd].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartD] = CASE WHEN ISNULL(
                                                                    SUM([rvd].[HCCTotal_PartD]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rvd].[EstRev_PartD])
                                                                   / ( SUM([rvd].[HCCTotal_PartD])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [TotalEstRev] = ISNULL(SUM([rvd].[EstRev_PartC]), 0)
                                         + ISNULL(SUM([rvd].[EstRev_PartD]), 0) ,
                         [TotalEstRevPerChart] = CASE WHEN SUM([rvd].[ChartsCompleted]) = 0 THEN
                                                          0
                                                      ELSE
                                                          ISNULL(
                                                                    ( ISNULL(
                                                                                SUM([rvd].[EstRev_PartC]) ,
                                                                                0
                                                                            )
                                                                      + ISNULL(
                                                                                  SUM([rvd].[EstRev_PartD]) ,
                                                                                  0
                                                                              )
                                                                    )
                                                                    / SUM([rvd].[ChartsCompleted]) ,
                                                                    0
                                                                )
                                                 END ,
                         [Notes] = NULL ,
                         [SummaryYear] = 0 ,
                         [ChartsRequested] = [ctrs].[ChartsRequested] ,
                         [IsSummary] = 0 ,
                         [PopulatedDate] = @PopulatedDate ,
                         [ReportBDate] = CAST(GETDATE() AS DATE) ,
                         [ReportEDate] = NULL ,
                         [Grouping] = [pl].[ProjectYear] ,
                         [GroupingOrder] = 0
                FROM     [Valuation].[RptRetrospectiveValuationDetail] [rvd] WITH ( NOLOCK )
                         LEFT JOIN [CTE_ctrs] [ctrs] ON [rvd].[ClientId] = [ctrs].[ClientId]
                         JOIN [Valuation].[ConfigProjectIdList] [pl] WITH ( NOLOCK ) ON [rvd].[ClientId] = [pl].[ClientId]
                                                                                        AND [rvd].[ProjectId] = [pl].[ProjectId]
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND [pl].[ActiveBDate] <= GETDATE()
                         AND ISNULL(
                                       [pl].[ActiveEDate] ,
                                       DATEADD(dd, 1, GETDATE())
                                   ) >= GETDATE()
                         AND [rvd].[OrderFlag] = 2 --1
                GROUP BY [ctrs].[ValuationDelivered] ,
                         [ctrs].[ProjectCompletion] ,
                         [ctrs].[ChartsCompleted] ,
                         [ctrs].[ChartsRequested] ,
                         [pl].[ProjectYear]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '080 - Notice: Zero rows loaded to [Valuation].[RptSummaryTotalUnique]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('081', 0, 1) WITH NOWAIT
        END

    DELETE [m]
    FROM  [Valuation].[RptSummaryTotal] [m]
    WHERE [m].[AutoProcessRunId] = @AutoProcessRunId
          AND [m].[ClientId] = @ClientId

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('082', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [HCCTotal_PartD] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [TotalEstRev] ,
                                                  [TotalEstRevPerChart] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  [ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT [ClientId] = [m].[ClientId] ,
                       [AutoProcessRunId] = @AutoProcessRunId ,
                       [InitialAutoProcessRunId] = [m].[AutoProcessRunId] ,
                       [ReportHeader] = CASE WHEN [m].[IsSummary] = 1 THEN
                                                 'Summary Year Over Year'
                                             ELSE 'Summary Year To Date'
                                        END ,
                       [RowDisplay] = [m].[RowDisplay] ,
                       [CodingThrough] = [m].[CodingThrough] ,
                       [ValuationDelivered] = [m].[ValuationDelivered] ,
                       [ProjectCompletion] = [m].[ProjectCompletion] ,
                       [ChartsCompleted] = [m].[ChartsCompleted] ,
                       [HCCTotal_PartC] = [m].[HCCTotal_PartC] ,
                       [EstRev_PartC] = [m].[EstRev_PartC] ,
                       [HCCRealizationRate_PartC] = [m].[HCCRealizationRate_PartC] ,
                       [EstRevPerChart_PartC] = [m].[EstRevPerChart_PartC] ,
                       [EstRevPerHCC_PartC] = [m].[EstRevPerHCC_PartC] ,
                       [HCCTotal_PartD] = [m].[HCCTotal_PartD] ,
                       [EstRev_PartD] = [m].[EstRev_PartD] ,
                       [HCCRealizationRate_PartD] = [m].[HCCRealizationRate_PartD] ,
                       [EstRevPerChart_PartD] = [m].[EstRevPerChart_PartD] ,
                       [EstRevPerHCC_PartD] = [m].[EstRevPerHCC_PartD] ,
                       [TotalEstRev] = [m].[TotalEstRev] ,
                       [TotalEstRevPerChart] = [m].[TotalEstRevPerChart] ,
                       [Notes] = CASE WHEN [m].[Notes] = '0' THEN ''
                                      ELSE [m].[Notes]
                                 END ,
                       [SummaryYear] = [m].[SummaryYear] ,
                       [ChartsRequested] = [m].[ChartsRequested] ,
                       [IsSummary] = [m].[IsSummary] ,
                       [PopulatedDate] = [m].[PopulatedDate] ,
                       [Grouping] = [m].[Grouping] , ---????LEFT([m].[RowDisplay], 4) -- 
                       [GroupingOrder] = [m].[GroupingOrder]
                FROM   [Valuation].[RptSummaryTotalUnique] [m] WITH ( NOLOCK )
                WHERE  [m].[ReportBDate] <= CAST(GETDATE() AS DATE)
                       AND ISNULL([m].[ReportEDate], DATEADD(dd, 1, GETDATE())) >= GETDATE()
                       AND [m].[ClientId] = @ClientId

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '082 - Notice: Zero rows loaded to [Valuation].[RptSummaryTotal]| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    /*E Add Data to RptSummaryTotal */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('082.1', 0, 1) WITH NOWAIT
        END

    /*B Add Total Data to RptSummaryTotal */

    INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [HCCTotal_PartD] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [TotalEstRev] ,
                                                  [TotalEstRevPerChart] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  [ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT   [ClientId] = [m].[ClientId] ,
                         [AutoProcessRunId] = [m].[AutoProcessRunId] ,
                         [InitialAutoProcessRunId] = MAX([m].[InitialAutoProcessRunId]) ,
                         [ReportHeader] = [m].[ReportHeader] ,
                         [RowDisplay] = [m].[Grouping] + ' - Project Totals' ,
                         [CodingThrough] = MAX([m].[CodingThrough]) ,
                         [ValuationDelivered] = MAX([m].[ValuationDelivered]) ,
                         [ProjectCompletion] = NULL ,
                         [ChartsCompleted] = MAX([m].[ChartsCompleted]) ,
                         [HCCTotal_PartC] = SUM([m].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([m].[EstRev_PartC]) ,
                         [HCCRealizationRate_PartC] = SUM([m].[HCCRealizationRate_PartC]) ,
                         [EstRevPerChart_PartC] = SUM([m].[EstRevPerChart_PartC]) ,
                         [EstRevPerHCC_PartC] = CASE WHEN ISNULL(
                                                                    SUM([m].[HCCTotal_PartC]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([m].[EstRev_PartC])
                                                                   / ( SUM([m].[HCCTotal_PartC])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [HCCTotal_PartD] = SUM([m].[HCCTotal_PartD]) ,
                         [EstRev_PartD] = SUM([m].[EstRev_PartD]) ,
                         [HCCRealizationRate_PartD] = SUM([m].[HCCRealizationRate_PartD]) ,
                         [EstRevPerChart_PartD] = SUM([m].[EstRevPerChart_PartD]) ,
                         [EstRevPerHCC_PartD] = CASE WHEN ISNULL(
                                                                    SUM([m].[HCCTotal_PartD]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([m].[EstRev_PartD])
                                                                   / ( SUM([m].[HCCTotal_PartD])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [TotalEstRev] = SUM([m].[TotalEstRev]) ,
                         [TotalEstRevPerChart] = SUM([m].[TotalEstRevPerChart]) ,
                         [Notes] = '' ,
                         [SummaryYear] = [m].[SummaryYear] ,
                         [ChartsRequested] = SUM([m].[ChartsRequested]) ,
                         [IsSummary] = [m].[IsSummary] ,
                         [PopulatedDate] = GETDATE() ,
                         [Grouping] = [m].[Grouping] ,
                         [GroupingOrder] = 1
                FROM     [Valuation].[RptSummaryTotal] [m]
                WHERE    [m].[AutoProcessRunId] = @AutoProcessRunId
                         AND [m].[ClientId] = @ClientId
                         AND [m].[IsSummary] = 1
                GROUP BY [m].[ClientId] ,
                         [m].[AutoProcessRunId] ,
                         [m].[ReportHeader] ,
                         [m].[SummaryYear] ,
                         [m].[IsSummary] ,
                         [m].[Grouping]

    /*E Add Total Data to RptSummaryTotal */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('083', 0, 1) WITH NOWAIT
        END

    /*B Add Data to [Valuation].[RptPaymentDetail] for Filtered Audit Summary */

    DELETE [rvd]
    FROM  [Valuation].[RptRetrospectiveValuationDetail] [rvd]
    WHERE [rvd].[AutoProcessRunId] = @AutoProcessRunId
          AND [rvd].[ClientId] = @ClientId
          AND [rvd].[ReportType] = 'FilteredAuditSummary'

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('084', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptRetrospectiveValuationDetail] (   [ClientId] ,
                                                                  [AutoProcessRunId] ,
                                                                  [ReportType] ,
                                                                  [ReportHeader] ,
                                                                  [DOSPaymentYearHeader] ,
                                                                  [RowDisplay] ,
                                                                  [ChartsCompleted] ,
                                                                  [HCCTotal_PartC] ,
                                                                  [EstRev_PartC] ,
                                                                  [EstRevPerHCC_PartC] ,
                                                                  [HCCRealizationRate_PartC] ,
                                                                  [HCCTotal_PartD] ,
                                                                  [EstRev_PartD] ,
                                                                  [EstRevPerHCC_PartD] ,
                                                                  [HCCRealizationRate_PartD] ,
                                                                  [EstRevPerChartsCompleted] ,
                                                                  [ProjectId] ,
                                                                  [ProjectDescription] ,
                                                                  [SubProjectId] ,
                                                                  [SubProjectDescription] ,
                                                                  [ReviewName] ,
                                                                  [ProjectSortOrder] ,
                                                                  [SubProjectSortOrder] ,
                                                                  [OrderFlag] ,
                                                                  [PopulatedDate]
                                                              )
                SELECT   [ClientId] = [rvd].[ClientId] ,
                         [AutoProcessRunId] = [rvd].[AutoProcessRunId] ,
                         [ReportType] = 'FilteredAuditSummary' ,
                         [ReportHeader] = 'Filtered Audit Summary' ,
                         [DOSPaymentYearHeader] = [rvd].[DOSPaymentYearHeader] ,
                         [RowDisplay] = [rvd].[RowDisplay] ,
                         [ChartsCompleted] = SUM([rvd].[ChartsCompleted]) ,
                         [HCCTotal_PartC] = SUM([rvd].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rvd].[EstRev_PartC]) ,
                         [EstRevPerHCC_PartC] = CASE WHEN SUM([rvd].[HCCTotal_PartC]) = 0 THEN
                                                         0
                                                     ELSE
                                                         SUM([rvd].[EstRev_PartC])
                                                         / ( SUM([rvd].[HCCTotal_PartC])
                                                             * 1.0
                                                           )
                                                END ,
                         [HCCRealizationRate_PartC] = CASE WHEN SUM([rvd].[ChartsCompleted]) = 0 THEN
                                                               0
                                                           ELSE
                                                               SUM([rvd].[HCCTotal_PartC])
                                                               / ( SUM([rvd].[ChartsCompleted])
                                                                   * 1.0
                                                                 )
                                                               * 100
                                                      END ,
                         [HCCTotal_PartD] = SUM([rvd].[HCCTotal_PartD]) ,
                         [EstRev_PartD] = SUM([rvd].[EstRev_PartD]) ,
                         [EstRevPerHCC_PartD] = CASE WHEN SUM([rvd].[HCCTotal_PartD]) = 0 THEN
                                                         0
                                                     ELSE
                                                         SUM([rvd].[EstRev_PartD])
                                                         / ( SUM([rvd].[HCCTotal_PartD])
                                                             * 1.0
                                                           )
                                                END ,
                         [HCCRealizationRate_PartD] = CASE WHEN SUM([rvd].[ChartsCompleted]) = 0 THEN
                                                               0
                                                           ELSE
                                                               SUM([rvd].[HCCTotal_PartD])
                                                               / ( SUM([rvd].[ChartsCompleted])
                                                                   * 1.0
                                                                 )
                                                               * 100
                                                      END ,
                         [EstRevPerChartsCompleted] = CASE WHEN SUM([rvd].[ChartsCompleted]) = 0 THEN
                                                               0
                                                           ELSE
                         (( ISNULL(SUM([rvd].[EstRev_PartC]), 0) * 1.0 )
                          + ( ISNULL(SUM([rvd].[EstRev_PartD]), 0) * 1.0 )
                         )
                         / ( SUM([rvd].[ChartsCompleted]) * 1.0 )
                                                      END ,
                         [ProjectId] = NULL ,             --[rvd].[ProjectId]
                         [ProjectDescription] = NULL ,    --[rvd].[ProjectDescription]
                         [SubProjectId] = NULL ,          --[rvd].[SubProjectId]
                         [SubProjectDescription] = NULL , --[rvd].[SubProjectDescription]
                         [ReviewName] = [rvd].[ReviewName] ,
                         [ProjectSortOrder] = NULL ,      --[rvd].[ProjectSortOrder]
                         [SubProjectSortOrder] = NULL ,   --[rvd].[SubProjectSortOrder]
                         [OrderFlag] = [rvd].[OrderFlag] ,
                         [PopulatedDate] = [rvd].[PopulatedDate]
                FROM     [Valuation].[RptRetrospectiveValuationDetail] [rvd] WITH ( NOLOCK )
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND [rvd].[ReportType] = 'RetrospectiveValuationDetail'
                         AND [rvd].[OrderFlag] = 3
                GROUP BY [rvd].[ClientId] ,
                         [rvd].[AutoProcessRunId] ,
                         [rvd].[DOSPaymentYearHeader] ,
                         [rvd].[RowDisplay] ,
                         [rvd].[ReviewName] ,
                         [rvd].[OrderFlag] ,
                         [rvd].[PopulatedDate]

    IF @@ROWCOUNT = 0
        BEGIN
            SET @Msg = ISNULL(@Msg, '')
                       + '084 - Notice: Zero rows loaded to [Valuation].[RptRetrospectiveValuationDetail] for FilteredAuditSummary| '
        --RAISERROR(@Msg, 16, 1)
        --SET @Msg = NULL
        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('085', 0, 1) WITH NOWAIT
        END

    /*E Add Data to [Valuation].[RptPaymentDetail] for Filtered Audit Summary */

    /*B Add Data to [Valuation].[RptPaymentDetail] for 'Current Week Totals By Rec Chart' */

    DELETE [rst]
    FROM  [Valuation].[RptSummaryTotal] [rst]
    WHERE [rst].[AutoProcessRunId] = @AutoProcessRunId
          AND [rst].[ClientId] = @ClientId
          AND [rst].[ReportHeader] = 'Current Week Totals By Rec Chart'

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('086', 0, 1) WITH NOWAIT
        END
        --
        /**/;
    WITH [CTE_ctrs]
    AS ( SELECT   [ClientId] = @ClientId ,
                  [Grouping] = LEFT([cpl].[RecommendedBy], 10) ,
                  [ClientCodingCompleteDate] = MAX(CAST([ctrs].[ClientCodingCompleteDate] AS DATE)) ,
                  [ValuationDelivered] = @DeliveredDate ,
                  [ProjectCompletion] = CASE WHEN ISNULL(
                                                            SUM([ctrs].[ChartsRequested]) ,
                                                            0
                                                        ) = 0 THEN 0
                                             ELSE
                  ( SUM([ctrs].[ChartsComplete])
                    / ( SUM([ctrs].[ChartsRequested]) * 1.0 )
                  ) * 100
                                        END ,
                  [ChartsCompleted] = SUM([ctrs].[ChartsComplete]) ,
                  [ChartsRequested] = SUM([ctrs].[ChartsRequested])
         FROM     [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK )
                  LEFT JOIN [Valuation].[ConfigProjectIdList] [cpl] WITH ( NOLOCK ) ON [ctrs].[ClientId] = [cpl].[ClientId]
                                                                                       AND [ctrs].[ProjectId] = [cpl].[ProjectId]
         WHERE    [ctrs].[LoadDate] = @CTRLoadDate
                  AND [ctrs].[ClientId] = @ClientId
                  AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId
                  AND [ctrs].[ProjectId] IN (   SELECT [pl].[ProjectId]
                                                FROM   #ProjectSubprojectReviewList [pl]
                                            )
         GROUP BY LEFT([cpl].[RecommendedBy], 10)
       )
    --
    INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [HCCTotal_PartD] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [TotalEstRev] ,
                                                  [TotalEstRevPerChart] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  [ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [InitialAutoProcessRunId] = @AutoProcessRunId ,
                         [ReportHeader] = 'Current Week Totals By Rec Chart' ,
                         [RowDisplay] = 'Total '
                                        + ISNULL([pl].[RecommendedBy], '')
                                        + ' Recommended Charts' ,
                         [CodingThrough] = '1900-01-01' ,
                         [ValuationDelivered] = @DeliveredDate ,
                         [ProjectCompletion] = NULL ,
                         [ChartsCompleted] = [ctrs].[ChartsCompleted] ,
                         [HCCTotal_PartC] = SUM([rvd].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rvd].[EstRev_PartC]) ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          [ctrs].[ChartsCompleted] ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         ( SUM([rvd].[HCCTotal_PartC])
                                                                           * 1.0
                                                                         )
                                                                         / ( [ctrs].[ChartsCompleted]
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartC] = CASE WHEN ISNULL(
                                                                      SUM([rvd].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rvd].[EstRev_PartC])
                                                                     / ( SUM([rvd].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartC] = CASE WHEN ISNULL(
                                                                    SUM([rvd].[HCCTotal_PartC]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rvd].[EstRev_PartC])
                                                                   / ( SUM([rvd].[HCCTotal_PartC])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [HCCTotal_PartD] = ISNULL(
                                                      SUM([rvd].[HCCTotal_PartD]) ,
                                                      0
                                                  ) ,
                         [EstRev_PartD] = ISNULL(SUM([rvd].[EstRev_PartD]), 0) ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          SUM([ctrs].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         SUM([rvd].[HCCTotal_PartD])
                                                                         / ( [ctrs].[ChartsCompleted]
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartD] = CASE WHEN ISNULL(
                                                                      SUM([rvd].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rvd].[EstRev_PartD])
                                                                     / ( SUM([rvd].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartD] = CASE WHEN ISNULL(
                                                                    SUM([rvd].[HCCTotal_PartD]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rvd].[EstRev_PartD])
                                                                   / ( SUM([rvd].[HCCTotal_PartD])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [TotalEstRev] = ISNULL(SUM([rvd].[EstRev_PartC]), 0)
                                         + ISNULL(SUM([rvd].[EstRev_PartD]), 0) ,
                         [TotalEstRevPerChart] = CASE WHEN SUM([rvd].[ChartsCompleted]) = 0 THEN
                                                          0
                                                      ELSE
                                                          ISNULL(
                                                                    ( ISNULL(
                                                                                SUM([rvd].[EstRev_PartC]) ,
                                                                                0
                                                                            )
                                                                      + ISNULL(
                                                                                  SUM([rvd].[EstRev_PartD]) ,
                                                                                  0
                                                                              )
                                                                    )
                                                                    / SUM([rvd].[ChartsCompleted]) ,
                                                                    0
                                                                )
                                                 END ,
                         [Notes] = NULL ,
                         [SummaryYear] = 0 ,
                         [ChartsRequested] = [ctrs].[ChartsRequested] ,
                         [IsSummary] = 0 ,
                         [PopulatedDate] = @PopulatedDate ,
                         [Grouping] = LEFT(ISNULL([pl].[RecommendedBy], ''), 10) ,
                         [GroupingOrder] = 0
                FROM     [Valuation].[RptRetrospectiveValuationDetail] [rvd] WITH ( NOLOCK )
                         JOIN [Valuation].[ConfigProjectIdList] [pl] WITH ( NOLOCK ) ON [rvd].[ClientId] = [pl].[ClientId]
                                                                                        AND [rvd].[ProjectId] = [pl].[ProjectId]
                         LEFT JOIN [CTE_ctrs] [ctrs] ON [rvd].[ClientId] = [ctrs].[ClientId]
                                                        AND [ctrs].[Grouping] = LEFT(ISNULL(
                                                                                               [pl].[RecommendedBy] ,
                                                                                               ''
                                                                                           ) ,10)
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND [pl].[ActiveBDate] <= GETDATE()
                         AND ISNULL(
                                       [pl].[ActiveEDate] ,
                                       DATEADD(dd, 1, GETDATE())
                                   ) >= GETDATE()
                         AND [rvd].[OrderFlag] = 1
                GROUP BY [ctrs].[ValuationDelivered] ,
                         [ctrs].[ProjectCompletion] ,
                         [ctrs].[ChartsCompleted] ,
                         [ctrs].[ChartsRequested] ,
                         [pl].[ProjectYear] ,
                         [pl].[RecommendedBy]
                         
                         
                         
                         
                    
                         

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('087', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [HCCTotal_PartD] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [TotalEstRev] ,
                                                  [TotalEstRevPerChart] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  [ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT   [ClientId] = [rst].[ClientId] ,
                         [AutoProcessRunId] = [rst].[AutoProcessRunId] ,
                         [InitialAutoProcessRunId] = [rst].[InitialAutoProcessRunId] ,
                         [ReportHeader] = [rst].[ReportHeader] ,
                         [RowDisplay] = 'Totals' ,
                         [CodingThrough] = [rst].[CodingThrough] ,
                         [ValuationDelivered] = [rst].[ValuationDelivered] ,
                         [ProjectCompletion] = [rst].[ProjectCompletion] ,
                         [ChartsCompleted] = SUM([rst].[ChartsCompleted]) ,
                         [HCCTotal_PartC] = SUM([rst].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rst].[EstRev_PartC]) ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          SUM([rst].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         ( SUM([rst].[HCCTotal_PartC])
                                                                           * 1.0
                                                                         )
                                                                         / ( SUM([rst].[ChartsCompleted])
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartC] = CASE WHEN ISNULL(
                                                                      SUM([rst].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rst].[EstRev_PartC])
                                                                     / ( SUM([rst].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartC] = CASE WHEN ISNULL(
                                                                    SUM([rst].[HCCTotal_PartC]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rst].[EstRev_PartC])
                                                                   / ( SUM([rst].[HCCTotal_PartC])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [HCCTotal_PartD] = SUM([rst].[HCCTotal_PartD]) ,
                         [EstRev_PartD] = SUM([rst].[EstRev_PartD]) ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          SUM([rst].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         SUM([rst].[HCCTotal_PartD])
                                                                         / ( SUM([rst].[ChartsCompleted])
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartD] = CASE WHEN ISNULL(
                                                                      SUM([rst].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rst].[EstRev_PartD])
                                                                     / ( SUM([rst].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartD] = CASE WHEN ISNULL(
                                                                    SUM([rst].[HCCTotal_PartD]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rst].[EstRev_PartD])
                                                                   / ( SUM([rst].[HCCTotal_PartD])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [TotalEstRev] = SUM([rst].[TotalEstRev]) ,
                         [TotalEstRevPerChart] = CASE WHEN SUM([rst].[ChartsCompleted]) = 0 THEN
                                                          0
                                                      ELSE
                                                          ISNULL(
                                                                    ( ISNULL(
                                                                                SUM([rst].[EstRev_PartC]) ,
                                                                                0
                                                                            )
                                                                      + ISNULL(
                                                                                  SUM([rst].[EstRev_PartD]) ,
                                                                                  0
                                                                              )
                                                                    )
                                                                    / SUM([rst].[ChartsCompleted]) ,
                                                                    0
                                                                )
                                                 END ,
                         [Notes] = NULL ,
                         [SummaryYear] = [rst].[SummaryYear] ,
                         [ChartsRequested] = SUM([rst].[ChartsRequested]) ,
                         [IsSummary] = [rst].[IsSummary] ,
                         [PopulatedDate] = [rst].[PopulatedDate] ,
                         [Grouping] = 'Total' ,
                         [GroupingOrder] = 1
                FROM     [Valuation].[RptSummaryTotal] [rst] WITH ( NOLOCK )
                WHERE    [rst].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rst].[ClientId] = @ClientId
                         AND [rst].[ReportHeader] = 'Current Week Totals By Rec Chart'
                GROUP BY [rst].[ClientId] ,
                         [rst].[AutoProcessRunId] ,
                         [rst].[InitialAutoProcessRunId] ,
                         [rst].[ReportHeader] ,
                         [rst].[CodingThrough] ,
                         [rst].[ValuationDelivered] ,
                         [rst].[ProjectCompletion] ,
                         [rst].[SummaryYear] ,
                         [rst].[IsSummary] ,
                         [rst].[PopulatedDate]
                         
                         
                         
                         
    /*Valuation By submission detail Begin */  
    
    
    
    
               
--UPDATE a 
--SET a.EstRevPerChart_A =  CASE WHEN a.ChartsCompleted = 0 THEN 0 ELSE 
--         a.EstRev_A/a.ChartsCompleted END ,
-- a.EstRevPerChart_B = CASE WHEN  a.ChartsCompleted = 0 THEN 0 ELSE 
--         a.EstRev_B/a.ChartsCompleted END
--          FROM [Valuation].[RptPaymentDetail]         a                                                               
--WHERE AutoProcessRunId = @AutoProcessRunId
--                         AND a.[ClientId] = @ClientId
--                         AND a.[ReportType] = 'Blended'
--                         AND a.[ReportSubType] = 'PaymentDetail' ;
               
    
    ---Part C --
    
    
     INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  --[TotalEstRev] ,
                                                  --[TotalEstRevPerChart] ,                                                  
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  --[ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT DISTINCT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [InitialAutoProcessRunId] = @AutoProcessRunId ,
                         [ReportHeader] = 'Valuation By Submission Detail' ,
                         [RowDisplay] = 'RAPS',
                         [CodingThrough] = '1900-01-01' ,
                         [ValuationDelivered] = @DeliveredDate ,
                         [ProjectCompletion] = NULL ,
                         [ChartsCompleted] = rvd.ChartsCompleted ,
                         [HCCTotal_PartC] = c.HCCTotal_B ,
                         [EstRev_PartC] = c.EstRev_B ,
                         [HCCRealizationRate_PartC] = c.HCCRealizationRate_B ,
                         [EstRevPerChart_PartC] = c.[EstRevPerChart_B] ,
                         [EstRevPerHCC_PartC] = c.EstRevPerHCC_B ,
                         [EstRev_PartD] = d.HCCTotal_B , 
                         [HCCRealizationRate_PartD] = d.HCCRealizationRate_B , 
                         [EstRevPerChart_PartD] = d.[EstRevPerChart_B] , 
                         [EstRevPerHCC_PartD] = d.EstRevPerHCC_B,
                         [Notes] = NULL ,
                         [SummaryYear] = 0 ,
                         --[ChartsRequested] =  rvd.ChartsCompleted ,
                         [IsSummary] = 0 ,
                         [PopulatedDate] = @PopulatedDate ,
                         [Grouping] = 'Total',
                         [GroupingOrder] = 0
               FROM     [Valuation].RptPaymentDetail [rvd] WITH ( NOLOCK )
                   LEFT JOIN [Valuation].RptPaymentDetail c ON c.AutoProcessRunId = rvd.AutoProcessRunId
                                       AND c.Part_C_D  = 'C'
                                       AND c.orderflag = 0
                   LEFT JOIN [Valuation].RptPaymentDetail d ON d.AutoProcessRunId = rvd.AutoProcessRunId
                                       AND d.Part_C_D  = 'D'
                                       AND d.orderflag = 0
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND  rvd.OrderFlag = 0;
                       
                INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  --[ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT DISTINCT  [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [InitialAutoProcessRunId] = @AutoProcessRunId ,
                         [ReportHeader] = 'Valuation By Submission Detail' ,
                         [RowDisplay] = 'EDS',
                         [CodingThrough] = '1900-01-01' ,
                         [ValuationDelivered] = @DeliveredDate ,
                         [ProjectCompletion] = NULL ,
                         [ChartsCompleted] = rvd.ChartsCompleted ,
                         [HCCTotal_PartC] = c.HCCTotal_A ,
                         [EstRev_PartC] = c.EstRev_A,
                         [HCCRealizationRate_PartC] = c.HCCRealizationRate_A ,
                         [EstRevPerChart_PartC] = c.[EstRevPerChart_A] ,
                         [EstRevPerHCC_PartC] = c.EstRevPerHCC_A ,
                         [EstRev_PartD] = d.HCCTotal_A , 
                         [HCCRealizationRate_PartD] = d.HCCRealizationRate_A , 
                         [EstRevPerChart_PartD] = d.[EstRevPerChart_A] , 
                         [EstRevPerHCC_PartD] = d.EstRevPerHCC_A,
                         [Notes] = NULL ,
                         [SummaryYear] = 0 ,
                         [IsSummary] = 0 ,
                         [PopulatedDate] = @PopulatedDate ,
                         [Grouping] = 'Total',
                         [GroupingOrder] = 0
                     FROM     [Valuation].RptPaymentDetail [rvd] WITH ( NOLOCK )
                   LEFT JOIN [Valuation].RptPaymentDetail c ON c.AutoProcessRunId = rvd.AutoProcessRunId
                                       AND c.Part_C_D  = 'C'
                                       AND c.orderflag = 0
                   LEFT JOIN [Valuation].RptPaymentDetail d ON d.AutoProcessRunId = rvd.AutoProcessRunId
                                       AND d.Part_C_D  = 'D'
                                       AND d.orderflag = 0
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND  rvd.OrderFlag = 0;
               
             /*Valuation by Submission Detail end */
                         
                         -------Part C and D END 
    
          
                         
                         
                         

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('088', 0, 1) WITH NOWAIT
        END

    /*E Add Data to [Valuation].[RptPaymentDetail] for 'Current Week Totals By Rec Chart' */

    /*B Add Data to [Valuation].[RptPaymentDetail] for 'Current Week Totals By SubGroup' */

    DELETE [rst]
    FROM  [Valuation].[RptSummaryTotal] [rst]
    WHERE [rst].[AutoProcessRunId] = @AutoProcessRunId
          AND [rst].[ClientId] = @ClientId
          AND [rst].[ReportHeader] = 'Current Week Totals By Wave'

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('089', 0, 1) WITH NOWAIT
        END

    /*B Get Distinct List of Subproject with SubGroup -Note: this should be corrected in future releases */

    DECLARE @WaveList TABLE
        (
            [ProjectId] INT ,
            [SubprojectId] INT ,
            [SubGroup] VARCHAR(128)
        )

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('090', 0, 1) WITH NOWAIT
        END

    INSERT INTO @WaveList (   [ProjectId] ,
                              [SubprojectId] ,
                              [SubGroup]
                          )
                SELECT DISTINCT [csprn].[ProjectId] ,
                       [csprn].[SubProjectId] ,
                       [csprn].[SubGroup]
                FROM   [Valuation].[ConfigSubProjectReviewName] [csprn] WITH ( NOLOCK )
                       JOIN [Valuation].[ConfigProjectIdList] [cpl] WITH ( NOLOCK ) ON [cpl].[ClientId] = [csprn].[ClientId]
                                                                                       AND [cpl].[ProjectId] = [csprn].[ProjectId]
                WHERE  [csprn].[ClientId] = @ClientId
                       AND [csprn].[SubGroup] IS NOT NULL
                       AND [csprn].[ActiveBDate] <= GETDATE()
                       AND (   [csprn].[ActiveEDate] IS NULL
                               OR [csprn].[ActiveEDate] > GETDATE()
                           )
                       AND [cpl].[ActiveBDate] <= GETDATE()
                       AND (   [cpl].[ActiveEDate] IS NULL
                               OR [cpl].[ActiveEDate] > GETDATE()
                           )
                       AND [cpl].[ClientId] = @ClientId -- additional join logic added to address Valuation Charts Completed Count issue identifed on  12/12/17  DW


    /*E Get Distinct List of Subproject with SubGroup -Note: this should be corrected in future releases */

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('091', 0, 1) WITH NOWAIT
        END
        --
        /**/;
    WITH [CTE_ctrs]
    AS ( SELECT   [ClientId] = @ClientId ,
                  [ProjectId] = [cpl].[ProjectId] ,
                  [ctrs].[SubprojectId] ,
                  [SubGroup] = [csprn].[SubGroup] ,
                  [ClientCodingCompleteDate] = MAX(CAST([ctrs].[ClientCodingCompleteDate] AS DATE)) ,
                  [ProjectCompletion] = CASE WHEN ISNULL(
                                                            SUM([ctrs].[ChartsRequested]) ,
                                                            0
                                                        ) = 0 THEN 0
                                             ELSE
                  ( SUM([ctrs].[ChartsComplete])
                    / ( SUM([ctrs].[ChartsRequested]) * 1.0 )
                  ) * 100
                                        END ,
                  [ChartsComplete] = SUM([ctrs].[ChartsComplete]) ,
                  [ChartsRequested] = SUM([ctrs].[ChartsRequested])
         FROM     [Valuation].[ValCTRSummary] [ctrs] WITH ( NOLOCK )
                  JOIN [Valuation].[ConfigProjectIdList] [cpl] WITH ( NOLOCK ) ON [ctrs].[ClientId] = [cpl].[ClientId]
                                                                                  AND [ctrs].[ProjectId] = [cpl].[ProjectId]
                  JOIN @WaveList [csprn] ON [ctrs].[ProjectId] = [csprn].[ProjectId]
                                            AND [ctrs].[SubprojectId] = [csprn].[SubprojectId]
         WHERE    [ctrs].[LoadDate] = @CTRLoadDate
                  AND [ctrs].[ClientId] = @ClientId
                  AND [ctrs].[AutoProcessRunId] = @AutoProcessRunId
                  AND [ctrs].[ProjectId] IN (   SELECT [pl].[ProjectId]
                                                FROM   #ProjectSubprojectReviewList [pl]
                                            )
                  AND [csprn].[SubGroup] IS NOT NULL
         GROUP BY [csprn].[SubGroup] ,
                  [cpl].[ProjectId] ,
                  [ctrs].[SubprojectId]
       ) ,
         [CTE_cr]
    AS ( SELECT   [ClientId] = [ctr].[ClientId] ,
                  [AutoProcessRunId] = [ctr].[AutoProcessRunId] ,
                  [SubGroup] = [csprn].[SubGroup] ,
                  [TtChartsRequested] = SUM([ctr].[ChartsRequested]) ,
                  [TtChartsVHRetrieved] = SUM([ctr].[ChartsVHRetrieved]) ,
                  [TtChartsCompleted] = SUM([ctr].[ChartsComplete])
         FROM     [Valuation].[ValCTRSummary] [ctr] WITH ( NOLOCK )
                  JOIN @WaveList [csprn] ON [ctr].[ProjectId] = [csprn].[ProjectId]
                                            AND [ctr].[SubprojectId] = [csprn].[SubprojectId]
         WHERE    [ctr].[AutoProcessRunId] = @AutoProcessRunId
                  AND [ctr].[ClientId] = @ClientId
                  AND [csprn].[SubGroup] IS NOT NULL
         GROUP BY [ctr].[ClientId] ,
                  [ctr].[AutoProcessRunId] ,
                  [csprn].[SubGroup]
       )
    INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [HCCTotal_PartD] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [TotalEstRev] ,
                                                  [TotalEstRevPerChart] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  [ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT   DISTINCT [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [InitialAutoProcessRunId] = @AutoProcessRunId ,
                         [ReportHeader] = 'Current Week Totals By Wave' ,
                         [RowDisplay] = ISNULL([cr].[SubGroup], '<?>') ,
                         [CodingThrough] = '1900-01-01' ,
                         [ValuationDelivered] = @DeliveredDate ,
                         [ProjectCompletion] = CASE WHEN ISNULL(
                                                                   [cr].[TtChartsRequested] ,
                                                                   0
                                                               ) = 0 THEN 0
                                                    ELSE
                         ( [cr].[TtChartsCompleted]
                           / ( [cr].[TtChartsRequested] * 1.0 )
                         ) * 100
                                               END ,
                         [ChartsCompleted] = [cr].[TtChartsCompleted] ,
                         [HCCTotal_PartC] = SUM([rvd].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rvd].[EstRev_PartC]) ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          [cr].[TtChartsCompleted] ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         ( SUM([rvd].[HCCTotal_PartC])
                                                                           * 1.0
                                                                         )
                                                                         / ( [cr].[TtChartsCompleted]
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartC] = CASE WHEN ISNULL(
                                                                      [cr].[TtChartsCompleted] ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rvd].[EstRev_PartC])
                                                                     / ( [cr].[TtChartsCompleted]
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartC] = CASE WHEN ISNULL(
                                                                    SUM([rvd].[HCCTotal_PartC]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rvd].[EstRev_PartC])
                                                                   / ( SUM([rvd].[HCCTotal_PartC])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [HCCTotal_PartD] = ISNULL(
                                                      SUM([rvd].[HCCTotal_PartD]) ,
                                                      0
                                                  ) ,
                         [EstRev_PartD] = ISNULL(SUM([rvd].[EstRev_PartD]), 0) ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          [cr].[TtChartsCompleted] ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         SUM([rvd].[HCCTotal_PartD])
                                                                         / ( [cr].[TtChartsCompleted]
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartD] = CASE WHEN ISNULL(
                                                                      [cr].[TtChartsCompleted] ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rvd].[EstRev_PartD])
                                                                     / ( [cr].[TtChartsCompleted]
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartD] = CASE WHEN ISNULL(
                                                                    SUM([rvd].[HCCTotal_PartD]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rvd].[EstRev_PartD])
                                                                   / ( SUM([rvd].[HCCTotal_PartD])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [TotalEstRev] = ISNULL(SUM([rvd].[EstRev_PartC]), 0)
                                         + ISNULL(SUM([rvd].[EstRev_PartD]), 0) ,
                         [TotalEstRevPerChart] = CASE WHEN [cr].[TtChartsCompleted] = 0 THEN
                                                          0
                                                      ELSE
                                                          ISNULL(
                                                                    ( ISNULL(
                                                                                SUM([rvd].[EstRev_PartC]) ,
                                                                                0
                                                                            )
                                                                      + ISNULL(
                                                                                  SUM([rvd].[EstRev_PartD]) ,
                                                                                  0
                                                                              )
                                                                    )
                                                                    / [cr].[TtChartsCompleted] ,
                                                                    0
                                                                )
                                                 END ,
                         [Notes] = NULL ,
                         [SummaryYear] = 0 ,
                         [ChartsRequested] = [cr].[TtChartsRequested] ,
                         [IsSummary] = 0 ,
                         [PopulatedDate] = @PopulatedDate ,
                         [Grouping] = 'Wave' ,
                         [GroupingOrder] = 0
                FROM     [Valuation].[RptRetrospectiveValuationDetail] [rvd] WITH ( NOLOCK )
                         JOIN [Valuation].[ConfigProjectIdList] [pl] WITH ( NOLOCK ) ON [rvd].[ClientId] = [pl].[ClientId]
                                                                                        AND [rvd].[ProjectId] = [pl].[ProjectId]
                         JOIN [CTE_ctrs] [ctrs] ON [rvd].[ClientId] = [ctrs].[ClientId]
                                                   AND [rvd].[ProjectId] = [ctrs].[ProjectId]
                                                   AND [rvd].[SubprojectId] = [ctrs].[SubprojectId]
                         JOIN [CTE_cr] [cr] ON [rvd].[ClientId] = [cr].[ClientId]
                                               AND [rvd].[AutoProcessRunId] = [cr].[AutoProcessRunId]
                                               AND [ctrs].[SubGroup] = [cr].[SubGroup]
                WHERE    [rvd].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rvd].[ClientId] = @ClientId
                         AND [pl].[ActiveBDate] <= GETDATE()
                         AND ISNULL(
                                       [pl].[ActiveEDate] ,
                                       DATEADD(dd, 1, GETDATE())
                                   ) >= GETDATE()
                         AND [rvd].[OrderFlag] = 2
                         AND [cr].[SubGroup] IS NOT NULL
                         AND [rvd].[ReportType] = 'RetrospectiveValuationDetail'
                GROUP BY [cr].[SubGroup] ,
                         [cr].[TtChartsRequested] ,
                         [cr].[TtChartsCompleted]

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('092', 0, 1) WITH NOWAIT
        END

    INSERT INTO [Valuation].[RptSummaryTotal] (   [ClientId] ,
                                                  [AutoProcessRunId] ,
                                                  [InitialAutoProcessRunId] ,
                                                  [ReportHeader] ,
                                                  [RowDisplay] ,
                                                  [CodingThrough] ,
                                                  [ValuationDelivered] ,
                                                  [ProjectCompletion] ,
                                                  [ChartsCompleted] ,
                                                  [HCCTotal_PartC] ,
                                                  [EstRev_PartC] ,
                                                  [HCCRealizationRate_PartC] ,
                                                  [EstRevPerChart_PartC] ,
                                                  [EstRevPerHCC_PartC] ,
                                                  [HCCTotal_PartD] ,
                                                  [EstRev_PartD] ,
                                                  [HCCRealizationRate_PartD] ,
                                                  [EstRevPerChart_PartD] ,
                                                  [EstRevPerHCC_PartD] ,
                                                  [TotalEstRev] ,
                                                  [TotalEstRevPerChart] ,
                                                  [Notes] ,
                                                  [SummaryYear] ,
                                                  [ChartsRequested] ,
                                                  [IsSummary] ,
                                                  [PopulatedDate] ,
                                                  [Grouping] ,
                                                  [GroupingOrder]
                                              )
                SELECT   [ClientId] = @ClientId ,
                         [AutoProcessRunId] = @AutoProcessRunId ,
                         [InitialAutoProcessRunId] = @AutoProcessRunId ,
                         [ReportHeader] = [rst].[ReportHeader] ,
                         [RowDisplay] = 'Totals' ,
                         [CodingThrough] = [rst].[CodingThrough] ,
                         [ValuationDelivered] = [rst].[ValuationDelivered] ,
                         [ProjectCompletion] = CASE WHEN ISNULL(
                                                                   SUM([rst].[ChartsRequested]) ,
                                                                   0
                                                               ) = 0 THEN 0
                                                    ELSE
                         ( SUM([rst].[ChartsCompleted])
                           / ( SUM([rst].[ChartsRequested]) * 1.0 )
                         ) * 100
                                               END ,
                         [ChartsCompleted] = SUM([rst].[ChartsCompleted]) ,
                         [HCCTotal_PartC] = SUM([rst].[HCCTotal_PartC]) ,
                         [EstRev_PartC] = SUM([rst].[EstRev_PartC]) ,
                         [HCCRealizationRate_PartC] = CASE WHEN ISNULL(
                                                                          SUM([rst].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         ( SUM([rst].[HCCTotal_PartC])
                                                                           * 1.0
                                                                         )
                                                                         / ( SUM([rst].[ChartsCompleted])
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartC] = CASE WHEN ISNULL(
                                                                      SUM([rst].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rst].[EstRev_PartC])
                                                                     / ( SUM([rst].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartC] = CASE WHEN ISNULL(
                                                                    SUM([rst].[HCCTotal_PartC]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rst].[EstRev_PartC])
                                                                   / ( SUM([rst].[HCCTotal_PartC])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [HCCTotal_PartD] = SUM([rst].[HCCTotal_PartD]) ,
                         [EstRev_PartD] = SUM([rst].[EstRev_PartD]) ,
                         [HCCRealizationRate_PartD] = CASE WHEN ISNULL(
                                                                          SUM([rst].[ChartsCompleted]) ,
                                                                          0
                                                                      ) = 0 THEN
                                                               0
                                                           ELSE
                                                               ISNULL(
                                                                         SUM([rst].[HCCTotal_PartD])
                                                                         / ( SUM([rst].[ChartsCompleted])
                                                                             * 1.0
                                                                           ) ,
                                                                         0
                                                                     ) * 100
                                                      END ,
                         [EstRevPerChart_PartD] = CASE WHEN ISNULL(
                                                                      SUM([rst].[ChartsCompleted]) ,
                                                                      0
                                                                  ) = 0 THEN 0
                                                       ELSE
                                                           ISNULL(
                                                                     SUM([rst].[EstRev_PartD])
                                                                     / ( SUM([rst].[ChartsCompleted])
                                                                         * 1.0
                                                                       ) ,
                                                                     0
                                                                 )
                                                  END ,
                         [EstRevPerHCC_PartD] = CASE WHEN ISNULL(
                                                                    SUM([rst].[HCCTotal_PartD]) ,
                                                                    0
                                                                ) = 0 THEN 0
                                                     ELSE
                                                         ISNULL(
                                                                   SUM([rst].[EstRev_PartD])
                                                                   / ( SUM([rst].[HCCTotal_PartD])
                                                                       * 1.0
                                                                     ) ,
                                                                   0
                                                               )
                                                END ,
                         [TotalEstRev] = SUM([rst].[TotalEstRev]) ,
                         [TotalEstRevPerChart] = CASE WHEN SUM([rst].[ChartsCompleted]) = 0 THEN
                                                          0
                                                      ELSE
                                                          ISNULL(
                                                                    ( ISNULL(
                                                                                SUM([rst].[EstRev_PartC]) ,
                                                                                0
                                                                            )
                                                                      + ISNULL(
                                                                                  SUM([rst].[EstRev_PartD]) ,
                                                                                  0
                                                                              )
                                                                    )
                                                                    / SUM([rst].[ChartsCompleted]) ,
                                                                    0
                                                                )
                                                 END ,
                         [Notes] = NULL ,
                         [SummaryYear] = 0 ,
                         [ChartsRequested] = SUM([rst].[ChartsRequested]) ,
                         [IsSummary] = 0 ,
                         [PopulatedDate] = [rst].[PopulatedDate] ,
                         [Grouping] = 'Total' ,
                         [GroupingOrder] = 1
                FROM     [Valuation].[RptSummaryTotal] [rst] WITH ( NOLOCK )
                WHERE    [rst].[AutoProcessRunId] = @AutoProcessRunId
                         AND [rst].[ClientId] = @ClientId
                         AND [rst].[ReportHeader] = 'Current Week Totals By Wave'
                GROUP BY [rst].[ClientId] ,
                         [rst].[AutoProcessRunId] ,
                         [rst].[ReportHeader] ,
                         [rst].[CodingThrough] ,
                         [rst].[ValuationDelivered] ,
                         [rst].[PopulatedDate]


    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            SET @ET = GETDATE()
            RAISERROR('093', 0, 1) WITH NOWAIT
        END

    /*E Add Data to [Valuation].[RptPaymentDetail] for 'Current Week Totals By SubGroup' */

    IF @Msg IS NOT NULL
        BEGIN
            SET @Msg = LEFT('Info: ' + @Msg, 2048)
            RAISERROR(@Msg, 16, 1)

        END

    IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10))
                  + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114)
                  + ' | ' + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('094', 0, 1) WITH NOWAIT
            PRINT 'Total ET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10))
                  + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' | '
                  + CONVERT(CHAR(23), GETDATE(), 121)
            RAISERROR('Done.|', 0, 1) WITH NOWAIT
        END