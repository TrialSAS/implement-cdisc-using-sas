*---------------------------------------------------------------*;
* make_sdtm_dy.sas is a SAS macro that takes two SDTM --DTC dates
* and calculates a SDTM study day (--DY) variable. It must be used
* in a datastep that has both the REFDATE and DATE variables 
* specified in the macro parameters below.
* MACRO PARAMETERS:
* refdate = --DTC baseline date to calculate the --DY from.  
*           This should be DM.RFSTDTC for SDTM --DY variables.
* date = --DTC date to calculate the --DY to.  The variable
*          associated with the --DY variable.
*---------------------------------------------------------------*;
/*例如，date = LBDTC = 2006-08-01T07:45 。 RFSTDTC=2006-01-12	*/

%macro make_sdtm_dy(refdate=RFSTDTC,date=); 

    if length(&date) >= 10 and length(&refdate) >= 10 then
      do;
        if input(substr(%substr("&date",2,%length(&date)-3)dtc,1,10),yymmdd10.) >= 
           input(substr(%substr("&refdate",2,%length(&refdate)-3)dtc,1,10),yymmdd10.) then
          %upcase(%substr("&date",2,%length(&date)-3))DY = input(substr(%substr("&date",2,%length(&date)-3)dtc,1,10),yymmdd10.) - 
          input(substr(%substr("&refdate",2,%length(&refdate)-3)dtc,1,10),yymmdd10.) + 1;
        else
          %upcase(%substr("&date",2,%length(&date)-3))DY = input(substr(%substr("&date",2,%length(&date)-3)dtc,1,10),yymmdd10.) - 
          input(substr(%substr("&refdate",2,%length(&refdate)-3)dtc,1,10),yymmdd10.);  
      end;

%mend make_sdtm_dy;    

/*SUBSTR Function
其中，SUBSTR (left of =) Function
表示：Replaces a substring of content in a character variable.
	代替一个字符变量中一个子字符串的内容。
SUBSTR (character-variable, position-expression [, length-expression]) = characters-to-replace
例如：
 mystring='kidnap';
	  substr(mystring, 1, 3)='cat';
	  put mystring=;
结果：mystring=catnap



其中，SUBSTR (right of =) Function
表示：Returns a substring, allowing a result with a length of zero.
	返回一个子字符串。
SUBSTR(character-expression, position-expression [, length-expression])
例如：
 a='chsh234960b3';
	  b=substr(a,5);
	  put b;
结果：234960b3
*/


/*input Function
语法：INPUT(source, <? | ??> informat.) 
作用：Returns the value that is produced when SAS converts an expression by using the specified informat. 
	
参数解析：Required Arguments

source
specifies a characterconstant, variable, or expression to which you want to apply a specific informat. 

? or ??
specifies the optional question mark (?) and double question mark (??) modifiers 
that suppress the printing of notes and input lines when invalid data values are read. 
使用问好？修饰符，在读取到无效数据时候，禁止打印note和 input lines。
The ? modifier suppresses the invalid data message. The ?? modifier suppresses the invalid data message 
and prevents the automatic variable_ERROR_ from being set to 1 when invalid data is read. 

informat.
is the SAS informatthat you want to apply to the source. This argument must be the nameof an informat followed by a period. The argument cannot be a characterconstant, variable, or expression. 


例如：
data one;                                                                                                                               
   numdate=122591;                                                                                                                        
   chardate=put(numdate, z6.);                                                                                                            
   sasdate=input(chardate, mmddyy6.);                                                                                                     
   put _all_;                                                                                                                             
run;
结果：numdate=122591 chardate=122591 sasdate=11681 _ERROR_=0 _N_=1

*/
