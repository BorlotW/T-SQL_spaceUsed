use <dataBase>
go

DROP TABLE IF EXISTS ##TABLE_LIST
SELECT o.db_name ,
       o.schema_id ,
       o.schema_name ,
       o.table_id ,
       o.table_name ,
       o.nr_qtd INTO ##table_List
FROM
  (SELECT db_name() AS db_name,
          s.schema_id,
          s.name AS schema_name ,
          t.object_id AS table_id,
          t.name AS table_name ,
          CAST(0 AS bigint) AS nr_qtd
   FROM <dataBase>.sys.tables t
   JOIN <dataBase>.sys.schemas s ON t.schema_id = s.schema_id) o
WHERE o.table_name NOT IN ('sysdiagrams')
ORDER BY 1, 2
SET NOCOUNT ON;

DECLARE @db_name varchar(20) ,
              @schema_id int ,@schema_name varchar(256) ,
              @table_id int ,@table_name varchar(256) ,
              @nr_qtd bigint ,@nr_qtd_aux bigint ,@query varchar(MAX);

DECLARE @TextoProc TABLE (  name varchar(256),
                                                 ROWS bigint, reserved varchar(256),
                                                 DATA varchar(256),
                                                 index_size varchar(256),
                                                 unused varchar(256));

DECLARE Table_List CURSOR FOR
                                   SELECT db_name,
                                             schema_id,
                                             schema_name,
                                             table_id,
                                             table_name,
                                             nr_qtd
                                   FROM ##table_List
                                   ORDER BY schema_name, table_name;

OPEN Table_List FETCH NEXT FROM Table_List INTO @db_name, @schema_id, @schema_name, @table_id, @table_name, @nr_qtd

WHILE @@FETCH_STATUS = 0 BEGIN
SET @nr_qtd = 0 IF @table_name IS NOT NULL BEGIN
DELETE @TextoProc
SET @nr_qtd_aux = 0
SET @query = ''
SET @query = N'OIMSQLDB_Seg..sp_spaceused ''' + @schema_name + '.' + @table_name + '''';

INSERT INTO @TextoProc (name, ROWS, reserved, DATA, index_size, unused) exec(@query)
SELECT @nr_qtd_aux = ROWS
FROM @TextoProc;


SET @nr_qtd = @nr_qtd_aux;

END
UPDATE ##table_List
SET nr_qtd = @nr_qtd
WHERE schema_name = @schema_name
  AND table_name = @table_name FETCH NEXT
  FROM Table_List INTO @db_name,
                       @schema_id,
                       @schema_name,
                       @table_id,
                       @table_name,
                       @nr_qtd END CLOSE Table_List;

DEALLOCATE Table_List;

SELECT * FROM ##table_List
