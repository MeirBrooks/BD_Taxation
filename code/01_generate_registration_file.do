
pause on
set more off
set varabbrev on

local latest_date "20131111"
local prior_date  "first"

include "${ROOT}/Code/master"

****************************************************************************************************************
// First, collect a list of acceptable multioutlets from the latest version of the registration file

use "`REGDATA'/all_registrations_`prior_date'.dta", clear
foreach type in old new {
	preserve
		keep id `type'bin
		drop if `type'bin == .
		duplicates tag `type'bin, generate(dups)
		keep if dups > 0
		drop dups
		sort id `type'bin
		tempfile baseline_dups_`type'bin
		save `baseline_dups_`type'bin'
	restore
}


****************************************************************************************************
// Use NBR data set to match old bins to new bins

use "`REGDATA'\Full_NBR_Registration_Database_20131111.dta", clear 
keep bin pre_bin datreg
rename bin newbin
rename pre_bin oldbin

drop if newbin == .
rename oldbin oldbin_binlink
rename datreg datreg_binlink
sort newbin
tempfile binlink
save `binlink'


******************************************************************************
//Add on matches for new registrations without new payments 
use "`REGDATA'/Latest Software Output/registration_matches_201311.dta", clear
append using "`REGDATA'/Latest Software Output/20140330_matches.dta"
rename bin newbin 
tempfile extra
save `extra'
**********************************************************************************

// Load in latest software data
use "`REGDATA'/Latest Software Output/`latest_date'NewPMTMatches.dta", clear
append using "`REGDATA'/Latest Software Output/20140127NewPMTMatches.dta"
append using "`REGDATA'/Latest Software Output/20140201NewPMTMatches.dta"
append using "`REGDATA'/Latest Software Output/20140203NewPMTMatches.dta"
append using "`REGDATA'/Latest Software Output/20140319NewPMTMatches.dta"

duplicates drop 

rename bin newbin
rename pre_bin oldbin 
keep newbin oldbin id

destring newbin oldbin,replace
drop if newbin == .



// update oldbin and datreg
sort newbin
merge newbin using `binlink'
drop if _merge == 2
replace oldbin = oldbin_binlink if oldbin == . 
cap g datsort = .
replace datsort = date(datreg_binlink,"MDY") if datsort == .
drop _merge oldbin_binlink datreg_binlink

// generate added, removed and current variables
di "`UpdateDate'"
gen added = mdy(real(substr("`UpdateDate'",5,2)),real(substr("`UpdateDate'",7,2)),real(substr("`UpdateDate'",1,4)))
format added %d
gen removed = .
gen current = 1 


append using "`REGDATA'/presoftware_registrations.dta" , generate(old_data) 
format datsort %d

// sometimes the data that is added is already in the dataset. drop those. 
foreach type in old new {
	duplicates tag `type'bin id if `type'bin != . , gen(dup)
	drop if old_data == 1 & dup > 0 & dup < . 
	drop dup
}




// save version of data to come back to after correcting for multioutlets and conflicts
append using `extra', gen(extra)
tempfile basedata
save `basedata'

// check for multioutlets (or mismatches)
// loop through old and new variables, extract new multioutlets/conflicts. combine and export to checking file
foreach type in old new {
	preserve
		duplicates tag `type'bin , g(multi_`type')
		keep if multi_`type' > 0  & `type'bin != .
		sort id `type'bin
		
		merge id `type'bin using `baseline_dups_`type'bin'
		
		keep if _merge == 1
		keep oldbin newbin id datsort
		sort oldbin newbin id 
		tempfile problems`type'
		save `problems`type''		
	restore
}

clear
append using `problemsold' `problemsnew'
duplicates drop

// create variable for which firm-reg match to keep, and adjust for neighbors (they may both be counted)
egen binid1 = group(oldbin)
egen binid2 = group(newbin)
gen binid = binid1
su binid
replace binid = binid2 + r(max) if binid == .
sort binid id
gen neighbor = binid == binid[_n+1] & substr(id,1,3) == substr(id[_n+1],1,3) & abs( real(substr(id,5,.)) - real(substr(id[_n+1],5,.)) + 1 ) <= ${neighbordist}
replace neighbor = 1 if binid == binid[_n-1] & substr(id,1,3) == substr(id[_n-1],1,3) & abs( real(substr(id,5,.)) - real(substr(id[_n-1],5,.)) - 1 ) <= ${neighbordist}

gen keep = .
replace keep = neighbor if neighbor == 1
drop binid* neighbor

tempfile problems
save `problems'

// add on demographic info from the census and registration data to match
// first, registraiotn info
use "`REGDATA'\Full_NBR_Registration_Database_20131111.dta", clear 

drop oldbin
rename bin newbin
rename pre_bin oldbin

gen comb_address= ""
order comb_address
drop add12-add15
foreach var of varlist add* {
	replace comb_address = comb_address + " " + `var'
}
rename comb_address address

foreach var of varlist name address tel1 {
	rename `var' `var'_reg
}
keep oldbin newbin name_reg address tel1

// keep versions sortedby newbin and oldbin
preserve
	keep if newbin != .
	sort newbin
	tempfile reg_info
	save `reg_info'
restore
preserve
	keep if oldbin != .
	sort oldbin
	tempfile reg_info2
	save `reg_info2'
restore

// census info
use "`CCT'/CleanCensus_and_Spatial.dta", clear

rename p1q4 name_census
gen address_census = "shop " + string(p1q5) if p1q5 != .
replace address_census = "shop " + q9 if address_census == "" & q9 != ""

gen market_clean = p1q7
replace market_clean = q10 if market_clean == ""
gen number_clean = p1q8
replace number_clean = q11 if number_clean == ""
gen road_clean = p1q9
replace road_clean = q12 if road_clean == ""
gen area_clean = q13

gen floor_clean = p1q10_a 
replace floor_clean = string(floor_level) if floor_clean == "" 
gen block_clean = p1q11
replace block_clean = q16 if block_clean == ""
gen section_clean = p1q12
replace section_clean = q17 if section_clean == ""

replace address_census = address_census + " " + market_clean + " " + number_clean + " " + road_clean + " " + area_clean + " floor " + floor_clean + " block " + block_clean + " section " + section_clean

rename p5q12 tel_owner_census
rename p5q13 tel_firm_census
rename p5q14 tel_other_census

keep id address_census tel* name_census
//tostring tel*,replace
sort id
tempfile census_info
save `census_info'


// load multioutlet/conflict observations and add on data. outsheet and fix problems by hand
***************************************************************************************************
use `problems'
sort newbin
merge newbin using `reg_info'
drop if _merge == 2 

sort oldbin
merge oldbin using `reg_info2', update _merge(_merge2)
drop if _merge2 == 2
gen to_drop=0
replace to_drop =1 if  _merge == 1 & _merge2 == 1 // guarantee that we have data for all observations
drop _merge _merge2

sort id
merge id using `census_info'
drop if _merge == 1
drop if _merge == 2
drop _merge

compress
order oldbin newbin id keep name_reg name_census address_reg address_census tel1_reg tel_*census
sort newbin id 

format oldbin newbin %13.0g
tostring tel_*census  ,replace
//format tel1_reg tel_*census %13.0g

outsheet using "`REGDATA'\conflicts_to_resolve.csv", delim(",") replace

replace keep=2 
replace keep=0 if to_drop==1

outsheet using "`REGDATA'\conflicts_resolved.csv", delim(",") replace

use "`CCT'/CleanCensus_and_Spatial.dta", clear
keep id p5q9
sort id
tempfile firmage
save `firmage' 

/*******************************************************/
// insheet hand-done data and update to account for decisions that couldn't be made by hand (firm age rule)
insheet using "`REGDATA'\conflicts_resolved.csv", delim(",") clear
assert newbin != . // if this is not true, then will have to do seperately for newbin and oldbin

// for firms where we can't tell by hand which firm the registration is to, assume the older firm is the registered one
sort id
merge id using `firmage'
assert _merge != 1
drop if _merge == 2
drop _merge

replace p5q9 = . if p5q9 == 99 | p5q9 == 98
gsort newbin -p5q9 id
by newbin: g keep_2 = _n == 1 if keep == 2 
replace keep = keep_2 if keep_2 != .
assert keep == 0 | keep == 1 

keep newbin id keep 
sort id newbin keep
tempfile adjustments
save `adjustments'

// make dataset with all dates that the registration happened, by old and new bin to update dates in final dataset
use "`REGDATA'\Full_NBR_Registration_Database_20131111.dta", clear
append using "`REGDATA'\Latest Software Output\201403_reg_all.dta"

keep bin pre_bin datreg app_cat
rename bin newbin
rename pre_bin oldbin
g datsort = date(datreg,"MDY")

foreach type in old new {
	preserve
		keep if `type'bin != .
		keep `type'bin datreg app_cat 
		g datsort_`type' = date(datreg,"MDY") 
		sort `type'bin datsort_`type'
		by `type'bin: drop if _n > 1 // there are some duplicate oldbins, but not newbins. newbins are later matched first to the adjustment data, so we are just using the data from the oldbin where there is no newbin, and in that case there are no duplicates
		tempfile datsort_`type'
		save `datsort_`type''
	restore
}


// take the base data and adjust for conflicts, add in date registered where necessary and update most recent registration variable
use `basedata', clear

sort id newbin
merge id newbin using `adjustments'
*assert _merge != 2
drop _merge
//drop if keep == 0
replace current = 0 if keep == 0
replace removed = mdy(real(substr("`UpdateDate'",5,2)),real(substr("`UpdateDate'",7,2)),real(substr("`UpdateDate'",1,4))) if keep == 0
format removed %d
drop keep old_data




// update date of registration
foreach type in new old {
	sort `type'bin
	merge `type'bin using `datsort_`type''
	drop if _merge == 2
	drop _merge
	replace datsort = datsort_`type' if datsort == .
	drop datsort_`type'
}

// update most recent variable
drop mostrecent
gsort id current -newbin -oldbin 
by id current: g mostrecent = _n == 1 
replace mostrecent = 0 if current == 0
label var mostrecent "Most recent registration"

gsort -mostrecent 
duplicates drop id newbin oldbin, force



// save 
order id oldbin newbin datsort mostrecent
tempfile main
save `main' 

insheet using "`REGDATA'\hand_matches_1.csv", comma names clear
rename bin newbin

append using `main', gen(main) 

duplicates tag id newbin, gen(dup)
drop if dup>0 & main==0

save "`REGDATA'\all_registrations_`latest_date'.data", replace 
