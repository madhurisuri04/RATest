CREATE TABLE log.RiskScoreBucketsLoad
(
	RiskScoreBucketsLoadID INT IDENTITY(1,1) NOT NULL,
	EncounterLkupSnapDate DATETIME NOT NULL,
	Bucket1Status VARCHAR(10),
	Bucket1RSSnapDate DATETIME,
	Bucket2Status VARCHAR(10),
	Bucket2RSSnapDate DATETIME,
	Bucket3Status VARCHAR(10),
	Bucket3RSSnapDate DATETIME,
	UserID VARCHAR(30) NOT NULL,
	LoadID BIGINT NOT NULL,
	LoadDate DATETIME2 NOT NULL
)