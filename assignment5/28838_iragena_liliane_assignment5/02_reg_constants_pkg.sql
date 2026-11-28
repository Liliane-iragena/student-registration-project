
-- ===========================================
-- PACKAGE : reg_constants_pkg
-- Purpose : Stores all fixed values used by
--           Registrar Module 2.0
-- Public  : Grade boundaries, score limits,
--           GPA values, tuition rate, statuses
--           and log action names
-- Author  : Liliane Iragena | ID: 28838
-- ===========================================

CREATE OR REPLACE PACKAGE reg_constants_pkg AS

    -- Grade boundaries
    c_grade_a_min CONSTANT NUMBER := 90;
    c_grade_b_min CONSTANT NUMBER := 80;
    c_grade_c_min CONSTANT NUMBER := 70;
    c_grade_d_min CONSTANT NUMBER := 60;

    -- Passing mark
    c_pass_mark CONSTANT NUMBER := 60;

    -- Score limits and rounding
    c_score_min CONSTANT NUMBER := 0;
    c_score_max CONSTANT NUMBER := 100;
    c_score_rounding_step CONSTANT NUMBER := 0.5;

    -- GPA values
    c_gpa_divisor CONSTANT NUMBER := 25;
    c_gpa_max CONSTANT NUMBER := 4;
    c_500_level_min_gpa CONSTANT NUMBER := 3.0;

    -- Tuition rate
    c_tuition_per_credit CONSTANT NUMBER := 150000;

    -- Status values
    c_student_status_active CONSTANT VARCHAR2(20) := 'Active';
    c_enrollment_status_active CONSTANT VARCHAR2(20) := 'Active';

    -- Log action names
    c_log_enroll CONSTANT VARCHAR2(30) := 'ENROLL';
    c_log_enroll_rejected CONSTANT VARCHAR2(30) := 'ENROLL_REJECTED';
    c_log_score CONSTANT VARCHAR2(30) := 'SCORE';
    c_log_score_rejected CONSTANT VARCHAR2(30) := 'SCORE_REJECTED';
    c_log_gpa_update CONSTANT VARCHAR2(30) := 'GPA_UPDATE';

END reg_constants_pkg;
/

SHOW ERRORS PACKAGE reg_constants_pkg;
SELECT
    object_name,
    object_type,
    status
FROM user_objects
WHERE object_name = 'REG_CONSTANTS_PKG';