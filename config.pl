% =====================================================================
% config.pl -- thresholds, reference values (ALL are engineering
% assumptions unless a source is attached; see README section 4).
% Measured Data /= Synthetic Test Case /= Assumption /= Literature rule.
% =====================================================================
:- dynamic threshold_scale/1.
threshold_scale(1.0).

% threshold(Name, Value)
threshold(leak_frac_high,       0.15).  % leakage fraction (-)         eq.16
threshold(ultrasonic_high_db,   60.0).  % ultrasonic level (dB)
threshold(filter_ratio_high,    2.0).   % I_F = dP_F / dP_F,ref(flow)  eq.31
threshold(dryer_dp_ratio_high,  2.0).   % dryer dP / reference dP
threshold(header_ratio_high,    1.8).   % header dP / reference dP     eq.30
threshold(header_excess_bar,    0.10).  % absolute floor on header excess dP (bar)
threshold(dewpoint_dev_high,    6.0).   % dew-point rise above ref (C) eq.33
threshold(capacity_deficit,     0.10).  % (rated - actual)/rated
threshold(spec_power_ratio_high,1.10).  % specific power / reference
threshold(disch_temp_rise_high, 8.0).   % discharge temp rise (C)
threshold(vib_high_mm_s,        3.5).   % compressor vibration RMS (mm/s) eq.38
threshold(cycle_ratio_high,     1.8).   % load/unload cycles vs reference
threshold(drain_ratio_low,      0.25).  % condensate drain flow vs reference
threshold(reg_error_bar,        0.30).  % |p_set - p_use| (bar)       eq.36
threshold(p_use_low_bar,        0.30).  % p_set - p_use (bar)
threshold(p_rec_low_bar,        0.40).  % p_rec,ref - p_rec (bar)
threshold(supply_margin_bar,    0.30).  % p_hdr >= p_set + margin
threshold(redundancy_tol_bar,   0.20).  % |p_rec - p_rec_b| (bar)
threshold(rec_range_bar,        0.35).  % allowed p_dis - p_rec band (bar)

thr(Name, V) :- threshold(Name, V0), threshold_scale(S), V is V0*S.

% ref(Name, Value): reference (healthy) quantities at the reference flow
ref(flow_12,       12.0).  % reference flow for dP scaling (Nm3/min)
ref(dp_dryer_12,   0.20).  % bar at reference flow
ref(dp_filter_12,  0.15).  % bar (clean element)
ref(dp_hdr_12,     0.25).  % bar
ref(p_dis,         7.8).   % bar(g) discharge
ref(p_rec,         7.7).   % bar(g) receiver
ref(dewpoint,      3.0).   % C pressure dew point (refrigerated dryer)
ref(rated_fad,     20.0).  % Nm3/min rated free-air delivery
ref(spec_power,    6.4).   % kW per (Nm3/min)
ref(t_d_ref,       85.0).  % C discharge temperature at reference ambient
ref(t_amb_ref,     25.0).  % C
ref(cycles,        12.0).  % load/unload cycles per hour
ref(drain,         1.0).   % L/h receiver condensate drain flow

% provenance status of the threshold set (replace with citations)
threshold_source(_, k_assumption).
