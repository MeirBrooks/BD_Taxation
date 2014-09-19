
clear

pause off
set more off
include "${ROOT}/Code/master"

local pay_date "20140203"
local reg_date "20131111"

global series_var num_payments_pos


use "`REGDATA'/all_registrations_`reg_date'.dta", clear
keep if current == 1 
// save for old and new bins
foreach type in old new {
	preserve
		keep if `type'bin != .
		keep id `type'bin
		sort id `type'bin
		rename `type'bin bin
		rename id id_`type'
		sort bin
		tempfile `type'match
		save ``type'match'
	restore
}

// merge bins into payment data
use "`PAYDATA'\all_payments_pre_bin_collapse.dta", replace 
drop id 

sort bin
merge bin using `oldmatch', _merge(mergeold)
drop if mergeold == 2

sort bin
merge bin using `newmatch', _merge(mergenew)
drop if mergenew == 2

assert id_new == "" | id_old == ""
g id = id_new
replace id = id_old if id_old != ""

sort id 
tempfile payments
save `payments'

use "`CCT'\CleanCensus_and_Spatial.dta", clear
sort id 

merge 1:m id using `payments', force
drop _merge


merge m:1 id using "`CCT'\CleanClusters.dta"
drop _merge

merge m:1 clusid using "`CCT'\TreatmentAssignment.dta"
drop _merge

tempfile pay_merged
save `pay_merged' 

use "`CCT'\reconciled_delivery_data.dta", clear

keep id letter_delivered reason_no_delivery delivery_date

tempfile letter
save `letter'

use `pay_merged', clear

merge m:1 id using `letter'

drop if missing(id) | instudy==0

*save "C:\Users\Evan\Dropbox\BD Taxation\Code\analysis\Code\es_explore\payments_with_id.dta", replace 
save "X:\BD Taxation\Code\analysis\Code\es_explore\payments_with_id.dta", replace
save "`PAYDATA'\payments_pre_bin_collapse_with_id.dta", replace 

*use "C:\Users\Evan\Dropbox\BD Taxation\Code\analysis\Code\es_explore\payments_with_id.dta", clear
use "X:\BD Taxation\Code\analysis\Code\es_explore\payments_with_id.dta", clear

split delivery_date, p("/")
destring delivery_date*, replace

gen treat_baseinfo = treat == 2 | treat == 4 | treat == 6 | treat == 8
gen treat_peers = treat == 3 | treat == 4 | treat == 7 | treat == 8 
gen treat_grouprec = treat == 5 | treat == 6 | treat == 7 | treat == 8
gen treat_nsXgrouprec = treat_peers*treat_grouprec



keep if yychal_p==2013 & (mmchal==6 | mmchal ==7) & !missing(yychal_p)

collapse (first) delivery_date* letter_delivered, by(id yychal_p mmchal daychal treat_peers) 
keep if letter_delivered

gen delivered_before = delivery_date1 < mmchal | (delivery_date1==mmchal & delivery_date2 < daychal) 
