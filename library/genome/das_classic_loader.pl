/*
   (EvaluationLink
    (PredicateNode "has_name")
    (ListLink
        (DiseaseOntologyNode "DOID:0001816")
        (ConceptNode "angiosarcoma")))


                  load_metta('&flybase',File)).
*/
include_atomspace_1_0(RelFilename):-
 absolute_file_name(RelFilename,Filename),
 track_load_into_file(Filename,
 must_det_ll((
  atom(RelFilename),
  current_self(Self),
  exists_file(RelFilename),!,
   must_det_ll((setup_call_cleanup(open(Filename,read,In, [encoding(utf8)]),
    ((directory_file_path(Directory, _, Filename),
      assert(metta_file(Self,Filename,Directory)),
      with_cwd(Directory,
        must_det_ll( load_atomspace_1_0_file_stream(Filename,Self,In))))),close(In))))))).

load_atomspace_1_0_file_stream(Filename,Self,In):-
  once((is_file_stream_and_size(In, Size) , Size>102400) -> P2 = read_sform2 ; P2 = read_metta),!,
  with_option(loading_file,Filename,
   %current_exec_file(Filename),
   ((must_det_ll((
       set_exec_num(Filename,1),
       %load_answer_file(Filename),
       set_exec_num(Filename,0))),
       once((repeat, ((
            current_read_mode(Mode),
            once(call(P2, In,Expr)), %write_src(read_atomspace_1_0=Expr),nl,
            must_det_ll((((do_atomspace_1_0(file(Filename),Mode,Self,Expr,_O)))->true;
                 pp_m(unknown_do_atomspace_1_0(file(Filename),Mode,Self,Expr)))),
           flush_output)),
          at_end_of_stream(In)))))),!.

%  ['InheritanceLink',['DiseaseOntologyNode','DOID:0112326'],['DiseaseOntologyNode','DOID:0050737']]
do_atomspace_1_0(_W,_M,_S,end_of_file,_O):-!.
do_atomspace_1_0(W,M,S,E,_O):-
    rewrite_as10_to_as20(E,E2,Extras),!,
    maplist(do_atomspace_2_0(W,M,S),[E2|Extras]).

do_atomspace_2_0(_W,_M,_S,E):-
    assert_OBO(E),
    !. % writeq(E),!,nl.

rewrite_as10_to_as20(A,A,[]):- \+ is_list(A).
rewrite_as10_to_as20([CN,Arg],Arg,[]):- CN='ConceptNode',!.
rewrite_as10_to_as20([ConceptNode,Arg1],Arg,[is_a(Arg,ConceptNode)|R]):- atom(ConceptNode),atom_concat(_Concept,'Node',ConceptNode),!,
   rewrite_as10_to_as20(Arg1,Arg,R),!.
rewrite_as10_to_as20(['EvaluationLink',['PredicateNode',Pred],['ListLink'|Args]], Res,
  [arity(Pred,Len),is_a(Pred,'Predicate')|ExtrasF]):-
   length(Args,Len),maplist(rewrite_as10_to_as20,Args,ArgsL,Extras), flatten(Extras,ExtrasF),
   Res =..  [Pred|ArgsL].


rewrite_as10_to_as20([InheritanceLink|Args],[Inheritance|ArgsL],ExtrasF):-
    atom(InheritanceLink),atom_concat(Inheritance,'Link',InheritanceLink),
    maplist(rewrite_as10_to_as20,Args,ArgsL,Extras), flatten(Extras,ExtrasF),!.

rewrite_as10_to_as20(A,A,[]).

