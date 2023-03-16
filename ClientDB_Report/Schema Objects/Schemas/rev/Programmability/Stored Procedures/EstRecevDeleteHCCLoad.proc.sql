CREATE PROC [rev].[EstRecevDeleteHCCLoad] (
    @Debug BIT = 0
	)
AS
/******************************************************************************************************************************** 
* Name			:	rev.EstRecevDeleteHCCLoad       																		    *
* Type 			:	Stored Procedure																							*																																																																																																																																																																																																																																																																																																																																																																																														
* Author       	:	Mitch Casto																									*
* Date			:	2017-04-26																									*
* Version		:																											    *																																																									*
* Description	:   This stored procedure will determine whether or not a refresh of the Part C Delete HCC stored               *
*                   procedure is needed for Estimated Receivable purposes ("R" parameter").    								    *	
*					Note: This stored procedure will be part of a nightly job attached to the Summary 2.0 job, hence            *
*                   every day when this will refresh only when there is new delete data available in RAPS.                      *				
*																											                	*
*																																*
* Version History :																												*
* =================================================================================================								*
* Author			Date		Version#    TFS Ticket#		           Description												*																
* -----------------	----------  --------    -----------		           ------------												*		
* D. Waddell		2017-05-02	1.0			64977 (TFS 64262)			Initial													*
*                                                                       also update to Section 004                              *
* Anand             2020-09-22  1.1         RRI-34/79581                Add to EstRecvRskadjActivity log table 
*********************************************************************************************************************************/ 


    SET STATISTICS IO OFF
    SET NOCOUNT ON

    /*****************************************************************/
    /* Initialize value of local variables                           */
    /*****************************************************************/

    DECLARE @PaymentYear int
	DECLARE @ProcessByStart datetime
	DECLARE @ProcessByEnd datetime
	DECLARE @CurrYear int
	Declare @RowCount_OUT INT;
	Declare @UserID VARCHAR(128) = SYSTEM_USER;
	Declare @EstRecvRskadjActivityID INT;


	SET @ProcessByEnd =  getdate()
	SET @CurrYear = YEAR(@ProcessByEnd)

    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            DECLARE @ProcessNameIn VARCHAR(128)
            SET @ET = GETDATE()
            SET @MasterET = @ET
            SET @ProcessNameIn = OBJECT_NAME(@@PROCID)
            EXEC [dbo].[PerfLogMonitor] @Section = '000'
                                      , @ProcessName = @ProcessNameIn
                                      , @ET = @ET
                                      , @MasterET = @MasterET
                                      , @ET_Out = @ET OUT
                                      , @TableOutput = 0
                                      , @End = 0
        END

   
  
    

		IF (OBJECT_ID('tempdb.dbo.[#Refresh_PY]') IS NOT NULL)
        BEGIN 
            DROP TABLE [#Refresh_PY]
        END 



		 IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '001'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        END




    /* B Get Refresh PY data */

    CREATE TABLE [#Refresh_PY] (
        [Id] INT IDENTITY(1, 1) PRIMARY KEY
      , [Payment_Year] INT NOT NULL
      
         
	  )

    IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '002'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        END
    INSERT INTO [#Refresh_PY] ([Payment_Year]
                             )
    SELECT [Payment_Year] = [a1].[Payment_Year]
      FROM [rev].[tbl_Summary_RskAdj_RefreshPY] [a1]
	  WHERE [a1].[Payment_Year] !> @CurrYear

    /* E Get Refresh PY data */


IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '003'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        END


/* Loop to incredmentally execute EstRec Delete HHC procedure by Payment Year */

WHILE EXISTS (SELECT TOP 1 [Payment_Year] FROM [#Refresh_PY])
BEGIN

    SELECT @PaymentYear = (SELECT TOP 1 [Payment_Year]
                       FROM [#Refresh_PY]
                       ORDER BY [Id] ASC)

	SELECT @ProcessByStart = (SELECT From_Date FROM rev.tbl_Summary_RskAdj_RefreshPY WHERE [Payment_Year] = @PaymentYear)


	IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '004'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        END



--PaymentYear loop based on rev.tbl_Summary_RskAdj_RefreshPY 
--PaymentYear not to exceed Year(GetDate()) 
 
If  
            (SELECT Max(ProcessedBy)
            FROM [rev].[tbl_Summary_RskAdj_RAPS_Preliminary] nolock
            WHERE deleted is not null
            and PaymentYear = @PaymentYear)
            >
            (Select CASE WHEN EXISTS (                                                      -- TFS 64262 (Updated)
                                                SELECT top 1 * 
                                                FROM rev.ERDeleteHCCOutput
                                                WHERE PaymentYear = @PaymentYear )
                                          THEN  (SELECT DISTINCT PopulatedDate
                                                      FROM rev.ERDeleteHCCOutput
                                                      WHERE PaymentYear = @PaymentYear)
                                    ELSE  '1/1/1900'
                              END)

 
BEGIN
		
    INSERT INTO [rev].[EstRecvRskadjActivity]
    (
        [Part_C_D_Flag],
        [Process],
		[Payment_Year], 
		[MYU],
        [BDate],
        [EDate],
        [AdditionalRows],
        [RunBy]
    )
    SELECT [Part_C_D_Flag] = 'Part C',
           [Process] = 'spr_EstRecv_Delete_HCC',
		   [Payment_Year] = @PaymentYear, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;


      EXEC [rev].[spr_EstRecv_Delete_HCC]
          @Payment_Year_NewDeleteHCC = @PaymentYear
        , @PROCESSBY_START = @ProcessByStart
		, @PROCESSBY_END  = @ProcessByEnd
        , @ReportOutputByMonth  = 'R'
        , @Debug = 0
		, @RowCount = @RowCount_OUT OUTPUT

	UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID;

		IF @Debug = 1
            BEGIN
                  EXEC [dbo].[PerfLogMonitor] '005'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        
            
                  PRINT   '@Payment_Year_NewDeleteHCC = ' + CAST(@PaymentYear as varchar)
                  PRINT   '@PROCESSBY_START = ' + CAST(@ProcessByStart as Varchar)
                  PRINT   '@PROCESSBY_END = '+ CAST(@ProcessByEnd as varchar)
            
            END

 
END   



 DELETE [#Refresh_PY]
    WHERE [Payment_Year] = @PaymentYear



	IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '006'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        END

END

DROP TABLE [#Refresh_PY]


IF @Debug = 1
        BEGIN
            EXEC [dbo].[PerfLogMonitor] '007'
                                      , @ProcessNameIn
                                      , @ET
                                      , @MasterET
                                      , @ET OUT
                                      , 0
                                      , 0
        END

		



