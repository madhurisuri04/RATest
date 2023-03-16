CREATE PROCEDURE [rev].[sprHCCMemberDetail]
    @Payment_Year VARCHAR(4),
    @AgedStatus VARCHAR(25),
    @PartCorD VARCHAR(2),
    @PlanID VARCHAR(5),
    @RAFT VARCHAR(5),
    @EncounterSource VARCHAR(10)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- =============================================
    -- Author:		D. Waddell
    -- Create date: 8/28/2020
    -- Description:	HCCs by Member (Source From Report Lvl- inlc. logic contained prior Plan Lvl version )
    -- Target DB:		ClientDB_Report
    -- TFS: 79183  (RRI-142)	
    -- =============================================
    DECLARE @SQL VARCHAR(4000);
    --DECLARE @Payment_Year VARCHAR(4) = 2020,
    --        @AgedStatus VARCHAR(25) = 'Aged',
    --        @PartCorD VARCHAR(2) = 'C';
    --DECLARE @InsertTableName VARCHAR(100) = '';
    --DECLARE @PlanID VARCHAR(5) = 'H1099';
    --DECLARE @RAFT VARCHAR(5) = 'CN';
    --DECLARE @EncounterSource VARCHAR(10) = 'RAPS';

    --Create table for report
    IF OBJECT_ID('[tempdb].[dbo].[#spr_HCC_Member_Detail_Final]', 'U') IS NOT NULL
        DROP TABLE #spr_HCC_Member_Detail_Final;
    CREATE TABLE #spr_HCC_Member_Detail_Final
    (
        Payment_Year VARCHAR(6),
        PartCorD VARCHAR(1),
        Category VARCHAR(50),
        [Description] VARCHAR(255),
        Factor FLOAT,
        Factor_Normalized FLOAT,
        Count_Members INT,
        Avg_Bid MONEY,
        PMPM MONEY,
        Est_Impact MONEY,
        NormalizationFactor DECIMAL(18, 4),
        CI DECIMAL(18, 4), --
        EncounterSource VARCHAR(5),
        RAFT VARCHAR(5),
        PlanID VARCHAR(5),
        AgedStatus VARCHAR(30)
    );
    IF @PartCorD = 'C'
    BEGIN

        INSERT INTO #spr_HCC_Member_Detail_Final
        (
            Payment_Year,
            PartCorD,
            Category,
            [Description],
            Factor,
            Factor_Normalized,
            Count_Members,
            Avg_Bid,
            PMPM,
            Est_Impact,
            NormalizationFactor,
            CI,
            EncounterSource,
            PlanID,
            RAFT,
            AgedStatus
        )
        SELECT DISTINCT
               A.PaymentYear [Payment_Year],
               PartCorD = 'C',
               A.[HCC] [Category],
               A.[HCCDescription] [Description],
               A.[HCCFactor] [Factor],
               AVG(A.AdjustedFinalFactor) AS Factor_Normalized,
               COUNT(DISTINCT A.HICN) [Count_Members],
               AVG(A.BidAmount) [Avg_Bid],
               SUM(A.EstimatedValue) / COUNT(DISTINCT A.HICN + CAST(A.PaymentStartDate AS VARCHAR(30))) [PMPM],
               SUM(A.EstimatedValue) [Est_Impact],
               CASE
                   WHEN C.Segment = 'CMS-HCC' THEN
                       AVG(C.PartCNormalizationFactor)
                   WHEN C.Segment = 'Functioning Graft' THEN
                       AVG(C.FunctioningGraftFactor)
                   WHEN C.Segment IN ( 'Dialysis', 'Transplant' ) THEN
                       AVG(C.ESRDDialysisFactor)
               END AS [Norm_Factor_Part_C],
               C.CodingIntensity [CI],
               A.EncounterSource [EncounterSource],
               A.PlanID [PlanID],
               A.[RAFactorType] [RAFT],
               A.AgedStatus
        FROM [rev].[PartCNewHCCOutputMParameter] A
            LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC C
                ON C.PaymentYear = A.[PaymentYear]
                   AND C.RAFactorType = A.[RAFactorType]
                   AND A.EncounterSource = C.SubmissionModel
        WHERE A.[PaymentYear] = @Payment_Year
              AND A.EncounterSource = @EncounterSource
              AND A.PlanID = @PlanID
              AND A.RAFactorType = @RAFT
              AND A.AgedStatus = @AgedStatus
        GROUP BY A.EncounterSource,
                 A.PlanID,
                 A.[RAFactorType],
                 A.AgedStatus,
                 A.[HCC],
                 A.HCCFactor,
                 A.[HCCDescription],
                 A.PaymentYear,
                 C.Segment,
                 C.CodingIntensity;

    END;

    IF @PartCorD = 'D'
    BEGIN

        INSERT INTO #spr_HCC_Member_Detail_Final
        (
            Payment_Year,
            PartCorD,
            Category,
            [Description],
            Factor,
            Factor_Normalized,
            Count_Members,
            Avg_Bid,
            PMPM,
            Est_Impact,
            NormalizationFactor,
            CI,
            EncounterSource,
            PlanID,
            RAFT,
            AgedStatus
        )
        SELECT DISTINCT
               A.PaymentYear [Payment_Year],
               PartCorD = 'D',
               A.RxHCC [Category],
               A.[HCCDescription] [Description],
               A.RxHCCFactor [Factor],
               AVG(A.AdjustedFinalFactor) AS Factor_Normalized,
               COUNT(DISTINCT A.HICN) [Count_Members],
               AVG(A.BidAmount) [Avg_Bid],
               SUM(A.AdjustedFinalFactor * A.BidAmount) [PMPM],
               SUM(A.EstimatedValue) [Est_Impact],
               C.PartD_Factor,
               C.CodingIntensity [CI],
               A.EncounterSource [EncounterSource],
               A.PlanID [PlanID],
               A.[RAFactorType] [RAFT],
               A.AgedStatus
        FROM [rev].[PartDNewHCCOutputMParameter] A
            LEFT JOIN [$(HRPReporting)].dbo.lk_normalization_factors C
                ON C.Year = A.[PaymentYear]
        WHERE A.[PaymentYear] = @Payment_Year
              AND A.EncounterSource = @EncounterSource
              AND A.PlanID = @PlanID
              AND A.RAFactorType = @RAFT
              AND A.AgedStatus = @AgedStatus
        GROUP BY A.EncounterSource,
                 A.PlanID,
                 A.[RAFactorType],
                 A.AgedStatus,
                 A.RxHCC,
                 A.RxHCCFactor,
                 A.[HCCDescription],
                 A.PaymentYear,
                 C.CodingIntensity,
                 C.PartD_Factor;


    END;


    SELECT Payment_Year,
           PartCorD,
           Category,
           [Description],
           Factor,
           Factor_Normalized,
           Count_Members,
           Avg_Bid,
           PMPM,
           Est_Impact,
           NormalizationFactor,
           CI,
           EncounterSource,
           RAFT,
           PlanID,
           AgedStatus
    FROM #spr_HCC_Member_Detail_Final
    WHERE PartCorD = @PartCorD
    ORDER BY Est_Impact DESC;

END;

GO