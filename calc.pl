% =====================================================================
% calc.pl -- observations and engineering calculations
% obs(Var,Value) holds the current case; suspect(Var) marks sensors
% judged unreliable. val/2 never returns a suspect reading.
% =====================================================================
:- dynamic obs/2, suspect/1.

val(V, X) :- obs(V, X), \+ suspect(V).

m_in_est(M) :- val(m_in, M), !.
m_in_est(M) :- val(m_use, U), M is U/0.92.

flow_scale(K) :- m_in_est(M), ref(flow_12, F), K is (M/F)*(M/F).   % dP ~ v^2 (eq.10-12)

leak_fraction(L) :- val(m_in, Mi), val(m_use, Mu), Mi > 0, L is (Mi-Mu)/Mi.   % eq.15-16
capacity(C) :- val(m_in, Mi), val(load, L), L > 0.05, C is Mi/L.
cap_deficit(D) :- capacity(C), ref(rated_fad, R), D is (R-C)/R.
spec_power_ratio(R) :- val(p_sh, P), val(m_in, M), M > 0, ref(spec_power, S0), R is (P/M)/S0.
t_rise(D) :- val(t_d, T), ref(t_d_ref, T0), ref(t_amb_ref, A0),
    ( val(t_amb, A) -> Tr is T0 + (A - A0) ; Tr = T0 ),
    D is T - Tr.
dew_dev(D) :- val(t_dew, T), ref(dewpoint, R), D is T - R.                       % eq.33

rec_best(P) :- val(p_rec, P), !.
rec_best(P) :- val(p_rec_b, P), !.
rec_best(P) :- val(p_dis, D), ref(p_dis, R0), ref(p_rec, R1), P is D - (R0 - R1).

header_dp(D) :- rec_best(Pr), val(dp_dryer, Dd), val(dp_filter, Df), val(p_hdr, Ph),
    D is Pr - Dd - Df - Ph.

dp_ratio(filter, R) :- val(dp_filter, D), flow_scale(K), ref(dp_filter_12, B), R is D/(B*K). % eq.31
dp_ratio(dryer,  R) :- val(dp_dryer,  D), flow_scale(K), ref(dp_dryer_12,  B), R is D/(B*K).
dp_ratio(header, R) :- header_dp(D),      flow_scale(K), ref(dp_hdr_12,    B), R is D/(B*K). % eq.30

% sensor plausibility (redundancy + range consistency)
rec_in_range(P) :- obs(p_dis, D), thr(rec_range_bar, W), P =< D + 0.05, P >= D - W.
suspect_sensor(p_rec) :- obs(p_rec, P), obs(p_dis, _), \+ rec_in_range(P),
    \+ ( obs(p_rec_b, B), \+ rec_in_range(B) ).
suspect_sensor(p_rec_b) :- obs(p_rec_b, P), obs(p_dis, _), \+ rec_in_range(P),
    obs(p_rec, A), rec_in_range(A).
suspect_sensor(m_use) :- holds(leak_unsupported).
