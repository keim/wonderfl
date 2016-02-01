package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;
    import flash.filters.*;
    import org.si.sound.patterns.*;
    import org.si.utils.timer;
    import com.bit101.components.*;

    [SWF(width='465', height='465', backgroundColor='#000000', frameRate='30')]
    public class main extends Sprite {
        private var gl:Render3D, _ssao:BitmapData, _ssaoEnabled:Boolean = true;
        private var controler:Sprite;
        private var prevTime:uint;
        private var arX:Number, arY:Number, viewX:Number, viewY:Number, viewdX:Number, viewdY:Number;
        private var attrForce:Number = 20, dumpForce:Number = 0.125;
        
        // entry point
        function main() {
            var i:int, j:int;
            addChild(controler = new Sprite());
            
            HexagonalPillar.initialize(400, 260);
            addChild(gl = new Render3D(300)).visible = false;
            _ssao = new BitmapData(400, 260, false, 0);
            controler.addChild(new Bitmap(HexagonalPillar.screen));
            controler.x = 32;
            controler.y = 20;
            controler.addEventListener("enterFrame", _onEnterFrame);
            controler.addEventListener("mouseDown",  _onMouseDown);
            
            //timer.initialize(this, 10, "Total : ##ms","Depth : ##ms","Flat : ##ms","Proj : ##ms","SSAO : ##ms");
            //timer.title = "debug";
            
            arX = arY = viewX = viewY = 0.5;
            viewdX = viewdY = 0;
            
            soundManager = new SoundManager(_onArpeggiatorFrame);
            controlPanel = new ControlPanel(this, 32, 280, soundManager.synth);
            new CheckBox(controler, 4, 245, "Ambient Shadow", function(e:Event):void {_ssaoEnabled = e.target.selected;}).selected = true;
            
            soundManager.bpm = HexagonalPillar.bpm = 100;
            soundManager.play();

            prevTime = getTimer();
        }

        private function _onEnterFrame(e:Event) : void {
            var i:int, t:int = getTimer(), dt:Number = (t - prevTime) * 0.001, ax:Number , ay:Number, dp:Number;
            prevTime = t;

            ax = (arX - viewX) * attrForce * dt;
            ay = (arY - viewY) * attrForce * dt;
            viewdX += ax;
            viewdY += ay;
            viewX += (viewdX + ax * 0.5) * dt;
            viewY += (viewdY + ay * 0.5) * dt;
            dp = Math.pow(dumpForce, dt);
            viewdX *= dp;
            viewdY *= dp;
            
            //timer.start(0);
            stage.quality = "low";
            HexagonalPillar.depth.lock();
            HexagonalPillar.screen.lock();
            HexagonalPillar.update(gl, viewX, viewY, dt);
            //timer.start(4);
            if (_ssaoEnabled) {
                _ssao.lock();
                _ssao.applyFilter(HexagonalPillar.depth, _ssao.rect, _ssao.rect.topLeft, blur);
                _ssao.draw(HexagonalPillar.depth, null, null, "subtract");
                _ssao.threshold(HexagonalPillar.depth, _ssao.rect, _ssao.rect.topLeft, "==", 0, 0, 255);
                HexagonalPillar.screen.draw(_ssao, null, colt, "multiply");
                _ssao.unlock();
            }
            //timer.pause(4);
            HexagonalPillar.depth.unlock();
            HexagonalPillar.screen.unlock();
            stage.quality = "high";
            //timer.pause(0);
        }
        private var blur:BlurFilter = new BlurFilter(64, 64);
        private var colt:ColorTransform = new ColorTransform(-8, -8, -8, 1, 255, 255, 255, 0);
        
        private function _onMouseDown(e:Event) : void { 
            stage.addEventListener("mouseMove", _onMouseMove);
            stage.addEventListener("mouseUp", _onMouseUp);
            soundManager.arStart();
        }
        private function _onMouseMove(e:Event) : void { 
            arX = controler.mouseX*0.0025;
            arY = controler.mouseY*0.0038461538461538463;
            arX = (arX < 0) ? 0 : (arX > 1) ? 1 : arX;
            arY = (arY < 0) ? 0 : (arY > 1) ? 1 : arY;
            soundManager.arControl(arX, arY);
        }
        private function _onMouseUp(e:Event) : void { 
            soundManager.arStop();
            stage.removeEventListener("mouseMove", _onMouseMove);
            stage.removeEventListener("mouseUp", _onMouseUp);
        }
        
        private function _onArpeggiatorFrame(seq:Sequencer) : void { HexagonalPillar.find(int(arX*8+3.5), int(arY*2+0.5)).height = 40; }
    }
}


import flash.display.*;
import flash.geom.*;
import flash.events.*;
import org.si.sion.*;
import org.si.sion.events.*;
import org.si.sion.effector.*;
import org.si.sound.*;
import org.si.sound.synthesizers.*;
import com.bit101.components.*;
import org.si.utils.timer;

var soundManager:SoundManager;
var controlPanel:ControlPanel;

class SoundManager {
    public var synth:AnalogSynth;
    private var sion:SiONDriver, ar:Arpeggiator, dm:DrumMachine, _autoPlay:Boolean;
    function SoundManager(onenterframe:Function) {
        sion = new SiONDriver();
        ar = new Arpeggiator("Fp", 1, [0,3,2,5,6,4,1]);
        dm = new DrumMachine(0,2,1,1,2,0);
        ar.synthesizer = synth = new AnalogSynth(0,1,5,0.5,0.1);
        ar.onEnterFrame = onenterframe;
        synth.setVCAEnvelop(0.2, 0.5, 0.75, 0.2);
        synth.setVCFEnvelop(0.5, 0.2, 0.1, 0.6, 0.6);
        _autoPlay = false;
    }
    public function set bpm(n:Number) : void { sion.bpm = n; }
    public function set autoPlay(b:Boolean) : void { 
        _autoPlay = b;
        ar.play();
    }
    public function setChorus(n:Number) : void { ar.effectSend1 = n; }
    public function setDelay(n:Number) : void { ar.effectSend2 = n; }
    public function play() : void {
        ar.volume = 0.3;
        ar.effectSend1 = 0.4;
        ar.effectSend2 = 0.2;
        dm.volume = 0.3;
        sion.play("#EFFECT1{chorus};#EFFECT2{delay};#A=[f8.f8.fffrfrr4];%5@2@v28@f40,2,60,32,,,72,60q5s40l16o3$AA(-3)A(-7)A(-5)");
        dm.play();
    }
    public function arStart() : void { ar.play(); }
    public function arStop() : void { if (!_autoPlay) ar.stop(); }
    public function arControl(nx:Number, ny:Number) : void {
        ar.scaleIndex = nx * 20 - 10;
        ar.scaleIndex = nx * 20 - 10;
        ar.gateTime = ny;
        ar.noteLength = [2,1,2,1][int(ny * 3.9)];
        ar.portament = (ny == 0 || ny == 1) ? 5 : 0;
    }
}

class ControlPanel extends Sprite {
    private var _wsList:Array = [0,4,5,1,6];
    private var _pitches:Array = [-1536,-768,-704,-640,-576,-512,-448,-384,-320,-256,-192,-128,-64,-48,-32,-24,-16,-12,-8,-6,-4,-3,-2,-1,0,1,2,3,4,6,8,12,16,24,32,48,64,128,192,256,320,384,448,512,576,640,704,768,1536];
    private var _bal:Knob, _det:Knob, _bpm:Knob, _dly:Knob, _cho:Knob, _ws1:Array = [], _ws2:Array = [], _con:Array = [], _detL:Label;
    private var vca:EnvelopControler, vcf:EnvelopControler, res:VSlider, auto:CheckBox;
    private var aat:Label, adt:Label, asl:Label, art:Label, fco:Label, fre:Label, fat:Label, fdt:Label, fpk:Label;
    private var _synth:AnalogSynth;
    function ControlPanel(parent:DisplayObjectContainer, xpos:Number, ypos:Number, synth:AnalogSynth) {
        var i:int, g:Graphics = graphics, vtx:Vector.<Number> = new Vector.<Number>();
        var cmd:Vector.<int> = Vector.<int>([1,2,2,2,2,2,2,2,2,1,2,2,2,1,2,2,2,2,2,1,2,2,2,1,2,2,2,2,2,2,2,2]);
        for (i=0; i<9; i++) vtx.push(20+i*2, 8-Math.sin(i*0.7853981633974483)*4);
        vtx.push(40+0,  8, 40+4,  4, 40+12, 12, 40+16,  8);
        vtx.push(60+0,  8, 60+0,  4, 60+8,   4, 60+8,  12, 60+16, 12, 60+16, 8);
        vtx.push(80+0,  8, 80+8,  4, 80+8,  12, 80+16,  8);
        for (i=0; i<9; i++) vtx.push(100+i*2, 8+(Math.random()*3+1)*(1-((i&1)<<1)));
        super();
        parent.addChild(this);
        x = xpos;
        y = ypos;
        _synth = synth;
        
        Style.LABEL_TEXT = 0xa0a0a0;
        Style.BACKGROUND = 0x606060;
        for (i=0; i<5; i++) {
            _ws1.push(new RadioButton(this, i*20+22, 18, "", false, _funcWSSelected(0, i)));
            _ws2.push(new RadioButton(this, i*20+22, 34, "", false, _funcWSSelected(1, i)));
            _ws1[i].groupName = "ws1";
            _ws2[i].groupName = "ws2";
        }
        new Label(this, 0, 14, "ws1");
        new Label(this, 0, 30, "ws2");
        g.lineStyle(1, Style.LABEL_TEXT);
        g.drawPath(cmd, vtx);
        _con.push(new RadioButton(this, 144, 18, "", false, function(e:Event):void{_synth.con = 0;}));
        _con.push(new RadioButton(this, 164, 18, "", false, function(e:Event):void{_synth.con = 1;}));
        _con.push(new RadioButton(this, 184, 18, "", false, function(e:Event):void{_synth.con = 2;}));
        _con[0].selected = _ws1[3].selected = _ws2[2].selected = true;
        new Label(this, 120, 14, "con");
        new Label(this, 140,  0, "Non");
        new Label(this, 160,  0, "Rng");
        new Label(this, 180,  0, "Syn");
        for (i=0; i<3; i++) _con[i].groupName = "con";
        _bal = _newKnob(205, 0, "bal", -100, 100, 0, function(e:Event):void{ _synth.balance = (_bal.value+100)* 0.005; });
        _det = _newKnob(230, 0, "det", 0, _pitches.length-1, _pitches.length>>1, _onChangeVCO2Pitch);
        _dly = _newKnob(255, 0, "dly", 0, 100, 20, function(e:Event):void{soundManager.setDelay(_dly.value*0.01);});
        _cho = _newKnob(280, 0, "cho", 0, 100, 40, function(e:Event):void{soundManager.setChorus(_cho.value*0.01);});
        _bpm = _newKnob(305, 0, "bpm", 80, 160, 100, function(e:Event):void{soundManager.bpm = HexagonalPillar.bpm = _bpm.value;});
        _det.showValue = false;
        _det.value = (_pitches.length>>1)+4;
        _detL = new Label(_det, 0, 36, "");
        _onChangeVCO2Pitch(null);
        
        vca = new EnvelopControler(this, 5, 56, 140, 80, {
            "at":_synth.attackTime  * 1.4285714285714286,
            "dt":_synth.decayTime   * 1.4285714285714286, 
            "sl":_synth.sustainLevel,
            "rt":_synth.releaseTime * 1.4285714285714286
        });
        vca.onUpdate = _onVCAUpdate;
        new Label(vca, 110, 0, "VCA");
        
        vcf = new EnvelopControler(this, 155, 56, 140, 80, {
            "at":_synth.vcfAttackTime  * 1.4285714285714286,
            "tl":_synth.vcfPeakCutoff, 
            "dt":_synth.vcfDecayTime   * 1.4285714285714286, 
            "sl":_synth.cutoff
        });
        vcf.onUpdate = _onVCFUpdate;
        new Label(vcf, 110, 0, "VCF");
        res = new VSlider(this, 305, 56, _onVCFUpdate);
        res.setSliderParams(0, 1, _synth.resonance);
        res.setSize(10, 80);
        res.tick = 0.0078125;
        
        auto = new CheckBox(this, 335, 10, "autoplay", function(e:Event) : void{ soundManager.autoPlay = auto.selected; });
        auto.selected = false;
        
        var ly:Number = 14;
        aat = envparam(this, "attackT.", _synth.attackTime);
        adt = envparam(this, "decayT.",  _synth.decayTime);
        asl = envparam(this, "sustainL.",_synth.sustainLevel);
        art = envparam(this, "releaseT.",_synth.releaseTime);
        fco = envparam(this, "cutoff",   _synth.cutoff);
        fre = envparam(this, "resonan.", _synth.resonance);
        fat = envparam(this, "vcfAtt.",  _synth.vcfAttackTime);
        fdt = envparam(this, "vcfDec.",  _synth.vcfDecayTime);
        fpk = envparam(this, "vcfPeak",  _synth.vcfPeakCutoff);
        
        function envparam(parent:DisplayObjectContainer, label:String, value:Number) : Label {
            ly +=12;
            new Label(parent, 335, ly, label);
            return new Label(parent, 375, ly, value.toFixed(2)); 
        }
    }
    
    private function _newKnob(xpos:Number, ypos:Number, label:String, min:Number, max:Number, val:Number, onChange:Function) : Knob {
        var knob:Knob = new Knob(this, xpos, ypos, label, onChange);
        knob.radius = 8;
        knob.labelPrecision = 0;
        knob.minimum = min;
        knob.maximum = max;
        knob.value = val;
        return knob;
    }
    
    private function _onChangeVCO2Pitch(e:Event) : void {
        var pitch:Number = _pitches[int(_det.value)]*0.015625;
        _synth.vco2pitch = pitch;
        _detL.text = pitch.toFixed(2);
        _detL.draw();
        _detL.x = 8 - _detL.width * 0.5;
    }
    private function _onVCAUpdate(e:Event=null) : void {
        _synth.setVCAEnvelop(vca.at*0.7, vca.dt*0.7, vca.sl, vca.rt*0.7);
        aat.text = _synth.attackTime.toFixed(2);
        adt.text = _synth.decayTime.toFixed(2);
        asl.text = _synth.sustainLevel.toFixed(2);
        art.text = _synth.releaseTime.toFixed(2);
    }
    private function _onVCFUpdate(e:Event=null) : void {
        _synth.setVCFEnvelop(vcf.sl*vcf.tl, res.value, vcf.at*0.7, vcf.dt*0.7, vcf.tl);
        fco.text = _synth.cutoff.toFixed(2);
        fre.text = _synth.resonance.toFixed(2);
        fat.text = _synth.vcfAttackTime.toFixed(2);
        fdt.text = _synth.vcfDecayTime.toFixed(2);
        fpk.text = _synth.vcfPeakCutoff.toFixed(2);
    }
    private function _funcWSSelected(opNum:int, index:int) : Function {
        return function(e:Event) : void { _wsSelected(opNum, index); };
    }
    private function _wsSelected(opNum:int, index:int) : void {
        if (opNum == 0) _synth.ws1 = _wsList[index];
        else _synth.ws2 = _wsList[index];
    }
}


// custom component "ControlPad" shown in Arpeggiator panel
class ControlPad extends Component {
    public var back:Sprite, pointer:Sprite, rx:Number=0.5, ry:Number=0.5, w:Number, h:Number;
    public var onStart:Function=null, onChange:Function, onStop:Function=null;
    function ControlPad(parent:DisplayObjectContainer, x:Number, y:Number, width:Number, height:Number) {
        super(parent, x, y);
        addChild(back = new Sprite());
        back.filters = [getShadow(2, true)];
        back.addEventListener(MouseEvent.MOUSE_DOWN, onBackClick);
        addChild(pointer = new Sprite());
        pointer.filters = [getShadow(1)];
        pointer.buttonMode = true;
        pointer.useHandCursor = true;
        pointer.addEventListener(MouseEvent.MOUSE_DOWN, onDrag);
        setSize(width, height);
        w = width - 12;
        h = height - 12;
    }
    
    override public function draw() : void {
        super.draw();
        back.graphics.clear();
        back.graphics.beginFill(Style.BACKGROUND);
        back.graphics.drawRect(0, 0, width, height);
        back.graphics.endFill();
        pointer.graphics.beginFill(0x8080ff, 0.5);
        pointer.graphics.lineStyle(2,Style.BUTTON_FACE);
        pointer.graphics.drawCircle(5, 5, 5);
        pointer.graphics.endFill();
        updatePointerPosition();
    }
    
    protected function onDrag(e:Event) : void {
        stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onSlide);
        pointer.startDrag(false, new Rectangle(0, 0, w, h));
        if (onStart != null) onStart();
    }
    
    protected function onDrop(e:MouseEvent) : void {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSlide);
        stopDrag();
        if (onStop != null) onStop();
    }

    protected function onSlide(e:MouseEvent) : void {
        var _rx:Number = rx, _ry:Number = ry;
        rx = pointer.x / w;
        ry = pointer.y / h;
        rx = (rx<0) ? 0 : (rx>1) ? 1 : rx;
        ry = (ry<0) ? 0 : (ry>1) ? 1 : ry;
        if (_rx != rx || _ry != ry) onChange();
    }
    
    protected function onBackClick(e:MouseEvent) : void {
        pointer.x = mouseX - 6;
        pointer.y = mouseY - 6;
        onSlide(e);
        onDrag(null);
    }
    
    public function setPointer(x:Number, y:Number) : void {
        rx = x;
        ry = y;
        updatePointerPosition();
    }
    
    public function updatePointerPosition() : void {
        pointer.x = rx * w;
        pointer.y = ry * h;
    }
}


// custom component "EnvelopControler" shown in BassSequencer panel
class EnvelopControler extends ControlPad {
    public var env:Sprite, at:Number, tl:Number, dt:Number, sl:Number, sr:Number, rt:Number;
    public var srFixed:Boolean, tlFixed:Boolean, rlFixed:Boolean, dragIndex:int, pt:Array, onUpdate:Function;
    function EnvelopControler(parent:DisplayObjectContainer, x:Number, y:Number, width:Number, height:Number, p:*) {
        at=p["at"]; dt=p["dt"]; sl=p["sl"];
        srFixed=!("sr" in p); tlFixed=!("tl" in p); rlFixed=!("rt" in p);
        tl=(tlFixed)?1:p["tl"]; sr=(srFixed)?1:p["sr"]; rt=(rlFixed)?1:p["rt"];
        dragIndex = 0;
        super(parent, x, y, width, height);
        back.addChild(env = new Sprite());
        env.filters = [getShadow(1)];
        addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        onChange = _onChange;
        onStart = _onStart;
        onStop = _onStop;
        rx = at * 0.3;
        ry = 1 - tl;
    }
    
    override public function draw() : void {
        super.draw();
        updateEnvelop();
    }
    
    protected function updateEnvelop() : void {
        pt = [[at*w*0.3,(1-tl)*h], [(at+dt)*w*0.3,(1-sl*tl)*h], [w*0.7,(1-sl*tl)*sr*h], [(rlFixed)?w:(0.7+rt*0.3)*w,(rlFixed)?((1-sl*tl)*sr*h):h]];
        env.graphics.clear();
        env.graphics.lineStyle(2,Style.BUTTON_FACE);
        env.graphics.moveTo(5, h+5);
        env.graphics.lineTo(pt[0][0]+5, pt[0][1]+5);
        env.graphics.lineTo(pt[1][0]+5, pt[1][1]+5);
        env.graphics.lineTo(pt[2][0]+5, pt[2][1]+5);
        env.graphics.lineTo(pt[3][0]+5, pt[3][1]+5);
    }
    
    protected function _onStart() : void { removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove); }
    protected function _onStop()  : void { addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove); }
    
    protected function onMouseMove(e:MouseEvent) : void {
        var i:int, dx:Number=pt[0][0]-mouseX, dy:Number=pt[0][1]-mouseY, d2:Number=dx*dx+dy*dy;
        for (dragIndex=0, i=1; i<4; i++) {
            dx = pt[i][0] - mouseX;
            dy = pt[i][1] - mouseY;
            if (dx*dx+dy*dy < d2) {
                d2 = dx*dx+dy*dy;
                dragIndex = i;
            }
        }
        pointer.x = pt[dragIndex][0];
        pointer.y = pt[dragIndex][1];
    }
    
    protected function _onChange() : void {
        var n:Number;
        switch (dragIndex) {
        case 0:
            at = (rx>=0.3) ? 1 : (rx * 3.3333333333333333);
            tl = (tlFixed) ? 1 : (1 - ry);
            rx = at * 0.3;
            ry = 1 - tl;
            break;
        case 1:
            n = rx - at * 0.3;
            dt = (n<0) ? 0 : (n>=0.3) ? 1 : (n * 3.3333333333333333);
            sl = (tl==0) ? 0 : ((1 - ry)/tl);
            if (sl > 1) sl = 1;
            rx = (at + dt)*0.3;
            ry = 1 - sl * tl;
            break;
        case 2:
            rx = 0.7;
            sl = (tl==0) ? 0 : ((1 - ry)/tl);
            if (sl > 1) sl = 1;
            ry = 1 - sl * tl;
            break;
        case 3:
            rt = (rlFixed) ? 1 : (rx<0.7) ? 0 : ((rx-0.7) * 3.3333333333333333);
            rx = rt * 0.3 + 0.7;
            ry = (rlFixed) ? (1 - sl * tl) : 1;
            break;
        default:
            break;
        }
        updatePointerPosition();
        updateEnvelop();
        onUpdate();
    }
}



/** 3D engine class */
class Render3D extends Shape {
//--------------------------------------------------variables
    public var matrix:Matrix3D;
    private var _projectionMatrix:Matrix3D;                              // projection matrix
    private var _matrixStac:Vector.<Matrix3D> = new Vector.<Matrix3D>(); // matrix stac
    private var _cmdWire:Vector.<int> = Vector.<int>([1,2]);             // commands to draw wire
    private var _cmdTriangle:Vector.<int> = Vector.<int>([1,2,2]);       // commands to draw triangle
    private var _cmdQuadrangle:Vector.<int> = Vector.<int>([1,2,2,2]);   // commands to draw quadrangle
    private var _data:Vector.<Number> = new Vector.<Number>(8, true);    // data to draw shape
    private var _clippingZ:Number;                                       // clipping z value
    private var _depthMap:BitmapData = new BitmapData(256, 256, false);  // texture for depth buffer rendering
    private var _zeroVector:Vector3D = new Vector3D(0,0,0,1);            // zero vector
    
//--------------------------------------------------constructor
    function Render3D(focus:Number=300, clippingZ:Number=-0.1) {
        var projector:PerspectiveProjection = new PerspectiveProjection()
        projector.focalLength = focus;
        _projectionMatrix = projector.toMatrix3D();
        _clippingZ = -clippingZ;
        matrix = new Matrix3D();
        _matrixStac.length = 1;
        _matrixStac[0] = matrix;
        var u:int, v:int;
        for (v=0; v<256; v++) 
            for (u=0; u<256; u++) 
                //_depthMap.setPixel(255-u, 255-v, (v<<8)|u);
                _depthMap.setPixel(255-u, 255-v, (u<<16)|(u<<8)|u);
    }
    
//--------------------------------------------------control matrix
    public function clear() : Render3D { matrix = _matrixStac[0]; _matrixStac.length = 1; return this; }
    public function push() : Render3D { _matrixStac.push(matrix.clone()); return this; }
    public function pop() : Render3D { matrix = (_matrixStac.length == 1) ? matrix : _matrixStac.pop(); return this; }
    public function id() : Render3D { matrix.identity(); return this; }
    public function t(x:Number, y:Number, z:Number) : Render3D { matrix.prependTranslation(x, y, z); return this; }
    public function tv(v:Vector3D) : Render3D { matrix.prependTranslation(v.x, v.y, v.z); return this; }
    public function s(x:Number, y:Number, z:Number) : Render3D { matrix.prependScale(x, y, z); return this; }
    public function sv(v:Vector3D) : Render3D { matrix.prependScale(v.x, v.y, v.z); return this; }
    public function r(angle:Number, axis:Vector3D) : Render3D { matrix.prependRotation(angle, axis); return this; }
    public function rv(v:Vector3D) : Render3D { matrix.prependRotation(v.w, v); return this; }
    public function rx(angle:Number) : Render3D { matrix.prependRotation(angle, Vector3D.X_AXIS); return this; }
    public function ry(angle:Number) : Render3D { matrix.prependRotation(angle, Vector3D.Y_AXIS); return this; }
    public function rz(angle:Number) : Render3D { matrix.prependRotation(angle, Vector3D.Z_AXIS); return this; }
    public function mult(mat:Matrix3D) : Render3D { matrix.prepend(mat); return this; }
    
//--------------------------------------------------projections
    public function project(pmesh:ProjectionMesh) : Render3D {
        matrix.transformVectors(pmesh.base.vertices, pmesh.verticesOnWorld);
        matrix.transformVectors(pmesh.base.gravPoints, pmesh.gravPointsOnWorld);
        pmesh.position = matrix.position;
        pmesh.sortZ = pmesh.position.lengthSquared;
        matrix.position = _zeroVector;
        matrix.transformVectors(pmesh.base.faceNormals,  pmesh.faceNormalsOnWorld);
        matrix.position = pmesh.position;
        var nearZ:Number = -Number.MAX_VALUE, farZ:Number = _clippingZ,
            vtx:Vector.<Number> = pmesh.verticesOnWorld,
            gp:Vector.<Number> = pmesh.gravPointsOnWorld, 
            fn:Vector.<Number> = pmesh.faceNormalsOnWorld,
            flist:Vector.<Face> = pmesh.base.faces,
            f:Face, f0:Face, i:int, imax:int, i0:int, i1:int, i2:int, 
            z0:Number, z1:Number, z2:Number, gpi:int, dot:Number;
        imax = flist.length;
        pmesh.faceProjected.length = 0;
        for (i=0; i<imax; i++) {
            f = flist[i];
            z0 = vtx[(f.i0<<1) + f.i0 + 2];
            z1 = vtx[(f.i1<<1) + f.i1 + 2];
            z2 = vtx[(f.i2<<1) + f.i2 + 2];
            if (z0<_clippingZ && z1<_clippingZ && z2<_clippingZ) {
                gpi = f.gpi - 2;
                dot  = gp[gpi] * fn[gpi]; gpi++;
                dot += gp[gpi] * fn[gpi]; gpi++;
                dot += gp[gpi] * fn[gpi];
                if (dot <= 0) {
                    if (nearZ < z0) nearZ = z0;
                    if (nearZ < z1) nearZ = z1;
                    if (nearZ < z2) nearZ = z2;
                    if (farZ  > z0) farZ  = z0;
                    if (farZ  > z1) farZ  = z1;
                    if (farZ  > z2) farZ  = z2;
                    pmesh.faceProjected.push(f);
                }
            }
        }
        pmesh.nearZ = nearZ;
        pmesh.farZ  = farZ;
        pmesh.indexDirty = true;
        pmesh.screenProjected = false;
        pmesh.faceProjected.sort(function(f1:Face, f2:Face):Number{ return gp[f1.gpi] - gp[f2.gpi]; });
        
        return this;
    }
    
//--------------------------------------------------rendering
    public function renderSolid(pmesh:ProjectionMesh, materialList:Array, light:Light) : Render3D {
        var idx:int, mat:Material, f:Face, vout:Vector.<Number> = pmesh.verticesOnScreen, 
            fn:Vector.<Number> = pmesh.faceNormalsOnWorld, g:Graphics = graphics;
        if (!pmesh.screenProjected) {
            Utils3D.projectVectors(_projectionMatrix, pmesh.verticesOnWorld, vout, pmesh.base.texCoords);
            pmesh.screenProjected = true;
        }
        g.clear();
        var i:int, imax:int = pmesh.faceProjected.length;
        for (i=0; i<imax; i++) {
            f = pmesh.faceProjected[i];
            mat = materialList[f.mat];
            idx = f.i0<<1;
            _data[0] = vout[idx]; idx++;
            _data[1] = vout[idx];
            idx = f.i1<<1;
            _data[2] = vout[idx]; idx++;
            _data[3] = vout[idx];
            idx = f.i2<<1;
            _data[4] = vout[idx]; idx++;
            _data[5] = vout[idx];
            g.beginFill(mat.getColor(light, fn[f.gpi-2], fn[f.gpi-1], fn[f.gpi]), mat.alpha);
            if (f.i3 == -1) {
                g.drawPath(_cmdTriangle, _data);
            } else {
                idx = f.i3<<1;
                _data[6] = vout[idx]; idx++;
                _data[7] = vout[idx];
                g.drawPath(_cmdQuadrangle, _data);
            }
            g.endFill();
        }
        return this;
    }
    
    public function renderWire(pmesh:ProjectionMesh, color:uint, alpha:Number=1, width:Number=1) : Render3D {
        var idx:int, vout:Vector.<Number> = pmesh.verticesOnScreen, g:Graphics = graphics;
        if (!pmesh.screenProjected) {
            Utils3D.projectVectors(_projectionMatrix, pmesh.verticesOnWorld, vout, pmesh.base.texCoords);
            pmesh.screenProjected = true;
        }
        g.clear();
        g.lineStyle(width, color, alpha);
        for each (var wire:Wire in pmesh.base.wires) {
            idx = wire.i0<<1;
            _data[0] = vout[idx]; idx++;
            _data[1] = vout[idx];
            idx = wire.i1<<1;
            _data[2] = vout[idx]; idx++;
            _data[3] = vout[idx];
            g.drawPath(_cmdWire, _data);
        }
        return this;
    }
    
    public function renderDepth(pmesh:ProjectionMesh) : Render3D {
        var i:int, imax:int = pmesh.vertexImax, g:Graphics = graphics, depth:Number,
            nearZ:Number = (_clippingZ < pmesh.nearZ) ? _clippingZ : pmesh.nearZ,
            r:Number = 1/(pmesh.farZ - nearZ), duvt:Vector.<Number> = _depthUVT;
        duvt.length = imax;
        for (i=2; i<imax; i+=5) {
            depth = (pmesh.verticesOnWorld[i] - nearZ) * r;
            duvt[i] = 0; i--;   // t
            duvt[i] = 0; i--;   // v
            duvt[i] = depth;    // u
        }
        Utils3D.projectVectors(_projectionMatrix, pmesh.verticesOnWorld, pmesh.verticesOnScreen, duvt);
        g.clear();
        g.beginBitmapFill(_depthMap, null, false, true);
        g.drawTriangles(pmesh.verticesOnScreen, pmesh.indicesProjected, duvt);
        g.endFill();
        return this;
    }
    private var _depthUVT:Vector.<Number> = new Vector.<Number>();
}

/** Point class that has both source and projected points. */
class Point3D extends Vector3D {
    public var world:Vector3D;
    function Point3D(x:Number=0, y:Number=0, z:Number=0, w:Number=1) { super(x,y,z,w); world=clone(); }
}

/** Face class */
class Face {
    public var index:int, i0:int, i1:int, i2:int, i3:int, gpi:int, mat:int;
    public var normal:Vector3D = new Vector3D();
    static private var _freeList:Vector.<Face> = new Vector.<Face>();
    static public function free(face:Face) : void { _freeList.push(face); }
    static public function alloc(index:int, i0:int, i1:int, i2:int, i3:int, mat:int) : Face { 
        var f:Face = _freeList.pop() || new Face();
        f.index=index; f.i0=i0; f.i1=i1; f.i2=i2; f.i3=i3; f.gpi=0; f.mat=mat;
        return f;
    }
}

/** Wire class */
class Wire {
    public var index:int, i0:int, i1:int;
    static private var _freeList:Vector.<Wire> = new Vector.<Wire>();
    static public function free(wire:Wire) : void { _freeList.push(wire); }
    static public function alloc(index:int, i0:int, i1:int) : Wire { 
        var w:Wire = _freeList.pop() || new Wire();
        w.index=index; w.i0=i0; w.i1=i1;
        return w;
    }
}

/** Mesh class. */
class Mesh {
    public var vertices:Vector.<Number>;                    // vertex
    public var verticesCount:int;                           // vertex count
    public var texCoords:Vector.<Number>;                   // texture coordinate
    public var gravPoints:Vector.<Number>;                  // gravity point
    public var faceNormals:Vector.<Number>;                 // face normal
    public var faces:Vector.<Face> = new Vector.<Face>();   // face list
    public var wires:Vector.<Wire> = new Vector.<Wire>();   // wireframe list
    
    /** constructor */
    function Mesh(vertexList:Array=null, faceList:Array=null) {
        if (vertexList) this.vertices = Vector.<Number>(vertexList);
        else            this.vertices = new Vector.<Number>();
        this.verticesCount = vertices.length / 3;
        this.texCoords = new Vector.<Number>();
        this.gravPoints = new Vector.<Number>();
        this.faceNormals = new Vector.<Number>();
        if (faceList) {
            for (var i:int=0; i<faceList.length; i+=3) face(faceList[i], faceList[i+1], faceList[i+2]);
            updateFaces(true);
        }
    }
    
    /** clear all faces */
    public function clear() : Mesh {
        var i:int, imax:int = faces.length;
        for (i=0; i<imax; i++) Face.free(faces[i]);
        faces.length = 0;
        gravPoints.length = 0;
        faceNormals.length = 0;
        return this;
    }
    
    /** register face */
    public function face(i0:int, i1:int, i2:int, mat:int=0) : Mesh {
        faces.push(Face.alloc(faces.length, i0, i1, i2, -1, mat));
        return this;
    }
    
    /** register quadrangle face. set div=true to divide into 2 triangles. */
    public function qface(i0:int, i1:int, i2:int, i3:int, mat:int=0, div:Boolean=true) : Mesh {
        if (div) {
            faces.push(Face.alloc(faces.length,   i0, i1, i2, -1, mat), 
                       Face.alloc(faces.length+1, i3, i2, i1, -1, mat));
        }
        else faces.push(Face.alloc(faces.length, i0, i1, i3, i2, mat));
        return this;
    }
    
    /** register wire */
    public function wire(i0:int, i1:int) : Mesh {
        wires.push(Wire.alloc(wires.length, i0, i1));
        return this;
    }
    
    /** update face gravity points and normal vectors. create wireframes when updateWire==true */
    public function updateFaces(updateWire:Boolean = false, facetAngle:Number = 180) : Mesh {
        var vtx:Vector.<Number> = vertices, gp:Vector.<Number> = gravPoints, fn:Vector.<Number> = faceNormals, 
            i:int, imax:int = faces.length, f:Face, vidx:int, i0:int, i1:int, i2:int, i3:int, 
            x01:Number, x02:Number, y01:Number, y02:Number, z01:Number, z02:Number;
        verticesCount = vertices.length/3;
        for (i=0; i<imax; i++) {
            f = faces[i];
            if (!f.gpi) {
                gp.length += 3;
                fn.length += 3;
                f.gpi = gp.length - 1;
            }
            vidx = f.gpi - 2;
            i0 = (f.i0<<1) + f.i0;
            i1 = (f.i1<<1) + f.i1;
            i2 = (f.i2<<1) + f.i2;
            x01 = vtx[i1] - vtx[i0];
            x02 = vtx[i2] - vtx[i0];
            gp[vidx] = (vtx[i0] + vtx[i1] + vtx[i2]) * 0.333333333333;
            vidx++; i0++; i1++; i2++;
            y01 = vtx[i1] - vtx[i0];
            y02 = vtx[i2] - vtx[i0];
            gp[vidx] = (vtx[i0] + vtx[i1] + vtx[i2]) * 0.333333333333;
            vidx++; i0++; i1++; i2++;
            z01 = vtx[i1] - vtx[i0];
            z02 = vtx[i2] - vtx[i0];
            gp[vidx] = (vtx[i0] + vtx[i1] + vtx[i2]) * 0.333333333333;
            f.normal.x = y02 * z01 - y01 * z02;
            f.normal.y = z02 * x01 - z01 * x02;
            f.normal.z = x02 * y01 - x01 * y02;
            f.normal.w = 0;
            f.normal.normalize();
            vidx = f.gpi - 2;
            fn[vidx] = f.normal.x; vidx++;
            fn[vidx] = f.normal.y; vidx++;
            fn[vidx] = f.normal.z;
            if (f.i3 != -1) {
                i3 = (f.i3<<1) + f.i3;
                vidx = f.gpi - 2;
                gp[vidx] = gp[vidx] * 0.75 + gp[i3] * 0.25; vidx++; i3++;
                gp[vidx] = gp[vidx] * 0.75 + gp[i3] * 0.25; vidx++; i3++;
                gp[vidx] = gp[vidx] * 0.75 + gp[i3] * 0.25;
            }
        }
        if (updateWire) {
            var facetCos:Number = Math.cos((180-facetAngle)*57.29577951308232);
            for (i=0; i<imax; i++) {
                f = faces[i];
                _wire(f, f.i0, f.i1);
                _wire(f, f.i1, f.i2);
                if (f.i3==-1) _wire(f, f.i2, f.i0);
                else { _wire(f, f.i2, f.i3); _wire(f, f.i3, f.i0); }
            }
        }
        return this;
        
        function _wire(f0:Face, i0:int, i1:int) : void {
            var fidx:int = findFaceByVertexIndex(i0, i1);
            if (fidx == -1 || facetCos >= f0.normal.dotProduct(faces[fidx].normal)) {
                var i:int, imax:int = wires.length, w:Wire;
                for (i=0; i<imax; i++) {
                    w = wires[i];
                    if ((w.i0==i0 && w.i1==i1) || (w.i0==i1 && w.i1==i0)) return;
                }
                wire(i0, i1);
            }
        }
    }
    
    /** find face by 2 vertex indexes. */
    public function findFaceByVertexIndex(i0:int, i1:int, prevIndex:int=-1) : int {
        var i:int, imax:int = faces.length, f:Face;
        for (i=prevIndex+1; i<imax; i++) {
            f = faces[i];
            if ((f.i0==i0 && f.i1==i1) || (f.i0==i1 && f.i1==i0) || (f.i1==i0 && f.i2==i1) || (f.i1==i1 && f.i2==i0)) return i;
            if (f.i3==-1) {
                if ((f.i2==i0 && f.i0==i1) || (f.i2==i1 && f.i0==i0)) return i;
            } else {
                if ((f.i2==i0 && f.i3==i1) || (f.i2==i1 && f.i3==i0) || (f.i3==i0 && f.i0==i1) || (f.i3==i1 && f.i0==i0)) return i;
            }
        }
        return -1;
    }
}

/** mesh for projection. */
class ProjectionMesh {
    /** ProjectionMesh sorter */
    static public function sorter(p0:ProjectionMesh, p1:ProjectionMesh) : Number { return p1.sortZ - p0.sortZ; }
    
    public var verticesOnWorld:Vector.<Number>;     // vertex on camera coordinate
    public var verticesOnScreen:Vector.<Number>;    // vertex on screen
    public var gravPointsOnWorld:Vector.<Number>;   // gravity points on camera coordinate
    public var faceNormalsOnWorld:Vector.<Number>;  // face normals on camera coordinate
    public var faceProjected:Vector.<Face>;         // projected faces
    public var vnormals:Vector.<Vector3D>;          // vertex normal
    public var nearZ:Number, farZ:Number;           // z buffer range
    public var position:Vector3D, sortZ:Number;     // object position and sorting Number
    public var screenProjected:Boolean = false;     // flag to projection on screen
    public var indexDirty:Boolean = false;          // flag to recalculate indexes
    public var base:Mesh = null;
    private var _projectedFaceIndices:Vector.<int> = new Vector.<int>();
    
    /** indices of projected faces */
    public function get indicesProjected() : Vector.<int> {
        var idx:Vector.<int> = _projectedFaceIndices, f:Face, i:int, imax:int, j:int;
        if (indexDirty) {
            idx.length = imax = faceProjected.length * 3;
            for (i=0,j=0; i<imax; j++) {
                f = faceProjected[j];
                idx[i] = f.i0; i++;
                idx[i] = f.i1; i++;
                idx[i] = f.i2; i++;
            }
            indexDirty = true;
        }
        return idx;
    }

    public function get vertexImax() : int { return (base.verticesCount<<1) + base.verticesCount; }
    public function get projected() : Boolean { return (position != null); }
    
    /** constructor */
    function ProjectionMesh(m:Mesh=null) {
        this.verticesOnWorld = new Vector.<Number>();
        this.verticesOnScreen = new Vector.<Number>();
        this.gravPointsOnWorld = new Vector.<Number>();
        this.faceNormalsOnWorld = new Vector.<Number>();
        this.faceProjected = new Vector.<Face>();
        this.vnormals = null;
        this.position = null;
        this.base = m || new Mesh();
    }
}

/** Light class */
class Light extends Point3D {
    public var halfVector:Vector3D = new Vector3D();
    
    /** constructor (set position) */
    function Light(x:Number=1, y:Number=1, z:Number=1) {
        super(x, y, z, 0);
        normalize();
    }

    /** projection */
    public function transformBy(viewMatrix:Matrix3D) : void {
        world = viewMatrix.deltaTransformVector(this);
        halfVector.x = world.x;
        halfVector.y = world.y;
        halfVector.z = world.z + 1; 
        halfVector.normalize();
    }
}

/** Material class */
class Material extends BitmapData {
    public var alpha:Number = 1;    // The alpha value is available for renderSolid()
    public var doubleSided:int = 0; // set doubleSided=-1 if double sided material
    
    /** constructor */
    function Material(dif:int=128, spc:int=128) { super(dif, spc, false); }
    
    /** set color. */
    public function setColor(col:uint, amb:int=64, dif:int=192, spc:int=0,  pow:Number=8) : Material {
        fillRect(rect, col);
        var lmap:LightMap = new LightMap(width, height);
        draw(lmap.diffusion(amb, dif), null, null, "hardlight");
        draw(lmap.specular (spc, pow), null, null, "add");
        lmap.dispose();
        return this;
    }
    
    /** calculate color by light and normal vector. */
    public function getColor(l:Light, nx:Number, ny:Number, nz:Number) : uint {
        var dir:Vector3D = l.world, hv:Vector3D = l.halfVector;
        var ln:int = int((dir.x * nx + dir.y * ny + dir.z * nz) * (width-1)),
            hn:int = int((hv.x  * nx + hv.y  * ny + hv.z  * nz) * (height-1));
        if (ln<0) ln = (-ln) & doubleSided;
        if (hn<0) hn = (-hn) & doubleSided;
        return getPixel(ln, hn);
    }
}

/** Light map */
class LightMap extends BitmapData {
    function LightMap(dif:int, spc:int) { super(dif, spc, false); }
    
    public function diffusion(amb:int, dif:int) : BitmapData {
        var col:int, rc:Rectangle = new Rectangle(0, 0, 1, height), ipk:Number = 1 / width;
        for (rc.x=0; rc.x<width; rc.x+=1) {
            col = ((rc.x * (dif - amb)) * ipk) + amb;
            fillRect(rc, (col<<16)|(col<<8)|col);
        }
        return this;
    }
    
    public function specular(spc:int, pow:Number) : BitmapData {
        var col:int, rc:Rectangle = new Rectangle(0, 0, width, 1),
            mpk:Number = (pow + 2) * 0.15915494309189534, ipk:Number = 1 / height;
        for (rc.y=0; rc.y<height; rc.y+=1) {
            col = Math.pow(rc.y * ipk, pow) * spc * mpk;
            if (col > 255) col = 255;
            fillRect(rc, (col<<16)|(col<<8)|col);
        }
        return this;
    }
}

/** Hexagonal Pillars */
class HexagonalPillar extends ProjectionMesh {
    public var ratio:Number, height:Number = 10, wave:Number = 0, row:int, col:int;
    function HexagonalPillar(row:int, col:int) {
        super();
        base.vertices.length = 36;
        for (i=1; i<6; i++) base.qface(i-1,i,i+5,i+6,0,true);
        base.qface(5,0,11,6,0,true);
        for (var i:int=1; i<5; i++) base.face(0,i+1,i);
        this.row = row; this.col = col;
        height = pillarHeight;
        ratio = 0.75;
        _updateVertex();
    }
    private function _updateVertex() : void {
        var i:int, j:int;
        for (i=0, j=18; i<18;) {
            base.vertices[j] = hexVertex[i]; j++;
            base.vertices[i] = hexVertex[i] * ratio; i++;
            base.vertices[j] = hexVertex[i]; j++;
            base.vertices[i] = hexVertex[i] * ratio; i++;
            base.vertices[j] = -20; j++;
            base.vertices[i] = height+wave; i++;
        }
        base.updateFaces();
    }
    public function project(gl:Render3D, hd:Number) : void {
        var x:Number = (row-8+scroll) * radius * 1.5, 
            y:Number = ((col*2+(row&1))-2) * radius * 0.8660254037844385;
        wave = Math.sin(x*0.02702445293410575 + wavePhase + col * 0.39269908169872414 * Math.sin(wavePhase*0.0625)) * waveHeight;
        height = (height-pillarHeight)*hd + pillarHeight;
        _updateVertex();
        gl.push().t(x, y, 0).project(this).pop();
        nearZ = -30;
        farZ = -150;
    }
    public function render(gl:Render3D) : void {
        //timer.start(1);
        depth.draw(gl.renderDepth(this), centering);
        //timer.pause(1);
        //timer.start(2);
        screen.draw(gl.renderSolid(this, materials, light), centering);
        //timer.pause(2);
    }
    static public var pillarHeight:Number = 0, heightDump:Number = 0.03125;
    static public var wavePhaseDelta:Number, waveHeight:Number = 10;
    static public var radius:Number = 10, scroll:Number=0, wavePhase:Number=0, speed:Number=1;
    static public var hexVertex:Vector.<Number> = new Vector.<Number>(18, true);
    static public var pillars:Array = new Array(45);//45
    static public var centering:Matrix, screen:BitmapData, depth:BitmapData;
    static public var materials:Array = [(new Material()).setColor(0xc0e0f0, 64, 192, 8, 40)];
    static public var light:Light = new Light(1,0.5,0.25);
    static public var camera:Vector3D = new Vector3D(0, 0, -80);
    static public function set bpm(n:Number) : void { wavePhaseDelta = n*0.02617993877991494; }
    static public function initialize(w:Number, h:Number) : void {
        var i:int, imax:int = pillars.length;
        for (i=0; i<18; i+=3) {
            hexVertex[i]   = Math.cos(i*0.3490658503988659) * radius;
            hexVertex[i+1] = Math.sin(i*0.3490658503988659) * radius;
            hexVertex[i+2] = 0;
        }
        for (i=0; i<imax; i++) pillars[i] = new HexagonalPillar(i%15, i/15);
        screen = new BitmapData(w, h, false, 0);
        depth  = new BitmapData(w, h, false, 0);
        centering = new Matrix(1, 0, 0, 1, w*0.5, h*0.5);
    }
    static public function update(gl:Render3D, nx:Number, ny:Number, dt:Number) : void {
        var i:int, imax:int = pillars.length, hd:Number = Math.pow(heightDump, dt);
        var head:Number = (0.5-nx)*70;
        var pitch:Number = (0.5-ny)*40;
        if (head < -30) head = -30;
        else if (head > 30) head = 30;
        if (pitch < -15) pitch = -15;
        else if (pitch > 15) pitch = 15;
        _scroll(dt);
        wavePhase += wavePhaseDelta * dt;
        light.transformBy(gl.id().tv(camera).rx(pitch-40).ry(-head).matrix);
        depth.fillRect(depth.rect, 0);
        screen.fillRect(screen.rect, 0xffffff);
        //timer.start(3);
        for (i=0; i<imax; i++) pillars[i].project(gl, hd);
        pillars.sort(ProjectionMesh.sorter);
        //timer.pause(3);
        for (i=0; i<imax; i++) pillars[i].render(gl);
    }
    static private function _scroll(dt:Number) : void {
        scroll += speed * dt;
        if (scroll > 2) {
            scroll -= 2;
            var i:int, imax:int = pillars.length;
            for (i=0; i<imax; i++) { 
                pillars[i].row += 2;
                if (pillars[i].row > 14) pillars[i].row-=15;
            }
        }
    }
    static public function find(row:int, col:int) : HexagonalPillar {
        var i:int, imax:int = pillars.length;
        row -= (scroll>=1) ? 1 : 0;
        for (i=0; i<imax; i++) { 
            if (pillars[i].row == row && pillars[i].col == col) return pillars[i];
        }
        return null;
    }
}
