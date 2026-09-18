from pathlib import Path
import math, random, struct, wave

ROOT = Path("relic_v05/assets")
AUDIO = ROOT / "audio"
VISUAL = ROOT / "visual"
AUDIO.mkdir(parents=True, exist_ok=True)
VISUAL.mkdir(parents=True, exist_ok=True)

SR = 32000
DURATION = 28.0

TRACKS = [
    ("emerald_wander.wav", 0, 196.00, 0.16),
    ("moonlit_rift.wav", 1, 164.81, 0.17),
    ("crystal_depths.wav", 2, 220.00, 0.15),
    ("ashen_boss.wav", 3, 146.83, 0.18),
    ("astral_origin.wav", 4, 246.94, 0.16),
]

def clamp16(x):
    return max(-32767, min(32767, int(x)))

for filename, seed, root, noise_amt in TRACKS:
    rnd = random.Random(9000 + seed)
    notes = [1.0, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2.0]
    chord_seq = [
        [1.0, 5/4, 3/2],
        [4/3, 5/3, 2.0],
        [3/2, 15/8, 9/4],
        [5/4, 3/2, 15/8],
    ]
    frames = bytearray()
    phase_l = phase_r = 0.0
    low_phase = 0.0
    noise_state_l = noise_state_r = 0.0
    total = int(SR * DURATION)
    for i in range(total):
        t = i / SR
        bar = int(t / 4.0)
        chord = chord_seq[(bar + seed) % len(chord_seq)]
        beat = (t * 2.0) % 1.0
        pulse = math.exp(-beat * 5.0)
        pad = 0.0
        for n, ratio in enumerate(chord):
            f = root * ratio * (0.5 if seed in (1, 3) else 1.0)
            pad += math.sin(2*math.pi*f*t + n*0.7) * 0.32
            pad += math.sin(2*math.pi*f*0.5*t + n*1.1) * 0.18
        melody_idx = int(t * (1.5 + seed*0.08)) % len(notes)
        mf = root * notes[(melody_idx + bar) % len(notes)]
        melody = math.sin(2*math.pi*mf*t + math.sin(t*0.7)*0.8) * (0.23 + 0.10*pulse)
        bassf = root * 0.25 * chord[0]
        bass = math.sin(2*math.pi*bassf*t) * (0.30 + 0.18*pulse)
        kick = math.sin(2*math.pi*(55 + 25*(1-beat))*t) * pulse * (0.18 if seed != 1 else 0.10)
        raw_l = rnd.uniform(-1, 1)
        raw_r = rnd.uniform(-1, 1)
        noise_state_l = noise_state_l*0.82 + raw_l*0.18
        noise_state_r = noise_state_r*0.82 + raw_r*0.18
        wind = (noise_state_l + noise_state_r) * 0.5 * noise_amt
        shimmer = math.sin(2*math.pi*(root*4.0)*t + math.sin(t*1.7)*2.0) * 0.035
        base = (pad + melody + bass + kick + wind + shimmer) * 0.34
        pan = math.sin(t*0.23 + seed) * 0.12
        left = base * (1.0-pan) + noise_state_l*0.028
        right = base * (1.0+pan) + noise_state_r*0.028
        frames += struct.pack("<hh", clamp16(left*32767), clamp16(right*32767))
    with wave.open(str(AUDIO / filename), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)

SFX = [
    ("loot_burst.wav", 1.1, 660, 0.20),
    ("legendary_drop.wav", 1.8, 880, 0.28),
    ("boss_intro.wav", 2.1, 110, 0.35),
    ("forge_hit.wav", 0.7, 180, 0.24),
    ("awaken.wav", 1.6, 520, 0.30),
    ("evolve.wav", 2.0, 740, 0.32),
    ("skill_leaf.wav", 0.75, 980, 0.18),
    ("skill_star.wav", 1.0, 1240, 0.20),
    ("garden_harvest.wav", 0.9, 440, 0.15),
    ("ui_confirm.wav", 0.28, 900, 0.10),
]
for idx, (filename, dur, freq, noise) in enumerate(SFX):
    rnd = random.Random(12000 + idx)
    frames = bytearray()
    total = int(SR * dur)
    for i in range(total):
        t = i / SR
        env = max(0.0, 1.0 - t/dur)
        sweep = freq * (1.0 + 0.7*(1-env))
        sig = math.sin(2*math.pi*sweep*t) * env
        sig += math.sin(2*math.pi*sweep*0.5*t) * env*0.45
        sig += rnd.uniform(-1,1)*noise*env
        if "boss" in filename:
            sig += math.sin(2*math.pi*55*t)*env*0.9
        v = clamp16(sig * 32767 * 0.38)
        frames += struct.pack("<hh", v, v)
    with wave.open(str(AUDIO / filename), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)

# Rich procedural visual overlays / atlases.
from PIL import Image, ImageDraw, ImageFilter
palettes = [
    ((125,220,135),(82,150,90),(239,215,140)),
    ((111,134,203),(63,106,104),(80,102,93)),
    ((90,101,158),(78,72,118),(123,104,167)),
    ((176,111,103),(99,71,68),(122,90,79)),
    ((199,233,255),(115,148,163),(230,242,245)),
    ((121,197,200),(84,127,112),(179,165,126)),
    ((85,80,142),(77,85,126),(117,104,157)),
    ((255,215,168),(156,122,69),(201,142,82)),
]
for idx, (sky, land, ground) in enumerate(palettes):
    rnd = random.Random(15000+idx)
    im = Image.new("RGB",(2048,2048),sky)
    d = ImageDraw.Draw(im,"RGBA")
    for y in range(2048):
        k=y/2048
        col=tuple(int(sky[c]*(1-k)+ground[c]*k) for c in range(3))
        d.line((0,y,2048,y),fill=col+(255,))
    for layer in range(4):
        base_y=950+layer*180
        pts=[(0,2048)]
        for x in range(0,2150,120):
            yy=base_y+rnd.randint(-110,80)
            pts.append((x,yy))
        pts += [(2048,2048)]
        alpha=210-layer*25
        lc=tuple(max(0,min(255,land[c]-layer*8)) for c in range(3))
        d.polygon(pts,fill=lc+(alpha,))
    for _ in range(180):
        x=rnd.randint(0,2047); y=rnd.randint(400,1700)
        r=rnd.randint(3,20)
        accent=((80+idx*23)%255,(180+idx*17)%255,(130+idx*31)%255,90)
        d.ellipse((x-r,y-r,x+r,y+r),fill=accent)
    for _ in range(45):
        x=rnd.randint(0,2047); y=rnd.randint(850,1700)
        h=rnd.randint(55,180)
        d.line((x,y,x,y-h),fill=(45,92,55,190),width=rnd.randint(2,6))
        d.ellipse((x-15,y-h-12,x+15,y-h+12),fill=(80+idx*12,150,85+idx*8,180))
    im=im.filter(ImageFilter.GaussianBlur(radius=0.6))
    im.save(VISUAL / f"biome_overlay_{idx}.png", optimize=False)

# Particle / rune atlas.
atlas=Image.new("RGBA",(2048,2048),(0,0,0,0))
d=ImageDraw.Draw(atlas,"RGBA")
for i in range(64):
    x=(i%8)*256+128; y=(i//8)*256+128
    rnd=random.Random(20000+i)
    col=(100+rnd.randint(0,155),100+rnd.randint(0,155),100+rnd.randint(0,155),230)
    for r in range(96,4,-10):
        a=max(8,220-r)
        d.ellipse((x-r,y-r,x+r,y+r),outline=col[:3]+(a,),width=3)
    for j in range(6):
        ang=2*math.pi*j/6+rnd.random()*0.4
        x2=x+math.cos(ang)*90; y2=y+math.sin(ang)*90
        d.line((x,y,x2,y2),fill=col,width=3)
atlas.save(VISUAL / "rune_atlas.png", optimize=False)

print("Generated Colossus asset pack")


# 2K boss/evolution aura atlases. These are used at runtime for large encounters
# and keep the visual pack substantial rather than padding the APK.
for idx in range(4):
    rnd = random.Random(30000 + idx)
    im = Image.new("RGBA", (2048, 2048), (0,0,0,0))
    d = ImageDraw.Draw(im, "RGBA")
    cx = cy = 1024
    base = [
        (120,210,255), (225,125,255), (255,175,90), (255,235,135)
    ][idx]
    for ring in range(18):
        r = 120 + ring * 48
        alpha = max(18, 170 - ring*7)
        d.ellipse((cx-r,cy-r,cx+r,cy+r), outline=base+(alpha,), width=4+(ring%4))
    for ray in range(96):
        a = 2*math.pi*ray/96 + idx*0.17
        inner = 240 + rnd.randint(-30,30)
        outer = 760 + rnd.randint(-110,130)
        x1 = cx + math.cos(a)*inner
        y1 = cy + math.sin(a)*inner
        x2 = cx + math.cos(a)*outer
        y2 = cy + math.sin(a)*outer
        d.line((x1,y1,x2,y2), fill=base+(rnd.randint(35,115),), width=rnd.randint(2,7))
    for star in range(420):
        x=rnd.randint(160,1888); y=rnd.randint(160,1888)
        rr=rnd.randint(2,9)
        d.ellipse((x-rr,y-rr,x+rr,y+rr), fill=base+(rnd.randint(40,180),))
    # central sigil
    pts=[]
    for j in range(16):
        a=-math.pi/2 + j*math.pi/8
        rr=360 if j%2==0 else 185
        pts.append((cx+math.cos(a)*rr,cy+math.sin(a)*rr))
    d.polygon(pts, outline=base+(220,))
    im = im.filter(ImageFilter.GaussianBlur(radius=0.35))
    im.save(VISUAL / f"boss_aura_{idx}.png", optimize=False)


# High-detail 2K magic/noise maps used by world events, boss phases and
# high-evolution aura overlays. These are intentionally high-frequency visual data.
for idx in range(4):
    rnd = random.Random(41000 + idx)
    raw = rnd.randbytes(2048 * 2048)
    noise = Image.frombytes("L", (2048, 2048), raw)
    # Blend a second shifted noise layer to produce usable cloud/rune turbulence.
    raw2 = rnd.randbytes(2048 * 2048)
    noise2 = Image.frombytes("L", (2048, 2048), raw2).filter(ImageFilter.GaussianBlur(radius=3.0 + idx*0.2))
    mixed = Image.blend(noise, noise2, 0.34)
    mixed.save(VISUAL / f"magic_noise_{idx}.png", optimize=False)
