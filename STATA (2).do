clear all

****************************************** QUESTION 1 ****************************************** 
** Question 1.a)
** Please, kindly import the "ratings.csv" file
**import delimited "/Users/giacomoricciardi/Desktop/Research/UCLA/Data Task/SWB_Data_task/ratings.csv"


** Question 1.b) visualizing the number of unique for aspects and workers, i.e. 17 and 1,056 respectively

codebook aspect, compact
codebook worker, compact

** Alternatively, this short code below actually generates 2 variables (nworkers, naspects) containing the
** number of unique values for respondents and aspects. Codebook only displays the number, without saving it.

preserve
sort worker
by worker, sort: gen nworkers = _n == 1
replace nworkers = sum(nworkers)
replace nworkers = nworkers[_N]

sort aspect
by aspect, sort: gen naspects = _n == 1
replace naspects = sum(naspects)
replace naspects = naspects[_N]
restore


** Question 1.c) First we sort by worker, aspect and time. Then we create a variable (duplicate)
** indicating whether it is a duplicate value of the same answered aspect. By dropping only values = 1,
** we make sure the recent observations are kept.

sort worker aspect time
quietly by worker aspect: gen duplicate = cond(_N == 1, 0, _n)

** Check if respondent answered to aspect questions more than twice. Not the case: max(duplicate)=2.
summarize duplicate  

** Dropping the least recent observations. 237 obs deleted (then get rid of the duplicate variable)
drop if duplicate == 1
drop duplicate


** Question 1.d) Generating the average rating per respondent and visualizing detailed summary
** (i.e. 25th, 50th, 75th, etc.). Display visualizes only the requested values. The .dta file was then saved

egen subjective_ratings = mean(rating), by(worker)
summarize subjective_ratings, detail
display "Min=" r(min), "25th=" r(p25), "50th=" r(p50), "75th=" r(p75), "Max=" r(max)

save ratings.dta, replace


****************************************** QUESTION 2 ****************************************** 
clear all
** Question 2.a)
** Please, kindly import the "demographics.csv" file
** import delimited "/Users/giacomoricciardi/Desktop/Research/UCLA/Data Task/SWB_Data_task/demographics.csv"


** Question 2.b) The number of obs. appears when importing, and count gives us the same result
count


** Question 2.c) Merged the two datasets (1 to many, keeping subjective_ratings only).
merge 1:m worker using ratings.dta, keepusing(subjective_ratings)
sort worker
by worker: keep if _n == 1


** Question 2.d) First OLS regression (robust option could be added) + saved results in Excel.
regress subjective_ratings income
outreg2 using regression_results, replace excel dec(3)


** Question 2.e) First age squared variable was created, in addition to education_level and race_type 
** which represent the numerical encoded variables for education and level (otherwise regressions does
** cannot work with strings). Then the multivariate regression was run  + saved results in Excel.

gen age2 = age * age
encode education, generate(education_level)
encode race, generate(race_type)

** The code below is just if order different from alphabetical is needed (more logical).
** In any case, regressions results are the same (tested and verified on Stata).
** foreach var of varlist education {
** replace `var'="1" if `var'="Less than high school"
** replace `var'="2" if `var'="High school"
** replace `var'="3" if `var'="Some college"
** replace `var'="4" if `var'="Bachelor's degree"
** replace `var'="5" if `var'="Graduate degree"
** replace `var'="6" if `var'="Master's degree"
** replace `var'="7" if `var'="Doctoral degree"
** }
** encode education, generate(education_level_int)

regress subjective_ratings income age age2 male education_level race_type
outreg2 using regression2_results, replace excel dec(3)

save demographics.dta, replace



****************************************** QUESTION 3 ****************************************** 
clear all
** Question 3.a) First we generate the "health-only" subjective_ratings as described in the pdf.

use ratings.dta

egen h_subjective_ratings = mean(rating) if aspect == "the quality of your sleep" | aspect == "you not feeling anxious" | aspect == "your emotional stability" | aspect == "your health" | aspect == "your mental health" | aspect == "your physical fitness" | aspect == "your physical safety and security", by(worker)
egen health_subjective_ratings = mean(h_subjective_ratings), by(worker)
drop h_subjective_ratings

save ratings.dta, replace

use demographics.dta

** Then we re-merge with the demographics dataset. 
merge 1:m worker using ratings.dta, keepusing(health_subjective_ratings) generate(merge2)
sort worker
by worker: keep if _n == 1

egen rating_per_income = mean(health_subjective_ratings), by(income)
egen age_per_income = mean(age), by(income)

** Question 3.b)

twoway scatter rating_per_income income, yaxis(1) || scatter age_per_income income, yaxis(2) ytitle("Rating", axis(1)) ytitle("Age", axis(2)) xtitle("Total household income") legend( label (1 "Average health-related subjective rating") label (2 "Respondent's average age")) saving(scatterplot, replace)

save demographics.dta, replace
