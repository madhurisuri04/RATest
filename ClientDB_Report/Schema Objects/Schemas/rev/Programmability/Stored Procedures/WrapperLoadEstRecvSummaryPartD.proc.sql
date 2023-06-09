/*******************************************************************************************************************************
* Name				:	rev.WrapperLoadEstRecvSummaryPartD
* Type 				:	Stored Procedure          
* Author       		:	Madhuri Suri
* TFS#				:   
* Date				:	4/2/2018
* Version			:	1.0
* Project			:	Wrapper SP used for loading permanent table for "EstRecvSummaryPartD" table for the Estimated Receivable Summary report
* SP call			:	Exec rev.WrapperLoadEstRecvSummaryPartD
* Version History	:
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------ 
Anand		        9/15/20       1.0        RRI-229/79617   Add Row Count to log table
*********************************************************************************************************************************/

CREATE PROCEDURE [rev].[WrapperLoadEstRecvSummaryPartD]
AS
BEGIN

SET NOCOUNT ON

DECLARE @Error_Message VARCHAR(8000)
Declare @RowCount_OUT INT;
Declare @UserID VARCHAR(128) = SYSTEM_USER;
Declare @EstRecvRskadjActivityID INT;

BEGIN TRY

IF OBJECT_ID('TempDB..#ActiveYears') IS NOT NULL
DROP TABLE #ActiveYears

CREATE TABLE #ActiveYears
(
	ActiveYearsID SMALLINT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	PaymentYear INT NOT NULL
)

INSERT INTO #ActiveYears
(
	PaymentYear
)
SELECT  
	RPY.Payment_Year
FROM rev.EstRecevRefreshPY RPY WITH(NOLOCK)
GROUP BY 
	RPY.Payment_Year
	
TRUNCATE TABLE etl.EstRecvSummaryPartD

/* Loop for each year */

DECLARE 
	@Counter INT,
	@I INT = 1
	
SET @Counter = (SELECT MAX(ActiveYearsID) FROM #ActiveYears)

WHILE (@I <= @Counter)
BEGIN
	
	DECLARE @PaymentYear INT = (SELECT PaymentYear FROM #ActiveYears WHERE ActiveYearsID = @I)
	
	PRINT @PaymentYear
	
	DELETE FROM rev.EstRecvSummaryPartD
	WHERE PaymentYear = @PaymentYear


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
    SELECT [Part_C_D_Flag] = 'Part D',
           [Process] = 'WrapperLoadEstRecvSummaryPartD',
		   [Payment_Year] = @PaymentYear, 
		   [MYU]=NULL,
           [BDate] = GETDATE(),
           [EDate] = NULL,
           [AdditionalRows] = NULL,
           [RunBy] = @UserID;

	           SET @EstRecvRskadjActivityID = SCOPE_IDENTITY();
			   SET @RowCount_OUT = 0;

EXEC rev.LoadEstRecvSummaryPartD @PaymentYear,@RowCount = @RowCount_OUT OUTPUT;
		
UPDATE [m]
                SET [m].[EDate] = GETDATE(),
                    [m].[AdditionalRows] = Isnull(@RowCount_OUT,0)
                FROM [rev].[EstRecvRskadjActivity] [m]
                WHERE [m].[EstRecvRskadjActivityID]  = @EstRecvRskadjActivityID

	SET @I = @I  + 1
		
END	

END TRY
	BEGIN CATCH
	      DECLARE @ErrorMsg VARCHAR(2000)
		  SET @ErrorMsg = 'Error: ' + ISNULL(Error_Procedure(),'script') + ': ' +  Error_Message() +
                           ', Error Number: ' + CAST(Error_Number() AS VARCHAR(10)) + ' Line: ' + 
                           CAST(Error_Line() AS VARCHAR(50))
   
		RAISERROR (@ErrorMsg, 16, 1)
	END CATCH	

END