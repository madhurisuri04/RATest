CREATE PROC [Valuation].[sprRptSummaryTotalRecommendedBy] (@ClientId INT
                                                         , @AutoProcessRunId INT)

/**************************************************************************************************** 
* Name			:	[Valuation].[sprRptSummaryTotalRecommendedBy]    								*
* Type 			:	Stored Procedure																*
* Author       	:	Mitch Casto																		*
* Date			:	2016-09-15																		*
* Version		:	1.0																				*
* Description	:	Used by DS_sprRptSummaryTotalRecommendedBy dataset in Valuation RDL				*
*																									*
* Version History :																					*
* =================																					*
* Author			Date			Version#    TFS Ticket#		Description							*
* -----------------	----------		--------    -----------		------------						*
* MCasto			2016-09-15  1.0				US54399			Initial								*
*																									*
*****************************************************************************************************/
AS
    SELECT [ClientId] = [rst].[ClientId]
         , [AutoProcessRunId] = [rst].[AutoProcessRunId]
         , [ReportHeader] = [rst].[ReportHeader]
         , [RowDisplay] = [rst].[RowDisplay]
         , [CodingThrough] = [rst].[CodingThrough]
         , [ValuationDelivered] = [rst].[ValuationDelivered]
         , [ProjectCompletion] = [rst].[ProjectCompletion]
         , [ChartsCompleted] = [rst].[ChartsCompleted]
         , [HCCTotal_PartC] = [rst].[HCCTotal_PartC]
         , [EstRev_PartC] = [rst].[EstRev_PartC]
         , [HCCRealizationRate_PartC] = [rst].[HCCRealizationRate_PartC]
         , [EstRevPerChart_PartC] = [rst].[EstRevPerChart_PartC]
         , [EstRevPerHCC_PartC] = [rst].[EstRevPerHCC_PartC]
         , [HCCTotal_PartD] = [rst].[HCCTotal_PartD]
         , [EstRev_PartD] = [rst].[EstRev_PartD]
         , [HCCRealizationRate_PartD] = [rst].[HCCRealizationRate_PartD]
         , [EstRevPerChart_PartD] = [rst].[EstRevPerChart_PartD]
         , [EstRevPerHCC_PartD] = [rst].[EstRevPerHCC_PartD]
         , [TotalEstRev] = [rst].[TotalEstRev]
         , [TotalEstRevPerChart] = [rst].[TotalEstRevPerChart]
         , [Notes] = [rst].[Notes]
         , [SummaryYear] = [rst].[SummaryYear]
         , [IsSummary] = [rst].[IsSummary]
         , [Grouping] = [rst].[Grouping]
         , [GroupOrder] = [rst].[GroupingOrder]
      FROM [Valuation].[RptSummaryTotal] [rst] WITH (NOLOCK)
     WHERE [rst].[ClientId]         = @ClientId
       AND [rst].[AutoProcessRunId] = @AutoProcessRunId
       AND [rst].[ReportHeader]     = 'Current Week Totals By Rec Chart'