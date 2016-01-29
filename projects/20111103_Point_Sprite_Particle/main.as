package {
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import flash.geom.*;
    import flash.text.*;
    import flash.net.*;
    
    import com.adobe.utils.*;
    import com.bit101.components.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
//    import org.si.ptolemy.*;
//    import org.si.ptolemy.core.*;
    
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sound.*;

    public class main extends Sprite {
/*      // for local
        private const gradURL:String = "grad.swf";
        private const partURL:String = "part.png";
/*/     // for wonderfl
        private const gradURL:String = "http://swf.wonderfl.net/swf/usercode/2/2c/2c1a/2c1a167b1a4db168e952e96df4e3d642544eb624.swf?t=1";
        private const partURL:String = "http://assets.wonderfl.net/images/related_images/6/6a/6a2d/6a2dffe6da5745c6a74c28a52a163077689afdab";
//*/
        
        private var controler:Sprite;
        private var ptolemy:Ptolemy;
        private var asm:AGALMiniAssembler = new AGALMiniAssembler();
        private var programs:Vector.<Program3D> = new Vector.<Program3D>();
        private var _psf:PointSpriteField;
        private var _texInfo:Vector.<PointSpriteTexInfo> = new Vector.<PointSpriteTexInfo>(4, true);
        private var _bmd:BitmapData, _tex:Texture;
        private var _prevTime:uint, _prevBeatTime:uint, _startTime:uint;
        
        private var sion:SiONDriver = new SiONDriver();
        private var beat:Number = 0, beatPerMS:Number;
        
        function main() {
            Wonderfl.disable_capture();
            ptolemy = new Ptolemy(this, 8, 8, 450, 450);
            ptolemy.addEventListener(Event.COMPLETE, setup);
            ptolemy.load(new URLRequest(gradURL), "grad", "img");
            ptolemy.load(new URLRequest(partURL), "particle", "img", true);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) : void {
                stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) : void {
                    stage.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);
                    stage.removeEventListener(MouseEvent.MOUSE_MOVE, _dragging);
                });
                stage.addEventListener(MouseEvent.MOUSE_MOVE, _dragging);
            })
        }
        
        private function setup(e:Event) : void {
            var i:int, prog:Program3D, a:Number, b:Number;
            var context3D:Context3D = ptolemy.context3D;
            removeEventListener(Event.COMPLETE, setup);
            context3D.enableErrorChecking = true;
            context3D.setCulling("none");
            context3D.setDepthTest(false, "always");
            context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
            _psf = new PointSpriteField(context3D, 1024);
            initialize();
            
            var GradEditor:Class = ptolemy.resources["grad"].getClass();
            addChild(controler = new Sprite());
            controler.x = controler.y = 8;
            controler.graphics.beginFill(0x404040, 0.6);
            controler.graphics.drawRect(0, 0, 180, 80);
            controler.graphics.endFill();
            with(new HUISlider(controler, 0, 20, "numEmitters", function(e:Event):void{ setting.emitCount = e.target.value;})) {
                setSliderParams(1, 64, setting.emitCount); tick = 1;
            }
            with(new HUISlider(controler, 0, 40, "particleShape", function(e:Event):void{ setting.tex = _texInfo[int(e.target.value)];})) {
                setSliderParams(0, 3, 0); tick = 1;
            }
            with(new HUISlider(controler, 0, 60, "bpm", function(e:Event):void{ sion.bpm = e.target.value; beatPerMS = sion.bpm / 60000;})) {
                setSliderParams(80, 200, 132);
            }
            var ge:* = new GradEditor(controler, 2, 2, "gradation", {color:[0xff8080,0x4040c0],alpha:[1,1],ratio:[0,192]}, 
function(e:Event):void { grad.create(ge.colorArray,ge.ratioArray);});
            ge.setSize(120,12);
            ge.changeImmediately = true;
            ge.alphaEnabled = false;
            _bmd = Bitmap(ptolemy.resources["particle"]).bitmapData;
            _tex = context3D.createTexture(_bmd.width, _bmd.height, "bgra", false);
            _tex.uploadFromBitmapData(_bmd);
            _texInfo[0] = new PointSpriteTexInfo(0,0,0.5,0.5,32,32);
            _texInfo[1] = new PointSpriteTexInfo(0.5,0,1,0.5,32,32);
            _texInfo[2] = new PointSpriteTexInfo(0,0.5,0.5,1,32,32);
            _texInfo[3] = new PointSpriteTexInfo(0.5,0.5,1,1,32,32);
            context3D.setTextureAt(0, _tex);
            
            for (i=0; i<shaders.length; i++) {
                prog = context3D.createProgram();
                prog.upload(asm.assemble("vertex", shaders[i].vs), asm.assemble("fragment", shaders[i].fs));
                programs.push(prog);
            }
            
            context3D.setProgramConstantsFromVector("vertex", 126, Vector.<Number>([ptolemy.sigl.pointSpriteFieldScale.x, ptolemy.sigl.pointSpriteFieldScale.y, 0, 0]));
            context3D.setProgramConstantsFromVector("vertex", 127, Vector.<Number>([0,0.5,1,2]));

            Emitter.tex = _texInfo[3];
            setting.tex = _texInfo[0];
            for (i=0; i<64; i++) emitters.push(new Emitter(i));
            _startTime = _prevBeatTime = _prevTime = getTimer();
            
            sion.bpm = 132;
            beatPerMS = sion.bpm / 60000;
            beat = 0;
            sion.addEventListener(SiONTrackEvent.BEAT, _onBeat);
            sion.play();
            new DrumMachine(0,8,0,2,2,0).play();
            
            addEventListener(Event.ENTER_FRAME, draw);
        }
        
        private function draw(e:Event) : void {
            var context3D:Context3D = ptolemy.context3D, i:int, 
                sigl:SiGLCore = ptolemy.sigl, s:Number = Math.random()*0.5 + 3,
                now:uint = getTimer(), dbeat:Number = (now-_prevBeatTime)*beatPerMS, dt:Number = (now-_prevTime)*0.001;
            
            var center:Vector3D = trocLarge.calc((now - _startTime)*0.00005);
            _psf.clearSprites();
            for (i=0; i<setting.emitCount; i++) emitters[i].update(_psf, dbeat+beat);
            Particle.update(_psf, dt);
            
            rx += (tx-rx)*0.05;
            rz += (tz-rz)*0.05;
            sigl.id().r(rx,Vector3D.X_AXIS).r(rz,Vector3D.Y_AXIS).t(center.x, center.y, center.z);
            context3D.clear(0, 0, 0, 1);
            context3D.setProgram(programs[0]);
            context3D.setProgramConstantsFromMatrix("vertex", 0, sigl.modelViewProjectionMatrix, true);
            _psf.drawTriangles(context3D);
            //if(!_sc){_sc = new BitmapData(450,450,false,0);with(addChildAt(new Bitmap(_sc),0)){x=y=8;}}context3D.drawToBitmapData(_sc);
            context3D.present();
            _prevTime = now;
        }
        private var _sc:BitmapData = null;
        
        private var rx:Number=0, rz:Number=0, tx:Number=0, tz:Number=0;
        private function _dragging(e:MouseEvent) : void {
            tz = (mouseX-233)*0.5;
            tx = (mouseY-233)*0.5;
        }
        
        private function _onBeat(e:SiONTrackEvent) : void {
            beat++;
            _prevBeatTime = getTimer();
        }
    }
}



var vs0:String = <agal><![CDATA[
m44 vt0, va0, vc0
mov vt1.xy, va1
mov vt1.zw, vc127.xx
div vt1.xy, vt1.xy, vt0.w
mul vt1.xy, vt1.xy, vc126.xy
add op, vt0, vt1
mov v0, va2
mov v1, va3
mov v2, va4
]]></agal>;
var fs0:String = <agal><![CDATA[
tex ft0, v0.xy, fs0 <2d, clamp, nearest>
mul ft0, ft0, v1
add ft0, ft0, v2
sat oc, ft0
]]></agal>;

var shaders:Array = [{"vs":vs0,"fs":fs0}];




import flash.geom.*;
import flash.display.*;
//import org.si.ptolemy.core.*;

var emitters:Array = [];
var emitCenter:Vector3D = new Vector3D();
var troc:Trochoid3D, trocLarge:Trochoid3D, grad:Gradation, setting:ParticleSetting;
var s$:Vector.<Number> = new Vector.<Number>(8192, true);
var c$:Vector.<Number> = new Vector.<Number>(8192, true);


function initialize() : void {
    for (var i:int=0;i<8192;i++) c$[(i-2048)&8191] = s$[i] = Math.sin(i*0.0007669903939428206);
    troc = new Trochoid3D(60, 40, 50, 3, 2, 5, 0, 0, 0);
    trocLarge = new Trochoid3D(400, 300, 400, 2, 1, 3, 0, 0, 0);
    grad = new Gradation();
    grad.create([0xff8080,0x402080,0],[0,128,255]);
    setting = new ParticleSetting({vvar:200, grav:-1000, vforce:-300, rotvar:1440, mag:2, life:2});
}

class ParticleSetting {
    public var vforce:Number = 0, reduction:Number = 0, life:Number = 1, lifevar:Number = 0;
    public var vini:Number = 0, vvar:Number = 0, vz:Number = 0, grav:Number = 0, acc:Number = 0;
    public var angini:Number = 0, angvar:Number = 0, rotini:Number=0, rotvar:Number=0;
    public var sclini:Number = 1, sclvar:Number = 0, mag:Number=1, tex:PointSpriteTexInfo;
    public var emitCount:int=10, emitInterval:int=2, numParticle:int=1;
    function ParticleSetting(param:* = null) {
        if (param) for (var key:String in param) this[key] = param[key];
    }
}


class Trochoid3D {
    public var r0:Number, r1:Number, r2:Number, f0:Number, f1:Number, f2:Number, p0:Number, p1:Number, p2:Number;
    public var $:Vector3D = new Vector3D(), matrix3D:Matrix3D = new Matrix3D();
    static private var _in:Vector.<Number> = new Vector.<Number>(3, true);
    static private var _out:Vector.<Number> = new Vector.<Number>(3, true);
    function Trochoid3D(r0:Number=1, r1:Number=0.5, r2:Number=0.71, f0:Number=2, f1:Number=1, f2:Number=3, p0:Number=0, p1:Number=0, p2:Number=0) {
        init(r0, r1, r2, f0, f1, f2, p0, p1, p2);
    }
    public function init(r0:Number, r1:Number, r2:Number, f0:Number, f1:Number, f2:Number, p0:Number=0, p1:Number=0, p2:Number=0) : void {
        this.r0 = r0; this.p0 = p0 * 6.283185307179586; this.f0 =  f0 * 6.283185307179586; 
        this.r1 = r1; this.p1 = p1 * 6.283185307179586; this.f1 = -f1 * 6.283185307179586; 
        this.r2 = r2; this.p2 = p2 * 6.283185307179586; this.f2 =  f2 * 6.283185307179586;
    }
    public function calc(t:Number) : Vector3D {
        var a0:Number = t*f0+p0, a1:Number = t*f1+p1, a2:Number = t*f2+p2, 
            s0:Number = Math.sin(a0), s1:Number = Math.sin(a1), s2:Number = Math.sin(a2), 
            c0:Number = Math.cos(a0), c1:Number = Math.cos(a1);
        _in[0] = c0 * r0 + c1 * r1;
        _in[1] = s0 * r0 + s1 * r1;
        _in[2] = s2 * r2;
        matrix3D.transformVectors(_in, _out);
        $.setTo(_out[0], _out[1], _out[2]);
        return $;
    }
}

class Gradation {
    public var $:Vector.<Vector3D> = new Vector.<Vector3D>(512, true);
    function Gradation() { for (var i:int=0; i<512; i++) $[i] = new Vector3D(1,1,1); }
    public function create(color:Array, ratio:Array) : void {
        var m:Matrix = new Matrix(), s:Shape = new Shape(), g:Graphics = s.graphics,
            b:BitmapData = new BitmapData(512, 1, false), i:int, c:uint, alpha:Array=[];
        for (i=0; i<color.length; i++) alpha.push(1);
        m.createGradientBox(512, 1, 0, 0, 0);
        g.beginGradientFill("linear", color, alpha, ratio, m);
        g.drawRect(0,0,512,1);
        g.endFill();
        b.draw(s);
        for (i=0; i<512; i++) {
            c = b.getPixel(i, 0);
            $[i].x = ((c>>16) & 0xff) * 0.00392156862745098;
            $[i].y = ((c>>8)  & 0xff) * 0.00392156862745098;
            $[i].z = ( c      & 0xff) * 0.00392156862745098;
        }
    }
}

class Emitter extends Vector3D {
    static public var tex:PointSpriteTexInfo;
    static private var _in:Vector.<Number> = new Vector.<Number>(3);
    static private var _out:Vector.<Number> = new Vector.<Number>(3)
    static private var _mat:Matrix3D = new Matrix3D();
    static private var _vec:Vector3D = new Vector3D();
    public var index:Number, prev:Vector3D, count:int=0;
    function Emitter(index:Number) { super(); this.index = index; prev = clone(); }
    public function update(psf:PointSpriteField, beat:Number) : void {
        var t:Number = index/setting.emitCount, c:Vector3D = trocLarge.$, r:Vector3D = troc.calc(beat/setting.emitCount+t);
        setTo(r.x-c.x, r.y-c.y, r.z-c.z);
        psf.createSprite(tex, x, y, z);
        if (++count >= setting.emitInterval) {
            _vec.setTo(x-prev.x, y-prev.y, z-prev.z);
            _vec.normalize();
            for (var i:int=0; i<setting.numParticle; i++) Particle.alloc(x, y, z, _vec);
            count = 0;
        }
        prev.copyFrom(this);
    }
}

class Particle extends Vector3D {
    static private var _vtemp:Vector3D = new Vector3D();
    static private var _activeList:Particle = null;
    static private var _freeList:Particle = null;
    public var next:Particle, tex:PointSpriteTexInfo, life:Number, age:Number;
    public var vx:Number, vy:Number, vz:Number, ax:Number, ay:Number, az:Number;
    public var scale:Number, dscale:Number, angle:int, dangle:Number, cvec:Vector.<Vector3D>;
    static public function alloc(x:Number, y:Number, z:Number, vel:Vector3D) : Particle {
        var newPart:Particle = _freeList || new Particle(), 
            life:Number = setting.life + setting.lifevar * (Math.random() - 0.5), 
            v:Number    = setting.vini + setting.vvar * (Math.random()-0.5), 
            acc:Number  = setting.acc / life;
        if (_freeList) _freeList = _freeList.next;
        _vtemp.setTo(Math.random()-0.5, Math.random()-0.5, Math.random()-0.5+setting.vz);
        _vtemp.normalize();
        newPart.tex = setting.tex;
        newPart.cvec = grad.$;
        newPart.life = life;
        newPart.age = 0;
        newPart.setTo(x, y, z);
        newPart.vx = vel.x * setting.vforce + _vtemp.x * v;
        newPart.vy = vel.y * setting.vforce + _vtemp.y * v;
        newPart.vz = vel.z * setting.vforce + _vtemp.z * v;
        newPart.ax = newPart.vx * acc;
        newPart.ay = newPart.vy * acc;
        newPart.az = newPart.vz * acc + setting.grav;
        newPart.scale = setting.sclini + setting.sclvar * (Math.random()-0.5);
        newPart.dscale = newPart.scale * (setting.mag - 1);
        newPart.angle = (setting.angini + setting.angvar * (Math.random()-0.5))*22.755555555555556; // 8192/360
        newPart.dangle = (setting.rotini + setting.rotvar * (Math.random()-0.5))*22.755555555555556;
        if (Math.random() < 0.5) newPart.dangle = -newPart.dangle;
        newPart.next = _activeList;
        return _activeList = newPart;
    }
    static public function update(psf:PointSpriteField, dt:Number) : void {
        var p:Particle, prev:Particle, t:Number, ang:int, col:int, scl:Number, sin:Number, cos:Number, c:Vector3D;
        for (p=_activeList; p;) {
            p.age += dt;
            if (p.age < p.life) {
                t = p.age / p.life;
                p.x += (p.vx + p.ax * dt * 0.5) * dt;
                p.y += (p.vy + p.ay * dt * 0.5) * dt;
                p.z += (p.vz + p.az * dt * 0.5) * dt;
                p.vx += (p.ax - p.vx * setting.reduction) * dt;
                p.vy += (p.ay - p.vy * setting.reduction) * dt;
                p.vz += (p.az - p.vz * setting.reduction) * dt;
                ang = (int(p.angle + p.dangle * t))&8191;
                scl = p.scale + p.dscale * t;
                col = int(t * 511);
                sin = s$[ang]; cos = c$[ang]; c = p.cvec[col];
                psf.createSprite(p.tex, p.x, p.y, p.z, scl*cos, -scl*sin, scl*sin, scl*cos, c.x*1.25, c.y*1.25, c.z*1.25, 1);
                prev = p; p = prev.next;
            } else {
                if (prev) { prev.next   = p.next; p.next = _freeList; _freeList = p; p = prev.next; } 
                else      { _activeList = p.next; p.next = _freeList; _freeList = p; p = _activeList; }
            }
        }
    }
}






/* Tiny Ptolemy */ {
    import flash.net.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.system.*;
    import flash.display.*;
    import flash.display3D.*;
    import com.adobe.utils.*;

    /** Operation Center */
    class Ptolemy extends EventDispatcher {
    // variables ----------------------------------------
        public var context3D:Context3D;
        public var sigl:SiGLCore;
        public var resources:* = {};

        private var _loadedResourceCount:int;
    // constructor ----------------------------------------
        function Ptolemy(parent:DisplayObjectContainer, xpos:Number, ypos:Number ,width:int, height:int) : void {
            var stage:Stage = parent.stage, stage3D:Stage3D = stage.stage3Ds[0];
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.LOW;
            stage3D.x = xpos; stage3D.y = ypos;
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, function(e:Event):void{
                context3D = e.target.context3D;
                if (context3D) {
                    context3D.enableErrorChecking = true;                   // check internal error
                    context3D.configureBackBuffer(width, height, 0, true);  // disable AA/ enable depth/stencil
                    context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
                    context3D.setCulling(Context3DTriangleFace.BACK);       // culling back face
                    context3D.setRenderToBackBuffer();
                    sigl = new SiGLCore(width, height);
                    dispatchEvent(e.clone());
                    if (--_loadedResourceCount == 0) dispatchEvent(new Event(Event.COMPLETE));
                } else dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Context3D not found"));
            });
            stage3D.requestContext3D();
            _loadedResourceCount = 1;
        }
    // load resource ----------------------------------------
        public function load(urlRequest:URLRequest, id:String=null, type:String=null, checkPolicyFile:Boolean=false) : EventDispatcher {
            var loader:Loader, urlLoader:URLLoader;
            _loadedResourceCount++;
            if (type == "img") {
                loader = new Loader();
                loader.load(urlRequest, new LoaderContext(checkPolicyFile));
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) : void {
                    resources[id] = e.target.content;
                    if (--_loadedResourceCount == 0) dispatchEvent(new Event(Event.COMPLETE));
                });
                return loader;
            }
            urlLoader = new URLLoader(urlRequest);
            urlLoader.dataFormat = (type == "txt") ? URLLoaderDataFormat.TEXT : URLLoaderDataFormat.BINARY;
            urlLoader.addEventListener(Event.COMPLETE, function(e:Event) : void {
                resources[id] = e.target.data;
                if (--_loadedResourceCount == 0) dispatchEvent(new Event(Event.COMPLETE));
            });
            return urlLoader;
        }
    }
    
    /** SiGLCore provides basic matrix operations. */
    class SiGLCore {
    // variables ----------------------------------------
        public var modelViewMatrix:Matrix3D = new Matrix3D(), projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
        public var viewWidth:Number, viewHeight:Number, pointSpriteFieldScale:Point = new Point();
        private var _mvMatrixStac:Vector.<Matrix3D> = new Vector.<Matrix3D>();
        private var _mvpMatrix:Matrix3D = new Matrix3D(), _mvpMatrixDirty:Boolean, _toDegree:Number, _toRadian:Number;
        private var _cameraPosition:Vector3D = new Vector3D(0,0,0), _magnification:Number, _zNear:Number, _zFar:Number, _fieldOfView:Number;
        static private var _tv:Vector.<Number> = new Vector.<Number>(16, true), _tm:Matrix3D = new Matrix3D();
    // properties ----------------------------------------
        public function get modelViewProjectionMatrix() : Matrix3D {
            if (_mvpMatrixDirty) {
                _mvpMatrix.copyFrom(projectionMatrix);
                _mvpMatrix.prepend(modelViewMatrix);
                _mvpMatrixDirty = false;
            }
            return _mvpMatrix;
        }
        public function get angleMode() : String { return (_toRadian == 1) ? "radian" : "degree"; }
        public function set angleMode(mode:String) : void { _toDegree = (mode == "radian") ? 57.29577951308232 : 1; _toRadian = (mode == "radian") ? 1 : 0.017453292519943295; }
        public function get fieldOfView() : Number { return _fieldOfView / _toRadian; }
        public function set fieldOfView(fov:Number) : void { _fieldOfView = fov * _toRadian; _updateProjectionMatrix(); }
        public function get magnification() : Number { return _magnification; }
        public function set magnification(mag:Number) : void { _magnification = mag; _updateProjectionMatrix(); }
        public function get cameraPosition() : Vector3D { return _cameraPosition; }
    // constructor ----------------------------------------
        function SiGLCore(width:Number=1, height:Number=1) {
            viewWidth = width; viewHeight = height;
            angleMode = "degree"; _magnification = 1;
            _zNear = -200; _zFar = 1000;
            modelViewMatrix.identity();
            _mvpMatrixDirty = true;
            this.fieldOfView = 60;
        }
    // matrix operations ----------------------------------------
        public function forceUpdateMatrix() : SiGLCore { _mvpMatrixDirty = true; return this; }
        public function setZRange(zNear:Number=-100, zFar:Number=100) : SiGLCore { _zNear = zNear; _zFar = zFar; _updateProjectionMatrix(); return this; }
        public function clear() : SiGLCore { _mvMatrixStac.length = 0; return id(); }
        public function id() : SiGLCore { modelViewMatrix.identity(); _mvpMatrixDirty = true; return this; }
        public function push() : SiGLCore { _mvMatrixStac.push(modelViewMatrix.clone()); return this; }
        public function pop() : SiGLCore { modelViewMatrix = _mvMatrixStac.pop(); return this; }
        public function r(angle:Number, axis:Vector3D, pivotPoint:Vector3D = null) : SiGLCore { modelViewMatrix.prependRotation(angle*_toDegree, axis, pivotPoint); _mvpMatrixDirty = true; return this; }
        public function s(scaleX:Number, scaleY:Number, scaleZ:Number=1) : SiGLCore { modelViewMatrix.prependScale(scaleX, scaleY, scaleZ); _mvpMatrixDirty = true; return this; }
        public function t(x:Number, y:Number, z:Number=0) : SiGLCore { modelViewMatrix.prependTranslation(x, y, z); _mvpMatrixDirty = true; return this; }
        public function re(angleX:Number, angleY:Number, angleZ:Number) : SiGLCore {
            var rx:Number = angleX*_toRadian, ry:Number=angleY*_toRadian, rz:Number=angleZ*_toRadian,
                sx:Number = Math.sin(rx), sy:Number = Math.sin(ry), sz:Number = Math.sin(rz), 
                cx:Number = Math.cos(rx), cy:Number = Math.cos(ry), cz:Number = Math.cos(rz);
            _tv[0] = cz*cy; _tv[1] = sz*cy; _tv[2] = -sy; _tv[4] = -sz*cx+cz*sy*sx; _tv[5] = cz*cx+sz*sy*sx;
            _tv[6] = cy*sx; _tv[8] = sz*sx+cz*sy*cx; _tv[9] = -cz*sx+sz*sy*cx;
            _tv[10] = cy*cx; _tv[14] = _tv[13] = _tv[12] = _tv[11] = _tv[7] = _tv[3] = 0; _tv[15] = 1;
            _tm.copyRawDataFrom(_tv); modelViewMatrix.prepend(_tm); _mvpMatrixDirty = true;
            return this;
        }
        private function _updateProjectionMatrix() : void {
            var aspect:Number = viewWidth / viewHeight;
            _cameraPosition.z = (viewHeight * 0.5) / Math.tan(_fieldOfView * 0.5);
            if (_zNear <= -_cameraPosition.z) _zNear = -_cameraPosition.z + 0.001;
            projectionMatrix.perspectiveFieldOfViewRH(_fieldOfView, aspect, _zNear + _cameraPosition.z, _zFar + _cameraPosition.z);
            pointSpriteFieldScale.setTo(projectionMatrix.rawData[0] * _cameraPosition.z, projectionMatrix.rawData[5] * _cameraPosition.z);
            projectionMatrix.prependTranslation(-_cameraPosition.x, -_cameraPosition.y, -_cameraPosition.z);
            projectionMatrix.prependScale(_magnification, _magnification, _magnification);
        }
    }


    /** Mesh */
    class Mesh {
    // variables ----------------------------------------
        public var vertices:Vector.<Number> = new Vector.<Number>();
        public var faces:Vector.<Face> = new Vector.<Face>();
        public var vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D;
        public var data32PerVertex:int, attributeList:Array = [];
        private var _indices:Vector.<uint> = new Vector.<uint>(), _indexDirty:Boolean=true;
    // properties ----------------------------------------
        public function get vertexCount() : int { return vertices.length / data32PerVertex; }
        public function set vertexCount(count:int) : void { vertices.length = count * data32PerVertex; }
        public function get indices() : Vector.<uint> {
            var idx:Vector.<uint> = _indices, f:Face, i:int, imax:int, j:int;
            if (_indexDirty) {
                idx.length = imax = faces.length * 3;
                for (i=0,j=0; i<imax; j++) {
                    f = faces[j];
                    idx[i] = f.i0; i++;
                    idx[i] = f.i1; i++;
                    idx[i] = f.i2; i++;
                }
                _indexDirty = false;
            }
            return idx;
        }
    // contructor ----------------------------------------
        function Mesh(bufferFormat:String="V3") {
            var rex:RegExp = /([_a-zA-Z]+)([1234b])/g, res:*, i:int=0;
            data32PerVertex = 0;
            while (res = rex.exec(bufferFormat)) data32PerVertex += (attributeList[i++]=int(res[2]));
        }
    // oprations ----------------------------------------
        public function allocateBuffer(context3D:Context3D) : Mesh {
            vertexBuffer = context3D.createVertexBuffer(vertexCount, data32PerVertex);
            indexBuffer  = context3D.createIndexBuffer(indices.length);
            return this;
        }
        public function upload(vertex:Boolean=true, index:Boolean=true) : Mesh {
            if (vertex) vertexBuffer.uploadFromVector(vertices, 0, vertexCount);
            if (index) indexBuffer.uploadFromVector(indices, 0, indices.length);
            return this;
        }
        public function drawTriangles(context3D:Context3D) : Mesh {
            var i:int, offset:int=0, form:Array = ["","float1","float2","float3","float4"];
            for (i=0; i<attributeList.length; offset+=attributeList[i++]) context3D.setVertexBufferAt(i, vertexBuffer, offset, form[attributeList[i]]);
            context3D.drawTriangles(indexBuffer, 0, faces.length);
            return this;
        }
        public function face(i0:int, i1:int, i2:int) : Mesh { faces.push(Face.alloc(i0, i1, i2)); _indexDirty = true; return this; }
        public function qface(i0:int, i1:int, i2:int, i3:int) : Mesh { faces.push(Face.alloc(i0, i1, i2), Face.alloc(i3, i2, i1)); _indexDirty = true; return this; }
        public function updateFaceNormal(updateVertexNormal:Boolean=true) : Mesh {
            var vtx:Vector.<Number> = vertices, vcount:int = vertexCount, fcount:int = faces.length, 
                i:int, istep:int, f:Face, iw:Number, fidx:int,  i0:int, i1:int, i2:int, n0:Vector3D, n1:Vector3D, n2:Vector3D, 
                x01:Number, x02:Number, y01:Number, y02:Number, z01:Number, z02:Number;
            // calculate face normals
            for (i=0; i<fcount; i++) {
                f=faces[i];
                i0=f.i0*data32PerVertex; i1=f.i1*data32PerVertex; i2=f.i2 * data32PerVertex;
                x01 = vtx[i1]-vtx[i0]; x02 = vtx[i2]-vtx[i0]; i0++; i1++; i2++;
                y01 = vtx[i1]-vtx[i0]; y02 = vtx[i2]-vtx[i0]; i0++; i1++; i2++;
                z01 = vtx[i1]-vtx[i0]; z02 = vtx[i2]-vtx[i0];
                f.normal.setTo(y02*z01-y01*z02, z02*x01-z01*x02, x02*y01-x01*y02);
                f.normal.normalize();
            }
            // calculate vertex normals
            if (updateVertexNormal) {
                istep = data32PerVertex - 2;
                // initialize
                for (i=0, i0=3; i<vcount; i++, i0+=istep) { vtx[i0]=0; i0++; vtx[i0]=0; i0++; vtx[i0]=0; }
                // sum up
                for (i=0; i<fcount; i++) {
                    f = faces[i];
                    i0 = f.i0 * data32PerVertex + 3;
                    vtx[i0]+=f.normal.x; i0++; vtx[i0]+=f.normal.y; i0++; vtx[i0]+=f.normal.z;
                    i0 = f.i1 * data32PerVertex + 3;
                    vtx[i0]+=f.normal.x; i0++; vtx[i0]+=f.normal.y; i0++; vtx[i0]+=f.normal.z;
                    i0 = f.i2 * data32PerVertex + 3;
                    vtx[i0]+=f.normal.x; i0++; vtx[i0]+=f.normal.y; i0++; vtx[i0]+=f.normal.z;
                }
                /* normalize (ussualy normalizing by gpu).
                for (i=0, i0=3; i<vcount; i++, i0+=istep) {
                    x01 = vtx[i0]; i0++; y01 = vtx[i0]; i0++; z01 = vtx[i0]; i0-=2;
                    iw = 1 / Math.sqrt(x01*x01 + y01*y01 + z01*z01);
                    vtx[i0] = x01 * iw; i0++; vtx[i0] = y01 * iw; i0++; vtx[i0] = z01 * iw;
                }
                //*/
            }
            return this;
        }
    }


    /** Face */
    class Face {
        public var i0:int, i1:int, i2:int, normal:Vector3D = new Vector3D();
        function Face() { i0 = i1 = i2 = 0; }
        static private var _freeList:Vector.<Face> = new Vector.<Face>();
        static public function free(face:Face) : void { _freeList.push(face); }
        static public function alloc(i0:int, i1:int, i2:int) : Face { 
            var f:Face = _freeList.pop() || new Face();
            f.i0 = i0; f.i1 = i1; f.i2 = i2; return f;
        }
    }
    
    
    /** Point Sprite Field */
    class PointSpriteField extends Mesh {
    // variables --------------------------------------------------
        private var spriteCount:int;
        private var maxSpriteCount:int;
    // constructor --------------------------------------------------
        function PointSpriteField(context3D:Context3D, maxSpriteCount:int=1024) {
            var i:int, j:int;
            super("V3S2T2C4O4");
            this.maxSpriteCount = maxSpriteCount;
            vertexCount = maxSpriteCount * 4;
            spriteCount = 0;
            for (i=0; i<vertices.length; i++) vertices[i] = 0;
            for (i=0, j=0; i<maxSpriteCount; i++) qface(j++, j++, j++, j++);
            allocateBuffer(context3D);
            upload();
        }
    // operations --------------------------------------------------
        public function clearSprites() : PointSpriteField { spriteCount = 0; return this; }
        public function createSprite(tex:PointSpriteTexInfo, x:Number, y:Number, z:Number=0, 
                                     mata:Number=1, matb:Number=0, matc:Number=0, matd:Number=1,
                                     rmul:Number=1, gmul:Number=1, bmul:Number=1, amul:Number=1, 
                                     radd:Number=0, gadd:Number=0, badd:Number=0, aadd:Number=0) : PointSpriteField {
            var wa:Number = tex.hw*mata, wc:Number = tex.hw*matc, hb:Number = tex.hh*matb, hd:Number = tex.hh*matd, 
                v0x:Number = -wa+hb, v0y:Number = -wc+hd, v1x:Number = wa+hb, v1y:Number = wc+hd, 
                i0:int = spriteCount*data32PerVertex*4, i1:int=i0+data32PerVertex, i2:int=i1+data32PerVertex, i3:int=i2+data32PerVertex;
            if (spriteCount == maxSpriteCount) return this;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = x; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = y; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = z; i0++; i1++; i2++; i3++;
            vertices[i3] = -(vertices[i0] = v0x); i0++; i3++;
            vertices[i3] = -(vertices[i0] = v0y); i0++; i3++;
            vertices[i2] = -(vertices[i1] = v1x); i1++; i2++;
            vertices[i2] = -(vertices[i1] = v1y); i1++; i2++;
            vertices[i0] = vertices[i2] = tex.u0; i0++; i2++;
            vertices[i1] = vertices[i3] = tex.u1; i1++; i3++;
            vertices[i0] = vertices[i1] = tex.v0; i0++; i1++;
            vertices[i2] = vertices[i3] = tex.v1; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = rmul; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = gmul; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = bmul; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = amul; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = radd; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = gadd; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = badd; i0++; i1++; i2++; i3++;
            vertices[i0] = vertices[i1] = vertices[i2] = vertices[i3] = aadd; i0++; i1++; i2++; i3++;
            spriteCount++;
            return this;
        }
        override public function drawTriangles(context3D:Context3D) : Mesh {
            if (spriteCount) {
                vertexBuffer.uploadFromVector(vertices, 0, spriteCount*4);
                context3D.setVertexBufferAt(0, vertexBuffer,  0, Context3DVertexBufferFormat.FLOAT_3);
                context3D.setVertexBufferAt(1, vertexBuffer,  3, Context3DVertexBufferFormat.FLOAT_2);
                context3D.setVertexBufferAt(2, vertexBuffer,  5, Context3DVertexBufferFormat.FLOAT_2);
                context3D.setVertexBufferAt(3, vertexBuffer,  7, Context3DVertexBufferFormat.FLOAT_4);
                context3D.setVertexBufferAt(4, vertexBuffer, 11, Context3DVertexBufferFormat.FLOAT_4);
                context3D.drawTriangles(indexBuffer, 0, spriteCount*2);
            }
            return this;
        }
    }

    
    /** Point Sprite Texture Infomation */
    class PointSpriteTexInfo {
        public var u0:Number, v0:Number, u1:Number, v1:Number, hw:Number, hh:Number;
        function PointSpriteTexInfo(u0:Number, v0:Number, u1:Number, v1:Number, width:Number, height:Number) {
            this.u0 = u0; this.v0 = v0; this.u1 = u1; this.v1 = v1; this.hw = width * 0.5; this.hh = height * 0.5;
        }
    }
}

