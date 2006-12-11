%{
#include <stdio.h>
#include <limits.h>
#include "iburg.h"
static char rcsid[] = "$Id: gram.y 21 1996-05-02 19:31:17Z drh $";
static int yylineno = 0;
%}
%union {
	int n;
	char *string;
	Tree tree;
}
%term TERMINAL
%term START
%term PPERCENT

%token  <string>        ID
%token  <n>             INT
%type	<string>	lhs
%type   <tree>          tree
%type   <n>             cost
%%
spec	: decls PPERCENT rules		{ yylineno = 0; }
	| decls				{ yylineno = 0; }
	;

decls	: /* lambda */
	| decls decl
	;

decl	: TERMINAL blist '\n'
	| START lhs   '\n'		{
		if (nonterm($2)->number != 1)
			yyerror("redeclaration of the start symbol\n");
		}
	| '\n'
	| error '\n'			{ yyerrok; }
	;

blist	: /* lambda */
	| blist ID '=' INT      	{ term($2, $4); }
	;

rules	: /* lambda */
	| rules lhs ':' tree '=' INT cost ';' '\n'	{ rule($2, $4, $6, $7); }
	| rules '\n'
	| rules error '\n'		{ yyerrok; }
	;

lhs	: ID				{ nonterm($$ = $1); }
	;

tree	: ID                            { $$ = tree($1, NULL, NULL); }
	| ID '(' tree ')'               { $$ = tree($1,   $3, NULL); }
	| ID '(' tree ',' tree ')'      { $$ = tree($1,   $3, $5); }
	;

cost	: /* lambda */			{ $$ = 0; }
	| '(' INT ')'			{ $$ = $2; }
	;
%%
#include <stdarg.h>
#include <ctype.h>
#include <string.h>

int errcnt = 0;
FILE *infp = NULL;
FILE *outfp = NULL;
static char buf[BUFSIZ], *bp = buf;
static int ppercent = 0;

static int get(void) {
	if (*bp == 0) {
		if (fgets(buf, sizeof buf, infp) == NULL)
			return EOF;
		bp = buf;
		yylineno++;
		while (buf[0] == '%' && buf[1] == '{' && buf[2] == '\n') {
			for (;;) {
				if (fgets(buf, sizeof buf, infp) == NULL) {
					yywarn("unterminated %{...%}\n");
					return EOF;
				}
				yylineno++;
				if (strcmp(buf, "%}\n") == 0)
					break;
				fputs(buf, outfp);
			}
			if (fgets(buf, sizeof buf, infp) == NULL)
				return EOF;
			yylineno++;
		}
	}
	return *bp++;
}

void yyerror(char *fmt, ...) {
	va_list ap;

	va_start(ap, fmt);
	if (yylineno > 0)
		fprintf(stderr, "line %d: ", yylineno);
	vfprintf(stderr, fmt, ap);
	if (fmt[strlen(fmt)-1] != '\n')
		 fprintf(stderr, "\n");
	errcnt++;
}

int yylex(void) {
	int c;

	while ((c = get()) != EOF) {
		switch (c) {
		case ' ': case '\f': case '\t':
			continue;
		case '\n':
		case '(': case ')': case ',':
		case ';': case '=': case ':':
			return c;
		}
		if (c == '%' && *bp == '%') {
			bp++;
			return ppercent++ ? 0 : PPERCENT;
		} else if (c == '%' && strncmp(bp, "term", 4) == 0
		&& isspace(bp[4])) {
			bp += 4;
			return TERMINAL;
		} else if (c == '%' && strncmp(bp, "start", 5) == 0
		&& isspace(bp[5])) {
			bp += 5;
			return START;
		} else if (isdigit(c)) {
			int n = 0;
			do {
				int d = c - '0';
				if (n > (SHRT_MAX - d)/10)
					yyerror("integer greater than %d\n", SHRT_MAX);
				else
					n = 10*n + d;
				c = get();
			} while (isdigit(c));
			bp--;
			yylval.n = n;
			return INT;
		} else if (isalpha(c)) {
			char *p = bp - 1;
			while (isalpha(c) || isdigit(c) || c == '_')
				c = get();
			bp--;
			yylval.string = alloc(bp - p + 1);
			strncpy(yylval.string, p, bp - p);
			yylval.string[bp - p] = 0;
			return ID;
		} else if (isprint(c))
			yyerror("illegal character `%c'\n", c);
		else
			yyerror("illegal character `\0%o'\n", c);
	}
	return 0;
}

void yywarn(char *fmt, ...) {
	va_list ap;

	va_start(ap, fmt);
	if (yylineno > 0)
		fprintf(stderr, "line %d: ", yylineno);
	fprintf(stderr, "warning: ");
	vfprintf(stderr, fmt, ap);
}
