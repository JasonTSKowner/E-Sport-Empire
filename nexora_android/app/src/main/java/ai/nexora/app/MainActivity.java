package ai.nexora.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

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
import java.util.UUID;

public class MainActivity extends Activity {
    private static final int BG = Color.rgb(9, 9, 11);
    private static final int PANEL = Color.rgb(20, 20, 25);
    private static final int PANEL_2 = Color.rgb(27, 27, 33);
    private static final int LINE = Color.rgb(42, 42, 51);
    private static final int TEXT = Color.rgb(244, 244, 247);
    private static final int MUTED = Color.rgb(145, 145, 158);
    private static final int ACCENT = Color.rgb(205, 211, 255);

    private final Handler main = new Handler(Looper.getMainLooper());
    private final ArrayList<Chat> chats = new ArrayList<>();

    private SharedPreferences prefs;
    private String activeId;
    private String defaultModel = "1.5";
    private boolean busy = false;

    private LinearLayout messageList;
    private ScrollView chatScroll;
    private EditText input;
    private Button sendButton;
    private TextView modelChip;
    private TextView profileButton;
    private TextView coreStatus;

    private static class Msg {
        String role;
        String text;
        String model;

        Msg(String role, String text, String model) {
            this.role = role;
            this.text = text;
            this.model = model;
        }
    }

    private static class Chat {
        String id;
        String title;
        String model;
        final ArrayList<Msg> messages = new ArrayList<>();

        Chat(String id, String title, String model) {
            this.id = id;
            this.title = title;
            this.model = model;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Window window = getWindow();
        window.setStatusBarColor(BG);
        window.setNavigationBarColor(BG);
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);

        prefs = getSharedPreferences("nexora_native", MODE_PRIVATE);
        loadState();
        buildUi();
        render();
    }

    private void buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BG);
        root.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        LinearLayout top = new LinearLayout(this);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setPadding(dp(10), dp(7), dp(10), dp(7));
        top.setBackgroundColor(BG);
        root.addView(top, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(58)));

        Button menu = smallButton("☰");
        menu.setOnClickListener(v -> showMenu());
        top.addView(menu, new LinearLayout.LayoutParams(dp(42), dp(42)));

        TextView brand = label("Nexora", 19, TEXT, true);
        LinearLayout.LayoutParams brandLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        brandLp.leftMargin = dp(10);
        top.addView(brand, brandLp);

        coreStatus = label("Core offline", 11, MUTED, false);
        LinearLayout.LayoutParams statusLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        statusLp.rightMargin = dp(8);
        top.addView(coreStatus, statusLp);

        profileButton = label("J", 14, TEXT, true);
        profileButton.setGravity(Gravity.CENTER);
        profileButton.setBackground(round(PANEL_2, 18, LINE, 1));
        profileButton.setOnClickListener(v -> showProfile());
        top.addView(profileButton, new LinearLayout.LayoutParams(dp(38), dp(38)));

        View divider = new View(this);
        divider.setBackgroundColor(Color.rgb(26, 26, 31));
        root.addView(divider, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(1)));

        chatScroll = new ScrollView(this);
        chatScroll.setFillViewport(true);
        chatScroll.setClipToPadding(false);
        messageList = new LinearLayout(this);
        messageList.setOrientation(LinearLayout.VERTICAL);
        messageList.setPadding(dp(14), dp(20), dp(14), dp(24));
        chatScroll.addView(messageList, new ScrollView.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        root.addView(chatScroll, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        LinearLayout composerWrap = new LinearLayout(this);
        composerWrap.setOrientation(LinearLayout.VERTICAL);
        composerWrap.setPadding(dp(10), dp(7), dp(10), dp(10));
        composerWrap.setBackgroundColor(BG);
        root.addView(composerWrap, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        LinearLayout composer = new LinearLayout(this);
        composer.setOrientation(LinearLayout.VERTICAL);
        composer.setPadding(dp(12), dp(8), dp(8), dp(8));
        composer.setBackground(round(PANEL, 21, LINE, 1));
        composerWrap.addView(composer, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        input = new EditText(this);
        input.setHint("Nachricht an Nexora …");
        input.setHintTextColor(Color.rgb(105, 105, 117));
        input.setTextColor(TEXT);
        input.setTextSize(15);
        input.setBackgroundColor(Color.TRANSPARENT);
        input.setPadding(dp(2), dp(5), dp(2), dp(8));
        input.setMaxLines(5);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        composer.addView(input, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        LinearLayout bottom = new LinearLayout(this);
        bottom.setOrientation(LinearLayout.HORIZONTAL);
        bottom.setGravity(Gravity.CENTER_VERTICAL);
        composer.addView(bottom, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(40)));

        modelChip = label("Nexora 1.5  ▾", 12, TEXT, true);
        modelChip.setGravity(Gravity.CENTER);
        modelChip.setPadding(dp(11), 0, dp(11), 0);
        modelChip.setBackground(round(Color.rgb(16, 16, 20), 12, LINE, 1));
        modelChip.setOnClickListener(v -> showModelPicker());
        bottom.addView(modelChip, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(34)));

        View spacer = new View(this);
        bottom.addView(spacer, new LinearLayout.LayoutParams(0, 1, 1f));

        sendButton = new Button(this);
        sendButton.setText("↑");
        sendButton.setTextSize(19);
        sendButton.setTextColor(Color.rgb(15, 15, 18));
        sendButton.setAllCaps(false);
        sendButton.setGravity(Gravity.CENTER);
        sendButton.setPadding(0, 0, 0, dp(2));
        sendButton.setBackground(round(Color.rgb(239, 239, 242), 13, Color.TRANSPARENT, 0));
        sendButton.setOnClickListener(v -> send());
        bottom.addView(sendButton, new LinearLayout.LayoutParams(dp(38), dp(38)));

        TextView disclaimer = label("Nexora kann Fehler machen. Wichtige Infos prüfen.", 9, Color.rgb(83, 83, 94), false);
        disclaimer.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams disLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        disLp.topMargin = dp(6);
        composerWrap.addView(disclaimer, disLp);

        setContentView(root);
        input.setOnEditorActionListener((v, actionId, event) -> false);
        updateProfileButton();
        updateCoreStatus();
    }

    private void render() {
        messageList.removeAllViews();
        Chat chat = activeChat();
        updateModelChip();
        updateCoreStatus();

        if (chat == null || chat.messages.isEmpty()) {
            renderWelcome();
        } else {
            for (Msg msg : chat.messages) addMessageView(msg);
            if (busy) addTypingView(chat.model);
        }
        main.postDelayed(() -> chatScroll.fullScroll(View.FOCUS_DOWN), 50);
    }

    private void renderWelcome() {
        LinearLayout welcome = new LinearLayout(this);
        welcome.setOrientation(LinearLayout.VERTICAL);
        welcome.setGravity(Gravity.CENTER_HORIZONTAL);
        welcome.setPadding(dp(10), dp(70), dp(10), dp(30));
        messageList.addView(welcome, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        ImageView logo = new ImageView(this);
        logo.setImageResource(R.drawable.ic_launcher);
        logo.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        welcome.addView(logo, new LinearLayout.LayoutParams(dp(76), dp(76)));

        TextView h = label("Was kann ich für dich tun?", 25, TEXT, true);
        h.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams hLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        hLp.topMargin = dp(18);
        welcome.addView(h, hLp);

        Chat c = activeChat();
        String m = c == null ? defaultModel : c.model;
        TextView sub = label("Nexora " + m + " · Native v1.5", 13, MUTED, false);
        sub.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        subLp.topMargin = dp(7);
        welcome.addView(sub, subLp);

        TextView note = label(coreEndpoint().isEmpty()
                ? "Die Oberfläche ist jetzt nativ. Für echte KI-Antworten muss nur noch der Nexora Core verbunden werden."
                : "Core verbunden. Schreib deine erste Nachricht.", 13, MUTED, false);
        note.setGravity(Gravity.CENTER);
        note.setLineSpacing(0, 1.18f);
        LinearLayout.LayoutParams noteLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        noteLp.topMargin = dp(18);
        welcome.addView(note, noteLp);

        String[] prompts = {"App planen", "Code verbessern", "Game-Konzept", "Problem analysieren"};
        for (String p : prompts) {
            TextView chip = label(p, 13, TEXT, true);
            chip.setGravity(Gravity.CENTER_VERTICAL);
            chip.setPadding(dp(14), 0, dp(14), 0);
            chip.setBackground(round(PANEL, 14, LINE, 1));
            chip.setOnClickListener(v -> {
                input.setText(((TextView) v).getText());
                input.setSelection(input.length());
                input.requestFocus();
            });
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
            lp.topMargin = dp(9);
            welcome.addView(chip, lp);
        }
    }

    private void addMessageView(Msg msg) {
        FrameLayout row = new FrameLayout(this);
        LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        rowLp.bottomMargin = dp(16);
        messageList.addView(row, rowLp);

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(13), dp(10), dp(13), dp(11));
        boolean user = "user".equals(msg.role);
        card.setBackground(round(user ? Color.rgb(36, 36, 43) : Color.rgb(17, 17, 21), 16, user ? Color.rgb(52, 52, 61) : Color.TRANSPARENT, user ? 1 : 0));

        TextView head = label(user ? profileName() : "Nexora " + (msg.model == null ? currentModel() : msg.model), 11, MUTED, true);
        card.addView(head);

        TextView body = label(msg.text, 15, TEXT, false);
        body.setLineSpacing(dp(2), 1.15f);
        LinearLayout.LayoutParams bodyLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        bodyLp.topMargin = dp(5);
        card.addView(body, bodyLp);

        FrameLayout.LayoutParams cardLp = new FrameLayout.LayoutParams(user ? dp(300) : ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        cardLp.gravity = user ? Gravity.END : Gravity.START;
        if (!user) cardLp.rightMargin = dp(14);
        row.addView(card, cardLp);
    }

    private void addTypingView(String model) {
        TextView t = label("Nexora " + model + " denkt …", 13, MUTED, false);
        t.setPadding(dp(13), dp(11), dp(13), dp(11));
        t.setBackground(round(Color.rgb(17, 17, 21), 15, Color.TRANSPARENT, 0));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.rightMargin = dp(14);
        lp.bottomMargin = dp(12);
        messageList.addView(t, lp);
    }

    private void send() {
        if (busy) return;
        String text = input.getText().toString().trim();
        if (text.isEmpty()) return;

        Chat c = activeChat();
        if (c == null) c = createChat();
        c.messages.add(new Msg("user", text, null));
        if ("Neuer Chat".equals(c.title)) c.title = text.length() > 34 ? text.substring(0, 34) + "…" : text;
        input.setText("");
        saveState();
        render();

        String endpoint = coreEndpoint();
        if (endpoint.isEmpty()) {
            Chat finalC = c;
            main.postDelayed(() -> {
                finalC.messages.add(new Msg("assistant",
                        "Der Nexora Core ist noch nicht verbunden. Öffne ☰ → Core verbinden und trage dort später euren Server-Endpunkt ein. Profil, Chats und Modellwahl funktionieren bereits nativ.",
                        finalC.model));
                saveState();
                render();
            }, 280);
            return;
        }

        busy = true;
        render();
        Chat requestChat = c;
        new Thread(() -> callCore(endpoint, requestChat, text)).start();
    }

    private void callCore(String endpoint, Chat chat, String latestText) {
        String answer;
        try {
            JSONObject body = new JSONObject();
            body.put("model", "nexora-" + chat.model);
            body.put("message", latestText);
            body.put("profile_name", profileName());
            body.put("profile_username", profileUsername());
            JSONArray history = new JSONArray();
            int start = Math.max(0, chat.messages.size() - 20);
            for (int i = start; i < chat.messages.size(); i++) {
                Msg m = chat.messages.get(i);
                JSONObject item = new JSONObject();
                item.put("role", m.role);
                item.put("content", m.text);
                history.put(item);
            }
            body.put("history", history);

            HttpURLConnection conn = (HttpURLConnection) new URL(endpoint).openConnection();
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            conn.setRequestProperty("Accept", "application/json, text/plain");
            conn.setDoOutput(true);
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
            if (code < 200 || code >= 300) throw new Exception("HTTP " + code + (response.isEmpty() ? "" : ": " + response));
            answer = parseCoreResponse(response);
            conn.disconnect();
        } catch (Exception e) {
            answer = "Core-Verbindung fehlgeschlagen. " + (e.getMessage() == null ? "Unbekannter Fehler." : e.getMessage());
        }

        String finalAnswer = answer;
        main.post(() -> {
            busy = false;
            chat.messages.add(new Msg("assistant", finalAnswer, chat.model));
            saveState();
            render();
        });
    }

    private String parseCoreResponse(String response) throws Exception {
        if (response == null || response.trim().isEmpty()) return "Der Core hat eine leere Antwort geliefert.";
        String t = response.trim();
        if (t.startsWith("{")) {
            JSONObject o = new JSONObject(t);
            if (o.has("text")) return o.optString("text", "");
            if (o.has("message")) return o.optString("message", "");
            if (o.has("output")) return o.optString("output", "");
            if (o.has("response")) return o.optString("response", "");
        }
        return t;
    }

    private void showModelPicker() {
        final String[] labels = {
                "Nexora 1.0\nLegacy · erste Generation",
                "Nexora 1.1\nBalanced · mehr Kontext",
                "Nexora 1.5\nNewest · stärkstes Profil"
        };
        final String[] ids = {"1.0", "1.1", "1.5"};
        int checked = "1.0".equals(currentModel()) ? 0 : ("1.1".equals(currentModel()) ? 1 : 2);
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Modell auswählen")
                .setSingleChoiceItems(labels, checked, null)
                .setNegativeButton("Abbrechen", null)
                .setPositiveButton("Übernehmen", null)
                .create();
        dialog.setOnShowListener(d -> dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
            int selected = dialog.getListView().getCheckedItemPosition();
            if (selected < 0) return;
            Chat c = activeChat();
            if (c == null) c = createChat();
            c.model = ids[selected];
            defaultModel = ids[selected];
            saveState();
            updateModelChip();
            render();
            dialog.dismiss();
        }));
        dialog.show();
    }

    private void showProfile() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();

        TextView title = label("Dein Profil", 21, TEXT, true);
        box.addView(title);
        TextView sub = label("Wird lokal auf diesem Gerät gespeichert.", 12, MUTED, false);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        subLp.topMargin = dp(4);
        subLp.bottomMargin = dp(18);
        box.addView(sub, subLp);

        EditText name = field("Anzeigename", profileName());
        box.addView(name, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)));

        EditText user = field("Username", profileUsername());
        LinearLayout.LayoutParams userLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        userLp.topMargin = dp(10);
        box.addView(user, userLp);

        Button save = actionButton("Profil speichern");
        LinearLayout.LayoutParams saveLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        saveLp.topMargin = dp(16);
        box.addView(save, saveLp);
        save.setOnClickListener(v -> {
            String n = name.getText().toString().trim();
            String u = user.getText().toString().trim();
            if (n.isEmpty()) n = "Jason";
            if (u.isEmpty()) u = "jason";
            prefs.edit().putString("profile_name", n).putString("profile_username", u).apply();
            updateProfileButton();
            render();
            dialog.dismiss();
            Toast.makeText(this, "Profil gespeichert", Toast.LENGTH_SHORT).show();
        });

        dialog.setContentView(box);
        configureDialogWindow(dialog);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showCoreSettings() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();
        box.addView(label("Nexora Core", 21, TEXT, true));
        TextView info = label("Hier kommt später euer eigener KI-Server rein. Die App sendet POST-JSON mit Modell, Nachricht und Chat-History.", 12, MUTED, false);
        info.setLineSpacing(0, 1.18f);
        LinearLayout.LayoutParams infoLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        infoLp.topMargin = dp(6);
        infoLp.bottomMargin = dp(16);
        box.addView(info, infoLp);

        EditText endpoint = field("https://dein-server.de/chat", coreEndpoint());
        endpoint.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        box.addView(endpoint, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)));

        Button save = actionButton("Core speichern");
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        lp.topMargin = dp(14);
        box.addView(save, lp);
        save.setOnClickListener(v -> {
            prefs.edit().putString("core_endpoint", endpoint.getText().toString().trim()).apply();
            updateCoreStatus();
            render();
            dialog.dismiss();
        });

        dialog.setContentView(box);
        configureDialogWindow(dialog);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showMenu() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();
        box.addView(label("Nexora", 21, TEXT, true));

        Button newChat = actionButton("＋  Neuer Chat");
        LinearLayout.LayoutParams newLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(46));
        newLp.topMargin = dp(14);
        box.addView(newChat, newLp);
        newChat.setOnClickListener(v -> {
            createChat();
            saveState();
            render();
            dialog.dismiss();
        });

        Button profile = secondaryButton("Profil");
        LinearLayout.LayoutParams pLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        pLp.topMargin = dp(8);
        box.addView(profile, pLp);
        profile.setOnClickListener(v -> {
            dialog.dismiss();
            showProfile();
        });

        Button core = secondaryButton("Core verbinden");
        LinearLayout.LayoutParams cLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        cLp.topMargin = dp(8);
        box.addView(core, cLp);
        core.setOnClickListener(v -> {
            dialog.dismiss();
            showCoreSettings();
        });

        TextView historyTitle = label("CHATS", 10, Color.rgb(100, 100, 112), true);
        historyTitle.setPadding(dp(2), dp(18), 0, dp(7));
        box.addView(historyTitle);

        ScrollView sc = new ScrollView(this);
        LinearLayout list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        sc.addView(list);
        for (Chat c : chats) {
            Button b = secondaryButton((c.id.equals(activeId) ? "●  " : "") + c.title);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42));
            lp.bottomMargin = dp(4);
            list.addView(b, lp);
            b.setOnClickListener(v -> {
                activeId = c.id;
                saveState();
                render();
                dialog.dismiss();
            });
        }
        LinearLayout.LayoutParams scLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(210));
        box.addView(sc, scLp);

        dialog.setContentView(box);
        configureDialogWindow(dialog);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private Chat createChat() {
        Chat c = new Chat(UUID.randomUUID().toString(), "Neuer Chat", defaultModel);
        chats.add(0, c);
        activeId = c.id;
        return c;
    }

    private Chat activeChat() {
        if (activeId == null) return null;
        for (Chat c : chats) if (activeId.equals(c.id)) return c;
        return null;
    }

    private String currentModel() {
        Chat c = activeChat();
        return c == null ? defaultModel : c.model;
    }

    private void updateModelChip() {
        if (modelChip != null) modelChip.setText("Nexora " + currentModel() + "  ▾");
    }

    private void updateProfileButton() {
        if (profileButton == null) return;
        String name = profileName().trim();
        profileButton.setText(name.isEmpty() ? "J" : name.substring(0, 1).toUpperCase());
    }

    private void updateCoreStatus() {
        if (coreStatus == null) return;
        coreStatus.setText(coreEndpoint().isEmpty() ? "Core offline" : "Core online");
        coreStatus.setTextColor(coreEndpoint().isEmpty() ? MUTED : Color.rgb(125, 221, 169));
    }

    private String profileName() {
        return prefs.getString("profile_name", "Jason");
    }

    private String profileUsername() {
        return prefs.getString("profile_username", "jason");
    }

    private String coreEndpoint() {
        return prefs.getString("core_endpoint", "").trim();
    }

    private void saveState() {
        try {
            JSONArray arr = new JSONArray();
            for (Chat c : chats) {
                JSONObject o = new JSONObject();
                o.put("id", c.id);
                o.put("title", c.title);
                o.put("model", c.model);
                JSONArray messages = new JSONArray();
                for (Msg m : c.messages) {
                    JSONObject mo = new JSONObject();
                    mo.put("role", m.role);
                    mo.put("text", m.text);
                    if (m.model != null) mo.put("model", m.model);
                    messages.put(mo);
                }
                o.put("messages", messages);
                arr.put(o);
            }
            prefs.edit()
                    .putString("chats_json", arr.toString())
                    .putString("active_id", activeId == null ? "" : activeId)
                    .putString("default_model", defaultModel)
                    .apply();
        } catch (Exception ignored) { }
    }

    private void loadState() {
        defaultModel = prefs.getString("default_model", "1.5");
        if (!"1.0".equals(defaultModel) && !"1.1".equals(defaultModel) && !"1.5".equals(defaultModel)) defaultModel = "1.5";
        activeId = prefs.getString("active_id", "");
        String raw = prefs.getString("chats_json", "");
        if (!raw.isEmpty()) {
            try {
                JSONArray arr = new JSONArray(raw);
                for (int i = 0; i < arr.length(); i++) {
                    JSONObject o = arr.getJSONObject(i);
                    Chat c = new Chat(o.optString("id", UUID.randomUUID().toString()), o.optString("title", "Chat"), o.optString("model", defaultModel));
                    JSONArray ms = o.optJSONArray("messages");
                    if (ms != null) {
                        for (int j = 0; j < ms.length(); j++) {
                            JSONObject mo = ms.getJSONObject(j);
                            c.messages.add(new Msg(mo.optString("role", "assistant"), mo.optString("text", ""), mo.optString("model", null)));
                        }
                    }
                    chats.add(c);
                }
            } catch (Exception ignored) { chats.clear(); }
        }
        if (chats.isEmpty()) createChat();
        if (activeChat() == null) activeId = chats.get(0).id;
    }

    private LinearLayout dialogBox() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(20), dp(20), dp(20), dp(20));
        box.setBackground(round(Color.rgb(17, 17, 21), 22, LINE, 1));
        return box;
    }

    private void configureDialogWindow(Dialog dialog) {
        Window w = dialog.getWindow();
        if (w == null) return;
        w.setBackgroundDrawableResource(android.R.color.transparent);
        WindowManager.LayoutParams p = new WindowManager.LayoutParams();
        p.copyFrom(w.getAttributes());
        p.width = Math.min(getResources().getDisplayMetrics().widthPixels - dp(24), dp(520));
        p.height = WindowManager.LayoutParams.WRAP_CONTENT;
        p.gravity = Gravity.CENTER;
        w.setAttributes(p);
    }

    private EditText field(String hint, String value) {
        EditText e = new EditText(this);
        e.setHint(hint);
        e.setHintTextColor(Color.rgb(100, 100, 112));
        e.setText(value == null ? "" : value);
        e.setTextColor(TEXT);
        e.setTextSize(14);
        e.setSingleLine(true);
        e.setPadding(dp(13), 0, dp(13), 0);
        e.setBackground(round(PANEL_2, 13, LINE, 1));
        return e;
    }

    private Button actionButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextSize(14);
        b.setTextColor(Color.rgb(18, 18, 22));
        b.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        b.setBackground(round(Color.rgb(235, 235, 239), 13, Color.TRANSPARENT, 0));
        return b;
    }

    private Button secondaryButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        b.setTextSize(13);
        b.setTextColor(TEXT);
        b.setPadding(dp(13), 0, dp(13), 0);
        b.setBackground(round(PANEL_2, 12, LINE, 1));
        return b;
    }

    private Button smallButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextSize(19);
        b.setTextColor(TEXT);
        b.setPadding(0, 0, 0, dp(1));
        b.setBackground(round(PANEL, 13, LINE, 1));
        return b;
    }

    private TextView label(String value, float size, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(size);
        t.setTextColor(color);
        if (bold) t.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return t;
    }

    private GradientDrawable round(int color, int radiusDp, int strokeColor, int strokeDp) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(dp(radiusDp));
        if (strokeDp > 0) d.setStroke(dp(strokeDp), strokeColor);
        return d;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
