package com.bassforge.eq;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.media.audiofx.AudioEffect;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

public class V7Activity extends Activity {
    private static final int BG = Color.rgb(5, 6, 9);
    private static final int SURFACE = Color.rgb(15, 17, 23);
    private static final int SURFACE_2 = Color.rgb(22, 25, 34);
    private static final int TEXT = Color.rgb(246, 247, 250);
    private static final int MUTED = Color.rgb(147, 153, 168);
    private static final int RED = Color.rgb(255, 38, 62);
    private static final int GREEN = Color.rgb(70, 224, 144);
    private static final int BLUE = Color.rgb(104, 150, 255);

    private static final String[] BAND_NAMES = {"31", "62", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"};
    private static final String[] INT_KEYS = {
            "bass","loudness","sub","punch","width","clarity","treble","sub_focus","punch_focus",
            "vocal","quality","intensity","warmth","presence","low_mid_cut","gain_ceiling",
            "sonic_strength","extreme_strength","fx_depth","fx_tight","fx_impact","fx_air","fx_smooth"
    };
    private static final int[] INT_DEFAULTS = {
            68,16,55,45,20,55,40,35,50,55,1,100,35,40,35,5,78,88,62,58,48,42,52
    };
    private static final String[] BOOL_KEYS = {
            "dynamic_bass","auto_gain","sonic_core","curve_smoothing","auto_clean","bass_definition",
            "clarity_restore","transient_focus","stereo_guard","adaptive_headroom","auto_profile",
            "extreme_bass","aurora_fx","fx_depth_on","fx_tight_on","fx_impact_on","fx_air_on","fx_smooth_on"
    };

    private SharedPreferences prefs;
    private LinearLayout page;
    private final List<TextView> navButtons = new ArrayList<>();
    private View glowLine;
    private TextView headerState;
    private final Handler uiHandler = new Handler(Looper.getMainLooper());
    private boolean glowHigh = false;

    private final Runnable glowPulse = new Runnable() {
        @Override public void run() {
            if (glowLine == null) return;
            glowHigh = !glowHigh;
            glowLine.animate().alpha(glowHigh ? 1f : 0.28f).setDuration(850).start();
            uiHandler.postDelayed(this, 900);
        }
    };

    interface Formatter { String format(int value); }

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        Window w = getWindow();
        w.setStatusBarColor(BG);
        w.setNavigationBarColor(BG);

        prefs = getSharedPreferences(BassService.PREFS, MODE_PRIVATE);
        initV7Defaults();

        if (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 701);
        }

        setContentView(buildShell());
        showPage("HOME");
        uiHandler.post(glowPulse);
    }

    @Override protected void onDestroy() {
        uiHandler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }

    private void initV7Defaults() {
        if (prefs.getBoolean("v7_defaults_applied", false)) return;
        prefs.edit()
                .putBoolean("aurora_fx", true)
                .putInt("fx_depth", 62)
                .putInt("fx_tight", 58)
                .putInt("fx_impact", 48)
                .putInt("fx_air", 42)
                .putInt("fx_smooth", 52)
                .putBoolean("fx_depth_on", true)
                .putBoolean("fx_tight_on", true)
                .putBoolean("fx_impact_on", true)
                .putBoolean("fx_air_on", true)
                .putBoolean("fx_smooth_on", true)
                .putBoolean("sonic_core", true)
                .putBoolean("auto_gain", true)
                .putBoolean("auto_clean", true)
                .putBoolean("bass_definition", true)
                .putBoolean("clarity_restore", true)
                .putBoolean("stereo_guard", true)
                .putBoolean("adaptive_headroom", true)
                .putBoolean("v7_defaults_applied", true)
                .apply();
    }

    private View buildShell() {
        LinearLayout shell = new LinearLayout(this);
        shell.setOrientation(LinearLayout.VERTICAL);
        shell.setBackgroundColor(BG);

        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(dp(18), dp(18), dp(18), dp(12));
        shell.addView(header, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout brand = new LinearLayout(this);
        brand.setOrientation(LinearLayout.VERTICAL);
        header.addView(brand, new LinearLayout.LayoutParams(0, -2, 1f));

        TextView title = txt("BASSFORGE", 28, TEXT, true);
        title.setLetterSpacing(0.08f);
        brand.addView(title);
        brand.addView(txt("V7 • AURORA FX", 11, RED, true), top(2));

        headerState = txt("", 11, GREEN, true);
        headerState.setGravity(Gravity.CENTER);
        headerState.setPadding(dp(10), dp(7), dp(10), dp(7));
        header.addView(headerState);
        refreshHeader();

        glowLine = new View(this);
        glowLine.setBackgroundColor(RED);
        LinearLayout.LayoutParams glowLp = new LinearLayout.LayoutParams(-1, dp(2));
        glowLp.setMargins(dp(18), 0, dp(18), 0);
        shell.addView(glowLine, glowLp);

        HorizontalScrollView navScroll = new HorizontalScrollView(this);
        navScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout nav = new LinearLayout(this);
        nav.setOrientation(LinearLayout.HORIZONTAL);
        nav.setPadding(dp(14), dp(10), dp(14), dp(8));
        navScroll.addView(nav);
        shell.addView(navScroll, new LinearLayout.LayoutParams(-1, -2));

        addNav(nav, "HOME");
        addNav(nav, "BASS");
        addNav(nav, "FX");
        addNav(nav, "EQ");
        addNav(nav, "PRESETS");
        addNav(nav, "SYSTEM");

        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(dp(16), dp(8), dp(16), dp(34));
        scroll.addView(page, new ScrollView.LayoutParams(-1, -2));
        shell.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1f));

        return shell;
    }

    private void addNav(LinearLayout row, String name) {
        TextView b = txt(name, 11, MUTED, true);
        b.setTag(name);
        b.setGravity(Gravity.CENTER);
        b.setPadding(dp(14), dp(9), dp(14), dp(9));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-2, -2);
        lp.setMargins(0, 0, dp(7), 0);
        row.addView(b, lp);
        navButtons.add(b);
        b.setOnClickListener(v -> showPage(name));
    }

    private void showPage(String name) {
        for (TextView b : navButtons) {
            boolean active = name.equals(String.valueOf(b.getTag()));
            b.setTextColor(active ? TEXT : MUTED);
            b.setBackground(round(active ? Color.rgb(63, 18, 29) : SURFACE, 14, active ? RED : Color.rgb(43, 47, 58), 1));
        }
        page.removeAllViews();
        if ("BASS".equals(name)) buildBassPage();
        else if ("FX".equals(name)) buildFxPage();
        else if ("EQ".equals(name)) buildEqPage();
        else if ("PRESETS".equals(name)) buildPresetsPage();
        else if ("SYSTEM".equals(name)) buildSystemPage();
        else buildHomePage();
    }

    private void buildHomePage() {
        hero("AURORA CONTROL CENTER", "Fast overview of the complete sound engine");

        LinearLayout engine = card();
        engine.setOrientation(LinearLayout.HORIZONTAL);
        engine.setGravity(Gravity.CENTER_VERTICAL);
        page.addView(engine, top(12));
        LinearLayout ec = new LinearLayout(this);
        ec.setOrientation(LinearLayout.VERTICAL);
        engine.addView(ec, new LinearLayout.LayoutParams(0, -2, 1f));
        ec.addView(txt("AUDIO ENGINE", 15, TEXT, true));
        TextView engineState = txt(engineStatus(), 12,
                prefs.getBoolean("engine_enabled", false) ? GREEN : MUTED, false);
        ec.addView(engineState, top(3));
        Switch power = styledSwitch(prefs.getBoolean("engine_enabled", false));
        engine.addView(power);
        power.setOnCheckedChangeListener((b, on) -> {
            prefs.edit().putBoolean("engine_enabled", on).apply();
            startEngine(on ? BassService.ACTION_START : BassService.ACTION_STOP);
            engineState.setText(on ? "ACTIVE • processing audio sessions" : "OFF • clean shutdown");
            engineState.setTextColor(on ? GREEN : MUTED);
            refreshHeader();
        });

        section("QUICK MODES");
        HorizontalScrollView qs = new HorizontalScrollView(this);
        qs.setHorizontalScrollBarEnabled(false);
        LinearLayout qr = new LinearLayout(this);
        qr.setOrientation(LinearLayout.HORIZONTAL);
        qs.addView(qr);
        page.addView(qs, top(8));
        action(qr, "STUDIO", () -> applyMode("studio"));
        action(qr, "DEEP", () -> applyMode("deep"));
        action(qr, "EXTREME CLEAN", () -> applyMode("extreme"));
        action(qr, "ARENA", () -> applyMode("arena"));
        action(qr, "GAMING", () -> applyMode("gaming"));
        action(qr, "NIGHT", () -> applyMode("night"));

        section("SIGNAL OVERVIEW");
        LinearLayout summary = card();
        summary.setOrientation(LinearLayout.VERTICAL);
        page.addView(summary, top(8));
        summary.addView(metricRow("Bass / Sub", prefs.getInt("bass",68) + "%  /  " + prefs.getInt("sub",55) + "%"));
        summary.addView(metricRow("Punch / Width", prefs.getInt("punch",45) + "%  /  " + prefs.getInt("width",20) + "%"), top(7));
        summary.addView(metricRow("SONIC CORE", prefs.getBoolean("sonic_core",true) ? prefs.getInt("sonic_strength",78) + "% • ON" : "OFF"), top(7));
        summary.addView(metricRow("AURORA FX", prefs.getBoolean("aurora_fx",true) ? activeFxCount() + "/5 modules • ON" : "OFF"), top(7));
        summary.addView(metricRow("Extreme Bass", prefs.getBoolean("extreme_bass",false) ? prefs.getInt("extreme_strength",88) + "% • ON" : "OFF"), top(7));
        summary.addView(metricRow("Digital ceiling", "+" + prefs.getInt("gain_ceiling",5) + " dB"), top(7));

        section("QUALITY STACK");
        LinearLayout quality = card();
        quality.setOrientation(LinearLayout.VERTICAL);
        page.addView(quality, top(8));
        quality.addView(txt("AUTO QUALITY ACTIVE", 13, GREEN, true));
        quality.addView(txt(qualitySummary(), 12, MUTED, false), top(6));

        HorizontalScrollView actions = new HorizontalScrollView(this);
        LinearLayout ar = new LinearLayout(this);
        ar.setOrientation(LinearLayout.HORIZONTAL);
        actions.addView(ar);
        page.addView(actions, top(9));
        action(ar, "MAX QUALITY", this::enableMaxQuality);
        action(ar, "OPEN FX", () -> showPage("FX"));
        action(ar, "DIAGNOSTICS", this::showDiagnostics);
    }

    private void buildBassPage() {
        hero("BASS LAB", "Low-end control without turning the whole mix into mud");
        slider("BASS", "Android BassBoost intensity", "bass", 0, 100, 68, v -> v + "%");
        slider("SUB BASS", "Deep low-end amount", "sub", 0, 100, 55, v -> v + "%");
        slider("PUNCH", "Kick and impact energy", "punch", 0, 100, 45, v -> v + "%");
        toggle("DYNAMIC BASS", "Adaptive shaping of the low-end curve", "dynamic_bass", true);

        section("EXTREME CLEAN");
        toggle("EXTREME BASS", "Pushes deep bass while extra cleanup/headroom stays active", "extreme_bass", false);
        slider("EXTREME STRENGTH", "Amount of dedicated extreme low-end shaping", "extreme_strength", 0, 100, 88, v -> v + "%");
        slider("SUB FOCUS", "Moves the deepest bass focus", "sub_focus", 0, 100, 35,
                v -> (32 + Math.round(v * 0.48f)) + " Hz");
        slider("PUNCH FOCUS", "Moves the kick focus", "punch_focus", 0, 100, 50,
                v -> (90 + Math.round(v * 1.5f)) + " Hz");

        section("AURORA LOW-END FX");
        slider("DEPTH", "Adds controlled ultra-low weight", "fx_depth", 0, 100, 62, v -> v + "%");
        slider("TIGHTNESS", "Cuts boom around the sub-to-midbass transition", "fx_tight", 0, 100, 58, v -> v + "%");
        HorizontalScrollView hs = new HorizontalScrollView(this);
        LinearLayout row = new LinearLayout(this); row.setOrientation(LinearLayout.HORIZONTAL); hs.addView(row);
        page.addView(hs, top(8));
        action(row, "EXTREME CLEAN", () -> applyMode("extreme"));
        action(row, "DEEP CLEAN", () -> applyMode("deep"));
        action(row, "RESET BASS", this::resetBassOnly);
    }

    private void buildFxPage() {
        hero("AURORA FX RACK", "Quality shaping modules • all work through real EQ/audio-effect controls");

        toggle("AURORA FX MASTER", "Master switch for the V7 FX rack", "aurora_fx", true);

        section("FX MODULES");
        fxModule("DEPTH", "Controlled sub extension below ~105 Hz", "fx_depth_on", "fx_depth", 62);
        fxModule("TIGHTNESS", "Reduces boom and low-mid smear", "fx_tight_on", "fx_tight", 58);
        fxModule("IMPACT", "Adds kick definition and attack presence", "fx_impact_on", "fx_impact", 48);
        fxModule("AIR", "Adds clean top-end detail", "fx_air_on", "fx_air", 42);
        fxModule("SMOOTHNESS", "Softens harsh upper-mid peaks", "fx_smooth_on", "fx_smooth", 52);

        section("SONIC CORE");
        toggle("SONIC CORE", "Automatic clean-up and quality processing", "sonic_core", true);
        slider("SONIC STRENGTH", "Strength of automatic quality processing", "sonic_strength", 0, 100, 78, v -> v + "%");
        toggle("CURVE SMOOTHING", "Smooths aggressive jumps between EQ bands", "curve_smoothing", true);
        toggle("AUTO ANTI-MUD", "Cleans low mids more when bass gets heavy", "auto_clean", true);
        toggle("BASS DEFINITION", "Keeps sub bass separated from midbass", "bass_definition", true);
        toggle("CLARITY RESTORE", "Restores detail masked by strong bass", "clarity_restore", true);
        toggle("TRANSIENT FOCUS", "Adds attack definition", "transient_focus", true);
        toggle("STEREO GUARD", "Reduces excessive width under heavy low-end load", "stereo_guard", true);
        toggle("ADAPTIVE HEADROOM", "Creates extra digital space before overload", "adaptive_headroom", true);

        section("TONE / SPACE");
        slider("CLARITY", "Anti-mud + definition contour", "clarity", 0, 100, 55, v -> v + "%");
        slider("TREBLE / AIR", "Top-end restoration", "treble", 0, 100, 40, v -> v + "%");
        slider("VOCAL PROTECTION", "Keeps mids readable with heavy bass", "vocal", 0, 100, 55, v -> v + "%");
        slider("WIDTH", "Virtualizer amount", "width", 0, 100, 20, v -> v + "%");
        slider("WARMTH", "Adds body in the low mids", "warmth", 0, 100, 35, v -> v + "%");
        slider("PRESENCE", "Adds forward detail", "presence", 0, 100, 40, v -> v + "%");
    }

    private void buildEqPage() {
        hero("10-BAND EQ", "Manual curve editor • -12 dB to +12 dB");
        int[] curve = readCurve();

        HorizontalScrollView tools = new HorizontalScrollView(this);
        LinearLayout tr = new LinearLayout(this); tr.setOrientation(LinearLayout.HORIZONTAL); tools.addView(tr);
        page.addView(tools, top(8));
        action(tr, "FLAT", () -> setCurve(new int[]{0,0,0,0,0,0,0,0,0,0}));
        action(tr, "CLEAN BASS", () -> setCurve(new int[]{8,8,6,3,0,0,0,1,1,1}));
        action(tr, "V-SHAPE", () -> setCurve(new int[]{7,6,4,1,-1,-1,1,3,5,6}));

        for (int i = 0; i < 10; i++) {
            final int idx = i;
            LinearLayout c = card();
            c.setOrientation(LinearLayout.VERTICAL);
            page.addView(c, top(i == 0 ? 12 : 8));
            LinearLayout h = new LinearLayout(this); h.setOrientation(LinearLayout.HORIZONTAL);
            TextView name = txt(BAND_NAMES[i] + " Hz", 13, TEXT, true);
            h.addView(name, new LinearLayout.LayoutParams(0,-2,1f));
            TextView val = txt(db(curve[i]), 13, RED, true);
            h.addView(val);
            c.addView(h);
            SeekBar sb = seek(0,24,curve[i]+12);
            c.addView(sb, top(6));
            sb.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                public void onProgressChanged(SeekBar s, int p, boolean u) {
                    if (!u) return;
                    int[] now = readCurve();
                    now[idx] = p - 12;
                    saveCurve(now);
                    val.setText(db(p-12));
                    pushUpdate();
                }
                public void onStartTrackingTouch(SeekBar s) {}
                public void onStopTrackingTouch(SeekBar s) {}
            });
        }
    }

    private void buildPresetsPage() {
        hero("PRESET VAULT", "Modes, profiles, snapshots and portable settings");

        section("SCENES");
        LinearLayout scenes = wrapActions(new String[]{"STUDIO","DEEP","EXTREME CLEAN","ARENA","GAMING","NIGHT"},
                new Runnable[]{() -> applyMode("studio"),() -> applyMode("deep"),() -> applyMode("extreme"),
                        () -> applyMode("arena"),() -> applyMode("gaming"),() -> applyMode("night")});
        page.addView(scenes, top(8));

        section("DEVICE PROFILES");
        LinearLayout prof = wrapActions(new String[]{"HEADPHONES","SPEAKER","MUSIC","GAMING"},
                new Runnable[]{() -> applyProfile("headphones"),() -> applyProfile("speaker"),
                        () -> applyProfile("music"),() -> applyProfile("gaming")});
        page.addView(prof, top(8));

        section("SLOTS");
        LinearLayout slots = wrapActions(new String[]{"SAVE S1","LOAD S1","SAVE S2","LOAD S2","SAVE S3","LOAD S3"},
                new Runnable[]{() -> saveSlot(1),() -> loadSlot(1),() -> saveSlot(2),() -> loadSlot(2),
                        () -> saveSlot(3),() -> loadSlot(3)});
        page.addView(slots, top(8));

        section("A / B");
        LinearLayout ab = wrapActions(new String[]{"SAVE A","LOAD A","SAVE B","LOAD B"},
                new Runnable[]{() -> saveSlot(10),() -> loadSlot(10),() -> saveSlot(11),() -> loadSlot(11)});
        page.addView(ab, top(8));

        section("PORTABLE PRESET");
        LinearLayout io = wrapActions(new String[]{"EXPORT","IMPORT"},
                new Runnable[]{this::exportPreset,this::importPreset});
        page.addView(io, top(8));
    }

    private void buildSystemPage() {
        hero("SYSTEM", "Engine behavior, diagnostics and app controls");

        toggle("AUTO DEVICE PROFILE", "Adapts some tuning when headphones/speaker output changes", "auto_profile", true);
        toggle("BOOT RESTART REMINDER", "Shows a restart reminder after reboot", "auto_start", false);
        toggle("AUTO GAIN", "Controls excessive digital output gain", "auto_gain", true);

        slider("MASTER INTENSITY", "Scales the shaped EQ curve", "intensity", 50, 150, 100, v -> v + "%");
        slider("GAIN CEILING", "Caps extra digital LoudnessEnhancer gain", "gain_ceiling", 0, 6, 5, v -> "+" + v + " dB");

        section("ENGINE SAFETY / CLEANUP");
        LinearLayout clean = card();
        clean.setOrientation(LinearLayout.VERTICAL);
        page.addView(clean, top(8));
        clean.addView(txt("CLEAN SHUTDOWN • ACTIVE", 13, GREEN, true));
        clean.addView(txt("EQ, BassBoost, Loudness and Virtualizer are neutralized before the native effect handles are released.", 12, MUTED, false), top(5));

        section("TOOLS");
        LinearLayout tools = wrapActions(new String[]{"DIAGNOSTICS","CHANGELOG","MAX QUALITY","RESET AUDIO"},
                new Runnable[]{this::showDiagnostics,this::showChangelog,this::enableMaxQuality,this::resetAll});
        page.addView(tools, top(8));
    }

    private void fxModule(String title, String desc, String boolKey, String valueKey, int def) {
        LinearLayout c = card();
        c.setOrientation(LinearLayout.VERTICAL);
        page.addView(c, top(8));
        LinearLayout h = new LinearLayout(this); h.setOrientation(LinearLayout.HORIZONTAL); h.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout copy = new LinearLayout(this); copy.setOrientation(LinearLayout.VERTICAL);
        h.addView(copy, new LinearLayout.LayoutParams(0,-2,1f));
        copy.addView(txt(title, 14, TEXT, true));
        copy.addView(txt(desc, 11, MUTED, false), top(2));
        Switch sw = styledSwitch(prefs.getBoolean(boolKey,true));
        h.addView(sw);
        c.addView(h);
        TextView val = txt(prefs.getInt(valueKey,def) + "%", 12, RED, true);
        val.setGravity(Gravity.RIGHT);
        c.addView(val, top(8));
        SeekBar sb = seek(0,100,prefs.getInt(valueKey,def));
        c.addView(sb, top(3));
        sw.setOnCheckedChangeListener((b,on)-> { prefs.edit().putBoolean(boolKey,on).apply(); pushUpdate(); });
        sb.setOnSeekBarChangeListener(simple(p -> { prefs.edit().putInt(valueKey,p).apply(); val.setText(p+"%"); pushUpdate(); }));
    }

    private void hero(String title, String subtitle) {
        LinearLayout h = card();
        h.setOrientation(LinearLayout.VERTICAL);
        h.setPadding(dp(18), dp(18), dp(18), dp(18));
        page.addView(h);
        h.addView(txt(title, 20, TEXT, true));
        h.addView(txt(subtitle, 12, MUTED, false), top(4));
    }

    private void section(String s) {
        TextView t = txt(s, 11, MUTED, true);
        t.setLetterSpacing(0.07f);
        page.addView(t, top(20));
    }

    private void slider(String title, String desc, String key, int min, int max, int def, Formatter fmt) {
        LinearLayout c = card();
        c.setOrientation(LinearLayout.VERTICAL);
        page.addView(c, top(8));
        LinearLayout h = new LinearLayout(this); h.setOrientation(LinearLayout.HORIZONTAL); h.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout copy = new LinearLayout(this); copy.setOrientation(LinearLayout.VERTICAL);
        h.addView(copy, new LinearLayout.LayoutParams(0,-2,1f));
        copy.addView(txt(title, 14, TEXT, true));
        copy.addView(txt(desc, 11, MUTED, false), top(2));
        int current = prefs.getInt(key, def);
        TextView value = txt(fmt.format(current), 13, RED, true);
        h.addView(value);
        c.addView(h);
        SeekBar sb = seek(min,max,current);
        c.addView(sb, top(8));
        sb.setOnSeekBarChangeListener(simple(p -> {
            prefs.edit().putInt(key,p).apply();
            value.setText(fmt.format(p));
            pushUpdate();
        }));
    }

    private void toggle(String title, String desc, String key, boolean def) {
        LinearLayout c = card();
        c.setOrientation(LinearLayout.HORIZONTAL);
        c.setGravity(Gravity.CENTER_VERTICAL);
        page.addView(c, top(8));
        LinearLayout copy = new LinearLayout(this); copy.setOrientation(LinearLayout.VERTICAL);
        c.addView(copy, new LinearLayout.LayoutParams(0,-2,1f));
        copy.addView(txt(title, 14, TEXT, true));
        copy.addView(txt(desc, 11, MUTED, false), top(2));
        Switch sw = styledSwitch(prefs.getBoolean(key,def));
        c.addView(sw);
        sw.setOnCheckedChangeListener((b,on)-> { prefs.edit().putBoolean(key,on).apply(); pushUpdate(); refreshHeader(); });
    }

    private LinearLayout metricRow(String left, String right) {
        LinearLayout r = new LinearLayout(this); r.setOrientation(LinearLayout.HORIZONTAL);
        r.addView(txt(left,12,MUTED,false),new LinearLayout.LayoutParams(0,-2,1f));
        r.addView(txt(right,12,TEXT,true));
        return r;
    }

    private LinearLayout wrapActions(String[] labels, Runnable[] actions) {
        LinearLayout outer = new LinearLayout(this);
        outer.setOrientation(LinearLayout.VERTICAL);
        int idx = 0;
        while (idx < labels.length) {
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            outer.addView(row, idx == 0 ? new LinearLayout.LayoutParams(-1,-2) : top(7));
            for (int j=0; j<2 && idx<labels.length; j++,idx++) {
                TextView b = txt(labels[idx], 11, TEXT, true);
                b.setGravity(Gravity.CENTER);
                b.setPadding(dp(12),dp(11),dp(12),dp(11));
                b.setBackground(round(SURFACE_2,14,Color.rgb(55,60,74),1));
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0,-2,1f);
                if (j==0) lp.setMargins(0,0,dp(7),0);
                row.addView(b,lp);
                final Runnable run=actions[idx];
                b.setOnClickListener(v->run.run());
            }
        }
        return outer;
    }

    private void action(LinearLayout row, String label, Runnable run) {
        TextView b = txt(label,11,TEXT,true);
        b.setGravity(Gravity.CENTER);
        b.setPadding(dp(13),dp(10),dp(13),dp(10));
        b.setBackground(round(SURFACE_2,14,Color.rgb(64,24,34),1));
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-2,-2); lp.setMargins(0,0,dp(7),0);
        row.addView(b,lp);
        b.setOnClickListener(v->run.run());
    }

    private void applyMode(String mode) {
        SharedPreferences.Editor e=prefs.edit();
        if ("studio".equals(mode)) {
            e.putString("curve","4,4,3,1,0,0,1,2,2,2").putInt("bass",68).putInt("sub",62).putInt("punch",55)
                    .putInt("width",18).putInt("clarity",82).putInt("treble",48).putInt("vocal",78)
                    .putInt("intensity",96).putInt("gain_ceiling",4).putBoolean("extreme_bass",false)
                    .putInt("fx_depth",45).putInt("fx_tight",72).putInt("fx_impact",46).putInt("fx_air",46).putInt("fx_smooth",62);
        } else if ("deep".equals(mode)) {
            e.putString("curve","10,10,8,4,1,0,0,0,1,1").putInt("bass",92).putInt("sub",100).putInt("punch",48)
                    .putInt("width",12).putInt("clarity",90).putInt("intensity",104).putInt("gain_ceiling",4)
                    .putBoolean("extreme_bass",false).putInt("fx_depth",88).putInt("fx_tight",76).putInt("fx_air",36);
        } else if ("extreme".equals(mode)) {
            e.putString("curve","12,12,10,5,0,-1,-1,0,1,2").putInt("bass",100).putInt("sub",100).putInt("punch",82)
                    .putInt("width",12).putInt("clarity",96).putInt("treble",54).putInt("vocal",84)
                    .putInt("intensity",112).putInt("gain_ceiling",4).putBoolean("extreme_bass",true)
                    .putInt("extreme_strength",94).putInt("fx_depth",92).putInt("fx_tight",86)
                    .putInt("fx_impact",58).putInt("fx_air",42).putInt("fx_smooth",62);
        } else if ("arena".equals(mode)) {
            e.putString("curve","8,8,7,4,1,0,1,2,3,3").putInt("bass",84).putInt("sub",72).putInt("punch",86)
                    .putInt("width",38).putInt("clarity",72).putInt("treble",58).putInt("presence",58)
                    .putBoolean("extreme_bass",false).putInt("fx_impact",74).putInt("fx_air",55);
        } else if ("gaming".equals(mode)) {
            e.putString("curve","4,4,3,1,0,1,2,3,3,2").putInt("bass",55).putInt("sub",40).putInt("punch",60)
                    .putInt("width",40).putInt("clarity",94).putInt("treble",68).putInt("vocal",84)
                    .putBoolean("extreme_bass",false).putInt("fx_tight",70).putInt("fx_impact",58).putInt("fx_air",56);
        } else {
            e.putString("curve","4,4,3,2,1,0,0,1,1,1").putInt("bass",52).putInt("sub",45).putInt("punch",36)
                    .putInt("width",14).putInt("clarity",76).putInt("loudness",8).putInt("gain_ceiling",2)
                    .putBoolean("extreme_bass",false).putInt("fx_depth",40).putInt("fx_smooth",75);
        }
        e.putBoolean("aurora_fx",true).putBoolean("sonic_core",true).putBoolean("auto_gain",true)
                .putBoolean("adaptive_headroom",true).putBoolean("auto_clean",true).apply();
        pushUpdate();
        Toast.makeText(this, mode.toUpperCase() + " loaded", Toast.LENGTH_SHORT).show();
        showPage("HOME");
    }

    private void applyProfile(String name) {
        SharedPreferences.Editor e=prefs.edit();
        if ("headphones".equals(name)) e.putInt("width",24).putInt("clarity",84).putInt("fx_tight",66).putInt("fx_air",48);
        else if ("speaker".equals(name)) e.putInt("width",6).putInt("sub_focus",66).putInt("punch_focus",60).putInt("fx_tight",78);
        else if ("gaming".equals(name)) e.putInt("width",42).putInt("clarity",92).putInt("fx_impact",64).putInt("fx_air",58);
        else e.putInt("width",20).putInt("clarity",82).putInt("fx_depth",60).putInt("fx_tight",62).putInt("fx_air",48);
        e.apply(); pushUpdate(); Toast.makeText(this,name.toUpperCase()+" profile",Toast.LENGTH_SHORT).show();
    }

    private void enableMaxQuality() {
        prefs.edit().putBoolean("aurora_fx",true).putBoolean("sonic_core",true)
                .putBoolean("fx_depth_on",true).putBoolean("fx_tight_on",true).putBoolean("fx_impact_on",true)
                .putBoolean("fx_air_on",true).putBoolean("fx_smooth_on",true)
                .putBoolean("curve_smoothing",true).putBoolean("auto_clean",true).putBoolean("bass_definition",true)
                .putBoolean("clarity_restore",true).putBoolean("transient_focus",true).putBoolean("stereo_guard",true)
                .putBoolean("adaptive_headroom",true).putBoolean("auto_gain",true)
                .putInt("sonic_strength",92).putInt("fx_tight",68).putInt("fx_smooth",58).apply();
        pushUpdate(); Toast.makeText(this,"MAX QUALITY enabled",Toast.LENGTH_SHORT).show(); showPage("HOME");
    }

    private void resetBassOnly() {
        prefs.edit().putInt("bass",68).putInt("sub",55).putInt("punch",45).putInt("sub_focus",35)
                .putInt("punch_focus",50).putBoolean("extreme_bass",false).putInt("extreme_strength",88)
                .putInt("fx_depth",62).putInt("fx_tight",58).apply();
        pushUpdate(); showPage("BASS");
    }

    private void resetAll() {
        prefs.edit().putString("curve","7,7,6,4,2,0,0,0,1,1")
                .putInt("bass",68).putInt("loudness",16).putInt("sub",55).putInt("punch",45).putInt("width",20)
                .putInt("clarity",55).putInt("treble",40).putInt("sub_focus",35).putInt("punch_focus",50)
                .putInt("vocal",55).putInt("quality",1).putInt("intensity",100).putInt("warmth",35)
                .putInt("presence",40).putInt("low_mid_cut",35).putInt("gain_ceiling",5).putInt("sonic_strength",78)
                .putInt("extreme_strength",88).putInt("fx_depth",62).putInt("fx_tight",58).putInt("fx_impact",48)
                .putInt("fx_air",42).putInt("fx_smooth",52)
                .putBoolean("extreme_bass",false).putBoolean("aurora_fx",true).putBoolean("sonic_core",true)
                .putBoolean("auto_gain",true).putBoolean("dynamic_bass",true).putBoolean("auto_clean",true)
                .putBoolean("bass_definition",true).putBoolean("clarity_restore",true).putBoolean("transient_focus",true)
                .putBoolean("stereo_guard",true).putBoolean("adaptive_headroom",true)
                .putBoolean("fx_depth_on",true).putBoolean("fx_tight_on",true).putBoolean("fx_impact_on",true)
                .putBoolean("fx_air_on",true).putBoolean("fx_smooth_on",true).apply();
        pushUpdate(); showPage("HOME"); Toast.makeText(this,"Audio settings reset",Toast.LENGTH_SHORT).show();
    }

    private int activeFxCount() {
        int n=0;
        for(String k:new String[]{"fx_depth_on","fx_tight_on","fx_impact_on","fx_air_on","fx_smooth_on"})
            if(prefs.getBoolean(k,true)) n++;
        return n;
    }

    private String qualitySummary() {
        int n=0;
        for(String k:new String[]{"curve_smoothing","auto_clean","bass_definition","clarity_restore","transient_focus","stereo_guard","adaptive_headroom","auto_gain"})
            if(prefs.getBoolean(k,true)) n++;
        return n + "/8 automatic quality modules enabled\n" +
                "Aurora FX: " + (prefs.getBoolean("aurora_fx",true) ? "ON" : "OFF") +
                " • Extreme: " + (prefs.getBoolean("extreme_bass",false) ? "ON" : "OFF");
    }

    private String engineStatus() {
        return prefs.getBoolean("engine_enabled",false) ? "ACTIVE • processing audio sessions" : "OFF • clean shutdown";
    }

    private void refreshHeader() {
        if(headerState==null) return;
        boolean on=prefs.getBoolean("engine_enabled",false);
        headerState.setText(on ? "ENGINE ON" : "ENGINE OFF");
        headerState.setTextColor(on ? GREEN : MUTED);
        headerState.setBackground(round(on ? Color.rgb(18,57,42) : SURFACE,12,on ? Color.rgb(37,109,78) : Color.rgb(45,49,59),1));
    }

    private void startEngine(String action) {
        Intent i=new Intent(this,BassService.class); i.setAction(action);
        try {
            if(Build.VERSION.SDK_INT>=26 && !BassService.ACTION_STOP.equals(action)) startForegroundService(i);
            else startService(i);
        } catch(Exception e) {
            Toast.makeText(this,"Audio engine could not start",Toast.LENGTH_SHORT).show();
        }
    }

    private void pushUpdate() {
        if(prefs.getBoolean("engine_enabled",false)) startEngine(BassService.ACTION_UPDATE);
    }

    private int[] readCurve() {
        int[] fallback={7,7,6,4,2,0,0,0,1,1};
        int[] out=new int[10];
        String[] p=prefs.getString("curve","7,7,6,4,2,0,0,0,1,1").split(",");
        for(int i=0;i<10;i++) {
            try { out[i]=i<p.length?Integer.parseInt(p[i]):fallback[i]; }
            catch(Exception e){ out[i]=fallback[i]; }
        }
        return out;
    }

    private void saveCurve(int[] c) {
        StringBuilder s=new StringBuilder();
        for(int i=0;i<c.length;i++){ if(i>0)s.append(','); s.append(c[i]); }
        prefs.edit().putString("curve",s.toString()).apply();
    }

    private void setCurve(int[] c) { saveCurve(c); pushUpdate(); showPage("EQ"); }

    private void saveSlot(int slot) {
        String p="v7slot"+slot+"_";
        SharedPreferences.Editor e=prefs.edit().putString(p+"curve",prefs.getString("curve",""));
        for(int i=0;i<INT_KEYS.length;i++) e.putInt(p+INT_KEYS[i],prefs.getInt(INT_KEYS[i],INT_DEFAULTS[i]));
        for(String k:BOOL_KEYS) e.putBoolean(p+k,prefs.getBoolean(k,true));
        e.putBoolean(p+"saved",true).apply();
        Toast.makeText(this,slot==10?"A saved":slot==11?"B saved":"Slot "+slot+" saved",Toast.LENGTH_SHORT).show();
    }

    private void loadSlot(int slot) {
        String p="v7slot"+slot+"_";
        if(!prefs.getBoolean(p+"saved",false)){Toast.makeText(this,"Nothing saved here",Toast.LENGTH_SHORT).show();return;}
        SharedPreferences.Editor e=prefs.edit().putString("curve",prefs.getString(p+"curve","7,7,6,4,2,0,0,0,1,1"));
        for(int i=0;i<INT_KEYS.length;i++) e.putInt(INT_KEYS[i],prefs.getInt(p+INT_KEYS[i],INT_DEFAULTS[i]));
        for(String k:BOOL_KEYS) e.putBoolean(k,prefs.getBoolean(p+k,true));
        e.apply(); pushUpdate(); Toast.makeText(this,"Preset loaded",Toast.LENGTH_SHORT).show();
    }

    private void exportPreset() {
        StringBuilder o=new StringBuilder("BF7;");
        o.append("curve=").append(prefs.getString("curve","")).append(';');
        for(int i=0;i<INT_KEYS.length;i++) o.append(INT_KEYS[i]).append('=').append(prefs.getInt(INT_KEYS[i],INT_DEFAULTS[i])).append(';');
        for(String k:BOOL_KEYS) o.append(k).append('=').append(prefs.getBoolean(k,true)).append(';');
        ClipboardManager cm=(ClipboardManager)getSystemService(CLIPBOARD_SERVICE);
        if(cm!=null) cm.setPrimaryClip(ClipData.newPlainText("BassForge V7 Preset",o.toString()));
        Toast.makeText(this,"BF7 preset copied",Toast.LENGTH_SHORT).show();
    }

    private void importPreset() {
        ClipboardManager cm=(ClipboardManager)getSystemService(CLIPBOARD_SERVICE);
        if(cm==null||!cm.hasPrimaryClip()||cm.getPrimaryClip()==null){Toast.makeText(this,"Clipboard empty",Toast.LENGTH_SHORT).show();return;}
        String raw=String.valueOf(cm.getPrimaryClip().getItemAt(0).coerceToText(this));
        if(!raw.startsWith("BF7;")){Toast.makeText(this,"No BF7 preset found",Toast.LENGTH_SHORT).show();return;}
        try {
            SharedPreferences.Editor e=prefs.edit();
            for(String item:raw.substring(4).split(";")) {
                int x=item.indexOf('='); if(x<=0) continue;
                String k=item.substring(0,x),v=item.substring(x+1);
                if("curve".equals(k)) e.putString(k,v);
                else if(isBool(k)) e.putBoolean(k,Boolean.parseBoolean(v));
                else if(isInt(k)) e.putInt(k,Integer.parseInt(v));
            }
            e.apply(); pushUpdate(); Toast.makeText(this,"BF7 preset imported",Toast.LENGTH_SHORT).show();
        } catch(Exception ex){Toast.makeText(this,"Invalid preset data",Toast.LENGTH_SHORT).show();}
    }

    private boolean isBool(String k){for(String x:BOOL_KEYS)if(x.equals(k))return true;return false;}
    private boolean isInt(String k){for(String x:INT_KEYS)if(x.equals(k))return true;return false;}

    private void showDiagnostics() {
        StringBuilder s=new StringBuilder();
        s.append(Build.MANUFACTURER).append(" ").append(Build.MODEL).append("\nAndroid ")
                .append(Build.VERSION.RELEASE).append(" • API ").append(Build.VERSION.SDK_INT).append("\n\n");
        try {
            AudioEffect.Descriptor[] d=AudioEffect.queryEffects();
            s.append("Audio effects reported: ").append(d==null?0:d.length).append("\n");
            if(d!=null) for(AudioEffect.Descriptor x:d) s.append("• ").append(x.name).append("\n");
        } catch(Throwable t){s.append("Effect query unavailable\n");}
        s.append("\nEngine: ").append(engineStatus()).append("\nAurora FX: ")
                .append(prefs.getBoolean("aurora_fx",true)?"ON":"OFF")
                .append("\nSONIC CORE: ").append(prefs.getBoolean("sonic_core",true)?"ON":"OFF");
        new AlertDialog.Builder(this).setTitle("BassForge Diagnostics").setMessage(s.toString()).setPositiveButton("CLOSE",null).show();
    }

    private void showChangelog() {
        String log="V7 AURORA FX\n"+
                "• Completely redesigned menu UI\n"+
                "• HOME / BASS / FX / EQ / PRESETS / SYSTEM navigation\n"+
                "• New control-center overview\n"+
                "• Animated red engine accent\n"+
                "• AURORA FX master rack\n"+
                "• Depth FX\n• Tightness FX\n• Impact FX\n• Air FX\n• Smoothness FX\n"+
                "• All five quality FX enabled by default\n"+
                "• New Studio, Deep, Extreme Clean, Arena, Gaming and Night scenes\n"+
                "• Reworked 10-band EQ page\n"+
                "• New preset vault with 3 slots + A/B\n"+
                "• New BF7 export/import format\n"+
                "• Better diagnostics and system overview\n"+
                "• Existing SONIC CORE + Extreme Clean retained\n"+
                "• Clean Shutdown retained\n\n"+
                "V6.1\n• Extreme Clean bass path and strength control\n\n"+
                "V6.0.3\n• Clean audio shutdown\n\n"+
                "V6\n• SONIC CORE auto-quality engine\n\n"+
                "V5\n• OVERDRIVE controls and preset lab";
        new AlertDialog.Builder(this).setTitle("BassForge EQ — Changelog").setMessage(log).setPositiveButton("CLOSE",null).show();
    }

    private LinearLayout card() {
        LinearLayout c=new LinearLayout(this);
        c.setPadding(dp(15),dp(14),dp(15),dp(14));
        c.setBackground(round(SURFACE,18,Color.rgb(37,41,52),1));
        return c;
    }

    private TextView txt(String s,int sp,int color,boolean bold) {
        TextView t=new TextView(this); t.setText(s); t.setTextSize(sp); t.setTextColor(color);
        t.setTypeface(Typeface.create("sans",bold?Typeface.BOLD:Typeface.NORMAL));
        return t;
    }

    private Switch styledSwitch(boolean checked) {
        Switch s=new Switch(this); s.setChecked(checked);
        s.setThumbTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},
                new int[]{RED,Color.rgb(120,124,135)}));
        s.setTrackTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},
                new int[]{Color.rgb(93,31,43),Color.rgb(52,55,65)}));
        return s;
    }

    private SeekBar seek(int min,int max,int value) {
        SeekBar s=new SeekBar(this); s.setMax(max-min); s.setProgress(Math.max(0,Math.min(max-min,value-min)));
        s.setTag(min);
        s.setProgressTintList(ColorStateList.valueOf(RED)); s.setThumbTintList(ColorStateList.valueOf(RED));
        return s;
    }

    private SeekBar.OnSeekBarChangeListener simple(java.util.function.IntConsumer cb) {
        return new SeekBar.OnSeekBarChangeListener() {
            public void onProgressChanged(SeekBar s,int p,boolean fromUser) {
                if(!fromUser)return; int min=(Integer)s.getTag(); cb.accept(p+min);
            }
            public void onStartTrackingTouch(SeekBar s){}
            public void onStopTrackingTouch(SeekBar s){}
        };
    }

    private GradientDrawable round(int fill,int radius,int strokeColor,int strokeWidth) {
        GradientDrawable g=new GradientDrawable(); g.setColor(fill); g.setCornerRadius(dp(radius));
        if(strokeWidth>0)g.setStroke(dp(strokeWidth),strokeColor); return g;
    }

    private LinearLayout.LayoutParams top(int px) {
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2); lp.setMargins(0,dp(px),0,0); return lp;
    }

    private String db(int v){return (v>0?"+":"")+v+" dB";}
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
}
