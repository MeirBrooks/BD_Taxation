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

**POST TREATMENT PAYMENTS/INDICATORS BY LETTER DELIVERY**
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
egen `PT'_VAT_prior4 = rowtotal(`T4' `T5' `T6')
replace `PT'_VAT_prior4 = `PT'_VAT_2012 + `PT'_VAT_prior4
gen `PT'_paid_prior4 = `PT'_VAT_prior4>0
la var `PT'_VAT_prior4 "Paid Pre Letter"
la var `PT'_paid_prior4 "Paid Pre Letter (0/1)"


**CREATE PRE-TREATMENT PERIOD VARIABLES BY LETTER PERIOD**
**FOR LETTER DELIVERY IN PERIOD 11: 
egen `PT'_VAT_pre1A = rowtotal(`PT'_pVATContribution2013_7-`PT'_pVATContribution2013_10) // 2013(7)-2013(10)
gen `PT'_paid_pre1A = `PT'_VAT_pre1A>0
egen `PT'_VAT_pre1B = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_6) // 2013(1)-2013(6).
gen `PT'_paid_pre1B = `PT'_VAT_pre1B>0
egen `PT'_VAT_pre1C = rowtotal(`PT'_VAT_pre1A `PT'_VAT_pre1B) // 2013(1)-2013(10)
gen `PT'_paid_pre1C = `PT'_VAT_pre1C > 0 // 2013(1)-2013(10)

la var `PT'_VAT_pre1A "Apr13-Jun13"
la var `PT'_paid_pre1A "Apr13-Jun13"
la var `PT'_VAT_pre1B "Jan13-Apr13"
la var `PT'_paid_pre1B "Jan13-Apr13"
la var `PT'_VAT_pre1C "Jan13-Jun13"
la var `PT'_paid_pre1C "Jan13-Jun13"

**FOR LETTER DELIVERY IN 2013 PERIOD 13:
egen `PT'_VAT_pre2A = rowtotal(`PT'_pVATContribution2013_9-`PT'_pVATContribution2013_12) // 2013(9)-2013(12)
gen `PT'_paid_pre2A = `PT'_VAT_pre2A>0
egen `PT'_VAT_pre2B = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_8) // 2013(1)-2013(8)
gen `PT'_paid_pre2B = `PT'_VAT_pre2B>0
egen `PT'_VAT_pre2C = rowtotal(`PT'_VAT_pre2A `PT'_VAT_pre2B) // 2013(1)-2013(10)
gen `PT'_paid_pre2C = `PT'_VAT_pre2C > 0 // 2013(1)-2013(10)

la var `PT'_VAT_pre2A "May13-Jul13"
la var `PT'_VAT_pre2B "Jan13-May13"
la var `PT'_paid_pre2A "May13-Jul13"
la var `PT'_paid_pre2B "Jan13-May13"
la var `PT'_VAT_pre2C "Jan13-Jul13"
la var `PT'_paid_pre2C "Jan13-Jul1"

**USING ACTUAL LETTER DELIVER DATE:
tempvar T1 T2 T3 T4 T5 T6 //could loop this but doing this for speed now
egen `T1' = rowtotal(`PT'_pVATContribution2013_7-`PT'_pVATContribution2013_10) if LD_PERIOD==11 //2013(7)-2013(10)
egen `T2' = rowtotal(`PT'_pVATContribution2013_8-`PT'_pVATContribution2013_11) if LD_PERIOD==12 //2013(8)-2013(11)
egen `T3' = rowtotal(`PT'_pVATContribution2013_9-`PT'_pVATContribution2013_12) if LD_PERIOD==13 //2013(9)-2013(12)
egen `PT'_VAT_pre4A = rowtotal(`T1' `T2' `T3')
gen `PT'_paid_pre4A = `PT'_VAT_pre4A>0

la var `PT'_VAT_pre4A "[LD-4],[LD-1]"
la var `PT'_paid_pre4A "[LD-4],[LD-1]"

egen `T4' = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_6) if LD_PERIOD==11 //2013(1)-2013(6)
egen `T5' = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_7) if LD_PERIOD==12 //2013(1)-2013(7)
egen `T6' = rowtotal(`PT'_pVATContribution2013_1-`PT'_pVATContribution2013_8) if LD_PERIOD==13 //2013(1)-2013(8)
egen `PT'_VAT_pre4B = rowtotal(`T4' `T5' `T6')
gen `PT'_paid_pre4B = `PT'_VAT_pre4B>0

la var `PT'_VAT_pre4B "Jan13,[LD-4]"
la var `PT'_paid_pre4B "Jan13,[LD-4]"

egen `PT'_VAT_pre4C = rowtotal(`PT'_VAT_pre4A `PT'_VAT_pre4B) // 2013(1)-2013(10)
gen `PT'_paid_pre4C = `PT'_VAT_pre4C > 0
la var `PT'_VAT_pre4C "Jan13,[LD-1]"
la var `PT'_paid_pre4C "Jan13,[LD-1]"

**CREATE TRIMMED VARIABLES + QUADRATICS OF TRIMMED VARIABLES**

**POST TREATMENT ANALYSIS**
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

gen		`PT'_VAT_post`i'_trim = 	min(`PT'_VAT_post`i', 10000)
gen		`PT'_VAT_post`i'_trim_sq = 	`PT'_VAT_post`i'_trim^2
la var 	`PT'_VAT_post`i'_trim 		"`POST'"
la var 	`PT'_VAT_post`i'_trim_sq 	"`POST' Sq"

gen 	`PT'_VAT_prior`i'_trim = 	min(`PT'_VAT_prior`i',10000)
gen 	`PT'_VAT_prior`i'_trim_sq = `PT'_VAT_prior`i'_trim^2
la var 	`PT'_VAT_prior`i'_trim 		"`PRE'"
la var 	`PT'_VAT_prior`i'_trim_sq 	"`PRE' Sq"
} //end i

**PRE-PERIOD ANALYSIS**
forv i=1/4{
	foreach j in A B C{
		if `i'!=3{
		gen 	`PT'_VAT_pre`i'`j'_trim = 	min(`PT'_VAT_pre`i'`j',10000)	
		gen 	`PT'_VAT_pre`i'`j'_trim_sq =	`PT'_VAT_pre`i'`j'_trim^2
		
		local LABEL : var label `PT'_VAT_pre`i'`j'
		la var `PT'_VAT_pre`i'`j'_trim 		"`LABEL'"
		la var `PT'_VAT_pre`i'`j'_trim_sq 	"`LABEL' Sq"
		} // end i!=3
	} //end j
} //end i

**CREATE 2012 AMOUNTS TRIMMMED
gen `PT'_VAT_2012_trim = 		min(`PT'_VAT_2012, 10000)
gen `PT'_VAT_2012_trim_sq = 	`PT'_VAT_2012_trim^2
la var `PT'_VAT_2012_trim 		"Paid in 2012"
la var `PT'_VAT_2012_trim_sq 	"Paid in 2012 Sq"

} //end PT


**GENERATE CLUSTER COMPLIANCE
bys clusid: egen mean_paid_2012 = mean(C_paid_2012)
	la var mean_paid_2012 "Cluster Compliance I"
gen HICOMP =  mean_paid_2012>.15
	la var HICOMP "High Compliance 0/1 (Based on Challan)"
	
**RANDOM LABELING
la var treat_peer "Peer Info"


