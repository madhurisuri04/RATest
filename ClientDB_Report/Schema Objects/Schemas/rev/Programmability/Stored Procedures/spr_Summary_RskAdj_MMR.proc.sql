CREATE PROCEDURE [rev].[spr_Summary_RskAdj_MMR]
    @FullRefresh BIT = 0,
    @YearRefresh INT = NULL,
    @LoadDateTime DATETIME = NULL,
    @DeleteBatch INT = NULL,
    @RowCount INT OUT,
    @Debug BIT = 0
AS
/************************************************************************************************ 
* Name			:	rev.spr_Summary_RskAdj_MMR														*
* Type 			:	Stored Procedure																*
* Author       	:	Mitch Casto																		*
* Date			:	2016-03-21																		*
* Version			:																				*
* Description		: Updates rev.tbl_Summary_RskAdj_MMR table with MMR data						*
*					Note: This stp is an adaptation from Summary 1.0 and will need further work to	*
*					optimize the sql.																*
*																									*
* Version History :																					*
*                                                                                                   *
* =================================================================================================	*
* Author			Date		Version#    TFS Ticket#		Description								*
* -----------------	----------  --------    -----------		------------							*
* Mitch Casto		2016-03-21	1.0			52224			Initial									*
* David Waddell		2016-04-12  1.1			52224			Remove the Do While Logic				* 
* Mitch Casto		2016-05-18	1.1			53367			Move results to permanent table			*
*															Add @ManualRun to remove requirment for	*
*															table ownership for Truncation when run	*
*															manually								*
*																									*
* David Waddell     2016-09-08 1.2          55925			perform daily kill and fill of result   *
*															table based on the Payment Year         *
*															by the Refresh PY   (US53053).          *
*                                                                                                   * 
* David Waddell		2017-01-12  1.3			US60182			Add MedicaidDualStatusCode to           *
*															#Member_Months_rollup and               * 
*															Tbl_Summary_RskAdj_MMR                  *
* David Waddell     2017-03-01  1.4			62757			Synchronizing Summary 2.0 to current    *
*															Summary - MMR spr                       *
* Mitch Casto		2017-03-27	1.5			63302/US63790	Removed @ManualRun process and replaced *
*															with parameterized delete batch			*
*															(Section 017 to 020)					*
*Madhuri Suri       2017-06-06              65131           OREC and Medicaid restated for ER       *
*                                                            Aged logic corrected 					*																
*			                                                                                        *
*																									*
* David Waddell     2017-10-18               67406/RE-1146  Insert Part D data infto MMR Summary    *
8                                                           Table (Sections 13,14,21,28,35.1-35.4)  *
*                                                                                                   * 
* David Waddell     2017-12-08               67944/RE-1214  Add PartDRAFactor in Summary MMR table  *
*                                                            Sect. 13,14,21,28                      * 
* David Waddell     2018-01-22               69098/RE1278   Insert PartDAged data into MMR Summary  *
*                                                           Section 35.6                            *
*Madhuri Suri      2018-12-03                74294        Part D Deefect Correction                 * 
                                                          => OREC Restated Cirrection               *
*Madhuri Suri       2019-01-10               74677         Adding Part D Total Payment column       * 
* D.Waddell		   10/29/2019	    		RE-6981		Set Transaction Isolation Level Read to     *
*                                                       Uncommitted                                 * 
* Anand             2021-02-08				 RRI-642/80728  Update MMR Bid Logic					*
* Anand				2021-03-01				 RRI-725/80885  Adding Part D BID Column and update from BIDS Rollup table*
****************************************************************************************************/
BEGIN

    SET STATISTICS IO OFF;
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;




    IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;
        DECLARE @ET DATETIME;
        DECLARE @MasterET DATETIME;
        DECLARE @ProcessNameIn VARCHAR(128)
        DECLARE @EDSloaddateSQL VARCHAR(MAX);
		DECLARE @MaxESRDPY INT;
		DECLARE @currentyear INT = YEAR(GETDATE());
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

    SET @LoadDateTime = ISNULL(@LoadDateTime, GETDATE());
    SET @DeleteBatch = ISNULL(@DeleteBatch, 100000);

    DECLARE @Payment_year INT = YEAR(GETDATE());




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


    --HMF 8/1/2016 Notes: 
    --After implementing rev.spr_Summary_RskAdj_RefreshPY there is no need for this temp table anymore, 
    --but due to legacy coding already in place the simpler approach of keeping the table joins intact and copying 
    --the newly created permanent table into this temp table is being applied. 
    --This temp table is now a carbon copy of rev.tbl_Summary_RskAdj_RefreshPY.

    CREATE TABLE [#Refresh_PY]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [Payment_Year] INT,
        [From_Date] DATE,
        [Thru_Date] DATE,
        [Lagged_From_Date] DATE,
        [Lagged_Thru_Date] DATE
    );

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

    INSERT INTO [#Refresh_PY]
    (
        [Payment_Year],
        [From_Date],
        [Thru_Date],
        [Lagged_From_Date],
        [Lagged_Thru_Date]
    )
    SELECT [Payment_Year] = [a1].[Payment_Year],
           [From_Date] = [a1].[From_Date],
           [Thru_Date] = [a1].[Thru_Date],
           [Lagged_From_Date] = [a1].[Lagged_From_Date],
           [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
    FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1];




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


    IF OBJECT_ID('tempdb.dbo.#tmp_LaggedDCPMMR') IS NOT NULL
    BEGIN
        DROP TABLE [#tmp_LaggedDCPMMR];
    END;

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

    CREATE TABLE [#tmp_LaggedDCPMMR]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [HICN] VARCHAR(12),
        [PaymentYear] INT,
        [DCP] INT
    );

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

    IF OBJECT_ID('tempdb.dbo.#tmp_DCPMMR') IS NOT NULL
    BEGIN
        DROP TABLE [#tmp_DCPMMR];
    END;

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

    CREATE TABLE [#tmp_DCPMMR]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [HICN] VARCHAR(12),
        [RAFT] VARCHAR(2),
        [PaymentYear] INT,
        [DCP] INT
    );

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

    DECLARE @maxMonth INT;

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


    /* Insert into #tmp_LaggedCMPMMR table  TFS 52224  */
    INSERT INTO [#tmp_LaggedDCPMMR]
    (
        [HICN],
        [PaymentYear],
        [DCP]
    )
    SELECT [HICN] = ISNULL([althcn].[FINALHICN], [t1].[HICN]),
           [PaymentYear] = [rp].[Payment_Year],
           [DCP] = COUNT(DISTINCT [t1].[PaymStart])
    FROM [dbo].[tbl_Member_Months_rollup] [t1]
        LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
            ON [t1].[PlanIdentifier] = [althcn].[PlanID]
               AND [t1].[HICN] = [althcn].[HICN]
        LEFT JOIN [#Refresh_PY] [rp]
            ON ([t1].[PaymStart]
               BETWEEN [rp].[Lagged_From_Date] AND [rp].[Lagged_Thru_Date]
               )
    GROUP BY ISNULL([althcn].[FINALHICN], [t1].[HICN]),
             [rp].[Payment_Year];


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


    /* Insert into #tmp_DCPMMR table TFS 52224 */

    INSERT INTO [#tmp_DCPMMR]
    (
        [HICN],
        [RAFT],
        [PaymentYear],
        [DCP]
    )
    SELECT [HICN] = ISNULL([althcn].[FINALHICN], [t1].[HICN]),
           [RA_Factor_Type] = [t1].[RA_Factor_Type],
           [PaymentYear] = [rpy].[Payment_Year],
           [DCP] = COUNT(DISTINCT [t1].[PaymStart])
    FROM [dbo].[tbl_Member_Months_rollup] [t1]
        LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
            ON [t1].[PlanIdentifier] = [althcn].[PlanID]
               AND [t1].[HICN] = [althcn].[HICN]
        LEFT JOIN [#Refresh_PY] [rpy]
            ON ([t1].[PaymStart]
               BETWEEN [rpy].[From_Date] AND [rpy].[Thru_Date]
               )
    WHERE [t1].[RA_Factor_Type] = 'E'
    GROUP BY ISNULL([althcn].[FINALHICN], [t1].[HICN]),
             [t1].[RA_Factor_Type],
             [rpy].[Payment_Year]
    UNION
    SELECT [HICN] = ISNULL([althcn].[FINALHICN], [t1].[HICN]),
           [RA_Factor_Type] = [t1].[RA_Factor_Type],
           [PaymentYear] = [rpy2].[Payment_Year],
           [DCP] = COUNT(DISTINCT [t1].[PaymStart])
    FROM [dbo].[tbl_Member_Months_rollup] [t1]
        LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
            ON [t1].[PlanIdentifier] = [althcn].[PlanID]
               AND [t1].[HICN] = [althcn].[HICN]
        JOIN [#Refresh_PY] [rpy2]
            ON ([t1].[PaymStart]
               BETWEEN [rpy2].[From_Date] AND [rpy2].[Thru_Date]
               )
    WHERE (
              [t1].[RA_Factor_Type] <> 'E'
              OR [t1].[RA_Factor_Type] IS NULL
          )
    GROUP BY ISNULL([althcn].[FINALHICN], [t1].[HICN]),
             [t1].[RA_Factor_Type],
             [rpy2].[Payment_Year];



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


    IF NOT EXISTS
    (
        SELECT 1
        FROM [sys].[indexes]
        WHERE [name] LIKE 'ix_tmp_DCPMMR_HICN%'
    )
    BEGIN

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '011',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

        CREATE NONCLUSTERED INDEX [ix_tmp_DCPMMR_HICN]
        ON [#tmp_DCPMMR] (
                             [HICN],
                             [RAFT],
                             [PaymentYear]
                         );

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '012',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

    END;


    IF (OBJECT_ID('tempdb.dbo.#Member_Months_rollup') IS NOT NULL)
    BEGIN
        DROP TABLE [#Member_Months_rollup];
    END;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '013',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    CREATE TABLE [#Member_Months_rollup]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [PlanIdentifier] [SMALLINT] NOT NULL,
        [HICN] [VARCHAR](12) NOT NULL,
        [PaymentYear] [INT] NOT NULL,
        [PaymStart] [SMALLDATETIME] NULL,
        [Sex] [VARCHAR](1) NULL,
        [RskAdjAgeGrp] [VARCHAR](4) NULL,
        [RA_Factor_Type] [VARCHAR](2) NULL,
        [DefaultInd] [VARCHAR](1) NULL,
        [OREC] [VARCHAR](1) NULL,
        [MedicAddOn] [VARCHAR](1) NULL,
        [Medicaid] [VARCHAR](1) NULL,
        [RskadjFctrA] [DECIMAL](19, 4) NULL,
        [SCC] [VARCHAR](5) NULL,
        [PBP] [VARCHAR](3) NULL,
        [OOA] [VARCHAR](1) NULL,
        [Part_A_Monthly_Payment_Rate] [SMALLMONEY] NULL,
        [Part_B_Monthly_Payment_Rate] [SMALLMONEY] NULL,
        [Hosp] [VARCHAR](1) NULL,
        [MSPFactor] [DECIMAL](9, 4) NULL,
        [TotalPayment] [SMALLMONEY] NULL,
        [Total_MA_Payment_Amount] [SMALLMONEY] NULL,
        [RiskPymtA] [SMALLMONEY] NULL,
        [RiskPymtB] [SMALLMONEY] NULL,
        [ESRD] [VARCHAR](1) NULL,
        [Part_D_RA_Factor_Type] [VARCHAR](2) NULL,
        [Part_D_Low_Income_Indicator] [VARCHAR](1) NULL,
        [MedicaidDualStatusCode] [VARCHAR](2) NULL,           -- US60182
        [BeneficiaryCurrentMedicaidStatus] [VARCHAR](2) NULL, --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
        [AgeGrp] [VARCHAR](4) NULL,                           --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
        [LowIncomePremiumSubsidy] [SMALLMONEY] NULL,          --TFS 67406/RE-1146
        [PartDLowIncomeMultiplier] [DECIMAL](19, 2) NULL,
        [PartDBasicPremiumAmount] [SMALLMONEY] NULL,
        [PartDDirectSubsidyPaymentAmount] [SMALLMONEY] NULL,
        [PartDRAFTProjected] [CHAR](2) NULL,
        [PartDRAFactor] [DECIMAL](19, 4) NULL,                --67944/RE-1214
        [TotalPartDPayment] [SMALLMONEY] NULL
    );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '014',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    INSERT INTO [#Member_Months_rollup]
    (
        [PlanIdentifier],
        [HICN],
        [PaymentYear],
        [PaymStart],
        [Sex],
        [RskAdjAgeGrp],
        [RA_Factor_Type],
        [DefaultInd],
        [OREC],
        [MedicAddOn],
        [Medicaid],
        [RskadjFctrA],
        [SCC],
        [PBP],
        [OOA],
        [Part_A_Monthly_Payment_Rate],
        [Part_B_Monthly_Payment_Rate],
        [Hosp],
        [MSPFactor],
        [TotalPayment],
        [Total_MA_Payment_Amount],
        [RiskPymtA],
        [RiskPymtB],
        [ESRD],
        [Part_D_RA_Factor_Type],
        [Part_D_Low_Income_Indicator],
        [MedicaidDualStatusCode],           -- US60182
        [BeneficiaryCurrentMedicaidStatus], --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
        [AgeGrp],                           --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
        [LowIncomePremiumSubsidy],          --TFS 67406/RE-1146
        [PartDLowIncomeMultiplier],
        [PartDBasicPremiumAmount],
        [PartDDirectSubsidyPaymentAmount],
        [PartDRAFTProjected],
        [PartDRAFactor],                    --67944/RE-1214
        [TotalPartDPayment]
    )
    SELECT [mem].[PlanIdentifier],
           [mem].[HICN],
           [PaymentYear] = YEAR([mem].[PaymStart]),
           [mem].[PaymStart],
           [mem].[Sex],
           [mem].[RskAdjAgeGrp],
           [mem].[RA_Factor_Type],
           [mem].[DefaultInd],
           [mem].[OREC],
           [mem].[MedicAddOn],
           [mem].[Medicaid],
           [mem].[RskadjFctrA],
           [mem].[SCC],
           [mem].[pbp],
           [mem].[OOA],
           [mem].[Part_A_Monthly_Payment_Rate],
           [mem].[Part_B_Monthly_Payment_Rate],
           [mem].[Hosp],
           [mem].[MSPFactor],
           [mem].[TotalPayment],
           [mem].[Total_MA_Payment_Amount],
           [mem].[RiskPymtA],
           [mem].[RiskPymtB],
           [mem].[ESRD],
           [mem].[Part_D_RA_Factor_Type],
           [mem].[Part_D_Low_Income_Indicator],
           [MedicaidDualStatusCode] = [mem].[Medicaid_Dual_Status_Code],                     --  US60182
           [BeneficiaryCurrentMedicaidStatus] = [mem].[Beneficiary_Current_Medicaid_Status], --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
           [AgeGrp] = [mem].[AgeGrp],                                                        --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
           [LowIncomePremiumSubsidy] = [mem].[Low_Income_Premium_Subsidy],                   -- TFS 67406/RE-1146
           [PartDLowIncomeMultiplier] = [mem].[Part_D_Low_Income_Multiplier],
           [PartDBasicPremiumAmount] = [mem].[Part_D_Basic_Premium_Amount],
           [PartDDirectSubsidyPaymentAmount] = [mem].[Part_D_Direct_Subsidy_Payment_Amount],
           [PartDRAFTProjected] = [mem].[Part_D_RA_Factor_Type],
           [PartDRAFactor] = [mem].[Part_D_RA_Factor],
           [TotalPartDPayment] = [Total_Part_D_Payment]                                      --67944/RE-1214
    FROM [dbo].[tbl_Member_Months_rollup] [mem] WITH (NOLOCK)
    WHERE [mem].[HICN] IS NOT NULL
          AND YEAR([mem].[PaymStart]) IN
              (
                  SELECT DISTINCT [Payment_Year] FROM [#Refresh_PY]
              );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '015',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    CREATE NONCLUSTERED INDEX [IX_#Member_Months_rollup_]
    ON [#Member_Months_rollup] (
                                   [HICN],
                                   [SCC],
                                   [PBP],
                                   [PlanIdentifier],
                                   [PaymentYear]
                               );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '016',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;






    /*B Truncate Or Delete rows in rev.tbl_Summary_RskAdj_MMR */

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '017',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    --                TRUNCATE TABLE [rev].[tbl_Summary_RskAdj_MMR]

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '018',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '019',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    WHILE (1 = 1)
    BEGIN

        DELETE TOP (@DeleteBatch)
        FROM [rev].[tbl_Summary_RskAdj_MMR]
        WHERE [PaymentYear] IN
              (
                  SELECT [py].[Payment_Year] FROM [#Refresh_PY] [py]
              );

        IF @@ROWCOUNT = 0
            BREAK;
        ELSE
            CONTINUE;
    END;


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '020',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    /*E Truncate Or Delete rows in rev.tbl_Summary_RskAdj_MMR */

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '021',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    SET @RowCount = 0

    /**/;
    WITH [CTE_dcp]
    AS (SELECT [HICN] = [a1].[HICN],
               [PaymentYear] = [a1].[PaymentYear],
               [DCP] = SUM([a1].[DCP])
        FROM [#tmp_DCPMMR] [a1]
        GROUP BY [a1].[HICN],
                 [a1].[PaymentYear]), /**/
                                      /**/
         [CTE_lagdcp]
    AS (SELECT [HICN] = [lagdcp].[HICN],
               [PaymentYear] = [lagdcp].[PaymentYear],
               [DCP] = SUM([lagdcp].[DCP])
        FROM [#tmp_LaggedDCPMMR] [lagdcp]
        GROUP BY [lagdcp].[HICN],
                 [lagdcp].[PaymentYear])
    INSERT INTO [rev].[tbl_Summary_RskAdj_MMR]
    (
        [PlanID],
        [HICN],
        [PaymentYear],
        [PaymStart],
        [Gender],
        [RskAdjAgeGrp],
        [PartCRAFTProjected],
        [PartCRAFTMMR],
        [PartCDefaultIndicator],
        [ORECRestated],
        [ORECMMR],
        [MedicaidRestated],
        [MedicaidAddOnMMR],
        [MedicaidMMR],
        [PartCRiskScoreMMR],
        [SCC],
        [OOA],
        [PBP],
        [MABID],
        [PartAMonthlyPaymentRate],
        [PartBMonthlyPaymentRate],
        [HOSP],
        [MSPFactor],
        [MonthsInLaggedDCP],
        [MonthsInDCP],
        [TotalPayment],
        [TotalMAPaymentAmount],
        [RiskPymtA],
        [RiskPymtB],
        [ESRD],
        [PartDRAFTMMR],
        [PartDLowIncomeIndicator],
        [LoadDateTime],
        [PriorPaymentYear],
        [MedicaidDualStatusCode],           -- US60182
        [BeneficiaryCurrentMedicaidStatus], --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
        [AgeGrp],                           --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
        [LowIncomePremiumSubsidy],          --TFS 67406/RE-1146
        [RskadjFctrA],
        [PartDLowIncomeMultiplier],
        [PartDBasicPremiumAmount],
        [PartDDirectSubsidyPaymentAmount],
        [PartDRAFTProjected],
        [PartDRAFactor],                    --67944/RE-1214
        [TotalPartDPayment]
    )
    SELECT [PlanID] = [mem].[PlanIdentifier],
           [HICN] = ISNULL([althcn].[FINALHICN], [mem].[HICN]),
           [PaymentYear] = YEAR([mem].[PaymStart]),
           [PaymStart] = [mem].[PaymStart],
           [Gender] = CASE
                          WHEN [mem].[Sex] = 'm' THEN
                              1
                          WHEN [mem].[Sex] = 'f' THEN
                              2
                          ELSE
                              3
                      END,
           [RskAdjAgeGrp] = [mem].[RskAdjAgeGrp],
           [PartCRAFTProjected] = [mem].[RA_Factor_Type],
           [PartCRAFTMMR] = [mem].[RA_Factor_Type],
           [PartCDefaultIndicator] = [mem].[DefaultInd],
           [ORECRestated] = ISNULL([mem].[OREC], 0),
           [ORECMMR] = ISNULL([mem].[OREC], 0),
           [MedicaidRestated] = CASE
                                    WHEN [mem].[DefaultInd] IS NULL THEN
                                        [mem].[MedicAddOn]
                                    ELSE
                                        [mem].[Medicaid]
                                END,
           [MedicaidAddOnMMR] = [mem].[MedicAddOn],
           [MedicaidMMR] = [mem].[Medicaid],
           [PartCRiskScoreMMR] = [mem].[RskadjFctrA],
           [SCC] = [mem].[SCC],
           [OOA] = [mem].[OOA],
           [PBP] = [mem].[PBP],
           [MABID] = CASE
                         WHEN [mem].[OOA] = 'Y' THEN
                             [bid2].[MA_BID]
                         ELSE
                             [bid1].[MA_BID]
                     END,
           [PartAMonthlyPaymentRate] = [mem].[Part_A_Monthly_Payment_Rate],
           [PartBMonthlyPaymentRate] = [mem].[Part_B_Monthly_Payment_Rate],
           [HOSP] = [mem].[Hosp],
           [MSPFactor] = [mem].[MSPFactor],
           [MonthsInLaggedDCP] = ISNULL(SUM([lagdcp].[DCP]), 0),
           [MonthsInDCP] = ISNULL(SUM([dcp].[DCP]), 0),
           [TotalPayment] = [mem].[TotalPayment],
           [TotalMAPaymentAmount] = [mem].[Total_MA_Payment_Amount],
           [RiskPymtA] = [mem].[RiskPymtA],
           [RiskPymtB] = [mem].[RiskPymtB],
           [ESRD] = [mem].[ESRD],
           [PartDRAFTMMR] = [mem].[Part_D_RA_Factor_Type],
           [PartDLowIncomeIndicator] = CASE [mem].[Part_D_Low_Income_Indicator]
                                           WHEN 'N' THEN
                                               0
                                           WHEN 'Y' THEN
                                               1
                                       END,
           [LoadDateTime] = @LoadDateTime,
           [PriorPaymentYear] = YEAR([mem].[PaymStart]) - 1,
           [MedicaidDualStatusCode] = [mem].[MedicaidDualStatusCode],                     -- US60182
           [BeneficiaryCurrentMedicaidStatus] = [mem].[BeneficiaryCurrentMedicaidStatus], --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
           [AgeGrp] = [mem].[AgeGrp],                                                     --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
           [LowIncomePremiumSubsidy] = [mem].[LowIncomePremiumSubsidy],                   --TFS 67406/RE-1146
           [RskadjFctrA] = [mem].[RskadjFctrA],
           [PartDLowIncomeMultiplier] = [mem].[PartDLowIncomeMultiplier],
           [PartDBasicPremiumAmount] = [mem].[PartDBasicPremiumAmount],
           [PartDDirectSubsidyPaymentAmount] = [mem].[PartDDirectSubsidyPaymentAmount],
           [PartDRAFTProjected] = [mem].[PartDRAFTProjected],
           [PartDRAFactor] = [mem].[PartDRAFactor],
           [TotalPartDPayment] = [TotalPartDPayment]                                      --67944/RE-1214
    FROM [#Member_Months_rollup] [mem]
        LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
            ON [mem].[PlanIdentifier] = [althcn].[PlanID]
               AND [mem].[HICN] = [althcn].[HICN]
        LEFT JOIN [CTE_dcp] [dcp]
            ON ISNULL([althcn].[FINALHICN], [mem].[HICN]) = [dcp].[HICN]
               AND [mem].[PaymentYear] = [dcp].[PaymentYear]
        LEFT JOIN [CTE_lagdcp] [lagdcp]
            ON ISNULL([althcn].[FINALHICN], [mem].[HICN]) = [lagdcp].[HICN]
               AND [mem].[PaymentYear] = [lagdcp].[PaymentYear]
        LEFT JOIN [dbo].[tbl_BIDS_rollup] [bid1]
            ON [mem].[PlanIdentifier] = [bid1].[PlanIdentifier]
               AND [mem].[PaymentYear] = [bid1].[Bid_Year]
               AND [mem].[SCC] = [bid1].[SCC]
               AND [mem].[PBP] = [bid1].[PBP]
        LEFT JOIN [dbo].[tbl_BIDS_rollup] [bid2]
            ON [mem].[PlanIdentifier] = [bid2].[PlanIdentifier]
               AND [mem].[PaymentYear] = [bid2].[Bid_Year]
               AND [bid2].[SCC] = 'OOA'
               AND [mem].[PBP] = [bid2].[PBP]
    GROUP BY [mem].[PlanIdentifier],
             ISNULL([althcn].[FINALHICN], [mem].[HICN]),
             [mem].[PaymStart],
             [mem].[Sex],
             [mem].[RskAdjAgeGrp],
             [mem].[RA_Factor_Type],
             [mem].[DefaultInd],
             [mem].[OREC],
             [mem].[MedicAddOn],
             [mem].[Medicaid],
             [mem].[RskadjFctrA],
             [mem].[SCC],
             [mem].[OOA],
             [mem].[PBP],
             [bid1].[MA_BID],
             [bid2].[MA_BID],
             [mem].[Part_A_Monthly_Payment_Rate],
             [mem].[Part_B_Monthly_Payment_Rate],
             [mem].[Hosp],
             [mem].[MSPFactor],
             [lagdcp].[DCP],
             [mem].[TotalPayment],
             [mem].[Total_MA_Payment_Amount],
             [mem].[RiskPymtA],
             [mem].[RiskPymtB],
             [mem].[ESRD],
             [mem].[Part_D_RA_Factor_Type],
             [mem].[Part_D_Low_Income_Indicator],
             [mem].[MedicaidDualStatusCode],           --US60182
             [mem].[BeneficiaryCurrentMedicaidStatus], --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
             [mem].[AgeGrp],                           --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
             [mem].[LowIncomePremiumSubsidy],          --TFS 67406/RE-1146 
             [mem].[RskadjFctrA],
             [mem].[PartDLowIncomeMultiplier],
             [mem].[PartDBasicPremiumAmount],
             [mem].[PartDDirectSubsidyPaymentAmount],
             [mem].[PartDRAFTProjected],
             [mem].[PartDRAFactor],                    --67944/RE-1214
             [mem].[TotalPartDPayment];

    SET @RowCount = @RowCount + @@ROWCOUNT;


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '023',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    IF OBJECT_ID('tempdb.dbo.#tmp_UpdateORECLogic') IS NOT NULL
    BEGIN
        DROP TABLE [#tmp_UpdateORECLogic];
    END;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '024',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    CREATE TABLE [#tmp_UpdateORECLogic]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [RAFT] VARCHAR(5),
        [OREC] INT,
        [ORECNEW] INT
    );

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '025',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    INSERT INTO [#tmp_UpdateORECLogic]
    (
        [RAFT],
        [OREC],
        [ORECNEW]
    )
    VALUES
    ('C', 3, 1),
    ('I', 3, 1),
    ('CF', 3, 1),
    ('CP', 3, 1),
    ('CN', 3, 1),
    ('C', 2, 0),
    ('I', 2, 0),
    ('CF', 2, 0),
    ('CP', 2, 0),
    ('CN', 2, 0),
    ('C', 9, 0),
    ('I', 9, 0),
    ('CF', 9, 0),
    ('CP', 9, 0),
    ('CN', 9, 0);


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '026',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    /*41262 Req 10 Changed the exists statment to make sure it only process the future payment year.*/
    IF (EXISTS
    (
        SELECT 1
        FROM [#Refresh_PY]
        WHERE [Payment_Year] >= @Payment_year
    )
       )
       AND (EXISTS
    (
        SELECT 1
        FROM [dbo].[RAPS_DiagHCC_rollup]
        WHERE YEAR([ProcessedBy]) = @Payment_year
    )
           )

    /* End */
    BEGIN

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '027',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

        DECLARE @MaPaymentStart DATETIME;

        SELECT @MaPaymentStart = MAX([PaymStart])
        FROM [rev].[tbl_Summary_RskAdj_MMR];

        /* End */

        /* 41262 req 8 Added new fields in to the MMR */

        /* 41262 req 12 insert order match the table order structure. */

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '028',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END

        /*B TFS44158 MC */

        /**/;
        WITH [CTE_dcp]
        AS (SELECT [HICN] = [dcp].[HICN],
                   [PaymentYear] = [dcp].[PaymentYear],
                   [DCP] = SUM([dcp].[DCP])
            FROM [#tmp_DCPMMR] [dcp]
            GROUP BY [dcp].[HICN],
                     [dcp].[PaymentYear]), /**/
             [CTE_lagdcp]
        AS (SELECT [HICN] = [lagdcp].[HICN],
                   [PaymentYear] = [lagdcp].[PaymentYear],
                   [DCP] = SUM([lagdcp].[DCP])
            FROM [#tmp_LaggedDCPMMR] [lagdcp]
            GROUP BY [lagdcp].[HICN],
                     [lagdcp].[PaymentYear])
        /*E TFS44158 MC */



        INSERT INTO [rev].[tbl_Summary_RskAdj_MMR]
        (
            [PlanID],
            [HICN],
            [PaymentYear],
            [PaymStart],
            [Gender],
            [RskAdjAgeGrp],
            [PartCRAFTProjected],
            [PartCRAFTMMR],
            [PartCDefaultIndicator],
            [ORECRestated],
            [ORECMMR],
            [MedicaidRestated],
            [MedicaidAddOnMMR],
            [MedicaidMMR],
            [PartCRiskScoreMMR],
            [SCC],
            [OOA],
            [PBP],
            [MABID],
            [PartAMonthlyPaymentRate],
            [PartBMonthlyPaymentRate],
            [HOSP],
            [MSPFactor],
            [MonthsInLaggedDCP],
            [MonthsInDCP],
            [TotalPayment],
            [TotalMAPaymentAmount],
            [RiskPymtA],
            [RiskPymtB],
            [ESRD],
            [PartDRAFTMMR],
            [PartDLowIncomeIndicator],
            [PriorPaymentYear],
            [LoadDateTime],
            [MedicaidDualStatusCode],  -- TFS 59650
            [Aged],
            [BeneficiaryCurrentMedicaidStatus],
            [AgeGrp],                  --HasanMF 6/1/2017: This field needs to be brought in from tbl_Member_Months_Rollup.
            [LowIncomePremiumSubsidy], --TFS 67406/RE-1146
            [RskadjFctrA],
            [PartDLowIncomeMultiplier],
            [PartDBasicPremiumAmount],
            [PartDDirectSubsidyPaymentAmount],
            [PartDRAFTProjected],
            [PartDRAFactor],           --67944/RE-1214
            [TotalPartDPayment]
        )
        SELECT DISTINCT
               [PlanID] = [mmr].[PlanID],
               [HICN] = [mmr].[HICN],
               [PaymentYear] = YEAR(@MaPaymentStart) + 1,
               [PaymStart] = [mmr].[PaymStart],
               [Gender] = [mmr].[Gender],
               [RskAdjAgeGrp] = [mmr].[RskAdjAgeGrp],
               [PartCRAFTProjected] = [mmr].[PartCRAFTProjected],
               [PartCRAFTMMR] = [mmr].[PartCRAFTMMR],
               [PartCDefaultIndicator] = [mmr].[PartCDefaultIndicator],
               [ORECRestated] = [mmr].[ORECRestated],
               [ORECMMR] = [mmr].[ORECMMR],
               [MedicaidRestated] = [mmr].[MedicaidRestated],
               [MedicaidAddOnMMR] = [mmr].[MedicaidAddOnMMR],
               [MedicaidMMR] = [mmr].[MedicaidMMR],
               [PartCRiskScoreMMR] = [mmr].[PartCRiskScoreMMR],
               [SCC] = [mmr].[SCC],
               [OOA] = [mmr].[OOA],
               [PBP] = [mmr].[PBP],
               [MABID] = [mmr].[MABID],
               [PartAMonthlyPaymentRate] = [mmr].[PartAMonthlyPaymentRate],
               [PartBMonthlyPaymentRate] = [mmr].[PartBMonthlyPaymentRate],
               [HOSP] = [mmr].[HOSP],
               [MSPFactor] = [mmr].[MSPFactor],
                                                                            /*B TFS44158 MC */
               [MonthsInLaggedDCP] = ISNULL([lagdcp].[DCP], 0),             --[mmr].[MonthsInLaggedDCP]
               [MonthsInDCP] = ISNULL([dcp].[DCP], 0),                      --[mmr].[MonthsInDCP]
                                                                            /*E TFS44158 MC */
               [TotalPayment] = [mmr].[TotalPayment],
               [TotalMAPaymentAmount] = [mmr].[TotalMAPaymentAmount],
               [RiskPymtA] = [mmr].[RiskPymtA],
               [RiskPymtB] = [mmr].[RiskPymtB],
               [ESRD] = [mmr].[ESRD],
               [PartDRAFTMMR] = [mmr].[PartDRAFTMMR],
               [PartDLowIncomeIndicator] = [mmr].[PartDLowIncomeIndicator],
               [PriorPaymentYear] = YEAR(@MaPaymentStart),
               [LoadDateTime] = @LoadDateTime,
               [MedicaidDualStatusCode] = [mmr].[MedicaidDualStatusCode],
               [Aged] = [mmr].[Aged],
               [BeneficiaryCurrentMedicaidStatus] = [mmr].[BeneficiaryCurrentMedicaidStatus],
               [AgeGrp] = [mmr].[AgeGrp],                                   --HasanMF 6/1/2017: Adding AgeGrp as an additional field to Summary MMR.
               [LowIncomePremiumSubsidy] = [mmr].[LowIncomePremiumSubsidy], --TFS 67406/RE-1146
               [RskadjFctrA] = [mmr].[RskadjFctrA],
               [PartDLowIncomeMultiplier] = [mmr].[PartDLowIncomeMultiplier],
               [PartDBasicPremiumAmount] = [mmr].[PartDBasicPremiumAmount],
               [PartDDirectSubsidyPaymentAmount] = [mmr].[PartDDirectSubsidyPaymentAmount],
               [PartDRAFTProjected] = [mmr].[PartDRAFTProjected],
               [PartDRAFactor] = [mmr].[PartDRAFactor],                     --67944/RE-1214
               [TotalPartDPayment] = mmr.[TotalPartDPayment]
        FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
            /*B TFS44158 MC */
            LEFT JOIN [CTE_dcp] [dcp]
                ON [mmr].[HICN] = [dcp].[HICN]
                   AND YEAR(@MaPaymentStart) + 1 = [dcp].[PaymentYear]
            LEFT JOIN [CTE_lagdcp] [lagdcp]
                ON [mmr].[HICN] = [lagdcp].[HICN]
                   AND YEAR(@MaPaymentStart) + 1 = [lagdcp].[PaymentYear]
        /*E TFS44158 MC */
        WHERE [mmr].[PaymStart] = @MaPaymentStart;

        SET @RowCount = @RowCount + @@ROWCOUNT;

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '029',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

        SET @maxMonth = MONTH(@MaPaymentStart); -- 41262 Added the MaxMonth back in to take care of e to C conversion for future year.

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '030',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;

    END;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '031',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    UPDATE [t1]
    SET [t1].[MABID] = [bid].[MA_BID]
    FROM [rev].[tbl_Summary_RskAdj_MMR] [t1]
        JOIN [#Refresh_PY] [py]
            ON [t1].[PaymentYear] = [py].[Payment_Year]
        LEFT JOIN [dbo].[tbl_BIDS_rollup] [bid]
            ON [t1].[PlanID] = [bid].[PlanIdentifier]
               AND YEAR([t1].[PaymStart]) = [bid].[Bid_Year]
               AND [bid].[SCC] = 'OOA'
               AND [t1].[PBP] = [bid].[PBP]
    WHERE [t1].[MABID] IS NULL;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '032',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    SELECT @MaxESRDPY = MAX([PayMo])
    FROM [$(HRPReporting)].dbo.lk_Ratebook_ESRD;


    UPDATE [mmr]
    SET [mmr].[MABID] = [esrd].[Rate]
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        JOIN [#Refresh_PY] [py]
            ON [mmr].[PaymentYear] = [py].[Payment_Year]
        JOIN [$(HRPReporting)].[dbo].[lk_Ratebook_ESRD] [esrd]
            ON [mmr].[SCC] = [esrd].[Code]
               AND 
			   (Case When [mmr].[PaymentYear]> @currentyear then @MaxESRDPY else [mmr].[PaymentYear] End)= [esrd].[PayMo]
    WHERE [mmr].[PartCRAFTProjected] IN ( 'D', 'ED', 'G1', 'G2' )
          AND [mmr].[PaymentYear] IN
              (
                  SELECT [PaymentYear] FROM [#Refresh_PY]
              );


    UPDATE [t1]
    SET [t1].[PartD_BID] = [bid].[PartD_BID]
    FROM [rev].[tbl_Summary_RskAdj_MMR] [t1]
        JOIN [#Refresh_PY] [py]
            ON [t1].[PaymentYear] = [py].[Payment_Year]
        LEFT JOIN [dbo].[tbl_BIDS_rollup] [bid]
            ON [t1].[PlanID] = [bid].[PlanIdentifier]
               AND YEAR([t1].[PaymStart]) = [bid].[Bid_Year]
               AND [t1].[PBP] = [bid].[PBP]

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '033.1',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    UPDATE [t1]
    SET [t1].[PartCRAFTProjected] = 'C'
    FROM [rev].[tbl_Summary_RskAdj_MMR] [t1]
        INNER JOIN [#tmp_DCPMMR] [t2]
            ON [t1].[HICN] = [t2].[HICN]
               AND [t1].[PaymentYear] = [t2].[PaymentYear]
               AND [t1].[MonthsInDCP] = [t2].[DCP]
    WHERE [t1].[PaymentYear] <= 2016
          AND [t1].[PartCRAFTProjected] = 'E'
          AND [t2].[DCP] = @maxMonth;


    UPDATE [t1] --41262 Req  11
    SET [t1].[PartCRAFTProjected] = 'C'
    FROM [rev].[tbl_Summary_RskAdj_MMR] [t1]
        INNER JOIN [#tmp_DCPMMR] [t2]
            ON [t1].[HICN] = [t2].[HICN]
               AND [t1].[PartCRAFTProjected] = [t2].[RAFT]
               AND YEAR([t1].[PaymStart]) = [t2].[PaymentYear] -- Correction for 41262 for E to C Raft t1.PaymentYear ti Year(t1.PaymStart)
    WHERE [t1].[PaymentYear] <= 2016
          AND [t1].[PartCRAFTProjected] = 'E'
          AND [t2].[DCP] >= 12;

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '033.2',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    UPDATE [t1]
    SET [t1].[PartCRAFTProjected] = CASE
                                        WHEN [t1].[MedicaidDualStatusCode] IN ( '02', '04', '08' ) THEN
                                            'CF'
                                        WHEN [t1].[MedicaidDualStatusCode] IN ( '01', '03', '05', '06' ) THEN
                                            'CP'
                                        WHEN [t1].[BeneficiaryCurrentMedicaidStatus] = 'Y' THEN
                                            'CF'
                                        ELSE
                                            'CN'
                                    END
    FROM [rev].[tbl_Summary_RskAdj_MMR] [t1]
        INNER JOIN [#tmp_DCPMMR] [t2]
            ON [t1].[HICN] = [t2].[HICN]
               AND [t1].[PaymentYear] = [t2].[PaymentYear]
               AND [t1].[MonthsInDCP] = [t2].[DCP]
    WHERE [t1].[PaymentYear] > 2016
          AND [t1].[PartCRAFTProjected] = 'E'
          AND [t2].[DCP] = @maxMonth;


    UPDATE [t1] --41262 Req  11
    SET [t1].[PartCRAFTProjected] = CASE
                                        WHEN [t1].[MedicaidDualStatusCode] IN ( '02', '04', '08' ) THEN
                                            'CF'
                                        WHEN [t1].[MedicaidDualStatusCode] IN ( '01', '03', '05', '06' ) THEN
                                            'CP'
                                        WHEN [t1].[BeneficiaryCurrentMedicaidStatus] = 'Y' THEN
                                            'CF'
                                        ELSE
                                            'CN'
                                    END
    FROM [rev].[tbl_Summary_RskAdj_MMR] [t1]
        INNER JOIN [#tmp_DCPMMR] [t2]
            ON [t1].[HICN] = [t2].[HICN]
               AND [t1].[PartCRAFTProjected] = [t2].[RAFT]
               AND YEAR([t1].[PaymStart]) = [t2].[PaymentYear] -- Correction for 41262 for E to C Raft t1.PaymentYear ti Year(t1.PaymStart)
    WHERE [t1].[PaymentYear] > 2016
          AND [t1].[PartCRAFTProjected] = 'E'
          AND [t2].[DCP] >= 12;


    --HasanMF 6/1/2017: ESRD Members should not have a blanket update for ORECRestated set to 9999. This section is being changed to handle MedicaidRestated reshaping.
    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '034',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    UPDATE mmr
    SET MedicaidRestated = CASE
                               WHEN MedicaidRestated = 'Y' THEN
                                   '1'
                               WHEN
                               (
                                   MedicaidRestated = 'N'
                                   OR MedicaidRestated IS NULL
                               ) THEN
                                   NULL
                           END
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        JOIN [#Refresh_PY] [py]
            ON [mmr].[PaymentYear] = [py].[Payment_Year];




    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    --HasanMF 2/16/2017: Placing this update within this section 
    UPDATE --US60182   Update Aged Column in the [rev].[tbl_Summary_RskAdj_MMR] table
        [mm]
    SET [mm].[Aged] = ISNULL([b].[Aged], '9999')
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mm]
        JOIN [#Refresh_PY] [py]
            ON [mm].[PaymentYear] = [py].[Payment_Year]
        JOIN [$(HRPReporting)].[dbo].[LkRiskModelAgeGroup] [b]
            ON [mm].[PartCRAFTProjected] = [b].[RAFactorType]
               AND [mm].[RskAdjAgeGrp] = [b].[Agegrp]
    WHERE [mm].[PaymentYear] = [b].[PaymentYear];



    UPDATE [mmr]
    SET [mmr].[PartDRAFTProjected] = 'C'
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
    WHERE [mmr].[PartDRAFTProjected] = 'E'
          AND [mmr].[MonthsInDCP] = '12'; --and @Payment_Year < 2011



    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035.1',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    --kp 12/20 determine which members do not have low income indicator - part d ra factor type = D2
    --IF @Payment_year >= 2011 -- TFS 67406/RE-1146 Part D  determine which memember have Low Income indicator for pymnt yr gtr 2010
    --    BEGIN
    IF OBJECT_ID('[tempdb].[dbo].[#non_low_income]', 'U') IS NOT NULL
        DROP TABLE #non_low_income;
    CREATE TABLE #non_low_income
    (
        hicn VARCHAR(20)
    );

    CREATE CLUSTERED INDEX non_low_income ON #non_low_income (hicn);


    INSERT INTO #non_low_income
    (
        hicn
    ) --TFS  67406/RE-1146
    SELECT DISTINCT
           [rp].hicn
    FROM [dbo].[tbl_Member_Months_rollup] [rp]
        JOIN [#Refresh_PY] [py]
            ON YEAR([rp].[PaymStart]) = [py].[Payment_Year]
    WHERE (
              ISNULL([rp].Part_D_Low_Income_Indicator, '0') = '0'
              OR [rp].Part_D_Low_Income_Indicator = 'N'
          )
          AND [rp].Low_Income_Premium_Subsidy = 0
          AND YEAR([rp].[PaymStart]) > 2010;
    --and Part_D_RA_Factor_Type is not null -- #13555




    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035.2',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    UPDATE [mmr]
    SET [mmr].[PartDRAFTProjected] = 'D2' --TFS  67406/RE-1146
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        JOIN [#Refresh_PY] [py]
            ON [mmr].[PaymentYear] = [py].[Payment_Year]
    WHERE [mmr].[PartDRAFTProjected] IN ( 'D4', 'D5', 'D6', 'D7', 'D8', 'D9' )
          AND [mmr].[MonthsInDCP] = '12'
          AND [mmr].[PaymentYear] > 2010
          AND NOT EXISTS
    (
        SELECT 1 FROM #non_low_income low WHERE [mmr].hicn = low.hicn
    );


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035.3',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    UPDATE [mmr]
    SET [mmr].[PartDRAFTProjected] = 'D1' --TFS  67406/RE-1146
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        JOIN [#Refresh_PY] [py]
            ON [mmr].[PaymentYear] = [py].[Payment_Year]
    WHERE [mmr].[PartDRAFTProjected] IN ( 'D4', 'D5', 'D6', 'D7', 'D8', 'D9' )
          AND [mmr].[MonthsInDCP] = '12'
          AND [mmr].[PaymentYear] > 2010
          AND EXISTS
    (
        SELECT 1 FROM #non_low_income low WHERE [mmr].hicn = low.hicn
    );
    --END

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035.4',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

                                                               /* Set [PartDRAFTProjected] to 'HP' if [Hosp] equal 'Y' */ --67944/RE-1214
    UPDATE [mmr]
    SET [mmr].[PartDRAFTProjected] = 'HP'
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        JOIN [#Refresh_PY] [py]
            ON [mmr].[PaymentYear] = [py].[Payment_Year]
    WHERE [mmr].[HOSP] = 'Y';

    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035.5',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

                                                          /* Set [PartDRAFTMMR]  to 'HP' if [Hosp] equal 'Y' */ --67944/RE-1214
    UPDATE [mmr]
    SET [mmr].[PartDRAFTMMR] = 'HP'
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        JOIN [#Refresh_PY] [py]
            ON [mmr].[PaymentYear] = [py].[Payment_Year]
    WHERE [mmr].[HOSP] = 'Y';


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '035.6',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


    UPDATE [mm]
    SET [mm].[PartDAged] = ISNULL([b].[Aged], '9999')
    FROM [rev].[tbl_Summary_RskAdj_MMR] [mm]
        JOIN [#Refresh_PY] [py]
            ON [mm].[PaymentYear] = [py].[Payment_Year]
        JOIN [$(HRPReporting)].[dbo].[LkRiskModelAgeGroup] [b]
            ON [mm].[PartDRAFTProjected] = [b].[RAFactorType]
               AND [mm].[RskAdjAgeGrp] = [b].[Agegrp]
    WHERE [mm].[PaymentYear] = [b].[PaymentYear];



    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '036',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;

    BEGIN TRANSACTION [UpdateOREC] WITH MARK N'Update to OREC';

    BEGIN TRY

        --HasanMF 6/1/2017: Editing the OREC update to only reflect ORECRestated. ORECMMR will remain unchanged.
        UPDATE [old]
        SET [old].[ORECRestated] = [new].[ORECNEW]
        FROM [rev].[tbl_Summary_RskAdj_MMR] [old]
            JOIN [#Refresh_PY] [py]
                ON [old].[PaymentYear] = [py].[Payment_Year]
            JOIN [#tmp_UpdateORECLogic] [new]
                ON (
                       [old].[PartCRAFTProjected] = [new].[RAFT]
                       AND [old].[ORECMMR] = [new].[OREC]
                   );

        --HasanMF 6/1/2017: Additional steps being added to ORECRestated updates.
        IF OBJECT_ID('[tempdb].[dbo].[#MorList]', 'U') IS NOT NULL
            DROP TABLE #MorList;

        CREATE TABLE #MorList
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY,
            [Paymo] NVARCHAR(8),
            [HICN] NVARCHAR(12),
            [ORG_DISABLD_MALE] SMALLINT,
            [ORG_DISABLD_FEMALE] SMALLINT
        );

        INSERT INTO [#MorList]
        (
            [Paymo],
            [HICN],
            [ORG_DISABLD_MALE],
            [ORG_DISABLD_FEMALE]
        )
        SELECT [Paymo] = mor.[Paymo],
               [HICN] = mor.[HICN],
               [ORG_DISABLD_MALE] = mor.[ORG_DISABLD_MALE],
               [ORG_DISABLD_FEMALE] = mor.[ORG_DISABLD_FEMALE]
        FROM dbo.MOR_rollup mor WITH (NOLOCK)
            JOIN [#Refresh_PY] [py]
                ON LEFT(mor.Paymo, 4) = [py].[Payment_Year]
            JOIN rev.[tbl_Summary_RskAdj_MMR] erd
                ON mor.[HICN] = erd.[HICN];

        UPDATE rev.[tbl_Summary_RskAdj_MMR]
        SET ORECRestated = 1
        FROM [#MorList] a
            JOIN [rev].[tbl_Summary_RskAdj_MMR] [mmr]
                ON a.HICN = mmr.HICN
            JOIN [#Refresh_PY] [py]
                ON LEFT(a.Paymo, 4) = [py].[Payment_Year];

        ---Changes for ER OREC Restated correction ---
        UPDATE mmr
        SET ORECRestated = '1'
        FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
            JOIN [#Refresh_PY] [py]
                ON [mmr].[PaymentYear] = [py].[Payment_Year]
        WHERE RskAdjAgeGrp < 6565; --MS 6/14

        UPDATE mmr
        SET ORECRestated = '0'
        FROM [rev].[tbl_Summary_RskAdj_MMR] [mmr]
            JOIN [#Refresh_PY] [py]
                ON [mmr].[PaymentYear] = [py].[Payment_Year]
        WHERE ORECRestated <> '1';

        --UPDATE mmr
        --SET    ORECRestated = 1
        --FROM   [rev].[tbl_Summary_RskAdj_MMR] [mmr]
        --       JOIN [#Refresh_PY] [py] ON [mmr].[PaymentYear] = [py].[Payment_Year]
        --WHERE  MedicaidRestated = '1'
        --       AND RskAdjAgeGrp < 6565 --MS 6/14
        --------------------------------------

        COMMIT TRANSACTION [UpdateOREC];

        IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '037',
                                        @ProcessNameIn,
                                        @ET,
                                        @MasterET,
                                        @ET OUT,
                                        0,
                                        0;
        END;



    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION [UpdateOREC];

        SELECT [ERROR_LINE] = ERROR_LINE(),
               [ERROR_NUMBER] = ERROR_NUMBER(),
               [ERROR_PROCEDURE] = ERROR_PROCEDURE(),
               [ERROR_SEVERITY] = ERROR_SEVERITY(),
               [ERROR_STATE] = ERROR_STATE();
    END CATCH;


    IF @Debug = 1
    BEGIN
        EXEC [dbo].[PerfLogMonitor] '038',
                                    @ProcessNameIn,
                                    @ET,
                                    @MasterET,
                                    @ET OUT,
                                    0,
                                    0;
    END;


END;