
SET SERVEROUTPUT ON;
SET FEEDBACK ON;

PROMPT ==========================================
PROMPT ASSIGNMENT 5 - PACKAGE MANAGEMENT
PROMPT ==========================================

-- 1. Check package dependencies
PROMPT Checking package dependencies...

SELECT name,
       type,
       referenced_name,
       referenced_type
FROM user_dependencies
WHERE name IN (
    'REG_CONSTANTS_PKG',
    'REG_UTIL_PKG',
    'REGISTRAR_PKG',
    'REPORT_PKG'
)
ORDER BY name, referenced_name;

-- 2. Recompile package specifications
PROMPT Recompiling package specifications...

ALTER PACKAGE reg_constants_pkg COMPILE;
ALTER PACKAGE reg_util_pkg COMPILE;
ALTER PACKAGE registrar_pkg COMPILE;
ALTER PACKAGE report_pkg COMPILE;

-- 3. Recompile package bodies
PROMPT Recompiling package bodies...

ALTER PACKAGE reg_util_pkg COMPILE BODY;
ALTER PACKAGE registrar_pkg COMPILE BODY;
ALTER PACKAGE report_pkg COMPILE BODY;

-- 4. Display package compilation status
PROMPT Checking package status...

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'REG_CONSTANTS_PKG',
    'REG_UTIL_PKG',
    'REGISTRAR_PKG',
    'REPORT_PKG'
)
ORDER BY object_name, object_type;

-- 5. Remove old standalone procedures/functions
-- These have been replaced by the new packages.
PROMPT Removing obsolete standalone procedures/functions...

BEGIN
    FOR obj IN (
        SELECT object_name, object_type
        FROM user_objects
        WHERE object_name IN (
            'PR_ENROLL_STUDENT',
            'PR_LOG_ACTION',
            'PR_RECALCULATE_GPA',
            'PR_RECORD_SCORE',
            'PR_ROUND_SCORE'
        )
        AND object_type IN ('PROCEDURE', 'FUNCTION')
    )
    LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'DROP ' || obj.object_type || ' ' || obj.object_name;

            DBMS_OUTPUT.PUT_LINE(
                'Dropped: ' || obj.object_type || ' ' || obj.object_name
            );
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(
                    'Could not drop ' || obj.object_name ||
                    ': ' || SQLERRM
                );
        END;
    END LOOP;
END;
/

-- 6. Final object status after package management
PROMPT Final package and standalone object status...

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'REG_CONSTANTS_PKG',
    'REG_UTIL_PKG',
    'REGISTRAR_PKG',
    'REPORT_PKG',
    'PR_ENROLL_STUDENT',
    'PR_LOG_ACTION',
    'PR_RECALCULATE_GPA',
    'PR_RECORD_SCORE',
    'PR_ROUND_SCORE'
)
ORDER BY object_name, object_type;

PROMPT Package management script completed.
