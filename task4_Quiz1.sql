------------DAy 4-----------
-- employees whose salary is between 4000 and 9000
select * from employees where salary between 4000 and 9000;

-- employees whose name starts with 'a' using similar to
select * from employees where first_name similar to 'a%';

-- employees who do not belong to any department
select * from employees where dept_id is null;

-- employees who work in departments 1, 2, or 3
select * from employees where dept_id in (1,2,3);

-- employee name and salary level using CASE WHEN High if salary > 8000

select first_name || ' ' || last_name as employee_name,
       case
         when salary > 8000 then 'high'
         when salary between 4000 and 8000 then 'medium'
         else 'low'
       end as salary_level
from employees;

-- employees assigned to at least one project using exists
select * from employees e
where exists (
		select 1 from employee_project ep 
		where ep.emp_id = e.emp_id);

-- employees whose salary is greater than any salary in department 2
select * from employees
where salary > any (select salary from employees where dept_id = 2);

-- create table high_salary_employees and insert employees with salary > 8000
create table high_salary_employees as
select * from employees where salary > 8000;

-- delete employees not assigned to any project
delete from employees e
where not exists (
select 1 from employee_project ep 
where ep.emp_id = e.emp_id);

-- display all distinct department locations
select distinct location from departments;

-- Create a calculated column showing salary after 10% bonus

select first_name, last_name, salary, salary * 1.10 as bonus_salary
from employees;

--Concatenate first_name and last_name into a single column using CONCAT

select concat(first_name, ' ', last_name) as full_name from employees;

--Find the POSITION of a character or substring in employee names using POSITION
select first_name, position('a' in first_name) as pos from employees;

--Replace a part of employee name using REPLACE
select replace(first_name, 'ali', 'alexander') from employees;

-- cast salary to integer
select cast(salary as integer) from employees;

--Display employee names with their department names

select e.first_name || ' ' || e.last_name as employee_name, d.dept_name
from employees e
left join departments d on e.dept_id = d.dept_id;

-- Count employees in each department (more than 1 employee)
select d.dept_name, count(e.emp_id) as emp_count
from departments d
join employees e on d.dept_id = e.dept_id
group by d.dept_name
having count(e.emp_id) > 1;

-- Top 3 highest paid employees with department names
select e.first_name || ' ' || e.last_name as employee_name, e.salary, d.dept_name
from employees e
left join departments d on e.dept_id = d.dept_id
order by e.salary desc
limit 3;

--Display all departments and the employees working in them, including departments that do not have employees.
select d.dept_name, e.first_name || ' ' || e.last_name as employee_name
from departments d
left join employees e on d.dept_id = e.dept_id;

--Display all employees with their department names, including employees who do not belong to any department.
select e.first_name || ' ' || e.last_name as employee_name, d.dept_name
from employees e
left join departments d on e.dept_id = d.dept_id;

-- 2.Total hours worked on each project ordered by highest hours
select p.project_name, sum(p.hours_worked) as total_hours
from projects p
group by p.project_name
order by total_hours desc;

-- .Average salary per department (avg > 6000)
select d.dept_name, avg(e.salary) as avg_salary
from departments d
join employees e on d.dept_id = e.dept_id
group by d.dept_name
having avg(e.salary) > 6000;






