import os, sys, math, random, collections, base64, json
from multiprocessing import Pool
random.seed(7)
CH = 4096
def ent(b):
    if not b: return 0.0
    c = collections.Counter(b); n = len(b)
    return -sum(v/n*math.log2(v/n) for v in c.values())
B64 = set(b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=\r\n")
def feats(b):
    """b: up to 256KB sample of a file."""
    f = {}
    f['H'] = ent(b)
    chunks = [b[i:i+CH] for i in range(0, len(b) - CH + 1, CH)]
    ce = [ent(c) for c in chunks]
    hi = [e >= 7.9 for e in ce]
    f['nch'] = len(ce)
    f['hi_frac'] = sum(hi)/len(ce) if ce else 0.0
    run = best = 0
    for h in hi:
        run = run + 1 if h else 0; best = max(best, run)
    f['run'] = best
    f['trans'] = sum(1 for i in range(len(hi)-1) if hi[i] != hi[i+1])
    blocks = [b[i:i+16] for i in range(0, min(len(b), 16384) - 15, 16)]
    be = [len(set(x)) for x in blocks]
    st = ['R' if e >= 14 else ('T' if e <= 12 else 'M') for e in be]
    alt = sum(1 for i in range(len(st)-1) if {st[i], st[i+1]} == {'R','T'})
    f['alt16'] = alt/max(1, len(st)-1)
    # base64-looking: all bytes in alphabet, and 64-symbol chi-square uniformity
    if b:
        inb = sum(1 for x in b if x in B64)/len(b)
        f['b64_frac'] = inb
        if inb > 0.99:
            sym = [x for x in b if x not in b"\r\n="]
            cnt = collections.Counter(sym); n = len(sym); exp = n/64
            f['b64_chi'] = sum((cnt.get(s,0)-exp)**2/exp for s in B64 - set(b"\r\n="))/63
        else: f['b64_chi'] = None
    return f

def sample(path):
    try:
        with open(path,'rb') as fh:
            return fh.read(262144)
    except Exception: return None

def legit(path):
    b = sample(path)
    if b is None or len(b) < 8192: return None
    f = feats(b); f['path'] = path; return f

def gather(roots, per_dir=25, cap=30000):
    out=[]
    for r in roots:
        for d, dirs, files in os.walk(r, followlinks=False):
            dirs[:] = [x for x in dirs if not x.startswith('.git') or x=='.git'][:60]
            random.shuffle(files)
            for fn in files[:per_dir]:
                p = os.path.join(d, fn)
                try:
                    if os.path.islink(p) or os.path.getsize(p) < 8192: continue
                except OSError: continue
                out.append(p)
            if len(out) > cap: return out
    return out

if __name__ == '__main__':
    roots = ['/usr', '/System/Library', '/Applications', os.path.expanduser('~/Dev'), '/Library']
    paths = gather(roots)
    random.shuffle(paths); paths = paths[:20000]
    with Pool(8) as p: res = [r for r in p.map(legit, paths, chunksize=64) if r]
    json.dump(res, open('legit.json','w'))
    print('legit files measured:', len(res))
