package com.jasontsk.projectcitadel;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.os.SystemClock;
import android.view.View;

/** Original in-engine village loading tableau; transitions only after real save loading completes. */
public final class LoadingController extends View {
    private final long started=SystemClock.uptimeMillis();
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path crest=new Path();
    private final RectF rect=new RectF();
    private final CameraController camera=new CameraController();
    private final VillageRenderer renderer;
    private Runnable onReady;
    private boolean completed;
    private final String[] status={"Restoring Village…","Preparing Builders…","Gathering Resources…","Raising Defenses…"};
    private final String[] tips={"Upgrade your Town Hall to unlock new buildings.","Keep your builders busy to progress faster.","Walls can use Elixir from Wall Level 3."};
    private final int tip;
    public LoadingController(Context context){
        super(context);tip=(int)((System.currentTimeMillis()/1000)%tips.length);
        GameState scene=GameState.fresh(System.currentTimeMillis());
        scene.townHall().level=4;
        scene.buildings.add(new BuildingInstance("archer",3,16,15));
        scene.buildings.add(new BuildingInstance("cannon",2,23,15));
        scene.buildings.add(new BuildingInstance("elixirmine",2,23,23));
        scene.buildings.add(new BuildingInstance("elixirstorage",2,13,23));
        scene.buildings.add(new BuildingInstance("builderhut",1,16,27));
        scene.revision++;
        renderer=new VillageRenderer(scene,camera);
        setContentDescription("Crownforge V0.2 loading village");
    }
    public void ready(Runnable callback){onReady=callback;invalidate();}
    @Override protected void onSizeChanged(int w,int h,int oldw,int oldh){camera.resize(w,h);camera.home();}
    @Override protected void onDraw(Canvas c){
        float elapsed=SystemClock.uptimeMillis()-started;
        int w=getWidth(),h=getHeight();
        renderer.draw(c,w,h,System.currentTimeMillis(),null,null,false);
        p.setShader(new LinearGradient(0,0,0,h,new int[]{0xFF0C202B,0xD00C202B,0x100C202B,0xF90C202B},new float[]{0,.24f,.60f,1},Shader.TileMode.CLAMP));
        c.drawRect(0,0,w,h,p);p.setShader(null);
        float s=w/420f;c.save();c.scale(s,s);float vh=h/s;
        float logoY=Math.min(195,vh*.24f);
        drawCrest(c,210,logoY-75,40);
        p.setTypeface(Typeface.create("serif",Typeface.BOLD));p.setTextAlign(Paint.Align.CENTER);p.setColor(0xFFFFDB91);p.setTextSize(38);
        c.drawText("CROWNFORGE",210,logoY,p);
        p.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));p.setTextSize(10);
        p.setColor(0xFFCED6C6);c.drawText("A KINGDOM OF YOUR MAKING",210,logoY+26,p);
        float progress=Math.min(onReady==null?.88f:1f,elapsed/2200f);
        float y=vh-158;
        p.setTextSize(14);p.setColor(0xFFF1DCA7);c.drawText(status[Math.min(3,(int)(progress*4))],210,y,p);
        rect.set(38,y+18,382,y+30);p.setColor(0xFF071A22);c.drawRoundRect(rect,6,6,p);
        if(progress>0){rect.set(41,y+21,41+338*progress,y+27);p.setColor(0xFFEAC477);c.drawRoundRect(rect,3,3,p);}
        p.setTextSize(11);p.setColor(0xFFB9CDC9);c.drawText(tips[tip],210,y+63,p);
        p.setTextSize(10);p.setColor(0xFF79989B);c.drawText("Crownforge V0.2  ·  Home Village",210,vh-35,p);
        if(elapsed<550){
            float alpha=elapsed<260?1f:Math.max(0,(550-elapsed)/290f);
            p.setColor(((int)(alpha*255)<<24)|0x0C202B);c.drawRect(0,0,420,vh,p);
            if(alpha>.7f){drawCrest(c,210,vh*.43f,64);p.setColor(0xFFFFDB91);p.setTextSize(28);p.setTypeface(Typeface.create("serif",Typeface.BOLD));c.drawText("CROWNFORGE",210,vh*.43f+106,p);}
        }
        c.restore();
        if(progress>=1 && onReady!=null && !completed){completed=true;post(onReady);}else if(!completed)postInvalidateOnAnimation();
    }
    private void drawCrest(Canvas c,float x,float y,float size){
        crest.reset();crest.moveTo(x-size,y-size*.72f);crest.lineTo(x,y-size);crest.lineTo(x+size,y-size*.72f);crest.lineTo(x+size*.78f,y+size*.52f);crest.lineTo(x,y+size);crest.lineTo(x-size*.78f,y+size*.52f);crest.close();
        p.setStyle(Paint.Style.FILL);p.setColor(0xFF29444C);c.drawPath(crest,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(0xFFCAA25C);c.drawPath(crest,p);p.setStyle(Paint.Style.FILL);
        p.setColor(0xFFE6C77E);c.drawRect(x-size*.55f,y-size*.27f,x+size*.55f,y+size*.48f,p);
        c.drawRect(x-size*.66f,y-size*.55f,x-size*.28f,y+size*.40f,p);c.drawRect(x+size*.28f,y-size*.55f,x+size*.66f,y+size*.40f,p);
        c.drawRect(x-size*.17f,y-size*.68f,x+size*.17f,y+size*.25f,p);
        p.setColor(0xFF122E39);rect.set(x-size*.14f,y+size*.02f,x+size*.14f,y+size*.54f);c.drawRoundRect(rect,size*.15f,size*.15f,p);
    }
}
