% =====================================================================
% conditions.pl -- symbolic conditions derived from numeric evidence.
% holds(C) is false when evidence is missing ("unknown" is never true).
% =====================================================================
holds(leak_fraction_high) :- leak_fraction(L), thr(leak_frac_high, T), L > T.
holds(leak_fraction_ok)   :- leak_fraction(L), thr(leak_frac_high, T), L =< T.
holds(leak_fraction_unobserved) :- \+ leak_fraction(_).
holds(ultrasonic_high) :- val(l_a, A), thr(ultrasonic_high_db, T), A > T.
holds(ultrasonic_ok)   :- val(l_a, A), thr(ultrasonic_high_db, T), A =< T.
holds(ultrasonic_unobserved) :- \+ val(l_a, _).
% apparent leakage with no ultrasonic or cycling corroboration -> flow meter suspect
holds(leak_unsupported) :-
    obs(m_in, Mi), obs(m_use, Mu), Mi > 0, L is (Mi-Mu)/Mi,
    thr(leak_frac_high, T), L > T,
    obs(l_a, A), thr(ultrasonic_high_db, U), A =< U,
    \+ holds(cycling_high).

holds(capacity_deficit) :- cap_deficit(D), thr(capacity_deficit, T), D > T.
holds(capacity_ok)      :- cap_deficit(D), thr(capacity_deficit, T), D =< T.
holds(spec_power_high)  :- spec_power_ratio(R), thr(spec_power_ratio_high, T), R > T.
holds(disch_temp_high)  :- t_rise(D), thr(disch_temp_rise_high, T), D > T.
holds(vibration_high)   :- val(v_rms, V), thr(vib_high_mm_s, T), V > T.

holds(cycling_high) :- val(cyc, C), ref(cycles, R), thr(cycle_ratio_high, T), C > R*T.
holds(cycling_ok)   :- val(cyc, C), ref(cycles, R), thr(cycle_ratio_high, T), C =< R*T.
holds(drain_low)    :- val(c_water, W), ref(drain, R), thr(drain_ratio_low, T), W < R*T.
holds(drain_ok)     :- val(c_water, W), ref(drain, R), thr(drain_ratio_low, T), W >= R*T.

holds(filter_dp_high)   :- dp_ratio(filter, R), thr(filter_ratio_high, T), R > T.
holds(filter_ok)        :- dp_ratio(filter, R), thr(filter_ratio_high, T), R =< T.
holds(dryer_dp_high)    :- dp_ratio(dryer, R), thr(dryer_dp_ratio_high, T), R > T.
holds(dryer_dp_ok)      :- dp_ratio(dryer, R), thr(dryer_dp_ratio_high, T), R =< T.
holds(dewpoint_high)    :- dew_dev(D), thr(dewpoint_dev_high, T), D > T.
holds(dewpoint_ok)      :- dew_dev(D), thr(dewpoint_dev_high, T), D =< T.
holds(header_dp_high)   :- dp_ratio(header, R), header_dp(D),
    thr(header_ratio_high, T), thr(header_excess_bar, E), R > T, D > E.
holds(header_ok)        :- dp_ratio(header, R), header_dp(D),
    thr(header_ratio_high, T), thr(header_excess_bar, E), ( R =< T ; D =< E ), !.

holds(p_use_low) :- val(p_set, S), val(p_use, U), thr(p_use_low_bar, T), S - U > T.
holds(p_rec_low) :- rec_best(P), ref(p_rec, R), thr(p_rec_low_bar, T), R - P > T.
holds(supply_ok) :- val(p_hdr, H), val(p_set, S), thr(supply_margin_bar, M), H >= S + M.
holds(reg_under) :- holds(p_use_low), holds(supply_ok).
holds(reg_over)  :- val(p_set, S), val(p_use, U), thr(reg_error_bar, T), U - S > T.
holds(reg_error) :- ( holds(reg_under) ; holds(reg_over) ), !.
holds(reg_ok)    :- val(p_set, S), val(p_use, U), thr(reg_error_bar, T), abs(S - U) =< T.
holds(reg_not_implicated) :- holds(reg_ok), !.
holds(reg_not_implicated) :- holds(p_use_low), val(p_hdr, _), \+ holds(supply_ok), !.

holds(prec_disagree) :- obs(p_rec, A), obs(p_rec_b, B), thr(redundancy_tol_bar, T), abs(A - B) > T.
holds(prec_out_of_range) :- ( suspect(p_rec) ; suspect(p_rec_b) ), !.
holds(sensors_checked_ok) :- obs(p_rec, _), obs(p_rec_b, _),
    \+ holds(prec_disagree), \+ holds(prec_out_of_range), \+ holds(leak_unsupported).

all_hold([]).
all_hold([C|T]) :- holds(C), all_hold(T).
