create table Doctors (
doctor_id serial primary key,
fName varchar(20),
mName varchar(20),
Lname varchar(20),
specialization varchar(20),
qualification text
);
-- insertion doctors--
insert into Doctors (fname, mname, lname, specialization, qualification)
values 
('ahmed', 'm.', 'ali', 'cardiology', 'md'),
('sara', 'k.', 'hassan', 'neurology', 'phd'),
('omar', 'a.', 'youssef', 'orthopedics', 'ms');
select * from Doctors;
-- ##########################
create table Patients (
Patient_id serial primary key,
fName varchar(20),
mName varchar(20),
Lname varchar(20),
dob date ,
locality text ,
city varchar(20),
doctor_id int, 
foreign key (doctor_id) references Doctors(doctor_id) 
ON update cascade on delete cascade
);

-- insertion patients--
insert into Patients (fname, mname, lname, dob, locality, city, doctor_id)
values
('mona', 's.', 'ibrahim', '1990-05-12', 'nasr city', 'cairo', 1),
('khaled', 'm.', 'fathy', '1985-03-20', 'heliopolis', 'cairo', 2),
('nour', 'a.', 'mahmoud', '2000-07-01', 'dokki', 'giza', 3),
('hany', 'r.', 'salem', '1995-11-15', 'shubra', 'cairo', 1),
('layla', 't.', 'mostafa', '1988-09-09', 'maadi', 'cairo', 2);

select * from Patients;
-- ##########################
create table Medicine (
med_code int primary key,
medicineName varchar(50),
price NUMERIC(10,2) ,
quantity int 
);
-- insertion medicines--
insert into Medicine (med_code, medicineName, price, quantity)
values
(777, 'paracetamol', 20.00, 100),
(555, 'ibuprofen', 35.00, 50),
(666, 'amoxicillin', 60.00, 30),
(888, 'vitamin c', 15.00, 200),
(999, 'aspirin', 25.00, 80);

select * from Medicine;
-- ##########################
create table patient_medicine (
bill_id serial primary key,
Patient_id int references Patients(Patient_id) ,
med_code int references Medicine(med_code) ,
quantity int ,
bill_date date  
);

insert into patient_medicine (patient_id, med_code, quantity, bill_date)
values
(1, 555, 2, '2026-01-01'),
(2, 666, 1, '2026-02-02'),
(3, 777, 1, '2026-03-03'),
(4, 888, 3, '2026-04-04'),
(5, 999, 2, '2026-05-05');
select * from patient_medicine;
-- ##########################


-- update the price of one medicine
select * from Medicine;
	update Medicine
	set price = price + 7
	where medicineName = 'ibuprofen';
select * from Medicine;
-- update the doctor assigned to one patient
select * from Patients;
	update Patients
	set doctor_id = 1
	where fname = 'mona' and lname = 'ibrahim';
select * from Patients;
-- add a new column phone_number to doctors
select * from Doctors;
	alter table Doctors
	add column phone_number varchar(15);
select * from Doctors;
-- add a new column email to patients and make it unique
select * from patients;
	alter table patients
	add column email varchar(50) unique;
select * from patients;

-- Modify the price column in the medicines table so it cannot accept negative values.
select * from Medicine;
alter table Medicine 
add constraint priceValidatrion check (price>0) ;
select * from Medicine;

--Update the doctor_id in the doctors table and observe the effect on the patients table.
select * from Patients;
select * from Doctors;
update Doctors set  doctor_id=33  where doctor_id=3;  -- it reflect on child table
select * from Patients;
-- drop table Patients;
-- drop table Doctors;
-- drop table Medicine;
-- drop table patient_medicine;


