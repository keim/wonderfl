// SiON ver0.60 サウンドオブジェクト [DrumMachine] の使い方
//   org.si.sound.DrumMachine は，シンプルなリズムジェネレータです．
//   バスドラム，スネア，ハイハットのパターン番号と音色番号を指定して，
//   play() メソッドを呼び出すと，リズムパターンを奏でます．
//
// SiON ver0.60 Useage of the sound object [DrumMachine].
//   The org.si.sound.DrumMachine is a simple rythm pattern player.
//   You can play the rythm pattern by calling play() method
//   with specifying the patten number and the voice number for each bass drum, snare drum and hihat synmbals.

package {
    import flash.display.*;
    import flash.events.Event;
    import org.si.sion.SiONDriver;
    import org.si.sion.effector.*;
    import org.si.sound.DrumMachine;
    
    import com.bit101.components.*;
    
    
    public class main extends Sprite {
        // ユーザーインタフェイス
        // user interfaces
        private var bpmSlider:HUISlider;
        private var bassPanel:PatternControlPanel;
        private var snarePanel:PatternControlPanel;
        private var hihatPanel:PatternControlPanel;

        // SiON インスタンス 
        // SiON instance
        private var driver:SiONDriver;
        private var drums:DrumMachine;
        
        
        // constructor
        function main() {
            // SiONDriver インスタンスを作成します
            // create new SiONDriver 
            driver = new SiONDriver();
            
            // DrumMachine インスタンスを作成します
            // create new DrumMachine
            drums = new DrumMachine(0,0,0,0,0,0);
            
            // changePatternOnNextSegment property (default = true)
            // false の場合パターンを即時変更します．true の場合小節区切りのタイミングでパターン変更します．
            // When it is false, the pattern will change immediately. When it is true, the pattern will change at the head of next measure.
            drums.changePatternOnNextSegment = false;
            
            // リズムパターンを番号で指定します．これらの番号はコンストラクタの引数としても指定可能です．
            // Specify pattern sequence by index number. These numbers can be specifyed in the arguments of constructor.
            drums.bassPatternNumber = 0;
            drums.snarePatternNumber = 0;
            drums.hihatPatternNumber = 0;
            drums.bassVoiceNumber = 0;
            drums.snareVoiceNumber = 0;
            drums.hihatVoiceNumber = 0;
            
            // ユーザーインターフェイスを作成します
            // create user interfaces
            _createUIs();
            
            // SiONDriver を起動します．
            // boot SiONDriver
            driver.play();
            
            // DrumMachine の演奏を開始します
            // start DrumMachine 
            drums.play();
        }
        
        
        private function _createUIs() : void {
            with (bpmSlider = new HUISlider(this, 108, 100, "BPM  ", _onChangeBPM)) {
                setSize(240,10);
                setSliderParams(80, 200, 144);
            }
            with (bassPanel = new PatternControlPanel(this, 8, 130, "bass")) {
                createPatternSlider(drums.bassPatternNumberMax, _onChangeBassPattern);
                createVoiceKnob(drums.bassVoiceNumberMax, _onChangeBassVoice);
                createVolumeKnob(drums.bassVolume, _onChangeBassVolume);
                createMuteCheck(_onChangeBassMute);
                updatePatternDisplay(drums.bassPattern);
            }
            with (snarePanel = new PatternControlPanel(this, 8, 200, "snare")) {
                createPatternSlider(drums.snarePatternNumberMax, _onChangeSnarePattern);
                createVoiceKnob(drums.snareVoiceNumberMax, _onChangeSnareVoice);
                createVolumeKnob(drums.snareVolume, _onChangeSnareVolume);
                createMuteCheck(_onChangeSnareMute);
                updatePatternDisplay(drums.snarePattern);
            }
            with (hihatPanel = new PatternControlPanel(this, 8, 270, "hihat")) {
                createPatternSlider(drums.hihatPatternNumberMax, _onChangeHihatPattern);
                createVoiceKnob(drums.hihatVoiceNumberMax, _onChangeHihatVoice);
                createVolumeKnob(drums.hihatVolume, _onChangeHihatVolume);
                createMuteCheck(_onChangeHihatMute);
                updatePatternDisplay(drums.hihatPattern);
            }
        }
        
        
        // 演奏テンポは，SiONDriver.bpmで変更します
        // Change bpm by SiONDriver.bpm
        private function _onChangeBPM(e:Event) : void {
            driver.bpm = bpmSlider.value;
        }
        
        
        // リズムパターンは，DrumMachine.****PatternNumber で変更します
        // Change sequences by DrumMachine.****PatternNumber
        private function _onChangeBassPattern(e:Event) : void {
            drums.bassPatternNumber = bassPanel.patternNumber;
            
            // リズムパターンは，DrumMachine.****Pattern からVector.<Note>型で参照できます．
            // You can refer sequence from DrumMachine.****Pattern as Vector.<Note>
            bassPanel.updatePatternDisplay(drums.bassPattern);
        }
        
        
        private function _onChangeSnarePattern(e:Event) : void {
            drums.snarePatternNumber = snarePanel.patternNumber;
            snarePanel.updatePatternDisplay(drums.snarePattern);
        }
        
        
        private function _onChangeHihatPattern(e:Event) : void {
            drums.hihatPatternNumber = hihatPanel.patternNumber;
            hihatPanel.updatePatternDisplay(drums.hihatPattern);
        }
        
        
        // リズム音色は，DrumMachine.****VoiceNumber で変更します
        // Change voices by DrumMachine.****VoiceNumber
        private function _onChangeBassVoice(e:Event) : void {
            drums.bassVoiceNumber = bassPanel.voiceNumber;
        }
        
        
        private function _onChangeSnareVoice(e:Event) : void {
            drums.snareVoiceNumber = snarePanel.voiceNumber;
        }
        

        private function _onChangeHihatVoice(e:Event) : void {
            drums.hihatVoiceNumber = hihatPanel.voiceNumber;
        }
        
        
        // 音量は，DrumMachine.****Volume で変更します
        // Change volumes by DrumMachine.****Volume
        private function _onChangeBassVolume(e:Event) : void {
            drums.bassVolume = bassPanel.volume;
        }
        
        
        private function _onChangeSnareVolume(e:Event) : void {
            drums.snareVolume = snarePanel.volume;
        }
        
        
        private function _onChangeHihatVolume(e:Event) : void {
            drums.hihatVolume = hihatPanel.volume;
        }
        
        
        // 消音，DrumMachine.****.mute で行います
        // Mute by DrumMachine.****.mute
        private function _onChangeBassMute(e:Event) : void {
            drums.bass.mute = bassPanel.mute;
        }
        
        
        private function _onChangeSnareMute(e:Event) : void {
            drums.snare.mute = snarePanel.mute;
        }
        
        
        private function _onChangeHihatMute(e:Event) : void {
            drums.hihat.mute = hihatPanel.mute;
        }
    }
}




import flash.display.*;
import flash.events.Event;
import com.bit101.components.*;
import org.si.sound.patterns.Note;

class PatternControlPanel extends Panel {
//-------------------------------------------------- variables
    public var patternSlider:HSlider;
    public var patternLabel:Label;
    public var onSliderChange:Function;
    public var voiceKnob:RotarySelector;
    public var volumeKnob:Knob;
    public var muteCheck:CheckBox;
    public var patternDisplay:Shape;
    
//-------------------------------------------------- properties
    public function get patternNumber() : int     { return int(patternSlider.value + 0.5); }
    public function get voiceNumber()   : int     { return voiceKnob.choice; }
    public function get volume()        : Number  { return volumeKnob.value; }
    public function get mute()          : Boolean { return muteCheck.selected; }
    
//-------------------------------------------------- constructor
    function PatternControlPanel(parent:DisplayObjectContainer, x:Number, y:Number, trackName:String) {
        super(parent, x, y);
        setSize(450, 64);
        new Label(content, 8, 24, trackName);
        patternLabel = new Label(content, 240, 8, "0");
        content.addChild(patternDisplay = new Shape());
        patternDisplay.x = 40;
        patternDisplay.y = 40;
    }
    
//-------------------------------------------------- create user interfaces
    public function createPatternSlider(maximum:int, func:Function) : void {
        onSliderChange = func;
        patternSlider = new HSlider(content, 40, 12, _onSliderChange);
        patternSlider.backClick = true;
        patternSlider.setSize(192, 12);
        patternSlider.setSliderParams(0, maximum-1, 0);
    }
    
    public function createVoiceKnob(maximum:int, func:Function) : void {
        voiceKnob = new RotarySelector(content, 280, 20, "voice", func);
        voiceKnob.setSize(16, 16);
        voiceKnob.labelMode = "numeric";
        voiceKnob.numChoices = maximum;
    }
    
    public function createVolumeKnob(value:Number, func:Function) : void {
        volumeKnob = new Knob(content, 350, 6, "volume", func);
        volumeKnob.radius = 8;
        volumeKnob.labelPrecision = 2;
        volumeKnob.value = value;
        volumeKnob.maximum = 1;
    }
    
    public function createMuteCheck(func:Function) : void {
        muteCheck = new CheckBox(content, 400, 26, "mute", func);
        muteCheck.selected = false;
    }
    
    public function updatePatternDisplay(pattern:Vector.<Note>) : void {
        patternDisplay.graphics.clear();
        patternDisplay.graphics.lineStyle(1, 0x808080);
        for (var i:int = 0; i<16; i++) {
            if (pattern[i] == null) patternDisplay.graphics.beginFill(0xffffff);
            else if (pattern[i].voiceIndex == 1) patternDisplay.graphics.beginFill(0x80c0ff);
            else patternDisplay.graphics.beginFill(0xffc080);
            patternDisplay.graphics.drawRect(i*12, 0, 10, 10);
            patternDisplay.graphics.endFill();
        }
    }
    
    private function _onSliderChange(e:Event) : void {
        patternLabel.text = String(patternNumber);
        onSliderChange(e);
    }
}
