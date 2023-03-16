create procedure [Valuation].[GetNewHCCPartD]
    @PAYMENT_YEAR varchar(4)
  , @PROCESSBY_START smalldatetime
  , @PROCESSBY_END smalldatetime
  , @PRIORITY varchar(1) -- P = Min Processed By    S = Min Date of Service
  , @Valuation bit = 0
  , @ProcessRunId int = null
  , @$EnumDbName varchar(128) = null
  , @Debug bit = 0
as


/************************************************************************   
 * Version History : 
  Author			Date		Version#    TFS Ticket#	      Description
* -----------------	----------  --------    -----------	      ------------  
  John Skur              TBD                    2432          New Part D report
  Steve Walker      1/11/2012                   8650          Added Max() to Update subqueries
  Josh Irwin        3/14/2012                   9716          Added logic to exit report if #RAPHICN_SPR_RAPS_HCC_RANGE is empty
  Josh Irwin        3/14/2012                  9884           Fixed date conversion issue
  Josh Irwin        5/31/2012                  11128          Updated logic to return correct column count even if there are no results
  Josh Irwin        9/13/2012                  13300          Added logic to filter records by HICN/Payment Year on tbl_Member_Months
  Madhuri Suri      3/3/2015     1.0           25628          Changes to Include D3 in the results
  Ravi Chauhan  	03/11/2015   2.0	       25628		  Included Dynamic SQL to get rollup planID
  Madhuri Suri      06/30/2015   2.1           43224          MOR Paymonth Changes --Hotfix
  Madhuri Suri      08/03/2015   2.2           39761          Changes to include IMF Flag
  Madhuri Suri      08/10/2015   2.3           44559          Hotfix: Remove RaiseError Syntax causing failure for inactive plans
  Madhuri Suri      09/14/2015   2.4		   44300          Adding [Processed_By_Flag] tp Valuation output
  Madhuri Suri 		10/12/2015   2.41		   45817		  ICD10 Compliance changes required.
  Madhuri Suri 		11/09/2015   2.42		   46640		  Null PCNs in Valuation Output
  Madhuri Suri 		02/08/2016   3.0		   47772		  Phase 2 Redesign Changes
  David Waddell		07/13/2018   3.1		   72101(RE-2508) Correct [Valuation].[GetNewHCCPartD] to reflect MBI changes for New HCC Part D legacy.	
***************************************************************************/
set transaction isolation level read uncommitted

/*For Test 39761*/
----  exec SPR_RAPS_HCC_RANGE_PartD '2015','01-01-2013','12-31-2015','S'
----        DECLARE @PAYMENT_YEAR VARCHAR(4) = '2015'
----, @PROCESSBY_START SMALLDATETIME = '5/1/2015'
----, @PROCESSBY_END SMALLDATETIME = '6/30/2015'
----, @PRIORITY VARCHAR(1) = 'P' -- P = Min Processed By    S = Min Date of Service
----, @Valuation BIT = 0
----, @ProcessRunId INT = NULL			
----, @$EnumDbName VARCHAR(128) 
----, @Debug BIT = 0


set nocount on;
set statistics io off;

declare @RecordCount int = 0;
declare @Populated_Date datetime = getdate();
declare @PlanId varchar(5);
set @$EnumDbName = isnull(@$EnumDbName, db_name());
/*39761 - IMF Flagging*/
declare @IMFInitialProcessby date
declare @IMFMidProcessby date
declare @IMFFinalProcessby date
declare @IMFDCPThrudate date
begin




    if @Debug = 1
    begin

        --EK 6/21/18 Drop #ProcessLog Table
        if object_id('[tempdb].[dbo].[#processlog]', 'U') is not null
        begin
            drop table #processlog;
        end;

        --IF object_id('tempdb.dbo.#processlog') > 0
        --	DROP TABLE #processlog

        create table #processlog
        (
            ProcessName varchar(128)
          , DatabaseName varchar(128)
          , MasterET datetime
          , ET datetime
          , Secs varchar(25)
          , StepID varchar(5)
        )


        declare @ET datetime = getdate()
        declare @MasterET datetime
        declare @ProcessName varchar(128) = object_name(@@procid)
        declare @DatabaseName varchar(128) = db_name()

        set @MasterET = getdate()
    end



    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '000'
        set @ET = getdate()
    end

    /* Original
	/*Note: Db specific */
	SET @PlanId = (SELECT
	PlanId
	FROM dbo.tbl_Plan_Name WITH (NOLOCK))
	*/

    declare @GetPlanIdSQL nvarchar(1024);

    set @GetPlanIdSQL = 'SELECT @PlanId = [Plan_Id] FROM [' + @$EnumDbName + '].[dbo].[tbl_Plan_Name] WITH (NOLOCK)';

    exec sp_executesql @GetPlanIdSQL, N'@PlanId VARCHAR(5) OUT', @PlanId out;


    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '001'
        set @ET = getdate()
    end

    declare @PAYMENT_YEAR2 varchar(4);
    set @PAYMENT_YEAR2 = @PAYMENT_YEAR;

    declare @PROCESSBY_START2 smalldatetime;
    set @PROCESSBY_START2 = @PROCESSBY_START;

    declare @PROCESSBY_END2 smalldatetime;
    set @PROCESSBY_END2 = @PROCESSBY_END;

    declare @PRIORITY2 varchar(1);
    set @PRIORITY2 = @PRIORITY;

    declare @PAYMENT_YEAR_NEW varchar(4);
    declare @MEMBER_MONTHS int;

    declare @Paymonth_MOR varchar(2) = (case
                                            when @PAYMENT_YEAR2 = 2015 then
                                                '08'
                                            else
                                                '07'
                                        end
                                       ) --43224
    declare @Paymonth_MMR varchar(2) = (
                                           select distinct
                                               right(Paymonth, 2)
                                           from [$(HRPReporting)].dbo.lk_DCP_dates a
                                           where left(PayMonth, 4) = @PAYMENT_YEAR2
                                                 and a.Mid_Year_Update = 'Y'
                                       ) --39761



    /*39761-- IMF Flagging */
    select @IMFDCPThrudate      = min(DCP_end)
         , @IMFInitialProcessby = min(Initial_Sweep_Date)
         , @IMFFinalProcessby   = max(Final_Sweep_Date)
    from [$(HRPReporting)]..lk_DCP_dates
    where Mid_Year_Update is null
          and left(Paymonth, 4) = @PAYMENT_YEAR;

    select @IMFMidProcessby = max(Initial_Sweep_Date)
    from [$(HRPReporting)]..lk_DCP_dates dcp
    where Mid_Year_Update = 'Y'
          and left(Paymonth, 4) = @PAYMENT_YEAR;



    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '002'
        set @ET = getdate()
    end

    /*45817*/
    if object_id('tempdb..#Vw_LkRiskModelsDiagHCC') is not null
        drop table #Vw_LkRiskModelsDiagHCC

    select ICDCode
         , HCCLabel    as HCC_Label
         , PaymentYear as Payment_Year
         , FactorType  as Factor_Type
         , ICD.ICDClassification
         , ef.StartDate
         , ef.EndDate
    into #Vw_LkRiskModelsDiagHCC
    from [$(HRPReporting)].dbo.[Vw_LkRiskModelsDiagHCC] ICD
        join [$(HRPReporting)].dbo.ICDEffectiveDates    ef
            on ICD.ICDClassification = ef.ICDClassification
    where ICD.FactorType = 'D1'
          and PaymentYear = @PAYMENT_YEAR2



    /* Originial
	/*Note: Db specific */
	SET @MEMBER_MONTHS = (SELECT
	COUNT(*)
	FROM DBO.TBL_MEMBER_MONTHS(NOLOCK)
	WHERE PAYMSTART BETWEEN '01/01/' + CONVERT(VARCHAR(4), @PAYMENT_YEAR2)AND '12/31/' + CONVERT(VARCHAR(4), @PAYMENT_YEAR2))
	*/

    declare @GetMember_MonthsSQL nvarchar(2048);

    set @GetMember_MonthsSQL
        = 'SELECT @MEMBER_MONTHS =
										   COUNT(*)
									 FROM [' + @$EnumDbName
          + '].[dbo].[TBL_MEMBER_MONTHS] WITH (NOLOCK)
									 WHERE PAYMSTART BETWEEN ''01/01/'' + CONVERT(CHAR(4), ' + @PAYMENT_YEAR2
          + ')AND ''12/31/'' 
									 + CONVERT(CHAR(4), ' + @PAYMENT_YEAR2 + ')';

    exec sp_executesql @GetMember_MonthsSQL
                     , N'@MEMBER_MONTHS INT OUT'
                     , @MEMBER_MONTHS out;


    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '003'
        set @ET = getdate()
    end
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    --WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!
    if @MEMBER_MONTHS = 0
       and
       (
           select case when year(getdate()) < @PAYMENT_YEAR2 then 0 else 1 end
       ) = 0
    begin
        set @PAYMENT_YEAR_NEW = @PAYMENT_YEAR2 - 1;
    end;
    else
    begin
        set @PAYMENT_YEAR_NEW = @PAYMENT_YEAR2;
    end;

    declare @PAYMSTART date;
    declare @PAYMEND date;

    if @MEMBER_MONTHS = 0
       and
       (
           select case when year(getdate()) < @PAYMENT_YEAR2 then 0 else 1 end
       ) = 0
    begin

        /* Original
		/*Note: Db specific */
		SET @PAYMSTART = (SELECT
		MAX([PAYMSTART])
		FROM [dbo].[tbl_Member_Months] WITH (NOLOCK)
		WHERE YEAR([PAYMSTART])
		= @PAYMENT_YEAR_NEW)
		*/
        declare @Get_PaymStartSQL nvarchar(1024);

        set @Get_PaymStartSQL
            = 'SELECT @PAYMSTART =
											  MAX([PAYMSTART])
										FROM [' + @$EnumDbName
              + '].[dbo].[tbl_Member_Months] WITH (NOLOCK)
										WHERE YEAR([PAYMSTART])
											 = ' + @PAYMENT_YEAR_NEW;

        exec sp_executesql @Get_PaymStartSQL
                         , N'@PAYMSTART DATE OUT'
                         , @PAYMSTART out;


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '004'
            set @ET = getdate()
        end

        --WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!
        set @PAYMEND = @PAYMSTART;
    end;
    else
    begin
        set @PAYMSTART = '01/01/' + convert(char(4), @PAYMENT_YEAR2);
        set @PAYMEND = '12/31/' + convert(char(4), @PAYMENT_YEAR2);
    end;

    declare @BIDYEAR varchar(4);

    /* Originial
	/*Note: Db specific */
	IF(SELECT
	COUNT(*)
	FROM [dbo].tbl_BIDS
	WHERE BID_YEAR
	=
	@PAYMENT_YEAR2)
	=
	0
	*/

    declare @GetBIDCountSQL nvarchar(1024);

    declare @GetBIDCount int;

    set @GetBIDCountSQL = 'SELECT
								@GetBIDCount = COUNT(*)
						  FROM [' + @$EnumDbName + '].[dbo].[tbl_BIDS] WITH (NOLOCK)
						  WHERE BID_YEAR = CAST(' + @PAYMENT_YEAR2 + ' AS NVARCHAR(10)) ';

    exec sp_executesql @GetBIDCountSQL
                     , N'@GetBIDCount INT OUT'
                     , @GetBIDCount out;


    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '005'
        set @ET = getdate()
    end
    if @GetBIDCount = 0
    begin
        set @BIDYEAR = @PAYMENT_YEAR_NEW;
    end;
    else
    begin
        set @BIDYEAR = @PAYMENT_YEAR2;
    end;
    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '006'
        set @ET = getdate()
    end
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    if object_id('[tempdb].[dbo].[#RAPHICN_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #RAPHICN_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#ALLALTHICN_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #ALLALTHICN_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#HICN_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #HICN_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#ALTHICN_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #ALTHICN_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_A_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_A_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#VW_RAPS_ACCEPTED_RANGE]', 'U') is not null
    begin
        drop table #VW_RAPS_ACCEPTED_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#POPUL_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #POPUL_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_B_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_B_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_B2_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_B2_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#HIERARCHY_B_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #HIERARCHY_B_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_MOR_B_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_MOR_B_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_C_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_C_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#HIERARCHY_B_C_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #HIERARCHY_B_C_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#HIERARCHY_C_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #HIERARCHY_C_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_DEMO_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_D_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #PLANRISK_D_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#HIERARCHY_D_B_SPR_RAPS_HCC_RANGE]', 'U') is not null
    begin
        drop table #HIERARCHY_D_B_SPR_RAPS_HCC_RANGE;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_A_Interactions_Detail]', 'U') is not null
    begin
        drop table #PLANRISK_A_Interactions_Detail;
    end;

    if object_id('[tempdb].[dbo].[#PLANRISK_A_Interactions_Max_DOS]', 'U') is not null
    begin
        drop table #PLANRISK_A_Interactions_Max_DOS;
    end;

    --EK 6/21/18
    if object_id('[tempdb].[dbo].[#MBICrosswalkPlan]', 'U') is not null
    begin
        drop table #MBICrosswalkPlan;
    end;


    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 1', GETDATE()

    /*DETERMINE LIST OF HICNS BASED ON RAPS*/
    create table #RAPHICN_SPR_RAPS_HCC_RANGE
    (
        [Id] int identity(1, 1) primary key
      , [HICN] varchar(15)
      , [FINALHICN] varchar(15)
      --EK 6/21/18
      , [LASTASSIGNEDHICN] varchar(15)
    );


    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '007'
        set @ET = getdate()
    end

    declare @RAPHICN_SPR_RAPS_HCC_RANGESQL varchar(2048);

    set @RAPHICN_SPR_RAPS_HCC_RANGESQL
        = '    
								INSERT  INTO #RAPHICN_SPR_RAPS_HCC_RANGE ([HICN])
								   SELECT DISTINCT [HICN] = raps.[HICN]
							        FROM [' + @$EnumDbName
          + '].[dbo].[vw_Raps_Accepted] raps WITH (NOLOCK)
									WHERE raps.[THRUDATE] 
												  BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2 - 1) + ''''
          + ' AND ''12/31/' + convert(char(4), @PAYMENT_YEAR2 - 1)
          + '''
												/*filters*/
										 AND raps.[PROCESSEDBY]
												  BETWEEN ''' + convert(char(10), @PROCESSBY_START2, 101) + ''''
          + ' AND ''' + convert(char(10), @PROCESSBY_END2, 101) + '''';

    exec (@RAPHICN_SPR_RAPS_HCC_RANGESQL);

    create nonclustered index IDX_#RAPHICN_SPR_RAPS_HCC_RANGE_HICN
    on #RAPHICN_SPR_RAPS_HCC_RANGE
    (
        [HICN]
      , [FINALHICN]
    );



    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '008'
        set @ET = getdate()
    end



    declare @RAPHICN_SPR_RAPS_HCC_RANGESQL02 varchar(4096);

    set @RAPHICN_SPR_RAPS_HCC_RANGESQL02
        = '    
							INSERT  INTO #RAPHICN_SPR_RAPS_HCC_RANGE(
												 [HICN]
												)--, [FINALHICN])
								SELECT DISTINCT
										 raps.[HICN]
									FROM [' + @$EnumDbName
          + '].[dbo].[VW_XPLAN_ACCEPTED_RAPS_DIAGS] raps WITH (NOLOCK)
									WHERE raps.[THRUDATE] 
										  BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2 - 1)
          + ''' 
											 AND ''12/31/' + convert(char(4), +@PAYMENT_YEAR2 - 1)
          + '''
										/*filters*/
									 AND raps.[PROCESSEDBY] 
										  BETWEEN ''' + convert(char(10), @PROCESSBY_START2, 101)
          + '''
											 AND ''' + convert(char(10), @PROCESSBY_END2, 101)
          + '''
									 AND NOT EXISTS(
												 SELECT
													   1
												 FROM #RAPHICN_SPR_RAPS_HCC_RANGE hicns
												 WHERE raps.[HICN]
													  = 
													  hicns.[HICN])
									 AND EXISTS(
											  SELECT
													1
											  FROM  [' + @$EnumDbName
          + '].[dbo].[TBL_MEMBER_MONTHS] mms WITH (NOLOCK)
											  WHERE raps.[HICN]
												   = 
												   mms.[HICN]
												AND YEAR(mms.[PaymStart]) = ''' + @PAYMENT_YEAR_NEW
          + '''
												   )';

    exec (@RAPHICN_SPR_RAPS_HCC_RANGESQL02);


    declare @RAPHICN_SPR_RAPS_HCC_RANGESQL03 varchar(4096);
    /*Join with MBI */
    set @RAPHICN_SPR_RAPS_HCC_RANGESQL03
        = '    
							INSERT  INTO #RAPHICN_SPR_RAPS_HCC_RANGE(
												 [HICN]
												)--, [FINALHICN])
								SELECT DISTINCT
										 raps.[HICN]
									FROM [' + @$EnumDbName
          + '].[dbo].[VW_XPLAN_ACCEPTED_RAPS_DIAGS] raps WITH (NOLOCK)
									WHERE raps.[THRUDATE] 
										  BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2 - 1)
          + ''' 
											 AND ''12/31/' + convert(char(4), +@PAYMENT_YEAR2 - 1)
          + '''
										/*filters*/
									 AND raps.[PROCESSEDBY] 
										  BETWEEN ''' + convert(char(10), @PROCESSBY_START2, 101)
          + '''
											 AND ''' + convert(char(10), @PROCESSBY_END2, 101)
          + '''
									 AND NOT EXISTS(
												 SELECT
													   1
												 FROM #RAPHICN_SPR_RAPS_HCC_RANGE hicns
												 WHERE raps.[HICN]
													  = 
													  hicns.[HICN])
									 AND EXISTS(
											
												SELECT
													1
											  FROM  [' + @$EnumDbName
          + '].[dbo].[TBL_MEMBER_MONTHS] mms WITH (NOLOCK)
											  JOIN [' + @$EnumDbName
          + '].[ssnri].[MBICrosswalkPlan] mbi WITH (NOLOCK)
													ON mms.HICN = mbi.MBI
											  WHERE raps.[HICN]
												   = 
												   MBI.[HICN]
												   )';

    exec (@RAPHICN_SPR_RAPS_HCC_RANGESQL03);



    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '009'
        set @ET = getdate()
    end


    /*DETERMINE LIST OF ALL ALTHICNS THAT MAP TO HICNS BASED ON RAPS*/
    create table #ALLALTHICN_SPR_RAPS_HCC_RANGE
    (
        [HICN] varchar(15)
      , [FINALHICN] varchar(15)
    );

    declare @ALLALTHICN_SPR_RAPS_HCC_RANGE_SQL varchar(2048);

    set @ALLALTHICN_SPR_RAPS_HCC_RANGE_SQL
        = '
				SELECT DISTINCT
					 a.[HICN]
					, a.[FINALHICN]
				FROM [' + @$EnumDbName
          + '].[dbo].[TBL_ALTHICN] a WITH (NOLOCK)
				UNION
				SELECT DISTINCT
					 a.[ALTHICN]
					, a.[FINALHICN]
				FROM [' + @$EnumDbName + '].[dbo].[TBL_ALTHICN] a WITH (NOLOCK)
				';



    set @ALLALTHICN_SPR_RAPS_HCC_RANGE_SQL
        = 'INSERT INTO #ALLALTHICN_SPR_RAPS_HCC_RANGE ([HICN],[FINALHICN]) ' + @ALLALTHICN_SPR_RAPS_HCC_RANGE_SQL
    exec (@ALLALTHICN_SPR_RAPS_HCC_RANGE_SQL);

    create nonclustered index IDX_ALLALTHICN_SPR_RAPS_HCC_RANGE_HICN
    on #ALLALTHICN_SPR_RAPS_HCC_RANGE
    (
        [HICN]
      , [FINALHICN]
    );

    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '010'
        set @ET = getdate()
    end

    update #RAPHICN_SPR_RAPS_HCC_RANGE
    set FINALHICN =
        (
            select max(ALT.FINALHICN)
            from #ALLALTHICN_SPR_RAPS_HCC_RANGE ALT
            where #RAPHICN_SPR_RAPS_HCC_RANGE.HICN = ALT.[HICN]
        );


    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '011'
        set @ET = getdate()
    end

    update m
    set m.FINALHICN = m.HICN
    from #RAPHICN_SPR_RAPS_HCC_RANGE m
    where m.FINALHICN is null;


    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '012'
        set @ET = getdate()
    end

    /*INSERT BACK IN ANY OTHER POTENTIAL ALTHICN INFORMATION*/

    insert into #RAPHICN_SPR_RAPS_HCC_RANGE
    (
        [HICN]
      , [FINALHICN]
    )
    select alt.[HICN]
         , alt.[FINALHICN]
    from #ALLALTHICN_SPR_RAPS_HCC_RANGE alt
    where exists
    (
        select 1
        from #RAPHICN_SPR_RAPS_HCC_RANGE rap
        where alt.FINALHICN = rap.FINALHICN
              and alt.HICN <> rap.HICN
    );

    --EK 6/21/18 /*START*/
    create table [#MBICrosswalkPlan]
    (
        [HICN] [varchar](12) not null
      , [MBI] [varchar](11) not null
    )

    declare @MBICrosswalkPlan varchar(2048);

    set @MBICrosswalkPlan = '
				SELECT DISTINCT
					 a.[HICN]
					, a.[MBI]
				FROM [' + @$EnumDbName + '].[ssnri].[MBICrosswalkPlan] a WITH (NOLOCK)
					';


    set @MBICrosswalkPlan = 'INSERT INTO #MBICrosswalkPlan ([HICN],[MBI]) ' + @MBICrosswalkPlan
    exec (@MBICrosswalkPlan);

    update m
    set m.LASTASSIGNEDHICN = m.FINALHICN
    from #RAPHICN_SPR_RAPS_HCC_RANGE m

    update m
    set m.FINALHICN = mbi.MBI
    from #RAPHICN_SPR_RAPS_HCC_RANGE m
        join #MBICrosswalkPlan       mbi
            on m.HICN = mbi.HICN


    --As HICN is joined directly to Member Months which has MBI, insert MBIs into HICN field	
    insert into #RAPHICN_SPR_RAPS_HCC_RANGE
    (
        HICN
      , FINALHICN
      , LASTASSIGNEDHICN
    )
    select MBI  as HICN
         , MBI  as FinalHICN
         , null as LastAssignedHICN
    from #MBICrosswalkPlan               mbi
        join #RAPHICN_SPR_RAPS_HCC_RANGE m
            on m.HICN = mbi.HICN

    --Populate Last Assigned HICN for MBIs	
    update a
    set a.LASTASSIGNEDHICN = case
                                 when not (
                                              len(b.LASTASSIGNEDHICN) = 11
                                              and b.LASTASSIGNEDHICN like '[1-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][0-9]'
                                          ) then
                                     b.LASTASSIGNEDHICN
                             end
    from #RAPHICN_SPR_RAPS_HCC_RANGE     a
        join #RAPHICN_SPR_RAPS_HCC_RANGE b
            on a.HICN = b.FINALHICN
    where b.LASTASSIGNEDHICN is not null

    --Populate Last Assigned HICN for MBIs from MBI Crosswalk if Last Assign HICN is not populated in previous step
    update a
    set a.LASTASSIGNEDHICN = case
                                 when not (
                                              len(b.HICN) = 11
                                              and b.HICN like '[1-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][aAc-hC-Hj-kJ-Km-nM-Np-rP-Rt-yT-Y][0-9][0-9]'
                                          ) then
                                     b.HICN
                             end
    from #RAPHICN_SPR_RAPS_HCC_RANGE a
        join #MBICrosswalkPlan       b
            on a.HICN = b.MBI
    where a.LASTASSIGNEDHICN is not null
    --EK 6/21/18 /*END*/


    if @Debug = 0
    begin
        if (object_id('tempdb.dbo.#ALLALTHICN_SPR_RAPS_HCC_RANGE') is not null)
        begin
            drop table #ALLALTHICN_SPR_RAPS_HCC_RANGE;
        end;

    end;
    if @Debug = 1
    begin
        insert into #processlog
        select @ProcessName
             , @DatabaseName
             , @MasterET
             , @ET
             , convert(char(12), getdate() - @MasterET, 114)
             , '013'
        set @ET = getdate()
    end
    /* Stop processing stored proc if #RAPHICN_SPR_RAPS_HCC_RANGE is empty - TFS: 9716 */
    if
    (
        select count(*) from #RAPHICN_SPR_RAPS_HCC_RANGE
    ) = 0
    begin
        select cast(null as varchar(6))     as [TYPE]
             , cast(null as varchar(4))     as PAYMENT_YEAR
             , cast(null as varchar(4))     as MODEL_YEAR
             , cast(null as smalldatetime)  as PROCESSED_BY_START
             , cast(null as smalldatetime)  as PROCESSED_BY_END
             , cast(null as varchar(1))     as PROCESSED_BY_FLAG
             , cast(null as varchar(5))     as PlanId
             , cast(null as varchar(15))    as HICN
             , cast(null as varchar(5))     as RA_FACTOR_TYPE
             , cast(null as varchar(20))    as RxHCC
             , cast(null as varchar(255))   as HCC_DESCRIPTION
             , cast(null as money)          as RxHCC_FACTOR
             , cast(null as varchar(20))    as HIER_RxHCC
             , cast(null as decimal(20, 4)) as HIER_RxHCC_FACTOR
             , cast(null as decimal(20, 4)) as PRE_ADJSTD_FACTOR
             , cast(null as decimal(20, 4)) as ADJSTD_FINAL_FACTOR
             , cast(null as varchar(50))    as HCC_PROCESSED_PCN
             , cast(null as varchar(50))    as HIER_HCC_PROCESSED_PCN
             , cast(null as int)            as UNQ_CONDITIONS
             , cast(null as int)            as MONTHS_IN_DCP
             , cast(null as int)            as MEMBER_MONTHS
             , cast(null as money)          as BID_AMOUNT
             , cast(null as money)          as ESTIMATED_VALUE
             , cast(null as int)            as ROLLFORWARD_MONTHS
             , cast(null as money)          as ANNUALIZED_ESTIMATED_VALUE
             , cast(null as varchar(3))     as ESRD
             , cast(null as varchar(3))     as HOSP
             , cast(null as varchar(3))     as PBP
             , cast(null as varchar(5))     as SCC
             , cast(null as datetime)       as PROCESSED_PRIORITY_PROCESSED_BY
             , cast(null as datetime)       as PROCESSED_PRIORITY_THRU_DATE
             , cast(null as varchar(20))    as PROCESSED_PRIORITY_DIAG
             , cast(null as varchar(18))    as PROCESSED_PRIORITY_FILEID
             , cast(null as varchar(1))     as PROCESSED_PRIORITY_RAC
             , cast(null as varchar(50))    as PROCESSED_PRIORITY_RAPS_SOURCE_ID
             , cast(null as datetime)       as DOS_PRIORITY_PROCESSED_BY
             , cast(null as datetime)       as DOS_PRIORITY_THRU_DATE
             , cast(null as varchar(50))    as DOS_PRIORITY_PCN
             , cast(null as varchar(20))    as DOS_PRIORITY_DIAG
             , cast(null as varchar(18))    as DOS_PRIORITY_FILEID
             , cast(null as varchar(1))     as DOS_PRIORITY_RAC
             , cast(null as varchar(50))    as RAPS_SOURCE
             , cast(null as varchar(40))    as PROVIDER_ID
             , cast(null as varchar(55))    as PROVIDER_LAST
             , cast(null as varchar(55))    as PROVIDER_FIRST
             , cast(null as varchar(80))    as PROVIDER_GROUP
             , cast(null as varchar(100))   as PROVIDER_ADDRESS
             , cast(null as varchar(30))    as PROVIDER_CITY
             , cast(null as varchar(2))     as PROVIDER_STATE
             , cast(null as varchar(13))    as PROVIDER_ZIP
             , cast(null as varchar(15))    as PROVIDER_PHONE
             , cast(null as varchar(15))    as PROVIDER_FAX
             , cast(null as varchar(55))    as TAX_ID
             , cast(null as varchar(20))    as NPI
             , cast(null as datetime)       as SWEEP_DATE
             , cast(null as datetime)       as POPULATED_DATE;
        /*47772 - Adding Columns to Output*/

        --		RAISERROR('Info: Zero rows returned from [dbo].[vw_Raps_Accepted]', 16, 1) WITH NOWAIT; /*Hotfix 44559*/


        if @Valuation = 1
        begin

            delete m
            from [Valuation].[NewHCCPartD] m
            where m.[PlanId] = @PlanId
                  and m.[ProcessRunId] = @ProcessRunId;

        end;

    end;

    else
    begin
        --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#ALLALTHICN_SPR_RAPS_HCC_RANGE]', 'U') IS NOT NULL DROP TABLE #ALLALTHICN_SPR_RAPS_HCC_RANGE

        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 2', GETDATE()

        /*DETERMINE LIST OF HICNS BASED ON ENROLLMENT*/
        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '014'
            set @ET = getdate()
        end

        create table #HICN_SPR_RAPS_HCC_RANGE
        (
            [Id] int identity(1, 1) primary key
          , [HICN] varchar(15)
          , FINALHICN varchar(15)
          , PAYMSTART datetime
        );

        declare @HICN_SPR_RAPS_HCC_RANGE_SQL varchar(4096);

        if @MEMBER_MONTHS = 0
           and
           (
               select case when year(getdate()) < @PAYMENT_YEAR2 then 0 else 1 end
           ) = 0
        begin

            /*DETERMINE ALL CURRENTLY ACTIVE HICNS WITH PAYMENT FOR FUTURE YEAR */

            if @Debug = 1
            begin
                insert into #processlog
                select @ProcessName
                     , @DatabaseName
                     , @MasterET
                     , @ET
                     , convert(char(12), getdate() - @MasterET, 114)
                     , '015'
                set @ET = getdate()
            end

            set @HICN_SPR_RAPS_HCC_RANGE_SQL
                = '	
								SELECT [HICN] = mmr.[HICN]
								,      [FINALHICN] = alt.[FINALHICN]
								,      [PAYMSTART] = MAX(mmr.[PAYMSTART])
								FROM [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] mmr WITH (NOLOCK)
								JOIN #RAPHICN_SPR_RAPS_HCC_RANGE alt WITH (NOLOCK) 
									   ON mmr.[HICN] = alt.[HICN]
								WHERE mmr.[PAYMSTART]
									=
									(
									SELECT MAX([PAYMSTART])
									FROM [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] WITH (NOLOCK))
								GROUP BY mmr.[HICN]
								,        alt.[FINALHICN]
								HAVING SUM(mmr.[TOTALPAYMENT])
									<>
									0
								------ORDER BY mmr.[HICN], alt.[FINALHICN],MAX(mmr.[PAYMSTART])  --?? Is ORDER BY needed??
								--EK 6/21/18 Join based on FinalHICN which holds MBI
								UNION
								SELECT [HICN] = alt.[HICN]
								,      [FINALHICN] = alt.[FINALHICN]
								,      [PAYMSTART] = MAX(mmr.[PAYMSTART])
								FROM [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] mmr WITH (NOLOCK)
								JOIN #RAPHICN_SPR_RAPS_HCC_RANGE alt WITH (NOLOCK) 
									   ON mmr.[HICN] = alt.[FinalHICN]
								WHERE mmr.[PAYMSTART]
									=
									(
									SELECT MAX([PAYMSTART])
									FROM [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] WITH (NOLOCK))
								GROUP BY alt.[HICN]
								,        alt.[FINALHICN]
								HAVING SUM(mmr.[TOTALPAYMENT])
									<>
									0
								';


            if @Debug = 1
            begin
                insert into #processlog
                select @ProcessName
                     , @DatabaseName
                     , @MasterET
                     , @ET
                     , convert(char(12), getdate() - @MasterET, 114)
                     , '016'
                set @ET = getdate()
            end

            --EK 6/21/18
            set @HICN_SPR_RAPS_HCC_RANGE_SQL
                = 'INSERT INTO #HICN_SPR_RAPS_HCC_RANGE ([HICN],[FINALHICN],[PAYMSTART]) '
                  + @HICN_SPR_RAPS_HCC_RANGE_SQL
            exec (@HICN_SPR_RAPS_HCC_RANGE_SQL);
        end;
        else
        begin

            /*DETERMINE ALL HICNS DURING PAYMENT YEAR WITH PAYMENT*/


            if @Debug = 1
            begin
                insert into #processlog
                select @ProcessName
                     , @DatabaseName
                     , @MasterET
                     , @ET
                     , convert(char(12), getdate() - @MasterET, 114)
                     , '017'
                set @ET = getdate()
            end

            set @HICN_SPR_RAPS_HCC_RANGE_SQL
                = '
						SELECT [HICN] = mmr.[HICN]
						,      [FINALHICN] = alt.[FINALHICN]
						,      [PAYMSTART] = MAX(mmr.[PAYMSTART])
						FROM [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] mmr WITH (NOLOCK)
						JOIN #RAPHICN_SPR_RAPS_HCC_RANGE alt WITH (NOLOCK)
							 ON mmr.HICN
								=
								alt.HICN
						WHERE mmr.PAYMSTART BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2)
                  + ''' 
								AND ''12/31/' + convert(char(4), @PAYMENT_YEAR2)
                  + '''
						GROUP BY mmr.HICN
						,        alt.FINALHICN
						HAVING SUM(mmr.TOTALPAYMENT) <> 0
						------ORDER BY mmr.HICN, alt.FINALHICN, MAX(mmr.PAYMSTART) --?? is ORDER BY needed ??
				--EK 6/21/18 Join based on FinalHICN which holds MBI
						UNION
						SELECT [HICN] = alt.[HICN]
						,      [FINALHICN] = alt.[FINALHICN]
						,      [PAYMSTART] = MAX(mmr.[PAYMSTART])
						FROM [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] mmr WITH (NOLOCK)
						JOIN #RAPHICN_SPR_RAPS_HCC_RANGE alt WITH (NOLOCK)
							 ON mmr.HICN
								=
								alt.FinalHICN
						WHERE mmr.PAYMSTART BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2)
                  + ''' 
								AND ''12/31/' + convert(char(4), @PAYMENT_YEAR2)
                  + '''
						GROUP BY alt.HICN
						,        alt.FINALHICN
						HAVING SUM(mmr.TOTALPAYMENT) <> 0			
			';

            if @Debug = 1
            begin
                insert into #processlog
                select @ProcessName
                     , @DatabaseName
                     , @MasterET
                     , @ET
                     , convert(char(12), getdate() - @MasterET, 114)
                     , '018'
                set @ET = getdate()
            end
            --EK 6/21/18
            set @HICN_SPR_RAPS_HCC_RANGE_SQL
                = 'INSERT INTO #HICN_SPR_RAPS_HCC_RANGE ([HICN],[FINALHICN],[PAYMSTART]) '
                  + @HICN_SPR_RAPS_HCC_RANGE_SQL
            exec (@HICN_SPR_RAPS_HCC_RANGE_SQL);
        end;

        if @Debug = 0
        begin
            if (object_id('tempdb.dbo.#RAPHICN_SPR_RAPS_HCC_RANGE') is not null)
            begin
                drop table #RAPHICN_SPR_RAPS_HCC_RANGE;
            end;
        end;

        create nonclustered index [IX_#HICN_SPR_RAPS_HCC_RANGE__HICN]
        on #HICN_SPR_RAPS_HCC_RANGE (HICN);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '019'
            set @ET = getdate()
        end

        /*PULL CURRENT RAPS DATA*/


        create table #PLANRISK_A_SPR_RAPS_HCC_RANGE
        (
            [Id] int identity(1, 1) primary key
          , HICN varchar(20)
          , [DESCRIPTION] varchar(200)
          , COMM money
          , HCC varchar(20)
          , AGE int
          , PROCESSED_PRIORITY_PCN varchar(40)/*47772 - Adding/Renaming Columns*/
          , DOS_PRIORITY_PCN varchar(40)
          , PROCESSED_PRIORITY_PROCESSED_BY datetime
          , PROCESSED_PRIORITY_THRU_DATE datetime
          , PROCESSED_PRIORITY_DIAG varchar(10)
          , PROCESSED_PRIORITY_RAC varchar(1)
          , PROCESSED_PRIORITY_FILEID varchar(18)
          , PROCESSED_PRIORITY_RAPS_SOURCE_ID varchar(50)
          , DOS_PRIORITY_PROCESSED_BY datetime
          , DOS_PRIORITY_THRU_DATE datetime
          , DOS_PRIORITY_DIAG varchar(20)
          , DOS_PRIORITY_RAC varchar(1)
          , DOS_PRIORITY_FILEID varchar(18)
          , DOS_PRIORITY_RAPS_SOURCE_ID varchar(50)
        );
        if object_id('TEMPDB.DBO.#VW_RAPS_ACCEPTED_RANGE') > 0
            drop table #VW_RAPS_ACCEPTED_RANGE
        create table #VW_RAPS_ACCEPTED_RANGE
        (
            [Id] int identity(1, 1) primary key
          , HICN varchar(20)
          , [DESCRIPTION] varchar(200)
          , COMM money
          , HCC varchar(20)
          , AGE int
          , DIAGNOSIS_CODE varchar(10)
          , CLAIMID varchar(40)
          , PROCESSED_BY_DATE datetime
          , THRU_DATE datetime
          , FILEID varchar(18)
          , RAPS_SOURCE_ID int
          , RAC char(1)
        );

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '020'
            set @ET = getdate()
        end
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 4', GETDATE()
        declare @PLANRISK_TMPA_SPR_RAPS_HCC_RANGE_SQL varchar(4096);

        set @PLANRISK_TMPA_SPR_RAPS_HCC_RANGE_SQL
            = '		
								INSERT  INTO #VW_RAPS_ACCEPTED_RANGE
											(
											 [HICN]
										   , [DESCRIPTION]
										   , [COMM]
										   , [HCC]
										   , [AGE]
										   , [DIAGNOSIS_CODE]
										   , [CLAIMID]
										   , [PROCESSED_BY_DATE]
										   , [THRU_DATE]
										   , FILEID
										   , RAPS_SOURCE_ID
										   , RAC
											)
							SELECT DISTINCT [FINALHICN] = hicns.[FINALHICN]
							,               [DESCRIPTION] = factor.[DESCRIPTION]
							,               [COMM] = 0
							,               [HCC_LABEL] = hcc.[HCC_LABEL]
							,               [AGE] = CAST(NULL AS INT)
							,               [DIAGNOSIS_CODE] = raps.[DIAGNOSISCODE]
							,               [CLAIMID] = raps.[PATIENTCONTROLNUMBER]
							,               [PROCESSED_BY_DATE] = raps.[PROCESSEDBY]
							,               [THRU_DATE] = raps.[THRUDATE]
							,               FILEID = RAPS.FILEID
							,               RAPS_SOURCE_ID = RAPS.SOURCE_ID
							,               RAC = RAPS.RAC
							FROM [' + @$EnumDbName
              + '].[dbo].[VW_RAPS_ACCEPTED] raps WITH (NOLOCK)
							JOIN #HICN_SPR_RAPS_HCC_RANGE hicns 
								ON raps.[HICN] = hicns.[HICN]
							/* JOIN [$(HRPReporting)].[dbo].[LK_DIAGNOSESHCC_PARTD] hcc WITH (NOLOCK) --45817 commented out old logic */
							/*  ON raps.[DIAGNOSISCODE] = hcc.[ICD9] --45817 commented out old logic */
							INNER JOIN #Vw_LkRiskModelsDiagHCC hcc /*45817*/
								ON raps.[DIAGNOSISCODE] = hcc.ICDCode /*45817*/
								AND raps.ThruDate between hcc.StartDate and hcc.EndDate /*45817*/
							JOIN [$(HRPReporting)].[dbo].[LK_FACTORS_PARTD] factor WITH (NOLOCK)
							 ON hcc.[HCC_LABEL] = factor.[HCC_LABEL]
							WHERE hcc.[PAYMENT_YEAR] = ''' + @PAYMENT_YEAR2
              + '''
								AND factor.[PAYMENT_YEAR] = ''' + @PAYMENT_YEAR2
              + '''
								AND raps.[THRUDATE] BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2 - 1)
              + ''' 
								   AND ''12/31/' + convert(char(4), +@PAYMENT_YEAR2 - 1) + '''
										';

        /*39761 - 
			1. Change lookup tables to associate new ones
			2. Removing ProcessedBy filter on RAPS diagnoses gathering
				 /*filters*/
				AND raps.[PROCESSEDBY] BETWEEN ''' + CONVERT(CHAR(10), @PROCESSBY_START2, 101)
								+ '''
				AND ''' + CONVERT(CHAR(10), @PROCESSBY_END2, 101) + '''
					*/


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '021'
            set @ET = getdate()
        end


        exec (@PLANRISK_TMPA_SPR_RAPS_HCC_RANGE_SQL);


        create nonclustered index IDX_PLANRISK_TMPA_SPR_RAPS_HCC_RANGE
        on #VW_RAPS_ACCEPTED_RANGE
        (
            [HICN]
          , [HCC]
        );


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '022'
            set @ET = getdate()
        end

        declare @PLANRISK_TMPA_SPR_RAPS_HCC_RANGE_SQL02 varchar(5120);

        /*MC Notes: should LEFT JOIN #VW_RAPS_ACCEPTED_RANGE be just a JOIN??? */
        set @PLANRISK_TMPA_SPR_RAPS_HCC_RANGE_SQL02
            = '	
									INSERT  INTO #VW_RAPS_ACCEPTED_RANGE
											(
											 [HICN]
										   , [DESCRIPTION]
										   , [COMM]
										   , [HCC]
										   , [AGE]
										   , [DIAGNOSIS_CODE]
										   , [CLAIMID]
										   , [PROCESSED_BY_DATE]
										   , [THRU_DATE]
										   , FILEID
										   , RAPS_SOURCE_ID
										   , RAC
											)
							
							--EK 6/21/18 Existing Bug. Change HICN to FINALHICN
							SELECT DISTINCT [HICN] = hicns.[FINALHICN]
							,               [DESCRIPTION] = factor.[DESCRIPTION]
							,               [COMM] = 0
							,               [HCC] = hcc.[HCC_LABEL]
							,               [AGE] = CAST(NULL AS INT)
							,               [DIAGNOSIS_CODE] = raps.[DIAGNOSISCODE]
							,               [CLAIMID] = raps.[PATIENTCONTROLNUMBER]
							,               [PROCESSED_BY_DATE] = raps.[PROCESSEDBY]
							,               [THRU_DATE] = raps.[THRUDATE]
							,               FILEID = RAPS.FILEID
							,               RAPS_SOURCE_ID = RAPS.SOURCE_ID
							,               RAC = RAPS.RAC
							FROM      [' + @$EnumDbName
              + '].[dbo].[VW_XPLAN_ACCEPTED_RAPS_DIAGS] raps WITH (NOLOCK)
							/* JOIN      [$(HRPReporting)].[dbo].[LK_RISK_MODELS_DIAGHCC] hcc WITH (NOLOCK) --45817 Commenting out old logic */
									/* ON raps.[DIAGNOSISCODE] = hcc.[ICD9] -- 45817 Commenting out old logic */
							--EK 6/21/18 Join in order to get Final HICN (MBI)
							JOIN #HICN_SPR_RAPS_HCC_RANGE hicns 
								ON raps.[HICN] = hicns.[HICN]
							INNER JOIN 	#Vw_LkRiskModelsDiagHCC hcc
								ON raps.[DIAGNOSISCODE] = hcc.ICDCode
								AND raps.ThruDate between hcc.StartDate and hcc.EndDate								
							LEFT JOIN #VW_RAPS_ACCEPTED_RANGE current_raps   
									ON raps.[HICN] = current_raps.[HICN]
									AND hcc.[HCC_LABEL] = current_raps.[HCC]
							JOIN [$(HRPReporting)].[dbo].[LK_FACTORS_PARTD] factor WITH (NOLOCK)
							        ON hcc.[HCC_LABEL] = factor.[HCC_LABEL]
							WHERE hcc.[PAYMENT_YEAR] = ''' + @PAYMENT_YEAR2
              + '''
								AND factor.[PAYMENT_YEAR] = ''' + @PAYMENT_YEAR2
              + '''
								AND raps.[THRUDATE] BETWEEN ''01/01/' + convert(char(4), @PAYMENT_YEAR2 - 1)
              + '''
								AND ''12/31/' + convert(char(4), @PAYMENT_YEAR2 - 1)
              + '''
								AND current_raps.[HICN] IS NULL
								--AND EXISTS (
								--SELECT [HICN]
								--FROM #HICN_SPR_RAPS_HCC_RANGE hicns
								--WHERE raps.[HICN] = hicns.[HICN]
								--)
								
					';

        /*39761 
1. Associate latest Look up tables
2. Removing ProcessedBy filter on RAPS diagnoses gathering
/*filters*/
			AND raps.[PROCESSEDBY] BETWEEN '''
                    + CONVERT(CHAR(10), @PROCESSBY_START2, 101) + '''
			AND ''' + CONVERT(CHAR(10), @PROCESSBY_END2, 101) + '''
*/

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '023'
            set @ET = getdate()
        end


        exec (@PLANRISK_TMPA_SPR_RAPS_HCC_RANGE_SQL02);


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '024'
            set @ET = getdate()
        end

        -- Split logic based on parameter for earliest Processed By or Date of Service
        --  IF @PRIORITY2 = 'P'
        begin

            insert into #PLANRISK_A_SPR_RAPS_HCC_RANGE
            (
                HICN
              , [DESCRIPTION]
              , COMM
              , HCC
              , AGE
              , PROCESSED_PRIORITY_PCN
              , DOS_PRIORITY_PCN
              , PROCESSED_PRIORITY_PROCESSED_BY
              , PROCESSED_PRIORITY_THRU_DATE
              , PROCESSED_PRIORITY_DIAG
              , PROCESSED_PRIORITY_RAC
              , PROCESSED_PRIORITY_FILEID
              , PROCESSED_PRIORITY_RAPS_SOURCE_ID
              , DOS_PRIORITY_PROCESSED_BY
              , DOS_PRIORITY_THRU_DATE
              , DOS_PRIORITY_DIAG
              , DOS_PRIORITY_RAC
              , DOS_PRIORITY_FILEID
              , DOS_PRIORITY_RAPS_SOURCE_ID
            )
            select HICN
                 , [DESCRIPTION]
                 , COMM
                 , HCC
                 , AGE
                 , null                   as PROCESSED_PRIORITY_PCN
                 , null                   as DOS_PRIORITY_PCN
                 , min(PROCESSED_BY_DATE) as PROCESSED_PRIORITY_PROCESSED_BY
                 , null                   as PROCESSED_PRIORITY_THRU_DATE
                 , null                   as PROCESSED_PRIORITY_DIAG
                 , null                   as PROCESSED_PRIORITY_RAC
                 , null                   as PROCESSED_PRIORITY_FILEID
                 , null                   as PROCESSED_PRIORITY_RAPS_SOURCE_ID
                 , null                   as DOS_PRIORITY_PROCESSED_BY
                 , min(THRU_DATE)         as DOS_PRIORITY_THRU_DATE
                 , null                   as DOS_PRIORITY_DIAG --/*47772*/
                 , null                   as DOS_PRIORITY_RAC
                 , null                   as DOS_PRIORITY_FILEID
                 , null                   as DOS_PRIORITY_RAPS_SOURCE_ID
            from #VW_RAPS_ACCEPTED_RANGE
            group by HICN
                   , [DESCRIPTION]
                   , COMM
                   , HCC
                   , AGE;

            create nonclustered index [IX_#PLANRISK_A_SPR_RAPS_HCC_RANGE__HICN__HCC]
            on #PLANRISK_A_SPR_RAPS_HCC_RANGE
            (
                [HICN]
              , [HCC]
            );
        end

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '025'
            set @ET = getdate()
        end
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 5', GETDATE()
        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set PROCESSED_PRIORITY_THRU_DATE =
            (/* 47772 - PROCESSED_PRIORITY_THRU_DATE*/
                select min(THRU_DATE)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      --AND #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_BY_DATE = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
            );


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '026'
            set @ET = getdate()
        end


        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set PROCESSED_PRIORITY_PCN =
            (
                select min(CLAIMID)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_THRU_DATE = TMPA.THRU_DATE
            );

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '027'
            set @ET = getdate()
        end

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set PROCESSED_PRIORITY_DIAG =
            (
                select min(DIAGNOSIS_CODE)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PCN = TMPA.CLAIMID
            );


        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set PROCESSED_PRIORITY_FILEID =
            (
                select min(FILEID)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PCN = TMPA.CLAIMID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_DIAG = TMPA.DIAGNOSIS_CODE
            );

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set PROCESSED_PRIORITY_RAPS_SOURCE_ID =
            (
                select min(RAPS_SOURCE_ID)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PCN = TMPA.CLAIMID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_DIAG = TMPA.DIAGNOSIS_CODE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_FILEID = TMPA.FILEID
            );

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set PROCESSED_PRIORITY_RAC =
            (
                select min(RAC)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_PCN = TMPA.CLAIMID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_DIAG = TMPA.DIAGNOSIS_CODE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_FILEID = TMPA.FILEID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.PROCESSED_PRIORITY_RAPS_SOURCE_ID = TMPA.RAPS_SOURCE_ID
            );



        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '028'
            set @ET = getdate()
        end



        ----                  END;
        ----              ELSE
        --BEGIN

        --INSERT  INTO #PLANRISK_A_SPR_RAPS_HCC_RANGE
        --SELECT
        --    HICN
        --  , [DESCRIPTION]
        --  , COMM
        --  , HCC
        --  , AGE
        --  , NULL
        --  , NULL
        --  , NULL
        --  , MIN(THRU_DATE)
        --FROM
        --    #VW_RAPS_ACCEPTED_RANGE
        --GROUP BY
        --    HICN
        --  , [DESCRIPTION]
        --  , COMM
        --  , HCC
        --  , AGE;

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '029'
            set @ET = getdate()
        end


        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 5', GETDATE()
        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set DOS_PRIORITY_PROCESSED_BY =
            (/* 47772 - DOS_PRIORITY_PROCESSED_BY*/
                select min(PROCESSED_BY_DATE)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_THRU_DATE = TMPA.THRU_DATE
            );

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '030'
            set @ET = getdate()
        end

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set DOS_PRIORITY_PCN =
            ( --DOS_PRIORITY_PCN
                select min(CLAIMID)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_THRU_DATE = TMPA.THRU_DATE
            );
        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '031'
            set @ET = getdate()
        end


        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set DOS_PRIORITY_DIAG =
            (
                select min(DIAGNOSIS_CODE)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PCN = TMPA.CLAIMID
            );




        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set DOS_PRIORITY_FILEID =
            (
                select min(FILEID)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PCN = TMPA.CLAIMID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_DIAG = TMPA.DIAGNOSIS_CODE
            );

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set DOS_PRIORITY_RAPS_SOURCE_ID =
            (
                select min(RAPS_SOURCE_ID)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PCN = TMPA.CLAIMID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_DIAG = TMPA.DIAGNOSIS_CODE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_FILEID = TMPA.FILEID
            );

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set DOS_PRIORITY_RAC =
            (
                select min(RAC)
                from #VW_RAPS_ACCEPTED_RANGE TMPA
                where #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = TMPA.HICN
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.HCC = TMPA.HCC
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PROCESSED_BY = TMPA.PROCESSED_BY_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_THRU_DATE = TMPA.THRU_DATE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_PCN = TMPA.CLAIMID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_DIAG = TMPA.DIAGNOSIS_CODE
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_FILEID = TMPA.FILEID
                      and #PLANRISK_A_SPR_RAPS_HCC_RANGE.DOS_PRIORITY_RAPS_SOURCE_ID = TMPA.RAPS_SOURCE_ID
            );



        ----                  END; /*47772*/
        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '032'
            set @ET = getdate()
        end

        if @Debug = 0
        begin
            if (object_id('tempdb.dbo.#VW_RAPS_ACCEPTED_RANGE') is not null)
            begin
                drop table #VW_RAPS_ACCEPTED_RANGE;
            end;
        end;

        --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#VW_RAPS_ACCEPTED_RANGE]', 'U') IS NOT NULL DROP TABLE #VW_RAPS_ACCEPTED_RANGE


        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 6', GETDATE()


        /*PULLS ALL DEMOGRAPHIC AND OTHER INFORMATION FOR THE POPULATION*/


        create table #POPUL_SPR_RAPS_HCC_RANGE
        (
            DATE_FOR_FACTORS datetime
          , HICN varchar(15)
          , AGE varchar(8)
          , SEX varchar(2)
          , MEDICAID varchar(2)
          , ORIG_DISAB varchar(2)
          , RA_FACTOR_TYPE_ varchar(5)
          , MAX_MOR varchar(8)
          , MID_YEAR_UPDATE_FLAG varchar(1)
          , AGEGROUPID varchar(4)
          , GENDERID varchar(1)
          , LI varchar(1)
        );


        create clustered index IDX_POPUL_SPR_RAPS_HCC_RANGE_HICN
        on #POPUL_SPR_RAPS_HCC_RANGE (HICN);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '033'
            set @ET = getdate()
        end


        if (object_id('tempdb.dbo.#hicn_list') is not null)
        begin
            drop table #hicn_list;
        end;

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '034'
            set @ET = getdate()
        end

        --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#hicn_list]', 'U') IS NOT NULL DROP TABLE #hicn_list
        select HICN.HICN
             , HICN.FINALHICN
             , HICN.PAYMSTART
        into #hicn_list
        from #HICN_SPR_RAPS_HCC_RANGE HICN
        group by HICN.HICN
               , HICN.FINALHICN
               , HICN.PAYMSTART;

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '035'
            set @ET = getdate()
        end

        declare @POPUL_SPR_RAPS_HCC_RANGE_SQL varchar(4096);

        /*ADDS INFORMATION FROM TBL_MEMBER_MONTHS FOR POPULATION*/
        set @POPUL_SPR_RAPS_HCC_RANGE_SQL
            = '
							SELECT [DATE_FOR_FACTORS] = MAX(mmr.[PAYMSTART])
							,      [HICN] = hicn_list.[FINALHICN]
							,      [AGE] = DATEDIFF(YY, mmr.[DOB], mmr.[PAYMSTART])
							,      [SEX] = mmr.[SEX]
							,      [MEDICAID] = mmr.[MEDICADDON]
							,      [ORIG_DISAB] = mmr.[OREC]
							,      [RA_FACTOR_TYPE_] = CASE 
										WHEN ''' + @PAYMENT_YEAR
              + ''' >= ''2011''   
										   THEN mmr.[Part_D_RA_Factor_Type]
										ELSE mmr.[RA_FACTOR_TYPE] 
										END
							,      [MAX_MOR] = ''''
							,      [MID_YEAR_UPDATE_FLAG] = ''''
							,      [AGEGROUPID] = mmr.[RskAdjAgeGrp]
							,      [GENDERID] = ''''
							,      [LI] = mmr.[Part_D_Low_Income_Indicator]                
							FROM [' + @$EnumDbName
              + '].[dbo].[TBL_MEMBER_MONTHS] mmr WITH (NOLOCK)
							JOIN #hicn_list  hicn_list   
								 ON mmr.[HICN] = hicn_list.[HICN]
									AND mmr.[PAYMSTART]	= hicn_list.[PAYMSTART]
							GROUP BY hicn_list.[FINALHICN]
							,        DATEDIFF(YY, mmr.[DOB], mmr.[PAYMSTART])
							,        mmr.[SEX]
							,        mmr.[MEDICADDON]
							,        mmr.[OREC]
							,        CASE WHEN ''' + @PAYMENT_YEAR
              + ''' >= ''2011''
										   THEN mmr.[Part_D_RA_Factor_Type]
										   ELSE mmr.[RA_FACTOR_TYPE]
										   END
							,        mmr.[RskAdjAgeGrp]
							,   	 mmr.Part_D_Low_Income_Indicator
							------ORDER BY hicn_list.[FINALHICN]	--?? is ORDER BY needed ??--
							';
        set @POPUL_SPR_RAPS_HCC_RANGE_SQL
            = 'INSERT INTO #POPUL_SPR_RAPS_HCC_RANGE ('
              + '[DATE_FOR_FACTORS],[HICN],[AGE],[SEX],[MEDICAID],[ORIG_DISAB]'
              + ',[RA_FACTOR_TYPE_],[MAX_MOR],[MID_YEAR_UPDATE_FLAG],[AGEGROUPID]' + ',[GENDERID],[LI]) '
              + @POPUL_SPR_RAPS_HCC_RANGE_SQL
        exec (@POPUL_SPR_RAPS_HCC_RANGE_SQL);

        update #POPUL_SPR_RAPS_HCC_RANGE
        set LI = 0
        where LI = 'N'

        update #POPUL_SPR_RAPS_HCC_RANGE
        set LI = 1
        where LI = 'Y'

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '036'
            set @ET = getdate()
        end

        if @Debug = 0
        begin
            if (object_id('tempdb.dbo.#hicn_list') is not null)
            begin
                drop table #hicn_list;
            end;
        end;

        ----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 7', GETDATE()

        /*UPDATE TABLE FOR ALL MEMBERS THAT HAD AN MID YEAR UPDATE ADJ REASON OF 26 OR 41*/


        /* 39761: 
1. Change for Part D Total Payment => mmr.[TOTAL_PART_D_PAYMENT] <> 
2. @Paymonth_MMR - Dynamically set the Hardcoded values*/
        declare @popul_SQL varchar(2048);

        set @popul_SQL
            = '
					UPDATE  popul
					SET	   popul.MID_YEAR_UPDATE_FLAG = ''Y''
					FROM	   #POPUL_SPR_RAPS_HCC_RANGE popul      
					JOIN	   [' + @$EnumDbName
              + '].[dbo].[TBL_MMR] mmr 
						   ON mmr.[HICN] = popul.[HICN]
					JOIN	   #HICN_SPR_RAPS_HCC_RANGE  hicns       
						   ON mmr.[HICN] = hicns.[HICN]
					WHERE mmr.[ADJREASON] IN(''41'', ''26'')
						AND mmr.[TOTAL_PART_D_PAYMENT] <> 0
						AND mmr.[PaymStart] >= CAST(''01/01/' + @PAYMENT_YEAR2
              + ''' AS SMALLDATETIME)
						AND mmr.[PaymStart] <=  CAST(''' + @Paymonth_MMR + '/31/' + @PAYMENT_YEAR2
              + ''' AS SMALLDATETIME)
					';


        exec (@popul_SQL);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '037'
            set @ET = getdate()
        end

        /*SET THE THE MAX_MOR TO YYYY07 FOR MEMBERS THAT HAD A MID YEAR UPDATE*/
        declare @popul02_SQL varchar(2048);

        ---Start #43224  Change 07 to 08 for 2015 PY
        set @popul02_SQL
            = '
						UPDATE popul
						SET	 popul.MAX_MOR = ''' + @PAYMENT_YEAR2 + @Paymonth_MOR
              + ''' 
						FROM  #POPUL_SPR_RAPS_HCC_RANGE popul      
						JOIN [' + @$EnumDbName
              + '].[dbo].[TBL_MORD] mor
							 ON MOR.HICN = POPUL.HICN
						JOIN #HICN_SPR_RAPS_HCC_RANGE hicns       
							 ON mor.[HICN] = hicns.[HICN]
						WHERE popul.[MID_YEAR_UPDATE_FLAG] = ''Y''
							AND mor.[PAYMO] = ''' + @PAYMENT_YEAR2 + @Paymonth_MOR + '''
				';
        --end #43224

        exec (@popul02_SQL);


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '038'
            set @ET = getdate()
        end

        /*SET THE MAX_MOR FOR MEMBERS THAT DID NOT HAVE A MID YEAR UPDATE*/

        declare @POPUL_SPR_RAPS_HCC_RANGE02_SQL varchar(2048);

        --start #43224 Change 07 to 08 for 2015 PY with variable
        set @POPUL_SPR_RAPS_HCC_RANGE02_SQL
            = '
								UPDATE #POPUL_SPR_RAPS_HCC_RANGE
								SET	   [MAX_MOR] = (SELECT MAX([PAYMO])
								FROM       [' + @$EnumDbName
              + '].[dbo].TBL_MORD mor
								JOIN #HICN_SPR_RAPS_HCC_RANGE hicns
									ON mor.[HICN] = hicns.[HICN]
								WHERE #POPUL_SPR_RAPS_HCC_RANGE.HICN = hicns.[FINALHICN]
									AND mor.[PAYMO] LIKE ''' + @PAYMENT_YEAR2
              + '%'')
								WHERE #POPUL_SPR_RAPS_HCC_RANGE.MID_YEAR_UPDATE_FLAG <> ''Y''
									AND #POPUL_SPR_RAPS_HCC_RANGE.MAX_MOR <> ''' + @PAYMENT_YEAR2 + @Paymonth_MOR
              + '''
								';

        --End #43224
        exec (@POPUL_SPR_RAPS_HCC_RANGE02_SQL);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '039'
            set @ET = getdate()
        end

        /*SET THE MAX_MOR TO THE MAX PAYMONTH IF GREATER THAN PREVIOUSLY SET VALUE*/
        declare @popul03_SQL varchar(2048);

        set @popul03_SQL
            = '
										UPDATE popul
										SET popul.[MAX_MOR] = mor_list.[PAYMONTH]
										FROM #POPUL_SPR_RAPS_HCC_RANGE   popul   
										JOIN (SELECT hicns.[FINALHICN]
											,       [PAYMONTH] = MAX(mor.[PAYMO])
											FROM [' + @$EnumDbName
              + '].[dbo].[TBL_MORD] mor 
											JOIN #HICN_SPR_RAPS_HCC_RANGE hicns 
											   ON mor.[HICN] = hicns.[HICN]
											   AND LEFT(mor.[PayMo], 4) = ''' + @PAYMENT_YEAR2
              + '''--kp bug 3798
											GROUP BY hicns.[FINALHICN]) mor_list 
												  ON popul.[HICN] = mor_list.[FINALHICN]
										WHERE mor_list.[PAYMONTH] > popul.[MAX_MOR]
										';

        exec (@popul03_SQL);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '040'
            set @ET = getdate()
        end

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 8', GETDATE()
        /*ADDS OREC FLAGS FROM THE MOR DATA*/
        declare @POPUL_SPR_RAPS_HCC_RANGE03_SQL varchar(2048);

        set @POPUL_SPR_RAPS_HCC_RANGE03_SQL
            = '
							UPDATE #POPUL_SPR_RAPS_HCC_RANGE
							SET [ORIG_DISAB] = 1
							FROM [' + @$EnumDbName
              + '].[dbo].[MORD] mor
							JOIN #HICN_SPR_RAPS_HCC_RANGE hicns       
								   ON mor.[HICN] = hicns.[HICN]
							WHERE #POPUL_SPR_RAPS_HCC_RANGE.[HICN] = hicns.[FINALHICN]
								AND mor.[PAYMO] = #POPUL_SPR_RAPS_HCC_RANGE.[MAX_MOR]
								AND (mor.[OriginallyDisabledMale] = ''1''
								OR mor.[OriginallyDisabledFeMale] = ''1'')
								AND #POPUL_SPR_RAPS_HCC_RANGE.[ORIG_DISAB] <> ''1''
							';

        exec (@POPUL_SPR_RAPS_HCC_RANGE03_SQL);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '041'
            set @ET = getdate()
        end

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 9', GETDATE()
        /*CONVERTED THE AGEGROUPID TO HRP STANDARDS*/
        update popul
        set popul.AGEGROUPID = AGE.AGEGROUPID
        from #POPUL_SPR_RAPS_HCC_RANGE         popul
            join [$(HRPReporting)].dbo.lk_AgeGroups AGE
                on popul.AGEGROUPID = AGE.[Description];
        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '042'
            set @ET = getdate()
        end
        /*CONVERETS MALE/FEMALE TO HRP STANDARDS 1/2*/
        update #POPUL_SPR_RAPS_HCC_RANGE
        set GENDERID = case
                           when SEX = 'M' then
                               '1'
                           when SEX = 'F' then
                               '2'
                       end;

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '043'
            set @ET = getdate()
        end

        /*UPDATE ORIG_DISABLED TO HRP STANDARD OF VALUE 3*/
        update #POPUL_SPR_RAPS_HCC_RANGE
        set ORIG_DISAB = case
                             when ORIG_DISAB = '1'
                                  and AGEGROUPID >= 6 then
                                 '3'
                             when ORIG_DISAB <> '3' then
                                 ' '
                         end;
        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '044'
            set @ET = getdate()
        end
        /*SET MEDICAID TO HRP STANDARD OF MEDICAID UNDER 65 TO 2 AND MEDICAID OVER 65 TO 1*/

        update #POPUL_SPR_RAPS_HCC_RANGE
        set MEDICAID = case
                           when MEDICAID = 'Y'
                                and AGEGROUPID >= 6 then
                               '1'
                           when MEDICAID = 'Y'
                                and AGEGROUPID <= 5 then
                               '2'
                       end;

        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 10', GETDATE()

        /*CREATE TABLE TO BUILD THE PLAN RISK SCORE*/

        create table #PLANRISK_SPR_RAPS_HCC_RANGE
        (
            HICN varchar(15)
          , DESCR varchar(75)
          , COMM decimal(10, 3)
          , HCC varchar(25)
          , AGE varchar(10)
        );

        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 11', GETDATE()
        /*ADD PLAN RISK SCORE TO CURRENT RAPS*/
        insert into #PLANRISK_A_SPR_RAPS_HCC_RANGE
        (
            HICN
          , [DESCRIPTION]
          , COMM
          , HCC
          , AGE
          , PROCESSED_PRIORITY_PCN
          , DOS_PRIORITY_PCN
          , PROCESSED_PRIORITY_PROCESSED_BY
          , PROCESSED_PRIORITY_THRU_DATE
          , PROCESSED_PRIORITY_DIAG
          , PROCESSED_PRIORITY_RAC
          , PROCESSED_PRIORITY_FILEID
          , PROCESSED_PRIORITY_RAPS_SOURCE_ID
          , DOS_PRIORITY_PROCESSED_BY
          , DOS_PRIORITY_THRU_DATE
          , DOS_PRIORITY_DIAG
          , DOS_PRIORITY_RAC
          , DOS_PRIORITY_FILEID
          , DOS_PRIORITY_RAPS_SOURCE_ID
        )
        select distinct
            HICN
          , DESCR
          , COMM
          , HCC
          , AGE
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
        from #PLANRISK_SPR_RAPS_HCC_RANGE;

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '045'
            set @ET = getdate()
        end
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 12', GETDATE()

        /*PULL CURRENT MOR DATA*/
        create table #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE
        (
            [Id] int identity(1, 1) primary key
          , HICN varchar(20)
          , [DESCRIPTION] varchar(200)
          , COMM money
          , HCC varchar(20)
          , PAYMONTH varchar(8)
        );

        /*ADD MOR DATA TO CURRENT RAPS*/
        declare @PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE_SQL varchar(2048);

        --strat #43224 change 07 to 08 for 2015 PY
        set @PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE_SQL
            = '
								INSERT  INTO #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE
										(
										 [HICN]
									   , [DESCRIPTION]
									   , [COMM]
									   , [HCC]
									   , [PAYMONTH]
										)

								SELECT hicns.[FINALHICN]
								,      mor.[DESCRIPTION]
								,      mor.[COMM]
								,      [HCC_LABEL] = mor.[NAME]
								,      MAX(mor.[Payment_Month])
								FROM       [' + @$EnumDbName
              + '].[dbo].[VW_CONVERTED_MORD_DATA] mor WITH (NOLOCK)
								JOIN #HICN_SPR_RAPS_HCC_RANGE hicns       
									ON mor.[HICN] = hicns.[HICN]
								WHERE mor.[Payment_Month] 
									   BETWEEN ''' + @PAYMENT_YEAR2 + @Paymonth_MOR + ''' AND ''' + @PAYMENT_YEAR2
              + '99''
								GROUP BY hicns.[FINALHICN]
								,        mor.[DESCRIPTION]
								,        mor.[COMM]
								,        mor.[NAME]
								';

        --End #43224
        exec (@PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE_SQL);

        create nonclustered index [IX_#PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE__HICN__HCC]
        on #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE
        (
            [HICN]
          , [HCC]
        );


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '046'
            set @ET = getdate()
        end
        insert into #PLANRISK_A_SPR_RAPS_HCC_RANGE
        (
            HICN
          , [DESCRIPTION]
          , COMM
          , HCC
          , AGE
          , PROCESSED_PRIORITY_PCN
          , DOS_PRIORITY_PCN
          , PROCESSED_PRIORITY_PROCESSED_BY /*47772*/
          , PROCESSED_PRIORITY_THRU_DATE
          , PROCESSED_PRIORITY_DIAG
          , PROCESSED_PRIORITY_RAC
          , PROCESSED_PRIORITY_FILEID
          , PROCESSED_PRIORITY_RAPS_SOURCE_ID
          , DOS_PRIORITY_PROCESSED_BY
          , DOS_PRIORITY_THRU_DATE
          , DOS_PRIORITY_DIAG
          , DOS_PRIORITY_RAC
          , DOS_PRIORITY_FILEID
          , DOS_PRIORITY_RAPS_SOURCE_ID
        )
        select distinct
            MOR.HICN
          , MOR.[DESCRIPTION]
          , MOR.COMM
          , MOR.HCC
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
        from #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE      MOR
            join #POPUL_SPR_RAPS_HCC_RANGE           POPUL
                on MOR.HICN = POPUL.HICN
                   and MOR.PAYMONTH = POPUL.MAX_MOR
            left join #PLANRISK_A_SPR_RAPS_HCC_RANGE HCC
                on MOR.HICN = HCC.HICN
                   and MOR.HCC = HCC.HCC
        where HCC.HICN is null
              and HCC.HCC is null;

        --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE]', 'U') IS NOT NULL DROP TABLE #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE
        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 13', GETDATE()

        ----IF @Debug = 0
        ----BEGIN
        ----	IF (OBJECT_ID('tempdb.dbo.#PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE') IS NOT NULL)
        ----	BEGIN
        ----		DROP TABLE #PLANRISK_MOR_A_SPR_RAPS_HCC_RANGE;
        ----	END;
        ----END;

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '047'
            set @ET = getdate()
        end

        /*UPDATE AGE FOR MEMBERS WITH HCCS*/

        update #PLANRISK_A_SPR_RAPS_HCC_RANGE
        set AGE =
            (
                select max(POPUL.AGEGROUPID)
                from #POPUL_SPR_RAPS_HCC_RANGE POPUL
                where POPUL.HICN = #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN
            );

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '048'
            set @ET = getdate()
        end


        /*UPDATE COMM FOR MEMBERS WITH HCCS*/
        -- JTS ADDED

        -- Ticket # 25628 Start

        update HCC
        set HCC.COMM = FACTORS.Factor
        from #PLANRISK_A_SPR_RAPS_HCC_RANGE            HCC
            inner join #POPUL_SPR_RAPS_HCC_RANGE       POPUL
                on HCC.HICN = POPUL.HICN
            inner join [$(HRPReporting)].dbo.lk_Risk_Models FACTORS
                on substring(HCC.HCC, 1, 3) = 'HCC'
                   and substring(FACTORS.Factor_Description, 1, 3) = 'HCC'
                   and cast(substring(HCC.HCC, 4, len(HCC.HCC) - 3) as int) = cast(substring(
                                                                                                FACTORS.Factor_Description
                                                                                              , 4
                                                                                              , len(FACTORS.Factor_Description)
                                                                                                - 3
                                                                                            ) as int)
                   and POPUL.RA_FACTOR_TYPE_ = FACTORS.Factor_Type
                   and FACTORS.Part_C_D_Flag = 'D'
                   and FACTORS.OREC = case
                                          when POPUL.AGEGROUPID > 6 then
                                              0
                                          when POPUL.AGEGROUPID <= 6 then
                                              1
                                      end
                   and POPUL.LI = FACTORS.LI
                   and FACTORS.Payment_Year = @PAYMENT_YEAR;
        -- Ticket # 25628 End	


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '049'
            set @ET = getdate()
        end
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 14', GETDATE()

        /*ADD DISABILITY INTERATION FOR DISABLED*OPPORTUNISTIC INFECTIONS*/

        -- Ticket # 25628 Start

        insert #PLANRISK_A_SPR_RAPS_HCC_RANGE
        (
            HICN
          , [DESCRIPTION]
          , COMM
          , HCC
          , AGE
          , PROCESSED_PRIORITY_PCN
          , DOS_PRIORITY_PCN
          , PROCESSED_PRIORITY_PROCESSED_BY /*47772*/
          , PROCESSED_PRIORITY_THRU_DATE
          , PROCESSED_PRIORITY_DIAG
          , PROCESSED_PRIORITY_RAC
          , PROCESSED_PRIORITY_FILEID
          , PROCESSED_PRIORITY_RAPS_SOURCE_ID
          , DOS_PRIORITY_PROCESSED_BY
          , DOS_PRIORITY_THRU_DATE
          , DOS_PRIORITY_DIAG
          , DOS_PRIORITY_RAC
          , DOS_PRIORITY_FILEID
          , DOS_PRIORITY_RAPS_SOURCE_ID
        )
        select #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN
             , 'DISABILITY INTERACT'
             , z.Factor
             , z.Factor_Description
             , #PLANRISK_A_SPR_RAPS_HCC_RANGE.AGE
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
             , null
        from #PLANRISK_A_SPR_RAPS_HCC_RANGE
            inner join #POPUL_SPR_RAPS_HCC_RANGE       d
                on #PLANRISK_A_SPR_RAPS_HCC_RANGE.HICN = d.HICN
            inner join [$(HRPReporting)].dbo.lk_risk_models z
                on d.LI = z.LI
        where HCC like 'HCC%'
              and #PLANRISK_A_SPR_RAPS_HCC_RANGE.AGE < 6
              and z.Factor_Description like 'D-%'
              and z.Part_C_D_Flag = 'D'
              and d.RA_FACTOR_TYPE_ = z.Factor_Type
              and z.OREC = case
                               when d.AGEGROUPID > 6 then
                                   0
                               when d.AGEGROUPID <= 6 then
                                   1
                           end
              and z.Payment_Year = @PAYMENT_YEAR



        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '050'
            set @ET = getdate()
        end
        ----IF @Debug = 0
        ----                BEGIN 
        ----                    IF (OBJECT_ID('tempdb.dbo.#PLANRISK_SPR_RAPS_HCC_RANGE') IS NOT NULL)
        ----                        BEGIN 
        ----                            DROP TABLE #PLANRISK_SPR_RAPS_HCC_RANGE;
        ----                        END; 
        ----                END;


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '051'
            set @ET = getdate()
        end
        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 25', GETDATE()

        /*PULL DEMOGRAPHIC DATA FOR ALL FACTOR TYPES*/

        create table #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE
        (
            HICN varchar(15)
          , PAYMSTART smalldatetime
          , ESRD varchar(3)
          , HOSP varchar(3)
          , PBP varchar(3)
          , SCC varchar(5)
        );


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '052'
            set @ET = getdate()
        end
        declare @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE_SQL varchar(2048);

        set @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE_SQL
            = '
								SELECT [HICN] = hicn.[FINALHICN]
								,      [PAYMSTART] = MAX(mmr.[PAYMSTART])
								,      [ESRD] = MAX(mmr.[ESRD])
								,      [HOSP] = MAX(mmr.[HOSP])
								,      [PBP] = NULL
								,      [SCC] = NULL
								FROM       [' + @$EnumDbName
              + '].[dbo].[TBL_MEMBER_MONTHS] mmr WITH (NOLOCK)
								 JOIN #HICN_SPR_RAPS_HCC_RANGE hicn        
									 ON mmr.[HICN] = hicn.[HICN]
								WHERE mmr.[PAYMSTART] BETWEEN ''' + convert(char(10), @PAYMSTART, 101) + ''' AND '''
              + convert(char(10), @PAYMEND, 101) + '''
								GROUP BY hicn.[FINALHICN]
						';
        set @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE_SQL
            = 'INSERT INTO #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE ([HICN],[PAYMSTART],[ESRD],[HOSP],[PBP],[SCC]) '
              + @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE_SQL
        exec (@PLANRISK_DEMO_SPR_RAPS_HCC_RANGE_SQL);



        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '053'
            set @ET = getdate()
        end
        declare @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE02_SQL varchar(2048);

        set @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE02_SQL
            = '
								UPDATE #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE
								SET [PBP] = (SELECT MAX([PBP])
								FROM       [' + @$EnumDbName
              + '].[dbo].[TBL_MEMBER_MONTHS] MMR 
								JOIN #HICN_SPR_RAPS_HCC_RANGE HICN        
									 ON mmr.[HICN] = hicn.[HICN]
								WHERE hicn.[FINALHICN] = #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE.[HICN]
									AND mmr.[PAYMSTART] = #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE.[PAYMSTART])
						';

        exec (@PLANRISK_DEMO_SPR_RAPS_HCC_RANGE02_SQL);

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '054'
            set @ET = getdate()
        end


        declare @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE03_SQL varchar(2048);

        set @PLANRISK_DEMO_SPR_RAPS_HCC_RANGE03_SQL
            = '
					UPDATE #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE
					SET SCC = (SELECT MAX([SCC])
					FROM [' + @$EnumDbName
              + '].[dbo].[TBL_MEMBER_MONTHS] mmr 
					JOIN #HICN_SPR_RAPS_HCC_RANGE                    hicn ON mmr.[HICN] = hicn.[HICN]
					WHERE hicn.[FINALHICN] = #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE.[HICN]
						AND mmr.[PAYMSTART] = #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE.[PAYMSTART])
					';


        exec (@PLANRISK_DEMO_SPR_RAPS_HCC_RANGE03_SQL);

        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 26', GETDATE()

        /*COMBINE DEMOGRAPHIC AND NEW RAPS SELECTION*/

        create table #PLANRISK_D_SPR_RAPS_HCC_RANGE
        (
            [Id] int identity(1, 1) primary key
          , HICN varchar(15)
          , PROCESSED_PRIORITY_PCN varchar(50)
          , DOS_PRIORITY_PCN varchar(50)
          , [DESCRIPTION] varchar(200)
          , [TYPE] varchar(6)
          , COMM money
          , HCC varchar(20)
          , HIER_HCC_OLD varchar(20)
          , HIER_FACTOR_OLD money
          , PRE_ADJSTD_FACTOR decimal(20, 4)/*47772*/
          , ADJSTD_FINAL_FACTOR decimal(20, 4)
          , MEMBER_MONTHS int
          , ROLLFORWARD_MONTHS int
          , ESRD varchar(3)
          , HOSP varchar(3)
          , PBP varchar(3)
          , SCC varchar(5)
          , BID money
          , ESTIMATED_VALUE money
          , ANNUALIZED_ESTIMATED_VALUE money
          , PROCESSED_PRIORITY_DIAG varchar(20)
          , PROCESSED_PRIORITY_PROCESSED_BY datetime
          , PROCESSED_PRIORITY_THRU_DATE datetime
          , DOS_PRIORITY_DIAG varchar(20)
          , DOS_PRIORITY_PROCESSED_BY datetime
          , DOS_PRIORITY_THRU_DATE datetime
          , PROCESSED_BY_FLAG varchar(1)    -- 39761 - IMF Flagging                    
          , PROCESSED_PRIORITY_RAC varchar(1)
          , PROCESSED_PRIORITY_FILEID varchar(18)
          , PROCESSED_PRIORITY_RAPS_SOURCE_ID varchar(50)
          , DOS_PRIORITY_RAC varchar(1)
          , DOS_PRIORITY_FILEID varchar(18)
          , DOS_PRIORITY_RAPS_SOURCE_ID varchar(50)
        );
        /*47772 - */
        insert into #PLANRISK_D_SPR_RAPS_HCC_RANGE
        select distinct
            RAPS.HICN
          , RAPS.PROCESSED_PRIORITY_PCN
          , RAPS.DOS_PRIORITY_PCN
          , RAPS.[DESCRIPTION]
          , 'PART D'
          , RAPS.COMM
          , RAPS.HCC
          , cast(0 as varchar)               HIER_HCC_OLD
          , cast(0 as money)                 HIER_FACTOR_OLD
          , cast(0 as decimal(20, 4))        PRE_ADJSTD_FACTOR          /*47772*/
          , cast(0 as decimal(20, 4))        ADJSTD_FINAL_FACTOR
          , cast(0 as int)                   MEMBER_MONTHS
          , cast(0 as int)                   ROLLFORWARD_MONTHS
          , DEMO.ESRD
          , DEMO.HOSP
          , DEMO.PBP
          , DEMO.SCC
          , cast(0 as money)                 MA_BID
          , cast(0 as money)                 ESTIMATED_VALUE
          , cast(0 as money)                 ANNUALIZED_ESTIMATED_VALUE /*47772*/
          , RAPS.PROCESSED_PRIORITY_DIAG
          , RAPS.PROCESSED_PRIORITY_PROCESSED_BY
          , RAPS.PROCESSED_PRIORITY_THRU_DATE
          , RAPS.DOS_PRIORITY_DIAG
          , RAPS.DOS_PRIORITY_PROCESSED_BY
          , RAPS.DOS_PRIORITY_THRU_DATE
          , null                                                        -- 39761 IMF Flagging
          , PROCESSED_PRIORITY_RAC
          , PROCESSED_PRIORITY_FILEID
          , PROCESSED_PRIORITY_RAPS_SOURCE_ID
          , DOS_PRIORITY_RAC
          , DOS_PRIORITY_FILEID
          , DOS_PRIORITY_RAPS_SOURCE_ID
        from #PLANRISK_A_SPR_RAPS_HCC_RANGE             RAPS
            left join #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE DEMO
                on RAPS.HICN = DEMO.HICN;

        ----IF @Debug = 0
        ----   BEGIN

        ----       IF (OBJECT_ID('tempdb.dbo.#PLANRISK_DEMO_SPR_RAPS_HCC_RANGE') IS NOT NULL)
        ----           BEGIN 
        ----               DROP TABLE #PLANRISK_DEMO_SPR_RAPS_HCC_RANGE;
        ----           END; 


        ----   END;


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '055'
            set @ET = getdate()
        end

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 27', GETDATE()

        /*UPDATE THE PRIOR AND NEW HCCS WITH HIERARCHIES*/
        /*39761 --Hierarchy logic only needs to be applied once. Hierarchy table name change */
        if (object_id('tempdb.dbo.#HIERARCHY_D_SPR_RAPS_HCC_RANGE') is not null)
        begin
            drop table #HIERARCHY_D_SPR_RAPS_HCC_RANGE;
        end;

        create table #HIERARCHY_D_SPR_RAPS_HCC_RANGE --39761
        (
            HICN varchar(15)
          , HCC_DROP varchar(20)
          , HCC_KEEP varchar(20)
        );

        insert into #HIERARCHY_D_SPR_RAPS_HCC_RANGE
        select distinct
            NEW_RAPS.HICN
          , max(HIER.HCC_DROP) as HCC_DROP
          , HIER.HCC_KEEP
        from #PLANRISK_D_SPR_RAPS_HCC_RANGE                NEW_RAPS
            join #PLANRISK_D_SPR_RAPS_HCC_RANGE            PRIOR_RAPS
                on NEW_RAPS.HICN = PRIOR_RAPS.HICN
            join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy HIER (nolock) --39761
                on NEW_RAPS.HCC = HIER.HCC_KEEP
                   and PRIOR_RAPS.HCC = HIER.HCC_DROP
        where HIER.Payment_Year = @PAYMENT_YEAR2
              and HIER.Part_C_D_Flag = 'D' --39761
        group by NEW_RAPS.HICN
               , HIER.HCC_KEEP;
        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '056'
            set @ET = getdate()
        end
        --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#PLANRISK_B_SPR_RAPS_HCC_RANGE]', 'U') IS NOT NULL DROP TABLE #PLANRISK_B_SPR_RAPS_HCC_RANGE
        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set HIER_HCC_OLD =
            (
                select max(HIER.HCC_DROP)
                from #HIERARCHY_D_SPR_RAPS_HCC_RANGE HIER
                where HIER.HICN = #PLANRISK_D_SPR_RAPS_HCC_RANGE.HICN
                      and HIER.HCC_KEEP = #PLANRISK_D_SPR_RAPS_HCC_RANGE.HCC
            );

        /*39761 -- Implementing 'HIER' prefix update that was previously applied on secondary working table*/
        update hcc
        set hcc.COMM = '0.00'
          , hcc.HCC = 'HIER' + hcc.HCC
        from #PLANRISK_D_SPR_RAPS_HCC_RANGE      hcc
            join #HIERARCHY_D_SPR_RAPS_HCC_RANGE hier
                on hcc.HICN = hier.HICN
                   and hcc.HCC = hier.HCC_DROP;
        --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHY_D_B_SPR_RAPS_HCC_RANGE]', 'U') IS NOT NULL DROP TABLE #HIERARCHY_D_B_SPR_RAPS_HCC_RANGE
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 28', GETDATE()
        -- Ticket # 25628 Start
        update RAPS
        set RAPS.HIER_FACTOR_OLD = FACTORS.Factor
        from #PLANRISK_D_SPR_RAPS_HCC_RANGE            RAPS
            inner join #POPUL_SPR_RAPS_HCC_RANGE       POPUL
                on RAPS.HICN = POPUL.HICN
            inner join [$(HRPReporting)].dbo.lk_Risk_Models FACTORS (nolock)
                on substring(RAPS.HIER_HCC_OLD, 1, 3) = 'HCC'
                   and substring(FACTORS.Factor_Description, 1, 3) = 'HCC'
                   and cast(substring(RAPS.HIER_HCC_OLD, 4, len(RAPS.HIER_HCC_OLD) - 3) as int) = cast(substring(
                                                                                                                    FACTORS.Factor_Description
                                                                                                                  , 4
                                                                                                                  , len(FACTORS.Factor_Description)
                                                                                                                    - 3
                                                                                                                ) as int)
                   and POPUL.RA_FACTOR_TYPE_ = FACTORS.Factor_Type
                   and FACTORS.Part_C_D_Flag = 'D'
                   and FACTORS.OREC = case
                                          when POPUL.AGEGROUPID > 6 then
                                              0
                                          when POPUL.AGEGROUPID <= 6 then
                                              1
                                      end
                   and POPUL.LI = FACTORS.LI
        where FACTORS.PAYMENT_YEAR = @PAYMENT_YEAR2

        -- Ticket # 25628 End 
        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set HIER_FACTOR_OLD = 0
        where HIER_FACTOR_OLD is null;

        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set HIER_FACTOR_OLD = null
        where HIER_HCC_OLD is null;


        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '057'
            set @ET = getdate()
        end

        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 29', GETDATE()
        /*UPDATE MA_BID AMOUNT FROM TBL_BIDS*/
        declare @PLANRISK_D_SPR_RAPS_HCC_RANGE_SQL varchar(2048);

        set @PLANRISK_D_SPR_RAPS_HCC_RANGE_SQL
            = '

							UPDATE #PLANRISK_D_SPR_RAPS_HCC_RANGE
							SET [BID] = (SELECT MAX([PartD_BID])
							FROM [' + @$EnumDbName + '].[dbo].[TBL_BIDS] bids
							WHERE bids.[BID_YEAR] = ''' + @BIDYEAR
              + '''
								AND #PLANRISK_D_SPR_RAPS_HCC_RANGE.[PBP]= bids.[PBP]
								--AND #PLANRISK_D_SPR_RAPS_HCC_RANGE.[SCC]= bids.[SCC]
								)';

        exec (@PLANRISK_D_SPR_RAPS_HCC_RANGE_SQL);

        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set BID = 0
        where BID is null;

        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set MEMBER_MONTHS = 0
        where MEMBER_MONTHS is null;

        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 30', GETDATE()
        /*UPDATE MEMBER_MONTHS AND ROLLFORWARD_MONTHS*/
        if @MEMBER_MONTHS = 0
           and
           (
               select case when year(getdate()) < @PAYMENT_YEAR2 then 0 else 1 end
           ) = 0
        begin
            update #PLANRISK_D_SPR_RAPS_HCC_RANGE
            set MEMBER_MONTHS = 1;

            update #PLANRISK_D_SPR_RAPS_HCC_RANGE
            set ROLLFORWARD_MONTHS = 0;
        end;
        else
        begin
            declare @PLANRISK_D_SPR_RAPS_HCC_RANGE02_SQL varchar(2048);

            set @PLANRISK_D_SPR_RAPS_HCC_RANGE02_SQL
                = '
															UPDATE #PLANRISK_D_SPR_RAPS_HCC_RANGE
															SET [MEMBER_MONTHS] = (SELECT COUNT(DISTINCT mmr.[PAYMSTART])
															FROM       [' + @$EnumDbName
                  + '].[dbo].[TBL_MEMBER_MONTHS] mmr
															JOIN #HICN_SPR_RAPS_HCC_RANGE hicns       
																ON mmr.[HICN] = hicns.[HICN]
															WHERE mmr.[PAYMSTART] BETWEEN ''01/01/'
                  + convert(char(4), @PAYMENT_YEAR2) + ''' 
																AND ''12/31/' + convert(char(4), @PAYMENT_YEAR2)
                  + '''
																AND hicns.[FINALHICN] = #PLANRISK_D_SPR_RAPS_HCC_RANGE.[HICN] 
																AND (ISNULL(mmr.[Hosp], ''N'') <> ''Y''))
												';

            exec (@PLANRISK_D_SPR_RAPS_HCC_RANGE02_SQL);

            ----IF @Debug = 0
            ----BEGIN
            ----	IF (OBJECT_ID('tempdb.dbo.#HICN_SPR_RAPS_HCC_RANGE') IS NOT NULL)
            ----	BEGIN
            ----		DROP TABLE #HICN_SPR_RAPS_HCC_RANGE;
            ----	END;
            ----END;

            update #PLANRISK_D_SPR_RAPS_HCC_RANGE
            set ROLLFORWARD_MONTHS = (12 -
                                      (
                                          select max(MEMBER_MONTHS) from #PLANRISK_D_SPR_RAPS_HCC_RANGE
                                      )
                                     )
            where MEMBER_MONTHS =
            (
                select max(MEMBER_MONTHS) from #PLANRISK_D_SPR_RAPS_HCC_RANGE
            );
        end;


        -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 31', GETDATE()


        /*47772*/
        /*UPDATE PRE_ADJSTD_FACTOR, ADJSTD_FINAL_FACTOR */

        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set PRE_ADJSTD_FACTOR = round(([COMM] - isnull(HIER_FACTOR_OLD, 0)), 3);

        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set ADJSTD_FINAL_FACTOR = round(   ([COMM] - isnull(HIER_FACTOR_OLD, 0)) /
                                           (
                                               select FACTOR.PartD_Factor
                                               from [$(HRPReporting)].dbo.lk_normalization_factors FACTOR
                                               where FACTOR.[Year] = @PAYMENT_YEAR
                                           )
                                         , 3
                                       );



        /*UPDATE ESTIMATED VALUE*/
        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set ESTIMATED_VALUE = round(
                                       BID * (MEMBER_MONTHS)
                                       * round(   ([COMM] - isnull(HIER_FACTOR_OLD, 0)) /
                                                  (
                                                      select FACTOR.PartD_Factor
                                                      from [$(HRPReporting)].dbo.lk_normalization_factors FACTOR
                                                      where FACTOR.[Year] = @PAYMENT_YEAR
                                                  )
                                                , 3
                                              )
                                     , 2
                                   );


        update #PLANRISK_D_SPR_RAPS_HCC_RANGE
        set ANNUALIZED_ESTIMATED_VALUE = round(
                                                  BID * (MEMBER_MONTHS + ROLLFORWARD_MONTHS)
                                                  * round(   ([COMM] - isnull(HIER_FACTOR_OLD, 0)) /
                                                             (
                                                                 select FACTOR.PartD_Factor
                                                                 from [$(HRPReporting)].dbo.lk_normalization_factors FACTOR
                                                                 where FACTOR.[Year] = @PAYMENT_YEAR
                                                             )
                                                           , 3
                                                         )
                                                , 2
                                              );



        update RAPS
        set ESTIMATED_VALUE = 0
          , ANNUALIZED_ESTIMATED_VALUE = 0
        from #PLANRISK_D_SPR_RAPS_HCC_RANGE RAPS
            join #POPUL_SPR_RAPS_HCC_RANGE  POPUL
                on RAPS.HICN = POPUL.HICN
        where POPUL.RA_FACTOR_TYPE_ in ( 'E', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9' );

        /*39761 -- IMF Flagging - UPDATE Processed_By_Flag - IMF flagging*/
        update dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE
        set PROCESSED_BY_FLAG = 'F'
        from dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE A
        where PROCESSED_PRIORITY_PROCESSED_BY > @IMFMidProcessby; /*47772*/

        update dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE
        set PROCESSED_BY_FLAG = 'M'
        from dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE
        where (
                  (
                      PROCESSED_PRIORITY_PROCESSED_BY > @IMFInitialProcessby
                      and PROCESSED_PRIORITY_PROCESSED_BY <= @IMFMidProcessby
                  )
                  or (
                         PROCESSED_PRIORITY_PROCESSED_BY <= @IMFInitialProcessby
                         and PROCESSED_PRIORITY_THRU_DATE > @IMFDCPThrudate /*47772*/
                     )
              );

        update dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE
        set PROCESSED_BY_FLAG = 'I'
        from dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE
        where (
                  PROCESSED_PRIORITY_PROCESSED_BY <= @IMFInitialProcessby
                  and PROCESSED_PRIORITY_THRU_DATE <= @IMFDCPThrudate
              );

        /*39761 -- Updating 'M' and/or 'F' flag to 'I' for those HICN-HCCs that showed up in the Initial MOR-D*/
        declare @PLANRISK_D_SPR_RAPS_HCC_RANGE_Update_IMF varchar(2048);

        set @PLANRISK_D_SPR_RAPS_HCC_RANGE_Update_IMF
            = '
								UPDATE raps
								SET raps.PROCESSED_BY_FLAG = ''I''
								FROM dbo.#PLANRISK_D_SPR_RAPS_HCC_RANGE raps
								JOIN [' + @$EnumDbName
              + '].[DBO].[VW_CONVERTED_MORD_DATA] mor WITH (NOLOCK) ON raps.HICN = mor.HICN
									AND raps.HCC = mor.NAME
									WHERE raps.PROCESSED_BY_FLAG IN (
										''M''
										,''F''
										)
									AND mor.[Payment_Month] BETWEEN  (cast(''' + @PAYMENT_YEAR2
              + ''' AS VARCHAR) + ''01'')
										AND (cast(''' + @PAYMENT_YEAR2 + '''  AS VARCHAR)+ right(''0''+ cast('''
              + @Paymonth_MOR + ''' - 1 AS VARCHAR), 2));
	
							';


        exec (@PLANRISK_D_SPR_RAPS_HCC_RANGE_Update_IMF);
        /*FINAL REPORT*/
        --WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!

        if @Debug = 1
        begin
            insert into #processlog
            select @ProcessName
                 , @DatabaseName
                 , @MasterET
                 , @ET
                 , convert(char(12), getdate() - @MasterET, 114)
                 , '058'
            set @ET = getdate()
        end

        if
        (
            select sum(MEMBER_MONTHS) from #PLANRISK_D_SPR_RAPS_HCC_RANGE
        ) = 0
        begin




            select top 0
                ''                as [TYPE]
              , @PAYMENT_YEAR2    as PAYMENT_YEAR
              , @PAYMENT_YEAR2    as MODEL_YEAR
              , @PROCESSBY_START2 as PROCESSED_BY_START
              , @PROCESSBY_END2   as PROCESSED_BY_END
              , ''                as PROCESSED_BY_FLAG
              , @PlanId           as PlanId
              , ''                as HICN
              , ''                as RA_FACTOR_TYPE
              , ''                as RxHCC
              , ''                as HCC_DESCRIPTION
              , 0                 as RxHCC_FACTOR
              , ''                as HIER_RxHCC
              , 0                 as HIER_RxHCC_FACTOR
              , 0                 as PRE_ADJSTD_FACTOR
              , 0                 as ADJSTD_FINAL_FACTOR
              , ''                as HCC_PROCESSED_PCN
              , ''                as HIER_HCC_PROCESSED_PCN
              , 1                 as UNQ_CONDITIONS /*47772*/
              , 0                 as MONTHS_IN_DCP
              , 0                 as MEMBER_MONTHS
              , 0                 as BID_AMOUNT
              , 0                 as ESTIMATED_VALUE
              , 0                 as ROLLFORWARD_MONTHS
              , 0                 as ANNUALIZED_ESTIMATED_VALUE
              , ''                as ESRD
              , ''                as HOSP
              , ''                as PBP
              , ''                as SCC
              , ''                as PROCESSED_PRIORITY_PROCESSED_BY
              , ''                as PROCESSED_PRIORITY_THRU_DATE
              , ''                as PROCESSED_PRIORITY_DIAG
              , ''                as PROCESSED_PRIORITY_FILEID
              , ''                as PROCESSED_PRIORITY_RAC
              , ''                as PROCESSED_PRIORITY_RAPS_SOURCE_ID
              , ''                as DOS_PRIORITY_PROCESSED_BY
              , ''                as DOS_PRIORITY_THRU_DATE
              , ''                as DOS_PRIORITY_PCN
              , ''                as DOS_PRIORITY_DIAG
              , ''                as DOS_PRIORITY_FILEID
              , ''                as DOS_PRIORITY_RAC
              , ''                as DOS_PRIORITY_RAPS_SOURCE
              , ''                as PROVIDER_LAST
              , ''                as PROVIDER_FIRST
              , ''                as PROVIDER_GROUP
              , ''                as PROVIDER_ADDRESS
              , ''                as PROVIDER_CITY
              , ''                as PROVIDER_STATE
              , ''                as PROVIDER_ZIP
              , ''                as PROVIDER_PHONE
              , ''                as PROVIDER_FAX
              , ''                as TAX_ID
              , ''                as NPI
              , ''                as SWEEP_DATE
              , ''                as POPULATED_DATE
              , [PRIORITY]        = case
                                        when @PRIORITY2 = 'P' then
                                            'Processed By Date'
                                        when @PRIORITY2 = 'S' then
                                            'Date of Service'
                                    end
            from #PLANRISK_D_SPR_RAPS_HCC_RANGE;
            /*47772 - Adding New Columns to Output*/

            if @Debug = 1
            begin
                insert into #processlog
                select @ProcessName
                     , @DatabaseName
                     , @MasterET
                     , @ET
                     , convert(char(12), getdate() - @MasterET, 114)
                     , '059'
                set @ET = getdate()
            end

        end;
        else
        begin


            if @Valuation <> 1
            begin


                if @Debug = 1
                begin
                    insert into #processlog
                    select @ProcessName
                         , @DatabaseName
                         , @MasterET
                         , @ET
                         , convert(char(12), getdate() - @MasterET, 114)
                         , '060'
                    set @ET = getdate()
                end

                select [TYPE]                            as [TYPE]
                     , @PAYMENT_YEAR2                    as PAYMENT_YEAR
                     , @PAYMENT_YEAR2                    as MODEL_YEAR
                     , @PROCESSBY_START2                 as PROCESSED_BY_START
                     , @PROCESSBY_END2                   as PROCESSED_BY_END
                     , [PROCESSED_BY_FLAG]               as PROCESSED_BY_FLAG
                     , @PlanId                           as PlanId
                     , raps.[HICN]                       as HICN
                     , popul.[RA_FACTOR_TYPE_]           as RA_FACTOR_TYPE
                     , [HCC]                             as RxHCC
                     , [DESCRIPTION]                     as HCC_DESCRIPTION
                     , [COMM]                            as RxHCC_FACTOR
                     , [HIER_HCC_OLD]                    as HIER_RxHCC
                     , [HIER_FACTOR_OLD]                 as HIER_RxHCC_FACTOR
                     , PRE_ADJSTD_FACTOR                 as PRE_ADJSTD_FACTOR
                     , ADJSTD_FINAL_FACTOR               as ADJSTD_FINAL_FACTOR
                     , PROCESSED_PRIORITY_PCN            as HCC_PROCESSED_PCN
                     , ''                                as HIER_HCC_PROCESSED_PCN
                     , 1                                 as UNQ_CONDITIONS /*47772*/
                     , 0                                 as MONTHS_IN_DCP
                     , [MEMBER_MONTHS]                   as MEMBER_MONTHS
                     , [BID]                             as BID_AMOUNT
                     , [ESTIMATED_VALUE]                 as ESTIMATED_VALUE
                     , [ROLLFORWARD_MONTHS]              as ROLLFORWARD_MONTHS
                     , ANNUALIZED_ESTIMATED_VALUE        as ANNUALIZED_ESTIMATED_VALUE
                     , [ESRD]                            as ESRD
                     , [HOSP]                            as HOSP
                     , [PBP]                             as PBP
                     , [SCC]                             as SCC
                     , PROCESSED_PRIORITY_PROCESSED_BY   as PROCESSED_PRIORITY_PROCESSED_BY
                     , PROCESSED_PRIORITY_THRU_DATE      as PROCESSED_PRIORITY_THRU_DATE
                     , PROCESSED_PRIORITY_DIAG           as PROCESSED_PRIORITY_DIAG
                     , PROCESSED_PRIORITY_FILEID         as PROCESSED_PRIORITY_FILEID
                     , PROCESSED_PRIORITY_RAC            as PROCESSED_PRIORITY_RAC
                     , PROCESSED_PRIORITY_RAPS_SOURCE_ID as PROCESSED_PRIORITY_RAPS_SOURCE_ID
                     , DOS_PRIORITY_PROCESSED_BY         as DOS_PRIORITY_PROCESSED_BY
                     , DOS_PRIORITY_THRU_DATE            as DOS_PRIORITY_THRU_DATE
                     , DOS_PRIORITY_PCN                  as DOS_PRIORITY_PCN
                     , DOS_PRIORITY_DIAG                 as DOS_PRIORITY_DIAG
                     , DOS_PRIORITY_FILEID               as DOS_PRIORITY_FILEID
                     , DOS_PRIORITY_RAC                  as DOS_PRIORITY_RAC
                     , DOS_PRIORITY_RAPS_SOURCE_ID       as DOS_PRIORITY_RAPS_SOURCE
                     , ''                                as PROVIDER_LAST
                     , ''                                as PROVIDER_FIRST
                     , ''                                as PROVIDER_GROUP
                     , ''                                as PROVIDER_ADDRESS
                     , ''                                as PROVIDER_CITY
                     , ''                                as PROVIDER_STATE
                     , ''                                as PROVIDER_ZIP
                     , ''                                as PROVIDER_PHONE
                     , ''                                as PROVIDER_FAX
                     , ''                                as TAX_ID
                     , ''                                as NPI
                     , case
                           when PROCESSED_BY_FLAG = 'I' then
                               @IMFInitialProcessby
                           when PROCESSED_BY_FLAG = 'M' then
                               @IMFMidProcessby
                           when PROCESSED_BY_FLAG = 'F' then
                               @IMFFinalProcessby
                       end                               as SWEEP_DATE
                     , @Populated_Date                   as POPULATED_DATE
                     , [PRIORITY]                        = case
                                                               when @PRIORITY2 = 'P' then
                                                                   'Processed By Date'
                                                               when @PRIORITY2 = 'S' then
                                                                   'Date of Service'
                                                           end
                from #PLANRISK_D_SPR_RAPS_HCC_RANGE     raps
                    left join #POPUL_SPR_RAPS_HCC_RANGE popul
                        on raps.[HICN] = popul.[HICN]
                where raps.[HCC] not like 'HIER%'
                      and raps.[MEMBER_MONTHS] > 0
                      and raps.[COMM] <> 0
                      and raps.PROCESSED_PRIORITY_PROCESSED_BY
                      between @PROCESSBY_START2 and @PROCESSBY_END2 /*47772*/
                /** 39761 Applying User-Defined Start and End Parameters here **/
                order by raps.[HICN]
                       , raps.[HCC];
            end;



            if @Debug = 1
            begin
                insert into #processlog
                select @ProcessName
                     , @DatabaseName
                     , @MasterET
                     , @ET
                     , convert(char(12), getdate() - @MasterET, 114)
                     , '061'
                set @ET = getdate()
            end
            --WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!
            if @Valuation = 1
            begin
                delete m
                from [Valuation].[NewHCCPartD] m
                where m.[ProcessRunId] = @ProcessRunId
                      and m.[PlanId] = @PlanId;

                if @Debug = 1
                begin
                    insert into #processlog
                    select @ProcessName
                         , @DatabaseName
                         , @MasterET
                         , @ET
                         , convert(char(12), getdate() - @MasterET, 114)
                         , '062'
                    set @ET = getdate()
                end

                insert into [Valuation].[NewHCCPartD]
                (
                    [ProcessRunId]
                  , [DbName]
                  , [TYPE]
                  , PAYMENT_YEAR
                  , MODEL_YEAR
                  , PROCESSED_BY_START
                  , PROCESSED_BY_END
                  , PROCESSED_BY_FLAG
                  , PlanId
                  , HICN
                  , RA_FACTOR_TYPE
                  , RxHCC
                  , HCC_DESCRIPTION
                  , RxHCC_FACTOR
                  , HIER_RxHCC
                  , HIER_RxHCC_FACTOR
                  , PRE_ADJSTD_FACTOR
                  , ADJSTD_FINAL_FACTOR
                  , HCC_PROCESSED_PCN
                  , HIER_HCC_PROCESSED_PCN
                  , UNQ_CONDITIONS
                  , MONTHS_IN_DCP
                  , MEMBER_MONTHS
                  , BID_AMOUNT
                  , ESTIMATED_VALUE
                  , ROLLFORWARD_MONTHS
                  , ANNUALIZED_ESTIMATED_VALUE
                  , ESRD
                  , HOSP
                  , PBP
                  , SCC
                  , PROCESSED_PRIORITY_PROCESSED_BY
                  , PROCESSED_PRIORITY_THRU_DATE
                  , PROCESSED_PRIORITY_DIAG
                  , PROCESSED_PRIORITY_FILEID
                  , PROCESSED_PRIORITY_RAC
                  , PROCESSED_PRIORITY_RAPS_SOURCE_ID
                  , DOS_PRIORITY_PROCESSED_BY
                  , DOS_PRIORITY_THRU_DATE
                  , DOS_PRIORITY_PCN
                  , DOS_PRIORITY_DIAG
                  , DOS_PRIORITY_FILEID
                  , DOS_PRIORITY_RAC
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
                  , TAX_ID
                  , NPI
                  , SWEEP_DATE
                  , POPULATED_DATE
                  , [PRIORITY]
                )
                select @ProcessRunId
                     , @$EnumDbName
                     , [TYPE]                            as [TYPE]
                     , @PAYMENT_YEAR2                    as PAYMENT_YEAR
                     , @PAYMENT_YEAR2                    as MODEL_YEAR
                     , @PROCESSBY_START2                 as PROCESSED_BY_START
                     , @PROCESSBY_END2                   as PROCESSED_BY_END
                     , [PROCESSED_BY_FLAG]               as PROCESSED_BY_FLAG
                     , @PlanId                           as PlanId
                     , raps.[HICN]                       as HICN
                     , popul.[RA_FACTOR_TYPE_]           as RA_FACTOR_TYPE
                     , [HCC]                             as RxHCC
                     , [DESCRIPTION]                     as HCC_DESCRIPTION
                     , [COMM]                            as RxHCC_FACTOR
                     , [HIER_HCC_OLD]                    as HIER_RxHCC
                     , [HIER_FACTOR_OLD]                 as HIER_RxHCC_FACTOR
                     , PRE_ADJSTD_FACTOR                 as PRE_ADJSTD_FACTOR
                     , ADJSTD_FINAL_FACTOR               as ADJSTD_FINAL_FACTOR
                     , PROCESSED_PRIORITY_PCN            as HCC_PROCESSED_PCN
                     , ''                                as HIER_HCC_PROCESSED_PCN
                     , 1                                 as UNQ_CONDITIONS           /*47772*/
                     , 0                                 as MONTHS_IN_DCP
                     , [MEMBER_MONTHS]                   as MEMBER_MONTHS
                     , [BID]                             as BID_AMOUNT
                     , [ESTIMATED_VALUE]                 as ESTIMATED_VALUE
                     , [ROLLFORWARD_MONTHS]              as ROLLFORWARD_MONTHS
                     , ANNUALIZED_ESTIMATED_VALUE        as ANNUALIZED_ESTIMATED_VALUE
                     , [ESRD]                            as ESRD
                     , [HOSP]                            as HOSP
                     , [PBP]                             as PBP
                     , [SCC]                             as SCC
                     , PROCESSED_PRIORITY_PROCESSED_BY   as PROCESSED_PRIORITY_PROCESSED_BY
                     , PROCESSED_PRIORITY_THRU_DATE      as PROCESSED_PRIORITY_THRU_DATE
                     , PROCESSED_PRIORITY_DIAG           as PROCESSED_PRIORITY_DIAG
                     , PROCESSED_PRIORITY_FILEID         as PROCESSED_PRIORITY_FILEID
                     , PROCESSED_PRIORITY_RAC            as PROCESSED_PRIORITY_RAC
                     , PROCESSED_PRIORITY_RAPS_SOURCE_ID as PROCESSED_PRIORITY_RAPS_SOURCE_ID
                     , DOS_PRIORITY_PROCESSED_BY         as DOS_PRIORITY_PROCESSED_BY
                     , DOS_PRIORITY_THRU_DATE            as DOS_PRIORITY_THRU_DATE
                     , DOS_PRIORITY_PCN                  as DOS_PRIORITY_PCN
                     , DOS_PRIORITY_DIAG                 as DOS_PRIORITY_DIAG
                     , DOS_PRIORITY_FILEID               as DOS_PRIORITY_FILEID
                     , DOS_PRIORITY_RAC                  as DOS_PRIORITY_RAC
                     , DOS_PRIORITY_RAPS_SOURCE_ID       as DOS_PRIORITY_RAPS_SOURCE /*2/1/2016*/
                     , ''                                as PROVIDER_LAST
                     , ''                                as PROVIDER_FIRST
                     , ''                                as PROVIDER_GROUP
                     , ''                                as PROVIDER_ADDRESS
                     , ''                                as PROVIDER_CITY
                     , ''                                as PROVIDER_STATE
                     , ''                                as PROVIDER_ZIP
                     , ''                                as PROVIDER_PHONE
                     , ''                                as PROVIDER_FAX
                     , ''                                as TAX_ID
                     , ''                                as NPI
                     , case
                           when PROCESSED_BY_FLAG = 'I' then
                               @IMFInitialProcessby
                           when PROCESSED_BY_FLAG = 'M' then
                               @IMFMidProcessby
                           when PROCESSED_BY_FLAG = 'F' then
                               @IMFFinalProcessby
                       end                               as SWEEP_DATE
                     , @Populated_Date                   as POPULATED_DATE
                     , [PRIORITY]                        = case
                                                               when @PRIORITY2 = 'P' then
                                                                   'Processed By Date'
                                                               when @PRIORITY2 = 'S' then
                                                                   'Date of Service'
                                                           end
                from #PLANRISK_D_SPR_RAPS_HCC_RANGE     raps
                    left join #POPUL_SPR_RAPS_HCC_RANGE popul
                        on raps.[HICN] = popul.[HICN]
                where raps.[HCC] not like 'HIER%'
                      and raps.[MEMBER_MONTHS] > 0
                      and raps.[COMM] <> 0
                      and raps.PROCESSED_PRIORITY_PROCESSED_BY
                      between @PROCESSBY_START2 and @PROCESSBY_END2; /*46640*/

                set @RecordCount = @@rowcount;


                if @Debug = 1
                begin
                    insert into #processlog
                    select @ProcessName
                         , @DatabaseName
                         , @MasterET
                         , @ET
                         , convert(char(12), getdate() - @MasterET, 114)
                         , '0'
                    set @ET = getdate()
                end
                if @$EnumDbName <> db_name()
                begin
                    declare @UpRecCountSQL varchar(4096);

                    set @UpRecCountSQL
                        = '
											UPDATE pwl
											SET pwl.[RowCount] = ISNULL(' + cast(@RecordCount as varchar(10))
                          + ', 0)
											FROM [RPTAutoEngine].[ProcessWorkList] pwl
											WHERE pwl.[ProcessWorkListId] = ' + cast(@ProcessRunId as varchar(10));
                end;
            end;
        end;
    --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#POPUL_SPR_RAPS_HCC_RANGE]', 'U') IS NOT NULL DROP TABLE #POPUL_SPR_RAPS_HCC_RANGE
    --/*DROP TABLE WHEN NOT NEEDED ANY LONGER*/ IF OBJECT_ID('[tempdb].[dbo].[#PLANRISK_D_SPR_RAPS_HCC_RANGE]', 'U') IS NOT NULL DROP TABLE #PLANRISK_D_SPR_RAPS_HCC_RANGE
    -----/*TRACK*/ INSERT INTO dbo.tbl_track_progress_SPR_RAPS_HCC_RANGE SELECT 'STEP 33', GETDATE()
    end;
---------------------------------------------------------------------------------
end;