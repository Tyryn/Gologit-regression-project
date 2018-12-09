clear all
cd "C:\Users\DELL\Documents\Masters\ECO5070S\Project"
global data "C:\Users\DELL\Documents\Masters\ECO5070S\Project\nids-w4-2014-2015-v1.1-stata11"
log using Tyryn_Carnegie_project, replace
//ssc install tabout, replace
use $data\Adult_W4_Anon_V1.1.dta

merge m:1 w4_hhid using $data\hhderived_W4_Anon_V1.1.dta

duplicates report

numlabel, add
set more off

********************************************************************************
***	Variable creation/cleaning
********************************************************************************

** Gender
rename w4_a_gen gender
tab gender, m
recode gender 1=0 2=1
label val gender gender
cap label drop gender
label define gender 0."0. Male" 1."1. Female"
tab gender, m
label var gender "Gender"

** Age

replace w4_a_dob_m=. if w4_a_dob_m==99 | w4_a_dob_m==88
replace w4_a_dob_y=. if w4_a_dob_y==9999
cap drop age
gen age = 2017 - w4_a_dob_y
tab age
label var age "Age"

** Perceived health

rename w4_a_hldes perc_health
tab perc_health, m
replace perc_health=. if perc_health<0
label var perc_health "Perceived health"
recode perc_health 5=1 4=2 1=5 2=4 
label val perc_health perc_health
label define perc_health 1."1. Poor" 2."2. Fair" 3."3. Good" 4."4. Very Good" ///
	5."5. Excellent"

*Creating dummies
gen  byte poor_health =.
replace poor_health=1 if perc_health==5
replace poor_health=0 if perc_health==1 | perc_health==2 | perc_health==3 | perc_health==4 
label var poor_health "Poor health"	
	
gen byte fair_health=.
replace fair_health=1 if perc_health==4
replace fair_health=0 if perc_health==1 | perc_health==2 | perc_health==3 | ///
	perc_health==5
label var fair_health "Fair health"

gen byte good_health=.
replace good_health=1 if perc_health==3
replace good_health=0 if perc_health==1 | perc_health==2 | perc_health==4 | ///
	perc_health==5
label var good_health "Good health"
	
gen byte verygood_health=.
replace verygood_health=1 if perc_health==2
replace verygood_health=0 if perc_health==1 | perc_health==3 | perc_health==4 | ///
	perc_health==5
label var verygood_health "Very good health"
	
gen byte excellent_health=.
replace excellent_health=1 if perc_health==1
replace excellent_health=0 if perc_health==2 | perc_health==3 | perc_health==4 | perc_health==5
label var excellent_health "Excellent health"
	
** Marital status 
//Married and living together considered the same

gen byte marital_status=.
replace marital_status = w4_a_evmar
replace marital_status = 1 if w4_a_mar==1 | w4_a_mar==2
replace marital_status = 2 if w4_a_mar==3 | w4_a_curmarst==2 | ///
	w4_a_curmarst==3
replace marital_status =. if marital_status <0
tab marital_status, m
recode marital_status 2=0

label var marital_status "Marital status"
label val marital_status marital_status
label define marital_status 0"0. Unmarried" 1"1. Married"
tab marital_status, m


** Years married
//Issue is that we are not accounting for partners that have lived together for
//a while, then got married. 

gen byte years_married=.
replace years_married=w4_a_mary_m
replace years_married=w4_a_mary_l if years_married==.
replace years_married=. if years_married<0
tab years_married, m
label var years_married "No. Years Married"


** Race

rename w4_a_popgrp race
tab race, m
replace race=. if race<0
label var race "Race"

*Creating dummies for races
gen byte African=.
replace African=1 if race==1
replace African=0 if race==2 | race==3 | race==4 
label var African "African"

gen byte Coloured=.
replace Coloured=1 if race==2
replace Coloured=0 if race==1 | race==3 | race==4 
label var Coloured "Coloured"

gen byte Asian_Indian=.
replace Asian_Indian=1 if race==3
replace Asian_Indian=0 if race==1 | race==2 | race==4 
label var Asian_Indian "Asian/Indian"

gen byte White=.
replace White=1 if race==4
replace White=0 if race==1 | race==2 | race==3 
label var White "White"

**********************************************************************
** Chronic diseases
***********************************************************************


rename w4_a_hldia diabetes
recode diabetes 2=0 
replace diabetes=. if diabetes<0
label val diabetes diabetes
label define diabetes 0 "0.No" 1 "1.Yes", replace
tab diabetes, m
label var diabetes "Was diagnosed with diabetes"


rename w4_a_hlhrt heart_problems
tab heart_problems, m
replace heart_problems=. if heart_problems<0
recode heart_problems 2=0
label val heart_problems heart_problems
label define heart_problems 0 "0.No" 1 "1.Yes", replace
label var heart_problems "Was diagnosed with heart problems"

rename w4_a_hltb_stl tb
replace tb=. if tb<0
recode tb 2=0
label val tb tb
label define tb 0 "0.No" 1 "1.Yes"
tab tb, m
label var tb "Was diagnosed with TB"

rename w4_a_hlbp blood_pressure
replace blood_pressure=. if blood_pressure<0
recode blood_pressure 2=0.
label val blood_pressure blood_pressure
label define blood_pressure 0."0.No" 1."1.Yes"
tab blood_pressure, m
label var blood_pressure "Was diagnosed with high blood pressure"


rename  w4_a_hlast asthma
replace asthma=. if asthma<0
recode asthma 2=0 
label val asthma astma
label define asthma 0."0.No" 1."1.Yes"
tab asthma, m
label var asthma "Was diagnosed with asthma"

cap drop diseased
gen byte diseased =.
foreach i in diabetes-asthma{
replace diseased=1 if `i'==1
}
replace diseased=0 if diabetes==0 & heart_problems==0 & ///
	blood_pressure==0 & asthma==0    //Left out tb as it has so many missing values

** Expenditure //Rocco Zizzamia, Simone Schotte, Murray Leibbrandt and Vimal Ranchhod
/*
rename w4_expenditure expenditure
gen byte exp_cat =.
replace exp_cat = 1 if expenditure < 1283
replace exp_cat = 2 if expenditure > 1283 & expenditure < 3104
replace exp_cat = 3 if expenditure > 3104 & expenditure < 10387
replace exp_cat = 4 if expenditure > 10387

label val exp_cat exp_cat
label define exp_cat 1."1. Poor" 2."2.Vulnerable" 3."3.Middle Class" ///
	4."4.Elite"
label var exp_cat "Household expenditure categories"
label var expenditure "Household expenditure"

tab exp_cat, m

gen byte poor =.
replace poor=1 if exp_cat==1
replace poor=0 if exp_cat!=1 & exp_cat!=.

gen byte vulnerable =.
replace vulnerable=1 if exp_cat==2
replace vulnerable=0 if exp_cat!=2 & exp_cat!=.

gen byte middle_class =.
replace middle_class=1 if exp_cat==3
replace middle_class=0 if exp_cat!=3 & exp_cat!=.

gen byte elite =.
replace elite=1 if exp_cat==4
replace elite=0 if exp_cat!=4 & exp_cat!=.

label var poor "Poor"
label var vulnerable "Vulnerable"
label var middle_class "Middle class"
label var elite "Elite" 
*/


** Income //Rocco Zizzamia, Simone Schotte, Murray Leibbrandt and Vimal Ranchhod

rename w4_pi_hhincome hh_income
label var hh_income "Household income" 
cap drop hh_count
gen hh_count = 1
egen hh_count1 = count(hh_count), by(w4_hhid)
gen hh_income_pc=.
replace hh_income_pc = hh_income/hh_count1

gen byte income_cat =.
replace income_cat = 1 if hh_income_pc <= 1283
replace income_cat = 2 if hh_income_pc > 1283 & hh_income_pc <= 3104
replace income_cat = 3 if hh_income_pc > 3104 & hh_income_pc <= 10387
replace income_cat = 4 if hh_income_pc > 10387

label val income_cat income_cat
label define income_cat 1."1. Poor" 2."2.Vulnerable" 3."3.Middle Class" ///
	4."4.Elite"
label var income_cat "Household income categories"


gen byte poor =.
replace poor=1 if income_cat==1
replace poor=0 if income_cat!=1 & income_cat!=.

gen byte vulnerable =.
replace vulnerable=1 if income_cat==2
replace vulnerable=0 if income_cat!=2 & income_cat!=.

gen byte middle_class =.
replace middle_class=1 if income_cat==3
replace middle_class=0 if income_cat!=3 & income_cat!=.

gen byte elite =.
replace elite=1 if income_cat==4
replace elite=0 if income_cat!=4 & income_cat!=.

label var poor "Poor"
label var vulnerable "Vulnerable"
label var middle_class "Middle class"
label var elite "Elite" 


** Life satisfaction/level of happiness
 
rename w4_a_wbsat satisfaction
tab satisfaction, m
replace satisfaction=. if satisfaction<0
recode satisfaction 2=1 3=2 4=2 5=3 6=3 7=4 8=4 9=5 10=5
label var satisfaction "Life satisfaction out of 5"
label define satisfaction 1."1.Poor" 2."2.Fair" 3."3.Good" 4."4.Very good" ///
	5."5.Excellent"

*Create dummies out of 5
gen poor_sat =.
replace poor_sat=1 if satisfaction==1 | satisfaction==2
replace poor_sat=0 if satisfaction==3 | satisfaction==4 | satisfaction==5 | ///
	satisfaction==6 | satisfaction==7 | satisfaction==8 | satisfaction==9 | ///
	satisfaction==10
label var poor_sat "Poor life satisfaction"

	
gen fair_sat=.
replace fair_sat=1 if satisfaction==3 | satisfaction==4
replace fair_sat=0 if satisfaction==1 | satisfaction==2 | satisfaction==5 | ///
	satisfaction==6 | satisfaction==7 | satisfaction==8 | satisfaction==9 | ///
	satisfaction==10
label var fair_sat "Fair life satisfaction"

gen good_sat=.
replace good_sat=1 if satisfaction==5 | satisfaction==6
replace good_sat=0 if satisfaction==1 | satisfaction==2 | satisfaction==3 | ///
	satisfaction==4 | satisfaction==7 | satisfaction==8 | satisfaction==9 | ///
	satisfaction==10
label var good_sat "Good life satisfaction"

gen verygood_sat=.
replace verygood_sat=1 if satisfaction==7 | satisfaction==8
replace verygood_sat=0 if satisfaction==1 | satisfaction==2 | satisfaction==3 | ///
	satisfaction==4 | satisfaction==5 | satisfaction==6 | satisfaction==9 | ///
	satisfaction==10
label var verygood_sat "Very good life satisfaction"
	
gen excellent_sat=.
replace excellent_sat=1 if satisfaction==9 | satisfaction==10
replace excellent_sat=0 if satisfaction==1 | satisfaction==2 | satisfaction==3 | ///
	satisfaction==4 | satisfaction==5 | satisfaction==6 | satisfaction==8 | ///
	satisfaction==9
label var excellent_sat "Excellent life satisfaction"

** Depressed?

gen depressed=. 
replace depressed=1 if w4_a_emodep==3 | w4_a_emodep==4
replace depressed=0 if w4_a_emodep==1 | w4_a_emodep==2
label var depressed "Felt depressed in past week"
label val depressed depressed
label define depressed 0."0.At most little depression" 1."1.At least moderate depression"

** Disability/ other

rename w4_a_hlser disability
recode disability 2=0
replace disability=. if disability<0
label val disability disability
label define disability 0."0.No" 1."1.Yes"
tab disability, m
label var disability "Respondent has a disability"

** BMI
rename  w4_a_height_1 height
replace height=. if height<=0
assert height>0
replace height = height/100

rename w4_a_weight_1 weight
replace weight=. if weight<=0
assert weight>0
tab weight

gen bmi = weight/(height^2)
label var bmi "Respondent's BMI"

*Creating a factor variable for "overweight, underweight etc"
* https://www.cdc.gov/healthyweight/assessing/bmi/adult_bmi/index.html

gen bmi_cat =.
replace bmi_cat =2 if bmi< 18.5
replace bmi_cat =1 if bmi>=18.5 & bmi<25
replace bmi_cat =3 if bmi>=25 & bmi<30
replace bmi_cat =4 if bmi>=30 

label val bmi_cat bmi_cat
label define bmi_cat 1."1.Healthy" 2."2.Underweight" 3."3.Overweight" 4."4.Obese"
label var bmi_cat "BMI categories"

** Exercise
 
gen exercise=.
replace exercise=0 if w4_a_hllfexer==1 | w4_a_hllfexer==2
replace exercise=1 if w4_a_hllfexer==3 | w4_a_hllfexer==4 | w4_a_hllfexer==5
label var exercise "Regularly exercises"
label val exercise exercise
label def exercise 0."0.Doesn't exercise" 1."1.Regularly exercises"

 
*Creating dummies for proportions

gen never_exercise=.
replace never_exercise=1 if w4_a_hllfexer==1
replace never_exercise=0 if w4_a_hllfexer==2 | w4_a_hllfexer==3 | w4_a_hllfexer==4 | w4_a_hllfexer==5
label var never_exercise "Never"

gen lessthanonceweek_exercise=.
replace lessthanonceweek_exercise=1 if w4_a_hllfexer==2
replace lessthanonceweek_exercise=0 if w4_a_hllfexer==1 | w4_a_hllfexer==3 | w4_a_hllfexer==4 | w4_a_hllfexer==5
label var lessthanonceweek_exercise "Less than once a week"

gen onceweek_exercise=.
replace onceweek_exercise=1 if w4_a_hllfexer==3
replace onceweek_exercise=0 if w4_a_hllfexer==1 | w4_a_hllfexer==2 | w4_a_hllfexer==4 | w4_a_hllfexer==5
label var onceweek_exercise "Once a week"

gen twiceweek_exercise=.
replace twiceweek_exercise=1 if w4_a_hllfexer==4
replace twiceweek_exercise=0 if w4_a_hllfexer==1 | w4_a_hllfexer==2 | w4_a_hllfexer==3 | w4_a_hllfexer==5
label var twiceweek_exercise "Twice a week"

gen thriceweek_exercise=.
replace thriceweek_exercise=1 if w4_a_hllfexer==5
replace thriceweek_exercise=0 if w4_a_hllfexer==1 | w4_a_hllfexer==2 | w4_a_hllfexer==3 | w4_a_hllfexer==4
label var thriceweek_exercise "Three times a week or more"

** Medical aid // makes sense maybe its cheaper to get med. aid if married?
 
rename w4_a_hlmedaid medical_aid
recode medical_aid 2=0
label val medical_aid medical_aid
label define medical_aid 0."0.No" 1."1.Yes"
replace medical_aid=. if medical_aid<0
tab medical_aid, m
label var medical_aid "Respondent has medical aid"
 
** Education

tab w4_a_edschgrd
rename w4_a_edschgrd school
replace school=. if school<0 | school==24
tab school, m
recode school 13=10 14=11 15=12 25=0 //https://educonnect.co.za/national-technical-certificate/#1477647482221-a1d2a4a3-7ff7


tab w4_a_edterlev, m
rename w4_a_edterlev hi_educ
replace hi_educ=. if hi_educ<0 | hi_educ==24
tab hi_educ, m

cap drop years_educ
gen years_educ = hi_educ
replace years_educ= school if hi_educ==.

tab years_educ, m
tab hi_educ, m
recode years_educ 13=10 14=11 15=12 16=12 17=12 18=13 19=13 20=15 21=16 22=16 ///
	23=17
	
tab years_educ, m
label var years_educ "No. of years completed education"

gen educ_cat=.
replace educ_cat=0 if years_educ==0
replace educ_cat=1 if years_educ>=1 & years_educ<=7
replace educ_cat=2 if years_educ>=8 & years_educ<12
replace educ_cat=3 if years_educ==12
replace educ_cat=4 if years_educ>12 & years_educ!=.
label val educ_cat educ_cat
label define educ_cat 0."0.No years of education" 1."1.Primary school" ///
	2."2.High school, no matric" 3."3.Matric" 4."4.Tertiary education"
label var educ_cat "Highest education in categories"


cap drop no_educ
gen no_educ =.
replace no_educ =1 if years_educ==0
replace no_educ =0 if years_educ>=1 & years_educ!=.
label var no_educ "No years of education"
tab no_educ, m

cap drop primary_educ
gen primary_educ =.
replace primary_educ =1 if years_educ>=1 & years_educ<=7
replace primary_educ =0 if years_educ>7 & years_educ!=. | years_educ==0
label var primary_educ "Primary school education"
tab primary_educ, m

cap drop highschool_educ
gen highschool_educ=.
replace highschool_educ=1 if years_educ>=8 & years_educ<12
replace highschool_educ =0 if  years_educ<=7 & years_educ!=.  
replace highschool_educ =0 if  years_educ>11 & years_educ!=.  
label var highschool_educ "High school education, no matric"
tab highschool_educ, m

gen matric_educ =.
replace matric_educ =1 if years_educ==12
replace matric_educ =0 if years_educ!=12 & years_educ!=.
label var matric_educ "Completed matric"

cap drop tertiary_educ
gen tertiary_educ =.
replace tertiary_educ =1 if years_educ>12 & years_educ!=.
replace tertiary_educ =0 if years_educ<=12 
label var tertiary_educ "Tertiary education"
tab tertiary_educ, m

** 
cap drop urban
tab w4_geo2011, m
gen urban =.
replace urban =1 if w4_geo2011==2
replace urban=0 if w4_geo2011==1 | w4_geo2011==3
label var  urban "Urban"


/*
** Children over 30 living with parents 

cap drop adult_child
gen adult_child=.
forvalue i = 1(1)17 {
replace adult_child=1 if w4_a_bhmem`i'==1 & w4_a_bhdob_y`i' <= 1985

}
replace adult_child=0 if w4_a_bhlive==2 
tab adult_child, m
label var adult_child "Child over 30 at home"
*/




**************************************************************************
** 	Summary statistics (Like Goldman et al)
**************************************************************************
//Can't use categorical variables race sector. Can use ordinals 
order marital_status gender age poor_health fair_health good_health ///
	verygood_health excellent_health ///
	diabetes heart_problems tb blood_pressure ///
	asthma disability bmi never_exercise ///
	lessthanonceweek_exercise onceweek_exercise twiceweek_exercise ///
	thriceweek_exercise depressed medical_aid poor vulnerable ///
	middle_class elite no_educ primary_educ highschool_educ ///
	matric_educ tertiary_educ urban African Coloured Asian_Indian White 


preserve 
keep if marital_status==1

eststo total: estpost summarize age-White [aw=w4_wgt]
eststo male: estpost summarize age-White if gender==0 [aw=w4_wgt]
eststo female: estpost summarize age-White if gender==1 [aw=w4_wgt]

esttab total male female using married1.rtf, replace label main(mean %6.2f) aux(count) mtitle("Total sample" "Male" "Female")
eststo clear
restore


preserve 
keep if marital_status==0

eststo total: estpost summarize age-White [aw=w4_wgt]
eststo male: estpost summarize age-White if gender==0 [aw=w4_wgt]
eststo female: estpost summarize age-White if gender==1 [aw=w4_wgt]

esttab total male female using unmarried1.rtf, replace label main(mean %6.2f) aux(count) mtitle("Total sample" "Male" "Female")
eststo clear
restore




****************************************************************************
** Ordinal logit
****************************************************************************

/* First looking at the ordinary ordinal logit model, we find that it violates
	the parallel lines assumption. So we use the generalised ordinal logit (gologit)
	but find that it's coefficients on marriage are insignificant. */




svyset pid [pweight = w4_wgt]

//Base category of bmi changed to healthy to make interpretation easier.
//fvset base 2 bmi_cat
/*Setting the base category to two actually messes up the marginal interpretations.*/

** Full sample
/*Auto was initially used. After finding out which variables were constrained,
	I manually did so to make the compution faster. */
	
/*We find that the gologit fixes the parallel assumption for the model restricted
	to males and to females but not when looking at the full sample */

ologit perc_health marital_status age gender diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat medical_aid urban, robust cluster(w4_hhid)


brant, detail

/* Cannot use Brant test along with AIC, BIC and Chi-square test when survey 
	weights are used. However the Wald tests used in the gologit2 does work.
	(Richard Williams, 2016)*/

	
****************************************************************************
** Generalised ordinal logit
****************************************************************************	
/*Using gologit2, we can (a) reproduce ologit’s estimates by using the pl parameter, i.e.
estimate a model in which all variables are constrained to meet the proportional odds/ parallel
regressions/ parallel lines assumption, (b) estimate a model (gologit2’s default) in which no
variables have to meet the parallel lines assumption (c) do a global likelihood ratio chi-square
test of the parallel lines assumption, and (d) use autofit to estimate a model in which some
variables are constrained to meet the parallel lines assumption while others are not.
I'm going to use the gologit default with autofit. */	
	
gologit2 perc_health marital_status age gender diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid urban [pweight=w4_wgt],  ///
	robust cluster(w4_hhid) ///
	pl(0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 4.race 1b.income_cat 2.income_cat ///
	3.income_cat 4.income_cat marital_status diseased gender medical_aid)

//	auto force technique(BHHH DFP BFGS nr) difficult - used to get unconstrained covariates.

outreg2 using gologit.doc, replace ctitle(Generalised ordinal logit: All) label


**Males

gologit2 perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid urban ///
	if gender==0 [pweight=w4_wgt], robust cluster(w4_hhid) ///
	pl(0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 4.race 1b.income_cat 2.income_cat ///
	3.income_cat 4.income_cat marital_status diseased gender medical_aid)

outreg2 using malelogit.doc, replace ctitle(Generalised ordinal logit: Males) label


**Females

gologit2 perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid urban if gender ==1 ///
	[pweight=w4_wgt], robust cluster(w4_hhid) ///	
	technique(BHHH DFP BFGS nr) force  ///
	pl(1b.income_cat 2.income_cat 3.income_cat 4.income_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 0b.educ_cat 1.educ_cat 2.educ_cat ///
	3.educ_cat 4.educ_cat medical_aid exercise marital_status disability) 

outreg2 using femalelogit.doc, replace ctitle(Generalised ordinal logit: Females) label



/*
*****	Testing model if we change perceived health to three categories

tab perc_health
gen perc_health2 = .
replace perc_health2 =1 if perc_health==1 | perc_health==2
replace perc_health2 = 2 if perc_health==3
replace perc_health2 = 3 if perc_health==4 | perc_health==5
label val perc_health2 perc_health2
label var perc_health2 "Perceived health: 3 cat."
label define 1."1. Poor health" 2."2.Fair health" 3."3.Good health"


ologit perc_health2 marital_status age gender diseased i.bmi_cat iexercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid
outreg2 using 3cat_ologit.doc, append ctitle(Ordinal logit: Perceived health in three categories) label
	
	
oparallel, ic //still fails
*/


**************************************************************
* Marginal effects at the means
**************************************************************



/* This is going to take a lot of time. Unfortunately post requires the gologit
	to be run each time. I need post to use outreg2. Double checking the 
	estimates can be done a lot quicker by getting rid of the post on each
	margin command line, taking the gologit out the loop, running, 
	and then checking the results window.*/

	
*************** Generalized ordinal logits ************************
/*
** All
svy: gologit2 perc_health marital_status age gender diseased i.bmi_cat exercise ///
 depressed i.race i.income_cat i.educ_cat disability medical_aid urban, ///
 pl(0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 4.race 1b.income_cat 2.income_cat ///
	3.income_cat 4.income_cat marital_status diseased gender medical_aid)
margins , dydx(marital_status age gender diseased i.bmi_cat exercise ///
 depressed i.race i.income_cat i.educ_cat disability medical_aid) ///
 predict(outcome(1))  atmeans post
 estimates store herearemargins1
outreg2 herearemargins1 using allmargins.doc, replace ctitle(Marginal effect: All) label
forvalue i = 2(1)5 {
svy: quietly gologit2 perc_health marital_status age gender diseased i.bmi_cat exercise ///
 depressed i.race i.income_cat i.educ_cat  disability medical_aid, ///
pl(0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 4.race 1b.income_cat 2.income_cat ///
	3.income_cat 4.income_cat marital_status diseased gender medical_aid)
margins , dydx(marital_status age gender diseased i.bmi_cat exercise ///
depressed i.race i.income_cat i.educ_cat  disability medical_aid ) ///
predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using allmargins.doc, append ctitle(Marginal effect: All) label
}



** Male
cap drop herearemargins*
gsvy: gologit2 perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat  disability medical_aid  if gender==0, ///
	pl(1b.race 2.race 1b.bmi_cat 3.bmi_cat 4.bmi_cat 1b.income_cat ///
	2.income_cat 3.income_cat 4.income_cat 0b.educ_cat 1.educ_cat ///
	2.educ_cat 3.educ_cat 4.educ_cat marital_status exercise disability diseased)
margins , dydx(marital_status age diseased i.bmi_cat exercise depressed ///
	i.race i.income_cat i.educ_cat  disability medical_aid ) predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using malemargins.doc, replace ctitle(Marginal effect: Male) label

forvalue i = 2(1)5 {
svy: quietly gologit2 perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat  disability medical_aid  if gender==0, ///
	pl(1b.race 2.race 1b.bmi_cat 3.bmi_cat 4.bmi_cat 1b.income_cat ///
	2.income_cat 3.income_cat 4.income_cat 0b.educ_cat 1.educ_cat ///
	2.educ_cat 3.educ_cat 4.educ_cat marital_status exercise disability diseased)
margins , dydx(marital_status age diseased ib2.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat  disability medical_aid ) ///
	predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using malemargins.doc, append ctitle(Marginal effect: Male) label
}



** Female
cap drop herearemargins*
svy: quietly gologit2 perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat  disability medical_aid  if gender==1, ///
	pl(1b.income_cat 2.income_cat 3.income_cat 4.income_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 4.race 0b.educ_cat 1.educ_cat ///
	2.educ_cat 3.educ_cat 4.educ_cat diseased marital_status exercise)

margins , dydx(marital_status age diseased i.bmi_cat exercise depressed ///
	i.race i.income_cat i.educ_cat  disability medical_aid ) predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using femalemargins.doc, ///
	replace ctitle(Marginal effect: Female) label
forvalue i = 2(1)5 {   
svy: quietly gologit2 perc_health marital_status age diseased i.bmi_cat ///
	exercise depressed i.race i.income_cat i.educ_cat  disability medical_aid  ///
	if gender==1, ///
	pl(1b.income_cat 2.income_cat 3.income_cat 4.income_cat 1b.bmi_cat ///
	3.bmi_cat 4.bmi_cat 1b.race 2.race 4.race 0b.educ_cat 1.educ_cat ///
	2.educ_cat 3.educ_cat 4.educ_cat diseased marital_status exercise)
margins , dydx(marital_status age diseased i.bmi_cat exercise depressed ///
	i.race i.income_cat i.educ_cat  disability medical_aid ) predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using femalemargins.doc, ///
	append ctitle(Marginal effect: Female) label
}


/*
***********		Ordinal logit	******************************************
*This section was produced just in order to check the marginal effects if we used
* an ologit instead */


svy: ologit perc_health marital_status age gender diseased i.bmi_cat exercise ///
 depressed i.race i.income_cat i.educ_cat  disability disability medical_aid 
margins , dydx(marital_status age gender diseased ib2.bmi_cat exercise ///
 depressed i.race i.income_cat i.educ_cat  disability disability medical_aid ) ///
 predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using allologitmargins.doc, replace ctitle(Marginal effect: All) label

forvalue i = 2(1)5 {
svy: quietly ologit perc_health marital_status age gender diseased i.bmi_cat exercise ///
 depressed i.race i.income_cat i.educ_cat disability medical_aid 
margins , dydx(marital_status age gender diseased i.bmi_cat exercise ///
depressed i.race i.income_cat i.educ_cat disability medical_aid ) ///
predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using allologitmargins.doc, append ctitle(Marginal effect: All) label
}

** Male
cap drop herearemargins*
svy: quietly ologit2 perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid  if gender==0
margins , dydx(marital_status age diseased i.bmi_cat exercise depressed ///
	i.race i.income_cat i.educ_cat disability) predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using maleologitmargins.doc, replace ctitle(Marginal effect: Male) label
forvalue i = 2(1)5 {
svy: quietly ologit perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid  if gender==0
margins , dydx(marital_status age diseased ib2.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid ) ///
	predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using maleologitmargins.doc, append ctitle(Marginal effect: Male) label
}


** Female
cap drop herearemargins*
svy: quietly ologit perc_health marital_status age diseased i.bmi_cat exercise ///
	depressed i.race i.income_cat i.educ_cat disability medical_aid  if gender==1, ///

margins , dydx(marital_status age diseased i.bmi_cat exercise depressed ///
	i.race i.income_cat i.educ_cat disability medical_aid ) predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using femaleologitmargins.doc, ///
	replace ctitle(Marginal effect: Female) label
forvalue i = 2(1)5 {   
svy: quietly ologit perc_health marital_status age  diseased i.bmi_cat ///
	exercise depressed i.race i.income_cat i.educ_cat disability medical_aid  ///
	if gender==1
margins , dydx(marital_status age diseased i.bmi_cat exercise depressed ///
	i.race i.income_cat i.educ_cat disability medical_aid ) predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using femaleologitmargins.doc, ///
	append ctitle(Marginal effect: Female) label
}

*/





********************************************************************************
**	Models without health variables 
********************************************************************************

** Gologit

* All
gologit2 perc_health marital_status age gender ///
  i.race i.income_cat i.educ_cat  [pweight=w4_wgt],  ///
	robust cluster(w4_hhid) ///
	pl(1b.race 2.race 3.race 4.race 1b.income_cat 2.income_cat 3.income_cat ///
	4.income_cat 0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat ///
	gender marital_status)
//	auto force technique(BHHH DFP BFGS nr) difficult - used to get unconstrained covariates.
outreg2 using allnohealth.doc, replace ctitle(Generalised ordinal logit: All) label
estat gof 
* Male
gologit2 perc_health marital_status age ///
  i.race i.income_cat i.educ_cat  [pweight=w4_wgt] if gender==0,  ///
	robust cluster(w4_hhid) ///
	pl(1b.income_cat 2.income_cat 3.income_cat 4.income_cat ///
	1b.race 2.race 4.race 0b.educ_cat 1.educ_cat 2.educ_cat ///
	3.educ_cat marital_status)
outreg2 using malenohealth.doc, replace ctitle(Generalised ordinal logit: All) label
estat gof 

* Female
gologit2 perc_health marital_status age ///
  i.race i.income_cat i.educ_cat  [pweight=w4_wgt] if gender==1,  ///
	robust cluster(w4_hhid) ///
	pl(1b.race 2.race 3.race 4.race 1b.income_cat 2.income_cat 3.income_cat ///
	0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat age ///
	marital_status)
outreg2 using femalenohealth.doc, replace ctitle(Generalised ordinal logit: All) label
estat gof 

/*
** Marginal effects at the means
** All
cap drop herearemargins*
quietly gologit2 perc_health marital_status age gender ///
  i.race i.income_cat i.educ_cat [pweight=w4_wgt], ///
	robust cluster(w4_hhid) ///
	pl(1b.race 2.race 3.race 4.race 1b.income_cat 2.income_cat 3.income_cat ///
	4.income_cat 0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat ///
	gender marital_status)
margins , dydx(marital_status age gender ///
  i.race i.income_cat i.educ_cat ) ///
 predict(outcome(1))  atmeans post
 estimates store herearemargins1
outreg2 herearemargins1 using allnohealthmargins.doc, replace ctitle(Marginal effect: All) label
forvalue i = 2(1)5 {
quietly gologit2 perc_health marital_status age gender ///
  i.race i.income_cat i.educ_cat [pweight=w4_wgt], ///
	robust cluster(w4_hhid) ///
	pl(1b.race 2.race 3.race 4.race 1b.income_cat 2.income_cat 3.income_cat ///
	4.income_cat 0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat ///
	gender marital_status)
margins , dydx(marital_status age gender ///
  i.race i.income_cat i.educ_cat ) ///
predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using allnohealthmargins.doc, append ctitle(Marginal effect: All) label
}
*/




** Male
cap drop herearemargins*
quietly gologit2  perc_health marital_status age  ///
  i.race i.income_cat i.educ_cat  [pweight=w4_wgt] if gender==0, ///
	robust cluster(w4_hhid) ///
	pl(1b.income_cat 2.income_cat 3.income_cat 4.income_cat ///
	1b.race 2.race 4.race 0b.educ_cat 1.educ_cat 2.educ_cat ///
	3.educ_cat marital_status)  ///
margins, dydx(marital_status age i.race i.income_cat i.educ_cat) predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using malenohealthmargins.doc, replace ctitle(Marginal effect: Male) label
forvalue i = 2(1)5 {
quietly gologit2 perc_health marital_status age  ///
  i.race i.income_cat i.educ_cat [pweight=w4_wgt] if gender==0, ///
	robust cluster(w4_hhid) ///
	pl(1b.income_cat 2.income_cat 3.income_cat 4.income_cat ///
	1b.race 2.race 4.race 0b.educ_cat 1.educ_cat 2.educ_cat ///
	3.educ_cat marital_status)
margins , dydx(marital_status age  ///
  i.race i.income_cat i.educ_cat) ///
	predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using malenohealthmargins.doc, append ctitle(Marginal effect: Male) label
}




/*
** Female
cap drop herearemargins*
quietly gologit2 perc_health marital_status age ///
  i.race i.income_cat i.educ_cat medical_aid [pweight=w4_wgt] if gender==1, ///
	pl(medical_aid 1b.race 2.race 3.race 4.race 1b.income_cat 2.income_cat ///
	3.income_cat 0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat marital_status)
margins , dydx(marital_status age  ///
  i.race i.income_cat i.educ_cat ) predict(outcome(1))  atmeans post
estimates store herearemargins1
outreg2 herearemargins1 using femalenohealthmargins.doc, ///
	replace ctitle(Marginal effect: Female) label
forvalue i = 2(1)5 {   
quietly gologit2 perc_health marital_status age ///
  i.race i.income_cat i.educ_cat [pweight=w4_wgt] if gender==1, ///
	robust cluster(w4_hhid) ///
	pl(1b.race 2.race 3.race 4.race 1b.income_cat 2.income_cat 3.income_cat ///
	0b.educ_cat 1.educ_cat 2.educ_cat 3.educ_cat 4.educ_cat age ///
	marital_status)
margins , dydx(marital_status age  ///
  i.race i.income_cat i.educ_cat) predict(outcome(`i'))  atmeans post
estimates store herearemargins`i'
outreg2 herearemargins`i' using femalenohealthmargins.doc, ///
	append ctitle(Marginal effect: Female) label
}
*/
*******************************************************************************
log close

exit


















