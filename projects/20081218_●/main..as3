package {
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.media.*;
    import flash.text.*;
    
    [SWF(width="465", height="465", backgroundColor="#ffffff", frameRate=30)]
    public class main extends Sprite {
        private var module:TinySiOPM=new TinySiOPM(2048), sound:Sound=new Sound(), channel:SoundChannel;
        private var bshc:Array = ["6060003305300031","0000620000006001","3110011121110010","0000000000000000"];
        private var tone:Array = [[640,3,11,24,-48], [960,4,3,20,0],    [1280,2,3,32,0],   [1024,4,3,8,0]];
        private var pong:Array = [60,62,64,67,69];
        private var pointer:int, frame:int, frameCounter:int, mouseDown:int, bouns:int;
        public function main() {
            stage.addEventListener(Event.ENTER_FRAME,     _onEnterFrame);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
    	    sound.addEventListener('sampleData', _onStream);
            var tf:TextField = new TextField();
            tf.text = "クリックではねる";
            tf.textColor = 0x808080;
            tf.x = 180;
            tf.y = 16;
            addChild(tf);
            channel = sound.play();
            pointer = 0;
            frame = 3;
            frameCounter = 0;
            mouseDown = 0;
            bouns = 0;
        }
        private function _onEnterFrame(event:Event) : void {
            if (mouseDown > 1) {
                addChild(new ball(mouseX, mouseY, mouseDown-2, function(p:int, v:Number) : void { bouns = (p<<5) | int(v*32); }));
                mouseDown = 0;
            }
        }
        private function _onMouseDown(event:MouseEvent) : void {
            mouseDown = 1;
        }
        private function _onStream(e:SampleDataEvent) : void {
            if (++frameCounter == frame) {
                for (var i:int=0; i<4; i++) {
                    var v:int = int(bshc[i].charAt(pointer));
                    if (v) { module.noteOn(tone[i][0], v<<tone[i][1], tone[i][2], tone[i][3], tone[i][4]); }
                }
                if (mouseDown == 1) {
                    var p:int = int(Math.random()*5);
                    module.noteOn(pong[p]<<4, 64, 2, 8);
                    mouseDown = p+2;
                }
                if (bouns > 0) {
                    module.noteOn(pong[bouns>>5]<<4, bouns&31, 2, 8);
                    bouns = 0;
                }
                pointer = (pointer + 1) & 15;
                frameCounter = 0;
            }
            module.buffer(e.data);
        }
    }
}


import flash.events.*;
import flash.display.*;
import flash.geom.*;
class ball extends Shape {
    private var v:Point=new Point(), pitch:int, bound:Function, spring:Boolean;
    function ball(x:int, y:int, p:int, f:Function) {
        graphics.clear();
        graphics.beginFill([0xf08080,0xe0e040,0x80f080,0x40e0e0,0x8080f0][p]);
        graphics.drawCircle(0, 0, 10);
        graphics.endFill();
        addEventListener("enterFrame", _ef);
        this.x = x;
        this.y = y;
        v.x = Math.random() * 10-5;
        v.y = Math.random() * -5-5;
        alpha = 1;
        pitch = p;
        bound = f;
        spring = true;
    }
    private function _ef(e:Event) : void {
        x+=v.x; y+=v.y; v.y+=1; alpha-=0.0078125;
        if (y>360 && v.y>0 && spring) { bound(pitch, alpha); spring=false; }
        if (y>450) { y=900-y; v.y=-v.y*0.7; spring=true; }
        if (x<0 || x>495 || alpha<0.01) { removeEventListener("enterFrame", _ef); parent.removeChild(this); }
    }
}


import flash.utils.ByteArray;
class TinySiOPM {
    private var term:Note, pipe:Vector.<Number>, bufferSize:int;
    private var pitchTable:Vector.<int> = new Vector.<int>(2048, true);      // 128:note * 16:detune
    private var logTable:Vector.<Number> = new Vector.<Number>(6144, true);  // 24:cause * 128:fine *2:p/n
    function TinySiOPM(bufferSize:int=2048) {
        var i:int, j:int, p:Number, v:Number, t:Vector.<int>;
        for (i=0, p=0; i<192; i++, p+=0.00520833333)
            for (v=Math.pow(2, p)*12441.464342886, j=i; j<2048; v*=2, j+=192)
                pitchTable[j] = int(v);
        for (i=0, p=0.0078125; i<256; i+=2, p+=0.0078125) 
            for (v=Math.pow(2, 13-p)*0.0001220703125, j=i; j<3328; v*=0.5, j+=256)
                logTable[j+1] = -(logTable[j] = v);
        for (i=3328; i<6144; i++) { logTable[i] = 0; }
        var famtri:Array = [0,1,2,3,4,5,6,7,6,5,4,3,2,1,0,0,-1,-2,-3,-4,-5,-6,-7,-8,-7,-6,-5,-4,-3,-2,-1,0];
        for (t=Note.createTable(10), i=0, p=0; i<1024; i++, p+=0.00613592315) { t[i] = _logIndex(Math.sin(p)); } // sin=0
        for (t=Note.createTable(10), i=0, p=0.75; i<1024; i++, p-=0.00146484375) { t[i] = _logIndex(p); }        // saw=1
        for (t=Note.createTable(5), i=0; i<32; i++) { t[i] = _logIndex(famtri[i]*0.0625); }                      // famtri=2
        for (t=Note.createTable(15), i=0; i<32768; i++) { t[i] = _logIndex(Math.random()-0.5); }                 // wnoize=3
        for (i=0; i<8; i++) for (t=Note.createTable(4), j=0; j<16; j++) { t[j] = (j<=i) ? 192 : 193; }           // pulse=4-11
        term = new Note();
        pipe = new Vector.<Number>(bufferSize, true);
        for (i=0; i<bufferSize; i++) pipe[i] = 0;
        this.bufferSize = bufferSize;
    }
    private function _logIndex(n:Number) : int {
        return (n<0) ? ((n<-0.00390625) ? (((int(Math.log(-n) * -184.66496523 + 0.5) + 1) << 1) + 1) : 2047)
                     : ((n> 0.00390625) ? (( int(Math.log( n) * -184.66496523 + 0.5) + 1) << 1)      : 2046);
    }
    public function buffer(data:ByteArray) : void {
        var n:Note, rep:int, i:int, imax:int, dph:int, lout:int, v:int;
        for (imax=1024; imax<=bufferSize; imax+=1024) {
            for (n=term.next; n!=term; n=n.next) {
                for (dph=pitchTable[n.pitch], i=imax-1024; i<imax; n.ph=(n.ph+dph)&0x3ffffff, i++) {
                    lout=n.table[n.ph>>n.shift]+n.gain; pipe[i]+=logTable[lout];
                }
                if (!n.inc()) n = n.remove();
            }
        }
        for (i=0; i<bufferSize; i++) { data.writeFloat(pipe[i]); data.writeFloat(pipe[i]); pipe[i]=0; }
    }
    public function noteOn(pitch:int, velocity:int=64, tone:int=0, decay:int=4, sweep:int=0) : void {
        Note.alloc().reset(tone, pitch, _logIndex(velocity*0.0078125), sweep, (decay<<2)).into(term);
    }
}
class Note {
    public var prev:Note, next:Note, ph:int, pitch:int, gain:int, sweep:int, decay:int, table:Vector.<int>, shift:int; 
    function Note() { prev = next = this; }
    public function remove() : Note { var r:Note=prev; prev.next=next; next.prev=prev; into(free); return r; }
    public function into(n:Note) : Note { prev=n.prev; next=n; prev.next=this; next.prev=this; return this; }
    public function inc() : Boolean { gain+=decay; pitch+=sweep; pitch&=2047; return (gain<4000); }
    public function reset(t:int, p:int, g:int, s:int, d:int) : Note { 
        ph=0; pitch=p; gain=g; sweep=s; decay=d<<1; table=waveTable[t]; shift=shiftTable[t]; return this;
    }
    static public var waveTable:Array=[], shiftTable:Array=[];
    static public function createTable(bit:int) : Vector.<int> { 
        var t:Vector.<int>=new Vector.<int>(1<<bit, true); waveTable.push(t); shiftTable.push(26-bit); return t;
    }
    static public var free:Note = new Note();
    static public function alloc() : Note {
        if (free.prev==free) return new Note();
        var r:Note=free.prev; free.prev=r.prev; free.prev.next=free; return r;
    }
}


