// forked from UtilZone's How to give slide effect in guitar
package {
    import flash.display.Sprite;
    import flash.events.*;
    import com.bit101.components.*;
    import org.si.sion.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sion.sequencer.SiMMLEnvelopTable;
    import org.si.sion.sequencer.SiMMLTable;

    public class FlashTest extends Sprite {
        private var track:SiMMLTrack;
        private var driver:SiONDriver;
        private var presetVoice:SiONPresetVoice;
        private var voice:SiONVoice;
        private var envelop:SiMMLEnvelopTable;
        public function FlashTest() {
           driver = new SiONDriver();
           presetVoice = new SiONPresetVoice();
           voice = new SiONVoice();
           voice = presetVoice["valsound.guitar"][1];
           driver.setEnvelopTable(0, Vector.<int>([0,-16,-32,-48,-64]));
           envelop = SiMMLTable.instance.getEnvelopTable(0);
           driver.play();

           var btn:PushButton = new PushButton(this);
            btn.label = "Play!";
            btn.x = 10;
            btn.y = 10
            btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
                track = driver.noteOn(60, voice, 16, 0, 0, 0, true);
                track.noteShift  = 5;
                track.pitchShift = 100;
                track.velocity = 500;
                track.expression = 10;
                track.channel.pan = 10;
                track.setPitchEnvelop(1, envelop, 4);
            }); 
            
        }
    }
}