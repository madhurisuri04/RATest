CREATE PROC [Valuation].[UpdateEDateAutoProcessRun]
    @Mode TINYINT ,
    @AutoProcessRunId INT
AS --
    /********************************************************************************************************************
* Name			:	[Valuation].[UpdateEDateAutoProcessRun]																*
* Type 			:	Stored Procedure																					*
* Author       	:	Mitch Casto																							*
* Date			:	2016-10-05																							*
* Version		:																										*
* Description	:	Updates EDate column in Valuation.AutoProcessRun with current datetime stamp using AutoProcessRunId	*
*																														*
* Version History :																										*
* =================																										*
* Author			Date			Version#    TFS Ticket#			Description											*
* -----------------	----------		--------    -----------			------------										*
* MCasto			2016-10-18		1.0			58445 / US57192															*
* MCasto			2017-04-21		1.1			61356 / US59323		Update to use modes.  The spr name may need to be	*
*																	change to more accurately reflect purpose			*
* MCasto			2017-07-27		1.2			RE1039/US67184		Set @Mode =1 to set EDate to Null					*
*												TFS66078																*
*																														*
************************************************************************************************************************/
    /* @Mode Settings
	
	1 = Set [Valuation].[AutoProcessRun].[BDate] = GETDATE() AND [EDate] = NULL
	2 = Set [Valuation].[AutoProcessRun].[EDate] = GETDATE()
	3 = Set [Valuation].[AutoProcessRun].[ClientVisibleBDate] = GETDATE()
	4 = Set [Valuation].[AutoProcessRun].[ClientVisibleEDate] = GETDATE()

*/

    SET NOCOUNT ON

    IF @Mode = 1
        BEGIN
            UPDATE [apr]
            SET    [apr].[BDate] = GETDATE() ,
                   [apr].[EDate] = NULL
            FROM   [Valuation].[AutoProcessRun] [apr]
            WHERE  [apr].[AutoProcessRunId] = @AutoProcessRunId
        END


    IF @Mode = 2
        BEGIN
            UPDATE [apr]
            SET    [apr].[EDate] = GETDATE()
            FROM   [Valuation].[AutoProcessRun] [apr]
            WHERE  [apr].[AutoProcessRunId] = @AutoProcessRunId
        END


    IF @Mode = 3
        BEGIN
            UPDATE [apr]
            SET    [apr].[ClientVisibleBDate] = GETDATE()
            FROM   [Valuation].[AutoProcessRun] [apr]
            WHERE  [apr].[AutoProcessRunId] = @AutoProcessRunId
        END

    IF @Mode = 4
        BEGIN
            UPDATE [apr]
            SET    [apr].[ClientVisibleEDate] = GETDATE()
            FROM   [Valuation].[AutoProcessRun] [apr]
            WHERE  [apr].[AutoProcessRunId] = @AutoProcessRunId
        END

