CREATE PROCEDURE [rev].[LoadPartCNewHCCOutputMParameterHistory]
(@Payment_Year VARCHAR(4))
AS
BEGIN
    SET NOCOUNT ON;

    /************************************************************************************************************************        
* Name			:	rev.[LoadPartCNewHCCOutputMParameterHistory].proc     			     	                                *                                                     
* Type 			:	Stored Procedure									                                                    *                
* Author       	:	D. Waddell    	       								                                                    *
* Date          :	9/3/2019      											                                                *	
* Ticket        :   76647  (RE-6186)                                                                                        *
* Description	:	Populates History Data into [rev].[PartCNewHCCOutputMParameter] tables once evry month                  *
* Version History :																											*
* ======================================================================================================================	*
* Author			Date		Version#    TFS Ticket#			Description													*	
* -----------------	----------  --------    -----------			------------												*
* D.Waddell		 2019-09-03 	1.0 		76647/ RE-6186		Initial														*
* D. Waddell     2019-10-23     1.1         76984/RE- 6707      Resolve EDS History Loading Issue                           * 
* D. Waddell     2020-09-30     1.2         79669/RRI-40		Insert into log table for History Load.                     *
*****************************************************************************************************************************/

    --DECLARE @Payment_Year VARCHAR(4) = 2018


    DECLARE @PaymentYear VARCHAR(4) = @Payment_Year;


    DECLARE @Error_Message VARCHAR(8000);
    BEGIN TRY
        DECLARE @TenthofMonth DATETIME = (DATEADD(dd, 10 - 1, DATEADD(mm, DATEDIFF(mm, 0, CURRENT_TIMESTAMP), 0)));

        IF (OBJECT_ID('tempdb.dbo.#RevLoad') IS NOT NULL)
        BEGIN
            DROP TABLE #RevLoad;
        END;

        DECLARE @UserID VARCHAR(128) = SYSTEM_USER;
        DECLARE @RowCnt INT = 0;
        DECLARE @HistoryRskadjActivityID INT;
        DECLARE @tblGroupingID INT;
        DECLARE @revLoaddate DATETIME;
        CREATE TABLE #RevLoad
        (
            EncounterSource VARCHAR(5) NULL,
            RevLoadDate DATETIME NOT NULL,
            IsAfter10thDayFlag INT NOT NULL
                DEFAULT 0,
            LoadHistryFlag INT NOT NULL
                DEFAULT 0
        );

        IF (OBJECT_ID('tempdb.dbo.#HistLoad') IS NOT NULL)
        BEGIN
            DROP TABLE #HistLoad;
        END;

        CREATE TABLE #HistLoad
        (
            EncounterSource VARCHAR(5) NULL,
            HistoryLoadDate DATETIME NOT NULL,
            UpdateHistryFlag INT NOT NULL
                DEFAULT 0
        );


        /* Insert into #RevLoad table*/

        INSERT INTO #RevLoad
        (
            EncounterSource,
            RevLoadDate
        )
        SELECT EncounterSource,
               MAX(ISNULL(LoadDate, '1900-01-01')) RevLoadDate
        FROM rev.PartCNewHCCOutputMParameter
        WHERE PaymentYear = @PaymentYear
              AND EncounterSource IN ( 'EDS', 'RAPS' )
        GROUP BY EncounterSource,
                 LoadDate
        ORDER BY EncounterSource,
                 LoadDate;

        SET @revLoaddate =
        (
            SELECT MAX(RevLoadDate) FROM #RevLoad
        );


        /* Insert into #HistLoad Table*/
        INSERT INTO #HistLoad
        (
            EncounterSource,
            HistoryLoadDate
        )
        SELECT EncounterSource,
               MAX(ISNULL(LoadDate, '1900-01-01')) HistoryLoadDate
        FROM hst.PartCNewHCCOutputMParameter
        WHERE PaymentYear = @PaymentYear
              AND EncounterSource IN ( 'EDS', 'RAPS' )
        GROUP BY EncounterSource
        ORDER BY EncounterSource;


        UPDATE #RevLoad
        SET IsAfter10thDayFlag = 1
        WHERE RevLoadDate >= @TenthofMonth;


        UPDATE r
        SET r.LoadHistryFlag = 1
        FROM #RevLoad r
            LEFT JOIN #HistLoad h
                ON r.EncounterSource = h.EncounterSource
        WHERE r.RevLoadDate >= ISNULL(h.HistoryLoadDate, '1900-01-01')
              AND ISNULL(h.HistoryLoadDate, '1900-01-01') <= @TenthofMonth;




        --select @FirstofMonth, @revLoaddate, (ISNULL(@hstLoaddate, '1900-01-01'))

        IF (GETDATE() >= @TenthofMonth)
        BEGIN

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
                   Process = 'rev.LoadPartCNewHCCOutputMParameterHistory',
                   TableName = 'hst.PartCNewHCCOutputMParameter',
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
            SET m.GroupingId = @tblGroupingID
            FROM rev.HistoryRskadjActivity m
            WHERE m.HistoryRskadjActivityID = @HistoryRskadjActivityID;

            /*[hst].[PartCNewHCCOutputMParameter] Table Insert*/

            INSERT INTO hst.PartCNewHCCOutputMParameter
            (
                PaymentYear,
                ModelYear,
                PaymentStartDate,
                ProcessedByStartDate,
                ProcessedByEndDate,
                ProcessedByFlag,
                EncounterSource,
                PlanID,
                HICN,
                RAFactorType,
                HCC,
                HCCDescription,
                HCCFactor,
                HierarchyHCC,
                HierarchyHCCFactor,
                PreAdjustedFactor,
                AdjustedFinalFactor,
                HCCProcessedPCN,
                HierarchyHCCProcessedPCN,
                UniqueConditions,
                MonthsInDCP,
                BidAmount,
                EstimatedValue,
                RollForwardMonths,
                ActiveIndicatorForRollForward,
                PBP,
                SCC,
                ProcessedPriorityProcessedByDate,
                ProcessedPriorityThruDate,
                ProcessedPriorityDiag,
                ProcessedPriorityFileID,
                ProcessedPriorityRAC,
                ProcessedPriorityRAPSSourceID,
                DOSPriorityProcessedByDate,
                DOSPriorityThruDate,
                DOSPriorityPCN,
                DOSPriorityDiag,
                DOSPriorityFileID,
                DOSPriorityRAC,
                DOSPriorityRAPSSourceID,
                ProcessedPriorityICN,
                ProcessedPriorityEncounterID,
                ProcessedPriorityReplacementEncounterSwitch,
                ProcessedPriorityClaimID,
                ProcessedPrioritySecondaryClaimID,
                ProcessedPrioritySystemSource,
                ProcessedPriorityRecordID,
                ProcessedPriorityVendorID,
                ProcessedPrioritySubProjectID,
                ProcessedPriorityMatched,
                DOSPriorityICN,
                DOSPriorityEncounterID,
                DOSPriorityReplacementEncounterSwitch,
                DOSPriorityClaimID,
                DOSPrioritySecondaryClaimID,
                DOSPrioritySystemSource,
                DOSPriorityRecordID,
                DOSPriorityVendorID,
                DOSPrioritySubProjectID,
                DOSPriorityMatched,
                ProviderID,
                ProviderLast,
                ProviderFirst,
                ProviderGroup,
                ProviderAddress,
                ProviderCity,
                ProviderState,
                ProviderZip,
                ProviderPhone,
                ProviderFax,
                TaxID,
                NPI,
                SweepDate,
                PopulatedDate,
                AgedStatus,
                UserID,
                LoadDate,
                ProcessedPriorityMAO004ResponseDiagnosisCodeID,
                DOSPriorityMAO004ResponseDiagnosisCodeID,
                ProcessedPriorityMatchedEncounterICN,
                DOSPriorityMatchedEncounterICN
            )
            SELECT p.PaymentYear,
                   p.ModelYear,
                   p.PaymentStartDate,
                   p.ProcessedByStartDate,
                   p.ProcessedByEndDate,
                   p.ProcessedByFlag,
                   p.EncounterSource,
                   p.PlanID,
                   p.HICN,
                   p.RAFactorType,
                   p.HCC,
                   p.HCCDescription,
                   p.HCCFactor,
                   p.HierarchyHCC,
                   p.HierarchyHCCFactor,
                   p.PreAdjustedFactor,
                   p.AdjustedFinalFactor,
                   p.HCCProcessedPCN,
                   p.HierarchyHCCProcessedPCN,
                   p.UniqueConditions,
                   p.MonthsInDCP,
                   p.BidAmount,
                   p.EstimatedValue,
                   p.RollForwardMonths,
                   p.ActiveIndicatorForRollForward,
                   p.PBP,
                   p.SCC,
                   p.ProcessedPriorityProcessedByDate,
                   p.ProcessedPriorityThruDate,
                   p.ProcessedPriorityDiag,
                   p.ProcessedPriorityFileID,
                   p.ProcessedPriorityRAC,
                   p.ProcessedPriorityRAPSSourceID,
                   p.DOSPriorityProcessedByDate,
                   p.DOSPriorityThruDate,
                   p.DOSPriorityPCN,
                   p.DOSPriorityDiag,
                   p.DOSPriorityFileID,
                   p.DOSPriorityRAC,
                   p.DOSPriorityRAPSSourceID,
                   p.ProcessedPriorityICN,
                   p.ProcessedPriorityEncounterID,
                   p.ProcessedPriorityReplacementEncounterSwitch,
                   p.ProcessedPriorityClaimID,
                   p.ProcessedPrioritySecondaryClaimID,
                   p.ProcessedPrioritySystemSource,
                   p.ProcessedPriorityRecordID,
                   p.ProcessedPriorityVendorID,
                   p.ProcessedPrioritySubProjectID,
                   p.ProcessedPriorityMatched,
                   p.DOSPriorityICN,
                   p.DOSPriorityEncounterID,
                   p.DOSPriorityReplacementEncounterSwitch,
                   p.DOSPriorityClaimID,
                   p.DOSPrioritySecondaryClaimID,
                   p.DOSPrioritySystemSource,
                   p.DOSPriorityRecordID,
                   p.DOSPriorityVendorID,
                   p.DOSPrioritySubProjectID,
                   p.DOSPriorityMatched,
                   p.ProviderID,
                   p.ProviderLast,
                   p.ProviderFirst,
                   p.ProviderGroup,
                   p.ProviderAddress,
                   p.ProviderCity,
                   p.ProviderState,
                   p.ProviderZip,
                   p.ProviderPhone,
                   p.ProviderFax,
                   p.TaxID,
                   p.NPI,
                   p.SweepDate,
                   p.PopulatedDate,
                   p.AgedStatus,
                   p.UserID,
                   p.LoadDate,
                   p.ProcessedPriorityMAO004ResponseDiagnosisCodeID,
                   p.DOSPriorityMAO004ResponseDiagnosisCodeID,
                   p.ProcessedPriorityMatchedEncounterICN,
                   p.DOSPriorityMatchedEncounterICN
            FROM rev.PartCNewHCCOutputMParameter p
                INNER JOIN #RevLoad r
                    ON p.LoadDate = r.RevLoadDate
                       AND p.EncounterSource = r.EncounterSource
            WHERE p.PaymentYear = @PaymentYear
                  AND
                  (
                      r.IsAfter10thDayFlag = 1
                      AND r.LoadHistryFlag = 1
                  );

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
GO

