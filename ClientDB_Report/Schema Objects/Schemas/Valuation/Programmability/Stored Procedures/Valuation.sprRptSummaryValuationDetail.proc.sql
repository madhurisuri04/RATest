CREATE PROC [Valuation].[sprRptSummaryValuationDetail] (@ClientId INT
                                                      , @AutoProcessRunId INT)
--
/**************************************************************************************************** 
* Name			:	[Valuation].[sprRptSummaryValuationDetail]    									*
* Type 			:	Stored Procedure																*
* Author       	:	Mitch Casto																		*
* Date			:	2016-09-15																		*
* Version		:	1.0																				*
* Description	:	Used by DS_sprRptSummaryValuationDetail dataset in Valuation RDL				*
*																									*
* Version History :																					*
* =================																					*
* Author			Date			Version#    TFS Ticket#		Description							*
* -----------------	----------		--------    -----------		------------						*
* MCasto			2016-09-15  1.0				US54399			Initial								*
*																									*
*****************************************************************************************************/
AS
    SELECT DISTINCT [ClientId] = [rv].[ClientId]
                  , [AutoProcessRunId] = [rv].[AutoProcessRunId]
                  , [ReportHeader] = [rv].[ReportHeader]
                  , [DOSPaymentYearHeader] = [rv].[DOSPaymentYearHeader]
                  , [RowDisplay03] = [rv3].[RowDisplay]
                  , [ChartsCompleted03] = [rv3].[ChartsCompleted]
                  , [HCCTotal_PartC03] = [rv3].[HCCTotal_PartC]
                  , [EstRev_PartC03] = [rv3].[EstRev_PartC]
                  , [EstRevPerHCC_PartC03] = CAST([rv3].[EstRevPerHCC_PartC] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartC03] = CAST([rv3].[HCCRealizationRate_PartC] AS DECIMAL(12, 5))
                  , [HCCTotal_PartD03] = [rv3].[HCCTotal_PartD]
                  , [EstRev_PartD03] = [rv3].[EstRev_PartD]
                  , [EstRevPerHCC_PartD03] = CAST([rv3].[EstRevPerHCC_PartD] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartD03] = CAST([rv3].[HCCRealizationRate_PartD] AS DECIMAL(12, 5))
                  , [EstRevPerChartsCompleted03] = CAST([rv3].[EstRevPerChartsCompleted] AS DECIMAL(12, 5))
                  , [OrderFlag03] = [rv3].[OrderFlag]
                  , [RowDisplay02] = [rv2].[RowDisplay]
                  , [ChartsCompleted02] = [rv2].[ChartsCompleted]
                  , [HCCTotal_PartC02] = [rv2].[HCCTotal_PartC]
                  , [EstRev_PartC02] = [rv2].[EstRev_PartC]
                  , [EstRevPerHCC_PartC02] = CAST([rv2].[EstRevPerHCC_PartC] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartC02] = CAST([rv2].[HCCRealizationRate_PartC] AS DECIMAL(12, 5))
                  , [HCCTotal_PartD02] = [rv2].[HCCTotal_PartD]
                  , [EstRev_PartD02] = [rv2].[EstRev_PartD]
                  , [EstRevPerHCC_PartD02] = CAST([rv2].[EstRevPerHCC_PartD] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartD02] = CAST([rv2].[HCCRealizationRate_PartD] AS DECIMAL(12, 5))
                  , [EstRevPerChartsCompleted02] = CAST([rv2].[EstRevPerChartsCompleted] AS DECIMAL(12, 5))
                  , [OrderFlag02] = [rv2].[OrderFlag]
                  , [RowDisplay01] = [rv1].[RowDisplay]
                  , [ChartsCompleted01] = [rv1].[ChartsCompleted]
                  , [HCCTotal_PartC01] = [rv1].[HCCTotal_PartC]
                  , [EstRev_PartC01] = [rv1].[EstRev_PartC]
                  , [EstRevPerHCC_PartC01] = CAST([rv1].[EstRevPerHCC_PartC] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartC01] = CAST([rv1].[HCCRealizationRate_PartC] AS DECIMAL(12, 5))
                  , [HCCTotal_PartD01] = [rv1].[HCCTotal_PartD]
                  , [EstRev_PartD01] = [rv1].[EstRev_PartD]
                  , [EstRevPerHCC_PartD01] = CAST([rv1].[EstRevPerHCC_PartD] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartD01] = CAST([rv1].[HCCRealizationRate_PartD] AS DECIMAL(12, 5))
                  , [EstRevPerChartsCompleted01] = CAST([rv1].[EstRevPerChartsCompleted] AS DECIMAL(12, 5))
                  , [OrderFlag01] = [rv1].[OrderFlag]
                  , [RowDisplay00] = [rv0].[RowDisplay]
                  , [ChartsCompleted00] = [rv0].[ChartsCompleted]
                  , [HCCTotal_PartC00] = [rv0].[HCCTotal_PartC]
                  , [EstRev_PartC00] = [rv0].[EstRev_PartC]
                  , [EstRevPerHCC_PartC00] = CAST([rv0].[EstRevPerHCC_PartC] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartC00] = CAST([rv0].[HCCRealizationRate_PartC] AS DECIMAL(12, 5))
                  , [HCCTotal_PartD00] = [rv0].[HCCTotal_PartD]
                  , [EstRev_PartD00] = [rv0].[EstRev_PartD]
                  , [EstRevPerHCC_PartD00] = CAST([rv0].[EstRevPerHCC_PartD] AS DECIMAL(12, 5))
                  , [HCCRealizationRate_PartD00] = CAST([rv0].[HCCRealizationRate_PartD] AS DECIMAL(12, 5))
                  , [EstRevPerChartsCompleted00] = CAST([rv0].[EstRevPerChartsCompleted] AS DECIMAL(12, 5))
                  , [OrderFlag00] = [rv0].[OrderFlag]
                  , [ProjectId] = [rv].[ProjectId]
                  , [ProjectDescription] = [rv].[ProjectDescription]
                  , [SubProjectId] = [rv].[SubProjectId]
                  , [SubProjectDescription] = [rv].[SubProjectDescription]
                  , [ProjectSortOrder] = [rv].[ProjectSortOrder]
                  , [SubProjectSortOrder] = [rv].[SubProjectSortOrder]
      FROM          [Valuation].[RptRetrospectiveValuationDetail] AS [rv] WITH (NOLOCK)
      LEFT JOIN     [Valuation].[RptRetrospectiveValuationDetail] AS [rv3] WITH (NOLOCK)
        ON [rv].[AutoProcessRunId]                                                                                    = [rv3].[AutoProcessRunId]
       AND [rv].[ClientId]                                                                                            = [rv3].[ClientId]
       AND [rv].[ProjectId]                                                                                           = [rv3].[ProjectId]
       AND [rv].[SubProjectId]                                                                                        = [rv3].[SubProjectId]
       AND [rv].[ReviewName]                                                                                          = [rv3].[ReviewName]
       AND [rv3].[OrderFlag]                                                                                          = 3
       AND ISNULL([rv3].[ChartsCompleted], 1) + ISNULL([rv3].[HCCTotal_PartC], 0) + ISNULL([rv3].[HCCTotal_PartD], 0) > 0
       AND [rv3].[RowDisplay] IS NOT NULL
       AND [rv3].[ReportType]                                                                                         = 'RetrospectiveValuationDetail'
      LEFT JOIN     [Valuation].[RptRetrospectiveValuationDetail] AS [rv2] WITH (NOLOCK)
        ON [rv].[AutoProcessRunId]                                                                                    = [rv2].[AutoProcessRunId]
       AND [rv].[ClientId]                                                                                            = [rv2].[ClientId]
       AND [rv].[ProjectId]                                                                                           = [rv2].[ProjectId]
       AND [rv].[SubProjectId]                                                                                        = [rv2].[SubProjectId]
       AND [rv2].[OrderFlag]                                                                                          = 2
       AND ISNULL([rv2].[ChartsCompleted], 1) + ISNULL([rv2].[HCCTotal_PartC], 1) + ISNULL([rv2].[HCCTotal_PartD], 1) > 0
       AND [rv2].[RowDisplay] IS NOT NULL
       AND [rv2].[ReportType]                                                                                         = 'RetrospectiveValuationDetail'
      LEFT JOIN     [Valuation].[RptRetrospectiveValuationDetail] AS [rv1] WITH (NOLOCK)
        ON [rv].[AutoProcessRunId]                                                                                    = [rv1].[AutoProcessRunId]
       AND [rv].[ClientId]                                                                                            = [rv1].[ClientId]
       AND [rv].[ProjectId]                                                                                           = [rv1].[ProjectId]
       AND [rv1].[OrderFlag]                                                                                          = 1
       AND ISNULL([rv1].[ChartsCompleted], 1) + ISNULL([rv1].[HCCTotal_PartC], 1) + ISNULL([rv1].[HCCTotal_PartD], 1) > 0
       AND [rv1].[RowDisplay] IS NOT NULL
       AND [rv1].[ReportType]                                                                                         = 'RetrospectiveValuationDetail'
      LEFT JOIN     [Valuation].[RptRetrospectiveValuationDetail] AS [rv0] WITH (NOLOCK)
        ON [rv].[AutoProcessRunId]                                                                                    = [rv0].[AutoProcessRunId]
       AND [rv].[ClientId]                                                                                            = [rv0].[ClientId]
       AND [rv0].[OrderFlag]                                                                                          = 0
       AND ISNULL([rv0].[ChartsCompleted], 1) + ISNULL([rv0].[HCCTotal_PartC], 1) + ISNULL([rv0].[HCCTotal_PartD], 1) > 0
       AND [rv0].[RowDisplay] IS NOT NULL
       AND [rv0].[ReportType]                                                                                         = 'RetrospectiveValuationDetail'
     WHERE          ([rv].[AutoProcessRunId] = @AutoProcessRunId)
       AND          ([rv].[ClientId]         = @ClientId)
       AND          ([rv].[ProjectId] IS NOT NULL)
       AND          ([rv].[SubProjectId] IS NOT NULL)
       AND          ([rv].[ReportType]       = 'RetrospectiveValuationDetail')
       AND          [rv2].[RowDisplay] IS NOT NULL