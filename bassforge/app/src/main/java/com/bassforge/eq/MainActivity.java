package com.bassforge.eq;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.res.ColorStateList;
import android.content.Context;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
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

public class MainActivity extends Activity {
    private static final int BG = Color.rgb(7, 7, 9);
    private static final int CARD = Color.rgb(18, 18, 23);
    private static final int CARD_2 = Color.rgb(25, 25, 31);
    private static final int TEXT = Color.rgb(244, 244, 247);
    private static final int MUTED = Color.rgb(151, 151, 163);
    private static final int ACCENT = Color.rgb(255, 25, 48);
    private static final int GREEN = Color.rgb(59, 214, 123);

    private static final String[] BAND_NAMES = {"31", "62", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"};

    private final int[] curve = new int[10];
    private final List<SeekBar> bandBars = new ArrayList<>();
    private final List<TextView> bandValues = new ArrayList<>();

    private SharedPreferences prefs;
    private SeekBar bassBar;
    private SeekBar loudnessBar;
    private SeekBar subBar;
    private SeekBar punchBar;
    private SeekBar widthBar;
    private SeekBar clarityBar;
    private SeekBar trebleBar;
    private SeekBar subFocusBar;
    private SeekBar punchFocusBar;
    private SeekBar vocalBar;
    private SeekBar intensityBar;
    private SeekBar warmthBar;
    private SeekBar presenceBar;
    private SeekBar lowMidCutBar;
    private SeekBar gainCeilingBar;
    private SeekBar sonicStrengthBar;
    private TextView bassValue;
    private TextView loudnessValue;
    private TextView subValue;
    private TextView punchValue;
    private TextView widthValue;
    private TextView clarityValue;
    private TextView trebleValue;
    private TextView subFocusValue;
    private TextView punchFocusValue;
    private TextView vocalValue;
    private TextView intensityValue;
    private TextView warmthValue;
    private TextView presenceValue;
    private TextView lowMidCutValue;
    private TextView gainCeilingValue;
    private TextView sonicStrengthValue;
    private Switch dynamicBassSwitch;
    private Switch autoGainSwitch;
    private Switch autoProfileSwitch;
    private Switch autoStartSwitch;
    private final List<Switch> qualitySwitches = new ArrayList<>();
    private final List<String> qualitySwitchKeys = new ArrayList<>();
    private TextView statusText;
    private Switch powerSwitch;
    private boolean buildingUi = true;
    private final Handler handler = new Handler(Looper.getMainLooper());

    private final Runnable pushUpdate = this::sendUpdateNow;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Window w = getWindow();
        w.setStatusBarColor(BG);
        w.setNavigationBarColor(BG);

        prefs = getSharedPreferences(BassService.PREFS, MODE_PRIVATE);
        initV6Defaults();
        loadState();

        if (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 300);
        }

        setContentView(buildUi());
        buildingUi = false;
        refreshControls();
        refreshStatusDelayed();
    }

    private void loadState() {
        int[] fallback = {7, 7, 6, 4, 2, 0, 0, 0, 1, 1};
        String saved = prefs.getString("curve", "7,7,6,4,2,0,0,0,1,1");
        String[] parts = saved.split(",");
        for (int i = 0; i < curve.length; i++) {
            try {
                curve[i] = i < parts.length ? Integer.parseInt(parts[i]) : fallback[i];
            } catch (Exception e) {
                curve[i] = fallback[i];
            }
        }
    }

    private View buildUi() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(BG);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(18), dp(24), dp(18), dp(34));
        scroll.addView(root, new ScrollView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        TextView brand = text("BASSFORGE", 34, TEXT, true);
        brand.setLetterSpacing(0.08f);
        root.addView(brand);

        TextView subtitle = text("SONIC CORE AUDIO ENGINE  •  V6", 12, ACCENT, true);
        subtitle.setLetterSpacing(0.14f);
        root.addView(subtitle, marginTop(2));

        LinearLayout statusCard = card();
        statusCard.setOrientation(LinearLayout.VERTICAL);
        statusCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        root.addView(statusCard, marginTop(18));

        LinearLayout powerRow = new LinearLayout(this);
        powerRow.setOrientation(LinearLayout.HORIZONTAL);
        powerRow.setGravity(Gravity.CENTER_VERTICAL);
        statusCard.addView(powerRow, matchWrap());

        LinearLayout powerText = new LinearLayout(this);
        powerText.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams powerTextLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        powerRow.addView(powerText, powerTextLp);

        powerText.addView(text("AUDIO ENGINE", 14, TEXT, true));
        statusText = text("Engine off", 12, MUTED, false);
        powerText.addView(statusText, marginTop(3));

        powerSwitch = new Switch(this);
        powerSwitch.setShowText(false);
        powerSwitch.setButtonTintList(null);
        if (Build.VERSION.SDK_INT >= 23) {
            powerSwitch.setThumbTintList(ColorStateList.valueOf(TEXT));
            powerSwitch.setTrackTintList(new ColorStateList(
                    new int[][]{new int[]{android.R.attr.state_checked}, new int[]{}},
                    new int[]{ACCENT, Color.rgb(63, 63, 70)}));
        }
        powerRow.addView(powerSwitch);
        powerSwitch.setChecked(prefs.getBoolean("engine_enabled", false));
        powerSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buildingUi) return;
            prefs.edit().putBoolean("engine_enabled", isChecked).apply();
            if (isChecked) {
                startEngine(BassService.ACTION_START);
            } else {
                startEngine(BassService.ACTION_STOP);
                statusText.setText("Engine off");
                statusText.setTextColor(MUTED);
            }
            refreshStatusDelayed();
        });

        sectionTitle(root, "PRESETS");
        HorizontalScrollView presetScroll = new HorizontalScrollView(this);
        presetScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout presetRow = new LinearLayout(this);
        presetRow.setOrientation(LinearLayout.HORIZONTAL);
        presetScroll.addView(presetRow);
        root.addView(presetScroll, marginTop(8));

        addPreset(presetRow, "MAX CLEAN", new int[]{12,12,10,6,1,0,0,1,2,2}, 100, 34, 100, 88, 22, 88);
        addPreset(presetRow, "CLEAN", new int[]{0,0,0,0,0,0,0,0,0,0}, 0, 0, 0, 0, 0, 35);
        addPreset(presetRow, "PREMIUM", new int[]{7,7,6,4,2,0,0,0,1,1}, 72, 12, 62, 48, 16, 68);
        addPreset(presetRow, "DEEP CLEAN", new int[]{10,10,8,4,1,0,-1,0,1,1}, 82, 10, 88, 38, 12, 82);
        addPreset(presetRow, "CLUB", new int[]{9,9,8,6,3,0,0,1,2,2}, 88, 15, 72, 78, 24, 62);
        addPreset(presetRow, "CINEMA", new int[]{11,10,8,5,2,0,0,1,2,3}, 88, 12, 84, 58, 38, 58);
        addPreset(presetRow, "EARTHQUAKE", new int[]{12,12,10,7,3,0,-2,-1,1,2}, 100, 12, 94, 72, 22, 72);
        addPreset(presetRow, "ABYSS+", new int[]{12,12,11,7,2,-1,-2,-1,1,2}, 100, 8, 100, 84, 26, 82);

        sectionTitle(root, "PROFILES & QUICK CONTROLS");
        HorizontalScrollView profileScroll = new HorizontalScrollView(this);
        profileScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout profileRow = new LinearLayout(this);
        profileRow.setOrientation(LinearLayout.HORIZONTAL);
        profileScroll.addView(profileRow);
        root.addView(profileScroll, marginTop(8));

        addActionButton(profileRow, "HEADPHONES", () -> applyProfile("headphones"));
        addActionButton(profileRow, "SPEAKER", () -> applyProfile("speaker"));
        addActionButton(profileRow, "GAMING", () -> applyProfile("gaming"));
        addActionButton(profileRow, "MUSIC", () -> applyProfile("music"));
        addActionButton(profileRow, "NIGHT", () -> applyProfile("night"));
        addActionButton(profileRow, "SAVE CUSTOM", this::saveCustomPreset);
        addActionButton(profileRow, "LOAD CUSTOM", this::loadCustomPreset);
        addActionButton(profileRow, "CHANGELOG", this::showChangelog);

        sectionTitle(root, "BASS CHARACTER");
        HorizontalScrollView qualityScroll = new HorizontalScrollView(this);
        qualityScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout qualityRow = new LinearLayout(this);
        qualityRow.setOrientation(LinearLayout.HORIZONTAL);
        qualityScroll.addView(qualityRow);
        root.addView(qualityScroll, marginTop(8));
        addActionButton(qualityRow, "SOFT", () -> setQuality(0));
        addActionButton(qualityRow, "CLEAN", () -> setQuality(1));
        addActionButton(qualityRow, "HARD", () -> setQuality(2));
        addActionButton(qualityRow, "BRUTAL", () -> setQuality(3));

        LinearLayout subCard = card();
        subCard.setOrientation(LinearLayout.VERTICAL);
        subCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(subCard, marginTop(18));

        LinearLayout subHeader = new LinearLayout(this);
        subHeader.setOrientation(LinearLayout.HORIZONTAL);
        subHeader.setGravity(Gravity.CENTER_VERTICAL);
        TextView subTitle = text("SUB BASS", 15, TEXT, true);
        subHeader.addView(subTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        subValue = text("55%", 14, ACCENT, true);
        subHeader.addView(subValue);
        subCard.addView(subHeader);
        subCard.addView(text("Deep 31–125 Hz weight • higher bass now also adds controlled loudness", 12, MUTED, false), marginTop(3));
        subBar = seek(0, 100);
        subBar.setProgress(prefs.getInt("sub", 55));
        subCard.addView(subBar, marginTop(9));
        subBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            subValue.setText(v + "%");
            prefs.edit().putInt("sub", v).apply();
            queueUpdate();
        }));

        LinearLayout punchCard = card();
        punchCard.setOrientation(LinearLayout.VERTICAL);
        punchCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(punchCard, marginTop(12));

        LinearLayout punchHeader = new LinearLayout(this);
        punchHeader.setOrientation(LinearLayout.HORIZONTAL);
        punchHeader.setGravity(Gravity.CENTER_VERTICAL);
        TextView punchTitle = text("PUNCH", 15, TEXT, true);
        punchHeader.addView(punchTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        punchValue = text("45%", 14, ACCENT, true);
        punchHeader.addView(punchValue);
        punchCard.addView(punchHeader);
        punchCard.addView(text("Kick impact around 90–280 Hz", 12, MUTED, false), marginTop(3));
        punchBar = seek(0, 100);
        punchBar.setProgress(prefs.getInt("punch", 45));
        punchCard.addView(punchBar, marginTop(9));
        punchBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            punchValue.setText(v + "%");
            prefs.edit().putInt("punch", v).apply();
            queueUpdate();
        }));

        LinearLayout clarityCard = card();
        clarityCard.setOrientation(LinearLayout.VERTICAL);
        clarityCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(clarityCard, marginTop(12));

        LinearLayout clarityHeader = new LinearLayout(this);
        clarityHeader.setOrientation(LinearLayout.HORIZONTAL);
        clarityHeader.setGravity(Gravity.CENTER_VERTICAL);
        TextView clarityTitle = text("CLEAN BASS / ANTI-MUD", 15, TEXT, true);
        clarityHeader.addView(clarityTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        clarityValue = text("55%", 14, ACCENT, true);
        clarityHeader.addView(clarityValue);
        clarityCard.addView(clarityHeader);
        clarityCard.addView(text("Reduces low-mid mud and restores definition around vocals and percussion", 12, MUTED, false), marginTop(3));
        clarityBar = seek(0, 100);
        clarityBar.setProgress(prefs.getInt("clarity", 55));
        clarityCard.addView(clarityBar, marginTop(9));
        clarityBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            clarityValue.setText(v + "%");
            prefs.edit().putInt("clarity", v).apply();
            queueUpdate();
        }));

        LinearLayout widthCard = card();
        widthCard.setOrientation(LinearLayout.VERTICAL);
        widthCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(widthCard, marginTop(12));

        LinearLayout widthHeader = new LinearLayout(this);
        widthHeader.setOrientation(LinearLayout.HORIZONTAL);
        widthHeader.setGravity(Gravity.CENTER_VERTICAL);
        TextView widthTitle = text("WIDTH / SPACE", 15, TEXT, true);
        widthHeader.addView(widthTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        widthValue = text("20%", 14, ACCENT, true);
        widthHeader.addView(widthValue);
        widthCard.addView(widthHeader);
        widthCard.addView(text("Android virtualizer for a wider headphone image", 12, MUTED, false), marginTop(3));
        widthBar = seek(0, 100);
        widthBar.setProgress(prefs.getInt("width", 20));
        widthCard.addView(widthBar, marginTop(9));
        widthBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            widthValue.setText(v + "%");
            prefs.edit().putInt("width", v).apply();
            queueUpdate();
        }));

        LinearLayout bassCard = card();
        bassCard.setOrientation(LinearLayout.VERTICAL);
        bassCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(bassCard, marginTop(18));

        LinearLayout bassHeader = rowBetween();
        bassHeader.addView(text("BASS ENGINE", 15, TEXT, true));
        bassValue = text("65%", 14, ACCENT, true);
        bassHeader.addView(bassValue);
        bassCard.addView(bassHeader);

        TextView bassDesc = text("Low-end impact + hardware bass boost", 12, MUTED, false);
        bassCard.addView(bassDesc, marginTop(3));

        bassBar = seek(0, 100);
        bassBar.setProgress(prefs.getInt("bass", 65));
        bassCard.addView(bassBar, marginTop(9));
        bassBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            bassValue.setText(v + "%");
            prefs.edit().putInt("bass", v).apply();
            queueUpdate();
        }));

        LinearLayout loudCard = card();
        loudCard.setOrientation(LinearLayout.VERTICAL);
        loudCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(loudCard, marginTop(12));

        LinearLayout loudHeader = rowBetween();
        loudHeader.addView(text("LOUDNESS", 15, TEXT, true));
        loudnessValue = text("+0.0 dB", 14, ACCENT, true);
        loudHeader.addView(loudnessValue);
        loudCard.addView(loudHeader);
        loudCard.addView(text("Extra output gain • also follows Bass strength automatically", 12, MUTED, false), marginTop(3));

        loudnessBar = seek(0, 100);
        loudnessBar.setProgress(prefs.getInt("loudness", 20));
        loudCard.addView(loudnessBar, marginTop(9));
        loudnessBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            loudnessValue.setText(String.format("+%.1f dB", v * 0.05f));
            prefs.edit().putInt("loudness", v).apply();
            queueUpdate();
        }));

        sectionTitle(root, "SONIC CORE • AUTO QUALITY");

        LinearLayout sonicCard = card();
        sonicCard.setOrientation(LinearLayout.VERTICAL);
        sonicCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(sonicCard, marginTop(8));

        LinearLayout sonicHeader = new LinearLayout(this);
        sonicHeader.setOrientation(LinearLayout.HORIZONTAL);
        sonicHeader.setGravity(Gravity.CENTER_VERTICAL);
        TextView sonicTitle = text("QUALITY ENGINE STRENGTH", 15, TEXT, true);
        sonicHeader.addView(sonicTitle, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        sonicStrengthValue = text("78%", 14, ACCENT, true);
        sonicHeader.addView(sonicStrengthValue);
        sonicCard.addView(sonicHeader);
        sonicCard.addView(text("Automatically tightens bass, restores clarity and protects digital headroom", 12, MUTED, false), marginTop(3));

        sonicStrengthBar = seek(0, 100);
        sonicStrengthBar.setProgress(prefs.getInt("sonic_strength", 78));
        sonicCard.addView(sonicStrengthBar, marginTop(9));
        sonicStrengthBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            sonicStrengthValue.setText(v + "%");
            prefs.edit().putInt("sonic_strength", v).apply();
            queueUpdate();
        }));

        HorizontalScrollView sonicActions = new HorizontalScrollView(this);
        sonicActions.setHorizontalScrollBarEnabled(false);
        LinearLayout sonicActionRow = new LinearLayout(this);
        sonicActionRow.setOrientation(LinearLayout.HORIZONTAL);
        sonicActions.addView(sonicActionRow);
        root.addView(sonicActions, marginTop(8));
        addActionButton(sonicActionRow, "AUTO QUALITY MAX", this::enableSonicCoreMax);
        addActionButton(sonicActionRow, "QUALITY BALANCED", this::enableSonicCoreBalanced);

        addQualitySwitch(root, "SONIC CORE", "Master automatic quality processing", "sonic_core");
        addQualitySwitch(root, "CURVE SMOOTHING", "Smooths harsh EQ jumps between bands", "curve_smoothing");
        addQualitySwitch(root, "AUTO ANTI-MUD", "Cleans 180–850 Hz more when bass is heavy", "auto_clean");
        addQualitySwitch(root, "BASS DEFINITION", "Tightens the sub-to-midbass transition", "bass_definition");
        addQualitySwitch(root, "CLARITY RESTORE", "Restores detail that strong bass can mask", "clarity_restore");
        addQualitySwitch(root, "TRANSIENT FOCUS", "Adds cleaner kick attack and percussion definition", "transient_focus");
        addQualitySwitch(root, "STEREO GUARD", "Reduces excessive width when low-end load is high", "stereo_guard");
        addQualitySwitch(root, "ADAPTIVE HEADROOM", "Automatically creates more digital space at extreme settings", "adaptive_headroom");

        sectionTitle(root, "OVERDRIVE CONTROL");

        LinearLayout intensityCard = card();
        intensityCard.setOrientation(LinearLayout.VERTICAL);
        intensityCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(intensityCard, marginTop(8));
        LinearLayout ih = new LinearLayout(this);
        ih.setOrientation(LinearLayout.HORIZONTAL);
        ih.setGravity(Gravity.CENTER_VERTICAL);
        TextView it = text("MASTER INTENSITY", 15, TEXT, true);
        ih.addView(it, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        intensityValue = text("100%", 14, ACCENT, true);
        ih.addView(intensityValue);
        intensityCard.addView(ih);
        intensityCard.addView(text("Scales the complete DSP curve from 50% to 150%", 12, MUTED, false), marginTop(3));
        intensityBar = seek(50, 150);
        intensityBar.setProgress(prefs.getInt("intensity", 100));
        intensityCard.addView(intensityBar, marginTop(9));
        intensityBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            intensityValue.setText(v + "%");
            prefs.edit().putInt("intensity", v).apply();
            queueUpdate();
        }));

        LinearLayout warmthCard = card();
        warmthCard.setOrientation(LinearLayout.VERTICAL);
        warmthCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(warmthCard, marginTop(12));
        LinearLayout wh = new LinearLayout(this);
        wh.setOrientation(LinearLayout.HORIZONTAL);
        wh.setGravity(Gravity.CENTER_VERTICAL);
        TextView wt = text("WARMTH", 15, TEXT, true);
        wh.addView(wt, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        warmthValue = text("35%", 14, ACCENT, true);
        wh.addView(warmthValue);
        warmthCard.addView(wh);
        warmthCard.addView(text("Adds body around 120–500 Hz", 12, MUTED, false), marginTop(3));
        warmthBar = seek(0, 100);
        warmthBar.setProgress(prefs.getInt("warmth", 35));
        warmthCard.addView(warmthBar, marginTop(9));
        warmthBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            warmthValue.setText(v + "%");
            prefs.edit().putInt("warmth", v).apply();
            queueUpdate();
        }));

        LinearLayout presenceCard = card();
        presenceCard.setOrientation(LinearLayout.VERTICAL);
        presenceCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(presenceCard, marginTop(12));
        LinearLayout ph = new LinearLayout(this);
        ph.setOrientation(LinearLayout.HORIZONTAL);
        ph.setGravity(Gravity.CENTER_VERTICAL);
        TextView pt = text("PRESENCE", 15, TEXT, true);
        ph.addView(pt, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        presenceValue = text("40%", 14, ACCENT, true);
        ph.addView(presenceValue);
        presenceCard.addView(ph);
        presenceCard.addView(text("Brings detail forward around 1.2–5.2 kHz", 12, MUTED, false), marginTop(3));
        presenceBar = seek(0, 100);
        presenceBar.setProgress(prefs.getInt("presence", 40));
        presenceCard.addView(presenceBar, marginTop(9));
        presenceBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            presenceValue.setText(v + "%");
            prefs.edit().putInt("presence", v).apply();
            queueUpdate();
        }));

        LinearLayout lmcCard = card();
        lmcCard.setOrientation(LinearLayout.VERTICAL);
        lmcCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(lmcCard, marginTop(12));
        LinearLayout lmh = new LinearLayout(this);
        lmh.setOrientation(LinearLayout.HORIZONTAL);
        lmh.setGravity(Gravity.CENTER_VERTICAL);
        TextView lmt = text("LOW-MID CUT", 15, TEXT, true);
        lmh.addView(lmt, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        lowMidCutValue = text("35%", 14, ACCENT, true);
        lmh.addView(lowMidCutValue);
        lmcCard.addView(lmh);
        lmcCard.addView(text("Removes boxiness/mud around 180–700 Hz", 12, MUTED, false), marginTop(3));
        lowMidCutBar = seek(0, 100);
        lowMidCutBar.setProgress(prefs.getInt("low_mid_cut", 35));
        lmcCard.addView(lowMidCutBar, marginTop(9));
        lowMidCutBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            lowMidCutValue.setText(v + "%");
            prefs.edit().putInt("low_mid_cut", v).apply();
            queueUpdate();
        }));

        LinearLayout ceilingCard = card();
        ceilingCard.setOrientation(LinearLayout.VERTICAL);
        ceilingCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(ceilingCard, marginTop(12));
        LinearLayout gh = new LinearLayout(this);
        gh.setOrientation(LinearLayout.HORIZONTAL);
        gh.setGravity(Gravity.CENTER_VERTICAL);
        TextView gt = text("GAIN CEILING", 15, TEXT, true);
        gh.addView(gt, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        gainCeilingValue = text("+5 dB", 14, ACCENT, true);
        gh.addView(gainCeilingValue);
        ceilingCard.addView(gh);
        ceilingCard.addView(text("Caps BassForge's extra digital output gain", 12, MUTED, false), marginTop(3));
        gainCeilingBar = seek(0, 6);
        gainCeilingBar.setProgress(prefs.getInt("gain_ceiling", 5));
        ceilingCard.addView(gainCeilingBar, marginTop(9));
        gainCeilingBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            gainCeilingValue.setText("+" + v + " dB");
            prefs.edit().putInt("gain_ceiling", v).apply();
            queueUpdate();
        }));

        sectionTitle(root, "REDLINE ADVANCED");

        LinearLayout subFocusCard = card();
        subFocusCard.setOrientation(LinearLayout.VERTICAL);
        subFocusCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(subFocusCard, marginTop(8));
        LinearLayout sfh = new LinearLayout(this);
        sfh.setOrientation(LinearLayout.HORIZONTAL);
        sfh.setGravity(Gravity.CENTER_VERTICAL);
        TextView sft = text("SUB FOCUS", 15, TEXT, true);
        sfh.addView(sft, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        subFocusValue = text("49 Hz", 14, ACCENT, true);
        sfh.addView(subFocusValue);
        subFocusCard.addView(sfh);
        subFocusCard.addView(text("Moves the deepest bass focus from ~32 Hz to ~80 Hz", 12, MUTED, false), marginTop(3));
        subFocusBar = seek(0, 100);
        subFocusBar.setProgress(prefs.getInt("sub_focus", 35));
        subFocusCard.addView(subFocusBar, marginTop(9));
        subFocusBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            subFocusValue.setText((32 + Math.round(v * 0.48f)) + " Hz");
            prefs.edit().putInt("sub_focus", v).apply();
            queueUpdate();
        }));

        LinearLayout punchFocusCard = card();
        punchFocusCard.setOrientation(LinearLayout.VERTICAL);
        punchFocusCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(punchFocusCard, marginTop(12));
        LinearLayout pfh = new LinearLayout(this);
        pfh.setOrientation(LinearLayout.HORIZONTAL);
        pfh.setGravity(Gravity.CENTER_VERTICAL);
        TextView pft = text("PUNCH FOCUS", 15, TEXT, true);
        pfh.addView(pft, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        punchFocusValue = text("165 Hz", 14, ACCENT, true);
        pfh.addView(punchFocusValue);
        punchFocusCard.addView(pfh);
        punchFocusCard.addView(text("Moves the kick impact from ~90 Hz to ~240 Hz", 12, MUTED, false), marginTop(3));
        punchFocusBar = seek(0, 100);
        punchFocusBar.setProgress(prefs.getInt("punch_focus", 50));
        punchFocusCard.addView(punchFocusBar, marginTop(9));
        punchFocusBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            punchFocusValue.setText((90 + Math.round(v * 1.5f)) + " Hz");
            prefs.edit().putInt("punch_focus", v).apply();
            queueUpdate();
        }));

        LinearLayout trebleCard = card();
        trebleCard.setOrientation(LinearLayout.VERTICAL);
        trebleCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(trebleCard, marginTop(12));
        LinearLayout th = new LinearLayout(this);
        th.setOrientation(LinearLayout.HORIZONTAL);
        th.setGravity(Gravity.CENTER_VERTICAL);
        TextView tt = text("TREBLE / AIR", 15, TEXT, true);
        th.addView(tt, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        trebleValue = text("40%", 14, ACCENT, true);
        th.addView(trebleValue);
        trebleCard.addView(th);
        trebleCard.addView(text("Restores top-end detail when bass is very strong", 12, MUTED, false), marginTop(3));
        trebleBar = seek(0, 100);
        trebleBar.setProgress(prefs.getInt("treble", 40));
        trebleCard.addView(trebleBar, marginTop(9));
        trebleBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            trebleValue.setText(v + "%");
            prefs.edit().putInt("treble", v).apply();
            queueUpdate();
        }));

        LinearLayout vocalCard = card();
        vocalCard.setOrientation(LinearLayout.VERTICAL);
        vocalCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        root.addView(vocalCard, marginTop(12));
        LinearLayout vh = new LinearLayout(this);
        vh.setOrientation(LinearLayout.HORIZONTAL);
        vh.setGravity(Gravity.CENTER_VERTICAL);
        TextView vt = text("VOCAL PROTECTION", 15, TEXT, true);
        vh.addView(vt, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        vocalValue = text("55%", 14, ACCENT, true);
        vh.addView(vocalValue);
        vocalCard.addView(vh);
        vocalCard.addView(text("Keeps mids and vocals from disappearing behind the low end", 12, MUTED, false), marginTop(3));
        vocalBar = seek(0, 100);
        vocalBar.setProgress(prefs.getInt("vocal", 55));
        vocalCard.addView(vocalBar, marginTop(9));
        vocalBar.setOnSeekBarChangeListener(simpleSeek(v -> {
            vocalValue.setText(v + "%");
            prefs.edit().putInt("vocal", v).apply();
            queueUpdate();
        }));

        LinearLayout dynamicCard = card();
        dynamicCard.setOrientation(LinearLayout.HORIZONTAL);
        dynamicCard.setGravity(Gravity.CENTER_VERTICAL);
        dynamicCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        root.addView(dynamicCard, marginTop(12));
        LinearLayout dynText = new LinearLayout(this);
        dynText.setOrientation(LinearLayout.VERTICAL);
        dynamicCard.addView(dynText, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        dynText.addView(text("DYNAMIC BASS CURVE", 14, TEXT, true));
        dynText.addView(text("Non-linear shaping for stronger bass without only adding gain", 11, MUTED, false), marginTop(2));
        dynamicBassSwitch = new Switch(this);
        dynamicBassSwitch.setChecked(prefs.getBoolean("dynamic_bass", true));
        dynamicCard.addView(dynamicBassSwitch);
        dynamicBassSwitch.setOnCheckedChangeListener((b, checked) -> {
            if (buildingUi) return;
            prefs.edit().putBoolean("dynamic_bass", checked).apply();
            queueUpdate();
        });

        LinearLayout autoGainCard = card();
        autoGainCard.setOrientation(LinearLayout.HORIZONTAL);
        autoGainCard.setGravity(Gravity.CENTER_VERTICAL);
        autoGainCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        root.addView(autoGainCard, marginTop(12));
        LinearLayout agText = new LinearLayout(this);
        agText.setOrientation(LinearLayout.VERTICAL);
        autoGainCard.addView(agText, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        agText.addView(text("AUTO GAIN / LIMITER V2", 14, TEXT, true));
        agText.addView(text("Reduces excessive gain when the EQ curve gets extreme", 11, MUTED, false), marginTop(2));
        autoGainSwitch = new Switch(this);
        autoGainSwitch.setChecked(prefs.getBoolean("auto_gain", true));
        autoGainCard.addView(autoGainSwitch);
        autoGainSwitch.setOnCheckedChangeListener((b, checked) -> {
            if (buildingUi) return;
            prefs.edit().putBoolean("auto_gain", checked).apply();
            queueUpdate();
        });

        sectionTitle(root, "PRESET LAB");
        HorizontalScrollView labScroll = new HorizontalScrollView(this);
        labScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout labRow = new LinearLayout(this);
        labRow.setOrientation(LinearLayout.HORIZONTAL);
        labScroll.addView(labRow);
        root.addView(labScroll, marginTop(8));
        addActionButton(labRow, "SAVE S1", () -> saveSlot(1));
        addActionButton(labRow, "LOAD S1", () -> loadSlot(1));
        addActionButton(labRow, "SAVE S2", () -> saveSlot(2));
        addActionButton(labRow, "LOAD S2", () -> loadSlot(2));
        addActionButton(labRow, "SAVE S3", () -> saveSlot(3));
        addActionButton(labRow, "LOAD S3", () -> loadSlot(3));

        HorizontalScrollView abScroll = new HorizontalScrollView(this);
        abScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout abRow = new LinearLayout(this);
        abRow.setOrientation(LinearLayout.HORIZONTAL);
        abScroll.addView(abRow);
        root.addView(abScroll, marginTop(8));
        addActionButton(abRow, "SAVE A", () -> saveSlot(10));
        addActionButton(abRow, "LOAD A", () -> loadSlot(10));
        addActionButton(abRow, "SAVE B", () -> saveSlot(11));
        addActionButton(abRow, "LOAD B", () -> loadSlot(11));
        addActionButton(abRow, "EXPORT", this::exportSettings);
        addActionButton(abRow, "IMPORT", this::importSettings);
        addActionButton(abRow, "DIAGNOSTICS", this::showDiagnostics);
        addActionButton(abRow, "RESET", this::resetDefaults);

        sectionTitle(root, "AUTOMATION");

        LinearLayout autoProfileCard = card();
        autoProfileCard.setOrientation(LinearLayout.HORIZONTAL);
        autoProfileCard.setGravity(Gravity.CENTER_VERTICAL);
        autoProfileCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        root.addView(autoProfileCard, marginTop(8));
        LinearLayout apText = new LinearLayout(this);
        apText.setOrientation(LinearLayout.VERTICAL);
        autoProfileCard.addView(apText, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        apText.addView(text("AUTO DEVICE PROFILE", 14, TEXT, true));
        apText.addView(text("Adjusts profile when headphones or speaker output is detected", 11, MUTED, false), marginTop(2));
        autoProfileSwitch = new Switch(this);
        autoProfileSwitch.setChecked(prefs.getBoolean("auto_profile", false));
        autoProfileCard.addView(autoProfileSwitch);
        autoProfileSwitch.setOnCheckedChangeListener((b, checked) -> {
            if (buildingUi) return;
            prefs.edit().putBoolean("auto_profile", checked).apply();
        });

        LinearLayout autoStartCard = card();
        autoStartCard.setOrientation(LinearLayout.HORIZONTAL);
        autoStartCard.setGravity(Gravity.CENTER_VERTICAL);
        autoStartCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        root.addView(autoStartCard, marginTop(12));
        LinearLayout asText = new LinearLayout(this);
        asText.setOrientation(LinearLayout.VERTICAL);
        autoStartCard.addView(asText, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        asText.addView(text("BOOT RESTART REMINDER", 14, TEXT, true));
        asText.addView(text("Shows a tap-to-restart reminder after reboot on modern Android", 11, MUTED, false), marginTop(2));
        autoStartSwitch = new Switch(this);
        autoStartSwitch.setChecked(prefs.getBoolean("auto_start", false));
        autoStartCard.addView(autoStartSwitch);
        autoStartSwitch.setOnCheckedChangeListener((b, checked) -> {
            if (buildingUi) return;
            prefs.edit().putBoolean("auto_start", checked).apply();
        });

        sectionTitle(root, "10-BAND CURVE");

        LinearLayout eqCard = card();
        eqCard.setOrientation(LinearLayout.VERTICAL);
        eqCard.setPadding(dp(14), dp(10), dp(14), dp(10));
        root.addView(eqCard, marginTop(8));

        for (int i = 0; i < 10; i++) {
            eqCard.addView(buildBandRow(i));
        }

        LinearLayout safety = new LinearLayout(this);
        safety.setOrientation(LinearLayout.VERTICAL);
        safety.setPadding(dp(15), dp(14), dp(15), dp(14));
        safety.setBackground(roundRect(Color.rgb(15, 29, 23), dp(16), Color.TRANSPARENT, 0));
        root.addView(safety, marginTop(16));
        safety.addView(text("REDLINE LIMITER V2 • DIGITAL HEADROOM", 13, GREEN, true));
        safety.addView(text(
                "V4 REDLINE combines bass-linked loudness, Auto Gain, focus shaping and anti-mud processing. It reduces digital overload, but your phone volume still controls how loud your headphones actually are.",
                12, Color.rgb(184, 207, 193), false), marginTop(4));

        TextView compat = text(
                "Compatibility: BassForge tries Android's global mix first and also listens for player audio sessions. Some phones or apps can block third-party system-wide effects.",
                11, MUTED, false);
        compat.setLineSpacing(0f, 1.15f);
        root.addView(compat, marginTop(14));

        return scroll;
    }

    private View buildBandRow(int index) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(0, dp(6), 0, dp(6));

        TextView name = text(BAND_NAMES[index] + " Hz", 12, TEXT, true);
        LinearLayout.LayoutParams nameLp = new LinearLayout.LayoutParams(dp(58), ViewGroup.LayoutParams.WRAP_CONTENT);
        row.addView(name, nameLp);

        SeekBar bar = seek(0, 24);
        bar.setProgress(curve[index] + 12);
        LinearLayout.LayoutParams barLp = new LinearLayout.LayoutParams(0, dp(38), 1f);
        row.addView(bar, barLp);

        TextView value = text(formatDb(curve[index]), 12, ACCENT, true);
        value.setGravity(Gravity.END);
        LinearLayout.LayoutParams valueLp = new LinearLayout.LayoutParams(dp(52), ViewGroup.LayoutParams.WRAP_CONTENT);
        row.addView(value, valueLp);

        bandBars.add(bar);
        bandValues.add(value);

        final int band = index;
        bar.setOnSeekBarChangeListener(simpleSeek(v -> {
            curve[band] = v - 12;
            value.setText(formatDb(curve[band]));
            saveCurve();
            queueUpdate();
        }));

        return row;
    }

    private void addPreset(LinearLayout row, String name, int[] presetCurve, int bass, int loudness, int sub, int punch, int width, int clarity) {
        TextView button = text(name, 12, TEXT, true);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(14), dp(10), dp(14), dp(10));
        button.setBackground(roundRect(CARD_2, dp(14), Color.rgb(48, 48, 58), dp(1)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, 0, dp(8), 0);
        row.addView(button, lp);

        button.setOnClickListener(v -> {
            System.arraycopy(presetCurve, 0, curve, 0, curve.length);
            prefs.edit()
                    .putInt("bass", bass)
                    .putInt("loudness", loudness)
                    .putInt("sub", sub)
                    .putInt("punch", punch)
                    .putInt("width", width)
                    .putInt("clarity", clarity)
                    .apply();
            if ("MAX CLEAN".equals(name)) {
                prefs.edit()
                        .putInt("treble", 54)
                        .putInt("sub_focus", 34)
                        .putInt("punch_focus", 48)
                        .putInt("vocal", 78)
                        .putBoolean("dynamic_bass", true)
                        .putBoolean("auto_gain", true)
                        .putInt("quality", 2)
                        .apply();
            }
            saveCurve();
            refreshControls();
            queueUpdate();
        });
    }

    private void refreshControls() {
        for (int i = 0; i < bandBars.size() && i < curve.length; i++) {
            bandBars.get(i).setProgress(curve[i] + 12);
            bandValues.get(i).setText(formatDb(curve[i]));
        }
        int bass = prefs.getInt("bass", 68);
        int loudness = prefs.getInt("loudness", 16);
        int sub = prefs.getInt("sub", 55);
        int punch = prefs.getInt("punch", 45);
        int width = prefs.getInt("width", 20);
        int clarity = prefs.getInt("clarity", 55);
        if (bassBar != null) bassBar.setProgress(bass);
        if (loudnessBar != null) loudnessBar.setProgress(loudness);
        if (subBar != null) subBar.setProgress(sub);
        if (punchBar != null) punchBar.setProgress(punch);
        if (widthBar != null) widthBar.setProgress(width);
        if (clarityBar != null) clarityBar.setProgress(clarity);
        if (bassValue != null) bassValue.setText(bass + "%");
        if (loudnessValue != null) loudnessValue.setText(String.format("+%.1f dB", loudness * 0.05f));
        if (subValue != null) subValue.setText(sub + "%");
        if (punchValue != null) punchValue.setText(punch + "%");
        if (widthValue != null) widthValue.setText(width + "%");
        if (clarityValue != null) clarityValue.setText(clarity + "%");
        int treble = prefs.getInt("treble", 40);
        int subFocus = prefs.getInt("sub_focus", 35);
        int punchFocus = prefs.getInt("punch_focus", 50);
        int vocal = prefs.getInt("vocal", 55);
        if (trebleBar != null) trebleBar.setProgress(treble);
        if (subFocusBar != null) subFocusBar.setProgress(subFocus);
        if (punchFocusBar != null) punchFocusBar.setProgress(punchFocus);
        if (vocalBar != null) vocalBar.setProgress(vocal);
        if (trebleValue != null) trebleValue.setText(treble + "%");
        if (subFocusValue != null) subFocusValue.setText((32 + Math.round(subFocus * 0.48f)) + " Hz");
        if (punchFocusValue != null) punchFocusValue.setText((90 + Math.round(punchFocus * 1.5f)) + " Hz");
        if (vocalValue != null) vocalValue.setText(vocal + "%");
        if (dynamicBassSwitch != null) dynamicBassSwitch.setChecked(prefs.getBoolean("dynamic_bass", true));
        if (autoGainSwitch != null) autoGainSwitch.setChecked(prefs.getBoolean("auto_gain", true));
        int intensity = prefs.getInt("intensity", 100);
        int warmth = prefs.getInt("warmth", 35);
        int presence = prefs.getInt("presence", 40);
        int lowMidCut = prefs.getInt("low_mid_cut", 35);
        int gainCeiling = prefs.getInt("gain_ceiling", 5);
        if (intensityBar != null) intensityBar.setProgress(intensity);
        if (warmthBar != null) warmthBar.setProgress(warmth);
        if (presenceBar != null) presenceBar.setProgress(presence);
        if (lowMidCutBar != null) lowMidCutBar.setProgress(lowMidCut);
        if (gainCeilingBar != null) gainCeilingBar.setProgress(gainCeiling);
        if (intensityValue != null) intensityValue.setText(intensity + "%");
        if (warmthValue != null) warmthValue.setText(warmth + "%");
        if (presenceValue != null) presenceValue.setText(presence + "%");
        if (lowMidCutValue != null) lowMidCutValue.setText(lowMidCut + "%");
        if (gainCeilingValue != null) gainCeilingValue.setText("+" + gainCeiling + " dB");
        if (autoProfileSwitch != null) autoProfileSwitch.setChecked(prefs.getBoolean("auto_profile", false));
        if (autoStartSwitch != null) autoStartSwitch.setChecked(prefs.getBoolean("auto_start", false));
        int sonicStrength = prefs.getInt("sonic_strength", 78);
        if (sonicStrengthBar != null) sonicStrengthBar.setProgress(sonicStrength);
        if (sonicStrengthValue != null) sonicStrengthValue.setText(sonicStrength + "%");
        for (int i = 0; i < qualitySwitches.size() && i < qualitySwitchKeys.size(); i++) {
            qualitySwitches.get(i).setChecked(prefs.getBoolean(qualitySwitchKeys.get(i), true));
        }
    }

    private void saveCurve() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < curve.length; i++) {
            if (i > 0) sb.append(',');
            sb.append(curve[i]);
        }
        prefs.edit().putString("curve", sb.toString()).apply();
    }

    private void queueUpdate() {
        if (buildingUi) return;
        handler.removeCallbacks(pushUpdate);
        handler.postDelayed(pushUpdate, 80);
    }

    private void sendUpdateNow() {
        if (!prefs.getBoolean("engine_enabled", false)) return;
        startEngine(BassService.ACTION_UPDATE);
        refreshStatusDelayed();
    }

    private void startEngine(String action) {
        Intent i = new Intent(this, BassService.class);
        i.setAction(action);
        try {
            if (Build.VERSION.SDK_INT >= 26 && !BassService.ACTION_STOP.equals(action)) {
                startForegroundService(i);
            } else {
                startService(i);
            }
        } catch (Exception e) {
            statusText.setText("Audio engine blocked by this device");
            statusText.setTextColor(ACCENT);
        }
    }

    private void refreshStatusDelayed() {
        handler.postDelayed(() -> {
            if (statusText == null) return;
            boolean on = prefs.getBoolean("engine_enabled", false);
            String status = on
                    ? prefs.getString("engine_status", "Starting audio engine…")
                    : "Engine off";
            statusText.setText(status);
            statusText.setTextColor(on ? GREEN : MUTED);
        }, 450);
    }

    private void initV6Defaults() {
        if (prefs.getBoolean("v6_defaults_applied", false)) return;
        prefs.edit()
                .putBoolean("sonic_core", true)
                .putInt("sonic_strength", 78)
                .putBoolean("curve_smoothing", true)
                .putBoolean("auto_clean", true)
                .putBoolean("bass_definition", true)
                .putBoolean("clarity_restore", true)
                .putBoolean("transient_focus", true)
                .putBoolean("stereo_guard", true)
                .putBoolean("adaptive_headroom", true)
                .putBoolean("auto_profile", true)
                .putBoolean("auto_gain", true)
                .putBoolean("dynamic_bass", true)
                .putBoolean("v6_defaults_applied", true)
                .apply();
    }

    private void addQualitySwitch(LinearLayout root, String title, String description, String key) {
        LinearLayout qualityCard = card();
        qualityCard.setOrientation(LinearLayout.HORIZONTAL);
        qualityCard.setGravity(Gravity.CENTER_VERTICAL);
        qualityCard.setPadding(dp(16), dp(13), dp(16), dp(13));
        root.addView(qualityCard, marginTop(8));

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        qualityCard.addView(copy, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        copy.addView(text(title, 14, TEXT, true));
        copy.addView(text(description, 11, MUTED, false), marginTop(2));

        Switch sw = new Switch(this);
        sw.setChecked(prefs.getBoolean(key, true));
        qualityCard.addView(sw);
        qualitySwitches.add(sw);
        qualitySwitchKeys.add(key);

        sw.setOnCheckedChangeListener((button, checked) -> {
            if (buildingUi) return;
            prefs.edit().putBoolean(key, checked).apply();
            queueUpdate();
        });
    }

    private void enableSonicCoreMax() {
        prefs.edit()
                .putBoolean("sonic_core", true)
                .putInt("sonic_strength", 92)
                .putBoolean("curve_smoothing", true)
                .putBoolean("auto_clean", true)
                .putBoolean("bass_definition", true)
                .putBoolean("clarity_restore", true)
                .putBoolean("transient_focus", true)
                .putBoolean("stereo_guard", true)
                .putBoolean("adaptive_headroom", true)
                .putBoolean("auto_profile", true)
                .putBoolean("auto_gain", true)
                .putBoolean("dynamic_bass", true)
                .apply();
        refreshControls();
        queueUpdate();
        Toast.makeText(this, "SONIC CORE MAX enabled", Toast.LENGTH_SHORT).show();
    }

    private void enableSonicCoreBalanced() {
        prefs.edit()
                .putBoolean("sonic_core", true)
                .putInt("sonic_strength", 72)
                .putBoolean("curve_smoothing", true)
                .putBoolean("auto_clean", true)
                .putBoolean("bass_definition", true)
                .putBoolean("clarity_restore", true)
                .putBoolean("transient_focus", true)
                .putBoolean("stereo_guard", true)
                .putBoolean("adaptive_headroom", true)
                .putBoolean("auto_gain", true)
                .apply();
        refreshControls();
        queueUpdate();
        Toast.makeText(this, "Balanced quality engine enabled", Toast.LENGTH_SHORT).show();
    }

    private static final String[] SNAPSHOT_KEYS = {
            "bass","loudness","sub","punch","width","clarity","treble",
            "sub_focus","punch_focus","vocal","quality","intensity",
            "warmth","presence","low_mid_cut","gain_ceiling","sonic_strength"
    };
    private static final int[] SNAPSHOT_DEFAULTS = {
            68,16,55,45,20,55,40,35,50,55,1,100,35,40,35,5,78
    };

    private static final String[] QUALITY_BOOL_KEYS = {
            "dynamic_bass","auto_gain","sonic_core","curve_smoothing","auto_clean",
            "bass_definition","clarity_restore","transient_focus","stereo_guard",
            "adaptive_headroom","auto_profile"
    };

    private void saveSlot(int slot) {
        saveCurve();
        SharedPreferences.Editor e = prefs.edit();
        String p = "slot" + slot + "_";
        e.putString(p + "curve", prefs.getString("curve", "0,0,0,0,0,0,0,0,0,0"));
        for (int i = 0; i < SNAPSHOT_KEYS.length; i++) {
            e.putInt(p + SNAPSHOT_KEYS[i], prefs.getInt(SNAPSHOT_KEYS[i], SNAPSHOT_DEFAULTS[i]));
        }
        for (String key : QUALITY_BOOL_KEYS) {
            e.putBoolean(p + key, prefs.getBoolean(key, true));
        }
        e.putBoolean(p + "saved", true);
        e.apply();
        Toast.makeText(this, slot == 10 ? "A saved" : slot == 11 ? "B saved" : "Slot " + slot + " saved", Toast.LENGTH_SHORT).show();
    }

    private void loadSlot(int slot) {
        String p = "slot" + slot + "_";
        if (!prefs.getBoolean(p + "saved", false)) {
            Toast.makeText(this, "Nothing saved here yet", Toast.LENGTH_SHORT).show();
            return;
        }
        SharedPreferences.Editor e = prefs.edit();
        e.putString("curve", prefs.getString(p + "curve", "0,0,0,0,0,0,0,0,0,0"));
        for (int i = 0; i < SNAPSHOT_KEYS.length; i++) {
            e.putInt(SNAPSHOT_KEYS[i], prefs.getInt(p + SNAPSHOT_KEYS[i], SNAPSHOT_DEFAULTS[i]));
        }
        for (String key : QUALITY_BOOL_KEYS) {
            e.putBoolean(key, prefs.getBoolean(p + key, true));
        }
        e.apply();
        loadState();
        refreshControls();
        queueUpdate();
    }

    private void exportSettings() {
        saveCurve();
        StringBuilder out = new StringBuilder("BF5;");
        out.append("curve=").append(prefs.getString("curve", "")).append(';');
        for (int i = 0; i < SNAPSHOT_KEYS.length; i++) {
            out.append(SNAPSHOT_KEYS[i]).append('=')
                    .append(prefs.getInt(SNAPSHOT_KEYS[i], SNAPSHOT_DEFAULTS[i])).append(';');
        }
        for (String key : QUALITY_BOOL_KEYS) {
            out.append(key).append('=').append(prefs.getBoolean(key, true)).append(';');
        }
        ClipboardManager cm = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
        if (cm != null) cm.setPrimaryClip(ClipData.newPlainText("BassForge V5 Preset", out.toString()));
        Toast.makeText(this, "Preset copied to clipboard", Toast.LENGTH_SHORT).show();
    }

    private void importSettings() {
        ClipboardManager cm = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
        if (cm == null || !cm.hasPrimaryClip() || cm.getPrimaryClip() == null || cm.getPrimaryClip().getItemCount() == 0) {
            Toast.makeText(this, "Clipboard is empty", Toast.LENGTH_SHORT).show();
            return;
        }
        CharSequence cs = cm.getPrimaryClip().getItemAt(0).coerceToText(this);
        String raw = cs == null ? "" : cs.toString();
        if (!raw.startsWith("BF5;")) {
            Toast.makeText(this, "No BassForge V5 preset in clipboard", Toast.LENGTH_SHORT).show();
            return;
        }
        try {
            SharedPreferences.Editor e = prefs.edit();
            String[] parts = raw.substring(4).split(";");
            for (String part : parts) {
                int idx = part.indexOf('=');
                if (idx <= 0) continue;
                String key = part.substring(0, idx);
                String val = part.substring(idx + 1);
                if ("curve".equals(key)) e.putString("curve", val);
                else if (isQualityBoolKey(key)) e.putBoolean(key, Boolean.parseBoolean(val));
                else {
                    for (String known : SNAPSHOT_KEYS) {
                        if (known.equals(key)) {
                            e.putInt(key, Integer.parseInt(val));
                            break;
                        }
                    }
                }
            }
            e.apply();
            loadState();
            refreshControls();
            queueUpdate();
            Toast.makeText(this, "Preset imported", Toast.LENGTH_SHORT).show();
        } catch (Exception ex) {
            Toast.makeText(this, "Preset data is invalid", Toast.LENGTH_SHORT).show();
        }
    }

    private boolean isQualityBoolKey(String key) {
        for (String known : QUALITY_BOOL_KEYS) {
            if (known.equals(key)) return true;
        }
        return false;
    }

    private void showDiagnostics() {
        StringBuilder info = new StringBuilder();
        info.append("Device: ").append(Build.MANUFACTURER).append(" ").append(Build.MODEL).append("\n");
        info.append("Android: ").append(Build.VERSION.RELEASE).append(" (API ").append(Build.VERSION.SDK_INT).append(")\n\n");
        try {
            AudioEffect.Descriptor[] effects = AudioEffect.queryEffects();
            info.append("Audio effects found: ").append(effects == null ? 0 : effects.length).append("\n");
            boolean eq = false, bass = false, virt = false, loud = false;
            if (effects != null) {
                for (AudioEffect.Descriptor d : effects) {
                    String n = (d.name == null ? "" : d.name).toLowerCase();
                    if (n.contains("equalizer")) eq = true;
                    if (n.contains("bass")) bass = true;
                    if (n.contains("virtual")) virt = true;
                    if (n.contains("loud")) loud = true;
                }
            }
            info.append("Equalizer: ").append(eq ? "detected" : "not listed").append("\n");
            info.append("BassBoost: ").append(bass ? "detected" : "not listed").append("\n");
            info.append("Virtualizer: ").append(virt ? "detected" : "not listed").append("\n");
            info.append("Loudness: ").append(loud ? "detected" : "not listed").append("\n\n");
        } catch (Throwable t) {
            info.append("Effect query unavailable on this device.\n\n");
        }
        info.append("Current engine status:\n")
                .append(prefs.getString("engine_status", "Engine off"))
                .append("\n\nSome apps or OEMs can still block third-party system-wide audio effects.");
        new AlertDialog.Builder(this)
                .setTitle("BassForge Diagnostics")
                .setMessage(info.toString())
                .setPositiveButton("CLOSE", null)
                .show();
    }

    private void resetDefaults() {
        prefs.edit()
                .putString("curve", "7,7,6,4,2,0,0,0,1,1")
                .putInt("bass", 68).putInt("loudness", 16).putInt("sub", 55)
                .putInt("punch", 45).putInt("width", 20).putInt("clarity", 55)
                .putInt("treble", 40).putInt("sub_focus", 35).putInt("punch_focus", 50)
                .putInt("vocal", 55).putInt("quality", 1).putInt("intensity", 100)
                .putInt("warmth", 35).putInt("presence", 40).putInt("low_mid_cut", 35)
                .putInt("gain_ceiling", 5).putInt("sonic_strength", 78)
                .putBoolean("dynamic_bass", true).putBoolean("auto_gain", true)
                .putBoolean("sonic_core", true).putBoolean("curve_smoothing", true)
                .putBoolean("auto_clean", true).putBoolean("bass_definition", true)
                .putBoolean("clarity_restore", true).putBoolean("transient_focus", true)
                .putBoolean("stereo_guard", true).putBoolean("adaptive_headroom", true)
                .putBoolean("auto_profile", true).apply();
        loadState();
        refreshControls();
        queueUpdate();
        Toast.makeText(this, "Audio settings reset", Toast.LENGTH_SHORT).show();
    }

    private void addActionButton(LinearLayout row, String label, Runnable action) {
        TextView button = text(label, 11, TEXT, true);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(13), dp(10), dp(13), dp(10));
        button.setBackground(roundRect(CARD_2, dp(14), Color.rgb(65, 20, 29), dp(1)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, 0, dp(8), 0);
        row.addView(button, lp);
        button.setOnClickListener(v -> action.run());
    }

    private void setQuality(int quality) {
        prefs.edit().putInt("quality", quality).apply();
        queueUpdate();
        String[] names = {"SOFT", "CLEAN", "HARD", "BRUTAL"};
        Toast.makeText(this, "Bass character: " + names[Math.max(0, Math.min(3, quality))], Toast.LENGTH_SHORT).show();
    }

    private void applyProfile(String profile) {
        SharedPreferences.Editor e = prefs.edit();
        if ("headphones".equals(profile)) {
            e.putInt("width", 24).putInt("clarity", 82).putInt("treble", 48).putInt("vocal", 70)
                    .putInt("sub_focus", 32).putInt("punch_focus", 46).putBoolean("auto_gain", true);
        } else if ("speaker".equals(profile)) {
            e.putInt("width", 8).putInt("clarity", 72).putInt("treble", 44).putInt("vocal", 62)
                    .putInt("sub_focus", 62).putInt("punch_focus", 58).putBoolean("auto_gain", true);
        } else if ("gaming".equals(profile)) {
            e.putInt("bass", 58).putInt("sub", 42).putInt("punch", 62).putInt("clarity", 90)
                    .putInt("treble", 68).putInt("vocal", 80).putInt("width", 42).putBoolean("auto_gain", true);
        } else if ("night".equals(profile)) {
            e.putInt("bass", 56).putInt("sub", 48).putInt("punch", 38).putInt("loudness", 12)
                    .putInt("clarity", 76).putInt("treble", 45).putInt("width", 18).putBoolean("auto_gain", true);
        } else {
            e.putInt("bass", 84).putInt("sub", 82).putInt("punch", 68).putInt("clarity", 78)
                    .putInt("treble", 52).putInt("vocal", 68).putInt("width", 24).putBoolean("auto_gain", true);
        }
        e.apply();
        refreshControls();
        queueUpdate();
        Toast.makeText(this, profile.toUpperCase() + " profile applied", Toast.LENGTH_SHORT).show();
    }

    private void saveCustomPreset() {
        saveCurve();
        SharedPreferences.Editor e = prefs.edit();
        e.putString("custom_curve", prefs.getString("curve", "0,0,0,0,0,0,0,0,0,0"));
        String[] keys = {"bass","loudness","sub","punch","width","clarity","treble","sub_focus","punch_focus","vocal","quality"};
        int[] defs = {68,16,55,45,20,55,40,35,50,55,1};
        for (int i = 0; i < keys.length; i++) e.putInt("custom_" + keys[i], prefs.getInt(keys[i], defs[i]));
        e.putBoolean("custom_dynamic_bass", prefs.getBoolean("dynamic_bass", true));
        e.putBoolean("custom_auto_gain", prefs.getBoolean("auto_gain", true));
        e.putBoolean("custom_saved", true);
        e.apply();
        Toast.makeText(this, "Custom preset saved", Toast.LENGTH_SHORT).show();
    }

    private void loadCustomPreset() {
        if (!prefs.getBoolean("custom_saved", false)) {
            Toast.makeText(this, "No custom preset saved yet", Toast.LENGTH_SHORT).show();
            return;
        }
        SharedPreferences.Editor e = prefs.edit();
        e.putString("curve", prefs.getString("custom_curve", "0,0,0,0,0,0,0,0,0,0"));
        String[] keys = {"bass","loudness","sub","punch","width","clarity","treble","sub_focus","punch_focus","vocal","quality"};
        int[] defs = {68,16,55,45,20,55,40,35,50,55,1};
        for (int i = 0; i < keys.length; i++) e.putInt(keys[i], prefs.getInt("custom_" + keys[i], defs[i]));
        e.putBoolean("dynamic_bass", prefs.getBoolean("custom_dynamic_bass", true));
        e.putBoolean("auto_gain", prefs.getBoolean("custom_auto_gain", true));
        e.apply();
        loadState();
        refreshControls();
        queueUpdate();
        Toast.makeText(this, "Custom preset loaded", Toast.LENGTH_SHORT).show();
    }

    private void showChangelog() {
        String log =
                "V6 SONIC CORE\n" +
                "• New automatic SONIC CORE quality engine\n" +
                "• Enabled automatically after updating\n" +
                "• Quality Engine Strength control\n" +
                "• Curve Smoothing\n" +
                "• Auto Anti-Mud processing\n" +
                "• Automatic Bass Definition\n" +
                "• Automatic Clarity Restore\n" +
                "• Transient Focus\n" +
                "• Stereo Guard\n" +
                "• Adaptive Headroom\n" +
                "• Auto Device Profile now enabled by default\n" +
                "• Dynamic Bass + Auto Gain enabled by default\n" +
                "• AUTO QUALITY MAX one-tap mode\n" +
                "• QUALITY BALANCED one-tap mode\n" +
                "• More controlled width at extreme low-end settings\n" +
                "• Stronger anti-clipping behavior at extreme EQ levels\n" +
                "• Smoother tonal transitions between EQ bands\n" +
                "• Better detail retention with heavy bass\n\n" +
                "V5 OVERDRIVE\n" +
                "• Master Intensity 50–150%\n" +
                "• Warmth control\n" +
                "• Presence control\n" +
                "• Low-Mid Cut\n" +
                "• Adjustable digital Gain Ceiling\n" +
                "• 3 independent preset slots\n" +
                "• A/B comparison snapshots\n" +
                "• Preset export to clipboard\n" +
                "• Preset import from clipboard\n" +
                "• Device/audio-effect diagnostics\n" +
                "• Auto Device Profile\n" +
                "• Boot restart reminder for Android 15+\n" +
                "• Notification NEXT preset control\n" +
                "• 5-preset notification cycle\n" +
                "• Device-aware headphone/speaker tuning\n" +
                "• Extended snapshot system\n" +
                "• Reset to factory audio settings\n" +
                "• OVERDRIVE black/red interface\n" +
                "• V5 preset format BF5\n" +
                "• Expanded digital headroom controls\n\n" +
                "V4 REDLINE\n" +
                "• MAX CLEAN one-tap preset\n" +
                "• Sub Focus + Punch Focus\n" +
                "• Treble / Air + Vocal Protection\n" +
                "• Dynamic Bass Curve\n" +
                "• Auto Gain / Limiter V2\n" +
                "• Bass character: Soft / Clean / Hard / Brutal\n" +
                "• Headphones / Speaker / Gaming / Music / Night profiles\n" +
                "• Custom preset Save / Load\n" +
                "• Android Quick Tile support\n" +
                "• REDLINE black/red UI\n\n" +
                "V3.2\n• New neon BF launcher icon\n\n" +
                "V3.1\n• Bass-linked loudness\n\n" +
                "V3 Premium\n• Anti-Mud / Clean Bass + premium presets\n\n" +
                "V2\n• Sub, Punch, Width and Abyss\n\n" +
                "V1\n• First EQ / BassBoost / Loudness engine";
        new AlertDialog.Builder(this)
                .setTitle("BassForge EQ — Changelog")
                .setMessage(log)
                .setPositiveButton("CLOSE", null)
                .show();
    }

    private void sectionTitle(LinearLayout root, String title) {
        TextView t = text(title, 12, MUTED, true);
        t.setLetterSpacing(0.1f);
        root.addView(t, marginTop(20));
    }

    private SeekBar seek(int min, int max) {
        SeekBar b = new SeekBar(this);
        if (Build.VERSION.SDK_INT >= 26) b.setMin(min);
        b.setMax(max);
        if (Build.VERSION.SDK_INT >= 21) {
            b.setProgressTintList(ColorStateList.valueOf(ACCENT));
            b.setThumbTintList(ColorStateList.valueOf(ACCENT));
        }
        return b;
    }

    private SeekBar.OnSeekBarChangeListener simpleSeek(IntConsumer consumer) {
        return new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (!buildingUi) consumer.accept(progress);
            }
            @Override public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override public void onStopTrackingTouch(SeekBar seekBar) {}
        };
    }

    private interface IntConsumer {
        void accept(int value);
    }

    private LinearLayout card() {
        LinearLayout card = new LinearLayout(this);
        card.setBackground(roundRect(CARD, dp(18), Color.rgb(40, 40, 49), dp(1)));
        return card;
    }

    private LinearLayout rowBetween() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView spacer = new TextView(this);
        return row;
    }

    private TextView text(String value, int sp, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(sp);
        t.setTextColor(color);
        if (bold) t.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return t;
    }

    private GradientDrawable roundRect(int fill, int radius, int strokeColor, int strokeWidth) {
        GradientDrawable g = new GradientDrawable();
        g.setColor(fill);
        g.setCornerRadius(radius);
        if (strokeWidth > 0) g.setStroke(strokeWidth, strokeColor);
        return g;
    }

    private LinearLayout.LayoutParams marginTop(int top) {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = dp(top);
        return lp;
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private String formatDb(int db) {
        if (db > 0) return "+" + db + " dB";
        return db + " dB";
    }

    private int dp(float value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
