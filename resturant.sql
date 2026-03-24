drop table if exists reservations cascade;
drop table if exists order_items cascade;
drop table if exists orders cascade;
drop table if exists item_ingredients cascade;
drop table if exists items cascade;
drop table if exists ingredients_stock cascade;
drop table if exists tables cascade;
drop table if exists customers cascade;
drop table if exists users cascade;

create table users (
    id serial primary key,
    name varchar(100) not null,
    email varchar(100) unique not null,
    role varchar(50) not null check (role in ('waiter', 'admin', 'staff_member')),
    password varchar(255) not null
);

create table customers (
    id serial primary key,
    customer_name varchar(100) not null,
    email varchar(100) unique,
    password varchar(255),
    phone_number varchar(20),
    address text
);

create table tables (
    id serial primary key,
    chairs_number int not null check (chairs_number > 0),
    status varchar(20) not null default 'available' check (status in ('available', 'reserved', 'occupied')),
    reservation_id int
);

create table items (
    id serial primary key,
    name varchar(100) not null,
    price decimal(10,2) not null check (price >= 0),
    description text
);

create table ingredients_stock (
    id serial primary key,
    name varchar(100) not null,
    qty decimal(10,2) not null default 0 check (qty >= 0)
);

create table item_ingredients (
    id serial primary key,
    item_id integer not null references items(id) on delete cascade,
    ingredient_id integer not null references ingredients_stock(id) on delete restrict,
    quantity_needed decimal(10,2) not null check (quantity_needed > 0),
    unique (item_id, ingredient_id)
);

create table orders (
    id serial primary key,
    customer_id integer references customers(id),
    table_id integer references tables(id),
    total decimal(10,2) default 0,
    payment_method_id integer,
    status varchar(20) not null default 'pending' check (status in ('pending', 'preparing', 'ready', 'served', 'paid')),
    created_at timestamp default current_timestamp
);

create table order_items (
    id serial primary key,
    order_id integer not null references orders(id) on delete cascade,
    item_id integer not null references items(id),
    qty int not null check (qty > 0),
    price decimal(10,2) not null check (price >= 0)
);

create table reservations (
    id serial primary key,
    table_id integer not null references tables(id),
    customer_id integer not null references customers(id),
    order_id integer references orders(id),
    reservation_time timestamp not null,
    duration interval default '2 hours'
);

alter table tables add constraint fk_tables_reservation
    foreign key (reservation_id) references reservations(id) on delete set null;

create or replace function create_simple_order(
    p_customer_id integer,
    p_table_id integer,
    p_items jsonb
) returns integer as $$
declare
    v_order_id integer;
    v_item record;
    v_ingredient record;
begin
    if (select status from tables where id = p_table_id) != 'available' then
        raise exception 'Table % is not available (status: %)', p_table_id, (select status from tables where id = p_table_id);
    end if;

    insert into orders (customer_id, table_id, total, status)
    values (p_customer_id, p_table_id, 0, 'pending')
    returning id into v_order_id;

    for v_item in select * from jsonb_to_recordset(p_items) as x(item_id int, qty int)
    loop
        insert into order_items (order_id, item_id, qty, price)
        select v_order_id, v_item.item_id, v_item.qty, price
        from items where id = v_item.item_id;

        for v_ingredient in
            select ingredient_id, quantity_needed * v_item.qty as needed
            from item_ingredients
            where item_id = v_item.item_id
        loop
            update ingredients_stock
            set qty = qty - v_ingredient.needed
            where id = v_ingredient.ingredient_id;
        end loop;
    end loop;

    update orders
    set total = (select sum(qty * price) from order_items where order_id = v_order_id)
    where id = v_order_id;

    update tables set status = 'occupied' where id = p_table_id;

    return v_order_id;
end;
$$ language plpgsql;

create or replace function create_reservation(
    p_table_id integer,
    p_customer_id integer,
    p_reservation_time timestamp,
    p_duration interval default '2 hours'
) returns integer as $$
declare
    v_reservation_id integer;
begin
    if (select status from tables where id = p_table_id) = 'occupied' then
        raise exception 'Table % is currently occupied, cannot reserve', p_table_id;
    end if;

    insert into reservations (table_id, customer_id, reservation_time, duration)
    values (p_table_id, p_customer_id, p_reservation_time, p_duration)
    returning id into v_reservation_id;

    update tables
    set status = 'reserved', reservation_id = v_reservation_id
    where id = p_table_id;

    return v_reservation_id;
end;
$$ language plpgsql;

create or replace function complete_order(p_order_id integer) returns void as $$
declare
    v_table_id integer;
begin
    select table_id into v_table_id from orders where id = p_order_id;

    if not found then
        raise exception 'Order % not found', p_order_id;
    end if;

    update orders set status = 'paid' where id = p_order_id;

    update tables set status = 'available', reservation_id = null where id = v_table_id;
end;
$$ language plpgsql;

insert into users (name, email, role, password) values
('John Doe', 'john@restaurant.com', 'waiter', 'hashed_pw_1'),
('Jane Smith', 'jane@restaurant.com', 'waiter', 'hashed_pw_2'),
('Admin User', 'admin@restaurant.com', 'admin', 'hashed_pw_3'),
('Mike Staff', 'mike@restaurant.com', 'staff_member', 'hashed_pw_4');

insert into customers (customer_name, email, phone_number, address) values
('Alice Johnson', 'alice@email.com', '1234567890', '123 Main St, City'),
('Bob Brown', 'bob@email.com', '0987654321', '456 Oak Ave, Town'),
('Charlie Davis', 'charlie@email.com', '1122334455', '789 Pine Rd, Village'),
('Diana Evans', 'diana@email.com', '5544332211', '101 Maple Ln, Suburb'),
('Eve Foster', 'eve@email.com', '9988776655', '202 Birch Blvd, Metro');

insert into tables (chairs_number, status, reservation_id) values
(2, 'available', null), (2, 'reserved', null), (4, 'available', null),
(4, 'occupied', null), (4, 'available', null), (6, 'reserved', null),
(6, 'occupied', null), (6, 'available', null), (8, 'available', null),
(8, 'reserved', null), (2, 'available', null), (4, 'occupied', null),
(4, 'reserved', null), (6, 'available', null), (8, 'available', null);

insert into items (name, price, description) values
('Margherita Pizza', 12.99, 'Classic tomato sauce, mozzarella, basil'),
('Pepperoni Pizza', 14.99, 'Tomato sauce, mozzarella, pepperoni'),
('Caesar Salad', 8.99, 'Romaine, croutons, parmesan, caesar dressing'),
('Spaghetti Carbonara', 13.99, 'Pasta, eggs, pecorino, pancetta'),
('Tiramisu', 6.99, 'Coffee soaked ladyfingers, mascarpone');

insert into ingredients_stock (name, qty) values
('Flour', 50.00), ('Tomato Sauce', 30.00), ('Mozzarella', 25.00), ('Pepperoni', 10.00),
('Romaine Lettuce', 15.00), ('Pasta', 20.00), ('Eggs', 60.00), ('Mascarpone', 8.00);

insert into item_ingredients (item_id, ingredient_id, quantity_needed) values
(1, 1, 0.250), (1, 2, 0.150), (1, 3, 0.200),
(2, 1, 0.250), (2, 2, 0.150), (2, 3, 0.200), (2, 4, 0.100),
(3, 5, 0.200), (3, 7, 1.000),
(4, 6, 0.200), (4, 7, 2.000), (4, 8, 0.100),
(5, 7, 2.000), (5, 8, 0.150);

insert into orders (customer_id, table_id, total, status, created_at) values
(1, 4, 0.00, 'pending', '2025-04-01 12:30:00'),
(2, 7, 0.00, 'preparing', '2025-04-01 13:15:00'),
(3, 12, 0.00, 'served', '2025-04-01 18:45:00');

insert into order_items (order_id, item_id, qty, price) values
(1, 1, 2, (select price from items where id=1)),
(1, 3, 1, (select price from items where id=3)),
(2, 2, 1, (select price from items where id=2)),
(2, 4, 1, (select price from items where id=4)),
(3, 5, 2, (select price from items where id=5));

update orders set total = (
    select sum(qty * price) from order_items where order_id = orders.id
) where id in (1,2,3);

insert into reservations (table_id, customer_id, order_id, reservation_time, duration) values
(2, 4, null, '2025-04-02 19:00:00', '2 hours'),
(6, 5, null, '2025-04-02 20:30:00', '1.5 hours'),
(10, 1, 1, '2025-04-01 12:00:00', '2 hours');

update tables set reservation_id = (select id from reservations where table_id = 2 limit 1) where id = 2;
update tables set reservation_id = (select id from reservations where table_id = 6 limit 1) where id = 6;
update tables set reservation_id = (select id from reservations where table_id = 10 limit 1) where id = 10;

select * from tables;