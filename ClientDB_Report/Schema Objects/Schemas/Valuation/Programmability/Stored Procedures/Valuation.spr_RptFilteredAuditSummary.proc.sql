CREATE PROCEDURE [Valuation].[spr_RptFilteredAuditSummary] (@ClientId INT
                                                          , @AutoProcessRunId INT)
AS
    SET NOCOUNT ON

    /**************************************************************************************************** 
* Name			:	Valuation.spr_RptFilteredAuditSummary											*
* Type 			:	Stored Procedure																*
* Author       	:	David Waddell																	*
* Date			:	2016-03-24																		*
* Version		:																					*
* Description	: Swelect for FilterAuditSummary Rpt						 						*
*																									*
* Version History :																					*
* =================================================================================================	*
* Author			Date		Version#    TFS Ticket#	Description									*
* -----------------	----------  --------    -----------	------------								*
* David Waddell		2016-03-24	1.0			51835		Initial										*
*																									*
*****************************************************************************************************/

    SELECT DISTINCT [ClientId] = [rv3].[ClientId]
                  , [AutoProcessRunId] = [rv3].[AutoProcessRunId]
                  , [ReportHeader] = [rv3].[ReportHeader]
                  , [DOSPaymentYearHeader] = [rv3].[DOSPaymentYearHeader]

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

      FROM
        --        [$(ClientDB_Report)].[Valuation].[RptRetrospectiveValuationDetail] rv3 WITH (NOLOCK)
                    [Valuation].[RptRetrospectiveValuationDetail] [rv3] WITH (NOLOCK)


     WHERE          [rv3].[AutoProcessRunId] = @AutoProcessRunId
       AND          [rv3].[ClientId]         = @ClientId
       AND          [rv3].[ReportType]       = 'FilteredAuditSummary'
