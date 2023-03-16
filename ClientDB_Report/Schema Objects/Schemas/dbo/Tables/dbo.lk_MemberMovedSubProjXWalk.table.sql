CREATE TABLE dbo.lk_MemberMovedSubProjXWalk
		(ProjectDescription				VARCHAR(100)
			,OriginalSubProjID			INT
			,OriginalSubProj			VARCHAR(100)
			,NewSubProjID				INT
			,NewSubProj					VARCHAR(100)
			,OriginalRequestID			INT
			,NewRequestID				INT
			,HICN						VARCHAR(20)
			,OriginalSPMRID				INT
			,NewSPMRID					INT
		)