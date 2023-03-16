CREATE PROCEDURE [rev].[SummaryRskAdjRefreshRunflag]
    @ALT_HICN bit = 0
  , @MMR_FLAG bit = 0
  , @MOR_FLAG bit = 0
  , @RAPS_FLAG bit = 0
  , @EDS_FLAG bit = 0
  , @Debug bit = 0
as
 /************************************************************************************************* 
* Name			:	rev.SummaryRskAdjRefreshRunflag								      				*
* Type 			:	Stored Procedure																*
* Author       	:	Madhuri Suri																	*
* Date			:	2018-2-12																		*
* Version			:																				*
* Description		: Updates the Refresh Run Flag in the Summary Rsk Adj table                     *
*						process																		*
*																									*
* Version History :																					*
* =================================================================================================	*
* Author			Date		Version#    TFS Ticket#		Description								*
* -----------------	----------  --------    -----------		------------							*
* Madhuri Suri		2018-02-17	1.0			     			Initial									*
* David Waddell		2018-05-16	1.1			71185/RE-2024	Part C Summary 2.0 - fix for Manual     *
*                                                           functionality (Section 001)  			*
* Madhuri Suri		2018-07-25	1.2			72182  			AltHICN spell correction and fixing  
                                                                                    force MOR issue *
* Anand 				2019-08-09  1.3      RE - 5112		Included EDS Src in Summary Process		*																	*
* Madhuri Suri      2018-09-24  2.0         76879           Summary 2.5 Changes                     *
* Madhuri Suri      2018-09-24  2.1         77181           Summary 2.5 Changes - 2                 *
* David Waddell     2020-05-21  2.2         78687/RE-8112   Correct Summary Refresh Flag Isue       *
* Madhuri Suri      2021-1-21   2.3         RRI-290/80000   Remove EDS Src Reference/Store Proc     *
*****************************************************************************************************/


  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

begin
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
	--declare @EDSSrc_LastUpdated datetime = null; -- RE - 5112

    /* E Initialize Performance Logging   */

    /*B Get table driven configuration variables */
    declare @Mode tinyint
    declare @BBusinessHours tinyint
    declare @EBusinessHours tinyint
    declare @DeleteBatchAltHICN int
    declare @DeleteBatchMMR int
    declare @DeleteBatchMOR int
    declare @DeleteBatchRAPS_Preliminary int
    declare @DeleteBatchRAPS int
    declare @DeleteBatchRAPS_MOR_Combined int
    declare @DeleteBatchEDS_Preliminary int
    declare @DeleteBatchEDS int
    declare @RowCount_OUT int = 0
    declare @AltHICN_RowCount int = 0
    declare @MMR_RowCount int = 0
    declare @MOR_RowCount int = 0
    declare @RAPS_RowCount int = 0
    declare @EDS_RowCount int = 0
    declare @Curr_DB varchar(128) = null;
    declare @Clnt_DB varchar(128) = null;

    set @Curr_DB =
    (
        select [Current Database] = db_name()
    )
    set @Clnt_DB = substring(@Curr_DB, 0, charindex('_Report', @Curr_DB))

    set @MMR_LastUpdated =
    (
        select max([EDate])
        from [rev].[tbl_Summary_RskAdj_Activity]
        where [Process] = '[rev].[spr_Summary_RskAdj_MMR]'
    )

    set @MMR_LastUpdated = isnull((@MMR_LastUpdated), dateadd(dd, -1, getdate()))

    set @MOR_LastUpdated =
    (
        select max([EDate])
        from [rev].[tbl_Summary_RskAdj_Activity]
        where [Process] = '[rev].[spr_Summary_RskAdj_MOR]'
    )

    set @MOR_LastUpdated = isnull((@MOR_LastUpdated), dateadd(dd, -1, getdate()))


    set @AltHICN_LastUpdated =
    (
        select max([EDate])
        from [rev].[tbl_Summary_RskAdj_Activity]
        where [Process] = '[rev].[spr_Summary_RskAdj_AltHICN]'
    )

    set @AltHICN_LastUpdated = isnull((@AltHICN_LastUpdated), dateadd(dd, -1, getdate()))


    set @RAPS_LastUpdated =
    (
        select max([EDate])
        from [rev].[tbl_Summary_RskAdj_Activity]
        where [Process] = '[rev].[spr_Summary_RskAdj_RAPS]'
    )

    set @RAPS_LastUpdated = isnull((@RAPS_LastUpdated), dateadd(dd, -1, getdate()))

--RE - 5112 - Commented the below EDS part.

 --   set @EDS_LastUpdated =
 --   (
 --       select max([EDate])
 --       from [rev].[tbl_Summary_RskAdj_Activity]
 --       where [Process] = '[rev].[spr_Summary_RskAdj_EDS]'
 --   )

	--set @EDS_LastUpdated = isnull((@EDS_LastUpdated), dateadd(dd, -1, getdate()))

	--RE - 5112

	--set @EDSSrc_LastUpdated =
 --   (
 --       select max([EDate])
 --       from [rev].[tbl_Summary_RskAdj_Activity]
 --       where [Process] = '[rev].[spr_Summary_RskAdj_EDS_Source]'
 --   )

	--set @EDSSrc_LastUpdated = isnull((@EDSSrc_LastUpdated), '1900-01-01') 


    select top 1
        @Mode = cast([a1].[Value] as tinyint)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@Mode'

    select top 1
        @BBusinessHours = cast([a1].[Value] as tinyint)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@BBusinessHours'

    select top 1
        @EBusinessHours = cast([a1].[Value] as tinyint)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@EBusinessHours'

    select top 1
        @DeleteBatchAltHICN = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchAltHICN'

    select top 1
        @DeleteBatchMMR = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchMMR'

    select top 1
        @DeleteBatchMOR = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchMOR'

    select top 1
        @DeleteBatchRAPS_Preliminary = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchRAPS_Preliminary'

    select top 1
        @DeleteBatchRAPS = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchRAPS'

    select top 1
        @DeleteBatchRAPS_MOR_Combined = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchRAPS_MOR_Combined'

    --EDS 

    select top 1
        @DeleteBatchEDS_Preliminary = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchEDS_Preliminary'

    select top 1
        @DeleteBatchEDS = cast([a1].[Value] as int)
    from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
    where [a1].[Variable] = '@DeleteBatchEDS' 

	--RE - 5112
	--select top 1
 --       @DeleteBatchEDSSrc = cast([a1].[Value] as int)
 --   from [rev].[tbl_Summary_RskAdj_Config] [a1] with (nolock)
 --   where [a1].[Variable] = '@DeleteBatchEDSSrc' 

 
    /*B Set Defaults if configuration values are not available */

    set @Mode = isnull(@Mode, 0)
    set @BBusinessHours = isnull(@BBusinessHours, 7)
    set @EBusinessHours = isnull(@EBusinessHours, 20)


    if @Debug = 1
    begin
        print '/*B Configuration Settings */'
        print '@Mode = ' + isnull(cast(@Mode as varchar(11)), 'NULL')
        print '@BBusinessHours = ' + isnull(cast(@BBusinessHours as varchar(11)), 'NULL')
        print '@EBusinessHours = ' + isnull(cast(@EBusinessHours as varchar(11)), 'NULL')
        print '@DeleteBatchAltHICN = ' + isnull(cast(@DeleteBatchAltHICN as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchMMR = ' + isnull(cast(@DeleteBatchMMR as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchMOR = ' + isnull(cast(@DeleteBatchMOR as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchRAPS_Preliminary = '
              + isnull(cast(@DeleteBatchRAPS_Preliminary as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchRAPS = ' + isnull(cast(@DeleteBatchRAPS as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchRAPS_MOR_Combined =  '
              + isnull(cast(@DeleteBatchRAPS_MOR_Combined as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchEDS_Preliminary = '
              + isnull(cast(@DeleteBatchEDS_Preliminary as varchar(11)), 'NULL --Default Value Used')
        print '@DeleteBatchEDS = ' + isnull(cast(@DeleteBatchEDS as varchar(11)), 'NULL --Default Value Used')
		--print '@DeleteBatchEDSSrc = ' + isnull(cast(@DeleteBatchEDSSrc as varchar(11)), 'NULL --Default Value Used') -- RE - 5112
        print '/*E Configuration Settings */'
        raiserror('', 0, 1) with nowait
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


    /* B If any @Force... flags are set to 1, then run only for the force flags */

    IF @ALT_HICN = 1
       or @MMR_FLAG = 1                                              -- TFS 71185   DW 05/16/18
       or @MOR_FLAG = 1
       or @RAPS_FLAG = 1
       or @EDS_FLAG = 1
	 --  or @EDSSrc_FLAG = 1 ---RE - 5112
  BEGIN
	 /*Resetting runflags to 0 */
    update rev.SummaryProcessRunFlag
    set RunFlag = 0
    where Process in ( 'AltHICN', 'MMR', 'RAPS', 'MOR', 'EDS') 


        update rev.SummaryProcessRunFlag
        set RunFlag = @ALT_HICN
        where Process in ( 'AltHICN' )

        update rev.SummaryProcessRunFlag
        set RunFlag = @MMR_FLAG
        where Process in ( 'MMR' )

        update rev.SummaryProcessRunFlag
        set RunFlag = @RAPS_FLAG
        where Process in ( 'RAPS' )

		UPDATE rev.SummaryProcessRunFlag
        set RunFlag = @MOR_FLAG
        where Process in ( 'MOR' )

        update rev.SummaryProcessRunFlag
        set RunFlag = @EDS_FLAG
        where Process in ( 'EDS' )

		--update rev.SummaryProcessRunFlag
  --      set RunFlag = @EDSSrc_FLAG
  --      where Process in ( 'EDSSrc' ) --RE -5112




    END

	
    /* E If any @Force... flags are set to 1, then run only for the force flags */

    ELSE

    BEGIN

        /*Resetting runflags to 0 */
        update rev.SummaryProcessRunFlag
        set RunFlag = 0, RefreshNeeded = 0
        where Process in ( 'AltHICN', 'MMR', 'RAPS', 'MOR', 'EDS') --RE -5112


	 
        
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

        if exists
        (
            select 1
            from [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig]     [conf]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTable]       [tbl]
                    on [conf].[RollupTableID] = [tbl].[RollupTableID]
                join [$(HRPInternalReportsDB)].[dbo].[RollupClient]      [clnt]
                    on [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                    on [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
                join [$(HRPReporting)].[dbo].[tbl_Clients]             [rptclnt]
                    on [rptclnt].[Client_Name] = [clnt].[ClientName]
            where [rptclnt].[Report_DB] = db_name()
                  and [tbl].[RollupTableName] in ( 'tbl_Member_Months_rollup' )
                  and [stat].[RollupStatus] = 'Stable'
                  and [stat].[IndexBuildEnd] > @MMR_LastUpdated
        )
        begin


            --update rev.SummaryProcessRunFlag
            --set RunFlag = 1
            --where Process in ( 'MMR', 'RAPS', 'EDS' )

			 update rev.SummaryProcessRunFlag
            set RefreshNeeded = 1, 
				RefreshNeededDate = GETDATE()
			 where Process in ( 'MMR' )

        end

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

        if exists
        (
            select 1
            from [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig]     [conf]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTable]       [tbl]
                    on [conf].[RollupTableID] = [tbl].[RollupTableID]
                join [$(HRPInternalReportsDB)].[dbo].[RollupClient]      [clnt]
                    on [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                    on [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
                join [$(HRPReporting)].[dbo].[tbl_Clients]             [rptclnt]
                    on [rptclnt].[Client_Name] = [clnt].[ClientName]
            where [rptclnt].[Report_DB] = db_name()
                  and [tbl].[RollupTableName] in ( 'tbl_ALTHICN_rollup' )
                  and [stat].[RollupStatus] = 'Stable'
                  and [stat].[IndexBuildEnd] > @AltHICN_LastUpdated
        )
        begin


            --update rev.SummaryProcessRunFlag
            --set RunFlag = 1
            --where Process in ( 'ALTHICN', 'MMR', 'RAPS', 'EDS' )
			
			 update rev.SummaryProcessRunFlag
            set RefreshNeeded = 1, 
				RefreshNeededDate = GETDATE()
			 where Process in ( 'ALTHICN' )


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

        if exists
        (
            select 1
            from [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig]     [conf]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTable]       [tbl]
                    on [conf].[RollupTableID] = [tbl].[RollupTableID]
                join [$(HRPInternalReportsDB)].[dbo].[RollupClient]      [clnt]
                    on [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                    on [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
                join [$(HRPReporting)].[dbo].[tbl_Clients]             [rptclnt]
                    on [rptclnt].[Client_Name] = [clnt].[ClientName]
            where [rptclnt].[Report_DB] = db_name()
                  and [tbl].[RollupTableName] in ( 'Converted_MOR_Data_rollup' )
                  and [stat].[RollupStatus] = 'Stable'
                  and [stat].[IndexBuildEnd] > @MOR_LastUpdated
        )
        begin


            --update rev.SummaryProcessRunFlag
            --set RunFlag = 1
            --where Process in ( 'MOR', 'RAPS', 'EDS' )
			update rev.SummaryProcessRunFlag
            set RefreshNeeded = 1, 
				RefreshNeededDate = GETDATE()
			 where Process in ( 'MOR' )


            if @Debug = 1
            begin
                exec [dbo].[PerfLogMonitor] @Section = '006'
                                          , @ProcessName = @ProcessNameIn
                                          , @ET = @ET
                                          , @MasterET = @MasterET
                                          , @ET_Out = @ET out
                                          , @TableOutput = 0
                                          , @End = 0
            end

        end

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] @Section = '007'
                                      , @ProcessName = @ProcessNameIn
                                      , @ET = @ET
                                      , @MasterET = @MasterET
                                      , @ET_Out = @ET out
                                      , @TableOutput = 0
                                      , @End = 0
        end

        if exists
        (
            select 1
            from [$(HRPInternalReportsDB)].[dbo].[RollupTableConfig]     [conf]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTable]       [tbl]
                    on [conf].[RollupTableID] = [tbl].[RollupTableID]
                join [$(HRPInternalReportsDB)].[dbo].[RollupClient]      [clnt]
                    on [conf].[ClientIdentifier] = [clnt].[ClientIdentifier]
                join [$(HRPInternalReportsDB)].[dbo].[RollupTableStatus] [stat]
                    on [stat].[RollupTableConfigID] = [conf].[RollupTableConfigID]
                join [$(HRPReporting)].[dbo].[tbl_Clients]             [rptclnt]
                    on [rptclnt].[Client_Name] = [clnt].[ClientName]
            where [rptclnt].[Report_DB] = db_name()
                  and [tbl].[RollupTableName] in ( 'Raps_Accepted_rollup' )
                  and [stat].[RollupStatus] = 'Stable'
                  and [stat].[IndexBuildEnd] > @RAPS_LastUpdated
        )
        begin

            --update rev.SummaryProcessRunFlag
            --set RunFlag = 1
            --where Process in ( 'RAPS' )

			
			update rev.SummaryProcessRunFlag
            set RefreshNeeded = 1, 
				RefreshNeededDate = GETDATE()
			 where Process in ( 'RAPS' )



            if @Debug = 1
            begin
                exec [dbo].[PerfLogMonitor] @Section = '008'
                                          , @ProcessName = @ProcessNameIn
                                          , @ET = @ET
                                          , @MasterET = @MasterET
                                          , @ET_Out = @ET out
                                          , @TableOutput = 0
                                          , @End = 0
            end

        END

        if @Debug = 1
        begin
            exec [dbo].[PerfLogMonitor] @Section = '009'
                                      , @ProcessName = @ProcessNameIn
                                      , @ET = @ET
                                      , @MasterET = @MasterET
                                      , @ET_Out = @ET out
                                      , @TableOutput = 0
                                      , @End = 0
        end

   /****************************************************
	Update RefreshFlag depending on Refershneeded dates
	******************************************************/
	
	
	BEGIN 

	
		Update	a
		Set		a.RefreshNeeded = 1
		from	rev.SummaryProcessRunFlag a
		where	a.RefreshNeededDate > a.lastRefreshDate


	END

BEGIN 
	/************IMPLEMENTING TRICKLEDOWN EFFECT*****************/
		IF EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process = 'AltHICN' and RefreshNeeded = 1)
			BEGIN
				UPDATE	a
				SET		a.RunFlag = 1
				FROM	rev.SummaryProcessRunFlag a
				WHERE	Process in ('AltHICN')
			END

		IF EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process = 'MMR' and RefreshNeeded = 1)
			BEGIN
				UPDATE	a
				SET		a.RunFlag = 1
				FROM	rev.SummaryProcessRunFlag a
				WHERE	Process in ('MMR', 'MOR', 'RAPS', 'EDS')-- EDS_Source not needed here.
			END

		IF EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process = 'MOR' and RefreshNeeded = 1)
			BEGIN
				UPDATE	a
				SET		a.RunFlag = 1
				FROM	rev.SummaryProcessRunFlag a
				WHERE	Process in ('MOR', 'RAPS', 'EDS')-- EDS_Source not needed here.
			END            

		IF EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process = 'RAPS' and RefreshNeeded = 1)
			BEGIN
				UPDATE	a
				SET		a.RunFlag = 1
				FROM	rev.SummaryProcessRunFlag a
				WHERE	Process in ('RAPS', 'EDS')
			END

		IF EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process = 'EDS' and RefreshNeeded = 1)
			BEGIN
				UPDATE	a
				SET		a.RunFlag = 1
				FROM	rev.SummaryProcessRunFlag a
				WHERE	Process in ('EDS')-- EDS_Source not needed here.
			END

		--IF EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process = 'EDSSrc' and RefreshNeeded = 1)
		--	BEGIN
		--		UPDATE	a
		--		SET		a.RunFlag = 1
		--		FROM	rev.SummaryProcessRunFlag a
		--		WHERE	Process in ('EDSSrc', 'EDS')
		--	END

END
END 

    if @Debug = 1
    begin
        exec [dbo].[PerfLogMonitor] @Section = '012'
                                  , @ProcessName = @ProcessNameIn
                                  , @ET = @ET
                                  , @MasterET = @MasterET
                                  , @ET_Out = @ET out
                                  , @TableOutput = 0
                                  , @End = 0
    end
	END