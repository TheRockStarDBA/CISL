/*
	CSIL - Columnstore Indexes Scripts Library for SQL Server 2014: 
	Columnstore Alignment - Shows the alignment (ordering) between the different Columnstore Segments
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
*/

-- Params --
declare
	@showPartitionStats bit = 1,			-- Shows alignment statistics based on the partition
	@showUnsupportedSegments bit = 1,		-- Shows unsupported Segments in the result set
	@tableName nvarchar(256) = NULL,		-- Allows to show data filtered down to 1 particular table
	@columnName nvarchar(256) = NULL,		-- Allows to show data filtered down to 1 particular column name
	@columnId int = NULL;					-- Allows to filter one specific column Id
-- end of --

declare @SQLServerVersion nvarchar(128) = cast(SERVERPROPERTY('ProductVersion') as NVARCHAR(128)), 
		@SQLServerEdition nvarchar(128) = cast(SERVERPROPERTY('Edition') as NVARCHAR(128));
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
set nocount on;

IF OBJECT_ID('tempdb..#column_store_segments') IS NOT NULL
	DROP TABLE #column_store_segments

SELECT part.object_id, part.partition_number, part.hobt_id, part.partition_id, seg.column_id, seg.segment_id, seg.min_data_id, seg.max_data_id
INTO #column_store_segments
FROM sys.column_store_segments seg
INNER JOIN sys.partitions part
       ON seg.hobt_id = part.hobt_id and seg.partition_id = part.partition_id
WHERE part.object_id = isnull(object_id(@tableName),part.object_id)

ALTER TABLE #column_store_segments
ADD UNIQUE (hobt_id, partition_id, column_id, min_data_id, segment_id);

ALTER TABLE #column_store_segments
ADD UNIQUE (hobt_id, partition_id, column_id, max_data_id, segment_id);

with cteSegmentAlignment as (
	select  part.object_id,  case @showPartitionStats when 1 then part.partition_number else 1 end as partition_number, 
			seg.partition_id, seg.column_id, cols.name as ColumnName, tp.name as ColumnType,
			seg.segment_id, 
			CONVERT(BIT, MAX(CASE WHEN filteredSeg.segment_id IS NOT NULL THEN 1 ELSE 0 END)) AS hasOverlappingSegment
		from sys.column_store_segments seg
			inner join sys.partitions part
				on seg.hobt_id = part.hobt_id and seg.partition_id = part.partition_id 
			inner join sys.columns cols
				on part.object_id = cols.object_id and seg.column_id = cols.column_id
			inner join sys.types tp
				on cols.system_type_id = tp.system_type_id and cols.user_type_id = tp.user_type_id
			outer apply (
				SELECT TOP 1 otherSeg.segment_id
				FROM #column_store_segments otherSeg WITH (FORCESEEK)
				WHERE seg.hobt_id = otherSeg.hobt_id 
						AND seg.partition_id = otherSeg.partition_id 
						AND seg.column_id = otherSeg.column_id
						AND seg.segment_id <> otherSeg.segment_id
						AND (seg.min_data_id < otherSeg.min_data_id and seg.max_data_id > otherSeg.min_data_id )  -- Scenario 1 
				UNION ALL
				SELECT TOP 1 otherSeg.segment_id
				FROM #column_store_segments otherSeg WITH (FORCESEEK)
				WHERE seg.hobt_id = otherSeg.hobt_id 
						AND seg.partition_id = otherSeg.partition_id 
						AND seg.column_id = otherSeg.column_id
						AND seg.segment_id <> otherSeg.segment_id
						AND (seg.min_data_id < otherSeg.max_data_id and seg.max_data_id > otherSeg.max_data_id )  -- Scenario 2 
			) filteredSeg
		where part.object_id = isnull(object_id(@tableName),part.object_id)
		group by part.object_id, case @showPartitionStats when 1 then part.partition_number else 1 end, seg.partition_id, seg.column_id, cols.name, tp.name, seg.segment_id
)
select object_name(object_id) as TableName, partition_number as 'Partition', cte.column_id as 'Column Id', cte.ColumnName, 
	cte.ColumnType,
	case cte.ColumnType when 'numeric' then 'Segment Elimination is not supported' 
						when 'datetimeoffset' then 'Segment Elimination is not supported' 
						when 'char' then 'Segment Elimination is not supported' 
						when 'nchar' then 'Segment Elimination is not supported' 
						when 'varchar' then 'Segment Elimination is not supported' 
						when 'nvarchar' then 'Segment Elimination is not supported' 
						when 'sysname' then 'Segment Elimination is not supported' 
						when 'binary' then 'Segment Elimination is not supported' 
						when 'varbinary' then 'Segment Elimination is not supported' 
						when 'uniqueidentifier' then 'Segment Elimination is not supported' 
		else 'OK' end as 'Segment Elimination',
	sum(CONVERT(INT, hasOverlappingSegment)) as [Dealigned Segments],
	count(*) as [Total Segments],
	100 - cast( sum(CONVERT(INT, hasOverlappingSegment)) * 100.0 / (count(*)) as Decimal(6,2)) as [Segment Alignment %]
	from cteSegmentAlignment cte
	where ((@showUnsupportedSegments = 0 and cte.ColumnType not in ('numeric','datetimeoffset','char', 'nchar', 'varchar', 'nvarchar', 'sysname','binary','varbinary','uniqueidentifier'))
		  OR @showUnsupportedSegments = 1)
		  and cte.ColumnName = isnull(@columnName,cte.ColumnName)
		  and cte.column_id = isnull(@columnId,cte.column_id)
	group by object_name(object_id), partition_number, cte.column_id, cte.ColumnName, cte.ColumnType
	order by object_name(object_id), partition_number, cte.column_id;
