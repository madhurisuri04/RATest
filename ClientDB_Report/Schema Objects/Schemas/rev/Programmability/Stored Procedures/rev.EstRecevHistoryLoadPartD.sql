CREATE PROCEDURE [rev].[EstRecevHistoryLoadPartD]
(
    @Payment_Year VARCHAR(4),
    @MYU VARCHAR(1)
)
AS
BEGIN
    SET NOCOUNT ON;

    /*************************************************************************************************************        
* Name			:	rev.[EstRecevHistoryLoadPartD].proc     			     	                             *                                                     
* Type 			:	Stored Procedure									                                     *                
* Author       	:	Madhuri Suri     									                                     *
* Date          :	10/14/2019											                                     *	
* Ticket        :                                                                                            *
* Version		:   Initial     												                             *
* Description	:	Populates History Data for ER Part D into Hst schema tables once evry month              *
*                                                                                                            *
Version     Modified By     TFS           Date        Description                                            *
1.1         D.Waddell       79669/RRI-40  9/30/20     Insert into log table for History                      *
*                                                     Loading.                                               *                
**************************************************************************************************************
* Description	:	Populates History Data into Hst schema tables once evry month                            *
*                                                                                                            * 
*************************************************************************************************************/

    --DECLARE @Payment_Year VARCHAR(4) = 2018
    --            DECLARE @MYU VARCHAR(1) = 'N'

    DECLARE @PaymentYear VARCHAR(4) = @Payment_Year,
            @MYUFlag VARCHAR(1) = @MYU;

    SET NOCOUNT ON;


    BEGIN TRY

        BEGIN TRANSACTION ERHistoryRunProc;
        DECLARE @Message VARCHAR(100);
        SET @Message = 'DATE : ' + CONVERT(VARCHAR(30), GETDATE(), 113) + ' - Start script - [ERHistoryRunProc]';
        RAISERROR(@Message, 0, 1) WITH NOWAIT;

        DECLARE @TenthofMonth DATETIME = (DATEADD(dd, 10 - 1, DATEADD(mm, DATEDIFF(mm, 0, CURRENT_TIMESTAMP), 0)));
        DECLARE @hstLoaddate DATETIME =
                (
                    SELECT TOP 1
                           ISNULL(loaddate, '1900-01-01') Populated
                    FROM hst.EstRecvDetailPartD
                    WHERE PaymentYear = @PaymentYear
                          AND MYUFlag = @MYUFlag
                );
        DECLARE @revLoaddate DATETIME =
                (
                    SELECT TOP 1
                           ISNULL(loaddate, '1900-01-01') Populated
                    FROM rev.EstRecvDetailPartD
                    WHERE PaymentYear = @PaymentYear
                          AND MYUFlag = @MYUFlag
                );
        DECLARE @UserID VARCHAR(128) = SYSTEM_USER;
        DECLARE @RowCnt INT = 0;
        DECLARE @HistoryRskadjActivityID INT;


        DECLARE @tblGroupingID INT;


        --select @FirstofMonth, @revLoaddate, (ISNULL(@hstLoaddate, '1900-01-01'))

        IF (
               (GETDATE() >= @TenthofMonth)
               AND (ISNULL(@hstLoaddate, '1900-01-01') < @TenthofMonth)
               AND ((ISNULL(@revLoaddate, '1900-01-01')) > (ISNULL(@hstLoaddate, '1900-01-01')))
           )
        BEGIN
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
                   PartCDFlag = 'Part D',
                   Process = 'rev.EstRecevHistoryLoadPartD',
                   TableName = 'hst.EstRecvDetailPartD',
                   PaymentYear = @PaymentYear,
                   MYUFlag = @MYUFlag,
                   LastUpdatedDate = @revLoaddate,
                   BDate = GETDATE(),
                   EDate = NULL,
                   AdditionalRows = NULL,
                   RunBy = @UserID;

            SET @HistoryRskadjActivityID = SCOPE_IDENTITY();
            SET @tblGroupingID = @HistoryRskadjActivityID;

            /* Update Grouping ID */
            UPDATE m
            SET m.GroupingId = @tblGroupingID
            FROM rev.HistoryRskadjActivity m
            WHERE m.HistoryRskadjActivityID = @HistoryRskadjActivityID;



            /*Detail Table Insert*/

            INSERT INTO hst.EstRecvDetailPartD
            (
                HPlanID,
                PaymentYear,
                MYUFlag,
                DateForFactors,
                HICN,
                PayStart,
                RAFTRestated,
                RAFTMMR,
                Agegrp,
                Sex,
                Medicaid,
                ORECRestated,
                MaxMOR,
                MidYearUpdateFlag,
                AgeGroupID,
                GenderID,
                SCC,
                PBP,
                Bid,
                NewEnrolleeFlagError,
                MonthsInDCP,
                ISARUsed,
                RiskScoreCalculated,
                RiskScoreMMR,
                RSDifference,
                EstimatedRecvAmount,
                ProjectedRiskScore,
                EstimatedRecvAmountAfterDelete,
                AmountDeleted,
                RiskScoreNewAfterDelete,
                DifferenceAfterDelete,
                ProjectedRiskScoreAfterDelete,
                RAPSProjectedRiskScore,
                RAPSProjectedRiskScoreAfterDelete,
                EDSProjectedRiskScore,
                EDSProjectedRiskScoreAfterDelete,
                MemberMonth,
                ActualFinalPaid,
                MARiskRevenueRecalc,
                MARiskRevenueVariance,
                TotalPremiumYTD,
                MidYearUpdateActual,
                LowIncomeMultiplier,
                PartDBasicPremiumAmount,
                PlanIdentifier,
                AgedStatus,
                SourceType,
                PartitionKey,
                LoadDate,
                UserID,
                LastAssignedHICN
            )
            SELECT HPlanID,
                   PaymentYear,
                   MYUFlag,
                   DateForFactors,
                   HICN,
                   PayStart,
                   RAFTRestated,
                   RAFTMMR,
                   Agegrp,
                   Sex,
                   Medicaid,
                   ORECRestated,
                   MaxMOR,
                   MidYearUpdateFlag,
                   AgeGroupID,
                   GenderID,
                   SCC,
                   PBP,
                   Bid,
                   NewEnrolleeFlagError,
                   MonthsInDCP,
                   ISARUsed,
                   RiskScoreCalculated,
                   RiskScoreMMR,
                   RSDifference,
                   EstimatedRecvAmount,
                   ProjectedRiskScore,
                   EstimatedRecvAmountAfterDelete,
                   AmountDeleted,
                   RiskScoreNewAfterDelete,
                   DifferenceAfterDelete,
                   ProjectedRiskScoreAfterDelete,
                   RAPSProjectedRiskScore,
                   RAPSProjectedRiskScoreAfterDelete,
                   EDSProjectedRiskScore,
                   EDSProjectedRiskScoreAfterDelete,
                   MemberMonth,
                   ActualFinalPaid,
                   MARiskRevenueRecalc,
                   MARiskRevenueVariance,
                   TotalPremiumYTD,
                   MidYearUpdateActual,
                   LowIncomeMultiplier,
                   PartDBasicPremiumAmount,
                   PlanIdentifier,
                   AgedStatus,
                   SourceType,
                   PartitionKey,
                   LoadDate,
                   UserID,
                   LastAssignedHICN
            FROM rev.EstRecvDetailPartD
            WHERE PaymentYear = @PaymentYear
                  AND MYUFlag = @MYUFlag
                  AND loaddate = @revLoaddate;

            SET @RowCnt = @@ROWCOUNT;

            /* Update HistoryRskadjActivity Table*/
            UPDATE a
            SET a.EDate = GETDATE(),
                a.AdditionalRows = @RowCnt
            FROM rev.HistoryRskadjActivity a
            WHERE HistoryRskadjActivityID = @HistoryRskadjActivityID;



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
            SELECT GroupingID = @tblGroupingID,
                   PartCDFlag = 'Part D',
                   Process = 'rev.EstRecevHistoryLoadPartD',
                   TableName = 'hst.RiskScoreFactorsPartD',
                   PaymentYear = @PaymentYear,
                   MYUFlag = @MYUFlag,
                   LastUpdatedDate = @revLoaddate,
                   BDate = GETDATE(),
                   EDate = NULL,
                   AdditionalRows = NULL,
                   RunBy = @UserID;

            SET @HistoryRskadjActivityID = SCOPE_IDENTITY();



            /*RiskScore Factors Table insert*/


            INSERT INTO hst.RiskScoreFactorsPartD
            (
                PaymentYear,
                MYUFlag,
                PlanIdentifier,
                HICN,
                AgeGrpID,
                HCCLabel,
                Factor,
                HCCHierarchy,
                FactorHierarchy,
                HCCDeleteHierarchy,
                FactorDeleteHierarchy,
                PartDRAFTProjected,
                PartDRAFTMMR,
                ModelYear,
                DeleteFlag,
                DateForFactors,
                HCCNumber,
                Aged,
                SourceType,
                PartitionKey,
                LoadDate,
                UserID
            )
            SELECT PaymentYear,
                   MYUFlag,
                   PlanIdentifier,
                   HICN,
                   AgeGrpID,
                   HCCLabel,
                   Factor,
                   HCCHierarchy,
                   FactorHierarchy,
                   HCCDeleteHierarchy,
                   FactorDeleteHierarchy,
                   PartDRAFTProjected,
                   PartDRAFTMMR,
                   ModelYear,
                   DeleteFlag,
                   DateForFactors,
                   HCCNumber,
                   Aged,
                   SourceType,
                   PartitionKey,
                   LoadDate,
                   UserID
            FROM rev.RiskScoreFactorsPartD
            WHERE PaymentYear = @PaymentYear
                  AND MYUFlag = @MYUFlag;


            SET @RowCnt = @@ROWCOUNT;

            /* Update HistoryRskadjActivity Table*/
            UPDATE a
            SET a.EDate = GETDATE(),
                a.AdditionalRows = @RowCnt
            FROM rev.HistoryRskadjActivity a
            WHERE HistoryRskadjActivityID = @HistoryRskadjActivityID;

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
            SELECT GroupingID = @tblGroupingID,
                   PartCDFlag = 'Part D',
                   Process = 'rev.EstRecevHistoryLoadPartD',
                   TableName = 'hst.RiskScoresPartD',
                   PaymentYear = @PaymentYear,
                   MYUFlag = @MYUFlag,
                   LastUpdatedDate = @revLoaddate,
                   BDate = GETDATE(),
                   EDate = NULL,
                   AdditionalRows = NULL,
                   RunBy = @UserID;

            SET @HistoryRskadjActivityID = SCOPE_IDENTITY();


            SET @RowCnt = 0;


            /*Risk Scores Table insert */

            INSERT INTO hst.RiskScoresPartD
            (
                Planidentifier,
                HICN,
                PaymentYear,
                MYUFlag,
                PartDRAFTProjected,
                RiskScoreCalculated,
                ModelYear,
                DeleteYN,
                DateForFactors,
                SourceType,
                PartitionKey,
                LoadDate,
                UserID
            )
            SELECT Planidentifier,
                   HICN,
                   PaymentYear,
                   MYUFlag,
                   PartDRAFTProjected,
                   RiskScoreCalculated,
                   ModelYear,
                   DeleteYN,
                   DateForFactors,
                   SourceType,
                   PartitionKey,
                   LoadDate,
                   UserID
            FROM rev.RiskScoresPartD
            WHERE PaymentYear = @PaymentYear
                  AND MYUFlag = @MYUFlag;


            SET @RowCnt = @@ROWCOUNT;
            /* Update HistoryRskadjActivity Table*/

            UPDATE a
            SET a.EDate = GETDATE(),
                a.AdditionalRows = @RowCnt
            FROM rev.HistoryRskadjActivity a
            WHERE HistoryRskadjActivityID = @HistoryRskadjActivityID;

        END;

        SET @Message = 'DATE : ' + CONVERT(VARCHAR(30), GETDATE(), 113) + ' - End script';
        RAISERROR(@Message, 0, 1) WITH NOWAIT;
        COMMIT TRANSACTION ERHistoryRunProc;
    END TRY
    BEGIN CATCH

        IF (XACT_STATE() = 1 OR XACT_STATE() = -1)
        BEGIN
            PRINT 'ROLLBACK TRANSACTION';
            ROLLBACK TRANSACTION ERHistoryRunProc;
        END;

        DECLARE @ERRORMSG VARCHAR(2000);
        SET @ERRORMSG
            = 'Error: ' + ISNULL(ERROR_PROCEDURE(), 'script') + ': ' + ERROR_MESSAGE() + ', Error Number: '
              + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR(50));

        RAISERROR(@ERRORMSG, 16, 1);

    END CATCH;

    SET NOCOUNT OFF;
END;