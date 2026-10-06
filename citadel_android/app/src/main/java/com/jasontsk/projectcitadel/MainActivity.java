package com.jasontsk.projectcitadel;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {
    static class Building {
        String type;
        int level;
        long finishAt;
        int target;
        Building(String type, int level) { this.type = type; this.level = level; }
    }

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final List<Building> buildings = new ArrayList<>();
    private final List<String> logs = new ArrayList<>();
    private SharedPreferences prefs;
    private double gold = 1200, elixir = 600;
    private int playerLevel = 1, xp = 0, selected = -1;
    private long lastTick;

    private TextView goldText, elixirText, builderText, levelText, xpText, thText, logText;
    private ProgressBar xpBar;
    private Button thUpgrade;
    private GridLayout villageGrid, buildGrid;
    private LinearLayout selectionBox;

    @Override public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(12,16,23));
        getWindow().setNavigationBarColor(Color.rgb(10,14,20));
        prefs = getSharedPreferences("citadel_v01", MODE_PRIVATE);
        load();
        buildUi();
        refreshAll();
        handler.post(ticker);
    }

    @Override protected void onPause() { super.onPause(); save(); }
    @Override protected void onDestroy() { handler.removeCallbacksAndMessages(null); save(); super.onDestroy(); }

    private final Runnable ticker = new Runnable() {
        @Override public void run() {
            long now = System.currentTimeMillis();
            double dt = Math.min(3.0, (now - lastTick) / 1000.0);
            lastTick = now;
            completeUpgrades(now);
            double[] prod = production();
            int[] caps = capacities();
            gold = Math.min(caps[0], gold + prod[0] * dt);
            elixir = Math.min(caps[1], elixir + prod[1] * dt);
            refreshAll();
            handler.postDelayed(this, 1000);
        }
    };

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(10), dp(14), dp(10), dp(24));
        root.setBackgroundColor(Color.rgb(13,17,24));
        scroll.addView(root);

        LinearLayout top = row();
        top.setPadding(dp(8), dp(8), dp(8), dp(8));
        top.setBackground(card(20,27,37,18,38,50,68));
        goldText = resourceText(); elixirText = resourceText(); builderText = resourceText();
        top.addView(goldText, weight()); top.addView(elixirText, weight()); top.addView(builderText, weight());
        root.addView(top, matchWrap(0,8));

        LinearLayout profile = new LinearLayout(this);
        profile.setOrientation(LinearLayout.VERTICAL);
        profile.setPadding(dp(12),dp(10),dp(12),dp(10));
        profile.setBackground(card(20,27,37,18,38,50,68));
        levelText = text("Level 1", 16, Color.WHITE, true);
        xpText = text("0 / 100 XP", 12, Color.rgb(150,161,179), false);
        xpBar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        xpBar.setMax(1000);
        profile.addView(levelText); profile.addView(xpText, matchWrap(0,5)); profile.addView(xpBar, matchFixed(dp(10),7));
        root.addView(profile, matchWrap(0,8));

        LinearLayout thCard = new LinearLayout(this);
        thCard.setOrientation(LinearLayout.VERTICAL);
        thCard.setPadding(dp(12),dp(12),dp(12),dp(12));
        thCard.setBackground(card(20,27,37,20,38,50,68));
        thText = text("🏰 Rathaus Level 1", 21, Color.WHITE, true);
        thUpgrade = button("Rathaus verbessern");
        thUpgrade.setOnClickListener(v -> upgradeTownHall());
        thCard.addView(thText); thCard.addView(thUpgrade, matchWrap(0,9));
        root.addView(thCard, matchWrap(0,8));

        root.addView(section("DORF"));
        villageGrid = new GridLayout(this);
        villageGrid.setColumnCount(4);
        villageGrid.setPadding(dp(7),dp(7),dp(7),dp(7));
        villageGrid.setBackground(card(21,50,37,18,44,89,68));
        root.addView(villageGrid, matchWrap(0,8));

        root.addView(section("BAUEN"));
        buildGrid = new GridLayout(this);
        buildGrid.setColumnCount(2);
        root.addView(buildGrid, matchWrap(0,8));

        root.addView(section("AUSWAHL"));
        selectionBox = new LinearLayout(this);
        selectionBox.setOrientation(LinearLayout.VERTICAL);
        selectionBox.setPadding(dp(12),dp(12),dp(12),dp(12));
        selectionBox.setBackground(card(20,27,37,18,38,50,68));
        root.addView(selectionBox, matchWrap(0,8));

        root.addView(section("DORF-LOG"));
        logText = text("", 12, Color.rgb(189,200,216), false);
        logText.setPadding(dp(12),dp(10),dp(12),dp(10));
        logText.setBackground(card(20,27,37,16,38,50,68));
        root.addView(logText);

        Button reset = button("Spielstand zurücksetzen");
        reset.setOnClickListener(v -> {
            prefs.edit().clear().apply();
            buildings.clear(); logs.clear(); gold=1200; elixir=600; playerLevel=1; xp=0; selected=-1;
            seed(); addLog("Dorf neu gegründet."); save(); refreshAll();
        });
        root.addView(reset, matchWrap(0,12));
        setContentView(scroll);
    }

    private void refreshAll() {
        int[] caps = capacities();
        goldText.setText("🪙 " + (int)gold + " / " + caps[0]);
        elixirText.setText("💧 " + (int)elixir + " / " + caps[1]);
        builderText.setText("🔨 " + (totalBuilders()-busyBuilders()) + "/" + totalBuilders());
        levelText.setText("⭐ Spielerlevel " + playerLevel);
        int need=xpNeed(); xpText.setText(xp + " / " + need + " XP"); xpBar.setProgress((int)(1000.0*xp/need));
        Building th=townHall();
        thText.setText("🏰 Rathaus Level " + th.level);
        int c=upgradeGold(th);
        thUpgrade.setText(th.level>=5 ? "Rathaus Max" : "Upgrade • " + c + " Gold");
        thUpgrade.setEnabled(th.level<5 && th.finishAt==0 && busyBuilders()<totalBuilders() && gold>=c);
        refreshVillage(); refreshBuildMenu(); refreshSelection(); refreshLog();
    }

    private void refreshVillage() {
        villageGrid.removeAllViews();
        for (int i=0;i<buildings.size();i++) {
            final int idx=i; Building b=buildings.get(i);
            String label=icon(b.type)+"\n"+name(b.type)+"\nLvl "+b.level;
            if(b.finishAt>0) label += "\n⏱ "+timeLeft(b.finishAt);
            Button btn=button(label);
            btn.setTextSize(11); btn.setGravity(Gravity.CENTER);
            btn.setBackground(cardColorFor(b.type, idx==selected));
            btn.setOnClickListener(v->{selected=idx; refreshSelection(); refreshVillage();});
            GridLayout.LayoutParams gp=new GridLayout.LayoutParams();
            gp.width=0; gp.height=dp(92); gp.columnSpec=GridLayout.spec(GridLayout.UNDEFINED,1,1f); gp.setMargins(dp(3),dp(3),dp(3),dp(3));
            villageGrid.addView(btn,gp);
        }
    }

    private void refreshBuildMenu() {
        buildGrid.removeAllViews();
        String[] types={"goldmine","goldstorage","elixirmine","elixirstorage","cannon","archer","builderhut","wall"};
        int th=townHall().level;
        for(String type:types){
            int limit=limit(type,th); if(limit==0) continue;
            int count=count(type); int g=baseGold(type), e=baseElixir(type);
            Button b=button(icon(type)+" "+name(type)+"\n"+count+"/"+limit+" • "+g+" Gold"+(e>0?" + "+e+" Elixier":""));
            b.setTextSize(11); b.setEnabled(count<limit && busyBuilders()<totalBuilders() && gold>=g && elixir>=e);
            b.setOnClickListener(v->build(type));
            GridLayout.LayoutParams gp=new GridLayout.LayoutParams(); gp.width=0; gp.height=dp(76); gp.columnSpec=GridLayout.spec(GridLayout.UNDEFINED,1,1f); gp.setMargins(dp(3),dp(3),dp(3),dp(3));
            buildGrid.addView(b,gp);
        }
    }

    private void refreshSelection() {
        selectionBox.removeAllViews();
        if(selected<0 || selected>=buildings.size()) { selectionBox.addView(text("Tippe ein Gebäude oder eine Mauer an.",13,Color.rgb(150,161,179),false)); return; }
        Building b=buildings.get(selected);
        selectionBox.addView(text(icon(b.type)+" "+name(b.type),19,Color.WHITE,true));
        selectionBox.addView(text("Level "+b.level+" / "+maxLevel(b.type),12,Color.rgb(150,161,179),false));
        if(b.finishAt>0){ selectionBox.addView(text("Upgrade läuft: "+timeLeft(b.finishAt),14,Color.rgb(110,231,255),true),matchWrap(0,8)); return; }
        if(b.level>=maxLevel(b.type)){ selectionBox.addView(text("Maximalstufe erreicht.",14,Color.rgb(124,231,167),true),matchWrap(0,8)); return; }
        int g=upgradeGold(b); int e=upgradeElixir(b);
        Button goldBtn=button("Upgrade • "+g+" Gold"+(e>0 && !b.type.equals("wall")?" + "+e+" Elixier":""));
        goldBtn.setEnabled((b.type.equals("wall") || busyBuilders()<totalBuilders()) && gold>=g && (b.type.equals("wall") || elixir>=e));
        goldBtn.setOnClickListener(v->upgradeSelected(false)); selectionBox.addView(goldBtn,matchWrap(0,8));
        if(b.type.equals("wall") && b.level>=3){
            Button elixirBtn=button("Upgrade • "+g+" Elixier"); elixirBtn.setEnabled(elixir>=g); elixirBtn.setOnClickListener(v->upgradeSelected(true)); selectionBox.addView(elixirBtn,matchWrap(0,6));
        }
    }

    private void refreshLog(){
        StringBuilder s=new StringBuilder(); for(int i=0;i<Math.min(10,logs.size());i++) s.append("• ").append(logs.get(i)).append("\n"); logText.setText(s.toString());
    }

    private void build(String type){
        int th=townHall().level; if(count(type)>=limit(type,th)) return;
        int g=baseGold(type), e=baseElixir(type); if(gold<g || elixir<e) return;
        gold-=g; elixir-=e; Building b=new Building(type,1); buildings.add(b); selected=buildings.size()-1;
        addXp(Math.max(3,xpReward(type)/2)); addLog(name(type)+" gebaut."); save(); refreshAll();
    }

    private void upgradeTownHall(){ selected=buildings.indexOf(townHall()); upgradeSelected(false); }

    private void upgradeSelected(boolean payElixir){
        if(selected<0 || selected>=buildings.size()) return; Building b=buildings.get(selected); if(b.level>=maxLevel(b.type)) return;
        int g=upgradeGold(b), e=upgradeElixir(b);
        if(payElixir){ if(!b.type.equals("wall") || b.level<3 || elixir<g) return; elixir-=g; }
        else { if(gold<g || (!b.type.equals("wall") && elixir<e)) return; gold-=g; if(!b.type.equals("wall")) elixir-=e; }
        if(b.type.equals("wall")){
            b.level++; addXp(xpReward(b.type)*b.level); addLog(name(b.type)+" auf Level "+b.level+" verbessert.");
        } else {
            if(busyBuilders()>=totalBuilders()) return;
            b.target=b.level+1; b.finishAt=System.currentTimeMillis()+upgradeSeconds(b)*1000L; addLog(name(b.type)+"-Upgrade gestartet.");
        }
        save(); refreshAll();
    }

    private void completeUpgrades(long now){
        boolean changed=false;
        for(Building b:buildings){ if(b.finishAt>0 && now>=b.finishAt){ b.level=b.target; b.target=0; b.finishAt=0; addXp(xpReward(b.type)*b.level); addLog(name(b.type)+" Level "+b.level+" fertig."); changed=true; } }
        if(changed){ save(); Toast.makeText(this,"Upgrade abgeschlossen!",Toast.LENGTH_SHORT).show(); }
    }

    private int totalBuilders(){ return 2 + count("builderhut"); }
    private int busyBuilders(){ int n=0; long now=System.currentTimeMillis(); for(Building b:buildings) if(b.finishAt>now && !b.type.equals("wall")) n++; return n; }
    private Building townHall(){ for(Building b:buildings) if(b.type.equals("townhall")) return b; throw new IllegalStateException(); }
    private int count(String type){ int n=0; for(Building b:buildings) if(b.type.equals(type)) n++; return n; }

    private int[] capacities(){ int g=1500,e=1000; for(Building b:buildings){ if(b.type.equals("goldstorage"))g+=1200*b.level; if(b.type.equals("elixirstorage"))e+=1200*b.level; if(b.type.equals("townhall")){g+=500*b.level;e+=500*b.level;} } return new int[]{g,e}; }
    private double[] production(){ double g=0,e=0; for(Building b:buildings){ if(b.type.equals("goldmine"))g+=2.2*b.level; if(b.type.equals("elixirmine"))e+=1.8*b.level; } return new double[]{g,e}; }
    private int xpNeed(){ return 100+(playerLevel-1)*70; }
    private void addXp(int amount){ xp+=amount; while(xp>=xpNeed()){ xp-=xpNeed(); playerLevel++; addLog("Spielerlevel "+playerLevel+" erreicht."); } }
    private int upgradeGold(Building b){ return (int)Math.round(baseGold(b.type)*Math.pow(1.75,b.level-1)); }
    private int upgradeElixir(Building b){ return (int)Math.round(baseElixir(b.type)*Math.pow(1.75,b.level-1)); }
    private int upgradeSeconds(Building b){ return (int)Math.round(baseSeconds(b.type)*Math.pow(1.35,b.level-1)); }
    private String timeLeft(long end){ long sec=Math.max(0,(end-System.currentTimeMillis()+999)/1000); return sec>=60?(sec/60)+":"+String.format(Locale.US,"%02d",sec%60):sec+"s"; }

    private int limit(String type,int th){
        switch(th){
            case 1: if(type.equals("goldmine"))return 1;if(type.equals("goldstorage"))return 1;if(type.equals("wall"))return 10;break;
            case 2: if(type.equals("goldmine"))return 2;if(type.equals("goldstorage"))return 1;if(type.equals("elixirmine"))return 1;if(type.equals("elixirstorage"))return 1;if(type.equals("cannon"))return 1;if(type.equals("wall"))return 20;break;
            case 3: if(type.equals("goldmine"))return 2;if(type.equals("goldstorage"))return 2;if(type.equals("elixirmine"))return 2;if(type.equals("elixirstorage"))return 1;if(type.equals("cannon"))return 2;if(type.equals("archer"))return 1;if(type.equals("builderhut"))return 1;if(type.equals("wall"))return 30;break;
            case 4: if(type.equals("goldmine"))return 3;if(type.equals("goldstorage"))return 2;if(type.equals("elixirmine"))return 3;if(type.equals("elixirstorage"))return 2;if(type.equals("cannon"))return 2;if(type.equals("archer"))return 2;if(type.equals("builderhut"))return 1;if(type.equals("wall"))return 40;break;
            default: if(type.equals("goldmine"))return 3;if(type.equals("goldstorage"))return 3;if(type.equals("elixirmine"))return 3;if(type.equals("elixirstorage"))return 3;if(type.equals("cannon"))return 3;if(type.equals("archer"))return 2;if(type.equals("builderhut"))return 1;if(type.equals("wall"))return 50;
        } return 0;
    }

    private int baseGold(String t){ switch(t){case"townhall":return 500;case"goldmine":return 150;case"elixirmine":return 300;case"goldstorage":return 250;case"elixirstorage":return 400;case"cannon":return 350;case"archer":return 700;case"builderhut":return 1000;case"wall":return 50;}return 0; }
    private int baseElixir(String t){ return t.equals("builderhut")?500:0; }
    private int baseSeconds(String t){ switch(t){case"townhall":return 12;case"goldmine":return 8;case"elixirmine":return 10;case"goldstorage":return 9;case"elixirstorage":return 11;case"cannon":return 12;case"archer":return 16;case"builderhut":return 20;default:return 0;} }
    private int xpReward(String t){ switch(t){case"townhall":return 80;case"goldmine":return 20;case"elixirmine":return 25;case"goldstorage":return 24;case"elixirstorage":return 28;case"cannon":return 30;case"archer":return 42;case"builderhut":return 50;case"wall":return 5;}return 1; }
    private int maxLevel(String t){ return t.equals("builderhut")?1:(t.equals("townhall")?5:8); }
    private String name(String t){ switch(t){case"townhall":return"Rathaus";case"goldmine":return"Goldmine";case"elixirmine":return"Elixiersammler";case"goldstorage":return"Goldlager";case"elixirstorage":return"Elixierlager";case"cannon":return"Kanone";case"archer":return"Bogenturm";case"builderhut":return"Bauhütte";case"wall":return"Mauer";}return t; }
    private String icon(String t){ switch(t){case"townhall":return"🏰";case"goldmine":return"⛏️";case"elixirmine":return"⚗️";case"goldstorage":return"🪙";case"elixirstorage":return"🧪";case"cannon":return"💣";case"archer":return"🏹";case"builderhut":return"🛖";case"wall":return"🧱";}return"•"; }

    private void seed(){ buildings.add(new Building("townhall",1)); buildings.add(new Building("goldmine",1)); buildings.add(new Building("goldstorage",1)); for(int i=0;i<6;i++)buildings.add(new Building("wall",1)); }
    private void addLog(String s){ logs.add(0,s); while(logs.size()>25)logs.remove(logs.size()-1); }

    private void save(){
        StringBuilder b=new StringBuilder(); for(Building x:buildings)b.append(x.type).append(',').append(x.level).append(',').append(x.finishAt).append(',').append(x.target).append(';');
        StringBuilder l=new StringBuilder(); for(String s:logs)l.append(s.replace("~"," ")).append('~');
        prefs.edit().putString("gold",Double.toString(gold)).putString("elixir",Double.toString(elixir)).putInt("playerLevel",playerLevel).putInt("xp",xp).putString("buildings",b.toString()).putString("logs",l.toString()).apply();
    }
    private void load(){
        buildings.clear(); logs.clear();
        try{gold=Double.parseDouble(prefs.getString("gold","1200")); elixir=Double.parseDouble(prefs.getString("elixir","600"));}catch(Exception ignored){}
        playerLevel=prefs.getInt("playerLevel",1); xp=prefs.getInt("xp",0);
        String raw=prefs.getString("buildings","");
        if(raw.isEmpty()) seed(); else for(String part:raw.split(";")){ if(part.isEmpty())continue; String[] q=part.split(","); if(q.length>=4){ Building x=new Building(q[0],Integer.parseInt(q[1])); x.finishAt=Long.parseLong(q[2]); x.target=Integer.parseInt(q[3]); buildings.add(x); } }
        String lr=prefs.getString("logs",""); if(!lr.isEmpty())for(String s:lr.split("~"))if(!s.isEmpty())logs.add(s); if(logs.isEmpty())addLog("Willkommen in Project Citadel V0.1.");
        lastTick=System.currentTimeMillis();
    }

    private TextView section(String s){ TextView t=text(s,12,Color.rgb(158,172,192),true); t.setPadding(dp(3),dp(10),0,dp(4)); return t; }
    private TextView resourceText(){ TextView t=text("",12,Color.WHITE,true); t.setGravity(Gravity.CENTER); return t; }
    private TextView text(String s,float size,int color,boolean bold){ TextView t=new TextView(this); t.setText(s); t.setTextSize(size); t.setTextColor(color); if(bold)t.setTypeface(null,android.graphics.Typeface.BOLD); return t; }
    private Button button(String s){ Button b=new Button(this); b.setText(s); b.setAllCaps(false); b.setTextColor(Color.WHITE); b.setTextSize(13); b.setPadding(dp(8),dp(7),dp(8),dp(7)); b.setBackground(card(17,25,36,12,38,50,68)); return b; }
    private LinearLayout row(){ LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.HORIZONTAL); l.setGravity(Gravity.CENTER_VERTICAL); return l; }
    private LinearLayout.LayoutParams weight(){ return new LinearLayout.LayoutParams(0,LinearLayout.LayoutParams.WRAP_CONTENT,1f); }
    private LinearLayout.LayoutParams matchWrap(int top,int bottom){ LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,LinearLayout.LayoutParams.WRAP_CONTENT); p.topMargin=dp(top);p.bottomMargin=dp(bottom);return p; }
    private LinearLayout.LayoutParams matchFixed(int h,int top){ LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,h);p.topMargin=dp(top);return p; }
    private GradientDrawable card(int r,int g,int b,int radius,int sr,int sg,int sb){ GradientDrawable d=new GradientDrawable(); d.setColor(Color.rgb(r,g,b)); d.setCornerRadius(dp(radius)); d.setStroke(dp(1),Color.rgb(sr,sg,sb)); return d; }
    private GradientDrawable cardColorFor(String type,boolean selected){ int r=25,g=35,b=48; if(type.equals("townhall")){r=111;g=60;b=49;}else if(type.equals("wall")){r=60;g=66;b=78;}else if(type.contains("elixir")){r=72;g=42;b=92;}else if(type.contains("gold")){r=84;g=65;b=24;}else if(type.equals("cannon")||type.equals("archer")){r=48;g=59;b=65;} GradientDrawable d=card(r,g,b,12,selected?110:70,selected?231:82,selected?255:100); return d; }
    private int dp(int v){ return (int)(v*getResources().getDisplayMetrics().density+0.5f); }
}
