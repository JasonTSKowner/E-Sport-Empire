package com.jasontsk.projectcitadel;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Shader;
import java.util.HashMap;
import java.util.Map;

/** Original Crownforge artwork. Vector masters are rasterized once, at 2x density. */
final class BuildingArt {
    static final class Sprite {
        final Bitmap bitmap;
        final float left, top, width, height;
        Sprite(Bitmap bitmap, float left, float top, float width, float height) {
            this.bitmap = bitmap; this.left = left; this.top = top;
            this.width = width; this.height = height;
        }
        boolean contains(float x, float y) {
            int px = (int)((x - left) * 2), py = (int)((y - top) * 2);
            return px >= 0 && py >= 0 && px < bitmap.getWidth() && py < bitmap.getHeight()
                    && Color.alpha(bitmap.getPixel(px, py)) > 80;
        }
    }

    private static final int STONE = 0xff9aaca3, LIGHT = 0xffcad0ac, DARK = 0xff506c67;
    private static final int ROOF = 0xff346d77, ROOF_LIGHT = 0xff579397, ROOF_DARK = 0xff214b58;
    private static final int WOOD = 0xffa67e4d, WOOD_DARK = 0xff644b35, GOLD = 0xffffcb64;
    private final Map<String, Map<Integer, Sprite>> cache = new HashMap<>();
    private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private Canvas c;

    Sprite get(BuildingInstance b, int mask) {
        int level = Math.max(1, b.level);
        int key = level * 16 + mask;
        Map<Integer, Sprite> variants = cache.get(b.type);
        if (variants == null) { variants = new HashMap<>(); cache.put(b.type, variants); }
        Sprite sprite = variants.get(key);
        if (sprite != null) return sprite;
        int size = b.definition().size;
        float width = size * 64 + 64, height = size * 32 + 190;
        float left = -width / 2, top = -(height - size * 16 - 24);
        Bitmap bitmap = Bitmap.createBitmap((int)width * 2, (int)height * 2, Bitmap.Config.ARGB_8888);
        c = new Canvas(bitmap); c.scale(2, 2); c.translate(-left, -top);
        String type = b.type.replace("_", "").replace(" ", "").toLowerCase(java.util.Locale.ROOT);
        shadow(size);
        if (!type.equals("wall")) foundation(size);
        switch (type) {
            case "townhall": townHall(level); break;
            case "goldmine": mine(level); break;
            case "elixirmine":
            case "elixircollector": collector(level); break;
            case "goldstorage": goldStorage(level); break;
            case "elixirstorage": elixirStorage(level); break;
            case "cannon": cannon(level); break;
            case "archer":
            case "archertower": archerTower(level); break;
            case "builderhut": hut(level); break;
            case "wall": wall(level, mask); break;
            default: hut(level);
        }
        sprite = new Sprite(bitmap, left, top, width, height);
        variants.put(key, sprite); c = null;
        return sprite;
    }

    private void shadow(int size) {
        oval(-size * 31 + 6, -size * 10 + 12, size * 31 + 23, size * 16 + 15, 0x340d2524);
        oval(-size * 24 + 9, -size * 8 + 10, size * 26 + 17, size * 13 + 12, 0x290d2524);
    }

    private void foundation(int size) {
        float a = size * 29;
        box(0, 1, a, a, 7, 0xff667760, 0xff485f53, 0xff82977a);
        diamond(0, -6, a * .9f, a * .45f, 0xffb8ad88);
        // Uneven laid stones sit below the structure, rather than a tile grid.
        for (int i = -2; i <= 2; i++) {
            line(i * a * .18f - a * .4f, -6 + i * a * .09f + a * .2f,
                    i * a * .18f + a * .2f, -6 + i * a * .09f - a * .1f, 0xff938f74, 1);
        }
        line(-a * .89f, -6, 0, -6 + a * .445f, 0xffc9c29d, 2);
    }

    private void townHall(int level) {
        // Silhouette evolves from timber great hall into a five-tower keep.
        int body = level >= 3 ? STONE : WOOD;
        int side = level >= 3 ? DARK : WOOD_DARK;
        int bright = level >= 3 ? LIGHT : 0xffc59b63;
        float h = 49 + level * 6;
        box(0, -5, 151, 139, h, body, side, bright);
        masonry(0, -5, 151, 139, h, level >= 3);
        gable(0, -5, 153, 142, h, 32 + level * 3);
        // Portal and lintel on the broad front face.
        poly(0xff34483d, -26, 24, -26, -21, -3, -10, -3, 36);
        poly(0xff896542, -23, 24, -23, -16, -6, -8, -6, 33);
        line(-15, -12, -15, 28, 0xff503c2b, 2);
        line(-28, -22, -2, -9, GOLD, 4);
        circle(-10, 12, 1.8f, GOLD);
        for (int i = 0; i < 2; i++) {
            float xx = 23 + i * 23;
            poly(0xff223d42, xx, 25-i*12, xx, 9-i*12, xx+10, 4-i*12, xx+10, 20-i*12);
            line(xx + 5, 23-i*12, xx + 5, 7-i*12, 0xffffdc87, 2);
        }
        if (level >= 2) {
            tower(-66, 4, 34, 69 + level * 5, level);
            tower(66, 4, 34, 69 + level * 5, level);
        } else {
            box(-62, 0, 12, 12, 69, WOOD, WOOD_DARK, 0xffd2af70);
            box(62, 0, 12, 12, 69, WOOD, WOOD_DARK, 0xffd2af70);
        }
        if (level >= 4) {
            tower(-37, -35, 29, 92, level);
            tower(37, -35, 29, 92, level);
        }
        if (level >= 5) {
            box(0, -40, 42, 42, 96, STONE, DARK, LIGHT);
            diamond(0, -142, 28, 14, ROOF_LIGHT);
            poly(ROOF_DARK, -28, -142, 0, -177, 0, -128);
            poly(ROOF, 0, -177, 28, -142, 0, -128);
            banner(4, -163, 25, 31);
        } else banner(8, -101 - level * 6, 26, 27);
        // Crown crest, bespoke three-point relief above the entrance.
        poly(GOLD, -27, -41, -22, -32, -16, -39, -10, -26, -5, -31, -5, -18, -27, -29);
        line(-26, -27, -5, -17, 0xff9b662e, 2);
        stairs(-13, 42, 40);
    }

    private void tower(float x, float y, float w, float h, int level) {
        box(x, y, w, w, h, STONE, DARK, LIGHT);
        for (int i=1; i<4; i++) {
            line(x-w/2, y-h*i/4, x, y+w/4-h*i/4, 0xff728880, 1);
            line(x, y+w/4-h*i/4, x+w/2, y-h*i/4, 0xff354f4d, 1);
        }
        box(x, y-h+4, w+6, w+6, 8, LIGHT, 0xff587c74, 0xffd6d9b9);
        if (level < 4) {
            poly(ROOF_DARK, x-w*.68f,y-h-4, x,y-h-40, x,y-h+7);
            poly(ROOF, x,y-h-40, x+w*.68f,y-h-4, x,y-h+7);
        } else {
            for (int j=-1;j<=1;j++) {
                box(x+j*w*.3f, y-h+Math.abs(j)*-w*.15f, 8, 8, 13, LIGHT, DARK, 0xffe0d5a7);
            }
        }
        poly(0xff294b4c, x-4,y-h+26, x-4,y-h+43, x+3,y-h+39, x+3,y-h+22);
    }

    private void mine(int level) {
        // Exposed rock seam, braced mineshaft, hoist wheel, and ore cart.
        poly(0xff5d7370, -62,7, -56,-33, -34,-66, 3,-74, 39,-43, 60,-1, 11,31);
        poly(0xff8a9b87, -56,-33, -34,-66, 3,-74, 7,-25, -16,3);
        poly(0xffa5ae92, 3,-74, 39,-43, 7,-25);
        poly(0xff435f5b, 7,-25, 39,-43, 60,-1, 11,31);
        poly(0xff192f31, -37,6, -37,-28, -17,-42, 5,-25, 5,27);
        line(-43,5,-43,-34,WOOD,8); line(-43,-34,10,-9,0xffc89a5d,9);
        line(7,-9,7,27,WOOD_DARK,8);
        line(-36,-29,-28,-21,0xffe1b06a,2);
        line(-24,16,16,36,0xff8a9990,3); line(-8,8,32,28,0xff8a9990,3);
        for(int i=0;i<4;i++) line(-25+i*11,19+i*5,-10+i*11,11+i*5,WOOD_DARK,3);
        poly(GOLD, 23,-43,30,-50,36,-41,29,-35); poly(0xffeeb440,38,-16,47,-19,50,-9,41,-7);
        box(36, 13, 28, 22, 17, 0xffb08342, WOOD_DARK, 0xffdfba6b);
        circle(24,20,6,0xff2c4141); circle(46,14,6,0xff2c4141);
        circle(24,20,2,GOLD); circle(46,14,2,GOLD);
        for(int i=0;i<5;i++) diamond(24+i*5,-4+(i%2)*3,6,5,i%2==0?GOLD:0xffdc9b39);
        line(37,-12,37,-74,WOOD,6); line(16,-83,53,-65,0xffd0a46a,7);
        circle(31,-72,11,WOOD_DARK); circle(31,-72,7,0xff9b855c);
        line(31,-72,31,-38,0xff303c35,2);
        lantern(-43,-30);
        if (level>=3) banner(53,-52,18,22);
    }

    private void collector(int level) {
        box(-10, 2, 82, 72, 20, STONE, DARK, LIGHT);
        cylinder(-13,-21,28,61,0xff364c65,0xff94cbd0);
        // Luminous vessel with a visible liquid meniscus and iron ribs.
        p.setShader(new LinearGradient(-40,0,13,0,new int[]{0xff553789,0xffb77fd8,0xff5c3d91},null,Shader.TileMode.CLAMP));
        c.drawOval(-38,-102,12,-38,p); p.setShader(null);
        oval(-33,-62,7,-44,0xffdf9ce9); oval(-34,-97,6,-81,0xffabdce0);
        line(-31,-90,-31,-57,0x99efffff,3);
        ellipseRing(-41,-102,15,-78,0xff658e9c,5);
        ellipseRing(-41,-57,15,-32,0xff657f87,5);
        line(-41,-90,-41,-44,0xff93b6b5,4); line(15,-90,15,-44,0xff374f62,4);
        box(-13,-97,15,15,13,0xff83a7a9,0xff395c64,GOLD);
        line(12,-49,36,-37,0xffcfb377,8); line(36,-37,36,0,0xffcfb377,8);
        line(12,-50,35,-38,0xfff1d699,2);
        cylinder(35,2,13,27,0xff54426f,0xffbc83d3);
        ellipseRing(26,-21,44,-14,GOLD,3);
        circle(-13,-115,5,0xffbce8ff);
        if(level>=3) { line(-46,-33,-46,-74,0xff638d98,4); circle(-46,-77,7,0xff94dae3); }
    }

    private void goldStorage(int level) {
        box(0, -1, 103, 91, 46, STONE, DARK, LIGHT);
        box(0, -38, 109, 97, 12, 0xffc2ad7b, 0xff7c7256, 0xffe0c994);
        // An open treasury lined with brass, brimming with polygonal coins.
        diamond(0,-56,45,23,0xff765735);
        for(int row=0;row<4;row++) for(int j=0;j<5;j++) {
            float xx=(j-2)*14+(row%2)*5, yy=-62+row*6-Math.abs(j-2)*3;
            oval(xx-7,yy-3,xx+7,yy+3,(j+row)%2==0?0xffffd86f:0xffdca441);
            line(xx-5,yy-2,xx+4,yy-2,0xffffeba3,1);
        }
        poly(0xffb58a40,-40,-35,-28,-29,-28,18,-40,12);
        poly(0xffb58a40,25,-29,37,-35,37,12,25,18);
        for(int i=0;i<3;i++) { circle(-34,-23+i*13,2,GOLD); circle(31,-23+i*13,2,GOLD); }
        poly(0xff6a5939,-13,-16,1,-9,1,15,-13,8);
        circle(-6,-1,5,GOLD); circle(-6,-1,2,0xff795a32);
        if(level>=3) { banner(-45,-60,20,24); banner(42,-62,18,23); }
    }

    private void elixirStorage(int level) {
        box(0, 4, 101, 93, 17, STONE, DARK, LIGHT);
        cylinder(0,-17,41,60,0xff384858,0xffadc2b1);
        p.setShader(new LinearGradient(-40,0,42,0,new int[]{0xff493965,0xffb376d5,0xff68418c,0xff343e55},null,Shader.TileMode.CLAMP));
        c.drawOval(-39,-109,39,-18,p); p.setShader(null);
        oval(-34,-57,34,-24,0xffae67c9); oval(-30,-57,30,-39,0xffd894e0);
        oval(-26,-89,-14,-60,0x88eff8ff); oval(-13,-96,-7,-78,0x55eff8ff);
        ellipseRing(-44,-43,44,-13,0xff7c938d,7);
        ellipseRing(-43,-111,43,-79,0xff7c9b95,7);
        for(int i=-1;i<=1;i++) line(i*36,-92,i*39,-28, i==1?0xff3f5d61:0xffa9bbae,5);
        cylinder(0,-109,20,13,0xff476b72,0xffa8c6bc);
        diamond(0,-125,12,6,GOLD); circle(0,-136,5,0xffb7e9ec);
        if(level>=3) { box(-47,0,13,13,47,STONE,DARK,LIGHT); box(47,0,13,13,47,STONE,DARK,LIGHT); }
    }

    private void cannon(int level) {
        box(0, -2, 60, 60, 13, STONE, DARK, LIGHT);
        cylinder(0,-15,25,13,0xff374d50,0xff6e8583);
        box(-2,-22,35,27,16,0xff6b7771,0xff33474a,0xff9aaa8d);
        circle(-19,-23,15,WOOD_DARK); circle(-19,-23,11,0xffad9766); circle(-19,-23,4,0xff364d4e);
        // Barrel points diagonally into world space, with a separate dark bore.
        poly(0xff30464b,-11,-47,8,-57,49,-37,51,-19,30,-12,-10,-31);
        poly(0xff799593,-11,-47,8,-57,49,-37,30,-27);
        poly(0xff4b656a,30,-27,49,-37,51,-19,30,-12);
        oval(31,-35,52,-14,0xff27424a); oval(36,-30,48,-19,0xff0c222b);
        line(1,-42,14,-49,GOLD,4); line(14,-49,20,-45,GOLD,4);
        line(13,-35,27,-42,0xffbec7ac,2);
        if(level>=3) { line(27,-30,43,-39,GOLD,4); circle(-19,-23,3,GOLD); }
        for(int i=0;i<3;i++) circle(-32+i*9,9-i*4,5,0xff35494b);
    }

    private void archerTower(int level) {
        box(0, -2, 46, 46, 71, STONE, DARK, LIGHT);
        masonry(0,-2,46,46,71,true);
        poly(0xff233f42,-7,-28,-7,-52,1,-48,1,-24);
        box(0,-73,69,69,15,WOOD,WOOD_DARK,0xffd8b27a);
        for(int i=-1;i<=1;i++) {
            box(-22+i*12,-71+i*6,7,7,20,WOOD,WOOD_DARK,0xffd3b984);
            box(22+i*12,-71-i*6,7,7,20,WOOD,WOOD_DARK,0xffd3b984);
        }
        line(-28,-81,-28,-108,WOOD_DARK,5); line(28,-81,28,-108,WOOD_DARK,5);
        gable(0,-78,65,65,33,20);
        banner(29,-124,18,25);
        // Crossbow turret visible beneath the teal canopy.
        line(-3,-101,18,-91,0xffd8bb7c,3); line(2,-85,13,-107,0xffbfa779,3);
        line(2,-85,18,-91,0xff454d43,1); line(13,-107,18,-91,0xff454d43,1);
        if(level>=3) { box(-23,2,14,14,32,STONE,DARK,LIGHT); box(23,2,14,14,32,STONE,DARK,LIGHT); }
    }

    private void hut(int level) {
        box(0,-3,55,55,34,WOOD,WOOD_DARK,0xffc5a66c);
        masonry(0,-3,55,55,34,false);
        gable(0,-3,66,66,36,19);
        box(12,-53,12,12,18,STONE,DARK,LIGHT);
        poly(0xff354641,-19,5,-19,-17,-5,-10,-5,12);
        poly(0xffb88744,10,-7,21,-12,21,1,10,7);
        line(15,-9,15,4,GOLD,2);
        box(31,8,23,15,13,WOOD,WOOD_DARK,0xffd8b174);
        // Hammer on the workbench is a recognizable builder insignia.
        line(26,-9,40,0,0xff594330,3); line(27,-13,22,-6,0xffb3c1ae,6);
        for(int i=0;i<3;i++) { line(-35,3+i*5,-19,11+i*5,WOOD_DARK,7); circle(-35,3+i*5,3,0xffcfaf76); }
        lantern(-23,-28);
    }

    private void wall(int level, int mask) {
        float h = 22 + level * 5;
        int front = level==1?WOOD:STONE, side=level==1?WOOD_DARK:DARK, top=level==1?0xffceaa73:LIGHT;
        // Arms meet tile boundaries, keeping diagonal segments contiguous.
        if((mask&8)!=0) box(16,-8,13,33,h-5,front,side,top);
        if((mask&4)!=0) box(-16,-8,33,13,h-5,front,side,top);
        box(0,0,26,26,h,front,side,top);
        if((mask&1)!=0) box(16,8,33,13,h-5,front,side,top);
        if((mask&2)!=0) box(-16,8,13,33,h-5,front,side,top);
        box(0,-h+1,31,31,5,top,side,level>=3?0xffd8c998:0xffc8c5a0);
        for(int i=-1;i<=1;i+=2) box(i*9,-h+2,7,7,9,front,side,top);
        if(level>=3) { poly(GOLD,-4,-h+9,0,-h+14,4,-h+9,0,-h+4); }
        if(level==1) { line(-7,-h+9,-7,1,0xffd6b57a,2); line(6,-h+9,6,1,0xff6c5338,2); }
        else { line(-12,-h/2,0,-h/2+6,0xff698379,1); line(0,-h/2+6,12,-h/2,0xff334f4d,1); }
    }

    private void masonry(float x,float y,float a,float b,float h,boolean stone) {
        int rows=stone?4:5;
        for(int i=1;i<rows;i++) {
            float yy=y-h*i/rows;
            line(x-(a+b)/2,yy+(b-a)/4,x+(a-b)/2,yy+(a+b)/4,stone?0xff758c80:0xff7f5d3d,1.3f);
            line(x+(a-b)/2,yy+(a+b)/4,x+(a+b)/2,yy+(a-b)/4,stone?0xff3c5955:0xff493e2f,1.2f);
        }
        if(!stone) {
            line(x-(a+b)/2+4,y+(b-a)/4-4,x-(a+b)/2+4,y+(b-a)/4-h+3,0xffd0ab71,4);
            line(x+(a-b)/2,y+(a+b)/4-2,x+(a-b)/2,y+(a+b)/4-h,WOOD_DARK,5);
        }
    }

    private void gable(float x,float y,float a,float b,float h,float peak) {
        float nx=x+(b-a)/2,ny=y-(a+b)/4-h;
        float ex=x+(a+b)/2,ey=y+(a-b)/4-h;
        float sx=x+(a-b)/2,sy=y+(a+b)/4-h;
        float wx=x-(a+b)/2,wy=y+(b-a)/4-h;
        float r1x=(nx+wx)/2,r1y=(ny+wy)/2-peak,r2x=(ex+sx)/2,r2y=(ey+sy)/2-peak;
        poly(ROOF_DARK,r1x,r1y,r2x,r2y,sx,sy,wx,wy);
        poly(ROOF,r1x,r1y,nx,ny,ex,ey,r2x,r2y);
        line(r1x,r1y,r2x,r2y,0xff7ca5a0,3);
        line(wx,wy,sx,sy,0xffc4aa72,3); line(sx,sy,ex,ey,0xff85744f,3);
        for(int i=1;i<6;i++) {
            float f=i/6f;
            line(r1x+(r2x-r1x)*f,r1y+(r2y-r1y)*f,wx+(sx-wx)*f,wy+(sy-wy)*f,ROOF_LIGHT,1);
        }
        for(int i=1;i<3;i++) {
            float f=i/3f;
            line(r1x+(wx-r1x)*f,r1y+(wy-r1y)*f,r2x+(sx-r2x)*f,r2y+(sy-r2y)*f,0xff193f4c,1);
        }
    }

    private void stairs(float x,float y,float w) {
        for(int i=3;i>=0;i--) box(x-i*3,y+i*4,w,8,3+i*2,STONE,DARK,LIGHT);
    }
    private void banner(float x,float y,float w,float h) {
        line(x,y+35,x,y-5,0xffd4b175,2);
        circle(x,y-7,3,GOLD);
        poly(0xff256b80,x+1,y-2,x+w,y+1,x+w-3,y+h-7,x+w*.48f,y+h,x+1,y+h-2);
        line(x+3,y+1,x+w-2,y+4,0xffe9cc7d,2);
        poly(GOLD,x+w*.35f,y+8,x+w*.52f,y+5,x+w*.68f,y+9,x+w*.5f,y+16);
    }
    private void lantern(float x,float y) {
        circle(x,y,9,0x22ffce68); circle(x,y,6,0x33ffce68);
        c.save(); c.translate(x,y); c.rotate(-10);
        rect(-3,-5,3,5,0xfff7ce7c); rect(-4,-7,4,-5,0xff434f42); rect(-4,5,4,7,0xff434f42); c.restore();
    }
    private void cylinder(float x,float y,float r,float h,int body,int lid) {
        p.setShader(new LinearGradient(x-r,y,x+r,y,new int[]{lid,body,body},null,Shader.TileMode.CLAMP));
        c.drawRect(x-r,y-h,x+r,y,p); c.drawOval(x-r,y-r*.4f,x+r,y+r*.4f,p); p.setShader(null);
        oval(x-r,y-h-r*.4f,x+r,y-h+r*.4f,lid);
    }
    private void box(float x,float y,float a,float b,float h,int left,int right,int top) {
        float nx=x+(b-a)/2,ny=y-(a+b)/4,ex=x+(a+b)/2,ey=y+(a-b)/4;
        float sx=x+(a-b)/2,sy=y+(a+b)/4,wx=x-(a+b)/2,wy=y+(b-a)/4;
        poly(left,wx,wy-h,sx,sy-h,sx,sy,wx,wy);
        poly(right,sx,sy-h,ex,ey-h,ex,ey,sx,sy);
        poly(top,nx,ny-h,ex,ey-h,sx,sy-h,wx,wy-h);
        line(wx,wy-h,sx,sy-h,0x45ffffff,1);
    }
    private void diamond(float x,float y,float w,float h,int color) { poly(color,x,y-h,x+w,y,x,y+h,x-w,y); }
    private void poly(int color,float... xy) {
        path.reset(); path.moveTo(xy[0],xy[1]); for(int i=2;i<xy.length;i+=2)path.lineTo(xy[i],xy[i+1]);path.close();
        p.setColor(color); p.setStyle(Paint.Style.FILL); c.drawPath(path,p);
    }
    private void line(float x1,float y1,float x2,float y2,int color,float width) {
        p.setColor(color);p.setStrokeWidth(width);p.setStrokeCap(Paint.Cap.ROUND);c.drawLine(x1,y1,x2,y2,p);
    }
    private void circle(float x,float y,float r,int color) {p.setColor(color);c.drawCircle(x,y,r,p);}
    private void oval(float l,float t,float r,float b,int color) {p.setColor(color);c.drawOval(l,t,r,b,p);}
    private void rect(float l,float t,float r,float b,int color) {p.setColor(color);c.drawRect(l,t,r,b,p);}
    private void ellipseRing(float l,float t,float r,float b,int color,float width) {
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(width);p.setColor(color);c.drawOval(l,t,r,b,p);p.setStyle(Paint.Style.FILL);
    }
}
