********************************************
* Datos asegurados - IMSS base restringida *
********************************************
clear all
set more off
set scheme s2mono

cd "D:\Research\Informality_IMSS"
global imss_data = "D:\database\IMSS_asegurados"
global data      = "D:\Research\Informality_IMSS\DTA"
global figures   = "D:\Research\Informality_IMSS\Figures"
global varios	 = "D:\Research\Informality_IMSS\DTA\varios"

forvalues i = 2005/2017{
forvalues j = 1/11{ // hasta mes 11

quietly use "$data\\`i'_`j'.dta", clear

quietly order year month cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion rango_edad sexo tamaño_patron 

quietly label drop cve_entidad	
quietly gen entidad = string(cve_entidad)
quietly tostring year, replace
quietly tostring month, replace
quietly tostring cve_entidad, replace

quietly gen id = year + month + entidad + cve_municipio
	
quietly keep year month cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion rango_edad sexo tamaño_patron tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc municipio norte entidad id sector_economico_1
	
quietly order id sexo rango_edad tamaño_patron norte tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc year month entidad cve_municipio

quietly sort id sexo rango_edad tamaño_patron norte tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc year month entidad cve_municipio 

*recode edad
quietly gen edad_r = .
quietly replace edad_r = 1 if (rango_edad=="E1" | rango_edad=="E2" | rango_edad=="E3" ///
	| rango_edad=="E4")
quietly replace edad_r = 2 if (rango_edad=="E5" | rango_edad=="E6" | rango_edad=="E7" ///
	| rango_edad=="E8")
quietly replace edad_r = 3 if (rango_edad=="E9" | rango_edad=="E10" | rango_edad=="E11" ///
	| rango_edad=="E12" | rango_edad=="E13" | rango_edad=="E14")

quietly label def edad_r 1 "menos de 30" 2 "30 a menos de 50" 3 "50 a mas"
quietly label values edad_r edad_r edad_r
quietly la var edad_r "Rangos de Edad"
quietly drop rango_edad

*recode size_emp
quietly gen sizef = 0
quietly replace sizef = 1 if (tamaño_patron=="S1" | tamaño_patron=="S2")
quietly replace sizef = 2 if (tamaño_patron=="S3")
quietly replace sizef = 3 if (tamaño_patron=="S4" | tamaño_patron=="S5" | ///
	tamaño_patron=="S6" | tamaño_patron=="S7")	
quietly label def sizef 0 "NA" 1 "hasta 5 trab" 2 "6-50 trab" 3 "mas de 50" 
quietly label values sizef sizef sizef sizef
quietly label var sizef "firm size"
quietly drop tamaño_patron
	
*salarios
quietly gen w_tpu = masa_sal_tpu/tpu_sal
quietly gen w_tpc = masa_sal_tpc/tpc_sal
quietly label var w_tpu "salario diario trabajadores permanentes urbanos"
quietly label var w_tpc "salario diario trabajadores pernamentes del campo"

quietly gen trabaja_tpu = 0
quietly replace trabaja_tpu = 1 if w_tpu!=.
quietly gen trabaja_tpc = 0
quietly replace trabaja_tpc = 1 if w_tpc!=.
quietly drop tpu tpc // solo me quedo con los trabajadores asociados a masa salarial

*recode economic sectors
quietly gen sector=0
quietly replace sector = 1 if sector_economico_1 == 0
quietly replace sector = 2 if sector_economico_1 == 1
quietly replace sector = 3 if (sector_economico_1 == 2 | sector_economico_1 == 3)
quietly replace sector = 4 if sector_economico_1 == 4
quietly replace sector = 5 if sector_economico_1 == 5
quietly replace sector = 6 if sector_economico_1 == 6
quietly replace sector = 7 if sector_economico_1 == 7
quietly replace sector = 8 if (sector_economico_1 == 8 | sector_economico_1 == 9)

quietly label def sector 1 "Agro-pesca-ganad." 2 "Minería" 3 "manufactura" ///
	4 "construcción" 5 "energia" 6 "comercio" 7 "transporte" ///
	8 "servicios"
quietly label values sector sector sector sector sector sector sector ///
	sector
quietly label var sizef "sectores 8"
quietly drop sector_economico_1
quietly drop if sector==0 // only data with labels

*tradable and non-tradable goods
quietly gen tradable = 0
quietly replace tradable = 1 if (sector==1 | sector==2 | sector==3)

quietly label def tradable 1 "tradable" 0 "non-tradable"
quietly label values tradable tradable
quietly label var sizef "tradable goods"

quietly order id year month entidad cve_entidad cve_municipio municipio ///
	cve_delegacion cve_subdelegacion norte sexo edad_r sizef tpu_sal ///
	masa_sal_tpu w_tpu trabaja_tpu tpc_sal ///
	masa_sal_tpc w_tpc trabaja_tpc sector tradable

quietly drop cve_entidad municipio cve_delegacion cve_subdelegacion 
quietly compress
quietly save "$varios\\`i'_`j'_0.dta", replace

foreach k in tpu tpc{

*calculo de trabajo ta: trabajadores asegurados
quietly use "$varios\\`i'_`j'_0.dta", clear
	
quietly keep id year month entidad cve_municipio norte sexo edad_r sizef `k'_sal ///
	w_`k' trabaja_`k' sector tradable
	
quietly drop if trabaja_`k'==0 //solo calculos para aquellos con datos
quietly order id year month entidad cve_municipio norte sexo edad_r sizef
quietly sort id year month entidad cve_municipio norte sexo edad_r sizef
		
quietly collapse (sum) `k'_sal, by(id year month entidad cve_municipio norte ///
	sexo edad_r sizef sector tradable)
quietly save "$varios\\`i'_`j'_0_`k'.dta", replace

*calculo de salario ta: trabajadores asegurados
quietly use "$varios\\`i'_`j'_0.dta", clear

quietly keep id year month entidad cve_municipio norte sexo edad_r sizef `k'_sal ///
	w_`k' trabaja_`k' sector tradable 
	
quietly drop if trabaja_`k'==0 //solo calculos para aquellos con datos
quietly order id year month entidad cve_municipio norte sexo edad_r sizef
quietly sort id year month entidad cve_municipio norte sexo edad_r sizef
	
quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
	
quietly gen xxx = id + norte + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx

quietly by xxx: egen `k'_sal1 = sum(`k'_sal)
quietly by xxx: gen mass_`k' = `k'_sal * w_`k'
quietly by xxx: egen sal_`k' = sum(mass_`k')
quietly by xxx: gen sal_`k'1 = sal_`k' / `k'_sal1

quietly drop w_`k' `k'_sal1 mass_`k' sal_`k' xxx
quietly rename sal_`k'1 w_`k'
	
quietly collapse (mean) w_`k', by(id year month entidad cve_municipio norte ///
	sexo edad_r sizef sector tradable) 

quietly mmerge id year month entidad cve_municipio norte sexo edad_r sizef ///
	sector tradable using "$varios\\`i'_`j'_0_`k'.dta"
quietly drop _merge
quietly save "$varios\\`i'_`j'_0_`k'.dta", replace		
}
	
quietly use "$varios\\`i'_`j'_0_tpu.dta", clear
quietly mmerge id year month entidad cve_municipio norte sexo edad_r sizef ///
	sector tradable using "$varios\\`i'_`j'_0_tpc.dta"
quietly drop _merge
quietly save "$varios\\`i'_`j'_0_wl.dta", replace

quietly use "$varios\\`i'_`j'_0.dta", clear
quietly mmerge id year month entidad cve_municipio norte sexo edad_r sizef ///
	sector tradable using "$varios\\`i'_`j'_0_wl.dta"
quietly drop if _merge==-1	
quietly drop _merge

quietly replace month = "0" + month if (month=="1" | month=="2" | month=="3" | ///
	month=="4" | month=="5" | month=="6" | month=="7" | month=="8" | month=="9")
quietly replace entidad = "0" + entidad if (entidad=="1" | entidad=="2" | entidad=="3" | ///
	entidad=="4" | entidad=="5" | entidad=="6" | entidad=="7" | entidad=="8" | ///
	entidad=="9")

quietly la var cve_municipio "codigo IMSS municipio"
quietly la var w_tpu "salario diario trabajadores permanentes urbanos"
quietly la var tpu_sal "trabajadores permanentes urbanos"
quietly la var w_tpc "salario diario trabajadores permanentes del campo"
quietly la var tpc_sal "trabajadores permanentes del campo"

quietly destring month, gen(month1)
quietly gen days = mdy(month1+1,1,`i') - mdy(month1,1,`i')
quietly gen trab_permanentes = tpu_sal + tpc_sal
quietly replace trab_permanentes = tpu_sal if tpc==.
quietly replace trab_permanentes = tpc_sal if tpu==.
quietly gen w_tp	= ((w_tpu*tpu_sal)+(w_tpc*tpc_sal))/trab_permanentes
quietly replace w_tp = w_tpu if w_tpc==.
quietly replace w_tp = w_tpc if w_tpu==.

quietly gen salario_tpu = w_tpu*days
quietly la var salario_tpu "salario promedio mensual tpu"

quietly gen salario_tpc = w_tpc*days
quietly la var salario_tpc "salario promedio mensual tpc"

quietly gen salario_tp = w_tp*days
quietly la var salario_tp "salario promedio mensual tp"
quietly drop days
quietly compress	
	
quietly drop tpu_sal masa_sal_tpu w_tpu trabaja_tpu tpc_sal masa_sal_tpc w_tpc ///
	trabaja_tpc salario_tpu salario_tpc w_tp

quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
quietly gen xxx = id + norte + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx
	
quietly gen yyy = trab_permanentes*salario_tp		
quietly by xxx: egen s_yyy = sum(yyy)		
quietly by xxx: egen s_emp = sum(trab_permanentes)
quietly gen zzz = s_yyy/s_emp
quietly drop salario_tp yyy s_yyy s_emp xxx month1 sexo1 edad_r1 sizef1
quietly collapse (sum) trab_permanentes (mean) zzz, by(id year month entidad cve_municipio norte ///
	sexo edad_r sizef sector tradable)
quietly drop if trab_permanentes==0 | trab_permanentes==.
quietly rename zzz salario_tp 
quietly drop if salario_tp ==.
quietly compress
quietly save "$data\\`i'_`j'_r_sector.dta", replace
}
}
*
forvalues i = 2005/2016{
forvalues j = 12/12{

quietly use "$data\\`i'_`j'.dta", clear

quietly order year month cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion rango_edad sexo tamaño_patron

quietly label drop cve_entidad	
quietly gen entidad = string(cve_entidad)
quietly tostring year, replace
quietly tostring month, replace
quietly tostring cve_entidad, replace

quietly gen id = year + month + entidad + cve_municipio
	
quietly keep year month cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion rango_edad sexo tamaño_patron tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc municipio norte entidad id sector_economico_1
	
quietly order id sexo rango_edad tamaño_patron norte tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc year month entidad cve_municipio

quietly sort id sexo rango_edad tamaño_patron norte tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc year month entidad cve_municipio 

*recode edad
quietly gen edad_r = .
quietly replace edad_r = 1 if (rango_edad=="E1" | rango_edad=="E2" | rango_edad=="E3" ///
	| rango_edad=="E4")
quietly replace edad_r = 2 if (rango_edad=="E5" | rango_edad=="E6" | rango_edad=="E7" ///
	| rango_edad=="E8")
quietly replace edad_r = 3 if (rango_edad=="E9" | rango_edad=="E10" | rango_edad=="E11" ///
	| rango_edad=="E12" | rango_edad=="E13" | rango_edad=="E14")

quietly label def edad_r 1 "menos de 30" 2 "30 a menos de 50" 3 "50 a mas"
quietly label values edad_r edad_r edad_r
quietly la var edad_r "Rangos de Edad"
quietly drop rango_edad

*recode size_emp
quietly gen sizef = 0
quietly replace sizef = 1 if (tamaño_patron=="S1" | tamaño_patron=="S2")
quietly replace sizef = 2 if (tamaño_patron=="S3")
quietly replace sizef = 3 if (tamaño_patron=="S4" | tamaño_patron=="S5" | ///
	tamaño_patron=="S6" | tamaño_patron=="S7")	
quietly label def sizef 0 "NA" 1 "hasta 5 trab" 2 "6-50 trab" 3 "mas de 50" 
quietly label values sizef sizef sizef sizef
quietly label var sizef "firm size"
quietly drop tamaño_patron
	
*salarios
quietly gen w_tpu = masa_sal_tpu/tpu_sal
quietly gen w_tpc = masa_sal_tpc/tpc_sal
quietly label var w_tpu "salario diario trabajadores permanentes urbanos"
quietly label var w_tpc "salario diario trabajadores pernamentes del campo"

quietly gen trabaja_tpu = 0
quietly replace trabaja_tpu = 1 if w_tpu!=.
quietly gen trabaja_tpc = 0
quietly replace trabaja_tpc = 1 if w_tpc!=.
quietly drop tpu tpc // solo me quedo con los trabajadores asociados a masa salarial

*recode economic sectors
quietly gen sector=0
quietly replace sector = 1 if sector_economico_1 == 0
quietly replace sector = 2 if sector_economico_1 == 1
quietly replace sector = 3 if (sector_economico_1 == 2 | sector_economico_1 == 3)
quietly replace sector = 4 if sector_economico_1 == 4
quietly replace sector = 5 if sector_economico_1 == 5
quietly replace sector = 6 if sector_economico_1 == 6
quietly replace sector = 7 if sector_economico_1 == 7
quietly replace sector = 8 if (sector_economico_1 == 8 | sector_economico_1 == 9)

quietly label def sector 1 "Agro-pesca-ganad." 2 "Minería" 3 "manufactura" ///
	4 "construcción" 5 "energia" 6 "comercio" 7 "transporte" ///
	8 "servicios"
quietly label values sector sector sector sector sector sector sector ///
	sector
quietly label var sizef "sectores 8"
quietly drop sector_economico_1
quietly drop if sector==0 // only data with labels

*tradable and non-tradable goods
quietly gen tradable = 0
quietly replace tradable = 1 if (sector==1 | sector==2 | sector==3)

quietly label def tradable 1 "tradable" 0 "non-tradable"
quietly label values tradable tradable
quietly label var sizef "tradable goods"

quietly order id year month entidad cve_entidad cve_municipio municipio ///
	cve_delegacion cve_subdelegacion norte sexo edad_r sizef tpu_sal ///
	masa_sal_tpu w_tpu trabaja_tpu tpc_sal ///
	masa_sal_tpc w_tpc trabaja_tpc sector tradable

quietly drop cve_entidad municipio cve_delegacion cve_subdelegacion 
quietly compress
quietly save "$varios\\`i'_`j'_0.dta", replace

foreach k in tpu tpc{

*calculo de trabajo ta: trabajadores asegurados
quietly use "$varios\\`i'_`j'_0.dta", clear
	
quietly keep id year month entidad cve_municipio norte sexo edad_r sizef `k'_sal ///
	w_`k' trabaja_`k' sector tradable
	
quietly drop if trabaja_`k'==0 //solo calculos para aquellos con datos
quietly order id year month entidad cve_municipio norte sexo edad_r sizef
quietly sort id year month entidad cve_municipio norte sexo edad_r sizef
		
quietly collapse (sum) `k'_sal, by(id year month entidad cve_municipio norte ///
	sexo edad_r sizef sector tradable)
quietly save "$varios\\`i'_`j'_0_`k'.dta", replace

*calculo de salario ta: trabajadores asegurados
quietly use "$varios\\`i'_`j'_0.dta", clear

quietly keep id year month entidad cve_municipio norte sexo edad_r sizef `k'_sal ///
	w_`k' trabaja_`k' sector tradable
	
quietly drop if trabaja_`k'==0 //solo calculos para aquellos con datos
quietly order id year month entidad cve_municipio norte sexo edad_r sizef
quietly sort id year month entidad cve_municipio norte sexo edad_r sizef
	
quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
	
quietly gen xxx = id + norte + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx

quietly by xxx: egen `k'_sal1 = sum(`k'_sal)
quietly by xxx: gen mass_`k' = `k'_sal * w_`k'
quietly by xxx: egen sal_`k' = sum(mass_`k')
quietly by xxx: gen sal_`k'1 = sal_`k' / `k'_sal1

quietly drop w_`k' `k'_sal1 mass_`k' sal_`k' xxx
quietly rename sal_`k'1 w_`k'
	
quietly collapse (mean) w_`k', by(id year month entidad cve_municipio norte ///
	sexo edad_r sizef sector tradable) 

quietly mmerge id year month entidad cve_municipio norte sexo edad_r sizef ///
	sector tradable using "$varios\\`i'_`j'_0_`k'.dta"
quietly drop _merge
quietly save "$varios\\`i'_`j'_0_`k'.dta", replace		
}
	
quietly use "$varios\\`i'_`j'_0_tpu.dta", clear
quietly mmerge id year month entidad cve_municipio norte sexo edad_r sizef ///
	sector tradable using "$varios\\`i'_`j'_0_tpc.dta"
quietly drop _merge
quietly save "$varios\\`i'_`j'_0_wl.dta", replace

quietly use "$varios\\`i'_`j'_0.dta", clear
quietly mmerge id year month entidad cve_municipio norte sexo edad_r sizef ///
	sector tradable using "$varios\\`i'_`j'_0_wl.dta"
quietly drop if _merge==-1	
quietly drop _merge

quietly replace month = "0" + month if (month=="1" | month=="2" | month=="3" | ///
	month=="4" | month=="5" | month=="6" | month=="7" | month=="8" | month=="9")
quietly replace entidad = "0" + entidad if (entidad=="1" | entidad=="2" | entidad=="3" | ///
	entidad=="4" | entidad=="5" | entidad=="6" | entidad=="7" | entidad=="8" | ///
	entidad=="9")

quietly la var cve_municipio "codigo IMSS municipio"
quietly la var w_tpu "salario diario trabajadores permanentes urbanos"
quietly la var tpu_sal "trabajadores permanentes urbanos"
quietly la var w_tpc "salario diario trabajadores permanentes del campo"
quietly la var tpc_sal "trabajadores permanentes del campo"

quietly destring month, gen(month1)
quietly gen days = mdy(1,1,`i'+1) - mdy(month1,1,`i')
quietly gen trab_permanentes = tpu_sal + tpc_sal
quietly replace trab_permanentes = tpu_sal if tpc==.
quietly replace trab_permanentes = tpc_sal if tpu==.
quietly gen w_tp	= ((w_tpu*tpu_sal)+(w_tpc*tpc_sal))/trab_permanentes
quietly replace w_tp = w_tpu if w_tpc==.
quietly replace w_tp = w_tpc if w_tpu==.

quietly gen salario_tpu = w_tpu*days
quietly la var salario_tpu "salario promedio mensual tpu"

quietly gen salario_tpc = w_tpc*days
quietly la var salario_tpc "salario promedio mensual tpc"

quietly gen salario_tp = w_tp*days
quietly la var salario_tp "salario promedio mensual tp"
quietly drop days
quietly compress	
	
quietly drop tpu_sal masa_sal_tpu w_tpu trabaja_tpu tpc_sal masa_sal_tpc w_tpc ///
	trabaja_tpc salario_tpu salario_tpc w_tp

quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
quietly gen xxx = id + norte + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx
	
quietly gen yyy = trab_permanentes*salario_tp		
quietly by xxx: egen s_yyy = sum(yyy)		
quietly by xxx: egen s_emp = sum(trab_permanentes)
quietly gen zzz = s_yyy/s_emp
quietly drop salario_tp yyy s_yyy s_emp xxx month1 sexo1 edad_r1 sizef1
quietly collapse (sum) trab_permanentes (mean) zzz, by(id year month entidad cve_municipio norte ///
	sexo edad_r sizef sector tradable)
quietly drop if trab_permanentes==0 | trab_permanentes==.
quietly rename zzz salario_tp 
quietly drop if salario_tp ==.
quietly compress
quietly save "$data\\`i'_`j'_r_sector.dta", replace
}
}
*
*************
*	Append	*
*************
use "$data\2005_1_r_sector.dta", clear
forvalues i = 2005/2005{
	forvalues j = 2/12{
		quietly append using "$data\\`i'_`j'_r_sector.dta"
		quietly compress
		quietly save "$data\imss_r_sector.dta", replace
		}
	}
*	
use "$data\imss_r_sector.dta", clear
forvalues i = 2006/2016{
	forvalues j = 1/12{
		quietly append using "$data\\`i'_`j'_r_sector.dta"
		quietly compress
		quietly save "$data\imss_r_sector.dta", replace
		}
	}
*
use "$data\imss_r_sector.dta", clear
forvalues i = 2017/2017{
	forvalues j = 1/11{
		quietly append using "$data\\`i'_`j'_r_sector.dta"
		quietly compress
		quietly save "$data\imss_r_sector.dta", replace
		}
	}
*
********************************
* base a nivel municipio INEGI *
********************************
use "$data\imss_r_sector.dta", clear // base IMSS restringida
rename entidad state_cod
drop norte

quietly mmerge state_cod cve_municipio using "$data\codes.dta"
drop if _merge==1 // no informacion imss no informacion trabajadores
drop if _merge==2 // no informacion imss

drop cve_entidad municipio _merge id

order year month state_cod mun_cod cve_municipio descripcion_municipio ///
	norte sexo edad_r sizef trab_permanentes salario_tp 
	
sort year month state_cod mun_cod cve_municipio descripcion_municipio ///
	norte sexo edad_r sizef trab_permanentes salario_tp 

tostring sexo, gen(sexo1)
tostring edad_r, gen(edad1)
tostring sizef, gen(size1)

order year month state_cod mun_cod cve_municipio descripcion_municipio ///
	sexo1 edad1 size1 norte sexo edad_r sizef trab_permanentes salario_tp

gen id = year + month + state_cod + mun_cod + sexo1 + edad1 + size1 + norte
gen id1 = year + month + state_cod + mun_cod + sexo1 + edad1 + size1
order id
sort id
by id: gen xxx = _N // igual hasta codigo norte
sort id1
by id1: gen xxx_1 = _N // igual hasta codigo salario

gen zzz = 0
replace zzz =1 if xxx==xxx_1
save "$data\imss_id_sector.dta", replace // base completa con INEGI code

*****************************
*	Juntando codigos IMSS	*
*****************************
*zzz = 0 problemas con el indicador norte
use "$data\imss_id_sector.dta", clear // base completa con INEGI code
order id id1
sort id id1

*quitamos isla de cedros (02001) para no confundir con ensenada (02001)
drop if state_cod=="02" & mun_cod=="001" & cve_municipio=="Y35"

*br if cve_municipio=="Y44"
replace mun_cod="070" if cve_municipio=="Y44" & norte=="1" & state_cod=="26"

drop id id1 xxx* zzz

gen id = year + month + state_cod + mun_cod + sexo1 + edad1 + size1 + norte
gen id1 = year + month + state_cod + mun_cod + sexo1 + edad1 + size1
order id
sort id
by id: gen xxx = _N // igual hasta codigo norte
sort id1
by id1: gen xxx_1 = _N // igual hasta codigo salario
gen zzz = 0
replace zzz =1 if xxx==xxx_1

replace mun_cod="114"  if cve_municipio=="Y44" & norte=="0" & state_cod=="26"
replace state_cod="21" if cve_municipio=="Y44" & norte=="0" & state_cod=="26"
replace descripcion_municipio="PUEBLA" if cve_municipio=="Y44" & norte=="0" & state_cod=="21"

drop id xxx zzz
save "$data\imss_id_0_sector.dta", replace // base completa con INEGI code corregido id norte

*id repetidos
use "$data\imss_id_0_sector.dta", clear
drop id1 xxx_1 
gen id1 = year + month + state_cod + mun_cod + sexo1 + edad1 + size1
sort id1
by id1: gen xxx_1 = _N 
save "$data\imss_id_01_sector.dta", replace

*solo una vez
use "$data\imss_id_01_sector.dta", clear
keep if xxx_1==1
save "$data\imss_id_1_sector.dta", replace // grupo no repetido

*grupos repetidos
use "$data\imss_id_01_sector.dta", clear
keep if xxx_1!=1

sort id1
order id1

by id1: egen trab_permanentes1 = sum(trab_permanentes)
gen masa_sal = trab_permanentes*salario_tp
by id1: egen salario_tot = sum(masa_sal)
gen salario_tp1 = salario_tot/trab_permanentes1
drop trab_permanentes salario_tp masa_* salario_tot 

by id1: gen yyy=_n
keep if yyy==1
drop yyy xxx

save "$data\imss_id_2_sector.dta", replace // grupo no repetido

*************
*	Append	*
*************
use "$data\imss_id_1_sector.dta", clear // grupo no repetido
drop xxx_1

keep id1 year month state_cod mun_cod cve_municipio sexo edad_r sizef norte ///
	trab_permanentes salario_tp sector tradable
sort id1 year month state_cod mun_cod cve_municipio sexo edad_r sizef norte ///
	trab_permanentes salario_tp sector tradable
order id1 year month state_cod mun_cod cve_municipio sexo edad_r sizef norte ///
	trab_permanentes salario_tp sector tradable
save "$data\imss_id_11_sector.dta", replace // grupo no repetido

*****************
use "$data\imss_id_2_sector.dta", clear // grupo no repetido
rename trab_permanentes1 trab_permanentes
rename salario_tp1	salario_tp

keep id1 year month state_cod mun_cod cve_municipio sexo edad_r sizef norte ///
	trab_permanentes salario_tp sector tradable
sort id1 year month state_cod mun_cod cve_municipio sexo edad_r sizef norte ///
	trab_permanentes salario_tp
order id1 year month state_cod mun_cod cve_municipio sexo edad_r sizef norte ///
	trab_permanentes salario_tp

append using "$data\imss_id_11_sector.dta"
sort year month state_cod mun_cod

tostring sexo, gen(sexo1)
tostring edad_r, gen(edad1)
tostring sizef, gen(size1)
drop id1
gen id1 = year + month + state_cod + mun_cod + sexo1 + edad1 + size1
order id1
sort id1
by id1: gen xxx_1 = _N // igual hasta codigo salario
drop xxx_1
save "$data\imss_id_4_sector.dta", replace // base append

*otras correcciones 
use "$data\imss_id_4_sector.dta", clear
replace mun_cod="023" if mun_cod=="047" & state_cod=="11" & norte=="0"

drop id1
gen id = year + month + state_cod + mun_cod + sexo1 + edad1 + size1 + norte
gen id1 = year + month + state_cod + mun_cod + sexo1 + edad1 + size1
order id
sort id
by id: gen xxx = _N // igual hasta codigo norte
sort id1
by id1: gen xxx_1 = _N // igual hasta codigo salario

by id1: egen trab_permanentes1 = sum(trab_permanentes)
gen masa_sal = trab_permanentes*salario_tp
by id1: egen salario_tot = sum(masa_sal)
gen salario_tp1 = salario_tot/trab_permanentes1
drop trab_permanentes salario_tp masa_* salario_tot 

by id1: gen yyy=_n
keep if yyy==1
drop yyy xxx
drop id id1 xxx xxx_1

gen id = year + month + state_cod + mun_cod + sexo1 + edad1 + size1 + norte
gen id1 = year + month + state_cod + mun_cod + sexo1 + edad1 + size1
order id
sort id
by id: gen xxx = _N // igual hasta codigo norte
sort id1
by id1: gen xxx_1 = _N // igual hasta codigo salario
drop xxx*

compress
drop id* cve_municipio sexo1 edad1 size1 
save "$data\imss_id_5_sector.dta", replace

*******************
* informacion IPC *	
*******************
clear all
global prices	 = "D:\Research\Informality_IMSS\DTA\INPC"

quietly import excel "$prices\prices.xlsx", sheet("Niveles") firstrow
drop in 156

*salarios y empleo IMSS
quietly mmerge year month using "$data\imss_id_5_sector.dta"
keep if _merge==3
drop _merge

order year month state_cod mun_cod norte sexo edad_r sizef trab_permanentes ///
	salario_tp1 inpc
sort year month state_cod mun_cod norte sexo edad_r sizef trab_permanentes ///
	salario_tp1 inpc

*censo 2010
sort year state_cod mun_cod
quietly mmerge year state_cod mun_cod using "$data\base_censo_2010_ok1.dta" 
keep if inpc!=.
drop _merge

*pobreza 2010
sort year state_cod mun_cod
quietly mmerge year state_cod mun_cod using "$data\pobreza_2010_ok.dta" 
keep if inpc!=.
drop _merge

sort year month state_cod mun_cod
quietly compress
save "$data\base_2010_01162017_sector.dta", replace // IMSS mas informacion 2010

*igualando nombres de variables censo 2005 para el append
use "$data\censo_2005_short_3.dta", clear // censo 2005
rename pob2005_hombre pob_hombre1
rename pob2005_mujer pob_mujer1
rename lee_escribe lee_escribe1
rename lee_escribe_hombre lee_escribe1_hombre1
rename lee_escribe_mujer lee_escribe1_mujer1

save "$data\censo_2005_short_31.dta", replace // censo 2005

*merge 2010
use "$data\base_2010_01162017_sector.dta", clear // IMSS mas informacion 2010
sort year state_cod mun_cod
recast long lee_escribe
format %10.0g lee_escribe

quietly mmerge year state_cod mun_cod using "$data\censo_2005_short_31.dta"

drop if inpc==.
replace lee_escribe = lee_escribe1 if year=="2005" & lee_escribe==.
replace lee_escribe_hombre = lee_escribe1_hombre1 if year=="2005" & ///
	lee_escribe_hombre==.
replace lee_escribe_mujer = lee_escribe1_mujer1 if year=="2005" & ///
	lee_escribe_mujer==.	
replace pob_hombre = pob_hombre1 if year=="2005" & pob_hombre==.
replace pob_mujer = pob_mujer1 if year=="2005" & pob_mujer==.
drop lee_escribe1 lee_escribe1_* pob_hombre1 pob_mujer1 
drop _merge
replace poblacion = pob_hombre+pob_mujer if year=="2005" & poblacion==.

save "$data\base_2010_01172017_sector.dta", replace // IMSS mas informacion 2010

*merge pobreza 2005
use "$data\pobreza_2005_short_1.dta", clear

drop pob2005
sort year state_cod mun_cod

quietly mmerge year state_cod mun_cod using "$data\base_2010_01172017_sector.dta"

replace pobreza = pobreza2005 if year=="2005" & pobreza==.
drop pobreza2005
drop if inpc==.

sort year month state_cod mun_cod
order year month state_cod mun_cod
drop _merge

quietly compress
save "$data\base_01172017_sector.dta", replace // IMSS mas informacion 2010
*

****
/*indicadores geograficos
rename norte nortef
quietly la var nortef "municipios frontera norte"

gen norte="0"
replace norte = "1" if (state_cod=="02" | state_cod=="05" | state_cod=="08" ///
	|state_cod=="19" |state_cod=="26" |state_cod=="28") 
quietly la var norte "estados frontera norte"

gen surf = 0
replace surf = 1 if (state_cod=="04" & (mun_cod=="011" | mun_cod=="010"))
replace surf = 1 if (state_cod=="07" & (mun_cod=="006" | mun_cod=="114" | ///
	mun_cod=="015" | mun_cod=="034" | mun_cod=="035" | mun_cod=="041" | ///
	mun_cod=="099" | mun_cod=="052" | mun_cod=="115" | mun_cod=="116" | ///
	mun_cod=="053" | mun_cod=="055" | mun_cod=="057" | mun_cod=="059" | ///
	mun_cod=="065" | mun_cod=="110" | mun_cod=="087" | mun_cod=="089" | ///
	mun_cod=="102" | mun_cod=="105" ))
replace surf = 1 if (state_cod=="23" & (mun_cod=="005" | mun_cod=="001" | ///
	mun_cod=="002" | mun_cod=="003" | mun_cod=="006" | mun_cod=="007" | ///
	mun_cod=="004" | mun_cod=="008" | mun_cod=="009" ))
replace surf = 1 if (state_cod=="27" & (mun_cod=="017" | mun_cod=="001"))
quietly la var surf "municipios frontera sur"

gen municipio = state_cod + mun_cod

gen norte_neighbour 	= "0"
replace norte_neighbour	= norte if norte_neighbour=="0"
replace norte_neighbour	= "1" if (municipio=="03002" | municipio=="25001" | ///
	municipio=="25003" | municipio=="25007" | municipio=="25010" | ///
	municipio=="25017" | municipio=="10034" | municipio=="10035" | ///
	municipio=="10009" | municipio=="10017" | municipio=="10010" | ///
	municipio=="10013" | municipio=="10036" | municipio=="10007" | ///
	municipio=="10012" | municipio=="10006" | municipio=="10027" | ///
	municipio=="32026" | municipio=="32027" | municipio=="32007" | ///
	municipio=="32041" | municipio=="24044" | municipio=="24007" | ///
	municipio=="24020" | municipio=="24017" | municipio=="24010" | ///
	municipio=="24058" | municipio=="24013" | municipio=="24040" | ///
	municipio=="30123" | municipio=="30133")

gen nortesf = 0
replace nortesf = 1 if (norte=="1" & nortef=="0")
quietly la var nortesf "estados del norte sin frontera norte"

gen resto = 0
replace resto = 1 if norte=="0" 
quietly la var resto "resto de municipios sin estados del norte"

gen restosf = 0
replace restosf = 1 if (resto==1 & surf==0)
quietly la var restosf "resto de municipios sin estados del norte y de frontera sur"

tostring surf, replace
tostring nortesf, replace
tostring resto, replace
tostring restosf, replace

quietly compress
save "$data\base_01172017_sector.dta", replace

*precios
************************************************************
*agregando indices de precios
clear all
import excel "D:\Research\Informality_IMSS\DTA\INPC.xlsx", sheet("Niveles") ///
	firstrow

tostring year, replace
tostring month, replace

replace month = "0" + month if month=="1" | month=="2" | month=="3" | month=="4" ///
	| month=="5" | month=="6" | month=="7" | month=="8" | month=="9"
	
sort year month
quietly mmerge year month municipio using "$data\base_01172017_sector.dta"

drop if norte==""

save "$data\base_01172017_1_sector.dta", replace

*informalidad2010
*********************************
clear all
import excel "D:\Research\Informality_IMSS\DTA\census\2010\Formal_informal_emp.xlsx", ///
	sheet("INEGI_Exporta_20170221092359") firstrow

gen year ="2010"
drop municipio
gen state_cod 	= substr(mun_cod,1,2)
gen muncod 		= substr(mun_cod,4,3)

order state_cod muncod year ocup_formal ocup_informal ocupados
drop mun_cod

rename ocup_formal 		formal_2010
rename ocup_informal	informal_2010
rename ocupados			ocup_2010

gen mun1 = state_cod+muncod
encode mun1, gen(municipio)

order municipio year formal* informal* ocup*
drop state_cod muncod
sort municipio year formal* informal* ocup*

drop municipio
rename mun1 municipio
order year municipio
sort year municipio

quietly mmerge year municipio using "$data\base_01172017_1_sector.dta"
drop if norte==""
drop _merge

compress
save "$data\base_01172017_2_sector.dta", replace

*juntanto con base edades 2010
use "$data\census\2010\edades.dta", clear

foreach i in 0_4 5_9 10_14 15_19 20_24 25_29 30_34 35_39 40_44 45_49 50_54 ///
	55_59 60_64 65_69 70_74 75_79 80_84 85_mas{
	quietly replace h_`i' = 0 if h_`i'==. 
	quietly replace m_`i' = 0 if m_`i'==.
	}
*
gen edad_hom = h_0_4+h_5_9+h_10_14+h_15_19+h_20_24+h_25_29+h_30_34+h_35_39 + ///
	h_40_44+h_45_49+h_50_54+h_55_59+h_60_64+h_65_69+h_70_74+h_75_79+h_80_84 + ///
	h_85_mas
gen edad_muj = m_0_4+m_5_9+m_10_14+m_15_19+m_20_24+m_25_29+m_30_34+m_35_39+	///
	m_40_44+m_45_49+m_50_54+m_55_59+m_60_64+m_65_69+m_70_74+m_75_79+m_80_84+ ///
	m_85_mas
	
gen r_0_19_h 	= h_0_4+h_5_9+h_10_14+h_15_19
gen r_20_59_h 	= h_20_24+h_25_29+h_30_34+h_35_39 + h_40_44+h_45_49+h_50_54+h_55_59
gen r_60mas_h 	= h_60_64+h_65_69+h_70_74+h_75_79+h_80_84+h_85_mas

gen r_0_19_m 	= m_0_4+m_5_9+m_10_14+m_15_19
gen r_20_59_m 	= m_20_24+m_25_29+m_30_34+m_35_39+m_40_44+m_45_49+m_50_54+m_55_59
gen r_60mas_m 	= m_60_64+m_65_69+m_70_74+m_75_79+m_80_84+m_85_mas
	
gen year ="2010"

keep year municipio1 edad_hom edad_muj r_*
order year municipio1 edad_hom edad_muj r_*

rename edad_hom edad1
rename edad_muj edad2

rename r_0_19_h 	r0191
rename r_0_19_m 	r0192
rename r_20_59_h 	r20591
rename r_20_59_m 	r20592
rename r_60mas_h	r60m1
rename r_60mas_m	r60m2

reshape long edad r019 r2059 r60m, i(municipio1) j(sexo)
label def sexo 1 "Hombre" 2 "Mujer"
label values sexo sexo

order municipio1 year sexo
sort municipio1 year sexo
rename municipio1 municipio

quietly mmerge municipio year sexo using "$data\base_01172017_2_sector.dta"
drop if _merge==1
drop _merge
	
save "$data\base_01172017_3_sector.dta", replace
exit
