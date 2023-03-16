CREATE PROCEDURE [dbo].[AutoGetProcessRunId]
 @ClientId INT
  , @ConfigClientMainId INT = -1
  , @FriendlyDescription VARCHAR(256) = NULL
  , @AutoProcessRunId INT OUT



/****************************************************************************************************************************        
* Name			:	AutoGetProcessRunId																						*                                                     
* Type 			:	Stored Procedure																						*                
* Author       	:	D.Waddell																								*
* Date          :	02/06/2016																								*	
* Version		:																											*
* Description	:	Get new HCCs from the roll up tables in																	* 
*					<Client>_Report database																				*
* Version History :																											*
* Author			Date		Version#    TFS Ticket#	Description															*
* -----------------	----------  --------    -----------	------------														*	
*  David Waddell		02/16/2016	1.0		50383		Initial																* 
****************************************************************************************************************************/   


AS
    SET NOCOUNT ON 
   
    INSERT  INTO [Valuation].[AutoProcessRun]
            (
             [ClientId],
            [ConfigClientMainId]
           , [BDate]
           , [FriendlyDescription]
            )
    SELECT
        [ClientId] = @ClientId
      , [ConfigClientMainId] = @ConfigClientMainId
      , [BDate] = GETDATE()
      , [FriendlyDescription] =  @FriendlyDescription 

    SELECT @AutoProcessRunId = SCOPE_IDENTITY()
