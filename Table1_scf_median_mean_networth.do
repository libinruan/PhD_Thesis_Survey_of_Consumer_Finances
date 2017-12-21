*share of entrepreneurial household is calculated in the file for Table2.

clear
set more off
set maxvar 32000
cd "C:\Users\Li-Pin\Desktop\final_Yang\data\clean_data"
!del mean2median.dta

capture program drop sub_mean2median
program define sub_mean2median
clear 
args yr
insheet using IncHomNeg_subset_`yr'.csv, comma names clear
destring, replace
drop if mi(numppl)
gen dummy = 1
*egen wgtavg = wtmean(net), weight(weight) by(dummy) *work as well.
summarize net [aw=weight], detail
*return list
gen p50 = r(p50)
gen avg = r(mean)
collapse p50 avg, by(dummy)
gen year = `yr'
gen a2m = avg/p50
order year avg p50 a2m
drop dummy
save temp, replace
if `yr'==1983{
	save mean2median, replace
	*append using mean2median temp
}
else
{
	append using mean2median temp
	save mean2median, replace
}	
end

forvalues i = 1983(3)2013{
	sub_mean2median `i'
}

collapse avg p50 a2m, by(year)
sort year
outsheet year avg p50 a2m using Figure1_mean2median.csv, comma replace
graph twoway line a2m year
!del mean2median.dta
!del temp.dta
