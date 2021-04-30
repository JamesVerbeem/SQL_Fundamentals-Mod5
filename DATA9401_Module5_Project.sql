-- DATA9401 Module V Project
/*Use “Grade Record” dataset (either use the entire dataset or the first 50 record).
Create a master table that will hold your entire dataset. -DONE
Normalize the dataset into third normal form.
Identify primary and foreign keys for your tables.
Use JOIN to create a consolidated table.
Present your code to class.*/;

-- Dataset was imported using the Tasks->Import Flat File method
USE DATA9401_ModV_Project

EXEC sp_columns gradeRecordModuleV /* Lists 10 columns and their data types, this is useful for the ERD design */;

-- Now that the ERD is done, the data broken up into the corresponding tables
CREATE TABLE Students (
	StudentID int PRIMARY KEY,
	LastName varchar(50) NOT NULL,
	FirstName varchar(50) NULL
);

CREATE TABLE Courses (
	CourseID int IDENTITY(2021001,1) NOT NULL PRIMARY KEY,
	CourseName varchar(100) NOT NULL,
	ProfID int
);

CREATE TABLE Grades2021001(
	StudentID int NOT NULL FOREIGN KEY REFERENCES Students(StudentID),
	CourseID int NOT NULL FOREIGN KEY REFERENCES Courses(CourseID), /* The "Courses" part of "Courses(CourseID)" was underlined by SSMS because I had missed adding the PRIMARY KEY constraint to any of the attributes in that table. Underline vanished once this was corrected. */
	MidtermExam decimal(3,2) NULL,
	FinalExam decimal(3,2) NULL,
	Assignment1 decimal(3,2) NULL,
	Assignment2 decimal(3,2) NULL,
	PRIMARY KEY (StudentID, CourseID),
);

CREATE TABLE LetterGrades(
	LGrade varchar(2) NOT NULL PRIMARY KEY,
	MinAvg decimal(4,3) NOT NULL UNIQUE,
	PassFail bit NOT NULL /* 1 will be pass, 0 will be fail */
);

SELECT *
	FROM Students
SELECT *
	FROM Courses
SELECT *
	FROM Grades2021001
SELECT *
	FROM LetterGrades
/* All the tables look correct, but are empty */;

/* Ensure the data is ready to be inserted into the tables */
SELECT *
	FROM gradeRecordModuleV;

SELECT COUNT(studentID)
	FROM gradeRecordModuleV
/* 1029 total records */;

SELECT COUNT(DISTINCT studentID)
	FROM gradeRecordModuleV
/* 1026 total records. THIS IS A PROBLEM!!! */;

SELECT studentID
	FROM gradeRecordModuleV
	GROUP BY studentID
	HAVING COUNT(*) > 1
/* Shows the three StudentIDs that are duplicated in the dataset: 35932, 47058, 64698  */;

SELECT *
	FROM gradeRecordModuleV
	WHERE studentID = 35932
	OR studentID = 47058
	OR studentID = 64698
/* Supplies the information for the duplicated records */;

SELECT First_name, Lastname
	FROM gradeRecordModuleV
	GROUP BY First_name, Lastname
	HAVING COUNT(*) > 1
/* No duplicates found when combining both First_name and Lastname. This means that the duplicate StudentID fields are likely entry errors.  */;

SELECT studentID, Lastname
	FROM gradeRecordModuleV
	GROUP BY studentID, Lastname
	HAVING COUNT(*) > 1
/* As there is no duplication of the last name of the students and their studentID these two attributes can safely be used as qualifiers to update the duplicate studentID fields using UPDATE and CASE/WHEN */;

/* Each of the duplicate studentID records should be changed to a new number. Add "1" and "2" to the end of each duplicate will allow the column to remain an integer data type, avoids having to search for another unused value, and still references their old studentID just in case there are some records that are not affected by a cascading change.*/
UPDATE gradeRecordModuleV
	SET studentID = CASE
			WHEN studentID = 64698 AND Lastname = 'Longea' THEN 646981
			WHEN studentID = 64698 AND Lastname = 'Burree' THEN 646982
			WHEN studentID = 35932 AND Lastname = 'Ducker' THEN 359321
			WHEN studentID = 35932 AND Lastname = 'Lynes' THEN 359322
			WHEN studentID = 47058 AND Lastname = 'Dumbleton' THEN 470581
			WHEN studentID = 47058 AND Lastname = 'Margett' THEN 470582
		END
/* Update didn't work... NULL values not permitted. Must use a WHERE clause instead of having all the qualifiers inside the CASE staement. */;

UPDATE gradeRecordModuleV
	SET studentID = CASE
			WHEN Lastname = 'Longea' THEN 646981
			WHEN Lastname = 'Burree' THEN 646982
			WHEN Lastname = 'Ducker' THEN 359321
			WHEN Lastname = 'Lynes' THEN 359322
			WHEN Lastname = 'Dumbleton' THEN 470581
			WHEN Lastname = 'Margett' THEN 470582
		END
		WHERE studentID IN (64698, 35932, 47058)
/* Update successful. Run the check for duplicates again, then check an individual record to ensure the correct attributes were updated. */;

SELECT studentID
	FROM gradeRecordModuleV
	GROUP BY studentID
	HAVING COUNT(*) > 1
SELECT *
	FROM gradeRecordModuleV
	WHERE studentID = 646981
/* No duplicate studentID entries and the test student record looks correct */;

/* Now it is time to break out the raw data into the associated tables */
SELECT *
	FROM Students

INSERT INTO Students (
		StudentID,
		LastName,
		FirstName)
	SELECT studentID,
		Lastname,
		First_name
		FROM gradeRecordModuleV
/* 1029 rows affected as expected. Student table is finished. */;

SELECT *
	FROM Courses

INSERT INTO Courses (
		CourseName,
		ProfID)
	VALUES (
		'DATA9401',
		1)
/* 1 row affected as expected. Check of table shows CourseID autopopulated as expected */;

SELECT *
	FROM LetterGrades

SELECT Grade
	FROM gradeRecordModuleV
	GROUP BY Grade
	HAVING COUNT (*) > 1
/* 10 records returned, letter grade scale found online to supplement missing pieces */

INSERT INTO LetterGrades
		VALUES (
		'A+', 0.97, 1),(
		'A', 0.93, 1),(
		'A-', 0.90, 1),(
		'B+', 0.87, 1),(
		'B', 0.83, 1),(
		'B-', 0.80, 1),(
		'C+', 0.77, 1),(
		'C', 0.73, 1),(
		'C-', 0.70, 1),(
		'D+', 0.67, 1),(
		'D', 0.65, 1),(
		'D-', 0.60, 1),(
		'F', 0, 0)
/* Table looks complete */;

UPDATE LetterGrades
	SET MinAvg = 0.63
	WHERE LGrade = 'D'
	/* Had to update the value for D based on the original data */;

SELECT *
	FROM Grades2021001

/* This does not work. Try paring it down to just the NOT NULL attributes of StudentID and CourseID
BEGIN TRAN
INSERT INTO Grades2021001 (StudentID, CourseID, MidtermExam, FinalExam, Assignment1, Assignment2)
	VALUES(
		(SELECT StudentID FROM Students),
		(SELECT CourseID FROM Courses),
		(SELECT Midtermexam, Finalexam, assignment1, assignment2 FROM gradeRecordModuleV WHERE (StudentID) = (studentID))
	)*/;

/* This still doesn't work. I think a temporary table would be the solution
BEGIN TRAN
INSERT INTO Grades2021001 (StudentID, CourseID)
	VALUES(
		(SELECT StudentID FROM Students),
		(SELECT CourseID FROM Courses)
	)*/

CREATE TABLE #TempTable (StudentID int, CourseID int, MidtermExam dec(3,2), FinalExam dec(3,2), Assignment1 dec(3,2), Assignment2 dec(3,2))

SELECT *
	FROM #TempTable
SELECT *
	FROM Grades2021001
/* Tables match */

DROP TABLE #TempTable
	/* Table needs to be dropped before performing SELECT INTO */


/* The query below fails because the attribute names of StudentID and studentID are functionally identical between two of the three source tables. To avoid the same error later, the temp table should also avoid using the same attribute names as the final destination table and should be truncated.

SELECT StudentID, CourseID, MidtermExam, FinalExam, Assignment1, Assignment2
	INTO #TempTable
	FROM Students, Courses, gradeRecordModuleV
*/;

CREATE TABLE #TempTable (S_ID int, C_ID int, M_Exam dec(3,2), F_Exam dec(3,2), Assign_1 dec(3,2), Assign_2 dec(3,2))

SELECT *
	FROM #TempTable
	/* Table is ready for data */

DROP TABLE #TempTable
	/* Table needs to be dropped before performing SELECT INTO */

SELECT StudentID, CourseID, MidtermExam, FinalExam, Assignment1, Assignment2
	INTO #TempTable
	FROM Courses, gradeRecordModuleV
	/* 1029 records as expected */

SELECT *
	FROM #TempTable
	/* Table is ready to be transferred to the Grades2021001 table */

TRUNCATE TABLE Grades2021001

INSERT INTO Grades2021001 (StudentID, CourseID, MidtermExam, FinalExam, Assignment1, Assignment2)
	SELECT *
		FROM #TempTable
	/* 1029 record as expected */

SELECT TOP (15) StudentID, MidtermExam, FinalExam, Assignment1, Assignment2
	FROM Grades2021001
	ORDER BY StudentID
SELECT TOP (15) studentID, Midtermexam, Finalexam, assignment1, assignment2
	FROM gradeRecordModuleV
	ORDER BY studentID
	/* Records are identical */

SELECT TOP (15) StudentID, MidtermExam, FinalExam, Assignment1, Assignment2
	FROM Grades2021001
	ORDER BY StudentID desc
SELECT TOP (15) studentID, Midtermexam, Finalexam, assignment1, assignment2
	FROM gradeRecordModuleV
	ORDER BY studentID desc
	/* Records are identical. Ask professor for more efficient way to check. */;

/* Aliases can also fix the ambiguous attribute name issue as shown below */
CREATE VIEW FinGrad2021001 AS
	SELECT a.LastName, a.FirstName, b.StudentID, b.CourseID, (b.MidtermExam + b.FinalExam + b.Assignment1 + b.Assignment2)/4 AS ClAVG
		FROM Students a, Grades2021001 b
SELECT *
	FROM FinGrad2021001
	ORDER BY LastName, FirstName
	/* Too many records, WHERE clause required. */;

IF OBJECT_ID('dbo.FinGrad2021001') IS NOT NULL
	DROP VIEW dbo.FinGrad2021001
	GO
CREATE VIEW FinGrad2021001 AS
	SELECT a.LastName, a.FirstName, b.StudentID, b.CourseID, (b.MidtermExam + b.FinalExam + b.Assignment1 + b.Assignment2)/4*100 AS ClAVG
		FROM Students a, Grades2021001 b
		WHERE A.StudentID = B.StudentID
	GO
SELECT *
	FROM FinGrad2021001
	ORDER BY LastName, FirstName
	/* Table showing correct number of records, but AVG column is displaying too many zeroes. Change AVG to reference a USER DEFINED FUNCTION (udf) instead and set data type to dec(3,1) */;

/* Build AVG udf for the VIEW to reference */
IF OBJECT_ID('dbo.udf_AVG2021001') IS NOT NULL
	DROP FUNCTION dbo.udf_AVG2021001
	GO
CREATE FUNCTION	udf_AVG2021001(
		@Mid_2021001 dec(3,2),
		@Fin_2021001 dec(3,2), 
		@As1_2021001 dec(3,2),
		@As2_2021001 dec(3,2))
	RETURNS dec(3,1) AS
		BEGIN
			RETURN ((@Mid_2021001 + @Fin_2021001 + @As1_2021001 + @As2_2021001)*100/4)
			END

IF OBJECT_ID('dbo.FinGrad2021001') IS NOT NULL
	DROP VIEW dbo.FinGrad2021001
	GO
CREATE VIEW FinGrad2021001 AS
	SELECT a.LastName, a.FirstName, b.StudentID, b.CourseID, dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2) AS ClsAVG
		FROM Students a, Grades2021001 b
		WHERE A.StudentID = B.StudentID
	GO
SELECT *
	FROM FinGrad2021001
	ORDER BY LastName, FirstName
/* View now displays AVG correctly. Add columns displaying Letter Grade and Pass/Fail from dbo.LetterGrades. */;

SELECT *
	FROM LetterGrades
	ORDER BY MinAvg desc
SELECT LGrade
	FROM LetterGrades
	WHERE MinAvg > .87
	ORDER BY MinAvg desc

/* Build letter Grade udf for VIEW to reference */
IF OBJECT_ID('dbo.udf_LetGrade') IS NOT NULL
	DROP FUNCTION dbo.udf_LetGrade
	GO
CREATE FUNCTION	udf_LetGrade(
		@ClAVG dec(3,1))
	RETURNS varchar(2) AS
		BEGIN
			RETURN
				CASE
					WHEN @ClAVG/100 >= 0.970 THEN 'A+'
					WHEN @ClAVG/100 >= 0.930 THEN 'A'
					WHEN @ClAVG/100 >= 0.900 THEN 'A-'
					WHEN @ClAVG/100 >= 0.870 THEN 'B+'
					WHEN @ClAVG/100 >= 0.830 THEN 'B'
					WHEN @ClAVG/100 >= 0.800 THEN 'B-'
					WHEN @ClAVG/100 >= 0.770 THEN 'C+'
					WHEN @ClAVG/100 >= 0.730 THEN 'C'
					WHEN @ClAVG/100 >= 0.700 THEN 'C-'
					WHEN @ClAVG/100 >= 0.670 THEN 'D+'
					WHEN @ClAVG/100 >= 0.630 THEN 'D'
					WHEN @ClAVG/100 >= 0.600 THEN 'D-'
					ELSE 'F'
				END
		END
;

/* Drag and drop values from the table below into the WHEN THEN clauses above, copied from TABLE LetterGrades.
A+	0.970
A	0.930
A-	0.900
B+	0.870
B	0.830
B-	0.800
C+	0.770
C	0.730
C-	0.700
D+	0.670
D	0.630
D-	0.600
F	0.000
*/;


SELECT dbo.udf_LetGrade (93) AS LGr

IF OBJECT_ID('dbo.FinGrad2021001') IS NOT NULL
	DROP VIEW dbo.FinGrad2021001
	GO
CREATE VIEW FinGrad2021001 AS
	SELECT a.LastName, a.FirstName, b.StudentID, b.CourseID, dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2) AS ClAVG, dbo.udf_LetGrade(dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2)) AS LetGr
		FROM Students a, Grades2021001 b
		WHERE A.StudentID = B.StudentID
	GO
SELECT *
	FROM FinGrad2021001
	ORDER BY LastName, FirstName
/* VIEW now correctly displays the corresponding Letter Grade. Though it uses CASE WHEN in a USER DEFINED FUNCTION rather than the TABLE dbo.LetterGrades */;

IF OBJECT_ID('dbo.udf_LetGrade2') IS NOT NULL
	DROP FUNCTION dbo.udf_LetGrade2
	GO
CREATE FUNCTION	udf_LetGrade2(
		@ClAvg dec(3,1))
	RETURNS varchar(2)
	AS
	BEGIN
		DECLARE @LGr varchar(2);
		SELECT @LGr = a.LGrade
			FROM LetterGrades a
			WHERE @ClAvg/100 >= a.MinAvg;
		RETURN @LGr;
	END;
	GO

IF OBJECT_ID('dbo.udf_PassFail') IS NOT NULL
	DROP FUNCTION dbo.udf_PassFail
	GO
CREATE FUNCTION	udf_PassFail(
		@ClAvg2 dec(3,1))
	RETURNS int
	AS
	BEGIN
		DECLARE @PF int;
		SELECT @PF = a.PassFail
			FROM LetterGrades a
			WHERE @ClAvg2/100 >= a.MinAvg;
		RETURN @PF;
	END;
	GO

SELECT *
	FROM LetterGrades

/* Both the Letter Grade and PassFail USER DEFINED FUNCTIONs have been built and are ready to used in a new VIEW. */
IF OBJECT_ID('dbo.FinGrad2021001_2') IS NOT NULL
	DROP VIEW dbo.FinGrad2021001_2
	GO
CREATE VIEW FinGrad2021001_2 AS
	SELECT a.LastName
			,a.FirstName
			,b.StudentID
			,b.CourseID
			,dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2) AS StAvg
			,dbo.udf_LetGrade2(dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2)) AS LetGr
			,CASE
				WHEN dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2) <60 THEN 0
				WHEN dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2) >=60 then 1
				END AS PassFail
			---- The code below was removed as it only returns 0 from the TABLE dbo.LetterGrades even though the same code works for the attribute LetGr
			--,dbo.udf_PassFail(dbo.udf_AVG2021001(b.MidtermExam, b.FinalExam, b.Assignment1, b.Assignment2)) AS PassFail
		FROM Students a, Grades2021001 b
		WHERE A.StudentID = B.StudentID
	GO
SELECT *
	FROM FinGrad2021001_2
	ORDER BY LastName, FirstName
;

IF OBJECT_ID('dbo.sp_StGr') IS NOT NULL
	DROP PROC dbo.sp_StGr
	GO
CREATE PROC sp_StGr @StudentID int, @CourseID int
	AS
	SELECT *
		FROM FinGrad2021001_2
		WHERE StudentID = @StudentID AND
			CourseID = @CourseID
;

EXEC sp_StGr @StudentID = 61824, @CourseID = 2021001
EXEC sp_StGr @StudentID = 54266, @CourseID = 2021001
EXEC sp_StGr @StudentID = 96409, @CourseID = 2021001
EXEC sp_StGr @StudentID = 470581, @CourseID = 2021001
EXEC sp_StGr @StudentID = 470582, @CourseID = 2021001

-- Next time the calculated StAvg column should be part of the marking table and made PERSISTENT, along with weights for each of the assignments and exams. Then the class grades table can reference that persistent column instead. That would simplify a lot of the code for the final grades view.