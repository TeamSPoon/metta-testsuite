%
% post match modew
%:- style_check(-singleton).

self_eval0(X):- \+ callable(X),!.
self_eval0(X):- is_valid_nb_state(X),!.
%self_eval0(X):- string(X),!.
%self_eval0(X):- number(X),!.
%self_eval0([]).
self_eval0(X):- is_metta_declaration(X),!.
self_eval0(X):- is_list(X),!,fail.
self_eval0(X):- typed_list(X,_,_),!.
%self_eval0(X):- compound(X),!.
%self_eval0(X):- is_ref(X),!,fail.
self_eval0('True'). self_eval0('False'). % self_eval0('F').
self_eval0('Empty').
self_eval0(X):- atom(X),!, \+ nb_current(X,_),!.

self_eval(X):- notrace(self_eval0(X)).

:-  set_prolog_flag(access_level,system).
hyde(F/A):- functor(P,F,A), redefine_system_predicate(P),'$hide'(F/A), '$iso'(F/A).
:- 'hyde'(option_else/2).
:- 'hyde'(atom/1).
:- 'hyde'(quietly/1).
:- 'hyde'(notrace/1).
:- 'hyde'(var/1).
:- 'hyde'(is_list/1).
:- 'hyde'(copy_term/2).
:- 'hyde'(nonvar/1).
:- 'hyde'(quietly/1).
%:- 'hyde'(option_value/2).


is_metta_declaration([F|_]):- F == '->',!.
is_metta_declaration([F,_,_|T]):- T ==[], is_metta_declaration_f(F).

is_metta_declaration_f(F):- F == ':', !.
is_metta_declaration_f(F):- F == '=', !,
   \+ (current_self(Space), is_user_defined_head_f(Space,F)).

(F==':';
  (F=='=',  \+
   \+ (current_self(Space), is_user_defined_head_f(Space,F)))).
% is_metta_declaration([F|T]):- is_list(T), is_user_defined_head([F]),!.

:- nb_setval(self_space, '&self').
evals_to(XX,Y):- Y=@=XX,!.
evals_to(XX,Y):- Y=='True',!, is_True(XX),!.

current_self(Space):- nb_current(self_space,Space).

do_expander('=',_,X,X):-!.
do_expander(':',_,X,Y):- !, get_type(X,Y)*->X=Y.

'get_type'(Arg,Type):- 'get-type'(Arg,Type).




eval_args(X,Y):- current_self(Space), 
  rtrace_on_existence_error(eval(100,Space,X,Y)).
eval_args(Depth,Self,X,Y):- rtrace_on_existence_error(eval(Depth,Self,X,Y)).
eval_args(Expander,RetType,Depth,Self,X,Y):- 
     rtrace_on_existence_error(eval(Expander,RetType,Depth,Self,X,Y)).

%eval(Expander,RetType,Depth,_Self,X,_Y):- forall(between(6,Depth,_),write(' ')),writeqln(eval(Expander,RetType,X)),fail.
eval(Depth,Self,X,Y):- eval('=',_RetType,Depth,Self,X,Y).

%eval(Expander,RetType,_Dpth,_Slf,X,Y):- nonvar(Y),X=Y,!.

eval(Expander,RetType,Depth,Self,X,Y):- nonvar(Y),!,
   get_type(Depth,Self,Y,RetType), !,
   eval(Expander,RetType,Depth,Self,X,XX),evals_to(XX,Y).

eval(_Expander,_RetType,_Dpth,_Slf,X,Y):- var(X),!,Y=X.

eval(Expander,RetType,_Dpth,_Slf,[X|T],Y):- T==[], number(X),!, do_expander(Expander,RetType,X,YY),Y=[YY].

eval(Expander,RetType,Depth,Self,[F|X],Y):-
  (F=='superpose' ; ( option_value(no_repeats,false))),
  notrace((D1 is Depth-1)),!,
  eval_00(Expander,RetType,D1,Self,[F|X],Y).

eval(Expander,RetType,Depth,Self,X,Y):-
  notrace(allow_repeats_eval_(X)),
  !,
  eval_00(Expander,RetType,Depth,Self,X,Y).
eval(Expander,RetType,Depth,Self,X,Y):-
  notrace((no_repeats_var(YY),
  D1 is Depth-1)),
  eval_00(Expander,RetType,D1,Self,X,Y),
   notrace(( \+ (Y\=YY))).

allow_repeats_eval_(_):- !.
allow_repeats_eval_(_):- option_value(no_repeats,false),!.
allow_repeats_eval_(X):- \+ is_list(X),!,fail.
allow_repeats_eval_([F|_]):- atom(F),allow_repeats_eval_f(F).
allow_repeats_eval_f('superpose').
allow_repeats_eval_f('collapse').

debugging_metta(G):- notrace((is_debugging((eval))->ignore(G);true)).


:- nodebug(metta(eval)).


w_indent(Depth,Goal):-
  \+ \+ mnotrace(ignore(((
    format('~N'),
    setup_call_cleanup(forall(between(Depth,101,_),write('  ')),Goal, format('~N')))))).
indentq(Depth,Term):-
  \+ \+ mnotrace(ignore(((
    format('~N'),
    setup_call_cleanup(forall(between(Depth,101,_),write('  ')),format('~q',[Term]),
    format('~N')))))).


with_debug(Flag,Goal):- is_debugging(Flag),!, call(Goal).
with_debug(Flag,Goal):- flag(eval_num,_,0),
  setup_call_cleanup(set_debug(Flag,true),call(Goal),set_debug(Flag,false)).

flag_to_var(Flag,Var):- atom(Flag), \+ atom_concat('trace-on-',_,Flag),!,atom_concat('trace-on-',Flag,Var).
flag_to_var(metta(Flag),Var):- !, nonvar(Flag), flag_to_var(Flag,Var).
flag_to_var(Flag,Var):- Flag=Var.

set_debug(Flag,Val):- \+ atom(Flag), flag_to_var(Flag,Var), atom(Var),!,set_debug(Var,Val).
set_debug(Flag,true):- !, debug(metta(Flag)),flag_to_var(Flag,Var),set_option_value(Var,true).
set_debug(Flag,false):- nodebug(metta(Flag)),flag_to_var(Flag,Var),set_option_value(Var,false).
if_trace((Flag;true),Goal):- !, notrace(( catch(ignore((Goal)),E,wdmsg(E-->if_trace((Flag;true),Goal))))).
if_trace(Flag,Goal):- notrace((catch(ignore((is_debugging(Flag),Goal)),E,wdmsg(E-->if_trace(Flag,Goal))))).


%maybe_efbug(SS,G):- efbug(SS,G)*-> if_trace(eval,wdmsg(SS=G)) ; fail.
maybe_efbug(_,G):- call(G).
%efbug(P1,G):- call(P1,G).
efbug(_,G):- call(G).



is_debugging(Flag):- var(Flag),!,fail.
is_debugging((A;B)):- !, (is_debugging(A) ; is_debugging(B) ).
is_debugging((A,B)):- !, (is_debugging(A) , is_debugging(B) ).
is_debugging(not(Flag)):- !,  \+ is_debugging(Flag).
is_debugging(Flag):- Flag== false,!,fail.
is_debugging(Flag):- Flag== true,!.
is_debugging(Flag):- debugging(metta(Flag),TF),!,TF==true.
is_debugging(Flag):- debugging(Flag,TF),!,TF==true.
is_debugging(Flag):- flag_to_var(Flag,Var),
   (option_value(Var,true)->true;(Flag\==Var -> is_debugging(Var))).

:- nodebug(metta(overflow)).


eval_99(Expander,RetType,Depth,Self,X,Y):- 
  eval(Expander,RetType,Depth,Self,X,Y)*->true;eval_failed(Depth,Self,X,Y).

eval_00(_Expander,_RetType,Depth,_Slf,X,Y):- Depth<1,!,X=Y, (\+ trace_on_overflow-> true; flag(eval_num,_,0),debug(metta(eval))).
%eval_00(Expander,RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,Y=X.
eval_00(Expander,RetType,Depth,Self,X,YO):-
( Depth2 is Depth-1,
  eval_11(Expander,RetType,Depth,Self,X,M),
  (M\=@=X ->eval_00(Expander,RetType,Depth2,Self,M,Y);Y=X)),
  finish_eval(Depth2,Self,Y,YO).



eval_11(Expander,RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,do_expander(Expander,RetType,X,Y).
eval_11(Expander,RetType,Depth,Self,X,Y):- \+ is_debugging((eval)),!,
  D1 is Depth-1,
  eval_20(Expander,RetType,D1,Self,X,Y).
eval_11(Expander,RetType,Depth,Self,X,Y):-
 notrace((

  flag(eval_num,EX,EX+1),
  option_else(traclen,Max,100),
  if_trace(eval, (EX>Max->(set_debug(eval,false), %set_debug(overflow,false),
                       write('Switched off tracing. For a longer trace !(pragma! tracelen 101))'));true)),
  nop(notrace(no_repeats_var(YY))),
  notrace(D1 is Depth-1),
  DR is 99-D1,
  if_trace((eval),indentq(Depth,'-->'(EX,eval(Self,X,'$VAR'('RET')),depth(DR)))),
  Ret=retval(fail))),
  call_cleanup((
    eval_20(Expander,RetType,D1,Self,X,Y),
    notrace(( \+ (Y\=YY), nb_setarg(1,Ret,Y)))),
    mnotrace(ignore(((Y\=@=X,if_trace((eval),indentq(Depth,'<--'(EX,Ret)))))))),
  (Ret\=@=retval(fail)->true;(rtrace(eval_00(Expander,RetType,D1,Self,X,Y)),fail)).





















:- discontiguous eval_20/6.
%:- discontiguous eval_40/6.
%:- discontiguous eval_30fz/5.
%:- discontiguous eval_31/5.
%:- discontiguous eval_60/5.

eval_20(Expander,RetType,_Dpth,_Slf,Name,Y):-
    atom(Name), nb_current(Name,X),!,do_expander(Expander,RetType,X,Y).












% =================================================================
% =================================================================
% =================================================================
%  VAR HEADS/ NON-LISTS
% =================================================================
% =================================================================
% =================================================================

eval_20(Expander,RetType,_Dpth,_Slf,[X|T],Y):- T==[], \+ callable(X),!, do_expander(Expander,RetType,X,YY),Y=[YY].
eval_20(Expander,RetType,_Dpth,Self,[X|T],Y):- T==[],  atom(X), 
   \+ is_user_defined_head_f(Self,X), 
   do_expander(Expander,RetType,X,YY),!,Y=[YY].

eval_20(Expander,RetType,Depth,Self,[V|VI],VVO):-  \+ is_list(VI),!,
 eval(Expander,RetType,Depth,Self,VI,VM),
  ( VM\==VI -> eval(Expander,RetType,Depth,Self,[V|VM],VVO) ;
    (eval(Expander,RetType,Depth,Self,V,VV), (V\==VV -> eval(Expander,RetType,Depth,Self,[VV|VI],VVO) ; VVO = [V|VI]))).

eval_20(Expander,RetType,_Dpth,_Slf,X,Y):- \+ is_list(X),!,do_expander(Expander,RetType,X,Y).

eval_20(Expander,_RetType,Depth,Self,[V|VI],[V|VO]):- var(V),is_list(VI),!,maplist(eval(Expander,_ArgRetType,Depth,Self),VI,VO).


% =================================================================
% =================================================================
% =================================================================
%  TRACE/PRINT
% =================================================================
% =================================================================
% =================================================================

eval_20(Expander,RetType,_Dpth,_Slf,['repl!'],Y):- !, repl,check_returnval(Expander,RetType,Y).
eval_20(Expander,RetType,Depth,Self,['!',Cond],Res):- !, call(eval(Expander,RetType,Depth,Self,Cond,Res)).
eval_20(Expander,RetType,Depth,Self,['rtrace!',Cond],Res):- !, rtrace(eval(Expander,RetType,Depth,Self,Cond,Res)).
eval_20(Expander,RetType,Depth,Self,['trace',Cond],Res):- !, with_debug(eval,eval(Expander,RetType,Depth,Self,Cond,Res)).
eval_20(Expander,RetType,Depth,Self,['time',Cond],Res):- !, time_eval(eval(Cond),eval(Expander,RetType,Depth,Self,Cond,Res)).
eval_20(Expander,RetType,Depth,Self,['print',Cond],Res):- !, eval(Expander,RetType,Depth,Self,Cond,Res),format('~N'),print(Res),format('~N').
% !(println! $1)
eval_20(Expander,RetType,Depth,Self,['println!'|Cond],Res):- !, maplist(eval(Expander,RetType,Depth,Self),Cond,[Res|Out]),
   format('~N'),maplist(write_src,[Res|Out]),format('~N').
eval_20(Expander,RetType,Depth,Self,['trace!',A|Cond],Res):- !, maplist(eval(Expander,RetType,Depth,Self),[A|Cond],[AA|Result]),
   last(Result,Res), format('~N'),maplist(write_src,[AA]),format('~N').

%eval_20(Expander,RetType,Depth,Self,['trace!',A,B],C):- !,eval(Expander,RetType,Depth,Self,B,C),format('~N'),wdmsg(['trace!',A,B]=C),format('~N').
%eval_20(Expander,RetType,_Dpth,_Slf,['trace!',A],A):- !, format('~N'),wdmsg(A),format('~N').

eval_20(Expander,RetType,_Dpth,_Slf,List,YY):- is_list(List),maplist(self_eval,List),List=[H|_], \+ atom(H), !,Y=List,do_expander(Expander,RetType,Y,YY).

eval_20(Expander,_ListOfRetType,Depth,Self,['TupleConcat',A,B],OO):- fail, !,
    eval(Expander,RetType,Depth,Self,A,AA),
    eval(Expander,RetType,Depth,Self,B,BB),
    append(AA,BB,OO).
eval_20(Expander,OuterRetType,Depth,Self,['range',A,B],OO):- (is_list(A);is_list(B)),
  ((eval(Expander,RetType,Depth,Self,A,AA),
    eval(Expander,RetType,Depth,Self,B,BB))),
    ((AA+BB)\=@=(A+B)),
    eval_20(Expander,OuterRetType,Depth,Self,['range',AA,BB],OO),!.


%eval_20(Expander,RetType,Depth,Self,['colapse'|List], Flat):- !, maplist(eval(Expander,RetType,Depth,Self),List,Res),flatten(Res,Flat).




% =================================================================
% =================================================================
% =================================================================
%  UNIT TESTING/assert<STAR>
% =================================================================
% =================================================================
% =================================================================


eval_20(Expander,RetType,Depth,Self,['assertTrue', X],TF):- !, eval(Expander,RetType,Depth,Self,['assertEqual',X,'True'],TF).
eval_20(Expander,RetType,Depth,Self,['assertFalse',X],TF):- !, eval(Expander,RetType,Depth,Self,['assertEqual',X,'False'],TF).

eval_20(Expander,RetType,Depth,Self,['assertEqual',X,Y],RetVal):- !,
   loonit_assert_source_tf(
        ['assertEqual',X,Y],
        (bagof_eval(Expander,RetType,Depth,Self,X,XX), bagof_eval(Expander,RetType,Depth,Self,Y,YY)),
         equal_enough_for_test(XX,YY), TF),
  (TF=='True'->return_empty(RetVal);RetVal=[got,XX,[expected(_)],YY]).

eval_20(Expander,RetType,Depth,Self,['assertNotEqual',X,Y],RetVal):- !,
   loonit_assert_source_tf(
        ['assertEqual',X,Y],
        (bagof_eval(Expander,RetType,Depth,Self,X,XX), bagof_eval(Expander,RetType,Depth,Self,Y,YY)),
         \+ equal_enough(XX,YY), TF),
  (TF=='True'->return_empty(RetVal);RetVal=[got,XX,expected,YY]).

eval_20(Expander,RetType,Depth,Self,['assertEqualToResult',X,Y],RetVal):- !,
   loonit_assert_source_tf(
        ['assertEqualToResult',X,Y],
        (bagof_eval(Expander,RetType,Depth,Self,X,XX), sort(Y,YY)),
         equal_enough_for_test(XX,YY), TF),
  (TF=='True'->return_empty(RetVal);RetVal=[got,XX,expected,YY]).


loonit_assert_source_tf(Src,Goal,Check,TF):-
   copy_term(Goal,OrigGoal),
   loonit_asserts(Src, time_eval('\n; EVAL TEST\n;',Goal), Check),
   as_tf(Check,TF),!,
  ignore((
          once((TF='True', trace_on_pass);(TF='False', trace_on_fail)),
     with_debug(metta(eval),time_eval('Trace',OrigGoal)))).

sort_result(Res,Res):- \+ compound(Res),!.
sort_result([And|Res1],Res):- is_and(And),!,sort_result(Res1,Res).
sort_result([T,And|Res1],Res):- is_and(And),!,sort_result([T|Res1],Res).
sort_result([H|T],[HH|TT]):- !, sort_result(H,HH),sort_result(T,TT).
sort_result(Res,Res).

unify_enough(L,L).
%unify_enough(L,C):- is_list(L),into_list_args(C,CC),!,unify_lists(CC,L).
%unify_enough(C,L):- is_list(L),into_list_args(C,CC),!,unify_lists(CC,L).
%unify_enough(C,L):- \+ compound(C),!,L=C.
%unify_enough(L,C):- \+ compound(C),!,L=C.
unify_enough(L,C):- into_list_args(L,LL),into_list_args(C,CC),unify_lists(CC,LL).

%unify_lists(C,L):- \+ compound(C),!,L=C.
%unify_lists(L,C):- \+ compound(C),!,L=C.
unify_lists(L,L):-!.
unify_lists([C|CC],[L|LL]):- unify_enough(L,C),!,unify_lists(CC,LL).

equal_enough(R,V):- is_list(R),is_list(V),sort(R,RR),sort(V,VV),!,equal_enouf(RR,VV),!.
equal_enough(R,V):- copy_term(R,RR),copy_term(V,VV),equal_enouf(R,V),!,R=@=RR,V=@=VV.

%s_empty(X):- var(X),!.
s_empty(X):- var(X),!,fail.
is_empty('Empty').
is_empty([]).
is_empty([X]):-!,is_empty(X).
has_let_star(Y):- sub_var('let*',Y).

equal_enough_for_test(X,Y):- is_empty(X),!,is_empty(Y).
equal_enough_for_test(X,Y):- has_let_star(Y),!,\+ is_empty(X).
equal_enough_for_test(X,Y):- must_det_ll((subst_vars(X,XX),subst_vars(Y,YY))),!,equal_enough_for_test2(XX,YY),!.
equal_enough_for_test2(X,Y):- equal_enough(X,Y).

equal_enouf(R,V):- is_ftVar(R), is_ftVar(V), R=V,!.
equal_enouf(X,Y):- is_empty(X),!,is_empty(Y).
equal_enouf(R,V):- R=@=V, R=V, !.
equal_enouf(_,V):- V=@='...',!.
equal_enouf(L,C):- is_list(L),into_list_args(C,CC),!,equal_enouf_l(CC,L).
equal_enouf(C,L):- is_list(L),into_list_args(C,CC),!,equal_enouf_l(CC,L).
%equal_enouf(R,V):- (var(R),var(V)),!, R=V.
equal_enouf(R,V):- (var(R);var(V)),!, R==V.
equal_enouf(R,V):- number(R),number(V),!, RV is abs(R-V), RV < 0.03 .
equal_enouf(R,V):- atom(R),!,atom(V), has_unicode(R),has_unicode(V).
equal_enouf(R,V):- (\+ compound(R) ; \+ compound(V)),!, R==V.
equal_enouf(L,C):- into_list_args(L,LL),into_list_args(C,CC),!,equal_enouf_l(CC,LL).

equal_enouf_l([S1,V1|_],[S2,V2|_]):- S1 == 'State',S2 == 'State',!, equal_enouf(V1,V2).
equal_enouf_l(C,L):- \+ compound(C),!,L=@=C.
equal_enouf_l(L,C):- \+ compound(C),!,L=@=C.
equal_enouf_l([C|CC],[L|LL]):- !, equal_enouf(L,C),!,equal_enouf_l(CC,LL).


has_unicode(A):- atom_codes(A,Cs),member(N,Cs),N>127,!.

set_last_error(_).

% =================================================================
% =================================================================
% =================================================================
%  SPACE EDITING
% =================================================================
% =================================================================
% =================================================================
% do_metta(_Who,What,Where,PredDecl,_TF):-   do_metta(Where,What, PredDecl).
/*
eval_20(Expander,RetType,_Dpth,Self,['add-atom',Other,PredDecl],TF):- !, into_space(Self,Other,Space), as_tf(do_metta(Space,load,PredDecl),TF).
eval_20(Expander,RetType,_Dpth,Self,['remove-atom',Other,PredDecl],TF):- !, into_space(Self,Other,Space), as_tf(do_metta(Space,unload,PredDecl),TF).
eval_20(Expander,RetType,_Dpth,Self,['atom-count',Other],Count):- !, into_space(Self,Other,Space), findall(_,metta_defn(Other,_,_),L1),length(L1,C1),findall(_,metta_atom(Space,_),L2),length(L2,C2),Count is C1+C2.
eval_20(Expander,RetType,_Dpth,Self,['atom-replace',Other,Rem,Add],TF):- !, into_space(Self,Other,Space), copy_term(Rem,RCopy),
  as_tf((metta_atom_iter_ref(Space,RCopy,Ref), RCopy=@=Rem,erase(Ref), do_metta(Other,load,Add)),TF).
*/

eval_20(Expander,RetType,Depth,Self,['add-atom',Other,PredDecl],Res):- !,
   into_space(Depth,Self,Other,Space),
   do_metta(python,load,Space,PredDecl,TF),return_empty([],Res),check_returnval(Expander,RetType,TF).
eval_20(Expander,RetType,Depth,Self,['remove-atom',Other,PredDecl],Res):- !,   into_space(Depth,Self,Other,Space),
   do_metta(python,unload,Space,PredDecl,TF),return_empty([],Res),check_returnval(Expander,RetType,TF).
eval_20(Expander,RetType,Depth,Self,['atom-count',Other],Count):- !,   (( into_space(Depth,Self,Other,Space), findall(_,metta_defn(Other,_,_),L1),length(L1,C1),
    findall(_,metta_atom(Space,_),L2),length(L2,C2),Count is C1+C2)),check_returnval(Expander,RetType,Count).
eval_20(Expander,RetType,Depth,Self,['atom-replace',Other,Rem,Add],TF):- !,
 ((into_space(Depth,Self,Other,Space), copy_term(Rem,RCopy),
   as_tf((metta_atom_iter_ref(Space,RCopy,Ref), RCopy=@=Rem,erase(Ref), do_metta(Other,load,Add)),TF))),
 check_returnval(Expander,RetType,TF).
eval_20(Expander,RetType,Depth,Self,['get-atoms',Other],Atom):- !,
  ignore(RetType='Atom'),
  get_atoms(Depth,Self,Other,Atom), check_returnval(Expander,RetType,Atom).

get_atoms(_Dpth,_Slf,Other,Atom):- Other=='&self',!,dcall(metta_atom(Other,Atom)).
% get_atoms_fail(Depth,Self,Other,Atom):- fail, is_asserted_space(Other),!, metta_atom(Other,Atom).
get_atoms(Depth,Self,Other,AtomO):-
  into_space(Depth,Self,Other,Space),
  once((space_to_Space(Depth,Self,Space,SpaceC),
  into_listoid(SpaceC,AtomsL))),
  %no_repeat_var(NRAtom),
  dcall((member(Atom,AtomsL),
  %Atom = NRAtom,
  AtomO=Atom)).

space_to_Space(_Dpth,_Slf,Space,SpaceC):- compound(Space),functor(Space,_,1),arg(1,Space,L),is_list(L),!,SpaceC=Space.
space_to_Space(Depth,Self,Space,SpaceC):- findall(Atom, metta_atom_iter(Depth,Self,Space,Atom),Atoms),
   SpaceC = 'hyperon::space::DynSpace'(Atoms).

%eval_20(Expander,RetType,Depth,Self,['match',Other,Goal,Template],Template):- into_space(Self,Other,Space),!, metta_atom_iter(Depth,Space,Goal).
%eval_20(Expander,RetType,Depth,Self,['match',Other,Goal,Template,Else],Template):- into_space(Self,Other,Space),!,  (metta_atom_iter(Depth,Space,Goal)*->true;Else=Template).

% Match-ELSE
eval_20(Expander,RetType,Depth,Self,['match',Other,Goal,Template,Else],Template):- !,
  ((eval_20(Expander,RetType,Depth,Self,['match',Other,Goal,Template],Template),
       \+ return_empty([],Template))*->true;Template=Else).
% Match-TEMPLATE
eval_20(Expander,RetType,Depth,Self,['match',Other,Goal,Template],Res):- !,
  dcall(( % copy_term(Goal+Template,CGoal+CTemplate),
  catch(get_atoms(Depth,Self,Other,Goal),E,
   (wdmsg(catch(get_atoms(Depth,Self,Other,Goal)=E)),
     rtrace(get_atoms(Depth,Self,Other,Goal)))))),
  %print(Template),
  must_eval_args(Expander,RetType,Depth,Self,Template,Res).


  /*
try_ma tch(Expander,RetType,Depth,Self,Other,Goal,Template,Res):- fail,
  into_space(Depth,Self,Other,Space),
  metta_atom_iter(Depth,Self,Space,Goal),
  eval_99(Expander,RetType,Depth,Self,Template,Res).
*/

try_match(Depth,Self,Other,Goal,_Template):-
  get_atoms(Depth,Self,Other,Goal).
  % Template=Res.

metta_atom_iter(Depth,Other,H):-
   current_self(Self),
   metta_atom_iter(Depth,Self,Other,H).

metta_atom_iter_fail(Depth,_Slf,Other,[Equal,[F|H],B]):- fail, '=' == Equal,!,  % trace,
   dcall(metta_defn(Other,[F|HH],BB)),
   once(eval_until_unify(Depth,Other,H,HH)),
   once(eval_until_unify(Depth,Other,B,BB)).

metta_atom_iter(_Depth,_Slf,Other,[Equal,[F|H],B]):- '=' == Equal,!,  % trace,
   dcall(metta_defn(Other,[F|H],B)). % once(eval_until_unify(Depth,Other,H,HH)).

%metta_atom_iter(Depth,_Slf,Other,[Equal,[F|H],B]):- '=' == Equal,!,  % trace,
 %  dcall(metta_defn(Other,[F|HH],B)), once(eval_until_unify(Depth,Other,H,HH)).

metta_atom_iter(Depth,_,_,_):- Depth<3,!,fail.
metta_atom_iter(Depth,Self,Other,[And|Y]):- atom(And), is_and(And),!,
  (Y==[] -> true ;  ( D2 is Depth -1, Y = [H|T], metta_atom_iter(D2,Self,Other,H),metta_atom_iter(D2,Self,Other,[And|T]))).
metta_atom_iter(_Dpth,_Slf,Other,H):- metta_atom(Other,H).
metta_atom_iter(Depth,Self,Other,H):- metta_defn(Other,H,B), D2 is Depth -1, metta_atom_iter(D2,Self,Other,B).
%metta_atom_iter(Depth,Other,H):- D2 is Depth -1, metta_defn(Other,H,B),metta_atom_iter(D2,Other,B).
%metta_atom_iter_l2(Depth,Self,Other,H):- metta_atom_iter(Depth,Self,Other,H).
%$metta_atom_iter(_Dpth,_Slf,[]):-!.

eval_20(Expander,RetType,_Dpth,_Slf,['new-space'],Space):- !, 'new-space'(Space),check_returnval(Expander,RetType,Space).


/*

metta_atom_iter(_Dpth,Other,[Equal,H,B]):- '=' == Equal,!,
  (metta_defn(Other,H,B)*->true;(metta_atom(Other,H),B='True')).

metta_atom_iter(Depth,_,_):- Depth<3,!,fail.
metta_atom_iter(_Dpth,_Slf,[]):-!.
metta_atom_iter(_Dpth,Other,H):- metta_atom(Other,H).
metta_atom_iter(Depth,Other,H):- D2 is Depth -1, metta_defn(Other,H,B),metta_atom_iter(D2,Other,B).
metta_atom_iter(_Dpth,_Slf,[And]):- is_and(And),!.
metta_atom_iter(Depth,Self,[And,X|Y]):- is_and(And),!,D2 is Depth -1, metta_atom_iter(D2,Self,X),metta_atom_iter(D2,Self,[And|Y]).
*/
/*
metta_atom_iter2(_,Self,[=,X,Y]):- metta_defn(Self,X,Y).
metta_atom_iter2(_Dpth,Other,[Equal,H,B]):- '=' == Equal,!, metta_defn(Other,H,B).
metta_atom_iter2(_Dpth,Self,X,Y):- metta_defn(Self,X,Y). %, Y\=='True'.
metta_atom_iter2(_Dpth,Self,X,Y):- metta_atom(Self,[=,X,Y]). %, Y\=='True'.
*/
metta_atom_iter_ref(Other,['=',H,B],Ref):-clause(metta_defn(Other,H,B),true,Ref).
metta_atom_iter_ref(Other,H,Ref):-clause(metta_atom(Other,H),true,Ref).


% =================================================================
% =================================================================
% =================================================================
%  CASE/SWITCH
% =================================================================
% =================================================================
% =================================================================

% Macro: case
eval_20(Expander,RetType,Depth,Self,['case',A,CL|T],Res):-
   must_det_ll(T==[]),
   into_case_list(CL,CASES),
   findall(Key-Value,
     (nth0(Nth,CASES,Case0),
       (is_case(Key,Case0,Value),
        if_trace(metta(case),(format('~N'),writeqln(c(Nth,Key)=Value))))),KVs),!,
   ((eval(Expander,RetType,Depth,Self,A,AA),
         if_trace(metta(case),writeqln(switch=AA)),
    (select_case(Depth,Self,AA,KVs,Value)->true;(member(Void -Value,KVs),Void=='%void%')))
     *->true;(member(Void -Value,KVs),Void=='%void%')),
    eval(Expander,RetType,Depth,Self,Value,Res).

  select_case(Depth,Self,AA,Cases,Value):-
     (best_key(AA,Cases,Value) -> true ;
      (maybe_special_keys(Depth,Self,Cases,CasES),
       (best_key(AA,CasES,Value) -> true ;
        (member(Void -Value,CasES),Void=='%void%')))).

  best_key(AA,Cases,Value):-
     ((member(Match-Value,Cases),AA ==Match)->true;
      ((member(Match-Value,Cases),AA=@=Match)->true;
        (member(Match-Value,Cases),AA = Match))).

		%into_case_list([[C|ASES0]],CASES):-  is_list(C),!, into_case_list([C|ASES0],CASES),!.
	into_case_list(CASES,CASES):- is_list(CASES),!.
		is_case(AA,[AA,Value],Value):-!.
		is_case(AA,[AA|Value],Value).

   maybe_special_keys(Depth,Self,[K-V|KVI],[AK-V|KVO]):-
     eval(Depth,Self,K,AK), K\=@=AK,!,
     maybe_special_keys(Depth,Self,KVI,KVO).
   maybe_special_keys(Depth,Self,[_|KVI],KVO):-
     maybe_special_keys(Depth,Self,KVI,KVO).
   maybe_special_keys(_Depth,_Self,[],[]).


% =================================================================
% =================================================================
% =================================================================
%  COLLAPSE/SUPERPOSE
% =================================================================
% =================================================================
% =================================================================



%[collapse,[1,2,3]]
eval_20(Expander,RetType,Depth,Self,['collapse',List],Res):-!,
 bagof_eval(Expander,RetType,Depth,Self,List,Res).

%[superpose,[1,2,3]]
eval_20(Expander,RetType,Depth,Self,['superpose',List],Res):- !,
  ((is_user_defined_goal(Self,List) ,eval(Expander,RetType,Depth,Self,List,UList), List\=@=UList)
    *->  eval_20(Expander,RetType,Depth,Self,['superpose',UList],Res)
       ; ((member(E,List),eval(Expander,RetType,Depth,Self,E,Res))*->true;return_empty([],Res))).

%[sequential,[1,2,3]]
eval_20(Expander,RetType,Depth,Self,['sequential',List],Res):- !,
  eval_20(Expander,RetType,Depth,Self,['superpose',List],Res).

get_sa_p1(P3,E,Cmpd,SA):-  compound(Cmpd), get_sa_p2(P3,E,Cmpd,SA).
get_sa_p2(P3,E,Cmpd,call(P3,N1,Cmpd)):- arg(N1,Cmpd,E).
get_sa_p2(P3,E,Cmpd,SA):- arg(_,Cmpd,Arg),get_sa_p1(P3,E,Arg,SA).
eval20_failed(Expander,RetType,Depth,Self, Term, Res):-
  mnotrace(( get_sa_p1(setarg,ST,Term,P1), % ST\==Term,
   compound(ST), ST = [F,List],F=='superpose',nonvar(List), %maplist(atomic,List),
   call(P1,Var))), !,
   %max_counting(F,20),
   member(Var,List),
   eval(Expander,RetType,Depth,Self, Term, Res).


sub_sterm(Sub,Sub).
sub_sterm(Sub,Term):- sub_sterm1(Sub,Term).
sub_sterm1(_  ,List):- \+ compound(List),!,fail.
sub_sterm1(Sub,List):- is_list(List),!,member(SL,List),sub_sterm(Sub,SL).
sub_sterm1(_  ,[_|_]):-!,fail.
sub_sterm1(Sub,Term):- arg(_,Term,SL),sub_sterm(Sub,SL).
eval20_failed_2(Expander,RetType,Depth,Self, Term, Res):-
   mnotrace(( get_sa_p1(setarg,ST,Term,P1),
   compound(ST), ST = [F,List],F=='collapse',nonvar(List), %maplist(atomic,List),
   call(P1,Var))), !, bagof_eval(Expander,RetType,Depth,Self,List,Var),
   eval(Expander,RetType,Depth,Self, Term, Res).


max_counting(F,Max):- flag(F,X,X+1),  X<Max ->  true; (flag(F,_,10),!,fail).
% =================================================================
% =================================================================
% =================================================================
%  if/If
% =================================================================
% =================================================================
% =================================================================



eval_20(Expander,RetType,Depth,Self,['if',Cond,Then,Else],Res):- !,
   eval(Expander,'Bool',Depth,Self,Cond,TF),
   (is_True(TF)
     -> eval(Expander,RetType,Depth,Self,Then,Res)
     ;  eval(Expander,RetType,Depth,Self,Else,Res)).

eval_20(Expander,RetType,Depth,Self,['If',Cond,Then,Else],Res):- !,
   eval(Expander,'Bool',Depth,Self,Cond,TF),
   (is_True(TF)
     -> eval(Expander,RetType,Depth,Self,Then,Res)
     ;  eval(Expander,RetType,Depth,Self,Else,Res)).

eval_20(Expander,RetType,Depth,Self,['If',Cond,Then],Res):- !,
   eval(Expander,'Bool',Depth,Self,Cond,TF),
   (is_True(TF) -> eval(Expander,RetType,Depth,Self,Then,Res) ;
      (!, fail,Res = [],!)).

eval_20(Expander,RetType,Depth,Self,['if',Cond,Then],Res):- !,
   eval(Expander,'Bool',Depth,Self,Cond,TF),
   (is_True(TF) -> eval(Expander,RetType,Depth,Self,Then,Res) ;
      (!, fail,Res = [],!)).


eval_20(Expander,RetType,_Dpth,_Slf,[_,Nothing],NothingO):- 
   'Nothing'==Nothing,!,do_expander(Expander,RetType,Nothing,NothingO).

% =================================================================
% =================================================================
% =================================================================
%  LET/LET*
% =================================================================
% =================================================================
% =================================================================



eval_until_unify(_Dpth,_Slf,X,X):- !.
eval_until_unify(Depth,Self,X,Y):- eval_until_eq(Expander,_RetType,Depth,Self,X,Y).

eval_until_eq(Expander,RetType,_Dpth,_Slf,X,Y):-  X=Y,check_returnval(Expander,RetType,Y).
%eval_until_eq(Expander,RetType,Depth,Self,X,Y):- var(Y),!,eval_in_steps_or_same(Expander,RetType,Depth,Self,X,XX),Y=XX.
%eval_until_eq(Expander,RetType,Depth,Self,Y,X):- var(Y),!,eval_in_steps_or_same(Expander,RetType,Depth,Self,X,XX),Y=XX.
eval_until_eq(Expander,RetType,Depth,Self,X,Y):- \+is_list(Y),!,eval_in_steps_some_change(Expander,RetType,Depth,Self,X,XX),Y=XX.
eval_until_eq(Expander,RetType,Depth,Self,Y,X):- \+is_list(Y),!,eval_in_steps_some_change(Expander,RetType,Depth,Self,X,XX),Y=XX.
eval_until_eq(Expander,RetType,Depth,Self,X,Y):- eval_in_steps_some_change(Expander,RetType,Depth,Self,X,XX),eval_until_eq(Expander,RetType,Depth,Self,Y,XX).
eval_until_eq(Expander,_RetType,_Dpth,_Slf,X,Y):- length(X,Len), \+ length(Y,Len),!,fail.
eval_until_eq(Expander,RetType,Depth,Self,X,Y):-  nth1(N,X,EX,RX), nth1(N,Y,EY,RY),
  EX=EY,!, maplist(eval_until_eq(Expander,RetType,Depth,Self),RX,RY).
eval_until_eq(Expander,RetType,Depth,Self,X,Y):-  nth1(N,X,EX,RX), nth1(N,Y,EY,RY),
  ((var(EX);var(EY)),eval_until_eq(Expander,RetType,Depth,Self,EX,EY)),
  maplist(eval_until_eq(Expander,RetType,Depth,Self),RX,RY).
eval_until_eq(Expander,RetType,Depth,Self,X,Y):-  nth1(N,X,EX,RX), nth1(N,Y,EY,RY),
  h((is_list(EX);is_list(EY)),eval_until_eq(Expander,RetType,Depth,Self,EX,EY)),
  maplist(eval_until_eq(Expander,RetType,Depth,Self),RX,RY).

 eval_1change(Expander,RetType,Depth,Self,EX,EXX):-
    eval_20(Expander,RetType,Depth,Self,EX,EXX),  EX \=@= EXX.

eval_complete_change(Expander,RetType,Depth,Self,EX,EXX):-
   eval(Expander,RetType,Depth,Self,EX,EXX),  EX \=@= EXX.

eval_in_steps_some_change(Expander,_RetType,_Dpth,_Slf,EX,_):- \+ is_list(EX),!,fail.
eval_in_steps_some_change(Expander,RetType,Depth,Self,EX,EXX):- eval_1change(Expander,RetType,Depth,Self,EX,EXX).
eval_in_steps_some_change(Expander,RetType,Depth,Self,X,Y):- append(L,[EX|R],X),is_list(EX),
    eval_in_steps_some_change(Expander,RetType,Depth,Self,EX,EXX), EX\=@=EXX,
    append(L,[EXX|R],XX),eval_in_steps_or_same(Expander,RetType,Depth,Self,XX,Y).

eval_in_steps_or_same(Expander,RetType,Depth,Self,X,Y):-eval_in_steps_some_change(Expander,RetType,Depth,Self,X,Y).
eval_in_steps_or_same(Expander,RetType,_Dpth,_Slf,X,Y):- X=Y,check_returnval(Expander,RetType,Y).

  % (fail,return_empty([],Template))).
  
  
eval_20(Expander,RetType,Depth,Self,['let',A,A5,AA],OO):- !,
  %(var(A)->true;trace),
  ((eval(Expander,RetType,Depth,Self,A5,AE), AE=A)),
    eval(Expander,RetType,Depth,Self,AA,OO).
%eval_20(Expander,RetType,Depth,Self,['let',A,A5,AA],AAO):- !,eval(Expander,RetType,Depth,Self,A5,A),eval(Expander,RetType,Depth,Self,AA,AAO).
eval_20(Expander,RetType,Depth,Self,['let*',[],Body],RetVal):- !, eval(Expander,RetType,Depth,Self,Body,RetVal).
eval_20(Expander,RetType,Depth,Self,['let*',[[Var,Val]|LetRest],Body],RetVal):- !,
     eval_20(Expander,RetType,Depth,Self,['let',Var,Val,['let*',LetRest,Body]],RetVal).


% =================================================================
% =================================================================
% =================================================================
%  CONS/CAR/CDR
% =================================================================
% =================================================================
% =================================================================



into_pl_list(Var,Var):- var(Var),!.
into_pl_list(Nil,[]):- Nil == 'Nil',!.
into_pl_list([Cons,H,T],[HH|TT]):- Cons == 'Cons', !, into_pl_list(H,HH),into_pl_list(T,TT),!.
into_pl_list(X,X).

into_metta_cons(Var,Var):- var(Var),!.
into_metta_cons([],'Nil'):-!.
into_metta_cons([Cons, A, B ],['Cons', AA, BB]):- 'Cons'==Cons, no_cons_reduce, !,
  into_metta_cons(A,AA), into_metta_cons(B,BB).
into_metta_cons([H|T],['Cons',HH,TT]):- into_metta_cons(H,HH),into_metta_cons(T,TT),!.
into_metta_cons(X,X).

into_listoid(AtomC,Atom):- AtomC = [Cons,H,T],Cons=='Cons',!, Atom=[H,[T]].
into_listoid(AtomC,Atom):- is_list(AtomC),!,Atom=AtomC.
into_listoid(AtomC,Atom):- typed_list(AtomC,_,Atom),!.

:- if( \+  current_predicate( typed_list / 3 )).
typed_list(Cmpd,Type,List):-  compound(Cmpd), Cmpd\=[_|_], compound_name_arguments(Cmpd,Type,[List|_]),is_list(List).
:- endif.

%eval_20(Expander,RetType,Depth,Self,['colapse'|List], Flat):- !, maplist(eval(Expander,RetType,Depth,Self),List,Res),flatten(Res,Flat).

%eval_20(Expander,RetType,Depth,Self,['flatten'|List], Flat):- !, maplist(eval(Expander,RetType,Depth,Self),List,Res),flatten(Res,Flat).


eval_20(Expander,RetType,_Dpth,_Slf,['car-atom',Atom],CAR_Y):- !, Atom=[CAR|_],!,do_expander(Expander,RetType,CAR,CAR_Y).
eval_20(Expander,RetType,_Dpth,_Slf,['cdr-atom',Atom],CDR_Y):- !, Atom=[_|CDR],!,do_expander(Expander,RetType,CDR,CDR_Y).

eval_20(Expander,RetType,Depth,Self,['Cons', A, B ],['Cons', AA, BB]):- no_cons_reduce, !,
  eval(Expander,RetType,Depth,Self,A,AA), eval(Expander,RetType,Depth,Self,B,BB).

eval_20(Expander,RetType,Depth,Self,['Cons', A, B ],[AA|BB]):- \+ no_cons_reduce, !,
   eval(Expander,RetType,Depth,Self,A,AA), eval(Expander,RetType,Depth,Self,B,BB).



% =================================================================
% =================================================================
% =================================================================
%  STATE EDITING
% =================================================================
% =================================================================
% =================================================================

eval_20(Expander,RetType,Depth,Self,['change-state!',StateExpr, UpdatedValue], Ret):- !, eval(Expander,RetType,Depth,Self,StateExpr,StateMonad),
  eval(Expander,RetType,Depth,Self,UpdatedValue,Value),  'change-state!'(Depth,Self,StateMonad, Value, Ret).
eval_20(Expander,RetType,Depth,Self,['new-state',UpdatedValue],StateMonad):- !,
  eval(Expander,RetType,Depth,Self,UpdatedValue,Value),  'new-state'(Depth,Self,Value,StateMonad).
eval_20(Expander,RetType,Depth,Self,['get-state',StateExpr],Value):- !,
  eval(Expander,RetType,Depth,Self,StateExpr,StateMonad), 'get-state'(StateMonad,Value).



% eval_20(Expander,RetType,Depth,Self,['get-state',Expr],Value):- !, eval(Expander,RetType,Depth,Self,Expr,State), arg(1,State,Value).



check_type:- option_else(typecheck,TF,'False'), TF=='True'.

:- dynamic is_registered_state/1.
:- flush_output.
:- setenv('RUST_BACKTRACE',full).

% Function to check if an value is registered as a state name
:- dynamic(is_registered_state/1).
is_nb_state(G):- is_valid_nb_state(G) -> true ;
                 is_registered_state(G),nb_current(G,S),is_valid_nb_state(S).

/*
:- multifile(space_type_method/3).
:- dynamic(space_type_method/3).
space_type_method(is_nb_space,new_space,init_space).
space_type_method(is_nb_space,clear_space,clear_nb_atoms).
space_type_method(is_nb_space,add_atom,add_nb_atom).
space_type_method(is_nb_space,remove_atom,'change-space!').
space_type_method(is_nb_space,replace_atom,replace_nb_atom).
space_type_method(is_nb_space,atom_count,atom_nb_count).
space_type_method(is_nb_space,get_atoms,'get-space').
space_type_method(is_nb_space,atom_iter,atom_nb_iter).
*/

:- multifile(state_type_method/3).
:- dynamic(state_type_method/3).
state_type_method(is_nb_state,new_state,init_state).
state_type_method(is_nb_state,clear_state,clear_nb_values).
state_type_method(is_nb_state,add_value,add_nb_value).
state_type_method(is_nb_state,remove_value,'change-state!').
state_type_method(is_nb_state,replace_value,replace_nb_value).
state_type_method(is_nb_state,value_count,value_nb_count).
state_type_method(is_nb_state,'get-state','get-state').
state_type_method(is_nb_state,value_iter,value_nb_iter).
%state_type_method(is_nb_state,query,state_nb_query).

% Clear all values from a state
clear_nb_values(StateNameOrInstance) :-
    fetch_or_create_state(StateNameOrInstance, State),
    nb_setarg(1, State, []).



% Function to confirm if a term represents a state
is_valid_nb_state(State):- compound(State),functor(State,'State',_).

% Find the original name of a given state
state_original_name(State, Name) :-
    is_registered_state(Name),
    nb_current(Name, State).

% Register and initialize a new state
init_state(Name) :-
    State = 'State'(_,_),
    asserta(is_registered_state(Name)),
    nb_setval(Name, State).

% Change a value in a state
'change-state!'(Depth,Self,StateNameOrInstance, UpdatedValue, Out) :-
    fetch_or_create_state(StateNameOrInstance, State),
    arg(2, State, Type),
    ( (check_type,\+ get_type(Depth,Self,UpdatedValue,Type))
     -> (Out = ['Error', UpdatedValue, 'BadType'])
     ; (nb_setarg(1, State, UpdatedValue), Out = State) ).

% Fetch all values from a state
'get-state'(StateNameOrInstance, Values) :-
    fetch_or_create_state(StateNameOrInstance, State),
    arg(1, State, Values).

'new-state'(Depth,Self,Init,'State'(Init, Type)):- check_type->get_type(Depth,Self,Init,Type);true.

'new-state'(Init,'State'(Init, Type)):- check_type->get_type(10,'&self',Init,Type);true.

fetch_or_create_state(Name):- fetch_or_create_state(Name,_).
% Fetch an existing state or create a new one

fetch_or_create_state(State, State) :- is_valid_nb_state(State),!.
fetch_or_create_state(NameOrInstance, State) :-
    (   atom(NameOrInstance)
    ->  (is_registered_state(NameOrInstance)
        ->  nb_current(NameOrInstance, State)
        ;   init_state(NameOrInstance),
            nb_current(NameOrInstance, State))
    ;   is_valid_nb_state(NameOrInstance)
    ->  State = NameOrInstance
    ;   writeln('Error: Invalid input.')
    ),
    is_valid_nb_state(State).

% =================================================================
% =================================================================
% =================================================================
%  GET-TYPE
% =================================================================
% =================================================================
% =================================================================

eval_20(Expander,RetType,Depth,Self,['get-type',Val],TypeO):- !, get_type(Depth,Self,Val,Type),ground(Type),Type\==[], Type\==Val,!,
  do_expander(Expander,RetType,Type,TypeO).



eval_20(Expander,RetType,Depth,Self,['length',L],Res):- !, eval(Expander,RetType,Depth,Self,L,LL), !, (is_list(LL)->length(LL,Res);Res=1).
eval_20(Expander,RetType,Depth,Self,['CountElement',L],Res):- !, eval(Expander,RetType,Depth,Self,L,LL), !, (is_list(LL)->length(LL,Res);Res=1).






% =================================================================
% =================================================================
% =================================================================
%  IMPORT/BIND
% =================================================================
% =================================================================
% =================================================================
nb_bind(Name,Value):- nb_current(Name,Was),same_term(Value,Was),!.
nb_bind(Name,Value):- nb_setval(Name,Value),!.
eval_20(Expander,RetType,Depth,Self,['import!',Other,File],RetVal):-
     (( into_space(Depth,Self,Other,Space),!, include_metta(Space,File),!,return_empty(Space,RetVal))),
     check_returnval(Expander,RetType,RetVal). %RetVal=[].
eval_20(Expander,RetType,Depth,Self,['bind!',Other,Expr],RetVal):-
   must_det_ll((into_name(Self,Other,Name),!,eval(Expander,RetType,Depth,Self,Expr,Value),
    nb_bind(Name,Value),  return_empty(Value,RetVal))),
   check_returnval(Expander,RetType,RetVal).
eval_20(Expander,RetType,Depth,Self,['pragma!',Other,Expr],RetVal):-
   must_det_ll((into_name(Self,Other,Name),!,nd_ignore((eval(Expander,RetType,Depth,Self,Expr,Value),set_option_value(Name,Value))),  return_empty(Value,RetVal),
    check_returnval(Expander,RetType,RetVal))).
eval_20(Expander,RetType,_Dpth,Self,['transfer!',File],RetVal):- !, must_det_ll((include_metta(Self,File),  return_empty(Self,RetVal),check_returnval(Expander,RetType,RetVal))).


nd_ignore(Goal):- call(Goal)*->true;true.








% =================================================================
% =================================================================
% =================================================================
%  NOP/EQUALITU/DO
% =================================================================
% =================================================================
% ================================================================
eval_20(_Expander,_RetType1,Depth,Self,['nop',Expr], Empty):- !,
  eval('=',_RetType2,Depth,Self,Expr,_),
  return_empty([], Empty).

eval_20(_Expander,_RetType1,Depth,Self,['do',Expr], Empty):- !,
  eval('=',_RetType2,Depth,Self,Expr,_),
  return_empty([],Empty).
/*
eval_20(Expander,_RetType1,Depth,Self,['do',Expr], Empty):- !,
  forall(eval(Expander,_RetType2,Depth,Self,Expr,_),true),
  return_empty([],_Empty).
*/
eval_20(_Expander,_RetType,_Depth,_Self,['nop'],_ ):- !, fail.

eval_20(_Expander,_RetType1,_Depth,_Self,['call',S], TF):- !, eval_call(S,TF).

% =================================================================
% =================================================================
% =================================================================
%  AND/OR
% =================================================================
% =================================================================
% =================================================================

is_True(T):- T\=='False',T\=='F',T\==[].

is_and(S):- \+ atom(S),!,fail.
is_and(',').
is_and(S,_):- \+ atom(S),!,fail.
is_and('and','True').
is_and('and2','True').
is_and('#COMMA','True'). is_and(',','True').  % is_and('And').

eval_20(Expander,RetType,_Dpth,_Slf,[And],True):- is_and(And,True),!,check_returnval(Expander,RetType,True).
eval_20(Expander,RetType,Depth,Self,[And,X,Y],TF):-  is_and(And,True),!, as_tf((
  eval_args(Expander,RetType,Depth,Self,X,True),eval_args(Expander,RetType,Depth,Self,Y,True)),TF).
eval_20(Expander,RetType,Depth,Self,[And,X],True):- is_and(And,True),!,
  eval_args(Expander,RetType,Depth,Self,X,True).
eval_20(Expander,RetType,Depth,Self,[And,X|Y],TF):- is_and(And,_True),!,
  eval_args(Expander,RetType,Depth,Self,X,TF1), \+ \+ is_True(TF1),
  eval_args(Expander,RetType,Depth,Self,[And|Y],TF).

eval_20(Expander,RetType,Depth,Self,['or',X,Y],TF):- !,
   as_tf((eval_args(Expander,RetType,Depth,Self,X,'True');eval_args(Expander,RetType,Depth,Self,Y,'True')),TF).


% =================================================================
% =================================================================
% =================================================================
%  PLUS/MINUS
% =================================================================
% =================================================================
% =================================================================
eval_20(Expander,RetType,Depth,Self,['+',N1,N2],N):- number(N1),!,
   eval(Expander,RetType,Depth,Self,N2,N2Res), catch(N is N1+N2Res,_E,(set_last_error(['Error',N2Res,'Number']),fail)).
eval_20(Expander,RetType,Depth,Self,['-',N1,N2],N):- number(N1),!,
   eval(Expander,RetType,Depth,Self,N2,N2Res), catch(N is N1-N2Res,_E,(set_last_error(['Error',N2Res,'Number']),fail)).
eval_20(Expander,RetType,Depth,Self,['*',N1,N2],N):- number(N1),!,
   eval(Expander,RetType,Depth,Self,N2,N2Res), catch(N is N1*N2Res,_E,(set_last_error(['Error',N2Res,'Number']),fail)).

% =================================================================
% =================================================================
% =================================================================
%  DATA FUNCTOR
% =================================================================
% =================================================================
% =================================================================
eval20_failked(Expander,RetType,Depth,Self,[V|VI],[V|VO]):-
    nonvar(V),is_metta_data_functor(V),is_list(VI),!,
    maplist(eval(Expander,RetType,Depth,Self),VI,VO).


% =================================================================
% =================================================================
% =================================================================
%  EVAL FAILED
% =================================================================
% =================================================================
% =================================================================
eval_20(Expander,RetType,Depth,Self,X,Y):-
  (eval_40(Expander,RetType,Depth,Self,X,M)*->
     M=Y ;
     % finish_eval(Depth,Self,M,Y);
    (eval_failed(Depth,Self,X,Y)*->true;X=Y)).

eval_failed(Depth,Self,T,TT):-
  finish_eval(Depth,Self,T,TT).

finish_eval(_Dpth,_Slf,T,TT):- var(T),!,TT=T.
finish_eval(_Dpth,_Slf,[],[]):-!.
%finish_eval(_Dpth,_Slf,[F|LESS],Res):- once(eval_selfless([F|LESS],Res)),mnotrace([F|LESS]\==Res),!.
%finish_eval(Depth,Self,[V|Nil],[O]):- Nil==[], once(eval(Expander,RetType,Depth,Self,V,O)),V\=@=O,!.
finish_eval(Depth,Self,[H|T],[HH|TT]):- !,
  eval(Depth,Self,H,HH),
  finish_eval(Depth,Self,T,TT).
finish_eval(Depth,Self,T,TT):- eval(Depth,Self,T,TT).

   %eval(Expander,RetType,Depth,Self,X,Y):- eval_20(Expander,RetType,Depth,Self,X,Y)*->true;Y=[].

%eval_20(Expander,RetType,Depth,_,_,_):- Depth<1,!,fail.
%eval_20(Expander,RetType,Depth,_,X,Y):- Depth<3, !, ground(X), (Y=X).
%eval_20(Expander,RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,Y=X.

% Kills zero arity functions eval_20(Expander,RetType,Depth,Self,[X|Nil],[Y]):- Nil ==[],!,eval(Expander,RetType,Depth,Self,X,Y).


/*
into_values(List,Many):- List==[],!,Many=[].
into_values([X|List],Many):- List==[],is_list(X),!,Many=X.
into_values(Many,Many).
eval_40(Expander,RetType,_Dpth,_Slf,Name,Value):- atom(Name), nb_current(Name,Value),!.
*/
% Macro Functions
%eval_20(Expander,RetType,Depth,_,_,_):- Depth<1,!,fail.
eval_40(_Expander,_RetType,Depth,_,X,Y):- Depth<3, !, fail, ground(X), (Y=X).
eval_40(Expander,RetType,Depth,Self,[F|PredDecl],Res):- fail,
   Depth>1,
   mnotrace((sub_sterm1(SSub,PredDecl), ground(SSub),SSub=[_|Sub], is_list(Sub), maplist(atomic,SSub))),
   eval(Expander,RetType,Depth,Self,SSub,Repl),
   mnotrace((SSub\=Repl, subst(PredDecl,SSub,Repl,Temp))),
   eval(Expander,RetType,Depth,Self,[F|Temp],Res).

% =================================================================
% =================================================================
% =================================================================
%  METTLOG PREDEFS
% =================================================================
% =================================================================
% =================================================================

eval_40(Expander,RetType,Depth,Self,['length',L],Res):- !, eval(Depth,Self,L,LL),
   (is_list(LL)->length(LL,Res);Res=1),
   check_returnval(Expander,RetType,Res).

eval_40(Expander,RetType,_Dpth,_Slf,['arity',F,A],TF):- !,as_tf(current_predicate(F/A),TF),check_returnval(Expander,RetType,TF).
eval_40(Expander,RetType,Depth,Self,['CountElement',L],Res):- !, eval(Expander,RetType,Depth,Self,L,LL), !, (is_list(LL)->length(LL,Res);Res=1),check_returnval(Expander,RetType,Res).
eval_40(Expander,RetType,_Dpth,_Slf,['make_list',List],MettaList):- !, into_metta_cons(List,MettaList),check_returnval(Expander,RetType,MettaList).

% user defined function
eval_40(Expander,RetType,Depth,Self,[H|PredDecl],Res):-
   mnotrace(is_user_defined_head(Self,H)),!,
   eval_60(Expander,RetType,Depth,Self,[H|PredDecl],Res).

eval_40(Expander,RetType,Depth,Self,[AE|More],Res):- is_special_op(AE),!,
  eval_70(Expander,RetType,Depth,Self,[AE|More],Res),
  check_returnval(Expander,RetType,Res).

eval_40(Expander,RetType,Depth,Self,[AE|More],Res):-
  maplist(must_eval_args(Expander,_,Depth,Self),More,Adjusted),
  eval_70(Expander,RetType,Depth,Self,[AE|Adjusted],Res),
  check_returnval(Expander,RetType,Res).

must_eval_args(Expander,RetType,Depth,Self,More,Adjusted):-
   (eval_args(Expander,RetType,Depth,Self,More,Adjusted)*->true;
      (with_debug(eval,eval_args(Expander,RetType,Depth,Self,More,Adjusted))*-> true;
         (
           nl,writeq(eval_args(Expander,RetType,Depth,Self,More,Adjusted)),writeln('.'),
             (More=Adjusted -> true ;
                (trace, throw(must_eval_args(Expander,RetType,Depth,Self,More,Adjusted))))))).


eval_70(_Expander,_RetType,_Dpth,_Slf,['==',X,Y],Res):- !,as_tf(X=Y,Res).


eval_70(Expander,RetType,Depth,Self,PredDecl,Res):-
  Do_more_defs = do_more_defs(true),
  clause(eval_80(Expander,RetType,Depth,Self,PredDecl,Res),Body),
  Do_more_defs == do_more_defs(true),
  call(Body),nb_setarg(1,Do_more_defs,false).


% =================================================================
% =================================================================
% =================================================================
% inherited by system
% =================================================================
% =================================================================
% =================================================================
eval_80(_Expander,_RetType,_Dpth,_Slf,LESS,Res):-
   notrace((ground(LESS),once((eval_selfless(LESS,Res),mnotrace(LESS\==Res))))),!.



% predicate inherited by system
eval_80(Expander,RetType,_Depth,_Self,[AE|More],TF):-
  length(More,Len),
  is_syspred(AE,Len,Pred),
  %mnotrace( \+ is_user_defined_goal(Self,[AE|More])),!,
  %adjust_args(Depth,Self,AE,More,Adjusted),
  More = Adjusted,
  catch_warn(efbug(show_call,as_tf(apply(Pred,Adjusted),TF))),
  check_returnval(Expander,RetType,TF).

:- if( \+  current_predicate( adjust_args / 2 )).

   :- discontiguous eval_80/6.
is_user_defined_goal(Self,Head):-
  is_user_defined_head(Self,Head).

:- endif.


% function inherited by system
eval_80(Expander,RetType,_Depth,_Self,[AE|More],Res):-
  length([AE|More],Len),
  is_syspred(AE,Len,Pred),
  %mnotrace( \+ is_user_defined_goal(Self,[AE|More])),!,
  %adjust_args(Depth,Self,AE,More,Adjusted),!,
  More = Adjusted,
  append(Adjusted,[Res],Args),!,
  efbug(show_call,catch_warn(apply(Pred,Args))),
  check_returnval(Expander,RetType,Res).

:- if( \+  current_predicate( check_returnval / 3 )).
check_returnval(_,_RetType,_TF).
:- endif.

:- if( \+  current_predicate( adjust_args / 5 )).
adjust_args(_Depth,_Self,_V,VI,VI).
:- endif.

eval_80(Expander,RetType,Depth,Self,PredDecl,Res):-
    eval_67(Expander,RetType,Depth,Self,PredDecl,Res).



last_element(T,E):- \+ compound(T),!,E=T.
last_element(T,E):- is_list(T),last(T,L),last_element(L,E),!.
last_element(T,E):- compound_name_arguments(T,_,List),last_element(List,E),!.




catch_warn(G):- quietly(catch(G,E,(wdmsg(catch_warn(G)-->E),fail))).
catch_nowarn(G):- quietly(catch(G,error(_,_),fail)).


as_tf(G,TF):-  G\=[_|_], catch_nowarn((call(G)*->TF='True';TF='False')).
%eval_selfless(['==',X,Y],TF):- as_tf(X=:=Y,TF),!.
%eval_selfless(['==',X,Y],TF):- as_tf(X=@=Y,TF),!.
%eval_selfless(['=',X,Y],TF):-!, as_tf(X #= Y,TF).
eval_selfless(['>',X,Y],TF):-!,as_tf(X>Y,TF).
eval_selfless(['<',X,Y],TF):-!,as_tf(X<Y,TF).
eval_selfless(['=>',X,Y],TF):-!,as_tf(X>=Y,TF).
eval_selfless(['<=',X,Y],TF):-!,as_tf(X=<Y,TF).
eval_selfless(['%',X,Y],TF):-!,eval_selfless(['mod',X,Y],TF).

eval_selfless(LIS,Y):-  mnotrace((
   LIS=[F,_,_], atom(F), catch_warn(current_op(_,yfx,F)),
   catch((LIS\=[_], s2p(LIS,IS), Y is IS),_,fail))),!.

% less Macro-ey Functions





%eval_40(Expander,RetType,Depth,Self,PredDecl,Res):- eval_6(Depth,Self,PredDecl,Res).

%eval_40(Expander,RetType,_Dpth,_Slf,L1,Res):- is_list(L1),maplist(self_eval,L1),!,Res=L1.
%eval_40(Expander,RetType,_Depth,_Self,X,X).
/*

is_user_defined_head(Other,H):- mnotrace(is_user_defined_head0(Other,H)).
is_user_defined_head0(Other,[H|_]):- !, nonvar(H),!, is_user_defined_head_f(Other,H).
is_user_defined_head0(Other,H):- callable(H),!,functor(H,F,_), is_user_defined_head_f(Other,F).
is_user_defined_head0(Other,H):- is_user_defined_head_f(Other,H).

is_user_defined_head_f(Other,H):- is_user_defined_head_f1(Other,H).
is_user_defined_head_f(Other,H):- is_user_defined_head_f1(Other,[H|_]).

%is_user_defined_head_f1(Other,H):- metta_type(Other,H,_).
is_user_defined_head_f1(Other,H):- metta_atom(Other,[H|_]).
is_user_defined_head_f1(Other,H):- metta_defn(Other,[H|_],_).
%is_user_defined_head_f(_,H):- is_metta_builtin(H).


is_special_op(F):- \+ atom(F), \+ var(F), !, fail.
is_special_op('case').
is_special_op(':').
is_special_op('=').
is_special_op('->').
is_special_op('let').
is_special_op('let*').
is_special_op('if').
is_special_op('rtrace').
is_special_op('or').
is_special_op('and').
is_special_op('not').
is_special_op('match').
is_special_op('call').
is_special_op('let').
is_special_op('let*').
is_special_op('nop').
is_special_op('assertEqual').
is_special_op('assertEqualToResult').

is_metta_builtin(Special):- is_special_op(Special).
is_metta_builtin('==').
is_metta_builtin(F):- once(atom(F);var(F)), current_op(_,yfx,F).
is_metta_builtin('println!').
is_metta_builtin('transfer!').
is_metta_builtin('collapse').
is_metta_builtin('superpose').
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

*/
% =================================================================
% =================================================================
% =================================================================
%  USER DEFINED FUNCTIONS
% =================================================================
% =================================================================
% =================================================================

eval_60(Expander,RetType,Depth,Self,H,B):-
   (eval_64(Expander,RetType,Depth,Self,H,B)*->true;eval_67(Expander,RetType,Depth,Self,H,B)).

eval_64(Expander,_RetType,_Dpth,Self,H,B):-  Expander='=',!, metta_defn(Self,H,B).
eval_64(Expander,_RetType,_Dpth,Self,H,B):-  Expander='match', dcall(metta_atom(Self,H)),B=H.

% Has argument that is headed by the same function
eval_67(Expander,RetType,Depth,Self,[H1|Args],Res):-
   mnotrace((append(Left,[[H2|H2Args]|Rest],Args), H2==H1)),!,
   eval(Expander,RetType,Depth,Self,[H2|H2Args],ArgRes),
   mnotrace((ArgRes\==[H2|H2Args], append(Left,[ArgRes|Rest],NewArgs))),
   eval_60(Expander,RetType,Depth,Self,[H1|NewArgs],Res).

eval_67(Expander,RetType,Depth,Self,[[H|Start]|T1],Y):-
   mnotrace((is_user_defined_head_f(Self,H),is_list(Start))),
   metta_defn(Self,[H|Start],Left),
   eval(Expander,RetType,Depth,Self,[Left|T1],Y).

% Has subterm to eval
eval_67(Expander,RetType,Depth,Self,[F|PredDecl],Res):-
   Depth>1,
   quietly(sub_sterm1(SSub,PredDecl)),
   mnotrace((ground(SSub),SSub=[_|Sub], is_list(Sub),maplist(atomic,SSub))),
   eval(Expander,RetType,Depth,Self,SSub,Repl),
   mnotrace((SSub\=Repl,subst(PredDecl,SSub,Repl,Temp))),
   eval_60(Expander,RetType,Depth,Self,[F|Temp],Res).

%eval_67(Expander,RetType,Depth,Self,X,Y):- (eval_68(Expander,RetType,Depth,Self,X,Y)*->true;metta_atom_iter(Depth,Self,[=,X,Y])).
/*
eval_67_fail(Depth,Self,PredDecl,Res):- fail,
 ((term_variables(PredDecl,Vars),
  (metta_atom(Self,PredDecl) *-> (Vars ==[]->Res='True';Vars=Res);
   (eval(Expander,RetType,Depth,Self,PredDecl,Res),ignore(Vars ==[]->Res='True';Vars=Res))))),
 PredDecl\=@=Res.
*/

%eval_68(Expander,RetType,_Dpth,Self,[H|_],_):- mnotrace( \+ is_user_defined_head_f(Self,H) ), !,fail.
%eval_68(Expander,RetType,_Dpth,Self,[H|T1],Y):- metta_defn(Self,[H|T1],Y).
%eval_68(Expander,RetType,_Dpth,Self,[H|T1],'True'):- metta_atom(Self,[H|T1]).
%eval_68(Expander,RetType,_Dpth,Self,CALL,Y):- fail,append(Left,[Y],CALL),metta_defn(Self,Left,Y).


%eval_6(Depth,Self,['ift',CR,Then],RO):- fail, !, %fail, % trace,
%   metta_defn(Self,['ift',R,Then],Become),eval(Expander,RetType,Depth,Self,CR,R),eval(Expander,RetType,Depth,Self,Then,_True),eval(Expander,RetType,Depth,Self,Become,RO).


%not_compound(Term):- \+ is_list(Term),!.
%eval_40(Expander,RetType,Depth,Self,Term,Res):- maplist(not_compound,Term),!,eval_645(Depth,Self,Term,Res).


% function inherited by system
/*
eval_80(Expander,RetType,Depth,Self,[F|X],FY):- is_function(F),  \+ is_special_op(F), is_list(X),
  maplist(eval(Expander,ArgTypes,Depth,Self),X,Y),!,
  eval_85(Depth,Self,[F|Y],FY).

eval_80(Expander,RetType,Depth,Self,FX,FY):- eval_85(Depth,Self,FX,FY).

eval_85(Depth,Self,[AE|More],TF):- length(More,Len),
  (is_syspred(AE,Len,Pred),catch_warn(as_tf(apply(Pred,More),TF)))*->true;eval_86(Depth,Self,[AE|More],TF).
eval_86(_Dpth,_Slf,[AE|More],TF):- length([AE|More],Len), is_syspred(AE,Len,Pred),append(More,[TF],Args),!,catch_warn(apply(Pred,Args)).
*/
%eval_80(Expander,RetType,Depth,Self,[X1|[F2|X2]],[Y1|Y2]):- is_function(F2),!,eval(Expander,RetType,Depth,Self,[F2|X2],Y2),eval(Expander,RetType,Depth,Self,X1,Y1).


% =================================================================
% =================================================================
% =================================================================
%  AGREGATES
% =================================================================
% =================================================================
% =================================================================

cwdl(DL,Goal):- call_with_depth_limit(Goal,DL,R), (R==depth_limit_exceeded->(!,fail);true).

%bagof_eval(Expander,RetType,Depth,Self,X,L):- bagof_eval(Expander,RetType,_RT,Depth,Self,X,L).


%bagof_eval(Expander,RetType,Depth,Self,X,S):- bagof(E,eval_ne(Expander,RetType,Depth,Self,X,E),S)*->true;S=[].
bagof_eval(_Expander,_RetType,_Dpth,_Slf,X,L):- typed_list(X,_Type,L),!.
bagof_eval(Expander,RetType,Depth,Self,X,L):-
   findall(E,eval_ne(Expander,RetType,Depth,Self,X,E),L).

setof_eval(Depth,Self,X,L):- setof_eval('=',_RT,Depth,Self,X,L).
setof_eval(Expander,RetType,Depth,Self,X,S):- bagof_eval(Expander,RetType,Depth,Self,X,L),
   sort(L,S).


eval_ne(Expander,RetType,Depth,Self,X,E):-
  eval(Expander,RetType,Depth,Self,X,E), \+ var(E), \+ is_empty(E).








