% =====================================================================
% main.pl -- entry point.   swipl -q -g run_all -t halt main.pl
% =====================================================================
:- style_check(-discontiguous).
:- style_check(-singleton).
:- [config, network, calc, conditions, rules, reasoning, explain, evaluate].
:- [data/cases].

% demo(Id): full explanation trace and maintenance plan for one case
demo(Id) :-
    case(Id, G, _, True, Sev, _, Obs, Exp),
    format("CASE ~w group=~w true=~w severity=~w expected=~w~n", [Id, G, True, Sev, Exp]),
    print_diagnosis(Obs).

% query a hand-written observation list, e.g.
% ?- diagnose_obs([p_dis=7.8, p_rec=7.7, ...]).
diagnose_obs(Obs) :- print_diagnosis(Obs).

run_all :-
    evaluate(test), ablation(test), sensitivity(test),
    format("~nDEV split (for debugging / threshold tuning only)~n", []),
    evaluate(dev).
