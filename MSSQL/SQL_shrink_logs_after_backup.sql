-- Begin Cursor to shrink log files after full backup

declare @DBName varchar(50)
declare @SQLString nvarchar(2000)
declare @LogName varchar(50)

DECLARE crsr_shrink_logs CURSOR FOR
	SELECT name FROM master..sysdatabases WHERE dbid > 4

OPEN crsr_shrink_logs
FETCH NEXT FROM crsr_shrink_logs INTO @DBName
WHILE @@FETCH_STATUS = 0
  BEGIN
		set @SQLString = 'USE [' + @DBName + '];
		
		-- Truncate the log by changing the database recovery model to SIMPLE.
		ALTER DATABASE [' + @DBName + ']
		SET RECOVERY SIMPLE;
				
		-- Shrink the truncated log file to 1 GB.
		DBCC SHRINKFILE (' + char(34) + @DBName + '_Log' + char(34) +', 256);
				
		-- Reset the database recovery model.
		ALTER DATABASE [' + @DBName + ']
		SET RECOVERY FULL;'
		--print @SQLString
		EXEC sp_executesql @SQLString
      	
      	FETCH NEXT FROM crsr_shrink_logs INTO @DBName
  END
CLOSE crsr_shrink_logs
DEALLOCATE crsr_shrink_logs
go
