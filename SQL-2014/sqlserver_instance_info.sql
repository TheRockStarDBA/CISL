/*
	Columnstore Indexes Scripts Library for SQL Server 2014: 
	SQL Server Instance Information - Provides with the list of the known SQL Server versions that have bugfixes or improvements over your current version + lists currently enabled trace flags on the instance & session
	Version: Release 1, September 2015

	Copyright 2015 Niko Neugebauer, OH22 IS (http://www.nikoport.com/columnstore/), (http://www.oh22.is/)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/*
	Known Issues & Limitations: 
		- Custom non-standard (non-CU & non-SP) versions are not targeted yet
*/

-- Params --
declare @showUnrecognizedTraceFlags bit = 1,		-- Enables showing active trace flags, even if they are not columnstore indexes related
		@identifyCurrentVersion bit = 1;			-- Enables identification of the currently used SQL Server Instance version
-- end of --

--------------------------------------------------------------------------------------------------------------------
declare @SQLServerVersion nvarchar(128) = cast(SERVERPROPERTY('ProductVersion') as NVARCHAR(128)), 
		@SQLServerEdition nvarchar(128) = cast(SERVERPROPERTY('Edition') as NVARCHAR(128)),
		@SQLServerBuild smallint = NULL;
declare @errorMessage nvarchar(512);

-- Ensure that we are running SQL Server 2014
if substring(@SQLServerVersion,1,CHARINDEX('.',@SQLServerVersion)-1) <> N'12'
begin
	set @errorMessage = (N'You are not running a SQL Server 2014. Your SQL Server version is ' + @SQLServerVersion);
	Throw 51000, @errorMessage, 1;
end

if SERVERPROPERTY('EngineEdition') <> 3 
begin
	set @errorMessage = (N'Your SQL Server 2014 Edition is not an Enterprise or a Developer Edition: Your are running a ' + @SQLServerEdition);
	Throw 51000, @errorMessage, 1;
end


--------------------------------------------------------------------------------------------------------------------
set @SQLServerBuild = substring(@SQLServerVersion,CHARINDEX('.',@SQLServerVersion,5)+1,CHARINDEX('.',@SQLServerVersion,8)-CHARINDEX('.',@SQLServerVersion,5)-1);

create table #SQLColumnstoreImprovements(
	BuildVersion smallint not null,
	SQLBranch char(3) not null,
	UpdateName nvarchar(100) not null,
	Description nvarchar(500) not null,
	URL nvarchar(1000) 
);

create table #SQLBranches(
	SQLBranch char(3) not null,
	MinVersion smallint not null );

create table #SQLVersions(
	SQLBranch char(3) not null,
	SQLVersion smallint not null,
	SQLVersionDescription nvarchar(100) );

insert into #SQLBranches (SQLBranch, MinVersion)
	values ('RTM', 2000 ), ('SP1', 4100);

insert #SQLVersions( SQLBranch, SQLVersion, SQLVersionDescription )
	values 
	( 'RTM', 2000, 'SQL Server 2014 RTM' ),
	( 'RTM', 2342, 'CU 1 for SQL Server 2014 RTM' ),
	( 'RTM', 2370, 'CU 2 for SQL Server 2014 RTM' ),
	( 'RTM', 2402, 'CU 3 for SQL Server 2014 RTM' ),
	( 'RTM', 2430, 'CU 4 for SQL Server 2014 RTM' ),
	( 'RTM', 2456, 'CU 5 for SQL Server 2014 RTM' ),
	( 'RTM', 2480, 'CU 6 for SQL Server 2014 RTM' ),
	( 'RTM', 2495, 'CU 7 for SQL Server 2014 RTM' ),
	( 'RTM', 2546, 'CU 8 for SQL Server 2014 RTM' ),
	( 'RTM', 2342, 'CU 9 for SQL Server 2014 RTM' ),
	( 'SP1', 4100, 'SQL Server 2014 SP1' ),
	( 'SP1', 4416, 'CU 1 for SQL Server 2014 SP1' ),
	( 'SP1', 2342, 'CU 2 for SQL Server 2014 SP1' );

insert into #SQLColumnstoreImprovements (BuildVersion, SQLBranch, UpdateName, Description, URL )
	values 
	( 2342, 'RTM', 'CU 1 for SQL Server 2014 RTM', 'FIX: Error 35377 when you build or rebuild clustered columnstore index with maxdop larger than 1 through MARS connection in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2942895' ),
	( 2370, 'RTM', 'CU 2 for SQL Server 2014 RTM', 'FIX: Loads or queries on CCI tables block one another in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2931815' ),
	( 2370, 'RTM', 'CU 2 for SQL Server 2014 RTM', 'FIX: Access violation when you insert data into a table that has a clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2966096' ),
	( 2370, 'RTM', 'CU 2 for SQL Server 2014 RTM', 'FIX: Error when you drop a clustered columnstore index table during recovery in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2974397' ),
	( 2370, 'RTM', 'CU 2 for SQL Server 2014 RTM', 'FIX: Poor performance when you bulk insert into partitioned CCI in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2969421' ),
	( 2370, 'RTM', 'CU 2 for SQL Server 2014 RTM', 'FIX: Truncated CCI partitioned table runs for a long time in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2969419' ),
	( 2370, 'RTM', 'CU 2 for SQL Server 2014 RTM', 'FIX: DBCC SHRINKDATABASE or DBCC SHRINKFILE cannot move pages that belong to the nonclustered columnstore index', 'https://support.microsoft.com/en-us/kb/2967198' ),
	( 2402, 'RTM', 'CU 3 for SQL Server 2014 RTM', 'FIX: UPDATE or INSERT statement on CCI makes sys.partitions not match actual row count in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2978472' ), 
	( 2402, 'RTM', 'CU 3 for SQL Server 2014 RTM', 'FIX: Cannot create indexed view on a clustered columnstore index and BCP on the table fails in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/2981764' ),
	( 2402, 'RTM', 'CU 3 for SQL Server 2014 RTM', 'FIX: Some columns in sys.column_store_segments view show NULL value when the table has non-dbo schema in SQL Server', 'https://support.microsoft.com/en-us/kb/2989704' ),
	( 2430, 'RTM', 'CU 4 for SQL Server 2014 RTM', 'FIX: Error 8654 when you run "INSERT INTO … SELECT" on a table with clustered columnstore index in SQL Server 2014 ', 'https://support.microsoft.com/en-us/kb/2998301' ),
	( 2430, 'RTM', 'CU 4 for SQL Server 2014 RTM', 'FIX: UPDATE STATISTICS performs incorrect sampling and processing for a table with columnstore index in SQL Server', 'https://support.microsoft.com/en-us/kb/2986627' ),
	( 2456, 'RTM', 'CU 5 for SQL Server 2014 RTM', 'FIX: Error 35377 occurs when you try to access clustered columnstore indexes in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3020113' ),
	( 2480, 'RTM', 'CU 6 for SQL Server 2014 RTM', 'FIX: Access violation occurs when you delete rows from a table that has clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3029762' ),
	( 2480, 'RTM', 'CU 6 for SQL Server 2014 RTM', 'FIX: OS error 665 when you execute DBCC CHECKDB command for database that contains columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3029977' ),
	( 2480, 'RTM', 'CU 6 for SQL Server 2014 RTM', 'FIX: Error 8646 when you run DML statements on a table with clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3035165' ),
	( 2480, 'RTM', 'CU 7 for SQL Server 2014 RTM', 'FIX: Improved memory management for columnstore indexes to deliver better query performance in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3053664' ),
	( 2495, 'RTM', 'CU 8 for SQL Server 2014 RTM', 'FIX: Partial results in a query of a clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3067257' ),
	( 2546, 'RTM', 'CU 8 for SQL Server 2014 RTM', 'FIX: Access violation when you query against a table that contains column store indexes in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3064784' ),
	( 2546, 'RTM', 'CU 8 for SQL Server 2014 RTM', 'FIX: Error 33294 occurs when you alter column types on a table that has clustered columnstore indexes in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3070139' ),
	( 2546, 'RTM', 'CU 8 for SQL Server 2014 RTM', '"Non-yielding Scheduler" error when a database has columnstore indexes on a SQL Server 2014 instance', 'https://support.microsoft.com/en-us/kb/3069488' ),
	( 2546, 'RTM', 'CU 8 for SQL Server 2014 RTM', 'FIX: Memory is paged out when columnstore index query consumes lots of memory in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3067968' ),
	( 2553, 'RTM', 'CU 9 for SQL Server 2014 RTM', 'FIX: Rare index corruption when you build a columnstore index with parallelism on a partitioned table in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3080155' ), 
	( 4100, 'SP1', 'SQL Server 2014 SP1', 'LOB reads are shown as zero when "SET STATISTICS IO" is on during executing a query with clustered columnstore index.', 'https://support.microsoft.com/en-us/kb/3058865' ),
	( 4100, 'SP1', 'SQL Server 2014 SP1', 'FIX: OS error 665 when you execute DBCC CHECKDB command for database that contains columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3029977' ),
	( 4100, 'SP1', 'SQL Server 2014 SP1', 'FIX: Error 8646 when you run DML statements on a table with clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3035165' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Improved memory management for columnstore indexes to deliver better query performance in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3053664' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', '"Non-yielding Scheduler" error when a database has columnstore indexes on a SQL Server 2014 instance', 'https://support.microsoft.com/en-us/kb/3069488' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Access violation occurs when you delete rows from a table that has clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3029762' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Memory is paged out when columnstore index query consumes lots of memory in SQL Server 2014 ', 'https://support.microsoft.com/en-us/kb/3067968' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Severe error in SQL Server 2014 during compilation of a query on a table with clustered columnstore index', 'https://support.microsoft.com/en-us/kb/3068297' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Error 8646 when you run DML statements on a table with clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3035165' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Partial results in a query of a clustered columnstore index in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3067257' ),
	( 4416, 'SP1', 'CU 1 for SQL Server 2014 SP1', 'FIX: Error 33294 occurs when you alter column types on a table that has clustered columnstore indexes in SQL Server 2014', 'https://support.microsoft.com/en-us/kb/3070139' );


if @identifyCurrentVersion = 1
begin
	if( exists (select 1
					from #SQLVersions
					where SQLVersion = cast(@SQLServerBuild as int) ) )
		select 'You are Running:' as MessageText, SQLVersionDescription, SQLBranch, SQLVersion as BuildVersion
			from #SQLVersions
			where SQLVersion = cast(@SQLServerBuild as int);
	else
		select 'You are Running a Non RTM/SP/CU standard version:' as MessageText, '-' as SQLVersionDescription, 
			ServerProperty('ProductLevel') as SQLBranch, @SQLServerBuild as SQLVersion;
end

select imps.*
	from #SQLColumnstoreImprovements imps
		inner join #SQLBranches branch
			on imps.SQLBranch = branch.SQLBranch
	where BuildVersion > @SQLServerBuild and branch.MinVersion < BuildVersion;

drop table #SQLColumnstoreImprovements;
drop table #SQLBranches;
drop table #SQLVersions;

--------------------------------------------------------------------------------------------------------------------
-- Trace Flags part
create table #ActiveTraceFlags(	
	TraceFlag nvarchar(20) not null,
	Status bit not null,
	Global bit not null,
	Session bit not null );

insert into #ActiveTraceFlags
	exec sp_executesql N'DBCC TRACESTATUS()';

create table #ColumnstoreTraceFlags(
	TraceFlag int not null,
	Description nvarchar(500) not null,
	URL nvarchar(600),
	SupportedStatus bit not null 
);

insert into #ColumnstoreTraceFlags (TraceFlag, Description, URL, SupportedStatus )
	values 
	(  634, 'Disables the background columnstore compression task.', 'https://msdn.microsoft.com/en-us/library/ms188396.aspx', 1 ),
	(  834, 'Enable Large Pages', 'https://support.microsoft.com/en-us/kb/920093?wa=wsignin1.0', 0 ),
	(  646, 'Gets text output messages that show what segments (row groups) were eliminated during query processing', 'http://social.technet.microsoft.com/wiki/contents/articles/5611.verifying-columnstore-segment-elimination.aspx', 1 ),
	( 9453, 'Disables Batch Execution Mode', 'http://www.nikoport.com/2014/07/24/clustered-columnstore-indexes-part-35-trace-flags-query-optimiser-rules/', 1 ),
	(10207, 'Skips Corrupted Columnstore Segments (Fixed in CU8 for SQL Server 2014 RTM and CU1 for SQL Server 2014 SP1)', 'https://support.microsoft.com/en-us/kb/3067257', 1 );

select tf.TraceFlag, isnull(conf.Description,'Unrecognized') as Description, isnull(conf.URL,'-') as URL, SupportedStatus
	from #ActiveTraceFlags tf
		left join #ColumnstoreTraceFlags conf
			on conf.TraceFlag = tf.TraceFlag
	where @showUnrecognizedTraceFlags = 1 or (@showUnrecognizedTraceFlags = 0 AND Description is not null);

drop table #ColumnstoreTraceFlags;
drop table #ActiveTraceFlags;

