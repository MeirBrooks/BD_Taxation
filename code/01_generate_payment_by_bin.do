/***************************

Title: Generate payment by bin

Purpose: This file takes in a pre-software payment by bin data set (created by prep_presoftware_payment.do) 
and the latest software PMTChallan and PMTvat19 datasets to produce the complete, latest payment by bin file. 
The only payments excluded from the output are those without a BIN which were matched directly to firm id. 

Author: Evan Storms

**************************/

clear

pause on
set more off
set varabbrev on
include "${ROOT}/Code/master"
	
local date "20140319"
local PackageAmount 9000

global lastyear_pay 2013

// Prepare software data and then append on the presoftware payment data 

// get challan info for making date
use "`PAYDATA'/Latest Software Output/`date'NewPMTChallan.dta", clear
renvars, lo
*pause
*Gen variable to record payment amount according to challan form
if `date'==20130529 | `date'==20131114{
	rename filerpaidamount challan_payment
	}
else{
	destring filerpaidamount, ignore(",""$") gen(challan_payment)
	}
rename challanbin binchallan
destring binchallan, replace

replace returnkey=id if missing(returnkey) & !missing(id) 

g order = 1 if pmttype == 1 & (withheldfiling == . | withheldfiling == 1) // prioritize dates from VAT payments, and payments that are not on behalf of another firm.
keep returnkey computerno daychal mmchal yychal binsupplied markedfordelete pmttype fiscalyear binstart challan_payment order paytype nameonbehalf binchallan entry*

rename paytype paytype_chal

rename returnkey id
drop if id == . 
gsort computerno id order -yychal -mmchal -daychal
duplicates drop computerno id,force
drop order
sort computerno id 
tempfile challan
save `challan'

// take in new info on VAT 19 forms
use "`PAYDATA'/Latest Software Output/`date'NewPMTvat19.dta", clear

cap gen MarkedForDelete=0
drop if MarkedForDelete==1
drop MarkedForDelete
else if `date'==20131114{
	drop _merge 
	}

// put variables into lowercase
renvars, lo


destring bin19 binstart binstart2, replace
tostring attestname1 attestdesignation1 attestcircle1 ///
		 attestname2 attestdesignation2 attestcircle2 ///
		 deonotes depositformfrom depositformto bindelete formselect test ///
		 , force replace

rename paytype source
label var source sourceLabel
replace source = 2 if source == 3

// merge in challan info
sort computerno id
merge computerno id using `challan', update
keep if _merge!=2 | pmttype==2 | missing(pmttype)

//make bin number
set type double

gen bin=bin19
replace bin=binstart if missing(bin) & binstart!=.
replace bin=binstart2 if missing(bin) & binstart2!=.
replace bin=binchallan if missing(bin) & binchallan!=. 


if `date'==20140115 | `date'==20140127 | `date'==20140203 | `date' ==20140319 {
	rename mm mmx
	gen mm=. 

	rename mmchal mmchalx 
	gen mmchal = .

	local months Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec 
	local month_counter=1

	foreach month in `months'{
		replace mm=`month_counter' if mmx=="`month'"
		replace mmchal = `month_counter' if mmchalx=="`month'"
		local month_counter = `month_counter' + 1
		}

	drop mmx mmchalx 
}
		
if `date'==20131111{
	gen mmchalx = ceil(date(mmchal, "M")/30)
	replace mmchalx =1 if mmchalx==0
	drop mmchal
	rename mmchalx mmchal
		}
	
	


*Fixes for 20131114 file 
if `date'==20131114 | `date'==20131111 | `date'==20140115 | `date'==20140127 | `date'==20140127 | `date'==20140203 | `date'==20140319 {
	foreach var of varlist q* mm*{
		destring `var', ignore("$", ",") replace force
	}
}

// make periods
replace mm = monthstart if mm==.
replace yy = yearstart	if yy==.
replace yy = 2012 if computerno == 3 & id == 3708 & bin19 == 9121051263
replace yy = 2012 if yy == 2021 | yy == 20132
replace yy = 2011 if yy == 20111
replace yy = 2010 if yy == 201

replace yychal = 2012 if yychal == 12 | yychal == 20 | yychal == 1012 | yychal == 212 | yychal == 201 | yychal == 202 | yychal == 21012 | yychal == 21022 | yychal == 2021 | yychal == 2102
replace yychal = 2011 if yychal == 20111
replace yychal = 2013 if yychal == 2018 | yychal==2013 | yychal==13 | yychal==203 |  yychal==213 | yychal == 2031 | yychal == 22013 | yychal==2023
replace yychal = 2010 if yychal == 2710

drop if yychal > 2014

assert yychal == 2008 | yychal == 2009 | yychal == 2010 | yychal == 2011 | yychal == 2012 | yychal == 2013 | yychal == 2014 |yychal == . 

replace yychal = yy if yychal == .

//Note: if missing month of payment, use "for month" plus 1; assumption: payment was made one month after the month being paid for
replace mmchal = mm + 1 if mmchal == . & mm != 12
replace yychal = yychal + 1 if mmchal == . & mm == 12
replace mmchal = 1 if mmchal == . & mm == 12
replace daychal = 27 if daychal == .

// for periods where the date is later than the current date, reduce time by one year
replace yychal = yychal - 1 if yychal == real(substr("`UpdateDate'",1,4)) & mmchal > real(substr("`UpdateDate'",5,2))

// Make sure to remove this 
*replace mmchal = mm if !missing(mm) 

//makeQuarter2 mmchal daychal, output(quarter) yearin(yychal)

//CHALLAN DATE
tempvar TEMP
gen `TEMP' = string(daychal)+"/"+string(mmchal)+"/"+string(yychal)
gen challandate2 = date(`TEMP', "DMY",2014)
format challandate2 %td

makePeriod mmchal daychal, output(period) yearin(yychal) // DCW: FROM ES USES CHALLAN DATE (WHAT IS USED FOR ANALYSIS AS OF 9/15/2014


//DO THIS BY DATA ENTRY DATE (DCW)
gen entrydate2 = date(entrydate,"DMY",2014) // generate date variable from string
format entrydate2 %td

gen day_entry  = day(entrydate2)
gen mnth_entry = month(entrydate2)
gen year_entry = year(entrydate2)
makePeriod mnth_entry day_entry, output(period_entry) yearin(year_entry) // DCW: USES ENTRY DATE AS PERIOD (USES YYCHAL AS YEAR FOR NOW TO KEEP OTHER CODE FROM BRAEKING)

//ALSO DO THIS BY ATTEST DATE (DCW)
tempvar TEMP
gen `TEMP' = string(attestday1)+"/"+string(attestmonth1)+"/"+string(attestyear1)
gen attestday3 = date(`TEMP', "DMY",2014)
format attestday3 %td

makePeriod attestmonth1 attestday1, output(period_attest) yearin(attestyear1)

//ALSO DO BY ORDER DATE 
gen orderdate2 = date(orderdate,"DMY",2014) // generate date variable from string
format orderdate2 %td

gen day_order  = day(orderdate2)
gen mnth_order = month(orderdate2)
gen year_order = year(orderdate2)
makePeriod mnth_entry day_entry, output(period_order) yearin(year_order) // DCW: USES ENTRY DATE AS PERIOD (USES YYCHAL AS YEAR FOR NOW TO KEEP OTHER CODE FROM BRAEKING)

//If you want to do this by day
makeDay mmchal daychal, output(day_period) yearin(yychal) 

//If you want to use the "for payment" comment this out and comment the previous line
*gen dd =1
*makePeriod mm dd, output(period) yearin(yy)


//This is just to check the dates 
*save "`PAYDATA'/Latest Software Output/`date'check.dta", replace 


// create vat contribution variable
gen VATContribution = q1_3 if abs(q4-q1_3)/q1_3<=.01
replace VATContribution = q1_3 + q2_3 if (q1_3 + q2_3 - q4)/q4 < .01 & VATContribution == .									// Sometimes people just list revenue and VAT owed on items with special tax rates (tooth paste) 
replace VATContribution = q4 if q1_3==. & q2_3==. & q3_3 ==. & q4!=. & q1_1!=. & q4/q1_1 <.16 & VATContribution == .			// Yes, VAT shouldn't really be more than 15% of revenue, but we have to give people some room for error and whatever else
replace VATContribution = q1_3 if (q1_2 + q1_3 - q4)/q4 < .01 & VATContribution ==.

replace VATContribution = q1_3 if q4==. & q5==. & q6==q1_3 & VATContribution ==.
replace VATContribution = q1_3 if q4==. & q6-q5 == q1_3 & VATContribution==.
replace VATContribution = q1_3 if q4==. & q6==. & q16==q1_3 & VATContribution ==.
replace VATContribution = q2_3 if q2_3==q4 & q1_3==. & VATContribution ==.
replace VATContribution = q1_3 if q4==. & q1_3==q6 & q1_3==q16 & VATContribution ==.
replace VATContribution = q2_3 if q2_3 == q3_3 & q2_3 == q16 & VATContribution ==.

replace VATContribution = q2_3+q3_3 if q2_3 + q3_3 == q4 & q2_3!=. & q3_3!=. & q4!=. & VATContribution ==.
replace VATContribution = q1_3 if abs(q1_3-q6)/q1_3<.01 & q4==. & q5==. & VATContribution ==.

replace VATContribution = q1_3 if q2_3==q1_3 & q15==q1_3 & q16==q1_3 & VATContribution ==.						// This represents at least one case where they put their taxable sales in q4 and q6
replace VATContribution = q1_3 if q1_3/q1_1<.15 & q4==. & q5==. & q6==. & q15==. & q16==. & VATContribution ==.
replace VATContribution = q1_3 if q15==q16 & q1_3+q5==q15 & VATContribution ==.												// one guy just didn't add up VAT to q5 in q6

replace VATContribution = q1_3 + q3_3 if q1_3+q3_3==q4 & VATContribution ==.

replace VATContribution = q1_3 if q1_3==q15 & q2_3==. & q1_3==q16 & VATContribution ==.							// slightly different from above, only nothing entered in q2_3
replace VATContribution = q1_3 if (q1_3/q1_1)<0.16 & q1_1 == q4 & (q1_3==q15 | q1_3==q16) & VATContribution ==.			// Again reporting sales price in q4 and q6

replace VATContribution = q4 if q1_3 + q2_3 != q4 & q1_1!=. & q2_1!=. & q1_3!=. & q2_3!=. & VATContribution ==.
replace VATContribution = q1_3 if (q1_3 == q16 | q1_3==q15) & q4==. & q6==. & VATContribution ==.
replace VATContribution = q1_3 if abs(((q1_3 + q5)-q6)/q6)<.01 & VATContribution ==.
replace VATContribution = q1_3 if abs(((q1_3 + q5)-q4)/q4)<.01 & VATContribution ==.
replace VATContribution = q1_3 if abs(((q4 + q5)-q1_3)/q1_3)<.01 & VATContribution ==.
replace VATContribution = q4 if q2_1==. & q3_1==. & q4==.15*q1_1 & VATContribution ==.

replace VATContribution = q4 if q1_1==. & q2_1==. & q4==q3_1 & q4!=. & VATContribution==.			// probably an old version of the VAT-19

replace VATContribution = q6 if q6/q1_1==.15 & q1_3==. & q2_1==. & q3_1==. & q4==. & q5==. & q6!=. & VATContribution ==.

replace VATContribution = q1_3 if q1_3/q1_1==.15 & q2_1==. & q3_1==. & q5==. & q16==q1_3 & VATContribution ==.  

replace VATContribution = q1_3 if abs(((q1_3 + q1_2)-q4))/q4<.01 & VATContribution ==.
replace VATContribution = q4 if abs((q2_3-q4)/q4)<.01 & q1_3==. & q3_3==. & VATContribution ==.

// if q4 ==  q1_1 + q1_2 + q1_3 , set vat contribution of q1_3 
g sumjunk = 0
forv j = 1(1)3 {
	replace sumjunk = sumjunk + q1_`j' if q1_`j' != .
}
replace VATContribution = q4 if (sumjunk - q4)/q4 & VATContribution == .
drop sumjunk

*If payment has challan but no v19, make VATContribution amount payed on challan form
replace VATContribution=challan_payment if _merge==2
replace source=2 if _merge==2
gen just_challan=0
replace just_challan=1 if _merge==2

drop _merge

// update zeroreturn variable
replace zeroreturn = "Yes" if q1_1==. & q1_3==. & q2_1==. & q2_3==. & q3_1==. & q3_3==. & q4==. & VATContribution ==.
replace zeroreturn = "Yes" if q1_3==. & q2_3==. & q4 ==. & q6==. & q15==. & q16==. & VATContribution ==.

gen sauce=4
gen day=daychal 

//outsheet file for no bin matches
preserve
keep if missing(bin) | bin<0
//save "`PAYDATA'\No BIN\latest_missing_bin.dta", replace
restore
********************************************************


di "`PAYDATA'"
// add on presoftware data 
append using "`PAYDATA'/Pre Software Data/presoftware_to_merge.dta", gen(pre_software)

duplicates drop bin yychal_p period day VATContribution, force

// get rid of returns with no bin
drop if bin == . | bin<0

//Create Date Variable for Entry for presoftware data (Can definitely clean this up with some Stata date work)
gen entry=entrydate
replace entry=entrydatechal if missing(entry)
replace entry = substr(entry,1,9)

split entry, p("-" "/")
gen temp_entry = entry1 
replace entry1=entry2 if regexm(entry,"/")
replace entry2 = temp_entry if regexm(entry,"/") 

local months Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec 
local month_counter=1
gen entry_month=0

foreach month in `months'{
	replace entry_month=`month_counter' if entry2=="`month'"
	local month_counter = `month_counter' + 1
	}
gen month_replace = entry2 if regexm(entry,"/")
destring month_replace, replace
replace entry_month = month_replace if regexm(entry,"/")

*keep if entry3=="13" & entry_month>5
 
//This is where we collapse by bin period 

//saveold "`PAYDATA'\all_payments_pre_bin_collapse.dta", replace 
*********************************************************************************
replace VATContribution=0 if missing(VATContribution)

// turn everything into periods/quarters
by bin `P1' `P2', sort : egen pVATContribution = sum(VATContribution) // analysis by payment date

//save "`PAYDATA'/bin_date_set.dta", replace 

//get number of payments (including 0 payments) and number of payments>0
by bin `P1' `P2', sort : gen num_payments_all=_N
by bin `P1' `P2', sort : egen num_payments_pos = sum(VATContribution>0) 

// generate quarterly zero returns
replace zeroreturn = "1" if zeroreturn == "Yes" | zeroreturn == "yes"
replace zeroreturn = "0" if zeroreturn == "No"  | zeroreturn == "no"
replace zeroreturn = "0" if zeroreturn != "1"
destring zeroreturn,replace
bys bin `P1' `P2' : egen pzeroreturn = min(zeroreturn)

drop if missing(`P1') | missing(`P2')

// generate string to reshape and reshape
g year_period = string(`P2') + "_" + string(`P1')

// drop obs too far in the past
drop if (`P2' < $firstyear_pay) | (`P2' == $firstyear_pay &  `P1' < $firstperiod_pay)
drop if (`P2' > $lastyear_pay) 

replace nam=name_pay if missing(nam) & !missing(name_pay)
drop name_pay
rename nam name_pay
bys bin: replace name_pay = name_pay[_n-1] if bin == bin[_n-1]

// assume regular payer if ever reg payer
bys bin: egen sourcejunk = min(source)
replace source = sourcejunk


keep pVATContribution pzeroreturn bin year_period name_pay source num_payments_all num_payments_pos 
duplicates drop bin year_period,force


reshape wide pVATContribution pzeroreturn num_payments_all num_payments_pos,i(bin) j(year_period) string

// update for missing payments (note that the zero for qVAT means no payment, the 0 for qzero means that there was no return and no payment
foreach var of varlist pVATContribution* pzeroreturn* num_payments* {
	replace `var' = 0 if `var' == . 
}
// update source if missing
g missingsource = source ==.
replace source = 2 if source == .
foreach var of varlist pVATContribution* {
	replace source = 1 if missingsource == 1 & `var' > `PackageAmount'
}
drop missingsource

// get dummy for what kind of bin this is under
format bin %15.0g
g usingnewbin = substr(string(bin),1,1) == "1"
g usingoldbin = substr(string(bin),1,1) == "5" |  substr(string(bin),1,1) == "9"
g invalidbin = usingnewbin == 0 & usingoldbin == 0 

saveold "`PAYDATA'/all_payments_by_bin_`date'.dta", replace
