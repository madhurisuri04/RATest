CREATE TABLE [etl].[EstRecvPartitionKey](
	[EstRecvPartitionKeyID] [INT] IDENTITY(1,1) NOT NULL,
	[PaymentYear] [VARCHAR](4) NOT NULL,
	[MYU] [VARCHAR](1) NOT NULL,
    [SourceType] [VARCHAR](4) NULL)

