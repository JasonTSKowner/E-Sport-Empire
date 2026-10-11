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
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.text.method.PasswordTransformationMethod;
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
    private static final int BG = Color.rgb(8, 8, 10);
    private static final int PANEL = Color.rgb(19, 19, 24);
    private static final int PANEL_2 = Color.rgb(26, 26, 33);
    private static final int PANEL_3 = Color.rgb(32, 32, 40);
    private static final int LINE = Color.rgb(43, 43, 53);
    private static final int TEXT = Color.rgb(244, 244, 248);
    private static final int MUTED = Color.rgb(145, 145, 159);
    private static final int ACCENT = Color.rgb(214, 218, 255);
    private static final int GREEN = Color.rgb(124, 225, 170);
    private static final int RED = Color.rgb(245, 117, 132);

    private final Handler main = new Handler(Looper.getMainLooper());
    private final ArrayList<Chat> chats = new ArrayList<>();

    private SharedPreferences prefs;
    private String activeId;
    private String defaultModel = "1.5";
    private boolean busy = false;
    private int requestGeneration = 0;

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
        menu.setContentDescription("Menü");
        menu.setOnClickListener(v -> showMenu());
        top.addView(menu, new LinearLayout.LayoutParams(dp(42), dp(42)));

        LinearLayout brandWrap = new LinearLayout(this);
        brandWrap.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams brandWrapLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        brandWrapLp.leftMargin = dp(10);
        top.addView(brandWrap, brandWrapLp);

        brandWrap.addView(label("Nexora", 18, TEXT, true));
        TextView version = label("AI · v1.6", 9, Color.rgb(95, 95, 108), false);
        version.setPadding(0, dp(1), 0, 0);
        brandWrap.addView(version);

        coreStatus = label("Core", 10, MUTED, true);
        coreStatus.setPadding(dp(9), dp(5), dp(9), dp(5));
        coreStatus.setGravity(Gravity.CENTER);
        coreStatus.setBackground(round(PANEL, 12, LINE, 1));
        coreStatus.setOnClickListener(v -> showCoreSettings());
        LinearLayout.LayoutParams statusLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        statusLp.rightMargin = dp(8);
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
        input.setHintTextColor(Color.rgb(105, 105, 118));
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
        modelChip.setBackground(round(Color.rgb(15, 15, 19), 12, LINE, 1));
        modelChip.setOnClickListener(v -> showModelPicker());
        bottom.addView(modelChip, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(34)));

        TextView memoryBadge = label("Memory", 10, MUTED, true);
        memoryBadge.setGravity(Gravity.CENTER);
        memoryBadge.setPadding(dp(10), 0, dp(10), 0);
        memoryBadge.setBackground(round(Color.rgb(15, 15, 19), 12, LINE, 1));
        memoryBadge.setOnClickListener(v -> showMemorySettings());
        LinearLayout.LayoutParams memoryLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(34));
        memoryLp.leftMargin = dp(7);
        bottom.addView(memoryBadge, memoryLp);

        View spacer = new View(this);
        bottom.addView(spacer, new LinearLayout.LayoutParams(0, 1, 1f));

        sendButton = new Button(this);
        sendButton.setText("↑");
        sendButton.setTextSize(19);
        sendButton.setTextColor(Color.rgb(15, 15, 18));
        sendButton.setAllCaps(false);
        sendButton.setGravity(Gravity.CENTER);
        sendButton.setPadding(0, 0, 0, dp(2));
        sendButton.setBackground(round(Color.rgb(239, 239, 243), 13, Color.TRANSPARENT, 0));
        sendButton.setOnClickListener(v -> {
            if (busy) stopGeneration(); else send();
        });
        bottom.addView(sendButton, new LinearLayout.LayoutParams(dp(38), dp(38)));

        TextView disclaimer = label("Nexora kann Fehler machen. Wichtige Infos prüfen.", 9, Color.rgb(80, 80, 91), false);
        disclaimer.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams disLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        disLp.topMargin = dp(6);
        composerWrap.addView(disclaimer, disLp);

        input.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) { }
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { updateSendButton(); }
            @Override public void afterTextChanged(Editable s) { }
        });

        setContentView(root);
        updateProfileButton();
        updateCoreStatus();
        updateSendButton();
    }

    private void render() {
        messageList.removeAllViews();
        Chat chat = activeChat();
        updateModelChip();
        updateCoreStatus();
        updateSendButton();

        if (chat == null || chat.messages.isEmpty()) {
            renderWelcome();
        } else {
            for (int i = 0; i < chat.messages.size(); i++) addMessageView(chat.messages.get(i), i);
            if (busy) addTypingView(chat.model);
        }
        main.postDelayed(() -> chatScroll.fullScroll(View.FOCUS_DOWN), 50);
    }

    private void renderWelcome() {
        LinearLayout welcome = new LinearLayout(this);
        welcome.setOrientation(LinearLayout.VERTICAL);
        welcome.setGravity(Gravity.CENTER_HORIZONTAL);
        welcome.setPadding(dp(10), dp(54), dp(10), dp(30));
        messageList.addView(welcome, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        ImageView logo = new ImageView(this);
        logo.setImageResource(R.drawable.nexora_pb);
        logo.setScaleType(ImageView.ScaleType.CENTER_CROP);
        logo.setBackground(round(Color.BLACK, 24, LINE, 1));
        welcome.addView(logo, new LinearLayout.LayoutParams(dp(84), dp(84)));

        TextView h = label("Was kann ich für dich tun?", 25, TEXT, true);
        h.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams hLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        hLp.topMargin = dp(18);
        welcome.addView(h, hLp);

        TextView sub = label("Nexora " + currentModel() + " · Core v" + NexoraCore.CORE_VERSION, 12, MUTED, true);
        sub.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        subLp.topMargin = dp(7);
        welcome.addView(sub, subLp);

        String state = coreEndpoint().isEmpty()
                ? "Core-System aktiv · echter Model-Server noch nicht verbunden"
                : "Model-Server verbunden · Memory und Kontext aktiv";
        TextView note = label(state, 12, coreEndpoint().isEmpty() ? MUTED : GREEN, false);
        note.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams noteLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        noteLp.topMargin = dp(10);
        noteLp.bottomMargin = dp(16);
        welcome.addView(note, noteLp);

        String[][] prompts = {
                {"App bauen", "Plane mit mir eine App komplett von Grund auf."},
                {"Code analysieren", "Analysiere meinen Code systematisch und verbessere ihn."},
                {"Game entwickeln", "Entwickle mit mir ein starkes Game-Konzept mit Progression."},
                {"Deep Reasoning", "Analysiere dieses Problem gründlich und nenne die beste Lösung."}
        };
        for (String[] p : prompts) {
            LinearLayout card = new LinearLayout(this);
            card.setOrientation(LinearLayout.VERTICAL);
            card.setPadding(dp(14), dp(10), dp(14), dp(9));
            card.setBackground(round(PANEL, 14, LINE, 1));
            card.addView(label(p[0], 13, TEXT, true));
            card.addView(label(p[1], 11, MUTED, false));
            card.setOnClickListener(v -> {
                input.setText(p[1]);
                input.setSelection(input.length());
                input.requestFocus();
            });
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.topMargin = dp(8);
            welcome.addView(card, lp);
        }
    }

    private void addMessageView(Msg msg, int index) {
        FrameLayout row = new FrameLayout(this);
        LinearLayout.LayoutParams rowLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        rowLp.bottomMargin = dp(14);
        messageList.addView(row, rowLp);

        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(13), dp(10), dp(13), dp(10));
        boolean user = "user".equals(msg.role);
        card.setBackground(round(user ? Color.rgb(35, 35, 43) : Color.rgb(16, 16, 20), 16,
                user ? Color.rgb(52, 52, 62) : Color.TRANSPARENT, user ? 1 : 0));

        TextView head = label(user ? profileName() : "Nexora " + (msg.model == null ? currentModel() : msg.model), 10, MUTED, true);
        card.addView(head);

        TextView body = label(msg.text, 15, TEXT, false);
        body.setTextIsSelectable(true);
        body.setLineSpacing(dp(2), 1.14f);
        body.setOnLongClickListener(v -> {
            copyText(msg.text);
            return true;
        });
        LinearLayout.LayoutParams bodyLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        bodyLp.topMargin = dp(5);
        card.addView(body, bodyLp);

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        actions.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams actionsLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(30));
        actionsLp.topMargin = dp(6);
        card.addView(actions, actionsLp);

        TextView copy = miniAction("Kopieren");
        copy.setOnClickListener(v -> copyText(msg.text));
        actions.addView(copy, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(28)));

        if (!user && index == activeChat().messages.size() - 1) {
            TextView retry = miniAction("Regenerieren");
            retry.setOnClickListener(v -> regenerateLast());
            LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(28));
            rlp.leftMargin = dp(6);
            actions.addView(retry, rlp);
        }

        FrameLayout.LayoutParams cardLp = new FrameLayout.LayoutParams(user ? dp(310) : ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        cardLp.gravity = user ? Gravity.END : Gravity.START;
        if (!user) cardLp.rightMargin = dp(10);
        row.addView(card, cardLp);
    }

    private TextView miniAction(String text) {
        TextView t = label(text, 10, Color.rgb(126, 126, 141), true);
        t.setGravity(Gravity.CENTER);
        t.setPadding(dp(8), 0, dp(8), 0);
        t.setBackground(round(Color.rgb(22, 22, 28), 10, LINE, 1));
        return t;
    }

    private void addTypingView(String model) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.HORIZONTAL);
        box.setGravity(Gravity.CENTER_VERTICAL);
        box.setPadding(dp(12), dp(10), dp(12), dp(10));
        box.setBackground(round(Color.rgb(16, 16, 20), 15, Color.TRANSPARENT, 0));
        TextView t = label("Nexora " + model + " denkt …", 12, MUTED, true);
        box.addView(t, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        TextView stop = miniAction("Stop");
        stop.setTextColor(RED);
        stop.setOnClickListener(v -> stopGeneration());
        box.addView(stop, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(28)));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.rightMargin = dp(10);
        lp.bottomMargin = dp(12);
        messageList.addView(box, lp);
    }

    private void send() {
        if (busy) return;
        String text = input.getText().toString().trim();
        if (text.isEmpty()) return;

        Chat c = activeChat();
        if (c == null) c = createChat();
        c.messages.add(new Msg("user", text, null));
        if ("Neuer Chat".equals(c.title)) c.title = makeTitle(text);
        input.setText("");
        saveState();
        requestAnswer(c, text);
    }

    private void requestAnswer(Chat chat, String latestText) {
        busy = true;
        requestGeneration++;
        final int generation = requestGeneration;
        render();

        NexoraCore.Config config = new NexoraCore.Config();
        config.endpoint = coreEndpoint();
        config.apiKey = coreApiKey();
        config.userName = profileName();
        config.username = profileUsername();
        config.memory = memoryText();
        config.customSystemPrompt = customInstruction();
        config.modelId = chat.model;

        ArrayList<NexoraCore.Message> history = new ArrayList<>();
        for (Msg m : chat.messages) history.add(new NexoraCore.Message(m.role, m.text));

        new Thread(() -> {
            NexoraCore.Result result = NexoraCore.complete(config, history, latestText);
            main.post(() -> {
                if (generation != requestGeneration) return;
                busy = false;
                chat.messages.add(new Msg("assistant", result.text, chat.model));
                saveState();
                render();
            });
        }).start();
    }

    private void stopGeneration() {
        if (!busy) return;
        requestGeneration++;
        busy = false;
        render();
        Toast.makeText(this, "Generierung gestoppt", Toast.LENGTH_SHORT).show();
    }

    private void regenerateLast() {
        if (busy) return;
        Chat c = activeChat();
        if (c == null || c.messages.isEmpty()) return;
        if ("assistant".equals(c.messages.get(c.messages.size() - 1).role)) c.messages.remove(c.messages.size() - 1);
        String latest = null;
        for (int i = c.messages.size() - 1; i >= 0; i--) {
            if ("user".equals(c.messages.get(i).role)) {
                latest = c.messages.get(i).text;
                break;
            }
        }
        if (latest == null) return;
        saveState();
        requestAnswer(c, latest);
    }

    private String makeTitle(String text) {
        String clean = text.replace('\n', ' ').trim();
        return clean.length() > 36 ? clean.substring(0, 36) + "…" : clean;
    }

    private void showModelPicker() {
        final String[] labels = {
                "Nexora 1.0\nFast · Legacy",
                "Nexora 1.1\nBalanced · mehr Kontext",
                "Nexora 1.5\nReasoning · stärkstes Profil"
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

        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        ImageView pb = new ImageView(this);
        pb.setImageResource(R.drawable.nexora_pb);
        pb.setScaleType(ImageView.ScaleType.CENTER_CROP);
        pb.setBackground(round(Color.BLACK, 17, LINE, 1));
        header.addView(pb, new LinearLayout.LayoutParams(dp(52), dp(52)));
        LinearLayout ht = new LinearLayout(this);
        ht.setOrientation(LinearLayout.VERTICAL);
        ht.setPadding(dp(12), 0, 0, 0);
        ht.addView(label("Dein Profil", 20, TEXT, true));
        ht.addView(label("Lokal gespeichert · für Personalisierung", 11, MUTED, false));
        header.addView(ht, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        box.addView(header);

        EditText name = field("Anzeigename", profileName());
        LinearLayout.LayoutParams nlp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        nlp.topMargin = dp(18);
        box.addView(name, nlp);

        EditText user = field("Username", profileUsername());
        LinearLayout.LayoutParams ulp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        ulp.topMargin = dp(10);
        box.addView(user, ulp);

        Button memory = secondaryButton("Memory bearbeiten");
        LinearLayout.LayoutParams mlp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        mlp.topMargin = dp(10);
        box.addView(memory, mlp);
        memory.setOnClickListener(v -> { dialog.dismiss(); showMemorySettings(); });

        Button save = actionButton("Profil speichern");
        LinearLayout.LayoutParams saveLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        saveLp.topMargin = dp(14);
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
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showMemorySettings() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();
        box.addView(label("Nexora Memory", 21, TEXT, true));
        TextView info = label("Schreib hier Dinge rein, die Nexora in neuen Antworten berücksichtigen soll. Diese Daten bleiben lokal und werden nur an deinen verbundenen Core gesendet.", 12, MUTED, false);
        info.setLineSpacing(0, 1.16f);
        LinearLayout.LayoutParams ilp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        ilp.topMargin = dp(6);
        ilp.bottomMargin = dp(14);
        box.addView(info, ilp);

        EditText memory = multiField("z. B. Projekte, Schreibstil, wichtige Präferenzen …", memoryText(), 1500);
        box.addView(memory, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(160)));

        Button save = actionButton("Memory speichern");
        LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        slp.topMargin = dp(13);
        box.addView(save, slp);
        save.setOnClickListener(v -> {
            prefs.edit().putString("memory_text", memory.getText().toString().trim()).apply();
            dialog.dismiss();
            Toast.makeText(this, "Memory gespeichert", Toast.LENGTH_SHORT).show();
        });

        dialog.setContentView(box);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showCoreSettings() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();
        box.addView(label("Nexora Core v" + NexoraCore.CORE_VERSION, 21, TEXT, true));
        TextView info = label("Der Core verwaltet Model-Routing, Memory, System-Prompt und bis zu 30 letzte Nachrichten Kontext. Für echte KI-Intelligenz braucht er einen kompatiblen Model-Server.", 12, MUTED, false);
        info.setLineSpacing(0, 1.16f);
        LinearLayout.LayoutParams infoLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        infoLp.topMargin = dp(6);
        infoLp.bottomMargin = dp(14);
        box.addView(info, infoLp);

        EditText endpoint = field("https://dein-server.de/chat", coreEndpoint());
        endpoint.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        box.addView(endpoint, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52)));

        EditText key = field("API-/Core-Key (optional)", coreApiKey());
        key.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        key.setTransformationMethod(PasswordTransformationMethod.getInstance());
        LinearLayout.LayoutParams klp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52));
        klp.topMargin = dp(9);
        box.addView(key, klp);

        EditText system = multiField("Custom Instructions für Nexora …", customInstruction(), 1000);
        LinearLayout.LayoutParams sysLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(110));
        sysLp.topMargin = dp(9);
        box.addView(system, sysLp);

        Button test = secondaryButton("Verbindung testen");
        LinearLayout.LayoutParams tlp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        tlp.topMargin = dp(10);
        box.addView(test, tlp);
        test.setOnClickListener(v -> {
            String e = endpoint.getText().toString().trim();
            if (e.isEmpty()) {
                Toast.makeText(this, "Noch kein Endpunkt eingetragen", Toast.LENGTH_SHORT).show();
                return;
            }
            Toast.makeText(this, "Wird beim nächsten Chat-Request geprüft", Toast.LENGTH_SHORT).show();
        });

        Button save = actionButton("Core speichern");
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        lp.topMargin = dp(10);
        box.addView(save, lp);
        save.setOnClickListener(v -> {
            prefs.edit()
                    .putString("core_endpoint", endpoint.getText().toString().trim())
                    .putString("core_api_key", key.getText().toString().trim())
                    .putString("custom_instruction", system.getText().toString().trim())
                    .apply();
            updateCoreStatus();
            render();
            dialog.dismiss();
        });

        dialog.setContentView(box);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void showMenu() {
        Dialog dialog = new Dialog(this);
        LinearLayout box = dialogBox();

        LinearLayout head = new LinearLayout(this);
        head.setOrientation(LinearLayout.HORIZONTAL);
        head.setGravity(Gravity.CENTER_VERTICAL);
        ImageView icon = new ImageView(this);
        icon.setImageResource(R.drawable.nexora_pb);
        icon.setScaleType(ImageView.ScaleType.CENTER_CROP);
        head.addView(icon, new LinearLayout.LayoutParams(dp(42), dp(42)));
        LinearLayout headText = new LinearLayout(this);
        headText.setOrientation(LinearLayout.VERTICAL);
        headText.setPadding(dp(10), 0, 0, 0);
        headText.addView(label("Nexora", 20, TEXT, true));
        headText.addView(label("v1.6 · Core " + NexoraCore.CORE_VERSION, 10, MUTED, false));
        head.addView(headText);
        box.addView(head);

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

        LinearLayout quick = new LinearLayout(this);
        quick.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams qlp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        qlp.topMargin = dp(8);
        box.addView(quick, qlp);

        Button profile = secondaryButton("Profil");
        Button memory = secondaryButton("Memory");
        Button core = secondaryButton("Core");
        quick.addView(profile, new LinearLayout.LayoutParams(0, dp(44), 1f));
        LinearLayout.LayoutParams memLp = new LinearLayout.LayoutParams(0, dp(44), 1f);
        memLp.leftMargin = dp(6);
        quick.addView(memory, memLp);
        LinearLayout.LayoutParams coreLp = new LinearLayout.LayoutParams(0, dp(44), 1f);
        coreLp.leftMargin = dp(6);
        quick.addView(core, coreLp);
        profile.setGravity(Gravity.CENTER);
        memory.setGravity(Gravity.CENTER);
        core.setGravity(Gravity.CENTER);
        profile.setOnClickListener(v -> { dialog.dismiss(); showProfile(); });
        memory.setOnClickListener(v -> { dialog.dismiss(); showMemorySettings(); });
        core.setOnClickListener(v -> { dialog.dismiss(); showCoreSettings(); });

        TextView historyTitle = label("CHATS", 10, Color.rgb(100, 100, 112), true);
        historyTitle.setPadding(dp(2), dp(18), 0, dp(7));
        box.addView(historyTitle);

        ScrollView sc = new ScrollView(this);
        LinearLayout list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        sc.addView(list);
        for (Chat c : chats) {
            Button b = secondaryButton((c.id.equals(activeId) ? "●  " : "") + c.title + "   · " + c.model);
            LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(42));
            blp.bottomMargin = dp(4);
            list.addView(b, blp);
            b.setOnClickListener(v -> {
                activeId = c.id;
                saveState();
                render();
                dialog.dismiss();
            });
        }
        box.addView(sc, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(190)));

        Button clear = secondaryButton("Aktuellen Chat löschen");
        clear.setTextColor(RED);
        LinearLayout.LayoutParams clp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(44));
        clp.topMargin = dp(8);
        box.addView(clear, clp);
        clear.setOnClickListener(v -> {
            deleteCurrentChat();
            dialog.dismiss();
        });

        dialog.setContentView(box);
        dialog.show();
        configureDialogWindow(dialog);
    }

    private void deleteCurrentChat() {
        Chat c = activeChat();
        if (c != null) chats.remove(c);
        if (chats.isEmpty()) createChat();
        else activeId = chats.get(0).id;
        saveState();
        render();
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
        boolean online = !coreEndpoint().isEmpty();
        coreStatus.setText(online ? "Core ✓" : "Core •");
        coreStatus.setTextColor(online ? GREEN : MUTED);
    }

    private void updateSendButton() {
        if (sendButton == null) return;
        if (busy) {
            sendButton.setText("■");
            sendButton.setTextSize(12);
            sendButton.setTextColor(Color.rgb(25, 25, 29));
            sendButton.setAlpha(1f);
            return;
        }
        sendButton.setText("↑");
        sendButton.setTextSize(19);
        boolean enabled = input != null && !input.getText().toString().trim().isEmpty();
        sendButton.setAlpha(enabled ? 1f : .42f);
    }

    private void copyText(String value) {
        ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (cm != null) cm.setPrimaryClip(ClipData.newPlainText("Nexora", value));
        Toast.makeText(this, "Kopiert", Toast.LENGTH_SHORT).show();
    }

    private String profileName() { return prefs.getString("profile_name", "Jason"); }
    private String profileUsername() { return prefs.getString("profile_username", "jason"); }
    private String coreEndpoint() { return prefs.getString("core_endpoint", "").trim(); }
    private String coreApiKey() { return prefs.getString("core_api_key", "").trim(); }
    private String memoryText() { return prefs.getString("memory_text", "").trim(); }
    private String customInstruction() { return prefs.getString("custom_instruction", "").trim(); }

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
        box.setBackground(round(Color.rgb(16, 16, 20), 22, LINE, 1));
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

    private EditText multiField(String hint, String value, int maxChars) {
        EditText e = new EditText(this);
        e.setHint(hint);
        e.setHintTextColor(Color.rgb(100, 100, 112));
        e.setText(value == null ? "" : value);
        e.setTextColor(TEXT);
        e.setTextSize(13);
        e.setGravity(Gravity.TOP | Gravity.START);
        e.setPadding(dp(13), dp(11), dp(13), dp(11));
        e.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        e.setMaxLines(8);
        e.setBackground(round(PANEL_2, 13, LINE, 1));
        e.addTextChangedListener(new TextWatcher() {
            boolean changing;
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) { }
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { }
            @Override public void afterTextChanged(Editable s) {
                if (changing || s.length() <= maxChars) return;
                changing = true;
                s.delete(maxChars, s.length());
                changing = false;
            }
        });
        return e;
    }

    private Button actionButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextSize(14);
        b.setTextColor(Color.rgb(18, 18, 22));
        b.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        b.setBackground(round(Color.rgb(237, 237, 241), 13, Color.TRANSPARENT, 0));
        return b;
    }

    private Button secondaryButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        b.setTextSize(12);
        b.setTextColor(TEXT);
        b.setPadding(dp(12), 0, dp(12), 0);
        b.setBackground(round(PANEL_2, 12, LINE, 1));
        return b;
    }

    private Button smallButton(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextSize(18);
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
