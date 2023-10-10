.read data.sql


select * from results limit 10;


select * from results
         where competitionId = 'BayAreaSpeedcubin412023' limit 10;

select * from results
         where competitionId = 'BayAreaSpeedcubin412023'
           and eventId = '333oh'
         order by pos limit 10;

select * from roundtypes;

select * from results
         where competitionId = 'BayAreaSpeedcubin412023'
           and eventId = '333oh'
           and roundTypeId='f'
         order by pos limit 10;

select * from results where personId='2017TUNG13' order by pos;

select * from results where personId='2017TUNG13' and pos <= 5 order by pos;

# joining

select * from Competitions where id='BayAreaSpeedcubin412023';

select competitionId, name, cityName from Results, Competitions
                                     where id = competitionId
                                       and competitionId = 'BayAreaSpeedcubin412023'
                                     limit 1;


select * from championships;
select * from competitions;
select Competitions.id, competition_id from competitions, championships limit 10;
select * from competitions, championships where competitions.id = competition_id limit 10;

# ambiguous names

select id from championships, competitions;
select id from championships;
select id from competitions;

select championships.id, competitions.id from championships, competitions;

# joining a table with itself

select * from results;

select * from results, results;

select * from results as a, results as b;


select * from results as a, results as b where a.personid='2017TUNG13' and b.personid='2015LEAN01';

select * from results as a, results as b
         where a.personid='2017TUNG13'
           and b.personid='2015LEAN01'
           and a.competitionId = b.competitionId;

select * from results as a, results as b
         where a.personid='2017TUNG13'
           and b.personid='2015LEAN01'
           and a.competitionId = b.competitionId
           and a.eventId = b.eventId
           and a.roundTypeId = b.roundTypeId;

select a.competitionId, a.eventId, a.personName, a.average, a.pos, b.personName, b.average, b.pos from results as a, results as b
         where a.personid='2017TUNG13'
           and b.personid='2015LEAN01'
           and a.competitionId = b.competitionId
           and a.eventId = b.eventId
           and a.roundTypeId = b.roundTypeId;

select a.competitionId, a.eventId, a.personName, a.average, a.pos, b.personName, b.average, b.pos from results as a, results as b
         where a.personid='2017TUNG13'
           and b.personid='2015LEAN01'
           and a.competitionId = b.competitionId
           and a.eventId = b.eventId
           and a.roundTypeId = b.roundTypeId
           and a.average > 0
           and b.average > 0;

select a.competitionId, a.eventId, a.personName, a.average, a.pos, b.personName, b.average, b.pos from results as a, results as b
         where a.personid='2017TUNG13'
           and b.personid='2015LEAN01'
           and a.competitionId = b.competitionId
           and a.eventId = b.eventId
           and a.roundTypeId = b.roundTypeId
           and a.average > 0 and b.average > 0
           and b.average < a.average order by b.average;

# other queries

select a.competitionId, a.eventId, a.personName, a.average, a.pos, b.personName, b.average, b.pos from results as a, results as b
         where a.personid='2017TUNG13'
           and b.personid='2022YINB01'
           and a.competitionId = b.competitionId
           and a.eventId = b.eventId
           and a.roundTypeId = b.roundTypeId
           and a.average > 0 and b.average > 0
           and b.average < a.average order by b.average;


