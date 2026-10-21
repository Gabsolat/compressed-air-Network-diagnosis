% =====================================================================
% evaluate.pl -- Tests A-H, metrics, ablation, sensitivity
% case(Id, Group, Split, TrueFaults, Severity, Provenance, Obs, ExpectedFamilies)
% =====================================================================
:- use_module(library(aggregate)).
:- use_module(library(random)).
:- dynamic case/8.

classes([fn,fl,fc,ff,fd,fr,ft,fv,fs,fp]).

eval_one(case(Id, Group, _, True, _, _, Obs, Exp), r(Id, Group, True, Pred, Ms, Compl, PlanOK)) :-
    get_time(T0),
    (  diagnose(Obs, result(Pred, Info)) -> true ; Pred = [undetermined], Info = none ),
    get_time(T1),
    Ms is (T1 - T0)*1000.0,
    (  Info == none -> Compl = false, PlanOK = false
    ;  explain(Pred, Info, Expl), explanation_complete(Pred, Expl, Compl),
       plan_faults(Pred, PF), plan(PF, Items), plan_valid(Exp, Items, PlanOK) ).
plan_faults(Pred, PF) :- subtract(Pred, [fn, undetermined], PF).

run_cases(Split, Results) :-
    findall(R, ( case(Id, G, Sp, T, S, P, O, E), Sp == Split,
                 eval_one(case(Id, G, Sp, T, S, P, O, E), R) ), Results).
run_cases_obs(Split, Pert, Results) :-       % with perturbed observations
    findall(R, ( case(Id, G, Sp, T, S, P, O0, E), Sp == Split,
                 call(Pert, O0, O),
                 eval_one(case(Id, G, Sp, T, S, P, O, E), R) ), Results).

% ----- metrics (eq.17-21, 55-58); multi-fault cases scored one-vs-rest per class -----
cls_counts(Rs, C, TP, FP, FN) :-
    aggregate_all(count, (member(r(_,_,T,P,_,_,_), Rs), memberchk(C,T), memberchk(C,P)), TP),
    aggregate_all(count, (member(r(_,_,T,P,_,_,_), Rs), \+ memberchk(C,T), memberchk(C,P)), FP),
    aggregate_all(count, (member(r(_,_,T,P,_,_,_), Rs), memberchk(C,T), \+ memberchk(C,P)), FN).

safe_div(A, B, R) :- Av is A, Bv is B, ( Bv =:= 0 -> R = 0.0 ; R is Av/Bv ).
f1(P, R, F) :- S is P+R, ( S =:= 0 -> F = 0.0 ; F is 2*P*R/S ).

micro(Rs, Acc, P, R, F1v) :-
    classes(Cs), length(Rs, N), length(Cs, K),
    findall(a(TP,FP,FN), (member(C,Cs), cls_counts(Rs,C,TP,FP,FN)), L),
    sum_counts(L, 0, 0, 0, TP, FP, FN),
    TN is N*K - TP - FP - FN,
    safe_div(TP+TN, TP+TN+FP+FN, Acc),
    safe_div(TP, TP+FP, P), safe_div(TP, TP+FN, R), f1(P, R, F1v).

sum_counts([], A, B, C, A, B, C).
sum_counts([a(X,Y,Z)|T], A0, B0, C0, A, B, C) :-
    A1 is A0+X, B1 is B0+Y, C1 is C0+Z, sum_counts(T, A1, B1, C1, A, B, C).

exact_acc(Rs, Acc) :-
    length(Rs, N),
    aggregate_all(count, (member(r(_,_,T,P,_,_,_), Rs), msort(T,S), msort(P,S)), K),
    safe_div(K, N, Acc).
coverage(Rs, Cd, Cc) :-
    length(Rs, N),
    aggregate_all(count, (member(r(_,_,_,P,_,_,_), Rs), P \== [undetermined]), Nd),
    aggregate_all(count, (member(r(_,_,T,P,_,_,_), Rs), msort(T,S), msort(P,S)), Nc),
    safe_div(Nd, N, Cd), safe_div(Nc, N, Cc).
times(Rs, Mean, Max) :-
    findall(M, member(r(_,_,_,_,M,_,_), Rs), Ms),
    (  Ms == [] -> Mean = 0.0, Max = 0.0 ; sum_list(Ms,S), length(Ms,L), Mean is S/L, max_list(Ms,Max) ).
explain_plan_rates(Rs, ExR, PlR) :-
    aggregate_all(count, (member(r(_,_,_,P,_,_,_), Rs), P \== [undetermined]), Nd),
    aggregate_all(count, (member(r(_,_,_,P,_,true,_), Rs), P \== [undetermined]), Ne),
    aggregate_all(count, (member(r(_,_,_,P,_,_,true), Rs), P \== [undetermined]), Np),
    safe_div(Ne, Nd, ExR), safe_div(Np, Nd, PlR).

report(Title, Rs) :-
    length(Rs, N), micro(Rs, Acc, P, R, F), exact_acc(Rs, EAcc), coverage(Rs, Cd, Cc),
    times(Rs, Mean, Max), explain_plan_rates(Rs, ExR, PlR),
    format("~n=== ~w (N=~d) ===~n", [Title, N]),
    format("Accuracy (exact set match)      : ~4f~n", [EAcc]),
    format("Accuracy (label-level, micro)   : ~4f~n", [Acc]),
    format("Precision / Recall / F1 (micro) : ~4f / ~4f / ~4f~n", [P, R, F]),
    format("Coverage (diagnosed / correct)  : ~4f / ~4f~n", [Cd, Cc]),
    format("Reasoning time mean / max (ms)  : ~4f / ~4f~n", [Mean, Max]),
    format("ExplainabilityRate / PlanValidity: ~4f / ~4f~n", [ExR, PlR]).

class_table(Rs) :-
    classes(Cs),
    format("~nPer-class (one-vs-rest)~n~w~t~8|~w~t~14|~w~t~20|~w~t~26|~w~t~34|~w~t~42|~w~n",
           [class, 'TP', 'FP', 'FN', 'Prec', 'Rec', 'F1']),
    forall(member(C, Cs),
       ( cls_counts(Rs, C, TP, FP, FN), safe_div(TP, TP+FP, P), safe_div(TP, TP+FN, R), f1(P, R, F),
         format("~w~t~8|~d~t~14|~d~t~20|~d~t~26|~3f~t~34|~3f~t~42|~3f~n", [C, TP, FP, FN, P, R, F]) )).

pred_label(Pred, L) :- ( Pred = [One] -> L = One ; L = multi ).
confusion(Rs) :-
    Cols = [fn,fl,fc,ff,fd,fr,ft,fv,fs,fp,undetermined,multi],
    format("~nConfusion matrix (single-label cases; rows=true, cols=predicted)~n~w", ['       ']),
    forall(member(C, Cols), format("~w~t~7+", [C])), nl,
    classes(Cs),
    forall(member(T, Cs),
       ( aggregate_all(count, (member(r(_,_,[T],_,_,_,_), Rs)), Tot),
         (  Tot =:= 0 -> true
         ;  format("~w~t~7|", [T]),
            forall(member(C, Cols),
               ( aggregate_all(count, (member(r(_,_,[T],P,_,_,_), Rs), pred_label(P, C)), K),
                 format("~d~t~7+", [K]) )), nl ) )).

group_table(Rs) :-
    setof(G, I^T^P^M^Cm^Pl^member(r(I,G,T,P,M,Cm,Pl), Rs), Gs),
    format("~nBy test group (exact set match)~n", []),
    forall(member(G, Gs),
       ( findall(R, (member(R, Rs), R = r(_,G,_,_,_,_,_)), Sub),
         length(Sub, N), exact_acc(Sub, A),
         format("  ~w~t~16|N=~d~t~24|acc=~3f~n", [G, N, A]) )).

evaluate(Split) :-
    full_modes(M), set_modes(M),
    run_cases(Split, Rs),
    report(full_system(Split), Rs), class_table(Rs), confusion(Rs), group_table(Rs).

% ----- ablation: reasoning components removed one at a time -----
ablation_configs([
    deductive_only-[deductive],
    ded_abd-[deductive,abductive,propagation],
    ded_cons-[deductive,consistency,propagation],
    full-[deductive,abductive,consistency,propagation],
    full_no_propagation-[deductive,abductive,consistency]
  ]).
ablation(Split) :-
    ablation_configs(Cs),
    format("~nABLATION on split=~w~n~w~t~24|~w~t~34|~w~t~44|~w~t~54|~w~t~64|~w~n",
           [Split, config, acc, microP, microR, microF1, 'multi acc / imperfect acc']),
    forall(member(Name-Modes, Cs),
       ( set_modes(Modes), run_cases(Split, Rs),
         micro(Rs, _, P, R, F), exact_acc(Rs, A),
         subset_acc(Rs, [f_multi], AM),
         subset_acc(Rs, [g_incomplete,g_noisy,g_conflict,g_borderline], AI),
         format("~w~t~24|~3f~t~34|~3f~t~44|~3f~t~54|~3f~t~64|~3f / ~3f~n", [Name, A, P, R, F, AM, AI]) )),
    full_modes(M), set_modes(M).
subset_acc(Rs, Gs, Acc) :-
    findall(R, (member(R, Rs), R = r(_,G,_,_,_,_,_), memberchk(G, Gs)), Sub),
    (  Sub == [] -> Acc = 0.0 ; exact_acc(Sub, Acc) ).

% ----- sensitivity: thresholds, missing observations, noise -----
sensitivity(Split) :-
    full_modes(M), set_modes(M),
    format("~nSENSITIVITY: threshold scale~n", []),
    forall(member(S, [0.8, 0.9, 1.0, 1.1, 1.2]),
       ( retractall(threshold_scale(_)), assertz(threshold_scale(S)),
         run_cases(Split, Rs), micro(Rs, _, _, _, F), exact_acc(Rs, A),
         format("  scale=~2f  acc=~3f  microF1=~3f~n", [S, A, F]) )),
    retractall(threshold_scale(_)), assertz(threshold_scale(1.0)),
    format("~nSENSITIVITY: random missing observations~n", []),
    forall(member(D, [0.0, 0.1, 0.2, 0.3]),
       ( set_random(seed(42)), run_cases_obs(Split, perturb(D, 0.0), Rs),
         micro(Rs, _, _, _, F), exact_acc(Rs, A), coverage(Rs, Cd, _),
         format("  drop=~2f  acc=~3f  microF1=~3f  coverage=~3f~n", [D, A, F, Cd]) )),
    format("~nSENSITIVITY: multiplicative uniform noise (+/- fraction)~n", []),
    forall(member(Nz, [0.0, 0.02, 0.05, 0.10]),
       ( set_random(seed(42)), run_cases_obs(Split, perturb(0.0, Nz), Rs),
         micro(Rs, _, _, _, F), exact_acc(Rs, A),
         format("  noise=~2f  acc=~3f  microF1=~3f~n", [Nz, A, F]) )).

perturb(_, _, [], []).
perturb(D, Nz, [V=X|T], Out) :-
    perturb(D, Nz, T, O1), random(R1),
    (  R1 < D -> Out = O1
    ;  random(R2), X2 is X*(1 + Nz*(2*R2 - 1)), Out = [V=X2|O1] ).
