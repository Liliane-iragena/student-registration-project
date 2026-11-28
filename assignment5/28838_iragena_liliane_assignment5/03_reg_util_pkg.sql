
-- ===========================================
-- PACKAGE : reg_util_pkg
-- Purpose : Shared utility functions for the
--           Registrar Module 2.0
-- Public  : letter_grade, round_score,
--           student_name (2 versions),
--           seats_left (2 versions), format_rwf
-- Author  : Liliane Iragena | ID: 28838
-- ===========================================

CREATE OR REPLACE PACKAGE reg_util_pkg AS

    -- Returns the letter grade for a given score
    FUNCTION letter_grade(
        p_score IN NUMBER
    ) RETURN VARCHAR2;

    -- Rounds a score to the nearest 0.5
    FUNCTION round_score(
        p_score IN NUMBER
    ) RETURN NUMBER;

    -- Returns student name using student ID
    FUNCTION student_name(
        p_student_id IN NUMBER
    ) RETURN VARCHAR2;

    -- Returns a name built from first and last name
    FUNCTION student_name(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Returns available seats using course ID
    FUNCTION seats_left(
        p_course_id IN NUMBER
    ) RETURN NUMBER;

    -- Returns available seats using course code
    FUNCTION seats_left(
        p_course_code IN VARCHAR2
    ) RETURN NUMBER;

    -- Formats an amount in Rwandan francs
    FUNCTION format_rwf(
        p_amount IN NUMBER
    ) RETURN VARCHAR2;

END reg_util_pkg;
/

SHOW ERRORS PACKAGE reg_util_pkg;
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'REG_UTIL_PKG';

-- ===========================================
-- PACKAGE BODY : reg_util_pkg
-- Purpose : Implements shared utility functions
-- Author  : Liliane Iragena | ID: 28838
-- ===========================================

CREATE OR REPLACE PACKAGE BODY reg_util_pkg AS

    -- ---------------------------------------
    -- FUNCTION: letter_grade
    -- Purpose : Converts a score into a letter grade
    -- Parameter: p_score - student's score
    -- Rules   : R6
    -- ---------------------------------------
    FUNCTION letter_grade(
        p_score IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        IF p_score IS NULL THEN
            RETURN NULL;

        ELSIF p_score >= reg_constants_pkg.c_grade_a_min THEN
            RETURN 'A';

        ELSIF p_score >= reg_constants_pkg.c_grade_b_min THEN
            RETURN 'B';

        ELSIF p_score >= reg_constants_pkg.c_grade_c_min THEN
            RETURN 'C';

        ELSIF p_score >= reg_constants_pkg.c_grade_d_min THEN
            RETURN 'D';

        ELSE
            RETURN 'F';
        END IF;
    END letter_grade;


    -- ---------------------------------------
    -- FUNCTION: round_score
    -- Purpose : Rounds score to nearest 0.5
    -- Parameter: p_score - student's score
    -- Rule    : R5
    -- ---------------------------------------
    FUNCTION round_score(
        p_score IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        IF p_score IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN ROUND(
            p_score / reg_constants_pkg.c_score_rounding_step
        ) * reg_constants_pkg.c_score_rounding_step;

    END round_score;


    -- ---------------------------------------
    -- FUNCTION: student_name (Version 1)
    -- Purpose : Retrieves a student's full name
    -- Parameter: p_student_id - student ID
    -- ---------------------------------------
    FUNCTION student_name(
        p_student_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_first_name students.first_name%TYPE;
        v_last_name  students.last_name%TYPE;
    BEGIN
        SELECT first_name, last_name
        INTO v_first_name, v_last_name
        FROM students
        WHERE student_id = p_student_id;

        RETURN student_name(v_first_name, v_last_name);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Unknown student';

    END student_name;


    -- ---------------------------------------
    -- FUNCTION: student_name (Version 2)
    -- Purpose : Builds a properly formatted name
    -- Parameters: p_first_name, p_last_name
    -- ---------------------------------------
    FUNCTION student_name(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN INITCAP(
            TRIM(p_first_name || ' ' || p_last_name)
        );
    END student_name;


    -- ---------------------------------------
    -- FUNCTION: seats_left (Version 1)
    -- Purpose : Calculates available course seats
    -- Parameter: p_course_id - course ID
    -- Rule    : R3
    -- ---------------------------------------
    FUNCTION seats_left(
        p_course_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_seats NUMBER;
    BEGIN
        SELECT c.max_students - COUNT(e.enrollment_id)
        INTO v_seats
        FROM courses c
        LEFT JOIN enrollments e
            ON c.course_id = e.course_id
            AND e.status =
                reg_constants_pkg.c_enrollment_status_active
        WHERE c.course_id = p_course_id
        GROUP BY c.max_students;

        RETURN v_seats;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;

    END seats_left;


    -- ---------------------------------------
    -- FUNCTION: seats_left (Version 2)
    -- Purpose : Calculates available seats by course code
    -- Parameter: p_course_code - course code
    -- Uses    : Version 1 of seats_left
    -- ---------------------------------------
    FUNCTION seats_left(
        p_course_code IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_course_id courses.course_id%TYPE;
    BEGIN
        SELECT course_id
        INTO v_course_id
        FROM courses
        WHERE course_code = p_course_code;

        RETURN seats_left(v_course_id);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;

    END seats_left;


    -- ---------------------------------------
    -- FUNCTION: format_rwf
    -- Purpose : Formats an amount in Rwandan francs
    -- Parameter: p_amount - amount to format
    -- ---------------------------------------
    FUNCTION format_rwf(
        p_amount IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        IF p_amount IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN 'RWF ' ||
            TO_CHAR(
                p_amount,
                'FM999G999G999G999G990',
                'NLS_NUMERIC_CHARACTERS = ''.,'''
            );

    END format_rwf;

END reg_util_pkg;
/

SHOW ERRORS PACKAGE BODY reg_util_pkg;
SELECT
    object_name,
    object_type,
    status
FROM user_objects
WHERE object_name = 'REG_UTIL_PKG'
ORDER BY object_type;
SELECT
    s.student_id,

    reg_util_pkg.letter_grade(e.score)
        AS letter_grade,

    reg_util_pkg.round_score(e.score)
        AS rounded_score,

    reg_util_pkg.student_name(s.student_id)
        AS name_by_id,

    reg_util_pkg.student_name(
        s.first_name,
        s.last_name
    ) AS name_by_parts,

    reg_util_pkg.seats_left(c.course_id)
        AS seats_by_id,

    reg_util_pkg.seats_left(c.course_code)
        AS seats_by_code,

    reg_util_pkg.format_rwf(
        c.credits * reg_constants_pkg.c_tuition_per_credit
    ) AS formatted_amount

FROM students s
JOIN enrollments e
    ON s.student_id = e.student_id
JOIN courses c
    ON e.course_id = c.course_id
WHERE e.score IS NOT NULL
  AND ROWNUM <= 10;
