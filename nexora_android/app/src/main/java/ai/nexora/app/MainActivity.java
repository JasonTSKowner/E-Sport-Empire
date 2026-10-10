package ai.nexora.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
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

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class MainActivity extends Activity {
    private static final int BG = Color.rgb(7, 7, 9);
    private static final int PANEL = Color.rgb(18, 18, 23);
    private static final int PANEL_2 = Color.rgb(25, 25, 31);
    private static final int LINE = Color.rgb(43, 43, 53);
    private static final int TEXT = Color.rgb(246, 246, 249);
    private static final int MUTED = Color.rgb(147, 147, 160);
    private static final int ACCENT = Color.rgb(205, 212, 255);
    private static final int SUCCESS = Color.rgb(123, 223, 170);
    private static final int DANGER = Color.rgb(255, 122, 138);

    private final Handler main = new Handler(Looper.getMainLooper());
    private final ArrayList<Chat> chats = new ArrayList<>();

    private SharedPreferences prefs;
    private String activeId;
    private String defaultModel = "1.5";
    private boolean busy = false;
    private int generationToken = 0;
    private long lastStreamRender = 0L;

    private LinearLayout messageList;
    private ScrollView chatScroll;
    private EditText input;
    private Button sendButton;
    private TextView modelChip;
    private TextView profileButton;
    private TextView coreStatus;

    private static final class Msg {
        String role;
        String text;
        String model;

        Msg(String role, String text, String model) {
            this.role = role;
            this.text = text;
            this.model = model;
        }
    }

    private static final class Chat {
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
        root.addView(top, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(58)));

        Button menu = smallButton("☰");
        menu.setOnClickListener(v -> showMenu());
        top.addView(menu, new LinearLayout.LayoutParams(dp(42), dp(42)));

        TextView brand = label("Nexora", 19, TEXT, true);
        LinearLayout.LayoutParams brandLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        brandLp.leftMargin = dp(10);
        top.addView(brand, brandLp);

        coreStatus = label("Core offline", 11, MUTED, false);
        coreStatus.setPadding(dp(8), dp(7), dp(8), dp(7));
        coreStatus.setOnClickListener(v -> showCoreSettings());
        LinearLayout.LayoutParams statusLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        statusLp.rightMargin = dp(5);
        top.addView(coreStatus, statusLp);

        profileButton = label("J", 14, TEXT, true);
        profileButton.setGravity(Gravity.CENTER);
        profileButton.setBackground(round(PANEL_2, 18, LINE, 1));
        profileButton.setOnClickListener(v -> showProfile());
        top.addView(profileButton, new LinearLayout.LayoutParams(dp(38), dp(38)));

        View divider = new View(this);
        divider.setBackgroundColor(Color.rgb(25, 25, 30));
        root.addView(divider, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(1)));

        chatScroll = new ScrollView(this);
        chatScroll.setFillViewport(true);
        chatScroll.setClipToPadding(false);
        messageList = new LinearLayout(this);
        messageList.setOrientation(LinearLayout.VERTICAL);
        messageList.setPadding(dp(14), dp(18), dp(14), dp(24));
        chatScroll.addView(messageList, new ScrollView.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        root.addView(chatScroll, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        LinearLayout composerWrap = new LinearLayout(this);
        composerWrap.setOrientation(LinearLayout.VERTICAL);
        composerWrap.setPadding(dp(10), dp(7), dp(10), dp(10));
        root.addView(composerWrap, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        LinearLayout composer = new LinearLayout(this);
        composer.setOrientation(LinearLayout.VERTICAL);
        composer.setPadding(dp(12), dp(8), dp(8), dp(8));
        composer.setBackground(round(PANEL, 22, LINE, 1));
        composerWrap.addView(composer, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        input = new EditText(this);
        input.setHint("Nachricht an Nexora …");
        input.setHintTextColor(Color.rgb(103, 103, 115));
        input.setTextColor(TEXT);
        input.setTextSize(15);
        input.setBackgroundColor(Color.TRANSPARENT);
        input.setPadding(dp(2), dp(5), dp(2), dp(8));
        input.setMaxLines(6);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        composer.addView(input, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        LinearLayout bottom = new LinearLayout(this);
        bottom.setOrientation(LinearLayout.HORIZONTAL);
        bottom.setGravity(Gravity.CENTER_VERTICAL);
        composer.addView(bottom, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(40)));

        modelChip = label("Nexora 1.5  ▾", 12, TEXT, true);
        modelChip.setGravity(Gravity.CENTER);
        modelChip.setPadding(dp(11), 0, dp(11), 0);
        modelChip.setBackground(round(Color.rgb(14, 14, 18), 12, LINE, 1));
        modelChip.setOnClickListener(v -> showModelPicker());
        bottom.addView(modelChip, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(34)));

        TextView memoryChip = label("Memory", 11, MUTED, true);
        memoryChip.setGravity(Gravity.CENTER);
        memoryChip.setPadding(dp(10), 0, dp(10), 0);
        memoryChip.setBackground(round(Color.rgb(14, 14, 18), 12, LINE, 1));
        memoryChip.setOnClickListener(v -> showMemory());
        LinearLayout.LayoutParams memLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(34));
        memLp.leftMargin = dp(7);
        bottom.addView(memoryChip, memLp);

        View spacer = new View(this);
        bottom.addView(spacer, new LinearLayout.LayoutParams(0, 1, 1f));

        sendButton = new Button(this);
        sendButton.setText("↑");
        sendButton.setTextSize(19);
        sendButton.setTextColor(Color.rgb(14, 14, 18));
        sendButton.setAllCaps(false);
        sendButton.setGravity(Gravity.CENTER);
        sendButton.setPadding(0, 0, 0, dp(2));
        sendButton.setBackground(round(Color.rgb(239, 239, 243), 13, Color.TRANSPARENT, 0));
        sendButton.setOnClickListener(v -> {
            if (busy) stopGeneration();
            else send();
        });
        bottom.addView(sendButton, new LinearLayout.LayoutParams(dp(38), dp(38)));

        TextView disclaimer = label("Nexora kann Fehler machen. Wichtige Infos prüfen.", 9, Color.rgb(82, 82, 93), false);
        disclaimer.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams disLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        disLp.topMargin = dp(6);
        composerWrap.addView(disclaimer, disLp);

        setContentView(root);
        updateProfileButton();
        updateCoreStatus();
    }

    private void render() {
        if (messageList == null) return;
        messageList.removeAllViews();
        Chat chat = activeChat();
        updateModelChip();
        updateCoreStatus();
        updateSendButton();

        if (chat == null || chat.messages.isEmpty()) {
            renderWelcome();
        } else {
            for (int i = 0; i < chat.messages.size(); i++) {
                addMessageView(chat, chat.messages.get(i), i);
            }
            if (busy && (chat.messages.isEmpty() || !"assistant".equals(chat.messages.get(chat.messages.size() - 1).role))) {
                addTypingView(chat.model);
            }
        }
        main.postDelayed(() -> chatScroll.fullScroll(View.FOCUS_DOWN), 35);
    }

    private void renderWelcome() {
        LinearLayout welcome = new LinearLayout(this);
        welcome.setOrientation(LinearLayout.VERTICAL);
        welcome.setGravity(Gravity.CENTER_HORIZONTAL);
        welcome.setPadding(dp(10), dp(58), dp(10), dp(30));
        messageList.addView(welcome, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        ImageView logo = new ImageView(this);
        logo.setImageResource(R.drawable.nexora_pb);
        logo.setScaleType(ImageView.ScaleType.CENTER_CROP);
        logo.setBackground(round(Color.BLACK, 24, LINE, 1));
        welcome.addView(logo, new LinearLayout.LayoutParams(dp(86), dp(86)));

        TextView h = label("Was kann ich für dich tun?", 25, TEXT, true);
        h.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams hLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        hLp.topMargin = dp(18);
        welcome.addView(h, hLp);

        String model = currentModel();
        TextView sub = label("Nexora " + model + " · Core v1.6", 13, MUTED, false);
        sub.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        subLp.topMargin = dp(7);
        welcome.addView(sub, subLp);

        String state;
        if (!isCoreConfigured(model)) {
            state = "Core bereit zum Verbinden. Öffne oben ‘Core offline’, trage einen OpenAI-kompatiblen Server und das Backend-Modell ein.";
        } else {
            state = "Core konfiguriert · Streaming, lokales Memory und Modell-Routing sind aktiv.";
        }
        TextView note = label(state, 13, MUTED, false);
        note.setGravity(Gravity.CENTER);
        note.setLineSpacing(0, 1.18f);
        LinearLayout.LayoutParams noteLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        noteLp.topMargin = dp(16);
        noteLp.bottomMargin = dp(10);
        welcome.addView(note, noteLp);

        String[][] prompts = {
                {"App bauen", "Plane und implementiere mit mir eine neue App."},
                {"Code debuggen", "Hilf mir, einen Bug systematisch zu finden und zu fixen."},
                {"Game entwickeln", "Entwickle mit mir ein hochwertiges Game-Konzept."},
                {"Komplex lösen", "Analysiere dieses Problem gründlich und finde die beste Lösung."}
        };
        for (String[] p : prompts) {
            TextView chip = label(p[0], 13, TEXT, true);
            chip.setGravity(Gravity.CENTER_VERTICAL);
            chip.setPadding(dp(14), 0, dp(14), 0);
            chip.setBackground(round(PANEL, 14, LINE, 1));
            chip.setOnClickListener(v -> {
                input.setText(p[1]);
                input.setSelection(input.length());
                input.requestFocus();
            });
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
            lp.topMargin = dp(9);
            welcome.addView(chip, lp);
        }
    }

    private void addMessageView(Chat chat, Msg msg, int index) {
        boolean user = "user".equals(msg.role);
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(user ? Gravity.END | Gravity.TOP : Gravity.START | Gravity.TOP);
        LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        rowLp.bottomMargin = dp(16);
        messageList.addView(row, rowLp);

        if (!user) {
            ImageView avatar = new ImageView(this);
            avatar.setImageResource(R.drawable.nexora_pb);
            avatar.setScaleType(ImageView.ScaleType.CENTER_CROP);
            avatar.setBackground(round(Color.BLACK, 10, LINE, 1));
            LinearLayout.LayoutParams aLp = new LinearLayout.LayoutParams(dp(32), dp(32));
            aLp.rightMargin = dp(9);
            row.addView(avatar, aLp);
        }

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(13), dp(10), dp(13), dp(10));
        card.setBackground(round(user ? Color.rgb(35, 35, 43) : Color.rgb(14, 14, 18), 16,
                user ? Color.rgb(54, 54, 64) : Color.rgb(31, 31, 38), 1));
        card.setOnLongClickListener(v -> {
            copyText(msg.text);
            return true;
        });

        TextView head = label(user ? profileName() : "Nexora " + (msg.model == null ? chat.model : msg.model), 11, MUTED, true);
        card.addView(head);

        TextView body = label(msg.text == null || msg.text.isEmpty() ? "…" : msg.text, 15, TEXT, false);
        body.setTextIsSelectable(true);
        body.setLineSpacing(dp(2), 1.14f);
        LinearLayout.LayoutParams bodyLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        bodyLp.topMargin = dp(5);
        card.addView(body, bodyLp);

        if (!user && msg.text != null && !msg.text.isEmpty()) {
            LinearLayout tools = new LinearLayout(this);
            tools.setOrientation(LinearLayout.HORIZONTAL);
            tools.setGravity(Gravity.START | Gravity.CENTER_VERTICAL);
            LinearLayout.LayoutParams toolsLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(34));
            toolsLp.topMargin = dp(7);
            card.addView(tools, toolsLp);

            Button copy = miniButton("Kopieren");
            copy.setOnClickListener(v -> copyText(msg.text));
            tools.addView(copy, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(32)));

            if (index == chat.messages.size() - 1 && !busy) {
                Button regen = miniButton("Neu generieren");
                LinearLayout.LayoutParams regenLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(32));
                regenLp.leftMargin = dp(7);
                tools.addView(regen, regenLp);
                regen.setOnClickListener(v -> regenerateLast());
            }
        }

        int width = user ? Math.min(dp(320), getResources().getDisplayMetrics().widthPixels - dp(82)) : 0;
        LinearLayout.LayoutParams cardLp = new LinearLayout.LayoutParams(user ? width : 0, ViewGroup.LayoutParams.WRAP_CONTENT, user ? 0f : 1f);
        if (!user) cardLp.rightMargin = dp(10);
        row.addView(card, cardLp);
    }

    private void addTypingView(String model) {
        TextView t = label("Nexora " + model + " denkt …", 13, MUTED, false);
        t.setPadding(dp(13), dp(11), dp(13), dp(11));
        t.setBackground(round(Color.rgb(14, 14, 18), 15, LINE, 1));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.rightMargin = dp(14);
        lp.bottomMargin = dp(12);
        messageList.addView(t, lp);
    }

    private void send() {
        if (busy) return;
        String text = input.getText().toString().trim();
        if (text.isEmpty()) return;

        Chat chat = activeChat();
        if (chat == null) chat = createChat();
        chat.messages.add(new Msg("user", text, null));
        if ("Neuer Chat".equals(chat.title)) chat.title = makeTitle(text);
        input.setText("");
        saveState();
        startGeneration(chat);
    }

    private void startGeneration(Chat chat) {
        if (chat == null || busy) return;
        String version = chat.model == null ? defaultModel : chat.model;
        if (!isCoreConfigured(version)) {
            chat.messages.add(new Msg("assistant",
                    "Der echte Nexora-Core ist vorbereitet, aber für Nexora " + version + " fehlt noch der Modellserver oder die Backend-Modell-ID. Tippe oben auf ‘Core offline’ und verbinde einen OpenAI-kompatiblen Endpunkt. Ich spiele dir keine Fake-Antwort vor.",
                    version));
            saveState();
            render();
            return;
        }

        busy = true;
        final int token = ++generationToken;
        Msg streaming = new Msg("assistant", "", version);
        chat.messages.add(streaming);
        saveState();
        render();

        NexoraCore.Config cfg = new NexoraCore.Config();
        cfg.endpoint = coreBaseUrl();
        cfg.apiKey = SecretStore.get(this, "core_api_key");
        cfg.backendModel = backendModel(version);
        cfg.nexoraVersion = version;
        cfg.profileName = profileName();
        cfg.profileUsername = profileUsername();
        cfg.memory = memoryText();
        cfg.streaming = true;
        cfg.timeoutMs = 90000;

        List<NexoraCore.Message> history = new ArrayList<>();
        for (int i = 0; i < chat.messages.size() - 1; i++) {
            Msg m = chat.messages.get(i);
            history.add(new NexoraCore.Message(m.role, m.text));
        }

        new Thread(() -> NexoraCore.generate(cfg, history, new NexoraCore.Callback() {
            @Override
            public void onDelta(String accumulatedText) {
                if (token != generationToken) return;
                streaming.text = accumulatedText;
                long now = System.currentTimeMillis();
                if (now - lastStreamRender >= 80) {
                    lastStreamRender = now;
                    main.post(() -> {
                        if (token == generationToken) render();
                    });
                }
            }

            @Override
            public void onComplete(String finalText) {
                if (token != generationToken) return;
                main.post(() -> {
                    if (token != generationToken) return;
                    streaming.text = finalText == null || finalText.trim().isEmpty() ? "Der Core hat eine leere Antwort geliefert." : finalText.trim();
                    busy = false;
                    saveState();
                    render();
                });
            }

            @Override
            public void onError(String message) {
                if (token != generationToken) return;
                main.post(() -> {
                    if (token != generationToken) return;
                    streaming.text = "Core-Fehler: " + (message == null ? "Unbekannter Fehler." : message);
                    busy = false;
                    saveState();
                    render();
                });
            }
        })).start();
    }

    private void stopGeneration() {
        if (!busy) return;
        generationToken++;
        busy = false;
        Chat c = activeChat();
        if (c != null && !c.messages.isEmpty()) {
            Msg last = c.messages.get(c.messages.size() - 1);
            if ("assistant".equals(last.role) && (last.text == null || last.text.trim().isEmpty())) {
                c.messages.remove(c.messages.size() - 1);
            }
        }
        saveState();
        render();
        Toast.makeText(this, "Generierung gestoppt", Toast.LENGTH_SHORT).show();
    }

    private void regenerateLast() {
        if (busy) return;
        Chat c = activeChat();
        if (c == null || c.messages.isEmpty()) return;
        int last = c.messages.size() - 1;
        if (last >= 0 && "assistant".equals(c.messages.get(last).role)) {
            c.messages.remove(last);
        }
        if (c.messages.isEmpty() || !"user".equals(c.messages.get(c.messages.size() - 1).role)) {
            render();
            return;
        }
        saveState();
        startGeneration(c);
    }

    private void showModelPicker() {
        final String[] labels = {
                "Nexora 1.0\nFast · kurze Antworten, kleiner Kontext",
                "Nexora 1.1\nBalanced · mehr Kontext und Stabilität",
                "Nexora 1.5\nDeep · stärkstes Profil für Code und komplexe Aufgaben"
        };
        final String[] ids = {"1.0", "1.1", "1.5"};
        int checked = "1.0".equals(currentModel()) ? 0 : ("1.1".equals(currentModel()) ? 1 : 2);
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Nexora Modell")
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
            render();
            dialog.dismiss();
        }));
        dialog.show();
    }

    private void showProfile() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();

        LinearLayout head = new LinearLayout(this);
        head.setOrientation(LinearLayout.HORIZONTAL);
        head.setGravity(Gravity.CENTER_VERTICAL);
        box.addView(head, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        ImageView pb = new ImageView(this);
        pb.setImageResource(R.drawable.nexora_pb);
        pb.setScaleType(ImageView.ScaleType.CENTER_CROP);
        pb.setBackground(round(Color.BLACK, 14, LINE, 1));
        head.addView(pb, new LinearLayout.LayoutParams(dp(48), dp(48)));

        LinearLayout texts = new LinearLayout(this);
        texts.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams textsLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        textsLp.leftMargin = dp(12);
        head.addView(texts, textsLp);
        texts.addView(label("Dein Profil", 21, TEXT, true));
        texts.addView(label("Nexora merkt sich diese Angaben lokal.", 12, MUTED, false));

        EditText name = field("Anzeigename", profileName());
        LinearLayout.LayoutParams nLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        nLp.topMargin = dp(18);
        box.addView(name, nLp);

        EditText user = field("Username", profileUsername());
        LinearLayout.LayoutParams uLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        uLp.topMargin = dp(10);
        box.addView(user, uLp);

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

    private void showMemory() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();
        box.addView(label("Nexora Memory", 21, TEXT, true));
        TextView info = label("Schreib hier Dinge rein, die Nexora dauerhaft berücksichtigen soll. Sie werden lokal gespeichert und bei jeder Anfrage passend zum Chat mitgegeben.", 12, MUTED, false);
        info.setLineSpacing(0, 1.18f);
        LinearLayout.LayoutParams infoLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        infoLp.topMargin = dp(6);
        infoLp.bottomMargin = dp(14);
        box.addView(info, infoLp);

        EditText memory = new EditText(this);
        memory.setText(memoryText());
        memory.setHint("z. B. Bevorzugte Sprache, Projektziele, Coding-Stil …");
        memory.setHintTextColor(Color.rgb(96, 96, 108));
        memory.setTextColor(TEXT);
        memory.setTextSize(13);
        memory.setGravity(Gravity.TOP | Gravity.START);
        memory.setPadding(dp(13), dp(11), dp(13), dp(11));
        memory.setBackground(round(PANEL_2, 13, LINE, 1));
        memory.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        box.addView(memory, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(170)));

        Button save = actionButton("Memory speichern");
        LinearLayout.LayoutParams saveLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        saveLp.topMargin = dp(14);
        box.addView(save, saveLp);
        save.setOnClickListener(v -> {
            prefs.edit().putString("memory_text", memory.getText().toString().trim()).apply();
            dialog.dismiss();
            Toast.makeText(this, "Memory gespeichert", Toast.LENGTH_SHORT).show();
        });

        dialog.setContentView(box);
        configureDialogWindow(dialog);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showCoreSettings() {
        Dialog dialog = new Dialog(this);
        ScrollView outer = new ScrollView(this);
        LinearLayout box = dialogBox();
        outer.addView(box);

        box.addView(label("Nexora Core v1.6", 21, TEXT, true));
        TextView info = label("Verbindet Nexora mit jedem OpenAI-kompatiblen /v1/chat/completions Server. Streaming, Memory und Modell-Routing übernimmt die App.", 12, MUTED, false);
        info.setLineSpacing(0, 1.18f);
        LinearLayout.LayoutParams infoLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        infoLp.topMargin = dp(6);
        infoLp.bottomMargin = dp(14);
        box.addView(info, infoLp);

        EditText endpoint = field("Base URL · z. B. https://server.example/v1", coreBaseUrl());
        endpoint.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        box.addView(endpoint, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)));

        String existingKey = SecretStore.get(this, "core_api_key");
        EditText apiKey = field("API-Key · optional bei lokalem Server", existingKey.isEmpty() ? "" : "••••••••");
        apiKey.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        LinearLayout.LayoutParams keyLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        keyLp.topMargin = dp(10);
        box.addView(apiKey, keyLp);

        TextView routing = label("MODELL-ROUTING", 10, Color.rgb(103, 103, 116), true);
        routing.setPadding(dp(2), dp(18), 0, dp(7));
        box.addView(routing);

        EditText m10 = field("Backend-Modell für Nexora 1.0", backendModel("1.0"));
        box.addView(m10, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)));
        EditText m11 = field("Backend-Modell für Nexora 1.1", backendModel("1.1"));
        LinearLayout.LayoutParams m11Lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        m11Lp.topMargin = dp(8);
        box.addView(m11, m11Lp);
        EditText m15 = field("Backend-Modell für Nexora 1.5", backendModel("1.5"));
        LinearLayout.LayoutParams m15Lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        m15Lp.topMargin = dp(8);
        box.addView(m15, m15Lp);

        TextView security = label("API-Keys werden verschlüsselt über Android Keystore gespeichert und nicht in den Chatverlauf geschrieben.", 11, MUTED, false);
        security.setLineSpacing(0, 1.15f);
        LinearLayout.LayoutParams secLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        secLp.topMargin = dp(12);
        box.addView(security, secLp);

        Button save = actionButton("Core speichern");
        LinearLayout.LayoutParams saveLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        saveLp.topMargin = dp(14);
        box.addView(save, saveLp);
        save.setOnClickListener(v -> {
            String base = endpoint.getText().toString().trim();
            String key = apiKey.getText().toString();
            prefs.edit()
                    .putString("core_base_url", base)
                    .putString("core_model_10", m10.getText().toString().trim())
                    .putString("core_model_11", m11.getText().toString().trim())
                    .putString("core_model_15", m15.getText().toString().trim())
                    .apply();
            if (!"••••••••".equals(key)) {
                if (key.trim().isEmpty()) SecretStore.clear(this, "core_api_key");
                else SecretStore.put(this, "core_api_key", key.trim());
            }
            updateCoreStatus();
            render();
            dialog.dismiss();
            Toast.makeText(this, "Core-Konfiguration gespeichert", Toast.LENGTH_SHORT).show();
        });

        Button clearKey = dangerButton("Gespeicherten API-Key löschen");
        LinearLayout.LayoutParams clearLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        clearLp.topMargin = dp(8);
        box.addView(clearKey, clearLp);
        clearKey.setOnClickListener(v -> {
            SecretStore.clear(this, "core_api_key");
            apiKey.setText("");
            Toast.makeText(this, "API-Key gelöscht", Toast.LENGTH_SHORT).show();
        });

        dialog.setContentView(outer);
        configureDialogWindow(dialog);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showMenu() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();

        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        box.addView(titleRow, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        ImageView logo = new ImageView(this);
        logo.setImageResource(R.drawable.nexora_pb);
        logo.setScaleType(ImageView.ScaleType.CENTER_CROP);
        logo.setBackground(round(Color.BLACK, 10, LINE, 1));
        titleRow.addView(logo, new LinearLayout.LayoutParams(dp(36), dp(36)));
        TextView title = label("Nexora", 21, TEXT, true);
        LinearLayout.LayoutParams titleLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        titleLp.leftMargin = dp(10);
        titleRow.addView(title, titleLp);
        TextView version = label("v1.6", 11, MUTED, true);
        titleRow.addView(version);

        Button newChat = actionButton("＋  Neuer Chat");
        LinearLayout.LayoutParams newLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(46));
        newLp.topMargin = dp(14);
        box.addView(newChat, newLp);
        newChat.setOnClickListener(v -> {
            generationToken++;
            busy = false;
            createChat();
            saveState();
            render();
            dialog.dismiss();
        });

        LinearLayout quick = new LinearLayout(this);
        quick.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams quickLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        quickLp.topMargin = dp(8);
        box.addView(quick, quickLp);

        Button profile = secondaryButton("Profil");
        quick.addView(profile, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f));
        profile.setOnClickListener(v -> { dialog.dismiss(); showProfile(); });

        Button memory = secondaryButton("Memory");
        LinearLayout.LayoutParams memoryLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f);
        memoryLp.leftMargin = dp(6);
        quick.addView(memory, memoryLp);
        memory.setOnClickListener(v -> { dialog.dismiss(); showMemory(); });

        Button core = secondaryButton("Core & Modelle");
        LinearLayout.LayoutParams coreLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        coreLp.topMargin = dp(8);
        box.addView(core, coreLp);
        core.setOnClickListener(v -> { dialog.dismiss(); showCoreSettings(); });

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
                generationToken++;
                busy = false;
                activeId = c.id;
                saveState();
                render();
                dialog.dismiss();
            });
        }
        box.addView(sc, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(190)));

        Button delete = dangerButton("Aktuellen Chat löschen");
        LinearLayout.LayoutParams deleteLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42));
        deleteLp.topMargin = dp(10);
        box.addView(delete, deleteLp);
        delete.setOnClickListener(v -> {
            Chat c = activeChat();
            if (c != null) chats.remove(c);
            if (chats.isEmpty()) createChat();
            else activeId = chats.get(0).id;
            generationToken++;
            busy = false;
            saveState();
            render();
            dialog.dismiss();
        });

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
        return c == null || c.model == null ? defaultModel : c.model;
    }

    private String coreBaseUrl() {
        String migrated = prefs.getString("core_base_url", "");
        if (migrated == null || migrated.trim().isEmpty()) {
            String legacy = prefs.getString("core_endpoint", "");
            if (legacy != null && !legacy.trim().isEmpty()) {
                migrated = legacy.trim();
                prefs.edit().putString("core_base_url", migrated).remove("core_endpoint").apply();
            }
        }
        return migrated == null ? "" : migrated.trim();
    }

    private String backendModel(String version) {
        String key;
        if ("1.0".equals(version)) key = "core_model_10";
        else if ("1.1".equals(version)) key = "core_model_11";
        else key = "core_model_15";
        return prefs.getString(key, "").trim();
    }

    private boolean isCoreConfigured(String version) {
        return !coreBaseUrl().isEmpty() && !backendModel(version).isEmpty();
    }

    private String memoryText() {
        return prefs.getString("memory_text", "");
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
        boolean configured = isCoreConfigured(currentModel());
        coreStatus.setText(configured ? "Core ready" : "Core offline");
        coreStatus.setTextColor(configured ? SUCCESS : MUTED);
    }

    private void updateSendButton() {
        if (sendButton == null) return;
        sendButton.setText(busy ? "■" : "↑");
        sendButton.setTextSize(busy ? 14 : 19);
    }

    private String profileName() {
        return prefs.getString("profile_name", "Jason");
    }

    private String profileUsername() {
        return prefs.getString("profile_username", "jason");
    }

    private String makeTitle(String text) {
        String clean = text.replace('\n', ' ').trim();
        return clean.length() > 34 ? clean.substring(0, 34) + "…" : clean;
    }

    private void copyText(String text) {
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboard != null) {
            clipboard.setPrimaryClip(ClipData.newPlainText("Nexora", text == null ? "" : text));
            Toast.makeText(this, "Kopiert", Toast.LENGTH_SHORT).show();
        }
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
                    mo.put("text", m.text == null ? "" : m.text);
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
        } catch (Exception ignored) {
        }
    }

    private void loadState() {
        defaultModel = prefs.getString("default_model", "1.5");
        if (!"1.0".equals(defaultModel) && !"1.1".equals(defaultModel) && !"1.5".equals(defaultModel)) defaultModel = "1.5";
        activeId = prefs.getString("active_id", "");
        String raw = prefs.getString("chats_json", "");
        if (raw != null && !raw.isEmpty()) {
            try {
                JSONArray arr = new JSONArray(raw);
                for (int i = 0; i < arr.length(); i++) {
                    JSONObject o = arr.getJSONObject(i);
                    Chat c = new Chat(o.optString("id", UUID.randomUUID().toString()), o.optString("title", "Chat"), o.optString("model", defaultModel));
                    if (!"1.0".equals(c.model) && !"1.1".equals(c.model) && !"1.5".equals(c.model)) c.model = defaultModel;
                    JSONArray ms = o.optJSONArray("messages");
                    if (ms != null) {
                        for (int j = 0; j < ms.length(); j++) {
                            JSONObject mo = ms.getJSONObject(j);
                            c.messages.add(new Msg(mo.optString("role", "assistant"), mo.optString("text", ""), mo.optString("model", null)));
                        }
                    }
                    chats.add(c);
                }
            } catch (Exception ignored) {
                chats.clear();
            }
        }
        if (chats.isEmpty()) createChat();
        if (activeChat() == null) activeId = chats.get(0).id;
    }

    private LinearLayout dialogBox() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(20), dp(20), dp(20), dp(20));
        box.setBackground(round(Color.rgb(15, 15, 19), 22, LINE, 1));
        return box;
    }

    private void configureDialogWindow(Dialog dialog) {
        Window w = dialog.getWindow();
        if (w == null) return;
        w.setBackgroundDrawableResource(android.R.color.transparent);
        WindowManager.LayoutParams p = new WindowManager.LayoutParams();
        p.copyFrom(w.getAttributes());
        p.width = Math.min(getResources().getDisplayMetrics().widthPixels - dp(24), dp(520));
        p.height = Math.min(getResources().getDisplayMetrics().heightPixels - dp(80), WindowManager.LayoutParams.WRAP_CONTENT);
        p.gravity = Gravity.CENTER;
        w.setAttributes(p);
    }

    private EditText field(String hint, String value) {
        EditText e = new EditText(this);
        e.setHint(hint);
        e.setHintTextColor(Color.rgb(99, 99, 111));
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
        b.setTextColor(Color.rgb(17, 17, 21));
        b.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        b.setBackground(round(Color.rgb(237, 237, 241), 13, Color.TRANSPARENT, 0));
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

    private Button dangerButton(String text) {
        Button b = secondaryButton(text);
        b.setTextColor(DANGER);
        return b;
    }

    private Button miniButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextSize(11);
        b.setTextColor(MUTED);
        b.setPadding(dp(9), 0, dp(9), 0);
        b.setBackground(round(Color.rgb(20, 20, 25), 10, LINE, 1));
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
