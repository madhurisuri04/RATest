CREATE FUNCTION [dbo].[HCCMostRecentModification] (
	@date1		datetime
	, @date2	datetime = NULL
	, @date3	datetime = NULL
	, @date4	datetime = NULL
	, @date5	datetime = NULL
	--, @date6	datetime = NULL
	--, @date7	datetime = NULL
	--, @date8	datetime = NULL
	--, @date9	datetime = NULL
	--, @date10	datetime = NULL
)
RETURNS datetime
AS
BEGIN
	DECLARE @mostrecent	datetime
	SET @mostrecent = '6/27/1980'

	IF @date1 IS NOT NULL
		IF @date1>@mostrecent
			SET @mostrecent = @date1

	IF @date2 IS NOT NULL
		IF @date2>@mostrecent
			SET @mostrecent = @date2

	IF @date3 IS NOT NULL
		IF @date3>@mostrecent
			SET @mostrecent = @date3

	IF @date4 IS NOT NULL
		IF @date4>@mostrecent
			SET @mostrecent = @date4

	IF @date5 IS NOT NULL
		IF @date5>@mostrecent
			SET @mostrecent = @date5

	--IF @date6 IS NOT NULL
	--	IF @date6>@mostrecent
	--		SET @mostrecent = @date6

	--IF @date7 IS NOT NULL
	--	IF @date7>@mostrecent
	--		SET @mostrecent = @date7

	--IF @date8 IS NOT NULL
	--	IF @date8>@mostrecent
	--		SET @mostrecent = @date8

	--IF @date9 IS NOT NULL
	--	IF @date9>@mostrecent
	--		SET @mostrecent = @date9

	--IF @date10 IS NOT NULL
	--	IF @date10>@mostrecent
	--		SET @mostrecent = @date10

	RETURN @mostrecent
END