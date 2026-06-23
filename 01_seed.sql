
USE UniHospital;
Go

-- =========================
-- Department ( 5 entries )
-- =========================


INSERT INTO Department (DeptName, Location)
VALUES
( 'Dermatology', 'Block A, Floor 1'),
( 'Urology', 'Block B, Floor 3'),
( 'Orthopaedics', 'Block C, Floor 1'),
( 'Oncology', 'Block D, Floor 4'),
( 'Cardiology', 'Block A, Floor 2');
GO

-- =========================
-- Doctors ( 10 entries )
-- =========================

INSERT INTO Doctor (FirstName, LastName, Specialisation, Phone, Hiredate, DeptID)
VALUES
('Dr. Aruna', 'Conteh', 'Dermatologgist','232-77-577475','2024-01-01', 6),
('Dr. Ali', 'Conteh', 'Urologist','232-77-577465','2024-01-02', 7),
('Dr. Fatmata', 'Sesay', 'Orthopaedic Surgeon','232-77-577455','2024-01-03', 8),
('Dr. Ibrahim', 'Koroma', 'Oncologist','232-77-577445','2024-01-04', 9),
('Dr. Alice', 'Smith', 'Cardiologyist','232-77-577435','2024-01-05', 10),
('Dr. Samuel', 'Johnson', 'Dermatologgist','232-77-577425','2024-01-06', 6),
('Dr. Hawa', 'Jalloh', 'Urologist','232-77-577415','2024-01-07', 7),
('Dr. Peter', 'Bangura', 'Orthopaedic Surgeon','232-77-477475','2024-01-08', 8),
('Dr. Aminata', 'Mansaray', 'Oncologist','232-77-377475','2024-01-09', 9),
('Dr. Kai', 'Momoh', 'Cardiologyist','232-77-277475','2024-01-10', 10);
GO

-- ====================
-- Wards ( 5 entries )
-- ====================

INSERT INTO Ward (WardName, Capacity, DeptID)
VALUES
('Ward A', 20, 6 ),
('Ward B', 15, 7 ),
('Ward C', 25, 8 ),
('Ward D', 10, 9 ),
('Ward A', 30, 6 );
GO

-- ======================
-- Patients (20 entries)
-- ======================

INSERT INTO Patient (FirstName, LastName, DOB, Gender, Address, Phone, InsuranceNo)
VALUES
('Mohamed', 'Kamara','01-01-1990','M', '1 Freetown Road', '232-76-111111', 'A1111'),
('Isatu', 'Conteh','01-01-1991','F', '2 Freetown Road', '232-76-222222', 'B1111'),
('Abdul', 'Sesay','01-01-1992','M', '3 Freetown Road', '232-76-333333', 'C1111'),
('Mariatu', 'Koroma','01-01-1993','F', '4 Freetown Road', '232-76-444444', 'D1111'),
('Joseph', 'Smith','01-01-1994','M', '5 Freetown Road', '232-76-555555', 'E1111'),
('Fatmata', 'Jalloh','01-01-1995','F', '6 Freetown Road', '232-76-666666', 'F1111'),
('Samuel', 'Johnson','01-01-1996','M', '7 Freetown Road', '232-76-777777', 'G1111'),
('Hawa', 'Bangura','01-01-1997','F', '8 Freetown Road', '232-76-888888','H1111'),
('Peter', 'Mansaray','01-01-1998','M', '9 Freetown Road', '232-76-999999','I1111'),
('Aminata', 'Brown','01-01-1999','F', '10 Freetown Road', '232-76-101010','J1111'),
('James', 'Doe','01-01-2000','M', '11 Freetown Road', '232-76-111222','K1111'),
('Alice', 'Taylor','01-01-2001','F', '12 Freetown Road', '232-76-222333', 'L1111'),
('David', 'King','01-01-2002','M', '13 Freetown Road', '232-76-333444', 'M1111'),
('Sarah', 'Queen','01-01-2003','F', '14 Freetown Road', '232-76-444555', 'N1111'),
('Michael', 'Prince','01-01-2004','M', '15 Freetown Road', '232-76-555666', 'O1111'),
('Mary', 'George','01-01-2005','F', '16 Freetown Road', '232-76-666777', 'P1111'),
('Paul', 'Harris','01-01-2006','M', '17 Freetown Road', '232-76-777888', 'Q1111'),
('Linda', 'White','01-01-2007','F', '18 Freetown Road', '232-76-888999', 'R1111'),
('Robert', 'Black','01-01-2008','M', '19 Freetown Road', '232-76-999000', 'S1111'),
('Lucy', 'Green','01-01-2009','F', '20 Freetown Road', '232-76-000111', 'T1111');
GO

-- ===========================
-- Appointments (30 entries)
-- ===========================

INSERT INTO Appointment (PatientID, DoctorID, ApptDate, ApptTime, Status, Notes)
VALUES
(321,169, '2026-06-01', '09:00:00', 'Scheduled', 'First consultation for hypertension'),
(322,170, '2026-06-02', '10:30:00', 'Scheduled', 'Follow-up on migraine treatment'),
(323,171, '2026-06-03', '11:15:00', 'Scheduled', 'Patient cancelled due to travel'),
(324,172, '2026-06-04', '14:00:00', 'Scheduled', 'Initial oncology screening'),
(325,173, '2026-06-05', '15:45:00', 'Scheduled', 'Patient did not attend'),
(326,174, '2026-06-06', '08:30:00', 'Scheduled', 'Routine cardiac check-up'),
(327,175, '2026-06-07', '13:00:00', 'Scheduled', 'Neurology consultation'),
(328,176, '2026-06-08', '09:45:00', 'Scheduled', 'Orthopaedic follow-up'),
(329,177, '2026-06-09', '16:00:00', 'Scheduled', 'Chemotherapy session'),
(330,178, '2026-06-10', '10:00:00', 'Scheduled', 'General health check-up'),
(331,179, '2026-06-11', '11:30:00', 'Scheduled', 'Cardiology review'),
(332,180, '2026-06-12', '12:15:00', 'Scheduled', 'Seizure management follow-up'),
(333,181, '2026-06-13', '09:00:00', 'Scheduled', 'Post-surgery check'),
(334,182, '2026-06-14', '15:00:00', 'Scheduled', 'Doctor unavailable'),
(335,183, '2026-06-15', '08:45:00', 'Scheduled', 'Diabetes monitoring'),
(336,184, '2026-06-16', '14:30:00', 'Scheduled', 'Cardiac stress test'),
(337,185, '2026-06-17', '10:00:00', 'Scheduled', 'Patient missed appointment'),
(338,186, '2026-06-18', '13:15:00', 'Scheduled', 'Bone fracture review'),
(339,187, '2026-06-19', '09:45:00', 'Scheduled', 'Radiation therapy session'),
(340,188, '2026-06-20', '11:00:00', 'Scheduled', 'Routine check-up'),
(341,189, '2026-06-21', '10:30:00', 'Scheduled', 'Neurology referral'),
(342,190, '2026-06-22', '09:15:00', 'Scheduled', 'Orthopaedic physiotherapy'),
(343,191, '2026-06-23', '14:00:00', 'Scheduled', 'Oncology consultation'),
(344,192, '2026-06-24', '15:30:00', 'Scheduled', 'Patient rescheduled'),
(345,193, '2026-06-25', '08:00:00', 'Scheduled', 'Cardiology ECG test'),
(346,194, '2026-06-26', '13:45:00', 'Scheduled', 'Neurology MRI review'),
(347,195, '2026-06-27', '09:30:00', 'Scheduled', 'Orthopaedic rehabilitation'),
(348,196, '2026-06-28', '16:15:00', 'Scheduled', 'Oncology lab results discussion'),
(349,197, '2026-06-29', '10:00:00', 'Scheduled', 'General medicine follow-up'),
(350,198, '2026-06-30', '11:45:00', 'Scheduled', 'Cardiology blood pressure review');
GO
 

-- =========================
-- Admissions (15 entries)
-- =========================

INSERT INTO Admission (PatientID, WardID, AdmitDate, DischargeDate, DiagnosisCode)
VALUES
(321, 206, '2026-06-01', '2026-07-05','Dia501'),
(322, 207, '2026-06-02', '2026-07-06','Dia502'),
(323, 208, '2026-06-03', '2026-07-07','Dia503'),
(324, 209, '2026-06-04', '2026-07-08','Dia504'),
(325, 210, '2026-06-05', '2026-07-09','Dia506'),
(326, 211, '2026-06-06', '2026-07-10','Dia507'),
(327, 212, '2026-06-07', '2026-07-11','Dia507'),
(328, 213, '2026-06-08', '2026-07-12','Dia508'),
(329, 214, '2026-06-09', '2026-07-13','Dia509'),
(330, 215, '2026-06-10', '2026-07-14','Dia510'),
(331, 216, '2026-06-11', '2026-07-15','Dia511'),
(332, 217, '2026-06-12', '2026-07-16','Dia512'),
(333, 218, '2026-06-13', '2026-07-17','Dia513'),
(334, 219, '2026-06-14', '2026-07-18','Dia513'),
(335, 220, '2026-06-15', '2026-07-19','Dia513');
GO 

-- =========================
-- Medications (10 entries)
-- =========================

INSERT INTO Medication (MedName, DosageForm, UnitCost, StockQty)
VALUES
('Aspirin','Tablet','5.00','5000'),
('Paracetamol','Tablet', '3.00','6000'),
('Ibuprofen','Capsule', '4.50','7000'),
('Metformin','Tablet','10.00','8000'),
('Insulin','Capsule','25.00','9000'),
('Amoxicillin','Syrup','8.00','10000'),
('Ciprofloxacin','Tablet','12.00','11000'),
('Atorvastatin','Suspension','15.00','12000'),
('Omeprazole','Ointment','7.00','13000'),
('Losartan','Solution','20.00','14000');
GO

-- =========================
-- Prescriptions (20 entries)
-- =========================

INSERT INTO Prescription (AdmissionID, MedID, DoctorID, Quantity, PrescDate)
VALUES
(524, 601, 169, 2, '2025-01-01'),
(525, 602, 170, 5, '2025-01-02'),
(526, 603, 171, 3, '2025-01-03'),
(527, 604, 172, 2, '2025-01-04'),
(528, 605, 173, 1, '2025-01-05'),
(529, 606, 174, 2, '2025-01-06'),
(530, 607, 175, 4, '2025-01-07'), 
(531, 608, 176, 2, '2025-01-08'),
(532, 609, 177, 2, '2025-01-09'),
(533, 610, 178, 2, '2025-01-10'),
(534, 601, 178, 2, '2025-01-11'),
(535, 602, 179, 1, '2025-01-12'),
(536, 603, 180, 3, '2025-01-13'),
(537, 604, 181, 2, '2025-01-14'),
(538, 605, 182, 1, '2025-01-15'),
(539, 606, 183, 2, '2025-01-16'),
(540, 607, 184, 1, '2025-01-17'),
(541, 608, 185, 2, '2025-01-18'),
(542, 609, 186, 3, '2025-01-19'),
(543, 610, 187, 2, '2025-01-20');
GO

-- =========================
-- Bills (15 entries)
-- =========================

INSERT INTO Bill (PatientID, AdmissionID, TotalAmount, PaidAmount, BillDate, Status)
VALUES
(321, 524, 150.00, 120.00, '2026-06-05','Unpaid'),
(322, 525, 200.00, 150.00, '2026-06-06','Unpaid'),
(323, 526, 250.00, 230.00, '2026-06-07','Unpaid'),
(324, 527, 300.00, 200.00, '2026-06-08','Unpaid'),
(325, 528, 800.00, 100.00, '2026-06-09','Unpaid'),
(326, 529, 350.00, 200.00, '2026-06-10','Unpaid'),
(327, 530, 500.00, 400.00, '2026-06-11','Unpaid'),
(328, 531, 550.00, 500.00, '2026-06-12','Unpaid'),
(329, 532, 900.00, 100.00, '2026-06-13','Unpaid'),
(330, 533, 180.00, 150.00, '2026-06-14','Unpaid'),
(331, 534, 150.00, 150.00, '2026-06-15','Unpaid'),
(332, 535, 200.00, 150.00, '2026-06-16','Unpaid'),
(333, 536, 250.00, 240.00, '2026-06-17','Unpaid'),
(334, 536, 600.00, 500.00, '2026-06-18','Unpaid'),
(335, 537, 800.00, 170.00, '2026-06-19','Unpaid');
GO

-- =========================
-- Staff (10 entries)
-- =========================

INSERT INTO Staff (FirstName, LastName, Role, DeptID, Salary, StartDate)
VALUES
('John', 'Doe', 'Nurse', 6, 3000, '2024-01-01'),
('Jane', 'Smith', 'Technician', 7, 1500, '2024-01-02'),
('Ali', 'Kamara', 'Receptionist', 8, 2000, '2024-01-03'),
('Mary', 'Johnson', 'Pharmacist', 9, 4000, '2024-01-04'),
('David','Brown', 'Cleaner', 10, 1000,'2024-01-05'),
('Sarah', 'Taylor', 'Nurse', 6, 3000, '2024-01-06'),
('Paul', 'Harris', 'Technician', 7, 1500, '2024-01-07'),
('Linda', 'White', 'Receptionist', 8, 2000, '2024-01-08'),
('Robert','Black', 'Pharmacist', 9, 4000, '2024-01-09'),
('Lucy','Green', 'Cleaner', 10, 1000, '2024-01-10');
GO











