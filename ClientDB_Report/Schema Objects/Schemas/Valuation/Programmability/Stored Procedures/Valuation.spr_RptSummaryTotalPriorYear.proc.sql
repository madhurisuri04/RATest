CREATE PROCEDURE [Valuation].[spr_RptSummaryTotalPriorYear]

(   @ClientId INT
  , @AutoProcessRunId INT
  , @IsSummary BIT = 0)

AS
--
/**************************************************************************************************** 
* Name			:	Valuation.spr_RptSummaryTotalPriorYear											*
* Type 			:	Stored Procedure																*
* Author       	:	David Waddell																	*
* Date			:	2016-03-23																		*
* Version			:																				*
* Description		: used for the 'Year To Year Summary' tab										*
*																									*
* Version History :																					*
* =================================================================================================	*
* Author			Date		Version#    TFS Ticket#	Description									*
* -----------------	----------  --------    -----------	------------								*
* David Waddell		2016-03-23	1.0			51835		Initial										*
*																									*
*****************************************************************************************************/

    SET NOCOUNT ON

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
         , [GroupingOrder] = [rst].[GroupingOrder]
      FROM
        --        [$(ClientDB_Report)].[Valuation].[RptSummaryTotal] rst WITH (NOLOCK)
           [Valuation].[RptSummaryTotal] [rst] WITH (NOLOCK)

     WHERE [rst].[ClientId]         = @ClientId
       AND [rst].[AutoProcessRunId] = @AutoProcessRunId
       AND [rst].[IsSummary]        = 1 -- @IsSummary
