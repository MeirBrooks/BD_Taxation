pause on 

**ORDER/LABEL**
order id clusid circle treat delivery_date letter_delivered reason_no_delivery
la var id "Firm ID"
la var clusid "Cluster ID"
la var circle "Circle Name"
la var treat "Treatment Assignment"
la var delivery_date "Delivery Date"
la var letter_delivered "0/1 Letter Delivered"
la var reason_no_delivery "No Letter Delivery"

**GENERATE TREATMENT VARIABLES*
gen treat_baseinfo = treat == 2 | treat == 4 | treat == 6 | treat == 8
gen treat_peer = treat == 3 | treat == 4 | treat == 7 | treat == 8 
gen treat_grouprec = treat == 5 | treat == 6 | treat == 7 | treat == 8
gen treat_peerXgrouprec = treat_peer*treat_grouprec

**GENERATE LETTER DELIVERY PERIOD**
gen LD_DATE = date(delivery_date, "MDY", 2013)
format LD_DATE %td
replace LD_DATE = date("06/26/2013","MDY") if LD_DATE == date("06/26/2016","MDY")
replace LD_DATE = date("07/05/2013","MDY") if LD_DATE == date("07/05/2103","MDY")
replace LD_DATE = date("07/06/2013","MDY") if LD_DATE == date("07/06/2103","MDY")

gen LD_PERIOD = . 
la var LD_PERIOD "Letter Delivery Period" 
replace LD_PERIOD = 11 if LD_DATE>=date("06/01/2013","MDY") & LD_DATE<=date("06/15/2013","MDY")
replace LD_PERIOD = 12 if LD_DATE>=date("06/16/2013","MDY") & LD_DATE<=date("06/30/2013","MDY")
replace LD_PERIOD = 13 if LD_DATE>=date("07/01/2013","MDY") & LD_DATE<=date("07/15/2013","MDY")
*NOTE: THERE ARE A FEW OTHERS WITH LETTER DELIVERY DATES OF APRIL AND MAY (NOT SURE WHY)


// generate total tax payments variable 
foreach PT in C A E{
	foreach year in 2012 2013{
		egen `PT'_VAT_`year'=rowtotal(`PT'_pVATContribution`year'*)
		gen `PT'_paid_`year' = `PT'_VAT_`year'>0
		la var `PT'_VAT_`year'  "Amount Paid in `year'"
		la var `PT'_paid_`year'  "0/1 Paid in `year'"
	} //end year

**POST/PRE TREATMENT PAYMENTS/INDICATORS BY LETTER PERIOD**
*p1*
egen `PT'_VAT_post1 = rowtotal(`PT'_pVATContribution2013_11-`PT'_pVATContribution2013_20)
gen `PT'_paid_post1 = `PT'_VAT_post1>0
la var `PT'_VAT_post1 "June-Oct" 
la var `PT'_paid_post1 "Paid June-Oct (0/1)" 

egen `PT'_VAT_prior1 = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_10)
replace `PT'_VAT_prior1 = `PT'_VAT_2012+`PT'_VAT_prior1
la var  `PT'_VAT_prior1  "Paid Jan12-Jun13"

*p2*
egen `PT'_VAT_post2 = rowtotal(`PT'_pVATContribution2013_13-`PT'_pVATContribution2013_20)
gen `PT'_paid_post2 = `PT'_VAT_post2>0
la var `PT'_VAT_post2 "July-Oct" 
la var `PT'_paid_post2 "Paid July-Oct (0/1)"

egen `PT'_VAT_prior2 = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_12)
replace `PT'_VAT_prior2 = `PT'_VAT_2012+`PT'_VAT_prior2
la var  `PT'_VAT_prior2  "Paid Jan12-July13"

*p3*
egen `PT'_VAT_post3 = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_20)
gen `PT'_paid_post3 = `PT'_VAT_post3>0
la var `PT'_VAT_post3 "Jan-Oct" 	
la var `PT'_paid_post3 "Paid Jan-Oct (0/1)"

gen `PT'_VAT_prior3 = `PT'_VAT_2012
la var  `PT'_VAT_prior3  "Paid Jan12-Dec12"

**POST TREATMENT PAYMENTS/INDICATORS BY LETTER DELIVERY
tempvar T1 T2 T3 T4 T5 T6 //could loop this but doing this for speed now
egen `T1' = rowtotal(`PT'_pVATContribution2013_11-`PT'_pVATContribution2013_20) if LD_PERIOD==11
egen `T2' = rowtotal(`PT'_pVATContribution2013_12-`PT'_pVATContribution2013_20) if LD_PERIOD==12
egen `T3' = rowtotal(`PT'_pVATContribution2013_13-`PT'_pVATContribution2013_20) if LD_PERIOD==13
egen `PT'_VAT_post4 = rowtotal(`T1' `T2' `T3')
gen `PT'_paid_post4 = `PT'_VAT_post4>0
la var `PT'_VAT_post4 "Paid Post Letter" 	
la var `PT'_paid_post4 "Paid Post Letter (0/1)"

egen `T4' = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_10) if LD_PERIOD==11
egen `T5' = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_11) if LD_PERIOD==12
egen `T6' = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_12) if LD_PERIOD==13
egen `PT'_VAT_prior4 = rowtotal(`T1' `T2' `T3')
replace `PT'_VAT_prior4 = `PT'_VAT_2012 + `PT'_VAT_prior4
gen `PT'_paid_prior4 = `PT'_VAT_prior4>0
la var `PT'_VAT_prior4 "Paid Pre Letter"
la var `PT'_paid_prior4 "Paid Pre Letter (0/1)"

**CREATE TRIMMED VARIABLES + QUADRATICS OF TRIMMED VARIABLES**

forv i=1/4{
if `i'==1{
	local POST 	"Jun13-Oct13"
	local PRE 	"Jan12-May13"
}
if `i'==2{
	local POST	"Jul13-Oct13"
	local PRE 	"Jan12-Jun13"
}
if `i'==3{
	local POST 	"Jan13-Oct13"
	local PRE 	"Jan12-Dec12"
}
if `i'==4{
	local POST	"After Letter"
	local PRE 	"Before Letter"
}
*P1*
gen		`PT'_VAT_post`i'_trim = 	min(`PT'_VAT_post`i', 10000)
gen		`PT'_VAT_post`i'_trim_sq = 	`PT'_VAT_post`i'_trim^2
la var 	`PT'_VAT_post`i'_trim 		"`POST' (Trimmed)"
la var 	`PT'_VAT_post`i'_trim_sq 	"`POST' Sq (Trimmed)"

gen 	`PT'_VAT_prior`i'_trim = 	min(`PT'_VAT_prior1,10000)
gen 	`PT'_VAT_prior`i'_trim_sq = `PT'_VAT_prior`i'_trim^2
la var 	`PT'_VAT_prior`i'_trim 		"`PRE' (Trimmed)"
la var 	`PT'_VAT_prior`i'_trim_sq 	"`PRE' Sq (Trimmed)"

} //end 


} //end PT


**GENERATE CLUSTER COMPLIANCE
bys clusid: egen mean_paid_2012 = mean(C_paid_2012)
	la var mean_paid_2012 "Cluster Compliance I"
gen HICOMP =  mean_paid_2012>.15
	la var HICOMP "High Compliance 0/1 (Based on Challan)"
	
**RANDOM LABELING
la var treat_peer "Peer Info"

save "X:\BD Taxation Core Data\Merged Data\for_analysis_v4.dta", replace



