DECLARE @FilePath VARCHAR(255),
@SSISPath VARCHAR(255) = '\HRP\Reporting\HIM\EdgeReports\'

DECLARE @XSDPath VARCHAR(50) = 'XSD\ReportsXSD\'

IF @@SERVERNAME like 'HRPDB001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\PRD\'
END
ELSE IF @@SERVERNAME like 'HRPSTGDB001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\UAT\'
END
ELSE IF @@SERVERNAME like 'HRPINTDBS001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\INT\'
END
ELSE IF @@SERVERNAME like 'HRPDEVRPT01'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\DEV\RPTDEV1\'
END
ELSE IF @@SERVERNAME like 'HRPDEVRPT02'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\DEV\RPTDEV2\'
END

MERGE dbo.[EdgeReportConfiguration] AS target
USING (
		-- RATEE
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RATransferElementsExtract.dtsx' 'ConfigurationValue' , 
				'RATEE' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RATEE\RATransferReport.xsd' 'ConfigurationValue', 
				'RATEE' 'ReportType'

		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RATEE\RATransferReportRoot.xsd' 'ConfigurationValue', 
				'RATEE' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RATEE\RATEERootStyleSheet.xslt' 'ConfigurationValue', 
				'RATEE' 'ReportType'

		-- RARSS
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RARiskScoreSummary.dtsx' 'ConfigurationValue' , 
				'RARSS' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RARSS\RiskScoreSummaryReport.xsd' 'ConfigurationValue', 
				'RARSS' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RARSS\RiskScoreSummaryReportRootGeneratedWithDataType.xsd' 'ConfigurationValue', 
				'RARSS' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RARSS\RiskScoreSummaryRootStyleSheet.xslt' 'ConfigurationValue', 
				'RARSS' 'ReportType'

		-- RARSD
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RARiskScoreDetail.dtsx' 'ConfigurationValue' , 
				'RARSD' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RARSD\RiskScoreDetailReport.xsd' 'ConfigurationValue', 
				'RARSD' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RARSD\RiskScoreDetailReportRootGeneratedWithDataType.xsd' 'ConfigurationValue', 
				'RARSD' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RARSD\RiskScoreDetailRootStyleSheet.xslt' 'ConfigurationValue', 
				'RARSD' 'ReportType'

		-- RACSS
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				 'Load_HIMRA_EdgeReport_RAClaimSelectionSummary.dtsx' 'ConfigurationValue' , 
				'RACSS' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RACSS\ClaimSelectionSummaryReport.xsd' 'ConfigurationValue', 
				'RACSS' 'ReportType'

		-- RACSD
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RAClaimSelectionDetail.dtsx' 'ConfigurationValue' , 
				'RACSD' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RACSD\ClaimSelectionDetailReport.xsd' 'ConfigurationValue', 
				'RACSD' 'ReportType'
		-- RISR
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RISummary.dtsx' 'ConfigurationValue' , 
				'RISR' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RISR\RISummaryReport.xsd' 'ConfigurationValue', 
				'RISR' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RISR\ReInsuranceSummaryReportRootFileWithDataType.xsd' 'ConfigurationValue', 
				'RISR' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RISR\ReInsuranceSummaryReportRoot.xslt' 'ConfigurationValue', 
				'RISR' 'ReportType'
				
		-- RIDE
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
			'Load_HIMRA_EdgeReport_RIDetail.dtsx' 'ConfigurationValue' , 
				'RIDE' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RIDE\RIDetailEnrolleeReport.xsd' 'ConfigurationValue', 
				'RIDE' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RIDE\ReInsuranceDetailReportRootFileWithDataType.xsd' 'ConfigurationValue', 
				'RIDE' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RIDE\ReInsuranceDetailReportRoot.xslt' 'ConfigurationValue', 
				'RIDE' 'ReportType'
		-- HRRP
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_HCRPDetail.dtsx' 'ConfigurationValue' , 
				'HCRP' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'HCRP\HCRPDetailReport.xsd' 'ConfigurationValue', 
				'HCRP' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'HCRP\HCRPDetailReportRootWithDataType.xsd' 'ConfigurationValue', 
				'HCRP' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'HCRP\HCRPDetailReportRoot.xslt' 'ConfigurationValue', 
				'HCRP' 'ReportType'
	   -- ECD
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
			'Load_HIMRA_EdgeReport_ECDetail.dtsx' 'ConfigurationValue' , 
				'ECD' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'ECD\EnrolleeClaimsWithWithoutDetailReport.xsd' 'ConfigurationValue', 
				'ECD' 'ReportType'

		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'ECD\EnrolleeWithoutClaimsDetailROOT.xsd' 'ConfigurationValue', 
				'ECD' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'ECD\ECDRootStyleSheet.xslt' 'ConfigurationValue', 
				'ECD' 'ReportType'
		-- RADVPS
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RADVPSummary.dtsx' 'ConfigurationValue' , 
				'RADVPS' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RADVPS\radvPopulationSummaryStatistics.xsd' 'ConfigurationValue', 
				'RADVPS' 'ReportType'

		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RADVPS\RADVPopulationSummaryStatisticsReportRoot.xsd' 'ConfigurationValue', 
				'RADVPS' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RADVPS\radvPopulationSummaryStatisticsRootStyleSheet.xslt' 'ConfigurationValue', 
				'RADVPS' 'ReportType'
				
		-- RAPHCCER
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RAPHCCERDetail.dtsx' 'ConfigurationValue' , 
				'RAPHCCER' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition', 
				@FilePath + @XSDPath + 'RAPHCCER\RAPaymentHCCEnrolleeReport.xsd' 'ConfigurationValue', 
				'RAPHCCER' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RAPHCCER\RAPaymentHCCEnrolleeReportRoot.xsd' 'ConfigurationValue', 
				'RAPHCCER' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RAPHCCER\RAPHCCERRootStyleSheet.xslt' 'ConfigurationValue', 
				'RAPHCCER' 'ReportType'	
		-- RAUF
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RAUserFee.dtsx' 'ConfigurationValue' , 
				'RAUF' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RAUF\RaUserFeeReport.xsd' 'ConfigurationValue', 
				'RAUF' 'ReportType'

		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RAUF\RAUserFeeReportRoot.xsd' 'ConfigurationValue', 
				'RAUF' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RAUF\RAUserFeeRootStyleSheet.xslt' 'ConfigurationValue', 
				'RAUF' 'ReportType'
				
		-- RADVPSF
		UNION
		SELECT	'SSIS_XML' 'ConfigurationDefinition', 
				'Load_HIMRA_EdgeReport_RADVPSummary.dtsx' 'ConfigurationValue' , 
				'RADVPSF' 'ReportType'
		UNION
		SELECT 'XSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RADVPSF\radvPopulationSummaryStatisticsFinal.xsd' 'ConfigurationValue', 
				'RADVPSF' 'ReportType'
		UNION
		SELECT 'RootNodeXSD' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RADVPSF\RADVPopulationSummaryStatisticsFinalReportRoot.xsd' 'ConfigurationValue', 
				'RADVPSF' 'ReportType'
		UNION
		SELECT 'RootNodeXLT' 'ConfigurationDefinition',  
				@FilePath + @XSDPath + 'RADVPSF\radvPopulationSummaryStatisticsFinalRootStyleSheet.xslt' 'ConfigurationValue', 
				'RADVPSF' 'ReportType'													
)
		AS source
ON (target.ConfigurationDefinition = source.ConfigurationDefinition 
	and target.ReportType = source.ReportType )
WHEN MATCHED THEN 
    UPDATE SET 
		ConfigurationValue = source.ConfigurationValue
WHEN NOT MATCHED THEN	
    INSERT (ConfigurationDefinition,ConfigurationValue,ReportType )
    VALUES (source.ConfigurationDefinition, source.ConfigurationValue, source.ReportType);