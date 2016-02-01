// Click screen to explode.
package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import frocessing.display.*;
    import frocessing.color.ColorLerp;
    import org.si.sion.*;
    import org.libspark.betweenas3.easing.*;
    import com.bit101.components.*;
    
    [SWF(backgroundColor="0", frameRate="60")]
    public class ExplosionRender extends F5MovieClip2D {
    // test
    //--------------------------------------------------------------------------------
        public var screen:BitmapData, driver:SiONDriver, data:SiONData;
        public var exp:Vector.<BitmapData>, frameCounter:int, pt:Point = null;
        
        public function setup() : void {
            screen = new BitmapData(240, 240, false);
            driver = new SiONDriver();
            data = driver.compile("%2@al2i0@4@ml8i1@1,32@tl8@f40,1,48,24,0,0,80,68s22o2q0g32q8g8");
            exp = explosion();
            with(addChild(new Bitmap(screen))) scaleX = scaleY = 2;
            new Label(this, 4, 0, "Click to explode.");
            new RadioButton(this,  4, 20, "60fps", true,  function(e:Event):void{stage.frameRate = 60;});
            new RadioButton(this, 49, 20, "30fps", false, function(e:Event):void{stage.frameRate = 30;});
            new RadioButton(this, 94, 20, "15fps", false, function(e:Event):void{stage.frameRate = 15;});
            new InputText(this, 8, 443, loaderInfo.url).setSize(450, 15);
        }

        public function mouseClicked() : void {
            pt = new Point(pmouseX*0.5-100, pmouseY*0.5-100);
            frameCounter = 0;
            driver.play(data);
        }
        
        public function draw() : void {
            screen.fillRect(screen.rect, 0);
            if (pt) {
                screen.copyPixels(exp[frameCounter], exp[frameCounter].rect, pt);
                if (++frameCounter==120) pt = null;
            }
        }
        
        
        
        
    // animations
    //--------------------------------------------------------------------------------
        public function explosion(col0:int=0xa0a060, col1:int=0x703010) : Vector.<BitmapData> {
            var fire:*  = palette([0,0xff000000|col0,0xff000000|col1,0xc0000000|(col1>>1),0], [0,0.05,0.2,0.6,1]);
            var smoke:* = palette([0,0xff000000,0xff000000,0x00808080], [0,0.1,0.2,1]);
            var part:*  = palette([0xff808080,0xff000000|col0,0], [0,0.5,1]);
            var init:*, i:int, r:Number, d:Number;
            var frame:Vector.<BitmapData> = new Vector.<BitmapData>(120);
            Particle.initialize();
            for (i=0; i<frame.length; i++) {
                Particle.begin(frame[i] = new BitmapData(200, 200, false, 0));
                if (Particle.counter<=10) {
                    init = {size:0, x:0, y:0};
                    r = random(10,30);
                    d = random(0, 6.28);
                    Particle.alloc(dust, part, null, {size:100, x:r*cos(d)*2, y:r*sin(d)}, init, random(20,60), Expo.easeOut, 0);
                }
                if (Particle.counter<=20) {
                    init = {size:30, x:random(0,30)-random(0,30), y:random(0,30)-random(0,30)};
                    Particle.alloc(cloud, fire, "add", {rot:random(-0.5,0.5), size:180}, init, random(50,100), Quint.easeOut, 0);
                    if (Particle.counter&1) {
                        init = {size:100, x:random(0,50)-random(0,50), y:random(0,50)-random(0,50)};
                        Particle.alloc(cloud, smoke, null, {y:init.y-20, rot:random(-1,1)}, init, 100, null, 0);
                    }
                }
                Particle.end();
            }
            return frame;
        }
        
        
    // textures
    //--------------------------------------------------------------------------------
        public function get cloud() : BitmapData {
            if (!_cloud) {
                _cloud = new BitmapData(256, 256, true);
                _cloud.perlinNoise(64, 64, 4, Math.random()*int.MAX_VALUE, false, true, 7, true);
                mat.createGradientBox(256, 256, 0, 0, 0);
                _cloud.draw(radialGradientShape(256, [0xffffff,0x404040, 0], [1,1,1], [0,128,255]), null, null, "multiply");
                _cloud.copyChannel(_cloud, _cloud.rect, _cloud.rect.topLeft, 1, 8);
                _cloud.colorTransform(_cloud.rect, new ColorTransform(1,1,1,1.5,128,128,128,-16));
            }
            return _cloud;
        }
        private var _cloud:BitmapData = null;
        
        public function get dust() : BitmapData {
            var i:int;
            if (!_dust) {
                _dust = new BitmapData(256, 256, true, 0);
                radialGradientShape(4, [0xffffff,0xffffff], [1,0], [0,255]);
                mat.identity();
                for (i=0; i<8; i++) {
                    mat.tx = Math.random()*192+28;
                    mat.ty = Math.random()*192+28;
                    _dust.draw(shp, mat);
                }
            }
            return _dust;
        }
        private var _dust:BitmapData = null;
        
        public function get flash() : BitmapData {
            var n:Number, r:Number;
            if (!_flash) {
                _flash = new BitmapData(256, 256, true, 0);
                for (n=0; n<6.283185307179586; n+=0.002181661564992912) {
                    r = (1-Math.random() * Math.random()) * 127;
                    mat.createGradientBox(256-r-r, 256-r-r, 0, r, r);
                    shp.graphics.clear();
                    shp.graphics.lineStyle(1);
                    shp.graphics.lineGradientStyle(GradientType.RADIAL, [0xffffff,0xffffff], [0.5,0], [0,255], mat);
                    shp.graphics.moveTo(127.5,127.5);
                    shp.graphics.lineTo(Math.sin(n)*181+127.5, Math.cos(n)*181+127.5);
                }
                _flash.draw(shp);
            }
            return _flash;
        }
        private var _flash:BitmapData = null;
        
        
    // utilities
    //--------------------------------------------------------------------------------
        public function palette(col32:Array, ratio:Array, rangeA:Number=1, rangeRGB:Number=1) : * {
            var a:Vector.<Number> = new Vector.<Number>(256), 
                r:Vector.<Number> = new Vector.<Number>(256), 
                g:Vector.<Number> = new Vector.<Number>(256), 
                b:Vector.<Number> = new Vector.<Number>(256), 
                i:int, c:int, col:uint;
            for (i=0; i<ratio.length; i++) ratio[i]=int(ratio[i]*256);
            rangeA /= 255;
            rangeRGB /= 255;
            for (c=0, i=0; i<256; i++, c+=(i>=ratio[c+1])) {
                col = ColorLerp.lerp(col32[c], col32[c+1], (i-ratio[c])/(ratio[c+1]-ratio[c]));
                a[i] = (col >>> 24) * rangeA;
                r[i] = ((col >> 16) & 255) * rangeRGB;
                g[i] = ((col >> 8) & 255) * rangeRGB;
                b[i] = (col & 255) * rangeRGB;
            }
            return {"a":a, "r":r, "g":g, "b":b};
        }
        
        public function radialGradientShape(size:Number, color:Array, alpha:Array, ratio:Array) : Shape {
            mat.createGradientBox(size, size, 0, 0, 0);
            shp.graphics.clear();
            shp.graphics.beginGradientFill(GradientType.RADIAL, color, alpha, ratio, mat);
            shp.graphics.drawRect(0, 0, size, size);
            shp.graphics.endFill();
            return shp;
        }
        
        private var shp:Shape = new Shape(), mat:Matrix = new Matrix();
    }
}




import flash.display.*;
import flash.geom.*;
import org.libspark.betweenas3.easing.*;
import org.libspark.betweenas3.tweens.*;
import org.libspark.betweenas3.core.easing.*;
import org.libspark.betweenas3.core.tweens.*;

class Particle {
    static public function initialize() : void {
        counter = 0;
    }
    static public function alloc(tex:BitmapData, pal:*, method:String, to:*=null, from:*=null, life:int=60, easing:IEasing=null, layer:int=0) : Particle {
        var p:Particle = _freeList.pop() || new Particle();
        p.texture = tex;
        p.a = pal.a;
        p.r = pal.r;
        p.g = pal.g;
        p.b = pal.b;
        p.method = method;
        p.aging = 1/life;
        p.age = 0;
        p.x = ("x" in from) ? from.x : 0;
        p.y = ("y" in from) ? from.y : 0;
        p.size = ("size" in from) ? from.size : 256;
        p.angle = Math.random() * 6.283185307179586;
        if ("rot" in to) {
            to["angle"] = p.angle + to.rot;
            delete to.rot;
        }
        var t:ITween = $.tween(p, to, from, life, easing, layer);
        t.onUpdate = p._update;
        t.onComplete = p._complete;
        t.play();
        return p;
    }
    static public function begin(screen:BitmapData) : void {
        _screen = screen;
    }
    static public function end() : void {
        $.update();
        counter++;
    }
    
    static public var counter:int = 0;
    static private var _freeList:Vector.<Particle> = new Vector.<Particle>();
    static private var _screen:BitmapData;
    public var x:Number, y:Number, angle:Number, size:Number, method:String, aging:Number, age:Number, layer:int;
    public var texture:BitmapData, a:Vector.<Number>, r:Vector.<Number>, g:Vector.<Number>, b:Vector.<Number>;
    public var mat:Matrix = new Matrix(), colt:ColorTransform = new ColorTransform();
    
    function Particle() {}
    private function _update() : void {
        var htxt:Number = texture.width * 0.5,
            hscr:Number = _screen.width * 0.5, 
            scale:Number = size/texture.width;
        mat.identity();
        mat.translate(-htxt, -htxt);
        mat.rotate(angle);
        mat.scale(scale, scale);
        mat.translate(x+hscr, y+hscr);
        var i:int = age * 255;
        if (i>255) i=255;
        colt.redMultiplier = r[i];
        colt.greenMultiplier = g[i];
        colt.blueMultiplier = b[i];
        colt.alphaMultiplier = a[i];
        _screen.draw(texture, mat, colt, method, null, true);
        age += aging;
    }
    private function _complete() : void { _freeList.push(this); }
}


// Customized betweenAS3. Free but naive ...
//--------------------------------------------------------------------------------
import org.libspark.betweenas3.core.ticker.*;
import org.libspark.betweenas3.core.updaters.*;
import org.libspark.betweenas3.core.updaters.display.*;
import org.libspark.betweenas3.core.updaters.geom.*;
import org.libspark.betweenas3.core.utils.*;

class ControlableTicker implements ITicker {
    private var _term:TickerListener = new TickerListener();
    private var _time:Number = 0;
    function ControlableTicker() { _term.nextListener = _term.prevListener = _term; }
    public function get time():Number { return _time; }
    public function addTickerListener(tl:TickerListener) : void {
        if (tl.nextListener != null || tl.prevListener != null) return;
        tl.prevListener = _term.prevListener;
        tl.nextListener = _term;
        _term.prevListener.nextListener = tl;
        _term.prevListener = tl;
    }
    public function removeTickerListener(tl:TickerListener) : void {
        tl.prevListener.nextListener = tl.nextListener;
        tl.nextListener.prevListener = tl.prevListener;
        tl.prevListener = tl.nextListener = null;
    }
    public function start() : void {}
    public function stop() : void {}
    public function update(deltaTime:Number) : void {
        _time += deltaTime;
        for (var tl:TickerListener = _term.nextListener; tl != _term; tl = tl.nextListener) {
            if (tl.tick(_time)) {
                tl.prevListener.nextListener = tl.nextListener;
                tl.nextListener.prevListener = tl.prevListener;
                var prev:TickerListener = tl.prevListener;
                tl.prevListener = tl.nextListener = null;
                tl = prev;
            }
        }
    }
} 

class $ {
    static private var _tickers:Vector.<ControlableTicker> = new Vector.<ControlableTicker>(4);
    static private var _updaterClassRegistry:ClassRegistry = new ClassRegistry();
    static private var _updaterFactory:UpdaterFactory = new UpdaterFactory(_updaterClassRegistry);
    {
        _tickers[0] = new ControlableTicker();
        _tickers[1] = new ControlableTicker();
        _tickers[2] = new ControlableTicker();
        _tickers[3] = new ControlableTicker();
        ObjectUpdater.register(_updaterClassRegistry);
        DisplayObjectUpdater.register(_updaterClassRegistry);
        MovieClipUpdater.register(_updaterClassRegistry);
        PointUpdater.register(_updaterClassRegistry);
    }
    
    static public function tween(target:*, to:*, from:*=null, time:Number=1.0, easing:IEasing=null, layer:int=0) : IObjectTween {
        var tween:ObjectTween = new ObjectTween(_tickers[layer]);
        tween.updater = _updaterFactory.create(target, to, from);
        tween.time = time;
        tween.easing = easing || Linear.easeNone;
        return tween;
    }
    
    static public function update() : void { 
        for (var i:int=0; i<_tickers.length; i++) _tickers[i].update(1); 
    }
}

