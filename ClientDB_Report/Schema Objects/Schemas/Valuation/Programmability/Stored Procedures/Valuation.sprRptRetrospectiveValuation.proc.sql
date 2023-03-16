CREATE PROC [Valuation].[sprRptRetrospectiveValuation] (@ClientId INT
                                                      , @AutoProcessRunId INT)
--
/**************************************************************************************************** 
* Name			:	[Valuation].[sprRptRetrospectiveValuation]    									*
* Type 			:	Stored Procedure																*
* Author       	:	Mitch Casto																		*
* Date			:	2016-09-15																		*
* Version		:	1.0																				*
* Description	:	Used by DS_sprRptRetrospectiveValuation dataset in Valuation RDL				*
*																									*
* Version History :																					*
* =================																					*
* Author			Date			Version#    TFS Ticket#		Description							*
* -----------------	----------		--------    -----------		------------						*
* MCasto			2016-09-15  1.0				US54399			Initial								*
*																									*
*****************************************************************************************************/
AS
    SELECT [ClientId] = [rv2].[ClientId]
         , [AutoProcessRunId] = [rv2].[AutoProcessRunId]
         , [ReportHeader] = [rv2].[ReportHeader]
         , [RowDisplay02] = [rv2].[RowDisplay]
         , [TotalChartsRequested02] = [rv2].[TotalChartsRequested]
         , [TotalChartsRetrieved02] = [rv2].[TotalChartsRetrieved]
         , [TotalChartsNotRetrieved02] = [rv2].[TotalChartsNotRetrieved]
         , [TotalChartsAdded02] = [rv2].[TotalChartsAdded]
         , [TotalCharts1stPassCoded02] = [rv2].[TotalCharts1stPassCoded]
         , [TotalChartsCompleted02] = [rv2].[TotalChartsCompleted]
         , [ProjectCompletion02] = CAST([rv2].[ProjectCompletion] AS DECIMAL(12, 5))
         , [ProjectId] = [rv2].[ProjectId]
         , [ProjectDescription] = [rv2].[ProjectDescription]
         , [SubProjectId] = [rv2].[SubProjectId]
         , [SubProjectDescription] = [rv2].[SubProjectDescription]
         , [ProjectSortOrder] = [rv2].[ProjectSortOrder]
         , [SubProjectSortOrder] = [rv2].[SubProjectSortOrder]
         , [OrderFlag02] = [rv2].[OrderFlag]
         , [RowDisplay01] = [rv1].[RowDisplay]
         , [TotalChartsRequested01] = [rv1].[TotalChartsRequested]
         , [TotalChartsRetrieved01] = [rv1].[TotalChartsRetrieved]
         , [TotalChartsNotRetrieved01] = [rv1].[TotalChartsNotRetrieved]
         , [TotalChartsAdded01] = [rv1].[TotalChartsAdded]
         , [TotalCharts1stPassCoded01] = [rv1].[TotalCharts1stPassCoded]
         , [TotalChartsCompleted01] = [rv1].[TotalChartsCompleted]
         , [ProjectCompletion01] = CAST([rv1].[ProjectCompletion] AS DECIMAL(12, 5))
         , [OrderFlag01] = [rv1].[OrderFlag]
         , [RowDisplay00] = [rv0].[RowDisplay]
         , [TotalChartsRequested00] = [rv0].[TotalChartsRequested]
         , [TotalChartsRetrieved00] = [rv0].[TotalChartsRetrieved]
         , [TotalChartsNotRetrieved00] = [rv0].[TotalChartsNotRetrieved]
         , [TotalChartsAdded00] = [rv0].[TotalChartsAdded]
         , [TotalCharts1stPassCoded00] = [rv0].[TotalCharts1stPassCoded]
         , [TotalChartsCompleted00] = [rv0].[TotalChartsCompleted]
         , [ProjectCompletion00] = CAST([rv0].[ProjectCompletion] AS DECIMAL(12, 5))
         , [OrderFlag00] = [rv0].[OrderFlag]
      FROM [Valuation].[RptRetrospectiveValuation] AS [rv2] WITH (NOLOCK)
      LEFT JOIN [Valuation].[RptRetrospectiveValuation] AS [rv1] WITH (NOLOCK)
        ON [rv2].[ClientId]         = [rv1].[ClientId]
       AND [rv2].[AutoProcessRunId] = [rv1].[AutoProcessRunId]
       AND [rv2].[ProjectId]        = [rv1].[ProjectId]
       AND [rv1].[OrderFlag]        = 1
      LEFT JOIN [Valuation].[RptRetrospectiveValuation] AS [rv0] WITH (NOLOCK)
        ON [rv2].[ClientId]         = [rv0].[ClientId]
       AND [rv2].[AutoProcessRunId] = [rv0].[AutoProcessRunId]
       AND [rv0].[OrderFlag]        = 0
     WHERE ([rv2].[AutoProcessRunId]                                                                    = @AutoProcessRunId)
       AND ([rv2].[ClientId]                                                                            = @ClientId)
       AND ([rv2].[OrderFlag]                                                                           = 2)
       AND ([rv2].[TotalChartsRequested] + [rv2].[TotalChartsRetrieved] + [rv2].[TotalChartsNotRetrieved]
            + [rv2].[TotalChartsAdded] + [rv2].[TotalCharts1stPassCoded] + [rv2].[TotalChartsCompleted] > 0)
        OR ([rv2].[AutoProcessRunId]                                                                    = @AutoProcessRunId)
       AND ([rv2].[ClientId]                                                                            = @ClientId)
       AND ([rv2].[OrderFlag]                                                                           = 2)
       AND ([rv1].[TotalChartsRequested] + [rv1].[TotalChartsRetrieved] + [rv1].[TotalChartsNotRetrieved]
            + [rv1].[TotalChartsAdded] + [rv1].[TotalCharts1stPassCoded] + [rv1].[TotalChartsCompleted] > 0)
        OR ([rv2].[AutoProcessRunId]                                                                    = @AutoProcessRunId)
       AND ([rv2].[ClientId]                                                                            = @ClientId)
       AND ([rv2].[OrderFlag]                                                                           = 2)
       AND ([rv0].[TotalChartsRequested] + [rv0].[TotalChartsRetrieved] + [rv0].[TotalChartsNotRetrieved]
            + [rv0].[TotalChartsAdded] + [rv0].[TotalCharts1stPassCoded] + [rv0].[TotalChartsCompleted] > 0)