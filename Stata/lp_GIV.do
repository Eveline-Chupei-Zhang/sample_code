*****************************************************************************************
*********************************** LP-GIV estimate *************************************
*******************************  Eveline Chupei Zhang  **********************************
*****************************************************************************************

clear all
set more off
global root "/Chupei_GIV/"
cd "$root"

foreach xxx in "presetting"{
global GFC_name "Global Financial Cycle"
global VIX_name "VIX"
global GLBIF_name "Global Inflow"
global GLBDCRT_name "Global Credit"
global UNC_name "Global Uncertainty"
global MSCI_name "MSCI Global"
global PCM_name "Commodity Price"
global FFR_name "Federal Funds Rate"
global GIVBank_name "Global Bank Idiosyncratic Shock"
global IP_name "US Industrial Production"
global PCE_name "US PCE"
global TS_name "US Term Spread"
global LEVUS_name "US Broker & Dealer Leverage"
global GLBIP_name "World Industrial Production"
global EBP_name "Excess Bond Premium"

global hor 20 
global ci1 90 
global ci2 68

global lags 8
}
global vars "IP PCE TS PCM EBP FFR LEVUS GFC GLBIP" // GIVBank


use LeverageFactor,replace
gen mdate=ym(year(dofq(qdate)),1) if quarter(dofq(qdate))==1
replace mdate=ym(year(dofq(qdate)),4) if quarter(dofq(qdate))==2
replace mdate=ym(year(dofq(qdate)),7) if quarter(dofq(qdate))==3
replace mdate=ym(year(dofq(qdate)),10) if quarter(dofq(qdate))==4
append using TempFiles/LeverageFactorv2
replace ZT=. if mdate==.
replace mdate=ym(year(dofq(qdate)),3) if quarter(dofq(qdate))==1 & mdate==.
replace mdate=ym(year(dofq(qdate)),6) if quarter(dofq(qdate))==2 & mdate==.
replace mdate=ym(year(dofq(qdate)),9) if quarter(dofq(qdate))==3 & mdate==.
replace mdate=ym(year(dofq(qdate)),12) if quarter(dofq(qdate))==4 & mdate==.
tsset mdate,m
tsfill
ipolate ZT mdate,gen(ipo)
keep mdate ipo
rename ipo ZT
save TempFiles/ZT,replace



import excel using bpssGFC_GIV.xlsx,firstrow clear
gen date=date(Date,"YMD"),a(Date)
gen mdate=mofd(date),a(date)
egen rowmiss=rowmiss($vars )
keep if rowmiss==0
tsset mdate,m
merge 1:1 mdate using TempFiles/ZT


global contrls ""
foreach vv in $vars{
	global contrls "$contrls L(1/$lags).`vv'"
}

tsset mdate,m


gen horizon=_n-1 if _n<=$hor +1

foreach v in $vars{
	foreach esm in iv ols{
		foreach xxm in _b u1 u2 l1 l2{
			qui gen `v'`xxm'`esm'=.
		}
	}
	forv h=0/$hor{
		local kn = `h'+1
		qui gen yy=f`h'.`v'
		qui newey yy GIVBank $contrls ,lag(`kn') force
		qui ereturn display,level($ci1 )
		qui matrix results1 = r(table)
		qui replace `v'_bols= results1[1,1] if horizon==`h'
		qui replace `v'l1ols= results1[5,1] if horizon==`h'
		qui replace `v'u1ols= results1[6,1] if horizon==`h' 
		
		qui ereturn display, level($ci2 ) 
		qui matrix results1 = r(table)
		qui replace `v'l2ols= results1[5,1] if horizon==`h'
		qui replace `v'u2ols= results1[6,1] if horizon==`h'
		
		qui ivreg2 yy (GIVBank=ZT) $contrls //,gmm2s kernel(bar) robust bw(`kn')
		qui ereturn display,level($ci1 )
		qui matrix results1 = r(table)
		qui replace `v'_biv= results1[1,1] if horizon==`h'
		qui replace `v'l1iv= results1[5,1] if horizon==`h'
		qui replace `v'u1iv= results1[6,1] if horizon==`h' 
		
		qui ereturn display, level($ci2 ) 
		qui matrix results1 = r(table)
		qui replace `v'l2iv= results1[5,1] if horizon==`h'
		qui replace `v'u2iv= results1[6,1] if horizon==`h'
		drop yy
	}
}


qui cap gen zero=0 
qui keep if horizon != .
save TempFiles/LPGIV,replace
 use TempFiles/LPGIV,replace
keep if horizon<=10
foreach v in $vars{
// 	foreach xxm in _b u1 l1 u2 l2{
// 		foreach tt in ols iv{
// 			qui su GFC`xxm'`tt' if horizon==0
// 			qui replace `v'`xxm'`tt'=`v'`xxm'`tt'/r(mean)
// 		}
// 	}
	 tw (rarea `v'u2ols `v'l2ols horizon,fc(blue%30) lc(blue%10)) ///
	    (line `v'_bols  horizon,lc(blue) lw(medthick)) ///
		(line zero horizon,lc(black) lw(thin)) /// ,siz(30pt)
		,xti("") ti("$`v'_name",c(black)) leg(off) /// siz(40pt)
		plotr(c(white)) graphr(c(white)) name(`v',replace) //ylab(,labsiz(40pt))
}
gr combine $vars , plotr(c(white)) graphr(c(white)) imargin(zero) c(3)
gr export Graphics/LPGIV.png,replace width(1800)


		(rarea `v'u2iv `v'l2iv horizon,fc(red%30) lc(red%10)) ///
	    (line `v'_biv  horizon,lc(red) lw(medthick)) ///




