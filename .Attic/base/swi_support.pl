

with_cwd(Dir,Goal):- setup_call_cleanup(working_directory(X, Dir), Goal, working_directory(_,X)).

with_option([],G):-!,call(G).
with_option([H|T],G):- !, with_option(H,with_option(T,G)).
with_option(N=V,G):-!,  with_option(N,V,G).
with_option(NV,G):- compound(NV), NV =..[N,V],!,with_option(N,V,G).
with_option(N,G):- with_option(N,true,G).

with_option(N,V,G):-  option_value(N,W),
  setup_call_cleanup(set_option_value(N,V),G, set_option_value(N,W)).


was_option_value(N,V):- nb_current(N,VV), !,V=VV.
was_option_value(N,V):- current_prolog_flag(N,VV),!,V=VV.
was_option_value(N,V):- prolog_load_context(N,VV),!,V=VV.

option_else( N,V,_Else):- was_option_value(N,VV),!,VV=V.
option_else(_N,V, Else):- !,V=Else.
option_value( N,V):- option_else( N,V ,[]).

set_option_value(N,V):-
   catch(nb_setval(N,V),_,true),
   catch(create_prolog_flag(N,V,[keep(false),access(read_write), type(term)]),_,true),
   catch(set_prolog_flag(N,V),_,true).

kaggle_arc:- \+ exists_directory('/opt/logicmoo_workspace/packs_sys/logicmoo_agi/prolog/kaggle_arc/'), !.
%kaggle_arc:- !.
kaggle_arc:-
   with_option(argv,['--libonly'],
     with_cwd('/opt/logicmoo_workspace/packs_sys/logicmoo_agi/prolog/kaggle_arc/',
       ensure_loaded(kaggle_arc))).

%:- ensure_loaded((read_obo2)).

:- kaggle_arc.



:- prolog_load_context(file, File),
    absolute_file_name('../../',Dir,[relative_to(File),file_type(directory)]),
    asserta(ftp_data(Dir)).

:- prolog_load_context(file, File),
    absolute_file_name('./',Dir,[relative_to(File),file_type(directory)]),
    asserta(pyswip_dir(Dir)).


:- if( \+ current_predicate(must_det_ll/1)).
% Calls the given Goal and throws an exception if Goal fails.
% Usage: must_det_ll(+Goal).
must_det_ll(M:Goal) :- !, must_det_ll(M,Goal).
must_det_ll(Goal) :- must_det_ll(user,Goal).

must_det_ll(_M,Goal) :- var(Goal),!,throw(var_must_det_ll(Goal)),!.
must_det_ll(M,Goal) :- var(M),!,strip_module(Goal,M,NewGoal),!,must_det_ll(M,NewGoal).
must_det_ll(M,(GoalA,GoalB)) :- !, must_det_ll(M,GoalA), must_det_ll(M,GoalB).
must_det_ll(M,(GoalA->GoalB;GoalC)) :- !, (call_ll(M,GoalA)-> must_det_ll(M,GoalB) ; must_det_ll(M,GoalC)).
must_det_ll(M,(GoalA*->GoalB;GoalC)) :- !, (call_ll(M,GoalA)*-> must_det_ll(M,GoalB) ; must_det_ll(M,GoalC)).
must_det_ll(M,(GoalA->GoalB)) :- !, (call_ll(M,GoalA)-> must_det_ll(M,GoalB)).
must_det_ll(_,M:Goal) :- !, must_det_ll(M,Goal).
must_det_ll(M,Goal) :-
    % Call Goal, succeed with true if Goal succeeds.
    M:call(Goal) -> true ; % If Goal fails, throw an exception indicating that Goal failed.
      throw(failed(Goal)).

call_ll(_M,Goal):- var(Goal),!,throw(var_call_ll(Goal)),!.
call_ll(M,Goal):- var(M),!,strip_module(Goal,M,NewGoal),!,call_ll(M,NewGoal).
call_ll(M,Goal):- M:call(Goal).
:- endif.


:- if( \+ current_predicate(if_t/2)).
if_t(If,Then):- call(If)->call(Then);true.
:-endif.

:- if( \+ current_predicate(atom_contains/2)).
atom_contains(Atom1, SubAtom) :- sub_atom(Atom1, _Before, _, _After, SubAtom).
:- endif.

:- if( \+ current_predicate(nop/1)).
nop(_).
:- endif.

:- if( \+ current_predicate(catch_ignore/1)).
catch_ignore(G):- ignore(catch(G,E,catch_i((nl,writeq(G=E),nl)))).
:- endif.

:- if( \+ current_predicate(catch_i/1)).
catch_i(G):- ignore(catch(G,_,true)).
:- endif.

