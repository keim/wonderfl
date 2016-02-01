// forked from ABA's forked from: Ground
// forked from ABA's Ground
// Ground.as
//  Display a 3d ground surface and pillars.
package
{
  import flash.display.Sprite;
  import flash.display.BitmapData;
  import flash.display.Bitmap;
  import flash.geom.Rectangle;
  import flash.events.Event;

  import flash.media.Sound;
  import flash.events.SampleDataEvent;

  [SWF(width="465", height="465", backgroundColor="0x000000", frameRate="30")]
  public class Ground extends Sprite
  {
    private const SCREEN_WIDTH:int = 465;
    private const SCREEN_HEIGHT:int = 465;
    private const COUNT:int = 512;
    private const NEAR_PLANE_DIST:Number = 0.6;
    private const PROJECTION_RATIO:Number = 250;
    private const LOD_RATIO:Number = 1.05;
    private const LOD_START_COUNT:Number = 16;
    private const PILLARS_COUNT:int = 32;
    private var buffer:BitmapData;
    private var rect:Rectangle;
    private var degs:Array;
    private var index:int;
    private var offset:Number;
    private var gys:Array;
    private var gzs:Array;
    private var gcs:Array;
    private var gas:Array;
    private var gIndices:Array;
    private var gCount:int;
    private var sightY:Number;
    private var pillars:Array;
    private var pillarRect:Rectangle;

    private var _sound:Sound;
    private var _sequencer:Sequencer;
    private var _module:TinySiOPM;

    public function Ground()
    {
      buffer = new BitmapData(SCREEN_WIDTH, SCREEN_HEIGHT, false, 0);
      var screen:Bitmap = new Bitmap(buffer);
      addChild(screen);
      rect = new Rectangle;
      pillarRect = new Rectangle;
      gys = new Array;
      gzs = new Array;
      gcs = new Array;
      gas = new Array;
      gIndices = new Array;
      var di:Number = 0;
      var did:Number = 1.0;
      gCount = 0;
      while (di < COUNT)
      {
        gys.push(0.0);
        gzs.push(0.0);
        gcs.push(int(0));
        gas.push(int(0));
        gIndices.push(int(0));
        if (di > LOD_START_COUNT)
          did *= LOD_RATIO;
        di += did;
        gCount++;
      }
      var i:int;
      degs = new Array;
      for (i = 0; i < COUNT; i++)
      {
        var d:Number;
        if (i < COUNT / 4)
          d = -0.001;
        else if (i < COUNT / 2)
          d = 0.002;
        else if (i < COUNT / 4 * 3)
          d = -0.003;
        else
          d = 0.004;
        degs.push(d);
      }
      pillars = new Array;
      for (i = 0; i < PILLARS_COUNT; i++)
      {
        var p:Pillar = new Pillar;
        p.x = (Math.random() * 0.9 + 0.1) * 200;
        if (Math.random() < 0.5)
          p.x *= -1;
        p.z = Math.random() * COUNT;
        p.width = 2;
        p.height = 10 + Math.random() * 15;
        pillars.push(p);
      }
      index = 0;
      offset = 0;
      sightY = 0;
      addEventListener(Event.ENTER_FRAME, onEnterFrame);
      
      var A:String,B:String,C:String,D:String,E:String,F:String,G:String,H:String;
      var M1:String="[f6ee16>g4a4<f6ee16>a+<crrf6ee16d4e4f16g+6g6f4]";
      var M2:String="[e20>l4eg<d|c+12>a+a10gf2ef2d6el3fef2gfg2a12g+4<f8d8]";
      var M3:String="c+16l2rec+>a+agfed12e4l3fef2gfg2a12g2<g10l1gab<cdefgl2o7";
      A ="@11s8o6l2[[c12cc18|c10crc18]|c10<crc18]dddrrdrcr16> [s6"+M1+M2+M3+"]";
      B ="@7l2[4e12ef18|f10fre18]fffrrfrer16 [l2s6v6[[c6>brr<d6crr>|b<crrc6>a+rr<d6crr>a+<crr]b4<c4c10dedd6c6d4]";
      B+="s2l4[e28dc+16>a+8ag<d16c8d8|c16d8f8]c14g18]";
      C ="@7l2[4c12cc18|c10crc18]dddrrdrcr16 >[l2s6v6[[g6grrg6grrggrr]8a6arra6al4raaf10l6ag+g+f4l2]";
      C+="s2[l32gef|l16fg+]f14g18]";
      D ="@7l2[4g12ga18|g+10g+rg18]g+g+g+rrg+rgr16 [v6o6k2"+M1+M2+M3+"]";
      E ="@1s14l2o3[56c<c>]<cccrrcrc>r16 [[[8c<c>]>[8a+<a+>][7a<a>]g<g>[8f<f>]|<]";
      E+="[[8e<e>][8a<a>][8d<d>]|[8f<f>]][4f<f>]g<g>a<a>a+<a+>b<b]";
      F ="v10@3s32o0k4r116cr[4c1][12r4c4]l2cccl1ccc2l2crcrr[12c1] [[32r4c4] [30r4c4]c4c4c2c2l1cccc]";
      G ="v4@3s64o0l1[224d]r32 [1024d]";
      H ="v16w32s48o4[56c]l2cccl1<gec2>l2crcrrl1<[4g][4e][4c]> l8[128c]";
      _sound = new Sound();
      _sound.addEventListener("sampleData", _onSoundStream);
      _module = new TinySiOPM(8192, _onSoundFrame);
      _sequencer = new Sequencer(4, [A,B,C,D,E,F,G,H]);
      _sound.play();
    }
    
    private function _onSoundFrame():void
    {
      _sequencer.onSequence();
    }
    
    private function _onSoundStream(e:SampleDataEvent):void
    {
      var out:Vector.<Number> = _module.render();
      for (var i:int=0; i<8192; i++) {
        e.data.writeFloat(out[i]);
        e.data.writeFloat(out[i]);
      }
    }

    private function onEnterFrame(evt:Event):void
    {
      buffer.fillRect(buffer.rect, 0);
      goForward(2.1);
      var idx:int = index;
      var d:Number = degs[idx];
      var dv:Number = -offset * d;
      var y:Number = 5 - offset * d;
      var z:Number = 1.0 - offset;
      var di:Number = 0;
      var did:Number = 1.0;
      var i:int;
      var gi:int = 0;
      var r:Number;
      for (i = 0; i < COUNT; i++)
      {
        var py:Number = y;
        var pz:Number = z;
        dv += degs[idx] - sightY * 0.00002;
        y += dv;
        z += 1.0;
        if (i > di)
        {
          r = Number(i) - di;
          gys[gi] = py * r + y * (1 - r);
          gzs[gi] = pz * r + z * (1 - r);
          var a:int = 255 - int(i * 255 / COUNT);
          gas[gi] = a;
          if (idx % 16 < 8)
            gcs[gi] = createColor(0x66, 0x88, 0x66, a);
          else
            gcs[gi] = createColor(0x77, 0x77, 0x77, a);
          gIndices[gi] = idx;
          gi++;
          if (di > LOD_START_COUNT)
            did *= LOD_RATIO;
          di += did;
        }
        idx++;
        if (idx >= COUNT)
          idx = 0;
      }
      rect.x = 0;
      rect.width = SCREEN_WIDTH;
      var sx:Number;
      var sy:Number;
      var psy:Number = 99999;
      for (i = gCount - 1; i >= 0; i--)
      {
        y = gys[i];
        z = gzs[i];
        sy = y * NEAR_PLANE_DIST / z * PROJECTION_RATIO + SCREEN_HEIGHT / 2;
        if (sy > psy)
        {
          rect.y = psy;
          rect.height = sy - psy;
          buffer.fillRect(rect, gcs[i]);
        }
        if (i < gCount - 1)
        {
          for (var j:int = 0; j < PILLARS_COUNT; j++)
          {
            var p:Pillar = pillars[j];
            if (gIndices[i] > gIndices[i + 1])
            {
              drawPillar(p, gIndices[i], gIndices[i + 1] + COUNT, i);
              drawPillar(p, gIndices[i] - COUNT, gIndices[i + 1], i);
            }
            else
            {
              drawPillar(p, gIndices[i], gIndices[i + 1], i);
            }
          }
        }
        psy = sy;
      }
    }

    private function drawPillar(p:Pillar, si:int, ei:int, i:int):void
    {
      if (p.z >= si && p.z < ei)
      {
        var r:Number = Number(ei - p.z) / (ei - si);
        var y:Number = gys[i] * r + gys[i + 1] * (1 - r);
        var z:Number = gzs[i] * r + gzs[i + 1] * (1 - r);
        var sx:Number = p.x * NEAR_PLANE_DIST / z * PROJECTION_RATIO + SCREEN_WIDTH / 2;
        var sy:Number = y * NEAR_PLANE_DIST / z * PROJECTION_RATIO + SCREEN_HEIGHT / 2;
        var sh:Number = NEAR_PLANE_DIST / z * PROJECTION_RATIO;
        for (var j:int = 0; j < 5; j++)
        {
          pillarRect.x = sx - sh * p.width * 2 / 5 * j;
          pillarRect.y = sy - sh * p.height;
          pillarRect.width = sh * p.width * 2 / 5;
          pillarRect.height = sh * p.height * 2;
          buffer.fillRect(pillarRect, createColor(0x55 + 0x11 * j, 0x55 + 0x11 * j, 0xbb, gas[i]));
        }
      }
    }

    private function createColor(r:int, g:int, b:int, a:int):int
    {
      return int(r * a / 256) * 0x10000 + int(g * a / 256) * 0x100 + int(b * a / 256);
    }

    private function goForward(v:Number):void
    {
      offset += v;
      while (offset >= 1.0)
      {
        offset -= 1.0;
        index++;
        if (index >= COUNT)
          index -= COUNT;
      }
    }
  }
}

class Pillar
{
  public var x:Number;
  public var z:Number;
  public var width:Number;
  public var height:Number;
}






class Sequencer {
  private var tracks:Array, count:int=Track.speed+1;
  function Sequencer(speed:int, mmls:Array) { Track.speed=speed; mml=mmls; }
  public function onSequence() : void {
    if (++count == Track.speed) {
      for each (var tr:Track in tracks) tr.execute();
      count = 0;
    }
  }
  public function set mml(list:Array) : void {
    tracks = [];
    for each (var seq:String in list) tracks.push(new Track(seq));
    count = 0;
  }
}
class Track {
  static public var codeA:int="a".charCodeAt(), nt:Array=[9,11,0,2,4,5,7], speed:int=3;
  public var oct:int, len:int, tl:int, dt:int, cnt:int, seq:String, sgn:int, stac:Array, note:Note;
  private var _rex:RegExp=/([a-gklorsvw<>[|\]$@])([#+])?(\d+)?/g;
  function Track(seq:String) {
    note = new Note(false);
    reset(seq);
  }
  public function reset(seq_:String) : void {
    seq=seq_; oct=5; len=4; tl=256; dt=0; cnt=0; sgn=0; _rex.lastIndex=0; stac=[];
  }
  public function execute() : void {
    if (--cnt <= 0) {
      while (true) {
        var res:* = _rex.exec(seq);
        if (!res) {
          if (sgn) { _rex.lastIndex = sgn; continue; }
          else     { cnt = int.MAX_VALUE; break; }
        }
        var cmd:int = res[1].charCodeAt();
        if (cmd>=codeA && cmd<=codeA+6) {
          cnt = (res[3])?int(res[3]):len;
          if (note.isPlaying()) note.stop();
          note.len = cnt*speed;
          note.tl = tl;
          note.play(((nt[cmd-codeA]+oct*12+((res[2])?1:0))<<4)+dt);
          break;
        } else if (res[1] == 'r') {
          cnt = (res[3])?int(res[3]):len;
          if (note.isPlaying()) note.stop();
          break;
        } else {
          switch(res[1]){
          case 'k': dt  = int(res[3]); break;
          case 'l': len = int(res[3]); break;
          case 'o': oct = int(res[3]); break;
          case 'v': tl  = TinySiOPM.log(int(res[3])*0.0625); break;
          case '<': oct++; break;
          case '>': oct--; break;
          case '@': note.ws = int(res[3]);    break;
          case 's': note.dr = int(res[3])<<2; break;
          case 'w': note.sw = -int(res[3]);   break;
          case '$': sgn = _rex.lastIndex; break;
          case '[': stac.unshift({p:_rex.lastIndex,c:((res[3])?int(res[3]):2),j:0}); break;
          case ']': stac[0].j = _rex.lastIndex; if (--stac[0].c == 0) stac.shift(); else _rex.lastIndex = stac[0].p; break;
          case '|':  if (stac[0].c == 1) { _rex.lastIndex = stac[0].j; stac.shift(); } break;
          }
        }
      }
    }
  }
}


class TinySiOPM {
  private var _output:Vector.<Number>, _bufferSize:int, _frameCallBack:Function;
  private var _pitchTable:Vector.<int> = new Vector.<int>(2048, true);
  private var _logTable:Vector.<Number> = new Vector.<Number>(6144, true);
  
  // Pass the buffer size and the function calls in each frame.
  function TinySiOPM(bufferSize:int=2048, frameCallBack:Function=null) {
    var i:int, j:int, p:Number, v:Number, t:Vector.<int>, ft:Array=[0,1,2,3,4,5,6,7,7,6,5,4,3,2,1,0];
    for (i=0, p=0; i<192; i++, p+=0.00520833333)                            // create pitchTable[128*16]
      for(v=Math.pow(2, p)*12441.464342886, j=i; j<2048; v*=2, j+=192) _pitchTable[j] = int(v);
    for (i=0; i<32; i++) _pitchTable[i] = (i+1)<<6;                         // [0:31] for white noize
    for (i=0, p=0.0078125; i<256; i+=2, p+=0.0078125)                       // create logTable[12*256*2]
      for(v=Math.pow(2, 13-p)*0.0001220703125, j=i; j<3328; v*=0.5, j+=256) _logTable[j+1] = -(_logTable[j] = v);
    for (i=3328; i<6144; i++) _logTable[i] = 0;                             // [3328:6144] is 0-fill area
    for (t=Note.table(10), i=0, p=0; i<1024; i++, p+=0.00613592315) t[i] = log(Math.sin(p));  // sin=0
    for (t=Note.table(10), i=0, p=0.75; i<1024; i++, p-=0.00146484375) t[i] = log(p);         // saw=1
    for (t=Note.table(5),  i=0; i<16; i++) t[i+16] = (t[i] = log(ft[i]*0.0625)) + 1;          // famtri=2
    for (t=Note.table(15), i=0; i<32768; i++) t[i] = log(Math.random()-0.5);                  // wnoize=3
    for (i=0; i<8; i++) for (t=Note.table(4), j=0; j<16; j++) t[j] = (j<=i) ? 192 : 193;      // pulse=4-11
    _output = new Vector.<Number>(bufferSize, true);                        // allocate monoral buffer
    _bufferSize = bufferSize; _frameCallBack = frameCallBack;               // set parameters
  }
  
  // calculate index of logTable
  static public function log(n:Number) : int {
    return (n<0) ? ((n<-0.00390625) ? (((int(Math.log(-n) * -184.66496523 + 0.5) + 1) << 1) + 1) : 2047)
                 : ((n> 0.00390625) ? (( int(Math.log( n) * -184.66496523 + 0.5) + 1) << 1)      : 2046);
  }
  
  // Returns monoral output as Vector.<Number>(bufferSize).
  public function render() : Vector.<Number> {
    var note:Note, rep:int, i:int, imax:int, ph:int, dph:int, lout:int, v:int;
    for (i=0; i<_bufferSize; i++) _output[i] = 0;
    for (imax=1024; imax<=_bufferSize; imax+=1024) {
      if (_frameCallBack!=null) _frameCallBack();
      var terminal:Note = Note._tm;
      for (note=terminal.n; note!=terminal; note=note.step()) {
        dph = _pitchTable[note.pt];
        for (i = imax-1024; i < imax; i++) {
          ph = note.ph>>note.sh;
          lout = note.wv[ph] + note.tl;
          _output[i] += _logTable[lout];
          note.ph = (note.ph+dph)&0x3ffffff;
        }
      }
    }
    return _output;
  }
  
  // note on
  public function noteOn(pitch:int, length:int, vol:Number=0.5, wave:int=0, decay:int=6, sweep:int=0) : Note {
    var note:Note = Note.alloc();
    note.len = length;
    note.tl = log(vol);
    note.ws = wave;
    note.dr = decay<<2;
    note.sw = sweep; 
    return note.play(pitch);
  }
}


class Note {
  static public var _w:Array=[], _s:Array=[], _fl:Note=new Note(), _tm:Note=new Note();
  static public function alloc():Note {if(_fl.p==_fl)return new Note();var r:Note=_fl.p;_fl.p=r.p;r.p.n=_fl;return r.reset();}
  static public function table(b:int):Vector.<int>{_w.push(new Vector.<int>(1<<b,true));_s.push(26-b);return _w[_w.length-1];}
  public function into(x:Note):Note{ p=x.p;n=x;p.n=this;n.p=this;return this; }
  public function step():Note { tl+=dr; pt+=sw; pt&=2047; return (--len==0||tl>3328) ? (stop().n) : n; }
  public var p:Note, n:Note, pt:int, tl:int, sw:int, dr:int, wv:Vector.<int>, sh:int, len:int, ph:int, fl:Note;
  function Note(useFreeList:Boolean=true) { p=n=this; fl=(useFreeList)?_fl:null; reset(); }
  public function set ws(t:int) : void { wv=_w[t]; sh=_s[t]; }
  public function play(pitch:int) : Note { into(_tm); pt=pitch; return this; }
  public function stop() : Note { var r:Note=p; p.n=n; n.p=p; if(fl)into(fl); pt=-1; return r; }
  public function reset() : Note { ph=0; pt=-1; len=0; tl=256; sw=0; dr=24; ws=0; return this; }
  public function isPlaying() : Boolean { return (pt>=0); }
}




