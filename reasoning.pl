% =====================================================================
% reasoning.pl -- deductive, abductive and consistency-based diagnosis
% Modes (ablation switches): deductive, abductive, consistency, propagation
% =====================================================================
:- use_module(library(lists)).
:- use_module(library(apply)).
:- dynamic mode_flag/1.

set_modes(Ms) :- retractall(mode_flag(_)), forall(member(M, Ms), assertz(mode_flag(M))).
full_modes([deductive, abductive, consistency, propagation]).
:- full_modes(M), set_modes(M).

load_case(Obs) :-
    retractall(obs(_,_)), retractall(suspect(_)),
    forall(member(V=X, Obs), assertz(obs(V,X))),
    findall(S, suspect_sensor(S), Ss0), sort(Ss0, Ss),
    forall(member(S, Ss), assertz(suspect(S))).

observed_symptoms(O) :-
    findall(S, (symptom(S), once(holds(S))), O0), sort(O0, O).

% ---------- deductive ----------
deductive(Faults, Fired) :-
    findall(F-R, (rule(R, F, Conds, _), once(all_hold(Conds))), Fired),
    findall(F, member(F-_, Fired), Fs0), sort(Fs0, Faults).

% ---------- propagation / explanation relation ----------
reaches(S, S).
reaches(A, B) :- mode_flag(propagation), prop(A, M), reaches(M, B).

explains_obs(F, S) :- direct(F, S0), once(holds(S0)), reaches(S0, S).   % evidence-supported
can_cause(F, S)    :- direct(F, S0), reaches(S0, S).                    % causal capability

explained(Faults, S) :- member(F, Faults), explains_obs(F, S), !.
residual(Faults, Res) :-
    observed_symptoms(O),
    findall(S, (member(S, O), \+ explained(Faults, S)), Res).

% ---------- combinatorics ----------
comb(0, _, []).
comb(N, [X|T], [X|C]) :- N > 0, N1 is N-1, comb(N1, T, C).
comb(N, [_|T], C)     :- N > 0, comb(N, T, C).

minimal_sets(Sets, Mins) :-
    findall(S, (member(S, Sets), \+ (member(T, Sets), T \== S, subset(T, S))), Mins).
min_card(Sets, Best) :-
    findall(L, (member(S, Sets), length(S, L)), Ls), min_list(Ls, Min),
    findall(S, (member(S, Sets), length(S, Min)), Best).
unique_best(Sets, Add) :-
    (  Sets == [] -> Add = []
    ;  minimal_sets(Sets, Mins), min_card(Mins, Best),
       ( Best = [One] -> Add = One ; Add = [] ) ).

% ---------- consistency-based (Reiter): conflicts and hitting sets ----------
exonerated(F) :- exonerated_by(F, Cs), Cs \== [], all_hold(Cs), !.

conflict(S, Set) :-
    findall(F, (candidate(F), can_cause(F, S), \+ exonerated(F)), Set0), sort(Set0, Set).

hits(H, Conflicts) :- forall(member(C, Conflicts), (member(F, H), memberchk(F, C))).

hitting_best(Conflicts, Add) :-
    findall(F, (member(C, Conflicts), member(F, C)), Fs0), sort(Fs0, Cs),
    findall(H, (between(1, 3, N), comb(N, Cs, H), hits(H, Conflicts)), Hs),
    unique_best(Hs, Add).

cons_add(Ded, Add) :-
    observed_symptoms(O),
    findall(Set, (member(S, O), conflict(S, Set), Set \== [],
                  \+ (member(F, Ded), memberchk(F, Set))), Conflicts),
    (  Conflicts == [] -> Add = [] ; hitting_best(Conflicts, Add) ).

contradictions(L) :-
    observed_symptoms(O),
    findall(S, (member(S, O), conflict(S, [])), L).

% ---------- abductive: KB u H |= O, minimum-cardinality covers (eq.47,49) ----------
abd_candidates(Cs) :-
    findall(F, (candidate(F), \+ (mode_flag(consistency), exonerated(F))), Cs).
covers(H, Res) :- forall(member(S, Res), (member(F, H), explains_obs(F, S))).
abd_add(Res, Add) :-
    abd_candidates(Cs),
    findall(H, (between(1, 3, N), comb(N, Cs, H), covers(H, Res)), Covers),
    unique_best(Covers, Add).

% ---------- integration ----------
augment(Ded, Res, Add, Method) :-
    (  mode_flag(abductive)   -> abd_add(Res, AddA) ; AddA = none ),
    (  mode_flag(consistency) -> cons_add(Ded, AddC) ; AddC = none ),
    choose_add(AddA, AddC, Add, Method).
choose_add(A, _, A, abductive)   :- A \== none, A \== [], !.
choose_add(_, C, C, consistency) :- C \== none, C \== [], !.
choose_add(_, _, [], none).

aug_active :- ( mode_flag(abductive) ; mode_flag(consistency) ), !.
pressure_unexplained(L) :- ( memberchk(p_use_low, L) ; memberchk(p_rec_low, L) ), !.

fallback([], O, _, Faults) :- !,
    (  O == [] -> Faults = [fn]
    ;  pressure_unexplained(O) -> Faults = [fp]
    ;  Faults = [undetermined] ).
fallback(F1, _, Res1, Faults) :-
    (  aug_active, pressure_unexplained(Res1), \+ memberchk(fp, F1)
    -> append(F1, [fp], F2), sort(F2, Faults)
    ;  Faults = F1 ).

diagnose(Obs, result(Faults, Info)) :-
    load_case(Obs),
    observed_symptoms(O),
    deductive(Ded, Fired),
    residual(Ded, Res0),
    (  Res0 == [] -> Add = [], Method = none
    ;  augment(Ded, Res0, Add, Method) ),
    union(Ded, Add, F1a), sort(F1a, F1),
    residual(F1, Res1),
    fallback(F1, O, Res1, Faults),
    Info = info(O, Fired, Res0, Add, Method, Res1).
