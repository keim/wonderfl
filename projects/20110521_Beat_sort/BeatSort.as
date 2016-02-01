// forked from saharan's Sleep sort
package {
    import flash.events.*;
    import flash.utils.*;
    import flash.text.TextField;
    import flash.display.Sprite;
    import org.si.sion.*;
    import org.si.sion.sequencer.*;
    import org.si.sion.events.*;
    import org.si.sound.*;
    public class BeatSort extends Sprite {
        private var trace:TextField;
        private var sion:SiONDriver = new SiONDriver();
        private var dm:DrumMachine = new DrumMachine();
        private var pitchScale:int;
        public function BeatSort() {
            initialize();
        }
        
        private function initialize():void {
            trace = new TextField();
            trace.wordWrap = true;
            trace.width = 465;
            trace.height = 465;
            addChild(trace);
            var numbers:Array = new Array();
            var i:int;
            for (i = 0; i < 200; i++) {
                numbers[i] = i;
                var flip:int = Math.random() * i;
                var temp:uint = numbers[i];
                numbers[i] = numbers[flip];
                numbers[flip] = temp;
                
            }
            sion.bpm = 144; // sorting speed :)
            sort(numbers);
        }

        private function sort(numbers:Array):void {
            var dualSaw:SiONVoice = new SiONVoice(5, 1, 63, 63, -8, 0, 1, 8);
            sion.addEventListener(SiONTrackEvent.NOTE_ON_FRAME, _onNoteOnFrame);
            sion.maxTrackCount = numbers.length + 10;
            sion.play("#EFFECT1{delay}");
            dm.volume = 1;
            dm.play();

            pitchScale = int(6400 / numbers.length);
            var maxNumber:int = 0;
            for (var i:int = 0; i < numbers.length; i++) {
                var number:uint = numbers[i] as uint;
                var track:SiMMLTrack = sion.noteOn(0, dualSaw, 1, number+8, 1);
                track.pitchShift = i * pitchScale + 1000;
                track.pan = ((i/numbers.length)-0.5) * 120;
                track.velocity = 40;
                track.effectSend1 = 64;
                track.setEventTrigger(0, 1);
                if (maxNumber < number) maxNumber = number;
            }
            // final note dipatchs eventTriggerID = 1
            sion.noteOn(80, new SiONVoice(5,0,63,16), 1, maxNumber+16, 1).setEventTrigger(1, 1);

            function _onNoteOnFrame(e:SiONTrackEvent) : void {
                if (e.eventTriggerID == 1) sion.fadeOut(5);
                else {
                    var index:int = (e.track.pitchShift - 1000)/ pitchScale;
                    trace.appendText(numbers[index].toString() + " ");
                }
            }
        }
    }
}
