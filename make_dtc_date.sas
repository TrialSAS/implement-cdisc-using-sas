*---------------------------------------------------------------*;
* make_dtc_date.sas is a SAS macro that creates a SDTM --DTC date
* within a SAS datastep when provided the pieces of the date in 
* separate SAS variables.
*
* NOTE: This macro must have SAS OPTIONS MISSING = ' ' set before 
* it is called to handle missing date parts properly.
*
* MACRO PARAMETERsS:
* dtcdate = SDTM --DTC date variable desired
* year = year variable
* month = month variable 
* day = day variable
* hour = hour variable
* minute = minute variable 
* second = second variable
*---------------------------------------------------------------*; 
%macro make_dtc_date(dtcdate=, year=., month=., day=., 
                     hour=., minute=., second=.); 

    ** in a series of if-then-else statements, determine where the
    ** smallest unit of date and time is present and then construct a DTC
    ** date based on the non-missing date variables.;

    if (&second ne .) then 
		/*全有： year，month，day，hour，minute，second */
		/* YYYY-MM-DDTHH:MM:SS */
		/* 2002-07-11T07:30:20 */
        &dtcdate = put(&year,z4.) || "-" || put(&month,z2.) || "-" 
                           || put(&day,z2.) || "T" || put(&hour,z2.) || ":" 
                           || put(&minute,z2.) || ":" || put(&second,z2.); 
						   
    else if (&minute ne .) then 
	
		/*只有： year，month，day，hour，minute 。	没有second 	*/
		/* YYYY-MM-DDTHH:MM */
		/* 2002-07-11T07:30 */
        &dtcdate = put(&year,z4.) || "-" || put(&month,z2.) || "-" 
                           || put(&day,z2.) || "T" || put(&hour,z2.) || ":" 
                           || put(&minute,z2.); 
						   
    else if (&hour ne .) then 
	
		/*只有； year，month，day，hour。 没有：minute，second	*/
        &dtcdate = put(&year,z4.) || "-" || put(&month,z2.) || "-" 
                           || put(&day,z2.) || "T" || put(&hour,z2.); 
						   
    else if (&day ne .) then 
	
		/*只有： year，month，day。 	没有：hour，minute，second */
		/*YYYY-MM-DD*/
		/*2009-02-13*/
        &dtcdate = put(&year,z4.) || "-" || put(&month,z2.) || "-" 
                           || put(&day,z2.); 
						   
    else if (&month ne .) then 
	
		/*只有： year，month。		没有： day，hour，minute，second	*/
        &dtcdate = put(&year,z4.) || "-" || put(&month,z2.); 
		
    else if (&year ne .) then 
	
		/*只有：	year。	没有：month，day，hour，minute，second*/
        &dtcdate = put(&year,z4.); 
		
    else if (&year = .) then 
	
        &dtcdate = ""; 

    ** remove duplicate blanks and replace space with a dash;
	/*删除重复的空格，并使用 破折号 代替 空格。*/
    if &dtcdate ne "" then
        &dtcdate = translate(trim(compbl(&dtcdate)),'-',' ');
		/*translate(source，to，from) 将空格替换为”-“。*/
%mend make_dtc_date;


/*COMPBL Function
语法： COMPBL(character-expression) 
功能： Removes multiple blanks from a character string.
	移除字符串中重复的空格。
	
例如：select compbl('January     Status');
结果：January Status
*/

/*TRIM Function
语法：TRIM([BOTH | LEADING | TRAILING] [trim-character] FROM column) 
功能：Removes leading characters, trailing characters,or both from a character string. 
	移除首尾空格。
*/

/*translate Function
语法：TRANSLATE(source, to-1, from-1 <, ...to-n, from-n>) 
功能：Replaces specific characters in a character expression.
	将source中的from字符替换为to字符。
	
参数解析：Required Arguments

source：
specifies a characterconstant, variable, or expression that contains the original characterstring. 

to：
specifies the charactersthat you want TRANSLATE to use as substitutes. 

from：
specifies the charactersthat you want TRANSLATE to replace. 



例如：
data new;                                                                                                                                
   x=translate('XYZW', 'AB', 'VW');                                                                                                       
   string1='AABBAABABB';                                                                                                                  
   y=translate(string1,'12','AB');                                                                                                        
   put x=;
   put y=;                                                                                                                             
run;
结果：
x=XYZB
y=1122112122
*/
