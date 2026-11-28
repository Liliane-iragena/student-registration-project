
-- ===========================================
-- ASSIGNMENT 5
-- PHASE 0: SETUP AND SQL BASELINE
-- Author: Liliane Iragena
-- Student ID: 28838
-- ===========================================

SET SERVEROUTPUT ON;

-- 0.1 Create REGISTRAR_LOG if it does not exist

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM user_tables
    WHERE table_name = 'REGISTRAR_LOG';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE REGISTRAR_LOG (
                log_id NUMBER PRIMARY KEY,
                action VARCHAR2(30) NOT NULL,
                student_id NUMBER,
                course_id NUMBER,
                details VARCHAR2(400),
                logged_by VARCHAR2(128) DEFAULT USER,
                logged_at DATE DEFAULT SYSDATE,
                CONSTRAINT chk_registrar_log_action
                CHECK (action IN (
                    ''ENROLL'',
                    ''ENROLL_REJECTED'',
                    ''SCORE'',
                    ''SCORE_REJECTED'',
                    ''GPA_UPDATE''
                ))
            )';

        DBMS_OUTPUT.PUT_LINE('REGISTRAR_LOG created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('REGISTRAR_LOG already exists.');
    END IF;
END;
/
-- Create REGISTRAR_LOG_SEQ if it does not exist

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM user_sequences
    WHERE sequence_name = 'REGISTRAR_LOG_SEQ';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE REGISTRAR_LOG_SEQ
            START WITH 1
            INCREMENT BY 1
            NOCACHE';

        DBMS_OUTPUT.PUT_LINE('REGISTRAR_LOG_SEQ created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('REGISTRAR_LOG_SEQ already exists.');
    END IF;
END;
/

-- ===========================================
-- 0.1 B: CHECK AND CREATE LOG SEQUENCE
-- ===========================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM user_sequences
    WHERE sequence_name = 'REGISTRAR_LOG_SEQ';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE REGISTRAR_LOG_SEQ
            START WITH 1
            INCREMENT BY 1
            NOCACHE';

        DBMS_OUTPUT.PUT_LINE('REGISTRAR_LOG_SEQ created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('REGISTRAR_LOG_SEQ already exists.');
    END IF;
END;
/

-- ===========================================
-- 0.2 A: TUITION BASELINE
-- ===========================================

SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    COUNT(e.enrollment_id) AS active_enrollments,
    NVL(SUM(c.credits), 0) AS total_credits,
    NVL(SUM(c.credits), 0) * 150000 AS tuition
FROM students s
LEFT JOIN enrollments e
    ON s.student_id = e.student_id
    AND e.status = 'Active'
LEFT JOIN courses c
    ON e.course_id = c.course_id
WHERE s.student_id BETWEEN 1001 AND 1010
GROUP BY
    s.student_id,
    s.first_name,
    s.last_name
ORDER BY s.student_id;

-- ===========================================
-- 0.2 B: GRADE DISTRIBUTION BASELINE
-- ===========================================

SELECT
    c.course_code,

    SUM(CASE
        WHEN e.score >= 90 THEN 1
        ELSE 0
    END) AS grade_a,

    SUM(CASE
        WHEN e.score >= 80 AND e.score < 90 THEN 1
        ELSE 0
    END) AS grade_b,

    SUM(CASE
        WHEN e.score >= 70 AND e.score < 80 THEN 1
        ELSE 0
    END) AS grade_c,

    SUM(CASE
        WHEN e.score >= 60 AND e.score < 70 THEN 1
        ELSE 0
    END) AS grade_d,

    SUM(CASE
        WHEN e.score < 60 THEN 1
        ELSE 0
    END) AS grade_f,

    SUM(CASE
        WHEN e.enrollment_id IS NOT NULL
         AND e.score IS NULL THEN 1
        ELSE 0
    END) AS ungraded

FROM courses c
LEFT JOIN enrollments e
    ON c.course_id = e.course_id
WHERE UPPER(TRIM(c.department)) = 'COMPUTER SCIENCE'
GROUP BY c.course_code
ORDER BY c.course_code;

-- ===========================================
-- 0.2 C: CURRENT FUNCTIONS AND PROCEDURES
-- ===========================================

SELECT
    object_name,
    object_type,
    status
FROM user_objects
WHERE object_type IN ('FUNCTION', 'PROCEDURE')
ORDER BY object_type, object_name;

