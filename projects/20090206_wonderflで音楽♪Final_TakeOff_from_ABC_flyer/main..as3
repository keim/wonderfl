// forked from keim_at_Si's ABC flyer
// forked from keim_at_Si's ABC ground
// The gradation colors are refered from psyrak's BumpyPlanet and nemu90kWw's 水平線.
// arrows or [wasd] to move, [shift/x/m] to accel.
//--------------------------------------------------------------------------------
package {
    import flash.display.*;
    import flash.events.*;
    import flash.media.*;

    [SWF(width='465', height='465', backgroundColor='#103860', frameRate='30')]
    public class main extends Sprite {
        function main() {
            // keyboard mapper
            _key = new KeyMapper(stage);
            _key.map(0,37,65).map(1,38,87).map(2,39,68).map(3,40,83).map(4,17,90,78).map(5,16,88,77);
            
            // rendering engine
            _shape3d.visible = false;
            addChild(_shape3d);
            
            // background
            _base.x = 232.5;
            _base.y = 232.5;
            _landscape.rotationX = -85;
            _landscape.scaleX = 10;
            _landscape.scaleY = 8;
            _landscape.x = -1024-_base.x;
            _landscape.y = 280-_base.y;
            _landscape.z = 1800;
            _sky.scaleX = 5;
            _sky.scaleY = 5;
            _sky.x = -1520-_base.x;
            _sky.y = -1400-_base.y;
            _sky.z = 1800;
            _base.addChild(_landscape);
            _base.addChild(_sky);
            addChild(_base);
            
            // rendering layer
            addChild(new Bitmap(_screen));
            
            // initialize
            _flyer = new Flyer(0, 0, 100);
            _pitch = 0;
            _roll = 0;
            
            // event listener
            addEventListener("enterFrame", _onEnterFrame);
            
            _startMusic();
        }

        private function _onEnterFrame(e:Event) : void {
            // move
            var inkey:int = _key.flag;
            _roll  += ((inkey & 1)      - ((inkey & 4)>>2))*5 - _roll*0.1;
            _pitch += (((inkey & 2)>>1) - ((inkey & 8)>>3))*2 - _pitch*0.1;
            _globalVel.z += 0.5 - _globalVel.z * ((inkey & 32) ? 0.03 : 0.06);
            _globalVel.x = (_roll) * 0.1 - 0.5;
            _base.rotationX = _pitch;
            _base.rotationZ = _roll;
            
            // update
            _landscape.update();
            _flyer.update();
            
            // rendering
            _screen.fillRect(_screen.rect, 0);
            _flyer.render();
        }
        
        // sound
        private var _sound:Sound = new Sound();
        private var _sequencer:Sequencer = new Sequencer();
        private var _module:TinySiOPM = new TinySiOPM(2048, 1024, _sequencer.onSoundFrame);
        
        private function _startMusic() : void {
            var mml:String = "";
            mml += "#BS=l2<ef+abaf+>[2a8[2a4<a>araa12<gara>a4<a>araa6arr<ef+>a4a4<a>araa6<arrgara>a4<a>ara";
            mml += "<ef+abaf+>a8a4<a>araa12<gara>a4<a>ara<<c+de4dc+>a4>a4a4<a>araa6<arrgara>a4f+4<f+r>g4<gr>g+4a8]|";
            mml += "[2[2a4<a>araa6<arrga>g4g4<g>grgg16b4b4<b>brbb6<brrd8<dr6>e8<errrde>>|a4]";
            mml += "l4g12g<g>gr<d8<dr>d<ef+r>>a8[11a]<gagd>g12g<g>gr<d8<dr>d<ef+r>>a8[23a]a16g8f+8";
            mml += "[4l2[6a4<ar>]g4<gr>f+4<f+r>]|l4[2f8f2r2g8<g2r2d>gg8<g2r2>a8<age>f8f2r2g8<g2r2>ga8<e6g2a<c>bg8>]f8f2r2g48";
            mml += "a8a<a2>a6a6a6a8aa2<a2>aa6a6g2a6[2aa8a6a6a8]l2]";
            mml += "[2l4[4f8f2r2g8<g2r2d>gg8<g2r2>a8<age>f8f2r2g8<g2r2>ga8<e6g2a<c>bg8>]f8f2r2|g52]g48l2];";
            mml += "@0@o1o4v6s16BS; @0@i3@o1o2s8BS; v7@0@i3o4s8BS;";
            mml += "#BD=r16[2v10p4[3l4[3rcr2cc2crrc]|rcr2cc2l2v8<p1ggp5cc>l4p4gv10c]l3v8<p1ggg2p3eee2p5ccc2>l4v10p4rc[3rcr2cc2|crrc]c6c10v10crcr|v8<c6c10>v10";
            mml += "[2l4[2[2ccr2cc2c[2r10c2c]r12]][2crrcrrcrrcrcr12crcrrcrrrcrrrcrcr]rcccl3v8<ggg2ccc2>l4v10cr12crcr";
            mml += "[4cr12cr8crcr8c8c8]|[4cr8crcrccr8crcr8]cr8cr8[2cr12]cc[3rcr6c2crrc]r4l2v8<ggggeeeecccc>ggv10]";
            mml += "[2[8cr8crcrccr8crcr8]cr8cr8[2cr12]cc]]rcrcr;";
            mml += "#SN=r16[2v15p3[3l8[6rc]|rcl2p1ccp5ccp4c8]l3p1ccc2p3ccc2p5ccc2p3ccc2l8[4rc]rcc6c10|c4c4rc6c10";
            mml += "[2[16rc][2l8rrcr4cr12crrcrcl4rccc|c2cc2c8]ccccccccl3ccc2ccc2l8c16cc";
            mml += "[4rcrcrc4c2c2cc]|l8[7rc]l4cccrl8[6rc]rl2cc6ccccc4cc10l8c[3rc][6rc]r4l2[14c]l8]";
            mml += "[2[2l8[7rc]l4cccrl8[6rc]rl2cc6ccccc4c|c2]c10l8c[3rc]]]c8l2[4c]c4c8c32;";
            mml += "#CY=r12[2l2[2s4v15p3d16s99v4p5[56c+]][2[3s4v15p3d16s99v4p5[8c+]]|[16c+]]|[16c+]";
            mml += "[2l4[2s4v15p3d16s32v5p5[28c+]]s4v15[2r4p3d28p6c+20p3d12|p6c+64]p6c+100p3d16s5[5p1c+8p6|d56]d8";
            mml += "|[2s4v15p3c+16l2v6p5[14s99c+c+s8c+4]]s4v15p6c+12p2d16v6p4s8l8[3c+|r]";
            mml += "l2[2s99[14v6c+v4c+]|s4v6d8]][2[4s4v15p3c+16l2v6p5[14s99c+c+s8c+4]]s4v15p6c+12p2d16v6p4s8l8[2c+r]|r4]]";
            mml += "s6v15p3r24c+8p6d32;";
            mml += "#CB=r16[2l8r256[32g]|[2r832|[32g][24g]][64g][8g][64g][8g]];";
            mml += "#RD=r16l8r512[2r256[2r4l8[7e]r4r64]r64[4r4[6e]r12]|r4[31e]r4r192][2r4[31e]r4]r64[2r4[31e]r4]r64;";
            mml += "@0s32w32o4BD; @3o0k6s12SN; @3o0CY; @2v8s99o6k120@o1CB;@0v8s64o6@i3p6CB; @2v10s4o6k123@o1RD;@0v5s20o5@i5p2RD;";
            mml += "#GT=r12[2l32s1o4fga56<c8>fga20<c6c2r8>a8<c6c2r4d8> fga20<g+1a5g+1a5g+1a3a28>fga20g+1a5g+1a5g+1a3|w1a28";
            mml += "w0[2[2a32g36b28<d16e16>][2g32<d32>d4r4|s8a4s1a52] s8a4s1a12s8a4s1a40g32a16g8f+8l4[4s4rarra8rs2a8a12g8f+8]";
            mml += "|[2f8rg20g8ra8s4ages2f8rg12ra36]f8rg52s4aar8<s2c16>s4aar<drs2c12>s4aar8<s2c8rd32>]";
            mml += "[4f8rg20g8ra8s4ages2f8rg12ra36]f8rg52 [4f8rg20g8ra8s4ages2|r8f8rgra36]f8rg12ra36f8rg48]a20l4grs7w2a32;";
            mml += "@2@o1o6v6k1  GT; @0@i3@o1o4v12k112GT; p7@1@i4o3v6    GT;";
            mml += "@2@o1o6v6k113GT; @0@i3@o1o4v12k224GT; p1@1@i4o3v6k112GT;";
            mml += "@2@o1o7v5k1  GT; @0@i3@o1o5v10k112GT; p4@1@i4o4v6    GT;";
            mml += "#S1=r16[2v8s5o6[2[2l2rrccrcrcc16rrddrdrdd16rreereree12|c+dc+6>a6e8c+6r6<]|l4arar24]rrarar|r20";
            mml += "l4v6[2c+32d36d28d16e16c+24e8d36d28d16e16r20[2g12f+32f+ree56|r16]l2[5s64[6>a>a<a<a]s5g8f+8]";
            mml += "|>l4[2a8rg16rg8ra16ra8rg16a36]a8rg52l2s64[16a>a<|a<a>]l4s5<] >l4[4a8rg16rg8ra16ra8rg16a36]a8rg52 l4[2a8rg16rg8ra16rr8a8rgra36]";
            mml += "l2>gab<c>ab<cd>b<cdecdefdefgefgafgabgab<c>ab<cd>b<cdecdefdefgefgafgabgab<c>ab<cdl4d+1e11d12cdd+1e3dc>a8reab8rb16a20egar<c12>b52]";
            mml += "r12gr6ar6v3ar6v2ar6v1ar6ar6;";
            mml += "#S2=r16[2v8s5o5[2[2l2rraararaa16rrbbrbrbb16<rrc+c+rc+rc+c+12|r4>a6e6c+8>a6<r6]|l4ere>r24]rrerer|r20>";
            mml += "l4v6[2[2a32b36b28a16b16]<d32[2d32drc+c+56|d28][5r48d8d8] |l4[2c8r>b16rb8r<c16rc8r>b16<c36]c8r>b52r124]";
            mml += "l4[4c8r>b16rb8r<c16rc8r>b16<c36]c8r>b52 l4[4c8r>b16rb8r<c16r|r8c8r>br<c36]c8r>b16<c36>a8rg52]";
            mml += "r12dr6er6v3er6v2er6v1er6er6;";
            mml += "#S3=r16[2v8s5o5[2[2l2rrffrfrff16rrggrgrgg16rraararaa12|r4e6c+6>a8e6<r6]<|l4c+rc+>r24]rrc+rc+r|r20>";
            mml += "l4v6[2[2e32g36f+28f+16g+16]b32[2a32araa56|b28][5r48b8a8] |l4[2f8rd16rd8re16rf8rd16e36]f8rd52r124]";
            mml += "l4[4f8rd16rd8re16rf8rd16e36]f8rd52 l4[4f8rd16rd8re16r|r8f8rdre36]f8rd12re36f8rd52]";
            mml += "r12>br6<c+r6v3c+r6v2c+r6v1c+r6c+r6;";
            mml += "@1k1S1; @1k-1S2; @1S3; @1k-1S1;";
            mml += "#MA=r16s4r508[2l4[2c1c+23dec+24de|d+1e15d12>a<c+1d11c+>arbr<]d+1e11dg+1a11g+arg+rf+rg+r";
            mml += "g+1a51a+1b7<c+>brag+1a43c1c+3ea24c1c+3ea20a+1b7<c+>brag+1a91";
            mml += "[2[3f+1g3]f+1g5f+5r1|e40]a40[3f+1g3]f+1g5f+5r1e40c+1d7c+d6er2c1c+3r>a44";
            mml += "|ab<c2>b2a<d+1e11d16>gg<c>ba16g2f2e12d8ega20ab<c>a<c+1d7>a<d+1e7>a8<d+1e3gega8b<c>a8<cd+1e7dr2cr2>a36<d+1e11d128r48>]";
            mml += "ab<c2>b2a<d+1e11d16>gg<c>ba16g2f2e12d8ega20ab<c>a<c+1d7>a<d+1e7>a8<d+1e3gega8b<c>a8<cd+1e7dr2cr2>a36";
            mml += "<d+1e11d16>gg<c>ba16g2f2e12d8ega20ab<c>a<c+1d7>a<d+1e7>a8<d+1e3gega8b<c>a8<cd+1e3rdr2cr2>a36<d+1e11d52>>";
            mml += ">b1<c3>b1<c3>a2g2a12l3geg2aga2bab2<c>b<c2dcd2l4r8d+1e13c6dc>ba<c20>l1ab<cdefgg+a8l4gfefge8d2c2d>a20cccc>b<cgc8>b1<c19";
            mml += "l2>b<cdecdefdefgefgafgabgab<c>ab<cd>b<cdecdefdefgefgafgabgab<c>ab<cd>b<cdecdefl4f+1g11f12eff+1g3fec8r>a<cd8rd16c20>ab<cre12d52>;";
            mml += "@1v12o6k-1MA; @6v12o5k1MA; @8v4p1o6r4MA;";
            
            _sequencer.mml = _expandMML(mml);
            _sound.addEventListener("sampleData", function(e:SampleDataEvent) : void {
                var i:int, out:Vector.<Number> = _module.render();
                for (i=0; i<4096; i++) e.data.writeFloat(out[i]);
            });
            _sound.play();
        }
        
        private function _expandMML(mml:String) : Array {
            var split:Array = mml.replace(/\s+/g, "").split(/;/);
            var list:Array = [], macro:* = {}, charA:int = "A".charCodeAt();
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

import flash.display.*;
import flash.geom.*;
import flash.events.*;
import flash.filters.*;
import mx.utils.Base64Decoder;

// internal variables
//----------------------------------------------------------------------------------------------------
var _key:KeyMapper;
var _models:ModelManager = new ModelManager();

var _flyer:Flyer;
var _landscape:Landscape = new Landscape(256, 256);
var _sky:Sky = new Sky();
var _base:Sprite = new Sprite();

var _light:Light = new Light(-1,-1,-1);
var _shape3d:Shape3D = new Shape3D();
var _screen:BitmapData = new BitmapData(465, 465, true, 0);
var _mat2d:Matrix = new Matrix(1,0,0,1,232,232);
var _pitch:Number, _roll:Number, _globalVel:Vector3D = new Vector3D();
var _homingAbility:Number = 0.1;

// Key mapper
//----------------------------------------------------------------------------------------------------
class KeyMapper {
    public  var flag:int = 0;
    private var _mask:Vector.<int> = new Vector.<int>(256, true);
    
    function KeyMapper(stage:Stage) : void { 
        stage.addEventListener("keyDown", function(e:KeyboardEvent):void { flag |= _mask[e.keyCode]; });
        stage.addEventListener("keyUp",   function(e:KeyboardEvent):void { flag &= ~(_mask[e.keyCode]); });
    }
    
    public function map(bit:int, ...args) : KeyMapper {
        for (var i:int=0; i<args.length; i++) { _mask[args[i]] = 1<<bit; }
        return this;
    }
}

// Resource
//----------------------------------------------------------------------------------------------------
class ModelManager {
    public var mdlFlyer:Model;
    public var mdlFire:Model;
    public var texFire:Vector.<BitmapData> = new Vector.<BitmapData>(8, true);
    private var _dec:Base64Decoder = new Base64Decoder();
    private const SCALE:Number = 0.1;
    function ModelManager() {
        var i:int, vdata:String="", idata:String="", shp:Shape=new Shape(), mtx:Matrix=new Matrix();
        // Flyer model
        vdata += "iN94Art14Ar5234tF43zutz4Au503zwR4HwxNz4Awt030zN34Ar524ItF44Mu504MwR4IQwt04LiN94Aft73Yft93AtF43znt53Q";
        vdata += "mt93AwR4HwvR6nmtN6nQvSB3mmuD4AmuF3gmuB3AiOD4AfuF3gfuB3AzN34A0SEIA0uAHm1N73w1N54A4eDYA4uAHz4t+324t94A";
        vdata += "7OB4AhN734at73Aat53Iat53Yat534at74AVt73AVt53IVt53YVt73gWR73rVt/3AVuB3IVuB3YVt/3gWR/3rat/3AauB3IauB3Y";
        vdata += "at/3gat/4AfuD3oiN94AUt6nQUt7XZUt7XGUt93cUt93DUuAHGUuAHZUuA3QWt93QWt93QiN94Aft74oft95AtF44Mnt54wmt95A";
        vdata += "wR4IQvR6oZtN6owvSB4ZmuD4AmuF4gmuB5AiOD4AfuF4gfuB5AzN34A0SEIA0uAIZ1N74Q1N54A4eDYA4uAIM4t+4J4t94A7OB4A";
        vdata += "hN74Iat75Aat544at54oat54Iat74AVt75AVt544Vt54oVt74gWR74UVt/5AVuB44VuB4oVt/4gWR/4Uat/5AauB44auB4oat/4g";
        vdata += "fuD4YiN94AUt6owUt7YmUt7Y5Ut94jUt948UuAI5UuAImUuA4wWt94wWt94wbN/3AbN/2QZt/0gdV93AdV92AgB93AgB92AcN/0I";
        vdata += "mt93AgB/3AgB/2AdV/3AdV/2Amt93AbN/5AbN/5wZt/7gdV95AdV96AgB95AgB96AcN/74mt95AgB/5AgB/6AdV/5AdV/6Amt95A";
        vdata += "UN/1wat93AWV92YX193ASt/2AUt92gVN93ATt/24VN93AWB/3AX193Aat93AUN/6Qat95AWV95oX195ASt/6AUt95gVN95ATt/5I";
        vdata += "VN95AWB/5AX195Aat95AWtj3IUtj3IVt53IVt53Qat53Iat53QWtj44Utj44Vt544Vt54wat544at54w"
        idata += "AAQIAAAgMABCQgHBCQYIBCAYFAAAoBAAAsKBBw4JBDg0JBDA0OAFRYTAEhUTADxITAEA8TAGBcWAFxsUAGRoYAJiglAJygmAJSgk";
        idata += "AHyMiAFh8iAFhUfAFiIhAGBYhAHjo5AKywQALDEyALSwyAPh0cAPxApAOh4dAOzodAGBobAFxgbAIBkYAISAYAQEExAMEAxAQUMy";
        idata += "AMUEyAQ0Y3AMkM3ARkc2AN0Y2AR0U1ANkc1ARUQ0ANUU0AREIvANEQvAQkAwAL0IwCSEZDCQUhDCRUdICSERFCSEJECSEBCCQUBI";
        idata += "ATlFQATlBNATk1KATkpLAUVJTAT1ZSAU1VUAYGNhAYWNiAX2NgAXV5aAXVpRAWlBRAXF1RAXFFTAdHVZAS2dmAbWxnAbWdoAV1h4";
        idata += "AZEt5AWFl1AWHV2AVlVTAVlNSAU1RbAU1tcAbHt6AbHprAbX17AbXtsAcoB9Acn1tAcYGAAcYByAcH+BAcIFxAb35/Ab39wAanx+";
        idata += "Aan5vAa3p8Aa3xqCfYCCCfYJ7CgoF/Cf36CCfnyCCfHqCCgnp7AbmkzAPXM4AFhMXAFBMXAT05SAUU5SAiIaFAhYaQAi4qRAiomR";
        idata += "Ai5GOAjI2OAk5SWAnpSTAn5iZAn5eYAnJ+ZAnJuaAp6WkAo6qhAqKmmAo6GiAqKepApKmnAqaSgAoKKrAq6mgAsLGzArbavAsrW0";
        idata += "Arq2vAtbO0As7WwArLC1At66sArLW3Auru5AuL28Av8HAAwsO+BBAUCBAQQCBBQYDBAgUDBCAUEBBwgEBCgwEBAQoEBCw0MBCgsM";
        idata += "BBAwOBBwQOAFBEQAExQQAFxQTAFhcTAHB0aAGRwaAHR4bAGh0bAFBseAERQeAIiYlAISIlAJyYiAIyciAJCAhAJSQhAKxARAKisR";
        idata += "ALSkQALC0QALg8pALS4pALzArAKi8rAMDEsAKzAsAMy4tAMjMtANzgzAMjczAOTo1ANDk1AOjs2ANTo2AOzw3ANjs3APD04ANzw4";
        idata += "AHT48AOx08APhw9APD49AOSoRAHjkRANC8qAOTQqCR0ZICSUdIAS0xPATktPATk9SAUU5SAVFVYAV1RYAVVZZAWFVZATFlWAT0xW";
        idata += "AYGFdAXGBdAXWFiAXl1iAXFtfAYFxfATEtmAZUxmAS2RoAZ0toAZEppAaGRpAZWZrAamVrAZmdsAa2ZsAaGluAbWhuAbW5zAcm1z";
        idata += "Ab3B1AdG91AcHF2AdXB2AcXJ3AdnF3AcnM9Ad3I9Adnd4AWHZ4APVd4Adz14AWUxlAdFllAdGVqAb3RqCg4KACgYOAAOHNuAMzhu";
        idata += "Ah4iFAhIeFAiYqIAh4mIAi4aIAiouIAj5COAjY+OAkIaLAjpCLAhIWQAj4SQAkpOWAlZKWAlZaYAl5WYAlpSZAmJaZAm5yeAnZue";
        idata += "AnJmUAnpyUAnZ6TAkp2TApaKgApKWgApaajAoqWjAp6imApaemArK6xAsKyxArq+yAsa6yAsbK0As7G0Aubu9AuLm9Aurm4AvLq4";
        idata += "AvsPBAv77BAwr6/AwMK/"
        mdlFlyer = _unpackModel(vdata, idata, [new Material(0xc0c0c0), new Material(0x203040), new Material(0xffc040)]);
        // Fire billboard
        mtx.createGradientBox(32,32,0,0);
        for (i=0; i<8; i++) {
            texFire[i] = new BitmapData(32, 32, true, 0);
            shp.graphics.clear();
            shp.graphics.beginGradientFill(GradientType.RADIAL, [0x80c0f0, 0x80c0f0], [0,0.5-i*0.05], [0,255], mtx);
            shp.graphics.drawCircle(16,16,16);
            shp.graphics.endFill();
            texFire[i].draw(shp);
        }
        mdlFire = new Model(Vector.<Number>([-1,-1,0,-1,1,0,1,-1,0,1,1,0]), Vector.<Number>([0,0,0,0,1,0,1,0,0,1,1,0]));
        mdlFire.face(0,1,2).face(3,2,1);
    }
    
    private function _unpackModel(vdata:String, idata:String, materials:Array) : Model {
        var i:int, ui:uint, model:Model = new Model(null, null, Vector.<Material>(materials));
        for (i=0; i<vdata.length; i+=5) {
            _dec.decode(vdata.substr(i, 5) + "A==");
            ui = (_dec.toByteArray().readUnsignedInt())>>2;
            model.vertices.push(((ui&1023)-512)*SCALE, (((ui>>10)&1023)-512)*SCALE, (((ui>>20)&1023)-512)*SCALE);
        }
        for (i=0; i<idata.length; i+=5) {
            _dec.decode(idata.substr(i, 5) + "A==");
            ui = (_dec.toByteArray().readUnsignedInt())>>2;
            model.face(ui&255, (ui>>8)&255, (ui>>16)&255, (ui>>24)&63);
        }
        return model;
    }
}

// Background
//----------------------------------------------------------------------------------------------------
class Sky extends Shape {
    // This color gradation is refered from nemu90kWw's 水平線
    // http://wonderfl.kayac.com/code/2b527a2efe155b7f69330822a3c7f7733ab6ea7e
    public var gradation:* = {
        color:[0x103860, 0x4070B8, 0x60B0E0, 0xD0F0F0, 0x0033c0, 0x0033c0], 
        alpha:[100, 100, 100, 100, 100, 0], ratio:[0, 128, 192, 216, 224, 255]
    };
    function Sky() {
        var mat:Matrix = new Matrix();
        mat.createGradientBox(700, 380, Math.PI/2);
        graphics.beginGradientFill("linear", gradation.color, gradation.alpha, gradation.ratio, mat);
        graphics.drawRect(0, 0, 700, 380);
        graphics.endFill();
    }
}

class Landscape extends Bitmap {
    // This color gradation is refered from psyrak's BumpyPlanet
    // http://wonderfl.kayac.com/code/d79cd85845773958620f42cb3e6cb363c2020c73
    public var gradation:* = {
        color:[0x000080, 0x0066ff, 0xcc9933, 0x00cc00, 0x996600, 0xffffff], 
        alpha:[100, 100, 100, 100, 100, 100], ratio:[0, 96, 96, 128, 168, 192]
    };
    public var pixels:BitmapData, texture:BitmapData, rect:Rectangle;
    function Landscape(w:int, h:int) {
        texture = new BitmapData(w*2, h*2, false, 0);
        pixels = new BitmapData(w, h, false, 0);
        rect = new Rectangle(0, 0, w, h);
        super(pixels);
        
        // height map
        var hmap:BitmapData = new BitmapData(w, h, false, 0);
        hmap.perlinNoise(w*0.5, h*0.5, 10, Math.random()*0xffffffff, true, false, 0, true);
        hmap.colorTransform(hmap.rect, new ColorTransform(1.5, 1.5, 1.5, 1, -64, -64, -64, 0));
        
        // texture
        var mapR:Array=new Array(256), mapG:Array=new Array(256), mapB:Array=new Array(256);
        var gmap:BitmapData = new BitmapData(256,1,false,0), render:Shape = new Shape(), mat:Matrix = new Matrix();
        mat.createGradientBox(256,1,0,0,0);
        render.graphics.clear();
        render.graphics.beginGradientFill("linear", gradation.color, gradation.alpha, gradation.ratio, mat);
        render.graphics.drawRect(0,0,256,1);
        render.graphics.endFill();
        gmap.draw(render);
        for (var i:int=0; i<256; i++) {
            var col:uint = gmap.getPixel(i, 0);
            mapR[i] = col & 0xff0000;
            mapG[i] = col & 0x00ff00;
            mapB[i] = col & 0x0000ff;
        }
        gmap.dispose();
        mat.identity();
        texture.paletteMap(hmap, hmap.rect, hmap.rect.topLeft, mapR, mapG, mapB);

        // shading
        var smap:BitmapData = new BitmapData(w, h, false, 0);
        smap.applyFilter(hmap, hmap.rect, hmap.rect.topLeft, new ConvolutionFilter(3,3,[-1,-1,0,-1,0,1,0,1,1],1,0,true,true));
        texture.draw(smap, null, new ColorTransform(4, 4, 4, 1, 160, 160, 160, 0), "multiply");
        
        // copy 2x2
        pt.x = w; pt.y = h; texture.copyPixels(texture, hmap.rect, pt);
        pt.x = 0; pt.y = h; texture.copyPixels(texture, hmap.rect, pt);
        pt.x = w; pt.y = 0; texture.copyPixels(texture, hmap.rect, pt);
        pt.x = 0; pt.y = 0;
    }
    
    private var pt:Point = new Point();
    public function update() : void {
        rect.x = (int(rect.x-_globalVel.x)) & (pixels.width-1);
        rect.y = (int(rect.y-_globalVel.z)) & (pixels.height-1);
        pixels.copyPixels(texture, rect, pt);
    }
}

// Flyer
//----------------------------------------------------------------------------------------------------
class Flyer {
    public var p:Vector3D, v:Vector3D, a:Vector3D, mdlFlyer:Model, mdlFire:Model;
    private var _afterBurner:Boolean = false;
    
    function Flyer(x:Number, y:Number, z:Number) : void {
        p = new Vector3D(x, y, z);
        v = new Vector3D();
        a = new Vector3D();
        mdlFlyer = _models.mdlFlyer;
        mdlFire  = _models.mdlFire;
    }
    
    public function update() : void {
        var inkey:int = _key.flag;
        a.x = ((inkey & 1) - ((inkey & 4)>>2))*1.2;
        a.y = (((inkey & 2)>>1) - ((inkey & 8)>>3))*0.8;
        v.x = v.x * 0.8 - p.x*0.05;
        v.y = v.y * 0.8 - p.y*0.05;
        _afterBurner = Boolean(inkey & 32);
        p.x += v.x + a.x * 0.5;
        p.y += v.y + a.y * 0.5;
        v.x += a.x;
        v.y += a.y;
    }
    
    public function render() : void {
        _shape3d.pushMatrix()
            .translate(p.x, p.y+10, p.z).rotateZ(v.x*6-_roll*0.5).rotateY(v.x*3).rotateX(v.y*-4)
            .project(mdlFlyer).renderSolid(_light);
        _screen.draw(_shape3d, _mat2d);
        var scale:Number = (_afterBurner) ? 1.7 : 1.5,
            length:Number = (_afterBurner) ? 1.5 : 1.0,
            rand:Number;
        for (var i:int=0; i<8; i++) {
            rand = scale*(0.9+Math.random()*0.1);
            _shape3d.pushMatrix()
                .translate(-4.8, -0.9, -18.1-i*length).scale(rand, rand, 1)
                .project(mdlFire).renderTexture(_models.texFire[i]);
            _screen.draw(_shape3d, _mat2d, null, "add");
            _shape3d.popMatrix().pushMatrix()
                .translate(4.8, -0.9, -18.1-i*length).scale(rand, rand, 1)
                .project(mdlFire).renderTexture(_models.texFire[i]);
            _screen.draw(_shape3d, _mat2d, null, "add");
            _shape3d.popMatrix();
        }
        _shape3d.popMatrix();
    }
}

// MML Sequencer
//   http://wonderfl.kayac.com/user/keim_at_Si
//----------------------------------------------------------------------------------------------------
class Sequencer {
    private var _tracks:Array, _count:int=Track.speed+1;
    function Sequencer(speed:int=2, mml:Array=null) {
        this.speed = speed;
        this.mml = mml;
    }
    public function onSoundFrame() : Boolean {
        if (++_count == Track.speed) {
            for each (var tr:Track in _tracks) tr.execute();
            _count = 0;
            return true;
        }
        return false;
    }
    public function set speed(spd:int) : void {
        Track.speed = spd;
        if (_count >= spd) _count=0;
    }
    public function set drSpeed(spd:int) : void {
        if (spd<0 || spd>2) return;
        Track.drs = spd;
    }
    public function set pos(p:int) : void {
        for (var i:int=0; i<p; i++) {
            for each (var tr:Track in _tracks) tr.execute();
        }
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
    static public var codeA:int="a".charCodeAt(), nt:Array=[9,11,0,2,4,5,7], speed:int=3, drs:int=2;
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
                    case 's':  osc.dr = (int(res[3])<<drs)&~1; break;
                    case 'w':  osc.sw = -(int(res[3])>>(2-drs));   break;
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

// 3D Engine
//   http://wonderfl.kayac.com/user/keim_at_Si
//----------------------------------------------------------------------------------------------------
/** 3D Shape */
class Shape3D extends Shape {
    /** model view matrix */
    public var matrix:Matrix3D;
    private var _modelProjected:Model = null;
    private var _facesProjected:Vector.<Face> = new Vector.<Face>();
    private var _vertexOnWorld:Vector.<Number> = new Vector.<Number>();
    private var _vout:Vector.<Number> = new Vector.<Number>();
    private var _projectionMatrix:Matrix3D;
    private var _matrixStac:Vector.<Matrix3D> = new Vector.<Matrix3D>();
    private var _cmdTriangle:Vector.<int> = Vector.<int>([1,2,2]);
    private var _cmdQuadrangle:Vector.<int> = Vector.<int>([1,2,2,2]);
    private var _data:Vector.<Number> = new Vector.<Number>(8, true);
    
    /** constructor */
    function Shape3D(focus:Number=300) {
        var projector:PerspectiveProjection = new PerspectiveProjection()
        projector.focalLength = focus;
        _projectionMatrix = projector.toMatrix3D();
        matrix = new Matrix3D();
        _matrixStac.length = 1;
        _matrixStac[0] = matrix;
    }
    
    /** push matrix */
    public function pushMatrix() : Shape3D { _matrixStac.push(matrix.clone()); return this; }
    
    /** pop matrix */
    public function popMatrix() : Shape3D { matrix = (_matrixStac.length == 1) ? matrix : _matrixStac.pop(); return this; }
    
    /** translate */
    public function translate(x:Number, y:Number, z:Number) : Shape3D { matrix.prependTranslation(x, y, z); return this; }
    
    /** scale */
    public function scale(x:Number, y:Number, z:Number) : Shape3D { matrix.prependScale(x, y, z); return this; }
    
    /** rotate */
    public function rotate(angle:Number, axis:Vector3D) : Shape3D { matrix.prependRotation(angle, axis); return this; }
    public function rotateX(angle:Number) : Shape3D { matrix.prependRotation(angle, Vector3D.X_AXIS); return this; }
    public function rotateY(angle:Number) : Shape3D { matrix.prependRotation(angle, Vector3D.Y_AXIS); return this; }
    public function rotateZ(angle:Number) : Shape3D { matrix.prependRotation(angle, Vector3D.Z_AXIS); return this; }
    
    /** project */
    public function project(model:Model) : Shape3D {
        var i0x3:int, i1x3:int, i2x3:int, x01:Number, x02:Number, y01:Number, y02:Number, z01:Number, z02:Number,
            viewx:Number, viewy:Number, viewz:Number;
        matrix.transformVectors(model.vertices, _vertexOnWorld);
        _facesProjected.length = 0;
        var vertices:Vector.<Number> = _vertexOnWorld;
        for each (var face:Face in model.faces) {
            i0x3 = (face.i0<<1) + face.i0;
            i1x3 = (face.i1<<1) + face.i1;
            i2x3 = (face.i2<<1) + face.i2;
            face.x = (vertices[i0x3] + vertices[i1x3] + vertices[i2x3]) * 0.333333333333;
            x01 = vertices[i1x3] - vertices[i0x3];
            x02 = vertices[i2x3] - vertices[i0x3];
            i0x3++; i1x3++; i2x3++;
            face.y = (vertices[i0x3] + vertices[i1x3] + vertices[i2x3]) * 0.333333333333;
            y01 = vertices[i1x3] - vertices[i0x3];
            y02 = vertices[i2x3] - vertices[i0x3];
            i0x3++; i1x3++; i2x3++;
            face.z = (vertices[i0x3] + vertices[i1x3] + vertices[i2x3]) * 0.333333333333;
            z01 = vertices[i1x3] - vertices[i0x3];
            z02 = vertices[i2x3] - vertices[i0x3];
            face.normal.z = x02*y01 - x01*y02;
            face.normal.x = y02*z01 - y01*z02;
            face.normal.y = z02*x01 - z01*x02;
            if (face.x * face.normal.x + face.y * face.normal.y + face.z * face.normal.z <= 0) {
                face.normal.normalize();
                _facesProjected.push(face);
            }
        }
        _facesProjected.sort(function(f1:Face, f2:Face) : Number { return f2.z - f1.z; });
        _modelProjected = model;
        return this;
    }

    /** render solid */
    public function renderSolid(light:Light) : Shape3D {
        var idx:int, mat:Material, materials:Vector.<Material> = _modelProjected.materials;
        Utils3D.projectVectors(_projectionMatrix, _vertexOnWorld, _vout, _modelProjected.texCoord);
        graphics.clear();
        for each (var face:Face in _facesProjected) {
            mat = materials[face.mat];
            graphics.beginFill(mat.getColor(light, face.normal), mat.alpha);
            idx = face.i0<<1;
            _data[0] = _vout[idx]; idx++;
            _data[1] = _vout[idx]; 
            idx = face.i1<<1;
            _data[2] = _vout[idx]; idx++;
            _data[3] = _vout[idx]; 
            idx = face.i2<<1;
            _data[4] = _vout[idx]; idx++;
            _data[5] = _vout[idx]; 
            graphics.drawPath(_cmdTriangle, _data);
            graphics.endFill();
        }
        return this;
    }
    
    /** render with texture */
    public function renderTexture(texture:BitmapData) : Shape3D {
        var idx:int, mat:Material;
        Utils3D.projectVectors(_projectionMatrix, _vertexOnWorld, _vout, _modelProjected.texCoord);
        graphics.clear();
        graphics.beginBitmapFill(texture, null, false, true);
        graphics.drawTriangles(_vout, _modelProjected.indices, _modelProjected.texCoord);
        graphics.endFill();
        return this;
    }
}

/** Face */
class Face {
    public var i0:int, i1:int, i2:int, i3:int, mat:int, x:Number, y:Number, z:Number, normal:Vector3D = new Vector3D();
    static private var _freeList:Vector.<Face> = new Vector.<Face>();
    static public function alloc() : Face { return _freeList.pop() || new Face(); }
    static public function free(face:Face) : void { _freeList.push(face); }
}

/** Model */
class Model {
    public var materials:Vector.<Material>;                 // material list
    public var vertices:Vector.<Number>;                    // vertex
    public var texCoord:Vector.<Number>;                    // texture coordinate
    public var faces:Vector.<Face> = new Vector.<Face>();   // face list
    private var _indices:Vector.<int> = new Vector.<int>(); // temporary index list
    
    /** indices as Vector.<int> */
    public function get indices() : Vector.<int> {
        _indices.length = 0;
        for each (var face:Face in faces) { _indices.push(face.i0, face.i1, face.i2); }
        return _indices;
    }

    /** constructor */
    function Model(vertices:Vector.<Number>=null, texCoord:Vector.<Number>=null, materials:Vector.<Material>=null) {
        this.vertices = vertices || new Vector.<Number>();
        this.texCoord = texCoord || new Vector.<Number>();
        this.materials = materials || Vector.<Material>([new Material()]);
    }
    
    /** clear */
    public function clear() : Model {
        for each (var face:Face in faces) Face.free(face);
        faces.length = 0;
        return this;
    }
    
    /** register face */
    public function face(i0:int, i1:int, i2:int, mat:int=0) : Model {
        var face:Face = Face.alloc();
        face.i0 = i0;
        face.i1 = i1;
        face.i2 = i2;
        face.mat = mat;
        faces.push(face);
        return this;
    }
}

/** Light */
class Light {
    private var _direction:Vector3D = new Vector3D();
    private var _halfVector:Vector3D = new Vector3D();
    public function get direction()  : Vector3D { return _direction; }
    public function get halfVector() : Vector3D { return _halfVector; }
    
    /** constructor (set position) */
    function Light(x:Number=1, y:Number=1, z:Number=1) { setPosition(x, y, z); }
    
    /** set position */
    public function setPosition(x:Number, y:Number, z:Number) : void {
        _direction.x = x;
        _direction.y = y;
        _direction.z = z; 
        _direction.normalize();
        _halfVector.x = _direction.x;
        _halfVector.y = _direction.y;
        _halfVector.z = _direction.z + 1; 
        _halfVector.normalize();
    }
}

/** Material */
class Material {
    public var colorTable:BitmapData = new BitmapData(256,256,false);
    public var alpha:Number = 1;
    private var _nega_filter:int = 0;
    
    /** constructor */
    function Material(color:uint=0xc0c0c0, alpha:Number=1.0) { setColor(color, alpha); }
    
    /** set color. */
    public function setColor(color:uint, alpha:Number= 1.0, 
                             amb:int=64, dif:int=192, spc:int=0,  pow:Number=8, 
                             emi:int=0,  doubleSided:Boolean=false) : Material 
    {
        var i:int, r:int, c:int, rc:Rectangle;
        var lightTable:BitmapData = new BitmapData(256, 256, false);
        
        // color/alpha
        colorTable.fillRect(colorTable.rect, color);
        this.alpha = alpha;

        // ambient/diffusion/emittance
        var ea:Number = (256-emi)*0.00390625, eb:Number = emi*0.5;
        r = dif - amb;
        rc = new Rectangle(0, 0, 1, 256);
        for (i=0; i<256; ++i) {
            rc.x = i;
            lightTable.fillRect(rc, (((i*r)>>8)+amb)*0x10101);
        }
        colorTable.draw(lightTable, null, new ColorTransform(ea,ea,ea,1,eb,eb,eb,0), BlendMode.HARDLIGHT);
        
        // specular/power
        if (spc > 0) {
            rc = new Rectangle(0, 0, 256, 1);
            for (i=0; i<256; ++i) {
                rc.y = i;
                c = int(Math.pow(i*0.0039215686, pow)*spc);
                lightTable.fillRect(rc, ((c<255)?c:255)*0x10101);
            }
            colorTable.draw(lightTable, null, null, BlendMode.ADD);
        }

        // double side
        _nega_filter = (doubleSided) ? -1 : 0;
        
        lightTable.dispose();

        return this;
    }
    
    /** calculate color by light and normal vector. */
    public function getColor(light:Light, normal:Vector3D) : uint {
        var dir:Vector3D = light.direction, hv:Vector3D = light.halfVector;
        var ln:int = int((dir.x * normal.x + dir.y * normal.y + dir.z * normal.z)*255),
            hn:int = int((hv.x  * normal.x + hv.y  * normal.y + hv.z  * normal.z)*255);
        if (ln<0) ln = (-ln) & _nega_filter;
        if (hn<0) hn = (-hn) & _nega_filter;
        return colorTable.getPixel(ln, hn);
    }
}
