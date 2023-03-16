CREATE procedure [rev].[spr_EstRecv_Delete_HCC]
    @Payment_Year_NewDeleteHCC varchar(4)
  , @PROCESSBY_START smalldatetime
  , @PROCESSBY_END smalldatetime
  , @ReportOutputByMonth varchar(1) = 'S' -- 'S' = Summary, 'D' = 'Detail Annualized'; 'M' = 'Detail per Member per Month' ; 'R' = Rollup
  , @Debug int = 0
  ,	@RowCount INT OUT
as /****************************************************************************************************************************************************************************************************************/
/* Name				:	spr_EstRecv_Delete_HCC																																									*/
/* Type 			:	Stored Procedure																																										*/
/* Author       	:	Kerri Phipps																																											*/
/* Date				:	10/31/2013																																												*/
/* Version			:																																															*/
/* Description		:	Get delete HCCs from the roll up tables in																																				*/
/*						<Client>_Report database																																								*/
/*																																																				*/
/* Version History :																																															*/
/* Author			Date		Version#	TFS Ticket#		Description																																			*/
/* ---------------	----------	--------	-----------		------------																																		*/
/* Kerri Phipps		10/31/2013	2.0			20225			Initial build of Delete HCC Procedure																												*/
/*																																																				*/
/* Dan Kim			11/12/2013  3.1			23088			Create new 'T' ReportOutput to write the 'M' output to dbo.EstRecHCCDeleteOutput																	*/
/* This is for RADAR internal requirement and will not be displayed in ReconEdge.																																*/
/* Ravi Chauhan		2/13/2014   3.2         25188           Add Model Year to the output for the parameter @ReportOutputByMonth T and M for the RADAR team. Also added model year joining condition.            */
/* Ravi Chauhan		06/03/2014  3.3         26249           Update New HCC Procs so that it can automate the process for RADAR to consume the data                                                              */
/* Ravi Chauhan		07/10/2014  3.4         29157           Fix 2 Payment Year Issue for the Payment Year 2014                                                                                                  */
/* Ravi Chauhan		02/12/2015  3.5         25641           Delete HCC Report - Part C changes.                                                                                                                 */
/* Ravi Chauhan		03/22/2015  4.5         36970           Part C New HCC and Delete HCC correction for use of lk_ratebook_ESRD                                                                                */
/* Madhuri Suri		06/30/2015  4.6         43205           MaxMor Paymonth change for 2015                                                                                                                     */
/* Scott Holland	07/06/2015	4.7			41262			Update new Summary table in logic.																													*/
/* Scott Holland	07/13/2015	4.8			41262			Update table name.																																	*/
/* Madhuri Suri		08/03/2015  4.9         42124           Null Values in Columns corrected                                                                                                                    */
/* Madhuri Suri		10/12/2015	5.0			45816			ICD10 Change updates.																																*/
/* D.Waddell		09/30/2016	5.1			85115			Tailor Part C Delete HCC to incorporate R Parameter for ER - Phase 1.2. Proc prev. resided in dbo schema											*/
/* D.Waddell		11/08/2016  5.2			85117           For R Parameter insert H Plan ID into PlanId field in output table  																		   		*/
/* D.Waddell		12/09/2016  5.3			60305             Part C Delete HCC Report to accommodate 2017PY Risk Model changes																					*/
/*					03/19/2017	5.4			62756			Encapsulated after section 8.1 to section 8.4 @ReportOutputByMonth = 'R'																			*/
/*															@Cln_Rpt_Srv is set at Section 006.6 and not at Section 007																							*/
/*															Added more @Debug sections	                                                                                                                        */
/* D.Waddell        05/03/2017 	5.5			64262           @ManualRun variable needs to be removed entirely. It no longer needs to be part of the stored proc user input variables, nor within the body of     */
/*                                                          the stored proc. Paymonth logic Change in section #20 new                                                                                           */
/* D. Waddell       05/15/2017  5.6			64782           Convert Part C New HCC to Summary 2.0	(Sections 012.1, 027)																					    */
/* D. Waddell       06/25/2018  5.7         71712 (RE-2264  Replace use of tbl_EstRecv_ModelSplits w/ lk_Risk_Score_Factor_PartC (Section 33)                                                                   */
/* Anand			09/22/2020  5.8         79581 (RRI-34)  Add Row Count Out parameter						                                                                                                    */
/****************************************************************************************************************************************************************************************************************/


set nocount on
set statistics io off

begin
    -- Control statements below are included to support ETL architecture and must be the first statement in the procedure.
    -- Control statement will not be executed and has no impact on the procedure output.
    -- The control statements must match the final output for @ReportOutputByMonth = 'M'.
    -- The field name, data type, and field order must be exactly as output for @ReportOutputByMonth = 'M'.
    -- The ETL process requests the metadata from the procedure and the first select is returned.
    --Declare @Payment_Year_NewDeleteHCC		VARCHAR(4),
    --	@PROCESSBY_START	SMALLDATETIME,
    --	@PROCESSBY_END		SMALLDATETIME,
    --	@ReportOutputByMonth varchar(1)
    --Set @Payment_Year_NewDeleteHCC = '2014'
    --set @PROCESSBY_START = '1/1/2013'
    --set @PROCESSBY_END = '12/31/2014'
    --set @ReportOutputByMonth = 'D'

    declare @fromdate          datetime
          , @thrudate          datetime
          , @initial_flag      datetime
          , @myu_flag          datetime
          , @final_flag        datetime
          , @Paymonth_MOR      char(2) --43205
          , @GetProviderIdSQL  varchar(4096)
          , @Clnt_Rpt_DB       varchar(128)
          , @ClntPlan_DB       varchar(128)
          , @Clnt_Rpt_Srv      varchar(128)
          , @Clnt_DB           varchar(128)
          , @ClntName          varchar(100)
          , @Rollup_PlanID_dyn smallint
          , @Rollup_PlanID     smallint
          , @RollupSQL         varchar(max)
          , @Coding_Intensity  decimal(18, 4)
          , @Norm_Factor       decimal(18, 4)
          , @PlanID            varchar(5)
          , @RollupSQL_N       nvarchar(max)
          , @PlanIDSQL         varchar(max)
          , @OutTableSQL       varchar(max)
          , @Rollup2SQL        varchar(max)
          , @ParmDefinition    nvarchar(500);


    declare @Open_Qry_SQL nvarchar(max);
    declare @TablePlan table
    (
        [ID] int identity(1, 1) primary key
      , [PlanID] varchar(5)
    );


    if @Debug = 1
    begin
        set statistics io on
        declare @ET datetime
        declare @MasterET datetime
        declare @ProcessNameIn varchar(128)
        set @ET = getdate()
        set @MasterET = @ET
        set @ProcessNameIn = object_name(@@procid)
        exec [dbo].[PerfLogMonitor] '001'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    if 1 = 2
        select [PAYMENT_YEAR]                     = cast(null as int)
             , [PAYMSTART]                        = cast(null as datetime)
             , [PROCESSED_BY_START]               = cast(null as smalldatetime)
             , [PROCESSED_BY_END]                 = cast(null as smalldatetime)
             , [PLANID]                           = cast(null as varchar(5))
             , [HICN]                             = cast(null as varchar(15))
             , [RA_FACTOR_TYPE]                   = cast(null as varchar(10))
             , [PROCESSED_PRIORITY_PROCESSED_BY]  = cast(null as datetime)
             , [PROCESSED_PRIORITY_THRU_DATE]     = cast(null as datetime)
             , [PROCESSED_PRIORITY_PCN]           = cast(null as varchar(50))
             , [PROCESSED_PRIORITY_DIAG]          = cast(null as varchar(20))
             , [THRU_PRIORITY_PROCESSED_BY]       = cast(null as datetime)
             , [THRU_PRIORITY_THRU_DATE]          = cast(null as datetime)
             , [THRU_PRIORITY_PCN]                = cast(null as varchar(50))
             , [THRU_PRIORITY_DIAG]               = cast(null as varchar(20))
             , [IN_MOR]                           = cast(null as varchar(1))
             , [HCC]                              = cast(null as varchar(20))
             , [HCC_DESCRIPTION]                  = cast(null as varchar(255))
             , [FACTOR]                           = cast(null as decimal(20, 4))
             , [HIER_HCC_OLD]                     = cast(null as varchar(20))
             , [HIER_FACTOR_OLD]                  = cast(null as decimal(20, 4))
             , [ACTIVE_INDICATOR_FOR_ROLLFORWARD] = cast(null as varchar(1))
             , [MONTHS_IN_DCP]                    = cast(null as int)
             , [ESRD]                             = cast(null as varchar(3))
             , [HOSP]                             = cast(null as varchar(3))
             , [PBP]                              = cast(null as varchar(3))
             , [SCC]                              = cast(null as varchar(5))
             , [BID]                              = cast(null as money)
             , [ESTIMATED_VALUE]                  = cast(null as money)
             , [RAPS_SOURCE]                      = cast(null as varchar(50))
             , [PROVIDER_ID]                      = cast(null as varchar(40))
             , [PROVIDER_LAST]                    = cast(null as varchar(55))
             , [PROVIDER_FIRST]                   = cast(null as varchar(55))
             , [PROVIDER_GROUP]                   = cast(null as varchar(80))
             , [PROVIDER_ADDRESS]                 = cast(null as varchar(100))
             , [PROVIDER_CITY]                    = cast(null as varchar(30))
             , [PROVIDER_STATE]                   = cast(null as varchar(2))
             , [PROVIDER_ZIP]                     = cast(null as varchar(13))
             , [PROVIDER_PHONE]                   = cast(null as varchar(15))
             , [PROVIDER_FAX]                     = cast(null as varchar(15))
             , [TAX_ID]                           = cast(null as varchar(55))
             , [NPI]                              = cast(null as varchar(20))
             , [SWEEP_DATE]                       = cast(null as datetime)



    /*Testing parameters*/
    --declare @Payment_Year_NewDeleteHCC		VARCHAR(4) = '2013'
    --declare @PROCESSBY_START	SMALLDATETIME = '3/16/2013'
    --declare @PROCESSBY_END		SMALLDATETIME = '12/31/2014'
    --declare @ReportOutputByMonth varchar(2) = 'M' --'S' = Summary; 'D' = 'Detail Annualized'; 'M' = 'Detail per Member per Month'; 'R' = Rollup
    --exec spr_EstRecv_New_HCC '2013','01/01/2012','12/31/2014','S'


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '002'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    select @fromdate = case
                           when year(getdate()) < @Payment_Year_NewDeleteHCC then
    (
        select min([DCP_Start])
        from [$(HRPReporting)].[dbo].[lk_DCP_dates]
        where substring([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
    )
                           else
                               cast('1/1/' + cast(@Payment_Year_NewDeleteHCC - 1 as varchar(4)) as datetime)
                       end
    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '003'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    select @thrudate = case
                           when year(getdate()) < @Payment_Year_NewDeleteHCC then
    (
        select min([DCP_End])
        from [$(HRPReporting)].[dbo].[lk_DCP_dates]
        where substring([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
    )
                           else
                               cast('12/31/' + cast(@Payment_Year_NewDeleteHCC - 1 as varchar(4)) as datetime)
                       end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '004'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    select @initial_flag =
    (
        select min([Initial_Sweep_Date])
        from [$(HRPReporting)].[dbo].[lk_DCP_dates]
        where substring([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
              and [Mid_Year_Update] is null
    )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '005'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    select @myu_flag
        =
    (
        select max([Initial_Sweep_Date])
        from [$(HRPReporting)].[dbo].[lk_DCP_dates]
        where substring([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC ---43205 changed Hardcoded 2014 to @Payment_Year_NewDeleteHCC
              and [Mid_Year_Update] = 'Y'
    )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '006'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    select @final_flag =
    (
        select max([Final_Sweep_Date])
        from [$(HRPReporting)].[dbo].[lk_DCP_dates]
        where substring([PayMonth], 1, 4) = @Payment_Year_NewDeleteHCC
              and [Mid_Year_Update] is null
    )



    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '006.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    /* Determines population of @TablePlan Session Table based on @ReportOutputMonth parameter value    TFS 54264*/
    if @ReportOutputByMonth = 'R'
    begin

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '006.2'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        set @Clnt_Rpt_DB =
        (
            select [Current Database] = db_name()
        );

        set @Clnt_Rpt_Srv =
        (
            select convert(sysname, serverproperty('servername'))
        );
        set @ClntName =
        (
            select [Client_Name]
            from [$(HRPReporting)].[dbo].[tbl_Clients]
            where [Report_DB] = @Clnt_Rpt_DB
        )

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '006.3'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        insert into @TablePlan
        (
            [PlanID]
        )
        select [rp].[PlanID]
        from [$(HRPInternalReportsDB)].[dbo].[RollupPlan]             [rp]
            inner join [$(HRPInternalReportsDB)].[dbo].[RollupClient] [cl]
                on [rp].[ClientIdentifier] = [cl].[ClientIdentifier]
        where [cl].[ClientName] = @ClntName
              and [rp].[Active] = 1
              and [rp].[UseForRollup] = 1

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '006.4'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

    end
    else
    begin
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '006.5'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        set @ClntPlan_DB =
        (
            select [Current Database] = db_name()
        );

        insert into @TablePlan
        (
            [PlanID]
        )
        select [PlanID] = right(@ClntPlan_DB, 5)


        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '006.6'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        select @Clnt_Rpt_DB  = [clnt].[Report_DB]
             , @Clnt_Rpt_Srv = [clnt].[Report_DB_Server]
        from @TablePlan                                               [pln]
            inner join [$(HRPReporting)].[dbo].[tbl_Connection]          [con]
                on [con].[Plan_ID] = [pln].[PlanID]
            inner join [$(HRPReporting)].[dbo].[xref_Client_Connections] [xref]
                on [xref].[Connection_ID] = [con].[Connection_ID]
            inner join [$(HRPReporting)].[dbo].[tbl_Clients]             [clnt]
                on [clnt].[Client_ID] = [xref].[Client_ID]
        where [con].[Active_CMS_Plan] = 1

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '006.7'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

    end


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '006.8'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    set @Clnt_DB =
    (
        select [Client_DB]
        from [$(HRPReporting)].[dbo].[tbl_Clients]
        where [Report_DB] = @Clnt_Rpt_DB
    )

    --select @Payment_Year_NewDeleteHCC payment_year, @processby_start processby_start, @processby_end processby_end, @ReportOutputByMonth ReportOutputByMonth, @fromdate fromdate, @thrudate thrudate, @initial_flag initial_flag, @myu_flag myu_flag, @final_flag final_flag
    -- Get Rollup data from ReportDB



    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '007'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    --SET @Clnt_Rpt_Srv = (SELECT CONVERT(sysname, SERVERPROPERTY('servername')));


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '008'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    --TFS 85115   incorporate "R" Parameter for ER 

    if object_id('tempdb..#RollupPlan ', 'U') is not null
        drop table [#RollupPlan]

    create table [#RollupPlan]
    (
        [ID] int identity(1, 1)
      , [PlanID] int
      , [Plan_ID] varchar(5)
    )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '008.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    /*B 62756*/
    if @ReportOutputByMonth = 'R'
    begin
        /*E 62756*/

        insert into [#RollupPlan]
        (
            [PlanID]
          , [Plan_ID]
        )
        select [RollPln].[PlanIdentifier]
             , [RollPln].[PlanID]
        from [$(HRPInternalReportsDB)].[dbo].[RollupPlan] [RollPln]
            inner join @TablePlan                    [pln]
                on [RollPln].[PlanID] = [pln].[PlanID]
        where [RollPln].[Active] = 1
              and [RollPln].[UseForRollup] = 1

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '008.2'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end


        /*43205 Start - Dynamic Paymonth for MOR Mid_year_Update */
        declare @SQL nvarchar(1024)
        declare @SQLParm nvarchar(1024)

        set @SQLParm = N'@Paymonth_MOROUT char(2) OUTPUT'
        set @SQL
            = 'SELECT DISTINCT  @Paymonth_MOROUT = CAST (RIGHT(Paymonth, 2) as CHAR(2))
                                             FROM ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
              + '.dbo.lk_DCP_dates_RskAdj 
                                             WHERE LEFT(paymonth,4)= ' + @Payment_Year_NewDeleteHCC
              + '
                                             AND MOR_Mid_Year_Update =''Y'' '
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '008.3'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end


        exec [sys].[sp_executesql] @SQL
                                 , @SQLParm
                                 , @Paymonth_MOROUT = @Paymonth_MOR output

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '008.4'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

    /*B 62756*/
    end
    /*E 62756*/
    else
    begin
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '008.5'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
        set @RollupSQL_N
            = 'SELECT  [RollPln].[PlanIdentifier] , [RollPln].[PlanID]  FROM [$(HRPInternalReportsDB)].[dbo].[RollupPlan] [RollPln]  WHERE   [RollPln].[Active] = 1  AND [RollPln].[UseForRollup] = 1 AND [RollPln].[PlanID] ='''''
              + right(@ClntPlan_DB, 5) + ''''''

        select @Open_Qry_SQL
            = 'INSERT INTO [#RollupPlan]  ( [PlanID],[Plan_ID]) SELECT  PlanIdentifier, PlanID FROM OPENQUERY(['
              + @Clnt_Rpt_Srv + '], ' + '''' + @RollupSQL_N + '''' + ') ;';


        exec sp_executesql @Open_Qry_SQL

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '008.6'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

    end


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '009'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    /*45816*/
    if object_id('tempdb..#Vw_LkRiskModelsDiagHCC') is not null
        drop table [#Vw_LkRiskModelsDiagHCC]

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '010'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    select [ICD].[ICDCode]
         , [HCC_Label]    = [ICD].[HCCLabel]
         , [Payment_Year] = [ICD].[PaymentYear]
         , [Factor_Type]  = [ICD].[FactorType]
         , [ICD].[ICDClassification]
         , [ef].[StartDate]
         , [ef].[EndDate]
    into [#Vw_LkRiskModelsDiagHCC]
    from [$(HRPReporting)].[dbo].[vw_LkRiskModelsDiagHCC] [ICD]
        join [$(HRPReporting)].[dbo].[ICDEffectiveDates]  [ef]
            on [ICD].[ICDClassification] = [ef].[ICDClassification]


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '011'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    /*43205 END - Dynamic Paymonth for MOR Mid_year_Update */


    if object_id('[TEMPDB].[DBO].[#New_HCC_rollup]', 'U') is not null
        drop table [dbo].[#New_HCC_rollup]

    create table [dbo].[#New_HCC_rollup]
    (
        [PlanID] int
      , [Plan_ID] varchar(5)
      , [HICN] varchar(12)
      , [PaymentYear] int
      , [PaymStart] datetime
      , [Model_Year] int
      , [Factor_category] varchar(20)
      , [Factor_Desc] varchar(50)
      , [Factor] decimal(20, 4)
      , [RAFT] varchar(3)
      , [HCC_Number] int
      , [Min_ProcessBy] datetime
      , [Min_ThruDate] datetime
      , [Min_ProcessBy_SeqNum] int
      , [Min_ThruDate_SeqNum] int
      , [Processed_Priority_Thru_Date] datetime -- 42124 Start
      , [Min_ProcessBy_PCN] varchar(50)
      , [Min_Processby_DiagCD] varchar(20)
      , [Thru_Priority_Processed_By] datetime
      , [Min_ThruDate_PCN] varchar(50)
      , [Min_ThruDate_DiagCD] varchar(20)
      , [Processed_Priority_RAPS_Source_ID] int
      , [Thru_Priority_RAPS_Source_ID] int
      , [Processed_Priority_Provider_ID] varchar(40)
      , [Thru_Priority_Provider_ID] varchar(40) -- 42124 END
      , [AGED] int                              -- TFS
    )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '012'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    -- 41262 updated table name
    if (year(getdate()) >= @Payment_Year_NewDeleteHCC)
    begin
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '012.1'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        set @RollupSQL
            = 'INSERT INTO #New_HCC_rollup (
				PlanID
				,Plan_ID
				,HICN
				,PaymentYear
				,PaymStart
				,Model_Year
				,Factor_category
				,Factor_Desc
				,Factor
				,RAFT
				,HCC_Number
				,Min_ProcessBy
				,Min_ThruDate
				,Min_ProcessBy_SeqNum
				,Min_ThruDate_SeqNum
				,Processed_Priority_Thru_Date -- 42124 Start
				,Min_ProcessBy_PCN
				,Min_Processby_DiagCD
				,Thru_Priority_Processed_By
				,Min_ThruDate_PCN
				,Min_ThruDate_DiagCD
				,Processed_Priority_RAPS_Source_ID
				,Thru_Priority_RAPS_Source_ID
				,Processed_Priority_Provider_ID
				,Thru_Priority_Provider_ID -- 42124 END
				,AGED
				)
		
				select 
									rps.PlanID,
									rp.Plan_ID,
									rps.HICN,
									rps.PaymentYear,
									rps.PaymStart,
									Model_Year = rps.ModelYear,
									rps.Factor_category,
									rps.Factor_Desc,
									rps.Factor,
									rps.RAFT,
									rps.HCC_Number,
									rps.Min_ProcessBy,
									rps.Min_ThruDate,
									rps.Min_ProcessBy_SeqNum,
									rps.Min_ThruDate_SeqNum,
									Processed_Priority_Thru_Date 	,	-- 42124 Start
									Min_ProcessBy_PCN	,			
									Min_Processby_DiagCD ,			
									Thru_Priority_Processed_By ,		
									Min_ThruDate_PCN	,		
									Min_ThruDate_DiagCD, 
									Processed_Priority_RAPS_Source_ID , 
									Thru_Priority_RAPS_Source_ID, 
									Processed_Priority_Provider_ID, 
									Thru_Priority_Provider_ID -- 42124 END
									,rps.AGED
								FROM ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
              + '.[rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] rps     
									  INNER JOIN [#RollupPlan] rp 
									 ON rps.PlanID = rp.PlanID   
										WHERE rps.factor_desc like ''DEL%''
										AND rps.PaymentYear = CAST(''' + @Payment_Year_NewDeleteHCC + ''' as INT) ' -- Ticket # 29157

        --TFS 64782
        exec (@RollupSQL)

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '012.2'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
    end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '013'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    create clustered index [New_HCC_rollup]
    on [#New_HCC_rollup]
    (
        [HICN]
      , [Factor_Desc]
    )


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '014'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    if object_id('[TEMPDB].[DBO].[#new_hcc_output]', 'U') is not null
        drop table [dbo].[#new_hcc_output]

    create table [dbo].[#new_hcc_output]
    (
        [payment_year] int
      , [paymstart] datetime
      , [model_year] int
      , [processed_by_start] datetime
      , [processed_by_end] datetime
      , [planid] varchar(5)
      , [hicn] varchar(15)
      , [ra_factor_type] varchar(2)
      , [processed_priority_processed_by] datetime
      , [processed_priority_thru_date] datetime
      , [processed_priority_pcn] varchar(50)
      , [processed_priority_diag] varchar(20)
      , [thru_priority_processed_by] datetime
      , [thru_priority_thru_date] datetime
      , [thru_priority_pcn] varchar(50)
      , [thru_priority_diag] varchar(20)
      , [in_mor] varchar(1)
      , [in_mor_max_month] varchar(6)
      , [hcc] varchar(20)
      , [hcc_No_Tags] varchar(20)
      , [hcc_description] varchar(255)
      , [factor] decimal(20, 4)
      , [hier_hcc_old] varchar(20)
      , [hier_factor_old] decimal(20, 4)
      , [member_months] int
      , [active_indicator_for_rollforward] varchar(1)
      , [months_in_dcp] int
      , [esrd] varchar(1)
      , [hosp] varchar(1)
      , [pbp] varchar(3)
      , [scc] varchar(5)
      , [bid] money
      , [estimated_value] money
      , [raps_source] varchar(50)
      , [provider_id] varchar(40)
      , [provider_last] varchar(55)
      , [provider_first] varchar(55)
      , [provider_group] varchar(80)
      , [provider_address] varchar(100)
      , [provider_city] varchar(30)
      , [provider_state] varchar(2)
      , [provider_zip] varchar(13)
      , [provider_phone] varchar(15)
      , [provider_fax] varchar(15)
      , [tax_id] varchar(55)
      , [npi] varchar(20)
      , [AGED] int
    )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '015'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    insert into [#new_hcc_output]
    (
        [payment_year]
      , [paymstart]
      , [model_year]
      , [processed_by_start]
      , [processed_by_end]
      , [planid]
      , [hicn]
      , [ra_factor_type]
      , [processed_priority_processed_by]
      , [processed_priority_thru_date]
      , [processed_priority_pcn]
      , [processed_priority_diag]
      , [thru_priority_processed_by]
      , [thru_priority_thru_date]
      , [thru_priority_pcn]
      , [thru_priority_diag]
      , [hcc]
      , [hcc_No_Tags]
      , [factor]
      , [member_months]
      , [raps_source]
      , [provider_id]
      , [AGED]
    )
    select distinct
        [n].[PaymentYear]
      , [n].[PaymStart]
      , [n].[Model_Year]
      , @PROCESSBY_START
      , @PROCESSBY_END
      , [n].[Plan_ID]                                                                       --H Plan ID
      , [n].[HICN]
      , [n].[RAFT]
      , [n].[Min_ProcessBy]
      , [n].[Processed_Priority_Thru_Date]                                                  --42124
      , [n].[Min_ProcessBy_PCN]
      , [n].[Min_Processby_DiagCD]
      , [n].[Thru_Priority_Processed_By]
      , [n].[Min_ThruDate]
      , [n].[Min_ThruDate_PCN]
      , [n].[Min_ThruDate_DiagCD]                                                           --42124
      , [n].[Factor_Desc]
      , substring([n].[Factor_Desc], 5, len([n].[Factor_Desc]))
      , [n].[Factor]
      , 1
      , isnull([n].[Processed_Priority_RAPS_Source_ID], [n].[Thru_Priority_RAPS_Source_ID]) --42124
      , isnull([n].[Processed_Priority_Provider_ID], [n].[Thru_Priority_Provider_ID])       --42124
      , [n].[AGED]
    from [#New_HCC_rollup] [n]

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '016'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    set @RollupSQL
        = '	
					UPDATE [n]
					   SET [n].[in_mor_max_month] = [t].[paymonth]
					  FROM [#new_hcc_output] [n]
					 INNER JOIN (SELECT [m].[HICN]
									  , [m].[Name] [hcc]
									  , MAX([m].[PayMonth]) [paymonth]
								   FROM ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
          + '.[dbo].[Converted_MOR_Data_rollup] [m]
								  WHERE LEFT([m].[PayMonth], 4) =' + @Payment_Year_NewDeleteHCC
          + 'GROUP BY [m].[HICN]
										 , [m].[Name]) [t]
						ON [n].[hicn] = [t].[HICN]
					   AND [t].[hcc]  = SUBSTRING([n].[hcc], 5, LEN([n].[hcc]))'

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '016.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    execute (@RollupSQL)

    -- Ticket # 25641

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '017'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    -- Ticket # 25641 Start
    if getdate() >= @Paymonth_MOR + '/1/' + @Payment_Year_NewDeleteHCC --- #43205 @PaymonthMOR instead of @PAYMO and change > to >=
    begin
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '018'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end


        set @RollupSQL
            = N'					
									UPDATE [n]
									   SET [n].[in_mor] = ''Y''
									  FROM [#new_hcc_output] [n]
									 INNER JOIN ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
              + '.[dbo].[Converted_MOR_Data_rollup] [v]
										ON [v].[Name] = [n].[hcc_No_Tags] -- add column in #new_hcc_output for the substring
									   AND [v].[HICN]  = [n].[hicn]
									   AND ( [v].[PayMonth]  >= ' + @Payment_Year_NewDeleteHCC + '+''' + @Paymonth_MOR
              + ''' AND [v].[PayMonth]  >= ''' + @Payment_Year_NewDeleteHCC
              + '''+ ''99'') 
									   AND CAST(SUBSTRING([v].[PayMonth], 1, 4) AS INT) = [n].[model_year]'

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '018.1'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
        /*#43205 @PaymonthMOR instead of @PAYMO
			      45817 Limiting for the max of PaymentYear+99  */

        execute (@RollupSQL)

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '019'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
    end
    -- before mid year update and @Payment_Year_NewDeleteHCC + '99' @Payment_Year_NewDeleteHCC + @Paymonth_MOR 
    else
    begin
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '020'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end



        set @RollupSQL
            = '  
                                          UPDATE [n]
                                             SET [n].[in_mor] = ''Y''
                                            FROM [#new_hcc_output] [n]
                                          INNER JOIN ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
              + '.[dbo].[Converted_MOR_Data_rollup] [v]
                                                ON [v].[Name]                                   = [n].[hcc_No_Tags]
                                             AND [v].[HICN]                                   = [n].[hicn]
                                             AND ( [v].[PayMonth]                              >= '
              + @Payment_Year_NewDeleteHCC + '' + '01'
              + '
                                                AND [v].[PayMonth]                             < '
              + @Payment_Year_NewDeleteHCC + @Paymonth_MOR
              + ')

							   AND CAST(SUBSTRING([v].[PayMonth], 1, 4) AS INT) = [n].[model_year]'

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '020.1'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
        --- #43205 @PaymonthMOR instead of @PAYMO

        execute (@RollupSQL)


        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '021'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
    end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '022'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    -- Ticket # 25641 End
    update [n]
    set [n].[in_mor] = 'N'
    from [#new_hcc_output] [n]
    where [n].[in_mor] is null

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '023'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end
    -- update Hierarchy

    set @RollupSQL
        = '	
					UPDATE        [HCCOP]
					   SET        [HCCOP].[hier_hcc_old] = [Hier].[HCC_DROP]
								, [HCCOP].[hier_factor_old] = [RskMod].[Factor]
					  --select *
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
											 AND [drp].[HCC_Number]                    = SUBSTRING([Hier].[HCC_KEEP], 4, LEN([Hier].[HCC_KEEP]) - 3)
											 AND [drp].[RAFT]                          = [HCCOP].[ra_factor_type]
											 AND [drp].[Model_Year]                    = [HCCOP].[model_year])
									 AND (      LEFT([RskMod].[Factor_Description], 3)       = ''HCC''
										OR      LEFT([RskMod].[Factor_Description], 3) = ''INT'')
									 AND (LEFT([Hier].[HCC_DROP], 3)                   = ''HCC'')
									 AND [RskMod].[Factor]                             > ISNULL([HCCOP].[hier_factor_old], 0)
									 AND LEFT([HCCOP].[hcc], 7)                        = ''DEL-HCC''
									 '
    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '023.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    execute (@RollupSQL)


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '024'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    update [n]
    set [n].[in_mor_max_month] = substring([n].[in_mor_max_month], 1, 4) + '12'
    from [#new_hcc_output] [n]
    where substring([n].[in_mor_max_month], 5, 2) = '99'

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '025'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    set @RollupSQL
        = 'INSERT INTO [#new_hcc_output] ([payment_year]
												 , [paymstart]
												 , [model_year]
												 , [processed_by_start]
												 , [processed_by_end]
												 , [in_mor]
												 , [in_mor_max_month]
												 , [planid]
												 , [hicn]
												 , [ra_factor_type]
												 , [hcc]
												 , [factor]
												 , [processed_priority_processed_by]
												 , [processed_priority_thru_date]
												 , [processed_priority_pcn]
												 , [processed_priority_diag]
												 , [thru_priority_processed_by]
												 , [thru_priority_thru_date]
												 , [thru_priority_pcn]
												 , [thru_priority_diag]
												 , [raps_source]
												 , [provider_id]
												 , [provider_last]
												 , [provider_first]
												 , [provider_group]
												 , [provider_address]
												 , [provider_city]
												 , [provider_state]
												 , [provider_zip]
												 , [provider_phone]
												 , [provider_fax]
												 , [tax_id]
												 , [npi]
												 , [AGED])
								SELECT DISTINCT [rps].[payment_year]
								  , [rps].[paymstart]
								  , [rps].[model_year]
								  ,''' + convert(varchar(10), @PROCESSBY_START, 101) + '''
								   ,''' + convert(varchar(10), @PROCESSBY_END, 101)
          + '''
								  , [rps].[in_mor]
								  , [rps].[in_mor_max_month]
								  , [rps].[planid]
								  , [rps].[hicn]
								  , [rps].[ra_factor_type]
								  , [rskmodintr].[Interaction_Label]
								  , [rm].[Factor]
								  , [rps].[processed_priority_processed_by]
								  , [rps].[processed_priority_thru_date]
								  , [rps].[processed_priority_pcn]
								  , [rps].[processed_priority_diag]
								  , [rps].[thru_priority_processed_by]
								  , [rps].[thru_priority_thru_date]
								  , [rps].[thru_priority_pcn]
								  , [rps].[thru_priority_diag]
								  , [rps].[raps_source]
								  , [rps].[provider_id]
								  , [rps].[provider_last]
								  , [rps].[provider_first]
								  , [rps].[provider_group]
								  , [rps].[provider_address]
								  , [rps].[provider_city]
								  , [rps].[provider_state]
								  , [rps].[provider_zip]
								  , [rps].[provider_phone]
								  , [rps].[provider_fax]
								  , [rps].[tax_id]
								  , [rps].[npi]
								  , [rps].[AGED]
					  FROM          [#new_hcc_output] [rps]
					 INNER JOIN  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
          + '.[dbo].[Raps_Accepted_rollup] [r]
						ON [rps].[hicn] = [r].[HICN]
					   AND SUBSTRING([rps].[in_mor_max_month], 1, 4) = YEAR([r].[ThruDate]) + 1
					 INNER JOIN     [#Vw_LkRiskModelsDiagHCC] [dh]
						ON [r].[DiagnosisCode]                       = [dh].[ICDCode] /*45816*/
					   AND [rps].[model_year]                        = [dh].[Payment_Year]
					   AND [r].[ThruDate] BETWEEN [dh].[StartDate] AND [dh].[EndDate] /*45816 */
					   AND [rps].[ra_factor_type]                    = [dh].[Factor_Type]
					 INNER JOIN     [$(HRPReporting)].[dbo].[lk_Risk_Models_Interactions] [rskmodintr]
						ON [rps].[ra_factor_type]                    = [rskmodintr].[Factor_Type]
					   AND [rps].[model_year]                        = [rskmodintr].[Payment_Year]
					 INNER JOIN     [$(HRPReporting)].[dbo].[lk_Risk_Models] [rm]
						ON [rps].[ra_factor_type]                    = [rm].[Factor_Type]
					   AND [rps].[model_year]                        = [rm].[Payment_Year]
					   AND [rskmodintr].[Interaction_Label]          = [rm].[Factor_Description]
					 WHERE          SUBSTRING([rps].[hcc], 5, LEN([rps].[hcc])) IN ([rskmodintr].[HCC_Label_1]
																				  , [rskmodintr].[HCC_Label_2]
																				  , [rskmodintr].[HCC_Label_3])
					   AND          [dh].[HCC_Label] IN ([rskmodintr].[HCC_Label_1], [rskmodintr].[HCC_Label_2]
													   , [rskmodintr].[HCC_Label_3])
					   AND          [rps].[in_mor] = ''Y''
					   AND          [rps].[hier_hcc_old] IS NULL '

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '025.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    execute (@RollupSQL)


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '026'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    update [n]
    set [n].[factor] = 0
    from [#new_hcc_output] [n]
    where [n].[factor] is null

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '027'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    set @RollupSQL
        = 'update n
	set n.months_in_dcp = mm.months_in_dcp,
		n.active_indicator_for_rollforward = (case when isnull(convert(varchar(12),m.max_paymstart,101),''N'') = ''N'' then ''N'' else ''Y'' end),
		n.esrd = (case when n.ra_factor_type in (select distinct ra_type from [$(HRPReporting)].dbo.lk_ra_factor_types where description like ''%dialysis%'' or description like ''%graft%'') then ''Y'' else ''N'' end),
		n.hosp = isnull(mmr.hosp,''N''),
		n.pbp = mmr.pbp,
		n.scc = mmr.scc,
		n.bid = isnull(b.ma_bid, b2.ma_bid)
	from #new_hcc_output n
	inner join ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
          + '.rev.tbl_Summary_RskAdj_MMR mmr on n.hicn = mmr.hicn and n.paymstart = mmr.paymstart
	left outer join ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB -- TFS 64782
          +   '.dbo.tbl_BIDS_rollup b on mmr.planid = b.planidentifier and mmr.pbp = b.pbp and mmr.scc = b.scc and b.bid_year = (case when year(getdate()) < '''
          + @Payment_Year_NewDeleteHCC + ''' then ' + cast(cast(@Payment_Year_NewDeleteHCC as int) - 1 as varchar(4))
          + ' else ''' + @Payment_Year_NewDeleteHCC + ''' end)
	left outer join ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
          + '.dbo.tbl_BIDS_rollup b2 on mmr.planid = b2.planidentifier and mmr.pbp = b2.pbp and b2.scc = ''OOA'' and b2.bid_year = (case when year(getdate()) < '''
          + @Payment_Year_NewDeleteHCC + ''' then ' + cast(cast(@Payment_Year_NewDeleteHCC as int) - 1 as varchar(4))
          + ' else ''' + @Payment_Year_NewDeleteHCC
          + ''' end)
	left outer join 	
		(select year(paymstart) paymyear, max(paymstart) max_paymstart
		from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
          + '.rev.tbl_Summary_RskAdj_MMR 
		group by year(paymstart)) m on year(n.paymstart) = m.paymyear and n.paymstart = m.max_paymstart
	left outer join 
		(select hicn, year(paymstart) paymyear, count(distinct paymstart) months_in_dcp 
		from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB -- TFS 64782
          +   '.dbo.tbl_member_months_rollup 
		group by hicn, year(paymstart)) mm on n.hicn = mm.hicn and year(n.paymstart)-1 = mm.paymyear
	left outer join 
		(select hicn, year(paymstart) paymyear, max(paymstart) max_paymstart
		from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
          + '.rev.tbl_Summary_RskAdj_MMR 
		group by hicn, year(paymstart)) mmm on n.hicn = mmm.hicn and year(n.paymstart) = mmm.paymyear and n.paymstart = mmm.max_paymstart'-- TFS 64782

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '027.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    exec (@RollupSQL)


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '028'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    --Fix ESRD rates - Ticket # 25188 Start
    update [n]
    set [n].[bid] = [esrd].[Rate]
    from [#new_hcc_output]                                 [n]
        inner join [$(HRPReporting)].[dbo].[lk_Ratebook_ESRD] [esrd]
            on [n].[scc] = [esrd].[Code]
    where [esrd].[PayMo] = @Payment_Year_NewDeleteHCC
          --and n.esrd = 'Y'
          and [n].[ra_factor_type] in ( 'D', 'ED', 'G1', 'G2' ) -- Ticket # 36970


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '029'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    --Fix ESRD rates - Ticket # 25188 End
    update [h]
    set [h].[hcc_description] = [f].[Description]
    from [#new_hcc_output]                                 [h]
        inner join [$(HRPReporting)].[dbo].[lk_Factors_PartC] [f]
            on substring([h].[hcc], 5, len([h].[hcc])) = [f].[HCC_Label]
    where [h].[ra_factor_type] in ( 'C', 'I', 'E', 'CF', 'CP', 'CN' ) -- TFS
          and [f].[payment_year] = @Payment_Year_NewDeleteHCC

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '030'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    update [h]
    set [h].[hcc_description] = [f].[Description]
    from [#new_hcc_output]                                 [h]
        inner join [$(HRPReporting)].[dbo].[lk_Factors_PartC] [f]
            on [h].[hcc] = [f].[HCC_Label]
    where [h].[ra_factor_type] in ( 'C', 'I', 'E', 'CF', 'CP', 'CN' )
          and [f].[payment_year] = @Payment_Year_NewDeleteHCC


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '031'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    update [h]
    set [h].[hcc_description] = [f].[Description]
    from [#new_hcc_output]                                 [h]
        inner join [$(HRPReporting)].[dbo].[lk_Factors_PartG] [f]
            on cast(substring([f].[HCC_Label], 4, len([f].[HCC_Label])) as int) = cast(substring(
                                                                                                    [h].[hcc]
                                                                                                  , 8
                                                                                                  , len([h].[hcc])
                                                                                                ) as int)
    where [h].[ra_factor_type] in ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          and [f].[payment_year] = @Payment_Year_NewDeleteHCC
          and substring([f].[HCC_Label], 1, 3) = 'hcc'


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '032'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    update [h]
    set [h].[hcc_description] = [f].[Description]
    from [#new_hcc_output]                                 [h]
        inner join [$(HRPReporting)].[dbo].[lk_Factors_PartC] [f]
            on [h].[hcc] = [f].[HCC_Label]
    where [h].[ra_factor_type] in ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          and [f].[payment_year] = @Payment_Year_NewDeleteHCC

    select @Coding_Intensity = [CodingIntensity]
    from [$(HRPReporting)].[dbo].[lk_normalization_factors]
    where [Year] = @Payment_Year_NewDeleteHCC


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '033'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    -- update bid and estimate
    update [HCCOP]
    set [HCCOP].[estimated_value] = isnull(
                                              ((round(
                                                         round(
                                                                  ([HCCOP].[factor]
                                                                   - isnull([HCCOP].[hier_factor_old], 0)
                                                                  )
                                                                  / [m].[PartCNormalizationFactor]
                                                                , 3
                                                              ) * (1 - @Coding_Intensity)
                                                       , 3
                                                     ) * ([HCCOP].[bid] * isnull([HCCOP].[member_months], 1))
                                               )
                                               * [SplitSegmentWeight]
                                              )
                                            , 0
                                          )
    from [#new_hcc_output]                                            [HCCOP]
        inner join [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] [m] --  TFS 71712  RE- 2264   modified by DW 06/21/18
            on [m].[ModelYear] = [HCCOP].[model_year]
               and [m].[PaymentYear] = [HCCOP].[payment_year]
               and [m].[RAFactorType] = [HCCOP].[ra_factor_type]
               and [m].[SubmissionModel] = 'RAPS'
    where isnull([HCCOP].[hosp], 'N') <> 'Y'
          and [HCCOP].[ra_factor_type] in ( 'C', 'CF', 'CP', 'CN' )



    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '034'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    update [HCCOP]
    set [HCCOP].[estimated_value] = case
                                        when [HCCOP].[ra_factor_type] = 'I' then
                                            isnull(
                                                      (round(
                                                                round(
                                                                         ([HCCOP].[factor]
                                                                          - isnull([HCCOP].[hier_factor_old], 0)
                                                                         )
                                                                         / ([nf].[PartC_Factor])
                                                                       , 3
                                                                     ) * (1 - @Coding_Intensity)
                                                              , 3
                                                            ) * ([HCCOP].[bid] * isnull([HCCOP].[member_months], 1))
                                                      )
                                                    , 0
                                                  )
                                        when [HCCOP].[ra_factor_type] in ( 'D', 'ED' ) then
                                            isnull(
                                                      (round(
                                                                ([HCCOP].[factor]
                                                                 - isnull([HCCOP].[hier_factor_old], 0)
                                                                )
                                                                / ([nf].[ESRD_Dialysis_Factor])
                                                              , 3
                                                            ) * ([HCCOP].[bid] * isnull([HCCOP].[member_months], 1))
                                                      )
                                                    , 0
                                                  )
                                        else
                                            isnull(
                                                      (round(
                                                                round(
                                                                         ([HCCOP].[factor]
                                                                          - isnull([HCCOP].[hier_factor_old], 0)
                                                                         )
                                                                         / ([nf].[FunctioningGraft_Factor])
                                                                       , 3
                                                                     ) * (1 - @Coding_Intensity)
                                                              , 3
                                                            ) * ([HCCOP].[bid] * isnull([HCCOP].[member_months], 1))
                                                      )
                                                    , 0
                                                  )
                                    end
    from [#new_hcc_output]                                         [HCCOP]
        inner join [$(HRPReporting)].[dbo].[lk_normalization_factors] [nf]
            on [nf].[Year] = @Payment_Year_NewDeleteHCC
    where isnull([HCCOP].[hosp], 'N') <> 'Y'
          and [HCCOP].[ra_factor_type] not in ( 'C', 'CF', 'CP', 'CN' )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '035'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    /*****************************************************************************************************************/


    if (object_id('tempdb.dbo.#ProviderId') is not null)
    begin
        drop table [#ProviderId]
    end


    create table [#ProviderId]
    (
        [Id] int identity(1, 1) primary key
      , [Provider_Id] varchar(40)
      , [Last_Name] varchar(55)
      , [First_Name] varchar(55)
      , [Group_Name] varchar(80)
      , [Contact_Address] varchar(100)
      , [Contact_City] varchar(30)
      , [Contact_State] char(2)
      , [Contact_Zip] varchar(13)
      , [Work_Phone] varchar(15)
      , [Work_Fax] varchar(15)
      , [Assoc_Name] varchar(55)
      , [NPI] varchar(10)
    )


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '036'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    set @SQL
        = '	INSERT  INTO [#ProviderId]
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
			FROM  ' + @Clnt_DB + '.[dbo].[tbl_provider_Unique] u
			ORDER BY
				u.[Provider_ID] '

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '036.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    exec (@SQL)


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '037'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end

    /************************************************************************************************/

    update [n]
    set [n].[provider_last] = [u].[Last_Name]
      , [n].[provider_first] = [u].[First_Name]
      , [n].[provider_group] = [u].[Group_Name]
      , [n].[provider_address] = [u].[Contact_Address]
      , [n].[provider_city] = [u].[Contact_City]
      , [n].[provider_state] = [u].[Contact_State]
      , [n].[provider_zip] = [u].[Contact_Zip]
      , [n].[provider_phone] = [u].[Work_Phone]
      , [n].[provider_fax] = [u].[Work_Fax]
      , [n].[tax_id] = [u].[Assoc_Name]
      , [n].[npi] = [u].[NPI]
    from [#new_hcc_output]       [n]
        inner join [#ProviderId] [u]
            on [n].[provider_id] = [u].[Provider_Id]

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '038'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    if object_id('[TEMPDB].[DBO].[#rollforward_months]', 'U') is not null
        drop table [dbo].[#rollforward_months]

    create table [dbo].[#rollforward_months]
    (
        [hicn] varchar(15)
      , [member_months] int
    )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '039'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end
    insert into [#rollforward_months]
    (
        [hicn]
      , [member_months]
    )
    select [hicn]
         , [member_months] = count(distinct [paymstart])
    from [#new_hcc_output]
    group by [hicn]



    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '040'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    declare @rollforward int = (
                                   select max([member_months]) from [#rollforward_months]
                               )

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '040.1'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end
    -- TFS 58118  "R" Parameter for insert output into ERDeleteHCCOutput table 
    if @ReportOutputByMonth = 'R'
    begin

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '041'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        set @SQL
            = 'DELETE [m1]
                              FROM ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
              + '.[rev].[ERDeleteHCCOutput] [m1] Where PaymentYear = ''' + @Payment_Year_NewDeleteHCC + ''''

        execute (@SQL)


        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '046'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end


        insert into [rev].[ERDeleteHCCOutput]
        (
            [Paymentyear]
          , [Modelyear]
          , [ProcessedbyStart]
          , [ProcessedbyEnd]
          , [ProcessedbyFlag]
          , [InMOR]
          , [PlanID]
          , [HICN]
          , [RAFactorType]
          , [HCC]
          , [HCCDescription]
          , [Factor]
          , [HIERHCCOld]
          , [HIERFactorOld]
          , [MemberMonths]
          , [BID]
          , [EstimatedValue]
          , [RollforwardMonths]
          , [AnnualizedEstimatedValue]
          , [MonthsinDCP]
          , [ESRD]
          , [HOSP]
          , [PBP]
          , [SCC]
          , [ProcessedPriorityProcessedby]
          , [ProcessedPriorityThrudate]
          , [ProcessedPriorityPCN]
          , [ProcessedPriorityDiag]
          , [ThruPriorityProcessedby]
          , [ThruPriorityThruDate]
          , [ThruPriorityPCN]
          , [ThruPriorityDiag]
          , [RAPSSource]
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
        )
        select [n].[payment_year]
             , [n].[model_year]
             , [n].[processed_by_start]
             , [n].[processed_by_end]
             , [processed_by_flag]          = case
                                                  when [n].[processed_priority_processed_by]
                                                       between @fromdate and @initial_flag then
                                                      'I'
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                      case
                                                          when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                    + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                          + '/01/'
                                                                                                                          + @Payment_Year_NewDeleteHCC then
                                                              'F'
                                                          else
                                                              'M'
                                                      end --#43205 Change to >= 08 with Variable
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                      'F'
                                              end
             , [n].[in_mor]
             , [n].[planid]
             , [n].[hicn]
             , [n].[ra_factor_type]
             , [n].[hcc]
             , [n].[hcc_description]
             , [factor]                     = isnull([n].[factor], 0)
             , [n].[hier_hcc_old]
             , [hier_factor_old]            = isnull([n].[hier_factor_old], 0)
             , [member_months]              = count(distinct [n].[paymstart])
             , [bid]                        = isnull([n].[bid], 0)
             , [estimated_value]            = isnull(sum([n].[estimated_value]), 0) * -1
             , [rollforward_months]         = case
                                                  when [r].[member_months] = @rollforward then
                                                      12 - [r].[member_months]
                                                  else
                                                      0
                                              end
             , [annualized_estimated_value] = isnull(
                                                        sum([n].[estimated_value])
                                                        + (case
                                                               when [r].[member_months] = @rollforward then
                                                                   12 - [r].[member_months]
                                                               else
                                                                   0
                                                           end * (sum([n].[estimated_value]) / [r].[member_months])
                                                          )
                                                      , 0
                                                    ) * -1
             , [months_in_dcp]              = isnull([n].[months_in_dcp], 0)
             , [esrd]                       = isnull([n].[esrd], 'N')
             , [hosp]                       = isnull([n].[hosp], 'N')
             , [n].[pbp]
             , [scc]                        = isnull([n].[scc], 'OOA')
             , [n].[processed_priority_processed_by]
             , [n].[processed_priority_thru_date]
             , [n].[processed_priority_pcn]
             , [n].[processed_priority_diag]
             , [n].[thru_priority_processed_by]
             , [n].[thru_priority_thru_date]
             , [n].[thru_priority_pcn]
             , [n].[thru_priority_diag]
             , [n].[raps_source]
             , [n].[provider_id]
             , [n].[provider_last]
             , [n].[provider_first]
             , [n].[provider_group]
             , [n].[provider_address]
             , [n].[provider_city]
             , [n].[provider_state]
             , [n].[provider_zip]
             , [n].[provider_phone]
             , [n].[provider_fax]
             , [n].[tax_id]
             , [n].[npi]
             , [SWEEP_DATE]                 = case
                                                  when [n].[processed_priority_processed_by]
                                                       between @fromdate and @initial_flag then
                                                      @initial_flag
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                      case
                                                          when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                    + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                          + '/01/'
                                                                                                                          + @Payment_Year_NewDeleteHCC then
                                                              @final_flag
                                                          else
                                                              @myu_flag
                                                      end --#43205 Change to >= 08 with Variable
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                      @final_flag
                                              end
             , [populated_date]             = getdate()
             , [AgedStatus]                 = case
                                                  when [n].[AGED] = 1 then
                                                      'Aged'
                                                  when [n].[AGED] = 0 then
                                                      'Disabled'
                                                  else
                                                      'Not Applicable'
                                              end
        from [#new_hcc_output]               [n]
            inner join [#rollforward_months] [r]
                on [n].[hicn] = [r].[hicn]
        where (
                  [n].[processed_priority_processed_by]
              between @PROCESSBY_START and @PROCESSBY_END
                  or (
                         cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                              + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                    + @Payment_Year_NewDeleteHCC --#43205 Change to >= 08 with Variable
                         and [n].[processed_priority_processed_by]
              between dateadd(dd, 1, @initial_flag) and @myu_flag
                     )
              )
              and [n].[hcc] not like 'HIER%'
        group by [n].[payment_year]
               , [n].[model_year]
               , [n].[processed_by_start]
               , [n].[processed_by_end]
               , [n].[planid]
               , [n].[in_mor]
               , [n].[hicn]
               , [n].[ra_factor_type]
               , [n].[hcc]
               , [n].[hcc_description]
               , [n].[factor]
               , [n].[hier_hcc_old]
               , [n].[hier_factor_old]
               , [n].[bid]
               , [r].[member_months]
               , [n].[months_in_dcp]
               , [n].[esrd]
               , [n].[hosp]
               , [n].[pbp]
               , [n].[scc]
               , [n].[processed_priority_processed_by]
               , [n].[processed_priority_thru_date]
               , [n].[processed_priority_pcn]
               , [n].[processed_priority_diag]
               , [n].[thru_priority_processed_by]
               , [n].[thru_priority_thru_date]
               , [n].[thru_priority_pcn]
               , [n].[thru_priority_diag]
               , [n].[raps_source]
               , [n].[provider_id]
               , [n].[provider_last]
               , [n].[provider_first]
               , [n].[provider_group]
               , [n].[provider_address]
               , [n].[provider_city]
               , [n].[provider_state]
               , [n].[provider_zip]
               , [n].[provider_phone]
               , [n].[provider_fax]
               , [n].[tax_id]
               , [n].[npi]
               , [n].[in_mor_max_month]
               , case
                     when [n].[processed_priority_processed_by]
                          between @fromdate and @initial_flag then
                         @initial_flag
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @initial_flag) and @myu_flag then
                         case
                             when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                       + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                             + @Payment_Year_NewDeleteHCC then
                                 @final_flag
                             else
                                 @myu_flag
                         end --#43205 Change to >= 08 with Variable
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @myu_flag) and @final_flag then
                         @final_flag
                 end
               , [n].[AGED]

SET @RowCount = Isnull(@@ROWCOUNT,0);

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '047'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

    end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '048'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    if @ReportOutputByMonth = 'S'
    --- Start #43205  change '6' to '8' for Payment year 2015
    begin
        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '049'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        select [n].[payment_year]
             , [n].[model_year]
             , [n].[processed_by_start]
             , [n].[processed_by_end]
             , [processed_by_flag]          = case
                                                  when [n].[processed_priority_processed_by]
                                                       between @fromdate and @initial_flag then
                                                      'I'
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                      case
                                                          when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                    + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                          + '/01/'
                                                                                                                          + @Payment_Year_NewDeleteHCC then
                                                              'F'
                                                          else
                                                              'M'
                                                      end --#43205 Change to >= 08 with Variable
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                      'F'
                                              end
             , [n].[in_mor]
             , [n].[planid]
             , [n].[hicn]
             , [n].[ra_factor_type]
             , [n].[hcc]
             , [n].[hcc_description]
             , [factor]                     = isnull([n].[factor], 0)
             , [n].[hier_hcc_old]
             , [hier_factor_old]            = isnull([n].[hier_factor_old], 0)
             , [member_months]              = count(distinct [n].[paymstart])
             , [bid]                        = isnull([n].[bid], 0)
             , [estimated_value]            = isnull(sum([n].[estimated_value]), 0) * -1
             , [rollforward_months]         = case
                                                  when [r].[member_months] = @rollforward then
                                                      12 - [r].[member_months]
                                                  else
                                                      0
                                              end
             , [annualized_estimated_value] = isnull(
                                                        sum([n].[estimated_value])
                                                        + (case
                                                               when [r].[member_months] = @rollforward then
                                                                   12 - [r].[member_months]
                                                               else
                                                                   0
                                                           end * (sum([n].[estimated_value]) / [r].[member_months])
                                                          )
                                                      , 0
                                                    ) * -1
             , [months_in_dcp]              = isnull([n].[months_in_dcp], 0)
             , [esrd]                       = isnull([n].[esrd], 'N')
             , [hosp]                       = isnull([n].[hosp], 'N')
             , [n].[pbp]
             , [scc]                        = isnull([n].[scc], 'N')
             , [SWEEP_DATE]                 = case
                                                  when [n].[processed_priority_processed_by]
                                                       between @fromdate and @initial_flag then
                                                      @initial_flag
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                      case
                                                          when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                    + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                          + '/01/'
                                                                                                                          + @Payment_Year_NewDeleteHCC then
                                                              @final_flag
                                                          else
                                                              @myu_flag
                                                      end --#43205 Change to >= 08 with Variable
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                      @final_flag
                                              end
             , [populated_date]             = getdate()
             , [AgedStatus]                 = case
                                                  when [n].[AGED] = 1 then
                                                      'Aged'
                                                  when [n].[AGED] = 0 then
                                                      'Disabled'
                                                  else
                                                      'Not Applicable'
                                              end
        from [#new_hcc_output]               [n]
            inner join [#rollforward_months] [r]
                on [n].[hicn] = [r].[hicn]
        where (
                  [n].[processed_priority_processed_by]
              between @PROCESSBY_START and @PROCESSBY_END
                  or (
                         cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                              + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                    + @Payment_Year_NewDeleteHCC --#43205 Change to >= 08 with Variable
                         and [n].[processed_priority_processed_by]
              between dateadd(dd, 1, @initial_flag) and @myu_flag
                     )
              )
              and [n].[hcc] not like 'HIER%'
        group by [n].[payment_year]
               , [n].[model_year]
               , [n].[processed_by_start]
               , [n].[processed_by_end]
               , case
                     when [n].[processed_priority_processed_by]
                          between @fromdate and @initial_flag then
                         'I'
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @initial_flag) and @myu_flag then
                         case
                             when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                       + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                             + @Payment_Year_NewDeleteHCC then
                                 'F'
                             else
                                 'M'
                         end --#43205 Change to >= 08 with Variable
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @myu_flag) and @final_flag then
                         'F'
                 end
               , [n].[planid]
               , [n].[in_mor]
               , [n].[hicn]
               , [n].[ra_factor_type]
               , [n].[hcc]
               , [n].[hcc_description]
               , [n].[factor]
               , [n].[hier_hcc_old]
               , [n].[hier_factor_old]
               , [n].[bid]
               , [r].[member_months]
               , [n].[months_in_dcp]
               , [n].[esrd]
               , [n].[hosp]
               , [n].[pbp]
               , [n].[scc]
               , case
                     when [n].[processed_priority_processed_by]
                          between @fromdate and @initial_flag then
                         @initial_flag
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @initial_flag) and @myu_flag then
                         case
                             when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                       + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                             + @Payment_Year_NewDeleteHCC then
                                 @final_flag
                             else
                                 @myu_flag
                         end --#43205 Change to >= 08 with Variable
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @myu_flag) and @final_flag then
                         @final_flag
                 end
               , [n].[AGED]
        order by [n].[hicn]
               , [n].[hcc]
               , [n].[model_year]


        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '050'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

    end

    --- END #43205  change '6' to '8' for Payment year 2015
    if @ReportOutputByMonth = 'D'
    --- Start #43205  change '6' to '8' for Payment year 2015
    begin

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '051'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        select [n].[payment_year]
             , [n].[model_year]
             , [n].[processed_by_start]
             , [n].[processed_by_end]
             , [processed_by_flag]          = case
                                                  when [n].[processed_priority_processed_by]
                                                       between @fromdate and @initial_flag then
                                                      'I'
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                      case
                                                          when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                    + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                          + '/01/'
                                                                                                                          + @Payment_Year_NewDeleteHCC then
                                                              'F'
                                                          else
                                                              'M'
                                                      end --#43205 Change to >= 08 with Variable
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                      'F'
                                              end
             , [n].[in_mor]
             , [n].[planid]
             , [n].[hicn]
             , [n].[ra_factor_type]
             , [n].[hcc]
             , [n].[hcc_description]
             , [factor]                     = isnull([n].[factor], 0)
             , [n].[hier_hcc_old]
             , [hier_factor_old]            = isnull([n].[hier_factor_old], 0)
             , [member_months]              = count(distinct [n].[paymstart])
             , [bid]                        = isnull([n].[bid], 0)
             , [estimated_value]            = isnull(sum([n].[estimated_value]), 0) * -1
             , [rollforward_months]         = case
                                                  when [r].[member_months] = @rollforward then
                                                      12 - [r].[member_months]
                                                  else
                                                      0
                                              end
             , [annualized_estimated_value] = isnull(
                                                        sum([n].[estimated_value])
                                                        + (case
                                                               when [r].[member_months] = @rollforward then
                                                                   12 - [r].[member_months]
                                                               else
                                                                   0
                                                           end * (sum([n].[estimated_value]) / [r].[member_months])
                                                          )
                                                      , 0
                                                    ) * -1
             , [months_in_dcp]              = isnull([n].[months_in_dcp], 0)
             , [esrd]                       = isnull([n].[esrd], 'N')
             , [hosp]                       = isnull([n].[hosp], 'N')
             , [n].[pbp]
             , [scc]                        = isnull([n].[scc], 'OOA')
             , [n].[processed_priority_processed_by]
             , [n].[processed_priority_thru_date]
             , [n].[processed_priority_pcn]
             , [n].[processed_priority_diag]
             , [n].[thru_priority_processed_by]
             , [n].[thru_priority_thru_date]
             , [n].[thru_priority_pcn]
             , [n].[thru_priority_diag]
             , [n].[raps_source]
             , [n].[provider_id]
             , [n].[provider_last]
             , [n].[provider_first]
             , [n].[provider_group]
             , [n].[provider_address]
             , [n].[provider_city]
             , [n].[provider_state]
             , [n].[provider_zip]
             , [n].[provider_phone]
             , [n].[provider_fax]
             , [n].[tax_id]
             , [n].[npi]
             , [SWEEP_DATE]                 = case
                                                  when [n].[processed_priority_processed_by]
                                                       between @fromdate and @initial_flag then
                                                      @initial_flag
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                      case
                                                          when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                    + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                          + '/01/'
                                                                                                                          + @Payment_Year_NewDeleteHCC then
                                                              @final_flag
                                                          else
                                                              @myu_flag
                                                      end --#43205 Change to >= 08 with Variable
                                                  when [n].[processed_priority_processed_by]
                                                       between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                      @final_flag
                                              end
             , [populated_date]             = getdate()
             , [AgedStatus]                 = case
                                                  when [n].[AGED] = 1 then
                                                      'Aged'
                                                  when [n].[AGED] = 0 then
                                                      'Disabled'
                                                  else
                                                      'Not Applicable'
                                              end
        from [#new_hcc_output]               [n]
            inner join [#rollforward_months] [r]
                on [n].[hicn] = [r].[hicn]
        where (
                  [n].[processed_priority_processed_by]
              between @PROCESSBY_START and @PROCESSBY_END
                  or (
                         cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                              + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                    + @Payment_Year_NewDeleteHCC --#43205 Change to >= 08 with Variable
                         and [n].[processed_priority_processed_by]
              between dateadd(dd, 1, @initial_flag) and @myu_flag
                     )
              )
              and [n].[hcc] not like 'HIER%'
        group by [n].[payment_year]
               , [n].[model_year]
               , [n].[processed_by_start]
               , [n].[processed_by_end]
               , [n].[planid]
               , [n].[in_mor]
               , [n].[hicn]
               , [n].[ra_factor_type]
               , [n].[hcc]
               , [n].[hcc_description]
               , [n].[factor]
               , [n].[hier_hcc_old]
               , [n].[hier_factor_old]
               , [n].[bid]
               , [r].[member_months]
               , [n].[months_in_dcp]
               , [n].[esrd]
               , [n].[hosp]
               , [n].[pbp]
               , [n].[scc]
               , [n].[processed_priority_processed_by]
               , [n].[processed_priority_thru_date]
               , [n].[processed_priority_pcn]
               , [n].[processed_priority_diag]
               , [n].[thru_priority_processed_by]
               , [n].[thru_priority_thru_date]
               , [n].[thru_priority_pcn]
               , [n].[thru_priority_diag]
               , [n].[raps_source]
               , [n].[provider_id]
               , [n].[provider_last]
               , [n].[provider_first]
               , [n].[provider_group]
               , [n].[provider_address]
               , [n].[provider_city]
               , [n].[provider_state]
               , [n].[provider_zip]
               , [n].[provider_phone]
               , [n].[provider_fax]
               , [n].[tax_id]
               , [n].[npi]
               , [n].[in_mor_max_month]
               , case
                     when [n].[processed_priority_processed_by]
                          between @fromdate and @initial_flag then
                         @initial_flag
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @initial_flag) and @myu_flag then
                         case
                             when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                       + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                             + @Payment_Year_NewDeleteHCC then
                                 @final_flag
                             else
                                 @myu_flag
                         end --#43205 Change to >= 08 with Variable
                     when [n].[processed_priority_processed_by]
                          between dateadd(dd, 1, @myu_flag) and @final_flag then
                         @final_flag
                 end
               , [n].[AGED]
        order by [n].[hicn]
               , [n].[hcc]
               , [n].[model_year]


        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '052'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
    end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '053'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0
    end


    --- END #43205  change '6' to '8' for Payment year 2015
    --- Start #43205  change '6' to '8' for Payment year 2015
    if @ReportOutputByMonth = 'M'
    begin

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '054'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end

        select [n].[payment_year]
             , [n].[model_year]
             -- Added Model Year - Ticket # 25188
             , [n].[paymstart]
             , [n].[processed_by_start]
             , [n].[processed_by_end]
             , [n].[planid]
             , [n].[hicn]
             , [n].[ra_factor_type]
             , [n].[processed_priority_processed_by]
             , [n].[processed_priority_thru_date]
             , [n].[processed_priority_pcn]
             , [n].[processed_priority_diag]
             , [n].[thru_priority_processed_by]
             , [n].[thru_priority_thru_date]
             , [n].[thru_priority_pcn]
             , [n].[thru_priority_diag]
             , [n].[in_mor]
             , [n].[hcc]
             , [n].[hcc_description]
             , [FACTOR]                           = isnull([n].[factor], 0)
             , [n].[hier_hcc_old]
             , [HIER_FACTOR_OLD]                  = isnull([n].[hier_factor_old], 0)
             , [active_indicator_for_rollforward] = isnull([n].[active_indicator_for_rollforward], 'N')
             , [MONTHS_IN_DCP]                    = isnull([n].[months_in_dcp], 0)
             , [ESRD]                             = isnull([n].[esrd], 'N')
             , [HOSP]                             = isnull([n].[hosp], 'N')
             , [n].[pbp]
             , [SCC]                              = isnull([n].[scc], 'OOA')
             , [BID]                              = isnull([n].[bid], 0)
             , [ESTIMATED_VALUE]                  = isnull([n].[estimated_value], 0) * -1
             , [n].[raps_source]
             , [n].[provider_id]
             , [n].[provider_last]
             , [n].[provider_first]
             , [n].[provider_group]
             , [n].[provider_address]
             , [n].[provider_city]
             , [n].[provider_state]
             , [n].[provider_zip]
             , [n].[provider_phone]
             , [n].[provider_fax]
             , [n].[tax_id]
             , [n].[npi]
             , [SWEEP_DATE]                       = case
                                                        when [n].[processed_priority_processed_by]
                                                             between @fromdate and @initial_flag then
                                                            @initial_flag
                                                        when [n].[processed_priority_processed_by]
                                                             between dateadd(dd, 1, @initial_flag) and @myu_flag then
                                                            case
                                                                when cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                                                                          + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR
                                                                                                                                + '/01/'
                                                                                                                                + @Payment_Year_NewDeleteHCC then
                                                                    @final_flag
                                                                else
                                                                    @myu_flag
                                                            end --#43205 Change to >= 08 with Variable
                                                        when [n].[processed_priority_processed_by]
                                                             between dateadd(dd, 1, @myu_flag) and @final_flag then
                                                            @final_flag
                                                    end
             , [AgedStatus]                       = case
                                                        when [n].[AGED] = 1 then
                                                            'Aged'
                                                        when [n].[AGED] = 0 then
                                                            'Disabled'
                                                        else
                                                            'Not Applicable'
                                                    end
        from [#new_hcc_output] [n]
        where (
                  [n].[processed_priority_processed_by]
              between @PROCESSBY_START and @PROCESSBY_END
                  or (
                         cast(substring([n].[in_mor_max_month], 5, 2) + '/01/'
                              + substring([n].[in_mor_max_month], 1, 4) as date) >= @Paymonth_MOR + '/01/'
                                                                                    + @Payment_Year_NewDeleteHCC --#43205 Change to >= 08 with Variable
                         and [n].[processed_priority_processed_by]
              between dateadd(dd, 1, @initial_flag) and @myu_flag
                     )
              )
              and [n].[hcc] not like 'HIER%'
        order by [n].[hicn]
               , [n].[hcc]
               , [n].[paymstart]
               , [n].[AGED]


        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] '055'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET out
                                      , 0
                                      , 0
        end
    end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '056'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 0

    end


    drop table [#RollupPlan]
    drop table [#new_hcc_output]
    drop table [#ProviderId]
    drop table [#New_HCC_rollup]

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] '057'
                                  , @ProcessNameIn
                                  , @ET
                                  , @MasterET
                                  , @ET out
                                  , 0
                                  , 1

    end

end
--- END #43205  change '6' to '8' for Payment year 2015
if @Debug = 1
begin
    print '@Clnt_Rpt_DB = ' + isnull(@Clnt_Rpt_DB, '')
    print '@ClntPlan_DB = ' + isnull(@ClntPlan_DB, '')
    print '@Clnt_Rpt_Srv = ' + isnull(@Clnt_Rpt_Srv, '')
    print '@Clnt_DB = ' + isnull(@Clnt_DB, '')
    print '@ClntName = ' + isnull(@ClntName, '')
end
--- END #43205  change '6' to '8' for Payment year 2015
