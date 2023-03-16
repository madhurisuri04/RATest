-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sprIsValidHIPPs] 	
	@Proc varchar(50),
	@StartDate DateTime,
	@EndDate DateTime,
	@result bit out
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @val int;
	select @val = count(*) from lk_HIPPSCMS where
		HIPPSCode = @Proc
		and CodeEffectiveFromDate <= @StartDate
		and (CodeEffectiveThroughDate >= @EndDate
		or CodeEffectiveThroughDate is null);
		
	set @result = CAST( @val as bit);    
END