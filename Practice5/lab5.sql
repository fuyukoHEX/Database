-- task 1
create table employees (
    employee_id int,
    first_name text,
    last_name text,
    age int check (age between 18 and 65),
    salary numeric check (salary > 0)
);

create table products_catalog (
    product_id int,
    product_name text,
    regular_price numeric,
    discount_price numeric,
    constraint valid_discount check (regular_price > 0 and discount_price > 0 and discount_price < regular_price)
);

create table bookings (
    booking_id int,
    check_in_date date,
    check_out_date date,
    num_guests int check (num_guests between 1 and 10),
    check (check_out_date > check_in_date)
);

insert into employees values (1, 'ivan', 'ivanov', 30, 5000);
insert into products_catalog values (1, 'phone', 1000, 900);
insert into bookings values (1, '2026-10-15', '2026-10-20', 2);


-- task 2
create table customers_nn (
    customer_id int not null,
    email text not null,
    phone text,
    registration_date date not null
);

create table inventory (
    item_id int not null,
    item_name text not null,
    quantity int not null check (quantity >= 0),
    unit_price numeric not null check (unit_price > 0),
    last_updated timestamp not null
);

insert into customers_nn values (1, 'test@test.com', null, '2026-10-13');


-- task 3
create table users_p3 (
    user_id int,
    username text unique,
    email text unique,
    created_at timestamp
);

create table course_enrollments (
    enrollment_id int,
    student_id int,
    course_code text,
    semester text,
    unique (student_id, course_code, semester)
);

drop table users_p3;

create table users_p3 (
    user_id int,
    username text constraint unique_username unique,
    email text constraint unique_email unique,
    created_at timestamp
);

insert into users_p3 values (1, 'admin', 'admin@mail.com', current_timestamp);


-- task 4
create table departments (
    dept_id int primary key,
    dept_name text not null,
    location text
);

insert into departments values
(1, 'it', 'astana'),
(2, 'hr', 'almaty'),
(3, 'sales', 'astana');

create table student_courses (
    student_id int,
    course_id int,
    enrollment_date date,
    grade text,
    primary key (student_id, course_id)
);


-- task 5
create table employees_dept (
    emp_id int primary key,
    emp_name text not null,
    dept_id int references departments(dept_id),
    hire_date date
);

insert into employees_dept values (1, 'john', 1, '2026-10-13');

create table authors (
    author_id int primary key,
    author_name text not null,
    country text
);

create table publishers (
    publisher_id int primary key,
    publisher_name text not null,
    city text
);

create table books (
    book_id int primary key,
    title text not null,
    author_id int references authors(author_id),
    publisher_id int references publishers(publisher_id),
    publication_year int,
    isbn text unique
);

insert into authors values (1, 'abai', 'kazakhstan');
insert into publishers values (1, 'mektep', 'almaty');
insert into books values (1, 'words', 1, 1, 1900, '12345');

create table categories (
    category_id int primary key,
    category_name text not null
);

create table products_fk (
    product_id int primary key,
    product_name text not null,
    category_id int references categories(category_id) on delete restrict
);

create table orders_fk (
    order_id int primary key,
    order_date date not null
);

create table order_items (
    item_id int primary key,
    order_id int references orders_fk(order_id) on delete cascade,
    product_id int references products_fk(product_id),
    quantity int check (quantity > 0)
);

insert into categories values (1, 'electronics');
insert into products_fk values (1, 'tv', 1);
insert into orders_fk values (1, '2026-10-13');
insert into order_items values (1, 1, 1, 2);

delete from orders_fk where order_id = 1;


-- task 6
create table customers (
    customer_id int primary key,
    name text not null,
    email text unique not null,
    phone text,
    registration_date date not null
);

create table products (
    product_id int primary key,
    name text not null,
    description text,
    price numeric check (price >= 0),
    stock_quantity int check (stock_quantity >= 0)
);

create table orders (
    order_id int primary key,
    customer_id int references customers(customer_id),
    order_date date not null,
    total_amount numeric,
    status text check (status in ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

create table order_details (
    order_detail_id int primary key,
    order_id int references orders(order_id) on delete cascade,
    product_id int references products(product_id) on delete restrict,
    quantity int check (quantity > 0),
    unit_price numeric check (unit_price >= 0)
);