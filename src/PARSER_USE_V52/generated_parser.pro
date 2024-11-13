


PREDICATES

  expect( CURSORTOq, TOKL, TOKL )
  syntax_error( string , TOKL )


PREDICATES
  s_atom_list( TOKL , TOKL , ATOM_LIST )
  s_atom( TOKL , TOKL , ATOM )
  s_operator( TOKL , TOKL , OPERATOR )
  s_expr( TOKL , TOKL , EXPR )

CLAUSES
  s_atom( [ t( variabel( STRING ) , _ ) | LL ] , LL , variabel( STRING ) ):- !.
  s_atom( [ t( number(  Rea  ) , _ ) | LL ] , LL , number(  Rea  ) ):- !.
  s_atom([ t( name( STRING ) ,_ ) | LL ], LL, namex( STRING ) ):- !.
  % s_atom(LL,_,_):-syntax_error(atom,LL),fail.
  
  s_atom( LL1 , LL0 , metta_sub( EXPR ) ):-	s_expr( LL1 , LL0 , EXPR ) , !.
  s_atom( LL , _ , _ ):- syntax_error( "atom" , LL ) , fail.
%--------
  s_operator( [ t( equal , _ ) | LL] , LL , equal ):-!.
%  s_operator( [t( simple_deduction_strength_formula , _ )|LL] , LL , simple_deduction_strength_formula ):-!.
  s_operator( [ t( conditional , _ ) | LL] , LL , conditional ):-!.
  s_operator( [ t( conjuction , _ ) | LL] , LL , conjuction ):-!.
%  s_operator( [t( conditional_probability_consistency , _ )|LL] , LL , conditional_probability_consistency ):-!.
  s_operator( [ t( smallerthan , _ ) | LL] , LL , smallerthan ):-!.
  s_operator( [ t( plus , _ ) | LL ] , LL , plus ):-!.
  s_operator( [ t( multiplication , _ ) | LL] , LL , multiplication ):-!.
  s_operator( [ t( division , _ ) | LL ] , LL , division ):-!.
  s_operator( [ t( minus , _ ) | LL ] , LL , minus ):-!.
  s_operator( [ t( name( String ) ,_ ) | LL ], LL, namex( String ) ):- !.
  s_operator( [ t( variabel( String ) ,_ ) | LL ], LL, variabel( String ) ):- !.
  s_operator( LL , _ , _ ):- syntax_error( "operator" , LL ) , fail.
%-----
  s_expr( [ t( exclamation , _ ), t( lpar , _ ) | LL1 ] , LL0 , exclama_atom_list( Operator , Atom_List ) ):-! , 
	s_operator( LL1 , LL2 , Operator ) , 
	s_atom_list( LL2 , LL3 , Atom_List ) , 
	expect( t( rpar , _ ) , LL3 , LL0 ).
	
  s_expr( [ t( lpar , _ ) | LL1 ] , LL0 , par_atom_list( Operator , Atom_List ) ):-! , 
	s_operator( LL1 , LL2 , Operator ) , 
	s_atom_list( LL2 , LL3 , Atom_List ) , 
	expect( t( rpar , _ ) , LL3 , LL0 ).
  s_expr( LL , _ , _ ):- syntax_error( "expr" , LL ) , fail.
%-----
  s_atom_list( LL1 , LL0 , [ Atom | Atom_List] ):-
	s_atom( LL1 , LL2 , Atom ) , ! , 
	s_atom_list( LL2 , LL0 , Atom_List ).
  s_atom_list( LL , LL , [] ).


CLAUSES

  expect(TOK, [ TOK | L ] , L ).

  syntax_error( Type_mess , [ Token | _Tok_lis ] ):-  
    Type_mess = "operator", 
    % term_str( CURSORTOq, Token, Sx ), 
	 term_str( TOKL, [ Token | _Tok_lis ], Sx ), 
%    format( Hh, "", ), 
	concat( "Parse error : ", Type_mess, C3 ),
	dlg_Note( C3, Sx), !.
  
  syntax_error( _ , _ ).



DOMAINS
  NUMBER_OF_EXTRA_CHARACTERS 	= INTEGER
  NUMBER_OF_SPACES		= INTEGER

PREDICATES
  is_a_space( CHAR )
  scan( CURSORq, SOURCE, TOKL )
  skip_spaces( SOURCE, SOURCE, NUMBER_OF_SPACES )
  string_tokenq( STRING, TOK )
  get_fronttoken( string, string, string) - ( i,o,o)
  
CLAUSES
  is_a_space( ' ' ).	
  is_a_space( '\t' ).	
  is_a_space( '\n' ).

% add manually 11:24 8-9-2024

get_fronttoken( Source, Bg, Res2 ):-
  fronttoken( Source, Fronttoken, Rest),   Fronttoken = "\"", !,
  searchstring( Rest, "\"", Pos ), P2 = Pos - 1, frontstr( P2, Rest, Bg, Res ),
  frontstr( 1, Res, _, Res2 ).

% we can change this 
get_fronttoken( Source, Bg3, Rest2 ):-
  fronttoken( Source, Fronttoken, Rest),   Fronttoken = "$", 
  fronttoken( Rest, Fronttoken2, Rest2), !,
  concat( "$", Fronttoken2, Bg3 ).

%get_fronttoken( Source, Bg, Res ):-
%  searchstring( Source, " ", Pos ), !, P2 = Pos - 1, frontstr( P2, Source, Bg, Res ).
%get_fronttoken( Source, Bg, Res ):-
%  searchstring( Source, "\n", Pos ), !, P2 = Pos - 1, frontstr( P2, Source, Bg, Res ).
%get_fronttoken( Source, Bg, Res ):-
%  searchstring( Source, "\t", Pos ), !, P2 = Pos - 1, frontstr( P2, Source, Bg, Res ).
  

get_fronttoken( Source, Fronttoken, Rest ):- fronttoken( Source, Fronttoken, Rest), !.
	 

% arrange for the Quote here  
  scan( Starting_Position, Source, [ t(Token, Location_Of_Token) | Tail ]) :-
	skip_spaces( Source, New_Source, Number_Of_Spaces),
	Location_Of_Token = Starting_Position + Number_Of_Spaces,
	get_fronttoken( New_Source, Fronttoken, Rest ),	!,

	Lower_Case_Fronttoken = Fronttoken,
	
	string_tokenq( Lower_Case_Fronttoken, Token),
	str_len( Fronttoken, Length_Of_Fronttoken),
	New_Starting_Position = Location_Of_Token + Length_Of_Fronttoken,
	scan( New_Starting_Position, Rest, Tail ).
  scan( _, _, [] ).

  skip_spaces( Source, New_Source, Number_Of_Spaces) :-
	frontchar( Source, Char, Source1),
	is_a_space( Char ),
	!,
	skip_spaces( Source1, New_Source, Number_Of_Spaces_In_Source1),
	Number_Of_Spaces = Number_Of_Spaces_In_Source1 + 1.
  skip_spaces( Source, Source, 0).


% Only let uncommented hier the ones that are being used in the
% chosen grammar-file 

%  string_tokenq(":", 	colon ) :- !.
%  string_tokenq("=", 	equalsign ) :- !.
  string_tokenq( "=", 	equal ) :- !.
  % string_tokenq("simple_deduction_strength_formula", 	simple_deduction_strength_formula ) :- !.

  string_tokenq( "if", 	conditional ) :- !.
  string_tokenq( "and", 	 conjuction ) :- !.

  %string_tokenq("conditional_probability_consistency", 	conditional_probability_consistency ) :- !.
  string_tokenq( "<", 	smallerthan ) :- !.
  string_tokenq( "+", 	plus ) :- !.
  string_tokenq( "*", 	multiplication ) :- !.
  string_tokenq( "!", 	exclamation ) :- !.
   
   
  string_tokenq( "/", 	division ) :- !.
  string_tokenq( "-", 	minus ) :- !.  
  
  string_tokenq( "(", 	lpar ) :- !.
  string_tokenq( ")",	rpar ) :- !.


% OPTIONAL
%  string_tokenq(";", 	semicolon ) :- !.
%  string_tokenq("?", 	interrogation ) :- !.
%  string_tokenq("\"",	quote ) :- !.
  string_tokenq( String, 	number(Rea)) :- str_real(String, Rea), !.

  string_tokenq( Str, 	variabel(Str) ) :-  
    frontstr( 1, Str, Bg, _Res ), Bg = "$",	!.

  string_tokenq( String, 	name(String) ) :-  	!.


% everything for calculations_simple.grm
%  string_tokenq("(", 	lpar) :- !.
%  string_tokenq(")",	rpar) :- !.
%  string_tokenq("/",	div) :- !.
%  string_tokenq("-", 	minus) :- !.
%  string_tokenq("+",	plus) :- !.
%  string_tokenq("*", 	mult) :- !.
%  string_tokenq(STRING, 	number(INTEGER)) :- str_int(STRING, INTEGER), !.
%  string_tokenq(STRING, 	number(REAL)) :- str_real(STRING, REAL), !.
%  string_tokenq(STRING, 	variabel(STRING)) :-  !.
% OPTIONAL
      %  string_tokenq("^", 	power) :- !.
      %  string_tokenq("$", 	expo) :- !.
      %  string_tokenq("#", 	log) :- !.
      %  string_tokenq("@", 	lgn ) :- !.


% DEZE toevoegen zodra je een grammar gebruikt  waarin deze voorkomen 

  


%PREDICATES
%parse( TOKL, EXPR )
%tokenize( SOURCE, TOKL )


CLAUSES
  
  
%  evaluate_expression3(EXPR,R2) :-
    % write(EXPR),
    %  dlg_Note(EXPR),
    % trap(term_str(SOURCE,TT,EXPR),_,fail),!,
	% dlg_Note(EXPR),
%    trap(evaluate_expression(EXPR,R2),_,fail).
%  evaluate_expression( EXPR, R2 ):-
%  	tokenize( EXPR, TOKENS ),	parse( TOKENS, TERM ),  	!,
%  	calculate2( TERM, R2 ).
%  evaluate_expression( A, A ) :- !.

tokenize( Expr, Tokens ) :- scan( 0, Expr, Tokens ).
 
 
% deze moet ook dynamisch 
% parse(TOKENS, TERM) :-   	s_sexp(TOKENS, UNUSED_TOKENS, TERM),  	UNUSED_TOKENS = [].



%include "hlptopic.con"
%include "t8w.con"


parse( Tokens, Term ) :-   	s_expr( Tokens, Unused_Tokens, Term ),  	Rest_Tokens = []. 

%----
parse_report( Tokens, Term, Rest_Tokens ) :-   	s_expr( Tokens, Rest_Tokens, Term ). 



%-----
parse_rest( Rest_tokens, _Count ):- Rest_Tokens = [] , ! . 

parse_rest( List_tokens, Count ):-
 parse_report( List_tokens, Termx, Rest_Tokens ),
 
 assert( term_parsed( Count, Termx ) ), 
 term_str( EXPR , Termx , Res2 ),  write( Res2 , "\n" ),
 Count2 = Count + 1,
 parse_rest( Rest_Tokens, Count2 ).
    
%---
predicates

print_transpiled( EXPR ) - ( i )
print_transpiled2( ATOM_LIST , string ) - ( i , i)

string_replace_tag(string, string, string, string ) - ( i,i,i,o)
display_results2()


rebuild_transpiled_sub( integer, string, slist, string , slist ) - ( i, i, i, o , o )
change_adhoc( string, string ) - ( i, o )

rebuild_transpiled_string( integer, string , slist, string, slist  ) - ( i, i, i, o, o )

rebuild_transpiled_strings( ATOM_LIST , slist, ATOM_LIST ) - ( i, i, o )

str_after( string, string, string, string ) - ( i,i,o,o)

which_list_for_second( integer, slist, slist, slist ) - ( i, i,i,o)


assert_var( string ) 
assert_vars( ATOM_LIST ) - ( i )
assert_variabels_concerned( integer ) - ( i )
assert_variabels_concerned_list( ilist ) - ( i )

rebuild_transpiled_sub2_vars_str( ATOM_LIST , slist , slist ) - ( i, i, o )
add_when_not_in_list( slist, slist , slist ) - ( i,i,o)
filter_which_are_not_in_list( slist, slist , slist, slist ) - ( i,i,o,o)

is_member( string , slist ) - ( i , i )
is_not_member( string , slist ) - ( i , i )
reverse_slist( slist, slist, slist ) - ( i, i, o )

write_body_subs( integer, ATOM_LIST ) - ( i, i )
write_head_body( integer, ATOM_LIST ) - ( i, i )
write_head_body2( integer, OPERATOR, ATOM_LIST ) - ( i, i, i )
update_head_subs( integer, integer , string ) - ( i , i , i )

try_get_head_vars2( integer, ilist, slist, string ) - ( i,i,i,o)

try_get_head_vars( integer, string, string ) - ( i, i, o )

clean_var_list( slist , slist ) - ( i,o)
temp_clean_str_var_lis( string, string ) - ( i,o)


clauses

update_head_subs( Nx,  Nx_sub  , Substr):- retract( head_subs( Nx, Lis, Slis ) ), !, assert( head_subs( Nx, [ Nx_sub | Lis ] ,[ Substr | Slis ]) ).
update_head_subs( Nx,  Nx_sub  , Substr ):-  !, assert( head_subs( Nx, [ Nx_sub ] , [ Substr ]) ).

reverse_slist( [], Varslist2 , Varslist2 ):- !.
reverse_slist( [ Varx | Vars_str_list ], Varslist , Varslist2 ):-
  reverse_slist(  Vars_str_list , [ Varx | Varslist ] , Varslist2 ).


is_member( Varx, [ Varx | _Varslist ] ):- !.
is_member( Varx, [ _ | Varslist ] ):-  is_member( Varx, Varslist  ), !.

is_not_member( Varx, Varslist  ):- is_member( Varx, Varslist  ), !, fail . 
is_not_member( _Varx, _Varslist  ):- !.




%filter_which_are_not_in_list( [], Varslist , Varslist2 ):- reverse_slist( Varslist , [], Varslist2 ), !.

% filter_which_are_not_in_list( [ Varx | Vars_str_list ], [ Varx | Varslist ] , Varslist3 ):- !.
filter_which_are_not_in_list( [], _Varslist, [] , [] ):- !.
filter_which_are_not_in_list( [ Varx | Vars_str_list ], Varslist, [ Varx | Varslist2 ] , Varslist3 ):-
 is_not_member( Varx, Varslist ), !,
filter_which_are_not_in_list(  Vars_str_list , Varslist,  Varslist2  , Varslist3 ).
% TODO has probably to be reversed somewhere 
filter_which_are_not_in_list( [ Varx | Vars_str_list ], Varslist, Varslist2 , [ Varx | Varslist3 ]):-
filter_which_are_not_in_list(  Vars_str_list , Varslist,  Varslist2  , Varslist3 ).


add_when_not_in_list( [], Varslist , Varslist2 ):- reverse_slist( Varslist , [], Varslist2 ), !.
add_when_not_in_list( [ Varx | Vars_str_list ], Varslist , Varslist2 ):-
 is_not_member( Varx, Varslist ), !,
add_when_not_in_list(  Vars_str_list , [ Varx | Varslist ] , Varslist2 ).
% TODO has probably to be reversed somewhere 
add_when_not_in_list( [ _Varx | Vars_str_list ], Varslist , Varslist2 ):-
add_when_not_in_list(  Vars_str_list , Varslist  , Varslist2 ).



print_transpiled2( [] , _ ):- !.

print_transpiled2( [ transpiled( Cou, Tx )  ] , Tag ):- !, str_int( Cs, Cou ), write( "transpiled( ", Cs, "," , Tx , " )  ", Tag  ).
print_transpiled2( [ transpiled( Cou, Tx ) | Rs ] , Tag ):-  !,
 str_int( Cs, Cou ), write( "transpiled( ", Cs, "," , Tx , " ) , ", Tag  ), print_transpiled2( Rs , Tag ).
 
print_transpiled2( [ _ | Rs ] , Tag ):-  print_transpiled2( Rs , Tag ). 

%----
print_transpiled( par_atom_list( Op, Lis  ) ):-
  transp_operat( Op , Op_s ),
  write( "par_atom_list(   ", Op_s , ", \n " ),
  print_transpiled2( Lis , "\n" ),
  write( " )   \n" ).

%---

string_replace_tag( A, Rmvtag, Rep, Ares ):-  searchstring( A , Rmvtag ,  P),  P2 = P - 1,
  str_len( Rmvtag, Le ), Le > 0, frontstr( P2, A, Sta, Rest ),
  frontstr( Le, REst, _, Rest2 ), !,	concat( Sta, Rep, Z1), concat ( Z1, Rest2, Aq ),
  string_replace_tag( Aq, Rmvtag, Rep, Ares ).
string_replace_tag( A, _Rmvtag, _, A ):-!.


% turn off 
change_adhoc( Res , Res ):- !.
change_adhoc( Res4 , Res7 ):-
   string_replace_tag( Res4, ",\"", ",", Res5 ), 
   string_replace_tag( Res5, "\"),\n", "),\n", Res6 ), 
   string_replace_tag( Res6, "\")])", ")])", Res7 ), !.

% transpilex(22,"conditional( transx(- 6 , [numf(4),numf(5)] -) , transx(- 21 , [numf(8),variabel(\"$Cs\"),numf(20)] -) , 0 ) ")])
% after 

assert_var( Sx ):- var_concerned( Sx ), !.
assert_var( Sx ):- assert( var_concerned( Sx ) ) , !.

assert_vars( [] ):- !.
assert_vars( [ variabel( Sx ) | Rs ] ):- !, assert_var( Sx ), assert_vars( Rs ).
assert_vars( [ _ | Rs ] ):- !,  assert_vars( Rs ).

% assert_vars( Numsf_vars )

%---
assert_variabels_concerned( Nx ):-  
 is_transp( is_debug , Nx , _Operat , Subnums , Numsf_vars, _ ), !,  
    assert_variabels_concerned_list( Subnums ),
   assert_vars( Numsf_vars ).
   
   
%assert_variabels_concerned( Nx ):-
%  is_transp( is_debug , Nx , Operat , Nums_sub , _Numsf_vars, _ ), !,  assert_variabels_concerned_list( Nums_sub ).
%assert_variabels_concerned( Nx ):- !.

assert_variabels_concerned_list( [] ):- !.
assert_variabels_concerned_list( [ Num | Nums_sub ] ):- !, assert_variabels_concerned( Num ),
 assert_variabels_concerned_list( Nums_sub ).
 

% rebuild_constructed_of_clauses_to_memory( Nx ), 
% is_transp( is_debug , Nx , Operat , Nums_sub , Numsf_vars ), 
%   rebuild_constructed_of_clauses_to_memory( Nx ), 
% term_str( slist , Vars_str_list , Sx ),
% concat( Hs, " ", Hs2 ), concat( Hs2, Sx, Hs3 ),  concat( Hs3, " , ", Hs4 ),
% format( Qw , " varx( % ) " , Var_str ) , concat( Hs, Qw, Hs2 ), rebuild_transpiled_sub2( Rs , Hs2, C6 ).

%rebuild_constructed_of_clauses_to_memory( [] ):- !.
%rebuild_constructedof_clauses_to_memory(  Numf ):-
%  is_transp( is_debug , Numf , _Operat , Numsf_sub , Numsf_vars ), 
  
%  rebuild_constructed_of_clauses_to_memory(  Rs  ). 
%rebuild_constructed_of_clauses_to_memory( [ _ | Rs ] ):-  rebuild_constructed_of_clauses_to_memory(  Rs  ). 
   
   % !,  assert_vars( Numsf_vars ). 

% Rest recursive also here 

%---   
rebuild_transpiled_sub2_vars_str( [] , Res, Res ):-!.
rebuild_transpiled_sub2_vars_str( [ numf( Nx ) | Rs ] , Varslist , C6 ):- !,
   assert_variabels_concerned( Nx ),    findall( Varx, var_concerned( Varx ), Vars_str_list ),
   add_when_not_in_list( Vars_str_list, Varslist , Varslist2 ), 
   rebuild_transpiled_sub2_vars_str( Rs , Varslist2 , C6 ).
rebuild_transpiled_sub2_vars_str( [ variabel( Var_str ) | Rs ], Varslist, C6 ):- !,
   add_when_not_in_list( [ Var_str ], Varslist , Varslist2 ), 
   rebuild_transpiled_sub2_vars_str( Rs , Varslist2 , C6 ).
% for safety
rebuild_transpiled_sub2_vars_str( [ _ | Rs ], Varslist , C6 ):- !,  rebuild_transpiled_sub2_vars_str( Rs , Varslist , C6 ). 
 
%--
%which_list_for_second( _, Varsn_lis2, _Varsn_lis_todo, Varsn_lis2 ):- !.

which_list_for_second( 0, Varsn_lis2, _Varsn_lis_todo, Varsn_lis2 ):- !.
which_list_for_second( _Count_replace, _Varsn_lis2, Varsn_lis_todo, Varsn_lis_todo ):-!.
 

clean_var_list( [], [] ):- !. 
clean_var_list( [H|Ter], [S3|Ter2] ):-
  upper_lower( S2, H ) , string_replace_tag( S2, "$", "", S3 ),
  clean_var_list( Ter,  Ter2 ).


temp_clean_str_var_lis( Headvars_str0, C7 ):-
  str_after( "[" , Headvars_str0, Bg0 , After2 ),
  str_after( "]" , After2, Bg , After3 ),
%   write( "succee0 " , Bg),
  concat( "[" , Bg, C1 ), concat( C1, "]" , C2 ), 
  trap( term_str( slist, Ter, C2 ), _, fail ), 
 %  write( "succee " , C2),
  clean_var_list( Ter, Ter2 ),
  term_str( slist, Ter2, C3 ), 
  string_replace_tag( C3, "[", "", C31 ), string_replace_tag( C31, "]", "", C32 ),
  string_replace_tag( C32, "\"", " ", C33 ),
  %str_after( "[" , C3, _ , C3 ),
  %str_after( "]" , After2, Bg , After3 ),
  
  !,
  %write( "succee3 " , C3),
  concat( Bg0, C33, C5 ), concat( C5, After3, C6 ),
  %write( "succee6 " , C6 ),
  temp_clean_str_var_lis( C6, C7 ).
  
temp_clean_str_var_lis( Headvars_str, Headvars_str ):-!.
 
%---

rebuild_transpiled_sub( Count_replace, Transp_list_str, Varsn_lis, C6, Varsn_lis2 ):-
  str_after( "," , Transp_list_str, _Num_funct_str , After1 ),
  str_after( "[" , After1, _ , After2 ),
  str_after( "]" , After2, Bg , After3 ),
  concat( "[" , Bg, C1 ), concat( C1, "]" , C2 ), 
  trap( term_str( ATOM_LIST, Ter, C2 ), _, fail ), !,
  % retractall( var_concerned( _ ) ), 
  rebuild_transpiled_sub2_vars_str( Ter, [], C6_vars_str_lis ),
  % rebuild_constructedof_clauses_to_memory( Ter ), 
  % OPTIONAL  MERGE varnames doubt is questionable 
    add_when_not_in_list( C6_vars_str_lis, Varsn_lis , Varsn_lis2 ),
    
	filter_which_are_not_in_list( C6_vars_str_lis, Varsn_lis , Varsn_lis_todo, _ ),
	which_list_for_second( Count_replace, Varsn_lis2, Varsn_lis_todo, Varsn_lis3 ),
%	term_str( slist , Varsn_lis_todo , C6 ),
 	term_str( slist , Varsn_lis3 , C6 ),
 % HERE  bezig 
  %term_str( ATOM_LIST, Ter, Ter_s ),
  %concat( "-q" , Ter_s, C5 ), concat( C5, "q-" , C6 ), 
  !.
rebuild_transpiled_sub( _, Transp_list_str, _, Transp_list_str , [] ):-!.

rebuild_transpiled_string( Count_replace, Tra_str , Varsnames_l , Tra_str2, Varsnames_resl ):-
% str_after( Varstr, Big_str, Before, 	Rest ):-
  str_after( "transx(-", Tra_str, Before, After ),
   str_after( "-)", After, Transp_list_str, After2 ), !,
    rebuild_transpiled_sub( Count_replace, Transp_list_str, Varsnames_l, Transp_list_str2, Vars_names_list ),
   concat( Before, Transp_list_str2, C1 ), concat( C1, After2, C2 ),
   Count_replace2 = Count_replace + 1,
  rebuild_transpiled_string( Count_replace2, C2 , Vars_names_list, Tra_str2 , Varsnames_resl  ).
rebuild_transpiled_string( _Count_replace, Resu , Varsnames_l, Resu , Varsnames_l ):- !.


%---
% rebuild_transpiled_string(
rebuild_transpiled_strings( [], _, [] ):- !.
rebuild_transpiled_strings( [ transpiled( Nx , Tra_str ) | Rest ] , Varsn_lis, [ transpiled( Nx , Tra_str2 ) | T_rebuild ] ):- !,
   % retractall( to_be_subconstructed( Nx ) ),
   assert( to_be_subconstructed( Nx ) ),
     % retractall( var_concerned( _ ) ), 
   rebuild_transpiled_string( 0, Tra_str  ,  [], Tra_str2, _Varsn_lis2  ),
   % turned of not vars share amongst them 
  rebuild_transpiled_strings(  Rest  ,  Varsn_lis, T_rebuild   ).


 
rebuild_transpiled_strings( [ variabel( Va ) | Rest ] , Varsn_lis, [ variabel( Va ) | T_rebuild ] ):- !,
      assert_vars( [variabel( Va ) ] ),
	 rebuild_transpiled_strings(  Rest  ,  Varsn_lis, T_rebuild   ).
 
 

rebuild_transpiled_strings( [ H | Rest ] , Varsn_lis, [ H | T_rebuild ] ):- !,
     rebuild_transpiled_strings(  Rest  ,  Varsn_lis, T_rebuild   ).

%--
write_body_subs( _Nx , [] ):- write( "" ), !.
% write_body_subs( Nx , [ transpiled( Nx_sub, Sub ), transpiled( _, _ ) ] ):- !,  update_head_subs( Nx, Nx_sub, Sub ),  write( " ", Sub , "", "" ).
write_body_subs( Nx , [ number( V ) ] ):-  term_str( ATOM, number(V), Sx ), !,   write( " ", Sx , "", "" ).
write_body_subs( Nx , [ transpiled( Nx_sub, Sub0 ) ] ):- !,  
 temp_clean_str_var_lis( Sub0, Sub ),
 update_head_subs( Nx, Nx_sub, Sub ),  write( " ", Sub , "", "" ).
write_body_subs( Nx , [ _ ] ):- !,   write( "" ). 

write_body_subs( Nx , [ transpiled( Nx_sub, Sub0 ) | Subs ] ):- !,  temp_clean_str_var_lis( Sub0, Sub ),
  update_head_subs( Nx, Nx_sub, Sub ),  write( " ", Sub , ",", "\n" ),  write_body_subs( Nx , Subs  ).
write_body_subs( Nx , [ _ | Subs ] ):- !, write_body_subs( Nx , Subs  ).

%---
try_get_head_vars2( Nx, [Nx|Nlis], [Sz | Slis], Sz ):- !.
try_get_head_vars2( Nx, [_|Nlis], [_ | Slis], Sz ):- !, try_get_head_vars2( Nx, Nlis, Slis, Sz ).
 

%---
try_get_head_vars( Nx0, _, Headvars_str ):-
 head_subs(_, Nlis, Slis), try_get_head_vars2( Nx0, Nlis, Slis, Headvars_str ), !.
try_get_head_vars( _Nx0, Sq, Sq ):- !.
 
%head_subs(1,[22],["conditional( [\"$ABs\",\"$Bs\",\"$As\",\"$Cs\",\"$BCs\"] , [] , 0 ) "])
%head_subs(22,[21,6],["conditional( [\"$Bs\"] , CS , [\"$BCs\",\"$ABs\",\"$Cs\"] ) ","conjuction( [\"$Bs\",\"$As\",\"$ABs\"] , [\"$Cs\",\"$BCs\"] ) "])

%---

write_head_body2( Nx0, Operat, Subs  ):- 
 term_str( OPERATOR, Operat, Sq ),
 try_get_head_vars( Nx0, Sq, Headvars_str0 ), 
 temp_clean_str_var_lis( Headvars_str0, Headvars_str ),
 assert( head_subs( Nx0 , [] , []  ) ),
 str_int( Sx , 0 ), 
 str_int( Sx0 , Nx0 ),
 write( "\n% " , Sx0, " ", Sx, ".\n" ), 
 write( Headvars_str, ":-", "\n" ), 
 write_body_subs( Nx0 , Subs ), write(".").


%---
write_head_body( Nx0, [ transpiled( Nx, Head ) | Subs ] ):-
 assert( head_subs( Nx , [] , [] ) ),
 str_int( Sx , Nx ), str_int( Sx0 , Nx0 ),
 write( "% " , Sx0, " ", Sx, ".\n" ), 
 write( Head , ":-", "\n" ), 
 write_body_subs( Nx , Subs ), write(".").

%---

display_results():- display_results2(), fail, !.


display_results():- 
 openwrite( fileselector1, "transpiled.pro"),
 writedevice(fileselector1),
 display_results2(), !,
% write_slist_to_lines( L ), 
 closefile( fileselector1 ),
 writedevice( stdout ),
 write("written to : ", "transpiled.pro", "\n").

display_results():- !.

%---
display_results2():-
  lasts( Res3 ) ,
  write( "% METTA CLAUSE \n" ), 
  write(  Res3, "\n" ), fail, !. 

% string_replace_tag( Res2, "transx", "\ntransz", Res30 ),
% string_replace_tag( Res3, "\\\"", "\"", Res4 ),
% Termx = par_atom_list( OPERATOR , Atom_List ),

   
display_results2():- 
   term_parsed( Count, Termx ) , 
   % str_int( Sx, Count ),    write( Sx, ". \n" ), 
   retractall( tel( _ ) ), assert( tel( 0 ) ),
   retractall( is_transp( _ ,_ ,_ ,_ ,_ ,_ ) ),
   retractall( is_trpile( _ ,_ ,_ ,_ ,_ ,_ ) ),
   retractall( transpile_start( _ ) ),
   retractall( to_be_subconstructed( _ ) ),
   transpile_metta( is_debug , Termx, Termx2 ), 
   term_str( EXPR , Termx2 , S_res2 ),      write( S_res2, "\n" ),
   write( "% METTA TRANSPILED LEVEL 0\n" ), 
   Termx2 = par_atom_list( Operat , Ato_list ),
   
   retractall( var_concerned( _ ) ), 
   rebuild_transpiled_strings( Ato_list, [], T_rebuild ),
   term_str( EXPR , par_atom_list( Operat , T_rebuild ), S_rebuild2 ), 
   write( "transpile_start( ", S_rebuild2 , " )\n" ),
   assert( transpile_start( par_atom_list( Operat , T_rebuild ) ) ),
%      string_replace_tag( Res2, "transpiled", "\ntranspilex", Res31 ),
%      string_replace_tag( Res31, "##", "\n", Res3 ),
%      change_adhoc( Res3 , Res7 ),
%      write( Res7, "\n" ),    
   
   fail ,  !.    

display_results2():- 
  retract( to_be_subconstructed( Nx ) )  , 
  % format( Qw, " % ", Nx ), write( "% ", Qw , "\n" ),
  is_transp( is_debug, Nx, Operat, Transp_sublis, _Ato_List2, Ato_List3 ), 
  retractall( var_concerned( _ ) ), 
  rebuild_transpiled_strings( Ato_List3, [], T_rebuild3 ),
  
  assert( is_trpile( is_debug, Nx, Operat, Transp_sublis, _Ato_List2, T_rebuild3 ) ), 
  % term_str( ATOM_LIST , T_rebuild3 , S_rebuild3 ),      write( S_rebuild3 , "\n" ),
  fail , !.


%display_results2():- 
%   write( "% METTA TRANSPILED LEVEL 2\n" ), 
%   term_parsed( Count, Termx ) , 
%   retractall( tel( _ ) ), assert( tel( 0 ) ),
%   transpile_metta( is_perform , Termx, Termx2 ), 
%   term_str( EXPR , Termx2 , Res2 ),   
%   string_replace_tag( Res2, "transpiled", "\ntranspilex", Res30 ),
%   string_replace_tag( Res30, "##", "\n", Res3 ),
%   string_replace_tag( Res3, "\\\"", "\"", Res4 ),
%   change_adhoc( Res4 , Res7 ),
%   write( Res7, "\n" ),    fail,   !.    
display_results2():- 
   write( "% METTA PROLOG CLAUSES\n\n" ),   
   retractall( head_subs( _, _ , _ ) ),
   transpile_start( Ter ), Ter = par_atom_list( _Operat0 , T_rebuild ),
   write_head_body( 0, T_rebuild ),
   % write( "succ1\n" ), 
   is_trpile( is_debug, Nx, Operat, Transp_sublis, _Ato_List2, T_rebuild3 ), 
   Transp_sublis = [ _H | _Res ],
   write_head_body2( Nx, Operat, T_rebuild3 ),
   % write_head_body( Nx, T_rebuild3 ),
   fail , ! .


display_results2():- 
   write( "% METTA HEADSUB\n\n" ),   
    head_subs( A, B , C  ),
   term_str( db_head_subs, head_subs( A, B , C  ), Sx ), write( Sx, "\n" ), 
   fail , ! .
	  
	  
% write( "% METTA TRANSPILED LEVEL 1\n" ),   


display_results2():- 
   write( "% INTERNAL TRANSPILED INFO 1 \n" ), 
   is_trpile( is_debug, Cou2, Operat, Transp_lis, Atom_List2, Atom_List3 ), 
   % str_int( Sx, Cou2 ),   write( Cou2 , " " ),
   %print_transpiled2( Atom_List2 , "" ), 
   % write( "\n" ),
   term_str( db_is_trpile, is_trpile( is_debug, Cou2, Operat, Transp_lis, Atom_List2, Atom_List3 ), Sx ),
   string_replace_tag( Sx, "\\\"", "\"", Sx2 ),
   write( Sx2, "\n" ),
   fail, !.


display_results2():- 
   write( "% INTERNAL PARSE INFO 2 \n" ), 
   is_transp( is_debug, Cou2, Operat, Transp_lis, Atom_List2, Atom_List3 ), 
   % str_int( Sx, Cou2 ),   write( Cou2 , " " ),
   %print_transpiled2( Atom_List2 , "" ), 
   % write( "\n" ),
   term_str( db_is_transp, is_transp( is_debug, Cou2, Operat, Transp_lis, Atom_List2, Atom_List3 ), Sx ),
   string_replace_tag( Sx, "\\\"", "\"", Sx2 ),
   write( Sx2, "\n" ),
   fail, !.

display_results2():-
  write( "% METTA PARSE TREE \n" ), 
  term_parsed( Count, Termx ) , str_int( Sx, Count ), 
  term_str( EXPR , Termx , Res2 ),   
  string_replace_tag( Res2, "metta_sub", "\nmetta_sx", Res3 ),
  % string_replace_tag( Res2, "metta_sub", "\nmetta_sx", Res3 ),
  % write( Sx, ". " ), 
  write(  Res3, "\n" ), 
  fail, !.

%display_results():- 
%   term_parsed( Count, Termx ) , str_int( Sx, Count ), 
%   Termx = exclama_atom_list( OPERATOR , Atom_List ),
%   write( Sx, ". \n" ), 
%   transpile_metta_to_prolog( OPERATOR, Atom_List, "", Transpiled_text ),
%   write( Transpiled_text  ), 
%   !.    

  
display_results2():- !.    