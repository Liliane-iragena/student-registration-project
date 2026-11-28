
# AUCA Registrar Module – PL/SQL

## Student Information
- **Name:** Iragena Liliane
- **Student ID:** 28838
- **Course:** INSY 8311 – Database Development with PL/SQL
- **Project:** AUCA Registrar Module

## Project Description
The AUCA Registrar Module is a database application developed
using Oracle PL/SQL. It supports student registration,
course enrollment, score management, GPA calculation,
and academic reporting.

## Project Objectives
- Manage student enrollment in courses.
- Validate enrollment requests.
- Prevent duplicate course enrollment.
- Record student scores and assign letter grades.
- Recalculate student GPA.
- Generate tuition and academic reports.
- Maintain registrar activity logs.
- Organize PL/SQL code using packages.

## Database Objects
The project uses the following tables:

- STUDENTS
- COURSES
- ENROLLMENTS
- EMPLOYEES
- DEPARTMENTS
- REGISTRAR_LOG

## PL/SQL Packages

### REG_CONSTANTS_PKG
Stores shared constants used by the registrar application,
including tuition and enrollment-related values.

### REG_UTIL_PKG
Provides reusable utility functions such as:
- Letter grade calculation
- Score rounding
- Student name retrieval
- Available course seats
- Rwandan Franc formatting

### REGISTRAR_PKG
Provides registrar operations such as:
- Enrolling students in courses
- Recording scores
- Recalculating student GPA
- Printing session summaries
- Resetting session statistics

### REPORT_PKG
Provides reporting functions and procedures such as:
- Tuition calculation for a student
- Tuition calculation based on credits
- Student transcript
- Course report

## Project Files

| File | Description |
|---|---|
| 01_setup_and_baseline.sql | Setup and baseline checks |
| 02_reg_constants_pkg.sql | Constants package |
| 03_reg_util_pkg.sql | Utility package |
| 04_registrar_pkg.sql | Registrar package |
| 05_report_pkg.sql | Reporting package |
| 06_integration_test.sql | Integration testing script |
| 07_package_management.sql | Package management and verification |

## Requirements
- Oracle Database
- Oracle SQL Developer
- Access to the AUCA Registrar database schema

## How to Use
1. Connect to the correct Oracle database schema.
2. Run the setup and baseline script if required.
3. Create the package specifications and package bodies.
4. Run the integration test script after all packages compile.
5. Review package status and compilation errors.
6. Review the generated reports and registrar logs.

## Testing
The project includes tests for:
- Utility functions
- Enrollment procedures
- Duplicate enrollment validation
- Score recording
- GPA recalculation
- Tuition calculations
- Student transcript
- Course reports
- Session summary

## Author
Iragena Liliane  
Student ID: 28838
