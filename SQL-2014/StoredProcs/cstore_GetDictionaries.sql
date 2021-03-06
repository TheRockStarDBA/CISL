/*
	Columnstore Indexes Scripts Library for SQL Server 2014: 
	Dictionaries Analysis - Shows detailed information about the Columnstore Dictionaries
	Version: Release 1, August 2015

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
if EXISTS (select * from sys.objects where type = 'p' and name = 'cstore_GetDictionaries' and schema_id = SCHEMA_ID('dbo') )
	Drop Procedure dbo.cstore_GetDictionaries;
GO

create procedure dbo.cstore_GetDictionaries(
-- Params --
	@showWarningsOnly bit = 0,							-- Enables to filter out the dictionaries based on the Dictionary Size (@warningDictionarySizeInMB) and Entry Count (@warningEntryCount)
	@warningDictionarySizeInMB Decimal(8,2) = 6.,		-- The size of the dictionary, after which the dictionary should be selected. The value is in Megabytes 
	@warningEntryCount Int = 1000000,					-- Enables selecting of dictionaries with more than this number 
	@showAllTextDictionaries bit = 0,					-- Enables selecting all textual dictionaries indepentantly from their warning status
	@tableName nvarchar(256) = NULL,					-- Allows to show data filtered down to 1 particular table
	@columnName nvarchar(256) = NULL					-- Allows to filter out data base on 1 particular column name
-- end of --
) as 
begin
	set nocount on;

	declare @table_object_id int = NULL;

	if (@tableName is not NULL )
		set @table_object_id = isnull(object_id(@tableName),-1);
	else 
		set @table_object_id = NULL;

	SELECT object_schema_name(i.object_id) + '.' + object_name(i.object_id) as 'TableName', 
			p.partition_number as 'Partition',
			(select count(rg.row_group_id) from sys.column_store_row_groups rg
				where rg.object_id = i.object_id and rg.partition_number = p.partition_number
					  and rg.state = 3 ) as 'RowGroups',
			count(csd.column_id) as 'Dictionaries', 
			sum(csd.entry_count) as 'EntriesCount',
			min(p.rows) as 'Rows Serving',
			cast( SUM(csd.on_disk_size)/(1024.0*1024.0) as Decimal(8,3)) as 'Size in MB'
		FROM sys.indexes AS i
			inner join sys.partitions AS p
				on i.object_id = p.object_id 
			inner join sys.column_store_dictionaries AS csd
				on csd.hobt_id = p.hobt_id and csd.partition_id = p.partition_id
		where i.type in (5,6)
			and i.object_id = isnull(@table_object_id,i.object_id)
		group by object_schema_name(i.object_id) + '.' + object_name(i.object_id), i.object_id, p.partition_number;



	select object_schema_name(part.object_id) + '.' + object_name(part.object_id) as 'TableName',
				ind.name as 'IndexName', 
				part.partition_number as 'Partition',
				cols.name as ColumnName, 
				dict.dictionary_id as 'SegmentId',
				tp.name as ColumnType,
				dict.column_id as 'ColumnId', 
				case dictionary_id when 0 then 'Global' else 'Local' end as 'Type', 
				part.rows as 'Rows Serving', 
				entry_count as 'Entry Count', 
				cast( on_disk_size / 1024. / 1024. as Decimal(8,2)) 'SizeInMb'
		from sys.column_store_dictionaries dict
			inner join sys.partitions part
				ON dict.hobt_id = part.hobt_id and dict.partition_id = part.partition_id
			inner join sys.indexes ind
				on part.object_id = ind.object_id and part.index_id = ind.index_id
			inner join sys.columns cols
				on part.object_id = cols.object_id and dict.column_id = cols.column_id
			inner join sys.types tp
				on cols.system_type_id = tp.system_type_id and cols.user_type_id = tp.user_type_id
		where 
			(( @showWarningsOnly = 1 
				AND 
				( cast( on_disk_size / 1024. / 1024. as Decimal(8,2)) > @warningDictionarySizeInMB OR
					entry_count > @warningEntryCount
				)
			) OR @showWarningsOnly = 0 )
			AND
			(( @showAllTextDictionaries = 1 
				AND
				case tp.name 
					when 'char' then 1
					when 'nchar' then 1
					when 'varchar' then 1
					when 'nvarchar' then 1
					when 'sysname' then 1
				end = 1
			) OR @showAllTextDictionaries = 0 )
			and ind.object_id = isnull(@table_object_id,ind.object_id)
			and cols.name = isnull(@columnName,cols.name)
		order by object_schema_name(part.object_id) + '.' +	object_name(part.object_id), ind.name, part.partition_number;


end
