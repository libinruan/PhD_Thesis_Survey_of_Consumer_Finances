clear
set more off
cd "C:\Users\Li-Pin\Desktop\scf"

capture program drop ageprofile_scf
program define ageprofile_scf
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

/*
forvalues bot = 20(5)85{
	local top = `bot'+4
	replace agegroup = `bot' if age>=`bot' & age<=`top'
}
*/

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

sort agegroup
************************************
* trick: local macro variable list
************************************
local x
foreach var of varlist nonh home heqv hqty {
	bysort agegroup: egen `var'avg = mean(`var')
	bysort agegroup: egen `var'med = median(`var')
	bysort agegroup: egen `var'p75 = pctile(`var'), p(75)
	bysort agegroup: egen `var'p25 = pctile(`var'), p(25)
	local x `x' `var'avg `var'med `var'p75 `var'p25
}

*collapse
bysort agegroup: gen no1 = _n
drop if no1!=1
keep agegroup `x'
save stat`argu', replace
end

************************************
* apply macro across different years
************************************
ageprofile_scf 2001
ageprofile_scf 2004
ageprofile_scf 2007
ageprofile_scf 2010
ageprofile_scf 2013

************************************
* combine datasets across years
************************************
use stat2001, clear
append using stat2004
save temp, replace

forvalue var = 2007(3)2013{
	use temp, clear
	append using stat`var'
	save temp, replace
}
sort agegroup

twoway line homep75 agegroup

use stat2010, clear
twoway (line homep75 agegroup) (line homep25 agegroup) (line homemed agegroup)
