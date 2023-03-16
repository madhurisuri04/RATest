CREATE PROCEDURE [rev].[spr_EstRecv_New_HCC]
    @Payment_Year_NewDeleteHCC VARCHAR(4),
    @PROCESSBY_START SMALLDATETIME,
    @PROCESSBY_END SMALLDATETIME,
    @ReportOutputByMonth CHAR(1),
    --= 'D' -- 'S' = Summary, 'D' = 'Detail Annualized'; 'M' = 'Detail per Member per Month'
    @RAPS_STRING_ALL VARCHAR(50),
    -- Ticket # 25657.
    @File_STRING_ALL VARCHAR(50),
    @SERVERNAME VARCHAR(257) = NULL,
    @ProcessRunId INT = -1,
    @Debug BIT = 0


/***********************************************************************************************************************************************************************************************************        
* Name			:	spr_EstRecv_New_HCC							                                                                                                                                           *                                                     
* Type 			:	Stored Procedure									                                                                                                                                   *                
* Author       	:	Kerri Phipps										                                                                                                                                   *
* Date          :	08/02/2013											                                                                                                                                   *	
* Version		:														                                                                                                                                   *
* Description	:	Get new HCCs from the roll up tables in                                                                                                                                                *
*					<Client>_Report database							                                                                                                                                   *
*					                                                                                                                                                                                       *                 
* Version History :                                                                                                                                                                                        *                
*  Author			Date		Version#    TFS Ticket#	Description                                                                                                                                        *
* -----------------	----------  --------    -----------	------------                                                                                                                                       *
* Balaji Dhanabalan	08/15/2013  2.0	    20730			Included Dynamic SQL to get rollup planID                                                                                                          *
* Balaji Dhanabalan 08/26/2013  3.0	    21625			Updated the control statement to match final output.                                                                                               *
*                                                                                                                                                                                                          *               
* Dan Kim			11/12/2013  3.1	    23088			Create new 'T' ReportOutput to write the 'M' output to dbo.EstRecHCCNewOutput                                                                      *
*  															This is for RADAR internal requirement and will not be displayed in ReconEdge.                                                                 *
* Ravi Chauhan      01/24/2014  3.2         24726           Modified BIDS for ESRD members.                                                                                                                *
* Ravi Chauhan      01/29/2014  3.3         24816           Implemented Condition Flag logic and added @RAPS_STRING parameter to select a PCN                                                              *
* Ravi Chauhan      02/09/2014  3.4         24942           Change to pull HCCs submimtted with a DOS for the initial risk scores but submitted by the initial sweep submission deadline.                  * 
* Ravi Chauhan      02/14/2014  3.5         25298           Modify Final Year sweep. Fix NULL values issue for the Processed_Priority_* and Thru_Priority_* fields.     								   *	 						
* Ravi Chauhan      02/24/2014  3.6         25351           Change to correct HCC descriptions for Blended Model.                                                                                          *
* Ravi Chauhan      02/25/2014  3.3         25426           Including Institutional beneficiaries (RAFT = I)  in the Blended Model.                                                                        * 
* Ravi Chauhan      03/17/2014  3.4         25315           Correct cross plan activity.                                                                                                                   *
* Ravi Chauhan      03/17/2014  3.5         25657           Modify PCN parameter prompt text to ALL.                                                                                                       *
* Ravi Chauhan      03/17/2014  3.6         25658           Move Plan level queries to Summary SP and just use Summary tables here.                                                                        *
* Ravi Chauhan      03/18/2014  3.7         25702           Change to pull HCCs that are submitted after Sep sweep deadline.                                                                               *
* Ravi Chauhan      03/20/2014  3.6         25953           To handle Alternate HICNs.                                                                                                                     *
* Ravi Chauhan      06/03/2014  3.7         26249           Update New HCC Procs so that it can automate the process for RADAR to consume the data                                                         *
* Ravi Chauhan      05/28/2014  3.8         26951           New HCC Report for Initial Projection.                                                                                                         *
* Ravi Chauhan      07/03/2014  3.9         29157           Roll Forward Indicator incorrect on the RevNav extract - T parameter and M parameter                                                           *
* Ravi Chauhan      08/26/2014  4.0         30626           New HCC report - Open 'T' parameter for 2015 Initial projection                                                                                *     
* Ravi Chauhan      10/19/2014  4.1         25703           Part C New HCC report Redesign                                                                                                                 *
* Ravi Chauhan      11/01/2014  4.2         32971           Fix duplicates in the T parameter output of New HCC.                                                                                           *
* Ravi Chauhan      11/07/2014  4.3         33186           Fix New HCC Performance issue running from ReconEdge.                                                                                          *
* Mitch Casto		11/14/2014  4.4					        Added ; to end of statements                                                                                                                   *
* Ravi Chauhan      12/12/2014  4.4         33931           Fix Valuation issue for Excellus and Health Spring client                                                                                      *
* Mitch Casto       11/14/2014  4.4         33815           Added capability to run in the Client_Report environment Added debugging code                                                                  *
* Ravi Chauhan      03/22/2015  4.5         36970           Part C New HCC and Delete HCC correction for use of lk_ratebook_ESRD                                                                           *
* Mitch Casto		06/10/2015  4.6			42494			Refactor code for 41262 & 42057                                                                                                                *
* David Waddell		11/18/2015	4.7			39388			added code to when condition in line 3723 -- address issue ident. causing var. between Plan version vs. Report version                         *
*																replaced ref. to .dbo.tbl_EstRecv_MMR mmr to .dbo.tbl_Summary_RskAdj_MMR in order to be in sync w. Plan version                            *
* David Waddell		01/14/2015	4.8			39388			add condition to terminate proc and display message if Report Output Month is Y and future year.                                               * 
* David Waddell     12/07/2016  4.9         59836           Risk Model: Part C New HCC Report to accommodate 2017PY Risk Model changes                                                                     *
* David Waddell     05/17/2017  5.0         64782            Convert Part C New HCC to Summary 2.0        (Section 021, 031, 054.1)                                                                        *
* Jenelle Samson	                        66188			Changed Aged to AgedStatus to make 'S' result sets match across all @Payment_Year_NewDeleteHCC values                                          *
*															Changed Aged to AgedStatu to make  'D' result sets match across all @Payment_Year_NewDeleteHCC values                                          *
*															MOVED position of model_year and Processed_By_Flag to make 'D' result sets match across all @Payment_Year_NewDeleteHCC values                  *
*															Also changed a few dynamic sql statements to include the "INSERT INTO table" clause to prevent a double INSERT INTO EXEC when run by           *
*                                                              ReconEdge Report Export function                                                                                                            *
* David Waddell     03/14/2018	5.1         70056           Resolve issue with legacy script issue with 2019 (Future Year) output. Add @Payment_Year_NewDeleteHCC <= YEAR(GETDATE() to ReportOutputByMonth *                                                                     *   
*                                                           in ('D','V') condition
* Rakshit Lall		06/27/2018	5.2			71870			Replaced the use of "dbo.tbl_EstRecv_ModelSplits" with "dbo.lk_Risk_Score_Factors_PartC"                                                                                                                                 *       
* David Waddell		03/06/2020  5.3			76254 (Re-5459) Modify to run at Report DB level  
************************************************************************************************************************************************************************************************************/

-- exec [spr_EstRecv_New_HCC] '2014','1/1/2013','12/31/2014','D','ALL','ALL'

--with recompile	
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

    DECLARE @Populated_Date DATETIME = GETDATE();

    -- Control statements below are included to support ETL architecture and must be the first statement in the procedure.
    -- Control statement will not be executed and has no impact on the procedure output. 
    -- The control statements must match the final output for @ReportOutputByMonth = 'M'.
    -- The field name, data type, and field order must be exactly as output for @ReportOutputByMonth = 'M'.
    -- The ETL process requests the metadata from the procedure and the first select is returned.

    /*Testing parameters*/

    --declare @Payment_Year_NewDeleteHCC		VARCHAR(4),   
    --	@PROCESSBY_START	SMALLDATETIME,    
    --	@PROCESSBY_END		SMALLDATETIME,    
    --	@ReportOutputByMonth varchar(1), --= 'D' -- 'S' = Summary, 'D' = 'Detail Annualized'; 'M' = 'Detail per Member per Month'
    --	@RAPS_STRING_ALL varchar(50),
    --	@File_STRING_ALL varchar(50),
    --	@SERVERNAME VARCHAR(257) = NULL,
    --	@DBNAME VARCHAR(128) = NULL


    --set @Payment_Year_NewDeleteHCC = '2013'
    --set @PROCESSBY_START = '1/1/2012'
    --set @PROCESSBY_END = '12/31/2014'
    --set @ReportOutputByMonth = 'D'
    --set @RAPS_STRING_ALL =  'ALL'
    --set @File_STRING_ALL = 'ALL'




    -- IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC AND  @ReportOutputByMonth = 'V' display error message and term proc
    IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
       AND @ReportOutputByMonth = 'V'
    BEGIN
        RAISERROR('Error Message: If ReportOutputByMonth = V, Payment Year cannot exceed Current Year.', 16, -1);

    END;




    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('000', 0, 1) WITH NOWAIT;
    END;


    IF 1 = 2
        SELECT CAST(NULL AS INT) AS PAYMENT_YEAR,
               CAST(NULL AS DATETIME) AS PAYMSTART,
               CAST(NULL AS SMALLDATETIME) AS PROCESSED_BY_START,
               CAST(NULL AS SMALLDATETIME) AS PROCESSED_BY_END,
               CAST(NULL AS VARCHAR(5)) AS PLANID,
               CAST(NULL AS VARCHAR(15)) AS HICN,
               CAST(NULL AS VARCHAR(10)) AS RA_FACTOR_TYPE,
               CAST(NULL AS DATETIME) AS PROCESSED_PRIORITY_PROCESSED_BY,
               CAST(NULL AS DATETIME) AS PROCESSED_PRIORITY_THRU_DATE,
               CAST(NULL AS VARCHAR(50)) AS PROCESSED_PRIORITY_PCN,
               CAST(NULL AS VARCHAR(20)) AS PROCESSED_PRIORITY_DIAG,
               CAST(NULL AS DATETIME) AS THRU_PRIORITY_PROCESSED_BY,
               CAST(NULL AS DATETIME) AS THRU_PRIORITY_THRU_DATE,
               CAST(NULL AS VARCHAR(50)) AS THRU_PRIORITY_PCN,
               CAST(NULL AS VARCHAR(20)) AS THRU_PRIORITY_DIAG,
               CAST(NULL AS VARCHAR(20)) AS HCC,
               CAST(NULL AS VARCHAR(255)) AS HCC_DESCRIPTION,
               CAST(NULL AS DECIMAL(20, 4)) AS FACTOR,
               CAST(NULL AS VARCHAR(20)) AS HIER_HCC_OLD,
               CAST(NULL AS DECIMAL(20, 4)) AS HIER_FACTOR_OLD,
               CAST(NULL AS VARCHAR(1)) AS ACTIVE_INDICATOR_FOR_ROLLFORWARD,
               CAST(NULL AS INT) AS MONTHS_IN_DCP,
               CAST(NULL AS VARCHAR(3)) AS ESRD,
               CAST(NULL AS VARCHAR(3)) AS HOSP,
               CAST(NULL AS VARCHAR(3)) AS PBP,
               CAST(NULL AS VARCHAR(5)) AS SCC,
               CAST(NULL AS MONEY) AS BID,
               CAST(NULL AS MONEY) AS ESTIMATED_VALUE,
               CAST(NULL AS VARCHAR(50)) AS RAPS_SOURCE,
               CAST(NULL AS VARCHAR(40)) AS PROVIDER_ID,
               CAST(NULL AS VARCHAR(55)) AS PROVIDER_LAST,
               CAST(NULL AS VARCHAR(55)) AS PROVIDER_FIRST,
               CAST(NULL AS VARCHAR(80)) AS PROVIDER_GROUP,
               CAST(NULL AS VARCHAR(100)) AS PROVIDER_ADDRESS,
               CAST(NULL AS VARCHAR(30)) AS PROVIDER_CITY,
               CAST(NULL AS VARCHAR(2)) AS PROVIDER_STATE,
               CAST(NULL AS VARCHAR(13)) AS PROVIDER_ZIP,
               CAST(NULL AS VARCHAR(15)) AS PROVIDER_PHONE,
               CAST(NULL AS VARCHAR(15)) AS PROVIDER_FAX,
               CAST(NULL AS VARCHAR(55)) AS TAX_ID,
               CAST(NULL AS VARCHAR(20)) AS NPI,
               CAST(NULL AS DATETIME) AS SWEEP_DATE;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('001', 0, 1) WITH NOWAIT;
    END;

    DECLARE @fromdate DATETIME;
    DECLARE @thrudate DATETIME;
    DECLARE @initial_flag DATETIME;
    DECLARE @myu_flag DATETIME;
    DECLARE @final_flag DATETIME;
    DECLARE @clientlvldb VARCHAR(128);
    DECLARE @MaxBidPY VARCHAR(5);
    DECLARE @MaxESRDPY INT;
    DECLARE @open_qry_sql NVARCHAR(MAX);

    -- Performance Tuning (Created Temp Table) Start

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('002', 0, 1) WITH NOWAIT;
    END;

    SELECT @fromdate = '1/1/' + CAST(@Payment_Year_NewDeleteHCC - 1 AS VARCHAR(4)); -- Ticket # 26951  Performance Tuning Removed the unnecessary CAST

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('003', 0, 1) WITH NOWAIT;
    END;


    SELECT @thrudate = '12/31/' + CAST(@Payment_Year_NewDeleteHCC - 1 AS VARCHAR(4)); -- Ticket # 26951 Performance Tuning Removed the unnecessary CAST

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('004', 0, 1) WITH NOWAIT;
    END;


    SELECT @initial_flag =
    (
        SELECT MIN(Initial_Sweep_Date)
        FROM [$(HRPReporting)].dbo.lk_DCP_dates
        WHERE SUBSTRING(PayMonth, 1, 4) = @Payment_Year_NewDeleteHCC
              AND Mid_Year_Update IS NULL
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

    SELECT @myu_flag =
    (
        SELECT MAX(Initial_Sweep_Date)
        FROM [$(HRPReporting)].dbo.lk_DCP_dates
        WHERE SUBSTRING(PayMonth, 1, 4) = @Payment_Year_NewDeleteHCC
              AND Mid_Year_Update = 'Y'
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

    SELECT @final_flag =
    (
        SELECT MAX(Final_Sweep_Date) --Use Final sweep date instead of initial_sweep_date - Ticket # 25298
        FROM [$(HRPReporting)].dbo.lk_DCP_dates
        WHERE SUBSTRING(PayMonth, 1, 4) = @Payment_Year_NewDeleteHCC
              AND Mid_Year_Update IS NULL
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('007', 0, 1) WITH NOWAIT;
    END;


    SELECT @MaxESRDPY = MAX(PayMo)
    FROM [$(HRPReporting)].dbo.lk_Ratebook_ESRD;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('008', 0, 1) WITH NOWAIT;
    END;

    -- Get Rollup data from ReportDB
    DECLARE @Clnt_Rpt_DB VARCHAR(128),
            @Clnt_Rpt_Srv VARCHAR(128),
            @ClientID INT,
            @Rollup_PlanID_dyn SMALLINT,
            @Rollup_PlanID SMALLINT,
            @RollupSQL VARCHAR(MAX),
            @Coding_Intensity DECIMAL(18, 4),
            @Norm_Factor DECIMAL(18, 4),
            @PlanID VARCHAR(5),
            @RollupSQL_N NVARCHAR(MAX);

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('008.1', 0, 1) WITH NOWAIT;
    END;

    SET @SERVERNAME = ISNULL(@SERVERNAME, @@SERVERNAME); /*MC 2015-05-06 TFS 39388 */
    SET @Clnt_Rpt_Srv = ISNULL(@Clnt_Rpt_Srv, @SERVERNAME);

    SET @ClientID =
    (
        SELECT [cl].[Client_ID]
        FROM [$(HRPReporting)].[dbo].[tbl_Clients] [cl]
        WHERE [Report_DB_Server] = @Clnt_Rpt_Srv
              AND [cl].[Report_DB] = DB_NAME()
    );

    SET @clientlvldb =
    (
        SELECT DISTINCT
               cl.Client_DB
        FROM [$(HRPReporting)].[dbo].[tbl_Clients] [cl]
        WHERE [Report_DB_Server] = @Clnt_Rpt_Srv
              AND [Client_ID] = @ClientID
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

    IF @SERVERNAME IS NOT NULL
       OR @clientlvldb IS NOT NULL
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('009.1', 0, 1) WITH NOWAIT;
        END;

        DECLARE @GetRptSrvDb NVARCHAR(1024);
        DECLARE @GetRptSrvDbParm NVARCHAR(1024);



        SET @Clnt_Rpt_Srv = @SERVERNAME;

        SET @Clnt_Rpt_DB =
        (
            SELECT [cl].[Report_DB]
            FROM [$(HRPReporting)].[dbo].[tbl_Clients] [cl]
            WHERE [Report_DB_Server] = @Clnt_Rpt_Srv
                  AND [Client_ID] = @ClientID
        );


        IF @Debug = 1
        BEGIN
            PRINT '--======================--';
            PRINT '@GetRptSrvDbParm: ' + ISNULL(@GetRptSrvDbParm, 'NULL');
            PRINT '--======================--';
            PRINT ISNULL(@GetRptSrvDb, 'NULL');
            PRINT '--======================--';
        END;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('009.2', 0, 1) WITH NOWAIT;
        END;

        --EXEC sp_executesql @GetRptSrvDb ,
        --                   @GetRptSrvDbParm ,
        --                   @Clnt_Rpt_DBOut = @Clnt_Rpt_DB OUTPUT ,
        --                   @Clnt_Rpt_SrvOut = @Clnt_Rpt_Srv OUTPUT

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('010', 0, 1) WITH NOWAIT;
        END;

    END;

    ELSE
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('011', 0, 1) WITH NOWAIT;
        END;

        SET @Clnt_Rpt_Srv = @SERVERNAME;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('012', 0, 1) WITH NOWAIT;
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

    IF (OBJECT_ID('tempdb.dbo.#PlanIdentifier') IS NOT NULL)
    BEGIN
        DROP TABLE #PlanIdentifier;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('013.1', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #PlanIdentifier
    (
        [PlanIdentifier] SMALLINT NOT NULL,
        [PlanID] VARCHAR(5) NOT NULL
    );
    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('014', 0, 1) WITH NOWAIT;
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
    /* INsert active Plan IDs into #PlanIdentifier table */


    INSERT INTO #PlanIdentifier
    (
        PlanIdentifier,
        PlanID
    )
    SELECT PlanIdentifier,
           PlanID
    FROM [$(HRPInternalReportsDB)].dbo.RollupPlan
    WHERE Active = 1
          AND ClientIdentifier = @ClientID;


    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_Srv: ' + ISNULL(@Clnt_Rpt_Srv, 'NULL');
        PRINT '--======================--';
    --PRINT '@RollupSQL_N: ' + ISNULL(@RollupSQL_N, 'NULL');
    --PRINT '--======================--';
    --PRINT ISNULL(@open_qry_sql, 'NULL');
    --PRINT '--======================--';
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('016', 0, 1) WITH NOWAIT;
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('017', 0, 1) WITH NOWAIT;
    END;




    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@clientlvldb: ' + ISNULL(@clientlvldb, 'NULL');
        PRINT '--======================--';

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('017.1', 0, 1) WITH NOWAIT;
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('017.2', 0, 1) WITH NOWAIT;
    END;





    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('018', 0, 1) WITH NOWAIT;
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


    DECLARE @GetPlanId NVARCHAR(1024);
    DECLARE @GetPlanIdParm NVARCHAR(1024);
    SET @GetPlanIdParm = N'@PlanIdOUT VARCHAR(50) OUTPUT';

    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@clientlvldb: ' + ISNULL(@clientlvldb, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@GetPlanId, 'NULL');
        PRINT '--======================--';
    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('020', 0, 1) WITH NOWAIT;
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('021', 0, 1) WITH NOWAIT;
    END;




    /*changed by Jason Bohanon to use an OPENQUERY instead of linked server joins*/
    SELECT @RollupSQL = REPLACE(@RollupSQL, '''', '''''');


    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_DB: ' + ISNULL(@Clnt_Rpt_DB, 'NULL');
        PRINT '--======================--';
        PRINT '@Rollup_PlanID: ' + ISNULL(CAST(@Rollup_PlanID AS VARCHAR(50)), 'NULL');
        PRINT '@Payment_Year_NewDeleteHCC: ' + ISNULL(@Payment_Year_NewDeleteHCC, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@RollupSQL, 'NULL');
        PRINT '--======================--';
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('022', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#New_HCC_Rollup', 'U') IS NOT NULL
        DROP TABLE #New_HCC_Rollup;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('022.1', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #New_HCC_Rollup
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [PlanId] INT NULL,
        [HICN] VARCHAR(12) NULL,
        [PaymentYear] INT NULL,
        [PaymStart] DATETIME,
        [Model_Year] INT,
        [Factor_category] VARCHAR(20),
        [Factor_Desc] VARCHAR(50),
        [Factor_Desc_ORIG] VARCHAR(50),
        [HCC] VARCHAR(50),
        [Factor] DECIMAL(20, 4),
        [RAFT] VARCHAR(3),
        [RAFT_ORIG] VARCHAR(3),
        [HCC_Number] INT,
        [Min_ProcessBy] DATETIME,
        [Min_ThruDate] DATETIME,
        [Min_ProcessBy_SeqNum] INT,
        [Min_ThruDate_SeqNum] INT,
        [Min_Processby_DiagCD] VARCHAR(50),
        [Min_ThruDate_DiagCD] VARCHAR(50),
        [Min_Processby_PCN] VARCHAR(50),
        [Min_ThruDate_PCN] VARCHAR(50),
        [Processed_Priority_Thru_Date] DATETIME,
        [Thru_Priority_Processed_By] DATETIME,
        [Processed_Priority_FileID] [VARCHAR](18),
        [Processed_Priority_RAPS_Source_ID] INT,
        [Processed_Priority_Provider_ID] VARCHAR(40),
        [Processed_Priority_RAC] [VARCHAR](1),
        [Thru_Priority_FileID] [VARCHAR](18),
        [Thru_Priority_RAPS_Source_ID] [INT],
        [Thru_Priority_Provider_ID] [VARCHAR](40),
        [Thru_Priority_RAC] [VARCHAR](2),
        [Unionqueryind] INT,
        [Factor_Desc_Type] VARCHAR(50),
        [AGED] INT -- TFS 59836
    );



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('023', 0, 1) WITH NOWAIT;
    END;



    /* Insert into #New_HCC_Rollup table*/

    INSERT INTO #New_HCC_Rollup
    (
        [PlanId],
        [HICN],
        [PaymentYear],
        [PaymStart],
        [Model_Year],
        [Factor_category],
        [Factor_Desc],
        [Factor_Desc_ORIG],
        [HCC],
        [Factor],
        [RAFT],
        [HCC_Number],
        [Min_ProcessBy],
        [Min_ThruDate],
        [Min_ProcessBy_SeqNum],
        [Min_ThruDate_SeqNum],
        [Min_Processby_DiagCD],
        [Min_ThruDate_DiagCD],
        [Min_Processby_PCN],
        [Min_ThruDate_PCN],
        [Processed_Priority_Thru_Date],
        [Thru_Priority_Processed_By],
        [RAFT_ORIG],
        [Processed_Priority_FileID],
        [Processed_Priority_RAPS_Source_ID],
        [Processed_Priority_Provider_ID],
        [Processed_Priority_RAC],
        [Thru_Priority_FileID],
        [Thru_Priority_RAPS_Source_ID],
        [Thru_Priority_Provider_ID],
        [Thru_Priority_RAC],
        [Unionqueryind], --[IMFFlag]
        [Factor_Desc_Type],
        [AGED]
    )
    SELECT [r].[PlanID],
           [r].[HICN],
           [r].[PaymentYear],
           [r].[PaymStart],
           [r].[ModelYear],
           [r].[Factor_category],
           [r].[Factor_Desc],
           [r].[Factor_Desc_ORIG],
           [HCC] = LEFT([r].[Factor_Desc_ORIG], 3),
           [r].[Factor],
           [r].[RAFT],
           [r].[HCC_Number],
           [r].[Min_ProcessBy],
           [r].[Min_ThruDate],
           [r].[Min_ProcessBy_SeqNum],
           [r].[Min_ThruDate_SeqNum],
           [r].[Min_Processby_DiagCD],
           [r].[Min_ThruDate_DiagCD],
           [r].[Min_Processby_PCN],
           [r].[Min_ThruDate_PCN],
           [r].[Processed_Priority_Thru_Date],
           [r].[Thru_Priority_Processed_By],
           [r].[RAFT_ORIG],
           [r].[Processed_Priority_FileID],
           [r].[Processed_Priority_RAPS_Source_ID],
           [r].[Processed_Priority_Provider_ID],
           [r].[Processed_Priority_RAC],
           [r].[Thru_Priority_FileID],
           [r].[Thru_Priority_RAPS_Source_ID],
           [r].[Thru_Priority_Provider_ID],
           [r].[Thru_Priority_RAC],
           [Unionqueryind] = [r].[IMFFlag],
           [Factor_Desc_Type] = CASE
                                    WHEN [r].[Factor_Desc] LIKE 'HCC%' THEN
                                        'HCC'
                                    WHEN [r].[Factor_Desc] LIKE 'M-High%' THEN
                                        'M-High'
                                    WHEN [r].[Factor_Desc] LIKE 'INCR%' THEN
                                        'INCR'
                                    WHEN [r].[Factor_Desc] LIKE 'INT%' THEN
                                        'INT'
                                    WHEN [r].[Factor_Desc] LIKE 'D-HCC%' THEN
                                        'D-HCC'
                                    ELSE
                                        NULL
                                END,
           [r].[AGED]
    FROM [rev].[tbl_Summary_RskAdj_RAPS_MOR_Combined] [r]
        INNER JOIN [#PlanIdentifier] [p]
            ON p.PlanIdentifier = [r].[PlanID]
               AND [r].[PaymentYear] = @Payment_Year_NewDeleteHCC
               AND ([r].[Factor_Desc] NOT LIKE 'DEL%')
               AND [r].[Factor] > 0;


    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_Srv: ' + ISNULL(@Clnt_Rpt_Srv, 'NULL');
        PRINT '--======================--';
        PRINT '--======================--';
        PRINT ISNULL(@open_qry_sql, 'NULL');
        PRINT '--======================--';
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('024', 0, 1) WITH NOWAIT;
    END;

    EXEC sys.sp_executesql @open_qry_sql;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('025', 0, 1) WITH NOWAIT;
    END;


    ALTER TABLE #New_HCC_Rollup REBUILD  ;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('026', 0, 1) WITH NOWAIT;
    END;

    --if not exists(select top 1 1 from #New_HCC_Rollup)
    -- Select 'No New HCC Present'

    CREATE NONCLUSTERED INDEX IX_#New_HCC_Rollup__HICN
    ON #New_HCC_Rollup ([HICN])
    INCLUDE (
                PlanId,
                PaymentYear,
                PaymStart,
                Model_Year,
                Factor_category,
                Factor_Desc,
                HCC,
                Factor,
                RAFT,
                RAFT_ORIG,
                HCC_Number,
                Min_ProcessBy,
                Min_ThruDate,
                Min_ProcessBy_SeqNum,
                Min_ThruDate_SeqNum,
                -- Ticket # 25658 Start
                Min_Processby_DiagCD,
                Min_ThruDate_DiagCD,
                Min_Processby_PCN,
                Min_ThruDate_PCN,
                Processed_Priority_Thru_Date,
                Thru_Priority_Processed_By,
                -- Ticket # 25658 Start
                Processed_Priority_FileID,
                Processed_Priority_RAPS_Source_ID,
                Processed_Priority_Provider_ID,
                Processed_Priority_RAC,
                Thru_Priority_FileID,
                Thru_Priority_RAPS_Source_ID,
                Thru_Priority_Provider_ID,
                Thru_Priority_RAC,
                Unionqueryind,
                AGED
            ); -- Performance Tuning (Added Columns in Include)


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('027', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('[etl].[IntermediateNewHCCOutput]', 'U') IS NOT NULL
        TRUNCATE TABLE etl.IntermediateNewHCCOutput;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('029', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('[TEMPDB].[DBO].[#Tbl_AltHICN]', 'U') IS NOT NULL
        DROP TABLE dbo.#Tbl_AltHICN;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('030', 0, 1) WITH NOWAIT;
    END;



    CREATE TABLE #Tbl_AltHICN
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [HICN] VARCHAR(12),
        [FINALHICN] VARCHAR(12)
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('031', 0, 1) WITH NOWAIT;
    END;



    /*Insert into #Tbl_AltHICN  */

    INSERT INTO [#Tbl_AltHICN]
    (
        [HICN],
        [FINALHICN]
    )
    SELECT [HICN],
           [FINALHICN]
    FROM [rev].[tbl_Summary_RskAdj_AltHICN] [ALTHCN]
        INNER JOIN [#PlanIdentifier] [p]
            ON [ALTHCN].[PlanID] = p.PlanIdentifier;







    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('033', 0, 1) WITH NOWAIT;
    END;

    CREATE INDEX IX_#Tbl_AltHICN_HICN ON #Tbl_AltHICN (HICN);

    IF (OBJECT_ID('tempdb.dbo.#List01') IS NOT NULL)
    BEGIN
        DROP TABLE #List01;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('034', 0, 1) WITH NOWAIT;
    END;


    CREATE TABLE #List01
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [ModelYear] INT,
        [Factor_Description] VARCHAR(50)
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('035', 0, 1) WITH NOWAIT;
    END;


    IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
    BEGIN

        INSERT INTO #List01
        (
            [ModelYear],
            [Factor_Description]
        )
        SELECT DISTINCT
               [m].[ModelYear],
               [d].[Factor_Description]
        FROM [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] m
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] d
                ON [m].[ModelYear] = [d].[Payment_Year]
                   AND m.RAFactorType = [d].[Factor_Type]
        WHERE [m].[PaymentYear] = @Payment_Year_NewDeleteHCC
              AND [d].[Factor_Type] IN ( 'C', 'CF', 'CP', 'CN' ); --TFS59836

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('036', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO etl.IntermediateNewHCCOutput
        (
            [PaymentYear],
            [PaymStart],
            [ModelYear],
            [ProcessedByStart],
            [ProcessedByEnd],
            [PlanID],
            [HICN],
            [RAFactorType],
            [RAFactorTypeORIG],
            [ProcessedPriorityProcessedBy],
            [ProcessedPriorityThruDate],
            [ProcessedPriorityPCN],
            [ProcessedPriorityDiag],
            [ProcessedPriorityFileID],
            [ProcessedPriorityRAPSSourceID],
            [ProcessedPriorityRAC],
            [ThruPriorityProcessedBy],
            [ThruPriorityThruDate],
            [ThruPriorityPCN],
            [ThruPriorityDiag],
            [ThruPriorityFileID],
            [ThruPriorityRAPSSourceID],
            [ThruPriorityRAC],
            [HCC],
            [HCCOrig],
            [OnlyHCC],
            [HCCNumber],
            [Factor],
            [MemberMonths],
            [ProviderID],
            [MinProcessBySeqnum],
            [Unionqueryind],
            [PaymStartYear],
            [AGED]
        )
        SELECT DISTINCT
               [PaymentYear] = n.PaymentYear,
               [PaymStart] = n.PaymStart,
               [ModelYear] = m.ModelYear,
               [ProcessedByStart] = @PROCESSBY_START,
               [ProcessedByEnd] = @PROCESSBY_END,
               [PlanID] = n.PlanId,
               [HICN] = n.HICN,
               [RAFactorType] = n.RAFT,
               [RAFactorTypeORIG] = n.RAFT_ORIG,
               [ProcessedPriorityProcessedBy] = n.Min_ProcessBy,

               -- Ticket # 25658 Start
               [ProcessedPriorityThruDate] = n.Processed_Priority_Thru_Date,
               [ProcessedPriorityPCN] = n.Min_Processby_PCN,
               [ProcessedPriorityDiag] = n.Min_Processby_DiagCD,
               [ProcessedPriorityFileID] = n.Processed_Priority_FileID,
               [ProcessedPriorityRAPSSourceID] =
               (
                   SELECT [r].[Category]
                   FROM [$(HRPReporting)].dbo.[lk_RAPS_Sources] r
                   WHERE n.Processed_Priority_RAPS_Source_ID = [r].[Source_ID]
               ),
               [ProcessedPriorityRAC] = n.Processed_Priority_RAC,
               [ThruPriorityProcessedBy] = n.Thru_Priority_Processed_By,
               [ThruPriorityThruDate] = n.Min_ThruDate,
               [ThruPriorityPCN] = n.Min_ThruDate_PCN,
               [ThruPriorityDiag] = n.Min_ThruDate_DiagCD,

               -- Ticket # 25658 Start
               [ThruPriorityFileID] = n.Thru_Priority_FileID,
               [ThruPriorityRAPSSourceID] =
               (
                   SELECT TOP 1
                          [r].[Category]
                   FROM [$(HRPReporting)].[dbo].[lk_RAPS_Sources] r
                   WHERE n.Thru_Priority_RAPS_Source_ID = [r].[Source_ID]
                   ORDER BY [r].[Category]
               ),
               [ThruPriorityRAC] = n.Thru_Priority_RAC,
               [HCC] = n.Factor_Desc,
               [HCCOrig] = n.Factor_Desc_ORIG,
               [OnlyHCC] = n.HCC,
               [HCCNumber] = n.HCC_Number,
               [Factor] = n.Factor,
               [MemberMonths] = 1,
               [ProviderID] = ISNULL(n.Processed_Priority_Provider_ID, n.Thru_Priority_Provider_ID),
               [MinProcessBySeqnum] = n.Min_ProcessBy_SeqNum,
               [Unionqueryind] = n.Unionqueryind,
               [PaymStartYear] = YEAR(n.PaymStart),
               [AGED] = n.AGED
        FROM #New_HCC_Rollup n
            LEFT JOIN [#List01] m
                ON n.Model_Year = m.ModelYear
                   AND n.Factor_Desc_ORIG = m.Factor_Description
        WHERE n.Factor_Desc_Type IN ( 'HCC', 'M-High', 'INCR', 'INT', 'D-HCC' )
              AND n.RAFT IN ( 'C', 'I', 'CF', 'CP', 'CN' ); -- Ticket # 25426 TFS 59836


    END;
    ELSE
    BEGIN
        INSERT INTO #List01
        (
            [ModelYear],
            [Factor_Description]
        )
        SELECT DISTINCT
               [m].[ModelYear],
               [d].[Factor_Description]
        FROM [$(HRPReporting)].[dbo].[lk_Risk_Score_Factors_PartC] m
            JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models] d
                ON [m].[ModelYear] = [d].[Payment_Year]
                   AND m.RAFactorType = [d].[Factor_Type]
        WHERE [m].[PaymentYear] = @Payment_Year_NewDeleteHCC
              AND [d].[Factor_Type] IN ( 'C' ); --TFS59836

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('036.1', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO etl.IntermediateNewHCCOutput
        (
            [PaymentYear],
            [PaymStart],
            [ModelYear],
            [ProcessedByStart],
            [ProcessedByEnd],
            [PlanID],
            [HICN],
            [RAFactorType],
            [RAFactorTypeORIG],
            [ProcessedPriorityProcessedBy],
            [ProcessedPriorityThruDate],
            [ProcessedPriorityPCN],
            [ProcessedPriorityDiag],
            [ProcessedPriorityFileID],
            [ProcessedPriorityRAPSSourceID],
            [ProcessedPriorityRAC],
            [ThruPriorityProcessedBy],
            [ThruPriorityThruDate],
            [ThruPriorityPCN],
            [ThruPriorityDiag],
            [ThruPriorityFileID],
            [ThruPriorityRAPSSourceID],
            [ThruPriorityRAC],
            [HCC],
            [HCCOrig],
            [OnlyHCC],
            [HCCNumber],
            [Factor],
            [MemberMonths],
            [ProviderID],
            [MinProcessBySeqnum],
            [Unionqueryind],
            [PaymStartYear],
            [AGED]
        )
        SELECT DISTINCT
               [PaymentYear] = n.PaymentYear,
               [PaymStart] = n.PaymStart,
               [ModelYear] = m.ModelYear,
               [ProcessedByStart] = @PROCESSBY_START,
               [ProcessedByEnd] = @PROCESSBY_END,
               [PlanID] = n.PlanId,
               [HICN] = n.HICN,
               [RAFactorType] = n.RAFT,
               [RAFactorTypeORIG] = n.RAFT_ORIG,
               [ProcessedPriorityProcessedBy] = n.Min_ProcessBy,

               -- Ticket # 25658 Start
               [ProcessedPriorityThruDate] = n.Processed_Priority_Thru_Date,
               [ProcessedPriorityPCN] = n.Min_Processby_PCN,
               [ProcessedPriorityDiag] = n.Min_Processby_DiagCD,
               [ProcessedPriorityFileID] = n.Processed_Priority_FileID,
               [ProcessedPriorityRAPSSourceID] =
               (
                   SELECT [r].[Category]
                   FROM [$(HRPReporting)].dbo.[lk_RAPS_Sources] r
                   WHERE n.Processed_Priority_RAPS_Source_ID = [r].[Source_ID]
               ),
               [ProcessedPriorityRAC] = n.Processed_Priority_RAC,
               [ThruPriorityProcessedBy] = n.Thru_Priority_Processed_By,
               [ThruPriorityThruDate] = n.Min_ThruDate,
               [ThruPriorityPCN] = n.Min_ThruDate_PCN,
               [ThruPriorityDiag] = n.Min_ThruDate_DiagCD,

               -- Ticket # 25658 Start
               [ThruPriorityFileID] = n.Thru_Priority_FileID,
               [ThruPriorityRAPSSourceID] =
               (
                   SELECT [r].[Category]
                   FROM [$(HRPReporting)].[dbo].[lk_RAPS_Sources] r
                   WHERE n.Thru_Priority_RAPS_Source_ID = [r].[Source_ID]
               ),
               [ThruPriorityRAC] = n.Thru_Priority_RAC,
               [HCC] = n.Factor_Desc,
               [HCCOrig] = n.Factor_Desc_ORIG,
               [OnlyHCC] = n.HCC,
               [HCCNumber] = n.HCC_Number,
               [Factor] = n.Factor,
               [MemberMonths] = 1,
               [ProviderID] = ISNULL(n.Processed_Priority_Provider_ID, n.Thru_Priority_Provider_ID),
               [MinProcessBySeqnum] = n.Min_ProcessBy_SeqNum,
               [Unionqueryind] = n.Unionqueryind,
               [PaymStartYear] = YEAR(n.PaymStart),
               [AGED] = n.AGED
        FROM #New_HCC_Rollup n
            LEFT JOIN [#List01] m
                ON n.Model_Year = m.ModelYear
                   AND n.Factor_Desc_ORIG = m.Factor_Description
        WHERE n.Factor_Desc_Type IN ( 'HCC', 'M-High', 'INCR', 'INT', 'D-HCC' )
              AND n.RAFT IN ( 'C', 'I' ); -- Ticket # 25426

    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('037', 0, 1) WITH NOWAIT;
    END;


    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#List01') IS NOT NULL)
        BEGIN
            DROP TABLE #List01;
        END;
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('038', 0, 1) WITH NOWAIT;
    END;


    IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
    BEGIN
        INSERT INTO etl.IntermediateNewHCCOutput
        (
            [PaymentYear],
            [PaymStart],
            [ModelYear],
            [ProcessedByStart],
            [ProcessedByEnd],
            [PlanID],
            [HICN],
            [RAFactorType],
            [RAFactorTypeORIG],
            [ProcessedPriorityProcessedBy],
            [ProcessedPriorityThruDate],
            [ProcessedPriorityPCN],
            [ProcessedPriorityDiag],
            [ProcessedPriorityFileID],
            [ProcessedPriorityRAPSSourceID],
            [ProcessedPriorityRAC],
            [ThruPriorityProcessedBy],
            [ThruPriorityThruDate],
            [ThruPriorityPCN],
            [ThruPriorityDiag],
            [ThruPriorityFileID],
            [ThruPriorityRAPSSourceID],
            [ThruPriorityRAC],
            [HCC],
            [HCCOrig],
            [OnlyHCC],
            [HCCNumber],
            [Factor],
            [MemberMonths],
            [ProviderID],
            [MinProcessBySeqnum],
            [Unionqueryind],
            [PaymStartYear],
            [AGED]
        )
        SELECT [PaymentYear] = n.PaymentYear,
               [PaymStart] = n.PaymStart,
               [ModelYear] = n.PaymentYear,
               [ProcessedByStart] = @PROCESSBY_START,
               [ProcessedByEnd] = @PROCESSBY_END,
               [PlanID] = n.PlanId,
               [HICN] = n.HICN,
               [RAFactorType] = n.RAFT,
               [RAFactorTypeORIG] = n.RAFT_ORIG,
               [ProcessedPriorityProcessedBy] = n.Min_ProcessBy,

               -- Ticket # 25658 Start
               [ProcessedPriorityThruDate] = n.Processed_Priority_Thru_Date,
               [ProcessedPriorityPCN] = n.Min_Processby_PCN,
               [ProcessedPriorityDiag] = n.Min_Processby_DiagCD,
               [ProcessedPriorityFileID] = n.Processed_Priority_FileID,
               [ProcessedPriorityRAPSSourceID] =
               (
                   SELECT Category
                   FROM [$(HRPReporting)].dbo.lk_RAPS_Sources r
                   WHERE n.Processed_Priority_RAPS_Source_ID = r.Source_ID
               ),
               [ProcessedPriorityRAC] = n.Processed_Priority_RAC,
               [ThruPriorityProcessedBy] = n.Thru_Priority_Processed_By,
               [ThruPriorityThruDate] = n.Min_ThruDate,
               [ThruPriorityPCN] = n.Min_ThruDate_PCN,
               [ThruPriorityDiag] = n.Min_ThruDate_DiagCD,

               -- Ticket # 25658 Start
               [ThruPriorityFileID] = n.Thru_Priority_FileID,
               [ThruPriorityRAPSSourceID] =
               (
                   SELECT Category
                   FROM [$(HRPReporting)].dbo.lk_RAPS_Sources r
                   WHERE n.Thru_Priority_RAPS_Source_ID = r.Source_ID
               ),
               [ThruPriorityRAC] = n.Thru_Priority_RAC,
               [HCC] = n.Factor_Desc,
               [HCCOrig] = n.Factor_Desc_ORIG,
               [OnlyHCC] = n.HCC,
               [HCCNumber] = n.HCC_Number,
               [Factor] = n.Factor,
               [MemberMonths] = 1,
               [ProviderID] = ISNULL(n.Processed_Priority_Provider_ID, n.Thru_Priority_Provider_ID),
               [MinProcessBySeqnum] = n.Min_ProcessBy_SeqNum,
               [Unionqueryind] = n.Unionqueryind,
               [PaymStartYear] = YEAR(n.PaymStart),
               [AGED] = n.AGED
        FROM #New_HCC_Rollup n
        WHERE n.Factor_Desc_Type IN ( 'HCC', 'M-High', 'INCR', 'INT', 'D-HCC' )
              AND n.RAFT NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ); -- Ticket # 25426   TFS 59836





    END;
    ELSE
    BEGIN
        INSERT INTO etl.IntermediateNewHCCOutput
        (
            [PaymentYear],
            [PaymStart],
            [ModelYear],
            [ProcessedByStart],
            [ProcessedByEnd],
            [PlanID],
            [HICN],
            [RAFactorType],
            [RAFactorTypeORIG],
            [ProcessedPriorityProcessedBy],
            [ProcessedPriorityThruDate],
            [ProcessedPriorityPCN],
            [ProcessedPriorityDiag],
            [ProcessedPriorityFileID],
            [ProcessedPriorityRAPSSourceID],
            [ProcessedPriorityRAC],
            [ThruPriorityProcessedBy],
            [ThruPriorityThruDate],
            [ThruPriorityPCN],
            [ThruPriorityDiag],
            [ThruPriorityFileID],
            [ThruPriorityRAPSSourceID],
            [ThruPriorityRAC],
            [HCC],
            [HCCOrig],
            [OnlyHCC],
            [HCCNumber],
            [Factor],
            [MemberMonths],
            [ProviderID],
            [MinProcessBySeqnum],
            [Unionqueryind],
            [PaymStartYear],
            [AGED]
        )
        SELECT [PaymentYear] = n.PaymentYear,
               [PaymStart] = n.PaymStart,
               [ModelYear] = n.PaymentYear,
               [ProcessedByStart] = @PROCESSBY_START,
               [ProcessedByEnd] = @PROCESSBY_END,
               [PlanID] = n.PlanId,
               [HICN] = n.HICN,
               [RAFactorType] = n.RAFT,
               [RAFactorTypeORIG] = n.RAFT_ORIG,
               [ProcessedPriorityProcessedBy] = n.Min_ProcessBy,

               -- Ticket # 25658 Start
               [ProcessedPriorityThruDate] = n.Processed_Priority_Thru_Date,
               [ProcessedPriorityPCN] = n.Min_Processby_PCN,
               [ProcessedPriorityDiag] = n.Min_Processby_DiagCD,
               [ProcessedPriorityFileID] = n.Processed_Priority_FileID,
               [ProcessedPriorityRAPSSourceID] =
               (
                   SELECT Category
                   FROM [$(HRPReporting)].dbo.lk_RAPS_Sources r
                   WHERE n.Processed_Priority_RAPS_Source_ID = r.Source_ID
               ),
               [ProcessedPriorityRAC] = n.Processed_Priority_RAC,
               [ThruPriorityProcessedBy] = n.Thru_Priority_Processed_By,
               [ThruPriorityThruDate] = n.Min_ThruDate,
               [ThruPriorityPCN] = n.Min_ThruDate_PCN,
               [ThruPriorityDiag] = n.Min_ThruDate_DiagCD,

               -- Ticket # 25658 Start
               [ThruPriorityFileID] = n.Thru_Priority_FileID,
               [ThruPriorityRAPSSourceID] =
               (
                   SELECT Category
                   FROM [$(HRPReporting)].dbo.lk_RAPS_Sources r
                   WHERE n.Thru_Priority_RAPS_Source_ID = r.Source_ID
               ),
               [ThruPriorityRAC] = n.Thru_Priority_RAC,
               [HCC] = n.Factor_Desc,
               [HCCOrig] = n.Factor_Desc_ORIG,
               [OnlyHCC] = n.HCC,
               [HCCNumber] = n.HCC_Number,
               [Factor] = n.Factor,
               [MemberMonths] = 1,
               [ProviderID] = ISNULL(n.Processed_Priority_Provider_ID, n.Thru_Priority_Provider_ID),
               [MinProcessBySeqnum] = n.Min_ProcessBy_SeqNum,
               [Unionqueryind] = n.Unionqueryind,
               [PaymStartYear] = YEAR(n.PaymStart),
               [AGED] = n.AGED
        FROM #New_HCC_Rollup n
        WHERE n.Factor_Desc_Type IN ( 'HCC', 'M-High', 'INCR', 'INT', 'D-HCC' )
              AND n.RAFT NOT IN ( 'C', 'I' ); -- Ticket # 25426   TFS 59836

    END;





    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('039', 0, 1) WITH NOWAIT;
    END;


    UPDATE n
    SET n.Factor = 0
    FROM etl.IntermediateNewHCCOutput n
    WHERE n.Factor IS NULL;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('040', 0, 1) WITH NOWAIT;
    END;

    -- Performance Tuning (Created Temp table and indexes) Start

    IF OBJECT_ID('TEMPDB..#tbl_Member_Months_RollUp', 'U') IS NOT NULL
        DROP TABLE #tbl_Member_Months_RollUp;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('041', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #tbl_Member_Months_RollUp
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [HICN] VARCHAR(12),
        [paymyear] VARCHAR(4),
        [months_in_dcp] INT
    );
    /* --commented out by Jason Bohanon to change to an OPENQUERY instead for performance and reliability
	 select @RollupSQL = 

     'select a.HICN , year(paymstart) paymyear, count(distinct paymstart) months_in_dcp 
 		from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB + '.dbo.tbl_member_months_rollup a
 		group by a.HICN, year(paymstart)
		 having (year(PaymStart) = ' + cast(cast(@Payment_Year_NewDeleteHCC as int) - 1 as varchar) + ' or year(PaymStart) = ' + @Payment_Year_NewDeleteHCC + ')
		 and a.HICN  is not null'
		 
		 insert into #tbl_Member_Months_RollUp 
		 exec (@RollupSQL)
		 
		 */
    -- Ticket # 33186	

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('042', 0, 1) WITH NOWAIT;
    END;

    SELECT @RollupSQL
        = 'select a.HICN , year(paymstart) paymyear, count(distinct paymstart) months_in_dcp 
 		from  ' + @Clnt_Rpt_DB
          + '.dbo.tbl_member_months_rollup a
 		group by a.HICN, year(paymstart)
		 having (year(PaymStart) = ' + CAST(CAST(@Payment_Year_NewDeleteHCC AS INT) - 1 AS VARCHAR)
          + ' or year(PaymStart) = ' + @Payment_Year_NewDeleteHCC + ')
		 and a.HICN  is not null';

    SELECT @RollupSQL = REPLACE(@RollupSQL, '''', '''''');

    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_DB: ' + ISNULL(@Clnt_Rpt_DB, 'NULL');
        PRINT '@Payment_Year_NewDeleteHCC: ' + ISNULL(@Payment_Year_NewDeleteHCC, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@RollupSQL, 'NULL');
        PRINT '--======================--';
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



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('044', 0, 1) WITH NOWAIT;
    END;

    SELECT @open_qry_sql
        = N'insert into #tbl_Member_Months_RollUp (HICN, paymyear, months_in_dcp)
SELECT HICN, paymyear, months_in_dcp
FROM OPENQUERY([' + @Clnt_Rpt_Srv + N'], ' + N'''' + @RollupSQL + N'''' + N') ;';


    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_Srv: ' + ISNULL(@Clnt_Rpt_Srv, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@open_qry_sql, 'NULL');
        PRINT '--======================--';
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('045', 0, 1) WITH NOWAIT;
    END;

    EXEC sys.sp_executesql @open_qry_sql;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('046', 0, 1) WITH NOWAIT;
    END;



    CREATE NONCLUSTERED INDEX idx_tbl_member_months_rollup_HICN
    ON #tbl_Member_Months_RollUp (HICN)
    INCLUDE (
                paymyear,
                months_in_dcp
            );


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('047', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#Tbl_MemberMonthRollup_AltHICN', 'U') IS NOT NULL
        DROP TABLE #Tbl_MemberMonthRollup_AltHICN;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('048', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #Tbl_MemberMonthRollup_AltHICN
    (
        HICN VARCHAR(12),
        paymyear VARCHAR(4),
        months_in_dcp INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('049', 0, 1) WITH NOWAIT;
    END;

    --set @start = getdate() 
    INSERT INTO #Tbl_MemberMonthRollup_AltHICN
    SELECT ISNULL(althcn.FINALHICN, a.HICN) hicn,
           a.paymyear,
           a.months_in_dcp
    FROM #tbl_Member_Months_RollUp a
        LEFT OUTER JOIN #Tbl_AltHICN althcn
            ON a.HICN = althcn.HICN
    WHERE a.HICN IS NOT NULL;
    --WHERE (year(PaymStart) = ' + cast(cast(@Payment_Year_NewDeleteHCC as int) - 1 as varchar) + ' or year(PaymStart) = ' + @Payment_Year_NewDeleteHCC + ')

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('050', 0, 1) WITH NOWAIT;
    END;


    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#Tbl_AltHICN') IS NOT NULL)
        BEGIN
            DROP TABLE #Tbl_AltHICN;
        END;

        IF (OBJECT_ID('tempdb.dbo.#tbl_Member_Months_RollUp') IS NOT NULL)
        BEGIN
            DROP TABLE #tbl_Member_Months_RollUp;
        END;
    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('051', 0, 1) WITH NOWAIT;
    END;

    CREATE CLUSTERED INDEX ix_Tbl_MemberMonthRollup_AltHICN_HICN
    ON #Tbl_MemberMonthRollup_AltHICN (
                                          HICN,
                                          paymyear
                                      );


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('052', 0, 1) WITH NOWAIT;
    END;

    SET @RollupSQL_N
        = N'select @MaxBidPY = MAX(Bid_Year) from ' + @Clnt_Rpt_Srv + N'.' + @Clnt_Rpt_DB + N'.dbo.tbl_BIDS_rollup';


    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_Srv: ' + ISNULL(@Clnt_Rpt_Srv, 'NULL');
        PRINT '@Clnt_Rpt_DB: ' + ISNULL(@Clnt_Rpt_DB, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@RollupSQL_N, 'NULL');
        PRINT '--======================--';
    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('053', 0, 1) WITH NOWAIT;
    END;

    EXEC sys.sp_executesql @RollupSQL_N,
                           N'@MaxBidPY varchar(5) OUTPUT',
                           @MaxBidPY OUTPUT;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('054', 0, 1) WITH NOWAIT;
    END;


    IF (OBJECT_ID('tempdb.dbo.#Bids_Rollup') IS NOT NULL)
    BEGIN
        DROP TABLE #Bids_Rollup;
    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('054.1', 0, 1) WITH NOWAIT;
    END;

    -- Ticket # 33186	

    /*	select @RollupSQL = 

	'update n
	set n.months_in_dcp = mm.months_in_dcp,
		n.active_indicator_for_rollforward = (case when isnull(convert(varchar(12),m.max_paymstart,101),''N'') = ''N'' then ''N'' else ''Y'' end),
		n.esrd = (case when n.ra_factor_type in (select distinct ra_type from [$(HRPReporting)].dbo.lk_ra_factor_types where description like ''%dialysis%'' or description like ''%graft%'') then ''Y'' else ''N'' end),
		n.hosp = isnull(mmr.hosp,''N''),
		n.pbp = mmr.pbp,
		n.scc = mmr.scc,
		n.bid = isnull(b.ma_bid, b2.ma_bid)
	from #New_HCC_Output n
	inner join ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB + '.rev.tbl_Summary_RskAdj_MMR mmr on n.hicn = mmr.hicn and n.paymstart = mmr.paymstart and n.payment_year = mmr.payment_year  -- Ticket # 26951
	left outer join ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB + '.dbo.tbl_BIDS_rollup b on mmr.planid = b.planidentifier and mmr.pbp = b.pbp and mmr.scc = b.scc and b.bid_year = (case when year(getdate()) < ' + @Payment_Year_NewDeleteHCC + ' then ' + isnull(@MaxBidPY,0) + ' else ' + @Payment_Year_NewDeleteHCC + ' end)
	left outer join ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB + '.dbo.tbl_BIDS_rollup b2 on mmr.planid = b2.planidentifier and mmr.pbp = b2.pbp and b2.scc = ''OOA'' and b2.bid_year = (case when year(getdate()) < ' + @Payment_Year_NewDeleteHCC + ' then ' + isnull(@MaxBidPY,0) + ' else ' + @Payment_Year_NewDeleteHCC + ' end)
	left outer join 	
		(select payment_year , max(paymstart) max_paymstart
		from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB + '.rev.tbl_Summary_RskAdj_MMR 
		group by payment_year) m on n.payment_year = m.payment_year and n.paymstart = m.max_paymstart
	left outer join 
	#Tbl_MemberMonthRollup_AltHICN mm on n.hicn = mm.hicn and case when year(getdate()) < ' + @Payment_Year_NewDeleteHCC + ' then year(n.paymstart) else year(n.paymstart)-1 end = mm.paymyear  -- Ticket # 26951
	left outer join 
		(select hicn, year(paymstart) paymyear, max(paymstart) max_paymstart
		from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB + '.rev.tbl_Summary_RskAdj_MMR 
		group by hicn, year(paymstart)) mmm on n.hicn = mmm.hicn and year(n.paymstart) = mmm.paymyear and n.paymstart = mmm.max_paymstart'

	

	exec (@RollupSQL)
	
*/
    -- Ticket # 33186

    CREATE TABLE #Bids_Rollup
    (
        pbp VARCHAR(4) NULL,
        scc VARCHAR(5) NULL,
        ma_bid_1 SMALLMONEY NULL,
        ma_bid_2 SMALLMONEY NULL,
        HICN VARCHAR(12) NULL,
        paymstart DATETIME NULL,
        payment_year INT NULL,
        hosp CHAR(1) NULL
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('055', 0, 1) WITH NOWAIT;
    END;
    -- TFS 64782 
    SELECT @open_qry_sql
        = N'SELECT mmr.pbp
            , mmr.scc
            , b.ma_bid as ma_bid1
            , b2.ma_bid as ma_bid2
            , mmr.HICN
            , mmr.paymstart
            , mmr.[PaymentYear]
            , mmr.hosp 
            FROM ' + @Clnt_Rpt_DB + N'.rev.tbl_Summary_RskAdj_MMR mmr 
		  left outer join ' + @Clnt_Rpt_DB
          + N'.dbo.tbl_BIDS_rollup b 
			 on mmr.planid = b.planidentifier 
				    and mmr.pbp = b.pbp 
				    and mmr.scc = b.scc 
				    and b.bid_year = (case when year(getdate()) < ' + @Payment_Year_NewDeleteHCC + N' then '
          + ISNULL(@MaxBidPY, 0) + N' else ' + @Payment_Year_NewDeleteHCC + N' end)
		  left outer join ' + @Clnt_Rpt_DB
          + N'.dbo.tbl_BIDS_rollup b2 
				on mmr.planid = b2.planidentifier 
				and mmr.pbp = b2.pbp 
				and b2.scc = ''OOA'' 
				and b2.bid_year = (case when year(getdate()) < ' + @Payment_Year_NewDeleteHCC + N' then '
          + ISNULL(@MaxBidPY, 0) + N' else ' + @Payment_Year_NewDeleteHCC + N' end)
	;';

    SELECT @open_qry_sql = REPLACE(@open_qry_sql, '''', '''''');

    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_DB: ' + ISNULL(@Clnt_Rpt_DB, 'NULL');
        PRINT '@Payment_Year_NewDeleteHCC: ' + ISNULL(@Payment_Year_NewDeleteHCC, 'NULL');
        PRINT '@MaxBidPY: ' + ISNULL(@MaxBidPY, 0);
        PRINT '--======================--';
        PRINT ISNULL(@open_qry_sql, 'NULL');
        PRINT '--======================--';
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('056', 0, 1) WITH NOWAIT;
    END;




    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('057', 0, 1) WITH NOWAIT;
    END;


    SELECT @open_qry_sql
        = N'INSERT INTO #Bids_Rollup(pbp, scc, ma_bid_1, ma_bid_2, HICN, paymstart, payment_year, hosp) 
SELECT pbp,scc,ma_bid1, ma_bid2, HICN, paymstart, PaymentYear, hosp
FROM OPENQUERY([' + @Clnt_Rpt_Srv + N'], ' + N'''' + @open_qry_sql + N'''' + N') ;';

    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@Clnt_Rpt_Srv: ' + ISNULL(@Clnt_Rpt_Srv, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@open_qry_sql, 'NULL');
        PRINT '--======================--';
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('058', 0, 1) WITH NOWAIT;
    END;

    EXEC sys.sp_executesql @open_qry_sql;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#Bids_RollupHICNMaxPaymStart') IS NOT NULL)
    BEGIN
        DROP TABLE #Bids_RollupHICNMaxPaymStart;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.1', 0, 1) WITH NOWAIT;
    END;


    CREATE TABLE #Bids_RollupHICNMaxPaymStart
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [HICN] VARCHAR(15),
        [paymyear] INT,
        [max_paymstart] DATETIME
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.2', 0, 1) WITH NOWAIT;
    END;


    INSERT INTO [#Bids_RollupHICNMaxPaymStart]
    (
        [HICN],
        [paymyear],
        [max_paymstart]
    )
    SELECT [HICN],
           [paymyear] = YEAR([paymstart]),
           [max_paymstart] = MAX([paymstart])
    FROM #Bids_Rollup
    GROUP BY [HICN],
             YEAR([paymstart]);

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.3', 0, 1) WITH NOWAIT;
    END;

    CREATE NONCLUSTERED INDEX [IX_#Bids_RollupHICNMaxPaymStart__HICN__max_paymstart__paymyear]
    ON #Bids_RollupHICNMaxPaymStart (
                                        [HICN],
                                        [max_paymstart],
                                        [paymyear]
                                    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.4', 0, 1) WITH NOWAIT;
    END;

    IF (OBJECT_ID('tempdb.dbo.#Bids_RollupMaxPaymStart') IS NOT NULL)
    BEGIN
        DROP TABLE #Bids_RollupMaxPaymStart;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.5', 0, 1) WITH NOWAIT;
    END;


    CREATE TABLE #Bids_RollupMaxPaymStart
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [payment_year] INT,
        [max_paymstart] DATETIME
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.6', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #Bids_RollupMaxPaymStart
    (
        [payment_year],
        [max_paymstart]
    )
    SELECT [payment_year] = bb.payment_year,
           [max_paymstart] = MAX(bb.paymstart)
    FROM #Bids_Rollup bb
    GROUP BY bb.payment_year;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('059.7', 0, 1) WITH NOWAIT;
    END;




    UPDATE n
    SET n.MonthsInDCP = mm.months_in_dcp,
        n.ActiveIndicatorForRollforward = (CASE
                                               WHEN ISNULL(CONVERT(VARCHAR(12), m.max_paymstart, 101), 'N') = 'N' THEN
                                                   'N'
                                               ELSE
                                                   'Y'
                                           END
                                          ),
        n.ESRD = CASE
                     WHEN rft.[RA_Type] IS NOT NULL THEN
                         'Y'
                     ELSE
                         'N'
                 END,
        n.HOSP = ISNULL(b.hosp, 'N'),
        n.PBP = b.pbp,
        n.SCC = b.scc,
        n.BID = ISNULL(b.ma_bid_1, b.ma_bid_2)
    FROM etl.IntermediateNewHCCOutput n
        JOIN #Bids_Rollup b
            ON n.HICN = b.HICN
               AND n.PaymStart = b.paymstart
               AND n.PaymentYear = b.payment_year
        LEFT JOIN #Bids_RollupMaxPaymStart m
            ON n.PaymentYear = m.payment_year
               AND n.PaymStart = m.max_paymstart
        LEFT JOIN #Tbl_MemberMonthRollup_AltHICN mm
            ON n.HICN = mm.HICN
               AND CASE
                       WHEN YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC THEN
                           n.PaymStartYear
                       ELSE
                           n.PaymStartYear - 1
                   END = mm.paymyear -- Ticket # 26951
        LEFT JOIN #Bids_RollupHICNMaxPaymStart mmm
            ON n.HICN = mmm.HICN
               AND n.PaymStartYear = mmm.paymyear
               AND n.PaymStart = mmm.max_paymstart
        LEFT JOIN [$(HRPReporting)].[dbo].[lk_RA_FACTOR_TYPES] rft
            ON n.RAFactorType = rft.[RA_Type]
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
        RAISERROR('060', 0, 1) WITH NOWAIT;
    END;


    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#Bids_Rollup') IS NOT NULL)
        BEGIN
            DROP TABLE #Bids_Rollup;
        END;

        IF (OBJECT_ID('tempdb.dbo.#Bids_RollupHICNMaxPaymStart') IS NOT NULL)
        BEGIN
            DROP TABLE #Bids_RollupHICNMaxPaymStart;

        END;

        IF (OBJECT_ID('tempdb.dbo.#Bids_RollupMaxPaymStart') IS NOT NULL)
        BEGIN
            DROP TABLE #Bids_RollupMaxPaymStart;
        END;


        IF (OBJECT_ID('tempdb.dbo.#Tbl_MemberMonthRollup_AltHICN') IS NOT NULL)
        BEGIN
            DROP TABLE #Tbl_MemberMonthRollup_AltHICN;
        END;

    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('060.1', 0, 1) WITH NOWAIT;
    END;




    UPDATE n
    SET n.BID = 0
    FROM etl.IntermediateNewHCCOutput n
    --WHERE
    --    n.esrd = 'Y'
    WHERE n.RAFactorType IN ( 'D', 'ED', 'G1', 'G2' ); -- Ticket # 36970;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('061', 0, 1) WITH NOWAIT;
    END;

    DECLARE @ESRDPY INT;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('062', 0, 1) WITH NOWAIT;
    END;

    IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
        SET @ESRDPY = @MaxESRDPY;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('063', 0, 1) WITH NOWAIT;
    END;

    ELSE IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('064', 0, 1) WITH NOWAIT;
    END;

    SET @ESRDPY = @Payment_Year_NewDeleteHCC;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('065', 0, 1) WITH NOWAIT;
    END;

    UPDATE n
    SET n.BID = esrd.Rate
    FROM etl.IntermediateNewHCCOutput n
        INNER JOIN [$(HRPReporting)].dbo.lk_Ratebook_ESRD esrd
            ON n.SCC = esrd.Code
    WHERE esrd.PayMo = @ESRDPY -- Ticket # 26951
          --AND n.esrd = 'Y'
          AND n.RAFactorType IN ( 'D', 'ED', 'G1', 'G2' ); -- Ticket # 36970; 

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('066', 0, 1) WITH NOWAIT;
    END;

    -- Ticket # 26951  Start
    IF OBJECT_ID('[TEMPDB]..[#Tbl_ModelSplit]', 'U') IS NOT NULL
        DROP TABLE #Tbl_ModelSplit;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('067', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #Tbl_ModelSplit
    (
        PaymentYear INT,
        ModelYear INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('068', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #Tbl_ModelSplit
    (
        PaymentYear,
        ModelYear
    )
    SELECT DISTINCT
           PaymentYear,
           ModelYear
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC
    WHERE PaymentYear = @Payment_Year_NewDeleteHCC;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('069', 0, 1) WITH NOWAIT;
    END;

    DECLARE @maxModelYear INT;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('070', 0, 1) WITH NOWAIT;
    END;

    SELECT @maxModelYear = MAX(ModelYear)
    FROM [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC
    WHERE PaymentYear = @Payment_Year_NewDeleteHCC;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('071', 0, 1) WITH NOWAIT;
    END;


    IF @maxModelYear <> @Payment_Year_NewDeleteHCC
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('072', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #Tbl_ModelSplit
        (
            PaymentYear,
            ModelYear
        )
        SELECT @Payment_Year_NewDeleteHCC,
               @Payment_Year_NewDeleteHCC;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('073', 0, 1) WITH NOWAIT;
        END;

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('074', 0, 1) WITH NOWAIT;
    END;

    -- Ticket # 26951 End	

    -- Performance Tuning (Created Temp Tables) Start
    IF OBJECT_ID('TEMPDB..#lk_Factors_PartC_HCC_INT', 'U') IS NOT NULL
        DROP TABLE #lk_Factors_PartC_HCC_INT;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('075', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #lk_Factors_PartC_HCC_INT
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        HCC_Label_NUMBER_HCC_INT INT,
        HCC_LABEL_HCC_INT VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('076', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#lk_Factors_PartG_HCC_INT', 'U') IS NOT NULL
        DROP TABLE #lk_Factors_PartG_HCC_INT;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('077', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #lk_Factors_PartG_HCC_INT
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        HCC_Label_NUMBER_HCC_INT INT,
        HCC_LABEL_HCC_INT VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('078', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#lk_Factors_PartC_DHCC', 'U') IS NOT NULL
        DROP TABLE #lk_Factors_PartC_DHCC;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('079', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #lk_Factors_PartC_DHCC
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        HCC_Label_NUMBER_DHCC INT,
        HCC_LABEL_DHCC VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );
    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('080', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#lk_Factors_PartG_DHCC', 'U') IS NOT NULL
        DROP TABLE #lk_Factors_PartG_DHCC;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('081', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #lk_Factors_PartG_DHCC
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        HCC_Label_NUMBER_DHCC INT,
        HCC_LABEL_DHCC VARCHAR(50),
        [Payment_Year] [VARCHAR](4),
        [Description] [VARCHAR](255)
    );
    --set @start = getdate() 

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('082', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #lk_Factors_PartC_HCC_INT
    SELECT CAST(SUBSTRING(HCC_Label, 4, LEN(HCC_Label) - 3) AS INT),
           LEFT(HCC_Label, 3),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartC
    WHERE (
              LEFT(HCC_Label, 3) = 'HCC'
              OR LEFT(HCC_Label, 3) = 'INT'
          );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('083', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #lk_Factors_PartG_HCC_INT
    SELECT CAST(SUBSTRING(HCC_Label, 4, LEN(HCC_Label) - 3) AS INT),
           LEFT(HCC_Label, 3),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartG
    WHERE (
              LEFT(HCC_Label, 3) = 'HCC'
              OR LEFT(HCC_Label, 3) = 'INT'
          );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('084', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #lk_Factors_PartC_DHCC
    SELECT CAST(SUBSTRING(HCC_Label, 6, LEN(HCC_Label) - 5) AS INT),
           LEFT(HCC_Label, 5),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartC
    WHERE LEFT(HCC_Label, 5) = 'D-HCC';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('085', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #lk_Factors_PartG_DHCC
    SELECT CAST(SUBSTRING(HCC_Label, 6, LEN(HCC_Label) - 5) AS INT),
           LEFT(HCC_Label, 5),
           [Payment_Year],
           [Description]
    FROM [$(HRPReporting)].dbo.lk_Factors_PartG
    WHERE LEFT(HCC_Label, 5) = 'D-HCC';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('086', 0, 1) WITH NOWAIT;
    END;

    -- Performance Tuning (Created Temp Tables) End


    --update Description
    IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
    BEGIN
        UPDATE hccop
        SET hccop.HCCDescription = rskmod.[Description]
        FROM etl.IntermediateNewHCCOutput hccop
            INNER JOIN #lk_Factors_PartC_HCC_INT rskmod
                -- Performance Tuning
                ON rskmod.HCC_Label_NUMBER_HCC_INT = hccop.HCCNumber
                   AND rskmod.HCC_LABEL_HCC_INT = hccop.OnlyHCC
            INNER JOIN #Tbl_ModelSplit ms
                ON rskmod.Payment_Year = ms.ModelYear
                   AND hccop.ModelYear = ms.ModelYear --Ticket # 25351 
        WHERE hccop.RAFactorType IN ( 'C', 'E', 'I', 'CF', 'CP', 'CN' ) -- TFS 59836
              --and ms.PaymentYear = @Payment_Year_NewDeleteHCC          -- Ticket # 26951
              --and (LEFT(RskMod.HCC_Label,3) = 'HCC' or LEFT(RskMod.HCC_Label,3) = 'INT')
              AND
              (
                  hccop.OnlyHCC = 'HCC'
                  OR hccop.OnlyHCC = 'INT'
              );



    END;
    ELSE
    BEGIN
        UPDATE hccop
        SET hccop.HCCDescription = rskmod.[Description]
        FROM etl.IntermediateNewHCCOutput hccop
            INNER JOIN #lk_Factors_PartC_HCC_INT rskmod
                -- Performance Tuning
                ON rskmod.HCC_Label_NUMBER_HCC_INT = hccop.HCCNumber
                   AND rskmod.HCC_LABEL_HCC_INT = hccop.OnlyHCC
            INNER JOIN #Tbl_ModelSplit ms
                ON rskmod.Payment_Year = ms.ModelYear
                   AND hccop.ModelYear = ms.ModelYear --Ticket # 25351 
        WHERE hccop.RAFactorType IN ( 'C', 'E', 'I' ) -- TFS 59836
              --and ms.PaymentYear = @Payment_Year_NewDeleteHCC          -- Ticket # 26951
              --and (LEFT(RskMod.HCC_Label,3) = 'HCC' or LEFT(RskMod.HCC_Label,3) = 'INT')
              AND
              (
                  hccop.OnlyHCC = 'HCC'
                  OR hccop.OnlyHCC = 'INT'
              );



    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('086.1', 0, 1) WITH NOWAIT;
    END;

    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartC_HCC_INT') IS NOT NULL)
        BEGIN
            DROP TABLE #lk_Factors_PartC_HCC_INT;
        END;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('087', 0, 1) WITH NOWAIT;
    END;

    UPDATE hccop
    SET hccop.HCCDescription = rskmod.[Description]
    FROM etl.IntermediateNewHCCOutput hccop
        INNER JOIN #lk_Factors_PartG_HCC_INT rskmod
            -- Performance Tuning
            ON rskmod.HCC_Label_NUMBER_HCC_INT = hccop.HCCNumber
               AND rskmod.HCC_LABEL_HCC_INT = hccop.OnlyHCC
        INNER JOIN #Tbl_ModelSplit ms
            ON rskmod.Payment_Year = ms.ModelYear
               AND hccop.ModelYear = ms.ModelYear --Ticket # 25351
    WHERE hccop.RAFactorType IN ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          --and ms.PaymentYear = @Payment_Year_NewDeleteHCC        -- Ticket # 26951       
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
        RAISERROR('087.1', 0, 1) WITH NOWAIT;
    END;

    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartG_HCC_INT') IS NOT NULL)
        BEGIN
            DROP TABLE #lk_Factors_PartG_HCC_INT;
        END;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('088', 0, 1) WITH NOWAIT;
    END;


    -- BD: update description for D-HCC

    IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
    BEGIN

        UPDATE hccop
        SET hccop.HCCDescription = rskmod.[Description]
        FROM etl.IntermediateNewHCCOutput hccop
            INNER JOIN #lk_Factors_PartC_DHCC rskmod
                -- Performance Tuning
                ON rskmod.HCC_Label_NUMBER_DHCC = hccop.HCCNumber
                   AND rskmod.HCC_LABEL_DHCC = LEFT(hccop.HCCOrig, 5)
            INNER JOIN #Tbl_ModelSplit ms
                ON rskmod.Payment_Year = ms.ModelYear
                   AND hccop.ModelYear = ms.ModelYear --Ticket # 25351
        WHERE hccop.RAFactorType IN ( 'C', 'E', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
              --and ms.PaymentYear = @Payment_Year_NewDeleteHCC    -- Ticket # 26951
              --and LEFT(RskMod.HCC_Label,5) = 'D-HCC' 
              AND LEFT(hccop.HCCOrig, 5) = 'D-HCC';

    END;
    ELSE
    BEGIN
        UPDATE hccop
        SET hccop.HCCDescription = rskmod.[Description]
        FROM etl.IntermediateNewHCCOutput hccop
            INNER JOIN #lk_Factors_PartC_DHCC rskmod
                -- Performance Tuning
                ON rskmod.HCC_Label_NUMBER_DHCC = hccop.HCCNumber
                   AND rskmod.HCC_LABEL_DHCC = LEFT(hccop.HCCOrig, 5)
            INNER JOIN #Tbl_ModelSplit ms
                ON rskmod.Payment_Year = ms.ModelYear
                   AND hccop.ModelYear = ms.ModelYear --Ticket # 25351
        WHERE hccop.RAFactorType IN ( 'C', 'E', 'I' ) --TFS 59836
              --and ms.PaymentYear = @Payment_Year_NewDeleteHCC    -- Ticket # 26951
              --and LEFT(RskMod.HCC_Label,5) = 'D-HCC' 
              AND LEFT(hccop.HCCOrig, 5) = 'D-HCC';

    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('088.1', 0, 1) WITH NOWAIT;
    END;

    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartC_DHCC') IS NOT NULL)
        BEGIN
            DROP TABLE #lk_Factors_PartC_DHCC;
        END;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('089', 0, 1) WITH NOWAIT;
    END;


    UPDATE HCCOP
    SET HCCOP.HCCDescription = RskMod.[Description]
    FROM etl.IntermediateNewHCCOutput HCCOP
        INNER JOIN #lk_Factors_PartG_DHCC RskMod
            -- Performance Tuning
            ON RskMod.HCC_Label_NUMBER_DHCC = HCCOP.HCCNumber
               AND RskMod.HCC_LABEL_DHCC = LEFT(HCCOP.HCCOrig, 5)
        INNER JOIN #Tbl_ModelSplit ms
            ON RskMod.Payment_Year = ms.ModelYear
               AND HCCOP.ModelYear = ms.ModelYear --Ticket # 25351
    WHERE HCCOP.RAFactorType IN ( 'C1', 'C2', 'D', 'E1', 'E2', 'ED', 'G1', 'G2', 'I1', 'I2' )
          --and ms.PaymentYear = @Payment_Year_NewDeleteHCC      -- Ticket # 26951
          --and LEFT(RskMod.HCC_Label,5) = 'D-HCC' 
          AND LEFT(HCCOP.HCCOrig, 5) = 'D-HCC';

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('089.1', 0, 1) WITH NOWAIT;
    END;


    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#lk_Factors_PartG_DHCC') IS NOT NULL)
        BEGIN
            DROP TABLE #lk_Factors_PartG_DHCC;
        END;

        IF (OBJECT_ID('tempdb.dbo.#Tbl_ModelSplit') IS NOT NULL)
        BEGIN
            DROP TABLE #Tbl_ModelSplit;
        END;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('090', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#HIER_hierarchy', 'U') IS NOT NULL
        DROP TABLE #HIER_hierarchy;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('091', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #HIER_hierarchy
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        hicn VARCHAR(15),
        model_year INT,
        ra_factor_type VARCHAR(2),
        hcc VARCHAR(50),
        Unionqueryind INT,
        MinHCCNumner INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('092', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #HIER_hierarchy
    (
        hicn,
        model_year,
        ra_factor_type,
        hcc,
        Unionqueryind,
        MinHCCNumner
    )
    SELECT hccop.HICN,
           hccop.ModelYear,
           hccop.RAFactorType,
           hccop.HCC,
           hccop.Unionqueryind,
           MIN(drp.HCC_Number)
    FROM etl.IntermediateNewHCCOutput hccop
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy hier
            ON hier.payment_year = hccop.ModelYear
               AND hier.ra_factor_type = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models rskmod
            ON rskmod.payment_year = hier.payment_year
               AND rskmod.Factor_Type = hier.ra_factor_type
               AND CAST(SUBSTRING(rskmod.Factor_Description, 4, LEN(rskmod.Factor_Description) - 3) AS INT) = CAST(SUBSTRING(
                                                                                                                                hier.HCC_DROP,
                                                                                                                                4,
                                                                                                                                LEN(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) AS INT)
               AND LEFT(rskmod.Factor_Description, 3) = LEFT(hier.HCC_DROP, 3)
               AND Demo_Risk_Type = 'risk'
        INNER JOIN #New_HCC_Rollup drp
            ON drp.HICN = hccop.HICN
               AND drp.HCC_Number = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.Factor_Desc LIKE 'HIER%'
               AND drp.HCC = LEFT(hier.HCC_DROP, 3)
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
    --and drp.Unionqueryind = hccop.Unionqueryind
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
             hccop.HCC,
             hccop.Unionqueryind;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('093', 0, 1) WITH NOWAIT;
    END;


    --update Hierarchy HCC
    UPDATE hccop
    SET hccop.HierHCCOld = drp.Factor_Desc,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.Min_Processby_PCN
    FROM etl.IntermediateNewHCCOutput hccop
        INNER JOIN #HIER_hierarchy hier
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
               AND hier.Unionqueryind = hccop.Unionqueryind
        INNER JOIN #New_HCC_Rollup drp
            ON drp.HICN = hccop.HICN
               AND drp.Factor_Desc LIKE 'HIER%'
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
               --and drp.Unionqueryind = hccop.Unionqueryind
               AND drp.HCC_Number = hier.MinHCCNumner;

    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#HIER_hierarchy') IS NOT NULL)
        BEGIN
            DROP TABLE #HIER_hierarchy;
        END;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('093.1', 0, 1) WITH NOWAIT;
    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('094', 0, 1) WITH NOWAIT;
    END;


    IF OBJECT_ID('TEMPDB..#INCR_hierarchy', 'U') IS NOT NULL
        DROP TABLE #INCR_hierarchy;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('095', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #INCR_hierarchy
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        hicn VARCHAR(15),
        model_year INT,
        ra_factor_type VARCHAR(2),
        hcc VARCHAR(50),
        MinHCCNumner INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('096', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #INCR_hierarchy
    (
        hicn,
        model_year,
        ra_factor_type,
        hcc,
        MinHCCNumner
    )
    SELECT hccop.HICN,
           hccop.ModelYear,
           hccop.RAFactorType,
           hccop.HCC,
           MIN(drp.HCC_Number)
    FROM etl.IntermediateNewHCCOutput hccop
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy hier
            ON hier.payment_year = hccop.ModelYear
               AND hier.ra_factor_type = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models rskmod
            ON rskmod.payment_year = hier.payment_year
               AND rskmod.Factor_Type = hier.ra_factor_type
               AND CAST(SUBSTRING(rskmod.Factor_Description, 4, LEN(rskmod.Factor_Description) - 3) AS INT) = CAST(SUBSTRING(
                                                                                                                                hier.HCC_DROP,
                                                                                                                                4,
                                                                                                                                LEN(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) AS INT)
               AND LEFT(rskmod.Factor_Description, 3) = LEFT(hier.HCC_DROP, 3)
               AND rskmod.Demo_Risk_Type = 'risk'
        INNER JOIN #New_HCC_Rollup drp
            ON drp.HICN = hccop.HICN
               AND drp.HCC_Number = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.Factor_Desc LIKE 'INCR%'
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
          --and RskMod.Factor > isnull(HCCOP.HIER_FACTOR_OLD,0)
          AND LEFT(hccop.HCC, 5) <> 'D-HCC'
    --and HCCOP.hicn = '007328933A'	
    --and HCCOP.paymstart = '2014-01-01 00:00:00.000'
    GROUP BY hccop.HICN,
             hccop.ModelYear,
             hccop.RAFactorType,
             hccop.HCC;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('097', 0, 1) WITH NOWAIT;
    END;


    --update Hierarchy HCC
    UPDATE hccop
    SET hccop.HierHCCOld = drp.Factor_Desc,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.Min_Processby_PCN
    FROM etl.IntermediateNewHCCOutput hccop
        JOIN #INCR_hierarchy hier
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
        JOIN #New_HCC_Rollup drp
            ON drp.HICN = hccop.HICN
               AND drp.Factor_Desc LIKE 'INCR%'
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
               AND drp.HCC_Number = hier.MinHCCNumner;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('097.1', 0, 1) WITH NOWAIT;
    END;

    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#INCR_hierarchy') IS NOT NULL)
        BEGIN
            DROP TABLE #INCR_hierarchy;
        END;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('098', 0, 1) WITH NOWAIT;
    END;


    IF OBJECT_ID('TEMPDB..#MOR_hierarchy', 'U') IS NOT NULL
        DROP TABLE #MOR_hierarchy;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('099', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #MOR_hierarchy
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
        hicn VARCHAR(15),
        model_year INT,
        ra_factor_type VARCHAR(2),
        hcc VARCHAR(50),
        MinHCCNumner INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('100', 0, 1) WITH NOWAIT;
    END;

    INSERT INTO #MOR_hierarchy
    (
        hicn,
        model_year,
        ra_factor_type,
        hcc,
        MinHCCNumner
    )
    SELECT hccop.HICN,
           hccop.ModelYear,
           hccop.RAFactorType,
           hccop.HCC,
           MIN(drp.HCC_Number)
    FROM etl.IntermediateNewHCCOutput hccop
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy hier
            ON hier.payment_year = hccop.ModelYear
               AND hier.ra_factor_type = hccop.RAFactorType
               AND CAST(SUBSTRING(hier.HCC_KEEP, 4, LEN(hier.HCC_KEEP) - 3) AS INT) = hccop.HCCNumber
               AND LEFT(hier.HCC_KEEP, 3) = hccop.OnlyHCC
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models rskmod
            ON rskmod.payment_year = hier.payment_year
               AND rskmod.Factor_Type = hier.ra_factor_type
               AND CAST(SUBSTRING(rskmod.Factor_Description, 4, LEN(rskmod.Factor_Description) - 3) AS INT) = CAST(SUBSTRING(
                                                                                                                                hier.HCC_DROP,
                                                                                                                                4,
                                                                                                                                LEN(hier.HCC_DROP)
                                                                                                                                - 3
                                                                                                                            ) AS INT)
               AND LEFT(rskmod.Factor_Description, 3) = LEFT(hier.HCC_DROP, 3)
               AND rskmod.Demo_Risk_Type = 'risk'
        INNER JOIN #New_HCC_Rollup drp
            ON drp.HICN = hccop.HICN
               AND drp.HCC_Number = CAST(SUBSTRING(hier.HCC_DROP, 4, LEN(hier.HCC_DROP) - 3) AS INT)
               AND drp.Factor_Desc LIKE 'MOR-INCR%'
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
          --and RskMod.Factor > isnull(HCCOP.HIER_FACTOR_OLD,0)
          AND LEFT(hccop.HCC, 5) <> 'D-HCC'
    --and HCCOP.hicn = '007328933A'	
    --and HCCOP.paymstart = '2014-01-01 00:00:00.000'
    GROUP BY hccop.HICN,
             hccop.ModelYear,
             hccop.RAFactorType,
             hccop.HCC;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('101', 0, 1) WITH NOWAIT;
    END;

    UPDATE hccop
    SET hccop.HierHCCOld = drp.Factor_Desc,
        hccop.HierFactorOld = drp.Factor,
        hccop.HierHCCProcessedPCN = drp.Min_Processby_PCN
    FROM etl.IntermediateNewHCCOutput hccop
        INNER JOIN #MOR_hierarchy hier
            ON hier.hicn = hccop.HICN
               AND hier.ra_factor_type = hccop.RAFactorType
               AND hier.model_year = hccop.ModelYear
               AND hier.hcc = hccop.HCC
        INNER JOIN #New_HCC_Rollup drp
            ON drp.HICN = hccop.HICN
               AND drp.Factor_Desc LIKE 'MOR-INCR%'
               AND drp.RAFT = hccop.RAFactorType
               AND drp.Model_Year = hccop.ModelYear
               AND drp.HCC_Number = hier.MinHCCNumner;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('101.1', 0, 1) WITH NOWAIT;
    END;

    --IF @Debug = 0
    --BEGIN
    --    IF (OBJECT_ID('tempdb.dbo.#MOR_hierarchy') IS NOT NULL)
    --    BEGIN
    --        DROP TABLE #MOR_hierarchy;
    --    END;

    --    IF (OBJECT_ID('tempdb.dbo.#New_HCC_rollup') IS NOT NULL)
    --    BEGIN
    --        DROP TABLE #New_HCC_Rollup;
    --    END;
    --END;

    -- Ticket # 26951 End

    --update HCCOP
    --set HCCOP.Unq_Condition = 0
    --from [etl].[IntermediateNewHCCOutput] HCCOP
    --where (model_year = @Payment_Year_NewDeleteHCC - 1 or model_year = @Payment_Year_NewDeleteHCC - 2)
    --and exists (select 1 from [etl].[IntermediateNewHCCOutput] n
    --            where HCCOP.hicn = n.hicn
    --            and HCCOP.HCC_Number = n.HCC_Number
    --            and HCCOP.onlyHCC = n.onlyHCC
    --            and n.model_year =  @Payment_Year_NewDeleteHCC)

    --update HCCOP
    --set HCCOP.Unq_Condition = 1
    --from [etl].[IntermediateNewHCCOutput] HCCOP
    --where HCCOP.Unq_Condition is NULL           

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('102', 0, 1) WITH NOWAIT;
    END;

    SELECT @Coding_Intensity = CodingIntensity
    FROM [$(HRPReporting)].dbo.lk_normalization_factors
    WHERE [Year] = @Payment_Year_NewDeleteHCC;

    -- Ticket # 26951 Start

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('103', 0, 1) WITH NOWAIT;
    END;

    IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
    BEGIN


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('104', 0, 1) WITH NOWAIT;
        END;

        IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
        BEGIN

            UPDATE HCCOP
            SET HCCOP.FinalFactor = CASE
                                        WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                            ISNULL(
                                                      (ROUND(
                                                                ROUND(
                                                                         ROUND(
                                                                                  (HCCOP.Factor)
                                                                                  / m.PartCNormalizationFactor,
                                                                                  3
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
                                                                                   - ISNULL(HCCOP.HierHCCOld, 0)
                                                                                  )
                                                                                  / m.PartCNormalizationFactor,
                                                                                  3
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                    ON m.ModelYear = HCCOP.ModelYear
                       AND m.PaymentYear = HCCOP.PaymentYear
                       AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType IN ( 'C', 'I', 'CF', 'CP', 'CN' ); -- Ticket # 25426    TFS 59836

        END;
        ELSE
        BEGIN
            UPDATE HCCOP
            SET HCCOP.FinalFactor = CASE
                                        WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                            ISNULL(
                                                      (ROUND(
                                                                ROUND(
                                                                         ROUND(
                                                                                  (HCCOP.Factor)
                                                                                  / m.PartCNormalizationFactor,
                                                                                  3
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                    ON m.ModelYear = HCCOP.ModelYear
                       AND m.PaymentYear = HCCOP.PaymentYear
                       AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType IN ( 'C', 'I' ); -- Ticket # 25426    TFS 59836




        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('105', 0, 1) WITH NOWAIT;
        END;


        IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
        BEGIN

            UPDATE HCCOP
            SET HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                               CASE
                                                   WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                       ISNULL(
                                                                 (ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)
                                                                  * (HCCOP.BID * 12)
                                                                 ),
                                                                 0
                                                             )
                                                   ELSE
                                                       ISNULL(
                                                                 (ROUND(
                                                                           ROUND(
                                                                                    (HCCOP.Factor)
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                                           (HCCOP.Factor
                                                                            - ISNULL(HCCOP.HierFactorOld, 0)
                                                                           )
                                                                           / (nf.ESRD_Dialysis_Factor),
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
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                    ISNULL((ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)), 0)
                                                ELSE
                                                    ISNULL(
                                                              (ROUND(
                                                                        ROUND(
                                                                                 (HCCOP.Factor)
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                                        / (nf.ESRD_Dialysis_Factor),
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
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                               ELSE
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                           END
                                   END
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                    ON nf.[Year] = @Payment_Year_NewDeleteHCC
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ); --TFS 59836

        END;
        ELSE
        BEGIN
            UPDATE HCCOP
            SET HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                               CASE
                                                   WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                       ISNULL(
                                                                 (ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)
                                                                  * (HCCOP.BID * 12)
                                                                 ),
                                                                 0
                                                             )
                                                   ELSE
                                                       ISNULL(
                                                                 (ROUND(
                                                                           ROUND(
                                                                                    (HCCOP.Factor)
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                                           (HCCOP.Factor
                                                                            - ISNULL(HCCOP.HierFactorOld, 0)
                                                                           )
                                                                           / (nf.ESRD_Dialysis_Factor),
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
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                    ISNULL((ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)), 0)
                                                ELSE
                                                    ISNULL(
                                                              (ROUND(
                                                                        ROUND(
                                                                                 (HCCOP.Factor)
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                                        / (nf.ESRD_Dialysis_Factor),
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
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                               ELSE
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                           END
                                   END
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                    ON nf.[Year] = @Payment_Year_NewDeleteHCC
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType NOT IN ( 'C', 'I' ); --TFS 59836


        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('106', 0, 1) WITH NOWAIT;
        END;

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('107', 0, 1) WITH NOWAIT;
    END;

    -- Ticket # 26951 End

    ELSE
    BEGIN
        --set @start = getdate() 

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('108', 0, 1) WITH NOWAIT;
        END;

        IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
        BEGIN
            UPDATE HCCOP
            SET HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                               ISNULL(
                                                         (ROUND(
                                                                   ROUND(
                                                                            ROUND(
                                                                                     (HCCOP.Factor)
                                                                                     / m.PartCNormalizationFactor,
                                                                                     3
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                    ON m.ModelYear = HCCOP.ModelYear
                       AND m.PaymentYear = HCCOP.PaymentYear
                       AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType IN ( 'C', 'I', 'CF', 'CP', 'CN' ); -- Ticket # 25426


        END;
        ELSE
        BEGIN
            UPDATE HCCOP
            SET HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                               ISNULL(
                                                         (ROUND(
                                                                   ROUND(
                                                                            ROUND(
                                                                                     (HCCOP.Factor)
                                                                                     / m.PartCNormalizationFactor,
                                                                                     3
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
                                                                                 ) * (1 - @Coding_Intensity),
                                                                            3
                                                                        ) * SplitSegmentWeight,
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
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
                                                                              ) * (1 - @Coding_Intensity),
                                                                         3
                                                                     ) * SplitSegmentWeight,
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
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                    ON m.ModelYear = HCCOP.ModelYear
                       AND m.PaymentYear = HCCOP.PaymentYear
                       AND m.RAFactorType = HCCOP.RAFactorType
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType IN ( 'C', 'I' ); -- Ticket # 25426


        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('109', 0, 1) WITH NOWAIT;
        END;


        IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
        BEGIN
            UPDATE HCCOP
            SET HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                               CASE
                                                   WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                       ISNULL(
                                                                 (ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)
                                                                  * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1))
                                                                 ),
                                                                 0
                                                             )
                                                   ELSE
                                                       ISNULL(
                                                                 (ROUND(
                                                                           ROUND(
                                                                                    (HCCOP.Factor)
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                                           (HCCOP.Factor
                                                                            - ISNULL(HCCOP.HierFactorOld, 0)
                                                                           )
                                                                           / (nf.ESRD_Dialysis_Factor),
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
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                    ISNULL((ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)), 0)
                                                ELSE
                                                    ISNULL(
                                                              (ROUND(
                                                                        ROUND(
                                                                                 (HCCOP.Factor)
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                                        / (nf.ESRD_Dialysis_Factor),
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
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                               ELSE
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                           END
                                   END
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                    ON nf.[Year] = @Payment_Year_NewDeleteHCC
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' );


        END;
        ELSE
        BEGIN
            UPDATE HCCOP
            SET HCCOP.EstimatedValue = CASE
                                           WHEN HCCOP.HierHCCOld LIKE 'HIER%' THEN
                                               CASE
                                                   WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                       ISNULL(
                                                                 (ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)
                                                                  * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1))
                                                                 ),
                                                                 0
                                                             )
                                                   ELSE
                                                       ISNULL(
                                                                 (ROUND(
                                                                           ROUND(
                                                                                    (HCCOP.Factor)
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                                           (HCCOP.Factor
                                                                            - ISNULL(HCCOP.HierFactorOld, 0)
                                                                           )
                                                                           / (nf.ESRD_Dialysis_Factor),
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
                                                                                    / (nf.FunctioningGraft_Factor),
                                                                                    3
                                                                                ) * (1 - @Coding_Intensity),
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
                                                    ISNULL((ROUND((HCCOP.Factor) / (nf.ESRD_Dialysis_Factor), 3)), 0)
                                                ELSE
                                                    ISNULL(
                                                              (ROUND(
                                                                        ROUND(
                                                                                 (HCCOP.Factor)
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                                        / (nf.ESRD_Dialysis_Factor),
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
                                                                                 / (nf.FunctioningGraft_Factor),
                                                                                 3
                                                                             ) * (1 - @Coding_Intensity),
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
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                               ELSE
                                                   ISNULL(
                                                             (ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)),
                                                             0
                                                         )
                                           END
                                   END
            FROM etl.IntermediateNewHCCOutput HCCOP
                INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                    ON nf.[Year] = @Payment_Year_NewDeleteHCC
            WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                  AND HCCOP.RAFactorType NOT IN ( 'C', 'I' );


        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('110', 0, 1) WITH NOWAIT;
        END;

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('111', 0, 1) WITH NOWAIT;
    END;


    IF @ReportOutputByMonth = 'V'
    BEGIN
        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('112', 0, 1) WITH NOWAIT;
        END;


        IF OBJECT_ID('TEMPDB..#RptClientPCNStrings', 'U') IS NOT NULL
            DROP TABLE #RptClientPCNStrings;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('113', 0, 1) WITH NOWAIT;
        END;

        CREATE TABLE #RptClientPCNStrings
        (
            ID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
            PCN_STRING VARCHAR(100)
        );

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('114', 0, 1) WITH NOWAIT;
        END;

        SET @RollupSQL
            = 'select PCN_STRING  from  ' + @Clnt_Rpt_Srv + '.' + @Clnt_Rpt_DB
              + '.dbo.RptClientPcnStrings
	                     where CLIENT_DB = ''' + @Clnt_Rpt_DB + ''' and PAYMENT_YEAR = ' + @Payment_Year_NewDeleteHCC
              + '
	                     and ACTIVE = ''Y'' and TERMDATE = ''0001-01-01'' and IDENTIFIER = ''Valuation''';

        IF @Debug = 1
        BEGIN
            PRINT '--======================--';
            PRINT '@Clnt_Rpt_Srv: ' + ISNULL(@Clnt_Rpt_Srv, 'NULL');
            PRINT '@Clnt_Rpt_DB: ' + ISNULL(@Clnt_Rpt_DB, 'NULL');
            PRINT '@Payment_Year_NewDeleteHCC: ' + ISNULL(@Payment_Year_NewDeleteHCC, 'NULL');
            PRINT '--======================--';
            PRINT '--======================--';
            PRINT ISNULL(@RollupSQL, 'NULL');
            PRINT '--======================--';
        END;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('115', 0, 1) WITH NOWAIT;
        END;


        SET @RollupSQL = 'INSERT  INTO #RptClientPCNStrings (PCN_STRING) ' + @RollupSQL;
        EXEC (@RollupSQL);


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('116', 0, 1) WITH NOWAIT;
        END;

        IF OBJECT_ID('TEMPDB..#HierPCNLookup', 'U') IS NOT NULL
            DROP TABLE #HierPCNLookup;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('117', 0, 1) WITH NOWAIT;
        END;

        CREATE TABLE #HierPCNLookup
        (
            [ID] INT IDENTITY(1, 1) PRIMARY KEY,
            [Processed_Priority_PCN] VARCHAR(50),
            HIER_HCC_PROCESSED_PCN VARCHAR(50)
        );

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('118', 0, 1) WITH NOWAIT;
        END;
        INSERT INTO #HierPCNLookup
        (
            Processed_Priority_PCN,
            HIER_HCC_PROCESSED_PCN
        )
        SELECT ProcessedPriorityPCN,
               HierHCCProcessedPCN
        FROM etl.IntermediateNewHCCOutput
        WHERE [HierHCCOld] LIKE 'HIER%';

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('119', 0, 1) WITH NOWAIT;
        END;

        IF (OBJECT_ID('tempdb.dbo.#ValuationPerfFix') IS NOT NULL)
        BEGIN
            DROP TABLE #ValuationPerfFix;
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('120', 0, 1) WITH NOWAIT;
        END;

        CREATE TABLE #ValuationPerfFix
        (
            [Id] INT IDENTITY(1, 1) PRIMARY KEY,
            [Processed_Priority_PCN] VARCHAR(50),
            [PCNFlag] BIT
        );


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('121', 0, 1) WITH NOWAIT;
        END;

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
            RAISERROR('122', 0, 1) WITH NOWAIT;
        END;

        UPDATE etl.IntermediateNewHCCOutput
        SET HCCPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput hccop
            JOIN #ValuationPerfFix a
                ON a.Processed_Priority_PCN = hccop.ProcessedPriorityPCN
        WHERE hccop.HierHCCOld LIKE 'HIER%';

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('122.1', 0, 1) WITH NOWAIT;
        END;

        IF @Debug = 0
        BEGIN
            IF (OBJECT_ID('tempdb.dbo.#ValuationPerfFix') IS NOT NULL)
            BEGIN
                DROP TABLE #ValuationPerfFix;
            END;
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('123', 0, 1) WITH NOWAIT;
        END;

        --Ticket # 33931 Start

        UPDATE etl.IntermediateNewHCCOutput
        SET HCCPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput HCCOP
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

        UPDATE etl.IntermediateNewHCCOutput
        SET HCCPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput HCCOP
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

        UPDATE etl.IntermediateNewHCCOutput
        SET HCCPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput HCCOP
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
            RAISERROR('124', 0, 1) WITH NOWAIT;
        END;

        UPDATE etl.IntermediateNewHCCOutput
        SET HCCPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput hccop
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

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('125', 0, 1) WITH NOWAIT;
        END;

        UPDATE etl.IntermediateNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput hccop
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

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('126', 0, 1) WITH NOWAIT;
        END;
        --Ticket # 33931 Start

        UPDATE etl.IntermediateNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput HCCOP
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

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('126.1', 0, 1) WITH NOWAIT;
        END;

        UPDATE etl.IntermediateNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput HCCOP
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

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('126.2', 0, 1) WITH NOWAIT;
        END;

        --Ticket # 33931 End

        UPDATE etl.IntermediateNewHCCOutput
        SET HierPCNMatch = a.PCNFlag
        FROM etl.IntermediateNewHCCOutput hccop
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
            RAISERROR('127', 0, 1) WITH NOWAIT;
        END;

        UPDATE etl.IntermediateNewHCCOutput
        SET HierPCNMatch = 0
        FROM etl.IntermediateNewHCCOutput hccop
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

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('127.1', 0, 1) WITH NOWAIT;
        END;

        IF @Debug = 0
        BEGIN
            IF (OBJECT_ID('tempdb.dbo.#HierPCNLookup') IS NOT NULL)
            BEGIN
                DROP TABLE #HierPCNLookup;
            END;

            IF (OBJECT_ID('tempdb.dbo.#RptClientPCNStrings') IS NOT NULL)
            BEGIN
                DROP TABLE #RptClientPCNStrings;
            END;
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('128', 0, 1) WITH NOWAIT;
        END;

        IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('129', 0, 1) WITH NOWAIT;
            END;

            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
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
                                                                          ) * (1 - @Coding_Intensity),
                                                                     3
                                                                 ) * SplitSegmentWeight,
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
                                                                             ) * (1 - @Coding_Intensity),
                                                                        3
                                                                    ) * SplitSegmentWeight,
                                                               3
                                                           )
                                                     ) * (HCCOP.BID * 12),
                                                     0
                                                 ),
                    HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                FROM etl.IntermediateNewHCCOutput HCCOP
                    INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                        ON m.ModelYear = HCCOP.ModelYear
                           AND m.PaymentYear = HCCOP.PaymentYear
                           AND m.RAFactorType = HCCOP.RAFactorType
                WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                      AND HCCOP.RAFactorType IN ( 'C', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
                      AND HCCOP.HCCPCNMatch = 1
                      AND HCCOP.HierPCNMatch = 0;


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
                                                                          ) * (1 - @Coding_Intensity),
                                                                     3
                                                                 ) * SplitSegmentWeight,
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
                                                                             ) * (1 - @Coding_Intensity),
                                                                        3
                                                                    ) * SplitSegmentWeight,
                                                               3
                                                           )
                                                     ) * (HCCOP.BID * 12),
                                                     0
                                                 ),
                    HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                FROM etl.IntermediateNewHCCOutput HCCOP
                    INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                        ON m.ModelYear = HCCOP.ModelYear
                           AND m.PaymentYear = HCCOP.PaymentYear
                           AND m.RAFactorType = HCCOP.RAFactorType
                WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                      AND HCCOP.RAFactorType IN ( 'C', 'I' ) --TFS 59836
                      AND HCCOP.HCCPCNMatch = 1
                      AND HCCOP.HierPCNMatch = 0;


            END;



            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('130', 0, 1) WITH NOWAIT;
            END;

            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
            BEGIN
                UPDATE HCCOP
                SET HCCOP.FinalFactor = CASE
                                            WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL(
                                                          (ROUND(
                                                                    (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                    / (nf.ESRD_Dialysis_Factor),
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
                                                                             / (nf.FunctioningGraft_Factor),
                                                                             3
                                                                         ) * (1 - @Coding_Intensity),
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
                                                                       / (nf.ESRD_Dialysis_Factor),
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
                                                                                / (nf.FunctioningGraft_Factor),
                                                                                3
                                                                            ) * (1 - @Coding_Intensity),
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
                FROM etl.IntermediateNewHCCOutput HCCOP
                    INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                        ON [Year] = @Payment_Year_NewDeleteHCC
                WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                      AND HCCOP.RAFactorType NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
                      AND HCCOP.HCCPCNMatch = 1
                      AND HCCOP.HierPCNMatch = 0;


            END;
            ELSE
            BEGIN
                UPDATE HCCOP
                SET HCCOP.FinalFactor = CASE
                                            WHEN HCCOP.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL(
                                                          (ROUND(
                                                                    (HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0))
                                                                    / (nf.ESRD_Dialysis_Factor),
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
                                                                             / (nf.FunctioningGraft_Factor),
                                                                             3
                                                                         ) * (1 - @Coding_Intensity),
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
                                                                       / (nf.ESRD_Dialysis_Factor),
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
                                                                                / (nf.FunctioningGraft_Factor),
                                                                                3
                                                                            ) * (1 - @Coding_Intensity),
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
                FROM etl.IntermediateNewHCCOutput HCCOP
                    INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                        ON [Year] = @Payment_Year_NewDeleteHCC
                WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                      AND HCCOP.RAFactorType NOT IN ( 'C', 'I' ) --TFS 59836
                      AND HCCOP.HCCPCNMatch = 1
                      AND HCCOP.HierPCNMatch = 0;

            END;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('131', 0, 1) WITH NOWAIT;
            END;

        END;
        ELSE
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('132', 0, 1) WITH NOWAIT;
            END;

            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
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
                                                                          ) * (1 - @Coding_Intensity),
                                                                     3
                                                                 ) * SplitSegmentWeight,
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
                                                                             ) * (1 - @Coding_Intensity),
                                                                        3
                                                                    ) * SplitSegmentWeight,
                                                               3
                                                           )
                                                     ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1)),
                                                     0
                                                 ),
                    HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                FROM etl.IntermediateNewHCCOutput HCCOP
                    INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                        ON m.ModelYear = HCCOP.ModelYear
                           AND m.PaymentYear = HCCOP.PaymentYear
                           AND m.RAFactorType = HCCOP.RAFactorType
                WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                      AND HCCOP.RAFactorType IN ( 'C', 'I', 'CF', 'CP', 'CN' ) --TFS 59836
                      AND HCCOP.HierPCNMatch = 0;


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
                                                                          ) * (1 - @Coding_Intensity),
                                                                     3
                                                                 ) * SplitSegmentWeight,
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
                                                                             ) * (1 - @Coding_Intensity),
                                                                        3
                                                                    ) * SplitSegmentWeight,
                                                               3
                                                           )
                                                     ) * (HCCOP.BID * ISNULL(HCCOP.MemberMonths, 1)),
                                                     0
                                                 ),
                    HCCOP.FactorDiff = ISNULL((ROUND((HCCOP.Factor - ISNULL(HCCOP.HierFactorOld, 0)), 3)), 0)
                FROM etl.IntermediateNewHCCOutput HCCOP
                    INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC m
                        ON m.ModelYear = HCCOP.ModelYear
                           AND m.PaymentYear = HCCOP.PaymentYear
                           AND m.RAFactorType = HCCOP.RAFactorType
                WHERE ISNULL(HCCOP.HOSP, 'N') <> 'Y'
                      AND HCCOP.RAFactorType IN ( 'C', 'I' ) --TFS 59836
                      AND HCCOP.HierPCNMatch = 0;

            END;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('133', 0, 1) WITH NOWAIT;
            END;

            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
            BEGIN
                UPDATE hccop
                SET hccop.FinalFactor = CASE
                                            WHEN hccop.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL(
                                                          (ROUND(
                                                                    (hccop.Factor - ISNULL(hccop.HierFactorOld, 0))
                                                                    / (nf.ESRD_Dialysis_Factor),
                                                                    3
                                                                )
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
                                                                             / (nf.FunctioningGraft_Factor),
                                                                             3
                                                                         ) * (1 - @Coding_Intensity),
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
                                                                       / (nf.ESRD_Dialysis_Factor),
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
                                                                                / (nf.FunctioningGraft_Factor),
                                                                                3
                                                                            ) * (1 - @Coding_Intensity),
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
                FROM etl.IntermediateNewHCCOutput hccop
                    INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                        ON [Year] = @Payment_Year_NewDeleteHCC
                WHERE ISNULL(hccop.HOSP, 'N') <> 'Y'
                      AND hccop.RAFactorType NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' )
                      AND hccop.HCCPCNMatch = 1
                      AND hccop.HierPCNMatch = 0;


            END;
            ELSE
            BEGIN
                UPDATE hccop
                SET hccop.FinalFactor = CASE
                                            WHEN hccop.RAFactorType IN ( 'D', 'ED' ) THEN
                                                ISNULL(
                                                          (ROUND(
                                                                    (hccop.Factor - ISNULL(hccop.HierFactorOld, 0))
                                                                    / (nf.ESRD_Dialysis_Factor),
                                                                    3
                                                                )
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
                                                                             / (nf.FunctioningGraft_Factor),
                                                                             3
                                                                         ) * (1 - @Coding_Intensity),
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
                                                                       / (nf.ESRD_Dialysis_Factor),
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
                                                                                / (nf.FunctioningGraft_Factor),
                                                                                3
                                                                            ) * (1 - @Coding_Intensity),
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
                FROM etl.IntermediateNewHCCOutput hccop
                    INNER JOIN [$(HRPReporting)].dbo.lk_normalization_factors nf
                        ON nf.[Year] = @Payment_Year_NewDeleteHCC
                WHERE ISNULL(hccop.HOSP, 'N') <> 'Y'
                      AND hccop.RAFactorType NOT IN ( 'C', 'I' )
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
                RAISERROR('134', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('135', 0, 1) WITH NOWAIT;
        END;

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('136', 0, 1) WITH NOWAIT;
    END;

    --select * from [etl].[IntermediateNewHCCOutput]
    --     where hicn = '067341879A'
    --     and  processed_priority_pcn = 'MR_AUDIT_PC109370004_394996_745_3HRP'
    --     and hier_hcc_old like 'HIER%'


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('137', 0, 1) WITH NOWAIT;
    END;



    IF OBJECT_ID('TEMPDB..#RollForward_Months', 'U') IS NOT NULL
        DROP TABLE #RollForward_Months;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('138', 0, 1) WITH NOWAIT;
    END;


    CREATE TABLE #RollForward_Months
    (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY,
        [planid] VARCHAR(5),
        [hicn] VARCHAR(15),
        [ra_factor_type] VARCHAR(2),
        [pbp] VARCHAR(3),
        [scc] VARCHAR(5),
        [member_months] DATETIME
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('139', 0, 1) WITH NOWAIT;
    END;

    --set @start = getdate() 
    INSERT INTO #RollForward_Months
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
    FROM etl.IntermediateNewHCCOutput
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
        RAISERROR('140', 0, 1) WITH NOWAIT;
    END;

    CREATE NONCLUSTERED INDEX ix_rollforward_months_HICN
    ON #RollForward_Months (
                               hicn,
                               ra_factor_type,
                               planid,
                               scc,
                               pbp
                           ); -- Performance Tuning (Added extra columns in Index)

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('141', 0, 1) WITH NOWAIT;
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('142', 0, 1) WITH NOWAIT;
    END;

    DECLARE @MaxMonth INT; -- Ticket # 29157

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('143', 0, 1) WITH NOWAIT;
    END;

    SELECT @MaxMonth = MONTH(MAX(paymstart))
    FROM etl.IntermediateNewHCCOutput; -- Ticket # 29157

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('144', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#NewHCCFinalDVView', 'U') IS NOT NULL
        DROP TABLE #NewHCCFinalDVView;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('145', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #NewHCCFinalDVView
    (
        payment_year INT,
        model_year INT,
        processed_by_start DATETIME,
        processed_by_end DATETIME,
        Unionqueryind INT,
        planid VARCHAR(5),
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

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('146', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#NewHCCFinalTView', 'U') IS NOT NULL
        DROP TABLE #NewHCCFinalTView;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('147', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #NewHCCFinalTView
    (
        [payment_year] [INT] NULL,
        [PAYMSTART] [DATETIME] NULL,
        [PROCESSED_BY_START] [SMALLDATETIME] NULL,
        [PROCESSED_BY_END] [SMALLDATETIME] NULL,
        [PLANID] [VARCHAR](5) NULL,
        [HICN] [VARCHAR](15) NULL,
        [RA_FACTOR_TYPE] [VARCHAR](10) NULL,
        [PROCESSED_PRIORITY_PROCESSED_BY] [DATETIME] NULL,
        [PROCESSED_PRIORITY_THRU_DATE] [DATETIME] NULL,
        [PROCESSED_PRIORITY_PCN] [VARCHAR](50) NULL,
        [PROCESSED_PRIORITY_DIAG] [VARCHAR](20) NULL,
        [THRU_PRIORITY_PROCESSED_BY] [DATETIME] NULL,
        [THRU_PRIORITY_THRU_DATE] [DATETIME] NULL,
        [THRU_PRIORITY_PCN] [VARCHAR](50) NULL,
        [THRU_PRIORITY_DIAG] [VARCHAR](20) NULL,
        [HCC] [VARCHAR](20) NULL,
        [HCC_DESCRIPTION] [VARCHAR](255) NULL,
        [FACTOR] [DECIMAL](20, 4) NULL,
        [HIER_HCC_OLD] [VARCHAR](20) NULL,
        [HIER_FACTOR_OLD] [DECIMAL](20, 4) NULL,
        [ACTIVE_INDICATOR_FOR_ROLLFORWARD] [VARCHAR](1) NULL,
        [MONTHS_IN_DCP] [INT] NULL,
        [ESRD] [VARCHAR](3) NULL,
        [HOSP] [VARCHAR](3) NULL,
        [PBP] [VARCHAR](3) NULL,
        [SCC] [VARCHAR](5) NULL,
        [BID] [MONEY] NULL,
        [ESTIMATED_VALUE] [MONEY] NULL,
        [RAPS_SOURCE] [VARCHAR](50) NULL,
        [PROVIDER_ID] [VARCHAR](40) NULL,
        [PROVIDER_LAST] [VARCHAR](55) NULL,
        [PROVIDER_FIRST] [VARCHAR](55) NULL,
        [PROVIDER_GROUP] [VARCHAR](80) NULL,
        [PROVIDER_ADDRESS] [VARCHAR](100) NULL,
        [PROVIDER_CITY] [VARCHAR](30) NULL,
        [PROVIDER_STATE] [VARCHAR](2) NULL,
        [PROVIDER_ZIP] [VARCHAR](13) NULL,
        [PROVIDER_PHONE] [VARCHAR](15) NULL,
        [PROVIDER_FAX] [VARCHAR](15) NULL,
        [TAX_ID] [VARCHAR](55) NULL,
        [NPI] [VARCHAR](20) NULL,
        [SWEEP_DATE] [DATETIME] NULL,
        [MODEL_YEAR] [INT] NULL,
        [FINAL_FACTOR] [DECIMAL](20, 4) NULL,
        factor_diff [DECIMAL](20, 4) NULL,
        [HIER_HCC_PROCESSED_PCN] [VARCHAR](50) NULL,
        [Processed_Priority_FileID] [VARCHAR](18) NULL,
        [Processed_Priority_RAC] [VARCHAR](1) NULL,
        [DOS_PRIORITY_FILEID] [VARCHAR](18) NULL,
        [DOS_PRIORITY_RAC] [VARCHAR](1) NULL,
        [DOS_PRIORITY_RAPS_SOURCE] VARCHAR(50) NULL,
        onlyHCC VARCHAR(20),
        HCC_Number INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('148', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#MaxMonthHCCRAFTPBPSCC', 'U') IS NOT NULL
        DROP TABLE #MaxMonthHCCRAFTPBPSCC;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('149', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #MaxMonthHCCRAFTPBPSCC
    (
        PaymentYear INT,
        ModelYear INT,
        PlanID VARCHAR(5),
        hicn VARCHAR(15),
        onlyHCC VARCHAR(20),
        HCC_Number INT,
        ra_factor_type VARCHAR(2),
        pbp VARCHAR(3),
        scc VARCHAR(5),
        MaxMemberMonth DATETIME,
        AGED INT
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('150', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#MaxMonthHCC', 'U') IS NOT NULL
        DROP TABLE #MaxMonthHCC;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('151', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #MaxMonthHCC
    (
        PaymentYear INT,
        ModelYear INT,
        PlanID VARCHAR(5),
        hicn VARCHAR(15),
        onlyHCC VARCHAR(20),
        HCC_Number INT,
        MaxMemberMonth DATETIME
    );

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('152', 0, 1) WITH NOWAIT;
    END;

    IF OBJECT_ID('TEMPDB..#FinalUniqueCondition', 'U') IS NOT NULL
        DROP TABLE #FinalUniqueCondition;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('153', 0, 1) WITH NOWAIT;
    END;

    CREATE TABLE #FinalUniqueCondition
    (
        PaymentYear INT,
        ModelYear INT,
        PlanID VARCHAR(5),
        hicn VARCHAR(15),
        onlyHCC VARCHAR(20),
        HCC_Number INT,
        ra_factor_type VARCHAR(2),
        pbp VARCHAR(3),
        scc VARCHAR(5),
        AGED INT
    );


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('154', 0, 1) WITH NOWAIT;
    END;



    IF (OBJECT_ID('tempdb.dbo.#ProviderId') IS NOT NULL)
    BEGIN
        DROP TABLE #ProviderId;
    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('154.1', 0, 1) WITH NOWAIT;
    END;


    CREATE TABLE #ProviderId
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

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('154.2', 0, 1) WITH NOWAIT;
    END;

    DECLARE @GetProviderIdSQL VARCHAR(4096);

    SET @GetProviderIdSQL
        = '

INSERT  INTO [#ProviderId]
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
FROM
    ' + @clientlvldb + '.dbo.[tbl_provider_Unique] u
ORDER BY
    u.[Provider_ID]   
'   ;

    IF @Debug = 1
    BEGIN
        PRINT '--======================--';
        PRINT '@clientlvldb: ' + ISNULL(@clientlvldb, 'NULL');
        PRINT '--======================--';
        PRINT ISNULL(@GetProviderIdSQL, 'NULL');
        PRINT '--======================--';
    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('154.3', 0, 1) WITH NOWAIT;
    END;

    EXEC (@GetProviderIdSQL);


    CREATE NONCLUSTERED INDEX [IX_#ProviderId__Provider_Id]
    ON #ProviderId ([Provider_Id])
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
            )
     ;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('154.4', 0, 1) WITH NOWAIT;
    END;


    --Modification for Ticket #24942 will not affect if we run payment year greater than current year - Ticket #24942 End
    --Sweep Date and processed_by_flag should be calculated using Unionqueryind - Ticket #24942 Start
    IF YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('155', 0, 1) WITH NOWAIT;
        END;

        IF @ReportOutputByMonth = 'S'
        BEGIN
            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('156', 0, 1) WITH NOWAIT;
            END;


            SELECT n.PaymentYear,
                   n.ModelYear,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           'I'
                       WHEN n.Unionqueryind = 2 THEN
                           'M'
                   --when n.Unionqueryind = 3 then 'F'
                   END processed_by_flag,
                   n.planid,
                   n.hicn,
                   n.RAFactorTypeORIG AS ra_factor_type,
                   -- Ticket # 26951
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC LIKE 'M-High%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%INT%'
                            AND n.HCC LIKE 'M-High%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%'
                            AND n.HCC LIKE 'M-High%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                       ELSE
                           n.HCC
                   END AS HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld LIKE 'MOR-INCR%' THEN
                           'MOR-' + SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%INT%'
                            AND n.HierHCCOld LIKE 'MOR-INCR%' THEN
                           'MOR-' + SUBSTRING(n.hier_hcc_old, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%'
                            AND n.HierHCCOld LIKE 'MOR-INCR%' THEN
                           'MOR-' + SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                       ELSE
                           n.HierHCCOld
                   END AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FactorDiff AS Pre_Adjstd_Factor,
                   n.FinalFactor AS Adjstd_Final_Factor,
                   ISNULL(n.MonthsIDCP, 0) 'months_in_dcp',
                   0 member_months,
                   -- Ticket # 26951
                   ISNULL(n.BID, 0) 'Bid_Amount',
                   0 estimated_value,
                   -- Ticket # 26951
                   12 rollforward_months,
                   -- Ticket # 26951
                   n.EstimatedValueAnnualizedEstimatedValue,
                   -- Ticket # 26951
                   --isnull(n.esrd, 'N') 'esrd', 
                   --isnull(n.hosp , 'N') 'hosp', 
                   n.pbp,
                   ISNULL(n.scc, 'N') 'scc',
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                   END SWEEP_DATE,
                   [populated_date] = @Populated_Date,
                   -- tfs 66188 - changed AGED to AgedStatus to make ResultSets match
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END
            --, [AGED]  
            FROM etl.IntermediateNewHCCOutput n
                INNER JOIN #RollForward_Months r
                    ON n.hicn = r.hicn
                       AND n.RAFactorType = r.ra_factor_type
                       AND n.planid = r.planid
                       AND n.scc = r.scc
                       AND n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessed_By
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
            ORDER BY n.hicn,
                     n.Unionqueryind,
                     n.ModelYear,
                     n.RAFactorTypeORIG,
                     n.HCC;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('157', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('158', 0, 1) WITH NOWAIT;
        END;


        IF @ReportOutputByMonth = 'D'
           OR @ReportOutputByMonth = 'V'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('159', 0, 1) WITH NOWAIT;
            END;

            IF @RAPS_STRING_ALL = 'ALL'
               AND @File_STRING_ALL = 'ALL'
            BEGIN

                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('160', 0, 1) WITH NOWAIT;
                END;

                INSERT INTO #NewHCCFinalDVView
                SELECT n.PaymentYear,
                       n.ModelYear,
                       n.ProcessedByStart,
                       n.ProcessedByEnd,
                       n.Unionqueryind,
                       n.planid,
                       n.hicn,
                       n.RAFactorTypeORIG AS ra_factor_type,
                       -- Ticket # 26951
                       n.HCC,
                       n.HCCDescription,
                       ISNULL(n.Factor, 0) 'HCC_FACTOR',
                       n.HierHCCOld AS HIER_HCC,
                       ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                       n.FinalFactor AS FINAL_FACTOR,
                       n.FactorDiff,
                       n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                       n.HierHCCProcessedPCN,
                       0 member_months,
                       -- Ticket # 26951
                       ISNULL(n.BID, 0) 'bid',
                       0 estimated_value,
                       -- Ticket # 26951 
                       12 rollforward_months,
                       -- Ticket # 26951
                       n.EstimatedValueAnnualizedEstimatedValue,
                       -- Ticket # 26951
                       ISNULL(n.months_in_dcp, 0) 'months_in_dcp',
                       ISNULL(n.ESRD, 'N') 'esrd',
                       ISNULL(n.HOSP, 'N') 'hosp',
                       n.pbp,
                       ISNULL(n.scc, 'OOA') 'scc',
                       n.ProcessedPriorityProcessedBy,
                       n.ProcessedPriorityThruDate,
                       n.ProcessedPriorityDiag,
                       n.ProcessedPriorityFileID,
                       n.ProcessedPriorityRAC,
                       n.ProcessedPriorityRAPSSourceID,
                       n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                       n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                       n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                       n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                       n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                       n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                       n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                       CASE
                           WHEN n.Unionqueryind = 1 THEN
                               @initial_flag
                           WHEN n.Unionqueryind = 2 THEN
                               @myu_flag
                       --when n.Unionqueryind = 3 then @final_flag 
                       END SWEEP_DATE,
                       [populated_date] = @Populated_Date,
                       n.OnlyHCC,
                       n.HCCNumber,
                       n.AGED
                FROM etl.IntermediateNewHCCOutput n
                    INNER JOIN #RollForward_Months r
                        ON n.hicn = r.hicn
                           AND n.RAFactorType = r.ra_factor_type
                           AND n.planid = r.planid
                           AND n.scc = r.scc
                           AND n.pbp = r.pbp
                WHERE n.ProcessedPriorityProcessedBy
                      BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                      AND n.HCC NOT LIKE 'HIER%';
                --order by n.hicn, n.hcc, n.model_year

                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('161', 0, 1) WITH NOWAIT;
                END;

            END;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('162', 0, 1) WITH NOWAIT;
            END;

            ELSE IF @RAPS_STRING_ALL <> 'ALL'
                    AND @File_STRING_ALL = 'ALL'
            BEGIN
                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('163', 0, 1) WITH NOWAIT;
                END;

                INSERT INTO #NewHCCFinalDVView
                SELECT n.PaymentYear,
                       n.ModelYear,
                       n.ProcessedByStart,
                       n.ProcessedByEnd,
                       n.Unionqueryind,
                       n.planid,
                       n.hicn,
                       n.RAFactorTypeORIG AS ra_factor_type,
                       -- Ticket # 26951
                       n.HCC,
                       n.HCCDescription,
                       ISNULL(n.Factor, 0) 'HCC_FACTOR',
                       n.HierHCCOld AS HIER_HCC,
                       ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                       n.FinalFactor AS FINAL_FACTOR,
                       n.FactorDiff,
                       n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                       n.HierHCCProcessedPCN,
                       0 member_months,
                       -- Ticket # 26951
                       ISNULL(n.BID, 0) 'bid',
                       0 estimated_value,
                       -- Ticket # 26951 
                       12 rollforward_months,
                       -- Ticket # 26951
                       n.EstimatedValue annualized_estimated_value,
                       -- Ticket # 26951
                       ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                       ISNULL(n.ESRD, 'N') 'esrd',
                       ISNULL(n.HOSP, 'N') 'hosp',
                       n.pbp,
                       ISNULL(n.scc, 'OOA') 'scc',
                       n.ProcessedPriorityProcessedBy,
                       n.ProcessedPriorityThru_Date,
                       n.ProcessedPriorityDiag,
                       n.ProcessedPriorityFileID,
                       n.ProcessedPriorityRAC,
                       n.ProcessedPriorityRAPSSourceID,
                       n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                       n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                       n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                       n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                       n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                       n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                       n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                       CASE
                           WHEN n.Unionqueryind = 1 THEN
                               @initial_flag
                           WHEN n.Unionqueryind = 2 THEN
                               @myu_flag
                       --when n.Unionqueryind = 3 then @final_flag 
                       END SWEEP_DATE,
                       [populated_date] = @Populated_Date,
                       n.OnlyHCC,
                       n.HCCNumber,
                       n.AGED
                FROM etl.IntermediateNewHCCOutput n
                    INNER JOIN #RollForward_Months r
                        ON n.hicn = r.hicn
                           AND n.ra_factor_type = r.ra_factor_type
                           AND n.planid = r.planid
                           AND n.scc = r.scc
                           AND n.pbp = r.pbp
                WHERE n.ProcessedPriorityProcessedBy
                      BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                      AND n.HCC NOT LIKE 'HIER%'
                      AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%';
                --order by n.hicn, n.hcc, n.model_year
                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('164', 0, 1) WITH NOWAIT;
                END;

            END;

            ELSE IF @RAPS_STRING_ALL = 'ALL'
                    AND @File_STRING_ALL <> 'ALL'
            BEGIN
                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('165', 0, 1) WITH NOWAIT;
                END;

                INSERT INTO #NewHCCFinalDVView
                SELECT n.PaymentYear,
                       n.ModelYear,
                       n.ProcessedByStart,
                       n.ProcessedByEnd,
                       n.Unionqueryind,
                       n.planid,
                       n.hicn,
                       n.RAFactorTypeORIG AS ra_factor_type,
                       -- Ticket # 26951
                       n.HCC,
                       n.HCCDescription,
                       ISNULL(n.Factor, 0) 'HCC_FACTOR',
                       n.HierHCCOld AS HIER_HCC,
                       ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                       n.FinalFactor AS FINAL_FACTOR,
                       n.FactorDiff,
                       n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                       n.HierHCCProcessedPCN,
                       0 member_months,
                       -- Ticket # 26951
                       ISNULL(n.BID, 0) 'bid',
                       0 estimated_value,
                       -- Ticket # 26951 
                       12 rollforward_months,
                       -- Ticket # 26951
                       n.EstimatedValue annualized_estimated_value,
                       -- Ticket # 26951
                       ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                       ISNULL(n.ESRD, 'N') 'esrd',
                       ISNULL(n.HOSP, 'N') 'hosp',
                       n.pbp,
                       ISNULL(n.scc, 'OOA') 'scc',
                       n.ProcessedPriorityProcessedBy,
                       n.ProcessedPriorityThruDate,
                       n.ProcessedPriorityDiag,
                       n.ProcessedPriorityFileID,
                       n.ProcessedPriorityRAC,
                       n.ProcessedPriorityRAPSSourceID,
                       n.ThruPriorityPprocessedBy AS DOS_PRIORITY_PROCESSED_BY,
                       n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                       n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                       n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                       n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                       n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                       n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                       CASE
                           WHEN n.Unionqueryind = 1 THEN
                               @initial_flag
                           WHEN n.Unionqueryind = 2 THEN
                               @myu_flag
                       --when n.Unionqueryind = 3 then @final_flag 
                       END SWEEP_DATE,
                       [populated_date] = @Populated_Date,
                       n.OnlyHCC,
                       n.HCCNumber,
                       n.AGED
                FROM etl.IntermediateNewHCCOutput n
                    INNER JOIN #RollForward_Months r
                        ON n.hicn = r.hicn
                           AND n.RAFactorType = r.ra_factor_type
                           AND n.planid = r.planid
                           AND n.scc = r.scc
                           AND n.pbp = r.pbp
                WHERE n.ProcessedPriorityProcessedBy
                      BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                      AND n.HCC NOT LIKE 'HIER%'
                      AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';
                --order by n.hicn, n.hcc, n.ModelYear

                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('166', 0, 1) WITH NOWAIT;
                END;

            END;

            ELSE IF @RAPS_STRING_ALL <> 'ALL'
                    AND @File_STRING_ALL <> 'ALL'
            BEGIN
                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('167', 0, 1) WITH NOWAIT;
                END;

                INSERT INTO #NewHCCFinalDVView
                SELECT n.PaymentYear,
                       n.ModelYear,
                       n.ProcessedByStart,
                       n.ProcessedByEnd,
                       n.Unionqueryind,
                       n.planid,
                       n.hicn,
                       n.RAFactorTypeORIG AS ra_factor_type,
                       -- Ticket # 26951
                       n.HCC,
                       n.HCCDescription,
                       ISNULL(n.Factor, 0) 'HCC_FACTOR',
                       n.hier_hcc_old AS HIER_HCC,
                       ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                       n.FinalFactor AS FINAL_FACTOR,
                       n.FactorDiff,
                       n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                       n.HierHCCProcessedPCN,
                       0 member_months,
                       -- Ticket # 26951
                       ISNULL(n.BID, 0) 'bid',
                       0 estimated_value,
                       -- Ticket # 26951 
                       12 rollforward_months,
                       -- Ticket # 26951
                       n.EstimatedValueAnnualizedEstimatedValue,
                       -- Ticket # 26951
                       ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                       ISNULL(n.ESRD, 'N') 'esrd',
                       ISNULL(n.HOSP, 'N') 'hosp',
                       n.pbp,
                       ISNULL(n.scc, 'OOA') 'scc',
                       n.ProcessedPriorityProcessedBy,
                       n.ProcessedPriorityThruDate,
                       n.processed_priority_diag,
                       n.Processed_Priority_FileID,
                       n.Processed_Priority_RAC,
                       n.ProcessedPriorityRAPSSourceID,
                       n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                       n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                       n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                       n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                       n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                       n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                       n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                       CASE
                           WHEN n.Unionqueryind = 1 THEN
                               @initial_flag
                           WHEN n.Unionqueryind = 2 THEN
                               @myu_flag
                       --when n.Unionqueryind = 3 then @final_flag 
                       END SWEEP_DATE,
                       [populated_date] = @Populated_Date,
                       n.OnlyHCC,
                       n.HCCNumber,
                       n.AGED
                FROM etl.IntermediateNewHCCOutput n
                    INNER JOIN #RollForward_Months r
                        ON n.hicn = r.hicn
                           AND n.RAFactorType = r.ra_factor_type
                           AND n.planid = r.planid
                           AND n.scc = r.scc
                           AND n.pbp = r.pbp
                WHERE n.ProcessedPriorityProcessedBy
                      BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                      AND n.HCC NOT LIKE 'HIER%'
                      AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%'
                      AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';

                --order by n.hicn,n.Unionqueryind, n.hcc, n.model_year

                IF @Debug = 1
                BEGIN
                    PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                          + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                          + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                    SET @ET = GETDATE();
                    RAISERROR('168', 0, 1) WITH NOWAIT;
                END;

            END;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('169', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #MaxMonthHCCRAFTPBPSCC
            SELECT PaymentYear,
                   ModelYear,
                   PlanID,
                   hicn,
                   onlyHCC,
                   HCCNumber,
                   RAFactorTypeORIG,
                   pbp,
                   scc,
                   MAX(PaymStart),
                   AGED
            FROM etl.IntermediateNewHCCOutput
            GROUP BY PaymentYear,
                     ModelYear,
                     PlanID,
                     hicn,
                     onlyHCC,
                     HCCNumber,
                     RAFactorTypeORIG,
                     pbp,
                     scc,
                     AGED;
            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('170', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #MaxMonthHCC
            SELECT PaymentYear,
                   ModelYear,
                   PlanID,
                   hicn,
                   onlyHCC,
                   HCC_Number,
                   MAX(MaxMemberMonth)
            FROM #MaxMonthHCCRAFTPBPSCC
            GROUP BY PaymentYear,
                     ModelYear,
                     PlanID,
                     hicn,
                     onlyHCC,
                     HCC_Number;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('171', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #FinalUniqueCondition
            SELECT n.PaymentYear,
                   n.ModelYear,
                   n.PlanID,
                   n.hicn,
                   n.onlyHCC,
                   n.HCCNumber,
                   n.RAFactorTypeORIG,
                   n.PBP,
                   n.SCC,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
                INNER JOIN #MaxMonthHCC m
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
                RAISERROR('172', 0, 1) WITH NOWAIT;
            END;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('173', 0, 1) WITH NOWAIT;
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
            FROM #NewHCCFinalDVView n
                JOIN [#ProviderId] u
                    ON n.provider_id = u.Provider_Id;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('173.1', 0, 1) WITH NOWAIT;
            END;

            /*---OUTPUT---*/
            SELECT n.payment_year,
                   n.model_year,
                   n.processed_by_start,
                   n.processed_by_end,
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           'I'
                       WHEN n.Unionqueryind = 2 THEN
                           'M'
                   END processed_by_flag,
                   n.planid,
                   n.hicn,
                   n.ra_factor_type,
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
                   END AS HCC,
                   n.hcc_description,
                   n.HCC_FACTOR,
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
                   END AS HIER_HCC,
                   n.HIER_HCC_FACTOR,
                   n.factor_diff AS Pre_Adjstd_Factor,
                   n.FINAL_FACTOR AS Adjstd_Final_Factor,
                   n.HCC_PROCESSED_PCN,
                   n.HIER_HCC_PROCESSED_PCN,
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
                   END AS UNQ_CONDITIONS,
                   n.months_in_dcp,
                   n.member_months,
                   n.bid AS Bid_Amount,
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
                   -- tfs 66188 - changed AGED to AgedStatus to make ResultSets match
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END
            --, n.AGED
            FROM #NewHCCFinalDVView n
                LEFT JOIN #FinalUniqueCondition m
                    ON n.payment_year = m.PaymentYear
                       AND n.model_year = m.ModelYear
                       AND n.planid = m.PlanID
                       AND n.hicn = m.hicn
                       AND n.onlyHCC = m.onlyHCC
                       AND n.HCC_Number = m.HCC_Number
                       AND n.ra_factor_type = m.ra_factor_type
                       AND n.pbp = m.pbp
                       AND n.scc = m.scc
            ORDER BY n.hicn,
                     n.Unionqueryind,
                     n.model_year,
                     n.ra_factor_type,
                     HCC,
                     n.rollforward_months;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('174', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('175', 0, 1) WITH NOWAIT;
        END;

    END;
    ELSE
    BEGIN
        IF @ReportOutputByMonth = 'S'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('176', 0, 1) WITH NOWAIT;
            END;
            SELECT n.PaymentYear,
                   n.ModelYear,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           'I'
                       WHEN n.Unionqueryind = 2 THEN
                           'M'
                       WHEN n.Unionqueryind = 3 THEN
                           'F'
                   END processed_by_flag,
                   n.planid,
                   n.hicn,
                   n.RAFactorType,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC LIKE 'M-High%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%INT%'
                            AND n.HCC LIKE 'M-High%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%'
                            AND n.HCC LIKE 'M-High%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                       ELSE
                           n.HCC
                   END AS HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld LIKE 'MOR-INCR%' THEN
                           'MOR-' + SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%INT%'
                            AND n.HierHCCOld LIKE 'MOR-INCR%' THEN
                           'MOR-' + SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%'
                            AND n.HierHCCOld LIKE 'MOR-INCR%' THEN
                           'MOR-' + SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                       ELSE
                           n.HierHCCOld
                   END AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FactorDiff AS Pre_Adjstd_Factor,
                   n.FinalFactor AS Adjstd_Final_Factor,
                   ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                   COUNT(DISTINCT n.PaymStart) member_months,
                   ISNULL(n.BID, 0) 'Bid_Amount',
                   ISNULL(SUM(n.EstimatedValue), 0) estimated_value,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                            OR
                            (
                                @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                AND MONTH(r.member_months) < @MaxMonth
                            ) THEN
                           0
                       ELSE -- Ticket # 29157
                           12 - MONTH(r.member_months)
                   END rollforward_months,
                   ISNULL(   SUM(n.EstimatedValue) + (CASE
                                                          WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                                                               OR
                                                               (
                                                                   @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                                                   AND MONTH(r.member_months) < @MaxMonth
                                                               ) THEN
                                                              0
                                                          ELSE -- Ticket # 29157
                                                              12 - MONTH(r.member_months)
                                                      END * (SUM(n.estimatedvalue) / COUNT(DISTINCT n.PaymStart))
                                                     ),
                             0
                         ) annualized_estimated_value,

                   --isnull(n.esrd, 'N') 'esrd', 
                   --isnull(n.hosp , 'N') 'hosp', 
                   n.pbp,
                   ISNULL(n.scc, 'N') 'scc',
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   [populated_date] = @Populated_Date,
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END
            --,n.Condition_Count,
            --n.Condition_Flag_Desc
            FROM etl.IntermediateNewHCCOutput n
                INNER JOIN #RollForward_Months r
                    ON n.hicn = r.hicn
                       AND n.RAFactorType = r.ra_factor_type
                       AND n.planid = r.planid
                       AND n.scc = r.scc
                       AND n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
            GROUP BY n.PaymentYear,
                     n.ModelYear,
                     n.ProcessedByStart,
                     n.ProcessedByEnd,
                     CASE
                         WHEN n.Unionqueryind = 1 THEN
                             'I'
                         WHEN n.Unionqueryind = 2 THEN
                             'M'
                         WHEN n.Unionqueryind = 3 THEN
                             'F'
                     END,
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
                     n.BID,
                     MONTH(r.member_months),
                     n.MonthsInDCP,
                     n.ESRD,
                     n.HOSP,
                     n.pbp,
                     n.scc,
                     CASE
                         WHEN n.Unionqueryind = 1 THEN
                             @initial_flag
                         WHEN n.Unionqueryind = 2 THEN
                             @myu_flag
                         WHEN n.Unionqueryind = 3 THEN
                             @final_flag
                     END,
                     n.AGED
            --,n.Condition_Count,
            --n.Condition_Flag_Desc
            ORDER BY n.hicn,
                     CASE
                         WHEN n.Unionqueryind = 1 THEN
                             'I'
                         WHEN n.Unionqueryind = 2 THEN
                             'M'
                         WHEN n.Unionqueryind = 3 THEN
                             'F'
                     END,
                     n.ModelYear,
                     n.RAFactorType,
                     n.HCC;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('177', 0, 1) WITH NOWAIT;
            END;

        END;
    END; /* added End statement    12/22/2015   DW   */



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('178', 0, 1) WITH NOWAIT;
    END;


    --set @start = getdate() 
    IF (
           @ReportOutputByMonth IN ( 'D', 'V' )
           AND @Payment_Year_NewDeleteHCC <= YEAR(GETDATE())
       ) --TFS 70056
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('179', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('180', 0, 1) WITH NOWAIT;
            END;

            DECLARE @new_hcc_output_HCCLIST TABLE
            (
                [HCC] VARCHAR(50)
            );

            INSERT INTO @new_hcc_output_HCCLIST
            (
                [HCC]
            )
            SELECT DISTINCT
                   n.HCC
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.HCC NOT LIKE 'HIER%';


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('180.1', 0, 1) WITH NOWAIT;
            END;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('180.2', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO [#NewHCCFinalDVView] WITH (TABLOCK)
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
                                              WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                                                   OR
                                                   (
                                                       @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                                       AND MONTH(r.member_months) < @MaxMonth
                                                   ) THEN
                                                  0
                                              ELSE -- Ticket # 29157
                                                  12 - MONTH(r.member_months)
                                          END,
                   [annualized_estimated_value] = ISNULL(
                                                            SUM(n.EstimatedValue)
                                                            + (CASE
                                                                   WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                                                                        OR
                                                                        (
                                                                            @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                                                            AND MONTH(r.member_months) < @MaxMonth
                                                                        ) THEN
                                                                       0
                                                                   ELSE -- Ticket # 29157
                                                                       12 - MONTH(r.member_months)
                                                               END
                                                               * (SUM(n.estimatedvalue) / COUNT(DISTINCT n.PaymStart))
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
            FROM etl.IntermediateNewHCCOutput n --=22,249,844
                JOIN #RollForward_Months r
                    --=215,463
                    ON n.hicn = r.hicn
                       AND n.RAFactorType = r.ra_factor_type
                       AND n.planid = r.planid
                       AND n.scc = r.scc
                       AND n.pbp = r.pbp
                JOIN @new_hcc_output_HCCLIST hl
                    ON n.HCC = hl.HCC
            WHERE n.ProcessedPriorityProcessedBy
            BETWEEN @PROCESSBY_START AND @PROCESSBY_END
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
                     -- , MONTH([r].[member_months])
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

        --order by n.hicn, n.hcc, n.model_year
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('182', 0, 1) WITH NOWAIT;
        END;


        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('183', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalDVView
            (
                payment_year,
                model_year,
                processed_by_start,
                processed_by_end,
                Unionqueryind,
                planid,
                hicn,
                ra_factor_type,
                hcc,
                hcc_description,
                HCC_FACTOR,
                HIER_HCC,
                HIER_HCC_FACTOR,
                FINAL_FACTOR,
                factor_diff,
                HCC_PROCESSED_PCN,
                HIER_HCC_PROCESSED_PCN,
                member_months,
                bid,
                estimated_value,
                rollforward_months,
                annualized_estimated_value,
                months_in_dcp,
                esrd,
                hosp,
                pbp,
                scc,
                processed_priority_processed_by,
                processed_priority_thru_date,
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
                populated_date,
                onlyHCC,
                HCC_Number,
                AGED
            )
            SELECT n.PaymentYear,
                   n.ModelYear,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.Unionqueryind,
                   n.planid,
                   n.hicn,
                   n.RAFactorType,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.HierHCCProcessedPCN,
                   COUNT(DISTINCT n.PaymStart) member_months,
                   ISNULL(n.BID, 0) 'bid',
                   ISNULL(SUM(n.EstimatedValue), 0) estimated_value,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                            OR
                            (
                                @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                AND MONTH(r.member_months) < @MaxMonth
                            ) THEN
                           0
                       ELSE -- Ticket # 29157
                           12 - MONTH(r.member_months)
                   END rollforward_months,
                   ISNULL(   SUM(n.EstimatedValue) + (CASE
                                                          WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                                                               OR
                                                               (
                                                                   @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                                                   AND MONTH(r.member_months) < @MaxMonth
                                                               ) THEN
                                                              0
                                                          ELSE -- Ticket # 29157
                                                              12 - MONTH(r.member_months)
                                                      END * (SUM(n.EstimatedValue) / COUNT(DISTINCT n.PaymStart))
                                                     ),
                             0
                         ) annualized_estimated_value,
                   ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                   ISNULL(n.ESRD, 'N') 'esrd',
                   ISNULL(n.HOSP, 'N') 'hosp',
                   n.pbp,
                   ISNULL(n.scc, 'OOA') 'scc',
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourceID,
                   n.Thru_PriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   [populated_date] = @Populated_Date,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
                INNER JOIN #RollForward_Months r
                    ON n.hicn = r.hicn
                       AND n.RAFactorType = r.ra_factor_type
                       AND n.planid = r.planid
                       AND n.scc = r.scc
                       AND n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%'
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
                     MONTH(r.member_months),
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
                     CASE
                         WHEN n.Unionqueryind = 1 THEN
                             @initial_flag
                         WHEN n.Unionqueryind = 2 THEN
                             @myu_flag
                         WHEN n.Unionqueryind = 3 THEN
                             @final_flag
                     END,
                     n.OnlyHCC,
                     n.HCCNumber,
                     n.AGED;

            --order by n.hicn, n.hcc, n.model_year

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('184', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('185', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalDVView
            (
                payment_year,
                model_year,
                processed_by_start,
                processed_by_end,
                Unionqueryind,
                planid,
                hicn,
                ra_factor_type,
                hcc,
                hcc_description,
                HCC_FACTOR,
                HIER_HCC,
                HIER_HCC_FACTOR,
                FINAL_FACTOR,
                factor_diff,
                HCC_PROCESSED_PCN,
                HIER_HCC_PROCESSED_PCN,
                member_months,
                bid,
                estimated_value,
                rollforward_months,
                annualized_estimated_value,
                months_in_dcp,
                esrd,
                hosp,
                pbp,
                scc,
                processed_priority_processed_by,
                processed_priority_thru_date,
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
                populated_date,
                onlyHCC,
                HCC_Number,
                AGED
            )
            SELECT n.PaymentYear,
                   n.ModelYear,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.Unionqueryind,
                   n.planid,
                   n.hicn,
                   n.RAFactorType,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.HierHCCProcessedPCN,
                   COUNT(DISTINCT n.PaymStart) member_months,
                   ISNULL(n.BID, 0) 'bid',
                   ISNULL(SUM(n.EstimatedValue), 0) estimated_value,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                            OR
                            (
                                @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                AND MONTH(r.member_months) < @MaxMonth
                            ) THEN
                           0
                       ELSE -- Ticket # 29157
                           12 - MONTH(r.member_months)
                   END rollforward_months,
                   ISNULL(   SUM(n.EstimatedValue) + (CASE
                                                          WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                                                               OR
                                                               (
                                                                   @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                                                   AND MONTH(r.member_months) < @MaxMonth
                                                               ) THEN
                                                              0
                                                          ELSE -- Ticket # 29157
                                                              12 - MONTH(r.member_months)
                                                      END * (SUM(n.estimatedvalue) / COUNT(DISTINCT n.PaymStart))
                                                     ),
                             0
                         ) annualized_estimated_value,
                   ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                   ISNULL(n.ESRD, 'N') 'esrd',
                   ISNULL(n.HOSP, 'N') 'hosp',
                   n.pbp,
                   ISNULL(n.scc, 'OOA') 'scc',
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourc_ID,
                   n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDdate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   [populated_date] = @Populated_Date,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
                INNER JOIN #RollForward_Months r
                    ON n.hicn = r.hicn
                       AND n.RAFactorType = r.ra_factor_type
                       AND n.planid = r.planid
                       AND n.scc = r.scc
                       AND n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%'
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
                     MONTH(r.member_months),
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
                     CASE
                         WHEN n.Unionqueryind = 1 THEN
                             @initial_flag
                         WHEN n.Unionqueryind = 2 THEN
                             @myu_flag
                         WHEN n.Unionqueryind = 3 THEN
                             @final_flag
                     END,
                     n.OnlyHCC,
                     n.HCCNumber,
                     n.AGED;

            --order by n.hicn, n.hcc, n.model_year

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('186', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('187', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('188', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalDVView
            SELECT n.PaymentYear,
                   n.ModelYear,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.Unionqueryind,
                   n.planid,
                   n.hicn,
                   n.RAFactorType,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.HierHCCProcessedPCN,
                   COUNT(DISTINCT n.PaymStart) member_months,
                   ISNULL(n.BID, 0) 'bid',
                   ISNULL(SUM(n.EstimatedValue), 0) estimated_value,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                            OR
                            (
                                @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                AND MONTH(r.member_months) < @MaxMonth
                            ) THEN
                           0
                       ELSE -- Ticket # 29157
                           12 - MONTH(r.member_months)
                   END rollforward_months,
                   ISNULL(   SUM(n.EstimatedValue) + (CASE
                                                          WHEN @Payment_Year_NewDeleteHCC < YEAR(GETDATE())
                                                               OR
                                                               (
                                                                   @Payment_Year_NewDeleteHCC >= YEAR(GETDATE())
                                                                   AND MONTH(r.member_months) < @MaxMonth
                                                               ) THEN
                                                              0
                                                          ELSE -- Ticket # 29157
                                                              12 - MONTH(r.member_months)
                                                      END * (SUM(n.EstimatedValue) / COUNT(DISTINCT n.PaymStart))
                                                     ),
                             0
                         ) annualized_estimated_value,
                   ISNULL(n.MonthsInDCP, 0) 'months_in_dcp',
                   ISNULL(n.ESRD, 'N') 'esrd',
                   ISNULL(n.HOSP, 'N') 'hosp',
                   n.pbp,
                   ISNULL(n.scc, 'OOA') 'scc',
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourceID,
                   n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCNn AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   [populated_date] = @Populated_Date,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
                INNER JOIN #RollForward_Months r
                    ON n.hicn = r.hicn
                       AND n.RAFactorType = r.ra_factor_type
                       AND n.planid = r.planid
                       AND n.scc = r.scc
                       AND n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%'
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
                     MONTH(r.MemberMonths),
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
                     CASE
                         WHEN n.Unionqueryind = 1 THEN
                             @initial_flag
                         WHEN n.Unionqueryind = 2 THEN
                             @myu_flag
                         WHEN n.Unionqueryind = 3 THEN
                             @final_flag
                     END,
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
                RAISERROR('189', 0, 1) WITH NOWAIT;
            END;

        --order by n.hicn, n.hcc, n.model_year
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('189.1', 0, 1) WITH NOWAIT;
        END;

        IF @Debug = 0
        BEGIN
            IF (OBJECT_ID('tempdb.dbo.#RollForward_Months') IS NOT NULL)
            BEGIN
                DROP TABLE #RollForward_Months;
            END;
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('190', 0, 1) WITH NOWAIT;
        END;

        IF @Payment_Year_NewDeleteHCC = 2015
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('191', 0, 1) WITH NOWAIT;
            END;

            UPDATE etl.IntermediateNewHCCOutput
            SET ModelYear = 2014
            WHERE ModelYear = 2015;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('192', 0, 1) WITH NOWAIT;
            END;

            UPDATE #NewHCCFinalDVView
            SET model_year = 2014
            WHERE model_year = 2015;
        END;
        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('193', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCCRAFTPBPSCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCCNumber,
               RAFactorType,
               pbp,
               scc,
               MAX(PaymStart),
               AGED
        FROM etl.IntermediateNewHCCOutput
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCCNumber,
                 RAFactorType,
                 pbp,
                 scc,
                 AGED;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('194', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCC_Number,
               MAX(MaxMemberMonth)
        FROM #MaxMonthHCCRAFTPBPSCC
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCC_Number;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('195', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #FinalUniqueCondition
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
        FROM etl.IntermediateNewHCCOutput n
            INNER JOIN #MaxMonthHCC m
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
            RAISERROR('196', 0, 1) WITH NOWAIT;
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
        FROM #NewHCCFinalDVView n
            JOIN [#ProviderId] u
                ON n.provider_id = u.Provider_Id;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('196.1', 0, 1) WITH NOWAIT;
        END;

        IF (@ReportOutputByMonth = 'V')
           AND (OBJECT_ID(N'[Valuation].[NewHCCPartC]', N'U') IS NOT NULL)
        BEGIN
            DELETE m
            FROM Valuation.NewHCCPartC m
                INNER JOIN #PlanIdentifier p
                    ON m.PlanId = p.PlanID
            WHERE m.ProcessRunId = @ProcessRunId;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('196.2', 0, 1) WITH NOWAIT;
            END;


            /*---OUTPUT--- For V */

            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
            BEGIN

                INSERT INTO Valuation.NewHCCPartC
                (
                    [ProcessRunId],
                    [Payment_Year],
                    --   , [PaymStart]
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
                    [AgedStatus]
                )
                SELECT [ProcessRunId] = @ProcessRunId,
                       [Payment_Year] = n.payment_year,
                       -- , [PaymStart] = '1/1/' + @Payment_Year_NewDeleteHCC
                       n.processed_by_start,
                       n.processed_by_end,
                       n.planid,
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
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%INT%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%D-HCC%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
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
                       [model_year] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC = 2015
                                               AND n.ra_factor_type NOT IN ( 'C', 'I', 'CF', 'CN', 'CP' )
                                               AND n.model_year = 2014 THEN
                                              2015
                                          ELSE
                                              n.model_year
                                      END,
                       [AgedStatus] = CASE
                                          WHEN n.AGED = 1 THEN
                                              'Aged'
                                          WHEN n.AGED = 0 THEN
                                              'Disabled'
                                          ELSE
                                              'Not Applicable'
                                      END
                FROM #NewHCCFinalDVView n
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
                           AND n.scc = m.scc;


            END;
            ELSE
            BEGIN
                INSERT INTO Valuation.NewHCCPartC
                (
                    [ProcessRunId],
                    [Payment_Year],
                    --   , [PaymStart]
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
                    [AgedStatus]
                )
                SELECT [ProcessRunId] = @ProcessRunId,
                       [Payment_Year] = n.payment_year,
                       -- , [PaymStart] = '1/1/' + @Payment_Year_NewDeleteHCC
                       n.processed_by_start,
                       n.processed_by_end,
                       n.planid,
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
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%INT%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%D-HCC%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
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
                       [model_year] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC = 2015
                                               AND n.ra_factor_type NOT IN ( 'C', 'I' )
                                               AND n.model_year = 2014 THEN
                                              2015
                                          ELSE
                                              n.model_year
                                      END,
                       [AgedStatus] = CASE
                                          WHEN n.AGED = 1 THEN
                                              'Aged'
                                          WHEN n.AGED = 0 THEN
                                              'Disabled'
                                          ELSE
                                              'Not Applicable'
                                      END
                FROM #NewHCCFinalDVView n
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
                           AND n.scc = m.scc;


            END;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('197', 0, 1) WITH NOWAIT;
            END;
        END;



        IF (@ReportOutputByMonth = 'V')
           AND (OBJECT_ID(N'[Valuation].[NewHCCPartC]', N'U') IS NULL)
        BEGIN

            /*---OUTPUT--- For V */


            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
            BEGIN
                SELECT [ProcessRunId] = @ProcessRunId,
                       [Payment_Year] = n.payment_year,
                       -- , [PaymStart] = '1/1/' + @Payment_Year_NewDeleteHCC
                       n.processed_by_start,
                       n.processed_by_end,
                       n.planid,
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
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%INT%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%D-HCC%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
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
                       [model_year] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC = 2015
                                               AND n.ra_factor_type NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ) -- TFS 59836
                                               AND n.model_year = 2014 THEN
                                              2015
                                          ELSE
                                              n.model_year
                                      END,
                       [AgedStatus] = CASE
                                          WHEN n.AGED = 1 THEN
                                              'Aged'
                                          WHEN n.AGED = 0 THEN
                                              'Disabled'
                                          ELSE
                                              'Not Applicable'
                                      END
                FROM #NewHCCFinalDVView n
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
                           AND n.scc = m.scc;



            END;
            ELSE
            BEGIN
                SELECT [ProcessRunId] = @ProcessRunId,
                       [Payment_Year] = n.payment_year,
                       -- , [PaymStart] = '1/1/' + @Payment_Year_NewDeleteHCC
                       n.processed_by_start,
                       n.processed_by_end,
                       n.planid,
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
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%INT%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%D-HCC%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
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
                       [model_year] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC = 2015
                                               AND n.ra_factor_type NOT IN ( 'C', 'I' ) -- TFS 59836
                                               AND n.model_year = 2014 THEN
                                              2015
                                          ELSE
                                              n.model_year
                                      END,
                       [AgedStatus] = CASE
                                          WHEN n.AGED = 1 THEN
                                              'Aged'
                                          WHEN n.AGED = 0 THEN
                                              'Disabled'
                                          ELSE
                                              'Not Applicable'
                                      END
                FROM #NewHCCFinalDVView n
                    LEFT JOIN #FinalUniqueCondition m
                        ON n.payment_year = m.PaymentYear
                           AND n.model_year = m.ModelYear
                           AND n.planid = m.PlanID
                           AND n.AGED = m.AGED
                           AND n.hicn = m.hicn
                           AND n.onlyHCC = m.onlyHCC
                           AND n.HCC_Number = m.HCC_Number
                           AND n.ra_factor_type = m.ra_factor_type
                           AND n.pbp = m.pbp
                           AND n.scc = m.scc;


            END;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('197.1', 0, 1) WITH NOWAIT;
            END;
        /*removed end statement 12-22-2015   */



        END;

        IF @ReportOutputByMonth = 'D'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('197.2', 0, 1) WITH NOWAIT;
            END;
            IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
            BEGIN
                --tfs 66188 - MOVED position of model_year and Processed_By_Flag 
                --				to make result sets for ReportOutputByMonth = 'D' the same for all 
                --				values of @Payment_Year_NewDeleteHCC

                SELECT [Payment_Year] = n.payment_year,
                       [model_year] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC = 2015
                                               AND n.ra_factor_type NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ) -- TFS 59836
                                               AND n.model_year = 2014 THEN
                                              2015
                                          ELSE
                                              n.model_year
                                      END,
                       n.processed_by_start,
                       n.processed_by_end,
                       [Processed_By_Flag] = CASE
                                                 WHEN n.Unionqueryind = 1 THEN
                                                     'I'
                                                 WHEN n.Unionqueryind = 2 THEN
                                                     'M'
                                                 WHEN n.Unionqueryind = 3 THEN
                                                     'F'
                                             END,
                       n.planid,
                       n.hicn,
                       n.ra_factor_type,
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
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%INT%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%D-HCC%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
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
                       [AgedStatus] = CASE
                                          WHEN n.AGED = 1 THEN
                                              'Aged'
                                          WHEN n.AGED = 0 THEN
                                              'Disabled'
                                          ELSE
                                              'Not Applicable'
                                      END
                FROM #NewHCCFinalDVView n
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
                           AND n.scc = m.scc;



            END;
            ELSE
            BEGIN
                --tfs 66188 - MOVED position of model_year and Processed_By_Flag 
                --				to make result sets for ReportOutputByMonth = 'D' the same for all 
                --				values of @Payment_Year_NewDeleteHCC


                SELECT [Payment_Year] = n.payment_year,
                       [model_year] = CASE
                                          WHEN @Payment_Year_NewDeleteHCC = 2015
                                               AND n.ra_factor_type NOT IN ( 'C', 'I' ) -- TFS 59836
                                               AND n.model_year = 2014 THEN
                                              2015
                                          ELSE
                                              n.model_year
                                      END,
                       n.processed_by_start,
                       n.processed_by_end,
                       [Processed_By_Flag] = CASE
                                                 WHEN n.Unionqueryind = 1 THEN
                                                     'I'
                                                 WHEN n.Unionqueryind = 2 THEN
                                                     'M'
                                                 WHEN n.Unionqueryind = 3 THEN
                                                     'F'
                                             END,
                       n.planid,
                       n.hicn,
                       n.ra_factor_type,
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
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('HCC', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%INT%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('INT', n.HIER_HCC), LEN(n.HIER_HCC))
                                        WHEN n.HIER_HCC LIKE '%D-HCC%'
                                             AND n.HIER_HCC LIKE 'MOR-INCR%' THEN
                                            'MOR-'
                                            + SUBSTRING(n.HIER_HCC, CHARINDEX('D-HCC', n.HIER_HCC), LEN(n.HIER_HCC))
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
                       [AgedStatus] = CASE
                                          WHEN n.AGED = 1 THEN
                                              'Aged'
                                          WHEN n.AGED = 0 THEN
                                              'Disabled'
                                          ELSE
                                              'Not Applicable'
                                      END
                FROM #NewHCCFinalDVView n
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
                           AND n.scc = m.scc;


            END;
            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('197.2', 0, 1) WITH NOWAIT;
            END;
        END;



        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('198', 0, 1) WITH NOWAIT;
        END;

    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('199', 0, 1) WITH NOWAIT;
    END;

    IF @ReportOutputByMonth = 'M'
       AND YEAR(GETDATE()) >= @Payment_Year_NewDeleteHCC
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('200', 0, 1) WITH NOWAIT;
        END;

        IF OBJECT_ID('TEMPDB..#NewHCCFinalMView', 'U') IS NOT NULL
            DROP TABLE #NewHCCFinalMView;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('201', 0, 1) WITH NOWAIT;
        END;

        CREATE TABLE #NewHCCFinalMView
        (
            payment_year INT,
            model_year INT,
            PAYMSTART DATETIME,
            processed_by_start DATETIME,
            processed_by_end DATETIME,
            planid VARCHAR(5),
            hicn VARCHAR(15),
            ra_factor_type VARCHAR(2),
            processed_priority_processed_by DATETIME,
            processed_priority_thru_date DATETIME,
            HCC_PROCESSED_PCN VARCHAR(50),
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
            hcc VARCHAR(50),
            hcc_description VARCHAR(255),
            HCC_FACTOR DECIMAL(20, 4),
            HIER_HCC VARCHAR(20),
            HIER_HCC_FACTOR DECIMAL(20, 4),
            FINAL_FACTOR DECIMAL(20, 4),
            factor_diff DECIMAL(20, 4),
            HIER_HCC_PROCESSED_PCN VARCHAR(50),
            active_indicator_for_rollforward CHAR(1),
            months_in_dcp INT,
            esrd VARCHAR(1),
            hosp VARCHAR(1),
            pbp VARCHAR(3),
            scc VARCHAR(5),
            bid MONEY,
            estimated_value MONEY,
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
            onlyHCC VARCHAR(20),
            HCC_Number INT,
            AGED INT
        );

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('202', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('203', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalMView
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourceID,
                   n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) AS 'ESTIMATED_VALUE',
                   -- Ticket # 26951
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%';
            --order by n.hicn, hcc, paymstart

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('204', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('205', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('206', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalMView
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourceID,
                   n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) AS 'ESTIMATED_VALUE',
                   -- Ticket # 26951
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%';
            --order by n.hicn, model_year,hcc, paymstart

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('207', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('208', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('209', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalMView
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourceID,
                   n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) AS 'ESTIMATED_VALUE',
                   -- Ticket # 26951
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';
            --order by n.hicn, hcc, paymstart

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('210', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('211', 0, 1) WITH NOWAIT;
        END;


        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('212', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalMView
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN AS HCC_PROCESSED_PCN,
                   n.ProcessedPriorityDiag,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ProcessedPriorityRAPSSourceID,
                   n.ThruPriorityProcessedBy AS DOS_PRIORITY_PROCESSED_BY,
                   n.ThruPriorityThruDate AS DOS_PRIORITY_THRU_DATE,
                   n.ThruPriorityPCN AS DOS_PRIORITY_PCN,
                   n.ThruPriorityDiag AS DOS_PRIORITY_DIAG,
                   n.ThruPriorityFileID AS DOS_PRIORITY_FILEID,
                   n.ThruPriorityRAC AS DOS_PRIORITY_RAC,
                   n.ThruPriorityRAPSSourceID AS DOS_PRIORITY_RAPS_SOURCE,
                   n.HCC,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'HCC_FACTOR',
                   n.HierHCCOld AS HIER_HCC,
                   ISNULL(n.HierFactorOld, 0) 'HIER_HCC_FACTOR',
                   n.FinalFactor AS FINAL_FACTOR,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) AS 'ESTIMATED_VALUE',
                   -- Ticket # 26951
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.OnlyHCC,
                   n.HCCNumber,
                   n.AGED
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';
            --order by n.hicn, hcc, paymstart

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('213', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('214', 0, 1) WITH NOWAIT;
        END;

        IF @Payment_Year_NewDeleteHCC = 2015
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('215', 0, 1) WITH NOWAIT;
            END;

            UPDATE etl.IntermediateNewHCCOutput
            SET ModelYear = 2014
            WHERE ModelYear = 2015;

            UPDATE #NewHCCFinalDVView
            SET model_year = 2014
            WHERE model_year = 2015;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('216', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('217', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCCRAFTPBPSCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCCNumber,
               RAFactorType,
               pbp,
               scc,
               MAX(PaymStart),
               AGED
        FROM etl.IntermediateNewHCCOutput
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCCNumber,
                 RAFactorType,
                 pbp,
                 scc,
                 AGED;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('218', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCC_Number,
               MAX(MaxMemberMonth)
        FROM #MaxMonthHCCRAFTPBPSCC
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCC_Number;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('219', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #FinalUniqueCondition
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
        FROM etl.IntermediateNewHCCOutput n
            INNER JOIN #MaxMonthHCC m
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
            RAISERROR('220', 0, 1) WITH NOWAIT;
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
        FROM #NewHCCFinalMView n
            JOIN [#ProviderId] u
                ON n.provider_id = u.Provider_Id;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('220.1', 0, 1) WITH NOWAIT;
        END;

        /*---OUTPUT--- For M*/

        IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
        BEGIN
            SELECT DISTINCT
                   n.payment_year,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC = 2015
                            AND n.ra_factor_type NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ) -- TFS 59836
                            AND n.model_year = 2014 THEN
                           2015
                       ELSE
                           n.model_year
                   END model_year,
                   n.PAYMSTART,
                   n.processed_by_start,
                   n.processed_by_end,
                   n.planid,
                   n.hicn,
                   n.ra_factor_type,
                   -- Ticket # 26951
                   n.processed_priority_processed_by,
                   n.processed_priority_thru_date,
                   n.HCC_PROCESSED_PCN,
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
                   END AS HCC,
                   n.hcc_description,
                   n.HCC_FACTOR,
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
                   END AS HIER_HCC,
                   n.HIER_HCC_FACTOR,
                   n.factor_diff AS Pre_Adjstd_Factor,
                   n.FINAL_FACTOR AS Adjstd_Final_Factor,
                   n.HIER_HCC_PROCESSED_PCN,
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
                   END AS UNQ_CONDITIONS,
                   n.months_in_dcp,
                   n.active_indicator_for_rollforward,
                   -- Ticket # 29157
                   n.pbp,
                   n.scc,
                   n.bid AS Bid_Amount,
                   n.estimated_value,
                   -- Ticket # 26951
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
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END
            FROM #NewHCCFinalMView n
                LEFT JOIN #FinalUniqueCondition m
                    ON n.payment_year = m.PaymentYear
                       AND n.model_year = m.ModelYear
                       AND n.planid = m.PlanID
                       AND n.AGED = m.AGED
                       AND n.hicn = m.hicn
                       AND n.onlyHCC = m.onlyHCC
                       AND n.HCC_Number = m.HCC_Number
                       AND n.ra_factor_type = m.ra_factor_type
                       AND n.pbp = m.pbp
                       AND n.scc = m.scc
            ORDER BY n.hicn,
                     model_year,
                     n.PAYMSTART,
                     n.ra_factor_type,
                     HCC;



        END;
        ELSE
        BEGIN
            SELECT DISTINCT
                   n.payment_year,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC = 2015
                            AND n.ra_factor_type NOT IN ( 'C', 'I' ) -- TFS 59836
                            AND n.model_year = 2014 THEN
                           2015
                       ELSE
                           n.model_year
                   END model_year,
                   n.PAYMSTART,
                   n.processed_by_start,
                   n.processed_by_end,
                   n.planid,
                   n.hicn,
                   n.ra_factor_type,
                   -- Ticket # 26951
                   n.processed_priority_processed_by,
                   n.processed_priority_thru_date,
                   n.HCC_PROCESSED_PCN,
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
                   END AS HCC,
                   n.hcc_description,
                   n.HCC_FACTOR,
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
                   END AS HIER_HCC,
                   n.HIER_HCC_FACTOR,
                   n.factor_diff AS Pre_Adjstd_Factor,
                   n.FINAL_FACTOR AS Adjstd_Final_Factor,
                   n.HIER_HCC_PROCESSED_PCN,
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
                   END AS UNQ_CONDITIONS,
                   n.months_in_dcp,
                   n.active_indicator_for_rollforward,
                   -- Ticket # 29157
                   n.pbp,
                   n.scc,
                   n.bid AS Bid_Amount,
                   n.estimated_value,
                   -- Ticket # 26951
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
                   [AgedStatus] = CASE
                                      WHEN n.AGED = 1 THEN
                                          'Aged'
                                      WHEN n.AGED = 0 THEN
                                          'Disabled'
                                      ELSE
                                          'Not Applicable'
                                  END
            FROM #NewHCCFinalMView n
                LEFT JOIN #FinalUniqueCondition m
                    ON n.payment_year = m.PaymentYear
                       AND n.model_year = m.ModelYear
                       AND n.planid = m.PlanID
                       AND n.AGED = m.AGED
                       AND n.hicn = m.hicn
                       AND n.onlyHCC = m.onlyHCC
                       AND n.HCC_Number = m.HCC_Number
                       AND n.ra_factor_type = m.ra_factor_type
                       AND n.pbp = m.pbp
                       AND n.scc = m.scc
            ORDER BY n.hicn,
                     model_year,
                     n.PAYMSTART,
                     n.ra_factor_type,
                     HCC;


        END;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('221', 0, 1) WITH NOWAIT;
        END;


    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('222', 0, 1) WITH NOWAIT;
    END;

    IF @ReportOutputByMonth = 'M'
       AND YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
    BEGIN
        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('223', 0, 1) WITH NOWAIT;
        END;

        SELECT [Message] = 'PMPM view is not valid for Initial Projection';

    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('224', 0, 1) WITH NOWAIT;
    END;

    -- #23088 Begin
    IF @ReportOutputByMonth = 'T'
       AND YEAR(GETDATE()) >= @Payment_Year_NewDeleteHCC
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('225', 0, 1) WITH NOWAIT;
        END;


        --TRUNCATE TABLE rev.EstRecHCCNewOutput;  -- Ticket # 26249
        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('226', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) 'HIER_FACTOR_OLD',
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) 'ESTIMATED_VALUE',
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
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
                RAISERROR('227', 0, 1) WITH NOWAIT;
            END;

        --order by n.hicn, hcc, paymstart
        END;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('228', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('229', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971 
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierHCCOld, 0) 'HIER_FACTOR_OLD',
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) 'ESTIMATED_VALUE',
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%';

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('230', 0, 1) WITH NOWAIT;
            END;

        --order by n.hicn, hcc, paymstart
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('231', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('232', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) 'HIER_FACTOR_OLD',
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) 'ESTIMATED_VALUE',
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('233', 0, 1) WITH NOWAIT;
            END;

        --order by n.hicn, hcc, paymstart
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('234', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('235', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   n.PaymStart,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971 
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) 'HIER_FACTOR_OLD',
                   ISNULL(n.ActiveIndicatorForRollforward, 'N') 'active_indicator_for_rollforward',
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) 'ESTIMATED_VALUE',
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';
            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('236', 0, 1) WITH NOWAIT;
            END;

        --order by n.hicn, hcc, paymstart
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('237', 0, 1) WITH NOWAIT;
        END;

        IF @Payment_Year_NewDeleteHCC = 2015
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('238', 0, 1) WITH NOWAIT;
            END;

            UPDATE etl.IntermediateNewHCCOutput
            SET ModelYear = 2014
            WHERE ModelYear = 2015;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('239', 0, 1) WITH NOWAIT;
            END;
            /*??? Why???*/
            UPDATE #NewHCCFinalDVView
            SET model_year = 2014
            WHERE model_year = 2015;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('240', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCCRAFTPBPSCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCCNumber,
               RAFactorType,
               pbp,
               scc,
               MAX(PaymStart)
        FROM etl.IntermediateNewHCCOutput
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCCNumber,
                 RAFactorType,
                 pbp,
                 scc;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('241', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCC_Number,
               MAX(MaxMemberMonth)
        FROM #MaxMonthHCCRAFTPBPSCC
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCC_Number;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('242', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #FinalUniqueCondition
        SELECT n.PaymentYear,
               n.ModelYear,
               n.PlanID,
               n.hicn,
               n.onlyHCC,
               n.HCCNumber,
               n.RAFactorType,
               n.PBP,
               n.SCC
        FROM etl.IntermediateNewHCCOutput n
            INNER JOIN #MaxMonthHCC m
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
            RAISERROR('243', 0, 1) WITH NOWAIT;
        END;

        UPDATE n
        SET n.PROVIDER_LAST = u.Last_Name,
            n.PROVIDER_FIRST = u.First_Name,
            n.PROVIDER_GROUP = u.Group_Name,
            n.PROVIDER_ADDRESS = u.Contact_Address,
            n.PROVIDER_CITY = u.Contact_City,
            n.PROVIDER_STATE = u.Contact_State,
            n.PROVIDER_ZIP = u.Contact_Zip,
            n.PROVIDER_PHONE = u.Work_Phone,
            n.PROVIDER_FAX = u.Work_Fax,
            n.TAX_ID = u.Assoc_Name,
            n.NPI = u.NPI
        FROM #NewHCCFinalTView n
            JOIN [#ProviderId] u
                ON n.PROVIDER_ID = u.Provider_Id;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('243.1', 0, 1) WITH NOWAIT;
        END;

        /*---OUTPUT---*/

        IF (CAST(@Payment_Year_NewDeleteHCC AS INT) > 2016)
        BEGIN
            INSERT INTO rev.EstRecHCCNewOutput
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                Pre_Adjstd_Factor,
                Adjstd_Final_Factor,
                HIER_HCC_PROCESSED_PCN,
                UNQ_CONDITIONS,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE
            )
            SELECT DISTINCT
                   n.payment_year,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC = 2015
                            AND n.RA_FACTOR_TYPE NOT IN ( 'C', 'I', 'CF', 'CP', 'CN' ) -- TFS 59836
                            AND n.MODEL_YEAR = 2014 THEN
                           2015
                       ELSE
                           n.MODEL_YEAR
                   END model_year,
                   n.PAYMSTART,
                   n.PROCESSED_BY_START,
                   n.PROCESSED_BY_END,
                   n.PLANID,
                   n.HICN,
                   n.RA_FACTOR_TYPE,
                   -- Ticket # 26951
                   n.PROCESSED_PRIORITY_PROCESSED_BY,
                   n.PROCESSED_PRIORITY_THRU_DATE,
                   n.PROCESSED_PRIORITY_PCN,
                   n.PROCESSED_PRIORITY_DIAG,
                   n.THRU_PRIORITY_PROCESSED_BY,
                   n.THRU_PRIORITY_THRU_DATE,
                   n.THRU_PRIORITY_PCN,
                   n.THRU_PRIORITY_DIAG,
                   n.HCC,
                   n.HCC_DESCRIPTION,
                   n.FACTOR,
                   n.HIER_HCC_OLD,
                   n.HIER_FACTOR_OLD,
                   n.ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                   -- Ticket # 29157
                   n.MONTHS_IN_DCP,
                   n.ESRD,
                   n.HOSP,
                   n.PBP,
                   n.SCC,
                   n.BID,
                   n.ESTIMATED_VALUE,
                   -- Ticket # 26951
                   n.RAPS_SOURCE,
                   n.PROVIDER_ID,
                   n.PROVIDER_LAST,
                   n.PROVIDER_FIRST,
                   n.PROVIDER_GROUP,
                   n.PROVIDER_ADDRESS,
                   n.PROVIDER_CITY,
                   n.PROVIDER_STATE,
                   n.PROVIDER_ZIP,
                   n.PROVIDER_PHONE,
                   n.PROVIDER_FAX,
                   n.TAX_ID,
                   n.NPI,
                   n.SWEEP_DATE,
                   n.factor_diff,
                   n.FINAL_FACTOR,
                   n.HIER_HCC_PROCESSED_PCN,
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
                            OR n.HCC LIKE 'INCR%' THEN
                           0
                       ELSE
                           1
                   END AS UNQ_CONDITIONS,
                   n.Processed_Priority_FileID,
                   n.Processed_Priority_RAC,
                   n.DOS_PRIORITY_FILEID,
                   n.DOS_PRIORITY_RAC,
                   n.DOS_PRIORITY_RAPS_SOURCE
            FROM #NewHCCFinalTView n
                LEFT JOIN #FinalUniqueCondition m
                    ON n.payment_year = m.PaymentYear
                       AND n.MODEL_YEAR = m.ModelYear
                       AND n.PLANID = m.PlanID
                       AND n.HICN = m.hicn
                       AND n.onlyHCC = m.onlyHCC
                       AND n.HCC_Number = m.HCC_Number
                       AND n.RA_FACTOR_TYPE = m.ra_factor_type
                       AND n.PBP = m.pbp
                       AND n.SCC = m.scc;
        ----ORDER BY
        ----    n.HICN
        ----  , MODEL_YEAR
        ----  , n.RA_FACTOR_TYPE
        ----  , HCC;


        END;
        ELSE
        BEGIN
            INSERT INTO rev.EstRecHCCNewOutput
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                Pre_Adjstd_Factor,
                Adjstd_Final_Factor,
                HIER_HCC_PROCESSED_PCN,
                UNQ_CONDITIONS,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE
            )
            SELECT DISTINCT
                   n.payment_year,
                   CASE
                       WHEN @Payment_Year_NewDeleteHCC = 2015
                            AND n.RA_FACTOR_TYPE NOT IN ( 'C', 'I' ) -- TFS 59836
                            AND n.MODEL_YEAR = 2014 THEN
                           2015
                       ELSE
                           n.MODEL_YEAR
                   END model_year,
                   n.PAYMSTART,
                   n.PROCESSED_BY_START,
                   n.PROCESSED_BY_END,
                   n.PLANID,
                   n.HICN,
                   n.RA_FACTOR_TYPE,
                   -- Ticket # 26951
                   n.PROCESSED_PRIORITY_PROCESSED_BY,
                   n.PROCESSED_PRIORITY_THRU_DATE,
                   n.PROCESSED_PRIORITY_PCN,
                   n.PROCESSED_PRIORITY_DIAG,
                   n.THRU_PRIORITY_PROCESSED_BY,
                   n.THRU_PRIORITY_THRU_DATE,
                   n.THRU_PRIORITY_PCN,
                   n.THRU_PRIORITY_DIAG,
                   n.HCC,
                   n.HCC_DESCRIPTION,
                   n.FACTOR,
                   n.HIER_HCC_OLD,
                   n.HIER_FACTOR_OLD,
                   n.ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                   -- Ticket # 29157
                   n.MONTHS_IN_DCP,
                   n.ESRD,
                   n.HOSP,
                   n.PBP,
                   n.SCC,
                   n.BID,
                   n.ESTIMATED_VALUE,
                   -- Ticket # 26951
                   n.RAPS_SOURCE,
                   n.PROVIDER_ID,
                   n.PROVIDER_LAST,
                   n.PROVIDER_FIRST,
                   n.PROVIDER_GROUP,
                   n.PROVIDER_ADDRESS,
                   n.PROVIDER_CITY,
                   n.PROVIDER_STATE,
                   n.PROVIDER_ZIP,
                   n.PROVIDER_PHONE,
                   n.PROVIDER_FAX,
                   n.TAX_ID,
                   n.NPI,
                   n.SWEEP_DATE,
                   n.factor_diff,
                   n.FINAL_FACTOR,
                   n.HIER_HCC_PROCESSED_PCN,
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
                            OR n.HCC LIKE 'INCR%' THEN
                           0
                       ELSE
                           1
                   END AS UNQ_CONDITIONS,
                   n.Processed_Priority_FileID,
                   n.Processed_Priority_RAC,
                   n.DOS_PRIORITY_FILEID,
                   n.DOS_PRIORITY_RAC,
                   n.DOS_PRIORITY_RAPS_SOURCE
            FROM #NewHCCFinalTView n
                LEFT JOIN #FinalUniqueCondition m
                    ON n.payment_year = m.PaymentYear
                       AND n.MODEL_YEAR = m.ModelYear
                       AND n.PLANID = m.PlanID
                       AND n.HICN = m.hicn
                       AND n.onlyHCC = m.onlyHCC
                       AND n.HCC_Number = m.HCC_Number
                       AND n.RA_FACTOR_TYPE = m.ra_factor_type
                       AND n.PBP = m.pbp
                       AND n.SCC = m.scc;
        ----ORDER BY
        ----    n.HICN
        ----  , MODEL_YEAR
        ----  , n.RA_FACTOR_TYPE
        ----  , HCC;


        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('244', 0, 1) WITH NOWAIT;
        END;


    END;

    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('245', 0, 1) WITH NOWAIT;
    END;

    IF @ReportOutputByMonth = 'T'
       AND YEAR(GETDATE()) < @Payment_Year_NewDeleteHCC
    BEGIN

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('246', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCCRAFTPBPSCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCCNumber,
               RAFactorType,
               pbp,
               scc,
               MAX(PaymStart)
        FROM etl.IntermediateNewHCCOutput
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCCNumber,
                 RAFactorType,
                 pbp,
                 scc;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('247', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #MaxMonthHCC
        SELECT PaymentYear,
               ModelYear,
               PlanID,
               hicn,
               onlyHCC,
               HCC_Number,
               MAX(MaxMemberMonth)
        FROM #MaxMonthHCCRAFTPBPSCC
        GROUP BY PaymentYear,
                 ModelYear,
                 PlanID,
                 hicn,
                 onlyHCC,
                 HCC_Number;


        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('248', 0, 1) WITH NOWAIT;
        END;

        INSERT INTO #FinalUniqueCondition
        SELECT n.PaymentYear,
               n.ModelYear,
               n.PlanID,
               n.hicn,
               n.onlyHCC,
               n.HCCNumber,
               n.RAFactorType,
               n.PBP,
               n.SCC
        FROM etl.IntermediateNewHCCOutput n
            INNER JOIN #MaxMonthHCC m
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
            RAISERROR('249', 0, 1) WITH NOWAIT;
        END;

        --TRUNCATE TABLE rev.EstRecHCCNewOutput;  -- Ticket # 26249
        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('250', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   '1/1/' + @Payment_Year_NewDeleteHCC,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) 'FACTOR',
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) 'HIER_FACTOR_OLD',
                   'Y' AS active_indicator_for_rollforward,
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) 'MONTHS_IN_DCP',
                   ISNULL(n.ESRD, 'N') 'ESRD',
                   ISNULL(n.HOSP, 'N') 'HOSP',
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') 'SCC',
                   ISNULL(n.BID, 0) 'BID',
                   ISNULL(n.EstimatedValue, 0) 'ESTIMATED_VALUE',
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            --inner join #RollForward_Months r on n.hicn = r.hicn and n.ra_factor_type = r.ra_factor_type     -- Ticket # 29157
            --      and n.planid = r.planid and n.scc = r.scc and n.pbp = r.pbp
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
                RAISERROR('251', 0, 1) WITH NOWAIT;
            END;

        --order by n.hicn, hcc
        -- Ticket # 30626 End
        -- Ticket # 30626 Start
        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('252', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL = 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('253', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   '1/1/' + @Payment_Year_NewDeleteHCC,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) AS [FACTOR],
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) AS [HIER_FACTOR_OLD],
                   'Y' AS active_indicator_for_rollforward,
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) AS [MONTHS_IN_DCP],
                   ISNULL(n.ESRD, 'N') AS [ESRD],
                   ISNULL(n.HOSP, 'N') AS [HOSP],
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') AS [SCC],
                   ISNULL(n.BID, 0) AS [BID],
                   ISNULL(n.EstimatedValue, 0) AS [ESTIMATED_VALUE],
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            --inner join #RollForward_Months r on n.hicn = r.hicn and n.ra_factor_type = r.ra_factor_type     -- Ticket # 29157
            --      and n.planid = r.planid and n.scc = r.scc and n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%';
            --and Processed_Priority_FileID like '%' + @File_STRING_ALL + '%'
            --order by n.hicn, hcc
            -- Ticket # 30626 End
            -- Ticket # 30626 Start

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('254', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('255', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL = 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('256', 0, 1) WITH NOWAIT;
            END;
            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   '1/1/' + @Payment_Year_NewDeleteHCC,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) AS [FACTOR],
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) AS [HIER_FACTOR_OLD],
                   'Y' AS active_indicator_for_rollforward,
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) AS [MONTHS_IN_DCP],
                   ISNULL(n.ESRD, 'N') AS [ESRD],
                   ISNULL(n.HOSP, 'N') AS [HOSP],
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') AS [SCC],
                   ISNULL(n.BID, 0) AS [BID],
                   ISNULL(n.EstimatedValue, 0) AS [ESTIMATED_VALUE],
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            --inner join #RollForward_Months r on n.hicn = r.hicn and n.ra_factor_type = r.ra_factor_type     -- Ticket # 29157
            --      and n.planid = r.planid and n.scc = r.scc and n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  --and PROCESSED_PRIORITY_PCN like '%' + @RAPS_STRING_ALL + '%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';
            --order by n.hicn, hcc
            -- Ticket # 30626 End
            -- Ticket # 30626 Start

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('257', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('258', 0, 1) WITH NOWAIT;
        END;

        IF @RAPS_STRING_ALL <> 'ALL'
           AND @File_STRING_ALL <> 'ALL'
        BEGIN

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('259', 0, 1) WITH NOWAIT;
            END;

            INSERT INTO #NewHCCFinalTView
            (
                payment_year,
                MODEL_YEAR,
                PAYMSTART,
                PROCESSED_BY_START,
                PROCESSED_BY_END,
                PLANID,
                HICN,
                RA_FACTOR_TYPE,
                PROCESSED_PRIORITY_PROCESSED_BY,
                PROCESSED_PRIORITY_THRU_DATE,
                PROCESSED_PRIORITY_PCN,
                PROCESSED_PRIORITY_DIAG,
                THRU_PRIORITY_PROCESSED_BY,
                THRU_PRIORITY_THRU_DATE,
                THRU_PRIORITY_PCN,
                THRU_PRIORITY_DIAG,
                HCC,
                HCC_DESCRIPTION,
                FACTOR,
                HIER_HCC_OLD,
                HIER_FACTOR_OLD,
                ACTIVE_INDICATOR_FOR_ROLLFORWARD,
                MONTHS_IN_DCP,
                ESRD,
                HOSP,
                PBP,
                SCC,
                BID,
                ESTIMATED_VALUE,
                RAPS_SOURCE,
                PROVIDER_ID,
                PROVIDER_LAST,
                PROVIDER_FIRST,
                PROVIDER_GROUP,
                PROVIDER_ADDRESS,
                PROVIDER_CITY,
                PROVIDER_STATE,
                PROVIDER_ZIP,
                PROVIDER_PHONE,
                PROVIDER_FAX,
                TAX_ID,
                NPI,
                SWEEP_DATE,
                FINAL_FACTOR,
                factor_diff,
                HIER_HCC_PROCESSED_PCN,
                Processed_Priority_FileID,
                Processed_Priority_RAC,
                DOS_PRIORITY_FILEID,
                DOS_PRIORITY_RAC,
                DOS_PRIORITY_RAPS_SOURCE,
                onlyHCC,
                HCC_Number
            )
            SELECT DISTINCT
                   n.PaymentYear,
                   n.ModelYear,
                   '1/1/' + @Payment_Year_NewDeleteHCC,
                   n.ProcessedByStart,
                   n.ProcessedByEnd,
                   n.PlanID,
                   n.HICN,
                   n.RAFactorType,
                   -- Ticket # 26951
                   n.ProcessedPriorityProcessedBy,
                   n.ProcessedPriorityThruDate,
                   n.ProcessedPriorityPCN,
                   n.ProcessedPriorityDiag,
                   n.ThruPriorityProcessedBy,
                   n.ThruPriorityThruDate,
                   n.ThruPriorityPCN,
                   n.ThruPriorityDiag,
                   CASE
                       WHEN n.HCC LIKE '%HCC%'
                            AND n.HCC NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('HCC', n.HCC), LEN(n.HCC)) -- Ticket # 32971
                       WHEN n.HCC LIKE '%INT%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('INT', n.HCC), LEN(n.HCC))
                       WHEN n.HCC LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HCC, CHARINDEX('D-HCC', n.HCC), LEN(n.HCC))
                   END,
                   n.HCCDescription,
                   ISNULL(n.Factor, 0) AS [FACTOR],
                   CASE
                       WHEN n.HierHCCOld LIKE '%HCC%'
                            AND n.HierHCCOld NOT LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('HCC', n.HierHCCOld), LEN(n.HierHCCOld)) -- Ticket # 32971
                       WHEN n.HierHCCOld LIKE '%INT%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('INT', n.HierHCCOld), LEN(n.HierHCCOld))
                       WHEN n.HierHCCOld LIKE '%D-HCC%' THEN
                           SUBSTRING(n.HierHCCOld, CHARINDEX('D-HCC', n.HierHCCOld), LEN(n.HierHCCOld))
                   END,
                   ISNULL(n.HierFactorOld, 0) AS [HIER_FACTOR_OLD],
                   'Y' AS [active_indicator_for_rollforward],
                   -- Ticket # 29157
                   ISNULL(n.MonthsInDCP, 0) AS [MONTHS_IN_DCP],
                   ISNULL(n.ESRD, 'N') AS [ESRD],
                   ISNULL(n.HOSP, 'N') AS [HOSP],
                   n.PBP,
                   ISNULL(n.SCC, 'OOA') AS [SCC],
                   ISNULL(n.BID, 0) AS [BID],
                   ISNULL(n.EstimatedValue, 0) AS [ESTIMATED_VALUE],
                   -- Ticket # 26951
                   n.ProcessedPriorityRAPSSourceID,
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
                   CASE
                       WHEN n.Unionqueryind = 1 THEN
                           @initial_flag
                       WHEN n.Unionqueryind = 2 THEN
                           @myu_flag
                       WHEN n.Unionqueryind = 3 THEN
                           @final_flag
                   END SWEEP_DATE,
                   n.FinalFactor,
                   n.FactorDiff,
                   n.HierHCCProcessedPCN,
                   n.ProcessedPriorityFileID,
                   n.ProcessedPriorityRAC,
                   n.ThruPriorityFileID,
                   n.ThruPriorityRAC,
                   n.ThruPriorityRAPSSourceID,
                   n.OnlyHCC,
                   n.HCCNumber
            FROM etl.IntermediateNewHCCOutput n
            --inner join #RollForward_Months r on n.hicn = r.hicn and n.ra_factor_type = r.ra_factor_type     -- Ticket # 29157
            --      and n.planid = r.planid and n.scc = r.scc and n.pbp = r.pbp
            WHERE n.ProcessedPriorityProcessedBy
                  BETWEEN @PROCESSBY_START AND @PROCESSBY_END
                  AND n.HCC NOT LIKE 'HIER%'
                  AND n.ProcessedPriorityPCN LIKE '%' + @RAPS_STRING_ALL + '%'
                  AND n.ProcessedPriorityFileID LIKE '%' + @File_STRING_ALL + '%';
            --order by n.hicn, hcc
            -- Ticket # 30626 End
            -- Ticket # 30626 Start

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                      + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('260', 0, 1) WITH NOWAIT;
            END;

        END;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('261', 0, 1) WITH NOWAIT;
        END;

        UPDATE n
        SET n.PROVIDER_LAST = u.Last_Name,
            n.PROVIDER_FIRST = u.First_Name,
            n.PROVIDER_GROUP = u.Group_Name,
            n.PROVIDER_ADDRESS = u.Contact_Address,
            n.PROVIDER_CITY = u.Contact_City,
            n.PROVIDER_STATE = u.Contact_State,
            n.PROVIDER_ZIP = u.Contact_Zip,
            n.PROVIDER_PHONE = u.Work_Phone,
            n.PROVIDER_FAX = u.Work_Fax,
            n.TAX_ID = u.Assoc_Name,
            n.NPI = u.NPI
        FROM #NewHCCFinalTView n
            JOIN [#ProviderId] u
                ON n.PROVIDER_ID = u.Provider_Id;

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('261.2', 0, 1) WITH NOWAIT;
        END;

        /*---OUTPUT--- For T*/

        INSERT INTO rev.EstRecHCCNewOutput
        (
            payment_year,
            MODEL_YEAR,
            PAYMSTART,
            PROCESSED_BY_START,
            PROCESSED_BY_END,
            PLANID,
            HICN,
            RA_FACTOR_TYPE,
            PROCESSED_PRIORITY_PROCESSED_BY,
            PROCESSED_PRIORITY_THRU_DATE,
            PROCESSED_PRIORITY_PCN,
            PROCESSED_PRIORITY_DIAG,
            THRU_PRIORITY_PROCESSED_BY,
            THRU_PRIORITY_THRU_DATE,
            THRU_PRIORITY_PCN,
            THRU_PRIORITY_DIAG,
            HCC,
            HCC_DESCRIPTION,
            FACTOR,
            HIER_HCC_OLD,
            HIER_FACTOR_OLD,
            ACTIVE_INDICATOR_FOR_ROLLFORWARD,
            MONTHS_IN_DCP,
            ESRD,
            HOSP,
            PBP,
            SCC,
            BID,
            ESTIMATED_VALUE,
            RAPS_SOURCE,
            PROVIDER_ID,
            PROVIDER_LAST,
            PROVIDER_FIRST,
            PROVIDER_GROUP,
            PROVIDER_ADDRESS,
            PROVIDER_CITY,
            PROVIDER_STATE,
            PROVIDER_ZIP,
            PROVIDER_PHONE,
            PROVIDER_FAX,
            TAX_ID,
            NPI,
            SWEEP_DATE,
            Pre_Adjstd_Factor,
            Adjstd_Final_Factor,
            HIER_HCC_PROCESSED_PCN,
            UNQ_CONDITIONS,
            Processed_Priority_FileID,
            Processed_Priority_RAC,
            DOS_PRIORITY_FILEID,
            DOS_PRIORITY_RAC,
            DOS_PRIORITY_RAPS_SOURCE
        --,[Condition_Count],
        --[Condition_Flag_Desc]
        )
        SELECT DISTINCT
               n.payment_year,
               n.MODEL_YEAR,
               n.PAYMSTART,
               n.PROCESSED_BY_START,
               n.PROCESSED_BY_END,
               n.PLANID,
               n.HICN,
               n.RA_FACTOR_TYPE,
               -- Ticket # 26951
               n.PROCESSED_PRIORITY_PROCESSED_BY,
               n.PROCESSED_PRIORITY_THRU_DATE,
               n.PROCESSED_PRIORITY_PCN,
               n.PROCESSED_PRIORITY_DIAG,
               n.THRU_PRIORITY_PROCESSED_BY,
               n.THRU_PRIORITY_THRU_DATE,
               n.THRU_PRIORITY_PCN,
               n.THRU_PRIORITY_DIAG,
               n.HCC,
               n.HCC_DESCRIPTION,
               n.FACTOR,
               n.HIER_HCC_OLD,
               n.HIER_FACTOR_OLD,
               n.ACTIVE_INDICATOR_FOR_ROLLFORWARD,
               -- Ticket # 29157
               n.MONTHS_IN_DCP,
               n.ESRD,
               n.HOSP,
               n.PBP,
               n.SCC,
               n.BID,
               n.ESTIMATED_VALUE,
               -- Ticket # 26951
               n.RAPS_SOURCE,
               n.PROVIDER_ID,
               n.PROVIDER_LAST,
               n.PROVIDER_FIRST,
               n.PROVIDER_GROUP,
               n.PROVIDER_ADDRESS,
               n.PROVIDER_CITY,
               n.PROVIDER_STATE,
               n.PROVIDER_ZIP,
               n.PROVIDER_PHONE,
               n.PROVIDER_FAX,
               n.TAX_ID,
               n.NPI,
               n.SWEEP_DATE,
               n.factor_diff,
               n.FINAL_FACTOR,
               n.HIER_HCC_PROCESSED_PCN,
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
                        OR n.HCC LIKE 'INCR%' THEN
                       0
                   ELSE
                       1
               END AS UNQ_CONDITIONS,
               n.Processed_Priority_FileID,
               n.Processed_Priority_RAC,
               n.DOS_PRIORITY_FILEID,
               n.DOS_PRIORITY_RAC,
               n.DOS_PRIORITY_RAPS_SOURCE
        FROM #NewHCCFinalTView n
            LEFT JOIN #FinalUniqueCondition m
                ON n.payment_year = m.PaymentYear
                   AND n.MODEL_YEAR = m.ModelYear
                   AND n.PLANID = m.PlanID
                   AND n.HICN = m.hicn
                   AND n.onlyHCC = m.onlyHCC
                   AND n.HCC_Number = m.HCC_Number
                   AND n.RA_FACTOR_TYPE = m.ra_factor_type
                   AND n.PBP = m.pbp
                   AND n.SCC = m.scc;
        ----ORDER BY
        ----    n.HICN
        ----  , MODEL_YEAR
        ----  , n.RA_FACTOR_TYPE
        ----  , HCC;



        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
                  + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('262', 0, 1) WITH NOWAIT;
        END;


    END;

    IF @Debug = 0
    BEGIN
        IF (OBJECT_ID('tempdb.dbo.#FinalUniqueCondition') IS NOT NULL)
        BEGIN
            DROP TABLE #FinalUniqueCondition;
        END;

        IF (OBJECT_ID('tempdb.dbo.#NewHCCFinalTView') IS NOT NULL)
        BEGIN
            DROP TABLE #NewHCCFinalTView;
        END;
        IF (OBJECT_ID('tempdb.dbo.#ProviderId') IS NOT NULL)
        BEGIN
            DROP TABLE #ProviderId;
        END;

        IF (OBJECT_ID('[etl].[IntermediateNewHCCOutput]') IS NOT NULL)
        BEGIN
            TRUNCATE TABLE etl.IntermediateNewHCCOutput;
        END;

        IF (OBJECT_ID('tempdb.dbo.#MaxMonthHCC') IS NOT NULL)
        BEGIN
            DROP TABLE #MaxMonthHCC;
        END;

        IF (OBJECT_ID('tempdb.dbo.#MaxMonthHCCRAFTPBPSCC') IS NOT NULL)
        BEGIN
            DROP TABLE #MaxMonthHCCRAFTPBPSCC;
        END;

        IF (OBJECT_ID('tempdb.dbo.#NewHCCFinalDVView') IS NOT NULL)
        BEGIN
            DROP TABLE #NewHCCFinalDVView;
        END;

    END;


    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: '
              + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121);
        SET @ET = GETDATE();
        RAISERROR('262.1', 0, 1) WITH NOWAIT;
    END;



    IF @Debug = 1
    BEGIN
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
        RAISERROR('263', 0, 1) WITH NOWAIT;
        PRINT 'Total ET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | '
              + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
        RAISERROR('Done.|', 0, 1) WITH NOWAIT;
    END;

END;

/*B TEMP - TEST tempdb tables */
IF @Debug = 1
BEGIN
    SET STATISTICS IO OFF;
    IF (OBJECT_ID('tempdb.dbo.#TL') IS NOT NULL)
    BEGIN
        DROP TABLE #TL;
    END;

    CREATE TABLE #TL
    (
        [TblName] VARCHAR(128),
        [ROWCOUNT] INT
    );

    DECLARE @SQL VARCHAR(2096);
    DECLARE @TblName VARCHAR(128);
    INSERT INTO #TL
    (
        [TblName]
    )
    SELECT DISTINCT
           t.TABLE_NAME
    FROM tempdb.INFORMATION_SCHEMA.TABLES t WITH (NOLOCK)
    ORDER BY t.TABLE_NAME;

    WHILE
    (SELECT [COUNT] = COUNT(*) FROM #TL WHERE [ROWCOUNT] IS NULL) > 0
    BEGIN

        SELECT TOP 1
               @TblName = [TblName]
        FROM #TL
        WHERE [ROWCOUNT] IS NULL
        ORDER BY [TblName];

        RAISERROR(@TblName, 0, 1) WITH NOWAIT;
        SET @SQL = '
UPDATE m
SET m.[RowCount] = (SELECT  COUNT(*) FROM    [' + @TblName + '] WITH (NOLOCK))
FROM  #TL m
WHERE m.[TblName] = ''' + @TblName + '''';

        EXEC (@SQL);

    END;

    SELECT [TblName],
           [ROWCOUNT]
    FROM #TL
    ORDER BY [TblName];

    IF (OBJECT_ID('tempdb.dbo.#TL') IS NOT NULL)
    BEGIN
        DROP TABLE #TL;
    END;
END;


/*E TEMP - TEST tempdb tables */
GO
