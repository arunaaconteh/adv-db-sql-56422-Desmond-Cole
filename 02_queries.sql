
USE UniHospital;
Go

-- ===============================
-- 2.1 Aggregate and Grouping Queries
-- ===============================

-- ========================
-- total number of doctors, AveStaffsalary, & CurrentAdmissions
-- ========================

WITH DoctorCounts AS (
    SELECT DeptID, COUNT(*) AS TotalDoctors
    FROM Doctor
    GROUP BY DeptID
),


StaffAvg AS (
    SELECT DeptID, AVG(Salary) AS AvgStaffSalary
    FROM Staff
    GROUP BY DeptID
),
CurrentAdm AS (
    SELECT w.DeptID, COUNT(*) AS CurrentAdmissions
    FROM Admission a
    JOIN Ward w ON a.WardID = w.WardID
    WHERE a.DischargeDate IS NULL OR a.DischargeDate > GETDATE()
    GROUP BY w.DeptID
)
SELECT d.DeptID, d.DeptName,
       ISNULL(dc.TotalDoctors, 0)      AS TotalDoctors,
       sa.AvgStaffSalary,
       ISNULL(ca.CurrentAdmissions, 0) AS CurrentAdmissions
FROM Department d
LEFT JOIN DoctorCounts dc ON dc.DeptID = d.DeptID
LEFT JOIN StaffAvg sa     ON sa.DeptID = d.DeptID
LEFT JOIN CurrentAdm ca   ON ca.DeptID = d.DeptID
ORDER BY d.DeptID;

-- ========================
-- 2. Patients with more than 3 appointments in the last 12 months
-- ========================

SELECT p.PatientID, p.FirstName, p.LastName, COUNT(ap.AppointmentID) AS ApptCount
FROM Patient p
JOIN Appointment ap ON ap.PatientID = p.PatientID
WHERE ap.ApptDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY p.PatientID, p.FirstName, p.LastName
HAVING COUNT(ap.AppointmentID) > 3
ORDER BY ApptCount DESC;

-- ========================
-- 3. TotalBilled, TotalPaid & Outstanding balance per patient, where outstanding > $500
-- ========================

SELECT p.PatientID, p.FirstName, p.LastName,
       SUM(b.TotalAmount) AS TotalBilled,
       SUM(b.PaidAmount)  AS TotalPaid,
       SUM(b.TotalAmount - b.PaidAmount) AS OutstandingBalance
FROM Patient p
JOIN Bill b ON b.PatientID = p.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
HAVING SUM(b.TotalAmount - b.PaidAmount) > 500
ORDER BY OutstandingBalance DESC;

-- ====================
-- 2.2 WindowFunctions
-- ====================

-- =============
-- 2.2a Doctors by number of appointment
-- ==============

SELECT
    d.DeptName,
    doc.DoctorID,
    doc.FirstName + ' ' + doc.LastName AS DoctorName,
    COUNT(a.AppointmentID) AS AppointmentCount,
    RANK() OVER (PARTITION BY d.DeptID
                 ORDER BY COUNT(a.AppointmentID) DESC) AS
                    RankByDept,
    DENSE_RANK() OVER (PARTITION BY d.DeptID
                 ORDER BY COUNT(a.AppointmentID) DESC) AS
                    DenseRankByDept
    FROM Doctor doc
        JOIN Department    d ON doc.DeptID        = d.DeptID
        LEFT JOIN Appointment  a  ON  a.DoctorID  =  doc.DoctorID
    GROUP BY  d.DeptID,  d.DeptName,  doc.DoctorID,
              doc.FirstName,  doc.LastName;
   GO

-- =============================================
-- 2.2b: Previous and next admission per patient
-- =============================================

SELECT
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS PatientName,
    adm.AdmissionID,
    adm.AdmitDate,
    LAG(adm.AdmitDate) OVER (
        PARTITION BY p.PatientID
        ORDER BY adm.AdmitDate
    ) AS PreviousAdmission,
    LEAD(adm.AdmitDate) OVER (
        PARTITION BY p.PatientID
        ORDER BY adm.AdmitDate
    ) AS NextAdmission
FROM Admission adm
JOIN Patient p ON adm.PatientID = p.PatientID
ORDER BY p.PatientID, adm.AdmitDate;

-- ============================================
-- 2.2c: 3-month rolling average of total bills
-- ============================================

SELECT
    YEAR(b.BillDate) AS BillYear,
    MONTH(b.BillDate) AS BillMonth,
    SUM(b.TotalAmount) AS MonthlyTotal,
    AVG(SUM(b.TotalAmount)) OVER (
        ORDER BY YEAR(b.BillDate), MONTH(b.BillDate)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Rolling3MonthAvg
FROM Bill b
GROUP BY YEAR(b.BillDate), MONTH(b.BillDate)
ORDER BY BillYear, BillMonth;

-- ===============================================================
-- 2.2d: Segment patients into quartiles by lifetime billed amount
-- ===============================================================
SELECT
    p.PatientID,
    p.FirstName + ' ' + p.LastName AS PatientName,
    SUM(b.TotalAmount) AS TotalBilled,
    NTILE(4) OVER (
        ORDER BY SUM(b.TotalAmount) DESC
    ) AS BillingQuartile
FROM Patient p
LEFT JOIN Bill b ON p.PatientID = b.PatientID
GROUP BY p.PatientID, p.FirstName, p.LastName
ORDER BY BillingQuartile, TotalBilled DESC;

-- =======================
-- 2.3 Common Table Expressions (CTEs)
-- =======================

-- ================
-- 1 Recursive CTE
-- ================

WITH DeptHierarchy AS (
    SELECT DeptID, DeptName, ParentDeptID, 0 AS Level
    FROM Department
    WHERE ParentDeptID IS NULL

    UNION ALL

    -- Recursive member: get sub-departments
    SELECT d.DeptID, d.DeptName, d.ParentDeptID, h.Level + 1
    FROM Department d
    INNER JOIN DeptHierarchy h ON d.ParentDeptID = h.DeptID
)
SELECT * FROM DeptHierarchy
ORDER BY Level, DeptName; 

-- =============================
--  2. Use a CTE to identify readmitted patients ( Within 30 days)
-- =============================

WITH PatientAdmissions AS (
    SELECT PatientID, AdmitDate, DischargeDate
    FROM Admission
),
Readmissions AS (
    SELECT a1.PatientID, a1.AdmitDate, a1.DischargeDate, a2.AdmitDate AS NextAdmit
    FROM PatientAdmissions a1
    INNER JOIN PatientAdmissions a2
        ON a1.PatientID = a2.PatientID
        AND a2.AdmitDate > a1.DischargeDate
        AND DATEDIFF(DAY, a1.DischargeDate, a2.AdmitDate) <= 30
)
SELECT DISTINCT PatientID
FROM Readmissions;

-- =============================
-- 3.Top-5 Highest-Cost Medications per Department, then Global Ranking
-- ==============================

WITH DeptMedCosts AS (
    SELECT d.DeptID, d.DeptName, m.MedID, m.MedName,
           SUM(p.Quantity * m.UnitCost) AS TotalCost
    FROM Prescription p
    INNER JOIN Medication m ON p.MedID = m.MedID
    INNER JOIN Admission a ON p.AdmissionID = a.AdmissionID
    INNER JOIN Ward w ON a.WardID = w.WardID
    INNER JOIN Department d ON w.DeptID = d.DeptID
    GROUP BY d.DeptID, d.DeptName, m.MedID, m.MedName
),
Top5PerDept AS (
    SELECT DeptID, DeptName, MedID, MedName, TotalCost,
           ROW_NUMBER() OVER (PARTITION BY DeptID ORDER BY TotalCost DESC) AS rn
    FROM DeptMedCosts
)
, GlobalRank AS (
    SELECT DeptID, DeptName, MedID, MedName, TotalCost,
           RANK() OVER (ORDER BY TotalCost DESC) AS GlobalRank
    FROM Top5PerDept
    WHERE rn <= 5
)
SELECT * FROM GlobalRank
ORDER BY GlobalRank;

-- =======================
-- 2.3 Common Table Expressions (CTEs)
-- =======================

-- add ParentDeptID column
ALTER TABLE Department ADD ParentDeptID INT NULL;

-- ================
-- 1 Recursive CTE
-- ================

WITH DeptHierarchy AS (
    SELECT DeptID, DeptName, ParentDeptID, 0 AS Level
    FROM Department
    WHERE ParentDeptID IS NULL

    UNION ALL

    -- Recursive member: get sub-departments
    SELECT d.DeptID, d.DeptName, d.ParentDeptID, h.Level + 1
    FROM Department d
    INNER JOIN DeptHierarchy h ON d.ParentDeptID = h.DeptID
)
SELECT * FROM DeptHierarchy
ORDER BY Level, DeptName; 

-- =============================
--  2. Use a CTE to identify readmitted patients ( Within 30 days)
-- =============================

WITH PatientAdmissions AS (
    SELECT PatientID, AdmitDate, DischargeDate
    FROM Admission
),
Readmissions AS (
    SELECT a1.PatientID, a1.AdmitDate, a1.DischargeDate, a2.AdmitDate AS NextAdmit
    FROM PatientAdmissions a1
    INNER JOIN PatientAdmissions a2
        ON a1.PatientID = a2.PatientID
        AND a2.AdmitDate > a1.DischargeDate
        AND DATEDIFF(DAY, a1.DischargeDate, a2.AdmitDate) <= 30
)
SELECT DISTINCT PatientID
FROM Readmissions;

-- =============================
-- 3.Top-5 Highest-Cost Medications per Department, then Global Ranking
-- ==============================

WITH DeptMedCosts AS (
    SELECT d.DeptID, d.DeptName, m.MedID, m.MedName,
           SUM(p.Quantity * m.UnitCost) AS TotalCost
    FROM Prescription p
    INNER JOIN Medication m ON p.MedID = m.MedID
    INNER JOIN Admission a ON p.AdmissionID = a.AdmissionID
    INNER JOIN Ward w ON a.WardID = w.WardID
    INNER JOIN Department d ON w.DeptID = d.DeptID
    GROUP BY d.DeptID, d.DeptName, m.MedID, m.MedName
),
Top5PerDept AS (
    SELECT DeptID, DeptName, MedID, MedName, TotalCost,
           ROW_NUMBER() OVER (PARTITION BY DeptID ORDER BY TotalCost DESC) AS rn
    FROM DeptMedCosts
)
, GlobalRank AS (
    SELECT DeptID, DeptName, MedID, MedName, TotalCost,
           RANK() OVER (ORDER BY TotalCost DESC) AS GlobalRank
    FROM Top5PerDept
    WHERE rn <= 5
)
SELECT * FROM GlobalRank
ORDER BY GlobalRank;

-- ========================
-- 2.4 Subqueries and Set Operations
-- ========================

-- =========================
-- 1 doctors whose appointment count is above the
-- =========================

SELECT d.DoctorID, d.FirstName, d.LastName, d.DeptID
FROM Doctor d
WHERE (
    SELECT COUNT(*)
    FROM Appointment a
    WHERE a.DoctorID = d.DoctorID
) >
(
    SELECT AVG(AppCount)
    FROM (
        SELECT COUNT(*) AS AppCount
        FROM Appointment a2
        WHERE a2.DoctorID IN (
            SELECT DoctorID FROM Doctor WHERE DeptID = d.DeptID
        )
        GROUP BY a2.DoctorID
    ) DeptCounts
);

-- ================================
-- 2 list patients who have been admitted but have never had a formal outpatient appointment.
-- ================================

SELECT p.PatientID, p.FirstName, p.LastName
FROM Patient p
WHERE p.PatientID IN (
    SELECT PatientID FROM Admission
)
EXCEPT
SELECT p.PatientID, p.FirstName, p.LastName
FROM Patient p
WHERE p.PatientID IN (
    SELECT PatientID FROM Appointment
);

-- =========================
--  find staff members who are also registered as patients in the system.
-- =========================

SELECT s.FirstName, s.LastName
FROM Staff s
INTERSECT
SELECT p.FirstName, p.LastName
FROM Patient p;


