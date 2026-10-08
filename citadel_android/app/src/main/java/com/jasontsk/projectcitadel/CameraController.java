package com.jasontsk.projectcitadel;

/** The single source of truth for world-to-screen transforms. */
public final class CameraController {
    public float x, y, zoom = 1f;
    private int width, height;
    private boolean initialized;
    private float minZoom = .38f, maxZoom = 2.4f;

    public void resize(int width, int height) {
        float oldCenterX = this.width > 0 ? screenToWorldX(this.width * .5f) : 0;
        float oldCenterY = this.height > 0 ? screenToWorldY(this.height * .5f) : 640;
        this.width = width;
        this.height = height;
        minZoom = Math.max(.27f, Math.min(width / 2100f, height / 1350f));
        maxZoom = Math.max(1.9f, width / 370f);
        if (!initialized) { home(); initialized = true; }
        else {
            zoom = Math.max(minZoom, Math.min(maxZoom, zoom));
            x = width * .5f - oldCenterX * zoom;
            y = height * .5f - oldCenterY * zoom;
            clamp();
        }
    }

    public void home() {
        zoom = Math.max(minZoom, Math.min(maxZoom, width / 740f));
        x = width * .5f;
        y = height * .51f - 620 * zoom;
        clamp();
    }

    public void pan(float dx, float dy) { x += dx; y += dy; clamp(); }

    /** Keeps the same world point beneath the pinch midpoint. */
    public void zoomAt(float factor, float sx, float sy) {
        if (factor <= 0 || Float.isNaN(factor) || Float.isInfinite(factor)) return;
        float wx = screenToWorldX(sx), wy = screenToWorldY(sy);
        zoom = Math.max(minZoom, Math.min(maxZoom, zoom * factor));
        x = sx - wx * zoom;
        y = sy - wy * zoom;
        clamp();
    }

    public float screenToWorldX(float sx) { return (sx - x) / zoom; }
    public float screenToWorldY(float sy) { return (sy - y) / zoom; }

    private void clamp() {
        if (width <= 0 || height <= 0) return;
        // Clamp the viewport centre inside the playable diamond. Its outer forest
        // can remain visible, but the player can never pan into empty infinity.
        float cx = (width * .5f - x) / zoom;
        float cy = (height * .5f - y) / zoom;
        float gx = VillageGrid.gridX(cx, cy), gy = VillageGrid.gridY(cx, cy);
        gx = Math.max(4, Math.min(VillageGrid.SIZE - 4, gx));
        gy = Math.max(4, Math.min(VillageGrid.SIZE - 4, gy));
        x = width * .5f - VillageGrid.worldX(gx, gy) * zoom;
        y = height * .5f - VillageGrid.worldY(gx, gy) * zoom;
    }
}
