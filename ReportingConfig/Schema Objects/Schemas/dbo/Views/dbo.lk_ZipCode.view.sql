﻿Create VIEW dbo.lk_ZipCode AS
SELECT 
	ZipCodeID,
	ZipCode,
	City,
	[State],
	County,
	AreCode,
	CityType,
	CityAliasAbbreviation,
	CityAliasName,
	Latitude,
	Longitude,
	TimeZone,
	Elevation,
	CountyFIPS,
	DayLightSaving,
	PreferredLastLineKey,
	ClassificationCode,
	MulitCounty,
	StateFIPS,
	CityStateKey,
	CityAliasCode,
	PrimaryRecord,
	CityMixedCase,
	CityAliasMixedCase,
	StateANSI,
	CountyANSI,
	FacilityCode,
	CityDeliveryIndicator,
	CarrierRouteRateSortation,
	FinanceNumber,
	UniqueZIPName,
	Created,
	Modified
FROM [$(HRPReporting)].dbo.lk_ZipCode