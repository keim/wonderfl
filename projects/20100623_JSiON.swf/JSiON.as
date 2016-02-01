// This SWF is refered from http://jsdo.it/keim_at_Si/JSiON.

package {
    import flash.display.Sprite;
    import flash.system.Security;
    import flash.external.ExternalInterface;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.sequencer.*;
    import org.si.sion.events.*;
    import org.si.sion.utils.*;
    
    [SWF(frameRate='60')]
    public class JSiON extends Sprite {
        public var driver:SiONDriver = new SiONDriver();
        public var dataList:Array = [];
        public var voiceList:* = {};
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        public var timerCount:int = 0;
        public var customVoiceIndex:int = 0;
        
        function JSiON() {
            Security.allowDomain("*");
            
            driver.autoStop = true;
            driver.debugMode = true;
            
            // register javascript interfaces
            ExternalInterface.addCallback("_compile", _compile);
            ExternalInterface.addCallback("_play",    _play);
            ExternalInterface.addCallback("_playmml", _playmml);
            ExternalInterface.addCallback("_stop",    _stop);
            ExternalInterface.addCallback("_pause",   driver.pause);
            ExternalInterface.addCallback("_resume",  driver.play);
            ExternalInterface.addCallback("_volume",  _volume);
            ExternalInterface.addCallback("_pan",     _pan);
            ExternalInterface.addCallback("_position",_position);
            ExternalInterface.addCallback("_bpm",     _bpm);
            ExternalInterface.addCallback("_noteOn",  _noteOn);
            ExternalInterface.addCallback("_noteOff", _noteOff);
            ExternalInterface.addCallback("_sequenceOn",  _sequenceOn);
            ExternalInterface.addCallback("_sequenceOff", _sequenceOff);
            
            // register handlers
            driver.setBeatCallbackInterval(1);
            driver.setTimerInterruption(1, _onTimerInterruption);
            driver.addEventListener(ErrorEvent.ERROR,             _onError);
            driver.addEventListener(SiONEvent.STREAM,             _onStream);
            driver.addEventListener(SiONEvent.STREAM_START,       _onStreamStart);
            driver.addEventListener(SiONEvent.STREAM_STOP,        _onStreamStop);
            driver.addEventListener(SiONEvent.FADE_IN_COMPLETE,   _onFadeInComplete);
            driver.addEventListener(SiONEvent.FADE_OUT_COMPLETE,  _onFadeOutComplete);
            driver.addEventListener(SiONTrackEvent.BEAT,          _onBeat);
            driver.addEventListener(SiONTrackEvent.NOTE_ON_FRAME, _onNoteOn);
            driver.addEventListener(SiONTrackEvent.NOTE_OFF_FRAME,_onNoteOff);
            
            ExternalInterface.call('JSiON.__onLoad', SiONDriver.VERSION);
        }
        
        
    // call javascript
    //--------------------------------------------------
        private function _onError(e:ErrorEvent)          : void { _error(e.text); }
        private function _onStream(e:SiONEvent)          : void { ExternalInterface.call('JSiON.__onStream'); }
        private function _onStreamStart(e:SiONEvent)     : void { ExternalInterface.call('JSiON.__onStreamStart'); timerCount = 0; }
        private function _onStreamStop(e:SiONEvent)      : void { ExternalInterface.call('JSiON.__onStreamStop'); }
        private function _onFadeInComplete(e:SiONEvent)  : void { ExternalInterface.call('JSiON.__onFadeInComplete'); }
        private function _onFadeOutComplete(e:SiONEvent) : void { ExternalInterface.call('JSiON.__onFadeOutComplete'); }
        private function _onBeat(e:SiONTrackEvent)       : void { ExternalInterface.call('JSiON.__onBeat', e.eventTriggerID); }
        private function _onTimerInterruption()          : void { ExternalInterface.call('JSiON.__onTimer', timerCount); timerCount++; }
        private function _onNoteOn(e:SiONTrackEvent)     : void { ExternalInterface.call('JSiON.__onNoteOn', e.eventTriggerID, e.note); }
        private function _onNoteOff(e:SiONTrackEvent)    : void { ExternalInterface.call('JSiON.__onNoteOff', e.eventTriggerID, e.note); }
        
        
    // callback from javascript
    //--------------------------------------------------
        private function _compile(...args) : * {
            if (args[0]) {
                dataList.push(driver.compile(args[0]));
                return dataList.length - 1;
            }
            return -1;
        }
        
        private function _play(...args) : void {
            var fadeTime:Number = Number(args[1]);
            driver.fadeIn((isNaN(fadeTime)) ? 0 : fadeTime);
            driver.play(dataList[int(args[0])] as SiONData);
        }
        
        private function _playmml(...args) : void {
            var fadeTime:Number = Number(args[1]);
            driver.fadeIn((isNaN(fadeTime)) ? 0 : fadeTime);
            driver.play(String(args[0]));
        }
        
        private function _stop(...args) : void {
            var fadeTime:Number = Number(args[0]);
            if (!isNaN(fadeTime)) driver.fadeOut(fadeTime);
            else driver.stop();
        }
        
        private function _volume(...args) : * {
            var vol:Number = Number(args[0]);
            if (!isNaN(vol)) driver.volume = (vol<0) ? 0 : (vol>1) ? 1 : vol;
            return driver.volume;
        }
    
        private function _pan(...args) : * {
            var pan:Number = Number(args[0]);
            if (!isNaN(pan)) driver.pan = (pan<-1) ? -1 : (pan>1) ? 1 : pan;
            return driver.pan;
        }
        
        private function _position(...args) : * {
            var pos:Number = Number(args[0]);
            if (!isNaN(pos)) driver.position = pos;
            return driver.position;
        }
        
        private function _bpm(...args) : * {
            var bpm:Number = Number(args[0]);
            if (!isNaN(bpm)) driver.bpm = bpm;
            return driver.bpm;
        }
        
        private function _noteOn(note:int, voiceID:String, length:Number, delay:Number, quant:Number, trackID:int, params:*) : * {
            if (isNaN(length)) length = 4;
            if (isNaN(delay))  delay = 0;
            if (isNaN(quant))  quant = 0;
            var track:SiMMLTrack = driver.noteOn(note, _getVoiceByID(voiceID), length, delay, quant, trackID);
            if (track) {
                try { for (var prop:String in params) if (prop in track) track[prop] = params[prop]; }
                catch (e:Error) { _onError(new ErrorEvent(e.toString())); }
            }
        }
        
        private function _noteOff(note:int, trackID:int, delay:Number, quant:Number) : void {
            if (isNaN(delay)) delay = 0;
            if (isNaN(quant)) quant = 0;
            driver.noteOff(note, trackID, delay, quant);
        }
        
        private function _sequenceOn(dataIndex:int, voiceID:String, length:Number, delay:Number, quant:Number, trackID:int) : * {
            if (isNaN(length)) length = 4;
            if (isNaN(delay))  delay = 0;
            if (isNaN(quant))  quant = 0;
            var data:SiONData = dataList[dataIndex] as SiONData;
            driver.sequenceOn(data, _getVoiceByID(voiceID), length, delay, quant, trackID);
        }
        
        private function _sequenceOff(trackID:int, delay:Number, quant:Number) : void {
            if (isNaN(delay)) delay = 0;
            if (isNaN(quant)) quant = 0;
            driver.sequenceOff(trackID, delay, quant);
        }
        
        private function _createVoice(...args) : String {
            var name:String = "customVoice[" + String(customVoiceIndex++) + "]",
                type:int = (args[0] != undefined) ? int(args[0]) : 5,
                ch:int   = (args[1] != undefined) ? int(args[1]) : 0,
                ar:int   = (args[2] != undefined) ? int(args[2]) : 63,
                rr:int   = (args[3] != undefined) ? int(args[3]) : 63,
                con:int  = (args[4] != undefined) ? int(args[4]) : -1,
                ws2:int  = (args[5] != undefined) ? int(args[5]) : 0,
                dt2:int  = (args[6] != undefined) ? int(args[6]) : 0;
            voiceList[name] = new SiONVoice(type, ch, ar, rr, con, ws2, dt2);
            return name;
        }
        
        private function _error(text:String) : void { 
            ExternalInterface.call('JSiON.__onError', text);
        }
        
        
    // internal use
    //--------------------------------------------------
        private function _getVoiceByID(voiceID:String) : SiONVoice {
            if (voiceID in voiceList) return voiceList[voiceID] as SiONVoice;
            return presetVoice[voiceID];
        }
    }
}

