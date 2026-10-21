#!/usr/bin/env python3
"""Synthetic test-case generator for KRR Mini-Project 31 (compressed-air network).
ALL DATA ARE SYNTHETIC (simple physics-based model + assumptions). They are NOT
measurements. Diagnostic reasoning is done only in Prolog; this script only
creates test inputs and expected labels.  Usage: python3 tools/gen_dataset.py [--check]
"""
import random, re, sys, os

SEED = 20261020
rng = random.Random(SEED)
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
LEVELS = {'low': 6.0, 'nom': 9.0, 'high': 12.0}
FAM = {'fl':'leak_repair','fc':'compressor_inspection','ff':'filter_service','fd':'dryer_service',
       'fr':'receiver_drain_service','ft':'header_inspection','fv':'regulator_service',
       'fs':'sensor_calibration'}
U = rng.uniform

def thresholds():
    t = {}
    for m in re.finditer(r'^threshold\((\w+),\s*([0-9.]+)\)', open(os.path.join(ROOT,'config.pl')).read(), re.M):
        t[m.group(1)] = float(m.group(2))
    return t
TH = thresholds()

def physics(level, **p):
    m_use = LEVELS[level] * U(0.95, 1.05)
    lam = p.get('lam', U(0.05, 0.09))
    cap_f = p.get('cap_f', 1.0)
    cap = 20.0 * cap_f
    m_in = m_use / (1 - lam)
    load = min(1.0, m_in / cap)
    t_amb = U(20, 32)
    sag = 3.0 * max(0.0, (1 - cap_f) - 0.10) + 0.5 * max(0.0, lam - 0.10)
    p_dis = 7.8 - sag
    p_rec = p_dis - 0.10
    K = (m_in / 12.0) ** 2
    dp_dryer = 0.20 * K * p.get('dryer_k', 1.0)
    dp_filter = 0.15 * K * p.get('filter_k', 1.0)
    dp_hdr = 0.25 * K * p.get('hdr_k', 1.0)
    p_hdr = p_rec - dp_dryer - dp_filter - dp_hdr
    p_set = 6.5
    p_use = min(p_set - 0.05, p_hdr - 0.12)
    if 'reg_under' in p: p_use = p_set - p['reg_under']
    if 'reg_over' in p: p_use = p_set + p['reg_over']
    sp = 6.4 * p.get('sp_f', 1.0)
    t_d = 85.0 + (t_amb - 25.0) + p.get('td_rise', 0.0)
    cyc = 12.0 * (1 + 3.0 * (lam - 0.08)) * p.get('cyc_f', 1.0)
    l_a = 45.0 + (p['l_add'] if 'l_add' in p else (21.0 + 30.0 * (lam - 0.18) if lam >= 0.15 else 0.0))
    return dict(p_dis=p_dis, p_rec=p_rec, p_rec_b=p_rec, dp_dryer=dp_dryer, dp_filter=dp_filter,
        p_hdr=p_hdr, p_set=p_set, p_use=p_use, m_in=m_in, m_use=m_use, p_sh=sp*m_in, t_d=t_d,
        t_amb=t_amb, v_rms=2.0 + p.get('vib_add', 0.0), t_dew=3.0 + p.get('dew_add', 0.0),
        c_water=1.0 * p.get('drain_f', 1.0), l_a=l_a, load=load, cyc=cyc)

def noisy(true, s=1.0, extra=None):
    o = {}
    def g(sig): return rng.gauss(0, sig * s)
    for k, v in true.items():
        if k in ('p_dis','p_rec','p_rec_b','p_hdr','p_set'): o[k] = v + g(0.01)
        elif k == 'p_use': o[k] = v + g(0.015)
        elif k in ('dp_dryer','dp_filter'): o[k] = v * (1 + g(0.03)) + g(0.003)
        elif k in ('m_in','m_use'): o[k] = v * (1 + g(0.01))
        elif k == 'p_sh': o[k] = v * (1 + g(0.015))
        elif k == 'load': o[k] = v * (1 + g(0.01))
        elif k == 't_d': o[k] = v + g(1.5)
        elif k == 't_amb': o[k] = v + g(1.0)
        elif k == 'v_rms': o[k] = max(0.1, v + g(0.25))
        elif k == 't_dew': o[k] = v + g(0.8)
        elif k == 'cyc': o[k] = max(1.0, v + g(0.8))
        elif k == 'c_water': o[k] = max(0.0, v + g(0.08))
        elif k == 'l_a': o[k] = v + g(2.0)
    if extra: o.update(extra)
    return o

CASES = []
def add(group, true, sev, obs, drop=(), note=''):
    o = {k: v for k, v in obs.items() if k not in drop}
    exp = ['none'] if true == ['fn'] else [FAM[f] for f in true]
    CASES.append(dict(id='c%03d' % (len(CASES) + 1), group=group, split='dev' if rng.random() < 0.3 else 'test',
        true=true, sev=sev, obs=o, exp=exp, note=note, full=not drop))

def lvls(n): return [list(LEVELS)[i % 3] for i in range(n)]

# A: normal
for lv in lvls(30): add('a_normal', ['fn'], 'none', noisy(physics(lv)))
# B: leakage
for lv in lvls(24):
    lam = U(0.18, min(0.30, 1 - LEVELS[lv] * 1.05 / 16.5))
    add('b_leak', ['fl'], 'lam=%.2f' % lam, noisy(physics(lv, lam=lam)))
# C: compressor deficiency (at least two of three secondary signs)
def comp_params():
    signs = rng.sample(['sp_f', 'td_rise', 'vib_add'], rng.choice([2, 3]))
    q = dict(cap_f=U(0.72, 0.85))
    if 'sp_f' in signs: q['sp_f'] = U(1.15, 1.35)
    if 'td_rise' in signs: q['td_rise'] = U(11, 20)
    if 'vib_add' in signs: q['vib_add'] = U(2.0, 3.5)
    return q
for lv in lvls(18):
    q = comp_params(); add('c_comp', ['fc'], 'cap=%.2f' % q['cap_f'], noisy(physics(lv, **q)))
# D: filter and dryer
for lv in lvls(18):
    k = U(2.5, 6.0); add('d_filter', ['ff'], 'k=%.1f' % k, noisy(physics(lv, filter_k=k)))
for i, lv in enumerate(lvls(18)):
    if i % 2 == 0:
        d = U(8, 20); add('d_dryer', ['fd'], 'dew+%.0f' % d, noisy(physics(lv, dew_add=d)))
    else:
        k = U(2.5, 4.5); add('d_dryer', ['fd'], 'dpk=%.1f' % k, noisy(physics(lv, dryer_k=k)))
# E: header restriction
for lv in lvls(18):
    k = U(3.0, 6.0); add('e_header', ['ft'], 'k=%.1f' % k, noisy(physics(lv, hdr_k=k)))
# extra classes: receiver, regulator, sensor
for lv in lvls(12):
    add('x_receiver', ['fr'], 'drain-fail', noisy(physics(lv, cyc_f=U(2.2, 3.5), drain_f=U(0.0, 0.1))))
for i, lv in enumerate(lvls(18)):
    if i % 2 == 0: add('x_regulator', ['fv'], 'under', noisy(physics(lv, reg_under=U(0.4, 0.9))))
    else: add('x_regulator', ['fv'], 'over', noisy(physics(lv, reg_over=U(0.4, 0.8))))
for i, lv in enumerate(lvls(18)):
    t = physics(lv); o = noisy(t)
    if i % 2 == 0:
        o['p_rec'] += rng.choice([-1, 1]) * U(0.5, 0.9)
        add('x_sensor', ['fs'], 'p_rec drift', o, drop=(('p_rec_b',) if i % 6 == 0 else ()))
    else:
        o['m_use'] *= (1 - U(0.20, 0.35)); add('x_sensor', ['fs'], 'm_use under-read', o)
# F: multiple faults
PAIRS = [('fl','ff'),('fl','fc'),('ff','fd'),('fd','ft'),('fl','fv'),('fc','ff'),('fr','fl'),('fr','fd')]
def multi(fs, lv):
    q = {}
    if 'fl' in fs: q['lam'] = U(0.18, 0.25)
    if 'fc' in fs: q.update(comp_params())
    if 'ff' in fs: q['filter_k'] = U(3.0, 5.0)
    if 'fd' in fs:
        if rng.random() < 0.5: q['dew_add'] = U(9, 18)
        else: q['dryer_k'] = U(2.5, 4.0)
    if 'ft' in fs: q['hdr_k'] = U(3.5, 6.0)
    if 'fv' in fs: q['reg_over'] = U(0.4, 0.8)
    if 'fr' in fs: q.update(cyc_f=U(2.2, 3.0), drain_f=U(0.0, 0.1))
    return q
for fs in PAIRS:
    for j in range(4):
        lv = ['low', 'nom'][j % 2] if ('fc' in fs and 'fl' in fs) else lvls(4)[j]
        add('f_multi', sorted(fs), '+'.join(fs), noisy(physics(lv, **multi(fs, lv))))
for fs in [('fl','ff','fd')] * 2:
    add('f_multi', sorted(fs), '+'.join(fs), noisy(physics('nom', **multi(fs, 'nom'))))
# G: imperfect evidence
DROPPABLE = ['l_a','p_sh','t_d','v_rms','cyc','c_water','p_use','t_amb','p_dis']
KEEP = {'fl': ['m_in','m_use'], 'fc': ['m_in','load'], 'ff': ['dp_filter','m_in'], 'fd': ['t_dew'],
        'ft': ['p_rec','p_rec_b','dp_dryer','dp_filter','p_hdr','m_in']}
for i in range(15):
    f = ['fl','fc','ff','fd','ft'][i % 5]; lv = lvls(15)[i]
    q = {'fl': dict(lam=U(0.18, 0.26)), 'fc': dict(cap_f=U(0.72, 0.85), sp_f=U(1.15, 1.3), td_rise=U(11, 18)),
         'ff': dict(filter_k=U(3, 6)), 'fd': dict(dew_add=U(9, 18)), 'ft': dict(hdr_k=U(3.5, 6))}[f]
    dr = rng.sample(DROPPABLE, rng.choice([2, 3, 4]))
    if f == 'fc': dr = list(set(dr) | {'p_sh', 't_d', 'v_rms'})  # leave capacity as the only sign
    add('g_incomplete', [f], 'drop=%s' % ','.join(dr), noisy(physics(lv, **q)), drop=tuple(dr))
for i in range(15):   # noisy: sigma x2.5; faults moderate-high, normals mid-range
    if i < 5: add('g_noisy', ['fn'], 'noise2.5', noisy(physics(lvls(5)[i], lam=U(0.05, 0.08)), s=2.5))
    else:
        f = ['fl','ff','fd','ft','fc'][i % 5]
        q = {'fl': dict(lam=U(0.22, 0.28)), 'ff': dict(filter_k=U(4, 6)), 'fd': dict(dew_add=U(12, 20)),
             'ft': dict(hdr_k=U(4.5, 6)), 'fc': dict(cap_f=U(0.72, 0.8), sp_f=U(1.25, 1.35), td_rise=U(14, 20))}[f]
        add('g_noisy', [f], 'noise2.5', noisy(physics('nom', **q), s=2.5))
for i in range(3):     # conflicting: flow meter disagrees with ultrasonic
    o = noisy(physics('nom')); o['m_use'] *= (1 - U(0.22, 0.32))
    add('g_conflict', ['fs'], 'meter-vs-ultrasonic', o, drop=('cyc',) if i == 2 else ())
for i in range(3):     # conflicting: redundant receiver sensors disagree
    o = noisy(physics('high')); o['p_rec_b'] -= U(0.5, 0.8)
    add('g_conflict', ['fs'], 'p_rec_b drift', o)
for i in range(12):    # borderline: 80% of threshold (normal) / 125% (fault) on one indicator
    kind = ['leak','filter','header','dew','cap','cyc'][i % 6]; fault = i >= 6
    m = 1.25 if fault else 0.80
    if kind == 'leak':
        lam = TH['leak_frac_high'] * m + (0.0)
        add('g_borderline', ['fl'] if fault else ['fn'], 'leak x%.2f' % m,
            noisy(physics('nom', lam=lam, l_add=(18.0 if fault else 7.0))))
    elif kind == 'filter': add('g_borderline', ['ff'] if fault else ['fn'], 'filter x%.2f' % m,
        noisy(physics('nom', filter_k=TH['filter_ratio_high'] * m)))
    elif kind == 'header': add('g_borderline', ['ft'] if fault else ['fn'], 'header x%.2f' % m,
        noisy(physics('nom', hdr_k=TH['header_ratio_high'] * m)))
    elif kind == 'dew': add('g_borderline', ['fd'] if fault else ['fn'], 'dew x%.2f' % m,
        noisy(physics('nom', dew_add=TH['dewpoint_dev_high'] * m)))
    elif kind == 'cap':
        q = dict(cap_f=1 - TH['capacity_deficit'] * m)
        if fault: q.update(sp_f=1.15)
        add('g_borderline', ['fc'] if fault else ['fn'], 'cap x%.2f' % m, noisy(physics('nom', **q)))
    else: add('g_borderline', ['fr'] if fault else ['fn'], 'cyc x%.2f' % m,
        noisy(physics('nom', cyc_f=TH['cycle_ratio_high'] * m, drain_f=(0.1 if fault else 1.0))))

def check():
    """Dataset-vs-threshold consistency (a mirror of the key indicators, NOT the expert system)."""
    bad = 0; n = 0
    for c in CASES:
        if not c['full'] or c['group'] in ('g_noisy', 'g_borderline'): continue
        o = c['obs']; n += 1
        m = o['m_in'] / 12.0; K = m * m
        ind = dict(
            leak=(o['m_in'] - o['m_use']) / o['m_in'] > TH['leak_frac_high'] and o['l_a'] > TH['ultrasonic_high_db'],
            filt=o['dp_filter'] / (0.15 * K) > TH['filter_ratio_high'],
            dryer=(o['dp_dryer'] / (0.20 * K) > TH['dryer_dp_ratio_high']) or (o['t_dew'] - 3 > TH['dewpoint_dev_high']),
            hdr=((o['p_rec_b'] - o['dp_dryer'] - o['dp_filter'] - o['p_hdr']) / (0.25 * K) > TH['header_ratio_high']),
            cap=(20 - o['m_in'] / o['load']) / 20 > TH['capacity_deficit'],
            cyc=o['cyc'] > 12 * TH['cycle_ratio_high'] and o['c_water'] < TH['drain_ratio_low'],
            reg=abs(o['p_set'] - o['p_use']) > TH['reg_error_bar'] and
                (o['p_hdr'] >= o['p_set'] + TH['supply_margin_bar'] or o['p_use'] > o['p_set']),
            sens=abs(o['p_rec'] - o['p_rec_b']) > TH['redundancy_tol_bar'])
        want = {'fl':'leak','ff':'filt','fd':'dryer','ft':'hdr','fc':'cap','fr':'cyc','fv':'reg','fs':'sens'}
        wanted = {want[f] for f in c['true'] if f in want}
        if c['group'] == 'x_sensor' and c['sev'] == 'm_use under-read': ind['sens'] = True; ind['leak'] = False
        if c['group'] == 'g_conflict' and 'meter' in c['sev']: ind['sens'] = True; ind['leak'] = False
        got = {k for k, v in ind.items() if v}
        if got != wanted:
            bad += 1; print('  MISMATCH', c['id'], c['group'], c['true'], 'wanted', sorted(wanted), 'got', sorted(got))
    print('check: %d complete-evidence cases examined, %d signature mismatches' % (n, bad))

def fmt(c):
    obs = ', '.join('%s=%.4f' % (k, v) for k, v in c['obs'].items())
    return "case(%s, %s, %s, [%s], '%s', 'synthetic:gen_dataset.py:seed%d;assumption:physics-v1', [%s], [%s])." % (
        c['id'], c['group'], c['split'], ','.join(c['true']), c['sev'], SEED, obs, ','.join(c['exp']))

if __name__ == '__main__':
    out = os.path.join(ROOT, 'data', 'cases.pl')
    with open(out, 'w') as f:
        f.write('%% cases.pl -- SYNTHETIC test cases (seed %d). Not measurements.\n' % SEED)
        f.write('%% case(Id,Group,Split,TrueFaults,Severity,Provenance,Obs,ExpectedActionFamilies)\n')
        for c in CASES: f.write(fmt(c) + '\n')
    from collections import Counter
    print('wrote %d cases ->' % len(CASES), out)
    print(dict(Counter(c['group'] for c in CASES)))
    print(dict(Counter(c['split'] for c in CASES)))
    if '--check' in sys.argv: check()
