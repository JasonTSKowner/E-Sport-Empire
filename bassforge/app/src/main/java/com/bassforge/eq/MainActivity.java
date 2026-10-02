package com.bassforge.eq;

import android.Manifest;
import android.app.Activity;
import android.content.res.ColorStateList;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
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

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends Activity {
    private static final int BG = Color.rgb(7, 7, 9);
    private static final int CARD = Color.rgb(18, 18, 23);
    private static final int CARD_2 = Color.rgb(25, 25, 31);
    private static final int TEXT = Color.rgb(244, 244, 247);
    private static final int MUTED = Color.rgb(151, 151, 163);
    private static final int ACCENT = Color.rgb(255, 74, 35);
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
    private TextView bassValue;
    private TextView loudnessValue;
    private TextView subValue;
    private TextView punchValue;
    private TextView widthValue;
    private TextView clarityValue;
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

        TextView subtitle = text("PREMIUM BASS PROCESSING  •  V3", 12, ACCENT, true);
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

        addPreset(presetRow, "CLEAN", new int[]{0,0,0,0,0,0,0,0,0,0}, 0, 0, 0, 0, 0, 35);
        addPreset(presetRow, "PREMIUM", new int[]{7,7,6,4,2,0,0,0,1,1}, 72, 12, 62, 48, 16, 68);
        addPreset(presetRow, "DEEP CLEAN", new int[]{10,10,8,4,1,0,-1,0,1,1}, 82, 10, 88, 38, 12, 82);
        addPreset(presetRow, "CLUB", new int[]{9,9,8,6,3,0,0,1,2,2}, 88, 15, 72, 78, 24, 62);
        addPreset(presetRow, "CINEMA", new int[]{11,10,8,5,2,0,0,1,2,3}, 88, 12, 84, 58, 38, 58);
        addPreset(presetRow, "EARTHQUAKE", new int[]{12,12,10,7,3,0,-2,-1,1,2}, 100, 12, 94, 72, 22, 72);
        addPreset(presetRow, "ABYSS+", new int[]{12,12,11,7,2,-1,-2,-1,1,2}, 100, 8, 100, 84, 26, 82);

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
        safety.addView(text("PREMIUM GAIN CONTROL • ALWAYS ON", 13, GREEN, true));
        safety.addView(text(
                "V3.1 links bass strength to a controlled output boost, while strong EQ peaks are still compensated to reduce harsh clipping and pumping.",
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
