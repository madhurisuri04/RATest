Create PROCEDURE [dbo].[spr_CheckTableRollupState]
	@Client_ID INT
AS
/*********************************************************************************
Health Risk Partners
Author:		 Brett A. Burnam
Date:        08/11/2011

Purpose:	To determine which tables are out of date and need to be rolled up

Parameters:	 

Assumptions:	
				

Modifications:
09/09/2011 bab changes to move the configuration tables from the report level
	           to HRPConfig
12/01/2011 bab add the dbo.tbl_Images_rollup table to the list of tables that are rolled up
			   on every execution 
07/11/2012 bab change the LastStateCheckDate value to the last time that HRPReporting was refreshed
			   and add 'InFlight' logic to catch files that were loading when the clone snapshot was taken
01/12/2018 dsw Incorporation of #ref_Client_Connections temp table to resolve Innovations Health Rollup issue (RE-1318)
10/09/2018 jsi Added tbl_RAPS_Detail_rollup to update statement that sets it's status to 'OutOfDate' each time the proc is run.
				Added logic to set the status to 'OutOfDate' when the source for tbl_Plan_Claims > then the destination.
				RE-3335 / TFS #73691
11/13/2018 jsi Added logic so that only valid PlanDBs (Active and UseForRollup) should be considered to determine if 
				tbl_plan_claims should be updated. TFS #74080.
11/15/2018 jsi Added logic to filter out invalid PlandDBs that have moved to other clients for tbl_plan_claims. TFS #74126.
12/27/2018 jsi Added logic to only update LastStateCheckDate for the @Client_ID executed. TFS #74532.
01/22/2019 jsi Added logic to refresh tbl_plan_claims_Validation. TFS #74723.
07/25/2019 jsi Modifications to allow for Innovation Health merged Plans usage (RE-6033) TFS #76500
07/31/2019 jsi Added logic to refresh RAPS_Detail, RAPS_Detail_Import, RAPS_Detail_Import_Failed. TFS #76513.
08/27/2019 jsi Added logic to refresh CNRAPSImportDetail. TFS #76705.
12/11/2019 Added logic to RollupRunGroup table.
01/07/2020 Added ClientId to RollupRunGroup table.
07/22/2020 jsi Added logic to refresh RAPS_RETURN. TFS #79130.
02/26/2022 RRI-2171 - Removed the logic for status update - Raps_Detail_Rollup & tbl_plan_claims_Rollup
08/26/2022 RRI-2789 - Updated logic for LastStateCheckDate
*********************************************************************************/

Set NoCount On
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--Set XACT_ABORT ON

--DECLARE @Client_ID INT = 19

Begin Try

	Begin Transaction

	-- Declare and set the Client Identifier for the rollup tables based on the Client_ID passed
	DECLARE @ClientIdentifier INT
	SELECT @ClientIdentifier = rc.ClientIdentifier
	FROM [$(HRPReporting)].[dbo].[tbl_Clients] tc WITH (NOLOCK)
	INNER JOIN [dbo].[RollupClient] rc WITH (NOLOCK)
	ON tc.Client_Name = rc.ClientName
	WHERE tc.Client_ID = @Client_ID

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
    )

	-------------------------------------------------------------------------------------
	--- Insert records into [#xref_Client_Connections] Temp table
	-------------------------------------------------------------------------------------
	INSERT INTO [#xref_Client_Connections] (
		[Client_ID]
		,[Connection_ID]
		)
	SELECT DISTINCT ISNULL([mg].[MergedClientID], [x].[Client_ID]) AS [Client_ID]
		,[x].[Connection_ID]
	FROM [$(HRPReporting)].[dbo].[xref_Client_Connections] [x] WITH (NOLOCK)
	LEFT OUTER JOIN [$(HRPReporting)].[dbo].[MergedClients] [mg] WITH (NOLOCK)
		ON [x].[Client_ID] = [mg].[ClientID]
		AND [mg].[Product] = 'RAPS'
		AND [mg].[ClientID] NOT IN (11, 76)
	INNER JOIN [$(HRPReporting)].dbo.tbl_Clients c WITH (NOLOCK)
		ON x.Client_ID = c.Client_ID
	INNER JOIN [$(HRPReporting)].dbo.tbl_connection tc WITH (NOLOCK)
		ON x.Connection_ID = tc.Connection_ID
	INNER JOIN dbo.RollupPlan rp WITH (NOLOCK) 
		ON tc.Plan_ID = rp.PlanID
	INNER JOIN dbo.RollupClient rc WITH (NOLOCK)
		ON rp.ClientIdentifier = rc.ClientIdentifier
	WHERE x.Client_ID = @Client_ID
		AND rp.Active = 1
		AND rp.UseForRollup = 1
		AND c.Client_Name = rc.ClientName
		AND rc.Active = 1
	ORDER BY [x].[Connection_ID]


	CREATE NONCLUSTERED INDEX [IX_#xref_Client_Connections__x_Client_ID]
    ON [#xref_Client_Connections] ( [Client_ID] )

	-------------------------------------------------------------------------
	-- Determine which tables are Out of Date and need to be rolled up
	-------------------------------------------------------------------------
	Update rts
		Set RollupState = 'OutOfDate',
			ModifiedDate = getdate()						
	From dbo.RollupTableStatus rts	
	Where rts.RollupState <> 'OutOfDate'
	And rts.RollupTableConfigID in (  Select rtc.RollupTableConfigID
									  From [$(HRPReporting)].dbo.tbl_Clients c with (nolock)
									  Inner Join [#xref_Client_Connections] xref with (nolock)
										On c.Client_ID = xref.Client_ID
									  Inner Join  [$(HRPReporting)].dbo.tbl_Connection conn with (nolock)
										On xref.Connection_ID = conn.Connection_ID
									  Inner Join dbo.[RollupPlan] p with (nolock)
										On conn.Plan_ID = p.PlanID
										And p.Active = 1
										And p.UseForRollup = 1
									  Inner Join dbo.RollupClient rc with (nolock)
										On p.ClientIdentifier = rc.ClientIdentifier
										And c.Client_Name = rc.ClientName
										And rc.Active = 1								
									  Inner Join [$(HRPReporting)].dbo.tbl_Uploads up with (nolock)
										On conn.Connection_ID = up.Connection_ID
									  Inner Join dbo.RollupTableFileTypeXref rtfx with (nolock)
										On up.FileTypeID = rtfx.FileTypeID
										And rtfx.Active = 1
									  Inner Join dbo.RollupTableConfig rtc with (nolock)
										On rtc.RollupTableID = rtfx.RollupTableID
										And rtc.ClientIdentifier = rc.ClientIdentifier									
									  Inner Join dbo.RollupTableStatus rts with (nolock)
										On 	rtc.RollupTableConfigID = rts.RollupTableConfigID	
									  Where up.ImportedDate > rts.LastStateCheckDate 
									  And up.ImportedDate  < getdate()
									  --And ((up.ImportedDate  < getdate()) Or (up.ImportedDate = '2079-01-01' And up.[FileName] like '%Manual%')))
									  )
									  
	-------------------------------------------------------------------------
	-- Process file imports that were processing when the clone snapshot was taken
	-------------------------------------------------------------------------
	Update rts
		Set RollupState = 'InFlight',
			ModifiedDate = getdate()						
	From dbo.RollupTableStatus rts	
	Where rts.RollupState <> 'InFlight'
	And rts.RollupTableConfigID in (  Select rtc.RollupTableConfigID
									  From [$(HRPReporting)].dbo.tbl_Clients c with (nolock)
									  Inner Join [#xref_Client_Connections] xref with (nolock)
										On c.Client_ID = xref.Client_ID
									  Inner Join  [$(HRPReporting)].dbo.tbl_Connection conn with (nolock)
										On xref.Connection_ID = conn.Connection_ID
									  Inner Join dbo.[RollupPlan] p with (nolock)
										On conn.Plan_ID = p.PlanID
										And p.Active = 1
										And p.UseForRollup = 1
									  Inner Join dbo.RollupClient rc with (nolock)
										On p.ClientIdentifier = rc.ClientIdentifier
										And c.Client_Name = rc.ClientName
										And rc.Active = 1								
									  Inner Join [$(HRPReporting)].dbo.tbl_Uploads up with (nolock)
										On conn.Connection_ID = up.Connection_ID
									  Inner Join dbo.RollupTableFileTypeXref rtfx with (nolock)
										On up.FileTypeID = rtfx.FileTypeID
										And rtfx.Active = 1
									  Inner Join dbo.RollupTableConfig rtc with (nolock)
										On rtc.RollupTableID = rtfx.RollupTableID
										And rtc.ClientIdentifier = rc.ClientIdentifier									
									  Inner Join dbo.RollupTableStatus rts with (nolock)
										On 	rtc.RollupTableConfigID = rts.RollupTableConfigID	
									  Where up.UniqueFileValue like 'CLONES_%' 
									  )										  
									  	
	-------------------------------------------------------------------------
	-- Update the RollupTableStatus table for all rollup tables that need to be refreshed
	-- each time the job runs
	-------------------------------------------------------------------------	
	Update rts
		Set RollupState = 'OutOfDate',
			ModifiedDate = getdate()						
	From dbo.RollupTableStatus rts
	Where Exists (Select 1
				 From dbo.RollupTableConfig rtc
				 Inner Join dbo.RollupTable rt
					On rtc.RollupTableID = rt.RollupTableID
				 Inner Join dbo.RollupClient rc
					On rtc.Clientidentifier = rc.Clientidentifier
					And rc.Active=1
					And rt.RollupTableName in ('tbl_BIDS_rollup','tbl_Images_rollup','tbl_RAPS_Detail_rollup',
											   'RAPS_Detail_Import_rollup', 'RAPS_Detail_Import_Failed_rollup','tbl_Plan_Claims_rollup','RAPS_Detail_rollup')
				 Where rtc.RollupTableConfigID = rts.RollupTableConfigID)
	And rts.RollupState <> 'OutOfDate'


-- Determine max populated date from PlanDBs
		DECLARE @SQL NVARCHAR(MAX) = ''
		DECLARE @MinRowID INT
		DECLARE @MaxRowID INT
		DECLARE @CurrentRowID INT
		DECLARE @ConnectionName VARCHAR(100)
		DECLARE @MaxPlanDBPopulatedDate DATETIME
		DECLARE @Report_DB VARCHAR(128)
		DECLARE @MaxClientReportDBPopulatedDate DATETIME

	------------------------------------------------------------------------
	-- Check to see when the last time tbl_Plan_Claims has been updated. If the max date from the PlanDB
	-- is greater than the Rollup value max date than set the RollupState = 'OutOfDate'
	-------------------------------------------------------------------------
	-- Check to see if [#xref_Client_Connections] table has data, if yes then process tbl_Plan_Claims logic

	--IF EXISTS (SELECT TOP 1 Id FROM [#xref_Client_Connections]) 
	--BEGIN
	--	-- Determine max populated date from PlanDBs
	--	DECLARE @SQL NVARCHAR(MAX) = ''
	--	DECLARE @MinRowID INT
	--	DECLARE @MaxRowID INT
	--	DECLARE @CurrentRowID INT
	--	DECLARE @ConnectionName VARCHAR(100)
	--	DECLARE @MaxPlanDBPopulatedDate DATETIME

	--	SELECT @MinRowID = MIN(ID)
	--		FROM [#xref_Client_Connections]

	--	SELECT @MaxRowID = MAX(ID)
	--		FROM [#xref_Client_Connections]

	--	SET @CurrentRowID = @MinRowID

	--	SET @SQL = 'SELECT @MaxPlanDBPopulatedDate = MAX(MaxPlanDBPopulatedDate)
	--		FROM ( '

	--	WHILE @CurrentRowID <= @MaxRowID
	--	BEGIN
	--		SELECT @ConnectionName = tc.Connection_Name
	--		FROM [HRPReporting].dbo.tbl_Connection tc WITH (NOLOCK)
	--		INNER JOIN [#xref_Client_Connections] xcc
	--		ON tc.Connection_ID = xcc.Connection_ID
	--		WHERE xcc.ID = @CurrentRowID

	--		SET @SQL = @SQL + ' SELECT MAX(ISNULL(RPL.LoadDate, TPC.Populated)) AS MaxPlanDBPopulatedDate
	--			FROM ' + @ConnectionName + '.dbo.tbl_Plan_Claims TPC WITH (NOLOCK)
	--			LEFT JOIN (
	--				SELECT MAX(RPCParameterLoggingID) AS RPCParameterLoggingID
	--					,Claim_ID
	--				FROM ' + @ConnectionName + '.dbo.tbl_Plan_Claims_Validation WITH (NOLOCK)
	--				GROUP BY Claim_ID
	--				) AS TPCV ON TPCV.Claim_ID = TPC.Claim_ID
	--			LEFT JOIN ' + @ConnectionName + '.dbo.RPCParameterLogging RPL WITH (NOLOCK)
	--			ON RPL.RPCParameterLoggingID = TPCV.RPCParameterLoggingID'

	--		IF @CurrentRowID <> @MaxRowID
	--			SET @SQL = @SQL + ' UNION '

	--		SET @CurrentRowID = @CurrentRowID + 1
	--	END

	--	SET @SQL = @SQL + ') q'

	--	EXEC sp_executesql @SQL, N'@MaxPlanDBPopulatedDate DATETIME out', @MaxPlanDBPopulatedDate out

	--	-- Determine max populated date from ClientReportDB
	--	DECLARE @Report_DB VARCHAR(128)
	--	DECLARE @MaxClientReportDBPopulatedDate DATETIME

	--	SELECT @Report_DB = Report_DB
	--	FROM [HRPReporting].dbo.tbl_Clients tc WITH (NOLOCK)
	--	WHERE Client_ID = @Client_ID

	--	SET @SQL = 'SELECT @MaxClientReportDBPopulatedDate = MAX(Populated)
	--		FROM ' + @Report_DB + '.[dbo].[tbl_Plan_Claims_rollup] WITH (NOLOCK)'

	--	EXEC sp_executesql @SQL, N'@MaxClientReportDBPopulatedDate DATETIME out', @MaxClientReportDBPopulatedDate out

	--	-- If max PlanDB populated date is greater than the ClientReportDB populated date then set the RollupState
	--	-- of dbo.RollupTableStatus to 'OutOfDate'
	--	IF @MaxPlanDBPopulatedDate > @MaxClientReportDBPopulatedDate
	--	BEGIN
	--		UPDATE rts
	--			SET RollupState = 'OutOfDate',
	--				ModifiedDate = GETDATE()						
	--		FROM dbo.RollupTableStatus rts WITH(NOLOCK)
	--		WHERE EXISTS (
	--			SELECT 1
	--			FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
	--			INNER JOIN dbo.RollupTable rt WITH(NOLOCK)
	--			ON rtc.RollupTableID = rt.RollupTableID
	--			WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
	--			AND rt.RollupTableName = 'tbl_Plan_Claims_rollup'
	--			AND rtc.ClientIdentifier = @ClientIdentifier)
	--			AND rts.RollupState <> 'OutOfDate'
	--	END
	--END 

 
	------------------------------------------------------------------------
	-- Check to see when the last time tbl_Plan_Claims_Validation has been updated. If the max date from the PlanDB
	-- is greater than the Rollup value max date than set the RollupState = 'OutOfDate'
	-------------------------------------------------------------------------
	-- Check to see if [#xref_Client_Connections] table has data, if yes then process tbl_Plan_Claims_Validation logic
	IF EXISTS (SELECT TOP 1 Id FROM [#xref_Client_Connections]) 
	BEGIN
		-- Determine max populated date from PlanDBs
		SET @SQL = ''

		SELECT @MinRowID = MIN(ID)
			FROM [#xref_Client_Connections]

		SELECT @MaxRowID = MAX(ID)
			FROM [#xref_Client_Connections]

		SET @CurrentRowID = @MinRowID

		SET @SQL = 'SELECT @MaxPlanDBPopulatedDate = MAX(MaxPlanDBPopulatedDate)
			FROM ( '

		WHILE @CurrentRowID <= @MaxRowID
		BEGIN
			SELECT @ConnectionName = tc.Connection_Name
			FROM [$(HRPReporting)].dbo.tbl_Connection tc WITH (NOLOCK)
			INNER JOIN [#xref_Client_Connections] xcc
			ON tc.Connection_ID = xcc.Connection_ID
			WHERE xcc.ID = @CurrentRowID

			SET @SQL = @SQL + ' SELECT MAX(LoadDate) AS MaxPlanDBPopulatedDate
				FROM ' + @ConnectionName + '.dbo.tbl_Plan_Claims_Validation WITH (NOLOCK)'

			IF @CurrentRowID <> @MaxRowID
				SET @SQL = @SQL + ' UNION '

			SET @CurrentRowID = @CurrentRowID + 1
		END

		SET @SQL = @SQL + ') q'

		EXEC sp_executesql @SQL, N'@MaxPlanDBPopulatedDate DATETIME out', @MaxPlanDBPopulatedDate out

		-- Determine max populated date from ClientReportDB
		SET @SQL = 'SELECT @MaxClientReportDBPopulatedDate = MAX(LoadDate)
			FROM ' + @Report_DB + '.dbo.tbl_Plan_Claims_Validation_rollup WITH (NOLOCK)'

		EXEC sp_executesql @SQL, N'@MaxClientReportDBPopulatedDate DATETIME out', @MaxClientReportDBPopulatedDate out

		-- If max PlanDB load date is greater than the ClientReportDB load date then set the RollupState
		-- of dbo.RollupTableStatus to 'OutOfDate'
		IF @MaxPlanDBPopulatedDate > @MaxClientReportDBPopulatedDate
		BEGIN
			UPDATE rts
				SET RollupState = 'OutOfDate',
					ModifiedDate = GETDATE()						
			FROM dbo.RollupTableStatus rts WITH(NOLOCK)
			WHERE EXISTS (
				SELECT 1
				FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
				INNER JOIN dbo.RollupTable rt WITH(NOLOCK)
				ON rtc.RollupTableID = rt.RollupTableID
				WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
				AND rt.RollupTableName = 'tbl_Plan_Claims_Validation_rollup'
				AND rtc.ClientIdentifier = @ClientIdentifier)
				AND rts.RollupState <> 'OutOfDate'
		END
	END
 
	------------------------------------------------------------------------
	-- Check to see when the last time RAPS_Detail has been updated. If the max date from the PlanDB
	-- is greater than the Rollup value max date than set the RollupState = 'OutOfDate'
	-------------------------------------------------------------------------
	-- Check to see if [#xref_Client_Connections] table has data, if yes then process RAPS_Detail logic
	--IF EXISTS (SELECT TOP 1 Id FROM [#xref_Client_Connections]) 
	--BEGIN
	--	-- Determine max populated date from PlanDBs
	--	SET @SQL = ''

	--	SELECT @MinRowID = MIN(ID)
	--		FROM [#xref_Client_Connections]

	--	SELECT @MaxRowID = MAX(ID)
	--		FROM [#xref_Client_Connections]

	--	SET @CurrentRowID = @MinRowID

	--	SET @SQL = 'SELECT @MaxPlanDBPopulatedDate = MAX(MaxPlanDBPopulatedDate)
	--		FROM ( '

	--	WHILE @CurrentRowID <= @MaxRowID
	--	BEGIN
	--		SELECT @ConnectionName = tc.Connection_Name
	--		FROM [HRPReporting].dbo.tbl_Connection tc WITH (NOLOCK)
	--		INNER JOIN [#xref_Client_Connections] xcc
	--		ON tc.Connection_ID = xcc.Connection_ID
	--		WHERE xcc.ID = @CurrentRowID

	--		SET @SQL = @SQL + ' SELECT MAX(IMPORTED_DATE) AS MaxPlanDBPopulatedDate
	--			FROM ' + @ConnectionName + '.dbo.RAPS_Detail WITH (NOLOCK)'

	--		IF @CurrentRowID <> @MaxRowID
	--			SET @SQL = @SQL + ' UNION '

	--		SET @CurrentRowID = @CurrentRowID + 1
	--	END

	--	SET @SQL = @SQL + ') q'

	--	EXEC sp_executesql @SQL, N'@MaxPlanDBPopulatedDate DATETIME out', @MaxPlanDBPopulatedDate out

	--	-- Determine max populated date from ClientReportDB
	--	SET @SQL = 'SELECT @MaxClientReportDBPopulatedDate = MAX(IMPORTED_DATE)
	--		FROM ' + @Report_DB + '.dbo.RAPS_Detail_rollup WITH (NOLOCK)'

	--	EXEC sp_executesql @SQL, N'@MaxClientReportDBPopulatedDate DATETIME out', @MaxClientReportDBPopulatedDate out

	--	-- If max PlanDB load date is greater than the ClientReportDB load date then set the RollupState
	--	-- of dbo.RollupTableStatus to 'OutOfDate'
	--	IF @MaxPlanDBPopulatedDate > @MaxClientReportDBPopulatedDate
	--	BEGIN
	--		UPDATE rts
	--			SET RollupState = 'OutOfDate',
	--				ModifiedDate = GETDATE()						
	--		FROM dbo.RollupTableStatus rts WITH(NOLOCK)
	--		WHERE EXISTS (
	--			SELECT 1
	--			FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
	--			INNER JOIN dbo.RollupTable rt WITH(NOLOCK)
	--			ON rtc.RollupTableID = rt.RollupTableID
	--			WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
	--			AND rt.RollupTableName = 'RAPS_Detail_rollup'
	--			AND rtc.ClientIdentifier = @ClientIdentifier)
	--			AND rts.RollupState <> 'OutOfDate'
	--	END
	--END

	------------------------------------------------------------------------
	-- Check to see when the last time CNRAPSImportDetail has been updated. If the max date from the PlanDB
	-- is greater than the Rollup value max date than set the RollupState = 'OutOfDate'
	-------------------------------------------------------------------------
	-- Check to see if [#xref_Client_Connections] table has data, if yes then process CNRAPSImportDetail logic
	IF EXISTS (SELECT TOP 1 Id FROM [#xref_Client_Connections]) 
	BEGIN
		-- Determine max populated date from PlanDBs
		SET @SQL = ''

		SELECT @MinRowID = MIN(ID)
			FROM [#xref_Client_Connections]

		SELECT @MaxRowID = MAX(ID)
			FROM [#xref_Client_Connections]

		SET @CurrentRowID = @MinRowID

		SET @SQL = 'SELECT @MaxPlanDBPopulatedDate = MAX(MaxPlanDBPopulatedDate)
			FROM ( '

		WHILE @CurrentRowID <= @MaxRowID
		BEGIN
			SELECT @ConnectionName = tc.Connection_Name
			FROM [$(HRPReporting)].dbo.tbl_Connection tc WITH (NOLOCK)
			INNER JOIN [#xref_Client_Connections] xcc
			ON tc.Connection_ID = xcc.Connection_ID
			WHERE xcc.ID = @CurrentRowID

			SET @SQL = @SQL + ' SELECT MAX(IMPORTED_DATE) AS MaxPlanDBPopulatedDate
				FROM ' + @ConnectionName + '.dbo.CNRAPSImportDetail WITH (NOLOCK)'

			IF @CurrentRowID <> @MaxRowID
				SET @SQL = @SQL + ' UNION '

			SET @CurrentRowID = @CurrentRowID + 1
		END

		SET @SQL = @SQL + ') q'

		EXEC sp_executesql @SQL, N'@MaxPlanDBPopulatedDate DATETIME out', @MaxPlanDBPopulatedDate out

		-- Determine max populated date from ClientReportDB
		SET @SQL = 'SELECT @MaxClientReportDBPopulatedDate = MAX(IMPORTED_DATE)
			FROM ' + @Report_DB + '.dbo.CNRAPSImportDetail_rollup WITH (NOLOCK)'

		EXEC sp_executesql @SQL, N'@MaxClientReportDBPopulatedDate DATETIME out', @MaxClientReportDBPopulatedDate out

		-- If max PlanDB load date is greater than the ClientReportDB load date then set the RollupState
		-- of dbo.RollupTableStatus to 'OutOfDate'
		IF @MaxPlanDBPopulatedDate > @MaxClientReportDBPopulatedDate
		BEGIN
			UPDATE rts
				SET RollupState = 'OutOfDate',
					ModifiedDate = GETDATE()						
			FROM dbo.RollupTableStatus rts WITH(NOLOCK)
			WHERE EXISTS (
				SELECT 1
				FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
				INNER JOIN dbo.RollupTable rt WITH(NOLOCK)
				ON rtc.RollupTableID = rt.RollupTableID
				WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
				AND rt.RollupTableName = 'CNRAPSImportDetail_rollup'
				AND rtc.ClientIdentifier = @ClientIdentifier)
				AND rts.RollupState <> 'OutOfDate'
		END
	END

	------------------------------------------------------------------------
	-- Check to see when the last time RAPS_RETURN has been updated. If the max date from the PlanDB
	-- is greater than the Rollup value max date than set the RollupState = 'OutOfDate'
	-------------------------------------------------------------------------
	-- Check to see if [#xref_Client_Connections] table has data, if yes then process RAPS_RETURN logic
	IF EXISTS (SELECT TOP 1 Id FROM [#xref_Client_Connections]) 
	BEGIN
		-- Determine max populated date from PlanDBs
		SET @SQL = ''

		SELECT @MinRowID = MIN(ID)
			FROM [#xref_Client_Connections]

		SELECT @MaxRowID = MAX(ID)
			FROM [#xref_Client_Connections]

		SET @CurrentRowID = @MinRowID

		SET @SQL = 'SELECT @MaxPlanDBPopulatedDate = MAX(MaxPlanDBPopulatedDate)
			FROM ( '

		WHILE @CurrentRowID <= @MaxRowID
		BEGIN
			SELECT @ConnectionName = tc.Connection_Name
			FROM [$(HRPReporting)].dbo.tbl_Connection tc WITH (NOLOCK)
			INNER JOIN [#xref_Client_Connections] xcc
			ON tc.Connection_ID = xcc.Connection_ID
			WHERE xcc.ID = @CurrentRowID

			SET @SQL = @SQL + ' SELECT MAX(IMPORTED_DATE) AS MaxPlanDBPopulatedDate
				FROM ' + @ConnectionName + '.dbo.RAPS_RETURN WITH (NOLOCK)'

			IF @CurrentRowID <> @MaxRowID
				SET @SQL = @SQL + ' UNION '

			SET @CurrentRowID = @CurrentRowID + 1
		END

		SET @SQL = @SQL + ') q'

		EXEC sp_executesql @SQL, N'@MaxPlanDBPopulatedDate DATETIME out', @MaxPlanDBPopulatedDate out

		-- Determine max populated date from ClientReportDB
		SET @SQL = 'SELECT @MaxClientReportDBPopulatedDate = MAX(IMPORTED_DATE)
			FROM ' + @Report_DB + '.dbo.RAPS_RETURN_rollup WITH (NOLOCK)'

		EXEC sp_executesql @SQL, N'@MaxClientReportDBPopulatedDate DATETIME out', @MaxClientReportDBPopulatedDate out

		-- If max PlanDB load date is greater than the ClientReportDB load date then set the RollupState
		-- of dbo.RollupTableStatus to 'OutOfDate'
		IF @MaxPlanDBPopulatedDate > @MaxClientReportDBPopulatedDate
		BEGIN
			UPDATE rts
				SET RollupState = 'OutOfDate',
					ModifiedDate = GETDATE()						
			FROM dbo.RollupTableStatus rts WITH(NOLOCK)
			WHERE EXISTS (
				SELECT 1
				FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
				INNER JOIN dbo.RollupTable rt WITH(NOLOCK)
				ON rtc.RollupTableID = rt.RollupTableID
				WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
				AND rt.RollupTableName = 'RAPS_RETURN_rollup'
				AND rtc.ClientIdentifier = @ClientIdentifier)
				AND rts.RollupState <> 'OutOfDate'
		END
	END
	-------------------------------------------------------------------------
	-- Indicate that when the Last time the source tables where checked
	-------------------------------------------------------------------------
	--Update rts
	--	SET    LastStateCheckDate = 
	--				(SELECT Isnull((SELECT Max([rs].[restore_date]) restore_date
	--					FROM   master.sys.databases d (nolock)
	--						   JOIN msdb.dbo.restorehistory rs (nolock)
	--							 ON d.name = rs.destination_database_name
	--					WHERE  d.name = 'HRPReporting'), Getdate())) 
	--From dbo.RollupTableStatus rts
	--WHERE EXISTS (
	--			SELECT 1
	--			FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
	--			WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
	--			AND rtc.ClientIdentifier = @ClientIdentifier)

	Update rts
		SET    LastStateCheckDate = 
					(SELECT Isnull(Max(d.create_date), Getdate()) as create_date
						FROM   master.sys.databases d (nolock)
						WHERE  d.name = 'HRPReporting') 
	From dbo.RollupTableStatus rts
	WHERE EXISTS (
				SELECT 1
				FROM dbo.RollupTableConfig rtc WITH(NOLOCK)
				WHERE rtc.RollupTableConfigID = rts.RollupTableConfigID
				AND rtc.ClientIdentifier = @ClientIdentifier)

--RE- 7195 Begin
--- Insert OutofDate Records to RollupRunGroup table ------

if (object_id('[dbo].[RollupRunGroupLog]') is not null)

BEGIN

Delete from [dbo].[RollupRunGroupLog] where ClientIdentifier=@Client_ID

End 

Insert into [dbo].[RollupRunGroupLog]  
(
[RollupTableConfigID],
[RunGroup],
[ClientIdentifier]
)

Select rtc.RollupTableConfigID,rt.RunGroup,@Client_ID as [ClientIdentifier]
	From dbo.RollupTableConfig rtc
	Inner Join dbo.RollupTable rt
		On rtc.RollupTableID = rt.RollupTableID
	Inner Join dbo.RollupTableStatus rts
		On rtc.RollupTableConfigID = rts.RollupTableConfigID
		 And rts.RollupState = 'OutOfDate'
	Inner Join dbo.RollupClient rc
		On rtc.ClientIdentifier = rc.ClientIdentifier
		And rc.Active = 1
		And rc.UseForRollup = 1	
	Where rtc.ClientIDentifier = @Client_ID
	And rtc.Active = 1
 
--RE- 7195 End


Commit Transaction	

End Try

-------------------------------------------------------------------------
-- Error handling
-------------------------------------------------------------------------	
Begin Catch
	If (XACT_STATE() = 1 Or XACT_STATE() = -1)
		Rollback Transaction
			  			    				
	Declare @ErrorMsg varchar(2000)
	Set @ErrorMsg = 'Error: ' + IsNull(Error_Procedure(),'script') + ': ' +  Error_Message() +
				    ', Error Number: ' + cast(Error_Number() as varchar(10)) + ' Line: ' + 
				    cast(Error_Line() as varchar(50))
	
	Raiserror (@ErrorMsg, 16, 1)

End Catch
