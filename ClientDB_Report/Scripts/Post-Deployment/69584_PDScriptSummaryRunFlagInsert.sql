
/*Author Madhuri Suri 
TFS Ticket: 69584
Date: 2/26/2018*/

IF NOT EXISTS (SELECT 1 FROM rev.SummaryProcessRunFlag WHERE Process IN ('AltHICN', 'MMR', 'RAPS', 'MOR','EDS'))
BEGIN 
PRINT 'Start Insert'
 INSERT INTO rev.SummaryProcessRunFlag
 VALUES ('AltHICN', 0)
 , ('MMR', 0),
 ('RAPS', 0),
 ('MOR', 0),
 ('EDS', 0)
 ;
 PRINT 'END Insert'
 END 