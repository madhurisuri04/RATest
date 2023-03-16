CREATE TRIGGER [Valuation].[TR_ValuationRptSummaryTotal] ON [Valuation].[RptSummaryTotal]
    AFTER INSERT, UPDATE, DELETE
AS
    BEGIN

        DECLARE @Action CHAR(1)

        IF EXISTS ( SELECT
                        1
                    FROM
                        inserted )
            IF EXISTS ( SELECT
                            1
                        FROM
                            deleted )
                SET @Action = 'U'
            ELSE
                SET @Action = 'I'
        ELSE
            SET @Action = 'D'


        IF @Action IN ('I', 'U')
            BEGIN 
            
                INSERT  INTO [Valuation].[LogRptSummaryTotal]
                        (
	[RptSummaryTotalId] ,
	[ClientId] ,
	[ClientId_old] ,
	[AutoProcessRunId] ,
	[AutoProcessRunId_old] ,
	[InitialAutoProcessRunId],
	[InitialAutoProcessRunId_old],
	[ReportHeader],
	[ReportHeader_old],
	[RowDisplay] ,
	[RowDisplay_old],
	[CodingThrough],
	[CodingThrough_old] ,
	[ValuationDelivered],
	[ValuationDelivered_old],
	[ProjectCompletion] ,
	[ProjectCompletion_old],
	[ChartsCompleted],
	[ChartsCompleted_old],
	[HCCTotal_PartC] ,
	[HCCTotal_PartC_old],
	[EstRev_PartC] ,
	[EstRev_PartC_old] ,
	[HCCRealizationRate_PartC] ,
	[HCCRealizationRate_PartC_old] ,
	[EstRevPerChart_PartC],
	[EstRevPerChart_PartC_old],
	[EstRevPerHCC_PartC],
	[EstRevPerHCC_PartC_old],
	[HCCTotal_PartD],
	[HCCTotal_PartD_old],
	[EstRev_PartD],
	[EstRev_PartD_old],
	[HCCRealizationRate_PartD],
	[HCCRealizationRate_PartD_old],
	[EstRevPerChart_PartD],
	[EstRevPerChart_PartD_old],
	[EstRevPerHCC_PartD],
	[EstRevPerHCC_PartD_old],
	[TotalEstRev] ,
	[TotalEstRev_old] ,
	[TotalEstRevPerChart],
	[TotalEstRevPerChart_old],
	[Notes],
	[Notes_old],
	[SummaryYear] ,
	[SummaryYear_old],
	[ChartsRequested] ,
	[ChartsRequested_old],
	[IsSummary],
	[IsSummary_old],
	[PopulatedDate],
	[PopulatedDate_old],
	[Grouping],
	[Grouping_old],
	[GroupingOrder],
	[GroupingOrder_old],
	[Edited],
	[EditedBy],
       [Action]

                        )
                SELECT
	[RptSummaryTotalId]= ISNULL( new.[RptSummaryTotalId], old.[RptSummaryTotalId]),
	[ClientId] = new.[ClientId],
	[ClientId_old] = old.[ClientId],
	[AutoProcessRunId] = new.[AutoProcessRunId]  ,
	[AutoProcessRunId_old] = old.[AutoProcessRunId]  ,
	[InitialAutoProcessRunId] = new.[InitialAutoProcessRunId],
	[InitialAutoProcessRunId_old] = old.[InitialAutoProcessRunId],
	[ReportHeader] = new.[ReportHeader],
	[ReportHeader_old]= old.[ReportHeader],
	[RowDisplay] = new.[RowDisplay]  ,
	[RowDisplay_old] = old.[RowDisplay],
	[CodingThrough] = new.[CodingThrough],
	[CodingThrough_old] = old.[CodingThrough],
	[ValuationDelivered]= new.[ValuationDelivered],
	[ValuationDelivered_old] = old.[ValuationDelivered],
	[ProjectCompletion] = new.[ProjectCompletion] ,
	[ProjectCompletion_old] = old.[ProjectCompletion],
	[ChartsCompleted] = new.[ChartsCompleted] ,
	[ChartsCompleted_old]= old.[ChartsCompleted],
	[HCCTotal_PartC]= new.[HCCTotal_PartC] ,
	[HCCTotal_PartC_old] = old.[HCCTotal_PartC],
	[EstRev_PartC] = new.[EstRev_PartC] ,
	[EstRev_PartC_old] = old.[EstRev_PartC] ,
	[HCCRealizationRate_PartC] = new.[HCCRealizationRate_PartC],
	[HCCRealizationRate_PartC_old]= old.[HCCRealizationRate_PartC],
	[EstRevPerChart_PartC] = new.[EstRevPerChart_PartC],
	[EstRevPerChart_PartC_old] = old.[EstRevPerChart_PartC],
	[EstRevPerHCC_PartC] = new.[EstRevPerHCC_PartC],
	[EstRevPerHCC_PartC_old] = old.[EstRevPerHCC_PartC],
	
	[HCCTotal_PartD] = new.[HCCTotal_PartD],
	[HCCTotal_PartD_old] = old.[HCCTotal_PartD],
	[EstRev_PartD] = new.[EstRev_PartD],
	[EstRev_PartD_old] = old.[EstRev_PartD],
	[HCCRealizationRate_PartD] = new.[HCCRealizationRate_PartD] ,
	[HCCRealizationRate_PartD_old] = old.[HCCRealizationRate_PartD] ,
	[EstRevPerChart_PartD] = new.[EstRevPerChart_PartD],
	[EstRevPerChart_PartD_old] =  old.[EstRevPerChart_PartD],
	[EstRevPerHCC_PartD] = new.[EstRevPerHCC_PartD],
	[EstRevPerHCC_PartD_old] = old.[EstRevPerHCC_PartD],
	[TotalEstRev] = new.[TotalEstRev],
	[TotalEstRev_old] = old.[TotalEstRev],
	[TotalEstRevPerChart] = new.[TotalEstRevPerChart],
	[TotalEstRevPerChart_old] = old.[TotalEstRevPerChart] ,
	[Notes] = new.[Notes],
	[Notes_old]  = old.[Notes],
	[SummaryYear] = new.[SummaryYear] ,
	[SummaryYear_old] = old.[SummaryYear] ,
	[ChartsRequested] = new.[ChartsRequested] ,
	[ChartsRequested_old] = old.[ChartsRequested],
	[IsSummary] = new.[IsSummary],
	[IsSummary_old] = old.[IsSummary],
	[PopulatedDate] = new.[PopulatedDate],
	[PopulatedDate_old]= old.[PopulatedDate],
	[Grouping] = new.[Grouping],
	[Grouping_old] = old.[Grouping],
	[GroupingOrder] = new.[GroupingOrder] ,
	[GroupingOrder_old] = old.[GroupingOrder] ,
	[Edited] = GETDATE(),
	[EditedBy] = USER_NAME(),
       [Action] = @Action



                FROM
                    inserted new
                LEFT JOIN [Deleted] old
                    ON [new].[RptSummaryTotalId] = [old].[RptSummaryTotalId]

            END        
      
        IF @Action = 'D'
            BEGIN 

                INSERT  INTO [Valuation].[LogRptSummaryTotal]
                        (
                         
	[RptSummaryTotalId] ,
	
	[ClientId_old] ,
	[AutoProcessRunId_old] ,
	[InitialAutoProcessRunId_old],
	[ReportHeader_old],
	[RowDisplay_old],
	
	[CodingThrough_old] ,
	[ValuationDelivered_old],
	[ProjectCompletion_old],
	[ChartsCompleted_old],
	[HCCTotal_PartC_old],
	[EstRev_PartC_old] ,
	[HCCRealizationRate_PartC_old] ,
	[EstRevPerChart_PartC_old],
	[EstRevPerHCC_PartC_old],
	[HCCTotal_PartD_old],
	[EstRev_PartD_old],
	[HCCRealizationRate_PartD_old],
	[EstRevPerChart_PartD_old],
	[EstRevPerHCC_PartD_old],
	[TotalEstRev_old] ,
	[TotalEstRevPerChart_old],
	[Notes_old],
	[SummaryYear_old] ,
	[ChartsRequested_old],
	[IsSummary_old],
	[PopulatedDate_old],
	[Grouping_old],
	[GroupingOrder_old],
	[Edited],
	[EditedBy],
       [Action]
                        )
                SELECT
	[RptSummaryTotalId]= old.[RptSummaryTotalId],
		[ClientId_old] = old.[ClientId],
		[AutoProcessRunId_old] = old.[AutoProcessRunId]  ,
		[InitialAutoProcessRunId_old] = old.[InitialAutoProcessRunId],
		[ReportHeader_old]= old.[ReportHeader],
		[RowDisplay_old] = old.[RowDisplay],
		[CodingThrough_old] = old.[CodingThrough],
		[ValuationDelivered_old] = old.[ValuationDelivered],
		[ProjectCompletion_old] = old.[ProjectCompletion],
		[ChartsCompleted_old]= old.[ChartsCompleted],
		[HCCTotal_PartC_old] = old.[HCCTotal_PartC],
		[EstRev_PartC_old] = old.[EstRev_PartC] ,
		[HCCRealizationRate_PartC_old] = old.[HCCRealizationRate_PartC],
		[EstRevPerChart_PartC_old] = old.[EstRevPerChart_PartC],
		[EstRevPerHCC_PartC_old] = old.[EstRevPerHCC_PartC],
		[HCCTotal_PartD_old] = old.[HCCTotal_PartD],
		[EstRev_PartD_old] = old.[EstRev_PartD],
		[HCCRealizationRate_PartD_old] = old.[HCCRealizationRate_PartD] ,
		[EstRevPerChart_PartD_old] =  old.[EstRevPerChart_PartD],
		[EstRevPerHCC_PartD_old] = old.[EstRevPerHCC_PartD],
		[TotalEstRev_old] = old.[TotalEstRev],
		[TotalEstRevPerChart_old] = old.[TotalEstRevPerChart] ,
		[Notes_old]  = old.[Notes],
		[SummaryYear_old] = old.[SummaryYear] ,
		[ChartsRequested_old] = old.[ChartsRequested],
		[IsSummary_old] = old.[IsSummary],
		[PopulatedDate_old]= old.[PopulatedDate],
		[Grouping_old] = old.[Grouping],
		[GroupingOrder_old] = old.[GroupingOrder] ,
		[Edited] = GETDATE(),
		[EditedBy] = USER_NAME(),
               [Action] = 'D'
                FROM
                    DELETEd old       

            END 
    END


