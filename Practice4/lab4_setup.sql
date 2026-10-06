create table employees (
    employee_id serial primary key,
    first_name varchar(50),
    last_name varchar(50),
    department varchar(50),
    salary numeric(10,2),
    hire_date date,
    manager_id integer,
    email varchar(100)
);

create table projects (
    project_id serial primary key,
    project_name varchar(100),
    budget numeric(12,2),
    start_date date,
    end_date date,
    status varchar(20)
);

create table assignments (
    assignment_id serial primary key,
    employee_id integer references employees(employee_id),
    project_id integer references projects(project_id),
    hours_worked numeric(5,1),
    assignment_date date
);

insert into employees (first_name, last_name, department, salary, hire_date, manager_id, email) values
    ('John', 'Smith', 'IT', 75000, '2020-01-15', null, 'john.smith@company.com'),
    ('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1, 'sarah.j@company.com'),
    ('Michael', 'Brown', 'Sales', 55000, '2019-06-10', null, 'mbrown@company.com'),
    ('Emily', 'Davis', 'HR', 60000, '2021-02-01', null, 'emily.davis@company.com'),
    ('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, null),
    ('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3, 'lisa.a@company.com');

insert into projects (project_name, budget, start_date, end_date, status) values
    ('Website Redesign', 150000, '2024-01-01', '2024-06-30', 'Active'),
    ('CRM Implementation', 200000, '2024-02-15', '2024-12-31', 'Active'),
    ('Marketing Campaign', 80000, '2024-03-01', '2024-05-31', 'Completed'),
    ('Database Migration', 120000, '2024-01-10', null, 'Active');

insert into assignments (employee_id, project_id, hours_worked, assignment_date) values
    (1, 1, 120.5, '2024-01-15'),
    (2, 1, 95.0, '2024-01-20'),
    (1, 4, 80.0, '2024-02-01'),
    (3, 3, 60.0, '2024-03-05'),
    (5, 2, 110.0, '2024-02-20'),
    (6, 3, 75.5, '2024-03-10');
