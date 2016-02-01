// forked from nemu90kWw's なんとかディウスっぽい蟹さん forked from: なんとかディウスっぽい背景
// forked from gyuque's なんとかディウスっぽい背景

// 左右キーとスペースで操作できます
package
{
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.ui.*;
        import flash.media.Sound;

	[SWF(width="320", height="240", backgroundColor="0x000000", frameRate="30")]
	public class Nemesis extends Sprite
	{
		public static const W:int = 320;
		public static const H:int = 240;

		private var mBGen:MountainGen = new MountainGen(80);
		private var mTGen:MountainGen = new MountainGen(80, 1);
		
		private var mScreenBmp:Bitmap;
		private var mScreen:BitmapData = new BitmapData(W, H, false, 0);
		private var mBGScreen:BitmapData = new BitmapData(W, H, true, 0);
		
		private var mStarbg:StarBG = new StarBG(W, H, 50);
		private var mKani:Kani;
		private var legs:Array = new Array();
		
		private var count:int = 0;
		
		function Nemesis()
		{
			mScreenBmp = new Bitmap(mScreen);
			addChild(mScreenBmp);
			
			mBGen.step();
			mTGen.step();
			for(var i:int = 0; i < W; i++)
			{
				mBGen.step();
				mTGen.step();
				mBGen.draw(mBGScreen, i, 160);
				mTGen.draw(mBGScreen, i, 0, false);
			}
			
			legs.push(new Leg(-80, 1));
			legs.push(new Leg(  0, 1));
			legs.push(new Leg( 80, 1));
			legs.push(new Leg(-80, -1));
			legs.push(new Leg(  0, -1));
			legs.push(new Leg( 80, -1));
			
			mKani = new Kani(legs);
			
			addEventListener(Event.ENTER_FRAME, tick);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, Key.onKeyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, Key.onKeyUpHandler);

                        _initializeSound();
		}
		
		private function tick(e:Event):void
		{
			var leg:Leg;
			
			mStarbg.main();
			mKani.main();
			
			if(count % 2 == 0) {scroll(1);}
			count++;
			
			//描画
			mScreen.fillRect(mScreen.rect, 0);
			mStarbg.draw(mScreen);
			
			var matrix:Matrix = new Matrix();
			for each(leg in legs)
			{
				matrix.translate(leg.x, leg.y);
				mScreen.draw(leg.sprite, matrix);
				matrix.identity();
			}
			matrix.translate(mKani.x, mKani.y);
			mScreen.draw(mKani, matrix);
			
			mScreen.copyPixels(mBGScreen, mScreen.rect, new Point(0, 0));
			
			//当たり判定
			for each(leg in legs) {
				leg.hitflag = mBGScreen.getPixel32(leg.x, leg.y) != 0x00000000;
			}
		}
		
		public function scroll(vx:int):void
		{
			mBGScreen.scroll(-vx, 0);
			mBGScreen.fillRect(new Rectangle(W-vx, 0, vx, H), 0);
			
			var i:int;
			mBGen.step();
			mTGen.step();
			
			for (i = 0; i < vx; i++)
			{
				mBGen.step();
				mTGen.step();
				mBGen.draw(mBGScreen, W-vx+i, 160);
				mTGen.draw(mBGScreen, W-vx+i, 0, false);
			}
			
			mKani.x -= vx;
			for each(var leg:Leg in legs) {leg.x -= vx;}
		}


        private var _sound:Sound;
        private var _module:TinySiOPM;
        private var _sequencer:Sequencer;
        
        private function _initializeSound() : void {
            var A:String  = "$v10@11s32w24o4l4[12ccrc2cc|cr2]r6v12@0[4ccrc2cccr6]";
            var B:String  = "$l8[12rc|rc4]c1c1[5c2][7rc]c1c1[7c2]";
            var Bm:String = "v6@0s0o6k64@o1"+B;
            var Bc:String = "v2@0s12o5w12@i4"+B;
            var Bn:String = "v12@3s24o0k6"+B;
            var C:String  = "$v6@3s48o0l2[168d] [4rdrds6d4s48rdrds6d4s48rddd]";
            var Sa:String = "[4c>cfcgc<c>cfcgc<c>c<]";
            var Sb:String = "[4g>g<c>g<d>g<g>g<c>g<d>g<g>g<]";
            var S1:String = "$p2v6@1s32l2o6k6["+Sa+"k-26]k6"+Sa+"o5s24[4l4gga+g2bl2g<c>g<c+>g<d>f]";
            var S2:String = "$p6v6@1s32l2o5k3["+Sb+"k-29]k3"+Sb+"o4s16[4l4gga+g2bl2g<c>g<c+>g<d>f]";
            var S3:String = "$p3v4@1s24l2o5k3["+Sa+"k-29]k3"+Sa+"o4s24[4l4gga+g2bl2g<c>g<c+>g<d>f]";
            var S4:String = "$p5v4@1s24l2o4k0["+Sb+"k-32]k0"+Sb+"o3s16[4l4gga+g2bl2g<c>g<c+>g<d>f]";
            var M1:String = "$p5v4@1s4o7k4[[4c4>a+24<]k-28]k4[4c4>a+24<] v7@1s20o6 [3g30f2]g20a+2g10";
            var M2:String = "$p3v12@2s4o6k4[[4c4>a+24<]k-28]k4[4c4>a+24<]v12@2s20o5[3g30f2]g20a+2g10";
            var M3:String = "$v7@2s4o6k2[[4g4f24]k-30]k2[4g4f24] v7@2s20o4 [3d30c2]d20f2d10";
            var Mn:String = "$v3@3s4o0k8[12c4c24] v12k1s20  [3c30c2]c20c2c10";
            _module = new TinySiOPM(2048, 1024, _onSoundFrame);
            _sequencer = new Sequencer(3, [A,Bm,Bc,Bn,C,S1,S2,S3,S4,M1,M2,M3,Mn]);
            _sound = new Sound();
            _sound.addEventListener("sampleData", _onStream);
            _sound.play();
        }
        
        private function _onSoundFrame() : void {
            if (_sequencer.onSoundFrame()) {
            }
        }
        
        private function _onStream(e:SampleDataEvent) : void {
            var moduleOut:Vector.<Number> = _module.render();
            for (var i:int = 0; i<4096; i++) {
                e.data.writeFloat(moduleOut[i]);
            }
        }
    }
}

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.ui.*;

class Kani extends Sprite
{
	public var body:Body = new Body();
	public var legs:Array = new Array();
	
	public var auto:Boolean;
	public var dir:String = "none";
	public var timer:int;
	public var dance:int;
	
	function Kani(legs:Array)
	{
		x = 200;
		y = 120;
		
		auto = false;
		timer = 100;
		
		this.legs = legs;
		for each(var leg:Leg in legs)
		{
			leg.parent = this;
			leg.x = x+leg.offset - 20+Math.random()*40;
			leg.y = 120 + 100*leg.invert;
		}
		
		addChild(body);
	}
	
	public function main():void
	{
		var leg:Leg;
		
		if(auto == false)
		{
			if(Key.isLeft == true) {dir = "left"; timer = 90;}
			else if(Key.isRight == true) {dir = "right"; timer = 90;}
			else {dir = "none";}
			
			if(Key.isSpace == true && dance == 0) {dance = 20; timer = 90;}
			
			timer--;
			if(timer == 0) {auto = true;}
		}
		if(auto == true)
		{
			if(timer == 0)
			{
				if(dir == "none")
				{
					if(x < 160) {dir = "right";}
					else {dir = "left";}
				}
				else {
					if(x < 50 && dir != "right") {
						timer = 60;
					}
					if(x > 300 && dir != "left") {
						timer = 60;
					}
				}
			}
			else {
				dir = "none";
				if(timer == 40) {
					dance = 20;
				}
				timer--;
			}
			
			if(Key.isLeft == true || Key.isRight == true)
			{
				auto = false;
				timer = 90;
			}
		}
		
		if(dir == "left") {x -= 2;}
		if(dir == "right") {x += 2;}
		
		if(dir != "none") {
			for each(leg in legs) {
				leg.move(dir);
			}
		}
		
		if(dance > 0)
		{
			if(dance > 15) {body.x = 2;}
			else if(dance > 10) {body.x = 0;}
			else if(dance > 5) {body.x = -2;}
			else {body.x = 0;}
			dance--;
		}
		
		graphics.clear();
		for each(leg in legs)
		{
			graphics.lineStyle(6, 0xFF80FF);
			graphics.moveTo(leg.offset/8, 10*leg.invert);
			graphics.lineTo((leg.x-x), (leg.y-y)-70*leg.invert);
			graphics.endFill();
		}
	}
}

class Body extends Sprite
{
	function Body()
	{
		graphics.beginFill(0xC060C0);
		graphics.lineStyle(2, 0xFF80FF);
		graphics.drawRect(-15, -15, 30, 30);
		graphics.endFill();
	}
}

class Leg
{
	public var parent:Kani;
	public var sprite:Sprite;
	
	public var x:Number;
	public var y:Number;
	public var offset:Number;
	public var invert:int;
	public var hitflag:Boolean;
	public var moveflag:Boolean;
	public var gear:int;
	
	function Leg(offset:Number, invert:int)
	{
		this.offset = offset;
		this.invert = invert;
		
		sprite = new Sprite();
		
		sprite.graphics.beginFill(0xC060C0);
		sprite.graphics.lineStyle(0, 0xFF80FF);
		sprite.graphics.lineTo(-5, -40*invert);
		sprite.graphics.lineTo(-5, -60*invert);
		sprite.graphics.lineTo(-2, -70*invert);
		sprite.graphics.lineTo(2, -70*invert);
		sprite.graphics.lineTo(5, -60*invert);
		sprite.graphics.lineTo(5, -40*invert);
		sprite.graphics.lineTo(0, 0);
		sprite.graphics.endFill();
	}
	
	public function move(dir:String):void
	{
		var threshold_l:Number = parent.x+offset + 30;
		var threshold_r:Number = parent.x+offset - 30;
		
		if(moveflag == false) {
			if(threshold_l < x || threshold_r > x)
			{
				moveflag = true;
				gear = -12;
			}
			if(threshold_r > x)
			{
				moveflag = true;
				gear = 12;
			}
		}
		
		if(moveflag == true)
		{
			if(dir == "left" && threshold_l-50 < x)
			{
				x -= 4;
				
				if(gear < 0) {
					y -= 4 * invert;
				}
				else {
					y += 4 * invert;
					if(hitflag == true) {
						moveflag = false;
					}
					if(y < 0 || y > 240) {
						gear = -12;
					}
				}
				gear++;
			}
			else if(dir == "right" && threshold_r+50 > x)
			{
				x += 4;
				
				if(gear > 0) {
					y -= 4 * invert;
				}
				else {
					y += 4 * invert;
					if(hitflag == true) {
						moveflag = false;
					}
					if(y < 0 || y > 240) {
						gear = 12;
					}
				}
				gear--;
			}
		}
	}
}

class StarBG
{
	private var mWidth:int;
	private var mHeight:int;

	private var mStars:Array;
	private var mN:int;
	
	private var mCount:int = 0;

	function StarBG(w:int, h:int, n:int)
	{
		mWidth = w;
		mHeight = h;
		mN = n;

		mStars  = new Array(n);
		for (var i:int = 0;i < n;i++) {
			mStars[i] = {
				x : Math.random()*w, y : Math.random()*h, speed : -Math.random()*1.5-0.5,
				color : ((Math.random()*0xC0+0x40)<<8)+((Math.random()*0xC0+0x40)<<16)+(Math.random()*0xC0+0x40),
				blink : Math.floor(Math.random())*40+20
			};
		}
	}

	public function main():void
	{
		var n:int = mN;

		for each(var star:Object in mStars)
		{
			star.x += star.speed;
			
			if(star.x < 0)
			{
				star.x += mWidth;
				star.y = Math.random()*mHeight;
				star.speed = -Math.random()*1.5-0.5;
			}
		}
		mCount++;
	}

	public function draw(b:BitmapData):void
	{
		for each(var star:Object in mStars)
		{
			if((mCount % star.blink) == 1) {b.setPixel(star.x, star.y, 0xFFFFFF);}
			else {b.setPixel(star.x, star.y, star.color);}
		}
	}
}

class Key
{
	public static var isLeft:Boolean = false;
	public static var isRight:Boolean = false;
	public static var isSpace:Boolean = false;
	
	public static function onKeyDownHandler(e:KeyboardEvent):void
	{
		switch(e.keyCode) {
			case Keyboard.LEFT: Key.isLeft = true; break;
			case Keyboard.RIGHT: Key.isRight = true; break;
			case Keyboard.SPACE: Key.isSpace = true; break;
		}
	}
	public static function onKeyUpHandler(e:KeyboardEvent):void
	{
		switch(e.keyCode) {
			case Keyboard.LEFT: Key.isLeft = false; break;
			case Keyboard.RIGHT: Key.isRight = false; break;
			case Keyboard.SPACE: Key.isSpace = false; break;
		}
	}
}

class MountainGen
{
	private var mPrevBuffer:Array;
	private var mHeight:int;
	private var mCount:int = 100;

	private var tmpBuffer:Array;
	private var mGenFunc:Function;
	function MountainGen(h:int, generator:int = 0)
	{
		mHeight = h;
		mGenFunc = generator ? genWav2 : genWav;
		mPrevBuffer = new Array(h);
		tmpBuffer   = new Array(h);
	}

	public function draw(b:BitmapData, x:int, y:int, rev:Boolean = true):void
	{
		var i:int;
		for (i = 0;i < mHeight;i++) {
			if (tmpBuffer[i]) {
				var c:int = tmpBuffer[i];
				b.setPixel32(x, rev ? (y+mHeight-i) : (y+i), 0xff000000 | (c/3+11) | ((c/5 + 170)<<16) | ((c/2+60) << 8));
			}
		}
	}

	public function step():void
	{
		var t:Number = Number(mCount) * 0.02;
		var h:int = mGenFunc(t) * mHeight;
		var i:int, k:int, m:int;

		for (i = 0;i < mHeight;i++) {
			mPrevBuffer[i] = tmpBuffer[i];
		}

		for (i = 0;i < mHeight;i++) {
			tmpBuffer[i] = (i < h) ? (Math.random()*80 + 80) : 0;

			if (tmpBuffer[i]) {
				if (mPrevBuffer[i])
					tmpBuffer[i] = (tmpBuffer[i] + mPrevBuffer[i]*7)/8;

				if (mPrevBuffer[i] == 0 || i == (h-1)) {
					m = 50;
					for (k = i;k >= 0 && m > 0;k--, m-=4) {
						if (m > 33) m--;
						tmpBuffer[k] += m;

						m += Math.random()*7;
					}
				}

				if (mPrevBuffer[i+1] && i == (h-1)) {
					m = -48;
					for (k = i;k >= 0 && m < 0;k--, m++) {
						tmpBuffer[k] += m;
						if (tmpBuffer[k]<1) tmpBuffer[k] = 1;
					}
				}

		   }
		}

	   for (i = 0;i < mHeight;i++)
			tmpBuffer[i] = (tmpBuffer[i] < 0) ? 0 : (tmpBuffer[i] > 255) ? 255 : tmpBuffer[i];

		mCount++;
	}

	private static function genWav(t:Number, nest:int = 0):Number
	{
		var v:Number = Math.sin(t);
		v += Math.cos(t*3) * 0.1;
		v += Math.cos(0.1 + t*10) * 0.02;
		v *= Math.cos(t*0.1);

		if (nest < 5)
			v += genWav(t+1, ++nest);

		v = v*0.2 + 0.3;

		return (v<0) ? 0 : (v>1) ? 1 : v;
	}

	private static function genWav2(t:Number, nest:int = 0):Number
	{
		var v:Number = Math.sin(t);
		v += Math.cos(t*3) * 0.1;
		v += Math.cos(0.1 + t*9) * 0.02;
		v *= Math.cos(0.2 + t*0.15);

		if (nest < 5)
			v += genWav2(t+1, ++nest);

		v = v*0.2 + 0.2;

		return (v<0) ? 0 : (v>1) ? 1 : v;
	}
}


// MML Sequencer
//   http://wonderfl.kayac.com/user/keim_at_Si
//--------------------------------------------------
class Sequencer {
    private var _tracks:Array, _count:int=Track.speed+1;
    function Sequencer(speed:int, mmls:Array) { Track.speed=speed; mml=mmls; }
    public function onSoundFrame() : Boolean {
        if (++_count == Track.speed) {
            for each (var tr:Track in _tracks) tr.execute();
            _count = 0;
            return true;
        }
        return false;
    }
    public function set mml(list:Array) : void {
        _tracks = [];
        for each (var seq:String in list) _tracks.push(new Track(seq));
        _count = 0;
    }
}

class Track {
    static public var codeA:int="a".charCodeAt(), nt:Array=[9,11,0,2,4,5,7], speed:int=3;
    public var oct:int, len:int, tl:int, dt:int, cnt:int, seq:String, sgn:int, stac:Array, osc:Osc;
    private var _rex:RegExp=/(@i|@o|[a-gkloprsvw<>[|\]$@])([#+])?(-?\d+)?/g;
    function Track(seq:String) {
        osc = (new Osc()).reset().activate(false);
        reset(seq);
    }
    public function reset(seq_:String) : void {
        seq=seq_; oct=5; len=4; tl=256; dt=0; cnt=0; sgn=0; _rex.lastIndex=0; stac=[];
    }
    public function execute() : void {
        if (--cnt <= 0) {
            for (var i:int=0; i<100; i++) {
                var res:* = _rex.exec(seq);
                if (!res) {
                    if (sgn) { _rex.lastIndex = sgn; continue; }
                    else     { cnt = int.MAX_VALUE; break; }
                }
                var cmd:int = res[1].charCodeAt();
                if (cmd>=codeA && cmd<=codeA+6) {
                    cnt = (res[3]) ? int(res[3]) : len;
                    osc.len = cnt * speed;
                    osc.pt = ((nt[cmd-codeA]+oct*12+((res[2])?1:0))<<4) + dt;
                    osc.tl = tl;
                    break;
                } else if (res[1] == 'r') {
                    cnt = (res[3]) ? int(res[3]) : len;
                    break;
                } else {
                    switch(res[1]){
                    case 'k': dt  = int(res[3]); break;
                    case 'l': len = int(res[3]); break;
                    case 'o': oct = int(res[3]); break;
                    case 'v': tl  = TinySiOPM.log(int(res[3])*0.0625); break;
                    case '<': oct++; break;
                    case '>': oct--; break;
                    case '@':  osc.ws = int(res[3]);    break;
                    case 's':  osc.dr = int(res[3])<<2; break;
                    case 'w':  osc.sw = -int(res[3]);   break;
                    case 'p':  osc.pan = (int(res[3])<<4)-64; break;
                    case '@i': osc.mod = int(res[3]);   break;
                    case '@o': osc.out = int(res[3]);   break;
                    case '$': sgn = _rex.lastIndex; break;
                    case '[': stac.unshift({p:_rex.lastIndex,c:((res[3])?int(res[3]):2),j:0}); break;
                    case '|': if (stac[0].c == 1) { _rex.lastIndex = stac[0].j; stac.shift(); } break;
                    case ']': 
                        stac[0].j = _rex.lastIndex;
                        if (--stac[0].c == 0) stac.shift();
                        else _rex.lastIndex = stac[0].p;
                        break;
                    }
                }
            }
        }
    }
}

class TinySiOPM {
    private var _output:Vector.<Number>, _zero:Vector.<int>, _pipe:Vector.<int>;
    private var _pitchTable:Vector.<int> = new Vector.<int>(2048, true);
    private var _logTable:Vector.<int> = new Vector.<int>(6144, true);
    private var _panTable:Vector.<Number> = new Vector.<Number>(129, true);
    private var _bufferSize:int, _callbackFrams:int, _onSoundFrame:Function;
    
    // Pass the buffer size and the function calls in each frame.
    function TinySiOPM(bufferSize:int=2048, callbackFrams:int=1024, onSoundFrame:Function=null) {
        var i:int, j:int, p:Number, v:Number, t:Vector.<int>, ft:Array=[0,1,2,3,4,5,6,7,7,6,5,4,3,2,1,0];
        for (i=0, p=0; i<192; i++, p+=0.00520833333)                            // create pitchTable[128*16]
            for(v=Math.pow(2, p)*12441.464342886, j=i; j<2048; v*=2, j+=192) _pitchTable[j] = int(v);
        for (i=0; i<32; i++) _pitchTable[i] = (i+1)<<6;                         // [0:31] for white noize
        for (i=0, p=0.0078125; i<256; i+=2, p+=0.0078125)                       // create logTable[12*256*2]
            for(v=Math.pow(2, 13-p), j=i; j<3328; v*=0.5, j+=256) _logTable[j+1] = -(_logTable[j]=int(v));
        for (i=3328; i<6144; i++) _logTable[i] = 0;                             // [3328:6144] is 0-fill area
        for (i=0, p=0; i<129; i++, p+=0.01217671571) _panTable[i]=Math.sin(p)*0.5;  // pan table;
        for (t=Osc.createTable(10), i=0, p=0; i<1024; i++, p+=0.00613592315) t[i] = log(Math.sin(p)); // sin=0
        for (t=Osc.createTable(10), i=0, p=0.75; i<1024; i++, p-=0.00146484375) t[i] = log(p);        // saw=1
        for (t=Osc.createTable(5),    i=0; i<16; i++) t[i+16] = (t[i] = log(ft[i]*0.0625)) + 1;       // famtri=2
        for (t=Osc.createTable(15), i=0; i<32768; i++) t[i] = log(Math.random()-0.5);                 // wnoize=3
        for (i=0; i<8; i++) for (t=Osc.createTable(4), j=0; j<16; j++) t[j] = (j<=i) ? 192 : 193;     // pulse=4-11
        _zero = new Vector.<int>(bufferSize, true);                             // allocate zero buffer
        _pipe = new Vector.<int>(bufferSize, true);                             // allocate fm pipe buffer
        _output = new Vector.<Number>(bufferSize*2, true);                      // allocate stereo out
        _bufferSize = bufferSize;
        _callbackFrams = callbackFrams; 
        _onSoundFrame = onSoundFrame;                                           // set parameters
        for (i=0; i<bufferSize; i++) { _pipe[i]=_zero[i]=0; }                   // clear buffers
    }
    
    // calculate index of logTable
    static public function log(n:Number) : int {
        return (n<0) ? ((n<-0.00390625) ? (((int(Math.log(-n) * -184.66496523 + 0.5) + 1) << 1) + 1) : 2047)
                     : ((n> 0.00390625) ? (( int(Math.log( n) * -184.66496523 + 0.5) + 1) << 1)      : 2046);
    }
    
    // Returns stereo output as Vector.<Number>(bufferSize*2).
    public function render() : Vector.<Number> {
        var i:int, j:int, ph:int, dph:int, mod:int, sh:int, tl:int, lout:int, v:int, imax:int, 
            osc:Osc, tm:Osc, l:Number, r:Number, wv:Vector.<int>, fm:Vector.<int>, base:Vector.<int>, 
            out:Vector.<int>=_pipe, lt:Vector.<int>=_logTable, stereoOut:Vector.<Number> = _output;
        imax = _bufferSize<<1;
        for (i=0; i<imax; i++) stereoOut[i] = 0;
        for (imax=_callbackFrams; imax<=_bufferSize; imax+=_callbackFrams) {
            if (_onSoundFrame!=null) _onSoundFrame();
            tm = Osc._tm;
            for (osc=tm.n; osc!=tm; osc=osc.update()) {
                dph=_pitchTable[osc.pt]; ph=osc.ph; mod=osc.mod+10; sh=osc.sh; tl=osc.tl; wv=osc.wv;
                fm=(osc.mod==0)?_zero:_pipe; base=(osc.out!=2)?_zero:_pipe;
                for (i = imax-_callbackFrams; i < imax; i++) {
                    v = ((ph + (fm[i] << mod))& 0x3ffffff) >> sh;
                    lout = wv[v] + tl;
                    out[i] = lt[lout] + base[i];
                    ph = (ph + dph) & 0x3ffffff;
                }
                osc.ph = ph;
                if (osc.out==0) {
                    l = _panTable[64-osc.pan] * 0.0001220703125;
                    r = _panTable[64+osc.pan] * 0.0001220703125;
                    for (i=imax-_callbackFrams, j=i*2; i<imax; i++) {
                        stereoOut[j] += out[i]*l; j++;
                        stereoOut[j] += out[i]*r; j++;
                    }
                }
            }
        }
        return stereoOut;
    }
    
    // note on
    public function noteOn(pitch:int, length:int=0, vol:Number=0.5, wave:int=0, decay:int=6, sweep:int=0, pan:int=0) : Osc {
        var osc:Osc = Osc.alloc().reset();
        osc.pt = pitch;
        osc.len = length;
        osc.tl = log(vol);
        osc.ws = wave;
        osc.dr = decay<<2;
        osc.sw = sweep; 
        osc.pan = pan;
        return osc.activate(true);
    }
}

class Osc {
    // create new wave table and you can refer the table by '@' command.
    static public function createTable(b:int) : Vector.<int> {
        _w.push(new Vector.<int>(1<<b,true)); _s.push(26-b);
        return _w[_w.length-1];
    }
    static public var _w:Array=[], _s:Array=[], _fl:Osc=new Osc(), _tm:Osc=new Osc();
    static public function alloc():Osc{ if(_fl.p==_fl)return new Osc();var r:Osc=_fl.p;_fl.p=r.p;r.p.n=_fl;return r; }
    public function into(x:Osc):Osc{ p=x.p;n=x;p.n=this;n.p=this;return this; }
    public var p:Osc, n:Osc, fl:Osc, pt:int, len:int, ph:int;
    public var tl:int, sw:int, dr:int, wv:Vector.<int>, sh:int, mod:int, out:int, pan:int;
    public function set ws(t:int) : void { wv=_w[t]; sh=_s[t]; }
    public function Osc() { p = n = this; }
    public function update() : Osc { tl+=dr; pt+=sw; pt&=2047; return (--len==0||tl>3328) ? (inactivate().n) : n; }
    public function reset() : Osc { ph=0; pt=0; len=0; tl=3328; sw=0; dr=24; pan=0; ws=0; mod=0; out=0; return this; }
    public function activate(autoFree:Boolean=false) : Osc { into(_tm); fl=(autoFree)?_fl:null; return this; }
    public function inactivate() : Osc { tl=3328; if(!fl)return this; var r:Osc=p; p.n=n; n.p=p; into(fl); return r; }
    public function isActive() : Boolean { return (tl<3328); }
}

