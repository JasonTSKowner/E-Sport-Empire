package com.jasontsk.projectcitadel;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Random;

/** Cached terrain, depth-sorted original structures, and transient world feedback. */
public final class VillageRenderer {
    private static final float TERRAIN_LEFT = -1440, TERRAIN_TOP = -160;
    private static final Comparator<BuildingInstance> DEPTH = (a,b) -> {
        int z = Integer.compare(a.x + a.y + a.definition().size,
                b.x + b.y + b.definition().size);
        if (z != 0) return z;
        z = Integer.compare(a.x - a.y, b.x - b.y);
        return z != 0 ? z : a.id.compareTo(b.id);
    };
    private final GameState state;
    private final CameraController camera;
    private final WallConnectionManager walls;
    private final BuildingArt art = new BuildingArt();
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private final Paint text = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path shape = new Path();
    private final RectF destination = new RectF();
    private final ArrayList<BuildingInstance> sorted = new ArrayList<>();
    private Bitmap terrain;
    private int revision = Integer.MIN_VALUE, count = -1;
    private int screenWidth, screenHeight;
    private LinearGradient backdrop;

    public VillageRenderer(GameState state, CameraController camera) {
        this.state = state; this.camera = camera;
        walls = new WallConnectionManager(state);
        text.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        text.setTextAlign(Paint.Align.CENTER);
        text.setTextSize(12);
    }

    private void refresh() {
        if (revision == state.revision && count == state.buildings.size()) return;
        sorted.clear(); sorted.addAll(state.buildings); Collections.sort(sorted, DEPTH);
        revision = state.revision; count = state.buildings.size();
        // Warm changed visuals outside the render loop. Repeated get calls are cache lookups.
        for (BuildingInstance b : sorted) art.get(b, walls.mask(b));
    }

    public void draw(Canvas c, int width, int height, long now,
            BuildingInstance selected, BuildingInstance preview, boolean valid) {
        if (terrain == null) terrain = createTerrain();
        if (width != screenWidth || height != screenHeight || backdrop == null) {
            screenWidth = width; screenHeight = height;
            backdrop = new LinearGradient(0,0,width,height,0xff163f43,0xff416951,Shader.TileMode.CLAMP);
        }
        paint.setShader(backdrop); paint.setAlpha(255); c.drawRect(0,0,width,height,paint); paint.setShader(null);
        refresh();
        c.save(); c.translate(camera.x,camera.y); c.scale(camera.zoom,camera.zoom);
        c.drawBitmap(terrain,TERRAIN_LEFT,TERRAIN_TOP,paint);
        if (selected != null && preview == null) footprint(c,selected,0x354fdfce,0xffb8efc3,false);
        if (preview != null) {
            placementGrid(c,preview);
            footprint(c,preview,valid?0x605bd3a0:0x70df6564,valid?0xffa6f6c0:0xffffa29a,true);
        }
        boolean previewDrawn = false;
        for (BuildingInstance b : sorted) {
            // A moving object gets a faint footprint at the committed position.
            if (preview != null && preview.id.equals(b.id)) {
                footprint(c,b,0x1fffffff,0x70fff2c8,false);
                continue;
            }
            if (preview != null && !previewDrawn && DEPTH.compare(preview,b) < 0) {
                drawStructure(c,preview,valid?220:150); previewDrawn = true;
            }
            drawStructure(c,b,b.isConstructing()?175:255);
            if (b.isBusy()) construction(c,b,now);
        }
        if (preview != null && !previewDrawn) drawStructure(c,preview,valid?220:150);
        if (selected != null && preview == null) selectionLabel(c,selected);
        if (preview != null) placementPin(c,preview,valid);
        c.restore();
    }

    public BuildingInstance hit(float worldX, float worldY) {
        refresh();
        // Reverse painter order means a visible foreground roof wins over a hidden rear tile.
        for (int i=sorted.size()-1;i>=0;i--) {
            BuildingInstance b=sorted.get(i);
            BuildingArt.Sprite sprite=art.get(b,walls.mask(b));
            float size=b.definition().size;
            float ax=VillageGrid.worldX(b.x+size*.5f,b.y+size*.5f);
            float ay=VillageGrid.worldY(b.x+size*.5f,b.y+size*.5f);
            if (sprite.contains(worldX-ax,worldY-ay)) return b;
        }
        return null;
    }

    /** Shared art for shop cards and the original launch illustration. */
    public void drawBuildingPreview(Canvas c, BuildingInstance b, float cx, float cy, float scale) {
        BuildingArt.Sprite sprite=art.get(b,0);
        c.save();c.translate(cx,cy);c.scale(scale,scale);
        destination.set(sprite.left,sprite.top,sprite.left+sprite.width,sprite.top+sprite.height);
        paint.setAlpha(255);c.drawBitmap(sprite.bitmap,null,destination,paint);c.restore();
    }

    private void drawStructure(Canvas c,BuildingInstance b,int alpha) {
        BuildingArt.Sprite sprite=art.get(b,walls.mask(b));
        float size=b.definition().size;
        float ax=VillageGrid.worldX(b.x+size*.5f,b.y+size*.5f);
        float ay=VillageGrid.worldY(b.x+size*.5f,b.y+size*.5f);
        // Offscreen structures do not issue bitmap draw calls.
        float left=(ax+sprite.left)*camera.zoom+camera.x;
        float top=(ay+sprite.top)*camera.zoom+camera.y;
        if(left>screenWidth || left+sprite.width*camera.zoom<0
                || top>screenHeight || top+sprite.height*camera.zoom<0)return;
        destination.set(ax+sprite.left,ay+sprite.top,ax+sprite.left+sprite.width,ay+sprite.top+sprite.height);
        paint.setAlpha(alpha);c.drawBitmap(sprite.bitmap,null,destination,paint);paint.setAlpha(255);
    }

    private void footprint(Canvas c,BuildingInstance b,int fill,int stroke,boolean tiles) {
        int size=b.definition().size;
        if(tiles) {
            for(int gx=b.x;gx<b.x+size;gx++)for(int gy=b.y;gy<b.y+size;gy++) {
                tile(c,gx,gy,1,fill,0x4479c8a0,1);
            }
        } else tile(c,b.x,b.y,size,fill,0,0);
        tile(c,b.x,b.y,size,0,stroke,2.2f);
    }

    private void placementGrid(Canvas c,BuildingInstance b) {
        // The local lattice exists only during placement; border tint shows blocked terrain.
        int size=b.definition().size;
        int minX=Math.max(0,b.x-3),maxX=Math.min(VillageGrid.SIZE,b.x+size+3);
        int minY=Math.max(0,b.y-3),maxY=Math.min(VillageGrid.SIZE,b.y+size+3);
        for(int gx=minX;gx<maxX;gx++)for(int gy=minY;gy<maxY;gy++) {
            boolean blocked=gx<2||gy<2||gx>=38||gy>=38;
            tile(c,gx,gy,1,blocked?0x35e78166:0x0affffff,blocked?0x50eea185:0x3874c992,.8f);
        }
    }

    private void tile(Canvas c,float gx,float gy,float size,int fill,int stroke,float width) {
        shape.reset();
        shape.moveTo(VillageGrid.worldX(gx,gy),VillageGrid.worldY(gx,gy));
        shape.lineTo(VillageGrid.worldX(gx+size,gy),VillageGrid.worldY(gx+size,gy));
        shape.lineTo(VillageGrid.worldX(gx+size,gy+size),VillageGrid.worldY(gx+size,gy+size));
        shape.lineTo(VillageGrid.worldX(gx,gy+size),VillageGrid.worldY(gx,gy+size));shape.close();
        if(fill!=0){paint.setColor(fill);paint.setStyle(Paint.Style.FILL);c.drawPath(shape,paint);}
        if(stroke!=0){paint.setColor(stroke);paint.setStyle(Paint.Style.STROKE);paint.setStrokeWidth(width);c.drawPath(shape,paint);paint.setStyle(Paint.Style.FILL);}
    }

    private void selectionLabel(Canvas c,BuildingInstance b) {
        float size=b.definition().size;
        float x=VillageGrid.worldX(b.x+size*.5f,b.y+size*.5f);
        float y=VillageGrid.worldY(b.x+size*.5f,b.y+size*.5f)+size*16+22;
        String label=b.definition().name+"  ·  "+(b.level==0?"Building":"Lv "+b.level);
        text.setTextSize(12);float half=text.measureText(label)*.5f+13;
        paint.setColor(0xee173c3d);c.drawRoundRect(x-half,y-13,x+half,y+9,8,8,paint);
        text.setColor(0xfff1e8c9);c.drawText(label,x,y+2,text);
    }

    private void placementPin(Canvas c,BuildingInstance b,boolean valid) {
        float size=b.definition().size;
        float x=VillageGrid.worldX(b.x+size*.5f,b.y+size*.5f);
        float y=VillageGrid.worldY(b.x+size*.5f,b.y+size*.5f)+size*16+23;
        paint.setColor(valid?0xe52c6f53:0xe5974f47);c.drawRoundRect(x-58,y-12,x+58,y+11,10,10,paint);
        text.setTextSize(11);text.setColor(0xfff9f4d9);c.drawText(valid?"READY TO PLACE":"SPACE BLOCKED",x,y+3,text);
    }

    private void construction(Canvas c,BuildingInstance b,long now) {
        float size=b.definition().size;
        float x=VillageGrid.worldX(b.x+size*.5f,b.y+size*.5f);
        float y=VillageGrid.worldY(b.x+size*.5f,b.y+size*.5f);
        float edge=size*25;
        paint.setStrokeWidth(4);paint.setColor(0xffa88755);
        c.drawLine(x-edge,y-9,x-edge,y-50,paint);c.drawLine(x,y+edge*.5f-9,x,y+edge*.5f-50,paint);
        c.drawLine(x-edge,y-41,x,y+edge*.5f-41,paint);
        paint.setStrokeWidth(2);paint.setColor(0xffdac082);
        c.drawLine(x-edge,y-43,x,y+edge*.5f-11,paint);
        float ratio=b.finishAt>b.startedAt?Math.max(0,Math.min(1,(now-b.startedAt)/(float)(b.finishAt-b.startedAt))):0;
        float py=y+size*16+12;
        paint.setColor(0xee1e4141);c.drawRoundRect(x-44,py-1,x+44,py+19,6,6,paint);
        paint.setColor(0xff577568);c.drawRoundRect(x-36,py+11,x+36,py+14,2,2,paint);
        paint.setColor(0xffedd08a);c.drawRoundRect(x-36,py+11,x-36+72*ratio,py+14,2,2,paint);
        long seconds=Math.max(0,(b.finishAt-now+999)/1000);
        text.setTextSize(10);text.setColor(0xfff4e5bb);
        c.drawText(seconds>=60?(seconds/60)+"m "+(seconds%60)+"s":seconds+"s",x,py+8,text);
    }

    private Bitmap createTerrain() {
        Bitmap bitmap=Bitmap.createBitmap(2880,1640,Bitmap.Config.RGB_565);
        Canvas c=new Canvas(bitmap);c.translate(-TERRAIN_LEFT,-TERRAIN_TOP);
        c.drawColor(0xff315a4b);
        Random random=new Random(71041);
        // Forest floor outside the island; muted flecks create depth without competing with play.
        for(int i=0;i<550;i++) {
            float x=-1440+random.nextFloat()*2880,y=-160+random.nextFloat()*1640;
            paint.setColor(i%2==0?0xff335f4a:0xff2d5446);
            c.drawOval(x-20,y-8,x+20,y+8,paint);
        }
        // Layered bevel makes the buildable clearing a substantial raised landscape.
        land(c,0,34,1310,655,0xff253f3d);land(c,0,24,1300,650,0xff536653);
        land(c,0,13,1290,645,0xff818363);land(c,0,5,1280,640,0xff759558);
        land(c,0,0,1280,640,0xff759955);
        shape.reset();shape.moveTo(0,0);shape.lineTo(1280,640);shape.lineTo(0,1280);shape.lineTo(-1280,640);shape.close();
        c.save();c.clipPath(shape);
        paint.setShader(new LinearGradient(-1100,100,1000,1200,0xff8cac63,0xff588247,Shader.TileMode.CLAMP));
        c.drawRect(-1280,0,1280,1280,paint);paint.setShader(null);
        // Broad softly varied grass patches, deliberately no permanent grid.
        int[] grass={0x187fab49,0x186c994d,0x1896b867,0x15759e50,0x12709744};
        for(int i=0;i<750;i++) {
            float gx=random.nextFloat()*40,gy=random.nextFloat()*40;
            float x=VillageGrid.worldX(gx,gy),y=VillageGrid.worldY(gx,gy),r=14+random.nextFloat()*42;
            paint.setColor(grass[i%grass.length]);c.drawOval(x-r,y-r*.4f,x+r,y+r*.4f,paint);
        }
        // A worn grassy arrival route belongs to the terrain, leaving placement unrestricted.
        paint.setColor(0x278f9b59);paint.setStrokeWidth(47);paint.setStrokeCap(Paint.Cap.ROUND);
        c.drawLine(-34,723,-248,838,paint);c.drawLine(-248,838,-668,1058,paint);
        for(int i=0;i<1750;i++) {
            float gx=random.nextFloat()*40,gy=random.nextFloat()*40;
            float x=VillageGrid.worldX(gx,gy),y=VillageGrid.worldY(gx,gy);
            paint.setColor(i%3==0?0x668aad55:0x4460803d);paint.setStrokeWidth(1);
            c.drawLine(x,y,x-2,y-3,paint);c.drawLine(x,y,x+2,y-4,paint);
            if(i%19==0){paint.setColor(0xffc4ba74);c.drawCircle(x+3,y,1.1f,paint);}
        }
        c.restore();
        // Shore stones and dense original conifers occupy the reserved two-tile perimeter.
        ArrayList<float[]> trees=new ArrayList<>();
        for(int side=0;side<4;side++)for(int i=0;i<48;i++) {
            float along=.25f+i*39.5f/47,across=.1f+random.nextFloat()*1.35f;
            float gx=side==0?along:side==1?40-across:side==2?40-along:across;
            float gy=side==0?across:side==1?along:side==2?40-across:40-along;
            trees.add(new float[]{VillageGrid.worldX(gx,gy),VillageGrid.worldY(gx,gy),.67f+random.nextFloat()*.62f,random.nextFloat()});
        }
        Collections.sort(trees,(a,b)->Float.compare(a[1],b[1]));
        for(float[] t:trees) {
            if(t[3]<.16f) rock(c,t[0],t[1],t[2]); else tree(c,t[0],t[1],t[2],t[3]>.68f);
        }
        // Foreground border details signal the clearing's real edge.
        for(int i=0;i<60;i++) {
            float along=2+random.nextFloat()*36;
            float gx=i%2==0?along:38.8f,gy=i%2==0?38.8f:along;
            rock(c,VillageGrid.worldX(gx,gy),VillageGrid.worldY(gx,gy),.18f+random.nextFloat()*.2f);
        }
        paint.setColor(Color.WHITE);paint.setAlpha(255);paint.setStyle(Paint.Style.FILL);
        return bitmap;
    }

    private void land(Canvas c,float x,float dy,float w,float h,int color) {
        shape.reset();shape.moveTo(x,dy);shape.lineTo(x+w,dy+h);shape.lineTo(x,dy+h*2);shape.lineTo(x-w,dy+h);shape.close();
        paint.setColor(color);c.drawPath(shape,paint);
    }

    private void tree(Canvas c,float x,float y,float scale,boolean broadleaf) {
        c.save();c.translate(x,y);c.scale(scale,scale);
        paint.setColor(0x39213d32);c.drawOval(-20,-1,39,13,paint);
        paint.setColor(0xff755f3c);c.drawRect(-4,-30,5,3,paint);
        if(broadleaf) {
            paint.setColor(0xff38683e);c.drawOval(-31,-67,27,-19,paint);
            paint.setColor(0xff527f43);c.drawOval(-32,-72,10,-31,paint);c.drawOval(-10,-80,25,-39,paint);
            paint.setColor(0xff749650);c.drawOval(-23,-75,1,-50,paint);c.drawOval(-2,-78,17,-61,paint);
        } else {
            tri(c,-31,-16,0,-63,33,-16,0xff2e6345);tri(c,-27,-34,0,-82,28,-34,0xff347849);
            tri(c,-22,-49,0,-103,23,-49,0xff438350);
            tri(c,-22,-49,0,-103,-4,-52,0xff65975c);tri(c,-27,-34,-8,-68,-5,-35,0xff518f51);
        }
        c.restore();
    }
    private void rock(Canvas c,float x,float y,float scale) {
        c.save();c.translate(x,y);c.scale(scale,scale);
        paint.setColor(0x3021372d);c.drawOval(-24,-4,29,11,paint);
        tri(c,-22,1,-13,-24,10,-4,0xff9da88b);tri(c,-13,-24,14,-20,10,-4,0xffb0b396);
        tri(c,14,-20,25,1,10,-4,0xff717f6e);tri(c,-22,1,10,-4,4,11,0xff7d8d76);
        tri(c,10,-4,25,1,4,11,0xff566f62);c.restore();
    }
    private void tri(Canvas c,float x1,float y1,float x2,float y2,float x3,float y3,int color) {
        shape.reset();shape.moveTo(x1,y1);shape.lineTo(x2,y2);shape.lineTo(x3,y3);shape.close();paint.setColor(color);c.drawPath(shape,paint);
    }
}
