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
css(C) :- css_lines(L), atomic_list_concat(L, C).
css_lines([
    ':root{--bg:#f6f7f9;--fg:#1c2330;--muted:#5c6675;--card:#fff;--line:#dde1e8;--accent:#0b5cad;--ok:#1a7f4b;--warn:#b45309;--bad:#b42318}',
    '@media (prefers-color-scheme:dark){:root{--bg:#12161d;--fg:#e6e9ef;--muted:#9aa4b2;--card:#1a2029;--line:#2c3542;--accent:#6ab0ff;--ok:#4cc38a;--warn:#f0a43a;--bad:#ff7b72}}',
    '*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.55 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}',
    'main{max-width:980px;margin:0 auto;padding:24px 16px 48px}',
    'h1{font-size:1.5rem;margin:0 0 4px}h2{font-size:1.1rem;margin:24px 0 8px}',
    '.sub{color:var(--muted);margin:0 0 16px}a{color:var(--accent)}',
    '.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:10px 0}',
    'table{border-collapse:collapse;width:100%}th,td{padding:7px 10px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}',
    'th{font-weight:600;color:var(--muted);font-size:.85rem;text-transform:uppercase;letter-spacing:.03em}',
    'td.num{text-align:right;font-variant-numeric:tabular-nums}',
    '.chip{display:inline-block;border:1px solid var(--line);border-radius:999px;padding:1px 10px;margin:2px 4px 2px 0;font-size:.9rem;background:var(--bg)}',
    '.badge{display:inline-block;border-radius:6px;padding:2px 10px;font-weight:600;margin:2px 6px 2px 0;border:1px solid var(--accent);color:var(--accent)}',
    '.badge.ok{border-color:var(--ok);color:var(--ok)}.badge.bad{border-color:var(--bad);color:var(--bad)}',
    '.urgent{border-left:5px solid var(--bad)}.high{border-left:5px solid var(--warn)}.medium{border-left:5px solid var(--accent)}',
    '.muted{color:var(--muted)}select,button{font:inherit;padding:8px 10px;border-radius:8px;border:1px solid var(--line);background:var(--card);color:var(--fg)}',
    'button{background:var(--accent);color:#fff;border-color:var(--accent);cursor:pointer}',
    'pre.report{overflow-x:auto;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px;font:13px/1.45 ui-monospace,Menlo,Consolas,monospace}',
    'footer{margin-top:32px;color:var(--muted);font-size:.85rem}',
    '.tablewrap{overflow-x:auto}'
]).


page_start(Title) :-
    format("Content-Type: text/html; charset=UTF-8~n~n"),
    css(C),
    format("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"),
    format("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"),
    format("<title>~w</title><style>~w</style></head><body><main>", [Title, C]),
    format("<p class=\"muted\"><a href=\"/\">Home</a> &middot; <a href=\"/results\">Evaluation report</a></p>").
page_end :-
    format("<footer>KRR Mini-Project 31 &ndash; Prolog expert system for compressed-air network fault diagnosis. "),
    format("All cases are <strong>synthetic</strong> test data, not plant measurements.</footer></main></body></html>~n").

chips([], _) :- !, format("<span class=\"muted\">none</span>").
chips(L, Goal) :- forall(member(X, L), ( call(Goal, X, H), format("<span class=\"chip\">~w</span>", [H]) )).

% ---------- home ----------
home_page :-
    page_start('Compressed-air network diagnosis'),
    format("<h1>Compressed-air network fault diagnosis</h1>"),
    format("<p class=\"sub\">Explainable Prolog expert system: deductive, abductive and consistency-based reasoning with corrective-maintenance planning.</p>"),
    format("<div class=\"card\"><form action=\"/demo\" method=\"get\"><label for=\"id\"><strong>Choose a test case</strong></label><br><br>"),
    format("<select name=\"id\" id=\"id\">"),
    forall(case(Id, G, _, True, _, _, _, _),
           ( glabel(G, GL), findall(P, (member(F, True), fault_plain(F, P)), Ps),
             atomic_list_concat(Ps, ' + ', TL),
             format("<option value=\"~w\">~w &middot; ~w &middot; true: ~w</option>", [Id, Id, GL, TL]) )),
    format("</select> <button type=\"submit\">Diagnose</button></form></div>"),
    format("<div class=\"card\"><strong>Evaluation report</strong><br>Runs the full evaluation: test split, ablation, sensitivity. "),
    format("<a href=\"/results\">Open the report</a></div>"),
    page_end.

% ---------- one case ----------
render_case(Id) :-
    case(Id, G, _, True, Sev, _, Obs, _), !,
    diagnose(Obs, result(Faults, Info)),
    Info = info(O, _, Res0, Add, Method, Res1),
    explain(Faults, Info, Expl), competing(Faults, Comp), plan(Faults, Items),
    findall(N-V, indicator(N, V), Ind),
    esc(Id, EId), glabel(G, GL),
    atom_string(SevA, Sev), humanize_sev(SevA, SevH),
    page_start('Diagnosis'),
    format("<h1>Case ~w</h1><p class=\"sub\">~w &middot; synthetic test case &middot; severity note: ~w</p>", [EId, GL, SevH]),
    format("<h2>Diagnosis</h2><div class=\"card\">"),
    forall(member(F, Faults), ( fault_html(F, H), format("<span class=\"badge\">~w</span>", [H]) )),
    msort(True, S1), msort(Faults, S2),
    (  S1 == S2 -> format("<span class=\"badge ok\">Matches the case label</span>")
    ;  format("<span class=\"badge bad\">Differs from the case label</span>"),
       format("<br><span class=\"muted\">Case label: </span>"),
       forall(member(F, True), ( fault_html(F, H), format("<span class=\"chip\">~w</span>", [H]) )) ),
    format("</div>"),
    format("<h2>Observations</h2><div class=\"card tablewrap\"><table><tr><th>Variable</th><th>Value</th><th>Unit</th></tr>"),
    obs_order(Ord),
    forall(( member(V, Ord), memberchk(V=X, Obs) ),
           ( var_html(V, VH), var_unit(V, U), format("<tr><td>~w</td><td class=\"num\">~3f</td><td>~w</td></tr>", [VH, X, U]) )),
    format("</table>"),
    findall(V, (member(V, Ord), \+ memberchk(V=_, Obs)), Miss),
    (  Miss == [] -> true
    ;  format("<p class=\"muted\">Not available in this case: "),
       forall(member(V, Miss), ( var_html(V, VH), format("<span class=\"chip\">~w</span>", [VH]) )),
       format("</p>") ),
    format("</div>"),
    format("<h2>Reasoning</h2><div class=\"card\"><p><strong>Abnormal symptoms detected</strong><br>"),
    chips(O, cond_html),
    format("</p><div class=\"tablewrap\"><table><tr><th>Derived indicator</th><th>Value</th></tr>"),
    forall(member(N-V, Ind),
           ( indicator_html(N, NH), format("<tr><td>~w</td><td class=\"num\">~3f</td></tr>", [NH, V]) )),
    format("</table></div>"),
    format("<p><strong>Left unexplained by the deductive rules</strong><br>"), chips(Res0, cond_html),
    format("</p><p><strong>Added by abductive or consistency-based reasoning</strong><br>"),
    chips(Add, fault_html),
    format("</p><p><strong>Still unexplained</strong><br>"), chips(Res1, cond_html),
    format("</p></div>"),
    format("<h2>Why this diagnosis</h2><div class=\"card tablewrap\"><table>"),
    format("<tr><th>Fault</th><th>Supporting evidence</th><th>Basis</th><th>Evidence score</th><th>Contradicting evidence</th></tr>"),
    forall(member(ex(F, Ev, Ba, _, _, CD, Co), Expl),
           ( fault_html(F, FH),
             format("<tr><td>~w</td><td>", [FH]), chips(Ev, cond_html),
             format("</td><td>"), chips(Ba, basis_html),
             format("</td><td class=\"num\">~3f</td><td>", [CD]), chips(Co, cond_html), format("</td></tr>") )),
    format("</table><p class=\"muted\">The evidence score ranks hypotheses; it is not a probability.</p>"),
    format("<p><strong>Competing hypotheses considered and not reported</strong><br>"),
    (  Comp == [] -> format("<span class=\"muted\">none</span>")
    ;  forall(member(F-R, Comp),
              ( fault_html(F, FH), humanize(R, RH), format("<span class=\"chip\">~w &ndash; ~w</span>", [FH, RH]) )) ),
    format("</p></div>"),
    format("<h2>Corrective maintenance plan</h2>"),
    (  Items == [] -> format("<div class=\"card muted\">No corrective action required or no plan available.</div>")
    ;  forall(member(item(P, Fam, Acts, Why), Items),
              ( humanize(Fam, FamH), humanize(P, PH),
                format("<div class=\"card ~w\"><span class=\"badge\">~w priority</span><strong>~w</strong><ol>", [P, PH, FamH]),
                forall(member(A, Acts), ( action_html(A, AH), format("<li>~w</li>", [AH]) )),
                format("</ol><span class=\"muted\">~w</span></div>", [Why]) )) ),
    page_end.
render_case(Id) :-
    esc(Id, E),
    page_start('Case not found'),
    format("<h1>Case not found</h1><p>No test case called <code>~w</code>. <a href=\"/\">Choose one from the list</a>.</p>", [E]),
    page_end.

humanize_sev(S, H) :- esc(S, E0), replace_all(E0, '_', ' ', H).

% ---------- evaluation report ----------
results_page :-
    page_start('Evaluation report'),
    format("<h1>Evaluation report</h1><p class=\"sub\">Test split, ablation and sensitivity analysis. Generated live from the Prolog system.</p>"),
    with_output_to(string(S), run_all),
    sanitize(S, Clean),
    format("<pre class=\"report\">~w</pre>", [Clean]),
    page_end.
