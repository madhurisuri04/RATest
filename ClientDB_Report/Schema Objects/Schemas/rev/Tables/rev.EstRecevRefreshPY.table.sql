    CREATE TABLE rev.EstRecevRefreshPY
        (
          EstRecevRefreshPYID INT IDENTITY(1, 1) ,
          Payment_Year INT ,
          MYU VARCHAR(2) ,
          ProcessedBy DATETIME ,
          DCPFromDate DATETIME ,
          DCPThrudate DATETIME
        )