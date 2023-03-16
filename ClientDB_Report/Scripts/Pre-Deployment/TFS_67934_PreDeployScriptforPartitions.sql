/*
Author: Madhuri Suri
Date: 4/10/2017
Ticket: 67934
Descrition: Post Deployment Script - inserting rows to the table [etl].[EstRecvPartitionKey]  
          
*/

IF NOT EXISTS ( SELECT  value
                FROM    sys.partition_schemes ps
                        INNER JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
                        INNER JOIN sys.partition_range_values prf ON pf.function_id = prf.function_id
                WHERE   pf.name = 'pfn_PYMYST'
                        AND ps.name = 'pscheme_PYMYST'
                        AND prf.value = 18 )
    BEGIN 


        ALTER PARTITION SCHEME pscheme_PYMYST
        NEXT USED [PRIMARY]

        ALTER PARTITION FUNCTION pfn_PYMYST()
        SPLIT RANGE  (13);
        ALTER PARTITION SCHEME pscheme_PYMYST
        NEXT USED [PRIMARY]

        ALTER PARTITION FUNCTION pfn_PYMYST()
        SPLIT RANGE  (14);
        ALTER PARTITION SCHEME pscheme_PYMYST
        NEXT USED [PRIMARY]

        ALTER PARTITION FUNCTION pfn_PYMYST()
        SPLIT RANGE  (15);
        ALTER PARTITION SCHEME pscheme_PYMYST
        NEXT USED [PRIMARY]

        ALTER PARTITION FUNCTION pfn_PYMYST()
        SPLIT RANGE  (16);
        ALTER PARTITION SCHEME pscheme_PYMYST
        NEXT USED [PRIMARY]

        ALTER PARTITION FUNCTION pfn_PYMYST()
        SPLIT RANGE  (17);
        ALTER PARTITION SCHEME pscheme_PYMYST
        NEXT USED [PRIMARY]

        ALTER PARTITION FUNCTION pfn_PYMYST()
        SPLIT RANGE  (18);
        PRINT 'End Script'
    END 

ELSE
    BEGIN 
        PRINT 'Partition extension already done '
    END 
