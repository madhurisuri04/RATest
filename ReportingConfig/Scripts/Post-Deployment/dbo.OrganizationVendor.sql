-- =============================================
-- Script Template
-- =============================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
DELETE FROM dbo.OrganizationVendor;

SET IDENTITY_INSERT [dbo].OrganizationVendor ON;
GO

DECLARE @OrgID int;

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Coventry';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1,@OrgID, 'ASH',  1, 1),
(2,@OrgID, 'CVTY', 0, 1),
(3,@OrgID, 'DNS', 1, 1),
(4,@OrgID, 'EYEMEDGHP', 1, 1),
(5,@OrgID, 'EYEMEDHA', 1, 1),
(6,@OrgID, 'HEARHA', 1, 1),
(7,@OrgID, 'HEARX', 1, 1),
(8,@OrgID, 'HRP', 1, 1),
(9,@OrgID, 'ILS', 1, 1),
(10,@OrgID, 'LCRP', 1, 1),
(11,@OrgID, 'MHNET', 1, 1),
(12,@OrgID, 'ONS', 1, 1),
(13,@OrgID, 'OPTUM', 1, 1),
(14,@OrgID, 'PCARE', 1, 1),
(15,@OrgID, 'PODCR', 1, 1),
(16,@OrgID, 'QUES', 1, 1),
(17,@OrgID, 'QUESHP', 1, 1),
(18,@OrgID, 'SFMSC', 1, 1),
(19,@OrgID, 'SOLSTICE', 1, 1),
(20,@OrgID, 'VCI', 1, 1),
(21,@OrgID, 'AVESIS', 1, 1),
(22,@OrgID, 'CENSEO', 1, 1),
(23,@OrgID, 'ADVHLTH', 1, 1),
(24,@OrgID, 'MedSave', 1, 1),
(25,@OrgID, 'EPISOURCE', 1, 1),
(26,@OrgID, 'ION', 1, 1),
(27,@OrgID, 'Matrix', 1, 1),
(28,@OrgID, 'YHA', 1, 1),
(29,@OrgID, 'OptumIns', 1, 1),
(30,@OrgID, 'PrvCo0001',1,1),
(31,@OrgID, 'PrvCo0002',1,1),
(32,@OrgID, 'PrvCo0003',1,1),
(33,@OrgID, 'PrvCo0004',1,1),
(34,@OrgID, 'PrvCo0005',1,1),
(35,@OrgID, 'PrvCo0006',1,1),
(36,@OrgID, 'PrvCo0007',1,1),
(37,@OrgID, 'PrvCo0008',1,1),
(38,@OrgID, 'PrvCo0009',1,1),
(39,@OrgID, 'PrvCo0010',1,1),
(40,@OrgID, 'PrvCo0011',1,1),
(41,@OrgID, 'PrvCo0012',1,1),
(42,@OrgID, 'PrvCo0013',1,1),
(43,@OrgID, 'PrvCo0014',1,1),
(44,@OrgID, 'PrvCo0015',1,1),
(45,@OrgID, 'PrvCo0016',1,1),
(46,@OrgID, 'PrvCo0017',1,1),
(47,@OrgID, 'PrvCo0018',1,1),
(48,@OrgID, 'PrvCo0019',1,1),
(49,@OrgID, 'PrvCo0020',1,1),
(50,@OrgID, 'PrvCo0021',1,1),
(51,@OrgID, 'PrvCo0022',1,1),
(52,@OrgID, 'PrvCo0023',1,1),
(53,@OrgID, 'PrvCo0024',1,1),
(54,@OrgID, 'PrvCo0025',1,1),
(55,@OrgID, 'PrvCo0026',1,1),
(56,@OrgID, 'PrvCo0027',1,1),
(57,@OrgID, 'PrvCo0028',1,1),
(58,@OrgID, 'PrvCo0029',1,1),
(59,@OrgID, 'PrvCo0030',1,1),
(60,@OrgID, 'PrvCo0031',1,1),
(61,@OrgID, 'PrvCo0032',1,1),
(62,@OrgID, 'PrvCo0033',1,1),
(63,@OrgID, 'PrvCo0034',1,1),
(64,@OrgID, 'PrvCo0035',1,1),
(65,@OrgID, 'PrvCo0036',1,1),
(66,@OrgID, 'PrvCo0037',1,1),
(67,@OrgID, 'PrvCo0038',1,1),
(68,@OrgID, 'PrvCo0039',1,1),
(69,@OrgID, 'PrvCo0040',1,1),
(70,@OrgID, 'PrvCo0041',1,1),
(71,@OrgID, 'PrvCo0042',1,1),
(72,@OrgID, 'PrvCo0043',1,1),
(73,@OrgID, 'PrvCo0044',1,1),
(74,@OrgID, 'PrvCo0045',1,1),
(75,@OrgID, 'PrvCo0046',1,1),
(76,@OrgID, 'PrvCo0047',1,1),
(77,@OrgID, 'PrvCo0048',1,1),
(78,@OrgID, 'PrvCo0049',1,1),
(79,@OrgID, 'PrvCo0050',1,1),
(80,@OrgID, 'PrvCo0051',1,1),
(81,@OrgID, 'PrvCo0052',1,1),
(82,@OrgID, 'PrvCo0053',1,1),
(83,@OrgID, 'PrvCo0054',1,1),
(84,@OrgID, 'PrvCo0055',1,1),
(85,@OrgID, 'PrvCo0056',1,1),
(86,@OrgID, 'PrvCo0057',1,1),
(87,@OrgID, 'PrvCo0058',1,1),
(88,@OrgID, 'PrvCo0059',1,1),
(89,@OrgID, 'PrvCo0060',1,1),
(90,@OrgID, 'PrvCo0061',1,1),
(91,@OrgID, 'PrvCo0062',1,1),
(92,@OrgID, 'PrvCo0063',1,1),
(93,@OrgID, 'PrvCo0064',1,1),
(94,@OrgID, 'PrvCo0065',1,1),
(95,@OrgID, 'PrvCo0066',1,1),
(96,@OrgID, 'PrvCo0067',1,1),
(97,@OrgID, 'PrvCo0068',1,1),
(98,@OrgID, 'PrvCo0069',1,1),
(99,@OrgID, 'PrvCo0070',1,1),
(100,@OrgID,'PrvCo0071',1,1),
(101,@OrgID,'PrvCo0072',1,1),
(102,@OrgID,'PrvCo0073',1,1),
(103,@OrgID,'PrvCo0074',1,1),
(104,@OrgID,'PrvCo0075',1,1),
(105,@OrgID,'PrvCo0076',1,1),
(106,@OrgID,'PrvCo0077',1,1),
(107,@OrgID,'PrvCo0078',1,1),
(108,@OrgID,'PrvCo0079',1,1),
(109,@OrgID,'PrvCo0080',1,1),
(110,@OrgID,'PrvCo0081',1,1),
(111,@OrgID,'PrvCo0082',1,1),
(112,@OrgID,'PrvCo0083',1,1),
(113,@OrgID,'PrvCo0084',1,1),
(114,@OrgID,'PrvCo0085',1,1),
(115,@OrgID,'PrvCo0086',1,1),
(116,@OrgID,'PrvCo0087',1,1),
(117,@OrgID,'PrvCo0088',1,1),
(118,@OrgID,'PrvCo0089',1,1),
(119,@OrgID,'PrvCo0090',1,1),
(120,@OrgID,'PrvCo0091',1,1),
(121,@OrgID,'PrvCo0092',1,1),
(122,@OrgID,'PrvCo0093',1,1),
(123,@OrgID,'PrvCo0094',1,1),
(124,@OrgID,'PrvCo0095',1,1),
(125,@OrgID,'PrvCo0096',1,1),
(126,@OrgID,'PrvCo0097',1,1),
(127,@OrgID,'PrvCo0098',1,1),
(128,@OrgID,'PrvCo0099',1,1),
(129,@OrgID,'PrvCo0100',1,1),
(130,@OrgID,'PrvCo0101',1,1),
(131,@OrgID,'PrvCo0102',1,1),
(132,@OrgID,'PrvCo0103',1,1),
(133,@OrgID,'PrvCo0104',1,1),
(134,@OrgID,'PrvCo0105',1,1),
(135,@OrgID,'PrvCo0106',1,1),
(136,@OrgID,'PrvCo0107',1,1),
(137,@OrgID,'PrvCo0108',1,1),
(138,@OrgID,'PrvCo0109',1,1),
(139,@OrgID,'PrvCo0110',1,1),
(140,@OrgID,'PrvCo0111',1,1),
(141,@OrgID,'PrvCo0112',1,1),
(142,@OrgID,'PrvCo0113',1,1),
(143,@OrgID,'PrvCo0114',1,1),
(144,@OrgID,'PrvCo0115',1,1),
(145,@OrgID,'PrvCo0116',1,1),
(146,@OrgID,'PrvCo0117',1,1),
(147,@OrgID,'PrvCo0118',1,1),
(148,@OrgID,'PrvCo0119',1,1),
(149,@OrgID,'PrvCo0120',1,1),
(150,@OrgID,'PrvCo0121',1,1),
(151,@OrgID,'PrvCo0122',1,1),
(152,@OrgID,'PrvCo0123',1,1),
(153,@OrgID,'PrvCo0124',1,1),
(154,@OrgID,'PrvCo0125',1,1),
(155,@OrgID,'PrvCo0126',1,1),
(156,@OrgID,'PrvCo0127',1,1),
(157,@OrgID,'IPA0001',1,1),
(158,@OrgID,'IPA0002',1,1),
(159,@OrgID,'IPA0003',1,1),
(160,@OrgID,'IPA0004',1,1),
(161,@OrgID,'IPA0005',1,1),
(162,@OrgID,'IPA0006',1,1),
(163,@OrgID,'IPA0007',1,1),
(164,@OrgID,'IPA0008',1,1),
(165,@OrgID,'IPA0009',1,1),
(166,@OrgID,'IPA0010',1,1),
(167,@OrgID,'IPA0011',1,1),
(168,@OrgID,'IPA0012',1,1),
(169,@OrgID,'IPA0013',1,1),
(170,@OrgID,'IPA0014',1,1),
(171,@OrgID,'IPA0015',1,1),
(172,@OrgID,'IPA0016',1,1),
(173,@OrgID,'IPA0017',1,1),
(174,@OrgID,'IPA0018',1,1),
(175,@OrgID,'IPA0019',1,1),
(176,@OrgID,'IPA0021',1,1),
(177,@OrgID,'IPA0022',1,1),
(178,@OrgID,'IPA0023',1,1),
(179,@OrgID,'IPA0024',1,1),
(180,@OrgID,'IPA0025',1,1),
(181,@OrgID,'IPA0026',1,1),
(182,@OrgID,'IPA0027',1,1),
(183,@OrgID,'IPA0028',1,1),
(184,@OrgID,'PrvCo0128',1,1),
(185,@OrgID,'VH',1,1),
-- Added as part of tfs 53138 
(186,@OrgID,'IPA0029',1,1),
(187,@OrgID,'IPA0030',1,1),
(188,@OrgID,'IPA0031',1,1),
(189,@OrgID,'IPA0032',1,1),
(190,@OrgID,'IPA0033',1,1),
(191,@OrgID,'IPA0034',1,1),
(192,@OrgID,'IPA0035',1,1),
(193,@OrgID,'TRNSUN',1,1),
(194,@OrgID,'PrvCo0130',1,1),
(195,@OrgID,'VTEDS',1,1),
--added as tfs 56885
(205,@OrgID,'CHC0001',1,1),
(206,@OrgID,'CHC0002',1,1),
(207,@OrgID,'CHC0003',1,1),
(208,@OrgID,'CHC0004',1,1),
(209,@OrgID,'CHC0005',1,1),
(210,@OrgID,'CHC0006',1,1),
(211,@OrgID,'CHC0007',1,1),
(212,@OrgID,'CHC0008',1,1),
(213,@OrgID,'CHC0009',1,1),
(214,@OrgID,'CHC0010',1,1),
(215,@OrgID,'CHC0011',1,1),
(216,@OrgID,'CHC0012',1,1),
(217,@OrgID,'CHC0013',1,1),
(218,@OrgID,'CHC0014',1,1),
(219,@OrgID,'CHC0015',1,1),
(220,@OrgID,'CHC0016',1,1),
(221,@OrgID,'CHC0017',1,1),
(222,@OrgID,'APIXIO',1,1),
(223,@OrgID,'OPTUMInsight',1,1),
--Added as tfs 61250
(224,@OrgID,'PrvCo0129',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Coventry2';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1501,@OrgID, 'ASH',  1, 1),
(1502,@OrgID, 'CVTY', 0, 1),
(1503,@OrgID, 'DNS', 1, 1),
(1504,@OrgID, 'EYEMEDGHP', 1, 1),
(1505,@OrgID, 'EYEMEDHA', 1, 1),
(1506,@OrgID, 'HEARHA', 1, 1),
(1507,@OrgID, 'HEARX', 1, 1),
(1508,@OrgID, 'HRP', 1, 1),
(1509,@OrgID, 'ILS', 1, 1),
(1510,@OrgID, 'LCRP', 1, 1),
(1511,@OrgID, 'MHNET', 1, 1),
(1512,@OrgID, 'ONS', 1, 1),
(1513,@OrgID, 'OPTUM', 1, 1),
(1514,@OrgID, 'PCARE', 1, 1),
(1515,@OrgID, 'PODCR', 1, 1),
(1516,@OrgID, 'QUES', 1, 1),
(1517,@OrgID, 'QUESHP', 1, 1),
(1518,@OrgID, 'SFMSC', 1, 1),
(1519,@OrgID, 'SOLSTICE', 1, 1),
(1520,@OrgID, 'VCI', 1, 1),
(1521,@OrgID, 'AVESIS', 1, 1),
(1522,@OrgID, 'CENSEO', 1, 1),
(1523,@OrgID, 'ADVHLTH', 1, 1),
(1524,@OrgID, 'MedSave', 1, 1),
(1525,@OrgID, 'EPISOURCE', 1, 1),
(1526,@OrgID, 'ION', 1, 1),
(1527,@OrgID, 'Matrix', 1, 1),
(1528,@OrgID, 'YHA', 1, 1),
(1529,@OrgID, 'OptumIns', 1, 1),
(1530,@OrgID, 'PrvCo0001',1,1),
(1531,@OrgID, 'PrvCo0002',1,1),
(1532,@OrgID, 'PrvCo0003',1,1),
(1533,@OrgID, 'PrvCo0004',1,1),
(1534,@OrgID, 'PrvCo0005',1,1),
(1535,@OrgID, 'PrvCo0006',1,1),
(1536,@OrgID, 'PrvCo0007',1,1),
(1537,@OrgID, 'PrvCo0008',1,1),
(1538,@OrgID, 'PrvCo0009',1,1),
(1539,@OrgID, 'PrvCo0010',1,1),
(1540,@OrgID, 'PrvCo0011',1,1),
(1541,@OrgID, 'PrvCo0012',1,1),
(1542,@OrgID, 'PrvCo0013',1,1),
(1543,@OrgID, 'PrvCo0014',1,1),
(1544,@OrgID, 'PrvCo0015',1,1),
(1545,@OrgID, 'PrvCo0016',1,1),
(1546,@OrgID, 'PrvCo0017',1,1),
(1547,@OrgID, 'PrvCo0018',1,1),
(1548,@OrgID, 'PrvCo0019',1,1),
(1549,@OrgID, 'PrvCo0020',1,1),
(1550,@OrgID, 'PrvCo0021',1,1),
(1551,@OrgID, 'PrvCo0022',1,1),
(1552,@OrgID, 'PrvCo0023',1,1),
(1553,@OrgID, 'PrvCo0024',1,1),
(1554,@OrgID, 'PrvCo0025',1,1),
(1555,@OrgID, 'PrvCo0026',1,1),
(1556,@OrgID, 'PrvCo0027',1,1),
(1557,@OrgID, 'PrvCo0028',1,1),
(1558,@OrgID, 'PrvCo0029',1,1),
(1559,@OrgID, 'PrvCo0030',1,1),
(1560,@OrgID, 'PrvCo0031',1,1),
(1561,@OrgID, 'PrvCo0032',1,1),
(1562,@OrgID, 'PrvCo0033',1,1),
(1563,@OrgID, 'PrvCo0034',1,1),
(1564,@OrgID, 'PrvCo0035',1,1),
(1565,@OrgID, 'PrvCo0036',1,1),
(1566,@OrgID, 'PrvCo0037',1,1),
(1567,@OrgID, 'PrvCo0038',1,1),
(1568,@OrgID, 'PrvCo0039',1,1),
(1569,@OrgID, 'PrvCo0040',1,1),
(1570,@OrgID, 'PrvCo0041',1,1),
(1571,@OrgID, 'PrvCo0042',1,1),
(1572,@OrgID, 'PrvCo0043',1,1),
(1573,@OrgID, 'PrvCo0044',1,1),
(1574,@OrgID, 'PrvCo0045',1,1),
(1575,@OrgID, 'PrvCo0046',1,1),
(1576,@OrgID, 'PrvCo0047',1,1),
(1577,@OrgID, 'PrvCo0048',1,1),
(1578,@OrgID, 'PrvCo0049',1,1),
(1579,@OrgID, 'PrvCo0050',1,1),
(1580,@OrgID, 'PrvCo0051',1,1),
(1581,@OrgID, 'PrvCo0052',1,1),
(1582,@OrgID, 'PrvCo0053',1,1),
(1583,@OrgID, 'PrvCo0054',1,1),
(1584,@OrgID, 'PrvCo0055',1,1),
(1585,@OrgID, 'PrvCo0056',1,1),
(1586,@OrgID, 'PrvCo0057',1,1),
(1587,@OrgID, 'PrvCo0058',1,1),
(1588,@OrgID, 'PrvCo0059',1,1),
(1589,@OrgID, 'PrvCo0060',1,1),
(1590,@OrgID, 'PrvCo0061',1,1),
(1591,@OrgID, 'PrvCo0062',1,1),
(1592,@OrgID, 'PrvCo0063',1,1),
(1593,@OrgID, 'PrvCo0064',1,1),
(1594,@OrgID, 'PrvCo0065',1,1),
(1595,@OrgID, 'PrvCo0066',1,1),
(1596,@OrgID, 'PrvCo0067',1,1),
(1597,@OrgID, 'PrvCo0068',1,1),
(1598,@OrgID, 'PrvCo0069',1,1),
(1599,@OrgID, 'PrvCo0070',1,1),
(1600,@OrgID, 'PrvCo0071',1,1),
(1601,@OrgID, 'PrvCo0072',1,1),
(1602,@OrgID, 'PrvCo0073',1,1),
(1603,@OrgID, 'PrvCo0074',1,1),
(1604,@OrgID, 'PrvCo0075',1,1),
(1605,@OrgID, 'PrvCo0076',1,1),
(1606,@OrgID, 'PrvCo0077',1,1),
(1607,@OrgID, 'PrvCo0078',1,1),
(1608,@OrgID, 'PrvCo0079',1,1),
(1609,@OrgID, 'PrvCo0080',1,1),
(1610,@OrgID, 'PrvCo0081',1,1),
(1611,@OrgID, 'PrvCo0082',1,1),
(1612,@OrgID, 'PrvCo0083',1,1),
(1613,@OrgID, 'PrvCo0084',1,1),
(1614,@OrgID, 'PrvCo0085',1,1),
(1615,@OrgID, 'PrvCo0086',1,1),
(1616,@OrgID, 'PrvCo0087',1,1),
(1617,@OrgID, 'PrvCo0088',1,1),
(1618,@OrgID, 'PrvCo0089',1,1),
(1619,@OrgID, 'PrvCo0090',1,1),
(1620,@OrgID, 'PrvCo0091',1,1),
(1621,@OrgID, 'PrvCo0092',1,1),
(1622,@OrgID, 'PrvCo0093',1,1),
(1623,@OrgID, 'PrvCo0094',1,1),
(1624,@OrgID, 'PrvCo0095',1,1),
(1625,@OrgID, 'PrvCo0096',1,1),
(1626,@OrgID, 'PrvCo0097',1,1),
(1627,@OrgID, 'PrvCo0098',1,1),
(1628,@OrgID, 'PrvCo0099',1,1),
(1629,@OrgID, 'PrvCo0100',1,1),
(1630,@OrgID, 'PrvCo0101',1,1),
(1631,@OrgID, 'PrvCo0102',1,1),
(1632,@OrgID, 'PrvCo0103',1,1),
(1633,@OrgID, 'PrvCo0104',1,1),
(1634,@OrgID, 'PrvCo0105',1,1),
(1635,@OrgID, 'PrvCo0106',1,1),
(1636,@OrgID, 'PrvCo0107',1,1),
(1637,@OrgID, 'PrvCo0108',1,1),
(1638,@OrgID, 'PrvCo0109',1,1),
(1639,@OrgID, 'PrvCo0110',1,1),
(1640,@OrgID, 'PrvCo0111',1,1),
(1641,@OrgID, 'PrvCo0112',1,1),
(1642,@OrgID, 'PrvCo0113',1,1),
(1643,@OrgID, 'PrvCo0114',1,1),
(1644,@OrgID, 'PrvCo0115',1,1),
(1645,@OrgID, 'PrvCo0116',1,1),
(1646,@OrgID, 'PrvCo0117',1,1),
(1647,@OrgID, 'PrvCo0118',1,1),
(1648,@OrgID, 'PrvCo0119',1,1),
(1649,@OrgID, 'PrvCo0120',1,1),
(1650,@OrgID, 'PrvCo0121',1,1),
(1651,@OrgID, 'PrvCo0122',1,1),
(1652,@OrgID, 'PrvCo0123',1,1),
(1653,@OrgID, 'PrvCo0124',1,1),
(1654,@OrgID, 'PrvCo0125',1,1),
(1655,@OrgID, 'PrvCo0126',1,1),
(1656,@OrgID, 'PrvCo0127',1,1),
(1657,@OrgID, 'IPA0001',1,1),
(1658,@OrgID, 'IPA0002',1,1),
(1659,@OrgID, 'IPA0003',1,1),
(1660,@OrgID, 'IPA0004',1,1),
(1661,@OrgID, 'IPA0005',1,1),
(1662,@OrgID, 'IPA0006',1,1),
(1663,@OrgID, 'IPA0007',1,1),
(1664,@OrgID, 'IPA0008',1,1),
(1665,@OrgID, 'IPA0009',1,1),
(1666,@OrgID, 'IPA0010',1,1),
(1667,@OrgID, 'IPA0011',1,1),
(1668,@OrgID, 'IPA0012',1,1),
(1669,@OrgID, 'IPA0013',1,1),
(1670,@OrgID, 'IPA0014',1,1),
(1671,@OrgID, 'IPA0015',1,1),
(1672,@OrgID, 'IPA0016',1,1),
(1673,@OrgID, 'IPA0017',1,1),
(1674,@OrgID, 'IPA0018',1,1),
(1675,@OrgID, 'IPA0019',1,1),
(1676,@OrgID, 'IPA0021',1,1),
(1677,@OrgID, 'IPA0022',1,1),
(1678,@OrgID, 'IPA0023',1,1),
(1679,@OrgID, 'IPA0024',1,1),
(1680,@OrgID, 'IPA0025',1,1),
(1681,@OrgID, 'IPA0026',1,1),
(1682,@OrgID, 'IPA0027',1,1),
(1683,@OrgID, 'IPA0028',1,1),
(1684,@OrgID, 'PrvCo0128',1,1),
(1685,@OrgID, 'VH',1,1),
-- Added as part of tfs 53138 
(1686,@OrgID,'IPA0029',1,1),
(1687,@OrgID,'IPA0030',1,1),
(1688,@OrgID,'IPA0031',1,1),
(1689,@OrgID,'IPA0032',1,1),
(1690,@OrgID,'IPA0033',1,1),
(1691,@OrgID,'IPA0034',1,1),
(1692,@OrgID,'IPA0035',1,1),
(1693,@OrgID,'VTEDS',1,1)
;
END


SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'MVP Health Care';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(3600,@OrgID, 'VO',1, 1),
(3601,@OrgID, 'LM', 1, 1),
(3602,@OrgID, 'MATRIX', 1, 1),
(3603,@OrgID, 'MVP', 0, 1),
(3604,@OrgID, 'LANDMARK',1,1),
(3605,@OrgID,'VALUEOPTIONS',1,1),
(3606,@OrgID,'VH',1,1),
(3607,@OrgID,'TRUHEARING',1,1),
(3608,@OrgID,'OPTUM',1,1),
(3609,@OrgID,'VTEDS',1,1),
(3610,@OrgID,'HlthFdlty',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'MVP Health Care2';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(3650,@OrgID, 'VO',1, 1),
(3651,@OrgID, 'LM', 1, 1),
(3652,@OrgID, 'MATRIX', 1, 1),
(3653,@OrgID, 'MVP', 0, 1),
(3654,@OrgID, 'LANDMARK',1,1),
(3655,@OrgID,'VALUEOPTIONS',1,1),
(3656,@OrgID,'VH',1,1),
(3657,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Independent Health';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(200,@OrgID, 'INDH', 0, 1),
(201,@OrgID, 'EYEMED', 1, 1), 
(202,@OrgID, 'INOVALON', 1, 1),
(203,@OrgID, 'VH', 1, 1),
(204,@OrgID,'VTEDS',1,1),
(299,@OrgID,'DXID',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Aetna';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(300,@OrgID, 'OptumInsight',1, 1),
(301,@OrgID, 'MEDASSUR',1, 1),
(302,@OrgID, 'AET', 0, 1),
(303,@OrgID, 'C25L',1, 1),
(304,@OrgID, 'C25LAL', 1, 1),
(305,@OrgID, 'ASH', 1, 1),
(306,@OrgID, 'DNS', 1, 1),
(307,@OrgID, 'EYEMEDGHP', 1, 1),
(308,@OrgID, 'EYEMEDHA', 1, 1),
(309,@OrgID, 'HEARHA', 1, 1),
(310,@OrgID, 'HEARX', 1, 1),
(311,@OrgID, 'HRP', 1, 1),
(312,@OrgID, 'ILS', 1, 1),
(313,@OrgID, 'LCRP', 1, 1),
(314,@OrgID, 'ONS', 1, 1),
(315,@OrgID, 'OPTUM', 1, 1),
(316,@OrgID, 'PCARE', 1, 1),
(317,@OrgID, 'PODCR', 1, 1),
(318,@OrgID, 'QUES', 1, 1),
(319,@OrgID, 'QUESHP', 1, 1),
(320,@OrgID, 'SFMSC', 1, 1),
(321,@OrgID, 'SOLSTICE', 1, 1),
(322,@OrgID, 'VCI', 1, 1),
(323,@OrgID, 'AVESIS', 1, 1),
(324,@OrgID, 'CENSEO', 1, 1),
(325,@OrgID, 'ADVHLTH', 1, 1),
(326,@OrgID, 'MedSave', 1, 1),
(327,@OrgID, 'EPISOURCE', 1, 1),
(328,@OrgID, 'ION', 1, 1),
(329,@OrgID, 'Matrix', 1, 1),
(330,@OrgID, 'YHA', 1, 1),
(331,@OrgID, 'PrvCo0001',1,1),
(332,@OrgID, 'PrvCo0002',1,1),
(333,@OrgID, 'PrvCo0003',1,1),
(334,@OrgID, 'PrvCo0004',1,1),
(335,@OrgID, 'PrvCo0005',1,1),
(336,@OrgID, 'PrvCo0006',1,1),
(337,@OrgID, 'PrvCo0007',1,1),
(338,@OrgID, 'PrvCo0008',1,1),
(339,@OrgID, 'PrvCo0009',1,1),
(340,@OrgID, 'PrvCo0010',1,1),
(341,@OrgID, 'PrvCo0011',1,1),
(342,@OrgID, 'PrvCo0012',1,1),
(343,@OrgID, 'PrvCo0013',1,1),
(344,@OrgID, 'PrvCo0014',1,1),
(345,@OrgID, 'PrvCo0015',1,1),
(346,@OrgID, 'PrvCo0016',1,1),
(347,@OrgID, 'PrvCo0017',1,1),
(348,@OrgID, 'PrvCo0018',1,1),
(349,@OrgID, 'PrvCo0019',1,1),
(350,@OrgID, 'PrvCo0020',1,1),
(351,@OrgID, 'PrvCo0021',1,1),
(352,@OrgID, 'PrvCo0022',1,1),
(353,@OrgID, 'PrvCo0023',1,1),
(354,@OrgID, 'PrvCo0024',1,1),
(355,@OrgID, 'PrvCo0025',1,1),
(356,@OrgID, 'PrvCo0026',1,1),
(357,@OrgID, 'PrvCo0027',1,1),
(358,@OrgID, 'PrvCo0028',1,1),
(359,@OrgID, 'PrvCo0029',1,1),
(360,@OrgID, 'PrvCo0030',1,1),
(361,@OrgID, 'PrvCo0031',1,1),
(362,@OrgID, 'PrvCo0032',1,1),
(363,@OrgID, 'PrvCo0033',1,1),
(364,@OrgID, 'PrvCo0034',1,1),
(365,@OrgID, 'PrvCo0035',1,1),
(366,@OrgID, 'PrvCo0036',1,1),
(367,@OrgID, 'PrvCo0037',1,1),
(368,@OrgID, 'PrvCo0038',1,1),
(369,@OrgID, 'PrvCo0039',1,1),
(370,@OrgID, 'PrvCo0040',1,1),
(371,@OrgID, 'PrvCo0041',1,1),
(372,@OrgID, 'PrvCo0042',1,1),
(373,@OrgID, 'PrvCo0043',1,1),
(374,@OrgID, 'PrvCo0044',1,1),
(375,@OrgID, 'PrvCo0045',1,1),
(376,@OrgID, 'PrvCo0046',1,1),
(377,@OrgID, 'PrvCo0047',1,1),
(378,@OrgID, 'PrvCo0048',1,1),
(379,@OrgID, 'PrvCo0049',1,1),
(380,@OrgID, 'PrvCo0050',1,1),
(381,@OrgID, 'PrvCo0051',1,1),
(382,@OrgID, 'PrvCo0052',1,1),
(383,@OrgID, 'PrvCo0053',1,1),
(384,@OrgID, 'PrvCo0054',1,1),
(385,@OrgID, 'PrvCo0055',1,1),
(386,@OrgID, 'PrvCo0056',1,1),
(387,@OrgID, 'PrvCo0057',1,1),
(388,@OrgID, 'PrvCo0058',1,1),
(389,@OrgID, 'PrvCo0059',1,1),
(390,@OrgID, 'PrvCo0060',1,1),
(391,@OrgID, 'PrvCo0061',1,1),
(392,@OrgID, 'PrvCo0062',1,1),
(393,@OrgID, 'PrvCo0063',1,1),
(394,@OrgID, 'PrvCo0064',1,1),
(395,@OrgID, 'PrvCo0065',1,1),
(396,@OrgID, 'PrvCo0066',1,1),
(397,@OrgID, 'PrvCo0067',1,1),
(398,@OrgID, 'PrvCo0068',1,1),
(399,@OrgID, 'PrvCo0069',1,1),
(400,@OrgID, 'PrvCo0070',1,1),
(401,@OrgID, 'PrvCo0071',1,1),
(402,@OrgID, 'PrvCo0072',1,1),
(403,@OrgID, 'PrvCo0073',1,1),
(404,@OrgID, 'PrvCo0074',1,1),
(405,@OrgID, 'PrvCo0075',1,1),
(406,@OrgID, 'PrvCo0076',1,1),
(407,@OrgID, 'PrvCo0077',1,1),
(408,@OrgID, 'PrvCo0078',1,1),
(409,@OrgID, 'PrvCo0079',1,1),
(410,@OrgID, 'PrvCo0080',1,1),
(411,@OrgID, 'PrvCo0081',1,1),
(412,@OrgID, 'PrvCo0082',1,1),
(413,@OrgID, 'PrvCo0083',1,1),
(414,@OrgID, 'PrvCo0084',1,1),
(415,@OrgID, 'PrvCo0085',1,1),
(416,@OrgID, 'PrvCo0086',1,1),
(417,@OrgID, 'PrvCo0087',1,1),
(418,@OrgID, 'PrvCo0088',1,1),
(419,@OrgID, 'PrvCo0089',1,1),
(420,@OrgID, 'PrvCo0090',1,1),
(421,@OrgID, 'PrvCo0091',1,1),
(422,@OrgID, 'PrvCo0092',1,1),
(423,@OrgID, 'PrvCo0093',1,1),
(424,@OrgID, 'PrvCo0094',1,1),
(425,@OrgID, 'PrvCo0095',1,1),
(426,@OrgID, 'PrvCo0096',1,1),
(427,@OrgID, 'PrvCo0097',1,1),
(428,@OrgID, 'PrvCo0098',1,1),
(429,@OrgID, 'PrvCo0099',1,1),
(430,@OrgID, 'PrvCo0100',1,1),
(431,@OrgID, 'PrvCo0101',1,1),
(432,@OrgID, 'PrvCo0102',1,1),
(433,@OrgID, 'PrvCo0103',1,1),
(434,@OrgID, 'PrvCo0104',1,1),
(435,@OrgID, 'PrvCo0105',1,1),
(436,@OrgID, 'PrvCo0106',1,1),
(437,@OrgID, 'PrvCo0107',1,1),
(438,@OrgID, 'PrvCo0108',1,1),
(439,@OrgID, 'PrvCo0109',1,1),
(440,@OrgID, 'PrvCo0110',1,1),
(441,@OrgID, 'PrvCo0111',1,1),
(442,@OrgID, 'PrvCo0112',1,1),
(443,@OrgID, 'PrvCo0113',1,1),
(444,@OrgID, 'PrvCo0114',1,1),
(445,@OrgID, 'PrvCo0115',1,1),
(446,@OrgID, 'PrvCo0116',1,1),
(447,@OrgID, 'PrvCo0117',1,1),
(448,@OrgID, 'PrvCo0118',1,1),
(449,@OrgID, 'PrvCo0119',1,1),
(450,@OrgID, 'PrvCo0120',1,1),
(451,@OrgID, 'PrvCo0121',1,1),
(452,@OrgID, 'PrvCo0122',1,1),
(453,@OrgID, 'PrvCo0123',1,1),
(454,@OrgID, 'PrvCo0124',1,1),
(455,@OrgID, 'PrvCo0125',1,1),
(456,@OrgID, 'PrvCo0126',1,1),
(457,@OrgID, 'PrvCo0127',1,1),
(458,@OrgID, 'IPA0001',1,1),
(459,@OrgID, 'IPA0002',1,1),
(460,@OrgID, 'IPA0003',1,1),
(461,@OrgID, 'IPA0004',1,1),
(462,@OrgID, 'IPA0005',1,1),
(463,@OrgID, 'IPA0006',1,1),
(464,@OrgID, 'IPA0007',1,1),
(465,@OrgID, 'IPA0008',1,1),
(466,@OrgID, 'IPA0009',1,1),
(467,@OrgID, 'IPA0010',1,1),
(468,@OrgID, 'IPA0011',1,1),
(469,@OrgID, 'IPA0012',1,1),
(470,@OrgID, 'IPA0013',1,1),
(471,@OrgID, 'IPA0014',1,1),
(472,@OrgID, 'IPA0015',1,1),
(473,@OrgID, 'IPA0016',1,1),
(474,@OrgID, 'IPA0017',1,1),
(475,@OrgID, 'IPA0018',1,1),
(476,@OrgID, 'IPA0019',1,1),
(477,@OrgID, 'IPA0021',1,1),
(478,@OrgID, 'IPA0022',1,1),
(479,@OrgID, 'IPA0023',1,1),
(480,@OrgID, 'IPA0024',1,1),
(481,@OrgID, 'IPA0025',1,1),
(482,@OrgID, 'IPA0026',1,1),
(483,@OrgID, 'IPA0027',1,1),
(484,@OrgID, 'IPA0028',1,1),
(485,@OrgID, 'PrvCo0128',1,1),
(486,@OrgID, 'VH',1,1),
-- Added as part of tfs 53138 
(487,@OrgID,'IPA0029',1,1),
(488,@OrgID,'IPA0030',1,1),
(489,@OrgID,'IPA0031',1,1),
(490,@OrgID,'IPA0032',1,1),
(491,@OrgID,'IPA0033',1,1),
(492,@OrgID,'IPA0034',1,1),
(493,@OrgID,'IPA0035',1,1),
(494,@OrgID,'TRNSUN', 1,1),
(495,@OrgID,'PrvCo0130',1,1),
(496,@OrgID,'VTEDS',1,1),
--added as tfs 56885
(504,@OrgID,'CHC0001',1,1),
(505,@OrgID,'CHC0002',1,1),
(506,@OrgID,'CHC0003',1,1),
(507,@OrgID,'CHC0004',1,1),
(508,@OrgID,'CHC0005',1,1),
(509,@OrgID,'CHC0006',1,1),
(510,@OrgID,'CHC0007',1,1),
(511,@OrgID,'CHC0008',1,1),
(512,@OrgID,'CHC0009',1,1),
(513,@OrgID,'CHC0010',1,1),
(514,@OrgID,'CHC0011',1,1),
(515,@OrgID,'CHC0012',1,1),
(516,@OrgID,'CHC0013',1,1),
(517,@OrgID,'CHC0014',1,1),
(518,@OrgID,'CHC0015',1,1),
(519,@OrgID,'CHC0016',1,1),
(520,@OrgID,'CHC0017',1,1),
(521,@OrgID,'APIXIO',1,1),
--Added as tfs 61250
(522,@OrgID,'PrvCo0129',1,1)
;
END


SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Aetna2';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(3000,@OrgID, 'OptumInsight',1, 1),
(3001,@OrgID, 'MEDASSUR',1, 1),
(3002,@OrgID, 'AET', 0, 1),
(3003,@OrgID, 'C25L',1, 1),
(3004,@OrgID, 'C25LAL', 1, 1),
(3005,@OrgID, 'ASH', 1, 1),
(3006,@OrgID, 'DNS', 1, 1),
(3007,@OrgID, 'EYEMEDGHP', 1, 1),
(3008,@OrgID, 'EYEMEDHA', 1, 1),
(3009,@OrgID, 'HEARHA', 1, 1),
(3010,@OrgID, 'HEARX', 1, 1),
(3011,@OrgID, 'HRP', 1, 1),
(3012,@OrgID, 'ILS', 1, 1),
(3013,@OrgID, 'LCRP', 1, 1),
(3014,@OrgID, 'ONS', 1, 1),
(3015,@OrgID, 'OPTUM', 1, 1),
(3016,@OrgID, 'PCARE', 1, 1),
(3017,@OrgID, 'PODCR', 1, 1),
(3018,@OrgID, 'QUES', 1, 1),
(3019,@OrgID, 'QUESHP', 1, 1),
(3020,@OrgID, 'SFMSC', 1, 1),
(3021,@OrgID, 'SOLSTICE', 1, 1),
(3022,@OrgID, 'VCI', 1, 1),
(3023,@OrgID, 'AVESIS', 1, 1),
(3024,@OrgID, 'CENSEO', 1, 1),
(3025,@OrgID, 'ADVHLTH', 1, 1),
(3026,@OrgID, 'MedSave', 1, 1),
(3027,@OrgID, 'EPISOURCE', 1, 1),
(3028,@OrgID, 'ION', 1, 1),
(3029,@OrgID, 'Matrix', 1, 1),
(3030,@OrgID, 'YHA', 1, 1),
(3031,@OrgID, 'PrvCo0001',1,1),
(3032,@OrgID, 'PrvCo0002',1,1),
(3033,@OrgID, 'PrvCo0003',1,1),
(3034,@OrgID, 'PrvCo0004',1,1),
(3035,@OrgID, 'PrvCo0005',1,1),
(3036,@OrgID, 'PrvCo0006',1,1),
(3037,@OrgID, 'PrvCo0007',1,1),
(3038,@OrgID, 'PrvCo0008',1,1),
(3039,@OrgID, 'PrvCo0009',1,1),
(3040,@OrgID, 'PrvCo0010',1,1),
(3041,@OrgID, 'PrvCo0011',1,1),
(3042,@OrgID, 'PrvCo0012',1,1),
(3043,@OrgID, 'PrvCo0013',1,1),
(3044,@OrgID, 'PrvCo0014',1,1),
(3045,@OrgID, 'PrvCo0015',1,1),
(3046,@OrgID, 'PrvCo0016',1,1),
(3047,@OrgID, 'PrvCo0017',1,1),
(3048,@OrgID, 'PrvCo0018',1,1),
(3049,@OrgID, 'PrvCo0019',1,1),
(3050,@OrgID, 'PrvCo0020',1,1),
(3051,@OrgID, 'PrvCo0021',1,1),
(3052,@OrgID, 'PrvCo0022',1,1),
(3053,@OrgID, 'PrvCo0023',1,1),
(3054,@OrgID, 'PrvCo0024',1,1),
(3055,@OrgID, 'PrvCo0025',1,1),
(3056,@OrgID, 'PrvCo0026',1,1),
(3057,@OrgID, 'PrvCo0027',1,1),
(3058,@OrgID, 'PrvCo0028',1,1),
(3059,@OrgID, 'PrvCo0029',1,1),
(3060,@OrgID, 'PrvCo0030',1,1),
(3061,@OrgID, 'PrvCo0031',1,1),
(3062,@OrgID, 'PrvCo0032',1,1),
(3063,@OrgID, 'PrvCo0033',1,1),
(3064,@OrgID, 'PrvCo0034',1,1),
(3065,@OrgID, 'PrvCo0035',1,1),
(3066,@OrgID, 'PrvCo0036',1,1),
(3067,@OrgID, 'PrvCo0037',1,1),
(3068,@OrgID, 'PrvCo0038',1,1),
(3069,@OrgID, 'PrvCo0039',1,1),
(3070,@OrgID, 'PrvCo0040',1,1),
(3071,@OrgID, 'PrvCo0041',1,1),
(3072,@OrgID, 'PrvCo0042',1,1),
(3073,@OrgID, 'PrvCo0043',1,1),
(3074,@OrgID, 'PrvCo0044',1,1),
(3075,@OrgID, 'PrvCo0045',1,1),
(3076,@OrgID, 'PrvCo0046',1,1),
(3077,@OrgID, 'PrvCo0047',1,1),
(3078,@OrgID, 'PrvCo0048',1,1),
(3079,@OrgID, 'PrvCo0049',1,1),
(3080,@OrgID, 'PrvCo0050',1,1),
(3081,@OrgID, 'PrvCo0051',1,1),
(3082,@OrgID, 'PrvCo0052',1,1),
(3083,@OrgID, 'PrvCo0053',1,1),
(3084,@OrgID, 'PrvCo0054',1,1),
(3085,@OrgID, 'PrvCo0055',1,1),
(3086,@OrgID, 'PrvCo0056',1,1),
(3087,@OrgID, 'PrvCo0057',1,1),
(3088,@OrgID, 'PrvCo0058',1,1),
(3089,@OrgID, 'PrvCo0059',1,1),
(3090,@OrgID, 'PrvCo0060',1,1),
(3091,@OrgID, 'PrvCo0061',1,1),
(3092,@OrgID, 'PrvCo0062',1,1),
(3093,@OrgID, 'PrvCo0063',1,1),
(3094,@OrgID, 'PrvCo0064',1,1),
(3095,@OrgID, 'PrvCo0065',1,1),
(3096,@OrgID, 'PrvCo0066',1,1),
(3097,@OrgID, 'PrvCo0067',1,1),
(3098,@OrgID, 'PrvCo0068',1,1),
(3099,@OrgID, 'PrvCo0069',1,1),
(3100,@OrgID, 'PrvCo0070',1,1),
(3101,@OrgID, 'PrvCo0071',1,1),
(3102,@OrgID, 'PrvCo0072',1,1),
(3103,@OrgID, 'PrvCo0073',1,1),
(3104,@OrgID, 'PrvCo0074',1,1),
(3105,@OrgID, 'PrvCo0075',1,1),
(3106,@OrgID, 'PrvCo0076',1,1),
(3107,@OrgID, 'PrvCo0077',1,1),
(3108,@OrgID, 'PrvCo0078',1,1),
(3109,@OrgID, 'PrvCo0079',1,1),
(3110,@OrgID, 'PrvCo0080',1,1),
(3111,@OrgID, 'PrvCo0081',1,1),
(3112,@OrgID, 'PrvCo0082',1,1),
(3113,@OrgID, 'PrvCo0083',1,1),
(3114,@OrgID, 'PrvCo0084',1,1),
(3115,@OrgID, 'PrvCo0085',1,1),
(3116,@OrgID, 'PrvCo0086',1,1),
(3117,@OrgID, 'PrvCo0087',1,1),
(3118,@OrgID, 'PrvCo0088',1,1),
(3119,@OrgID, 'PrvCo0089',1,1),
(3120,@OrgID, 'PrvCo0090',1,1),
(3121,@OrgID, 'PrvCo0091',1,1),
(3122,@OrgID, 'PrvCo0092',1,1),
(3123,@OrgID, 'PrvCo0093',1,1),
(3124,@OrgID, 'PrvCo0094',1,1),
(3125,@OrgID, 'PrvCo0095',1,1),
(3126,@OrgID, 'PrvCo0096',1,1),
(3127,@OrgID, 'PrvCo0097',1,1),
(3128,@OrgID, 'PrvCo0098',1,1),
(3129,@OrgID, 'PrvCo0099',1,1),
(3130,@OrgID, 'PrvCo0100',1,1),
(3131,@OrgID, 'PrvCo0101',1,1),
(3132,@OrgID, 'PrvCo0102',1,1),
(3133,@OrgID, 'PrvCo0103',1,1),
(3134,@OrgID, 'PrvCo0104',1,1),
(3135,@OrgID, 'PrvCo0105',1,1),
(3136,@OrgID, 'PrvCo0106',1,1),
(3137,@OrgID, 'PrvCo0107',1,1),
(3138,@OrgID, 'PrvCo0108',1,1),
(3139,@OrgID, 'PrvCo0109',1,1),
(3140,@OrgID, 'PrvCo0110',1,1),
(3141,@OrgID, 'PrvCo0111',1,1),
(3142,@OrgID, 'PrvCo0112',1,1),
(3143,@OrgID, 'PrvCo0113',1,1),
(3144,@OrgID, 'PrvCo0114',1,1),
(3145,@OrgID, 'PrvCo0115',1,1),
(3146,@OrgID, 'PrvCo0116',1,1),
(3147,@OrgID, 'PrvCo0117',1,1),
(3148,@OrgID, 'PrvCo0118',1,1),
(3149,@OrgID, 'PrvCo0119',1,1),
(3150,@OrgID, 'PrvCo0120',1,1),
(3151,@OrgID, 'PrvCo0121',1,1),
(3152,@OrgID, 'PrvCo0122',1,1),
(3153,@OrgID, 'PrvCo0123',1,1),
(3154,@OrgID, 'PrvCo0124',1,1),
(3155,@OrgID, 'PrvCo0125',1,1),
(3156,@OrgID, 'PrvCo0126',1,1),
(3157,@OrgID, 'PrvCo0127',1,1),
(3158,@OrgID, 'IPA0001',1,1),
(3159,@OrgID, 'IPA0002',1,1),
(3160,@OrgID, 'IPA0003',1,1),
(3161,@OrgID, 'IPA0004',1,1),
(3162,@OrgID, 'IPA0005',1,1),
(3163,@OrgID, 'IPA0006',1,1),
(3164,@OrgID, 'IPA0007',1,1),
(3165,@OrgID, 'IPA0008',1,1),
(3166,@OrgID, 'IPA0009',1,1),
(3167,@OrgID, 'IPA0010',1,1),
(3168,@OrgID, 'IPA0011',1,1),
(3169,@OrgID, 'IPA0012',1,1),
(3170,@OrgID, 'IPA0013',1,1),
(3171,@OrgID, 'IPA0014',1,1),
(3172,@OrgID, 'IPA0015',1,1),
(3173,@OrgID, 'IPA0016',1,1),
(3174,@OrgID, 'IPA0017',1,1),
(3175,@OrgID, 'IPA0018',1,1),
(3176,@OrgID, 'IPA0019',1,1),
(3177,@OrgID, 'IPA0021',1,1),
(3178,@OrgID, 'IPA0022',1,1),
(3179,@OrgID, 'IPA0023',1,1),
(3180,@OrgID, 'IPA0024',1,1),
(3181,@OrgID, 'IPA0025',1,1),
(3182,@OrgID, 'IPA0026',1,1),
(3183,@OrgID, 'IPA0027',1,1),
(3184,@OrgID, 'IPA0028',1,1),
(3185,@OrgID, 'PrvCo0128',1,1),
(3186,@OrgID, 'VH',1,1),
-- Added as part of tfs 53138 
(3187,@OrgID,'IPA0029',1,1),
(3188,@OrgID,'IPA0030',1,1),
(3189,@OrgID,'IPA0031',1,1),
(3190,@OrgID,'IPA0032',1,1),
(3191,@OrgID,'IPA0033',1,1),
(3192,@OrgID,'IPA0034',1,1),
(3193,@OrgID,'IPA0035',1,1),
(3194,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Health First Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(4000,@OrgID, 'HFHP',0, 1),
(4001,@OrgID, 'CN',1, 1),
(4002,@OrgID, 'VH',1, 1),
(4003,@OrgID, 'Magellan',1, 1),
(4004,@OrgID, 'ESI',1, 1),
(4005,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Lovelace';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(500,@OrgID, 'LOVE', 0, 1),
(501,@OrgID, 'TRIZETTO', 1, 1),
(502,@OrgID, 'VH', 1, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Presbyterian Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(600,@OrgID, 'PHP', 0, 1),
--TFS32366
(602,@OrgID, 'YHA', 1, 1),
(603,@OrgID, 'MDX', 1, 1),
(604,@OrgID, 'VH', 1, 1),
(605,@OrgID,'VTEDS',1,1)

END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Humana';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values

(650,@OrgID, 'HUM', 0, 1),
(651,@OrgID, 'HMDC', 1, 1),
(652,@OrgID, 'VH', 1, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Health Spring';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(700,@OrgID, 'HSPR', 0, 1),
(701,@OrgID, 'BIDW-MHC',1, 1),
(702,@OrgID, 'BIDW-QNXT',1, 1),
(703,@OrgID, 'BIDW-FACETS', 1, 1),
(704,@OrgID, 'VH', 1, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Scott and White Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(800,@OrgID, 'SWHP', 0, 1),
(801,@OrgID, 'BLOCK', 1, 1),
(802,@OrgID, 'ASH', 1, 1),
(804,@OrgID, 'ARGUS', 1, 1),
(805,@OrgID, 'CN', 1, 1),
(806,@OrgID, 'VH', 1, 1),
(807,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'The Regence Group';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values

(900,@OrgID, 'RGNC', 0, 1),
(901,@OrgID, 'VSP', 1, 1),
(902,@OrgID, 'VH', 1, 1),
(903,@OrgID,'VTEDS',1,1),
(904,@OrgID,'CAMBIAM',1,1),
(905,@OrgID,'CAMBIAN',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'The Regence Group2';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values

(950,@OrgID, 'RGNC', 0, 1),
(951,@OrgID, 'VSP', 1, 1),
(952,@OrgID, 'VH', 1, 1),
(953,@OrgID,'VTEDS',1,1)

;
END


SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name in ('Health Plan of New England (Demo)', 'New England Health');

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode,VendorFlag, Active)
values
(1000,@OrgID, 'DEMO', 0, 1),
(1001,@OrgID, 'VENDR', 1, 1),
(1002,@OrgID, 'VENDC', 1, 1),
(1003,@OrgID, 'VH', 1, 1),
(1004,@OrgID,'VTEDS',1,1)

;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Training 1';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1100,@OrgID, 'TRN1',0, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Training 2';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1101,@OrgID, 'TRN2', 0, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Training 3';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1102,@OrgID, 'TRN3', 0, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Training 4';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1103,@OrgID, 'TRN4', 0, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Plynt';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1104,@OrgID, 'PLYNT', 0, 1),
(1105,@OrgID, 'VH', 1, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Independence Blue Cross';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1200,@OrgID, 'IBC', 0,1), 
(1201,@OrgID, 'AMERIHEALTH', 0,1),
(1202,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Health Net';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1300,@OrgID, 'HNET', 0,1), 
(1301,@OrgID, 'MHN', 1, 1),
(1302,@OrgID, 'VH', 1, 1),
(1303,@OrgID, 'VSP', 1, 1),
(1304,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Blue Cross and Blue Shield of TN';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1400,@OrgID, 'BCBSTN', 0,1),
(1401,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Molina';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1500,@OrgID, 'MOL', 0,1)
,(1702,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Highmark';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1750,@OrgID, 'HIGH', 0,1),
(1751,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'MCS';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1700,@OrgID, 'MCS', 0,1),
(1701,@OrgID, 'VH', 1,1),
(1703,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'VIVA Health';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1800,@OrgID, 'VIVA', 0,1),
(1801,@OrgID, 'VH', 1,1),
(1802,@OrgID,'VTEDS',1,1)

;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Health Alliance Medical Plans';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(1900,@OrgID, 'HAMP', 0,1),
--TFS28460 06/25/2014
(1901,@OrgID, 'CATAMARAN', 1,1),
(1902,@OrgID, 'CN', 1,1),
(1903,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'CCHP';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2000,@OrgID, 'CCHP', 0,1),
--TFS28748 6/25/2014
(2001,@OrgID, 'APIXIO', 1,1),
(2002,@OrgID, 'CENSEO', 1,1),
(2003,@OrgID, 'VSP', 1,1),
(2004,@OrgID, 'CGSHT', 1,1),
(2005,@OrgID, 'VH', 1,1),
(2006,@OrgID,'VTEDS',1,1),
(2007,@OrgID,'NextGen',1,1),
(2008,@OrgID,'HealthFid',1,1)
;
END

--TFS31385 09/19/2014

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'HCSC';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2100,@OrgID, 'HCSC', 0,1),
(2101,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Rocky Mountain Health Plans Foundation';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2200,@OrgID, 'RMHP', 0,1),
(2201,@OrgID, 'CN', 1,1),
(2202,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'CoreSource';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2300,@OrgID, 'CORE', 0,1),
(2301,@OrgID, 'CN', 1,1),
(2302,@OrgID, 'VH', 1,1)
;
END

 SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Trustmark';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2400,@OrgID, 'TMRK', 0,1),
(2401,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Community Health Choice';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2500,@OrgID, 'CHC', 0,1),
(2501,@OrgID, 'CN', 1,1),
(2502,@OrgID,'Beacon',0,1),
(2503,@OrgID,'Kelsey',0,1),
(2504,@OrgID,'VH',1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'CareSource';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2600,@OrgID, 'CSRC', 0,1),
(2601,@OrgID, 'CN', 1,1),
(2602,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'BCBS AZ';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2700,@OrgID, 'BCBSAZ', 0,1),
(2701,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'BCBSMI PPO';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2750,@OrgID, 'BCBSMIPPO', 0,1),
(2751,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'BCBS KC';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2800,@OrgID, 'BCBSKC', 0,1),
(2801,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'BCBSMI HMO';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2850,@OrgID, 'BCBSMIHMO', 0,1),
(2851,@OrgID, 'CH', 1,1),
(2852,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'BCBS Horizon';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(2900,@OrgID, 'BCBSHRZ', 0,1),
(2901,@OrgID, 'CH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'CGHC';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(3300,@OrgID, 'CGHC', 0,1),
(3301,@OrgID, 'CN', 1,1),
(3302,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'INHMOH';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(3400,@OrgID, 'INHMOH', 0,1),
(3401,@OrgID, 'CN', 1,1),
(3402,@OrgID, 'VH', 1,1)
;
END

SET @OrgID = NULL;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Wellpoint';

IF @OrgID IS NOT NULL
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
VALUES
(3500,@OrgID, 'WELLPT', 0,1),
(3501,@OrgID, 'VH', 1,1)
;
END


SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Sanford Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(4200,@OrgID, 'SNFHP',0, 1),
(4201,@OrgID, 'VH',1, 1),
(4202,@OrgID,'VTEDS',1,1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Neighborhood Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(4300,@OrgID, 'NHP',0, 1),
(4301,@OrgID, 'VH',1, 1)

;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Samaritan Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6200 ,@OrgID, 'SAMHP',0, 1),
(6201 ,@OrgID, 'VH',1, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Universal American';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6300 ,@OrgID, 'UAM',0, 1),
(6303 ,@OrgID, 'APS',1, 1),
(6304 ,@OrgID, 'CAREington',1, 1),
(6305 ,@OrgID, 'EyeMed',1, 1),
(6306 ,@OrgID, 'Kelsey',1, 1),
(6307 ,@OrgID, 'MCA',1, 1),
(6308 ,@OrgID, 'MHAP',1, 1),
(6309 ,@OrgID, 'NWDC',1, 1),
(6310 ,@OrgID, 'SETMA',1, 1),
(6311 ,@OrgID, 'VFP',1, 1),
(6312 ,@OrgID, 'EPISource',1, 1),
(6313 ,@OrgID, 'Outcomes',1, 1),
(6314 ,@OrgID, 'RecordFlow',1, 1),
(6315 ,@OrgID, 'EMSI',1, 1),
(6316 ,@OrgID, 'PEAK',1, 1),
(6317 ,@OrgID, 'Censeo',1, 1),
(6318 ,@OrgID, 'QuestLabs',1, 1),
(6319 ,@OrgID, 'CVS',1, 1),
(6320 ,@OrgID, 'CMS',1, 1),
(6321 ,@OrgID, 'Optum',1, 1),
(6322 ,@OrgID, 'Altegra',1, 1),
(6323 ,@OrgID, 'Passport',1, 1),
(6324 ,@OrgID, 'LabCorp',1, 1),
(6325 ,@OrgID, 'DDDS',1, 1),
(6326 ,@OrgID, 'Aspire',1, 1),
(6327 ,@OrgID, 'Millenium',1, 1),
(6328 ,@OrgID, 'TC',1, 1),
(6329 ,@OrgID, 'Verisk',1, 1),
(6330 ,@OrgID, 'Intercede',1, 1),
(6331 ,@OrgID, 'LACNY',1, 1),
(6332 ,@OrgID, 'CRISP',1, 1),
(6333 ,@OrgID, 'Conversio',1, 1),
(6334 ,@OrgID, 'FACETS',1, 1),
(6335,@OrgID,'VTEDS',1,1)

;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'VNSNY';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6301 ,@OrgID, 'VNSNY',0, 1),
(6302 ,@OrgID, 'VH',1, 1)
;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Federated Mutual Insurance';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6400,@OrgID, 'FMI',1, 1)

;
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Neighborhood Health Plan CRA';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6500,@OrgID, 'NHPCRA',1, 1);
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Oscar Health Insurance';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6600,@OrgID, 'OSCR',1, 1);
END

SET @OrgID = null;
SELECT @OrgID = OrganizationID
FROM dbo.Organization o
WHERE o.Name = 'Vantage Health Plan';

if @OrgID is not null
BEGIN
INSERT INTO dbo.OrganizationVendor(OrganizationVendorID, OrganizationID, VendorCode, VendorFlag, Active)
values
(6700,@OrgID, 'VHP',0, 1),
(6701,@OrgID, 'CGHST',1, 1),
(6702,@OrgID, 'EMSI',1, 1);
END


SET IDENTITY_INSERT [dbo].OrganizationVendor OFF;
GO

COMMIT TRANSACTION;
go
