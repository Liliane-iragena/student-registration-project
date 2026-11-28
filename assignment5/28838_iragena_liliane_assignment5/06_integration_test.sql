
SET SERVEROUTPUT ON;
SET FEEDBACK ON;

PROMPT =========================================
PROMPT ASSIGNMENT 5 - INTEGRATION TESTS
PROMPT =========================================

-- 1. Test REG_UTIL_PKG functions
PROMPT --- Utility package functions ---

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Letter grade for 87.5: ' ||
        reg_util_pkg.letter_grade(87.5)
    );

    DBMS_OUTPUT.PUT_LINE(
        'Rounded score: ' ||
        reg_util_pkg.round_score(87.3)
    );

    DBMS_OUTPUT.PUT_LINE(
        'Student name: ' ||
        reg_util_pkg.student_name(1045)
    );

    DBMS_OUTPUT.PUT_LINE(
        'Tuition for 12 credits: ' ||
        reg_util_pkg.format_rwf(
            report_pkg.tuition_for_credits(12)
        )
    );
END;
/

-- 2. Test REPORT_PKG tuition function
PROMPT --- Tuition report ---

BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Student tuition: ' ||
        reg_util_pkg.format_rwf(
            report_pkg.tuition_for_student(1045)
        )
    );
END;
/

-- 3. Test student transcript
PROMPT --- Student transcript ---

BEGIN
    report_pkg.student_transcript(1045);
END;
/

-- 4. Test course report for all departments
PROMPT --- All courses report ---

BEGIN
    report_pkg.course_report;
END;
/

-- 5. Test course report for one department
PROMPT --- Department course report ---

BEGIN
    report_pkg.course_report('Computer Science');
END;
/

-- 6. Test registrar package enrollment
PROMPT --- Enrollment procedure ---

DECLARE
    v_message VARCHAR2(400);
BEGIN
    registrar_pkg.enroll_student(
        p_student_id  => 1045,
        p_course_code => 'BUS101',
        p_message     => v_message
    );

    DBMS_OUTPUT.PUT_LINE(v_message);
END;
/

-- 7. Test score recording
PROMPT --- Record score ---

DECLARE
    v_message VARCHAR2(400);
BEGIN
    registrar_pkg.record_score(
        p_enrollment_id => 261,
        p_score         => 87.5,
        p_message       => v_message
    );

    DBMS_OUTPUT.PUT_LINE(v_message);
END;
/

-- 8. Test GPA recalculation
PROMPT --- Recalculate GPA ---

DECLARE
    v_old_gpa NUMBER;
    v_new_gpa NUMBER;
BEGIN
    registrar_pkg.recalculate_gpa(
        p_student_id => 1045,
        p_old_gpa    => v_old_gpa,
        p_new_gpa    => v_new_gpa
    );

    DBMS_OUTPUT.PUT_LINE('Old GPA: ' || v_old_gpa);
    DBMS_OUTPUT.PUT_LINE('New GPA: ' || v_new_gpa);
END;
/

-- 9. Print session summary
PROMPT --- Session summary ---

BEGIN
    registrar_pkg.print_session_summary;
END;
/

PROMPT =========================================
PROMPT INTEGRATION TEST SCRIPT COMPLETED
PROMPT =========================================
