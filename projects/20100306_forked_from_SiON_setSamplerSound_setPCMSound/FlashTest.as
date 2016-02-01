// forked from SOU1's SiON setSamplerSound/setPCMSound
// mp3をSiONで鳴らしたい程度が上手くいかないです
// 正直ASとか初めてなので自分のポカとしか思えないです
// setSamplerSoundとかの使い方間違えてる気がします
//
// -> Sound.loadは，Event.COMPLETE後でないと中身をとりだせません．
package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.media.*;
    import flash.net.*;
    import flash.events.Event;
	import org.si.sion.*;
    public class FlashTest extends Sprite {
        private var driver:SiONDriver = new SiONDriver();
        private var mml:SiONData;
        private var source:Sound = new Sound();
        private var pcmsound:SiONVoice = new SiONVoice(10);
    		
    		private function loadSound(url:String):void
    		{
            var tf :TextField = new TextField;
            tf.text=url;
            tf.autoSize = TextFieldAutoSize.LEFT;
            addChild( tf );
        }
        
        public function FlashTest() {
            // write as3 code here..
            var FlashVars:Object = loaderInfo.parameters;
            var url:String = FlashVars["url"];
            if (url){}else{url="http://s1224.com/music/sw/trancelike_state.mp3"}; 
            loadSound(url);
            var loadData:String = "http://s1224.com/music/sw/trancelike_state.mp3";
            source.load(new URLRequest(loadData));
            
	        // Event．COMPLETEでロード終了
            source.addEventListener(Event.COMPLETE, _onComplete);
            
            //mml = driver.compile("%10@0c");
            //driver.noteOn(60, pcmsound, 2);
            
            //mml = driver.compile("#EFFECT{delay120,40};t144@%3@5v32l16>[eb<g]5>[f+<d|a]6>[g<d|b]9<c>>g<d<d>d<d>[cg<e]5>g[da<|e]3[d>|da]3a[ea<e]5>[eb|<e]6>>[eb<g]5>[f+<d|a]6>[g<d|b]9<c>>g<d<d>d<d>[cg<e]5>g[da<|e]3[d>|da]3a[ea<e]5>[eb|<e]6;");
            mml = driver.compile("t150@v64,32@%3@5v32l16>[eb<g]5>[f+<d|a]6>[g<d|b]9<c>>g<d<d>d<d>[cg<e]5>g[da<|e]3[d>|da]3a[ea<e]5>[eb|<e]6>>[eb<g]5>[f+<d|a]6>[g<d|b]9<c>>g<d<d>d<d>[cg<e]5>g[da<|e]3[d>|da]3a[ea<e]5>[eb|<e]6;");
            //driver.setPCMSound(0,source,5,1048576);
            //mml = driver.compile("%7@0c");
            //driver.setSamplerSound(60,source,true,2,10000000);
            //mml = driver.compile("%10@0c");
            //driver.play();
            //driver.noteOn(60, pcmsound, 2);
            //driver.playSound(60,0,0);
            //source.play();
        }
        
        // source.load()は，Event．COMPLETEでロード終了後でないと
        // 中身を取り出せません．
        // あと，現バージョンでは4分の曲をサンプラー音として設定しようとすると
        // 正直に全部展開しようとするため，軽いブラクラになります．すいません．
        // (ver0.60では，mp3を展開せずに再生できるようになル予定です．)
        // また，sequenceOnでmmlを演奏する場合，effectorの設定が
        // 適用されないので，"#EFFECT"は，driver.play()に渡して下さい．
        private function _onComplete(e:Event) : void {
            driver.setSamplerSound(60,source,true,2,2000000);
            driver.play("#EFFECT1{delay120,40};");
            driver.sequenceOn(mml,null,0,0,4);
            driver.playSound(60,0,0,4);
        }
    }
}