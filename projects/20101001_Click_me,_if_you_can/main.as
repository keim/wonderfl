package {
    import flash.net.*;
    import flash.events.*;
    import flash.display.*;
    import flash.utils.*;
    import com.bit101.components.*;
    import net.wonderfl.score.basic.*;
    
    [SWF(frameRate='24',backgroundColor='#000000')]
    public class main extends Sprite {
    //---------------------------------------- variables
        private var hiscore:int;
        
    //---------------------------------------- constructor
        function main() {
            var me:Sprite = this;
            addEventListener(Event.ADDED_TO_STAGE, function(e:Event) : void {
                removeEventListener(e.type, arguments.callee);
                Style.LABEL_TEXT = 0xf0f0ff;
                Style.BUTTON_FACE = 0x606060;
                setup();
                _startTitle();
                addEventListener("enterFrame", function(e:Event) : void {
                    phaseMain[phase]();
                });
            });
        }
        
    //---------------------------------------- setup
        private function setup() : void {
            hiscore = 0;
            ClickPoint.initialize(this, 144);
            SoundManager.initialize(this, 144);
            _tweetButton(190, 440);
        }
        
        private function _tweetButton(x:Number, y:Number) : PushButton {
            return new PushButton(this, x, y, "TWEET SCORE", function(e:Event) : void {
                navigateToURL(new URLRequest("http://twitter.com/home/?status=" + escapeMultiByte("[Click me, if you can] score:" + String(hiscore) + " #wonderfl http://wonderfl.net/c/n4Ku/")), "_blank");
            });
        }
        
    //---------------------------------------- phases
        private var phase:int=0, nextPhase:int = -1;
        private var TITLE:int=0, MAIN:int=1, GAMEOVER:int=2, RESULT:int=3;
        private var phaseStart:Array = [_startTitle, _startMain, _startGameover, _startResult];
        private var phaseMain:Array  = [_loop,       _loopMain,  _loop,          _loopResult];
        private var phaseEnd:Array   = [_endTitle,   _endMain,   _doNothing,     _doNothing];
        private function _doNothing() : void {}
        
        private function _changePhase(p:int) : void {
            if (nextPhase == -1) {
                nextPhase = p;
                phaseEnd[phase]();
                do {
                    phase = nextPhase
                    phaseStart[phase]();
                } while (phase != nextPhase);
                nextPhase = -1;
            } else {
                nextPhase = p;
            }
        }
        
    //---------------------------------------- TITLE phase
        private function _loop() : void {
            ClickPoint.update();
        }
        private function _startTitle() : void {
            ClickPoint.showMessage("Click me, if you can", 0);
            addEventListener(MouseEvent.CLICK, _onTiitleClicked);
        }
        private function _endTitle() : void {
        }
        private function _onTiitleClicked(e:MouseEvent) : void {
            removeEventListener(MouseEvent.CLICK, _onTiitleClicked);
            _changePhase(MAIN);
        }
        
    //---------------------------------------- MAIN phase
        private function _startMain() : void {
            ClickPoint.showMessage("START !", 2);
            ClickPoint.reset();
            ClickPoint.enabled = true;
            SoundManager.play();
        }
        private function _loopMain() : void {
            if (!ClickPoint.update()) _changePhase(GAMEOVER);
        }
        private function _endMain() : void {
            ClickPoint.enabled = false;
        }
        
    //---------------------------------------- GAMEOVER phase
        private function _startGameover() : void {
            if (hiscore < ClickPoint.score) {
                hiscore = ClickPoint.score;
            }
            ClickPoint.showMessage("Game Over", 0);
            SoundManager.stop();
            addEventListener(MouseEvent.CLICK, _onGameoverClicked);
        }
        private function _onGameoverClicked(e:MouseEvent) : void {
            removeEventListener(MouseEvent.CLICK, _onGameoverClicked);
            _changePhase(RESULT);
        }
        
    //---------------------------------------- RESULT phase
        private var bsf:BasicScoreForm, bsrv: BasicScoreRecordViewer, exitLoop:Boolean;
        private function _startResult() : void {
            if (hiscore == ClickPoint.score) {
                Style.LABEL_TEXT = 0x808080;
                bsf = new BasicScoreForm(this, 92.5, 152.5, ClickPoint.score, 'HI SCORE !', _onCloseBSF);
                bsf.onCloseClick = _onCloseBSF;
                exitLoop = false;
            } else _changePhase(TITLE);
        }
        
        private function _loopResult() : void {
            ClickPoint.update();
            if (exitLoop) _changePhase(TITLE);
        }
        
        private function _onCloseBSF(succeeded:Boolean=false) : void {
            if (bsf != null) removeChild(bsf);
            Style.LABEL_TEXT = 0xf0f0ff;
            bsrv = new BasicScoreRecordViewer(this, 122.5, 112.5,'RANKING', 30, true, _onCloseBSRV);
            bsf = null;
        }
        
        private function _onCloseBSRV() : void {
            if (bsrv != null) removeChild(bsrv);
            bsrv = null;
            exitLoop = true;
        }
    }
}


import com.bit101.components.*;
import org.libspark.betweenas3.*;
import org.libspark.betweenas3.easing.*;
import org.libspark.betweenas3.tweens.*;
import org.si.sion.*;
import org.si.sion.events.*;
import org.si.sion.sequencer.*;
import org.si.sound.*;
import frocessing.core.*;
import frocessing.geom.*;
import flash.display.*;
import flash.filters.*;
import flash.events.*;
import flash.text.*;
import flash.geom.*;

function r(min:int, max:int) : int {
    return int(Math.random() * (max - min + 0.9999847412109375) + min);
}
    
function r0(range:int) : int {
    var i:int = int(Math.random() * (range * 2 - 0.0000152587890625));
    return (i<range) ? (i-range) : (i-range+1);
}

class SoundManager {
    static public var sion:SiONDriver = new SiONDriver();
    static public var dm:DrumMachine = new DrumMachine(0,2,0,0,2,0);
    static public var backing:SiONData;
    static public function initialize(parent:Sprite, bpm:Number) : void {
        sion.bpm = bpm;
        sion.autoStop = true;
        sion.noteOnExceptionMode = SiONDriver.NEM_OVERWRITE;
        sion.addEventListener(SiONTrackEvent.BEAT, onBeat);
        sion.addEventListener(SiONEvent.STREAM_STOP, onStreamStop);
        sion.setSamplerData(5,sion.render("t144;@v40%2@2q0s40o7a"));
        sion.setSamplerData(1,sion.render("t144;%2@1q0s32@f80,3a"));
        sion.setSamplerData(2,sion.render("t144;#A=%5@1@v64p2q8s32l64o5ga<edgb<e;k4A;k-4A"));
        sion.setSamplerData(3,sion.render("t144;#A=%5@1@v64p2q8s32l64o7cgbad;k4A;k-4A"));
        sion.setSamplerData(4,sion.render("t144;#A=%5@1@v64p2q8s32l64o7e>a<d>gc>b<e;k4A;k-4A"));
        backing = sion.compile("#EFFECT1{delay};%1@2v8s40@f40,4o2q4$l8[aa16aa16a]4[ff16ff16f][gg16gg16g]");
    }
    
    static public function onBeat(e:SiONTrackEvent) : void {
        ClickPoint.beat(e.eventTriggerID>>2);
        if ((e.eventTriggerID & 7) == 0) {
            ClickPoint._(r(4,12),r(4,10),r(0,3),2).rel
                      .q(1,r(0,2),r0(2)).w(2).q(1,r(0,2),r0(2)).w(2)
                      .q(1,r(0,2),r0(2)).w(2).q(1,r(0,2),r0(2)).w(2)
                      .q(1,r(0,2),r0(2)).w(2).q(1,r(0,2),r0(2)).k().$;
        }
    }
    
    static public function onStreamStop(e:SiONEvent) : void {
        dm.stop();
    }
    
    static public function play() : void {
        sion.play(backing, false);
        dm.play();
    }
    
    static public function stop() : void {
        sion.fadeOut(4);
    }
    
    static public function playSound(id:int, length:int, quant:Number, delay:int) : void {
        var track:SiMMLTrack = sion.playSound(id, length, 0, quant, id);
        track.effectSend1 = delay;
    }
}

class ClickPoint extends Point {
    static public var hues:Array = [0,60,120,210];
    static public var animIndexSync:int, enabled:Boolean;
    static public var score:int, frameCount:int, timeGain:int;
    static public var scrollPoint:Point = new Point(), pt:Point = new Point();
    static private var hexPositions:Vector.<Point> = new Vector.<Point>(17*16, true);
    static private var faceTextures:Vector.<Vector.<BitmapData>> = new Vector.<Vector.<BitmapData>>(4, true);
    static private var field:Sprite, layers:Vector.<Bitmap> = new Vector.<Bitmap>();
    static private var hexmap:BitmapData = new BitmapData(400,400+32,false,0);
    static private var cursor:BitmapData = new BitmapData(44,40,true,0), beatCursor:BitmapData = new BitmapData(44,40,true,0);
    static private var background:BitmapData, pixels:BitmapData, blur:BitmapData, effect:BitmapData;
    static private var scoreLabel:Label, timerLabel:Label, message:Label, msgTween:ITween;
    static private var colt:ColorTransform = new ColorTransform(0.8,0.8,0.8);
    static private var digm:Matrix = new Matrix(0.0625,0,0,0.0625,12.5,12.5), digc:ColorTransform = new ColorTransform();
    static private var _freeList:Array = [], _activeList:Array = [];
    static private var rrow:int, rcol:int, rt:Number, beater:Number, cursorIndex:int;
    static private var clickedColor:int, clickedColorCount:int, clickedFrameCount:int, clickMiss:int;
    static private var s:Shape=new Shape(), $:F5Graphics3D = new F5Graphics3D(s.graphics, 400, 400);
    public var colorIndex:int, itemCount:int, killed:Boolean, items:Vector.<BonusItem> = new Vector.<BonusItem>(4, true);
    private var _delay:Number = 0, _rel:Boolean = false, ts:Array, faces:Vector.<BitmapData>, faceIndex:int, tween:ITween;
    private var label:BitmapData = new BitmapData(48, 16, true, 0);
    function ClickPoint() {
        for (var i:int=0; i<4; i++) items[i] = new BonusItem();
    }
    static public function initialize(parent:Sprite, bpm:Number) : void {
        var i:int, j:int, tex:BitmapData, pt:Point, mt:Matrix = new Matrix(), ct:ColorTransform = new ColorTransform(),
            n:Number, col:uint, ew:Number = BonusItem.rect.width, es:Number = ew*0.5;
        with(parent.addChild(field = new Sprite())) { x = y = 232; buttonMode = true; }
        field.addEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
        field.addEventListener(MouseEvent.CLICK,      _onMouseClick);
        background = _createLayer(1, false, "normal");
        pixels = _createLayer(1);
        blur   = _createLayer(1);
        effect = _createLayer(16);
        Style.LABEL_TEXT = 0xe0e0ff;
        message = new Label(field, 0, -25, "");
        message.scaleX = message.scaleY = 3;
        message.autoSize = true;
        scoreLabel = new Label(field, -195, 170, "");
        scoreLabel.scaleX = scoreLabel.scaleY = 2;
        timerLabel = new Label(field, -50, -210, "");
        timerLabel.scaleX = timerLabel.scaleY = 3;
        $.size(400,400);$.beginDraw();$.noFill();$.stroke(60);$.strokeWeight(1);
        for (i=0; i<17*16; i++) {
            pt = hexPositions[i] = new Point((i%17)*27-34+18,(int(i/17)-((i%17)&1)*0.5)*32-16);
            $.line(pt.x-9, pt.y-16, pt.x-18, pt.y-32);
            $.line(pt.x-9, pt.y-16, pt.x-18, pt.y);
            $.line(pt.x-9, pt.y-16, pt.x+9,  pt.y-16);
        }
        $.endDraw();hexmap.draw(s,null,null,null,null,true);
        $.beginDraw();$.fill(255);$.stroke(128);$.strokeWeight(8);$.beginCurrentFill();
        $.shapePath([1,2,2,2,2,2,100],[4,20,13,4,31,4,40,20,31,36,13,36]);
        $.endFill();$.endDraw();beatCursor.draw(s);
        $.beginDraw();$.fill(255);$.noStroke();$.beginCurrentFill();
        $.shapePath([1,2,2,2,2,2,100],[10,20,16,9,28,9,34,20,28,31,16,31]);
        $.endFill();$.endDraw();cursor.draw(s);
        $.size(64,64);$.colorMode("hsv",360,1,1,1);$.imageMode(3);
        for (i=0; i<hues.length; i++) {
            tex = new BitmapData(64, 64, true, 0);$.beginDraw();
            $.noFill();$.stroke(hues[i],0.7,1,0.5);$.strokeWeight(2);$.circle(32, 32, 12);
            $.fill(hues[i],0.7,1,0.5);$.circle(32, 32, 9);
            $.endDraw();tex.draw(s);
            Style.LABEL_TEXT = $.color(hues[i],0.3,1);
            tex.draw(new Label(null, 0, 0, "Click me !"), new Matrix(1,0,0,1,9,22), null, "add", null, false);
            faceTextures[i] = new Vector.<BitmapData>(10);
            faceTextures[i][0] = tex;
            for (j=1; j<10; j++) {
                mt.identity();
                mt.translate(-32, -32);
                mt.scale(1+j*j*0.01, 1-j*j*0.01);
                mt.translate(32, 32);
                //ct.alphaMultiplier = (10-j) * 0.1;
                faceTextures[i][j] = new BitmapData(64, 64, true, 0);
                faceTextures[i][j].draw(tex, mt, ct, null, null, true);
            }
            col = $.color(hues[i],0.5,1);
            BonusItem.texturesList[i] = new Vector.<BitmapData>(16);
            for (j=0; j<16; j++) {
                tex = new BitmapData(ew, ew, true, 0);$.beginDraw();
                $.noStroke();$.fillGradient("radial", es, es, es*32/(j+32), 0, [0xffffff,col,col], [0.7,0.5,0], [0,64,255]);$.rect(0,0,ew,ew);
                $.endDraw();tex.draw(s);
                BonusItem.texturesList[i][j] = tex;
            }
        }
        for (i=0; i<160; i++) {
            $.resetMatrix();$.rotateZ(i*0.039269908169872414);$.rotateX(i*0.15707963267948968);
            BonusItem.coord[i] = $.modelXYZ(0, 1, 0);
            BonusItem.coord[i].z = int(BonusItem.coord[i].z * 8 + 8);
            if (BonusItem.coord[i].z > 15) BonusItem.coord[i].z = 15;
        }
        rt = 60 / bpm;
        clickedColor = -1;
        clickedColorCount = 0;
        clickedFrameCount = 0;
        clickMiss = 0;
    }
    static private function _createLayer(scale:Number=1, alpha:Boolean=false, blendMode:String="add") : BitmapData {
        var layer:Bitmap = new Bitmap(new BitmapData(400/scale, 400/scale, alpha, 0));
        field.addChild(layer).blendMode = blendMode;
        layer.x = layer.y = -200;
        layer.scaleX = layer.scaleY = scale;
        return layer.bitmapData;
    }
    static public function calcIndex(x:Number, y:Number) : int {
        var ix:int = int((x+34)*0.037037037037037035), iy:int = int((y+32)/32+(ix&1)*0.5);
        return iy*17+ix;
    }
    static public function calcCoord(result:Point, row:int, col:int) : * {
        if (col<0 || col>15 || row<0 || row>16) return null;
        var hp:Point = hexPositions[col*17+row];
        result.x = hp.x;
        result.y = hp.y;
        return {x:result.x, y:result.y};
    }
    static public function showMessage(str:String, time:Number=0) : void {
        if (msgTween) { msgTween.stop(); msgTween = null; }
        message.text = str;
        message.alpha = 1;
        message.visible = (str != null);
        if (message.visible) {
            message.draw();
            message.x = - message.width * 1.5;
            if (time>0) {
                msgTween = BetweenAS3.tween(message, {alpha:0}, {alpha:1}, 2, Linear.linear);
                msgTween.onComplete = function():void {message.visible = false;};
                msgTween.play();
            }
        }
    }

    static private function _onMouseMove(e:MouseEvent) : void {
        var newIndex:int = calcIndex(e.localX+200, e.localY+200);
        if (cursorIndex != newIndex) {
            var center:Point = hexPositions[cursorIndex=newIndex];
            pt.x = center.x-22+scrollPoint.x; pt.y = center.y-20+scrollPoint.y;
            blur.copyPixels(cursor, cursor.rect, pt);
            SoundManager.playSound(5,2,1,0);
        }
    }
    static private function _onMouseClick(e:MouseEvent) : void {
        if (!enabled) return;
        var i:int, imax:int = _activeList.length, dx:Number, dy:Number, d2:Number, d2i:int=-1, d2min:Number = 1024;
        for (i=0; i<imax; i++) {
            dx = e.localX + 200 - _activeList[i].x;
            dy = e.localY + 200 - _activeList[i].y;
            d2 = dx*dx+dy*dy;
            if (d2<d2min) { d2i=i; d2min=d2; }
        }
        if (d2i != -1) {
            score += 10;
            _activeList[d2i].kill();
            for (i=0; i<8; i++) Particle.alloc(_activeList[d2i].x, _activeList[d2i].y, hues[_activeList[d2i].colorIndex]);
            if (clickedColor == _activeList[d2i].colorIndex) {
                clickedColor = _activeList[d2i].colorIndex;
                if (++clickedColorCount == 3) {
                    clickedColor = -1;
                    var speed:int = (clickedFrameCount>40) ? 10 : (60-clickedFrameCount),
                        bonus:int = int(speed*speed*0.2) * 10;
                    score += bonus;
                    frameCount += timeGain*24;
                    if (--timeGain<2) timeGain=2;
                    showMessage("BONUS +" + bonus.toString(), 1);
                }
            } else {
                clickedColor = _activeList[d2i].colorIndex;
                clickedColorCount = 1;
                clickedFrameCount = 0;
                clickMiss = 0;
            }
            SoundManager.playSound(1+clickedColorCount,8,1,32);
        } else {
            frameCount -= 72;
            showMessage("TIME -3sec", 1);
            SoundManager.playSound(1,2,1,16);
        }
    }
    static public function reset() : void {
        score = 0;
        frameCount = 30*24;
        timeGain = 10;
    }
    static public function update() : Boolean {
        var i:int, imax:int = _activeList.length;
        if (++animIndexSync == 80) animIndexSync = 0;
        background.copyPixels(hexmap, hexmap.rect, scrollPoint); 
        pixels.fillRect(pixels.rect, 0);
        blur.colorTransform(blur.rect, colt);
        $.beginDraw();Particle.drawAll($);
        $.endDraw();pixels.draw(s, new Matrix(1,0,0,1,200,200));
        effect.draw(s, digm, null, "add", null, true);
        effect.colorTransform(effect.rect, colt);
        for (i=0; i<imax; i++) _activeList[i].draw();
        for (i=0; i<imax; i++) if (_activeList[i].killed) {
            _activeList[i].tween.stop();
            _freeList.push(_activeList[i]);
            _activeList.splice(i, 1);
            i--; imax--;
        }
        beater *= 0.9;
        clickedFrameCount++;
        timerLabel.text = "TIME:"+String(int(frameCount*0.041666666666666664));
        scoreLabel.text = "SCORE:"+String(score);
        if (--frameCount <= 0) { frameCount=0; return false; }
        return true;
    }
    static public function beat(beatIndex:int) : void {
        beater = 1;
        animIndexSync = (beatIndex & 7) * 10;
        var center:Point = hexPositions[cursorIndex];
        pt.x = center.x-22+scrollPoint.x; pt.y = center.y-20+scrollPoint.y;
        blur.copyPixels(beatCursor, beatCursor.rect, pt);
    }
    public function setup(row:int, col:int, color:int, item:int) : ClickPoint {
        _activeList.push(this);
        calcCoord(this, rrow=row, rcol=col);
        colorIndex = color; itemCount = item; faceIndex = -10;
        for (var i:int=0; i<itemCount; i++) items[i].setup(this, i*20, 32);
        faces = faceTextures[color]; ts = []; _delay = 1; _rel = false; killed = false;
        return this;
    }
    public function draw() : void {
        if (faceIndex!=0) if (++faceIndex == 10) { kill(); return; }
        var fi:int = (faceIndex<0) ? -faceIndex : faceIndex;
        pt.x = x+scrollPoint.x-32; pt.y = y+scrollPoint.y-32;
        pixels.copyPixels(faces[fi], faces[fi].rect, pt);
        for (var i:int=0; i<itemCount; i++) items[i].draw(pixels, blur);
    }
    public function disapear() : void { faceIndex = 1; }
    public function kill() : void { killed = true; }
    
//-------------------------------------------------- inline script
    static public function _(row:int, col:int, color:int, item:int) : ClickPoint { 
        var newClickPoint:ClickPoint = _freeList.pop() || new ClickPoint();
        return newClickPoint.setup(row, col, color, item); 
    }
    public function get rel() : ClickPoint { _rel = true; return this; }
    public function get abs() : ClickPoint { _rel = false; return this; }
    public function w(n:Number) : ClickPoint { _delay = n; return this; }
    public function l(time:Number, p0:int, p1:int) : ClickPoint { return to(time, p0, p1, Linear.linear); }
    public function b(time:Number, p0:int, p1:int) : ClickPoint { return to(time, p0, p1, Bounce.easeOut); }
    public function c(time:Number, p0:int, p1:int) : ClickPoint { return to(time, p0, p1, Cubic.easeOut); }
    public function e(time:Number, p0:int, p1:int) : ClickPoint { return to(time, p0, p1, Expo.easeOut); }
    public function q(time:Number, p0:int, p1:int) : ClickPoint { return to(time, p0, p1, Quad.easeInOut); }
    public function k() : ClickPoint { return f(disapear); }
    public function f(func:Function) : ClickPoint { return append(BetweenAS3.func(func)); }
    public function to(time:Number, p0:int, p1:int, easing:*) : ClickPoint { 
        if (_rel) {
            if (p0==0) { rcol -= p1; }
            else { rrow += p1; rcol += (p0==1) ? -((p1+(rrow&1)+1)>>1):((p1+(rrow&1))>>1); }
        } else {
            rrow = p0;
            rcol = p1;
        }
        var param:* = calcCoord(pt, rrow, rcol);
        return (param)?append(BetweenAS3.to(this, param, time*rt, easing)):this;
    }
    public function append(t:ITween) : ClickPoint {
        if (_delay == 0) ts.push(t);
        else ts.push(BetweenAS3.delay(t, _delay*rt));
        _delay = 0;
        return this;
    }
    public function get $() : ClickPoint {
        if (ts.length > 0) {
            tween = BetweenAS3.serialTweens(ts);
            tween.play();
        }
        ts = [];
        return this;
    }
}

class BonusItem extends Point {
    static public var rect:Rectangle = new Rectangle(0,0,12,12);
    static public var texturesList:Vector.<Vector.<BitmapData>> = new Vector.<Vector.<BitmapData>>(4, true);
    static public var coord:Vector.<FNumber3D> = new Vector.<FNumber3D>(400, true);
    public var animIndex:int, radius:Number, textures:Vector.<BitmapData>, center:ClickPoint;
    function BonusItem() : void {}
    public function setup(center:ClickPoint, animIndex:int, radius:Number) : void {
        this.center=center;this.animIndex=animIndex; this.radius=radius;
        this.textures=texturesList[center.colorIndex];
        this.x = center.x; this.y = center.y;
    }
    public function draw(pixels:BitmapData, blur:BitmapData) : void {
        if (center) {
            var ai:int = (ClickPoint.animIndexSync<<1) + animIndex;
            if (ai >= 160) ai -= 160;
            var  i:int, v:FNumber3D=coord[ai], ti:int=int(v.z);
            var dx:Number=(center.x+ClickPoint.scrollPoint.x-6+v.x*radius-x)*0.125, 
                dy:Number=(center.y+ClickPoint.scrollPoint.y-6+v.y*radius-y)*0.125;
            for (i=0; i<8; i++,x+=dx,y+=dy) blur.copyPixels(textures[ti], rect, this);
            pixels.copyPixels(textures[ti], rect, this);
        }
    }
}

class Particle {
    static private var _freeList:Array = [], _activeList:Array = [];
    public var x:Number, y:Number, z:Number, hue:Number, angle:Number, rot:Number, alpha:Number, da:Number;
    function Particle() {}
    public function draw($:F5Graphics3D) : void {
        $.pushMatrix();
        $.fill(hue, 0.5, 1, alpha);$.translate(x, y, z);$.rotateZ(angle);
        $.beginShape(F5C.TRIANGLES);$.vertex3d(6,-3,-3);$.vertex3d(-3,6,-3);$.vertex3d(-3,-3,6);$.endShape();
        $.popMatrix();
        angle += rot; alpha -= da; z -= 0.2;
    }
    static public function drawAll($:F5Graphics3D) : void {
        var i:int, imax:int = _activeList.length;
        for (i=0; i<imax; i++) _activeList[i].draw($);
    }
    static public function alloc(x:Number, y:Number, hue:Number) : void {
        var inst:Particle = _freeList.pop() || new Particle();
        var time:Number = Math.random()+1;
        x+=Math.random()*20-10-200; y+=Math.random()*20-10-200;
        inst.x = x; inst.y = y; inst.z = 0;
        inst.hue = hue; inst.alpha = 0.6; inst.da = 0.58/(time*24);
        inst.rot = Math.random()*0.6-0.3; inst.angle = Math.random()*6.28-3.14;
        var t:ITween = BetweenAS3.to(inst, {x:x+Math.random()*120-60, y:y+Math.random()*120-60}, time, Expo.easeOut);
        t.onComplete = inst.free; t.play();
        _activeList.push(inst);
    }
    public function free() : void {
        _activeList.splice(_activeList.indexOf(this), 1);
        _freeList.push(this);
    }
}

