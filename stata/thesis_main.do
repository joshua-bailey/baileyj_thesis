* joshua bailey - masters thesis - stata do file 

/*
Contents (separated by horizontal lines) :

1. GENERATE VARIABLES AND DATA PREP
2. TABLES 
3. FIGURES 

*/

clear all
clear mata
clear matrix
set more off
set scheme white_tableau 

cd "/Users/joshuabailey/Library/Mobile Documents/com~apple~CloudDocs/thesis/masters_thesis_code"

global	main 		"/Users/joshuabailey/Library/Mobile Documents/com~apple~CloudDocs/thesis/masters_thesis_code"
global 	data		"$main/data1"
global 	figures		"$main/figures"



// GENERATE VARIABLES AND DATA PREP ===========================================


// ECONOMIC COMPLEXITY MEASURES 

* Employment-based ECI

clear 
import excel using "$data/employment_itl2.xlsx", firstrow sheet("employment") cellrange(A1:AP2185)

reshape long UK, i(Year Industry) j(itl2) string
rename UK employment
rename Industry industry
rename Year year

* Produce ECI variables and clean output
ecomplexity employment, i(itl2) p(industry) t(year) 

* Gen additional vars
gen distance = 1/density
replace eci = -eci
replace pci = -pci
gen high_pci = 1 if pci>=1
replace high_pci = 0 if pci<1

save subnat_employment_eci, replace



* Exportt-based ECI 

clear
import excel using "$data/consoludated_subnationaltrade_goodsservices_final.xlsx", sheet("Sheet1") firstrow cellrange(A1:AM373)

keep if Directionoftrade == "Exports"
drop Directionoftrade ITLlevel goods* services* check_goods check_services tot tot_ons_timeseries difference
reshape long tot_, i(year ITLname) j(sector) string
rename tot_ exports

ecomplexity exports, i(ITLname) p(sector) t(year)
drop if ITLcode == "UNK2" 

save subnat_export_eci, replace

* Combine ECI measures and accounts data for analysis

clear 
import excel using "$data/itl2_matching.xlsx", sheet("Sheet1") firstrow 
save itl2_matching, replace

use subnat_employment_eci, clear 
keep year itl2 eci diversity coi 
collapse eci diversity coi, by(itl2 year)
encode itl2, gen(itl2_)
merge m:1 itl2 using itl2_matching, nogen
save subnat_employment_eci_collapse, replace


use subnat_export_eci, clear 
keep year ITLname ITLcode sector eci diversity coi 
collapse eci diversity coi, by(ITLcode year)
rename eci eci_exports
rename diversity diversity_exports
rename coi coi_exports
save subnat_export_eci_collapse, replace


use subnat_employment_eci_collapse, clear
merge 1:1 ITLcode year using subnat_export_eci_collapse, nogen
drop if missing(itl2)

save eci_comb, replace


// OTHER DATA PREP

* regional gva - index=2019
clear
import excel using "$data/regionalgrossvalueaddedbalancedbyindustryandallitlregions.xlsx", sheet("Table2a") cellrange(A2:AB3938) firstrow 

keep if SIC07code == "Total"
drop SIC*
reshape long n, i(ITLregioncode ITLregionname) j(year)
rename n gva_index2019
encode ITLregionname, gen(itl2)
rename ITLregioncode ITLcode 
rename ITLregionname ITLname
save gva_index, replace

* regional gva - gbp=2019
clear
import excel using "$data/regionalgrossvalueaddedbalancedbyindustryandallitlregions.xlsx", sheet("Table2b") cellrange(A2:AB3938) firstrow 

keep if SIC07code == "Total"
drop SIC*
reshape long n, i(ITLregioncode ITLregionname) j(year)
rename n gva_gbp2019
encode ITLregionname, gen(itl2)
rename ITLregioncode ITLcode 
rename ITLregionname ITLname
save gva_gbp, replace


* gva per hour worked - index, UK=100, current prices 
clear
import excel using "$data/itlproductivity.xlsx", sheet("A1") cellrange(A5:U239) firstrow 
keep if ITLlevel == "ITL2"
reshape long n, i(ITLcode Regionname) j(year)
rename n gva_ph_index
drop ITLlevel
rename Regionname ITLname
save gva_ph_index, replace

* gva per hour worked - gbp, chained

clear
import excel using "$data/itlproductivity.xlsx", sheet("A3") cellrange(A5:U239) firstrow 
keep if ITLlevel == "ITL2"
destring n2005, replace
reshape long n, i(ITLcode Regionname) j(year)
rename n gva_ph_gbp
drop ITLlevel
rename Regionname ITLname
save gva_ph_gbp, replace

* gva per job filled - index, UK=100, current prices
clear
import excel using "$data/itlproductivity.xlsx", sheet("B1") cellrange(A5:W239) firstrow 
keep if ITLlevel == "ITL2"
reshape long n, i(ITLcode Regionname) j(year)
rename n gva_pj_index
drop ITLlevel
rename Regionname ITLname
save gva_pj_index, replace

* gva per job filled - gbp, chained
clear
import excel using "$data/itlproductivity.xlsx", sheet("B3") cellrange(A5:W239) firstrow 
keep if ITLlevel == "ITL2"
reshape long n, i(ITLcode Regionname) j(year)
rename n gva_pj_gbp
drop ITLlevel
rename Regionname ITLname
save gva_pj_gbp, replace


* gfcf, prices=2020
clear 
import excel using "$data/regional_gfcf19972020byassetandindustry.xlsx", sheet("1.2") cellrange(A4:AE928) firstrow 

ds n*
foreach var of varlist `r(varlist)' {
  replace `var' = "0" if `var' == "[w]"
  destring `var', replace
}

drop Asset ITL1code ITL1name 
keep if SIC07industrycode == "Total"
drop SIC07industrycode SIC07industryname
reshape long n, i(ITL2name ITL2code) j(year)
rename n gfcf_gbp
rename ITL2name ITLname
rename ITL2code ITLcode

save gfcf_gbp, replace

* capital stock 
clear
import delimited using "$data/martin_gfcf_itl2.csv", varnames(1)

* construct stock
gen real_gfcf_cp = gfcf_cp / (gfcf_deflator/100)
keep if asset == "Total"
keep if sic07 == "Total"
gsort itl2code year
gsort itl2code year

bysort itl2code (year) : gen cap_stock = sum(real_gfcf_cp)

rename itl2code ITLcode 
rename itl2name ITLname

save cap_stock, replace


* gdhi, current prices
clear 
import excel using "$data/gdhi_nomisexport.xlsx", sheet("Data") cellrange(A7:AA60) firstrow 
drop in 1/12
drop in 41
reshape long n, i(Area itl) j(year)
rename n gdhi_gbp
rename itl ITLcode

save gdhi_gbp, replace


* gdhi per head, current prices
clear 
import excel using "$data/gdhi_nomisexport.xlsx", sheet("Data") cellrange(A73:AA126) firstrow 
drop in 1/12
drop in 41
reshape long n, i(Area itl) j(year)
rename n gdhi_pp_gbp
rename itl ITLcode

save gdhi_pp_gbp, replace

* fdi, earnings 
clear 
import excel using "$data/20230419FDIsubnatinwardtables.xlsx", sheet("4.7 ITL2 earn industry group") cellrange(A4:K348) firstrow 

ds n*
foreach var of varlist `r(varlist)' {
  replace `var' = "0" if `var' == "c" | `var' == "low"
  destring `var', replace
}

keep if Industrialgroup == "All industries"
drop Measure Industrialgroup
reshape long n, i(Regionname ITL2code) j(year)
rename n fdi_earn_gbp
rename Regionname ITLname
rename ITL2code ITLcode

save fdi_earn_gbp, replace

* fdi, flow
clear
import excel using "$data/20230419FDIsubnatinwardtables.xlsx", sheet("2.7 ITL2 flow industry group") cellrange(A4:K348) firstrow 

ds n*
foreach var of varlist `r(varlist)' {
  replace `var' = "0" if `var' == "c" | `var' == "low"
  destring `var', replace
}

keep if Industrialgroup == "All industries"
drop Measure Industrialgroup
reshape long n, i(Regionname ITL2code) j(year)
rename n fdi_flow_gbp
rename Regionname ITLname
rename ITL2code ITLcode

save fdi_flow_gbp, replace

* exports
clear
import excel using "$data/consoludated_subnationaltrade_goodsservices_final.xlsx", sheet("Sheet1") firstrow cellrange(A1:AM373)

keep if Directionoftrade == "Exports"
keep year ITLcode ITLname tot tot_ons_timeseries
rename tot exports_ons
rename tot_ons_timeseries exports_ons_timeseries

save exports, replace

* human capital, share of population with certain education, OECD
clear
import delimited using "$data/OECD_UKREGION_EDUCAT_24032024162130593.csv", varnames(1)

keep if ind == "NEAC_SHARE_EA_Y25T64"
drop location country indicator gender v10 meas measure unitcode unit powercodecode powercode referenceperiodcode referenceperiod flagcodes flags

merge m:1 reg_id using itl2_matching
drop if missing(ITLname) | missing(region)

gen sh_tertiary = value if educationiscedlevel == "Total tertiary education (ISCED2011 levels 5 to 8)"
gen sh_uppersecondary = value if educationiscedlevel == "Upper secondary and post-secondary non-tertiary education"
collapse sh_tertiary sh_uppersecondary, by(ITLcode ITLname year)
gen sh_uppersec_tertiary = sh_tertiary + sh_uppersecondary


save human_cap, replace


* GDE on R&D (GERD) by sector and region 

clear
import excel using "$data/ukgerdbysectorofperformanceandregion2015to2020", sheet("Table 1") firstrow cellrange(A8:H277)
drop if missing(var)

ds n*
foreach var of varlist `r(varlist)' {
	replace `var' = "0" if `var' == "[c]" | `var' == "[x]"
	destring `var', replace
}

rename RegionCode ITLcode
merge m:1 ITLcode using itl2_matching, nogen keepusing(ITLname)
gen itl2 = 0 if missing(ITLname)
replace itl2 = 1 if missing(itl2)
rename itl2 nitl2
drop ITLname

reshape long n, i(var ITLcode Region) j(year)
rename n gerd
rename nitl2 itl2
rename Region ITLname

gen gerd_business = gerd if var == "business"
gen gerd_gov = gerd if var == "gov"
gen gerd_he = gerd if var == "he"
gen gerd_non_profit = gerd if var == "non_profit"
gen gerd_tot = gerd if var == "tot"

collapse gerd* itl2, by(year ITLname ITLcode)
drop gerd

save gerd, replace

keep if itl2 == 1
drop itl2

save gerd_forconsolidated, replace


* Population density, OECD, ITL2
clear 
import delimited "$data/Rural_Urban_Classification_(2011)_of_NUTS_3_(2015)_in_England.csv", varnames(1)

* prepare data
gen reg_id = substr(nuts315cd, 1, 4)
merge m:1 reg_id using itl2_matching
replace ITLname = "Outer London - West and North West" if reg_id == "UKI7" 
replace ITLcode = "TLI7" if reg_id == "UKI7"
drop if missing(objectid)

* take average urbanisation code and round 
sencode broad_ruc11, gen(urban) gsort(-v11)
collapse urban, by(ITLname ITLcode)
gen urban_itl2 = round(urban, 1)
save urban, replace


* GDP per capita 
clear
import excel using "$data/regionalgrossdomesticproductgdpallitlregions (2)", sheet("Table 11") firstrow cellrange(A2:AA238)

keep if ITL == "ITL2"
drop ITL
reshape long n, i(ITLcode Regionname) j(year)
rename n gdp_pc_gbp
rename Regionname ITLname

save gdp_pc, replace



* merge accounts data into ECI 
use eci_comb, clear 

merge 1:1 ITLcode ITLname year using gva_index, keepusing(gva_index2019) nogen
merge 1:1 ITLcode ITLname year using gva_gbp, keepusing(gva_gbp2019) nogen
merge 1:1 ITLcode ITLname year using gva_ph_index, keepusing(gva_ph_index) nogen
merge 1:1 ITLcode ITLname year using gva_ph_gbp, keepusing(gva_ph_gbp) nogen
merge 1:1 ITLcode ITLname year using gva_pj_index, keepusing(gva_pj_index) nogen
merge 1:1 ITLcode ITLname year using gva_pj_gbp, keepusing(gva_pj_gbp) nogen
merge 1:1 ITLcode ITLname year using gfcf_gbp, keepusing(gfcf_gbp) nogen
merge 1:1 ITLcode ITLname year using cap_stock, keepusing(cap_stock) nogen
merge 1:1 ITLcode year using gdhi_gbp, keepusing(gdhi_gbp) nogen
merge 1:1 ITLcode year using gdhi_pp_gbp, keepusing(gdhi_pp_gbp) nogen
merge 1:1 ITLcode ITLname year using fdi_earn_gbp, keepusing(fdi_earn_gbp) nogen
merge 1:1 ITLcode ITLname year using fdi_flow_gbp, keepusing(fdi_flow_gbp) nogen
merge 1:1 ITLcode ITLname year using exports, keepusing(exports_ons exports_ons_timeseries) nogen
merge 1:1 ITLcode ITLname year using human_cap, keepusing(sh_tertiary sh_uppersecondary sh_uppersec_tertiary) nogen
merge 1:1 ITLcode ITLname year using gerd_forconsolidated, keepusing(gerd*) nogen
merge 1:1 ITLname year using gdp_pc, keepusing(gdp_pc_gbp) nogen
merge m:1 ITLcode ITLname using urban, keepusing(urban_itl2) nogen


* clean up 
drop if ITLcode == "UNK2"
drop itl2 itl2_
order ITLcode ITLname, before(eci)
drop if ITLcode == "TLXX" | ITLcode == "TLZ" | ITLcode == "UK"
encode ITLname, gen(ITLname_)
order ITLname_, after(ITLname)

* gen log variables for analysis

ds gva_index2019 gva_gbp2019 gva_ph_index gva_ph_gbp gva_pj_index gva_pj_gbp gfcf_gbp gdhi_gbp gdhi_pp_gbp fdi_earn_gbp fdi_flow_gbp exports_ons exports_ons_timeseries gerd_business gerd_gov gerd_he gerd_non_profit gerd_tot gdp_pc_gbp
foreach var of varlist `r(varlist)' {
  gen ln_`var' = ln(`var')
}

egen std_eci = std(eci), by(year)
egen std_eci_exports = std(eci_exports), by(year)

xtset ITLname_ year, yearly

save consolidated_all, replace


// TABLES =====================================================================


// Tables 1 and 2

use consolidated_all, clear


* Define global macros for file names for easier reference and potential adjustments
global table1 "table1_final.doc"
global table2 "table2_final.doc"

* Label variables for cleaner table names
label variable ln_gva_ph_gbp "ln GVA per hour"
label variable ln_gdp_pc_gbp "ln GDP per person"
label variable ln_gdhi_pp_gbp  "ln GDHI per person"
label variable std_eci "ECI Emp"
label variable std_eci_exports "ECI Exports"
label variable ln_gfcf_gbp "ln GFCF"
label variable sh_tertiary "Sh Tertiary"


* Table 1: Living Standards and ECI - cross section 
foreach outcome in ln_gdhi_pp_gbp ln_gdp_pc_gbp {
       
    * (1) Emp with capital
    reg `outcome' std_eci ln_gfcf_gbp, robust
    outreg2 using $table1, append word label ctitle("`outcome'", "Emp: K") adjr2
	
	* (2) Exp with capital
	reg `outcome' std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table1, append word label ctitle(Exp: K) adjr2
    
	* (3) Emp with capital and educ
    reg `outcome' std_eci ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table1, append word label ctitle(Emp: K+L) adjr2
	
	* (4) Exp with capital and educ
	reg `outcome' std_eci_exports ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table1, append word label ctitle(Exp: K+L) adjr2
    
    * (5) Emp and Exp with capital
    reg `outcome' std_eci std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table1, append word label ctitle(Emp/Exp: K) adjr2
    
	* (6) Emp and Exp with capital and educ
    reg `outcome' std_eci std_eci_exports ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table1, append word label ctitle(Emp/Exp: K+L) title("Table 1 - Cross section") sortvar(std_eci std_eci_exports) adjr2
	
}


* Table 2: Living Standards and ECI - panel
foreach outcome in ln_gva_ph_gbp ln_gdp_pc_gbp {
       
    * (1) Emp, capital - RE
    xtreg `outcome' std_eci ln_gfcf_gbp, robust
    outreg2 using $table2, append word label ctitle("`outcome'", "Emp: K") addtext(Urban FE, NO) e(r2_w r2_b r2_o)
    
    * (2) Exp, capital - RE
    xtreg `outcome' std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table2, append word label ctitle(Exp: K) addtext(Urban FE, NO) e(r2_w r2_b r2_o)
	
	* (3) Emp and Exp, capital - RE
    xtreg `outcome' std_eci std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table2, append word label ctitle(Emp/Exp: K) addtext(Urban FE, NO) e(r2_w r2_b r2_o)
	
    * (4) Emp, capital - FE
    reghdfe `outcome' std_eci ln_gfcf_gbp, vce(robust) absorb(urban_itl2)
    outreg2 using $table2, append word label ctitle(Emp: K) addtext(Urban FE, YES) adjr2 
    
    * (5) Exp, capital - FE
    reghdfe `outcome' std_eci_exports ln_gfcf_gbp, vce(robust)  absorb(urban_itl2)
    outreg2 using $table2, append word label ctitle(Exp: K) addtext(Urban FE, YES) adjr2 
	
	* (6) Emp and Exp, capital - FE
    reghdfe `outcome' std_eci std_eci_exports ln_gfcf_gbp, vce(robust) absorb(urban_itl2)
    outreg2 using $table2, append word label ctitle(Emp/Exp: K) addtext(Urban FE, YES) title("Table 2 - Panel") sortvar(std_eci std_eci_exports) adjr2 
    
}




// robustness tables: gdhi and gva per job

global table3 "table3_final.doc"
global table4 "table4_final.doc"

* Table 3: Living Standards and ECI - cross section - gdhi and gva per job
foreach outcome in ln_gdhi_pp_gbp ln_gva_pj_gbp {
       
    * (1) Emp with capital
    reg `outcome' std_eci ln_gfcf_gbp, robust
    outreg2 using $table3, append word label ctitle("`outcome'", "Emp: K") adjr2
	
	* (2) Exp with capital
	reg `outcome' std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table3, append word label ctitle(Exp: K) adjr2
    
	* (3) Emp with capital and educ
    reg `outcome' std_eci ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table3, append word label ctitle(Emp: K+L) adjr2
	
	* (4) Exp with capital and educ
	reg `outcome' std_eci_exports ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table3, append word label ctitle(Exp: K+L) adjr2
    
    * (5) Emp and Exp with capital
    reg `outcome' std_eci std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table3, append word label ctitle(Emp/Exp: K) adjr2
    
	* (6) Emp and Exp with capital and educ
    reg `outcome' std_eci std_eci_exports ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table3, append word label ctitle(Emp/Exp: K+L) title("Table 3 - Cross section") sortvar(std_eci std_eci_exports) adjr2
	
}


* Table 4: Living Standards and ECI - panel - gdhi and gva per job
foreach outcome in ln_gdhi_pp_gbp ln_gva_pj_gbp {
       
    * (1) Emp, capital - RE
    xtreg `outcome' std_eci ln_gfcf_gbp, robust
    outreg2 using $table4, append word label ctitle("`outcome'", "Emp: K") addtext(Urban FE, NO) e(r2_w r2_b r2_o)
    
    * (2) Exp, capital - RE
    xtreg `outcome' std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table4, append word label ctitle(Exp: K) addtext(Urban FE, NO) e(r2_w r2_b r2_o)
	
	* (3) Emp and Exp, capital - RE
    xtreg `outcome' std_eci std_eci_exports ln_gfcf_gbp, robust
    outreg2 using $table4, append word label ctitle(Emp/Exp: K) addtext(Urban FE, NO) e(r2_w r2_b r2_o)
	
    * (4) Emp, capital - FE
    reghdfe `outcome' std_eci ln_gfcf_gbp, vce(robust) absorb(urban_itl2)
    outreg2 using $table4, append word label ctitle(Emp: K) addtext(Urban FE, YES) adjr2 
    
    * (5) Exp, capital - FE
    reghdfe `outcome' std_eci_exports ln_gfcf_gbp, vce(robust)  absorb(urban_itl2)
    outreg2 using $table4, append word label ctitle(Exp: K) addtext(Urban FE, YES) adjr2 
	
	* (6) Emp and Exp, capital - FE
    reghdfe `outcome' std_eci std_eci_exports ln_gfcf_gbp, vce(robust) absorb(urban_itl2)
    outreg2 using $table4, append word label ctitle(Emp/Exp: K) addtext(Urban FE, YES) title("Table 4 - Panel") sortvar(std_eci std_eci_exports) adjr2 
    
}



// robustness tables: with additional controls

global table5 "table5_final.doc"
global table6 "table6_final.doc"

* Table 5: Living Standards and ECI - cross section - controls
foreach outcome in ln_gva_ph_gbp ln_gdp_pc_gbp {
       
    * (1) Emp with capital
    reg `outcome' std_eci ln_gfcf_gbp, robust
    outreg2 using $table5, append word label ctitle("`outcome'", "Emp: K") adjr2
	
	* (2) Emp with capital and educ
    reg `outcome' std_eci ln_gfcf_gbp sh_tertiary, robust
    outreg2 using $table5, append word label ctitle(Emp: K+L) adjr2
	
	* (3) Emp with gerd
	reg `outcome' std_eci ln_gerd_business ln_gerd_gov ln_gerd_he, robust
    outreg2 using $table5, append word label ctitle(Emp: R&D) adjr2
    
    * (4) Emp and capital and gerd 
    reg `outcome' std_eci ln_gfcf_gbp ln_gerd_business ln_gerd_gov ln_gerd_he, robust
    outreg2 using $table5, append word label ctitle(Emp: K+R&D) adjr2
    
	* (5) Emp and capital, human cap and gerd 
    reg `outcome' std_eci ln_gfcf_gbp sh_tertiary ln_gerd_business ln_gerd_gov ln_gerd_he, robust
    outreg2 using $table5, append word label ctitle(Emp: K+L+R&D) title("Table 5 - Cross section") sortvar(std_eci std_eci_exports) adjr2
	
}


* Table 4: Living Standards and ECI - panel - controls
foreach outcome in ln_gva_ph_gbp ln_gdp_pc_gbp {
	
       
    * (1) Emp with capital
    xtreg `outcome' std_eci ln_gfcf_gbp, robust
    outreg2 using $table6, append word label ctitle("`outcome'", "Emp: K") addtext(Urban FE, NO) e(r2_w r2_b r2_o)
    
   * (2) Emp with gerd
	xtreg `outcome' std_eci ln_gerd_business ln_gerd_gov ln_gerd_he, robust
    outreg2 using $table6, append word label ctitle(Emp: R&D) addtext(Urban FE, NO) e(r2_w r2_b r2_o)
	
	* (3) Emp with capital and gerd
	xtreg `outcome' std_eci ln_gfcf_gbp ln_gerd_business ln_gerd_gov ln_gerd_he, robust
    outreg2 using $table6, append word label ctitle(Emp: K+R&D) addtext(Urban FE, NO) e(r2_w r2_b r2_o)
	
    * (4) Emp and gerd, fe
    reghdfe `outcome' std_eci ln_gfcf_gbp sh_tertiary, vce(robust) absorb(urban_itl2)
    outreg2 using $table6, append word label ctitle(Emp: R&D) addtext(Urban FE, YES) adjr2 
    
    * (5) Emp and capital and gerd, fe
    reghdfe `outcome' std_eci ln_gfcf_gbp ln_gerd_business ln_gerd_gov ln_gerd_he, vce(robust)  absorb(urban_itl2)
    outreg2 using $table6, append word label ctitle(Exp: K+R&D) addtext(Urban FE, YES) title("Table 6 - Panel") sortvar(std_eci std_eci_exports) adjr2  

    
}




// FIGURES ====================================================================


// Section 2 ==============================

// (Fig) GDP per capita, UK regions 

clear
import excel using "$data/regionalgrossdomesticproductgdpallitlregions (2)", sheet("Table 11") firstrow cellrange(A2:AA238)

keep if ITL == "ITL1"
drop ITL
reshape long n, i(ITLcode Regionname) j(year)
rename n gdp_pc_gbp
rename Regionname ITLname
encode ITLname, gen(ITL1)


xtset ITL1 year, yearly


xtline gdp_pc_gbp, overlay ///
	legend(pos(3) col(1) all order(3 8 1 2 4 5 6 7 9 10 11 12)) ///
	xtitle(""off"") ///
	ytitle("GDP per head, chained volume measure, GBP") ///
	ylabel(,nogrid nogextend) ///
	xlabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS", size(vsmall))

graph export "$figures/gdp_pc_gbp.png", replace

// (Fig) GDHI per capita, UK regions
clear
import delimited using "$data/regional_gdhi_gdppc_itl1.csv", varnames(1)

ds year var, not
foreach var of varlist `r(varlist)' {
  rename `var' n`var'
}

reshape long n, i(year var) j(region) string

rename n value
rename region itl1 

gen gdhi_pc_gbp = cond(var == "gdhi_pc_gbp", value, .)
gen gdhi_pc_index = cond(var == "gdhi_pc_index", value, .)
gen gdp_pc_gbp = cond(var == "gdp_pc_gbp", value, .)

drop var value

replace itl1 = "North East" if itl1 == "northeast"
replace itl1 = "North West" if itl1 == "northwest"
replace itl1 = "Yorkshire and The Humber" if itl1 == "yorkshireandthehumber"
replace itl1 = "East Midlands" if itl1 == "eastmidlands"
replace itl1 = "West Midlands" if itl1 == "westmidlands"
replace itl1 = "East" if itl1 == "east"
replace itl1 = "London" if itl1 == "london"
replace itl1 = "South East" if itl1 == "southeast"
replace itl1 = "South West" if itl1 == "southwest"
replace itl1 = "Wales" if itl1 == "wales"
replace itl1 = "Scotland" if itl1 == "scotland"
replace itl1 = "Northern Ireland" if itl1 == "northernireland"

encode itl1, gen(ITL1)
collapse gdhi_pc_gbp gdhi_pc_index gdp_pc_gbp, by(ITL1 year)

gen ln_gdp_pc_gbp = log(gdp_pc_gbp)

xtset ITL1 year, yearly


xtline gdhi_pc_index, overlay ///
	legend(pos(3) col(1) all order(3 8 1 2 4 5 6 7 9 10 11 12)) ///
	xtitle(""off"") ///
	ytitle("Gross Disposable Household Income, per head, UK = 100 ") ///
	ylabel(,nogrid nogextend) ///
	xlabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS - Nomis", size(vsmall))

graph export "$figures/gdhi_pc_index.png", replace



// (Fig) Healthy life expectancy 

clear 
import excel using "$data/lifeexpect.xlsx", firstrow sheet("data") cellrange(A7:G19)


sencode Countryorregion, gen(region) gsort(MalesLifeexpectancy)


twoway rcap MalesUpperCI MalesLowerCI region, horizontal lcolor(navy) lwidth(medium) ///
	|| scatter region MalesLifeexpectancy, mcolor(navy) msymbol(O) msize(vsmall) mlabel(Countryorregion) mlabposition(3) mlabgap(15) ///
	|| rcap FemalesUpperCI FemalesLowerCI region, horizontal lcolor(orange) lwidth(medium) ///
	|| scatter region FemalesLifeexpectancy, mcolor(orange) msymbol(O) msize(vsmall) ///
		legend(label(1 "Male 95% CI") label(2 "Male Life Expectancy") ///
               label(3 "Female 95% CI") label(4 "Female Life Expectancy")) ///
        ytitle("Country or Region") ///
        xtitle("Life Expectancy") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) ///
		plotregion(lcolor(black)) ///
		note("Source: ONS. Plot shows life expectancy at birth (by sex) in 2020 to 2022 for England, Northern Ireland, Wales, and English regions.", size(vsmall))

graph export "$figures/lifeexpect.png", replace


// (Fig) Deindustrialisation, Standbury et al (2023)

*  Load ARDECO raw sector by region level data
use "$data/ardeco_sectorlevel_data_all", clear

* Rename all variables lower case
rename *, lower

* Country
gen country = substr(nuts_id,1,2)

* Keep NUTS level 1 region
keep if stat_==1

* Rename key variables
rename rnetz employment
rename rovgz gva
rename rowcz compensation

* GVA per worker by industry
gen gvapw = gva/employment
lab var gvapw "GVA per worker (Thou EUR)"
local vars gvapw
foreach var of local vars{
	gen `var'_uk = `var' if country=="UK"
	gen `var'_nonuk = `var' if country!="UK"
}

* Region level variables
bysort nuts_id year: egen empregion = total(employment)
bysort nuts_id year: egen gvaregion= total(gva)
gen gvapwregion = gvaregion/empregion

* Generate compensation per worker in each industry
gen comppw = compensation/employment
lab var comppw "Compensation per worker (Thou EUR)"

* Flag extra-regional regions, or things like French DOM TOM, Madeira, Azores
gen flag_extra = 1 if strpos(nuts_id,"Z")==3|nuts_id=="PT2"|nuts_id=="PT3"|nuts_id=="FRY"

* Generate employment share of each industry
gen empshare = employment/empregion

* Generate variable for employment shares in different years
local years 1980 1991 2000 2010
foreach year of local years{
	capture drop helper
	gen helper = empshare if year==`year'
	bysort nuts_id nace_r2: egen empshare_`year' = mean(helper)
	gen empshare_change_since`year' = empshare - empshare_`year'
	gen empshare_pctch_since`year' = empshare_change_since`year'/empshare_`year'
	capture drop helper
	gen helper = employment if year==`year'
	bysort nuts_id nace_r2: egen emp_`year' = mean(helper)
	gen emp_pctch_since`year' = (employment-emp_`year')/emp_`year'
	gen emp_ch_since`year' = (employment-emp_`year')
	capture drop helper
	gen helper = empregion if year==`year'
	bysort nuts_id nace_r2: egen emp_tot_`year' = mean(helper)
	gen emp_ch_share_since`year' = (employment-emp_`year')/emp_tot_`year'
} 

* Generate short label for graphs
gen nuts_label = nuts_name
replace nuts_label = "Yorks & Humber" if nuts_name=="Yorkshire and The Humber"
replace nuts_label = "East" if nuts_name=="East of England"
replace nuts_label = subinstr(nuts_label, " (UK)", "", .)

* Generate very short acronyms for graphs
gen nuts_short = "LON" if nuts_label=="London"
replace nuts_short = "SE" if nuts_label=="South East"
replace nuts_short = "E" if nuts_label == "East"
replace nuts_short = "SCO" if nuts_label == "Scotland"
replace nuts_short = "SW" if nuts_label == "South West"
replace nuts_short = "NW" if nuts_label == "North West"
replace nuts_short = "NE" if nuts_label == "North East"
replace nuts_short = "WM" if nuts_label == "West Midlands"
replace nuts_short = "EM" if nuts_label == "East Midlands"
replace nuts_short = "YH" if nuts_label == "Yorks & Humber"
replace nuts_short = "WA" if nuts_label == "Wales"
replace nuts_short = "NI" if nuts_label =="Northern Ireland"

* Western Europe tag
capture drop helper
gen helper = (!missing(gvapw) & year==1990)
bysort nuts_id: egen tag_westerneurope = max(helper)
drop helper

replace nuts_name = subinstr(nuts_name," (UK)","",.)
gen empshare_change_19802018 = empshare - empshare_1980
capture drop pos
gen pos = 9
replace pos = 10 if nuts_name=="Scotland"|nuts_name=="South West"|nuts_name=="Wales"

local vars "empshare_change_since1980 empshare_1980"
local cond "nace_r2==`"B-E"' & year==2018 & stat_levl_code==1 & !missing(empshare) & !missing(empshare_1980) & flag_extra!=1"
twoway (lfit `vars' if `cond', lpattern(dash)) ///
    || (lfit `vars' if `cond' & country=="UK", lpattern(dash)) ///
    || (scatter `vars' if `cond', mcolor(%10)) ///
    || (scatter `vars' if `cond' & country=="UK", mlabel(nuts_label) mlabsize(vsmall) mlabv(pos)) ///
    || (scatter `vars' if `cond' & country=="FR", mcolor(%50)) ///
    || (scatter `vars' if `cond' & country=="DE", mcolor(%50)) ///
    || (scatter `vars' if `cond' & country=="IT", mcolor(%50)) ///
    , legend(order(3 "Other" 4 "UK" 5 "France" 6 "Germany (West)" 7 "Italy") pos(6) cols(5)) ///
    ytitle("Change 1980-2018") ///
    xtitle("Manufacturing and mining employment share, 1980") ///
	ylabel(,nogrid nogextend) ///
	xlabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ARDECO. Reproduced from Stansbury et al. (2023)." "Blue denotes line of best fit across all regions; orange line denotes line of best fit for UK only. 'Other' includes NUTS1 regions in Austria," "Belgium, Denmark, Finland, Greece, Ireland, Luxembourg, Netherlands, Norway, Portugal, Spain", size(vsmall))


graph export "$figures/deindustrialisation_over_time.png", replace


	
// (Fig) Regional GVA per worker over time

use "$data/ardeco_regionlevel_data_all", clear
gen uk = 1 if substr(NUTS_ID, 1, 2) == "UK"
keep if uk == 1
keep if STAT_LEVL_CODE == 1
drop if missing(ROVGE)
replace NUTS_NAME = subinstr(NUTS_NAME, "(UK)", "", .)
replace NUTS_NAME = rtrim(NUTS_NAME)
gen GVA_pw = ROVGE / RNETD
encode NUTS_NAME, gen(ITL1name)
xtset ITL1name year, yearly

xtline GVA_pw, ///
	overlay ///
	legend(pos(3) col(1) all order(4 9 1 2 3 5 6 7 8 10 11 12 13)) ///
	xtitle(""off"") ///
	ytitle("Gross value added per worker,'000s EUR PPS, 2015 prices") ///
	ylabel(,nogrid nogextend) ///
	xlabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ARDECO", size(vsmall))
	
graph export "$figures/gva_pw.png", replace



// (Fig) Regional GVA per worker over time, UK disparities
use "$data/ardeco_regionlevel_data_all", clear
keep if year == 2019 & STAT_LEVL_CODE == 2
drop if missing(RUVGD_EUR)
replace NUTS_NAME = subinstr(NUTS_NAME, "(UK)", "", .)
replace NUTS_NAME = rtrim(NUTS_NAME)
drop if strpos(NUTS_NAME, "Extra") > 0

encode NUTS_NAME, gen(ITL1name)

gen country = substr(NUTS_ID, 1, 2)

gen GVA_pw_eur = RUVGD_EUR / RNETD
drop if missing(GVA_pw_eur)

egen max_GVApw = max(GVA_pw_eur), by(country)
egen min_GVApw = min(GVA_pw_eur), by(country)
gen GVA_pw_range = max_GVApw - min_GVApw
gen GVA_pw_ratio = max_GVApw / min_GVApw
drop if GVA_pw_range == 0
drop if country == "IE"

* vioplot

sencode country, gen(country_) gsort(-GVA_pw_range)

vioplot GVA_pw_eur, over(country_) ///
	ytitle("GVA per worker, 000s EUR") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ARDECO", size(vsmall))
	
graph export "$figures/gva_pw_range_vio.png", replace


collapse GVA_pw_range GVA_pw_ratio, by(country)

graph hbar GVA_pw_range, over(country, sort(1) descending) ///
	ytitle("Range of GVA per worker, 000s EUR") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ARDECO", size(vsmall))
	
graph export "$figures/gva_pw_range.png", replace


// (Fig) Regional GVA per worker over time, UK disparities, persistence

use "$data/ardeco_regionlevel_data_all", clear
keep if year == 2019 | year == 1980 
keep if STAT_LEVL_CODE == 2
drop if missing(RUVGD_EUR)
replace NUTS_NAME = subinstr(NUTS_NAME, "(UK)", "", .)
replace NUTS_NAME = rtrim(NUTS_NAME)
drop if strpos(NUTS_NAME, "Extra") > 0

encode NUTS_NAME, gen(ITL1name)

gen country = substr(NUTS_ID, 1, 2)

gen GVA_pw_eur = RUVGD_EUR / RNETD
drop if missing(GVA_pw_eur)

egen max_GVApw = max(GVA_pw_eur), by(country year)
egen min_GVApw = min(GVA_pw_eur), by(country year)
gen GVA_pw_range_1980 = max_GVApw - min_GVApw if year == 1980
gen GVA_pw_range_2019 = max_GVApw - min_GVApw if year == 2019

collapse GVA_pw_range_1980 GVA_pw_range_2019, by(country)
drop if GVA_pw_range_1980 == 0 | missing(GVA_pw_range_1980)
drop if GVA_pw_range_2019 == 0 | missing(GVA_pw_range_2019)
drop if country == "IE"

			
twoway scatter GVA_pw_range_2019 GVA_pw_range_1980 ///
	|| scatter GVA_pw_range_2019 GVA_pw_range_1980 if country == "FR", ///
		mlabel(country) ///
	|| scatter GVA_pw_range_2019 GVA_pw_range_1980 if country == "DE", ///
		mlabel(country) ///
    || scatter GVA_pw_range_2019 GVA_pw_range_1980 if country == "UK", ///
        mlabel(country) ///
		legend(off) ///
		aspectratio(1) ///
		ytitle("Range of GVA per worker, 000s EUR, 2019") ///
		yscale(range(0 80)) ytick(0(20)80) ylabel(0(20)80, nogrid) ///
		xtitle("Range of GVA per worker, 000s EUR, 1980") ///
		xscale(range(0 80)) xtick(0(20)80) xlabel(0(20)80, nogrid) ///
		plotregion(lcolor(black)) ///
		note("Source: ARDECO", size(vsmall))

	
graph export "$figures/gva_pw_range_timeseries.png", replace


// (Fig) UK agglomeration, population and GVA

* Import data from Centre for Cities, data from Rodrigues and Breach 2021)
clear
import excel "$data/CentreForCities", sheet(forstata) firstrow

* Plot population against GVA per worker
replace population = population/1000000
replace gvapw = gvapw/1000
capture drop pos
gen pos = 3
replace pos = 2 if city=="Manchester"
replace pos = 1 if city=="Newcastle"
replace pos = 4 if city=="Nottingham"
replace pos = 9 if city=="London"



local scattervars gvapw population 
twoway ///
	(scatter `scattervars'  if strpos(country,"UK")!=0 | country=="London", mlabv(pos) mlabel(city) mlabsize(vsmall) mcolor(%50)) ///
	(scatter `scattervars' if strpos(country,"France")!=0|country=="Paris", mcolor(%50)) ///
	(scatter `scattervars' if strpos(country,"Germany")!=0, mcolor(%50)) ///
	(scatter `scattervars' if strpos(country,"Italy")!=0, mcolor(%50)) ///
	(scatter `scattervars' if strpos(country,"Spain")!=0|strpos(country,"Other")!=0, mcolor(%50)) ///
	(lfit `scattervars', lcolor(midblue)) ///
	(lfit `scattervars' if country != "UK, excluding London", lcolor(cranberry)) ///
	, ///
		xsc(log) ///
		xlabel(0.5 1 2 4 6 8 10, nogextend nogrid) ///
		ylabel(, nogrid nogextend) ///
		ysc(log) ///
		legend(pos(6) row(1) order(1 "UK" 2 "France" 3 "Germany" 4 "Italy" 5 "Other Western Europe" 6 "Fit with UK" 7 "Fit without UK, excluding London") size(vsmall)) /// 
		xtitle("Population (millions, log scale)") ///
		ytitle("GVA per worker, '000 GBP PPS, 2011") ///
		plotregion(lcolor(black)) ///
		note("Source: OECD. Reproduced from Stansbury et al. (2023), originally from Rodrigues and Breach (2021).", size(vsmall))

graph export "$figures/population_gvapw.png", replace



// (Fig) City centre access, road and rail

import excel "$data/City_Center_Accessibility_Conwell_Eckert_Mobarak", firstrow clear

*Clean variables
rename Country country 
split City, p(",")
drop City2
drop City
rename City1 City

*Drop averages
drop if strpos(City, "Average")!=0

*Plot
gen pos = 3

local scattervars A_1530_C A_1530_P
local cond 
twoway ///
	(scatter `scattervars' if strpos(country,"US")==0 & strpos(country,"UK")==0 `cond', ///
		mcolor(%50)) ///
	(scatter `scattervars' if strpos(country,"US")!=0 `cond', ///
		mcolor(%50)) ///
	(scatter `scattervars'  if strpos(country,"UK")!=0 `cond', ///
		mcolor(%80) mlabel(City) mlabsize(vsmall) mlabv(pos) msize(medsmall)) ///
	, ///
		xlabel(, nogrid nogextend) ///
		ylabel(, nogrid nogextend) ///
		xtitle("Area accessible within 30 minutes by public transport, at rush hour, sq km") ///
		ytitle("Area accessible within 30 minutes by car at rush hour, sq km") ///
		legend(pos(6) cols(3) order(3 "UK" 2 "USA" 1 "Other Europe")) ///
		plotregion(lcolor(black)) ///
		note("Source: OECD. Reproduced from Stansbury et al. (2023), originally from Conwell, Eckert, and Mobarak (2022)." "Esimates computed using Google Maps data with a start time of 08:30", size(vsmall))

graph export "$figures/road_rail.png", replace


// (Fig) GFCF, ardeco 

use "$data/ardeco_regionlevel_data_all", clear 
keep if STAT_LEVL_CODE == 1
keep NUTS_ID year NUTS_NAME ROIGT RNPTN RNPTD RNETD
gen ROIGT_PC = (ROIGT / RNPTD) * 1000
keep if substr(NUTS_ID, 1, 2) == "DE" | substr(NUTS_ID, 1, 2) == "FR" | substr(NUTS_ID, 1, 2) == "UK"
drop if substr(NUTS_NAME, 1, 11) == "Extra regio"
drop if NUTS_NAME == "Extra-Regio"
drop if year == 2022

encode NUTS_NAME, gen(_NUTS_NAME)
xtset _NUTS_NAME year, yearly

keep if year>2008 & year<2020
sum ROIGT_PC
collapse ROIGT ROIGT_PC, by(NUTS_ID NUTS_NAME)
replace NUTS_NAME = subinstr(NUTS_NAME, " (UK)", "", .)
replace NUTS_NAME = subinstr(NUTS_NAME, " (IT)", "", .)
replace NUTS_NAME = subinstr(NUTS_NAME, " (ES)", "", .)


gsort ROIGT_PC 
gen ROIGT_PC_rank = [_n]
gen ROIGT_PC_UK = ROIGT_PC if substr(NUTS_ID, 1, 2) == "UK"
replace ROIGT_PC = . if !missing(ROIGT_PC_UK)

* plot
graph hbar ROIGT_PC ROIGT_PC_UK, over(NUTS_NAME, sort(ROIGT_PC_rank) descending label(angle(0) labsize(vsmall))) ///
	legend(off) ///
	yline(6.594164) ///
	ytitle("Real gross fixed capital formation per person, 2009-2019 average, '000 EUR", size(small)) ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ARDECO. UK ITL1 regions highlighted. UK, Germany and France ITL1 regions shown." "Dotted line is the EU (inc. UK) 2009-19 unweighted average.", size(vsmall))
	
graph export "$figures/ardeco_gfcf.png", replace	


// (Fig) Public investment analysis 

use consolidated_all, clear 

* Assume ITLcode variable exists and contains the region codes
gen itl1 = substr(ITLcode, 1, 3)

* Generate the region name variable using `cond()` function
gen str24 itl1name = cond(itl1 == "TLC", "North East", ///
                          cond(itl1 == "TLD", "North West", ///
                          cond(itl1 == "TLE", "Yorkshire and the Humber", ///
                          cond(itl1 == "TLF", "East Midlands", ///
                          cond(itl1 == "TLG", "West Midlands", ///
                          cond(itl1 == "TLH", "East of England", ///
                          cond(itl1 == "TLI", "London", ///
                          cond(itl1 == "TLJ", "South East", ///
                          cond(itl1 == "TLK", "South West", "")))))))))

collapse eci diversity coi, by(itl1 itl1name year)
rename itl1name region

merge m:1 region year using "$data/ons_regional_public_spending", nogen

ds year itl1 region eci diversity coi gvapc population, not
foreach var of varlist `r(varlist)' {
	gen `var'_pc_th = (`var'/population) * 1000
	replace `var' = `var'/ 1000
	rename `var' `var'_bn
} 

* gen extra vars
gen capex_growth_pc_th = capex_economic_pc_th + capex_eductraining_pc_th + capex_housing_pc_th

* plot capex by cat
graph hbar (sum) capex_econ_transport_pc_th capex_econ_ecdev_pc_th capex_econ_scitech_pc_th capex_econ_agric_pc_th capex_econ_employment_pc_th capex_defence_pc_th capex_eductraining_pc_th capex_housing_pc_th capex_health_pc_th capex_environment_pc_th capex_recculture_pc_th capex_publicorder_pc_th capex_social_pc_th if !missing(region), /// 
	ascategory ///
	yvaroptions(relabel(1 "Econ - Transport" ///
						2 "Econ - Development" ///
						3 "Econ - Science and Tech" ///
						4 "Econ - Agriculture" ///
						5 "Econ - Employment" ///
						6 "Defence" ///
						7 "Education and Training" ///
						8 "Housing" ///
						9 "Health" ///
						10 "Environment" ///
						11 "Culture" ///
						12 "Public order" ///
						13 "Social other")) ///
	ytitle("Cumulative public capital investment, per person, 1999-2019, £'000") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS - Country and Regional Analysis", size(vsmall))

graph export "$figures/public_capitalspend_area.png", replace		
	

* capex by region and cat
graph hbar (sum) capex_economic_pc_th capex_defence_pc_th capex_eductraining_pc_th capex_housing_pc_th capex_health_pc_th capex_environment_pc_th capex_recculture_pc_th capex_publicorder_pc_th capex_social_pc_th if !missing(region), over(region, sort(1) descending) stack ///
	legend(order(1 "Economic development" ///
						2 "Defence" ///
						3 "Education and Training" ///
						4 "Housing" ///
						5 "Health" ///
						6 "Environment" ///
						7 "Culture" ///
						8 "Public order" ///
						9 "Social other")) ///
	ytitle("Cumulative public capital investment, per person, 1999-2019, £'000") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS - Country and Regional Analysis. All economic development sub-categories combined.", size(vsmall))

graph export "$figures/public_capitalspend_region.png", replace	

* growth spending and ECI 
twoway scatter eci capex_growth_pc_th ///
	|| scatter eci capex_growth_pc_th if region == "London" ///
	|| lfit eci capex_growth_pc_th, ///
		legend(order(1 "All ex. London" 2 "London") ring(0)) ///
		xtitle("Growth-supporting public capital spending, per head, per year, £'000") ///
		ytitle("Economic Complexity Index") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Country and Regional Analysis." "Growth-supporting capital includes capital spending on economic development, education and training, and housing. Period covers 2015-2019.", size(vsmall))
		
graph export "$figures/public_capitalspend_eci.png", replace	




// Section 4 ================================================

// (Fig) Export, ITL1

clear
import excel using "$data/itl1_exports", firstrow cellrange(A5:D19)

drop in 13/14

graph dot TotalTradeExports2021 TotalTradeExports2018, over(Region, sort(1) descending) ///
	legend(order(1 "2021" 2 "2018") ring(0) pos(5)) ///
	marker(1, msize(large)) ///
	ytitle("Total trade exports (£ billion)") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS.", size(vsmall))

graph export "$figures/exports_itl1.png", replace


// (Fig) GFCF, ITL2

* combine the assets
clear
foreach i in 1 2 3 4 5 6 {
	clear 
	import excel using "$data/regional_gfcf19972020byassetandindustry.xlsx", sheet("`i'.2") cellrange(A4:AE928) firstrow 

	save gfcf_`i'_raw, replace	
	}

	
use gfcf_1_raw, clear 
foreach i in 2 3 4 5 6 {
	append using gfcf_`i'_raw	
	}


ds n*
foreach var of varlist `r(varlist)' {
  replace `var' = "0" if `var' == "[w]"
  replace `var' = "0" if `var' == "[low]"
  destring `var', replace
}

drop ITL1code ITL1name 
keep if SIC07industrycode == "Total"
drop SIC07industrycode SIC07industryname
reshape long n, i(ITL2name ITL2code Asset) j(year)
rename n gfcf_gbp
rename ITL2name ITLname
rename ITL2code ITLcode

replace Asset = "All" if Asset == "All assets"
replace Asset = "Buildings" if Asset == "Buildings and structures"
replace Asset = "ICT" if Asset == "ICT equipment"
replace Asset = "Intangibles" if Asset == "Intangible assets"
replace Asset = "Other_tangible" if Asset == "Other tangible assets"
replace Asset = "Transport" if Asset == "Transport equipment"


reshape wide gfcf, i(ITLname ITLcode year) j(Asset) string 

*rename vars
local vars gfcf_gbpAll gfcf_gbpBuildings gfcf_gbpICT gfcf_gbpIntangibles gfcf_gbpOther_tangible gfcf_gbpTransport

foreach var of local vars {
    * Construct the new variable name by removing the prefix
    local newvar = subinstr("`var'", "gfcf_gbp", "", .)
    
    * Rename the variable to its new name
    rename `var' `newvar'
}


* make everything in billions 
local vars All Buildings ICT Intangibles Other_tangible Transport
foreach var of local vars {
    replace `var' = `var' / 1000
}


save gfcf_graph, replace

* plot 

keep if year > 2016
collapse (sum) All Buildings ICT Intangibles Other_tangible Transport, by(ITLname)
drop if ITLname == "Extra-Regio"

graph hbar Buildings ICT Intangibles Other_tangible Transport, ///
	over(ITLname, sort(All) descending label(labsize(vsmall))) stack ///
	legend(order(1 "Buildings" 2 "ICT" 3 "Intangibles" 4 "Other tangible" 5 "Transport") size(vsmall) ring(0)) ///
	ytitle("Gross Fixed Capital Formation, £bn") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS.", size(vsmall))
	
graph export "$figures/gfcf_2017_20.png", replace




// (Fig) Employment ECI, ITL2, 2019

use subnat_employment_eci, clear

*subset the data
keep if year == 2019
collapse eci diversity employment coi, by(itl2)

* import clean labels
merge 1:1 itl2 using itl2_matching, keepusing(ITLname) nogen
encode ITLname, gen(_ITLname)

* highlight London
gsort eci
gen eci_rank = [_n]
gen eci_lond = eci if substr(itl2, 1, 1) == "I"
replace eci = . if !missing(eci_lond)

* plot
graph hbar eci eci_lond, over(ITLname, sort(eci_rank) descending label(angle(0) labsize(vsmall))) ///
	legend(off) ///
	ytitle("Economic Complexity Index") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS - Nomis. London and surrounding areas highlighted.", size(vsmall))
 
graph export "$figures/eci_emp_2019.png", replace




// (Fig) Employment ECI over time

use subnat_employment_eci, clear

* import clean labels
merge m:1 itl2 using itl2_matching, keepusing(ITLname) nogen
encode ITLname, gen(_ITLname)

* organise data for plotting
collapse eci diversity employment coi, by(ITLname _ITLname itl2 year)
gen eci_2015 = eci if year == 2015
gen eci_2022 = eci if year == 2022
collapse eci_2015 eci_2022, by(ITLname itl2)

* plot
twoway scatter eci_2015 eci_2022 ///
	|| scatter eci_2015 eci_2022 if substr(itl2, 1, 1) == "I" /// plot London 
	|| lfit eci_2015 eci_2022, ///
		legend(off) ///
		xtitle("Economic Complexity Index, 2022") ///
		ytitle("Economic Complexity Index, 2015") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. London and surrounding areas highlighted.", size(vsmall))
		

graph export "$figures/eci_emp_overtimescatter.png", replace


// (Fig) PCI employment, top and bottom 15 sectors

use subnat_employment_eci, clear

* prepare pci employment data, taking average pci 2015-2022
collapse pci, by(industry)
gen sic3 = substr(industry, 1, 3)
merge m:1 sic3 using sic3names, nogen
replace GroupName = substr(industry,7,.) if missing(GroupName)
rename GroupName sic3names

gsort -pci
gen rank = [_n]
gen pci_high = pci if rank <=15
gen pci_low = pci if rank >= 245 & rank <= 260
replace rank = . if missing(pci_high) & missing(pci_low)
gen sic3names_highlow = sic3names if !missing(pci_high) | !missing(pci_low)
replace rank = -rank

* plot

graph hbar pci_high pci_low, ///
	over(sic3names_highlow, sort(rank) descending label(labsize(vsmall))) legend(off) ///
	ytitle("Product Complexity Index", size(vsmall)) ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS - Nomis." "Plot shows top and bottom 15 ranked industries, by PCI, mean 2015-2022.", size(vsmall))

graph export "$figures/pci_emp_topbottom.png", replace




// (Fig) ECI for core cities, plus top and bottom places 

use subnat_employment_eci, clear

* import geographic labels
merge m:1 itl2 using itl2_matching, nogen
replace core_city = 0 if core_city!=1


* Core city ECI 

gsort -eci year 
gen rank = [_n]

gen eci_corecity = eci if core_city==1 
gen eci_excorecity = eci if core_city==0

* create label to graph over 
gen corecity_andhighlow = ITLname
replace corecity_andhighlow = core_city_name if core_city == 1

graph hbar eci_excorecity eci_corecity if eci>1.75 | eci<-0.5 | core_city==1, over(corecity_andhighlow, sort(rank) label(angle(0) labsize(vsmall))) ///
	nofill ///
	legend(off) ///
	ytitle("Economic Complexity Index, 2015-2022 average ") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS - Nomis." "Plot shows regions with ECI > 1.75, < -0.5, and the Core Cities (highlighted).", size(vsmall))

graph export "$figures/eci_emp_topbottom_corecity.png", replace


// (Fig) RCA and ECI

use subnat_employment_eci, clear

replace itl2 = "Inner London East" if itl2 == "I4InnerLondonEast"
replace itl2 = "Inner London West" if itl2 == "I3InnerLondonWest"
replace itl2 = "West Wales" if itl2 == "L1WestWales"

twoway scatter eci diversity ///
	|| scatter eci diversity if itl2 == "Inner London East" | itl2 == "Inner London West" ///
	|| scatter eci diversity if itl2 == "West Wales", mcolor(red) ///
    || lfit eci diversity, ///
		legend(order(2 "Inner London" 3 "West Wales") ring(0) pos(2) col(1)) ///
        ytitle("Economic Complexity Index, 2015-2022", size(small)) ///
        xtitle("Diversity, by ITL2 region and year", size(small)) ///
        ylabel(,nogrid nogextend) ///
        xlabel(,nogrid nogextend) ///
        plotregion(lcolor(black)) ///
    note("Source: ONS - Nomis", size(vsmall))
	
graph export "$figures/eci_rca.png", replace

// (Fig) ECI employment relationship with key outcome variables 

use consolidated_all, clear

merge m:1 ITLcode using itl2_matching, nogen keepusing(core_city_lond_name core_city_name core_city london london_se)

* GVA per job
twoway scatter ln_gva_pj_gbp eci ///
	|| scatter ln_gva_pj_gbp eci if !missing(core_city) ///
	|| scatter ln_gva_pj_gbp eci if !missing(london) ///
	|| lfit ln_gva_pj_gbp eci, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GVA per job") ///
		ytitle("Log GVA per job", size(small)) ///
		xtitle("ECI, 2015-2022", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gva_pj", replace)
	
* GVA per hour
twoway scatter ln_gva_ph_gbp eci ///
	|| scatter ln_gva_ph_gbp eci if !missing(core_city) ///
	|| scatter ln_gva_ph_gbp eci if !missing(london) ///
	|| lfit ln_gva_ph_gbp eci, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GVA per hour") ///
		ytitle("Log GVA per hour", size(small)) ///
		xtitle("ECI, 2015-2022", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gva_ph", replace)
	
* GHDI per person
twoway scatter ln_gdhi_pp_gbp eci ///
	|| scatter ln_gdhi_pp_gbp eci if !missing(core_city) ///
	|| scatter ln_gdhi_pp_gbp eci if !missing(london) ///
	|| lfit ln_gdhi_pp_gbp eci, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GHDI per person") ///
		ytitle("Log GDHI per person", size(small)) ///
		xtitle("ECI, 2015-2022", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gdhi_pp", replace)
	
* GDP per capita
twoway scatter ln_gdp_pc_gbp eci ///
	|| scatter ln_gdp_pc_gbp eci if !missing(core_city) ///
	|| scatter ln_gdp_pc_gbp eci if !missing(london) ///
	|| lfit ln_gdp_pc_gbp eci, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GDP per capita") ///
		ytitle("Log GDP per capita", size(small)) ///
		xtitle("ECI, 2015-2022", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS and HMRC. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gdppc", replace)
		
graph combine eci_gva_pj.gph eci_gva_ph.gph eci_gdhi_pp.gph eci_gdppc.gph

graph export "$figures/eci_associations.png", replace



// (Fig) ECI export relationship with key outcome cariables 

use consolidated_all, clear

merge m:1 ITLcode using itl2_matching, nogen keepusing(core_city_lond_name core_city_name core_city london london_se)

* GVA per job
twoway scatter ln_gva_pj_gbp eci_exports ///
	|| scatter ln_gva_pj_gbp eci_exports if !missing(core_city) ///
	|| scatter ln_gva_pj_gbp eci_exports if !missing(london) ///
	|| lfit ln_gva_pj_gbp eci_exports, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GVA per job") ///
		ytitle("Log GVA per job", size(small)) ///
		xtitle("ECI (exports), 2019-2021", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gva_pj_exports", replace)
	
* GVA per hour
twoway scatter ln_gva_ph_gbp eci_exports ///
	|| scatter ln_gva_ph_gbp eci_exports if !missing(core_city) ///
	|| scatter ln_gva_ph_gbp eci_exports if !missing(london) ///
	|| lfit ln_gva_ph_gbp eci_exports, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GVA per hour") ///
		ytitle("Log GVA per hour", size(small)) ///
		xtitle("ECI (exports), 2019-2021", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gva_ph_exports", replace)
	
* GHDI per person
twoway scatter ln_gdhi_pp_gbp eci_exports ///
	|| scatter ln_gdhi_pp_gbp eci_exports if !missing(core_city) ///
	|| scatter ln_gdhi_pp_gbp eci_exports if !missing(london) ///
	|| lfit ln_gdhi_pp_gbp eci_exports, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GHDI per person") ///
		ytitle("Log GDHI per person", size(small)) ///
		xtitle("ECI (exports), 2019-2021", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gdhi_pp_exports", replace)
	
* GDP per capita
twoway scatter ln_gdp_pc_gbp eci_exports ///
	|| scatter ln_gdp_pc_gbp eci_exports if !missing(core_city) ///
	|| scatter ln_gdp_pc_gbp eci_exports if !missing(london) ///
	|| lfit ln_gdp_pc_gbp eci, ///
		legend(pos(6) row(1) order(2 "Core Cities" 3 "London" 1 "Other") ring(0)) ///
		subtitle("GDP per capita") ///
		ytitle("Log GDP per capita", size(small)) ///
		xtitle("ECI (exports), 2019-2021", size(small)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS and OECD. Each observation is at year-ITL2 level.", size(vsmall)) ///
		saving("eci_gdppc_exports", replace)
		
graph combine eci_gva_pj_exports.gph eci_gva_ph_exports.gph eci_gdhi_pp_exports.gph eci_gdppc_exports.gph

graph export "$figures/eci_associations_exports.png", replace



// (Fig) Sectoral distances for key places, identifying sectoral opportunities, 2019

use subnat_employment_eci, clear

* import geographic labels
merge m:1 itl2 using itl2_matching, nogen
replace core_city = 0 if core_city!=1

* import sector labels
gen sic3 = substr(industry, 1, 3)
merge m:1 sic3 using sic3names, nogen
replace GroupName = substr(industry,7,.) if missing(GroupName)
rename GroupName sic3names

* create label to graph over 
gen corecity_andhighlow = ITLname
replace corecity_andhighlow = core_city_name if core_city == 1

* create a dynamic distance measure 
gen distance_core_city = distance if core_city == 1
egen distance_core_city_pc25 = pctile(distance_core_city), p(50) by(core_city_name year)


* plot for each place 2019

keep if year == 2019

levelsof core_city_name, local(core_cities)

foreach level of local core_cities {
	twoway scatter pci distance if core_city_name=="`level'" & rca>=1 ///
	|| scatter pci distance if core_city_name=="`level'" & rca<1 ///
	|| scatter pci distance if core_city_name=="`level'"  & rca<1 & high_pci==1 & distance<distance_core_city_pc25, ///
		mlabel(sic3names) ///
		mlabsize(tiny) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(1 "Current strengths" 2 "Not strengths" 3 "Opportunities") ///
			position(11) col(1) ring(0) size(vsmall) keygap(1) fcolor(none) lcolor(none)) ///
		subtitle("`level'", size(medium)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. Distance = 1/Density." "Opportunities are sectors with PCI > 1 and Distance < 50 percentile of area-year distances but RCA < 1", size(vsmall)) 
	
	graph export "$figures/city_opps_`level'.png", replace
}

* generate specific plots for city, based on different opportunity parameters

* Manchester

gen sic_label_manc = sic3names if ///
	industry == "631 : Data processing, hosting and related activities; web portals" | ///
	industry == "639 : Other information service activities" | ///
	industry == "620 : Computer programming, consultancy and related activities" | ///
	industry == "741 : Specialised design activities" 

twoway scatter pci distance if core_city_name=="Manchester" & rca>=1 ///
	|| scatter pci distance if core_city_name=="Manchester" & rca<1 ///
	|| scatter pci distance if core_city_name=="Manchester"  & rca<1 & pci>3 & distance<distance_core_city_pc25, ///
		jitter(2) ///
		mlabel(sic_label_manc) ///
		mlabsize(vsmall) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(1 "Current strengths" 2 "Not strengths" 3 "Opportunities") ///
			position(11) col(1) ring(0) size(vsmall) keygap(1) fcolor(none) lcolor(none)) ///
		subtitle("`level'", size(medium)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. Distance = 1/Density." "Opportunities are sectors with PCI > 3 and Distance < 50 percentile of area-year distances but RCA < 1", size(vsmall)) 
	
graph export "$figures/city_opps_Manchester.png", replace


* Newcastle

gen sic_label_newc = sic3names if ///
	industry == "691 : Legal activities" | ///
	industry == "649 : Other financial service activities, except insurance and pension funding" | ///
	industry == "652 : Reinsurance" | ///
	industry == "663 : Fund management activities" 

twoway scatter pci distance if core_city_name=="Newcastle" & rca>=1, ///
		mlabel(sic_label_newc) ///
		mlabsize(vsmall) ///
	|| scatter pci distance if core_city_name=="Newcastle" & rca<1 ///
	|| scatter pci distance if core_city_name=="Newcastle"  & rca<1 & pci>2.5 & distance<3, ///
		jitter(2) ///
		mlabel(sic_label_newc) ///
		mlabsize(vsmall) ///
		mlabp(9) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(1 "Current strengths" 2 "Not strengths" 3 "Opportunities") ///
			position(11) col(1) ring(0) size(vsmall) keygap(1) fcolor(none) lcolor(none)) ///
		subtitle("`level'", size(medium)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. Distance = 1/Density." "Opportunities are sectors with PCI > 2.5 and Distance < 3 but RCA < 1", size(vsmall)) 
	
graph export "$figures/city_opps_Newcastle.png", replace


* Liverpool

gen sic_label_liv = sic3names if ///
	industry == "268 : Manufacture of magnetic and optical media" | ///
	industry == "612 : Wireless telecommunications activities" | ///
	industry == "474 : Retail sale of information and communication equipment in specialised stores" | ///
	industry == "611 : Wired telecommunications activities" | ///
	industry == "592 : Sound recording and music publishing activities" | ///
	industry == "900 : Creative, arts and entertainment activities" | ///
	industry == "182 : Reproduction of recorded media" 

twoway scatter pci distance if core_city_name=="Liverpool" & rca>=1, ///
		mlabel(sic_label_liv) ///
		mlabsize(vsmall) ///
	|| scatter pci distance if core_city_name=="Liverpool" & rca<1 ///
	|| scatter pci distance if core_city_name=="Liverpool"  & rca<1 & pci>2 & distance<3.5, ///
		jitter(2) ///
		mlabel(sic_label_liv) ///
		mlabsize(vsmall) ///
		mlabp(3) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(1 "Current strengths" 2 "Not strengths" 3 "Opportunities") ///
			position(11) col(1) ring(0) size(vsmall) keygap(1) fcolor(none) lcolor(none)) ///
		subtitle("`level'", size(medium)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. Distance = 1/Density." "Opportunities are sectors with PCI > 2 and Distance < 3.5 but RCA < 1", size(vsmall)) 
	
graph export "$figures/city_opps_Liverpool.png", replace


// London version

* limit to London
keep if london == 1
collapse pci distance rca high_pci, by(sic3names)

* plot 
twoway scatter pci distance if rca>=1 ///
	|| scatter pci distance if rca<1 ///
	|| scatter pci distance if rca<1 & high_pci==1 & distance<3.5, ///
		mlabel(sic3names) ///
		mlabsize(tiny) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(1 "Current strengths" 2 "Not strengths" 3 "Opportunities") ///
			position(11) col(1) ring(0) size(vsmall) keygap(1) fcolor(none) lcolor(none)) ///
		subtitle("London", size(medium)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. Distance = 1/Density." "Opportunities are sectors with PCI > 1 and Distance < 3.5 but RCA < 1", size(vsmall)) 
		
graph export "$figures/city_opps_London.png", replace



// (Fig) Sectoral distances for key places, identifying sectoral opportunities, economic shape

use subnat_employment_eci, clear

* import geographic labels
merge m:1 itl2 using itl2_matching, nogen
replace core_city = 0 if core_city!=1

* import sector labels
gen sic3 = substr(industry, 1, 3)
merge m:1 sic3 using sic3names, nogen
replace GroupName = substr(industry,7,.) if missing(GroupName)
rename GroupName sic3names

* create label to graph over 
gen corecity_andhighlow = ITLname
replace corecity_andhighlow = core_city_name if core_city == 1

* plot for different economy types: Inner London - West, Manchester, Sheffield, Glasgow

keep if year == 2019

gen city_type = ITLname if ///
	ITLname == "Inner London - West"  ///

replace city_type = core_city_name if ///
	ITLname == "Greater Manchester" | ///
	ITLname == "West Central Scotland" | ///
	ITLname == "South Yorkshire"

levelsof city_type, local(city_type)

foreach level of local city_type {
	twoway scatter pci distance if city_type=="`level'" & rca>=1 ///
	|| scatter pci distance if city_type=="`level'" & rca<1 ///
	|| qfit pci distance if city_type=="`level'" ///
	, ///
		mlabel(sic3names) ///
		mlabsize(tiny) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(1 "Current strengths" 2 "Not strengths") ///
			position(11) col(1) ring(0) size(vsmall) keygap(1) fcolor(none) lcolor(none)) ///
		subtitle("`level'", size(medium)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		saving("citytype_`level'", replace)
}

graph combine "citytype_Inner London - West.gph" "citytype_Sheffield.gph" "citytype_Glasgow City.gph" "citytype_Manchester.gph", ///
	note("Source: ONS - Nomis. Strengths are sectors where the place has an RCA > 1.", size(vsmall))

graph export "$figures/city_econtypes.png", replace


// (Fig) COI, how many good sectors are near you

use consolidated_all, clear 

*prepare the data
keep if year == 2019

* import geographic labels
merge m:1 ITLcode using itl2_matching, nogen
replace core_city = 0 if core_city!=1

* create label to graph over 
gen corecity_andhighlow = ITLname
replace corecity_andhighlow = core_city_name if core_city == 1


gen city_type = ITLname if ///
	ITLname == "Inner London - West"  ///

replace city_type = core_city_name if ///
	ITLname == "Greater Manchester" | ///
	ITLname == "West Central Scotland" | ///
	ITLname == "South Yorkshire"

gen pos = 9
replace pos = 3 if core_city_name == "Birmingham"
replace pos = 2 if london == 1
replace pos = 9 if core_city_lond_name == "Inner London - West" | core_city_lond_name == "Inner London - East"

* plot
twoway scatter coi gva_ph_gbp ///
	|| lfit coi gva_ph_gbp ///
	|| scatter coi gva_ph_gbp if london == 1, mlabel(core_city_lond_name) mlabv(pos) ///
	|| scatter coi gva_ph_gbp if core_city == 1, mlabel(core_city_name) mlabv(pos) ///
		legend(off) ///
		xtitle("GVA per hour, £'000") ///
		ytitle("Complexity Outlook Index") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. London and Core Cities highlighted.", size(vsmall)) 

graph export "$figures/city_coi.png", replace	


// (Fig) OOG, high value sectors to target

use subnat_employment_eci, clear

* import geographic labels
merge m:1 itl2 using itl2_matching, nogen
replace core_city = 0 if core_city!=1

* import sector labels
gen sic3 = substr(industry, 1, 3)
merge m:1 sic3 using sic3names, nogen
replace GroupName = substr(industry,7,.) if missing(GroupName)
rename GroupName sic3names

* create label to graph over 
gen corecity_andhighlow = ITLname
replace corecity_andhighlow = core_city_name if core_city == 1

* pick cities to examine

gen city_type = ITLname if ///
	ITLname == "Inner London - West"  ///

replace city_type = core_city_name if ///
	ITLname == "Greater Manchester" | ///
	ITLname == "West Central Scotland" | ///
	ITLname == "South Yorkshire"

* create labels for opportunity sectors 

gen glas_sectors = sic3names if ///
	industry == "244 : Manufacture of basic precious and other non-ferrous metals" | ///
	industry == "252 : Manufacture of tanks, reservoirs and containers of metal" | ///
	industry == "241 : Manufacture of basic iron and steel and of ferro-alloys"

gen pos = 9
replace pos = 6 if industry == "252 : Manufacture of tanks, reservoirs and containers of metal"
	
keep if year == 2019	
	
	
* plot for glasgow

twoway scatter pci distance if city_type=="Glasgow City" ///
	|| scatter pci distance if city_type=="Glasgow City" & cog>=0.3 ///
	|| scatter pci distance if city_type=="Glasgow City" & cog>=0.3 & !missing(glas_sectors) ///
	, ///
		mlabel(glas_sectors) ///
		mlabsize(small) ///
		mlabv(pos) ///
		ytitle("Product Complexity Index, 2019", size(small)) ///
		xtitle("Sectoral 'distance'", size(small)) ///
		legend(order(2 "Opportunities") ///
			position(11) col(1) ring(0) size(small) keygap(1) fcolor(none) lcolor(none)) ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Nomis. Opportunities are sectors with COG > .5.", size(vsmall))


graph export "$figures/city_glasgow_cog.png", replace



// (Fig) NIPO

use "$data/nipo", clear 

* prepare the data
gen hs4 = substr(ProductHS6digit2012, 1, 4)
gen hs3 = substr(ProductHS6digit2012, 1, 3)
merge m:m hs4 using hs_sic_mapping, keepusing(sic3) nogen
merge m:m sic3 using sic3names, nogen
drop if missing(EntryID)
drop if missing(SizeofsubsidyUSDmillion)

* cumulative plot
gsort Implementationdate EntryID
gen order = [_n]
gsort order
gen total_overtime = SizeofsubsidyUSDmillion
replace total_overtime=total_overtime[_n] + total_overtime[_n-1] if _n>1
replace total_overtime = total_overtime/1000
format Implementationdate %tdMon_CCYY

gsort order
twoway line total_overtime Implementationdate if Implementationdate < date("01nov2023", "DMY") ///
	|| 	dot total_overtime Implementationdate if EntryID == 123050 ///
		, ///
		mlabel(Jurisdiction) ///
		yline(2372, lcolor(red)) ///
		ylabel(2372, add) ///
		legend(off) ///
		ytitle("Cumulative subsidy size (USD billion)") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: New Industrial Policy Observatory (NIPO).", size(vsmall)) 

graph export "$figures/nipo.png", replace



// (Fig) VMPK

clear
import delimited using "$data/martin_gfcf_itl1.csv", varnames(1)

* construct stock
gen real_gfcf_cp = gfcf_cp / (gfcf_deflator/100)
keep if asset == "Total"
keep if sic07 == "Total"
gsort itl1code year
gsort itl1code year

bysort itl1code (year) : gen cap_stock = sum(real_gfcf_cp)

replace itl1name = subinstr(itl1name, " (England)", "", .)
replace itl1name = "East of England" if itl1name == "East"
replace itl1name = "Yorkshire and the Humber" if itl1name == "Yorkshire and The Humber"
rename itl1code ITLcode 
rename itl1name ITLname
drop sic07 asset

save cap_stock_itl1, replace

* grab fdi series 

clear
import excel using "$data/20230419FDIsubnatinwardtables.xlsx", sheet("1.1 ITL1 flow") cellrange(A4:J186) firstrow 

ds n*
foreach var of varlist `r(varlist)' {
  replace `var' = "0" if `var' == "c" | `var' == "low"
  destring `var', replace
}

keep if Measure == "Total net FDI flows in the UK"
drop Measure 
reshape long n, i(Regionname ITL1code) j(year)
rename n fdi_flow
replace Regionname = subinstr(Regionname, " (England)", "", .)
replace Regionname = "East of England" if Regionname == "East"
replace Regionname = "Yorkshire and the Humber" if Regionname == "Yorkshire and The Humber"
rename Regionname ITLname
rename ITL1code ITLcode


save fdi_flow_itl1, replace


use "$data/ons_regional_public_spending", clear

rename region ITLname
merge 1:1 ITLname year using cap_stock_itl1, nogen
merge 1:1 ITLcode year using fdi_flow_itl1, nogen 

* construct VMPK
gen cap_stockpc = cap_stock / population

gen alpha = 0.3
gen VMPK = alpha * (gvapc/cap_stock) 
gen lnVMPK = ln(VMPK)
gen lnGVAPC = ln(gvapc)
gen lnCAPEX = ln(capex_total)
gen lnGFCF = ln(real_gfcf_cp)
gen lnFDI = ln(fdi_flow)

* public capex
twoway scatter lnVMPK lnCAPEX if year>2009 ///
	|| scatter lnVMPK lnCAPEX if ITLname == "London" & year>2009 ///
	|| lfit lnVMPK lnCAPEX if year>2009 ///
	|| lfit lnVMPK lnCAPEX if ITLname != "London" & year>2009, ///
		legend(order(1 "All ex. London" 4 "All ex. London fit" 2 "London" 3 "All fit")) ///
		xtitle(" Log public capital expenditure") ///
		ytitle("Log VMPK") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Country and Regional Analysis.", size(vsmall))
		
graph export "$figures/vmpk_publicinvest.png", replace	


* gfcf
twoway scatter lnVMPK lnGFCF if year>2009 ///
	|| scatter lnVMPK lnGFCF if ITLname == "London" & year>2009 ///
	|| lfit lnVMPK lnGFCF if year>2009 ///
	|| lfit lnVMPK lnGFCF if ITLname != "London" & year>2009, ///
		legend(order(1 "All ex. London" 4 "All ex. London fit" 2 "London" 3 "All fit")) ///
		xtitle(" Log Gross Fixed Capital Formation") ///
		ytitle("Log VMPK") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Country and Regional Analysis.", size(vsmall))
		
graph export "$figures/vmpk_gfcf.png", replace	
	
* fdi
twoway scatter lnVMPK lnFDI if year>2009 ///
	|| scatter lnVMPK lnFDI if ITLname == "London" & year>2009 ///
	|| lfit lnVMPK lnFDI if year>2009 ///
	|| lfit lnVMPK lnFDI if ITLname != "London" & year>2009, ///
		legend(order(1 "All ex. London" 4 "All ex. London fit" 2 "London" 3 "All fit")) ///
		xtitle(" Log Gross inward Foreign Direct Investment") ///
		ytitle("Log VMPK") ///
		ylabel(,nogrid nogextend) ///
		xlabel(,nogrid nogextend) /// 
		plotregion(lcolor(black)) ///
		note("Source: ONS - Country and Regional Analysis.", size(vsmall))
		
graph export "$figures/vmpk_fdi.png", replace	


	
// appendix figs 


// (Fig) GERD 

use consolidated_all, clear 

graph hbar gerd_business gerd_gov gerd_he gerd_non_profit if year==2019, ///
	over(ITLname, sort(1) descending label(labsize(vsmall))) stack ///
	legend(order(1 "Business GERD" 2 "Govt. GERD" 3 "HE GERD" 4 "Non-profit GERD") ring(0)) ///
	ytitle("Gross domestic expenditure on research and development, £m") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS. Data shown for 2019.")
	
	
graph export "$figures/gerd_itl2.png", replace	


// (Fig) Share of tertiary

use consolidated_all, clear 

graph hbar sh_tertiary if year==2019, ///
	over(ITLname, sort(1) descending label(labsize(vsmall))) ///
	nofill ///
	ytitle("Share of the working population with at least tertiary education") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS. Data shown for 2019.")
	
	
graph export "$figures/tertiary_itl2.png", replace	
	

// (Fig) Capital stock
	
graph hbar cap_stock if year==2019, ///
	over(ITLname, sort(1) descending label(labsize(vsmall))) ///
	nofill ///
	ytitle("Capital stock, per head, £") ///
	ylabel(,nogrid nogextend) ///
	plotregion(lcolor(black)) ///
	note("Source: ONS. Data shown for 2019.")
	
	
graph export "$figures/capstock_itl2.png", replace	


// (Fig) ECI employment and ECI exports 

twoway scatter std_eci std_eci_exports ///
	|| lfit std_eci std_eci_exports, ///
		ytitle("ECI employment") ///
		xtitle("ECI export") ///
		xlabel(,nogrid nogextend) ///
		ylabel(,nogrid nogextend) ///
		plotregion(lcolor(black)) ///
		aspectratio(1) ///
		legend(off) ///
		note("Source: ONS.")
	
graph export "$figures/eci_comp.png", replace		
