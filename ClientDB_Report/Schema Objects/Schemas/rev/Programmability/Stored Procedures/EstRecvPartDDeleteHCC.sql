CREATE PROCEDURE [rev].[EstRecvPartDDeleteHCC]
    (
	@Debug INT = 0
	)
AS /*****************************************************************************************************************************************************************************************************************/
    /* Name				:	EstRecvPartDDeleteHCC																																									*/
    /* Type 			:	Stored Procedure																																										*/
    /* Author       	:	D. Waddell																																											     */
    /* Date				:	03/05/2018																																												 */
    /* Version			:																																															 */
    /* Description		:	The Part D Delete HCC process will gather information from the Part D Summary RAPS MORD Combined output, specifically the Delete HCC information. The data will be presented at the HICN */
    /*                      Deleted RxHCC level and each record will be updated with attributing encounter level information. This output will allow the user to understand which single encounter was deleted last  */
    /*                      to fully delete that RxHCC.                                                                                                                                                              */
    /*						<Client>_Report database																																								 */
    /*																																																				 */
    /* Version History :																																															*/
    /* Author			Date		Version#	TFS Ticket#		Description																																			*/
    /* ---------------	----------	--------	-----------		------------																																		*/
    /* D. Waddell		03/21/2018	1.0			69793 /RE-14521	Initial build of Part D Delete HCC Procedure.																									    */
    /* Anand            9/22/2020   1.1		    RRI-229/79617   Add Row Count to Log table 																																																			*/
    /****************************************************************************************************************************************************************************************************************/


    SET NOCOUNT ON

    SET STATISTICS IO OFF

    BEGIN
        --DECLARE @Debug INT = 1
        DECLARE @fromdate DATETIME ,
                @thrudate DATETIME ,
                @initial_flag DATETIME ,
                @myu_flag DATETIME ,
                @final_flag DATETIME ,
                @Paymonth_MOR CHAR(2) , --43205
                @GetProviderIdSQL VARCHAR(4096) ,
                @Clnt_Rpt_DB VARCHAR(128) ,
                @ClntPlan_DB VARCHAR(128) ,
                @Clnt_Rpt_Srv VARCHAR(128) ,
                @Clnt_DB VARCHAR(128) ,
                @ClntName VARCHAR(100) ,
                @Rollup_PlanID_dyn SMALLINT ,
                @Rollup_PlanID SMALLINT ,
                @RollupSQL VARCHAR(MAX) ,
                @Coding_Intensity DECIMAL(18, 4) ,
                @Norm_Factor DECIMAL(18, 4) ,
                @PlanID VARCHAR(5) ,
                @RollupSQL_N NVARCHAR(MAX) ,
                @PlanIDSQL VARCHAR(MAX) ,
                @OutTableSQL VARCHAR(MAX) ,
                @Rollup2SQL VARCHAR(MAX) ,
                @ParmDefinition NVARCHAR(500) ,
                @MaxBidPY VARCHAR(5) ,
                @ErrorMessage VARCHAR(500) ,
                @ErrorSeverity INT ,
                @Today DATETIME ,
                @ErrorState INT,
				@RowCount_OUT INT,
				@UserID VARCHAR(128) = SYSTEM_USER,
				@EstRecvRskadjActivityID INT;


        DECLARE @Open_Qry_SQL NVARCHAR(MAX);
        DECLARE @TablePlan TABLE
            (
                [ID] INT IDENTITY(1, 1) PRIMARY KEY ,
                [PlanID] VARCHAR(5)
            );


        IF @Debug = 1
            BEGIN
                SET STATISTICS IO ON
                DECLARE @ET DATETIME
                DECLARE @MasterET DATETIME
                DECLARE @ProcessNameIn VARCHAR(128)
                SET @ET = GETDATE()
                SET @MasterET = @ET
                SET @ProcessNameIn = OBJECT_NAME(@@PROCID)
                EXEC [dbo].[PerfLogMonitor] '000' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        IF 1 = 2
            SELECT [PAYMENT_YEAR] = CAST(NULL AS INT) ,
                   [PAYMSTART] = CAST(NULL AS DATETIME) ,
                   [PROCESSED_BY_START] = CAST(NULL AS SMALLDATETIME) ,
                   [PROCESSED_BY_END] = CAST(NULL AS SMALLDATETIME) ,
                   [PLANID] = CAST(NULL AS VARCHAR(5)) ,
                   [HICN] = CAST(NULL AS VARCHAR(15)) ,
                   [RA_FACTOR_TYPE] = CAST(NULL AS VARCHAR(10)) ,
                   [PROCESSED_PRIORITY_PROCESSED_BY] = CAST(NULL AS DATETIME) ,
                   [PROCESSED_PRIORITY_THRU_DATE] = CAST(NULL AS DATETIME) ,
                   [PROCESSED_PRIORITY_PCN] = CAST(NULL AS VARCHAR(50)) ,
                   [PROCESSED_PRIORITY_DIAG] = CAST(NULL AS VARCHAR(20)) ,
                   [THRU_PRIORITY_PROCESSED_BY] = CAST(NULL AS DATETIME) ,
                   [THRU_PRIORITY_THRU_DATE] = CAST(NULL AS DATETIME) ,
                   [THRU_PRIORITY_PCN] = CAST(NULL AS VARCHAR(50)) ,
                   [THRU_PRIORITY_DIAG] = CAST(NULL AS VARCHAR(20)) ,
                   [IN_MOR] = CAST(NULL AS VARCHAR(1)) ,
                   [HCC] = CAST(NULL AS VARCHAR(20)) ,
                   [HCC_DESCRIPTION] = CAST(NULL AS VARCHAR(255)) ,
                   [FACTOR] = CAST(NULL AS DECIMAL(20, 4)) ,
                   [HIER_HCC_OLD] = CAST(NULL AS VARCHAR(20)) ,
                   [HIER_FACTOR_OLD] = CAST(NULL AS DECIMAL(20, 4)) ,
                   [ACTIVE_INDICATOR_FOR_ROLLFORWARD] = CAST(NULL AS VARCHAR(1)) ,
                   [MONTHS_IN_DCP] = CAST(NULL AS INT) ,
                   [ESRD] = CAST(NULL AS VARCHAR(3)) ,
                   [HOSP] = CAST(NULL AS VARCHAR(3)) ,
                   [PBP] = CAST(NULL AS VARCHAR(3)) ,
                   [SCC] = CAST(NULL AS VARCHAR(5)) ,
                   [BID] = CAST(NULL AS MONEY) ,
                   [ESTIMATED_VALUE] = CAST(NULL AS MONEY) ,
                   [RAPS_SOURCE] = CAST(NULL AS VARCHAR(50)) ,
                   [PROVIDER_ID] = CAST(NULL AS VARCHAR(40)) ,
                   [PROVIDER_LAST] = CAST(NULL AS VARCHAR(55)) ,
                   [PROVIDER_FIRST] = CAST(NULL AS VARCHAR(55)) ,
                   [PROVIDER_GROUP] = CAST(NULL AS VARCHAR(80)) ,
                   [PROVIDER_ADDRESS] = CAST(NULL AS VARCHAR(100)) ,
                   [PROVIDER_CITY] = CAST(NULL AS VARCHAR(30)) ,
                   [PROVIDER_STATE] = CAST(NULL AS VARCHAR(2)) ,
                   [PROVIDER_ZIP] = CAST(NULL AS VARCHAR(13)) ,
                   [PROVIDER_PHONE] = CAST(NULL AS VARCHAR(15)) ,
                   [PROVIDER_FAX] = CAST(NULL AS VARCHAR(15)) ,
                   [TAX_ID] = CAST(NULL AS VARCHAR(55)) ,
                   [NPI] = CAST(NULL AS VARCHAR(20)) ,
                   [SWEEP_DATE] = CAST(NULL AS DATETIME)




        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '001.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        /* Set Thru Date */
        SET @thrudate = GETDATE()

        SET @Today = GETDATE()




        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '001.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        IF OBJECT_ID('TempDB..#Refresh_PY') IS NOT NULL
            DROP TABLE #Refresh_PY





        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '001.3' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END




        /* Identify Years to Refresh Data */
        CREATE TABLE [#Refresh_PY]
            (
                [Id] INT IDENTITY(1, 1) PRIMARY KEY ,
                [Payment_Year] INT ,
                [From_Date] DATE ,
                [Thru_Date] DATE ,
                [Lagged_From_Date] DATE ,
                [Lagged_Thru_Date] DATE ,
                [InitialFlag] DATETIME ,
                [MyuFlag] DATETIME ,
                [FinalFlag] DATETIME ,
                [PartD_Factor] DECIMAL(18, 4) ,
                [Payment_Year_MinusOne] INT
            )




        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '001.4' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        /*   Insert into #Refresh_PY  */
        INSERT INTO [#Refresh_PY] (   [Payment_Year] ,
                                      [From_Date] ,
                                      [Thru_Date] ,
                                      [Lagged_From_Date] ,
                                      [Lagged_Thru_Date] ,
                                      [Payment_Year_MinusOne]
                                  )
                    SELECT [Payment_Year] = [a1].[Payment_Year] ,
                           [From_Date] = [a1].[From_Date] ,
                           [Thru_Date] = [a1].[Thru_Date] ,
                           [Lagged_From_Date] = [a1].[Lagged_From_Date] ,
                           [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date] ,
                           [Payment_Year_MinusOne] = [a1].[Payment_Year] - 1
                    FROM   [rev].[tbl_Summary_RskAdj_RefreshPY] [a1]



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '002' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        /* Update Sweep Flag */
        UPDATE [py]
        SET    [py].[InitialFlag] = [py2].[InitialFlagDate]
        FROM   [#Refresh_PY] [py]
               INNER JOIN (   SELECT   [p].[Payment_Year] ,
                                       [InitialFlagDate] = MIN([lk].[Initial_Sweep_Date])
                              FROM     [#Refresh_PY] [p]
                                       INNER JOIN [$(HRPReporting)].[dbo].[lk_DCP_dates] [lk] ON SUBSTRING(
                                                                                                           [lk].PayMonth ,
                                                                                                           1 ,
                                                                                                           4
                                                                                                       ) = CAST([p].[Payment_Year] AS CHAR(4))
                                                                                              AND [lk].[Mid_Year_Update] IS NULL
                              GROUP BY [p].[Payment_Year]
                          ) [py2] ON [py].[Payment_Year] = [py2].[Payment_Year]


        UPDATE [py]
        SET    [py].[MyuFlag] = py2.[MidYearUpdate]
        FROM   [#Refresh_PY] [py]
               INNER JOIN (   SELECT   [p].[Payment_Year] ,
                                       [MidYearUpdate] = MIN([lk].[Initial_Sweep_Date])
                              FROM     [#Refresh_PY] [p]
                                       INNER JOIN [$(HRPReporting)].[dbo].[lk_DCP_dates] [lk] ON SUBSTRING(
                                                                                                           [lk].PayMonth ,
                                                                                                           1 ,
                                                                                                           4
                                                                                                       ) = CAST([p].[Payment_Year] AS CHAR(4))
                                                                                              AND [lk].[Mid_Year_Update] = 'Y'
                              GROUP BY [p].[Payment_Year]
                          ) [py2] ON [py].[Payment_Year] = [py2].[Payment_Year]





        UPDATE [py]
        SET    [py].[FinalFlag] = [py2].[FinalSweepDate]
        FROM   [#Refresh_PY] [py]
               INNER JOIN (   SELECT   [p].[Payment_Year] ,
                                       [FinalSweepDate] = MIN([lk].[Final_Sweep_Date])
                              FROM     [#Refresh_PY] [p]
                                       INNER JOIN [$(HRPReporting)].[dbo].[lk_DCP_dates] [lk] ON SUBSTRING(
                                                                                                           [lk].PayMonth ,
                                                                                                           1 ,
                                                                                                           4
                                                                                                       ) = CAST([p].[Payment_Year] AS CHAR(4))
                                                                                              AND [lk].[Mid_Year_Update] IS NULL
                              GROUP BY [p].[Payment_Year]
                          ) [py2] ON [py].[Payment_Year] = [py2].[Payment_Year]









        UPDATE [py]
        SET    [py].[PartD_Factor] = [t].[PartD_Factor]
        FROM   [#Refresh_PY] [py]
               INNER JOIN (   SELECT DISTINCT [f].[PartD_Factor] ,
                                     [Year]
                              FROM   [#Refresh_PY] [py]
                                     INNER JOIN [$(HRPReporting)].[dbo].[lk_normalization_factors] [f] ON [f].[Year] = CAST([py].[Payment_Year] AS CHAR(4))
                          ) [t] ON [t].[Year] = CAST([py].[Payment_Year] AS CHAR(4))




        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '003' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END





        IF ( OBJECT_ID('TempDB..#BidsRollup') IS NOT NULL )
            DROP TABLE [#BidsRollup]

        /* Create #Bid Rollup Table*/
        CREATE TABLE [#BidsRollup]
            (
                [BidsRollupID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
                [PBP] VARCHAR(4) NULL ,
                [SCC] VARCHAR(5) NULL ,
                [MABID1] SMALLMONEY NULL ,
                [HICN] VARCHAR(12) NULL ,
                [PaymStart] DATETIME NULL ,
                [PaymentYear] SMALLINT NULL ,
                [HOSP] CHAR(1) NULL
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '003.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#BidsRollup] (   [PBP] ,
                                      [SCC] ,
                                      [MABID1] ,
                                      [HICN] ,
                                      [PaymStart] ,
                                      [PaymentYear] ,
                                      [HOSP]
                                  )
                    SELECT DISTINCT [MMR].[PBP] ,
                           [MMR].[SCC] ,
                           [b].[PartD_BID] AS [MABID1] ,
                           [MMR].[HICN] ,
                           [MMR].[PaymStart] ,
                           [MMR].[PaymentYear] ,
                           [MMR].[HOSP]
                    FROM   [rev].[tbl_Summary_RskAdj_MMR] [MMR]
                           INNER JOIN [#Refresh_PY] [py] ON [MMR].[PaymentYear] = [py].[Payment_Year]
                           LEFT OUTER JOIN [dbo].[tbl_BIDS_rollup] [b] ON [MMR].[PlanID] = [b].[PlanIdentifier]
                                                                          AND [MMR].[PBP] = [b].[PBP]
                                                                          AND CAST([b].[Bid_Year] AS INT) = ( CASE WHEN YEAR(GETDATE()) < [py].[Payment_Year] THEN
                                                                                                                       ISNULL(
                                                                                                                                 @MaxBidPY ,
                                                                                                                                 0
                                                                                                                             )
                                                                                                                   ELSE
                                                                                                                       [py].[Payment_Year]
                                                                                                              END
                                                                                                            )
        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '003.2' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        IF OBJECT_ID('TempDB..#BidsRollupHICNMaxPaymStart') IS NOT NULL
            DROP TABLE #BidsRollupHICNMaxPaymStart

        /* Create #BidsRollupHICNMaxPaymStart Table */
        CREATE TABLE [#BidsRollupHICNMaxPaymStart]
            (
                [BidsRollupHICNMaxPaymStartID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
                [HICN] VARCHAR(15) NULL ,
                [PaymYear] INT NULL ,
                [MaxPaymStart] DATETIME NULL
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '003.3' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#BidsRollupHICNMaxPaymStart] (   [HICN] ,
                                                      [PaymYear] ,
                                                      [MaxPaymStart]
                                                  )
                    SELECT   [HICN] ,
                             YEAR([PaymStart]) AS [PaymYear] ,
                             MAX([PaymStart]) AS [MaxPaymStart]
                    FROM     #BidsRollup
                    GROUP BY [HICN] ,
                             YEAR([PaymStart])

        CREATE NONCLUSTERED INDEX IX_BidsRollupHICNMaxPaymStart_AllColumns
            ON #BidsRollupHICNMaxPaymStart
            (
                [HICN] ,
                [PaymYear] ,
                [MaxPaymStart]
            )

        IF OBJECT_ID('TempDB..#BidsRollupMaxPaymStart') IS NOT NULL
            DROP TABLE [#BidsRollupMaxPaymStart]

        /*Create #BidsRollupMaxPaymStart */
        CREATE TABLE [#BidsRollupMaxPaymStart]
            (
                [BidsRollupMaxPaymStartID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
                [PaymYear] INT NULL ,
                [MaxPaymStart] DATETIME NULL
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '003.5' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#BidsRollupMaxPaymStart] (   [PaymYear] ,
                                                  [MaxPaymStart]
                                              )
                    SELECT   [PaymentYear] AS [PaymYear] ,
                             MAX([PaymStart]) AS [MaxPaymStart]
                    FROM     [#BidsRollup] [bb]
                    GROUP BY [bb].[PaymentYear]



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '004' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '006' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        SET @Clnt_Rpt_DB = ( SELECT [Current Database] = DB_NAME());

        SET @Clnt_Rpt_Srv = ( SELECT CONVERT(
                                                sysname ,
                                                SERVERPROPERTY('servername')
                                            )
                            );
        SET @ClntName = (   SELECT [Client_Name]
                            FROM   [$(HRPReporting)].[dbo].[tbl_Clients]
                            WHERE  [Report_DB] = @Clnt_Rpt_DB
                        )



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '006.8' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        SET @Clnt_DB = (   SELECT [Client_DB]
                           FROM   [$(HRPReporting)].[dbo].[tbl_Clients]
                           WHERE  [Report_DB] = @Clnt_Rpt_DB
                       )




        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '007' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        IF OBJECT_ID('tempdb..#RollupPlan ', 'U') IS NOT NULL
            DROP TABLE [#RollupPlan]

        /* Create [#RollupPlan] Table */
        CREATE TABLE [#RollupPlan]
            (
                [ID] INT IDENTITY(1, 1) ,
                [PlanID] INT ,
                [Plan_ID] VARCHAR(5)
            )



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '007.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        IF OBJECT_ID('tempdb..#Paymonth_MOR ', 'U') IS NOT NULL
            DROP TABLE [#Paymonth_MOR]

        CREATE TABLE [#Paymonth_MOR]
            (
                [ID] INT IDENTITY(1, 1) ,
                [PayYr] CHAR(4) ,
                [PayMth] VARCHAR(6) ,
                [In_Mor] CHAR(1)
            )


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '008' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '008.2' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        INSERT INTO [#Paymonth_MOR] (   [PayYr] ,
                                        [PayMth] ,
                                        [In_Mor]
                                    )
                    SELECT DISTINCT LEFT([lk].[PayMonth], 4) ,
                           [lk].[PayMonth] ,
                           [MOR_Mid_Year_Update]
                    FROM   dbo.lk_DCP_dates_RskAdj [lk]
                           INNER JOIN [#Refresh_PY] [py] ON [py].[Payment_Year] = CAST(LEFT([lk].[PayMonth], 4) AS INT)
                                                            AND [lk].MOR_Mid_Year_Update = 'Y'

        DECLARE @SQL NVARCHAR(1024)
        DECLARE @SQLParm NVARCHAR(1024)



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '008.5' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0

            END





        /*45816*/
        IF OBJECT_ID('tempdb..#Vw_LkRiskModelsDiagHCC') IS NOT NULL
            DROP TABLE [#Vw_LkRiskModelsDiagHCC]

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '010' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        SELECT [ICD].[ICDCode] ,
               [HCC_Label] = [ICD].[HCCLabel] ,
               [Payment_Year] = [ICD].[PaymentYear] ,
               [Factor_Type] = [ICD].[FactorType] ,
               [ICD].[ICDClassification] ,
               [ef].[StartDate] ,
               [ef].[EndDate]
        INTO   [#Vw_LkRiskModelsDiagHCC]
        FROM   [$(HRPReporting)].[dbo].[Vw_LkRiskModelsDiagHCC] [ICD]
               JOIN [$(HRPReporting)].[dbo].[ICDEffectiveDates] [ef] ON [ICD].[ICDClassification] = [ef].[ICDClassification]


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '011' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        /* - Dynamic Paymonth for MOR Mid_year_Update */


        IF OBJECT_ID('[TEMPDB].[DBO].[#New_HCC_rollup]', 'U') IS NOT NULL
            DROP TABLE [dbo].[#New_HCC_rollup]

        CREATE TABLE [dbo].[#New_HCC_rollup]
            (
                [PlanIdentifier] INT ,
                [Plan_ID] VARCHAR(5) ,
                [HICN] VARCHAR(12) ,
                [PaymentYear] INT ,
                [PaymStart] DATETIME ,
                [ModelYear] INT ,
                [Factorcategory] VARCHAR(20) ,
                [RxHCCLabel] VARCHAR(50) ,
                [Factor] DECIMAL(20, 4) ,
                [PartDRAFTRestated] VARCHAR(3) ,
                [RxHCCNumber] INT ,
                [MinProcessBy] DATETIME ,
                [MinThruDate] DATETIME ,
                [MinProcessBySeqNum] INT ,
                [MinThruDateSeqNum] INT ,
                [ProcessedPriority_Thru_Date] DATETIME ,
                [MinProcessByPCN] VARCHAR(50) ,
                [MinProcessbyDiagCD] VARCHAR(20) ,
                [ThruPriorityProcessedBy] DATETIME ,
                [MinThruDatePCN] VARCHAR(50) ,
                [MinThruDateDiagCD] VARCHAR(20) ,
                [ProcessedPriorityRAPSSourceID] INT ,
                [ThruPriorityRAPSSourceID] INT ,
                [ProcessedPriorityProviderID] VARCHAR(40) ,
                [ThruPriorityProviderID] VARCHAR(40) ,
                [Unionqueryind] INT NULL ,
                [AGED] INT
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '012' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '012.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#New_HCC_rollup] (   [PlanIdentifier] ,
                                          [HICN] ,
                                          [PaymentYear] ,
                                          [PaymStart] ,
                                          [ModelYear] ,
                                          [Factorcategory] ,
                                          [RxHCCLabel] ,
                                          [Factor] ,
                                          [PartDRAFTRestated] ,
                                          [RxHCCNumber] ,
                                          [MinProcessBy] ,
                                          [MinThruDate] ,
                                          [MinProcessBySeqNum] ,
                                          [MinThruDateSeqNum] ,
                                          [ProcessedPriority_Thru_Date] ,
                                          [MinProcessByPCN] ,
                                          [MinProcessbyDiagCD] ,
                                          [ThruPriorityProcessedBy] ,
                                          [MinThruDatePCN] ,
                                          [MinThruDateDiagCD] ,
                                          [ProcessedPriorityRAPSSourceID] ,
                                          [ThruPriorityRAPSSourceID] ,
                                          [ProcessedPriorityProviderID] ,
                                          [ThruPriorityProviderID] ,
                                          [Unionqueryind] ,
                                          [AGED]
                                      )
                    SELECT [rps].[PlanIdentifier] ,
                           [rps].[HICN] ,
                           [rps].[PaymentYear] ,
                           [rps].[PaymStart] ,
                           [Model_Year] = [rps].[ModelYear] ,
                           [rps].[Factorcategory] ,
                           [rps].[RxHCCLabel] ,
                           [rps].[Factor] ,
                           [rps].[PartDRAFTRestated] ,
                           [rps].[RxHCCNumber] ,
                           [rps].[MinProcessBy] ,
                           [rps].[MinThruDate] ,
                           [rps].[MinProcessBySeqNum] ,
                           [rps].[MinThruDateSeqNum] ,
                           [ProcessedPriorityThruDate] ,
                           [MinProcessByPCN] ,
                           [MinProcessbyDiagCD] ,
                           [ThruPriorityProcessedBy] ,
                           [MinThruDatePCN] ,
                           [MinThruDateDiagCD] ,
                           [ProcessedPriorityRAPSSourceID] ,
                           [ThruPriorityRAPSSourceID] ,
                           [ProcessedPriorityProviderID] ,
                           [ThruPriorityProviderID] ,
                           [IMFFlag] AS [UnionqueryInd] ,
                           [rps].[Aged]
                    FROM   [rev].[SummaryPartDRskAdjRAPSMORDCombined] rps
                           INNER JOIN [#Refresh_PY] py ON [rps].[PaymentYear] = [py].[Payment_Year]
                    WHERE  [rps].[RxHCCLabel] LIKE 'DEL%'



        EXEC ( @RollupSQL )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '012.2' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '013' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        CREATE CLUSTERED INDEX [New_HCC_rollup]
            ON [#New_HCC_rollup]
            (
                [HICN] ,
                [RxHCCLabel]
            )


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '013.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        IF OBJECT_ID('TempDB..#AltHICN]') IS NOT NULL
            DROP TABLE [#AltHICN]
        /* Create [#AltHICN] Table */
        CREATE TABLE [#AltHICN]
            (
                [AltHICNID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
                [HICN] VARCHAR(12) NULL ,
                [FinalHICN] VARCHAR(12) NULL
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '013.2' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO #AltHICN (   [HICN] ,
                                 [FinalHICN]
                             )
                    SELECT   [HICN] ,
                             [FinalHICN]
                    FROM     [rev].[tbl_Summary_RskAdj_AltHICN]
                    GROUP BY [HICN] ,
                             [FinalHICN]

        CREATE NONCLUSTERED INDEX IX_AltHICN_HICN
            ON #AltHICN ( [HICN] )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '013.3' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END




        IF OBJECT_ID('[TEMPDB].[DBO].[#new_hcc_output]', 'U') IS NOT NULL
            DROP TABLE [dbo].[#new_hcc_output]

        /*Create [#new_hcc_output] Table */
        CREATE TABLE [dbo].[#new_hcc_output]
            (
                [payment_year] INT ,
                [paymstart] DATETIME ,
                [model_year] INT ,
                [processed_by_start] DATETIME ,
                [processed_by_end] DATETIME ,
                [planid] VARCHAR(5) ,
                [planidentifier] INT ,
                [hicn] VARCHAR(15) ,
                [ra_factor_type] VARCHAR(2) ,
                [processed_priority_processed_by] DATETIME ,
                [processed_priority_thru_date] DATETIME ,
                [processed_priority_pcn] VARCHAR(50) ,
                [processed_priority_diag] VARCHAR(20) ,
                [thru_priority_processed_by] DATETIME ,
                [thru_priority_thru_date] DATETIME ,
                [thru_priority_pcn] VARCHAR(50) ,
                [thru_priority_diag] VARCHAR(20) ,
                [in_mor] VARCHAR(1) ,
                [in_mor_max_month] VARCHAR(6) ,
                [hcc] VARCHAR(20) ,
                [hcc_No_Tags] VARCHAR(20) ,
                [hcc_description] VARCHAR(255) ,
                [factor] DECIMAL(20, 4) ,
                [hier_hcc_old] VARCHAR(20) ,
                [hier_factor_old] DECIMAL(20, 4) ,
                [member_months] INT ,
                [active_indicator_for_rollforward] VARCHAR(1) ,
                [months_in_dcp] INT ,
                [esrd] VARCHAR(1) ,
                [hosp] VARCHAR(1) ,
                [pbp] VARCHAR(3) ,
                [scc] VARCHAR(5) ,
                [PartD_BID] MONEY ,
                [estimated_value] MONEY ,
                [raps_source] VARCHAR(50) ,
                [provider_id] VARCHAR(40) ,
                [provider_last] VARCHAR(55) ,
                [provider_first] VARCHAR(55) ,
                [provider_group] VARCHAR(80) ,
                [provider_address] VARCHAR(100) ,
                [provider_city] VARCHAR(30) ,
                [provider_state] VARCHAR(2) ,
                [provider_zip] VARCHAR(13) ,
                [provider_phone] VARCHAR(15) ,
                [provider_fax] VARCHAR(15) ,
                [tax_id] VARCHAR(55) ,
                [UnionQueryInd] INT NULL ,
                [npi] VARCHAR(20) ,
                [PaymStartYear] INT NULL ,
                [AGED] INT
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '015' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#new_hcc_output] (   [payment_year] ,
                                          [paymstart] ,
                                          [model_year] ,
                                          [processed_by_start] ,
                                          [processed_by_end] ,
                                          [planid] ,
                                          [planidentifier] ,
                                          [hicn] ,
                                          [ra_factor_type] ,
                                          [processed_priority_processed_by] ,
                                          [processed_priority_thru_date] ,
                                          [processed_priority_pcn] ,
                                          [processed_priority_diag] ,
                                          [thru_priority_processed_by] ,
                                          [thru_priority_thru_date] ,
                                          [thru_priority_pcn] ,
                                          [thru_priority_diag] ,
                                          [hcc] ,
                                          [hcc_No_Tags] ,
                                          [factor] ,
                                          [member_months] ,
                                          [raps_source] ,
                                          [provider_id] ,
                                          [UnionQueryInd] ,
                                          [PaymStartYear] ,
                                          [AGED]
                                      )
                    SELECT DISTINCT [n].[PaymentYear] ,
                           [n].[PaymStart] ,
                           [model_year] = [n].[ModelYear] ,
                           [processed_by_start] = [py].[From_Date] ,
                           [processed_by_end] = @thrudate ,
                           [planid] = [n].[Plan_ID] , --H Plan ID,
                           [planidentifier] = [n].[PlanIdentifier] ,
                           [n].[HICN] ,
                           [ra_factor_type] = [n].[PartDRAFTRestated] ,
                           [n].[MinProcessBy] ,
                           [processed_priority_processed_by] = [n].[ProcessedPriority_Thru_Date] ,
                           [processed_priority_pcn] = [n].[MinProcessByPCN] ,
                           [processed_priority_diag] = [n].[MinProcessbyDiagCD] ,
                           [n].[ThruPriorityProcessedBy] ,
                           [thru_priority_processed_by] = [n].[MinThruDate] ,
                           [thru_priority_pcn] = [n].[MinThruDatePCN] ,
                           [thru_priority_diag] = [n].[MinThruDateDiagCD] ,
                           [hcc] = [n].[RxHCCLabel] ,
                           [hcc_No_Tags] = SUBSTRING(
                                                        [n].[RxHCCLabel] ,
                                                        5 ,
                                                        LEN([n].[RxHCCLabel])
                                                    ) ,
                           [factor] = [n].[Factor] ,
                           [member_months] = 1 ,
                           [raps_source] = ISNULL(
                                                     [n].[ProcessedPriorityRAPSSourceID] ,
                                                     [n].[ThruPriorityRAPSSourceID]
                                                 ) ,  --42124
                           [provider_id] = ISNULL(
                                                     [n].[ProcessedPriorityProviderID] ,
                                                     [n].[ThruPriorityProviderID]
                                                 ) ,  --42124
                           [n].[Unionqueryind] ,
                           YEAR(n.PaymStart) AS PaymStartYear ,
                           [AGED] = [n].[AGED]
                    FROM   [#New_HCC_rollup] [n]
                           INNER JOIN [#Refresh_PY] [py] ON [n].PaymentYear = [py].[Payment_Year]




        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '015.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        IF OBJECT_ID('TempDB..#MemberMonthsRollUp') IS NOT NULL
            DROP TABLE [#MemberMonthsRollUp]


        /*Create [#MemberMonthsRollUp] Table */
        CREATE TABLE [#MemberMonthsRollUp]
            (
                [MemberMonthsRollUpID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
                [HICN] VARCHAR(12) NULL ,
                [PaymYear] SMALLINT NULL ,
                [MonthsInDCP] INT NULL
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '015.2' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#MemberMonthsRollUp] (   [HICN] ,
                                              [PaymYear] ,
                                              [MonthsInDCP]
                                          )
                    SELECT   [HICN] ,
                             YEAR([MMR].[PaymStart]) AS PaymYear ,
                             COUNT(DISTINCT PaymStart) AS MonthsInDCP
                    FROM     [dbo].[tbl_Member_Months_rollup] [MMR]
                             INNER JOIN [#Refresh_PY] [py] ON YEAR([MMR].[PaymStart]) = [py].[Payment_Year]
                                                              AND [MMR].[HICN] IS NOT NULL
                    GROUP BY [MMR].[HICN] ,
                             YEAR([MMR].[PaymStart])

        CREATE NONCLUSTERED INDEX IX_MemberMonthsRollUp_HICN
            ON #MemberMonthsRollUp ( [HICN] )
            INCLUDE
            (
                [PaymYear] ,
                [MonthsInDCP]
            )


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '015.3' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        IF OBJECT_ID('TempDB..#MemberMonthRollupAltHICN') IS NOT NULL
            DROP TABLE [#MemberMonthRollupAltHICN]

        /*Create [#MemberMonthRollupAltHICN] Table */
        CREATE TABLE [#MemberMonthRollupAltHICN]
            (
                [MemberMonthRollupAltHICNID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
                [HICN] VARCHAR(12) ,
                [PaymYear] SMALLINT ,
                [MonthsInDCP] INT
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '015.4' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#MemberMonthRollupAltHICN] (   [HICN] ,
                                                    [PaymYear] ,
                                                    [MonthsInDCP]
                                                )
                    SELECT ISNULL([althcn].[FinalHICN], [a].[HICN]) AS [HICN] ,
                           [a].[PaymYear] ,
                           [a].[MonthsInDCP]
                    FROM   [#MemberMonthsRollUp] [a]
                           LEFT OUTER JOIN #AltHICN [althcn] ON [a].[HICN] = [althcn].[HICN]
                    WHERE  [a].[HICN] IS NOT NULL

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '015.5' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        CREATE NONCLUSTERED INDEX IX_MemberMonthRollupAltHICN_HICN
            ON [#MemberMonthRollupAltHICN]
            (
                [HICN] ,
                [PaymYear]
            )






        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '016' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        UPDATE [n]
        SET    [n].[in_mor_max_month] = [t].[paymonth]
        FROM   [#new_hcc_output] [n]
               INNER JOIN (   SELECT   [m].[HICN] ,
                                       [m].[Name] [hcc] ,
                                       MAX([m].Payment_Month) [paymonth]
                              FROM     [dbo].[Converted_MORD_Data_rollup] [m]
                                       INNER JOIN [#Refresh_PY] [py] ON CAST(LEFT([m].[Payment_Month], 4) AS INT) = [py].[Payment_Year]
                              GROUP BY [m].[HICN] ,
                                       [m].[Name]
                          ) [t] ON [n].[hicn] = [t].[hicn]
                                   AND [t].[hcc] = SUBSTRING(
                                                                [n].[hcc] ,
                                                                5 ,
                                                                LEN([n].[hcc])
                                                            )





        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '018' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        UPDATE [n]
        SET    [n].[in_mor] = 'Y'
        FROM   [#new_hcc_output] [n]
               INNER JOIN [dbo].[Converted_MORD_Data_rollup] [v] ON [v].[Name] = [n].[hcc_No_Tags] -- add column in #new_hcc_output for the substring
                                                                    AND [v].[hicn] = [n].[hicn]
               INNER JOIN [#Paymonth_MOR] [lk] ON LEFT([v].[Payment_Month], 4) = [lk].[PayYr]
                                                  AND (   LEFT([v].[Payment_Month], 6) >= [lk].[PayMth]
                                                          AND LEFT([v].[Payment_Month], 6) >= [lk].[PayYr]
                                                                                              + '99'
                                                      ) --Testing this with "<" and also with ">" 
                                                  AND CAST(SUBSTRING(
                                                                        [v].[Payment_Month] ,
                                                                        1 ,
                                                                        4
                                                                    ) AS INT) = [n].[model_year]



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '019' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        -- before mid year update and @Payment_Year_NewDeleteHCC + '99' @Payment_Year_NewDeleteHCC + @Paymonth_MOR 

        BEGIN
            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '020' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END




            UPDATE [n]
            SET    [n].[in_mor] = 'Y'
            FROM   [#new_hcc_output] [n]
                   INNER JOIN [dbo].[Converted_MORD_Data_rollup] [v] ON [v].[Name] = [n].[hcc_No_Tags]
                                                                        AND [v].[hicn] = [n].[hicn]
                                                                        AND CAST(SUBSTRING(
                                                                                              [v].[Payment_Month] ,
                                                                                              1 ,
                                                                                              4
                                                                                          ) AS INT) = [n].[model_year]
                   INNER JOIN [#Paymonth_MOR] [mo] ON (   [v].[Payment_Month] >= [mo].[PayMth]
                                                                                 + +'01'
                                                          AND LEFT([v].[Payment_Month], 6) < [mo].[PayMth]
                                                      )


            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '020.1' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END


            EXECUTE ( @RollupSQL )


            IF @Debug = 1
                BEGIN
                    EXEC [dbo].[PerfLogMonitor] '021' ,
                                                @ProcessNameIn ,
                                                @ET ,
                                                @MasterET ,
                                                @ET OUT ,
                                                0 ,
                                                0
                END
        END

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '022' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        -- Ticket # 25641 End
        UPDATE [n]
        SET    [n].[in_mor] = 'N'
        FROM   [#new_hcc_output] [n]
        WHERE  [n].[in_mor] IS NULL

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '023' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END
        -- update Hierarchy

        SET @RollupSQL = '	
					UPDATE        [HCCOP]
					   SET        [HCCOP].[hier_hcc_old] = [Hier].[HCC_DROP]
								, [HCCOP].[hier_factor_old] = [RskMod].[Factor]
					 
					  FROM        [#new_hcc_output] [HCCOP]
					 INNER JOIN ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
                         + '.[dbo].[Raps_Accepted_rollup] [r]
						ON [HCCOP].[hicn]                                                                      = [r].[HICN]
					   AND SUBSTRING([HCCOP].[in_mor_max_month], 1, 4)                                         = YEAR([r].[ThruDate]) + 1
					 INNER JOIN   [#Vw_LkRiskModelsDiagHCC] [dh]
						ON [r].[DiagnosisCode]                                                                 = [dh].[ICDCode] /*45816 */
					   AND YEAR([r].[ThruDate]) + 1                                                            = [dh].[Payment_Year]
					   AND [r].[ThruDate] BETWEEN [dh].[StartDate] AND [dh].[EndDate] /*45816 */
					   AND [HCCOP].[ra_factor_type]                                                            = [dh].[Factor_Type]
					 INNER JOIN   [$(HRPReporting)].[dbo].[lk_Risk_Models_Hierarchy] [Hier]
						ON [Hier].[Payment_Year]                                                               = [HCCOP].[model_year]
					   AND [Hier].[RA_FACTOR_TYPE]                                                             = [HCCOP].[ra_factor_type]
					   AND SUBSTRING([Hier].[HCC_KEEP], 4, LEN([Hier].[HCC_KEEP]) - 3)                         = SUBSTRING(
																													 [HCCOP].[hcc], 8
																												   , LEN([HCCOP].[hcc]) - 3)
					   AND SUBSTRING([Hier].[HCC_DROP], 4, LEN([Hier].[HCC_DROP]) - 3)                         = SUBSTRING(
																													 [dh].[HCC_Label], 4
																												   , LEN([dh].[HCC_Label]) - 3)
					   AND LEFT([Hier].[HCC_KEEP], 3)                                                          = SUBSTRING([HCCOP].[hcc], 5, 3)
					 INNER JOIN   [$(HRPReporting)].[dbo].[lk_Risk_Models] [RskMod]
						ON [RskMod].[Payment_Year]                                                             = [Hier].[Payment_Year]
					   AND [RskMod].[Factor_Type]                                                              = [Hier].[RA_FACTOR_TYPE]
					   AND SUBSTRING([RskMod].[Factor_Description], 4, LEN([RskMod].[Factor_Description]) - 3) = SUBSTRING(
																													 [Hier].[HCC_DROP]
																												   , 4
																												   , LEN(
																														 [Hier].[HCC_DROP])
																													 - 3)
					   AND [RskMod].[Demo_Risk_Type]                                                           = ''risk''
					 WHERE        EXISTS (SELECT 1
											FROM [#New_HCC_rollup] [drp]
										   WHERE [drp].[HICN]                          = [HCCOP].[hicn]
											 AND [drp].[RxHCCNumber]                    = SUBSTRING([Hier].[HCC_KEEP], 4, LEN([Hier].[HCC_KEEP]) - 3)
											 AND [drp].[PartDRAFTRestated]             = [HCCOP].[ra_factor_type]
											 AND [drp].[ModelYear]                    = [HCCOP].[model_year])
									 AND (      LEFT([RskMod].[Factor_Description], 3)       = ''HCC''
										OR      LEFT([RskMod].[Factor_Description], 3) = ''INT'')
									 AND (LEFT([Hier].[HCC_DROP], 3)                   = ''HCC'')
									 AND [RskMod].[Factor]                             > ISNULL([HCCOP].[hier_factor_old], 0)
									 AND LEFT([HCCOP].[hcc], 7)                        = ''DEL-HCC''
									 '
        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '023.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        EXECUTE ( @RollupSQL )


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '024' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        UPDATE [n]
        SET    [n].[in_mor_max_month] = SUBSTRING([n].[in_mor_max_month], 1, 4)
                                        + '12'
        FROM   [#new_hcc_output] [n]
        WHERE  SUBSTRING([n].[in_mor_max_month], 5, 2) = '99'



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '026' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        UPDATE [n]
        SET    [n].[factor] = 0
        FROM   [#new_hcc_output] [n]
        WHERE  [n].[factor] IS NULL

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '027' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END




        UPDATE [n]
        SET    [n].[months_in_dcp] = [mm].[MonthsInDCP] ,
               [n].[active_indicator_for_rollforward] = CASE WHEN ISNULL(
                                                                            CONVERT(
                                                                                       VARCHAR(12) ,
                                                                                       [m].[MaxPaymStart],
                                                                                       101
                                                                                   ) ,
                                                                            'N'
                                                                        ) = 'N' THEN
                                                                 'N'
                                                             ELSE 'Y'
                                                        END ,
               [n].[esrd] = ( CASE WHEN [n].[ra_factor_type] IN (   SELECT DISTINCT [RA_Type]
                                                                    FROM   [$(HRPReporting)].[dbo].[lk_RA_FACTOR_TYPES]
                                                                    WHERE  [Description] LIKE '%dialysis%'
                                                                           OR [Description] LIKE '%graft%'
                                                                ) THEN 'Y'
                                   ELSE 'N'
                              END
                            ) ,
               [n].[hosp] = ISNULL([b].[HOSP], 'N') ,
               [n].[pbp] = [b].[PBP] ,
               [n].[scc] = [b].[SCC] ,
               [n].[PartD_BID] = [b].[MABID1]
        FROM   [#new_hcc_output] [n]
               JOIN [#BidsRollup] [b] ON [n].[hicn] = [b].[HICN]
                                         AND [n].[paymstart] = [b].[PaymStart]
                                         AND [n].[payment_year] = [b].[PaymentYear]
               LEFT JOIN [#BidsRollupMaxPaymStart] [m] ON [n].[payment_year] = [m].[PaymYear]
                                                          AND [n].[paymstart] = [m].[MaxPaymStart]
               LEFT JOIN [#MemberMonthRollupAltHICN] [mm] ON [n].[hicn] = [mm].[HICN]
                                                             AND CASE WHEN YEAR(GETDATE()) < [mm].[PaymYear] THEN
                                                                          [n].[PaymStartYear]
                                                                      ELSE
                                                                          [n].[PaymStartYear]
                                                                          - 1
                                                                 END = [mm].[PaymYear]
               LEFT JOIN [#BidsRollupHICNMaxPaymStart] [mmm] ON [n].[hicn] = [mmm].[HICN]
                                                                AND [n].[PaymStartYear] = [mmm].[PaymYear]
                                                                AND [n].[paymstart] = [mmm].[MaxPaymStart]






        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '029' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        --Fix ESRD rates - Ticket # 25188 End
        UPDATE [h]
        SET    [h].[hcc_description] = [f].[Description]
        FROM   [#new_hcc_output] [h]
               INNER JOIN [$(HRPReporting)].[dbo].[lk_Factors_PartD] [f] ON SUBSTRING(
                                                                                      [h].[hcc] ,
                                                                                      5 ,
                                                                                      LEN([h].[hcc])
                                                                                  ) = [f].[HCC_Label]
               INNER JOIN [#Refresh_PY] [py] ON [f].[payment_year] = CAST([py].[Payment_Year] AS CHAR(4))
        WHERE  [h].[ra_factor_type] IN ( 'D1', 'D2', 'D3' )
               AND [f].[payment_year] = CAST([py].[Payment_Year] AS CHAR(4))

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '030' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        UPDATE [h]
        SET    [h].[hcc_description] = [f].[Description]
        FROM   [#new_hcc_output] [h]
               INNER JOIN [$(HRPReporting)].[dbo].[lk_Factors_PartD] [f] ON [h].[hcc] = [f].[HCC_Label]
               INNER JOIN [#Refresh_PY] [py] ON [f].[payment_year] = CAST([py].[Payment_Year] AS CHAR(4))
        WHERE  [h].[ra_factor_type] IN ( 'D1', 'D2', 'D3' )









        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '034' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        UPDATE [HCCOP]
        SET    [HCCOP].[estimated_value] = ROUND(
                                                    [HCCOP].[PartD_BID]
                                                    * ( [HCCOP].[member_months] )
                                                    * ROUND(
                                                               ( [HCCOP].[factor]
                                                                 - ISNULL(
                                                                             [HCCOP].[hier_factor_old] ,
                                                                             0
                                                                         )
                                                               )
                                                               / [py].[PartD_Factor] ,
                                                               3
                                                           ) ,
                                                    2
                                                )
        FROM   [#new_hcc_output] [HCCOP]
               INNER JOIN [#Refresh_PY] [py] ON [HCCOP].payment_year = [py].[Payment_Year]
                                                AND [HCCOP].[hcc] NOT LIKE '%REMOVE%'
                                                AND ISNULL(HCCOP.hosp, 'N') <> 'Y'


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '035' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        /*****************************************************************************************************************/


        IF ( OBJECT_ID('tempdb.dbo.#ProviderId') IS NOT NULL )
            BEGIN
                DROP TABLE [#ProviderId]
            END


        CREATE TABLE [#ProviderId]
            (
                [Id] INT IDENTITY(1, 1) PRIMARY KEY ,
                [Provider_Id] VARCHAR(40) ,
                [Last_Name] VARCHAR(55) ,
                [First_Name] VARCHAR(55) ,
                [Group_Name] VARCHAR(80) ,
                [Contact_Address] VARCHAR(100) ,
                [Contact_City] VARCHAR(30) ,
                [Contact_State] CHAR(2) ,
                [Contact_Zip] VARCHAR(13) ,
                [Work_Phone] VARCHAR(15) ,
                [Work_Fax] VARCHAR(15) ,
                [Assoc_Name] VARCHAR(55) ,
                [NPI] VARCHAR(10)
            )


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '036' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        SET @SQL = '	INSERT  INTO [#ProviderId]
					(
					 [Provider_ID]
				   , [Last_Name]
				   , [First_Name]
				   , [Group_Name]
				   , [Contact_Address]
				   , [Contact_City]
				   , [Contact_State]
				   , [Contact_Zip]
				   , [Work_Phone]
				   , [Work_Fax]
				   , [Assoc_Name]
				   , [NPI]
					)
			SELECT
				[u].[Provider_ID]
			  , [u].[Last_Name]
			  , [u].[First_Name]
			  , [u].[Group_Name]
			  , [u].[Contact_Address]
			  , [u].[Contact_City]
			  , [u].[Contact_State]
			  , [u].[Contact_Zip]
			  , [u].[Work_Phone]
			  , [u].[Work_Fax]
			  , [u].[Assoc_Name]
			  , [u].[NPI]
			FROM  ' + @Clnt_DB
                   + '.[dbo].[tbl_provider_Unique] u
			ORDER BY
				u.[Provider_ID] '

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '036.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        EXEC ( @SQL )


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '037' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        /************************************************************************************************/

        UPDATE [n]
        SET    [n].[provider_last] = [u].[Last_Name] ,
               [n].[provider_first] = [u].[First_Name] ,
               [n].[provider_group] = [u].[Group_Name] ,
               [n].[provider_address] = [u].[Contact_Address] ,
               [n].[provider_city] = [u].[Contact_City] ,
               [n].[provider_state] = [u].[Contact_State] ,
               [n].[provider_zip] = [u].[Contact_Zip] ,
               [n].[provider_phone] = [u].[Work_Phone] ,
               [n].[provider_fax] = [u].[Work_Fax] ,
               [n].[tax_id] = [u].[Assoc_Name] ,
               [n].[npi] = [u].[NPI]
        FROM   [#new_hcc_output] [n]
               INNER JOIN [#ProviderId] [u] ON [n].[provider_id] = [u].[Provider_Id]

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '038' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        IF OBJECT_ID('[TEMPDB].[DBO].[#rollforward_months]', 'U') IS NOT NULL
            DROP TABLE [dbo].[#rollforward_months]

        CREATE TABLE [dbo].[#rollforward_months]
            (
                [paymentyear] INT ,
                [hicn] VARCHAR(15) ,
                [member_months] INT ,
                [max_roll_frwd_mth] INT
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '039' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END




        INSERT INTO [#rollforward_months] (   [paymentyear] ,
                                              [hicn] ,
                                              [member_months]
                                          )
                    SELECT   [paymentyear] = [payment_year] ,
                             [hicn] ,
                             [member_months] = COUNT(DISTINCT [paymstart])
                    FROM     [#new_hcc_output]
                    GROUP BY [payment_year] ,
                             [hicn]



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '040' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        IF OBJECT_ID('[TEMPDB].[DBO].[#max_member_months]', 'U') IS NOT NULL
            DROP TABLE [dbo].[#max_member_months]

        CREATE TABLE [dbo].[#max_member_months]
            (
                [paymentyear] INT ,
                [hicn] VARCHAR(15) ,
                [mx_mm] INT
            )

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '040.1' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        INSERT INTO [#max_member_months] (   [paymentyear] ,
                                             [hicn] ,
                                             [mx_mm]
                                         )
                    SELECT   [rf].[paymentyear] ,
                             [rf].[hicn] ,
                             MAX([rf].[member_months]) AS [mx_mm]
                    FROM     [#rollforward_months] [rf]
                    GROUP BY [rf].[paymentyear] ,
                             [rf].[hicn]


        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '040.2' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END



        UPDATE [p]
        SET    [max_roll_frwd_mth] = CASE WHEN [p].[paymentyear] < YEAR(GETDATE()) THEN
                                              12
                                          ELSE [t].[mx_mm]
                                     END
        FROM   [#rollforward_months] [p]
               INNER JOIN [#max_member_months] [t] ON [p].[hicn] = [t].[hicn]
                                                      AND [p].[paymentyear] = [t].[paymentyear]








        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '041' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END

        /* Truncate the [etl].[ERPartDDeleteHCCOutput] Table */

        IF  (   SELECT COUNT(1)
                FROM   [etl].[ERPartDDeleteHCCOutput]
            ) > 0
            BEGIN
                TRUNCATE TABLE [etl].[ERPartDDeleteHCCOutput]
            END



        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '046' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END


        INSERT INTO [etl].[ERPartDDeleteHCCOutput] (   [Paymentyear] ,
                                                       [Modelyear] ,
                                                       [ProcessedbyStart] ,
                                                       [ProcessedbyEnd] ,
                                                       [ProcessedbyFlag] ,
                                                       [InMOR] ,
                                                       [PlanID] ,
                                                       [HICN] ,
                                                       [RAFactorType] ,
                                                       [RxHCC] ,
                                                       [RxHCCDescription] ,
                                                       [Factor] ,
                                                       [HIERRxHCCOld] ,
                                                       [HIERFactorOld] ,
                                                       [MemberMonths] ,
                                                       [BID] ,
                                                       [EstimatedValue] ,
                                                       [RollforwardMonths] ,
                                                       [AnnualizedEstimatedValue] ,
                                                       [MonthsinDCP] ,
                                                       [ESRD] ,
                                                       [HOSP] ,
                                                       [PBP] ,
                                                       [SCC] ,
                                                       [ProcessedPriorityProcessedby] ,
                                                       [ProcessedPriorityThrudate] ,
                                                       [ProcessedPriorityPCN] ,
                                                       [ProcessedPriorityDiag] ,
                                                       [ThruPriorityProcessedby] ,
                                                       [ThruPriorityThruDate] ,
                                                       [ThruPriorityPCN] ,
                                                       [ThruPriorityDiag] ,
                                                       [RAPSSource] ,
                                                       [ProviderID] ,
                                                       [ProviderLast] ,
                                                       [ProviderFirst] ,
                                                       [ProviderGroup] ,
                                                       [ProviderAddress] ,
                                                       [ProviderCity] ,
                                                       [ProviderState] ,
                                                       [ProviderZip] ,
                                                       [ProviderPhone] ,
                                                       [ProviderFax] ,
                                                       [TaxID] ,
                                                       [NPI] ,
                                                       [SweepDate] ,
                                                       [PopulatedDate] ,
                                                       [AgedStatus] ,
                                                       [LoadDate] ,
                                                       [UserID]
                                                   )
                    SELECT   [Paymentyear] = [n].[payment_year] ,
                             [Modelyear] = [n].[model_year] ,
                             [ProcessedbyStart] = [n].[processed_by_start] ,
                             [ProcessedbyEnd] = [n].[processed_by_end] ,
                             [ProcessedbyFlag] = CASE WHEN [n].[processed_priority_processed_by]
                                                           BETWEEN [py].[From_Date] AND [py].[InitialFlag] THEN
                                                          'I'
                                                      WHEN [n].[processed_priority_processed_by]
                                                           BETWEEN DATEADD(
                                                                              dd ,
                                                                              1 ,
                                                                              [py].[InitialFlag]
                                                                          ) AND [py].[MyuFlag] THEN
                                                          CASE WHEN CAST(SUBSTRING(
                                                                                      [n].[in_mor_max_month] ,
                                                                                      5 ,
                                                                                      2
                                                                                  )
                                                                         + '/01/'
                                                                         + SUBSTRING(
                                                                                        [n].[in_mor_max_month] ,
                                                                                        1 ,
                                                                                        4
                                                                                    ) AS DATE) >= CAST(( RIGHT([mo].[PayMth], 2)
                                                                                                         + '/01/'
                                                                                                         + CAST([py].Payment_Year AS VARCHAR(4))
                                                                                                       ) AS DATE) THEN
                                                                   'F'
                                                               ELSE 'M'
                                                          END --#43205 Change to >= 08 with Variable
                                                      WHEN [n].[processed_priority_processed_by]
                                                           BETWEEN DATEADD(
                                                                              dd ,
                                                                              1 ,
                                                                              [py].[MyuFlag]
                                                                          ) AND [py].[FinalFlag] THEN
                                                          'F'
                                                 END ,
                             [InMOR] = [n].[in_mor] ,
                             [PlanID] = [rp].[planid] ,
                             [HiCN] = [n].[hicn] ,
                             [RAFactorType] = [n].[ra_factor_type] ,
                             [RxHCC] = [n].[hcc] ,
                             [RxHCCDescription] = [n].[hcc_description] ,
                             [factor] = ISNULL([n].[factor], 0) ,
                             [HIERRxHCCOld] = [n].[hier_hcc_old] ,
                             [HIERFactorOld] = ISNULL([n].[hier_factor_old], 0) ,
                             [MemberMonths] = COUNT(DISTINCT [n].[paymstart]) ,
                             [BID] = ISNULL([n].[PartD_BID], 0) ,
                             [EstimatedValue] = ISNULL(
                                                          SUM([n].[estimated_value]) ,
                                                          0
                                                      ) * -1 ,
                             [RollforwardMonths] = CASE WHEN [r].[member_months] = [r].[max_roll_frwd_mth] THEN
                                                            12
                                                            - [r].[member_months]
                                                        ELSE 0
                                                   END ,
                             [AnnualizedEstimatedValue] = ISNULL(
                                                                    ( SUM([n].[estimated_value])
                                                                      + ( CASE WHEN [r].[member_months] = [r].[max_roll_frwd_mth] THEN
                                                                                   12
                                                                                   - [r].[member_months]
                                                                               ELSE
                                                                                   0
                                                                          END
                                                                        )
                                                                      * ( SUM([n].[estimated_value])
                                                                          / [r].[member_months]
                                                                        )
                                                                    ) ,
                                                                    0
                                                                ) * -1 ,
                             [MonthsinDCP] = ISNULL([n].[months_in_dcp], 0) ,
                             ISNULL([n].[esrd], 'N') ,
                             ISNULL([n].[hosp], 'N') ,
                             [n].[pbp] ,
                             ISNULL([n].[scc], 'OOA') ,
                             [ProcessedPriorityProcessedby] = [n].[processed_priority_processed_by] ,
                             [ProcessedPriorityThrudate] = [n].[processed_priority_thru_date] ,
                             [ProcessedPriorityPCN] = [n].[processed_priority_pcn] ,
                             [ProcessedPriorityDiag] = [n].[processed_priority_diag] ,
                             [ThruPriorityProcessedby] = [n].[thru_priority_processed_by] ,
                             [ThruPriorityThruDate] = [n].[thru_priority_thru_date] ,
                             [n].[thru_priority_pcn] ,
                             [n].[thru_priority_diag] ,
                             [n].[raps_source] ,
                             [n].[provider_id] ,
                             [n].[provider_last] ,
                             [n].[provider_first] ,
                             [n].[provider_group] ,
                             [n].[provider_address] ,
                             [n].[provider_city] ,
                             [n].[provider_state] ,
                             [n].[provider_zip] ,
                             [n].[provider_phone] ,
                             [n].[provider_fax] ,
                             [n].[tax_id] ,
                             [n].[npi] ,
                             CASE WHEN n.UnionQueryInd = 1 THEN
                                      [py].[InitialFlag]
                                  WHEN n.UnionQueryInd = 2 THEN [py].[MyuFlag]
                                  WHEN n.UnionQueryInd = 3 THEN
                                      [py].[FinalFlag]
                             END ,
                             [PopulatedDate] = GETDATE() ,
                             [AgedStatus] = CASE WHEN [n].[AGED] = 1 THEN
                                                     'Aged'
                                                 WHEN [n].[AGED] = 0 THEN
                                                     'Disabled'
                                                 ELSE 'Not Applicable'
                                            END ,
                             @Today AS [LoadDate] ,
                             SUSER_NAME() AS [UserID]
                    FROM     [#new_hcc_output] [n]
                             LEFT JOIN [#rollforward_months] [r] ON [n].[hicn] = [r].[hicn]
                                                                    AND [n].[payment_year] = [r].[paymentyear]
                             INNER JOIN [#Refresh_PY] [py] ON [n].[payment_year] = [py].[Payment_Year]
                             LEFT JOIN [#Paymonth_MOR] [mo] ON CAST([n].[payment_year] AS CHAR(4)) = [mo].[PayYr]
                             LEFT JOIN [$(HRPInternalReportsDB)].[dbo].[RollupPlan] [rp] ON [n].[planidentifier] = [rp].[planidentifier]
                    WHERE    (   [n].[processed_priority_processed_by]
                             BETWEEN [py].[From_Date] AND @thrudate
                                 OR (   CAST(SUBSTRING(
                                                          [n].[in_mor_max_month] ,
                                                          5 ,
                                                          2
                                                      ) + '/01/'
                                             + SUBSTRING(
                                                            [n].[in_mor_max_month] ,
                                                            1 ,
                                                            4
                                                        ) AS DATE) >= CAST(( RIGHT([mo].[PayMth], 2)
                                                                             + '/01/'
                                                                             + CAST([py].Payment_Year AS VARCHAR(4))
                                                                           ) AS DATE) --#43205 Change to >= 08 with Variable
                                        AND [n].[processed_priority_processed_by]
                             BETWEEN DATEADD(dd, 1, [py].[InitialFlag]) AND [py].[MyuFlag]
                                    )
                             )
                             AND [n].[hcc] NOT LIKE 'HIER%'
                    GROUP BY [n].[payment_year] ,
                             [n].[model_year] ,
                             [n].[processed_by_start] ,
                             [n].[processed_by_end] ,
                             [rp].[planid] ,
                             [n].[in_mor] ,
                             [n].[hicn] ,
                             [n].[ra_factor_type] ,
                             [n].[hcc] ,
                             [n].[hcc_description] ,
                             [n].[factor] ,
                             [n].[hier_hcc_old] ,
                             [n].[hier_factor_old] ,
                             n.[PartD_BID] ,
                             [r].[member_months] ,
                             [r].[max_roll_frwd_mth] ,
                             [n].[months_in_dcp] ,
                             [n].[esrd] ,
                             [n].[hosp] ,
                             [n].[pbp] ,
                             [n].[scc] ,
                             [n].[processed_priority_processed_by] ,
                             [n].[processed_priority_thru_date] ,
                             [n].[processed_priority_pcn] ,
                             [n].[processed_priority_diag] ,
                             [n].[thru_priority_processed_by] ,
                             [n].[thru_priority_thru_date] ,
                             [n].[thru_priority_pcn] ,
                             [n].[thru_priority_diag] ,
                             [n].[raps_source] ,
                             [n].[provider_id] ,
                             [n].[provider_last] ,
                             [n].[provider_first] ,
                             [n].[provider_group] ,
                             [n].[provider_address] ,
                             [n].[provider_city] ,
                             [n].[provider_state] ,
                             [n].[provider_zip] ,
                             [n].[provider_phone] ,
                             [n].[provider_fax] ,
                             [n].[tax_id] ,
                             [n].[npi] ,
                             [n].[in_mor_max_month] ,
                             CASE WHEN [n].[processed_priority_processed_by]
                                       BETWEEN [py].[From_Date] AND [py].[InitialFlag] THEN
                                      [py].[InitialFlag]
                                  WHEN [n].[processed_priority_processed_by]
                                       BETWEEN DATEADD(
                                                          dd ,
                                                          1 ,
                                                          [py].[InitialFlag]
                                                      ) AND [py].[MyuFlag] THEN
                                      CASE WHEN CAST(SUBSTRING(
                                                                  [n].[in_mor_max_month] ,
                                                                  5 ,
                                                                  2
                                                              ) + '/01/'
                                                     + SUBSTRING(
                                                                    [n].[in_mor_max_month] ,
                                                                    1 ,
                                                                    4
                                                                ) AS DATE) >= CAST(( RIGHT([mo].[PayMth], 2)
                                                                                     + '/01/'
                                                                                     + CAST([py].Payment_Year AS VARCHAR(4))
                                                                                   ) AS DATE) THEN
                                               [py].[FinalFlag]
                                           ELSE [py].[MyuFlag]
                                      END --#43205 Change to >= 08 with Variable
                                  WHEN [n].[processed_priority_processed_by]
                                       BETWEEN DATEADD(dd, 1, [py].[MyuFlag]) AND [py].[FinalFlag] THEN
                                      [py].[FinalFlag]
                             END ,
                             [n].[AGED] ,
                             [py].[From_Date] ,
                             [py].[InitialFlag] ,
                             [py].[MyuFlag] ,
                             [py].[Payment_Year] ,
                             [py].[FinalFlag] ,
                             [mo].[PayMth] ,
                             [n].[UnionQueryInd]

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '047' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END




        DROP TABLE [#RollupPlan]
        DROP TABLE [#new_hcc_output]
        DROP TABLE [#ProviderId]
        DROP TABLE [#New_HCC_rollup]
        DROP TABLE [#AltHICN]

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '057' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            1

            END

        /* Switch partitions for each PaymentYear */

        IF EXISTS (   SELECT TOP 1 1
                      FROM   [etl].[ERPartDDeleteHCCOutput]
                  )
            BEGIN

                DECLARE @I INT
                DECLARE @ID INT = (   SELECT COUNT(DISTINCT [Payment_Year])
                                      FROM   [#Refresh_PY]
                                  )

                SET @I = 1

                WHILE ( @I <= @ID )
                    BEGIN

                        DECLARE @PaymentYear INT = (   SELECT [Payment_Year]
                                                       FROM   [#Refresh_PY]
                                                       WHERE  Id = @I
                                                   )

                        PRINT 'Starting Partition Switch For PaymentYear : '
                              + CONVERT(VARCHAR(4), @PaymentYear)

                        BEGIN TRY

                            BEGIN TRANSACTION SwitchPartitions;

                            TRUNCATE TABLE [out].[ERPartDDeleteHCCOutput]

                            -- Switch Partition for History SummaryPartDRskAdjRAPS 
                            ALTER TABLE [hst].[ERPartDDeleteHCCOutput] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [out].[ERPartDDeleteHCCOutput] PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                            -- Switch Partition for DBO SummaryPartDRskAdjRAPS 
                            ALTER TABLE [rev].[ERPartDDeleteHCCOutput] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [hst].[ERPartDDeleteHCCOutput] PARTITION $Partition.[pfn_SummPY](@PaymentYear)

                            -- Switch Partition for ETL SummaryPartDRskAdjRAPS	

							 INSERT INTO [rev].[EstRecvRskadjActivity]
								(
									[Part_C_D_Flag],
									[Process],
									[Payment_Year], 
									[MYU],
									[BDate],
									[EDate],
									[AdditionalRows],
									[RunBy]
								)
								SELECT [Part_C_D_Flag] = 'Part D',
									   [Process] = 'EstRecvPartDDeleteHCC',
									   [Payment_Year] = @PaymentYear, 
									   [MYU]=NULL,
									   [BDate] = GETDATE(),
									   [EDate] = NULL,
									   [AdditionalRows] = NULL,
									   [RunBy] = @UserID;

									SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
									SET @RowCount_OUT = 0;
		

                            ALTER TABLE [etl].[ERPartDDeleteHCCOutput] SWITCH PARTITION $Partition.[pfn_SummPY](@PaymentYear)TO [rev].[ERPartDDeleteHCCOutput] PARTITION $Partition.[pfn_SummPY](@PaymentYear)

							Set @RowCount_OUT = @@Rowcount

						   UPDATE [m]
								SET [m].[EDate] = GETDATE(),
									[m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
								FROM [rev].[EstRecvRskadjActivity] [m]
								WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;

                            COMMIT TRANSACTION SwitchPartitions;

                            PRINT 'Partition Completed For PaymentYear : '
                                  + CONVERT(VARCHAR(4), @PaymentYear)

                        END TRY
                        BEGIN CATCH

                            SELECT @ErrorMessage = ERROR_MESSAGE() ,
                                   @ErrorSeverity = ERROR_SEVERITY() ,
                                   @ErrorState = ERROR_STATE();

                            IF (   XACT_STATE() = 1
                                   OR XACT_STATE() = -1
                               )
                                BEGIN
                                    ROLLBACK TRANSACTION SwitchPartitions;
                                END;

                            RAISERROR(
                                         @ErrorMessage ,
                                         @ErrorSeverity ,
                                         @ErrorState
                                     );

                            RETURN;

                        END CATCH;

                        SET @I = @I + 1

                    END

            END
        ELSE
            PRINT 'Partition switching did not run because there was no data was loaded in the ETL table'

        IF @Debug = 1
            BEGIN
                EXEC [dbo].[PerfLogMonitor] '058' ,
                                            @ProcessNameIn ,
                                            @ET ,
                                            @MasterET ,
                                            @ET OUT ,
                                            0 ,
                                            0
            END






        IF @Debug = 1
            BEGIN
                PRINT '@Clnt_Rpt_DB = ' + ISNULL(@Clnt_Rpt_DB, '')
                PRINT '@ClntPlan_DB = ' + ISNULL(@ClntPlan_DB, '')
                PRINT '@Clnt_Rpt_Srv = ' + ISNULL(@Clnt_Rpt_Srv, '')
                PRINT '@Clnt_DB = ' + ISNULL(@Clnt_DB, '')
                PRINT '@ClntName = ' + ISNULL(@ClntName, '')
            END


    END

