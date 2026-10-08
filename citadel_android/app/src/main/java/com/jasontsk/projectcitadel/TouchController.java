package com.jasontsk.projectcitadel;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.ViewConfiguration;

/** Explicit states prevent building selection after camera gestures. */
public final class TouchController {
    public enum State { IDLE,PRESSED,PANNING,SCALING,PLACING,UI }
    public State state=State.IDLE;
    private final VillageView view;
    private final ScaleGestureDetector scale;
    private final float slop;
    private float downX,downY,lastX,lastY,focusX,focusY;
    private boolean multi;
    public TouchController(VillageView view){
        this.view=view;slop=ViewConfiguration.get(view.getContext()).getScaledTouchSlop();
        scale=new ScaleGestureDetector(view.getContext(),new ScaleGestureDetector.SimpleOnScaleGestureListener(){
            @Override public boolean onScaleBegin(ScaleGestureDetector d){multi=true;state=State.SCALING;focusX=d.getFocusX();focusY=d.getFocusY();return true;}
            @Override public boolean onScale(ScaleGestureDetector d){
                view.camera.pan(d.getFocusX()-focusX,d.getFocusY()-focusY);
                view.camera.zoomAt(d.getScaleFactor(),d.getFocusX(),d.getFocusY());
                focusX=d.getFocusX();focusY=d.getFocusY();view.invalidate();return true;
            }
        });
    }
    public boolean onTouch(MotionEvent event){
        int action=event.getActionMasked();float x=event.getX(),y=event.getY();
        if(action==MotionEvent.ACTION_DOWN){downX=lastX=x;downY=lastY=y;multi=false;state=view.ui.press(x,y)?State.UI:(view.placement.active()?State.PLACING:State.PRESSED);}
        if(state==State.UI){
            if(action==MotionEvent.ACTION_UP){view.ui.release(x,y);view.performClick();state=State.IDLE;}
            else if(action==MotionEvent.ACTION_CANCEL){view.ui.cancelPress();state=State.IDLE;}return true;
        }
        scale.onTouchEvent(event);
        if(action==MotionEvent.ACTION_POINTER_DOWN){multi=true;state=State.SCALING;}
        if(action==MotionEvent.ACTION_MOVE && !multi){
            float dx=x-downX,dy=y-downY;
            if(state==State.PLACING)place(x,y);
            else if(state==State.PANNING){view.camera.pan(x-lastX,y-lastY);view.invalidate();}
            else if(dx*dx+dy*dy>slop*slop){state=State.PANNING;view.camera.pan(dx,dy);view.invalidate();}
        }
        if(action==MotionEvent.ACTION_UP){
            if(!multi){
                if(state==State.PRESSED){view.select(view.renderer.hit(view.camera.screenToWorldX(x),view.camera.screenToWorldY(y)));view.performClick();}
                else if(state==State.PLACING){place(x,y);view.performClick();}
            }state=State.IDLE;
        }
        if(action==MotionEvent.ACTION_CANCEL)state=State.IDLE;
        lastX=x;lastY=y;return true;
    }
    private void place(float x,float y){float wx=view.camera.screenToWorldX(x),wy=view.camera.screenToWorldY(y);view.placement.position(VillageGrid.gridX(wx,wy),VillageGrid.gridY(wx,wy));view.invalidate();}
}
