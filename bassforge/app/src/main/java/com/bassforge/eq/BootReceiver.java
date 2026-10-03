package com.bassforge.eq;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class BootReceiver extends BroadcastReceiver {
    private static final String CHANNEL = "bassforge_boot";
    private static final int ID = 4405;

    @Override
    public void onReceive(Context context, Intent intent) {
        if (!Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) return;

        boolean enabled = context.getSharedPreferences(BassService.PREFS, Context.MODE_PRIVATE)
                .getBoolean("auto_start", false);
        if (!enabled) return;

        context.getSharedPreferences(BassService.PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean("boot_restart_pending", true).apply();

        try {
            NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) return;

            if (Build.VERSION.SDK_INT >= 26) {
                NotificationChannel ch = new NotificationChannel(
                        CHANNEL, "BassForge Restart", NotificationManager.IMPORTANCE_DEFAULT);
                ch.setDescription("Restart reminder after phone reboot.");
                nm.createNotificationChannel(ch);
            }

            Intent open = new Intent(context, MainActivity.class);
            open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            PendingIntent pi = PendingIntent.getActivity(
                    context, 44, open,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

            Notification.Builder b = Build.VERSION.SDK_INT >= 26
                    ? new Notification.Builder(context, CHANNEL)
                    : new Notification.Builder(context);

            Notification n = b
                    .setSmallIcon(android.R.drawable.ic_media_play)
                    .setContentTitle("BassForge EQ V6")
                    .setContentText("Tap to restart the SONIC CORE audio engine")
                    .setContentIntent(pi)
                    .setAutoCancel(true)
                    .build();
            nm.notify(ID, n);
        } catch (Throwable ignored) {
        }
    }
}
