******************************
* Limpieza de consola
******************************
clear all
set more off


******************************
* Ajuste de directorio
******************************
* Definimos el directorio base. Cambiar si se corre desde otro equipo
pwd
cd "D:\IMSS_INEGI"
pwd

global directorio = "D:\IMSS_INEGI"
global base = "D:\appended"

quietly use "$base\imss_2020_2021_mod.dta", clear

gen date = dofm(fecha)
format date %d
gen mes = month(date)
gen anio = year(date)
drop date

quietly order anio mes cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion rango_edad sexo tamaño_patron 
	
quietly gen entidad = string(cve_entidad)
quietly tostring anio, replace
quietly tostring mes, replace
quietly tostring cve_entidad, replace
	
quietly gen id = anio + mes + entidad + cve_municipio
	
quietly keep anio mes cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion rango_edad sexo tamaño_patron tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc entidad id sector_economico_1
*se omitieron las variables norte y municipio
	
quietly order id sexo rango_edad tamaño_patron tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc anio mes entidad cve_municipio
*se omite la variable norte

quietly sort id sexo rango_edad tamaño_patron tpu tpc tpu_sal tpc_sal ///
	masa_sal_tpu masa_sal_tpc anio mes entidad cve_municipio 
*se omite la variable norte

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

quietly order id anio mes entidad cve_entidad cve_municipio cve_delegacion ///
	cve_subdelegacion sexo edad_r sizef tpu_sal ///
	masa_sal_tpu w_tpu trabaja_tpu tpc_sal ///
	masa_sal_tpc w_tpc trabaja_tpc sector tradable
*se omiten las variables municipio y norte

quietly drop cve_entidad cve_delegacion cve_subdelegacion 
*se omite la variable municipio

**** PRIMERA PARTE ****
quietly compress
quietly save "$base\parte_1.dta", replace
***********************


*** CÁLCULO DE LOS TPU ***

*calculo de trabajo ta: trabajadores asegurados
quietly use "$base\parte_1.dta", clear
	
quietly keep id anio mes entidad cve_municipio sexo edad_r sizef tpu_sal ///
	w_tpu trabaja_tpu sector tradable
*se omite norte
	
quietly drop if trabaja_tpu==0 //solo calculos para aquellos con datos
quietly order id anio mes entidad cve_municipio sexo edad_r sizef
quietly sort id anio mes entidad cve_municipio sexo edad_r sizef
		
quietly collapse (sum) tpu_sal, by(id anio mes entidad cve_municipio ///
	sexo edad_r sizef sector tradable)
quietly save "$base\parte_1_0_tpu.dta", replace

*calculo de salario ta: trabajadores asegurados
quietly use "$base\parte_1.dta", clear

quietly keep id anio mes entidad cve_municipio sexo edad_r sizef tpu_sal ///
	w_tpu trabaja_tpu sector tradable 
	
quietly drop if trabaja_tpu==0 //solo calculos para aquellos con datos
quietly order id anio mes entidad cve_municipio sexo edad_r sizef
quietly sort id anio mes entidad cve_municipio sexo edad_r sizef
	
quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
	
quietly gen xxx = id + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx

quietly by xxx: egen tpu_sal1 = sum(tpu_sal)
quietly by xxx: gen mass_tpu = tpu_sal * w_tpu
quietly by xxx: egen sal_tpu = sum(mass_tpu)
quietly by xxx: gen sal_tpu1 = sal_tpu / tpu_sal1

quietly drop w_tpu tpu_sal1 mass_tpu sal_tpu xxx
quietly rename sal_tpu1 w_tpu
	
quietly collapse (mean) w_tpu, by(id anio mes entidad cve_municipio ///
	sexo edad_r sizef sector tradable) 
	
quietly merge m:m id anio mes entidad cve_municipio sexo edad_r sizef ///
	sector tradable using "$base\parte_1_0_tpu.dta"
*por alguna razón no reconoció el comando mmerge, por lo que se usó la especificación m:m
quietly drop _merge
quietly save "$base\parte_1_0_tpu.dta", replace		


*** CÁLCULO DE LOS TPC ***

quietly use "$base\parte_1.dta", clear

quietly keep id anio mes entidad cve_municipio sexo edad_r sizef tpc_sal ///
	w_tpc trabaja_tpc sector tradable
*se omite norte
	
quietly drop if trabaja_tpc==0 //solo calculos para aquellos con datos
quietly order id anio mes entidad cve_municipio sexo edad_r sizef
quietly sort id anio mes entidad cve_municipio sexo edad_r sizef
		
quietly collapse (sum) tpc_sal, by(id anio mes entidad cve_municipio ///
	sexo edad_r sizef sector tradable)
quietly save "$base\parte_1_0_tpc.dta", replace

*calculo de salario ta: trabajadores asegurados
quietly use "$base\parte_1.dta", clear

quietly keep id anio mes entidad cve_municipio sexo edad_r sizef tpc_sal ///
	w_tpc trabaja_tpc sector tradable 
	
quietly drop if trabaja_tpc==0 //solo calculos para aquellos con datos
quietly order id anio mes entidad cve_municipio sexo edad_r sizef
quietly sort id anio mes entidad cve_municipio sexo edad_r sizef
	
quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
	
quietly gen xxx = id + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx

quietly by xxx: egen tpc_sal1 = sum(tpc_sal)
quietly by xxx: gen mass_tpc = tpc_sal * w_tpc
quietly by xxx: egen sal_tpc = sum(mass_tpc)
quietly by xxx: gen sal_tpc1 = sal_tpc / tpc_sal1

quietly drop w_tpc tpc_sal1 mass_tpc sal_tpc xxx
quietly rename sal_tpc1 w_tpc
	
quietly collapse (mean) w_tpc, by(id anio mes entidad cve_municipio ///
	sexo edad_r sizef sector tradable) 

quietly merge m:m id anio mes entidad cve_municipio sexo edad_r sizef ///
	sector tradable using "$base\parte_1_0_tpc.dta"
quietly drop _merge
quietly save "$base\parte_1_0_tpc.dta", replace



*** UNIÓN DE TPU Y TPC PARA LA BASE WL ***
quietly use "$base\parte_1_0_tpu.dta", clear
quietly merge m:m id anio mes entidad cve_municipio sexo edad_r sizef ///
	sector tradable using "$base\parte_1_0_tpc.dta"
quietly drop _merge
quietly save "$base\parte_1_0_wl.dta", replace

*** UNIÓN DE PARTE 1 Y WL ***
quietly use "$base\parte_1.dta", clear
quietly merge m:m id anio mes entidad cve_municipio sexo edad_r sizef ///
	sector tradable using "$base\parte_1_0_wl.dta"
quietly drop if _merge==-1	
quietly drop _merge

*** AJUSTE DE BASE FINAL ***
quietly replace mes = "0" + mes if (mes=="1" | mes=="2" | mes=="3" | ///
	mes=="4" | mes=="5" | mes=="6" | mes=="7" | mes=="8" | mes=="9")
quietly replace entidad = "0" + entidad if (entidad=="1" | entidad=="2" | entidad=="3" | ///
	entidad=="4" | entidad=="5" | entidad=="6" | entidad=="7" | entidad=="8" | ///
	entidad=="9")

quietly la var cve_municipio "codigo IMSS municipio"
quietly la var w_tpu "salario diario trabajadores permanentes urbanos"
quietly la var tpu_sal "trabajadores permanentes urbanos"
quietly la var w_tpc "salario diario trabajadores permanentes del campo"
quietly la var tpc_sal "trabajadores permanentes del campo"

quietly destring mes, gen(mes1)
quietly destring anio, gen(anio1) 
quietly gen dias = mdy(mes1 + 1,1, anio1) - mdy(mes1,1, anio1)
quietly gen trab_permanentes = tpu_sal + tpc_sal
quietly replace trab_permanentes = tpu_sal if tpc==.
quietly replace trab_permanentes = tpc_sal if tpu==.
quietly gen w_tp = ((w_tpu*tpu_sal)+(w_tpc*tpc_sal))/trab_permanentes
quietly replace w_tp = w_tpu if w_tpc==.
quietly replace w_tp = w_tpc if w_tpu==.

quietly gen salario_tpu = w_tpu*dias
quietly la var salario_tpu "salario promedio mensual tpu"

quietly gen salario_tpc = w_tpc*dias
quietly la var salario_tpc "salario promedio mensual tpc"

quietly gen salario_tp = w_tp*dias
quietly la var salario_tp "salario promedio mensual tp"
quietly drop dias
quietly compress	
	
quietly drop tpu_sal masa_sal_tpu w_tpu trabaja_tpu tpc_sal masa_sal_tpc w_tpc ///
	trabaja_tpc salario_tpu salario_tpc w_tp

quietly tostring sexo, gen(sexo1)
quietly tostring edad_r, gen(edad_r1)
quietly tostring sizef, gen(sizef1)
quietly gen xxx = id + sexo1 + edad_r1 + sizef1
quietly order xxx
quietly sort xxx
	
quietly gen yyy = trab_permanentes*salario_tp		
quietly by xxx: egen s_yyy = sum(yyy)		
quietly by xxx: egen s_emp = sum(trab_permanentes)
quietly gen zzz = s_yyy/s_emp
quietly drop salario_tp yyy s_yyy s_emp xxx mes1 sexo1 edad_r1 sizef1

quietly collapse (sum) trab_permanentes (mean) zzz, by(id anio mes entidad cve_municipio ///
	sexo edad_r sizef sector tradable)
	
quietly drop if trab_permanentes==0 | trab_permanentes==.
quietly rename zzz salario_tp 
quietly drop if salario_tp ==.

quietly compress
quietly save "$base\imss_r_sector.dta", replace



/// Parte 2: Unión de bases de datos

quietly use "$base\imss_r_sector.dta", clear
drop id salario_tp
rename cve_municipio munid_imss
rename entidad entid_inegi
save "$directorio\imss2.dta", replace

// División de Variables Categóricas

quietly use "$directorio\imss2.dta", clear
collapse (sum) trab_permanentes, by(anio mes entid_inegi  munid_imss tradable)
reshape wide trab_permanentes, i(anio mes entid_inegi munid_imss) j(tradable)
rename trab_permanentes0 nontrada
rename trab_permanentes1 tradable
replace munid_imss = "DF" if entid_inegi == "09"
save "$directorio\tradable.dta", replace

quietly use "$directorio\imss2.dta", clear
collapse (sum) trab_permanentes, by(anio mes entid_inegi munid_imss sector)
decode sector, generate(sector_eco)
drop sector
replace sector_eco = "agro_pesc_ganad" if sector_eco == "Agro-pesca-ganad."
replace sector_eco = "mineria" if sector_eco == "Minería"
replace sector_eco = "manufact" if sector_eco == "manufactura"
replace sector_eco = "constr" if sector_eco == "construcción"
replace sector_eco = "energia" if sector_eco == "energ"
replace sector_eco = "com" if sector_eco == "comercio"
replace sector_eco = "transp" if sector_eco == "transporte"
replace sector_eco = "serv" if sector_eco == "servicios"
replace munid_imss = "DF" if entid_inegi == "09"
reshape wide trab_permanentes, i(anio mes entid_inegi munid_imss) j(sector_eco) string
rename trab_permanentes* *
save "$directorio\sector.dta", replace

quietly use "$directorio\imss2.dta", clear
collapse (sum) trab_permanentes, by(anio mes entid_inegi munid_imss sizef)
decode sizef, generate(tam)
drop sizef
replace tam = "menos5trab" if tam == "hasta 5 trab"
replace tam = "trab_6_50" if tam == "6-50 trab"
replace tam = "mas50trab" if tam == "mas de 50"
replace munid_imss = "DF" if entid_inegi == "09"
reshape wide trab_permanentes, i(anio mes entid_inegi munid_imss) j(tam) string
drop trab_permanentesNA
rename trab_permanentes* *
save "$directorio\tamanio.dta", replace

quietly use "$directorio\imss2.dta", clear
collapse (sum) trab_permanentes, by(anio mes entid_inegi munid_imss edad_r)
decode edad_r, generate(edad)
drop edad_r
replace edad = "edadmenos30" if edad == "menos de 30"
replace edad = "edad30_50" if edad == "30 a menos de 50"
replace edad = "edadmas50" if edad == "50 a mas"
replace edad = "edadmenos30" if edad == "menos de 30"
replace munid_imss = "DF" if entid_inegi == "09"
reshape wide trab_permanentes, i(anio mes entid_inegi munid_imss) j(edad) string
rename trab_permanentes* *
save "$directorio\edad.dta", replace

quietly use "$directorio\imss2.dta", clear
collapse (sum) trab_permanentes, by(anio mes entid_inegi munid_imss sexo)
tostring sexo, replace
replace sexo = "hombre" if sexo == "1"
replace sexo = "mujer" if sexo == "2"
replace munid_imss = "DF" if entid_inegi == "09"
reshape wide trab_permanentes, i(anio mes entid_inegi munid_imss) j(sexo) string
rename trab_permanentes* *
save "$directorio\sexo.dta", replace

// Unión de variables categóricas IMSS

use "$directorio\tradable.dta", clear
merge m:m anio mes entid_inegi munid_imss using "$directorio\sector.dta", keep(master match)
drop _merge
merge m:m anio mes entid_inegi munid_imss using "$directorio\tamanio.dta", keep(master match)
drop _merge
merge m:m anio mes entid_inegi munid_imss using "$directorio\edad.dta", keep(master match)
drop _merge
merge m:m anio mes entid_inegi munid_imss using "$directorio\sexo.dta", keep(master match)
drop _merge
save "$directorio\imss3.dta", replace

// Códigos IMSS-INEGI

use "$directorio\codes.dta", clear
drop descripcion_municipio cve_entidad code norte municipio
rename mun_cod munid_inegi
rename state_cod entid_inegi
rename cve_municipio munid_imss
drop if munid_inegi == ""
save "$directorio\codes2.dta", replace

// Códigos GADM-INEGI

import delimited "codes_gadm.txt", clear
gen munid_inegi = substr(id_muni_inegi,4,6)
gen entid_inegi = substr(id_muni_inegi,1,2)
drop id_match id_muni_inegi id_ent_inegi entidady municipioy id_match
rename entidadx ent_fb
rename municipiox mun_fb
rename id_ent_gadm entid_gadm
rename id_muni_gadm munid_gadm
drop if mun_fb != "Coyoacán" & entid_inegi == "09"
replace munid_inegi = "000" if entid_inegi == "09"
replace munid_gadm = "000" if entid_inegi == "09"
replace entid_gadm = "000" if entid_inegi == "09"
replace mun_fb = "Distrito Federal" if entid_inegi == "09"
save "$directorio\id_gadm_inegi.dta", replace

// Unión de códigos GADM-INEGI-IMSS

quietly use "$directorio/imss3.dta", clear
quietly merge m:m entid_inegi munid_imss using "$directorio\codes2.dta", keep(master match)
drop _merge
order anio mes entid_inegi munid_imss munid_inegi
quietly merge m:m entid_inegi munid_inegi using "$directorio\id_gadm_inegi.dta", keep(master match)
drop _merge
rename ent_fb ent
rename mun_fb mun
order anio mes ent entid_inegi entid_gadm mun munid_inegi munid_imss munid_gadm
drop if munid_gadm == ""
save "$directorio\imss_gadm_inegi.dta", replace

// Códigos y Datos de FB

global fb = "C:\Users\Diego Mendoza M\OneDrive - Fundacion Universidad de las Americas Puebla\Servicio Social\Paper de Movilidad-Empleo\Facebook"

import delimited "$fb\fb_panel_mov.txt", clear
drop municipio
gen entid_gadm = substr(polygon_id,1,5)
gen mes2 = substr(fecha,1,7)
drop if mes2 == "2021-02" | mes2 == "2021-03"
drop fecha
replace polygon_id = "000" if entid_gadm == "MEX.9"
collapse (mean) cambio_mov inmovilidad, by(mes2 polygon_id)
rename polygon_id munid_gadm
gen anio = substr(mes2,1,4)
gen mes = substr(mes2,6,7)
drop mes2
order anio mes munid_gadm
save "fb_muni.dta", replace

// Unión de IMSS-INEGI-GADM-FB

use "$directorio/imss_gadm_inegi.dta", clear
drop if mes == "02"
quietly merge m:m anio mes munid_gadm using "fb_muni.dta", keep(master match)
order anio mes ent entid_inegi entid_gadm mun munid_inegi munid_imss munid_gadm
gen fecha1 = anio + "-" + mes
gen fecha = monthly(fecha1, "YM")
format fecha %tm
drop fecha1
order fecha
save "$directorio\imss_inegi_fb.dta", replace

/// Unión de datos de Google

global google = "C:\Users\Diego Mendoza M\OneDrive - Fundacion Universidad de las Americas Puebla\Servicio Social\Paper de Movilidad-Empleo\Google"

use "$google\google_panel.dta", clear
replace mes = "01" if mes == "1"
drop if anio == "2020" & mes == "02"
gen fecha2 = anio + "-" + mes
gen fecha = monthly(fecha2, "YM")
format fecha %tm
drop fecha2
order fecha
replace ent = "Michoacán" if ent == "MichoacÃ¡n"
replace ent = "Querétaro" if ent == "QuerÃ©taro"
replace ent = "Yucatán" if ent == "Yucatan"
replace ent = "San Luis Potosí" if ent == "San Luis Potosi"
replace ent = "Nuevo León" if ent == "Nuevo Leon"
replace ent = "México" if ent == "State of Mexico"
replace ent = "Distrito Federal" if ent == "Mexico City"
save "$directorio\google_panel.dta", replace

use "$directorio\imss_inegi_fb.dta", clear
rename constr construc
collapse (sum) nontrada tradable agro_pesc_ganad com construc energia manufact /// 
mineria serv transp mas50trab menos5trab trab_6_50 edad30_50 edadmas50 ///
edadmenos30 hombre mujer, by(fecha anio mes ent entid_inegi entid_gadm)
sort anio mes ent, stable
merge m:m anio mes ent using "$directorio\google_panel.dta", keep(master match)
drop _merge
save "$directorio\imss_google.dta", replace

use "$directorio\imss_inegi_fb.dta", clear
rename constr construc
collapse (mean) inmovilidad cambio_mov, by(fecha anio mes ent entid_inegi entid_gadm)
sort anio mes ent, stable
merge m:m fecha anio mes ent using "$directorio\imss_google.dta", keep(master match)
drop _merge
save "$directorio\imss_google_fb.dta", replace


/// Unión de instrumento "Google Trends"
import delimited "$directorio/instrumento_google.txt", clear
gen anio = substr(fecha,1,4)
gen mes2 = substr(fecha,6,7)
gen mes = substr(mes2,1,2)
drop fecha mes2
collapse (mean) popularity_score, by(categoria ent anio mes)
drop if categoria == ""
keep if anio == "2020" | anio == "2021"
drop if anio == "2020" & (mes == "01" | mes == "02")
drop if anio == "2021" & (mes == "02" | mes == "03" | mes == "03" | mes == "04" | mes == "05" | mes == "06" | mes == "07" | mes == "08" | mes == "09" | mes== "10" | mes == "11" | mes == "12")
collapse (mean) popularity_score, by(ent anio mes)
replace ent = "Distrito Federal" if ent == "Ciudad de México"
save "$directorio\instrumento.dta", replace

use "$directorio\imss_google_fb.dta", clear
merge m:m mes ent using "$directorio\instrumento.dta", keep(master match)
drop _merge
order ent anio mes
sort ent anio mes
save "$directorio\imss_google_fb_instr.dta", replace

/// Unión de datos movilidad LA RUTA para Puebla

use "$directorio\imss_inegi_fb.dta", clear
keep if (munid_inegi == "114" | munid_inegi == "015" | munid_inegi == "119") & entid_inegi == "21"
drop if anio == "2021"
drop if mes == "10" | mes == "11" | mes == "12"
collapse (sum) nontrada tradable agro_pesc_ganad com constr energia manufact mineria serv transp mas50trab menos5trab trab_6_50 edad30_50 edadmas50 edadmenos30 hombre mujer, by(fecha anio mes entid_inegi ent munid_inegi mun)
replace munid_inegi = "000"
replace mun = "Puebla"
collapse (sum) nontrada tradable agro_pesc_ganad com constr energia manufact mineria serv transp mas50trab menos5trab trab_6_50 edad30_50 edadmas50 edadmenos30 hombre mujer, by(fecha anio mes entid_inegi ent mun munid_inegi)
save "$directorio\imss_puebla.dta", replace

use "$directorio\imss_inegi_fb.dta", clear
keep if (munid_inegi == "114" | munid_inegi == "015" | munid_inegi == "119") & entid_inegi == "21"
drop if anio == "2021"
drop if mes == "10" | mes == "11" | mes == "12"
replace mun = "Puebla"
replace munid_inegi = "000"
collapse (mean) cambio_mov inmovilidad, by(fecha anio mes ent entid_inegi mun munid_inegi)

save "$directorio\imss_fb_puebla.dta", replace
merge m:m fecha anio mes ent entid_inegi mun munid_inegi mun munid_inegi using "$directorio\imss_puebla.dta", keep(master match)
drop _merge
save "$directorio\imss_fb_puebla_2.dta", replace

import excel "$directorio/instrumento_linea.xlsx", sheet("PANEL") first clear
tostring dia mes, replace
drop if mes == "2"
replace mes = "03" if mes == "3"
replace mes = "04" if mes == "4"
replace mes = "05" if mes == "5"
replace mes = "06" if mes == "6"
replace mes = "07" if mes == "7"
replace mes = "08" if mes == "8"
replace mes = "09" if mes == "9"
collapse (sum) lin_1 lin_2 lin_3 lin_tot, by(mes)
merge m:m mes using "$directorio\imss_fb_puebla_2.dta", keep(master match)
drop _merge
order fecha anio mes ent entid_inegi mun munid_inegi inmovilidad cambio_mov lin_1 lin_2 lin_3 lin_tot
save "$directorio\imss_fb_instr.dta", replace

use "$directorio\imss_fb_instr.dta", clear
ivreg2 serv (cambio_mov = lin_tot), first
ivreg2 serv (cambio_mov = lin_tot), first robust

ivreg2 serv (inmovilidad = lin_tot), first
ivreg2 serv (inmovilidad = lin_tot), first robust

ivreg2 com (inmovilidad = lin_tot), first robust
ivreg2 transp (inmovilidad = lin_tot), first robust
ivreg2 menos5trab (inmovilidad = lin_tot), first robust
ivreg2 trab_6_50 (inmovilidad = lin_tot), first robust
ivreg2 mas50trab (inmovilidad = lin_tot), first robust
ivreg2 constr (inmovilidad = lin_tot), first robust
ivreg2 agro_pesc_ganad (inmovilidad = lin_tot), first robust
ivreg2 energia (inmovilidad = lin_tot), first robust
ivreg2 manufact (inmovilidad = lin_tot), first robust
ivreg2 mineria (inmovilidad = lin_tot), first robust

// Estadística Descriptiva

/*
quietly use "$base\imss_r_sector.dta", clear
drop id
gen fecha2 = anio + "-" + mes
gen fecha = monthly(fecha2, "YM")
format fecha %tm
drop fecha2
order fecha

collapse (sum) trab_permanentes, by(fecha sexo edad_r sizef sector tradable)

twoway scatter trab_permanentes fecha, by(edad_r)

controles del censo
regresiones de outreg2 prueba con empleo en log
descargar datos de google trends
acomodar datos de ruta puebla a diarios con fb
*/

import excel "$directorio\controles_censo.xlsx", sheet(controles) clear first
tostring anio, replace
save "$directorio\controles_censo.dta", replace

use "$directorio\imss_google_fb_instr.dta", clear
merge m:m ent anio entid_inegi using "$directorio\controles_censo.dta", keep(master match)
drop _merge
save "$directorio\imss_mov_final.dta", replace

// Regresiones preliminares
global output = "D:\IMSS_INEGI\output_iv"
global output2 = "D:\IMSS_INEGI\output_iv_2"
global output3 = "D:\IMSS_INEGI\output_iv_3"
global output4 = "D:\IMSS_INEGI\output_iv_4"

use "$directorio\imss_mov_final.dta", clear

destring entid_inegi, replace
destring mes, replace
xtset entid_inegi fecha

gen inmovilidad2 = inmovilidad*100
gen cambio_mov2 = cambio_mov*100
drop inmovilidad cambio_mov

rename inmovilidad2 inmovilidad
rename cambio_mov2 cambio_mov 

// Usando inmovilidad

foreach var in nontrada tradable agro_pesc_ganad com construc energia manufact mineria serv transp mas50trab menos5trab trab_6_50 edad30_50 edadmas50 edadmenos30 hombre mujer {
	gen l`var' = log(`var')
}

foreach var in inmovilidad cambio_mov com_google super_google parques_google trans_google ofic_google resid_google {
	quietly xtreg `var' popularity_score
	quietly outreg2 using "$output\popularity_score_`var'.xls", excel ///
	replace ctitle(`var') stats(coef se) ///
	dec(3)
	}
	
/*
	-> 0) Añadir F-stat
	-> 1) Interacción: mes*controles ; para xtivreg2 
	-> 2) [aw/fw = pob] en lugar de poner población como control
	-> 3) Usar ambos métodos
	
Revisar AI y economía

Revisar la variación en las categorías del intrumento, y filtrar

xtivreg2 lagro_pesc_ganad (inmovilidad = popularity_score), small first fe
*/

global controles1 pob_eco_act pob_estudio_sup manz_transp

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (inmovilidad =popularity_score) , small first
	outreg2 using "$output\inmovilidad_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (cambio_mov =popularity_score), small first
	outreg2 using "$output\cambio_mov_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (com_google =popularity_score), small first
	outreg2 using "$output\com_google_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (super_google =popularity_score), small first
	outreg2 using "$output\super_google_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (parques_google =popularity_score), small first
	outreg2 using "$output\parques_google_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (trans_google =popularity_score), small first
	outreg2 using "$output\trans_google_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (ofic_google =popularity_score), small first
	outreg2 using "$output\ofic_google_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (resid_google =popularity_score), small first
	outreg2 using "$output\resid_google_`var'.xls", excel ///
	replace ctitle("`var2'") stats(coef se) ///
	dec(3) adj
}

/*
xtivreg2 com inmovilidad (inmovilidad = popularity_score), small first fe

ivregress 2sls com $controles1 i.entid_inegi i.fecha (inmovilidad = popularity_score), small first
	
outreg2 using "$output\inmovilidad_com.xls", excel ///
replace ctitle("com") stats(coef se) ///
dec(3) adj addstat(F-weak identification, e(widstat))
*/

*======================*
* MÉTODO 1: Interacción: mes*controles ; para xtivreg2 
*======================*

gen pob_eco_act2 = pob_eco_act*mes
gen pob_estudio_sup2 = pob_estudio_sup*mes
gen manz_transp2 = manz_transp*mes

global controles2 pob_eco_act2 pob_estudio_sup2 manz_transp2

*xtivreg2 lagro_pesc_ganad pob_eco_act2 pob_estudio_sup2 manz_transp2 (inmovilidad=popularity_score), fe small first

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (inmovilidad =popularity_score) , fe small first
	outreg2 using "$output2\inmovilidad_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (cambio_mov =popularity_score), fe small first
	outreg2 using "$output2\cambio_mov_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (com_google =popularity_score), fe small first
	outreg2 using "$output2\com_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (super_google =popularity_score), fe small first
	outreg2 using "$output2\super_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (parques_google =popularity_score), fe small first
	outreg2 using "$output2\parques_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (trans_google =popularity_score), fe small first
	outreg2 using "$output2\trans_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (ofic_google =popularity_score), fe small first
	outreg2 using "$output2\ofic_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (resid_google =popularity_score), fe small first
	outreg2 using "$output2\resid_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

*======================*
* MÉTODO 2: [aw/fw = pob] en lugar de poner población como control
*======================*

*ivregress 2sls lagro_pesc_ganad $controles1 i.entid_inegi i.fecha (inmovilidad =popularity_score) [aw=pob_tot], small first

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (inmovilidad =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\inmovilidad_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (cambio_mov =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\cambio_mov_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (com_google =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\com_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (super_google =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\super_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (parques_google =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\parques_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3)
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (trans_google =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\trans_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (ofic_google =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\ofic_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly ivregress 2sls `var' $controles1 i.entid_inegi i.fecha (resid_google =popularity_score) [aw=pob_tot], small first
	outreg2 using "$output3\resid_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	dec(3) adj
}

*======================*
* MÉTODO 3: Ambos métodos
*======================*

*xtivreg2 lagro_pesc_ganad $controles2 (inmovilidad=popularity_score) [aw=pob_tot], fe small first

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (inmovilidad =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\inmovilidad_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (cambio_mov =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\cambio_mov_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (com_google =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\com_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (super_google =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\super_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (parques_google =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\parques_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (trans_google =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\trans_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (ofic_google =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\ofic_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}

foreach var in lnontrada ltradable lagro_pesc_ganad lcom lconstruc lenergia lmanufact lmineria lserv ltransp lmas50trab lmenos5trab ltrab_6_50 ledad30_50 ledadmas50 ledadmenos30 lhombre lmujer {
	quietly xtivreg2 `var' $controles2 (resid_google =popularity_score) [aw=pob_tot], fe small first
	outreg2 using "$output4\resid_google_`var'.xls", excel ///
	replace ctitle("`var'") stats(coef se) ///
	addstat(F-weak identification, e(widstat)) dec(3) adj
}