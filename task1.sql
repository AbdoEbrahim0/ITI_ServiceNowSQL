create table books (
bookId serial primary key,
bookDesc TEXT, 
bookName varchar(50) not null,
yearPublish Integer CHECK (yearPublish >= 1500) ,
lastDateReturned Date ,
isTaken Boolean default false,
price numeric(10,2),
bookInfo json ,
categoryId integer
);

-- drop table category;
create  table  category(
categoryId serial primary key,
CategoryName varchar(20)
)
alter table books add constraint fk_category foreign key (categoryId)
references category(categoryId);




