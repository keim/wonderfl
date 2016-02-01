package {
    import flash.events.*;
    import flash.display.*;
    import flash.utils.getTimer;
    import net.hires.debug.Stats;
    
    [SWF(frameRate='60')]
    public class main extends Sprite {
        function main() {
            addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
        }
        
        private function _onAddedToStage(e:Event) : void {
            removeEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
            var bitmap:Bitmap = new Bitmap(screen = new BitmapData(size, size, false, 0));
            if (size<232) bitmap.scaleX = bitmap.scaleY = 2;
            bitmap.x = bitmap.y = 232 - size * bitmap.scaleX * 0.5;
            addChild(bitmap);
            addChild(new Stats());
            setup();
            addEventListener(Event.ENTER_FRAME, _onEnterFrame);
        }
        
        private function _onEnterFrame(e:Event) : void {
            mx = (mouseX - 232.5) * 0.00390625;
            my = (232.5 - mouseY) * 0.00390625;
            time = getTimer() * 0.001;
            draw();
        }
    }
}

// parameters, you can modify them.
var size:int = 192;
var ambient:Number = 0.1;
var diffusion:Number = 0.7;
var specular:Number = 0.6;
var power:Number = 12;


import flash.display.*;
import flash.geom.*

class Material {
    public var lmap:Vector.<uint> = new Vector.<uint>(512, true);
    function Material(col:uint, amb:Number, dif:Number) {
        var i:int, a:Number, r:int=col>>16, g:int=(col>>8)&255, b:int=col&255;
        for (i=0; i<512; i++) {
            a = ((i<256) ? amb : ((((i-256) * (dif - amb)) * 0.00390625) + amb)) * 2;
            if (a<1) lmap[i] = ((r*a)<<16)|((g*a)<<8)|((b*a)<<0);
            else lmap[i] = ((255-(255-r)*(2-a))<<16)|((255-(255-g)*(2-a))<<8)|(((255-(255-b)*(2-a)))<<0);
        }
    }
}

class Sphere {
    public var x:Number, y:Number, z:Number, r2:Number, mat:Material;
    public var cx:Number, cy:Number, cz:Number, cr:Number, omg:Number, pha:Number;
    function Sphere(cx:Number, cy:Number, cz:Number, cr:Number, omg:Number, pha:Number, r:Number, mat:Material) {
        this.cx = cx;
        this.cy = cy;
        this.cz = cz;
        this.cr = cr;
        this.omg = omg;
        this.pha = pha;
        this.r2 = r * r;
        this.mat = mat;
    }
    public function update() : void {
        var ang:Number = time * omg + pha;
        x = Math.cos(ang)*cr+cx;
        y = cy;
        z = Math.sin(ang)*cr+cz;
    }
}

var focusZ:Number = size;
var floorY:Number = 100;
var screen:BitmapData;
var initialDir:Vector.<Number> = new Vector.<Number>(size*size*3, true);
var spheres:Vector.<Sphere> = new Vector.<Sphere>();
var ldir:Vector3D = new Vector3D();
var light:Vector3D = new Vector3D(100,100,100);
var smap:Vector.<uint> = new Vector.<uint>(512, true);
var fcol:Vector.<uint> = new Vector.<uint>(1024, true);
var refs:Vector.<uint> = Vector.<uint>([0, 1, 2, 3, 3]);
var reff:Vector.<uint> = Vector.<uint>([0xffffff, 0x7f7f7f, 0x3f3f3f, 0x1f1f1f, 0x1f1f1f]);
var time:Number, mx:Number, my:Number, camX:Number, camY:Number, camZ:Number, tcamX:Number, tcamY:Number, tcamZ:Number;

function setup() : void {
    var i:int, j:int, idx:int, l:Number, s:int, hs:Number = (size - 1) * 0.5;
    for (j=0,idx=0; j<size; j++) for (i=0; i<size; i++) {
        l = 1/Math.sqrt((i - hs)*(i - hs) + (j - hs)*(j - hs) + focusZ*focusZ);
        initialDir[idx] = (i-hs) * l; idx++;
        initialDir[idx] = (j-hs) * l; idx++;
        initialDir[idx] = focusZ   * l; idx++;
    }
    for (i=0; i<512; i++) {
        s = (i<256) ? 64 : int(Math.pow((i-256) * 0.00390625, power) * (power + 2) * specular * 0.15915494309189534 * 192 + 64);
        if (s > 255) s = 255;
        smap[i] = 0x10101 * s;
        s = (i<256) ? (255-i) : (i-256);
        fcol[i] = 0x10101 * (s - (s>>3) + 31);
        fcol[i+512] = 0x10101 * ((s>>2) - (s>>5) + 31);
    }
    spheres.push(new Sphere(100, 40, 600, 200, 0.3, 1.0, 60, new Material(0x8080ff,ambient,diffusion)));
    spheres.push(new Sphere(  0, 50, 300, 100, 0.8, 0.8, 50, new Material(0x80ff80,ambient,diffusion)));
    spheres.push(new Sphere( 50, 60, 200, 200, 0.6, 2.0, 40, new Material(0xff8080,ambient,diffusion)));
    spheres.push(new Sphere(-50, 70, 500, 300, 0.4, 1.4, 30, new Material(0xc0c080,ambient,diffusion)));
    spheres.push(new Sphere(-90, 30, 600, 400, 0.2, 1.5, 70, new Material(0xc080c0,ambient,diffusion)));
    spheres.push(new Sphere( 70, 80, 400, 100, 0.7, 1.2, 20, new Material(0x80c0c0,ambient,diffusion)));
    camX = camY = camZ = tcamX = tcamY = tcamZ = 0;
}

function draw() : void {
    var i:int, j:int, k:int, l:int, idx:int, t:Number, tmin:Number, n:Number, s:Sphere, 
        ln:int, pixel:uint, hit:Sphere, a:int, kmax:int, 
        ox:Number, oy:Number, oz:Number, dx:Number, dy:Number, dz:Number, nx:Number, ny:Number, nz:Number,
        dsx:Number, dsy:Number, dsz:Number, B:Number, C:Number, D:Number;
    light.x = Math.cos(time*0.6)*100;
    light.y = Math.sin(time*1.1)*25+100;
    light.z = Math.sin(time*0.9)*100-100;
    ldir.x = -light.x;
    ldir.y = -light.y;
    ldir.z = -light.z;
    ldir.normalize();
    
    tcamX = mx * 400;
    tcamY = my * 150 - 50;
    tcamZ = my * 400 - 200;
    camX += (tcamX - camX) * 0.02;
    camY += (tcamY - camY) * 0.02;
    camZ += (tcamZ - camZ) * 0.02;
    
    kmax = spheres.length;
    for (k=0; k<kmax; k++) spheres[k].update();
    
    for (j=0,idx=0; j<size; j++) {
        for (i=0; i<size; i++) {
            ox = camX;
            oy = camY;
            oz = camZ;
            dx = initialDir[idx]; idx++;
            dy = initialDir[idx]; idx++;
            dz = initialDir[idx]; idx++;
            
            pixel = 0;
            for (l=1; l<5; l++) {
                tmin = 99999;
                hit = null;
                for (k=0; k<kmax; k++) {
                    s = spheres[k];
                    dsx = ox - s.x;
                    dsy = oy - s.y;
                    dsz = oz - s.z;
                    B = dsx * dx + dsy * dy + dsz * dz;
                    C = dsx * dsx + dsy * dsy + dsz * dsz - s.r2;
                    D = B * B - C;
                    if (D > 0) {
                        t = - B - Math.sqrt(D);
                        if ((t > 0) && (t < tmin)) {
                            tmin = t;
                            hit = s;
                        }
                    }
                }

                if (hit) {
                    ox += dx * tmin;
                    oy += dy * tmin;
                    oz += dz * tmin;
                    nx = ox - hit.x;
                    ny = oy - hit.y;
                    nz = oz - hit.z;
                    n = 1 / Math.sqrt(nx*nx + ny*ny + nz*nz);
                    nx *= n;
                    ny *= n;
                    nz *= n;
                    n = -(nx*dx + ny*dy + nz*dz) * 2;
                    dx += nx * n;
                    dy += ny * n;
                    dz += nz * n;
                    ln = int((ldir.x * nx + ldir.y * ny + ldir.z * nz) * 256) + 256;
                    a = hit.mat.lmap[ln];
                    a >>= refs[l];
                    a &= reff[l];
                    pixel += a;
                } else {
                    if (dy < 0) {
                        ln = int((ldir.x * dx + ldir.y * dy + ldir.z * dz) * 256) + 256;
                        a = smap[ln];
                        ln = l - 1;
                        a >>= refs[ln];
                        a &= reff[ln];
                        pixel += a;
                        break;
                    } else {
                        tmin = (floorY-oy)/dy;
                        ox += dx * tmin;
                        oy += dy * tmin;
                        oz += dz * tmin;
                        dy = -dy;
                        ln = dy * 256 + (((((ox+oz)>>7)+((ox-oz)>>7))&1)<<9) + 256;
                        a = fcol[ln];
                        a >>= refs[l];
                        a &= reff[l];
                        pixel += a;
                    }
                }
            }
            
            screen.setPixel(i, j, pixel);
        }
    }
}

