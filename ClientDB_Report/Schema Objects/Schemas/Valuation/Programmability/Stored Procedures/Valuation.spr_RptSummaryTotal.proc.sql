CREATE PROCEDURE [Valuation].[spr_RptSummaryTotal] (@ClientId INT
                                                  , @AutoProcessRunId INT
                                                  , @IsSummary BIT = 0)
AS /************************************************************************************ 
* Name			:	Valuation.spr_RptSummaryTotal									*
* Type 			:	Stored Procedure												*
* Author       	:	D. Waddell													    *
* Date			:	2016-03-23												     	*
* Version		:	1.0																*
* Description	:	used for the 'Year To Year Summary' tab				 		    *
*																					*
*																					*
* Version History	:																*
* ===================																*
* Author			Date		  Version#    TFS Ticket#	Description				*
* -----------------	----------  --------    -----------	------------				*
* DWaddell			2016-03-23  1.0			51835			Initial					*
* MCasto			2016-09-14	1.1			US54399			Added where clause		*
*															[ReportHeader]     =	*
*															'Summary Year To Date'	*
*																					*
************************************************************************************/
    SET NOCOUNT ON

    SELECT [ClientId] = [rst].[ClientId]
         , [AutoProcessRunId] = [rst].[AutoProcessRunId]
         , [InitialAutoProcessRunId] = [rst].[InitialAutoProcessRunId]
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
      FROM
        --        [$(ClientDB_Report)].[Valuation].[RptSummaryTotal] rst WITH (NOLOCK)
           [Valuation].[RptSummaryTotal] [rst] WITH (NOLOCK)
     WHERE [rst].[ClientId]         = @ClientId
       AND [rst].[AutoProcessRunId] = @AutoProcessRunId
       AND [rst].[IsSummary]        = @IsSummary
       AND [rst].[ReportHeader]     = 'Summary Year To Date'
