CREATE TABLE [dbo].RADVMemberStatuses
(
	ID int identity,
	RADVStatusCode varchar (5),
	RADVStatusDescription varchar (255),
	CreationDateTime datetime2,
	LastUpdateDateTime datetime2
)
