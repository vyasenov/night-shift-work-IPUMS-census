clear all
cd "~/Desktop/nighttime work"

* LOAD DATA

use usa_00147.dta

**********
**********
**********

* SELECT SAMPLE

drop if incwage == 0
drop if departs == 0
drop if uhrs < 20

**********
**********

* CREATE YEARLY, WEEKLY, HOURLY WAGE MEASURES

tab wksw, m	
recode wksw (1 = 8) (2 = 20.8) (3 = 33.1) (4 = 42.4) (5 = 48.3) (6 = 51.9)
tab wksw, m

gen wage_w = incwage / wksw
gen wage_h = incwage / (wksw * uhrs)
rename incwage wage_y 
corr wage*

**********
**********

* CREATE WAGE BINS FOR EACH YEAR

local years 1990 2000 2010 2018
foreach i of local years {

	xtile bin_w_`i' if wage_y > 0 & year == `i' = wage_w, n(20)
	*xtile bin_y if wage_y > 0 = wage_y, n(50)
	*xtile bin_h if wage_y > 0 = wage_h, n(50)
	*xtile bin_inc = inctot, n(50)

	replace bin_w_`i' = bin_w_`i' * 5 - 1
	*replace bin_y = bin_y * 2 - 1
	*replace bin_h = bin_h * 2 - 1
	*replace bin_inc = bin_inc * 2 - 1
}	

sum bin*

gen bin_w = .
replace bin_w = bin_w_1990 if year == 1990
replace bin_w = bin_w_2000 if year == 2000
replace bin_w = bin_w_2010 if year == 2010
replace bin_w = bin_w_2018 if year == 2018
sum bin_w

drop bin_w_*
drop if bin_w == .

* DEFINITE NIGHT WORK
gen night = departs >= 1800
sum depart if night == 1
tab night

/* ALTERNATIVE DEFINITION OF NIGHT WORK
gen night2 = night
replace night2 = 1 if depart <= 600
tab night*, m
*/

**************
**************

* AGGREGATE 

preserve
collapse night* [pw=perwt], by(bin_w year)
sum

reshape wide night*, i(bin) j(year)
sum

* PLOT: PROBABILITY OF WORKING NIGHT SHIFTS BY WAGE PERCENTILE BINS 

twoway (line night1990 bin) ///
	(line night2000 bin) ///
	(line night2010 bin) ///
	(line night2018 bin), ///
	legend(ring(0) pos(2)) ///
	name(g1, replace) ///
	xtitle("Percentile") ///
	ytitle("Share Working Night Shifts") ///
	subtitle("Night Time Work Across the Wage Distribution")
graph export night.png, replace
restore
	
/*
twoway (line night21990 bin) ///
	(line night22000 bin) ///
	(line night22010 bin) ///
	(line night22018 bin), ///
	legend(ring(0) pos(2)) ///
	name(g2, replace)	
*/

**************
**************

* ALTERNATIVE PLOT: WHERE IN THE WAGE DISTRIBUTION ARE NIGHT SHIFT WORKERS

keep if night == 1

preserve
collapse (sum) perwt, by(bin_w year)

sum

reshape wide perwt, i(bin) j(year)
sum

local years 1990 2000 2010 2018
foreach i of local years {
	sum perwt`i'
	replace perwt`i' = perwt`i' / r(sum)
}

twoway (line perwt1990 bin) ///
	(line perwt2000 bin) ///
	(line perwt2010 bin) ///
	(line perwt2018 bin), ///
	legend(ring(0) pos(2)) ///
	name(g1, replace) ///
	xtitle("Percentile") ///
	ytitle("Share of Night Shift Workers") ///
	subtitle("Location of Night Shift Workers in the Wage Distribution")
graph export night2.png, replace

restore
