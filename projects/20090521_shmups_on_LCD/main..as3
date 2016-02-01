// forked from keim_at_Si's wonderflでポケコン
//   phase 6 ＋ Beep音．
//   move;arrow or wasd/shot;ctrl,z,n/slow;shift,x,m
//--------------------------------------------------
package {
    import flash.display.*;
    import flash.events.*;

    [SWF(width="465", height="465", backgroundColor="0", frameRate="30")]
    public class main extends Sprite {
        function main() {
            // key mapping
            _key = new KeyMapper(stage);
            _key.map(0,37,65).map(1,38,87).map(2,39,68).map(3,40,83).map(4,17,90,78).map(5,16,88,77);

            // lcd render
            _lcd = new LCDRender();
            _lcd.charMap[65] = LCDRender.hex2bmp("70607c6070");
            addChild(_lcd);
            addEventListener("enterFrame", _onEnterFrame);
            
            // beep
            _beep = new Beep();

            _actorManager[FIBER]     = new ActorManager(Fiber);
            _actorManager[BULLET]    = new ActorManager(Actor).pat("070507", 3).pat("0e1b111b0e", 5);
            _actorManager[SHOT]      = new ActorManager(Actor).pat("3f0000003f", 6).pat("3f", 6);
            _actorManager[ENEMY]     = new ActorManager(Actor, _actorManager[SHOT]);
            _actorManager[PARTICLE]  = new ActorManager(Actor).pat("01", 1);
            _actorManager[EXPLOSION] = new ActorManager(Explosion);
            _actorManager[ENEMY].pat("583c563f3f563c58", 7, 6).pat("2b7e353c3c357e2b", 14, 20).pat("2b7e353c3c357e2b", 21, 20).pat("01", 1);
            _actorManager[EXPLOSION].pat("0000060909060000").pat("1669b9c644463d02").pat("1285324884844a30");
            _actorManager[EXPLOSION].pat("0002000060905021").pat("0000000000000080");
            for (var i:int=0, p:Number=0; i<5120; i++, p+=0.0015339807878856411) sin[i] = Math.sin(p);
            _player = Player(_playerManager.alloc());
            _player.changeStatus(0);
            _player.life = 3;
            score = 0;
            _sceneManager.changeScene(0);
        }

        private function _onEnterFrame(e:Event) : void {
            frameCount++;
            _lcd.cls();
            if (frameCount & 1) _actorManager[PARTICLE].alloc().init(Math.random()*96, 0, 0, int(Math.random()*3)+1);
            if (_sceneManager.update()) _player.update(_actorManager[BULLET]);
            for (var i:int = 0; i<6; i++) _actorManager[i].updateAll();
            _lcd.render();
        }
    }
}

// internal variables
const FIBER:int = 0;
const BULLET:int = 1;
const SHOT:int = 2;
const ENEMY:int = 3;
const PARTICLE:int = 4;
const EXPLOSION:int = 5;

var sin:Vector.<Number> = new Vector.<Number>(5120, true);
var _lcd:LCDRender;
var _key:KeyMapper;
var _beep:Beep;
var _sceneManager:SceneManager = new SceneManager();
var _playerManager:ActorManager = new ActorManager(Player).pat("7820782f782078", 7);
var _actorManager:Vector.<ActorManager> = new Vector.<ActorManager>(6, true);
var _player:Player;
var frameCount:int;
var score:int;
var phase:int;

var shotScript:Vector.<String> = Vector.<String>([
    "&c1[99999ha180f40{&p0}f{&p1v20w1ha190vd40}f{&p1v-20w1ha170vd40}w2f40{&p0}40w2f40f{&p1v20w1ha200vd40}f{&p1v-20w1ha160vd40}w2f40{&p0}w2]",
    "&c1[99999ha180f40{&p0}f{&p1v20w1v0,-40}f{&p1v-20w1v0,-40}w2]"
]);


import flash.display.*;
import flash.geom.*;
import flash.filters.*;
import flash.events.*;
import flash.media.*;
import flash.utils.*;

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
                bmp.fillRect(rect, -(pat&1));
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
    
    public function line(x0:int, y0:int, x1:int, y1:int, color:int=255, thick:Number=1) : void {
        _shape.graphics.clear();
        _shape.graphics.lineStyle(thick, color);
        _shape.graphics.moveTo(x0, y0);
        _shape.graphics.lineTo(x1, y1);
        data.draw(_shape);
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

class KeyMapper {
    public  var keys:uint = 0;
    private var _map:Vector.<int> = new Vector.<int>(256, true);
    
    function KeyMapper(stage:Stage) : void { 
        for (var i:int=0; i<256; i++) _map[i]=31;
        stage.addEventListener("keyDown", function(e:KeyboardEvent) : void {
            keys |= 1<<_map[e.keyCode];
        });
        stage.addEventListener("keyUp",   function(e:KeyboardEvent) : void {
            keys &= ~(1<<_map[e.keyCode]);
        });
    }
    
    public function map(bit:int, ...args) : KeyMapper {
        for (var i:int=0; i<args.length; i++) _map[args[i]] = bit;
        return this;
    }
}

class Beep {
    private var _phase:int, _pitch:int, _count:int, _sweep:int;
    private var _sound:Sound = new Sound();
    private var _step:Vector.<int> = new Vector.<int>(256, true);
    private var _wave:Vector.<Number> = new Vector.<Number>(16, true);
    
    function Beep() {
        var i:int;
        _sound.addEventListener("sampleData", _onStream);
        for (i=0; i<16; i++) _wave[i] = 0;
        for (i=0; i<256; i++) _step[i] = i;
        _wave[14] = -(_wave[15] = 0.1);
        _sweep = _count = _pitch = _phase = 0;
        _sound.play();
    }
    
    public function play(pitch:int, length:int, sweep:int) : void {
        _pitch = pitch;
        _count = length+1;
        _sweep = sweep;
    }
    
    private function _onStream(e:SampleDataEvent) : void {
        var l:int, i:int, n:Number, data:ByteArray = e.data;
        for (l=0; l<2; l++) {
            if (--_count == 0) { _pitch = _sweep = 0; }
            _pitch += _sweep;
            for (i=0; i<1024; i++) {
                _phase = (_phase+_step[_pitch&255]) & 4095;
                data.writeFloat(_wave[_phase>>8]);
                data.writeFloat(_wave[_phase>>8]);
            }
        }
    }
}

class SceneManager {
    public var id:int;
    public var initPhase:int = 0;
    private var _stage:Actor, _stageScript:String;
    private var _groupScript:Array = [
        ["&c2&p3p6v12[8f{&l1vd24i20vw10f8w10vd-20}w2]ko",
         "&c2&p3p90v-12[8f{&l1vd24i20vw10f8w10vd-20}w2]ko", 
         "&p1&l20v0,12i8v0,1w8[2ha-56f8hs16[7w5f8]w5ha56f8hs-16[7w5f8]w5]a0,1",
         "[40ha90f100{w1b5,120f10{&p1}ko}ha-90f100w30]"],
        ["&c2&p3p12v24[5f{&l2v0,20i10vw10ht[6f-10{i30hv180vd20}w1hs0]w30hti60vd40}w2]ko",
         "&c2&p3p84v-24[5f{&l2v0,20i10vw10ht[6f-10{i30hv180vd20}w1hs0]w30hti60vd40}w2]ko", 
         "&p1&l20v0,12i8v0,1w8b3,40ht10f6w24ht-10f6w48a0,1",
         "[20b4,100htf8{&p0}w3b1ha135[5f15{&p1i10vw10vd20}w1]w11ha215[5f15w1]w8]"],
        ["&c2&p3p6v12[8f{&l1b2,0,2vd24i20vw10f8w10vd-20}w2]ko",
         "&c2&p3p90v-12[8f{&l1b2,0,2vd24i20vw10f8w10vd-20}w2]ko", 
         "&p1&l20v0,12i8v0,1w8b4,60,6f8{&p1}w24b4,60,-6f8w48a0,1",
         "[20haf20{&p1i15vw20hab12,330f5w10ha15b12,330f10ko}[2ha90f50{w1vd-4w1hv[4f-15{&p1}w2]ko}w16ha-90f50w16]]"],
        ["&c2&p3p4,16[4f{&l3hr60[2v20,1w6f8w12v-20,1w6f8w12]}w2]ko",
         "&c2&p3p92,16[4f{&l3hr60[2v-20,1w6f8w12v20,1w6f8w12]}w2]ko", 
         "&p1&l20v0,12i8v0,1w8[3b3,40f1{&p1hvi40vd12}w16]a0,1",
         "b4,120[40ht40f6{&p1}hs-10bv2[4w2f]w12ht-40f6hs10bv2[4w2f]w12]"],
        ["&c2&p3p6v10[4f{&l2v0,48i10vw10a0,-1hr90b3,240[f4w20]}w4]fko",
         "&c2&p3p90v-10[4f{&l2v0,48i10vw10a0,-1hr90b3,240[f4w20]}w4]ko",
         "&p1&l20v0,12i8v0,1w8[2b2,10ht8f6hs-2bv1[7fw2]ht-8f6hs2bv1[7fw2]w24]a0,1",
         "ha[40b1f{vb7,120f8{&p1}hsw20b6,100f16{&p0}ko}[8w1b2,60f-10{&p1[60ad1w2]}]w24]"],
        ["&c2&p3p84[2f{&l4i4v0,20w4bv2f6[3v-20,0w4v0,-16fw4v20,0w4v0,24fw4]}w8]ko",
         "&c2&p3p12[2f{&l4i4v0,20w4bv2f6[3v20,0w4v0,-16fw4v-20,0w4v0,24fw4]}w8]ko",
         "&p1&l20v0,12i8v0,1w8[2ha-48f6{&p1}hs16bv1[5w2f]w6ha40f6hs-16bv1[5w2f]w6]a0,1",
         "@{b3,240hs10[320f20{&p1hv90w5f10}w4]}b3,240hs-10[320f20{&p1hv90w5f10}w4]"]
    ];

    function SceneManager() {
        _stageScript  = "&c2&p3&l0,1p48w64[2f$0w32f$1w32]f$0w16f$1w16f$2w48p24f$2p72f$2w64";
        _stageScript += "[2f$0w24p16f$2w24f$1w24p84f$2w24]w32p24f$2p72f$2[2w16f$0w16f$1]w64p48f$3ko";
        for (var i:int=0; i<_groupScript.length; i++) {
            _groupScript[i][3] = "&p2&l100v0,20i8v0,1w8@{v10[10i64v-10w64v10w64]a0,1}"+_groupScript[i][3];
        }
    }
    
    public function changeScene(id:int) : void {
        this.id = id;
        frameCount = 0;
        switch (id) {
        case 1: _start(); break;
        case 2: _stage.kill(); break;
        }
    }
    
    private function _start() : void {
        _beep.play(0,32,32);
        if (phase == _groupScript.length) { changeScene(3); return; }
        _stage = _actorManager[ENEMY].alloc().init(48, 0, 0, 0, 2);
        Fiber(_actorManager[FIBER].alloc()).motion(_stage, _stageScript, _groupScript[phase++]);
    }
    
    public function update() : Boolean {
        for (var i:int=0, x:Number=90; i<_player.life; i++, x-=6) _lcd.print(x, 0, 'a');
        _lcd.print( 0, 0, String(score));
        switch (id) {
        case 0:
            _lcd.print(0, 32, "-TINY CANNON ML-"); _lcd.print(6, 64, "PRESS SHOT KEY");
            if (frameCount>30 && (_key.keys & 16)) {
                _actorManager[BULLET].freeAll();
                _actorManager[ENEMY].freeAll();
                _player.init(48,80);
                _player.life = 3;
                score = 0;
                phase = initPhase;
                changeScene(1);
            }
            break;
        case 1:
            if (frameCount<60) _lcd.print(27, 44, "PHASE:"+String(phase));
            if (_actorManager[ENEMY].isEmpty) changeScene(1);
            return true;
        case 2:
            _lcd.print(9, 44, "- GAME OVER -");
            if (frameCount>30 && (_key.keys & 16)) changeScene(0);
            break;
        case 3:
            _lcd.print(15, 44, "ALL CLEAR !");
            if (frameCount>30 && (_key.keys & 16)) changeScene(0);
            break;
        }
        return false;
    }
}

class ActorManager {
    private var _actorClass:Class, _evaluator:ActorManager, _freeList:Actor, _activeList:Actor;
    public  var _pattern:Vector.<BitmapData> = new Vector.<BitmapData>();
    public  var _size2:Vector.<Number> = new Vector.<Number>();
    
    public function get isEmpty() : Boolean { return (_activeList.next==_activeList); }
    
    function ActorManager(actorClass:Class, evaluator:ActorManager=null) {
        _actorClass = actorClass;
        _evaluator = evaluator;
        _freeList = new Actor(this);
        _activeList = new Actor(this);
    }
    
    public function pat(hex:String, h:int=8, size:Number=0) : ActorManager {
        _pattern.push(LCDRender.hex2bmp(hex, h, ((h-1)>>3) + 1));
        _size2.push(size*size);
        return this;
    }
    
    public function alloc() : Actor {
        var actor:Actor = _freeList.pop() || new _actorClass(this);
        _activeList.push(actor);
        return actor;
    }
    
    public function free(act:Actor) : Actor {
        var next:Actor = act.next;
        act.prodNum++;
        act.remove();
        _freeList.push(act);
        return next;
    }
    
    public function updateAll() : void {
        for (var act:Actor=_activeList.next; act!=_activeList; act=act.update(_evaluator));
    }
    
    public function freeAll() : void {
        for (var act:Actor=_activeList.next; act!=_activeList; act=free(act));
    }
    
    public function hitEval(obj:Actor, dist2:Number) : int {
        for (var cnt:int=0, act:Actor=_activeList.next; act!=_activeList; act=act.next)  {
            var dx:Number = act.x - obj.x, dy:Number = act.y - obj.y;
            if (dx*dx+dy*dy < dist2) { act=free(act).prev; cnt++; }
        }
        return cnt;
    }
}

class Actor {
    public var x:Number, y:Number, vx:Number, vy:Number, ax:Number, ay:Number, ac:int;
    public var childManager:ActorManager, life:int, bonus:int, range:Boolean, patNum:int, prodNum:int=0;
    protected var _manager:ActorManager;
    
    function Actor(manager:ActorManager) {
        _manager = manager;
        prev = this; 
        next = this;
    }
    
    public function init(x:Number, y:Number, vx:Number=0, vy:Number=0, patNum:int=0) : Actor {
        pos(x, y).vel(vx, vy).acc(0, 0, 0);
        this.patNum = patNum;
        range = true;
        life = 0;
        bonus = 0;
        childManager = _actorManager[BULLET];
        return this;
    }
    
    public function pos(x:Number, y:Number) : Actor {
        this.x = x;
        this.y = y;
        return this;
    }
    
    public function vel(vx:Number, vy:Number, term:int=0) : Actor {
        if (term == 0) {
            this.vx = vx;
            this.vy = vy;
        } else {
            var n:Number = 1 / term;
            acc((vx-this.vx)*n, (vy-this.vy)*n, term);
        }
        return this;
    }
    
    public function acc(ax:Number, ay:Number, ac:int) : Actor {
        this.ax = ax;
        this.ay = ay;
        this.ac = ac;
        return this;
    }
    
    public function update(eval:ActorManager) : Actor {
        x += vx + ax * 0.5;
        y += vy + ax * 0.5;
        vx += ax;
        vy += ay;
        if (--ac == 0) { ax=0; ay=0; }
        if (range && (x<0 || x>95 || y<0 || y>95)) return _manager.free(this);
        if (eval && life>0 && (life-=eval.hitEval(this, _manager._size2[patNum]))<=0) {
            score += bonus;
            _actorManager[EXPLOSION].alloc().init(x, y, vx, vy+1).vel(0,0,20);
            _beep.play(64,4,-8);
            return _manager.free(this);
        }
        _lcd.gprint(x+0.5, y+0.5, _manager._pattern[patNum]);
        return next;
    }
    
    public function kill() : void {
        _manager.free(this);
    }
    
    public var prev:Actor, next:Actor;
    public function push(act:Actor) : void { act.next=this; act.prev=prev; prev.next=act; prev=act; }
    public function pop() : Actor { return (prev==this) ? null : prev.remove(); }
    public function remove() : Actor { prev.next=next; next.prev=prev; return this; }
}

class Player extends Actor {
    private var _status:int, _statusCount:int, _statusCounts:Vector.<int>=Vector.<int>([20,60,0,0]);
    public var prevShot:int=0, shotFiber:Fiber=null;
    
    function Player(manager:ActorManager) { super(manager); }
    
    override public function update(eval:ActorManager) : Actor {
        var inkey:uint = _key.keys;
        if (--_statusCount == 0) changeStatus(_status+1);
        if (_status == 0) {
            y -= _statusCount*0.2;
        } else {
            vx = ((inkey>>2) & 1) - (inkey & 1);
            vy = ((inkey>>3) & 1) - ((inkey>>1) & 1);
            if ((inkey & 32) == 0) { vx<<=1; vy<<=1; }
            inkey &= 48;
            if (inkey != prevShot) {
                if (shotFiber) { shotFiber.kill(); shotFiber = null; }
                if (inkey&16) shotFiber = Fiber(_actorManager[FIBER].alloc()).motion(this, shotScript[int(inkey==48)]);
            }
            prevShot = inkey;
            if (x+vx<3 || x+vx>92) vx=0;
            if (y+vy<3 || y+vy>92) vy=0;
            x += vx;
            y += vy;
        }
        if (_status == 2 && eval.hitEval(this, 4)) miss();
        if (_status == 2 || (frameCount & 1)) _lcd.gprint(x, y, _manager._pattern[0]);
        return next;
    }
    
    public function changeStatus(s:int) : void {
        _status = s;
        _statusCount = _statusCounts[s];
        if (s==0) y+=38;
    }
    
    public function miss() : void {
        if (shotFiber) { shotFiber.kill(); shotFiber = null; }
        for (var i:int=0; i<8; i++) 
            _actorManager[EXPLOSION].alloc().init(x, y, Math.random()*4-2, Math.random()*2-1).vel(0,0,20);
        _beep.play(192,40,-4);
        if (--life == 0) _sceneManager.changeScene(2);
        else changeStatus(0);
    }
}

class Explosion extends Actor {
    private var _animCount:int;
    
    function Explosion(manager:ActorManager) { super(manager); }
    
    override public function init(x:Number, y:Number, vx:Number=0, vy:Number=0, patNum:int=0) : Actor {
        _animCount = 0;
        return super.init(x, y, vx, vy, patNum);
    }
    
    override public function update(eval:ActorManager) : Actor {
        patNum = (++_animCount)>>2;
        return (_animCount==19) ? _manager.free(this) : super.update(eval);
    }
}

class Fiber extends Actor {
    private const VRAT:Number = 0.2;
    private const ARAT:Number = 0.04;
    
    public var actor:Actor, script:String, prevScript:String, counter:int, childScript:Vector.<String>;
    private var _bc:int, _ba:Number, _bv:Number, _interval:int, _prodNum:int, _loopStac:Array = [];
    public var rex:RegExp = /(h[avtsr]|bv|[av]d|ko|&[clp]|[pvaiwfb@[\]])([-\d]+)?,?([-\d]+)?,?([-\d]+)?(\{)?(\$(\d+))?/g;
    public var rex2:RegExp = /[{}]/g;
    
    function Fiber(manager:ActorManager) { super(manager); }

    public function motion(actor:Actor, script:String, childScript:Array=null) : Fiber {
        pos(0, 0).vel(0, 0).acc(0, 0, 2);
        _bc = 1;
        _ba = 0;
        _bv = 0;
        _interval = 0;
        this.actor  = actor;
        this.script = script;
        this.childScript = (childScript) ? Vector.<String>(childScript) : new Vector.<String>();
        prevScript = null;
        _prodNum = actor.prodNum;
        childManager = actor.childManager;
        counter = 1;
        _loopStac.length = 0;
        rex.lastIndex = 0;
        return this;
    }
    
    override public function update(eval:ActorManager) : Actor {
        var res:*, p0:int, p1:int, p2:int, i:int, n:Number;
        if (actor.prodNum != _prodNum) return _manager.free(this);
        if (--counter == 0) {
            for (res = rex.exec(script); res; res = rex.exec(script)) {
                p0 = res[2] || 0;
                p1 = res[3] || 0;
                p2 = res[4] || 0;
                switch (res[1]) {
                case 'w': counter = p0; return next;
                case 'i': _interval = p0; break;
                case 'p': actor.pos(p0, p1); break;
                case 'v': actor.vel(p0*VRAT, p1*VRAT, _interval); break;
                case 'a': actor.acc(p0*ARAT, p1*ARAT, 0); break;
                case 'f': _fire(p0 * VRAT, seq()); break;
                case 'ha': acc(p0, 0, 0); break;
                case 'hv': acc(p0, 0, 1); break;
                case 'ht': acc(p0, 0, 2); break;
                case 'hs': ax=p0; ac=3; break;
                case 'hr': acc(p0, 0, 4); break;
                case 'bv': vy = p0 * VRAT; break;
                case 'b': _bc = p0 || 1; _ba = p1*0.017453292519943295; _bv = p2*VRAT; break;
                case '@': Fiber(_actorManager[FIBER].alloc()).motion(actor, seq()); break;
                case '&l': actor.life = p0; actor.bonus = p0*10; actor.range = (p1 == 0); break;
                case '&p': actor.patNum = p0; break;
                case '&c': childManager = _actorManager[BULLET+p0]; break;
                case 'ko': actor.kill(); return _manager.free(this);
                case '[': _loopStac.unshift({c:p0, p:rex.lastIndex}); break;
                case ']': 
                    if (--_loopStac[0].c == 0) _loopStac.shift();
                    else rex.lastIndex = _loopStac[0].p;
                    break;
                case 'vd':
                    i = int(angle * 651.8986469044033) & 4095;
                    actor.vel(sin[i+1024]*p0*VRAT, sin[i]*p0*VRAT, _interval);
                    break;
                case 'ad':
                    i = int(angle * 651.8986469044033) & 4095;
                    actor.acc(sin[i+1024]*p0*VRAT, sin[i]*p0*VRAT, 0);
                    break;
                }
            }
            counter = 0;
            return _manager.free(this);
        }
        return next;
        
        function seq() : String {
            if (res[5]) {
                rex2.lastIndex = rex.lastIndex;
                for (res=rex2.exec(script), i=1; res; res=rex2.exec(script)) {
                    i += (res[0]=='{');
                    if (res[0] == '}' && --i == 0) {
                        prevScript = script.substring(rex.lastIndex, rex2.lastIndex - 1);
                        break;
                    }
                }
                rex.lastIndex = rex2.lastIndex;
            }
            if (res[7]) prevScript = childScript[int(res[7])];
            return prevScript;
        }
    }
    
    public function get angle() : Number {
        switch (ac) {
        case 0: ay = ax * 0.017453292519943295 + 1.5707963267948965; break;
        case 1: ay = ax * 0.017453292519943295 + Math.atan2(actor.vy, actor.vx); break;
        case 2: ay = ax * 0.017453292519943295 + Math.atan2(_player.y-actor.y, _player.x-actor.x); break;
        case 3: ay += ax * 0.017453292519943295; break;
        case 4: ay = (Math.random()-0.5) * ax * 0.017453292519943295 + 1.5707963267948965; break;
        }
        return ay;
    }
    
    private function _fire(vel:Number, script:String) : void {
        vx = (vel = vel || (vx+vy));
        var i:int, iang:int, ang:Number=angle, div:Number = (_bc>1) ? 1/(_bc-1) : 1,
            astep:Number = _ba*div, vstep:Number = _bv*div, fired:Actor;
        for (i=0, ang-=_ba*0.5, vel-=_bv*0.5; i<_bc; i++, ang+=astep, vel+=vstep) {
            iang = int(ang*651.8986469044033)&4095;
            fired = childManager.alloc().init(actor.x, actor.y, sin[iang+1024]*vel, sin[iang]*vel);
            if (script) Fiber(_actorManager[FIBER].alloc()).motion(fired, script);
        }
    }
}


