// forked from nemu90kWw's MIDIシーケンスを解析してみた
//
// デフォルトのMIDIは，kashiwa@正直日記さんのものをお借りしました．
// 最初に，ドラムをプリレンダリングするため，少し待ってください．
// ほんのちょっと複雑なMIDIファイルを鳴らすだけで，
// 誰でも簡単にブラウザクラッシュができます．
package
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import mx.utils.Base64Decoder;
	
	[SWF(width="465", height="465", frameRate="24")]
	public class main extends Sprite
	{
		private var button:Sprite;
		private var playButton:Sprite, stopButton:Sprite;
		private var fileReference:FileReference;
		
		private var textfield:TextField = new TextField();
		private var information:TextField = new TextField();
		
		private var midi:SMFSequence;
	    
	    private var midiPlayer:MIDIPlayer;
		
		function main()
		{
			textfield.width = 465
			textfield.height = 465-30;
			textfield.y = 30;
			textfield.wordWrap = true;
			addChild(textfield);
			
		    information.width = 232;
			information.height = 30;
		    information.x = 235;
		    information.y = 10;
		    addChild(information);
		    
			var decoder:Base64Decoder = new Base64Decoder();
			decoder.decode(SMFBinary.data);
			
			var ba:ByteArray = decoder.toByteArray();
			ba.uncompress();
			
			midi = new SMFSequence(ba);
			textfield.text = midi.toString();
			
		    button     = b(5, 5, "Open SMF");
		    playButton = b(130, 5, "Play");
		    stopButton = b(130, 5, "Stop");
		    stopButton.visible = false;
		    function b(x:Number, y:Number, label:String) : Sprite {
		        var button:Sprite = new Sprite(),
    		        buttontext:TextField = new TextField();
		        
			button.x = x;
			button.y = y;
			button.mouseChildren = false;
			button.buttonMode = true;
			button.graphics.lineStyle(1, 0xBBBBBB);
			button.graphics.beginFill(0xEEEEEE);
			button.graphics.drawRoundRect(0, 0, 100, 20, 5, 5);
			button.graphics.endFill();
			addChild(button);
			
			buttontext.width = 100;
			buttontext.height = 20;
			buttontext.htmlText = "<p align='center'><font face='_sans'>" + label + "</span></p>";
			button.addChild(buttontext);
			
		        return button;
		    }
		    
			fileReference = new FileReference();
			fileReference.addEventListener(Event.SELECT, onSelect);
			fileReference.addEventListener(Event.COMPLETE, onComplete);
			button.addEventListener(MouseEvent.CLICK, onClick);
		    playButton.addEventListener(MouseEvent.CLICK, onPlay);
		    stopButton.addEventListener(MouseEvent.CLICK, onStop);
		    addEventListener(Event.ENTER_FRAME, onEnverFrame);
		    
		    midiPlayer = new MIDIPlayer();
		}
		
		private function onClick(event:MouseEvent):void 
		{
			fileReference.browse([new FileFilter("MIDIシーケンス(mid)", "*.mid")]);
		}
	    
		private function onSelect(event:Event):void
		{
			fileReference.load();
		}
		
		private function onComplete(event:Event):void
		{
			midi = new SMFSequence(fileReference.data);
			textfield.text = midi.toString();
		}
	    
	    private function onPlay(event:MouseEvent):void 
	    {
	        midiPlayer.play(midi);
	        playButton.visible = false;
	        stopButton.visible = true;
	    }
	    
	    private function onStop(event:MouseEvent):void 
	    {
	        driver.stop();
	        playButton.visible = true;
	        stopButton.visible = false;
	    }
	    
	    private function onEnverFrame(event:Event):void
	    {
	        information.text = "position : " + (driver.position*0.001).toFixed(1) + "[sec]";
	    }
	}
}




import flash.text.*;
import org.si.sion.*;
import org.si.sion.sequencer.SiMMLTrack;
import org.si.sion.utils.SiONPresetVoice;
import org.si.sion.namespaces._sion_internal;

var driver:SiONDriver;

var trackCountLimit:int = 24;
var freePointer:int = 0;
function freeNoteOffTracks() : void {
    var tr:SiMMLTrack, activeTracks:int, i:int, imax:int = driver.trackCount;
    for (activeTracks=0, i=0; i<imax; i++) {
        tr = driver.sequencer.tracks[i];
        if (tr.isActive) activeTracks++;
    }
    if (activeTracks > trackCountLimit) {
        for (activeTracks=0, i=0; i<imax; i++) {
            if (++freePointer == imax) freePointer = 0;
            tr = driver.sequencer.tracks[freePointer];
            if (!tr.channel.isIdling && !tr.channel.isNoteOn()) {
                tr.channel.reset();
                if (--activeTracks == trackCountLimit) return;
            }
        }
        for (i=activeTracks - trackCountLimit; i>=0; --i) {
            if (++freePointer == imax) freePointer = 0;
            tr = driver.sequencer.tracks[freePointer];
            tr.keyOff();
            tr.channel.reset();
        }
    }
}

class MIDIPlayer {
    public  var voices:SiONPresetVoice;
    private var _tickPerClock:Number;
    private var _channels:Vector.<MIDIChannel> = new Vector.<MIDIChannel>(16);
    private var _pointers:Vector.<SMFTrackPointer> = new Vector.<SMFTrackPointer>();
    
    function MIDIPlayer() {
        driver = SiONDriver.mutex || new SiONDriver();
        voices = new SiONPresetVoice();
        MIDIChannel.midiVoiceList = voices["midi"];
        _createGMDrumSet();
        for (var i:int=0; i<16; i++) _channels[i] = new MIDIChannel(i);
    }
    
    public function play(smfData:SMFSequence) : void {
        _pointers.length = smfData.tracks.length;
        for (var i:int=0; i<_pointers.length; i++) {
            _pointers[i] = new SMFTrackPointer(smfData.tracks[i]);
        }
        
        SMFTrackPointer.tickPerClock = smfData.division/8;
        driver.setTimerInterruption(0.5, _onMIDIClock);
        driver.bpm = smfData.tempo;
        
        reset();
        driver.play("#EFFECT1{reverb};#EFFECT2{chorus};");
    }
    
    private function _createGMDrumSet() : void {
        var perc:Array = voices["valsound.percus"], tom:SiONVoice = new SiONVoice(), wave:Vector.<Number>;
        var mml:String = "@v128%6";
        for (var i:int=0; i<perc.length; i++) driver.setVoice(i, perc[i]);
        // bd
        wave = driver.render(mml+"v20@0o2c2");
        driver.setSamplerData(35, wave);
        driver.setSamplerData(36, wave);
        // sd
        driver.setSamplerData(37, driver.render(mml+"v20@26o4c2"));
        driver.setSamplerData(38, driver.render("#EFFECT{ws};@v128%6v16@30o3c2"));
        driver.setSamplerData(39, driver.render(mml+"v20@26o5g2"));
        driver.setSamplerData(40, driver.render("#EFFECT{ws};@v128%6v16@14o2g2"));
        // tom
        tom.param = [8,0,0,19,60,48,0,48,15,12,0,0,1,0,0,0,0,68,17,48,8,0,0,0,0,0,0,1,0,0,0,0,68,34,60,45,0,0,8,26,0,0,1,0,300,0,0,0,32,60,24,0,24,15,0,0,0,1,0,0,0,0,0];
        tom.setLPFEnvelop(100);
        driver.setVoice(64, tom);
        driver.setSamplerData(41, driver.render(mml+"v24@64o3c"));
        driver.setSamplerData(43, driver.render(mml+"v24@64o3e"));
        driver.setSamplerData(45, driver.render(mml+"v24@64o3g"));
        driver.setSamplerData(47, driver.render(mml+"v24@64o4c"));
        driver.setSamplerData(48, driver.render(mml+"v24@64o4g"));
        driver.setSamplerData(50, driver.render(mml+"v24@64o4b"));
        // hh
        driver.setSamplerData(42, driver.render(mml+"p2v6@17o4c"));
        driver.setSamplerData(44, driver.render(mml+"p2v6@15o4c"));
        driver.setSamplerData(46, driver.render(mml+"p2v6@24o5f1"));
        // cc
        driver.setSamplerData(49, driver.render(mml+"v16@7o5c1^1"));
        driver.setSamplerData(51, driver.render(mml+"v16@27o6f+1^1"));
        driver.setSamplerData(52, driver.render(mml+"v16@7o2g1^1"));
        driver.setSamplerData(55, driver.render(mml+"v16@7o5c1^1"));
        driver.setSamplerData(57, driver.render(mml+"v16@7o5f1^1"));
    }
    
    public function reset() : void {
        for (var i:int=0; i<16; i++) _channels[i].reset();
    }
    
    private function _onMIDIClock() : void {
        freeNoteOffTracks();
        var e:SMFEvent, pt:SMFTrackPointer;
        for each (pt in _pointers) {
            while (e = pt.getNextEvent()) {
                switch(e.type) {
                case 0x80: _channels[e.channel].noteOff(e.note); break;
                case 0x90: _channels[e.channel].noteOn(e.note, e.velocity); break;
                case 0xa0: _channels[e.channel].channelAfterTouch(e.value); break;
                case 0xb0: _channels[e.channel].controlChange(e.cc, e.value); break;
                case 0xc0: _channels[e.channel].programChange(e.value); break;
                case 0xd0: _channels[e.channel].channelAfterTouch(e.value); break;
                case 0xe0: _channels[e.channel].pitchBend(e.lsb | (e.msb<<7)); break;
                case 0x51: driver.bpm = 60000000/e.tempo; break;
                }
            }
        }
    }
}

class SMFTrackPointer {
    static public var tickPerClock:Number;
    public var smfSequence:Vector.<SMFEvent>, pointer:int=0, ticks:Number=0;
    function SMFTrackPointer(track:SMFTrack) { smfSequence = track.sequence; }
    public function getNextEvent() : SMFEvent {
        if (pointer >= smfSequence.length) return null;
        var e:SMFEvent = smfSequence[pointer];
        ticks += e.delta_time;
        if (ticks >= tickPerClock) {
            ticks -= (e.delta_time + tickPerClock);
            return null;
        }
        pointer++;
        return e;
    }
}

class MIDIChannel {
    use namespace _sion_internal;
    static public var midiVoiceList:Array;
    static private var _pbRate:Number = 1/8192*64;
    
    public var drumChannel:Boolean = false, mute:Boolean = false;
    public var volumes:Vector.<int>, exp:int, pan:int, centerPitch:int;
    public var programNum:int, pb:int, afterTouch:int, modulation:int;
    public var rpn:int, pbRange:int, fineTune:int, courseTune:int;
    private var _trackID:int;
    
    function MIDIChannel(channelNumber:int) {
        _trackID = channelNumber;
        drumChannel = (channelNumber == 9);
    }
    
    public function reset() : void {
        volumes = Vector.<int>([100, 0, 0, 0, 0, 0, 0, 0]);
        programNum = 0;
        exp = 128;
        pan = 64;
        pb = 0;
        afterTouch = 0;
        modulation = 0;
        rpn = 0;
        pbRange = 2;
        fineTune = 64;
        courseTune = 64;
    }
    
    public function noteOff(note:int) : void {
        if (mute) return;
        driver.noteOff(note, _trackID, 0, 0);
    }
    
    public function noteOn(note:int, vel:int) : void {
        var track:SiMMLTrack;
        if (mute) return;
        if (vel == 0) noteOff(note);
        else {
            if (drumChannel) track = driver.playSound(note, 0, 0, 0, _trackID);
            else track = driver.noteOn(note, midiVoiceList[programNum], 0, 0, 0, _trackID);
            track.noteShift  = courseTune - 64; // not available
            track.pitchShift = fineTune - 64;   // not available
            track.velocity = vel + afterTouch;
            track.expression = exp;
            track.channel.setAllStreamSendLevels(volumes);
            track.channel.pan = pan-64;
            track.channel.setPitchModulation(modulation);
            if (pb != 0) track.channel.pitch += pb * pbRange * _pbRate;
        }
    }
    
    public function controlChange(cc:int, value:int) : void {
        switch (cc) {
        case 1:  modulation = value; break;
        case 6:  dataEntry(value); break;
        case 7:  volumes[0] = value; break;
        case 10: pan = value; break;
        case 33: modulation = value; break;
        case 91: volumes[1] = value; break;
        case 93: volumes[2] = value; break;
        case 100: rpn = (rpn & 0xff00) | value;      break; // LSB
        case 101: rpn = (rpn & 0x00ff) | (value<<8); break; // MSB
        case 2: case 11:
            exp = value; 
            forEachTracks(function(tr:SiMMLTrack):void{tr.expression = exp;});
            break;
        }
        
        function dataEntry(value:int) : void {
            switch (rpn) {
            case 0x0000: pbRange    = value; break;
            case 0x0001: fineTune   = value; break;
            case 0x0002: courseTune = value; break;
            }
        }
    }
    
    public function programChange(pn:int) : void {
        programNum = pn;
    }
    
    public function channelAfterTouch(value:int) : void {
        if (mute) return;
        var atDiff:int = afterTouch - value;
        forEachTracks(function(tr:SiMMLTrack) : void { tr.velocity += atDiff; });
        afterTouch = value;
    }
    
    public function pitchBend(value:int) : void {
        var pitchDiff:int = (value - 8192 - pb) * pbRange * _pbRate;
        forEachTracks(function(tr:SiMMLTrack) : void { tr.channel.pitch += pitchDiff; });
        pb = value - 8192;
    }
    
    public function forEachTracks(func:Function) : void {
        // The tracks created by noteOn have an internal track id of "trackID | DRIVER_NOTE_ID_OFFSET".
        var internalTrackID:int = _trackID | SiMMLTrack.DRIVER_NOTE_ID_OFFSET;
        for each (var tr:SiMMLTrack in driver.sequencer.tracks) {
            if (tr.isActive && tr.trackID == internalTrackID) func(tr);
        }
    }
}




	import flash.utils.ByteArray;
	
	class SMFSequence
	{
		public var format:int;
		public var numTracks:int;
		public var division:int;
		public var tempo:int = 0;
		public var title:String = "";
		public var artist:String = "";
		public var signature_n:int;
		public var signature_d:int;
		public var length:int;
		
		public var tracks:Vector.<SMFTrack> = new Vector.<SMFTrack>();
		
		function SMFSequence(bytes:ByteArray)
		{
			bytes.position = 0;
			
			while(bytes.bytesAvailable > 0)
			{
				var type:String = bytes.readMultiByte(4, "us-ascii");
				switch(type)
				{
				case "MThd":	//ヘッダ
					bytes.position += 4;	//ヘッダのデータ長は常に00 00 00 06なのでスルー
					format = bytes.readUnsignedShort();
					numTracks = bytes.readUnsignedShort();
					division = bytes.readUnsignedShort();
					break;
				case "MTrk":	//トラック
					var len:uint = bytes.readUnsignedInt();
					var temp:ByteArray = new ByteArray();
					bytes.readBytes(temp, 0, len);
					var track:SMFTrack = new SMFTrack(this, temp);
					tracks.push(track);
					length = Math.max(length, track.length);
					break;
				default:
					return;
				}
			}
		}
		
		public function toString():String
		{
			var text:String = "format : "+format+" | numTracks : "+numTracks+" | division : "+division+"\n";
			text += "タイトル : "+title+" | 著作権表示 : "+artist+"\n";
			text += "拍子 : "+signature_d+"分の"+signature_n+"拍子 | BPM : "+tempo+" | length : "+length+"\n";
			
			text += "\n";
			
			for(var i:int = 0; i < tracks.length; i++)
			{
				text += "トラック"+i+" : "+tracks[i].toString() + "\n";
			}
			
			return text;
		}
	}

	class SMFTrack
	{
		public var parent:SMFSequence;
		public var sequence:Vector.<SMFEvent> = new Vector.<SMFEvent>();
		public var length:int;
		
		function SMFTrack(parent:SMFSequence, bytes:ByteArray)
		{
			this.parent = parent;
			
			var event:SMFEvent;
			var temp:int;
			var len:int;
			
			var type:int;
			var channel:int;
			
			var time:int;
			/*
			var readVariableLength:Function = function(time:uint = 0):uint
			{
				var temp:uint = bytes.readUnsignedByte();
				if(temp & 0x80) {return readVariableLength(time + (temp & 0x7F));}
				else {return time + (temp & 0x7F);}
			}
			*/
			var readVariableLength:Function = function(time:uint = 0):uint
			{
				var temp:uint = bytes.readUnsignedByte();
				if(temp & 0x80) {return readVariableLength((time << 7) + (temp & 0x7F));}
				else {return (time << 7) + (temp & 0x7F);}
			}
			
			main : while(bytes.bytesAvailable > 0)
			{
				event = new SMFEvent();
				event.delta_time = readVariableLength();
				time += event.delta_time;
				event.time = time;
				
				temp = bytes.readUnsignedByte();
				
				if(temp == 0xFF)
				{
					event.type = bytes.readUnsignedByte();
					len = readVariableLength();
					
					switch(event.type)
					{
					case 0x02:	//作者
						event.artist = bytes.readMultiByte(len, "Shift-JIS");
						parent.artist = event.artist;
						break;
					case 0x03:	//タイトル
						event.title = bytes.readMultiByte(len, "Shift-JIS");
						parent.title = event.title;
						break;
					case 0x2F:	//トラック終了
						break main;
					case 0x51:	//テンポ
						event.tempo = bytes.readUnsignedByte()*0x10000 + bytes.readUnsignedShort();
						if(parent.tempo == 0) {
							parent.tempo = 60000000 / event.tempo;
						}
						break;
					case 0x58:	//拍子
						parent.signature_n = bytes.readUnsignedByte();
						parent.signature_d = Math.pow(2, bytes.readUnsignedByte());
						bytes.position += 2;
						break;
					default:
						bytes.position += len;
						break;
					}
				}
				else if(temp == 0xF0 || temp == 0xF7)	//Sysx
				{
					event.type = temp;
					len = readVariableLength();
					event.sysx = new ByteArray();
					bytes.readBytes(event.sysx, 0, len);
				}
				else {
					if(temp & 0x80) {
						type = temp & 0xF0;
						channel = temp & 0x0F;
					}
					else {
						bytes.position--;
					}
					
					event.type = type;
					event.channel = channel;
					
					switch(type)
					{
					case 0x80:	//ノートオフ
						event.note = bytes.readUnsignedByte();
						event.velocity = bytes.readUnsignedByte();
						break;
					case 0x90:	//ノートオン
						event.note = bytes.readUnsignedByte();
						event.velocity = bytes.readUnsignedByte();
						break;
					case 0xA0:	//ポリフォニックキープレッシャー
						event.note = bytes.readUnsignedByte();
						event.value = bytes.readUnsignedByte();
						break;
					case 0xB0:	//コントロールチェンジ
						event.cc = bytes.readUnsignedByte();
						event.value = bytes.readUnsignedByte();
						break;
					case 0xC0:	//パッチチェンジ
						event.value = bytes.readUnsignedByte();
						break;
					case 0xD0:	//チャンネルプレッシャー
						event.value = bytes.readUnsignedByte();
						break;
					case 0xE0:	//ピッチベンド
						event.lsb = bytes.readUnsignedByte();
						event.msb = bytes.readUnsignedByte();
						break;
					}
				}
				sequence.push(event);
			}
			length = time;
		}
		
		public function toString():String
		{
			var text:String = length + "\n";
			
			for(var i:int = 0; i < sequence.length; i++)
			{
				if(sequence[i].toString() == "") {continue;}
				text += sequence[i].toString();
			}
			
			return text;
		}
	}

	dynamic class SMFEvent
	{
		public var delta_time:uint;	//相対時間
		public var time:uint;	//絶対時間
		public var type:int;
		
		public function toString():String
		{
			var text:String = "";
			//text = type.toString(16);
			//*
			switch(type)
			{
			case 0x90:
				if(this.velocity == 0) {break;}
				
				switch(this.note % 12)
				{
				case  0: text += "ド"; break;
				case  1: text += "ド#"; break;
				case  2: text += "レ"; break;
				case  3: text += "ミb"; break;
				case  4: text += "ミ"; break;
				case  5: text += "ファ"; break;
				case  6: text += "ファ#"; break;
				case  7: text += "ソ"; break;
				case  8: text += "ソ#"; break;
				case  9: text += "ラ"; break;
				case 10: text += "シb"; break;
				case 11: text += "シ"; break;
				}
				//text += " "+this.velocity;
				break;
			case 0xB0:
				text += "CC#" + this.cc +" "+this.value + " ";
				break;
			case 0xC0:
				text += "楽器変更 " + this.value + " ";
				break;
			case 0xF0:
			case 0xF7:
				text += "Sysx : ";
				for(var i:int = 0; i < this.sysx.length; i++) {
					text += this.sysx[i].toString(16)+" ";
				}
				break;
			}
			/*/
			if(type == 0x90 && this.velocity != 0)
			{
				switch(this.note % 12)
				{
				case  0: text += "c"; break;
				case  1: text += "c+"; break;
				case  2: text += "d"; break;
				case  3: text += "d+"; break;
				case  4: text += "e"; break;
				case  5: text += "f"; break;
				case  6: text += "f+"; break;
				case  7: text += "g"; break;
				case  8: text += "g+"; break;
				case  9: text += "a"; break;
				case 10: text += "a+"; break;
				case 11: text += "b"; break;
				}
			}
			//*/
			return text;
		}
	}
	
	class SMFBinary
	{
		public static const data:String = "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";
	}
