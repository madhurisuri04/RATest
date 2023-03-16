CREATE PROCEDURE [Valuation].[UpdateAutoProcessWorkList]
	(
	@AutoProcessId INT = NULL
    ,@AutoProcessRunId INT = NULL
    , @Debug BIT = 0
    , @Parameter VARCHAR (8000) = NULL
    )
AS
    SET STATISTICS IO OFF
    SET NOCOUNT ON

    IF @Debug = 1
        BEGIN
            SET STATISTICS IO ON
            DECLARE @ET DATETIME
            DECLARE @MasterET DATETIME
            SET @ET = GETDATE()
            SET @MasterET = @ET
        END

    DECLARE @DelSQL VARCHAR(1024)
    DECLARE @InsertSQL VARCHAR(4096)
    DECLARE @UpdateSQL VARCHAR(4096)

    IF @Debug = 1
        BEGIN
            Exec [dbo].[PerfLogMonitor] '000','UpdateAutoProcessWorkList',@ET,@MasterET,NULL,0,0
        END
        
  
    

	/************************************************/
	/* Insert record into AutoProcessWorkList Table */ 
	/************************************************/

    SET @InsertSQL = '
	INSERT INTO [dbo].[AutoProcessWorkList] ( 
		   ,[ClientId]         
           ,[AutoProcessRunId]  
           ,[AutoProcessId]
           ,[AutoProcessActionId]
           ,[Phase]
           ,[Priority]
           ,[PreRunSecs] 
           ,[DbName]
           ,[CommandDb] 
           ,[CommandSchema] 
           ,[CommandSTP] 
           ,[Parameter] 
           ,[AutoProcessActionCatalogId]  
           ,[DependAutoProcessActionCatalogId] 
           ,[ByPlan]
           )
           
         Select            
           [ClientId] = ap.[ClientId] 
           ,[AutoProcessRunId]
           ,[AutoProcessId]
           ,[AutoProcessActionId]
           ,[Phase]
           ,[Priority]
           ,[PreRunSecs] = 0
           ,[DbName] = cm.[ClientReportDb]
           ,[CommandDb]
           ,[CommandSchema]
           ,[CommandSTP]
           ,CASE
				WHEN ac.PopulateParameter = 1 THEN csp.ParameterValue
				ELSE  '''+ @Parameter +'''
			END as [Parameter]
           ,[AutoProcessActionCatalogId] = ISNULL(ap.AutoProcessActionCatalogId,ac.AutoProcessActionCatalogId)
           ,[DependAutoProcessActionCatalogId] = ISNULL(ap.DependAutoProcessActionCatalogId,ac.DependAutoProcessActionCatalogId)
           ,[ByPlan] = ISNULL(ap.ByPlan,ac.ByPlan)  
           
           From dbo.AutoProcessAction ap 
           inner join dbo.AutoProcessActionCatalog ac 
           on ap.AutoProcessActionCatalogId = ac.AutoProcessActionCatalogId 
           left join Valuation.ConfigStaticParameters csp 
           on ap.AutoProcessActionCatalogId = csp.AutoProcessActionCatalogId 
		   inner join Valuation.ConfigClientMain cm
		   on ap.ap.ClientId = cm.ClientId
		   Where  ap.AutoProcessRunId = '+ @AutoProcessRunId + ' and ap.AutoProcessId = '+ @AutoProcessId + 'and ISNULL(cm.[ActiveEDate],'') = '''''



	 IF @Debug = 1
        BEGIN

      		PRINT '--======================--'
            PRINT '@AutoProcessRunId: ' + CAST(@AutoProcessRunId AS VARCHAR(11))
			PRINT '--======================--'
            PRINT @InsertSQL
            PRINT '--======================--'
            
            
            Exec [dbo].[PerfLogMonitor] '001','UpdateAutoProcessWorkList',@ET,@MasterET,NULL,0,0
        
        END
        
   
    
    EXEC (@InsertSQL);


/******************************************************************/
/* Update Previous Run Second for AutoProcessWorkList Table       */
/******************************************************************/


WITH    PreviousRunSub_CTE		/*B Get the last [AutoProcessWorkListId] for DbName, Schema & STP */
          AS (
				SELECT [AutoProcessWorkListId] = MAX(pwl.[AutoProcessWorkListId])
					, [DbName] = pwl.[DbName]
                    , [CommandDb] = pwl.[CommandDb]
                    , [CommandSchema] = pwl.[CommandSchema]
                    , [CommandSTP] = pwl.[CommandSTP]
				FROM [dbo].[AutoProcessWorkList] pwl
                WHERE
					pwl.[BDate] IS NOT NULL
                    AND pwl.[EDate] IS NOT NULL
                GROUP BY 
                    pwl.[DbName]
                    , pwl.[CommandDb]
                    , pwl.[CommandSchema]
                    , pwl.[CommandSTP]

      /*E Get the last [AutoProcessWorkListId] for DbName, Schema & STP */
      
             ) ,
        PreviousRun_CTE			/*B Get the last ET for DbName, Schema & STP */
          AS (
				SELECT [DbName] = pwl.[DbName]
					, [CommandDb] = pwl.[CommandDb]
                    , [CommandSchema] = pwl.[CommandSchema]
                    , [CommandSTP] = pwl.[CommandSTP]
                    , [ET(secs)] = DATEDIFF(ss, pwl.[BDate], pwl.[EDate])
                FROM [dbo].[AutoProcessWorkList] pwl
                JOIN PreviousRunSub_CTE a1
                ON pwl.[AutoProcessWorkListId] = a1.[AutoProcessWorkListId]
                WHERE pwl.[BDate] IS NOT NULL
					AND pwl.[EDate] IS NOT NULL
                GROUP BY 
					pwl.[DbName]
                    , pwl.[CommandDb]
                    , pwl.[CommandSchema]
                    , pwl.[CommandSTP]
                    , pwl.[BDate]
                    , pwl.[EDate]

      /*E Get the last ET for DbName, Schema & STP */
      
             ) ,
        Avg_CTE
          AS (SELECT
                [DbName] = pwl.[DbName]
              , [CommandDb] = pwl.[CommandDb]
              , [CommandSchema] = pwl.[CommandSchema]
              , [CommandSTP] = pwl.[CommandSTP]
              , [ET(secs)] = AVG(DATEDIFF(ss, pwl.[BDate], pwl.[EDate]))
              FROM [dbo].[AutoProcessWorkList] pwl
              WHERE
                pwl.[BDate] IS NOT NULL
                AND pwl.[EDate] IS NOT NULL
              GROUP BY
                pwl.[DbName]
              , pwl.[CommandDb]
              , pwl.[CommandSchema]
              , pwl.[CommandSTP]
             ) ,
        Results_CTE
          AS (SELECT
                b.[DbName]
              , b.[CommandDb]
              , b.[CommandSchema]
              , b.[CommandSTP]
              , [ET(secs)] = AVG(b.[ET(secs)])
              FROM
                (SELECT
                    a.[DbName]
                  , a.[CommandDb]
                  , a.[CommandSchema]
                  , a.[CommandSTP]
                  , a.[ET(secs)]
                 FROM
                    PreviousRun_CTE a
                 UNION ALL
                 SELECT
                    a.[DbName]
                  , a.[CommandDb]
                  , a.[CommandSchema]
                  , a.[CommandSTP]
                  , a.[ET(secs)]
                 FROM
                    Avg_CTE a
                ) b
              GROUP BY
                b.[DbName]
              , b.[CommandDb]
              , b.[CommandSchema]
              , b.[CommandSTP]
             )

	/* upate PreRuns Sec    */ 
    UPDATE
        pwl
    SET
        pwl.[PreRunSecs] = r1.[ET(secs)]
    FROM
        [dbo].[AutoProcessWorkList] pwl
    JOIN Results_CTE r1
        ON ISNULL(pwl.[DbName], 'x') = ISNULL(r1.[DbName], 'x')
           AND ISNULL(pwl.[CommandDb], 'x') = ISNULL(r1.[CommandDb], 'x')
           AND ISNULL(pwl.[CommandSchema], 'x') = ISNULL(r1.[CommandSchema], 'x')
           AND pwl.[CommandSTP] = r1.[CommandSTP]
    WHERE
        pwl.[AutoProcessRunId] = @AutoProcessRunId
        AND (
             pwl.[ErrorInfo] IS NULL
             OR pwl.[ErrorInfo] = ''
            )
        AND r1.[ET(secs)] > 0


/******************************************************************/
/* End of Add Previous Run Seconds for AutoProcessWorkList Table  */
/******************************************************************/

	   
   





    IF @Debug = 1
        BEGIN

             Exec [dbo].[PerfLogMonitor] '002','UpdateAutoProcessWorkList',@ET,@MasterET,NULL,0,0
             Exec [dbo].[PerfLogMonitor] 'Done','UpdateAutoProcessWorkList',@ET,@MasterET,NULL,0,1
        END
GO


