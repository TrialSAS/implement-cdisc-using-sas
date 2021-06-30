/*make_empty_dataset.sas*/

*---------------------------------------------------------------*;
* make_empty_dataset.sas creates a zero record dataset based on a 
* dataset metadata spreadsheet.  The dataset created is called
* EMPTY_** where "**" is the name of the dataset.  This macro also
* creates a global macro variable called **KEEPSTRING that holds 
* the dataset variables desired and listed in the order they  
* should appear.  [The variable order is dictated by VARNUM in the 
* metadata spreadsheet.]
*
* MACRO PARAMETERS:
* metadatafile = the MS Excel file containing the dataset metadata
* dataset = the dataset or domain name you want to extract
*---------------------------------------------------------------*;

/* variable_metadata中的变量有：
*	DOMAIN、VARNUM、VARIABLE、TYPE、LENGTH、LABEL、KEYSEQUENCE、SIGNIFICANTDIGITS、ORIGIN、COMMENTOID、DISPLAYFORMAT、
*	COMPUTATIONMETHODOID、CODELISTNAME、MANDATORY、ROLE、SASFIELDNAME。*/

%macro make_empty_dataset(metadatafile=,dataset=);

    proc import 
        datafile="&metadatafile"
        out=_temp 
        dbms=excelcs
        replace;
        sheet="VARIABLE_METADATA";
    run;

    ** sort the dataset by expected specified variable order;
    proc sort
      data=_temp;
	  where domain = "&dataset";
        by varnum;	  
		/*varnum 表示variable在SDTM Domain中出现的顺序，值为“1，2，3...”*/
    run;

    ** create keepstring macro variable and load metadata 
    ** information into macro variables;
    %global &dataset.KEEPSTRING;
	/*新建全局宏变量&dataset.KEEPSTRING，比如： DM.KEEPSTRING*/
	
    data NULL_;
      set _temp nobs=nobs end=eof;
	  /*set 语句的选项nobs、end。
	  * 语法：NOBS=variable： 创建和命名一个临时变量variable，它的值通常为数据集中观测的总数。
	  * END=variable ： 创建和命名一个临时变量，包含一个 end-of-file indicator【文件尾标志】。（初始值通常为0，当读取到最后一个观测时值为1。）
	  * nobs：number of observations。观测的数量。
	  */

        if _n_=1 then
          call symput("vars", compress(put(nobs,3.)));		
		  **在本书中，当dataset=DM时，nobs=23，故，此处vars=23;
			/*[1] put Function，以指定的format返回一个值。Returns a value using a specified format
			*语法：PUT(source, format.) 
			*/

			/*[2] compress Function，从原始字符串中剔除指定字符后，返回一个新字符串。
			*  语法：COMPRESS(character-expression[, character-list-expression] [, modifier(s)])
			*  当只有第一个参数时，移除所有的空格。*/
			
			/*[3] call symput Routine, 将在DATA步生成的值分配给一个宏变量。Assigns a value produced in a DATA step to a macrovariable.
			* 	语法：CALL SYMPUT(macro-variable, value); 	
				*/
			
			
			
        call symputx('var'    || compress(put(_n_, 3.)), variable);
		/*call symputx Routine： 表示： 将一个值分配给一个宏变量，并移除首尾的空格。Assigns a value to a macro variable, and removesboth leading and trailing blanks. 
		* 语法：CALL SYMPUTX(macro-variable, value <, symbol-table>); 
				其中，<,symbol-table> 指定一个字符常量，变量或表达式。
		*/
        call symputx('label'  || compress(put(_n_, 3.)), label);
        call symputx('length' || compress(put(_n_, 3.)), put(length, 3.));


        ** valid ODM types include TEXT, INTEGER, FLOAT, DATETIME, 
        ** DATE, TIME and map to SAS numeric or character;
        if upcase(type) in ("INTEGER", "FLOAT") then
          call symputx('type' || compress(put(_n_, 3.)), "");
        else if upcase(type) in ("TEXT", "DATE", "DATETIME", "TIME") then
          call symputx('type' || compress(put(_n_, 3.)), "$");
        else
          put "ERR" "OR: not using a valid ODM type.  " type=;


        ** create **KEEPSTRING macro variable;
        length keepstring $ 32767;	 
        retain keepstring;		
		
		/*将所有的variable都放到宏变量keepstring中，keepstring的值为（类似于）：”|STUDYID|DOMAIN|USUBJID|SUBJID|RFSTDTC|RFENDTC|RFXSTDTC|RFXENDTC “*/
        keepstring = compress(keepstring) || "|" || left(variable); 
        if eof then
          call symputx(upcase(compress("&dataset" || 'KEEPSTRING')), 
                       left(trim(translate(keepstring," ","|"))));
    run;
     

    ** create a 0-observation template data set used for assigning 
    ** variable attributes to the actual data sets;
	/* 创建新空数据集，如 EMPTY_DM ，
	*  vars表示：如这里，DM的数量是23，这里vars=23。
	*  var表示：的是从SDTM_Metadata.xlsx中读取的 VARIABLE, 如“STUDYID,DOMAIN,USUBJID...”
	*  label 表示：从SDTM_Metadata.xlsx中读取的label。如：“Study Identifier”，“Domain  Abbreviation”
	*  length 表示：length，如STUDYID的length为15.
	*/
	
	/*如xlsx文件第29行，DOMAIN=DM, VARNUM=1, VARIABLE=STUDYID, TYPE=text， LENGTH=15, LABEL="Study Identifier" 
	其中，VARNUM用来： 排序， VARIABLE用于：转换为var， TYPE用于：转换为SAS TYPE,只有N,C两种类型。
	LENGTH用于：转化为：length，如这里还是 15。 	*/
	
    data EMPTY_&dataset;
        %do i=1 %to &vars;           
           attrib &&var&i label="&&label&i" 
             %if "&&length&i" ne "" %then
               length=&&type&i.&&length&i... ;
           ;
           %if &&type&i=$ %then
             retain &&var&i '';
           %else
             retain &&var&i .;
           ;
        %end;
        if 0;
    run;
	/*attrib Statement: 作用：Associates a format, informat, label, and lengthwith one or more variables. 
	* 将一个format，informat，label，length与一个变量相关联。
	* 语法：ATTRIB variable-list(s)  attribute-list(s); */

%mend make_empty_dataset;

