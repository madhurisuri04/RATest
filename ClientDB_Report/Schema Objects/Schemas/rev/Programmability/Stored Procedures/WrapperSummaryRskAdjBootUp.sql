CREATE PROCEDURE [rev].[WrapperSummaryRskAdjBootUp]
    @YearRefresh int = null
  , @ForceAltHICN bit = 0
  , @ForceMMR bit = 0
  , @ForceMOR bit = 0
  , @ForceRAPS bit = 0
  , @ForceEDS bit = 0
  , @Debug bit = 0
as --
/************************************************************************************************************/
/* Name				:	[rev].[WrapperSummaryRskAdjBootUp]     	    						*/
/* Type 			:	Stored Procedure																	*/
/* Author       	:   Madhuri Suri    																	*/
/* Date				:	2/26/2018																			*/
/* Version			:																						*/
/* Description		:	Wrapper procedure invokes the Summary 2.0 modules   								*/
/*																											*/
/* Version History :																						*/
/* =================																						*/
/* Author				Date		Version#    TFS Ticket#		Description								    */
/* -----------------	----------  --------    -----------		------------								*/
/*  D. Waddell           6/07/2018    1.1        71385           Add Activity Log Entry called "Boot        */
/*                                                               Up Summary Process". (Section 001,005)     */
/* Anand				 2019-07-26	  1.2		RE - 5112		 Added Src flag                             */
/* Madhuri Suri			 2021-1-21    1.3       RRI-290/80000    Remove EDS Src Reference/Store Proc        */
/************************************************************************************************************/
begin
    set nocount on

    /*B Initialize Activity Logging */
    declare @tbl_Summary_RskAdj_ActivityIdMain int = (
                                                         select max(GroupingId) from rev.[tbl_Summary_RskAdj_Activity]
                                                     )


    insert into [rev].[tbl_Summary_RskAdj_Activity]
    (
        [GroupingId]
      , [Process]
      , [BDate]
      , [EDate]
      , [AdditionalRows]
      , [RunBy]
    )
    select [GroupingId]     = null
         , [Process]        = 'Boot Up Summary Process'
                              + case
                                    when @YearRefresh is not null then
                                        ' (PY ' + ltrim(rtrim(cast(@YearRefresh as varchar(11)))) + ' Only)'
                                    else
                                        ''
                                end
         , [BDate]          = getdate()
         , [EDate]          = null
         , [AdditionalRows] = null
         , [RunBy]          = user_name()

    set @tbl_Summary_RskAdj_ActivityIdMain = scope_identity()

    update [m]
    set [m].[GroupingId] = @tbl_Summary_RskAdj_ActivityIdMain
    from [rev].[tbl_Summary_RskAdj_Activity] [m]
    where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain

    /*E Initialize Activity Logging */

    /* B Initialize Performance Logging  */
    if @Debug = 1
    begin
        -- SET STATISTICS IO ON
        declare @Mode tinyint
        declare @ET datetime
        declare @MasterET datetime
        declare @ProcessNameIn varchar(128)
        declare @MOR_LastUpdated datetime = null
        declare @MMR_LastUpdated datetime = null
        declare @AltHICN_LastUpdated datetime = null
        declare @RAPS_LastUpdated datetime = null
        declare @EDS_LastUpdated datetime = null
        declare @EDSloaddateSQL varchar(max);
        declare @EDSloaddate datetime;
        declare @BBusinessHours tinyint
        declare @EBusinessHours tinyint

        /*B Identify tables to be changed*/
        declare @MMR_FLAG  bit = @ForceMMR
              , @ALT_HICN  bit = @ForceAltHICN
              , @MOR_FLAG  bit = @ForceMOR
              , @RAPS_FLAG bit = @ForceRAPS
              , @EDS_FLAG  bit = @ForceEDS

        set @ET = getdate()
        set @MasterET = @ET
        set @ProcessNameIn = object_name(@@procid)

        exec [dbo].[PerfLogMonitor] @Section = '000'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] @Section = '001'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end

    /*
      Step 01
      Populates [rev].[tbl_Summary_RskAdj_RefreshPY]
      */

    exec [rev].[spr_Summary_RskAdj_RefreshPY] @FullRefresh = 0
                                            , @YearRefresh = @YearRefresh
                                            , @Debug = 0

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] @Section = '002'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end
    /*
      Step 02
      Populates rev.SummaryProcessRunFlag
      */
    exec [rev].SummaryRskAdjRefreshRunflag @ForceAltHICN
                                         , @ForceMMR
                                         , @ForceMOR
                                         , @ForceRAPS
                                         , @ForceEDS
                                         , @Debug = 0


    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] @Section = '003'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end


    /*
      Step 03
      Populates Alt HICN and MMR
      */
    exec [rev].WrapperSummaryAltHICNMMR @Debug

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] @Section = '004'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] @Section = '005'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end

/*B Update Activity Logging  */

    update [m]
    set [m].[EDate] = getdate()
    from [rev].[tbl_Summary_RskAdj_Activity] [m]
    where [m].[tbl_Summary_RskAdj_ActivityId] = @tbl_Summary_RskAdj_ActivityIdMain
          and [Process] like 'Boot Up Summary Process%'

/*E Update Activity Logging */



end
GO


