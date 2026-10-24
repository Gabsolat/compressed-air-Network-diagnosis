% =====================================================================
% explain.pl -- explanation facility and corrective-maintenance planner
% =====================================================================
raw_evidence(F, E) :-
    support(F, L),
    findall(W, (member(C-W, L), once(holds(C))), Ws), sum_list(Ws, E).

explain(Faults, info(_, Fired, _, Add, Method, _), Expl) :-
    all_faults(AF),
    findall(E, (member(F, AF), raw_evidence(F, E)), Es), max_list(Es, Mx),
    findall(Ex, (member(F, Faults), explain_fault(F, Fired, Add, Method, Mx, Ex)), Expl).

explain_fault(fn, _, _, _, _, ex(fn, [], [no_abnormal_symptom_observed], 1.0, 1.0, 1.0, [])) :- !.
explain_fault(undetermined, _, _, _, _,
              ex(undetermined, O, [no_unique_minimal_explanation], 0.0, 0.0, 0.0, [])) :- !,
    observed_symptoms(O).
explain_fault(F, Fired, Add, Method, Mx, ex(F, Evid, Basis, Eb, Cr, CD, Contra)) :-
    support(F, L),
    findall(C, (member(C-_, L), once(holds(C))), Evid),
    findall(R, member(F-R, Fired), Rs),
    (  Rs \== [] -> Basis = Rs
    ;  memberchk(F, Add) -> Basis = [Method]
    ;  Basis = [residual_pressure_fallback] ),
    raw_evidence(F, E), Eb is E/(Mx + 0.001),                       % eq.43
    length(Evid, NS),
    (  exonerated_by(F, Cs) -> findall(C, (member(C, Cs), once(holds(C))), Contra) ; Contra = [] ),
    length(Contra, NC),
    Cr is NS/(NS + NC + 0.001),                                      % eq.44
    CD is 0.6*Eb + 0.4*Cr.                                           % eq.45 (evidence score, NOT a probability)

competing(Faults, Comp) :-
    all_faults(AF),
    findall(F-Reason,
        ( member(F, AF), \+ memberchk(F, Faults), raw_evidence(F, E), E > 0,
          ( exonerated(F) -> Reason = exonerated_by_normal_evidence
                           ; Reason = insufficient_evidence ) ), Comp).

explanation_complete(Pred, Expl, true) :-
    forall(member(F, Pred),
           ( member(ex(F, Evid, Basis, _, _, _, _), Expl), Basis \== [],
             ( F == fn ; Evid \== [] ) )), !.
explanation_complete(_, _, false).

indicator(leak_fraction, V)   :- leak_fraction(V).
indicator(capacity_deficit, V):- cap_deficit(V).
indicator(spec_power_ratio, V):- spec_power_ratio(V).
indicator(filter_ratio, V)    :- dp_ratio(filter, V).
indicator(dryer_dp_ratio, V)  :- dp_ratio(dryer, V).
indicator(header_ratio, V)    :- dp_ratio(header, V).
indicator(dewpoint_dev, V)    :- dew_dev(V).

% ---------------- maintenance planner ----------------
% maintenance(Fault, Family, [Actions], Rationale)
maintenance(fl, leak_repair, [run_ultrasonic_leak_survey, tag_and_repair_leaks, recheck_flow_balance],
    'Leakage wastes air and energy; survey locates leaks, repair restores flow balance').
maintenance(fc, compressor_inspection, [inspect_intake_filter_and_valves, check_unloader_and_controls, test_fad_and_power],
    'Capacity/efficiency deficit points to intake restriction, valve wear or control faults').
maintenance(ff, filter_service, [replace_filter_element, record_clean_dp_baseline],
    'Excess filter dP wastes energy and starves downstream demand').
maintenance(fd, dryer_service, [inspect_dryer_cooling_and_refrigeration, check_condensate_drain, clean_or_service_dryer],
    'Dew-point rise or dryer dP rise indicates degraded drying capacity or fouling').
maintenance(fr, receiver_drain_service, [inspect_receiver_drain_valve, drain_receiver, inspect_receiver_internals],
    'Failed drain accumulates condensate, shrinks effective volume and raises cycling').
maintenance(ft, header_inspection, [inspect_header_for_blockage_or_partly_closed_valve, balance_branch_flows, measure_dp_per_segment],
    'Excess header dP after exonerating dryer and filter localises a distribution restriction').
maintenance(fv, regulator_service, [inspect_regulator_and_pilot, recalibrate_setpoint, replace_if_unstable],
    'Regulated pressure deviates from setpoint although supply pressure is adequate').
maintenance(fs, sensor_calibration, [verify_against_reference_gauge, recalibrate_or_replace_sensor],
    'Inconsistent or uncorroborated readings indicate an instrumentation problem, not equipment failure').
maintenance(fp, pressure_profile_check, [measure_pressure_profile_along_network, collect_missing_measurements],
    'Pressure abnormality not isolated to a component with the available data').

priority(fl, P) :- ( leak_fraction(L), L > 0.25 -> P = urgent ; P = high ).
priority(ff, P) :- ( dp_ratio(filter, R), R > 4.0 -> P = urgent ; P = high ).
priority(fc, high).
priority(fd, high).
priority(fr, medium).
priority(ft, high).
priority(fv, high).
priority(fs, medium).
priority(fp, medium).
rank(urgent, 0). rank(high, 1). rank(medium, 2).

plan(Faults, Items) :-
    findall(Rk-item(P, Fam, Acts, Why),
        ( member(F, Faults), maintenance(F, Fam, Acts0, Why), once(priority(F, P)),
          rank(P, Rk), sensor_actions(F, Acts0, Acts) ), Ps0),
    keysort(Ps0, Ps), pairs_values(Ps, Items).
sensor_actions(fs, A0, A) :- !, findall(verify_sensor(S), suspect(S), Ss), append(A0, Ss, A).
sensor_actions(_, A, A).

plan_valid(ExpFams, Items, Valid) :-
    findall(Fam, member(item(_, Fam, _, _), Items), Fs),
    (  ExpFams == [none] -> ( Items == [] -> Valid = true ; Valid = false )
    ;  forall(member(E, ExpFams), memberchk(E, Fs)) -> Valid = true
    ;  Valid = false ).

print_diagnosis(Obs) :-
    diagnose(Obs, result(Faults, Info)),
    Info = info(O, _, Res0, Add, Method, Res1),
    explain(Faults, Info, Expl), competing(Faults, Comp), plan(Faults, Items),
    findall(N=V, (indicator(N, V0), V is round(V0*1000)/1000), Ind),
    format("Observed abnormal symptoms : ~w~n", [O]),
    format("Derived indicators         : ~w~n", [Ind]),
    format("Residual after deduction   : ~w~n", [Res0]),
    format("Added by ~w : ~w ; unexplained afterwards: ~w~n", [Method, Add, Res1]),
    format("DIAGNOSIS                  : ~w~n", [Faults]),
    forall(member(ex(F, Ev, Ba, Eb, Cr, CD, Co), Expl),
        format("  ~w: evidence=~w basis=~w E_norm=~3f Cr=~3f score=~3f contra=~w~n",
               [F, Ev, Ba, Eb, Cr, CD, Co])),
    format("Competing / rejected       : ~w~n", [Comp]),
    next_questions(Faults, Qs),
    forall(member(Need-Whys, Qs), format("ASK FOR ~w (rules ~w)~n", [Need, Whys])),
    forall(member(item(P, Fam, Acts, Why), Items),
        format("PLAN [~w] ~w: ~w~n    why: ~w~n", [P, Fam, Acts, Why])).

% ---------------- consultation: what the system would ask for next ----------------
% A condition is true (holds), unknown (a needed measurement is missing) or false.
cond_status(C, true)    :- once(holds(C)), !.
cond_status(C, unknown) :- missing_for(C, M), M \== [], !.
cond_status(_, false).

missing_for(C, Missing) :-
    (  cond_needs(C, Needs) -> true ; Needs = [] ),
    findall(N, (member(N, Needs), \+ need_met(N)), Missing).
need_met(any(L)) :- !, member(V, L), val(V, _), !.
need_met(V) :- val(V, _).

% a rule is open when no condition is refuted and at least one is still unknown
open_rule(Faults, R-F, Unknown) :-
    rule(R, F, Conds, _), \+ memberchk(F, Faults),
    \+ once(all_hold(Conds)),
    findall(C-S, (member(C, Conds), cond_status(C, S)), St),
    \+ memberchk(_-false, St),
    findall(C, member(C-unknown, St), Unknown), Unknown \== [],
    (  memberchk(_-true, St) -> true ; weak_diagnosis(Faults) ).

weak_diagnosis(Faults) :- subtract(Faults, [fn, fp, undetermined], []).

next_questions(Faults, Qs) :-
    findall(Need-(R-F-C),
            ( open_rule(Faults, R-F, Unknown), member(C, Unknown),
              missing_for(C, Ms), member(Need, Ms) ), Raw),
    keysort(Raw, Sorted), group_pairs_by_key(Sorted, Qs0),
    findall(Need-Why, ( member(Need-W0, Qs0), sort(W0, Why) ), Qs).
