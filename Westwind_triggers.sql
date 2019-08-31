use Westwind
use Westwind

alter trigger tr_limitOfDay on ReservedDay
for update,insert
as
begin
	declare @errors int
	set @errors=(select count(*) from
				(
					select rd.ConferenceDayID, count(rd.ReservedDayID) as 'AlreadyUsed'
					from ReservedDay as rd
					where rd.State='A' or rd.State='R'
					group by rd.ConferenceDayID
				)T0 
				inner join ConferenceDay  as cd
				on cd.ConferenceDayID = T0.ConferenceDayID
				where T0.AlreadyUsed-cd.LimitOfParticipants >0
				)
	if(@errors <>0)
	begin
	RAISERROR('All places for the day you selected are gone...',16,-1)
	end
end



alter trigger tr_limitOfWorkshop on ReservedWorkshop
for update,insert
as
begin
	declare @errors int
	set @errors=(select count(*) from
				(
					select rw.WorkshopID, count(rw.ReservedWorkshopID) as 'AlreadyUsed'
					from ReservedWorkshop as rw
					where rw.State='A' or rw.State='R'
					group by rw.WorkshopID
				)T0 
				inner join Workshop  as w
				on w.WorkshopID = T0.WorkshopID and w.LimitOfParticipants - T0.AlreadyUsed <0
				
				)
	print @errors.
	if(@errors <>0)
	begin
	RAISERROR('All places for the day you selected are gone...',16,-1)
	end
end



