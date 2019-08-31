use Westwind
create view view_clientWorkshopReservations
as 
select c.CompanyName as 'Client', conf.ConferenceName , ConferenceDay.Date as 'DateOfReservation' , w.Name as 'WorkshopName'
from Client as c inner join ReservedConference as rc
on rc.ClientID = c.ClientID and c.isCompany=1 and c.CompanyName is not null
inner join ReservedDay as rd 
on rd.ReservedConferenceID = rc.ReservedConferenceID
inner join ReservedWorkshop as rw 
on rw.ReservedDayID = rd.ReservedDayID
inner join Conference as conf
on conf.ConferenceID=rc.ConferenceID
inner join ConferenceDay 
on ConferenceDay.ConferenceDayID = rd.ConferenceDayID
inner join Workshop as w
on w.WorkshopID = rw.WorkshopID
union
select c.Contactname as 'Client', conf.ConferenceName , ConferenceDay.Date , w.Name as 'WorkshopName'
from Client as c inner join ReservedConference as rc
on rc.ClientID = c.ClientID and c.isCompany=0
inner join ReservedDay as rd 
on rd.ReservedConferenceID = rc.ReservedConferenceID
inner join ReservedWorkshop as rw 
on rw.ReservedDayID = rd.ReservedDayID
inner join Conference as conf
on conf.ConferenceID=rc.ConferenceID
inner join ConferenceDay 
on ConferenceDay.ConferenceDayID = rd.ConferenceDayID
inner join Workshop as w
on w.WorkshopID = rw.WorkshopID





create view  view_Payments
as
select c.ClientID, rc.ReservedConferenceID, T0.ReservedDaysPrice as 'ReservedDaysPrice', T1.ReservedWorkshopsPrice as 'ReservedWorkshopsPrice' ,  T0.ReservedDaysPrice+ T1.ReservedWorkshopsPrice as 'TotalReservationPrice', rc.MoneyPaid, (T0.ReservedDaysPrice+ T1.ReservedWorkshopsPrice) -rc.MoneyPaid as 'PieniądzeKtóreJeszczeTrzebaWpłacić'
from
(
	select 	T0.ReservedConferenceID, sum(T0.Price) as 'ReservedDaysPrice'
	from
	(
		select rc.ReservedConferenceID, p.price
		from Price as p   
		inner join Conference as c
		on c.ConferenceID =p.ConferenceID   and p.price= 	(
															select  top 1 price
															from price
															where  Date <getDate() and ConferenceID=p.ConferenceID 
															order by date desc
															)      
		inner join ConferenceDay as cd
		on cd.ConferenceID=c.ConferenceID
		inner join ReservedDay as rd
		on rd.ConferenceDayID=cd.ConferenceDayID and rd.StudentCardID is null
		inner join ReservedConference as rc
		on rc.ReservedConferenceID=rd.ReservedConferenceID
		union
		select rc.ReservedConferenceID, (1-p.StudentDiscount)*p.price
		from Price as p   
		inner join Conference as c
		on c.ConferenceID =p.ConferenceID   and p.price= 	(
															select  top 1 price
															from price
															where  Date <getDate() and ConferenceID=p.ConferenceID 
															order by date desc
															)      
		inner join ConferenceDay as cd
		on cd.ConferenceID=c.ConferenceID
		inner join ReservedDay as rd
		on rd.ConferenceDayID=cd.ConferenceDayID and rd.StudentCardID is not null
		inner join ReservedConference as rc
		on rc.ReservedConferenceID=rd.ReservedConferenceID
	)T0
	group by ReservedConferenceID
)T0 inner join 
(
	select rc.ReservedConferenceID, sum(w.price) as 'ReservedWorkshopsPrice'
	from ReservedConference as rc inner join ReservedDay as rd
	on rc.ReservedConferenceID=rd.ReservedConferenceID
	inner join ReservedWorkshop as rw 
	on rw.ReservedDayID=rd.ReservedDayID
	inner join Workshop as w
	on w.WorkshopId=rw.WorkshopID
	group by rc.ReservedConferenceID
)T1	
on T0.ReservedConferenceID = T1.ReservedConferenceID
inner join ReservedConference as rc
on rc.ReservedConferenceID=T1.ReservedConferenceID
inner join client as c
on rc.ClientID = c.ClientID





create view view_dayListOfParticipants
as 
select conf.ConferenceID, cd.ConferenceDayID, p.ParticipantID, p.Firstname, p.Lastname, p.Phone, p.ClientID
from Conference as conf inner join ConferenceDay as cd
on conf.ConferenceID = cd.ConferenceDayID
inner join RegisteredDay as rd 
on rd.ConferenceDayID=cd.ConferenceDayID
inner join Participant as p 
on p.ParticipantID=rd.RegisteredDayID


create view view_workshopListOfParticipants
as
select w.WorkshopID, p.ParticipantID, p.Firstname, p.Lastname, p.Phone, p.ClientID
from 
Workshop as w inner join RegisteredWorkshop as rw 
on w.WorkshopID = rw.WorkshopID
inner join RegisteredDay as rd
on rd.RegisteredDayID=rw.RegisteredDayID
inner join participant as p
on rd.ParticipantID = p.ParticipantID


create view view_canceledReservations
as 
select c.ClientID, rc.ConferenceID, rc.State as 'ReservedConference.State', rd.ConferenceDayID, rd.State as 'ReservedDay.State', rw.ReservedDayID, rw.State as 'ReservedWorkshop.State'  
from Client as c inner join ReservedConference as rc
on c.ClientID = rc.ClientID 
inner join ReservedDay as rd 
on rd.ReservedConferenceID = rc.ReservedConferenceID 
inner join ReservedWorkshop as rw 
on rw.ReservedDayID = rd.ReservedDayID and rw.State ='C'


create view view_Top40Clients
as
select top 40 T0.ClientID, sum(T0.NumberOfRegistrations) as 'SumaIlościZarejestrowanychDniOrazWarsztatów'
from
(
	select  c.ClientID, count(rd.RegisteredDayID) as 'NumberOfRegistrations'
	from Client as c inner join participant as p 
	on C.ClientID = p.ClientID
	inner join RegisteredDay as rd 
	on Rd.ParticipantID = p.ParticipantID
	group by c.ClientID
	UNION
	select  c.ClientID, count(rw.RegisteredWorkshopID) as 'NumberOfRegistrations'
	from Client as c inner join participant as p 
	on C.ClientID = p.ClientID
	inner join RegisteredDay as rd 
	on Rd.ParticipantID = p.ParticipantID
	inner join RegisteredWorkshop as rw 
	on rw.RegisteredDayID=rd.RegisteredDayID
	group by c.ClientID
) T0 
group by T0.ClientID
order by sum(T0.NumberOfRegistrations) desc



create view view_ConferenceDayWorkshop
as 
select c.ConferenceID, cd.ConferenceDayID, w.WorkshopId
from
Conference as c inner join ConferenceDay as cd
on c.ConferenceID = cd.ConferenceID
inner join Workshop as w
on w.ConfernceDayID = cd.ConferenceDayID


