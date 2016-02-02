// forked from ABA's UpDownRoad
// UpDownRoad.as
//  Display a 3d updown road with 3d particles.
package
{
  import flash.display.Sprite;
  import flash.display.BitmapData;
  import flash.display.Bitmap;
  import flash.geom.Rectangle;
  import flash.events.Event;
  import flash.events.SampleDataEvent;
  import flash.media.Sound;

  [SWF(width="465", height="465", backgroundColor="0x000000", frameRate="30")]
  public class UpDownRoad extends Sprite
  {
    private const SCREEN_WIDTH:int = 465;
    private const SCREEN_HEIGHT:int = 465;
    private const DRAWN_PARTICLES_MAX_COUNT:int = 2000;
    private const PROJECTION_RATIO:Number = 128;
    private const LOD_DISTANCE:Number = 200;
    private const MAX_DEPTH:Number = 500;
    private const ROAD_SPACING:Number = 5;
    private const ROAD_WIDTH:Number = 64;
    private const ROAD_HEIGHT:Number = 6;
    private const SIGHT_HEIGHT:Number = 30;
    private const BACKGROUND_BOX_SIZE:int = 16;
    private const BACKGROUND_R:int = 0x88;
    private const BACKGROUND_G:int = 0xcc;
    private const BACKGROUND_B:int = 0xff;
    private var buffer:BitmapData = new BitmapData(SCREEN_WIDTH, SCREEN_HEIGHT, false, 0);
    private var rect:Rectangle = new Rectangle;
    private var roads:Vector.<Road> = new Vector.<Road>;
    private var particles:Vector.<Particle> = new Vector.<Particle>;
    private var drawnParticles:Vector.<DrawnParticle> = new Vector.<DrawnParticle>;
    private var dpIndex:int;
    private var viewpoint:Vector3 = new Vector3;
    private var yaw:Number, pitch:Number, roll:Number;
    private var offset:Vector3 = new Vector3;
    private var carPosIndex:Number;
    private var roadIndex:int;

    public function UpDownRoad()
    {
      addChild(new Bitmap(buffer));
      yaw = pitch = roll = 0;
      createRoad();
      for (var i:int = 0; i < DRAWN_PARTICLES_MAX_COUNT; i++)
        drawnParticles.push(new DrawnParticle);
      carPosIndex = roads.length - 10;
      addEventListener(Event.ENTER_FRAME, onEnterFrame);

      _initializeSound();
    }

    private function onEnterFrame(evt:Event):void
    {
      buffer.fillRect(buffer.rect, 0x99ffdd);
      carPosIndex += 1.7;
      if (carPosIndex >= roads.length)
        carPosIndex -= roads.length;
      var cpi:int = carPosIndex;
      var ncpi:int = carPosIndex + 1;
      if (ncpi >= roads.length)
        ncpi -= roads.length;
      var co:Number = carPosIndex - cpi;
      var rp:Vector3 = roads[cpi].pos;
      var nrp:Vector3 = roads[ncpi].pos;
      viewpoint.x += (rp.x * (1 - co) + nrp.x * co - viewpoint.x) * 0.2;
      viewpoint.y += (rp.y * (1 - co) + nrp.y * co - viewpoint.y - SIGHT_HEIGHT) * 0.2;
      viewpoint.z += (rp.z * (1 - co) + nrp.z * co - viewpoint.z) * 0.2;
      var oa:Number = roads[ncpi].angle - roads[cpi].angle;
      oa = normalizeAngle(oa);
      oa = roads[cpi].angle + oa * co - yaw;
      oa = normalizeAngle(oa);
      yaw += oa * 0.1;
      yaw = normalizeAngle(yaw);
      pitch += ((roads[cpi].upDown * (1 - co) + roads[ncpi].upDown * co) * 0.5 - pitch) * 0.2;
      roll += (-oa * 0.7 - roll) * 0.1;
      drawBackground();
      dpIndex = 0;
      for each (var p:Particle in particles)
        drawParticle(p);
      drawnParticles.sort(sortOnZ);
      function sortOnZ(v1:DrawnParticle, v2:DrawnParticle):Number
      {
        if (v1.pos.z < v2.pos.z)
          return 1;
        else if (v1.pos.z > v2.pos.z)
          return -1;
        else
          return 0;
      }
      for (var i:int = 0; i < dpIndex; i++)
      {
        var dp:DrawnParticle = drawnParticles[i];
        rect.x = dp.pos.x - dp.width;
        rect.y = dp.pos.y - dp.height;
        rect.width = dp.width * 2;
        rect.height = dp.height * 2;
        buffer.fillRect(rect, dp.color);
      }
    }

    private function drawParticle(p:Particle):void
    {
      offset.x = p.pos.x - viewpoint.x;
      offset.y = p.pos.y - viewpoint.y;
      offset.z = p.pos.z - viewpoint.z;
      offset.rotationYaw(yaw);
      offset.rotationPitch(pitch);
      offset.rotationRoll(roll);
      if (offset.z < -10 || offset.z > MAX_DEPTH)
        return;
      if (p.detail != null && offset.length < LOD_DISTANCE)
      {
        for each (var pp:Particle in p.detail)
          drawParticle(pp);
        return;
      }
      if (offset.z < 1 || p.width <= 0)
        return;
      var ar:Number = 1.0 - offset.z / MAX_DEPTH;
      if (ar < 0)
        return;
      var dp:DrawnParticle = drawnParticles[dpIndex];
      var zr:Number = 1.0 / offset.z * PROJECTION_RATIO;
      dp.pos.x = offset.x * zr + SCREEN_WIDTH / 2;
      dp.pos.y = offset.y * zr + SCREEN_HEIGHT / 2;
      dp.pos.z = offset.z;
      dp.width = p.width * zr;
      dp.height = p.height * zr;
      dp.color = createColor(p.r, p.g, p.b, 250 * ar);
      dpIndex++;
    }

    private function createColor(r:int, g:int, b:int, a:int):int
    {
      return int((r * a + BACKGROUND_R * (256 - a)) / 256) * 0x10000 +
             int((g * a + BACKGROUND_G * (256 - a)) / 256) * 0x100 +
             int((b * a + BACKGROUND_B * (256 - a)) / 256);
    }

    private function drawBackground():void
    {
      offset.x = 0;
      offset.y = 0;
      offset.z = 99999;
      offset.rotationPitch(pitch);
      var zr:Number = 1.0 / offset.z * PROJECTION_RATIO;
      var bc:int = SCREEN_WIDTH / BACKGROUND_BOX_SIZE + 1;
      var bx:Number, by:Number;
      var vby:Number = BACKGROUND_BOX_SIZE * Math.sin(roll);
      var bh:Number, bby:Number;
      for (var j:int = 0; j < 3; j++)
      {
        switch (j)
        {
          case 0:
          {
            bh = 8;
            bby = 0;
            break;
          }
          case 1:
          {
            bh = 16;
            bby = 16;
            break;
          }
          case 2:
          {
            bh = SCREEN_HEIGHT / 3;
            bby = 48;
            break;
          }
        }
        bx = SCREEN_WIDTH / 2 - BACKGROUND_BOX_SIZE * bc / 2;
        by = offset.y * zr + SCREEN_HEIGHT / 2 - vby * bc / 2 + bby + bh;
        rect.width = BACKGROUND_BOX_SIZE;
        rect.height = bh * 2;
        for (var i:int = 0; i < bc; i++)
        {
          rect.x = bx - BACKGROUND_BOX_SIZE / 2;
          rect.y = by - bh;
          buffer.fillRect(rect, createColor(0x88 - j * 0x33, 0x88 - j * 0x33, 0xff, 255));
          bx += BACKGROUND_BOX_SIZE;
          by += vby;
        }
      }
    }

    private var roadPattern:Array = [20, 0, 0.2, 1, 16, 0, -3, 0, 16, 0, 3, 0, 80, 0.05, 0.05, 1, 90, 0, 0, 0, 80, -0.05, -1.0, 1, 20, 0, 1.75, 1];

    private function createRoad():void
    {
      var r:Road = new Road;
      var a:Number = 0;
      var ud:Number = roadPattern[2];
      r.angle = a;
      r.upDown = ud;
      var c:int;
      var ta:Number, tud:Number;
      var polePattern:int;
      var i:int;
      roadIndex = 0;
      for (i = 0; i < roadPattern.length; i += 4)
      {
        c = roadPattern[i];
        ta = roadPattern[i + 1];
        tud = roadPattern[i + 2];
        polePattern = roadPattern[i + 3];
        for (var j:int = 0; j < c; j++)
        {
          a += (ta - a) * 0.2;
          ud += (tud - ud) * 0.1;
          r.angle += a;
          r.angle = normalizeAngle(r.angle);
          r.upDown = ud;
          addRoadAndPole(r, polePattern);
          r = getNextRoad(r);
        }
      }
      c = Math.sqrt(r.pos.x * r.pos.x + r.pos.z * r.pos.z) / ROAD_SPACING;
      var vrp:Vector3 = new Vector3;
      vrp.x = -r.pos.x / c;
      vrp.y = -r.pos.y / c;
      vrp.z = -r.pos.z / c;
      var va:Number = -r.angle / c;
      var vud:Number = -r.upDown / c;
      for (i = 0; i < c; i++)
      {
        addRoadAndPole(r, polePattern);
        var nr:Road = new Road;
        nr.pos.x = r.pos.x + vrp.x;
        nr.pos.y = r.pos.y + vrp.y;
        nr.pos.z = r.pos.z + vrp.z;
        nr.angle = r.angle + va;
        nr.upDown = r.upDown + vud;
        r = nr;
      }
    }

    private function addRoadAndPole(r:Road, polePattern:int):void
    {
      addRoadParticles(r);
      roads.push(r);
      if (polePattern > 0 && roadIndex % 7 == 0)
      {
        addPoleParticles(r);
      }
      roadIndex++;
    }

    private function getNextRoad(r:Road):Road
    {
      var nr:Road = new Road;
      nr.pos.x = r.pos.x + Math.sin(r.angle) * ROAD_SPACING;
      nr.pos.z = r.pos.z + Math.cos(r.angle) * ROAD_SPACING;
      nr.pos.y = r.pos.y + Math.sin(r.upDown) * ROAD_SPACING;
      nr.angle = r.angle;
      nr.upDown = r.upDown;
      return nr;
    }

    private function addRoadParticles(r:Road):void
    {
      for (var j:int = 0; j < 3; j++)
      {
        var p:Particle = new Particle;
        var ox:Number = Math.cos(r.angle) * ROAD_WIDTH / 3 * 2;
        var oz:Number = -Math.sin(r.angle) * ROAD_WIDTH / 3 * 2;
        p.pos.x = r.pos.x + ox * (j - 1);
        p.pos.y = r.pos.y;
        p.pos.z = r.pos.z + oz * (j - 1);
        p.width = ROAD_WIDTH / 3 * 1.05;
        p.height = ROAD_HEIGHT;
        p.detail = new Vector.<Particle>;
        var pc:int = p.width / p.height + 2;
        ox = Math.cos(r.angle) * p.width / pc * 2;
        oz = -Math.sin(r.angle) * p.width / pc * 2;
        var c:int = 0;
        var i:int;
        var pp:Particle;
        for (i = 0; i < pc; i++)
        {
          pp = new Particle;
          pp.pos.x = p.pos.x + ox * (i - pc / 2);
          pp.pos.y = p.pos.y;
          pp.pos.z = p.pos.z + oz * (i - pc / 2);
          pp.width = pp.height = p.height;
          pp.r = pp.g = pp.b = 190 + Math.random() * 30;
          c += pp.r;
          pp.detail = null;
          p.detail.push(pp);
        }
        p.r = p.g = p.b = c / pc;
        particles.push(p);
        if (roadIndex % 3 == 0 && j != 1)
        {
          pp = new Particle;
          pp.pos.x = p.pos.x + ox * pc / 2 * 1.2 * (j - 1);
          pp.pos.y = p.pos.y - p.height * 0.5;
          pp.pos.z = p.pos.z + oz * pc / 2 * 1.2 * (j - 1);
          pp.width = p.height;
          pp.height = p.height * 0.6;
          pp.r = pp.g = pp.b = 32;
          pp.detail = null;
          particles.push(pp);
        }
      }
    }

    private function addPoleParticles(r:Road):void
    {
      for (var i:int = 0; i < 2; i++)
      {
        var p:Particle = new Particle;
        p.width = 4;
        p.height = 36;
        p.pos.x = r.pos.x - Math.cos(r.angle) * ROAD_WIDTH * (i * 2 - 1) * 1.1;
        p.pos.y = r.pos.y - p.height / 2;
        p.pos.z = r.pos.z + Math.sin(r.angle) * ROAD_WIDTH * (i * 2 - 1) * 1.1;
        p.r = 250; p.g = 60; p.b = 60;
        p.detail = new Vector.<Particle>;
        for (var j:int = 0; j < 8; j++)
        {
          var pp:Particle = new Particle;
          pp.pos.x = p.pos.x;
          pp.pos.y = p.pos.y - j * p.height / 8;
          pp.pos.z = p.pos.z;
          pp.width = p.width;
          pp.height = p.height / 8;
          pp.r = p.r;
          pp.g = p.g;
          pp.b = p.b;
          pp.detail = null;
          p.detail.push(pp);
        }
        particles.push(p);
      }
    }

    private function normalizeAngle(v:Number):Number {
      if (v > Math.PI)
        return v - Math.PI * 2;
      else if (v < -Math.PI)
        return v + Math.PI * 2;
      else
        return v;
    }


    private var _sound:Sound;
    private var _module:TinySiOPM;
    private var _sequencer:Sequencer;

    private function _initializeSound():void {
        var mml:String =""
        mml+="#BS=r28$s10l4[3e8[22e]er<s2c12>s10brg]s1a36g12f+16s12e8[5e]l2egabl4ers2e20";
        mml+="s10[[3e8[22e]er<s2c12>s10brg]e8[15e]gabf+8gae8eeegab";
        mml+="[[<c8[6c]>b8[6b]a8[6a]|g8ggggab]|a8aaaabr]a8[6a]<d8[14d]>]";
        mml+="erer20[8[erer20|erer20]|er28]erer20";
        mml+="[[[<c8[6c]>b8[6b]a8[6a]|g8ggggab]|a8aaaabr]a8[6a]]<d8[14d]>;";
        mml+="@0@o1o2BS; v7@0@i3o4BS;";
        mml+="#BD=r8l4v14s32cc2<v5e2c2>g2v14crl4c$[rcrr[15ccrr]] [[rcrr[15ccrr]]";
        mml+="[rcrr[15ccrr]] [2ccrr]cl2<v6ggggeeeecccc>l4v14c]";
        mml+="rcr20[6[crcr20|crcr20]|cr28][8crcrrccr]crcrrcccr";
        mml+="[4rcrr[15ccrr]] [2ccrr]cl2<v6ggggeeeecccc>l4v14c;";
        mml+="#SN=r8l4v14s12k8cc2k4s32c2c2c6k8s12l8c$k8[14rc]l4ck4ccrk8ccl8c[7rc]r4c4c[5rc]rl2k4ccc8r4k8c8c4c4r8";
        mml+="l8[[[15rc]r4c4c] [k8[13rc]|r4c2c2c4k4l4crccrccl8r] rc[rcr4c4c]c4k4l2s32[3c1c1ccc]r4l8k8s12]";
        mml+="l16[[2rc]|rc4s24k4c4c8s12k8rc4c12]rc4c12k4s32l2[ccc4]k8s12c4c4c8 l8[6[7rc]r4c4c]r16c4c4c8";
        mml+="[4k8[13rc]|r4c2c2c4k4l4crccrccl8r] rc[rcr4c4c]c4k4l2s32[3c1c1ccc]r4l8k8s12;";
        mml+="#CY=r8l8s4v8c+20$l8[3s6p3v16d12s10p5v6[14d]d4]s6v16d12p5v6[3d]p2v12d12p5d16p3v16d44p4d20";
        mml+="[l4[4p5s6v16d12s24p6v6[29d]]l8p5[4s6v16d16s10v8[14d]][4d]p3s4v12c+32]";
        mml+="s64v3l2[512d]v12s6c+8v15c+2r22";
        mml+="l8p5[8s6v16d16s10v8[14d]][4d]p3s4v12c+32;";
        mml+="@0w32o4BD; @3o0SN; @3o0CY;";
        mml+="#GT=r28$l4[3[3[s2e8s12e]ee]ers2b2<c10>brg]s1a36g12f+16s2e40re20";
        mml+="[l4[3[3[s2e8s12e]ee]ers2b2<c10>brg][[s2e8s12e]ee]es1g16f+12e20s12eer";
        mml+="s1l8[<c24c>b24b<d24d>g24g<c24c>b24b|a56b]a64<d64>]";
        mml+="r256s24l4[192e]s12erer20";
        mml+="s1l8[[<c24c>b24b<d24d>g24g<c24c>b24b|a56b]a64]<d64>;";
        mml+="@2@o1o6    GT; @0@i3@o1o4k112GT; p1v5@1@i4o3    GT;";
        mml+="@2@o1o6k112GT; @0@i3@o1o4k224GT; p7v4@1@i4o3k112GT;";
        mml+="#S1=v5r28$o6s6l4e8[4e|r36drdrer]r28[3dr]e8[er36drdr|er]s1c36>b12a12r<erer32d20";
        mml+="s2[[[e32d32|d24crc20d8r]rd28dr|c12>b<rd]g12f+rd";
        mml+="[[er20erdr20dr|dr20drdr12d16]|d24drd24d8]d64d56dr]";
        mml+="v7drdrv1drdr[8[v6drdrv1dv6c+12|v6drdrv1drdr]|drrrv1drrr]drdr20";
        mml+="[[[er20erdr20dr|dr20drdr12d16]|d24drd24d8]d64]d56dr;";
        mml+="#S2=v6r28$o5s6l4g8[4g|r36f+rf+rgr]r28[3f+r]g8[gr36f+rf+r|gr]s1e36e12dr12erer32f+20";
        mml+="s2[[[g32f+32|f+24f+re20f+8r]rf+28f+r|e12drf+]b12brf+";
        mml+="[[gr20grgr20gr|f+r20f+rgr12fgb8]|g24grf+24f+8]g64f+56f+r]";
        mml+="v8grgrv1grgr[8[v6grgrv1gv6g12|v6grgrv1grgr]|grrrv1grrr]grgr20";
        mml+="[[[gr20grgr20gr|f+r20f+rgr12fgb8]|g24grf+24f+8]g64]f+56f+r;";
        mml+="#S3=v6r28$o5s6l4b8[4b|r36ararbr]r28[3ar]b8[br36arar|br]s1a36g12f+12rbrbr32a20";
        mml+="s2>[[[b32a32|a24grg20a8r]ra28ar|g12ara]<<d12d>ra";
        mml+="[[cr20cr>br20br|ar20arbr12b16<]|a56a8<]a64a56ar]<";
        mml+="v8ererv1erer[8[v6ererv1ev6e12|v6ererv1erer]|errrv1errr]erer20";	
        mml+="[[[cr20cr>br20br|ar20arbr12b16<]|a56a8<]a64]a56ar<;";
        mml+="p6@1S1; p2@1S2; @1S3;";
        mml+="#MA=r28$@1s3[l16f+1g19f+d>a12b48l4|f+gargre8r112<]r8<cde36g8el8aea+2b2l4rer32d20";
        mml+="@10[s6l4[>[b8bbbbab<c+2d2r>a24|a8aaaagab8<c>ba8eg]r|<f+16g8f+e24r8]<g16f+12e20>";
        mml+="s3b<d>b<e20re8d16>brgra24gab16 fgb<de24f+gd16cr>b8a52<ef+r";
        mml+="g28f+g8d16grf+12gargrarb16<c+1d3rdr>g16<d+1e7dr>g12<cr>ba64f+64];";
        mml+="#MB=r20@2s1w12o9c64s4w-32o4[4c8]r16s2w6o8c64s4w24o5[5c6]r2s1w-12o4c64s0w-2o5c224";
        mml+="@10s3w0o6l4[8rf+de>gb<d>f+abegaf+de<];";
        mml+="#MB2=r772l4<[4raf+g>b<df+>a<de>ab<d>af+g<]>;";
        mml+="#MC=r16>[s3b<d>b<e20re8d16>brgra24gab16 fgb<de24f+gd16cr>b8a52<ef+r";
        mml+="g28f+g8d16grf+12gargrarb16<c+1d3rdr>g16<d+1e7dr>g12<cr>b|a52>]a64<d64>;";
        mml+="v8o6k-1MAv6MBv8MC; v10o5k1MAv3MB2v10MC; v3p1o6r4MAv4MBv3MC;";

        _module = new TinySiOPM(2048, 1024, _onSoundFrame);
        _sequencer = new Sequencer(2, _expandMML(mml));
        _sound = new Sound();
        _sound.addEventListener("sampleData", _onStream);
        _sound.play();
    }
        
    private function _onSoundFrame() : void {
        _sequencer.onSoundFrame();
    }
        
    private function _onStream(e:SampleDataEvent) : void {
        var moduleOut:Vector.<Number> = _module.render();
        for (var i:int = 0; i<4096; i++) {
            e.data.writeFloat(moduleOut[i]);
        }
    }

    private function _expandMML(mml:String) : Array {
        var split:Array = mml.replace(/\s+/g, "").split(/;/);
        var list:Array = [], macro:* = {};
        var defMacro:RegExp = /^#([_A-Z][_A-Z0-9]*)=?(.*)/m;
        for each (var seq:String in split) {
            var res:* = defMacro.exec(seq);
            if (res) macro[res[1]] = res[2];
            else list.push(seq.replace(/[_A-Z][_A-Z0-9]*/g, function() : String {
                if (!arguments[0] in macro) return "";
                return macro[arguments[0]];
            }));
        }
        return list;
    }
  }
}

class Road
{
  public var pos:Vector3 = new Vector3;
  public var angle:Number, upDown:Number;
}

class Particle
{
  public var pos:Vector3 = new Vector3;
  public var width:Number;
  public var height:Number;
  public var r:int, g:int, b:int;
  public var detail:Vector.<Particle>;
}

class DrawnParticle
{
  public var pos:Vector3 = new Vector3;
  public var width:Number;
  public var height:Number;
  public var color:int;
}

class Vector3
{
  public var x:Number = 0;
  public var y:Number = 0;
  public var z:Number = 0;

  public function rotationYaw(v:Number):void
  {
    var sv:Number = Math.sin(v);
    var cv:Number = Math.cos(v);
    var rx:Number = cv * x - sv * z;
    z = sv * x + cv * z;
    x = rx;
  }

  public function rotationPitch(v:Number):void
  {
    var sv:Number = Math.sin(v);
    var cv:Number = Math.cos(v);
    var ry:Number = cv * y - sv * z;
    z = sv * y + cv * z;
    y = ry;
  }

  public function rotationRoll(v:Number):void
  {
    var sv:Number = Math.sin(v);
    var cv:Number = Math.cos(v);
    var rx:Number = cv * x - sv * y;
    y = sv * x + cv * y;
    x = rx;
  }

  public function get length():Number
  {
    return Math.sqrt(x * x + y * y + z * z);
  }
}




// MML Sequencer
//   http://wonderfl.kayac.com/user/keim_at_Si
//--------------------------------------------------
class Sequencer {
    private var _tracks:Array, _count:int=Track.speed+1;
    function Sequencer(speed:int, mmls:Array=null) { Track.speed=speed; mml=mmls; }
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
        if (list) {
            for each (var seq:String in list) _tracks.push(new Track(seq));
        }
        _count = 0;
    }
}

class Track {
    static public var codeA:int="a".charCodeAt(), nt:Array=[9,11,0,2,4,5,7], speed:int=3;
    public var oct:int, len:int, tl:int, dt:int, cnt:int, seq:String, sgn:int, stac:Array, osc:Osc;
    private var _rex:RegExp=/(@i|@o|[a-gkloprsvw<>[|\]$@])([#+])?(-?\d+)?/g;
    function Track(seq:String) {
        osc = Osc.alloc().reset().activate(false);
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
        for (t=Osc.createTable(5),  i=0; i<16; i++) t[i+16] = (t[i] = log(ft[i]*0.0625)) + 1;         // famtri=2
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

    // reset all oscillators
    public function reset() : void {
        for (var o:Osc=Osc._tm.n; o!=Osc._tm; o=o.inactivate().n) { o.fl = Osc._fl; }
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

