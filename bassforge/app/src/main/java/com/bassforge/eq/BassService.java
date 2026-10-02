package com.bassforge.eq;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.media.audiofx.BassBoost;
import android.media.audiofx.Equalizer;
import android.media.audiofx.LoudnessEnhancer;
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
    public static final String EXTRA_SESSION_ID = "session_id";

    private static final int NOTIFICATION_ID = 4401;
    private static final String CHANNEL_ID = "bassforge_engine";
    private static final int[] TARGET_FREQS = {31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000};

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

        if (ACTION_CLOSE_SESSION.equals(action)) {
            int id = intent.getIntExtra(EXTRA_SESSION_ID, -1);
            releaseSession(id);
            refreshStatus();
            return START_STICKY;
        }

        prefs.edit().putBoolean("engine_enabled", true).apply();

        if (ACTION_OPEN_SESSION.equals(action)) {
            int id = intent.getIntExtra(EXTRA_SESSION_ID, -1);
            if (id >= 0) ensureSession(id);
        } else {
            ensureSession(0);
        }

        applyAll();
        refreshStatus();
        return START_STICKY;
    }

    private void ensureForeground() {
        Intent open = new Intent(this, MainActivity.class);
        PendingIntent pi = PendingIntent.getActivity(
                this, 0, open, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(this, CHANNEL_ID)
                : new Notification.Builder(this);

        Notification notification = builder
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentTitle("BassForge EQ")
                .setContentText("Audio engine active")
                .setContentIntent(pi)
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
        if (fx.hasAnyEffect()) {
            sessions.put(sessionId, fx);
        }
    }

    private void applyAll() {
        int[] curve = readCurve();
        int bass = prefs.getInt("bass", 65);
        int loudness = prefs.getInt("loudness", 20);

        for (FxSet fx : sessions.values()) {
            fx.apply(curve, bass, loudness);
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
            status = "Compatibility mode • waiting for an audio session";
        } else if (sessions.size() == 1 && sessions.containsKey(0)) {
            status = "Engine active • global mix";
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

    private static class FxSet {
        final int sessionId;
        Equalizer equalizer;
        BassBoost bassBoost;
        LoudnessEnhancer loudnessEnhancer;

        FxSet(int sessionId) {
            this.sessionId = sessionId;

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
        }

        boolean hasAnyEffect() {
            return equalizer != null || bassBoost != null || loudnessEnhancer != null;
        }

        void apply(int[] curve, int bass, int loudness) {
            float maxBoost = 0f;
            for (int v : curve) maxBoost = Math.max(maxBoost, v);

            // Smart headroom: strong low-end boost gets compensated before it reaches
            // the hardware range. This is not a medical volume limiter; it simply
            // reduces the chance of obvious digital clipping.
            float headroomDb = Math.max(0f, maxBoost - 6f) * 0.38f
                    + Math.max(0, bass - 70) * 0.02f;

            if (equalizer != null) {
                try {
                    short[] range = equalizer.getBandLevelRange();
                    short bands = equalizer.getNumberOfBands();
                    for (short b = 0; b < bands; b++) {
                        int hz = equalizer.getCenterFreq(b) / 1000;
                        float wantedDb = interpolatedDb(hz, curve) - headroomDb;
                        int levelMb = Math.round(wantedDb * 100f);
                        levelMb = clamp(levelMb, range[0], range[1]);
                        equalizer.setBandLevel(b, (short) levelMb);
                    }
                } catch (Throwable ignored) {
                }
            }

            if (bassBoost != null) {
                try {
                    short strength = (short) clamp(bass * 10, 0, 1000);
                    bassBoost.setStrength(strength);
                } catch (Throwable ignored) {
                }
            }

            if (loudnessEnhancer != null) {
                try {
                    int requestedMb = Math.round(clamp(loudness, 0, 100) * 6f);
                    int headroomPenaltyMb = Math.round(Math.max(0f, maxBoost - 8f) * 60f);
                    int targetMb = Math.max(0, requestedMb - headroomPenaltyMb);
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
        }
    }
}
