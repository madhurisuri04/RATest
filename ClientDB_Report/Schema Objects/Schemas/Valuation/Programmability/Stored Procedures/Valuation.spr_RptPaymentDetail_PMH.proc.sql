CREATE PROCEDURE [Valuation].[spr_RptPaymentDetail_PMH]
	(
     @ClientId INT
   , @AutoProcessRunId INT
   , @ReportType VARCHAR(128)
   , @ReportSubType VARCHAR(128)
    )




AS 
--Note: used for the 'Blended Payment Detail' & ??? tabs

/**************************************************************************************************** 
* Name			:	Valuation.spr_RptPaymentDetail_PMH												*
* Type 			:	Stored Procedure																*
* Author       	:	David Waddell																	*
* Date			:	2016-03-23																		*
* Version			:																				*
* Description		: used for the 'Blended Payment Detail' & ??? tabs								*
*																									*
* Version History :																					*
* =================================================================================================	*
* Author			Date		Version#    TFS Ticket#	Description									*
* -----------------	----------  --------    -----------	------------								*
* David Waddell		2016-03-21	1.0			51835		Initial										*
*																									*
*****************************************************************************************************/ 
   
    SET NOCOUNT ON 
           
    SELECT DISTINCT
        [ReportType] = [pd].[ReportType]
      , [ReportSubType] = [pd].[ReportSubType]
      , [ClientId] = [pd].[ClientId]
      , [AutoProcessRunId] = [pd].[AutoProcessRunId]
      , [ReportHeader] = [pd].[ReportHeader]
      , [Header_A] = [pd].[Header_A]
      , [Header_B] = [pd].[Header_B]
      , [Header_ESRD] = [pd].[Header_ESRD]
      
      , [RowDisplay03] = [pd3].[RowDisplay]--ISNULL([pd3].[RowDisplay], '03')
      
      , [ChartsCompleted03] = ISNULL([pd3].[ChartsCompleted], 0)
      , [HCCTotal_A03] = ISNULL([pd3].[HCCTotal_A], 0)
      , [EstRev_A03] = ISNULL([pd3].[EstRev_A], 0)
      , [EstRevPerHCC_A03] = ISNULL([pd3].[EstRevPerHCC_A], 0)
      , [HCCRealizationRate_A03] = ISNULL([pd3].[HCCRealizationRate_A], 0)
      , [HCCTotal_B03] = ISNULL([pd3].[HCCTotal_B], 0)
      , [EstRev_B03] = ISNULL([pd3].[EstRev_B], 0)
      , [EstRevPerHCC_B03] = ISNULL([pd3].[EstRevPerHCC_B], 0)
      , [HCCRealizationRate_B03] = ISNULL([pd3].[HCCRealizationRate_B], 0)
      , [HCCTotal_ESRD03] = ISNULL([pd3].[HCCTotal_ESRD], 0)
      , [EstRev_ESRD03] = ISNULL([pd3].[EstRev_ESRD], 0)
      , [EstRevPerHCC_ESRD03] = ISNULL([pd3].[EstRevPerHCC_ESRD], 0)
      , [HCCRealizationRate_ESRD03] = ISNULL([pd3].[HCCRealizationRate_ESRD], 0)
      , [OrderFlag03] = [pd3].[OrderFlag]
      
      , [RowDisplay02] = [pd2].[RowDisplay]
      
      , [ChartsCompleted02] = ISNULL([pd2].[ChartsCompleted], 0)
      , [HCCTotal_A02] = ISNULL([pd2].[HCCTotal_A], 0)
      , [EstRev_A02] = ISNULL([pd2].[EstRev_A], 0)
      , [EstRevPerHCC_A02] = ISNULL([pd2].[EstRevPerHCC_A], 0)
      , [HCCRealizationRate_A02] = ISNULL([pd2].[HCCRealizationRate_A], 0)
      , [HCCTotal_B02] = ISNULL([pd2].[HCCTotal_B], 0)
      , [EstRev_B02] = ISNULL([pd2].[EstRev_B], 0)
      , [EstRevPerHCC_B02] = ISNULL([pd2].[EstRevPerHCC_B], 0)
      , [HCCRealizationRate_B02] = ISNULL([pd2].[HCCRealizationRate_B], 0)
      , [HCCTotal_ESRD02] = ISNULL([pd2].[HCCTotal_ESRD], 0)
      , [EstRev_ESRD02] = ISNULL([pd2].[EstRev_ESRD], 0)
      , [EstRevPerHCC_ESRD02] = ISNULL([pd2].[EstRevPerHCC_ESRD], 0)
      , [HCCRealizationRate_ESRD02] = ISNULL([pd2].[HCCRealizationRate_ESRD], 0)
      , [OrderFlag02] = [pd2].[OrderFlag]
      , [RowDisplay01] = [pd1].[RowDisplay]
      , [ChartsCompleted01] = ISNULL([pd1].[ChartsCompleted], 0)
      , [HCCTotal_A01] = ISNULL([pd1].[HCCTotal_A], 0)
      , [EstRev_A01] = ISNULL([pd1].[EstRev_A], 0)
      , [EstRevPerHCC_A01] = ISNULL([pd1].[EstRevPerHCC_A], 0)
      , [HCCRealizationRate_A01] = ISNULL([pd1].[HCCRealizationRate_A], 0)
      , [HCCTotal_B01] = ISNULL([pd1].[HCCTotal_B], 0)
      , [EstRev_B01] = ISNULL([pd1].[EstRev_B], 0)
      , [EstRevPerHCC_B01] = ISNULL([pd1].[EstRevPerHCC_B], 0)
      , [HCCRealizationRate_B01] = ISNULL([pd1].[HCCRealizationRate_B], 0)
      , [HCCTotal_ESRD01] = ISNULL([pd1].[HCCTotal_ESRD], 0)
      , [EstRev_ESRD01] = ISNULL([pd1].[EstRev_ESRD], 0)
      , [EstRevPerHCC_ESRD01] = ISNULL([pd1].[EstRevPerHCC_ESRD], 0)
      , [HCCRealizationRate_ESRD01] = ISNULL([pd1].[HCCRealizationRate_ESRD], 0)
      , [OrderFlag01] = [pd1].[OrderFlag]
      , [RowDisplay00] = [pd0].[RowDisplay]
      , [ChartsCompleted00] = ISNULL([pd0].[ChartsCompleted], 0)
      , [HCCTotal_A00] = ISNULL([pd0].[HCCTotal_A], 0)
      , [EstRev_A00] = ISNULL([pd0].[EstRev_A], 0)
      , [EstRevPerHCC_A00] = ISNULL([pd0].[EstRevPerHCC_A], 0)
      , [HCCRealizationRate_A00] = ISNULL([pd0].[HCCRealizationRate_A], 0)
      , [HCCTotal_B00] = ISNULL([pd0].[HCCTotal_B], 0)
      , [EstRev_B00] = ISNULL([pd0].[EstRev_B], 0)
      , [EstRevPerHCC_B00] = ISNULL([pd0].[EstRevPerHCC_B], 0)
      , [HCCRealizationRate_B00] = ISNULL([pd0].[HCCRealizationRate_B], 0)
      , [HCCTotal_ESRD00] = ISNULL([pd0].[HCCTotal_ESRD], 0)
      , [EstRev_ESRD00] = ISNULL([pd0].[EstRev_ESRD], 0)
      , [EstRevPerHCC_ESRD00] = ISNULL([pd0].[EstRevPerHCC_ESRD], 0)
      , [HCCRealizationRate_ESRD00] = ISNULL([pd0].[HCCRealizationRate_ESRD], 0)
      , [OrderFlag00] = [pd0].[OrderFlag]
      , [ProjectId] = [pd].[ProjectId]
      , [ProjectDescription] = [pd].[ProjectDescription]
      , [SubProjectId] = [pd].[SubProjectId]
      , [SubProjectDescription] = [pd].[SubProjectDescription]
      , [ReviewName] = [pd].[ReviewName]
      , [ProjectSortOrder] = [pd].[ProjectSortOrder]
      , [SubProjectSortOrder] = [pd].[SubProjectSortOrder]
    FROM
--        [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd WITH (NOLOCK)
        [Valuation].[RptPaymentDetail] pd WITH (NOLOCK)
        
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd3 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd3 WITH (NOLOCK)

        ON [pd].[AutoProcessRunId] = [pd3].[AutoProcessRunId]
           AND [pd].[ClientId] = [pd3].[ClientId]
           AND [pd].[ProjectId] = [pd3].[ProjectId]
           AND [pd].[SubProjectId] = [pd3].[SubProjectId]
           AND [pd].[ReviewName] = [pd3].[ReviewName]
           AND [pd3].[OrderFlag] = 3
           AND (ISNULL([pd3].[ChartsCompleted], 1) + ISNULL([pd3].[HCCTotal_A], 0) + ISNULL([pd3].[HCCTotal_B], 0) + ISNULL([pd3].[HCCTotal_ESRD], 0)) > 0
           AND [pd3].[RowDisplay] IS NOT NULL
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd2 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd2 WITH (NOLOCK)
    
        ON [pd].[AutoProcessRunId] = [pd2].[AutoProcessRunId]
           AND [pd].[ClientId] = [pd2].[ClientId]
           AND [pd].[ProjectId] = [pd2].[ProjectId]
           AND [pd].[SubProjectId] = [pd2].[SubProjectId]
           AND [pd2].[ReportType] = @ReportType
           AND [pd2].[ReportSubType] = @ReportSubType
           AND [pd2].[OrderFlag] = 2
      --     AND (ISNULL([pd2].[ChartsCompleted], 1) + ISNULL([pd2].[HCCTotal_A], 1) + ISNULL([pd2].[HCCTotal_B], 1) + ISNULL([pd2].[HCCTotal_ESRD], 1)) > 0
           AND (ISNULL([pd2].[ChartsCompleted], 1) + ISNULL([pd2].[HCCTotal_A], 0) + ISNULL([pd2].[HCCTotal_B], 0) + ISNULL([pd2].[HCCTotal_ESRD], 0)) > 0

           AND [pd2].[RowDisplay] IS NOT NULL
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd1 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd1 WITH (NOLOCK)

        ON [pd].[AutoProcessRunId] = [pd1].[AutoProcessRunId]
           AND [pd].[ClientId] = [pd1].[ClientId]
           AND [pd].[ProjectId] = [pd1].[ProjectId]
           AND [pd1].[ReportType] = @ReportType
           AND [pd1].[ReportSubType] = @ReportSubType
           AND [pd1].[OrderFlag] = 1
           AND (ISNULL([pd1].[ChartsCompleted], 1) + ISNULL([pd1].[HCCTotal_A], 0) + ISNULL([pd1].[HCCTotal_B], 0) + ISNULL([pd1].[HCCTotal_ESRD], 0)) > 0
           AND [pd1].[RowDisplay] IS NOT NULL
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd0 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd0 WITH (NOLOCK)
    
        ON [pd].[AutoProcessRunId] = [pd0].[AutoProcessRunId]
           AND [pd].[ClientId] = [pd0].[ClientId]
           AND [pd0].[ReportType] = @ReportType
           AND [pd0].[ReportSubType] = @ReportSubType
           AND [pd0].[OrderFlag] = 0
           AND (ISNULL([pd0].[ChartsCompleted], 1) + ISNULL([pd0].[HCCTotal_A], 0) + ISNULL([pd0].[HCCTotal_B], 0) + ISNULL([pd0].[HCCTotal_ESRD], 0)) > 0
           AND [pd0].[RowDisplay] IS NOT NULL
    WHERE
        [pd].[AutoProcessRunId] = @AutoProcessRunId
        AND [pd].[ClientId] = @ClientId
        AND [pd].[ReportType] = @ReportType
        AND [pd].[ReportSubType] = @ReportSubType
        AND [pd].[ProjectId] IS NOT NULL
        AND [pd].[SubProjectId] IS NOT NULL 

  
RETURN 0