// forked from keim_at_Si's wonderflで3D 【Flat shading】
// 高速化，マウスで光源移動，クリックで材質変更
//--------------------------------------------------
package {
    import flash.display.*;
    import flash.text.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.utils.*;
    import net.hires.debug.Stats;

    [SWF(width="465", height="465", backgroundColor="0x000000", frameRate="30")]
    public class main extends Sprite {
        private var _matrix:Matrix3D = new Matrix3D();
        private var _engine:EngineFaceBasedRender = new EngineFaceBasedRender();
        
        // material setting (color, alpha, amb, dif, spc, phong, emi, doubleSided)
        private var _materials:Vector.<Material> = Vector.<Material>([
            (new Material()).setColor(0x8080c0, 1, 64, 128, 128, 12, 0, false),   // standerd
            (new Material()).setColor(0x8080c0, 1, 64, 192,   0,  0, 0, false),   // matte
            (new Material()).setColor(0x8080c0, 1, 16,  64, 192, 18, 0, false),   // speculer
            (new Material()).setColor(0x8080c0, 1,  8,  32, 256, 24, 0, false),   // more speculer
            (new Material()).setColor(0x8080c0, 1,  0, 255,   0,  0, 0, false),   // diffusion only
            (new Material()).setColor(0x8080c0, 1,  0,   0, 255, 12, 0, false),   // speculer only
            (new Material()).setColor(0x8080c0, 1,128, 128,   0,  0, 0, false),   // one color
            (new Material()).setColor(0x8080c0, 1,  0,   0,   0,  0, 255, false), // one color (same)
        ]);
        private var _light:Light = new Light();
        private var _model:Model = new Model();
        private var _boxVertex:Vector.<Number> = new Vector.<Number>();
        private var _sphVertex:Vector.<Number> = new Vector.<Number>();
        private var _vertexNormal:Vector.<Vector3D> = new Vector.<Vector3D>();
        
        private var _t:Number, _dt:Number, _rot:Number, _matIndex:int;
        private var _timeSum:int, _timeCount:int;
        
        private var _textField:TextField = new TextField();
        
        function main() {
            _engine.x = 232;
            _engine.y = 232;
            addChild(_engine);
            addEventListener("enterFrame", _onEnterFrame);
            stage.addEventListener("click", function(e:Event):void{ _matIndex=(_matIndex+1)&7; });

            // create shape
            for (var x:Number=-14; x<16; x+=4) {
                for (var y:Number=-14; y<16; y+=4) {
                    _vertex( x, y, 16);
                    _vertex( x,-y,-16);
                    _vertex( y, 16, x);
                    _vertex(-y,-16, x);
                    _vertex( 16, x, y);
                    _vertex(-16, x,-y);
                }
            }
            for (var i:int=0; i<7; i++) {
                for (var j:int=0; j<7; j++) {
                    for (var k:int=0; k<6; k++) {
                        var i0:int = (i*8+j)*6+k;
                        _model.face(i0, i0+6, i0+48).face(i0+54, i0+48, i0+6);
                    }
                }
            }
            _model.vertices.length = _boxVertex.length;
            _model.texCoord.length = _boxVertex.length;
            _vertexNormal.length = _boxVertex.length/3;
            for (i=0; i<_vertexNormal.length; i++) _vertexNormal[i] = new Vector3D();
            
            // initialize parameters
            _matIndex = 0;
            _rot = 0;
            _t = 0;
            _dt = 0.01;
            _timeSum = 0;
            _timeCount = 0;
            _textField.autoSize = "left";
            _textField.background = true;
            _textField.backgroundColor = 0x80f080;
            addChild(_textField);
            var status:Stats = new Stats();
            status.x = 400;
            addChild(status);

            function _vertex(x:Number, y:Number, z:Number) : void {
                _boxVertex.push( x, y, z);
                var ilen:Number = 20/Math.sqrt(x*x+y*y+z*z);
                _sphVertex.push( x*ilen, y*ilen, z*ilen);
            }
        }

        private function _onEnterFrame(e:Event) : void {
            var i:int, t:int;
            // update paremters
            _rot += 1;
            _t += _dt;
            if (_t>3 || _t<-3) { _dt = -_dt; _t += _dt; }
            for (i=0; i<_model.vertices.length; i++) {
                _model.vertices[i] = _boxVertex[i]*_t + _sphVertex[i]*(1-_t);
            }

            // light position
            _light.setPosition(mouseX-232, mouseY-232, -100);
            
            t = getTimer();
            _engine.pushMatrix();
            _matrix.identity();
            _matrix.appendRotation(_rot*0.3, Vector3D.X_AXIS);
            _matrix.appendRotation(_rot,     Vector3D.Y_AXIS);
            _matrix.appendTranslation(0, 0, 100);
            _engine.matrix.append(_matrix);
            _engine.project(_model);
            _engine.render(_model, _light, _materials[_matIndex]);
            _engine.popMatrix();
            _timeSum += getTimer() - t;
            
            if (++_timeCount == 30) {
                _textField.text = "Redering time: " + String(_timeSum) + "[ms/30frames]";
                _timeSum = 0;
                _timeCount = 0;
            }
        }
    }
}


import flash.display.*;
import flash.geom.*;

class EngineFaceBasedRender extends Shape {
    public var matrix:Matrix3D;
    
    private var _vertexOnWorld:Vector.<Number> = new Vector.<Number>();
    private var _vout:Vector.<Number> = new Vector.<Number>();
    
    private var _projector:PerspectiveProjection;
    private var _projectionMatrix:Matrix3D;
    private var _matrixStac:Vector.<Matrix3D>;

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
            face.z = vertices[i0x3] + vertices[i1x3] + vertices[i2x3];
            face.normal.x = y01*z02 - y02*z01;
            face.normal.y = z01*x02 - z02*x01;
            face.normal.z = x01*y02 - x02*y01;
            face.normal.normalize();
        }
        model.faces.sort(function(f1:Face, f2:Face) : Number { return f2.z - f1.z; });
        return this;
    }
    
    public function render(model:Model, light:Light, material:Material) : EngineFaceBasedRender {
        Utils3D.projectVectors(_projectionMatrix, _vertexOnWorld, _vout, model.texCoord);
        graphics.clear();
        for each (var face:Face in model.faces) {
            graphics.beginFill(material.getColor(light, face.normal), material.alpha);
            graphics.moveTo(_vout[face.i0<<1], _vout[(face.i0<<1)+1]);
            graphics.lineTo(_vout[face.i1<<1], _vout[(face.i1<<1)+1]);
            graphics.lineTo(_vout[face.i2<<1], _vout[(face.i2<<1)+1]);
            graphics.endFill();
        }
        return this;
    }
}

class Face {
    public var i0:int, i1:int, i2:int, z:Number, normal:Vector3D = new Vector3D();

    // Factory
    static private var _freeList:Vector.<Face> = new Vector.<Face>();
    static public function alloc() : Face { return _freeList.pop() || new Face(); }
    static public function free(face:Face) : void { _freeList.push(face); }
}

class Model {
    public var vertices:Vector.<Number>;
    public var texCoord:Vector.<Number>;
    public var faces:Vector.<Face> = new Vector.<Face>();
    private var _indices:Vector.<int> = new Vector.<int>();

    function Model(vertices:Vector.<Number>=null, texCoord:Vector.<Number>=null) {
        this.vertices = vertices || new Vector.<Number>();
        this.texCoord = texCoord || new Vector.<Number>();
    }
    
    public function clear() : Model {
        for each (var face:Face in faces) Face.free(face);
        faces.length = 0;
        return this;
    }
    
    public function face(i0:int, i1:int, i2:int) : Model {
        var face:Face = Face.alloc();
        face.i0 = i0;
        face.i1 = i1;
        face.i2 = i2;
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


