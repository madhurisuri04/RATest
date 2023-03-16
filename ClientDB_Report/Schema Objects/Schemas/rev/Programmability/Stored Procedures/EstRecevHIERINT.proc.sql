CREATE PROCEDURE [rev].[EstRecevHIERINT]
(
@RowCount INT OUT
)
AS
BEGIN
    SET NOCOUNT ON;

    /************************************************************************        
* Name			:	rev.EstRecevHIERINTc.proc     			     	*                                                     
* Type 			:	Stored Procedure									*                
* Author       	:	Madhuri Suri     									*
* Date          :	04/10/2017											*	
* Ticket        :   
* Version		:        												*
* Description	:	Populates HIER/INT into etl ER tables	            *

***************************************************************************/
    /********************************************************************************************
TICKET       DATE              NAME                DESCRIPTION
64919       6/12/2017          Madhuri Suri  
65509       6/26/2017          Madhuri Suri        EDS Implementation
65862        8/7/2017          Madhuri Suri        ER 1 to ER2 Logic changes
67277       10/9/2017          Madhuri Suri        Factor values for DHCC cmg through wrong  
75089        2/20/2019         Mahduri Suri        ER amount fix for HFHP found issue
75824        4/25/2019         Madhuri Suri        Part C ER 2.0 Minor Changes 
76279        7/25/2019         Madhuri Suri        Part C ER 2.0 EDS and RAPS MMR and MOR correction 
76914		 09/30/2019		   Anand			   APCC Flag - RE -6534			
78841        06/15/20		   D. Waddell		   (RE-8158) Fix [rev].[EstRecevHIERINT] Factor Issue 
RRI-34/79581 09/15/20          Anand               Add Row Count Output Parameter
***********************************************************************************************/
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    DECLARE @populate_date DATETIME = GETDATE();

    /****************
UPDATE DELETES 
******************/
    UPDATE a
    SET DeleteFlag = 1,
        HCCDeleteHierarchy = 'DEL-' + HCCLabel,
        Factor = b.Factor,
        FactorHierarchy = b.factor,
        FactorDeleteHierarchy = 0
    FROM etl.RiskScoreFactorsPartC a
        JOIN rev.ERDeleteHCCOutput b
            ON a.HICN = b.HICN
               AND a.HCCNumber = REPLACE(
                                            REPLACE(
                                                       REPLACE(REPLACE(b.HCC, 'DEL-HCC ', ''), 'DEL-HCC00', ''),
                                                       'DEL-HCC0',
                                                       ''
                                                   ),
                                            'DEL-HCC',
                                            ''
                                        )
               AND a.ModelYear = b.Modelyear
               AND a.PaymentYear = b.Paymentyear --6/7
        LEFT JOIN [$(HRPInternalReportsDB)].dbo.RollupPlan rp
            ON rp.PlanIdentifier = a.PlanIdentifier
    WHERE b.HCC NOT LIKE 'INT%'
          AND b.PlanID = rp.PlanID --6/7
          AND a.SourceType = 'RAPS';

    /**********************************
RAPS HIERARCHY WITH DELETES - INTO BUILDUP 
************************************/
    ----SELECT * FROM etl.RiskScoreFactorsPartC WHERE HCCLabel LIKE 'HIER%'
    IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHY1]', 'U') IS NOT NULL
        DROP TABLE #HIERARCHY1;
    CREATE TABLE #HIERARCHY1
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY,
        HICN VARCHAR(15),
        RAFTRestated VARCHAR(2),
        HCC1 VARCHAR(20),
        HCCNumber INT
    );
    INSERT #HIERARCHY1
    SELECT A.HICN,
           A.PartCRAFTProjected,
           C.HCC_DROP,
           A.HCCNumber
    FROM etl.RiskScoreFactorsPartC A
        INNER JOIN etl.RiskScoreFactorsPartC B
            ON B.HICN = A.HICN
               AND B.PaymentYear = A.PaymentYear
               AND A.DateForFactors = B.DateForFactors
               AND A.PlanIdentifier = B.PlanIdentifier
               AND A.ModelYear = B.ModelYear
               AND A.PartCRAFTProjected = B.PartCRAFTProjected --6/7
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C
            ON B.HCCLabel = C.HCC_KEEP
               AND A.HCCLabel = C.HCC_DROP
               AND A.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND B.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND C.Payment_Year = A.ModelYear
               AND C.Part_C_D_Flag = 'C'
    WHERE A.SourceType IN ( 'RAPS', 'RMOR' );

    IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHY2]', 'U') IS NOT NULL
        DROP TABLE #HIERARCHY2;
    CREATE TABLE #HIERARCHY2
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY,
        HICN VARCHAR(15),
        RAFTRestated VARCHAR(2),
        HCC1 VARCHAR(20),
        HCCNumber INT
    );



    INSERT #HIERARCHY2
    SELECT A.HICN,
           A.PartCRAFTProjected,
           C.HCC_DROP,
           A.HCCNumber
    FROM etl.RiskScoreFactorsPartC A
        INNER JOIN etl.RiskScoreFactorsPartC B
            ON B.HICN = A.HICN
               AND B.PaymentYear = A.PaymentYear
               AND A.DateForFactors = B.DateForFactors
               AND A.PlanIdentifier = B.PlanIdentifier
               AND A.ModelYear = B.ModelYear
               AND A.PartCRAFTProjected = B.PartCRAFTProjected --6/7
               AND A.SourceType = B.SourceType --6/13
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C
            ON B.HCCLabel = C.HCC_KEEP
               AND A.HCCLabel = C.HCC_DROP
               AND A.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND B.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND C.Payment_Year = A.ModelYear
               AND C.Part_C_D_Flag = 'C'
               AND A.PartCRAFTProjected = C.RA_FACTOR_TYPE
    WHERE A.DeleteFlag = 0
          AND B.DeleteFlag = 0
          AND A.SourceType IN ( 'RAPS', 'RMOR' );



    UPDATE A
    SET A.HCCHierarchy = 'HIER-' + HCCLabel,
        A.HCCDeleteHierarchy = 'HIER-' + HCCLabel,
        A.FactorHierarchy = 0,
        A.FactorDeleteHierarchy = 0
    FROM etl.RiskScoreFactorsPartC A
        JOIN #HIERARCHY1 Hier
            ON Hier.HICN = A.HICN
               AND Hier.RAFTRestated = A.PartCRAFTProjected
               AND Hier.HCCNumber = A.HCCNumber
    WHERE A.SourceType IN ( 'RAPS', 'RMOR' );



    /**********************************
EDS PCC HCC Counters - INTO BUILDUP  RE -6534	
************************************/

    IF OBJECT_ID('[tempdb].[dbo].[#EDSHCCCounter]', 'U') IS NOT NULL
        DROP TABLE #EDSHCCCounter;
    CREATE TABLE #EDSHCCCounter
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY,
        SourceType VARCHAR(15),
        PaymentYear VARCHAR(4),
        MYUFlag VARCHAR(1),
        HICN VARCHAR(15),
        PartCRAFTProjected VARCHAR(2),
        PCCLabel VARCHAR(5),
        HCCCounter INT
    );

    INSERT #EDSHCCCounter
    SELECT SourceType,
           a.PaymentYear,
           MYUFlag,
           HICN,
           PartCRAFTProjected,
           PCCLabel = CASE
                          WHEN COUNT(DISTINCT HCCLabel) > 9 THEN
                              'D10P'
                          ELSE
                              'D' + CAST(COUNT(DISTINCT HCCLabel) AS VARCHAR)
                      END,
           HCCCounter = COUNT(DISTINCT HCCLabel)
    FROM etl.RiskScoreFactorsPartC a
        JOIN [$(HRPReporting)].dbo.lk_Risk_Score_Factors_PartC r
            ON a.SourceType = r.SubmissionModel
               AND a.PaymentYear = r.PaymentYear
               AND a.ModelYear = r.ModelYear
               AND a.PartCRAFTProjected = r.RAFactorType
    WHERE r.APCCFlag = 'Y'
          AND a.HCCLabel = a.HCCHierarchy
          AND a.HCCLabel = a.HCCDeleteHierarchy
    --and a.HCCHierarchy = a.HCCDeleteHierarchy
    GROUP BY SourceType,
             a.PaymentYear,
             MYUFlag,
             HICN,
             PartCRAFTProjected;


    INSERT etl.RiskScoreFactorsPartC
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
    SELECT DISTINCT
           HCC.PaymentYear,
           HCC.MYUFlag,
           HCC.PlanIdentifier,
           HCC.HICN,
           HCC.AgeGrpID,
           HCC.Populated,
           C.PCCLabel,
           E.Factor AS Factor,    --TFS 78841  modified 6/15/20 D. Waddell
           C.PCCLabel AS HCC_Hierarchy,
           E.Factor AS FActor_hierarchy,   --TFS 78841  modified 6/15/20 D. Waddell
           C.PCCLabel AS HCC_Delete_Hierarchy,
           E.Factor AS FActor_delete_hierarchy,
           HCC.PartCRAFTProjected,
           HCC.PartCRAFTMMR,
           HCC.ModelYear,
           HCC.DeleteFlag,
           HCC.DateForFactors,
           C.[HCCCounter] AS HCCNumber,
           HCC.aged,
           C.SourceType,
           HCC.PartitionKey
    FROM etl.RiskScoreFactorsPartC HCC
        JOIN #EDSHCCCounter [C]
            ON [C].PaymentYear = [HCC].[PaymentYear]
               AND [C].MYUFlag = [HCC].MYUFlag
               AND [C].PartCRAFTProjected = [HCC].PartCRAFTProjected
               AND [C].SourceType = [HCC].[SourceType]
               AND [C].HICN = [HCC].[HICN]
        LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Models E
            ON E.Factor_Type = HCC.PartCRAFTProjected
               AND E.Payment_Year = HCC.ModelYear
               AND C.PCCLabel = E.Factor_Description
               AND E.Part_C_D_Flag = 'C'
               AND HCC.Aged = E.Aged --6/7
    WHERE HCC.DeleteFlag = 0
          AND HCC.SourceType = 'EDS';


SET @RowCount = Isnull(@@ROWCOUNT,0);


    /***********************************
EDS INERACTIONS - BUILDUP
***************************************/

    /***********************************
RAPS INERACTIONS - BUILDUP
***************************************/

    INSERT etl.RiskScoreFactorsPartC
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
    SELECT HCC.PaymentYear,
           HCC.MYUFlag,
           HCC.PlanIdentifier,
           HCC.HICN,
           HCC.AgeGrpID,
           HCC.Populated,
           [int].Interaction_Label,
           E.Factor AS Factor,
           [int].Interaction_Label AS HCC_Hierarchy,
           E.Factor AS FActor_hierarchy,
           [int].Interaction_Label AS HCC_Delete_Hierarchy,
           E.Factor AS FActor_delete_hierarchy,
           HCC.PartCRAFTProjected,
           HCC.PartCRAFTMMR,
           HCC.ModelYear,
           HCC.DeleteFlag,
           HCC.DateForFactors,
           HCC.HCCNumber,
           HCC.aged,
           'INT' AS SourceType,
           HCC.PartitionKey
    FROM etl.RiskScoreFactorsPartC HCC
        JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Interactions] [int]
            ON HCC.[ModelYear] = [int].[Payment_Year]
               AND HCC.PartCRAFTProjected = [int].[Factor_Type]
               AND HCC.HCCNumber = [int].[HCC_Number_1]
               AND (HCC.HCCHierarchy NOT LIKE 'HIER%')
        JOIN etl.RiskScoreFactorsPartC [hcc2]
            ON [hcc2].[ModelYear] = [int].[Payment_Year]
               AND [hcc2].PartCRAFTProjected = [int].[Factor_Type]
               AND [hcc2].HCCNumber = [int].[HCC_Number_2]
               AND [hcc2].[PaymentYear] = HCC.[PaymentYear]
               AND [hcc2].[HICN] = HCC.[HICN]
               AND ([hcc2].HCCHierarchy NOT LIKE 'HIER%')
        JOIN etl.RiskScoreFactorsPartC [hcc3]
            ON [hcc3].[ModelYear] = [int].[Payment_Year]
               AND [hcc3].PartCRAFTProjected = [int].[Factor_Type]
               AND [hcc3].HCCNumber = [int].[HCC_Number_3]
               AND [hcc3].[PaymentYear] = HCC.[PaymentYear]
               AND [hcc3].[HICN] = HCC.[HICN]
               AND ([hcc3].HCCHierarchy NOT LIKE 'HIER%')
        LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Models E
            ON E.Factor_Type = HCC.PartCRAFTProjected
               AND E.Payment_Year = hcc2.ModelYear
               AND [int].Interaction_Label = E.Factor_Description
               AND E.Part_C_D_Flag = 'C'
               AND HCC.Aged = E.Aged --6/7
        LEFT OUTER JOIN etl.RiskScoreFactorsPartC exclude
            ON HCC.HICN = exclude.HICN
               AND [int].Interaction_Label = exclude.HCCLabel
               AND HCC.PlanIdentifier = exclude.PlanIdentifier
               AND HCC.PaymentYear = exclude.PaymentYear
               AND HCC.ModelYear = exclude.ModelYear --6/7
    WHERE exclude.HICN IS NULL
          AND HCC.SourceType IN ( 'RAPS', 'RMOR' )
    GROUP BY HCC.PaymentYear,
             HCC.MYUFlag,
             HCC.PlanIdentifier,
             HCC.HICN,
             HCC.AgeGrpID,
             HCC.Populated,
             [int].Interaction_Label,
             E.Factor,
             HCC.PartCRAFTProjected,
             HCC.ModelYear,
             HCC.DeleteFlag,
             HCC.DateForFactors,
             HCC.HCCNumber,
             HCC.aged,
             HCC.SourceType,
             HCC.PartitionKey,
             HCC.partcRAFTMMR;



SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);


    /**********************************
EDS HIERARCHY WITH DELETES - INTO BUILDUP 
************************************/
    ----SELECT * FROM etl.RiskScoreFactorsPartC WHERE HCCLabel LIKE 'HIER%'
    IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHYEDS1]', 'U') IS NOT NULL
        DROP TABLE #HIERARCHYEDS1;
    CREATE TABLE #HIERARCHYEDS1
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY,
        HICN VARCHAR(15),
        RAFTRestated VARCHAR(2),
        HCC1 VARCHAR(20),
        HCCNumber INT
    );
    INSERT #HIERARCHYEDS1
    SELECT A.HICN,
           A.PartCRAFTProjected,
           C.HCC_DROP,
           A.HCCNumber
    FROM etl.RiskScoreFactorsPartC A
        INNER JOIN etl.RiskScoreFactorsPartC B
            ON B.HICN = A.HICN
               AND B.PaymentYear = A.PaymentYear
               AND A.DateForFactors = B.DateForFactors
               AND A.PlanIdentifier = B.PlanIdentifier
               AND A.ModelYear = B.ModelYear
               AND A.PartCRAFTProjected = B.PartCRAFTProjected --6/7
               AND A.SourceType = B.SourceType --6/13
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C
            ON B.HCCLabel = C.HCC_KEEP
               AND A.HCCLabel = C.HCC_DROP
               AND A.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND B.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND C.Payment_Year = A.ModelYear
               AND C.Part_C_D_Flag = 'C'
    WHERE A.SourceType IN ( 'EDS', 'EMOR' );

    IF OBJECT_ID('[tempdb].[dbo].[#HIERARCHYEDS2]', 'U') IS NOT NULL
        DROP TABLE #HIERARCHYEDS2;
    CREATE TABLE #HIERARCHYEDS2
    (
        ID INT IDENTITY(1, 1) PRIMARY KEY,
        HICN VARCHAR(15),
        RAFTRestated VARCHAR(2),
        HCC1 VARCHAR(20),
        HCCNumber INT
    );



    INSERT #HIERARCHYEDS2
    SELECT A.HICN,
           A.PartCRAFTProjected,
           C.HCC_DROP,
           A.HCCNumber
    FROM etl.RiskScoreFactorsPartC A
        INNER JOIN etl.RiskScoreFactorsPartC B
            ON B.HICN = A.HICN
               AND B.PaymentYear = A.PaymentYear
               AND A.DateForFactors = B.DateForFactors
               AND A.PlanIdentifier = B.PlanIdentifier
               AND A.ModelYear = B.ModelYear
               AND A.PartCRAFTProjected = B.PartCRAFTProjected --6/7
               AND A.SourceType = B.SourceType --6/13 
        INNER JOIN [$(HRPReporting)].dbo.lk_Risk_Models_Hierarchy C
            ON B.HCCLabel = C.HCC_KEEP
               AND A.HCCLabel = C.HCC_DROP
               AND A.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND B.PartCRAFTProjected = C.RA_FACTOR_TYPE
               AND C.Payment_Year = A.ModelYear
               AND C.Part_C_D_Flag = 'C'
               AND A.PartCRAFTProjected = C.RA_FACTOR_TYPE
    WHERE A.DeleteFlag = 0
          AND B.DeleteFlag = 0
          AND A.SourceType IN ( 'EDS', 'EMOR' );



    UPDATE A
    SET A.HCCHierarchy = 'HIER-' + HCCLabel,
        A.HCCDeleteHierarchy = 'HIER-' + HCCLabel,
        A.FactorHierarchy = 0,
        A.FactorDeleteHierarchy = 0
    FROM etl.RiskScoreFactorsPartC A
        JOIN #HIERARCHYEDS1 Hier
            ON Hier.HICN = A.HICN
               AND Hier.RAFTRestated = A.PartCRAFTProjected
               AND Hier.HCCNumber = A.HCCNumber
    WHERE A.SourceType IN ( 'EDS', 'EMOR' );




/***********************************
EDS INERACTIONS - BUILDUP
***************************************/

    INSERT etl.RiskScoreFactorsPartC
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
    SELECT HCC.PaymentYear,
           HCC.MYUFlag,
           HCC.PlanIdentifier,
           HCC.HICN,
           HCC.AgeGrpID,
           HCC.Populated,
           [int].Interaction_Label,
           E.Factor AS Factor,
           [int].Interaction_Label AS HCC_Hierarchy,
           E.Factor AS FActor_hierarchy,
           [int].Interaction_Label AS HCC_Delete_Hierarchy,
           E.Factor AS FActor_delete_hierarchy,
           HCC.PartCRAFTProjected,
           HCC.PartCRAFTMMR,
           HCC.ModelYear,
           HCC.DeleteFlag,
           HCC.DateForFactors,
           HCC.HCCNumber,
           HCC.aged,
           'EDS' AS SourceType,
           HCC.PartitionKey
    FROM etl.RiskScoreFactorsPartC HCC
        JOIN [$(HRPReporting)].[dbo].[lk_Risk_Models_Interactions] [int]
            ON HCC.[ModelYear] = [int].[Payment_Year]
               AND HCC.PartCRAFTProjected = [int].[Factor_Type]
               AND HCC.HCCNumber = [int].[HCC_Number_1]
               AND (HCC.HCCHierarchy NOT LIKE 'HIER%')
        JOIN etl.RiskScoreFactorsPartC [hcc2]
            ON [hcc2].[ModelYear] = [int].[Payment_Year]
               AND [hcc2].PartCRAFTProjected = [int].[Factor_Type]
               AND [hcc2].HCCNumber = [int].[HCC_Number_2]
               AND [hcc2].[PaymentYear] = HCC.[PaymentYear]
               AND [hcc2].[HICN] = HCC.[HICN]
               AND ([hcc2].HCCHierarchy NOT LIKE 'HIER%')
               AND HCC.SourceType = hcc2.SourceType --6/13
        JOIN etl.RiskScoreFactorsPartC [hcc3]
            ON [hcc3].[ModelYear] = [int].[Payment_Year]
               AND [hcc3].PartCRAFTProjected = [int].[Factor_Type]
               AND [hcc3].HCCNumber = [int].[HCC_Number_3]
               AND [hcc3].[PaymentYear] = HCC.[PaymentYear]
               AND [hcc3].[HICN] = HCC.[HICN]
               AND ([hcc3].HCCHierarchy NOT LIKE 'HIER%')
               AND HCC.SourceType = hcc3.SourceType --6/13
        LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Models E
            ON E.Factor_Type = HCC.PartCRAFTProjected
               AND E.Payment_Year = hcc2.ModelYear
               AND [int].Interaction_Label = E.Factor_Description
               AND E.Part_C_D_Flag = 'C'
               AND HCC.Aged = E.Aged --6/7
        LEFT OUTER JOIN etl.RiskScoreFactorsPartC exclude
            ON HCC.HICN = exclude.HICN
               AND [int].Interaction_Label = exclude.HCCLabel
               AND HCC.PlanIdentifier = exclude.PlanIdentifier
               AND HCC.PaymentYear = exclude.PaymentYear
               AND HCC.ModelYear = exclude.ModelYear --6/7
               AND HCC.SourceType = exclude.SourceType --6/13
    WHERE exclude.HICN IS NULL
          AND HCC.SourceType IN ( 'EDS', 'EMOR' )
    GROUP BY HCC.PaymentYear,
             HCC.MYUFlag,
             HCC.PlanIdentifier,
             HCC.HICN,
             HCC.AgeGrpID,
             HCC.Populated,
             [int].Interaction_Label,
             E.Factor,
             HCC.PartCRAFTProjected,
             HCC.ModelYear,
             HCC.DeleteFlag,
             HCC.DateForFactors,
             HCC.HCCNumber,
             HCC.aged,
             HCC.SourceType,
             HCC.PartitionKey,
             HCC.partcRAFTMMR;


SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);


    INSERT etl.RiskScoreFactorsPartC
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
    SELECT p.PaymentYear,
           p.MYUFlag,
           p.PlanIdentifier,
           p.HICN,
           p.AgeGrpID,
           p.Populated,
           p.HCCLabel,
           E.Factor AS Factor,
           E.Factor_Description AS HCC_Hierarchy,
           E.Factor AS FActor_hierarchy,
           E.Factor_Description AS HCC_Delete_Hierarchy,
           E.Factor AS FActor_delete_hierarchy,
           p.PartCRAFTProjected,
           p.PartCRAFTMMR,
           p.ModelYear,
           p.DeleteFlag,
           p.DateForFactors,
           p.HCCNumber,
           p.Aged,
           'RAPS' AS SourceType,
           p.PartitionKey
    FROM etl.RiskScoreFactorsPartC p
        LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Models E
            ON E.Factor_Type = p.PartCRAFTProjected
               AND E.Payment_Year = p.ModelYear
               AND p.HCCLabel = REPLACE(E.Factor_Description, 'D-', '')
               AND E.Part_C_D_Flag = 'C'
               AND p.Aged = E.Aged --6/7
    WHERE E.Factor_Description LIKE 'D-%'
          AND p.ModelYear = E.Payment_Year --6/26
          AND p.AgeGrpID < 6
          AND p.SourceType IN ( 'RAPS', 'RMOR' ); -- 65862

SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);

    INSERT etl.RiskScoreFactorsPartC
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
    SELECT p.PaymentYear,
           p.MYUFlag,
           p.PlanIdentifier,
           p.HICN,
           p.AgeGrpID,
           p.Populated,
           p.HCCLabel,
           E.Factor AS Factor,
           E.Factor_Description AS HCC_Hierarchy,
           E.Factor AS FActor_hierarchy,
           E.Factor_Description AS HCC_Delete_Hierarchy,
           E.Factor AS FActor_delete_hierarchy,
           p.PartCRAFTProjected,
           p.PartCRAFTMMR,
           p.ModelYear,
           p.DeleteFlag,
           p.DateForFactors,
           p.HCCNumber,
           p.Aged,
           'EDS' AS SourceType,
           p.PartitionKey
    FROM etl.RiskScoreFactorsPartC p
        LEFT JOIN [$(HRPReporting)].dbo.lk_Risk_Models E
            ON E.Factor_Type = p.PartCRAFTProjected
               AND E.Payment_Year = p.ModelYear
               AND p.HCCLabel = REPLACE(E.Factor_Description, 'D-', '')
               AND E.Part_C_D_Flag = 'C'
               AND p.Aged = E.Aged --6/7
    WHERE E.Factor_Description LIKE 'D-%'
          AND p.ModelYear = E.Payment_Year --6/26
          AND p.AgeGrpID < 6
          AND p.SourceType IN ( 'EDS', 'EMOR' );


SET @RowCount = @RowCount + Isnull(@@ROWCOUNT,0);


    UPDATE A
    SET Factor = '0.00'
    FROM etl.RiskScoreFactorsPartC A
        INNER JOIN etl.RiskScoreFactorsPartC B
            ON A.HICN = B.HICN
               AND A.PaymentYear = B.PaymentYear
               AND A.ModelYear = B.ModelYear
               AND A.PartCRAFTProjected = B.PartCRAFTProjected
               AND (
            (
                (A.HCCHierarchy = 'INT1')
                AND (B.HCCHierarchy = 'INT6')
                OR (A.HCCHierarchy = 'INT5')
                   AND (B.HCCHierarchy = 'INT6')
            )
                   );


END;