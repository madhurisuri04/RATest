-- =============================================
-- Script Template
-- =============================================
IF DB_NAME() NOT IN ('HIMConfig')
BEGIN


	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRANSACTION;
	DELETE FROM dbo.OrganizationContract;

	SET IDENTITY_INSERT [dbo].OrganizationContract ON;

	DECLARE @OrgID int;

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Coventry';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
 
	(  1,@OrgID,1,'H0370','ENC0014',45),
	(  2,@OrgID,1,'H1076','ENC0014',45),
	(  3,@OrgID,1,'H1013','ENC0014',45),
	(  4,@OrgID,1,'H1608','ENC0014',45),
	(  5,@OrgID,1,'H1609','ENC0014',45),
	(  6,@OrgID,1,'H2611','ENC0014',45),
	(  7,@OrgID,1,'H2663','ENC0014',45),
	(  8,@OrgID,1,'H2667','ENC0014',45),
	(  9,@OrgID,1,'H2672','ENC0014',45),
	( 10,@OrgID,1,'H3959','ENC0014',45),
	( 11,@OrgID,1,'H5302','ENC0014',45),
	( 12,@OrgID,1,'H5509','ENC0014',45),
	( 13,@OrgID,1,'H5522','ENC0014',45),
	( 14,@OrgID,1,'H5850','ENC0014',45),
	( 15,@OrgID,1,'H7149','ENC0014',45),
	( 16,@OrgID,1,'H7301','ENC0014',45),
	( 17,@OrgID,1,'H7306','ENC0014',45),
	( 18,@OrgID,1,'H8393','ENC0014',45),
	( 19,@OrgID,1,'H8649','ENC0014',45),
	( 20,@OrgID,1,'H8980','ENC0014',45),
	( 21,@OrgID,1,'H9847','ENC0014',45),
	( 22,@OrgID,1,'H3144','ENC0014',45),
	( 23,@OrgID,1,'H1692','ENC0014',45),
	( 24,@OrgID,1,'H3928','ENC0014',45),
	( 25,@OrgID,1,'H5048','ENC0014',45),
	( 26,@OrgID,6,'H0370','SH9569',45),
	( 27,@OrgID,6,'H1076','SH9569',45),
	( 28,@OrgID,6,'H1013','SH9569',45),
	( 29,@OrgID,6,'H1608','SH9569',45),
	( 30,@OrgID,6,'H1609','SH9569',45),
	( 31,@OrgID,6,'H2611','SH9569',45),
	( 32,@OrgID,6,'H2663','SH9569',45),
	( 33,@OrgID,6,'H2667','SH9569',45),
	( 34,@OrgID,6,'H2672','SH9569',45),
	( 35,@OrgID,6,'H3959','SH9569',45),
	( 36,@OrgID,6,'H5302','SH9569',45),
	( 37,@OrgID,6,'H5509','SH9569',45),
	( 38,@OrgID,6,'H5522','SH9569',45),
	( 39,@OrgID,6,'H5850','SH9569',45),
	( 40,@OrgID,6,'H7149','SH9569',45),
	( 41,@OrgID,6,'H7301','SH9569',45),
	( 42,@OrgID,6,'H7306','SH9569',45),
	( 43,@OrgID,6,'H8393','SH9569',45),
	( 44,@OrgID,6,'H8649','SH9569',45),
	( 45,@OrgID,6,'H8980','SH9569',45),
	( 46,@OrgID,6,'H9847','SH9569',45),
	( 47,@OrgID,6,'H3144','SH9569',45),
	( 48,@OrgID,6,'H0846','SH9569',45),
	( 49,@OrgID,6,'H5227','SH9569',45),
	( 50,@OrgID,6,'H5952','SH9569',45),
	( 51,@OrgID,6,'H8239','SH9569',45),
	( 52,@OrgID,6,'H5517','SH9569',45),
	( 53,@OrgID,6,'H7692','SH9569',45),
	( 54,@OrgID,6,'H2947','SH9569',45),
	( 55,@OrgID,6,'H0806','SH9569',45),
	( 56,@OrgID,6,'H7206','SH9569',45),
	( 57,@OrgID,6,'S0197','SH9569',45),
	( 58,@OrgID,6,'S5569','SH9569',45),
	( 59,@OrgID,6,'S5670','SH9569',45),
	( 60,@OrgID,6,'S5674','SH9569',45),
	( 61,@OrgID,6,'S5768','SH9569',45),
	( 62,@OrgID,6,'V1013','SH9569',45),
	( 63,@OrgID,6,'V2663','SH9569',45),
	( 64,@OrgID,6,'M1013','SH9569',45),
	( 65,@OrgID,6,'M1076','SH9569',45),
	( 66,@OrgID,6,'M1609','SH9569',45),
	( 67,@OrgID,6,'M2663','SH9569',45),
	( 68,@OrgID,6,'M2672','SH9569',45),
	( 69,@OrgID,6,'M3959','SH9569',45),
	( 70,@OrgID,6,'M5509','SH9569',45),
	( 71,@OrgID,6,'M5850','SH9569',45),
	( 72,@OrgID,6,'P2663','SH9569',45),
	( 73,@OrgID,6,'P3959','SH9569',45),
	( 74,@OrgID,6,'P5522','SH9569',45),
	( 75,@OrgID,6,'P8980','SH9569',45),
	( 76,@OrgID,6,'P8239','SH9569',45),
	( 77,@OrgID,6,'P5509','SH9569',45),
	( 78,@OrgID,6,'P5850','SH9569',45),
	( 79,@OrgID,6,'P1013','SH9569',45),
	( 80,@OrgID,6,'P2672','SH9569',45),
	( 81,@OrgID,6,'P1609','SH9569',45),
	( 82,@OrgID,6,'P1076','SH9569',45),
	( 83,@OrgID,6,'P8649','SH9569',45),
	( 84,@OrgID,6,'P5517','SH9569',45),
	( 85,@OrgID,6,'P1608','SH9569',45),
	( 86,@OrgID,6,'P7149','SH9569',45),
	( 87,@OrgID,6,'P9847','SH9569',45),
	( 88,@OrgID,6,'P5302','SH9569',45),
	( 89,@OrgID,6,'P7301','SH9569',45),
	( 90,@OrgID,6,'P7306','SH9569',45),
	( 91,@OrgID,6,'P8393','SH9569',45),
	( 92,@OrgID,6,'P7692','SH9569',45),
	( 93,@OrgID,6,'P2947','SH9569',45),
	( 94,@OrgID,6,'P0806','SH9569',45),
	( 95,@OrgID,6,'P7206','SH9569',45),
	( 96,@OrgID,6,'P0370','SH9569',45),
	( 97,@OrgID,6,'P2611','SH9569',45),
	( 98,@OrgID,6,'P2667','SH9569',45),
	( 99,@OrgID,6,'P3144','SH9569',45),
	(100,@OrgID,6,'H9371','SH9569',45),
	(101,@OrgID,6,'H1692','SH9569',45),
	(102,@OrgID,6,'H3928','SH9569',45),
	(103,@OrgID,6,'H5048','SH9569',45),
	(104,@OrgID,1,'H5414','ENC0014',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'MVP Health Care';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(1000,@OrgID,1,'H3305','ENC0010',45),
	(1001,@OrgID,1,'H3346','ENC0010',45),
	(1002,@OrgID,1,'H9615','ENC0010',45),
	(1003,@OrgID,1,'H9859','ENC0010',45),
	(1004,@OrgID,6,'H3305','SH9570',45),
	(1005,@OrgID,6,'H3346','SH9570',45),
	(1006,@OrgID,6,'H9615','SH9570',45),
	(1007,@OrgID,6,'H9859','SH9570',45),
	(1008,@OrgID,6,'H6806','SH9570',45),
	(1009,@OrgID,6,'S0586','',45),
	(1010,@OrgID,1,'H5613','ENC0010',45)

	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Independent Health';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(2000,@OrgID,1,'H3344','ENC0011',45),
	(2001,@OrgID,1,'H3362','ENC0011',45),
	(2002,@OrgID,6,'H3344','SH9578',45),
	(2003,@OrgID,6,'H3362','SH9578',45),
	(2004,@OrgID,6,'H9519','SH9578',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Aetna';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(3000,@OrgID,1,'H0318','ENC0015',45),
	(3001,@OrgID,1,'H0523','ENC0015',45),
	(3002,@OrgID,1,'H0901','ENC0015',45),
	(3003,@OrgID,1,'H1109','ENC0015',45),
	(3004,@OrgID,1,'H1110','ENC0015',45),
	(3005,@OrgID,1,'H1419','ENC0015',45),
	(3006,@OrgID,1,'H2112','ENC0015',45),
	(3007,@OrgID,1,'H3152','ENC0015',45),
	(3008,@OrgID,1,'H3312','ENC0015',45),
	(3009,@OrgID,1,'H3597','ENC0015',45),
	(3010,@OrgID,1,'H3623','ENC0015',45),
	(3011,@OrgID,1,'H3931','ENC0015',45),
	(3012,@OrgID,1,'H4523','ENC0015',45),
	(3013,@OrgID,1,'H4524','ENC0015',45),
	(3014,@OrgID,1,'H4910','ENC0015',45),
	(3015,@OrgID,1,'H5414','ENC0015',45),
	(3016,@OrgID,1,'H5521','ENC0015',45),
	(3017,@OrgID,1,'H5793','ENC0015',45),
	(3018,@OrgID,1,'H5813','ENC0015',45),
	(3019,@OrgID,1,'H5832','ENC0015',45),
	(3020,@OrgID,1,'H5950','ENC0015',45),
	(3021,@OrgID,1,'H6923','ENC0015',45),
	(3022,@OrgID,1,'H7908','ENC0015',45),
	(3023,@OrgID,1,'H8684','ENC0015',45),
	(3024,@OrgID,6,'H0318','SH9577',45),
	(3025,@OrgID,6,'H0523','SH9577',45),
	(3026,@OrgID,6,'H0901','SH9577',45),
	(3027,@OrgID,6,'H1109','SH9577',45),
	(3028,@OrgID,6,'H1110','SH9577',45),
	(3029,@OrgID,6,'H1419','SH9577',45),
	(3030,@OrgID,6,'H2112','SH9577',45),
	(3031,@OrgID,6,'H3152','SH9577',45),
	(3032,@OrgID,6,'H3312','SH9577',45),
	(3033,@OrgID,6,'H3597','SH9577',45),
	(3034,@OrgID,6,'H3623','SH9577',45),
	(3035,@OrgID,6,'H3931','SH9577',45),
	(3036,@OrgID,6,'H4523','SH9577',45),
	(3037,@OrgID,6,'H4524','SH9577',45),
	(3038,@OrgID,6,'H4910','SH9577',45),
	(3039,@OrgID,6,'H5414','SH9577',45),
	(3040,@OrgID,6,'H5521','SH9577',45),
	(3041,@OrgID,6,'H5793','SH9577',45),
	(3042,@OrgID,6,'H5813','SH9577',45),
	(3043,@OrgID,6,'H5832','SH9577',45),
	(3044,@OrgID,6,'H5950','SH9577',45),
	(3045,@OrgID,6,'H6923','SH9577',45),
	(3046,@OrgID,6,'H7908','SH9577',45),
	(3047,@OrgID,6,'H8684','SH9577',45),
	(3048,@OrgID,6,'H0322','SH9577',45),
	(3049,@OrgID,6,'S5810','SH9577',45),
	(3050,@OrgID,6,'R5595','SH9577',45),
	(3051,@OrgID,6,'H9663','SH9577',45),
	(3052,@OrgID,6,'H5736','SH9577',45),
	(3053,@OrgID,6,'H5531','SH9577',45),
	(3054,@OrgID,6,'H5512','SH9577',45),
	(3055,@OrgID,6,'H5510','SH9577',45),
	(3056,@OrgID,6,'H5437','SH9577',45),
	(3057,@OrgID,6,'H5144','SH9577',45),
	(3058,@OrgID,6,'H4911','SH9577',45),
	(3059,@OrgID,6,'H4781','SH9577',45),
	(3060,@OrgID,6,'H4362','SH9577',45),
	(3061,@OrgID,6,'H3624','SH9577',45),
	(3062,@OrgID,6,'H2047','SH9577',45),
	(3063,@OrgID,6,'H1420','SH9577',45),
	(3064,@OrgID,6,'H0902','SH9577',45),
	(3065,@OrgID,6,'H0768','SH9577',45),
	(3066,@OrgID,1,'H6560','ENC0015',45),
	(3067,@OrgID,6,'H6560','SH9577',45),
	(3068,@OrgID,1,'R6694','ENC0015',45),
	(3069,@OrgID,6,'R6694','ENC0015',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Aetna2';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(3500,@OrgID,1,'H0318','ENC0015',45),
	(3501,@OrgID,1,'H0523','ENC0015',45),
	(3502,@OrgID,1,'H0901','ENC0015',45),
	(3503,@OrgID,1,'H1109','ENC0015',45),
	(3504,@OrgID,1,'H1110','ENC0015',45),
	(3505,@OrgID,1,'H1419','ENC0015',45),
	(3506,@OrgID,1,'H2112','ENC0015',45),
	(3507,@OrgID,1,'H3152','ENC0015',45),
	(3508,@OrgID,1,'H3312','ENC0015',45),
	(3509,@OrgID,1,'H3597','ENC0015',45),
	(3510,@OrgID,1,'H3623','ENC0015',45),
	(3511,@OrgID,1,'H3931','ENC0015',45),
	(3512,@OrgID,1,'H4523','ENC0015',45),
	(3513,@OrgID,1,'H4524','ENC0015',45),
	(3514,@OrgID,1,'H4910','ENC0015',45),
	(3515,@OrgID,1,'H5414','ENC0015',45),
	(3516,@OrgID,1,'H5521','ENC0015',45),
	(3517,@OrgID,1,'H5793','ENC0015',45),
	(3518,@OrgID,1,'H5813','ENC0015',45),
	(3519,@OrgID,1,'H5832','ENC0015',45),
	(3520,@OrgID,1,'H5950','ENC0015',45),
	(3521,@OrgID,1,'H6923','ENC0015',45),
	(3522,@OrgID,1,'H7908','ENC0015',45),
	(3523,@OrgID,1,'H8684','ENC0015',45),
	(3524,@OrgID,6,'H0318','SH9577',45),
	(3525,@OrgID,6,'H0523','SH9577',45),
	(3526,@OrgID,6,'H0901','SH9577',45),
	(3527,@OrgID,6,'H1109','SH9577',45),
	(3528,@OrgID,6,'H1110','SH9577',45),
	(3529,@OrgID,6,'H1419','SH9577',45),
	(3530,@OrgID,6,'H2112','SH9577',45),
	(3531,@OrgID,6,'H3152','SH9577',45),
	(3532,@OrgID,6,'H3312','SH9577',45),
	(3533,@OrgID,6,'H3597','SH9577',45),
	(3534,@OrgID,6,'H3623','SH9577',45),
	(3535,@OrgID,6,'H3931','SH9577',45),
	(3536,@OrgID,6,'H4523','SH9577',45),
	(3537,@OrgID,6,'H4524','SH9577',45),
	(3538,@OrgID,6,'H4910','SH9577',45),
	(3539,@OrgID,6,'H5414','SH9577',45),
	(3540,@OrgID,6,'H5521','SH9577',45),
	(3541,@OrgID,6,'H5793','SH9577',45),
	(3542,@OrgID,6,'H5813','SH9577',45),
	(3543,@OrgID,6,'H5832','SH9577',45),
	(3544,@OrgID,6,'H5950','SH9577',45),
	(3545,@OrgID,6,'H6923','SH9577',45),
	(3546,@OrgID,6,'H7908','SH9577',45),
	(3547,@OrgID,6,'H8684','SH9577',45),
	(3548,@OrgID,6,'H0322','SH9577',45),
	(3549,@OrgID,6,'S5810','SH9577',45),
	(3550,@OrgID,6,'R5595','SH9577',45),
	(3551,@OrgID,6,'H9663','SH9577',45),
	(3552,@OrgID,6,'H5736','SH9577',45),
	(3553,@OrgID,6,'H5531','SH9577',45),
	(3554,@OrgID,6,'H5512','SH9577',45),
	(3555,@OrgID,6,'H5510','SH9577',45),
	(3556,@OrgID,6,'H5437','SH9577',45),
	(3557,@OrgID,6,'H5144','SH9577',45),
	(3558,@OrgID,6,'H4911','SH9577',45),
	(3559,@OrgID,6,'H4781','SH9577',45),
	(3560,@OrgID,6,'H4362','SH9577',45),
	(3561,@OrgID,6,'H3624','SH9577',45),
	(3562,@OrgID,6,'H2047','SH9577',45),
	(3563,@OrgID,6,'H1420','SH9577',45),
	(3564,@OrgID,6,'H0902','SH9577',45),
	(3565,@OrgID,6,'H0768','SH9577',45),
	(3566,@OrgID,1,'H6560','ENC0015',45),
	(3567,@OrgID,6,'H6560','SH9577',45),
	(3568,@OrgID,1,'R6694','ENC0015',45),
	(3569,@OrgID,6,'R6694','ENC0015',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Health First Health Plan';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(4000,@OrgID,1,'H1099','ENC0013',45),
	(4001,@OrgID,6,'H1099','SH1099',45),	
	(4002,@OrgID,6,'S0223','SH1099',45)
	
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Lovelace';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(5000,@OrgID,1,'H3251','ENC0016',45),
	(5001,@OrgID,1,'H6801','ENC0016',45),
	(5002,@OrgID,1,'H3511','ENC0016',45),
	(5007,@OrgID,6,'H3251','SH9567',45),
	(5008,@OrgID,6,'H6801','SH9567',45),
	(5009,@OrgID,6,'H3511','SH9567',45),
	(5003,@OrgID,6,'Q3251','XX9567',45),
	(5004,@OrgID,6,'T3251','XX9567',45),
	(5005,@OrgID,6,'H3207','XX9567',45),
	(5006,@OrgID,6,'T3207','XX9567',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Presbyterian Health Plan';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(5050,@OrgID,1,'H3204','ENC0004',45),
	(5051,@OrgID,1,'H3206','ENC0004',45),
	(5052,@OrgID,6,'H3204','SH9579',45),
	(5053,@OrgID,6,'H3206','SH9579',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Humana';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(6000,@OrgID,1,'H7731','ENC0061',45),
	(6001,@OrgID,6,'H7731','SH9590',45),
	(6002,@OrgID,6,'H0248','SHXXXX',45),
	(6003,@OrgID,6,'H0317','SH0248',45),
	(6004,@OrgID,6,'H0623','SH0248',45),
	(6005,@OrgID,6,'H1036','SH0248',45),
	(6006,@OrgID,6,'H1406','SH0248',45),
	(6007,@OrgID,6,'H1418','SH0248',45),
	(6008,@OrgID,6,'H1468','SH0248',45),
	(6009,@OrgID,6,'H1510','SH0248',45),
	(6010,@OrgID,6,'H1681','SH0248',45),
	(6011,@OrgID,6,'H1716','SH0248',45),
	(6012,@OrgID,6,'H1804','SH0248',45),
	(6013,@OrgID,6,'H1806','SH0248',45),
	(6014,@OrgID,6,'H1906','SH0248',45),
	(6015,@OrgID,6,'H1951','SH0248',45),
	(6016,@OrgID,6,'H2029','SH0248',45),
	(6017,@OrgID,6,'H2486','SH0248',45),
	(6018,@OrgID,6,'H2542','SH0248',45),
	(6019,@OrgID,6,'H2649','SH0248',45),
	(6020,@OrgID,6,'H2949','SH0248',45),
	(6021,@OrgID,6,'H3028','SH0248',45),
	(6022,@OrgID,6,'H3405','SH0248',45),
	(6023,@OrgID,6,'H3619','SH0248',45),
	(6024,@OrgID,6,'H4007','SH0248',45),
	(6025,@OrgID,6,'H4008','SH0248',45),
	(6026,@OrgID,6,'H4510','SH0248',45),
	(6027,@OrgID,6,'H4520','SH0248',45),
	(6028,@OrgID,6,'H4606','SH0248',45),
	(6029,@OrgID,6,'H4956','SH0248',45),
	(6030,@OrgID,6,'H5041','SH0248',45),
	(6031,@OrgID,6,'H5214','SH0248',45),
	(6032,@OrgID,6,'H5216','SH0248',45),
	(6033,@OrgID,6,'H5291','SH0248',45),
	(6034,@OrgID,6,'H5415','SH0248',45),
	(6035,@OrgID,6,'H5426','SH0248',45),
	(6036,@OrgID,6,'H5470','SH0248',45),
	(6037,@OrgID,6,'H5525','SH0248',45),
	(6038,@OrgID,6,'H5657','SH0248',45),
	(6039,@OrgID,6,'H5868','SH0248',45),
	(6040,@OrgID,6,'H6411','SH0248',45),
	(6041,@OrgID,6,'H6900','SH0248',45),
	(6042,@OrgID,6,'H7002','SH0248',45),
	(6043,@OrgID,6,'H7188','SH0248',45),
	(6044,@OrgID,6,'H8644','SH0248',45),
	(6045,@OrgID,6,'H8707','SH0248',45),
	(6046,@OrgID,6,'H9503','SH0248',45),
	(6047,@OrgID,6,'R5826','SH0248',45),
	(6048,@OrgID,6,'H1407','SH0248',45),
	(6049,@OrgID,6,'H4461','SH0248',45),
	(6050,@OrgID,6,'H5523','SH0248',45),
	(6051,@OrgID,6,'H5683','SH0248',45),
	(6052,@OrgID,6,'H0108','SH0248',45),
	(6053,@OrgID,6,'H1291','SH0248',45),
	(6054,@OrgID,6,'H2012','SH0248',45),
	(6055,@OrgID,6,'H2944','SH0248',45),
	(6056,@OrgID,6,'H4141','SH0248',45),
	(6057,@OrgID,6,'H4774','SH0248',45),
	(6058,@OrgID,6,'H4785','SH0248',45),
	(6059,@OrgID,6,'H5970','SH0248',45),
	(6060,@OrgID,6,'H6609','SH0248',45),
	(6061,@OrgID,6,'H6622','SH0248',45),
	(6062,@OrgID,6,'H8145','SH0248',45),
	(6063,@OrgID,6,'H8953','SH0248',45),
	(6064,@OrgID,6,'H5948','SH9590',45),
	(6065,@OrgID,6,'H0307','SH0248',45),
	(6066,@OrgID,6,'H4408','SH0248',45)
	;
	END



	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Health Spring';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(7000,@OrgID,1,'H0150','ENC0056',45),
	(7001,@OrgID,1,'H1355','ENC0056',45),
	(7002,@OrgID,1,'H1415','ENC0056',45),
	(7003,@OrgID,1,'H2108','ENC0056',45),
	(7004,@OrgID,1,'H2165','ENC0056',45),
	(7005,@OrgID,1,'H3949','ENC0056',45),
	(7006,@OrgID,1,'H3964','ENC0056',45),
	(7007,@OrgID,1,'H4407','ENC0056',45),
	(7008,@OrgID,1,'H4454','ENC0056',45),
	(7009,@OrgID,1,'H4513','ENC0056',45),
	(7010,@OrgID,1,'H4528','ENC0056',45),
	(7011,@OrgID,1,'H5410','ENC0056',45),
	(7012,@OrgID,1,'H7281','ENC0056',45),
	(7013,@OrgID,1,'H7787','ENC0056',45),
	(7014,@OrgID,1,'H9184','ENC0056',45),
	(7015,@OrgID,1,'H1266','ENC0056',45),
	(7016,@OrgID,1,'H2038','ENC0056',45),
	(7017,@OrgID,1,'H2676','ENC0056',45),
	(7018,@OrgID,1,'H4871','ENC0056',45),
	(7019,@OrgID,1,'H7811','ENC0056',45),
	(7020,@OrgID,1,'H4125','ENC0056',45),
	(7021,@OrgID,1,'H6972','ENC0056',45),
	(7022,@OrgID,6,'S5932','HSPRXX',45),
	(7023,@OrgID,6,'H0150','HSPRXX',45),
	(7024,@OrgID,6,'H1355','HSPRXX',45),
	(7025,@OrgID,6,'H1415','HSPRXX',45),
	(7026,@OrgID,6,'H2108','HSPRXX',45),
	(7027,@OrgID,6,'H2165','HSPRXX',45),
	(7028,@OrgID,6,'H3949','HSPRXX',45),
	(7029,@OrgID,6,'H3964','HSPRXX',45),
	(7030,@OrgID,6,'H4407','HSPRXX',45),
	(7031,@OrgID,6,'H4454','HSPRXX',45),
	(7032,@OrgID,6,'H4513','HSPRXX',45),
	(7033,@OrgID,6,'H4528','HSPRXX',45),
	(7034,@OrgID,6,'H5410','HSPRXX',45),
	(7035,@OrgID,6,'H7281','HSPRXX',45),
	(7036,@OrgID,6,'H7787','HSPRXX',45),
	(7037,@OrgID,6,'H9184','HSPRXX',45),
	(7038,@OrgID,6,'H1266','HSPRXX',45),
	(7039,@OrgID,6,'H2038','HSPRXX',45),
	(7040,@OrgID,6,'H2676','HSPRXX',45),
	(7041,@OrgID,6,'H4871','HSPRXX',45),
	(7042,@OrgID,6,'H7811','HSPRXX',45),
	(7043,@OrgID,6,'H4125','HSPRXX',45),
	(7044,@OrgID,6,'H6972','HSPRXX',45),
	(7045,@OrgID,6,'S5998','HSPRXX',45),
	(7046,@OrgID,6,'H0439','SH9569',45),
	(7047,@OrgID,6,'H3945','SH9577',45),
	(7048,@OrgID,6,'H7020','SH0248',45),
	(7049,@OrgID,6,'H9725','SH9577',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Scott and White Health Plan';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(8000,@OrgID,1,'H4564','ENC0012',45),
	(8001,@OrgID,1,'H8237','ENC0012',45),
	(8002,@OrgID,6,'H4564','SH9566',45),
	(8003,@OrgID,6,'H8237','SH9566',45),
	(8004,@OrgID,6,'S5915','SH9566',45)
	;
	END



	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'The Regence Group';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(9000,@OrgID,1,'H1304','ENC0036',45),
	(9001,@OrgID,1,'H3817','ENC0036',45),
	(9002,@OrgID,1,'H4605','ENC0036',45),
	(9003,@OrgID,1,'H5009','ENC0036',45),
	(9004,@OrgID,1,'H5010','ENC0036',45),
	(9005,@OrgID,1,'H6237','ENC0036',45),
	(9006,@OrgID,1,'H9110','ENC0036',45),
	(9007,@OrgID,1,'H1997','ENC0036',45),
	(9008,@OrgID,6,'H1304','SH9591',45),
	(9009,@OrgID,6,'H3817','SH9591',45),
	(9011,@OrgID,6,'H4605','SH9591',45),
	(9012,@OrgID,6,'H5009','SH9591',45),
	(9013,@OrgID,6,'H5010','SH9591',45),
	(9014,@OrgID,6,'H6237','SH9591',45),
	(9015,@OrgID,6,'H9110','SH9591',45),
	(9016,@OrgID,6,'H1997','SH9591',45),
	(9017,@OrgID,6,'S5609','',45),
	(9018,@OrgID,6,'S5916','',45),
	(9019,@OrgID,6,'H1969','SH9591',45),
	(9020,@OrgID,1,'H1969','SH9591',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name in ('Health Plan of New England (Demo)', 'New England Health');

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(10000,@OrgID,1,'H0000','ENC0000',45),
	(10001,@OrgID,6,'H0000','SH0000',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Health Net';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(11000,@OrgID,3,'H3237','DCAT06',5),
	(11001,@OrgID,3,'H4979','ENC0000',5),
	(11002,@OrgID,3,'H5884','ENC0000',5),
	(11003,@OrgID,3,'H7917','ENC0000',5),
	(11004,@OrgID,6,'H0562','',45),
	(11005,@OrgID,6,'H0351','',45),
	(11006,@OrgID,6,'H5439','',45),
	(11007,@OrgID,6,'H5520','',45),
	(11008,@OrgID,6,'H6815','',45),
	(11009,@OrgID,1,'H3237','DCAT06',45),
	(11010,@OrgID,1,'H4979','ENC0000',45),
	(11011,@OrgID,1,'H5884','ENC0000',45),
	(11012,@OrgID,1,'H7917','ENC0000',45)

	;
	END



	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Molina';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(12000,@OrgID,1,'H5810','ENCXMOL',45),
	(12001,@OrgID,1,'H5926','ENCXMOL',45),
	(12002,@OrgID,1,'H9082','ENCXMOL',45),
	(12003,@OrgID,1,'H7678','ENCXMOL',45),
	(12004,@OrgID,1,'H5628','ENCXMOL',45),
	(12005,@OrgID,1,'H5823','ENCXMOL',45),
	(12006,@OrgID,1,'H0490','ENCXMOL',45),
	(12007,@OrgID,1,'H8130','ENCXMOL',45),
	(12008,@OrgID,1,'H8870','ENCXMOL',45),
	(12009,@OrgID,6,'H5810','SHXXXX',45),
	(12010,@OrgID,6,'H5926','SHXXXX',45),
	(12011,@OrgID,6,'H9082','SHXXXX',45),
	(12012,@OrgID,6,'H7678','SHXXXX',45),
	(12013,@OrgID,6,'H5628','SHXXXX',45),
	(12014,@OrgID,6,'H5823','SHXXXX',45),
	(12015,@OrgID,6,'H0490','SHXXXX',45),
	(12016,@OrgID,6,'H8130','SHXXXX',45),
	(12017,@OrgID,6,'H8870','SHXXXX',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Highmark';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(13000,@OrgID,1,'H3916','ENCXHMK',45),
	(13001,@OrgID,1,'H3957','ENCXHMK',45),
	(13002,@OrgID,1,'H5106','ENCXHMK',45),
	(13003,@OrgID,6,'H3916','SH3957',45),
	(13004,@OrgID,6,'H3957','SH3957',45),
	(13005,@OrgID,6,'H5106','SH3957',45)
	;
	END


	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Blue Cross and Blue Shield of TN';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(14000,@OrgID,1,'H4979','ENCXXTN',45),
	(14001,@OrgID,1,'H5884','ENCXXTN',45),
	(14002,@OrgID,1,'H7917','ENCXXTN',45),
	(14003,@OrgID,1,'H3259','ENCXXTN',45),
	(14004,@OrgID,1,'H8146','ENCXXTN',45),
	(14005,@OrgID,6,'H4979','SH5884',45),
	(14006,@OrgID,6,'H5884','SH5884',45),
	(14007,@OrgID,6,'H7917','SH5884',45),
	(14008,@OrgID,6,'H3259','SH5884',45),
	(14009,@OrgID,6,'H8146','SH5884',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'MCS';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(15000,@OrgID,1,'H4006','ENCXMCS',45),
	(15001,@OrgID,1,'H5577','ENCXMCS',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'VIVA Health';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(16000,@OrgID,1,'H0154','ENCXVIV',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Health Alliance Medical Plans';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(17000,@OrgID,1,'H0773','DILT08',15),
	(17001,@OrgID,1,'H1417','ENC0067',45),
	(17002,@OrgID,1,'H1463','ENC0067',45),
	(17003,@OrgID,1,'H1737','ENC0067',45),
	(17004,@OrgID,1,'H3471','ENC0067',45),
	(17005,@OrgID,1,'S4219','ENC0067',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'CCHP';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(18000,@OrgID,1,'H0571','ENCCCHP',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Sanford Health Plan';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(19000,@OrgID,1,'H3503','ENC0077',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Universal American';

	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(20000,@OrgID,1,'H4506','ENC0088',45),
	(20001,@OrgID,1,'H5656','ENC0088',45),
	(20002,@OrgID,1,'H2775','ENC0088',45),
	(20003,@OrgID,1,'H2816','ENC0088',45),
	(20004,@OrgID,1,'H0174','ENC0088',45),
	(20005,@OrgID,1,'H6361','ENC0088',45)
	;
	END

	SET @OrgID = null;
	SELECT @OrgID = OrganizationID
	FROM dbo.Organization o
	WHERE o.Name = 'Vantage Health Plan';
	
	
	if @OrgID is not null
	BEGIN
	INSERT INTO dbo.OrganizationContract(ID,OrganizationID, LineOfBusinessID, LOBPlanID, LOBSubmitterIdentifier,StateCodeID)
	values
	(21000,@OrgID,1,'H5576','ENC0095',45)	
	;
	END


	SET IDENTITY_INSERT [dbo].OrganizationContract OFF;

	COMMIT TRANSACTION;

END
