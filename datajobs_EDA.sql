-- Import csv file to table
copy jobs_in_data
from 'C:\Users\aphan\OneDrive\Desktop\Anh Phan\jobs_in_data\jobs_in_data.csv'
delimiter ','
csv header;

-- Count different countries' different size companies
select 
	"companyLocation",
	count(case when "companySize" = 'S' then "companySize" else null end) S_count,
	count(case when "companySize" = 'M' then "companySize" else null end) M_count,
	count(case when "companySize" = 'L' then "companySize" else null end) L_count
from jobs_in_data
group by 1
order by 1 asc; -- With the most data in the dataset, 92% of the US's companies are mid-sized.

-- 1. Proportions of each countries' jobs in dataset
select  jobs_in_data."companyLocation" as Country,
		(count(*)/sum(count(*)) over())*100 as percentage
from jobs_in_data
group by Country
order by Country asc; -- Majority of data comes from the US: 87% of the dataset

-- 2. Count jobs and average salary of each job category
select
	jobs_in_data."jobCategory" as Category,
	count(jobs_in_data."jobTitle") as number_of_jobs,
	round(avg(jobs_in_data."salaryInUSD"),2) as average_salary_USD
from jobs_in_data
group by 1
order by 3 desc; -- the result is in descending ordered by average salary, which Machine Learning
				 -- and AI jobs make the highest salary. In 4 years, Data Science and Research has
				 -- the most number of jobs out of all locations in the dataset.

-- 3. Proportions of each years' jobs in dataset
select  jobs_in_data."workYear" as "Year",
		(count(*)/sum(count(*)) over())*100 as percentage
from jobs_in_data
group by "Year"
order by "Year" asc; -- Majority of data comes from 2023: 79.6% of the dataset

-- 4. Jobs posting over the years
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM crosstab(
   'SELECT "jobCategory", "workYear", COUNT(*) 
    FROM jobs_in_data 
    GROUP BY 1, 2 
    ORDER BY 1, 2',
   'SELECT DISTINCT "workYear" FROM jobs_in_data ORDER BY 1'
) AS pivot_table("jobCategory" TEXT, "2020" INT, "2021" INT, "2022" INT, "2023" INT)
order by "2023" DESC; -- Data jobs tend to grow with more opportunities over years, especially roles:
					  -- Data Engineer, Data Scientist, Data Analyst, and Machine Learning and AI.

-- 5. Top 5 most available jobs each year
select year, title, numberOfJobs, rank
from
(select  jobs_in_data."workYear" as "year",
		jobs_in_data."jobTitle" as title,
		count(*) as numberOfJobs,
		dense_rank() over(partition by jobs_in_data."workYear" order by count(*) desc) as "rank"
from jobs_in_data
group by "year", title
order by "year" asc, "rank" asc)
where "rank" <= 5
order by "year" asc, "rank" asc -- Data Scientist, Engineer, Analyst, and ML Engineer has most job hirings throughout the years.

-- 6. Avg salary of different experience level for each job category
SELECT * FROM crosstab(
  'SELECT "jobCategory", "experienceLevel", ROUND(AVG("salaryInUSD"),2) AS average_salary_USD
   FROM jobs_in_data
   GROUP BY 1,2
   ORDER BY 1,2',   

   $$VALUES ('Entry-level'::text), ('Mid-level'::text), ('Senior'::text), ('Executive'::text)$$
) AS pivot_data("jobCategory" text, "Entry-level" numeric, "Mid-level" numeric, "Senior" numeric, "Executive" numeric);
-- Entry-level positions for jobs in Data Science and Research make the highest salary on average,
-- Mid-level to Executive, jobs in Machine Learning and AI have higher average salary.

-- 7. Average salary of job categories over the year
select * from
crosstab
('select "jobCategory", "workYear", round(avg("salaryInUSD"),2)
from jobs_in_data
group by 1,2
order by 1,2',
 
'select distinct "workYear"
from jobs_in_data
order by 1'
)
as pivot_table
("jobCategory" TEXT, "2020" numeric, "2021" numeric, "2022" numeric, "2023" numeric)
order by "2023" desc; -- ML and AI jobs average salary make big jumps over the past years, indicating
					  -- the strong growth of opportunities and needs in ML and AI. While most job
					  -- categories avg salary increase overtime, some also decrease.

-- 8. How is company size affects jobs' salary
select
		"companySize",
		round(coalesce(avg(case when "experienceLevel" = 'Entry-level' then "salaryInUSD" end), 0),2) as "Entry-level",
		round(coalesce(avg(case when "experienceLevel" = 'Mid-level' then "salaryInUSD" end), 0),2) as "Mid-level",
		round(coalesce(avg(case when "experienceLevel" = 'Senior' then "salaryInUSD" end), 0),2) as "Senior",
		round(coalesce(avg(case when "experienceLevel" = 'Executive' then "salaryInUSD" end), 0),2) as "Executive"
from jobs_in_data
group by 1; -- On average, medium sized companies are willing to pay more for entry-level
			-- and mid-level roles. Large sized companies pay more for senior and executive roles.

-- 9. How is work settings affect jobs' salary
select
		"workSetting",
		round(coalesce(avg(case when "experienceLevel" = 'Entry-level' then "salaryInUSD" end), 0),2) as "Entry-level",
		round(coalesce(avg(case when "experienceLevel" = 'Mid-level' then "salaryInUSD" end), 0),2) as "Mid-level",
		round(coalesce(avg(case when "experienceLevel" = 'Senior' then "salaryInUSD" end), 0),2) as "Senior",
		round(coalesce(avg(case when "experienceLevel" = 'Executive' then "salaryInUSD" end), 0),2) as "Executive"
from jobs_in_data
group by 1; -- With the first 3 experience level, employees who work in-person
			-- get paid higher on average compared to those who work remote or hybrid.
			-- At the executive level, those who work remote get paid higher on average.