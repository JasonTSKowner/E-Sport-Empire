package com.jasontsk.projectcitadel;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.WindowManager;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Android lifecycle only; simulation and presentation own their separate state. */
public class MainActivity extends Activity {
    final Handler handler = new Handler(Looper.getMainLooper());
    final ExecutorService loader = Executors.newSingleThreadExecutor();
    VillageView villageView;
    SaveManager saves;
    GameAudio audio;
    private boolean resumed, destroyed, startupPlayed;
    private long savedAt;
    private final Runnable tick = new Runnable() {
        @Override public void run() {
            if (!resumed || destroyed) return;
            if (villageView != null) {
                long now = System.currentTimeMillis();
                int oldLevel = villageView.state.playerLevel;
                int oldHall = villageView.state.townHallLevel();
                int completed = villageView.manager.advance(now);
                if (completed > 0) {
                    audio.play(villageView.state.townHallLevel() > oldHall ? "townhall" : "complete");
                    villageView.notifyUser(completed == 1 ? "Your builders have finished!" : completed + " projects completed!");
                    persist();
                }
                if (oldLevel < villageView.state.playerLevel) audio.play("levelup");
                if (now - savedAt >= 15000) persist();
                villageView.invalidate();
            }
            handler.postDelayed(this, 1000);
        }
    };
    @Override public void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN);
        saves = new SaveManager(this);
        LoadingController loading = new LoadingController(this);
        setContentView(loading);
        loader.execute(() -> {
            GameState loaded = saves.load(System.currentTimeMillis());
            handler.post(() -> {
                if (destroyed) return;
                audio = new GameAudio(this, loaded);
                if (resumed) { audio.play("startup"); startupPlayed=true; } else audio.pause();
                loading.ready(() -> {
                    if (destroyed) return;
                    villageView = new VillageView(this, loaded);
                    int completed = villageView.manager.advance(System.currentTimeMillis());
                    setContentView(villageView);
                    villageView.setAlpha(0f);
                    villageView.animate().alpha(1f).setDuration(400).start();
                    if (resumed) audio.startAmbience();
                    if (saves.message != null && !saves.message.isEmpty()) villageView.notifyUser(saves.message);
                    else if (completed > 0) villageView.notifyUser("Welcome back. " + completed + " projects completed.");
                    else villageView.notifyUser("Welcome to Crownforge. Drag to explore, pinch to zoom.");
                    persist();
                });
            });
        });
    }
    void persist() {
        if (villageView == null) return;
        if (!saves.save(villageView.state)) villageView.notifyUser("Could not save. Your previous save is protected.");
        savedAt = System.currentTimeMillis();
    }
    @Override protected void onResume() {
        super.onResume(); resumed = true;
        if (audio != null) { audio.resume(); if (!startupPlayed) { audio.play("startup"); startupPlayed=true; } if (villageView != null) audio.startAmbience(); }
        handler.removeCallbacks(tick); handler.post(tick);
    }
    @Override protected void onPause() {
        resumed = false; handler.removeCallbacks(tick);
        if (villageView != null) villageView.manager.advance(System.currentTimeMillis());
        persist(); if (audio != null) audio.pause(); super.onPause();
    }
    @Override protected void onDestroy() {
        destroyed = true; handler.removeCallbacksAndMessages(null); loader.shutdown();
        if (audio != null) audio.release(); super.onDestroy();
    }
    @Override public void onBackPressed() {
        if (villageView != null && villageView.dismiss()) return;
        super.onBackPressed();
    }
}
