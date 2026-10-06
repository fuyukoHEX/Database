-- task 1.1
select first_name || ' ' || last_name as full_name, department, salary
from employees;

-- task 1.2
select distinct department
from employees;

-- task 1.3
select project_name, budget,
    case
        when budget > 150000 then 'Large'
        when budget between 100000 and 150000 then 'Medium'
        else 'Small'
    end as budget_category
from projects;

-- task 1.4
select first_name || ' ' || last_name as full_name,
    coalesce(email, 'No email provided') as email
from employees;

-- task 2.1
select *
from employees
where hire_date > '2020-01-01';

-- task 2.2
select *
from employees
where salary between 60000 and 70000;

-- task 2.3
select *
from employees
where last_name like 'S%' or last_name like 'J%';

-- task 2.4
select *
from employees
where manager_id is not null and department = 'IT';

-- task 3.1
select upper(first_name || ' ' || last_name) as full_name_upper,
    length(last_name) as last_name_length,
    substring(email from 1 for 3) as email_prefix
from employees;

-- task 3.2
select first_name || ' ' || last_name as full_name,
    salary as annual_salary,
    round(salary / 12, 2) as monthly_salary,
    salary * 0.10 as raise_amount
from employees;

-- task 3.3
select format('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) as project_info
from projects;

-- task 3.4
select first_name || ' ' || last_name as full_name,
    hire_date,
    extract(year from age(current_date, hire_date)) as years_with_company
from employees;

-- task 4.1
select department, round(avg(salary), 2) as avg_salary
from employees
group by department;

-- task 4.2
select p.project_name, sum(a.hours_worked) as total_hours
from projects p
join assignments a on p.project_id = a.project_id
group by p.project_id, p.project_name;

-- task 4.3
select department, count(*) as employee_count
from employees
group by department
having count(*) > 1;

-- task 4.4
select max(salary) as max_salary,
    min(salary) as min_salary,
    sum(salary) as total_payroll
from employees;

-- task 5.1
select employee_id, first_name || ' ' || last_name as full_name, salary
from employees
where salary > 65000
union
select employee_id, first_name || ' ' || last_name as full_name, salary
from employees
where hire_date > '2020-01-01';

-- task 5.2
select employee_id, first_name || ' ' || last_name as full_name, salary
from employees
where department = 'IT'
intersect
select employee_id, first_name || ' ' || last_name as full_name, salary
from employees
where salary > 65000;

-- task 5.3
select employee_id, first_name || ' ' || last_name as full_name
from employees
except
select e.employee_id, e.first_name || ' ' || e.last_name as full_name
from employees e
join assignments a on e.employee_id = a.employee_id;

-- task 6.1
select *
from employees e
where exists (
    select 1
    from assignments a
    where a.employee_id = e.employee_id
);

-- task 6.2
select *
from employees
where employee_id in (
    select a.employee_id
    from assignments a
    join projects p on a.project_id = p.project_id
    where p.status = 'Active'
);

-- task 6.3
select *
from employees
where salary > any (
    select salary
    from employees
    where department = 'Sales'
);

-- task 7.1
select e.first_name || ' ' || e.last_name as full_name,
    e.department,
    round(avg(a.hours_worked), 2) as avg_hours_worked,
    rank() over (partition by e.department order by e.salary desc) as salary_rank_in_department
from employees e
left join assignments a on e.employee_id = a.employee_id
group by e.employee_id, e.first_name, e.last_name, e.department, e.salary
order by e.department, salary_rank_in_department;

-- task 7.2
select p.project_name,
    sum(a.hours_worked) as total_hours,
    count(distinct a.employee_id) as employee_count
from projects p
join assignments a on p.project_id = a.project_id
group by p.project_id, p.project_name
having sum(a.hours_worked) > 150;

-- task 7.3
select emp.department,
    count(*) as total_employees,
    round(avg(emp.salary), 2) as avg_salary,
    (
        select e.first_name || ' ' || e.last_name
        from employees e
        where e.department = emp.department
        order by e.salary desc
        limit 1
    ) as highest_paid_employee,
    greatest(max(emp.salary), min(emp.salary)) as top_salary,
    least(max(emp.salary), min(emp.salary)) as bottom_salary
from employees emp
group by emp.department;
