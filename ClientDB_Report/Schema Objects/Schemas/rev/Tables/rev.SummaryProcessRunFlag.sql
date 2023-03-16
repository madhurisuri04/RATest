CREATE TABLE rev.SummaryProcessRunFlag
(ID INT IDENTITY(1,1) NOT NULL ,
 Process VARCHAR (10) NULL ,
 RunFlag BIT NULL, 
 [RefreshNeeded] [bit] NULL,
 [RefreshNeededDate] [Date] NULL,
 [LastRefreshDate] [Datetime] NULL)
 