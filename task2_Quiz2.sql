create table departments (
dept_id serial primary key  ,
dept_name varchar(20) not null
);

create table employees (
emp_id serial primary key,
emp_name varchar(25) not null,
salary NUMERIC(10,2) check (salary>0),
dept_id int  references departments(dept_id) on update cascade on delete cascade,
hire_date date default current_date
);


create table projects (
project_id int  primary key,
projectName varchar(20),
dept_id int references departments(dept_id) on update cascade on delete Set null
) 

-- insert at least 3 records into departments
insert into departments (dept_name)
values
('hr'),
('engineering'),
('finance');

-- insert at least 5 records into employees
insert into employees (emp_name, salary, dept_id)
values
('ahmed ali', 5000.00, 1),
('sara hassan', 6000.00, 2),
('omar youssef', 5500.00, 3),
('mona ibrahim', 4800.00, 1),
('khaled fathy', 7000.00, 2);

-- insert at least 3 records into projects
insert into projects (project_id, projectname, dept_id)
values
(101, 'erp system', 2),
(102, 'recruitment drive', 1),
(103, 'budget analysis', 3);

--  update the salary of one employee by increasing it by 1000

update employees
set salary = salary + 1000
where emp_name = 'ahmed ali';

--  update the department of one employee
update employees
set dept_id = 3
where emp_name = 'mona ibrahim';

--  add a new column called email to employees and make it unique
alter table employees
add column email varchar(50) unique;

select * from departments;

-- Add a new column called phone to the departments table.
alter table departments
add column phone varchar(20) unique;

-- Modify the salary column so it cannot accept NULL values.
alter table employees
add constraint salaryNotNull check (salary is not null)

-- Update the dept_id of one department and observe the effect on related tables.
select * from employees
update departments set dept_id=22 where dept_id=2 ; -- it reflets on all related tables as it is updated cascde

