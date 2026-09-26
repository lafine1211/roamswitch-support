import json, os, random, collections, base64
from ransom_shape_measure import feats
random.seed(11)
legit = json.load(open('legit.json'))
texts=[]
for r in legit:
    if r['H'] < 5.5 and r['b64_frac'] < 0.999:
        try: t=open(r['path'],'rb').read(262144)
        except Exception: continue
        if len(t) < 8192: continue
        t = (t * (262144//len(t)+1))[:262144]      # documents of ordinary size: fill the 256KB sample
        texts.append(t)
        if len(texts)>=300: break
rnd=os.urandom
def full(b): return rnd(len(b))
def p16(b):
    o=bytearray(b)
    for i in range(0,len(o)-15,32): o[i:i+16]=rnd(16)
    return bytes(o)
def alt4k(b):
    o=bytearray(b)
    for i in range(0,len(o)-4095,8192): o[i:i+4096]=rnd(4096)
    return bytes(o)
def sparse4k(b):
    o=bytearray(b)
    for i in range(0,len(o)-4095,16384): o[i:i+4096]=rnd(4096)
    return bytes(o)
def head(b):   # first 64KB encrypted, rest untouched (header-only style)
    return rnd(65536)+b[65536:]
def b64(b): return base64.encodebytes(rnd(len(b)*3//4))
sims={'full':full,'16/32':p16,'4KB交互':alt4k,'1/4区間':sparse4k,'先頭64KB':head,'Base64':b64}
simf={k:[feats(fn(t)) for t in texts] for k,fn in sims.items()}
R0=lambda f: f['H']>=7.92
rules={
 'A 区間: 高区間25〜85%かつ高↔低の切替>=4':      lambda f: f['nch']>=16 and 0.20<=f['hi_frac']<=0.85 and f['trans']>=4,
 'B 先頭区間: 連続>=8高区間かつ全体H<7.92':       lambda f: f['run']>=8 and f['H']<7.92,
 'C 16Bの交互>=0.5':                             lambda f: f['alt16']>=0.5,
 'D Base64の一様':                               lambda f: f['b64_frac']>0.99 and f['b64_chi'] is not None and f['b64_chi']<2.0 and 5.7<=f['H']<=6.05,
}
def ext(p):
    e=os.path.splitext(p)[1].lower(); return e or '(なし)'
print(f"合法 {len(legit)} 件、模擬の入力 {len(texts)} 件(256KBに拡張)")
print(f"R0(現行, H>=7.92): 合法 {sum(1 for r in legit if R0(r))} 件 ({100*sum(1 for r in legit if R0(r))/len(legit):.2f}%); 模擬の検知 "+", ".join(f"{k}:{100*sum(1 for f in v if R0(f))/len(v):.0f}%" for k,v in simf.items()))
print()
for name,rule in rules.items():
    newfp=[r for r in legit if rule(r) and not R0(r)]
    allfp=[r for r in legit if rule(r)]
    tp={k:sum(1 for f in v if rule(f))/len(v) for k,v in simf.items()}
    print(f"{name}\n   合法: 全体 {len(allfp)} 件({100*len(allfp)/len(legit):.2f}%)、うちR0では検知されない新しい誤検知 {len(newfp)} 件({100*len(newfp)/len(legit):.2f}%)")
    print("   模擬の検知: "+", ".join(f"{k}:{100*v:.0f}%" for k,v in tp.items()))
    top=collections.Counter(ext(r['path']) for r in newfp).most_common(6)
    if top: print("   新しい誤検知の拡張子:", ", ".join(f"{e}:{c}" for e,c in top))
