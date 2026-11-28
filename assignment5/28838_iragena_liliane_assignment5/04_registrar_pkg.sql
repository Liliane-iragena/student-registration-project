
-- ===========================================
-- PACKAGE : registrar_pkg
-- Purpose : Enrollment, scores and GPA (R1-R9)
-- Public  : enroll_student (2 versions),
--           record_score, recalculate_gpa,
--           print_session_summary, reset_session
-- Author  : Liliane Iragena | ID: 28838
-- ===========================================

CREATE OR REPLACE PACKAGE registrar_pkg AS

    -- Enroll student using course ID
    PROCEDURE enroll_student(
        p_student_id IN NUMBER,
        p_course_id  IN NUMBER,
        p_message    OUT VARCHAR2
    );

    -- Enroll student using course code
    PROCEDURE enroll_student(
        p_student_id  IN NUMBER,
        p_course_code IN VARCHAR2,
        p_message     OUT VARCHAR2
    );

    -- Record a student's score
    PROCEDURE record_score(
        p_enrollment_id IN NUMBER,
        p_score         IN NUMBER,
        p_message       OUT VARCHAR2
    );

    -- Recalculate a student's GPA
    PROCEDURE recalculate_gpa(
        p_student_id IN NUMBER,
        p_old_gpa    OUT NUMBER,
        p_new_gpa    OUT NUMBER
    );

    -- Display the current session summary
    PROCEDURE print_session_summary;

    -- Reset session counters
    PROCEDURE reset_session;

END registrar_pkg;
/

SHOW ERRORS PACKAGE registrar_pkg;
SELECT
    object_name,
    object_type,
    status
FROM user_objects
WHERE object_name = 'REGISTRAR_PKG';

-- ===========================================
-- PACKAGE BODY : registrar_pkg
-- Purpose : Implements enrollment, scores,
--           GPA and session tracking (R1-R9)
-- Author  : Liliane Iragena | ID: 28838
-- ===========================================

CREATE OR REPLACE PACKAGE BODY registrar_pkg AS

    -- =======================================
    -- PRIVATE SESSION VARIABLES
    -- =======================================

    v_students_enrolled  NUMBER := 0;
    v_enrollments_rejected NUMBER := 0;
    v_scores_saved      NUMBER := 0;
    v_scores_rejected   NUMBER := 0;
    v_gpas_updated      NUMBER := 0;

    v_session_started TIMESTAMP;
    v_current_semester courses.semester%TYPE;


    -- =======================================
    -- PRIVATE FUNCTION: can_enroll
    -- Purpose : Checks enrollment eligibility
    -- Parameters: p_student_id, p_course_id
    -- Rules   : R1, R2, R3, R4
    -- =======================================

    FUNCTION can_enroll(
        p_student_id IN NUMBER,
        p_course_id  IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_student_status students.status%TYPE;
        v_student_gpa    students.gpa%TYPE;
        v_course_code    courses.course_code%TYPE;
        v_seats          NUMBER;
        v_count          NUMBER;
    BEGIN

        -- Check whether student exists
        BEGIN
            SELECT status, gpa
            INTO v_student_status, v_student_gpa
            FROM students
            WHERE student_id = p_student_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'STUDENT NOT FOUND';
        END;

        -- R1: Student must be Active
        IF NVL(v_student_status, ' ') <>
            reg_constants_pkg.c_student_status_active THEN

            RETURN 'STUDENT NOT ACTIVE';
        END IF;

        -- Check whether course exists
        BEGIN
            SELECT course_code
            INTO v_course_code
            FROM courses
            WHERE course_id = p_course_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'COURSE NOT FOUND';
        END;

        -- R2: Prevent duplicate active enrollment
        SELECT COUNT(*)
        INTO v_count
        FROM enrollments
        WHERE student_id = p_student_id
          AND course_id = p_course_id
          AND status =
              reg_constants_pkg.c_enrollment_status_active;

        IF v_count > 0 THEN
            RETURN 'ALREADY ENROLLED';
        END IF;

        -- R3: Check available seats
        v_seats := reg_util_pkg.seats_left(p_course_id);

        IF NVL(v_seats, 0) <= 0 THEN
            RETURN 'COURSE FULL';
        END IF;

        -- R4: 500-level courses require GPA >= 3.0
        IF SUBSTR(v_course_code, 3, 1) = '5'
           AND NVL(v_student_gpa, 0) <
               reg_constants_pkg.c_500_level_min_gpa THEN

            RETURN 'GPA TOO LOW';
        END IF;

        RETURN 'OK';

    END can_enroll;


    -- =======================================
    -- PRIVATE PROCEDURE: log_action
    -- Purpose : Records an action in REGISTRAR_LOG
    -- Parameters: action, student ID, course ID,
    --             details
    -- Rule    : R8
    -- =======================================

    PROCEDURE log_action(
        p_action     IN VARCHAR2,
        p_student_id IN NUMBER,
        p_course_id  IN NUMBER,
        p_details    IN VARCHAR2
    )
    IS
    BEGIN

        INSERT INTO registrar_log (
            log_id,
            action,
            student_id,
            course_id,
            details
        )
        VALUES (
            registrar_log_seq.NEXTVAL,
            p_action,
            p_student_id,
            p_course_id,
            p_details
        );

    END log_action;


    -- =======================================
    -- PUBLIC PROCEDURE: enroll_student
    -- Version 1: Uses course ID
    -- Purpose : Enrolls an eligible student
    -- Parameters: student ID, course ID, message
    -- Rules   : R1, R2, R3, R4, R8, R9
    -- =======================================

    PROCEDURE enroll_student(
        p_student_id IN NUMBER,
        p_course_id  IN NUMBER,
        p_message    OUT VARCHAR2
    )
    IS
        v_reason      VARCHAR2(50);
        v_course_code courses.course_code%TYPE;
    BEGIN

        -- Check enrollment eligibility
        v_reason := can_enroll(
            p_student_id,
            p_course_id
        );

        IF v_reason <> 'OK' THEN

            p_message := 'Rejected: ' || v_reason;

            v_enrollments_rejected :=
                v_enrollments_rejected + 1;

            log_action(
                reg_constants_pkg.c_log_enroll_rejected,
                p_student_id,
                p_course_id,
                v_reason
            );

            RETURN;
        END IF;

        -- Retrieve course code
        SELECT course_code
        INTO v_course_code
        FROM courses
        WHERE course_id = p_course_id;

        -- Create the enrollment
        INSERT INTO enrollments (
            enrollment_id,
            student_id,
            course_id,
            enrollment_date,
            grade,
            score,
            status
        )
        VALUES (
            enrollment_seq.NEXTVAL,
            p_student_id,
            p_course_id,
            SYSDATE,
            NULL,
            NULL,
            reg_constants_pkg.c_enrollment_status_active
        );

        -- Build the success message
        p_message :=
            'Enrolled: ' ||
            reg_util_pkg.student_name(p_student_id) ||
            ' in ' || v_course_code ||
            ' (' || v_current_semester || ')';

        -- Update session counter
        v_students_enrolled := v_students_enrolled + 1;

        -- Record successful enrollment
        log_action(
            reg_constants_pkg.c_log_enroll,
            p_student_id,
            p_course_id,
            p_message
        );

    END enroll_student;


    -- =======================================
    -- PUBLIC PROCEDURE: enroll_student
    -- Version 2: Uses course code
    -- Purpose : Finds course ID and calls
    --           the ID version of enrollment
    -- Parameters: student ID, course code, message
    -- Rules   : R1, R2, R3, R4, R8, R9
    -- =======================================

    PROCEDURE enroll_student(
        p_student_id  IN NUMBER,
        p_course_code IN VARCHAR2,
        p_message     OUT VARCHAR2
    )
    IS
        v_course_id courses.course_id%TYPE;
    BEGIN

        -- Find course ID using course code
        BEGIN
            SELECT course_id
            INTO v_course_id
            FROM courses
            WHERE UPPER(TRIM(course_code)) =
                  UPPER(TRIM(p_course_code));

        EXCEPTION
            WHEN NO_DATA_FOUND THEN

                p_message := 'Rejected: COURSE NOT FOUND';

                v_enrollments_rejected :=
                    v_enrollments_rejected + 1;

                log_action(
                    reg_constants_pkg.c_log_enroll_rejected,
                    p_student_id,
                    NULL,
                    'COURSE NOT FOUND: ' || p_course_code
                );

                RETURN;
        END;

        -- Call the ID version.
        -- Enrollment logic exists only once.
        enroll_student(
            p_student_id,
            v_course_id,
            p_message
        );

    END enroll_student;


    -- =======================================
    -- PUBLIC PROCEDURE: record_score
    -- Purpose : Validates, rounds and saves score
    -- Parameters: enrollment ID, score, message
    -- Rules   : R5, R6, R8, R9
    -- =======================================

    PROCEDURE record_score(
        p_enrollment_id IN NUMBER,
        p_score         IN NUMBER,
        p_message       OUT VARCHAR2
    )
    IS
        v_student_id    enrollments.student_id%TYPE;
        v_course_id     enrollments.course_id%TYPE;
        v_rounded_score NUMBER;
        v_grade         VARCHAR2(2);
        v_score_text    VARCHAR2(30);
    BEGIN

        -- Find the enrollment
        BEGIN
            SELECT student_id, course_id
            INTO v_student_id, v_course_id
            FROM enrollments
            WHERE enrollment_id = p_enrollment_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN

                p_message := 'Rejected: ENROLLMENT NOT FOUND';

                v_scores_rejected := v_scores_rejected + 1;

                log_action(
                    reg_constants_pkg.c_log_score_rejected,
                    NULL,
                    NULL,
                    'ENROLLMENT NOT FOUND: ' || p_enrollment_id
                );

                RETURN;
        END;

        -- R5: Validate score range
        IF p_score IS NULL
           OR p_score < reg_constants_pkg.c_score_min
           OR p_score > reg_constants_pkg.c_score_max THEN

            p_message := 'Rejected: SCORE MUST BE BETWEEN 0 AND 100';

            v_scores_rejected := v_scores_rejected + 1;

            log_action(
                reg_constants_pkg.c_log_score_rejected,
                v_student_id,
                v_course_id,
                p_message
            );

            RETURN;
        END IF;

        -- R5: Round score to nearest 0.5
        v_rounded_score := reg_util_pkg.round_score(p_score);

        -- R6: Calculate letter grade
        v_grade := reg_util_pkg.letter_grade(v_rounded_score);

        -- Update enrollment score and grade
        UPDATE enrollments
        SET score = v_rounded_score,
            grade = v_grade
        WHERE enrollment_id = p_enrollment_id;

        v_score_text := TO_CHAR(
            v_rounded_score,
            'FM999990D0',
            'NLS_NUMERIC_CHARACTERS = ''.,'''
        );

        p_message :=
            'Score saved: ' ||
            v_score_text ||
            ' (' || v_grade || ')';

        -- Update session counter
        v_scores_saved := v_scores_saved + 1;

        -- Log successful score
        log_action(
            reg_constants_pkg.c_log_score,
            v_student_id,
            v_course_id,
            p_message
        );

    END record_score;


    -- =======================================
    -- PUBLIC PROCEDURE: recalculate_gpa
    -- Purpose : Calculates GPA from graded scores
    -- Parameters: student ID, old GPA, new GPA
    -- Rule    : R7, R8, R9
    -- =======================================

    PROCEDURE recalculate_gpa(
        p_student_id IN NUMBER,
        p_old_gpa    OUT NUMBER,
        p_new_gpa    OUT NUMBER
    )
    IS
        v_average_score NUMBER;
        v_graded_count  NUMBER;
        v_calculated_gpa NUMBER;
    BEGIN

        -- Retrieve current GPA
        BEGIN
            SELECT gpa
            INTO p_old_gpa
            FROM students
            WHERE student_id = p_student_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                p_old_gpa := NULL;
                p_new_gpa := NULL;
                RETURN;
        END;

        -- Find average of graded scores
        SELECT COUNT(score), AVG(score)
        INTO v_graded_count, v_average_score
        FROM enrollments
        WHERE student_id = p_student_id
          AND score IS NOT NULL;

        -- R7: Do not recalculate without graded courses
        IF v_graded_count = 0 THEN
            p_new_gpa := p_old_gpa;
            RETURN;
        END IF;

        -- R7: GPA = average score / 25
        v_calculated_gpa := LEAST(
            ROUND(
                v_average_score /
                reg_constants_pkg.c_gpa_divisor,
                2
            ),
            reg_constants_pkg.c_gpa_max
        );

        p_new_gpa := v_calculated_gpa;

        -- Update only when the GPA changes
        IF NVL(p_old_gpa, -1) <>
           NVL(p_new_gpa, -1) THEN

            UPDATE students
            SET gpa = p_new_gpa
            WHERE student_id = p_student_id;

            v_gpas_updated := v_gpas_updated + 1;

            -- R8: Record GPA change
            log_action(
                reg_constants_pkg.c_log_gpa_update,
                p_student_id,
                NULL,
                'GPA changed from ' ||
                NVL(TO_CHAR(p_old_gpa), 'NULL') ||
                ' to ' || TO_CHAR(p_new_gpa)
            );

        END IF;

    END recalculate_gpa;


    -- =======================================
    -- PUBLIC PROCEDURE: print_session_summary
    -- Purpose : Displays current session counters
    -- Parameters: None
    -- =======================================

    PROCEDURE print_session_summary
    IS
    BEGIN

        DBMS_OUTPUT.PUT_LINE('================================');
        DBMS_OUTPUT.PUT_LINE('REGISTRAR SESSION SUMMARY');
        DBMS_OUTPUT.PUT_LINE('================================');

        DBMS_OUTPUT.PUT_LINE(
            'Session started: ' ||
            TO_CHAR(
                v_session_started,
                'YYYY-MM-DD HH24:MI:SS.FF'
            )
        );

        DBMS_OUTPUT.PUT_LINE(
            'Students enrolled: ' || v_students_enrolled
        );

        DBMS_OUTPUT.PUT_LINE(
            'Enrollments rejected: ' || v_enrollments_rejected
        );

        DBMS_OUTPUT.PUT_LINE(
            'Scores saved: ' || v_scores_saved
        );

        DBMS_OUTPUT.PUT_LINE(
            'Scores rejected: ' || v_scores_rejected
        );

        DBMS_OUTPUT.PUT_LINE(
            'GPAs updated: ' || v_gpas_updated
        );

        DBMS_OUTPUT.PUT_LINE('================================');

    END print_session_summary;


    -- =======================================
    -- PUBLIC PROCEDURE: reset_session
    -- Purpose : Resets all session counters
    -- Parameters: None
    -- =======================================

    PROCEDURE reset_session
    IS
    BEGIN

        v_students_enrolled := 0;
        v_enrollments_rejected := 0;
        v_scores_saved := 0;
        v_scores_rejected := 0;
        v_gpas_updated := 0;

        DBMS_OUTPUT.PUT_LINE('Session counters reset.');

    END reset_session;


    -- =======================================
    -- PACKAGE INITIALIZATION SECTION
    -- Purpose : Records session start time,
    --           retrieves current semester and
    --           announces package loading
    -- =======================================

BEGIN

    v_session_started := SYSTIMESTAMP;

    BEGIN
        SELECT semester
        INTO v_current_semester
        FROM courses
        WHERE ROWNUM = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_current_semester := 'Unknown semester';
    END;

    DBMS_OUTPUT.PUT_LINE(
        'registrar_pkg loaded for ' || v_current_semester
    );

END registrar_pkg;
/

SHOW ERRORS PACKAGE BODY registrar_pkg;
SELECT
    object_name,
    object_type,
    status
FROM user_objects
WHERE object_name IN (
    'REG_CONSTANTS_PKG',
    'REG_UTIL_PKG',
    'REGISTRAR_PKG'
)
AND object_type IN ('PACKAGE', 'PACKAGE BODY')
ORDER BY object_name, object_type;