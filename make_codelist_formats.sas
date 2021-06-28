*---------------------------------------------------------------*;
* make_codelist_formats.sas creates a permanent SAS format library
* stored to the libref LIBRARY from the codelist metadata file 
* CODELISTS.xls.  The permanent format library that is created
* contains formats that are named like this: 
*   CODELISTNAME_SOURCEDATASET_SOURCEVARIABLE
* where CODELISTNAME is the name of the SDTM codelist, 
* SOURCEDATASET is the name of the source SAS dataset and
* SOURCEVARIABLE is the name of the source SAS variable.
*---------------------------------------------------------------*;
%include "D:\SASShare\GitHub\implement-cdisc-using-sas\common.sas";


proc import 
    datafile="D:\SASShare\GitHub\implement-cdisc-using-sas\appendix-a\SDTM_METADATA.xlsx"
    out=formatdata 
    dbms=excelcs 
    replace; 
    sheet="CODELISTS";
run;

/*CODELIST中的变量有：
*	CODELISTNAME、RANK、CODEVALUE、TRANSLATED、TYPE、CODELISTDICTIONARY、CODELISTVERSION、
*	ORDERNUMBER、sourcedataset、sourcevariable、sourcevalue、sourcetype。 */

** make a proc format control dataset out of the SDTM metadata; 

data source.formatdata;
    set formatdata(drop=type);

	where sourcedataset ne "" and sourcevalue ne "";
	/* sourcedataset的值为：“adverse”、“demographic”，“labs”等，
	* sourcevalue的值为“1、2、3、4、5”，“0，1”，“CHEMISTRY,HEMATOLOGY,URINALYSIS”等*/
	
	/* 语法解析：where
	* where:在data sets中 选择匹配特定条件的观测。Selects observations from SAS data sets that meeta particular condition. 
	*  where可以在 DATA step 或PROC step中使用。
	* 其中，在Data step使用时：
	*	 The WHERE statement applies to all data sets in the preceding SET, 
	*	 MERGE, MODIFY, or UPDATE statement, and variables that are used 
	* 	 in the WHERE statement must appear in all of those data sets. 
	* 	 You cannot use the WHERE statement with the POINT= option 
	* 	 in the SET and MODIFY statements
	*/

	keep fmtname start end label type;	
	/* keep语句 新建变量fmtname、start、end、label、type。*/
	/*语法解析：keep：
	* 指定在output 数据集中的变量。
	*/
	
	length fmtname $ 32 start end $ 16 label $ 200 type $ 1;

	fmtname = compress(codelistname || "_" || sourcedataset 
                  || "_" || sourcevariable);
	/*结果为：codelist_sourcedataset_sourcevariable格式。
	*例如：ACN_adverse_aeaction， LBTEST_labs_labtest 。
	*/
	
	start = left(sourcevalue);
	/*其中，sourcevalue如： “1，2，3”， 如“CHEMISTRY、HEMATOLOGY、URINALYSIS”等。*/
	end = left(sourcevalue);
	
	label = left(codedvalue);
	/*其中， codevalue如： A“NOT RELATED、POSSIBLY RELATED、PROBABLY RELATED、MILD、MODERATE、SEVERE”，
		如：YEARS, USA, "HIGH、LOW、NORMAL"*/
	if upcase(sourcetype) = "NUMBER" then
	    type = "N";
	else if upcase(sourcetype) = "CHARACTER" then
	    type = "C";
run;

** create a SAS format library to be used in SDTM conversions;
proc format		
/*PROC FORMAT: 使用一个SAS 数据集生成format。*/

    library=library		/*指定一个SAS library或catalog来存放生成的formats。*/
    cntlin=source.formatdata  /*指定用source.formatdata数据集生成format。*/
    fmtlib;		/*打印formats的信息。*/
run;
