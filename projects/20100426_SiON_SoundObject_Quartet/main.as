// SiON ver0.6x's new concept "SoundObject"
package {
    import flash.display.*;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.utils.*;
    import org.si.sion.events.*;
    import org.si.sion.effector.*;
    import org.si.sound.*;
    import org.si.sound.patterns.*;
    import org.si.sound.synthesizers.*;
    import com.bit101.components.*;
    
    
    public class main extends Sprite {
        
        // SiON SoundObjects (in org.si.sound.*)
        //----------------------------------------
        // SoundObjects are SiON-based software instruments which brings an operational feeling of DisplayObject.
        // SoundObject は，DisplayObject のような感覚で操作を行える SiON を音源として使用したソフトウェア楽器です．
        public var Ar:Arpeggiator;
        public var Bs:BassSequencer;
        public var Cp:ChordPad;
        public var Dm:DrumMachine;
        
        
        // Synthesizers (in org.si.sound.synthesizers.*)
        //----------------------------------------
        // Synthesizers are wrapper classes of SiONVoice.
        // Synthesizer は SiONVoice のラッパークラスです．
        // This provides more direct, easier controls of SiON's voice.
        // より直感的で簡単な SiONVoice の操作を提供します．
        public var waveTableSynth:WaveTableSynth;
        public var analogSynth:AnalogSynth;
        public var padVoiceLoader:PresetVoiceLoader;
        
        
        // Effectors (in org.si.sion.effector.*)
        //----------------------------------------
        // Effectors are from SiON's effector package. 
        // Effector は SiON の effector package を使用します．
        // SoundObject.effectors property or SiDriver.effector.slot* property has a similar operation of "DisplayObject.filters".
        // SoundObject.effectors プロパティ や SiDriver.effector.slot* は DisplayObject.filters と似たような操作を行えます．
        public var equaliser:SiEffectEqualiser;
        public var delay:SiEffectStereoDelay;
        public var chorus:SiEffectStereoChorus;
        public var autopan:SiEffectAutoPan;

        
        // SiONDriver
        //----------------------------------------
        // Even using SoundObject, you have to create new SiONDriver and call play() method.
        // SoundObject を使用する場合でも，SiONDriver を生成して play() メソッドを呼び出す必要があります．
        public var driver:SiONDriver;
        
        
        // constructor
        function main() {
            _generalSettings();
            
            
            // create new SiON objects
            //----------------------------------------
            // In current version(0.60), you have to create new effectors after SiONDriver creation.
            // 現バージョン(0.60)では，SiONDriver を生成後にエフェクタを生成する必要があります．
            driver = new SiONDriver();
            equaliser = new SiEffectEqualiser();
            delay  = new SiEffectStereoDelay(300, 0.25, true, 1);
            chorus = new SiEffectStereoChorus(20, 0.2, 4, 20, 1);
            autopan = new SiEffectAutoPan();
            
            
            // SiONDriver
            //----------------------------------------
            // Set up general parameters (BPM, effect and so on) by SiONDriver's property.
            // BPM やグローバルエフェクトなど全体に関する操作は SiONDriver のプロパティで行います．
            driver.autoStop = true;              // set auto stop after fade out
            driver.bpm = 132;                    // BPM = 132
            driver.effector.slot0 = [equaliser]; // The equaliser is applied to slot0 (master effector)
            driver.effector.slot1 = [delay];     // The delay effector is applied to slot1 (global effector)
            driver.effector.slot2 = [chorus];    // The chorus effector is applied to slot2 (global effector)
            driver.addEventListener(SiONTrackEvent.BEAT, _onBeat);           // handler for each beat
            driver.addEventListener(SiONEvent.STREAM_START, _onStartStream); // handler when streaming starts
            driver.addEventListener(SiONEvent.STREAM_STOP,  _onStopStream);  // handler when streaming stopped
            new GlobalPanel(this);
            
            
            // Arpeggiator
            //----------------------------------------
            // The Arpeggiator is a monophonic sequencer plays arpeggio pattern specifyed by int Array.
            // Arpeggiator は，int 型 Array で指定したアルペジオパターンを演奏する単音シーケンサです．
            Ar = new Arpeggiator();
            Ar.scaleName = "o6Emp";             // scaled in E minor pentatonic on octave 6
            Ar.pattern = [0,1,2,3,4,2,3,1];     // basic pattern is "egab<d>abg" in MML
            Ar.noteLength = 1;                  // note langth = 16th 
            Ar.gateTime = 0.2;                  // gate time = 0.2
            Ar.effectors = [autopan];           // apply auto-panning effector to Arpeggiator (local effector)
            // These effect send level calculations porvides MIDI's effect send feelings (but not perfectly same).
            // 下記のエフェクトセンドレベル計算を行う事で，ある程度 MIDI 音源のエフェクトセンドのように振舞う事ができます．
            Ar.volume = 0.3;                    // dry volume = 0.3
            Ar.effectSend1 = Ar.volume * 0.4;   // effect send for slot1 = 0.3 * 0.4 = 0.12
            Ar.effectSend2 = Ar.volume * 0.5;   // effect send for slot2 = 0.3 * 0.4 = 0.15
            // In this sample, the wave table synthesizer is applied to Arpeggiator. 
            // このサンプルでは，波形メモリシンセを Arpeggiator に適用しました．
            // The wave table synthesizer provides simple additive synthesis by SiON's "wavecolor". Or you can edit wave shape directly.
            // 波形メモリシンセは SiON の "wavecolor" を指定するシンプルな加算合成方式シンセサイザです. 波形を直接編集することも出来ます．
            waveTableSynth = new WaveTableSynth();
            waveTableSynth.color = 0x1203acff;  // wavecolor value
            waveTableSynth.releaseTime = 0.2;   // release time
            Ar.synthesizer = waveTableSynth;    // apply synthesizer
            new ArPanel(this, Ar);
            
            
            // BassSequencer
            //----------------------------------------
            // The BassSequencer is a monophonic sequencer select bass line pattern by number. You can also apply orignal pattern.
            // BassSequencer は，ベースラインパターンを番号で指定する単音シーケンサです．独自パターンを指定することも出来ます．
            Bs = new BassSequencer("");             // in current version(0.60) you have to pass something in 1st argument... sorry
            Bs.chordName = "o3Em9";                 // E minor 9th chord on octave 3
            Bs.patternNumber = 6;                   // bass line pattern number 6
            Bs.changePatternOnNextSegment = false;  // change pattern immediately after changing patternNumber property
            Bs.volume = 0.4;                        // dry volume = 0.3
            // In this sample, the analog-like synthesizer is applied to BassSequencer. 
            // このサンプルでは，アナログライクシンセを BassSequencer に適用しました．
            // The analog-like synth provide controls by "analog synthesizer like" parameters.
            // アナログライクシンセはアナログシンセのようなパラメータで波形をコントロールする事ができます.
            analogSynth = new AnalogSynth();
            analogSynth.ws1 = AnalogSynth.SAW;      // wave shape of vco1 = saw wave
            analogSynth.ws2 = AnalogSynth.SAW;      // wave shape of vco2 = saw wave
            analogSynth.vco2pitch = 0.1;            // pitch difference of vco2 = 0.1 (10cent)
            analogSynth.setVCAEnvelop(0.2, 0.5, 0.75, 0.2);     // set ADSR amplitude envelop
            analogSynth.setVCFEnvelop(0.4, 0.3, 0.1, 0.6, 0.7); // set filter envelop (cutoff, resonance, attack, decay, peak cutoff)
            Bs.synthesizer = analogSynth;           // apply synthesizer
            new BsPanel(this, Bs);


            // ChordPad
            //----------------------------------------
            // The ChordPad is a polyphonic sequencer plays a rhythm pattern which lengthes are specifyed by int Array. 
            // ChordPad は，int 型 Array で長さを指定したリズムパターンを演奏する多声シーケンサです．
            // The number of voices (1~6) should be specifyed in constructor. The default number of voices is 3.
            // 同時発音数(1～6) はコンストラクタで渡す必要があります．指定しない場合のデフォルト値は 3 です．
            Cp = new ChordPad(null, 4);
            Cp.chordName = "Em9";                           // E minor 9th chord on octave 5 (default)
            Cp.voiceMode = ChordPad.HIGH;                   // high position voicing mode
            Cp.pattern = [4,0,0,0,0,0,1,0,2,0,0,1,0,0,1,0]; // pattern of lengthes. 0 means no sound
            Cp.gateTime = 0.8;                              // gate time = 0.8
            Cp.volume = 0.2;                                // dry volume = 0.2
            Cp.effectSend1 = Cp.volume * 0.3;               // effect send for slot1 = 0.2 * 0.3 = 0.06
            Cp.effectSend2 = Cp.volume * 0.3;               // effect send for slot2 = 0.2 * 0.3 = 0.06
            // In this sample, preset voice loader is applied to ChordPad. 
            // このサンプルでは，プリセットボイスローダを ChordPad に適用しました．
            // The preset voice loader provides simple voice number access to SiONPresetVoice.
            // プリセットボイスローダは SiONPresetVoice に対するボイス番号によるアクセスを提供します．
            padVoiceLoader = new PresetVoiceLoader("svmidi"); // load voice categoly "svmidi"
            padVoiceLoader.voiceNumber = 7;     // voice number = 7 (clavinet)
            Cp.synthesizer = padVoiceLoader;    // apply synthesizer
            new CpPanel(this, Cp);

            
            // DrumMachine
            //----------------------------------------
            // The DrumMachine is a 3 tracks sequencer plays drum patterns specifyed by independent number for each bass, snare and hihat.
            // DrumMachine は，バス，スネア，ハイハットそれぞれに独立した番号でドラムパターンを指定するを3声シーケンサです．
            Dm = new DrumMachine();
            Dm.bassPatternNumber = 0;   // bass drum pattern number
            Dm.snarePatternNumber = 8;  // snare drum pattern number
            Dm.hihatPatternNumber = 0;  // hihat drum pattern number
            Dm.changePatternOnNextSegment = false;  // change pattern immediately after changing ****PatternNumber property
            Dm.volume = 0.4;
            // In this sample, we use default voices of DrumMachine. You can also apply any voices for each track.
            // このサンプルでは，DrumMachine のデフォルトボイスを使用しています．各トラックに独自のボイスを割り当てることも出来ます．
            // All DrumMachine's default voices are 1 operator voice, so you can play very light-weighted rhythm track.
            // DrumMachine のデフォルトボイスは全て１オペレータで合成するため，非常に軽快にリズムトラックを再生できます．
            Dm.bassVoiceNumber = 0;   // bass drum voice number
            Dm.snareVoiceNumber = 2;  // snare drum voice number
            Dm.hihatVoiceNumber = 0;  // hihat drum voice number
            new DmPanel(this, Dm);
            
            
            // start playing !!
            // 演奏開始！！
            play();
        }
        
        
        public function play() : void {
            // Even using SoundObject, you have to call SiONDriver.play() method to start SiON's sound streaming.
            // SoundObject を使用する場合であっても，SiON で音を合成するのために SiONDriver.play() メソッドを呼び出す必要があります．
            // In this sample, effectors are specifyed before calling play() method, 
            // このサンプルでは，play() メソッド呼び出しの前にエフェクタを設定しているため，
            // so we pass false in the 2nd argument to avoid initializing effector inside.
            // 第二引数で false を渡して内部でエフェクタの初期化を行わないようにしています．
            driver.play(null, false);
            
            
            // The SoundObject starts playing sound by play() method and stop it by stop() method.
            // SoundObject は，play() メソッドで演奏を開始し，stop() メソッドで演奏を停止します．
            Ar.play();
            Bs.play();
            Cp.play();
            Dm.play();
        }
        
        
        // started
        protected function _onStartStream(e:SiONEvent) : void {
            // switch the play button's label
            GlobalPanel.changePlayButtonLabel("stop");
        }
        
        
        // stopped
        protected function _onStopStream(e:SiONEvent) : void {
            // In current version (0.60), you have to stop all SoundObjects explicitly when the SiON's stream stopped.
            // 現バージョン(0.60)では，SiON のストリーミング終了時に，明示的に SoundObject の演奏を止める必要があります．
            // In the future version, it may stop automatically. Sorry for the inconvenience.
            // 将来のバージョンでは，自動的に演奏を止めるようになる予定です．ご面倒おかけしてすいません．
            Ar.stop();
            Bs.stop();
            Cp.stop();
            Dm.stop();
            
            // switch the play button's label
            GlobalPanel.changePlayButtonLabel("play");
        }
        
        
        // So, what shall we do here ?
        protected function _onBeat(e:SiONTrackEvent) : void {
        }
        
        
        // So, what shall we do here ???
        protected function _onKeyDown(e:KeyboardEvent) : void {
            switch (String.fromCharCode(e.charCode)) {
            case 'c': _updateChord("o6Emp", "o3CM7", "o5CM7"); break;
            case 'd': _updateChord("o6Emp", "o3D9",  "o5D9");  break;
            case 'e': _updateChord("o6Emp", "o3Em9", "o5Em9"); break;
            case 'f': _updateChord("o6F+b", "o3F+7", "o5F+7"); break;
            case 'g': _updateChord("o6Emp", "o3GM7", "o5GM7"); break;
            case 'a': _updateChord("o6Emp", "o3Am9", "o5CM7"); break;
            case 'b': _updateChord("o5Bb",  "o2B7",  "o4B7");  break;
            }
        }
        
        
        // Specify chord and scale name for each instrument except for DrumMachine.
        // DrumMachine 以外の各楽器にコード名/スケール名を指定します． 
        public function _updateChord(ArScale:String, BrChord:String, CpChord:String) : void {
            Ar.scaleName = ArScale;
            Bs.chordName = BrChord;
            Cp.chordName = CpChord;
        }
        
        
        // General settings
        private function _generalSettings() : void {
            // color setting
            Style.BACKGROUND = 0x808080;
            Style.BUTTON_FACE = 0x606060;
            Style.LABEL_TEXT = 0xaaaaaa;
            Style.DROPSHADOW = 0;
            Style.PANEL = 0x303030;
            Style.PROGRESS_BAR = 0x404040;
            Style_POINTER = 0x8080ff;
            
            // draw background
            var shape:Shape = new Shape();
            shape.graphics.beginFill(0);
            shape.graphics.drawRect(0,0,465,465);
            shape.graphics.endFill();
            addChild(shape);
            
            // add event handlers
            stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
        }
    }
}




//----------------------------------------
// Hints for advanced usage
//----------------------------------------
// Sorry, there are extremely few comments in the following code.
// すいません．以降，本領発揮でほとんどコメントがありません．
// You may search some hints with the keywords of "Ar.", "Bs.", "Cp." and "Dm.".
// "Ar.", "Bs.", "Cp.", "Dm." の各文字列で以降を検索すると，SoundObject のプロパティの使い方のヒントになるかもしれません．
// And if you are interested in customized Component, please search by "custom".
// また，もしカスタマイズされた Component に興味がある場合，"custom" で検索してみて下さい．

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import org.si.sion.*;
import org.si.sion.utils.*;
import org.si.sion.events.*;
import org.si.sion.effector.*;
import org.si.sound.*;
import org.si.sound.events.*;
import org.si.sound.patterns.*;
import org.si.sound.synthesizers.*;
import com.bit101.components.*;
var Style_POINTER:uint;

class GlobalPanel extends Panel {
    static private var me:GlobalPanel;
    public var start:PushButton, vol:Knob_, tempo:Knob_, low:Knob_, mid:Knob_, high:Knob_, lowVal:Label, midVal:Label, highVal:Label;
    private var _driver:SiONDriver, _eq:SiEffectEqualiser, _updateChord:Function, _play:Function;
    private var _table:Vector.<Number> = new Vector.<Number>(101);
    
    function GlobalPanel(_main:main) {
        super(_main, 2, 25);
        setSize(461, 51);
        for (var i:int=0; i<101; i++) _table[i] = Math.pow(2, i*0.04-2);
        _driver = _main.driver;
        _eq = _driver.effector.getEffectorList(0)[0] as SiEffectEqualiser;
        _updateChord = _main._updateChord;
        _play = _main.play;
        var tl:Label = new Label(content, 4, -4, "SiON SoundObject Quartet");
        tl.scaleX = tl.scaleY = 2;
        
        start = new PushButton(content, 4, 30, "stop", function(e:Event) : void {
            if (start.label == "stop") _driver.fadeOut(3);
            else _play();
        });
        start.setSize(38, 14);
        new PushButton(content,  50, 30, "GM7", function(e:Event):void { _updateChord("o6Emp", "o3GM7", "o5GM7");}).setSize(33, 14);
        new PushButton(content,  85, 30, "Am9", function(e:Event):void { _updateChord("o6Emp", "o3Am9", "o5CM7");}).setSize(33, 14);
        new PushButton(content, 120, 30, "CM7", function(e:Event):void { _updateChord("o6Emp", "o3CM7", "o5CM7");}).setSize(33, 14);
        new PushButton(content, 155, 30, "D9",  function(e:Event):void { _updateChord("o6Emp", "o3D9",  "o5D9"); }).setSize(33, 14);
        new PushButton(content, 190, 30, "Em9", function(e:Event):void { _updateChord("o6Emp", "o3Em9", "o5Em9");}).setSize(33, 14);

        vol = new Knob_(content, 242, -3, "volume", function(e:Event):void { _driver.volume = vol.value; });
        vol.value = _driver.volume;
        
        tempo = new Knob_(content, 278, -3, "BPM", function(e:Event):void { _driver.bpm = tempo.value; });
        tempo.setSize(20, 20);
        tempo.minimum = 70;
        tempo.maximum = 200;
        tempo.value = _driver.bpm;
        
        new Label(content, 350, 35, "3 Band Equaliser");
        low = _eqKnob(370, "low");
        mid = _eqKnob(400, "middle");
        high = _eqKnob(430, "high");
        
        new Label(content, 310, -2, "low");
        new Label(content, 310, 11, "middle");
        new Label(content, 310, 24, "high");
        lowVal = new Label(content, 340, -2, "1.00");
        midVal = new Label(content, 340, 11, "1.00");
        highVal = new Label(content, 340, 24, "1.00");
        
        me = this;
    }

    protected function _eqKnob(x:Number, label:String) : Knob_ {
        var knob:Knob_ = new Knob_(content, x, -3, label, _updateEQ);
        knob.minimum = 0;
        knob.maximum = 100;
        knob.value = 50;
        knob.valueLabel.visible = false;
        return knob;
    }
    
    protected function _updateEQ(e:Event) : void {
        var l:Number = _table[int(low.value)], m:Number = _table[int(mid.value)], h:Number = _table[int(high.value)];
        _eq.setParameters(l, m, h);
        lowVal.text = l.toFixed(2);
        midVal.text = m.toFixed(2);
        highVal.text = h.toFixed(2);
    }
    
    static public function changePlayButtonLabel(label:String) : void {
        me.start.label = label;
    }
}

class SoundObjectPanel extends Panel {
    private var _soundObject:SoundObject, es1:VSlider, es2:VSlider, mute:CheckBox;
    
    function SoundObjectPanel(parent:DisplayObjectContainer, x:Number, y:Number, title:String, soundObject:SoundObject, fadeButton:Boolean = true) {
        super(parent, x, y);
        _soundObject = soundObject;
        setSize(230, 180);
        var tl:Label = new Label(content, 4, -4, title);
        tl.scaleX = tl.scaleY = 2;
        mute = new CheckBox(content, 7, 32, "mute", function(e:Event):void{
            _soundObject.mute = mute.selected;
        });
        var vol:Knob_ = new Knob_(content, 10, 30, "", function(e:Event):void{
            _soundObject.volume = e.target.value;
            _soundObject.effectSend1 = _soundObject.volume * es1.value;
            _soundObject.effectSend2 = _soundObject.volume * es2.value;
        });
        vol.value = _soundObject.volume;
        es1 = new VSlider(content,  8, 90, function(e:Event):void{ _soundObject.effectSend1 = _soundObject.volume * es1.value; });
        es2 = new VSlider(content, 24, 90, function(e:Event):void{ _soundObject.effectSend2 = _soundObject.volume * es2.value; });
        new Label(content,  6, 162, "Del");
        new Label(content, 22, 162, "Cho");
        es1.setSize(12,72);
        es2.setSize(12,72);
        es1.tick = 0.0078125;
        es2.tick = 0.0078125;
        es1.setSliderParams(0,1,_soundObject.effectSend1/_soundObject.volume);
        es2.setSliderParams(0,1,_soundObject.effectSend2/_soundObject.volume);
        if (fadeButton) {
            new PushButton(content, 141, 4, "fadeIn",  function(e:Event):void{ _soundObject.fadeIn(3);  }).setSize(40,14);
            new PushButton(content, 183, 4, "fadeOut", function(e:Event):void{ _soundObject.fadeOut(4); }).setSize(43,14);
        }
    }
}


class ArPanel extends SoundObjectPanel {
    public var Ar:Arpeggiator, waveTableSynth:WaveTableSynth, manual:CheckBox;
    public var pad:ControlPad, si:Label, gt:Label, nl:Label, po:Label, wc:Label;
    public var col8th:VSlider, col5th:VSlider, col4th:VSlider, ws:RotarySelector;
    function ArPanel(parent:DisplayObjectContainer, Ar:Arpeggiator) {
        super(parent, 2, 78, "Arpeggiator", Ar, false);
        this.Ar = Ar;
        this.waveTableSynth = Ar.synthesizer as WaveTableSynth;
        
        new Label(content, 50, 30, "wavecolor :");
        wc = new Label(content, 50, 43, "");
        col4th = new VSlider(content, 52, 95, onColorChanged);
        col5th = new VSlider(content, 67, 95, onColorChanged);
        col8th = new VSlider(content, 82, 95, onColorChanged);
        col4th.setSliderParams(0, 1, 0.2);
        col5th.setSliderParams(0, 1, 0.4);
        col8th.setSliderParams(0, 1, 0.6);
        col4th.setSize(12, 80);
        col5th.setSize(12, 80);
        col8th.setSize(12, 80);
        col4th.tick = 0.0078125;
        col5th.tick = 0.0078125;
        col8th.tick = 0.0078125;
        ws = new RotarySelector(content, 65, 72, "", onColorChanged);
        ws.numChoices = 4;
        ws.choice = 3;
        ws.setSize(16, 16);
        onColorChanged(null);
        
        new Label(content, 110, 120, "scaleIndex property");
        new Label(content, 110, 134, "gateTime property");
        new Label(content, 110, 148, "noteLength property");
        new Label(content, 110, 162, "protament property");
        si = new Label(content, 200, 120, ": "+Ar.scaleIndex.toString());
        gt = new Label(content, 200, 134, ": "+Ar.gateTime.toFixed(2));
        nl = new Label(content, 200, 148, ": "+Ar.noteLength.toFixed(1));
        po = new Label(content, 200, 162, ": "+Ar.portament.toString());
        
        manual = new CheckBox(content, 120, 6, "manual control", function(e:Event) : void {
            if (manual.selected) {
                pad.onStart = Ar.play;
                pad.onStop = Ar.stop;
                Ar.stop();
            } else {
                pad.onStart = null;
                pad.onStop = null;
                Ar.play();
            }
        });
        manual.selected = false;
        pad = new ControlPad(content, 120, 22, 100, 100);
        pad.onChange = function() : void {
            Ar.scaleIndex = pad.rx * 20 - 10;
            Ar.gateTime = pad.ry;
            Ar.noteLength = [2,1,2,1][int(pad.ry * 3.9)];
            Ar.portament = (pad.ry == 0 || pad.ry == 1) ? 5 : 0;
            gt.text = ": "+Ar.gateTime.toFixed(2);
            po.text = ": "+Ar.portament.toString();
            si.text = ": "+Ar.scaleIndex.toString();
            nl.text = ": "+Ar.noteLength.toFixed(1);
        }
        pad.setPointer(0.5, Ar.gateTime);
    }
    
    protected function onColorChanged(e:Event) : void {
        var c8:Number = col8th.value, c5:Number = col5th.value, c4:Number = col4th.value, col:uint = 0;
        col |= (c8<0.75) ? 15 : int((1 - c8) * 60);
        col |= ((c8<0.50) ? (c8*30) : (c8<0.75) ? 15 : int((1 - c8) * 44 + 4))<<4;
        col |= ((c8<0.25) ? 0 : (c8<0.75) ? int((c8-0.25)*30) : int((1 - c8) * 32 + 7))<<12;
        col |= ((c8<0.50) ? 0 : int((c8-0.5)*30))<<24;
        col |= ((c5<0.50) ? int(c5*30) : 15)<<8;
        col |= ((c5<0.50) ? 0 : int((c5-0.5)*30))<<20;
        col |= (c4*15)<<16;
        col |= [0,3,5,1][ws.choice]<<28;
        waveTableSynth.color = col;
        wc.text = "0x"+("0000000"+col.toString(16)).substr(-8,8);
    }
}

class BsPanel extends SoundObjectPanel {
    public var Bs:BassSequencer, analogSynth:AnalogSynth;
    public var patternNumber:Label, vca:EnvelopControler, vcf:EnvelopControler, res:VSlider;
    public var aat:Label, adt:Label, asl:Label, art:Label;
    public var fco:Label, fre:Label, fat:Label, fdt:Label, fpk:Label;
    function BsPanel(parent:DisplayObjectContainer, Bs:BassSequencer) {
        super(parent, 233, 78, "BassSequencer", Bs);
        this.Bs = Bs;
        this.analogSynth = Bs.synthesizer as AnalogSynth;

        new Label(content, 50, 30, "patternNumber property : ");
        patternNumber = new Label(content, 215, 48, String(Bs.patternNumber));
        var ps:HSlider = new HSlider(content, 50, 48, function(e:Event):void{ 
            Bs.patternNumber = e.target.value; 
            patternNumber.text = String(Bs.patternNumber);
        });
        ps.setSize(160, 14);
        ps.setSliderParams(0, Bs.patternNumberMax-1,  Bs.patternNumber);

        vca = new EnvelopControler(content, 50,  68, 100, 54, {
            "at":analogSynth.attackTime  * 1.4285714285714286,
            "dt":analogSynth.decayTime   * 1.4285714285714286, 
            "sl":analogSynth.sustainLevel,
            "rt":analogSynth.releaseTime * 1.4285714285714286
        });
        vca.onUpdate = onVCAUpdate;
        new Label(content, 125, 68, "VCA");
        
        vcf = new EnvelopControler(content, 50, 124, 100, 54, {
            "at":analogSynth.vcfAttackTime  * 1.4285714285714286,
            "tl":analogSynth.vcfPeakCutoff, 
            "dt":analogSynth.vcfDecayTime   * 1.4285714285714286, 
            "sl":analogSynth.cutoff
        });
        vcf.onUpdate = onVCFUpdate;
        new Label(content, 125, 124, "VCF");
        res = new VSlider(content, 152, 124, onVCFUpdate);
        res.setSliderParams(0, 1, analogSynth.resonance);
        res.setSize(10, 54);
        res.tick = 0.0078125;
        
        var ly:Number = 54;
        aat = envparam("attackT.", analogSynth.attackTime);
        adt = envparam("decayT.",  analogSynth.decayTime);
        asl = envparam("sustainL.",analogSynth.sustainLevel);
        art = envparam("releaseT.",analogSynth.releaseTime);
        fco = envparam("cutoff",   analogSynth.cutoff);
        fre = envparam("resonan.", analogSynth.resonance);
        fat = envparam("vcfAtt.",  analogSynth.vcfAttackTime);
        fdt = envparam("vcfDec.",  analogSynth.vcfDecayTime);
        fpk = envparam("vcfPeak",  analogSynth.vcfPeakCutoff);
        
        function envparam(label:String, value:Number) : Label {
            ly +=12;
            new Label(content, 164, ly, label);
            return new Label(content, 204, ly, value.toFixed(2)); 
        }
    }
    
    protected function onVCAUpdate(e:Event=null) : void {
        analogSynth.setVCAEnvelop(vca.at*0.7, vca.dt*0.7, vca.sl, vca.rt*0.7);
        aat.text = analogSynth.attackTime.toFixed(2);
        adt.text = analogSynth.decayTime.toFixed(2);
        asl.text = analogSynth.sustainLevel.toFixed(2);
        art.text = analogSynth.releaseTime.toFixed(2);
    }
    
    protected function onVCFUpdate(e:Event=null) : void {
        analogSynth.setVCFEnvelop(vcf.sl*vcf.tl, res.value, vcf.at*0.7, vcf.dt*0.7, vcf.tl);
        fco.text = analogSynth.cutoff.toFixed(2);
        fre.text = analogSynth.resonance.toFixed(2);
        fat.text = analogSynth.vcfAttackTime.toFixed(2);
        fdt.text = analogSynth.vcfDecayTime.toFixed(2);
        fpk.text = analogSynth.vcfPeakCutoff.toFixed(2);
    }
}

class CpPanel extends SoundObjectPanel {
    public var Cp:ChordPad, padVoiceLoader:PresetVoiceLoader, nameLabel:Label, ls:LengthSequencer, pb:HSlider, pbLabel:Label;
    public var voiceNumbers:Array = [3, 5, 7, 12, 16, 17, 18, 25, 81, 87];
    function CpPanel(parent:DisplayObjectContainer, Cp:ChordPad) {
        super(parent, 2, 260, "ChordPad", Cp);
        this.Cp = Cp;
        this.padVoiceLoader = Cp.synthesizer as PresetVoiceLoader;
        
        var shape:Shape = new Shape();
        shape.graphics.beginFill(Style.BUTTON_FACE);
        shape.graphics.drawRect(56, 90, 48, 14);
        shape.graphics.endFill();
        content.addChild(shape);
        nameLabel = new Label(content, 58, 87, padVoiceLoader.voice.name);

        var vn:RotarySelector = new RotarySelector(content, 60, 45, "", function(e:Event):void {
            padVoiceLoader.voiceNumber = voiceNumbers[e.target.choice];
            nameLabel.text = padVoiceLoader.voice.name;
        });
        vn.setSize(40, 40);
        vn.labelMode = "roman";
        vn.numChoices = 10;
        vn.choice = 2;
        
        new Label(content, 128, 21, "voiceMode property :");
        new RadioButton(content, 132, 39, "CLOSED",      false, function(e:Event):void { Cp.voiceMode = ChordPad.CLOSED; });
        new RadioButton(content, 132, 53, "OPENED",      false, function(e:Event):void { Cp.voiceMode = ChordPad.OPENED; });
        new RadioButton(content, 132, 67, "MIDDLE",      false, function(e:Event):void { Cp.voiceMode = ChordPad.MIDDLE; });
        new RadioButton(content, 132, 81, "HIGH",        true,  function(e:Event):void { Cp.voiceMode = ChordPad.HIGH; });
        new RadioButton(content, 132, 95, "OPENED_HIGH", false, function(e:Event):void { Cp.voiceMode = ChordPad.OPENED_HIGH; });

        new Label(content, 50, 104, "pitchBend property :");
        pbLabel = new Label(content, 156, 104, "0.00");
        pb = new HSlider(content, 50, 124, function(e:Event):void { Cp.pitchBend = pb.value; });
        pb.addEventListener("enterFrame", function(e:Event):void { 
            Cp.pitchBend = (pb.value *= 0.92);
            pbLabel.text = Cp.pitchBend.toFixed(2);
        })
        pb.setSliderParams(-2, 2, 0);
        pb.setSize(176, 12);
        pb.tick = 0.0078125;
        
        new Label(content, 50, 138, "pattern property :");
        ls = new LengthSequencer(content, 50, 160, 176, 12, Cp.pattern);
        ls.onUpdate = function() : void { Cp.pattern = ls.pattern; }
        new PushButton(content, 176, 142, "clear", function():void{ Cp.pattern = ls.clear(); }).setSize(50, 14);
    }
}

class DmPanel extends SoundObjectPanel {
    public var Dm:DrumMachine;
    public var bdpNumber:Label, sdpNumber:Label, hhpNumber:Label;
    public var bdMute:CheckBox, sdMute:CheckBox, hhMute:CheckBox;
    function DmPanel(parent:DisplayObjectContainer, Dm:DrumMachine) {
        super(parent, 233, 260, "DrumMachine", Dm);
        this.Dm = Dm;
        
        new Label(content, 50, 35, "bassPatternNumber property : ");
        bdpNumber = new Label(content, 215, 54, String(Dm.bassPatternNumber));
        var bdp:HSlider = new HSlider(content, 50, 54, function(e:Event):void{ 
            Dm.bassPatternNumber = e.target.value; 
            bdpNumber.text = String(Dm.bassPatternNumber);
        });
        bdp.setSize(160, 14);
        bdp.setSliderParams(0, Dm.bassPatternNumberMax-1,  Dm.bassPatternNumber);
        
        new Label(content, 50, 70, "snarePatternNumber property : ");
        sdpNumber = new Label(content, 215, 89, String(Dm.snarePatternNumber));
        var sdp:HSlider = new HSlider(content, 50, 89, function(e:Event):void{ 
            Dm.snarePatternNumber = e.target.value; 
            sdpNumber.text = String(Dm.snarePatternNumber);
        });
        sdp.setSize(160, 14);
        sdp.setSliderParams(0, Dm.snarePatternNumberMax-1, Dm.snarePatternNumber);
        
        new Label(content, 50, 105, "hihatPatternNumber property : ");
        hhpNumber = new Label(content, 215, 124, String(Dm.hihatPatternNumber));
        var hhp:HSlider = new HSlider(content, 50, 124, function(e:Event):void{ 
            Dm.hihatPatternNumber = e.target.value; 
            hhpNumber.text = String(Dm.hihatPatternNumber);
        });
        hhp.setSize(160, 14);
        hhp.setSliderParams(0, Dm.hihatPatternNumberMax-1, Dm.hihatPatternNumber);
        
        new Label(content, 50, 140, "Sequencer.mute property : ");
        bdMute = new CheckBox(content,  50, 160, "bass",  function(e:Event):void{ Dm.bass.mute  = bdMute.selected; });
        sdMute = new CheckBox(content, 120, 160, "snare", function(e:Event):void{ Dm.snare.mute = sdMute.selected; });
        hhMute = new CheckBox(content, 190, 160, "hihat", function(e:Event):void{ Dm.hihat.mute = hhMute.selected; });
    }
}


// custom component "Knob_" is a small knob.
class Knob_ extends Component {
    public var knob:Sprite, label:Label, valueLabel:Label, _startY:Number, rad:Number=10, value:Number=0;
    public var minimum:Number=0, maximum:Number=1;
    function Knob_(parent:DisplayObjectContainer, x:Number, y:Number, labelText:String, onChange:Function) {
        super(parent, x, y);
        addChild(knob = new Sprite());
        knob.filters = [getShadow(1)];
        knob.buttonMode = true;
        knob.useHandCursor = true;
        knob.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        label = new Label(this, 0, 0, labelText);
        label.autoSize = true;
        label.draw();
        label.x = rad - label.width / 2;
        valueLabel = new Label(this);
        valueLabel.autoSize = true;
        if (onChange != null) addEventListener(Event.CHANGE, onChange);
    }
    
    override public function draw() : void {
        knob.graphics.clear();
        knob.graphics.beginFill(Style.BACKGROUND);
        knob.graphics.drawCircle(0, 0, rad);
        knob.graphics.endFill();
        knob.graphics.beginFill(Style.BUTTON_FACE);
        knob.graphics.drawCircle(0, 0, rad - 2);
        knob.graphics.endFill();
        knob.graphics.beginFill(Style.BACKGROUND);
        knob.graphics.drawRect(rad*0.5, -rad*0.1, rad*0.6, rad*0.2);
        knob.graphics.endFill();
        knob.x = rad;
        knob.y = rad + 20;
        knob.rotation = -225 + (value - minimum)/(maximum - minimum) * 270;
        valueLabel.text = value.toFixed(2);
        valueLabel.draw();
        valueLabel.x = rad - valueLabel.width * 0.5;
        valueLabel.y = rad * 2 + 20;
    }
    
    protected function onMouseDown(event:MouseEvent) : void {
        _startY = mouseY;
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    }
    
    protected function onMouseMove(event:MouseEvent):void {
        var oldValue:Number=value, diff:Number=_startY-mouseY, 
            range:Number=maximum-minimum, percent:Number=range/200;
        value += percent * diff;
        if (value < minimum) value = minimum;
        else if (value > maximum) value = maximum;
        if (value != oldValue) {
            invalidate();
            dispatchEvent(new Event(Event.CHANGE));
        }
        _startY = mouseY;
    }
    
    protected function onMouseUp(event:MouseEvent) : void {
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
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


// custom component "LengthSequencer" shown in ChordPad panel
class LengthSequencer extends Component {
    public var back:Sprite, cursor:Sprite, notes:Sprite, sepr:Shape;
    public var divw:Number, pattern:Array, onUpdate:Function;
    public var pointer:int=0, dragPoint:int, cursorPos:int, cursorLen:int;
    function LengthSequencer(parent:DisplayObjectContainer, x:Number, y:Number, width:Number, height:Number, pattern:Array) {
        super(parent, x, y);
        this.pattern = pattern;
        addChild(back = new Sprite());
        back.filters = [getShadow(2, true)];
        addEventListener(MouseEvent.MOUSE_DOWN, onDrag);
        addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        addChild(notes = new Sprite());
        notes.filters = [getShadow(1)];
        addChild(cursor = new Sprite());
        cursor.buttonMode = true;
        cursor.useHandCursor = true;
        addChild(sepr = new Shape());
        setSize(width, height);
        divw = width/16;
        back.graphics.clear();
        back.graphics.beginFill(Style.BACKGROUND);
        back.graphics.drawRect(0, 0, width, height);
        back.graphics.endFill();
        sepr.graphics.clear();
        sepr.graphics.lineStyle(1, Style.LABEL_TEXT);
        for (var i:int=1; i<16; i++) {
            sepr.graphics.moveTo(divw*i, 1);
            sepr.graphics.lineTo(divw*i, height-1);
        }
        dragPoint = -1;
        cursorLen = 1;
    }
    
    override public function draw() : void {
        super.draw();
        updateCursor();
        updatePattern();
    }
    
    public function clear() : Array {
        for (var i:int=0; i<16; i++) pattern[i] = 0;
        invalidate();
        return pattern;
    }
    
    protected function updateCursor() : void {
        cursor.graphics.clear();
        cursor.graphics.beginFill(Style_POINTER, 0.5);
        cursor.graphics.drawRect(2, 2, divw * cursorLen-2, height-3);
        cursor.graphics.endFill();
    }
    
    protected function updatePattern() : void {
        notes.graphics.clear();
        notes.graphics.beginFill(Style.BUTTON_FACE);
        for (var i:int=0; i<16; i++) {
            if (pattern[i] > 0) notes.graphics.drawRect(i*divw+3, 3, divw*pattern[i]-5, height-6);
        }
        notes.graphics.endFill();
    }
    
    protected function onDrag(e:Event) : void {
        stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onSlide);
        back.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        cursor.startDrag(false, new Rectangle(0, 0, width, 0));
        pointer = mouseX / divw;
        dragPoint = pointer = (pointer<0) ? 0 : (pointer>15) ? 15 : pointer;
    }
    
    protected function onDrop(e:MouseEvent) : void {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSlide);
        back.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stopDrag();
        var ptr:int = getNoteIndex(cursorPos);
        if (ptr != -1) pattern[ptr] = cursorPos - ptr;
        for (var i:int=0; i<cursorLen; i++) {
            if (pattern[cursorPos+i] > cursorLen-i) {
                pattern[cursorPos+cursorLen] = pattern[cursorPos+i] - cursorLen + i;
            }
            pattern[cursorPos+i] = 0;
        }
        pattern[cursorPos] = cursorLen;
        dragPoint = -1;
        cursorLen = 1;
        invalidate();
        if (onUpdate != null) onUpdate();
    }
    
    protected function onMouseMove(e:MouseEvent) : void {
        pointer = mouseX / divw;
        cursorPos = pointer = (pointer<0) ? 0 : (pointer>15) ? 15 : pointer;
        cursor.x = pointer * divw;
    }

    protected function onSlide(e:MouseEvent) : void {
        var prevLen:int = cursorLen;
        pointer = mouseX / divw;
        cursorPos = pointer = (pointer<0) ? 0 : (pointer>15) ? 15 : pointer;
        cursorLen = dragPoint - pointer + 1;
        if (cursorLen <= 0) {
            cursorLen = -cursorLen + 2;
            cursorPos = dragPoint;
        }
        if (prevLen != cursorLen) updateCursor();
        cursor.x = cursorPos * divw;
    }
    
    protected function getNoteIndex(pos:int) : int {
        for (var ptr:int=pos; ptr>=0; ptr--) {
            if (pattern[ptr] > 0) return (pattern[ptr] > pos - ptr) ? ptr : -1;
        }
        return -1;
    }
}