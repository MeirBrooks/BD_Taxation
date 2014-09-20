/*
PROJECT: BD-TAXATION - REGRESSIONS BY DATE
ANALYSIS BY ENTRY DATE


NOTES: 
1 - Always uses only firms who's letters were delivered
2 - high compliance is where we see the action */

use "X:\BD Taxation Core Data\Merged Data\for_analysis_v4.dta", clear

drop *_num* *pVATContribution* reg* __*

order mean_paid_2012 HICOMP, after(LD_PERIOD)

**SET OUTPUT LOCALS**
local OUT "X:\BD Taxation\Code\analysis\Code\dw_explore\Analysis4London"
local START preamble(list info) replace
local END enddoc compile
local CWIDTH 4cm

**SET GLOBAL ESTTAB SETTINGS*
local STARS "star(* .1 ** .05 *** .01)"
local ESTOPT replace label booktabs fragment b(3) se(3) nonotes 
local NOTE "Cluster robust standard errors in parentheses (firm cluster level). All VAT payment variables top-coded at 10,000 Tk.  Squared VAT payment terms are the squared top-coded variables. High compliance cluster implies $>$15% of firms in a cluster paid VAT in 2012."

**BEGIN REGRESSIONS*

local PAYMENT_CTRLS "C_VAT_prior\`i'_trim C_VAT_prior\`i'_trim_sq"
local KEEP_COLUMNS "REG\`COMPNO'\`INCLUDE_ZEROS'\`type'1 REG\`COMPNO'\`INCLUDE_ZEROS'\`type'4"

**SECTION 1 -- HIGH/LOW COMPLIANCE + PAYMENT AMOUNT/INDICATORS + ZEROS/NON-ZEROS**
foreach type in C A E{
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
		}
		if "`INCLUDE_ZEROS'"=="1"{
		local ZEROS ""
		local ZERONOTE ""
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
				esttab `KEEP_COLUMNS'  using "`OUT'/Raw/REG11`type'`COMP'`INCLUDE_ZEROS'", /// 
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
				tex3pt "`OUT'/Raw/REG11`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`DATE2'_LondonAnalysis.tex", ///
									`START' land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(ols) ///
									note("`NOTE'")
			}
			else {
				tex3pt "`OUT'/Raw/REG11`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`DATE2'_LondonAnalysis.tex", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(ols) ///
									note("`NOTE'")
			}


			**1.3 VAT PAYMENT INDICATOR + HIGH/LOW COMPLIANCE**
				forvalues i=1/4{
					qui reg `type'_paid_post`i' treat_peer C_paid_2012 if letter_delivered==1 & HICOMP==`COMPNO' `ZEROS', vce(cluster clusid)		
					qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
					qui sum `e(depvar)' if e(sample) & treat_peer==0
					qui estadd scalar CTRLMEAN = r(mean)
				}
					esttab `KEEP_COLUMNS' using "`OUT'/Raw/REG13`type'`COMP'`INCLUDE_ZEROS'", /// 
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

				tex3pt "`OUT'/Raw/REG13`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`DATE2'_LondonAnalysis.tex", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(ols) ///
									note("`NOTE'")
									
			**1.2 VAT PAYMENT + HIGH/LOW COMPLIANCE + NONPAYER**
				forvalues i=1/4{
					qui reg `type'_VAT_post`i'_trim treat_peer `PAYMENT_CTRLS' if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0 `ZEROS', vce(cluster clusid)
					qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
					qui sum `e(depvar)' if e(sample) & treat_peer==0
					qui estadd scalar CTRLMEAN = r(mean)
				}
					esttab `KEEP_COLUMNS' using "`OUT'/Raw/REG12`type'`COMP'`INCLUDE_ZEROS'", /// 
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

				tex3pt "`OUT'/Raw/REG12`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`DATE2'_LondonAnalysis.tex", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(ols) ///
									note("`NOTE'")

			**1.4 VAT PAYMENT INDICATOR + HIGH/LOW COMPLIANCE + NONPAYER**
				forvalues i=1/4{
					qui reg `type'_paid_post`i' treat_peer if letter_delivered==1 & HICOMP==`COMPNO' & C_paid_2012==0 `ZEROS', vce(cluster clusid)
					qui eststo REG`COMPNO'`INCLUDE_ZEROS'`type'`i'
					qui sum `e(depvar)' if e(sample) & treat_peer==0
					qui estadd scalar CTRLMEAN = r(mean)
				}
					esttab `KEEP_COLUMNS' using "`OUT'/Raw/REG14`type'`COMP'`INCLUDE_ZEROS'", /// 
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
				tex3pt "`OUT'/Raw/REG14`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`DATE2'_LondonAnalysis.tex", ///
									land `END' ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab2") ///
									star(ols) ///
									note("`NOTE'")
			}
			else{						
				tex3pt "`OUT'/Raw/REG14`type'`COMP'`INCLUDE_ZEROS'" using "`OUT'/`DATE2'_LondonAnalysis.tex", ///
									land ///
									clearpage cwidth(`CWIDTH') ///
									title("`TITLE' `DATE' `SAMPLE'") ///
									tlabel("tab1") ///
									star(ols) ///
									note("`NOTE'")
			}					
} //end					
} //end
} //end
