/*
PROJECT: BD-TAXATION
ANALYSIS BY ENTRY DATE
*/

pause off

**FIRST LOAD ANALYSIS_V3 TO GRAB COMPLIANCE INDICATORS USED IN THE PREVOIUS CHALLAN DATE BASED ANALYSIS
use "X:\BD Taxation Core Data\Merged Data\for_analysis_v3.dta", clear

replace letter_delivered = 0 if mi(letter_delivered) // code from ES and RC -- not sure why we are doig this

// generate total tax payments variable 
foreach year in 2011 2012 2013{
		egen VAT_`year'=rowtotal(pVATContribution`year'*)
		gen paid_`year' = VAT_`year'>0
		}

*Redefine VAT_2013 to only use data up to July 2013
drop VAT_2013
drop paid_2013
egen VAT_2013=rowtotal(pVATContribution2013_1-pVATContribution2013_13)
g paid_2013 = VAT_2013>0

egen VAT_prior_2013 = rowtotal(pVATContribution2013_1-pVATContribution2013_10)
gen VAT_prior = VAT_2012 + VAT_prior_2013 
gen paid_2013_prior = VAT_prior_2013>0
gen paid_prior = VAT_prior>0
egen VAT_total=rowtotal(VAT_2011 VAT_2012 VAT_2013)

bys clusid: egen mean_paid_2012 = mean(paid_2012)
bys clusid: egen mean_paid_2013_prior = mean(paid_2013_prior)
bys clusid: egen mean_paid_prior = mean(paid_prior) 

**RAJ DEFINED AS .20 -- JUST USE THIS TO COMPARE FOR NOW**
gen HIGHCOMPLIANCE = mean_paid_2012>.2

keep id mean_paid* HIGHCOMPLIANCE pVATContribution2012* pVATContribution2013* num_payments_*2012* num_payments_*2013* paid_2012

tempfile COMPLIANCERATES 
save `COMPLIANCERATES'

**NOW LOAD NEW DATA FOR PAYMENTS BY ENTRY DATE AND THEN MERGE IN THE COMPLIANCE RATES*
use "X:\BD Taxation Core Data\Merged Data\CleanMerged20140319.dta", clear
drop if instudy==0 // drop firms not in the study
keep id clusid treat circle letter_delivered reason_no_delivery pVATContribution* num_payments* // payment and no. payments
rename pVAT* ePVAT*
rename num_payments* enum_payments*

merge 1:1 id using `COMPLIANCERATES', nogen
 
order id clusid treat circle letter_delivered reason_no_delivery mean_paid_2012 mean_paid_2013_prior mean_paid_prior HIGHCOMPLIANCE

**CHANGE SHAPE OF DATA TO LONG SO THAT YOU MAY GRAPH THESE THINGS**
forval i = 2012/2013{
	forval j=1/24 {
		local x = (`i'-2011)*24 + `j'
		rename pVATContribution`i'_`j'  pVATContribution`x'
		rename ePVATContribution`i'_`j'  ePVATContribution`x'
		rename num_payments_pos`i'_`j' num_payments_pos`x'
		rename enum_payments_pos`i'_`j' enum_payments_pos`x'
		}
	}
	
drop enum_payments_all* 

**RESHAPE IN PREPARTION FOR GRAPHING*
reshape long pVATContribution num_payments_pos ePVATContribution enum_payments_pos, i(id clusid treat circle letter* reason_no_delivery) j(period)
replace ePVATContribution = 0 if ePVATContribution==.

**GENERATE YEAR FROM PERIOD**
gen year = 2011 if period<25
replace year = 2012 if period>24 & period<49
replace year = 2013 if period>48

**GENERATE MONTH FROM PERIOD**
tempvar TEMP
gen `TEMP' = mod(period,24)
replace `TEMP' = 24 if `TEMP' == 0
tab `TEMP'
gen month = . 

forv n=0/11{
	local j = `n'+1
	replace month = `j' if inlist(`TEMP',1+2*`n',2*(`n'+1))
}

**GENEREATE YEAR-MONTH VARIABLE**
tempvar TEMP2
gen `TEMP2' = string(month)+"/"+string(year)
gen YEAR_MONTH = date(`TEMP2',"MY",2014)
format YEAR_MONTH %tdMon-CCYY

**COLLAPSE TO MONTHLY OBSERVATIONS**
collapse 	(mean) clusid treat circle letter_delivered reason_no_delivery mean_paid_2012 mean_paid_2013_prior mean_paid_prior paid_2012 HIGHCOMPLIANCE ///
			(sum) ePVATContribution pVATContribution, by(id YEAR_MONTH)
			
**CREATE Y/M VARIABLES*			
gen year = year(YEAR_MONTH)
gen month = month(YEAR_MONTH)

**GENERATE TREATMENT PRE/POST INDICATORS*
g treat_mth = year==2013&month==7
g post_treat = year==2013&month>=7

**GENERATE TRIMMED PAYMENT AMOUNTS @ 30,000**
rename pVATContribution vat_amt
rename ePVATContribution evat_amt
g vat_amt_trim = min(vat_amt,30000)
g paid_vat = vat_amt>0
g e_amt_trim = min(evat_amt,30000)

**GENERATE PEERS TREATMENT VARIABLE**
g treat_peers = treat==3|treat==4|treat==7|treat==8

**CREATE X-AXIS VARIABLE FOR YEARMONTH**
egen ex_per = group(year month)

local GPHEXP "X:\BD Taxation\Code\analysis\Code\dw_explore\Payments_by_dates"

**CREATE CHALLAN DATE BINSCATTER**
binscatter vat_amt_trim ex_per ///
			if letter_delivered==1&HIGHCOMPLIANCE==1, ///
			line(connect) xline(6 18) by(treat_peers) discrete absorb(circle) ylabel(0(500)2500)
			
			graph export "`GPHEXP'/Challan_Date_HICOMP.png", replace
			
binscatter vat_amt_trim ex_per ///
			if letter_delivered==1&HIGHCOMPLIANCE==1&paid_2012==0, ///
			line(connect) xline(6 18) by(treat_peers) discrete absorb(circle) ylabel(0(500)2500)
			
			graph export "`GPHEXP'/Challan_Date_HICOMP_NOPAY.png", replace
			
binscatter vat_amt_trim ex_per ///
			if letter_delivered==1&HIGHCOMPLIANCE==0, ///
			line(connect) xline(6 18) by(treat_peers) discrete absorb(circle) ylabel(0(500)2500)
			
			graph export "`GPHEXP'/Challan_Date_LOCOMP.png", replace
					
			
**CREATE ENTRY DATE BINSCATTER**
binscatter e_amt_trim ex_per ///
			if letter_delivered==1&HIGHCOMPLIANCE==1, ///
			line(connect) xline(6 18) by(treat_peers) discrete absorb(circle) ylabel(0(500)2500)
			
			graph export "`GPHEXP'/Entry_Date_HICOMP.png", replace
			
binscatter e_amt_trim ex_per ///
			if letter_delivered==1&HIGHCOMPLIANCE==1&paid_2012==0, ///
			line(connect) xline(6 18) by(treat_peers) discrete absorb(circle) ylabel(0(500)2500)
			
			graph export "`GPHEXP'/Entry_Date_HICOMP_NOPAY.png", replace			
			
binscatter e_amt_trim ex_per ///
			if letter_delivered==1&HIGHCOMPLIANCE==0, ///
			line(connect) xline(6 18) by(treat_peers) discrete absorb(circle) ylabel(0(500)2500)

			graph export "`GPHEXP'/Entry_Date_LOCOMP.png", replace
