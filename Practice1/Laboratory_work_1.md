# **Laboratory Work 1**

## Relational Model, Keys, ER Diagrams and Normalization

**Author:** Database Systems Course  
**Date:** Fall Semester 2026

---

# Key Identification Exercises

## Superkey and Candidate Key Analysis

**Relation A: Employee**

`Employee(EmpID, SSN, Email, Phone, Name, Department, Salary)`

### Superkeys

Some possible superkeys are:

- `{EmpID}`
- `{SSN}`
- `{Email}`
- `{EmpID, Name}`
- `{SSN, Department}`
- `{Email, Salary}`
- `{EmpID, SSN, Email}`

The last four examples contain additional attributes, so they are still superkeys, although they are not minimal.

### Candidate Keys

The candidate keys are:

- `{EmpID}` — identifies an employee within the organization.
- `{SSN}` — uniquely identifies a person.
- `{Email}` — identifies the employee's corporate email address.

### Primary Key

I would choose `{EmpID}` as the primary key. It is an internal identifier, is short and convenient to use in other tables, and does not expose a sensitive personal identifier such as SSN.

### Phone Number

Phone is not a reliable candidate key. Even if all three sample records have different phone numbers, two employees may share a phone number, for example when they use the same office phone or another shared number.

---

## Course Registration

`Registration(StudentID, CourseCode, Section, Semester, Year, Grade, Credits)`

### Primary Key

The primary key is:

`{StudentID, CourseCode, Semester, Year}`

### Why These Attributes Are Needed

- `StudentID` identifies the student.
- `CourseCode` identifies the course taken by that student.
- `Semester` and `Year` distinguish different academic terms, so the same course can be taken again later.
- `Section` is not needed if the business rule guarantees that a student cannot register for two sections of the same course in the same term.

If `Section` is unique for a particular course offering within a semester and year, an alternative key could be:

`{StudentID, Section, Semester, Year}`

Otherwise, the key above is the appropriate choice.

---

## Foreign Key Design

The main foreign key relationships are:

| Relation | Foreign Key | References |
|---|---|---|
| Student | `AdvisorID` | `Professor(ProfID)` |
| Course | `DepartmentCode` | `Department(DeptCode)` |
| Department | `ChairID` | `Professor(ProfID)` |
| Enrollment | `StudentID` | `Student(StudentID)` |
| Enrollment | `CourseID` | `Course(CourseID)` |

---

# ER Diagram Construction

## Hospital Management System

### Entities

The strong entities are:

- `Patient`
- `Doctor`
- `Department`
- `Appointment`
- `Prescription`

`Room` is a weak entity. It depends on `Department` because room numbers are not necessarily unique across the whole hospital. The department together with the room number can identify a room.

### Attributes

| Entity | Attributes |
|---|---|
| **Patient** | `PatientID` (PK), `Name` (composite: First, Last), `BirthDate`, `Address` (composite: Street, City, State, Zip), `Phone` (multi-valued), `InsuranceInfo` (composite: Provider, PolicyNo, GroupNo) |
| **Doctor** | `DoctorID` (PK), `Name` (composite: First, Last), `Specialization` (multi-valued), `Phone`, `OfficeLocation` |
| **Department** | `DeptCode` (PK), `Name`, `Location` |
| **Appointment** | `AppointmentID` (PK), `Date`, `Time`, `Purpose`, `Notes` |
| **Prescription** | `PrescriptionID` (PK), `MedicationName`, `Dosage`, `Instructions` |
| **Room** | `RoomNumber` (partial discriminator), `Capacity` |

### Relationships and Cardinalities

| Relationship | Cardinality |
|---|---|
| `Patient → Appointment` | 1:N |
| `Doctor → Appointment` | 1:N |
| `Patient → Prescription` | 1:N |
| `Doctor → Prescription` | 1:N |
| `Department → Doctor` | 1:N |
| `Department → Room` | 1:N, identifying relationship |

![ER diagram for the Hospital Management System](erdplus.jpg)

---

## E-commerce Platform

### Weak Entity

`OrderItem` is a weak entity that depends on `Order`. Its discriminator is `LineNumber`, and the full primary key is formed from `OrderID` and `LineNumber`.

### M:N Relationships with Attributes

The relationship between `Product` and `Customer` represents product reviews and has the attributes `Rating`, `Comment`, and `ReviewDate`.

The relationship between `Product` and `Vendor` represents the supply relationship and can include an attribute such as `SupplyPrice`.

![ER diagram for the E-commerce Platform](erdplus%281%29.jpg)

---

# Normalization Workshop

## Denormalized Table Analysis

**Given Relation**

`StudentProject(StudentID, StudentName, StudentMajor, ProjectID, ProjectTitle, ProjectType, SupervisorID, SupervisorName, SupervisorDept, Role, HoursWorked, StartDate, EndDate)`

### Functional Dependencies

| Determinant | Determines |
|---|---|
| `StudentID` | `StudentName`, `StudentMajor` |
| `ProjectID` | `ProjectTitle`, `ProjectType`, `SupervisorID` |
| `SupervisorID` | `SupervisorName`, `SupervisorDept` |
| `StudentID, ProjectID` | `Role`, `HoursWorked`, `StartDate`, `EndDate` |

### Anomalies and Redundancy

There are several problems in the original relation:

- **Data redundancy:** Student and supervisor information is repeated for every project assignment.
- **Update anomaly:** If a supervisor's department changes, every row containing that supervisor has to be updated.
- **Insert anomaly:** A new project or supervisor cannot be stored in this table unless there is already a student assignment.
- **Delete anomaly:** Deleting the only student assigned to a project may also remove the only stored information about that project and its supervisor.

### First Normal Form (1NF)

The relation satisfies 1NF if every attribute contains atomic values and there are no repeating groups or other multi-valued attributes stored in a single field.

### Second Normal Form (2NF)

The primary key is:

`{StudentID, ProjectID}`

There are partial dependencies because some attributes depend only on one part of this composite key:

`StudentID → StudentName, StudentMajor`

and

`ProjectID → ProjectTitle, ProjectType, SupervisorID`

A 2NF decomposition is:

| Relation | Primary Key | Other Attributes |
|---|---|---|
| `Student` | `StudentID` | `StudentName`, `StudentMajor` |
| `Project` | `ProjectID` | `ProjectTitle`, `ProjectType`, `SupervisorID` |
| `StudentAssignment` | `StudentID, ProjectID` | `Role`, `HoursWorked`, `StartDate`, `EndDate` |

At this stage, supervisor details are still associated with the project and will be separated in the 3NF decomposition.

### Third Normal Form (3NF)

There is a transitive dependency:

`ProjectID → SupervisorID`

and

`SupervisorID → SupervisorName, SupervisorDept`

Therefore, supervisor information should be placed in its own relation.

The final 3NF schemas are:

| Relation | Primary Key | Other Attributes |
|---|---|---|
| `Student` | `StudentID` | `StudentName`, `StudentMajor` |
| `Supervisor` | `SupervisorID` | `SupervisorName`, `SupervisorDept` |
| `Project` | `ProjectID` | `ProjectTitle`, `ProjectType`, `SupervisorID` |
| `StudentAssignment` | `StudentID, ProjectID` | `Role`, `HoursWorked`, `StartDate`, `EndDate` |

The foreign keys are:

- `Project.SupervisorID → Supervisor(SupervisorID)`
- `StudentAssignment.StudentID → Student(StudentID)`
- `StudentAssignment.ProjectID → Project(ProjectID)`

---

## Advanced Normalization

**Given Relation**

`CourseSchedule(StudentID, StudentMajor, CourseID, CourseName, InstructorID, InstructorName, TimeSlot, Room, Building)`

### Primary Key

The proposed primary key is:

`{StudentID, CourseID}`

A student can take several courses, and a course can have several students. Under the assumptions given in the relation, this combination identifies an enrollment and its associated course schedule.

### Functional Dependencies

| Determinant | Determines |
|---|---|
| `StudentID` | `StudentMajor` |
| `CourseID` | `CourseName`, `InstructorID`, `TimeSlot`, `Room` |
| `InstructorID` | `InstructorName` |
| `Room` | `Building` |
| `InstructorID, TimeSlot` | `CourseID`, `Room` |
| `Room, TimeSlot` | `CourseID`, `InstructorID` |

### BCNF Verification

The relation does not satisfy BCNF. For example,

`StudentID → StudentMajor`

`InstructorID → InstructorName`

and

`Room → Building`

The determinants in these dependencies are not superkeys of the original relation.

### BCNF Decomposition

The relation can be decomposed into:

| Relation | Primary Key | Other Attributes |
|---|---|---|
| `Student` | `StudentID` | `StudentMajor` |
| `Instructor` | `InstructorID` | `InstructorName` |
| `Classroom` | `Room` | `Building` |
| `CourseOffering` | `CourseID` | `CourseName`, `InstructorID`, `TimeSlot`, `Room` |
| `Enrollment` | `StudentID, CourseID` | — |

The foreign keys are:

- `CourseOffering.InstructorID → Instructor(InstructorID)`
- `CourseOffering.Room → Classroom(Room)`
- `Enrollment.StudentID → Student(StudentID)`
- `Enrollment.CourseID → CourseOffering(CourseID)`

### Loss Analysis

The decomposition is intended to be lossless because the relations are connected through their primary and foreign keys.

The dependency

`Room, TimeSlot → CourseID`

is not completely preserved by ordinary single-table key constraints after decomposition. Checking this dependency would require an additional constraint, trigger, or application-level validation.

---

# Design Challenge

## University Club Management System

### Entities and Structure

The proposed system contains the following main entities:

- `Student`: stores basic student information and enrollment details.
- `FacultyAdvisor`: stores information about faculty advisors responsible for clubs.
- `Club`: stores the main information about each university club.
- `ClubBudget` and `Expense`: handle club budgets and individual expenses.
- `Event` and `RoomReservation`: handle club events and room reservations.
- `Membership`, `OfficerPosition`, and `Attendance`: represent student participation, officer roles, and event attendance.

### Relational Schemas

| Relation | Schema |
|---|---|
| `Student` | `Student(student_id, first_name, last_name, email, major, enrollment_year)` |
| `FacultyAdvisor` | `FacultyAdvisor(advisor_id, name, email, department)` |
| `Club` | `Club(club_id, name, founded, description, advisor_id)` |
| `ClubBudget` | `ClubBudget(budget_id, fiscal_year, allocated_amount, club_id)` |
| `Expense` | `Expense(expense_id, description, amount, date, category, budget_id)` |
| `Room` | `Room(room_id, building, number, capacity)` |
| `Event` | `Event(event_id, name, date, start_time, end_time, club_id)` |
| `RoomReservation` | `RoomReservation(reservation_id, date, start_time, end_time, approval_status, event_id, room_id)` |
| `Membership` | `Membership(membership_id, join_date, status, club_id, student_id)` |
| `OfficerPosition` | `OfficerPosition(officer_id, position_title, term_start, term_end, membership_id)` |
| `Attendance` | `Attendance(attendance_id, status, student_id, event_id)` |

The main foreign keys are:

| Relation | Foreign Key | References |
|---|---|---|
| `Club` | `advisor_id` | `FacultyAdvisor(advisor_id)` |
| `ClubBudget` | `club_id` | `Club(club_id)` |
| `Expense` | `budget_id` | `ClubBudget(budget_id)` |
| `Event` | `club_id` | `Club(club_id)` |
| `RoomReservation` | `event_id` | `Event(event_id)` |
| `RoomReservation` | `room_id` | `Room(room_id)` |
| `Membership` | `club_id` | `Club(club_id)` |
| `Membership` | `student_id` | `Student(student_id)` |
| `OfficerPosition` | `membership_id` | `Membership(membership_id)` |
| `Attendance` | `student_id` | `Student(student_id)` |
| `Attendance` | `event_id` | `Event(event_id)` |

### Design Decision

Officer roles are stored in a separate `OfficerPosition` relation instead of being added directly to `Membership`.

This approach keeps regular membership information separate from officer-specific information. It also avoids unnecessary `NULL` values for ordinary members and makes it possible to store the start and end dates of an officer's term. Since the relation references `Membership`, only registered club members can be assigned an officer position.

### Sample Queries in Natural Language

- Find all active students who currently hold an officer position in the Computer Science Club and show their titles.
- List all approved room reservations for next week together with the club, building, and room number.
- Calculate the total expenses recorded for each club budget during the current fiscal year.

![Relational schema for the University Club Management System](erdplus%282%29.jpg)
