
-------------- DAY 3 ------------------
insert into doctors (fname, mname, lname, specialization, qualification)
values 
(  'Sara', 'Ahmed', 'Nabil','Pediatrics', 'MBBS'),
(  'Omar', 'Hassan', 'Farouk','Dermatology', 'MD');
select * from Doctors
select * from Patients


create table Doctor_Treats_Patient (
Doctor_id int references Doctors(Doctor_id), 
Patient_id int references Patients(Patient_id) 
);


INSERT INTO Doctor_Treats_Patient (Doctor_id, Patient_id)
VALUES
(1, 1),
(1, 2),
(2, 3),
(3, 4),
(4, 5),
(2, 1);

select * from Doctor_Treats_Patient;
select * from patient_medicine
select * from Medicine
select * from Patients
select * from Doctors
--1.A patient was added by mistake with patient_id = 5. Remove this patient from the system. 
alter table patient_medicine add constraint fk_patient_medicine_patient 
foreign key (Patient_id) references Patients(Patient_id)
  on delete cascade
delete from Patients where  patient_id = 5
--2.Display all doctors who work in Cardiology department and their salary is greater than 12000.
alter table Doctors add column salary numeric(10,2);  
update Doctors set salary =10000 where Doctor_id =1
update Doctors set salary =8000 where Doctor_id =2

update Doctors set salary =13000 where Doctor_id =3,
update Doctors set salary =15000 where Doctor_id =4,
update Doctors set salary =20000 where Doctor_id =5
-- alter table Doctors
-- RENAME COLUMN specialization TO department;

select * from Doctors where salary >12000 and department='cardiology'
--3.Display all patients whose name starts with the letter "M".
select * from Patients where fname ILIKE 'M%'
--4.Show doctors whose salary is between 10000 and 20000.
select * from Doctors where salary  between 10000 and 20000
--5.Display doctors who specialize in Cardiology or Dermatology. 
select * from Doctors where department in ('cardiology','Dermatology')
--6.Display doctors who do not work in the Neurology department.
select * from Doctors where department not in ('neurology') 

select * from Doctor_Treats_Patient;
select * from patient_medicine
select * from Medicine
select * from Patients
select * from Doctors
-- 7.Find all patients who did not enter their phone number.
select * from Patients where email is null
-- 8.Display doctor name and salary, and create a new column called salary_status: If salary > 15000 → "High Salary" Otherwise → "Normal Salary" 
select fname , salary,
case
	when salary >=15000 then 'High Salary'
	else 'Normal Salary' 
end as salary_status
from Doctors 
-- 9.Display all patients who have appointments with doctor_id = 1. 
select * from Doctor_Treats_Patient where doctor_id = 1
-- 10.Create a new table called high_salary_doctors and insert doctors whose salary is greater than 15000. 
select * from Doctors
create table high_salary_doctors (
doctor_id int references Doctors(doctor_id) 
, department varchar(20) 
,salary NUMERIC(10,2) );
-- search on insert select
select doctor_id, department,salary from Doctors where salary >=15000

insert into high_salary_doctors (doctor_id,department,salary) values (4,'Pediatrics',15000)
,(5,'Dermatology',20000)
-- 11.Display the doctors who have at least one appointment with a patient in the system.
select distinct doctor_id from Doctor_Treats_Patient

---
select * from Doctor_Treats_Patient;
select * from patient_medicine
select * from Medicine
select * from Patients
select * from Doctors
---

-- 16.UPPER / LOWER / INITCAP Display all patient names in uppercase, lowercase, and capitalized format (first letter of each word uppercase).
select * from Patients
select  fname,lname
	,UPPER(fname) AS fname,
    LOWER(lname) AS lname,
    INITCAP(fname || ' ' || lname) AS fullNameCapitalized
from Patients
-- 17.TRIM / LTRIM / RTRIM Clean up the phone column by removing leading and trailing spaces. 
update Patients set email='   A@gmail.com '   where  Patient_id=1
update Patients set email='   B@gmail.com '   where  Patient_id=2
update Patients set email='   C@gmail.com '   where  Patient_id=3
update Patients set email='   D@gmail.com '   where  Patient_id=4

select email ,TRIM(email),LTRIM(email),RTRIM(email) from Patients
-- 18.CONCAT Display full patient info combining name and phone as a single column called contact_info. 
select CONCAT(fname ||' his email is : ' || email) as contact_info from Patients 
-- 19.SUBSTRING / POSITION Extract the first 3 letters of patient names and find the position of letter "a" in the name.

select SUBSTRING(fname  FROM 1 FOR 3) as subString_name ,POSITION('a' IN fname) as Postion_of_a from Patients

--20.REPLACE In doctor names, replace "Ahmed" with "Ahmad". 
select * from Doctors

SELECT 
    fname AS original_name,
    REPLACE(fname, 'ahmed', 'Ahmad') AS updated_name
from Doctors

--21.CASTING Display doctor salary as integer and as text in separate columns.

select 
    fname,
    salary,
    salary::int as salary_as_integer,
    salary::varchar(10) as salary_as_text
from Doctors;


--------Day 2-------

-- create table Doctors (
-- doctor_id serial primary key,
-- fName varchar(20),
-- mName varchar(20),
-- Lname varchar(20),
-- specialization varchar(20),
-- qualification text
-- );
-- -- insertion doctors--
-- insert into doctors (fname, mname, lname, specialization, qualification)
-- values 
-- ('ahmed', 'm.', 'ali', 'cardiology', 'md'),
-- ('sara', 'k.', 'hassan', 'neurology', 'phd'),
-- ('omar', 'a.', 'youssef', 'orthopedics', 'ms');
-- -- #####
-- create table Patients (
-- Patient_id serial primary key,
-- fName varchar(20),
-- mName varchar(20),
-- Lname varchar(20),
-- dob date ,
-- locality text ,
-- city varchar(20),
-- doctor_id int, 
-- foreign key (doctor_id) references Doctors(doctor_id) 
-- ON update cascade on delete cascade
-- );
-- -- insertion patients--
-- insert into patients (fname, mname, lname, dob, locality, city, doctor_id)
-- values
-- ('mona', 's.', 'ibrahim', '1990-05-12', 'nasr city', 'cairo', 1),
-- ('khaled', 'm.', 'fathy', '1985-03-20', 'heliopolis', 'cairo', 2),
-- ('nour', 'a.', 'mahmoud', '2000-07-01', 'dokki', 'giza', 3),
-- ('hany', 'r.', 'salem', '1995-11-15', 'shubra', 'cairo', 1),
-- ('layla', 't.', 'mostafa', '1988-09-09', 'maadi', 'cairo', 2);

-- create table Medicine (
-- med_code int primary key,
-- medicineName varchar(50),
-- price NUMERIC(10,2) ,
-- quantity int 
-- );

-- insert into Medicine (med_code, medicineName, price, quantity)
-- values
-- (777, 'paracetamol', 20.00, 100),
-- (555, 'ibuprofen', 35.00, 50),
-- (666, 'amoxicillin', 60.00, 30),
-- (888, 'vitamin c', 15.00, 200),
-- (999, 'aspirin', 25.00, 80);

-- create table patient_medicine (
-- bill_id serial primary key,
-- Patient_id int references Patients(Patient_id) ,
-- med_code int references Medicine(med_code) ,
-- quantity int ,
-- bill_date date  
-- );



-- drop table patient_medicine;
-- drop table Medicine;
-- drop table patient_medicine;
-- drop table patient_medicine;

