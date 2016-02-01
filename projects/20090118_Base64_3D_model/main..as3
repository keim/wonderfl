// forked from keim_at_Si's wonderflで3D 【Flat shading】 高速化
// forked from keim_at_Si's wonderflで3D 【Flat shading】
// マウスで光源移動
//--------------------------------------------------
package {
    import flash.display.*;
    import flash.text.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.utils.*;
    import mx.utils.Base64Decoder;

    [SWF(width="465", height="465", backgroundColor="0x000000", frameRate="30")]
    public class main extends Sprite {
        private var _matrix:Matrix3D = new Matrix3D();
        private var _engine:EngineFaceBasedRender = new EngineFaceBasedRender();
        
        private var _light:Light = new Light();
        private var _model:Model = new Model();
        
        private var _textField:TextField = new TextField();
        
        private var _rot:Number, _timeSum:int, _timeCount:int;
        
        function main() {
            _engine.x = 232;
            _engine.y = 232;
            addChild(_engine);
            addEventListener("enterFrame", _onEnterFrame);
            
            _loadModel(0.1);
            
            // initialize parameters
            _rot = 180;
            _timeSum = 0;
            _timeCount = 0;
            _textField.autoSize = "left";
            _textField.background = true;
            _textField.backgroundColor = 0x80f080;
            addChild(_textField);
        }

        private function _onEnterFrame(e:Event) : void {
            _rot += 1;

            // light position
            _light.setPosition(mouseX-232, mouseY-232, -100);
            
            var t:int = getTimer();
            _engine.pushMatrix();
            _matrix.identity();
            _matrix.appendRotation(_rot*0.3, Vector3D.X_AXIS);
            _matrix.appendRotation(_rot,     Vector3D.Y_AXIS);
            _matrix.appendTranslation(0, 0, 100);
            _engine.matrix.append(_matrix);
            _engine.project(_model);
            _engine.render(_model, _light);
            _engine.popMatrix();
            _timeSum += getTimer() - t;
            
            if (++_timeCount == 30) {
                var str:String = "";
                str += "Redering time: " + String(_timeSum) + "[ms/30frames]";
                str += "\nVertices: " + String(_model.vertices.length/3);
                str += "\nFaces: " + String(_model.faces.length);
                _textField.text = str;
                _timeSum = 0;
                _timeCount = 0;
            }
        }
        
        private function _loadModel(scale:Number) : void {
            var i:int, ui:uint;
            var vdata:String="", idata:String="", dec:Base64Decoder = new Base64Decoder();
            vdata += "d2CYAUWKYAUGJH4S6HHzRWMYARGLHzPuH3wO2MYAPWLH0M2IYAUGJIIS6HIMRGLIMPuH4QPWLILd2CYAgWEXYgWCXAS6HHzYWGXQ";
            vdata += "ZWCXAPuH3wQuFXmS2FXQQt+XmZV8YAZV6XgZV+XAd18YAgV6XggV+XAM2IYALt74ALV/3mK2EXwK2GYAHh8oAHV/3zHWBH2HWCYA";
            vdata += "E1+YAe2EX4lWEXAlWGXIlWGXYlWGX4lWEYAqWEXAqWGXIqWGXYqWEXgpuEXrqWAXAqV+XIqV+XYqWAXgpuAXrlWAXAlV+XIlV+XY";
            vdata += "lWAXglWAYAgV8Xod2CYArWFXQrWEnZrWEnGrWCXcrWCXDrV/3GrV/3ZrV/HQpWCXQpWCXQd2CYAgWEYogWCZAS6HIMYWGYwZWCZA";
            vdata += "PuH4QQuFYZS2FYwQt+YZZV8YAZV6YgZV+ZAd18YAgV6YggV+ZAM2IYALt74ALV/4ZK2EYQK2GYAHh8oAHV/4MHWBIJHWCYAE1+YA";
            vdata += "e2EYIlWEZAlWGY4lWGYolWGYIlWEYAqWEZAqWGY4qWGYoqWEYgpuEYUqWAZAqV+Y4qV+YoqWAYgpuAYUlWAZAlV+Y4lV+YolWAYg";
            vdata += "gV8YYd2CYArWFYwrWEomrWEo5rWCYjrWCY8rV/45rV/4mrV/IwpWCYwpWCYwk2AXAk2AWQmWAUgiqCXAiqCWAf+CXAf+CWAj2AUI";
            vdata += "ZWCXAf+AXAf+AWAiqAXAiqAWAZWCXAk2AZAk2AZwmWAbgiqCZAiqCaAf+CZAf+CaAj2Ab4ZWCZAf+AZAf+AaAiqAZAiqAaAZWCZA";
            vdata += "r2AVwlWCXApqCWYoKCXAtWAWArWCWgq2CXAsWAW4q2CXAp+AXAoKCXAlWCXAr2AaQlWCZApqCZooKCZAtWAaArWCZgq2CZAsWAZI";
            vdata += "q2CZAp+AZAoKCZAlWCZApWcXIrWcXIqWGXIqWGXQlWGXIlWGXQpWcY4rWcY4qWGY4qWGYwlWGY4lWGYw";
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
            idata += "AvsPBAv77BAwr6/AwMK/";
            _model.materials[0] = (new Material()).setColor(0xc0c0c0,1,80,192,0,40);
            _model.materials[1] = (new Material()).setColor(0x203040,1,160,192,0,5);
            _model.materials[2] = (new Material()).setColor(0xffc040,1,160,192,0,5);
            // 5[letters/vertex] (10[bits/Number])
            for (i=0; i<vdata.length; i+=5) {
                dec.decode(vdata.substr(i, 5) + "A==");
                ui = (dec.toByteArray().readUnsignedInt())>>2;
                _model.vertices.push(((ui&1023)-512)*scale, (((ui>>10)&1023)-512)*scale, (((ui>>20)&1023)-512)*scale);
            }
            // 5[letters/face] (8[bits/index] and 6[bits/material num.])
            for (i=0; i<idata.length; i+=5) {
                dec.decode(idata.substr(i, 5) + "A==");
                ui = (dec.toByteArray().readUnsignedInt())>>2;
                _model.face(ui&255, (ui>>8)&255, (ui>>16)&255, (ui>>24)&63);
            }
        }
    }
}


import flash.display.*;
import flash.geom.*;

class EngineFaceBasedRender extends Shape {
    public var matrix:Matrix3D;
    
    private var _faceProjected:Vector.<Face> = new Vector.<Face>();
    private var _vertexOnWorld:Vector.<Number> = new Vector.<Number>();
    private var _vout:Vector.<Number> = new Vector.<Number>();
    
    private var _projector:PerspectiveProjection;
    private var _projectionMatrix:Matrix3D;
    private var _matrixStac:Vector.<Matrix3D>;

    private var _commands:Vector.<int> = Vector.<int>([1,2,2]);
    private var _data:Vector.<Number> = new Vector.<Number>(6, true);
    
    function EngineFaceBasedRender(focus:Number=300) {
        _projector  = new PerspectiveProjection();
        _matrixStac = new Vector.<Matrix3D>();
        initialize(focus);
    }

    public function initialize(focus:Number) : EngineFaceBasedRender {
        _projector.focalLength = focus;
        _projectionMatrix = _projector.toMatrix3D();
        matrix = new Matrix3D();
        _matrixStac.length = 1;
        _matrixStac[0] = matrix;
        return this;
    }

    public function clearMatrix() : EngineFaceBasedRender { 
        matrix = _matrixStac[0];
        _matrixStac.length = 1;
        return this;
    }
    
    public function pushMatrix() : EngineFaceBasedRender {
        _matrixStac.push(matrix.clone());
        return this;
    }
    
    public function popMatrix() : EngineFaceBasedRender {
        if (_matrixStac.length == 1) return this;
        matrix = _matrixStac.pop();
        return this;
    }
    
    public function project(model:Model) : EngineFaceBasedRender {
        var i0x3:int, i1x3:int, i2x3:int, x01:Number, x02:Number, y01:Number, y02:Number, z01:Number, z02:Number;
        matrix.transformVectors(model.vertices, _vertexOnWorld);
        _faceProjected.length = 0;
        var vertices:Vector.<Number> = _vertexOnWorld;
        for each (var face:Face in model.faces) {
            i0x3 = (face.i0<<1) + face.i0;
            i1x3 = (face.i1<<1) + face.i1;
            i2x3 = (face.i2<<1) + face.i2;
            x01 = vertices[i1x3] - vertices[i0x3];
            x02 = vertices[i2x3] - vertices[i0x3];
            i0x3++; i1x3++; i2x3++;
            y01 = vertices[i1x3] - vertices[i0x3];
            y02 = vertices[i2x3] - vertices[i0x3];
            i0x3++; i1x3++; i2x3++;
            z01 = vertices[i1x3] - vertices[i0x3];
            z02 = vertices[i2x3] - vertices[i0x3];
            face.normal.z = x01*y02 - x02*y01;
            if (face.normal.z > 0) {
                face.z = vertices[i0x3] + vertices[i1x3] + vertices[i2x3];
                face.normal.x = y01*z02 - y02*z01;
                face.normal.y = z01*x02 - z02*x01;
                face.normal.normalize();
                _faceProjected.push(face);
            }
        }
        _faceProjected.sort(function(f1:Face, f2:Face) : Number { return f2.z - f1.z; });
        return this;
    }

    public function render(model:Model, light:Light) : EngineFaceBasedRender {
        var idx:int, mat:Material;
        Utils3D.projectVectors(_projectionMatrix, _vertexOnWorld, _vout, model.texCoord);
        graphics.clear();
        for each (var face:Face in _faceProjected) {
            idx = face.i0<<1;
            _data[0] = _vout[idx]; idx++;
            _data[1] = _vout[idx]; 
            idx = face.i1<<1;
            _data[2] = _vout[idx]; idx++;
            _data[3] = _vout[idx]; 
            idx = face.i2<<1;
            _data[4] = _vout[idx]; idx++;
            _data[5] = _vout[idx]; 
            mat = model.materials[face.mat];
            graphics.beginFill(mat.getColor(light, face.normal), mat.alpha);
            graphics.drawPath(_commands, _data);
            graphics.endFill();
        }
        return this;
    }
}

class Face {
    public var i0:int, i1:int, i2:int, mat:int, z:Number, normal:Vector3D = new Vector3D();

    // Factory
    static private var _freeList:Vector.<Face> = new Vector.<Face>();
    static public function alloc() : Face { return _freeList.pop() || new Face(); }
    static public function free(face:Face) : void { _freeList.push(face); }
}

class Model {
    public var materials:Vector.<Material>;
    public var vertices:Vector.<Number>;
    public var texCoord:Vector.<Number>;
    public var faces:Vector.<Face> = new Vector.<Face>();
    private var _indices:Vector.<int> = new Vector.<int>();

    function Model(vertices:Vector.<Number>=null, texCoord:Vector.<Number>=null, materials:Vector.<Material>=null) {
        this.vertices = vertices || new Vector.<Number>();
        this.texCoord = texCoord || new Vector.<Number>();
        this.materials = materials || Vector.<Material>([new Material()]);
    }
    
    public function clear() : Model {
        for each (var face:Face in faces) Face.free(face);
        faces.length = 0;
        return this;
    }
    
    public function face(i0:int, i1:int, i2:int, mat:int=0) : Model {
        var face:Face = Face.alloc();
        face.i0 = i0;
        face.i1 = i1;
        face.i2 = i2;
        face.mat = mat;
        faces.push(face);
        return this;
    }
    
    public function get indices() : Vector.<int> {
        _indices.length = 0;
        for each (var face:Face in faces) _indices.push(face.i0, face.i1, face.i2);
        return _indices;
    }
}

class Light {
    private var _direction:Vector3D = new Vector3D();
    private var _halfVector:Vector3D = new Vector3D();
    public function get direction() : Vector3D { return _direction; }
    public function get halfVector() : Vector3D { return _halfVector; }
    
    function Light(x:Number=1, y:Number=1, z:Number=1) { setPosition(x, y, z); }
    
    public function setPosition(x:Number, y:Number, z:Number) : void {
        _direction.x = -x;
        _direction.y = -y;
        _direction.z = -z; 
        _direction.normalize();
        _halfVector.x = _direction.x;
        _halfVector.y = _direction.y;
        _halfVector.z = _direction.z + 1; 
        _halfVector.normalize();
    }
}

class Material {
    public var colorTable:BitmapData = new BitmapData(256,256,false);
    public var alpha:Number = 1;
    private var _nega_filter:int = 0;
    
    function Material() { setColor(0xc0c0c0, 1); }
    
    public function setColor(color:uint, alpha_:Number= 1.0, 
                             amb:int=64, dif:int=192, spc:int=0, pow:Number=8, emi:int=0, doubleSided:Boolean=false) : Material
    {
        var i:int, r:int, c:int,
            lightTable:BitmapData = new BitmapData(256, 256, false),
            rct:Rectangle = new Rectangle();
        
        // base color
        alpha = alpha_;
        colorTable.fillRect(colorTable.rect, color);

        // ambient/diffusion/emittance
        var ea:Number = (256-emi)*0.00390625,
            eb:Number = emi*0.5;
        r = dif - amb;
        rct.width=1; rct.height=256; rct.y=0;
        for (i=0; i<256; ++i) {
            rct.x = i;
            lightTable.fillRect(rct, (((i*r)>>8)+amb)*0x10101);
        }
        colorTable.draw(lightTable, null, new ColorTransform(ea,ea,ea,1,eb,eb,eb,0), BlendMode.HARDLIGHT);
        
        // specular/power
        if (spc > 0) {
            rct.width=256; rct.height=1; rct.x=0;
            for (i=0; i<256; ++i) {
                rct.y = i;
                c = int(Math.pow(i*0.0039215686, pow)*spc);
                lightTable.fillRect(rct, ((c<255)?c:255)*0x10101);
            }
            colorTable.draw(lightTable, null, null, BlendMode.ADD);
        }
        lightTable.dispose();

        // double sided
        _nega_filter = (doubleSided) ? -1 : 0;
        
        return this;
    }
    
    public function getColor(light:Light, normal:Vector3D) : uint
    {
        var v:Vector3D, ln:int, hn:int, sign:int;
        
        // ambient
        v = light.direction;
        ln = int((v.x * normal.x + v.y * normal.y + v.z * normal.z)*255);
        sign = ((ln & 0x80000000)>>31);
        ln = (ln ^ sign) & ((~sign) | _nega_filter);

        // specular
        v = light.halfVector;
        hn = int((v.x * normal.x + v.y * normal.y + v.z * normal.z)*255);
        sign = ((hn & 0x80000000)>>31);
        hn = (hn ^ sign) & ((~sign) | _nega_filter);
        
        return colorTable.getPixel(ln, hn);
    }
    
    static public function calculateTexCoord(texCoord:Point, light:Light, normal:Vector3D, doubleSided:Boolean=false) : void {
        var v:Vector3D = light.direction;
        texCoord.x = v.x * normal.x + v.y * normal.y + v.z * normal.z;
        if (texCoord.x < 0) texCoord.x = (doubleSided) ? -texCoord.x : 0;
        v = light.halfVector;
        texCoord.y = v.x * normal.x + v.y * normal.y + v.z * normal.z;
        if (texCoord.y < 0) texCoord.y = (doubleSided) ? -texCoord.y : 0;
    }
}



