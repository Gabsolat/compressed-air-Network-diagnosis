% =====================================================================
% rules.pl -- deductive diagnostic rules with provenance
% rule(Id, Fault, [Conditions], SourceId).  KB u E |= F  (eq.22)
% Source ids refer to the knowledge-acquisition table in the README.
% Status of every source = to_verify (thresholds are assumptions).
% =====================================================================
rule(r01, fl, [leak_fraction_high, ultrasonic_high],                    k_doe).
rule(r02, fl, [leak_fraction_high, cycling_high, ultrasonic_unobserved], k_doe).
rule(r03, fl, [ultrasonic_high, cycling_high, leak_fraction_unobserved], k_doe).
rule(r04, fc, [capacity_deficit, spec_power_high],                      k_iso1217).
rule(r05, fc, [capacity_deficit, disch_temp_high],                      k_iso1217).
rule(r06, fc, [capacity_deficit, vibration_high],                       k_iso1217).
rule(r07, fc, [spec_power_high, disch_temp_high, vibration_high],       k_iso1217).
rule(r08, ff, [filter_dp_high],                                         k_doe).
rule(r09, fd, [dewpoint_high],                                          k_iso8573).
rule(r10, fd, [dryer_dp_high],                                          k_doe).
rule(r11, fr, [cycling_high, drain_low],                                k_doe).
rule(r12, ft, [header_dp_high],                                         k_fluid).
rule(r13, fv, [reg_under],                                              k_assumption).
rule(r14, fv, [reg_over],                                               k_assumption).
rule(r15, fs, [prec_disagree],                                          k_assumption).
rule(r16, fs, [prec_out_of_range],                                      k_assumption).
rule(r17, fs, [leak_unsupported],                                       k_assumption).

source(k_doe,        'US DOE / Compressed Air Challenge sourcebook (verify edition, thresholds)').
source(k_iso1217,    'ISO 1217 displacement compressors acceptance tests (verify)').
source(k_iso8573,    'ISO 8573-1 compressed-air purity classes (verify dew-point class)').
source(k_fluid,      'Darcy-Weisbach pipe-flow textbook relations (eq.10-12)').
source(k_assumption, 'Engineering assumption by author; attach citation or justification').
