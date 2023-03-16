/*  Created By Kosta Dombrovskiy
	TFS 17141
	Description:  Add RADVMemberStatuses.
	Date: 10/29/2013
	Modifications:

*/

set identity_insert RADVMemberStatuses on

	merge RADVMemberStatuses as Target
	using
		(
				select 1 as ID, 'Y' as RADVStatusCode, 'Confirmed, Passed' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 2 as ID, 'HY' as RADVStatusCode, 'Confirmed, Higher in Hierarchy' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 3 as ID, 'LY' as RADVStatusCode, 'Confirmed, Lower in Hierarchy' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 4 as ID, 'S' as RADVStatusCode, 'Confirmed, but Signature/Auth/Name Errors' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 5 as ID, 'HS' as RADVStatusCode, 'Confirmed Higher, but Signature/Auth/Name Errors' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 6 as ID, 'LS' as RADVStatusCode, 'Confirmed Lower, but Signature/Auth/Name Errors' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 7 as ID, 'CN' as RADVStatusCode, 'Failed, Error Reading Chart' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 8 as ID, 'N' as RADVStatusCode, 'Failed with Errors' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 9 as ID, 'INP' as RADVStatusCode, 'Chart Received, No failures tied to the chart' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 10 as ID, 'NC' as RADVStatusCode, 'No Chart' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime
				union all
				select 11 as ID, 'NW' as RADVStatusCode, 'Discovered' as RADVStatusDescription, sysdatetime() as CreationDateTime, sysdatetime() as LastUpdateDateTime

		) as Source
		on (target.ID = Source.ID)
		when matched then
				Update set --Target.ID = Source.ID, 
				Target.RADVStatusCode = Source.RADVStatusCode, Target.RADVStatusDescription = Source.RADVStatusDescription, Target.CreationDateTime = Source.CreationDateTime
							, Target.LastUpdateDateTime = Source.LastUpdateDateTime
		when not matched then
				Insert (ID, RADVStatusCode, RADVStatusDescription, CreationDateTime, LastUpdateDateTime)
				values (Source.ID, Source.RADVStatusCode, Source.RADVStatusDescription, Source.CreationDateTime, Source.LastUpdateDateTime);

set identity_insert RADVMemberStatuses off
