/*
Author: Madhuri Suri
Date: 4/10/2017
Ticket: 67934
Descrition: Post Deployment Script - inserting rows to the table [etl].[EstRecvPartitionKey]  
          
*/

IF NOT EXISTS ( SELECT  1
                FROM    [etl].[EstRecvPartitionKey] WHERE PaymentYear = 2018)
BEGIN
PRINT 'Start Script- Inserted'
INSERT INTO [etl].[EstRecvPartitionKey] (PaymentYear, [MYU], [SourceType]) VALUES (2018, 'Y', 'MMR')
INSERT INTO [etl].[EstRecvPartitionKey] (PaymentYear, [MYU], [SourceType]) VALUES (2018, 'Y', 'RAPS')
INSERT INTO [etl].[EstRecvPartitionKey] (PaymentYear, [MYU], [SourceType]) VALUES  (2018,'Y', 'EDS')
INSERT INTO [etl].[EstRecvPartitionKey] (PaymentYear, [MYU], [SourceType]) VALUES (2018, 'N', 'MMR')
INSERT INTO [etl].[EstRecvPartitionKey] (PaymentYear, [MYU], [SourceType]) VALUES  (2018,'N', 'RAPS')
INSERT INTO [etl].[EstRecvPartitionKey] (PaymentYear, [MYU], [SourceType]) VALUES  (2018,'N', 'EDS')

PRINT 'end Script'
END 
ELSE 
BEGIN 
PRINT 'No Insert '
END 
