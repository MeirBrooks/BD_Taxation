do "S:\bd-tax"

include "Y:\BD_Taxation\code\generate_payment_by_bin"
do "Y:\BD_Taxation\code\generate_registration_file"
do "Y:\BD_Taxation\code\merge_id_to_uncollapsed_payments"
do "Y:\BD_Taxation\code\merge_pay_reg_census"

**PROCESS TO FINAL DATA**
keep if instudy==1 
keep id clusid treat circle letter_delivered reason_no_delivery delivery_date ///
		pVATContribution* ///
		num_payments_* ///
		reg* //
		
order id clusid treat circle letter_delivered reason_no_delivery delivery_date

save "X:\BD Taxation Core Data\Merged Data\for_analysis_v4.dta"
