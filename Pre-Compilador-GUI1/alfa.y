%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    
    #include "alfa.h"
    #include "tablaSimbolos.h"
    #include "tablaHash.h"
    #include "generacion.h"

    void yyerror(const char* err);
    extern int line, col, error;
    extern FILE *yyin;
    extern FILE *yyout;
    extern int yylex();
    extern int yyleng;

    /*variables para conocer el estado actual del simbolo*/

    TIPO tipo_actual;
    CLASE clase_actual;
    INFO_SIMBOLO * aux;

    /*Ambito global y local*/

    extern TABLA_HASH * tablaSimbolosLocal;
    extern TABLA_HASH * tablaSimbolosGlobal;

    /*Otra informacion*/

    int tamanio_vector_actual=0; //Tamanio del vector
    int pos_variable_local_actual=1; //Posicion de variable global en ambitos de variables locales
    int num_variables_locales_actual=0;
    int cuantos_no=0;
    char aux_char[100];
    int en_explist=1;
    int etiqueta=1;
    int fn_return=0;
    
    /*Parametros*/
    
    int num_parametros_actual=0;
    int pos_parametro_actual=0;
    int num_parametros_llamada_actual=0;
    int comprobacion_parametros=0;

    /*Etiquetas*/
    int num_comparaciones=0;
%}
%union
        {
            tipo_atributos atributos;
        }


/*Simbolos no terminales con valor semantico*/

%type <atributos> condicional
%type <atributos> comparacion
%type <atributos> elemento_vector
%type <atributos> exp
%type <atributos> constante
%type <atributos> constante_entera
%type <atributos> constante_logica
%type <atributos> identificador
%type <atributos> fn_declaracion
%type <atributos> fn_name
%type <atributos> if_exp
%type <atributos> if_exp_sentencias
%type <atributos> bucle_exp
%type <atributos> bucle_exp_sentencias


/*Simbolos terminales con valor semantico*/

%token <atributos> TOK_CONSTANTE_ENTERA
%token <atributos> TOK_CONSTANTE_REAL
%token <atributos> TOK_IDENTIFICADOR

/*Simbolos terminales sin valor semantico*/

%token TOK_MAIN
%token TOK_INT
%token TOK_BOOLEAN
%token TOK_ARRAY
%token TOK_FUNCTION
%token TOK_IF
%token TOK_ELSE
%token TOK_WHILE
%token TOK_SCANF
%token TOK_PRINTF
%token TOK_RETURN
%token TOK_PUNTOYCOMA
%token TOK_COMA
%token TOK_PARENTESISIZQUIERDO
%token TOK_PARENTESISDERECHO
%token TOK_CORCHETEIZQUIERDO
%token TOK_CORCHETEDERECHO
%token TOK_LLAVEIZQUIERDA
%token TOK_LLAVEDERECHA
%token TOK_ASIGNACION
%token TOK_MAS
%token TOK_MENOS
%token TOK_DIVISION
%token TOK_ASTERISCO
%token TOK_AND
%token TOK_OR
%token TOK_NOT
%token TOK_IGUAL
%token TOK_DISTINTO
%token TOK_MENORIGUAL
%token TOK_MAYORIGUAL
%token TOK_MENOR
%token TOK_MAYOR
%token TOK_TRUE
%token TOK_FALSE
%token TOK_ERROR

%left TOK_ASIGNACION
%left TOK_AND TOK_OR
%left TOK_IGUAL TOK_DISTINTO
%left TOK_MAYOR TOK_MENOR TOK_MAYORIGUAL TOK_MENORIGUAL
%left TOK_MAS TOK_MENOS
%left TOK_DIVISION TOK_ASTERISCO
%left TOK_NOT MENOSU
%left TOK_PARENTESISIZQUIERDO TOK_PARENTESISDERECHO TOK_CORCHETEIZQUIERDO TOK_CORCHETEDERECHO

%start programa

%%
programa: TOK_MAIN TOK_LLAVEIZQUIERDA inicio declaraciones escritura1 funciones escritura2 sentencias fin TOK_LLAVEDERECHA {fprintf(stdout, ";R1:\t<programa> ::= main { <declaraciones> <funciones> <sentencias> }\n");}
;

inicio:{
    CrearTablaGlobal();
    escribir_subseccion_data(yyout);
    escribir_cabecera_bss(yyout);
}

fin:{
    escribir_fin(yyout);
    LimpiarTablas();
}

escritura1:{
    INFO_SIMBOLO * totales = tablaSimbolosGlobal->simbolos;
    while(totales != NULL){

        if(totales->categoria == VARIABLE){
            if(totales->tipo == INT) {
                declarar_variable(yyout,totales->lexema,ENTERO,(totales->clase == VECTOR) ? totales->adicional1 : 1);
            }else if(totales->tipo == BOOLEAN){
                declarar_variable(yyout,totales->lexema,BOOLEANO,(totales->clase == VECTOR) ? totales->adicional1 : 1);
            }
        }

        totales = totales->siguiente;
    }

    escribir_segmento_codigo(yyout);
}

escritura2:{
    escribir_inicio_main(yyout);
}

/*=========================================================================================================================*/
/*=========================================================================================================================*/
/*=========================================================================================================================*/

declaraciones: declaracion {

    fprintf(stdout, ";R2:\t<declaraciones> ::= <declaracion>\n");

}
            | declaracion declaraciones {

    fprintf(stdout, ";R3:\t<declaraciones> ::= <declaracion> <declaraciones>\n");

};



declaracion: clase identificadores TOK_PUNTOYCOMA {

    fprintf(stdout, ";R4:\t<declaracion> ::= <clase> <identificadores> ;\n");

};


clase: clase_escalar {
    
    clase_actual=ESCALAR; 
    fprintf(stdout, ";R5:\t<clase> ::= <clase_escalar>\n");

}
    | clase_vector {

    clase_actual=VECTOR;
    fprintf(stdout, ";R7:\t<clase> ::= <clase_vector>\n");

};


clase_escalar: tipo {

    fprintf(stdout, ";R9:\t<clase_escalar> ::= <tipo>\n");

};


clase_vector: TOK_ARRAY tipo TOK_CORCHETEIZQUIERDO constante_entera TOK_CORCHETEDERECHO {

    tamanio_vector_actual = $4.valor_entero;
    if((tamanio_vector_actual < 1) || (tamanio_vector_actual > MAX_TAMANIO_VECTOR)){
        fprintf(stdout,"****Error Semantico en la linea %d columna %d: tamanio array inferior o superior al permitido en la declaracion\n", line,col);
        return -1;
    }

    fprintf(stdout, ";R15:\t<clase_vector> ::= array <tipo> [ <constante_entera> ]\n");
};


tipo: TOK_INT {

    tipo_actual=INT; 
    fprintf(stdout, ";R10:\t<tipo> ::= int\n");

}
    | TOK_BOOLEAN {

    tipo_actual=BOOLEAN; 
    fprintf(stdout, ";R11:\t<tipo> ::= boolean\n");

};

identificadores: identificador {

    fprintf(stdout, ";R18:\t<identificadores> ::= <identificador>\n");

}
            | identificador TOK_COMA identificadores {

    fprintf(stdout, ";R19:\t<identificadores> ::= <identificador> , <identificadores>\n");

};


/*=========================================================================================================================*/
/*=========================================================================================================================*/
/*=========================================================================================================================*/


funciones: funcion funciones {

    fprintf(stdout, ";R20:\t<funciones> ::= <funcion> <funciones>\n");

}
        | /* LAMBDA */ {

    fprintf(stdout, ";R21:\t<funciones> ::=\n");

};

fn_name: TOK_FUNCTION tipo TOK_IDENTIFICADOR {
    
    aux = UsoGlobal($3.lexema);

    if(aux != NULL){ //Error porque el identificador ya existe en este ambito
        fprintf(stdout,"****Error Semantico en la linea %d: declaracion doble de la funcion\n", line);
        return -1;
    }else{

        if(DeclararFuncion($3.lexema,FUNCION,tipo_actual,ESCALAR,-1,-1) == OK){
            pos_variable_local_actual=1;
            num_variables_locales_actual=0;
            pos_parametro_actual=0;
            num_parametros_actual=0;
            tamanio_vector_actual=0;
            $$.tipo = tipo_actual;
            strcpy($$.lexema,$3.lexema);
            fn_return = 0;
        }else{
            fprintf(stdout,"****Error Semantico en la linea %d: fallo al declarar la funcion %s en el ambito global\n",line,$3.lexema);
            return -1;
        }

    }
};




fn_declaracion: fn_name TOK_PARENTESISIZQUIERDO parametros_funcion TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA declaraciones_funcion{
    
    aux = UsoExclusivoLocal($1.lexema);

    aux->adicional1 = num_parametros_actual;
    aux->adicional2 = num_variables_locales_actual;

    aux = UsoGlobal($1.lexema);

    aux->adicional1 = num_parametros_actual;
    aux->adicional2 = num_variables_locales_actual;

    $$ = $1;

    declararFuncion(yyout,$1.lexema,num_variables_locales_actual);

};



funcion: fn_declaracion sentencias TOK_LLAVEDERECHA {

    CerrarFuncion();
    tablaSimbolosLocal=NULL;

    aux = UsoGlobal($1.lexema);

    if(aux == NULL){
        fprintf(stdout,"****Error Semantico en la linea %d: acceso a la variable %s sin declarar\n", line, $1.lexema);
        return -1;
    }

    if(fn_return == 0){
        fprintf(stdout,"****Error Semantico en la linea %d: no existe retorno para la funcion %s\n", line, $1.lexema);
        return -1;
    }

   

fprintf(stdout, ";R22:\t<funcion> ::= function <tipo> <identificador> ( <parametros_funcion> ) { <declaraciones_funcion> <sentencias> }\n");

};


parametros_funcion: parametro_funcion resto_parametros_funcion {


    fprintf(stdout, ";R23:\t<parametros_funcion> ::= <parametro_funcion> <resto_parametros_funcion>\n");

}
                | /* LAMBDA */ {

    fprintf(stdout, ";;R24:\t<parametros_funcion> ::=\n");

};



resto_parametros_funcion: TOK_PUNTOYCOMA parametro_funcion resto_parametros_funcion {

    fprintf(stdout, ";R25:\t <resto_parametros_funcion> ::= ; <parametro_funcion> <resto_parametros_funcion>\n");

}
                        | /* LAMBDA */ {

    fprintf(stdout, ";R26:\t<resto_parametros_funcion> ::=\n");

};

parametro_funcion: tipo idpf {

    fprintf(stdout, ";R27:\t<parametro_funcion> ::= <tipo> <identificador>\n");

};

declaraciones_funcion: declaraciones {

    fprintf(stdout, ";R28:\t<declaraciones_funcion> ::= <declaraciones>\n");

}
                    | /* LAMBDA */ {

    fprintf(stdout, ";R29:\t<declaraciones_funcion> ::=\n");

};

/*=========================================================================================================================*/
/*=========================================================================================================================*/
/*=========================================================================================================================*/


sentencias: sentencia {

    fprintf(stdout, ";R30:\t<sentencias> ::= <sentencia>\n");

}
        | sentencia sentencias {

    fprintf(stdout, ";R31:\t<sentencias> ::= <sentencia> <sentencias>\n");

};

sentencia: sentencia_simple TOK_PUNTOYCOMA {

    fprintf(stdout, ";R32:\t<sentencia> ::= <sentencia_simple> ;\n");

}
            | bloque {

    fprintf(stdout, ";R33:\t<sentencia> ::= <bloque>\n");

};

sentencia_simple: asignacion {

    fprintf(stdout, ";R34:\t<sentencia_simple> ::= <asignacion>\n");

}
                | lectura {

    fprintf(stdout, ";R35:\t<sentencia_simple> ::= <lectura>\n");

}
                | escritura {

    fprintf(stdout, ";R36:\t<sentencia_simple> ::= <escritura>\n");

}
                | retorno_funcion {

    fprintf(stdout, ";R38:\t<sentencia_simple> ::= <retorno_funcion>\n");

};

bloque: condicional {

    fprintf(stdout, ";R40:\t<bloque> ::= <condicional>\n");

}
    | bucle {

fprintf(stdout, ";R41:\t<bloque> ::= <bucle>\n");

};

asignacion: TOK_IDENTIFICADOR TOK_ASIGNACION exp {

    aux = UsoLocal($1.lexema);

    printf("AUX >= %s %d   %s %d ", aux->lexema, aux->tipo, $3.lexema,$3.tipo);

    if(aux == NULL){ fprintf(stdout,"Error Semantico en la linea %d: No existe la variable a asignar\n",line);
    return -1;}
    if(aux->categoria == FUNCION){ fprintf(stdout,"Error Semantico en la linea %d: la variable es de categoria FUNCION\n",line);
    return -1;}
    if(aux->clase == VECTOR){ fprintf(stdout,"Error Semantico en la linea %d: la variable es de clase VECTOR\n",line);
    return -1;}
    if(aux->tipo != $3.tipo){ fprintf(stdout,"Error Semantico en la linea %d: la asignacion es de tipos distintos\n",line);
    return -1;}

    /*quiere decir que es global*/
    if(UsoExclusivoLocal($1.lexema) == NULL){
        asignar(yyout,$1.lexema,$3.direcciones);
    

    /*quiere decir que es parametro*/ /*FALTA PROBAR*/
    }else if(aux->categoria == PARAMETRO){
        escribir_operando(yyout,$3.lexema,$3.direcciones);
        escribirParametro(yyout,aux->adicional2,num_parametros_actual);
        asignarDestinoEnPila(yyout,$3.direcciones);

    /*quiere decir que es local*/ /*FALTA PROBAR*/
    }else{
        escribir_operando(yyout,$3.lexema,$3.direcciones);
        escribirVariableLocal(yyout,aux->adicional2);
        asignarDestinoEnPila(yyout,$3.direcciones);
    }

fprintf(stdout, ";R43:\t<asignacion> ::= <identificador> = <exp>\n");

}
        | elemento_vector TOK_ASIGNACION exp {

        aux = UsoLocal($1.lexema);
        if(aux == NULL){ 
            fprintf(stdout,"Error Semantico en la linea %d: no existe la variable a asignar\n",line);
            return -1;}
        if(aux->tipo != $3.tipo){
            fprintf(stdout,"Error Semantico en la linea %d: la asignacion es de tipos distintos\n",line);
            return -1;
        }

        asignarDestinoEnPila(yyout,$3.direcciones); /*o es una constante o es una variable*/
        fprintf(stdout, ";R44:\t<asignacion> ::= <elemento_vector> = <exp>\n");

};

elemento_vector: TOK_IDENTIFICADOR TOK_CORCHETEIZQUIERDO exp TOK_CORCHETEDERECHO {

    aux = UsoGlobal($1.lexema);

    if(aux == NULL){
        fprintf(stdout,"****Error Semantico en la linea %d: la variable %s no ha sido declarada\n",line, $1.lexema);
        return -1;
    }

    if(aux->clase != VECTOR){
        fprintf(stdout,"****Error Semantico en la linea %d: la variable %s no es de tipo vector\n",line, $1.lexema);
        return -1;
    }

    if($3.valor_entero >= aux->adicional1){
        fprintf(stdout,"****Error Semantico en la linea %d: se quiere usar una posicion del vector superior a la permitida\n",line);
        return -1;
    }

    if($3.tipo != INT){
        fprintf(stdout,"****Error Semantico en la linea %d: el tipo de la constante del array no es de tipo entero\n",line);
        return -1;
    }

    escribir_elemento_vector(yyout,$1.lexema,MAX_TAMANIO_VECTOR,$3.direcciones);
    $$.tipo = aux->tipo;
    $$.direcciones = 1;

    fprintf(stdout, ";R48:\t<elemento_vector> ::= <identificador> [ <exp> ]\n");

};

condicional: if_exp_sentencias TOK_LLAVEDERECHA {


    ifthenelse_fin(yyout, $1.etiqueta);

    fprintf(stdout, ";R50:\t<condicional> ::= if ( <exp> ) { <sentencias> }\n");


}
        | if_exp_sentencias TOK_LLAVEDERECHA TOK_ELSE TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA {

    ifthenelse_fin(yyout, $1.etiqueta);

    fprintf(stdout, ";R51:\t<condicional> ::= if ( <exp> ) { <sentencias> } else { <sentencias> }\n");

};

if_exp_sentencias: if_exp sentencias {

    $$.etiqueta = $1.etiqueta;
    ifthenelse_fin_then(yyout, $$.etiqueta);

}


if_exp: TOK_IF TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA {
    
    if($3.tipo != BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: la comparacion no es de tipo booleano\n",line);
        return -1;
    }

    $$.etiqueta = etiqueta++;
    ifthen_inicio(yyout, $3.direcciones, $$.etiqueta);
}


bucle:  bucle_exp_sentencias  sentencias TOK_LLAVEDERECHA {

    while_fin(yyout,$1.etiqueta);
    
    fprintf(stdout, ";R52:\t<bucle> ::= while ( <exp> ) { <sentencias> }\n");

};

bucle_exp_sentencias: bucle_exp TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA {
    
    if($3.tipo != BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: la comparacion no es de tipo booleano\n",line);
        return -1;
    }

    $$.direcciones = $3.direcciones;
    $$.etiqueta = $1.etiqueta;
    while_exp_pila(yyout,$$.direcciones,$$.etiqueta);

}

bucle_exp: TOK_WHILE {
    
    $$.etiqueta = etiqueta++;
    while_inicio(yyout,$$.etiqueta);

}



lectura: TOK_SCANF TOK_IDENTIFICADOR {
      if(tablaSimbolosLocal != NULL){ //HAY AMBITO LOCAL

        aux = UsoExclusivoLocal($2.lexema);

        if(aux != NULL){
            if(aux->categoria == FUNCION){
                fprintf(stdout,"****Error Semantico en la linea %d: variable declarada como funcion\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                fprintf(stdout,"****Error Semantico en la linea %d: Variable declarada como vector\n", line);
                return -1;
            }

            /*LEER SI ES UN PARAMETRO*/
            if(aux->categoria == PARAMETRO){
                //escribirParametro(yyout,aux->adicional2,num_parametros_actual);
            }else{/*LEER SI ES UNA LOCAL*/

            }

            

        }else{
            
            aux = UsoGlobal($2.lexema);

            if(aux != NULL){
                if(aux->categoria == FUNCION){
                    fprintf(stdout,"****Error Semantico en la linea %d: variable declarada como funcion\n", line);
                    return -1;
                }

                if(aux->clase == VECTOR){
                    fprintf(stdout,"****Error Semantico en la linea %d: variable declarada como vector\n", line);
                    return -1;
                }

                if(aux->tipo == INT){
                    leer(yyout,$2.lexema,0);
                }else if(aux->tipo == BOOLEAN){
                    leer(yyout,$2.lexema,1);
                }


            }else{
                fprintf(stdout,"****Error Semantico en la linea %d: llamada a la variable %s sin declarar\n", line, $2.lexema);
                return -1;
            }
        }

    }else{

        aux = UsoGlobal($2.lexema);

        if(aux != NULL){
            if(aux->categoria == FUNCION){
                fprintf(stdout,"****Error Semantico en la linea %d: variable declarada como funcion\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                fprintf(stdout,"****Error Semantico en la linea %d: variable declarada como vector\n", line);
                return -1;
            }

            if(aux->tipo == INT){
                leer(yyout,$2.lexema,0);
            }else if(aux->tipo == BOOLEAN){
                leer(yyout,$2.lexema,1);
            }


        }else{
            fprintf(stdout,"****Error Semantico en la linea %d: llamada a la variable %s sin declarar\n", line, $2.lexema);
            return -1;
        }

    }

    fprintf(stdout, ";R54:\t<lectura> ::= scanf <identificador>\n");
}
;

escritura: TOK_PRINTF exp {

    if($2.tipo == INT){
        escribir(yyout,$2.direcciones,0);    
    }else{
        escribir(yyout,$2.direcciones,1);
    }

    fprintf(stdout, ";R56:\t<escritura> ::= printf <exp>\n");

};

retorno_funcion: TOK_RETURN exp {

    retornarFuncion(yyout,$2.direcciones);
    fn_return++;

    fprintf(stdout, ";R61:\t<retorno_funcion> ::= return <exp>\n");
};

exp: exp TOK_MAS exp {
    
    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        sumar(yyout,$1.direcciones,$3.direcciones);

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: suma de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R72:\t<exp> ::= <exp> + <exp>\n");

}
    | exp TOK_MENOS exp {

    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        restar(yyout,$1.direcciones,$3.direcciones);

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: resta de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R73:\t<exp> ::= <exp> - <exp>\n");

}
    | exp TOK_DIVISION exp {

    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        dividir(yyout, $1.direcciones, $3.direcciones);

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: division de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R74:\t<exp> ::= <exp> / <exp>\n");

}
    | exp TOK_ASTERISCO exp {

    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        multiplicar(yyout,$1.direcciones,$3.direcciones);

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: multiplicacion de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R75:\t<exp> ::= <exp> * <exp>\n");


}
    | TOK_MENOS exp %prec MENOSU {


    if($2.tipo == INT){
        $$.tipo = INT;
        $$.direcciones = 0;

        cambiar_signo(yyout,$2.direcciones);
    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: cambio de signo en variable que no es de tipo INT\n", line);
        return -1;
    }

    fprintf(stdout, ";R76:\t<exp> ::= - <exp>\n");

}
    | exp TOK_AND exp {

    if($1.tipo == BOOLEAN && $3.tipo == BOOLEAN){

        $$.tipo = BOOLEAN;
        $$.direcciones = 0;

        y(yyout,$1.direcciones,$3.direcciones);

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: and de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R77:\t<exp> ::= <exp> && <exp>\n");
}
    | exp TOK_OR exp {

    if($1.tipo == BOOLEAN && $3.tipo == BOOLEAN){

        $$.tipo = BOOLEAN;
        $$.direcciones = 0;

        o(yyout,$1.direcciones,$3.direcciones);

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: or de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R78:\t<exp> ::= <exp> || <exp>\n");
}
    | TOK_NOT exp {

    if($2.tipo == BOOLEAN){
        $$.tipo = BOOLEAN;
        $$.direcciones = 0;

        no(yyout,$2.direcciones,cuantos_no);
        cuantos_no++;

    }else{
        fprintf(stdout,"****Error Semantico en la linea %d: negacion de variable que no es de tipo BOOLEAN\n",line);
        return -1;
    }

    fprintf(stdout, ";R79:\t<exp> ::= ! <exp>\n");
}
    | TOK_IDENTIFICADOR {

    strcpy($$.lexema,$1.lexema);

    if(tablaSimbolosLocal != NULL){
        aux = UsoExclusivoLocal($1.lexema);
        if(aux != NULL){ //BUSQUEDA EN LOCAL
            if(aux->categoria == FUNCION){
                fprintf(stdout,"****Error Semantico en la linea %d: variable no es de la categoria correspondiente\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                fprintf(stdout,"****Error Semantico en la linea %d: variable no es de la clase correspondiente\n", line);
                return -1;
            }


            if(aux->categoria == VARIABLE){
                escribirVariableLocal(yyout,aux->adicional2);
            }else if(aux->categoria == PARAMETRO){
                escribirParametro(yyout,aux->adicional2,num_parametros_actual);
            }

            $$.tipo = aux->tipo;
            $$.direcciones = 1;

        }else{
            
            aux =  UsoGlobal($1.lexema);
            
            if(aux != NULL){
                
                if(aux->categoria == FUNCION){
                    fprintf(stdout,"****Error Semantico en la linea %d: variable no es de la categoria correspondiente\n", line);
                    return -1;
                }

                if(aux->clase == VECTOR){
                    fprintf(stdout,"****Error Semantico en la linea %d: variable no es de la clase correspondiente\n", line);
                    return -1;
                }

                escribir_operando(yyout,$1.lexema,1); //Direccion

                $$.tipo = aux->tipo;
                $$.direcciones = 1;              


            }else{
                fprintf(stdout,"****Error Semantico en la linea %d: llamada a variable sin definir\n", line);
                return -1;
            }
        }
        
    }else{ //BUSQUEDA EN GLOBAL

        aux =  UsoGlobal($1.lexema);
        if(aux != NULL){
            if(aux->categoria == FUNCION){
                fprintf(stdout,"****Error Semantico en la linea %d: variable no es de la categoria correspondiente\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                fprintf(stdout,"****Error Semantico en la linea %d: variable no es de la clase correspondiente\n", line);
                return -1;
            }

            escribir_operando(yyout,$1.lexema,1); //Direccion


            $$.tipo = aux->tipo;
            $$.direcciones = 1;          

        }else{
            fprintf(stdout,"****Error Semantico en la linea %d: llamada a variable sin definir\n", line);
            return -1;
        }

    }


    fprintf(stdout, ";R80:\t<exp> ::= <identificador>\n");

}
    | constante {

    snprintf(aux_char, sizeof(aux_char), "%d", $1.valor_entero);
    escribir_operando(yyout,aux_char,$1.direcciones);
    $$.tipo = $1.tipo;
    $$.direcciones = $1.direcciones;
    $$.valor_entero = $1.valor_entero;

    fprintf(stdout, ";R81:\t<constante>\n");

}
    | TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO {

    $$.tipo = $2.tipo;
    $$.direcciones = $2.direcciones;

    fprintf(stdout, ";R82:\t<exp> ::= ( <exp> )\n");

}
    | TOK_PARENTESISIZQUIERDO comparacion TOK_PARENTESISDERECHO {

    $$.tipo = $2.tipo;
    $$.direcciones = $2.direcciones;

    fprintf(stdout, ";R83:\t<exp> ::= ( <comparacion> )\n");

}
    | elemento_vector {

    $$.tipo = $1.tipo;
    $$.direcciones = $1.direcciones;

    fprintf(stdout, ";R85:\t<exp> ::= <elemento_vector>\n");

}
    | TOK_IDENTIFICADOR TOK_PARENTESISIZQUIERDO lista_expresiones TOK_PARENTESISDERECHO {



    if((aux = UsoLocal($1.lexema)) == NULL){
        fprintf(stdout,"****Error Semantico en la linea %d: la funcion %s no ha sido declarada\n",line,$1.lexema);
        return -1;
    }


    if(aux->categoria != FUNCION){
        fprintf(stdout,"****Error Semantico en la linea %d: la variable no esta declarada como funcion\n",line);
        return -1;
    }

    if(aux->adicional1 != comprobacion_parametros){
        fprintf(stdout,"****Error Semantico en la linea %d: numero incorrecto de parametros\n",line);
        return -1;
    }

    llamarFuncion(yyout, aux->lexema, aux->adicional1);
    en_explist=0;
    $$.tipo = aux->tipo;
    $$.direcciones = 0;

    fprintf(stdout, ";R88:\t<exp> ::= <identificador> ( <lista_expresiones> )\n");

};


lista_expresiones: exp resto_lista_expresiones {

    comprobacion_parametros = comprobacion_parametros + 1;    
    operandoEnPilaAArgumento(yyout,$1.direcciones);

    fprintf(stdout, ";R89:\t<lista_expresiones> ::= <exp> <resto_lista_expresiones>\n");

}
                | /* LAMBDA */ {

    comprobacion_parametros = 0;
    fprintf(stdout, ";R90:\t<lista_expresiones> ::=\n");

};

resto_lista_expresiones: TOK_COMA exp resto_lista_expresiones {


    comprobacion_parametros = comprobacion_parametros + 1;
    fprintf(stdout, ";R91:\t<resto_lista_expresiones> ::= , <exp> <resto_lista_expresiones>\n");

}
                    | /* LAMBDA */ {

    comprobacion_parametros = 0;
    fprintf(stdout, ";R92:\t<resto_lista_expresiones> ::=\n");

};

comparacion: exp TOK_IGUAL exp {

    if($1.tipo == BOOLEAN || $3.tipo == BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: las variables a comparar no pueden ser de tipo booleano\n",line);
        return -1;
    }

    $$.tipo = BOOLEAN;
    $$.direcciones = 0;

    igual(yyout,$1.direcciones,$3.direcciones,num_comparaciones++);

    fprintf(stdout, ";R93:\t<comparacion> ::= <exp> == <exp>\n");

}
        | exp TOK_DISTINTO exp {


    if($1.tipo == BOOLEAN || $3.tipo == BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: las variables a comparar no pueden ser de tipo booleano\n",line);
        return -1;
    }

    $$.tipo = BOOLEAN;
    $$.direcciones = 0;

    distinto(yyout,$1.direcciones,$3.direcciones,num_comparaciones++);


    fprintf(stdout, ";R94:\t<comparacion> ::= <exp> != <exp>\n");

}
        | exp TOK_MENORIGUAL exp {


    if($1.tipo == BOOLEAN || $3.tipo == BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: las variables a comparar no pueden ser de tipo booleano\n",line);
        return -1;
    }

    $$.tipo = BOOLEAN;
    $$.direcciones = 0;

    menor_igual(yyout,$1.direcciones,$3.direcciones,num_comparaciones++);


    fprintf(stdout, ";R95:\t<comparacion> ::= <exp> <= <exp>\n");

}
        | exp TOK_MAYORIGUAL exp {


    if($1.tipo == BOOLEAN || $3.tipo == BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: las variables a comparar no pueden ser de tipo booleano\n",line);
        return -1;
    }

    mayor_igual(yyout,$1.direcciones,$3.direcciones,num_comparaciones++);


    $$.tipo = BOOLEAN;
    $$.direcciones = 0;

    fprintf(stdout, ";R96:\t<comparacion> ::= <exp> >= <exp>\n");

}
        | exp TOK_MENOR exp {


    if($1.tipo == BOOLEAN || $3.tipo == BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: las variables a comparar no pueden ser de tipo booleano\n",line);
        return -1;
    }

    $$.tipo = BOOLEAN;
    $$.direcciones = 0;

    menor(yyout,$1.direcciones,$3.direcciones,num_comparaciones++);


    fprintf(stdout, ";R97:\t<comparacion> ::= <exp> < <exp>\n");

}
        | exp TOK_MAYOR exp {


    if($1.tipo == BOOLEAN || $3.tipo == BOOLEAN){
        fprintf(stdout,"****Error Semantico en la linea %d: las variables a comparar no pueden ser de tipo booleano\n",line);
        return -1;
    }

    $$.tipo = BOOLEAN;
    $$.direcciones = 0;

    mayor(yyout,$1.direcciones,$3.direcciones,num_comparaciones++);


    fprintf(stdout, ";R98:\t<comparacion> ::= <exp> > <exp>\n");

}
;

constante:
constante_logica{

    $$.tipo=$1.tipo;
    $$.direcciones=$1.direcciones;
    $$.valor_entero=$1.valor_entero;

    fprintf(stdout, ";R99:\t<constante> ::= <constante_logica>\n");

}| constante_entera {

    $$.tipo=$1.tipo;
    $$.direcciones=$1.direcciones;
    $$.valor_entero=$1.valor_entero;

    fprintf(stdout, ";R100:\t<constante> ::= <constante_entera>\n");
};

constante_logica: TOK_TRUE {

    $$.tipo=BOOLEAN; 
    $$.direcciones=0; 
    $$.valor_entero=1; 
    fprintf(stdout, ";R102:\t<constante_logica> ::= true\n");

}
                | TOK_FALSE {

    $$.tipo=BOOLEAN; 
    $$.direcciones=0; 
    $$.valor_entero=0; 
    fprintf(stdout, ";R103:\t<constante_logica> ::= false\n");

};

constante_entera: TOK_CONSTANTE_ENTERA {
   
    $$.tipo=INT; 
    $$.direcciones=0; 
    $$.valor_entero=$1.valor_entero; 
    fprintf(stdout, ";R104:\t<constante_entera> ::= <numero>\n");

};

identificador: TOK_IDENTIFICADOR {

    if(tablaSimbolosLocal != NULL){ //EXISTE LA LOCAL
        aux = UsoExclusivoLocal($1.lexema);
        if(aux != NULL){ //YA EXISTE EL ELEMENTO
            //INDICARLO CON PRINT
            fprintf(stdout,"****Error Semantico en linea %d: variable duplicada\n", line);
            return -1;
        }else{
            //INSERTARLO EN LA TABLA LOCAL MIRANDO QUE SU CLASE SEA ESCALAR
            if(clase_actual != ESCALAR){
                //ERROR DE DECLARACION, INDICAMOS
                fprintf(stdout,"****Error Semantico en la linea %d: variable local de tipo incorrecto\n",line);
                return -1;
            }else{
                //INSERTARLO EN LA TABLA LOCAL(Revisar parametros)
                if(DeclararLocal($1.lexema,VARIABLE,tipo_actual,clase_actual,0,pos_variable_local_actual) == OK){
                    pos_variable_local_actual++;
                    num_variables_locales_actual++;
                }else{
                    fprintf(stdout,"****Error Semantico en la linea %d: fallo al crear la variable %s",line,$1.lexema);
                    return -1;
                }
            }
        }
    }else{
        aux = UsoExclusivoGlobal($1.lexema);
        if(aux != NULL){ //YA EXISTE EL ELEMENTO
            //INDICARLO CON PRINT
            fprintf(stdout,"****Error Semantico en la linea %d: variable duplicada\n", line);
            return -1;
        }else{
            //INSERTARLO EN LA TABLA GLOBAL(Revisar parametros)
            if(DeclararGlobal($1.lexema,VARIABLE,tipo_actual,clase_actual,tamanio_vector_actual,0) == OK){
                tamanio_vector_actual=0;
            }else{
                fprintf(stdout,"****Error Semantico en la linea %d: fallo al crear la variable %s",line,$1.lexema);
                return -1;
            }
            
        }
    }

    fprintf(stdout, ";R108:\t<identificador> ::= TOK_IDENTIFICADOR\n");
};

idpf: TOK_IDENTIFICADOR{

    if(tablaSimbolosLocal != NULL){
        aux = UsoExclusivoLocal($1.lexema);
        if(aux != NULL){
            fprintf(stdout,"****Error Semantico en la linea %d: acceso a la variable %s sin declarar\n", line, $1.lexema);
            return -1;
        }else{
            if(DeclararLocal($1.lexema,PARAMETRO,tipo_actual,ESCALAR,0,pos_parametro_actual) == OK){
                pos_parametro_actual++;
                num_parametros_actual++;
            }else{
                fprintf(stdout,"****Error Semantico en la linea %d: fallo al crear el parametro %s",line,$1.lexema);
                return -1;
            }
        }
    }else{
        fprintf(stdout,"****Ambito local no esta abierto\n");
        fprintf(stdout,"****Error Semantico en linea %d ,columna %d\n", line, col);
        return -1;
    }

};

%%

void yyerror (const char* err){
        if(error == 0){
                fprintf(stdout,"****Error sintactico en [lin %d, col %d]\n", line, col-yyleng);
        }
        error = 0;
}