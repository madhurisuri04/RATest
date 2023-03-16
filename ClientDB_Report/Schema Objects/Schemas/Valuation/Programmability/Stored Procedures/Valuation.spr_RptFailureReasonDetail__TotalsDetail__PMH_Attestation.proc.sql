CREATE PROCEDURE [Valuation].[spr_RptFailureReasonDetail__TotalsDetail__PMH_Attestation]
	(
     @ClientId INT
   , @AutoProcessRunId INT
   , @ReportType VARCHAR(128)
   , @ReportSubType VARCHAR(128)
    )

	
AS    
    SET NOCOUNT ON 
           
    SELECT DISTINCT 
        [ReportType] = [pd3].[ReportType]
      , [ReportSubType] = [pd3].[ReportSubType]
      , [ClientId] = [pd3].[ClientId]
      , [AutoProcessRunId] = [pd3].[AutoProcessRunId]
      , [ReportHeader] = [pd3].[ReportHeader]
      , [Header_A] = [pd3].[Header_A]
      , [Header_B] = [pd3].[Header_B]
      , [Header_ESRD] = [pd3].[Header_ESRD]
      , [RowDisplay03] = [pd3].[RowDisplay]
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
      , [ProjectId] = [pd3].[ProjectId]
      , [ProjectDescription] = [pd3].[ProjectDescription]
      , [SubProjectId] = [pd3].[SubProjectId]
      , [SubProjectDescription] = [pd3].[SubProjectDescription]
      , [ReviewName] = [pd3].[ReviewName]
      , [ProjectSortOrder] = [pd3].[ProjectSortOrder]
      , [SubProjectSortOrder] = [pd3].[SubProjectSortOrder]
    FROM
--        [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd3 WITH (NOLOCK)
        [Valuation].[RptPaymentDetail] pd3 WITH (NOLOCK)
        
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd2 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd2 WITH (NOLOCK)
        
        ON [pd3].[AutoProcessRunId] = [pd2].[AutoProcessRunId]
           AND [pd3].[ClientId] = [pd2].[ClientId]
           AND [pd3].[ProjectId] = [pd2].[ProjectId]
           AND [pd3].[SubProjectId] = [pd2].[SubProjectId]
           AND [pd2].[ReportType] = @ReportType
           AND [pd2].[ReportSubType] = @ReportSubType
           AND [pd2].[OrderFlag] = 2
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd1 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd1 WITH (NOLOCK)

        ON [pd3].[AutoProcessRunId] = [pd1].[AutoProcessRunId]
           AND [pd3].[ClientId] = [pd1].[ClientId]
           AND [pd3].[ProjectId] = [pd1].[ProjectId]
           AND [pd1].[OrderFlag] = 1
           AND [pd1].[ReportType] = @ReportType
           AND [pd1].[ReportSubType] = @ReportSubType
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptPaymentDetail] pd0 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptPaymentDetail] pd0 WITH (NOLOCK)

        ON [pd3].[AutoProcessRunId] = [pd0].[AutoProcessRunId]
           AND [pd3].[ClientId] = [pd0].[ClientId]
           AND [pd0].[OrderFlag] = 0
           AND [pd0].[ReportType] = @ReportType
           AND [pd0].[ReportSubType] = @ReportSubType
    WHERE
        [pd3].[AutoProcessRunId] = @AutoProcessRunId
        AND [pd3].[ClientId] = @ClientId
        AND [pd3].[ReportType] = @ReportType
        AND [pd3].[ReportSubType] = @ReportSubType
        AND [pd3].[OrderFlag] = 3
        AND (
             (ISNULL([pd3].[ChartsCompleted], 0) + ISNULL([pd3].[HCCTotal_A], 0) + ISNULL([pd3].[HCCTotal_B], 0) + ISNULL([pd3].[HCCTotal_ESRD], 0)) > 0
             AND (ISNULL([pd2].[HCCTotal_A], 0) + ISNULL([pd2].[HCCTotal_B], 0) + ISNULL([pd2].[HCCTotal_ESRD], 0)) > 0
            )




RETURN 0