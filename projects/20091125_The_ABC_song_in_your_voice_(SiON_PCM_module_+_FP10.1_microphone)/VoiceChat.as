// forked from keno42's FP10.1用 マイク録音&再生
// マウスダウンの間に録音、放すと きらきら星 in your voice
package  
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.SampleDataEvent;
    import flash.media.Microphone;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.text.TextField;
    import flash.utils.ByteArray;
    import org.si.sion.*;
    public class VoiceChat extends Sprite
    {
        private var recording:Sprite = new Sprite();
        private const recordR:Number = 100; // 半径
        private const recordW:Number = 40; // ボリュームに応じた揺れ幅
        private var mic:Microphone;
        public function VoiceChat() 
        {
            addChild(recording);
            mic = Microphone.getMicrophone();
            mic.rate = 44;
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
            stage.addEventListener(MouseEvent.MOUSE_UP, onUp);
        }
        private function onDown(e:MouseEvent):void {
            recording.x = e.localX;
            recording.y = e.localY;
            myVoice = new ByteArray();
            mic.addEventListener(SampleDataEvent.SAMPLE_DATA, onRecord);
        }
        private function onUp(e:MouseEvent):void {
            recording.graphics.clear();
            mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, onRecord);
            myVoice.position = 0;
            //var sound:Sound = new Sound();
            //sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onPlay);
            //sound.play();
            var i:int, imax:int = myVoice.bytesAvailable>>3, 
                data:Vector.<Number>=new Vector.<Number>(imax);
            for (i=0; i<imax; i++) {
                var n:Number = myVoice.readFloat()*10;
                data[i] = (n>1)?1:(n<-1)?-1:n;
            }
            driver.setPCMData(0, data, false);
            driver.play("t100%7@0q8l8[ccggaag4ffeeddc4|[ggffeed4]]");
        }
        private var driver:SiONDriver = new SiONDriver();
        private var myVoice:ByteArray = new ByteArray();
        private function onRecord(e:SampleDataEvent):void {
            myVoice.writeBytes(e.data);
            e.data.position = 0;
            recording.graphics.clear();
            recording.graphics.lineStyle(0);
            var fr:Number = recordR + recordW * e.data.readFloat();
            var fa:Number = Math.PI / 128;
            recording.graphics.moveTo( fr * Math.cos(fa), fr * Math.sin(fa) );
            for ( var i:int = 2; i < 256; i += 2 ) {
                var r:Number = recordR + recordW * e.data.readFloat();
                var a:Number = i * Math.PI / 128;
                recording.graphics.lineTo( r * Math.cos(a), r * Math.sin(a) );
            }
            recording.graphics.lineTo( fr * Math.cos(fa), fr * Math.sin(fa) );
        }
    }
}