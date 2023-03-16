CREATE PROCEDURE [rev].[spr_Summary_RskAdj_AltHICN]
    (
      @LoadDateTime DATETIME = NULL ,
      @DeleteBatch INT = NULL ,
      @RowCount INT OUT ,
      @Debug BIT = 0
    )
AS 
/******************************************************************************************************************************************* 
* Name			:	rev.spr_Summary_RskAdj_AltHICN													
* Type 			:	Stored Procedure																
* Author       	:	Mitch Casto																		
* Date			:	2016-03-21																		
* Version			:																				
* Description		: Updates dbo.tbl_Summary_RskAdj_AltHICN table with AltHICN data				
*					This stp is an adaptation from Summary 1.0 and will need further work to		
*					optimize the sql.																
* SP Test		:	[rev].[spr_Summary_RskAdj_AltHICN] NULL, NULL, 0, 0																									
* Version History :																					
* =================================================================================================	
* Author			Date		Version#    TFS Ticket#		Description								
* -----------------	----------  --------    -----------		------------							
* Mitch Casto		2016-03-21	1.0			52224			Initial									
* Mitch Casto		2016-05-18	1.1			53367			Add @ManualRun to remove requirment for	
*															table ownership for Truncation when run	
*															manually								
* Mitch Casto		2017-03-27	1.2			63302/US63790	Removed @ManualRun process and replaced with parameterized delete batch (Section 002 to 005)			
* Madhuri Suri      2017-06-06  1.3         65131           AltHICN Logic change					
* Rakshit Lall		2018-05-07	1.4			70863			Added update/insert logic for adding MBI
* Rakshit Lall		2018-06-12	1.5			71613			Modified the SP to add a LEFT JOIN on PlanID to pull all the plans for the HICNs
* Rakshit Lall		2018-07-16	1.6			72012			Re-added the update which was once removed
* Rakshit Lall		2018-07-18	1.7			72012			Mapped "LastUpdatedInSource", "LoadDateTime" and "UserID" column mappings
* Rakshit Lall		2018-07-31	1.8			72012			Added update to fix MBI updates missed for some HICNs
* Rakshit Lall		2018-08-14	1.9			72527			Fixed the 2nd update for the AltHICN column
* Madhuri Suri      2018-09-24  2.0         76879           Summary 2.5 Changes
* Madhuri Suri      2018-09-24  2.1         77181           Summary 2.5 Changes - 2*
********************************************************************************************************************************************/
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

BEGIN 
    SET STATISTICS IO OFF
    SET NOCOUNT ON

    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            DECLARE @ProcessNameIn VARCHAR(128)
            SET @ET = GETDATE()
            SET @MasterET = @ET
            SET @ProcessNameIn = OBJECT_NAME(@@PROCID)
            EXEC [dbo].[PerfLogMonitor] @Section = '000',
                @ProcessName = @ProcessNameIn, @ET = @ET,
                @MasterET = @MasterET, @ET_Out = @ET OUT, @TableOutput = 0,
                @End = 0
        END


    SET @LoadDateTime = ISNULL(@LoadDateTime, GETDATE())
    SET @DeleteBatch = ISNULL(@DeleteBatch, 20000)

	DECLARE @UserID VARCHAR(128) = SYSTEM_USER

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '001', @ProcessNameIn, @ET, @MasterET,
                @ET OUT, 0, 0
        END

    /*B Truncate Or Delete rows in rev.tbl_Summary_RskAdj_AltHICN */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '002', @ProcessNameIn, @ET, @MasterET,
                @ET OUT, 0, 0
        END

    --            TRUNCATE TABLE [rev].[tbl_Summary_RskAdj_AltHICN]

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '003', @ProcessNameIn, @ET, @MasterET,
                @ET OUT, 0, 0
        END


    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '004', @ProcessNameIn, @ET, @MasterET,
                @ET OUT, 0, 0
        END

    WHILE ( 1 = 1 )
        BEGIN

            DELETE TOP ( @DeleteBatch )
            FROM    [rev].[tbl_Summary_RskAdj_AltHICN]

            IF @@ROWCOUNT = 0
                BREAK
            ELSE
                CONTINUE
        END



    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '005', @ProcessNameIn, @ET, @MasterET,
                @ET OUT, 0, 0
        END

    /*E Truncate Or Delete rows in rev.tbl_Summary_RskAdj_AltHICN */

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '006', @ProcessNameIn, @ET, @MasterET,
                @ET OUT, 0, 0
        END

----------------------------------------------------------------------------------------------------------------------------------------------------  
    IF OBJECT_ID('[tempdb].[dbo].[#tbl_althicn]', 'U') IS NOT NULL
        DROP TABLE #tbl_althicn  
    
	CREATE TABLE dbo.#tbl_althicn
        (
          ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
          HICN VARCHAR(24) NULL ,
          FINALHICN VARCHAR(24) NULL,
          PlanIdentifier SMALLINT NULL ,
          LastUpdated DATETIME NULL
        )  
  

    INSERT  INTO #tbl_althicn
            ( HICN ,
              FINALHICN ,
              PlanIdentifier ,
              LastUpdated
            )
            SELECT DISTINCT
                    HICN ,
                    FinalHICN ,
                    PlanIdentifier ,
                    LastUpdated
            FROM    dbo.tbl_AltHICN_rollup
            UNION
            SELECT DISTINCT
                    ALTHICN ,
                    FinalHICN ,
                    PlanIdentifier ,
                    LastUpdated
            FROM    dbo.tbl_AltHICN_rollup 
      
 ----------------------------------------------------------------------------------------------------------------------------------------------------  
    IF OBJECT_ID('[tempdb].[dbo].[#AltHICNLastupdated]', 'U') IS NOT NULL
        DROP TABLE #AltHICNLastupdated  
    
    CREATE TABLE dbo.#AltHICNLastupdated
        (
          ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
          Row1 VARCHAR(24) NULL,
          HICN VARCHAR(24) NULL ,
          FInalHICN VARCHAR(24) NULL ,
          PlanIdentifier SMALLINT NULL ,
          LastUpdated DATETIME NULL
        )  
  

    INSERT  INTO #AltHICNLastupdated
            ( Row1 ,
              HICN ,
              FINALHICN ,
              PlanIdentifier ,
              LastUpdated
            )
            SELECT DISTINCT
                    RANK() OVER ( PARTITION BY a.HICN, PlanIdentifier ORDER BY a.LastUpdated DESC ) AS Row1 ,
                    HICN ,
                    FinalHICN ,
                    PlanIdentifier ,
                    LastUpdated
            FROM    #tbl_althicn a
            ORDER BY LastUpdated DESC 
        
        
    INSERT  INTO [rev].[tbl_Summary_RskAdj_AltHICN]
		( 
			[PlanID] ,
            [HICN] ,
            [FINALHICN] ,
            [LoadDateTime] ,
			[LastUpdatedInSource] ,
			[UserID]
        )
            SELECT  PlanIdentifier ,
                    hicn ,
                    FInalHICN ,
					@LoadDateTime ,
                    LastUpdated ,
					@UserID
            FROM    #AltHICNLastupdated
            WHERE   Row1 = 1      
    SET @RowCount = @@ROWCOUNT

    /* Get the <Client>_ClientLevel DB value in a variable */

	DECLARE
	@ClientLevelDB VARCHAR(50)

	SELECT 
		@ClientLevelDB = C.Client_DB
	FROM [$(HRPReporting)].dbo.tbl_Clients C
	WHERE
		C.Report_DB = DB_NAME()

	--SELECT @ClientLevelDB

	/* 
		Update the FinalHICN in the table with MBI and LastAssignedHICN with FinalHICN
		and 
		Update set where FinalHICN is NOT available in the ssnri.MBIAltHICNCrosswalk table 
	*/

	DECLARE @Updates VARCHAR(6000)

	SELECT @Updates = 
	'
	UPDATE a
	SET 
		a.LastAssignedHICN = a.FinalHICN,
		a.FINALHICN = b.MBI,
		a.LoadDateTime = ''' + CAST(@LoadDateTime AS VARCHAR(20)) + '''
	FROM rev.tbl_Summary_RskAdj_AltHICN a
	JOIN ' + @ClientLevelDB + '.ssnri.MBIAltHICNCrosswalk b
		ON a.FinalHICN = b.AltHICN
	
	UPDATE a
	SET 
		a.LastAssignedHICN = CASE 
								WHEN a.FINALHICN = b.MBI
								THEN a.HICN
								ELSE a.FinalHICN
								END,
		a.FINALHICN = b.MBI,
		a.LoadDateTime = ''' + CAST(@LoadDateTime AS VARCHAR(20)) + '''
	FROM rev.tbl_Summary_RskAdj_AltHICN a
	JOIN ' + @ClientLevelDB + '.ssnri.MBIAltHICNCrosswalk b
		ON a.HICN = COALESCE(b.AltHICN, b.FinalHICN)
	WHERE
		(a.LastAssignedHICN IS NULL OR a.LastAssignedHICN = '''')

	UPDATE HCN
	SET
		HCN.FinalHICN = b.MBI,
		HCN.LastAssignedHICN = HCN.FINALHICN,
		HCN.LoadDateTime = ''' + CAST(@LoadDateTime AS VARCHAR(20)) + '''
	FROM rev.tbl_Summary_RskAdj_AltHICN HCN
	JOIN rev.tbl_Summary_RskAdj_AltHICN LAHCN
		ON HCN.HICN = LAHCN.LastAssignedHICN
	JOIN ' + @ClientLevelDB + '.ssnri.MBIAltHICNCrosswalk b
		ON COALESCE(b.FinalHICN, b.AltHICN) = LAHCN.HICN
	WHERE
		HCN.LastAssignedHICN IS NULL
	AND
		HCN.HICN <> b.MBI
	'
	
	EXEC (@Updates)
	
	/* Insert the HICN MBI Crosswalk records that didn't have a HICN in the "tbl_Summary_RskAdj_AltHICN" table */

	DECLARE @Inserts VARCHAR(6000)

	SELECT @Inserts =
	'
	INSERT INTO rev.tbl_Summary_RskAdj_AltHICN
	(
		PlanID,
		HICN,
		FINALHICN,
		LastAssignedHICN,
		LoadDateTime,
		LastUpdatedInSource,
		UserID
	)
	SELECT 
		b.PlanIdentifier AS PlanID,
		a.AltHICN AS HICN,
		a.MBI AS FINALHICN,
		CASE 
			WHEN ssnri.fnValidateMBI(a.FinalHICN) = 0 
			THEN a.FinalHICN
		END AS LastAssignedHICN, '''
		+ CAST(@LoadDateTime AS VARCHAR(20)) + ''' AS LoadDateTime,
		a.Loaddate AS LastUpdatedInSource, '''
		+ @UserID + ''' AS UserID
	FROM ' + @ClientLevelDB + '.ssnri.MBIAltHICNCrosswalk a
	JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan b
		ON RIGHT(PlanDB, 5) = b.PlanId
	LEFT JOIN rev.tbl_Summary_RskAdj_AltHICN c
		ON c.HICN = a.AltHICN
		AND c.PlanID = b.PlanIdentifier
	WHERE 
		c.HICN IS NULL
	'

	EXEC (@Inserts)

---------NEW LOGIC FOR UPDATING ALTHICN FOR ALL SUMMARY TABLES-----
declare @MMR_FLAG  bit = (SELECT RunFlag FROM rev.SummaryProcessRunFlag WHERE Process = 'MMR')
    , @ALT_HICN  bit = (SELECT RunFlag FROM rev.SummaryProcessRunFlag WHERE Process = 'ALTHICN')
    , @MOR_FLAG  bit = (SELECT RunFlag FROM rev.SummaryProcessRunFlag WHERE Process = 'MOR')
    , @RAPS_FLAG bit = (SELECT RunFlag FROM rev.SummaryProcessRunFlag WHERE Process = 'RAPS')
    , @EDS_FLAG  bit = (SELECT RunFlag FROM rev.SummaryProcessRunFlag WHERE Process = 'EDS')
	, @EDSSrc_FLAG  bit = (SELECT RunFlag FROM rev.SummaryProcessRunFlag WHERE Process = 'EDSSrc')


	---AltHICN update logic for all tables 

	  CREATE TABLE [#Refresh_PY] (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY
      , [Payment_Year] INT
      , [From_Date] SMALLDATETIME
      , [Thru_Date] SMALLDATETIME
      , [Lagged_From_Date] SMALLDATETIME
      , [Lagged_Thru_Date] SMALLDATETIME)

    INSERT INTO [#Refresh_PY] ([Payment_Year]
                             , [From_Date]
                             , [Thru_Date]
                             , [Lagged_From_Date]
                             , [Lagged_Thru_Date])
    SELECT [Payment_Year] = [a1].[Payment_Year]
         , [From_Date] = [a1].[From_Date]
         , [Thru_Date] = [a1].[Thru_Date]
         , [Lagged_From_Date] = [a1].[Lagged_From_Date]
         , [Lagged_Thru_Date] = [a1].[Lagged_Thru_Date]
      FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1]


---When althicn is 1 
IF @ALT_HICN = 1 AND @MMR_FLAG = 0

BEGIN   	   
	  /*[tbl_Summary_RskAdj_MMR]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_MMR] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanID = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	 WHERE  althcn.FINALHICN IS NOT NULL 
END

IF @ALT_HICN = 1 AND @RAPS_FLAG = 0

BEGIN 
	  /*[tbl_Summary_RskAdj_RAPS_Preliminary]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_RAPS_Preliminary] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].[PlanIdentifier] = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].SummaryPartDRskAdjRAPSPreliminary a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].[PlanIdentifier] = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 
	
	  
	   
	  /*[tbl_Summary_RskAdj_RAPS]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_RAPS] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanID = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].SummaryPartDRskAdjRAPS a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 
	  /*[[tbl_Summary_RskAdj_RAPS_MOR_Combined]]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanID = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].SummaryPartDRskAdjRAPSMORDCombined a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

	END

IF @ALT_HICN = 1 AND @MOR_FLAG = 0

BEGIN 
	  /*[tbl_Summary_RskAdj_MOR]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_MOR] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanID = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].SummaryPartDRskAdjMORD a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

END

IF @ALT_HICN = 1 AND @EDSSrc_FLAG = 0

BEGIN    
   	  /*[[tbl_Summary_RskAdj_EDS_Source]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_EDS_Source] a
	   JOIN [#Refresh_PY] [py]
        ON  year([a].[ServiceEndDate]) + 1 = [py].[Payment_Year]
	join [$(HRPInternalReportsDB)].dbo.rollupplan r on r.planID = a.ContractID
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON r.PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 
END

IF @ALT_HICN = 1 AND @EDS_FLAG = 0

BEGIN 
	  /*[tbl_Summary_RskAdj_EDS_Preliminary]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_EDS_Preliminary] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].SummaryPartDRskAdjEDSPreliminary a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 
	   
	  /*[[tbl_Summary_RskAdj_EDS]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_EDS] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanID = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].SummaryPartDRskAdjEDS a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanIdentifier = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 

	   
	  /*[tbl_Summary_RskAdj_EDS_MOR_Combined]*/
Update a
SET a.HICN = ISNULL([althcn].[FINALHICN], [a].[HICN])
      FROM [rev].[tbl_Summary_RskAdj_EDS_MOR_Combined] a
	   JOIN [#Refresh_PY] [py]
        ON a.[PaymentYear] = [py].[Payment_Year]
      LEFT JOIN [rev].[tbl_Summary_RskAdj_AltHICN] [althcn]
        ON [a].PlanID = [althcn].[PlanID]
       AND [a].[HICN]           = [althcn].[HICN]
	    WHERE  althcn.FINALHICN IS NOT NULL 



END


END