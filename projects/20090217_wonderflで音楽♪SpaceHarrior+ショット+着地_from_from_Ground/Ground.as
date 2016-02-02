// forked from h_sakurai's 背景を付けざるを得ない from:from:Ground
// forked from ABA's forked from: 音楽を付けざるを得ない from:from:Ground
// forked from keim_at_Si's 音楽を付けざるを得ない from:from:Ground
// forked from ABA's Ground
// Ground.as
//  Display a 3d ground surface and pillars.
//  Control: Arrow keys or [WASD] keys. [Z] or [Shift] key to shot.
package
{
  import flash.display.Sprite;
  import flash.display.BitmapData;
  import flash.display.Bitmap;
  import flash.text.TextField;
  import flash.geom.Rectangle;
  import flash.events.Event;
  import flash.events.KeyboardEvent;
  import flash.events.SampleDataEvent;
  import flash.media.Sound;
  import flash.geom.Matrix;
  import flash.geom.ColorTransform;
  [SWF(width="465", height="465", backgroundColor="0x000000", frameRate="30")]
  public class Ground extends Sprite
  {
    private const SCREEN_WIDTH:int = 465;
    private const SCREEN_HEIGHT:int = 465;
    private const COUNT:int = 512;
    private const NEAR_PLANE_DIST:Number = 1;
    private const PROJECTION_RATIO:Number = 250;
    private const LOD_RATIO:Number = 1.05;
    private const LOD_START_COUNT:Number = 16;
    private const PILLARS_COUNT:int = 64;
    private const WIRE_WIDTH:int = 2;
    private const HAR_SPEED:Number = 11;
    private const BACK_R:int = 210, BACK_G:int = 0, BACK_B:int = 240;
    private var buffer:BitmapData;
    private var left:Boolean, up:Boolean, right:Boolean, down:Boolean, shot:Boolean;
    private var rect:Rectangle;
    private var degs:Array;
    private var index:int;
    private var offset:Number;
    private var gys:Array, gzs:Array, gcs:Array, gas:Array, gIndices:Array;
    private var gCount:int;
    private var sightX:Number, sightY:Number;
    private var pillars:Array;
    private var pillarRect:Rectangle;
    private var harX:Number, harY:Number;
    private var wireRect:Rectangle;
    private var _sound:Sound;
    private var _sequencer:Sequencer;
    private var _module:TinySiOPM;
    private var scoreText:TextField;
    private var score:int;

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
        p.x = (Math.random() * 2.0 - 1.0) * 200;
        p.z = Math.random() * COUNT;
        p.width = 2;
        p.height = 10 + Math.random() * 15;
        pillars.push(p);
      }
      index = 0;
      offset = 0;
      sightX = sightY = 0;
      harX = harY = 0;
      wireRect = new Rectangle;
      initializeSound();
      _sound.play();
      stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
      stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
      addEventListener(Event.ENTER_FRAME, onEnterFrame);

      score = 0;
      scoreText = new TextField();
      with(scoreText) {
        width = 300;
        height = 300;
        multiline = true;
        textColor = 0xffffff;
        text="SCORE 0000000000";
      }
      addChild(scoreText);
      initBackGround();
    }

    private function onEnterFrame(evt:Event):void
    {
      score += 1;
      drawBackGround();
      goForward(3.3);
      drawGroundAndPillars();
      drawShots();
      updateHar();
      Shot.updateAll();
      updateScore();
    }

    private function updateScore():void
    {
      var txt:String = "";
      txt = "" + score;
      while(txt.length < 10) txt = "0" + txt;
      scoreText.text = "SCORE " + txt;
    }

    private var bgMatrix:Matrix;
    private var bgBuffer:BitmapData;
    private var bgRect:Rectangle = new Rectangle();
    private function initBackGround():void
    {
      bgMatrix = new Matrix();
      bgBuffer = new BitmapData(SCREEN_WIDTH, SCREEN_HEIGHT, false, 0);

      var BACK_R :int = 210, BACK_G :int = 128, BACK_B :int = 240;
      var BACK_R2:int = 210, BACK_G2:int = 255, BACK_B2:int = 255;
      var rect:Rectangle = bgRect;
      var i:int;
      rect.x=0;rect.y=0;
      rect.width = SCREEN_WIDTH;
      rect.height = SCREEN_HEIGHT - 180;
      bgBuffer.fillRect(rect, BACK_R * 0x10000 + BACK_G * 0x100 + BACK_B);
      rect.y = rect.height;
      rect.height = 3;
      for (i = 0; i < 60; i++)
      {
        bgBuffer.fillRect(rect,
          int(((60-i)*BACK_R+i*BACK_R2)/60) * 0x10000
          + int(((60-i)*BACK_G+i*BACK_G2)/60) * 0x100
          + int(((60-i)*BACK_B+i*BACK_B2)/60));
        rect.y += 3;
      }
    }
    private function drawBackGround():void
    {
      var y:Number = gys[gCount - 1];
      var z:Number = gzs[gCount - 1];
      var sy:Number = y * NEAR_PLANE_DIST / z * PROJECTION_RATIO + SCREEN_HEIGHT / 2;
      bgMatrix.ty = -SCREEN_HEIGHT + sy + 10;
      buffer.draw(bgBuffer, bgMatrix);
    }

    private function drawGroundAndPillars():void
    {
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
        dv += degs[idx] + sightY * 0.00002;
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
            gcs[gi] = createColor(0x77, 0xbb, 0x77, a);
          else
            gcs[gi] = createColor(0x99, 0x99, 0x99, a);
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

    private var tree:Tree = new Tree();

    private function drawPillar(p:Pillar, si:int, ei:int, i:int):void
    {
      if (p.z >= si && p.z < ei)
      {
        var r:Number = Number(ei - p.z) / (ei - si);
        var y:Number = gys[i] * r + gys[i + 1] * (1 - r);
        var z:Number = gzs[i] * r + gzs[i + 1] * (1 - r);
        var sx:Number = (p.x - sightX) * NEAR_PLANE_DIST / z * PROJECTION_RATIO + SCREEN_WIDTH / 2;
        var sy:Number = y * NEAR_PLANE_DIST / z * PROJECTION_RATIO + SCREEN_HEIGHT / 2;
        var sh:Number = NEAR_PLANE_DIST / z * PROJECTION_RATIO;
//*
        tree.matrix.tx = sx;
        tree.matrix.ty = sy-sh*10;
        tree.matrix.a = sh/20;
        tree.matrix.d = sh/10;

        var ct:ColorTransform = new ColorTransform();
        ct.redOffset = ct.blueOffset = ct.greenOffset = 192-gas[i]*3/4;
        buffer.draw(tree.canvas, tree.matrix, ct);
//*/
/*
        for (var j:int = 0; j < 5; j++)
        {
          pillarRect.x = sx - sh * p.width * 2 / 5 * j;
          pillarRect.y = sy - sh * p.height;
          pillarRect.width = sh * p.width * 2 / 5;
          pillarRect.height = sh * p.height * 2;
          buffer.fillRect(pillarRect, createColor(0x77 + 0x11 * j, 0x77 + 0x11 * j, 0xcc, gas[i]));
        }
//*/
      }
    }

    private function drawShots():void
    {
       for each (var s:Shot in Shot.displayList) drawShot(s);
    }

    private function drawShot(s:Shot):void
    {
      var sh:Number = NEAR_PLANE_DIST / s.z * PROJECTION_RATIO;
      var sx:Number = (s.x - sightX) * sh + SCREEN_WIDTH * 0.5;
      var sy:Number = s.y * sh + SCREEN_HEIGHT * 0.5;
      pillarRect.x = sx - sh*6;
      pillarRect.y = sy - sh*6;
      pillarRect.width = sh*12;
      pillarRect.height = sh*12;
      buffer.fillRect(pillarRect, createColor(0xcc, 0x77, 0x77, 256-s.z*0.5));
    }

    private function createColor(r:int, g:int, b:int, a:int):int
    {
      return int((r * a + BACK_R * (256 - a)) / 256) * 0x10000 +
             int((g * a + 230 * (256 - a)) / 256) * 0x100 +
             int((b * a + BACK_B * (256 - a)) / 256);
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

    private function updateHar():void
    {
      if (right && harX < SCREEN_WIDTH / 2 - 20)
        harX += HAR_SPEED;
      if (left && harX > -SCREEN_WIDTH / 2 + 20)
        harX -= HAR_SPEED;
      if (up && harY < SCREEN_HEIGHT / 2 - 40)
        harY += HAR_SPEED;
      if (down && harY > -SCREEN_HEIGHT / 2 + 40)
        harY -= HAR_SPEED;
      sightX = harX * 0.4;
      sightY = harY * 0.6;
      var landing:Boolean = (harY >= SCREEN_HEIGHT / 2 - 40);
      var hx:int = harX + SCREEN_WIDTH / 2;
      var hy:int = harY + SCREEN_HEIGHT / 2;
      rect.x = hx - 12;
      rect.y = hy - 30;
      rect.width = 20;
      rect.height = 40;
      drawWireBox(rect, 0xdd7777);
      rect.x++;
      drawWireBox(rect, 0xaa4444);
      rect.x = hx - 14;
      rect.y = hy - 45;
      rect.width = 16;
      rect.height = 20;
      drawWireBox(rect, 0xdddd77);
      rect.x++;
      drawWireBox(rect, 0xaaaa44);
      rect.x = (landing && (index&16)==0)?(hx + 3):(hx - 20);
      rect.y = hy + 5;
      rect.width = 12;
      rect.height = 40;
      drawWireBox(rect, 0x77dddd);
      rect.x++;
      drawWireBox(rect, 0x44aaaa);
      rect.x = (landing && (index&16)==0)?(hx - 20):(hx - 1);
      rect.y = hy + 10;
      rect.width = 15;
      rect.height = 25;
      drawWireBox(rect, 0x77dddd);
      rect.x++;
      drawWireBox(rect, 0x44aaaa);
      rect.x = hx - 1;
      rect.y = hy - 12;
      rect.width = 16;
      rect.height = 16;
      drawWireBox(rect, 0xee4444);
      rect.x++;
      drawWireBox(rect, 0xbb2222);

      if (shot && (index&3)==0) {
        Shot.alloc().reset(harX*(0.4+0.12), harY*0.12, 1);
      }
    }

    private function drawWireBox(rect:Rectangle, color:int):void
    {
      wireRect.x = rect.x;
      wireRect.y = rect.y;
      wireRect.width = rect.width;
      wireRect.height = WIRE_WIDTH;
      buffer.fillRect(wireRect, color);
      wireRect.y = rect.y + rect.height - WIRE_WIDTH;
      buffer.fillRect(wireRect, color);
      wireRect.y = rect.y;
      wireRect.width = WIRE_WIDTH;
      wireRect.height = rect.height;
      buffer.fillRect(wireRect, color);
      wireRect.x = rect.x + rect.width - WIRE_WIDTH;
      buffer.fillRect(wireRect, color);
    }

    private function onKeyUp(evt:KeyboardEvent):void
    {
      switch (evt.keyCode)
      {
      case 0x25:
      case 0x41:
        left = false;
        break;
      case 0x26:
      case 0x57:
        up = false;
        break;
      case 0x27:
      case 0x44:
        right = false;
        break;
      case 0x28:
      case 0x53:
        down = false;
        break;
      case 0x10:
      case 0x5a:
        shot = false;
        break;
      }
    }

    private function onKeyDown(evt:KeyboardEvent):void
    {
      switch (evt.keyCode)
      {
      case 0x25:
      case 0x41:
        left = true;
        break;
      case 0x26:
      case 0x57:
        up = true;
        break;
      case 0x27:
      case 0x44:
        right = true;
        break;
      case 0x28:
      case 0x53:
        down = true;
        break;
      case 0x10:
      case 0x5a:
        shot = true;
        break;
      }
    }

    private function initializeSound():void
    {
      var A:String,B:String,C:String,D:String,E:String,F:String,G:String,H:String,X:String;
      var M1:String="l2[f6ee16>g4a4<f6ee16>a+<crrf6ee16d4e4f16g+6g6f4]";
      var M2:String="[e20>l4eg<d|c+12>a+a10gf2ef2d6el3fef2gfg2a12g+4<f8d8]";
      var M3:String="c+16l2rec+>a+agfed12e4l3fef2gfg2a12g2<";
      A ="$@11s8o6l2[[c12cc18|c10crc18]|c10<crc18]dddrrdrcr16> [[s6"+M1+M2+M3+"|g10l1gab<cdefgl2o7]g18|";
      B ="$@7s6o5l2[4e12ef18|f10fre18]fffrrfrer16 [[l2s6v6[[c6>brr<d6crr>|b<crrc6>a+rr<d6crr>a+<crr]b4<c4c10dedd6c6d4]";
      B+="s2l4[e28dc+16>a+8ag<d16c8d8|c16d8f8]c14g18]|";
      C ="$@7s6o5l2[4c12cc18|c10crc18]dddrrdrcr16> [[l2s6v6[[g6grrg6grrggrr]8a6arra6al4raaf10l6ag+g+f4l2]";
      C+="s2[l32gef|l16fg+]f14g18]|";
      D ="$@7s6o5l2k0[4g12ga18|g+10g+rg18]g+g+g+rrg+rgr16 [[v6o6k2"+M1+M2+M3+"|g10l1gab<cdefgl2o7]g18|";
      E ="$@1s16l2o3[56c<c>]<cccrrcrc>r16 [[[[8c<c>]>[8a+<a+>][7a<a>]g<g>[8f<f>]|<]";
      E+="[[8e<e>][8a<a>][8d<d>]|[8f<f>]][4f<f>]g<g>a<a>a+<a+>b<b]|";
      F ="$v10@3s32o0k4l4r116cr[4c1][12r4c4]l2cccl1ccc2l2crcrr[12c1] [[l4[32rc][30rc]ccc2c2l1cccc]|";
      G ="$v4@3s64o0l1[224d]r32 [[1024d]|[124drdd]r16]";
      H ="$v16w32s48o4l4[56c]l2cccl1<gec2>l2crcrrl1<[4g][4e][4c]> [l8[128c]|";
      A+=">r256[v6s0a18s2l2v4cdv5ev6gev5ds0c20s2v6g>a<cv5e>a<cs0d22s1v6c4>b4<c4>bagar24<]]";
      X ="[aagar14|eee6]fff6bbab";
      B+="l2s12["+X+"r14ggg6aagar24]["+X+"r12s4g4g4g4s12aaga|r24]r10aa4bb6]";
      X ="eeder14>ab<c6ffefr14>ab<c6ggfg";
      C+="l2s12<["+X+"r14>b<cd6eeder24]["+X+"r12s4>b4<c4d4s12eede|r24]r10ff4gg6>]";
      D+="l2s12>[4[cc>b<cr24]ddcdr24cc>b<c|r24]r10cc4dd6]";
      E+=">[4[8a<a>][8f<f>][8g<g>]|[8a<a>]][4a<a>]rff4gg6<]";
      F+="[l8[8rc6|r14c4]|r2l4rcrc]c1c3l2cc4ccl1cccc]";
      H+="[l3[8v16cc1c2c2r8|ccc2r2c1v8c1r4]|l1ccccrcrcrrccr2cr]l2rcc4ccl1<gec>g]";
      _sound = new Sound();
      _sound.addEventListener("sampleData", _onSoundStream);
      _module = new TinySiOPM(8192, _onSoundFrame);
      _sequencer = new Sequencer(4, [A,B,C,D,E,F,G,H]);
    }

    private function _onSoundFrame():void
    {
      _sequencer.onSoundFrame();
    }

    private function _onSoundStream(e:SampleDataEvent):void
    {
      var out:Vector.<Number> = _module.render();
      for (var i:int=0; i<8192; i++) {
        e.data.writeFloat(out[i]);
        e.data.writeFloat(out[i]);
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

class Shot
{
  static private const SHOT_SPEED:Number = 30;
  static private const SHOT_Z_LIMIT:Number = 512;
  static private var _freeList:Array=[];
  static public var displayList:Array=[];
  static public function alloc():Shot {
    return _freeList.pop()||new Shot();
  }
  static public function updateAll():void {
    displayList = displayList.filter(function(e:*, i:int, a:Array):Boolean{
      return e.update();
    });
  }

  public var x:Number;
  public var y:Number;
  public var z:Number;
  public function reset(x_:Number, y_:Number, z_:Number) : Shot {
    x=x_; y=y_; z=z_;
    displayList.push(this);
    return this;
  }
  public function free() : void { 
    _freeList.push(this);
  }
  public function update() : Boolean {
    z+=SHOT_SPEED;
    if (z>SHOT_Z_LIMIT) {
      free();
      return false;
    }
    return true;
  }
}

import flash.display.*;
import flash.geom.Rectangle;
import flash.geom.Matrix;
class Tree{ 
  public var matrix:Matrix = new Matrix();
  public var canvas:BitmapData = new BitmapData(200, 200, true, 0);
  public function Tree() {
    seed = Math.random() *0xfffffff;
    const a:Vector.<Number> = Vector.<Number>([0.05, 0.05, 0.46, 0.47, 0.43, 0.42]);
    const b:Vector.<Number> = Vector.<Number>([0, 0, -0.32, -0.15, 0.28, 0.26]);
    const c:Vector.<Number> = Vector.<Number>([0, 0, 0.39, 0.17, -0.25, -0.35]);
    const d:Vector.<Number> = Vector.<Number>([0.6, -0.5, 0.38, 0.42, 0.45, 0.31]);
    const e:Vector.<Number> = Vector.<Number>([0, 0, 0, 0, 0, 0]);
    const f:Vector.<Number> = Vector.<Number>([0, 1, 0.6, 1.1, 1, 0.7]);
    const N:uint = 6;
    const M:uint = N*25;

    var i:int, j:int, k:int, r:int;
    var x:Number, y:Number, s:Number = 0, t:Number;
    var ip:Vector.<int>    = new Vector.<int>(N);
    var table:Vector.<int> = new Vector.<int>(M);
    var p:Vector.<Number> = new Vector.<Number>(N);

    for (i = 0; i < N; i++)
    {
      p[i] = abs(a[i] * d[i] - b[i] * c[i]);
      s += p[i];
      ip[i] = i;
    }

    for (i = 0; i < N-1; i++) 
    {
      k = i;
      for (j = i + 1; j < N; j++ )
        if (p[j] < p[k]) k = j;
      t =  p[i];  p[i] =  p[k];  p[k] = t;
      r = ip[i]; ip[i] = ip[k]; ip[k] = r;
    }

    r = M;

    for (i = 0; i < N; i++) 
    {
      k = (r * p[i] / s + 0.5) >> 0;
      s -= p[i];
      do
      {
        table[--r] = ip[i];
      }
      while (--k > 0);
    }

    x = y = 0;
    var rect:Rectangle = new Rectangle();
    var w:int;
    const offsetX:int = 50;
    const scale:int = 50;
    const offsetY:int = 100;
    rect.width = 8;
    rect.height = 4;

    for (i = 0; i < 1000; i++) 
    {
      j = table[random() % M];
      t = a[j] * x + b[j] * y + e[j];
      y = c[j] * x + d[j] * y + f[j];
      x = t;
      rect.x = offsetX + x * scale;
      rect.y = offsetY - y * scale;

      if(j > 1) w++; else w = 0;
      if(w > 3)
             if(i % 16 == 0) k = 0xff68AC36;
        else if(i % 4  == 0) k = 0xff326C06;
        else                 k = 0xff143606;
      else                   k = 0xff441111;

      canvas.fillRect(rect, k);
    }

  }
  private var seed:uint;
  private function abs (v:Number):Number {
    if (v < 0) return -v; return v;
  }
  private function random ():uint {
    return seed = seed * 144314351 + 43214141;
  }
}

class Sequencer {
  private var tracks:Array, count:int=Track.speed+1;
  function Sequencer(speed:int, mmls:Array) { Track.speed=speed; mml=mmls; }
  public function onSoundFrame() : void {
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
      for (var i:int=0; i<100; i++) {
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
