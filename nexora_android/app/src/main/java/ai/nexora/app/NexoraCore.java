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
    public static final String CORE_VERSION = "0.1";

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
        public String userName = "Jason";
        public String username = "jason";
        public String memory = "";
        public String customSystemPrompt = "";
        public String modelId = "1.5";
    }

    public static final class Result {
        public final boolean ok;
        public final String text;
        public final int httpCode;
        public Result(boolean ok, String text, int httpCode) {
            this.ok = ok;
            this.text = text;
            this.httpCode = httpCode;
        }
    }

    private NexoraCore() {}

    public static String systemPrompt(String modelId, String custom) {
        String base = "You are Nexora AI. Be accurate, practical, direct and helpful. " +
                "Never pretend a tool or capability exists if it does not. Preserve context, state uncertainty clearly, " +
                "and prefer complete useful answers over filler.";
        if ("1.0".equals(modelId)) {
            base += " Keep answers concise and simple unless detail is requested.";
        } else if ("1.1".equals(modelId)) {
            base += " Balance speed with reasoning. Explain important tradeoffs when useful.";
        } else {
            base += " Use stronger reasoning, structured planning, code awareness and deeper context handling for complex tasks.";
        }
        if (custom != null && !custom.trim().isEmpty()) base += "\nAdditional Nexora instruction: " + custom.trim();
        return base;
    }

    public static Result complete(Config config, List<Message> history, String latestText) {
        if (config.endpoint == null || config.endpoint.trim().isEmpty()) {
            return new Result(false,
                    "Nexora Core v" + CORE_VERSION + " ist bereit, aber noch kein echter Model-Server verbunden. " +
                    "Die App kann bereits Profil, Memory, Model-Routing und Chat-Kontext verwalten. Für starke KI-Antworten muss jetzt ein kompatibler Modell-Endpunkt verbunden werden.", 0);
        }

        HttpURLConnection conn = null;
        try {
            URL url = new URL(config.endpoint.trim());
            conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(60000);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            conn.setRequestProperty("Accept", "application/json, text/plain");
            conn.setRequestProperty("X-Nexora-Core", CORE_VERSION);
            if (config.apiKey != null && !config.apiKey.trim().isEmpty()) {
                conn.setRequestProperty("Authorization", "Bearer " + config.apiKey.trim());
            }
            conn.setDoOutput(true);

            JSONObject body = new JSONObject();
            body.put("core", "nexora-core-" + CORE_VERSION);
            body.put("model", "nexora-" + config.modelId);
            body.put("message", latestText == null ? "" : latestText);
            body.put("system", systemPrompt(config.modelId, config.customSystemPrompt));
            body.put("profile_name", config.userName == null ? "" : config.userName);
            body.put("profile_username", config.username == null ? "" : config.username);
            body.put("memory", config.memory == null ? "" : config.memory);
            body.put("capabilities", new JSONArray()
                    .put("multi_model_routing")
                    .put("profile_memory")
                    .put("conversation_context")
                    .put("system_prompt")
                    .put("retry_safe"));

            JSONArray messages = new JSONArray();
            JSONObject sys = new JSONObject();
            sys.put("role", "system");
            sys.put("content", systemPrompt(config.modelId, config.customSystemPrompt));
            messages.put(sys);
            if (config.memory != null && !config.memory.trim().isEmpty()) {
                JSONObject mem = new JSONObject();
                mem.put("role", "system");
                mem.put("content", "User memory/context: " + config.memory.trim());
                messages.put(mem);
            }
            int start = Math.max(0, history == null ? 0 : history.size() - 30);
            if (history != null) {
                for (int i = start; i < history.size(); i++) {
                    Message m = history.get(i);
                    JSONObject item = new JSONObject();
                    item.put("role", m.role);
                    item.put("content", m.content);
                    messages.put(item);
                }
            }
            body.put("messages", messages);
            body.put("history", messages);

            byte[] bytes = body.toString().getBytes(StandardCharsets.UTF_8);
            conn.setFixedLengthStreamingMode(bytes.length);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(bytes);
            }

            int code = conn.getResponseCode();
            InputStream stream = code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream();
            StringBuilder raw = new StringBuilder();
            if (stream != null) {
                try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = br.readLine()) != null) raw.append(line).append('\n');
                }
            }
            String response = raw.toString().trim();
            if (code < 200 || code >= 300) {
                return new Result(false, "Core HTTP " + code + (response.isEmpty() ? "" : ": " + response), code);
            }
            return new Result(true, parseResponse(response), code);
        } catch (Exception e) {
            String msg = e.getMessage() == null ? "Unbekannter Netzwerkfehler" : e.getMessage();
            return new Result(false, "Core-Verbindung fehlgeschlagen: " + msg, 0);
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static String parseResponse(String response) throws Exception {
        if (response == null || response.trim().isEmpty()) return "Der Core hat eine leere Antwort geliefert.";
        String t = response.trim();
        if (t.startsWith("{")) {
            JSONObject o = new JSONObject(t);
            if (o.has("text")) return o.optString("text", "");
            if (o.has("response")) return o.optString("response", "");
            if (o.has("output")) return o.optString("output", "");
            if (o.has("message") && o.opt("message") instanceof String) return o.optString("message", "");
            JSONArray choices = o.optJSONArray("choices");
            if (choices != null && choices.length() > 0) {
                JSONObject c = choices.optJSONObject(0);
                if (c != null) {
                    JSONObject m = c.optJSONObject("message");
                    if (m != null && m.has("content")) return m.optString("content", "");
                    if (c.has("text")) return c.optString("text", "");
                }
            }
        }
        return t;
    }

    public static List<Message> copyHistory(List<String[]> rows) {
        ArrayList<Message> out = new ArrayList<>();
        if (rows == null) return out;
        for (String[] row : rows) {
            if (row != null && row.length >= 2) out.add(new Message(row[0], row[1]));
        }
        return out;
    }
}
