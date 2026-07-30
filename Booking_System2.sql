-- ==========================================
-- DROP ALL TABLES (CLEAN START)
-- ==========================================

drop table if exists seat_occupancy cascade;
drop table if exists room_occupancy cascade;
drop table if exists payment cascade;
drop table if exists review cascade;
drop table if exists flight_booking cascade;
drop table if exists room_booking cascade;
drop table if exists flight cascade;
drop table if exists airline cascade;
drop table if exists room cascade;
drop table if exists hotel cascade;
drop table if exists "user" cascade;

-- ==========================================
-- TABLE CREATION
-- ==========================================

-- 1. user table
create table "user" (
    user_id serial primary key,
    name varchar(100) not null,
    email varchar(100) unique not null,
    phone varchar(20),
    password varchar(255) not null,
    role varchar(20) not null check (role in ('customer', 'admin')),
    age int,
    gender varchar(10) check (gender in ('male', 'female', 'other')),
    created_at timestamp default now()
);

-- 2. hotel table
create table hotel (
    hotel_id serial primary key,
    name varchar(200) not null,
    location varchar(200) not null,
    rating decimal(2,1) check (rating between 0 and 5),
    description text,
    created_at timestamp default now()
);

-- 3. room table (availability column removed)
create table room (
    room_id serial primary key,
    hotel_id int not null references hotel(hotel_id) on delete cascade,
    type varchar(50) not null,
    price decimal(10,2) not null
);

-- 4. airline table
create table airline (
    airline_id serial primary key,
    name varchar(100) not null,
    code varchar(3) unique
);

-- 5. flight table
create table flight (
    flight_id serial primary key,
    airline_id int not null references airline(airline_id),
    departure_city varchar(100) not null,
    arrival_city varchar(100) not null,
    dep_time timestamp not null,
    arr_time timestamp not null,
    price decimal(10,2) not null,
    total_seats int not null
);

-- 6. room_booking table (with history fields)
create table room_booking (
    room_booking_id serial primary key,
    user_id int not null references "user"(user_id),
    room_id int not null references room(room_id),
    check_in date not null,
    check_out date not null,
    price decimal(10,2) not null,
    status varchar(20) not null check (status in ('confirmed', 'cancelled')),
    booking_date timestamp default now(),
    updated_at timestamp default now(),
    cancelled_at timestamp,
    cancelled_by int references "user"(user_id)
);

-- 7. flight_booking table (with history fields)
create table flight_booking (
    flight_booking_id serial primary key,
    user_id int not null references "user"(user_id),
    flight_id int not null references flight(flight_id),
    seat_number varchar(4) not null,
    price decimal(10,2) not null,
    status varchar(20) not null check (status in ('confirmed', 'cancelled')),
    booking_date timestamp default now(),
    updated_at timestamp default now(),
    cancelled_at timestamp,
    cancelled_by int references "user"(user_id)
);

-- 8. room_occupancy (double‑booking prevention for rooms)
create table room_occupancy (
    room_id int not null references room(room_id) on delete cascade,
    night_date date not null,
    room_booking_id int not null references room_booking(room_booking_id) on delete cascade,
    primary key (room_id, night_date)
);

-- 9. seat_occupancy (double‑booking prevention for flights)
create table seat_occupancy (
    flight_id int not null references flight(flight_id) on delete cascade,
    seat_number varchar(4) not null,
    flight_booking_id int not null references flight_booking(flight_booking_id) on delete cascade,
    primary key (flight_id, seat_number)
);

-- 10. payment table
create table payment (
    payment_id serial primary key,
    room_booking_id int references room_booking(room_booking_id) on delete set null,
    flight_booking_id int references flight_booking(flight_booking_id) on delete set null,
    amount decimal(10,2) not null,
    method varchar(50) not null check (method in ('credit', 'cash', 'wallet')),
    payment_date timestamp default now(),
    status varchar(20) default 'completed',
    constraint chk_one_booking check (
        (room_booking_id is not null and flight_booking_id is null) or
        (room_booking_id is null and flight_booking_id is not null)
    )
);

-- 11. review table
create table review (
    review_id serial primary key,
    user_id int not null references "user"(user_id),
    hotel_id int not null references hotel(hotel_id) on delete cascade,
    rating int check (rating between 1 and 5),
    comment text,
    created_at timestamp default now()
);

-- ==========================================
-- INDEXES
-- ==========================================

create index idx_room_booking_user on room_booking(user_id);
create index idx_room_booking_room on room_booking(room_id);
create index idx_room_booking_status on room_booking(status);
create index idx_room_booking_dates on room_booking(check_in, check_out);
create index idx_room_booking_cancelled_by on room_booking(cancelled_by) where cancelled_by is not null;

create index idx_flight_booking_user on flight_booking(user_id);
create index idx_flight_booking_flight on flight_booking(flight_id);
create index idx_flight_booking_status on flight_booking(status);
create index idx_flight_booking_cancelled_by on flight_booking(cancelled_by) where cancelled_by is not null;

create index idx_room_occupancy_room_night on room_occupancy(room_id, night_date);
create index idx_seat_occupancy_flight on seat_occupancy(flight_id);

create index idx_payment_room_booking on payment(room_booking_id) where room_booking_id is not null;
create index idx_payment_flight_booking on payment(flight_booking_id) where flight_booking_id is not null;

create index idx_review_hotel on review(hotel_id);
create index idx_review_user on review(user_id);

-- ==========================================
-- TRIGGERS AND FUNCTIONS
-- ==========================================

-- Generic function to update updated_at on any change
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- ==================== ROOM BOOKING ====================
-- BEFORE trigger: set cancelled_at when status changes to 'cancelled'
create or replace function set_room_booking_cancelled_at()
returns trigger as $$
begin
    if new.status = 'cancelled' and old.status = 'confirmed' and new.cancelled_at is null then
        new.cancelled_at = now();
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_room_booking_set_cancelled_at
before update on room_booking
for each row execute function set_room_booking_cancelled_at();

-- AFTER trigger: handle occupancy changes (insert/delete)
create or replace function handle_room_booking_occupancy()
returns trigger as $$
begin
    if new.status = 'confirmed' and (old is null or old.status != 'confirmed') then
        -- Insert occupancy nights
        insert into room_occupancy (room_id, night_date, room_booking_id)
        select new.room_id, generate_series(new.check_in, new.check_out - 1, '1 day'), new.room_booking_id;
    elsif new.status = 'cancelled' and old.status = 'confirmed' then
        -- Delete occupancy rows
        delete from room_occupancy where room_booking_id = new.room_booking_id;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_room_booking_occupancy
after insert or update of status on room_booking
for each row execute function handle_room_booking_occupancy();

-- ==================== FLIGHT BOOKING ====================
-- BEFORE trigger: set cancelled_at when status changes to 'cancelled'
create or replace function set_flight_booking_cancelled_at()
returns trigger as $$
begin
    if new.status = 'cancelled' and old.status = 'confirmed' and new.cancelled_at is null then
        new.cancelled_at = now();
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_flight_booking_set_cancelled_at
before update on flight_booking
for each row execute function set_flight_booking_cancelled_at();

-- AFTER trigger: handle occupancy changes (insert/delete)
create or replace function handle_flight_booking_occupancy()
returns trigger as $$
begin
    if new.status = 'confirmed' and (old is null or old.status != 'confirmed') then
        insert into seat_occupancy (flight_id, seat_number, flight_booking_id)
        values (new.flight_id, new.seat_number, new.flight_booking_id);
    elsif new.status = 'cancelled' and old.status = 'confirmed' then
        delete from seat_occupancy where flight_booking_id = new.flight_booking_id;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_flight_booking_occupancy
after insert or update of status on flight_booking
for each row execute function handle_flight_booking_occupancy();

-- ==================== COMMON UPDATED_AT TRIGGERS ====================
create trigger trg_room_booking_updated_at
before update on room_booking
for each row execute function update_updated_at_column();

create trigger trg_flight_booking_updated_at
before update on flight_booking
for each row execute function update_updated_at_column();

-- ==========================================
-- SAMPLE DATA INSERTION (EGYPT LOCALIZED)
-- ==========================================

-- 1. Users
insert into "user" (name, email, phone, password, role, age, gender) values
('Ahmed Ali', 'ahmed@email.com', '+201234567890', 'hashed_pw_ahmed', 'customer', 32, 'male'),
('Sara Mohamed', 'sara@email.com', '+201098765432', 'hashed_pw_sara', 'customer', 28, 'female'),
('Admin User', 'admin@egypttravel.com', null, 'hashed_pw_admin', 'admin', null, null),
('Abdo Magdy', 'abdo_magdy@email.com', '+201234567891', 'hashed_pw_abdo', 'customer', 25, 'male'),
('Mhmd Hosny', 'mhmd_hosny@email.com', '+201098765433', 'hashed_pw_mhmdH', 'customer', 30, 'male'),
('Mhmd Essam', 'mhmd_essam@email.com', '+201112233445', 'hashed_pw_mhmdE', 'customer', 22, 'male'),
('Fatma', 'fatma@email.com', '+201554433221', 'hashed_pw_fatma', 'customer', 35, 'female'),
('karim', 'karim@email.com', '+201234567777', 'hashed_pw_karim', 'customer', 41, 'male'),
('sandy', 'eng_sandy@email.com', '+201098765555', 'hashed_pw_sandy', 'customer', 51, 'female');

-- 2. Hotels
insert into hotel (name, location, rating, description) values
('Stella Resort', 'Sharm El Sheikh', 4.8, 'Luxury resort on the Red Sea.'),
('Mena House', 'Giza', 4.5, 'Overlooking the Pyramids.'),
('Hilton Alexandria', 'Alexandria', 4.2, 'On the Mediterranean coast.'),
('Marlies Resort', 'Hurghada', 4.7, 'Resort with diving and water activities.'),
('Venice Hotel', 'Luxor', 4.3, 'Close to Karnak Temple.'),
('Horus Eye', 'Sharm El Sheikh', 3.8, 'Resort with ancient egyptian vibes.'),
('Elsadat ', 'Sharm El Sheikh', 4.0, 'close to mountains and red sea'),
('sun beach ', 'Hurghada', 3.5, 'private beach area and direct beachfront access.')

-- 3. Rooms (no availability column)
alter table room
add column capacity int;

-- Stella Resort
insert into room (hotel_id, type, price) values
(1, 'Standard Garden View', 1200.00),
(1, 'Sea View', 1800.00),
(1, 'Suite', 2500.00);

-- Mena House
insert into room (hotel_id, type, price) values
(2, 'Standard', 1500.00),
(2, 'Pyramid View', 2200.00),
(2, 'Royal Suite', 3500.00);

-- Hilton Alexandria
insert into room (hotel_id, type, price) values
(3, 'Standard', 1000.00),
(3, 'Sea View', 1400.00),
(3, 'Executive Suite', 2100.00);

-- Marlies Resort
insert into room (hotel_id, type, price) values
(4, 'Standard', 1100.00),
(4, 'Pool View', 1500.00),
(4, 'Family Suite', 2300.00);

-- Venice Hotel
insert into room (hotel_id, type, price) values
(5, 'Standard', 800.00),
(5, 'Nile View', 1200.00),
(5, 'Deluxe', 1600.00);

update room
set capacity = case
    when type ILIKE 'standard' then 2
    when type ILIKE 'sea view' then 2
    when type ILIKE 'suite' then 4
    when type ILIKE 'pyramid view' then 3
    when type ILIKE 'royal suite' then 5
    when type ILIKE 'executive suite' then 4
    when type ILIKE 'family suite' then 6
    when type ILIKE 'deluxe' then 3
    when type ILIKE 'nile view' then 2
    when type ILIKE 'pool view' then 3
    else 2
end;
select * from room;
-- 4. Airlines
insert into airline (name, code) values
('EgyptAir', 'MS'),
('Air Cairo', 'SM'),
('Nile Air', 'NP');

-- 5. Flights
insert into flight (airline_id, departure_city, arrival_city, dep_time, arr_time, price, total_seats) values
-- EgyptAir flights
(1, 'Cairo', 'Sharm El Sheikh', '2025-08-01 08:00:00', '2025-08-01 09:15:00', 950.00, 180),
(1, 'Cairo', 'Luxor', '2025-08-02 10:00:00', '2025-08-02 11:30:00', 850.00, 150),
(1, 'Cairo', 'Hurghada', '2025-08-03 14:00:00', '2025-08-03 15:15:00', 900.00, 160),
(1, 'Alexandria', 'Sharm El Sheikh', '2025-08-04 12:30:00', '2025-08-04 14:00:00', 1100.00, 120),
-- Air Cairo
(2, 'Cairo', 'Alexandria', '2025-08-05 07:00:00', '2025-08-05 08:00:00', 500.00, 200),
(2, 'Sharm El Sheikh', 'Luxor', '2025-08-06 15:00:00', '2025-08-06 16:30:00', 750.00, 100),
-- Nile Air
(3, 'Cairo', 'Aswan', '2025-08-07 11:00:00', '2025-08-07 12:45:00', 1000.00, 140),
(3, 'Hurghada', 'Cairo', '2025-08-08 18:00:00', '2025-08-08 19:15:00', 850.00, 130);

-- 6. Room Bookings
-- Booking 1: Ahmed books Stella Resort, Sea View, 3 nights, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (1, 2, '2025-07-10', '2025-07-13', 1800.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 5400.00, 'credit');

-- Booking 2: Sara books Mena House, Pyramid View, 2 nights, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (2, 5, '2025-07-15', '2025-07-17', 2200.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 4400.00, 'wallet');

-- Booking 3: Ahmed books Marlies Resort, Family Suite, 4 nights, later cancelled
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (1, 12, '2025-08-01', '2025-08-05', 2300.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 9200.00, 'credit');
-- Cancel booking 3 (admin)
update room_booking set status = 'cancelled', cancelled_by = 3 where room_booking_id = currval('room_booking_room_booking_id_seq');

-- Booking 4: Sara books Hilton Alexandria, Sea View, 1 night, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (2, 8, '2025-07-20', '2025-07-21', 1400.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 1400.00, 'cash');

-- Booking 5: Abdo books Mena House, Standard, 1 night, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (4, 4, '2025-08-05', '2025-08-06', 1500.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 1500.00, 'wallet');

-- Booking 6: Mhmd Hosny books Stella Resort, Standard Garden View, 4 nights, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (5, 1, '2025-08-10', '2025-08-14', 1200.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 4800.00, 'credit');

-- Booking 7: Mhmd Essam books Venice Hotel, Nile View, 3 nights, later cancelled
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (6, 14, '2025-08-15', '2025-08-18', 1200.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 3600.00, 'cash');
-- Cancel booking 7 (admin)
update room_booking set status = 'cancelled', cancelled_by = 3 where room_booking_id = currval('room_booking_room_booking_id_seq');

-- Booking 8: Fatma books Hilton Alexandria, Executive Suite, 2 nights, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (7, 9, '2025-08-20', '2025-08-22', 2100.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 4200.00, 'credit');

-- Booking 9: Ahmed Ali books Marlies Resort, Pool View, 3 nights, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (1, 11, '2025-08-25', '2025-08-28', 1500.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 4500.00, 'wallet');

-- Booking 10: Sara Mohamed books Stella Resort, Suite, 5 nights, confirmed
insert into room_booking (user_id, room_id, check_in, check_out, price, status)
values (2, 3, '2025-09-01', '2025-09-06', 2500.00, 'confirmed')
returning room_booking_id;
insert into payment (room_booking_id, amount, method) values (currval('room_booking_room_booking_id_seq'), 12500.00, 'credit');

-- 7. Flight Bookings
-- Flight booking 1: Ahmed books EgyptAir Cairo→Sharm, seat 12A, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (1, 1, '12A', 950.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 950.00, 'credit');

-- Flight booking 2: Sara books Air Cairo Cairo→Alexandria, seat 5B, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (2, 5, '5B', 500.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 500.00, 'wallet');

-- Flight booking 3: Ahmed books EgyptAir Cairo→Luxor, seat 8C, later cancelled
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (1, 2, '8C', 850.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 850.00, 'credit');
-- Cancel flight booking 3 (customer)
update flight_booking set status = 'cancelled', cancelled_by = 1 where flight_booking_id = currval('flight_booking_flight_booking_id_seq');

-- Flight booking 4: Sara books Nile Air Hurghada→Cairo, seat 10F, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (2, 8, '10F', 850.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 850.00, 'cash');

-- Flight booking 5: Abdo books EgyptAir Cairo→Hurghada, seat 14C, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (4, 3, '14C', 900.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 900.00, 'cash');

-- Flight booking 6: Mhmd Hosny books Air Cairo Sharm→Luxor, seat 2A, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (5, 6, '2A', 750.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 750.00, 'credit');

-- Flight booking 7: Mhmd Essam books Nile Air Cairo→Aswan, seat 7F, later cancelled
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (6, 7, '7F', 1000.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 1000.00, 'wallet');
-- Cancel flight booking 7 (customer)
update flight_booking set status = 'cancelled', cancelled_by = 6 where flight_booking_id = currval('flight_booking_flight_booking_id_seq');

-- Flight booking 8: Fatma books EgyptAir Alexandria→Sharm, seat 3B, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (7, 4, '3B', 1100.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 1100.00, 'credit');

-- Flight booking 9: Ahmed Ali books Air Cairo Cairo→Alexandria, seat 12D, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (1, 5, '12D', 500.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 500.00, 'cash');

-- Flight booking 10: Sara Mohamed books Nile Air Hurghada→Cairo, seat 4E, confirmed
insert into flight_booking (user_id, flight_id, seat_number, price, status)
values (2, 8, '4E', 850.00, 'confirmed')
returning flight_booking_id;
insert into payment (flight_booking_id, amount, method) values (currval('flight_booking_flight_booking_id_seq'), 850.00, 'credit');

-- 8. Reviews
insert into review (user_id, hotel_id, rating, comment) values
(1, 1, 5, 'Wonderful resort, great service and beautiful beach.'),
(2, 2, 5, 'Unforgettable view of the pyramids!'),
(1, 3, 4, 'Nice hotel, but room was a bit dated.'),
(2, 4, 5, 'Perfect for diving, staff very friendly.'),
(4, 5, 4, 'Nice hotel, but a bit far from the center.'),
(5, 1, 5, 'Excellent diving center!'),
(6, 3, 3, 'Good location but rooms need renovation.'),
(7, 4, 5, 'Family friendly and very clean.'),
(1, 2, 5, 'Magical view, worth every penny.');

---------------------quries  -------------------


select * from "user";
select * from hotel;
select * from room;
select * from airline;
select * from flight;
select * from room_booking;
select * from flight_booking;
select * from room_occupancy;
select * from seat_occupancy;
select * from payment;
select * from review;


-- system – automated insights


-- user average age by role
select count(*) as "total_customers",
       round(avg(age), 2) as avg_ages
from "user"
group by role;

-- age group distribution of customers
with group_ages_table as (
    select name, age,
           case
               when age between 20 and 30 then 'age [20-30]'
               when age between 31 and 40 then 'age [31-40]'
               when age between 41 and 50 then 'age [41-50]'
               when age > 50 then 'age > 50'
           end as grouped_ages
    from "user"
    where role = 'customer'
)
select grouped_ages, count(*)
from group_ages_table
group by grouped_ages;

-- gender distribution of customers
select gender, count(*)
from "user"
where role = 'customer'
group by gender;

-- no. of rooms booked per month
select 
    to_char(check_in, 'Month') as booking_month,
    count(*) as total_room_bookings
from room_booking
group by booking_month
order by booking_month;

-- no. of flights booked per month
select 
    to_char(booking_date, 'Month') as booking_month,
    count(*) as total_flight_bookings
from flight_booking
group by booking_month
order by booking_month;

-- ==========================================
-- managers – strategic decisions
-- ==========================================

-- best 3 hotels (for partnership or bonuses)
select * from hotel order by rating desc limit 3;

-- group rating for hotels (overall quality distribution)
select grouped_rating_hotels, string_agg(name, ' , ') as hotels from (
    select name,
           case
               when rating between 4.5 and 5 then 'rating [4.5-5]'
               when rating between 4.0 and 4.5 then 'rating [4-4.5]'
               when rating between 3.0 and 4.0 then 'rating [3-4]'
           end as grouped_rating_hotels
    from hotel
) group by grouped_rating_hotels order by grouped_rating_hotels desc;

-- capacity of each hotel (room count)
select h.hotel_id, h.name, sum(capacity) as capacity_of_hotel
from hotel h
join room r using(hotel_id)
group by h.hotel_id, h.name;

-- reserved seats and available seats per flight (occupancy insight)
select f.flight_id, f.total_seats,
       count(so.seat_number) as "reserved seats",
       f.total_seats - count(so.seat_number) as "available seats"
from seat_occupancy so
join flight f using(flight_id)
group by f.flight_id, f.total_seats
order by flight_id;

-- total passengers per flight (with names)
select fb.flight_id,
       count(u.*) as "total passengers",
       array_agg(u.name) as "passengers names",
       array_agg(u.user_id) as "passengers id's"
from "user" u
join flight_booking fb on u.user_id = fb.user_id
group by fb.flight_id
order by fb.flight_id;

-- most booked flights (popularity)
select flight_id,
       count(*) as booking_count,
       dense_rank() over (order by count(*) desc) as "most booked flights(Rank)"
from flight_booking
group by flight_id
order by "most booked flights(Rank)";

-- top customers by number of flights taken
select user_id,
       count(*) as booking_count,
       dense_rank() over (order by count(*) desc) as rank_by_occurrence
from flight_booking
group by user_id
order by rank_by_occurrence;

-- group hotel names by location (for regional analysis)
select location, string_agg(name, ' , ') as hotels
from hotel
group by location;

-- sells per hotel and their location to increase or end partnerships with them
select h.location,
       h.name as "hotel name",
       array_agg(coalesce(room_id::text, 'none')) as "verified room ids",
       count(room_id) as "no. rooms booked",
       array_agg(coalesce(((rb.check_out - rb.check_in) * rb.price)::text, '-')) as "tot prices per residence",
       coalesce(sum(((rb.check_out - rb.check_in) * rb.price)), 0) as "total revenue"
from room r
join room_booking rb using (room_id)
right join hotel h using (hotel_id)
group by location, name;

-- sells per airlines (confirmed and cancelled)
select a.name as airline_name,
       fb.status,
       array_agg(flight_id::text) as verified_flight_ids,
       count(flight_id) as "no_flight_booked/cancelled",
       array_agg(case when fb.status = 'confirmed' then fb.price::text else '-' end) as price_of_flight,
       coalesce(sum(case when fb.status = 'confirmed' then fb.price else 0 end), 0) as total_revenue
from airline a
left join flight f using (airline_id)
left join flight_booking fb using (flight_id)
group by a.name, fb.status
order by a.name, fb.status;

-- cancellation rate per airlines
with cancelation_confirmation_rate as (
    select a.name as airline_name,
           fb.status,
           array_agg(flight_id) as verified_flight_ids,
           count(flight_id) as "no_flight_booked/cancelled"
    from airline a
    left join flight f using (airline_id)
    left join flight_booking fb using (flight_id)
    group by a.name, fb.status
)
select airline_name,
       status,
       "no_flight_booked/cancelled",
       round(
           "no_flight_booked/cancelled"::numeric
           / sum("no_flight_booked/cancelled") over (partition by airline_name)
           * 100, 2
       ) as rate_percent
from cancelation_confirmation_rate
order by airline_name, status;

-- cancellation / confirmation rate per hotels
select *
from (
    with cancelation_confirmation_rate as (
        select h.name as hotel_name,
               coalesce(rb.status, 'none') as status,
               coalesce(
                   case when count(rb.room_id) = 0 then null
                        else array_agg(rb.room_id::text) end,
                   array['none']::text[]
               ) as verified_room_ids,
               coalesce(count(r.room_id), 0) as no_room_booked_cancelled
        from hotel h
        left join room r using (hotel_id)
        left join room_booking rb using (room_id)
        group by h.name, rb.status
    )
    select hotel_name,
           status,
           no_room_booked_cancelled,
           verified_room_ids,
           round(
               coalesce(
                   no_room_booked_cancelled::numeric
                   / nullif(sum(no_room_booked_cancelled) over (partition by hotel_name), 0),
                   0
               ) * 100, 2
           ) as rate_percent
    from cancelation_confirmation_rate
    order by hotel_name desc
) where not (status = 'none' and no_room_booked_cancelled <> 0);

-- rating from reviews of users for each hotel to know best hotels and worst hotels
select h.location,
       h.name as "hotel name",
       array_agg(r.rating),
       round(avg(r.rating), 2) as "user rating"
from hotel h
join review r using (hotel_id)
group by location, name
order by "user rating" desc;

-- ==========================================
-- users – search and availability
-- ==========================================

-- only available rooms (with no occupancy at all)
select r.*, true as availability, h.name as hotel_name
from room r
join hotel h on r.hotel_id = h.hotel_id
where not exists (
    select 1 from room_occupancy ro where ro.room_id = r.room_id
);

-- only available rooms for specific dates (example: 2025-07-10 to 2025-07-21)
with user_input as (
    select date '2025-07-10' as check_in,
           date '2025-07-21' as check_out
)
select r.room_id, r.price, r.type, r.hotel_id, h.name as hotel_name
from room r
join hotel h on r.hotel_id = h.hotel_id
where r.room_id not in (
    select distinct ro.room_id
    from room_occupancy ro
    join user_input i on ro.night_date between i.check_in and i.check_out
);

-- flights from Cairo to Sharm El Sheikh
select a.airline_id, a.name, f.*
from flight f
join airline a using(airline_id)
where departure_city = 'Cairo' and arrival_city ilike 'sharm%';

-- cheapest 3 flights
with cte as (
    select a.airline_id, a.name, f.departure_city, f.arrival_city,
           row_number() over (order by f.price) as cheapest_3_flights
    from flight f
    join airline a using(airline_id)
)
select * from cte where cheapest_3_flights <= 3;

-- only reserved rooms (rooms that have been booked at least once)
select r.*, false as availability, h.name as hotel_name
from room r
join hotel h on r.hotel_id = h.hotel_id
where exists (
    select 1 from room_occupancy ro where ro.room_id = r.room_id
);

-- to know all flights or rooms booked between specific dates
select * from flight
where dep_time between date('2025-08-01') and date('2025-08-05') and departure_city = 'Cairo';
-- --for data analysis
-- -- User avg ages 
-- select count(*) as "total_customers", round(avg(age) ,2)as avg_ages from "user" 
-- group by role;
-- -- divide into grouped ages
-- 							-- select   count(name)  from "user" as u 
-- 							-- where age  between  20 and 30 
-- 							-- union all
-- 							-- select   count(name)  from "user" as u 
-- 							-- where age between 31 and 40 ;
-- with group_ages_table as(
-- select name ,age ,case
-- 					when age between 20 and 30  then 'age [20-30]'
-- 					when age between 31 and 40  then 'age [31-40]'
-- 					when age between 41 and 50  then 'age [41-50]'
-- 					when age > 50 then 'age > 50'
-- 					end as "grouped_ages"
-- from "user"
-- where role='customer'
-- )
-- select grouped_ages ,count(*) from group_ages_table
-- group by grouped_ages;

-- -- divide into grouped genders

-- select gender ,count(*) 
-- from "user"
-- where role='customer'
-- group by gender

-- -- ######### hotels #########
--  -- best 3 hotels [to contact for reserving more rooms or future  work or bonus]
--  select * from hotel
--  order by rating desc
--  limit 3;
--  -- group hotel names by location
-- select location, string_agg(name, ' , ') as hotels
-- from hotel
-- group by location;


--  -- group rating for hotels 
-- select grouped_rating_hotels, string_agg(name, ' , ') as hotels  from 
-- 	(
-- 		select name ,case
-- 					when rating between 4.5 and 5  then 'rating [4.5-5]'
-- 					when rating between 4.0 and 4.5  then 'rating [4-4.5]'
-- 					when rating between 3.0 and 4.0  then 'rating [3-4]'
-- 					end as "grouped_rating_hotels"
-- 		from hotel
-- 	)
-- 	group by grouped_rating_hotels
--  order by grouped_rating_hotels desc;

-- -- ######### rooms #########
-- --availaible rooms

-- select * from room_occupancy as ro 

-- -- only reserved rooms
-- select r.*, false as availability ,h.name as hotel_name
-- from room r
-- join  hotel as h
-- on r.hotel_id= h.hotel_id
-- where  exists (
--     select 1
--     from room_occupancy as ro
--     where ro.room_id = r.room_id
-- );

-- -- only availiable rooms 

-- select r.*, true as availability,h.name as hotel_name
-- from room r 
-- join  hotel as h
-- on r.hotel_id= h.hotel_id
-- where not exists (
--     select 1
--     from room_occupancy as ro
--     where ro.room_id = r.room_id 
-- );
-- -- only availiable rooms for specific dates
-- 		-- example input dates
-- 		-- with user_input as (
-- 		--     select date '2025-07-10' as check_in,
-- 		--            date '2025-07-21' as check_out
-- 		-- )
-- 		-- select distinct ro.room_id 
-- 		-- 			from room_occupancy ro join user_input i
-- 		-- 			on ro.night_date between i.check_in and i.check_out -- return 2,5,8 which are resereved in that date
		
					
-- with user_input as (
--     select date '2025-07-10' as check_in,
--            date '2025-07-21' as check_out
-- )
-- select r.room_id , r.price,r.type, r.hotel_id ,h.name as hotel_name 
-- from room  r
-- join  hotel as h
-- on r.hotel_id= h.hotel_id

-- where r.room_id not in (
-- 			select distinct ro.room_id 
-- 			from room_occupancy ro join user_input i
-- 			on ro.night_date between i.check_in and i.check_out -- return 2,5,8 which are resereved in that date
-- )
-- select * from room_occupancy as ro 

-- -- capacity of each hotels
-- select h.hotel_id,h.name , sum(capacity) as capcity_of_hotel 
-- from hotel h
-- join room r
-- using(hotel_id)
-- group by h.hotel_id,h.name 


-- -- ######## flights #########
-- select * from flight;
-- --travelling to  sharm from cairo 
-- select a.airline_id,a.name,f.* from flight f
-- join airline a
-- using (airline_id)
-- where departure_city ='Cairo'  and arrival_city ILIKE 'sharm%' 

-- -- cheapest 3 flights
-- with cte as(
-- select a.airline_id,a.name,f.departure_city ,f.arrival_city,
-- row_number() over (order by f.price) as cheapest_3_flights
-- from flight f
-- join airline a
-- using (airline_id)

-- )
-- select * from cte 
--  where cheapest_3_flights <=3


-- -- reserved seats and available_seats  for each flight_id

-- select f.flight_id,f.total_seats, count(so.seat_number) as "reserved seats",  f.total_seats - count(so.seat_number) as "available seats"

-- from seat_occupancy so
-- join flight f
-- using (flight_id)
-- group by f.flight_id,f.total_seats
-- order by flight_id

-- -- total passengers for each flight 
-- select fb.flight_id, count(u.* )as "total passengers" ,array_agg(u.name ) as "passengers names" ,array_agg(u.user_id ) as "passengers id's" 

-- from "user" as u
-- join flight_booking fb
-- on u.user_id =fb.user_id 
-- group by fb.flight_id
-- order by fb.flight_id

-- -- top customers based on number of flights he take
-- select user_id,
--        count(*) as booking_count,
--        dense_rank() over (order by count(*) desc) as rank_by_occurrence
-- from flight_booking
-- group by user_id
-- order by rank_by_occurrence;

-- --most booked flights

-- select flight_id,
--        count(*) as booking_count,
--        dense_rank() over (order by count(*) desc) as "most booked flights"
-- from flight_booking
-- group by flight_id
-- order by "most booked flights";


-- CRM on genders for data analysis
