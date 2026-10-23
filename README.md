# KRR Mini-Project 31: Explainable Prolog Expert System for Compressed-Air Network Fault Diagnosis

**STATUS (read first).** The Prolog code and the dataset generator were written without a Prolog interpreter
available. The Python generator was executed and its dataset checked; the **Prolog has NOT been executed**
(only a bracket/terminator check was done). **No performance numbers exist yet.** Run the commands in section 1,
fix any load errors, and only then quote results in the report. Never report numbers that did not come from your own run.

## 1. Run it
```
swipl --version                       # record the version for the reproducibility section
python3 tools/gen_dataset.py --check  # regenerates data/cases.pl (seed 20261020) and checks signatures
swipl -q -g run_all -t halt main.pl > results/results.txt
swipl main.pl                         # interactive:  ?- demo(c001).   ?- demo(c040).
```
Splits: `dev` (about 25-30 %) for debugging/threshold tuning; `test` for reported results. If you tune a threshold
after seeing `test` results, say so in the report.

## 2. Step 1: network boundary (G = (V, E))
Single fixed-speed load/unload rotary-screw compressor c1 (rated FAD 20 Nm3/min, about 7.8 bar(g)) -> wet receiver r1
-> refrigerated dryer d1 -> filter f1 -> header h1 -> regulator g1 (set-point 6.5 bar) -> branch b1 -> end use u1.
Excluded: multi-compressor sequencing, VSD control, desiccant dryers, individual end-use equipment faults, pipe corrosion.
Assumption: flow through dryer, filter and header is approximately m_in (leaks are treated as downstream, distributed).

## 3. Step 2: fault taxonomy (each fault has a physical justification)
| ID | Fault | Physical meaning | Key evidence | Maintenance family |
|---|---|---|---|---|
| fl | Leakage | Air lost between compressor and use | leakage fraction, ultrasonic level, cycling | leak_repair |
| fc | Compressor capacity deficiency | Delivered FAD below rated, higher specific power | capacity deficit, specific power, discharge temp, vibration | compressor_inspection |
| ff | Filter restriction | Element loading raises dP | dP_F / reference | filter_service |
| fd | Dryer/air-treatment fault | Dew point rises or dryer dP rises | dew-point deviation, dryer dP ratio | dryer_service |
| fr | Receiver abnormality | Failed drain, condensate fills volume, cycling rises | cycling, drain flow | receiver_drain_service |
| ft | Distribution restriction | Excess dP in header after exonerating dryer and filter | residual header dP ratio | header_inspection |
| fv | Regulator/valve fault | Outlet deviates from set-point with adequate supply (or over-pressure) | set-point error, supply margin | regulator_service |
| fs | Instrumentation fault (**added**) | Sensor reading inconsistent with redundancy, range or corroboration | redundant p_rec, range check, uncorroborated leakage | sensor_calibration |
| fp | Unlocalised pressure abnormality (**refined**) | The brief's F_P is a *symptom* that fl, fc, ff, fd, ft, fv can all cause, so it is kept only as a fallback hypothesis | low p_use / p_rec with no isolated cause | pressure_profile_check |
| fn | Normal | no abnormal symptom | | none |

## 4. Step 3: variables and thresholds
Observation variables (all synthetic here; unavailable ones are simply omitted from a case):
`p_dis` discharge pressure (bar g) | `p_rec`, `p_rec_b` receiver pressure, two redundant sensors (bar g) | `dp_dryer`, `dp_filter` (bar) |
`p_hdr` header-end pressure (bar g) | `p_set` regulator set-point (bar g) | `p_use` pressure after regulator (bar g) |
`m_in` compressor output (Nm3/min) | `m_use` metered end-use flow (Nm3/min) | `p_sh` shaft power (kW) | `t_d` discharge temp (C) |
`t_amb` ambient (C) | `v_rms` compressor vibration RMS (mm/s) | `t_dew` pressure dew point (C) | `c_water` receiver drain flow (L/h) |
`l_a` ultrasonic leak level (dB, **my definition** of the brief's undefined L_a) | `load` loaded-time fraction | `cyc` load/unload cycles per hour.
Brief variables **not used** (no sensor assumed): T_s, P_s, m_a (replaced by m_in), Q_a, P_int, T_int, P_use/Q_use sub-metering, I_m, T_b, RH, eta_c.

Thresholds are in `config.pl`. **Every threshold is currently an engineering assumption** (`k_assumption`). Before submission, replace each with a
cited value or a written justification. Likely anchors to verify: leakage fraction and filter dP guidance (DOE/Compressed Air Challenge
sourcebook), dew-point class (ISO 8573-1), compressor acceptance basis (ISO 1217). I have not verified those values, so do not cite them as-is.

## 5. Step 4: knowledge acquisition and literature plan
| Knowledge | Source type | Converted into |
|---|---|---|
| Leakage fraction, ultrasonic detection | DOE sourcebook (verify), leak-detection papers | rules r01-r03, `leak_frac_high`, `ultrasonic_high_db` |
| Compressor capacity/efficiency | ISO 1217 (verify), compressor texts | rules r04-r07, eqs. 20-26 |
| Pipe/component dP vs flow (dP ~ v^2) | Darcy-Weisbach textbooks | `flow_scale/1`, dP ratios, rules r08, r10, r12 |
| Dew point / air quality | ISO 8573-1 (verify) | rule r09, `dewpoint_dev_high` |
| Consistency-based diagnosis | Reiter (1987), AI 32(1); de Kleer and Williams (1987), AI 32(1) | `conflict/2`, `hitting_best/2` |
| Abduction | Console, Dupre and Torasso (1991); Kakas, Kowalski and Toni (1992) | `abd_add/2`, `covers/2` |
| Prolog | Sterling and Shapiro; Bratko; Wielemaker et al. (2012), TPLP 12 | whole system |

These foundational references are ones I am fairly confident exist, but **check every detail against the originals**. The 70-90 source
target (at least 60 % recent peer-reviewed) still needs a proper database search (Scopus/IEEE/ScienceDirect) managed in EndNote. I have not built that list.

## 6. Step 5-7: design
Files: `config.pl` (thresholds) | `network.pl` (graph, fault universe, causal and propagation knowledge, evidence weights) |
`calc.pl` (engineering calculations: eqs. 10-12, 15-16, 20-26, 30-33) | `conditions.pl` (numeric to symbolic `holds/1`; missing evidence is never true) |
`rules.pl` (17 deductive rules with provenance) | `reasoning.pl` (deductive, abductive, consistency, integration) |
`explain.pl` (explanations, evidence scores, maintenance planner) | `evaluate.pl` (metrics, Tests A-H, ablation, sensitivity) | `main.pl`.

Reasoning:
* **Deductive** (`deductive/2`): a rule fires when all its conditions hold, KB u E |= F.
* **Abductive** (`abd_add/2`): for symptoms the deductive rules leave unexplained, find minimum-cardinality fault sets H (up to 3) with KB u H |= O.
  A fault explains a symptom only if one of its direct effects is observed and a causal propagation path leads to it. Added only if the minimum cover is unique.
* **Consistency-based** (`cons_add/2`): Reiter conflict sets (faults that could cause a symptom and are not exonerated by observed normal evidence), then minimal hitting sets. Added only if unique.
* **Sensor handling**: `suspect_sensor/1` marks unreliable sensors (redundancy mismatch, range inconsistency, uncorroborated leakage); `val/2` then ignores them.
* **Propagation** (`prop/2`) links symptoms causally (e.g. `filter_dp_high -> p_use_low`). Turning it off is an ablation.
* **Evidence score** = 0.6 * normalised weighted evidence (eq. 42-43) + 0.4 * rule confidence (eq. 44-45). It is a ranking score, **not a probability**.
  Eq. 46 (Bayesian posterior) is deliberately not implemented: no priors or likelihoods exist from real data, and the framework forbids claiming probabilistic certainty without them. Justify this in the report.

## 7. Decisions you must keep consistent in the report
1. **Coverage**: two definitions are printed: diagnosed/N (the brief, eq. 54) and correct/N (the framework). State which one you headline.
2. **Multi-fault metrics**: scored one-vs-rest per class over fault *sets*; micro-averaged. "Accuracy (exact set match)" requires the predicted set to equal the true set. The label-level micro accuracy is also printed. Say so in the report.
3. **PlanValidity** = diagnosed cases whose plan includes the expected action family of every *true* fault (normal: empty plan).
4. **Equations 23-25** of the brief are circular as written; the code uses measured shaft power and flow (`spec_power_ratio/1`), and `capacity/1` uses the loaded fraction. Eq. 13 vs 18 sign conventions need checking when you write section 2.4.
5. **Limitation**: a real receiver blockage can look like a receiver-sensor fault (p_rec out of range vs p_dis). Document it.

## 8. Dataset (256 synthetic cases, seed 20261020)
Groups: a_normal 30 | b_leak 24 | c_comp 18 | d_filter 18 | d_dryer 18 | e_header 18 | x_receiver 12 | x_regulator 18 | x_sensor 18 |
f_multi 34 | g_incomplete 15 | g_noisy 15 | g_conflict 6 | g_borderline 12. Mapping to the brief: Test A = a_normal, B = b_leak, C = c_comp,
D = d_filter + d_dryer, E = e_header, F = f_multi, G = g_*, H = explanation and plan metrics over all cases. The `x_*` groups cover receiver, regulator and
instrumentation faults required by the framework. The generator's `--check` verifies that every complete-evidence case shows its intended signature (0 mismatches
at the time of writing). It does not validate the expert system.
Provenance on every case: *synthetic, generated from a simplified physics model with stated assumptions*. They are not measurements.

## 9. Not done yet
Steps 1-9 are implemented in code, but: the Prolog has not been run; thresholds are unsourced; the literature list is a plan; the 40+ equation dictionary, TikZ figures
and report text are not written; unit tests per predicate are not written.

## 10. Deployment (Docker, Render via GitHub)
Files: `Dockerfile`, `server.pl` (HTTP routes), `web.pl` (HTML pages), `static/` (CSS and JavaScript), `render.yaml`, `.dockerignore`.
1. Push this folder to GitHub (commit `data/cases.pl`; the image does not need Python).
2. Render: New > Web Service > connect the repo > Language/Runtime: **Docker**. The repo root is this folder (`Dockerfile` next to `main.pl`), so leave Root Directory empty.
3. Health check path: `/health`. Render supplies `PORT`; the server reads it (default 10000).
4. Pages: `/` (input form with a live pressure-profile chart, a readings counter and a guide to what the entered readings can assess), `/diagnose` (detailed diagnosis report),
   `/cases` (built-in test cases), `/demo?id=c001`, `/results` (evaluation report), `/health`.
   The report has a pressure-profile chart, a section index and seven numbered steps: readings received (and any sensor judged implausible), engineering checks (formula, value, limit, bar against limit, result),
   rules that fired with their knowledge source, abductive and consistency-based reasoning, what was ruled out, the evidence table with rejected hypotheses, and a prioritised maintenance plan.
   Design: `static/style.css` and `static/app.js`, which `web.pl` embeds directly into every page, so no separate file route is needed (no external libraries or fonts; light and dark themes; print stylesheet). `web.pl` maps every internal atom to readable text with true subscripts, so underscores never appear in the web app.
   The terminal output of `main.pl` still shows raw atom names.
Local test: `docker build -t krr31 . && docker run -p 10000:10000 krr31`, then open `http://localhost:10000/results`.
Notes: free-tier services sleep when idle, and `/results` runs the whole evaluation, so the first call can be slow. The Dockerfile uses `swipl:stable`; pin an exact tag
and record it as your Prolog version. **Neither the Docker build, the server nor the web pages have been run yet** (same status as the Prolog code).
