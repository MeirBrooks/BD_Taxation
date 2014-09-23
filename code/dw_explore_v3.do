/*
PROJECT: BD-TAXATION - REGRESSIONS BY DATE
ANALYSIS BY ENTRY DATE


NOTES: 
1 - Always uses only firms who's letters were delivered
2 - high compliance is where we see the action */

pause on 
set more off

use "X:\BD Taxation Core Data\Merged Data\for_analysis_v4.dta", clear

drop *_num* *pVATContribution* reg* __*
gen sample = . 

order mean_paid_2012 HICOMP, after(LD_PERIOD)

**SET OUTPUT LOCALS**
local OUT "X:\BD Taxation\Code\analysis\Code\dw_explore\Analysis4London"
local START preamble(list info) replace
local END enddoc compile
local CWIDTH 4cm

**SET GLOBAL ESTTAB SETTINGS*
local STARS "star(* .1 ** .05 *** .01)"
local ESTOPT replace label booktabs fragment b(3) se(3) nonotes 
local NOTE "Clusters are defined as geographic groups of firms. All VAT payment variables top-coded at 10,000 Tk.  Squared VAT payment terms are the squared top-coded variables. High compliance cluster implies $>$15% of firms in a cluster paid VAT in 2012."

**BEGIN REGRESSIONS*

**SECTION 1 -- POST TREATMENT ANALYSIS HIGH/LOW COMPLIANCE + PAYMENT AMOUNT/INDICATORS + ZEROS/NON-ZEROS**
local PAYMENT_CTRLS "C_VAT_prior1_trim C_VAT_prior1_trim_sq"
local KEEP_COLUMNS "REG\`COMPNO'\`INCLUDE_ZEROS'\`type'1 REG\`COMPNO'\`INCLUDE_ZEROS'\`type'4"
local FILENAME "\`DATE2'_OLS_Post-Payment.tex"

foreach type in C{ //C FOR CHALLAN, A FOR ATTEST, E FOR ENTRY
	if "`type'"=="C"{
	local DATE "Challan Date"
	local DATE2 "Challan"
	}

	if "`type'"=="A"{
	local DATE "Attest Date"
	local DATE2 "Attest"
	}

	if "`type'"=="E"{
	local DATE "Entry Date"
	local DATE2 "Entry"
	}


	foreach INCLUDE_ZEROS in 1 0{
		if "`INCLUDE_ZEROS'"=="0"{
		local ZEROS "& \`type'_VAT_post\`i'!=0"
		local ZERONOTE ", Excluding Analysis Period Non-Payers"
		local ESTOUTADD "SPECIAL"
		}
		if "`INCLUDE_ZEROS'"=="1"{
		local ZEROS ""
		local ZERONOTE ""
		local ESTOUTADD ""
		}

		foreach COMP in High Low{
			if "`COMP'"=="High" {
			local COMPNO = 1
			}
			if "`COMP'"=="Low" {
			local COMPNO = 0
			}

		**1.1 VAT PAYMENT + HIGH/LOW COMPLIANCE**
			eststo clear
			forvalues i=1/4{
				qui reg `type'_VAT_post`i'_trim treat_peer C_paid_2012 `PAYMENT_CTRLS' if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS', vce(cluster clusid)
				qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
				
			}
			
		**RUN SAMPLE 1 USING SAMPLE USED FOR SAMPLE 4**
			local i = 1 
			qui reg `type'_VAT_post1_trim treat_peer C_paid_2012 `PAYMENT_CTRLS' if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & e(sample), vce(cluster clusid)
			eststo SPECIAL
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
		
				esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/REG11`type'`COMP'`INCLUDE_ZEROS'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						stats(CTRLMEAN r2 N, ///
						 fmt(3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Ctrl. Mean" "R-Sq" "Observations") ///
						) // end stats		
						


			local TITLE  "Payment Amounts Based on"
			local SAMPLE "[`COMP' Compliance`ZERONOTE']"

			if "`COMP'"=="High" & "`INCLUDE_ZEROS'"=="1"{
				tex3pt "`OUT'/Raw/REG11`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									`START' land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}
			else {
				tex3pt "`OUT'/Raw/REG11`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}


		**1.3 VAT PAYMENT INDICATOR + HIGH/LOW COMPLIANCE**
			forvalues i=1/4{
				qui reg `type'_paid_post`i' treat_peer C_paid_2012 if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS', vce(cluster clusid)		
				qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
				
				
		**RUN SAMPLE 1 USING SAMPLE USED FOR SAMPLE 4**
			local i = 1 
			qui reg `type'_paid_post1 treat_peer C_paid_2012 if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & e(sample), vce(cluster clusid)				
			eststo SPECIAL
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
				
					esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/REG13`type'`COMP'`INCLUDE_ZEROS'", /// 
							replace fragment booktabs ///
							label b(3) se(3) se ///
							star(* .1 ** .05 *** .01) ///
							stats(CTRLMEAN r2 N, ///
							 fmt(3 3 0) ///
							 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
							 labels("Ctrl. Mean" "R-Sq" "Observations") ///
							) // end stats		
							


			local TITLE "Payment Indicators Based on"
			local SAMPLE "[`COMP' Compliance`ZERONOTE']"

				tex3pt "`OUT'/Raw/REG13`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
									
		**1.2 VAT PAYMENT + HIGH/LOW COMPLIANCE + NONPAYER**
			forvalues i=1/4{
				qui reg `type'_VAT_post`i'_trim treat_peer `PAYMENT_CTRLS' if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0 `ZEROS', vce(cluster clusid)
				qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
			
		**RUN SAMPLE 1 USING SAMPLE USED FOR SAMPLE 4**
			local i = 1 				
			qui reg `type'_VAT_post1_trim treat_peer `PAYMENT_CTRLS' if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0 `ZEROS' & e(sample), vce(cluster clusid)
			eststo SPECIAL
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
				
				
					esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/REG12`type'`COMP'`INCLUDE_ZEROS'", /// 
							replace fragment booktabs ///
							label b(3) se(3) se ///
							star(* .1 ** .05 *** .01) ///
							stats(CTRLMEAN r2 N, ///
							 fmt(3 3 0) ///
							 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
							 labels("Ctrl. Mean" "R-Sq" "Observations") ///
							) // end stats		
							


			local TITLE		 	"Payment Amounts Based on"
			local SAMPLE		"[`COMP' Compliance, 2012 Non-Payers`ZERONOTE']"

				tex3pt "`OUT'/Raw/REG12`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")

		**1.4 VAT PAYMENT INDICATOR + HIGH/LOW COMPLIANCE + NONPAYER**
			forvalues i=1/4{
				qui reg `type'_paid_post`i' treat_peer if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0 `ZEROS', vce(cluster clusid)
				qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
				
		*RUN SAMPLE 1 USING SAMPLE USED FOR SAMPLE 4**
			local i = 1 			
			qui reg `type'_paid_post1 treat_peer if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0 `ZEROS' & e(sample), vce(cluster clusid)
			eststo SPECIAL
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
				
				
					esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/REG14`type'`COMP'`INCLUDE_ZEROS'", /// 
							replace fragment booktabs ///
							label b(3) se(3) se ///
							star(* .1 ** .05 *** .01) ///
							stats(CTRLMEAN r2 N, ///
							 fmt(3 3 0) ///
							 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
							 labels("Ctrl. Mean" "R-Sq" "Observations") ///
							) // end stats		
							

			local TITLE  "Payment Indicators Based on"
			local SAMPLE "[`COMP' Compliance, 2012 Non-Payers`ZERONOTE']"

							
			if "`COMP'"=="Low" & "`INCLUDE_ZEROS'"=="0"{						
				tex3pt "`OUT'/Raw/REG14`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land `END' ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab2") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}
			else{						
				tex3pt "`OUT'/Raw/REG14`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}					
} //end					
} //end
} //end

  //END SECTION 1

**SECTION 2 -- PRE-PERIOD ANALYSIS**
eststo clear 
local KEEP_COLUMNS "PP\`COMPNO'\`INCLUDE_ZEROS'\`type'1* PP\`COMPNO'\`INCLUDE_ZEROS'\`type'4*"
local FILENAME "\`DATE2'_OLS_Pre-Payment.tex"

foreach type in C{ //C FOR CHALLAN, A FOR ATTEST, E FOR ENTRY
	if "`type'"=="C"{
	local DATE "Challan Date"
	local DATE2 "Challan"
	}

	if "`type'"=="A"{
	local DATE "Attest Date"
	local DATE2 "Attest"
	}

	if "`type'"=="E"{
	local DATE "Entry Date"
	local DATE2 "Entry"
	}


	foreach INCLUDE_ZEROS in 1 0{
		if "`INCLUDE_ZEROS'"=="0"{
		local ZEROS "& \`type'_VAT_post\`i'!=0"
		local ZERONOTE ", Excluding Analysis Period Non-Payers"
		local ESTOUTADD ""
		}
		if "`INCLUDE_ZEROS'"=="1"{
		local ZEROS ""
		local ZERONOTE ""
		local ESTOUTADD ""
		}

		foreach COMP in High Low{
			if "`COMP'"=="High" {
			local COMPNO = 1
			}
			if "`COMP'"=="Low" {
			local COMPNO = 0
			}
		
		**2.1 VAT PAYMENT + HIGH/LOW COMPLIANCE**
		foreach i in 1 4 {
			foreach j in A B C {
				qui reg `type'_VAT_pre`i'`j'_trim treat_peer C_paid_2012 C_VAT_2012_trim C_VAT_2012_trim_sq if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS', vce(cluster clusid)
				qui eststo PP`COMPNO'`INCLUDE_ZEROS'`type'`i'`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			
			}
		}
		
		**RUN SAMPLE 1 USING SAMPLE FOR SAMPLE 4**
			local i = 1 
			foreach j in A B C {
			qui reg `type'_VAT_pre`i'`j'_trim treat_peer C_paid_2012 C_VAT_2012_trim C_VAT_2012_trim_sq if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & e(sample), vce(cluster clusid)
				eststo SPECIAL`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
		
				esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/PP21`type'`COMP'`INCLUDE_ZEROS'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						stats(CTRLMEAN r2 N, ///
						 fmt(3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Ctrl. Mean" "R-Sq" "Observations") ///
						) // end stats		
						
			local TITLE  "Pre-Payment Period Amounts Based on"
			local SAMPLE "[`COMP' Compliance`ZERONOTE']"

			if "`COMP'"=="High" & "`INCLUDE_ZEROS'"=="1"{
				tex3pt "`OUT'/Raw/PP21`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									`START' land ///
									clearpage ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}
			else {
				tex3pt "`OUT'/Raw/PP21`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}
			

			
		**2.2 VAT INDICATOR + HIGH/LOW COMPLIANCE**
		foreach i in 1 4 {
			foreach j in A B C {
				qui reg `type'_paid_pre`i'`j' treat_peer C_paid_2012 if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS', vce(cluster clusid)
				qui eststo PP`COMPNO'`INCLUDE_ZEROS'`type'`i'`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			
			}
		}
		
		**RUN SAMPLE 1 USING SAMPLE FOR SAMPLE 4**
			local i = 1 
			foreach j in A B C {
			qui reg `type'_paid_pre`i'`j' treat_peer C_paid_2012 if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & e(sample), vce(cluster clusid)
				eststo SPECIAL`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
		
				esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/PP22`type'`COMP'`INCLUDE_ZEROS'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						stats(CTRLMEAN r2 N, ///
						 fmt(3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Ctrl. Mean" "R-Sq" "Observations") ///
						) // end stats		
						
			local TITLE "Pre-Payment Period Indicators Based on"
			local SAMPLE "[`COMP' Compliance`ZERONOTE']"


				tex3pt "`OUT'/Raw/PP22`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
									
									
**2.3 VAT PAYMENT + HIGH/LOW COMPLIANCE + NONPAYERS IN 2012**
		foreach i in 1 4 {
			foreach j in A B C {
				qui reg `type'_VAT_pre`i'`j'_trim treat_peer if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & C_paid_2012==0 , vce(cluster clusid)
				qui eststo PP`COMPNO'`INCLUDE_ZEROS'`type'`i'`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			
			}
		}
		
		**RUN SAMPLE 1 USING SAMPLE FOR SAMPLE 4**
			local i = 1 
			foreach j in A B C {
			qui reg `type'_VAT_pre`i'`j'_trim treat_peer if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & C_paid_2012==0  & e(sample), vce(cluster clusid)
				eststo SPECIAL`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
		
				esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/PP23`type'`COMP'`INCLUDE_ZEROS'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						stats(CTRLMEAN r2 N, ///
						 fmt(3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Ctrl. Mean" "R-Sq" "Observations") ///
						) // end stats		
						
			local TITLE  "Pre-Payment Period Amounts Based on"
			local SAMPLE "[`COMP' Compliance, 2012 Non-Payers`ZERONOTE']"



				tex3pt "`OUT'/Raw/PP23`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")

	**2.4 VAT INDICATOR + HIGH/LOW COMPLIANCE + NONPAYERS IN 2012**
		foreach i in 1 4 {
			foreach j in A B C {
				qui reg `type'_paid_pre`i'`j' treat_peer if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & C_paid_2012==0, vce(cluster clusid)
				qui eststo PP`COMPNO'`INCLUDE_ZEROS'`type'`i'`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			
			}
		}
		
		**RUN SAMPLE 1 USING SAMPLE FOR SAMPLE 4**
			local i = 1 
			foreach j in A B C {
			qui reg `type'_paid_pre`i'`j' treat_peer if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS' & e(sample) & C_paid_2012==0, vce(cluster clusid)
				eststo SPECIAL`j'
				qui sum `e(depvar)' if e(sample) & treat_peer==0
				qui estadd scalar CTRLMEAN = r(mean)
			}
		
				esttab `KEEP_COLUMNS' `ESTOUTADD' using "`OUT'/Raw/PP24`type'`COMP'`INCLUDE_ZEROS'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						stats(CTRLMEAN r2 N, ///
						 fmt(3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Ctrl. Mean" "R-Sq" "Observations") ///
						) // end stats		
						
			local TITLE "Pre-Payment Period Indicators Based on"
			local SAMPLE "[`COMP' Compliance, 2012 Non-Payers`ZERONOTE']"


			if "`COMP'"=="Low" & "`INCLUDE_ZEROS'"=="0"{						
				tex3pt "`OUT'/Raw/PP24`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land `END' ///
									clearpage ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab2") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}
			else{						
				tex3pt "`OUT'/Raw/PP24`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`FILENAME'", ///
									land ///
									clearpage ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(cluster clusid) ///
									note("`NOTE'")
			}					
			
		} //END COMP
	} //END INCLUDE_ZEROS
} //END TYPE



**SECTION 3 -- TOBIT SPECIFICATION ON POST-PERIOD ANALYSIS**
eststo clear 
local FILENAME "\`DATE2'_TOBIT_Post-Payment.tex"
local CWIDTH "3.5cm"


foreach type in C{ //C FOR CHALLAN, A FOR ATTEST, E FOR ENTRY
	if "`type'"=="C"{
	local DATE "Challan Date"
	local DATE2 "Challan"
	}

	if "`type'"=="A"{
	local DATE "Attest Date"
	local DATE2 "Attest"
	}

	if "`type'"=="E"{
	local DATE "Entry Date"
	local DATE2 "Entry"
	}

		foreach COMP in High Low{
			if "`COMP'"=="High" {
			local COMPNO = 1
			}
			if "`COMP'"=="Low" {
			local COMPNO = 0
			}
			
		**RUN TOBIT ON POST-LETTER PERIOD VARIABLES INCLUDING 2012 NON-PAYERS**
			local TITLE		 	"Tobit of Payment Amounts Based on"
			local SAMPLE		"[`COMP' Compliance]"
		
			forv i = 1(3)4{
			tobit `type'_VAT_post`i'_trim treat_peer C_paid_2012 C_VAT_prior1_trim C_VAT_prior1_trim_sq ///
					if letter_delivered==1 & HICOMP==`COMPNO', ///
					vce(cluster clusid) ll(0) // ll = lower limit of 0
				
				eststo T`type'`i' 
				
				**MARGIN 1:
				estpost margins, dydx(*) predict(e(0,.))
				eststo TM1`type'`i' 
				
				**MARGIN 2: 
				est restore T`type'`i' 
				estpost margins, dydx(*) predict(pr(0,.))
				eststo TM2`type'`i' 
				
				**MARGIN 3: 
				est restore T`type'`i' 
				estpost margins, dydx(*) predict(ystar(0,.))
				eststo TM3`type'`i' 
				
				esttab T`type'`i' TM1`type'`i' TM2`type'`i' using "`OUT'/Raw/TOBIT_`type'`i'`COMP'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						eqlabels(, none) ///
						mgroups("Tobit Coef." "Marginal Effects", ///
						 pattern(1 1 0) ///
                         prefix(\multicolumn{@span}{c}{) ////
                         suffix(}) ///
                         span erepeat(\cmidrule(lr){@span}) ///
                        ) ///end mgroups
						stats(ll F p N, ///
						 fmt(3 3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Log-Likelihood" "Model F-Stat" "F-Stat P-Value" "Observations") ///
						) // end stats

						
				if `i' == 1 & "`COMP'" == "High"{
					tex3pt "`OUT'/Raw/TOBIT_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
						land `START' ///
						clearpage ///
						cwidth(`CWIDTH') ///
						title("`TITLE' `DATE' `SAMPLE'") ///
						tlabel("tab2") ///
						star(cluster clusid) ///
						note("`NOTE'")
				}
				else{ 
					tex3pt "`OUT'/Raw/TOBIT_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
						land  ///
						clearpage ///
						cwidth(`CWIDTH') ///
						title("`TITLE' `DATE' `SAMPLE'") ///
						tlabel("tab2") ///
						star(cluster clusid) ///
						note("`NOTE'")
				}
			} //END forvalues

			**RUN TOBIT ON POST-LETTER PERIOD VARIABLES EXCLUDING 2012 NON-PAYERS**
			local TITLE		 	"Tobit of Payment Amounts Based on"
			local SAMPLE		"[`COMP' Compliance, 2012 Non-Payers]"
		
			forv i = 1(3)4{
			tobit `type'_VAT_post`i'_trim treat_peer C_VAT_prior1_trim C_VAT_prior1_trim_sq ///
					if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0, ///
					vce(cluster clusid) ll(0) // ll = lower limit of 0
				
				eststo T`type'`i' 
				
				**MARGIN 1:
				estpost margins, dydx(*) predict(e(0,.))
				eststo TM1`type'`i' 
				
				**MARGIN 2: 
				est restore T`type'`i' 
				estpost margins, dydx(*) predict(pr(0,.))
				eststo TM2`type'`i' 
				
				**MARGIN 3: 
				est restore T`type'`i' 
				estpost margins, dydx(*) predict(ystar(0,.))
				eststo TM3`type'`i' 
				
				esttab T`type'`i' TM1`type'`i' TM2`type'`i' using "`OUT'/Raw/TOBITNP_`type'`i'`COMP'", /// 
						replace fragment booktabs ///
						label b(3) se(3) se ///
						star(* .1 ** .05 *** .01) ///
						eqlabels(, none) ///
						mgroups("Tobit Coef." "Marginal Effects", ///
						 pattern(1 1 0) ///
                         prefix(\multicolumn{@span}{c}{) ////
                         suffix(}) ///
                         span erepeat(\cmidrule(lr){@span}) ///
                        ) ///end mgroups
						stats(ll F p N, ///
						 fmt(3 3 3 0) ///
						 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
						 labels("Log-Likelihood" "Model F-Stat" "F-Stat P-Value" "Observations") ///
						) // end stats

				if "`i'" == "4" & "`COMP'" == "Low"{
					tex3pt "`OUT'/Raw/TOBITNP_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
						land `END' ///
						clearpage ///
						cwidth(`CWIDTH') ///
						title("`TITLE' `DATE' `SAMPLE'") ///
						tlabel("tab2") ///
						star(cluster clusid) ///
						note("`NOTE'")
				}
				else{ 
					tex3pt "`OUT'/Raw/TOBITNP_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
						land  ///
						clearpage ///
						cwidth(`CWIDTH') ///
						title("`TITLE' `DATE' `SAMPLE'") ///
						tlabel("tab2") ///
						star(cluster clusid) ///
						note("`NOTE'")
				}
			} //end forvalues
		} //END TYPE
} //END COMP



**SECTION 4 -- TOBIT SPECIFICATION PRE-PERIOD1**
eststo clear 
local CWIDTH "3.5cm"

foreach type in C{ //C FOR CHALLAN, A FOR ATTEST, E FOR ENTRY
	if "`type'"=="C"{
	local DATE "Challan Date"
	local DATE2 "Challan"
	}

	if "`type'"=="A"{
	local DATE "Attest Date"
	local DATE2 "Attest"
	}

	if "`type'"=="E"{
	local DATE "Entry Date"
	local DATE2 "Entry"
	}
	
	foreach PERIOD in 1 4{
		if "`PERIOD'" == "1"{
		local FILENAME "\`DATE2'_TOBIT_P1-PrePayment.tex"
		}

		if "`PERIOD'" == "4"{
		local FILENAME "\`DATE2'_TOBIT_P4-PrePayment.tex"
		}

			foreach COMP in High Low{
				if "`COMP'"=="High" {
				local COMPNO = 1
				}
				if "`COMP'"=="Low" {
				local COMPNO = 0
				}
				
			**RUN TOBIT ON POST-LETTER PERIOD VARIABLES INCLUDING 2012 NON-PAYERS**
				local TITLE		 	"Tobit of Pre-Payment Period Amounts Based on"
				local SAMPLE		"[`COMP' Compliance]"
			
				foreach i in A B C {
				tobit `type'_VAT_pre`PERIOD'`i'_trim treat_peer C_paid_2012 C_VAT_2012_trim C_VAT_2012_trim_sq ///
						if letter_delivered==1 & HICOMP==`COMPNO', ///
						vce(cluster clusid) ll(0) // ll = lower limit of 0
					
					eststo T`type'`i' 
					
					**MARGIN 1:
					estpost margins, dydx(*) predict(e(0,.))
					eststo TM1`type'`i' 
					
					**MARGIN 2: 
					est restore T`type'`i' 
					estpost margins, dydx(*) predict(pr(0,.))
					eststo TM2`type'`i' 
					
					**MARGIN 3: 
					est restore T`type'`i' 
					estpost margins, dydx(*) predict(ystar(0,.))
					eststo TM3`type'`i'
					
					esttab T`type'`i' TM1`type'`i' TM2`type'`i' using "`OUT'/Raw/TOBIT`PERIOD'_`type'`i'`COMP'", /// 
							replace fragment booktabs ///
							label b(3) se(3) se ///
							star(* .1 ** .05 *** .01) ///
							eqlabels(, none) ///
							mgroups("Tobit Coef." "Marginal Effects", ///
							 pattern(1 1 0) ///
							 prefix(\multicolumn{@span}{c}{) ////
							 suffix(}) ///
							 span erepeat(\cmidrule(lr){@span}) ///
							) ///end mgroups
							stats(ll F p N, ///
							 fmt(3 3 3 0) ///
							 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
							 labels("Log-Likelihood" "Model F-Stat" "F-Stat P-Value" "Observations") ///
							) // end stats

							
					if "`i'" == "A" & "`COMP'" == "High"{
						tex3pt "`OUT'/Raw/TOBIT`PERIOD'_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
							land `START' ///
							clearpage ///
							cwidth(`CWIDTH') ///
							title("`TITLE' `DATE' `SAMPLE'") ///
							tlabel("tab2") ///
							star(cluster clusid) ///
							note("`NOTE'")
					}
					else{ 
						tex3pt "`OUT'/Raw/TOBIT`PERIOD'_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
							land  ///
							clearpage ///
							cwidth(`CWIDTH') ///
							title("`TITLE' `DATE' `SAMPLE'") ///
							tlabel("tab2") ///
							star(cluster clusid) ///
							note("`NOTE'")
					}
				} //END forvalues

				**RUN TOBIT ON POST-LETTER PERIOD VARIABLES EXCLUDING 2012 NON-PAYERS**
				local TITLE		 	"Tobit of Pre-Payment Period Amounts Based on"
				local SAMPLE		"[`COMP' Compliance, 2012 Non-Payers]"
			
				foreach i in A B C {
				tobit `type'_VAT_pre`PERIOD'`i'_trim treat_peer ///
						if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012 == 0 , ///
						vce(cluster clusid) ll(0) // ll = lower limit of 0
					
					eststo T`type'`i' 
					
					**MARGIN 1:
					estpost margins, dydx(*) predict(e(0,.))
					eststo TM1`type'`i' 
					
					**MARGIN 2: 
					est restore T`type'`i' 
					estpost margins, dydx(*) predict(pr(0,.))
					eststo TM2`type'`i' 
					
					**MARGIN 3: 
					est restore T`type'`i' 
					estpost margins, dydx(*) predict(ystar(0,.))
					eststo TM3`type'`i' 
					
					esttab T`type'`i' TM1`type'`i' TM2`type'`i' using "`OUT'/Raw/TOBIT`PERIOD'NP_`type'`i'`COMP'", /// 
							replace fragment booktabs ///
							label b(3) se(3) se ///
							star(* .1 ** .05 *** .01) ///
							eqlabels(, none) ///
							mgroups("Tobit Coef." "Marginal Effects", ///
							 pattern(1 1 0) ///
							 prefix(\multicolumn{@span}{c}{) ////
							 suffix(}) ///
							 span erepeat(\cmidrule(lr){@span}) ///
							) ///end mgroups
							stats(ll F p N, ///
							 fmt(3 3 3 0) ///
							 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
							 labels("Log-Likelihood" "Model F-Stat" "F-Stat P-Value" "Observations") ///
							) // end stats

					if "`i'" == "C" & "`COMP'" == "Low"{
						tex3pt "`OUT'/Raw/TOBIT`PERIOD'NP_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
							land `END' ///
							clearpage ///
							cwidth(`CWIDTH') ///
							title("`TITLE' `DATE' `SAMPLE'") ///
							tlabel("tab2") ///
							star(cluster clusid) ///
							note("`NOTE'")
					}
					else{ 
						tex3pt "`OUT'/Raw/TOBIT`PERIOD'NP_`type'`i'`COMP'" using "`OUT'/`FILENAME'", ///
							land  ///
							clearpage ///
							cwidth(`CWIDTH') ///
							title("`TITLE' `DATE' `SAMPLE'") ///
							tlabel("tab2") ///
							star(cluster clusid) ///
							note("`NOTE'")
					}
				} //end forvalues
			} //END TYPE
	} //END PERIOD
} //END COMP


/*

cap log close
log using "Y:\BD_Taxation\Tobit_VAT4.txt", replace

**EXPLORATORY WORK**
eststo clear
**RUN TOBIT**
**Betas indicator how a one unit change in a regressor affects the latent dependent variable Y*.
tobit C_VAT_post4_trim treat_peer C_paid_2012 C_VAT_prior1_trim C_VAT_prior1_trim_sq ///
		if letter_delivered==1 & HICOMP==1, ///
		vce(cluster clusid) ll(0)
		
		eststo TEMP1

**RUN POSTESTIMATION**
**Marginal effects of E(Y|Y>0) 
**Gives the marginal effects for the expected value of Y conditional on Y being uncensored.  
estpost margins, dydx(*) predict(e(0,.))
eststo MARGINS1

**Marginal Effects of Pr(Y*>0) describe how the probability of being uncensored changes with respect to the regressors
est restore TEMP1
estpost margins, dydx(*) predict(pr(0,.))
eststo MARGINS2

**Marginal effects of E(Y*|Y>0)=E(Y)
**Gives the marginal effects for the unconditional expected value of Y, given that uncensored values are >0. 
est restore TEMP1
estpost margins, dydx(*) predict(ystar(0,.))
eststo MARGINS3
*same as: 
	*margins, dydx(*) expression(predict(ystar(0,.))*predict(pr(0,.)))
	*i.e. decomposes the effect into an effect on the uncensored proportion of the distribution and 
	*the probability that an observation will fall in the positive part of the distribution

**In this case: 
**Those treated with peers as 4% more likely to be uncensored 
**OR 
**those treated with peers are 4% less likely to be censored in the data (i.e. paid zero tax).

**NOTE: Report betas + all three margins


*********************
**REGRESSION OUTPUT**
*********************
esttab, label b(3) se(3) se ///
		star(* .1 ** .05 *** .01) //

**COLUMN1 = BETAS FROM TOBIT (i.e. Marginal effects of regressors on latent variable Y*)
**COLUMN2 = Marginal Effects for the expected value of Y conditional on Y being uncensored [i.e. E(Y|Y>0)]
**COLUMN3 = Marginal effects for Pr(Y*>0) - describes how the probability of being uncensored changes with respect to the regressors (i.e. those treated at x% more likely to pay >0Tk tax)
**COLUMN4 = Marginal effects for the unconditional expected value of Y, given that uncensored values are >0 [i.e. E(Y*|Y>0)=E(Y)]

**MUSHFIQ: I believe Column2 & Column3 were the effects you were referring too.
**NOTE: I believe we could also censor the data from above @ 10k and use the untrimmed variables

cap log close




