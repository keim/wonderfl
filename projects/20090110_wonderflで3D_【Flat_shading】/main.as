package {
    import flash.display.*;
    import flash.text.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.utils.*;
    import net.hires.debug.Stats;


    [SWF(width="465", height="465", backgroundColor="0x000000", frameRate="30")]
    public class main extends Sprite {
        private var _screen:BitmapData = new BitmapData(465, 465, false, 0x808080);
        private var _matrix:Matrix3D = new Matrix3D();
        private var _matrix2d:Matrix = new Matrix(1,0,0,1,230,230);
        private var _engine:EngineFaceBasedRender = new EngineFaceBasedRender();
        
        private var _light:Light = new Light(1,1,1);
        private var _material:Material = new Material();

        private var _boxVertex:Vector.<Number> = new Vector.<Number>();
        private var _sphVertex:Vector.<Number> = new Vector.<Number>();
        private var _vertBuf:Vector.<Number> = new Vector.<Number>();
        private var _idxBuf:Vector.<int> = new Vector.<int>();
        
        private var _t:Number, _dt:Number, _rot:Number;
        private var _timeSum:int, _timeCount:int;
        
        private var _textField:TextField = new TextField();
        
        function main() {
            addChild(new Bitmap(_screen));
            addEventListener("enterFrame", _onEnterFrame);

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
                        _idxBuf.push(i0, i0+6, i0+48, i0+54, i0+48, i0+6);
                    }
                }
            }
            _vertBuf.length = _boxVertex.length;
            
            // initialize parameters
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

            // material setting (color, alpha, amb, dif, spc, phong, emi)
            _material.setColor(0x8080c0, 1, 64, 128, 128, 12, 0);

            function _vertex(x:Number, y:Number, z:Number) : void {
                _boxVertex.push( x, y, z);
                var ilen:Number = 20/Math.sqrt(x*x+y*y+z*z);
                _sphVertex.push( x*ilen, y*ilen, z*ilen);
            }
        }

        private function _onEnterFrame(e:Event) : void {
            // update paremters
            _rot += 1;
            _t += _dt;
            if (_t>3 || _t<-3) { _dt = -_dt; _t += _dt; }
            imax = _vertBuf.length;
            for (i=0; i<imax; i++) {
                _vertBuf[i] = _boxVertex[i]*_t + _sphVertex[i]*(1-_t);
            }

            _screen.fillRect(_screen.rect, 0);
            
            var t:int = getTimer();
            // rendering
            _engine.vertexBuffer = _vertBuf;
            _engine.pushMatrix();
                
            _matrix.identity();
            _matrix.appendRotation(_rot, new Vector3D(0.707,0,0.707));
            _matrix.appendTranslation(0, 0, 100);
            _engine.matrix.append(_matrix);
            
            _engine.clearFace();
            var imax:int = _idxBuf.length
            for (var i:int=0; i<imax; i+=3) {
                _engine.setFace(_idxBuf[i], _idxBuf[i+1], _idxBuf[i+2]);
            }
            _engine.render(_screen, _light, _material, _matrix2d);
            
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

class EngineFaceBasedRender {
    public var matrix:Matrix3D;
    
    private var _vertexOnModel:Vector.<Number>;
    private var _vertexOnWorld:Vector.<Number>;
    private var _vertexDirty:Boolean;
    private var _faces:Vector.<Triangle>;
    
    private var _texCoord:Vector.<Number>;
    private var _vout:Vector.<Number>;
    
    private var _projector:PerspectiveProjection;
    private var _projectionMatrix:Matrix3D;
    private var _renderer:Shape;
    private var _matrixStac:Vector.<Matrix3D>;

    function EngineFaceBasedRender(fov:Number=30, focus:Number=300) {
        _vertexOnModel = null;
        _vertexOnWorld = new Vector.<Number>();
        _faces      = new Vector.<Triangle>();
        _projector  = new PerspectiveProjection();
        _renderer   = new Shape();
        _matrixStac = new Vector.<Matrix3D>();
        _texCoord   = new Vector.<Number>();
        _vout = new Vector.<Number>();
        initialize(fov, focus);
    }

    public function initialize(fov:Number, focus:Number) : EngineFaceBasedRender {
        _projector.fieldOfView = fov;
        _projector.focalLength = focus;
        _projectionMatrix = _projector.toMatrix3D();
        matrix = new Matrix3D();
        _matrixStac.length = 1;
        _matrixStac[0] = matrix;
        _vertexDirty = true;
        return this;
    }

    public function set vertexBuffer(vb:Vector.<Number>) : void {
        _vertexOnModel = vb;
        _vertexOnWorld.length = vb.length;
        _vertexDirty = true;
    }

    public function clearMatrix() : EngineFaceBasedRender { 
        matrix = _matrixStac[0];
        _matrixStac.length = 1;
        _vertexDirty = true;
        return this;
    }
    
    public function pushMatrix() : EngineFaceBasedRender {
        _matrixStac.push(matrix.clone());
        _vertexDirty = true;
        return this;
    }
    
    public function popMatrix() : EngineFaceBasedRender {
        if (_matrixStac.length == 1) return this;
        matrix = _matrixStac.pop();
        _vertexDirty = true;
        return this;
    }

    public function clearFace() : EngineFaceBasedRender {
        for each (var face:Triangle in _faces) { face.free(); }
        _faces.length = 0;
        return this;
    }
    
    public function setFace(i0:int, i1:int, i2:int) : EngineFaceBasedRender {
        if (_vertexDirty && _vertexOnModel) {
            matrix.transformVectors(_vertexOnModel, _vertexOnWorld);
            _vertexDirty = false;
        }
        var i0x3:int=i0*3, i1x3:int=i1*3, i2x3:int=i2*3;
        var x0:Number=_vertexOnWorld[i0x3], y0:Number=_vertexOnWorld[i0x3+1], z0:Number=_vertexOnWorld[i0x3+2], 
            x1:Number=_vertexOnWorld[i1x3], y1:Number=_vertexOnWorld[i1x3+1], z1:Number=_vertexOnWorld[i1x3+2], 
            x2:Number=_vertexOnWorld[i2x3], y2:Number=_vertexOnWorld[i2x3+1], z2:Number=_vertexOnWorld[i2x3+2];
        var face:Triangle = Triangle.alloc().initialize(i0<<1, i1<<1, i2<<1, z0+z1+z2);
        var x01:Number=x1-x0, y01:Number=y1-y0, z01:Number=z1-z0, 
            x02:Number=x2-x0, y02:Number=y2-y0, z02:Number=z2-z0;
        face.normal.x = y01*z02 - y02*z01;
        face.normal.y = z01*x02 - z02*x01;
        face.normal.z = x01*y02 - x02*y01;
        face.normal.normalize();
        _faces.push(face);
        return this;
    }

    public function render(screen:BitmapData, light:Light, mat:Material, matrix:Matrix) : BitmapData {
        var vw:Vector.<Number> = _vertexOnWorld;
        _vout.length = _vertexOnWorld.length;
        _texCoord.length = _vertexOnWorld.length * 3;
        Utils3D.projectVectors(_projectionMatrix, vw, _vout, _texCoord);
        
        _faces.sort(function(t1:Triangle, t2:Triangle) : Number {return t2.z-t1.z;});

        _renderer.graphics.clear();
        for each (var face:Triangle in _faces) {
            _renderer.graphics.beginFill(mat.calculateColor(light, face.normal), mat.alpha);
            _renderer.graphics.moveTo(_vout[face.i0], _vout[face.i0+1]);
            _renderer.graphics.lineTo(_vout[face.i1], _vout[face.i1+1]);
            _renderer.graphics.lineTo(_vout[face.i2], _vout[face.i2+1]);
            _renderer.graphics.endFill();
        }

        screen.draw(_renderer, matrix);
        return screen;
    }
}

class Triangle {
    public var i0:int, i1:int, i2:int, z:Number; 
    public var normal:Vector3D = new Vector3D();
    static private var _freeList:Vector.<Triangle> = new Vector.<Triangle>();
    
    static public function alloc() : Triangle {
        return _freeList.pop() || new Triangle();
    }
    public function free() : void {
        _freeList.push(this);
    }
    
    public function initialize(i0_:int, i1_:int, i2_:int, z_:Number) : Triangle {
        i0 = i0_;
        i1 = i1_;
        i2 = i2_;
        z = z_;
        return this;
    }
}

class Light {
    private var _position:Vector3D = new Vector3D();
    private var _halfVector:Vector3D = new Vector3D();
    public function get position() : Vector3D { return _position; }
    public function get halfVector() : Vector3D { return _halfVector; }
    
    function Light(x:Number, y:Number, z:Number) { setPosition(x, y, z); }
    
    public function setPosition(x:Number, y:Number, z:Number) : void {
        _position.x = x;
        _position.y = y;
        _position.z = z; 
        _position.normalize();
        _halfVector.x = _position.x;
        _halfVector.y = _position.y;
        _halfVector.z = _position.z + 1; 
        _halfVector.normalize();
    }
}

class Material {
    public var colorTable:BitmapData = new BitmapData(256,256,false);
    public var alpha:Number = 1;
    private var _nega_filter:int = 0;
    
    function Material() { setColor(0xc0c0c0, 1); }
    
    public function setColor(color:uint, alpha_:Number= 1.0, 
                             amb:int=64, dif:int=192, spc:int=0, pow:Number=8, emi:int=0, doubleSided:Boolean=false) : void
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

        _nega_filter = (doubleSided) ? -1 : 0;
    }
    
    public function calculateColor(light:Light, normal:Vector3D) : uint
    {
        var v:Vector3D, ln:int, hn:int, sign:int;
        
        // ambient
        v = light.position;
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
}
