CREATE PROC [rev].[spr_Summary_RskAdj_RefreshPY]
(
    @LoadDateTime DATETIME = NULL,
    @FullRefresh BIT = 0,
    @YearRefresh INT = NULL,
    @Debug BIT = 0
)
AS /************************************************************************************************* 
* Name			:	rev.spr_Summary_RskAdj_RefreshPY												*
* Type 			:	Stored Procedure																*
* Author       	:	Mitch Casto																		*
* Date			:	2016-03-21																		*
* Version			:																				*
* Description		: Create list of Refresh Payment Year to be used by stored procs in the summary *
*						process																		*
*					Note: This stp is an adaptation from Summary 1.0 and will need further work to	*
*					optimize the sql.																*
*																									*
* Version History :																					*
* =================================================================================================	*
* Author			Date		Version#    TFS Ticket#		Description								*
* -----------------	----------  --------    -----------		------------							*
* Mitch Casto		2016-03-21	1.0			52224													*
* Mitch Casto		2016-05-18	1.1			53367			Move results to permanent table			*
*															Add @ManualRun to remove requirment for	*
*															table ownership for Truncation when run	*
*															manually								*
																									*
* Mitch Casto		2017-03-27	1.2			63302/US63790	Removed @ManualRun process and replaced *
*															with parameterized delete batch			*
*															(Section 002 to 005)					*
*																									*
* D.Waddell			10/29/2019	1.3			RE-6981			Set Transaction Isolation Level Read to *
*                                                           Uncommitted     
*Madhuri Suri       6/4/2021    1.4         RRI 1140        Update Adjustment Reason 25 logic 
*Anand				11/15/2021	1.5			RRI-1555		Update Final Cut off date to 1 year. 
*****************************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;
        DECLARE @ET DATETIME;
        DECLARE @MasterET DATETIME;
        DECLARE @ProcessNameIn VARCHAR(128);
        SET @ET = GETDATE();
        SET @MasterET = @ET;
        SET @ProcessNameIn = OBJECT_NAME(@@PROCID);
        EXEC [dbo].[PerfLogMonitor] @Section = '000',
                                    @ProcessName = @ProcessNameIn,
                                    @ET = @ET,
                                    @MasterET = @MasterET,
                                    @ET_Out = @ET OUT,
                                    @TableOutput = 0,
                                    @End = 0;
		 END;


    DECLARE @Payment_year INT = YEAR(GETDATE());
    DECLARE @Thru_Date DATE;
    DECLARE @From_Date DATE;
    DECLARE @Lagged_Thru_Date DATE;
    DECLARE @Lagged_From_Date DATE;
    SET @LoadDateTime = ISNULL(@LoadDateTime, GETDATE());


    SET @From_Date = '1/1/' + CAST(@Payment_year - 1 AS VARCHAR);
    SET @Thru_Date = '12/31/' + CAST(@Payment_year - 1 AS VARCHAR);
    SET @Lagged_From_Date = '7/1/' + CAST(@Payment_year - 2 AS VARCHAR);
    SET @Lagged_Thru_Date = '6/30/' + CAST(@Payment_year - 1 AS VARCHAR);

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '001',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /*B Truncate Or Delete rows in rev.tbl_Summary_RskAdj_RefreshPY */

    DELETE [m1]
    FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [m1];

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '002',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    IF (@FullRefresh = 1)
    BEGIN

       INSERT INTO [rev].[tbl_Summary_RskAdj_RefreshPY]
        (
            [Payment_Year],
            [From_Date],
            [Thru_Date],
            [Lagged_From_Date],
            [Lagged_Thru_Date],
            [LoadDateTime]
        )
        VALUES
        (
			 @Payment_year - 1,
			'01/01/' + CAST(@Payment_year - 2 AS CHAR(4)),
		    '12/31/' + CAST(@Payment_year - 2 AS CHAR(4)), 
			'07/01/' + CAST(@Payment_year - 3 AS CHAR(4)),
		    '06/30/' + CAST(@Payment_year - 2 AS CHAR(4)), 
			 @LoadDateTime
		),
		(
			@Payment_year, 
			@From_Date,
			@Thru_Date,
			@Lagged_From_Date,
			@Lagged_Thru_Date,
			@LoadDateTime
		),
        (
			@Payment_year + 1, 
			'01/01/' + CAST(@Payment_year AS CHAR(4)),
			'12/31/' + CAST(@Payment_year AS CHAR(4)),
            '07/01/' + CAST(@Payment_year - 1 AS CHAR(4)),
			'06/30/' + CAST(@Payment_year AS CHAR(4)),
			@LoadDateTime
		);

		IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '003',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;




    END;
    ELSE IF (ISNUMERIC(@YearRefresh) = 1 AND @YearRefresh IS NOT NULL)
    BEGIN

        INSERT INTO [rev].[tbl_Summary_RskAdj_RefreshPY]
        (
            [Payment_Year],
            [From_Date],
            [Thru_Date],
            [Lagged_From_Date],
            [Lagged_Thru_Date],
            [LoadDateTime]
        )
        VALUES
			(
				@YearRefresh, 
				'01/01/' + CAST(@YearRefresh - 1 AS CHAR(4)),
				'12/31/' + CAST(@YearRefresh - 1 AS CHAR(4)),
				'07/01/' + CAST(@YearRefresh - 2 AS CHAR(4)), 
				'06/30/' + CAST(@YearRefresh - 1 AS CHAR(4)),
				 @LoadDateTime
			);

	IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '004',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

    END;
    ELSE
    BEGIN
   
        IF EXISTS
        (
            SELECT 1
            FROM [dbo].[tbl_MMR_rollup]
            WHERE [AdjReason] = '25'
                  AND YEAR([PaymStart]) = @Payment_year - 1
        )
        BEGIN
            DECLARE @MinDateAdjReason25 DATETIME;
            DECLARE @MaxDateAdjReason25 DATETIME;
            DECLARE @MaxDCPFinalSweetDate DATETIME;
            DECLARE @MaxFinalDate DATETIME;

            SET @MinDateAdjReason25 =
            (
                SELECT MIN(Imported_date)
                FROM [dbo].[tbl_MMR_rollup]
                WHERE [AdjReason] = '25'
                      AND YEAR([PaymStart]) = @Payment_year - 1
            );

            SET @MaxDCPFinalSweetDate =
            (
                SELECT MAX(Final_sweep_Date)
                FROM [$(HRPReporting)].dbo.lk_dcp_dates
                WHERE LEFT(Paymonth, 4) = @Payment_year - 1
            );

            SET @MaxDateAdjReason25 =
            (
                SELECT CASE
                           WHEN @MinDateAdjReason25 > @MaxDCPFinalSweetDate THEN
                               @MinDateAdjReason25
                           ELSE
                               @MaxDCPFinalSweetDate
                       END
            );


            SET @MaxFinalDate =
            (
                SELECT DATEADD(YEAR, 1, @MaxDateAdjReason25)
            );

            IF EXISTS
            (
                SELECT 1
                FROM [dbo].[tbl_MMR_rollup]
                WHERE [AdjReason] = '25'
                      AND YEAR([PaymStart]) = @Payment_year - 1
                      AND Imported_date
                      BETWEEN @MinDateAdjReason25 AND @MaxFinalDate
            )
            BEGIN
                INSERT INTO [rev].[tbl_Summary_RskAdj_RefreshPY]
                (
                    [Payment_Year],
                    [From_Date],
                    [Thru_Date],
                    [Lagged_From_Date],
                    [Lagged_Thru_Date],
                    [LoadDateTime]
                )
                SELECT @Payment_year - 1,
                       '1/1/' + CAST(@Payment_year - 2 AS CHAR(4)),
                       '12/31/' + CAST(@Payment_year - 2 AS CHAR(4)),
                       '07/01/' + CAST(@Payment_year - 3 AS CHAR(4)),
                       '06/30/' + CAST(@Payment_year - 2 AS CHAR(4)),
                       [LoadDateTime] = @LoadDateTime;

      IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '005',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;


	END;

            IF EXISTS
            (
                SELECT 1
                FROM [dbo].[tbl_MMR_rollup]
                WHERE [AdjReason] = '25'
                      AND YEAR([PaymStart]) = @Payment_year - 1
                      AND Imported_date > @MaxFinalDate
            )
            BEGIN

                SELECT @Payment_year = @Payment_year;

	        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '006',
                                            @ProcessNameIn,
                                            @ET,
                                            @MasterET,
                                            @ET OUT,
                                            0,
                                            0;
            END;
          END;

        END;
        ELSE
        BEGIN

    
            INSERT INTO [rev].[tbl_Summary_RskAdj_RefreshPY]
            (
                [Payment_Year],
                [From_Date],
                [Thru_Date],
                [Lagged_From_Date],
                [Lagged_Thru_Date],
                [LoadDateTime]
            )
            SELECT @Payment_year - 1,
                   '1/1/' + CAST(@Payment_year - 2 AS CHAR(4)),
                   '12/31/' + CAST(@Payment_year - 2 AS CHAR(4)),
                   '07/01/' + CAST(@Payment_year - 3 AS CHAR(4)),
                   '06/30/' + CAST(@Payment_year - 2 AS CHAR(4)),
                   [LoadDateTime] = @LoadDateTime;
        END;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '007',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

        INSERT INTO [rev].[tbl_Summary_RskAdj_RefreshPY]
        (
            [Payment_Year],
            [From_Date],
            [Thru_Date],
            [Lagged_From_Date],
            [Lagged_Thru_Date],
            [LoadDateTime]
        )
        SELECT @Payment_year,
               @From_Date,
               @Thru_Date,
               @Lagged_From_Date,
               @Lagged_Thru_Date,
               [LoadDateTime] = @LoadDateTime;

        IF EXISTS
        (
            SELECT 1
            FROM [dbo].[RAPS_DiagHCC_rollup]
            WHERE YEAR([ProcessedBy]) = @Payment_year
        )
        BEGIN

            IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '008',
                                            @ProcessNameIn,
                                            @ET,
                                            @MasterET,
                                            @ET OUT,
                                            0,
                                            0;
            END;

            INSERT INTO [rev].[tbl_Summary_RskAdj_RefreshPY]
            (
                [Payment_Year],
                [From_Date],
                [Thru_Date],
                [Lagged_From_Date],
                [Lagged_Thru_Date],
                [LoadDateTime]
            )
            SELECT @Payment_year + 1,
                   '1/1/' + CAST(@Payment_year AS CHAR(4)),
                   '12/31/' + CAST(@Payment_year AS CHAR(4)),
                   '07/01/' + CAST(@Payment_year - 1 AS CHAR(4)),
                   '06/30/' + CAST(@Payment_year AS CHAR(4)),
                   [LoadDateTime] = @LoadDateTime;

        END;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '009',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

    END;


    UPDATE [py]
    SET [py].[Initial_Sweep_Date] = [swp].[Initial_Sweep_Date],
        [py].[Final_Sweep_Date] = [swp].[Final_Sweep_Date]
    FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [py]
        JOIN
        (
            SELECT [a].[Payment_Year],
                   [Initial_Sweep_Date] = MIN([dcp].[Initial_Sweep_Date]),
                   [Final_Sweep_Date] = MAX([dcp].[Final_Sweep_Date])
            FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a]
                INNER JOIN [$(HRPReporting)].[dbo].[lk_DCP_dates] [dcp]
                    ON [a].[Payment_Year] = LEFT([dcp].[PayMonth], 4)
            WHERE [dcp].[Mid_Year_Update] IS NULL
            GROUP BY [a].[Payment_Year]
        ) [swp]
            ON [py].[Payment_Year] = [swp].[Payment_Year];

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '010',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    UPDATE [py]
    SET [py].[MidYear_Sweep_Date] = [swp].[MidYear_Sweep_Date]
    FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [py]
        JOIN
        (
            SELECT [a].[Payment_Year],
                   [MidYear_Sweep_Date] = MAX([dcp].[Initial_Sweep_Date])
            FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a]
                INNER JOIN [$(HRPReporting)].[dbo].[lk_DCP_dates] [dcp]
                    ON [a].[Payment_Year] = LEFT([dcp].[PayMonth], 4)
            WHERE [dcp].[Mid_Year_Update] = 'Y'
            GROUP BY [a].[Payment_Year]
        ) [swp]
            ON [py].[Payment_Year] = [swp].[Payment_Year];


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '011',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;

        SELECT [Payment_Year] = [a1].[Payment_Year],
               [From_Date] = [a1].[From_Date],
               [Thru_Date] = [a1].[Thru_Date],
               [Lagged_From_Date] = [a1].[Lagged_From_Date],
               [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date],
               [Initial_Sweep_Date] = [a1].[Initial_Sweep_Date],
               [Final_Sweep_Date] = [a1].[Final_Sweep_Date],
               [MidYear_Sweep_Date] = [a1].[MidYear_Sweep_Date],
               [LoadDateTime] = [a1].[LoadDateTime]
        FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];
    END;
END;