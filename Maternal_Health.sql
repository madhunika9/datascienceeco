select * from fetal_health_risk;
select * from hospitalization_labor;
select * from maternal_fat_assmt;
select * from maternal_labs;
select * from patient_history;
select * from pregnancy_nutrition;
select * from prior_gestational_health;
 
---Question 33 Get the number of patients who used every type of drug using the windows function.
with cte_drug as (select drugs_preference,
ROW_NUMBER() over (partition by drugs_preference) as count_patients
from fetal_health_risk)
select drugs_preference, count(count_patients) from cte_drug group by drugs_preference;

---Question 34 Write a query to get patients who satisfy these conditions: low hematrocit, low hemaglobin or 
---low fasting blood glucose in the 1st tri. Use the string agg function to show how many conditions are satisfied by each patient
with cte_agg1 as (select caseid, first_trimester_hematocrit, first_trimester_hemoglobin, first_tri_fasting_blood_glucose
				 from maternal_labs where 
				 first_trimester_hematocrit<33 ),
cte_agg2 as (select caseid, first_trimester_hematocrit, first_trimester_hemoglobin, first_tri_fasting_blood_glucose
				 from maternal_labs where 
				 first_trimester_hemoglobin <11),
cte_agg3 as (select caseid, first_trimester_hematocrit, first_trimester_hemoglobin, first_tri_fasting_blood_glucose
				 from maternal_labs where 
				 first_tri_fasting_blood_glucose <70)
select c1.caseid,string_agg(c1.caseid||' '||c1.first_trimester_hematocrit||' '||c2.first_trimester_hemoglobin||' '||c3.first_tri_fasting_blood_glucose,',') 
from cte_agg1 c1 join cte_agg2 c2 on c1.caseid=c2.caseid join cte_agg3 c3 on
c2.caseid=c3.caseid group by c1.caseid;
--- Joins should be changed



---Question 35 What % of all patients with high fasting glucose don't consume breakfast?
with cte_fastingglucose as (select m.caseid, m.third_tri_fasting_blood_glucose,p.breakfast_meal from
maternal_labs m left join pregnancy_nutrition p on m.caseid=p.caseid where m.third_tri_fasting_blood_glucose>=100 
or second_tri_fasting_blood_glucose>=100 or first_tri_fasting_blood_glucose>=100 )
SELECT breakfast_meal, COUNT(*) * 100 / (SELECT COUNT(*) FROM cte_fastingglucose) AS percentage
FROM cte_fastingglucose GROUP BY breakfast_meal having breakfast_meal=0;

---Question 37 Display the mean, standard deviation and variance of all prepregnant weight in the patient history table
select avg(prepregnant_weight), stddev_pop(prepregnant_weight), var_pop(prepregnant_weight) from patient_history;

---Question 38 Display any 10 random patients along with their age
select caseid,age_years_old from patient_history order by random() limit 10;

----Question 39 What % of all overweight patients consume cookies.
with cte_overweight as (select p.caseid , p.maternal_weight_at_inclusion,p.current_bmi, n.cookies 
from patient_history p left join pregnancy_nutrition n on 
p.caseid=n.caseid where p.current_bmi>=25.0 and p.current_bmi<=29.99)
SELECT cookies, COUNT(*) * 100 / (SELECT COUNT(*) FROM cte_overweight) AS percentage
FROM cte_overweight GROUP BY cookies having cookies=1;	

---Question 40 What was the average 1-minute APGAR score for newborns who's mothers had had at least 2 prior pregnancies vs mothers who had no prior pregnancies?
with cte_atleast2preg as (select h.caseid, h.apgar_1st_min as apgar_2preg, g.past_pregnancies_number from hospitalization_labor h left join 
prior_gestational_health g on h.caseid=g.caseid where past_pregnancies_number>=2),
cte_nopreg as (select h.caseid, h.apgar_1st_min as apgar_nopreg, g.past_pregnancies_number from hospitalization_labor h left join 
prior_gestational_health g on h.caseid=g.caseid where past_pregnancies_number is null)
select round(avg(apgar_2preg),2) as avg_apgar_2preg,round(avg(apgar_nopreg),2) as avg_apgar_nopreg from cte_atleast2preg a 
full outer join cte_nopreg b on a.caseid=b.caseid;
---Question 41 Write a query to calculate the moving average of newborn weight in kgs between every 2 pregnancies 
--for every patient using windows moving/sliding dynamic average functions.
select caseid, past_pregnancies_number,
AVG(past_newborn_1_weight) OVER (
        ORDER BY caseid
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_average_1,
AVG(past_newborn_2_weight) OVER (
        ORDER BY caseid
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_average_2,
	AVG(past_newborn_3_weight) OVER (
        ORDER BY caseid
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_average_3
from prior_gestational_health;
---Question 42 How many past pregnancies has each patient had?
select caseid, sum(past_pregnancies_number) as patients_past_pregnancies from prior_gestational_health 
group by caseid order by caseid ;
	
---Question 43 What was the average newborn weight of each patients past pregnancies combined in kgs?
with cte_newbornweight as (select caseid, avg(past_newborn_1_weight) as n1,avg(past_newborn_2_weight) as n2,
avg(past_newborn_3_weight) as n3,avg(past_newborn_4_weight) as n4
from prior_gestational_health group by caseid),
cte_weight as (select caseid, round(sum(n1+n2+n3+n4)*(0.25),2) as avg_newborn_weight from cte_newbornweight 
group by caseid )
select caseid, round((avg_newborn_weight)/1000,2) as avg_newborn_weight from cte_weight where avg_newborn_weight is not null;


--- Question 46 Group the patients into 4 categories of total Visceral fat 
--- and show the count of patients in each category that had a C-section
with cte_visceral as(
select m.caseid,m.periumbilical_visceral_fat,
case
when m.periumbilical_visceral_fat<25 then 'Healthy'
when m.periumbilical_visceral_fat<50 then 'elevated'
when m.periumbilical_visceral_fat<75 then 'excessive'
when m.periumbilical_visceral_fat>=75 then 'pathological'
else null
end as visceralfat_group,
h.cesarean_section_reason from maternal_fat_assmt m left join 
hospitalization_labor h on m.caseid=h.caseid where h.cesarean_section_reason is not null and m.periumbilical_visceral_fat is not null)
select visceralfat_group, count(visceralfat_group) from cte_visceral group by visceralfat_group ;

---Question 47 Create a function to check if a patient was born in a leap year.
CREATE OR REPLACE FUNCTION leap_year(year int)
RETURNS text AS $$
begin
    if(year%4=0)
		then return 'Leap year';
	else
		return 'Not Leap Year';
	end if;
end
$$ LANGUAGE plpgsql;
select leap_year(2024);


----------Question 48 Calculate Mean Arterial pressure for all patients.
with cte_map as (select caseid, (left_systolic_blood_pressure+right_systolic_blood_pressure)*(0.5) as systolic_blood_pressure,
(left_diastolic_blood_pressure+right_diastolic_blood_pressure)*(0.5) as diastolic_blood_pressure 
from maternal_labs)

select caseid, round((diastolic_blood_pressure) + (0.33)*(systolic_blood_pressure - diastolic_blood_pressure),2) as MAP 
from cte_map;


