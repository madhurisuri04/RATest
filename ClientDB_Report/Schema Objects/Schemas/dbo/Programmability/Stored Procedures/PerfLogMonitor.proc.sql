
CREATE PROC [dbo].[PerfLogMonitor]
    @Section VARCHAR(128)			--Section Label.  Usually the first starts with '000', then '001' . . .
  , @ProcessName VARCHAR(128) = NULL	--Within a stp, set to OBJECT_NAME(@@PROCID) to output stp name into output
  , @ET DATETIME = NULL				--Sets the current datetime
  , @MasterET DATETIME				--Sets the intial datetime of process start
  , @ET_Out DATETIME OUT				--Passes the new @ET out
  , @TableOutput BIT = 0				--Set to 1 if output to table is needed
  , @End BIT = 0					--Adds a terminating row.  Set to 1 when last statement    
AS /*
*********************************************************************************        
* Name			:	dbo.PerfLogMonitor											*                                                     
* Type 			:	Stored Procedure											*                
* Author       	:	Mitch Casto													*
* Date			:	2015-09-30													*	
* Version			:															*
* Description		:	Performance Log Monitor - Provides support to enable	*
*					   developers to add debugging code within stored			*
*					   procedures to get logical reads, elapsed time etc.		*
*					   with a minimal code footprint							*
*																				*
* Version History :																*
* Author			Date		  Version#	TFS Ticket#	    Description			*
* -----------------	----------  --------	-----------	    ------------		*
* Mitch Casto		2015-09-30  1.0	    	46394		    Initial				*
*																				*		
*********************************************************************************
*/
    BEGIN
        DECLARE @Now DATETIME = GETDATE()
        SET @ET = ISNULL(@ET, GETDATE())

        IF @TableOutput = 1
            BEGIN
                SELECT
                    [Section] = @Section
                  , [ProcessName] = @ProcessName
                  , [Start] = @ET
                  , [End] = @Now
                  , [ET(secs)] = DATEDIFF(ss, @ET, @Now)
                  , [TotalStart] = @MasterET
                  , [TotalET(secs)] = DATEDIFF(ss, @MasterET, @Now)
            END
            
        PRINT 'ET: ' + CAST(DATEDIFF(ss, @ET, @Now) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), @Now - @ET, 114) + ' || TET: ' + CAST(DATEDIFF(ss, @MasterET, @Now) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), @Now - @MasterET, 114) + ' || ' + CONVERT(CHAR(23), @Now, 121) 
        PRINT @Section
        
        IF @End = 1
            BEGIN
                PRINT 'Total ET: ' + CAST(DATEDIFF(ss, @MasterET, @Now) AS VARCHAR(10)) + ' secs | ' + CONVERT(CHAR(12), @Now - @MasterET, 114) + ' | ' + CONVERT(CHAR(23), @Now, 121) 
                PRINT 'Done.|'
            END 
        RAISERROR('', 0, 1) WITH NOWAIT
                   
        SET @ET_Out = @Now

    END

GO
