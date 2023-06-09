global path "C:\Users\savas\Documents\Ashoka\Economics\IGIDR\National Medical Registry"

cd "$path\UpdatedDataFiles"

import delimited "NMC_PG_Specialization_data.csv", clear
*it seems that we cannot generate dummies using tab, gen in this dataset. We need multiple conditions for dummy creation. 

*degree dummies
gen mbbs = 0
replace mbbs = 1 if ug_degree == "MBBS" 

*All "" pg degrees are supposed to be none. 
replace pg_degree_1 = "None" if pg_degree_1 == ""
replace pg_degree_2 = "None" if pg_degree_2 == ""
replace pg_degree_3 = "None" if pg_degree_3 == ""

*remove all observations where a student has no degree at all. 
count if ug_degree == "None" & pg_degree_1 == "None" & pg_degree_2 == "None" & pg_degree_2 == "None"
gen no_degree = 0 
replace no_degree = 1 if ug_degree == "None" & pg_degree_1 == "None" & pg_degree_2 == "None" & pg_degree_2 == "None"
keep if no_degree != 1

*check if any pg degre accidently has MBBS in it. This could be becasue the data was wrongly cleaned. 
count if pg_degree_1 == "MBBS"
count if pg_degree_2 == "MBBS"
count if pg_degree_3 == "MBBS"

*Did the doctor undertake a PG degree? 1 if addn qual 1 2 or 3 are not None and qualmain_main is neither MBBS nor None. 
gen pg_yes = 0
replace pg_yes = 1 if pg_degree_1 != "None" | pg_degree_2 != "None" | pg_degree_3 != "None"

*create dummies for each PG degree
local deg_generate_list MD MS DNB Diploma DM Fellow MCPS
foreach degree of local deg_generate_list {
	gen pg_`degree' = 0
	replace pg_`degree' = 1 if pg_degree_1 == "`degree'" | pg_degree_2 == "`degree'" | pg_degree_3 == "`degree'" 	
	replace pg_`degree' = . if mbbs == 0
}

*predicted female from website. 
gen pred_fem = 0
replace pred_fem = 1 if predicted_gender == "female"
replace pred_fem = . if predicted_gender == ""

gen pred_male = 1 - pred_fem 

*number of degrees
gen num_pg_degrees = 0
replace num_pg_degrees = 1 if pg_degree_1 != "None" & pg_degree_2 == "None" & pg_degree_3 == "None"
replace num_pg_degrees = 2 if pg_degree_1 != "None" & pg_degree_2 != "None" & pg_degree_3 == "None"
replace num_pg_degrees = 2 if pg_degree_1 != "None" & pg_degree_2 == "None" & pg_degree_3 != "None"
replace num_pg_degrees = 3 if pg_degree_1 != "None" & pg_degree_2 != "None" & pg_degree_3 != "None"

*sex ratio
gen sex_ratio = female / male

*rename census state column
rename v85 census_state

*literacy percent in general
gen literacy_percent = literate / population

*female literacy percent. 
gen fem_lit_percent = female_literate/ female

//rural households
gen rural_hh_percent = rural_households/ households

*female labor force participation
gen fem_lpf = female_workers/workers

**purchasing power parity
gen mean_ppp = (45000)/2 * power_parity_less_than_rs_45000/total_power_parity + (90000 + 45000)/2 * power_parity_rs_45000_90000/total_power_parity + (150000+90000)/2*power_parity_rs_90000_150000/total_power_parity + (240000+150000)/2*power_parity_rs_150000_240000/total_power_parity + (330000+240000)/2 * power_parity_rs_240000_330000/total_power_parity + (425000+330000)/2*power_parity_rs_330000_425000/total_power_parity + (540000+425000)/2 * power_parity_rs_425000_545000/total_power_parity + (545000)/2*power_parity_above_rs_545000/total_power_parity 
gen ln_mean_ppp = log(mean_ppp)

*quartile generation: 
local variablenames literacy_percent fem_lit_percent rural_hh_percent fem_lpf ln_mean_ppp sex_ratio
foreach variable_i of local variablenames {
	pctile `variable_i'_quartile_gen = `variable_i', nq(4)
	
	gen `variable_i'_q1_cutoff = `variable_i'_quartile_gen[1]
	gen `variable_i'_q2_cutoff = `variable_i'_quartile_gen[2]
	gen `variable_i'_q3_cutoff = `variable_i'_quartile_gen[3]
	
	gen `variable_i'_q1 = 0
	gen `variable_i'_q2 = 0
	gen `variable_i'_q3 = 0
	gen `variable_i'_q4 = 0

	replace `variable_i'_q1 = 1 if `variable_i' < `variable_i'_q1_cutoff
	replace `variable_i'_q2 = 1 if `variable_i' > `variable_i'_q1_cutoff & `variable_i' <= `variable_i'_q2_cutoff
	replace `variable_i'_q3 = 1 if `variable_i' > `variable_i'_q2_cutoff & `variable_i' <= `variable_i'_q3_cutoff
	replace `variable_i'_q4 = 1 if `variable_i' > `variable_i'_q3_cutoff
	
	replace `variable_i'_q1 = . if `variable_i' == .
	replace `variable_i'_q2 = . if `variable_i' == .
	replace `variable_i'_q3 = . if `variable_i' == .
	replace `variable_i'_q4 = . if `variable_i' == .

}
 
*globals
global prob_gender_cond probabilty_gender > 0.8 & probabilty_gender != .
global pg_prob_cond pg_yes == 1 & probabilty_gender > 0.8 & probabilty_gender != .

*Summary tables
*age of qualification from degree:
cd "C:\Users\savas\Documents\Ashoka\Courses\Health Economics\Health Econ_Presentation_Research Progresss\Tables"

*estpost tabstat age_qualification_main if qualmain_main == "MBBS", by(census_state ) stat(mean count sd min max)
*esttab, cells("mean count sd min max") noobs, using "mbbs_age_qual_sumstats.csv" 

*estpost tabstat age_qualification_addtional_1 if addnqual1_main == "MD", by(census_state ) stat(mean count sd min max)
*esttab, cells("mean count sd min max") noobs, using "md_age_qual_sumstats.csv" 

*estpost tabstat age_qualification_addtional_1 if addnqual1_main == "MS", by(census_state ) stat(mean count sd min max)
*esttab, cells("mean count sd min max") noobs, using "ms_age_qual_sumstats.csv" 

*estpost tabstat sex_ratio, by(census_state)
*esttab, cells("mean") noobs, using "sex_ratio_compare.csv"

*================================================================================================================

*Regressions: 
*MBBS degrees
prtest pred_fem = 0.5 if $prob_gender_cond

*Proportion of females in MBBS over time. 
local year_list 1900 1910 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010
foreach year of local year_list{
	local upper_bound = `year' + 10
	di `year' "-" `upper_bound'
	prtest pred_fem = 0.5 if mbbs == 1 & ug_degree_year >= `year' & ug_degree_year <= `upper_bound' & probabilty_gender > 0.8
	*estadd scalar prop1_`year' = r(P)
}

*Proportion of females in MBBS over time: but with t-tests. 
*local year_list 1900 1910 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010
*foreach year of local year_list{
*	local upper_bound = `year' + 10
*	di `year' "-" `upper_bound'
*	asdoc ttest pred_fem == pred_male if mbbs == 1 & ug_degree_year >= `year' & ug_degree_year <= `upper_bound' & probabilty_gender > 0.8, rowappend
*}

*MBBS females are likely to come from districts with higher literacy. 
ttest fem_lit_percent if probabilty_gender > 0.8, by(pred_fem)

*MBBS students come come from more urban households. 
bysort census_state: sum rural_hh_percent

*================================================================================================================
*Num of PG degrees on female
reg num_pg_degrees pred_fem if $prob_gender_cond

*================================================================================================================

*Undertakig PG on female: 
reg pg_yes pred_fem if $prob_gender_cond

*both analysis by state of origin
*bysort census_state: reg pg_yes pred_fem if $prob_gender_cond
*bysort census_state: reg pg_yes pred_fem##(fem_lit_percent_q1 fem_lit_percent_q2 fem_lit_percent_q3) if $prob_gender_cond
*bysort census_state: reg pg_yes pred_fem##(ln_mean_ppp_q1 ln_mean_ppp_q2 ln_mean_ppp_q3) if $prob_gender_cond

*Undertake PG degree female, by year of birth / graduation from program. 
local year_list 1900 1920 1940 1960 1980 2000
foreach year of local year_list{
	local upper_bound = `year' + 20 
	di `year' "-" `upper_bound'
	quietly reg pg_yes pred_fem if $prob_gender_cond & ug_degree_year >= `year' & ug_degree_year <= `upper_bound'
	matrix list e(b)
	di (e(b)[1,2] + e(b)[1,1]) / e(b)[1,2]
}

local year_list 1900 1910 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010
foreach year of local year_list{
	local upper_bound = `year' + 10
	di `year' "-" `upper_bound'
	prtest pred_fem = 0.5 if pg_yes == 1 & ug_degree_year >= `year' & ug_degree_year <= `upper_bound' & probabilty_gender > 0.7
}

*================================================================================================================

*MD: 
*MD on female, intensive margin
reg pg_MD pred_fem if $pg_prob_cond		

*how many men did a PG? 
count if pg_yes == 1 & pred_fem == 0 & probabilty_gender > 0.8
*How many men did an MD? 
count if pg_MD == 1 & pred_fem == 0 & probabilty_gender > 0.8
*then divide the two coeff above. This should be the same as the constant term in our regression. 
*interpretation: out of all men who did a PG, 65% of them did an MD. 
*same interpretation for females: out of all women who did a PG, 60% of them did an MD. 

*Statewise MD on female interacted with female literacy
*bysort census_state: reg pg_MD pred_fem##(fem_lit_q_1 fem_lit_q_2 fem_lit_q_3) if $pg_prob_cond

*================================================================================================================

*MS:
reg pg_MS pred_fem if pg_yes == 1 & $prob_gender_cond

*MS on female interacted with population literacy
*bysort census_state: reg pg_MS pred_fem##(fem_lit_q_1 fem_lit_q_2 fem_lit_q_3) if $pg_prob_cond

*================================================================================================================

*Diploma
*Diploma:
reg pg_Diploma pred_fem if pg_yes == 1 & $pg_prob_cond

*Diploma on female interacted with population literacy
*bysort census_state: reg pg_MS pred_fem##(fem_lit_q_1 fem_lit_q_2 fem_lit_q_3) if $pg_prob_cond

local variablelist pg_yes num_pg_degrees MD MS Diploma
foreach variable_i of local variablelist{
	di "`variable_i'"
	if "`variable_i'" == "pg_yes" {
		quietly reg `variable_i' pred_fem if $prob_gender_cond
		eststo `variable_i'_pred_fem
	}
	else if  "`variable_i'" == "num_pg_degrees" {
		quietly reg `variable_i' pred_fem if $pg_prob_cond
		eststo `variable_i'_pred_fem
	}
	
	else {
		quietly reg pg_`variable_i' pred_fem if $pg_prob_cond
		eststo `variable_i'_pred_fem
	}
		
	local regressand_list literacy_percent fem_lit_percent ln_mean_ppp rural_hh_percent fem_lpf
	foreach regressand of local regressand_list{
		di "`regressand'"
		if "`variable_i'" != "num_pg_degrees" & "`variable_i'" != "pg_yes"{
			quietly reg pg_`variable_i' pred_fem##(`regressand'_q1 `regressand'_q2 `regressand'_q3) if $pg_prob_cond
			eststo `variable_i'_`regressand'
		}
		else if "`variable_i'" == "num_pg_degrees"{
			quietly reg `variable_i' pred_fem##(`regressand'_q1 `regressand'_q2 `regressand'_q3) if $pg_prob_cond
			eststo num_pgdeg_`regressand'
		}
		else {
			quietly reg `variable_i' pred_fem##(`regressand'_q1 `regressand'_q2 `regressand'_q3) if $prob_gender_cond
			eststo pg_yes_`regressand'
		}
	}
}

local regressand_list literacy_percent fem_lit_percent ln_mean_ppp rural_hh_percent fem_lpf 
foreach regressand of local regressand_list{
	
	if "`regressand'" == "literacy_percent" {
		local title "Heterogeneity in Outcomes by District Population Literacy"
	}
	
	else if "`regressand'" == "fem_lit_percent"{
		local title "Heterogeneity in Outcomes by District Female Literacy"
	}
	
	else if "`regressand'" == "ln_mean_ppp"{
		local title "Heterogeneity in Outcomes by District Income"
	}
	
	else if "`regressand'" == "rural_hh_percent"{
		local title "Heterogeneity in Outcomes by Percentage of Rural HH in District"
	}
	
	else if "`regressand'" == "fem_lpf"{
		local title "Heterogeneity in Outcomes by Female Labour Force Participation"
	}
	
	local filetype_local tex rtf
	foreach filetype of local filetype_local {
		if "`filetype '" == "tex" {
			cd "C:\Users\savas\Documents\Ashoka\Courses\Health Economics\Health Econ_Course Research\Medical Education in India\Medical Education - Tables Repo\Tex Tables"
		}
		else {
			cd "C:\Users\savas\Documents\Ashoka\Courses\Health Economics\Health Econ_Course Research\Medical Education in India\Medical Education - Tables Repo\RTF Tables"

		}
		esttab pg_yes_`regressand' num_pgdeg_`regressand' MD_`regressand' MS_`regressand' Diploma_`regressand' using "`regressand'_quartile_reg.`filetype'", keep (1.pred_fem 1.`regressand'_q1 1.`regressand'_q2 1.`regressand'_q3 1.pred_fem#1.`regressand'_q1 1.pred_fem#1.`regressand'_q2 1.pred_fem#1.`regressand'_q3 _cons) p(3) varlabel (1.pred_fem "female" 1.`regressand'_q1  		"`regressand' q1" 1.`regressand'_q2 "`regressand' q2" 1.`regressand'_q3 "`regressand' q3" 1.pred_fem#1.`regressand'_q1 "female*`regressand' q1" 1.pred_fem#1.`regressand'_q2 				"female*`regressand' q2" 1.pred_fem#1.`regressand'_q3 "female*`regressand' q3") refcat(1.`regressand'_q1 "[1em]\textbf{Quartiles}" 1.pred_fem#1.`regressand'_q1 				 	"[1em]\textbf{Gender interactions}", nolabel) title (`title') star(* 0.1 ** 0.05 *** 0.01) replace 
	}
}

cd "C:\Users\savas\Documents\Ashoka\Courses\Health Economics\Health Econ_Course Research\Medical Education in India\Medical Education - Tables Repo\Tex Tables"
esttab pg_yes_pred_fem num_pg_degrees_pred_fem MD_pred_fem MS_pred_fem Diploma_pred_fem using "pg_yes.tex", p(3) varlabel (pred_fem "female") title("Likelihoods of Outcomes by Gender") star(* 0.1 ** 0.05 *** 0.01) replace

