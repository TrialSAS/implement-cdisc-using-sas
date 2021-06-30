*----------------------------------------------------------------*;
* make_sort_order.sas creates a global macro variable called  
* **SORTSTRING where ** is the name of the dataset that contains  
* the KEYSEQUENCE metadata specified sort order for a given dataset.
*
* MACRO PARAMETERS:
* metadatafile = the file containing the dataset metadata
* dataset = the dataset or domain name
*----------------------------------------------------------------*;

* variable_metadata中的变量有：
*	DOMAIN、VARNUM、VARIABLE、TYPE、LENGTH、LABEL、KEYSEQUENCE、SIGNIFICANTDIGITS、ORIGIN、COMMENTOID、DISPLAYFORMAT、
*	COMPUTATIONMETHODOID、CODELISTNAME、MANDATORY、ROLE、SASFIELDNAME。*/

%macro make_sort_order(metadatafile=,dataset=);

    proc import 
        datafile="&metadatafile"
        out=_temp 
        dbms=excelcs
        replace;
        sheet="VARIABLE_METADATA";
    run;

    proc sort
	data=_temp;
	where keysequence ne . and domain="&dataset";	/*keysequence的值为数字“1、2 ...”*/
	by keysequence;
    run;

    ** create **SORTSTRING macro variable;
    %global &dataset.SORTSTRING;
    data null_;
	set _temp end=eof;
	length domainkeys $ 200;
        retain domainkeys '';

        domainkeys = trim(domainkeys) || ' ' || trim(put(variable,8.));

        if eof then
          call symputx(compress("&dataset" || "SORTSTRING"), domainkeys);
    run;
		/*这里生成的变量是如： DMSORTSTRING, 它的值为domainkeys的值。*/

%mend make_sort_order;


/*1. CALL SYMPUTX Routine
语法： CALL SYMPUTX(macro-variable, value <, symbol-table>); 
作用：Assigns a value to a macro variable, and removesboth leading and trailing blanks. 
	将一个值 分配给一个 宏变量，并移除首尾的空格。
*/

/* 2. RETAIN Statement
语法：RETAIN  <element-list(s) <initial-value(s) |(initial-value-1)| (initial-value-list-1)> 
<... element-list-n <initial-value-n |(initial-value-n )| (initial-value-list-n)> >>; 
作用：Causes a variable that is created by an INPUT or assignment statement to 
*		retain its value from one iteration of the DATA step to the next. 
* 让INPUT语句或赋值语句生成的变量，保留它的值从一次迭代到下一次，而不清空。
*/