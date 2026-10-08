package com.jasontsk.projectcitadel;

/** A reversible preview transaction; committed buildings change only on confirmation. */
public final class PlacementManager {
    private final BuildingManager manager;
    public BuildingInstance preview;
    public String movingId;
    public PlacementManager(BuildingManager manager) { this.manager=manager; }
    public boolean active() { return preview!=null; }
    public void beginBuild(String type) {
        movingId=null; preview=new BuildingInstance(type,1,20,20);
        for(int radius=0;radius<36;radius++) {
            for(int x=20-radius;x<=20+radius;x++) for(int y=20-radius;y<=20+radius;y++) {
                if(manager.grid.canPlace(type,x,y,null)){preview.x=x;preview.y=y;return;}
            }
        }
    }
    public void beginMove(BuildingInstance b) { movingId=b.id;preview=new BuildingInstance(b.type,b.level,b.x,b.y);preview.id=b.id; }
    public void position(float gx,float gy) {
        if(!active())return;
        int size=preview.definition().size;
        preview.x=(int)Math.floor(gx-size/2f+0.5f);preview.y=(int)Math.floor(gy-size/2f+0.5f);
    }
    public boolean valid() { return active() && manager.grid.canPlace(preview.type,preview.x,preview.y,movingId); }
    public String confirm(long now) {
        if(!active())return "Choose a building first.";
        if(!valid())return "Choose clear grass inside the village boundary.";
        String error=movingId==null?manager.build(preview.type,preview.x,preview.y,now):manager.move(movingId,preview.x,preview.y);
        if(error==null)cancel();return error;
    }
    public void cancel() { preview=null;movingId=null; }
}
