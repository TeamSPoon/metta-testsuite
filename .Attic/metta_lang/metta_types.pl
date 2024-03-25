typed_list(Cmpd,Type,List):-  compound(Cmpd), Cmpd\=[_|_], compound_name_arguments(Cmpd,Type,[List|_]),is_list(List).
is_syspred(H,Len,Pred):- notrace(is_syspred0(H,Len,Pred)).
is_syspred0(H,_Ln,_Prd):- \+ atom(H),!,fail.
is_syspred0(H,_Ln,_Prd):- upcase_atom(H,U),downcase_atom(H,U),!,fail.
is_syspred0(H,Len,Pred):- current_predicate(H/Len),!,Pred=H.
is_syspred0(H,Len,Pred):- atom_concat(Mid,'!',H), H\==Mid, is_syspred0(Mid,Len,Pred),!.
is_syspred0(H,Len,Pred):- atom_concat(Mid,'-p',H), H\==Mid, is_syspred0(Mid,Len,Pred),!.
is_syspred0(H,Len,Pred):- atom_concat(Mid,'-fn',H), H\==Mid, is_syspred0(Mid,Len,Pred),!.
is_syspred0(H,Len,Pred):- into_underscores(H,Mid), H\==Mid, is_syspred0(Mid,Len,Pred),!.
%is_function(F):- atom(F).
is_metta_data_functor(_Eq,_Othr,H):- trace, clause(is_data_functor(H),_).
is_metta_data_functor(Eq,Other,H):- H\=='Right', H\=='Something',
 % metta_type(Other,H,_), % fail,
  \+ get_metta_atom(Eq,Other,[H|_]),
  \+ metta_defn(Eq,Other,[H|_],_),
  \+ is_metta_builtin(H),
  \+ is_comp_op(H,_),
  \+ is_math_op(H,_,_).


:- if( \+ current_predicate(mnotrace/1) ).
 mnotrace(G):- once(G).
:- endif.

'Number':attr_unify_hook(_,NewValue):- numeric(NewValue).

%is_decl_type(ST):- metta_type(_,_,[_|Type]),is_list(Type),sub_sterm(T,Type),nonvar(T),T=@=ST, \+ nontype(ST).
is_decl_type([ST|_]):- !, atom(ST),is_decl_type_l(ST).
is_decl_type(ST):- \+ atom(ST),!,fail.
is_decl_type('%Undefined%').  is_decl_type('Number').
is_decl_type('String').       is_decl_type('Bool').
is_decl_type('Type').         is_decl_type('Symbol').
is_decl_type('Expression').
is_decl_type('Any').          is_decl_type('Atom').
is_decl_type(Type):-          is_decl_type_l(Type).
is_decl_type_l('StateMonad'). is_decl_type_l('List').


last_type(List,Type):- is_list(List),last(List,Type),is_type(Type).
last_type(Type,Type):- is_type(Type),!.

is_type(Type):- nontype(Type),!,fail.
is_type(Type):- is_decl_type(Type).
is_type(Type):- atom(Type).

nontype(Type):- var(Type),!.
nontype('->').
nontype(N):- number(N).

needs_eval(EvalMe):- is_list(EvalMe),!.


args_violation(_Dpth,_Slf,Args,List):- ( \+ iz_conz(Args); \+ iz_conz(List)), !, fail.
args_violation(Depth,Self,[A|Args],[L|List]):- once(arg_violation(Depth,Self,A,L) ; args_violation(Depth,Self,Args,List)).
arg_violation(Depth,Self,A,L):- fail, 
   \+ (get_type0(Depth,Self,A,T), \+ type_violation(T,L)).
%arg_violation(Depth,Self,A,_):- get_type(Depth,Self,A,_),!.

type_violation(T,L):- \+ \+ (is_nonspecific_type(T);is_nonspecific_type(L)),!,fail.
type_violation(T,L):- T\=L.


not_arg_violation(Depth,Self,Arg,Type):-
   \+ arg_violation(Depth,Self,Arg,Type),
   arg_conform(Depth,Self,Arg,Type).


args_conform(_Dpth,_Slf,Args,List):- ( \+ iz_conz(Args); \+ iz_conz(List)), !.
args_conform(Depth,Self,[A|Args],[L|List]):- arg_conform(Depth,Self,A,L) , args_conform(Depth,Self,Args,List).
arg_conform(Depth,Self,A,L):- get_type(Depth,Self,A,T), type_conform(T,L),!.
arg_conform(_Dpth,_Slf,_,_).
%arg_conform(Depth,Self,A,_):- get_type(Depth,Self,A,_),!.

type_conform(T,L):- T=L,!.
type_conform(T,L):- \+ \+ (is_nonspecific_type(T);is_nonspecific_type(L)),!.

is_nonspecific_type(Var):- var(Var),!.
is_nonspecific_type('%Undefined%').
is_nonspecific_type([]).
is_nonspecific_type('Atom').
is_nonspecific_type('Any').

%get_type(Depth,Self,Val,Type):- get_type01(Depth,Self,Val,Type).
get_type(Depth,Self,Var,TypeO):- var(Var),var(TypeO),!.
get_type(Depth,Self,Val,TypeO):- no_repeats(TypeT,
  (get_type9(Depth,Self,Val,Type),TypeT=Type)),
  Type=TypeO.

get_type9(_Dpth,_Slf,Expr,'hyperon::space::DynSpace'):- is_dynaspace(Expr),!.
get_type9(Depth,Self,Val,Type):- \+ integer(Depth),!,get_type9(10,Self,Val,Type).
get_type9(Depth,Self,Val,Type):- get_type0(Depth,Self,Val,Type).
get_type9(Depth,Self,Val,Type):- get_type1(Depth,Self,Val,Type), ground(Type),Type\==[], Type\==Val,!.
%get_type9(_Depth,_Self,Val,Type):- symbol(Val),atom_contains(Val,' '),!,Type='String'.
get_type9(Depth,Self,Val,Type):- get_type2(Depth,Self,Val,Type), ( is_list(Type)->! ; true).
get_type9(_Dpth,_Slf,_Vl,[]).

get_type2(Depth,_Slf,Type,Type):- Depth<1,!.
%get_type(Depth,Self,Val,Type):- is_debugging(eval), !,
% ftrace(get_type0(Depth,Self,Val,Type)).
get_type2(Depth,Self,Val,Type):- get_type0(Depth,Self,Val,Type).
get_type2(Depth,Self,Val,Type):- get_type1(Depth,Self,Val,Type).


is_space_type(Space,is_asserted_space):- was_asserted_space(Space),!.
is_space_type(Space,Test):- no_repeats(Test,space_type_method(Test,_,_)),call(Test,Space),!.

is_state_type(State,Test):- no_repeats(Test,state_type_method(Test,_,_)),call(Test,State),!.

%is_dynaspace(Expr):- \+ is_list(Expr), callable(Expr), is_space_type(Expr,_).
is_dynaspace(S):- var(S),!,fail.
is_dynaspace(S):- was_asserted_space(S).
is_dynaspace(S):- py_named_space(S).
is_dynaspace(S):- typed_list(S,'hyperon::space::DynSpace',_).
%  notrace( is_space_type(Expr,_)),!.
get_type0(_Dpth,_Slf,Expr,'hyperon::space::DynSpace'):- is_dynaspace(Expr),!.
get_type0(Depth,Self,Expr,['StateMonad',Type]):-  notrace( is_valid_nb_state(Expr)),!, 'get-state'(Expr,Val),!,
  ((state_decltype(Expr,Type),nonvar(Type)); (Depth2 is Depth-1, get_type(Depth2,Self,Val,Type))).
get_type0(Depth,Self,Val,Type):- \+ compound(Val),!,get_type01(Depth,Self,Val,Type),!.
get_type0(Depth,Self,Val,Type):- get_type03(Depth,Self,Val,Type),!.

get_type01(_Dpth,_Slf,Var,'%Undefined%'):- var(Var),!.
get_type01(_Dpth,_Slf, [],'%Undefined%'):- !.
get_type01(_Dpth,Self,Op,Type):- metta_type(Self,Op,Type),!.
get_type01(_Dpth,_Slf,Val,'Number'):- number(Val).
get_type01(_Dpth,_Slf,Val,'Integer'):- integer(Val).
get_type01(_Dpth,_Slf,Val,'Decimal'):- float(Val).
get_type01(_Dpth,_Slf,Val,'Rational'):- rational(Val).
get_type01(_Dpth,_Slf,Val,'Bool'):- (Val=='False';Val=='True'),!.
%get_type01(_Dpth,_Slf,Val,Type):- string(Val),!,(Type='String';Type='Symbol').
get_type01(Depth,Self,Op,Type):- Depth2 is Depth-1, eval_args(Depth2,Self,Op,Val),Op\=@=Val,!, get_type(Depth2,Self,Val,Type).
get_type01(_Dpth,_Slf,Expr,_):-  \+ atom(Expr),!,fail.
get_type01(_Dpth,_Slf,Val,Type):- is_decl_type(Val),(Type=Val;Type='Type').
get_type01(_Dpth,_Slf,Val,Type):- symbolic_list_concat([Type,_|_],'@',Val).
get_type01(_Dpth,_Slf,Val,Type):- symbolic_list_concat([Type,_|_],':',Val).
get_type01(_Dpth,_Slf,_,'%Undefined%'):- !. %report undefined symbols as such 
%get_type01(_Dpth,_Slf,Expr,'hyperon::space::DynSpace'):- \+ is_list(Expr), callable(Expr), is_space_type(Expr,_).
%get_type01(_Dpth,_Slf,_Val,'String').
%get_type01(_Dpth,_Slf,_Val,'Symbol').



get_type02(_Dpth,Self,Expr,Type):- metta_type(Self,TExpr,Type), TExpr == Expr.
get_type02(_Dpth,Self,Expr,Type):- metta_type(Self,TExpr,Type), TExpr =@= Expr.
get_type02(Depth,Self,[Op|Expr],Type):- maplist(get_type(Depth,Self),Expr,Types),
  metta_type(Self,[Op|Types],Type).


get_type03(Depth,Self,[[Op|Args]|Arg],Type):- symbol(Op),
 get_type03(Depth,Self,[Op|Args],Type1),
 get_type(Depth,Self,Arg,ArgType),
 ignore(sub_var(ArgType,Type1)->true;(sub_term(ST,Type1),var(ST),ST=ArgType)),
 last(Type1,Type).

get_type03(_Dpth,_Slf,Cmpd,Type):-typed_list(Cmpd,Type,_List).
get_type03(Depth,Self,[Op|Args],Type):- symbol(Op),
  get_operator_typedef(Self,Op,Params,RetType),
  % Fills in type variables when possible
  ignore(args_conform(Depth,Self,Args,Params)),
  % unitests:  arg violations should return ()
  (\+ args_violation(Depth,Self,Args,Params) -> Type=RetType ; (Type=[],!)).


get_type03(Depth,Self,Expr,Type):- get_type02(Depth,Self,Expr,Type).

get_type03(Depth,Self,EvalMe,Type):- needs_eval(EvalMe),Depth2 is Depth-1,
   eval_args(Depth2,Self,EvalMe,Val),
   \+ needs_eval(Val),!,
   get_type(Depth2,Self,Val,Type).

get_type03(Depth,Self,Expr,Type):-  Depth2 is Depth-1,
  eval_args(Depth2, Self,Expr,Val), Expr\=@=Val,!,
  get_type(Depth2,Self,Val,Type).

get_type03(_Dpth,_Slf,Val,Type):- is_decl_type(Val),(Type=Val;Type='Type').

get_type03(_Dpth,_Slf,Expr,'Expression'):- is_list(Expr),!.

get_type03(Depth,Self,List,Types):- List\==[], is_list(List),
  Depth2 is Depth-1,maplist(get_type(Depth2,Self),List,Types).


get_type03(_Dpth,_Slf,Cmpd,Type):- compound(Cmpd),!, \+ ground(Cmpd),!,Type=[].

%get_type0(_Dpth,Self,List,Type):- is_list(List),metta_type(Self,Type,['->'|List]).
%get_type(Depth,Self,Op,Type):- nonvar(Op),metta_type(Self,Op,Type2),Depth2 is Depth-1,get_type(Depth2,Self,Type2,Type).
%get_type(Depth,Self,Op,Type):- Depth>0,nonvar(Op),metta_type(Self,Type,Op),!. %,!,last_element(List,Type).
%get_type(Depth,Self,[T|List],['List',Type]):- Depth2 is Depth-1,  is_list(List),get_type(Depth2,Self,T,Type),!,
%  forall((member(Ele,List),nonvar(Ele)),get_type(Depth2,Self,Ele,Type)),!.
%get_type(Depth,_Slf,Cmpd,Type):- compound(Cmpd), functor(Cmpd,Type,1),!.
%get_type0(_Dpth,_Slf,_,'%Undefined%'):- fail.

state_decltype(Expr,Type):- functor(Expr,_,A),arg(A,Expr,Type),once(var(Type);is_decl_type(Type)).


get_type1(_Dpth,_Slf,Var,'%Undefined%'):- var(Var),!.
get_type1(_Dpth,_Slf,Val,'Number'):- number(Val),!.
get_type1(Depth,Self,Expr,['StateMonad',Type]):- is_valid_nb_state(Expr),'get-state'(Expr,Val),!,
   get_type1(Depth,Self,Val,Type).


get_type1(Depth,Self,EvalMe,Type):- needs_eval(EvalMe),
     eval_args(Depth,Self,EvalMe,Val), \+ needs_eval(Val),!,
   get_type1(Depth,Self,Val,Type).

get_type1(_Dpth,Self,[Fn|_],Type):- symbol(Fn),metta_type(Self,Fn,List),last_element(List,Type), nonvar(Type),
   is_type(Type).
get_type1(_Dpth,Self,List,Type):- is_list(List),metta_type(Self,List,LType),last_element(LType,Type), nonvar(Type),
   is_type(Type).

get_type1(Depth,_Slf,Type,Type):- Depth<1,!.
get_type1(_Dpth,Self,List,Type):- is_list(List),metta_type(Self,Type,['->'|List]).
get_type1(Depth,Self,List,Types):- List\==[], is_list(List),Depth2 is Depth-1,maplist(get_type1(Depth2,Self),List,Types).
get_type1(_Dpth,Self,Fn,Type):- symbol(Fn),metta_type(Self,Fn,Type),!.
%get_type1(Depth,Self,Fn,Type):- nonvar(Fn),metta_type(Self,Fn,Type2),Depth2 is Depth-1,get_type1(Depth2,Self,Type2,Type).
%get_type1(Depth,Self,Fn,Type):- Depth>0,nonvar(Fn),metta_type(Self,Type,Fn),!. %,!,last_element(List,Type).

get_type1(Depth,Self,Expr,Type):-Depth2 is Depth-1,
 eval_args(Depth2,Self,Expr,Val),
  Expr\=@=Val,get_type1(Depth2,Self,Val,Type).


get_type1(_Dpth,_Slf,Val,'String'):- string(Val),!.
get_type1(_Dpth,_Slf,Val,Type):- is_decl_type(Val),Type=Val.
get_type1(_Dpth,_Slf,Val,'Bool'):- (Val=='False';Val=='True'),!.
% get_type1(_Dpth,_Slf,Val,'Symbol'):- symbol(Val).
%get_type1(Depth,Self,[T|List],['List',Type]):- Depth2 is Depth-1,  is_list(List),get_type1(Depth2,Self,T,Type),!,
%  forall((member(Ele,List),nonvar(Ele)),get_type1(Depth2,Self,Ele,Type)),!.
%get_type1(Depth,_Slf,Cmpd,Type):- compound(Cmpd), functor(Cmpd,Type,1),!.
get_type1(_Dpth,_Slf,Cmpd,Type):- \+ ground(Cmpd),!,Type=[].
get_type1(_Dpth,_Slf,_,'%Undefined%'):- fail.
%get_type1(Depth,Self,Val,Type):- Depth2 is Depth-1, get_type0(Depth2,Self,Val,Type).



as_prolog(I,O):- as_prolog(10,'&self',I,O).
as_prolog(_Dpth,_Slf,I,O):- \+ iz_conz(I),!,I=O.
as_prolog(Depth,Self,[Cons,H,T],[HH|TT]):- Cons=='Cons',!,as_prolog(Depth,Self,H,HH),as_prolog(Depth,Self,T,TT).
as_prolog(Depth,Self,[List,H|T],O):- List=='::',!,maplist(as_prolog(Depth,Self),[H|T],L),!, O = L.
as_prolog(Depth,Self,[At,H|T],O):- At=='@',!,maplist(as_prolog(Depth,Self),[H|T],[HH|L]),atom(H),!, O =.. [HH|L].
as_prolog(Depth,Self,I,O):- is_list(I),!,maplist(as_prolog(Depth,Self),I,O).
as_prolog(_Dpth,_Slf,I,I).


try_adjust_arg_types(_Eq,RetType,Depth,Self,Params,X,Y):-
  as_prolog(Depth,Self,X,M),
  args_conform(Depth,Self,M,Params),!,
  set_type(Depth,Self,Y,RetType),
  into_typed_args(Depth,Self,Params,M,Y).
%adjust_args(Eq,RetType,Depth,Self,_,X,Y):- is_list(X), !, maplist(eval_args(Depth,Self),X,Y).
%adjust_args(Eq,RetType,Depth,Self,_,X,Y):- is_list(X), !, maplist(as_prolog(Depth,Self),X,Y),!.

adjust_args(_Eq,_RetType,_Dpth,Self,F,X,Y):- (X==[] ; is_special_op(Self,F); \+ iz_conz(X)),!,Y=X.
adjust_args(Eq,RetType,Depth,Self,Op,X,Y):-
    adjust_argsA(Eq,RetType,Depth,Self,Op,X,Y)*->true; adjust_argsB(Eq,RetType,Depth,Self,Op,X,Y).

adjust_argsA(Eq,RetType,Depth,Self,Op,X,Y):-
  %trace,
  get_operator_typedef(Self,Op,Params,RetType),
  try_adjust_arg_types(Eq,RetType,Depth,Self,Params,X,Y).
%adjust_args(_Eq,_RetType,Depth,Self,_,X,Y):- as_prolog(Depth,Self,X,Y).
adjust_argsB(_Eq,_RetType,_Depth,_Self,_,X,Y):- X = Y.

into_typed_args(_Dpth,_Slf,T,M,Y):- (\+ iz_conz(T); \+ iz_conz(M)),!, M=Y.
into_typed_args(Depth,Self,[T|TT],[M|MM],[Y|YY]):-
  into_typed_arg(Depth,Self,T,M,Y),
  into_typed_args(Depth,Self,TT,MM,YY).

into_typed_arg(_Dpth,Self,T,M,Y):- var(M),!,put_attr(M,metta_type,Self=T),put_attr(Y,metta_type,Self=T),Y=M.
into_typed_arg(Depth,Self,T,M,Y):- into_typed_arg0(Depth,Self,T,M,Y)*->true;M=Y.

into_typed_arg0(Depth,Self,T,M,Y):- var(T), !, 
  get_type(Depth,Self,M,T),
 (wants_eval_kind(T)->eval_args(Depth,Self,M,Y);Y=M).

into_typed_arg0(Depth,Self,T,M,Y):- is_pro_eval_kind(T),!,eval_args(Depth,Self,M,Y).
into_typed_arg0(Depth,Self,T,M,Y):- ground(M),!, \+ arg_violation(Depth,Self,M,T),Y=M.
into_typed_arg0(_Dpth,_Slf,T,M,Y):- is_non_eval_kind(T),!,M=Y.
into_typed_arg0(Depth,Self,_,M,Y):- eval_args(Depth,Self,M,Y).

set_type(Depth,Self,Var,Type):- nop(set_type(Depth,Self,Var,Type)),!.
set_type(Depth,Self,Var,Type):- get_type(Depth,Self,Var,Was)
   *->Was=Type
   ; if_t(var(Var),put_attr(Var,metta_type,Self=Type)).

metta_type:attr_unify_hook(Self=Type,NewValue):-
   get_type(20,Self,NewValue,Was),
   can_assign(Was,Type).

can_assign(Was,Type):- Was=Type,!.
can_assign(Was,Type):- (is_nonspecific_type(Was);is_nonspecific_type(Type)),!.
can_assign(_Ws,_Typ).

is_non_eval_kind(Type):- is_nonspecific_type(Type),!.
is_non_eval_kind('Atom').

is_pro_eval_kind('Number').
is_pro_eval_kind('Symbol').
is_pro_eval_kind('Bool').
is_pro_eval_kind([List|_]):- List=='List'.

is_feo_f('Cons').

is_seo_f('{...}').
is_seo_f('[...]').
is_seo_f('{}').
is_seo_f('[]').
is_seo_f('StateMonad').
is_seo_f('State').
is_seo_f('Event').
is_seo_f('Concept').
is_seo_f(N):- number(N),!.

%is_user_defined_goal(Self,[H|_]):- is_user_defined_head(Eq,Self,H).

is_user_defined_head(Other,H):- is_user_defined_head(=,Other,H).
is_user_defined_head(Eq,Other,H):- mnotrace(is_user_defined_head0(Eq,Other,H)).
is_user_defined_head0(Eq,Other,[H|_]):- !, nonvar(H),!, is_user_defined_head_f(Eq,Other,H).
is_user_defined_head0(Eq,Other,H):- callable(H),!,functor(H,F,_), is_user_defined_head_f(Eq,Other,F).
is_user_defined_head0(Eq,Other,H):- is_user_defined_head_f(Eq,Other,H).

is_user_defined_head_f(Other,H):- is_user_defined_head_f(=,Other,H).
is_user_defined_head_f(Eq,Other,H):- is_user_defined_head_f1(Eq,Other,H).
is_user_defined_head_f(Eq,Other,H):- is_user_defined_head_f1(Eq,Other,[H|_]).

%is_user_defined_head_f1(Eq,Other,H):- metta_type(Other,H,_).
%s_user_defined_head_f1(Other,H):- get_metta_atom(Eq,Other,[H|_]).
is_user_defined_head_f1(Other,H):- is_user_defined_head_f1(=,Other,H).
is_user_defined_head_f1(Eq,Other,H):- metta_defn(Eq,Other,[H|_],_).
%is_user_defined_head_f(Eq,_,H):- is_metta_builtin(H).



is_special_op(Op):-  current_self(Self),is_special_op(Self,Op).

is_special_op(_Slf,F):- \+ atom(F), \+ var(F), !, fail.
is_special_op(Self,Op):- get_operator_typedef(Self,Op,Params,_RetType),
   maplist(is_non_eval_kind,Params).
is_special_op(_Slf,Op):- is_special_builtin(Op).



get_operator_typedef(Self,Op,ParamTypes,RetType):-
  get_operator_typedef1(Self,Op,ParamTypes,RetType)*->true;
  get_operator_typedef2(Self,Op,ParamTypes,RetType).
get_operator_typedef1(Self,Op,ParamTypes,RetType):-
   metta_type(Self,Op,['->'|List]),
   append(ParamTypes,[RetType],List).
get_operator_typedef2(Self,Op,ParamTypes,RetType):-
  nop(wdmsg(missing(get_operator_typedef2(Self,Op,ParamTypes,RetType)))),!,fail.

is_metta_data_functor(Eq,F):-
  current_self(Self),is_metta_data_functor(Eq,Self,F).


is_special_builtin('case').
is_special_builtin(':').

%is_special_builtin('=').
is_special_builtin('->').
is_special_builtin('bind!').
%is_special_builtin('new-space').
is_special_builtin('let').
is_special_builtin('let*').
is_special_builtin('if').
is_special_builtin('rtrace').
is_special_builtin('or').
is_special_builtin('and').
is_special_builtin('not').
is_special_builtin('match').
is_special_builtin('call').
is_special_builtin('let').
is_special_builtin('let*').
is_special_builtin('nop').
is_special_builtin('assertEqual').
is_special_builtin('assertEqualToResult').
is_special_builtin('collapse').
is_special_builtin('superpose').
%is_special_builtin('==').

is_metta_builtin(Special):- is_special_builtin(Special).

is_metta_builtin('==').
is_metta_builtin(F):- once(atom(F);var(F)), current_op(_,yfx,F).
is_metta_builtin('println!').
is_metta_builtin('transfer!').
is_metta_builtin('compile!').
is_metta_builtin('+').
is_metta_builtin('-').
is_metta_builtin('*').
is_metta_builtin('/').
is_metta_builtin('%').
is_metta_builtin('==').
is_metta_builtin('<').
is_metta_builtin('>').
is_metta_builtin('all').
is_metta_builtin('import!').
is_metta_builtin('pragma!').

% Comparison Operators in Prolog
% is_comp_op('=', 2).          % Unification
is_comp_op('\\=', 2).        % Not unifiable
is_comp_op('==', 2).         % Strict equality
is_comp_op('\\==', 2).       % Strict inequality
is_comp_op('@<', 2).         % Term is before
is_comp_op('@=<', 2).        % Term is before or equal
is_comp_op('@>', 2).         % Term is after
is_comp_op('@>=', 2).        % Term is after or equal
is_comp_op('=<', 2).         % Less than or equal
is_comp_op('<', 2).          % Less than
is_comp_op('>=', 2).         % Greater than or equal
is_comp_op('>', 2).          % Greater than
is_comp_op('is', 2).         % Arithmetic equality
is_comp_op('=:=', 2).        % Arithmetic exact equality
is_comp_op('=\\=', 2).       % Arithmetic inequality

% Arithmetic Operations
is_math_op('*', 2, exists).         % Multiplication
is_math_op('**', 2, exists).        % Exponentiation
is_math_op('+', 1, exists).         % Unary Plus
is_math_op('+', 2, exists).         % Addition
is_math_op('-', 1, exists).         % Unary Minus
is_math_op('-', 2, exists).         % Subtraction
is_math_op('.', 2, exists).         % Array Indexing or Member Access (Depends on Context)
is_math_op('/', 2, exists).         % Division
is_math_op('//', 2, exists).        % Floor Division
is_math_op('///', 2, exists).       % Alternative Division Operator (Language Specific)
is_math_op('/\\', 2, exists).       % Bitwise AND
is_math_op('<<', 2, exists).        % Bitwise Left Shift
is_math_op('>>', 2, exists).        % Bitwise Right Shift
is_math_op('\\', 1, exists).        % Bitwise NOT
is_math_op('\\/', 2, exists).       % Bitwise OR
is_math_op('^', 2, exists).         % Bitwise XOR
is_math_op('abs', 1, exists).       % Absolute Value
is_math_op('acos', 1, exists).      % Arc Cosine
is_math_op('acosh', 1, exists).     % Hyperbolic Arc Cosine
is_math_op('asin', 1, exists).      % Arc Sine
is_math_op('asinh', 1, exists).     % Hyperbolic Arc Sine
is_math_op('atan', 1, exists).      % Arc Tangent
is_math_op('atan2', 2, exists).     % Two-Argument Arc Tangent
is_math_op('atanh', 1, exists).     % Hyperbolic Arc Tangent
is_math_op('cbrt', 1, exists).      % Cube Root
is_math_op('ceil', 1, exists).      % Ceiling Function
is_math_op('ceiling', 1, exists).   % Ceiling Value
is_math_op('cmpr', 2, exists).      % Compare Two Values (Language Specific)
is_math_op('copysign', 2, exists).  % Copy the Sign of a Number
is_math_op('cos', 1, exists).       % Cosine Function
is_math_op('cosh', 1, exists).      % Hyperbolic Cosine
is_math_op('cputime', 0, exists).   % CPU Time
is_math_op('degrees', 1, exists).   % Convert Radians to Degrees
is_math_op('denominator', 1, exists). % Get Denominator of Rational Number
is_math_op('div', 2, exists).       % Integer Division
is_math_op('e', 0, exists).         % Euler's Number
is_math_op('epsilon', 0, exists).   % Machine Epsilon
is_math_op('erf', 1, exists).       % Error Function
is_math_op('erfc', 1, exists).      % Complementary Error Function
is_math_op('eval', 1, exists).      % Evaluate Expression
is_math_op('exp', 1, exists).       % Exponential Function
is_math_op('expm1', 1, exists).     % exp(x) - 1
is_math_op('fabs', 1, exists).      % Absolute Value (Floating-Point)
is_math_op('float', 1, exists).     % Convert Rational to Float
is_math_op('float_fractional_part', 1, exists). % Fractional Part of Float
is_math_op('float_integer_part', 1, exists).    % Integer Part of Float
is_math_op('floor', 1, exists).     % Floor Value
is_math_op('fmod', 2, exists).      % Floating-Point Modulo Operation
is_math_op('frexp', 2, exists).     % Get Mantissa and Exponent
is_math_op('fsum', 1, exists).      % Accurate Floating Point Sum
is_math_op('gamma', 1, exists).     % Gamma Function
is_math_op('gcd', 2, exists).       % Greatest Common Divisor
is_math_op('getbit', 2, exists).    % Get Bit at Position
is_math_op('hypot', 2, exists).     % Euclidean Norm, Square Root of Sum of Squares
is_math_op('inf', 0, exists).       % Positive Infinity
is_math_op('integer', 1, exists).   % Convert Float to Integer
is_math_op('isinf', 1, exists).     % Check for Infinity
is_math_op('isnan', 1, exists).     % Check for Not a Number
is_math_op('lcm', 2, exists).       % Least Common Multiple
is_math_op('ldexp', 2, exists).     % Load Exponent of a Floating Point Number
is_math_op('lgamma', 1, exists).    % Log Gamma
is_math_op('log', 1, exists).       % Logarithm Base e
is_math_op('log10', 1, exists).     % Base 10 Logarithm
is_math_op('log1p', 1, exists).     % log(1 + x)
is_math_op('log2', 1, exists).      % Base 2 Logarithm
is_math_op('lsb', 1, exists).       % Least Significant Bit
is_math_op('max', 2, exists).       % Maximum of Two Values
is_math_op('maxr', 2, exists).      % Maximum Rational Number (Language Specific)
is_math_op('min', 2, exists).       % Minimum of Two Values
is_math_op('minr', 2, exists).      % Minimum Rational Number (Language Specific)
is_math_op('mod', 2, exists).       % Modulo Operation
is_math_op('modf', 2, exists).      % Return Fractional and Integer Parts
is_math_op('msb', 1, exists).       % Most Significant Bit
is_math_op('nan', 0, exists).       % Not a Number
is_math_op('nexttoward', 2, exists). % Next Representable Floating-Point Value
is_math_op('numerator', 1, exists). % Get Numerator of Rational Number
is_math_op('pi', 0, exists).        % Pi
is_math_op('popcount', 1, exists).  % Count of Set Bits
is_math_op('pow', 2, exists).       % Exponentiation
is_math_op('powm', 3, exists).      % Modulo Exponentiation
is_math_op('radians', 1, exists).   % Convert Degrees to Radians
is_math_op('remainder', 2, exists). % Floating-Point Remainder
is_math_op('remquo', 3, exists).    % Remainder and Part of Quotient
is_math_op('round', 1, exists).     % Round to Nearest Integer
is_math_op('roundeven', 1, exists). % Round to Nearest Even Integer
is_math_op('setbit', 2, exists).    % Set Bit at Position
is_math_op('signbit', 1, exists).   % Sign Bit of Number
is_math_op('sin', 1, exists).       % Sine Function
is_math_op('sinh', 1, exists).      % Hyperbolic Sine
is_math_op('sqrt', 1, exists).      % Square Root
is_math_op('tan', 1, exists).       % Tangent Function
is_math_op('tanh', 1, exists).      % Hyperbolic Tangent
is_math_op('testbit', 2, exists).   % Test Bit at Position
is_math_op('trunc', 1, exists).     % Truncate Decimal to Integer
is_math_op('ulogb', 1, exists).     % Unbiased Exponent of a Floating-Point Value
is_math_op('xor', 2, exists).       % Exclusive OR
is_math_op('zerop', 1, exists).     % Test for Zero

%:- load_pfc_file('metta_ontology.pl.pfc').


