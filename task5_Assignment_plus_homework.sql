select * from Departments
select * from employees
select * from projects
select * from employee_project

alter table employees add column hire_date date

update employees set hire_date = '1-1-2005' where  emp_id=2
update employees set hire_date = '2-2-2005' where  emp_id=3;
update employees set hire_date = '5-5-2005' where  emp_id=6;
update employees set hire_date = '10-10-2005' where  emp_id=10;


create table works_on (
    emp_id int references employees(emp_id),
    project_id int references projects(project_id),
    hours int,
    primary key (emp_id, project_id)
);

-- add a budget column to projects
alter table projects add column budget numeric(12,2);

update projects set budget = 50000 where project_id = 1; -- erp system
update projects set budget = 30000 where project_id = 2; -- website redesign
update projects set budget = 45000 where project_id = 3; -- marketing campaign
update projects set budget = 20000 where project_id = 4; -- financial audit

insert into works_on (emp_id, project_id, hours) values
(2, 1, 40),   -- alaa on erp system
(3, 1, 60),   -- amira on erp system
(4, 2, 50),   -- adam on website redesign
(5, 3, 70),   -- sara on marketing campaign
(6, 3, 80),   -- mona on marketing campaign
(10, 4, 30);  -- asmaa on financial audit

--For each department, show the latest hired employee (based on hire_date).

-- select d.dept_name ,e.*  from departments  d join employees e
-- on e.dept_id =d.dept_id
-- group by d.dept_id

-- select * from employees order by hire_date desc
-- limit 1;
 --Solution--
select d.dept_name , max(hire_date) from departments  d join employees e
on e.dept_id =d.dept_id
group by d.dept_id


--Display all employees with their department names using a NATURAL JOIN.
select e.first_name, d.dept_name from employees e
natural left join   departments d -- on e.dept_id=d.dept_id

--Show each project and its budget, along with the number of employees working on it (assuming a works_on table exists).
select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from works_on

select w.project_id,p.budget,count(w.emp_id) from projects as p join works_on w on p.project_id =w.project_id
group by w.project_id,p.budget


--List all employees who have the same salary, without repeating pairs .
select  e1.emp_id, e1.first_name, e1.last_name, e1.salary
from employees e1
join employees e2 
  on e1.emp_id != e2.emp_id
 and e1.salary = e2.salary ;


--Show project name with the employees working on it (assuming a works_on table exists).
select p.project_name,w.emp_id , e.first_name || ' ' || e.last_name  from projects p 
join works_on w
	on p.project_id =w.project_id
join employees  e 
	on w.emp_id= e.emp_id 
--Show names of employees and departments in one list.
select  e.first_name || ' ' || e.last_name ,d.dept_id,dept_name from departments d
 full join employees  e 
	on d.dept_id =e.dept_id

select first_name || ' ' || last_name
	from employees
		union
select dept_name 
	from departments;

--select * from employees where hire_date = (select hire_date from employees group by emp_id where hire_date =max(hire_date) ) 

--######### homeWork Section ########--

--1.For each department, show one employee (any employee) in that department. 
select distinct on (d.dept_name) d.dept_name,e.first_name || ' ' || e.last_name as empName
from departments d join employees e
on d.dept_id=e.dept_id




-- 2.Show department name and average salary of employees in that department (use subquery)

select e.dept_id, avg(salary) as avg_salary from Employees e group by e.dept_id

select d.dept_name ,avg_salary from Departments d
join (select e.dept_id, avg(salary) as avg_salary from Employees e group by e.dept_id) as temp_table
on d.dept_id=temp_table.dept_id
-- 3.Show employees who were hired on the same date. 
select * from employees

select e1.* 
from employees e1 join employees e2
on e1.hire_date = e2.hire_date and e1.emp_id != e2.emp_id
-- 4.Show employees whose salary is greater than the average salary.
 select * from employees as e2 
 where e2.salary > (select avg(e.salary) from Employees e)
 
