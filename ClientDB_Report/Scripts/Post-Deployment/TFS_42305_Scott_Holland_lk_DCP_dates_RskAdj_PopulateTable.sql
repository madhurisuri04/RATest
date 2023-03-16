/*		Create By:		Scott Holland
		Create Date:	06/29/2015
		Notes:			This is to be used for the changes required for the Summary, NewHCC, and DeleteHCC changes required for the MOR CMS change on dates.
		Revisions:
*/


BEGIN TRAN LK_DCP_DATES_RSKADJ

BEGIN TRY
	IF OBJECT_ID('tempdb..#tmp_ChgTest') IS NOT NULL
		DROP TABLE #tmp_ChgTest

	CREATE TABLE #tmp_ChgTest (
		[ID] [int] IDENTITY(1, 1) NOT NULL
		,[PayMonth] [varchar](6) NOT NULL
		,[MOR_DCP] [varchar](50) NOT NULL
		,[Full_Year] [varchar](1) NOT NULL
		,[Description] [varchar](50) NOT NULL
		,[Group_Year] [int] NOT NULL
		,[Order] [int] NOT NULL
		,[DCP_Start] [datetime] NOT NULL
		,[DCP_End] [datetime] NOT NULL
		,[Initial_Sweep_Date] [datetime] NULL
		,[Final_Sweep_Date] [datetime] NULL
		,[Mid_Year_Update] [varchar](1) NULL
		)

	INSERT INTO #tmp_ChgTest (
		PayMonth
		,MOR_DCP
		,Full_Year
		,[Description]
		,Group_Year
		,[Order]
		,DCP_Start
		,DCP_End
		,Initial_Sweep_Date
		,Final_Sweep_Date
		,Mid_Year_Update
		)
	SELECT PayMonth
		,MOR_DCP
		,Full_Year
		,[Description]
		,Group_Year
		,[Order]
		,DCP_Start
		,DCP_End
		,Initial_Sweep_Date
		,Final_Sweep_Date
		,Mid_Year_Update
	FROM HRPReporting.dbo.lk_DCP_dates
	
	EXCEPT
	
	SELECT PayMonth
		,MOR_DCP
		,Full_Year
		,[Description]
		,Group_Year
		,[Order]
		,DCP_Start
		,DCP_End
		,Initial_Sweep_Date
		,Final_Sweep_Date
		,Mid_Year_Update
	FROM dbo.lk_DCP_dates_RskAdj

	IF OBJECT_ID('tempdb..#tmp_ChgTest') IS NOT NULL
	BEGIN
		TRUNCATE TABLE dbo.lk_DCP_dates_RskAdj
	END

	INSERT INTO dbo.lk_DCP_dates_RskAdj (
		PayMonth
		,MOR_DCP
		,Full_Year
		,[Description]
		,Group_Year
		,[ORDER]
		,DCP_Start
		,DCP_End
		,Initial_Sweep_Date
		,Final_Sweep_Date
		,Mid_Year_Update
		,MOR_Mid_Year_Update
		)
	SELECT PayMonth
		,MOR_DCP
		,Full_Year
		,[Description]
		,Group_Year
		,[ORDER]
		,DCP_Start
		,DCP_End
		,Initial_Sweep_Date
		,Final_Sweep_Date
		,Mid_Year_Update
		,Mid_Year_Update
	FROM HRPReporting.dbo.lk_DCP_dates
	WHERE left(PayMonth, 4) >= 2009
	ORDER BY PayMonth

	UPDATE dbo.lk_DCP_dates_RskAdj
	SET MOR_Mid_Year_Update = NULL
	WHERE PayMonth = '201408'

	UPDATE dbo.lk_DCP_dates_RskAdj
	SET MOR_Mid_Year_Update = 'Y'
	WHERE PayMonth = '201407'
END TRY

BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber
		,ERROR_SEVERITY() AS ErrorSeverity
		,ERROR_STATE() AS ErrorState
		,ERROR_PROCEDURE() AS ErrorProcedure
		,ERROR_LINE() AS ErrorLine
		,ERROR_MESSAGE() AS ErrorMessage;

	IF @@TRANCOUNT > 0
		ROLLBACK TRAN LK_DCP_DATES_RSKADJ
END CATCH

IF @@TRANCOUNT > 0
	COMMIT TRAN LK_DCP_DATES_RSKADJ