*---------------------------------------------------------------*;
* DM.sas creates the SDTM DM and SUPPDM datasets and saves them
* as permanent SAS datasets to the target libref.
*---------------------------------------------------------------*;
%include "D:\SASShare\GitHub\implement-cdisc-using-sas\common.sas";

**** CREATE EMPTY DM DATASET CALLED EMPTY_DM;
%make_empty_dataset(metadatafile=D:\SASShare\GitHub\implement-cdisc-using-sas\appendix-a\SDTM_METADATA.xlsx,dataset=DM)
 
**** GET FIRST AND LAST DOSE DATE FOR RFSTDTC AND RFENDTC;

/*这里首先需要运行程序dosing.sas生成数据集source.dosing，然后执行DM.sas*/
/*数据集dosing中的变量有：subject、startdt、enddt、firstdose、lastdose。*/
proc sort
  data=source.dosing(keep=subject startdt enddt)
  out=dosing;
    by subject startdt;
run;

**** FIRSTDOSE=FIRST DOSING AND LASTDOSE=LAST DOSING;
data dosing;
  set dosing;
    by subject;

    retain firstdose lastdose;

    if first.subject then
      do;
        firstdose = .;
        lastdose = .;
      end;

    firstdose = min(firstdose,startdt,enddt);
    lastdose = max(lastdose,startdt,enddt);

    if last.subject;
run; 
/*1. 创建FIRST.和LAST.变量的前提是数据必须是排好序的。利用SORT排序，BY var。
* 2. 使用SET复制已排好序的数据，用BY语句创建FIRST.和LAST.，BY的对象是第一步排序的变量 var。*/
/*In the DATA step, SAS identifies the beginning and end of each BY group by 
	creating the following two temporary variables for each BY variable: */


**** GET DEMOGRAPHICS DATA;
proc sort
  data=source.demographic
  out=demographic;
    by subject;
run;

**** MERGE DEMOGRAPHICS AND FIRST DOSE DATE;
data demog_dose;
  merge demographic
        dosing;
    by subject;
run;

**** DERIVE THE MAJORITY OF SDTM DM VARIABLES;
options missing = ' ';
data dm;
  set EMPTY_DM
    demog_dose(rename=(race=_race));

    studyid = 'XYZ123';
    domain = 'DM';
    usubjid = left(uniqueid);
    subjid = put(subject,3.); 
    rfstdtc = put(firstdose,yymmdd10.);  
    rfendtc = put(lastdose,yymmdd10.); 
    rfxstdtc = put(firstdose,yymmdd10.);  
    rfxendtc = put(lastdose,yymmdd10.);
    rficdtc = put(icdate,yymmdd10.);
    rfpendtc = put(lastdoc,yymmdd10.);
    dthfl = 'N';
    siteid = substr(subjid,1,1) || "00";
    brthdtc = put(dob,yymmdd10.);
    age = floor ((intck('month',dob,firstdose) - 		/*floor函数：返回小于该值的最大整数。*/
          (day(firstdose) < day(dob))) / 12);			/*day函数： 返回日期中的day，即yyyymmdd中的dd。*/
    if age ne . then
      ageu = 'YEARS';
    sex = put(gender,sex_demographic_gender.);
    race = put(_race,race_demographic_race.);
    armcd = put(trt,armcd_demographic_trt.);
    arm = put(trt,arm_demographic_trt.);
    actarmcd = put(trt,armcd_demographic_trt.);
    actarm = put(trt,arm_demographic_trt.);
    country = "USA"; 
run; 

/*INTCK Function
* 作用：Returns the number of interval boundaries of a given kind that lie between two SAS dates, 
*	times, or timestamp values encodedas DOUBLE. 
*	返回两个给定SAS时间之间的间隔。（计算年龄）
*	
* 语法：INTCK({interval[multiple][.shift-index]}, start-date, end-date[,'method']) 
*	INTCK(start-date, end-date[,'method']) 
*	
* 参数：
* interval： 取值为“WEEK,MONTH, or QTR. ”等。指定一个字符常量，变量，或 表达式。
*/

**** DEFINE SUPPDM FOR OTHER RACE; 
**** CREATE EMPTY SUPPDM DATASET CALLED EMPTY_SUPPDM;
%make_empty_dataset(metadatafile=D:\SASShare\GitHub\implement-cdisc-using-sas\appendix-a\SDTM_METADATA.xlsx,dataset=SUPPDM)

data suppdm;
  set EMPTY_SUPPDM
      dm; 

    keep &SUPPDMKEEPSTRING;  /*  **keepstring 全局宏变量，由%make_empty_dataset 宏程序创建。*/

    **** OUTPUT OTHER RACE AS A SUPPDM VALUE;
    if orace ne '' then
      do;
        rdomain = 'DM';
        qnam = 'RACEOTH';
        qlabel = 'Race, Other';
        qval = left(orace);
        qorig = 'CRF Page 1';
        output;
      end;

    **** OUTPUT RANDOMIZATION DATE AS SUPPDM VALUE;
    if randdt ne . then
      do;
        rdomain = 'DM';
        qnam = 'RANDDTC';
        qlabel = 'Randomization Date';
        qval = left(put(randdt,yymmdd10.));
        qorig = 'CRF Page 1';
        output;
      end;
run;


**** SORT DM ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=D:\SASShare\GitHub\implement-cdisc-using-sas\appendix-a\SDTM_METADATA.xlsx,dataset=DM)

proc sort
  data=dm(keep = &DMKEEPSTRING)
  out=target.dm;
    by &DMSORTSTRING;
run;


**** SORT SUPPDM ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=D:\SASShare\GitHub\implement-cdisc-using-sas\appendix-a\SDTM_METADATA.xlsx,dataset=SUPPDM)

proc sort
  data=suppdm
  out=target.suppdm;
    by &SUPPDMSORTSTRING;
run;
