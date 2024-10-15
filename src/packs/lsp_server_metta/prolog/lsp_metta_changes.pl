:- module(lsp_metta_changes, [handle_doc_changes/2,
                      doc_text_fallback/2,
                       doc_text/2]).
:- use_module(lsp_metta_split, [
    split_text_document/2,
    split_document_get_multiple_sections/7,
    coalesce_text/2
]).

/** <module> LSP changes
 Module for tracking edits to the source, in order to be able to act on
 the code as it is in the editor buffer, before saving.

 @author James Cash
*/

:- use_module(library(readutil), [read_file_to_codes/3]).
:- use_module(lsp_metta_utils).

:- dynamic doc_text/2.

%! handle_doc_changes(+File:atom, +Changes:list) is det.
%
%  Track =Changes= to the file =File=.

handle_doc_changes(_, []) :- !.
handle_doc_changes(Path, [Change|Changes]) :-
    handle_doc_change(Path, Change),
    handle_doc_changes(Path, Changes).

handle_doc_change(Path, Change) :-
    _{range: _{start: _{line: StartLine, character: StartChar},
               end:   _{line: EndLine,   character: _EndChar}},
      rangeLength: ReplaceLen, text: Text} :< Change,
    !,
    atom_codes(Text, ChangeCodes),
    doc_text_fallback(Path, OrigDocument),
    split_document_get_multiple_sections(StartLine,EndLine,NewStartLine,OrigDocument,Pre,This,Post),
    %debug(server,"0:~w ~w ~w ~w ~w",[NewStartLine,EndLine,StartChar,ReplaceLen,This]),
    coalesce_text(This,TextBlock),
    %debug(server,"1:~w",[TextBlock]),
    string_codes(TextBlock,OrigCodes),
    %debug(server,"2:~w",[OrigCodes]),
    replace_codes(OrigCodes, NewStartLine, StartChar, ReplaceLen, ChangeCodes,
                  NewCodes),
    %debug(server,"3:~w",[NewCodes]),
    string_codes(NewText,NewCodes),
    %debug(server,"4:~w",[NewText]),
    split_text_document(NewText,NewSplitText),
    %debug(server,"5:~w",[NewSplitText]),
    append([Pre,NewSplitText,Post],NewDocument),
    retractall(doc_text(Path, _)),
    assertz(doc_text(Path, NewDocument)).
handle_doc_change(Path, Change) :-
    retractall(doc_text(Path, _)),
    atom_codes(Change.text, TextCodes),
    assertz(doc_text(Path, TextCodes)).

%! doc_text_fallback(+Path:atom, -Text:text) is det.
%
%  Get the contents of the file at =Path=, either with the edits we've
%  been tracking in memory, or from the file on disc if no edits have
%  occured.
doc_text_fallback(Path, Text) :-
    doc_text(Path, Text), !.
doc_text_fallback(Path, Text) :-
    read_file_to_string(Path, Text, []),
    split_text_document(Text,SplitText),
    assertz(doc_text(Path, SplitText)).

%! replace_codes(Text, StartLine, StartChar, ReplaceLen, ReplaceText, -NewText) is det.
replace_codes(Text, StartLine, StartChar, ReplaceLen, ReplaceText, NewText) :-
    phrase(replace(StartLine, StartChar, ReplaceLen, ReplaceText),
           Text,
           NewText).
    %debug(server,"replace_codes ~w ~w ~w ~w ~w ~w", [Text, StartLine, StartChar, ReplaceLen, ReplaceText, NewText]).

replace(0, 0, 0, NewText), NewText --> !, [].
replace(0, 0, Skip, NewText) -->
    !, skip(Skip),
    replace(0, 0, 0, NewText).
replace(0, Chars, Skip, NewText), [C] --> {C#<128, succ(Chars0,Chars)}, [C], !, replace(0, Chars0, Skip, NewText).
replace(0, Chars, Skip, NewText), [C,B0] --> {C#>=128, C#<224, succ(Chars0,Chars)}, [C,B0], !, replace(0, Chars0, Skip, NewText).
replace(0, Chars, Skip, NewText), [C,B0,B1] --> {C#>=224, C#<240, succ(Chars0,Chars)}, [C,B0,B1], !, replace(0, Chars0, Skip, NewText).
replace(0, Chars, Skip, NewText), [C,B0,B1,B2] --> {C#>=240, plus(Chars0,2,Chars)}, [C,B0,B1,B2], !, replace(0, Chars0, Skip, NewText).
replace(Lines1, Chars, Skip, NewText), Line -->
    line(Line), !,
    { succ(Lines0, Lines1) },
    replace(Lines0, Chars, Skip, NewText).

skip(0) --> !.
skip(N) --> [C], { C#<128, succ(N0, N) }, skip(N0).
skip(N) --> [C,_], { C#>=128,C#<224, succ(N0, N) }, skip(N0).
skip(N) --> [C,_,_], { C#>=224,C#<240, succ(N0, N) }, skip(N0).
skip(N) --> [C,_,_,_], { C#>=240, plus(N0, 2, N) }, skip(N0).

line([0'\n]) --> [0'\n], !.
line([C|Cs]) --> [C], line(Cs).
