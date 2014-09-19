do "S:\bd-tax"

local createdata = 0 

**CREATE LOOP FOR EACH TYPE OF DATE**
foreach DATETYPE in CHALLAN ATTEST ENTRY{

if "`DATETYPE'"=="CHALLAN"{
	local P1 		period
	local P2 		yychal_p
}

if "`DATETYPE'"=="ATTEST"{
	local P1 		period_attest 
	local P2 		attestyear1_p
}
if "`DATETYPE'"=="`ENTRY'"{
	local P1 		period_entry 
	local P2 		year_entry_p
}
if `createdata' == 1{
include "Y:\BD_Taxation\code\generate_payment_by_bin" // uses `P1' and `P2'
do "Y:\BD_Taxation\code\generate_registration_file"
do "Y:\BD_Taxation\code\merge_id_to_uncollapsed_payments"
include "Y:\BD_Taxation\code\merge_pay_reg_census"
} //end createdata



**CREATE FILE TO RECEIVE MERGES*
if "`DATETYPE'"=="CHALLAN"{
	use "X:\BD Taxation Core Data\Merged Data\CleanMerged_`DATETYPE'_20140319.dta", clear
	keep if instudy==1
	keep id clusid treat circle letter_delivered reason_no_delivery delivery_date reg*
	tempfile MERGE
	save `MERGE'
}

**PROCESS TO FINAL DATA**
use "X:\BD Taxation Core Data\Merged Data\CleanMerged_`DATETYPE'_20140319.dta", clear
keep if instudy==1 
keep id pVATContribution* num_payments_* 
local PREAMBLE = substr("`DATETYPE'",1,1)
rename pVATContribution* `PREAMBLE'_pVATContribution*
rename num_payments* `PREAMBLE'_num_payments*
tempfile `DATETYPE'
save ``DATETYPE''
}

**CREATE FILE TO MERGE PAYMENT VARIABLES TO**
use `MERGE', clear
foreach DATETYPE in CHALLAN ATTEST ENTRY{
merge 1:1 id using ``DATETYPE'', nogen
}
		
save "X:\BD Taxation Core Data\Merged Data\for_analysis_v4.dta", replace



