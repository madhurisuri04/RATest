CREATE PROCEDURE [dbo].[spr_RollupTable]
		@RollupTableConfigID			int
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        06/29/2011

Purpose:	 

Parameters:	 @RollupTableID -- from the RollupTable

Assumptions: 

Modifications:
08/30/2011 bab change the non-clustered idnex drop and recreate process to a disable and 
		       enable process
09/07/2011 bab changes for the configuration tables to move from the client (report) level to HRPInternalReports
10/21/2011 bab comment out Xact_Abort setting; change non-rollup execution call to be able to handle a NULL @DateFieldForFilter
04/22/2013 bab add logic to increase the Date Field Filter functionality (handle Null values and invalid dates)
01/12/2018	dsw  Incorporation of #ref_Client_Connections temp table to resolve Innovations Health Rollup issue (RE-1318)
04/12/2019	jsi  Modifications to the roll-up table process to preserve index attributes (RE-4742)
06/05/2019	jsi  Modifications to the roll-up table process to preserve index attributes (RE-5361)
07/09/2019	jsi  Modifications to allow for Innovation Health merged Plans usage (RE-4374)	
07/10/2019 CRR - 1605 - Logging the Execution time for each plan/table into Rolluplog table under HrpinternalReports DB.
07/25/2019	jsi  Modifications to allow for Innovation Health merged Plans usage (RE-6033)  TFS #76500
10/21/2019	jsi  Modifications to remove filter for disabled indexes from index table load (RE-6860) TFS #77077
11/19/2019	RE - 7055 - Add TargetTableName Column to Rollup_log table.
12/16/2019  RE- 7195  - Add RunGroup Column to Rollup_log table.
1/3/2020 -  RE-7431-TFS:77587 - Modified the Store proc for Incremental Load - Raps_detail_rollup & tbl_raps_detail_rollup
1/23/2020   RE-7649 - TFS:77747 - Skip Disable index step for Raps tables
04/23/2020  RRI - 4 - TFS:78423 - Adding Tbl_plan_Claims_Rollup - Incremental logic.
*********************************************************************************/

Set NoCount On
--Set XACT_ABORT ON

Begin Try

	-------------------------------------------------------------------------
	-- Declare variables
	-------------------------------------------------------------------------
	Declare @PatIndexValue							int,
			@ClientName								varchar(100),
			@TruncateSql							nvarchar(1000),
			@ExecProcSql							nvarchar(1000),
			@ExecProcIncre							nvarchar(1000),
			@InsertSql								nvarchar(max),
			@GetIndexSql							nvarchar(1000),
			@GetColumnsSql							nvarchar(1000),
			@DatabaseCnt							int,
			@Cnt									int,
			@DatabaseName							sysname,
			@PlanIdentifier							smallint,
			@EarliestDate							varchar(10),
			@OfflineDB								varchar(4000),
			@ColumnList								nvarchar(max),
			@TargetTableIdentityName				sysname,
			@TableName								sysname,
			@SchemaName								sysname,
			@TargetTableName						sysname,
			@DateFieldForFilter						sysname,
			@RollingYears							int,
			@DynamicInsert							bit,
			@RollupTableStatusID					int,
			@RollupStatus							varchar(10),
			@RollupStatusCnt						smallint,
			@TableActive							bit,
			@DataValidation							bit,
			@DateFieldForFilterType					varchar(5),
			@PlanID									varchar(5),
			@IndexCnt								smallint,
			@IDXDisableCnt							smallint,
			@IDXEnableCnt							smallint,
			@DisableIndexSql						nvarchar(1000),
			@NonClusteredIndexName					varchar(1000),
			@FillFactor								tinyint,
			@DataCompressionDesc					nvarchar(60),
			@EnableIndexSql							nvarchar(2000),
			@ClientReportDB							sysname,
			@FilterValuesStartWithYear				bit,
			@IncludeNullDates						bit,
			@IncludeInvalidDates					bit,			
			@DateFilterDataType						sysname,
			@DateFilterDataTypePrevValue			sysname,			
			@DateFilterDataTypeCategory				varchar(8),--Values are (numeric, date, string)
			@IsDateFilterDataTypeNullable			bit,
			@IsDateFilterDataTypeNullablePrevValue	bit,
			@EarliestDateSql						nvarchar(50),
			@DateFilterSql							nvarchar(200),
			@DateFieldForFilterNULLSql				nvarchar(200),
			@DeriveDateFieldFilterDataTypeSql		nvarchar(2000),
			@startdate								datetime, -- CRR - 1605
			@Enddate								datetime, -- CRR - 1605
			@Row_count								INT, -- CRR - 1605
			@Scopeid								INT, -- CRR - 1605			
			@RunGroup								Char(2),
			@Incre_load_Count						INT,			
			@Incre_load 							INT,			
			@ParmDefinition						    nvarchar(500),
			@Incre_Flag									bit
									
	Declare @PlanDatabase Table
		(PlanDatabaseID		int identity primary key,
		 DatabaseName		sysname,
		 PlanIdentifier		smallint,
		 PlanID				varchar(5),
		 state_desc			nvarchar(60))
	
	Create Table #NonClusteredIndex
		(NonClusteredIndexID int identity primary key
		 ,IndexName					sysname
		 ,fill_factor				tinyint
		 ,data_compression_desc		nvarchar(60))
	
	-------------------------------------------------------------------------
	-- Set variable values
	-------------------------------------------------------------------------
	Set @DataValidation = 0
	Set @Cnt = 1
	Set @IDXDisableCnt = 1
	Set @IDXEnableCnt = 1
	Set @OfflineDB = ''
	Set @ColumnList = ''
	Set @DateFilterDataTypePrevValue = 'NoSuchType'
	Set @IsDateFilterDataTypeNullablePrevValue = 0

	-------------------------------------------------------------------------
	-- Create [#xref_Client_Connections] Temp Table       (RE-1318)
	-------------------------------------------------------------------------
	IF ( OBJECT_ID('tempdb.dbo.[#xref_Client_Connections]') IS NOT NULL )
    BEGIN
        DROP TABLE [#xref_Client_Connections]
    END


	/*Create #xref_Client_Connections table */

	CREATE TABLE [#xref_Client_Connections]
		(
			[Id] [INT] IDENTITY(1, 1) PRIMARY KEY NOT NULL ,
			[Client_ID] INT ,
			[Connection_ID] INT
		);

	-------------------------------------------------------------------------------------
	--- Insert records into [#xref_Client_Connections] Temp table      (RE-1318)
	-------------------------------------------------------------------------------------
	INSERT INTO [#xref_Client_Connections] (   [Client_ID] ,
                                           [Connection_ID]
                                       )
            SELECT ISNULL([mg].[MergedClientID], [x].[Client_ID]) AS [Client_ID] ,
                   [x].[Connection_ID]
            FROM   [$(HRPReporting)].[dbo].[xref_Client_Connections] [x]         -- (RE-1318    DSW modified 1/8/18)
                   LEFT OUTER JOIN [$(HRPReporting)].[dbo].[MergedClients] [mg] ON [x].[Client_ID] = [mg].[ClientID]
                                                                                AND [mg].[Product] = 'RAPS'
                                                                                AND [mg].[ClientID] <> 11

	CREATE NONCLUSTERED INDEX [IX_#xref_Client_Connections_Client_ID]
    ON [#xref_Client_Connections] ( [Client_ID] )

	-------------------------------------------------------------------------
	-- Get specific Rollup values for the table
	-------------------------------------------------------------------------	
	Select @TargetTableName = rt.RollupTableName,
		   @TableName = rt.SourceTableName,
		   @SchemaName = rt.SourceTableSchema,
		   @DateFieldForFilter = rt.DateFieldForFilter,
		   @DateFieldForFilterType = rt.DateFieldForFilterType,
		   @RollingYears = rtc.RollingYearsFilter,
		   @DynamicInsert = rtc.DynamicRollup,
		   @TableActive = rtc.Active,
		   @ClientName = rc.ClientName,
		   @FilterValuesStartWithYear = IsNull(rt.FilterValuesStartWithYear,1),
		   @IncludeNullDates = IsNull(rtc.IncludeNullDates,0),
		   @IncludeInvalidDates = IsNull(rtc.IncludeInvalidDates,0),
		   @RunGroup	= rt.RunGroup,
		   @Incre_Flag=rtc.TruncateTable
	From dbo.RollupTableConfig rtc
	Inner Join  [dbo].[RollupTable] rt
		On rtc.RollupTableID = rt.RollupTableID
	Inner Join dbo.RollupClient rc
		On rtc.ClientIdentifier = rc.ClientIdentifier		
	Where rtc.RollupTableConfigID = @RollupTableConfigID
	
	If @@ROWCOUNT <> 1
		Raiserror('The is no record in the RollupTable for the @RollupTableConfigID (%s) that was requested',16,1,@RollupTableConfigID)
		
	If @TableActive = 0
		Raiserror('The table requested to rollup (%s) is Not currently Active ',16,1,@TargetTableName)	
			
	-------------------------------------------------------------------------
	-- Derive the date used to filter the source rollup data
	-------------------------------------------------------------------------
	If @DateFieldForFilter Is Not Null
	  Begin 
		If @DateFieldForFilterType = 'Day'
			Set @EarliestDate = cast((YEAR(getdate())-(@RollingYears -1)) as varchar(4)) + '-01-01'	
		Else If @DateFieldForFilterType = 'Month'
			Set @EarliestDate = cast((YEAR(getdate())-(@RollingYears -1)) as varchar(4)) + '-01'
	    Else If @DateFieldForFilterType = 'Year'
			Set @EarliestDate = cast((YEAR(getdate())-(@RollingYears -1)) as varchar(4))
		Else
			Raiserror('There is an invalid DateFieldForFilterType value (%s) in the RollupTable; Valid values are (Day,Month,Year)',16,1,@DateFieldForFilterType)							
	  End
	  
	-------------------------------------------------------------------------
	-- Derive value used to exclude columns from the dynamic select list
	-------------------------------------------------------------------------	  
	Set @TargetTableIdentityName = @TargetTableName + 'ID'
	
	-------------------------------------------------------------------------
	-- check that HRPReporting database is online
	-------------------------------------------------------------------------	
	If Not Exists (Select 1 From master.sys.databases Where name = 'HRPReporting' And state_desc = 'ONLINE')
	  Begin
		Raiserror('The HRPReporting Database either does not exist or is Offline',16,1)			
	  End	
	  
	-------------------------------------------------------------------------
	-- Get the Client Reporting databae name
	-------------------------------------------------------------------------
	Set @ClientReportDB = (Select Report_DB From [$(HRPReporting)].dbo.tbl_Clients c with (nolock) Where Client_Name = @ClientName)
	
	If (@@ROWCOUNT <> 1 Or @ClientReportDB Is Null)
		Raiserror('Could not derive the Reporting database name',16,1)		
			  	
	-------------------------------------------------------------------------
	-- populate dataset of plan level databases
	-------------------------------------------------------------------------	
	Insert Into @PlanDatabase
		(DatabaseName, PlanID, PlanIdentifier, state_desc)	
	Select DISTINCT conn.Connection_Name As DatabaseName, conn.Plan_ID, p.PlanIdentifier,db.state_desc
	From [$(HRPReporting)].dbo.tbl_Clients c with (nolock)
	Inner Join [#xref_Client_Connections] xref with (nolock)    --(RE-1318  DSW modified 1/8/18)
		On c.Client_ID = xref.Client_ID
	Inner Join  [$(HRPReporting)].dbo.tbl_Connection conn with (nolock)
		On xref.Connection_ID = conn.Connection_ID
	Inner Join dbo.[RollupPlan] p with (nolock)
		On conn.Plan_ID = p.PlanID
		And p.Active = 1
		And p.UseForRollup = 1
	Inner Join dbo.RollupClient rc
		On p.ClientIdentifier = rc.ClientIdentifier
		And rc.Active = 1
		And rc.UseForRollup = 1
		And rc.ClientName = @ClientName
		AND 
		(
				(c.Client_Name = rc.ClientName)
			OR 
				(rc.ClientName = 'Innovation Health')
		)
	Left Outer Join master.sys.databases db
		On conn.Connection_Name = db.name
		And db.state_desc = 'ONLINE'

	Order by p.PlanIdentifier asc
		
	Set @DatabaseCnt = @@ROWCOUNT	
	
	-------------------------------------------------------------------------
	-- Handle Clients with no databases
	-------------------------------------------------------------------------		
	If @DatabaseCnt = 0
		Raiserror('There are no databases listed under this Client (%s).',16,1,@ClientName)	
	
	-------------------------------------------------------------------------
	-- Determine if any of the source databases are offline or do not exist
	-------------------------------------------------------------------------
	Select @OfflineDB = @OfflineDB + DatabaseName + ', ' From @PlanDatabase Where IsNull(state_desc,'') <> 'ONLINE'
	
	If @@ROWCOUNT > 0 
		Raiserror('The following database(s) %s are listed under this Client (%s) but are NOT currently Online',16,1,@OfflineDB,@ClientName)
		
	-------------------------------------------------------------------------
	-- Determine the status information for the table to rollup and handle any errors
	-------------------------------------------------------------------------	
	Select @RollupTableStatusID = RollupTableStatusID,
		   @RollupStatus = RollupStatus
	From dbo.RollupTableStatus
	Where RollupTableConfigID = @RollupTableConfigID
	
	Set @RollupStatusCnt = @@ROWCOUNT
			
	If @RollupStatusCnt > 1
		Raiserror('The RollupTableStatus Table has more than one entry for the %s table under this Client (%s)',16,1,@TargetTableName,@ClientName)
		
	If @RollupStatus = 'InProcess'
		Raiserror('The table %s is currently being rolled up by a different process or failed under a previous execution',16,1,@TargetTableName)				
		
	If @RollupStatusCnt = 0 
	  Begin
		Insert Into dbo.RollupTableStatus
			(RollupTableConfigID, RollupStatus, RollupState, PlanIdentifierCurrentlyProcessing, PlanIDCurrentlyProcessing, PlanNumberCurrentlyProcessing, 
			 NumberOfPlansToProcess, RollupStart, RollupEnd, IndexBuildStart, IndexBuildEnd, LastStateCheckDate, CreateDate, ModifiedDate)
		Select @RollupTableConfigID, 'New', 'OutOfDate', NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1900-01-01', GETDATE(),GETDATE()
		
		Set @RollupTableStatusID = (Select RollupTableStatusID
									From dbo.RollupTableStatus
									Where RollupTableConfigID = @RollupTableConfigID)
	  End
	  
	-------------------------------------------------------------------------
	-- Past this point all errors that can be handled will update the status to 'Unstable'
	-------------------------------------------------------------------------	  	
	Set @DataValidation = 1
									    
	-------------------------------------------------------------------------
	-- Update Rollup Status for the table being rolled up
	-------------------------------------------------------------------------
	Update rts
		Set RollupStatus = 'InProcess',
			RollupStart = GETDATE(),
			RollupEnd = NULL,
			PlanIdentifierCurrentlyProcessing = NULL,
			NumberOfPlansToProcess = @DatabaseCnt,
			IndexBuildStart = NULL,
			IndexBuildEnd = NULL,	
			ModifiedDate = GETDATE()
	From dbo.RollupTableStatus rts
	Where RollupTableStatusID = @RollupTableStatusID
							    									
	-------------------------------------------------------------------------
	-- Build and execute truncate statement
	-------------------------------------------------------------------------	

	If @Incre_Flag=1

	Begin
	 
	 Set @TruncateSql = 'Truncate Table ' + @ClientReportDB + '.[dbo].[' + @TargetTableName + ']'
			
	 Execute sp_executesql @stmt = @TruncateSql

	End
	
	If @Incre_Flag=1
	
	Begin
	-------------------------------------------------------------------------
	-- Disable NonClustered Indexes (if any)
	-------------------------------------------------------------------------	
	Set @GetIndexSql = 'Use ' + @ClientReportDB +
					   ' Insert Into #NonClusteredIndex (IndexName, fill_factor, data_compression_desc) ' +
					   'SELECT i.[Name]
							,CASE WHEN ISNULL(i.fill_factor, 0) = 0 THEN 100 ELSE i.fill_factor END AS fill_factor
							,ISNULL(p.data_compression_desc, ''NONE'') AS data_compression_desc
						FROM ' + @ClientReportDB + '.sys.indexes i
						JOIN sys.partitions AS p
						ON p.object_id = i.object_id
							AND p.index_id = i.index_id
						WHERE i.object_id = OBJECT_ID(''' + @TargetTableName + ''') ' +
						'AND i.type_desc = ''NONCLUSTERED'''

	--Print @GetIndexSql				   					   
	Execute sp_executesql @stmt = @GetIndexSql	
		
	Set @IndexCnt = (Select count(NonClusteredIndexID) From #NonClusteredIndex)
	
	While (@IDXDisableCnt <= @IndexCnt)
	  Begin
		Set @NonClusteredIndexName = (Select IndexName From #NonClusteredIndex Where NonClusteredIndexID = @IDXDisableCnt)
		
		Set @DisableIndexSql = 'Alter Index [' + @NonClusteredIndexName + '] on ' + @ClientReportDB + '.[dbo].[' + @TargetTableName + '] Disable'
		
		--print @DisableIndexSql
		Execute sp_executesql @stmt = @DisableIndexSql
		
		Set @IDXDisableCnt = @IDXDisableCnt + 1
			 
	  End

	End		
	-------------------------------------------------------------------------
	-- Build and execute Insert execution statement for each plan level database
	-------------------------------------------------------------------------
	If @DynamicInsert = 0 --manual insert logic
	  Begin
		While (@Cnt <= @DatabaseCnt)
		  Begin
		  
			-------------------------------------------------------------------------
			-- Get the source database and plan for this iteration
			-------------------------------------------------------------------------			  
			Select @DatabaseName = DatabaseName,
				   @PlanIdentifier = PlanIdentifier,
				   @PlanID = PlanID
			From @PlanDatabase
			Where PlanDatabaseID = @Cnt
			
			-------------------------------------------------------------------------
			-- Update the status for the planID that is being processed
			-------------------------------------------------------------------------				
			Update rts
				Set RollupStatus = 'InProcess',
					PlanIdentifierCurrentlyProcessing = @PlanIdentifier,
					PlanIDCurrentlyProcessing = @PlanID,
					PlanNumberCurrentlyProcessing = @Cnt,
					ModifiedDate = GETDATE()
			From dbo.RollupTableStatus rts
			Where RollupTableStatusID = @RollupTableStatusID			

 	
			Set @ExecProcSql = 'Execute ' + @ClientReportDB + '.dbo.spr_Insert_' + @SchemaName + '_' + @TableName + 
							   '_rollup @SourceDatabase = ''' + @DatabaseName + 
							   ''', @PlanIdentifier = ' + cast(@PlanIdentifier as varchar(3))
							   							   
			If @DateFieldForFilter IS NOT NULL
			  Begin	
				Set @ExecProcSql = @ExecProcSql + ', @EarliestDate = ''' + @EarliestDate + ''''
			  End									   
 

			Set @ExecProcIncre = 'Execute ' + @ClientReportDB  + '.dbo.spr_Insert_' + @SchemaName + '_' + @TableName + 
							   '_rollup @SourceDatabase = ''' + @DatabaseName + 
							   ''', @PlanIdentifier = ' + cast(@PlanIdentifier as varchar(3)) +
							    ', @Incre_load_Count= @Incre_load_Count OUTPUT'
 

-- CRR -1605 Start
		SET @startdate = GETDATE()
		

 		INSERT INTO [dbo].[Rollup_Log]
            (
                DatabaseName
              , PlanIdentifier
              , PlanID
			  , SourceTableName --RE-7055
			  , TargetTableName --RE-7055 
			  , Start_Time
			  , RunGroup
            )
            SELECT @DatabaseName
                 , @PlanIdentifier
                 , @PlanID
				 , @TableName
				 , @TargetTableName
				 , @startdate
				 , @RunGroup

		   SET @ScopeId = SCOPE_IDENTITY()

---TFS:77587 - Begin

set @ParmDefinition =N'@Incre_load_Count Int OUTPUT';
 
			If  @Incre_Flag=0
 
				Begin
			 	 	Execute sp_executesql  @ExecProcIncre
										 , @ParmDefinition
										 , @Incre_load_Count = @Incre_load OUTPUT
					Set @Row_count = @Incre_load;
				End
 
 
		   Else
		
			 Begin
 
			  Execute sp_executesql @stmt = @ExecProcSql
       		  Set @Row_count = @@ROWCOUNT
		    
			End

   
		  
		   SET @Enddate = GETDATE()

		   UPDATE L
            SET [L].[End_Time] = @Enddate
              , [L].[Execution_Time] = CONVERT(CHAR(12), @Enddate - @startdate, 114)
              , [L].[Row_Count] = @Row_count
            FROM [dbo].[Rollup_Log] L
            WHERE L.[Rollup_logID] = @ScopeId


			Set @Cnt = @Cnt + 1			
		  End
	  End
	Else -- Dynamic Insert logic
	  Begin
		-------------------------------------------------------------------------
		-- Derive the column list from the target table and remove the trailing comma
		-------------------------------------------------------------------------	  	 		
		Set @GetColumnsSql = N'Set @dColumnList = '''' ' +
							 'Select @dColumnList = @dColumnList + ''['' + s.name + ''], '' ' +
						     'From ' + @ClientReportDB + '.sys.columns as s ' + 
		                     'Inner Join ' + @ClientReportDB + '.sys.objects as o ' +
		                     'On s.object_id = o.object_id ' +
		                     'Where o.name = ''' + @TargetTableName + '''' +
		                      ' And s.name Not In (''' + @TargetTableIdentityName + ''',''PlanIdentifier'' , ''RollupLoad'' )'	
		 
 

		Execute sp_executesql 
			@stmt = @GetColumnsSql,
			@params = N'@dColumnList As nvarchar(max) OUTPUT',
			@dColumnList = @ColumnList OUTPUT
		                     		
		Set @ColumnList = LEFT(@ColumnList,LEN(@ColumnList) -1)
															 	
		While (@Cnt <= @DatabaseCnt)
		  Begin
			-------------------------------------------------------------------------
			-- Get the source database and plan for this iteration
			-------------------------------------------------------------------------	
			Select @DatabaseName = DatabaseName,
				   @PlanIdentifier = PlanIdentifier,
				   @PlanID = PlanID
			From @PlanDatabase
			Where PlanDatabaseID = @Cnt
			
			-------------------------------------------------------------------------
			-- Update the status for the planID that is being processed
			-------------------------------------------------------------------------				
			Update rts
				Set RollupStatus = 'InProcess',
					PlanIdentifierCurrentlyProcessing = @PlanIdentifier,
					PlanIDCurrentlyProcessing = @PlanID,
					PlanNumberCurrentlyProcessing = @Cnt,
					ModifiedDate = GETDATE()
			From dbo.RollupTableStatus rts
			Where RollupTableStatusID = @RollupTableStatusID				
			
			-------------------------------------------------------------------------
			-- Build the Insert statement for the specific plan
			-------------------------------------------------------------------------
			Set @InsertSql = 'Insert Into ' + @ClientReportDB + '.[dbo].[' + @TargetTableName + '] ([PlanIdentifier], ' + @ColumnList + ') ' +
							 'Select ' + CAST(@PlanIdentifier as varchar(3)) + ', ' + @ColumnList +
							 ' From [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] with (nolock)' +
							 ' Where 1 = 1 '
							 
			-------------------------------------------------------------------------
			-- Determine the data type and nullability of the Date Filter column in the source table
			-------------------------------------------------------------------------								 							 		
			If @DateFieldForFilter IS NOT NULL
			  Begin
				Set @DeriveDateFieldFilterDataTypeSql = 'Use ' + @DatabaseName + 
													   ' Select @dDateFilterDataType = t.name,' + 
													   '	    @dIsDateFilterDataTypeNullable = c.is_nullable' +
													   ' From sys.columns c' +
													   ' Inner Join sys.objects o' +
													   '	On c.object_id = o.object_id' +
													   '	And o.name = ''' + @TableName + '''' +
													   ' Inner Join sys.types t' +
													   '	On c.user_type_id = t.user_type_id' +
													   ' Inner Join sys.schemas s' +
													   '	On o.schema_id = s.schema_id' +
													   '	And s.name = ''' + @SchemaName + '''' + 
													   ' Where c.name = ''' + @DateFieldForFilter + ''''
												   
				--Print @DeriveDateFieldFilterDataTypeSql		
				Execute sp_executesql 
					@stmt = @DeriveDateFieldFilterDataTypeSql,
					@params = N'@dDateFilterDataType As sysname Output, @dIsDateFilterDataTypeNullable As bit Output',
					@dDateFilterDataType = @DateFilterDataType Output, 	@dIsDateFilterDataTypeNullable = @IsDateFilterDataTypeNullable Output
					
				-------------------------------------------------------------------------
				-- End the process if the Date Filter data type and nullabililty cannot be established
				-------------------------------------------------------------------------
				If @DateFilterDataType is Null Or @IsDateFilterDataTypeNullable Is Null
				  Begin
					Raiserror('Unable to determine the Date Filter Data Type or the Date Filter nullability; PlanID/DBName = %s source table/object = %s; Date Filter Column = %s',16,1, @DatabaseName,@TableName,@DateFieldForFilter)
				  End				
					
				-------------------------------------------------------------------------
				-- Determine if the Data Type or Nullability for the Date Filter is different from previous plan
				-------------------------------------------------------------------------
				If (@DateFilterDataType <> @DateFilterDataTypePrevValue) Or (@IsDateFilterDataTypeNullable <> @IsDateFilterDataTypeNullablePrevValue)  						
				  Begin
				  					
					-------------------------------------------------------------------------
					-- Derive the @DateFilterDataTypeCategory value (which bucket does the data type fall into)
					-------------------------------------------------------------------------																		   								  
					If @DateFilterDataType in ('bigint','int','numeric','smallint','tinyint')
						Set @DateFilterDataTypeCategory = 'numeric'
					Else
						If  @DateFilterDataType in ('char','nchar','nvarchar','varchar')
							Set @DateFilterDataTypeCategory = 'string'
						Else
							If @DateFilterDataType in ('date','datetime','datetime2','smalldatetime')
								Set @DateFilterDataTypeCategory = 'date'
							Else
								Raiserror('The Date Filter DataType if not of one of the three categories (string, numeric or date)',16,1)						
					  				  
					-------------------------------------------------------------------------
					-- Derive the first half of the date comparison (default logic that is used unless overridden by a scenario below)
					-------------------------------------------------------------------------
					 --Default 
					Set @DateFilterSql = ' And ' + @DateFieldForFilter + ' '  
					
					-------------------------------------------------------------------------
					-- Derive the first half of the date comparison
					-------------------------------------------------------------------------								  
					If (@DateFilterDataTypeCategory = 'string' And @DateFieldForFilterType = 'Day') And (@FilterValuesStartWithYear = 0 Or @IncludeInvalidDates = 1) 
					  Begin 
						If @IsDateFilterDataTypeNullable = 1
							If @IncludeNullDates = 0 And  @IncludeInvalidDates = 0
								Set @DateFilterSql = ' And Case IsDate(IsNull(' + @DateFieldForFilter + ',''20790606'')) When 1 Then CAST(IsNull(' + @DateFieldForFilter + ',''19000101'') AS date) Else ''19000101'' End'
							Else
								If @IncludeNullDates = 1 And  @IncludeInvalidDates = 1
									Set @DateFilterSql = ' And Case IsDate(IsNull(' + @DateFieldForFilter + ',''11111111'')) When 1 Then CAST(IsNull(' + @DateFieldForFilter + ',''20790606'') AS date) Else ''20790606'' End'
								Else
									If @IncludeNullDates = 0 And  @IncludeInvalidDates = 1
										Set @DateFilterSql = ' And Case IsDate(IsNull(' + @DateFieldForFilter + ', ''20790606'')) When 1 Then CAST(IsNull(' + @DateFieldForFilter + ',''19000101'') AS date) Else ''20790606'' End' 
									Else
										If @IncludeNullDates = 1 And  @IncludeInvalidDates = 0
											Set @DateFilterSql = ' And Case IsDate(IsNull(' + @DateFieldForFilter + ', ''20790606'')) When 1 Then CAST(IsNull(' + @DateFieldForFilter + ',''20790606'') AS date) Else ''19000101'' End' 							
						Else --@IsDateFilterDataTypeNullable = 0
						  Begin
							If @IncludeInvalidDates = 1
								Set @DateFilterSql = ' And Case IsDate(' + @DateFieldForFilter + ') When 1 Then CAST(' + @DateFieldForFilter + ' As date) Else ''19000101'' End'
							Else --@IncludeInvalidDates = 0
								Set @DateFilterSql = ' And Case IsDate(' + @DateFieldForFilter + ') When 1 Then CAST(' + @DateFieldForFilter + ' As date) Else ''20790606'' End'	  
						  End
						 
					  End
					Else
						If @DateFilterDataTypeCategory = 'date' And @IsDateFilterDataTypeNullable = 0 And @IncludeNullDates = 1
							Set @DateFilterSql = ' And IsNull(' + @DateFieldForFilter + ', ''20790606'') '
							
					-------------------------------------------------------------------------
					-- Derive the second half of the date comparison (trying to avoid as many implicit casts as possible)
					-------------------------------------------------------------------------  
					Set @EarliestDateSql = Case @DateFilterDataTypeCategory
												When 'nvarchar' Then ' N''' + @EarliestDate + ''''
												When 'numeric' Then ' ' + @EarliestDate
												Else ' ''' + @EarliestDate+ ''''
											End	
				  End															  
			  
				-------------------------------------------------------------------------
				-- Add the Date Filter logic together to complete the date filter
				-------------------------------------------------------------------------  			  			 			  
				Set @InsertSql = @InsertSql + @DateFilterSql + ' >= ' + @EarliestDateSql 
				
				-------------------------------------------------------------------------
				-- Add the Date Filter logic together to complete the date filter
				-------------------------------------------------------------------------  			  			 			  								
				If @DateFilterDataTypeCategory in ('int','string') And @IncludeNullDates = 1 And @IsDateFilterDataTypeNullable = 1 And @DateFilterSql Not Like '%IsNull%'
				  Begin
					Set @InsertSql = @InsertSql + ' Or ' + @DateFieldForFilter + ' Is Null'
				  End									
			  End		
			  
--CRR 1605 Start		 	
	  SET @startdate = GETDATE()
	  
	  INSERT INTO [dbo].[Rollup_Log]
            (
                DatabaseName
              , PlanIdentifier
              , PlanID
			  , SourceTableName --RE-7055
			  , TargetTableName --RE-7055
			  , Start_Time
			  , RunGroup
            )
            SELECT @DatabaseName
                 , @PlanIdentifier
                 , @PlanID
				 , @TableName 
				 , @TargetTableName
				 , @startdate	
				 , @RunGroup
																   
			--Print @InsertSql
			Begin Transaction

			SET @ScopeId = SCOPE_IDENTITY()


				Execute sp_executesql @stmt = @InsertSql	
				
			Set @Row_count = @@ROWCOUNT

	        SET @Enddate = GETDATE()

			UPDATE L
            SET [L].[End_Time] = @Enddate
              , [L].[Execution_Time] = CONVERT(CHAR(12), @Enddate - @startdate, 114)
              , [L].[Row_Count] = @Row_count
            FROM [dbo].[Rollup_Log] L
            WHERE L.[Rollup_logID] = @ScopeId
							
			Commit Transaction
			
			-------------------------------------------------------------------------
			-- Reset certain parameter values
			-------------------------------------------------------------------------  
			Set  @DateFilterDataType = @DateFilterDataTypePrevValue
			Set  @IsDateFilterDataTypeNullable = @IsDateFilterDataTypeNullablePrevValue
				
			Set @DateFilterDataType = NULL
			Set @IsDateFilterDataTypeNullable = NULL		
						
			Set @Cnt = @Cnt + 1			
		  End	  
	  End
	  
	-------------------------------------------------------------------------
	-- Update the status indicating completion of the rollup and begin of Index build
	-------------------------------------------------------------------------	  
	Update rts
		Set RollupStatus = 'IndexBuild',
			RollupState = 'Current',
			RollupEnd = GETDATE(),
			PlanIdentifierCurrentlyProcessing = NULL,
			PlanIDCurrentlyProcessing = NULL,
			PlanNumberCurrentlyProcessing = NULL,
			NumberOfPlansToProcess = NULL,			
			IndexBuildStart = getdate(),
			IndexBuildEnd = NULL,
			ModifiedDate = GETDATE()
	From dbo.RollupTableStatus rts
	Where RollupTableStatusID = @RollupTableStatusID		  
	  
	-------------------------------------------------------------------------
	-- Enable all non-clustered indexes that were previously disabled on the table
	-------------------------------------------------------------------------	
	If @Incre_Flag=1
	
	Begin

	While (@IDXEnableCnt <= @IndexCnt)
	  Begin
		Set @NonClusteredIndexName = (Select IndexName From #NonClusteredIndex Where NonClusteredIndexID = @IDXEnableCnt)
		Set @FillFactor = (Select fill_factor From #NonClusteredIndex Where NonClusteredIndexID = @IDXEnableCnt)
		Set @DataCompressionDesc = (Select data_compression_desc From #NonClusteredIndex Where NonClusteredIndexID = @IDXEnableCnt)
		
		Set @EnableIndexSql = 'Alter Index [' + @NonClusteredIndexName + '] on ' + @ClientReportDB + '.[dbo].[' + @TargetTableName + '] Rebuild' +
			' WITH (FILLFACTOR = ' + CAST(@FillFactor AS VARCHAR(3)) + ', DATA_COMPRESSION = ' + @DataCompressionDesc + ')'

		Execute sp_executesql @stmt = @EnableIndexSql
	
		Set @IDXEnableCnt = @IDXEnableCnt + 1
			 
	  End	

	End	  		  	  
	-------------------------------------------------------------------------
	-- Update the status indicating completion of the index build
	-------------------------------------------------------------------------				
	Update rts
		Set RollupStatus = 'Stable',
			IndexBuildEnd = getdate(),
			ModifiedDate = GETDATE()
	From dbo.RollupTableStatus rts
	Where RollupTableStatusID = @RollupTableStatusID	  		  		
	
	-------------------------------------------------------------------------
	-- Clean up
	-------------------------------------------------------------------------	
	Drop Table #NonClusteredIndex
	
End Try

-------------------------------------------------------------------------
-- Error handling
-------------------------------------------------------------------------	
Begin Catch
	If (XACT_STATE() = 1 Or XACT_STATE() = -1)
		Rollback Transaction

	If @DataValidation = 1 --passed the data validation logic
	Begin		
		Begin Try				
			If Exists (Select 1 
					   From dbo.RollupTableStatus with (nolock)
					   Where RollupTableStatusID = @RollupTableStatusID)
					   
					-------------------------------------------------------------------------
					-- Update the status indicating that the data for the table's rollup is unstable
					-------------------------------------------------------------------------				
					Update rts
						Set RollupStatus = 'Unstable',
							RollupEnd = GETDATE(),
							ModifiedDate = GETDATE()
					From dbo.RollupTableStatus rts
					Where RollupTableStatusID = @RollupTableStatusID		  
		End Try

		Begin Catch
		  Raiserror ('Unable to update the dbo.RollupTableStatus table indicating that the data is unstable',16,1)
		End Catch
	End
			  			    				
	Declare @ErrorMsg varchar(2000)
	Set @ErrorMsg = 'Error: ' + IsNull(Error_Procedure(),'script') + ': ' +  Error_Message() +
				    ', Error Number: ' + cast(Error_Number() as varchar(10)) + ' Line: ' + 
				    cast(Error_Line() as varchar(50))
	
	Raiserror (@ErrorMsg, 16, 1)

End Catch