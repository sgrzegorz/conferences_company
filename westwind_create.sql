use master 
if exists(select * from sys.databases where name='Westwind')
begin
	drop database Westwind;
end
create database Westwind

use Westwind

CREATE TABLE Conference(
	ConferenceID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	ConferenceName nvarchar(40) not null,
	Startdate DATE not null,
	Enddate DATE not null ,
	Firstname nvarchar(40)  not null,
	Lastname  nvarchar(40) not null,
	Phone int not null,
	Address NVARCHAR(40)
)
ALTER TABLE Conference
ADD CONSTRAINT CHK_StartdateEnddateGetDate CHECK (datediff(day,getdate(),startdate)>0 and datediff(day,startdate,enddate)>0); 
--datediff(day,'2017-10-10','2017-11-11')=32
 ------TIME------  getDate()  --------- StartDate ----Enddate------------FUTURE--->

create table ConferenceDay(
	ConferenceDayID int not null primary key identity(1,1),
	ConferenceID int not null foreign key references Conference(ConferenceID),
	Date date not null,
	LimitOfParticipants int not null check (LimitOfParticipants>=0)

)

CREATE TABLE Price(
	PriceID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
	ConferenceID INT NOT NULL foreign key references Conference(ConferenceID),
	Date date not null,
	Price money not null default(0) check (price>0),
	StudentDiscount float default(0) check(StudentDiscount >=0 and StudentDiscount<=1)
)
ALTER TABLE Price
  ADD CONSTRAINT uq_time UNIQUE(PriceID, Date);


CREATE TABLE Client(
	ClientID int not null primary key identity(1,1),
	isCompany  bit not null,
	CompanyName nvarchar(40),
	Contactname nvarchar(40) not null,
	Phone int not null,
	Address nvarchar(40) not null
)



create table ReservedConference(
	ReservedConferenceID int not null primary key identity(1,1),
	ConferenceID int not null foreign key references Conference(ConferenceID),
	ClientID int not null foreign key references Client(ClientID),
	Date date default getDate(),
	MoneyPaid money not null default 0,
	State char(1) not null default 'A' check (State='A' or State='C' or State='R')
)
ALTER TABLE ReservedConference
  ADD CONSTRAINT uq_ReservedConference UNIQUE(ClientID, ConferenceID);


create table Participant(
	ParticipantID int not null primary key identity(1,1),
	ClientID int not null foreign key references Client(ClientID),
	Firstname nvarchar(40) not null,
	Lastname nvarchar(40) not null,
	Phone int not null,
)

create table ReservedDay(
	ReservedDayID int not null primary key identity(1,1),
	ReservedConferenceID int not null foreign key references ReservedConference(ReservedConferenceID),
	ConferenceDayID int not null foreign key references ConferenceDay(ConferenceDayID),
	StudentCardID varchar(6) unique,
	State char(1) not null default 'A' check (State='A' or State='C' or State='R')
)	

create table Organizer(
	OrganizerId int not null primary key identity(1,1),
	Firstname nvarchar(40) not null,
	Lastname nvarchar(40) not null,
	Phone int,
)

create table Workshop(
	WorkshopId int not null primary key identity(1,1),
	ConfernceDayID int not null foreign key references ConferenceDay(ConferenceDayID),
	OrganizerID int not null foreign key references Organizer(OrganizerID),
	Name nvarchar(40) not null,
	Starttime datetime not null, --przechowuje tylko hh:mm
	Endtime datetime not null,   -- przechowuje tylko hh:mm
	Price money not null default(0),
	Cancelled bit  not null default 0,
	LimitOfParticipants int not null check (LimitOfParticipants>=0)
)
ALTER TABLE Workshop
ADD CONSTRAINT CHK_StarttimeEndtime CHECK (DATEPART(hour, endtime)*60 + DATEPART(minute, endtime) > DATEPART(hour, starttime)*60 + DATEPART(minute, endtime));


create table ReservedWorkshop(
	ReservedWorkshopID int not null primary key identity(1,1),
	ReservedDayID int not null foreign key references ReservedDay(ReservedDayID),
	WorkshopID int not null foreign key references Workshop(WorkshopID),
	State char(1) not null default 'A' check (State='A' or State='C' or State='R')
)

create table RegisteredDay(
	RegisteredDayID int not null primary key identity(1,1),
	ConferenceDayID int not null foreign key references ConferenceDay(ConferenceDayID),
	ParticipantID int not null foreign key references Participant(ParticipantID)

)
--ALTER TABLE RegisteredDay
--ADD CONSTRAINT uq_RegisteredDay UNIQUE(ConferenceDayID, ParticipantID);



create table RegisteredWorkshop(
	RegisteredWorkshopID int not null primary key identity(1,1),
	WorkshopID int not null foreign key references Workshop(WorkshopID),
	RegisteredDayID int not null foreign key references RegisteredDay(RegisteredDayID)
)


