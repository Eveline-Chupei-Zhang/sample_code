*---------------------------------------------------------------------------------------------------------*
*                                 distribution of state-level specialization measures
*                                              Eveline Chupei Zhang
*---------------------------------------------------------------------------------------------------------*



* import dataset
use "input_dataset1.dta", clear
append using "input_dataset2.dta"



* favorite state indicator
bys year lei: egen double max_XS_bts=max(XS_bts)
gen f_state=1 if XS_bts==max_XS_bts
replace f_state=0 if missing(f_state)
  
* favorite state specialization
sort year lei f_state
gen double spec3_f_state=XS_bts if f_state==1

* all other states specialization
gen double spec3_o_state=XS_bts if f_state==0



preserve



* banks and nonbanks
* favorite state 
sum spec3_f_state if depository==1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)
sum spec3_f_state if depository==0
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)
local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')
local bins = 45
local width = (`max'-`min')/`bins'

* histogram of favorite state 
twoway (hist spec3_f_state if depository==1, percent start(`min') width(`width') fcolor(black%45) lcolor(black) lwidth(0.5pt)) ///
       (hist spec3_f_state if depository==0, percent start(`min') width(`width') fcolor(maroon%55) lcolor(black) lwidth(0.5pt) legend(order(1 "Bank" 2 "Non-bank") size(small)) xtitle(Excess specialization for banks and non-banks in the favorite state) graphregion(color(white)) yla(, labsize(small)))

graph save "Graph" "/fig2_v3/output/favorite_state/fig2_b_nb_fstate.gph", replace

graph export "fig2_b_nb_fstate.pdf",replace


* * histogram  of all other states
hist_overlay spec3_o_state, frac over(depository) color2(black%45) color1(maroon%55) xtitle(Excess specialization for banks and non-banks in all other states) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) yscale(r(0 0.41)) legend(order(2 "Bank" 1 "Non-bank") size(small)) bin(50)

graph save "Graph" "/fig2_v3/output/all_other_states/fig2_b_nb_otherstate.gph", replace

graph export "fig2_b_nb_otherstate.pdf",replace










* large banks and Small banks
keep if depository==1

gen large_bank=1 if total_assets>=5.0e+10
replace large_bank=0 if missing(large_bank)

* favorite state 
hist_overlay spec3_f_state, frac over(large_bank) color1(maroon%55) color2(black%45) xtitle(Excess specialization for large banks and small banks in the favorite state) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) yscale(r(0 0.21)) legend(order(2 "Bank" 1 "Non-bank") size(small)) bin(50)

graph save "Graph" "/fig2_v3/output/favorite_state/fig2_lb_sb_fstate.gph", replace

graph export "fig2_lb_sb_fstate.pdf",replace



* all other states
hist_overlay spec3_o_state, frac over(large_bank) color1(maroon%55) color2(black%45) xtitle(Excess specialization for large banks and small banks in all other states) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) legend(size(small)) bin(50)


graph save "Graph" "/fig2_v3/output/all_other_states/fig2_lb_sb_otherstate", replace

graph export "fig2_lb_sb_otherstate.pdf",replace










* Large nonbank and small nonbank
restore

preserve

keep if depository==0

gen large_nonbank=1 if L_bt>=7.0e+09
replace large_nonbank=0 if missing(large_nonbank)


* favorite state 
hist_overlay spec3_f_state, frac over(large_nonbank) color2(navy%50) color1(black%45) xtitle(Excess specialization for large non-banks and small non-banks in the favorite state) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) legend(size(small)) bin(50) yscale(r(0 0.16))

graph save "Graph" "/fig2_v3/output/favorite_state/fig2_lnb_snb_fstate.gph", replace

graph export "fig2_lnb_snb_fstate.pdf",replace




* all other states
hist_overlay spec3_o_state, frac over(large_nonbank) color2(navy%50) color1(black%45) xtitle(Excess specialization for large non-banks and small non-banks in all other states) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) legend(size(small)) bin(50) yscale(r(0 0.615))


graph save "Graph" "/fig2_v3/output/favorite_state/fig2_lnb_snb_otherstate.gph", replace

graph export "fig2_lnb_snb_otherstate.pdf",replace










* fintech and nonfintech nonbanks 
drop large_nonbank

merge m:1 respondent_rssd using "/Users/chupei.zhang/Dropbox/URAP_Matteo/Fintech_Bank-nonbank_lending/summary_stat/StateLevel_spec3_ByLenderGroup/input_dataset/fintech_classification.dta"

replace fintech=1 if respondent_name=="GUARANTEED RATE AFFINITY, LLC"
replace fintech=0 if missing(fintech)

mdesc XS_bts respondent_name
list lei respondent_rssd respondent_name XS_bts state2 _merge if missing(respondent_name)


drop if missing(XS_bts)
drop name _merge


* favorite state 
hist_overlay spec3_f_state, frac over(fintech) color2(navy%50) color1(black%45) xtitle(Excess specialization for fintech and non-fintech non-banks in the favorite state) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) legend(size(small)) bin(50) ysc(r(0 0.16))

graph save "Graph" "/fig2_v3/output/favorite_state/fig2_f_nf_fstate.gph", replace

graph export "fig2_f_nf_fstate.pdf",replace




* all other states
hist_overlay spec3_o_state, frac over(fintech) color2(navy%50) color1(black%45) xtitle(Excess specialization for fintech and non-fintech non-banks in all other states) ytitle(Percent) graphregion(color(white)) yla(, labsize(small)) yscale(r(0 0.42)) legend(size(small)) bin(50) ysc(r(0 0.61))


graph save "Graph" "/fig2_v3/output/all_other_states/fig2_f_nf_otherstate.gph", replace

graph export "fig2_f_nf_otherstate.pdf",replace




                                                           
