-- ===========================================
-- PACKAGE : report_pkg
-- Purpose : Reports and tuition calculations
-- Public  : tuition_for_student,
--           tuition_for_credits,
--           student_transcript,
--           course_report
-- Author  : Iragena Liliane | ID: 28838
-- ===========================================

CREATE OR REPLACE PACKAGE report_pkg AS

    FUNCTION tuition_for_student(
        p_student_id NUMBER
    ) RETURN NUMBER;

    FUNCTION tuition_for_credits(
        p_credits NUMBER
    ) RETURN NUMBER;

    PROCEDURE student_transcript(
        p_student_id IN NUMBER
    );

    PROCEDURE course_report(
        p_department IN VARCHAR2 DEFAULT NULL
    );

END report_pkg;
/
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'REPORT_PKG';

CREATE OR REPLACE PACKAGE BODY report_pkg AS

    -- Tuition for one student based on active enrollments
    FUNCTION tuition_for_student(
        p_student_id NUMBER
    ) RETURN NUMBER
    IS
        v_total_credits NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(c.credits), 0)
        INTO v_total_credits
        FROM enrollments e
        JOIN courses c
            ON c.course_id = e.course_id
        WHERE e.student_id = p_student_id
          AND e.status = 'Active';

        RETURN v_total_credits
               * reg_constants_pkg.c_tuition_per_credit;
    END tuition_for_student;


    -- Tuition based on number of credits
    FUNCTION tuition_for_credits(
        p_credits NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        IF p_credits IS NULL OR p_credits < 0 THEN
            RETURN 0;
        END IF;

        RETURN p_credits
               * reg_constants_pkg.c_tuition_per_credit;
    END tuition_for_credits;


    -- Print transcript for one student
    PROCEDURE student_transcript(
        p_student_id IN NUMBER
    )
    IS
        v_student_name VARCHAR2(200);
        v_gpa          NUMBER;
        v_status       VARCHAR2(30);
        v_found        BOOLEAN := FALSE;
    BEGIN
        SELECT first_name || ' ' || last_name,
               gpa,
               status
        INTO v_student_name,
             v_gpa,
             v_status
        FROM students
        WHERE student_id = p_student_id;

        DBMS_OUTPUT.PUT_LINE('================================');
        DBMS_OUTPUT.PUT_LINE('STUDENT TRANSCRIPT');
        DBMS_OUTPUT.PUT_LINE('================================');
        DBMS_OUTPUT.PUT_LINE('Student ID: ' || p_student_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || v_student_name);
        DBMS_OUTPUT.PUT_LINE('GPA: ' || TO_CHAR(v_gpa, '0.00'));
        DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
        DBMS_OUTPUT.PUT_LINE('--------------------------------');
        DBMS_OUTPUT.PUT_LINE(
            RPAD('COURSE', 15) ||
            RPAD('SCORE', 10) ||
            RPAD('GRADE', 10) ||
            'STATUS'
        );
        DBMS_OUTPUT.PUT_LINE('--------------------------------');

        FOR r IN (
            SELECT c.course_code,
                   e.score,
                   e.grade,
                   e.status
            FROM enrollments e
            JOIN courses c
                ON c.course_id = e.course_id
            WHERE e.student_id = p_student_id
            ORDER BY c.course_code
        )
        LOOP
            v_found := TRUE;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.course_code, 15) ||
                RPAD(NVL(TO_CHAR(r.score), 'N/A'), 10) ||
                RPAD(NVL(r.grade, 'N/A'), 10) ||
                NVL(r.status, 'N/A')
            );
        END LOOP;

        IF NOT v_found THEN
            DBMS_OUTPUT.PUT_LINE('No enrollments found.');
        END IF;

        DBMS_OUTPUT.PUT_LINE('--------------------------------');
        DBMS_OUTPUT.PUT_LINE(
            'Tuition: ' ||
            reg_util_pkg.format_rwf(
                tuition_for_student(p_student_id)
            )
        );
        DBMS_OUTPUT.PUT_LINE('================================');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(
                'Student not found: ' || p_student_id
            );
    END student_transcript;


    -- Course report, optionally filtered by department
    PROCEDURE course_report(
        p_department IN VARCHAR2 DEFAULT NULL
    )
    IS
        v_found BOOLEAN := FALSE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('================================');
        DBMS_OUTPUT.PUT_LINE('COURSE REPORT');
        DBMS_OUTPUT.PUT_LINE('Department: ' ||
            NVL(p_department, 'ALL'));
        DBMS_OUTPUT.PUT_LINE('================================');

        DBMS_OUTPUT.PUT_LINE(
            RPAD('CODE', 12) ||
            RPAD('COURSE NAME', 25) ||
            RPAD('ENROLLED', 12) ||
            RPAD('CAPACITY', 12) ||
            'AVG SCORE'
        );

        DBMS_OUTPUT.PUT_LINE('--------------------------------');

        FOR r IN (
            SELECT c.course_code,
                   c.course_name,
                   c.max_students,
                   COUNT(
                       CASE
                           WHEN e.status = 'Active'
                           THEN e.enrollment_id
                       END
                   ) AS enrolled,
                   ROUND(AVG(
                       CASE
                           WHEN e.status = 'Active'
                           THEN e.score
                       END
                   ), 2) AS average_score
            FROM courses c
            LEFT JOIN enrollments e
                ON e.course_id = c.course_id
            WHERE p_department IS NULL
               OR UPPER(c.department) = UPPER(p_department)
            GROUP BY c.course_code,
                     c.course_name,
                     c.max_students
            ORDER BY c.course_code
        )
        LOOP
            v_found := TRUE;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.course_code, 12) ||
                RPAD(SUBSTR(r.course_name, 1, 24), 25) ||
                RPAD(TO_CHAR(r.enrolled), 12) ||
                RPAD(TO_CHAR(r.max_students), 12) ||
                NVL(TO_CHAR(r.average_score), 'N/A')
            );
        END LOOP;

        IF NOT v_found THEN
            DBMS_OUTPUT.PUT_LINE('No courses found.');
        END IF;

        DBMS_OUTPUT.PUT_LINE('================================');

    END course_report;

END report_pkg;
/
