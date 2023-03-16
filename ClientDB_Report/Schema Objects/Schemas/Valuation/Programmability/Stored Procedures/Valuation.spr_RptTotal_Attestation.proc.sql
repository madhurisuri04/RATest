CREATE PROCEDURE [Valuation].[spr_RptTotal_Attestation]
	 (
     @ClientId INT
   , @AutoProcessRunId INT
   , @ReportType VARCHAR(128)
   , @ReportSubType VARCHAR(128)
    )

AS
    SET NOCOUNT ON 

    
/************************************************************************************ 
* Name			:	Valuation.spr_RptTotal_Attestation								*
* Type 			:	Stored Procedure												*
* Author       	:	D. Waddell													    *
* Date			:	2016-03-23												     	*
* Version		:	1.0																*
* Description	:																    *
*																					*
*																					*
* Version History	:																*
* ===================																*
* Author			Date		  Version#    TFS Ticket#	Description				*
* -----------------	----------  --------    -----------	------------				*
* DWaddell			2016-03-23  1.0			51835			Initial					*
*																					*
************************************************************************************/ 



    SELECT DISTINCT
        [ClientId] = [rt3].[ClientId]
      , [AutoProcessRunId] = [rt3].[AutoProcessRunId]
      , [ReportType] = [rt3].[ReportType]
      , [ReportSubType] = [rt3].[ReportSubType]
      , [ReportHeader] = [rt3].[ReportHeader]
      , [Header] = [rt3].[Header]
      , [RowDisplay03] = [rt3].[RowDisplay]
      , [HCCTotal_PartC03] = [rt3].[HCCTotal_PartC]
      , [EstRev_PartC03] = [rt3].[EstRev_PartC]
      , [EstRevPerHCC_PartC03] = [rt3].[EstRevPerHCC_PartC]
      , [HCCTotal_PartD03] = [rt3].[HCCTotal_PartD]
      , [EstRev_PartD03] = [rt3].[EstRev_PartD]
      , [EstRevPerHCC_PartD03] = [rt3].[EstRevPerHCC_PartD]
      , [OrderFlag03] = [rt3].[OrderFlag]
      , [RowDisplay02] = [rt2].[RowDisplay]
      , [HCCTotal_PartC02] = [rt2].[HCCTotal_PartC]
      , [EstRev_PartC02] = [rt2].[EstRev_PartC]
      , [EstRevPerHCC_PartC02] = [rt2].[EstRevPerHCC_PartC]
      , [HCCTotal_PartD02] = [rt2].[HCCTotal_PartD]
      , [EstRev_PartD02] = [rt2].[EstRev_PartD]
      , [EstRevPerHCC_PartD02] = [rt2].[EstRevPerHCC_PartD]
      , [OrderFlag02] = [rt2].[OrderFlag]
      , [RowDisplay01] = [rt1].[RowDisplay]
      , [HCCTotal_PartC01] = [rt1].[HCCTotal_PartC]
      , [EstRev_PartC01] = [rt1].[EstRev_PartC]
      , [EstRevPerHCC_PartC01] = [rt1].[EstRevPerHCC_PartC]
      , [HCCTotal_PartD01] = [rt1].[HCCTotal_PartD]
      , [EstRev_PartD01] = [rt1].[EstRev_PartD]
      , [EstRevPerHCC_PartD01] = [rt1].[EstRevPerHCC_PartD]
      , [OrderFlag01] = [rt1].[OrderFlag]
      , [RowDisplay00] = [rt0].[RowDisplay]
      , [HCCTotal_PartC00] = [rt0].[HCCTotal_PartC]
      , [EstRev_PartC00] = [rt0].[EstRev_PartC]
      , [EstRevPerHCC_PartC00] = [rt0].[EstRevPerHCC_PartC]
      , [HCCTotal_PartD00] = [rt0].[HCCTotal_PartD]
      , [EstRev_PartD00] = [rt0].[EstRev_PartD]
      , [EstRevPerHCC_PartD00] = [rt0].[EstRevPerHCC_PartD]
      , [OrderFlag00] = [rt0].[OrderFlag]
      , [ProjectId] = [rt3].[ProjectId]
      , [ProjectDescription] = [rt3].[ProjectDescription]
      , [SubProjectId] = [rt3].[SubProjectId]
      , [SubProjectDescription] = [rt3].[SubProjectDescription]
      , [ProjectSortOrder] = [rt3].[ProjectSortOrder]
      , [SubProjectSortOrder] = [rt3].[SubProjectSortOrder]
    FROM
--        [$(ClientDB_Report)].[Valuation].[RptTotal] rt3 WITH (NOLOCK)
        [Valuation].[RptTotal] rt3 WITH (NOLOCK)
        
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptTotal] rt2 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptTotal] rt2 WITH (NOLOCK)
        ON [rt3].[AutoProcessRunId] = [rt2].[AutoProcessRunId]
           AND [rt3].[ClientId] = [rt2].[ClientId]
           AND [rt3].[ProjectId] = [rt2].[ProjectId]
           AND [rt3].[SubProjectId] = [rt2].[SubProjectId]
           AND [rt2].[OrderFlag] = 2
           AND [rt2].[ReportType] = @ReportType
           AND [rt2].[ReportSubType] = @ReportSubType
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptTotal] rt1 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptTotal] rt1 WITH (NOLOCK)
        ON [rt3].[AutoProcessRunId] = [rt1].[AutoProcessRunId]
           AND [rt3].[ClientId] = [rt1].[ClientId]
           AND [rt3].[ProjectId] = [rt1].[ProjectId]
           AND [rt1].[OrderFlag] = 1
           AND [rt1].[ReportType] = @ReportType
           AND [rt1].[ReportSubType] = @ReportSubType
--    LEFT JOIN [$(ClientDB_Report)].[Valuation].[RptTotal] rt0 WITH (NOLOCK)
    LEFT JOIN [Valuation].[RptTotal] rt0 WITH (NOLOCK)

        ON [rt3].[AutoProcessRunId] = [rt0].[AutoProcessRunId]
           AND [rt3].[ClientId] = [rt0].[ClientId]
           AND [rt0].[OrderFlag] = 0
           AND [rt0].[ReportType] = @ReportType
           AND [rt0].[ReportSubType] = @ReportSubType
    WHERE
        [rt3].[AutoProcessRunId] = @AutoProcessRunId
        AND [rt3].[ClientId] = @ClientId
        AND [rt3].[ReportType] = @ReportType
        AND [rt3].[ReportSubType] = @ReportSubType
        AND (ISNULL([rt3].[HCCTotal_PartC], 0) + ISNULL([rt3].[HCCTotal_PartD], 0) > 0
       --      OR ISNULL([rt2].[HCCTotal_PartC], 0) + ISNULL([rt2].[HCCTotal_PartD], 0) > 0
         --    OR ISNULL([rt1].[HCCTotal_PartC], 0) + ISNULL([rt1].[HCCTotal_PartD], 0) > 0
         --    OR ISNULL([rt0].[HCCTotal_PartC], 0) + ISNULL([rt0].[HCCTotal_PartD], 0) > 0
             )
        AND [rt3].[OrderFlag] = 3


RETURN 0