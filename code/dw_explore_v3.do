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

**SET GLOBAL ESTTAB SETTINGS*
local STARS "star(* .1 ** .05 *** .01)"
local ESTOPT replace label booktabs fragment b(3) se(3) nonotes 
local NOTE "Standard Errors clustered at cluster level in parentheses. All VAT payment variables top-coded at 10,000 Tk.  Squared VAT payment terms are the squared top-coded variables. High compliance cluster implies $>$15% of firms in a cluster paid VAT in 2012."

**BEGIN REGRESSIONS*

**1.1 VAT PAYMENT + HIGH COMPLIANCE**
eststo clear
foreach type in C A E{
	forvalues i=1/4{
		qui reg `type'_VAT_post`i'_trim treat_peer C_paid_2012 C_VAT_prior`i'_trim C_VAT_prior`i'_trim_sq if letter_delivered==1 & HICOMP==1, vce(cluster clusid)
		qui eststo REG`type'`i'
		qui sum `e(depvar)' if e(sample) & treat_peer==0
		qui estadd scalar CTRLMEAN = r(mean)
	}
		esttab REG`type'* using "`OUT'/Raw/REG11`type'", /// 
				replace fragment booktabs ///
				label b(3) se(3) se ///
				star(* .1 ** .05 *** .01) ///
				stats(CTRLMEAN r2 N, ///
				 fmt(3 3 0) ///
				 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
				 labels("Ctrl. Mean" "R-Sq" "Observations") ///
				) // end stats		
				
}

local TITLE "[High Compliance] Payment Amounts Based on"

	tex3pt "`OUT'/Raw/REG11C" using "`OUT'/LondonAnalysis.tex", ///
                        `START' land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Challan Date") ///
                        tlabel("tab1") ///
                        star(ols) ///
						note("`NOTE'")
						
	tex3pt "`OUT'/Raw/REG11A" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Attest Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")					
						
	tex3pt "`OUT'/Raw/REG11E" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Entry Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")
						

**1.2 VAT PAYMENT INDICATOR + HIGH COMPLIANCE**
eststo clear
foreach type in C A E{
	forvalues i=1/4{
		qui reg `type'_paid_post`i' treat_peer C_paid_2012  if letter_delivered==1 & HICOMP==1, vce(cluster clusid)		
		qui eststo REG`type'`i'
		qui sum `e(depvar)' if e(sample) & treat_peer==0
		qui estadd scalar CTRLMEAN = r(mean)
	}
		esttab REG`type'* using "`OUT'/Raw/REG12`type'", /// 
				replace fragment booktabs ///
				label b(3) se(3) se ///
				star(* .1 ** .05 *** .01) ///
				stats(CTRLMEAN r2 N, ///
				 fmt(3 3 0) ///
				 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
				 labels("Ctrl. Mean" "R-Sq" "Observations") ///
				) // end stats		
				
}

local TITLE "[High Compliance] Payment Indicators Based on"

	tex3pt "`OUT'/Raw/REG12C" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Challan Date") ///
                        tlabel("tab1") ///
                        star(ols) ///
						note("`NOTE'")
						
	tex3pt "`OUT'/Raw/REG12A" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Attest Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")					
						
	tex3pt "`OUT'/Raw/REG12E" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Entry Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")

**1.3 VAT PAYMENT + HIGH COMPLIANCE + NONPAYER**
eststo clear
foreach type in C A E{
	forvalues i=1/4{
		qui reg `type'_VAT_post`i'_trim treat_peer C_VAT_prior`i'_trim C_VAT_prior`i'_trim_sq if letter_delivered==1 & HICOMP==1 & C_paid_2012==0, vce(cluster clusid)
		qui eststo REG`type'`i'
		qui sum `e(depvar)' if e(sample) & treat_peer==0
		qui estadd scalar CTRLMEAN = r(mean)
	}
		esttab REG`type'* using "`OUT'/Raw/REG13`type'", /// 
				replace fragment booktabs ///
				label b(3) se(3) se ///
				star(* .1 ** .05 *** .01) ///
				stats(CTRLMEAN r2 N, ///
				 fmt(3 3 0) ///
				 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
				 labels("Ctrl. Mean" "R-Sq" "Observations") ///
				) // end stats				
}

local TITLE "[High Compliance, Non-Payers] Payment Amounts Based on"

	tex3pt "`OUT'/Raw/REG13C" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Challan Date") ///
                        tlabel("tab1") ///
                        star(ols) ///
						note("`NOTE'")
						
	tex3pt "`OUT'/Raw/REG13A" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Attest Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")					
						
	tex3pt "`OUT'/Raw/REG13E" using "`OUT'/LondonAnalysis.tex", ///
                        land  ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Entry Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")

**1.4 VAT PAYMENT INDICATOR + HIGH COMPLIANCE + NONPAYER**
eststo clear
foreach type in C A E{
	forvalues i=1/4{
		qui reg `type'_paid_post`i' treat_peer if letter_delivered==1 & HICOMP==1 & C_paid_2012==0, vce(cluster clusid)
		qui eststo REG`type'`i'
		qui sum `e(depvar)' if e(sample) & treat_peer==0
		qui estadd scalar CTRLMEAN = r(mean)
	}
		esttab REG`type'* using "`OUT'/Raw/REG14`type'", /// 
				replace fragment booktabs ///
				label b(3) se(3) se ///
				star(* .1 ** .05 *** .01) ///
				stats(CTRLMEAN r2 N, ///
				 fmt(3 3 0) ///
				 layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
				 labels("Ctrl. Mean" "R-Sq" "Observations") ///
				) // end stats		
				
}

local TITLE "[High Compliance, Non-Payers] Payment Indicators Based on"

	tex3pt "`OUT'/Raw/REG14C" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Challan Date") ///
                        tlabel("tab1") ///
                        star(ols) ///
						note("`NOTE'")
						
	tex3pt "`OUT'/Raw/REG14A" using "`OUT'/LondonAnalysis.tex", ///
                        land ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Attest Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")					
						
	tex3pt "`OUT'/Raw/REG14E" using "`OUT'/LondonAnalysis.tex", ///
                        land `END' ///
                        clearpage cwidth(20mm) ///
                        title("`TITLE' Entry Date") ///
                        tlabel("tab2") ///
                        star(ols) ///
                        note("`NOTE'")
