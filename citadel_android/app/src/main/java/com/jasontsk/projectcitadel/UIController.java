package com.jasontsk.projectcitadel;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Typeface;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** Game-styled HUD and contextual sheets, drawn independently from world coordinates. */
public final class UIController {
    public enum Panel { NONE,SHOP,INFO,UPGRADE,SETTINGS }
    public Panel panel=Panel.NONE;
    public String notice="";
    public long noticeUntil;
    private final VillageView view;
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF rect=new RectF();
    private final Path path=new Path();
    private final List<Action> actions=new ArrayList<>();
    private String pressed;
    private float scale=1,height=840;
    private int category;
    private static final int INK=0xF21A2B32, EDGE=0xFF587078, GOLD=0xFFF3CB79, TEXT=0xFFF7F2DF, SOFT=0xFFB5C7C7, TEAL=0xFF73D5C5;
    private static final Typeface BOLD=Typeface.create("sans-serif-medium",Typeface.NORMAL);
    private static final Typeface NORMAL=Typeface.create("sans-serif",Typeface.NORMAL);
    private static final class Action { String id;RectF area;Runnable run;Action(String id,RectF area,Runnable run){this.id=id;this.area=area;this.run=run;} }
    public UIController(VillageView view){this.view=view;}
    public void draw(Canvas c,int w,int h,long now){
        scale=w/420f;height=h/scale;actions.clear();c.save();c.scale(scale,scale);
        hud(c);footer(c,now);
        if(panel!=Panel.NONE){actions.clear();p.setColor(0x95081219);c.drawRect(0,0,420,height,p);sheet(c,now);}
        if(now<noticeUntil && notice!=null && !notice.isEmpty()){
            float y=panel==Panel.NONE?132:height-78;
            box(c,22,y,398,y+54,12,0xF022363B,EDGE);wrap(c,notice,210,y+20,13,TEXT,358,2,true);
        }
        c.restore();
    }
    private void hud(Canvas c){
        box(c,12,14,156,78,14,INK,EDGE);
        crest(c,39,44,22,TEAL);text(c,""+view.state.playerLevel,39,49,20,TEXT,true,true);
        text(c,"COMMANDER",69,33,10,GOLD,true,false);
        text(c,view.state.xp+" / "+view.state.xpNeeded()+" XP",69,52,11,TEXT,false,false);
        bar(c,69,62,144,67,view.state.xp/(float)view.state.xpNeeded(),TEAL);
        resource(c,168,14,408,54,"GOLD",view.state.gold,view.manager.resources.goldCapacity(),GOLD);
        resource(c,168,62,408,102,"ELIXIR",view.state.elixir,view.manager.resources.elixirCapacity(),0xFFDFA4FA);
        box(c,12,86,156,119,10,INK,EDGE);
        text(c,"BUILDERS",24,107,10,SOFT,true,false);
        text(c,view.manager.builders.free()+" / "+view.manager.builders.total(),141,108,15,TEXT,true,true);
        actions.add(new Action("builders",new RectF(12,86,156,119),()->view.notifyUser("Builders: "+view.manager.builders.free()+" free. Completed Builder Huts add one builder each.")));
    }
    private void resource(Canvas c,float l,float t,float r,float b,String label,double amount,int cap,int color){
        box(c,l,t,r,b,12,INK,EDGE);p.setColor(color);c.drawCircle(l+18,t+17,8,p);
        p.setColor(0x5525373A);c.drawCircle(l+16,t+15,3,p);
        text(c,label,l+34,t+14,9,color,true,false);
        text(c,number((long)amount)+" / "+number(cap),r-12,t+27,14,TEXT,true,false,Paint.Align.RIGHT);
        bar(c,l+12,b-7,r-12,b-4,(float)(amount/cap),color);
    }
    private void footer(Canvas c,long now){
        if(view.placement.active()){
            BuildingInstance b=view.placement.preview;
            box(c,12,height-164,408,height-12,18,INK,EDGE);
            text(c,view.placement.movingId==null?"PLACE "+b.definition().name.toUpperCase(Locale.US):"MOVE "+b.definition().name.toUpperCase(Locale.US),26,height-137,16,GOLD,true,false);
            text(c,view.placement.valid()?"Clear ground. Ready to confirm.":"Blocked. Choose clear grass.",26,height-113,13,view.placement.valid()?TEAL:0xFFF5A89C,false,false);
            text(c,"Drag to position · Pinch to explore",26,height-91,11,SOFT,false,false);
            button(c,"cancel-place","Cancel",26,height-70,184,height-26,false,()->view.cancelPlacement());
            button(c,"confirm-place","Confirm",196,height-70,394,height-26,true,()->view.confirmPlacement());
            return;
        }
        if(view.selected!=null){
            BuildingInstance b=view.selected;
            box(c,12,height-190,408,height-78,17,INK,EDGE);
            text(c,b.definition().name,26,height-164,20,TEXT,true,false);
            text(c,"LEVEL "+Math.max(1,b.level),393,height-166,11,GOLD,true,false,Paint.Align.RIGHT);
            if(b.isBusy()){
                long span=Math.max(1,b.finishAt-b.startedAt);
                text(c,(b.isConstructing()?"Building":"Upgrading to level "+b.targetLevel)+" · "+duration(b.finishAt-now),26,height-144,12,TEAL,false,false);
                bar(c,26,height-133,394,height-129,1f-(b.finishAt-now)/(float)span,TEAL);
            } else text(c,b.type.equals("townhall")?"The heart of your growing kingdom":b.definition().production(Math.max(1,b.level))>0?"Producing "+number(b.definition().production(b.level))+" per hour":"Tap an action to shape your village",26,height-143,12,SOFT,false,false);
            boolean wall=b.type.equals("wall");float bw=wall?84:114;
            button(c,"info","Info",26,height-122,26+bw,height-88,false,()->{panel=Panel.INFO;view.invalidate();});
            button(c,"move","Move",34+bw,height-122,34+bw*2,height-88,false,()->view.beginMove());
            button(c,"upgrade","Upgrade",42+bw*2,height-122,42+bw*3,height-88,true,()->{panel=Panel.UPGRADE;view.invalidate();});
            if(wall)button(c,"extend","+1",318,height-122,394,height-88,false,()->{
                BuildingInstance source=view.selected;view.beginBuild("wall");
                int[][] offsets={{1,0},{0,1},{-1,0},{0,-1}};
                for(int[] o:offsets)if(view.manager.grid.canPlace("wall",source.x+o[0],source.y+o[1],null)){view.placement.preview.x=source.x+o[0];view.placement.preview.y=source.y+o[1];break;}
            });
        } else {
            text(c,"CROWNFORGE",22,height-85,11,TEXT,true,false);
            text(c,"Your kingdom begins here",22,height-68,11,0xFFD6E5CB,false,false);
        }
        button(c,"settings","Settings",12,height-58,114,height-12,false,()->{panel=Panel.SETTINGS;view.invalidate();});
        button(c,"home","Home",124,height-58,228,height-12,false,()->{view.camera.home();view.invalidate();});
        button(c,"shop","BUILD",240,height-64,408,height-12,true,()->{panel=Panel.SHOP;view.selected=null;view.invalidate();});
    }
    private void sheet(Canvas c,long now){
        float top=Math.max(136,height*.20f),bottom=height-94;
        if(panel==Panel.SHOP){shop(c,Math.max(132,height*.15f),bottom);return;}
        top=Math.max(20,Math.min(top,Math.min(height-496,bottom-444)));
        box(c,12,top,408,bottom,20,0xFF192D34,0xFF7D8E86);
        String title=panel==Panel.SETTINGS?"SETTINGS":panel==Panel.UPGRADE?"FORGE AHEAD":"BUILDING DETAILS";
        text(c,title,28,top+30,19,GOLD,true,false);
        button(c,"close","×",354,top+10,396,top+48,false,()->{panel=Panel.NONE;view.invalidate();});
        if(panel==Panel.SETTINGS){settings(c,top,bottom);return;}
        BuildingInstance b=view.selected;if(b==null){panel=Panel.NONE;return;}
        BuildingDefinition d=b.definition();int lv=Math.max(1,b.level),next=b.isBusy()?b.targetLevel:lv+1;
        boolean compare=panel==Panel.UPGRADE && (b.isBusy() || b.level<d.maxLevel(view.state.townHallLevel()));
        view.renderer.drawBuildingPreview(c,b,89,top+141,0.5f);
        text(c,d.name,170,top+83,20,TEXT,true,false);
        text(c,(b.isConstructing()?"Under construction":("Level "+lv))+(compare?"  →  "+next:""),170,top+109,15,TEAL,true,false);
        text(c,d.size+" × "+d.size+" tiles",170,top+134,12,SOFT,false,false);
        float y=top+176;
        stat(c,"Hit points",d.hp(b.level),d.hp(next),y,compare);y+=34;
        if(d.production(lv)>0){stat(c,"Production / hour",d.production(b.level),d.production(next),y,compare);y+=34;}
        if(d.capacity(lv)>0){stat(c,"Storage capacity",d.capacity(b.level),d.capacity(next),y,compare);y+=34;}
        if(d.damage(lv)>0){stat(c,"Defense damage",d.damage(b.level),d.damage(next),y,compare);y+=34;}
        if(b.type.equals("townhall")){text(c,"Unlocks structures, limits and upgrade levels",28,y,12,SOFT,false,false);y+=28;}
        if(panel==Panel.INFO){
            wrap(c,b.isBusy()?"Builder assigned · "+duration(b.finishAt-now)+" remaining":b.type.equals("wall")?"Walls connect with neighboring segments. Upgrades to level 3 and above accept Gold or Elixir.":"Buildings snap to your village tiles. Moving is free and can always be canceled.",28,y+14,13,SOFT,358,3,false);
            return;
        }
        if(b.isBusy()){
            text(c,"Builder at work · "+duration(b.finishAt-now),28,y+15,15,TEAL,true,false);
            bar(c,28,y+35,392,y+43,1f-(b.finishAt-now)/(float)Math.max(1,b.finishAt-b.startedAt),TEAL);return;
        }
        if(lv>=d.maxLevel(view.state.townHallLevel())){
            wrap(c,lv>=d.maxLevel(5)?"This structure has reached the V0.2 maximum.":"Level limit reached. Upgrade your Town Hall to unlock further improvements.",28,y+16,14,SOFT,356,3,false);return;
        }
        text(c,b.type.equals("wall")?"Instant upgrade · No builder needed":"Duration: "+duration(d.upgradeSeconds(lv)*1000L)+" · 1 builder",28,y+13,13,TEAL,false,false);
        boolean choice=b.type.equals("wall")&&next>=3;
        int gold=d.upgradeGold(lv),elixir=d.upgradeElixir(lv);
        float by=Math.max(y+32,bottom-(choice?120:72));
        button(c,"pay-gold",number(gold)+" Gold"+(elixir>0&&!b.type.equals("wall")?" + "+number(elixir)+" Elixir":""),28,by,392,by+44,true,()->view.upgrade(false));
        if(choice)button(c,"pay-elixir",number(gold)+" Elixir",28,by+53,392,by+97,false,()->view.upgrade(true));
    }
    private void shop(Canvas c,float top,float bottom){
        box(c,12,top,408,bottom,20,0xFF192D34,0xFF7D8E86);
        text(c,"BUILD YOUR KINGDOM",28,top+30,18,GOLD,true,false);
        button(c,"close","×",354,top+10,396,top+46,false,()->{panel=Panel.NONE;view.invalidate();});
        String[] cats={"Resources","Defense","Walls"};
        for(int i=0;i<3;i++){final int index=i;button(c,"category"+i,cats[i],26+i*124,top+56,142+i*124,top+92,category==i,()->{category=index;view.invalidate();});}
        List<BuildingDefinition> defs=new ArrayList<>();
        for(BuildingDefinition d:BuildingDefinition.all()){
            boolean resource=d.type.contains("gold")||d.type.contains("elixir")||d.type.equals("builderhut");
            if((category==0&&resource)||(category==1&&(d.type.equals("cannon")||d.type.equals("archer")))||(category==2&&d.type.equals("wall")))defs.add(d);
        }
        float cardH=Math.min(139,(bottom-top-112)/3f);
        for(int i=0;i<defs.size();i++){
            BuildingDefinition d=defs.get(i);float l=26+(i%2)*190,t=top+106+(i/2)*cardH;
            int count=0;for(BuildingInstance b:view.state.buildings)if(b.type.equals(d.type))count++;
            int limit=d.limit(view.state.townHallLevel());boolean locked=limit==0;
            box(c,l,t,l+178,t+cardH-9,12,locked?0xFF233A40:0xFF30464B,locked?0xFF41575C:0xFF74867A);
            view.renderer.drawBuildingPreview(c,new BuildingInstance(d.type,1,0,0),l+44,t+cardH*.48f,Math.min(.30f,cardH/380f));
            text(c,d.name,l+11,t+cardH-45,13,locked?SOFT:TEXT,true,false);
            text(c,locked?"Town Hall "+d.requiredTownHall():number(d.buildGold)+" Gold"+(d.buildElixir>0?" + "+number(d.buildElixir)+" E":""),l+11,t+cardH-27,11,locked?SOFT:GOLD,false,false);
            text(c,count+" / "+limit,l+164,t+20,11,SOFT,true,false,Paint.Align.RIGHT);
            final int current=count;
            actions.add(new Action("buy-"+d.type,new RectF(l,t,l+178,t+cardH-9),()->{
                if(locked)view.fail("Requires Town Hall level "+d.requiredTownHall()+".");
                else if(current>=limit)view.fail("Building limit reached. Upgrade your Town Hall.");
                else view.beginBuild(d.type);
            }));
        }
    }
    private void settings(Canvas c,float top,float bottom){
        text(c,"Make the village your own",28,top+66,13,SOFT,false,false);
        volume(c,"Master",view.state.masterVolume,top+96,0);
        volume(c,"Music & ambience",view.state.musicVolume,top+166,1);
        volume(c,"Sound effects",view.state.sfxVolume,top+236,2);
        button(c,"mute",view.state.muted?"Sound muted · Tap to unmute":"Sound enabled · Tap to mute",28,top+304,392,top+348,!view.state.muted,()->{view.state.muted=!view.state.muted;settingsChanged();});
        text(c,"Crownforge V0.2 · Home Village",28,bottom-49,13,GOLD,true,false);
        text(c,"Original art, code & synthesized sound",28,bottom-28,11,SOFT,false,false);
    }
    private void volume(Canvas c,String name,float value,float y,int kind){
        text(c,name,28,y,14,TEXT,true,false);
        for(int i=0;i<=4;i++){
            final float v=i/4f;final int k=kind;
            button(c,"volume"+kind+"-"+i,i*25+"%",28+i*74,y+12,94+i*74,y+45,Math.abs(value-v)<.12,()->{
                if(k==0)view.state.masterVolume=v;else if(k==1)view.state.musicVolume=v;else view.state.sfxVolume=v;settingsChanged();
            });
        }
    }
    private void settingsChanged(){if(view.host.audio!=null)view.host.audio.applySettings();view.changed();}
    private void stat(Canvas c,String name,int value,int next,float y,boolean compare){text(c,name,28,y,13,SOFT,false,false);text(c,number(value)+(compare?"  →  "+number(next):""),390,y,15,compare?TEAL:TEXT,true,false,Paint.Align.RIGHT);}
    private void button(Canvas c,String id,String label,float l,float t,float r,float b,boolean accent,Runnable run){
        boolean down=id.equals(pressed);int fill=accent?(down?0xFFB28D48:0xFFE4BC6A):(down?0xFF405B61:0xFF2B434B);
        box(c,l,t+3,r,b+3,10,0x88060F15,0);box(c,l,t,r,b,10,fill,accent?0xFFFFE3A5:0xFF6E888B);
        text(c,label,(l+r)/2,(t+b)/2+5,Math.min(14,(r-l)/Math.max(1,label.length())*1.6f),accent?0xFF253235:TEXT,true,true);
        actions.add(new Action(id,new RectF(l,t,r,b),run));
    }
    private void box(Canvas c,float l,float t,float r,float b,float radius,int fill,int stroke){rect.set(l,t,r,b);p.setStyle(Paint.Style.FILL);p.setColor(fill);c.drawRoundRect(rect,radius,radius,p);if(stroke!=0){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(stroke);c.drawRoundRect(rect,radius,radius,p);p.setStyle(Paint.Style.FILL);}}
    private void bar(Canvas c,float l,float t,float r,float b,float fraction,int color){box(c,l,t,r,b,(b-t)/2,0xFF0F242B,0);float f=Math.max(0,Math.min(1,fraction));if(f>0)box(c,l,t,l+(r-l)*f,b,(b-t)/2,color,0);}
    private void crest(Canvas c,float x,float y,float size,int color){path.reset();path.moveTo(x-size*.9f,y-size*.8f);path.lineTo(x,y-size);path.lineTo(x+size*.9f,y-size*.8f);path.lineTo(x+size*.7f,y+size*.55f);path.lineTo(x,y+size);path.lineTo(x-size*.7f,y+size*.55f);path.close();p.setColor(0xFF234E55);c.drawPath(path,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(color);c.drawPath(path,p);p.setStyle(Paint.Style.FILL);}
    private void text(Canvas c,String s,float x,float y,float size,int color,boolean bold,boolean center){text(c,s,x,y,size,color,bold,center,center?Paint.Align.CENTER:Paint.Align.LEFT);}
    private void text(Canvas c,String s,float x,float y,float size,int color,boolean bold,boolean center,Paint.Align align){p.setColor(color);p.setTextSize(size);p.setTypeface(bold?BOLD:NORMAL);p.setTextAlign(align);c.drawText(s,x,y,p);p.setTextAlign(Paint.Align.LEFT);}
    private void wrap(Canvas c,String s,float x,float y,float size,int color,float width,int maxLines,boolean center){
        p.setTextSize(size);p.setTypeface(NORMAL);StringBuilder line=new StringBuilder();int row=0;
        for(String word:s.split(" ")){String attempt=line.length()==0?word:line+" "+word;if(p.measureText(attempt)>width&&line.length()>0){text(c,line.toString(),x,y+row*18,size,color,false,center);if(++row>=maxLines)return;line.setLength(0);line.append(word);}else{line.setLength(0);line.append(attempt);}}
        if(row<maxLines)text(c,line.toString(),x,y+row*18,size,color,false,center);
    }
    public boolean press(float physicalX,float physicalY){
        float x=physicalX/scale,y=physicalY/scale;pressed=null;
        for(int i=actions.size()-1;i>=0;i--){Action a=actions.get(i);if(a.area.contains(x,y)){pressed=a.id;view.invalidate();return true;}}
        return panel!=Panel.NONE || y<125 || (view.placement.active()&&y>height-164) || (view.selected!=null&&y>height-190);
    }
    public void release(float physicalX,float physicalY){
        String id=pressed;pressed=null;if(id==null)return;
        float x=physicalX/scale,y=physicalY/scale;
        for(Action a:actions)if(a.id.equals(id)&&a.area.contains(x,y)){Runnable run=a.run;view.sound("button");run.run();break;}
        view.invalidate();
    }
    public void cancelPress(){pressed=null;view.invalidate();}
    public static String number(long value){return String.format(Locale.US,"%,d",value);}
    public static String duration(long millis){long seconds=Math.max(0,(millis+999)/1000);if(seconds>=3600)return seconds/3600+"h "+(seconds%3600)/60+"m";if(seconds>=60)return seconds/60+"m "+seconds%60+"s";return seconds+"s";}
}
