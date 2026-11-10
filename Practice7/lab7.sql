CREATE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id;


CREATE VIEW dept_statistics AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS average_salary,
    MAX(e.salary) AS maximum_salary,
    MIN(e.salary) AS minimum_salary
FROM departments d
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;


CREATE VIEW project_overview AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS team_size
FROM projects p
JOIN departments d
    ON p.dept_id = d.dept_id
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;


CREATE VIEW high_earners AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.salary > 55000;


CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
    END AS salary_grade
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id;


ALTER VIEW high_earners RENAME TO top_performers;


SELECT * FROM top_performers;


CREATE VIEW temp_view AS
SELECT *
FROM employees
WHERE salary < 50000;

DROP VIEW temp_view;


CREATE VIEW employee_salaries AS
SELECT
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees;


UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';


SELECT *
FROM employees
WHERE emp_name = 'John Smith';


INSERT INTO employee_salaries
    (emp_id, emp_name, dept_id, salary)
VALUES
    (6, 'Alice Johnson', 102, 58000);


CREATE VIEW it_employees AS
SELECT
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;


INSERT INTO it_employees
    (emp_id, emp_name, dept_id, salary)
VALUES
    (7, 'Bob Wilson', 103, 60000);


CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id,
    d.dept_name,
    COALESCE(ec.total_employees, 0) AS total_employees,
    COALESCE(ec.total_salaries, 0) AS total_salaries,
    COALESCE(pc.total_projects, 0) AS total_projects,
    COALESCE(pc.total_project_budget, 0) AS total_project_budget
FROM departments d
LEFT JOIN (
    SELECT
        dept_id,
        COUNT(*) AS total_employees,
        SUM(salary) AS total_salaries
    FROM employees
    GROUP BY dept_id
) ec ON d.dept_id = ec.dept_id
LEFT JOIN (
    SELECT
        dept_id,
        COUNT(*) AS total_projects,
        SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
) pc ON d.dept_id = pc.dept_id
WITH DATA;


SELECT *
FROM dept_summary_mv
ORDER BY total_employees DESC;


INSERT INTO employees
    (emp_id, emp_name, dept_id, salary)
VALUES
    (8, 'Charlie Brown', 101, 54000);


SELECT *
FROM dept_summary_mv;


REFRESH MATERIALIZED VIEW dept_summary_mv;


SELECT *
FROM dept_summary_mv;


CREATE UNIQUE INDEX idx_dept_summary_mv
ON dept_summary_mv (dept_id);


REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;


CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS assigned_employees
FROM projects p
JOIN departments d
    ON p.dept_id = d.dept_id
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;


SELECT *
FROM project_stats_mv;


REFRESH MATERIALIZED VIEW project_stats_mv;


CREATE ROLE analyst;

CREATE ROLE data_viewer
WITH LOGIN PASSWORD 'viewer123';

CREATE USER report_user
WITH PASSWORD 'report456';


SELECT rolname
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%';


CREATE ROLE db_creator
WITH LOGIN CREATEDB PASSWORD 'creator789';

CREATE ROLE user_manager
WITH LOGIN CREATEROLE PASSWORD 'manager101';

CREATE ROLE admin_user
WITH LOGIN SUPERUSER PASSWORD 'admin999';


GRANT SELECT ON employees TO analyst;
GRANT SELECT ON departments TO analyst;
GRANT SELECT ON projects TO analyst;

GRANT ALL PRIVILEGES ON employee_details TO data_viewer;

GRANT SELECT, INSERT ON employees TO report_user;


CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;


CREATE USER hr_user1 WITH PASSWORD 'hr001';
CREATE USER hr_user2 WITH PASSWORD 'hr002';
CREATE USER finance_user1 WITH PASSWORD 'fin001';


GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;


GRANT SELECT, UPDATE ON employees TO hr_team;

GRANT SELECT ON dept_statistics TO finance_team;


REVOKE UPDATE ON employees FROM hr_team;

REVOKE hr_team FROM hr_user2;

REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;


ALTER ROLE analyst
WITH LOGIN PASSWORD 'analyst123';

ALTER ROLE user_manager
WITH SUPERUSER;

ALTER ROLE analyst
WITH PASSWORD NULL;

ALTER ROLE data_viewer
WITH CONNECTION LIMIT 5;


CREATE ROLE read_only;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;


CREATE ROLE junior_analyst
WITH LOGIN PASSWORD 'junior123';

CREATE ROLE senior_analyst
WITH LOGIN PASSWORD 'senior123';


GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;


CREATE ROLE project_manager
WITH LOGIN PASSWORD 'pm123';


ALTER VIEW dept_statistics
OWNER TO project_manager;

ALTER TABLE projects
OWNER TO project_manager;


CREATE ROLE temp_owner
WITH LOGIN;


CREATE TABLE temp_table (
    id INT
);


ALTER TABLE temp_table
OWNER TO temp_owner;


REASSIGN OWNED BY temp_owner TO postgres;

DROP OWNED BY temp_owner;

DROP ROLE temp_owner;


CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;


GRANT SELECT ON hr_employee_view TO hr_team;


CREATE VIEW finance_employee_view AS
SELECT
    emp_id,
    emp_name,
    salary
FROM employees;


GRANT SELECT ON finance_employee_view TO finance_team;


CREATE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS employee_count,
    COALESCE(ROUND(AVG(e.salary), 2), 0) AS average_salary,
    COUNT(DISTINCT p.project_id) AS active_projects,
    COALESCE(SUM(DISTINCT p.budget), 0) AS total_project_budget,
    CASE
        WHEN COUNT(DISTINCT e.emp_id) = 0 THEN 0
        ELSE ROUND(
            COALESCE(SUM(DISTINCT p.budget), 0) /
            COUNT(DISTINCT e.emp_id),
            2
        )
    END AS budget_per_employee
FROM departments d
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
LEFT JOIN projects p
    ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;


ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;


CREATE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status
FROM projects p
JOIN departments d
    ON p.dept_id = d.dept_id
WHERE p.budget > 75000;


CREATE ROLE viewer_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;


CREATE ROLE entry_role;

GRANT viewer_role TO entry_role;

GRANT INSERT ON employees TO entry_role;
GRANT INSERT ON projects TO entry_role;


CREATE ROLE analyst_role;

GRANT entry_role TO analyst_role;

GRANT UPDATE ON employees TO analyst_role;
GRANT UPDATE ON projects TO analyst_role;


CREATE ROLE manager_role;

GRANT analyst_role TO manager_role;

GRANT DELETE ON employees TO manager_role;
GRANT DELETE ON projects TO manager_role;


CREATE USER alice
WITH LOGIN PASSWORD 'alice123';

CREATE USER bob
WITH LOGIN PASSWORD 'bob123';

CREATE USER charlie
WITH LOGIN PASSWORD 'charlie123';


GRANT viewer_role TO alice;

GRANT analyst_role TO bob;

GRANT manager_role TO charlie;