libname source "C:\location_of_your_raw_source_data_from_appendix_a;
libname library "C:\location_of_your_format_library)";
libname target "C:\location_of_your_sdtm_datasets";

options ls=256 nocenter
        EXTENDOBSCOUNTER=NO
        mautosource 
        SASAUTOS = ("!SASROOT\core\sasmacro",      "!SASROOT\aacomp\sasmacro",
                    "!SASROOT\accelmva\sasmacro",  "!SASROOT\cstframework\sasmacro",          
                    "!SASROOT\dmscore\sasmacro",   "!SASROOT\genetics\sasmacro",          
                    "!SASROOT\graph\sasmacro",     "!SASROOT\hps\sasmacro",          
                    "!SASROOT\iml\sasmacro",       "!SASROOT\inttech\sasmacro",   
                    "!SASROOT\stat\sasmacro",      
                    "C:\location_of_your_autocall_sas_macros");