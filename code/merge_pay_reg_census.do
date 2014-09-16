
clear

pause off
set more off
include "${ROOT}/Code/master"

local pay_date "20140319"
local reg_date "20131111"

global series_var num_payments_pos

local latest_date "20140319"
********************************************************************************
// Prepare data from payments without bins matched directly to firms so we can add to timeseries


	// start by preparing the latest data from the software
	use "`PAYDATA'\No BIN\latest_missing_bin.dta", clear
	rename id entry_id 
	keep computerno entry_id entry_id period yychal_p VATContribution
	merge entry_id computerno using "`PAYDATA'\No BIN\matches_for_pckg_wo_bin_nodupes.dta", sort
	keep if _merge !=2
	
	
	replace period= 12 if missing(period) 
	replace yychal_p= 2013 if yychal_p==2014
	drop if yychal_p < 2012 | yychal_p > 2013 | missing(yychal_p) 
	gen yearperiod = string(yychal_p) + "_" + string(period)
	gen num_payments_all = 1 
	gen num_payments_pos =0
	replace VATContribution=0 if missing(VATContribution)
	replace num_payments_pos=1 if VATContribution>0 
	gen source=2
	
	keep id computerno entry_id yearperiod VATContribution source num_payments*
	tempfile latest_nobin
	save `latest_nobin'
	
	
	
	insheet using "`PAYDATA'\No BIN\missing bin combined 2 matched checked 2.csv", delim(",") names clear
	drop _merge
	sort computerno_chal returnkey_chal 
	merge computerno_chal returnkey_chal  using "`PAYDATA'\No BIN\paymentsNOBIN.dta"
	gen year_check = yychal_p
	replace year_check = yy_p if missing(year_check)
	drop if year_check < 2012 | year_check > 2013 | missing(year_check)
	keep if _merge !=1 
	gen valid=  _merge == 3 & keep == "x" & (package == 1 | markedfordelete == .) & id != "" & VATContribution != .
				
	// make the VATContribu var, reshape and rename for the merge onto the existing data
	gen yearperiod = string(year_check) + "_" + string(period)
	gen num_payments_all = 1
	gen num_payments_pos =0
	replace VATContribution=0 if missing(VATContribution)
	replace num_payments_pos=1 if VATContribution>0
	
	rename computerno_chal computerno
	rename returnkey_chal entry_id
	
	append using `latest_nobin', gen(latest)

	duplicates drop computerno entry_id VATContribution period year_check, force 
	
	
	
	
	keep id yearperiod VATContribution num_payments*
	sort id yearperiod 
	
	*Now, format payments for merge in to final payment and reg dataset
	rename VATContribution pVATContribution
	
	save "C:\Users\Evan\Dropbox\BD Taxation Core Data\Payment and Registration\Payment\pre_collapse.dta", replace 
	
	use "C:\Users\Evan\Dropbox\BD Taxation Core Data\Payment and Registration\Payment\pre_collapse.dta", clear
	
	collapse (sum) pVATContribution num_payments_all num_payments_pos, by(id yearperiod)
	reshape wide pVATContribution num_payments_all num_payments_pos ,i(id) j(yearperiod) string

	gen no_identification = missing(id)

	sort id
	tempfile VATContributionNOBIN
	save `VATContributionNOBIN'
		
********************************************************************************
// match ids to payments 

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
use "`PAYDATA'/all_payments_by_bin_`pay_date'.dta" , clear

sort bin
merge bin using `oldmatch', _merge(mergeold)
drop if mergeold == 2

sort bin
merge bin using `newmatch', _merge(mergenew)
drop if mergenew == 2

assert id_new == "" | id_old == ""
g id = id_new
replace id = id_old if id_old != ""


///For multioutlets, divide payments across outlets 
bys bin: gen num_outlets= _N
foreach var of varlist pVAT* num_payments*{
	replace `var' = `var'/num_outlets
	}
drop num_outlets 


// Check time series of total payments and fraction payments missing id's.
append using `VATContributionNOBIN', gen(nobin)
replace no_identification =0 if nobin==0
drop if no_identification==1
drop no_identification 






gen holder=1

foreach var of varlist pVAT* num* {
	replace `var'=0 if missing(`var')
	}


save "`PAYDATA'\total_check.dta", replace 


********************************************************************************
/// Now on with the data prep. 


use "C:\Users\Evan\Dropbox\BD Taxation Core Data\Payment and Registration\Payment\total_check.dta", clear 

// combine payments and adjust zero return
foreach var of varlist pVAT* num_payments*{
	by id, sort: egen junk = total(`var')
	replace `var' = junk
	drop junk
	label var `var' "Half-month VAT payment" 
}
foreach var of varlist pzero* {
	by id, sort: egen junk = max(`var')
	replace `var' = junk
	drop junk
	label var `var' "Zero return"
}
order id pVAT* pzero*, seq

duplicates drop id,force
sort id

tempfile payments
save `payments'


// create current registration status variables from registration database
use "`REGDATA'/all_registrations_`reg_date'.dta", clear
g year = year(datsort)
g month = month(datsort)
g day = day(datsort)

makePeriod month day,output(period) yearin(year)

// make local to update registration status once merged to main dataset
local adjustlist ""
forv y = 2011(1)2013 {
	forv p = 1(1)24 {
		g beforejunk = year_p < `y' | (year_p == `y' & period <= `p') | datsort == .
		bys id: egen reg`y'_`p' = max(beforejunk)
		drop beforejunk
		label var reg`y'_`p' "Registered by the end of P`p' `y'"
		
		local adjustlist "`adjustlist' reg`y'_`p'"
	}
}

drop year year_p month period day mostrecent oldbin newbin 
duplicates drop	id,force
sort id
tempfile reg_time
save `reg_time'
********************************************************************************

use "`CCT'\CleanCensus_and_Spatial.dta", clear

merge id using `payments', sort
drop _merge

merge id using `reg_time', sort
drop _merge 

merge id using "`CCT'\CleanClusters.dta", sort
drop _merge

merge m:1 clusid using "`CCT'\TreatmentAssignment.dta"
drop _merge

saveold "`MERGEDATA'/CleanMerged`latest_date'.dta", replace

use "`CCT'\reconciled_delivery_data.dta", clear

keep id letter_delivered reason_no_delivery

tempfile letter
save `letter'

use "`MERGEDATA'/CleanMerged`latest_date'", clear

merge id using `letter', sort 

saveold "`MERGEDATA'/CleanMerged`latest_date'.dta", replace
