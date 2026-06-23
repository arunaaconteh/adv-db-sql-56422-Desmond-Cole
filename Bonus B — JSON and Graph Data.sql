
USE UniHospital;
GO

--========================
-- Part 1. Add a MedicalHistory column
-- =========================== 

ALTER TABLE Patient
ADD MedicalHistory NVARCHAR(MAX);

--============================
-- 2. Insert structured JSON into MedicalHistory 
--=========================
-- Example for PatientID = 301

UPDATE Patient
SET MedicalHistory = '{
  "Allergies": ["Penicillin", "Peanuts"],
  "ChronicConditions": ["Hypertension"],
  "Surgeries": [
    {"Type": "Appendectomy", "Year": 2018},
    {"Type": "Knee Replacement", "Year": 2022}
  ],
  "FamilyHistory": {"Diabetes": true, "Cancer": false}
}'
WHERE PatientID = 301;

--===============================
-- 3. Query JSON using SQL Server functions
-- ==============================

-- Extract a scalar value with JSON_VALUE
SELECT 
  FirstName,
  LastName,
  JSON_VALUE(MedicalHistory, '$.FamilyHistory.Diabetes') AS DiabetesHistory
FROM Patient
WHERE PatientID = 301;

-- Parse arrays with OPENJSON:
SELECT 
  FirstName,
  LastName,
  Allergies.Value AS Allergy
FROM Patient
CROSS APPLY OPENJSON(MedicalHistory, '$.Allergies') AS Allergies
WHERE PatientID = 301;

-- Extract nested JSON with JSON_QUERY:
SELECT 
  FirstName,
  LastName,
  JSON_QUERY(MedicalHistory, '$.Surgeries') AS Surgeries
FROM Patient
WHERE PatientID = 301;

-- =============================
-- Part 2: Doctor Referral Network with Graph Tables
-- =============================

-- 1. Create Graph Tables
-- Doctor node table
CREATE TABLE DoctorNode (
    DoctorID INT PRIMARY KEY,
    Name NVARCHAR(100)
) AS NODE;

-- Referral edge table
CREATE TABLE Referral (
    ReferralID INT PRIMARY KEY,
    Reason NVARCHAR(200)
) AS EDGE;

-- 2. Insert Doctors as Nodes
INSERT INTO DoctorNode (DoctorID, Name)
VALUES 
(101, 'Dr. Aruna Conteh'),
(102, 'Dr. Ali Conteh'),
(103, 'Dr. Fatmata Sesay'),
(104, 'Dr. Ibrahim Koroma'),
(105, 'Dr. Alice Smith');

-- 3. Insert Referrals as Edges
INSERT INTO Referral (ReferralID, $from_id, $to_id, Reason)
VALUES
(1, (SELECT $node_id FROM DoctorNode WHERE DoctorID = 101),
    (SELECT $node_id FROM DoctorNode WHERE DoctorID = 102),
    'Specialist consultation'),
(2, (SELECT $node_id FROM DoctorNode WHERE DoctorID = 102),
    (SELECT $node_id FROM DoctorNode WHERE DoctorID = 104),
    'Cancer screening'),
(3, (SELECT $node_id FROM DoctorNode WHERE DoctorID = 104),
    (SELECT $node_id FROM DoctorNode WHERE DoctorID = 105),
    'Cardiac evaluation');

-- 4. Query shortest referral path
SELECT d.Name AS DoctorName, r.Reason
FROM DoctorNode d, Referral r
WHERE MATCH(SHORTEST_PATH(
    (SELECT $node_id FROM DoctorNode WHERE DoctorID = 101)-[:Referral*]->(SELECT $node_id FROM DoctorNode WHERE DoctorID = 105)
));

