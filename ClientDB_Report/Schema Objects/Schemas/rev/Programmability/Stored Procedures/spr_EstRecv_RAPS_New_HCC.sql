/*
Name		:	spr_EstRecv_RAPS_New_HCC
Author      :	Rakshit Lall
Date		:	07/07/2017
SP Call		:	EXEC [dbo].[spr_EstRecv_RAPS_New_HCC] '2019', '1/1/2018', '12/31/2018', 'M', 0
Version		:	1.0
                1.1   Modified on 8/29/17 by D. Waddell Sect. 96, 97 Resolve New Hierarchy Issue (Per Hasan F. 8/17/17- all INCR prefix being observed and M-High- prefix being removed in the last update)
				1.2   Modified on 5/17/19 by D. Waddell/Anand Sundarrajan    Finalizing Configuration changes to Report DB version
				1.3   Modified on 6/11/19 by D. Waddell     Add missing "Else" condition on line 826 
				1.4	  RE - 6187 -TFS - 76718 - 09/03/19  by Anand -  Added Valuation part based on Reportoutput = 'V'	
				1.5   RE-7581 (TFS 77831) Modified on 2/12/2020 by D. Waddell -  New HCC Process Improvement Phase 1 - Replaced [#New_HCC_Output] with etl.IntermediateRAPSNewHCCOutput 
				1.6   RE-7793 (TFS 77839) by M. Suri  7/1/20 -  New HCC Process Improvement Phase 2 - rev.spr_EstRecv_RAPS_New_HCC to run quicker
                1.7   RRI-288 (TFS 79866) Modified 10/27/20 by D.Waddell  Resolve Dividing by Zero Issue. Identify where normalization factor legacy table is being used within our processes, and replace this 
                                                            with the modernized version of the normalization table.
				1.8   RRI-466 (TFS 80727) Removing legacy outdated logic										
				1.9   RRI-340/80908 - Anand -04/03/21 Added Aged Column in #FinaluniqueCondition temp table
                2.0	  RRI- 348/908 -David Waddell	05/29/2021	Add New HCC Log Tracking logic. (Section 41)
Description	:	SP Will be called by the wrapper to load data to a permanent table used by extract/new HCC Report
*/

CREATE PROCEDURE [rev].[spr_EstRecv_RAPS_New_HCC]
    @Payment_Year_NewDeleteHCC VARCHAR(4),
    @PROCESSBY_START SMALLDATETIME,
    @PROCESSBY_END SMALLDATETIME,
    @ReportOutputByMonth CHAR(1),
    @ProcessRunId INT = -1,
    @RowCount INT OUT,
    @TableName VARCHAR (100) OUT,
	@ReportOutputByMonthID CHAR(1) OUT,
    @Debug BIT = 0
AS
SET NOCOUNT ON;

BEGIN

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET STATISTICS IO OFF;

    IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;
        DECLARE @ET DATETIME;
        DECLARE @MasterET DATETIME;
        SET @ET = GETDATE();
        SET @MasterET = @ET;
    END;

    DECLARE @initial_flag DATETIME;
    DECLARE @myu_flag DATETIME;
    DECLARE @final_flag DATETIME;
    DECLARE @Populated_Date DATETIME = GETDATE();
    DECLARE @qry_sql NVARCHAR(MAX);
    DECLARE @currentyear VARCHAR(4) = YEAR(GETDATE());
    DECLARE @Year_NewDeleteHCC_PaymentYearMinuseOne INT;
    DECLARE @Year_NewDeleteHCC_PaymentYear VARCHAR(4);
    DECLARE @DeleteBatch INT;
    DECLARE @NewHCCActivityIdMain INT; 
	DECLARE @NewHCCActivityIdSecondary INT;
	DECLARE @Today DATETIME;
	DECLARE @UserID Varchar(20);
	DECLARE @RAPSRowCount INT;
	DECLARE @RefreshDate  DATETIME;

   
   -- Modified RRI-348  DW 04/13/21
	Set @NewHCCActivityIdMain  =
        (
            SELECT MAX([GroupingId]) FROM [rev].[NewHCCActivity]
        );
		
	Set @UserID = CURRENT_USER
   
   --RE - 6187  Start

    IF @currentyear < @Payment_Year_NewDeleteHCC
       AND @ReportOutputByMonth = 'V'
    BEGIN
        RAISERROR('Error Message: If ReportOutputByMonth = V, Payment Year cannot exceed Current Year.', 16, -1);

    END;

    --RE - 6187  End

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('001', 0, 1) WITH NOWAIT;
    END;


    IF (OBJECT_ID('tempdb.dbo.#PlanIdentifier') IS NOT NULL)
    BEGIN
        DROP TABLE [#PlanIdentifier];
    END;

    CREATE TABLE [#PlanIdentifier]
    (
        [PlanIdentifier] SMALLINT NOT NULL,
        [PlanID] VARCHAR(5) NOT NULL
    );

    INSERT INTO [#PlanIdentifier]
    (
        [PlanIdentifier],
        [PlanID]
    )
    SELECT DISTINCT
           rp.PlanIdentifier,
           rp.PlanID
    FROM [$(HRPInternalReportsDB)].dbo.RollupPlan [rp]
    WHERE rp.Active = 1;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('002', 0, 1) WITH NOWAIT;
    END;

    SELECT @initial_flag =
    (
        SELECT MIN([Initial_Sweep_Date])
        FROM [$(HRPReporting)].dbo.lk_DCP_dates
        WHERE SUBSTRING([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
              AND [Mid_Year_Update] IS NULL
    );

    SELECT @myu_flag =
    (
        SELECT MAX([Initial_Sweep_Date])
        FROM [$(HRPReporting)].dbo.lk_DCP_dates
        WHERE SUBSTRING([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
              AND [Mid_Year_Update] = 'Y'
    );

    SELECT @final_flag =
    (
        SELECT MAX([Final_Sweep_Date]) --Use Final sweep date instead of initial_sweep_date - Ticket # 25298
        FROM [$(HRPReporting)].dbo.lk_DCP_dates
        WHERE SUBSTRING([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
              AND [Mid_Year_Update] IS NULL
    );

    DECLARE @Clnt_DB VARCHAR(128)
    DECLARE @Coding_Intensity DECIMAL(18, 4);

    SET @Clnt_DB =
    (
        SELECT [Client_DB]
        FROM [$(HRPReporting)].dbo.tbl_Clients
        WHERE [Report_DB] = DB_NAME()
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('003', 0, 1) WITH NOWAIT;
    END;

	IF OBJECT_ID('[etl].[IntermediateRAPSNewHCCOutput]', 'U') IS NOT NULL
        TRUNCATE TABLE [etl].[IntermediateRAPSNewHCCOutput];


INSERT INTO [etl].[IntermediateRAPSNewHCCOutput]
    (
        [PlanID],
        [HICN],
        [PaymentYear],
        [PaymStart],
        [ModelYear],
        [ProcessedByStart],
        [ProcessedByEnd],
        [HCC],
        [Factor],
        [HCCOrig],
        [OnlyHCC],
        [RAFactorType],
        [HCCNumber],
        [ProcessedPriorityProcessedBy],
        [ProcessedPriorityThruDate],
        [ProcessedPriorityPCN],
        [ProcessedPriorityDiag],
        [ProcessedPriorityFileID],
        [ProcessedPriorityRAPSSourceID],
        [ProcessedPriorityRAC],
        [ThruPriorityThruDate],
        [MinProcessBySeqnum],
        [ThruPriorityDiag],
        [ThruPriorityPCN],
        [ThruPriorityProcessedBy],
        [RAFactorTypeORIG],
        [ThruPriorityFileID],
        [ThruPriorityRAPSSourceID],
        [ThruPriorityRAC],
        [PaymStartYear],
        [Unionqueryind],
        [AGED],
        [ProviderID],
        [MemberMonths]
    )
    SELECT [PlanID] = n.PlanID,
           [HICN] = n.HICN,
           [PaymentYear] = n.PaymentYear,
           [PaymStart] = n.PaymStart,
           [ModelYear] = n.ModelYear,
           [ProcessedByStart] = @PROCESSBY_START,
           [ProcessedByEnd] = @PROCESSBY_END,
           [HCC] = n.Factor_Desc,
           [Factor] = Isnull(n.Factor,0),
           [HCCOrig] = n.Factor_Desc_ORIG,
           [OnlyHCC] = LEFT(n.Factor_Desc_ORIG, 3),
           [RAFactorType] = n.RAFT,
           [HCCNumber] = n.HCC_Number,
           [ProcessedPriorityProcessed_By] = n.Min_ProcessBy,
           [ProcessedPriorityThruDate] = n.Processed_Priority_Thru_Date,
           [ProcessedPiorityPCN] = n.Min_ProcessBy_PCN,
           [ProcessedPriorityDiag] = n.Min_Processby_DiagCD,
           [ProcessedPriorityFileID] = n.Processed_Priority_FileID,
           [ProcessedPriorityRAPSSourceID] =
           (
               SELECT r.Category
               FROM [$(HRPReporting)].dbo.lk_RAPS_Sources [r]
               WHERE n.Processed_Priority_RAPS_Source_ID = r.Source_ID
           ),
           [ProcessedPriorityRAC] = n.[Processed_Priority_RAC],
           [ThruPriorityThruDate] = n.Min_ThruDate,
           [MinProcessBySeqnum] = n.Min_ProcessBy_SeqNum,
           [ThruPriorityDiag] = n.Min_ThruDate_DiagCD,
           [ThruPriorityPCN] = n.Min_ThruDate_PCN,
           [ThruPriorityProcessedBy] = n.Thru_Priority_Processed_By,
           [RAFactorTypeORIG] = n.RAFT_ORIG,
           [ThruPriorityFileID] = n.Thru_Priority_FileID,
           [ThruPriorityRAPSSourceID] =
           (
               SELECT r.Category
               FROM [$(HRPReporting)].dbo.lk_RAPS_Sources [r]
               WHERE n.Thru_Priority_RAPS_Source_ID = r.Source_ID
           ),
           [ThruPriorityRAC] = n.Thru_Priority_RAC,
           [PaymStartYear] = YEAR(n.PaymStart),
           [Unionqueryind] = n.IMFFlag,
           [Aged] = n.[Aged],
           [ProviderID] = ISNULL(n.Processed_Priority_Provider_ID, n.Thru_Priority_Provider_ID),
           [MemberMonths] = 1
    FROM rev.tbl_Summary_RskAdj_RAPS_MOR_Combined n
    WHERE [PaymentYear] = @Payment_Year_NewDeleteHCC
          AND ([Factor_Desc] NOT LIKE 'DEL%')
          AND
          (
              Factor_Desc LIKE 'HCC%'
              OR Factor_Desc LIKE 'M-High%'
              OR Factor_Desc LIKE 'INCR%'
              OR Factor_Desc LIKE 'INT%'
              OR Factor_Desc LIKE 'D-HCC%'
              OR Factor_Desc LIKE 'M-%'
          )
          AND [Factor] > 0;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('004', 0, 1) WITH NOWAIT;
    END;

    --RE - 6188 - Implementing the same logic from RAPS.

    IF OBJECT_ID('TEMPDB..#MonthsInDCP', 'U') IS NOT NULL
        DROP TABLE [#MonthsInDCP];
		
    CREATE TABLE [#MonthsInDCP]
    (
        [HICN] VARCHAR(12),
        [paymyear] VARCHAR(4),
        [months_in_dcp] INT
    );
	
    SET @Year_NewDeleteHCC_PaymentYearMinuseOne = CAST(@Payment_Year_NewDeleteHCC AS INT) - 1;
    SET @Year_NewDeleteHCC_PaymentYear = CAST(@Payment_Year_NewDeleteHCC AS INT);

	INSERT INTO [#MonthsInDCP]
    (
        [HICN],
        [paymyear],
        [months_in_dcp]
    )
    SELECT a.HICN,
           a.PaymentYear,
           COUNT(DISTINCT a.PaymStart) [months_in_dcp]
    FROM rev.tbl_Summary_RskAdj_MMR (NOLOCK) [a]
    WHERE (a.PaymentYear IN ( @Year_NewDeleteHCC_PaymentYearMinuseOne, @Year_NewDeleteHCC_PaymentYear ))
          AND a.HICN IS NOT NULL
    GROUP BY a.HICN,
             a.PaymentYear;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('005', 0, 1) WITH NOWAIT;
    END;

    CREATE NONCLUSTERED INDEX [idx_MonthsInDCP_HICN]
    ON [#MonthsInDCP] ([HICN])
    INCLUDE (
                [paymyear],
                [months_in_dcp]
            );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('006', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#MMR_BID') IS NOT NULL)
    BEGIN
        DROP TABLE [#MMR_BID];
    END;

    CREATE TABLE [#MMR_BID]
    (
        [pbp] VARCHAR(4),
        [scc] VARCHAR(5),
        [MABID] SMALLMONEY,
        [HICN] VARCHAR(12),
        [paymstart] DATETIME,
        [payment_year] INT,
        [hosp] CHAR(1)
    );

INSERT INTO [#MMR_BID]
    (	
        [pbp],
        [scc],
        [MABID],
        [HICN],
        [paymstart],
        [payment_year],
        [hosp]
    )
    SELECT Distinct 
		   mmr.PBP,
           mmr.SCC,
           mmr.MABID,
           mmr.HICN,
           mmr.PaymStart,
           mmr.PaymentYear,
           mmr.HOSP
    FROM rev.tbl_Summary_RskAdj_MMR [mmr]
    WHERE mmr.PaymentYear = @Payment_Year_NewDeleteHCC; -- RE - 6188

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('007', 0, 1) WITH NOWAIT;
    END;
 
    IF (OBJECT_ID('tempdb.dbo.#MMR_BIDMaxPaymStart') IS NOT NULL)
    BEGIN
        DROP TABLE [#MMR_BIDMaxPaymStart];
    END;

    CREATE TABLE [#MMR_BIDMaxPaymStart]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [payment_year] INT,
        [max_paymstart] DATETIME
    );

    INSERT INTO [#MMR_BIDMaxPaymStart]
    (
        [payment_year],
        [max_paymstart]
    )
    SELECT [payment_year] = bb.payment_year,
           [max_paymstart] = MAX(bb.paymstart)
    FROM [#MMR_BID] [bb]
    GROUP BY bb.payment_year;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('008', 0, 1) WITH NOWAIT;
    END;

    UPDATE [n]
    SET n.MonthsInDCP = mm.months_in_dcp,
        n.ActiveIndicatorForRollforward = (CASE
                                               WHEN ISNULL(CONVERT(VARCHAR(12), m.max_paymstart, 101), 'N') = 'N' THEN
                                                   'N'
                                               ELSE
                                                   'Y'
                                           END
                                          ),
        n.ESRD = CASE
                     WHEN rft.RA_Type IS NOT NULL THEN
                         'Y'
                     ELSE
                         'N'
                 END,
        n.HOSP = ISNULL(b.hosp, 'N'),
        n.PBP = b.pbp,
        n.SCC = b.scc,
        n.BID = b.mabid
    FROM etl.IntermediateRAPSNewHCCOutput [n]
        JOIN [#MMR_BID] [b]
            ON n.HICN = b.HICN
               AND n.PaymStart = b.paymstart
               AND n.PaymentYear = b.payment_year
        LEFT JOIN [#MMR_BIDMaxPaymStart] [m]
            ON n.PaymentYear = m.payment_year
               AND n.PaymStart = m.max_paymstart
        LEFT JOIN [#MonthsInDCP] [mm]
            ON n.HICN = mm.HICN
               AND CASE
                       WHEN @currentyear < @Payment_Year_NewDeleteHCC THEN
                           n.PaymStartYear
                       ELSE
                           n.PaymStartYear - 1
                   END = mm.paymyear -- Ticket # 26951
        LEFT JOIN [$(HRPReporting)].dbo.lk_RA_FACTOR_TYPES [rft]
            ON n.RAFactorType = rft.RA_Type
               AND
               (
                   rft.[Description] LIKE '%dialysis%'
                   OR rft.[Description] LIKE '%graft%'
               );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('009', 0, 1) WITH NOWAIT;
    END;

   
    IF OBJECT_ID('[TEMPDB]..[#Tbl_ModelSplit]', 'U') IS NOT NULL
        DROP TABLE [#Tbl_ModelSplit];


    CREATE TABLE [#Tbl_ModelSplit]
    (
        [PaymentYear] INT,
        [ModelYear] INT
    );

    INSERT INTO [#Tbl_ModelSplit]
    (
        [PaymentYear],
        [ModelYear]
    )
    SELECT DISTINCT
           [PaymentYear],
           [ModelYear]
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC
    WHERE [PaymentYear] = @Payment_Year_NewDeleteHCC
          AND [SubmissionModel] = 'RAPS';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('010', 0, 1) WITH NOWAIT;
    END;

    DECLARE @maxModelYear INT;

    SELECT @maxModelYear = MAX([ModelYear])
    FROM [#Tbl_ModelSplit]

    IF @maxModelYear <> @Payment_Year_NewDeleteHCC
    BEGIN

        INSERT INTO [#Tbl_ModelSplit]
        (
            [PaymentYear],
            [ModelYear]
        )
        SELECT @Payment_Year_NewDeleteHCC,
               @Payment_Year_NewDeleteHCC;

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('011', 0, 1) WITH NOWAIT;
    END;
    -- Ticket # 26951 End	

    -- Performance Tuning (Created Temp Tables) Start

    IF OBJECT_ID('TEMPDB..#lk_Factors_PartC_HCC_INT', 'U') IS NOT NULL
        DROP TABLE [#lk_Factors_PartC_HCC_INT];

    CREATE TABLE [#lk_Factors_PartC_HCC_INT]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [HCC_Label_NUMBER_HCC_INT] INT,
        [HCC_LABEL_HCC_INT] VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );

    IF OBJECT_ID('TEMPDB..#lk_Factors_PartG_HCC_INT', 'U') IS NOT NULL
        DROP TABLE [#lk_Factors_PartG_HCC_INT];

    CREATE TABLE [#lk_Factors_PartG_HCC_INT]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [HCC_Label_NUMBER_HCC_INT] INT,
        [HCC_LABEL_HCC_INT] VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );


    IF OBJECT_ID('TEMPDB..#lk_Factors_PartC_DHCC', 'U') IS NOT NULL
        DROP TABLE [#lk_Factors_PartC_DHCC];

    CREATE TABLE [#lk_Factors_PartC_DHCC]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [HCC_Label_NUMBER_DHCC] INT,
        [HCC_LABEL_DHCC] VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );

    IF OBJECT_ID('TEMPDB..#lk_Factors_PartG_DHCC', 'U') IS NOT NULL
        DROP TABLE [#lk_Factors_PartG_DHCC];
		
    CREATE TABLE [#lk_Factors_PartG_DHCC]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [HCC_Label_NUMBER_DHCC] INT,
        [HCC_LABEL_DHCC] VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );


    INSERT INTO [#lk_Factors_PartC_HCC_INT]
    (
        [HCC_Label_NUMBER_HCC_INT],
        [HCC_LABEL_HCC_INT],
        [Payment_Year],
        [Description]
    )
    SELECT CAST(SUBSTRING([HCC_Label], 4, LEN([HCC_Label]) - 3) AS INT),
           LEFT([HCC_Label], 3),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartC
    WHERE (
              LEFT([HCC_Label], 3) = 'HCC'
              OR LEFT([HCC_Label], 3) = 'INT'
          );


    INSERT INTO [#lk_Factors_PartG_HCC_INT]
    (
        [HCC_Label_NUMBER_HCC_INT],
        [HCC_LABEL_HCC_INT],
        [Payment_Year],
        [Description]
    )
    SELECT CAST(SUBSTRING([HCC_Label], 4, LEN([HCC_Label]) - 3) AS INT),
           LEFT([HCC_Label], 3),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartG
    WHERE (
              LEFT([HCC_Label], 3) = 'HCC'
              OR LEFT([HCC_Label], 3) = 'INT'
          );

    INSERT INTO [#lk_Factors_PartC_DHCC]
    (
        [HCC_Label_NUMBER_DHCC],
        [HCC_LABEL_DHCC],
        [Payment_Year],
        [Description]
    )
    SELECT CAST(SUBSTRING([HCC_Label], 6, LEN([HCC_Label]) - 5) AS INT),
           LEFT([HCC_Label], 5),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartC
    WHERE LEFT([HCC_Label], 5) = 'D-HCC';


    INSERT INTO [#lk_Factors_PartG_DHCC]
    (
        [HCC_Label_NUMBER_DHCC],
        [HCC_LABEL_DHCC],
        [Payment_Year],
        [Description]
    )
    SELECT CAST(SUBSTRING([HCC_Label], 6, LEN([HCC_Label]) - 5) AS INT),
           LEFT([HCC_Label], 5),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartG
    WHERE LEFT([HCC_Label], 5) = 'D-HCC';


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('012', 0, 1) WITH NOWAIT;
    END;

    UPDATE [hccop]
    SET hccop.HCCDescription = rskmod.Description
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [#lk_Factors_PartC_HCC_INT] [rskmod]
            ON rskmod.HCC_Label_NUMBER_HCC_INT = hccop.HCCNumber
               AND rskmod.HCC_LABEL_HCC_INT = hccop.OnlyHCC
        INNER JOIN [#Tbl_ModelSplit] [ms]
            ON rskmod.Payment_Year = ms.ModelYear
               AND hccop.ModelYear = ms.ModelYear --Ticket # 25351 
    WHERE hccop.RAFactorType IN ( 'C', 'E', 'I', 'CF', 'CP', 'CN' ) --('C', 'I', 'E')
          --and ms.PaymentYear = @Payment_Year_NewDeleteHCC          -- Ticket # 26951
          --and (LEFT(RskMod.HCC_Label,3) = 'HCC' or LEFT(RskMod.HCC_Label,3) = 'INT')
          AND
          (
              hccop.OnlyHCC = 'HCC'
              OR hccop.OnlyHCC = 'INT'
          );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('013', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartC_HCC_INT') IS NOT NULL)
    BEGIN
        DROP TABLE [#lk_Factors_PartC_HCC_INT];
    END;

    UPDATE [hccop]
    SET hccop.HCCDescription = rskmod.[Description]
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [#lk_Factors_PartG_HCC_INT] [rskmod]
            -- Performance Tuning
            ON rskmod.HCC_Label_NUMBER_HCC_INT = hccop.HCCNumber
               AND rskmod.HCC_LABEL_HCC_INT = hccop.OnlyHCC
        INNER JOIN [#Tbl_ModelSplit] [ms]
            ON rskmod.Payment_Year = ms.ModelYear
               AND hccop.ModelYear = ms.ModelYear --Ticket # 25351
    WHERE hccop.RAFactorType IN ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          AND
          (
              hccop.OnlyHCC = 'HCC'
              OR hccop.OnlyHCC = 'INT'
          );

    IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartG_HCC_INT') IS NOT NULL)
    BEGIN
        DROP TABLE [#lk_Factors_PartG_HCC_INT];
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('014', 0, 1) WITH NOWAIT;
    END;

  -- BD: update description for D-HCC
    UPDATE [hccop]
    SET hccop.HCCDescription = rskmod.Description
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [#lk_Factors_PartC_DHCC] [rskmod]
            -- Performance Tuning
            ON rskmod.HCC_Label_NUMBER_DHCC = hccop.HCCNumber
               AND rskmod.HCC_LABEL_DHCC = LEFT(hccop.HCCOrig, 5)
        INNER JOIN [#Tbl_ModelSplit] [ms]
            ON rskmod.Payment_Year = ms.ModelYear
               AND hccop.ModelYear = ms.ModelYear --Ticket # 25351
    WHERE hccop.RAFactorType IN ( 'C', 'E', 'I', 'CF', 'CP', 'CN' ) --('C', 'I', 'E')
          AND LEFT(hccop.HCCOrig, 5) = 'D-HCC';

    IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartC_DHCC') IS NOT NULL)
    BEGIN
        DROP TABLE [#lk_Factors_PartC_DHCC];
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('015', 0, 1) WITH NOWAIT;
    END;

    UPDATE [HCCOP]
    SET HCCOP.HCCDescription = RskMod.Description
    FROM etl.IntermediateRAPSNewHCCOutput [HCCOP]
        INNER JOIN [#lk_Factors_PartG_DHCC] [RskMod]
            -- Performance Tuning
            ON RskMod.HCC_Label_NUMBER_DHCC = HCCOP.HCCNumber
               AND RskMod.HCC_LABEL_DHCC = LEFT(HCCOP.HCCOrig, 5)
        INNER JOIN [#Tbl_ModelSplit] [ms]
            ON RskMod.Payment_Year = ms.ModelYear
               AND HCCOP.ModelYear = ms.ModelYear --Ticket # 25351
    WHERE HCCOP.RAFactorType IN ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          AND LEFT(HCCOP.HCCOrig, 5) = 'D-HCC';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('016', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartG_DHCC') IS NOT NULL)
    BEGIN
        DROP TABLE [#lk_Factors_PartG_DHCC];
    END;
    IF (OBJECT_ID('tempdb.dbo.#Tbl_ModelSplit') IS NOT NULL)
    BEGIN
        DROP TABLE [#Tbl_ModelSplit];
    END;

    IF OBJECT_ID('TEMPDB..#New_HCC_Rollup', 'U') IS NOT NULL
        DROP TABLE [#New_HCC_Rollup];

    CREATE TABLE [#New_HCC_Rollup]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [Factor_Desc] VARCHAR(50),
        [Factor] DECIMAL(20, 4),
        [Model_Year] INT,
        [Min_ThruDate_PCN] VARCHAR(50),
        [PaymentYear] INT,
        [RAFT] VARCHAR(3),
        [HCC] VARCHAR(50),
        [HCC_Number] INT,
        [HICN] VARCHAR(12),
        [Min_Processby_PCN] VARCHAR(50)
    );

    INSERT INTO [#New_HCC_Rollup]
    (
        [Factor_Desc],
        [Factor],
        [Model_Year],
        [Min_ThruDate_PCN],
        [PaymentYear],
        [RAFT],
        [HCC],
        [HCC_Number],
        [HICN],
        [Min_Processby_PCN]
    )
    SELECT Distinct [Factor_Desc],
           [Factor],
           [Model_Year] = [ModelYear],
           [Min_Processby_PCN],
           [PaymentYear],
           [RAFT],
           [HCC] = LEFT([Factor_Desc_ORIG], 3),
           [HCC_Number],
           [HICN],
           [Min_Processby_PCN]
    FROM rev.tbl_Summary_RskAdj_RAPS_MOR_Combined
    WHERE [PaymentYear] = @Payment_Year_NewDeleteHCC
          AND [Factor_Desc] LIKE 'HIER%'
          AND [Factor] > 0;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('017', 0, 1) WITH NOWAIT;
    END;
	   
    IF OBJECT_ID('TEMPDB..#HIER_hierarchy', 'U') IS NOT NULL
        DROP TABLE [#HIER_hierarchy];

    CREATE TABLE [#HIER_hierarchy]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [hicn] VARCHAR(15),
        [model_year] INT,
        [ra_factor_type] VARCHAR(2),
        [hcc] VARCHAR(50),
        [Unionqueryind] INT,
        [MinHCCNumber] INT
    );

    INSERT INTO [#HIER_hierarchy]
    (
        [hicn],
        [model_year],
        [ra_factor_type],
        [hcc],
        [Unionqueryind],
        [MinHCCNumber]
    )
    SELECT hccop.HICN,
           hccop.ModelYear,
           hccop.RAFactorType,
           hccop.HCC,
           hccop.Unionqueryind,
           MIN(drp.HCC_Number)
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy [hier]
            ON hier.Payment_Year = hccop.ModelYear
               AND hier.RA_FACTOR_TYPE = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models [rskmod]
            ON rskmod.Payment_Year = hier.Payment_Year
               AND rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               AND CAST(SUBSTRING(
                                     rskmod.Factor_Description,
                                     PATINDEX('%[0-9]%', rskmod.Factor_Description),
                                     LEN(rskmod.Factor_Description)
                                 ) AS VARCHAR(4)) = CAST(SUBSTRING(
                                                                      hier.HCC_DROP,
                                                                      PATINDEX('%[0-9]%', hier.HCC_DROP),
                                                                      LEN(hier.HCC_DROP)
                                                                  ) AS VARCHAR(4))
               --   AND CAST(SUBSTRING(rskmod.Factor_Description, 4, LEN(rskmod.Factor_Description) - 3) AS INT) = CAST(SUBSTRING(hier.HCC_DROP,4,LEN(hier.HCC_DROP)- 3) AS INT)
               AND LEFT(rskmod.Factor_Description, 3) = LEFT(hier.HCC_DROP, 3)
               AND rskmod.Demo_Risk_Type = 'risk'
        INNER JOIN [#New_HCC_Rollup] [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCC_Number = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.Factor_Desc LIKE 'HIER%'
               AND drp.HCC = LEFT(hier.HCC_DROP, 3)
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
    WHERE (
              LEFT(rskmod.Factor_Description, 3) = 'HCC'
              OR LEFT(rskmod.Factor_Description, 3) = 'INT'
          )
          AND
          (
              LEFT(hier.HCC_DROP, 3) = 'HCC'
              OR LEFT(hier.HCC_DROP, 3) = 'INT'
          )
          AND LEFT(hccop.HCC, 5) <> 'D-HCC'
    GROUP BY hccop.HICN,
             [hccop].[ModelYear],
             [hccop].[RAFactorType],
             [hccop].[HCC],
             [hccop].[Unionqueryind];

    CREATE NONCLUSTERED INDEX [IX_#HIER_hierarchy_HCC_Label_NUMBER_DHCC__HCC_LABEL_DHCC__Payment_Year]
    ON [#HIER_hierarchy] (
                             [ra_factor_type],
                             [hcc],
                             [Unionqueryind],
                             [MinHCCNumber]
                         );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('018', 0, 1) WITH NOWAIT;
    END;

    --update Hierarchy HCC
    UPDATE [hccop]
    SET hccop.HierHCCOld = drp.Factor_Desc,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.Min_Processby_PCN
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [#HIER_hierarchy] [hier]
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
               AND hier.Unionqueryind = hccop.Unionqueryind
        INNER JOIN [#New_HCC_Rollup] [drp]
            ON drp.HICN = hccop.HICN
               AND drp.Factor_Desc LIKE 'HIER%'
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
               --and drp.Unionqueryind = hccop.Unionqueryind
               AND drp.HCC_Number = hier.MinHCCNumber;

   IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('019', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#HIER_hierarchy') IS NOT NULL)
    BEGIN
        DROP TABLE [#HIER_hierarchy];
    END;

    IF OBJECT_ID('TEMPDB..#INCR_hierarchy', 'U') IS NOT NULL
        DROP TABLE [#INCR_hierarchy];

    CREATE TABLE [#INCR_hierarchy]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [hicn] VARCHAR(15),
        [model_year] INT,
        [ra_factor_type] VARCHAR(2),
        [hcc] VARCHAR(50),
        [MinHCCNumber] INT
    );

    INSERT INTO [#INCR_hierarchy]
    (
        [hicn],
        [model_year],
        [ra_factor_type],
        [hcc],
        [MinHCCNumber]
    )
    SELECT hccop.HICN,
           hccop.ModelYear,
           hccop.RAFactorType,
           hccop.HCC,
           MIN(drp.HCCNumber)
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy [hier]
            ON hier.Payment_Year = hccop.ModelYear
               AND hier.RA_FACTOR_TYPE = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models [rskmod]
            ON rskmod.Payment_Year = hier.Payment_Year
               AND rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               AND CAST(SUBSTRING(
                                     rskmod.Factor_Description,
                                     PATINDEX('%[0-9]%', rskmod.Factor_Description),
                                     LEN(rskmod.Factor_Description)
                                 ) AS VARCHAR(4)) = CAST(SUBSTRING(
                                                                      hier.HCC_DROP,
                                                                      PATINDEX('%[0-9]%', hier.HCC_DROP),
                                                                      LEN(hier.HCC_DROP)
                                                                  ) AS VARCHAR(4))
               AND rskmod.Demo_Risk_Type = 'risk'
        INNER JOIN etl.IntermediateRAPSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCCNumber = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.HCC LIKE 'INCR%'
               AND drp.HCC = LEFT(hier.HCC_DROP, 3)
               AND drp.RAFactorType = hccop.RAFactorType
               AND drp.ModelYear = hccop.ModelYear
    WHERE (
              LEFT(rskmod.Factor_Description, 3) = 'HCC'
              OR LEFT(rskmod.Factor_Description, 3) = 'INT'
          )
          AND
          (
              LEFT(rskmod.Factor_Description, 3) = 'HCC'
              OR LEFT(rskmod.Factor_Description, 3) = 'INT'
          )
          --and RskMod.Factor > isnull(HCCOP.HIER_FACTOR_OLD,0)
          AND LEFT(hccop.HCC, 5) <> 'D-HCC'
    GROUP BY hccop.HICN,
             hccop.ModelYear,
             hccop.RAFactorType,
             hccop.HCC;


    CREATE NONCLUSTERED INDEX [IX_INCR_hierarchy_hicn_model_year_ra_factor_type_hcc_MinHCCNumber]
    ON [#INCR_hierarchy] (
                             [hicn],
                             [model_year],
                             [ra_factor_type],
                             [hcc],
                             [MinHCCNumber]
                         );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('020', 0, 1) WITH NOWAIT;
    END;

    --update Hierarchy HCC
    UPDATE [hccop]
    SET hccop.HierHCCOld = REPLACE(drp.HCC, 'M-High-', ''),
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.ProcessedPriorityPCN
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        JOIN [#INCR_hierarchy] [hier]
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
        JOIN etl.IntermediateRAPSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCCDescription LIKE '%INCR%' --HasanMF 8/14/2017: All INCR prefix being observed in this step.
               AND drp.RAFactorType = hccop.RAFactorType
               AND drp.ModelYear = hccop.ModelYear
               AND drp.HCCNumber = hier.MinHCCNumber;


    IF (OBJECT_ID('tempdb.dbo.#INCR_hierarchy') IS NOT NULL)
    BEGIN
        DROP TABLE [#INCR_hierarchy];
    END;

    IF OBJECT_ID('TEMPDB..#MOR_hierarchy', 'U') IS NOT NULL
        DROP TABLE [#MOR_hierarchy];

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('021', 0, 1) WITH NOWAIT;
    END;


    CREATE TABLE [#MOR_hierarchy]
    (
        [ID] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        [hicn] VARCHAR(15),
        [model_year] INT,
        [ra_factor_type] VARCHAR(2),
        [hcc] VARCHAR(50),
        [MinHCCNumber] INT
    );

	INSERT INTO [#MOR_hierarchy]
    (
        [hicn],
        [model_year],
        [ra_factor_type],
        [hcc],
        [MinHCCNumber]
    )
    SELECT hccop.HICN,
           hccop.ModelYear,
           hccop.RAFactorType,
           hccop.HCC,
           MIN(drp.HCCNumber)
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy [hier]
            ON hier.Payment_Year = hccop.ModelYear
               AND hier.RA_FACTOR_TYPE = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models [rskmod]
            ON rskmod.Payment_Year = hier.Payment_Year
               AND rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               AND CAST(SUBSTRING(
                                     rskmod.Factor_Description,
                                     PATINDEX('%[0-9]%', rskmod.Factor_Description),
                                     LEN(rskmod.Factor_Description)
                                 ) AS INT) = CAST(SUBSTRING(
                                                               hier.HCC_DROP,
                                                               PATINDEX('%[0-9]%', hier.HCC_DROP),
                                                               LEN(hier.HCC_DROP)
                                                           ) AS INT)
               AND LEFT(rskmod.Factor_Description, 3) = LEFT(hier.HCC_DROP, 3)
               AND rskmod.Demo_Risk_Type = 'risk'
        INNER JOIN etl.IntermediateRAPSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCCNumber = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.HCCDescription LIKE 'MOR-INCR%'
               AND drp.HCC = LEFT(hier.HCC_DROP, 3)
               AND drp.RAFactorType = hccop.RAFactorType
               AND drp.ModelYear = hccop.ModelYear
    WHERE (
              LEFT(rskmod.Factor_Description, 3) = 'HCC'
              OR LEFT(rskmod.Factor_Description, 3) = 'INT'
          )
          AND
          (
              LEFT(hier.HCC_DROP, 3) = 'HCC'
              OR LEFT(hier.HCC_DROP, 3) = 'INT'
          )
          --and RskMod.Factor > isnull(HCCOP.HIER_FACTOR_OLD,0)
          AND LEFT(hccop.HCC, 5) <> 'D-HCC'
    GROUP BY hccop.HICN,
             hccop.ModelYear,
             hccop.RAFactorType,
             hccop.HCC;

    CREATE NONCLUSTERED INDEX [IX_#MOR_hierarchy_hicn_model_year_ra_factor_type_hcc_MinHCCNumber]
    ON [#MOR_hierarchy] (
                            [hicn],
                            [model_year],
                            [ra_factor_type],
                            [hcc],
                            [MinHCCNumber]
                        );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('022', 0, 1) WITH NOWAIT;
    END;


    UPDATE [hccop]
    SET hccop.HierHCCOld = drp.HCCDescription,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.ProcessedPriorityPCN
    FROM etl.IntermediateRAPSNewHCCOutput [hccop]
        INNER JOIN [#MOR_hierarchy] [hier]
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
        INNER JOIN etl.IntermediateRAPSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCCDescription LIKE 'MOR-INCR%'
               AND drp.RAFactorType = hccop.RAFactorType
               AND drp.ModelYear = hccop.ModelYear
               AND drp.HCCNumber = hier.MinHCCNumber;


    IF (OBJECT_ID('tempdb.dbo.#MOR_hierarchy') IS NOT NULL)
    BEGIN
        DROP TABLE [#MOR_hierarchy];
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('023', 0, 1) WITH NOWAIT;
    END;
    -- Ticket # 26951 End

    IF (OBJECT_ID('tempdb.dbo.#lk_risk_Score_factors_PartC') IS NOT NULL)
    BEGIN
        DROP TABLE #lk_risk_Score_factors_PartC;
    END;

    CREATE TABLE #lk_Risk_Score_Factors_PartC
    (
        [ID] [INT] IDENTITY(1, 1) NOT FOR REPLICATION NOT NULL,
        [PaymentYear] [INT] NULL,
        [PartCNormalizationFactor] [DECIMAL](20, 4) NULL,
        [RAFactorType] [VARCHAR](5) NULL,
        [SplitSegmentWeight] [DECIMAL](20, 4) NULL,
        [CodingIntensity] [DECIMAL](20, 4) NULL,
        [ModelYear] [INT] NULL,
        [SubmissionModel] [VARCHAR](5) NOT NULL,
        [Segment] [VARCHAR](50) NULL
    );

    INSERT INTO #lk_Risk_Score_Factors_PartC
    SELECT a.PaymentYear,
           a.PartCNormalizationFactor,
           a.RAFactorType,
           a.[SplitSegmentWeight],
           a.CodingIntensity,
           a.ModelYear,
           a.SubmissionModel,
           a.Segment
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC a
    WHERE PaymentYear = @Payment_Year_NewDeleteHCC
          AND a.SubmissionModel = 'RAPS'
          AND a.Segment = 'CMS-HCC'
          AND RAFactorType IN ( 'CN', 'CF', 'CP', 'C', 'I' )
	UNION
        SELECT a.PaymentYear,
           a.FunctioningGraftFactor,
           a.RAFactorType,
           a.[SplitSegmentWeight],
           a.CodingIntensity,
           a.ModelYear,
           a.SubmissionModel,
           a.Segment
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC a
    WHERE PaymentYear = @Payment_Year_NewDeleteHCC
          AND a.SubmissionModel = 'RAPS'
          AND a.Segment = 'Functioning Graft'
    UNION
    SELECT a.PaymentYear,
           a.ESRDDialysisFactor,
           a.RAFactorType,
           a.[SplitSegmentWeight],
           a.CodingIntensity,
           a.ModelYear,
           a.SubmissionModel,
           a.Segment
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC a
    WHERE PaymentYear = @Payment_Year_NewDeleteHCC
          AND a.SubmissionModel = 'RAPS'
          AND a.Segment IN ( 'Dialysis', 'Transplant' );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('024', 0, 1) WITH NOWAIT;
    END;

    UPDATE [HCCOP]
    SET HCCOP.FinalFactor = CASE
                                WHEN m.PartCNormalizationFactor = 0 THEN
                                    0
                                ELSE
        (CASE
             WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                 ISNULL(
                           (ROUND(
                                     ROUND(
                                              ROUND((HCCOP.Factor) / m.PartCNormalizationFactor, 3)
                                              * (1 - m.CodingIntensity),
                                              3
                                          ) * [SplitSegmentWeight],
                                     3
                                 )
                           ),
                           0
                       )
             ELSE
                 ISNULL(
                           (ROUND(
                                     ROUND(
                                              ROUND(
                                                       (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                       / m.PartCNormalizationFactor,
                                                       3
                                                   ) * (1 - m.CodingIntensity),
                                              3
                                          ) * [SplitSegmentWeight],
                                     3
                                 )
                           ),
                           0
                       )
         END
        )
                            END,
        HCCOP.EstimatedValue = CASE
                                   WHEN m.PartCNormalizationFactor = 0 THEN
                                       0
                                   ELSE
        (CASE
             WHEN @currentyear < @Payment_Year_NewDeleteHCC THEN
        (CASE
             WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                 ISNULL(
                           (ROUND(
                                     ROUND(
                                              ROUND((HCCOP.Factor) / m.PartCNormalizationFactor, 3)
                                              * (1 - m.CodingIntensity),
                                              3
                                          ) * [SplitSegmentWeight],
                                     3
                                 )
                           ) * (HCCOP.BID * 12),
                           0
                       )
             ELSE
                 ISNULL(
                           (ROUND(
                                     ROUND(
                                              ROUND(
                                                       (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                       / m.PartCNormalizationFactor,
                                                       3
                                                   ) * (1 - m.CodingIntensity),
                                              3
                                          ) * [SplitSegmentWeight],
                                     3
                                 )
                           ) * (HCCOP.BID * 12),
                           0
                       )
         END
        )
             ELSE
        (CASE
             WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                 ISNULL(
                           (ROUND(
                                     ROUND(
                                              ROUND((HCCOP.Factor) / m.PartCNormalizationFactor, 3)
                                              * (1 - m.CodingIntensity),
                                              3
                                          ) * [SplitSegmentWeight],
                                     3
                                 )
                           ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1)),
                           0
                       )
             ELSE
                 ISNULL(
                           (ROUND(
                                     ROUND(
                                              ROUND(
                                                       (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                       / m.PartCNormalizationFactor,
                                                       3
                                                   ) * (1 - m.CodingIntensity),
                                              3
                                          ) * [SplitSegmentWeight],
                                     3
                                 )
                           ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1)),
                           0
                       )
         END
        )
         END
        )
                               END,
        HCCOP.FactorDiff = CASE
                               WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                   ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                               ELSE
                                   ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                           END
    FROM etl.IntermediateRAPSNewHCCOutput [HCCOP]
        INNER JOIN #lk_Risk_Score_Factors_PartC [m]
            ON m.ModelYear = HCCOP.ModelYear
               AND m.PaymentYear = HCCOP.PaymentYear
               AND m.RAFactorType = HCCOP.RAFactorType
    WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
          AND m.SubmissionModel = 'RAPS';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('025', 0, 1) WITH NOWAIT;
    END;

    -- RE  - 6188 Start

    IF @ReportOutputByMonth = 'V'
    BEGIN

        IF OBJECT_ID('TEMPDB..#RptClientPCNStrings', 'U') IS NOT NULL
            DROP TABLE #RptClientPCNStrings;

        CREATE TABLE #RptClientPCNStrings
        (
            ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
            PCN_STRING VARCHAR(100)
        );

        INSERT INTO #RptClientPCNStrings
        (
            PCN_STRING
        )
        SELECT PCN_STRING
        FROM dbo.RptClientPcnStrings
        WHERE PAYMENT_YEAR = @Payment_Year_NewDeleteHCC
              AND ACTIVE = 'Y'
              AND TERMDATE = '0001-01-01'
              AND IDENTIFIER = 'Valuation';

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('026', 0, 1) WITH NOWAIT;
        END;


        IF OBJECT_ID('TEMPDB..#HierPCNLookup', 'U') IS NOT NULL
            DROP TABLE #HierPCNLookup;

        CREATE TABLE #HierPCNLookup
        (
            [ID] INT IDENTITY(1, 1) PRIMARY KEY,
            [Processed_Priority_PCN] VARCHAR(50),
            HIER_HCC_PROCESSED_PCN VARCHAR(50)
        );
		
        INSERT INTO #HierPCNLookup
        (
            Processed_Priority_PCN,
            HIER_HCC_PROCESSED_PCN
        )
        SELECT ProcessedPriorityPCN,
               HierHCCProcessedPCN
        FROM etl.IntermediateRAPSNewHCCOutput
        WHERE [HierHCCOld] LIKE 'HIER%';


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('027', 0, 1) WITH NOWAIT;
        END;

        IF (OBJECT_ID('tempdb.dbo.#ValuationPerfFix') IS NOT NULL)
        BEGIN
            DROP TABLE #ValuationPerfFix;
        END;

        CREATE TABLE #ValuationPerfFix
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY,
            [Processed_Priority_PCN] VARCHAR(50),
            [PCNFlag] BIT
        );

        INSERT INTO #ValuationPerfFix
        (
            [Processed_Priority_PCN],
            [PCNFlag]
        )
        SELECT n.Processed_Priority_PCN,
               [PCNFlag] = CASE
                               WHEN r.PCN_STRING IS NULL THEN
                                   0
                               ELSE
                                   1
                           END
        FROM #HierPCNLookup n
            LEFT JOIN #RptClientPCNStrings r
                ON PATINDEX('%' + r.PCN_STRING + '%', n.Processed_Priority_PCN) > 0;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('028', 0, 1) WITH NOWAIT;
        END;

        UPDATE [etl].[IntermediateRAPSNewHCCOutput]
        SET HCCPCNMatch = PCNFlag
        FROM etl.IntermediateRAPSNewHCCOutput hccop
            JOIN #ValuationPerfFix a
                ON a.Processed_Priority_PCN = hccop.ProcessedPriorityPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';


        IF (OBJECT_ID('tempdb.dbo.#ValuationPerfFix') IS NOT NULL)
        BEGIN
            DROP TABLE #ValuationPerfFix;
        END;

        --Ticket # 33931 Start

        UPDATE [etl].[IntermediateRAPSNewHCCOutput]
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
            INNER JOIN
            (
                SELECT n.Processed_Priority_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 3, 5))), n.Processed_Priority_PCN) > 0
                WHERE (n.Processed_Priority_PCN LIKE 'V%')
                      AND (r.PCN_STRING LIKE 'V%')
            ) a
                ON a.Processed_Priority_PCN = HCCOP.ProcessedPriorityPCN
        WHERE HCCOP.HierHCCOld LIKE 'HIER%';


        UPDATE HCCOP --etl.IntermediateRAPSNewHCCOutput
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
            INNER JOIN
            (
                SELECT n.Processed_Priority_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 7, 5))), n.Processed_Priority_PCN) > 0
                WHERE (n.Processed_Priority_PCN LIKE '%-VRSK%')
                      AND (r.PCN_STRING LIKE '%-VRSK%')
            ) a
                ON a.Processed_Priority_PCN = HCCOP.ProcessedPriorityPCN
        WHERE HCCOP.HierHCCOld LIKE 'HIER%';


        --Ticket # 33931 End    

        UPDATE HCCOP --etl.IntermediateRAPSNewHCCOutput
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
            INNER JOIN
            (
                SELECT n.Processed_Priority_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 10, 50))), n.Processed_Priority_PCN) > 0
                WHERE (
                          n.Processed_Priority_PCN LIKE 'MR_Audit%'
                          OR n.Processed_Priority_PCN LIKE 'PL_Audit%'
                          OR n.Processed_Priority_PCN LIKE 'HRP_Audit%'
                      )
                      AND
                      (
                          r.PCN_STRING LIKE 'MR_Audit%'
                          OR r.PCN_STRING LIKE 'PL_Audit%'
                          OR r.PCN_STRING LIKE 'HRP_Audit%'
                      )
            -- TFS 39388
            ) a
                ON a.Processed_Priority_PCN = HCCOP.ProcessedPriorityPCN
        WHERE HCCOP.HierHCCOld LIKE 'HIER%';


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('029', 0, 1) WITH NOWAIT;
        END;


        UPDATE hccop --etl.IntermediateRAPSNewHCCOutput
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] hccop
            INNER JOIN
            (
                SELECT n.Processed_Priority_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 22, 50))), n.Processed_Priority_PCN) > 0
                WHERE n.Processed_Priority_PCN LIKE 'MR_Audit_Prospective%'
            ) a
                ON a.Processed_Priority_PCN = hccop.ProcessedPriorityPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';


        UPDATE hccop --etl.IntermediateRAPSNewHCCOutput
        SET HierPCNMatch = PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] hccop
            INNER JOIN
            (
                SELECT n.HIER_HCC_PROCESSED_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + r.PCN_STRING + '%', n.HIER_HCC_PROCESSED_PCN) > 0
            ) a
                ON a.HIER_HCC_PROCESSED_PCN = hccop.HierHCCProcessedPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';

        --Ticket # 33931 Start

        UPDATE HCCOP --etl.IntermediateRAPSNewHCCOutput
        SET HierPCNMatch = PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
            INNER JOIN
            (
                SELECT n.HIER_HCC_PROCESSED_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 3, 5))), n.HIER_HCC_PROCESSED_PCN) > 0
                WHERE (n.HIER_HCC_PROCESSED_PCN LIKE 'V%')
                      AND (r.PCN_STRING LIKE 'V%')
            ) a
                ON a.HIER_HCC_PROCESSED_PCN = HCCOP.HierHCCProcessedPCN
        WHERE HCCOP.HierHCCOld LIKE 'HIER%';


        UPDATE HCCOP --etl.IntermediateRAPSNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
            INNER JOIN
            (
                SELECT n.HIER_HCC_PROCESSED_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 7, 5))), n.HIER_HCC_PROCESSED_PCN) > 0
                WHERE (n.HIER_HCC_PROCESSED_PCN LIKE '%-VRSK%')
                      AND (r.PCN_STRING LIKE '%-VRSK%')
            ) a
                ON a.HIER_HCC_PROCESSED_PCN = HCCOP.HierHCCProcessedPCN
        WHERE HCCOP.HierHCCOld LIKE 'HIER%';

        --Ticket # 33931 End
		
        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('030', 0, 1) WITH NOWAIT;
        END;


        UPDATE hccop --etl.IntermediateRAPSNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM [etl].[IntermediateRAPSNewHCCOutput] hccop
            INNER JOIN
            (
                SELECT n.HIER_HCC_PROCESSED_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 10, 50))), n.HIER_HCC_PROCESSED_PCN) > 0
                WHERE (
                          n.HIER_HCC_PROCESSED_PCN LIKE 'MR_Audit%'
                          OR n.HIER_HCC_PROCESSED_PCN LIKE 'PL_Audit%'
                          OR n.HIER_HCC_PROCESSED_PCN LIKE 'HRP_Audit%'
                      )
                      AND
                      (
                          r.PCN_STRING LIKE 'MR_Audit%'
                          OR n.HIER_HCC_PROCESSED_PCN LIKE 'PL_Audit%'
                          OR n.HIER_HCC_PROCESSED_PCN LIKE 'HRP_Audit%'
                      )
            ) a
                ON a.HIER_HCC_PROCESSED_PCN = hccop.HierHCCProcessedPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';



        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('031', 0, 1) WITH NOWAIT;
        END;

        UPDATE hccop --etl.IntermediateRAPSNewHCCOutput
        SET HierPCNMatch = 0
        FROM [etl].[IntermediateRAPSNewHCCOutput] hccop
            INNER JOIN
            (
                SELECT n.HIER_HCC_PROCESSED_PCN,
                       CASE
                           WHEN r.PCN_STRING IS NULL THEN
                               0
                           ELSE
                               1
                       END PCNFlag
                FROM #HierPCNLookup n
                    LEFT JOIN #RptClientPCNStrings r
                        ON PATINDEX('%' + LTRIM(RTRIM(SUBSTRING(r.PCN_STRING, 22, 50))), n.HIER_HCC_PROCESSED_PCN) > 0
                WHERE n.HIER_HCC_PROCESSED_PCN LIKE 'MR_Audit_Prospective%'
            ) a
                ON a.HIER_HCC_PROCESSED_PCN = hccop.HierHCCProcessedPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';


        IF (OBJECT_ID('tempdb.dbo.#HierPCNLookup') IS NOT NULL)
        BEGIN
            DROP TABLE #HierPCNLookup;
        END;

        IF (OBJECT_ID('tempdb.dbo.#RptClientPCNStrings') IS NOT NULL)
        BEGIN
            DROP TABLE #RptClientPCNStrings;
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('032', 0, 1) WITH NOWAIT;
        END;

            UPDATE HCCOP
            SET HCCOP.FinalFactor = ISNULL(
                                              (ROUND(
                                                        ROUND(
                                                                 ROUND(
                                                                          (HCCOP.Factor
                                                                           - ISNULL(HCCOP.HierFactorOld, 0)
                                                                          )
                                                                          / m.PartCNormalizationFactor,
                                                                          3
                                                                      ) * (1 - m.CodingIntensity),
                                                                 3
                                                             ) * m.SplitSegmentWeight,
                                                        3
                                                    )
                                              ),
                                              0
                                          ),
                HCCOP.EstimatedValue = Case When @currentyear < @Payment_Year_NewDeleteHCC then
										ISNULL(
                                                 (ROUND(
                                                           ROUND(
                                                                    ROUND(
                                                                             (HCCOP.Factor
                                                                              - ISNULL(HCCOP.HierFactorOld, 0)
                                                                             )
                                                                             / m.PartCNormalizationFactor,
                                                                             3
                                                                         ) * (1 - m.CodingIntensity),
                                                                    3
                                                                ) * m.SplitSegmentWeight,
                                                           3
                                                       )
                                                 ) * (HCCOP.BID * 12),
                                                 0
                                             )
											 Else
											 ISNULL(
                                                 (ROUND(
                                                           ROUND(
                                                                    ROUND(
                                                                             (HCCOP.Factor
                                                                              - ISNULL(HCCOP.HierFactorOld, 0)
                                                                             )
                                                                             / m.PartCNormalizationFactor,
                                                                             3
                                                                         ) * (1 - m.CodingIntensity),
                                                                    3
                                                                ) * m.SplitSegmentWeight,
                                                           3
                                                       )
                                                 ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1)),
                                                 0
                                             ) End,
                HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
            FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
                 INNER JOIN #lk_Risk_Score_Factors_PartC [m]
					ON m.ModelYear = HCCOP.ModelYear
					AND m.PaymentYear = HCCOP.PaymentYear
					AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.HCCPCNMatch = 1
                  AND HCCOP.HierPCNMatch = 0;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('033', 0, 1) WITH NOWAIT;
            END;


            UPDATE HCCOP
            SET HCCOP.FinalFactor = ISNULL(
                                                      (ROUND(
                                                                ROUND(
                                                                         (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                         / (m.PartCNormalizationFactor),
                                                                         3
                                                                     ) * (1 - m.CodingIntensity),
                                                                3
                                                            )
                                                      ),
                                                      0
                                                  ),
                HCCOP.EstimatedValue = Case When @currentyear < @Payment_Year_NewDeleteHCC then 
											ISNULL(
                                                         (ROUND(
                                                                   ROUND(
                                                                            (HCCOP.Factor
                                                                             - ISNULL(HCCOP.HierFactorOld, 0)
                                                                            )
                                                                            / (m.PartCNormalizationFactor),
                                                                            3
                                                                        ) * (1 - m.CodingIntensity),
                                                                   3
                                                               ) * (HCCOP.BID * 12)
                                                         ),
                                                         0
                                                     )
											 Else
											  ISNULL(
                                                         (ROUND(
                                                                   ROUND(
                                                                            (hccop.Factor - ISNULL(hccop.HierFactorOld, 0)) / (m.PartCNormalizationFactor),
                                                                            3
                                                                        ) * (1 - m.CodingIntensity),
                                                                   3
                                                               ) * (hccop.BID * ISNULL(hccop.MemberMonths, 1))
                                                         ),
                                                         0
                                                     )
											 End,
                HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
            FROM [etl].[IntermediateRAPSNewHCCOutput] HCCOP
              INNER JOIN #lk_Risk_Score_Factors_PartC [m]
				 ON m.ModelYear = HCCOP.ModelYear
				AND m.PaymentYear = HCCOP.PaymentYear
				AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.HCCPCNMatch = 1
                  AND HCCOP.HierPCNMatch = 0;
    END;

    -- RE  - 6188 End
	
    IF OBJECT_ID('TEMPDB..#RollForward_Months', 'U') IS NOT NULL
        DROP TABLE [#RollForward_Months];

    CREATE TABLE [#RollForward_Months]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [planid] INT,
        [hicn] VARCHAR(15),
        [ra_factor_type] VARCHAR(2),
        [pbp] VARCHAR(3),
        [scc] VARCHAR(5),
        [member_months] DATETIME
    );

    --set @start = getdate() 
    INSERT INTO [#RollForward_Months]
    (
        [planid],
        [hicn],
        [ra_factor_type],
        [pbp],
        [scc],
        [member_months]
    )
    SELECT [planid],
           [hicn],
           [RAFactorType],
           [pbp],
           [scc],
           [member_months] = MAX([PaymStart])
    FROM [etl].[IntermediateRAPSNewHCCOutput]
    GROUP BY [planid],
             [hicn],
             [RAFactorType],
             [pbp],
             [scc];


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('034', 0, 1) WITH NOWAIT;
    END;

    CREATE NONCLUSTERED INDEX [ix_rollforward_months_HICN]
    ON [#RollForward_Months] (
                                 [hicn],
                                 [ra_factor_type],
                                 [planid],
                                 [scc],
                                 [pbp]
                             ); 

    DECLARE @MaxMonth INT; -- Ticket # 29157

    SELECT @MaxMonth = MONTH(MAX([PaymStart]))
    FROM [etl].[IntermediateRAPSNewHCCOutput]; -- Ticket # 29157

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('035', 0, 1) WITH NOWAIT;
    END;
 
 IF OBJECT_ID('TEMPDB..#MaxMonthHCC', 'U') IS NOT NULL
        DROP TABLE [#MaxMonthHCC];

    CREATE TABLE [#MaxMonthHCC]
    (
        [PaymentYear] INT,
        [ModelYear] INT,
        [PlanID] INT,
        [hicn] VARCHAR(15),
        [onlyHCC] VARCHAR(20),
        [HCC_Number] INT,
        [MaxMemberMonth] DATETIME
    );

	INSERT INTO [#MaxMonthHCC]
        (
            [PaymentYear],
            [ModelYear],
            [PlanID],
            [hicn],
            [onlyHCC],
            [HCC_Number],
            [MaxMemberMonth]
        )
        SELECT [PaymentYear],
               [ModelYear],
               [PlanID],
               [hicn],
               [onlyHCC],
               [HCCNumber],
               MAX([PaymStart])
        FROM [etl].[IntermediateRAPSNewHCCOutput]
        GROUP BY [PaymentYear],
                 [ModelYear],
                 [PlanID],
                 [hicn],
                 [onlyHCC],
                 [HCCNumber];


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('036', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#FinalUniqueCondition', 'U') IS NOT NULL
        DROP TABLE [#FinalUniqueCondition];

    CREATE TABLE [#FinalUniqueCondition]
    (
        [PaymentYear] INT,
        [ModelYear] INT,
        [PlanID] INT,
        [hicn] VARCHAR(15),
        [onlyHCC] VARCHAR(20),
        [HCC_Number] INT,
        [ra_factor_type] VARCHAR(2),
        [pbp] VARCHAR(3),
        [scc] VARCHAR(5),
        [AGED] INT
    );

	INSERT INTO [#FinalUniqueCondition]
        (
            [PaymentYear],
            [ModelYear],
            [PlanID],
            [hicn],
            [onlyHCC],
            [HCC_Number],
            [ra_factor_type],
            [pbp],
            [scc],
            [AGED]
        )
        SELECT n.PaymentYear,
               n.ModelYear,
               n.PlanID,
               n.hicn,
               n.onlyHCC,
               n.HCCNumber,
               n.RAFactorType,
               n.PBP,
               n.SCC,
               n.AGED
        FROM [etl].[IntermediateRAPSNewHCCOutput] [n]
            INNER JOIN [#MaxMonthHCC] [m]
                ON n.PaymentYear = m.PaymentYear
                   AND n.ModelYear = m.ModelYear
                   AND n.PlanID = m.PlanID
                   AND n.hicn = m.hicn
                   AND n.onlyHCC = m.onlyHCC
                   AND n.HCCNumber = m.HCC_Number
                   AND n.PaymStart = m.MaxMemberMonth;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('037', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#ProviderId') IS NOT NULL)
    BEGIN
        DROP TABLE [#ProviderId];
    END;

    CREATE TABLE [#ProviderId]
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [Provider_Id] VARCHAR(40),
        [Last_Name] VARCHAR(55),
        [First_Name] VARCHAR(55),
        [Group_Name] VARCHAR(80),
        [Contact_Address] VARCHAR(100),
        [Contact_City] VARCHAR(30),
        [Contact_State] CHAR(2),
        [Contact_Zip] VARCHAR(13),
        [Work_Phone] VARCHAR(15),
        [Work_Fax] VARCHAR(15),
        [Assoc_Name] VARCHAR(55),
        [NPI] VARCHAR(10)
    );


    SET @qry_sql
        = N'INSERT  INTO [#ProviderId]
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
SELECT distinct 
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
FROM ' + +@Clnt_DB
          + N'.dbo.[tbl_provider_Unique] u 
	INNER JOIN [etl].[IntermediateRAPSNewHCCOutput] N ON U.Provider_ID=N.ProviderID
ORDER BY
    u.[Provider_ID]';

	
    EXEC (@qry_sql);
		
    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('038', 0, 1) WITH NOWAIT;
    END;

    CREATE NONCLUSTERED INDEX [IX_#ProviderId__Provider_Id]
    ON [#ProviderId] ([Provider_Id])
    INCLUDE (
                [Last_Name],
                [First_Name],
                [Group_Name],
                [Contact_Address],
                [Contact_City],
                [Contact_State],
                [Contact_Zip],
                [Work_Phone],
                [Work_Fax],
                [Assoc_Name],
                [NPI]
            );


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('039', 0, 1) WITH NOWAIT;
    END;

    -- RE - 6188 Start

    IF @ReportOutputByMonth = 'V' AND @Payment_Year_NewDeleteHCC <= @currentyear

    BEGIN

		IF OBJECT_ID('TEMPDB..#NewHCCFinalDView', 'U') IS NOT NULL
        DROP TABLE #NewHCCFinalDView;
 
	CREATE TABLE #NewHCCFinalDView
        (
            payment_year INT,
            model_year INT,
            processed_by_start DATETIME,
            processed_by_end DATETIME,
            Unionqueryind INT,
            planid INT,
            hicn VARCHAR(15),
            ra_factor_type VARCHAR(2),
            hcc VARCHAR(50),
            hcc_description VARCHAR(255),
            HCC_FACTOR DECIMAL(20, 4),
            HIER_HCC VARCHAR(20),
            HIER_HCC_FACTOR DECIMAL(20, 4),
            FINAL_FACTOR DECIMAL(20, 4),
            factor_diff DECIMAL(20, 4),
            HCC_PROCESSED_PCN VARCHAR(50),
            HIER_HCC_PROCESSED_PCN VARCHAR(50),
            member_months INT,
            bid MONEY,
            estimated_value MONEY,
            rollforward_months INT,
            annualized_estimated_value MONEY,
            months_in_dcp INT,
            esrd VARCHAR(1),
            hosp VARCHAR(1),
            pbp VARCHAR(3),
            scc VARCHAR(5),
            processed_priority_processed_by DATETIME,
            processed_priority_thru_date DATETIME,
            processed_priority_diag VARCHAR(20),
            [Processed_Priority_FileID] [VARCHAR](18),
            [Processed_Priority_RAC] [VARCHAR](1),
            [Processed_Priority_RAPS_Source_ID] VARCHAR(50),
            DOS_PRIORITY_PROCESSED_BY DATETIME,
            DOS_PRIORITY_THRU_DATE DATETIME,
            DOS_PRIORITY_PCN VARCHAR(50),
            DOS_PRIORITY_DIAG VARCHAR(20),
            DOS_PRIORITY_FILEID [VARCHAR](18),
            DOS_PRIORITY_RAC [VARCHAR](1),
            DOS_PRIORITY_RAPS_SOURCE VARCHAR(50),
            provider_id VARCHAR(40),
            provider_last VARCHAR(55),
            provider_first VARCHAR(55),
            provider_group VARCHAR(80),
            provider_address VARCHAR(100),
            provider_city VARCHAR(30),
            provider_state VARCHAR(2),
            provider_zip VARCHAR(13),
            provider_phone VARCHAR(15),
            provider_fax VARCHAR(15),
            tax_id VARCHAR(55),
            npi VARCHAR(20),
            SWEEP_DATE DATE,
            populated_date DATETIME,
            onlyHCC VARCHAR(20),
            HCC_Number INT,
            AGED INT --TFS 59836

        );

        INSERT INTO [#NewHCCFinalDView] WITH (TABLOCK)
        (
            [payment_year],
            [model_year],
            [processed_by_start],
            [processed_by_end],
            [Unionqueryind],
            [planid],
            [hicn],
            [ra_factor_type],
            [hcc],
            [hcc_description],
            [HCC_FACTOR],
            [HIER_HCC],
            [HIER_HCC_FACTOR],
            [FINAL_FACTOR],
            [factor_diff],
            [HCC_PROCESSED_PCN],
            [HIER_HCC_PROCESSED_PCN],
            [member_months],
            [bid],
            [estimated_value],
            [rollforward_months],
            [annualized_estimated_value],
            [months_in_dcp],
            [esrd],
            [hosp],
            [pbp],
            [scc],
            [processed_priority_processed_by],
            [processed_priority_thru_date],
            [processed_priority_diag],
            [Processed_Priority_FileID],
            [Processed_Priority_RAC],
            [Processed_Priority_RAPS_Source_ID],
            [DOS_PRIORITY_PROCESSED_BY],
            [DOS_PRIORITY_THRU_DATE],
            [DOS_PRIORITY_PCN],
            [DOS_PRIORITY_DIAG],
            [DOS_PRIORITY_FILEID],
            [DOS_PRIORITY_RAC],
            [DOS_PRIORITY_RAPS_SOURCE],
            [provider_id],
            [provider_last],
            [provider_first],
            [provider_group],
            [provider_address],
            [provider_city],
            [provider_state],
            [provider_zip],
            [provider_phone],
            [provider_fax],
            [tax_id],
            [npi],
            [SWEEP_DATE],
            [populated_date],
            [onlyHCC],
            [HCC_Number],
            [AGED]
        )
        SELECT [payment_year] = n.PaymentYear,
               [model_year] = n.ModelYear,
               [processed_by_start] = n.ProcessedByStart,
               [processed_by_end] = n.ProcessedByEnd,
               [Unionqueryind] = n.Unionqueryind,
               [planid] = n.planid,
               [hicn] = n.hicn,
               n.RAFactorType,
               n.HCC,
               n.HCCDescription,
               [HCC_FACTOR] = ISNULL(n.Factor, 0),
               [HIER_HCC] = n.HierHCCOld,
               [HIER_HCC_FACTOR] = ISNULL(n.HierFactorOld, 0),
               [FINAL_FACTOR] = n.FinalFactor,
               n.FactorDiff,
               [HCC_PROCESSED_PCN] = n.ProcessedPriorityPCN,
               n.HierHCCProcessedPCN,
               [member_months] = COUNT(DISTINCT n.PaymStart),
               [bid] = ISNULL(n.BID, 0),
               [estimated_value] = ISNULL(SUM(n.EstimatedValue), 0),
               [rollforward_months] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC < @currentyear
                                               OR
                                               (
                                                   @Payment_Year_NewDeleteHCC >= @currentyear
                                                   AND MONTH(r.member_months) < @MaxMonth
                                               ) THEN
                                              0
                                          ELSE -- Ticket # 29157
                                              12 - MONTH(r.member_months)
                                      END,
               [annualized_estimated_value] = ISNULL(
                                                        SUM(n.EstimatedValue)
                                                        + (CASE
                                                               WHEN @Payment_Year_NewDeleteHCC < @currentyear
                                                                    OR
                                                                    (
                                                                        @Payment_Year_NewDeleteHCC >= @currentyear
                                                                        AND MONTH(r.member_months) < @MaxMonth
                                                                    ) THEN
                                                                   0
                                                               ELSE -- Ticket # 29157
                                                                   12 - MONTH(r.member_months)
                                                           END * (SUM(n.EstimatedValue) / COUNT(DISTINCT n.PaymStart))
                                                          ),
                                                        0
                                                    ),
               [months_in_dcp] = ISNULL(n.MonthsInDCP, 0),
               [esrd] = ISNULL(n.ESRD, 'N'),
               [hosp] = ISNULL(n.HOSP, 'N'),
               [pbp] = n.pbp,
               [scc] = ISNULL(n.scc, 'OOA'),
               n.ProcessedPriorityProcessedBy,
               n.ProcessedPriorityThruDate,
               n.ProcessedPriorityDiag,
               n.ProcessedPriorityFileID,
               n.ProcessedPriorityRAC,
               n.ProcessedPriorityRAPSSourceID,
               [DOS_PRIORITY_PROCESSED_BY] = n.ThruPriorityProcessedBy,
               [DOS_PRIORITY_THRU_DATE] = n.ThruPriorityThruDate,
               [DOS_PRIORITY_PCN] = n.ThruPriorityPCN,
               [DOS_PRIORITY_DIAG] = n.ThruPriorityDiag,
               [DOS_PRIORITY_FILEID] = n.ThruPriorityFileID,
               [DOS_PRIORITY_RAC] = n.ThruPriorityRAC,
               [DOS_PRIORITY_RAPS_SOURCE] = n.ThruPriorityRAPSSourceID,
               n.ProviderID,
               n.ProviderLast,
               n.ProviderFirst,
               n.ProviderGroup,
               n.ProviderAddress,
               n.ProviderCity,
               n.ProviderState,
               n.ProviderZip,
               n.ProviderPhone,
               n.ProviderFax,
               n.TaxID,
               n.NPI,
               [SWEEP_DATE] = CASE
                                  WHEN n.Unionqueryind = 1 THEN
                                      @initial_flag
                                  WHEN n.Unionqueryind = 2 THEN
                                      @myu_flag
                                  WHEN n.Unionqueryind = 3 THEN
                                      @final_flag
                              END,
               [Populated_Date] = @Populated_Date,
               [onlyHCC] = n.OnlyHCC,
               [HCC_Number] = n.HCCNumber,
               n.AGED
        FROM [etl].[IntermediateRAPSNewHCCOutput] n
            JOIN #RollForward_Months r
                ON n.hicn = r.hicn
                   AND n.RAFactorType = r.ra_factor_type
                   AND n.planid = r.planid
                   AND n.scc = r.scc
                   AND n.pbp = r.pbp
        WHERE n.ProcessedPriorityProcessedBy BETWEEN @PROCESSBY_START AND @PROCESSBY_END
		      AND n.HCC NOT LIKE 'HIER%'
        GROUP BY n.PaymentYear,
                 n.ModelYear,
                 n.ProcessedByStart,
                 n.ProcessedByEnd,
                 n.Unionqueryind,
                 n.planid,
                 n.hicn,
                 n.RAFactorType,
                 n.HCC,
                 n.HCCDescription,
                 n.Factor,
                 n.HierHCCOld,
                 n.HierFactorOld,
                 n.FinalFactor,
                 n.FactorDiff,
                 n.ProcessedPriorityPCN,
                 n.HierHCCProcessedPCN,
                 n.BID,
                 r.member_months,
                 n.MonthsInDCP,
                 n.ESRD,
                 n.HOSP,
                 n.pbp,
                 n.scc,
                 n.ProcessedPriorityProcessedBy,
                 n.ProcessedPriorityThruDate,
                 n.ProcessedPriorityDiag,
                 n.ProcessedPriorityFileID,
                 n.ProcessedPriorityRAC,
                 n.ProcessedPriorityRAPSSourceID,
                 n.ThruPriorityProcessedBy,
                 n.ThruPriorityThruDate,
                 n.ThruPriorityPCN,
                 n.ThruPriorityDiag,
                 n.ThruPriorityFileID,
                 n.ThruPriorityRAC,
                 n.ThruPriorityRAPSSourceID,
                 n.ProviderID,
                 n.ProviderLast,
                 n.ProviderFirst,
                 n.ProviderGroup,
                 n.ProviderAddress,
                 n.ProviderCity,
                 n.ProviderState,
                 n.ProviderZip,
                 n.ProviderPhone,
                 n.ProviderFax,
                 n.TaxID,
                 n.NPI,
                 n.OnlyHCC,
                 n.HCCNumber,
                 n.AGED;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('040', 0, 1) WITH NOWAIT;
        END;

        UPDATE n
        SET n.provider_last = u.Last_Name,
            n.provider_first = u.First_Name,
            n.provider_group = u.Group_Name,
            n.provider_address = u.Contact_Address,
            n.provider_city = u.Contact_City,
            n.provider_state = u.Contact_State,
            n.provider_zip = u.Contact_Zip,
            n.provider_phone = u.Work_Phone,
            n.provider_fax = u.Work_Fax,
            n.tax_id = u.Assoc_Name,
            n.npi = u.NPI
        FROM #NewHCCFinalDView n
            JOIN [#ProviderId] u
                ON n.provider_id = u.Provider_Id;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('041', 0, 1) WITH NOWAIT;
        END;

        IF (OBJECT_ID(N'[Valuation].[NewHCCPartC]', N'U') IS NOT NULL)
        BEGIN

            SET @DeleteBatch = 300000;

            WHILE (1 = 1)
            BEGIN

                DELETE TOP (@DeleteBatch)
                FROM Valuation.NewHCCPartC
                WHERE [EncounterSource] = 'RAPS'
                      AND [ProcessRunId] = @ProcessRunId;

               IF @@rowcount = 0
                    BREAK;
                ELSE
                    CONTINUE;
            END;


            INSERT INTO Valuation.NewHCCPartC
            (
                [ProcessRunId],
                [Payment_Year],
                [Processed_By_Start],
                [Processed_By_End],
                [PlanId],
                [HICN],
                [Ra_Factor_Type],
                [Processed_By_Flag],
                [HCC],
                [HCC_Description],
                [HCC_FACTOR],
                [HIER_HCC],
                [HIER_HCC_FACTOR],
                [Pre_Adjstd_Factor],
                [Adjstd_Final_Factor],
                [HCC_PROCESSED_PCN],
                [HIER_HCC_PROCESSED_PCN],
                [UNQ_CONDITIONS],
                [Months_In_DCP],
                [Member_Months],
                [Bid_Amount],
                [Estimated_Value],
                [Rollforward_Months],
                [Annualized_Estimated_Value],
                [PBP],
                [SCC],
                [Processed_Priority_Processed_By],
                [Processed_Priority_Thru_Date],
                [Processed_Priority_Diag],
                [Processed_Priority_FileID],
                [Processed_Priority_RAC],
                [Processed_Priority_RAPS_Source_ID],
                [DOS_Priority_Processed_By],
                [DOS_Priority_Thru_Date],
                [DOS_Priority_PCN],
                [DOS_Priority_Diag],
                [DOS_Priority_FileId],
                [DOS_Priority_RAC],
                [DOS_PRIORITY_RAPS_SOURCE],
                [Provider_Id],
                [Provider_Last],
                [Provider_First],
                [Provider_Group],
                [Provider_Address],
                [Provider_City],
                [Provider_State],
                [Provider_Zip],
                [Provider_Phone],
                [Provider_Fax],
                [Tax_Id],
                [NPI],
                [Sweep_Date],
                [Populated_Date],
                [Model_Year],
                [AgedStatus],
                [EncounterSource]
            )
            SELECT DISTINCT
                   [ProcessRunId] = @ProcessRunId,
                   [Payment_Year] = n.payment_year,
                   n.processed_by_start,
                   n.processed_by_end,
                   p.PlanID,
                   n.hicn,
                   n.ra_factor_type,
                   [Processed_By_Flag] = CASE
                                             WHEN n.Unionqueryind = 1 THEN
                                                 'I'
                                             WHEN n.Unionqueryind = 2 THEN
                                                 'M'
                                             WHEN n.Unionqueryind = 3 THEN
                                                 'F'
                                         END,
                   [HCC] = CASE
                               WHEN n.hcc LIKE '%HCC%'
                                    AND n.hcc LIKE 'M-High%' THEN
                                   SUBSTRING(n.hcc, CHARINDEX('HCC', n.hcc), LEN(n.hcc))
                               WHEN n.hcc LIKE '%INT%'
                                    AND n.hcc LIKE 'M-High%' THEN
                                   SUBSTRING(n.hcc, CHARINDEX('INT', n.hcc), LEN(n.hcc))
                               WHEN n.hcc LIKE '%D-HCC%'
                                    AND n.hcc LIKE 'M-High%' THEN
                                   SUBSTRING(n.hcc, CHARINDEX('D-HCC', n.hcc), LEN(n.hcc))
                               ELSE
                                   n.hcc
                           END,
                   n.hcc_description,
                   n.HCC_FACTOR,
                   [HIER_HCC] = CASE
                                    WHEN n.HIER_HCC LIKE '%HCC%'
                                         AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                        'MOR-' + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                    WHEN n.HIER_HCC LIKE '%INT%'
                                         AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                        'MOR-' + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                    WHEN n.HIER_HCC LIKE '%D-HCC%'
                                         AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                        'MOR-' + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                    ELSE
                                        n.HIER_HCC
                                END,
                   n.HIER_HCC_FACTOR,
                   [Pre_Adjstd_Factor] = n.factor_diff,
                   [Adjstd_Final_Factor] = n.FINAL_FACTOR,
                   n.HCC_PROCESSED_PCN,
                   n.HIER_HCC_PROCESSED_PCN,
                   [UNQ_CONDITIONS] = CASE
                                          WHEN (
                                                   m.PaymentYear IS NULL
                                                   AND m.ModelYear IS NULL
                                                   AND m.PlanID IS NULL
                                                   AND m.hicn IS NULL
                                                   AND m.onlyHCC IS NULL
                                                   AND m.HCC_Number IS NULL
                                                   AND m.ra_factor_type IS NULL
                                                   AND m.scc IS NULL
                                                   AND m.pbp IS NULL
                                               )
                                               OR n.hcc LIKE 'INCR%' THEN
                                              0
                                          ELSE
                                              1
                                      END,
                   n.months_in_dcp,
                   n.member_months,
                   [Bid_Amount] = n.bid,
                   n.estimated_value,
                   n.rollforward_months,
                   n.annualized_estimated_value,
                   n.pbp,
                   n.scc,
                   n.processed_priority_processed_by,
                   n.processed_priority_thru_date,
                   n.processed_priority_diag,
                   n.Processed_Priority_FileID,
                   n.Processed_Priority_RAC,
                   n.Processed_Priority_RAPS_Source_ID,
                   n.DOS_PRIORITY_PROCESSED_BY,
                   n.DOS_PRIORITY_THRU_DATE,
                   n.DOS_PRIORITY_PCN,
                   n.DOS_PRIORITY_DIAG,
                   n.DOS_PRIORITY_FILEID,
                   n.DOS_PRIORITY_RAC,
                   n.DOS_PRIORITY_RAPS_SOURCE,
                   n.provider_id,
                   n.provider_last,
                   n.provider_first,
                   n.provider_group,
                   n.provider_address,
                   n.provider_city,
                   n.provider_state,
                   n.provider_zip,
                   n.provider_phone,
                   n.provider_fax,
                   n.tax_id,
                   n.npi,
                   n.SWEEP_DATE,
                   n.populated_date,
                   n.model_year,
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END,
                   'RAPS' AS EncounterSource
            FROM #NewHCCFinalDView n
                LEFT JOIN #FinalUniqueCondition m
                    ON n.payment_year = m.PaymentYear
                       AND n.model_year = m.ModelYear
                       AND n.AGED = m.AGED
                       AND n.planid = m.PlanID
                       AND n.hicn = m.hicn
                       AND n.onlyHCC = m.onlyHCC
                       AND n.HCC_Number = m.HCC_Number
                       AND n.ra_factor_type = m.ra_factor_type
                       AND n.pbp = m.pbp
                       AND n.scc = m.scc
                LEFT JOIN [#PlanIdentifier] [p]
                    ON n.planid = p.PlanIdentifier;

        END;

        --Modified for RRI-348
		SET @RowCount = Isnull(@@ROWCOUNT,0);
		SET @ReportOutputByMonthID = 'V';
		SET @TableName = 'Valuation.NewHCCPartC';

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('042', 0, 1) WITH NOWAIT;
        END;
    END;

    -- RE - 6188 End

    IF @ReportOutputByMonth = 'M'
    BEGIN

        IF OBJECT_ID('TEMPDB..#NewHCCFinalMView', 'U') IS NOT NULL
            DROP TABLE [#NewHCCFinalMView];

        CREATE TABLE [#NewHCCFinalMView]
        (
            [payment_year] INT NULL,
            [model_year] INT NULL,
            [PAYMSTART] DATETIME NULL,
            [processed_by_start] DATETIME NULL,
            [processed_by_end] DATETIME NULL,
            [planid] INT NULL,
            [hicn] VARCHAR(15) NULL,
            [ra_factor_type] VARCHAR(2) NULL,
            [processed_priority_processed_by] DATETIME NULL,
            [processed_priority_thru_date] DATETIME NULL,
            [HCC_PROCESSED_PCN] VARCHAR(50) NULL,
            [processed_priority_diag] VARCHAR(20) NULL,
            [Processed_Priority_FileID] [VARCHAR](18) NULL,
            [Processed_Priority_RAC] [VARCHAR](1) NULL,
            [Processed_Priority_RAPS_Source_ID] VARCHAR(50) NULL,
            [DOS_PRIORITY_PROCESSED_BY] DATETIME NULL,
            [DOS_PRIORITY_THRU_DATE] DATETIME NULL,
            [DOS_PRIORITY_PCN] VARCHAR(50) NULL,
            [DOS_PRIORITY_DIAG] VARCHAR(20) NULL,
            [DOS_PRIORITY_FILEID] [VARCHAR](18) NULL,
            [DOS_PRIORITY_RAC] [VARCHAR](1) NULL,
            [DOS_PRIORITY_RAPS_SOURCE] VARCHAR(50) NULL,
            [hcc] VARCHAR(50) NULL,
            [hcc_description] VARCHAR(255) NULL,
            [HCC_FACTOR] DECIMAL(20, 4) NULL,
            [HIER_HCC] VARCHAR(20) NULL,
            [HIER_HCC_FACTOR] DECIMAL(20, 4) NULL,
            [FINAL_FACTOR] DECIMAL(20, 4) NULL,
            [factor_diff] DECIMAL(20, 4) NULL,
            [HIER_HCC_PROCESSED_PCN] VARCHAR(50) NULL,
            [active_indicator_for_rollforward] CHAR(1) NULL,
            [months_in_dcp] INT NULL,
            [esrd] VARCHAR(1) NULL,
            [hosp] VARCHAR(1) NULL,
            [pbp] VARCHAR(3) NULL,
            [scc] VARCHAR(5) NULL,
            [bid] MONEY NULL,
            [estimated_value] MONEY NULL,
            [provider_id] VARCHAR(40) NULL,
            [provider_last] VARCHAR(55) NULL,
            [provider_first] VARCHAR(55) NULL,
            [provider_group] VARCHAR(80) NULL,
            [provider_address] VARCHAR(100) NULL,
            [provider_city] VARCHAR(30) NULL,
            [provider_state] VARCHAR(2) NULL,
            [provider_zip] VARCHAR(13) NULL,
            [provider_phone] VARCHAR(15) NULL,
            [provider_fax] VARCHAR(15) NULL,
            [tax_id] VARCHAR(55) NULL,
            [npi] VARCHAR(20) NULL,
            [SWEEP_DATE] DATE NULL,
            [onlyHCC] VARCHAR(20) NULL,
            [HCC_Number] INT NULL,
            [AGED] INT NULL,
            [ProcessedByFlag] CHAR(1) NULL,
            [RollForwardMonths] INT NULL
        );

        INSERT INTO [#NewHCCFinalMView]
        (
            payment_year,
            model_year,
            PAYMSTART,
            processed_by_start,
            processed_by_end,
            planid,
            hicn,
            ra_factor_type,
            processed_priority_processed_by,
            processed_priority_thru_date,
            HCC_PROCESSED_PCN,
            processed_priority_diag,
            Processed_Priority_FileID,
            Processed_Priority_RAC,
            Processed_Priority_RAPS_Source_ID,
            DOS_PRIORITY_PROCESSED_BY,
            DOS_PRIORITY_THRU_DATE,
            DOS_PRIORITY_PCN,
            DOS_PRIORITY_DIAG,
            DOS_PRIORITY_FILEID,
            DOS_PRIORITY_RAC,
            DOS_PRIORITY_RAPS_SOURCE,
            hcc,
            hcc_description,
            HCC_FACTOR,
            HIER_HCC,
            HIER_HCC_FACTOR,
            FINAL_FACTOR,
            factor_diff,
            HIER_HCC_PROCESSED_PCN,
            active_indicator_for_rollforward,
            months_in_dcp,
            esrd,
            hosp,
            pbp,
            scc,
            bid,
            estimated_value,
            provider_id,
            provider_last,
            provider_first,
            provider_group,
            provider_address,
            provider_city,
            provider_state,
            provider_zip,
            provider_phone,
            provider_fax,
            tax_id,
            npi,
            SWEEP_DATE,
            onlyHCC,
            HCC_Number,
            AGED,
            ProcessedByFlag,
            RollForwardMonths
        )
        SELECT DISTINCT
               [PaymentYear],
               [ModelYear],
               n.PaymStart,
               [ProcessedByStart],
               [ProcessedByEnd],
               n.planid,
               n.hicn,
               n.RAFactorType,
               -- Ticket # 26951
               n.ProcessedPriorityProcessedBy,
               n.ProcessedPriorityThruDate,
               n.ProcessedPriorityPCN AS [HCC_PROCESSED_PCN],
               n.ProcessedPriorityDiag,
               n.ProcessedPriorityFileID,
               n.ProcessedPriorityRAC,
               n.ProcessedPriorityRAPSSourceID,
               n.ThruPriorityProcessedBy AS [DOS_PRIORITY_PROCESSED_BY],
               n.ThruPriorityThruDate AS [DOS_PRIORITY_THRU_DATE],
               n.ThruPriorityPCN AS [DOS_PRIORITY_PCN],
               n.ThruPriorityDiag AS [DOS_PRIORITY_DIAG],
               n.ThruPriorityFileID AS [DOS_PRIORITY_FILEID],
               n.ThruPriorityRAC AS [DOS_PRIORITY_RAC],
               n.ThruPriorityRAPSSourceID AS [DOS_PRIORITY_RAPS_SOURCE],
               n.HCC,
               n.HCCDescription,
               ISNULL(n.Factor, 0) 'HCC_FACTOR',
               [HierHCCOld] AS [HIER_HCC],
               ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
               n.FinalFactor AS [FINAL_FACTOR],
               n.FactorDiff,
               [HierHCCProcessedPCN],
               ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
               -- Ticket # 29157
               ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
               ISNULL(n.ESRD, 'N') 'ESRD',
               ISNULL(n.HOSP, 'N') 'HOSP',
               n.pbp,
               ISNULL(n.scc, 'OOA') 'SCC',
               ISNULL(n.BID, 0) 'BID',
               ISNULL(n.EstimatedValue, 0) AS 'ESTIMATED_VALUE',
               -- Ticket # 26951
               n.ProviderID,
               n.ProviderLast,
               n.ProviderFirst,
               n.ProviderGroup,
               n.ProviderAddress,
               n.ProviderCity,
               [ProviderState],
               n.ProviderZip,
               n.ProviderPhone,
               n.ProviderFax,
               n.TaxID,
               n.NPI,
               CASE
                   WHEN n.Unionqueryind = 1 THEN
                       @initial_flag
                   WHEN n.Unionqueryind = 2 THEN
                       @myu_flag
                   WHEN n.Unionqueryind = 3 THEN
                       @final_flag
               END [SweepDate],
               n.OnlyHCC,
               n.HCCNumber,
               n.AGED,
               CASE
                   WHEN n.Unionqueryind = 1 THEN
                       'I'
                   WHEN n.Unionqueryind = 2 THEN
                       'M'
                   WHEN n.Unionqueryind = 3 THEN
                       'F'
               END AS [ProcessedByFlag],
               CASE
                   WHEN @Payment_Year_NewDeleteHCC < @currentyear
                        OR
                        (
                            @Payment_Year_NewDeleteHCC >= @currentyear
                            AND MONTH(r.member_months) < @MaxMonth
                        ) THEN
                       0
                   ELSE
                       12 - MONTH(r.member_months)
               END AS [RollForwardMonths]
        FROM etl.IntermediateRAPSNewHCCOutput [n]
            LEFT JOIN [#RollForward_Months] [r]
                ON n.hicn = r.hicn
                   AND n.RAFactorType = r.ra_factor_type
                   AND n.planid = r.planid
                   AND n.scc = r.scc
                   AND n.pbp = r.pbp
        WHERE n.ProcessedPriorityProcessedBy
              BETWEEN @PROCESSBY_START AND @PROCESSBY_END
              AND n.HCC NOT LIKE 'HIER%';

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('043', 0, 1) WITH NOWAIT;
        END;

        UPDATE [n]
        SET n.provider_last = u.Last_Name,
            n.provider_first = u.First_Name,
            n.provider_group = u.Group_Name,
            n.provider_address = u.Contact_Address,
            n.provider_city = u.Contact_City,
            n.provider_state = u.Contact_State,
            n.provider_zip = u.Contact_Zip,
            n.provider_phone = u.Work_Phone,
            n.provider_fax = u.Work_Fax,
            n.tax_id = u.Assoc_Name,
            n.npi = u.NPI
        FROM [#NewHCCFinalMView] [n]
            JOIN [#ProviderId] [u]
                ON n.provider_id = u.Provider_Id;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('043', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO rev.PartCNewHCCOutputMParameter
        (
            [PaymentYear],
            [ModelYear],
            [PaymentStartDate],
            [ProcessedByStartDate],
            [ProcessedByEndDate],
            [ProcessedByFlag],
            [EncounterSource],
            [PlanID],
            [HICN],
            [RAFactorType],
            [HCC],
            [HCCDescription],
            [HCCFactor],
            [HierarchyHCC],
            [HierarchyHCCFactor],
            [PreAdjustedFactor],
            [AdjustedFinalFactor],
            [HCCProcessedPCN],
            [HierarchyHCCProcessedPCN],
            [UniqueConditions],
            [MonthsInDCP],
            [BidAmount],
            [EstimatedValue],
            [RollForwardMonths],
            [ActiveIndicatorForRollForward],
            [PBP],
            [SCC],
            [ProcessedPriorityProcessedByDate],
            [ProcessedPriorityThruDate],
            [ProcessedPriorityDiag],
            [ProcessedPriorityFileID],
            [ProcessedPriorityRAC],
            [ProcessedPriorityRAPSSourceID],
            [DOSPriorityProcessedByDate],
            [DOSPriorityThruDate],
            [DOSPriorityPCN],
            [DOSPriorityDiag],
            [DOSPriorityFileID],
            [DOSPriorityRAC],
            [DOSPriorityRAPSSourceID],
            [ProcessedPriorityICN],
            [ProcessedPriorityEncounterID],
            [ProcessedPriorityReplacementEncounterSwitch],
            [ProcessedPriorityClaimID],
            [ProcessedPrioritySecondaryClaimID],
            [ProcessedPrioritySystemSource],
            [ProcessedPriorityRecordID],
            [ProcessedPriorityVendorID],
            [ProcessedPrioritySubProjectID],
            [ProcessedPriorityMatched],
            [DOSPriorityICN],
            [DOSPriorityEncounterID],
            [DOSPriorityReplacementEncounterSwitch],
            [DOSPriorityClaimID],
            [DOSPrioritySecondaryClaimID],
            [DOSPrioritySystemSource],
            [DOSPriorityRecordID],
            [DOSPriorityVendorID],
            [DOSPrioritySubProjectID],
            [DOSPriorityMatched],
            [ProviderID],
            [ProviderLast],
            [ProviderFirst],
            [ProviderGroup],
            [ProviderAddress],
            [ProviderCity],
            [ProviderState],
            [ProviderZip],
            [ProviderPhone],
            [ProviderFax],
            [TaxID],
            [NPI],
            [SweepDate],
            [PopulatedDate],
            [AgedStatus],
            [UserID],
            [LoadDate],
            [ProcessedPriorityMAO004ResponseDiagnosisCodeID],
            [DOSPriorityMAO004ResponseDiagnosisCodeID],
            [ProcessedPriorityMatchedEncounterICN],
            [DOSPriorityMatchedEncounterICN]
        )
        SELECT DISTINCT
               n.payment_year,
               n.model_year,
               n.PAYMSTART AS [PaymentStartDate],
               n.processed_by_start AS [ProcessedByStartDate],
               n.processed_by_end AS [ProcessedByEndDate],
               n.ProcessedByFlag AS [ProcessedByFlag],
               'RAPS' AS [EncounterSource],
               p.PlanID AS [PlanID],
               n.hicn AS [HICN],
               n.ra_factor_type AS [RAFactorType],
               CASE
                   WHEN n.hcc LIKE '%HCC%'
                        AND n.hcc LIKE 'M-High%' THEN
                       SUBSTRING(n.hcc, CHARINDEX('HCC', n.hcc), LEN(n.hcc))
                   WHEN n.hcc LIKE '%INT%'
                        AND n.hcc LIKE 'M-High%' THEN
                       SUBSTRING(n.hcc, CHARINDEX('INT', n.hcc), LEN(n.hcc))
                   WHEN n.hcc LIKE '%D-HCC%'
                        AND n.hcc LIKE 'M-High%' THEN
                       SUBSTRING(n.hcc, CHARINDEX('D-HCC', n.hcc), LEN(n.hcc))
                   ELSE
                       n.hcc
               END AS [HCC],
               [HCCDescription] = n.hcc_description,
               [HCCFactor] = n.HCC_FACTOR,
               CASE
                   WHEN n.HIER_HCC LIKE '%HCC%'
                        AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                       'MOR-' + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                   WHEN n.HIER_HCC LIKE '%INT%'
                        AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                       'MOR-' + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                   WHEN n.HIER_HCC LIKE '%D-HCC%'
                        AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                       'MOR-' + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                   ELSE
                       n.HIER_HCC
               END AS [HierarchyHCC],
               [HierarchyHCCFactor] = n.HIER_HCC_FACTOR,
               [PreAdjustedFactor] = n.factor_diff,
               (n.FINAL_FACTOR) * (SS.SubmissionSplitWeight) AS [AdjustedFinalFactor],
               [HCCProcessedPCN] = n.HCC_PROCESSED_PCN,
               [HierarchyHCCProcessedPCN] = n.HIER_HCC_PROCESSED_PCN,
               CASE
                   WHEN (
                            m.PaymentYear IS NULL
                            AND m.ModelYear IS NULL
                            AND m.PlanID IS NULL
                            AND m.hicn IS NULL
                            AND m.onlyHCC IS NULL
                            AND m.HCC_Number IS NULL
                            AND m.ra_factor_type IS NULL
                            AND m.scc IS NULL
                            AND m.pbp IS NULL
                        )
                        OR n.hcc LIKE 'INCR%' THEN
                       0
                   ELSE
                       1
               END AS [UniqueConditions],
               [MonthsInDCP] = n.months_in_dcp,
               [BidAmount] = n.bid,
               (n.estimated_value) * (SS.SubmissionSplitWeight) AS [EstimatedValue],
               CASE
                   WHEN @currentyear < @Payment_Year_NewDeleteHCC THEN
                       11
                   ELSE
                       n.RollForwardMonths
               END AS [RollForwardMonths],
               [ActiveIndicatorForRollForward] = n.active_indicator_for_rollforward,
               [PBP] = n.pbp,
               [SCC] = n.scc,
               [ProcessedPriorityProcessedByDate] = n.processed_priority_processed_by,
               [ProcessedPriorityThruDate] = n.processed_priority_thru_date,
               [ProcessedPrioritydDiag] = n.processed_priority_diag,
               [ProcessedPriorityFileID] = n.Processed_Priority_FileID,
               [ProcessedPriorityRAC] = n.Processed_Priority_RAC,
               [ProcessedPriorityRAPSSourceID] = n.Processed_Priority_RAPS_Source_ID,
               [DOSPriorityProcessedByDate] = n.DOS_PRIORITY_PROCESSED_BY,
               [DOSPriorityThruDate] = n.DOS_PRIORITY_THRU_DATE,
               [DOSPriorityPCN] = n.DOS_PRIORITY_PCN,
               [DOSPriorityDiag] = n.DOS_PRIORITY_DIAG,
               [DOSPriorityFileID] = n.DOS_PRIORITY_FILEID,
               [DOSPriorityRAC] = n.DOS_PRIORITY_RAC,
               [DOSPriorityRAPSSourceID] = n.DOS_PRIORITY_RAPS_SOURCE,
               NULL AS [ProcessedPriorityICN],
               NULL AS [ProcessedPriorityEncounterID],
               NULL AS [ProcessedPriorityReplacementEncounterSwitch],
               NULL AS [ProcessedPriorityClaimID],
               NULL AS [ProcessedPrioritySecondaryClaimID],
               NULL AS [ProcessedPrioritySystemSource],
               NULL AS [ProcessedPriorityRecordID],
               NULL AS [ProcessedPriorityVendorID],
               NULL AS [ProcessedPrioritySubProjectID],
               NULL AS [ProcessedPriorityMatched],
               NULL AS [DOSPriorityICN],
               NULL AS [DOSPriorityEncounterID],
               NULL AS [DOSPriorityReplacementEncounterSwitch],
               NULL AS [DOSPriorityClaimID],
               NULL AS [DOSPrioritySecondaryClaimID],
               NULL AS [DOSPrioritySystemSource],
               NULL AS [DOSPriorityRecordID],
               NULL AS [DOSPriorityVendorID],
               NULL AS [DOSPrioritySubProjectID],
               NULL AS [DOSPriorityMatched],
               [ProviderID] = n.provider_id,
               [ProviderLast] = n.provider_last,
               [ProviderFirst] = n.provider_first,
               [ProviderGroup] = n.provider_group,
               [ProviderAddress] = n.provider_address,
               [ProviderCity] = n.provider_city,
               [ProviderState] = n.provider_state,
               [ProviderZip] = n.provider_zip,
               [ProviderPhone] = n.provider_phone,
               [ProviderFax] = n.provider_fax,
               [TaxID] = n.tax_id,
               [NPI] = n.npi,
               [SweepDate] = n.SWEEP_DATE,
               GETDATE() AS [PopulatedDate],
               [AgedStatus] = CASE
                                  WHEN n.AGED = 1 THEN
                                      'Aged'
                                  WHEN n.AGED = 0 THEN
                                      'Disabled'
                                  ELSE
                                      'Not Applicable'
                              END,
               SUSER_NAME() AS [UserID],
               GETDATE() AS [LoadDate],
               NULL AS [ProcessedPriorityMAO004ResponseDiagnosisCodeID],
               NULL AS [DOSPriorityMAO004ResponseDiagnosisCodeID],
               NULL AS [ProcessedPriorityMatchedEncounterICN],
               NULL AS [DOSPriorityMatchedEncounterICN]
        FROM [#NewHCCFinalMView] [n]
            JOIN [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit [SS] WITH (NOLOCK)
                ON n.payment_year = SS.PaymentYear
                   AND SS.SubmissionModel = 'RAPS'
                   AND SS.MYUFlag = 'N'
            LEFT JOIN [#FinalUniqueCondition] [m]
                ON n.payment_year = m.PaymentYear
                   AND n.model_year = m.ModelYear
                   AND n.planid = m.PlanID
                   AND n.hicn = m.hicn
                   AND n.onlyHCC = m.onlyHCC
                   AND n.HCC_Number = m.HCC_Number
                   AND n.ra_factor_type = m.ra_factor_type
                   AND n.pbp = m.pbp
                   AND n.scc = m.scc
            LEFT JOIN [#PlanIdentifier] [p]
                ON n.planid = p.PlanIdentifier;

 --Modified for RRI-348/RRI-908
		SET @RowCount = Isnull(@@ROWCOUNT,0);
		SET @ReportOutputByMonthID = 'M';
		SET @TableName = 'rev.PartCNewHCCOutputMParameter';


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('044', 0, 1) WITH NOWAIT;
        END;

    END;

		IF (OBJECT_ID('tempdb.dbo.#FinalUniqueCondition') IS NOT NULL)
        BEGIN
            DROP TABLE [#FinalUniqueCondition];
        END;

        IF (OBJECT_ID('tempdb.dbo.#ProviderId') IS NOT NULL)
        BEGIN
            DROP TABLE [#ProviderId];
        END;

        IF (OBJECT_ID('etl.IntermediateRAPSNewHCCOutput') IS NOT NULL)
        BEGIN
            TRUNCATE TABLE [etl].[IntermediateRAPSNewHCCOutput];
        END;

        IF (OBJECT_ID('tempdb.dbo.#MaxMonthHCC') IS NOT NULL)
        BEGIN
            DROP TABLE [#MaxMonthHCC];
        END;

        IF (OBJECT_ID('tempdb.dbo.#NewHCCFinalDView') IS NOT NULL)
        BEGIN
            DROP TABLE [#NewHCCFinalDView];
        END;

		IF (OBJECT_ID('tempdb.dbo.#NewHCCFinalMView') IS NOT NULL)
        BEGIN
            DROP TABLE [#NewHCCFinalMView];
        END;

        IF (OBJECT_ID('tempdb.dbo.#RollForward_Months') IS NOT NULL)
        BEGIN
            DROP TABLE [#RollForward_Months];
        END;

		IF (OBJECT_ID('tempdb.dbo.#MMR_BID') IS NOT NULL)
		BEGIN
			DROP TABLE [#MMR_BID];
		END;
		
		IF (OBJECT_ID('tempdb.dbo.#MMR_BIDMaxPaymStart') IS NOT NULL)
		BEGIN
		    DROP TABLE [#MMR_BIDMaxPaymStart];
	    END;

	    IF (OBJECT_ID('tempdb.dbo.#MonthsInDCP') IS NOT NULL)
	    BEGIN
			DROP TABLE [#MonthsInDCP];
		END;

END;