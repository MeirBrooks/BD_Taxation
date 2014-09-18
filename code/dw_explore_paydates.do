use "X:\BD Taxation Core Data\Merged Data\for_analysis_v3.dta", clear

forv year = 2012/2013{
	forv i = 0/6{
		local j = 1+(2*`i')
		local k = 2*`i'
		if `i'<=5{
			local B1 `B1' pVATContribution`year'_`j'
		} 
		if `i'>0{
			local E1 `E1' pVATContribution`year'_`k'
		}
	}
}
di "`B'"
di "`E'"


egen BPAYMENT_TOTAL = rowtotal(`B1')
egen EPAYMENT_TOTAL = rowtotal(`E1')


forv year = 2012/2013{
	forv i = 0/6{
		local j = 1+(2*`i')
		local k = 2*`i'
		if `i'<=5{
			local B2 `B2' num_payments_pos`year'_`j'
		} 
		if `i'>0{
			local E2 `E2' num_payments_pos`year'_`k'
		}
	}
}

egen BNUMPAYMENT_TOTAL = rowtotal(`B2')
egen ENUMPAYMENT_TOTAL = rowtotal(`E2')
