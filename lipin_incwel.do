clear
set more off
cd "E:\GoogleDrive\Coursework\2015summer\scf"

capture program drop incwel_scf
program define incwel_scf
args argu
use scf`argu', clear

label var age "x14 age"
label var wgt "x42001/5 corrected weights for implicates "
*FIN=LIQ+CDS+NMMF+STOCKS+BOND+RETQLIQ+SAVBND+CASHLI+OTHMA+OTHFIN
label var fin "total financial assets"
label var vehic "autos,motor homes, rvs, airplanes"
label var houses "value of primary residence"
label var housecl "homeownership class: 1=owner, 2=otherwise"
label var oresre "other residential real estate"
label var nnresre "net equity in nonresidential real estate"

label var bus " ACTBUS+NONACTBUS "
label var actbus "businesses where the HH has an active interest"
label var nonactbus "businesses where the HH has an inactive interest"

label var nhnfin "total nonfinancial assets excluding prncipal residence"
label var asset "total asset = FIN+NFIN"
label var mrthel "housing debt (incl. mortgage)"
label var homeeq "home equity = home value - housing debt"
gen occat1 = OCCAT1
gen occat2 = OCCAT2

gen isboss = 0
replace isboss = 1 if occat1==2

label var occat1 "work status categories for head"
* 1 work for someone else, 2 self-employed/partnership, 3 retired,
* disabled + student/homemaker/misc. not working and 65 and out of 
* the labor force
label var occat2 "occupation classification for head"
* 1 managerial/professional 2 technical,sales,services 3 laborers
* 4 not working

label var norminc "adjust actual/normal income to level of survey year"
label var networth "networth = asset - debt"
gen house = houses //Yang didn't add vehic into this category
gen nonhouse = networth - house 
drop if wgt==. | wgt<=0
drop if house<=0 // rather than just less than. It is key to the result
drop if nonhouse==.

gen agegroup = 0
drop if age<19 | age>=90

gen shift = `argu' - 2001
gen year = `argu'

*we limit ourselves to people were at leat 20 years old in 2001
drop if age<(19+shift) 

forvalues bot = 20(5)70{
	local top = `bot'+4
	replace agegroup = `bot'+shift+2 if age>=`bot'+shift & age<=`top'+shift
}
drop if agegroup==0
drop if agegroup>70+shift+2 | agegroup<20+shift+2

* household consumption equivalent 
gen divider = 0
replace divider = 1   if famsiz==1 
replace divider = 1.1 if famsiz==2
replace divider = 1.2 if famsiz==3
replace divider = 1.3 if famsiz==4
replace divider = 1.4 if famsiz==5
replace divider = 1.5 if famsiz==6
replace divider = 1.6 if famsiz==7
replace divider = 1.7 if famsiz==8
replace divider = 1.8 if famsiz==9
replace divider = 1.9 if famsiz==10
replace divider = 2   if famsiz==11
replace divider = 2.1 if famsiz==12
replace divider = 2.2 if famsiz>13
drop if divider==0

gen nonh = nonhouse      // non-housing part of net worth
gen home = house         // value of primary residence
gen heqv = house/divider // value of primary residence adjusted for family size
gen hqty = homeeq        // home equity

xtile inc10 = norminc [aw=wgt], n(10)
gen wtincwelmed = .
gen wtincwelmed_e = .
gen wtincwelmed_w = .
gen wtinchomemed_e = .
gen wtinchomemed_w = .

levelsof inc10, local(vals)
qui foreach l of local vals{
	summarize networth [aw=wgt] if inc10 == `l', detail 
	replace wtincwelmed = r(p50) if inc10 == `l'
	
	summarize networth [aw=wgt] if inc10 == `l' & isboss == 1, detail
	replace wtincwelmed_e = r(p50) if inc10 == `l' & isboss == 1
	
	summarize networth [aw=wgt] if inc10 == `l' & isboss == 0, detail
	replace wtincwelmed_w = r(p50) if inc10 == `l' & isboss == 0

	summarize home [aw=wgt] if inc10 == `l' & isboss == 1, detail
	replace wtinchomemed_e = r(p50) if inc10 == `l' & isboss == 1
	
	summarize home [aw=wgt] if inc10 == `l' & isboss == 0, detail
	replace wtinchomemed_w = r(p50) if inc10 == `l' & isboss == 0	
	
}
bysort isboss inc10: gen no1=_n
drop if no1!=1

gen wiwmed_e = wtincwelmed_e/1000000
gen wiwmed_w = wtincwelmed_w/1000000
gen wihmed_w = wtinchomemed_w/1000000
gen wihmed_e = wtinchomemed_e/1000000

*line wtincwelmed_e inc10 if isboss == 1 || line wtincwelmed_w inc10 if isboss == 0
sort isboss inc10
**********************************
* bar chart (both codes blocks work)
**********************************
/*
graph bar (mean) wiwmed_w wiwmed_e, over(inc10) ///	
	legend( label(1 "Worker") label(2 "Self-employer")) ///
	ytitle("Million Dollars") title("Median Household Net Worth") ///
	subtitle("by income class [each=10%]") ///
	note("Source: 2010 Survey of Consumer Finances, Federal Resrve Board of Governors") ///
	graphregion(color(white) lwidth(medium)) ///
	legend(ring(0) col(1) position(11) bmargin(large))
	
graph export image2.emf

*/

gen inc10l = inc10 - 0.2
gen inc10r = inc10 + 0.2
twoway bar wiwmed_w inc10l if isboss==0, barw(0.4) xlabel(1 (1) 10, noticks) || ///
	bar wiwmed_e inc10r if isboss==1, barw(0.4) ///
	legend(ring(0) col(1) position(11) bmargin(large)) ///
	legend( label(1 "Worker") label(2 "Self-employer") label(3 "Worker") label(4 "Self-employer")) ///
	ytitle("Net Worth in Million Dollars (bar chart)") title("Median Household Net Worth and Home Equity") ///
	subtitle("by income class [each=10%]") ///
	note("Source: 2013 Survey of Consumer Finances, Federal Resrve Board of Governors") ///	
	graphregion(color(white) lwidth(medium)) ///
	plotregion(margin(l=2 b=0)) || line wihmed_w inc10 if isboss==0, lcolor(navy) yaxis(2) ytitle("Home Equity in Million Dollars (line chart)", axis(2)) || line wihmed_e inc10 if isboss==1, lcolor(maroon) yaxis(2)
graph save 1allinone, replace	
graph export 1allinone.emf, replace	

twoway bar wiwmed_w inc10l if isboss==0, barw(0.4) xlabel(1 (1) 10, noticks) || ///
	bar wiwmed_e inc10r if isboss==1, barw(0.4) ///
	legend(ring(0) col(1) position(11) bmargin(large)) ///
	legend( label(1 "Worker") label(2 "Self-employer") ) ///
	ytitle("Million Dollars") title("Median Household Net Worth") ///
	subtitle("by income class [each=10%]") ///
	note("Source: 2013 Survey of Consumer Finances, Federal Resrve Board of Governors") ///	
	graphregion(color(white) lwidth(medium)) ///
	plotregion(margin(l=5 b=0)) 
graph save 2networth, replace
graph export 2networth.emf, replace

twoway bar wihmed_w inc10l if isboss==0, barw(0.4) xlabel(1 (1) 10, noticks) || ///
	bar wihmed_e inc10r if isboss==1, barw(0.4) ///
	legend(ring(0) col(1) position(11) bmargin(large)) ///
	legend( label(1 "Worker") label(2 "Self-employer") ) ///
	ytitle("Million Dollars") title("Median Household Home Equity") ///
	subtitle("by income class [each=10%]") ///
	note("Source: 2013 Survey of Consumer Finances, Federal Resrve Board of Governors") ///	
	graphregion(color(white) lwidth(medium)) ///
	plotregion(margin(l=5 b=0)) 
graph save 3homeequity, replace
graph export 3homeequity.emf, replace

end

************************************
* apply macro across different years
************************************
incwel_scf 2013
