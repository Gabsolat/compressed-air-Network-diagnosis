% =====================================================================
% network.pl -- network graph G=(V,E), fault universe, causal knowledge
% =====================================================================
% V: components
component(c1, compressor).   component(r1, receiver).
component(d1, dryer).        component(f1, filter).
component(h1, header).       component(g1, regulator).
component(b1, branch).       component(u1, end_use).
% E: directed flow links
flow_edge(c1,r1). flow_edge(r1,d1). flow_edge(d1,f1). flow_edge(f1,h1).
flow_edge(h1,g1). flow_edge(g1,b1). flow_edge(b1,u1).
downstream(A,B) :- flow_edge(A,B).
downstream(A,B) :- flow_edge(A,X), downstream(X,B).

% fault universe (fn = normal; fs added: instrumentation fault; fp = residual)
fault_name(fl, compressed_air_leakage).
fault_name(fc, compressor_capacity_or_performance_deficiency).
fault_name(ff, filter_restriction).
fault_name(fd, dryer_or_air_treatment_fault).
fault_name(fr, receiver_abnormality_drain_or_volume).
fault_name(ft, distribution_line_restriction).
fault_name(fv, regulator_or_valve_abnormality).
fault_name(fs, instrumentation_fault).
fault_name(fp, unlocalised_pressure_abnormality).
fault_name(fn, normal_operation).
all_faults([fl,fc,ff,fd,fr,ft,fv,fs,fp]).
candidate(F) :- member(F, [fl,fc,ff,fd,fr,ft,fv,fs]).   % fp is fallback only

fault_component(fl, network_pipework). fault_component(fc, c1).
fault_component(ff, f1). fault_component(fd, d1). fault_component(fr, r1).
fault_component(ft, h1). fault_component(fv, g1). fault_component(fs, sensors).

% abnormal symptoms (symbolic evidence the reasoner works with)
symptom(leak_fraction_high). symptom(ultrasonic_high). symptom(filter_dp_high).
symptom(dryer_dp_high).      symptom(dewpoint_high).   symptom(header_dp_high).
symptom(capacity_deficit).   symptom(spec_power_high). symptom(disch_temp_high).
symptom(vibration_high).     symptom(cycling_high).    symptom(drain_low).
symptom(reg_over).           symptom(reg_under).       symptom(p_use_low).
symptom(p_rec_low).          symptom(prec_disagree).   symptom(prec_out_of_range).
symptom(leak_unsupported).

% causal (not merely correlated) direct effects of each fault
explains_direct(fl, [leak_fraction_high, ultrasonic_high, cycling_high]).
explains_direct(fc, [capacity_deficit, spec_power_high, disch_temp_high, vibration_high]).
explains_direct(ff, [filter_dp_high]).
explains_direct(fd, [dryer_dp_high, dewpoint_high]).
explains_direct(fr, [cycling_high, drain_low]).
explains_direct(ft, [header_dp_high]).
explains_direct(fv, [reg_over, reg_under]).
explains_direct(fs, [prec_disagree, prec_out_of_range, leak_unsupported]).
explains_direct(fp, [p_use_low, p_rec_low]).
direct(F,S) :- explains_direct(F,L), member(S,L).

% fault propagation: causal links between symptoms (downstream effects)
prop(filter_dp_high,    p_use_low).
prop(dryer_dp_high,     p_use_low).
prop(header_dp_high,    p_use_low).
prop(reg_under,         p_use_low).
prop(capacity_deficit,  p_rec_low).
prop(leak_fraction_high,p_rec_low).
prop(p_rec_low,         p_use_low).

% evidence weights per fault (sum to 1), eq.42
support(fl, [leak_fraction_high-0.4, ultrasonic_high-0.4, cycling_high-0.2]).
support(fc, [capacity_deficit-0.4, spec_power_high-0.25, disch_temp_high-0.2, vibration_high-0.15]).
support(ff, [filter_dp_high-1.0]).
support(fd, [dewpoint_high-0.5, dryer_dp_high-0.5]).
support(fr, [cycling_high-0.5, drain_low-0.5]).
support(ft, [header_dp_high-1.0]).
support(fv, [reg_error-1.0]).
support(fs, [prec_disagree-0.4, prec_out_of_range-0.3, leak_unsupported-0.3]).
support(fp, [p_use_low-0.5, p_rec_low-0.5]).

% normal-behaviour evidence that exonerates a fault (all must hold)
exonerated_by(fl, [leak_fraction_ok, ultrasonic_ok]).
exonerated_by(fc, [capacity_ok]).
exonerated_by(ff, [filter_ok]).
exonerated_by(fd, [dryer_dp_ok, dewpoint_ok]).
exonerated_by(fr, [cycling_ok, drain_ok]).
exonerated_by(ft, [header_ok]).
exonerated_by(fv, [reg_not_implicated]).
exonerated_by(fs, [sensors_checked_ok]).

% measurements each symbolic condition depends on (any([...]) = at least one of them)
cond_needs(leak_fraction_high, [m_in, m_use]).   cond_needs(leak_fraction_ok, [m_in, m_use]).
cond_needs(ultrasonic_high, [l_a]).              cond_needs(ultrasonic_ok, [l_a]).
cond_needs(cycling_high, [cyc]).                 cond_needs(cycling_ok, [cyc]).
cond_needs(capacity_deficit, [m_in, load]).      cond_needs(capacity_ok, [m_in, load]).
cond_needs(spec_power_high, [p_sh, m_in]).
cond_needs(disch_temp_high, [t_d]).
cond_needs(vibration_high, [v_rms]).
cond_needs(filter_dp_high, [dp_filter, any([m_in, m_use])]).
cond_needs(filter_ok,      [dp_filter, any([m_in, m_use])]).
cond_needs(dryer_dp_high,  [dp_dryer, any([m_in, m_use])]).
cond_needs(dryer_dp_ok,    [dp_dryer, any([m_in, m_use])]).
cond_needs(dewpoint_high, [t_dew]).              cond_needs(dewpoint_ok, [t_dew]).
cond_needs(header_dp_high, [p_hdr, dp_dryer, dp_filter, any([p_rec, p_rec_b, p_dis]), any([m_in, m_use])]).
cond_needs(header_ok,      [p_hdr, dp_dryer, dp_filter, any([p_rec, p_rec_b, p_dis]), any([m_in, m_use])]).
cond_needs(drain_low, [c_water]).                cond_needs(drain_ok, [c_water]).
cond_needs(reg_under, [p_set, p_use, p_hdr]).
cond_needs(reg_over,  [p_set, p_use]).
cond_needs(prec_disagree, [p_rec, p_rec_b]).
cond_needs(prec_out_of_range, [p_rec, p_dis]).
cond_needs(leak_unsupported, [m_in, m_use, l_a]).
cond_needs(ultrasonic_unobserved, []).
cond_needs(leak_fraction_unobserved, []).
