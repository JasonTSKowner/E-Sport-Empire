package com.jasontsk.projectcitadel;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.media.SoundPool;
import android.os.Build;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** All audio is original mathematical synthesis; no bundled or sampled third-party recordings. */
public final class GameAudio {
    private static final int RATE = 22050;
    private static final String[] EVENTS = {"startup", "button", "select", "place", "upgrade", "complete", "error", "collect", "levelup", "townhall"};
    private final GameState state;
    private final Context context;
    private final SoundPool effects;
    private final android.media.AudioManager systemAudio;
    private final ExecutorService synthesis = Executors.newSingleThreadExecutor(r -> new Thread(r, "Crownforge-audio"));
    private final Map<String, Integer> sounds = new HashMap<>();
    private final Set<Integer> ready = new HashSet<>();
    private final Set<String> pending = new HashSet<>();
    private AudioTrack ambience;
    private AudioTrack music;
    private boolean ambienceRequested;
    private boolean paused;
    private boolean released;
    private boolean focused;
    private AudioFocusRequest focusRequest;
    private final android.media.AudioManager.OnAudioFocusChangeListener focusListener = this::onAudioFocusChanged;

    private void onAudioFocusChanged(int change) {
        synchronized (GameAudio.this) {
            if (released) return;
            if (change == android.media.AudioManager.AUDIOFOCUS_GAIN) {
                focused = true;
                applySettings();
                beginLoops();
            } else {
                focused = false;
                effects.autoPause();
                pauseTrack(ambience);
                pauseTrack(music);
            }
        }
    }

    public GameAudio(Context context, GameState state) {
        this.context = context.getApplicationContext();
        this.state = state;
        systemAudio = (android.media.AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        AudioAttributes attributes = new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build();
        effects = new SoundPool.Builder().setMaxStreams(6).setAudioAttributes(attributes).build();
        effects.setOnLoadCompleteListener((pool, id, status) -> {
            synchronized (GameAudio.this) {
                if (released || status != 0) return;
                ready.add(id);
                for (String event : EVENTS) {
                    Integer sample = sounds.get(event);
                    if (sample != null && sample == id && pending.remove(event)) play(event);
                }
            }
        });
        synthesis.execute(this::prepare);
    }

    public synchronized void play(String event) {
        if (released || paused || state.muted) return;
        if (!requestFocus()) return;
        Integer sample = sounds.get(event);
        if (sample == null || !ready.contains(sample)) {
            // Keep the startup identity if the loading screen arrives before synthesis completes.
            if ("startup".equals(event)) pending.add(event);
            return;
        }
        float volume = gain(state.masterVolume) * gain(state.sfxVolume);
        effects.play(sample, volume, volume, "startup".equals(event) ? 2 : 1, 0, 1f);
    }

    public synchronized void startAmbience() {
        ambienceRequested = true;
        applySettings();
        beginLoops();
    }

    public synchronized void pause() {
        paused = true;
        pending.clear();
        effects.autoPause();
        pauseTrack(ambience);
        pauseTrack(music);
        abandonFocus();
    }

    public synchronized void resume() {
        if (released) return;
        paused = false;
        applySettings();
        beginLoops();
    }

    public synchronized void applySettings() {
        if (released) return;
        float master = state.muted ? 0 : gain(state.masterVolume);
        if (ambience != null) ambience.setVolume(master * gain(state.sfxVolume) * 0.4f);
        if (music != null) music.setVolume(master * gain(state.musicVolume) * 0.55f);
        if (master == 0) {
            effects.autoPause();
            pauseTrack(ambience);
            pauseTrack(music);
            abandonFocus();
        } else beginLoops();
    }

    public synchronized void release() {
        if (released) return;
        released = true;
        synthesis.shutdownNow();
        pending.clear();
        effects.release();
        releaseTrack(ambience);
        releaseTrack(music);
        ambience = music = null;
        abandonFocus();
    }

    private void prepare() {
        File directory = new File(context.getCacheDir(), "crownforge-synth-v2");
        if (!directory.exists() && !directory.mkdirs()) return;
        for (int event = 0; event < EVENTS.length; event++) {
            synchronized (this) { if (released) return; }
            try {
                File clip = new File(directory, EVENTS[event] + ".wav");
                if (!clip.exists()) writeWave(clip, synthEffect(event));
                synchronized (this) {
                    if (released) return;
                    int id = effects.load(clip.getAbsolutePath(), 1);
                    if (id != 0) sounds.put(EVENTS[event], id);
                }
            } catch (Exception ignored) { /* A missing audio device must never prevent gameplay. */ }
        }
        AudioTrack preparedAmbience = null;
        AudioTrack preparedMusic = null;
        try {
            preparedAmbience = makeLoop(synthAmbience());
            preparedMusic = makeLoop(synthMusic());
            synchronized (this) {
                if (released) {
                    releaseTrack(preparedAmbience);
                    releaseTrack(preparedMusic);
                    return;
                }
                ambience = preparedAmbience;
                music = preparedMusic;
                applySettings();
                beginLoops();
            }
        } catch (Exception ignored) {
            releaseTrack(preparedAmbience);
            releaseTrack(preparedMusic);
        }
    }

    private void beginLoops() {
        if (released || paused || !ambienceRequested || state.muted || state.masterVolume <= 0 || !requestFocus()) return;
        playTrack(ambience);
        playTrack(music);
    }

    private boolean requestFocus() {
        if (focused) return true;
        if (systemAudio == null || state.muted || paused || released) return false;
        int result;
        if (Build.VERSION.SDK_INT >= 26) {
            if (focusRequest == null) focusRequest = new AudioFocusRequest.Builder(android.media.AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                    .setOnAudioFocusChangeListener(focusListener).build();
            result = systemAudio.requestAudioFocus(focusRequest);
        } else result = systemAudio.requestAudioFocus(focusListener, android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.AUDIOFOCUS_GAIN);
        focused = result == android.media.AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
        return focused;
    }

    private void abandonFocus() {
        if (systemAudio == null || !focused) return;
        if (Build.VERSION.SDK_INT >= 26 && focusRequest != null) systemAudio.abandonAudioFocusRequest(focusRequest);
        else systemAudio.abandonAudioFocus(focusListener);
        focused = false;
    }

    private static AudioTrack makeLoop(short[] pcm) {
        AudioTrack track = new AudioTrack.Builder()
                .setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                .setAudioFormat(new AudioFormat.Builder().setSampleRate(RATE).setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                .setBufferSizeInBytes(pcm.length * 2).setTransferMode(AudioTrack.MODE_STATIC).build();
        if (track.getState() == AudioTrack.STATE_UNINITIALIZED) { track.release(); throw new IllegalStateException("Audio unavailable"); }
        track.write(pcm, 0, pcm.length);
        track.setLoopPoints(0, pcm.length, -1);
        track.setVolume(0);
        return track;
    }

    private static void playTrack(AudioTrack track) {
        try { if (track != null && track.getPlayState() != AudioTrack.PLAYSTATE_PLAYING) track.play(); } catch (IllegalStateException ignored) { }
    }
    private static void pauseTrack(AudioTrack track) {
        try { if (track != null && track.getPlayState() == AudioTrack.PLAYSTATE_PLAYING) track.pause(); } catch (IllegalStateException ignored) { }
    }
    private static void releaseTrack(AudioTrack track) { if (track != null) track.release(); }
    private static float gain(float value) { return Float.isNaN(value) ? 0 : Math.max(0, Math.min(1, value)); }

    private static short[] synthEffect(int kind) {
        double duration = kind == 0 ? 1.75 : kind >= 8 ? 0.95 : kind == 5 ? 0.65 : 0.22;
        short[] pcm = new short[(int) (RATE * duration)];
        long noiseState = 71119 + kind;
        double[] notes = {196, 262, 330, 392};
        for (int i = 0; i < pcm.length; i++) {
            double t = i / (double) RATE;
            noiseState = noiseState * 1664525 + 1013904223;
            double noise = ((noiseState >>> 16) & 65535) / 32768.0 - 1;
            double sample;
            if (kind == 0) {
                // Deep stone impact, inharmonic iron resonance, then a rising magical crest.
                sample = 0.40 * Math.sin(2 * Math.PI * (66 * t - 11 * t * t)) * Math.exp(-5 * t);
                sample += 0.18 * noise * Math.exp(-34 * t);
                sample += 0.17 * (Math.sin(2 * Math.PI * 293.7 * t) + 0.45 * Math.sin(2 * Math.PI * 779 * t)) * Math.exp(-3.7 * t);
                for (int n = 0; n < notes.length; n++) {
                    double u = t - 0.26 - n * 0.14;
                    if (u > 0) sample += 0.11 * Math.sin(2 * Math.PI * notes[n] * 2 * u) * Math.min(1, u * 45) * Math.exp(-4 * u);
                }
            } else if (kind == 6) {
                sample = 0.26 * Math.sin(2 * Math.PI * (180 * t - 100 * t * t)) * Math.exp(-15 * t);
            } else if (kind == 3 || kind == 4) {
                sample = (0.28 * Math.sin(2 * Math.PI * 130 * t) + 0.10 * noise) * Math.exp(-22 * t);
                sample += 0.18 * Math.sin(2 * Math.PI * (kind == 3 ? 440 : 554) * t) * Math.exp(-11 * t);
            } else if (kind == 5 || kind >= 8) {
                sample = 0;
                double base = kind == 9 ? 0.75 : 1;
                for (int n = 0; n < notes.length; n++) {
                    double u = t - n * 0.105;
                    if (u >= 0) sample += 0.25 * Math.sin(2 * Math.PI * notes[n] * 2 * base * u) * Math.min(1, u * 100) * Math.exp(-7 * u);
                }
            } else {
                double pitch = kind == 1 ? 700 : kind == 2 ? 420 : 1046;
                sample = 0.26 * Math.sin(2 * Math.PI * pitch * t) * Math.exp(-24 * t);
                sample += 0.06 * Math.sin(2 * Math.PI * pitch * 1.5 * t) * Math.exp(-17 * t);
            }
            sample *= Math.min(1, t * 400) * Math.min(1, (duration - t) * 40);
            pcm[i] = pcm(sample);
        }
        return pcm;
    }

    private static short[] synthAmbience() {
        double duration = 12;
        short[] pcm = new short[(int) (RATE * duration)];
        long noiseState = 271828;
        double breeze = 0;
        for (int i = 0; i < pcm.length; i++) {
            double t = i / (double) RATE;
            noiseState = noiseState * 1664525 + 1013904223;
            breeze = breeze * 0.985 + ((((noiseState >>> 16) & 65535) / 32768.0) - 1) * 0.015;
            double sample = breeze * (0.25 + 0.08 * Math.sin(2 * Math.PI * t / duration));
            for (int bird = 0; bird < 3; bird++) {
                double u = t - 1.7 - bird * 3.5;
                if (u > 0 && u < 0.48) sample += 0.025 * Math.sin(2 * Math.PI * (1600 * u + 440 * u * u)) * Math.pow(Math.sin(Math.PI * u / 0.48), 2);
            }
            sample *= Math.min(1, t) * Math.min(1, duration - t);
            pcm[i] = pcm(sample);
        }
        return pcm;
    }

    private static short[] synthMusic() {
        double duration = 16;
        short[] pcm = new short[(int) (RATE * duration)];
        double[] phrase = {146.83, 220, 293.66, 261.63, 196, 220, 164.81, 146.83};
        for (int i = 0; i < pcm.length; i++) {
            double t = i / (double) RATE;
            int note = Math.min(phrase.length - 1, (int) (t / 2));
            double u = t - note * 2;
            double envelope = (1 - Math.exp(-u * 8)) * Math.exp(-u * 1.8);
            double sample = 0.085 * (Math.sin(2 * Math.PI * phrase[note] * u) + 0.23 * Math.sin(2 * Math.PI * phrase[note] * 2 * u)) * envelope;
            sample += 0.018 * Math.sin(2 * Math.PI * 73.416 * t) * Math.pow(Math.sin(Math.PI * t / duration), 2);
            sample *= Math.min(1, t * 3) * Math.min(1, (duration - t) * 2);
            pcm[i] = pcm(sample);
        }
        return pcm;
    }

    private static short pcm(double sample) { return (short) Math.round(Math.max(-0.92, Math.min(0.92, sample)) * 32767); }
    private static void writeWave(File file, short[] pcm) throws IOException {
        try (FileOutputStream out = new FileOutputStream(file)) {
            out.write(new byte[]{'R', 'I', 'F', 'F'}); little(out, 36 + pcm.length * 2, 4);
            out.write(new byte[]{'W', 'A', 'V', 'E', 'f', 'm', 't', ' '}); little(out, 16, 4);
            little(out, 1, 2); little(out, 1, 2); little(out, RATE, 4); little(out, RATE * 2, 4); little(out, 2, 2); little(out, 16, 2);
            out.write(new byte[]{'d', 'a', 't', 'a'}); little(out, pcm.length * 2, 4);
            byte[] bytes = new byte[pcm.length * 2];
            for (int i = 0; i < pcm.length; i++) { bytes[i * 2] = (byte) pcm[i]; bytes[i * 2 + 1] = (byte) (pcm[i] >> 8); }
            out.write(bytes);
        }
    }
    private static void little(FileOutputStream out, int value, int count) throws IOException {
        for (int i = 0; i < count; i++) out.write((value >> (8 * i)) & 255);
    }
}
