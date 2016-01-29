// SiON Keyborad WF1 ver0.58
package {
    import flash.display.Sprite;
    import flash.events.*;
    import flash.system.System;
    import com.bit101.components.*;
    
    public class main extends Sprite {
        function main() {
            graphics.beginFill(0);
            graphics.drawRect(0,0,465,465);
            graphics.endFill();
            
            addChild(keyboard = new Sprite());
            keyboard.x = 0;
            keyboard.y = 120;
            
            keys = new KeyDisplay(keyboard, 32, 54);
            Style.BACKGROUND = 0x606060;
            Style.BUTTON_FACE = 0x404040;
            Style.LABEL_TEXT = 0xaaaaaa;
            Style.DROPSHADOW = 0;
            Style.PANEL = 0x202020;
            Style.PROGRESS_BAR = 0x404040;
            selector = new VoiceSelector(keyboard, 32, -16);
            volume = new VolumePanel(keyboard, 32, 78);
            stage.addEventListener("keyDown", _onKeyDown);
            stage.addEventListener("keyUp", _onKeyUp);

            var disc:String = "[ UP / DOWN ] = Change Voice      ";
            disc += "[ LEFT / RIGHT ] = Change Categoly      ";
            disc += "[ Q / W ] = Octave Shift";
            new Label(keyboard, 16, 204, disc);
            
            disc = "[ P ] = Send parameters to clipboard";
            clipboard = new Text(keyboard, 16, 230, disc);
            clipboard.setSize(433, 96);
            
            initializeSiON();
        }
        
        private function _onKeyDown(e:KeyboardEvent) : void {
            var i:int, c:String, mml:String;
            switch (e.keyCode) {
            case 40: updateVoice(voiceIndex-1); break;
            case 38: updateVoice(voiceIndex+1); break;
            case 37: updateCategoly(categolyIndex-1); break;
            case 39: updateCategoly(categolyIndex+1); break;
            default:
                switch (c = String.fromCharCode(e.charCode)) {
                case 'q': keys.octDown(); break;
                case 'w': keys.octUp();   break;
                case 'p': 
                    mml = voiceList[voiceIndex].getMML(voiceIndex);
                    clipboard.text = "[ P ] = Send parameters to clipboard \n" + mml.replace(/\r/g, '');
                    System.setClipboard(mml);
                    break;
                default:  if ((i="zsxdcvgbhnjm,l.;/".indexOf(c)) >= 0) keyOn(i); break;
                }
            }
        }
        
        private function _onKeyUp(e:KeyboardEvent) : void {
            var i:int, c:String = String.fromCharCode(e.charCode);
            if ((i="zsxdcvgbhnjm,l.;/".indexOf(c)) >= 0) keyOff(i);
        }
    }
}



import flash.display.*;
import flash.events.*;
import flash.filters.*;
import flash.text.*;
import flash.geom.*;
import com.bit101.components.*;
import org.si.sion.*;
import org.si.sion.effector.*;
import org.si.sion.sequencer.SiMMLTrack;
import org.si.sion.utils.SiONPresetVoice;

// SiON variables
var driver:SiONDriver = new SiONDriver();
var presetVoice:SiONPresetVoice = new SiONPresetVoice();
var voiceList:Array = presetVoice.categolies[0];
var voiceIndex:int = 0;
var categolyIndex:int = 0;
var delaySendLevel:Number = 0.2;
var chorusSendLevel:Number = 0;
var lpf:SiCtrlFilterLowPass = new SiCtrlFilterLowPass();
var cutoff:Number = 1;
var resonance:Number = 0;

// UIs
var keyboard:Sprite;
var keys:KeyDisplay;
var selector:VoiceSelector;
var volume:VolumePanel;
var keyFlag:int;
var clipboard:Text;

// Global Functions
function initializeSiON() : void {
    // effector setting
    lpf.control(1, 0);
    driver.effector.slot0 = [lpf];
    driver.effector.slot1 = [new SiEffectStereoDelay(200,0.2,false)];
    driver.effector.slot2 = [new SiEffectStereoChorus(20,0.2,4,20)];
    
    // start stream without initializing effectors
    driver.play(null, false);
}

function updateCategoly(index:int) : void {
    var imax:int = presetVoice.categolies.length;
    if (index < 0) index = imax - 1;
    else if (index >= imax) index = 0;
    categolyIndex = index;
    voiceList = presetVoice.categolies[index];
    selector.onUpdateCategoly();
    volume.onUpdateCategoly();
    updateVoice(voiceIndex);
}

function updateVoice(index:int, callFromKnob:Boolean=false) : void {
    if (voiceList) {
        if (index < 0) index = 0;
        else if (index >= voiceList.length) index = voiceList.length - 1;
        voiceIndex = index;
        selector.updateName();
        if (!callFromKnob) volume.updateVoiceIndex();
    }
}

function keyOn(index:int) : void {
    if ((keyFlag & (1<<index)) == 0) {
        keyFlag |= 1<<index;
        var trk:SiMMLTrack = driver.noteOn(index + keys.octave*12, voiceList[voiceIndex], 0);
        trk.channel.setStreamSend(1, delaySendLevel);
        trk.channel.setStreamSend(2, chorusSendLevel);
        keys.keyOn(index);
    }
}

function keyOff(index:int) : void {
    keyFlag &= ~(1<<index);
    driver.noteOff(index + keys.octave*12);
    keys.keyOff(index);
}

function allNoteOff() : void {
    for each (var trk:SiMMLTrack in driver.sequencer.tracks) trk.keyOff();
}

class KeyDisplay extends Sprite {
    private var _screenBitmap:Bitmap;
    private var _screen:BitmapData = new BitmapData(400, 144, false, 0);
    private var _cls:BitmapData = new BitmapData(400, 144, false, 0x202020);
    private var _bkeyBase:BitmapData = new BitmapData(320, 120, true, 0);
    private var _wkeyPos:Array = [100,120,140,160,180,200,220,240,260,280];
    private var _bkeyPos:Array = [112,136,172,194,216,252,276];
    private var _wkeyIndex:Array = [0,2,4,5,7,9,11,12,14,16];
    private var _bkeyIndex:Array = [1,3,6,8,10,13,15];
    private var _wkeyPushed:BitmapData = new BitmapData(20, 120, true, 0x808080ff);
    private var _bkeyPushed:BitmapData = new BitmapData(12, 80, true, 0x408080ff);
    private var _light:BitmapData = new BitmapData(12, 12, true, 0);
    private var _keyFlag:int = 0, _newKeyFlag:int = 0x3000000, _padUpdated:Boolean = false;
    
    public function get octave() : int { return (_keyFlag>>24)+2; }
    
    function KeyDisplay(parent:DisplayObjectContainer, x:Number, y:Number) {
        this.x = x;
        this.y = y;
        parent.addChild(this);
        _createBitmap();
        addEventListener("enterFrame", _onEnterFrame);
        addChild(_screenBitmap = new Bitmap(_screen));
        stage.addEventListener("mouseDown", _onMouseDown);
        stage.addEventListener("mouseUp",   _onMouseUp);
        stage.addEventListener("mouseMove", _onMouseMove);
    }
    
    public function keyOn(index:int)  : void { _newKeyFlag = _newKeyFlag | (1<<index); }
    public function keyOff(index:int) : void { _newKeyFlag = _newKeyFlag &~(1<<index); }
    public function octUp() : void { 
        var oct:int = _newKeyFlag >> 24;
        if (++oct > 6) oct=6;
        _newKeyFlag = (oct<<24) | (_newKeyFlag & 0xffffff);
        allNoteOff();
    }
    public function octDown() : void { 
        var oct:int = _newKeyFlag >> 24;
        if (--oct < 0) oct=0;
        _newKeyFlag = (oct<<24) | (_newKeyFlag & 0xffffff);
        allNoteOff();
    }
    
    private function _createBitmap() : void {
        var canvas:Shape = new Shape(), g:Graphics = canvas.graphics, chars:String,
            i:int, mat:Matrix = new Matrix(), rc:Rectangle = new Rectangle(0,8,8,4), label:Label;
        parent.addChild(canvas);
        // white keys
        g.clear();
        g.lineStyle(2, 0);
        mat.createGradientBox(8, 8, Math.PI/2);
        g.beginGradientFill("linear", [0x404040,0xf0f0f0], [1,1], [0,255], mat);
        g.drawRoundRect(0,-4,20,124,8);
        g.endFill();
        g.lineStyle(4, 0x808080, 0.25);
        g.drawPath(Vector.<int>([1,2]), Vector.<Number>([0,-4, 0,120]));
        Style.LABEL_TEXT = 0x666666;
        label = new Label(null,0,0,"");
        chars = "Q  ZXCVBNM,./  W";
        for (i=0; i<16; i++) {
            mat.identity();
            mat.translate(i*20+40, 20);
            _cls.draw(canvas, mat);
            label.text = chars.charAt(i);
            label.draw();
            mat.translate(4, 96);
            _cls.draw(label, mat);
        }
        // board
        g.clear();
        mat.createGradientBox(20, 20, Math.PI/2);
        g.beginGradientFill("linear", [0,0x404040,0x202020], [1,1,1], [0,192,255], mat);
        g.drawRect(0,0,400,20);
        g.endFill();
        _cls.draw(canvas);
        // octave
        label.text = "oct.";
        label.draw();
        mat.identity();
        mat.translate(4, 0);
        _cls.draw(label, mat);
        for (rc.x=30; rc.x<136; rc.x+=16) _cls.fillRect(rc, 0);
        g.clear();
        mat.createGradientBox(8, 8, 0);
        g.beginGradientFill("radial", [0xff8040,0x800000], [1,0], [0,255], mat);
        g.drawCircle(6, 6, 8);
        g.endFill();
        _light.draw(canvas);
        // logo
        label.text = "SiON FM Synthesizer WF-1";
        label.draw();
        mat.identity();
        mat.translate(280, -2);
        _cls.draw(label, mat);
        // black keys
        g.clear();
        g.beginFill(0x808080, 0.25);
        g.drawPath(Vector.<int>([1,2,2,2]), Vector.<Number>([12,0, 16,0, 18,75, 12,82]));
        g.endFill();
        g.lineStyle(2, 0);
        g.beginFill(0x303030);
        g.drawRoundRect(0,0,12,80,3);
        g.endFill();
        g.lineStyle(3, 0x606060, 0.5);
        g.drawPath(Vector.<int>([1,2,2]), Vector.<Number>([2,0, 2,73, 8,73]));
        g.lineStyle(1, 0xc0c0c0, 0.5);
        g.drawPath(Vector.<int>([1,2,2]), Vector.<Number>([2,0, 2,71, 7,71]));
        Style.LABEL_TEXT = 0xaaaaaa;
        label = new Label(null,0,0,"");
        var pos:Array = [-8,14,36,72,96,132,154,176,212,236,272,294,316];
        chars = "   SDGHJL;   ";
        for (i=0; i<pos.length; i++) {
            mat.identity();
            mat.translate(pos[i], 0);
            _bkeyBase.draw(canvas, mat);
            label.text = chars.charAt(i);
            label.draw();
            mat.translate(1, 50);
            _bkeyBase.draw(label, mat);
        }
        // Filter pad
        label.text = "Filter";
        label.draw();
        mat.identity();
        mat.translate(6, 84);
        _cls.draw(label, mat);
        _cls.fillRect(new Rectangle(8,104,24,24), 0);
        
        parent.removeChild(canvas);
    }
    
    private function _onEnterFrame(e:Event) : void {
        if (_keyFlag != _newKeyFlag || _padUpdated) {
            _keyFlag = _newKeyFlag;
            _padUpdated = false;
            _screen.copyPixels(_cls, _cls.rect, _cls.rect.topLeft);
            var i:int, mat:Matrix = new Matrix(1,0,0,1,0,20), pt:Point = new Point(40, 20);
            for  (i=0; i<_wkeyIndex.length; i++) {
                if (_keyFlag & (1<<_wkeyIndex[i])) {
                    mat.tx = _wkeyPos[i];
                    _screen.draw(_wkeyPushed, mat);
                }
            }
            _screen.copyPixels(_bkeyBase, _bkeyBase.rect, pt);
            for  (i=0; i<_bkeyIndex.length; i++) {
                if (_keyFlag & (1<<_bkeyIndex[i])) {
                    mat.tx = _bkeyPos[i];
                    _screen.draw(_bkeyPushed, mat);
                }
            }
            pt.x = octave*16-2;
            pt.y = 6;
            _screen.copyPixels(_light, _light.rect, pt);
            pt.x = int(resonance*23) + 4;
            pt.y = 123 - int(cutoff*23);
            _screen.copyPixels(_light, _light.rect, pt);
        }
    }
    
    private var _draggingStart:Point;
    private function _onMouseDown(e:MouseEvent) : void { 
        if (mouseX>4 && mouseX<36 && mouseY>104 && mouseY<136) {
            _draggingStart = new Point(mouseX-resonance*50, mouseY+cutoff*50);
        }
    }
    private function _onMouseUp(e:MouseEvent) : void { _draggingStart = null; }
    private function _onMouseMove(e:MouseEvent) : void {
        if (_draggingStart) {
            resonance = (mouseX - _draggingStart.x) * 0.02;
            if (resonance < 0) resonance = 0;
            else if (resonance > 0.9) resonance = 0.9;
            cutoff = (_draggingStart.y - mouseY) * 0.02;
            if (cutoff < 0) cutoff = 0;
            else if (cutoff > 1) cutoff = 1;
            _padUpdated = true;
            lpf.control(cutoff, resonance);
        }
    }
}

class VoiceSelector extends Sprite {
    private var _cursor:Bitmap = new Bitmap(new BitmapData(48, 14, true, 0x408080ff));
    private var _categolies:Sprite = new Sprite();
    private var _voiceName:Label;
    
    function VoiceSelector(parent:DisplayObjectContainer, x:Number, y:Number) {
        this.x = x;
        this.y = y;
        parent.addChild(this);
        _categolies.x = 1;
        _categolies.y = 18;
        addChild(_categolies);
        var imax:int = presetVoice.categolies.length, button:PushButton;
        for (var i:int=0; i<imax; i++) {
            var list:Array = presetVoice.categolies[i],
                label:String = (list.name.charAt() == "v") ? list.name.substr(9) : list.name;
            button = new PushButton(_categolies, (i&7)*50, (i>>3)*16, label, _onCategolyPushed);
            button.setSize(48, 14);
        }
    
        (new PushButton(this,  1, 2, "-", function(e:Event) : void { updateVoice(voiceIndex-1); })).setSize(14, 14);
        (new PushButton(this, 17, 2, "+", function(e:Event) : void { updateVoice(voiceIndex+1); })).setSize(14, 14);
        _categolies.addChild(_cursor);
        _voiceName = new Label(this, 33, 0, "SiON preset voices are from VAL-SOUND");
        _voiceName.setSize(200, 18);
    }
    
    private function _onCategolyPushed(e:Event) : void {
        _cursor.x = e.target.x;
        _cursor.y = e.target.y;
        updateCategoly(int((_cursor.x+10)*0.02) + (int(_cursor.y>8)<<3));
    }

    public function updateName() : void {
        var str:String = ("00"+String(voiceIndex+1)).substr(-3,3) + "; ";
        str += voiceList[voiceIndex].name;
        _voiceName.text = str;
    }
    
    public function onUpdateCategoly() : void {
        _cursor.x = (categolyIndex&7)*50;
        _cursor.y = (categolyIndex>>3)*16;
    }
}

class VolumePanel extends Sprite {
    private var _rev:Knob, _cho:Knob, _prg:Knob;
    function VolumePanel(parent:DisplayObjectContainer, x:Number, y:Number) {
        this.x = x;
        this.y = y;
        parent.addChild(this);
        _prg = _newKnob(this, 12,   0, "Voice",  _onChangeVoice);
        _rev = _newKnob(this, 372,  0, "Delay",  _onChangeEffect);
        _cho = _newKnob(this, 372, 60, "Chorus", _onChangeEffect);
        _prg.showValue = false;
        _rev.value = 20;
        
        function _newKnob(cont:DisplayObjectContainer, x:Number, y:Number, label:String, cb:Function) : Knob {
            var ret:Knob = new Knob(cont, x, y, label, cb);
            ret.radius = 8;
            return ret;
        }
    }
    
    public function onUpdateCategoly() : void {
        _prg.minimum = 0;
        _prg.maximum = voiceList.length;
        _prg.value = voiceIndex;
        _prg.mouseRange = (voiceList.length<20) ? 100 : 200;
    }
    
    public function updateVoiceIndex() : void {
        _prg.value = voiceIndex;
    }
    
    private function _onChangeVoice(e:Event) : void {
        updateVoice(int(_prg.value), true);
    }
    
    private function _onChangeEffect(e:Event) : void {
        delaySendLevel  = _rev.value * 0.01;
        chorusSendLevel = _cho.value * 0.01;
    }
}
