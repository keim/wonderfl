package {
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.media.*;
    import flash.text.*;
    import flash.geom.*;
    
    [SWF(width="465", height="465", backgroundColor="#ffffff", frameRate=30)]
    public class main extends Sprite {
        private var module:TinySiOPM=new TinySiOPM(), sound:Sound=new Sound(), channel:SoundChannel;
        private var bshc:Array = ["8060004205300042","0000620000006001","3121001121110110"];
        private var tone:Array = [[672,4,0,20,-48],  [4,4,3,24,0],      [31,2,3,36,0]];
        private var auto:Array = [0x5001,0x1101,0x1211,0x16d1,0x1252,0x6609,0xc514,0x6a01,0xd414,0xa4a4,0xa444,0x5249];
        private var pong:Array = [57,60,62,64,67,69];
        private var screen:Bitmap = new Bitmap(new BitmapData(465, 465, true, 0));
        private var balls:Array = [];
        private var pointer:int, frame:int, frameCounter:int, note:int, bound:int, autoNum:int, wave:int, beat:int;
        private var shadow:DropShadowFilter = new DropShadowFilter(8,45,0,0.5,6,6);
        private var shape:Shape=new Shape(), mat:Matrix=new Matrix(), pos:Number, scl:Number;
        private var apButton:SimpleButton, tfNormal:TextField;
        public function main() {
            function tf(t:String, c:uint=0x808080, x:int=0, y:int=0) : TextField {
                var tf:TextField=new TextField(); tf.htmlText=t; tf.textColor=c; tf.height=24; tf.x=x; tf.y=y; return tf;
            }
            function sb(t:String, f:Function, x:int, y:int) : SimpleButton {
                var over:TextField = tf("<u><b>"+t+"</b></u>", 0xf08080);
                var button:SimpleButton = new SimpleButton(tf("<u>"+t+"</u>"), over, over, over); button.x=x; button.y=y;
                button.addEventListener("mouseDown", f); return button;
            }
    	    sound.addEventListener('sampleData', _onStream);
            stage.addEventListener("enterFrame", _onEnterFrame);
            stage.addEventListener("mouseDown",  function(e:Event):void{ note=1; _switchAutoPlay(false); });
            tfNormal=tf("クリックでえんそう",0x808080, 180, 16);
            apButton=sb("ぜんじどうえんそう",function(e:Event):void{_switchAutoPlay(true);e.stopPropagation();},180,16);
            addChild(apButton); apButton.visible = false;
            addChild(tfNormal);
            addChild(sb("おとかえる",function(e:Event):void{if(++wave==12)wave=0; e.stopPropagation();}, 32,  16));
            addChild(sb("はやくする",function(e:Event):void{if(--frame==1)frame=5;e.stopPropagation();}, 380, 16));
            addChild(screen);
            pointer=0; frame=3; frameCounter=0; note=0; bound=0; autoNum=1; wave=2; pos=500; scl=1; beat=0;
            shape.graphics.lineStyle(3, 0, 0.5);
            shape.graphics.drawPath(Vector.<int>([1,2,1,2,1,2,1,2,1,2,1,2]), 
                Vector.<Number>([-500,-40,500,-40,-500,-20,500,-20,-500,0,500,0,-500,20,500,20,-500,40,500,40,0,-40,0,40]));
            ball.createShape();
            channel = sound.play();
        }
        private function _onEnterFrame(event:Event) : void {
            var bd:BitmapData = screen.bitmapData;
            if (note > 1) {
                var x:int = (autoNum) ? Math.random()*200+132 : mouseX,
                    y:int = (autoNum) ? Math.random()*100+132 : mouseY;
                balls.push(new ball(x, y, note-2, function(p:int, v:Number):void{ 
                    var iv:int = int(v*48);
                    if ((bound & 63) < iv) bound = (p<<6) | iv;
                }));
                note = 0;
            }
            scl+=(1-scl)*0.5; pos-=6-frame; if (pos<0) pos+=500;
            mat.identity(); mat.scale(scl,scl); mat.translate(pos, 160);
            bd.fillRect(bd.rect, 0x00ffffff);
            bd.draw(shape, mat);
            balls = balls.filter(function(b:*,i:int,a:Array):Boolean { return b.render(bd); });
            bd.applyFilter(bd, bd.rect, bd.rect.topLeft, shadow);
        }
        private function _onStream(e:SampleDataEvent) : void {
            if (++frameCounter >= frame) {
                for (var i:int=0; i<3; i++) {
                    var v:int = parseInt(bshc[i].charAt(pointer), 16);
                    if (v) { module.noteOn(tone[i][0], v<<tone[i][1], tone[i][2], tone[i][3], tone[i][4]); }
                }
                if (autoNum) {
                    if ((auto[autoNum-1]>>pointer) & 1) note = 1;
                    if (pointer == 15) autoNum = int(Math.random()*12)+1;
                }
                if (note == 1) { 
                    var p:int = int(Math.random()*6);
                    module.noteOn((pong[p]+(beat>>7))<<4,64,wave,8);
                    note = p+2;
                }
                if (bound > 0) {
                    module.noteOn((pong[bound>>6]+(beat>>7))<<4,bound&63,wave,8);
                    bound = 0;
                }
                pointer = (pointer + 1) & 15;
                if ((pointer & 3)==2) { scl=1.4; beat++; }
                frameCounter = 0;
            }
            module.buffer(e.data);
        }
        private function _switchAutoPlay(ap:Boolean) : void {
            if (ap == Boolean(autoNum)) return;
            if (ap) { apButton.visible=false; tfNormal.visible=true;  autoNum=1; } 
            else    { apButton.visible=true;  tfNormal.visible=false; autoNum=0; } 
        }
    }
}


import flash.events.*;
import flash.display.*;
import flash.geom.*;
class ball {
    static private var color:Vector.<uint> = Vector.<uint>([0xf08080,0xe0e040,0x80f080,0x40e0e0,0x8080f0,0xe040e0]);
    static private var _s:Shape = new Shape(), _m:Matrix = new Matrix(), _c:ColorTransform = new ColorTransform();
    private var p:Point, v:Point, alpha:Number, pitch:int, bound:Function, bounded:Boolean, len:Number, dlen:Number;
    function ball(x:int, y:int, pit:int, f:Function) {
        p=new Point(x, y); v=new Point(Math.random()*8-4-(x-232)*0.016, Math.random()*-6-6);
        alpha=1; pitch=pit; bound=f; bounded=true; len=Math.random()*0.2+0.6; dlen=0;
    }
    public function render(bd:BitmapData) : Boolean {
        p.x+=v.x; p.y+=v.y; v.y+=1; alpha-=0.0078125; len+=dlen; dlen+=(1-len)*0.3-dlen*0.1; 
        if (v.y>0 && bounded && p.y+v.y*8>400) { bound(pitch, alpha); bounded=false; }
        else if (p.y>450) { p.y=900-p.y; v.y=-v.y*0.7; bounded=true; len=0.7; }
        if (p.x<0 || p.x>495 || alpha<0.01) return false;
        _m.identity(); _m.scale(1, len); _m.translate(p.x, p.y);
        _c.alphaMultiplier = alpha;
        _c.redOffset = color[pitch] >> 16;
        _c.greenOffset = (color[pitch] >> 8) & 255;
        _c.blueOffset = color[pitch] & 255;
        bd.draw(_s, _m, _c);
        return true;
    }
    static public function createShape() : void {
        _s.graphics.clear();
        _s.graphics.lineStyle(3, 0);
        _s.graphics.beginFill(0);
        _s.graphics.drawCircle(0, 0, 10);
        _s.graphics.endFill();
        _s.graphics.drawPath(Vector.<int>([1,2,2,2,2,2]),Vector.<Number>([10,0,10,-50,15,-38,20,-32,20,-25,17,-17]));
    }
}


import flash.utils.ByteArray;
class TinySiOPM {
    private var _t:Note, _o:Vector.<Number>, _s:int;
    private var _p:Vector.<int> = new Vector.<int>(2048, true);         // pitchTable[128*16]
    private var _l:Vector.<Number> = new Vector.<Number>(6144, true);   // logTable[12*256*2]
    function TinySiOPM(bufferSize:int=2048) {
        var i:int, j:int, p:Number, v:Number, t:Vector.<int>;
        for (i=0, p=0; i<192; i++, p+=0.00520833333)                    // pitch table
            for(v=Math.pow(2, p)*12441.464342886, j=i; j<2048; v*=2, j+=192) _p[j] = int(v);
        for (i=0; i<32; i++) _p[i] = (i+1)<<6;                          // pitch=0-31 for white noize
        for (i=0, p=0.0078125; i<256; i+=2, p+=0.0078125)               // log table
            for(v=Math.pow(2, 13-p)*0.0001220703125, j=i; j<3328; v*=0.5, j+=256) _l[j+1] = -(_l[j] = v);
        for (i=3328; i<6144; i++) _l[i] = 0;
        var famtri:Array = [0,1,2,3,4,5,6,7,7,6,5,4,3,2,1,0,-1,-2,-3,-4,-5,-6,-7,-8,-8,-7,-6,-5,-4,-3,-2,-1];
        for (t=Note.table(10), i=0, p=0; i<1024; i++, p+=0.00613592315) t[i] = _log(Math.sin(p)); // sin=0
        for (t=Note.table(10), i=0, p=0.75; i<1024; i++, p-=0.00146484375) t[i] = _log(p);        // saw=1
        for (t=Note.table(5),  i=0; i<32; i++) t[i] = _log(famtri[i]*0.0625);                     // famtri=2
        for (t=Note.table(15), i=0; i<32768; i++) t[i] = _log(Math.random()-0.5);                 // wnoize=3
        for (i=0; i<8; i++) for (t=Note.table(4), j=0; j<16; j++) t[j] = (j<=i) ? 192 : 193;      // pulse=4-11
        _s=bufferSize; _t=new Note(); _o=new Vector.<Number>(_s, true); for(i=0; i<_s; i++) _o[i]=0;
    }
    private function _log(n:Number) : int {
        return (n<0) ? ((n<-0.00390625) ? (((int(Math.log(-n) * -184.66496523 + 0.5) + 1) << 1) + 1) : 2047)
                     : ((n> 0.00390625) ? (( int(Math.log( n) * -184.66496523 + 0.5) + 1) << 1)      : 2046);
    }
    public function buffer(data:ByteArray) : void {
        var n:Note, rep:int, i:int, imax:int, dph:int, lout:int, v:int;
        for (imax=1024; imax<=_s; imax+=1024) for (n=_t.next; n!=_t; n=n.step())
                for (dph=_p[n.pitch], i=imax-1024; i<imax; n.ph=(n.ph+dph)&0x3ffffff, i++)
                    { lout=n.wave[n.ph>>n.shift]+n.gain; _o[i]+=_l[lout]; }
        for (i=0; i<_s; i++) { data.writeFloat(_o[i]); data.writeFloat(_o[i]); _o[i]=0; }
    }
    public function noteOn(pitch:int, velocity:int=64, tone:int=0, decay:int=4, sweep:int=0) : Note { 
        return Note.alloc().reset(pitch, _log(velocity*0.0078125), tone, (decay<<2), sweep).into(_t); 
    }
}
class Note {
    public var prev:Note, next:Note, ph:int, pitch:int, gain:int, sweep:int, decay:int, wave:Vector.<int>, shift:int; 
    static private var _w:Array=[], _s:Array=[], _fl:Note = new Note();
    function Note() { prev = next = this; }
    public function free() : Note { var r:Note=prev; r.next=next; next.prev=r; into(_fl); return r; }
    public function into(n:Note) : Note { prev=n.prev; next=n; prev.next=this; next.prev=this; return this; }
    public function step() : Note { gain+=decay; pitch+=sweep; pitch&=2047; return (gain>3328)?(free().next):next; }
    public function reset(p:int, g:int, t:int, d:int, s:int) : Note 
    { ph=0; pitch=p; gain=g; sweep=s; decay=d<<1; wave=_w[t]; shift=_s[t]; return this; }
    static public function table(b:int) : Vector.<int>
    { var t:Vector.<int>=new Vector.<int>(1<<b, true); _w.push(t); _s.push(26-b); return t; }
    static public function alloc() : Note 
    { if (_fl.prev==_fl) { return new Note(); } var r:Note=_fl.prev; _fl.prev=r.prev; _fl.prev.next=_fl; return r; }
}

