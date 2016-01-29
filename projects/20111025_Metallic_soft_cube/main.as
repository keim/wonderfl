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
    //import org.si.ptolemy.*;
    //import org.si.ptolemy.core.*;

    public class main extends Sprite {
/*      // for local
        private const cceURL:String = "cce.swf";
        private const envURL:String = "_env1.png";
/*/     // for wonderfl
        private const cceURL:String = "http://swf.wonderfl.net/swf/usercode/6/67/679c/679c3b410a599d83b3548ce73ce37b873ae4046b.swf?t=1319478894168";
        private const envURL:String = "http://assets.wonderfl.net/images/related_images/b/b2/b217/b2177f87d979a28b9bcbb6e0b89370e77ce22337";
//*/
        
        private var container:Sprite;
        private var ptolemy:Ptolemy;
        
        private var asm:AGALMiniAssembler = new AGALMiniAssembler();
        private var programs:Vector.<Program3D> = new Vector.<Program3D>();

        private var _boxVertex:Vector.<Vector3D> = new Vector.<Vector3D>();
        private var _sphVertex:Vector.<Vector3D> = new Vector.<Vector3D>();
        private var _sphNormal:Vector.<Vector3D> = new Vector.<Vector3D>();
        private var _effector:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
        private var _gravPoints:Vector.<Vector3D> = new Vector.<Vector3D>(8);
        private var _amplitude:Vector.<Number> = new Vector.<Number>(8);
        private var _mesh:Mesh = new Mesh("V3N3");
        
        private var _ifreq:Number;
        private var _phase:Number;
        private var _rotx:Number;

        private var _ambVector:Vector.<Number> = Vector.<Number>([0.2,0.2,0.3,1]);
        private var _difVectorDif:Vector.<Number> = Vector.<Number>([0.4,0.4,0.6,1]); 
        private var _col:uint = 0x80c0e0;
        private var _amb:Number = 0.3;
        private var _dif:Number = 0.9;
        private var _ref:Number = 0.25;
        private var _pow:Number = 16;
        private var _spc:Number = 200;
        private var _var:Number = 0.5;
        private var _shp:Number = 0.5;
        private var _specMap:BitmapData;
        private var _specTex:Texture;
        private var _shpereMap:BitmapData;
        private var _shpereTex:Texture;
        
        private var _startTime:Number;
        private var _lightPosition:Vector3D = new Vector3D();
        private var _halfVector:Vector3D = new Vector3D();
        
        function main() {
            Wonderfl.disable_capture();
            ptolemy = new Ptolemy(this, 8, 8, 450, 450);
            ptolemy.addEventListener(Event.COMPLETE, setup);
            ptolemy.load(new URLRequest(cceURL), "cce", "img", true);
            ptolemy.load(new URLRequest(envURL), "env", "img", true);
        }
        
        
        private function setup(e:Event) : void {
            var px:Number, py:Number, i:int, j:int, k:int, i0:int;
            var context3D:Context3D = ptolemy.context3D, prog:Program3D;
            removeEventListener(Event.COMPLETE, setup);
            
            context3D.enableErrorChecking = true;
            
            // create shape 
            for (i=0; i<8; i++) {
                _gravPoints[i] = new Vector3D(((i&1)<<1)*120-120, (i&2)*120-120, ((i&4)>>1)*120-120);
                _amplitude[i] = 1;
            }
            for (px=-84; px<90; px+=12) for (py=-84; py<90; py+=12) {
                _vertex( px, py, 84);
                _vertex( px,-py,-84);
                _vertex( py, 84, px);
                _vertex(-py,-84, px);
                _vertex( 84, px, py);
                _vertex(-84, px,-py);
            }
            for (i=0; i<14; i++) for (j=0; j<14; j++) for (k=0; k<6; k++) {
                i0 = (i*15+j)*6+k;
                _mesh.qface(i0, i0+6, i0+90, i0+96);
            }
            _mesh.vertexCount = _boxVertex.length;
            _mesh.allocateBuffer(context3D);
            _mesh.upload(false, true);
            
            _shpereMap = ptolemy.resources["env"].bitmapData;
            _shpereTex = context3D.createTexture(512, 512, "bgra", false);
            _shpereTex.uploadFromBitmapData(_shpereMap);
            _specMap = new BitmapData(256, 1, false, 0);
            _specTex = context3D.createTexture(256, 1, "bgra", false);
            context3D.setTextureAt(0, _specTex);
            context3D.setTextureAt(1, _shpereTex);
            for (i=0; i<shaders.length; i++) {
                prog = context3D.createProgram();
                prog.upload(asm.assemble("vertex", shaders[i].vs), asm.assemble("fragment", shaders[i].fs));
                programs.push(prog);
            }
            context3D.setProgramConstantsFromVector("vertex",   9, Vector.<Number>([0, 0.5, 1, 2]));
            context3D.setProgramConstantsFromVector("fragment", 9, Vector.<Number>([0, 0.5, 1, 2]));
            
            addChild(container = new Sprite());
            container.x = container.y = 8;
            var ColorChooserEx:Class = ptolemy.resources["cce"].getClass();
            new ColorChooserEx(container, 0, 0, _col,  function(e:Event):void { _col = e.target.value; updateColor();});
            new HUISlider(container, 0, 20, "ambient", function(e:Event):void { _amb = e.target.value; updateColor();}).setSliderParams(0,1,_amb);
            new HUISlider(container, 0, 40, "diffuse", function(e:Event):void { _dif = e.target.value; updateColor();}).setSliderParams(0,1,_dif);
            new HUISlider(container, 0, 60, "power",   function(e:Event):void { _pow = e.target.value; updateSpecMap();}).setSliderParams(0,64,_pow);
            new HUISlider(container, 0, 80, "specular",function(e:Event):void { _spc = e.target.value; updateSpecMap();}).setSliderParams(0,255,_spc);
            new HUISlider(container, 0, 100, "refrection",function(e:Event):void { _ref = e.target.value; }).setSliderParams(0,1,_ref);
            new HUISlider(container, 0, 410, "variance",  function(e:Event):void { _var = e.target.value; updateSpecMap();}).setSliderParams(0,1,_var);
            new HUISlider(container, 0, 430, "shape",     function(e:Event):void { _shp = e.target.value; }).setSliderParams(-1,1,_shp);
            updateSpecMap();
            updateColor();

            _rotx = 0;
            _startTime = getTimer();
            addEventListener(Event.ENTER_FRAME, draw);
            

            _ifreq = 3.141592653589793/(60000/(80));
        }
        
        private function _vertex(x:Number, y:Number, z:Number) : void {
            var vec:Vector3D = new Vector3D(x, y, z),  nml:Vector3D = vec.clone(), sph:Vector3D,
                effect:Vector.<Number> = new Vector.<Number>(8, true), i:int;
            for (i=0; i<8; i++) {
                effect[i] = (240 - Vector3D.distance(_gravPoints[i], vec)) / 100;
                if (effect[i] < 0) effect[i] = 0;
            }
            nml.normalize();
            sph = nml.clone();
            sph.scaleBy(112);
            _boxVertex.push(vec);
            _sphVertex.push(sph);
            _sphNormal.push(nml);
            _effector.push(effect);
        }

        private function updateSpecMap() : void {
            for (var i:int=0; i<256; i++) {
                var c:int = int(Math.pow(i*0.0039215686, _pow)*_spc);
                _specMap.setPixel32(i, 0, ((c<255)?c:255)*0x10101);
            }
            _specTex.uploadFromBitmapData(_specMap);

        }
        
        private function updateColor() : void {
            var r:Number = ((_col>>16)&255)*0.00392156862745098,
                g:Number = ((_col>>8)&255)*0.00392156862745098,
                b:Number = (_col&255)*0.00392156862745098, difamb:Number = _dif - _amb;
            _difVectorDif[0] = r * difamb;
            _difVectorDif[1] = g * difamb;
            _difVectorDif[2] = b * difamb;
            _ambVector[0] = r * _amb;
            _ambVector[1] = g * _amb;
            _ambVector[2] = b * _amb;
        }
        
        private function draw(e:Event) : void {
            var context3D:Context3D = ptolemy.context3D,
                sigl:SiGLCore = ptolemy.sigl, 
                time:Number = getTimer() - _startTime;
            
            var i:int, imax:int = _mesh.vertexCount, j:int, idx:int, bv:Vector3D, sv:Vector3D, 
                vstep:int = _mesh.data32PerVertex, vertices:Vector.<Number> = _mesh.vertices;
            
            // geometry blending
            _phase = time * 0.00005 + 0.1;
            for (j=0; j<8; j++) {
                _amplitude[j] = (Math.cos(time * _ifreq + j * _phase)) * _var + _shp;
            }
            
            var rat:Number, eff:Vector.<Number>;
            for (i=0; i<imax; i++) {
                idx = i * vstep;
                bv = _boxVertex[i];
                sv = _sphVertex[i];
                eff = _effector[i];
                for (rat=0, j=0; j<8; j++) rat += eff[j] * _amplitude[j];
                vertices[idx] = sv.x * (1-rat) + bv.x * rat; idx++;
                vertices[idx] = sv.y * (1-rat) + bv.y * rat; idx++;
                vertices[idx] = sv.z * (1-rat) + bv.z * rat;
            }
            _mesh.updateFaceNormal(true);
            _mesh.upload(true, false);

            _rotx += Math.sin(time*0.0002) * 3;
            sigl.id().re(_rotx, time*0.02, time*0.05);
            
            // lighting vector
            _lightPosition.x = 232-mouseX;
            _lightPosition.y = mouseY-232;
            _lightPosition.z = 50;
            _lightPosition.normalize();
            _halfVector.copyFrom(_lightPosition);
            _halfVector.z += 1;
            _halfVector.normalize();
            _inv.copyFrom(sigl.modelViewMatrix);
            _inv.invert();
            var l:Vector3D = _inv.deltaTransformVector(_lightPosition);
            var h:Vector3D = _inv.deltaTransformVector(_halfVector);
            
            // drawing
            context3D.clear(0.125, 0.125, 0.125, 1);
            context3D.setProgram(programs[0]);
            context3D.setVertexBufferAt(0, _mesh.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
            context3D.setVertexBufferAt(1, _mesh.vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            context3D.setProgramConstantsFromMatrix("vertex",   4, sigl.modelViewMatrix, true);
            context3D.setProgramConstantsFromVector("fragment", 0, Vector.<Number>([l.x, l.y, l.z, 0]));
            context3D.setProgramConstantsFromVector("fragment", 1, Vector.<Number>([h.x, h.y, h.z, 0]));
            context3D.setProgramConstantsFromVector("fragment", 2, _ambVector);
            context3D.setProgramConstantsFromVector("fragment", 3, _difVectorDif);
            context3D.setProgramConstantsFromVector("fragment", 4, Vector.<Number>([_ref, 0, 0, 0]));
            context3D.drawTriangles(_mesh.indexBuffer, 0, _mesh.indices.length/3);
            context3D.present();
        }
        private var _inv:Matrix3D = new Matrix3D();
    }
}



var vs0:String = <agal><![CDATA[
m44 op, va0, vc0
nrm vt0.xyz, va1.xyz
mov vt0.w, vc9.x
mov v0, vt0
m44 vt0, vt0, vc4
mul vt0, vt0, vc9.yyy
add v1,  vt0, vc9.yyy
]]></agal>;
var fs0:String = <agal><![CDATA[
dp3 ft0, v0, fc0
sat ft0, ft0
mul ft0, fc3, ft0
add ft0, ft0, fc2
dp3 ft1, v0, fc1
tex ft3, ft1.xy, fs0 <2d,clamp,nearest>
tex ft4, v1.xy, fs1 <2d,repeat,nearest>
mul ft4, ft4, fc9.w
sub ft4, ft4, fc9.z
mul ft4, ft4, fc4.x
sat ft2, ft4
add ft4, ft4, fc9.z
sat ft1, ft4
add ft0, ft0, ft2
mul ft0, ft0, ft1
add oc, ft0, ft3
]]></agal>;



var shaders:Array = [
{"vs":vs0,"fs":fs0}
];





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
        public var modelViewMatrix:Matrix3D = new Matrix3D();
        public var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
        public var viewWidth:Number, viewHeight:Number;
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
        public function set angleMode(mode:String) : void {
            _toDegree = (mode == "radian") ? 57.29577951308232 : 1;
            _toRadian = (mode == "radian") ? 1 : 0.017453292519943295;
        }
        public function get fieldOfView() : Number { return _fieldOfView / _toRadian; }
        public function set fieldOfView(fov:Number) : void { _fieldOfView = fov * _toRadian; _updateProjectionMatrix(); }
        public function get magnification() : Number { return _magnification; }
        public function set magnification(mag:Number) : void { _magnification = mag; _updateProjectionMatrix(); }
        public function get cameraPosition() : Vector3D { return _cameraPosition; }
    // constructor ----------------------------------------
        function SiGLCore(width:Number=1, height:Number=1) {
            viewWidth = width;
            viewHeight = height;
            angleMode = "degree";
            _zNear = -100;
            _zFar = 100;
            _magnification = 1;
            modelViewMatrix.identity();
            this.fieldOfView = 60;
            _mvpMatrixDirty = true;
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
            if (_zNear <= _cameraPosition.z) _zNear = _cameraPosition.z + 0.001;
            projectionMatrix.perspectiveFieldOfViewRH(_fieldOfView, aspect, _zNear - _cameraPosition.z, _zFar - _cameraPosition.z);
            projectionMatrix.prependTranslation(-_cameraPosition.x, -_cameraPosition.y, -_cameraPosition.z);
            projectionMatrix.prependScale(_magnification, _magnification, _magnification);
        }
    }


    /** Mesh */
    class Mesh {
    // variables ----------------------------------------
        public var vertices:Vector.<Number> = new Vector.<Number>();
        public var faces:Vector.<Face> = new Vector.<Face>();
        public var vertexBuffer:VertexBuffer3D;
        public var indexBuffer:IndexBuffer3D;
        public var data32PerVertex:int;
        private var _indices:Vector.<uint> = new Vector.<uint>(), _indexDirty:Boolean=true;
        private var _normalOffset:int;
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
            var res:* = /(V(\d))(N(\d))?(T(\d))?(C(\d))?/.exec(bufferFormat);
            data32PerVertex = int(res[2]) + int(res[4]) + int(res[6]) + int(res[8]);
            _normalOffset = (int(res[4]) > 0) ? int(res[2]) : -1;
            this.data32PerVertex = data32PerVertex;
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
        public function qface(i0:int, i1:int, i2:int, i3:int) : Mesh {
            faces.push(Face.alloc(i0, i1, i2), Face.alloc(i3, i2, i1));
            _indexDirty = true;
            return this;
        }
        public function updateFaceNormal(updateVertexNormal:Boolean=true) : Mesh {
            var vtx:Vector.<Number> = vertices, vcount:int = vertexCount, fcount:int = faces.length, 
                i:int, istep:int, f:Face, iw:Number, fidx:int, 
                i0:int, i1:int, i2:int, n0:Vector3D, n1:Vector3D, n2:Vector3D, 
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
            if (updateVertexNormal && (_normalOffset != -1)) {
                istep = data32PerVertex - 2;
                // initialize
                for (i=0, i0=_normalOffset; i<vcount; i++, i0+=istep) { vtx[i0]=0; i0++; vtx[i0]=0; i0++; vtx[i0]=0; }
                // sum up
                for (i=0; i<fcount; i++) {
                    f = faces[i];
                    i0 = f.i0 * data32PerVertex + _normalOffset;
                    vtx[i0]+=f.normal.x; i0++; vtx[i0]+=f.normal.y; i0++; vtx[i0]+=f.normal.z;
                    i0 = f.i1 * data32PerVertex + _normalOffset;
                    vtx[i0]+=f.normal.x; i0++; vtx[i0]+=f.normal.y; i0++; vtx[i0]+=f.normal.z;
                    i0 = f.i2 * data32PerVertex + _normalOffset;
                    vtx[i0]+=f.normal.x; i0++; vtx[i0]+=f.normal.y; i0++; vtx[i0]+=f.normal.z;
                }
                /*  normalize vertex vector (if need)
                for (i=0, i0=_normalOffset; i<vcount; i++, i0+=istep) {
                    x01 = vtx[i0]; i0++; y01 = vtx[i0]; i0++; z01 = vtx[i0]; i0-=2;
                    iw = 1 / Math.sqrt(x01*x01 + y01*y01 + z01*z01);
                    vtx[i0] = x01 * iw; i0++; vtx[i0] = y01 * iw; i0++; vtx[i0] = z01 * iw;
                }//*/
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
}

