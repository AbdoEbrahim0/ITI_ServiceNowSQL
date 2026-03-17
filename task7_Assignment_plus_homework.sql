select * from Departments
select * from employees
select * from projects
select * from employee_project


select dept_name, array_agg(e.first_name)
from employees as e join departments d
on e.dept_id = d.dept_id
group by dept_name

select * from Departments
select * from employees

with cte as (
select e.* , rank() over(partition by d.dept_id order by e.salary ) as MyTop
from employees e join Departments d 
on e.dept_id =d.dept_id 

)
select * from cte where MyTop=1;



select e.* , rank() over(partition by d.dept_id order by e.salary desc ) as MyTop
from employees e join Departments d 
on e.dept_id =d.dept_id 

--###### Day 7 ########
select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks
select * from works_on

-- Assign a row number to each task per employee ordered by due_date. 
select e.first_name, task_name , due_date ,row_number() over (partition by emp_id order by due_date)
from tasks join employees e
using (emp_id)


-- ** Rank employees based on their salary (highest salary = rank 1). 

-- with limit 
select first_name || ' '|| last_name , salary,  dense_rank() over ( order by salary desc) as dr
from  employees 
limit 1;
-- with subquery
select * from 
(
select first_name || ' '|| last_name , salary,  dense_rank() over ( order by salary desc) as dr
from  employees 
)
where dr=1

-- Show the latest task for each employee.
select * from 
(
select e.first_name, task_name , due_date ,dense_rank() over (partition by emp_id order by due_date desc) as dr
from tasks join employees e
using (emp_id)
)
where dr =1

-- Show each employee with the average salary of their department.
select first_name || ' '|| last_name ,d.dept_name,avg(e.salary) over (partition by dept_id) as avgSalaryPerDept
from departments d join employees e
using (dept_id)
-- Show running count of tasks per employee ordered by due_date. 
select first_name || ' '|| last_name,due_date, count(task_id) over (partition by emp_id order by due_date desc) as dr
from tasks join employees e
using (emp_id)
-- ** Show each employee with their rank based on salary.
select first_name || ' '|| last_name , salary,  row_number() over ( order by salary desc) as rn
from  employees 
-- Show employee name and number of tasks, but only for employees whose task count is above average.

with cte as (

select distinct first_name || ' '|| last_name, count(task_id) over (partition by emp_id order by emp_id desc) as task_count
from tasks join employees e
using (emp_id)
)
 select *  from cte
 where task_count > (select  avg(task_count) from cte)

 -- Rank tasks by priority (High first), without gaps in ranking.
 select * from Departments
select * from employees
select * from projects
select * from employee_project
select * from employee_project
select * from tasks
select * from works_on


select * , dense_rank() over (order by case priority
								when 'High' then 1
								when 'Medium' then 2
								when 'Low' then 3
										end)  as prio_rank
from tasks

-- Show the employee who has the maximum number of tasks.
select distinct first_name || ' '|| last_name as full_name, count(task_id) over (partition by emp_id order by emp_id desc) as task_count
from tasks join employees e
using (emp_id)

order by task_count desc
limit 1;

-- do this first section 
ALTER TABLE employees
ADD COLUMN mgr_id INT;

ALTER TABLE employees
ADD CONSTRAINT fk_manager
FOREIGN KEY (mgr_id)
REFERENCES employees(emp_id);

UPDATE employees SET mgr_id = 3 WHERE emp_id IN (1,2);
UPDATE employees SET mgr_id = 4 WHERE emp_id IN (5);
select * from employees

-- Show employees who have more tasks than their manager

select * from (
				with cte as
							(
					select  emp.emp_id,emp.first_name, emp.last_name, emp.mgr_id ,
								count(task_name) as count_tasks_Employee 
							from employees emp join tasks t
							on emp.emp_id = t.emp_id
							group by emp.emp_id, emp.first_name,emp.last_name,emp.mgr_id 
							
							)
			select e.* , mgr.count_tasks_Employee as mgr_count_tasks
			from cte as e
			left join cte as mgr
			on e.mgr_id = mgr.emp_id
				)
where count_tasks_Employee> mgr_count_tasks


-- [[dummy trials]]


-- select  emp.emp_id ,count(task_name) --over(partition by emp.emp_id order by task_name ) as count_tasks
-- from employees as mgr join employees as emp
-- on mgr.emp_id= emp.emp_id --and mgr.mgr_id is not null
-- join tasks t 
-- on t.emp_id =emp.emp_id
-- group by emp.emp_id


-- select * , (select count_tasks_Employee as mgr_count_tasks from tempTable e join tempTable mgr on e.mgr_id =mgr.emp_id)
-- from (

-- select  emp.* ,count(task_name) as count_tasks_Employee 
-- from employees emp 
-- join tasks t
-- on emp.emp_id = t.emp_id
-- group by emp.emp_id

-- ) as tempTable
