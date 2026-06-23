
USE UniHospital;
GO

-- =========================
-- 3.1 Stored Procedures
-- =========================

-- =========================
-- 3.1b: usp_DischargePatient
-- ========================
CREATE OR ALTER PROCEDURE usp_DischargePatient
    @AdmissionID INT,
    @DischargeDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Update discharge date
        UPDATE Admission
        SET DischargeDate = @DischargeDate
        WHERE AdmissionID = @AdmissionID;

        -- Calculate bill total from prescriptions
        DECLARE @TotalAmount DECIMAL(10,2) = 0;

        SELECT @TotalAmount = SUM(m.UnitCost * p.Quantity)
        FROM Prescription p
        INNER JOIN Medication m ON p.MedID = m.MedID
        WHERE p.AdmissionID = @AdmissionID;

        -- Insert bill record (PaidAmount initially 0)
        DECLARE @PatientID INT;
        SELECT @PatientID = PatientID FROM Admission WHERE AdmissionID = @AdmissionID;

        INSERT INTO Bill (PatientID, AdmissionID, TotalAmount, PaidAmount, BillDate)
        VALUES (@PatientID, @AdmissionID, @TotalAmount, 0, @DischargeDate);

        -- Update medication stock
        UPDATE m
        SET m.StockQty = m.StockQty - p.Quantity
        FROM Medication m
        INNER JOIN Prescription p ON m.MedID = p.MedID
        WHERE p.AdmissionID = @AdmissionID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

--  ====================
-- 3.1c: usp_DoctorWorkloadReport 
-- =================
CREATE OR ALTER PROCEDURE usp_DoctorWorkloadReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT d.DoctorID,
           d.FirstName,
           d.LastName,
           COUNT(DISTINCT a.AppointmentID) AS AppointmentCount,
           COUNT(DISTINCT adm.AdmissionID) AS AdmissionCount,
           AVG(b.TotalAmount) AS AvgBillValue
    FROM Doctor d
    LEFT JOIN Appointment a 
        ON d.DoctorID = a.DoctorID 
       AND a.ApptDate BETWEEN @StartDate AND @EndDate
    LEFT JOIN Admission adm 
        ON d.DeptID = adm.WardID  -- assuming ward links to dept
       AND adm.AdmitDate BETWEEN @StartDate AND @EndDate
    LEFT JOIN Bill b 
        ON adm.AdmissionID = b.AdmissionID
       AND b.BillDate BETWEEN @StartDate AND @EndDate
    GROUP BY d.DoctorID, d.FirstName, d.LastName
    ORDER BY d.DoctorID;
END;
GO

-- ===========================
-- 3.2 User - Defined Functions
-- ===========================

-- ===========================
-- 3.2a: Scalar Function (Patient Age)
-- ===========================

CREATE OR ALTER FUNCTION dbo.fn_PatientAge
(
    @DOB DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @DOB, GETDATE()) 
           - CASE WHEN FORMAT(GETDATE(), 'MMdd') < FORMAT(@DOB, 'MMdd') 
                  THEN 1 ELSE 0 END;
END;
GO

-- ===========
-- 3.2b Inline TVF:
-- ===========

CREATE OR ALTER FUNCTION dbo.fn_PatientHistory
(
    @PatientID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 'Appointment' AS RecordType,
           A.AppointmentID AS RecordID,
           A.ApptDate AS RecordDate,
           CONCAT('DoctorID:', A.DoctorID, ' Time:', A.ApptTime) AS Details
    FROM Appointment A
    WHERE A.PatientID = @PatientID

    UNION ALL

    SELECT 'Admission',
           Ad.AdmissionID,
           Ad.AdmitDate,
           CONCAT('WardID:', Ad.WardID, ' Diagnosis:', Ad.DiagnosisCode)
    FROM Admission Ad
    WHERE Ad.PatientID = @PatientID

    UNION ALL

    SELECT 'Prescription',
           P.PrescID,
           P.PrescDate,
           CONCAT('MedID:', P.MedID, ' Qty:', P.Quantity)
    FROM Prescription P
    INNER JOIN Admission Ad ON P.AdmissionID = Ad.AdmissionID
    WHERE Ad.PatientID = @PatientID

    UNION ALL

    SELECT 'Bill',
           B.BillID,
           B.BillDate,
           CONCAT('Total:', B.TotalAmount, ' Paid:', B.PaidAmount)
    FROM Bill B
    WHERE B.PatientID = @PatientID
);
GO

-- ====================
-- 3.2c Scalar function
-- ====================

CREATE OR ALTER FUNCTION dbo.fn_OutstandingBalance
(
    @PatientID INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Balance DECIMAL(10,2);

    SELECT @Balance = SUM(TotalAmount - PaidAmount)
    FROM Bill
    WHERE PatientID = @PatientID;

    RETURN ISNULL(@Balance, 0);
END;
GO

-- ============
-- 3.3 Triggers
-- ============

 CREATE TABLE PatientAuditLog (
 LogID INT IDENTITY(1,1) PRIMARY KEY,
 Action NVARCHAR(10) NOT NULL,
 PatientID INT,
  ChangedBy NVARCHAR(100) DEFAULT SYSTEM_USER,
  ChangedAt DATETIME2 DEFAULT SYSDATETIME(),
  OldData NVARCHAR(MAX),
  NewData NVARCHAR(MAX)
  );
  GO

-- ===================================
-- 3.3a: Audit trigger on Patient table
-- ===================================

CREATE OR ALTER TRIGGER trg_Patient_Audit
ON Patient
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    INSERT INTO PatientAuditLog (Action, PatientID, NewData)
    SELECT 'INSERT', i.PatientID, (SELECT i.* FOR JSON AUTO)
    FROM INSERTED i
    WHERE NOT EXISTS (SELECT 1 FROM DELETED d WHERE d.PatientID = i.PatientID);

    -- DELETE
    INSERT INTO PatientAuditLog (Action, PatientID, OldData)
    SELECT 'DELETE', d.PatientID, (SELECT d.* FOR JSON AUTO)
    FROM DELETED d
    WHERE NOT EXISTS (SELECT 1 FROM INSERTED i WHERE i.PatientID = d.PatientID);

    -- UPDATE
    INSERT INTO PatientAuditLog (Action, PatientID, OldData, NewData)
    SELECT 'UPDATE', i.PatientID, (SELECT d.* FOR JSON AUTO), (SELECT i.* FOR JSON AUTO)
    FROM INSERTED i
    INNER JOIN DELETED d ON i.PatientID = d.PatientID;
END;
GO

-- ==========================
-- 3.3b:INSTEAD OF trigger on a BillingView
-- ==========================

CREATE OR ALTER VIEW BillingView
AS
SELECT 
    B.BillID, B.PatientID, P.FirstName, P.LastName,
    B.TotalAmount, B.PaidAmount, B.BillDate
FROM Bill B
INNER JOIN Patient P ON B.PatientID = P.PatientID;
GO

-- =====================================
-- 3.3c:Trigger to enforce business rule
-- =====================================

CREATE OR ALTER TRIGGER trg_DoctorAppointmentLimit
ON Appointment
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Appointment A
        INNER JOIN INSERTED i ON A.DoctorID = i.DoctorID AND A.ApptDate = i.ApptDate
        GROUP BY A.DoctorID, A.ApptDate
        HAVING COUNT(*) > 10
    )
    BEGIN
        RAISERROR('Doctor cannot have more than 10 appointments on the same date.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO



