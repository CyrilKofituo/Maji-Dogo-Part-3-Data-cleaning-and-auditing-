/* looking up the audit table*/
SELECT 
 location_id, 
true_water_source_score
FROM md_water_services.auditor_report;

/* combining the tables*/
SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    water_quality.subjective_quality_score as surveyor_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id ;
    
    /* checking if scores are the same*/
    SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
where auditor_report.true_water_source_score = water_quality.subjective_quality_score 
and visits.visit_count  = 1 ;
	
	
    /* looking at the score that are not the same or correct */
    SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1 ;

/* adding type_of_water_source column from the water_source table as (survey_source) and type_of_water_source from the auditor_report table, and call it auditor_source.*/
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    water_source.type_of_water_source as survey_source,
    auditor_report.type_of_water_source as auditor_source,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.water_source
on
	water_source.source_id =visits.source_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1 ; 


/* looking for the employees at fault*/
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1 ;

/* using the employees at fault table as CTE called (Incorrect_records).*/
with 
Incorrect_records as ( 
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1) 
SELECT * FROM Incorrect_records ;


/* CREATING THE UNIQUE TABLE OF EMPLOYEES AND THEIR NUMBER OF MISTAKES*/
with 
Incorrect_records as ( 
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1) 
SELECT 
employee_name,  
COUNT(employee_name) AS number_mistakes
FROM Incorrect_records 
group by employee_name
ORDER BY  number_mistakes DESC;



/* CREATING A VIEW OF THE EMPLOYEE AND NUMBER OF MISTAKES TABLE*/
CREATE VIEW error_count AS (
with 
Incorrect_records as ( 
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1) 
SELECT 
employee_name,  
COUNT(employee_name) AS number_mistakes
FROM Incorrect_records 
group by employee_name
ORDER BY  number_mistakes DESC);

SELECT
AVG(number_mistakes) AS avg_error_count_per_empl
FROM error_count;


/* CALCULATING EMPLOYEES WITH MISTAKES ABOVE AVERAGE or list of suspects*/
SELECT
employee_name,
number_mistakes
FROM
error_count
WHERE
number_mistakes > (SELECT
AVG(number_mistakes) 
FROM error_count);


/* CREATING A VIEW OF THE INCORRECT RECORDS or the employees at fault*/
CREATE VIEW
Incorrect_records as ( 
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    auditor_report.statements AS statement,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1);


/* creating a view of the list of suspects or employees whose mistakes are above average*/
create view
list_of_suspects as(
SELECT
employee_name,
number_mistakes
FROM
error_count
WHERE
number_mistakes > (SELECT
AVG(number_mistakes) 
FROM error_count));
select * from list_of_suspects;


/* This query filters all of the records where the "SUSPECTED" employees gathered data.*/
with 
Incorrect_records as ( 
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    auditor_report.statements,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1)
select employee_name,location_id,statements
from Incorrect_records 
where employee_name  IN (SELECT employee_name FROM list_of_suspects);


/* This query filters all of the records where the "SUSPECTED" employees gathered data and had the word cash in their statement*/
with 
Incorrect_records as ( 
 SELECT 
	auditor_report.location_id as location_id,
	auditor_report.true_water_source_score as auditor_score,
	visits.record_id,
    employee.employee_name,
    auditor_report.statements,
    water_quality.subjective_quality_score as employee_score
FROM 
	md_water_services.auditor_report
join 
	md_water_services.visits
on 
	auditor_report.location_id = visits.location_id 
join
	md_water_services.water_quality
on
	visits.record_id = water_quality.record_id 
join
	md_water_services.employee
on
employee.assigned_employee_id = visits.assigned_employee_id
where auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
and visits.visit_count = 1)
select employee_name,location_id,statements
from Incorrect_records 
where employee_name  IN (SELECT employee_name FROM list_of_suspects)
AND statements LIKE "%CASH%" ;



