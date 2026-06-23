
-- ================================================
-- Point-in-Time Restore to 10 Minutes Ago
-- ================================================

USE master;
GO

DECLARE @TargetTime DATETIME =DATEADD(MINUTE, -10, GETDATE());

-- Step 1: Restore the Full Backup (WITH NORECOVERY keeps DB in restoring state)
RESTORE DATABASE UniHospital
FROM DISK = N'C:\Backups\UniHospital_Full.bak'
WITH NORECOVERY,
     REPLACE,
     STATS = 10;
GO

-- Step 2: Restore the Differential Backup (WITH NORECOVERY — still not done)
RESTORE DATABASE UniHospital
FROM DISK = N'C:\Backups\UniHospital_Diff.bak'
WITH NORECOVERY,
     STATS = 10;
GO

-- Step 3: Restore the Transaction Log WITH STOPAT (point-in-time)
RESTORE LOG UniHospital
FROM DISK = N'C:\Backups\UniHospital_Log.bak'
WITH RECOVERY,
     STOPAT = DATEADD(MINUTE, -10, GETDATE()),
     STATS = 10;
GO

--==============================
-- 1 Create a Login and Database User
--===========================
USE master;
GO

-- Create a SQL Server login
CREATE LOGIN ClinicianLogin
WITH PASSWORD = 'StrongPassword123!';
GO

USE UniHospital;
GO

-- Create a database user mapped to the login
CREATE USER ClinicianUser FOR LOGIN ClinicianLogin;
GO

-- Add the user to the db_clinician role
ALTER ROLE db_clinician ADD MEMBER ClinicianUser;
GO

-- ===================
-- 2 Verify Role Permissions
-- ===================

-- As ClinicianUser, try selecting from Appointment (should succeed)
EXECUTE AS USER = 'ClinicianUser';
SELECT TOP 5 * FROM Appointment;

-- Try selecting from Bill (should fail)
SELECT TOP 5 * FROM Bill;

-- Revert back to your admin context
REVERT;

--=====================
--3 Implement Row-Level Security (RLS)
-- =========================

-- 1 Create a function that enforces filtering 

USE UniHospital;
GO

CREATE SCHEMA Security;
GO

CREATE FUNCTION Security.fn_DoctorPredicate(@DoctorID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_DoctorPredicateResult
WHERE @DoctorID = CAST(SESSION_CONTEXT(N'DoctorID') AS INT);
GO
 
-- 2 Bind the function to the Appointment table 

CREATE SECURITY POLICY AppointmentFilter
ADD FILTER PREDICATE Security.fn_DoctorPredicate(DoctorID)
ON dbo.Appointment
WITH (STATE = ON);
GO
 
-- Before querying, set the doctor’s context
-- Simulate Dr. Aruna (DoctorID = 101)
EXEC sp_set_session_context @key = N'DoctorID', @value = 101;

-- Now this doctor only sees their own appointments
SELECT * FROM Appointment;

-- ===========================================
-- Maintenance Script for Index Fragmentation
-- ==========================================

USE UniHospital;
GO

DECLARE @TableName NVARCHAR(128);
DECLARE @IndexName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

-- Cursor to loop through fragmented indexes
DECLARE cur CURSOR FOR
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragPct
FROM sys.dm_db_index_physical_stats(
        DB_ID('UniHospital'), NULL, NULL, NULL, 'SAMPLED') ips
JOIN sys.indexes i
    ON ips.object_id = i.object_id
    AND ips.index_id = i.index_id
WHERE ips.page_count > 100;

OPEN cur;
FETCH NEXT FROM cur INTO @TableName, @IndexName, @SQL;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @SQL BETWEEN 10 AND 30
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REORGANIZE;';
    ELSE IF @SQL > 30
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD WITH (ONLINE = ON);';

    PRINT @SQL; -- For review
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM cur INTO @TableName, @IndexName, @SQL;
END

CLOSE cur;
DEALLOCATE cur;
GO

-- Update statistics after index maintenance
EXEC sp_updatestats;
GO
