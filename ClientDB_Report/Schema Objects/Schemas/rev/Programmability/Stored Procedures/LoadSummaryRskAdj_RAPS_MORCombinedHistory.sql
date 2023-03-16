CREATE PROCEDURE rev.LoadSummaryRskAdj_RAPS_MORCombinedHistory
(
    @Payment_Year VARCHAR(4),
    @Debug BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    /************************************************************************************************************************        
* Name			:	[rev].[LoadSummaryRskAdj_RAPS_MORCombinedHistory].proc     			     	                            *                                                     
* Type 			:	Stored Procedure									                                                    *                
* Author       	:	D. Waddell    	       								                                                    *
* Date          :	4/29/2020      											                                                *	
* Ticket        :   (RE-8053)                                                                                               *
* Description	:	Populates History Data into [hst].[tbl_Summary_RskAdj_RAPS_MOR_Combined] table once every month         *
* Version History :																											*
* ======================================================================================================================	*
* Author			Date		Version#    TFS Ticket#			Description													*	
* -----------------	----------  --------    -----------			------------												*
* D.Waddell		 2020-05-12 	1.0 		78495/ RE-8053		Initial														*
* D. Waddell     2020-10-01     1.1         79669/RRI-40		Insert into log table for History Load.                     *
*****************************************************************************************************************************/

    --DECLARE @Payment_Year VARCHAR(4) = 2018


    DECLARE @PaymentYear VARCHAR(4) = @Payment_Year;
    DECLARE @UserID VARCHAR(128) = SYSTEM_USER;
    DECLARE @RowCnt INT = 0;
    DECLARE @HistoryRskadjActivityID INT;
    DECLARE @tblGroupingID INT;
    DECLARE @Error_Message VARCHAR(8000);
    BEGIN TRY
        DECLARE @TenthofMonth DATETIME = (DATEADD(dd, 10 - 1, DATEADD(mm, DATEDIFF(mm, 0, CURRENT_TIMESTAMP), 0)));
        DECLARE @hstLoaddate datetime = (SELECT TOP 1 ISNULL(LoadDateTime, '1900-01-01') Populated
                                               FROM hst.tbl_Summary_RskAdj_RAPS_MOR_Combined
                                               WHERE PaymentYear = @PaymentYear 
                                               AND (Factor_category Like  'RAPS%' OR
              Factor_category Like  'MOR%') 
                                               ORDER BY Populated DESC  )
DECLARE @revLoaddate datetime = (SELECT TOP 1  ISNULL(LoadDateTime, '1900-01-01') Populated 
                                               FROM rev.tbl_Summary_RskAdj_RAPS_MOR_Combined
                                               WHERE PaymentYear = @PaymentYear 
                                               AND (Factor_category Like  'RAPS%' OR
              Factor_category Like  'MOR%') 
                                                  ORDER BY Populated DESC)


        IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON;
            DECLARE @ET DATETIME;
            DECLARE @MasterET DATETIME;
            SET @ET = GETDATE();
            SET @MasterET = @ET;
        END;

              

        IF @Debug = 1
        BEGIN
            PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                  + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
            SET @ET = GETDATE();
            RAISERROR('001', 0, 1) WITH NOWAIT;
        END;




        --select @FirstofMonth, @revLoaddate, (ISNULL(@hstLoaddate, '1900-01-01'))

        IF  ((GETDATE() >= @TenthofMonth)
    AND (ISNULL(@hstLoaddate, '1900-01-01') < @TenthofMonth)
    AND ((ISNULL(@revLoaddate, '1900-01-01')) > (ISNULL(@hstLoaddate, '1900-01-01'))))
        BEGIN


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('002', 0, 1) WITH NOWAIT;
            END;



            /* Insert into HistoryRskadjActivity Table*/

            INSERT INTO rev.HistoryRskadjActivity
            (
                GroupingID,
                PartCDFlag,
                Process,
                TableName,
                PaymentYear,
                MYUFlag,
                LastUpdatedDate,
                BDate,
                EDate,
                AdditionalRows,
                RunBy
            )
            SELECT GroupingID = NULL,
                   PartCDFlag = 'Part C',
                   Process = 'rev.LoadSummaryRskAdj_RAPS_MORCombinedHistory',
                   TableName = 'hst.tbl_Summary_RskAdj_RAPS_MOR_Combined',
                   PaymentYear = @PaymentYear,
                   MYUFlag = NULL,
                   LastUpdatedDate = @revLoaddate,
                   BDate = GETDATE(),
                   EDate = NULL,
                   AdditionalRows = NULL,
                   RunBy = @UserID;

            SET @HistoryRskadjActivityID = SCOPE_IDENTITY();
            SET @tblGroupingID = @HistoryRskadjActivityID;

            /* Update Grouping ID */
            UPDATE m
            SET m.GroupingID = @tblGroupingID
            FROM rev.HistoryRskadjActivity m
            WHERE m.HistoryRskadjActivityID = @HistoryRskadjActivityID;



            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('003', 0, 1) WITH NOWAIT;
            END;



            /*[hst].[tbl_Summary_RskAdj_RAPS_MOR_Combined]Table Insert*/

            INSERT INTO hst.tbl_Summary_RskAdj_RAPS_MOR_Combined
            (
                PlanID,
                HICN,
                PaymentYear,
                PaymStart,
                ModelYear,
                Factor_category,
                Factor_Desc,
                Factor,
                RAFT,
                HCC_Number,
                Min_ProcessBy,
                Min_ThruDate,
                Min_ProcessBy_SeqNum,
                Min_ThruDate_SeqNum,
                Min_Processby_DiagCD,
                Min_ThruDate_DiagCD,
                Min_ProcessBy_PCN,
                Min_ThruDate_PCN,
                Processed_Priority_Thru_Date,
                Thru_Priority_Processed_By,
                RAFT_ORIG,
                Processed_Priority_FileID,
                Processed_Priority_RAPS_Source_ID,
                Processed_Priority_Provider_ID,
                Processed_Priority_RAC,
                Thru_Priority_FileID,
                Thru_Priority_RAPS_Source_ID,
                Thru_Priority_Provider_ID,
                Thru_Priority_RAC,
                IMFFlag,
                Factor_Desc_ORIG,
                Factor_Desc_EstRecev,
                LoadDateTime,
                Aged,
                LastAssignedHICN
            )
            SELECT p.PlanID,
                   p.HICN,
                   p.PaymentYear,
                   p.PaymStart,
                   p.ModelYear,
                   p.Factor_category,
                   p.Factor_Desc,
                   p.Factor,
                   p.RAFT,
                   p.HCC_Number,
                   p.Min_ProcessBy,
                   p.Min_ThruDate,
                   p.Min_ProcessBy_SeqNum,
                   p.Min_ThruDate_SeqNum,
                   p.Min_Processby_DiagCD,
                   p.Min_ThruDate_DiagCD,
                   p.Min_ProcessBy_PCN,
                   p.Min_ThruDate_PCN,
                   p.Processed_Priority_Thru_Date,
                   p.Thru_Priority_Processed_By,
                   p.RAFT_ORIG,
                   p.Processed_Priority_FileID,
                   p.Processed_Priority_RAPS_Source_ID,
                   p.Processed_Priority_Provider_ID,
                   p.Processed_Priority_RAC,
                   p.Thru_Priority_FileID,
                   p.Thru_Priority_RAPS_Source_ID,
                   p.Thru_Priority_Provider_ID,
                   p.Thru_Priority_RAC,
                   p.IMFFlag,
                   p.Factor_Desc_ORIG,
                   p.Factor_Desc_EstRecev,
                   p.LoadDateTime,
                   p.Aged,
                   p.LastAssignedHICN
            FROM rev.tbl_Summary_RskAdj_RAPS_MOR_Combined p
                INNER JOIN #SummLoad r
                    ON p.LoadDateTime = r.SummLoadDate
                       AND p.Factor_category = r.Factor_category
            WHERE p.PaymentYear = @PaymentYear
                  ;

            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('004', 0, 1) WITH NOWAIT;
            END;

            /* Update HistoryRskadjActivity Table*/
            UPDATE a
            SET a.EDate = GETDATE(),
                a.AdditionalRows = @RowCnt
            FROM rev.HistoryRskadjActivity a
            WHERE HistoryRskadjActivityID = @HistoryRskadjActivityID;


            IF @Debug = 1
            BEGIN
                PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, GETDATE()) AS VARCHAR(10)) + ' secs | '
                      + CONVERT(CHAR(12), GETDATE() - @ET, 114) + ' | ' + CONVERT(CHAR(23), GETDATE(), 121);
                SET @ET = GETDATE();
                RAISERROR('005', 0, 1) WITH NOWAIT;
            END;
        END;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg VARCHAR(2000);
        SET @ErrorMsg
            = 'Error: ' + ISNULL(ERROR_PROCEDURE(), 'script') + ': ' + ERROR_MESSAGE() + ', Error Number: '
              + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR(50));

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH;
END;
GO


