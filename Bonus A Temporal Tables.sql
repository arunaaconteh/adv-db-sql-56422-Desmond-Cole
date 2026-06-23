
--=======================
-- Bonus A Temporal Table
-- ======================

--=======================
-- 1 Convert Patient and Admission to Temporal Tables
-- ======================

USE UniHospital;
GO

-- Convert Patient table
ALTER TABLE Patient
ADD SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN,
    SysEndTime   DATETIME2 GENERATED ALWAYS AS ROW END   HIDDEN,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);
GO

ALTER TABLE Patient
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PatientHistory));
GO

-- Convert Admission table
ALTER TABLE Admission
ADD SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN,
    SysEndTime   DATETIME2 GENERATED ALWAYS AS ROW END   HIDDEN,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);
GO

ALTER TABLE Admission
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.AdmissionHistory));
GO

-- ===============================
-- 2 Query Historical States
-- ===============================

-- View Patient records as of June 10, 2026
SELECT *
FROM Patient
FOR SYSTEM_TIME AS OF '2026-06-10T00:00:00';

-- =========================
-- 3 Point-in-Time Audit (Two Weeks Ago)
-- ========================

-- Admissions state two weeks ago
SELECT *
FROM Admission
FOR SYSTEM_TIME AS OF '2026-06-09T00:00:00';

