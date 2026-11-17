create table departments (
    dept_id int primary key,
    dept_name varchar(50),
    location varchar(50)
);

create table employees (
    emp_id int primary key,
    emp_name varchar(100),
    dept_id int,
    salary decimal(10,2),
    foreign key (dept_id) references departments(dept_id)
);

create table projects (
    proj_id int primary key,
    proj_name varchar(100),
    budget decimal(12,2),
    dept_id int,
    foreign key (dept_id) references departments(dept_id)
);

insert into departments values
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

insert into employees values
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

insert into projects values
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

create index emp_salary_idx on employees(salary);

select indexname, indexdef
from pg_indexes
where tablename = 'employees';

create index emp_dept_idx on employees(dept_id);

select * from employees where dept_id = 101;

select
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;

create index emp_dept_salary_idx on employees(dept_id, salary);

select emp_name, salary
from employees
where dept_id = 101 and salary > 52000;

create index emp_salary_dept_idx on employees(salary, dept_id);

select * from employees where dept_id = 102 and salary > 50000;

select * from employees where salary > 50000 and dept_id = 102;

alter table employees add column email varchar(100);

update employees set email = 'john.smith@company.com' where emp_id = 1;
update employees set email = 'jane.doe@company.com' where emp_id = 2;
update employees set email = 'mike.johnson@company.com' where emp_id = 3;
update employees set email = 'sarah.williams@company.com' where emp_id = 4;
update employees set email = 'tom.brown@company.com' where emp_id = 5;

create unique index emp_email_unique_idx on employees(email);

insert into employees (emp_id, emp_name, dept_id, salary, email)
values (6, 'New Employee', 101, 55000, 'john.smith@company.com');

alter table employees add column phone varchar(20) unique;

select indexname, indexdef
from pg_indexes
where tablename = 'employees' and indexname like '%phone%';

create index emp_salary_desc_idx on employees(salary desc);

select emp_name, salary
from employees
order by salary desc;

create index proj_budget_nulls_first_idx on projects(budget nulls first);

select proj_name, budget
from projects
order by budget nulls first;

create index emp_name_lower_idx on employees(lower(emp_name));

select * from employees where lower(emp_name) = 'john smith';

alter table employees add column hire_date date;

update employees set hire_date = '2020-01-15' where emp_id = 1;
update employees set hire_date = '2019-06-20' where emp_id = 2;
update employees set hire_date = '2021-03-10' where emp_id = 3;
update employees set hire_date = '2020-11-05' where emp_id = 4;
update employees set hire_date = '2018-08-25' where emp_id = 5;

create index emp_hire_year_idx on employees(extract(year from hire_date));

select emp_name, hire_date
from employees
where extract(year from hire_date) = 2020;

alter index emp_salary_idx rename to employees_salary_index;

select indexname from pg_indexes where tablename = 'employees';

drop index emp_salary_dept_idx;

reindex index employees_salary_index;

select e.emp_name, e.salary, d.dept_name
from employees e
join departments d on e.dept_id = d.dept_id
where e.salary > 50000
order by e.salary desc;

create index emp_salary_filter_idx on employees(salary) where salary > 50000;

create index proj_high_budget_idx on projects(budget)
where budget > 80000;

select proj_name, budget
from projects
where budget > 80000;

explain select * from employees where salary > 52000;

set enable_seqscan = off;

explain select * from employees where salary > 52000;

reset enable_seqscan;

create index dept_name_hash_idx on departments using hash (dept_name);

select * from departments where dept_name = 'IT';

create index proj_name_btree_idx on projects(proj_name);

create index proj_name_hash_idx on projects using hash (proj_name);

select * from projects where proj_name = 'Website Redesign';

select * from projects where proj_name > 'Database';

select
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;

drop index if exists proj_name_hash_idx;

create view index_documentation as
select
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
from pg_indexes
where schemaname = 'public'
    and indexname like '%salary%';

select * from index_documentation;

create index emp_hire_month_idx on employees(extract(month from hire_date));

select emp_name, hire_date
from employees
where extract(month from hire_date) = 1;

create unique index emp_dept_email_unique_idx on employees(dept_id, email);

set enable_seqscan = off;

explain analyze select * from employees where dept_id = 101;

reset enable_seqscan;

set enable_indexscan = off;
set enable_bitmapscan = off;
set enable_indexonlyscan = off;

explain analyze select * from employees where dept_id = 101;

reset enable_indexscan;
reset enable_bitmapscan;
reset enable_indexonlyscan;

create index emp_covering_idx on employees(dept_id) include (emp_name, salary);

select emp_name, salary from employees where dept_id = 101;