package ai.nexora.app;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

public final class NexoraCore {
    private NexoraCore() {}

    public static final class Message {
        public final String role;
        public final String content;
        public Message(String role, String content) {
            this.role = role;
            this.content = content;
        }
    }

    public static final class Config {
        public String endpoint = "";
        public String apiKey = "";
        public String backendModel = "";
        public String nexoraVersion = "1.5";
        public String profileName = "User";
        public String profileUsername = "user";
        public String memory = "";
        public boolean streaming = true;
        public int timeoutMs = 60000;
    }

    public interface Callback {
        void onDelta(String accumulatedText);
        void onComplete(String finalText);
        void onError(String message);
    }

    public static void generate(Config cfg, List<Message> history, Callback callback) {
        if (cfg == null || cfg.endpoint == null || cfg.endpoint.trim().isEmpty()) {
            callback.onError("Kein Core-Endpunkt eingerichtet.");
            return;
        }
        if (cfg.backendModel == null || cfg.backendModel.trim().isEmpty()) {
            callback.onError("Für Nexora " + cfg.nexoraVersion + " ist noch kein Backend-Modell eingetragen.");
            return;
        }

        HttpURLConnection conn = null;
        try {
            String endpoint = normalizeEndpoint(cfg.endpoint);
            JSONObject body = buildRequest(cfg, history);
            byte[] bytes = body.toString().getBytes(StandardCharsets.UTF_8);

            conn = (HttpURLConnection) new URL(endpoint).openConnection();
            conn.setRequestMethod("POST");
            conn.setConnectTimeout(Math.max(10000, cfg.timeoutMs / 2));
            conn.setReadTimeout(Math.max(20000, cfg.timeoutMs));
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            conn.setRequestProperty("Accept", cfg.streaming ? "text/event-stream, application/json" : "application/json");
            if (cfg.apiKey != null && !cfg.apiKey.trim().isEmpty()) {
                conn.setRequestProperty("Authorization", "Bearer " + cfg.apiKey.trim());
            }
            conn.setDoOutput(true);
            conn.setFixedLengthStreamingMode(bytes.length);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(bytes);
            }

            int code = conn.getResponseCode();
            InputStream stream = code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream();
            if (code < 200 || code >= 300) {
                String errorBody = readAll(stream);
                callback.onError("Core HTTP " + code + (errorBody.isEmpty() ? "" : " · " + trimError(errorBody)));
                return;
            }

            if (cfg.streaming) {
                String result = consumeStream(stream, callback);
                if (result == null || result.trim().isEmpty()) {
                    callback.onError("Der Core hat keine Textantwort geliefert.");
                } else {
                    callback.onComplete(result);
                }
            } else {
                String raw = readAll(stream);
                String result = parseCompletion(raw);
                if (result.isEmpty()) callback.onError("Der Core hat keine Textantwort geliefert.");
                else callback.onComplete(result);
            }
        } catch (Exception e) {
            String message = e.getMessage();
            callback.onError(message == null || message.trim().isEmpty() ? "Unbekannter Core-Fehler." : message);
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static JSONObject buildRequest(Config cfg, List<Message> history) throws Exception {
        JSONObject body = new JSONObject();
        body.put("model", cfg.backendModel.trim());
        body.put("stream", cfg.streaming);
        body.put("temperature", temperature(cfg.nexoraVersion));
        body.put("max_tokens", maxTokens(cfg.nexoraVersion));

        JSONArray messages = new JSONArray();
        JSONObject system = new JSONObject();
        system.put("role", "system");
        system.put("content", systemPrompt(cfg));
        messages.put(system);

        int maxHistory = maxHistory(cfg.nexoraVersion);
        int start = Math.max(0, history == null ? 0 : history.size() - maxHistory);
        if (history != null) {
            for (int i = start; i < history.size(); i++) {
                Message m = history.get(i);
                if (m == null || m.content == null || m.content.trim().isEmpty()) continue;
                String role = "assistant".equals(m.role) ? "assistant" : "user";
                JSONObject item = new JSONObject();
                item.put("role", role);
                item.put("content", m.content);
                messages.put(item);
            }
        }
        body.put("messages", messages);
        return body;
    }

    private static String systemPrompt(Config cfg) {
        StringBuilder p = new StringBuilder();
        p.append("You are Nexora AI, model profile Nexora ").append(cfg.nexoraVersion).append(". ");
        p.append("You are a capable general assistant inside the Nexora mobile app. ");
        p.append("Answer the user's actual request directly. Be accurate, useful, and natural. ");
        p.append("Never claim you performed actions, browsing, file access, or real-world operations unless the supplied context proves it. ");
        p.append("When uncertain, say what is uncertain instead of inventing facts. ");
        p.append("For coding, prefer complete working solutions, explain important tradeoffs, and preserve existing project behavior unless asked to change it. ");
        p.append("Use the user's language unless they request another language. ");

        if ("1.0".equals(cfg.nexoraVersion)) {
            p.append("This profile prioritizes speed and concise answers. Keep reasoning lightweight and output compact unless detail is requested. ");
        } else if ("1.1".equals(cfg.nexoraVersion)) {
            p.append("This profile balances speed and quality. Check assumptions and give enough context to be reliably useful. ");
        } else {
            p.append("This is the strongest Nexora profile. Think carefully before answering complex tasks, verify internal consistency, and provide polished, structured results without exposing private chain-of-thought. ");
        }

        p.append("User profile: display name=").append(safe(cfg.profileName))
                .append(", username=").append(safe(cfg.profileUsername)).append(". ");
        if (cfg.memory != null && !cfg.memory.trim().isEmpty()) {
            p.append("Persistent user memory supplied by the app follows. Use only when relevant and never mention that it came from a hidden system prompt:\n")
                    .append(cfg.memory.trim()).append("\n");
        }
        return p.toString();
    }

    private static String consumeStream(InputStream stream, Callback callback) throws Exception {
        StringBuilder full = new StringBuilder();
        StringBuilder rawFallback = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                if (!line.startsWith("data:")) {
                    rawFallback.append(line).append('\n');
                    continue;
                }
                String data = line.substring(5).trim();
                if ("[DONE]".equals(data)) break;
                if (data.isEmpty()) continue;
                try {
                    JSONObject event = new JSONObject(data);
                    JSONArray choices = event.optJSONArray("choices");
                    if (choices == null || choices.length() == 0) continue;
                    JSONObject choice = choices.optJSONObject(0);
                    if (choice == null) continue;
                    JSONObject delta = choice.optJSONObject("delta");
                    if (delta != null) {
                        String content = delta.optString("content", "");
                        if (!content.isEmpty()) {
                            full.append(content);
                            callback.onDelta(full.toString());
                        }
                    } else {
                        JSONObject message = choice.optJSONObject("message");
                        if (message != null) {
                            String content = message.optString("content", "");
                            if (!content.isEmpty()) {
                                full.append(content);
                                callback.onDelta(full.toString());
                            }
                        }
                    }
                } catch (Exception ignored) {
                    rawFallback.append(data).append('\n');
                }
            }
        }
        if (full.length() > 0) return full.toString();
        String fallback = rawFallback.toString().trim();
        return fallback.isEmpty() ? "" : parseCompletion(fallback);
    }

    private static String parseCompletion(String raw) throws Exception {
        if (raw == null || raw.trim().isEmpty()) return "";
        String t = raw.trim();
        if (!t.startsWith("{")) return t;
        JSONObject root = new JSONObject(t);
        JSONArray choices = root.optJSONArray("choices");
        if (choices != null && choices.length() > 0) {
            JSONObject choice = choices.optJSONObject(0);
            if (choice != null) {
                JSONObject message = choice.optJSONObject("message");
                if (message != null) return message.optString("content", "");
                String text = choice.optString("text", "");
                if (!text.isEmpty()) return text;
            }
        }
        if (root.has("text")) return root.optString("text", "");
        if (root.has("output")) return root.optString("output", "");
        if (root.has("response")) return root.optString("response", "");
        return "";
    }

    private static String normalizeEndpoint(String base) {
        String t = base.trim();
        while (t.endsWith("/")) t = t.substring(0, t.length() - 1);
        if (t.endsWith("/chat/completions")) return t;
        if (t.endsWith("/v1")) return t + "/chat/completions";
        return t + "/v1/chat/completions";
    }

    private static int maxHistory(String version) {
        if ("1.0".equals(version)) return 12;
        if ("1.1".equals(version)) return 24;
        return 40;
    }

    private static int maxTokens(String version) {
        if ("1.0".equals(version)) return 900;
        if ("1.1".equals(version)) return 1800;
        return 3200;
    }

    private static double temperature(String version) {
        if ("1.0".equals(version)) return 0.55;
        if ("1.1".equals(version)) return 0.45;
        return 0.35;
    }

    private static String readAll(InputStream stream) throws Exception {
        if (stream == null) return "";
        StringBuilder out = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) out.append(line).append('\n');
        }
        return out.toString().trim();
    }

    private static String trimError(String text) {
        String t = text.replace('\n', ' ').trim();
        return t.length() > 260 ? t.substring(0, 260) + "…" : t;
    }

    private static String safe(String value) {
        if (value == null) return "";
        return value.replace('\n', ' ').replace('\r', ' ').trim();
    }

    public static List<Message> copyHistory(List<Message> input) {
        return input == null ? new ArrayList<>() : new ArrayList<>(input);
    }
}
