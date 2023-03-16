CREATE PROCEDURE [rev].[EstRecevHistoryLoadPartC]
(
    @Payment_Year VARCHAR(4),
    @MYU VARCHAR(1)
)
AS
BEGIN
    SET NOCOUNT ON;

    /**********************************************************************************************        
* Name			:	rev.[EstRecevHistoryLoadPartC].proc     			     	              *                                                     
* Type 			:	Stored Procedure									                      *                
* Author       	:	Madhuri Suri     									                      *
* Date          :	7/22/2019											                      *	
* Ticket        :   76451                                                                     *
* Version		:   Initial     												              *
* Modifications                                                                               *
***********************************************************************************************
Version     Modified By     TFS           Date        Description                             *
1.1         D.Waddell       79669/RRI-40  9/30/20     Insert into log table for History       *
*                                                     Loading.                                *                
***********************************************************************************************
* Description	:	Populates History Data into Hst schema tables once evry month             *
*                                                                                             * 
**********************************************************************************************/


    --DECLARE @Payment_Year VARCHAR(4) = 2018
    --            DECLARE @MYU VARCHAR(1) = 'N'

    DECLARE @PaymentYear VARCHAR(4) = @Payment_Year,
            @MYUFlag VARCHAR(1) = @MYU;

    DECLARE @Error_Message VARCHAR(8000);
    BEGIN TRY

        DECLARE @TenthofMonth DATETIME = (DATEADD(dd, 10 - 1, DATEADD(mm, DATEDIFF(mm, 0, CURRENT_TIMESTAMP), 0)));
        DECLARE @hstLoaddate DATETIME =
                (
                    SELECT TOP 1
                           ISNULL(Populated, '1900-01-01') Populated
                    FROM hst.EstRecvDetailPartC
                    WHERE PaymentYear = @PaymentYear
                          AND MYUFlag = @MYUFlag
                );
        DECLARE @revLoaddate DATETIME =
                (
                    SELECT TOP 1
                           ISNULL(Populated, '1900-01-01') Populated
                    FROM rev.EstRecvDetailPartC
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
                   PartCDFlag = 'Part C',
                   Process = 'rev.EstRecevHistoryLoadPartC',
                   TableName = 'hst.EstRecvDetailPartC',
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

            INSERT INTO hst.EstRecvDetailPartC
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
                MAXMOR,
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
                MemberMonth,
                ActualFinalPaid,
                MARiskRevenue_A_B,
                MARiskRevenueRecalc,
                MARiskRevenueVariance,
                TotalPremiumYTD,
                MidYearUpdateActual,
                Populated,
                ESRD,
                DefaultInd,
                PlanIdentifier,
                AgedStatus,
                SourceType,
                PartitionKey,
                RAPSProjectedRiskScore,
                RAPSProjectedRiskScoreAfterDelete,
                EDSProjectedRiskScore,
                EDSProjectedRiskScoreAfterDelete
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
                   MAXMOR,
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
                   MemberMonth,
                   ActualFinalPaid,
                   MARiskRevenue_A_B,
                   MARiskRevenueRecalc,
                   MARiskRevenueVariance,
                   TotalPremiumYTD,
                   MidYearUpdateActual,
                   Populated,
                   ESRD,
                   DefaultInd,
                   PlanIdentifier,
                   AgedStatus,
                   SourceType,
                   PartitionKey,
                   RAPSProjectedRiskScore,
                   RAPSProjectedRiskScoreAfterDelete,
                   EDSProjectedRiskScore,
                   EDSProjectedRiskScoreAfterDelete
            FROM rev.EstRecvDetailPartC
            WHERE PaymentYear = @PaymentYear
                  AND MYUFlag = @MYUFlag
                  AND Populated = @revLoaddate;

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
                   PartCDFlag = 'Part C',
                   Process = 'rev.EstRecevHistoryLoadPartC',
                   TableName = 'hst.RiskScoreFactorsPartC',
                   PaymentYear = @PaymentYear,
                   MYUFlag = @MYUFlag,
                   LastUpdatedDate = @revLoaddate,
                   BDate = GETDATE(),
                   EDate = NULL,
                   AdditionalRows = NULL,
                   RunBy = @UserID;

            SET @HistoryRskadjActivityID = SCOPE_IDENTITY();


            /*RiskScore Factors Table insert*/


            INSERT INTO hst.RiskScoreFactorsPartC
            (
                PaymentYear,
                MYUFlag,
                PlanIdentifier,
                HICN,
                AgeGrpID,
                Populated,
                HCCLabel,
                Factor,
                HCCHierarchy,
                FactorHierarchy,
                HCCDeleteHierarchy,
                FactorDeleteHierarchy,
                PartCRAFTProjected,
                PartCRAFTMMR,
                ModelYear,
                DeleteFlag,
                DateForFactors,
                HCCNumber,
                Aged,
                SourceType,
                PartitionKey
            )
            SELECT PaymentYear,
                   MYUFlag,
                   PlanIdentifier,
                   HICN,
                   AgeGrpID,
                   Populated,
                   HCCLabel,
                   Factor,
                   HCCHierarchy,
                   FactorHierarchy,
                   HCCDeleteHierarchy,
                   FactorDeleteHierarchy,
                   PartCRAFTProjected,
                   PartCRAFTMMR,
                   ModelYear,
                   DeleteFlag,
                   DateForFactors,
                   HCCNumber,
                   Aged,
                   SourceType,
                   PartitionKey
            FROM rev.RiskScoreFactorsPartC
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
                   PartCDFlag = 'Part C',
                   Process = 'rev.EstRecevHistoryLoadPartC',
                   TableName = 'hst.RiskScoresPartC',
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

            INSERT INTO hst.RiskScoresPartC
            (
                Planidentifier,
                HICN,
                PaymentYear,
                MYUFlag,
                PartCRAFTProjected,
                RiskScoreCalculated,
                ModelYear,
                DeleteYN,
                DateForFactors,
                SourceType,
                PartitionKey,
                Populated
            )
            SELECT Planidentifier,
                   HICN,
                   PaymentYear,
                   MYUFlag,
                   PartCRAFTProjected,
                   RiskScoreCalculated,
                   ModelYear,
                   DeleteYN,
                   DateForFactors,
                   SourceType,
                   PartitionKey,
                   Populated
            FROM rev.RiskScoresPartC
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

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMsg VARCHAR(2000);
        SET @ErrorMsg
            = 'Error: ' + ISNULL(ERROR_PROCEDURE(), 'script') + ': ' + ERROR_MESSAGE() + ', Error Number: '
              + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' Line: ' + CAST(ERROR_LINE() AS VARCHAR(50));

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH;
END;
