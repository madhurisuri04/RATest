CREATE TABLE [dbo].[ExtractDelivery]
(
	ExtractDeliveryID bigint not null identity(1,1),
	ExtractRequestID bigint not null,
	RequestedUserEmail varchar(100),
	ExtractFileName varchar(255),
	ExtractDeliveryLocation varchar(1000),
	ExtractInternalLocation varchar(1000),
	CreatedDate datetime2(7) not null,
	CreatedUser varchar(500) not null,
	UpdatedDate datetime2(7) not null,
	UpdatedUser varchar(500) not null
)
