       
create nonclustered index idx_RptClientPcnStrings 
on RptClientPcnStrings (IDENTIFIER, CLIENT_DB, PAYMENT_YEAR)
INCLUDE (PROJECT, PCN_STRING, LASTUPDATEDTM,ACTIVE,TERMDATE)

