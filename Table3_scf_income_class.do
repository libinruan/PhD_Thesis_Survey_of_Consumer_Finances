clear
set more off
set maxvar 32000
cd "C:\Users\Li-Pin\Desktop\final_Yang\data\clean_data"
!del *.dta

insheet using IncHomNeg_II_subset_2013.csv, comma names clear
gen one = 1
sort inc
gen cumwgt = sum(weight)
sort one
by one: egen sumwgt = total(weight)
gen ratio = cumwgt/sumwgt
gen pplwgt = weight/sumwgt

gen inc0 = .
gen inc1 = .
gen inc2 = .
gen inc3 = .
gen inc4 = .
gen inc5 = .
gen inc6 = .

replace inc0 = 1  if ratio<=1
replace inc1 = 1  if ratio<=0.2
replace inc2 = 1  if ratio>0.2 & ratio<=0.4
replace inc3 = 1  if ratio>0.4 & ratio<=0.6
replace inc4 = 1  if ratio>0.6 & ratio<=0.8 
replace inc5 = 1  if ratio>0.8 & ratio<=0.9 
replace inc6 = 1  if ratio>0.9

order pplwgt ratio cumwgt weight net inc*

gen wettinc = pplwgt*inc
gen wettnet = pplwgt*net

gen imed = .
gen iavg = .
gen wmed = .
gen wavg = .
gen idx = .
gen entsum = .
gen entshare = .
save data, replace

forvalues v = 0/6{
	use data, replace
	
	summarize inc [aw=pplwgt] if inc`v' == 1, detail
	replace imed = r(p50) if inc`v' == 1
	
	summarize inc [aw=pplwgt] if inc`v' == 1, detail
	replace iavg = r(mean) if inc`v' == 1
	
	summarize net [aw=pplwgt] if inc`v' == 1, detail
	replace wmed = r(p50) if inc`v' == 1
	
	summarize net [aw=pplwgt] if inc`v' == 1, detail
	replace wavg = r(mean) if inc`v' == 1
	
	summarize pplwgt if inc`v' == 1, detail
	replace entsum = r(sum) if inc`v' == 1
	summarize pplwgt if inc`v' == 1 & smlbuz == 1, detail
	replace entshare = r(sum)/entsum if inc`v' == 1
	
	replace idx = `v' if inc`v' == 1
	drop if idx == .
	collapse(mean) imed iavg wmed wavg entshare, by(idx)
	if `v'==0{
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

collapse(mean) imed iavg wmed wavg entshare, by(idx)

outsheet idx i* w* entshare using Figure3_2013_income_class.csv, comma replace

!del *.dta

