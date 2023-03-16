CREATE VIEW [rev].[RiskAdjustmentDashboard]
AS
	SELECT PaymentYear
		,SUM(PartCAverageRiskScore) AS PartCAverageRiskScore
		,SUM(PartDAverageRiskScore) AS PartDAverageRiskScore
		,SUM(PartCTotalEstReceivables) AS PartCTotalEstReceivables
		,SUM(PartDTotalEstReceivables) AS PartDTotalEstReceivables
	FROM
	(
		SELECT z.PaymentYear
			   ,PartCAverageRiskScore = SUM(z.AdjustedFinalFactor) / COUNT(DISTINCT z.HICN)
			   ,0 AS PartDAverageRiskScore
			   ,0 AS PartCTotalEstReceivables
			   ,0 AS PartDTotalEstReceivables
		FROM
		(
			SELECT DISTINCT
				   b.PaymentYear
				   ,b.EncounterSource
				   ,b.HICN
				   ,a.HCC
				   ,a.AdjustedFinalFactor
			FROM [rev].[PartCNewHCCOutputMParameter] a WITH (NOLOCK)
				INNER JOIN
				(
					SELECT PaymentYear
						   ,EncounterSource
						   ,HICN
						   ,MayPaymStart = MAX(PaymentStartDate)
					FROM [rev].[PartCNewHCCOutputMParameter] WITH (NOLOCK)
					WHERE EncounterSource = 'EDS'
					GROUP BY PaymentYear
							 ,EncounterSource
							 ,HICN
				) b
					ON a.PaymentYear = b.PaymentYear
					   AND a.EncounterSource = b.EncounterSource
					   AND a.HICN = b.HICN
					   AND a.PaymentStartDate = b.MayPaymStart
		) z
		WHERE z.PaymentYear BETWEEN YEAR(GETDATE()) - 2 AND YEAR(GETDATE()) + 1 
		GROUP BY z.PaymentYear

		UNION ALL

		SELECT z.PaymentYear
			   ,0 AS PartCAverageRiskScore
			   ,PartDAverageRiskScore = SUM(z.AdjustedFinalFactor) / COUNT(DISTINCT z.HICN)
			   ,0 AS PartCTotalEstReceivables
			   ,0 AS PartDTotalEstReceivables
		FROM
		(
			SELECT DISTINCT
				   b.PaymentYear
				   ,b.EncounterSource
				   ,b.HICN
				   ,a.AdjustedFinalFactor
			FROM [rev].[PartDNewHCCOutputMParameter] a WITH (NOLOCK)
				INNER JOIN
				(
					SELECT PaymentYear
						   ,EncounterSource
						   ,HICN
						   ,MayPaymStart = MAX(PaymentStartDate)
					FROM [rev].[PartDNewHCCOutputMParameter] WITH (NOLOCK)
					WHERE EncounterSource = 'EDS'
					GROUP BY PaymentYear
							 ,EncounterSource
							 ,HICN
				) b
					ON a.PaymentYear = b.PaymentYear
					   AND a.EncounterSource = b.EncounterSource
					   AND a.HICN = b.HICN
					   AND a.PaymentStartDate = b.MayPaymStart
		) z
		WHERE z.PaymentYear BETWEEN YEAR(GETDATE()) - 2 AND YEAR(GETDATE()) + 1 
		GROUP BY z.PaymentYear

		UNION ALL

		SELECT PaymentYear
			,0 AS PartCAverageRiskScore
			,0 AS PartDAverageRiskScore
			,PartCTotalEstReceivables = SUM(EstimatedValue)
			,0 AS PartDTotalEstReceivables
		FROM [rev].[PartCNewHCCOutputMParameter] WITH (NOLOCK)
		WHERE EncounterSource = 'EDS'
		AND PaymentYear BETWEEN YEAR(GETDATE()) - 2 AND YEAR(GETDATE()) + 1
		GROUP BY PaymentYear

		UNION ALL

		SELECT PaymentYear
			,0 AS PartCAverageRiskScore
			,0 AS PartDAverageRiskScore
			,0 AS PartCTotalEstReceivables
			,PartDTotalEstReceivables = SUM(EstimatedValue)
		FROM [rev].[PartDNewHCCOutputMParameter] WITH (NOLOCK)
		WHERE EncounterSource = 'EDS'
		AND PaymentYear BETWEEN YEAR(GETDATE()) - 2 AND YEAR(GETDATE()) + 1
		GROUP BY PaymentYear

	) q
	GROUP BY PaymentYear