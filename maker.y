%{
#include <iostream>
#include <vector>
#include <stack>
#include "ASTNode.h"
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);
class SymTable* current;
std::vector<SymTable*> Vector_Tabele;
std::stack<SymTable*> Stack_Table;
int errorCount = 0;
%}
%union {
     char* string;
}
%{
     void check_existance(SymTable*currento, const char* a , const char* b , const char* c){
          if(!currento->existsId(b)) {
                    currento->addVar(a,b, c);
               } else {
                    errorCount++; 
                    yyerror("Variable already defined");
                    }
     }
     %}
%token  BGIN END ASSIGN NR TRUTH_VALUE CBEGIN CEND REAL CTRL CONNECT CMP
%token<string> ID TYPE Class_ID Class_Type
%start progr
%left '+' '-' 
%left '*' '/'
%%
progr :  declarations classes main {if (errorCount == 0) cout<< "The program is correct!" << endl;}
      |  declarations main {if (errorCount == 0) cout<< "The program is correct!" << endl;}
      ;

main : BGIN  {SymTable* currentmain;     
     currentmain = new SymTable("main");
     Stack_Table.push(currentmain);
     Vector_Tabele.push_back(currentmain);} list END  {Stack_Table.pop();
                                    current=Stack_Table.top();}
     ;
//Listul e ffolosie in MAIN si in Control functions
list :  statement ';' 
     | list statement ';'
     ;

statement: ID ASSIGN e	     	 
         | ID '(' call_list ')' //Ce-i asta???................................DAca descoperim ce e pot baga Decl-u
         | ID ASSIGN TRUTH_VALUE {if (current->getValueType($1)!="bool"){
                                        errorCount++; 
                                        yyerror("Variable is not bool");
                                    }
                                 }
          | CTRL  condition_chain  CBEGIN list CEND
         ;
condition_chain: '(' condition ')'
               | '(' condition_chain CONNECT condition ')'
               ;
condition: e CMP e
         ;
declarations: fundamental_type arrays
            | fundamental_type
            | arrays
            | /* epsilon */
            ;

fundamental_type : decl           
	            |  fundamental_type decl   
	            ;

decl       : TYPE ID  { check_existance(Stack_Table.top() , $1 , $2 , "func");
                        class SymTable* fucntion_scope;
                        fucntion_scope=new SymTable($2);
                        Stack_Table.push(fucntion_scope);
                        current=fucntion_scope;
                        Vector_Tabele.push_back(current);
                        } 
             '(' list_param ')' ';'{
                                    Stack_Table.pop();
                                    current=Stack_Table.top();
                                   }
           | TYPE ID ';'{check_existance(Stack_Table.top() , $1 , $2 , "var");}
           ;

arrays : arr
       | arrays arr
       ;

arr : TYPE ID arr_list ';' {check_existance(Stack_Table.top() , $1 , $2 , "pointer");
                           }
       ;

arr_list : '[' NR ']' arr_list
         | '[' NR ']'
         ;
classes : class
        | classes class
        ;

class :  Class_Type Class_ID ':' CBEGIN {
                                        check_existance(current , $1 , $2 , "class");
                                        class SymTable* class_scope;//TTrebuie sa vad cum propag pointeru tabelului in DECL
                                        class_scope=new SymTable($2);
                                        Stack_Table.push(class_scope);
                                        current=class_scope;
                                        Vector_Tabele.push_back(current);
                                        }
                              declarations CEND ';' {
                                                            Stack_Table.pop();
                                                       current=Stack_Table.top();
                                                    }
      ;

list_param : param 
            | list_param ','  param 
            ;

            
param : TYPE ID {check_existance(Stack_Table.top() , $1 , $2 ,"var");}
      ; 
      

     


e : e '+' e   {}
  | e '*' e   {}
  | e '-' e   {}
  | e '/' e   {}
  |'(' e ')'  {}
  | NR        {}
  | REAL      {}
  | ID        {}
  ;

        
call_list : e
           | call_list ',' e
           | statement
           ;
%%
void yyerror(const char * s){
     cout << "error:" << s << " at line: " << yylineno << endl;
}

int main(int argc, char** argv){
     yyin=fopen(argv[1],"r");
     current = new SymTable("global");
     Stack_Table.push(current);
     Vector_Tabele.push_back(current);
     yyparse();
     Stack_Table.push(current);
     cout << "Variables:" <<endl;
     for (auto i : Vector_Tabele){
          i->printVars();
          delete i;
     }
} 