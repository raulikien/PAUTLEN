%{
#include <stdio.h>
#include <stdlib.h>
#include "tokens.h"
extern FILE * salida;
%}
%option noyywrap

%%
main { fprintf(salida,"%s ",yytext); return TOK_MAIN; }
array { fprintf(salida,"%s ",yytext); return TOK_ARRAY; }
int { fprintf(salida,"%s ",yytext); return TOK_INT; }
if { fprintf(salida,"%s ",yytext); return TOK_IF; }
else { fprintf(salida,"%s ",yytext); return TOK_ELSE; }
while { fprintf(salida,"%s ",yytext); return TOK_WHILE; }
%%
int main()
{
return yylex();
}
