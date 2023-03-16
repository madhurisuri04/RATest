/*******************************************************************************************************************************
* Name			:	rpt.GetPartDDeleteHCCOutput
* Type 			:	Stored Procedure          
* Author       	:	David Waddell
* TFS#          :   
* Date          :	4/9/2018
* Version		:	1.0
* Project		:	SP for generating the output for the "Part D Estimated Receivable Delete HCC Output" SSRS report from RE
* SP call		:	Exec rpt.GetERPartDDeleteHCCOutput '2017', 'H3305', NULL
* Version History :
  Author			Date		Version#	TFS Ticket#		Description
* -----------------	----------	--------	-----------		------------
  D. Waddell         4/16/2018     1.0        70580              Initial
*********************************************************************************************************************************************************/

CREATE PROCEDURE [rpt].[GetPartDDeleteHCCOutput]
    @PaymentYear    VARCHAR (4) ,
    @ProcessByStart DATETIME ,
    @ProcessByEnd   DATETIME ,
    @PlanID         VARCHAR (200)
AS
    BEGIN

        SET NOCOUNT ON

        DECLARE @Error_Message VARCHAR (8000)
        BEGIN TRY

            DECLARE @PYear      VARCHAR (4)   = @PaymentYear ,
                    @PStartDate DATETIME      = @ProcessByStart ,
                    @PEndDate   DATETIME      = @ProcessByEnd ,
                    @PID        VARCHAR (200) = @PlanID


            IF OBJECT_ID( 'TempDB..#tempPID' ) IS NOT NULL DROP TABLE [#tempPID]

            CREATE TABLE [#tempPID]
                (
                    [Item] VARCHAR (200)
                )

            INSERT INTO [#tempPID] ( [Item] )
                        SELECT [Item]
                        FROM   [dbo].[fnSplit]( @PID, ',' )


            BEGIN

                DECLARE @RptSQL VARCHAR (7000)

                SET @RptSQL = '
SELECT [Paymentyear]
      ,[Modelyear]
      ,[ProcessedbyStart]
      ,[ProcessedbyEnd]
      ,[ProcessedbyFlag]
      ,[InMOR]
      ,[PlanID]
      ,[HICN]
      ,[RAFactorType]
      ,[RxHCC]
      ,[RxHCCDescription]
      ,[Factor]
      ,[HIERRxHCCOld]
      ,[HIERFactorOld]
      ,[MemberMonths]
      ,[BID]
      ,[EstimatedValue]
      ,[RollforwardMonths]
      ,[AnnualizedEstimatedValue]
      ,[MonthsinDCP]
      ,[ESRD]
      ,[HOSP]
      ,[PBP]
      ,[SCC]
      ,[ProcessedPriorityProcessedby]
      ,[ProcessedPriorityThrudate]
      ,[ProcessedPriorityPCN]
      ,[ProcessedPriorityDiag]
      ,[ThruPriorityThruDate]
      ,[ThruPriorityPCN]
      ,[ThruPriorityDiag]
      ,[RAPSSource]
      ,[ProviderID]
      ,[ProviderLast]
      ,[ProviderFirst]
      ,[ProviderGroup]
      ,[ProviderAddress]
      ,[ProviderCity]
      ,[ProviderState]
      ,[ProviderZip]
      ,[ProviderPhone]
      ,[ProviderFax]
      ,[TaxID]
      ,[NPI]
      ,[SweepDate]
      ,[PopulatedDate]
      ,[AgedStatus]
      
  FROM [rev].[ERPartDDeleteHCCOutput] WITH(NOLOCK)
WHERE
	[Paymentyear] = ' + @PYear
                              + ' AND
			EXISTS (SELECT 1 FROM [#TempPID] [tp] WHERE [PlanID] = [tp].[Item])
		AND
			([ProcessedPriorityProcessedby] >= '''
                              + CONVERT( VARCHAR (10), @PStartDate, 101 )
                              + '''
		AND 
			[ProcessedPriorityProcessedby] <= '''
                              + CONVERT( VARCHAR (10), @PEndDate, 101 )
                              + ''')
 
 ORDER BY
	[PlanID],
	[HICN],
	[RxHCC] '


                EXEC ( @RptSQL )


            END


        END TRY
        BEGIN CATCH
            DECLARE @ErrorMsg VARCHAR (2000)
            SET @ErrorMsg = 'Error: ' + ISNULL( ERROR_PROCEDURE(), 'script' )
                            + ': ' + ERROR_MESSAGE() + ', Error Number: '
                            + CAST(ERROR_NUMBER() AS VARCHAR (10))
                            + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR (50))

            RAISERROR( @ErrorMsg, 16, 1 )
        END CATCH

    END