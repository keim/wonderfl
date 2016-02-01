// forked from keno42's FP10.1用 マイク録音&再生
// SiON FFT module で 声紋解析 (Hamming窓＋時間分解能11ms)
package {
    import flash.display.*;
    import flash.events.*;
    import flash.media.*;
    import flash.text.*;
    import flash.utils.ByteArray;
    import org.si.utils.FFT;
    import frocessing.color.ColorLerp;
    import com.bit101.components.*;
    public class main extends Sprite {
        private var voicePrint:BitmapData = new BitmapData(465, 256, false, 0);
        private var mic:Microphone, scaler:HSlider;
        public function main() {
            _initFFT();
            with(addChild(new Bitmap(voicePrint))){ y=100; }
            (scaler = new HSlider(this, 100, 370, _onScalerChanged)).setSize(264, 20);
            scaler.value = 25;
            mic = Microphone.getMicrophone();
            mic.rate = 44;
            mic.setSilenceLevel(0);
            mic.setLoopBack();
            mic.addEventListener("sampleData", _in);
        }
        
        private function _onScalerChanged(e:Event) : void { 
            scale = scaler.value;
        }
        
        private function _in(e:SampleDataEvent):void {
            for (e.data.position=0; e.data.bytesAvailable>0;) {
                _execFFT(e.data);
                _updateImage();
            }
        }
        
        private function _updateImage() : void {
            voicePrint.scroll(-4, 0);
            for (var i:int=0; i < 256; i++) {
                voicePrint.setPixel(461, 255-i, grad[frm[3][i]]);
                voicePrint.setPixel(462, 255-i, grad[frm[2][i]]);
                voicePrint.setPixel(463, 255-i, grad[frm[1][i]]);
                voicePrint.setPixel(464, 255-i, grad[frm[0][i]]);
            }
        }

        private var src:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(4);
        private var dst:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(4);
        private var amp:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(4);
        private var frm:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(4);
        private var hamm:Vector.<Number> = new Vector.<Number>(2048);
        private var fft:FFT = new FFT(2048);
        private var grad:Array, scale:Number;
        private function _initFFT() : void {
            var i:int;
            for (i=0; i<4; i++) {
                src[i] = new Vector.<Number>(2048);
                dst[i] = new Vector.<Number>(2048);
                amp[i] = new Vector.<Number>(1024);
                frm[i] = new Vector.<int>(256);
            }
            for (i=0; i<2048; i++) hamm[i]=0.54-Math.cos(i*0.00306796)*0.46;
            ColorLerp.mode = "hsv";
            grad = ColorLerp.gradient(0x000040, 0xff0000, 256);
            scale = 25;
        }
        private function _execFFT(data:ByteArray) : void {
            var index:int, i:int, j:int, n:Number, 
                f:Vector.<int>, a:Vector.<Number>,
                s0:Vector.<Number> = src[0],
                s1:Vector.<Number> = src[1],
                s2:Vector.<Number> = src[2],
                s3:Vector.<Number> = src[3];
            for (index=3; index>=0; --index) {
                for (i=0; i<512; i++) {
                    n = data.readFloat();
                    j = i;     s0[j] = n * hamm[j];
                    j += 512;  s1[j] = n * hamm[j];
                    j += 512;  s2[j] = n * hamm[j];
                    j += 512;  s3[j] = n * hamm[j];
                }
                a = amp[index];
                f = frm[index];
                fft.setData(s3).calcDCT().getMagnitude(a)
                for (i=0; i<256; i++) { // from 86Hz to 5.6kHz
                    n = Math.log(a[i+4]*scale);
                    f[i] = int(((n<0) ? 0 : (n>1) ? 1 : n) * 255);
                }
                s3 = s2;
                s2 = s1;
                s1 = s0;
                s0 = src[index];
            }
        }
    }   
}

