CREATE PROCEDURE [dbo].[sprIsPayableByMedicare]
	@ProcCode VARCHAR(50),
	@StartDate DATETIME,
	@EndDate DATETIME,

	@result BIT OUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @val INT;

	--if there are any active records with the given ProcCode, then it is not payable by Medicare
	SELECT @val = COUNT(*) 
		FROM [dbo].[NonPayableMedicareCode] 
		WHERE ProcCode = @ProcCode
		AND StartDate <= @StartDate
		AND (EndDate IS NULL OR EndDate >= @EndDate);

	--Casting a non-zero number to bit will result in a 1. If there is 1 or more results the ProcCode 
	--is not payable by Medicare. We need to negate the value output from the CAST operation so that 
	--@val > 0 will return 0 (not payable) and @val = 0 will return 1 (payable)
	SET @result = ~CAST(@val as bit);    
END