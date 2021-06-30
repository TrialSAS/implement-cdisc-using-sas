libname source "D:\SASShare\GitHub\implement-cdisc-using-sas\appendix-a";
libname library "D:\SASShare\GitHub\implement-cdisc-using-sas";
libname target "D:\SASShare\GitHub\implement-cdisc-using-sas\target";

options ls=256 nocenter

		/*ls，即：linesize=256,语法：LINESIZE=n | MIN | MAX | hexX 。 其中，n表示一行中的字符数（number of characters ）。*/
		
        EXTENDOBSCOUNTER=NO
		
        mautosource
		
		/*要使用autocall macros，必须设置两个SAS System options：mautosource，激活autocall facility。还有一个是：sasautos。*/
		
        SASAUTOS = ("!SASROOT\core\sasmacro",      "!SASROOT\aacomp\sasmacro",
                    "!SASROOT\accelmva\sasmacro",  "!SASROOT\cstframework\sasmacro",          
                    "!SASROOT\dmscore\sasmacro",   "!SASROOT\genetics\sasmacro",          
                    "!SASROOT\graph\sasmacro",     "!SASROOT\hps\sasmacro",          
                    "!SASROOT\iml\sasmacro",       "!SASROOT\inttech\sasmacro",   
                    "!SASROOT\stat\sasmacro",      
                    "D:\SASShare\GitHub\implement-cdisc-using-sas\macros");
					
		/*SASAUTOS=library-specification | (library-specification-1..., library-specification-n)
		*指定 autocall library 或libraries。
		*/


/*如何使用Autocall Macros？
* To use an autocall macro, call it in your program with the statement %macro-name.
* The macro processor searches first in the Work library for a compiled macro
* definition with that name. If the macro processor does not find a compiled macro
* and if the MAUTOSOURCE is in effect, the macro processor searches the libraries
* specified by the SASAUTOS option for a member with that name. When the macro
* processor finds the member, it does the following:
1 compiles all of the source statements in that member, including all macro definitions
2 executes any open code (macro statements or SAS source statements not within
	any macro definition) in that member
3 executes the macro with the name that you invoked
*/

/*SASAUTOS=系统选项，因为SAS在启动时会初始化自带的一些Autocall库，所以SASAUTOS会有默认的值。
*如果直接覆盖SASAUTOS的值，那么SAS系统自带的宏将会不可用。因此在赋值的时候，要加上默认的SASAUTOS值。

SASAUTOS的默认值可在SAS启动的配置文件“sasv9.cfg”中找到。若默认语言为中文，则该配置文件位于：
D:\ClinicalSAS\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg*/