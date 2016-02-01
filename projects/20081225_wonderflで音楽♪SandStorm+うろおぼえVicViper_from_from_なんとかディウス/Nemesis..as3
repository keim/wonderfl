// forked from gyuque's マルチポー forked from: ゲームっぽくしてみた
// forked from ton's ゲームっぽくしてみたforked from: なんとかディウスっぽい背景
// forked from gyuque's なんとかディウスっぽい背景
// ゲームっぽくしてみた
// 十字キーで移動
// スペースキーで弾発射
//   -> すいません．．Shiftに変更させてもらいました．keim_at_Si
// だれか当たり判定つけて＞＜

package
{
    import flash.display.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.ui.Keyboard;
    import flash.media.Sound;

    [SWF(width="320", height="240", backgroundColor="0x000000", frameRate="30")]  
    public class Nemesis extends Sprite
    {
        public static const W:int = 320;
        public static const H:int = 240;
        
        public static var KeyMapping:Object = {};

        private var mScroll:int = 0;
        private var mMyPos:Point;
        private var mBGen:MountainGen = new MountainGen(160);
        private var mTGen:MountainGen = new MountainGen(160, 1);
        private var mBBGen:MountainGen = new MountainGen(180, 1, true);

        private var mBBGScreen:BitmapData = new BitmapData(W, H, true, 0);
        private var mBBGScreenBmp:Bitmap;
        private var mBBGScreenBmp2:Bitmap;

        private var mBGScreen:BitmapData = new BitmapData(W, H, true, 0);
        private var mBGScreenBmp:Bitmap;
        private var mBGScreenBmp2:Bitmap;
        private var mStarbg:StarBG = new StarBG(W, H, 30);
        
        private var ship:Ship = new Ship(0xffffff, true);
        private var mKeyState:KeyState = new KeyState();

        function Nemesis()
        {
            mapKey(Keyboard.UP, KeyState.K_UP);
            mapKey(Keyboard.DOWN, KeyState.K_DOWN);
            mapKey(Keyboard.LEFT,KeyState.K_LEFT);
            mapKey(Keyboard.RIGHT, KeyState.K_RIGHT);
            mapKey(Keyboard.SHIFT, KeyState.K_TRG1);

            setupBG();
            setupShip();

            addEventListener(Event.ENTER_FRAME, tick);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownHandler);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpHandler);

            _initializeSound();
        }

        private function setupShip():void {
            ship.x = 40;
            ship.y = H / 2;

            var m1:Ship = new Multiple();
            ship.appendMultiple(m1);

            var m2:Ship = new Multiple();
            ship.appendMultiple(m2);

            ship.fillMoveBuffer();           

            addChild(m1);
            addChild(m2);
            addChild(ship);
        }

        private function setupBG():void {
            addChild(mStarbg);

            mBBGScreenBmp = new Bitmap(mBBGScreen);
            addChild(mBBGScreenBmp);
            mBBGScreenBmp2 = new Bitmap(mBBGScreen);
            addChild(mBBGScreenBmp2);

            mBGScreenBmp = new Bitmap(mBGScreen);
            addChild(mBGScreenBmp);
            mBGScreenBmp2 = new Bitmap(mBGScreen);
            addChild(mBGScreenBmp2);

            var i:int;
            mBGen.step();
            mTGen.step();
            mBBGen.step();
            for (i = 0;i < W;i++) {
                mBGen.step();
                mTGen.step();
                mBGen.draw(mBGScreen, i, 80);
                mTGen.draw(mBGScreen, i, 0, false);

                mBBGen.step();
                mBBGen.draw(mBBGScreen, i, 60);
            }
        }

        private static function mapKey(raw:uint, _to:uint):void {
            KeyMapping[raw] = _to;   
        }
        
        private var _clrrc:Rectangle = new Rectangle(0, 0, 1, H);
        private function tick(e:Event):void
        {
            var ox:int = mScroll % W;
            var ox2:int = int(mScroll/2) % W;
            _clrrc.x = ox;
            mBGScreen.fillRect(_clrrc, 0);

            mStarbg.tick();
            mBGen.step();
            mTGen.step();

            mStarbg.draw();
            mBGen.draw(mBGScreen, ox, 80);
            mTGen.draw(mBGScreen, ox, 0, false);

            if ((mScroll%2)==1) {
                _clrrc.x = ox2;
                mBBGScreen.fillRect(_clrrc, 0);
                mBBGen.step();
                mBBGen.draw(mBBGScreen, ox2, 60);
            }

            mBGScreenBmp.x = -ox;
            mBGScreenBmp2.x = W-ox;

            mBBGScreenBmp.x = -ox2;
            mBBGScreenBmp2.x = W-ox2;

            ship.moveByKeyState(mKeyState.state);
            ship.tick();
            ship.draw();

            mScroll++;
        }
        
        private function onKeyDownHandler(e:KeyboardEvent):void {
            if (KeyMapping.hasOwnProperty(e.keyCode))
                mKeyState.setState(KeyMapping[e.keyCode]);
        }
        private function onKeyUpHandler(e:KeyboardEvent):void {
            if (KeyMapping.hasOwnProperty(e.keyCode))
                mKeyState.delState(KeyMapping[e.keyCode]);
        }       


    // Sound
    //------------------------------------------------------------
        private function _initializeSound() : void {
            var A:String = "$v12@0s32w24o4l1[[4cr|crrc]cgfe[crcrrc]|[crcrrc]]v6<gggeeeccc>ggg";
            A+="v12[8crcrrccrcrcc] [v12[3crcrcccccrcc]|v6<gggeeeccc>ggg] crcrcccccrcc [4crcr3]";
            A+="[v12[5crcrrc]|[crcrrc]v8<ggeecc>]v8c<g>c<g>c<ggc>g<gc>g<ggec>gc";
            var B:String = "$v14@3s32o0k4l3[14rc]l1[12c]";
            B+="l3[14rc]rl1r[8c] [l3[6rc]|l1[12c]]rcrcl1[3r3ccc][6c] [l3[4rc]|[3rc]l1[6c]]l1[6c][3rc][12c]";
            var C1:String = "@3o0l1@o0v8s4 [d21v12s32cccv8s4d24]";
            var C2:String = "p6l2[8ee1e1e1eeee1]";
            var C3:String = "p4@o0@3o0k8v3s1[8c12]v6s6l6k0[4d] d48d24d24";
            var C4:String = "p4@i0@3o0k0v6s1r96l6s32[4c] r96";
            var Cm:String = "$"+C1+"@2v10s4o6k123@o1"+C2+C3;
            var Cc:String = "$"+"r96@0v3s20o5@i5"+C2+C4;
            var D:String = "$l1[8g2gggggggg<d>g]";
            D+="[16g2gg<d>g] <[c2[8c]gc>b2[8b]<f+>b|a2[8a]<e>a<[7d]c>b<c>ba<]<d+2[8d+]a+d+f2[8f]<c>f";
            D+="g2gg>g<gf2ff>f<fe2ee>e<edc>b<c>ba";
            D+="[g2[5g]<d>ggb<d>f+2[5f+]<d>f+f+a<d>e2[5e]beegb<c2cc>g<cd>a<d>a<cd>]";
            var Dl:String = "@0v6s64o7k80@o1"+D;
            var Dm:String = "@2v7s8o3@i1@o1"+D;
            var Dc:String = "@0v6s16o4@i3"+D;
            var E:String = "l1g9gb<dg12>a9a<cfa12>b9b<dgb12c9cfa<c12>>"
            E+="l2[g6<d12|dc>b<c6g18>]c>b<c>a20<cd"
            E+="e8f+gd8c>ba8g4l1gab<cdef+gab<cd>l2e8f+gd8f+4g8aa+aa+<c6>a+1<c1d24>>"
            E+="l1g9gag<d8c2>b2g9gag<g6f+2d2>a2g9gag<d8c2>b2g8<l2egf+ga8"
            var Ea:String="p5$@1v8s4o6k0"+E, Eb:String="p4$@2v12s2o5k2"+E, Ed:String="p2r2$@1v2s2o5"+E;
            var F:String = "$@1p2v4s2o4 l12[g<g>f<f>]"
            F+="v3s1l2[g18gab|f9l1v4s24fffv3s1f8l2ef]<c12> @2s16v8l1fa<c>a<cfcfafa<c"
            F+="@1v4o4l12s1c>ba<dc>b<d+f v8s4l6gfed v4o4l12s1[gf+ec6d6]";
            var G:String = "$@1p6v4s2o4 l12[b<b>a<a>]"
            G+="v3s1l2[b18b<cd>|a9l1v4s24aaas1v3a8l2ga]<f12 @2k2s16v8l1fa<c>a<cfcfafa<c"
            G+="@1v4o4l12s1gf+eagf+a+<c v8s4l6dc>ba v4o5l12s1[dd>bg6a6]";
            var H:String = "$@1p4v4s2o5 l12[d<d>c<c>] r96 s1edcdedd+f v8s8l6gfed v4o5l12s1[bage6f+6]"
            var I:String = "$@1v2s32o7 l1[[4gd>bgb<d]|[4fc>afa<c]][fc>afa<c]fdecd>b<c>abgaf"
            I+="o6s0[[4gbg<d>b<c>][4faf<c>ab]]";
            I+="o7v4s32[[bgeceg][af+d>b<df+]|[gec>a<ce]>def+gab<cdef+ga][gd+>a+ga+<d+][afc>a<cf]";
            I+="bgege>b<afcfc>a<ge>b<e>bg<f+d>a<d>af+"
            I+="o6[[gb<d>ab<g>][a<df+>a<da>][b<eg>b<gb>]<cegcg<c>df+ada<d>>]";
            _module = new TinySiOPM(2048, 1024, _onSoundFrame);
            _sequencer = new Sequencer(5, [A,B,Cm,Cc,Dl,Dm,Dc,Ea,Eb,Ed,F,G,H,I]);
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
import flash.events.Event;
import flash.geom.Point;
import flash.media.Sound;

var _sound:Sound;
var _module:TinySiOPM;
var _sequencer:Sequencer;


class KeyState
{
    public static const K_UP:uint    = 0x01;
    public static const K_DOWN:uint  = 0x02;
    public static const K_LEFT:uint  = 0x04;
    public static const K_RIGHT:uint = 0x08;
    public static const K_TRG1:uint  = 0x10;
    public static const K_TRG2:uint  = 0x20;

    private var mState:uint = 0;

    public function setState(s:uint):void {
        mState |= s;
    }

    public function delState(s:uint):void {
        mState &= ~s;
    }

    public function get state():uint {
        return mState;
    }
}

class Ship extends Sprite
{
    private var speed:int = 4;
    protected var mCount:int = 0;
    private var mMovBuf:PositionRingBuffer;
    private var mMultiples:Array;
    private var _shotCount:int;

    public var color:uint;
    function Ship(color:uint, enable_buf:Boolean = false)
    {
        this.color = color;
        draw();

        _shotCount = 0;
        if (enable_buf)
            mMovBuf = new PositionRingBuffer(100);
    }

    public function fillMoveBuffer():void {
        for (var i:int = 0;i < 100;i++)
            mMovBuf.push(x, y, false);
    }

    public function appendMultiple(m:Ship):void
    {
        if (!mMultiples) mMultiples = [];
        mMultiples.push(m);
    }

    public function draw():void
    {
        var g:Graphics = graphics;
        g.clear();
/*
        g.lineStyle(0, color);
        g.lineTo( -30, -10);
        g.lineTo( -30, 10);
        g.lineTo(0, 0);
        g.endFill();
*/
        g.beginFill(0xc0c0c0);
        g.drawPath(Vector.<int>([1,2,2,2,2,2]),
            Vector.<Number>([16,-2,-10,-4,-15,-3,-25,5,-20,5,-10,1]));
        g.endFill();
        g.beginFill(0x808080);
        g.drawPath(Vector.<int>([1,2,2,2]),
            Vector.<Number>([-15,-2,-15,2,-20,2,-20,-2]));
        g.endFill();
        g.beginFill(0x80a0f0);
        g.drawPath(Vector.<int>([1,2,2,2]),
            Vector.<Number>([-8,-4,-2,-3,5,0,-15,0]));
        g.endFill();
        g.beginFill(0xffffff);
        g.drawPath(Vector.<int>([1,2,2,2]),
            Vector.<Number>([-8,-1,-18,-7,-22,-7,-15,0]));
        g.endFill();
        g.beginFill(0xe0e0e0);
        g.drawPath(Vector.<int>([1,2,2,2,2,2]),
            Vector.<Number>([16,1,-10,-1,-15,0,-25,8,-20,8,-10,4]));
        g.endFill();
                
        if (mMultiples) {
            for each(var m:Ship in mMultiples)
                m.draw();
        }
    }

    public function moveByKeyState(s:uint):void
    {
             if (s&KeyState.K_UP)    y -= speed;
        else if (s&KeyState.K_DOWN)  y += speed;
             if (s&KeyState.K_LEFT)  x -= speed;
        else if (s&KeyState.K_RIGHT) x += speed;

        if (s&KeyState.K_TRG1) 
            fireShot();

             if (x - width< 0) x = width;
        else if (x > Nemesis.W) x = Nemesis.W;

             if (y - height/2 < 0) y = height/2;
        else if (y + height/2 > Nemesis.H) y = Nemesis.H - height/2; 

        mMovBuf.push(x, y);
    }

    public function tick():void {
        if (mMultiples) {
            var len:int = mMultiples.length;
            for (var i:int = 0;i < len;i++) {
                mMultiples[i].x = mMovBuf.getX((i+1)*8) - 10;
                mMultiples[i].y = mMovBuf.getY((i+1)*8);
            }

            for each(var m:Ship in mMultiples)
                m.tick();
        }
        mCount++;
     }

    public function fireShot():void {
        if (!(mCount%5) && _shotCount<2) {
            var bullet:Bullet = new Bullet(this);
            bullet.x = x;
            bullet.y = y;
            parent.addChild(bullet);
            _shotCount++;
            if (mMultiples) // = if player...('A`)
                _module.noteOn(1440,0,0.5,11,64,-256);
        }

        if (mMultiples) {
            for each(var m:Ship in mMultiples)
                m.fireShot();
        }
    }

    public function onShotRemoved() : void {
        _shotCount--;
    }
}

class Multiple extends Ship
{
    import flash.geom.Matrix;

    public static const GRAD_COLORS:Array = [0xffba33, 0xaa0000];
    public static const GRAD_ALPHAS:Array = [1, 1];
    public static const GRAD_RATIOS:Array = [100, 255];
    private var mGradTrans:Matrix = new Matrix();

    function Multiple()
    {
        super(0);
    }

    public override function draw():void
    {
        var g:Graphics = graphics;
        var r:Number = Math.sin(mCount*0.9)*0.7 + 9;

        mGradTrans.createGradientBox(r*2, r*1.8,0 , -r*1.1, -r*0.9);
        g.clear();
        g.beginGradientFill(GradientType.RADIAL, GRAD_COLORS, GRAD_ALPHAS, GRAD_RATIOS, mGradTrans);
        g.drawEllipse(-r, -r*0.8, r*2, r*1.6);
        g.endFill();
    }
}

class PositionRingBuffer
{
    private var xs:Array;
    private var ys:Array;
    private var length:uint;
    private var pos:int = 0;

    function PositionRingBuffer(len:uint)
    {
        length = len;
        xs = new Array(len);
        ys = new Array(len);
    }

    public function push(x:int, y:int, chk:Boolean = true):void {
        var i:int = (pos + length - 1) % length;
        if (chk) {
            if (xs[i] == x && ys[i] == y) return;
        }

        xs[pos] = x;
        ys[pos] = y;

        pos = ++pos % length;
    }

    public function getX(i:int):int {
        i = (pos - i + length) % length;
        return xs[i];
    }

    public function getY(i:int):int {
        i = (pos - i + length) % length;
        return ys[i];
    }
}

class Bullet extends Sprite
{
    public var color:uint;
    public var size:uint;
    public var speed:uint;
    private var _ship:Ship;

    function Bullet(ship:Ship, color:uint = 0xeeddaa, size:uint = 3, speed:uint = 20)
    {
        this._ship = ship;
        this.color = color;
        this.size = size;
        this.speed = speed;
        
        this.graphics.beginFill(color);
        this.graphics.drawEllipse(-size, -size/2, size*1.8, size);
        this.graphics.drawCircle(-size*1.3, 0, size/2);
        this.graphics.drawCircle(-size*1.8, 0, size/3);
        this.graphics.endFill();
        
        addEventListener(Event.ENTER_FRAME, updateHandler);
    }
    
    private function updateHandler(e:Event):void 
    {
        this.x += speed;
        
        if (this.x + size / 2 > Nemesis.W) {
            this.parent.removeChild(this);
            removeEventListener(Event.ENTER_FRAME, updateHandler);
            _ship.onShotRemoved();
        }
    }
}


class MountainGen
{
    private var mPrevBuffer:Array;
    private var mHeight:int;
    private var mCount:int = 0;

    private var tmpBuffer:Array;
    private var mGenFunc:Function;
    private var mDark:Boolean;
    
    function MountainGen(h:int, generator:int = 0, dark:Boolean = false)
    {
                mDark = dark;
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
                b.setPixel32(x, rev ? (y+mHeight-i) : (y+i), makeColor(c));
            }
        }
    }

    private function makeColor(c:int):uint
    {
        if (mDark)
            return 0xff000000 | (c/7+5) | ((c/7 + 80)<<16) | ((c/6+50) << 8);
        return 0xff000000 | (c/3+11) | ((c/5 + 170)<<16) | ((c/2+60) << 8);
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
        v += Math.sin(t*3) * 0.1;
        v += Math.cos(0.1 + t*10) * 0.02;
        v *= Math.sin(t*0.1);

        if (nest < 5)
            v += genWav2(t*2.0, 1+nest)*0.5;

        v = v*0.2 + 0.22;

        return (v<0) ? 0 : (v>1) ? 1 : v;
    }

    private static function genWav2(t:Number, nest:int = 0):Number
    {
        var v:Number = Math.sin(t);
        v += Math.cos(t*3) * 0.1;
        v += Math.cos(0.1 + t*9) * 0.02;
        v *= Math.cos(0.2 + t*0.15);

        if (nest < 5)
            v += genWav2(t*2.0, 1+nest)*0.5;

        v = v*0.2 + 0.23;

        return (v<0) ? 0 : (v>1) ? 1 : v;
    }
}

class StarBG extends Sprite
{
    private var mWidth:int;
    private var mHeight:int;

    private var mStars:Array;
    private var mStarVs:Array;
    private var mN:int;

    function StarBG(w:int, h:int, n:int)
    {
        mWidth = w;
        mHeight = h;
        mN = n;

        mStars  = new Array(n);
        mStarVs = new Array(n);
        for (var i:int = 0;i < n;i++) {
            mStars[i] = new Point(int( Math.random()*w ), int( Math.random()*h ));
            mStarVs[i] = Math.random() + 0.2;
        }
    }

    public function tick():void
    {
        var n:int = mN;

        for (var i:int = 0;i < n;i++) {
            mStars[i].x -= Number(mStarVs[i]);

            if (mStars[i].x < 0) {
                mStars[i].x += mWidth;
                mStars[i].y = int( Math.random()*mHeight );
            }
        }
    }

    public function draw():void
    {
        var g:Graphics = graphics;
        var n:int = mN;

        g.clear();
        for (var i:int = 0;i < n;i++) {
            g.beginFill(0xffffff);
            g.drawCircle( mStars[i].x, mStars[i].y , 0.4);
        }
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
    private var _rex:RegExp=/(@i|@o|[a-gkloprsvw<>[|\]$@])([#+])?(\d+)?/g;
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
                    case 'k': dt    = int(res[3]); break;
                    case 'l': len = int(res[3]); break;
                    case 'o': oct = int(res[3]); break;
                    case 'v': tl    = TinySiOPM.log(int(res[3])*0.0625); break;
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
