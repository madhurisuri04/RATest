/**************************************************************************************************************************************************************************************************
* Name			:	rev.LoadSummaryPartDRAPSNewHCC  
* Author       	:	Rakshit Lall
* TFS#          :   
* Date          :	1/10/2018
* Version		:	1.0
* Project		:	SP Will be called by the wrapper to load data to a permanent table used by extract/new HCC Report
* SP call		:	EXEC rev.LoadSummaryPartDRAPSNewHCC '2018', '1/1/2017', '12/31/2017', 'M', 'ALL', 'ALL'
* Version History :
*  Author			DATE		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
*	Rakshit Lall	1/18/2018	1.1			68897			Cleaned up the code - Removed commented code
*	Rakshit Lall	1/22/2018	1.2			68897			Fixed HIER issue by getting LEFT(RxHCCLabelOrig, 3) for "HCC" in the RollUp
*	Rakshit Lall	2/7/2018	1.3			68897			Fixed the issue related to HICNs dropping and fixed the BID value source
*	David Waddell   03/29/2018  1.4         70339           Fix Part D duplicate issue. In Section 03. Added PaymentYear Where condition for INSERT INTO #NewHCCRollup
*	David Waddell   04/03/2018  1.5         70374           Change PlanID to show H plans in PartDNewHCCOutputMParameter table. Modified mapping of #NewHCCOutput to source
*	                                                        from  [$(HRPInternalReportsDB)].[dbo].[RollupPlan] table in order to pull HPlan ID to be used downstream for OutoutMParameter table 
*   David Waddell   06/08/2018  1.61        70876           Populated  LastAssignedHICN col. in the [rev].[PartDNewHCCOutputMParameter]  table. (Section 75) 
*   Anand           05/12/2020  1.7			78582           Added Valuation Part
*   Anand			04/03/2021	1.8			80908			Part D New HCC Process Improvement - Remove Legacy part and used Permanent tables
*   Anand			03/11/2021	1.9			80941			Updated #MOR hier Logic
*   D. Waddell      05/29/2021  2.0         RRI-348/908     Add New HCC Activity Log  insert
**************************************************************************************************************************************************************************************************/

CREATE procedure [rev].[LoadSummaryPartDRAPSNewHCC]
    @PaymentYearNewDeleteHCC smallint
  , @ProcessByStartDate smalldatetime
  , @ProcessByEndDate smalldatetime
  , @ReportOutputByMonth char(1)
  , @ProcessRunId int = -1
  , @RowCount int out
  , @TableName VARCHAR (100) OUT
  , @ReportOutputByMonthID CHAR(1) OUT
  , @Debug bit = 0
as
begin

    set nocount on;

    set transaction isolation level read uncommitted;

    set statistics io off;

    declare @Today  datetime = getdate()
          , @ErrorMessage  varchar(500)
          , @ErrorSeverity int
          , @ErrorState    int
		  , @DeleteBatch INT
		  , @CurrentYear Int = Year(getdate())
		  , @Year_NewDeleteHCC_PaymentYearMinuseOne INT
		  , @Year_NewDeleteHCC_PaymentYear VARCHAR(4)
           , @UserID Varchar(20)
		  , @NewHCCActivityIdMain INT
	      , @NewHCCActivityIdSecondary INT;

 IF @Debug = 1
    BEGIN
        SET STATISTICS IO ON;
        DECLARE @ET DATETIME;
        DECLARE @MasterET DATETIME;
        SET @ET = GETDATE();
        SET @MasterET = @ET;
    END;

    	-- Modified RRI-348  DW 04/13/21
	Set @NewHCCActivityIdMain  =
        (
            SELECT MAX([GroupingId]) FROM [rev].[NewHCCActivity]
        );

	Set @UserID = CURRENT_USER

    if @CurrentYear < @PaymentYearNewDeleteHCC
       and @ReportOutputByMonth = 'V'
    begin
        raiserror('Error Message: If ReportOutputByMonth = V, Payment Year cannot exceed Current Year.', 16, -1);
    end;

    declare @InitialFlag datetime
          , @MyuFlag     datetime
          , @FinalFlag   datetime;

     IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('001', 0, 1) WITH NOWAIT;
    END;


    select @InitialFlag =
    (
        select min(Initial_Sweep_Date)
        from [$(HRPReporting)].dbo.lk_DCP_dates
        where substring(PayMonth, 1, 4) = @PaymentYearNewDeleteHCC
              and Mid_Year_Update is null
    );

    select @MyuFlag =
    (
        select max(Initial_Sweep_Date)
        from [$(HRPReporting)].dbo.lk_DCP_dates
        where substring(PayMonth, 1, 4) = @PaymentYearNewDeleteHCC
              and Mid_Year_Update = 'Y'
    );

    select @FinalFlag =
    (
        select max(Final_Sweep_Date)
        from [$(HRPReporting)].dbo.lk_DCP_dates
        where substring(PayMonth, 1, 4) = @PaymentYearNewDeleteHCC
              and Mid_Year_Update is null
    );

	 IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('002', 0, 1) WITH NOWAIT;
    END;

  IF OBJECT_ID('[etl].[IntermediatePartDRAPSNewHCCOutput]', 'U') IS NOT NULL
        TRUNCATE TABLE [etl].[IntermediatePartDRAPSNewHCCOutput];

    Insert into [etl].[IntermediatePartDRAPSNewHCCOutput]
    (
        PaymentYear
      , PaymStart
      , ModelYear
      , ProcessedByStart
      , ProcessedByEnd
      , PlanId
      , HICN
      , RAFactorType
      , RAFactorTypeORIG
      , ProcessedPriorityProcessedBy
      , ProcessedPriorityThruDate
      , ProcessedPriorityPCN
      , ProcessedPriorityDiag
      , ProcessedPriorityFileID
      , ProcessedPriorityRAPSSourceID
      , ProcessedPriorityRAC
      , ThruPriorityProcessedBy
      , ThruPriorityThruDate
      , ThruPriorityPCN
      , ThruPriorityDiag
      , ThruPriorityFileID
      , ThruPriorityRAPSSourceID
      , ThruPriorityRAC
      , HCC
      , HCCOrig
      , OnlyHCC
      , HCCNumber
      , Factor
      , MemberMonths
      , ProviderID
      , MinProcessBySeqnum
      , UnionQueryInd
      , PaymStartYear
      , Aged
      , ESRD
      , Hosp
    )
    select distinct
        n.PaymentYear
      , n.PaymStart
      , n.ModelYear
      , @ProcessByStartDate
      , @ProcessByEndDate
      , [PlanId]                                                        = [rp].[PlanId]
      , n.HICN
      , n.PartDRAFTRestated
      , n.PartDRAFTMMR
      , n.MinProcessBy
      , n.ProcessedPriorityThruDate
      , n.MinProcessbyPCN
      , n.MinProcessbyDiagCD
      , n.ProcessedPriorityFileID
      , ProcessedPriorityRAPSSourceID                                   =
        (
            select r.Category
            from [$(HRPReporting)].dbo.lk_RAPS_Sources r
            where n.ProcessedPriorityRAPSSourceID = r.Source_ID
        )
      , n.ProcessedPriorityRAC
      , n.ThruPriorityProcessedBy
      , n.MinThruDate
      , n.MinThruDatePCN
      , n.MinThruDateDiagCD
      , n.ThruPriorityFileID
      , ThruPriorityRAPSSourceID                                        =
        (
            select r.Category
            from [$(HRPReporting)].dbo.lk_RAPS_Sources r
            where n.ThruPriorityRAPSSourceID = r.Source_ID
        )
      , n.ThruPriorityRAC
      , n.RxHCCLabel
      , n.RxHCCLabelOrig
      , left(RxHCCLabelOrig, 3)
      , n.RxHCCNumber
      , isnull(n.Factor, 0)                                             as Factor
      , 1                                                               as MemberMonths
      , isnull(n.ProcessedPriorityProviderID, n.ThruPriorityProviderID) as ProviderID
      , n.MinProcessBySeqNum
      , n.IMFFlag
      , year(n.PaymStart)                                               as PaymStartYear
      , n.AGED
      , n.ESRD
      , n.Hospice
    from rev.SummaryPartDRskAdjRAPSMORDCombined n
        left join [$(HRPInternalReportsDB)].[dbo].[RollupPlan] [rp]
            on [n].[planidentifier] = [rp].[planidentifier]
               and [rp].[active] = 1
	 where n.RxHCCLabel not like 'DEL%' -- Delete Records should not be part of the Part D New HCC output
          and Factor > 0
          and PaymentYear = @PaymentYearNewDeleteHCC


   IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('003', 0, 1) WITH NOWAIT;
    END;

    
    IF OBJECT_ID('TEMPDB..#MonthsInDCP', 'U') IS NOT NULL
        DROP TABLE [#MonthsInDCP];
		
    CREATE TABLE [#MonthsInDCP]
    (
        [HICN] VARCHAR(12),
        [paymyear] VARCHAR(4),
        [months_in_dcp] INT
    );
	
    SET @Year_NewDeleteHCC_PaymentYearMinuseOne = CAST(@PaymentYearNewDeleteHCC AS INT) - 1;
    SET @Year_NewDeleteHCC_PaymentYear = CAST(@PaymentYearNewDeleteHCC AS INT);

	INSERT INTO [#MonthsInDCP]
    (
        [HICN],
        [paymyear],
        [months_in_dcp]
    )
    SELECT a.HICN,
           PaymentYear as PaymYear,
           COUNT(DISTINCT a.PaymStart) [months_in_dcp]
    FROM rev.tbl_Summary_RskAdj_MMR (NOLOCK) [a]
    WHERE (a.PaymentYear IN ( @Year_NewDeleteHCC_PaymentYearMinuseOne, @Year_NewDeleteHCC_PaymentYear ))
          AND a.HICN IS NOT NULL
    GROUP BY HICN,
             PaymentYear;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('004', 0, 1) WITH NOWAIT;
    END;

    CREATE NONCLUSTERED INDEX [idx_MonthsInDCP_HICN]
    ON [#MonthsInDCP] ([HICN])
    INCLUDE (
                [paymyear],
                [months_in_dcp]
            );
   
     IF (OBJECT_ID('tempdb.dbo.#MMR_BID') IS NOT NULL)
    BEGIN
        DROP TABLE [#MMR_BID];
    END;

    CREATE TABLE [#MMR_BID]
    (
        [pbp] VARCHAR(4),
        [scc] VARCHAR(5),
        [PartD_BID] SMALLMONEY,
        [HICN] VARCHAR(12),
        [paymstart] DATETIME,
        [payment_year] INT,
        [hosp] CHAR(1)
    );

INSERT INTO [#MMR_BID]
    (	
        [pbp],
        [scc],
        [PartD_BID],
        [HICN],
        [paymstart],
        [payment_year],
        [hosp]
    )
    SELECT Distinct 
		   mmr.PBP,
           mmr.SCC,
           mmr.PartD_BID,
           mmr.HICN,
           mmr.PaymStart,
           mmr.PaymentYear,
           mmr.HOSP
    FROM rev.tbl_Summary_RskAdj_MMR [mmr]
    WHERE mmr.PaymentYear = @PaymentYearNewDeleteHCC;  


	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('005', 0, 1) WITH NOWAIT;
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
        RAISERROR('006', 0, 1) WITH NOWAIT;
    END;

    update n
    set n.MonthsInDCP = mm.months_in_dcp
      , n.ActiveIndicatorForRollforward = case
                                              when isnull(convert(varchar(12), m.max_paymstart, 101), 'N') = 'N' then
                                                  'N'
                                              else
                                                  'Y'
                                          end
      , n.Hosp = isnull(b.HOSP, 'N')
      , n.PBP = b.PBP
      , n.SCC = b.SCC
      , n.Bid = b.PartD_BID
    from [etl].[IntermediatePartDRAPSNewHCCOutput]                        n
        join [#MMR_BID]                      b
            on n.HICN = b.HICN
               and n.PaymStart = b.PaymStart
               and n.PaymentYear = b.payment_year
        left join [#MMR_BIDMaxPaymStart]     m
            on n.PaymentYear = m.payment_year
               and n.PaymStart = m.max_paymstart
        left join [#MonthsInDCP]   mm
            on n.HICN = mm.HICN
               and case
                       when @CurrentYear < @PaymentYearNewDeleteHCC then
                           n.PaymStartYear
                       else
                           n.PaymStartYear - 1
                   end = mm.PaymYear
     

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('007', 0, 1) WITH NOWAIT;
    END;

    -- Check if graft component needed for Part D

    if object_id('TempDB..#lkFactorsPartDHCCINT') is not null
        drop table #lkFactorsPartDHCCINT;

    create table #lkFactorsPartDHCCINT
    (
        lkFactorsPartDHCCINTID int identity(1, 1) primary key not null
      , HCCLabelNumberHCCINT int null
      , HCCLabelHCCINT varchar(50) null
      , PaymentYear smallint null
      , [Description] varchar(255) null
    )

    insert into #lkFactorsPartDHCCINT
    (
        HCCLabelNumberHCCINT
      , HCCLabelHCCINT
      , PaymentYear
      , [Description]
    )
    select cast(substring(HCC_Label, 4, len(HCC_Label) - 3) as int) as HCCLabelNumberHCCINT
         , left(HCC_Label, 3)                                       as HCCLabelHCCINT
         , Payment_Year                                             as PaymentYear
         , [Description]
    from [$(HRPReporting)].dbo.lk_Factors_PartD
    where left(HCC_Label, 3) = 'HCC'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('008', 0, 1) WITH NOWAIT;
    END;

    update hccop
    set hccop.HCCDescription = rskmod.[Description]
    from [etl].[IntermediatePartDRAPSNewHCCOutput]                   hccop
        inner join #lkFactorsPartDHCCINT rskmod
            on rskmod.HCCLabelNumberHCCINT = hccop.HCCNumber
               and rskmod.HCCLabelHCCINT = hccop.OnlyHCC
               and rskmod.PaymentYear = hccop.PaymentYear
    where hccop.OnlyHCC = 'HCC'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('009', 0, 1) WITH NOWAIT;
    END;


    if object_id('TempDB..#lkFactorsPartDDHCC') is not null
        drop table #lkFactorsPartDDHCC

    create table #lkFactorsPartDDHCC
    (
        lkFactorsPartDDHCCID int identity(1, 1) primary key not null
      , HCCLabelNumberDHCC int null
      , HCCLabelDHCC varchar(50) null
      , PaymentYear smallint null
      , [Description] varchar(255) null
    )

    insert into #lkFactorsPartDDHCC
    (
        HCCLabelNumberDHCC
      , HCCLabelDHCC
      , PaymentYear
      , [Description]
    )
    select cast(substring(HCC_Label, 6, len(HCC_Label) - 5) as int) as HCCLabelNumberDHCC
         , left(HCC_Label, 5)                                       as HCCLabelDHCC
         , Payment_Year                                             as PaymentYear
         , [Description]
    from [$(HRPReporting)].dbo.lk_Factors_PartD
    where left(HCC_Label, 5) = 'D-HCC'

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('010', 0, 1) WITH NOWAIT;
    END;

    update hccop
    set hccop.HCCDescription = rskmod.[Description]
    from [etl].[IntermediatePartDRAPSNewHCCOutput] hccop
        inner join #lkFactorsPartDDHCC rskmod
            on rskmod.HCCLabelNumberDHCC = hccop.HCCNumber
               and rskmod.HCCLabelDHCC = left(hccop.HCCOrig, 5)
    where left(hccop.HCCOrig, 5) = 'D-HCC'


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('011', 0, 1) WITH NOWAIT;
    END;

    IF object_id('TempDB..#Hierarchy') is not null
        drop table #Hierarchy

    create table #Hierarchy
    (
        HierID int identity(1, 1) primary key not null
      , HICN varchar(15) null
      , PaymentYear int null
      , RAFactorType char(2) null
      , HCC varchar(50) null
      , UnionqueryInd int null
      , MinHCCNumber int null
    )
  
    insert into #Hierarchy
    (
        HICN
      , PaymentYear
      , RAFactorType
      , HCC
      , UnionqueryInd
      , MinHCCNumber
    )
    select distinct 
		   hccop.HICN
         , hccop.PaymentYear
         , hccop.RAFactorType
         , hccop.HCC
         , hccop.UnionQueryInd
         , min(drp.HCCNumber) as MinHCCNumber
    from [etl].[IntermediatePartDRAPSNewHCCOutput]                                       hccop
        inner join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy hier
            on hier.Payment_Year = hccop.PaymentYear
               and hier.RA_FACTOR_TYPE = hccop.RAFactorType
               and cast(substring(hier.HCC_KEEP, 4, len(hier.HCC_KEEP) - 3) as int) = hccop.HCCNumber
               and left(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        inner join [$(HRPReporting)].dbo.lk_Risk_Models           rskmod
            on rskmod.Payment_Year = hier.Payment_Year
               and rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               and cast(substring(rskmod.Factor_Description, 4, len(rskmod.Factor_Description) - 3) as int) = cast(substring(
                                                                                                                                hier.HCC_DROP
                                                                                                                              , 4
                                                                                                                              , len(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) as int)
               and left(rskmod.Factor_Description, 3) = left(hier.HCC_DROP, 3)
               and rskmod.Demo_Risk_Type = 'risk'
        inner join [etl].[IntermediatePartDRAPSNewHCCOutput]                              drp
            on drp.HICN = hccop.HICN
               and drp.HCCNumber = cast(substring(hier.HCC_DROP, 4, len(hier.HCC_DROP) - 3) as int)
               and drp.HCC like 'HIER%'
               and drp.OnlyHCC = left(hier.HCC_DROP, 3)
               and drp.RAFactorType = hccop.RAFactorType
               and drp.PaymentYear = hccop.PaymentYear
    where (left(rskmod.Factor_Description, 3) = 'HCC')
          and (left(hier.HCC_DROP, 3) = 'HCC')
          and left(hccop.HCC, 5) <> 'D-HCC'
    group by hccop.HICN
           , hccop.PaymentYear
           , hccop.RAFactorType
           , hccop.HCC
           , hccop.UnionQueryInd

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('012', 0, 1) WITH NOWAIT;
    END;


    update hccop
    set hccop.HierHCCOld = drp.HCC
      , hccop.HierFactorOld = drp.Factor
      , hccop.HierHCCProcessedPCN = drp.ProcessedPriorityPCN
    from [etl].[IntermediatePartDRAPSNewHCCOutput]            hccop
        inner join #Hierarchy    hier
            on hier.HICN = hccop.HICN
               and hier.RAFactorType = hccop.RAFactorType
               and hier.PaymentYear = hccop.PaymentYear
               and hier.HCC = hccop.HCC
               and hier.UnionqueryInd = hccop.UnionQueryInd
        inner join [etl].[IntermediatePartDRAPSNewHCCOutput]    drp
            on drp.HICN = hccop.HICN
               and drp.HCC like 'HIER%'
               and drp.RAFactorType = hccop.RAFactorType
               and drp.PaymentYear = hccop.PaymentYear
               and drp.HCCNumber = hier.MinHCCNumber

    if object_id('TempDB..#INCRHierarchy') is not null
        drop table #INCRHierarchy;

    create table #INCRHierarchy
    (
        INCRHierarchyID int identity(1, 1) primary key not null
      , HICN varchar(15) null
      , PaymentYear int null
      , RAFactorType char(2) null
      , HCC varchar(50) null
      , MinHCCNumber int null
    )

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('013', 0, 1) WITH NOWAIT;
    END;

    insert into #INCRHierarchy
    (
        HICN
      , PaymentYear
      , RAFactorType
      , HCC
      , MinHCCNumber
    )
    select hccop.HICN
         , hccop.PaymentYear
         , hccop.RAFactorType
         , hccop.HCC
         , min(drp.HCCNumber) as MinHCCNumber
    from [etl].[IntermediatePartDRAPSNewHCCOutput]                                        hccop
        inner join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy hier
            on hier.Payment_Year = hccop.PaymentYear
               and hier.RA_FACTOR_TYPE = hccop.RAFactorType
               and cast(substring(hier.HCC_KEEP, 4, len(hier.HCC_KEEP) - 3) as int) = hccop.HCCNumber
               and left(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        inner join [$(HRPReporting)].dbo.lk_Risk_Models           rskmod
            on rskmod.Payment_Year = hier.Payment_Year
               and rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               and cast(substring(rskmod.Factor_Description, 4, len(rskmod.Factor_Description) - 3) as int) = cast(substring(
                                                                                                                                hier.HCC_DROP
                                                                                                                              , 4
                                                                                                                              , len(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) as int)
               and left(rskmod.Factor_Description, 3) = left(hier.HCC_DROP, 3)
               and Demo_Risk_Type = 'risk'
        inner join [etl].[IntermediatePartDRAPSNewHCCOutput]  drp
            on drp.HICN = hccop.HICN
               and drp.HCCNumber = cast(substring(hier.HCC_DROP, 4, len(hier.HCC_DROP) - 3) as int)
               and drp.HCC like '%INCR%'
               and drp.OnlyHCC = left(hier.HCC_DROP, 3)
               and drp.RAFactorType = hccop.RAFactorType
               and drp.PaymentYear = hccop.PaymentYear
    where (left(rskmod.Factor_Description, 3) = 'HCC')
          and (left(hier.HCC_DROP, 3) = 'HCC')
          and left(hccop.HCC, 5) <> 'D-HCC'
    group by hccop.HICN
           , hccop.PaymentYear
           , hccop.RAFactorType
           , hccop.HCC

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('014', 0, 1) WITH NOWAIT;
    END;

    update hccop
    set hccop.HierHCCOld = replace(drp.HCC, 'M-High-', '')
      , hccop.HierFactorOld = drp.Factor
      , hccop.HierHCCProcessedPCN = drp.ProcessedPriorityPCN
    from [etl].[IntermediatePartDRAPSNewHCCOutput]       hccop
        join #INCRHierarchy hier
            on hier.HICN = hccop.HICN
               and hier.RAFactorType = hccop.RAFactorType
               and hier.PaymentYear = hccop.PaymentYear
               and hier.HCC = hccop.HCC
        join [etl].[IntermediatePartDRAPSNewHCCOutput]   drp
            on drp.HICN = hccop.HICN
               and drp.HCC like '%INCR%'
               and drp.RAFactorType = hccop.RAFactorType
               and drp.PaymentYear = hccop.PaymentYear
               and drp.HCCNumber = hier.MinHCCNumber

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('015', 0, 1) WITH NOWAIT;
    END;

    if object_id('TempDB..#MORHierarchy') is not null
        drop table #MORHierarchy;

    create table #MORHierarchy
    (
        MORHierarchyID int identity(1, 1) primary key not null
      , HICN varchar(15)
      , PaymentYear int
      , RAFactorType char(2)
      , HCC varchar(50)
      , MinHCCNumber int
    )

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('017', 0, 1) WITH NOWAIT;
    END;

    insert into #MORHierarchy
    (
        HICN
      , PaymentYear
      , RAFactorType
      , HCC
      , MinHCCNumber
    )
    select hccop.HICN
         , hccop.PaymentYear
         , hccop.RAFactorType
         , hccop.HCC
         , min(drp.HCCNumber) as MinHCCNumber
    from [etl].[IntermediatePartDRAPSNewHCCOutput]                                        hccop
        inner join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy hier
            on hier.Payment_Year = hccop.PaymentYear
               and hier.RA_FACTOR_TYPE = hccop.RAFactorType
               and cast(substring(hier.HCC_KEEP, 4, len(hier.HCC_KEEP) - 3) as int) = hccop.HCCNumber
               and left(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        inner join [$(HRPReporting)].dbo.lk_Risk_Models           rskmod
            on rskmod.Payment_Year = hier.Payment_Year
               and rskmod.Factor_Type = hier.RA_FACTOR_TYPE
               and cast(substring(rskmod.Factor_Description, 4, len(rskmod.Factor_Description) - 3) as int) = cast(substring(
                                                                                                                                hier.HCC_DROP
                                                                                                                              , 4
                                                                                                                              , len(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) as int)
               and left(rskmod.Factor_Description, 3) = left(hier.HCC_DROP, 3)
               and Demo_Risk_Type = 'risk'
        inner join [etl].[IntermediatePartDRAPSNewHCCOutput]                             drp
            on drp.HICN = hccop.HICN
               and drp.HCCNumber = cast(substring(hier.HCC_DROP, 4, len(hier.HCC_DROP) - 3) as int)
               and drp.HCC like 'MOR-INCR%'
               and drp.OnlyHCC = left(hier.HCC_DROP, 3)
               and drp.RAFactorType = hccop.RAFactorType
               and drp.PaymentYear = hccop.PaymentYear
    where (left(rskmod.Factor_Description, 3) = 'HCC')
          and (left(hier.HCC_DROP, 3) = 'HCC')
          and left(hccop.HCC, 5) <> 'D-HCC'
    group by hccop.HICN
           , hccop.PaymentYear
           , hccop.RAFactorType
           , hccop.HCC

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('016', 0, 1) WITH NOWAIT;
    END;

    update hccop
    set hccop.HierHCCOld = drp.HCC
      , hccop.HierFactorOld = drp.Factor
      , hccop.HierHCCProcessedPCN = drp.ProcessedPriorityPCN
    from [etl].[IntermediatePartDRAPSNewHCCOutput]            hccop
        inner join #MORHierarchy hier
            on hier.HICN = hccop.HICN
               and hier.RAFactorType = hccop.RAFactorType
               and hier.PaymentYear = hccop.PaymentYear
               and hier.HCC = hccop.HCC
        inner join [etl].[IntermediatePartDRAPSNewHCCOutput]   drp
            on drp.HICN = hccop.HICN
               and drp.HCC like 'MOR-INCR%'
               and drp.RAFactorType = hccop.RAFactorType
               and drp.PaymentYear = hccop.PaymentYear
               and drp.HCCNumber = hier.MinHCCNumber
	
	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('017', 0, 1) WITH NOWAIT;
    END;

    update HCCOP
    set HCCOP.EstimatedValue = round(
                                        HCCOP.Bid * (HCCOP.MemberMonths)
                                        * round((HCCOP.Factor - isnull(HCCOP.HierFactorOld, 0)) / PartD_Factor, 3)
                                      , 2
                                    )
      , HCCOP.FinalFactor = round((HCCOP.Factor - isnull(HCCOP.HierFactorOld, 0)) / PartD_Factor, 3)
      , HCCOP.FactorDiff = case
                               when HCCOP.HierHCCOld like 'HIER%' then
                                   isnull((round((HCCOP.Factor), 3)), 0)
                               else
                                   isnull((round((HCCOP.Factor - isnull(HCCOP.HierFactorOld, 0)), 3)), 0)
                           end
    from [etl].[IntermediatePartDRAPSNewHCCOutput]                                        HCCOP
        inner join [$(HRPReporting)].dbo.lk_normalization_factors nf
            on [Year] = @PaymentYearNewDeleteHCC
    where isnull(HCCOP.Hosp, 'N') <> 'Y';

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('018', 0, 1) WITH NOWAIT;
    END;

    if @ReportOutputByMonth = 'V'
    begin

        if object_id('TempDB..#RptClientPCNStrings') is not null
            drop table #RptClientPCNStrings;

        create table #RptClientPCNStrings
        (
            RptClientPCNStringsID int identity(1, 1) primary key not null
          , PCNString varchar(100) null
        )

        insert into #RptClientPCNStrings
        (
            PCNString
        )
        select PCN_STRING
        from dbo.RptClientPcnStrings
        where PAYMENT_YEAR = @PaymentYearNewDeleteHCC
              and ACTIVE = 'Y'
              and TERMDATE = '0001-01-01'
              and IDENTIFIER = 'Valuation'

  IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('019', 0, 1) WITH NOWAIT;
    END;

        if object_id('TempDB..#HierPCNLookup') is not null
            drop table #HierPCNLookup

        create table #HierPCNLookup
        (
            HierPCNLookupID int identity(1, 1) primary key not null
          , ProcessedPriorityPCN varchar(50) null
          , HierHCCProcessedPCN varchar(50) null
        )

        insert into #HierPCNLookup
        (
            ProcessedPriorityPCN
          , HierHCCProcessedPCN
        )
        select ProcessedPriorityPCN
             , HierHCCProcessedPCN
        from [etl].[IntermediatePartDRAPSNewHCCOutput] 
        where HierHCCOld like 'HIER%'
        group by ProcessedPriorityPCN
               , HierHCCProcessedPCN

  IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('020', 0, 1) WITH NOWAIT;
    END;

        if object_id('TempDB..#ValuationPerfFix') is not null
            drop table #ValuationPerfFix

        create table #ValuationPerfFix
        (
            ValuationPerfFixID int identity(1, 1) primary key not null
          , ProcessedPriorityPCN varchar(50) null
          , PCNFlag bit
        )
 
        insert into #ValuationPerfFix
        (
            ProcessedPriorityPCN
          , PCNFlag
        )
        select n.ProcessedPriorityPCN
             , PCNFlag = case
                             when r.PCNString is null then
                                 0
                             else
                                 1
                         end
        from #HierPCNLookup                n
            left join #RptClientPCNStrings r
                on patindex('%' + r.PCNString + '%', n.ProcessedPriorityPCN) > 0

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('021', 0, 1) WITH NOWAIT;
    END;

        update hccop
        set HCCPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]          hccop
            join #ValuationPerfFix a
                on a.ProcessedPriorityPCN = hccop.ProcessedPriorityPCN
        where hccop.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('022', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HCCPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  HCCOP
            inner join
            (
                select ProcessedPriorityPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 3, 5))), n.ProcessedPriorityPCN) > 0
                where n.ProcessedPriorityPCN like 'V%'
                      and PCNString like 'V%'
            )              a
                on a.ProcessedPriorityPCN = HCCOP.ProcessedPriorityPCN
        where HCCOP.HierHCCOld like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('023', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HCCPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  HCCOP
            inner join
            (
                select ProcessedPriorityPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 7, 5))), n.ProcessedPriorityPCN) > 0
                where n.ProcessedPriorityPCN like '%-VRSK%'
                      and PCNString like '%-VRSK%'
            )              a
                on a.ProcessedPriorityPCN = HCCOP.ProcessedPriorityPCN
        where HCCOP.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('024', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HCCPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  HCCOP
            inner join
            (
                select ProcessedPriorityPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 10, 50))), n.ProcessedPriorityPCN) > 0
                where (
                          n.ProcessedPriorityPCN like 'MRAudit%'
                          or n.ProcessedPriorityPCN like 'PLAudit%'
                          or n.ProcessedPriorityPCN like 'HRPAudit%'
                      )
                      and (
                              PCNString like 'MRAudit%'
                              or PCNString like 'PLAudit%'
                              or PCNString like 'HRPAudit%'
                          )
            )              a
                on a.ProcessedPriorityPCN = HCCOP.ProcessedPriorityPCN
        where HCCOP.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('025', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HCCPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  hccop
            inner join
            (
                select ProcessedPriorityPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 22, 50))), n.ProcessedPriorityPCN) > 0
                where n.ProcessedPriorityPCN like 'MRAuditProspective%'
            )              a
                on a.ProcessedPriorityPCN = hccop.ProcessedPriorityPCN
        where hccop.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('026', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HIERPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  hccop
            inner join
            (
                select HierHCCProcessedPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + PCNString + '%', n.HierHCCProcessedPCN) > 0
            )              a
                on a.HierHCCProcessedPCN = hccop.HierHCCProcessedPCN
        where hccop.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('027', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HIERPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  HCCOP
            inner join
            (
                select HierHCCProcessedPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 3, 5))), n.HierHCCProcessedPCN) > 0
                where (n.HierHCCProcessedPCN like 'V%')
                      and (PCNString like 'V%')
            )              a
                on a.HierHCCProcessedPCN = HCCOP.HierHCCProcessedPCN
        where HCCOP.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('028', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HIERPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  HCCOP
            inner join
            (
                select HierHCCProcessedPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 7, 5))), n.HierHCCProcessedPCN) > 0
                where (n.HierHCCProcessedPCN like '%-VRSK%')
                      and (PCNString like '%-VRSK%')
            )              a
                on a.HierHCCProcessedPCN = HCCOP.HierHCCProcessedPCN
        where HCCOP.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('029', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HIERPCNMatch = PCNFlag
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  hccop
            inner join
            (
                select HierHCCProcessedPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 10, 50))), n.HierHCCProcessedPCN) > 0
                where (
                          n.HierHCCProcessedPCN like 'MRAudit%'
                          or n.HierHCCProcessedPCN like 'PLAudit%'
                          or n.HierHCCProcessedPCN like 'HRPAudit%'
                      )
                      and (
                              PCNString like 'MRAudit%'
                              or n.HierHCCProcessedPCN like 'PLAudit%'
                              or n.HierHCCProcessedPCN like 'HRPAudit%'
                          )
            )              a
                on a.HierHCCProcessedPCN = hccop.HierHCCProcessedPCN
        where hccop.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('030', 0, 1) WITH NOWAIT;
    END;

        update HCCOP
        set HIERPCNMatch = 0
        from [etl].[IntermediatePartDRAPSNewHCCOutput]  hccop
            inner join
            (
                select HierHCCProcessedPCN
                     , case
                           when r.PCNString is null then
                               0
                           else
                               1
                       end PCNFlag
                from #HierPCNLookup                n
                    left join #RptClientPCNStrings r
                        on patindex('%' + ltrim(rtrim(substring(PCNString, 22, 50))), n.HierHCCProcessedPCN) > 0
                where n.HierHCCProcessedPCN like 'MRAuditProspective%'
            )              a
                on a.HierHCCProcessedPCN = hccop.HierHCCProcessedPCN
        where hccop.[HierHCCOld] like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('031', 0, 1) WITH NOWAIT;
    END;

            update HCCOP
            set HCCOP.FactorDiff = isnull((round((HCCOP.Factor - isnull(HCCOP.HierFactorOld, 0)), 3)), 0)
            from [etl].[IntermediatePartDRAPSNewHCCOutput]                                        HCCOP
                inner join [$(HRPReporting)].dbo.lk_normalization_factors nf
                    on [Year] = @PaymentYearNewDeleteHCC
            where isnull(HCCOP.Hosp, 'N') <> 'Y'
                  and HCCPCNMatch = 1
                  and HIERPCNMatch = 0

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('032', 0, 1) WITH NOWAIT;
    END;


End;

    if object_id('TempDB..#RollForwardMonths') is not null
        drop table #RollForwardMonths

    create table #RollForwardMonths
    (
        RollForwardMonthsID int identity(1, 1) primary key not null
      , PlanID varchar(5) null
      , HICN varchar(15) null
      , RAFactorType char(2) null
      , PBP varchar(3) null
      , SCC varchar(5) null
      , MemberMonths datetime
    )
 
    insert into #RollForwardMonths
    (
        PlanID
      , HICN
      , RAFactorType
      , PBP
      , SCC
      , MemberMonths
    )
    select PlanId
         , HICN
         , RAFactorType
         , PBP
         , SCC
         , MemberMonths = max(PaymStart)
    from [etl].[IntermediatePartDRAPSNewHCCOutput] 
    group by PlanId
           , HICN
           , RAFactorType
           , PBP
           , SCC

    create nonclustered index IXRollforwardMonthsHICN
    on #RollForwardMonths
    (
        HICN
      , RAFactorType
      , PlanID
      , SCC
      , PBP
    )

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('033', 0, 1) WITH NOWAIT;
    END;

    declare @MaxMonth int = (
                                select month(max(PaymStart)) from [etl].[IntermediatePartDRAPSNewHCCOutput] 
                            )

  
	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('034', 0, 1) WITH NOWAIT;
    END;
 
    if object_id('TempDB..#MaxMonthHCC') is not null
        drop table #MaxMonthHCC

    create table #MaxMonthHCC
    (
        MaxMonthHCC int identity(1, 1) primary key not null
      , PaymentYear int null
      , ModelYear int null
      , PlanID varchar(5) null
      , HICN varchar(15) null
      , OnlyHCC varchar(20) null
      , HCCNumber int null
      , MaxMemberMonth datetime
    )

    insert into #MaxMonthHCC
    (
        PaymentYear
      , ModelYear
      , PlanID
      , HICN
      , OnlyHCC
      , HCCNumber
      , MaxMemberMonth
    )
    select PaymentYear
         , ModelYear
         , PlanID
         , HICN
         , OnlyHCC
         , HCCNumber
         , max(PaymStart) as MaxMemberMonth
    from [etl].[IntermediatePartDRAPSNewHCCOutput] 
    group by PaymentYear
           , ModelYear
           , PlanID
           , HICN
           , OnlyHCC
           , HCCNumber

  
	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('035', 0, 1) WITH NOWAIT;
    END;

    if object_id('TempDB..#FinalUniqueCondition') is not null
        drop table #FinalUniqueCondition

    create table #FinalUniqueCondition
    (
        FinalUniqueConditionID int identity(1, 1) primary key not null
      , PaymentYear int null
      , ModelYear int null
      , PlanID varchar(5) null
      , HICN varchar(15) null
      , OnlyHCC varchar(20) null
      , HCCNumber int null
      , RAFactorType char(2) null
      , PBP varchar(3) null
      , SCC varchar(5) null
      , AGED int
    )

    insert into #FinalUniqueCondition
    (
        PaymentYear
      , ModelYear
      , PlanID
      , HICN
      , OnlyHCC
      , HCCNumber
      , RAFactorType
      , PBP
      , SCC
      , AGED
    )
    select n.PaymentYear
         , n.ModelYear
         , n.PlanId
         , n.HICN
         , n.OnlyHCC
         , n.HCCNumber
         , n.RAFactorType
         , n.PBP
         , n.SCC
         , n.Aged
    from [etl].[IntermediatePartDRAPSNewHCCOutput]           n
        inner join #MaxMonthHCC m
            on n.PaymentYear = m.PaymentYear
               and n.ModelYear = m.ModelYear
               and n.PlanId = m.PlanID
               and n.HICN = m.HICN
               and n.OnlyHCC = m.OnlyHCC
               and n.HCCNumber = m.HCCNumber
               and n.PaymStart = m.MaxMemberMonth

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('036', 0, 1) WITH NOWAIT;
    END;

    declare @ClientLevelDB varchar(30)

    declare @DBName varchar(50) = db_name()

    select @ClientLevelDB =
    (
        select case
                   when @DBName like '%_Report'
                        and @DBName <> 'Aetna_Report' then
                       replace(db_name(), '_Report', '_ClientLevel')
                   when @DBName like '%_Report'
                        and @DBName = 'Aetna_Report' then
                       replace(db_name(), '_Report', '_ClientDB')
                   else
                       null
               end
    )

    if (object_id('TempDB.dbo.#Providers') is not null)
        drop table #Providers

    create table #Providers
    (
        ID int identity(1, 1) primary key not null
      , ProviderId varchar(40) null
      , LastName varchar(55) null
      , FirstName varchar(55) null
      , GroupName varchar(80) null
      , ContactAddress varchar(100) null
      , ContactCity varchar(30) null
      , ContactState char(2) null
      , ContactZip varchar(13) null
      , WorkPhone varchar(15) null
      , WorkFax varchar(15) null
      , AssocName varchar(55) null
      , NPI varchar(10)
    )
 
    declare @LoadProvider varchar(5000)

    set @LoadProvider
        = '
			INSERT INTO #Providers
			(
				ProviderId,
				LastName,
				FirstName,
				GroupName,
				ContactAddress,
				ContactCity,
				ContactState,
				ContactZip,
				WorkPhone,
				WorkFax,
				AssocName,
				NPI
			)
			SELECT
				P.Provider_ID,
				P.Last_Name,
				P.First_Name,
				P.Group_Name,
				P.Contact_Address,
				P.Contact_City,
				P.Contact_State,
				P.Contact_Zip,
				P.Work_Phone,
				P.Work_Fax,
				P.Assoc_Name,
				P.NPI
			FROM ' + @ClientLevelDB
          + '.dbo.tbl_Providers P
			 INNER JOIN [etl].[IntermediatePartDRAPSNewHCCOutput] N
				ON N.ProviderID=P.Provider_ID
			GROUP BY
				P.Provider_ID,
				P.Last_Name,
				P.First_Name,
				P.Group_Name,
				P.Contact_Address,
				P.Contact_City,
				P.Contact_State,
				P.Contact_Zip,
				P.Work_Phone,
				P.Work_Fax,
				P.Assoc_Name,
				P.NPI	
			'

    exec (@LoadProvider)
	 
	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('037', 0, 1) WITH NOWAIT;
    END;
 
    if @ReportOutputByMonth = 'V'
    begin

	  if object_id('TempDB..#NewHCCFinalValView') is not null
        drop table #NewHCCFinalValView;

    create table #NewHCCFinalValView
    (
        NewHCCFinalDVViewID bigint identity(1, 1) primary key not null
      , PaymentYear int null
      , ModelYear int null
      , ProcessedByStart datetime null
      , ProcessedByEnd datetime null
      , UnionqueryInd int null
      , Planid varchar(5) null
      , Hicn varchar(15) null
      , RAFactorType char(2) null
      , HCC varchar(50) null
      , HCCDescription varchar(255) null
      , HCCFactor decimal(20, 4) null
      , HierHCC varchar(20) null
      , HierHCCfactor decimal(20, 4) null
      , FinalFactor decimal(20, 4) null
      , FactorDiff decimal(20, 4) null
      , HCCProcessedPCN varchar(50) null
      , HierHCCProcessedPCN varchar(50) null
      , MemberMonths int null
      , BID money null
      , EstimatedValue money null
      , Rollforwardmonths int null
      , AnnualizedEstimatedValue money null
      , MonthsInDCP int null
      , ESRD char(1) null
      , HOSP char(1) null
      , PBP varchar(3) null
      , SCC varchar(5) null
      , ProcessedPriorityProcessedBy datetime null
      , ProcessedPriorityThrudate datetime null
      , ProcessedPriorityDiag varchar(20) null
      , ProcessedPriorityFileID varchar(18) null
      , ProcessedPriorityRAC char(1) null
      , ProcessedPriorityRAPSSourceID varchar(50) null
      , DOSPriorityProcessedBy datetime null
      , DOSPriorityThruDate datetime null
      , DOSPriorityPCN varchar(50) null
      , DOSPriorityDiag varchar(20) null
      , DOSPriorityFileID varchar(18) null
      , DOSPriorityRAC char(1) null
      , DOSPriorityRAPSSource varchar(50) null
      , ProviderID varchar(40) null
      , ProviderLast varchar(55) null
      , ProviderFirst varchar(55) null
      , ProviderGroup varchar(80) null
      , ProviderAddress varchar(100) null
      , ProviderCity varchar(30) null
      , ProviderState char(2) null
      , ProviderZip varchar(13) null
      , ProviderPhone varchar(15) null
      , ProviderFax varchar(15) null
      , TaxID varchar(55) null
      , NPI varchar(20) null
      , SweepDate date null
      , PopulatedDate datetime null
      , OnlyHCC varchar(20) null
      , HCCNumber int null
      , AGED int
    );

	INSERT INTO [#NewHCCFinalValView] WITH ( TABLOCK )
				(
					PaymentYear,
					ModelYear,
					ProcessedByStart,
					ProcessedByEnd,
					UnionqueryInd,
					Planid,
					Hicn,
					RAFactorType,
					HCC,
					HCCDescription,
					HCCFactor,
					HierHCC,
					HierHCCfactor,
					FinalFactor,
					FactorDiff,
					HCCProcessedPCN,
					HierHCCProcessedPCN,
					MemberMonths,
					BID,
					EstimatedValue,
					Rollforwardmonths,
					AnnualizedEstimatedValue,
					MonthsInDCP,
					ESRD,
					HOSP,
					PBP,
					SCC,
					ProcessedPriorityProcessedBy,
					ProcessedPriorityThrudate,
					ProcessedPriorityDiag,
					ProcessedPriorityFileID,
					ProcessedPriorityRAC,
					ProcessedPriorityRAPSSourceID,
					DOSPriorityProcessedBy,
					DOSPriorityThruDate,
					DOSPriorityPCN,
					DOSPriorityDiag,
					DOSPriorityFileID,
					DOSPriorityRAC,
					DOSPriorityRAPSSource,
					ProviderID,
					ProviderLast,
					ProviderFirst,
					ProviderGroup,
					ProviderAddress,
					ProviderCity,
					ProviderState,
					ProviderZip,
					ProviderPhone,
					ProviderFax,
					TaxID,
					NPI,
					SweepDate,
					PopulatedDate,
					OnlyHCC,
					HCCNumber,
					AGED
				)
				
				SELECT
					n.PaymentYear,
					n.ModelYear,
					n.ProcessedByStart,
					n.ProcessedByEnd,
					n.UnionQueryInd,
					n.PlanId,
					n.HICN,
					n.RAFactorType AS RAFactorType,
					n.HCC,
					n.HCCDescription,
					ISNULL(n.Factor, 0) AS HCCFactor,
					n.HierHCCOld AS HierHCC,
					ISNULL(n.HierFactorOld, 0) AS HierHCCFactor,
					n.FinalFactor AS FinalFactor,
					n.FactorDiff,
					n.ProcessedPriorityPCN AS HCCProcessedPCN,
					n.HierHCCProcessedPCN,
					COUNT(DISTINCT n.PaymStart) AS MemberMonths,
					ISNULL(n.Bid, 0) AS Bid,
					ISNULL(SUM(n.EstimatedValue), 0) AS EstimatedValue, 
					CASE
						WHEN @PaymentYearNewDeleteHCC < @CurrentYear OR (@PaymentYearNewDeleteHCC >= @CurrentYear AND MONTH(r.MemberMonths) < @MaxMonth) 
						THEN 0
						ELSE 12 - MONTH(r.MemberMonths)
					END AS RollforwardMonths,
					ISNULL
						(
						SUM(n.EstimatedValue) + (CASE WHEN @PaymentYearNewDeleteHCC < @CurrentYear OR (@PaymentYearNewDeleteHCC >= @CurrentYear AND MONTH(r.MemberMonths) < @MaxMonth) 
						THEN 0
						ELSE 12 - MONTH(r.MemberMonths)
						END 
						* 
						(
						SUM(n.EstimatedValue) / COUNT(DISTINCT n.PaymStart)))
						, 0) AS AnnualizedEstimatedValue,
					ISNULL(n.MonthsInDCP, 0) AS MonthsInDCP,
					ISNULL(n.ESRD, 'N') AS ESRD,
					ISNULL(n.HOSP, 'N') AS HOSP,
					n.PBP,
					ISNULL(n.SCC, 'OOA') AS SCC,
					n.ProcessedPriorityProcessedBy,
					n.ProcessedPriorityThruDate,
					n.ProcessedPriorityDiag,
					n.ProcessedPriorityFileID,
					n.ProcessedPriorityRAC,
					n.ProcessedPriorityRAPSSourceID,
					n.ThruPriorityProcessedBy AS DOSPriorityProcessedBy,
					n.ThruPriorityThruDate AS DOSPriorityThruDate,
					n.ThruPriorityPCN AS DOSPriorityPCN,
					n.ThruPriorityDiag AS DOSPriorityDiag,
					n.ThruPriorityFileID AS DOSPriorityFileID,
					n.ThruPriorityRAC AS DOSPriorityRAC,
					n.ThruPriorityRAPSSourceID AS DOSPriorityRAPSSource,
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
					n.npi,
					CASE
						WHEN n.UnionQueryInd = 1 THEN @InitialFlag
						WHEN n.UnionQueryInd = 2 THEN @MyuFlag
						WHEN n.UnionQueryInd = 3 THEN @FinalFlag
						END AS SweepDate,
					@Today AS PopulatedDate,
					OnlyHCC,
					HCCNumber,
					n.AGED
					FROM [etl].[IntermediatePartDRAPSNewHCCOutput]  n
					INNER JOIN #RollForwardMonths r
						ON n.HICN = r.HICN
						AND n.RAFactorType = r.RAFactorType
						AND n.PlanId = r.PlanID
						AND n.SCC = r.SCC
						AND n.PBP = r.PBP
					WHERE 
						(n.ProcessedPriorityProcessedBy >= @ProcessByStartDate AND n.ProcessedPriorityProcessedBy <= @ProcessByEndDate)

				Group By

					n.PaymentYear,
					n.ModelYear,
					n.ProcessedByStart,
					n.ProcessedByEnd,
					n.UnionQueryInd,
					n.PlanId,
					n.HICN,
					n.RAFactorType,
					n.HCC,
					n.HCCDescription,
					n.Factor,
					n.HierHCCOld ,
					n.HierFactorOld,
					n.FinalFactor,
					n.FactorDiff,
					n.ProcessedPriorityPCN ,
					n.HierHCCProcessedPCN,
					n.Bid,
					r.MemberMonths,
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
					n.ThruPriorityProcessedBy,
					n.ThruPriorityThruDate,
					n.ThruPriorityPCN,
					n.ThruPriorityDiag ,
					n.ThruPriorityFileID ,
					n.ThruPriorityRAC ,
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
					n.npi,
					OnlyHCC,
					HCCNumber,
					n.AGED

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('038', 0, 1) WITH NOWAIT;
    END;

    update n
    set n.ProviderLast = u.LastName
      , n.ProviderFirst = u.FirstName
      , n.ProviderGroup = u.GroupName
      , n.ProviderAddress = u.ContactAddress
      , n.ProviderCity = u.ContactCity
      , n.ProviderState = u.ContactState
      , n.ProviderZip = u.ContactZip
      , n.ProviderPhone = u.WorkPhone
      , n.ProviderFax = u.WorkFax
      , n.TaxID = u.AssocName
      , n.NPI = u.NPI
    from #NewHCCFinalValView n
        join #Providers      u
            on n.ProviderID = u.ProviderId

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('039', 0, 1) WITH NOWAIT;
    END;

        if object_id(N'Valuation.NewHCCPartD', N'U') is not null
        begin

			set @DeleteBatch = 300000;
						
					while (1 = 1)
						begin
	
							    delete top (@DeleteBatch)
								from [Valuation].[NewHCCPartD] 
								where [EncounterSource] = 'RAPS'
								and [ProcessRunId]=@ProcessRunId;
												 

					if @@rowcount = 0
					break
					else
				        continue
					end

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('040', 0, 1) WITH NOWAIT;
    END;

             Insert into Valuation.NewHCCPartD
            (
                ProcessRunId
              , Payment_Year
              , Processed_By_Start
              , Processed_By_End
              , PlanID
              , HICN
              , RA_FACTOR_TYPE
              , Processed_By_Flag
              , RxHCC
              , HCC_Description
              , RxHCC_FACTOR
              , HIER_RxHCC
              , HIER_RxHCC_FACTOR
              , Pre_Adjstd_Factor
              , Adjstd_Final_Factor
              , HCC_PROCESSED_PCN
              , HIER_HCC_PROCESSED_PCN
              , UNQ_CONDITIONS
              , Months_In_DCP
              , MEMBER_MONTHS
              , Bid_Amount
              , ESTIMATED_VALUE
              , Rollforward_Months
              , ANNUALIZED_ESTIMATED_VALUE
              , PBP
              , SCC
              , Processed_Priority_Processed_By
              , Processed_Priority_Thru_Date
              , Processed_Priority_Diag
              , Processed_Priority_FileID
              , Processed_Priority_RAC
              , Processed_Priority_RAPS_Source_ID
              , DOS_Priority_Processed_By
              , DOS_Priority_Thru_Date
              , DOS_Priority_PCN
              , DOS_Priority_Diag
              , DOS_Priority_FileId
              , DOS_Priority_RAC
              , DOS_PRIORITY_RAPS_SOURCE
              , PROVIDER_LAST
              , PROVIDER_FIRST
              , PROVIDER_GROUP
              , PROVIDER_ADDRESS
              , PROVIDER_CITY
              , PROVIDER_STATE
              , PROVIDER_ZIP
              , PROVIDER_PHONE
              , PROVIDER_FAX
              , Tax_Id
              , NPI
              , Sweep_Date
              , Populated_Date
              , MODEL_YEAR
			  , EncounterSource

            )
            select @ProcessRunId              as ProcessRunId
                 , n.PaymentYear
                 , n.ProcessedByStart
                 , n.ProcessedByEnd
                 , n.Planid
                 , n.Hicn
                 , n.RAFactorType
                 , case
                       when n.UnionqueryInd = 1 then
                           'I'
                       when n.UnionqueryInd = 2 then
                           'M'
                       when n.UnionqueryInd = 3 then
                           'F'
                   end                        as Processed_By_Flag
                 , case
                       when n.HCC like '%HCC%'
                            and n.HCC like 'M-High%' then
                           substring(n.HCC, charindex('HCC', n.HCC), len(n.HCC))
                       when n.HCC like '%D-HCC%'
                            and n.HCC like 'M-High%' then
                           substring(n.HCC, charindex('D-HCC', n.HCC), len(n.HCC))
                       else
                           n.HCC
                   end                        as RxHCC
                 , n.HCCDescription
                 , n.HCCFactor                as RxHCC_Factor
                 , case
                       when n.HierHCC like '%HCC%'
                            and n.HierHCC like 'MOR-INCR%' then
                           'MOR-' + substring(n.HierHCC, charindex('HCC', n.HierHCC), len(n.HierHCC))
                       when n.HierHCC like '%D-HCC%'
                            and n.HierHCC like 'MOR-INCR%' then
                           'MOR-' + substring(n.HierHCC, charindex('D-HCC', n.HierHCC), len(n.HierHCC))
                       else
                           n.HierHCC
                   end                        as HIER_RxHCC
                 , n.HierHCCfactor            as HIER_RxHCC_FACTOR
                 , n.FactorDiff               as Pre_Adjstd_Factor
                 , n.FinalFactor              as Adjstd_Final_Factor
                 , n.HCCProcessedPCN
                 , n.HierHCCProcessedPCN
                 , case
                       when (
                                m.PaymentYear is null
                                and m.ModelYear is null
                                and m.PlanID is null
                                and m.HICN is null
                                and m.OnlyHCC is null
                                and m.HCCNumber is null
                                and m.RAFactorType is null
                                and m.SCC is null
                                and m.PBP is null
                            )
                            or n.HCC like 'INCR%' then
                           0
                       else
                           1
                   end                        as UNQ_CONDITIONS
                 , n.MonthsInDCP
                 , n.MemberMonths
                 , n.BID                      as Bid_Amount
                 , n.EstimatedValue           as ESTIMATED_VALUE
                 , n.Rollforwardmonths        as Rollforward_Months
                 , n.AnnualizedEstimatedValue as ANNUALIZED_ESTIMATED_VALUE
                 , n.PBP
                 , n.SCC
                 , n.ProcessedPriorityProcessedBy
                 , n.ProcessedPriorityThrudate
                 , n.ProcessedPriorityDiag
                 , n.ProcessedPriorityFileID
                 , n.ProcessedPriorityRAC
                 , n.ProcessedPriorityRAPSSourceID
                 , n.DOSPriorityProcessedBy
                 , n.DOSPriorityThruDate
                 , n.DOSPriorityPCN
                 , n.DOSPriorityDiag
                 , n.DOSPriorityFileID
                 , n.DOSPriorityRAC
                 , n.DOSPriorityRAPSSource
                 , n.ProviderLast
                 , n.ProviderFirst
                 , n.ProviderGroup
                 , n.ProviderAddress
                 , n.ProviderCity
                 , n.ProviderState
                 , n.ProviderZip
                 , n.ProviderPhone
                 , n.ProviderFax
                 , n.TaxID
                 , n.NPI
                 , n.SweepDate
                 , n.PopulatedDate
                 , n.ModelYear
				 , 'RAPS' as EncounterSource
            from #NewHCCFinalValView            n
                left join #FinalUniqueCondition m
                    on n.PaymentYear = m.PaymentYear
                       and n.ModelYear = m.ModelYear
                       and n.AGED = m.AGED
                       and n.Planid = m.PlanID
                       and n.Hicn = m.HICN
                       and n.OnlyHCC = m.OnlyHCC
                       and n.HCCNumber = m.HCCNumber
                       and n.RAFactorType = m.RAFactorType
                       and n.PBP = m.PBP
                       and n.SCC = m.SCC;

    SET @RowCount = Isnull(@@ROWCOUNT,0);  --RRI-348/908
    SET @ReportOutputByMonthID = 'V';
	SET @TableName = 'Valuation.NewHCCPartD';


  	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('041', 0, 1) WITH NOWAIT;
    END;
        end

    end

    if @ReportOutputByMonth = 'M'
    begin
 
        if object_id('TempDB..#NewHCCFinalMView') is not null
            drop table #NewHCCFinalMView;

        create table #NewHCCFinalMView
        (
            PaymentYear int null
          , ModelYear int null
          , PAYMSTART datetime null
          , Processed_by_start datetime null
          , Processed_by_end datetime null
          , Planid varchar(5) null
          , Hicn varchar(15) null
          , RAFactorType char(2) null
          , Processed_priority_processed_by datetime null
          , Processed_priority_thru_date datetime null
          , HCC_PROCESSED_PCN varchar(50) null
          , Processed_priority_diag varchar(20) null
          , Processed_Priority_FileID varchar(18) null
          , Processed_Priority_RAC char(1) null
          , Processed_Priority_RAPS_Source_ID varchar(50) null
          , DOS_PRIORITY_PROCESSED_BY datetime null
          , DOS_PRIORITY_THRU_DATE datetime null
          , DOS_PRIORITY_PCN varchar(50) null
          , DOS_PRIORITY_DIAG varchar(20) null
          , DOS_PRIORITY_FILEID varchar(18) null
          , DOS_PRIORITY_RAC char(1) null
          , DOS_PRIORITY_RAPS_SOURCE varchar(50) null
          , Hcc varchar(50) null
          , Hcc_description varchar(255) null
          , HCC_FACTOR decimal(20, 4) null
          , HIER_HCC varchar(20) null
          , HIER_HCC_FACTOR decimal(20, 4) null
          , FINAL_FACTOR decimal(20, 4) null
          , Factor_diff decimal(20, 4) null
          , HIER_HCC_PROCESSED_PCN varchar(50) null
          , Active_indicator_for_rollforward char(1) null
          , Months_in_dcp int null
          , Esrd char(1) null
          , Hosp char(1) null
          , PBP varchar(3) null
          , SCC varchar(5) null
          , Bid money null
          , EstimatedValue money null
          , Providerid varchar(40) null
          , Providerlast varchar(55) null
          , Providerfirst varchar(55) null
          , Providergroup varchar(80) null
          , Provideraddress varchar(100) null
          , Providercity varchar(30) null
          , Providerstate char(2) null
          , Providerzip varchar(13) null
          , Providerphone varchar(15) null
          , Providerfax varchar(15) null
          , Tax_id varchar(55) null
          , Npi varchar(20) null
          , SWEEP_DATE date null
          , OnlyHCC varchar(20) null
          , HCCNumber int null
          , AGED int null
          , ProcessedByFlag char(1) null
          , RollForwardMonths int null
        )

        insert into #NewHCCFinalMView
        (
            PaymentYear
          , ModelYear
          , PAYMSTART
          , Processed_by_start
          , Processed_by_end
          , Planid
          , Hicn
          , RAFactorType
          , Processed_priority_processed_by
          , Processed_priority_thru_date
          , HCC_PROCESSED_PCN
          , Processed_priority_diag
          , Processed_Priority_FileID
          , Processed_Priority_RAC
          , Processed_Priority_RAPS_Source_ID
          , DOS_PRIORITY_PROCESSED_BY
          , DOS_PRIORITY_THRU_DATE
          , DOS_PRIORITY_PCN
          , DOS_PRIORITY_DIAG
          , DOS_PRIORITY_FILEID
          , DOS_PRIORITY_RAC
          , DOS_PRIORITY_RAPS_SOURCE
          , Hcc
          , Hcc_description
          , HCC_FACTOR
          , HIER_HCC
          , HIER_HCC_FACTOR
          , FINAL_FACTOR
          , Factor_diff
          , HIER_HCC_PROCESSED_PCN
          , Active_indicator_for_rollforward
          , Months_in_dcp
          , Esrd
          , Hosp
          , PBP
          , SCC
          , Bid
          , EstimatedValue
          , Providerid
          , Providerlast
          , Providerfirst
          , Providergroup
          , Provideraddress
          , Providercity
          , Providerstate
          , Providerzip
          , Providerphone
          , Providerfax
          , Tax_id
          , Npi
          , SWEEP_DATE
          , OnlyHCC
          , HCCNumber
          , AGED
          , ProcessedByFlag
          , RollForwardMonths
        )
        select distinct
            n.PaymentYear
          , n.ModelYear
          , n.PaymStart
          , n.ProcessedByStart
          , n.ProcessedByEnd
          , n.PlanId
          , n.HICN
          , n.RAFactorType
          , n.ProcessedPriorityProcessedBy
          , n.ProcessedPriorityThruDate
          , n.ProcessedPriorityPCN                       as HCCPROCESSEDPCN
          , n.ProcessedPriorityDiag
          , n.ProcessedPriorityFileID
          , n.ProcessedPriorityRAC
          , n.ProcessedPriorityRAPSSourceID
          , n.ThruPriorityProcessedBy                    as DOSPRIORITYPROCESSEDBY
          , n.ThruPriorityThruDate                       as DOSPRIORITYTHRUDATE
          , n.ThruPriorityPCN                            as DOSPRIORITYPCN
          , n.ThruPriorityDiag                           as DOSPRIORITYDIAG
          , n.ThruPriorityFileID                         as DOSPRIORITYFILEID
          , ThruPriorityRAC                              as DOSPRIORITYRAC
          , ThruPriorityRAPSSourceID                     as DOSPRIORITYRAPSSOURCE
          , n.HCC
          , n.HCCDescription
          , isnull(n.Factor, 0)                          'HCCFACTOR'
          , n.HierHCCOld                                 as HIERHCC
          , isnull(n.HierFactorOld, 0)                   'HIERHCCFACTOR'
          , n.FinalFactor                                as FINALFACTOR
          , n.FactorDiff
          , n.HierHCCProcessedPCN
          , isnull(n.ActiveIndicatorForRollforward, 'N') 'ActiveIndicatorForRollforward'
          , isnull(n.MonthsInDCP, 0)                     'MONTHSINDCP'
          , isnull(n.ESRD, 'N')                          'ESRD'
          , isnull(n.Hosp, 'N')                          'HOSP'
          , n.PBP
          , isnull(n.SCC, 'OOA')                         'SCC'
          , isnull(n.Bid, 0)                             'BID'
          , isnull(n.EstimatedValue, 0)                  as 'EstimatedValue'
          , n.ProviderID
          , n.ProviderLast
          , n.ProviderFirst
          , n.ProviderGroup
          , n.ProviderAddress
          , n.ProviderCity
          , n.ProviderState
          , n.ProviderZip
          , n.ProviderPhone
          , n.ProviderFax
          , n.TaxID
          , n.NPI
          , case
                when n.UnionQueryInd = 1 then
                    @InitialFlag
                when n.UnionQueryInd = 2 then
                    @MyuFlag
                when n.UnionQueryInd = 3 then
                    @FinalFlag
            end                                          SWEEPDATE
          , n.OnlyHCC
          , n.HCCNumber
          , n.Aged
          , case
                when n.UnionQueryInd = 1 then
                    'I'
                when n.UnionQueryInd = 2 then
                    'M'
                when n.UnionQueryInd = 3 then
                    'F'
            end                                          as ProcessedByFlag
          , case
                when @PaymentYearNewDeleteHCC < @CurrentYear
                     or (
                            @PaymentYearNewDeleteHCC >= @CurrentYear
                            and month(r.MemberMonths) < @MaxMonth
                        ) then
                    0
                else
                    12 - month(r.MemberMonths)
            end                                          as RollForwardMonths
        from [etl].[IntermediatePartDRAPSNewHCCOutput]                n
            left join #RollForwardMonths r
                on n.HICN = r.HICN
                   and n.RAFactorType = r.RAFactorType
                   and n.PlanId = r.PlanID
                   and n.SCC = r.SCC
                   and n.PBP = r.PBP
        where n.ProcessedPriorityProcessedBy
              between @ProcessByStartDate and @ProcessByEndDate
              and n.HCC not like 'HIER%'

	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('042', 0, 1) WITH NOWAIT;
    END;


   update n
    set n.ProviderLast = u.LastName
      , n.ProviderFirst = u.FirstName
      , n.ProviderGroup = u.GroupName
      , n.ProviderAddress = u.ContactAddress
      , n.ProviderCity = u.ContactCity
      , n.ProviderState = u.ContactState
      , n.ProviderZip = u.ContactZip
      , n.ProviderPhone = u.WorkPhone
      , n.ProviderFax = u.WorkFax
      , n.Tax_ID = u.AssocName
      , n.NPI = u.NPI
    from #NewHCCFinalMView n
        join #Providers      u
            on n.ProviderID = u.ProviderId

 
	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('043', 0, 1) WITH NOWAIT;
    END;

        Insert into etl.PartDNewHCCOutputMParameter
        (
            [PaymentYear]
          , [ModelYear]
          , [PaymentStartDate]
          , [ProcessedByStartDate]
          , [ProcessedByEndDate]
          , [ProcessedByFlag]
          , [EncounterSource]
          , [PlanID]
          , [HICN]
          , [RAFactorType]
          , [RxHCC]
          , [HCCDescription]
          , [RxHCCFactor]
          , [HierarchyRxHCC]
          , [HierarchyRxHCCFactor]
          , [PreAdjustedFactor]
          , [AdjustedFinalFactor]
          , [HCCProcessedPCN]
          , [HierarchyHCCProcessedPCN]
          , [UniqueConditions]
          , [MonthsInDCP]
          , [BidAmount]
          , [EstimatedValue]
          , [RollForwardMonths]
          , [ActiveIndicatorForRollForward]
          , [PBP]
          , [SCC]
          , [ProcessedPriorityProcessedByDate]
          , [ProcessedPriorityThruDate]
          , [ProcessedPriorityDiag]
          , [ProcessedPriorityFileID]
          , [ProcessedPriorityRAC]
          , [ProcessedPriorityRAPSSourceID]
          , [DOSPriorityProcessedByDate]
          , [DOSPriorityThruDate]
          , [DOSPriorityPCN]
          , [DOSPriorityDiag]
          , [DOSPriorityFileID]
          , [DOSPriorityRAC]
          , [DOSPriorityRAPSSourceID]
          , [ProcessedPriorityICN]
          , [ProcessedPriorityEncounterID]
          , [ProcessedPriorityReplacementEncounterSwitch]
          , [ProcessedPriorityClaimID]
          , [ProcessedPrioritySecondaryClaimID]
          , [ProcessedPrioritySystemSource]
          , [ProcessedPriorityRecordID]
          , [ProcessedPriorityVendorID]
          , [ProcessedPrioritySubProjectID]
          , [ProcessedPriorityMatched]
          , [DOSPriorityICN]
          , [DOSPriorityEncounterID]
          , [DOSPriorityReplacementEncounterSwitch]
          , [DOSPriorityClaimID]
          , [DOSPrioritySecondaryClaimID]
          , [DOSPrioritySystemSource]
          , [DOSPriorityRecordID]
          , [DOSPriorityVendorID]
          , [DOSPrioritySubProjectID]
          , [DOSPriorityMatched]
          , [ProviderID]
          , [ProviderLast]
          , [ProviderFirst]
          , [ProviderGroup]
          , [ProviderAddress]
          , [ProviderCity]
          , [ProviderState]
          , [ProviderZip]
          , [ProviderPhone]
          , [ProviderFax]
          , [TaxID]
          , [NPI]
          , [SweepDate]
          , [PopulatedDate]
          , [AgedStatus]
          , [UserID]
          , [LoadDate]
          , [ProcessedPriorityMAO004ResponseDiagnosisCodeID]
          , [DOSPriorityMAO004ResponseDiagnosisCodeID]
          , [ProcessedPriorityMatchedEncounterICN]
          , [DOSPriorityMatchedEncounterICN]
        )
        select distinct
            n.PaymentYear                                   as PaymentYear
          , n.ModelYear
          , n.PAYMSTART                                     as PaymentStart
          , n.Processed_by_start                            as ProcessedByStart
          , n.Processed_by_end                              as ProcessedByEnd
          , n.ProcessedByFlag                               as ProcessedByFlag
          , 'RAPS'                                          as EncounterSource
          , n.Planid                                        as PlanID
          , n.Hicn                                          as HICN
          , n.RAFactorType                                  as RAFactorType
          , case
                when n.Hcc like '%HCC%'
                     and n.Hcc like 'M-High%' then
                    substring(n.Hcc, charindex('HCC', n.Hcc), len(n.Hcc))
                when n.Hcc like '%D-HCC%'
                     and n.Hcc like 'M-High%' then
                    substring(n.Hcc, charindex('D-HCC', n.Hcc), len(n.Hcc))
                else
                    n.Hcc
            end                                             as HCC
          , n.Hcc_description                               as HCCDescription
          , HCC_FACTOR                                      as HCCFactor
          , case
                when HIER_HCC like '%HCC%'
                     and HIER_HCC like 'MOR-INCR%' then
                    'MOR-' + substring(HIER_HCC, charindex('HCC', HIER_HCC), len(HIER_HCC))
                when HIER_HCC like '%D-HCC%'
                     and HIER_HCC like 'MOR-INCR%' then
                    'MOR-' + substring(HIER_HCC, charindex('D-HCC', HIER_HCC), len(HIER_HCC))
                else
                    HIER_HCC
            end                                             as HierarchyHCC
          , HIER_HCC_FACTOR                                 as HierarchyHCCFactor
          , Factor_diff                                     as PreAdjustedFactor
          , (n.FINAL_FACTOR) * (SS.SubmissionSplitWeight)   as AdjustedFinalFactor
          , HCC_PROCESSED_PCN                               as HCCProcessedPCN
          , HIER_HCC_PROCESSED_PCN                          as HierarchyHCCProcessedPCN
          , case
                when (
                         m.PaymentYear is null
                         and m.ModelYear is null
                         and m.PlanID is null
                         and m.HICN is null
                         and m.OnlyHCC is null
                         and m.HCCNumber is null
                         and m.RAFactorType is null
                         and m.SCC is null
                         and m.PBP is null
                     )
                     or n.Hcc like 'INCR%' then
                    0
                else
                    1
            end                                             as UniqueConditions
          , Months_in_dcp                                   as MonthsInDCP
          , Bid                                             as BidAmount
          , (n.EstimatedValue) * (SS.SubmissionSplitWeight) as EstimatedValue
          , case
                when @CurrentYear < @PaymentYearNewDeleteHCC then
                    11
                else
                    n.RollForwardMonths
            end                                             as RollForwardMonths
          , Active_indicator_for_rollforward                as ActiveIndicatorForRollForward
          , n.PBP                                           as PBP
          , n.SCC                                           as SCC
          /* These fields are populated for RAPS */
          , Processed_priority_processed_by                 as ProcessedPriorityProcessedByDate
          , Processed_priority_thru_date                    as ProcessedPriorityThruDate
          , Processed_priority_diag                         as ProcessedPriorityDiag
          , Processed_Priority_FileID                       as ProcessedPriorityFileID
          , Processed_Priority_RAC                          as ProcessedPriorityRAC
          , Processed_Priority_RAPS_Source_ID               as ProcessedPriorityRAPSSourceID
          , DOS_PRIORITY_PROCESSED_BY                       as DOSPriorityProcessedByDate
          , DOS_PRIORITY_THRU_DATE                          as DOSPriorityProcessedByDate
          , DOS_PRIORITY_PCN                                as DOSPriorityPCN
          , DOS_PRIORITY_DIAG                               as DOSPriorityDiag
          , DOS_PRIORITY_FILEID                             as DOSPriorityFileID
          , DOS_PRIORITY_RAC                                as DOSPriorityRAC
          , DOS_PRIORITY_RAPS_SOURCE                        as DOSPriorityRAPSSourceID
          /* These fields will be populated for EDS but will be NULL for RAPS */
          , null                                            as ProcessedPriorityICN
          , null                                            as ProcessedPriorityEncounterID
          , null                                            as ProcessedPriorityReplacementEncounterSwitch
          , null                                            as ProcessedPriorityClaimID
          , null                                            as ProcessedPrioritySecondaryClaimID
          , null                                            as ProcessedPrioritySystemSource
          , null                                            as ProcessedPriorityRecordID
          , null                                            as ProcessedPriorityVendorID
          , null                                            as ProcessedPrioritySubProjectID
          , null                                            as ProcessedPriorityMatched
          , null                                            as DOSPriorityICN
          , null                                            as DOSPriorityEncounterID
          , null                                            as DOSPriorityReplacementEncounterSwitch
          , null                                            as DOSPriorityClaimID
          , null                                            as DOSPrioritySecondaryClaimID
          , null                                            as DOSPrioritySystemSource
          , null                                            as DOSPriorityRecordID
          , null                                            as DOSPriorityVendorID
          , null                                            as DOSPrioritySubProjectID
          , null                                            as DOSPriorityMatched
          , n.Providerid                                    as ProviderID
          , Providerlast                                    as ProviderLast
          , Providerfirst                                   as ProviderFirst
          , Providergroup                                   as ProviderGroup
          , Provideraddress                                 as ProviderAddress
          , Providercity                                    as ProviderCity
          , Providerstate                                   as ProviderState
          , Providerzip                                     as ProviderZip
          , Providerphone                                   as ProviderPhone
          , Providerfax                                     as ProviderFax
          , Tax_id                                          as TaxID
          , Npi                                             as NPI
          , SWEEP_DATE                                      as SweepDate
          , @Today                                          as PopulatedDate
          , AgedStatus                                      = case
                                                                  when n.AGED = 1 then
                                                                      'Aged'
                                                                  when n.AGED = 0 then
                                                                      'Disabled'
                                                                  else
                                                                      'Not Applicable'
                                                              end
          , suser_name()                                    as UserID
          , @Today                                          as LoadDate
          , null                                            as ProcessedPriorityMAO004ResponseDiagnosisCodeID
          , null                                            as DOSPriorityMAO004ResponseDiagnosisCodeID
          , null                                            as ProcessedPriorityMatchedEncounterICN
          , null                                            as DOSPriorityMatchedEncounterICN
        from #NewHCCFinalMView                                   n
            join [$(HRPReporting)].dbo.EDSRAPSSubmissionSplit         SS
                on n.PaymentYear = SS.PaymentYear
                   and SS.SubmissionModel = 'RAPS'
                   and SS.MYUFlag = 'N'
            left join #FinalUniqueCondition                      m
                on n.PaymentYear = m.PaymentYear
                   and [n].[ModelYear] = [m].[ModelYear]
                   and [n].[Planid] = [m].[PlanID]
                   and [n].[AGED] = [m].[AGED]
                   and [n].[Hicn] = [m].[HICN]
                   and [n].[OnlyHCC] = [m].[OnlyHCC]
                   and [n].[HCCNumber] = [m].[HCCNumber]
                   and [n].[RAFactorType] = [m].[RAFactorType]
                   and [n].[PBP] = [m].[PBP]
            left join [rev].[SummaryPartDRskAdjRAPSMORDCombined] [mr]
                on [n].[PaymentYear] = [mr].[PaymentYear]
                   and [n].[ModelYear] = [mr].[ModelYear]
                   and [n].[Hicn] = [mr].[Hicn]
                   and [n].[HCCNumber] = [mr].[RxHCCNumber];


    SET @RowCount = Isnull(@@ROWCOUNT,0);  --RRI-348/908
    SET @ReportOutputByMonthID = 'M';
	SET @TableName = 'etl.PartDNewHCCOutputMParameter';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('044', 0, 1) WITH NOWAIT;
    END;

        update [m1]
        set [m1].[LastAssignedHICN] = isnull(
                                                [b].[LastAssignedHICN]
                                              , case
                                                    when ssnri.fnValidateMBI([m1].[HICN]) = 1 then
                                                        [b].[HICN]
                                                end
                                            )
        from [etl].[PartDNewHCCOutputMParameter] [m1]
            cross apply
        (
            select top 1
                [b].[LastAssignedHICN]
              , [b].[HICN]
            from [rev].[SummaryPartDRskAdjRAPSMORDCombined] as [b]
            where [m1].[HICN] = [b].[HICN]
                  and [m1].[PaymentYear] = [b].[PaymentYear]
                  and [m1].[ModelYear] = [b].[ModelYear]
            order by [b].[LoadDate] desc
        )                                        as [b]


	IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('045', 0, 1) WITH NOWAIT;
    END;
 
    end

end


 


 