***************************************************************************************;
* Program: resizenfields                                                              *;
* Purpose: Bepaal voor alle text velden de maximum veld lengte en passen deze veld    *;
*          lengtes ook aan                                                            *;
***************************************************************************************;

%macro resizenfields (BronData=, DoelData=);
 %if (%superq(BronData)= or %superQ(DoelData)=) %then %do;
    %put You must specify both BronData= and DoelData=;
    %goto ByeBye;
  %end;

  proc contents noprint data=&BronData  out=_contnt_; run;
  proc sort data=_contnt_; by VARNUM;                  run;

  %local dsid nvars rc needed;
  %let dsid=%sysfunc(open(_contnt_));
  %if &dsid %then %do;
    %let nvars=%sysfunc(attrn(&dsid,NOBS));
    %let rc=%sysfunc(close(&dsid));
  %end;
  %else %goto ByeBye;

  %local zero;
  %do i=1 %to &nvars;
    %local var&i typ&i len&i mln&i;
  %end;

  data _null_;
    set _contnt_;
    by VARNUM;
    call symput ('var'||left(_n_), name);
    if type=2
      then call symput ('typ'||left(_n_), '$');
      else call symput ('typ'||left(_n_), ' ');
    call symput ('len'||left(_n_), length);
  run;

  proc sql noprint;
    select
    0
    %do i=1 %to &nvars;
      %if &&typ&i=$ %then ,max(length(&&var&i)) ;
    %end;
    into
    :zero
    %do i=1 %to &nvars;
      %if &&typ&i=$ %then ,:mln&i ;
    %end;
    from &BronData
    ;
  quit;

  %let needed = 0;
  %do i = 1 %to &nvars;
    %if &&typ&i=$ %then
      %let needed = %eval (&needed OR (&&mln&i < &&len&i));
  %end;

  %if (%superq(BronData) ne %superq(DoelData)) or &needed %then %do;     
    options varlenchk=nowarn;
    data &DoelData
         ;
      retain %do i=1 %to &nvars; 
                &&var&i 
             %end;
         ;
        %do i=1 %to &nvars;
                %if &&typ&i=$ %then %do;
                 %let lengteFormatInformat=%sysfunc(compress($&&mln&i...));
                    attrib &&var&i    length=&lengteFormatInformat.;
                %end; 
             %end;;
        set &BronData;
    run;
    options varlenchk=warn;
  %end;
  %else %do;
  %end;

    proc sql;
        drop table _contnt_;
    quit;

  %ByeBye:
%mend resizenfields;