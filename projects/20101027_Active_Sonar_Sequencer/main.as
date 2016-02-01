package {
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import flash.geom.*;
    import org.si.sion.events.*;
    
    [SWF(width="465", height="465", backgroundColor="0xffffff", frameRate="30")]
    public class main extends Sprite {
        private var _container:Sprite;
        private var _prevTime:int;
        private var _mouseDownPoint:Point = null;
        private var _sequencerBeatIndex:int;
        private var _colorIndex:int;
        function main() {
            addChild(_container = new Sprite());
            _container.x = _container.y = 233;
            g = new graph(_container);
            c = new control(this);
            n = new nowloading(this);
            s = new sound(setup, n.progressCallback, onBeat, onTimerInterruption, onStream);
            _prevTime = getTimer();
            g.setColor(3);
        }
        public function setup() : void {
            _sequencerBeatIndex = -1;
            g.bpm = s.bpm = 120;
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            _container.doubleClickEnabled = true;
            _container.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            _container.addEventListener(MouseEvent.MOUSE_UP,   onMouseUp);
            _container.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            _container.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
        }
        public function onEnterFrame(e:Event) : void {
            var dt:int = getTimer() - _prevTime;
            _prevTime += dt;
            g.update(dt*0.001);
        }
        public function onBeat(e:SiONTrackEvent) : void { g.onBeat(e.eventTriggerID & 31); }
        public function onTimerInterruption() : void { g.onTimerInterruption(_sequencerBeatIndex = (_sequencerBeatIndex+1) & 31); }
        public function onStream(e:SiONEvent) : void { g.onStream(); }
        public function onMouseDown(e:MouseEvent) : void {
            var cx:Number = e.localX, cy:Number = e.localY;
            if (cx*cx+cy*cy>38416) g.message("#Error; CANNOT Create s.e. outer.");
            else {
                if (g.mouseTarget) _mouseDownPoint = new Point(g.mouseTarget.x, g.mouseTarget.y);
                else _mouseDownPoint = new Point(cx, cy);
            }
        }
        public function onMouseUp(e:MouseEvent) : void {
            if (_mouseDownPoint) {
                var dx:Number = e.localX-_mouseDownPoint.x, dy:Number = e.localY-_mouseDownPoint.y,
                    clickRange:Number = (g.mouseTarget) ? 100 : 9;
                if (dx*dx+dy*dy < clickRange) g.onClick(e.localX, e.localY);
                else g.onDraggingEnd(_mouseDownPoint.x, _mouseDownPoint.y, dx, dy);
            }
            _mouseDownPoint = null;
        }
        public function onMouseMove(e:MouseEvent) : void {
            if (_mouseDownPoint) {
                var dx:Number = e.localX-_mouseDownPoint.x, dy:Number = e.localY-_mouseDownPoint.y;
                g.onDragging(_mouseDownPoint.x, _mouseDownPoint.y, dx, dy);
            } else g.onMove(e.localX, e.localY);
        }
        public function onDoubleClick(e:MouseEvent) : void {
            g.setColor(_colorIndex++);
        }
    }
}

import flash.net.*;
import flash.geom.*;
import flash.media.*;
import flash.events.*;
import flash.display.*;
import frocessing.core.*;
import frocessing.geom.*;
import frocessing.display.*;
import frocessing.core.constants.*;
import org.si.sion.*;
import org.si.sion.utils.*;
import org.si.sion.effector.*;
import org.si.sion.events.*;
import org.si.sound.*;
import org.si.utils.*;
import org.si.sion.utils.SiONUtil;
import org.libspark.betweenas3.*;
import org.libspark.betweenas3.easing.*;
import org.libspark.betweenas3.tweens.*;
import com.bit101.components.*;

// global variables
var g:graph, s:sound, c:control, n:nowloading;
var $:F5Drawer = new F5Drawer(), $l:MCLabelDrawer = new MCLabelDrawer();

// F5 drawer
class F5Drawer extends F5Graphics2D {
    public var s:Shape = new Shape();
    function F5Drawer() {
        super(s.graphics);
        colorMode(F5C.HSV,1,1,1,1);
        beginDraw();
    }
    public function render(p:BitmapData, blend:String="normal", mr:Number=1, mg:Number=1, mb:Number=1, ma:Number=1, or:Number=0, og:Number=0, ob:Number=0, oa:Number=0) : BitmapData {
        endDraw(); 
        p.draw(s, new Matrix(1,0,0,1,p.width*0.5,p.height*0.5), new ColorTransform(mr,mg,mb,ma,or,og,ob,oa), blend);
        beginDraw();
        return p;
    }
}

class MCLabelDrawer extends Label {
    function MCLabelDrawer() {
        var c:uint = Style.LABEL_TEXT;
        Style.LABEL_TEXT = 0;
        super(null, 0, 0, "");
        Style.LABEL_TEXT = c;
    }
    public function render(p:BitmapData, str:String, centerx:Number=0, centery:Number=0, scale:Number=1, color:uint=0xffffff, alpha:Number = 1, blend:String="normal") :BitmapData {
        text = str; draw();
        if (!p) p = new BitmapData(this.width*scale, this.height*scale, true, 0);
        var mat:Matrix = new Matrix(scale,0,0,scale,int(p.width*0.5-width*scale*0.5+centerx),int(p.height*0.5-height*scale*0.5+centery));
        var colt:ColorTransform = new ColorTransform(1,1,1,1,(color>>16)&255, (color>>8)&255, color&255, alpha);
        p.draw(this, mat, colt, blend);
        return p;
    }
}

// graphics by Frocessing
class graph extends F5BitmapData2D {
    public var pixels:BitmapData = new BitmapData(400, 400, false, 0), mouseTarget:Ball;
    private var msg:Label, msgboard:BitmapData, lines:Array=new Array(10), msgmat:Matrix = new Matrix(1,0,0,1,5,0);
    private var msgcolt:ColorTransform = new ColorTransform();
    private var rps:Number, angle:Number, prevAngle:Number;
    private var colt:ColorTransform = new ColorTransform(0.92,0.92,0.92);
    private var cls:BitmapData = new BitmapData(400, 400, false, 0);
    private var cursor:BitmapData = new BitmapData(48, 48, false, 0);
    private var curmat:Matrix = new Matrix();
    private var c2dd2t:BitmapData = new BitmapData(64, 28, true, 0);
    private var gradation:Vector.<uint> = new Vector.<uint>(256);
    private var spec:spectrum = new spectrum();
    function graph(parent:DisplayObjectContainer) {
        super(400, 400, false, 0);
        with(parent.addChild(new Bitmap(this.bitmapData))){x=y=-200;};
        with(parent.addChild(new Bitmap(pixels))){x=y=-200;blendMode="add";};
        colorMode(F5C.HSV,1,1,1,1);
        imageMode(F5C.CENTER);
        initialize();
    }
    public function set bpm(n:Number) : void { 
        rps = 0.01308996938995747*n; 
        Ripple.life = 240/n;
    }
    public function initialize() : void {
        prevAngle = angle = 0;
        Ball.beatIndex = 0;
    }
    public function setColor(index:int) : void {
        var hue:Number=index*0.125, i:int, sn:Number, cs:Number, l:Number;
        for (i=0; i<128; i++) {
            gradation[i] = color(hue,1,i*0.0078125,1);
            gradation[i+128] = color(hue,(128-i)*0.0078125,1,1);
        }
        $.noFill(); $.lineStyle(1, gradation[64]);
        $.circle(0, 0, 190); 
        for (i=0; i<8; i++) $.circle(0, 0, i*20+40);
        for (i=0; i<16; i++) $.line(Math.cos(i*0.39269908169872414)*180, Math.sin(i*0.39269908169872414)*180,0,0);
        for (i=0; i<128; i++) {
            sn = Math.sin(i*0.04908738521234052);
            cs = Math.cos(i*0.04908738521234052);
            l = 190-[6,2,4,2][i&3];
            $.line(cs*190, sn*190, cs*l, sn*l);
        }
        $.strokeWeight(3); $.line(200,0,184,0); $.line(-200,0,-184,0); $.line(0,200,0,184); $.line(0,-200,0,-184); 
        cls.fillRect(cls.rect, gradation[16]);
        $.render(cls);
        $.noFill(); $.lineStyle(2, gradation[32]); $.line(0,-15,0,-24); $.line(0,18,0,22); $.lineStyle(2, gradation[8]); $.circle(0,0,18);
        $.render(cursor);
        $l.render(c2dd2t, "Click to Delete", 0, -6, 1, gradation[64]);
        $l.render(c2dd2t, "Drag to Throw", 0, 6, 1, gradation[64]);
        Style.LABEL_TEXT = 0;
        msg = new Label();
        msgcolt = new ColorTransform(1,1,1,1,(gradation[128]>>16)&255, (gradation[128]>>8)&255, gradation[128]&255, 0)
        msgboard = new BitmapData(200, 120, true, 0);
        Ball.createTextures(gradation);
        Ripple.createTextures(gradation);
        spec.createTextures(gradation);
        c.updateColor(msgcolt);
        message("SYSTEM change color(#"+gradation[128].toString(16).substr(2)+")");
    }
    public function message(text:String) : void {
        var i:int;
        lines.push(text);
        lines.shift();
        msgboard.fillRect(msgboard.rect, 0);
        for (i=0, msgmat.ty=0; i<10; i++, msgmat.ty+=11) {
            if (lines[i]) {
                msg.text = lines[i]; msg.draw();
                msgcolt.alphaMultiplier = i * 0.1;
                msgboard.draw(msg, msgmat, msgcolt);
            }
        }
    }
    public function update(dt:Number) : void {
        var i:int, sample:Vector.<Number> = s.output;
        pixels.copyPixels(cls, cls.rect, cls.rect.topLeft);
        bitmapData.colorTransform(bitmapData.rect, colt);
        Ball.update(dt);
        Ripple.update(dt);
        beginDraw();
        noStroke(); fillColor = gradation[128]; fillAlpha = 0.5;
        translate(200, 200);
        angle += rps*dt;
        triangle(Math.sin(prevAngle)*176, Math.cos(prevAngle)*-176, Math.sin(angle)*176, Math.cos(angle)*-176, 0, 0);
        prevAngle = angle;
        if (mouseTarget) {
            curmat.identity();
            curmat.translate(-24, -24);
            curmat.rotate(angle*2);
            curmat.translate(mouseTarget.x+200, mouseTarget.y+200);
            bitmapData.draw(cursor, curmat, null, "add");
            curmat.identity();
            curmat.translate(mouseTarget.x+200+4, mouseTarget.y+200-32);
            pixels.draw(c2dd2t, curmat, null, "add");
        }
        endDraw();
        $.noFill(); $.stroke(gradation[64]); $.strokeWeight(1);
        $.moveTo(-200, 0);
        for (i=0; i<400; i+=2) $.lineTo(i-200, sample[i]*300);
        $.render(pixels);
        pixels.draw(spec, new Matrix(1,0,0,1,306,330), null, "add");
        pixels.copyPixels(msgboard, msgboard.rect, new Point(2,280));
    }
    public function onMove(x:Number, y:Number) : void {
        mouseTarget = Ball.checkNearElement(x, y);
    }
    public function onClick(x:Number, y:Number) : void {
        if (mouseTarget) {
            mouseTarget.destroy();
            g.message("DELETE SE(" + mouseTarget.beat + "," + mouseTarget.note + ");");
            mouseTarget = null;
        } else {
            mouseTarget = Ball.create(x, y);
            g.message("CREATE stable SE(" + mouseTarget.beat + "," + mouseTarget.note + ");");
        }
    }
    public function onDragging(x:Number, y:Number, dx:Number, dy:Number) : void {
        if (dx*dx+dy*dy >= 9) {
            beginDraw();
            lineStyle(1, gradation[64]);
            line(x+200, y+200, x+dx+200, y+dy+200);
            endDraw();
        }
    }
    public function onDraggingEnd(x:Number, y:Number, dx:Number, dy:Number) : void {
        var vx:Number = dx * 0.2, vy:Number = dy * 0.2;
        if (mouseTarget) {
            mouseTarget.vx = vx;
            mouseTarget.vy = vy;
            mouseTarget = null;
            g.message("SET SE velocity(" + vx.toFixed(2) + "," + vy.toFixed(2) + ");");
        } else {
            var b:Ball = Ball.create(x, y, vx, vy);
            g.message("CREATE moving SE(" + b.beat + "," + b.note +  "," + vx.toFixed(2) + "," + vy.toFixed(2) + ");");
        }
    }
    public function onBeat(b:int) : void {
        if ((b&3)==0) angle = (b>>2) * 0.7853981633974483;
        Ball.beatIndex = b;
    }
    public function onTimerInterruption(sequencerBeatIndex:int) : void {
        Ball.onTimerInterruption(sequencerBeatIndex);
    }
    public function onStream() : void {
        spec.update();
    }
}

class Ball {
    static public var beatIndex:int = -1;
    public var x:Number, y:Number, vx:Number, vy:Number, beat:int, note:int;
    static public var freeList:Array = [], activeList:Array = [];
    static public var texture:BitmapData;
    static public var field:BitmapData = new BitmapData(400, 400, false, 0);
    function Ball() {}
    static public function createTextures(grad:Vector.<uint>) : void {
        $.fill(grad[32]);$.stroke(grad[128]); $.strokeWeight(1);
        $.triangle(0,-4,-3,2,3,2);
        $.render(texture = new BitmapData(10, 10, false, 0));
    }
    static public function create(x:Number, y:Number, vx:Number=0, vy:Number=0) : Ball {
        var ball:Ball = freeList.pop() || new Ball();
        ball.x = x;
        ball.y = y;
        ball.vx = vx;
        ball.vy = vy;
        ball.updateNote();
        activeList.push(ball);
        Ripple.create(ball.x, ball.y);
        s.playSample(ball.note, 128, 1);
        return ball;
    }
    public function destroy() : void {
        activeList.splice(activeList.indexOf(this), 1);
        freeList.push(this);
        Ripple.create(x, y);
        s.playSample(note, 128, 1);
    }
    public function updateNote() : void {
        beat = int(Math.atan2(x, -y) * 5.092958178940651 + 0.5);
        note = int(Math.sqrt(x*x+y*y)*0.065) - 2; // 1/200*13
        if (beat < 0) beat += 32;
        if (note < 0) note = 0;
        else if (note > 9) note = 9;
    }
    static public function update(dt:Number) : void {
        var b:Ball, i:int, imax:int = activeList.length, 
            pix:BitmapData = g.pixels, mat:Matrix = new Matrix();
        for (i=0; i<imax; i++) {
            b = activeList[i];
            b.x += b.vx * dt;
            b.y += b.vy * dt;
            mat.identity();
            mat.translate(b.x+195, b.y+195);
            pix.draw(texture, mat, null, "add");
            if (beatIndex == b.beat) Ripple.create(b.x, b.y);
            if (b.vx != 0 || b.vy != 0) {
                b.updateNote();
                if (b.x*b.x+b.y*b.y>38416) {
                    activeList.splice(i, 1);
                    freeList.push(b);
                    i--;
                    imax--;
                    g.message("#Warning; S.E. escaped.");
                }
            }
        }
        beatIndex = -1;
    }
    static public function onTimerInterruption(sequencerBeatIndex:int) : void {
        var b:Ball, i:int, imax:int = activeList.length;
        for (i=0; i<imax; i++) {
            b = activeList[i];
            if (b.beat == sequencerBeatIndex) s.playSample(b.note, 128, 0);
        }
    }
    static public function checkNearElement(x:Number, y:Number) : Ball {
        var b:Ball, nearest:Ball, dx:Number, dy:Number, len2:Number, i:int, imax:int = activeList.length;
        for (i=0, nearest=null, len2=100; i<imax; i++) {
            b = activeList[i];
            if (b.vx != 0 || b.vy != 0) continue;
            dx = b.x - x;
            dy = b.y - y;
            if (dx*dx+dy*dy < len2) {
                len2 = dx*dx+dy*dy;
                nearest = b;
            }
        }
        return nearest;
    }
}

class Ripple {
    public var x:Number, y:Number, rot:Number, alpha:Number, age:int, tween:ITween;
    static public var freeList:Array = [], activeList:Array = [], life:Number = 2;
    static public var texture0:BitmapData, texture1:BitmapData;
    function Ripple() {}
    static public function createTextures(grad:Vector.<uint>) : void {
        var i:int, j:int, a:Number, qsample:BitmapData = new BitmapData(256,256,false,0), shrink:Matrix = new Matrix(0.25,0,0,0.25,0,0);
        $.noStroke();
        $.texture($l.render(null, "|  SONAR Synth. |  SONAR Synth. ", 0, 0, 4, grad[64]));
        $.beginShape(F5C.TRIANGLE_STRIP);
        for (a=0, j=0; j<64; j++, a+=0.09817477042468103) {
            $.vertex(Math.cos(a)*128,Math.sin(a)*128,j*0.015625,0);
            $.vertex(Math.cos(a)*80,Math.sin(a)*80,j*0.015625,1);
        }
        $.endShape();
        $.render(qsample);
        texture0 = new BitmapData(64, 64, false, 0);
        texture0.draw(qsample, shrink, null, "add", null, true);
        qsample.dispose();
        $.noStroke();
        $.fillGradient("radial", 0, 0, 32, 0, [grad[160],grad[160],grad[0]], [1,1], [0,32,255]);
        $.rect(-32,-32,64,64);
        $.render(texture1 = new BitmapData(64, 64, false, 0));
    }
    static public function create(x:Number, y:Number) : Ripple {
        var ripple:Ripple = freeList.pop() || new Ripple();
        ripple.x = x;
        ripple.y = y;
        ripple.rot = 0;
        ripple.alpha = 1;
        ripple.age = -1;
        activeList.push(ripple);
        ripple.tween = BetweenAS3.to(ripple, {'rot':3.141592653589793, 'alpha':0}, life, Linear.linear);
        ripple.tween.play();
        g.bitmapData.draw(texture1, new Matrix(1,0,0,1,x+200-32,y+200-32), null, "add");
        return ripple;
    }
    static public function update(dt:Number) : void {
        var ripple:Ripple, i:int, imax:int = activeList.length, 
            mat:Matrix = new Matrix(), pt:Point = new Point(), 
            colt:ColorTransform = new ColorTransform();
        for (i=0; i<imax; i++) {
            ripple = activeList[i];
            mat.identity();
            mat.translate(-32, -32);
            mat.rotate(ripple.rot);
            mat.translate(ripple.x+200, ripple.y+200);
            colt.alphaMultiplier = ripple.alpha;
            g.pixels.draw(texture0, mat, colt, "add");
            if (!ripple.tween.isPlaying) {
                activeList.splice(i, 1);
                freeList.push(ripple);
                i--;
                imax--;
            }
        }
    }
}

// sounds by SiON
class sound {
    private var jamPresetVoice:JAMPresetVoice, sion:SiONDriver, dm:DrumMachine, eq:SiEffectEqualiser;
    private var delayBuffer:Vector.<Number> = new Vector.<Number>(512), _onLoad:Function, _onStream:Function;
    function sound(onload:Function, onprogress:Function, onbeat:Function, ontimer:Function, onstream:Function) {
        sion = new SiONDriver();
        sion.noteOnExceptionMode = SiONDriver.NEM_IGNORE;
        sion.setBeatCallbackInterval(1);
        sion.setTimerInterruption(1, ontimer);
        sion.addEventListener(SiONTrackEvent.BEAT, onbeat);
        sion.addEventListener(SiONEvent.STREAM, _onStreamInternal);
        _onLoad = onload;
        _onStream = onstream;
        dm = new DrumMachine(0,8,2,3,2,0);
        jamPresetVoice = new JAMPresetVoice(_onLoadInternal, onprogress);
    }
    public function set bpm(n:Number) : void { sion.bpm = n; }
    public function get output() : Vector.<Number> { return delayBuffer; }
    public function playSample(sampleNumber:int, volume:int, quant:int) : void {
        sion.noteOn(60, jamPresetVoice[sampleNumber], 4, 0, quant, sampleNumber).masterVolume = volume;
    }
    public function setEQ(l:Number, m:Number, h:Number) : void { eq.setParameters(l, m, h); }
    private function _onLoadInternal() : void {
        dm.volume = 0.3;
        sion.effector.slot0 = [eq = new SiEffectEqualiser()];
        sion.fadeIn(4);
        sion.play("%%5@2@v28@f40,2,60,32,,,72,60q8s24l8o3$[d<d]4>2[b-<b-]4[c<c]4>2[a<a]c<c>c+<c+", false);
        dm.play();
        _onLoad();
    }
    private function _onStreamInternal(e:SiONEvent) : void {
        _onStream(e);
        var out:Vector.<Number> = sion.module.output, i:int, j:int;
        for (i=0, j=2; i<512; i++, j+=8) delayBuffer[i] = out[j];
    }
}

class spectrum extends BitmapData {
    private var fft:FFT = new FFT(512), its:Vector.<Number> = new Vector.<Number>(256);
    private var data:Vector.<Number> = new Vector.<Number>(512);
    private var hamm:Vector.<Number> = new Vector.<Number>(512);
    private var texture:BitmapData, cls:BitmapData, ZEROPOINT:Point = new Point();
    function spectrum() {
        super(88, 64, false, 0);
        for (var i:int=0; i<512; i++) hamm[i] = 0.54-Math.cos(i*0.01227184)*0.46;
    }
    
    public function createTextures(grad:Vector.<uint>) : void {
        texture = new BitmapData(5, 60, false, 0);
        cls = new BitmapData(88, 64, false, 0);
        for (var r:Rectangle = new Rectangle(0,0,5,2); r.y<60; r.y+=3) {
            r.x = 0;
            texture.fillRect(r,grad[40]);
            for (r.x=4; r.x<88; r.x+=6) cls.fillRect(r,grad[12]);
        }
        $.stroke(grad[40]); $.moveTo(-43,-31); $.lineTo(-43,29); $.lineTo(43,29); $.render(cls);
    }
    
    public function update() : void {
        var sample:Vector.<Number> = s.output, i:int, bit:int, s0:Number, s1:Number, i0:int, i1:int, imax:int,
            rc:Rectangle = new Rectangle(0,0,9,4), pt:Point = new Point();
        for (i=0; i<512; i++) data[i] = sample[i] * hamm[i];
        fft.setData(data).calcRealFFT().getIntensity(its);
        copyPixels(cls, rect, ZEROPOINT);
        for (bit=0; bit<7; bit++) {
            imax = 1<<bit;
            for(s0=s1=0, i0=imax*2, i1=imax*3, i=0; i<imax; i++, i0++, i1++) {
                s0 += its[i0];
                s1 += its[i1];
            }
            pt.x = bit * 12 + 4;
            rc.height = int(Math.log(s0)*3) * 3;
            if (rc.height > 60) rc.height = 60;
            pt.y = rc.y = 60 - rc.height;
            copyPixels(texture, rc, pt);
            pt.x = bit * 12 + 10;
            rc.height = int(Math.log(s1)*3) * 3;
            if (rc.height > 60) rc.height = 60;
            pt.y = rc.y = 60 - rc.height;
            copyPixels(texture, rc, pt);
        }
    }
}

// nowloading
class nowloading extends F5BitmapData2D {
    private var _bitmap:Bitmap, _label:Label = new Label(), _prog:Number, _progDraw:Number;
    function nowloading(parent:DisplayObjectContainer) {
        super(465,465,true,0xffffffff);
        _progDraw = _prog = 0;
        parent.addChild(_bitmap = new Bitmap(bitmapData));
        parent.addEventListener(Event.ENTER_FRAME, function(e:Event):void {
            _progDraw += (_prog - _progDraw) * 0.2;
            if (_progDraw > 0.95 && _prog == 1) {
                e.target.removeEventListener(e.type, arguments.callee);
                BetweenAS3.serial(BetweenAS3.to(_bitmap, {"alpha":0}, 1), BetweenAS3.removeFromParent(_bitmap)).play();
                _progDraw = 1;
            }
            beginDraw();fill(255,255,255);rect(0,0,465,465);lineStyle(10,0xc0c0c0,1);
            arc(232,232,100,100,-1.5707963267948965+_progDraw*6.283185307179586,-1.5707963267948965);endDraw();
            _label.text = ("LOADING... [" + int(_progDraw*100).toString() + "%]");_label.draw();
            bitmapData.draw(_label, new Matrix(1,0,0,1,int(232.5-_label.width*0.5),226));
        });
    }
    public function progressCallback(prog:Number) : void { _prog = prog; }
}

// control panel
class control extends Sprite {
    private var high:Knob, mid:Knob, low:Knob, highVal:Label, midVal:Label, lowVal:Label, bpmKnob:Knob;
    private var eqt:Vector.<Number> = new Vector.<Number>(101), moving:Boolean;
    function control(parent:DisplayObjectContainer) {
        super();
        Style.BACKGROUND = Style.LABEL_TEXT = 0;
        Style.BUTTON_FACE = 0;
        for (var i:int=0; i<101; i++) eqt[i] = Math.pow(2, i*0.04-2);
        bpmKnob = _newKnob(10, "BPM",   80, 160, 120, function(e:Event) : void {
            s.bpm=g.bpm=bpmKnob.value;
            g.message("CHANGE bpm(" + int(bpmKnob.value).toString() + ");");
        });
        low = _newKnob(314, "Low",    0, 100,  50, _updateEQ);
        mid = _newKnob(344, "Middle", 0, 100,  50, _updateEQ);
        high =_newKnob(374, "High",   0, 100,  50, _updateEQ);
        lowVal  = new Label(this, 312, 35, "1.00");
        midVal  = new Label(this, 342, 35, "1.00");
        highVal = new Label(this, 372, 35, "1.00");
        bpmKnob.showValue = true;
        x = 32;
        y = 32;
        parent.addChild(this);
    }
    public function updateColor(colt:ColorTransform) : void {
        low.transform.colorTransform = colt;
        mid.transform.colorTransform = colt;
        high.transform.colorTransform = colt;
        lowVal.transform.colorTransform = colt;
        midVal.transform.colorTransform = colt;
        highVal.transform.colorTransform = colt;
        bpmKnob.transform.colorTransform = colt;
    }
    public function set bpm(n:Number) : void { bpmKnob.value = n; }
    private function _newKnob(x:Number, label:String, min:Number, max:Number, val:Number, onChange:Function) : Knob {
        var knob:Knob = new Knob(this, x, 0, label, onChange);
        knob.radius = 8;
        knob.labelPrecision = 0;
        knob.minimum = min;
        knob.maximum = max;
        knob.value = val;
        knob.showValue = false;
        return knob;
    }
    private function _updateEQ(e:Event) : void {
        var l:Number = eqt[int(low.value)], m:Number = eqt[int(mid.value)], h:Number = eqt[int(high.value)],
            lt:String = l.toFixed(2), mt:String = m.toFixed(2), ht:String = h.toFixed(2);
        s.setEQ(l, m, h);
        lowVal.text = lt;
        midVal.text = mt;
        highVal.text = ht;
        g.message("CHANGE equalizer(" + lt + "," + mt + "," + ht + ");");
    }
}

// SiON Voice List of JAM session4's mp3 data. 
// Access SiONVoices with hash keys like ["drop1.mp3"], or indecies of [0]~[9].
// And Key of ["droppcm.mp3"] is for PCM voice.
dynamic class JAMPresetVoice {
    private var _onLoad:Function, _onProgress:Function, _requestedCount:int = -1, _loadedCount:int = 0;
    static private const _mp3home:String = "http://assets.wonderfl.net/sounds/event/jam/";

    public function get loadingProgression() : Number { return _loadedCount/_requestedCount; }
    
    function JAMPresetVoice(onload:Function=null, onprogress:Function=null, urllist:Array=null) {
        _onLoad = onload;
        _onProgress = onprogress;
        urllist = urllist || [];
        var i:int, sound:Sound, jpv:JAMPresetVoice = this;
        for (i=0; i<10; i++) urllist.unshift(_mp3home + "drop" + String(10-i) + ".mp3");
        _requestedCount = urllist.length;
        _loadedCount = 0;
        for (i=0; i<_requestedCount; i++) {
            sound = new Sound(new URLRequest(urllist[i]));
            sound.addEventListener(Event.COMPLETE, _complete(i, sound));
        }
        function _complete(sampleNumber:int, sound:Sound) : Function {
            return function(e:Event) : void {
                e.target.removeEventListener(e.type, arguments.callee);
                var voice:SiONVoice = new SiONVoice();
                var silentLength:int = SiONUtil.getHeadSilence(sound, 0.01);
                voice.setMP3Voice(sound).slice(silentLength);
                voice.name = sound.url.match(/[\w_]+\.mp3$/)[0];
                jpv[sampleNumber] = jpv[voice.name] = voice;
                if (voice.name == "drop3.mp3") {
                    voice = new SiONVoice();
                    voice.setPCMVoice(sound).slice(silentLength);
                    voice.name = "droppcm.mp3";
                    jpv[_requestedCount] = jpv[voice.name] = voice;
                }
                ++_loadedCount;
                if (_onProgress != null) _onProgress(loadingProgression);
                if (_loadedCount == _requestedCount && _onLoad != null) _onLoad();
            };
        }
    }
}
