*----------------------------------------------------------------*;
* make_sort_order.sas creates a global macro variable called  
* **SORTSTRING where ** is the name of the dataset that contains  
* the KEYSEQUENCE metadata specified sort order for a given dataset.
*
* MACRO PARAMETERS:
* metadatafile = the file containing the dataset metadata
* dataset = the dataset or domain name
*----------------------------------------------------------------*;
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
	where keysequence ne . and domain="&dataset";
	by keysequence;
    run;

    ** create **SORTSTRING macro variable;
    %global &dataset.SORTSTRING;
    data _null_;
	set _temp end=eof;
	length domainkeys $ 200;
        retain domainkeys '';

        domainkeys = trim(domainkeys) || ' ' || trim(put(variable,8.));

        if eof then
          call symputx(compress("&dataset" || "SORTSTRING"), domainkeys);
    run;

%mend make_sort_order;
