*
clear
set more off
set maxvar 32000
cd "C:\Users\Li-Pin\Desktop\final_Yang\data\clean_data"
!del *.dta

capture program drop sub_share_totalworth
program define sub_share_totalworth
args yr

//local yr 1983
clear

insheet using IncHomNeg_II_subset_`yr'.csv, comma names clear
*drop if weight == 0
*drop if net<0

gen one = 1

summarize weight if smlbuz==1, detail
gen sml = r(sum)
sort one
by one: egen sumsml = total(weight)
gen share_sml = sml/sumsml

sort net
gen cumwgt = sum(weight)
sort one
by one: egen sumwgt = total(weight) 
gen ratio = cumwgt/sumwgt
gen pplwgt = weight/sumwgt

order year pplwgt weight sumwgt

gen net1 = .
gen net2 = .
gen net3 = .
gen net4 = .

gen no = .

replace net1 = 1 if ratio <=0.5
replace net2 = 1 if ratio >=0.5 & ratio <=0.9
replace net3 = 1 if ratio >=0.9 & ratio <=0.99
replace net4 = 1 if ratio >=0.99
gen wettnet = pplwgt*net
bysort one: egen sumwettnet = total(wettnet)


gen sub = .
gen shr = .
gen idx = .
gen entsum = .
gen entshare = .
save data, replace

/*
//---------------------------------------------------------------
use data, replace 
summarize wettnet if net1 == 1,detail
replace sub = r(sum)/sumwettnet if net1 == 1

summarize pplwgt if net1 == 1 & smlbuz == 1, detail
replace entshare = r(sum) if net1 == 1 & smlbuz == 1

replace idx = 1 if net1 == 1
return list

//----
summarize wettnet if net2 == 1,detail
replace sub = r(sum)/sumwettnet if net2 == 1

summarize pplwgt if net2 == 1, detail
replace entshare = r(sum) if net2 == 1

replace idx = 2 if net2 == 1
return list

summarize wettnet if net3 == 1,detail
replace sub = r(sum)/sumwettnet if net3 == 1
replace idx = 3 if net3 == 1
return list

//----
summarize wettnet if net4 == 1,detail
replace sub = r(sum)/sumwettnet if net4 == 1
replace idx = 4 if net4 == 1
return list

collapse(mean) year sub, by(idx)*/

forvalues v = 1/4{
	use data, replace
	summarize wettnet if net`v' == 1, detail
	replace sub = r(sum)/sumwettnet if net`v' == 1 
	
	summarize pplwgt if net`v'== 1, detail
	replace entsum = r(sum) if net`v'==1
	summarize pplwgt if net`v' == 1 & smlbuz == 1, detail
	replace entshare = r(sum)/entsum if net`v' == 1	
	
	replace idx = `v' if net`v' == 1
	drop if idx==.	
	gen netshare = sub
	collapse(mean) year netshare entshare share_sml, by(idx)
	if `v'==1{
		save stat1, replace
	}
	else
	{
		save temp, replace
		use stat1, replace
		append using temp
		save stat1, replace
	}
}

collapse(mean) year netshare entshare share_sml, by(idx)
save `yr', replace
end

forvalues v = 1983(3)2013{
	sub_share_totalworth `v'
}

forvalues v = 1983(3)2013{
	if `v' == 1983{
		use `v', replace							
		save complete, replace
	}
	else{
		use complete, replace
		append using complete `v'
		save complete, replace
	}
}
collapse(mean) netshare entshare share_sml, by(year idx)
sort year idx
outsheet year idx netshare entshare share_sml using Figure2_total_worth.csv, comma replace
!del *.dta
