CREATE TABLE ipl_matches (
id int,
city varchar,
date date,
player_of_match varchar,
venue varchar,
neutral_venue int,
team1 varchar,
team2 varchar,
toss_winner varchar,
toss_decision varchar,
winner varchar,
result varchar,
result_margin varchar,
eliminator varchar,
method varchar,
umpire1 varchar,
umpire2 varchar);

COPY ipl_matches FROM 'F:\DS\SQL\Final Project\IPL Dataset\IPL Dataset\IPL_matches.csv' CSV HEADER;

SELECT * FROM ipl_matches;

CREATE TABLE ipl_ball ( 
match_id int,  
inning int,  
over int,  
ball int,  
batsman varchar,  
non_striker varchar,  
bowler varchar,  
batsman_runs int, 
extra_runs int,  
total_runs int, 
wicket_ball int, 
dismissal_kind varchar, 
player_dismissed varchar, 
fielder varchar, 
extras_type varchar, 
batting_team varchar,  
bowling_team varchar 
); 

COPY ipl_ball FROM 'F:\DS\SQL\Final Project\IPL Dataset\IPL Dataset\IPL_Ball.csv' CSV HEADER;

SELECT * FROM ipl_ball;

/* Question 1  Aggressive Batsmans */ 

SELECT batsman,
       SUM(batsman_runs) AS total_runs,
       COUNT(ball) AS total_ball_faced,
       ROUND(CAST(SUM(batsman_runs) AS DECIMAL) / COUNT(ball) * 100, 2) AS strike_rate
FROM ipl_ball
WHERE extras_type NOT IN ('wides')
GROUP BY batsman
HAVING COUNT(ball) >= 500
ORDER BY strike_rate DESC
LIMIT 10;


/* Question 2 */ 

--Find those player who playes more than 2 ipl season
  

SELECT
    a.batsman,
    COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) AS played_season,
    SUM(a.batsman_runs) AS total_runs,
    COUNT(CASE WHEN a.wicket_ball = 1 THEN 1 ELSE NULL END) AS no_of_dismiss,
    CASE
        WHEN COUNT(CASE WHEN a.wicket_ball = 1 THEN 1 ELSE NULL END) > 0 THEN
            round(CAST(SUM(a.batsman_runs) AS DECIMAL) / COUNT(CASE WHEN a.wicket_ball = 1 THEN 1 ELSE NULL END),2)
        ELSE
            0.0  -- To handle cases where there are no dismissals (avoid division by zero)
    END AS avg
FROM
    ipl_ball AS a
JOIN
    ipl_matches AS b
ON
    a.match_id = b.id
GROUP BY
    a.batsman
HAVING
    COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) > 2  	
ORDER BY
    avg DESC
LIMIT
    10;
	
/* Hard-Hitting batters */ 




WITH batsman_stats AS (
    SELECT 
        a.batsman,
        COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) AS played_season,
        SUM(a.batsman_runs) AS total_runs,
        COUNT(CASE WHEN a.batsman_runs = 4 THEN 1 ELSE NULL END) AS number_of_fours,
        COUNT(CASE WHEN a.batsman_runs = 6 THEN 1 ELSE NULL END) AS number_of_six,
        SUM(CASE WHEN a.batsman_runs IN (4,6) THEN a.batsman_runs ELSE NULL END) AS boundaries_runs
    FROM
        ipl_ball AS a
    JOIN
        ipl_matches AS b
    ON
        a.match_id = b.id
    GROUP BY
        a.batsman
    HAVING
        COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) > 2
)
SELECT *, round((boundaries_runs * 100.0 / total_runs),2) AS percentage
FROM batsman_stats
WHERE boundaries_runs IS NOT NULL
ORDER BY percentage DESC LIMIT 10;

SELECT 
    a.batsman,
    COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) AS played_season,
    SUM(a.batsman_runs) AS total_runs,
    COUNT(CASE WHEN a.batsman_runs = 4 THEN 1 ELSE NULL END) AS number_of_fours,
    COUNT(CASE WHEN a.batsman_runs = 6 THEN 1 ELSE NULL END) AS number_of_six,
    SUM(CASE WHEN a.batsman_runs IN (4, 6) THEN a.batsman_runs ELSE 0 END) AS boundaries_runs,
    round((SUM(CASE WHEN a.batsman_runs IN (4, 6) THEN a.batsman_runs ELSE 0 END) * 100.0 / SUM(a.batsman_runs)),2) AS boundaries_percentage
FROM ipl_ball AS a
JOIN ipl_matches AS b
ON a.match_id = b.id
GROUP BY a.batsman
HAVING COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) > 2
ORDER BY boundaries_percentage DESC
LIMIT 10;

--Question 4 Blowers 

SELECT * from ipl_ball;


SELECT
    bowler,
    COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN ball ELSE NULL END) AS total_balls,
    COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN ball ELSE NULL END) / 6.0 AS total_overs,
    SUM(total_runs) AS total_runs,
    SUM(total_runs) / (COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN ball ELSE NULL END) / 6.0) AS economy
FROM
    ipl_ball
GROUP BY
    bowler
HAVING 
	COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN ball ELSE NULL END) > 500
ORDER BY 
	economy DESC
LIMIT 10 ;

SELECT 
	bowler,
	COUNT(ball) as total_balls,
	round(COUNT(over) / 6,2) as total_over,
	SUM(total_runs) as total_runs,
	round(cast(SUM(total_runs) as decimal) / (COUNT(over) / 6),2) as economy
	from ipl_ball
	group by bowler
	having COUNT(ball)>500
	ORDER BY economy asc
LIMIT 10 ;

-- Question 5 strike rate 

SELECT 
	bowler,
	count(case when ball between 1 and 6 then ball else null end) as total_balls, 
	count(case when wicket_ball = 1 then wicket_ball else null end) as total_wicket, 
	count(case when ball between 1.0 and 6.0 then ball else null end) / count(case when wicket_ball = 1.0 then wicket_ball else null end) as Strike_rate
FROM 
	ipl_ball
GROUP BY 
	bowler
HAVING 
	COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN ball ELSE NULL END) > 500
ORDER BY
	Strike_rate DESC 
LIMIT 10;

SELECT
    bowler,
    count(case when ball between 1 and 6 then ball else null end) as total_balls, 
	count(case when wicket_ball = 1 then wicket_ball else null end) as total_wicket, 
    CASE
        WHEN COUNT(CASE WHEN wicket_ball = 1  THEN 1 ELSE NULL END) > 0 THEN
            CAST(COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN 1 ELSE NULL END) AS DECIMAL(10, 2)) /
            COUNT(CASE WHEN wicket_ball = 1  THEN 1 ELSE NULL END)
        ELSE
            0.0  -- Avoid division by zero
    END AS strike_rate
FROM
    ipl_ball
GROUP BY
    bowler
HAVING
    COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN 1 ELSE NULL END) > 500
ORDER BY
    strike_rate ASC  -- Use ASC to get the top bowlers with the lowest strike rates
LIMIT
    10;
	
SELECT 
	bowler,
	count(ball) as total_balls,
	SUM(wicket_ball) as total_wicket,
	round(count(ball)*1.0/sum(wicket_ball),2) as strike_rate
FROM ipl_ball
WHERE NOT extras_type= 'wides' 
GROUP BY bowler
HAVING 	count(ball) > 500
order by strike_rate
LIMIT 10;

--Question 6 All rounder 

SELECT * from ipl_ball;

SELECT batsman AS all_rounder,
round((SUM(batsman_runs)*1.0/COUNT(ball) *100),2) AS bats_strike_rate,bowl_strike_rate
FROM ipl_ball AS a 
INNER JOIN
(SELECT bowler,COUNT(bowler) AS balls,
SUM(wicket_ball) AS total_wicket,
round(((COUNT(bowler)*1.0/SUM(wicket_ball))),2)AS bowl_strike_rate
FROM ipl_ball
GROUP BY bowler 
HAVING COUNT(bowler)>300 
ORDER BY bowl_strike_rate asc)  AS b
ON a.batsman = b.bowler
WHERE NOT extras_type= 'wides' 
GROUP BY batsman,bowl_strike_rate
HAVING COUNT(ball)>=500 
ORDER BY bats_strike_rate DESC, bowl_strike_rate ASC
LIMIT 10;

SELECT batsman AS all_rounder,
       round((SUM(batsman_runs)*1.0/COUNT(ball) *100),2) AS bats_strike_rate,
       bowl_strike_rate
FROM ipl_ball AS a 
INNER JOIN (
    SELECT bowler,
           COUNT(bowler) AS balls,
           SUM(wicket_ball) AS total_wicket,
           round(((COUNT(bowler)*1.0/SUM(wicket_ball))),2) AS bowl_strike_rate
    FROM ipl_ball
    GROUP BY bowler 
    HAVING COUNT(bowler) > 300 
    ORDER BY bowl_strike_rate ASC
) AS b
ON a.batsman = b.bowler
WHERE NOT extras_type = 'wides' 
GROUP BY batsman, bowl_strike_rate
HAVING COUNT(ball) >= 500 
ORDER BY bats_strike_rate DESC, bowl_strike_rate ASC
LIMIT 10;



SELECT batsman, bowl_strike_rate,
round((sum(batsman_runs)*1.0 / count(ball)*100), 2) as bater_strikerate 
from ipl_ball as a
inner join 
(select bowler, 
  CASE
        WHEN COUNT(CASE WHEN wicket_ball = 1  THEN 1 ELSE NULL END) > 0 THEN
            CAST(COUNT(CASE WHEN ball BETWEEN 1 AND 6 THEN 1 ELSE NULL END) AS DECIMAL(10, 2)) /
            COUNT(CASE WHEN wicket_ball = 1  THEN 1 ELSE NULL END)
        ELSE
            0.0  -- Avoid division by zero
    END AS bowl_strike_rate
from ipl_ball 
 group by bowler
 having count(case when ball between 1 and 6 then ball else null end) > 300
 order by bowl_strike_rate asc) 
 as b 
 on a.batsman = b.bowler 
 where not extras_type = 'wides'
 group by batsman, bowl_strike_rate
 having count(case when ball between 1 and 6 then ball else null end) > 500
 
 order by bater_strikerate desc,bowl_strike_rate;
 
 -- Question 7 Wicketkiper 
 
select distinct dismissal_kind from ipl_ball;

select * from ipl_matches;

SELECT
    a.batsman,
    COUNT(DISTINCT EXTRACT(YEAR FROM b.date)) AS played_season,
	round((SUM(CASE WHEN a.batsman_runs IN (4, 6) THEN a.batsman_runs ELSE 0 END) * 100.0 / SUM(a.batsman_runs)),2) AS percentage,
	COUNT(case when witcket_ball IN ('stumped', 'caught'))

--Question 8 
	
--Q1 

SELECT COUNT(DISTINCT city) as total_cities from ipl_matches;

--Q2 

CREATE TABLE deliveries_v02 AS
SELECT *, 
  CASE 
    WHEN total_runs >= 4 THEN 'boundary'
    WHEN total_runs = 0 THEN 'dot'
    ELSE 'other'
  END AS ball_result
FROM ipl_ball;

select * from deliveries_v02;

--Q3 

SELECT 
COUNT('dot') as dot_ball,
COUNT('boundary') as boundary_ball
FROM deliveries_v02;

--Q4 

SELECT batting_team, 
count('boundary') as total_boundaries 
FROM deliveries_v02 
GROUP BY batting_team
ORDER BY total_boundaries DESC;

select distinct batting_team as Team,count(ball_result) as "Boundaries"
from deliveries_v02 where ball_result = 'boundary'
group by batting_team
order by "Boundaries" desc;

WITH BoundaryCounts AS (
    SELECT batting_team, COUNT(*) AS Boundaries
    FROM deliveries_v02
    WHERE ball_result = 'boundary'
    GROUP BY batting_team
)
SELECT * FROM BoundaryCounts
ORDER BY Boundaries DESC;


--Q5 


SELECT bowling_team, 
count('dot') as total_dot_ball 
FROM deliveries_v02 
GROUP BY bowling_team
ORDER BY total_dot_ball DESC;

SELECT batting_team, 
count('dot') as total_dot_ball 
FROM deliveries_v02 
GROUP BY batting_team
ORDER BY total_dot_ball DESC;

WITH BoundaryCounts AS (
    SELECT batting_team, COUNT(*) AS Boundaries
    FROM deliveries_v02
    WHERE ball_result = 'dot'
    GROUP BY batting_team
)
SELECT * FROM BoundaryCounts
ORDER BY Boundaries DESC;

--Q6

SELECT count(case when dismissal_kind != 'NA' then dismissal_kind else NULL end) as number_of_dismissals from deliveries_v02;

--Q7 

SELECT * FROM deliveries_v02;

SELECT 
bowler,
sum(extra_runs) AS total_extras
FROM deliveries_v02
GROUP BY bowler
ORDER BY total_extras DESC 
LIMIT 5;

--Q8


CREATE TABLE deliveries_v03 as 
SELECT a.*, b.venue, b.date from 
deliveries_v02 as a inner join 
(SELECT id, venue, date from ipl_matches) as b 
on a.match_id = b.id;

SELECT * FROM deliveries_v03;

--Q9 

SELECT venue,
sum(total_runs) as venue_runs
FROM deliveries_v03
GROUP BY venue 
order by venue_runs DESC ;

--Q10 

SELECT max(venue) as venue,
EXTRACT(year from date) as match_year,
sum(total_runs) as venue_runs
FROM deliveries_v03
GROUP BY venue , EXTRACT(year from date)
HAVING max(venue) = 'Eden Gardens'
order by venue_runs DESC 



