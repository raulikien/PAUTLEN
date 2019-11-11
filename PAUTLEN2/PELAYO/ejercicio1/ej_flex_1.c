#include <stdio.h>
#include <stdlib.h>
#include "tokens.h"

extern int yylex();
extern FILE *yyin;
extern char yytext[];
FILE * yyout;

int main(int argc, char** argv){

	int valor_patron=0;

	if(argc < 3){
		printf("Error en los parametros ==>> ./ejecutable fichero_entrada fichero_salida");
		return -1;
	}

	yyin = fopen(argv[1], "r");
	yyout = fopen(argv[2],"w+");

	while((valor_patron = yylex()) != 0){

		switch(valor_patron){
			
			case TOK_MAIN:
				fprintf(yyout,"RECONOCIDO %d: MAIN", valor_patron);
				break;

			case TOK_INT:
				fprintf(yyout,"RECONOCIDO %d: INT", valor_patron);
				break;

			case TOK_ARRAY:
				fprintf(yyout,"RECONOCIDO %d: ARRAY", valor_patron);
				break;

			case TOK_IF:
				fprintf(yyout,"RECONOCIDO %d: IF", valor_patron);
				break;
	
			case TOK_ELSE:
				fprintf(yyout,"RECONOCIDO %d: ELSE", valor_patron);
				break;

			case TOK_WHILE:
				fprintf(yyout,"RECONOCIDO %d: WHILE", valor_patron);
				break;
			default:
				printf("\nError producido detectando una expresion");

		}
	}

	fclose(yyout);
	fclose(yyin);
	return 0;


}
