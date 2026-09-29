CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (100, 'John', 'Smith', 'IT');

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Anna', 'Brown', 'HR', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT', 200000, 1),
       ('HR', 80000, 2),
       ('Sales', 150000, 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Mike', 'Davis', 'Sales', 50000 * 1.1, CURRENT_DATE);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Olga', 'Ivanova', 'IT', 70000, '2019-05-10', 'Active'),
       ('Peter', 'Petrov', 'Sales', 45000, '2018-03-15', 'Inactive'),
       ('Sara', 'Lee', 'Sales', 90000, '2017-07-01', 'Terminated'),
       ('Tom', 'Young', NULL, 30000, '2023-06-01', 'Active');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Alpha', 1, '2022-01-01', '2022-12-31', 60000),
       ('Beta', 2, '2023-02-01', '2023-09-30', 40000),
       ('Gamma', 3, '2024-01-01', '2024-12-31', 70000);

CREATE TEMP TABLE temp_employees (LIKE employees);
INSERT INTO temp_employees
SELECT * FROM employees WHERE department = 'IT';

UPDATE employees SET salary = salary * 1.10
WHERE department = 'IT';

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments
SET budget = (
    SELECT ROUND(AVG(salary) * 1.2)
    FROM employees
    WHERE employees.department = departments.dept_name
);

UPDATE employees
SET salary = salary * 1.15, status = 'Promoted'
WHERE department = 'Sales';

DELETE FROM employees WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

DELETE FROM departments
WHERE dept_id::text NOT IN (
    SELECT DISTINCT department FROM employees WHERE department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Null', 'Person', NULL, NULL);

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Null2', 'Person2', NULL, NULL);

DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Nina', 'Kim', 'IT', 60000, '2021-01-01')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary FROM employees) old
WHERE e.emp_id = old.emp_id AND e.department = 'IT'
RETURNING e.emp_id, old.salary AS old_salary, e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Nina', 'Kim', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Nina' AND last_name = 'Kim'
);

UPDATE employees
SET salary = salary * CASE
    WHEN (SELECT budget FROM departments WHERE dept_name = employees.department) > 100000
    THEN 1.10
    ELSE 1.05
END;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('B1', 'Bulk', 'IT', 50000, CURRENT_DATE),
       ('B2', 'Bulk', 'IT', 51000, CURRENT_DATE),
       ('B3', 'Bulk', 'IT', 52000, CURRENT_DATE),
       ('B4', 'Bulk', 'IT', 53000, CURRENT_DATE),
       ('B5', 'Bulk', 'IT', 54000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Bulk';

CREATE TABLE employee_archive (LIKE employees);

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

UPDATE projects
SET end_date = end_date + 30
WHERE budget > 50000
  AND dept_id IN (
      SELECT d.dept_id
      FROM departments d
      WHERE (SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_name) > 3
  );