
USE UniHospital;
GO

-- ===============================
-- Assume parameters are passed in
-- ===============================
DECLARE @PatientID INT = 301;   -- Example patient
DECLARE @NewWardID INT = 202;   -- Example new ward
DECLARE @DiagnosisCode NVARCHAR(20) = 'DiaTransfer';

BEGIN TRY
    BEGIN TRANSACTION TransferPatient;

    -- ======================================
    -- Step 1: Discharge from current admission
    -- ======================================
    
    UPDATE Admission
    SET DischargeDate = CAST(GETDATE() AS DATE)
    WHERE PatientID = @PatientID
      AND DischargeDate IS NULL;

    IF @@ROWCOUNT = 0
        THROW 50010, 'No active admission found for patient.', 1;

    -- =========================
    -- Step 2: Admit to new ward
    -- =========================

    DECLARE @NewAdmissionID INT;
    INSERT INTO Admission (PatientID, WardID, AdmitDate, DiagnosisCode)
    VALUES (@PatientID, @NewWardID, CAST(GETDATE() AS DATE), @DiagnosisCode);

    SET @NewAdmissionID = SCOPE_IDENTITY();

    -- =====================
    -- Step 3: Log transfer
    -- =====================
    IF OBJECT_ID('dbo.PatientTransferLog', 'U') IS NULL
    BEGIN
        CREATE TABLE PatientTransferLog (
            LogID INT IDENTITY(1,1) PRIMARY KEY,
            PatientID INT NOT NULL,
            OldWardID INT NOT NULL,
            NewWardID INT NOT NULL,
            TransferDate DATETIME2 DEFAULT SYSDATETIME()
        );
    END;

    DECLARE @OldWardID INT;
    SELECT @OldWardID = WardID
    FROM Admission
    WHERE PatientID = @PatientID
    ORDER BY AdmissionID DESC
    OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;

    INSERT INTO PatientTransferLog (PatientID, OldWardID, NewWardID)
    VALUES (@PatientID, @OldWardID, @NewWardID);

    COMMIT TRANSACTION TransferPatient;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION TransferPatient;

    SELECT
        ERROR_NUMBER()   AS ErrorNumber,
        ERROR_SEVERITY() AS Severity,
        ERROR_STATE()    AS State,
        ERROR_PROCEDURE() AS Procedure_,
        ERROR_LINE()     AS Line,
        ERROR_MESSAGE()  AS Message;
END CATCH;
GO 

-- =====================================
-- 5.2a Session 1: Patient first, Bill second
-- =====================================
USE UniHospital;
BEGIN TRANSACTION;

-- Step 1: Acquire X lock on Patient row 301
UPDATE Patient
SET    Phone = '232-76-111000'
WHERE  PatientID = 301;

-- Pause here (in SSMS: run up to this point, then switch windows)
-- WAITFOR DELAY '00:00:05';   -- optional: simulate human pause

-- Step 2: Try to acquire X lock on Bill row 801
-- This will BLOCK because Session 2 holds a lock on Bill 801
UPDATE Bill
SET    PaidAmount = PaidAmount + 10
WHERE  BillID = 801;

COMMIT TRANSACTION;
PRINT 'Session 1 committed';

-- ======================================================
-- Session 2: Bill first, Patient second (OPPOSITE order)
-- ======================================================

USE UniHospital;
BEGIN TRANSACTION;

-- Step 1: Acquire X lock on Bill row 801

UPDATE Bill
SET    PaidAmount = PaidAmount + 5
WHERE  BillID = 801;


UPDATE Patient
SET    Phone = '232-76-111999'
WHERE  PatientID = 301;

COMMIT TRANSACTION;
PRINT 'Session 2 committed';

-- ===========================================================
-- Option A: Query live blocking while deadlock is in progress
-- ===========================================================
SELECT
    r.session_id,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time          / 1000.0  AS wait_sec,
    r.status,
    SUBSTRING(t.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE r.statement_end_offset
          END - r.statement_start_offset)/2)+1)  AS current_sql
FROM  sys.dm_exec_requests   r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id > 0
   OR  r.wait_type LIKE 'LCK%';




