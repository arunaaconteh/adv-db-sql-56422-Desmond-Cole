
USE UniHospital;
GO

 DECLARE @AdmissionID INT;  --  Dclares
 ALTER FULLTEXT INDEX ON Appointment

 -- =====================================
 -- --4.1a: Patients with unpaid bills (Bill.Status = ’Unpaid’)
 -- =====================================

SELECT PatientID, TotalAmount, PaidAmount 
FROM Bill 
WHERE Status = 'Unpaid';

CREATE NONCLUSTERED INDEX IX_Bill_Unpaid
ON Bill (PatientID)
INCLUDE (TotalAmount, PaidAmount, BillDate);

-- ========================================
-- 4.1b: Admissions currently in a specific ward (DischargeDate IS NULL)
-- ========================================

CREATE NONCLUSTERED INDEX IX_Admission_Ward_Active
ON Admission (WardID, DischargeDate)
INCLUDE (PatientID, AdmitDate, DiagnosisCode);

-- =======================================
-- 4.1c: Prescriptions for a given admission ordered by date
-- =======================================

SELECT * 
FROM Prescription 
WHERE AdmissionID = @AdmissionID 
ORDER BY PrescDate;

CREATE NONCLUSTERED INDEX IX_Prescription_Admission_Date
ON Prescription (AdmissionID, PrescDate)
INCLUDE (MedID, Quantity);

-- ====================================
-- 4.1d: Full-text search on Appointment.Notes (use Full-Text Index)
-- ====================================

SELECT * 
FROM Appointment 
WHERE CONTAINS(Notes, 'cough OR fever');

CREATE FULLTEXT CATALOG FT_AppointmentNotes;
CREATE FULLTEXT INDEX ON Appointment(Notes LANGUAGE 1033)
KEY INDEX PK_Appointment;

-- ========================
-- 4.3 Query to Test (Before and After Index)
-- ========================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    YEAR(BillDate) AS BillYear,
    MONTH(BillDate) AS BillMonth,
    COUNT(*) AS BillCount,
    SUM(TotalAmount) AS TotalBilled,
    SUM(PaidAmount) AS TotalPaid,
    SUM(TotalAmount - PaidAmount) AS Outstanding
FROM Bill
GROUP BY YEAR(BillDate), MONTH(BillDate)
ORDER BY BillYear, BillMonth;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;




