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


# v0.7 VISUAL OVERKILL PACK
# 2K high-frequency effect fields that are actually sampled/rendered in-game.
VFX = VISUAL / "v07"
VFX.mkdir(parents=True, exist_ok=True)

# Six chromatic energy fields: boss phases, world events, evolutions, loot cinematics.
for idx in range(3):
    rnd = random.Random(51000 + idx)
    w = h = 2048
    # RGB high-frequency field with directional streaks + turbulence.
    # Generate the full RGB field in one deterministic block instead of
    # iterating through 4.2 million pixels in Python.
    raw = rnd.randbytes(w*h*3)
    im = Image.frombytes("RGB",(w,h),raw)
    d = ImageDraw.Draw(im,"RGBA")
    cx = cy = 1024
    for ray in range(180):
        a = 2*math.pi*ray/180.0 + idx*0.11
        inner = 120 + rnd.randint(0,220)
        outer = 800 + rnd.randint(-120,180)
        col = (120+((idx*29)%120), 150+((idx*17)%95), 255, rnd.randint(24,70))
        d.line((cx+math.cos(a)*inner,cy+math.sin(a)*inner,
                cx+math.cos(a)*outer,cy+math.sin(a)*outer),
               fill=col,width=rnd.randint(1,6))
    im.save(VFX / f"energy_field_{idx}.png", optimize=False)

# Two premium 4x4 animated VFX atlases. Each cell is a different impact/ring frame.
for atlas_idx in range(2):
    rnd = random.Random(56000 + atlas_idx)
    im = Image.new("RGBA",(2048,2048),(0,0,0,0))
    d = ImageDraw.Draw(im,"RGBA")
    for frame in range(16):
        fx = (frame%4)*512
        fy = (frame//4)*512
        cx = fx+256
        cy = fy+256
        t = frame/15.0
        base = [(105,235,255),(255,120,224)][atlas_idx]
        # Animated shockwave rings.
        for ring in range(10):
            r = 34 + ring*18 + int(t*110)
            alpha = max(10,190-ring*15-int(t*75))
            d.ellipse((cx-r,cy-r,cx+r,cy+r),outline=base+(alpha,),width=2+(ring%4))
        # Radial shards.
        for shard in range(48):
            a = 2*math.pi*shard/48.0 + t*0.85 + rnd.random()*0.05
            r1 = 45 + rnd.randint(0,55) + int(t*60)
            r2 = r1 + rnd.randint(20,110)
            col = (base[0],base[1],base[2],rnd.randint(45,180))
            d.line((cx+math.cos(a)*r1,cy+math.sin(a)*r1,
                    cx+math.cos(a)*r2,cy+math.sin(a)*r2),fill=col,width=rnd.randint(2,7))
        # Spark cloud.
        for _ in range(120):
            a = rnd.random()*2*math.pi
            rr = rnd.random()*(170+90*t)
            x = cx+math.cos(a)*rr
            y = cy+math.sin(a)*rr
            sr = rnd.randint(1,6)
            d.ellipse((x-sr,y-sr,x+sr,y+sr),fill=base+(rnd.randint(35,180),))
    im.save(VFX / f"impact_atlas_{atlas_idx}.png", optimize=False)

# Loot beam / rarity pillar maps with dense procedural detail.
for idx in range(2):
    rnd = random.Random(59000 + idx)
    im = Image.new("RGBA",(2048,2048),(0,0,0,0))
    d = ImageDraw.Draw(im,"RGBA")
    center = 1024
    base = [(255,226,110),(194,126,255)][idx]
    for x in range(2048):
        dx = abs(x-center)/1024.0
        a = int(max(0, 150*(1-dx**0.7)))
        d.line((x,0,x,2048),fill=base+(a,))
    for _ in range(1200):
        x = int(rnd.gauss(center,360))
        y = rnd.randrange(2048)
        if 0 <= x < 2048:
            rr = rnd.randint(1,8)
            d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=(255,255,255,rnd.randint(35,180)))
    for y in range(120,2048,120):
        d.line((250,y,1798,y+rnd.randint(-30,30)),fill=base+(rnd.randint(15,45),),width=rnd.randint(1,5))
    im.save(VFX / f"loot_beam_{idx}.png", optimize=False)

# A dense 2K foreground sparkle/particle layer for high-evolution biomes.
rnd = random.Random(62000)
im = Image.new("RGBA",(2048,2048),(0,0,0,0))
d = ImageDraw.Draw(im,"RGBA")
for _ in range(5200):
    x=rnd.randrange(2048); y=rnd.randrange(2048)
    rr=rnd.randint(1,5)
    hue=rnd.randrange(4)
    cols=[(130,240,255),(255,210,110),(220,130,255),(130,255,170)]
    col=cols[hue]
    d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=col+(rnd.randint(25,165),))
im.save(VFX / "spark_field.png", optimize=False)


# v0.8 ULTRA ASSET REBUILD
# High-resolution content is streamed in-game. Only the current biome/boss/cinematic
# is loaded, so APK size can grow without forcing every texture into RAM.
ULTRA = VISUAL / "v08"
ULTRA.mkdir(parents=True, exist_ok=True)

ultra_palettes = [
    ((98,189,228),(65,135,105),(41,83,71),(245,212,113)),
    ((91,113,184),(48,75,98),(32,53,68),(169,219,255)),
    ((102,77,153),(61,54,101),(36,39,72),(210,157,255)),
    ((197,91,73),(103,54,48),(55,38,40),(255,189,102)),
    ((178,226,245),(101,155,178),(61,104,124),(232,250,255)),
    ((70,157,161),(49,109,100),(28,74,72),(173,255,218)),
    ((64,55,120),(47,42,92),(28,25,61),(185,139,255)),
    ((236,169,82),(142,94,56),(82,58,51),(255,232,145)),
]

# 3K premium biome plates.
for idx, (sky, mid, low, accent) in enumerate(ultra_palettes):
    rnd = random.Random(71000 + idx)
    w = h = 3072
    im = Image.new("RGB",(w,h),sky)
    d = ImageDraw.Draw(im,"RGBA")

    # cinematic vertical gradient
    for y in range(0,h,4):
        t = y/(h-1)
        if t < 0.56:
            u=t/0.56
            col=tuple(int(sky[k]*(1-u)+mid[k]*u) for k in range(3))
        else:
            u=(t-0.56)/0.44
            col=tuple(int(mid[k]*(1-u)+low[k]*u) for k in range(3))
        d.rectangle((0,y,w,y+5),fill=col+(255,))

    # sun/moon + volumetric rays
    sun=(2350,620)
    for rr in range(420,40,-28):
        a=max(4,int(54*(1-rr/450)))
        d.ellipse((sun[0]-rr,sun[1]-rr,sun[0]+rr,sun[1]+rr),fill=accent+(a,))
    d.ellipse((sun[0]-95,sun[1]-95,sun[0]+95,sun[1]+95),fill=accent+(220,))
    for ray in range(28):
        a = -0.75 + ray*0.055 + rnd.uniform(-0.02,0.02)
        length=rnd.randint(950,1900)
        width=rnd.randint(30,95)
        x2=sun[0]+math.cos(a)*length
        y2=sun[1]+math.sin(a)*length
        d.line((sun[0],sun[1],x2,y2),fill=accent+(rnd.randint(7,20),),width=width)

    # deep layered mountains and cliffs
    for layer in range(7):
        base_y=1150+layer*190
        pts=[(0,h)]
        step=170-layer*8
        for x in range(-120,w+180,step):
            peak=base_y+rnd.randint(-320+layer*22,150)
            pts.append((x,peak))
        pts.append((w,h))
        fac=0.80-layer*0.055
        lc=tuple(max(0,min(255,int(mid[k]*fac))) for k in range(3))
        d.polygon(pts,fill=lc+(235-layer*15,))

    # waterfalls / magical streams
    for stream in range(4):
        x=450+stream*680+rnd.randint(-100,100)
        top=920+rnd.randint(-100,180)
        width=rnd.randint(34,72)
        d.rectangle((x-width,top,x+width,2400),fill=(172,230,255,46))
        d.rectangle((x-width//3,top,x+width//3,2400),fill=(232,252,255,92))

    # trees, crystals, glowing plants
    for _ in range(170):
        x=rnd.randint(20,w-20)
        y=rnd.randint(1400,2860)
        scale=rnd.uniform(0.55,1.8)
        trunk=(x-rnd.randint(8,20),y-int(90*scale),x+rnd.randint(8,20),y)
        d.rectangle(trunk,fill=(45,50,39,160))
        crown=(x-int(65*scale),y-int(180*scale),x+int(65*scale),y-int(60*scale))
        leaf_col=(max(30,mid[0]+rnd.randint(-25,25)),max(45,mid[1]+rnd.randint(-20,35)),max(45,mid[2]+rnd.randint(-20,35)),150)
        d.ellipse(crown,fill=leaf_col)
    for _ in range(95):
        x=rnd.randint(0,w); y=rnd.randint(1500,2920)
        hh=rnd.randint(25,130)
        col=accent+(rnd.randint(75,170),)
        d.polygon([(x,y-hh),(x-rnd.randint(6,24),y),(x+rnd.randint(6,24),y)],fill=col)

    # spark depth
    for _ in range(2600):
        x=rnd.randrange(w); y=rnd.randrange(450,h)
        rr=rnd.randint(1,7)
        alpha=rnd.randint(12,90)
        d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=accent+(alpha,))

    # subtle high-frequency texture to prevent flat/cheap rendering and retain detail
    noise=Image.frombytes("RGB",(w,h),rnd.randbytes(w*h*3))
    im=Image.blend(im,noise,0.048)
    im.save(ULTRA / f"ultra_biome_{idx}.png", optimize=False)

# Eight premium boss-stage backplates, one per biome family.
for idx in range(8):
    rnd=random.Random(76000+idx)
    w=h=2048
    base=ultra_palettes[idx][2]
    accent=ultra_palettes[idx][3]
    im=Image.new("RGB",(w,h),base)
    d=ImageDraw.Draw(im,"RGBA")
    cx=cy=1024

    # textured cosmic field
    noise=Image.frombytes("RGB",(w,h),rnd.randbytes(w*h*3))
    im=Image.blend(im,noise,0.07)
    d=ImageDraw.Draw(im,"RGBA")
    for ring in range(26):
        rr=135+ring*34
        alpha=max(8,125-ring*4)
        d.ellipse((cx-rr,cy-rr,cx+rr,cy+rr),outline=accent+(alpha,),width=2+(ring%5))
    for ray in range(160):
        a=2*math.pi*ray/160 + idx*0.07
        r1=rnd.randint(120,360)
        r2=rnd.randint(620,1000)
        d.line((cx+math.cos(a)*r1,cy+math.sin(a)*r1,cx+math.cos(a)*r2,cy+math.sin(a)*r2),
               fill=accent+(rnd.randint(10,70),),width=rnd.randint(1,9))
    # large runic fragments
    for _ in range(120):
        x=rnd.randint(100,1948); y=rnd.randint(100,1948)
        s=rnd.randint(14,90)
        d.polygon([(x,y-s),(x+s,y),(x,y+s),(x-s,y)],outline=accent+(rnd.randint(20,120),))
    im.save(ULTRA / f"boss_stage_{idx}.png", optimize=False)

# Skill / ultimate cinematic plates. Loaded only during the effect.
skill_colors=[
    (111,245,151),(104,205,255),(142,231,255),(255,225,105),
    (255,112,185),(194,122,255),(255,132,93),(255,244,181)
]
for idx,col in enumerate(skill_colors):
    rnd=random.Random(80000+idx)
    w=h=1536
    im=Image.new("RGB",(w,h),(12,12,22))
    noise=Image.frombytes("RGB",(w,h),rnd.randbytes(w*h*3))
    im=Image.blend(im,noise,0.10)
    d=ImageDraw.Draw(im,"RGBA")
    cx=cy=768
    for ring in range(18):
        rr=70+ring*36
        d.ellipse((cx-rr,cy-rr,cx+rr,cy+rr),outline=col+(max(12,170-ring*8),),width=3+(ring%6))
    for ray in range(120):
        a=2*math.pi*ray/120+rnd.uniform(-0.025,0.025)
        r1=rnd.randint(40,180)
        r2=rnd.randint(430,760)
        d.line((cx+math.cos(a)*r1,cy+math.sin(a)*r1,cx+math.cos(a)*r2,cy+math.sin(a)*r2),
               fill=col+(rnd.randint(25,130),),width=rnd.randint(2,8))
    for _ in range(850):
        x=rnd.randrange(w); y=rnd.randrange(h); rr=rnd.randint(1,8)
        d.ellipse((x-rr,y-rr,x+rr,y+rr),fill=col+(rnd.randint(25,150),))
    im.save(ULTRA / f"cinematic_{idx}.png", optimize=False)

# High-resolution UI material surfaces used on loot/core/forge panels.
for idx in range(4):
    rnd=random.Random(85000+idx)
    w=h=2048
    base=[(28,31,40),(31,39,47),(43,31,52),(48,38,26)][idx]
    im=Image.new("RGB",(w,h),base)
    noise=Image.frombytes("RGB",(w,h),rnd.randbytes(w*h*3))
    im=Image.blend(im,noise,0.055)
    d=ImageDraw.Draw(im,"RGBA")
    accent=[(113,210,255),(122,243,183),(218,139,255),(255,206,119)][idx]
    for y in range(0,h,128):
        d.line((0,y,w,y+rnd.randint(-18,18)),fill=accent+(18,),width=rnd.randint(1,4))
    for x in range(0,w,128):
        d.line((x,0,x+rnd.randint(-18,18),h),fill=accent+(14,),width=rnd.randint(1,4))
    for ring in range(12):
        rr=220+ring*70
        d.ellipse((1024-rr,1024-rr,1024+rr,1024+rr),outline=accent+(max(7,55-ring*4),),width=2)
    im.save(ULTRA / f"ui_surface_{idx}.png", optimize=False)

print("Generated v0.8 Ultra Asset Rebuild pack")
