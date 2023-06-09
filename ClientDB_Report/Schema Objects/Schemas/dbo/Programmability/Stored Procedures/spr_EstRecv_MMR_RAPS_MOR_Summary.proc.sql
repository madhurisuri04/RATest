/************************************************************************        
* Name			:	spr_EstRecv_MMR_RAPS_MOR_Summary					*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Balaji Dhanabalan									*
* Date          :	06/12/2013											*	
* Version		:														*
* Description	:	Summarize MMR, RAPS and MOR							*
*
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------  
Balaji Dhanabalan	07/30/2013	2.0			17833			Disease Interactions are duplicating in RAPS Factor table
Balaji Dhanabalan	10/16/2013	3.0			22246			Include previous and future Payment year depending on current run date.
																?	Summarize data for current PY
																?	If next year MMR is received then summarize next PY 
																?	If previous year final adjustment is not received the summarize previous PY.
															Include DiagnosisCode, Diagnosis ID and PCN in the output for all new HCC, INT, D-HCC and Delete HCC.
															Update Min_ProcessBy, Min_thrudate, Min_ProcessBy_Seq_Num,  Min_ThruDate_Seq_Num for D-HCC.
															
Ravi Chauhan        1/2/2014    3.0         22246           Updated HICN with RAFT E and 12 months Payment to RAFT C  
Ravi Chauhan        2/10/2014   3.1         24919           Change to override HPlan / Contract on RAPS by the most current HPlan / Contract from MMR for that member for that Payment Year    															
Ravi Chauhan        2/25/2014   3.2         25353           Change to correct duplicates on Natural key for Interactions.
Ravi Chauhan        2/25/2014   3.3         25426           Including Institutional beneficiaries (RAFT = I)  in the Blended Model 
Ravi Chauhan        3/17/2014   3.4         25315           Fix member plan accross multiple plan issue.
Ravi Chauhan        3/17/2014   3.5         25658           Move Plan level code from New HCC to Summary SP.   
Ravi Chauhan        3/20/2014   3.6         25953           To handle Alternate HICNs. 
Ravi Chauhan        5/19/2014   3.7         26951           Add Future Payment Year - New HCC Report for Initial Projection   
Ravi Chauhan        7/17/2014   3.8         25703           New HCC Hierarchy Logic and other changes  
Scott Hollabd		09/09/2014  3.9			25703			Made changes to the MOR logic 
Scott Holland		10/16/2014	4.0	        25703			Added Debugging to Code
Scott Holland		10/30/2014  4.1		    32890			Updated the MMR flag for the MMR flag error set to 0, and update the HCC temp table defintions to match the table DDL.
Scott Holland		01/06/2015	4.11		35124			Issue with data accumilating in MMR table. Remove OR statement at line 559.
Madhuri Suri 		07/01/2015	5.0 		43205			MOR Paymonth changes for 2015 PY 
													
																
***************************************************************************/
  --exec [spr_EstRecv_MMR_RAPS_MOR_Summary] 1,1,1,1,0,2015
CREATE PROCEDURE [dbo].[spr_EstRecv_MMR_RAPS_MOR_Summary]

--DECLARE 
	@MMR_FLAG BIT, 
	@ALT_HICN BIT,
	@MOR_FLAG BIT,
	@RAPS_FLAG BIT,
	@FullRefresh BIT = 0,
	@YearRefresh INT = NULL 
	AS

BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON

	DECLARE @Debug BIT = 0

	IF @Debug = 1
	BEGIN
		SET STATISTICS IO OFF

		DECLARE @ET DATETIME
		DECLARE @MasterET DATETIME

		SET @ET = GETDATE()
		SET @MasterET = @ET
	END

	-- sample exec code
	-- exec spr_EstRecv_MMR_RAPS_MOR_Summary 1,1,1,1
	--SET @MMR_FLAG = 1
	--SET @ALT_HICN = 1
	--SET @MOR_FLAG = 1
	--SET @RAPS_FLAG = 1

	DECLARE @sql VARCHAR(500),
		@IndexName VARCHAR(500),
		@TableName VARCHAR(500),
		@DisableRebuild VARCHAR(20),
		@Loop INT,
		@LoopMax INT,
		@Paymonth_MOR INT  --43205

	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'001',
				0,
				1
				)
		WITH NOWAIT
	END


	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'002',
				0,
				1
				)
		WITH NOWAIT
	END

	DECLARE @Payment_year INT = YEAR(getdate())
	DECLARE @Model_Year INT,
		/* Added the variable to implement Initial, Mid and Final Windows */
		-- Ticket # 25703
		@IMFInitialProcessby DATE,
		@IMFMidProcessby DATE,
		@IMFFinalProcessby DATE,
		@IMFDCPThrudate DATE
	DECLARE @PY_Cnt SMALLINT,
		@MY_Cnt SMALLINT,
		@Count_MY INT
	DECLARE @maxPayMStart INT
	DECLARE @Thru_Date SMALLDATETIME
	DECLARE @From_Date SMALLDATETIME

	SELECT @From_Date = '1/1/' + cast(@Payment_year - 1 AS VARCHAR)

	SELECT @Thru_Date = '12/31/' + cast(@Payment_year - 1 AS VARCHAR)
	
	
	-- Determine the PYs to be refreshed
	IF OBJECT_ID('[TEMPDB].[DBO].[#Refresh_PY]', 'U') IS NOT NULL
		DROP TABLE dbo.#Refresh_PY

	CREATE TABLE dbo.#Refresh_PY (
		ID INT identity(1, 1),
		Payment_Year INT,
		From_Date SMALLDATETIME,
		Thru_Date SMALLDATETIME
		)

	/* Added the logic for Full Refresh for the 3 Payment years, 1 Payment year or follow the logic */
	-- Ticket # 25703 Start
	IF (@FullRefresh = 1)
	BEGIN
		INSERT INTO #Refresh_PY (
			Payment_Year,
			From_Date,
			Thru_Date
			)
		VALUES (
			@Payment_year - 1,
			'01/01/' + cast(@Payment_year - 2 AS VARCHAR(4)),
			'12/31/' + cast(@Payment_year - 2 AS VARCHAR(4))
			),
			(
			@Payment_year,
			@From_Date,
			@Thru_Date
			),
			(
			@Payment_year + 1,
			'01/01/' + cast(@Payment_year AS VARCHAR(4)),
			'12/31/' + cast(@Payment_year AS VARCHAR(4))
			)
	END
	ELSE IF (
			ISNUMERIC(@YearRefresh) = 1
			AND @YearRefresh IS NOT NULL
			)
	BEGIN
		INSERT INTO #Refresh_PY (
			Payment_Year,
			From_Date,
			Thru_Date
			)
		VALUES (
			@YearRefresh,
			'01/01/' + cast(@YearRefresh - 1 AS VARCHAR(4)),
			'12/31/' + cast(@YearRefresh - 1 AS VARCHAR(4))
			)
					
	END
	ELSE
	BEGIN
		INSERT INTO #Refresh_PY (
			Payment_Year,
			From_Date,
			Thru_Date
			)
		SELECT @Payment_year,
			@From_Date,
			@Thru_Date

		IF EXISTS (
				SELECT 1
				FROM tbl_MMR_rollup
				WHERE AdjReason = '25'
					AND year(PaymStart) = @Payment_year - 1
				)
			SELECT @Payment_year = @Payment_year
		ELSE
		BEGIN
			INSERT INTO #Refresh_PY (
				Payment_Year,
				From_Date,
				Thru_Date
				)
			SELECT @Payment_year - 1,
				'1/1/' + cast(@Payment_year - 2 AS VARCHAR),
				'12/31/' + cast(@Payment_year - 2 AS VARCHAR)
		END

		IF EXISTS (
				SELECT 1
				FROM RAPS_DiagHCC_rollup
				WHERE year(processedby) = @Payment_year
				) -- Ticket # 26951
		BEGIN
			INSERT INTO #Refresh_PY (
				Payment_Year,
				From_Date,
				Thru_Date
				)
			SELECT @Payment_year + 1,
				'1/1/' + cast(@Payment_year AS VARCHAR),
				'12/31/' + cast(@Payment_year AS VARCHAR)
		END
	END

	-- Ticket # 25703 End
	IF OBJECT_ID('[tempdb].[dbo].#CountMonth', 'U') IS NOT NULL
		DROP TABLE #CountMonth

	CREATE TABLE dbo.#CountMonth (
		ID INT identity(1, 1) PRIMARY KEY NOT NULL,
		HICN VARCHAR(24),
		RA_Factor_Type VARCHAR(2),
		Payment_Year VARCHAR(5),
		Months INT
		)

	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'003',
				0,
				1
				)
		WITH NOWAIT
	END

	-- Alt HICN logic
	--if OBJECT_ID('tbl_EstRecv_alt_hicn') is not null
	--drop table
	--tbl_EstRecv_alt_hicn
	--	create table tbl_EstRecv_alt_hicn --tbl_ALTHICN_rollup
	--	(
	--	PlanID int, 	
	--	HICN varchar(25),
	--	FINALHICN varchar(20)
	--	)
	IF @ALT_HICN = 1
	BEGIN
		TRUNCATE TABLE tbl_EstRecv_alt_hicn

		-- Alt HICN logic
		INSERT INTO tbl_EstRecv_alt_hicn --tbl_ALTHICN_rollup
			(
			PlanID,
			HICN,
			FINALHICN
			)
		SELECT DISTINCT PlanIdentifier,
			HICN,
			FINALHICN
		FROM tbl_ALTHICN_rollup
		
		UNION
		
		SELECT DISTINCT PlanIdentifier,
			ALTHICN 'HICN',
			FINALHICN
		FROM tbl_ALTHICN_rollup

		-- UPDATE RUN LOG
		UPDATE tbl_EstRecv_Summary_tbl_Log
		SET Last_updated = GETDATE()
		WHERE Summary_tbl_Name = 'tbl_EstRecv_alt_hicn'
	END


	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'004',
				0,
				1
				)
		WITH NOWAIT
	END

	--select top 1 *  
	--into dbo.tbl_EstRecv_MMR
	--from tbl_EstRecv_MMR
	--truncate table dbo.tbl_EstRecv_MMR
	-- Get Member Month details
	IF @MMR_FLAG = 1
	BEGIN
		/* 25703 Logic is needed to take care of issue with running a single year refresh. */
		/* Start */
		--IF @YearRefresh = @Payment_year
		--	DELETE
		--	FROM dbo.tbl_EstRecv_MMR
		--	WHERE Payment_Year IN (
		--			@Payment_year,
		--			@Payment_year + 1
		--			)
		--ELSE
		--	DELETE
		--	FROM dbo.tbl_EstRecv_MMR
		--	WHERE Payment_Year IN (
		--			SELECT DISTINCT Payment_Year
		--			FROM #Refresh_PY
		--			)
		
		/* Ticket Number 35124 */
		/* Begin */
		IF 	(@YearRefresh = @Payment_year AND
				EXISTS(
				SELECT 1
				FROM RAPS_DiagHCC_rollup
				WHERE year(processedby) = @Payment_year
								))
		BEGIN
		
		WHILE (1 = 1)
		BEGIN								
			DELETE TOP (10000)
			FROM dbo.tbl_EstRecv_MMR
			WHERE Payment_Year IN (
					SELECT DISTINCT Payment_Year
					FROM #Refresh_PY
					)
			OR 
			Payment_Year = @Payment_year + 1					

			IF @@ROWCOUNT = 0
				BREAK
			ELSE
				CONTINUE
		END 
		end
		else
		begin
				WHILE (1 = 1)
		BEGIN								
			DELETE TOP (10000)
			FROM dbo.tbl_EstRecv_MMR
			WHERE Payment_Year IN (
					SELECT DISTINCT Payment_Year
					FROM #Refresh_PY
					)
					
			IF @@ROWCOUNT = 0
				BREAK
			ELSE
				CONTINUE
		END   
		end    
		
		/* End */


		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'005',
					0,
					1
					)
			WITH NOWAIT
		END

		/* End */
		-- Get Member Month details
		INSERT INTO dbo.tbl_EstRecv_MMR (
			PlanID,
			HICN,
			PaymStart,
			Gender,
			AgeGrp,
			RAFT,
			RAFT_ORIG,
			OREC,
			Medicaid,
			LI,
			Payment_Year,
			RS_old,
			SCC,
			PBP,
			HOSP,
			PartD_RAFT,
			OREC_CALC
			)
		SELECT DISTINCT mem.PlanIdentifier,
			isnull(ALTHCN.FinalHICN, mem.HICN),
			mem.PaymStart,
			CASE 
				WHEN mem.Sex = 'm'
					THEN 1
				WHEN mem.Sex = 'f'
					THEN 2
				ELSE 3
				END AS Gender,
			mem.RskAdjAgeGrp AS AgeGrp,
			mem.RA_Factor_Type AS RAFT,
			mem.RA_Factor_Type AS RAFT_ORIG,
			isnull(mem.OREC, 0),
			mem.MedicAddOn AS Medicaid,
			CASE mem.Part_D_Low_Income_Indicator
				WHEN 'N'
					THEN 0
				WHEN 'Y'
					THEN 1
				END AS LI,
			YEAR(mem.paymstart),
			mem.RSKADJFCTRA,
			mem.SCC,
			mem.pbp,
			mem.Hosp,
			mem.Part_D_RA_Factor_Type AS PartD_RAFT,
			isnull(mem.OREC, 0)
		FROM dbo.tbl_Member_Months_rollup mem
		LEFT JOIN tbl_EstRecv_alt_hicn ALTHCN ON mem.PlanIdentifier = ALTHCN.PlanID
			AND mem.HICN = ALTHCN.HICN
		WHERE mem.HICN IS NOT NULL
			AND YEAR(mem.paymstart) IN (
				SELECT DISTINCT Payment_Year
				FROM #Refresh_PY
				)

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'006',
					0,
					1
					)
			WITH NOWAIT
		END

		--order by YEAR(mem.paymstart)
		/*  This will only add a clustered index on HICN if the table does not already have an clustered index. */
		/* Start */
		--if (select name from sys.sysindexes
		--	where name = N'idx_tbl_EstRecv_MMR_HICN') is null
		--begin	
		--create clustered index idx_tbl_EstRecv_MMR_HICN on dbo.tbl_EstRecv_MMR
		--(HICN asc)
		--end		
		--if (select name from sys.sysindexes
		--	where name = N'idx_tbl_EstRecv_MMR_PaymStart') is not null
		--begin
		--	drop index idx_tbl_EstRecv_MMR_PaymStart on dbo.tbl_EstRecv_MMR
		--end
		--create nonclustered index idx_tbl_EstRecv_MMR_PaymStart on dbo.tbl_EstRecv_MMR
		--(PaymStart, RAFT, OREC)
		/* End */
		--insert into #CountMonth
		--      select HICN,RA_Factor_Type,count(distinct PaymStart) months
		--      from tbl_Member_Months_rollup 
		--      where RA_Factor_Type = 'E'
		--and PAYMSTART BETWEEN @From_Date AND @Thru_Date
		--group by HICN,RA_Factor_Type
		--having count(distinct PaymStart) >= 12	
		--update tbl_EstRecv_MMR	
		--set RAFT = 'C'	
		--from tbl_EstRecv_MMR mm
		--inner join #CountMonth c
		--on mm.hicn = c.HICN
		--and mm.raft = c.RA_Factor_Type
		-- Temporary code fix for ESRD members till ESRD risk model is made consistent with PART-C and PART-D
		UPDATE mm
		SET OREC_CALC = 9999
			--,Medicaid = 9999
		FROM dbo.tbl_EstRecv_MMR mm
		WHERE RAFT IN (
				'C1',
				'C2',
				'D',
				'E1',
				'E2',
				'ED',
				'G1',
				'G2',
				'I1',
				'I2'
				)

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'007',
					0,
					1
					)
			WITH NOWAIT
		END

		-- Ticket # 26951 Start
		/* Data issue with the way the OREC code was needing to be update for ticket number 25703 -- SRH 07/16/2014 */
		/* Begin OREC Update Logic */
		IF OBJECT_ID('tempdb..#tmp_UpdateORECLogic') IS NOT NULL
			DROP TABLE #tmp_UpdateORECLogic

		CREATE TABLE #tmp_UpdateORECLogic (
			ID INT identity(1, 1) PRIMARY KEY NOT NULL,
			RAFT VARCHAR(5),
			OREC INT,
			ORECNEW INT
			)

		/* The values inserted into this table are the logic changes. If any new values need to be added they will be 
	need to be added to the value insertion. */
		INSERT INTO #tmp_UpdateORECLogic (
			RAFT,
			OREC,
			ORECNEW
			)
		VALUES (
			'C',3,1
			),
			(
			'I',3,1
			),
			(
			'C',2,0
			),
			(
			'I',2,0
			),
			(
			'C',9,0
			),
			(
			'I',9,0
			)

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'008',
					0,
					1
					)
			WITH NOWAIT
		END

		/* End Update OREC Logic */
		/* Logic added for current year single year refresh */
		/* Start */
		
		/* Ticket Number 35124 */
		/* Begin */
		IF 
				(EXISTS(
				SELECT 1
				FROM RAPS_DiagHCC_rollup
				WHERE year(processedby) = @Payment_year
								)
				OR								
				(@YearRefresh = @Payment_year AND
				EXISTS(
				SELECT 1
				FROM RAPS_DiagHCC_rollup
				WHERE year(processedby) = @Payment_year
								)))
								
		/* End */								
								
		BEGIN
			DECLARE @MaPaymentStart DATETIME

			SELECT @MaPaymentStart = MAX(PaymStart)
			FROM dbo.tbl_EstRecv_MMR

			/* End */
			INSERT INTO dbo.tbl_EstRecv_MMR (
				PlanID,
				HICN,
				PaymStart,
				Gender,
				AgeGrp,
				RAFT,
				RAFT_ORIG,
				OREC,
				Medicaid,
				LI,
				Payment_Year,
				RS_old,
				SCC,
				PBP,
				HOSP,
				PartD_RAFT,
				OREC_CALC
				)
			SELECT PlanID,
				HICN,
				@MaPaymentStart,
				Gender,
				AgeGrp,
				RAFT,
				RAFT_ORIG,
				OREC,
				Medicaid,
				LI,
				year(@MaPaymentStart) + 1,
				RS_old,
				SCC,
				PBP,
				HOSP,
				PartD_RAFT,
				OREC_CALC
			FROM dbo.tbl_EstRecv_MMR
			WHERE PaymStart = @MaPaymentStart

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'009',
						0,
						1
						)
				WITH NOWAIT
			END
		END

		-- Ticket # 26951 End
		-- ,UPDATE RUN LOG
		UPDATE tbl_EstRecv_Summary_tbl_Log
		SET Last_updated = GETDATE()
		WHERE Summary_tbl_Name = 'tbl_EstRecv_MMR'
	END

	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'010',
				0,
				1
				)
		WITH NOWAIT
	END


	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'011',
				0,
				1
				)
		WITH NOWAIT
	END

	-- Ticket # 25953 Start
	IF OBJECT_ID('[TEMPDB].[DBO].[#AlthicnRAPS]', 'U') IS NOT NULL
		DROP TABLE dbo.#AlthicnRAPS

	CREATE TABLE dbo.#AlthicnRAPS (
		ID INT identity(1, 1) PRIMARY KEY NOT NULL,
		[RAPS_DiagHCC_rollupID] INT NOT NULL,
		[PlanIdentifier] SMALLINT NOT NULL,
		[ProcessedBy] SMALLDATETIME NOT NULL,
		[DiagnosisCode] VARCHAR(7) NULL,
		[HICN] VARCHAR(25) NULL,
		[PatientControlNumber] VARCHAR(40) NULL,
		[SeqNumber] VARCHAR(7) NULL,
		[ThruDate] SMALLDATETIME NULL,
		FileID VARCHAR(18),
		Source_Id INT,
		Provider_Id VARCHAR(40),
		RAC VARCHAR(1),
		[Deleted] VARCHAR(1) NULL,
		YearThruDate INT
		)

	INSERT INTO dbo.#AlthicnRAPS
	SELECT a.RAPS_DiagHCC_rollupID,
		a.PlanIdentifier,
		a.ProcessedBy,
		a.DiagnosisCode,
		isnull(ALTHCN.FinalHICN, a.HICN) HICN,
		a.PatientControlNumber,
		a.SeqNumber,
		a.ThruDate,
		a.FileID,
		a.Source_ID,
		a.Provider_ID,
		a.RAC,
		a.Deleted,
		YEAR(a.ThruDate) AS YearThruDate
	FROM RAPS_DiagHCC_rollup a 
	LEFT JOIN tbl_EstRecv_alt_hicn ALTHCN
		ON a.PlanIdentifier = ALTHCN.PlanID
		AND a.HICN = ALTHCN.HICN
	WHERE 
	a.HICN IS NOT NULL
		AND a.Void_Indicator IS NULL
		AND (
			a.DiagnosisError1 IS NULL
			OR a.DiagnosisError1 > '500'
			)
		AND (
			a.DiagnosisError2 IS NULL
			OR a.DiagnosisError2 > '500'
			)
		AND a.DOBError IS NULL
		AND a.SeqError IS NULL
		AND a.RAC_Error IS NULL
		AND (
			a.HICNError > '499'
			OR a.HICNError IS NULL
			)
	option(recompile)              		





	--CREATE NONCLUSTERED INDEX idx_AltHICNRAPS_ProcessedBy ON #AlthicnRAPS ([ProcessedBy]) include (
	--	[RAPS_DiagHCC_rollupID],
	--	[DiagnosisCode],
	--	[HICN],
	--	[PatientControlNumber],
	--	[SeqNumber],
	--	[ThruDate],
	--	[FileID],
	--	[Source_Id],
	--	[Provider_Id],
	--	[RAC],
	--	[Deleted],
	--	[YearThruDate]
	--	)

	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'012',
				0,
				1
				)
		WITH NOWAIT
	END

	IF @MOR_FLAG = 1
	BEGIN
		IF OBJECT_ID('[TEMPDB].[DBO].[#AlthicnMOR]', 'U') IS NOT NULL
			DROP TABLE dbo.#AlthicnMOR

		CREATE TABLE dbo.#AlthicnMOR (
			ID INT identity(1, 1) PRIMARY KEY NOT NULL,
			HICN VARCHAR(12) NULL,
			PayMonth VARCHAR(8) NULL,
			[Month] INT,
			NAME VARCHAR(50) NULL,
			RecordType CHAR(1) NULL,
			PlanIdentifier SMALLINT NOT NULL,
			COMM DECIMAL(20, 4)
			)

		INSERT INTO #AlthicnMOR (
			HICN,
			PayMonth,
			[Month],
			NAME,
			RecordType,
			PlanIdentifier,
			COMM
			)
		SELECT isnull(ALTHCN.FinalHICN, a.HICN) HICN,
			a.PayMonth,
			right(a.PayMonth, 2) AS [Month],
			a.NAME,
			a.RecordType,
			a.PlanIdentifier,
			a.Comm
		FROM Converted_MOR_Data_rollup a WITH (NOLOCK)
		LEFT JOIN tbl_EstRecv_alt_hicn ALTHCN WITH (NOLOCK) ON a.PlanIdentifier = ALTHCN.PlanID
			AND a.HICN = ALTHCN.HICN
		WHERE a.HICN IS NOT NULL

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'013',
					0,
					1
					)
			WITH NOWAIT
		END

		CREATE NONCLUSTERED INDEX idx_AltHICNMOR_HICN ON #AlthicnMOR (
			HICN,
			NAME,
			RecordType,
			PlanIdentifier,
			PayMonth
			) include ([Month])

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'014',
					0,
					1
					)
			WITH NOWAIT
		END
	END

	-- Ticket # 25953 End		        
	SELECT @PY_Cnt = max(ID)
	FROM #Refresh_PY

	/* Begin Payment Year Loop */
	WHILE @PY_Cnt > = 1
	BEGIN -- @Payment_year LOOP
		SELECT @Payment_Year = Payment_Year,
			@From_Date = From_Date,
			@Thru_Date = Thru_Date
		FROM #Refresh_PY
		WHERE ID = @PY_Cnt
  
		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'015',
					0,
					1
					)
			WITH NOWAIT
		END

		IF @MOR_FLAG = 1
		BEGIN
			--DELETE
			--FROM dbo.tbl_EstRecv_RiskFactorsMOR
			--WHERE PaymentYear = @Payment_Year
			
			WHILE (1 = 1)
			BEGIN
				DELETE TOP (10000)
				FROM dbo.tbl_EstRecv_RiskFactorsMOR
				WHERE PaymentYear = @Payment_year

				IF @@ROWCOUNT = 0
					BREAK
				ELSE
					CONTINUE
			END

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'016',
						0,
						1
						)
				WITH NOWAIT
			END
		END

		/* Calculated Initial, Mid and Final Windows */
		-- Ticket # 25703 Start
		SELECT @IMFDCPThrudate = min(DCP_end),
			@IMFInitialProcessBy = MIN(Initial_Sweep_Date),
			@IMFFinalProcessBy = MAX(Final_Sweep_Date)
		FROM [$(HRPReporting)]..lk_DCP_dates
		WHERE Mid_Year_Update IS NULL
			AND LEFT(Paymonth, 4) = @Payment_Year
			
	    SET @Paymonth_MOR  = (SELECT DISTINCT RIGHT(Paymonth, 1) 
	                                       FROM dbo.lk_DCP_dates_RskAdj 
	                                       WHERE LEFT(paymonth,4)=@Payment_year 
	                                       AND MOR_Mid_Year_Update ='Y')	--43205

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'017',
					0,
					1
					)
			WITH NOWAIT
		END

		SELECT @IMFMidProcessBy = MAX(Initial_Sweep_Date)
		FROM [$(HRPReporting)]..lk_DCP_dates dcp
		WHERE Mid_Year_Update = 'Y'
			AND LEFT(Paymonth, 4) = @Payment_Year

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'018',
					0,
					1
					)
			WITH NOWAIT
		END

		-- Ticket # 25703 End
		-- Ticket # 26951 Start
		IF year(GETDATE()) < @Payment_Year
		BEGIN
			DECLARE @maxMonth INT

			SELECT @maxMonth = max(month(PaymStart))
			FROM dbo.tbl_EstRecv_MMR
			WHERE payment_year = @Payment_Year

			TRUNCATE TABLE #CountMonth

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'019',
						0,
						1
						)
				WITH NOWAIT
			END

			INSERT INTO #CountMonth
			SELECT isnull(ALTHCN.FinalHICN, mem.HICN),
				RA_Factor_Type,
				@Payment_Year,
				count(DISTINCT PaymStart) months
			FROM tbl_Member_Months_rollup mem
			-- Ticket # 25953 Start
			LEFT JOIN tbl_EstRecv_alt_hicn ALTHCN ON mem.PlanIdentifier = ALTHCN.PlanID
				AND mem.HICN = ALTHCN.HICN
			-- Ticket # 25953 End
			WHERE RA_Factor_Type = 'E'
				AND mem.HICN IS NOT NULL -- Ticket # 25953 End
				AND PAYMSTART BETWEEN @From_Date
					AND @Thru_Date
			GROUP BY isnull(ALTHCN.FinalHICN, mem.HICN),
				RA_Factor_Type,
				YEAR(PaymStart)
			HAVING count(DISTINCT PaymStart) = @maxMonth

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'020',
						0,
						1
						)
				WITH NOWAIT
			END

			--select @Payment_Year,getdate()
			UPDATE dbo.tbl_EstRecv_MMR
			SET RAFT = 'C'
			FROM dbo.tbl_EstRecv_MMR mm
			INNER JOIN #CountMonth c ON mm.hicn = c.HICN
				AND mm.raft = c.RA_Factor_Type
				AND mm.Payment_Year = c.Payment_Year

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'021',
						0,
						1
						)
				WITH NOWAIT
			END
		END
				-- Ticket # 26951 End
		ELSE
		BEGIN
			-- Update RAFT E to C for 12 months or more enrolle.
			TRUNCATE TABLE #CountMonth

			INSERT INTO #CountMonth
			SELECT isnull(ALTHCN.FinalHICN, mem.HICN),
				RA_Factor_Type,
				@Payment_Year,
				count(DISTINCT PaymStart) months
			FROM tbl_Member_Months_rollup mem
			-- Ticket # 25953 Start
			LEFT JOIN tbl_EstRecv_alt_hicn ALTHCN ON mem.PlanIdentifier = ALTHCN.PlanID
				AND mem.HICN = ALTHCN.HICN
			-- Ticket # 25953 End
			WHERE RA_Factor_Type = 'E'
				AND mem.HICN IS NOT NULL -- Ticket # 25953 End
				AND PAYMSTART BETWEEN @From_Date
					AND @Thru_Date
			GROUP BY isnull(ALTHCN.FinalHICN, mem.HICN),
				RA_Factor_Type,
				YEAR(PaymStart)
			HAVING count(DISTINCT PaymStart) >= 12

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'022',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE dbo.tbl_EstRecv_MMR
			SET RAFT = 'C'
			FROM dbo.tbl_EstRecv_MMR mm
			INNER JOIN #CountMonth c ON mm.hicn = c.HICN
				AND mm.raft = c.RA_Factor_Type
				AND year(mm.PaymStart) = c.Payment_Year

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'023',
						0,
						1
						)
				WITH NOWAIT
			END
		END


/* 32890 Change to add MMR flag to fix issue with 0 MMR flag being sent to stored procedure. */
		
IF @MMR_FLAG = 1
BEGIN		

		BEGIN TRANSACTION UpdateOREC
		WITH MARK N'Update to OREC'

		BEGIN TRY
			UPDATE old
			SET OREC = new.ORECNEW,
				OREC_CALC = new.ORECNEW
			FROM dbo.tbl_EstRecv_MMR old
			INNER JOIN #tmp_UpdateORECLogic new ON old.RAFT = new.RAFT
				AND old.OREC = new.OREC
			WHERE old.Payment_Year = @Payment_Year

			COMMIT TRANSACTION UpdateOREC
		END TRY

		BEGIN CATCH
			ROLLBACK TRANSACTION UpdateOREC

			SELECT ERROR_LINE(),
				ERROR_NUMBER(),
				ERROR_PROCEDURE(),
				ERROR_SEVERITY(),
				ERROR_STATE()
		END CATCH
end

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'024',
					0,
					1
					)
			WITH NOWAIT
		END

		IF OBJECT_ID('[TEMPDB].[DBO].[#tbl_EstRecv_MMR]', 'U') IS NOT NULL
			DROP TABLE dbo.#tbl_EstRecv_MMR

		CREATE TABLE dbo.#tbl_EstRecv_MMR (
			ID INT identity(1, 1) PRIMARY KEY NOT NULL,
			PlanId INT,
			[HICN] [varchar](12),
			[RAFT] [varchar](2),
			Payment_Year INT,
			PaymStart [datetime],
			[RAFT_ORIG] [varchar](2),
			[OREC] [varchar](5),
			[OREC_CALC] [varchar](5),
			[HOSP] VARCHAR(1),
			[AgeGrp] [varchar](4),
			PriorPaymentYear INT
			)

		INSERT INTO #tbl_EstRecv_MMR
		SELECT PlanID,
			HICN,
			RAFT,
			Payment_Year,
			PaymStart,
			RAFT_ORIG,
			OREC,
			OREC_CALC,
			HOSP,
			[AgeGrp],
			Payment_Year - 1 AS PriorPaymentYear
		FROM dbo.tbl_EstRecv_MMR
		WHERE Payment_Year = @Payment_year

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'025',
					0,
					1
					)
			WITH NOWAIT
		END

		CREATE NONCLUSTERED INDEX idx_tbl_EstRecv_MMR_Payment_Year ON #tbl_EstRecv_MMR (HICN) include (
			PlanID,
			RAFT,
			Payment_Year,
			PriorPaymentYear
			)

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'026',
					0,
					1
					)
			WITH NOWAIT
		END

		CREATE NONCLUSTERED INDEX idx_tbl_EstRecv_MMT_RAFT ON #tbl_EstRecv_MMR (RAFT) include (
			PlanID,
			Payment_Year,
			HICN,
			PaymStart,
			RAFT_ORIG,
			HOSP
			)

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'027',
					0,
					1
					)
			WITH NOWAIT
		END

		IF @MOR_FLAG = 1
		BEGIN
			/*  Begin AltHICNMOR12Mo Temp Table */
			IF OBJECT_ID('tempdb..#AltHicnMOR12Mo') IS NOT NULL
				DROP TABLE #AltHicnMOR12Mo

			CREATE TABLE #AltHicnMOR12Mo (
				ID INT identity(1, 1) PRIMARY KEY NOT NULL,
				HICN VARCHAR(12),
				PayMonth VARCHAR(8),
				[Month] INT,
				NAME VARCHAR(50),
				RecordType CHAR(1),
				PlanIdentifier SMALLINT,
				Comm DECIMAL(20, 4)
				)

			INSERT INTO #AltHicnMOR12Mo (
				HICN,
				PayMonth,
				[Month],
				NAME,
				RecordType,
				PlanIdentifier,
				Comm
				)
			SELECT HICN,
				PayMonth,
				[Month],
				NAME,
				RecordType,
				PlanIdentifier,
				Comm
			FROM #AlthicnMOR m
			WHERE [Month] <= 12
				AND left(PayMonth, 4) = @Payment_Year

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'028',
						0,
						1
						)
				WITH NOWAIT
			END

			CREATE NONCLUSTERED INDEX idx_AltHicnMORNoHosp_HICN ON #AltHicnMOR12Mo (
				HICN,
				NAME,
				RecordType,
				PlanIdentifier,
				PayMonth
				) include ([Month])

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'029',
						0,
						1
						)
				WITH NOWAIT
			END

			/* End AltHICNMOR12M0 Temp Table */
			/* Begin MMR MaxPlanID Temp Table */
			IF OBJECT_ID('tempdb..#tmp_MaxPlanID') IS NOT NULL
				DROP TABLE #tmp_MaxPlanID

			CREATE TABLE #tmp_MaxPlanID (
				ID INT identity(1, 1) PRIMARY KEY NOT NULL,
				PlanID INT,
				HICN VARCHAR(12),
				PaymStart DATETIME,
				[Month] INT,
				[Year] INT,
				OREC_CALC VARCHAR(5),
				HOSP VARCHAR(1) NULL,
				RAFT VARCHAR(3) NULL
				)

			INSERT INTO #tmp_MaxPlanID (
				PlanID,
				HICN,
				PaymStart,
				[Month],
				[Year],
				OREC_CALC
				)
			SELECT PlanId,
				HICN,
				PaymStart,
				MONTH(PaymStart) AS [Month],
				YEAR(PaymStart) AS [Year],
				OREC_CALC
			FROM #tbl_EstRecv_MMR mmr
			WHERE PaymStart = (
					SELECT TOP 1 PaymStart
					FROM #tbl_EstRecv_MMR mi
					WHERE mmr.HICN = mi.HICN
					ORDER BY PaymStart DESC
					)

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'030',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE h
			SET HOSP = 'Y'
			FROM #tmp_MaxPlanID h
			INNER JOIN #tbl_EstRecv_MMR m ON h.PlanID = m.PlanId
				AND h.HICN = m.HICN
				AND h.PaymStart = m.PaymStart
				AND h.OREC_CALC = m.OREC_CALC
			WHERE m.HOSP = 'Y'

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'031',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE h
			SET h.RAFT = m.RAFT
			FROM #tmp_MaxPlanID h
			INNER JOIN #tbl_EstRecv_MMR m ON h.PlanID = m.PlanId
				AND h.HICN = m.HICN
				AND h.PaymStart = m.PaymStart
				AND h.OREC_CALC = m.OREC_CALC

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'032',
						0,
						1
						)
				WITH NOWAIT
			END

			CREATE NONCLUSTERED INDEX idx_MaxPlanID_HICN ON #tmp_MaxPlanID (
				HICN,
				PaymStart
				) include (
				PlanID,
				OREC_CALC,
				HOSP,
				RAFT
				)

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'033',
						0,
						1
						)
				WITH NOWAIT
			END

			/* End MaxPlanID Temp Table */
			/* Begin tmpMOR temp table */
			IF OBJECT_ID('tempdb..#tmp_MOR') IS NOT NULL
				DROP TABLE #tmp_MOR

			CREATE TABLE #tmp_MOR (
				ID INT identity(1, 1) PRIMARY KEY NOT NULL,
				PlanID INT,
				HICN VARCHAR(12),
				PaymentYear INT,
				PaymStart DATE,
				Model_Year INT,
				Factor_Category VARCHAR(20),
				Factor_Description VARCHAR(50),
				Factor DECIMAL(20, 4),
				HCC_Number VARCHAR(5),
				RAFT VARCHAR(3),
				RAFT_ORIG VARCHAR(2),
				HOSP VARCHAR(1),
				OREC_CALC VARCHAR(5)
				)

			INSERT INTO #tmp_MOR (
				PlanID,
				HICN,
				PaymentYear,
				PaymStart,
				Model_Year,
				Factor_Category,
				Factor_Description,
				Factor,
				HCC_Number,
				RAFT,
				RAFT_ORIG,
				HOSP,
				OREC_CALC
				)
			SELECT PlanID,
				HICN,
				PaymentYear,
				PaymStart,
				Model_Year,
				Factor_Category,
				Factor_Description,
				Factor,
				HCC_Number,
				RAFT,
				RAFT_ORIG,
				HOSP,
				OREC_CALC
			FROM (
				SELECT CASE 
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
									AND e.HICN IS NULL
								)
							AND e.PlanID IS NULL
							THEN mp.PlanID
						ELSE coalesce(e.PlanID, m.PlanIdentifier)
						END AS PlanID,
					m.HICN,
					@Payment_year AS PaymentYear,
					right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) AS PaymStart,
					CASE 
						WHEN m.RecordType = 'A'
							THEN (
									SELECT ModelYear
									FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits
									WHERE RecordType = m.RecordType
										AND PaymentYear = left(m.PayMonth, 4)
										AND SplitSegmentNumber = 1
									)
						WHEN m.RecordType = 'B'
							THEN @Payment_year
						WHEN m.RecordType = 'C'
							THEN (
									SELECT ModelYear
									FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits
									WHERE RecordType = m.RecordType
										AND PaymentYear = left(m.PayMonth, 4)
										AND SplitSegmentNumber = 2
									)
						END AS Model_Year,
					'MOR-HCC' AS Factor_Category,
					CASE 
						WHEN (
								ltrim(rtrim(e.RAFT)) IN (
									'C1',
									'C2',
									'D',
									'I1',
									'I2',
									'G1',
									'G2'
									)
								AND PATINDEX('INT%', m.NAME) = 0
								)
							AND len(ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1)))) < 3
							THEN replace(replace(m.NAME, ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))), right('00' + ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))), 3)), ' ', '')
						WHEN (
								ltrim(rtrim(e.RAFT)) IN (
									'C1',
									'C2',
									'D',
									'I1',
									'I2',
									'G1',
									'G2'
									)
								AND PATINDEX('INT%', m.NAME) = 0
								)
							AND len(ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1)))) >= 3
							THEN replace(replace(m.NAME, ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))), right('00' + ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))), 3)), ' ', '')
						WHEN (
								ltrim(rtrim(e.RAFT)) IN (
									'D1',
									'D2',
									'D3',
									'D4',
									'D5',
									'D6',
									'D7',
									'D8',
									'D9'
									)
								AND PATINDEX('INT%', m.NAME) = 0
								)
							THEN replace(replace(m.NAME, ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))), right('00' + ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))), 3)), ' ', '')
						WHEN (
								ltrim(rtrim(e.RAFT)) IN (
									'C',
									'I'
									)
								AND ltrim(rtrim(m.NAME)) NOT LIKE '% %'
								AND PATINDEX('INT%', m.NAME) = 0
								)
							THEN CAST(LEFT(m.NAME, LEN(m.NAME) - CAST(PATINDEX('%[A-Z]%', REVERSE(m.NAME)) AS INT) + 1) AS VARCHAR(30)) + ' ' + CAST(LTRIM(REVERSE(LEFT(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))) AS VARCHAR(20))
						ELSE m.NAME
						END AS Factor_Description,
					CASE 
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
								)
							OR EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) <= mpi.PaymStart
								)
							THEN NULL
						WHEN e.HICN IS NULL
							AND e.RAFT IS NULL
							THEN m.Comm
						ELSE NULL
						END AS Factor,
					cast(ltrim(reverse(left(REVERSE(m.NAME), PATINDEX('%[A-Z]%', reverse(m.NAME)) - 1))) AS INT) AS HCC_Number,
					CASE 
						WHEN e.HICN IS NULL
							AND EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
									AND mpi.HOSP = 'Y'
								)
							THEN 'HP'
						WHEN e.HICN IS NULL
							AND EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) <= mpi.PaymStart
									AND mpi.HOSP = 'Y'
								)
							THEN 'HP'
						WHEN e.RAFT IS NULL
							AND e.HOSP = 'Y'
							AND EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) = mpi.PaymStart
								)
							THEN 'HP'
						WHEN e.RAFT IS NULL
							AND e.HOSP = 'Y'
							THEN 'HP'
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND e.HICN IS NULL
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
								)
							THEN (
									SELECT TOP 1 mpi.RAFT
									FROM #tmp_MaxPlanID mpi
									WHERE m.HICN = mpi.HICN
										AND RIGHT(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
										AND e.HICN IS NULL
									ORDER BY mpi.PaymStart DESC
									)
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND e.HICN IS NULL
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) <= mpi.PaymStart
								)
							THEN (
									SELECT TOP 1 mpi.RAFT
									FROM #tmp_MaxPlanID mpi
									WHERE m.HICN = mpi.HICN
										AND RIGHT(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) <= mpi.PaymStart
										AND e.HICN IS NULL
									ORDER BY mpi.PaymStart DESC
									)
						ELSE e.RAFT
						END AS RAFT,
					e.RAFT_ORIG,
					CASE 
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
									AND mpi.HOSP = 'Y'
								)
							AND e.HOSP IS NULL
							THEN 'Y'
						ELSE e.HOSP
						END AS HOSP,
					CASE 
						WHEN patindex('D-%', m.NAME) > 0
							THEN 9999
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
									AND e.HICN IS NULL
								)
							THEN (
									SELECT TOP 1 OREC_CALC
									FROM #tmp_MaxPlanID mpi
									WHERE m.HICN = mpi.HICN
										AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) >= mpi.PaymStart
										AND e.HICN IS NULL
									ORDER BY mpi.PaymStart DESC
									)
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) <= mpi.PaymStart
									AND e.HICN IS NULL
								)
							THEN (
									SELECT TOP 1 OREC_CALC
									FROM #tmp_MaxPlanID mpi
									WHERE m.HICN = mpi.HICN
										AND right(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) <= mpi.PaymStart
										AND e.HICN IS NULL
									ORDER BY mpi.PaymStart DESC
									)
						WHEN EXISTS (
								SELECT 1
								FROM #tmp_MaxPlanID mpi
								WHERE m.HICN = mpi.HICN
									AND RIGHT(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) = mpi.PaymStart
								)
							AND e.HICN IS NULL
							THEN (
									SELECT TOP 1 OREC_CALC
									FROM #tmp_MaxPlanID mpi
									WHERE m.HICN = mpi.HICN
										AND RIGHT(m.PayMonth, 2) + '/01/' + LEFT(m.PayMonth, 4) = mpi.PaymStart
									ORDER BY mpi.PaymStart DESC
									)
						ELSE e.OREC_CALC
						END AS OREC_CALC
				FROM #AltHicnMOR12Mo m WITH (NOLOCK)
				LEFT JOIN #tbl_EstRecv_MMR e WITH (NOLOCK) ON m.HICN = e.HICN
					AND left(m.PayMonth, 4) = e.Payment_Year
					AND m.Month = MONTH(e.PaymStart)
				LEFT JOIN #tmp_MaxPlanID mp ON m.HICN = mp.HICN
				) t1
			GROUP BY PlanID,
				HICN,
				PaymentYear,
				PaymStart,
				Model_Year,
				Factor_Category,
				Factor_Description,
				Factor,
				HCC_Number,
				RAFT,
				RAFT_ORIG,
				HOSP,
				OREC_CALC

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'034',
						0,
						1
						)
				WITH NOWAIT
			END

			CREATE NONCLUSTERED INDEX idx_tmp_MOR_HICN ON #tmp_MOR (HICN) include (
				PlanID,
				PaymentYear,
				PaymStart,
				RAFT
				)

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'035',
						0,
						1
						)
				WITH NOWAIT
			END

			/* End tmpMOR temp Table */
			/* Update tmpMOR Factor temp table */
			UPDATE m
			SET Factor_Description = rm.Factor_Description
			FROM #tmp_MOR m
			INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models rm ON m.Model_Year = rm.Payment_Year
				AND m.RAFT = rm.Factor_Type
				AND replace(m.Factor_Description, ' ', '') = replace(rm.Factor_Description, ' ', '')
				AND rm.Part_C_D_Flag = 'C'
				AND rm.Demo_Risk_Type = 'RISK'
				AND rm.OREC = 9999
				AND m.RAFT IN (
					'C',
					'I'
					)
				AND m.Factor_Description NOT LIKE '% %'
				AND m.Factor_Description LIKE 'D-%'

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'036',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE m
			SET Factor_Description = rm.Factor_Description
			FROM #tmp_MOR m
			INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models rm ON m.Model_Year = rm.Payment_Year
				AND m.RAFT = rm.Factor_Type
				AND replace(m.Factor_Description, ' ', '') = replace(rm.Factor_Description, ' ', '')
				AND rm.Part_C_D_Flag = 'C'
				AND rm.Demo_Risk_Type = 'RISK'
				AND rm.OREC = m.OREC_CALC
				AND m.RAFT IN (
					'C',
					'I'
					)
				AND m.Factor_Description NOT LIKE '% %'
				AND m.Factor_Description NOT LIKE 'D-%'

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'037',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE m
			SET Factor = 0.00
			FROM #tmp_MOR m
			WHERE m.RAFT = 'HP'

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'038',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE m
			SET Factor = mdl.Factor
			FROM #tmp_MOR m
			INNER JOIN [$(HRPReporting)].dbo.lk_risk_models mdl ON m.Model_Year = mdl.Payment_Year
				AND m.RAFT = mdl.Factor_Type
				AND m.HCC_Number = cast(ltrim(reverse(left(REVERSE(mdl.Factor_Description), PATINDEX('%[A-Z]%', reverse(mdl.Factor_Description)) - 1))) AS INT)
				AND left(m.Factor_Description, 3) = left(mdl.Factor_Description, 3)
			WHERE m.OREC_CALC = 9999
				AND patindex('D-%', m.Factor_Description) > 0
				AND mdl.Part_C_D_Flag = 'C'
				AND mdl.Demo_Risk_Type = 'Risk'
				AND m.Factor IS NULL

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'039',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE m
			SET Factor = mdl.Factor
			FROM #tmp_MOR m
			INNER JOIN [$(HRPReporting)].dbo.lk_risk_models mdl ON m.Model_Year = mdl.Payment_Year
				AND m.RAFT = mdl.Factor_Type
				AND m.HCC_Number = cast(ltrim(reverse(left(REVERSE(mdl.Factor_Description), PATINDEX('%[A-Z]%', reverse(mdl.Factor_Description)) - 1))) AS INT)
				AND left(m.Factor_Description, 3) = left(mdl.Factor_Description, 3)
				AND m.OREC_CALC = mdl.OREC
			WHERE mdl.Part_C_D_Flag = 'C'
				AND mdl.Demo_Risk_Type = 'Risk'
				AND m.Factor IS NULL

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'040',
						0,
						1
						)
				WITH NOWAIT
			END

			UPDATE t
			SET Factor_Description = t1.Factor_Description
			FROM #tmp_MOR t
			INNER JOIN (
				SELECT ID,
					replace(Factor_Description, HCC_Number, right('00' + HCC_Number, 3)) AS Factor_Description
				FROM #tmp_MOR
				WHERE (
						ltrim(rtrim(RAFT)) IN (
							'C1',
							'C2',
							'D',
							'I1',
							'I2'
							)
						AND PATINDEX('INT%', Factor_Description) = 0
						)
					AND LEN(HCC_Number) < 3
					AND PATINDEX('HCC%0%', Factor_Description) = 0
					AND patindex('D-%', Factor_Description) = 0
				) t1 ON t.ID = t1.ID

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'041',
						0,
						1
						)
				WITH NOWAIT
			END

			/* End Update Factor tmpMOt temp table */
			/* Begin Insert into MOR table */
			INSERT INTO dbo.tbl_EstRecv_RiskFactorsMOR (
				PlanID,
				HICN,
				PaymentYear,
				PaymStart,
				Model_Year,
				Factor_category,
				Factor_Desc,
				Factor,
				HCC_Number,
				RAFT,
				RAFT_ORIG
				)
			SELECT PlanID,
				HICN,
				PaymentYear,
				PaymStart,
				Model_Year,
				Factor_category,
				Factor_Description,
				Factor,
				HCC_Number,
				RAFT,
				RAFT_ORIG
			FROM #tmp_MOR
			WHERE PaymentYear = @Payment_year

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'042',
						0,
						1
						)
				WITH NOWAIT
			END
		END

		/* End Insert into MOR table */
		IF @RAPS_FLAG = 1
		BEGIN
			TRUNCATE TABLE tbl_EstRecv_RAPS_DiagHCC

			--IF EXISTS (
			--		SELECT NAME
			--		FROM sys.indexes
			--		WHERE NAME = 'IDX_tbl_EstRecv_RAPS_DiagHCC'
			--		)
			--	DROP INDEX IDX_tbl_EstRecv_RAPS_DiagHCC ON dbo.tbl_EstRecv_RAPS_DiagHCC
			--select top 1 * 
			--into dbo.tbl_EstRecv_RAPS_DiagHCC
			--from tbl_EstRecv_RAPS_DiagHCC
			--truncate table dbo.tbl_EstRecv_RAPS_DiagHCC
			INSERT INTO dbo.tbl_EstRecv_RAPS_DiagHCC (
				RAPS_DiagHCC_rollupID,
				PlanIdentifier,
				ProcessedBy,
				DiagnosisCode,
				HICN,
				PatientControlNumber,
				SeqNumber,
				ThruDate,
				/* Ticket # 25703 Start */
				FileID,
				Source_Id,
				Provider_Id,
				RAC,
				Deleted,
				RAFT,
				Payment_year
				)
			SELECT DISTINCT rps.RAPS_DiagHCC_rollupID,
				--Take Plan ID from MMR table Ticket # 24919 Start 
				mm.PlanID,
				--Take Plan ID from MMR table Ticket # 24919 End
				rps.ProcessedBy,
				rps.DiagnosisCode,
				rps.HICN,
				rps.PatientControlNumber,
				rps.SeqNumber,
				rps.ThruDate,
				FileID,
				Source_Id,
				Provider_Id,
				RAC,
				/* Ticket # 25703 end */
				CASE 
					WHEN rps.Deleted IS NULL
						THEN 'A'
					ELSE 'D'
					END Deleted,
				mm.RAFT,
				mm.Payment_Year
			FROM #tbl_EstRecv_MMR mm
			INNER JOIN #AlthicnRAPS rps -- Ticket # 25953
				ON
				-- BD: This check commented to get cross plan RAPS
				-- rps.PlanIdentifier = mm.PlanID and 
				rps.HICN = mm.HICN
				AND rps.YearThruDate = mm.PriorPaymentYear
			WHERE rps.ProcessedBy <= @IMFFinalProcessBy -- Ticket # 25703	
				--order by rps.RAPS_DiagHCC_rollupID, rps.HICN, rps.ThruDate 

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'043',
						0,
						1
						)
				WITH NOWAIT
			END
					--IF (
					--		SELECT NAME
					--		FROM sys.sysindexes
					--		WHERE NAME = N'IDX_tbl_EstRecv_RAPS_DiagHCC'
					--		) IS NOT NULL
					--BEGIN
					--DROP INDEX IDX_tbl_EstRecv_RAPS_DiagHCC ON dbo.tbl_EstRecv_RAPS_DiagHCC
					--END
					--IF (
					--		SELECT NAME
					--		FROM sys.sysindexes
					--		WHERE NAME = N'IDX_tbl_EstRecv_RAPS_DiagHCC_HICN'
					--		) IS NULL
					--BEGIN
					--	CREATE CLUSTERED INDEX IDX_tbl_EstRecv_RAPS_DiagHCC_HICN ON dbo.tbl_EstRecv_RAPS_DiagHCC (HICN ASC)
					--END
					--CREATE NONCLUSTERED INDEX IDX_tbl_EstRecv_RAPS_DiagHCC ON dbo.tbl_EstRecv_RAPS_DiagHCC (
					--	Payment_year,
					--	RAFT,
					--	DiagnosisCode
					--	)
		END

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'044',
					0,
					1
					)
			WITH NOWAIT
		END

		-- Determine the Model Yearss to be refreshed
		IF OBJECT_ID('[TEMPDB].[DBO].[#Refresh_MY]', 'U') IS NOT NULL
			DROP TABLE dbo.#Refresh_MY

		CREATE TABLE dbo.#Refresh_MY (
			ID SMALLINT identity(1, 1),
			Payment_Year INT,
			Model_Year INT
			)

		INSERT INTO #Refresh_MY (
			Payment_Year,
			Model_Year
			)
		SELECT DISTINCT PaymentYear,
			ModelYear
		FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits
		WHERE PaymentYear = @Payment_Year

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'045',
					0,
					1
					)
			WITH NOWAIT
		END

		-- Ticket # 26951 Start
		DECLARE @maxModelYear INT

		SELECT @maxModelYear = MAX(modelyear)
		FROM [$(HRPReporting)].dbo.tbl_EstRecv_ModelSplits
		WHERE PaymentYear = @Payment_Year

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'046',
					0,
					1
					)
			WITH NOWAIT
		END

		IF @maxModelYear <> @Payment_Year
		BEGIN
			INSERT INTO #Refresh_MY (
				Payment_Year,
				Model_Year
				)
			SELECT @Payment_Year,
				@Payment_Year
		END

		IF @Debug = 1
		BEGIN
			PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

			SET @ET = GETDATE()

			RAISERROR (
					'047',
					0,
					1
					)
			WITH NOWAIT
		END

		-- Ticket # 26951 End
		SELECT @MY_Cnt = max(ID)
		FROM #Refresh_MY

		WHILE @MY_Cnt > = 1
		BEGIN -- @MODEL_YEAR LOOP
			SELECT @Model_Year = Model_Year
			FROM #Refresh_MY
			WHERE ID = @MY_Cnt

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'048',
						0,
						1
						)
				WITH NOWAIT
			END

			-- Mor has to be refreshed first ticket # 25703
			IF @MOR_FLAG = 1
			BEGIN
				-- RecordType parameter to be used only for Payment year which has split model.
				SELECT @Count_MY = COUNT(Model_Year)
				FROM #Refresh_MY
				WHERE Payment_Year = @Payment_year
				GROUP BY Payment_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'049',
							0,
							1
							)
					WITH NOWAIT
				END

				IF @Count_MY > 1
					AND @Payment_year = @Model_Year
					-- MOR Disease Hierarchy
					UPDATE drp
					SET drp.Factor_Desc = 'HIER-' + drp.Factor_Desc
					--,	drp.Factor = 0
					FROM tbl_EstRecv_RiskFactorsMOR drp
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
						AND Hier.Payment_Year = drp.Model_Year
						AND Hier.RA_FACTOR_TYPE = drp.RAFT
						AND Hier.Part_C_D_Flag = 'C'
						AND left(Hier.HCC_DROP, 3) = 'HCC'
						AND left(drp.Factor_Desc, 3) = 'HCC'
					INNER JOIN tbl_EstRecv_RiskFactorsMOR kep ON kep.PlanID = drp.PlanID
						AND kep.HICN = drp.HICN
						AND kep.RAFT = drp.RAFT
						AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
						AND kep.Model_Year = drp.Model_Year
						AND kep.PaymStart = drp.PaymStart
						AND left(kep.Factor_Desc, 3) = 'HCC'
					WHERE drp.PaymentYear = @Payment_Year
						AND drp.Model_Year = @Model_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'050',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE drp
				SET drp.Factor_Desc = 'HIER-' + drp.Factor_Desc
				--,	drp.Factor = 0
				FROM tbl_EstRecv_RiskFactorsMOR drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(substring(Hier.HCC_DROP, 4, LEN(Hier.HCC_DROP) - 3) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = drp.Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.Factor_Desc, 3) = 'INT'
				INNER JOIN tbl_EstRecv_RiskFactorsMOR kep ON kep.PlanID = drp.PlanID
					AND kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(substring(Hier.HCC_keep, 4, LEN(Hier.HCC_DROP) - 3) AS INT)
					AND kep.Model_Year = drp.Model_Year
					AND kep.PaymStart = drp.PaymStart
					AND left(kep.Factor_Desc, 3) = 'INT'
				WHERE drp.PaymentYear = @Payment_Year
					AND drp.Model_Year = @Model_Year
			END

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'051',
						0,
						1
						)
				WITH NOWAIT
			END

			IF @RAPS_FLAG = 1
			BEGIN
				--select top 1 * 
				--into dbo.tbl_EstRecv_RiskFactorsRAPS
				--from tbl_EstRecv_RiskFactorsRAPS
				--truncate table dbo.tbl_EstRecv_RiskFactorsRAPS
				--DELETE
				--FROM dbo.tbl_EstRecv_RiskFactorsRAPS
				--WHERE Model_Year = @Model_Year
				--	AND PaymentYear = @Payment_Year
				
				WHILE (1 = 1)
				BEGIN
					DELETE TOP (10000)
					FROM dbo.tbl_EstRecv_RiskFactorsRAPS
					WHERE PaymentYear = @Payment_Year
					AND Model_Year = @Model_Year
					IF @@ROWCOUNT = 0
						BREAK
					ELSE
						CONTINUE
				END      

				

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'052',
							0,
							1
							)
					WITH NOWAIT
				END

				TRUNCATE TABLE dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'053',
							0,
							1
							)
					WITH NOWAIT
				END

				IF @Payment_year = @Model_Year
					AND @maxModelYear <> @Payment_Year
				BEGIN
					INSERT INTO dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod (
						RAPS_DiagHCC_rollupID,
						PlanIdentifier,
						ProcessedBy,
						DiagnosisCode,
						HICN,
						PatientControlNumber,
						SeqNumber,
						ThruDate,
						/* Ticket # 25703 Start */
						FileID,
						Source_Id,
						Provider_Id,
						RAC,
						Deleted,
						RAFT,
						Payment_year,
						[HCC],
						[HCC_Number]
						)
					SELECT DISTINCT diag.RAPS_DiagHCC_rollupID,
						diag.PlanIdentifier,
						diag.ProcessedBy,
						diag.DiagnosisCode,
						diag.HICN,
						diag.PatientControlNumber,
						diag.SeqNumber,
						diag.ThruDate,
						diag.FileID,
						diag.Source_Id,
						diag.Provider_Id,
						diag.RAC,
						/* Ticket # 25703 END */
						diag.Deleted,
						diag.RAFT,
						RskMod.Payment_Year,
						RskMod.HCC_Label,
						RskMod.HCC_Number
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC diag
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_DiagHCC RskMod ON RskMod.Payment_Year = diag.Payment_year
						AND RskMod.Factor_Type = diag.RAFT
						AND RskMod.ICD9 = diag.DiagnosisCode
					WHERE RskMod.HCC_Label LIKE 'HCC%'
						AND diag.RAFT NOT IN (
							'C',
							'I'
							)

					IF @Debug = 1
					BEGIN
						PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

						SET @ET = GETDATE()

						RAISERROR (
								'054',
								0,
								1
								)
						WITH NOWAIT
					END
				END
				ELSE IF @Payment_year = @Model_Year
					AND @maxModelYear = @Payment_Year -- Ticket # 26951
				BEGIN
					INSERT INTO dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod (
						RAPS_DiagHCC_rollupID,
						PlanIdentifier,
						ProcessedBy,
						DiagnosisCode,
						HICN,
						PatientControlNumber,
						SeqNumber,
						ThruDate,
						/* Ticket # 25703 Start */
						FileID,
						Source_Id,
						Provider_Id,
						RAC,
						Deleted,
						RAFT,
						Payment_year,
						[HCC],
						[HCC_Number]
						)
					SELECT DISTINCT diag.RAPS_DiagHCC_rollupID,
						diag.PlanIdentifier,
						diag.ProcessedBy,
						diag.DiagnosisCode,
						diag.HICN,
						diag.PatientControlNumber,
						diag.SeqNumber,
						diag.ThruDate,
						diag.FileID,
						diag.Source_Id,
						diag.Provider_Id,
						diag.RAC,
						/* Ticket # 25703 END */
						diag.Deleted,
						diag.RAFT,
						RskMod.Payment_Year,
						RskMod.HCC_Label,
						RskMod.HCC_Number
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC diag
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_DiagHCC RskMod ON RskMod.Payment_Year = diag.Payment_year
						AND RskMod.Factor_Type = diag.RAFT
						AND RskMod.ICD9 = diag.DiagnosisCode
					WHERE RskMod.HCC_Label LIKE 'HCC%'

					IF @Debug = 1
					BEGIN
						PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

						SET @ET = GETDATE()

						RAISERROR (
								'055',
								0,
								1
								)
						WITH NOWAIT
					END
				END
				ELSE IF @Payment_year <> @Model_Year
				BEGIN
					INSERT INTO dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod (
						RAPS_DiagHCC_rollupID,
						PlanIdentifier,
						ProcessedBy,
						DiagnosisCode,
						HICN,
						PatientControlNumber,
						SeqNumber,
						ThruDate,
						/* Ticket # 25703 Start */
						FileID,
						Source_Id,
						Provider_Id,
						RAC,
						Deleted,
						RAFT,
						Payment_year,
						[HCC],
						[HCC_Number]
						)
					SELECT DISTINCT diag.RAPS_DiagHCC_rollupID,
						diag.PlanIdentifier,
						diag.ProcessedBy,
						diag.DiagnosisCode,
						diag.HICN,
						diag.PatientControlNumber,
						diag.SeqNumber,
						diag.ThruDate,
						diag.FileID,
						diag.Source_Id,
						diag.Provider_Id,
						diag.RAC,
						/* Ticket # 25703 END */
						diag.Deleted,
						diag.RAFT,
						RskMod.Payment_Year,
						RskMod.HCC_Label,
						RskMod.HCC_Number
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC diag
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_DiagHCC RskMod ON RskMod.Payment_Year = @Model_Year
						AND RskMod.Factor_Type = diag.RAFT
						AND RskMod.ICD9 = diag.DiagnosisCode
						AND diag.Payment_Year = @Payment_Year
					WHERE diag.RAFT IN (
							'C',
							'I'
							) -- Ticket # 25426
						AND RskMod.HCC_Label LIKE 'HCC%'

					IF @Debug = 1
					BEGIN
						PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

						SET @ET = GETDATE()

						RAISERROR (
								'056',
								0,
								1
								)
						WITH NOWAIT
					END
				END

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'057',
							0,
							1
							)
					WITH NOWAIT
				END

				--select top 1 * into dbo.tbl_EstRecv_RAPS from tbl_EstRecv_RAPS
				--truncate table dbo.tbl_EstRecv_RAPS
				TRUNCATE TABLE dbo.tbl_EstRecv_RAPS

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'058',
							0,
							1
							)
					WITH NOWAIT
				END

				--Loading Accpeted RAPS
				INSERT INTO dbo.tbl_EstRecv_RAPS (
					PlanID,
					HICN,
					RAFT,
					[HCC],
					HCC_ORIG,
					HCC_ORIG_EstRecev,
					[HCC_Number],
					Min_Process_By,
					Min_Thru,
					Deleted,
					Payment_Year
					)
				SELECT DISTINCT rps.PlanIdentifier,
					rps.HICN,
					rps.RAFT,
					rps.HCC,
					rps.HCC,
					rps.HCC,
					rps.HCC_Number,
					MIN(rps.ProcessedBy),
					MIN(rps.ThruDate),
					rps.Deleted,
					rps.Payment_Year
				FROM dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod rps
				WHERE rps.Deleted = 'A'
				GROUP BY rps.PlanIdentifier,
					rps.HICN,
					rps.RAFT,
					rps.HCC,
					rps.HCC_Number,
					rps.deleted,
					rps.Payment_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'059',
							0,
							1
							)
					WITH NOWAIT
				END

				--Loading Deletes
				INSERT INTO dbo.tbl_EstRecv_RAPS (
					PlanID,
					HICN,
					RAFT,
					[HCC],
					HCC_ORIG,
					HCC_ORIG_EstRecev,
					[HCC_Number],
					Min_Process_By,
					Min_Thru,
					Deleted,
					Payment_Year
					)
				SELECT DISTINCT rps.PlanIdentifier,
					rps.HICN,
					rps.RAFT,
					rps.HCC,
					rps.HCC,
					rps.HCC,
					rps.HCC_Number,
					MAX(rps.ProcessedBy),
					MAX(rps.ThruDate),
					rps.Deleted,
					rps.Payment_Year
				FROM dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod rps
				LEFT JOIN dbo.tbl_EstRecv_RAPS RpsAct ON RpsAct.PlanID = rps.PlanIdentifier
					AND RpsAct.HICN = rps.HICN
					AND RpsAct.RAFT = rps.RAFT
					AND RpsAct.[HCC] = rps.HCC
					AND RpsAct.[HCC_Number] = rps.HCC_Number
					AND RpsAct.Deleted = 'A'
					AND RpsAct.Payment_Year = rps.Payment_Year
				WHERE RpsAct.HCC IS NULL
					AND rps.Deleted = 'D'
				GROUP BY rps.PlanIdentifier,
					rps.HICN,
					rps.RAFT,
					rps.HCC,
					rps.HCC_Number,
					rps.deleted,
					rps.Payment_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'060',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Update Minumum ProcessBy SeqNum 
				UPDATE rps
				SET rps.[Min_ProcessBy_SeqNum] = drv.SeqNumber
				FROM dbo.tbl_EstRecv_RAPS rps
				INNER JOIN (
					SELECT MIN(diag.SeqNumber) 'SeqNumber',
						diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ProcessedBy
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod diag
					GROUP BY diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,MO
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ProcessedBy
					) drv ON rps.PlanID = drv.PlanIdentifier
					AND rps.HICN = drv.HICN
					AND rps.RAFT = drv.RAFT
					--and rps.HCC = drv.HCC
					AND rps.HCC_Number = drv.HCC_Number
					AND rps.deleted = drv.deleted
					AND rps.Payment_Year = drv.Payment_Year
					AND Min_Process_By = drv.ProcessedBy

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'061',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Update Minumum ProcessBy Diag ID 
				UPDATE rps
				SET rps.Min_Processby_DiagID = drv.RAPS_DiagHCC_rollupID
				FROM dbo.tbl_EstRecv_RAPS rps
				INNER JOIN (
					SELECT MIN(diag.RAPS_DiagHCC_rollupID) 'RAPS_DiagHCC_rollupID',
						diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ProcessedBy,
						diag.SeqNumber
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod diag
					GROUP BY diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ProcessedBy,
						diag.SeqNumber
					) drv ON rps.PlanID = drv.PlanIdentifier
					AND rps.HICN = drv.HICN
					AND rps.RAFT = drv.RAFT
					--and rps.HCC = drv.HCC
					AND rps.HCC_Number = drv.HCC_Number
					AND rps.deleted = drv.deleted
					AND rps.Payment_Year = drv.Payment_Year
					AND rps.Min_Process_By = drv.ProcessedBy
					AND rps.Min_ProcessBy_SeqNum = drv.SeqNumber

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'062',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Update Min_Processby_DiagCD, Min_ProcessBy_PCN
				UPDATE rps
				SET rps.Min_Processby_DiagCD = Diag.DiagnosisCode,
					rps.Min_ProcessBy_PCN = Diag.PatientControlNumber,
					rps.processed_priority_thru_date = Diag.ThruDate, -- Ticket # 25658
					/* Ticket # 25703 Start */
					rps.Processed_Priority_FileID = Diag.FileID,
					rps.Processed_Priority_RAPS_Source_ID = Diag.Source_Id,
					rps.Processed_Priority_Provider_ID = Diag.Provider_Id,
					rps.Processed_Priority_RAC = Diag.RAC
				/* Ticket # 25703 END */
				FROM dbo.tbl_EstRecv_RAPS rps
				INNER JOIN dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod Diag WITH (NOLOCK) ON Diag.RAPS_DiagHCC_rollupID = rps.Min_Processby_DiagID

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'063',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Update Minumum ThruDate SeqNum 
				UPDATE rps
				SET rps.Min_Thru_SeqNum = drv.SeqNumber
				FROM dbo.tbl_EstRecv_RAPS rps
				INNER JOIN (
					SELECT MIN(diag.SeqNumber) 'SeqNumber',
						diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ThruDate
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod diag
					GROUP BY diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ThruDate
					) drv ON rps.PlanID = drv.PlanIdentifier
					AND rps.HICN = drv.HICN
					AND rps.RAFT = drv.RAFT
					--and rps.HCC = drv.HCC
					AND rps.HCC_Number = drv.HCC_Number
					AND rps.deleted = drv.deleted
					AND rps.Payment_Year = drv.Payment_Year
					AND rps.Min_Thru = drv.ThruDate

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'064',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Update Minumum ThruDate Diag ID 
				UPDATE rps
				SET rps.Min_ThruDate_DiagID = drv.RAPS_DiagHCC_rollupID
				FROM dbo.tbl_EstRecv_RAPS rps
				INNER JOIN (
					SELECT MIN(diag.RAPS_DiagHCC_rollupID) 'RAPS_DiagHCC_rollupID',
						diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ThruDate,
						diag.SeqNumber
					FROM dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod diag
					GROUP BY diag.PlanIdentifier,
						diag.HICN,
						diag.RAFT,
						--diag.HCC,
						diag.HCC_Number,
						diag.deleted,
						diag.Payment_Year,
						diag.ThruDate,
						diag.SeqNumber
					) drv ON rps.PlanID = drv.PlanIdentifier
					AND rps.HICN = drv.HICN
					AND rps.RAFT = drv.RAFT
					--and rps.HCC = drv.HCC
					AND rps.HCC_Number = drv.HCC_Number
					AND rps.deleted = drv.deleted
					AND rps.Payment_Year = drv.Payment_Year
					AND rps.Min_Thru = drv.ThruDate
					AND rps.Min_Thru_SeqNum = drv.SeqNumber

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'065',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Update Min_ThruDate_DiagCD, Min_ThruDate_PCN
				UPDATE rps
				SET rps.Min_ThruDate_DiagCD = Diag.DiagnosisCode,
					rps.Min_ThruDate_PCN = Diag.PatientControlNumber,
					rps.thru_priority_processed_by = Diag.ProcessedBy, -- Ticket # 25658
					/* Ticket # 25703 Start */
					rps.Thru_Priority_FileID = Diag.FileID,
					rps.Thru_Priority_RAPS_Source_ID = Diag.Source_Id,
					rps.Thru_Priority_Provider_ID = Diag.Provider_Id,
					rps.Thru_Priority_RAC = Diag.RAC
				/* Ticket # 25703 END */
				FROM dbo.tbl_EstRecv_RAPS rps
				INNER JOIN dbo.tbl_EstRecv_RAPS_DiagHCC_RskMod Diag WITH (NOLOCK) ON Diag.RAPS_DiagHCC_rollupID = rps.Min_ThruDate_DiagID

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'066',
							0,
							1
							)
					WITH NOWAIT
				END

				/* IMPLEMENTING IMF LOGIC IN RAPS TABLE Ticket # 25703 Start */
				UPDATE dbo.tbl_EstRecv_RAPS
				SET IMFFlag = 3
				FROM dbo.tbl_EstRecv_RAPS
				WHERE Min_Process_By > @IMFMidProcessBy

				UPDATE dbo.tbl_EstRecv_RAPS
				SET IMFFlag = 2
				FROM dbo.tbl_EstRecv_RAPS
				WHERE (
						(
							Min_Process_By > @IMFInitialProcessBy
							AND Min_Process_By <= @IMFMidProcessBy
							)
						OR (
							Min_Process_By <= @IMFInitialProcessBy
							AND processed_priority_thru_date > @IMFDCPThrudate
							)
						)

				UPDATE dbo.tbl_EstRecv_RAPS
				SET IMFFlag = 1
				FROM dbo.tbl_EstRecv_RAPS
				WHERE (
						Min_Process_By <= @IMFInitialProcessBy
						AND processed_priority_thru_date <= @IMFDCPThrudate
						)

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'067',
							0,
							1
							)
					WITH NOWAIT
				END

				/* Ticket # 25703 END */
				-- Update Del HCC
				UPDATE dbo.tbl_EstRecv_RAPS
				SET HCC = 'DEL-' + HCC
				WHERE Deleted = 'D'

				UPDATE dbo.tbl_EstRecv_RAPS
				SET HCC_ORIG_EstRecev = 'DEL-' + HCC_ORIG_EstRecev
				WHERE Deleted = 'D'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'068',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Get HCC Hierarchy for different submission window ticket # 25703
				UPDATE drp
				SET drp.HCC_ORIG_EstRecev = 'HIER-' + drp.HCC_ORIG_EstRecev
				--,	drp.Factor = 0
				FROM tbl_EstRecv_RAPS drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = drp.Payment_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG_EstRecev, 3) = 'HCC'
				INNER JOIN tbl_EstRecv_RAPS kep ON kep.PlanID = drp.PlanID
					AND kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.Payment_Year = drp.Payment_Year
					AND left(kep.HCC_ORIG_EstRecev, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'069',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t1
				SET t1.HCC = t2.HCCNew
				FROM dbo.tbl_EstRecv_RAPS t1
				INNER JOIN (
					SELECT CASE 
							WHEN drp.IMFFlag >= kep.IMFFlag
								THEN 'HIER-' + drp.HCC
							ELSE drp.HCC
							END AS HCCNew,
						drp.HCC,
						drp.HICN,
						drp.IMFFlag,
						drp.Payment_Year,
						drp.Min_Process_By,
						drp.RAFT,
						drp.Min_Thru
					FROM dbo.tbl_EstRecv_RAPS drp
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
						AND Hier.Payment_Year = drp.Payment_Year
						AND Hier.RA_FACTOR_TYPE = drp.RAFT
						AND Hier.Part_C_D_Flag = 'C'
						AND left(Hier.HCC_DROP, 3) = 'HCC'
						AND left(drp.HCC, 3) = 'HCC'
					INNER JOIN dbo.tbl_EstRecv_RAPS kep ON kep.PlanID = drp.PlanID
						AND kep.HICN = drp.HICN
						AND kep.RAFT = drp.RAFT
						AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
						AND kep.Payment_Year = drp.Payment_Year
						--and kep.IMFFlag = drp.IMFFlag
						AND LEFT(kep.HCC, 3) = 'HCC'
					GROUP BY drp.HCC,
						drp.HICN,
						drp.IMFFlag,
						drp.Payment_Year,
						drp.Min_Process_By,
						drp.RAFT,
						drp.Min_Thru,
						kep.IMFFlag
					) t2 ON t1.HICN = t2.HICN
					AND t1.HCC = t2.HCC
					AND t1.IMFFlag = t2.IMFFlag
					AND t1.Payment_Year = t2.Payment_Year
					AND t1.Min_Process_By = t2.Min_Process_By
					AND t1.RAFT = t2.RAFT
					AND t1.Min_Thru = t2.Min_Thru

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'070',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t3
				SET t3.HCC = t2.HCCNew
				FROM tbl_EstRecv_RAPS t3
				INNER JOIN (
					SELECT ROW_NUMBER() OVER (
							PARTITION BY t1.HCC,
							t1.HICN,
							t1.IMFFlag,
							t1.Payment_Year,
							t1.Min_Process_By,
							t1.RAFT,
							t1.Min_Thru ORDER BY (t1.HICN)
							) AS RowNum,
						t1.HCC,
						t1.HCCNew,
						t1.HICN,
						t1.IMFFlag,
						t1.Payment_Year,
						t1.Min_Process_By,
						t1.RAFT,
						t1.Min_Thru
					FROM (
						SELECT drp.HCC,
							CASE 
								WHEN drp.IMFFlag < kep.IMFFlag
									THEN 'INCR-' + drp.HCC
								ELSE drp.HCC
								END AS HCCNew,
							drp.HICN,
							drp.IMFFlag,
							drp.Payment_Year,
							drp.Min_Process_By,
							drp.RAFT,
							drp.Min_Thru
						FROM dbo.tbl_EstRecv_RAPS drp
						INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_Number = drp.HCC_Number
							AND Hier.Payment_Year = drp.Payment_Year
							AND Hier.RA_FACTOR_TYPE = drp.RAFT
							AND Hier.Part_C_D_Flag = 'C'
							AND left(Hier.HCC_DROP, 3) = 'HCC'
							AND left(drp.HCC, 3) = 'HCC'
						INNER JOIN dbo.tbl_EstRecv_RAPS kep ON kep.HICN = drp.HICN
							AND kep.PlanID = drp.PlanID
							AND kep.RAFT = drp.RAFT
							AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
							AND kep.Payment_Year = drp.Payment_Year
							AND left(kep.HCC, 3) = 'HCC'
						) t1
					) t2 ON t2.HICN = t3.HICN
					AND t2.IMFFlag = t3.IMFFlag
					AND t2.Payment_Year = t3.Payment_Year
					AND t2.Min_Process_By = t3.Min_Process_By
					AND t2.RAFT = t3.RAFT
					AND t2.Min_Thru = t3.Min_Thru
					AND t2.HCC = t3.HCC
				WHERE t2.RowNum = 1

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'071',
							0,
							1
							)
					WITH NOWAIT
				END

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'072',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Get Highest HCC for interactions 
				--if OBJECT_ID('[dbo].[tbl_EstRecv_RAPS_Interactions]') is not null
				TRUNCATE TABLE dbo.tbl_EstRecv_RAPS_Interactions

				--CREATE TABLE [dbo].[tbl_EstRecv_RAPS_Interactions](
				--			[PlanID] [int] NULL,
				--			[HICN] [varchar](12) NULL,
				--			[RAFT] [varchar](3) NULL,
				--			[HCC] [varchar](50) NULL,
				--			[HCC_Number] [int] NULL,
				--			[HCC_Number1] [int] NULL,
				--			[HCC_Number2] [int] NULL,
				--			[HCC_Number3] [int] NULL,
				--			[Min_Process_By] [datetime] NULL,
				--			[Min_Thru] [datetime] NULL,
				--			[Min_ProcessBy_SeqNum] [int] NULL,
				--			[Min_Thru_SeqNum] [int] NULL,
				--			[Min_Processby_DiagID] [int] NULL,
				--			[Min_ThruDate_DiagID] [int] NULL,
				--			[Min_Processby_DiagCD] [varchar](7) NULL,
				--			[Min_ThruDate_DiagCD] [varchar](7) NULL,
				--			[Min_ProcessBy_PCN] [varchar](40) NULL,
				--			[Min_ThruDate_PCN] [varchar](40) NULL,
				--			[processed_priority_thru_date] [datetime] NULL,
				--			[thru_priority_processed_by] [datetime] NULL,
				--			[Payment_Year] [int] NULL,
				--			[Processed_Priority_FileID] [varchar](18) NULL,
				--			[Processed_Priority_RAPS_Source_ID] [int] NULL,
				--			[Processed_Priority_Provider_ID] [varchar](40) NULL,
				--			[Processed_Priority_RAC] [varchar](1) NULL,
				--			[Thru_Priority_FileID] [varchar](18) NULL,
				--			[Thru_Priority_RAPS_Source_ID] [int] NULL,
				--			[Thru_Priority_Provider_ID] [varchar](40) NULL,
				--			[Thru_Priority_RAC] [varchar](1) NULL,
				--			[IMFFlag] [smallint] NULL,
				--			[HCC_ORIG] [varchar](50) NULL,
				--			[HCC_ORIG_EstRecev] [varchar](50) NULL,
				--			Max_HCC_NumberMPD int,
				--			Max_HCC_NumberMTD int
				--		)
				INSERT INTO dbo.tbl_EstRecv_RAPS_Interactions (
					PlanID,
					HICN,
					RAFT,
					HCC,
					HCC_ORIG,
					HCC_ORIG_EstRecev,
					HCC_Number,
					HCC_Number1,
					HCC_Number2,
					HCC_Number3,
					Min_Process_By,
					Min_Thru,
					Payment_Year
					)
				SELECT DISTINCT rps.PlanID,
					rps.HICN,
					rps.RAFT,
					RskModIntr.Interaction_Label,
					RskModIntr.Interaction_Label,
					RskModIntr.Interaction_Label,
					CAST(RIGHT(RskModIntr.Interaction_Label, len(RskModIntr.Interaction_Label) - 3) AS INT) 'HCC_Number',
					RskModIntr.HCC_Number_1,
					RskModIntr.HCC_Number_2,
					RskModIntr.HCC_Number_3,
					m.Min_Process_By,
					m.[Min_Thru],
					RskModIntr.Payment_Year
				FROM [$(HRPReporting)].dbo.lk_Risk_Models_Interactions RskModIntr
				INNER JOIN dbo.tbl_EstRecv_RAPS rps ON rps.RAFT = RskModIntr.Factor_Type
					AND rps.Payment_Year = RskModIntr.Payment_Year
				INNER JOIN dbo.tbl_EstRecv_RAPS rpsHCC1 ON rpsHCC1.HCC_Number = RskModIntr.HCC_Number_1
					AND rpsHCC1.HICN = rps.HICN
					AND rpsHCC1.RAFT = rps.RAFT
					AND rpsHCC1.HCC NOT LIKE '%DEL%'
					AND rpsHCC1.Payment_Year = rps.Payment_Year
				INNER JOIN dbo.tbl_EstRecv_RAPS rpsHCC2 ON rpsHCC2.HCC_Number = RskModIntr.HCC_Number_2
					AND rpsHCC2.HICN = rps.HICN
					AND rpsHCC2.RAFT = rps.RAFT
					AND rpsHCC2.HCC NOT LIKE '%DEL%'
					AND rpsHCC2.Payment_Year = rps.Payment_Year
				INNER JOIN dbo.tbl_EstRecv_RAPS rpsHCC3 ON rpsHCC3.HCC_Number = RskModIntr.HCC_Number_3
					AND rpsHCC3.HICN = rps.HICN
					AND rpsHCC3.RAFT = rps.RAFT
					AND rpsHCC3.HCC NOT LIKE '%DEL%'
					AND rpsHCC3.Payment_Year = rps.Payment_Year
				INNER JOIN (
					SELECT rps.PlanID,
						rps.HICN,
						rps.RAFT,
						RskModIntr.Interaction_Label,
						CAST(RIGHT(RskModIntr.Interaction_Label, len(RskModIntr.Interaction_Label) - 3) AS INT) 'HCC_Number',
						(
							SELECT max([date])
							FROM (
								VALUES (min(rpsHCC1.Min_Process_By)),
									(min(rpsHCC2.Min_Process_By)),
									(min(rpsHCC3.Min_Process_By))
								) x([date])
							) 'Min_Process_By',
						(
							SELECT max([thrudate])
							FROM (
								VALUES (min(rpsHCC1.Min_Thru)),
									(min(rpsHCC2.Min_Thru)),
									(min(rpsHCC3.Min_Thru))
								) x([thrudate])
							) AS [Min_Thru],
						RskModIntr.Payment_Year
					FROM [$(HRPReporting)].dbo.lk_Risk_Models_Interactions RskModIntr
					INNER JOIN dbo.tbl_EstRecv_RAPS rps ON rps.RAFT = RskModIntr.Factor_Type
						AND rps.Payment_Year = RskModIntr.Payment_Year
					INNER JOIN tbl_EstRecv_RAPS rpsHCC1 ON rpsHCC1.HCC_Number = RskModIntr.HCC_Number_1
						AND rpsHCC1.HICN = rps.HICN
						AND rpsHCC1.RAFT = rps.RAFT
						AND rpsHCC1.HCC NOT LIKE '%DEL%'
						AND rpsHCC1.Payment_Year = rps.Payment_Year
					INNER JOIN tbl_EstRecv_RAPS rpsHCC2 ON rpsHCC2.HCC_Number = RskModIntr.HCC_Number_2
						AND rpsHCC2.HICN = rps.HICN
						AND rpsHCC2.RAFT = rps.RAFT
						AND rpsHCC2.HCC NOT LIKE '%DEL%'
						AND rpsHCC2.Payment_Year = rps.Payment_Year
					INNER JOIN tbl_EstRecv_RAPS rpsHCC3 ON rpsHCC3.HCC_Number = RskModIntr.HCC_Number_3
						AND rpsHCC3.HICN = rps.HICN
						AND rpsHCC3.RAFT = rps.RAFT
						AND rpsHCC3.HCC NOT LIKE '%DEL%'
						AND rpsHCC3.Payment_Year = rps.Payment_Year
					GROUP BY rps.PlanID,
						rps.HICN,
						rps.RAFT,
						RskModIntr.Interaction_Label,
						RskModIntr.Payment_Year
					) m ON rps.PlanID = m.PlanID
					AND rps.HICN = m.HICN
					AND rps.RAFT = m.RAFT
					AND RskModIntr.Payment_Year = m.Payment_Year
					AND RskModIntr.Interaction_Label = m.Interaction_Label

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'073',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE i
				SET Max_HCC_NumberMPD = t4.HCC_Number
				FROM dbo.tbl_EstRecv_RAPS_Interactions i
				INNER JOIN (
					SELECT RowNum,
						HICN,
						PlanID,
						RAFT,
						Payment_Year,
						HCC,
						HCC_Number,
						Min_Process_By,
						Min_ProcessBy_SeqNum
					FROM (
						SELECT row_number() OVER (
								PARTITION BY HICN,
								PlanID,
								RAFT,
								Payment_Year,
								HCC,
								Min_Process_By ORDER BY Min_ProcessBy_SeqNum DESC
								) AS RowNum,
							HICN,
							PlanID,
							RAFT,
							Payment_Year,
							HCC,
							HCC_Number,
							Min_Process_By,
							Min_ProcessBy_SeqNum
						FROM (
							SELECT raps.HICN,
								raps.PlanID,
								raps.RAFT,
								raps.Payment_Year,
								t1.HCC,
								raps.HCC_Number,
								MAX(raps.Min_ProcessBy_SeqNum) AS Min_ProcessBy_SeqNum,
								raps.Min_Process_By
							FROM dbo.tbl_EstRecv_RAPS raps
							INNER JOIN dbo.tbl_EstRecv_RAPS_Interactions t1 ON t1.PlanID = raps.PlanID
								AND t1.HICN = raps.HICN
								AND t1.RAFT = raps.RAFT
								AND raps.HCC_Number IN (
									t1.HCC_Number1,
									t1.HCC_Number2,
									t1.HCC_Number3
									)
								AND t1.Min_Process_By = raps.Min_Process_By
								AND t1.Payment_Year = raps.Payment_Year
							GROUP BY raps.HCC_Number,
								t1.HCC,
								raps.Min_Process_By,
								raps.HICN,
								raps.PlanID,
								raps.RAFT,
								raps.Payment_Year
							) t2
						) t3
					WHERE t3.RowNum = 1
					) t4 ON i.HCC = t4.HCC
					AND i.HICN = t4.HICN
					AND i.PlanID = t4.PlanID
					AND i.RAFT = t4.RAFT
					AND i.Payment_Year = t4.Payment_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'074',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE i
				SET Max_HCC_NumberMTD = t4.HCC_Number
				FROM dbo.tbl_EstRecv_RAPS_Interactions i
				INNER JOIN (
					SELECT RowNum,
						HICN,
						PlanID,
						RAFT,
						Payment_Year,
						HCC,
						HCC_Number,
						Min_Thru,
						Min_Thru_SeqNum
					FROM (
						SELECT row_number() OVER (
								PARTITION BY HICN,
								PlanID,
								RAFT,
								Payment_Year,
								HCC,
								Min_Thru ORDER BY Min_Thru_SeqNum DESC
								) AS RowNum,
							HICN,
							PlanID,
							RAFT,
							Payment_Year,
							HCC,
							HCC_Number,
							Min_Thru,
							Min_Thru_SeqNum
						FROM (
							SELECT raps.HICN,
								raps.PlanID,
								raps.RAFT,
								raps.Payment_Year,
								t1.HCC,
								raps.HCC_Number,
								MAX(raps.Min_Thru_SeqNum) AS Min_Thru_SeqNum,
								raps.Min_Thru
							FROM dbo.tbl_EstRecv_RAPS raps
							INNER JOIN dbo.tbl_EstRecv_RAPS_Interactions t1 ON t1.PlanID = raps.PlanID
								AND t1.HICN = raps.HICN
								AND t1.RAFT = raps.RAFT
								AND raps.HCC_Number IN (
									t1.HCC_Number1,
									t1.HCC_Number2,
									t1.HCC_Number3
									)
								AND t1.Min_Thru = raps.Min_Thru
								AND t1.Payment_Year = raps.Payment_Year
							GROUP BY raps.HCC_Number,
								t1.HCC,
								raps.Min_Thru,
								raps.HICN,
								raps.PlanID,
								raps.RAFT,
								raps.Payment_Year
							) t2
						) t3
					WHERE t3.RowNum = 1
					) t4 ON i.HCC = t4.HCC
					AND i.HICN = t4.HICN
					AND i.PlanID = t4.PlanID
					AND i.RAFT = t4.RAFT
					AND i.Payment_Year = t4.Payment_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'075',
							0,
							1
							)
					WITH NOWAIT
				END

				/* This Deletes interaction that have a higher HCC that does not participate in a interaction. */
				DELETE i
				FROM dbo.tbl_EstRecv_RAPS_Interactions i
				INNER JOIN (
					SELECT i.*
					FROM dbo.tbl_EstRecv_RAPS_Interactions i
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy h ON (
							i.HCC_Number1 = h.HCC_DROP_NUMBER
							OR i.HCC_Number2 = h.HCC_DROP_NUMBER
							OR i.HCC_Number3 = h.HCC_DROP_NUMBER
							)
						AND i.RAFT = h.RA_FACTOR_TYPE
						AND i.Payment_Year = h.Payment_Year
					INNER JOIN dbo.tbl_EstRecv_RAPS r ON h.HCC_KEEP_NUMBER = r.HCC_Number
						AND i.HICN = r.HICN
						AND i.Payment_Year = r.Payment_Year
						AND i.PlanID = r.PlanID
						AND i.RAFT = r.RAFT
					WHERE isnumeric(h.HCC_DROP_NUMBER) = 1
						AND h.HCC_KEEP_NUMBER NOT IN (
							i.HCC_Number1,
							i.HCC_Number2,
							i.HCC_Number3
							)
					) i1 ON i.HICN = i1.HICN
					AND i.RAFT = i1.RAFT
					AND i.HCC_Number1 = i1.HCC_Number1
					AND i.HCC_Number2 = i1.HCC_Number2
					AND i.HCC_Number3 = i1.HCC_Number3
					AND i.PlanID = i1.PlanID
					AND i.HCC = i1.HCC
					AND i.Min_Process_By = i1.Min_Process_By
					AND i.Min_Thru = i1.Min_Thru
					AND i.IMFFlag = i1.IMFFlag
					AND i.Min_ProcessBy_SeqNum = i1.Min_ProcessBy_SeqNum
					AND i.Min_Thru_SeqNum = i1.Min_Thru_SeqNum
					AND i.Processed_Priority_FileID = i1.Processed_Priority_FileID

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'076',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Get Disease Interactions
				--select * from dbo.tbl_EstRecv_RAPS_Interactions
				/* Min Process By Interaction Update */
				UPDATE u1
				SET Min_ProcessBy_SeqNum = u2.Min_ProcessBy_SeqNum,
					Min_Processby_DiagID = u2.Min_Processby_DiagID,
					Min_Processby_DiagCD = u2.Min_Processby_DiagCD,
					Min_ProcessBy_PCN = u2.Min_ProcessBy_PCN,
					processed_priority_thru_date = u2.processed_priority_thru_date,
					Processed_Priority_FileID = u2.Processed_Priority_FileID,
					Processed_Priority_RAPS_Source_ID = u2.Processed_Priority_RAPS_Source_ID,
					Processed_Priority_Provider_ID = u2.Processed_Priority_Provider_ID,
					Processed_Priority_RAC = u2.Processed_Priority_RAC
				FROM dbo.tbl_EstRecv_RAPS_Interactions u1
				INNER JOIN (
					SELECT row_Number() OVER (
							PARTITION BY raps.HICN,
							raps.Raft,
							raps.PlanID,
							raps.Min_Process_By,
							raps.Min_Thru,
							it.HCC_Number1,
							it.HCC_Number2,
							it.HCC_Number3 ORDER BY raps.Min_ProcessBy_SeqNum DESC
							) AS RowNum,
						raps.Min_ProcessBy_SeqNum,
						raps.Min_Processby_DiagID,
						raps.Min_Processby_DiagCD,
						raps.Min_ProcessBy_PCN,
						raps.processed_priority_thru_date,
						raps.Processed_Priority_FileID,
						raps.Processed_Priority_RAPS_Source_ID,
						raps.Processed_Priority_Provider_ID,
						raps.Processed_Priority_RAC,
						raps.HICN,
						raps.PlanID,
						raps.Payment_Year,
						raps.RAFT,
						raps.Min_Process_By,
						it.HCC_Number,
						it.HCC_Number1,
						it.HCC_Number2,
						it.HCC_Number3
					FROM dbo.tbl_EstRecv_RAPS raps
					INNER JOIN dbo.tbl_EstRecv_RAPS_Interactions it ON raps.HICN = it.HICN
						AND raps.PlanID = it.PlanID
						AND raps.RAFT = it.RAFT
						AND raps.Min_Process_By = it.Min_Process_By
						AND raps.HCC_Number = it.Max_HCC_NumberMPD
					) u2 ON u1.HICN = u2.HICN
					AND u1.PlanID = u2.PlanID
					AND u1.RAFT = u2.RAFT
					AND u1.Payment_Year = u2.Payment_Year
					AND u1.HCC_Number = u2.HCC_Number
					AND u1.HCC_Number1 = u2.HCC_Number1
					AND u1.HCC_Number2 = u2.HCC_Number2
					AND u1.HCC_Number3 = u2.HCC_Number3
				WHERE u2.RowNum = 1

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'077',
							0,
							1
							)
					WITH NOWAIT
				END

				/* Min Thru Interaction Update */
				UPDATE u1
				SET Min_Thru_SeqNum = u2.Min_Thru_SeqNum,
					Min_ThruDate_DiagID = u2.Min_ThruDate_DiagID,
					Min_ThruDate_DiagCD = u2.Min_ThruDate_DiagCD,
					Min_ThruDate_PCN = u2.Min_ThruDate_PCN,
					thru_priority_processed_by = u2.thru_priority_processed_by,
					Thru_Priority_FileID = u2.Thru_Priority_FileID,
					Thru_Priority_RAPS_Source_ID = u2.Thru_Priority_RAPS_Source_ID,
					Thru_Priority_Provider_ID = u2.Thru_Priority_Provider_ID,
					Thru_Priority_RAC = u2.Thru_Priority_RAC
				FROM dbo.tbl_EstRecv_RAPS_Interactions u1
				INNER JOIN (
					SELECT row_Number() OVER (
							PARTITION BY raps.HICN,
							raps.Raft,
							raps.PlanID,
							raps.Min_Process_By,
							raps.Min_Thru,
							it.HCC_Number1,
							it.HCC_Number2,
							it.HCC_Number3 ORDER BY raps.Min_Thru_SeqNum DESC
							) AS RowNum,
						raps.Min_Thru_SeqNum,
						raps.Min_ThruDate_DiagID,
						raps.Min_ThruDate_DiagCD,
						raps.Min_ThruDate_PCN,
						raps.thru_priority_processed_by,
						raps.Thru_Priority_FileID,
						raps.Thru_Priority_RAPS_Source_ID,
						raps.Thru_Priority_Provider_ID,
						raps.Thru_Priority_RAC,
						raps.HICN,
						raps.PlanID,
						raps.Payment_Year,
						raps.RAFT,
						raps.Min_Thru,
						it.HCC_Number,
						it.HCC_Number1,
						it.HCC_Number2,
						it.HCC_Number3
					FROM dbo.tbl_EstRecv_RAPS raps
					INNER JOIN dbo.tbl_EstRecv_RAPS_Interactions it ON raps.HICN = it.HICN
						AND raps.PlanID = it.PlanID
						AND raps.RAFT = it.RAFT
						AND raps.Min_Thru = it.Min_Thru
						AND raps.HCC_Number = it.Max_HCC_NumberMTD
					) u2 ON u1.HICN = u2.HICN
					AND u1.PlanID = u2.PlanID
					AND u1.RAFT = u2.RAFT
					AND u1.Payment_Year = u2.Payment_Year
					AND u1.HCC_Number = u2.HCC_Number
				WHERE u2.RowNum = 1

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'078',
							0,
							1
							)
					WITH NOWAIT
				END

				/* IMPLEMENTING IMF LOGIC IN RAPS Interactions TABLE Ticket # 25703 Start */
				UPDATE i
				SET IMFFlag = 3
				FROM dbo.tbl_EstRecv_RAPS_Interactions i
				WHERE Min_Process_By > @IMFMidProcessBy

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'079',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE i
				SET IMFFlag = 2
				FROM dbo.tbl_EstRecv_RAPS_Interactions i
				WHERE (
						(
							Min_Process_By > @IMFInitialProcessBy
							AND Min_Process_By <= @IMFMidProcessBy
							)
						OR (
							Min_Process_By <= @IMFInitialProcessBy
							AND processed_priority_thru_date > @IMFDCPThrudate
							)
						)

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'080',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE i
				SET IMFFlag = 1
				FROM dbo.tbl_EstRecv_RAPS_Interactions i
				WHERE (
						Min_Process_By <= @IMFInitialProcessBy
						AND processed_priority_thru_date <= @IMFDCPThrudate
						)

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'081',
							0,
							1
							)
					WITH NOWAIT
				END

				/* Ticket # 25703 END */
				/* Interaction Heirachy Begin */
				UPDATE drp
				SET drp.HCC_ORIG_EstRecev = 'HIER-' + drp.HCC_ORIG_EstRecev
				--,   drp.Factor = 0
				FROM tbl_EstRecv_RAPS_Interactions drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP = drp.HCC_ORIG_EstRecev
					AND Hier.Payment_Year = drp.Payment_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG_EstRecev, 3) = 'INT'
				INNER JOIN tbl_EstRecv_RAPS_Interactions kep ON kep.PlanID = drp.PlanID
					AND kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC = Hier.HCC_KEEP
					AND kep.Payment_Year = drp.Payment_Year
					AND left(kep.HCC_ORIG_EstRecev, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'082',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t1
				SET t1.HCC = t2.HCCNew
				FROM dbo.tbl_EstRecv_RAPS_Interactions t1
				INNER JOIN (
					SELECT 'HIER-' + drp.HCC AS HCCNew,
						drp.HCC,
						drp.HICN,
						drp.IMFFlag,
						drp.Payment_Year,
						drp.Min_Process_By,
						drp.RAFT,
						drp.Min_Thru
					FROM dbo.tbl_EstRecv_RAPS_Interactions drp
					INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
						AND Hier.Payment_Year = drp.Payment_Year
						AND Hier.RA_FACTOR_TYPE = drp.RAFT
						AND Hier.Part_C_D_Flag = 'C'
						AND left(Hier.HCC_DROP, 3) = 'INT'
						AND left(drp.HCC, 3) = 'INT'
					INNER JOIN dbo.tbl_EstRecv_RAPS_Interactions kep ON kep.PlanID = drp.PlanID
						AND kep.HICN = drp.HICN
						AND kep.RAFT = drp.RAFT
						AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
						AND kep.Payment_Year = drp.Payment_Year
						AND LEFT(kep.HCC, 3) = 'INT'
					GROUP BY drp.HCC,
						drp.HICN,
						drp.IMFFlag,
						drp.Payment_Year,
						drp.Min_Process_By,
						drp.RAFT,
						drp.Min_Thru,
						drp.IMFFlag
					) t2 ON t1.HICN = t2.HICN
					AND t1.HCC = t2.HCC
					AND t1.IMFFlag = t2.IMFFlag
					AND t1.Payment_Year = t2.Payment_Year
					AND t1.Min_Process_By = t2.Min_Process_By
					AND t1.RAFT = t2.RAFT
					AND t1.Min_Thru = t2.Min_Thru

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'083',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t3
				SET t3.HCC = t2.HCCNew
				FROM dbo.tbl_EstRecv_RAPS_Interactions t3
				INNER JOIN (
					SELECT ROW_NUMBER() OVER (
							PARTITION BY t1.HCC,
							t1.HICN,
							t1.IMFFlag,
							t1.Payment_Year,
							t1.Min_Process_By,
							t1.RAFT,
							t1.Min_Thru ORDER BY (t1.HICN)
							) AS RowNum,
						t1.HCC,
						t1.HCCNew,
						t1.HICN,
						t1.IMFFlag,
						t1.Payment_Year,
						t1.Min_Process_By,
						t1.RAFT,
						t1.Min_Thru
					FROM (
						SELECT drp.HCC,
							CASE 
								WHEN drp.IMFFlag < kep.IMFFlag
									THEN 'INCR-' + drp.HCC
								ELSE 'HIER-' + drp.HCC
								END AS HCCNew,
							drp.HICN,
							drp.IMFFlag,
							drp.Payment_Year,
							drp.Min_Process_By,
							drp.RAFT,
							drp.Min_Thru
						FROM dbo.tbl_EstRecv_RAPS_Interactions drp
						INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
							AND Hier.Payment_Year = drp.Payment_Year
							AND Hier.RA_FACTOR_TYPE = drp.RAFT
							AND Hier.Part_C_D_Flag = 'C'
							AND left(Hier.HCC_DROP, 3) = 'INT'
							AND left(drp.HCC, 3) = 'INT'
						INNER JOIN dbo.tbl_EstRecv_RAPS kep ON kep.HICN = drp.HICN
							AND kep.PlanID = drp.PlanID
							AND kep.RAFT = drp.RAFT
							AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
							AND kep.Payment_Year = drp.Payment_Year
							AND left(kep.HCC, 3) = 'INT'
						) t1
					) t2 ON t2.HICN = t3.HICN
					AND t2.IMFFlag = t3.IMFFlag
					AND t2.Payment_Year = t3.Payment_Year
					AND t2.Min_Process_By = t3.Min_Process_By
					AND t2.RAFT = t3.RAFT
					AND t2.Min_Thru = t3.Min_Thru
					AND t2.HCC = t3.HCC
				WHERE t2.RowNum = 1

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'084',
							0,
							1
							)
					WITH NOWAIT
				END

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'085',
							0,
							1
							)
					WITH NOWAIT
				END

				/* Interaction Heirachy End */
				---- Get Hierarchy Interactions
				--update drp
				--set drp.HCC = 'HIER-' + drp.HCC
				----,	drp.Factor = 0
				--from dbo.tbl_EstRecv_RAPS_Interactions drp
				--inner join [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier
				--on Hier.HCC_DROP = drp.HCC	
				--and Hier.Payment_Year = drp.Payment_Year
				--and Hier.RA_FACTOR_TYPE = drp.RAFT
				--and Hier.Part_C_D_Flag = 'C'
				--and left(Hier.HCC_DROP,3) = 'INT' 
				--and left(drp.HCC,3) = 'INT'
				--inner join dbo.tbl_EstRecv_RAPS_Interactions kep
				--on 	kep.PlanID = drp.PlanID
				--and kep.HICN = drp.HICN
				--and kep.RAFT = drp.RAFT
				--and kep.HCC = Hier.HCC_KEEP		
				--and kep.Payment_Year = drp.Payment_Year
				--and left(kep.HCC,3) = 'INT'
				IF OBJECT_ID('[TEMPDB].[DBO].[#InteractionsRank]', 'U') IS NOT NULL
					DROP TABLE dbo.#InteractionsRank

				CREATE TABLE dbo.#InteractionsRank (
					ID INT identity(1, 1) PRIMARY KEY NOT NULL,
					HICN VARCHAR(12),
					RAFT VARCHAR(3),
					HCC VARCHAR(50),
					Min_ProcessBy_SeqNum INT,
					Min_Thru_SeqNum INT,
					Min_Processby_DiagCD VARCHAR(7),
					Min_ThruDate_DiagCD VARCHAR(7),
					RankID INT
					)

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'086',
							0,
							1
							)
					WITH NOWAIT
				END

				--select top 1 * 
				--into dbo.tbl_EstRecv_RAPS_Interactions	from tbl_EstRecv_RAPS_Interactions	
				--truncate table dbo.tbl_EstRecv_RAPS_Interactions	
				INSERT INTO dbo.#InteractionsRank
				SELECT DISTINCT HICN,
					RAFT,
					HCC,
					Min_ProcessBy_SeqNum,
					Min_Thru_SeqNum,
					Min_Processby_DiagCD,
					Min_ThruDate_DiagCD,
					RANK() OVER (
						PARTITION BY HICN,
						RAFT,
						HCC ORDER BY Min_ProcessBy_SeqNum,
							Min_Thru_SeqNum,
							Min_Processby_DiagCD,
							Min_ThruDate_DiagCD
						)
				FROM dbo.tbl_EstRecv_RAPS_Interactions
				WHERE (
						Min_ProcessBy_SeqNum IS NOT NULL
						AND Min_Thru_SeqNum IS NOT NULL
						)

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'087',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Insert HCCs/HIER into dbo.tbl_EstRecv_RiskFactorsRAPS 
				--select top 1 * into dbo.tbl_EstRecv_RiskFactorsRAPS from tbl_EstRecv_RiskFactorsRAPS
				--truncate table dbo.tbl_EstRecv_RiskFactorsRAPS
				INSERT INTO dbo.tbl_EstRecv_RiskFactorsRAPS (
					PlanID,
					HICN,
					PaymentYear,
					PaymStart,
					Model_Year,
					Factor_category,
					Factor_Desc,
					Factor_Desc_ORIG,
					Factor_Desc_EstRecev,
					Factor,
					HCC_Number,
					RAFT,
					RAFT_ORIG,
					Min_ProcessBy,
					Min_ThruDate,
					Min_ProcessBy_SeqNum,
					Min_ThruDate_SeqNum,
					Min_Processby_DiagCD,
					Min_ThruDate_DiagCD,
					Min_ProcessBy_PCN,
					Min_ThruDate_PCN,
					processed_priority_thru_date, -- Ticket # 25658
					thru_priority_processed_by, -- Ticket # 25658
					/* Ticket # 25703 Start */
					Processed_Priority_FileID,
					Processed_Priority_RAPS_Source_ID,
					Processed_Priority_Provider_ID,
					Processed_Priority_RAC,
					Thru_Priority_FileID,
					Thru_Priority_RAPS_Source_ID,
					Thru_Priority_Provider_ID,
					Thru_Priority_RAC,
					IMFFlag
					)
				SELECT DISTINCT mmr.PlanID, -- Ticket # 25315
					RskFct.HICN,
					mmr.Payment_Year,
					mmr.PaymStart,
					RskFct.Payment_Year,
					'RAPS',
					RskFct.HCC,
					RskFct.HCC_ORIG,
					RskFct.HCC_ORIG_EstRecev,
					rskmod.Factor,
					RskFct.HCC_Number,
					mmr.RAFT,
					mmr.RAFT_ORIG,
					RskFct.Min_Process_By,
					RskFct.Min_Thru,
					RskFct.Min_ProcessBy_SeqNum,
					RskFct.Min_Thru_SeqNum,
					RskFct.Min_Processby_DiagCD,
					RskFct.Min_ThruDate_DiagCD,
					RskFct.Min_ProcessBy_PCN,
					RskFct.Min_ThruDate_PCN,
					RskFct.processed_priority_thru_date, -- Ticket # 25658
					RskFct.thru_priority_processed_by, -- Ticket # 25658
					RskFct.Processed_Priority_FileID,
					RskFct.Processed_Priority_RAPS_Source_ID,
					RskFct.Processed_Priority_Provider_ID,
					RskFct.Processed_Priority_RAC,
					RskFct.Thru_Priority_FileID,
					RskFct.Thru_Priority_RAPS_Source_ID,
					RskFct.Thru_Priority_Provider_ID,
					RskFct.Thru_Priority_RAC,
					RskFct.IMFFlag
				/* Ticket # 25703 END */
				FROM #tbl_EstRecv_MMR mmr
				INNER JOIN dbo.tbl_EstRecv_RAPS RskFct ON RskFct.HICN = mmr.HICN
					AND RskFct.RAFT = mmr.RAFT
				INNER JOIN [$(HRPReporting)].dbo.lk_risk_models RskMod ON RskMod.Payment_Year = RskFct.Payment_Year
					AND cast(substring(RskMod.Factor_Description, 4, LEN(RskMod.Factor_Description) - 3) AS INT) = RskFct.HCC_Number
					AND RskMod.OREC = mmr.OREC_CALC
					AND RskMod.Factor_Type = mmr.RAFT
				WHERE RskMod.Part_C_D_Flag = 'C'
					AND RskMod.Demo_Risk_Type = 'Risk'
					AND RskMod.Factor_Description LIKE 'HCC%'
					AND RskFct.Payment_Year = @Model_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'088',
							0,
							1
							)
					WITH NOWAIT
				END

				--and mmr.Payment_Year = @Payment_Year
				--Insert Interaction into tbl_EstRecv_RiskFactorsRAPS
				INSERT INTO dbo.tbl_EstRecv_RiskFactorsRAPS (
					PlanID,
					HICN,
					PaymentYear,
					PaymStart,
					Model_Year,
					Factor_category,
					Factor_Desc,
					Factor_Desc_ORIG,
					Factor_Desc_EstRecev,
					Factor,
					HCC_Number,
					RAFT,
					RAFT_ORIG,
					Min_ProcessBy,
					Min_ThruDate,
					Min_ProcessBy_SeqNum,
					Min_ThruDate_SeqNum,
					Min_Processby_DiagCD,
					Min_ThruDate_DiagCD,
					Min_ProcessBy_PCN,
					Min_ThruDate_PCN,
					processed_priority_thru_date, -- Ticket # 25658
					thru_priority_processed_by, -- Ticket # 25658
					/* Ticket # 25703 Start */
					Processed_Priority_FileID,
					Processed_Priority_RAPS_Source_ID,
					Processed_Priority_Provider_ID,
					Processed_Priority_RAC,
					Thru_Priority_FileID,
					Thru_Priority_RAPS_Source_ID,
					Thru_Priority_Provider_ID,
					Thru_Priority_RAC,
					IMFFlag
					)
				SELECT DISTINCT mmr.PlanID, -- Ticket # 25315
					Intr.HICN,
					mmr.Payment_Year,
					mmr.PaymStart,
					Intr.Payment_Year,
					'RAPS-Interaction',
					Intr.HCC,
					Intr.HCC_ORIG,
					Intr.HCC_ORIG_EstRecev,
					rskmod.Factor,
					Intr.HCC_Number,
					mmr.RAFT,
					mmr.RAFT_ORIG,
					Intr.Min_Process_By,
					Intr.Min_Thru,
					Intr.Min_ProcessBy_SeqNum,
					Intr.Min_Thru_SeqNum,
					Intr.Min_Processby_DiagCD,
					Intr.Min_ThruDate_DiagCD,
					Intr.Min_ProcessBy_PCN,
					Intr.Min_ThruDate_PCN,
					Intr.processed_priority_thru_date, -- Ticket # 25658
					Intr.thru_priority_processed_by, -- Ticket # 25658
					Intr.Processed_Priority_FileID,
					Intr.Processed_Priority_RAPS_Source_ID,
					Intr.Processed_Priority_Provider_ID,
					Intr.Processed_Priority_RAC,
					Intr.Thru_Priority_FileID,
					Intr.Thru_Priority_RAPS_Source_ID,
					Intr.Thru_Priority_Provider_ID,
					Intr.Thru_Priority_RAC,
					Intr.IMFFlag
				/* Ticket # 25703 END */
				FROM #tbl_EstRecv_MMR mmr
				INNER JOIN dbo.tbl_EstRecv_RAPS_Interactions Intr ON Intr.HICN = mmr.HICN
					AND Intr.RAFT = mmr.RAFT
				INNER JOIN dbo.#InteractionsRank drvIntr ON Intr.HICN = drvIntr.HICN
					AND Intr.RAFT = drvIntr.RAFT
					AND Intr.HCC = drvIntr.HCC
					AND Intr.Min_ProcessBy_SeqNum = drvIntr.Min_ProcessBy_SeqNum
					AND Intr.Min_Thru_SeqNum = drvIntr.Min_Thru_SeqNum -- Ticket # 25353
					AND Intr.Min_Processby_DiagCD = drvIntr.Min_Processby_DiagCD
					AND Intr.Min_ThruDate_DiagCD = drvIntr.Min_ThruDate_DiagCD
				INNER JOIN [$(HRPReporting)].dbo.lk_risk_models RskMod ON RskMod.Payment_Year = Intr.Payment_Year
					AND CAST(RIGHT(RskMod.Factor_Description, len(RskMod.Factor_Description) - 3) AS INT) = Intr.HCC_Number
					AND RskMod.OREC = mmr.OREC_CALC
					AND RskMod.Factor_Type = mmr.RAFT
				WHERE RskMod.Part_C_D_Flag = 'C'
					AND RskMod.Demo_Risk_Type = 'Risk'
					AND RskMod.Factor_Description LIKE 'INT%'
					AND Intr.Payment_Year = @Model_Year
					AND drvIntr.RankID = 1

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'089',
							0,
							1
							)
					WITH NOWAIT
				END

				--and mmr.Payment_Year = @Payment_Year
				-- Get disability interactions
				INSERT INTO dbo.tbl_EstRecv_RiskFactorsRAPS (
					PlanID,
					HICN,
					PaymentYear,
					PaymStart,
					Model_Year,
					Factor_category,
					Factor_Desc,
					Factor_Desc_ORIG,
					Factor_Desc_EstRecev,
					Factor,
					HCC_Number,
					RAFT,
					RAFT_ORIG,
					Min_ProcessBy,
					Min_ThruDate,
					Min_ProcessBy_SeqNum,
					Min_ThruDate_SeqNum,
					Min_Processby_DiagCD,
					Min_ThruDate_DiagCD,
					Min_ProcessBy_PCN,
					Min_ThruDate_PCN,
					processed_priority_thru_date, -- Ticket # 25658
					thru_priority_processed_by, -- Ticket # 25658
					/* Ticket # 25703 Start */
					Processed_Priority_FileID,
					Processed_Priority_RAPS_Source_ID,
					Processed_Priority_Provider_ID,
					Processed_Priority_RAC,
					Thru_Priority_FileID,
					Thru_Priority_RAPS_Source_ID,
					Thru_Priority_Provider_ID,
					Thru_Priority_RAC,
					IMFFlag
					)
				SELECT DISTINCT mmr.PlanID, -- Ticket # 25315
					RskFct.HICN,
					mmr.Payment_Year,
					mmr.PaymStart,
					RskFct.Payment_Year,
					'RAPS-Disability',
					RskMod.Factor_Description,
					RskMod.Factor_Description,
					RskMod.Factor_Description,
					rskmod.Factor,
					RskFct.HCC_Number,
					mmr.RAFT,
					mmr.RAFT_ORIG,
					RskFct.Min_Process_By,
					RskFct.Min_Thru,
					RskFct.Min_ProcessBy_SeqNum,
					RskFct.Min_Thru_SeqNum,
					RskFct.Min_Processby_DiagCD,
					RskFct.Min_ThruDate_DiagCD,
					RskFct.Min_ProcessBy_PCN,
					RskFct.Min_ThruDate_PCN,
					RskFct.processed_priority_thru_date, -- Ticket # 25658
					RskFct.thru_priority_processed_by, -- Ticket # 25658
					RskFct.Processed_Priority_FileID,
					RskFct.Processed_Priority_RAPS_Source_ID,
					RskFct.Processed_Priority_Provider_ID,
					RskFct.Processed_Priority_RAC,
					RskFct.Thru_Priority_FileID,
					RskFct.Thru_Priority_RAPS_Source_ID,
					RskFct.Thru_Priority_Provider_ID,
					RskFct.Thru_Priority_RAC,
					RskFct.IMFFlag
				/* Ticket # 25703 END */
				FROM #tbl_EstRecv_MMR mmr
				INNER JOIN dbo.tbl_EstRecv_RAPS RskFct ON RskFct.HICN = mmr.HICN
					AND RskFct.RAFT = mmr.RAFT
				INNER JOIN [$(HRPReporting)].dbo.lk_risk_models RskMod ON RskMod.Payment_Year = RskFct.Payment_Year
					AND cast(substring(RskMod.Factor_Description, 6, len(RskMod.Factor_Description) - 5) AS INT) = RskFct.HCC_Number
					AND RskMod.OREC = '9999'
					AND RskMod.Factor_Type = mmr.RAFT
				WHERE RskMod.Part_C_D_Flag = 'C'
					AND RskMod.Demo_Risk_Type = 'Risk'
					AND RskMod.Factor_Description LIKE 'D-HCC%'
					AND RskFct.HCC LIKE 'HCC%'
					AND RskFct.Payment_Year = @Model_Year
					--and mmr.Payment_Year = @Payment_Year
					AND mmr.AgeGrp < '6565'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'090',
							0,
							1
							)
					WITH NOWAIT
				END
			END

			SELECT @maxPayMStart = MAX(month(paymstart))
			FROM tbl_EstRecv_RiskFactorsMOR
			WHERE PaymentYear = @Payment_year
				AND Model_Year = @Model_Year

			IF @Debug = 1
			BEGIN
				PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

				SET @ET = GETDATE()

				RAISERROR (
						'091',
						0,
						1
						)
				WITH NOWAIT
			END

			/* 32890 Had to change the HCC temp tables size is being update to match the table DDL. */
-- Start #43205 Changes to Paymonth for 2015 PY from variable
			IF @maxPayMStart >= @Paymonth_MOR --#43205 @PayMonthMOR
			BEGIN
				--declare @Payment_year int = 2013,@Model_Year int = 2013
				IF OBJECT_ID('[TEMPDB]..[#MaxMOR]', 'U') IS NOT NULL
					DROP TABLE #MaxMOR

				CREATE TABLE #MaxMOR (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					Paymstart DATE,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#FinalMidMOR]', 'U') IS NOT NULL
					DROP TABLE #FinalMidMOR

				CREATE TABLE #FinalMidMOR (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					Paymstart DATE,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#FinalInitialMidMOR]', 'U') IS NOT NULL
					DROP TABLE #FinalInitialMidMOR

				CREATE TABLE #FinalInitialMidMOR (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					Paymstart DATE,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#FinalInitialMOR]', 'U') IS NOT NULL
					DROP TABLE #FinalInitialMOR

				CREATE TABLE #FinalInitialMOR (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					Paymstart DATE,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#RapsInitial]', 'U') IS NOT NULL
					DROP TABLE #RapsInitial

				CREATE TABLE #RapsInitial (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#Raps]', 'U') IS NOT NULL
					DROP TABLE #Raps

				CREATE TABLE #Raps (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC_ORIG_ER VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#RapsMORUnion]', 'U') IS NOT NULL
					DROP TABLE #RapsMORUnion

				CREATE TABLE #RapsMORUnion (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC_ORIG_ER VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#RapsMid]', 'U') IS NOT NULL
					DROP TABLE #RapsMid

				CREATE TABLE #RapsMid (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#RapsFinal]', 'U') IS NOT NULL
					DROP TABLE #RapsFinal

				CREATE TABLE #RapsFinal (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSInitial]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSInitial

				CREATE TABLE #TestMORRAPSInitial (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT,
					RelationFlag VARCHAR(10)
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSMid]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSMid

				CREATE TABLE #TestMORRAPSMid (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT,
					RelationFlag VARCHAR(10)
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinal]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSFinal

				CREATE TABLE #TestMORRAPSFinal (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_ORIG VARCHAR(50),
					HCC_Number INT,
					RelationFlag VARCHAR(10)
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinalActual]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSFinalActual

				CREATE TABLE #TestMORRAPSFinalActual (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(50),
					HCC_ORIG VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_Number INT,
					RelationFlag VARCHAR(10)
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSInitailUpdateRaps]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSInitailUpdateRaps

				CREATE TABLE #TestMORRAPSInitailUpdateRaps (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(120),
					HCC_ORIG VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSMidUpdateRaps]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSMidUpdateRaps

				CREATE TABLE #TestMORRAPSMidUpdateRaps (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(120),
					HCC_ORIG VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_Number INT
					)

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSFinalUpdateRaps]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSFinalUpdateRaps

				CREATE TABLE #TestMORRAPSFinalUpdateRaps (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(120),
					HCC_ORIG VARCHAR(50),
					factor DECIMAL(20, 4),
					HCC_Number INT
					)

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'092',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #MaxMOR (
					PlanID,
					HICN,
					PY,
					MY,
					Paymstart,
					RAFT,
					Factor_Category,
					HCC,
					factor,
					HCC_ORIG,
					HCC_Number
					)
				SELECT m.PlanID,
					m.HICN,
					m.PaymentYear,
					m.Model_Year,
					m.PaymStart,
					m.RAFT,
					m.Factor_category,
					m.Factor_Desc,
					m.Factor,
					m.Factor_Desc,
					m.HCC_Number
				FROM tbl_EstRecv_RiskFactorsMOR m
				INNER JOIN (
					SELECT planid,
						hicn,
						paymentyear,
						Model_Year,
						max(paymstart) maxPayMStart
					FROM tbl_EstRecv_RiskFactorsMOR
					WHERE paymentyear = @Payment_year
						AND Model_Year = @Model_Year
					GROUP BY planid,
						hicn,
						paymentyear,
						Model_Year
					HAVING max(month(paymstart)) >= @Paymonth_MOR  -- #43205 @PayMonthMOR
					) a ON m.hicn = a.hicn
					AND m.paymentyear = a.paymentyear
					AND m.Model_Year = a.Model_Year
					AND m.paymstart = a.maxPayMStart
					AND m.PlanID = a.PlanID

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'093',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #RapsInitial
				SELECT DISTINCT PlanID,
					HICN,
					PaymentYear,
					Model_Year,
					RAFT,
					Factor_Category,
					Factor_Desc,
					Factor,
					Factor_Desc_ORIG,
					HCC_Number
				FROM tbl_EstRecv_RiskFactorsRAPS
				WHERE PATINDEX('HIER%', Factor_Desc) = 0
					AND PATINDEX('DEL%', Factor_Desc) = 0
					AND IMFFlag = 1
					AND PaymentYear = @Payment_year
					AND Model_Year = @Model_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'094',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #RapsMid
				SELECT DISTINCT PlanID,
					HICN,
					PaymentYear,
					Model_Year,
					RAFT,
					Factor_Category,
					Factor_Desc,
					Factor,
					Factor_Desc_ORIG,
					HCC_Number
				FROM tbl_EstRecv_RiskFactorsRAPS
				WHERE PATINDEX('HIER%', Factor_Desc) = 0
					AND PATINDEX('DEL%', Factor_Desc) = 0
					AND IMFFlag = 2
					AND PaymentYear = @Payment_year
					AND Model_Year = @Model_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'095',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #RapsFinal
				SELECT DISTINCT PlanID,
					HICN,
					PaymentYear,
					Model_Year,
					RAFT,
					Factor_Category,
					Factor_Desc,
					Factor,
					Factor_Desc_ORIG,
					HCC_Number
				FROM tbl_EstRecv_RiskFactorsRAPS
				WHERE PATINDEX('HIER%', Factor_Desc) = 0
					AND PATINDEX('DEL%', Factor_Desc) = 0
					AND IMFFlag = 3
					AND PaymentYear = @Payment_year
					AND Model_Year = @Model_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'096',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #FinalMidMOR
				SELECT *
				FROM #MaxMOR
				
				EXCEPT
				
				SELECT t1.*
				FROM #MaxMOR t1
				INNER JOIN #RapsMid t ON t.HICN = t1.HICN
					AND t.PY = t1.PY
					AND t.MY = t1.MY
					AND t.HCC_Number = t1.HCC_Number

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'097',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #FinalInitialMidMOR
				SELECT *
				FROM #FinalMidMOR
				
				EXCEPT
				
				SELECT t1.*
				FROM #FinalMidMOR t1
				INNER JOIN #RapsInitial t ON t.HICN = t1.HICN
					AND t.PY = t1.PY
					AND t.MY = t1.MY
					AND t.HCC_Number = t1.HCC_Number

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'098',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #FinalInitialMOR
				SELECT *
				FROM #FinalInitialMidMOR
				
				EXCEPT
				
				SELECT t1.*
				FROM #FinalInitialMidMOR t1
				INNER JOIN #RapsInitial t ON t.HICN = t1.HICN
					AND t.PY = t1.PY
					AND t.MY = t1.MY
					AND t.HCC_Number = t1.HCC_Number

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'099',
							0,
							1
							)
					WITH NOWAIT
				END

				-- finding hierarchy between RAPS and MOR ticket # 25703
				INSERT INTO #TestMORRAPSInitial (
					PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
					)
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
				FROM #RapsInitial
				
				UNION
				
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
				FROM #FinalInitialMOR

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'100',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #TestMORRAPSMid (
					PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
					)
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
				FROM #RapsMid
				
				UNION
				
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
				FROM #FinalInitialMidMOR

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'101',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #TestMORRAPSFinal (
					PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
					)
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
				FROM #RapsFinal
				
				UNION
				
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					Factor,
					HCC_ORIG,
					HCC_Number
				FROM #MaxMOR

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'102',
							0,
							1
							)
					WITH NOWAIT
				END

				-- HCC Updates
				UPDATE drp
				SET drp.RelationFlag = 'Drop'
				FROM #TestMORRAPSInitial drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG, 3) = 'HCC'
				INNER JOIN #TestMORRAPSInitial kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'103',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE kep
				SET kep.RelationFlag = 'Keep'
				FROM #TestMORRAPSInitial drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG, 3) = 'HCC'
				INNER JOIN #TestMORRAPSInitial kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'104',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE drp
				SET drp.RelationFlag = 'Drop'
				FROM #TestMORRAPSMid drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG, 3) = 'HCC'
				INNER JOIN #TestMORRAPSMid kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'105',
							0,
							1
							)
					WITH NOWAIT
				END

				--and kep.Factor_Category = drp.Factor_Category
				UPDATE kep
				SET kep.RelationFlag = 'Keep'
				FROM #TestMORRAPSMid drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG, 3) = 'HCC'
				INNER JOIN #TestMORRAPSMid kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'106',
							0,
							1
							)
					WITH NOWAIT
				END

				--and kep.Factor_Category = drp.Factor_Category
				UPDATE drp
				SET drp.RelationFlag = 'Drop'
				FROM #TestMORRAPSFinal drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG, 3) = 'HCC'
				INNER JOIN #TestMORRAPSFinal kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'107',
							0,
							1
							)
					WITH NOWAIT
				END

				--and kep.Factor_Category = drp.Factor_Category
				UPDATE kep
				SET kep.RelationFlag = 'Keep'
				FROM #TestMORRAPSFinal drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG, 3) = 'HCC'
				INNER JOIN #TestMORRAPSFinal kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'108',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Interaction updates
				UPDATE drp
				SET drp.RelationFlag = 'Drop'
				FROM #TestMORRAPSInitial drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG, 3) = 'INT'
				INNER JOIN #TestMORRAPSInitial kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'109',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE kep
				SET kep.RelationFlag = 'Keep'
				FROM #TestMORRAPSInitial drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG, 3) = 'INT'
				INNER JOIN #TestMORRAPSInitial kep ON kep.PlanID = drp.PlanID
					AND kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'110',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE drp
				SET drp.RelationFlag = 'Drop'
				FROM #TestMORRAPSMid drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG, 3) = 'INT'
				INNER JOIN #TestMORRAPSMid kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'111',
							0,
							1
							)
					WITH NOWAIT
				END

				--and kep.Factor_Category = drp.Factor_Category
				UPDATE kep
				SET kep.RelationFlag = 'Keep'
				FROM #TestMORRAPSMid drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG, 3) = 'INT'
				INNER JOIN #TestMORRAPSMid kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'112',
							0,
							1
							)
					WITH NOWAIT
				END

				--and kep.Factor_Category = drp.Factor_Category
				UPDATE drp
				SET drp.RelationFlag = 'Drop'
				FROM #TestMORRAPSFinal drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG, 3) = 'INT'
				INNER JOIN #TestMORRAPSFinal kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'113',
							0,
							1
							)
					WITH NOWAIT
				END

				--and kep.Factor_Category = drp.Factor_Category
				UPDATE kep
				SET kep.RelationFlag = 'Keep'
				FROM #TestMORRAPSFinal drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON cast(ltrim(reverse(left(REVERSE(Hier.HCC_DROP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_DROP_NUMBER)) - 1))) AS INT) = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG, 3) = 'INT'
				INNER JOIN #TestMORRAPSFinal kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = cast(ltrim(reverse(left(REVERSE(Hier.HCC_KEEP_NUMBER), PATINDEX('%[A-Z]%', reverse(Hier.HCC_KEEP_NUMBER)) - 1))) AS INT)
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND LEFT(kep.HCC_ORIG, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'114',
							0,
							1
							)
					WITH NOWAIT
				END

				--select * from #TestMORRAPSMid
				--and kep.Factor_Category = drp.Factor_Category
				UPDATE kep
				SET kep.RelationFlag = 'Same'
				FROM #TestMORRAPSFinal kep
				INNER JOIN #MaxMOR drp ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = drp.HCC_Number
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND left(drp.HCC_ORIG, 3) = left(kep.HCC_ORIG, 3)
				WHERE kep.Factor_Category = 'RAPS'
					OR kep.Factor_Category = 'RAPS-Disability'
					OR kep.Factor_Category = 'RAPS-Interaction'

				--OR kep.Factor_Category = 'MOR-HCC'
				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'115',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE drp
				SET drp.RelationFlag = 'Same'
				FROM (
					SELECT *
					FROM #TestMORRAPSFinal kep
					WHERE kep.RelationFlag = 'Same'
					) a
				INNER JOIN (
					SELECT *
					FROM #TestMORRAPSFinal
					) drp ON a.HICN = drp.HICN
					AND a.RAFT = drp.RAFT
					AND a.HCC_Number = drp.HCC_Number
					AND a.PY = drp.PY
					AND a.MY = drp.MY
					AND left(a.HCC_ORIG, 3) = left(drp.HCC_ORIG, 3)
				WHERE drp.Factor_Category = 'MOR-HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'116',
							0,
							1
							)
					WITH NOWAIT
				END

				IF OBJECT_ID('[TEMPDB]..[#TestMORRAPSLowerHCC]', 'U') IS NOT NULL
					DROP TABLE #TestMORRAPSLowerHCC

				CREATE TABLE #TestMORRAPSLowerHCC (
					PlanID INT,
					HICN VARCHAR(20),
					PY INT,
					MY INT,
					RAFT VARCHAR(5),
					Factor_Category VARCHAR(50),
					HCC VARCHAR(20),
					HCC_ORIG VARCHAR(50),
					Factor DECIMAL(20, 4),
					HCC_Number INT,
					RelationFlag VARCHAR(10)
					)

				INSERT INTO #TestMORRAPSLowerHCC
				SELECT DISTINCT t.PlanID,
					t.HICN,
					t.PY,
					t.MY,
					t.RAFT,
					Factor_Category,
					t.HCC,
					t.HCC_ORIG,
					t.Factor,
					t.HCC_Number,
					RelationFlag
				FROM #TestMORRAPSFinal t
				INNER JOIN (
					SELECT DISTINCT PlanID,
						HICN,
						PY,
						MY,
						RAFT,
						HCC_Number
					FROM #RapsInitial
					
					UNION
					
					SELECT DISTINCT PlanID,
						HICN,
						PY,
						MY,
						RAFT,
						HCC_Number
					FROM #RapsMid
					) a ON t.HICN = a.HICN
					AND t.PY = a.PY
					AND t.MY = a.MY
					AND t.HCC_Number = a.HCC_Number
				WHERE Factor_Category = 'MOR-HCC'
					AND RelationFlag = 'Drop'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'117',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #TestMORRAPSFinalActual
				SELECT DISTINCT t1.PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC,
					HCC_ORIG,
					Factor,
					HCC_Number,
					RelationFlag
				FROM #TestMORRAPSFinal t1
				
				EXCEPT
				
				SELECT *
				FROM #TestMORRAPSLowerHCC

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'118',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE #TestMORRAPSFinalActual
				SET RelationFlag = NULL
				FROM #TestMORRAPSFinalActual t
				INNER JOIN #TestMORRAPSLowerHCC lh ON t.HICN = lh.HICN
					AND t.PY = lh.PY
					AND t.MY = lh.MY
					AND LEFT(t.HCC_ORIG, 3) = LEFT(lh.HCC_ORIG, 3)
				WHERE t.RelationFlag = 'Keep'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'119',
							0,
							1
							)
					WITH NOWAIT
				END

				--select * from #TestMORRAPSFinal
				INSERT INTO #TestMORRAPSInitailUpdateRaps
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					CASE 
						WHEN (
								Factor_Category = 'RAPS'
								OR Factor_Category = 'RAPS-Disability'
								OR Factor_Category = 'RAPS-Interaction'
								)
							AND RelationFlag = 'Drop'
							THEN 'M-' + HCC
						WHEN Factor_Category = 'MOR-HCC'
							AND RelationFlag = 'Keep'
							THEN 'MOR-' + HCC
						WHEN (
								Factor_Category = 'RAPS'
								OR Factor_Category = 'RAPS-Disability'
								OR Factor_Category = 'RAPS-Interaction'
								)
							AND RelationFlag = 'Keep'
							THEN 'M-High-' + HCC
						WHEN Factor_Category = 'MOR-HCC'
							AND RelationFlag = 'Drop'
							THEN 'MOR-INCR-' + HCC
						ELSE HCC
						END,
					HCC_ORIG,
					Factor,
					HCC_Number
				FROM #TestMORRAPSInitial
				WHERE RelationFlag IS NOT NULL

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'120',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #TestMORRAPSFinalUpdateRaps
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					CASE 
						WHEN (
								Factor_Category = 'RAPS'
								OR Factor_Category = 'RAPS-Disability'
								OR Factor_Category = 'RAPS-Interaction'
								)
							AND RelationFlag = 'Keep'
							THEN 'M-High-' + HCC
						WHEN (
								Factor_Category = 'RAPS'
								OR Factor_Category = 'RAPS-Disability'
								OR Factor_Category = 'RAPS-Interaction'
								)
							AND (
								RelationFlag = 'Drop'
								OR RelationFlag = 'Same'
								)
							THEN 'M-' + HCC
						WHEN Factor_Category = 'MOR-HCC'
							AND RelationFlag = 'Drop'
							THEN 'MOR-INCR-' + HCC
						WHEN Factor_Category = 'MOR-HCC'
							AND (
								RelationFlag = 'Keep'
								OR RelationFlag = 'Same'
								)
							THEN 'MOR-' + HCC
						ELSE HCC
						END,
					HCC_ORIG,
					Factor,
					HCC_Number
				FROM #TestMORRAPSFinalActual
				WHERE RelationFlag IS NOT NULL

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'121',
							0,
							1
							)
					WITH NOWAIT
				END

				--select * from #TestMORRAPSFinalUpdateRaps
				INSERT INTO #TestMORRAPSMidUpdateRaps
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					CASE 
						WHEN (
								Factor_Category = 'RAPS'
								OR Factor_Category = 'RAPS-Disability'
								OR Factor_Category = 'RAPS-Interaction'
								)
							AND RelationFlag = 'Keep'
							THEN 'M-High-' + HCC
						WHEN (
								Factor_Category = 'RAPS'
								OR Factor_Category = 'RAPS-Disability'
								OR Factor_Category = 'RAPS-Interaction'
								)
							AND RelationFlag = 'Drop'
							THEN 'M-' + HCC
						WHEN Factor_Category = 'MOR-HCC'
							AND RelationFlag = 'Drop'
							THEN 'MOR-INCR-' + HCC
						WHEN Factor_Category = 'MOR-HCC'
							AND (
								RelationFlag = 'Keep'
								OR RelationFlag IS NULL
								)
							THEN 'MOR-' + HCC
						ELSE HCC
						END,
					HCC_ORIG,
					Factor,
					HCC_Number
				FROM #TestMORRAPSMid
				WHERE RelationFlag IS NOT NULL

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'122',
							0,
							1
							)
					WITH NOWAIT
				END

				--select * from #TestMORRAPSFinalUpdateRaps
				--select * from #TestMORRAPSFinalActual
				UPDATE t
				SET t.Factor_Desc = t1.HCC
				FROM tbl_EstRecv_RiskFactorsRAPS t
				INNER JOIN #TestMORRAPSInitailUpdateRaps t1 ON t.HICN = t1.HICN
					AND t.PaymentYear = t1.PY
					AND t.RAFT = t1.RAFT
					AND t.HCC_Number = t1.HCC_Number
					AND t.Model_Year = t1.MY
					AND t.Factor_Category = t1.Factor_Category
				WHERE t.IMFFlag = 1
					AND PATINDEX('HIER%', t.Factor_Desc) = 0

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'123',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t
				SET t.Factor_Desc = t1.HCC
				FROM tbl_EstRecv_RiskFactorsRAPS t
				INNER JOIN #TestMORRAPSMidUpdateRaps t1 ON t.HICN = t1.HICN
					AND t.PaymentYear = t1.PY
					AND t.RAFT = t1.RAFT
					AND t.HCC_Number = t1.HCC_Number
					AND t.Model_Year = t1.MY
					AND t.Factor_Category = t1.Factor_Category
				WHERE t.IMFFlag = 2
					AND PATINDEX('HIER%', t.Factor_Desc) = 0

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'124',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t
				SET t.Factor_Desc = t1.HCC
				FROM tbl_EstRecv_RiskFactorsRAPS t
				INNER JOIN #TestMORRAPSFinalUpdateRaps t1 ON t.HICN = t1.HICN
					AND t.PaymentYear = t1.PY
					AND t.RAFT = t1.RAFT
					AND t.HCC_Number = t1.HCC_Number
					AND t.Model_Year = t1.MY
					AND t.Factor_Category = t1.Factor_Category
				WHERE t.IMFFlag = 3
					AND PATINDEX('HIER%', t.Factor_Desc) = 0

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'125',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO tbl_EstRecv_RiskFactorsRAPS (
					PlanID,
					HICN,
					PaymentYear,
					Model_Year,
					RAFT,
					Factor_Category,
					Factor_Desc,
					Factor_Desc_ORIG,
					Factor,
					HCC_Number
					)
				SELECT t.*
				FROM #TestMORRAPSMidUpdateRaps t
				INNER JOIN #RapsMid r ON t.PlanID = r.PlanID
					AND t.HICN = r.HICN
					AND t.PY = r.PY
					AND t.MY = r.MY
					AND t.RAFT = r.RAFT
				WHERE t.Factor_Category = 'MOR-HCC'
				
				UNION
				
				SELECT t.*
				FROM #TestMORRAPSFinalUpdateRaps t
				INNER JOIN #RapsFinal r ON t.PlanID = r.PlanID
					AND t.HICN = r.HICN
					AND t.PY = r.PY
					AND t.MY = r.MY
					AND t.RAFT = r.RAFT
				WHERE t.Factor_Category = 'MOR-HCC'
				
				UNION
				
				SELECT t.*
				FROM #TestMORRAPSInitailUpdateRaps t
				INNER JOIN #RapsInitial r ON t.PlanID = r.PlanID
					AND t.HICN = r.HICN
					AND t.PY = r.PY
					AND t.MY = r.MY
					AND t.RAFT = r.RAFT
				WHERE t.Factor_Category = 'MOR-HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'126',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #Raps
				SELECT DISTINCT PlanID,
					HICN,
					PaymentYear,
					Model_Year,
					RAFT,
					Factor_Category,
					Factor_Desc_EstRecev,
					HCC_Number
				FROM tbl_EstRecv_RiskFactorsRAPS
				WHERE PATINDEX('HIER%', Factor_Desc_EstRecev) = 0
					AND PATINDEX('DEL%', Factor_Desc_EstRecev) = 0
					AND PATINDEX('MOR%', Factor_Category) = 0
					AND PaymentYear = @Payment_year
					AND Model_Year = @Model_Year

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'127',
							0,
							1
							)
					WITH NOWAIT
				END

				INSERT INTO #RapsMORUnion
				SELECT *
				FROM #Raps
				
				UNION
				
				SELECT PlanID,
					HICN,
					PY,
					MY,
					RAFT,
					Factor_Category,
					HCC_ORIG,
					HCC_Number
				FROM #MaxMOR

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'128',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE drp
				SET drp.HCC_ORIG_ER = 'HIER-' + drp.HCC_ORIG_ER
				--,	drp.Factor = 0
				FROM #RapsMORUnion drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP_NUMBER = drp.HCC_Number
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'HCC'
					AND left(drp.HCC_ORIG_ER, 3) = 'HCC'
				INNER JOIN #RapsMORUnion kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_Number = Hier.HCC_KEEP_NUMBER
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND left(kep.HCC_ORIG_ER, 3) = 'HCC'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'129',
							0,
							1
							)
					WITH NOWAIT
				END

				-- Get Hierarchy Interactions
				UPDATE drp
				SET drp.HCC_ORIG_ER = 'HIER-' + drp.HCC_ORIG_ER
				--,	drp.Factor = 0
				FROM #RapsMORUnion drp
				INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy Hier ON Hier.HCC_DROP = drp.HCC_ORIG_ER
					AND Hier.Payment_Year = @Model_Year
					AND Hier.RA_FACTOR_TYPE = drp.RAFT
					AND Hier.Part_C_D_Flag = 'C'
					AND left(Hier.HCC_DROP, 3) = 'INT'
					AND left(drp.HCC_ORIG_ER, 3) = 'INT'
				INNER JOIN #RapsMORUnion kep ON kep.HICN = drp.HICN
					AND kep.RAFT = drp.RAFT
					AND kep.HCC_ORIG_ER = Hier.HCC_KEEP
					AND kep.PY = drp.PY
					AND kep.MY = drp.MY
					AND left(kep.HCC_ORIG_ER, 3) = 'INT'

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'130',
							0,
							1
							)
					WITH NOWAIT
				END

				UPDATE t
				SET t.Factor_Desc_EstRecev = t1.HCC_ORIG_ER
				FROM tbl_EstRecv_RiskFactorsRAPS t
				INNER JOIN #RapsMORUnion t1 ON t.HICN = t1.HICN
					AND t.PaymentYear = t1.PY
					AND t.RAFT = t1.RAFT
					AND t.HCC_Number = t1.HCC_Number
					AND t.Model_Year = t1.MY
					AND t.Factor_Category = t1.Factor_Category
				WHERE PATINDEX('HIER%', t.Factor_Desc) = 0

				IF @Debug = 1
				BEGIN
					PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

					SET @ET = GETDATE()

					RAISERROR (
							'131',
							0,
							1
							)
					WITH NOWAIT
				END
			END

			SELECT @MY_Cnt = @MY_Cnt - 1
		END -- Get the next Model Year

		SELECT @PY_Cnt = @PY_Cnt - 1
	END -- Get next Payment Year
			/* End Payment Year Loop */

	--UPDATE RUN LOG
	IF @RAPS_FLAG = 1
		UPDATE tbl_EstRecv_Summary_tbl_Log
		SET Last_updated = GETDATE()
		WHERE Summary_tbl_Name = 'tbl_EstRecv_RiskFactorsRAPS'

	IF @MOR_FLAG = 1
		UPDATE tbl_EstRecv_Summary_tbl_Log
		SET Last_updated = GETDATE()
		WHERE Summary_tbl_Name = 'tbl_EstRecv_RiskFactorsMOR'

	IF @Debug = 1
	BEGIN
		PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, GETDATE()) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), GETDATE() - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), GETDATE(), 121)

		SET @ET = GETDATE()

		RAISERROR (
				'132',
				0,
				1
				)
		WITH NOWAIT
	END

	SET NOCOUNT OFF
END

