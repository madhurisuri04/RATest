/*
Name			:	spr_EstRecv_EDS_New_HCC
Author			:	Rakshit Lall
Date			:	07/13/2017
SP Call			:	EXEC [rev].[spr_EstRecv_EDS_New_HCC] '2018', '1/1/2017', '12/31/2017', 'M',-1, 0
Version			:	1.0
Description		:	SP Will be called by the wrapper to load EDS data to a permanent table used by extract/new HCC Report
Version History	:
Version #		Author			Date		TFS				Purpose
1.1				Rakshit Lall	9/13/2017					Replace DBO summary reference with REF + Changed WHERE filter to include more RAFactorTypes
1.2             David Waddell   06/07/2018  70876			Populated  LastAssignedHICN col. in the [etl].].[PartCNewHCCOutputMParameter]  table. (Section 220.1) 
1.3				Rakshit Lall	06/21/2018	71498			Replaced "dbo.tbl_EstRecv_ModelSplits" with "[lk_Risk_Score_Factors_PartC]"
1.4				Rakshit Lall	07/30/2018	72327			Remove restrictions that stop the data for future years to get processed + The changes are NOT made to the same SP in the report 
															level because that's not being used
1.5				Rakshit Lall	09/07/2018	73005			Changed the source table to "[rev].[tbl_Summary_RskAdj_EDS_MOR_Combined]" on Line # 585 + The changes are NOT made to the same SP in the report 
															level because that's not being used
1.6				David Waddell/	05/22/2019	75870(RE-4908)	Finalizing Configuration changes to Report DB version
                Anand S.
1.7				David Waddell	06/18/2019  RE-5231			Performance Enhancement for EstRecv EDS New HCC. Resolve data not being populated in Target table issue.
1.8				Anand			09/03/2019	RE - 6188/76718       Added Valuation part based on Reportoutput = 'V' 
1.9				David Waddell   2/12/2020   RE-7582        New HCC Process Improvement Phase 2 - rev.spr_EstRecv_EDS_New_HCC (RE-7582). Replace #NewHCC_Output with etl.IntermediateEDSNewHCCOutput  
2.0             David Waddell   09/18/2020  RRI-164        New HCC optimization process for EDS.
2.1             David Waddell   10/23/2020  RRI-282         Resolve Dividing by Zero Issue. Identify where normalization factor legacy table is being used within our processes, and replace this 
                                                            with the modernized version of the normalization table.
2.2				Anand			02/16/2021  RRI-483/80801   Removed Legacy outdated logic
2.3             Madhuri Suri    03/08/2021  RRI-755         Add RAPS Source ID logic
2.4             David Waddell   06/24/2021  RRI-1258        Add New HCC Log Tracking logic. (Section 41 & 46)
*/

CREATE PROCEDURE [rev].[spr_EstRecv_EDS_New_HCC]
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
    DECLARE @fromdate DATETIME;
    DECLARE @thrudate DATETIME;
    DECLARE @MaxBidPY VARCHAR(5);
    DECLARE @MaxESRDPY INT;
    DECLARE @Populated_Date DATETIME = GETDATE();
    DECLARE @qry_sql NVARCHAR(MAX);
    DECLARE @currentyear VARCHAR(4) = YEAR(GETDATE());
    DECLARE @Year_NewDeleteHCC_PaymentYearMinuseOne INT;
    DECLARE @Year_NewDeleteHCC_PaymentYear VARCHAR(4);
    DECLARE @DeleteBatch INT;


    --RE - 6188  Start

    IF @currentyear < @Payment_Year_NewDeleteHCC
       AND @ReportOutputByMonth = 'V'
    BEGIN
        RAISERROR('Error Message: If ReportOutputByMonth = V, Payment Year cannot exceed Current Year.', 16, -1);

    END;

    --RE - 6188  End

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('001', 0, 1) WITH NOWAIT;
    END;


    --Create #PlanIdentifier temp table

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
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE())  AS VARCHAR(10)) + ' secs | '
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

    SELECT @MaxESRDPY = MAX([PayMo])
    FROM [$(HRPReporting)].dbo.lk_Ratebook_ESRD;



    -- Get Rollup data from ReportDB
    DECLARE @Clnt_DB VARCHAR(128);

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


    IF OBJECT_ID('[etl].[IntermediateEDSNewHCCOutput]', 'U') IS NOT NULL
        TRUNCATE TABLE [etl].[IntermediateEDSNewHCCOutput];

    INSERT INTO [etl].[IntermediateEDSNewHCCOutput]
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
        [MinProcessbySeqnum],
        [ThruPriorityDiag],
        [ThruPriorityPCN],
        [ThruPriorityProcessedBy],
        [RAFactorTypeOrig],
        [ThruPriorityFileID],
        [ThruPriorityRAPSSourceID],
        [ThruPriorityRAC],
        [PaymStartYear],
        [UnionqueryInd],
        [ProcessedPriorityMAO004ResponseDiagnosisCodeID],
        [DOSPriorityMAO004ResponseDiagnosisCodeID],
        [Aged],
        [ProviderID],
        [MemberMonths]
    )
    SELECT [PlanID] = n.PlanID,
           [HICN] = n.HICN,
           [PaymentYear] = n.PaymentYear,
           [PaymStart] = n.PaymStart,
           [ModelYear] = n.Model_Year,
           [ProcessedByStart] = @PROCESSBY_START,
           [ProcessedByEnd] = @PROCESSBY_END,
           [HCC] = n.Factor_Desc,
           [Factor] = Isnull(n.Factor,0),
           [HCCOrig] = n.Factor_Desc_ORIG,
           [OnlyHCC] = LEFT(n.Factor_Desc_ORIG, 3),
           [RAFactorType] = n.RAFT,
           [HCCNumber] = n.HCC_Number,
           [ProcessedPriorityProcessed_By] = n.Min_ProcessBy,
           [ProcessedPriorityThruDate] = n.processed_priority_thru_date,
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
           [ThruPriorityProcessedBy] = n.thru_priority_processed_by,
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
           [ProcessedPriorityMAO004ResponseDiagnosisCodeID] = n.[Min_ProcessBy_MAO004ResponseDiagnosisCodeId],
           [DOSPriorityMAO004ResponseDiagnosisCodeID] = n.[Min_ThruDate_MAO004ResponseDiagnosisCodeId],
           [Aged] = n.[Aged],
           [ProviderID] = ISNULL(n.Processed_Priority_Provider_ID, n.Thru_Priority_Provider_ID),
           [MemberMonths] = 1
    FROM rev.tbl_Summary_RskAdj_EDS_MOR_Combined n
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
			  OR Factor_Desc LIKE 'MOR-INCR%'
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

    -- Performance Tuning (Created Temp table and indexes) Start
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
        RAISERROR('009', 0, 1) WITH NOWAIT;
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
        RAISERROR('005', 0, 1) WITH NOWAIT;
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
        [hosp] CHAR(1), 
		[PlanID] INT
    );
	
    INSERT INTO [#MMR_BID]
    (
        [pbp],
        [scc],
        [MABID],
        [HICN],
        [paymstart],
        [payment_year],
        [hosp], 
		[PlanID]
    )
    SELECT mmr.PBP,
           mmr.SCC,
           CASE WHEN (MMR.SCC IS NOT NULL 
		       AND MMR.OOA IS NOT NULL
			   AND b.MA_BID IS NOT NULL)
			   THEN B.MA_BID ELSE mmr.MABID END ,
           mmr.HICN,
           mmr.PaymStart,
           mmr.PaymentYear,
           mmr.HOSP,
		   mmr.PlanID
    FROM rev.tbl_Summary_RskAdj_MMR [mmr]
	LEFT JOIN dbo.tbl_BIDS_Rollup b ON mmr.SCC = b.SCC 
	                     AND MMR.PBP = B.PBP
						 AND MMR.PAYMENTYEAR = B.BID_YEAR
						 AND MMR.PLANID = B.PLANIDENTIFIER
    WHERE mmr.PaymentYear = @Payment_Year_NewDeleteHCC;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('006', 0, 1) WITH NOWAIT;
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
        RAISERROR('007', 0, 1) WITH NOWAIT;
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
    FROM etl.IntermediateEDSNewHCCOutput [n]
        JOIN [#MMR_BID] [b]
            ON n.HICN = b.HICN
               AND n.PaymStart = b.paymstart
               AND n.PaymentYear = b.payment_year
			   AND n.PlanID = b.PlanID
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
        RAISERROR('008', 0, 1) WITH NOWAIT;
    END;

    -- Ticket # 26951  Start
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
          AND [SubmissionModel] = 'EDS';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('009', 0, 1) WITH NOWAIT;
    END;

    DECLARE @maxModelYear INT;


    SELECT @maxModelYear = MAX([ModelYear])
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC
    WHERE [PaymentYear] = @Payment_Year_NewDeleteHCC
          AND [SubmissionModel] = 'EDS';


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
        RAISERROR('010', 0, 1) WITH NOWAIT;
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
        RAISERROR('011', 0, 1) WITH NOWAIT;
    END;


    UPDATE [hccop]
    SET hccop.HCCDescription = rskmod.Description
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
        INNER JOIN [#lk_Factors_PartC_HCC_INT] [rskmod]
            -- Performance Tuning
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
        RAISERROR('012', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartC_HCC_INT') IS NOT NULL)
    BEGIN
        DROP TABLE [#lk_Factors_PartC_HCC_INT];
    END;


    UPDATE [hccop]
    SET hccop.HCCDescription = rskmod.[Description]
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
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
        RAISERROR('013', 0, 1) WITH NOWAIT;
    END;


    -- BD: update description for D-HCC
    UPDATE [hccop]
    SET hccop.HCCDescription = rskmod.Description
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
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
        RAISERROR('014', 0, 1) WITH NOWAIT;
    END;


    UPDATE [HCCOP]
    SET HCCOP.HCCDescription = RskMod.Description
    FROM etl.IntermediateEDSNewHCCOutput [HCCOP]
        INNER JOIN [#lk_Factors_PartG_DHCC] [RskMod]
            -- Performance Tuning
            ON RskMod.HCC_Label_NUMBER_DHCC = HCCOP.HCCNumber
               AND RskMod.HCC_LABEL_DHCC = LEFT(HCCOP.HCCOrig, 5)
        INNER JOIN [#Tbl_ModelSplit] [ms]
            ON RskMod.Payment_Year = ms.ModelYear
               AND HCCOP.ModelYear = ms.ModelYear --Ticket # 25351
    WHERE HCCOP.RAFactorType IN ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          AND LEFT(HCCOP.HCCOrig, 5) = 'D-HCC';

    IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartG_DHCC') IS NOT NULL)
    BEGIN
        DROP TABLE [#lk_Factors_PartG_DHCC];
    END;
    IF (OBJECT_ID('tempdb.dbo.#Tbl_ModelSplit') IS NOT NULL)
    BEGIN
        DROP TABLE [#Tbl_ModelSplit];
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

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('016', 0, 1) WITH NOWAIT;
    END;

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
    SELECT [Factor_Desc],
           [Factor],
           [Model_Year],
           [Min_ProcessBy_PCN],
           [PaymentYear],
           [RAFT],
           [HCC] = LEFT([Factor_Desc_ORIG], 3),
           [HCC_Number],
           [HICN],
           [Min_ProcessBy_PCN]
    FROM rev.tbl_Summary_RskAdj_EDS_MOR_Combined
    WHERE [PaymentYear] = @Payment_Year_NewDeleteHCC
          AND ( [Factor_Desc] LIKE 'HIER%')
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
           hccop.UnionqueryInd,
           MIN(drp.HCC_Number)
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
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
             [hccop].[UnionqueryInd];

			 
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
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
        INNER JOIN [#HIER_hierarchy] [hier]
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
               AND hier.Unionqueryind = hccop.UnionqueryInd
        INNER JOIN [#New_HCC_Rollup] [drp]
            ON drp.HICN = hccop.HICN
               AND drp.Factor_Desc LIKE 'HIER%'
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
               --and drp.Unionqueryind = hccop.Unionqueryind
               AND drp.HCC_Number = hier.MinHCCNumber;



    IF (OBJECT_ID('tempdb.dbo.#HIER_hierarchy') IS NOT NULL)
    BEGIN
        DROP TABLE [#HIER_hierarchy];
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('019', 0, 1) WITH NOWAIT;
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
           hccop.HCC ,
           MIN(drp.HCCNumber)
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy [hier]
            ON hier.Payment_Year = hccop.ModelYear
               AND hier.RA_FACTOR_TYPE = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models [rskmod]
            ON rskmod.Payment_Year = hier.Payment_Year
               AND rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               AND CAST(SUBSTRING(rskmod.Factor_Description, 4, LEN(rskmod.Factor_Description) - 3) AS INT) = CAST(SUBSTRING(
                                                                                                                                hier.HCC_DROP,
                                                                                                                                4,
                                                                                                                                LEN(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) AS INT)
               AND LEFT(rskmod.Factor_Description, 3) = LEFT(hier.HCC_DROP, 3)
               AND rskmod.Demo_Risk_Type = 'risk'
        INNER JOIN etl.IntermediateEDSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCCNumber = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.HCC LIKE 'INCR%'
               AND drp.OnlyHCC = LEFT(hier.HCC_DROP, 3)
               AND drp.[RAFactorType] = hccop.RAFactorType
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
    --and HCCOP.hicn = '007328933A'	
    --and HCCOP.paymstart = '2014-01-01 00:00:00.000'
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
    SET hccop.HierHCCOld = drp.HCC,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.HierHCCProcessedPCN
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
        JOIN [#INCR_hierarchy] [hier]
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
        JOIN etl.IntermediateEDSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCC LIKE 'INCR%'
               AND drp.RAFactorType = hccop.RAFactorType
               AND drp.ModelYear = hccop.ModelYear
               AND drp.HCCNumber = hier.[MinHCCNumber];

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
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
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
        INNER JOIN etl.IntermediateEDSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCCNumber = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.HCC LIKE 'MOR-INCR%'
               AND drp.OnlyHCC = LEFT(hier.HCC_DROP, 3)
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
    SET hccop.HierHCCOld = drp.HCC,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.ProcessedPriorityPCN
    FROM etl.IntermediateEDSNewHCCOutput [hccop]
        INNER JOIN [#MOR_hierarchy] [hier]
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
        INNER JOIN etl.IntermediateEDSNewHCCOutput [drp]
            ON drp.HICN = hccop.HICN
               AND drp.HCC LIKE 'MOR-INCR%'
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
    -- Ticket # 26951 Start

  
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
          AND a.SubmissionModel = 'EDS'
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
          AND a.SubmissionModel = 'EDS'
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
          AND a.SubmissionModel = 'EDS'
          AND a.Segment IN ( 'Dialysis', 'Transplant' );

		  
   -------Correction to Update Values=> Start Part 1 ----
    IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
    BEGIN


        UPDATE [HCCOP]
        SET HCCOP.FinalFactor = CASE
                                    WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                        ISNULL(
                                                  (ROUND(
                                                            ROUND(
                                                                     ROUND(
                                                                              (HCCOP.Factor)
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
                                    ELSE
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
                                                                 ) * [SplitSegmentWeight],
                                                            3
                                                        )
                                                  ),
                                                  0
                                              )
                                END,
            HCCOP.EstimatedValue = CASE
                                       WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                           ISNULL(
                                                     (ROUND(
                                                               ROUND(
                                                                        ROUND(
                                                                                 (HCCOP.Factor)
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
                                       ELSE
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
                                                                    ) * [SplitSegmentWeight],
                                                               3
                                                           )
                                                     ) * (HCCOP.BID * 12),
                                                     0
                                                 )
                                   END,
            HCCOP.FactorDiff = CASE
                                   WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                       ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                                   ELSE
                                       ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                               END
        FROM etl.IntermediateEDSNewHCCOutput [HCCOP]
            INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
        WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
              AND HCCOP.RAFactorType IN ( 'CN', 'CF', 'CP', 'C', 'I' ) -- Ticket # 25426
              AND m.SubmissionModel = 'EDS';

      

        UPDATE [HCCOP]
        SET HCCOP.EstimatedValue = CASE
                                       WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                           CASE
                                               WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor) / (m.PartCNormalizationFactor), 3)
                                                              * (HCCOP.BID * 12)
                                                             ),
                                                             0
                                                         )
                                               ELSE
                                                   ISNULL(
                                                             (ROUND(
                                                                       ROUND(
                                                                                (HCCOP.Factor)
                                                                                / (m.PartCNormalizationFactor),
                                                                                3
                                                                            ) * (1 - m.CodingIntensity),
                                                                       3
                                                                   ) * (HCCOP.BID * 12)
                                                             ),
                                                             0
                                                         )
                                           END
                                       ELSE
                                           CASE
                                               WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                   ISNULL(
                                                             (ROUND(
                                                                       (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                       / (m.PartCNormalizationFactor),
                                                                       3
                                                                   ) * (HCCOP.BID * 12)
                                                             ),
                                                             0
                                                         )
                                               ELSE
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
                                           END
                                   END,
            HCCOP.FinalFactor = CASE
                                    WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                        CASE
                                            WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL((ROUND((HCCOP.Factor) / (M.PartCNormalizationFactor), 3)), 0)
                                            ELSE
                                                ISNULL(
                                                          (ROUND(
                                                                    ROUND(
                                                                             (HCCOP.Factor)
                                                                             / (m.PartCNormalizationFactor),
                                                                             3
                                                                         ) * (1 - m.CodingIntensity),
                                                                    3
                                                                )
                                                          ),
                                                          0
                                                      )
                                        END
                                    ELSE
                                        CASE
                                            WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL(
                                                          (ROUND(
                                                                    (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                    / (m.PartCNormalizationFactor),
                                                                    3
                                                                )
                                                          ),
                                                          0
                                                      )
                                            ELSE
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
                                                                )
                                                          ),
                                                          0
                                                      )
                                        END
                                END,
            HCCOP.FactorDiff = CASE
                                   WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                       CASE
                                           WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                               ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                                           ELSE
                                               ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                                       END
                                   ELSE
                                       CASE
                                           WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                               ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                                           ELSE
                                               ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                                       END
                               END
        FROM etl.IntermediateEDSNewHCCOutput [HCCOP]
            INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
        WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
              AND HCCOP.RAFactorType NOT IN ( 'CN', 'CF', 'CP', 'C', 'I' );

    END;

 
    ELSE
    BEGIN
        --set @start = getdate() 

        UPDATE [HCCOP]
        SET HCCOP.EstimatedValue = CASE
                                       WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                           ISNULL(
                                                     (ROUND(
                                                               ROUND(
                                                                        ROUND(
                                                                                 (HCCOP.Factor)
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
                                       ELSE
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
                                                                    ) * [SplitSegmentWeight],
                                                               3
                                                           )
                                                     ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1)),
                                                     0
                                                 )
                                   END,
            HCCOP.FinalFactor = CASE
                                    WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                        ISNULL(
                                                  (ROUND(
                                                            ROUND(
                                                                     ROUND(
                                                                              (HCCOP.Factor)
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
                                    ELSE
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
                                                                 ) * [SplitSegmentWeight],
                                                            3
                                                        )
                                                  ),
                                                  0
                                              )
                                END,
            HCCOP.FactorDiff = CASE
                                   WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                       ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                                   ELSE
                                       ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                               END
        FROM etl.IntermediateEDSNewHCCOutput [HCCOP]
              INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
        WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
              AND HCCOP.RAFactorType IN ( 'CN', 'CF', 'CP', 'C', 'I' ) -- Ticket # 25426
              AND m.SubmissionModel = 'EDS';



        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('031', 0, 1) WITH NOWAIT;
        END;

        UPDATE [HCCOP]
        SET HCCOP.EstimatedValue = CASE
                                       WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                           CASE
                                               WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor) / (m.PartCNormalizationFactor), 3)
                                                              * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1))
                                                             ),
                                                             0
                                                         )
                                               ELSE
                                                   ISNULL(
                                                             (ROUND(
                                                                       ROUND(
                                                                                (HCCOP.Factor)
                                                                                / (m.PartCNormalizationFactor),
                                                                                3
                                                                            ) * (1 - m.CodingIntensity),
                                                                       3
                                                                   ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1))
                                                             ),
                                                             0
                                                         )
                                           END
                                       ELSE
                                           CASE
                                               WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                   ISNULL(
                                                             (ROUND(
                                                                       (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                       / (m.PartCNormalizationFactor),
                                                                       3
                                                                   ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1))
                                                             ),
                                                             0
                                                         )
                                               ELSE
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
                                                                   ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1))
                                                             ),
                                                             0
                                                         )
                                           END
                                   END,
            HCCOP.FinalFactor = CASE
                                    WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                        CASE
                                            WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL((ROUND((HCCOP.Factor) / (m.PartCNormalizationFactor), 3)), 0)
                                            ELSE
                                                ISNULL(
                                                          (ROUND(
                                                                    ROUND(
                                                                             (HCCOP.Factor)
                                                                             / (m.PartCNormalizationFactor),
                                                                             3
                                                                         ) * (1 - m.CodingIntensity),
                                                                    3
                                                                )
                                                          ),
                                                          0
                                                      )
                                        END
                                    ELSE
                                        CASE
                                            WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL(
                                                          (ROUND(
                                                                    (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                    / (m.PartCNormalizationFactor),
                                                                    3
                                                                )
                                                          ),
                                                          0
                                                      )
                                            ELSE
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
                                                                )
                                                          ),
                                                          0
                                                      )
                                        END
                                END,
            HCCOP.FactorDiff = CASE
                                   WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                       CASE
                                           WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                               ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                                           ELSE
                                               ISNULL((ROUND((HCCOP.Factor), 3)), 0)
                                       END
                                   ELSE
                                       CASE
                                           WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                               ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                                           ELSE
                                               ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                                       END
                               END
        FROM etl.IntermediateEDSNewHCCOutput [HCCOP]
            INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
        WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
              AND HCCOP.RAFactorType NOT IN ( 'CN', 'CF', 'CP', 'C', 'I' );

    END;

-------Correction to Update Values=> Start Part 1 ----

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
        FROM etl.IntermediateEDSNewHCCOutput
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


        UPDATE [etl].[IntermediateEDSNewHCCOutput]
        SET HCCPCNMatch = PCNFlag
        FROM etl.IntermediateEDSNewHCCOutput hccop
            JOIN #ValuationPerfFix a
                ON a.Processed_Priority_PCN = hccop.ProcessedPriorityPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';


        IF (OBJECT_ID('tempdb.dbo.#ValuationPerfFix') IS NOT NULL)
        BEGIN
            DROP TABLE #ValuationPerfFix;
        END;

        --Ticket # 33931 Start

        UPDATE [etl].[IntermediateEDSNewHCCOutput]
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] HCCOP
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

        UPDATE HCCOP --etl.IntermediateEDSNewHCCOutput
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] HCCOP
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

        UPDATE HCCOP --etl.IntermediateEDSNewHCCOutput
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] HCCOP
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


        UPDATE hccop --etl.IntermediateEDSNewHCCOutput
        SET HCCPCNMatch = PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] hccop
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


        UPDATE hccop --etl.IntermediateEDSNewHCCOutput
        SET HierPCNMatch = PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] hccop
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

        UPDATE HCCOP --etl.IntermediateEDSNewHCCOutput
        SET HierPCNMatch = PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] HCCOP
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

        UPDATE HCCOP --etl.IntermediateEDSNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] HCCOP
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

        UPDATE hccop --etl.IntermediateEDSNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM [etl].[IntermediateEDSNewHCCOutput] hccop
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

        UPDATE hccop --etl.IntermediateEDSNewHCCOutput
        SET HierPCNMatch = 0
        FROM [etl].[IntermediateEDSNewHCCOutput] hccop
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

	       IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
        BEGIN

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
                HCCOP.EstimatedValue = ISNULL(
                                                 (ROUND(
                                                           ROUND(
                                                                    ROUND(
                                                                             (HCCOP.Factor
                                                                              - ISNULL(HCCOP.HierFactorOld, 0)
                                                                             )
                                                                             / m.PartCNormalizationFactor,
                                                                             3
                                                                         ) * (1 -  m.CodingIntensity),
                                                                    3
                                                                ) * m.SplitSegmentWeight,
                                                           3
                                                       )
                                                 ) * (HCCOP.BID * 12),
                                                 0
                                             ),
                HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
            FROM etl.IntermediateEDSNewHCCOutput HCCOP
                INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType IN ( 'C', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
                  AND HCCOP.HCCPCNMatch = 1
                  AND HCCOP.HierPCNMatch = 0;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('040', 0, 1) WITH NOWAIT;
            END;


            UPDATE HCCOP
            SET HCCOP.FinalFactor = CASE
                                        WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                            ISNULL(
                                                      (ROUND(
                                                                (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                / (m.PartCNormalizationFactor),
                                                                3
                                                            )
                                                      ),
                                                      0
                                                  )
                                        ELSE
                                            ISNULL(
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
                                                  )
                                    END,
                HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                               ISNULL(
                                                         (ROUND(
                                                                   (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                   / (m.PartCNormalizationFactor),
                                                                   3
                                                               ) * (HCCOP.BID * 12)
                                                         ),
                                                         0
                                                     )
                                           ELSE
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
                                       END,
                HCCOP.FactorDiff = CASE
                                       WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                           ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                                       ELSE
                                           ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                                   END
            FROM etl.IntermediateEDSNewHCCOutput HCCOP
                 INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
                  AND HCCOP.HCCPCNMatch = 1
                  AND HCCOP.HierPCNMatch = 0;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('041', 0, 1) WITH NOWAIT;
            END;


        END;
        ELSE
        BEGIN

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
                                                                      ) * (1 -  m.CodingIntensity),
                                                                 3
                                                             ) * m.SplitSegmentWeight,
                                                        3
                                                    )
                                              ),
                                              0
                                          ),
                HCCOP.EstimatedValue = ISNULL(
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
                                             ),
                HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
            FROM etl.IntermediateEDSNewHCCOutput HCCOP
             INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType IN ( 'C', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
                  AND HCCOP.HierPCNMatch = 0;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('042', 0, 1) WITH NOWAIT;
            END;

            UPDATE hccop
            SET hccop.FinalFactor = CASE
                                        WHEN hccop.RAFactorType IN ( 'D', 'ED' ) THEN
                                            ISNULL(
                                                      (ROUND(
                                                                (hccop.Factor - ISNULL(hccop.HierFactorOld, 0))
                                                                / ( m.PartCNormalizationFactor),
                                                                3
                                                            )
                                                      ),
                                                      0
                                                  )
                                        ELSE
                                            ISNULL(
                                                      (ROUND(
                                                                ROUND(
                                                                         (hccop.Factor - ISNULL(hccop.HierFactorOld, 0))
                                                                         / ( m.PartCNormalizationFactor),
                                                                         3
                                                                     ) * (1 -  m.CodingIntensity),
                                                                3
                                                            )
                                                      ),
                                                      0
                                                  )
                                    END,
                hccop.EstimatedValue = CASE
                                           WHEN hccop.RAFactorType IN ( 'D', 'ED' ) THEN
                                               ISNULL(
                                                         (ROUND(
                                                                   (hccop.Factor - ISNULL(hccop.HierFactorOld, 0))
                                                                   / ( m.PartCNormalizationFactor),
                                                                   3
                                                               ) * (hccop.BID * ISNULL(hccop.MemberMonths, 1))
                                                         ),
                                                         0
                                                     )
                                           ELSE
                                               ISNULL(
                                                         (ROUND(
                                                                   ROUND(
                                                                            (hccop.Factor
                                                                             - ISNULL(hccop.HierFactorOld, 0)
                                                                            )
                                                                            / ( m.PartCNormalizationFactor),
                                                                            3
                                                                        ) * (1 -  m.CodingIntensity),
                                                                   3
                                                               ) * (hccop.BID * ISNULL(hccop.MemberMonths, 1))
                                                         ),
                                                         0
                                                     )
                                       END,
                hccop.FactorDiff = CASE
                                       WHEN hccop.RAFactorType IN ( 'D', 'ED' ) THEN
                                           ISNULL((ROUND((hccop.Factor - ISNULL(hccop.HierFactorOld, 0)), 3)), 0)
                                       ELSE
                                           ISNULL((ROUND((hccop.Factor - ISNULL(hccop.HierFactorOld, 0)), 3)), 0)
                                   END
            FROM etl.IntermediateEDSNewHCCOutput hccop
                INNER JOIN #lk_Risk_Score_Factors_PartC [m]
                ON m.ModelYear = HCCOP.ModelYear
                   AND m.PaymentYear = HCCOP.PaymentYear
                   AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(hccop.HOSP, 'N') <> 'Y'
                  AND hccop.RAFactorType NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' )
                  AND hccop.HCCPCNMatch = 1
                  AND hccop.HierPCNMatch = 0;

        END;



        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('043', 0, 1) WITH NOWAIT;
        END;


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
    SELECT [PlanID],
           [HICN],
           [RAFactorType],
           [PBP],
           [SCC],
           [member_months] = MAX([PaymStart])
    FROM [etl].[IntermediateEDSNewHCCOutput]
    GROUP BY [PlanID],
             [HICN],
             [RAFactorType],
             [PBP],
             [SCC];

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('035', 0, 1) WITH NOWAIT;
    END;


    CREATE NONCLUSTERED INDEX [ix_rollforward_months_HICN]
    ON [#RollForward_Months] (
                                 [hicn],
                                 [ra_factor_type],
                                 [planid],
                                 [scc],
                                 [pbp]
                             ); -- Performance Tuning (Added extra columns in Index)



    DECLARE @MaxMonth INT; -- Ticket # 29157

    SELECT @MaxMonth = MONTH(MAX([PaymStart]))
    FROM [etl].[IntermediateEDSNewHCCOutput]; -- Ticket # 29157


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('036', 0, 1) WITH NOWAIT;
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
        FROM [etl].[IntermediateEDSNewHCCOutput]
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
        RAISERROR('037', 0, 1) WITH NOWAIT;
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
			[Aged]
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
			   n.aged
        FROM [etl].[IntermediateEDSNewHCCOutput] [n]
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
        RAISERROR('038', 0, 1) WITH NOWAIT;
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
	INNER JOIN [etl].[IntermediateEDSNewHCCOutput] N ON U.Provider_ID=N.ProviderID
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
        RAISERROR('039', 0, 1) WITH NOWAIT;
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
        RAISERROR('040', 0, 1) WITH NOWAIT;
    END;


    --RE - 6188 Start

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
			[ProcessedPriorityMAO004ResponseDiagnosisCodeID] BIGINT NULL, ---RRI 755 MS
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
            AGED INT ,--TFS 59836,
			[ProcessedPriorityICN] BIGINT NULL,---RRI 755 MS
            [ProcessedPriorityEncounterID] BIGINT NULL,
            [ProcessedPriorityReplacementEncounterSwitch] CHAR(1) NULL,
            [ProcessedPriorityClaimID] VARCHAR(50) NULL,
            [ProcessedPrioritySecondaryClaimID] VARCHAR(50) NULL,
            [ProcessedPrioritySystemSource] VARCHAR(30) NULL,
            [ProcessedPriorityRecordID] VARCHAR(80) NULL,
            [ProcessedPriorityVendorID] VARCHAR(100) NULL,
            [ProcessedPrioritySubProjectID] INT NULL,
            [ProcessedPriorityMatched] CHAR(1) NULL,
            [ProcessedPriorityMatchedEncounterICN] BIGINT NULL---RRI 755 MS

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
			[ProcessedPriorityMAO004ResponseDiagnosisCodeID],---RRI 755 MS
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
               [Unionqueryind] = n.UnionqueryInd,
               [planid] = n.PlanID,
               [hicn] = n.HICN,
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
               [pbp] = n.PBP,
               [scc] = ISNULL(n.SCC, 'OOA'),
               n.ProcessedPriorityProcessedBy,
               n.ProcessedPriorityThruDate,
               n.ProcessedPriorityDiag,
               n.ProcessedPriorityFileID,
               n.ProcessedPriorityRAC,
               n.ProcessedPriorityRAPSSourceID,
			   n.[ProcessedPriorityMAO004ResponseDiagnosisCodeID], --RRI 755 MS 
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
                                  WHEN n.UnionqueryInd = 1 THEN
                                      @initial_flag
                                  WHEN n.UnionqueryInd = 2 THEN
                                      @myu_flag
                                  WHEN n.UnionqueryInd = 3 THEN
                                      @final_flag
                              END,
               [Populated_Date] = @Populated_Date,
               [onlyHCC] = n.OnlyHCC,
               [HCC_Number] = n.HCCNumber,
               n.Aged
        FROM [etl].[IntermediateEDSNewHCCOutput] n
            JOIN #RollForward_Months r
                ON n.HICN = r.hicn
                   AND n.RAFactorType = r.ra_factor_type
                   AND n.PlanID = r.planid
                   AND n.SCC = r.scc
                   AND n.PBP = r.pbp
        WHERE n.ProcessedPriorityProcessedBy BETWEEN @PROCESSBY_START AND @PROCESSBY_END
			  AND n.HCC NOT LIKE 'HIER%'
        GROUP BY n.PaymentYear,
                 n.ModelYear,
                 n.ProcessedByStart,
                 n.ProcessedByEnd,
                 n.UnionqueryInd,
                 n.PlanID,
                 n.HICN,
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
                 n.PBP,
                 n.SCC,
                 n.ProcessedPriorityProcessedBy,
                 n.ProcessedPriorityThruDate,
                 n.ProcessedPriorityDiag,
                 n.ProcessedPriorityFileID,
                 n.ProcessedPriorityRAC,
                 n.ProcessedPriorityRAPSSourceID,
				 n.[ProcessedPriorityMAO004ResponseDiagnosisCodeID], ---RRI 755 MS
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
                 n.Aged;
 
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


        UPDATE [n]
        SET n.ProcessedPriorityICN = p1.SentEncounterICN,
            n.ProcessedPriorityEncounterID = p1.SentICNEncounterID,
            n.ProcessedPriorityReplacementEncounterSwitch = p1.ReplacementEncounterSwitch,
            n.ProcessedPriorityClaimID = p1.ClaimID,
            n.ProcessedPrioritySecondaryClaimID = p1.SecondaryClaimID,
            n.ProcessedPrioritySystemSource = p1.SystemSource,
            n.ProcessedPriorityRecordID = p1.RecordID,
            n.ProcessedPriorityVendorID = p1.VendorID,
            n.ProcessedPrioritySubProjectID = p1.SubProjectID,
            n.ProcessedPriorityMatched = p1.Matched,
            n.ProcessedPriorityMatchedEncounterICN = CASE
                                                         WHEN p1.Matched = 'Y' THEN
                                                             p1.OriginalEncounterICN
                                                         ELSE
                                                             NULL
                                                     END
        FROM [#NewHCCFinalDView] [n]
            INNER JOIN rev.tbl_Summary_RskAdj_EDS_Preliminary [p1] 
                ON n.hicn = p1.HICN
                   AND n.payment_year = p1.PaymentYear
                   AND n.ProcessedPriorityMAO004ResponseDiagnosisCodeID = p1.MAO004ResponseDiagnosisCodeID; --- RRI 755 MS





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
                WHERE [EncounterSource] = 'EDS'
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
				[PCN_SubprojectID],
				[ProcessedPriorityRecordID], ---RRI 755 MS
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
				   n.ProcessedPrioritySubProjectID,
				   n.ProcessedPriorityRecordID, --- RRI 755 MS
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
                   [model_year] = n.model_year,
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END,
                   'EDS' AS EncounterSource
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

                    --Modified for RRI-1258
		SET @RowCount = Isnull(@@ROWCOUNT,0);
		SET @ReportOutputByMonthID = 'V';
		SET @TableName = 'Valuation.NewHCCPartC';



        END;

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
            [payment_year] INT,
            [model_year] INT,
            [PAYMSTART] DATETIME,
            [processed_by_start] DATETIME,
            [processed_by_end] DATETIME,
            [planid] INT,
            [hicn] VARCHAR(15),
            [ra_factor_type] VARCHAR(2),
            [processed_priority_processed_by] DATETIME,
            [processed_priority_thru_date] DATETIME,
            [HCC_PROCESSED_PCN] VARCHAR(50),
            [processed_priority_diag] VARCHAR(20),
            [Processed_Priority_FileID] [VARCHAR](18),
            [Processed_Priority_RAC] [VARCHAR](1),
            [Processed_Priority_RAPS_Source_ID] VARCHAR(50),
            [DOS_PRIORITY_PROCESSED_BY] DATETIME,
            [DOS_PRIORITY_THRU_DATE] DATETIME,
            [DOS_PRIORITY_PCN] VARCHAR(50),
            [DOS_PRIORITY_DIAG] VARCHAR(20),
            [DOS_PRIORITY_FILEID] [VARCHAR](18),
            [DOS_PRIORITY_RAC] [VARCHAR](1),
            [DOS_PRIORITY_RAPS_SOURCE] VARCHAR(50),
            [hcc] VARCHAR(50),
            [hcc_description] VARCHAR(255),
            [HCC_FACTOR] DECIMAL(20, 4),
            [HIER_HCC] VARCHAR(20),
            [HIER_HCC_FACTOR] DECIMAL(20, 4),
            [FINAL_FACTOR] DECIMAL(20, 4),
            [factor_diff] DECIMAL(20, 4),
            [HIER_HCC_PROCESSED_PCN] VARCHAR(50),
            [active_indicator_for_rollforward] CHAR(1),
            [months_in_dcp] INT,
            [esrd] VARCHAR(1),
            [hosp] VARCHAR(1),
            [pbp] VARCHAR(3),
            [scc] VARCHAR(5),
            [bid] MONEY,
            [estimated_value] MONEY,
            [provider_id] VARCHAR(40),
            [provider_last] VARCHAR(55),
            [provider_first] VARCHAR(55),
            [provider_group] VARCHAR(80),
            [provider_address] VARCHAR(100),
            [provider_city] VARCHAR(30),
            [provider_state] VARCHAR(2),
            [provider_zip] VARCHAR(13),
            [provider_phone] VARCHAR(15),
            [provider_fax] VARCHAR(15),
            [tax_id] VARCHAR(55),
            [npi] VARCHAR(20),
            [SWEEP_DATE] DATE,
            [onlyHCC] VARCHAR(20),
            [HCC_Number] INT,
            [ProcessedPriorityICN] BIGINT NULL,
            [ProcessedPriorityEncounterID] BIGINT NULL,
            [ProcessedPriorityReplacementEncounterSwitch] CHAR(1) NULL,
            [ProcessedPriorityClaimID] VARCHAR(50) NULL,
            [ProcessedPrioritySecondaryClaimID] VARCHAR(50) NULL,
            [ProcessedPrioritySystemSource] VARCHAR(30) NULL,
            [ProcessedPriorityRecordID] VARCHAR(80) NULL,
            [ProcessedPriorityVendorID] VARCHAR(100) NULL,
            [ProcessedPrioritySubProjectID] INT NULL,
            [ProcessedPriorityMatched] CHAR(1) NULL,
            [ProcessedPriorityMAO004ResponseDiagnosisCodeID] BIGINT NULL,
            [ProcessedPriorityMatchedEncounterICN] BIGINT NULL,
            [DOSPriorityICN] BIGINT NULL,
            [DOSPriorityEncounterID] BIGINT NULL,
            [DOSPriorityReplacementEncounterSwitch] CHAR(1) NULL,
            [DOSPriorityClaimID] VARCHAR(50) NULL,
            [DOSPrioritySecondaryClaimID] VARCHAR(50) NULL,
            [DOSPrioritySystemSource] VARCHAR(30) NULL,
            [DOSPriorityRecordID] VARCHAR(80) NULL,
            [DOSPriorityVendorID] VARCHAR(100) NULL,
            [DOSPrioritySubProjectID] INT NULL,
            [DOSPriorityMatched] CHAR(1) NULL,
            [DOSPriorityMAO004ResponseDiagnosisCodeID] BIGINT NULL,
            [DOSPriorityMatchedEncounterICN] BIGINT NULL,
            [Aged] INT NULL,
            [ProcessedByFlag] CHAR(1) NULL,
            [RollForwardMonths] INT NULL
        );

        INSERT INTO [#NewHCCFinalMView]
        (
            [payment_year],
            [model_year],
            [PAYMSTART],
            [processed_by_start],
            [processed_by_end],
            [planid],
            [hicn],
            [ra_factor_type],
            [processed_priority_processed_by],
            [processed_priority_thru_date],
            [HCC_PROCESSED_PCN],
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
            [hcc],
            [hcc_description],
            [HCC_FACTOR],
            [HIER_HCC],
            [HIER_HCC_FACTOR],
            [FINAL_FACTOR],
            [factor_diff],
            [HIER_HCC_PROCESSED_PCN],
            [active_indicator_for_rollforward],
            [months_in_dcp],
            [esrd],
            [hosp],
            [pbp],
            [scc],
            [bid],
            [estimated_value],
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
            [onlyHCC],
            [HCC_Number],
            [ProcessedPriorityMAO004ResponseDiagnosisCodeID],
            [DOSPriorityMAO004ResponseDiagnosisCodeID],
            [Aged],
            [ProcessedByFlag],
            [RollForwardMonths]
        )
        SELECT DISTINCT
               n.PaymentYear,
               n.ModelYear,
               n.PaymStart,
               n.ProcessedByStart,
               n.ProcessedByEnd,
               n.PlanID,
               n.HICN,
               n.RAFactorType,                                                                    -- Ticket # 26951
               n.ProcessedPriorityProcessedBy,
               n.ProcessedPriorityThruDate,
               [HCC_PROCESSED_PCN] = n.ProcessedPriorityPCN,
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
               n.HCC,
               n.HCCDescription,
               [HCC_FACTOR] = ISNULL(n.Factor, 0),
               [HIER_HCC] = n.HierHCCOld,
               [HIER_HCC_FACTOR] = ISNULL(n.HierFactorOld, 0),
               [FINAL_FACTOR] = n.FinalFactor,
               n.FactorDiff,
               n.HierHCCProcessedPCN,
               [active_indicator_for_rollforward] = ISNULL(n.ActiveIndicatorForRollforward, 'N'), -- Ticket # 29157
               [MONTHS_IN_DCP] = ISNULL(n.MonthsInDCP, 0),
               [ESRD] = ISNULL(n.ESRD, 'N'),
               [HOSP] = ISNULL(n.HOSP, 'N'),
               n.PBP,
               [SCC] = ISNULL(n.SCC, 'OOA'),
               [BID] = ISNULL(n.BID, 0),
               [ESTIMATED_VALUE] = ISNULL(n.EstimatedValue, 0),                                   -- Ticket # 26951
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
                                  WHEN n.UnionqueryInd = 1 THEN
                                      @initial_flag
                                  WHEN n.UnionqueryInd = 2 THEN
                                      @myu_flag
                                  WHEN n.UnionqueryInd = 3 THEN
                                      @final_flag
                              END,
               n.OnlyHCC,
               n.HCCNumber,
               [ProcessedPriorityMAO004ResponseDiagnosisCodeID] = n.ProcessedPriorityMAO004ResponseDiagnosisCodeID,
               [DOSPriorityMAO004ResponseDiagnosisCodeID] = n.DOSPriorityMAO004ResponseDiagnosisCodeID,
               n.Aged,
               CASE
                   WHEN n.UnionqueryInd = 1 THEN
                       'I'
                   WHEN n.UnionqueryInd = 2 THEN
                       'M'
                   WHEN n.UnionqueryInd = 3 THEN
                       'F'
                   ELSE
                       'U'
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
        FROM [etl].[IntermediateEDSNewHCCOutput] [n]
            LEFT JOIN [#RollForward_Months] [r]
                ON n.HICN = r.hicn
                   AND n.RAFactorType = r.ra_factor_type
                   AND n.PlanID = r.planid
                   AND n.SCC = r.scc
                   AND n.PBP = r.pbp
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
            RAISERROR('044', 0, 1) WITH NOWAIT;
        END;

        UPDATE [n]
        SET n.ProcessedPriorityICN = p1.SentEncounterICN,
            n.ProcessedPriorityEncounterID = p1.SentICNEncounterID,
            n.ProcessedPriorityReplacementEncounterSwitch = p1.ReplacementEncounterSwitch,
            n.ProcessedPriorityClaimID = p1.ClaimID,
            n.ProcessedPrioritySecondaryClaimID = p1.SecondaryClaimID,
            n.ProcessedPrioritySystemSource = p1.SystemSource,
            n.ProcessedPriorityRecordID = p1.RecordID,
            n.ProcessedPriorityVendorID = p1.VendorID,
            n.ProcessedPrioritySubProjectID = p1.SubProjectID,
            n.ProcessedPriorityMatched = p1.Matched,
            n.ProcessedPriorityMatchedEncounterICN = CASE
                                                         WHEN p1.Matched = 'Y' THEN
                                                             p1.OriginalEncounterICN
                                                         ELSE
                                                             NULL
                                                     END
        FROM [#NewHCCFinalMView] [n]
            INNER JOIN rev.tbl_Summary_RskAdj_EDS_Preliminary [p1] -- RE - 6188 - Changed to Inner Join  & Added couple of columns for performance Tuning
                ON n.hicn = p1.HICN
                   AND n.payment_year = p1.PaymentYear
                   AND n.ProcessedPriorityMAO004ResponseDiagnosisCodeID = p1.MAO004ResponseDiagnosisCodeID;



        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('045', 0, 1) WITH NOWAIT;
        END;

        UPDATE [n]
        SET n.DOSPriorityICN = p1.SentEncounterICN,
            n.DOSPriorityEncounterID = p1.SentICNEncounterID,
            n.DOSPriorityReplacementEncounterSwitch = p1.ReplacementEncounterSwitch,
            n.DOSPriorityClaimID = p1.ClaimID,
            n.DOSPrioritySecondaryClaimID = p1.SecondaryClaimID,
            n.DOSPrioritySystemSource = p1.SystemSource,
            n.DOSPriorityRecordID = p1.RecordID,
            n.DOSPriorityVendorID = p1.VendorID,
            n.DOSPrioritySubProjectID = p1.SubProjectID,
            n.DOSPriorityMatched = p1.Matched,
            n.DOSPriorityMatchedEncounterICN = CASE
                                                   WHEN p1.Matched = 'Y' THEN
                                                       p1.OriginalEncounterICN
                                                   ELSE
                                                       NULL
                                               END
        FROM [#NewHCCFinalMView] [n]
            INNER JOIN rev.tbl_Summary_RskAdj_EDS_Preliminary [p1] -- RE - 6188 - Changed to Inner Join  & Added couple of columns for performance Tuning
                ON n.hicn = p1.HICN
                   AND n.payment_year = p1.PaymentYear
                   AND n.DOSPriorityMAO004ResponseDiagnosisCodeID = p1.MAO004ResponseDiagnosisCodeID;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('046', 0, 1) WITH NOWAIT;
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
               [PaymentYear] = n.payment_year,
			   [ModelYear] = n.model_year,               
               n.PAYMSTART AS [PaymentStartDate],
               n.processed_by_start AS [ProcessedByStartDate],
               n.processed_by_end AS [ProcessedByEndDate],
               n.ProcessedByFlag AS [ProcessedByFlag],
               'EDS' AS [EncounterSource],
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
               n.ProcessedPriorityICN,
               n.ProcessedPriorityEncounterID,
               n.ProcessedPriorityReplacementEncounterSwitch,
               n.ProcessedPriorityClaimID,
               n.ProcessedPrioritySecondaryClaimID,
               n.ProcessedPrioritySystemSource,
               n.ProcessedPriorityRecordID,
               n.ProcessedPriorityVendorID,
               n.ProcessedPrioritySubProjectID,
               n.ProcessedPriorityMatched,
               n.DOSPriorityICN,
               n.DOSPriorityEncounterID,
               n.DOSPriorityReplacementEncounterSwitch,
               n.DOSPriorityClaimID,
               n.DOSPrioritySecondaryClaimID,
               n.DOSPrioritySystemSource,
               n.DOSPriorityRecordID,
               n.DOSPriorityVendorID,
               n.DOSPrioritySubProjectID,
               n.DOSPriorityMatched,
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
                                  WHEN n.Aged = 1 THEN
                                      'Aged'
                                  WHEN n.Aged = 0 THEN
                                      'Disabled'
                                  ELSE
                                      'Not Applicable'
                              END,
               SUSER_NAME() AS [UserID],
               GETDATE() AS [LoadDate],
               n.ProcessedPriorityMAO004ResponseDiagnosisCodeID,
               n.DOSPriorityMAO004ResponseDiagnosisCodeID,
               n.ProcessedPriorityMatchedEncounterICN,
               n.DOSPriorityMatchedEncounterICN
        FROM [#NewHCCFinalMView] [n]
            JOIN [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit [SS] WITH (NOLOCK)
                ON n.payment_year = SS.PaymentYear
                   AND SS.SubmissionModel = 'EDS'
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


                --Modified for RRI-1258
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
            RAISERROR('047', 0, 1) WITH NOWAIT;
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
        IF (OBJECT_ID('etl.IntermediateEDSNewHCCOutput') IS NOT NULL)
        BEGIN
            TRUNCATE TABLE [etl].[IntermediateEDSNewHCCOutput];
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

