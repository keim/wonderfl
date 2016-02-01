package {
    import flash.display.*;
    import flash.events.*;
    import org.si.sion.*;
    import org.si.sion.events.*;

    public class main extends Sprite {
        private const BadAppleURL :String = "http://assets.wonderfl.net/images/related_images/a/ad/ad5f/ad5f22e7e851e5717d5481acdb9e2951fd41eb24";//"badapple.png";
        private const BadAAppleURL:String = "http://assets.wonderfl.net/images/related_images/3/37/37f8/37f81cf7ee6e2a64feb8961e0b089592bda65aeb";//"badaapple.png";
        
        private var shadowMovie:ShadowMovie = new ShadowMovie();
        private var lcd:LCDRender = new LCDRender(1, 0xb0c0b0, 0xb0b0b0, 0x000000, 0.4);
        private var driver:SiONDriver = new SiONDriver();
        private var konamiCommand:CommandDetector;
        private var pause:Boolean = true;
        private var title:String = "BAD APPLE !!";
        
        function main() {
            graphics.beginFill(0);
            graphics.drawRect(0,0,465,465);
            graphics.endFill();
            stage.frameRate = 30;
            lcd.x = lcd.y = 32;
            addChild(lcd);
            lcd.print(60,80,  "SHOUJO");
            lcd.print(48,88,"KITO-CHU");
            lcd.render();
            addEventListener(Event.ENTER_FRAME, init);
        }
        
        public function init(e:Event) : void {
            konamiCommand = new CommandDetector(stage,[38,38,40,40,37,39,37,39,66,65]);
            konamiCommand.addEventListener(KeyboardEvent.KEY_UP, function(e:Event) : void {
                e.target.removeEventListener(e.type, arguments.callee);
                driver.addEventListener(SiONEvent.STREAM_START, start);
                driver.play(shadowMovie.sionMML);
            });
            konamiCommand.addEventListener(Event.COMPLETE, function(e:Event) : void {
                e.target.removeEventListener(e.type, arguments.callee);
                driver.play(konamiMML);
                shadowMovie.addEventListener(Event.COMPLETE, setup);
                shadowMovie.decode(BadAAppleURL);
                title = "BAD AAPPLE !"
                lcd.cls();
                lcd.print(0,88,"WAIT A MOMENT...");
                lcd.render();
            });
            e.target.removeEventListener(e.type, arguments.callee);
            shadowMovie.addEventListener(Event.COMPLETE, setup);
            shadowMovie.decode(BadAppleURL);
            addEventListener(Event.ENTER_FRAME, draw);
        }
        
        public function setup(e:Event) : void {
            e.target.removeEventListener(e.type, arguments.callee);
            lcd.cls();
            lcd.print(0,32,"- " + title + " -");
            lcd.print(0,56,"HIT KEY TO START");
            lcd.box(0,11,96,85,255,"difference");
        }
        
        public function start(e:SiONEvent) : void {
            pause = false;
            shadowMovie.resetPosition(-240);
            lcd.print(1,2, title);
            lcd.print(36,86,"FRAME:0000");
            lcd.box(0,0,96,48,255,"difference");
        }
        
        public function draw(e:Event) : void {
            if (!pause) {
                lcd.gprint(48, 48, shadowMovie.updateImage(false));
                lcd.box(72,86,96,96,0);
                lcd.print(72, 86, ("000"+shadowMovie.currentFrame.toString()).substr(-4,4));
            }
            lcd.render();
        }
    }
}
import flash.system.LoaderContext;

import flash.net.*;
import flash.geom.*;
import flash.events.*;
import flash.filters.*;
import flash.display.*;
import flash.utils.*;

class ShadowMovie extends EventDispatcher {
    public var image:BitmapData;
    public var sionMML:String;
    public var frameCount:int, frameRate:int, currentFrame:int;
    public var compressed:ByteArray = new ByteArray();
    private var _startTime:int, _msPerFrame:Number;
    
    function ShadowMovie() {}
    
    public function decode(url:String) : void {
        var loader:Loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
            var i:int, mmlBA:ByteArray = new ByteArray();
            var pixels:BitmapData = Bitmap(e.target.content).bitmapData;
            var width:int = _readShort(4), height:int = _readShort(6);
            var datasize:int = _readShort(8)+(_readShort(10)<<16), mmlsize:int = _readShort(12);
            compressed.clear();
            for (i=0; i<datasize; i++) compressed.writeByte(pixels.getPixel(i%465, i/465) & 255);
            for (; i<datasize+mmlsize; i++) mmlBA.writeByte(pixels.getPixel(i%465, i/465) & 255);
            compressed.uncompress();
            trace(compressed.length);
            mmlBA.position = 0;
            sionMML = mmlBA.readUTF();
            frameRate = _readShort(0);
            frameCount = _readShort(2);
            _msPerFrame = 1000 / frameRate;
            image = new BitmapData(width, height, false, 0);
            resetPosition();
            dispatchEvent(e.clone());
            function _readShort(x:int) : int { return (pixels.getPixel(x,464)&255) + ((pixels.getPixel(x+1,464)&255)<<8); }
        });
        loader.load(new URLRequest(url), new LoaderContext(true));
    }

    public function resetPosition(delay:int=0) : void {
        compressed.position = 0;
        currentFrame = 0;
        _startTime = getTimer() + delay;
    }
    
    public function updateImage(positive:Boolean=true) : BitmapData {
        while (currentFrame * _msPerFrame < (getTimer()-_startTime)) {
            var len:int, height:int = image.height, imaxmax:int = height * image.width, 
                imax:int = 0, i:int = 0, x:int = 0, y:int = 0, 
                color:uint = (positive) ? 0 : 0xffffff;
            while (compressed.bytesAvailable > 0 && imax < imaxmax) {
                len = compressed.readByte();
                if (len & 128) len = (len & 127) | (compressed.readByte()<<7);
                imax += len;
                for (; i<imax; i++) {
                    image.setPixel(x, y, color);
                    if (++y == height) {
                        x++;
                        y = 0;
                    }
                }
                color = (color) ? 0x000000 : 0xffffff;
            }
            currentFrame++;
        }
        return image;
    }
}

class LCDRender extends Bitmap {
    public var data:BitmapData = new BitmapData(96, 96, false, 0);
    public var charMap:Vector.<BitmapData> = Vector.<BitmapData>([
        hex2bmp("0000000000"), hex2bmp("00005f0000"), hex2bmp("0003000300"), hex2bmp("143e143e14"), //  !"#
        hex2bmp("242a7f2a12"), hex2bmp("4c2c106864"), hex2bmp("3649592650"), hex2bmp("0000030000"), // $%&'
        hex2bmp("001c224100"), hex2bmp("0041221c00"), hex2bmp("22143e1422"), hex2bmp("08083e0808"), // ()*+
        hex2bmp("0050300000"), hex2bmp("0808080808"), hex2bmp("0060600000"), hex2bmp("2010080402"), // ,-./
        hex2bmp("3e5149453e"), hex2bmp("00427f4000"), hex2bmp("4261514946"), hex2bmp("2241494936"), // 0123
        hex2bmp("3824227f20"), hex2bmp("4f49494931"), hex2bmp("3e49494932"), hex2bmp("0301710907"), // 4567
        hex2bmp("3649494936"), hex2bmp("264949493e"), hex2bmp("0036360000"), hex2bmp("0056360000"), // 89:;
        hex2bmp("0814224100"), hex2bmp("1414141414"), hex2bmp("0041221408"), hex2bmp("0201510906"), // <=>?
        hex2bmp("3e4159551e"), hex2bmp("7c2221227c"), hex2bmp("7f49494936"), hex2bmp("3e41414122"), // @ABC
        hex2bmp("7f4141423c"), hex2bmp("7f49494941"), hex2bmp("7f09090901"), hex2bmp("3e4149493a"), // DEFG
        hex2bmp("7f0808087f"), hex2bmp("00417f4100"), hex2bmp("2040413f01"), hex2bmp("7f08142241"), // HIJK
        hex2bmp("7f40404040"), hex2bmp("7f020c027f"), hex2bmp("7f0408107f"), hex2bmp("3e4141413e"), // LMNO
        hex2bmp("7f09090906"), hex2bmp("3e4151215e"), hex2bmp("7f09192946"), hex2bmp("2649494932"), // PQRS
        hex2bmp("01017f0101"), hex2bmp("3f4040403f"), hex2bmp("1f2040201f"), hex2bmp("1f601c601f"), // TUVW
        hex2bmp("6314081463"), hex2bmp("0708700807"), hex2bmp("6151494543"), hex2bmp("00007f4100"), // XYZ[
        hex2bmp("0204081020"), hex2bmp("00417f0000"), hex2bmp("0002010200"), hex2bmp("4040404040"), // \]^_
    ]);
    
    private var _screen:BitmapData = new BitmapData(384, 384, true, 0);
    private var _display:BitmapData = new BitmapData(400, 400, false, 0);
    private var _cls:BitmapData = new BitmapData(400, 400, false, 0);
    private var _matS2D:Matrix = new Matrix(1,0,0,1,8,8);
    private var _shadow:DropShadowFilter = new DropShadowFilter(4, 45, 0, 0.6, 6, 6);
    private var _residueMap:Vector.<Number> = new Vector.<Number>(9216, true);
    private var _toneFilter:uint, _dotColor:uint, _residue:Number;
    private var _dot:Rectangle = new Rectangle(0,0,3,3);
    private var _pt:Point = new Point();
    private var _shape:Shape = new Shape();
    
    static public function hex2bmp(hex:String, height:int=8, scale:int=1) : BitmapData {
        var i:int, pat:int,
            rect:Rectangle = new Rectangle(0, 0, scale, scale),
            bmp:BitmapData = new BitmapData((hex.length>>1)*scale, height, true, 0);
        for (i=0, rect.x=0; i<hex.length; i+=2, rect.x+=scale)
            for (rect.y=0, pat=parseInt(hex.substr(i, 2), 16); pat!=0; rect.y+=scale, pat>>=1) {
                bmp.fillRect(rect, (pat&1)<<31>>31);
            }
        return bmp;
    }
    
    function LCDRender(bit:int=2, backColor:uint = 0xb0c0b0, 
                      dot0Color:uint = 0xb0b0b0, dot1Color:uint = 0x000000, residue:Number = 0.4) {
        _toneFilter = (0xff00 >> bit) & 0xff;
        _dotColor = dot1Color;
        _cls.fillRect(_cls.rect, backColor);
        _residue = residue;
        for (_dot.x=8; _dot.x<392; _dot.x+=4)
            for (_dot.y=8; _dot.y<392; _dot.y+=4)
                _cls.fillRect(_dot, dot0Color);
        charMap.length = 96;
        for (var i:int=32; i<64; i++) charMap[i+32] = charMap[i];
        super(_display);
        x = 32;
        y = 32;
    }
    
    public function cls() : void {
        data.fillRect(data.rect, 0);
    }
    
    public function line(x0:int, y0:int, x1:int, y1:int, color:int=255, thick:Number=1, method:String=null) : void {
        _shape.graphics.clear();
        _shape.graphics.lineStyle(thick, color);
        _shape.graphics.moveTo(x0, y0);
        _shape.graphics.lineTo(x1, y1);
        data.draw(_shape, null, null, method);
    }

    public function box(x0:int, y0:int, x1:int, y1:int, color:int=255, method:String=null) : void {
        _shape.graphics.clear();
        _shape.graphics.beginFill(color);
        _shape.graphics.drawRect(x0, y0, x1-x0, y1-y0);
        _shape.graphics.endFill();
        data.draw(_shape, null, null, method);
    }

    public function gprint(x:int, y:int, bmp:BitmapData) : void {
        _pt.x = x - (bmp.width >> 1);
        _pt.y = y - (bmp.height >> 1);
        data.copyPixels(bmp, bmp.rect, _pt);
    }
        
    public function print(x:int, y:int, str:String) : void {
        _pt.x = x;
        _pt.y = y;
        var bmp:BitmapData;
        for (var i:int=0; i<str.length; i++, _pt.x+=6) {
            bmp = charMap[str.charCodeAt(i)-32];
            data.copyPixels(bmp, bmp.rect, _pt);
        }
    }
    
    public function render() : void {
        var x:int, y:int, gray:int, mask:uint, i:int;
        _screen.fillRect(_screen.rect, 0);
        for (i=0, _dot.y=0, y=0; y<96; _dot.y+=4, y++) {
            for (_dot.x=0, x=0; x<96; _dot.x+=4, x++, i++) {
                gray = ((data.getPixel(x, y) & _toneFilter)>>1) + int(_residueMap[i]);
                if (gray > 255) gray = 255;
                _residueMap[i] = gray * _residue;
                if (gray) _screen.fillRect(_dot, (gray<<24) | _dotColor);
            }
        }
        _screen.applyFilter(_screen, _screen.rect, _screen.rect.topLeft, _shadow);
        _display.copyPixels(_cls, _cls.rect, _cls.rect.topLeft);
        _display.draw(_screen, _matS2D);
    }
}

class CommandDetector extends EventDispatcher {
    private var index:int, command:Array, acceptance:Boolean=true;
    public function set accept(b:Boolean) : void {
        index = 0;
        acceptance = b;
    }
    function CommandDetector(stage:Stage, command:Array) {
        this.command = command;
        stage.addEventListener(KeyboardEvent.KEY_UP, _key);
    }
    private function _key(e:KeyboardEvent) : void {
        if (acceptance && command[index] == e.keyCode) {
            if (++index == command.length) dispatchEvent(new Event(Event.COMPLETE));
        } else {
            index = 0;
            dispatchEvent(e.clone());
        }
    }
}
var konamiMML:String = "#I=%8l16@8s27v6;#J=%0l16@7s25v8k4q1;#A=q8g.r.q1<d>g;t138;IA;Ik4A;Iq1b<dgbg;Jdgb<d>b;J>dgb<d>b;";

