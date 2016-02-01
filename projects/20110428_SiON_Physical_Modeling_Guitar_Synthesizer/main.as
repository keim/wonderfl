package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;
    import com.bit101.components.*;

    [SWF(width='465', height='465', backgroundColor='#000000', frameRate='60')]
    public class main extends Sprite {
        private var _guitar:Guitar;
        private var _prevMouseY:Number, _prevMouseY2:Number, _prevMouseX:Number, _prevMouseVelocity:Number;
        private var _tension:HUISlider, _detune:HUISlider, _seedtype:HUISlider, _angle:HUISlider;
        private var _stroke:HUISlider, _cutoff:HUISlider, _resonance:HUISlider, _chorus:HUISlider, _reverb:HUISlider;
        private var _autotune:CheckBox, _angledetect:CheckBox, _strokedetect:CheckBox, _seedtypename:Label;
        private var _chord:Label, _message:Label;
        
        private var _controler:Sprite, _tab:Sprite, _strings:Sprite;
        private var _stringsAmps:Vector.<Number> = new Vector.<Number>(6, true);
        
        // entry point
        function main() {
            var y:Number = 0, x:Number = 0;
            graphics.beginFill(0);
            graphics.drawRect(0,0,465,465);
            graphics.endFill();
            addEventListener(Event.ADDED_TO_STAGE, setup);
            addChild(_controler = new Sprite());
            addChild(_tab = new Sprite());
            addChild(_strings = new Sprite());
            _controler.y = 20;
            _tab.x = 20;
            _tab.y = 270;
            _strings.x = 280;
            _strings.y = 270;
            _chord = new Label(this, 20, 320);
            _chord.scaleX = _chord.scaleY = 5;
            _message = new Label(this, 20, 400, "Scratch gut to strum the guitar!");
            _message.scaleX = _message.scaleY = 2;
            _seedtype = _slider("SeedNoiseType", 0, 1, 0, 5, 4, function(e:Event):void { 
                _guitar.ws = int(e.target.value);
                _seedtypename.text = ["[White]", "[Pulse]", "[93bit]", "[Hipass]", "[Perlin]", "[128bit]"][int(e.target.value)];
            });
            _tension = _slider("Tension", 2, 0.01, 0, 1, 0.1, function(e:Event):void { 
                _guitar.tension = e.target.value;
                if (_autotune.selected) {
                    _guitar.detune = _detune.value = -e.target.value*16;
                }
            });
            _detune = _slider("Detune", 1, 0.1, -24, 24, -1.6, function(e:Event):void { _guitar.detune = e.target.value; });
            _angle = _slider("PlunkAngle", 2, 0.01, 0, 1, 1, function(e:Event):void { _guitar.angle = e.target.value; });
            _stroke = _slider("StrokeSpeed", 2, 0.01, 0, 1, 0.25);
            _cutoff = _slider("LPFilter", 2, 0.01, 0, 1, 1, function(e:Event):void { _guitar.cutoff = e.target.value; });
            _resonance = _slider("Resonanse", 2, 0.01, 0, 1, 0, function(e:Event):void { _guitar.resonance = e.target.value; });
            y += 10;
            _reverb = _slider("ReverbSend", 2, 0.01, 0, 1, 0, function(e:Event):void { _guitar.reverbSend = e.target.value; });
            _chorus = _slider("ChorusSend", 2, 0.01, 0, 1, 0, function(e:Event):void { _guitar.chorusSend = e.target.value; });
            _seedtypename = new Label(_controler, 210, 0, "[Perlin]");
            _autotune = new CheckBox(_controler, 220, 44, "AutoTune");
            _autotune.selected = true;
            _angledetect = new CheckBox(_controler, 220, 64, "FromGesture");
            _angledetect.selected = true;
            _strokedetect = new CheckBox(_controler, 220, 84, "FromGesture");
            _strokedetect.selected = true;
            x = 40;
            y = 110;
            _button("maj", function(e:Event):void { _guitar.chord = "maj"; updateTab(); });
            _button("m", function(e:Event):void { _guitar.chord = "m"; updateTab(); });
            _button("7", function(e:Event):void { _guitar.chord = "7"; updateTab(); });
            _button("M7", function(e:Event):void { _guitar.chord = "M7"; updateTab(); });
            _button("m7", function(e:Event):void { _guitar.chord = "m7"; updateTab(); });
            x = 0;
            y = 150;
            _button("A",  function(e:Event):void { _guitar.note = 0; updateTab(); });
            _button("A#", function(e:Event):void { _guitar.note = 1; updateTab(); });
            _button("B",  function(e:Event):void { _guitar.note = 2; updateTab(); });
            _button("C",  function(e:Event):void { _guitar.note = 3; updateTab(); });
            _button("C#", function(e:Event):void { _guitar.note = 4; updateTab(); });
            _button("D",  function(e:Event):void { _guitar.note = 5; updateTab(); });
            x = 0;
            y = 170;
            _button("D#", function(e:Event):void { _guitar.note = 6; updateTab(); });
            _button("E",  function(e:Event):void { _guitar.note = 7; updateTab(); });
            _button("F",  function(e:Event):void { _guitar.note = 8; updateTab(); });
            _button("F#", function(e:Event):void { _guitar.note = 9; updateTab(); });
            _button("G",  function(e:Event):void { _guitar.note = 10; updateTab(); });
            _button("G#", function(e:Event):void { _guitar.note = 11; updateTab(); });
            
            function _slider(label:String, prec:int, tick:Number, min:Number, max:Number, val:Number, func:Function=null) : HUISlider {
                var slider:HUISlider = new HUISlider(_controler, 0, y, label, func);
                slider.labelPrecision = prec;
                slider.tick = tick;
                slider.setSliderParams(min, max, val);
                slider.setSize(240, 16);
                y += 20;
                return slider;
            }
            function _button(label:String, func:Function=null) : PushButton {
                var button:PushButton = new PushButton(_controler, 225+x, y, label, func);
                button.setSize(38, 16);
                x += 40;
                return button;
            }
        }

        public function setup(e:Event) : void {
            removeEventListener(Event.ADDED_TO_STAGE, setup);
            _guitar = new Guitar(onNoteOn);
            _strings.addEventListener(MouseEvent.MOUSE_DOWN, _beginDrag);
            addEventListener(Event.ENTER_FRAME, draw);
            updateTab();
        }
        
        private function draw(e:Event) : void {
            var g:Graphics = _strings.graphics, i:int;
            g.clear();
            g.beginFill(0);
            g.drawRect(-20, -60, 240, 200);
            g.endFill();
            for (i=0; i<6; i++) {
                _stringsAmps[i] *= -0.95;
                g.lineStyle(1, 0x404040);
                g.beginFill(0x404040);
                g.drawRect(0,i*10+5-_stringsAmps[i]*2,160,_stringsAmps[i]*4);
                g.endFill();
                g.lineStyle(1, 0x808080);
                g.moveTo(0,  i*10+5+_stringsAmps[i]*2);
                g.lineTo(160,i*10+5+_stringsAmps[i]*2);
            }
        }
        
        private function onNoteOn(stringNum:int) : void {
            _stringsAmps[stringNum] = 1;
        }
        
        private function updateTab() : void {
            var g:Graphics = _tab.graphics, i:int;
            g.clear();
            g.lineStyle(1, 0xc0c0c0);
            g.beginFill(0x808080);
            g.drawRect(0,0,240,60);
            g.endFill();
            for (i=1; i<8; i++) {
                g.moveTo(i*30, 0);
                g.lineTo(i*30, 60);
            }
            for (i=1; i<6; i++) {
                g.moveTo(0,  i*10);
                g.lineTo(240,i*10);
            }
            g.beginFill(0xc04040);
            for (i=0; i<6; i++) {
                if (_guitar.fingerPosition[i] > 0) g.drawCircle(_guitar.fingerPosition[i]*30-15,i*10+5,3);
                else if (_guitar.fingerPosition[i] < 0) {
                    g.moveTo(-10, i*10+1);
                    g.lineTo(-2, i*10+9);
                    g.moveTo(-2, i*10+1);
                    g.lineTo(-10, i*10+9);
                }
            }
            g.endFill();
            _chord.text = _guitar.chordString;
        }
        
        private function _beginDrag(e:MouseEvent) : void {
            _prevMouseX = mouseX;
            _prevMouseY2 = _prevMouseY = mouseY;
            _prevMouseVelocity = 0;
            stage.addEventListener(MouseEvent.MOUSE_MOVE, _dragging);
            stage.addEventListener(MouseEvent.MOUSE_UP,   _endDrag);
        }
        
        private function _dragging(e:MouseEvent) : void {
            var mouseVelocity2:Number = _prevMouseY2 - _prevMouseY,
                mouseVelocity:Number = _prevMouseY - mouseY;
            if ((mouseVelocity2 < -10 || mouseVelocity2 > 10) && 
                (mouseVelocity  < -10 || mouseVelocity  > 10) && 
                (_prevMouseVelocity * mouseVelocity <= 0)) {
                if (_angledetect.selected) {
                    var ang:Number = (_prevMouseX - mouseX) * 0.25 / mouseVelocity;
                    if (ang < 0) ang = -ang;
                    if (ang > 1) ang = 1;
                    _guitar.angle = _angle.value = 1 - ang;
                }
                if (_strokedetect.selected) {
                    var str:Number = mouseVelocity * 0.025;
                    if (str < 0) str = -str;
                    if (str > 1.1) str = 1.1;
                    _stroke.value = 1.2 - str;
                }
                _guitar.plunk(((mouseVelocity < 0) ? 4410 : -4410) * _stroke.value);
                _prevMouseVelocity = mouseVelocity;
            }
            _prevMouseX = mouseX
            _prevMouseY2 = _prevMouseY;
            _prevMouseY = mouseY;
        }
        
        private function _endDrag(e:MouseEvent) : void {
            if (_prevMouseVelocity == 0) _guitar.mute();
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, _dragging);
            stage.removeEventListener(MouseEvent.MOUSE_UP,   _endDrag);
        }
    }
}




import org.si.sion.*;
import org.si.sion.sequencer.*;
import org.si.sion.effector.*;
import org.si.sion.events.*;


class Guitar {
    public var fingerPosition:Vector.<int> = new Vector.<int>(6, true);
    
    public function set ws(i:int) : void {
        _ws = i+16;
        updateVoice();
    }
    public function set tension(t:Number) : void {
        _tension = t * 48 + 2;
        _pitchShift = t * 16 * 64;
        updateVoice();
    }
    public function set detune(p:Number) : void {
        _detune = p * 64;
        updateVoice();
    }
    public function set angle(v:Number) : void {
        _ar = v * 24 + 24;
        _tl = 12 - v * 12;
        updateVoice();
    }
    public function set cutoff(l:Number) : void {
        _cutoff = l*128;
        updateVoice();
    }
    public function set resonance(l:Number) : void {
        _resonance = l*8;
        updateVoice();
    }
    public function set reverbSend(l:Number) : void {
        for (var i:int=0; i<6; i++) _tracks[i].effectSend1 = l*48;
    }
    public function set chorusSend(l:Number) : void {
        for (var i:int=0; i<6; i++) _tracks[i].effectSend2 = l*24;
    }
    public function set chord(c:String) : void {
        _chord = c;
        var pos:Array = _chordList[_chord][_baseNote];
        for (var i:int=0; i<6; i++) fingerPosition[i] = pos[i];
    }
    public function set note(n:int) : void {
        _baseNote = n % 12;
        var pos:Array = _chordList[_chord][_baseNote];
        for (var i:int=0; i<6; i++) fingerPosition[i] = pos[i];
    }
    public function get chordString() : String {
        return ["A","A#","B","C","C#","D","D#","E","F","F#","G","G#"][_baseNote] + _chord;
    }
    
    private var _ar:int=48, _dr:int=48, _tl:int=0, _fixedPitch:int=68, _ws:int=20, _tension:int=8;
    private var _pitchShift:int = 0, _detune:int = 0, _vel:int = 128, _cutoff:int = 128, _resonance:int = 0;
    private var _driver:SiONDriver = new SiONDriver();
    private var _voice:SiONVoice = new SiONVoice();
    private var _tracks:Vector.<SiMMLTrack> = new Vector.<SiMMLTrack>(6, true);
    private var _stringBaseNotes:Vector.<int> = Vector.<int>([40,45,50,55,59,64]);
    private var _baseNote:int = 0, _chord:String = "maj";
    private var _onNoteOn:Function;
    
    function Guitar(noteOn:Function) : void {
        _onNoteOn = noteOn;
        _driver.debugMode = true;
        _driver.effector.slot1 = [new SiEffectStereoReverb(0.7, 0.4, 0.9, 1)];
        _driver.effector.slot2 = [new SiEffectStereoChorus(20, 0.2, 4, 20, 1)];
        _driver.play(null, false);
        _driver.addEventListener(SiONTrackEvent.NOTE_ON_FRAME, _noteOn);
        for (var i:int=0; i<6; i++) {
            _tracks[i] = _driver.newUserControlableTrack(i);
            _tracks[i].masterVolume = 24;
            _tracks[i].effectSend1 = 0;
            _tracks[i].effectSend2 = 0;
            _tracks[i].setEventTrigger(i, 1, 0);
        }
        updateVoice();
        note = 0;
    }
    
    public function plunk(delay:int = 100) : void {
        var delayMax:int = (delay<0) ? -(delay*5) : 0;
        for (var i:int=0; i<6; i++) {
            if (fingerPosition[i] >= 0) {
                _tracks[i].keyOn(_stringBaseNotes[i]+fingerPosition[i], 0, i*delay+delayMax);
            }
        }
    }
    
    public function mute() : void {
        for (var i:int=0; i<6; i++) _tracks[i].keyOff(0);
    }
    
    public function updateVoice() : void {
        _voice.setPMSGuitar(_ar, _dr, _tl, _fixedPitch, _ws, _tension);
        _voice.setLPFEnvelop(_cutoff, _resonance);
        for (var i:int=0; i<6; i++) {
            _voice.setTrackVoice(_tracks[i]);
            _tracks[i].pitchShift = _pitchShift + _detune;
            _tracks[i].velocity = _vel;
        }
    }
    
    private function _noteOn(e:SiONTrackEvent) : void {
        _onNoteOn(e.eventTriggerID);
    }
        
    
    static private var _chordList:* = {
        "maj":[
            [-1,0,2,2,2,0],[-1,1,3,3,3,1],[-1,2,4,4,4,2],
            [-1,3,2,0,1,0],[-1,4,3,1,2,1],[-1,0,0,2,3,2],
            [-1,6,5,3,4,3],[ 0,2,2,1,0,0],[ 1,3,3,2,1,1],
            [ 2,4,4,3,2,2],[ 3,2,0,0,0,3],[-1,3,1,1,1,4],
        ],
        "m":[
            [-1,0,2,2,1,0],[-1,1,3,3,2,1],[-1,2,4,4,3,2],
            [-1,3,1,0,1,-1],[-1,4,6,6,5,4],[-1,-1,0,2,3,1],
            [-1,-1,4,3,4,2],[0,2,2,0,0,0],[1,3,3,1,1,1],
            [2,4,4,2,2,2],[3,5,5,3,3,3],[4,6,6,4,4,4]
        ],
        "7":[
            [-1,0,2,0,2,0],[-1,1,3,1,3,1],[-1,2,1,2,0,2],
            [-1,3,2,3,1,0],[-1,-1,3,4,2,4],[-1,0,0,2,1,2],
            [-1,-1,1,3,2,3],[0,2,2,1,3,0],[1,3,1,2,1,1],
            [2,4,2,3,2,2],[3,2,0,0,0,1],[2,-1,1,1,1,2]
        ],
        "M7":[
            [0,0,2,1,2,0],[1,1,3,2,3,1],[2,2,4,3,4,2],
            [0,3,2,0,0,0],[-1,4,3,1,1,1],[-1,0,0,2,2,2],
            [-1,6,5,3,3,3],[0,2,1,1,0,0],[0,3,3,2,1,0],
            [2,4,3,3,2,2],[3,2,0,0,0,2],[-1,3,1,1,1,3]
        ],
        "m7":[
            [-1,0,2,0,1,0],[-1,1,3,1,2,1],[-1,2,4,2,3,2],
            [-1,3,1,3,1,3],[-1,2,2,1,2,-1],[-1,-1,0,2,1,1],
            [-1,-1,1,3,2,2],[0,2,0,0,0,0],[1,3,1,1,1,1],
            [2,4,2,2,2,2],[3,5,3,3,3,3],[4,6,4,4,4,4]
        ]
    };
}
