-- LEVEL 1

-- Question 1: Number of users with sessions

select count(user_id) as users_with_sessions
from
(select user_id, count(id) as n_sessions
from sessions
group by user_id) temp
where n_sessions > 0;

-- Question 2: Number of chargers used by user with id 1
select count(charger_id) as chargers_used
from sessions
where user_id = 1


-- LEVEL 2

-- Question 3: Number of sessions per charger type (AC/DC):
select count(a.id) as n_sessions, b.type
from sessions a
inner join chargers b
on a.charger_id = b.id 
group by b.type

-- Question 4: Chargers being used by more than one user

select count(distinct(user_id)) as different_users, charger_id
from sessions
group by charger_id
having count(distinct(user_id)) > 1

-- Question 5: Average session time per charger
with temp as (select timestampdiff(second, start_time, end_time)/3600 as hours_used, charger_id
from sessions)

select avg(hours_used), charger_id
from temp
group by charger_id



-- LEVEL 3

-- Question 6: Full username of users that have used more than one charger in one day (NOTE: for date only consider start_time)
select distinct id, name, surname
from users a
inner join
(select user_id, date(start_time), count(charger_id) chargers_used
from sessions
group by user_id, date(start_time)
having chargers_used > 1) b
on a.id = b.user_id;

-- Question 7: Top 3 chargers with longer sessions
select sum(timestampdiff(second, start_time, end_time)/3600) as totaltime_sessions, charger_id, label
from sessions a
inner join chargers b
on a.charger_id = b.id
group by charger_id
order by totaltime_sessions DESC
limit 3

-- Question 8: Average number of users per charger (per charger in general, not per charger_id specifically)

select avg(n_users)
from
(select count(distinct(user_id)) as n_users, charger_id
from sessions
group by charger_id) temp

-- Question 9: Top 3 users with more chargers being used
select user_id, count(charger_id) as chargers_used
from sessions
group by user_id
order by count(charger_id) desc
limit 3


 
-- LEVEL 4

-- Question 10: Number of users that have used only AC chargers, DC chargers or both
with temp2 as
    (SELECT user_id, 
           MAX(Used_AC) AS used_AC, 
           MAX(Used_DC) AS used_DC, 
           MAX(Used_AC) + MAX(Used_DC) AS used_Both
    FROM (
        SELECT user_id, 
               type, 
               CASE WHEN type = 'AC' THEN 1 ELSE 0 END AS Used_AC,
               CASE WHEN type = 'DC' THEN 1 ELSE 0 END AS Used_DC
        FROM sessions a
        INNER JOIN chargers b ON a.charger_id = b.id
    ) temp
    GROUP BY user_Id)
    
    select distinct (select count(distinct(user_id)) from temp2 where used_AC = 1 ) as used_ac, 
    (select count(distinct(user_id)) from temp2 where used_DC = 1 ) as used_dc,
    (select count(distinct(user_id)) from temp2 where used_both = 2 ) as used_both
    from temp2

-- Question 11: Monthly average number of users per charger

select avg(n_users), month_
from
(select count(distinct(user_id)) as n_users, charger_id, month(start_time) as month_
from sessions
group by charger_id, month(start_time)) temp
group by month_;

-- Question 12: Top 3 users per charger (for each charger, number of sessions)

select charger_id, user_id
from
(select charger_id, user_id, count(id), rank() over(partition by charger_id order by count(id) desc) rn
from sessions
group by charger_id, user_id
order by charger_id) temp
where rn <=3 ;


-- LEVEL 5

-- Question 13: Top 3 users with longest sessions per month (consider the month of start_time)
    select month_, user_id, session_hours
    from
    (select sum(timestampdiff(second, start_time, end_time)/3600) as session_hours, 
    user_id, 
    month(start_time) as month_, 
    rank() over (partition by month(start_time) order by sum(timestampdiff(second, start_time, end_time)/3600) desc) as rnk
    from sessions
    group by user_id, month(start_time)) temp
    where rnk <= 3

    
-- Question 14. Average time between sessions for each charger for each month (consider the month of start_time)

with temp as (select timestampdiff(second, start_time, end_time)/3600 as hours_used, charger_id, month(start_time) as month_
from sessions)

select avg(hours_used), charger_id, month_
from temp
group by charger_id, month_
