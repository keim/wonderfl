package {
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import org.si.sion.events.*;
    
    [SWF(width="465", height="465", backgroundColor="0xffffff", frameRate="30")]
    public class main extends Sprite {
        private var _prevTime:int;
        function main() {
            g = new graph(this);
            c = new control(this);
            s = new sound(setup, progressCallback, onBeat);
            n = new nowloading(this, s.start);
            _prevTime = getTimer();
        }
        public function setup() : void {
            g.bpm = s.bpm = 88;
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            stage.addEventListener(MouseEvent.CLICK, onClick);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }
        public function onEnterFrame(e:Event) : void {
            var dt:int = getTimer() - _prevTime;
            _prevTime += dt;
            g.update(dt*0.001);
        }
        public function onBeat(e:SiONTrackEvent) : void {
            switch(e.eventTriggerID) {
            case 64:  g.message = 'wonderfl x jsdo.it'; break;
            case 128: g.message = 'HTML5 x Flash'; break;
            case 192: g.message = '- JAM session 4 -,presented by TAKASHI YAMAGCHI @ d.v.d'; break;
            case 256: g.message = '" The Instrument "'; break;
            case 384: g.message = 'powered by SiON'; break;
            case 424: s.gotoTitle(); break;
            }
        }
        public function onClick(e:MouseEvent) : void {
            g.onClick((e.localX-232.5)*0.005, (e.localY-232.5)*0.005)
        }
        public function onMouseMove(e:MouseEvent) : void {
            if (e.localY < 60) c.open();
            else if (e.localY > 240) c.close();
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
import org.si.sion.sequencer.*;
import org.si.sion.effector.*;
import org.si.sion.events.*;
import org.si.sound.*;
import org.si.sion.utils.SiONUtil;
import org.libspark.betweenas3.*;
import org.libspark.betweenas3.easing.*;
import org.libspark.betweenas3.tweens.*;
import com.bit101.components.*;

// global variables
var g:graph, s:sound, c:control, n:nowloading;
var $:F5Drawer = new F5Drawer();

// F5 drawer
class F5Drawer extends F5Graphics2D {
    public var s:Shape = new Shape();
    function F5Drawer() { super(s.graphics); colorMode(F5C.HSV,1,1,1,1); beginDraw(); }
    public function draw(p:BitmapData, blend:String="normal", mr:Number=1, mg:Number=1, mb:Number=1, ma:Number=1, or:Number=0, og:Number=0, ob:Number=0, oa:Number=0) : BitmapData {
        endDraw(); p.draw(s, new Matrix(1,0,0,1,p.width*0.5,p.height*0.5), new ColorTransform(mr,mg,mb,ma,or,og,ob,oa), blend); beginDraw(); return p;
    }
}

// graphics by Frocessing3D
class graph extends F5BitmapData3D {
    private var scroll:Number = 1, scrollSpeed:Number = 2, rot:Number = 0, omg:Number = 0, bgcolor:Number = 0;
    private var lightMatrix:Vector.<Number> = new Vector.<Number>(88);
    private var msg:Label, back:BitmapData = new BitmapData(400,400,true,0);
    function graph(parent:DisplayObjectContainer) {
        super(400, 400, false, 0);
        with(parent.addChild(new Bitmap(this.bitmapData))){x=y=32;};
        colorMode(F5C.HSV,1,1,1,1);
        imageMode(F5C.CENTER);
        backFaceCulling = true;
        initialize();
    }
    public function set bpm(n:Number) : void { scrollSpeed = (n-60)*0.08; }
    public function initialize() : void {
        for (var i:int=0; i<88; i++) lightMatrix[i] = 0;
        lightMatrix[30] = 1;
        Ball.initialize();
        Style.LABEL_TEXT = color(0.6, 0.5, 0.2);
        msg = new Label();
    }
    public function set message(text:String) : void {
        var i:int, lines:Array = text.split(',');
        msg.text = lines[0]; msg.draw();
        back.fillRect(back.rect, 0);
        back.draw(msg, new Matrix(2, 0, 0, 2, 200 - msg.width, 184 - lines.length * 6));
        for (i=1; i<lines.length; i++) {
            msg.text = lines[i]; msg.draw();
            back.draw(msg, new Matrix(1, 0, 0, 1, 200 - msg.width * 0.5, 216 + i * 12));
        }
    }
    public function update(dt:Number) : void {
        var iz:Number, ix:Number, iy:Number, i:int, c:Number, b:BitmapData = bitmapData;
        b.fillRect(b.rect, color(0.6, 1, bgcolor));
        b.copyPixels(back, b.rect, b.rect.topLeft);
        beginDraw();
        translate(200, 200);
        scale(2.5);
        rotateZ(rot);
        strokeWeight(1);
        for (i=0, iz=scroll*200; iz<2000; iz+=200) {
            stroke(0.6, 0.5, 1, 1-iz * 0.0005);
            moveTo(-400,-200,-iz);lineTo( 400,-200,-iz);lineTo( 600,-100,-iz);
            lineTo( 600, 100,-iz);lineTo( 400, 200,-iz);lineTo(-400, 200,-iz);
            lineTo(-600, 100,-iz);lineTo(-600,-100,-iz);lineTo(-400,-200,-iz);
            for (ix=-400; ix<=400; ix+=100) {
                line3d(ix,-200,-iz,ix,-200,-iz-200);
                line3d(ix, 200,-iz,ix, 200,-iz-200);
            }
            line3d(-600,-100,-iz,-600,-100,-iz-200);
            line3d( 600,-100,-iz, 600,-100,-iz-200);
            line3d(-600, 100,-iz,-600, 100,-iz-200);
            line3d( 600, 100,-iz, 600, 100,-iz-200);
            noStroke();
            for (ix=-400; ix<=350; ix+=100, i++) {
                c = lightMatrix[i];
                if (c > 0) {
                    fill(0.6, 1-c, 1, c);
                    beginShape(F5VertexMode.QUAD_STRIP);
                    vertex3d(ix+10, 200,-iz-180);
                    vertex3d(ix+10,-200,-iz-180);
                    vertex3d(ix+10, 200,-iz-20);
                    vertex3d(ix+10,-200,-iz-20);
                    vertex3d(ix+90, 200,-iz-20);
                    vertex3d(ix+90,-200,-iz-20);
                    vertex3d(ix+90, 200,-iz-180);
                    vertex3d(ix+90,-200,-iz-180);
                    endShape();
                    lightMatrix[i] = c * 0.9;
                    if (lightMatrix[i] < 0.01) lightMatrix[i] = 0;
                }
            }
        }
        Ball.update(dt);
        endDraw();
        
        scroll -= scrollSpeed * dt;
        while (scroll<0) {
            scroll+=1;
            for (i=8; i<88; i++) lightMatrix[i-8] = lightMatrix[i];
            for (i=80; i<88;  i++) lightMatrix[i] = 0;
        }
        
        rot += omg * dt;
        if (rot>6.283185307179586) rot -= 6.283185307179586;
        else if (rot<0) rot += 6.283185307179586;
        omg += Math.random()*0.06-0.03;
        omg *= 0.99;
        
        bgcolor *= 0.9;
    }
    public function onClick(x:Number, y:Number) : void {
        var lcr:int = (x<-0.3)?2:(x>0.3)?0:1;
        omg -= lcr * 0.05 - 0.05;
        var si:int = int(Math.random()*4)+lcr*3;
        Ball.create(si*80-360,(rot<1.5707963267948965||rot>=4.71238898038469),si);
    }
    public function boundAt(x:Number, z:Number) : void {
        var index:int = int(-z*0.005+scroll) * 8 + int((x + 400) / 100);
        if (index < 88) lightMatrix[index] = 1;
        var newbgcolor:Number = 1+z*0.0003;
        if (newbgcolor>bgcolor) bgcolor = newbgcolor;
    }
    public function titleSoundHandler() : void {
        message = 'Bound Ball Synthesizer 2,created by keim_at_Si';
        bgcolor = 8;
    }
}

class Ball {
    public var x:Number, y:Number ,z:Number, vx:Number, vy:Number, vz:Number, g:Number, si:int, sounded:Boolean;
    static public var freeList:Array = [], activeList:Array = [], tex:BitmapData = new BitmapData(128, 128, true, 0);
    static public var latency:Number = 0.2; // 200ms
    function Ball() {}
    static public function initialize() : void {
        $.noStroke();
        $.fillGradient("radial", 0, 0, 64, 0, [0xffffff,0xffffff,0xffffff,0xffffff], [1.0,1.0,0.4,0], [0,64,72,255]);
        $.rect(-64,-64,128,128);
        $.draw(tex);
    }
    static public function create(x:Number, gravity:Boolean, si:int) : void {
        var ball:Ball = freeList.pop() || new Ball();
        ball.x = x;
        ball.y = -200;
        ball.z = 0;
        ball.vx = 0;
        ball.vy = 1500*(Math.random()*0.25+0.5);
        ball.vz = -Math.random()*500-700;
        ball.g = -1500;
        ball.si = si;
        ball.sounded = false;
        if (gravity) {
            ball.x = -ball.x;
            ball.y = -ball.y;
            ball.vy = -ball.vy;
            ball.g = -ball.g;
        }
        activeList.push(ball);
        s.playSample(si,128);
    }
    static public function update(dt:Number) : void {
        var b:Ball, i:int, predY:Number, imax:int = activeList.length;
        for (i=0; i<imax; i++) {
            b = activeList[i];
            b.vy += b.g * dt;
            b.x += b.vx * dt;
            b.y += b.vy * dt;
            b.z += b.vz * dt;
            if (b.z < -2000) {
                activeList.splice(i, 1);
                freeList.push(b);
                i--;
                imax--;
            } else {
                if (!b.sounded) {
                    predY = b.y + b.vy * latency + b.g * latency * latency * 0.5;
                    if (predY < -200 || predY >200) {
                        b.sounded = true;
                        s.playSample(b.si, 128+b.z*0.048);
                    }
                }
                if (b.y < -200) { 
                    b.y = -200;
                    b.vy = -b.vy * 0.96;
                    g.boundAt(b.x, b.z);
                    b.sounded = false;
                } else if (b.y > 200) {
                    b.y = 200;
                    b.vy = -b.vy * 0.96;
                    g.boundAt(b.x, b.z);
                    b.sounded = false;
                }
                g.image2d(tex, b.x, b.y, b.z);
            }
        }
    }
}

// sounds by SiON
class sound {
    public var accel:Boolean = true;
    private var jamPresetVoice:JAMPresetVoice, sion:SiONDriver, dm:DrumMachine, eq:SiEffectEqualiser, titleSeq:SiONData;
    function sound(onload:Function, onprogress:Function, onbeat:Function) {
        sion = new SiONDriver();
        sion.addEventListener(SiONTrackEvent.BEAT, onbeat);
        sion.addEventListener(SiONTrackEvent.NOTE_ON_FRAME, _onNoteOn);
        titleSeq = sion.compile("%2q0s32l16v4[cc(]16;%2@1,48,12,0,12,15@f64,2,12,0,0,0,0o6q8r1^1%e1,1,0c1^1");//)
        dm = new DrumMachine(0,2,0,0,2,0);
        jamPresetVoice = new JAMPresetVoice(onload, onprogress);
    }
    public function set bpm(n:Number) : void { sion.bpm = n; }
    public function start() : void {
        dm.volume = 0.3;
        sion.effector.slot0 = [eq = new SiEffectEqualiser()];
        sion.fadeIn(4);
        sion.play("%3@3@v48@fb4@f72,1q5s48l8o1$[[d.]4|<cd]c4>%e0,1,0", false);
        dm.play();
    }
    public function playSample(sampleNumber:int, volume:int) : void {
        sion.noteOn(60, jamPresetVoice[sampleNumber], 4, 0, 1).masterVolume = volume;
    }
    public function gotoTitle() : void {
        sion.sequenceOn(titleSeq, null, 0, 0, 32);
    }
    public function setEQ(l:Number, m:Number, h:Number) : void {
        eq.setParameters(l, m, h);
    }
    private function _onNoteOn(e:SiONTrackEvent) : void {
        Ball.latency = sion.latency * 0.001;
        if (Ball.latency > 0.5) Ball.latency = 0.5; 
        if (e.eventTriggerID == 1) g.titleSoundHandler();
        else if (accel) {
            sion.bpm += 4;
            if (sion.bpm > 144) sion.bpm = 144;
            g.bpm = c.bpm = sion.bpm;
        }
    }
}

// nowloading
function progressCallback(prog:Number) : void { n.progression = prog; }
class nowloading extends F5BitmapData2D {
    public var progression:Number;
    private var _bitmap:Bitmap, _label:Label = new Label(), _progDraw:Number;
    function nowloading(parent:DisplayObjectContainer, onComplete:Function) {
        super(465,465,true,0xffffffff);
        _progDraw = progression = 0;
        parent.addChild(_bitmap = new Bitmap(bitmapData));
        parent.addEventListener(Event.ENTER_FRAME, function(e:Event):void {
            _progDraw += (progression - _progDraw) * 0.2;
            if (_progDraw > 0.95 && progression == 1) {
                e.target.removeEventListener(e.type, arguments.callee);
                BetweenAS3.serial(BetweenAS3.to(_bitmap, {"alpha":0}, 1), BetweenAS3.removeFromParent(_bitmap), BetweenAS3.func(onComplete)).play();
                _progDraw = 1;
            }
            beginDraw();fill(255,255,255);rect(0,0,465,465);lineStyle(10,0xc0c0c0,1);
            arc(232,232,100,100,-1.5707963267948965+_progDraw*6.283185307179586,-1.5707963267948965);endDraw();
            _label.text = ("LOADING... [" + int(_progDraw*100).toString() + "%]");_label.draw();
            bitmapData.draw(_label, new Matrix(1,0,0,1,int(232.5-_label.width*0.5),226));
        });
    }
}

// control panel
class control extends Sprite {
    private var high:Knob, mid:Knob, low:Knob, highVal:Label, midVal:Label, lowVal:Label, bpmKnob:Knob, accel:CheckBox;
    private var eqt:Vector.<Number> = new Vector.<Number>(101), moving:Boolean;
    function control(parent:DisplayObjectContainer) {
        super();
        for (var i:int=0; i<101; i++) eqt[i] = Math.pow(2, i*0.04-2);
        bpmKnob = _newKnob(20, "BPM",   88, 144, 100, function(e:Event) : void { s.bpm=g.bpm=bpmKnob.value; });
        low = _newKnob(280, "Low",    0, 100,  50, _updateEQ);
        mid = _newKnob(320, "Middle", 0, 100,  50, _updateEQ);
        high =_newKnob(360, "High",   0, 100,  50, _updateEQ);
        lowVal  = new Label(this, 276, 38, "1.00");
        midVal  = new Label(this, 316, 38, "1.00");
        highVal = new Label(this, 356, 38, "1.00");
        accel = new CheckBox(this, 50, 20, "accel.", function(e:Event) : void { s.accel = accel.selected; });
        new RadioButton(this, 100, 10, "low quality",  false,function(e:Event) : void { stage.quality = "low";  }).groupName = "quality";
        new RadioButton(this, 100, 30, "high quality", true, function(e:Event) : void { stage.quality = "best"; }).groupName = "quality";
        accel.selected = true;
        bpmKnob.showValue = true;
        x = 32;
        y = -60;
        visible = false;
        graphics.beginFill(0xffffff, 0.5);
        graphics.drawRect(0,0,465,60);
        parent.addChild(this);
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
        var l:Number = eqt[int(low.value)], m:Number = eqt[int(mid.value)], h:Number = eqt[int(high.value)];
        s.setEQ(l, m, h);
        lowVal.text = l.toFixed(2);
        midVal.text = m.toFixed(2);
        highVal.text = h.toFixed(2);
    }
    public function open() : void {
        if (!moving) {
            moving = true;
            visible = true;
            BetweenAS3.serial(BetweenAS3.to(this, {"y":32}, 1, Bounce.easeOut), BetweenAS3.func(function():void{ moving = false;})).play();
        }
    }
    public function close() : void {
        if (visible && !moving) {
            moving = true;
            BetweenAS3.serial(BetweenAS3.to(this, {"y":-60}, 1, Bounce.easeOut), BetweenAS3.func(function():void{ moving = visible = false;})).play();
        }
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

