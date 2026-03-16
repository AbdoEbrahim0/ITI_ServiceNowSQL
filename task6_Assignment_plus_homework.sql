select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks

-- insert into employees values(1,'abdo','magdy',2500,1,'2005-7-7')
public.courses
"lec_Lab4".Schemas.public.tasks (
CREATE TABLE tasks (
    task_id SERIAL PRIMARY KEY,
    task_name VARCHAR(100),
    status VARCHAR(20),
    priority VARCHAR(20),
    due_date DATE,
    emp_id INT
);
-- drop table "lec_Lab4.Schemas.public.tasks"

INSERT INTO tasks (task_name, status, priority, due_date, emp_id)
VALUES 
('Prepare report', 'Completed', 'High', '2026-03-20', 1),
 
('Fix system bug', 'In Progress', 'High', '2026-03-18', 2),
 
('Update database', 'Pending', 'Medium', '2026-03-25', 3),
 
('Design new feature', 'In Progress', 'High', '2026-03-22', 1),
 
('Test application', 'Completed', 'Low', '2026-03-19', 4),
 
('Write documentation', 'Pending', 'Medium', '2026-03-28', 2),
 
('Client meeting preparation', 'In Progress', 'High', '2026-03-17', 5),
 
('Code review', 'Completed', 'Medium', '2026-03-21', 3),
 
('Deploy update', 'Pending', 'High', '2026-03-26', 1),
 
('Security audit', 'Pending', 'High', '2026-03-30', 4);



-- ################ day 6 ###########
select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks
select * from works_on

--1.Using the employee table, find the average salary per department, 
--and then display only the departments where the average salary is greater than 4000. Use a CTE (WITH clause).
with cte as (select dept_id ,avg(salary) as avgSalary from employees group by dept_id  )
select * from cte  where avgSalary >4000;
--2.List employees who do not work in the 'IT' department. Use the EXCEPT clause.
select * from employees
select * from Departments

select * from employees where dept_id in (
					select dept_id
					from employees
					except
					select dept_id
					from Departments
					where dept_name='it'
					)

--3.Find employees who are in both the 'Sales' and 'Marketing' projects (assuming works_on table). Use INTERSECT. 
select * from employees
select * from works_on

select emp_id from works_on where project_id= (select project_id  from projects where project_name='sales') 
intersect
select emp_id from works_on where project_id= (select project_id  from projects where project_name='marketing') 

-- 4.Update the salary of employee emp_id = 5 to 6000. Then update department of emp_id = 5 to 3. If any error occurs, rollback the changes.Write the SQL commands.
start transaction ;
update  employees set salary =6000 where emp_id=5;
update  employees set dept_id=4 where emp_id=5;
commit;
rollback;


-- 6.Show employees who work in the Sales department.
select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks
select * from works_on

select * from 

with OnlySales as (
	select p.project_id,p.project_name,w.emp_id from projects p join works_on w on w.project_id=p.project_id
	where p.project_name='sales')

select e.*, os.project_id,os.project_name from  employees e join OnlySales os on e.emp_id= os.emp_id
--------------------------------

select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks
select * from works_on

-- Show employees who have tasks with priority 'High'.
--with only join
select e.* ,t.task_name, t.priority
from tasks t join employees e 
on e.emp_id =t.emp_id
where t.priority  ILIKE 'high'

--with cte & join
with tasks_temp as (
	select *
	from tasks
	where priority  ILIKE 'high'
)
select e.* ,t.task_name, t.priority
from tasks_temp t join employees e 
on e.emp_id =t.emp_id

-- Show employees who have tasks due today.
-- there is no data in current date
--only join
select current_date;
select e.* ,t.task_name, t.priority,t.due_date
from tasks t join employees e 
on e.emp_id =t.emp_id
where t.due_date=current_date; 

-- Show employees who do not have any tasks with status 'Completed'.
with tempTasks as (
select * from tasks where status !='Completed'
)

select e.* ,t.status
from tempTasks t join employees e 
on e.emp_id =t.emp_id


-- ### homework ####--
select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks
select * from works_on
-- Show employees who have more than 2 tasks. 
--[result :: only emp_id =1 who have more than 2 tasks]
with tempTasks as
(
select emp_id
from tasks 
group by emp_id having count(*)>2
)
select * from employees where emp_id in ( select * from tempTasks)
-- Show tasks that have a due date later than the latest completed task.
 with latestDate as (
select  max(due_date) from tasks where status ='Completed'  --(21-20-19) max is 21
 )
 select * from tasks where due_date> (select * from latestDate) --[result :: 5 tasks ]

-- Show employee names who are assigned High priority tasks.
--cte & subquerry [result:: 6 employees]
with HighPriority as
(
select emp_id
from tasks 
where priority similar to 'High'
)

select *  from employees where emp_id in ( select * from HighPriority)

--cte & join  [result:: 6 employees]
with HighPriority as
(
select emp_id,priority
from tasks 
where priority similar to 'High'
)

select first_name || ' ' ||last_name  as fullName , HP.priority from employees e join HighPriority HP 
on HP.emp_id=e.emp_id
-- Show employees who have at least one completed task.
with oneLeastCompletedEmp_id as
(
select distinct emp_id from tasks where status='Completed'
)
select e.* from employees as e join  oneLeastCompletedEmp_id o
on e.emp_id=o.emp_id
