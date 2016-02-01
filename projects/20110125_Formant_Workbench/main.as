package {
    import flash.text.*;
    import flash.geom.*;
    import flash.display.*;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.utils.*;
    import org.si.sound.*;
    
    import com.bit101.components.*;
    import org.si.sound.mdx.*;
    import flash.utils.ByteArray;
    import flash.net.*;
    
    public class main extends Sprite {
        private var driver:SiONDriver = new SiONDriver();
        private var vowel:SiFilterVowel = new SiFilterVowel();
        private var formantControler:FormantControler;
        private var vowelControler:ControlPad, vowelMap:Bitmap;
        private var defaultWave:Vector.<Number> = new Vector.<Number>(1024);
        
        function main() {
            driver.debugMode = true;
            addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
            Style_POINTER = 0xff6060;

            var i:int, t:Number;
            for (i=0, t=0; i<1024; i++, t+=0.0009765625) {
                if (t < .3)       defaultWave[i] = t * t / 0.09 * (3. - 2 * t / 0.3);
                else if (t < .42) defaultWave[i] = 1 - (t - 0.3) * (t - 0.3) / 0.0144;
                else              defaultWave[i] = 0;
            }
            driver.setWaveTable(0, defaultWave);
        }
        
        private function _onAddedToStage(e:Event) : void {
            e.target.removeEventListener(e.type, arguments.callee);
            formantControler = new FormantControler(this, 32, 220);
            formantControler.onUpdate = _onUpdateFormant;
            vowelControler = new ControlPad(this, 32, 32, 180, 180);
            vowelControler.onChange = _onChangeVowel;
            vowelControler.setPointer(formantControler.freq[0]/1000, (2400-formantControler.freq[1])/1600);
            var tf:TextField = new TextField(), mat:Matrix = new Matrix();
            tf.defaultTextFormat = new TextFormat(null, 30, 0x808080);
            vowelControler.back.addChild(vowelMap = new Bitmap(new BitmapData(180, 180, true, 0)));
            _drawVowelMap(30, 25, "i");
            _drawVowelMap(80, 20, "e");
            _drawVowelMap(150, 90, "a");
            _drawVowelMap(35, 130, "u");
            _drawVowelMap(70, 140, "o");
            for (var i:int=0; i<6; i++) updateFormant(i);
            driver.effector.slot0 = [vowel];
            new FormantInput(this, updateMML);
            function _drawVowelMap(x:Number, y:Number, text:String) : void {
                mat.tx = x;
                mat.ty = y;
                tf.text = text;
                vowelMap.bitmapData.draw(tf, mat);
            }
        }
        
        private function _onUpdateFormant() : void {
            updateFormant(formantControler.dragIndex);
        }
        
        private function _onChangeVowel() : void {
            formantControler.freq[0] = vowelControler.rx * 1000;
            formantControler.freq[1] = 2400 - vowelControler.ry * 1600;
            formantControler.draw();
            updateFormant(0);
            updateFormant(1);
        }
        
        private function updateFormant(idx:int) : void {
            vowel.formant[idx].update(SiFilterVowelFormant.calcFreqIndex(formantControler.freq[idx]), formantControler.band[idx], formantControler.gain[idx]);
        }
        
        private function updateMML(mml:String) : void {
            driver.play(mml, false);
        }
    }
}




import flash.display.*;
import flash.events.*;
import flash.geom.*;
import com.bit101.components.*;
import org.si.sion.effector.*;
import org.si.sion.sequencer.SiMMLTable;
import org.si.utils.SLLint;

var Style_POINTER:uint;

class FormantInput extends Sprite {
    private var input:InputText, _updateMML:Function;
    function FormantInput(parent:DisplayObjectContainer, updateMML:Function) {
        parent.addChild(this);
        this.x = 210;
        this.y = 32;
        var test:PushButton = new PushButton(this, 4, 4, "TEST MML", _onTestMML);
        input = new InputText(this, 72, 4, "%5@256@v3 kt-12 $cdefgfedc1");
        test.setSize(68, 18);
        input.setSize(165, 18);
        _updateMML = updateMML;
        _onTestMML(null);
    }
    
    private function _onTestMML(e:Event) : void {
        _updateMML(input.text);
    }
}

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
        pointer.graphics.beginFill(Style_POINTER, 0.5);
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


class FormantControler extends ControlPad {
    public var env:Sprite, grid:Shape;
    public var freq:Vector.<Number> = Vector.<Number>([800, 1300, 2300, 3500, 4500, 5000])
    public var gain:Vector.<Number> = Vector.<Number>([36,  24,   12,   9,    6,    6]);
    public var band:Vector.<Number> = Vector.<Number>([3,   3,    2,    3,    3,    3]);
    public var dragIndex:int, pt:Vector.<Point>, onUpdate:Function;
    public var knob:Vector.<Knob> = new Vector.<Knob>(6);
    
    function FormantControler(parent:DisplayObjectContainer, x:Number, y:Number) {
        pt = new Vector.<Point>(6);
        dragIndex = 0;
        super(parent, x, y, 400, 180);
        back.addChild(grid = new Shape());
        back.addChild(env = new Sprite());
        env.filters = [getShadow(1)];
        addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        onChange = _onChange;
        onStart = _onStart;
        onStop = _onStop;
        var i:int, t:Number, dt:Number, g:Graphics = grid.graphics;
        g.lineStyle(1, Style.LABEL_TEXT);
        for (i=1, t=(dt=w/16)+5; i<16; i++, t+=dt) {
            g.moveTo(t, 5);
            g.lineTo(t, h+5);
        }
        for (i=1, t=(dt=h/10)+5; i<10; i++, t+=dt) {
            g.moveTo(5, t);
            g.lineTo(w+5, t);
        }
        for (i=0; i<6; i++) {
            knob[i] = new Knob(this, i*70+20, 180, "band["+String(i)+"]", function(e:Event):void{
                var idx:int = int((e.target.x - 35) / 70);
                if (idx<0 || idx>7) return;
                dragIndex = idx;
                band[dragIndex] = int(e.target.value);
                onUpdate();
            });
            knob[i].radius = 10;
            knob[i].labelPrecision = 0;
            knob[i].minimum = 0;
            knob[i].maximum = 7;
            knob[i].value = band[i];
        }
    }
    
    override public function draw() : void {
        super.draw();
        updateEnvelop();
    }
    
    protected function updateEnvelop() : void {
        var i:int, g:Graphics = env.graphics;
        g.clear();
        g.lineStyle(2,Style.BUTTON_FACE);
        for (i=0; i<6; i++) {
            pt[i] = new Point((freq[i]/6400)*w, h-((gain[i]+12)/60)*h);
            g.moveTo(pt[i].x+5, h-36+5);
            g.lineTo(pt[i].x+5, pt[i].y+5);
        }
    }
    
    protected function _onStart() : void { removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove); }
    protected function _onStop()  : void { addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove); }
    
    protected function onMouseMove(e:MouseEvent) : void {
        var i:int, dx:Number=pt[0].x-mouseX, dy:Number=pt[0].y-mouseY, d2:Number=dx*dx+dy*dy;
        for (dragIndex=0, i=1; i<6; i++) {
            dx = pt[i].x - mouseX;
            dy = pt[i].y - mouseY;
            if (dx*dx+dy*dy < d2) {
                d2 = dx*dx+dy*dy;
                dragIndex = i;
            }
        }
        pointer.x = pt[dragIndex].x;
        pointer.y = pt[dragIndex].y;
    }
    
    protected function _onChange() : void {
        freq[dragIndex] = rx * 6400;
        gain[dragIndex] = (1-ry) * 60 - 12;
        updatePointerPosition();
        updateEnvelop();
        onUpdate();
    }
}


// Vowel filter
//----------------------------------------------------------------------------------------------------
class SiFilterVowel extends SiEffectBase {
//------------------------------------------------------------ variables
    static public const FORMANT_COUNT:int = 6;
    public var formant:Vector.<SiFilterVowelFormant>;
    public var outputLevel:Number = 1;
    
    // tap matrix
    private var _t0i0:Number, _t0i1:Number, _t0o0:Number, _t0o1:Number;
    private var _t1i0:Number, _t1i1:Number, _t1o0:Number, _t1o1:Number;
    private var _t2i0:Number, _t2i1:Number, _t2o0:Number, _t2o1:Number;
    private var _t3i0:Number, _t3i1:Number, _t3o0:Number, _t3o1:Number;
    private var _t4i0:Number, _t4i1:Number, _t4o0:Number, _t4o1:Number;
    private var _t5i0:Number, _t5i1:Number, _t5o0:Number, _t5o1:Number;
    
//------------------------------------------------------------ constructor
    function SiFilterVowel() {
        SiFilterVowelFormant.initialize();
        formant = new Vector.<SiFilterVowelFormant>(FORMANT_COUNT, true);
        for (var i:int=0; i<FORMANT_COUNT; i++) formant[i] = new SiFilterVowelFormant();
        formant[0].update(SiFilterVowelFormant.calcFreqIndex(800),  3, 30);
        formant[1].update(SiFilterVowelFormant.calcFreqIndex(1300), 2, 18);
        formant[2].update(SiFilterVowelFormant.calcFreqIndex(2200), 3, 10);
        formant[3].update(SiFilterVowelFormant.calcFreqIndex(3500), 3, 10);
        formant[4].update(SiFilterVowelFormant.calcFreqIndex(4500), 3, 10);
        formant[5].update(SiFilterVowelFormant.calcFreqIndex(5000), 3, 10);
    }
    
//------------------------------------------------------------ operation
    override public function prepareProcess() : int {
        _t0i0 = _t0i1 = _t0o0 = _t0o1 = 0;
        _t1i0 = _t1i1 = _t1o0 = _t1o1 = 0;
        _t2i0 = _t2i1 = _t2o0 = _t2o1 = 0;
        _t3i0 = _t3i1 = _t3o0 = _t3o1 = 0;
        _t4i0 = _t4i1 = _t4o0 = _t4o1 = 0;
        _t5i0 = _t5i1 = _t5o0 = _t5o1 = 0;
        return 1;
    }
    
    override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int {
        startIndex <<= 1;
        length <<= 1;
        var i:int, output:Number, input:Number, imax:int=startIndex+length, 
            f1ab1:Number = formant[0].ab1, f1a2:Number = formant[0].a2, f1b0:Number = formant[0].b0, f1b2:Number = formant[0].b2, 
            f2ab1:Number = formant[1].ab1, f2a2:Number = formant[1].a2, f2b0:Number = formant[1].b0, f2b2:Number = formant[1].b2, 
            f3ab1:Number = formant[2].ab1, f3a2:Number = formant[2].a2, f3b0:Number = formant[2].b0, f3b2:Number = formant[2].b2, 
            f4ab1:Number = formant[3].ab1, f4a2:Number = formant[3].a2, f4b0:Number = formant[3].b0, f4b2:Number = formant[3].b2, 
            f5ab1:Number = formant[4].ab1, f5a2:Number = formant[4].a2, f5b0:Number = formant[4].b0, f5b2:Number = formant[4].b2, 
            f6ab1:Number = formant[5].ab1, f6a2:Number = formant[5].a2, f6b0:Number = formant[5].b0, f6b2:Number = formant[5].b2;
        for (i=startIndex; i<imax;) {
            input = buffer[i];
            output = f1b0 * input + f1ab1 * _t0i0 + f1b2 * _t0i1 - f1ab1 * _t0o0 - f1a2 * _t0o1;
            _t0i1 = _t0i0; _t0i0 = input; _t0o1 = _t0o0; _t0o0 = input = output;
            output = f2b0 * input + f2ab1 * _t1i0 + f2b2 * _t1i1 - f2ab1 * _t1o0 - f2a2 * _t1o1;
            _t1i1 = _t1i0; _t1i0 = input; _t1o1 = _t1o0; _t1o0 = input = output;
            output = f3b0 * input + f3ab1 * _t2i0 + f3b2 * _t2i1 - f3ab1 * _t2o0 - f3a2 * _t2o1;
            _t2i1 = _t2i0; _t2i0 = input; _t2o1 = _t2o0; _t2o0 = input = output;
            output = f4b0 * input + f4ab1 * _t3i0 + f4b2 * _t3i1 - f4ab1 * _t3o0 - f4a2 * _t3o1;
            _t3i1 = _t3i0; _t3i0 = input; _t3o1 = _t3o0; _t3o0 = input = output;
            output = f5b0 * input + f5ab1 * _t4i0 + f5b2 * _t4i1 - f5ab1 * _t4o0 - f5a2 * _t4o1;
            _t4i1 = _t4i0; _t4i0 = input; _t4o1 = _t4o0; _t4o0 = input = output;
            output = f6b0 * input + f6ab1 * _t5i0 + f6b2 * _t5i1 - f6ab1 * _t5o0 - f6a2 * _t5o1;
            _t5i1 = _t5i0; _t5i0 = input; _t5o1 = _t5o0; _t5o0 = input = output;
            output *= outputLevel;
            if (output < -1) output = -1;
            else if (output > 1) output = 1;
            buffer[i] = output; i++;
            buffer[i] = output; i++;
        }
        return 1;
    }
}


class SiFilterVowelFormant {
    static private var _alphaTable:Vector.<Vector.<Number>> = null;
    static private var _cosTable:Vector.<Number> = null;
    static private var _gainTable:Vector.<Number> = null;
    static private var _ibandList:Array = [0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4];
    static public function initialize() : void {
        if (!_alphaTable) {
            var iband:int, ifreq:int, igain:int, band:Number, freq:Number, table:Vector.<Number>, 
                omg:Number, cos:Number, sin:Number, angh:Number;            
            _alphaTable = new Vector.<Vector.<Number>>(8, true);
            for (iband=0; iband<8; iband++) {
                _alphaTable[iband] = table = new Vector.<Number>(1024, true);
                band = _ibandList[iband];
                for (ifreq=0, freq=50; ifreq<1024; ifreq++, freq*=1.0218971486541166) { // 2^(1/32)
                    omg  = freq * 0.00014247585730565955; // 2*pi/44100
                    sin  = Math.sin(omg);
                    angh = 0.34657359027997264 * band * omg / sin; // log(2)*0.5
                    table[ifreq] = sin * (Math.exp(angh) - Math.exp(-angh)) * 0.5; // sin * sinh(angh)
                }
            }
            _cosTable = new Vector.<Number>(1024, true);
            for (ifreq=0, freq=50; ifreq<1024; ifreq++, freq*=1.0218971486541166) { // 2^(1/32)
                _cosTable[ifreq]  = Math.cos(freq * 0.00014247585730565955);
            }
            _gainTable = new Vector.<Number>(128, true);
            for (igain=0; igain<128; igain++) {
                _gainTable[igain] = Math.pow(10, (igain-32)*0.025);
            }
        }
    }
    
    static public function calcFreqIndex(frequency:Number) : int {
        var ifreq:int = (Math.log(frequency) * 1.4426950408889633 - 5.643856189774724) * 32; // * 1/loge(2) - log2(50)
        if (ifreq < 0) return 0;
        if (ifreq > 1023) return 1023;
        return ifreq
    }
    
    public var ab1:Number, a2:Number, b0:Number, b2:Number;
    
    function SiFilterVowelFormant() {
        clear();
    }
    
    public function clear() : void {
        b0 = 1;
        ab1 = a2 = b2 = 0;
    }
    
    public function update(ifreq:int, iband:int, gain:int) : void {
        gain += 32;
        if (gain < 0) gain = 0;
        else if (gain > 127) gain = 127;
        var alp:Number   = _alphaTable[iband][ifreq],
            A:Number     = _gainTable[gain],
            alpA:Number  = alp * A, 
            alpiA:Number = alp / A,
            ia0:Number   = 1 / (1+alpiA);
        ab1 = -2 * _cosTable[ifreq] * ia0;
        a2 = (1-alpiA) * ia0;
        b0 = (1+alpA) * ia0;
        b2 = (1-alpA) * ia0;
    }
}


