package com.bassforge.eq;

import android.content.Intent;
import android.os.Build;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

public class BassTileService extends TileService {
    @Override
    public void onStartListening() {
        super.onStartListening();
        updateTile();
    }

    @Override
    public void onClick() {
        super.onClick();
        boolean enabled = getSharedPreferences(BassService.PREFS, MODE_PRIVATE)
                .getBoolean("engine_enabled", false);

        Intent i = new Intent(this, BassService.class);
        i.setAction(enabled ? BassService.ACTION_STOP : BassService.ACTION_START);

        try {
            if (Build.VERSION.SDK_INT >= 26 && !enabled) {
                startForegroundService(i);
            } else {
                startService(i);
            }
        } catch (Exception ignored) {
        }

        getSharedPreferences(BassService.PREFS, MODE_PRIVATE)
                .edit()
                .putBoolean("engine_enabled", !enabled)
                .apply();
        updateTile();
    }

    private void updateTile() {
        Tile tile = getQsTile();
        if (tile == null) return;
        boolean enabled = getSharedPreferences(BassService.PREFS, MODE_PRIVATE)
                .getBoolean("engine_enabled", false);
        tile.setLabel("BassForge");
        tile.setState(enabled ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        tile.updateTile();
    }
}
