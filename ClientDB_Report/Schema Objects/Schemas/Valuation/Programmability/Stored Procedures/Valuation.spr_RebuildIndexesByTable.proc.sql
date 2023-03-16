CREATE PROC [Valuation].[spr_RebuildIndexesByTable]
    (
     @SchemaName VARCHAR(128) 
   , @TableName VARCHAR(128) 
   , @SortInTemp BIT = 0
   , @Online BIT = 0
   
    )
AS /*
*********************************************************************************        
* Name			:   [Valuation].spr_RebuildIndexesByTable						*                                                     
* Type 			:   Stored Procedure											*                
* Author       	:   Mitch Casto													*
* Date			:   2015-10-30													*	
* Description		:   Provides mechanism to rebuild (defrag) all active		* 
*				    indexes on a table, starting with the primary key			*
* Parameters		:   @SchemaName is the schema name for the subject table	*
*				    @TableName is the name of the subject table					*
*				    @SortInTemp toggles sorting the rebuild in index			*
*				    @Online toggles availability of table during rebuild		*
*																				*
* Version History :																*
* Author			Date		  Version#	TFS Ticket#	    Description			*
* -----------------	----------  --------	-----------	    ------------		*
* Mitch Casto		2015-10-30  1.0a    	45735		    Initial				*
*																				*
*																				*		
*********************************************************************************
*/
    SET NOCOUNT ON 

    DECLARE @Id INT

    DECLARE @IndexName VARCHAR(128)
    DECLARE @Action NVARCHAR(1024)


/*B Clean parameter */

    SET @SchemaName = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@SchemaName)), ']', ''), '[', ''), ';', '')
    SET @TableName = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@TableName)), ']', ''), '[', ''), ';', '')
    

/*B Clean parameter */


    DECLARE @IndexList TABLE
        (
         [Id] INT IDENTITY(1, 1)
                  PRIMARY KEY
       , [SchemaName] VARCHAR(128)
       , [TableName] VARCHAR(128)
       , [IndexName] VARCHAR(128)
       , [Type] TINYINT
        )

/*B Create list of available indexes */

    INSERT  @IndexList
            (
             [SchemaName]
           , [TableName]
           , [IndexName]
           , [Type]
            )
    SELECT DISTINCT
        [SchemaName] = [s].[name]
      , [TableName] = [c].[name]
      , [IndexName] = [b].[name]
      , [Type] = [b].[type]
    FROM
        [sys].[indexes] [b] WITH (NOLOCK)
    JOIN [sys].[objects] [c] WITH (NOLOCK)
        ON [b].[object_id] = [c].[object_id]
    JOIN [sys].[schemas] [s] WITH (NOLOCK)
        ON [c].[schema_id] = [s].[schema_id]
    WHERE
        [c].[type] = 'U'
        AND [b].[name] IS NOT NULL
        AND [b].[is_disabled] = 0
        AND [s].[name] = @SchemaName
        AND [c].[name] = @TableName

/*E Create list of available indexes */


/*B Cycle through list to rebuild IX */

    WHILE EXISTS ( SELECT
                    *
                   FROM
                    @IndexList )
        BEGIN

            SELECT TOP 1
                @Id = [a1].[Id]
              , @SchemaName = [a1].[SchemaName]
              , @TableName = [a1].[TableName]
              , @IndexName = [a1].[IndexName]
            FROM
                @IndexList [a1]
            ORDER BY
                [a1].[SchemaName]
              , [a1].[TableName]
              , [a1].[Type]
              , [a1].[IndexName]

            SET @Action = 'ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] REBUILD WITH (SORT_IN_TEMPDB = ' + CASE WHEN @SortInTemp = 0 THEN 'OFF'
                                                                                                                                                  ELSE 'ON'
                                                                                                                                             END + ', ONLINE = ' + CASE WHEN @Online = 0 THEN 'OFF'
                                                                                                                                                                        ELSE 'ON'
                                                                                                                                                                   END + ')'

            RAISERROR(@Action, 0, 1) WITH NOWAIT
        
            EXEC [sys].[sp_executesql]
                @Action 

            DELETE
                [a1]
            FROM
                @IndexList [a1]
            WHERE
                [a1].[Id] = @Id

        END

/*E Cycle through list to rebuild IX */

