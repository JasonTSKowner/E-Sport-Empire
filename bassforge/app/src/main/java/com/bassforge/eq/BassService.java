package com.bassforge.eq;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.media.audiofx.AudioEffect;
import android.media.audiofx.BassBoost;
import android.media.audiofx.Equalizer;
import android.media.audiofx.LoudnessEnhancer;
import android.media.audiofx.Virtualizer;
import android.os.Build;
import android.os.IBinder;

import java.util.HashMap;
import java.util.Map;

public class BassService extends Service {
    public static final String PREFS = "bassforge";
    public static final String ACTION_START = "com.bassforge.eq.START";
    public static final String ACTION_UPDATE = "com.bassforge.eq.UPDATE";
    public static final String ACTION_STOP = "com.bassforge.eq.STOP";
    public static final String ACTION_OPEN_SESSION = "com.bassforge.eq.OPEN_SESSION";
    public static final String ACTION_CLOSE_SESSION = "com.bassforge.eq.CLOSE_SESSION";
    public static final String ACTION_MAX_CLEAN = "com.bassforge.eq.MAX_CLEAN";
    public static final String EXTRA_SESSION_ID = "session_id";

    private static final int NOTIFICATION_ID = 4402;
    private static final String CHANNEL_ID = "bassforge_engine";
    private static final int[] TARGET_FREQS = {
            31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
    };

    private final Map<Integer, FxSet> sessions = new HashMap<>();
    private SharedPreferences prefs;

    @Override
    public void onCreate() {
        super.onCreate();
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : ACTION_START;

        if (ACTION_STOP.equals(action)) {
            prefs.edit()
                    .putBoolean("engine_enabled", false)
                    .putString("engine_status", "Engine off")
                    .apply();
            releaseAll();
            stopForeground(STOP_FOREGROUND_REMOVE);
            stopSelf();
            return START_NOT_STICKY;
        }

        ensureForeground();
        prefs.edit().putBoolean("engine_enabled", true).apply();

        if (ACTION_MAX_CLEAN.equals(action)) {
            prefs.edit()
                    .putString("curve", "12,12,10,6,1,0,0,1,2,2")
                    .putInt("bass", 100)
                    .putInt("loudness", 34)
                    .putInt("sub", 100)
                    .putInt("punch", 88)
                    .putInt("width", 22)
                    .putInt("clarity", 88)
                    .putInt("treble", 54)
                    .putInt("sub_focus", 34)
                    .putInt("punch_focus", 48)
                    .putInt("vocal", 78)
                    .putBoolean("dynamic_bass", true)
                    .putBoolean("auto_gain", true)
                    .putInt("quality", 2)
                    .apply();
        }

        if (ACTION_CLOSE_SESSION.equals(action)) {
            int id = intent.getIntExtra(EXTRA_SESSION_ID, -1);
            releaseSession(id);
            refreshStatus();
            return START_STICKY;
        }

        if (ACTION_OPEN_SESSION.equals(action)) {
            int id = intent.getIntExtra(EXTRA_SESSION_ID, -1);
            if (id >= 0) ensureSession(id);
        } else {
            // Session 0 is the Android output mix on devices that expose global effects.
            ensureSession(0);
        }

        applyAll();
        refreshStatus();
        return START_STICKY;
    }

    private void ensureForeground() {
        Intent open = new Intent(this, MainActivity.class);
        PendingIntent pi = PendingIntent.getActivity(
                this, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(this, CHANNEL_ID)
                : new Notification.Builder(this);

        Intent maxCleanIntent = new Intent(this, BassService.class);
        maxCleanIntent.setAction(ACTION_MAX_CLEAN);
        PendingIntent maxCleanPi = PendingIntent.getService(
                this, 1, maxCleanIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Intent stopIntent = new Intent(this, BassService.class);
        stopIntent.setAction(ACTION_STOP);
        PendingIntent stopPi = PendingIntent.getService(
                this, 2, stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification notification = builder
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentTitle("BassForge EQ V4 REDLINE")
                .setContentText("REDLINE engine active • tap for controls")
                .setContentIntent(pi)
                .addAction(new Notification.Action.Builder(
                        null, "MAX CLEAN", maxCleanPi).build())
                .addAction(new Notification.Action.Builder(
                        null, "OFF", stopPi).build())
                .setOngoing(true)
                .build();

        startForeground(NOTIFICATION_ID, notification);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "BassForge Audio Engine",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("Keeps BassForge audio processing active.");
            NotificationManager nm = getSystemService(NotificationManager.class);
            if (nm != null) nm.createNotificationChannel(channel);
        }
    }

    private void ensureSession(int sessionId) {
        if (sessions.containsKey(sessionId)) return;
        FxSet fx = new FxSet(sessionId);
        if (fx.hasAnyEffect()) sessions.put(sessionId, fx);
    }

    private void applyAll() {
        int[] curve = readCurve();
        int bass = prefs.getInt("bass", 68);
        int loudness = prefs.getInt("loudness", 16);
        int sub = prefs.getInt("sub", 55);
        int punch = prefs.getInt("punch", 45);
        int width = prefs.getInt("width", 20);
        int clarity = prefs.getInt("clarity", 55);
        int treble = prefs.getInt("treble", 40);
        int subFocus = prefs.getInt("sub_focus", 35);
        int punchFocus = prefs.getInt("punch_focus", 50);
        int vocal = prefs.getInt("vocal", 55);
        boolean dynamicBass = prefs.getBoolean("dynamic_bass", true);
        boolean autoGain = prefs.getBoolean("auto_gain", true);
        int quality = prefs.getInt("quality", 1);

        for (FxSet fx : sessions.values()) {
            fx.apply(curve, bass, loudness, sub, punch, width, clarity,
                    treble, subFocus, punchFocus, vocal, dynamicBass, autoGain, quality);
        }
    }

    private int[] readCurve() {
        int[] out = new int[10];
        String saved = prefs.getString("curve", "7,7,6,4,2,0,0,0,1,1");
        String[] parts = saved.split(",");
        for (int i = 0; i < out.length; i++) {
            try {
                out[i] = i < parts.length ? Integer.parseInt(parts[i]) : 0;
            } catch (NumberFormatException e) {
                out[i] = 0;
            }
        }
        return out;
    }

    private void refreshStatus() {
        String status;
        if (sessions.isEmpty()) {
            status = "Compatibility mode • waiting for player audio";
        } else if (sessions.size() == 1 && sessions.containsKey(0)) {
            status = "Engine active • global output mix";
        } else {
            int playerSessions = sessions.containsKey(0) ? sessions.size() - 1 : sessions.size();
            status = "Engine active • " + Math.max(1, playerSessions) + " player session";
            if (playerSessions != 1) status += "s";
        }
        prefs.edit().putString("engine_status", status).apply();
    }

    private void releaseSession(int id) {
        FxSet fx = sessions.remove(id);
        if (fx != null) fx.release();
    }

    private void releaseAll() {
        for (FxSet fx : sessions.values()) fx.release();
        sessions.clear();
    }

    @Override
    public void onDestroy() {
        releaseAll();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    private static float interpolatedDb(int hz, int[] curve) {
        if (hz <= TARGET_FREQS[0]) return curve[0];
        if (hz >= TARGET_FREQS[TARGET_FREQS.length - 1]) return curve[curve.length - 1];

        double logHz = Math.log(hz);
        for (int i = 0; i < TARGET_FREQS.length - 1; i++) {
            if (hz >= TARGET_FREQS[i] && hz <= TARGET_FREQS[i + 1]) {
                double a = Math.log(TARGET_FREQS[i]);
                double b = Math.log(TARGET_FREQS[i + 1]);
                double t = (logHz - a) / (b - a);
                return (float) (curve[i] + (curve[i + 1] - curve[i]) * t);
            }
        }
        return 0f;
    }

    private static float subExtraDb(int hz, int sub, int focus, boolean dynamicBass, int quality) {
        float amount = sub / 100f;
        int center = 32 + Math.round((focus / 100f) * 48f);
        float distance = Math.abs((float)Math.log(Math.max(20, hz) / (double)center));
        float shape = Math.max(0f, 1f - distance / 1.25f);
        float q = quality == 0 ? 0.86f : quality == 2 ? 1.10f : quality >= 3 ? 1.18f : 1f;
        float dyn = dynamicBass ? (0.88f + 0.12f * amount) : 1f;
        return 6.0f * amount * shape * q * dyn;
    }

    private static float punchExtraDb(int hz, int punch, int focus, int quality) {
        float amount = punch / 100f;
        int center = 90 + Math.round((focus / 100f) * 150f);
        float distance = Math.abs((float)Math.log(Math.max(50, hz) / (double)center));
        float shape = Math.max(0f, 1f - distance / 0.95f);
        float q = quality == 0 ? 0.85f : quality == 2 ? 1.08f : quality >= 3 ? 1.15f : 1f;
        return 3.8f * amount * shape * q;
    }

    private static float trebleAirDb(int hz, int treble) {
        float amount = treble / 100f;
        if (hz >= 8000) return 2.0f * amount;
        if (hz >= 4000) return 1.4f * amount;
        if (hz >= 2000) return 0.7f * amount;
        return 0f;
    }

    private static float vocalProtectDb(int hz, int vocal) {
        float amount = vocal / 100f;
        if (hz >= 300 && hz <= 700) return -0.8f * amount;
        if (hz > 700 && hz <= 2500) return 1.1f * amount;
        if (hz > 2500 && hz <= 4200) return 0.7f * amount;
        return 0f;
    }

    // Premium contour: reduce low-mid mud while restoring a little definition.
    // This keeps strong bass from masking vocals and percussion.
    private static float clarityContourDb(int hz, int clarity) {
        float amount = clarity / 100f;
        if (hz >= 180 && hz <= 320) return -2.2f * amount;
        if (hz > 320 && hz <= 520) return -1.4f * amount;
        if (hz >= 1800 && hz <= 4200) return 1.2f * amount;
        if (hz > 4200 && hz <= 9000) return 0.8f * amount;
        return 0f;
    }

    private static class FxSet {
        Equalizer equalizer;
        BassBoost bassBoost;
        LoudnessEnhancer loudnessEnhancer;
        Virtualizer virtualizer;

        FxSet(int sessionId) {
            try {
                equalizer = new Equalizer(0, sessionId);
                equalizer.setEnabled(true);
            } catch (Throwable ignored) {
                equalizer = null;
            }

            try {
                bassBoost = new BassBoost(0, sessionId);
                bassBoost.setEnabled(true);
            } catch (Throwable ignored) {
                bassBoost = null;
            }

            try {
                loudnessEnhancer = new LoudnessEnhancer(sessionId);
                loudnessEnhancer.setEnabled(true);
            } catch (Throwable ignored) {
                loudnessEnhancer = null;
            }

            try {
                virtualizer = new Virtualizer(0, sessionId);
                virtualizer.setEnabled(true);
            } catch (Throwable ignored) {
                virtualizer = null;
            }
        }

        boolean hasAnyEffect() {
            return equalizer != null
                    || bassBoost != null
                    || loudnessEnhancer != null
                    || virtualizer != null;
        }

        void apply(int[] curve, int bass, int loudness, int sub, int punch, int width, int clarity,
                   int treble, int subFocus, int punchFocus, int vocal,
                   boolean dynamicBass, boolean autoGain, int quality) {
            float rawMax = 0f;
            for (int v : curve) rawMax = Math.max(rawMax, v);
            float effectiveMax = rawMax
                    + 5.5f * (sub / 100f)
                    + 3.4f * (punch / 100f);

            // Smart headroom: stronger low-end shaping automatically gives the mix
            // more digital space. It is intentionally conservative at extreme settings.
            float headroomDb = Math.max(0f, effectiveMax - 5f) * 0.46f
                    + Math.max(0, bass - 65) * 0.022f
                    + Math.max(0, sub - 75) * 0.015f
                    + Math.max(0, punch - 80) * 0.010f;

            if (equalizer != null) {
                try {
                    short[] range = equalizer.getBandLevelRange();
                    short bands = equalizer.getNumberOfBands();

                    for (short b = 0; b < bands; b++) {
                        int hz = equalizer.getCenterFreq(b) / 1000;
                        float wantedDb = interpolatedDb(hz, curve)
                                + subExtraDb(hz, sub, subFocus, dynamicBass, quality)
                                + punchExtraDb(hz, punch, punchFocus, quality)
                                + clarityContourDb(hz, clarity)
                                + trebleAirDb(hz, treble)
                                + vocalProtectDb(hz, vocal)
                                - headroomDb;

                        int levelMb = Math.round(wantedDb * 100f);
                        levelMb = clamp(levelMb, range[0], range[1]);
                        equalizer.setBandLevel(b, (short) levelMb);
                    }
                } catch (Throwable ignored) {
                }
            }

            if (bassBoost != null) {
                try {
                    int combined = Math.round(bass * 7.0f + sub * 3.0f);
                    bassBoost.setStrength((short) clamp(combined, 0, 1000));
                } catch (Throwable ignored) {
                }
            }

            if (virtualizer != null) {
                try {
                    virtualizer.setStrength((short) clamp(width * 10, 0, 1000));
                } catch (Throwable ignored) {
                }
            }

            if (loudnessEnhancer != null) {
                try {
                    // V3.1: bass and output level rise together, but in a controlled way.
                    // The automatic bass-linked gain is intentionally modest so a higher
                    // bass setting feels bigger and louder without turning into a huge jump.
                    int userGainMb = Math.round(clamp(loudness, 0, 100) * 5.0f);
                    int bassLinkedMb = Math.round(clamp(bass, 0, 100) * 1.2f
                            + clamp(sub, 0, 100) * 0.7f
                            + clamp(punch, 0, 100) * 0.25f);

                    // Keep extra gain under control when the EQ curve itself is already extreme.
                    int overloadPenaltyMb = autoGain
                            ? Math.round(Math.max(0f, effectiveMax - 9f) * 44f)
                            : 0;
                    int qualityPenalty = quality >= 3 ? 45 : quality == 2 ? 20 : 0;
                    int targetMb = userGainMb + bassLinkedMb - overloadPenaltyMb - qualityPenalty;

                    // REDLINE limiter ceiling. This protects digital headroom; it is not
                    // a hearing-safety volume limiter.
                    targetMb = clamp(targetMb, 0, 620);
                    loudnessEnhancer.setTargetGain(targetMb);
                } catch (Throwable ignored) {
                }
            }
        }

        void release() {
            try {
                if (equalizer != null) equalizer.release();
            } catch (Throwable ignored) {}
            try {
                if (bassBoost != null) bassBoost.release();
            } catch (Throwable ignored) {}
            try {
                if (loudnessEnhancer != null) loudnessEnhancer.release();
            } catch (Throwable ignored) {}
            try {
                if (virtualizer != null) virtualizer.release();
            } catch (Throwable ignored) {}
        }
    }
}
