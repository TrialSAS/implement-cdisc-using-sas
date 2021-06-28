*-----------------------------------------------------------------------------------;
* Transpose a BDS data set so that certain variables are side-by-side
*   Transposition can be based on PARAM's, AVISITs, or both
*
*   If transposing by a PARAM only, then variables named after PARAMCD values are created 
*     with PARAM values as the labels.  
*   If transposing by an AVISIT, then AVISxx_x becomes a variable with xx_x representing 
*     the AVISITN value (decimals, if present, are converted to an uderscore).  AVISIT
*     becomes the label for the variable.  
*   If transposing both a PARAM and an AVISIT, then variables named PARAMCD_AVISxx_x are created
*     with "PARAM (AVISIT)" as the label.
*   
*   In all cases, the new variables take on the values of AVAL unless all values of AVAL
*     are missing, in which case AVALC is used instead.
*  
*   Other variables for which transposing is requested will be prefixed with PARAMCD, AVISxx_x,
*     or both. 
*
*   Variable names and labels will be longer than the 8- and 40-character limits imposed on
*      SAS transport files.
*
*    To select only certain PARAM's within &INDATA, use a WHERE statement 
*      e.g. indata=%str(adtte (where=(PARAMCD in('PFS', 'PFS2'))))
*
*    CARRYONVARS = the variables to be transposed along with AVAL/AVALC 
*-----------------------------------------------------------------------------------;

%macro horizontalize(indata= ,outdata= ,xposeby= ,carryonvars=adt, sortby=usubjid);

    %** check that XPOSEBY variables are either PARAMCD or AVISITN (or both);
    data _null_;
      badvars = 0;
      xposeby1 = compress("%scan(%upcase(&xposeby), 1)");
      xposeby2 = compress("%scan(%upcase(&xposeby), 2)");      
      put xposeby2= ;
      if xposeby1 not in ("PARAMCD", "AVISITN") then
        do;
          put "PROB" "LEM: Illegal XPOSEBY variable: %scan(%upcase(&xposeby), 1)"; 
          badvars = 1;
        end;
      else if xposeby2 ne "" and xposeby2 not in ("PARAMCD", "AVISITN") then
        do;           
          put "PROB" "LEM: Illegal XPOSEBY variable: %scan(%upcase(&xposeby), 2)";  
          badvars = 1;
        end;
      call symput("badvars", put(badvars, 1.));
      call symput("xposeby1", xposeby1);
      call symput("xposeby2", xposeby2);
    run;
    
    %if &xposeby2^= %then
      %let lastvar = &xposeby2;
    %else
      %let lastvar = &xposeby1;
      
    %if &badvars=0 %then
      %do;
      
         proc summary
           data = &indata;
           class &xposeby;
           var aval;
           output out=_nonmissing n=notallmissing;
         run;
         
         proc print data = _nonmissing;
         run;
         
         data _null_;
           set _nonmissing end=eof;
             where %if "&lastvar"="&xposeby2" %then _type_=3; %else _type_=1;;
             
           ** if all AVAL values are missing then populate the root transposed var with AVALC;
           if notallmissing then
             call symput(compress(paramcd) || "VAR", "AVAL");
           else
             call symput(compress(paramcd) || "VAR", "AVALC");
             
           length varlist $800;
           %if %index(%upcase(&xposeby), AVISITN)>0 %then
             %do;
               avisvar = "AVIS_" || compress(tranwrd(put(avisitn, best.), ".", "_"));
               put avisvar= ;
             %end;

           retain varlist ;
           %if &xposeby1=PARAMCD and &xposeby2=AVISITN %then
             varlist = trim(varlist) || " " || trim(&xposeby1) || "_" || trim(avisvar);
           %else %if &xposeby1=PARAMCD %then
             varlist = trim(varlist) || " " || trim(&xposeby1) ;
           %if &xposeby1=AVISITN and &xposeby2=PARAMCD %then
             varlist = trim(varlist) || " " || trim(avisvar) || "_" || trim(&xposeby1) ;
           %else %if &xposeby1=AVISITN %then
             varlist = trim(varlist) || " " || trim(avisvar) ;
           ;  
           if eof then
             do;
               put varlist= ;
               call symput("varlist", trim(varlist));
             end;
         run;
         
         %*** Need to determine which CarryOn vars are numeric and which are character;
         %let dsetnum=%sysfunc(open(&indata));
         %let items=1;
         %let numvars= ;
         %let charvars= ;
         %do %while(%scan(&carryonvars,&items)^= );
           %let var = %scan(&carryonvars,&items);
           %let varnum=%sysfunc(varnum(&dsetnum,&var));
           %if %sysfunc(vartype(&dsetnum,&varnum))=C %then
             %let charvars=&charvars &var;
           %else %if %sysfunc(vartype(&dsetnum,&varnum))=N %then
             %let numvars=&numvars &var;
           %let items=%eval(&items+1);
         %end;
         %*** Determine which variables need to be dropped after transforming;
         %let avalc_exists = %sysfunc(varnum(&dsetnum,avalc));
         %let rc = %sysfunc(close(&dsetnum));
         
                
         %*** Find the last SORTBY var;
         %let items=1;
         %do %while(%scan(&sortby,&items)^= );
           %let lastsortvar = %scan(&sortby,&items);
           %let items=%eval(&items+1);
         %end;
         %put lastsortvar=&lastsortvar sortby=&sortby;         
           
         proc sort
           data = &indata
           out = __temp;
             by &sortby &xposeby;
         run;  
           
         data __temp;
           set __temp;
             by &sortby &xposeby1 &xposeby2;
              
                drop &xposeby &carryonvars avisvalstrt avisvalend __tmp: aval 
                     %if &avalc_exists %then avalc;
                     %if %index(%upcase(&xposeby),PARAM) %then param paramcd;
                     %if %index(%upcase(&xposeby),AVISIT) %then avisit avisitn;
                ;
                
                length __tmp $99;
                *array nums{*} &numvars;
                *array chars{*} $ &charvars;
                                
                ** cycle through each group of variables and the CarryOn variables;
                ** initialize and retain each one individually, ;
                **   then assign to values when proper record comes up;
                %let grp=1;
                %do %while(%scan(&varlist,&grp)^= );
                  %let basename = %scan(&varlist,&grp);
                  
                  retain &basename;
                  if first.&lastsortvar then
                    &basename = .;
                    
                  ** Note: if PARAMCD contains an underscore then this code will not work...;

                  ** if AVISITN is an XPOSEBY var and values of AVISITN contain decimals,  ;
                  **  then the decimal has been converted to an underscore.  When matching ;
                  **  up records, we need to identify the AVISITN value of the current     ;
                  **  record and convert underscores back to decimals                      ;
                  if index("&basename",'AVIS_') then
                    do;
                      avisvalstrt = index("&basename", 'AVIS_')+5;
                      __tmp = substr("&basename",avisvalstrt);
                      __tmp = translate(__tmp, 'x', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
                      avisvalend = index(__tmp,'_x');
                      if avisvalend>0 then
                        __tmp = substr(__tmp, 1, avisvalend);
                      __tmp = tranwrd(__tmp,'_','.');
                      __tmp2 = input(__tmp, best.);
                    end;
                      

                  *------------------------------------------;
                  * Transpose AVAL;
                  *------------------------------------------;
                  %if %upcase(&xposeby1)=PARAMCD %then
                    %do;
                      %put basename=&basename;
                        if %if %index(&basename,_AVIS) %then 
                              paramcd="%substr(&basename,1,%eval(%index(&basename,_AVIS)-1))";
                           %else
                              paramcd="&basename" ;
                           %if &xposeby2^= %then 
                              and avisitn=__tmp2;
                           then &basename = aval; 
                    %end;
                  %else %if %upcase(&xposeby1)=AVISITN %then
                    %do;
                      if avisitn=__tmp2  
                        %if &xposeby2^= %then 
                          and paramcd="%substr(&basename,avisvalend)";
                        then &basename = aval; 
                    %end;
                  put paramcd= avisitn= aval= &basename= ;
                  

                  *-----------------------------------------------;
                  ** Transpose the CARRYONVARs;
                  *-----------------------------------------------;
                  %let nvars=1;                    
                  %do %while(%scan(&numvars,&nvars)^= );
                    %let nvar = &basename._%scan(&numvars,&nvars);
                    retain &nvar; 
                    if first.&lastsortvar then
                      &nvar = .;
                    %if %upcase(&xposeby1)=PARAMCD %then
                      %do;
                        if %if %index(&basename,_AVIS) %then 
                              paramcd="%substr(&basename,1,%eval(%index(&basename,_AVIS)-1))";
                           %else
                              paramcd="&basename" ;
                          %if &xposeby2^= %then 
                            and avisitn=__tmp2;
                          then &nvar = %scan(&numvars,&nvars); 
                      %end;
                    %else %if %upcase(&xposeby1)=AVISITN %then
                      %do;
                        if avisitn=__tmp2  
                          %if &xposeby2^= %then 
                            and paramcd="%substr(&basename,avisvalend)";
                          then &nvar = %scan(&numvars,&nvars); 
                      %end;
                    %let nvars=%eval(&nvars+1);
                  %end;
                  %let cvars=1;                    
                  %do %while(%scan(&charvars,&cvars)^= );
                    %let cvar = &basename._%scan(&charvars,&cvars);
                    retain &cvar; 
                    if first.&lastsortvar then
                      &cvar = "               ";
                    %if %upcase(&xposeby1)=PARAMCD %then
                      %do;
                        if %if %index(&basename,_AVIS) %then 
                              paramcd="%substr(&basename,1,%eval(%index(&basename,_AVIS)-1))";
                           %else
                              paramcd="&basename" ;
                           %if &xposeby2^= %then 
                              and avisitn=__tmp2;
                           then &cvar = %scan(&charvars,&cvars); 
                      %end;
                    %else %if %upcase(&xposeby1)=AVISITN %then
                      %do;
                        if avisitn=__tmp2  
                          %if &xposeby2^= %then 
                            and paramcd="%substr(&basename,avisvalend)";
                          then &cvar = %scan(&charvars,&cvars); 
                      %end;
                    %let cvars=%eval(&cvars+1);
                  %end;
                  %let grp=%eval(&grp+1);
                %end;  
                
                if last.&lastsortvar;
         run;

         ** create a format that maps each variable name to its label;
         proc sort
           data = &indata
           out = _fmt
           nodupkey;
             by &xposeby1 &xposeby2;
             
         data _fmt;
           set _fmt;
             by &xposeby1 &xposeby2;
             
                keep fmtname start label ;
                retain fmtname "labels" type 'c' ;
                length start $60 label $200;
                %if &xposeby2^= and &xposeby1=PARAMCD %then
                  %do;
                    label = trim(param) || "/" || trim(avisit);
                    start = trim(paramcd) || "_AVIS_" || compress(tranwrd(put(avisitn, best.), ".", "_"));
                  %end;
                %else %if &xposeby2^= and &xposeby1=AVISITN %then
                  %do;
                    label = trim(avisit) || "/" || trim(param); 
                    start = trim(put(avisitn, best.)) || "_" || trim(paramcd);
                  %end;
                %else %if &xposeby1=AVISITN %then
                  %do;
                    label = avisit;
                    start = trim(put(avisitn, best.));
                  %end;
                %else 
                  %do;
                    label = param ;
                    start = trim(paramcd);
                  %end;
                ;                
                put paramcd= avisitn= start= label= ;
         run;                             
         
         proc contents
           data=&indata (keep = &carryonvars) out = _carryons;
         run;
         
         data _carryons;
           set _carryons end=eof;
           
                length &carryonvars $40;
                retain &carryonvars ;
                keep   &carryonvars;
                array labels{*} &carryonvars;
                do i = 1 to dim(labels);
                  if upcase(vname(labels{i}))=upcase(name) then
                    do;
                      labels{i} = label;
                      put labels{i}= ;
                    end;
                end;
                if eof;                    
         run;                

         %** create macro variables of the new transposed variables;
         data _null_;
           set _fmt end=eof;
           
                length varlist $400;
                retain varlist ' ' varnum 0;
                if _n_=1 then set _carryons;
                call symput(start, trim(label));
                varlist = trim(varlist) || " " || trim(start); 
                varnum + 1;
                array labels{*} &carryonvars;
                do i = 1 to dim(labels);
                  _start = trim(start) || "_" || trim(upcase(vname(labels{i})));
                  _label = trim(label) || "/" || trim(labels{i});
                  call symput(_start, trim(_label));
                  varlist = trim(varlist) || " " || trim(_start); 
                  varnum + 1;
                end;
                if eof then
                  do;
                    call symput("varlist", trim(varlist));
                    call symput("varnum",  put(varnum, 3.));
                  end;
         run;                
         %put varlist=&varlist;
         
         proc print
           data = _fmt;
         run ;

         proc print
           data = __temp;
         run;
         
         data __temp;
           set __temp;
           
                label %do i = 1 %to &varnum;
                         %scan(&varlist,&i) = "&&&%scan(&varlist,&i)"
                      %end;
                ;
         run;                    
      %end;  
      
%mend horizontalize;

  	