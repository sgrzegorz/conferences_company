use Westwind 

create procedure addPrice
@ConferenceID INT, @Date date, @Price money, @StudentDiscount float
as 
begin
	begin try
	begin transaction
		
		if(@Date > (select top 1 c.Startdate from Conference as c inner join Price as p on c.ConferenceID =p.ConferenceID where c.ConferenceID=@ConferenceID))
		begin
			RAISERROR('Price Term Is After Conference!',16,-1)
		end
		insert into Price(ConferenceID,Date,Price,StudentDiscount)
		values (@ConferenceID,@Date,@Price,@StudentDiscount)
	commit transaction
	end try 
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end

create procedure addConference
	@ConferenceName nvarchar(40),
	@Startdate DATE,
	@Enddate DATE,
	@Firstname nvarchar(40),
	@Lastname nvarchar(40),
	@Phone int,
    @Address NVARCHAR(40)
as
begin
		begin try
		begin transaction
			insert into Conference(ConferenceName,Startdate,Enddate,Firstname,Lastname,Phone,Address)
			values (@ConferenceName,@Startdate,@Enddate,@Firstname,@Lastname,@Phone,@Address)
		commit transaction
		end try
		begin catch
			SELECT ERROR_MESSAGE() AS ErrorMessage;
			ROLLBACK TRANSACTION	
		end catch
		
end 

create procedure addConferenceDay
@ConferenceID int, @Date date, @LimitOfParticipants int
as
begin
	begin try
	begin transaction
		Declare @Startdate date, @Enddate date
		set @Startdate=(select c.startdate from Conference as c where c.ConferenceID = @ConferenceID)
		set @Enddate= (select c.enddate from Conference as c where c.ConferenceID = @ConferenceID)
		if(@Date>=@Startdate and @Date <=@Enddate) RAISERROR('Error day couldnt be inserted because its beyond <Conference.Startdate, Conference.Enddate>  ',16,-1)

			insert into ConferenceDay(ConferenceID,Date,LimitOfParticipants)
			values (@ConferenceID,@Date,@LimitOfParticipants)
	commit transaction
	end try 
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end


create procedure addWorkshop --in datetime only hh:mm are important,
@ConfernceDayID int, @OrganizerID int, @Name nvarchar(40),@Starttime datetime,@Endtime datetime,@Price money,@LimitOfParticipants int
as
begin
	begin try
	begin transaction
		insert into Workshop(ConfernceDayID , OrganizerID, Name,Starttime,Endtime,Price ,LimitOfParticipants)
		values (@ConfernceDayID, @OrganizerID, @Name ,@Starttime ,@Endtime ,@Price,@LimitOfParticipants)
	commit transaction
	end try 
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end
select * from Workshop
execute addWorkshop 222, 34, 'fas', '1955-12-13 12:43:00.000' , '1955-12-13 13:43:00.000', 12,100


create procedure addParticipant 
@ClientID int, @Firstname varchar(40), @LastName varchar(40), @Phone int
as 
begin
	begin try
	begin transaction
		insert into Participant(ClientID,Firstname,Lastname,Phone)
		values (@ClientID, @Firstname, @LastName, @Phone)
	commit transaction
	end try
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end
execute addParticipant 1,'Ola','Godlewska',123456789

create procedure makeIdentifier
@ParticipantID int
as
begin
	begin try
	select CONVERT(varchar(10), p.ParticipantID)+' '+p.FirstName +' '+p.Lastname +' [ '+c.CompanyName +'] 'as 'Identifier'
	from Participant as p inner join client as c
	on p.ClientID = c.ClientID
	where c.IsCompany=1 and p.ParticipantID = @ParticipantID
	union
	select CONVERT(varchar(10), p.ParticipantID)+' '+p.FirstName +' '+p.Lastname +' ' as 'Identifier'
	from Participant as p inner join client as c
	on p.ClientID = c.ClientID
	where c.IsCompany=0 and p.ParticipantID = @ParticipantID
	end try
	begin catch
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end



------------------------------------------------------------------------------------ReservationProcedures-----------------------------------------------------------------------------------------------------

create procedure reserveConference
@ConferenceID int, @ClientID int
as
begin
		begin try
		begin transaction
			insert into ReservedConference(ConferenceID,ClientID)
			values (@ConferenceID,@ClientID)
		commit transaction
		end try
		begin catch
			RAISERROR('Error, transaction not completed!',16,-1)
			ROLLBACK TRANSACTION	
		end catch
end 


create procedure reserveDay
@ReservedConferenceID int,@ConferenceDayID int, @StudentCardID  varchar(6)
as
begin
		begin try
		begin transaction
				insert into ReservedDay(ReservedConferenceID,ConferenceDayID,StudentCardID)
				values(@ReservedConferenceID,@ConferenceDayID,@StudentCardID)
		commit transaction
		end try
		begin catch
			SELECT ERROR_MESSAGE() AS ErrorMessage;
			ROLLBACK TRANSACTION	
		end catch
end 


create procedure reserveWorkshop
@ReservedDayID int,
@WorkshopID int
as
begin
	begin try
	begin transaction
		insert into reservedWorkshop(ReservedDayID,WorkshopID)
		values (@ReservedDayID,@WorkshopID)
	commit transaction
	end try
	begin catch
		SELECT ERROR_MESSAGE() AS ErrorMessage;
		ROLLBACK TRANSACTION	
	end catch
end 


create procedure changeReservedDayRegisteredDay
@ReservedDayID int, @ParticipantID int
as 
begin
	begin try
	begin transaction
		declare  @ConferenceDayID int
		set @ConferenceDayID = (select rd.ConferenceDayID from ReservedDay as rd where rd.ReservedDayID=@ReservedDayID)
		update ReservedDay
		set State='R' where ReservedDayID=@ReservedDayID

		update ReservedWorkshop
		set State='R' where ReservedDayID=@ReservedDayID

		declare @ReservedConferenceID int
		set @ReservedConferenceID= (select rd.ReservedConferenceID from ReservedDay as rd where rd.ReservedDayID=@ReservedDayID) 
		if((select count(*) from ReservedDay as rd where rd.ReservedConferenceID =@ReservedConferenceID and rd.ReservedDayID = @ReservedDayID)=0 )
		begin
			update ReservedConference
			set State='R' where ReservedConference.ReservedConferenceID = @ReservedConferenceID
		end

		insert into RegisteredDay(ConferenceDayID,ParticipantID)
		values (@ConferenceDayID,@ParticipantID)

		declare @RegisteredDayID int
		set @RegisteredDayID = (select rd.RegisteredDayID from RegisteredDay as rd where rd.ConferenceDayID=@ConferenceDayID and rd.ParticipantID=@ParticipantID)

		
		INSERT INTO RegisteredWorkshop(WorkshopID, RegisteredDayID)
		SELECT rw.ReservedWorkshopID, @RegisteredDayID FROM ReservedWorkshop as rw where rw.ReservedDayID= @ReservedDayID

	commit transaction
	end try
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end
execute changeReservedDayRegisteredDay 10,50

create procedure deactivateReservation
@ReservedConferenceID int
as 
begin
	begin try
	begin transaction
		declare @ReservedDayID int

		update ReservedConference
		set Status ='C' where ReservedConferenceID=@ReservedConferenceID
		
		update ReservedDay
		set Status='C' where ReservedConferenceID=@ReservedConferenceID

		update ReservedWorkshop
		set Status ='C' where ReservedWorkshopID in ( select ReservedWorkshopID from
													ReservedDay as rd inner Join RevervedWorkshop as rw
													on rd.ReservedDayID = rw.RevervedWorkshopID
													inner join ReservedConference as rc 
													on rc.ReservedConferenceID = rd.ReservedConferenceID
													where rc.ReservedConferenceID=@ReservedConferenceID 
													)
	commit transaction
	end try
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch
end


create procedure removeReservedConference
@ReservedConferenceID int
as
begin
	begin try
	begin transaction
		delete from ReservedWorkshop
		where ReservedWorkshopID in 
								(
								select rw.ReservedWorkshopID
								from ReservedConference as rc inner join ReservedDay as rd
								on rc.ReservedConferenceID = rd.ReservedConferenceID
								inner join ReservedWorkshop as rw
								on rw.ReservedDayID = rd.ReservedDayID
								where rc.ReservedConferenceID=@ReservedConferenceID
								)
		delete from ReservedDay 
		where ReservedDayID in 
								(
								select rd.ReservedDayID
								from ReservedConference as rc inner join ReservedDay as rd
								on rc.ReservedConferenceID = rd.ReservedConferenceID
								where rc.ReservedConferenceID=@ReservedConferenceID
								)
		delete from ReservedConference
		where ReservedConferenceID = @ReservedConferenceID		
	commit transaction
	end try
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch							
end 

create procedure removeReservedDay
@ReservedDayID int 
as
begin
	begin try
	begin transaction
		delete from ReservedWorkshop
		where ReservedWorkshopID in 
								(
								select rw.ReservedWorkshopID
								from ReservedWorkshop as rw inner join ReservedDay as rd
								on rw.ReservedDayID = rd.ReservedDayID
								where rd.ReservedDayID=@ReservedDayID
								)
		delete from ReservedDay 
		where ReservedDayID=@ReservedDayID
	commit transaction
	end try
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch							
end 

create procedure removeReservedWorkshop
@ReservedWorkshopID int 
as
begin
	begin try
	begin transaction
		delete from ReservedWorkshop
		where ReservedWorkshopID=@ReservedWorkshopID
	commit transaction
	end try
	begin catch
		ROLLBACK TRANSACTION
		SELECT ERROR_MESSAGE() AS ErrorMessage;
	end catch							
end 

