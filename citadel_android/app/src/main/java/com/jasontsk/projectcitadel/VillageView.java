package com.jasontsk.projectcitadel;
import android.graphics.Canvas;
import android.view.MotionEvent;
import android.view.View;

/** Redraw on gestures, actions and simulation ticks instead of rebuilding widgets. */
public final class VillageView extends View {
    public final MainActivity host;
    public final GameState state;
    public final BuildingManager manager;
    public final CameraController camera;
    public final VillageRenderer renderer;
    public final PlacementManager placement;
    public final UIController ui;
    public final TouchController touch;
    public BuildingInstance selected;
    public VillageView(MainActivity host,GameState state) {
        super(host);this.host=host;this.state=state;
        manager=new BuildingManager(state);camera=new CameraController();renderer=new VillageRenderer(state,camera);
        placement=new PlacementManager(manager);ui=new UIController(this);touch=new TouchController(this);
        setFocusable(true);setContentDescription("Crownforge village. Drag to pan, pinch to zoom, tap buildings to select.");
    }
    @Override protected void onSizeChanged(int w,int h,int oldw,int oldh){camera.resize(w,h);}
    @Override protected void onDraw(Canvas canvas){
        long now=System.currentTimeMillis();
        renderer.draw(canvas,getWidth(),getHeight(),now,selected,placement.preview,placement.valid());
        ui.draw(canvas,getWidth(),getHeight(),now);
    }
    @Override public boolean onTouchEvent(MotionEvent event){return touch.onTouch(event);}
    @Override public boolean performClick(){super.performClick();return true;}
    public void select(BuildingInstance b){selected=b;if(b!=null)sound("select");invalidate();}
    public void beginBuild(String type){placement.beginBuild(type);selected=null;ui.panel=UIController.Panel.NONE;sound("button");invalidate();}
    public void beginMove(){if(selected==null)return;placement.beginMove(selected);ui.panel=UIController.Panel.NONE;sound("button");invalidate();}
    public void confirmPlacement(){
        if(!placement.active())return;
        BuildingInstance p=placement.preview;String moving=placement.movingId;
        String error=placement.confirm(System.currentTimeMillis());
        if(error!=null){fail(error);return;}
        selected=moving==null?manager.grid.at(p.x,p.y):state.find(moving);
        sound("place");notifyUser(moving==null?(p.type.equals("wall")?"Wall placed. Extend your defenses with +1.":"Construction started. Your builder is on the way."):"Building moved.");changed();
    }
    public void cancelPlacement(){placement.cancel();sound("button");invalidate();}
    public void upgrade(boolean elixir){
        if(selected==null)return;int oldLevel=state.playerLevel;
        String error=manager.upgrade(selected.id,elixir,System.currentTimeMillis());
        if(error!=null){fail(error);return;}
        ui.panel=UIController.Panel.NONE;sound(state.playerLevel>oldLevel?"levelup":"upgrade");
        notifyUser(selected.type.equals("wall")?"Wall strengthened to level "+selected.level:"Upgrade started. Your builder is working.");changed();
    }
    public void changed(){host.persist();invalidate();}
    public void sound(String event){if(host.audio!=null)host.audio.play(event);}
    public void fail(String message){sound("error");notifyUser(message);}
    public void notifyUser(String message){ui.notice=message;ui.noticeUntil=System.currentTimeMillis()+4800;invalidate();}
    public boolean dismiss(){
        if(placement.active()){cancelPlacement();return true;}
        if(ui.panel!=UIController.Panel.NONE){ui.panel=UIController.Panel.NONE;invalidate();return true;}
        if(selected!=null){select(null);return true;}return false;
    }
}
