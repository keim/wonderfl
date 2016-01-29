package {
    import flash.text.*;
    import flash.events.*;
    import flash.display.Sprite;
    import flash.utils.ByteArray;
    
    import org.si.sion.SiONDriver;
    import org.si.sion.midi.*;
    import org.si.sion.events.*;
    import org.si.utils.ByteArrayExt;
    
    import com.bit101.components.*;
    
    
    public class main extends Sprite {
        public var driver:SiONDriver = new SiONDriver(4096);
        public var smfData:SMFData = new SMFData();
        
        private var _title:TextField;
        private var _midiMode:Label;
        private var _tempo:Label;
        
        /*--------------------------------------------------
         * How to play MIDI file on SiON version 0.65
         * 1) create SMFData object 
         * 2) call load() or loadBytes() method
         * 3) call SiONDriver.play() with SMFData object
         *--------------------------------------------------*/
        private function _playMIDIFile(midiFile:ByteArray) : void
        {
            smfData.loadBytes(midiFile);
            driver.play(smfData);
        }
        
        
        
        function main() {
            var i:int;
            
            // black minimal comps
            Style.BACKGROUND = 0x404040;
            Style.BUTTON_FACE = 0x606060;
            Style.LABEL_TEXT = 0xaaaaaa;
            Style.INPUT_TEXT = 0xaaaaaa;
            Style.DROPSHADOW = 0;
            Style.PANEL = 0x303030;
            Style.PROGRESS_BAR = 0x404040;
            
            container = this;
            new PushButton(this, 0, 0, "Load SMF ...", function(e:Event):void {
                if (driver.isPlaying) driver.fadeOut(4);
                new ByteArrayExt().browse(function(ba:ByteArrayExt) : void {
                    _playMIDIFile(ba);
                    _title.text = smfData.title;
                    _tempo.text = "T:" + smfData.bpm.toFixed(1);
                    reset();
                }, null, null, "Standard MIDI File", "*.mid;*.smf");
            });
            
            // event handler
            driver.addEventListener(SiONEvent.FADE_OUT_COMPLETE, _onFadeOut);
            driver.addEventListener(SiONTrackEvent.CHANGE_BPM,   _onBPMChanged);
            driver.addEventListener(SiONTrackEvent.BEAT,         _onBeat);
            driver.addEventListener(SiONMIDIEvent.NOTE_ON,  _onNoteOn);
            driver.addEventListener(SiONMIDIEvent.NOTE_OFF, _onNoteOff);
            driver.addEventListener(SiONMIDIEvent.CONTROL_CHANGE, _onControlChange);
            driver.addEventListener(SiONMIDIEvent.PROGRAM_CHANGE, _onProgramChange);
            driver.addEventListener(SiONMIDIEvent.PITCH_BEND, _onPitchBend);
            // callbacks
            driver.midiModule.onSysEx = _onSystemExclusive;
            driver.midiModule.onFinishSequence = _onFinishSequence;
            
            // setup screen
            setup();
            _title = new TextField();
            _title.defaultTextFormat = new TextFormat("_sans", 12, 0xffffff);
            _title.x = 120;
            _title.y = 0;
            _title.width = 300;
            _title.text = "SCC MIDI Player !! powered by SiON v0.65";
            addChild(_title);
            
            _midiMode = new Label(this, 420, 5);
            _tempo    = new Label(this, 420, -4);
        }
        
        
    // handlers ----------------------------------------------------------------------
        private function _onFadeOut(e:SiONEvent) : void
        {
            driver.stop();
        }
        
        private function _onBPMChanged(e:SiONTrackEvent) : void
        {
            _tempo.text = "T:" + driver.bpm.toFixed(1);
        }
        
        private function _onBeat(e:SiONTrackEvent) : void
        {
            tempoIndicatorAlpha = 1;
        }
        
        private function _onNoteOn(e:SiONMIDIEvent) : void 
        {
            noteOn[e.midiChannelNumber][e.note] = 1;
            release[e.midiChannelNumber][e.note] = 1;
        }
        
        private function _onNoteOff(e:SiONMIDIEvent) : void 
        {
            release[e.midiChannelNumber][e.note] = 0.84;
        }
        
        private function _onControlChange(e:SiONMIDIEvent) : void
        {
            switch(e.controllerNumber) {
            case SMFEvent.CC_MODULATION:    updateModulation(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_EXPRESSION:    updateExpression(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_SUSTAIN_PEDAL: updateSustain(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_PANPOD:        updatePanpod(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_VOLUME:        updateVolume(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_REVERB_SEND:   updateReverb(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_CHORUS_SEND:   updateChorus(e.midiChannelNumber, e.value); break;
            case SMFEvent.CC_DELAY_SEND:    updateDelay(e.midiChannelNumber, e.value);  break;
            }
        }
        
        private function _onProgramChange(e:SiONMIDIEvent) : void 
        {
            updateVoiceInformation(e.midiModule, e.midiChannelNumber, e.value, e.midiChannel.drumMode);
        }

        private function _onPitchBend(e:SiONMIDIEvent) : void
        {
            updatePitchBend(e.midiChannelNumber, e.value);
        }
        
        private function _onSystemExclusive(channelNumber:int, bytes:ByteArray) : void 
        {
            if (driver.midiModule.systemExclusiveMode != "") _midiMode.text = driver.midiModule.systemExclusiveMode;
        }
        
        private function _onFinishSequence() : void
        {
            driver.fadeOut(4);
        }
    }
}


import flash.display.*;
import flash.geom.*;
import flash.events.*;
import org.si.sion.midi.*;
import com.bit101.components.*;

var noteOn:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(16);
var release:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(16);
var noteOnRect:Vector.<Vector.<Rectangle>> = new Vector.<Vector.<Rectangle>>(16);
var noteOnColor:Vector.<uint> = new Vector.<uint>(85);
var keyImage:BitmapData = new BitmapData(465, 445, false, 0);
var keyOnImage:BitmapData = new BitmapData(465, 445, true, 0);
var tempoIndicator:Shape = new Shape();
var keyShape:Shape = new Shape();
var lbl:Label = new Label();
var mat:Matrix = new Matrix();
var rc:Rectangle = new Rectangle();
var container:Sprite;
var tempoIndicatorAlpha:Number = 0;

function setup() : void {
    var tr:int, i:int, x:Number;
    var bw:Array = [0,1,0,1,0,0,1,0,1,0,1,0];
    var g:Graphics;
    
    for (i=0; i<16; i++) {
        noteOn[i] = new Vector.<Number>(128);
        release[i] = new Vector.<Number>(128); 
        noteOnRect[i] = new Vector.<Rectangle>(85);
    }

    g = tempoIndicator.graphics
    g.beginFill(0xf06060);
    g.drawCircle(0, 0, 4);
    g.endFill();
    g = keyShape.graphics;
    g.lineStyle(1, 0x808080);
    g.drawPath(Vector.<int>([1,2,2]), Vector.<Number>([0,0, 0,24, 5,24]));
    g.lineStyle(1, 0xc0c0c0);
    g.drawPath(Vector.<int>([1,2,2]), Vector.<Number>([5,24, 5,-1, 0,-1]));
    for (tr=0; tr<16; tr++) {
        rc.setTo(0,tr*28,300,25);
        keyImage.fillRect(rc, 0xf0f0f0);
        rc.setTo(375,tr*28,90,25);
        keyImage.fillRect(rc, 0x202038);
        for (i=0; i<9; i++) {
            rc.setTo(302+i*8,tr*28,6,25);
            keyImage.fillRect(rc, 0x303030);
        }
        for (mat.setTo(1,0,0,1,0,tr*28); mat.tx<300; mat.tx+=6) {
            keyImage.draw(keyShape, mat);
        }
        _drawText(keyImage, 375, tr*28-4, "[TRACK" + String(tr+1) + "]");
    }
    g.clear();
    g.beginFill(0x202020);
    g.lineStyle(1, 0x404040);
    g.drawPath(Vector.<int>([1,2,2,2]), Vector.<Number>([0,0, 0,14, 4,14, 4,0]));
    g.endFill();
    g.lineStyle(1, 0x808080);
    g.drawPath(Vector.<int>([1,2,2]), Vector.<Number>([1,0, 1,12, 2,12]));
    for (i=0,x=0; i<85; i++) {
        var bwf:int = bw[i%12];
        noteOnColor[i] = (bwf) ? 0xffccaa : 0xff2222;
        for (tr=0; tr<16; tr++) {
            noteOnRect[tr][i] = new Rectangle(x+bwf+1, tr*28, 4-bwf, 24-bwf*10);
            if (bwf) {
                mat.ty = tr*28;
                mat.tx = x+1;
                keyImage.draw(keyShape, mat);
            }
        }
        x += (bwf == bw[(i+1)%12])?6:3;
    }
    with(container.addChild(new Bitmap(keyImage))) { x = 0; y = 20; }
    with(container.addChild(new Bitmap(keyOnImage))) { x = 0; y = 20; }
    tempoIndicator.x = 110;
    tempoIndicator.y = 10;
    container.addChild(tempoIndicator);
    container.addEventListener(Event.ENTER_FRAME, draw);
    container.graphics.beginFill(0x303050);
    container.graphics.drawRect(0,0,465,20);
    container.graphics.endFill();
}


function reset() : void {
    var tr:int, nt:int;
    keyOnImage.fillRect(keyOnImage.rect, 0);
    for (tr=0; tr<16; tr++) {
        for (nt=0; nt<128; nt++) {
            noteOn[tr][nt] = 0;
            release[tr][nt] = 0;
        }
        updatePitchBend(tr, 0);
        updateModulation(tr, 0);
        updateExpression(tr, 128);
        updateSustain(tr, 0);
        updatePanpod(tr, 64);
        updateVolume(tr, 128);
        updateReverb(tr, 0);
        updateChorus(tr, 0);
        updateDelay(tr, 0);
    }
}


function _drawText(img:BitmapData, x:Number, y:Number, str:String, scale:Number=1) : void {
    mat.setTo(scale,0,0,scale,x,y);
    lbl.text = str;
    lbl.draw();
    img.draw(lbl, mat);
}


function updateVoiceInformation(midiModule:MIDIModule, tr:int, pn:int, drumMode:int) : void {
    rc.setTo(375, tr*28+13, 90, 13);
    keyOnImage.fillRect(rc, 0);
    if (drumMode) {
        _drawText(keyOnImage, 375, tr*28+8, String(pn) + ":[DRUM MODE]");
    } else {
        _drawText(keyOnImage, 375, tr*28+8, String(pn) + ":" + midiModule.voiceSet[pn].name);
    }
}


function updatePitchBend(tr:int, bend:int) : void { _updateBar(tr, 0, (bend>0) ? (-bend*12/8192) : 0, (bend<0) ? (-bend*12/8192) : 1, 13); }
function updateModulation(tr:int, mod:int) : void { _updateBar(tr, 1, -mod*25/128); }
function updateExpression(tr:int, exp:int) : void { _updateBar(tr, 2, -exp*25/128); }
function updateSustain(tr:int, sus:int) : void    { _updateBar(tr, 3, -sus*25/128); }
function updatePanpod(tr:int, pan:int) : void     { _updateBar(tr, 4, (pan>64) ? (-(pan-64)*12/64) : 0, (pan<64) ? (-(pan-64)*12/64) : 1, 13); }
function updateVolume(tr:int, vol:int) : void     { _updateBar(tr, 5, -vol*25/128); }
function updateReverb(tr:int, rev:int) : void     { _updateBar(tr, 6, -rev*25/128); }
function updateChorus(tr:int, cho:int) : void     { _updateBar(tr, 7, -cho*25/128); }
function updateDelay(tr:int, dly:int) : void      { _updateBar(tr, 8, -dly*25/128); }


function _updateBar(tr:int, index:int, y0:int, y1:int=0, c:int=25) : void {
    rc.setTo(302+index*8, tr*28, 6, 25);
    keyOnImage.fillRect(rc, 0);
    rc.setTo(302+index*8, tr*28+c+y0, 6, y1-y0);
    keyOnImage.fillRect(rc, 0xff8080a0);
}

function draw(e:Event) : void {
    rc.setTo(0, 0, 300, 450);
    keyOnImage.fillRect(rc, 0);
    for (var tr:int=0; tr<16; tr++) {
        var n:Vector.<Number> = noteOn[tr],
            r:Vector.<Number> = release[tr],
            nr:Vector.<Rectangle> = noteOnRect[tr];
        for (var i:int=0, j:int=24; i<85; i++, j++) {
            if (n[j] > 0) {
                n[j] *= r[j];
                if (n[j] < 0.01) n[j] = 0;
                keyOnImage.fillRect(nr[i], ((n[j]*255)<<24)|noteOnColor[i]);
            }
        }
    }
    tempoIndicator.alpha = tempoIndicatorAlpha;
    tempoIndicatorAlpha *= 0.9;
}

