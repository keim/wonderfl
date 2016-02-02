// forked from keim_at_Si's ABC ground
// The gradation colors are refered from psyrak's BumpyPlanet and nemu90kWw's 水平線.
// arrows or [wasd] to move, [shift/x/m] to accel.
//--------------------------------------------------------------------------------
package {
    import flash.display.*;
    import flash.events.*;

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

// 3D Engine
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

