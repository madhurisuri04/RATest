Create PROCEDURE [dbo].[sprIsValidAdjustmentReasonCode] 	
	@Code varchar(5),
	@AdjudicationDate DATETIME,
	@result bit out
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @val int;
	select @val = count(*) from lk_ClmStatusReasonWPC where
	@AdjudicationDate >= EffectiveDate	
	AND (DeactivationDate is null or DeactivationDate  = '1900-01-01 00:00:00' or @AdjudicationDate <= DeactivationDate)
	 and Code = @Code
		
	set @result = CAST( @val as bit);    
	
END