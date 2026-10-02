package com.bassforge.eq;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.audiofx.AudioEffect;
import android.os.Build;

public class AudioSessionReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (!context.getSharedPreferences(BassService.PREFS, Context.MODE_PRIVATE)
                .getBoolean("engine_enabled", false)) {
            return;
        }

        int sessionId = intent.getIntExtra(AudioEffect.EXTRA_AUDIO_SESSION, -1);
        if (sessionId < 0) return;

        Intent serviceIntent = new Intent(context, BassService.class);
        if (AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION.equals(intent.getAction())) {
            serviceIntent.setAction(BassService.ACTION_OPEN_SESSION);
        } else if (AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION.equals(intent.getAction())) {
            serviceIntent.setAction(BassService.ACTION_CLOSE_SESSION);
        } else {
            return;
        }
        serviceIntent.putExtra(BassService.EXTRA_SESSION_ID, sessionId);

        try {
            if (Build.VERSION.SDK_INT >= 26) {
                context.startForegroundService(serviceIntent);
            } else {
                context.startService(serviceIntent);
            }
        } catch (Exception ignored) {
        }
    }
}
