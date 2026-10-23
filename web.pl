% =====================================================================
% web.pl -- HTML rendering for the web app. Internal atoms such as
% p_use_low or leak_repair are never shown to the user: they are mapped to
% readable text with true subscripts (P<sub>use</sub>), not underscores.
% =====================================================================

% ---------- symbols with subscripts, and units ----------
var_html(p_dis,    'P<sub>dis</sub>').
var_html(p_rec,    'P<sub>rec</sub>').
var_html(p_rec_b,  'P<sub>rec,b</sub>').
var_html(dp_dryer, '&Delta;P<sub>dryer</sub>').
var_html(dp_filter,'&Delta;P<sub>filter</sub>').
var_html(p_hdr,    'P<sub>hdr</sub>').
var_html(p_set,    'P<sub>set</sub>').
var_html(p_use,    'P<sub>use</sub>').
var_html(m_in,     'm&#775;<sub>in</sub>').
var_html(m_use,    'm&#775;<sub>use</sub>').
var_html(p_sh,     'P<sub>sh</sub>').
var_html(t_d,      'T<sub>d</sub>').
var_html(t_amb,    'T<sub>amb</sub>').
var_html(v_rms,    'V<sub>RMS</sub>').
var_html(t_dew,    'T<sub>dew</sub>').
var_html(c_water,  'C<sub>water</sub>').
var_html(l_a,      'L<sub>a</sub>').
var_html(load,     'Loaded fraction').
var_html(cyc,      'Load/unload cycles').

var_unit(p_dis,'bar(g)'). var_unit(p_rec,'bar(g)'). var_unit(p_rec_b,'bar(g)').
var_unit(dp_dryer,'bar'). var_unit(dp_filter,'bar'). var_unit(p_hdr,'bar(g)').
var_unit(p_set,'bar(g)'). var_unit(p_use,'bar(g)').
var_unit(m_in,'Nm<sup>3</sup>/min'). var_unit(m_use,'Nm<sup>3</sup>/min').
var_unit(p_sh,'kW'). var_unit(t_d,'&deg;C'). var_unit(t_amb,'&deg;C').
var_unit(v_rms,'mm/s'). var_unit(t_dew,'&deg;C'). var_unit(c_water,'L/h').
var_unit(l_a,'dB'). var_unit(load,'&ndash;'). var_unit(cyc,'h<sup>&minus;1</sup>').

obs_order([p_dis,p_rec,p_rec_b,dp_dryer,dp_filter,p_hdr,p_set,p_use,m_in,m_use,
           load,p_sh,t_d,t_amb,v_rms,t_dew,c_water,cyc,l_a]).

fault_sub(fl,'L'). fault_sub(fc,'C'). fault_sub(ff,'F'). fault_sub(fd,'D').
fault_sub(fr,'R'). fault_sub(ft,'T'). fault_sub(fv,'V'). fault_sub(fs,'S').
fault_sub(fp,'P'). fault_sub(fn,'N').

indicator_html(leak_fraction,    'Leakage fraction &lambda;<sub>L</sub>').
indicator_html(capacity_deficit, 'Compressor capacity deficit').
indicator_html(spec_power_ratio, 'Specific power ratio').
indicator_html(filter_ratio,     'Filter restriction index I<sub>F</sub>').
indicator_html(dryer_dp_ratio,   'Dryer &Delta;P ratio').
indicator_html(header_ratio,     'Header &Delta;P ratio &Lambda;<sub>P</sub>').
indicator_html(dewpoint_dev,     'Dew-point deviation (&deg;C)').

group_label(a_normal,    'Test A &ndash; Normal operation').
group_label(b_leak,      'Test B &ndash; Leakage').
group_label(c_comp,      'Test C &ndash; Compressor deficiency').
group_label(d_filter,    'Test D &ndash; Filter fault').
group_label(d_dryer,     'Test D &ndash; Dryer fault').
group_label(e_header,    'Test E &ndash; Distribution restriction').
group_label(f_multi,     'Test F &ndash; Multiple faults').
group_label(g_incomplete,'Test G &ndash; Incomplete observations').
group_label(g_noisy,     'Test G &ndash; Noisy observations').
group_label(g_conflict,  'Test G &ndash; Conflicting observations').
group_label(g_borderline,'Test G &ndash; Borderline values').
group_label(x_receiver,  'Extra &ndash; Receiver fault').
group_label(x_regulator, 'Extra &ndash; Regulator fault').
group_label(x_sensor,    'Extra &ndash; Instrumentation fault').

cond_label(p_use_low,         'P<sub>use</sub> low').
cond_label(p_rec_low,         'P<sub>rec</sub> low').
cond_label(prec_disagree,     'Redundant receiver pressure sensors disagree').
cond_label(prec_out_of_range, 'Receiver pressure reading outside plausible range').
cond_label(leak_unsupported,  'Apparent leakage not corroborated by ultrasonic or cycling evidence').
cond_label(reg_error,         'Regulator set-point error').
cond_label(reg_under,         'Regulator output below set-point with adequate supply').
cond_label(reg_over,          'Regulator output above set-point').
cond_label(ultrasonic_high,   'Ultrasonic level high').

token_html(dp, '&Delta;P').
token_html(fad, 'FAD').

% ---------- generic readable text: no underscores ----------
humanize(Atom, Html) :-
    atomic_list_concat(Parts, '_', Atom),
    maplist(tok, Parts, Ws),
    atomic_list_concat(Ws, ' ', Text),
    cap_first(Text, Html).
tok(P, W) :- ( token_html(P, W) -> true ; W = P ).
cap_first(T, C) :-
    (  sub_atom(T, 0, 1, _, F), sub_atom(T, 1, _, 0, R)
    -> upcase_atom(F, U), atom_concat(U, R, C)
    ;  C = T ).

cond_html(C, H) :- cond_label(C, H), !.
cond_html(C, H) :- humanize(C, H).

fault_html(undetermined, 'Undetermined') :- !.
fault_html(F, H) :-
    fault_name(F, N), humanize(N, Nm), fault_sub(F, S),
    format(atom(H), '~w (F<sub>~w</sub>)', [Nm, S]).
fault_plain(F, H) :-
    (  fault_name(F, N) -> humanize(N, H) ; humanize(F, H) ).

action_html(verify_sensor(S), H) :- !,
    ( var_html(S, V) -> true ; humanize(S, V) ),
    format(atom(H), 'Verify sensor ~w', [V]).
action_html(A, H) :- humanize(A, H).

basis_html(B, H) :-
    (  sub_atom(B, 0, 1, _, r), sub_atom(B, 1, _, 0, N), atom_number(N, _)
    -> format(atom(H), 'Rule R~w', [N])
    ;  humanize(B, H) ).

glabel(G, H) :- ( group_label(G, H) -> true ; humanize(G, H) ).

% ---------- text helpers ----------
replace_all(Text, From, To, Out) :-
    atomic_list_concat(Parts, From, Text), atomic_list_concat(Parts, To, Out).
esc(In, Out) :-
    atom_string(A0, In),
    replace_all(A0, '&', '&amp;', A1), replace_all(A1, '<', '&lt;', A2),
    replace_all(A2, '>', '&gt;', A3), replace_all(A3, '"', '&quot;', Out).
% report text: escape, then replace underscores by spaces (same length keeps columns aligned)
sanitize(In, Out) :- esc(In, E), replace_all(E, '_', ' ', Out).

% ---------- page template ----------
page_start(Title) :-
    format("Content-Type: text/html; charset=UTF-8~n~n"),
    format("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"),
    format("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"),
    format("<title>~w | Compressed-air diagnosis</title>", [Title]),
    format("<script>(function(){try{var t=localStorage.getItem('krr-theme');if(!t){t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'}document.documentElement.dataset.theme=t}catch(e){}})();</script>"),
    format("<link rel=\"stylesheet\" href=\"/static/style.css\"><script defer src=\"/static/app.js\"></script></head><body>"),
    format("<header class=\"site\"><div class=\"wrap bar\"><a class=\"brand\" href=\"/\">"),
    format("<svg class=\"mark\" viewBox=\"0 0 24 24\" width=\"24\" height=\"24\" aria-hidden=\"true\"><path d=\"M3.5 17a8.5 8.5 0 0 1 17 0\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\"/><path d=\"M12 17l4.2-5.4\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\"/><circle cx=\"12\" cy=\"17\" r=\"1.8\" fill=\"currentColor\"/></svg>"),
    format("<span>Compressed-air diagnosis</span></a>"),
    format("<nav aria-label=\"Main\"><a href=\"/\">Diagnose</a><a href=\"/cases\">Test cases</a><a href=\"/results\">Evaluation</a></nav>"),
    format("<button type=\"button\" id=\"theme-toggle\" class=\"btn ghost\">Dark mode</button></div></header><main id=\"main\">").
page_end :-
    format("</main><footer class=\"site-foot\"><div class=\"wrap\">"),
    format("Decision support only. The limits used here are engineering assumptions of this prototype and must be confirmed against your plant standards. The built-in test cases are synthetic."),
    format("</div></footer></body></html>~n").

chips([], _) :- !, format("<span class=\"muted\">none</span>").
chips(L, Goal) :- forall(member(X, L), ( call(Goal, X, H), format("<span class=\"chip\">~w</span>", [H]) )).

% ---------- field descriptions for the input form ----------
var_desc(p_dis,'Compressor discharge pressure').
var_desc(p_rec,'Receiver pressure (sensor 1)').
var_desc(p_rec_b,'Receiver pressure from a second, redundant sensor (optional)').
var_desc(dp_dryer,'Pressure drop across the dryer').
var_desc(dp_filter,'Pressure drop across the filter').
var_desc(p_hdr,'Pressure at the far end of the header').
var_desc(p_set,'Regulator set-point').
var_desc(p_use,'Pressure at the point of use, after the regulator').
var_desc(m_in,'Air produced by the compressor (free-air delivery)').
var_desc(m_use,'Total metered end-use flow').
var_desc(load,'Fraction of time the compressor is loaded (0 to 1)').
var_desc(p_sh,'Compressor shaft power').
var_desc(t_d,'Compressor discharge temperature').
var_desc(t_amb,'Ambient temperature').
var_desc(v_rms,'Compressor vibration, RMS velocity').
var_desc(t_dew,'Dryer outlet pressure dew point').
var_desc(c_water,'Receiver condensate drain flow').
var_desc(cyc,'Compressor load/unload cycles per hour').
var_desc(l_a,'Ultrasonic leak-detector level').

var_hint(p_dis,'7.8'). var_hint(p_rec,'7.7'). var_hint(p_rec_b,'7.7'). var_hint(dp_dryer,'0.20').
var_hint(dp_filter,'0.15'). var_hint(p_hdr,'7.1'). var_hint(p_set,'6.5'). var_hint(p_use,'6.45').
var_hint(m_in,'9.8'). var_hint(m_use,'9.0'). var_hint(load,'0.5'). var_hint(p_sh,'62').
var_hint(t_d,'85'). var_hint(t_amb,'25'). var_hint(v_rms,'2.0'). var_hint(t_dew,'3').
var_hint(c_water,'1.0'). var_hint(cyc,'12'). var_hint(l_a,'45').

field_group('Compressor and power', [p_dis, m_in, load, p_sh, t_d, t_amb, v_rms]).
field_group('Receiver', [p_rec, p_rec_b, cyc, c_water]).
field_group('Air treatment', [dp_dryer, dp_filter, t_dew]).
field_group('Distribution and point of use', [p_hdr, p_set, p_use, m_use, l_a]).

fault_info(fl, 'Compressed air escapes through leaks in pipes, fittings, couplings or equipment, so the compressor produces more air than the plant uses.',
    'worn couplings, hoses and seals, loose fittings, failed drain valves, corroded pipework', 'wasted energy, pressure drop, longer compressor running time').
fault_info(fc, 'The compressor delivers less air, or needs more power per unit of air, than its rating.',
    'clogged intake filter, worn valves or rings, leaking unloader, control faults, hot intake air', 'pressure cannot be held at high demand, higher energy cost, overheating').
fault_info(ff, 'The filter element is loaded with dirt or liquid, so the air meets more resistance than it should.',
    'element past its service life, oil or water carry-over, dirty intake air', 'pressure drop wastes energy and starves downstream users').
fault_info(fd, 'The dryer is not removing moisture properly (high dew point) or its internal resistance has risen.',
    'low refrigerant, fouled condenser, failed condensate drain, overload, blocked heat exchanger', 'wet air, corrosion, condensate in the lines, product quality problems').
fault_info(fr, 'The receiver condensate drain is not working or the effective volume has shrunk, so the compressor cycles too often.',
    'blocked or failed drain valve, accumulated water', 'short cycling, extra wear, wet air').
fault_info(ft, 'A section of the distribution line has abnormal flow resistance.',
    'partly closed valve, blocked or undersized pipe, scale or debris, collapsed hose', 'low pressure at users and an unstable supply').
fault_info(fv, 'The regulator does not hold its set-point although supply pressure is adequate (or it lets pressure rise above it).',
    'worn diaphragm or seat, contaminated pilot, drifting spring or set-point', 'over- or under-pressure at the point of use, tool and process problems').
fault_info(fs, 'One or more instruments give readings that disagree with the rest of the evidence, so the equipment itself may be healthy.',
    'sensor drift, calibration error, wiring problems, fouled flow meter', 'false alarms, missed faults, wrong maintenance decisions if the reading is trusted').
fault_info(fp, 'Pressure is low but the readings supplied do not show which component is responsible.',
    'not isolated with the data available', 'unresolved pressure loss; supply more measurements').
fault_info(fn, 'No abnormal condition is evident from the readings supplied.', 'none', 'none').
fault_info(undetermined, 'The readings do not point to a single explanation; several faults remain possible.',
    'insufficient or ambiguous evidence', 'supply more measurements to narrow the diagnosis').

% ---------- engineering checks shown in the walkthrough ----------
% check_def(Id, Label, Formula, ValueGoal, ThresholdGoal, Direction, Unit, AbnormalCond, NormalCond)
check_def(leak, 'Leakage fraction &lambda;<sub>L</sub>',
    '(m&#775;<sub>in</sub> &minus; m&#775;<sub>use</sub>) / m&#775;<sub>in</sub>', leak_fraction, leak_thr, above, '', leak_fraction_high, leak_fraction_ok).
check_def(ultra, 'Ultrasonic level L<sub>a</sub>', 'measured', v_ultra, ultra_thr, above, 'dB', ultrasonic_high, ultrasonic_ok).
check_def(cap, 'Compressor capacity deficit',
    '(FAD<sub>rated</sub> &minus; m&#775;<sub>in</sub> / load) / FAD<sub>rated</sub>', cap_deficit, cap_thr, above, '', capacity_deficit, capacity_ok).
check_def(spw, 'Specific power ratio',
    '(P<sub>sh</sub> / m&#775;<sub>in</sub>) / reference', spec_power_ratio, spw_thr, above, '', spec_power_high, none).
check_def(tdis, 'Discharge temperature rise',
    'T<sub>d</sub> &minus; (85 + T<sub>amb</sub> &minus; 25)', t_rise, td_thr, above, '&deg;C', disch_temp_high, none).
check_def(vib, 'Vibration V<sub>RMS</sub>', 'measured', v_vib, vib_thr, above, 'mm/s', vibration_high, none).
check_def(cyc, 'Load/unload cycles', 'measured', v_cyc, cyc_thr, above, 'h<sup>&minus;1</sup>', cycling_high, cycling_ok).
check_def(drain, 'Receiver drain flow', 'measured', v_drain, drain_thr, below, 'L/h', drain_low, drain_ok).
check_def(filt, 'Filter restriction index I<sub>F</sub>',
    '&Delta;P<sub>filter</sub> / (reference &times; (m&#775;<sub>in</sub>/12)<sup>2</sup>)', v_filt, filt_thr, above, '', filter_dp_high, filter_ok).
check_def(dry, 'Dryer &Delta;P ratio',
    '&Delta;P<sub>dryer</sub> / (reference &times; (m&#775;<sub>in</sub>/12)<sup>2</sup>)', v_dry, dry_thr, above, '', dryer_dp_high, dryer_dp_ok).
check_def(dew, 'Dew-point deviation',
    'T<sub>dew</sub> &minus; 3 &deg;C', dew_dev, dew_thr, above, '&deg;C', dewpoint_high, dewpoint_ok).
check_def(hdr, 'Header &Delta;P ratio &Lambda;<sub>P</sub>',
    '(P<sub>rec</sub> &minus; &Delta;P<sub>dryer</sub> &minus; &Delta;P<sub>filter</sub> &minus; P<sub>hdr</sub>) / (reference &times; (m&#775;<sub>in</sub>/12)<sup>2</sup>)',
    v_hdr, hdr_thr, above, '', header_dp_high, header_ok).
check_def(reg, 'Regulator error P<sub>set</sub> &minus; P<sub>use</sub>',
    'P<sub>set</sub> &minus; P<sub>use</sub>', v_reg, reg_thr, band, 'bar', reg_error, reg_ok).
check_def(prd, 'Receiver sensor disagreement',
    '|P<sub>rec</sub> &minus; P<sub>rec,b</sub>|', v_prd, prd_thr, above, 'bar', prec_disagree, none).

v_ultra(V) :- val(l_a, V).        v_vib(V) :- val(v_rms, V).
v_cyc(V) :- val(cyc, V).          v_drain(V) :- val(c_water, V).
v_filt(V) :- dp_ratio(filter, V). v_dry(V) :- dp_ratio(dryer, V).
v_hdr(V) :- dp_ratio(header, V).  v_reg(V) :- val(p_set, S), val(p_use, U), V is S - U.
v_prd(V) :- obs(p_rec, A), obs(p_rec_b, B), V is abs(A - B).
leak_thr(T) :- thr(leak_frac_high, T).     ultra_thr(T) :- thr(ultrasonic_high_db, T).
cap_thr(T) :- thr(capacity_deficit, T).    spw_thr(T) :- thr(spec_power_ratio_high, T).
td_thr(T) :- thr(disch_temp_rise_high, T). vib_thr(T) :- thr(vib_high_mm_s, T).
cyc_thr(T) :- ref(cycles, R), thr(cycle_ratio_high, T0), T is R*T0.
drain_thr(T) :- ref(drain, R), thr(drain_ratio_low, T0), T is R*T0.
filt_thr(T) :- thr(filter_ratio_high, T). dry_thr(T) :- thr(dryer_dp_ratio_high, T).
dew_thr(T) :- thr(dewpoint_dev_high, T).  hdr_thr(T) :- thr(header_ratio_high, T).
reg_thr(T) :- thr(reg_error_bar, T).      prd_thr(T) :- thr(redundancy_tol_bar, T).

check_status(Abn, Ok, VG, S) :-
    (  once(holds(Abn)) -> S = abnormal
    ;  Ok == none -> ( once(catch(call(VG, _), _, fail)) -> S = normal ; S = unknown )
    ;  once(holds(Ok)) -> S = normal
    ;  S = unknown ).

% ---------- input parsing ----------
temp_var(t_d). temp_var(t_amb). temp_var(t_dew).
valid_value(load, N) :- !, N >= 0, N =< 1.05.
valid_value(V, N) :- ( temp_var(V) -> true ; N >= 0 ).

parse_inputs(Request, Obs, Errors) :-
    (  memberchk(search(S), Request) -> true ; S = [] ),
    obs_order(Ord),
    findall(R, ( member(V, Ord), member(V=Raw, S), Raw \== '', input_item(V, Raw, R) ), Items),
    findall(V=N, member(ok(V=N), Items), Obs),
    findall(Msg, ( member(bad(V), Items), var_html(V, H),
                   format(atom(Msg), 'The value for ~w is not a valid number or is out of range.', [H]) ), Errors0),
    (  Obs == [], Errors0 == [], S \== [] -> Errors = ['No readings were entered. Please fill in at least two fields.']
    ;  Errors0 == [], Obs \== [], \+ Obs = [_,_|_] -> Errors = ['Please enter at least two readings so the checks have something to compare.']
    ;  Errors = Errors0 ).
input_item(V, Raw, R) :-
    (  atom_number(Raw, N), valid_value(V, N) -> R = ok(V=N) ; R = bad(V) ).

obs_query(Obs, Q) :-
    findall(P, ( member(V=X, Obs), format(atom(P), '~w=~4f', [V, X]) ), Ps),
    atomic_list_concat(Ps, '&', Q).

prefill(Request, Pre) :-
    (  memberchk(search(S), Request), memberchk(example=Id, S), case(Id, _, _, _, _, _, Obs, _)
    -> Pre = Obs
    ;  parse_inputs(Request, Pre0, _), Pre = Pre0 ).

% ---------- form page ----------
group_help('Compressor and power', 'Output, loading and condition of the compressor.').
group_help('Receiver', 'Storage vessel pressure, cycling and condensate drain.').
group_help('Air treatment', 'Dryer and filter pressure drop, and dew point.').
group_help('Distribution and point of use', 'Header, regulator and end-use readings.').

example_label(a_normal, 'Healthy network').     example_label(b_leak, 'Leakage').
example_label(c_comp, 'Compressor deficiency'). example_label(d_filter, 'Clogged filter').
example_label(d_dryer, 'Dryer fault').          example_label(e_header, 'Line restriction').
example_label(x_receiver, 'Receiver drain failure'). example_label(x_regulator, 'Regulator fault').
example_label(x_sensor, 'Faulty sensor').       example_label(f_multi, 'Two faults at once').

form_page(Pre, Errors) :-
    page_start('Diagnose'),
    format("<section class=\"intro wrap\"><div><h1>Compressed-air network fault diagnosis</h1>"),
    format("<p class=\"lead\">Enter the readings you have from your compressor station and distribution network. "),
    format("The expert system checks them against engineering rules, explains each step of its reasoning and recommends corrective maintenance.</p>"),
    format("<p class=\"muted\">It looks for leaks, filter and dryer problems, compressor and regulator faults, receiver and line restrictions, and faulty instruments. "),
    format("Leave a field blank if you have no measurement, and never guess one. The grey numbers inside the fields are typical healthy values.</p></div>"),
    format("<figure class=\"chart-card\"><figcaption>Pressure profile along your network</figcaption>"),
    format("<div id=\"profile\" class=\"profile\"></div><p class=\"chart-note\" id=\"profile-note\"></p></figure></section>"),
    forall(member(E, Errors), format("<div class=\"wrap\"><div class=\"alert\" role=\"alert\">~w</div></div>", [E])),
    examples_section,
    format("<form id=\"diag\" class=\"wrap layout\" action=\"/diagnose\" method=\"get\" novalidate><div>"),
    forall(field_group(Title, Vars),
           ( group_help(Title, Help),
             format("<fieldset class=\"group\"><legend>~w</legend><p class=\"group-help\">~w</p><div class=\"fields\">", [Title, Help]),
             forall(member(V, Vars), field_html(V, Pre)),
             format("</div></fieldset>") )),
    format("</div>"),
    input_panel,
    format("</form>"),
    page_end.

examples_section :-
    format("<section class=\"examples wrap\"><strong>Start from an example</strong> "),
    forall(( member(G, [a_normal,b_leak,c_comp,d_filter,d_dryer,e_header,x_receiver,x_regulator,x_sensor,f_multi]),
             once(case(_, G, _, _, _, _, Obs, _)), example_label(G, L), obs_query(Obs, Q) ),
           format("<button type=\"button\" class=\"chip example\" aria-pressed=\"false\" data-obs=\"~w\">~w</button>", [Q, L])),
    format("<span class=\"muted\"> Synthetic cases that fill the form. Then run the diagnosis.</span></section>").

input_panel :-
    obs_order(Ord), length(Ord, N),
    format("<aside class=\"panel\" aria-label=\"Summary of your inputs\">"),
    format("<div class=\"count\"><b id=\"count\">0</b><span class=\"muted\">of ~d readings entered</span></div>", [N]),
    format("<div class=\"meterbar\"><i id=\"count-bar\"></i></div>"),
    format("<h2>What your readings can assess</h2><ul class=\"caps\" id=\"caps\"></ul>"),
    format("<p class=\"msg\" id=\"form-msg\" role=\"status\"></p>"),
    format("<div class=\"actions\"><button type=\"submit\" class=\"btn primary\">Run diagnosis</button>"),
    format("<button type=\"button\" class=\"btn\" id=\"clear\">Clear all</button></div></aside>").

field_html(V, Pre) :-
    var_html(V, H), var_unit(V, U), var_hint(V, Hint), var_desc(V, D),
    (  memberchk(V=X, Pre) -> format(atom(Val), '~4f', [X]) ; Val = '' ),
    (  temp_var(V) -> Min = '' ; Min = ' min="0"' ),
    (  V == load -> Max = ' max="1.05"' ; Max = '' ),
    format("<div class=\"field\"><label for=\"f-~w\"><span class=\"sym\">~w</span><span class=\"desc\">~w</span></label>", [V, H, D]),
    format("<div class=\"input\"><input id=\"f-~w\" type=\"number\" step=\"any\" inputmode=\"decimal\" name=\"~w\" value=\"~w\" placeholder=\"~w\"~w~w>", [V, V, Val, Hint, Min, Max]),
    format("<span class=\"unit\">~w</span></div></div>", [U]).

% ---------- list of built-in test cases ----------
cases_page :-
    page_start('Test cases'),
    format("<div class=\"wrap\" style=\"padding-top:36px\"><h1>Built-in test cases</h1>"),
    format("<p class=\"lead\">Synthetic cases used to evaluate the system. Choose one to see its full diagnosis.</p>"),
    format("<div class=\"card\"><form action=\"/demo\" method=\"get\"><select name=\"id\">"),
    forall(case(Id, G, _, True, _, _, _, _),
           ( glabel(G, GL), findall(P, (member(F, True), fault_plain(F, P)), Ps),
             atomic_list_concat(Ps, ' + ', TL),
             format("<option value=\"~w\">~w: ~w (label: ~w)</option>", [Id, Id, GL, TL]) )),
    format("</select> <button type=\"submit\" class=\"btn primary\">Show diagnosis</button></form></div></div>"),
    page_end.

% ---------- diagnosis page (shared by user input and test cases) ----------
render_diagnosis(Obs, Heading, Sub, EditLink, TrueOpt) :-
    (  catch(compute_diagnosis(Obs, Data), _, fail)
    -> render_data(Data, Heading, Sub, EditLink, TrueOpt)
    ;  page_start('Error'),
       format("<div class=\"wrap\" style=\"padding-top:36px\"><h1>The diagnosis could not be completed</h1>"),
       format("<p>Check the readings and try again. <a href=\"/\">Back to the form</a></p></div>"),
       page_end ).

compute_diagnosis(Obs, d(Faults, Info, Expl, Comp, Items, Sus)) :-
    diagnose(Obs, result(Faults, Info)),
    explain(Faults, Info, Expl), competing(Faults, Comp), plan(Faults, Items),
    findall(S, suspect(S), Sus).

obs_of_case(Obs) :- findall(V=X, obs(V, X), Obs).

render_data(d(Faults, Info, Expl, Comp, Items, Sus), Heading, Sub, EditLink, TrueOpt) :-
    Info = info(O, Fired, Res0, Add, _, Res1),
    obs_of_case(Obs), obs_query(Obs, Q),
    page_start('Diagnosis report'),
    format("<section class=\"summary wrap\"><div class=\"verdict\"><h1>~w</h1><p class=\"muted\">~w</p>", [Heading, Sub]),
    summary_block(Faults, TrueOpt),
    format("<div class=\"tools\"><a class=\"btn\" href=\"~w\">Change the inputs</a><button type=\"button\" class=\"btn\" id=\"print\">Print report</button></div></div>", [EditLink]),
    format("<figure class=\"chart-card\"><figcaption>Pressure profile along the network</figcaption>"),
    format("<div id=\"profile\" class=\"profile\" data-obs=\"~w\"></div><p class=\"chart-note\" id=\"profile-note\"></p></figure></section>", [Q]),
    format("<div class=\"wrap report\"><nav class=\"toc\" aria-label=\"Report sections\">"),
    forall(member(N-T, [1-'Readings received', 2-'Engineering checks', 3-'Rules that fired', 4-'Further reasoning',
                        5-'What was ruled out', 6-'Why this diagnosis', 7-'Maintenance plan']),
           format("<a href=\"#s~w\">~w &nbsp;~w</a>", [N, N, T])),
    format("</nav><div>"),
    step_inputs(Obs, Sus),
    step_checks,
    step_rules(Fired),
    step_reasoning(O, Res0, Add, Res1),
    step_ruled_out(O),
    step_explanation(Expl, Comp),
    step_plan(Items),
    format("</div></div>"),
    page_end.

step_open(N, Title) :-
    format("<section class=\"step\" id=\"s~w\"><h2><span class=\"num\">~w</span>~w</h2>", [N, N, Title]).
step_close :- format("</section>").

sensor_html(S, H) :- ( var_html(S, H) -> true ; humanize(S, H) ).

summary_block(Faults, TrueOpt) :-
    forall(member(F, Faults),
           ( fault_html(F, H), ( F == fn -> Cls = ' ok' ; Cls = '' ),
             format("<span class=\"badge~w\">~w</span>", [Cls, H]) )),
    (  TrueOpt = true(True)
    -> msort(True, S1), msort(Faults, S2),
       (  S1 == S2 -> format("<span class=\"badge ok\">Matches the test-case label</span>")
       ;  format("<span class=\"badge bad\">Differs from the test-case label</span>") )
    ;  true ),
    forall(member(F, Faults),
           (  fault_info(F, M, C, Q)
           -> fault_html(F, FH),
              format("<div class=\"fault\"><p><strong>~w</strong></p><p>~w</p><p class=\"muted\">Typical causes: ~w.</p><p class=\"muted\">Consequences: ~w.</p></div>", [FH, M, C, Q])
           ;  true )).

step_inputs(Obs, Sus) :-
    step_open(1, 'Readings received'),
    format("<div class=\"card\"><div class=\"table-scroll\"><table><tr><th>Variable</th><th>Value</th><th>Unit</th></tr>"),
    obs_order(Ord),
    forall(( member(V, Ord), memberchk(V=X, Obs) ),
           ( var_html(V, VH), var_unit(V, U), format("<tr><td>~w</td><td class=\"value\">~3f</td><td>~w</td></tr>", [VH, X, U]) )),
    format("</table></div>"),
    findall(V, (member(V, Ord), \+ memberchk(V=_, Obs)), Miss),
    (  Miss == [] -> true
    ;  format("<p class=\"muted\">Not supplied. Checks that need these are marked not determined: "),
       forall(member(V, Miss), ( var_html(V, VH), format("<span class=\"chip\">~w</span>", [VH]) )),
       format("</p>") ),
    (  Sus == [] -> true
    ;  format("<p><span class=\"badge warn\">Possible instrument problem</span> Readings from "),
       chips(Sus, sensor_html),
       format(" look implausible or inconsistent and were excluded from the engineering checks.</p>") ),
    format("</div>"),
    step_close.

step_checks :-
    step_open(2, 'Engineering checks'),
    format("<div class=\"card\"><div class=\"table-scroll\"><table>"),
    format("<tr><th>Check</th><th>How it is calculated</th><th>Value</th><th>Limit</th><th>Against limit</th><th>Result</th></tr>"),
    forall(check_def(_, Label, Formula, VG, TG, Dir, Unit, Abn, Ok),
           check_row(Label, Formula, VG, TG, Dir, Unit, Abn, Ok)),
    format("</table></div><p class=\"muted\">Reference values assume a healthy 20 Nm<sup>3</sup>/min station at 7.8 bar(g). Pressure-drop references scale with flow squared. The tick on each bar marks the limit.</p></div>"),
    step_close.

check_row(Label, Formula, VG, TG, Dir, Unit, Abn, Ok) :-
    check_status(Abn, Ok, VG, S),
    format("<tr><td>~w</td><td class=\"formula\">~w</td><td class=\"value\">", [Label, Formula]),
    (  once(catch(call(VG, V), _, fail)) -> format("~3f ~w", [V, Unit]) ; V = none, format("<span class=\"muted\">not available</span>") ),
    format("</td><td>"),
    (  once(call(TG, T)) -> limit_text(Dir, T, Unit) ; T = none ),
    format("</td><td>"), meter(V, T, S), format("</td><td>"), verdict_badge(S), format("</td></tr>").

meter(V, T, S) :-
    (  number(V), number(T), T =\= 0
    -> P0 is abs(V)/abs(T)*50, P is min(100, P0),
       format("<div class=\"meter s-~w\" role=\"img\" aria-label=\"Reading relative to its limit\"><i style=\"width:~1f%\"></i><b></b></div>", [S, P])
    ;  format("<span class=\"muted\">n/a</span>") ).

limit_text(above, T, U) :- format("above ~3f ~w", [T, U]).
limit_text(below, T, U) :- format("below ~3f ~w", [T, U]).
limit_text(band,  T, U) :- format("outside &plusmn;~3f ~w", [T, U]).

verdict_badge(S) :-
    (  S == abnormal -> format("<span class=\"badge bad\">Abnormal</span>")
    ;  S == normal   -> format("<span class=\"badge ok\">Normal</span>")
    ;  format("<span class=\"muted\">Not determined</span>") ).

step_rules(Fired) :-
    step_open(3, 'Rules that fired'),
    format("<div class=\"card\">"),
    (  Fired == [] -> format("<p class=\"muted\">No rule had all of its conditions satisfied by the readings.</p>")
    ;  format("<div class=\"table-scroll\"><table><tr><th>Rule</th><th>Conclusion</th><th>Conditions satisfied</th><th>Knowledge source</th></tr>"),
       forall(member(F-R, Fired),
              ( rule(R, F, Conds, Src), basis_html(R, RH), fault_html(F, FH),
                format("<tr><td>~w</td><td>~w</td><td>", [RH, FH]), chips(Conds, cond_html),
                format("</td><td>"),
                (  source(Src, Desc) -> format("~w", [Desc]) ; format("~w", [Src]) ),
                format("</td></tr>") )),
       format("</table></div>") ),
    format("</div>"),
    step_close.

step_reasoning(O, Res0, Add, Res1) :-
    step_open(4, 'Further reasoning'),
    format("<div class=\"card\">"),
    format("<p><strong>Abnormal symptoms detected</strong><br>"), chips(O, cond_html),
    format("</p><p><strong>Left unexplained by the rules above</strong><br>"), chips(Res0, cond_html),
    format("</p><p><strong>Faults added by abductive or consistency-based reasoning</strong><br>"), chips(Add, fault_html),
    format("</p><p><strong>Still unexplained afterwards</strong><br>"), chips(Res1, cond_html),
    format("</p></div>"),
    step_close.

step_ruled_out(O) :-
    step_open(5, 'What was ruled out'),
    format("<div class=\"card\">"),
    findall(F-Cs, ( candidate(F), exonerated(F), exonerated_by(F, Cs) ), Ex),
    format("<p><strong>Faults cleared by normal evidence</strong></p>"),
    (  Ex == [] -> format("<p class=\"muted\">None could be cleared with the readings supplied.</p>")
    ;  format("<div class=\"table-scroll\"><table><tr><th>Fault</th><th>Cleared because</th></tr>"),
       forall(member(F-Cs, Ex),
              ( fault_html(F, FH), format("<tr><td>~w</td><td>", [FH]), chips(Cs, cond_html), format("</td></tr>") )),
       format("</table></div>") ),
    format("<p><strong>Faults that could still cause each symptom</strong></p>"),
    (  O == [] -> format("<p class=\"muted\">No abnormal symptoms.</p>")
    ;  format("<div class=\"table-scroll\"><table><tr><th>Symptom</th><th>Possible causes not yet cleared</th></tr>"),
       forall(member(S, O),
              ( cond_html(S, SH), conflict(S, Set), format("<tr><td>~w</td><td>", [SH]),
                (  Set == [] -> format("<span class=\"badge warn\">none: the evidence is contradictory</span>") ; chips(Set, fault_html) ),
                format("</td></tr>") )),
       format("</table></div>") ),
    format("</div>"),
    step_close.

step_explanation(Expl, Comp) :-
    step_open(6, 'Why this diagnosis'),
    format("<div class=\"card\"><div class=\"table-scroll\"><table>"),
    format("<tr><th>Fault</th><th>Supporting evidence</th><th>Basis</th><th>Evidence score</th><th>Contradicting evidence</th></tr>"),
    forall(member(ex(F, Ev, Ba, _, _, CD, Co), Expl),
           ( fault_html(F, FH),
             format("<tr><td>~w</td><td>", [FH]), chips(Ev, cond_html),
             format("</td><td>"), chips(Ba, basis_html),
             format("</td><td class=\"value\">~3f</td><td>", [CD]), chips(Co, cond_html), format("</td></tr>") )),
    format("</table></div><p class=\"muted\">The evidence score ranks hypotheses. It is not a probability.</p>"),
    format("<p><strong>Other hypotheses considered and not reported</strong><br>"),
    (  Comp == [] -> format("<span class=\"muted\">none</span>")
    ;  forall(member(F-R, Comp),
              ( fault_html(F, FH), humanize(R, RH), format("<span class=\"chip\">~w: ~w</span>", [FH, RH]) )) ),
    format("</p></div>"),
    step_close.

step_plan(Items) :-
    step_open(7, 'Maintenance plan'),
    (  Items == [] -> format("<div class=\"card muted\">No corrective action is required, or no plan is available for this diagnosis.</div>")
    ;  forall(member(item(P, Fam, Acts, Why), Items),
              ( humanize(Fam, FamH), humanize(P, PH),
                format("<div class=\"card plan ~w\"><span class=\"badge\">~w priority</span><strong>~w</strong><ol>", [P, PH, FamH]),
                forall(member(A, Acts), ( action_html(A, AH), format("<li>~w</li>", [AH]) )),
                format("</ol><span class=\"muted\">~w</span></div>", [Why]) )) ),
    step_close.

% ---------- entry points used by server.pl ----------
form_for_request(Request) :- prefill(Request, Pre), form_page(Pre, []).

diagnose_request(Request) :-
    parse_inputs(Request, Obs, Errors),
    (  Errors == []
    -> (  Obs == [] -> form_page([], [])
       ;  obs_query(Obs, Q), format(atom(Edit), '/?~w', [Q]),
          render_diagnosis(Obs, 'Diagnosis report', 'Based on the readings you entered.', Edit, none) )
    ;  form_page(Obs, Errors) ).

render_case(Id) :-
    case(Id, G, _, True, _, _, Obs, _), !,
    glabel(G, GL), format(atom(Edit), '/?example=~w', [Id]),
    format(atom(Head), 'Test case ~w', [Id]),
    format(atom(Sub), '~w. Synthetic test case.', [GL]),
    render_diagnosis(Obs, Head, Sub, Edit, true(True)).
render_case(Id) :-
    esc(Id, E),
    page_start('Case not found'),
    format("<div class=\"wrap\" style=\"padding-top:36px\"><h1>Case not found</h1><p>No test case is called <code>~w</code>. <a href=\"/cases\">Choose one from the list</a>.</p></div>", [E]),
    page_end.

results_page :-
    page_start('Evaluation'),
    format("<div class=\"wrap\" style=\"padding-top:36px\"><h1>Evaluation report</h1>"),
    format("<p class=\"lead\">Test split, ablation and sensitivity analysis, generated live from the Prolog system.</p>"),
    with_output_to(string(S), run_all),
    sanitize(S, Clean),
    format("<pre class=\"report-text\">~w</pre></div>", [Clean]),
    page_end.
