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
    import org.libspark.betweenas3.*;
    import org.libspark.betweenas3.easing.*;
    import org.libspark.betweenas3.tweens.*;
//    import org.si.ptolemy.*;
//    import org.si.ptolemy.core.*;
//    import org.si.ptolemy.utils.*;

    public class main extends Sprite {
/*      // for local
        private const cceURL:String = "cce.swf";
        private const envURL :String = "_env2.png";
        private const cubeURL:String = "_cube.png";
/*/     // for wonderfl
        private const cceURL:String = "http://swf.wonderfl.net/swf/usercode/6/67/679c/679c3b410a599d83b3548ce73ce37b873ae4046b.swf?v=1";
        private const envURL:String = "http://assets.wonderfl.net/images/related_images/b/bb/bbf1/bbf12c60cf84e5ab43e059920783d036da25df48";
        private const cubeURL:String = "http://assets.wonderfl.net/images/related_images/0/0a/0af4/0af44d6dad95415359d744cfb88e879a41e21754";
//*/
        
        private var ptolemy:Ptolemy;
        
        private var asm:AGALMiniAssembler = new AGALMiniAssembler();
        private var programs:Vector.<Program3D> = new Vector.<Program3D>();

        private var _meshA:Mesh = new Mesh("V3N3");
        private var _meshB:Mesh = new Mesh("V3N3");
        private var _back:Mesh = new Mesh("V3T2");
        private var _meshAMatrix:SiGLMatrix = new SiGLMatrix();
        private var _meshBMatrix:SiGLMatrix = new SiGLMatrix();
        private var _meshASize:Number = 180, _meshBSize:Number = 200;
        private var _meshAShape:int = 10, _meshBShape:int = 6;

        private var _boolMode:int = 4;
        private var _boolOperations:Vector.<BooleanOperation> = Vector.<BooleanOperation>([
            new BooleanOperation("A",   "back",  "none",  "always",   "never"),
            new BooleanOperation("B",   "none",  "back",  "never",    "always"),
            new BooleanOperation("A+B", "back",  "back",  "always",   "always"),
            new BooleanOperation("A*B", "back",  "back",  "notEqual", "notEqual"),
            new BooleanOperation("A-B", "back",  "front", "equal",    "notEqual"),
            new BooleanOperation("B-A", "front", "back",  "notEqual", "equal")
        ]);
        
        private var _materialA:FlatShadingMaterial = new FlatShadingMaterial(0x8080e0);
        private var _materialB:FlatShadingMaterial = new FlatShadingMaterial(0x8080e0);
        private var _ref:Number = 0.25;
        private var _specTex:Texture, _cubeTex:CubeTexture;
        private var _backMap:BitmapData, _backTex:Texture;
        private var _light:Light = new Light();
        private var _cameraMatrix:SiGLMatrix = new SiGLMatrix();
        
        private var _startTime:Number, _animStartTime:Number;
        
        function main() {
            Wonderfl.disable_capture();
            ptolemy = new Ptolemy(this, 8, 8, 450, 450);
            ptolemy.sigl.setZRange(-300, 1000);
            ptolemy.addEventListener(Event.COMPLETE, setup);
            ptolemy.load(new URLRequest(cceURL),  "cce",  "img", true);
            ptolemy.load(new URLRequest(envURL),  "env",  "img", true);
            ptolemy.load(new URLRequest(cubeURL), "cube", "img", true);
        }
        
        
        private function setup(e:Event) : void {
            var i:int, j:int, k:int, context3D:Context3D = ptolemy.context3D, prog:Program3D, mat:Matrix3D = new Matrix3D();
            removeEventListener(Event.COMPLETE, setup);
            context3D.enableErrorChecking = true;
            
            // create shape
            SolidFactory.plane(_back, 450, 450, 0).updateBuffer("T", Vector.<Number>([0,1,1,1,0,0,1,0]));
            _back.allocateBuffer(context3D).upload();
            _backMap = ptolemy.resources["env"].bitmapData;
            _backTex = context3D.createTexture(_backMap.width, _backMap.height, "bgra", false);
            _backTex.uploadFromBitmapData(_backMap);

            _specTex = context3D.createTexture(1024, 1, "bgra", false);
            _specTex.uploadFromBitmapData(_materialA.specMap);
            
            _cubeTex = createCubeTexture(context3D, ptolemy.resources["cube"].bitmapData);
            updateMesh(_meshA, _meshAShape, _meshASize);
            updateMesh(_meshB, _meshBShape, _meshBSize);
            
            for (i=0; i<shaders.length; i++) {
                prog = context3D.createProgram();
                prog.upload(asm.assemble("vertex", shaders[i].vs), asm.assemble("fragment", shaders[i].fs));
                programs.push(prog);
            }
            
            context3D.setProgramConstantsFromVector("vertex",  126, Vector.<Number>([0.2, 2, 0, 0]));
            context3D.setProgramConstantsFromVector("vertex",  127, Vector.<Number>([0, 0.5, 1, 2]));
            context3D.setProgramConstantsFromVector("fragment", 27, Vector.<Number>([0, 0.5, 1, 2]));
            
            setupControler();
            _startTime = getTimer();
            addEventListener(Event.ENTER_FRAME, draw);
        }
        
        
        private function setupControler() : void {
            var ColorChooserEx:Class = ptolemy.resources["cce"].getClass(), cb:ComboBox, 
                shapes:Array = ["SHPERE", "TETRAHEDRON", "HEXAHEDRON", "OCTAHEDRON", "DODECAHEDRON", "ICOSAHEDRON", "GEODESTIC DOME", "PENTA PILLAR", "CYLINDER", "CONE", "CRYSTAL"]; 
            addChild(_mouseCapture = new Sprite());
            _mouseCapture.graphics.beginFill(0, 0);
            _mouseCapture.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            _mouseCapture.graphics.endFill();
            _mouseCapture.visible = false;
            addChild(_ctrl = new Sprite()); _w=240; _h=20; 
            new ColorChooserEx(_ctrl,  2, 2, _materialA.color, function(e:Event):void { _materialA.color = e.target.value; });
            new ColorChooserEx(_ctrl, 82, 2, _materialB.color, function(e:Event):void { _materialB.color = e.target.value; });
            newSlider("Mesh A size", 0, 400, _meshASize, 10, 0, function(e:Event):void { _meshASize = e.target.value; updateMesh(_meshA, _meshAShape, _meshASize); });
            newSlider("Mesh B size", 0, 400, _meshBSize, 10, 0, function(e:Event):void { _meshBSize = e.target.value; updateMesh(_meshB, _meshBShape, _meshBSize); }); _h+=10;
            newSlider("ambient", 0, 1, _materialA.ambient, 0.1, 1, function(e:Event):void { _materialA.ambient = _materialB.ambient = e.target.value; });
            newSlider("diffuse", 0, 1, _materialA.diffuse, 0.1, 1, function(e:Event):void { _materialA.diffuse = _materialB.ambient = e.target.value; });
            newSlider("power",   0,64, _materialA.power,     1, 0, function(e:Event):void { _materialA.power = e.target.value;    _specTex.uploadFromBitmapData(_materialA.specMap);});
            newSlider("specular",0, 3, _materialA.specular,0.1, 1, function(e:Event):void { _materialA.specular = e.target.value; _specTex.uploadFromBitmapData(_materialA.specMap);});
            newSlider("refrect", 0, 1, _ref,               0.1, 1, function(e:Event):void { _ref = e.target.value; });
            setupControlPanel(0, "PARAMETERS");
            cb = new ComboBox(this, 246, 8, shapes[_meshAShape], shapes);
            cb.numVisibleItems = shapes.length;
            cb.selectedIndex = _meshAShape;
            cb.addEventListener(Event.SELECT, function(e:Event):void{ _meshAShape = e.target.selectedIndex; updateMesh(_meshA, _meshAShape, _meshASize); });
            cb = new ComboBox(this, 358, 8, shapes[_meshBShape], shapes);
            cb.numVisibleItems = shapes.length;
            cb.selectedIndex = _meshBShape;
            cb.addEventListener(Event.SELECT, function(e:Event):void{ _meshBShape = e.target.selectedIndex; updateMesh(_meshB, _meshBShape, _meshBSize); });
            new PushButton(this, 8,   8, "MESH A", function(e:Event):void {_boolMode = 0;});
            new PushButton(this, 8,  28, "MESH B", function(e:Event):void {_boolMode = 1;});
            new PushButton(this, 8,  48, "A+B", function(e:Event):void {_boolMode = 2;});
            new PushButton(this, 8,  68, "A*B", function(e:Event):void {_boolMode = 3;});
            new PushButton(this, 8,  88, "A-B", function(e:Event):void {_boolMode = 4;});
            new PushButton(this, 8, 108, "B-A", function(e:Event):void {_boolMode = 5;});
        }
        private function setupControlPanel(tabIndex:int, label:String) : void {
            _ctrl.x = 8; _ctrl.y = 465;
            _ctrl.graphics.beginFill(0, 0.75);
            _ctrl.graphics.drawRect(0, 0, _w, _h);
            _ctrl.graphics.endFill();
            new PushButton(_ctrl, tabIndex*90, -18, label, function(e:Event):void {
                var ctrl:DisplayObjectContainer = e.target.parent;
                ctrl.parent.addChild(ctrl);
                BetweenAS3.to(ctrl, {y:476-ctrl.height}, 0.5, Sine.easeOut).play();
                _mouseCapture.visible = true;
                _mouseCapture.addEventListener(MouseEvent.CLICK, function(e:Event):void{
                    _mouseCapture.visible = false;
                    _mouseCapture.removeEventListener(MouseEvent.CLICK, arguments.callee);
                    BetweenAS3.to(ctrl, {y:465}, 0.5, Sine.easeOut).play();
                });
            }).setSize(90, 18);
        }
        private function newSlider(label:String, min:Number, max:Number, val:Number, tick:Number, prec:int, func:Function) : void {
            var slider:HUISlider = new HUISlider(_ctrl, 4, _h, label, func);
            slider.setSliderParams(min, max, val); slider.tick = tick; slider.labelPrecision = prec;
            _h += 20; slider.width = _w;
        }
        private var _ctrl:Sprite, _h:Number, _w:Number, _mouseCapture:Sprite;
        
        
        private function updateMesh(mesh:Mesh, shape:int, size:Number) : void {
            mesh.dispose();
            switch(shape) {
            case 0:  SolidFactory.sphere(mesh, size, 2).updateFaceNormal(true);  break;
            case 1:  SolidFactory.tetrahedron(mesh, size).updateFaceNormal(true); break;
            case 2:  SolidFactory.hexahedron(mesh, size).updateFaceNormal(true); break; 
            case 3:  SolidFactory.octahedron(mesh, size).updateFaceNormal(true); break;
            case 4:  SolidFactory.dodecahedron(mesh, size).updateFaceNormal(true); break;
            case 5:  SolidFactory.icosahedron(mesh, size).updateFaceNormal(true); break;
            case 6:  SolidFactory.sphere(mesh, size, 2, false).updateFaceNormal(true); break;
            case 7:  SolidFactory.pillar(mesh,  5, size*0.5,  320, 1, false).updateFaceNormal(true); break;
            case 8:  SolidFactory.pillar(mesh, 32, size*0.5,  320, 1,  true).updateFaceNormal(true); break;
            case 9:  SolidFactory.pillar(mesh, 32, size*0.5,    0, 1,  true, size, 0).updateFaceNormal(true); break;
            case 10: SolidFactory.pillar(mesh,  8, size*0.5, size, 1, false, size*0.5, size*0.5).updateFaceNormal(true); break;
            }
        }
        
        
        private function draw(e:Event) : void {
            var context3D:Context3D = ptolemy.context3D,
                sigl:SiGLCore = ptolemy.sigl, 
                t:Number = (_startTime - getTimer()) * 0.00314,
                op:BooleanOperation = _boolOperations[_boolMode];
            
            // upload
            if (_meshA.vertexBuffer == null) _meshA.allocateBuffer(context3D).upload();
            if (_meshB.vertexBuffer == null) _meshB.allocateBuffer(context3D).upload();

            // global motion
            // lighting vector
            _light.setTo(mouseX-233, 233-mouseY, 300);
            _meshAMatrix.identity();
            _meshAMatrix.prependRotationXYZ(t*0.1, t*0.06, 0);
            _meshBMatrix.identity();
            _meshBMatrix.prependRotationXYZ(0, t*0.3, t*0.05);
            _meshBMatrix.prependTranslation(-60, 0, 0);
            
            // drawing
            context3D.clear();
            context3D.setProgramConstantsFromVector("fragment", 4, Vector.<Number>([_ref,1-_ref,0,0]));
            context3D.setStencilReferenceValue(0);
            // background
            sigl.id();
            context3D.setProgram(programs[2]);
            context3D.setTextureAt(0, _backTex);
            context3D.setTextureAt(1, null);
            context3D.setCulling("none");
            context3D.setDepthTest(false, "always");
            context3D.setStencilActions("frontAndBack", "always");
            context3D.setProgramConstantsFromMatrix("vertex", 0, sigl.modelViewProjectionMatrix, true);
            _back.drawTriangles(context3D);
            // CSG 
            switch (_boolMode) {
            case 2:
                drawMesh(_meshA, _meshAMatrix, _materialA, "back", "always");
                drawMesh(_meshB, _meshBMatrix, _materialB, "back", "always");
                break;
            case 4:
                drawCSG(_meshB, _meshBMatrix, _meshA, _meshAMatrix, _materialB, op.surfB, op.stencilB);
                drawCSG(_meshA, _meshAMatrix, _meshB, _meshBMatrix, _materialA, op.surfA, op.stencilA);
                break;
            default:
                drawCSG(_meshA, _meshAMatrix, _meshB, _meshBMatrix, _materialA, op.surfA, op.stencilA);
                drawCSG(_meshB, _meshBMatrix, _meshA, _meshAMatrix, _materialB, op.surfB, op.stencilB);
                break;
            }

            //if(!_s){_s=new BitmapData(450,450,false,0);with(addChildAt(new Bitmap(_s),0)){x=y=8;}}context3D.drawToBitmapData(_s);
            context3D.present();
        }
        private var _s:BitmapData = null;
        
        private function drawCSG(meshA:Mesh, meshAMatrix:Matrix3D, meshB:Mesh, meshBMatrix:Matrix3D, materialA:FlatShadingMaterial, cullingA:String, stencilOpA:String) : void {
            var context3D:Context3D = ptolemy.context3D, sigl:SiGLCore = ptolemy.sigl; 
            
            context3D.clear(0,0,0,1,1,0,Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
            context3D.setProgram(programs[1]);
            context3D.setTextureAt(0, null);
            context3D.setTextureAt(1, null);
            context3D.setColorMask(false, false, false, false);
            sigl.push().m(meshAMatrix);
            context3D.setCulling(cullingA);
            context3D.setDepthTest(true, "less");
            context3D.setStencilActions("frontAndBack", "always");
            context3D.setProgramConstantsFromMatrix("vertex", 0, sigl.modelViewProjectionMatrix, true);
            meshA.drawTriangles(context3D);
            sigl.rem().m(meshBMatrix);
            context3D.setCulling("none");
            context3D.setDepthTest(false, "less");
            context3D.setStencilActions("front", "always", "incrementWrap");
            context3D.setStencilActions("back", "always", "decrementWrap");
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            meshB.drawTriangles(context3D);
            sigl.pop();
            
            context3D.clear(0,0,0,1,1,0,Context3DClearMask.DEPTH);
            drawMesh(meshA, meshAMatrix, materialA, cullingA, stencilOpA);
        }

        private function drawMesh(mesh:Mesh, matrix:Matrix3D, material:FlatShadingMaterial, culling:String, stencilOp:String) : void {
            var context3D:Context3D = ptolemy.context3D, sigl:SiGLCore = ptolemy.sigl; 
            
            context3D.setProgram(programs[0]);
            context3D.setTextureAt(0, _specTex);
            context3D.setTextureAt(1, _cubeTex);
            context3D.setColorMask(true, true, true, true);
            context3D.setStencilActions("frontAndBack", stencilOp);
            sigl.push().m(matrix);
            _light.transform(sigl);
            context3D.setCulling(culling);
            context3D.setDepthTest(true, "less");
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            context3D.setProgramConstantsFromMatrix("vertex",   4, sigl.modelViewMatrix, true);
            context3D.setProgramConstantsFromVector("fragment", 0, _light.lightVector);
            context3D.setProgramConstantsFromVector("fragment", 1, _light.halfVector);
            context3D.setProgramConstantsFromVector("fragment", 2, material.ambientVector);
            context3D.setProgramConstantsFromVector("fragment", 3, material.diffuseDifVector);
            
            mesh.drawTriangles(context3D);
            sigl.pop();
        }
    }
}


var vs0:String = <agal><![CDATA[
m44 op, va0, vc0
mov v0, va1

sub vt0, va0, vc3
nrm vt0.xyz, vt0
dp3 vt1.x, vt0, va1

mul vt2.x, vt1.x, vc126.y
mul vt2, va1, vt2.x
add vt2, vt2, vt0
m33 vt2.xyz, vt2, vc4
abs vt2.z, vt2.z
mov v1, vt2

mul vt2.x, vt1.x, vc126.x
mul vt2, va1, vt2.x
add vt2, vt2, vt0
m33 vt2.xyz, vt2, vc4
abs vt2.z, vt2.z
neg vt2.z, vt2.z
mov v2, vt2

dp3 v3.z, va1, vc6
mov v3.xyw, vc127.xxx
]]></agal>;
var fs0:String = <agal><![CDATA[
dp3 ft0.x, v0, fc0
abs ft0.x, ft0.x
sat ft0.x, ft0.x
mul ft0, fc3, ft0.x
add ft0, ft0, fc2
dp3 ft1.x, v0, fc1
abs ft1.x, ft1.x
tex ft3, ft1.xx, fs0 <2d,clamp,nearest>
tex ft4, v1.xyz, fs1 <cube,linear,mipnearest>
tex ft2, v2.xyz, fs1 <cube,linear,mipnearest>
mul ft0, ft0, ft2

abs ft1.z, v3.z
sub ft1.z, fc27.z, ft1.z
mul ft1.z, ft1.z, ft1.z
mul ft1.z, ft1.z, ft1.z

mul ft1.x, fc4.y, ft1.z
add ft1.x, ft1.x, fc4.x
sub ft1.y, fc27.z, ft1.x

mul ft4, ft4, ft1.x
mul ft0, ft0, ft1.y
add ft0, ft0, ft4
add oc, ft0, ft3
]]></agal>;
/* frsnel
F = F0 + (1-F0)(1-cos)^5
*/

var vs1:String = <agal><![CDATA[
m44 op, va0, vc0
mov vt0, va1
]]></agal>;
var fs1:String = <agal><![CDATA[
mov oc, fc27.zzz
]]></agal>;

var vs2:String = <agal><![CDATA[
m44 op, va0, vc0
mov v0, va1
]]></agal>;
var fs2:String = <agal><![CDATA[
tex oc, v0.xy, fs0 <2d,clamp,nearest>
]]></agal>;

var shaders:Array = [{"vs":vs0,"fs":fs0}, {"vs":vs1,"fs":fs1}, {"vs":vs2,"fs":fs2}];


class BooleanOperation {
    public var name:String, surfA:String, surfB:String, stencilA:String, stencilB:String; 
    function BooleanOperation(name:String, surfA:String, surfB:String, stencilA:String, stencilB:String) {
        this.surfA=surfA; this.surfB=surfB; this.stencilA=stencilA; this.stencilB=stencilB;
    }
}


import flash.display.*;
import flash.geom.*;
import flash.display3D.*;
import flash.display3D.textures.*;
function createCubeTexture(context3D:Context3D, bitmap:BitmapData) : CubeTexture {
    var size:int = bitmap.width / 3, tex:CubeTexture = context3D.createCubeTexture(size, "bgra", false), 
        src:BitmapData, bmp:BitmapData, mat:Matrix = new Matrix(), i:int, mm:int, s:int, scl:Number, rot:Array=[-1,1,2,0,0,0];
    for (i=0; i<6; i++) {
        src = new BitmapData(size, size, false);
        src.copyPixels(bitmap, new Rectangle((i%3)*size, (int(i/3))*size, size, size), new Point(0, 0));
        for (mm=0, s=size; s!=0; mm++, s>>=1) {
            scl = s / size;
            mat.identity();
            mat.translate(size*-0.5,size*-0.5);
            mat.rotate(rot[i]*Math.PI*0.5);
            mat.translate(size*0.5,size*0.5);
            mat.scale(scl, scl);
            bmp = new BitmapData(s, s, false);
            bmp.draw(src, mat, null, null, null, true);
            tex.uploadFromBitmapData(bmp, i, mm);
            bmp.dispose();
        }
    }
    return tex;
}



{
    /**  Solid Mesh Factory class. */
    class SolidFactory {
        /* tetrahedron */
        static public function tetrahedron(mesh:Mesh, size:Number=1) : Mesh {
            var s:Number = size * 0.5;
            _begin(mesh);
            _f3(); _tv.push( s, s, s, -s, s,-s,  s,-s,-s);
            _f3(); _tv.push( s,-s,-s, -s, s,-s, -s,-s, s);
            _f3(); _tv.push( s,-s,-s, -s,-s, s,  s, s, s);
            _f3(); _tv.push( s, s, s, -s,-s, s, -s, s,-s);
            return _end();
        }
        
        
        /** hexahedron */
        static public function hexahedron(mesh:Mesh, size:Number=1) : Mesh {
            var s:Number = size * 0.5;
            _begin(mesh);
            _f4(); _tv.push(-s,-s,-s,  s,-s,-s, -s, s,-s,  s, s,-s);
            _f4(); _tv.push(-s,-s,-s, -s, s,-s, -s,-s, s, -s, s, s);
            _f4(); _tv.push( s,-s,-s, -s,-s,-s,  s,-s, s, -s,-s, s);
            _f4(); _tv.push(-s, s,-s,  s, s,-s, -s, s, s,  s, s, s);
            _f4(); _tv.push( s, s,-s,  s,-s,-s,  s, s, s,  s,-s, s);
            _f4(); _tv.push( s,-s, s, -s,-s, s,  s, s, s, -s, s, s);
            return _end();
        }
        
        
        /** octahedron */
        static public function octahedron(mesh:Mesh, size:Number=1) : Mesh {
            var s:Number = size * 0.5;
            _begin(mesh);
            _f3(); _tv.push(0,0,-s,  -s,0,0,  0,-s,0);
            _f3(); _tv.push(0,0,-s,  0,-s,0,  s,0,0);
            _f3(); _tv.push(0,0,-s,   s,0,0,  0,s,0);
            _f3(); _tv.push(0,0,-s,   0,s,0,  -s,0,0);
            _f3(); _tv.push(0,-s,0,  -s,0,0,  0,0,s);
            _f3(); _tv.push(s,0,0,   0,-s,0,  0,0,s);
            _f3(); _tv.push(0,s,0,    s,0,0,  0,0,s);
            _f3(); _tv.push(-s,0,0,   0,s,0,  0,0,s);
            return _end();
        }
        
        
        /** dodecahedron */
        static public function dodecahedron(mesh:Mesh, size:Number=1) : Mesh {
            var s:Number = size * 0.5,
                a:Number = s*0.149071198, b:Number = s*0.241202266, c:Number = s*0.283550269, 
                d:Number = s*0.390273464, e:Number = s*0.458793973, f:Number = s*0.631475730, 
                g:Number = s*0.742344243;
            _begin(mesh);
            _v3d(c,f,d);    _v3d(e,f,-a); _v3d(0,f,-b-b); _v3d(-e,f,-a);  _v3d(-c,f,d);
            _v3d(e,a,f);    _v3d(g,a,-b); _v3d(0,a,-d-d); _v3d(-g,a,-b);  _v3d(-e,a,f);
            _v3d(0,-a,d+d); _v3d(g,-a,b); _v3d(e,-a,-f);  _v3d(-e,-a,-f); _v3d(-g,-a,b);
            _v3d(0,-f,b+b); _v3d(e,-f,a); _v3d(c,-f,-d);  _v3d(-c,-f,-d); _v3d(-e,-f,a);
            _f5(0,3,1,2,4); _f5(4,5,9,10,0); _f5(0,6,5,11,1);
            _f5(1,7,6,12,2); _f5(2,8,7,13,3); _f5(3,9,8,14,4);
            _f5(17,11,12,6,16); _f5(16,10,11,5,15); _f5(15,14,10,9,19);
            _f5(19,13,14,8,18); _f5(18,12,13,7,17); _f5(16,18,15,19,17);
            return _end();
        }
        
        
        /** icosahedron */
        static public function icosahedron(mesh:Mesh, size:Number=1) : Mesh {
            var s:Number = size * 0.5,
                a:Number = s*0.276393202, b:Number = s*0.447213595, c:Number = s*0.525731112, 
                d:Number = s*0.723606798, e:Number = s*0.850650808;
            _begin(mesh);
            _f3(); _tv.push(0,s,0, e,b,a, 0,b,b+b);  _f3(); _tv.push(0,b,b+b, e,b,a, c,-b,d);
            _f3(); _tv.push(0,s,0, c,b,-d, e,b,a);   _f3(); _tv.push(e,b,a, c,b,-d, e,-b,-a);
            _f3(); _tv.push(0,s,0, -c,b,-d, c,b,-d); _f3(); _tv.push(c,b,-d, -c,b,-d, 0,-b,-b-b);
            _f3(); _tv.push(0,s,0, -e,b,a, -c,b,-d); _f3(); _tv.push(-c,b,-d, -e,b,a, -e,-b,-a);
            _f3(); _tv.push(0,s,0, 0,b,b+b, -e,b,a); _f3(); _tv.push(-e,b,a, 0,b,b+b, -c,-b,d);
            _f3(); _tv.push(0,b,b+b, c,-b,d, -c,-b,d);     _f3(); _tv.push(-c,-b,d, c,-b,d, 0,-s,0);
            _f3(); _tv.push(e,b,a, e,-b,-a, c,-b,d);       _f3(); _tv.push(c,-b,d, e,-b,-a, 0,-s,0);
            _f3(); _tv.push(c,b,-d, 0,-b,-b-b, e,-b,-a);   _f3(); _tv.push(e,-b,-a, 0,-b,-b-b, 0,-s,0);
            _f3(); _tv.push(-c,b,-d, -e,-b,-a, 0,-b,-b-b); _f3(); _tv.push(0,-b,-b-b, -e,-b,-a, 0,-s,0);
            _f3(); _tv.push(-e,b,a, -c,-b,d, -e,-b,-a);    _f3(); _tv.push(-e,-b,-a, -c,-b,d, 0,-s,0);
            return _end();
        }
        
        
        /** Geodesic dome sphere */
        static public function sphere(mesh:Mesh, size:Number=1, precision:int=1, shareVertex:Boolean=true) : Mesh {
            var s:Number=size*0.5, i:int, imax:int, istep:int, v:Vector3D=new Vector3D();
            if (shareVertex) {
                var a:Number=0.276393202, b:Number=0.447213595, c:Number=0.525731112, d:Number=0.723606798, e:Number=0.850650808
                mesh.clear(); mesh.vertexCount=0;
                _tv.length = 0;
                _tv.push(0,1,0, 0,b,b+b, e,b,a, c,b,-d, -c,b,-d, -e,b,a);
                _tv.push(e,-b,-a, c,-b,d, -c,-b,d, -e,-b,-a, 0,-b,-b-b, 0,-1,0);
                mesh.qface(0,2,1,7).qface(0,3,2,6).qface(0,4,3,10).qface(0,5,4,9).qface(0,1,5,8);
                mesh.qface(1,7,8,11).qface(2,6,7,11).qface(3,10,6,11).qface(4,9,10,11).qface(5,8,9,11);
                mesh.updateBuffer(Mesh.vertexAttributeName, _tv);
            } else {
                icosahedron(mesh, 1);
            }
            mesh.divideFaces(precision, shareVertex);
            i = mesh.attributes[Mesh.vertexAttributeName].offset;
            imax = mesh.vertices.length;
            istep = mesh.data32PerVertex;
            for (i=0; i<imax; i+=istep) {
                v.setTo(mesh.vertices[i], mesh.vertices[i+1], mesh.vertices[i+2]);
                v.normalize();
                mesh.vertices[i]   = v.x * s;
                mesh.vertices[i+1] = v.y * s;
                mesh.vertices[i+2] = v.z * s;
            } 
            return mesh;
        }
        
        
        /** pillar */
        static public function pillar(mesh:Mesh, faceCount:int, radius:Number=1, height:Number=1, ratio:Number=1, shareVertex:Boolean=true, capConeHeightPosi:Number=0, capConeHeightNega:Number=0) : Mesh {
            var i:int, d:Number, a:Number, i0:int, i1:int, ioff:int, imax:int;
            mesh.clear(); mesh.vertexCount=0;
            _tv.length = faceCount * 3 * 2;
            for (i=0, i0=0, i1=faceCount*3, a=0, d=6.283185307179586/faceCount; i<faceCount; i++, a-=d) {
                _tv[i0] =  (_tv[i1] = Math.cos(a) * radius) * ratio; i0++; i1++;
                _tv[i0] =  (_tv[i1] = Math.sin(a) * radius) * ratio; i0++; i1++;
                _tv[i0] = -(_tv[i1] = -height * 0.5); i0++; i1++;
            }
            if (shareVertex) {
                for (i=1, imax=faceCount; i<imax; i++) mesh.qface(i,i-1,i+imax,i+imax-1);
                mesh.qface(0,imax-1,imax,imax*2-1);
            } else {
                _tv.length += (imax = _tv.length);
                for (i0=0, i1=imax; i0<imax; i0++, i1++) _tv[i1] = _tv[i0];
                i0 = faceCount * 2;
                for (i=1, imax=faceCount; i<imax; i++) mesh.qface(i,i0+i-1,i+imax,i0+i+imax-1);
                mesh.qface(0,i0+imax-1,imax,i0+imax*2-1);
            }
            if (ratio>0 && !isNaN(capConeHeightPosi)) {
                ioff = (i1 = _tv.length) / 3;
                if (shareVertex) {
                    _tv.length += (imax = faceCount * 3) + 3;
                    _tv[i1++] = 0; _tv[i1++] = 0; _tv[i1++] = height * 0.5 + capConeHeightPosi;
                    for (i=0; i<imax; i++, i1++) _tv[i1] = _tv[i];
                    for (i=1, imax=faceCount; i<imax; i++) mesh.face(ioff,ioff+i,ioff+i+1);
                    mesh.face(ioff,ioff+imax,ioff+1);
                } else {
                    _tv.length += (imax = faceCount * 3) * 2 + 3;
                    _tv[i1++] = 0; _tv[i1++] = 0; _tv[i1++] = height * 0.5 + capConeHeightPosi;
                    for (i=0, i0=i1+imax; i<imax; i++, i0++, i1++) _tv[i1] = _tv[i0] = _tv[i];
                    for (i=1, imax=faceCount; i<imax; i++) mesh.face(ioff,ioff+i,ioff+imax+i+1);
                    mesh.face(ioff,ioff+imax,ioff+1);
                }
            }
            if (!isNaN(capConeHeightNega)) {
                ioff = (i1 = _tv.length) / 3;
                if (shareVertex) {
                    _tv.length += (imax = faceCount * 3) + 3;
                    _tv[i1++] = 0; _tv[i1++] = 0; _tv[i1++] = -height * 0.5 - capConeHeightNega;
                    for (i=0; i<imax; i++, i1++) _tv[i1] = _tv[i+imax];
                    for (i=1, imax=faceCount; i<imax; i++) mesh.face(ioff,ioff+i+1,ioff+i);
                    mesh.face(ioff,ioff+1,ioff+imax);
                } else {
                    _tv.length += (imax = faceCount * 3) * 2 + 3;
                    _tv[i1++] = 0; _tv[i1++] = 0; _tv[i1++] = -height * 0.5 - capConeHeightNega;
                    for (i=0, i0=i1+imax; i<imax; i++, i0++, i1++) _tv[i1] = _tv[i0] = _tv[i+imax];
                    for (i=1, imax=faceCount; i<imax; i++) mesh.face(ioff,ioff+imax+i+1,ioff+i);
                    mesh.face(ioff,ioff+imax+1,ioff+imax);
                }
            }
            return mesh.updateBuffer(Mesh.vertexAttributeName, _tv);
        }
        
        
        static public function plane(mesh:Mesh, width:Number, height:Number, z:Number=0) : Mesh {
            _tv.length = 0;
            _tv.push(-width*0.5,-height*0.5,z, width*0.5,-height*0.5,z, -width*0.5,height*0.5,z, width*0.5,height*0.5,z);
            mesh.qface(0,1,2,3);
            return mesh.updateBuffer(Mesh.vertexAttributeName, _tv);
        }
        
        
        
        
    // internal functions
    //--------------------------------------------------
        static private var _tv:Vector.<Number> = new Vector.<Number>(), _tv3d:Vector.<Vector3D> = new Vector.<Vector3D>(), _ii:int, _mesh:Mesh;
        static private function _v3d(x:Number, y:Number, z:Number) : void { _tv3d.push(new Vector3D(x, y, z)); }
        static private function _begin(mesh:Mesh) : void { _mesh = mesh; mesh.clear(); mesh.vertexCount=0; _ii = 0; _tv.length = 0; _tv3d.length = 0; }
        static private function _f3() : void { _mesh.face(_ii++, _ii++, _ii++); }
        static private function _f4() : void { _mesh.qface(_ii++, _ii++, _ii++, _ii++); }
        static private function _end() : Mesh { return _mesh.updateBuffer(Mesh.vertexAttributeName, _tv); }
        static private function _f5(i0:int, i1:int, i2:int, i3:int, i4:int) : void {
            _mesh.qface(_ii++, _ii++, _ii++, _ii++).face(_ii-3, _ii-4, _ii++);
            _tv.push(_tv3d[i0].x, _tv3d[i0].y, _tv3d[i0].z);
            _tv.push(_tv3d[i1].x, _tv3d[i1].y, _tv3d[i1].z);
            _tv.push(_tv3d[i2].x, _tv3d[i2].y, _tv3d[i2].z);
            _tv.push(_tv3d[i3].x, _tv3d[i3].y, _tv3d[i3].z);
            _tv.push(_tv3d[i4].x, _tv3d[i4].y, _tv3d[i4].z);
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
            sigl = new SiGLCore(width, height);
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, function(e:Event):void{
                context3D = e.target.context3D;
                if (context3D) {
                    context3D.enableErrorChecking = true;                   // check internal error
                    context3D.configureBackBuffer(width, height, 0, true);  // disable AA/ enable depth/stencil
                    context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
                    context3D.setCulling(Context3DTriangleFace.BACK);       // culling back face
                    context3D.setRenderToBackBuffer();
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
        public var modelViewMatrix:SiGLMatrix = new SiGLMatrix(), projectionMatrix:SiGLMatrix = new SiGLMatrix();
        public var viewWidth:Number, viewHeight:Number, pointSpriteFieldScale:Point = new Point();
        public var defaultCameraMatrix:SiGLMatrix = new SiGLMatrix(), matrix:SiGLMatrix = modelViewMatrix;
        private var _mvpMatrix:Matrix3D = new Matrix3D(), _mvpdir:Boolean, _2d:Number, _2r:Number;
        private var _mag:Number, _zNear:Number, _zFar:Number, _fieldOfView:Number, _alignTopLeft:Boolean = false;
    // properties ----------------------------------------
        public function get modelViewProjectionMatrix() : Matrix3D {
            if (_mvpdir) {
                _mvpMatrix.copyFrom(projectionMatrix);
                _mvpMatrix.prepend(modelViewMatrix);
                _mvpdir = false;
            }
            return _mvpMatrix;
        }
        public function get align() : String { return (_alignTopLeft) ? "topLeft" : "center"; }
        public function set align(mode:String) : void { _alignTopLeft = (mode == "topLeft"); _updateProjectionMatrix(); }
        public function get matrixMode() : String { return (matrix === projectionMatrix) ? "projection" : "modelView"; }
        public function set matrixMode(mode:String) : void { matrix = (mode == "projection") ? projectionMatrix : modelViewMatrix; }
        public function get angleMode() : String { return (_2r == 1) ? "radian" : "degree"; }
        public function set angleMode(mode:String) : void { _2d = (mode == "radian") ? 57.29577951308232 : 1; _2r = (mode == "radian") ? 1 : 0.017453292519943295; }
        public function get fieldOfView() : Number { return _fieldOfView / _2r; }
        public function set fieldOfView(fov:Number) : void { _fieldOfView = fov * _2r; _updateProjectionMatrix(); }
        public function get magnification() : Number { return _mag; }
        public function set magnification(mag:Number) : void { _mag = mag; _updateProjectionMatrix(); }
    // constructor ----------------------------------------
        function SiGLCore(width:Number=1, height:Number=1) {
            viewWidth = width; viewHeight = height;
            angleMode = "degree"; _mag = 1;
            _zNear = -1000; _zFar = 200;
            modelViewMatrix.identity();
            _mvpdir = true;
            this.fieldOfView = 60;
        }
    // matrix operations ----------------------------------------
        public function forceUpdateMatrix() : SiGLCore { _mvpdir = true; return this; }
        public function setZRange(zNear:Number=-100, zFar:Number=100) : SiGLCore { _zNear = zNear; _zFar = zFar; _updateProjectionMatrix(); return this; }
        public function clear() : SiGLCore { matrix.clear(); _mvpdir = true; return this; }
        public function id() : SiGLCore { matrix.id(); _mvpdir = true; return this; }
        public function push() : SiGLCore { matrix.push(); return this; }
        public function pop() : SiGLCore { matrix.pop(); _mvpdir = true; return this; }
        public function rem() : SiGLCore { matrix.rem(); _mvpdir = true; return this; }
        public function r(a:Number, axis:Vector3D, pivot:Vector3D = null) : SiGLCore { matrix.prependRotation(a*_2d, axis, pivot); matrix._invdir = _mvpdir = true; return this; }
        public function s(x:Number, y:Number, z:Number=1) : SiGLCore { matrix.prependScale(x, y, z); matrix._invdir = _mvpdir = true; return this; }
        public function t(x:Number, y:Number, z:Number=0) : SiGLCore { matrix.prependTranslation(x, y, z); matrix._invdir = _mvpdir = true; return this; }
        public function m(mat:Matrix3D) : SiGLCore { matrix.prepend(mat); matrix._invdir = _mvpdir = true; return this; }
        public function re(x:Number, y:Number, z:Number) : SiGLCore { matrix.prependRotationXYZ(x*_2r, y*_2r, z*_2r); _mvpdir = true; return this; }
        public function setCameraMatrix(mat:Matrix3D=null) : SiGLCore { projectionMatrix.rem().prepend(mat || defaultCameraMatrix); _mvpdir = true; return this; }
        private function _updateProjectionMatrix() : void {
            var wh:Number = viewWidth / viewHeight, rev:Number = (_alignTopLeft)?-1:1,
                fl:Number = (viewHeight * 0.5) / Math.tan(_fieldOfView * 0.5);
            if (_zNear <= -fl) _zNear = -fl + 0.001;
            projectionMatrix.clear().perspectiveFieldOfView(_fieldOfView, wh, _zNear+fl, _zFar+fl, -1);
            pointSpriteFieldScale.setTo(projectionMatrix.rawData[0] * fl, projectionMatrix.rawData[5] * fl);
            projectionMatrix.push();
            defaultCameraMatrix.identity();
            defaultCameraMatrix.prependTranslation(0, 0, -fl);
            if (_alignTopLeft) defaultCameraMatrix.prependTranslation(viewWidth* 0.5, -viewHeight * 0.5, 0);
            defaultCameraMatrix.prependScale(_mag, _mag * rev, _mag * rev);
            setCameraMatrix();
        }
    }
    

    /** SiGLMatrix is extention of Matrix3D with push/pop operation */
    class SiGLMatrix extends Matrix3D {
        internal var _invdir:Boolean = false, _inv:Matrix3D = new Matrix3D(), _stac:Vector.<Matrix3D> = new Vector.<Matrix3D>();
        static private var _tv:Vector.<Number> = new Vector.<Number>(16, true), _tm:Matrix3D = new Matrix3D();
        static private var _in:Vector.<Number> = new Vector.<Number>(4, true), _out:Vector.<Number> = new Vector.<Number>(4, true);
        public function get inverted() : Matrix3D { if (_invdir) { _inv.copyFrom(this); _inv.invert(); _invdir = false; } return _inv; }
        public function forceUpdateInvertedMatrix() : SiGLMatrix { _invdir=true; return this; }
        public function clear() : SiGLMatrix { _stac.length=0; return id(); }
        public function id() : SiGLMatrix { identity(); _inv.identity(); return this; }
        public function push() : SiGLMatrix { _stac.push(this.clone()); return this; }
        public function pop() : SiGLMatrix { this.copyFrom(_stac.pop()); _invdir=true; return this; }
        public function rem() : SiGLMatrix { this.copyFrom(_stac[_stac.length-1]); _invdir=true; return this; }
        public function prependRotationXYZ(rx:Number, ry:Number, rz:Number) : SiGLMatrix {
            var sx:Number = Math.sin(rx), sy:Number = Math.sin(ry), sz:Number = Math.sin(rz), 
                cx:Number = Math.cos(rx), cy:Number = Math.cos(ry), cz:Number = Math.cos(rz);
            _tv[0] = cz*cy; _tv[1] = sz*cy; _tv[2] = -sy; _tv[4] = -sz*cx+cz*sy*sx; _tv[5] = cz*cx+sz*sy*sx;
            _tv[6] = cy*sx; _tv[8] = sz*sx+cz*sy*cx; _tv[9] = -cz*sx+sz*sy*cx;
            _tv[10] = cy*cx; _tv[14] = _tv[13] = _tv[12] = _tv[11] = _tv[7] = _tv[3] = 0; _tv[15] = 1;
            _tm.copyRawDataFrom(_tv); prepend(_tm); _invdir=true;
            return this;
        }
        public function lookAt(cx:Number, cy:Number, cz:Number, tx:Number=0, ty:Number=0, tz:Number=0, ux:Number=0, uy:Number=1, uz:Number=0, w:Number=0) : SiGLMatrix {
            var dx:Number=tx-cx, dy:Number=ty-cy, dz:Number=tz-cz, dl:Number=-1/Math.sqrt(dx*dx+dy*dy+dz*dz), 
                rx:Number=dy*uz-dz*uy, ry:Number=dz*ux-dx*uz, rz:Number=dx*uy-dy*ux, rl:Number= 1/Math.sqrt(rx*rx+ry*ry+rz*rz);
            _tv[0]  = (rx*=rl); _tv[4]  = (ry*=rl); _tv[8]  = (rz*=rl); _tv[12] = -(cx*rx+cy*ry+cz*rz) * w;
            _tv[2]  = (dx*=dl); _tv[6]  = (dy*=dl); _tv[10] = (dz*=dl); _tv[14] = -(cx*dx+cy*dy+cz*dz) * w;
            _tv[1]  = (ux=dy*rz-dz*ry); _tv[5]  = (uy=dz*rx-dx*rz); _tv[9]  = (uz=dx*ry-dy*rx); _tv[13] = -(cx*ux+cy*uy+cz*uz) * w;
            _tv[3] = _tv[7] = _tv[11] = 0; _tv[15] = 1; copyRawDataFrom(_tv); _invdir=true;
            return this;
        }
        public function perspectiveFieldOfView(fieldOfViewY:Number, aspectRatio:Number, zNear:Number, zFar:Number, lh:Number=1.0) : void {
            var yScale:Number = 1.0 / Math.tan(fieldOfViewY * 0.5), xScale:Number = yScale / aspectRatio;
            this.copyRawDataFrom(Vector.<Number>([xScale,0,0,0,0,yScale,0,0,0,0,zFar/(zFar-zNear)*lh,lh,0,0,(zNear*zFar)/(zNear-zFar),0]));
        }
        public function transform(vector:Vector3D) : Vector3D {
            _in[0] = vector.x; _in[1] = vector.y; _in[2] = vector.z; _in[3] = vector.w;
            transformVectors(_in, _out); vector.setTo(_out[0], _out[1], _out[2]); vector.w = _out[3];
            return vector;
        }
    }
    
    
    /** Mesh */
    class Mesh {
    // constants ----------------------------------------
        static public const vertexAttributeName:String = "V";
        static public const normalAttributeName:String = "N";
    // variables ----------------------------------------
        public var vertices:Vector.<Number> = new Vector.<Number>();
        public var faces:Vector.<Face> = new Vector.<Face>();
        public var vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D;
        public var data32PerVertex:int, attributes:*={}, atl:Array = [];
        private var _indices:Vector.<uint> = new Vector.<uint>(), _indexDirty:Boolean=true;
    // properties ----------------------------------------
        public function get vertexCount() : int { return vertices.length / data32PerVertex; }
        public function set vertexCount(count:int) : void { vertices.length = count * data32PerVertex; }
        public function get indices() : Vector.<uint> {
            var idx:Vector.<uint> = _indices, f:Face, i:int, imax:int, j:int;
            if (_indexDirty) {
                idx.length = imax = faces.length * 3;
                for (i=0,j=0; i<imax; j++) { f=faces[j]; idx[i]=f.i0; i++; idx[i]=f.i1; i++; idx[i]=f.i2; i++; }
                _indexDirty = false;
            }
            return idx;
        }
    // contructor ----------------------------------------
        function Mesh(bufferFormat:String="V3") {
            var rex:RegExp = /([_a-zA-Z]+)([1234b])/g, res:*, i:int=0;
            data32PerVertex = 0;
            while (res = rex.exec(bufferFormat)) {
                attributes[res[1]] = {size:int(res[2]), offset:data32PerVertex};
                data32PerVertex += (atl[i++]=int(res[2]));
            }
        }
    // oprations ----------------------------------------
        public function updateBuffer(attr:String, l:Vector.<Number>, offset:int=0) : Mesh {
            var vai:* = attributes[attr], size:int = vai.size, il:int, iv:int, i:int, j:int, imax:int=l.length/size+offset;
            if (vertices.length < imax * data32PerVertex) vertices.length = imax * data32PerVertex;
            for (il=0, i=offset; i<imax; i++) for (j=0, iv=i*data32PerVertex+vai.offset; j<size; j++, iv++, il++) vertices[iv]=l[il];
            return this;
        }
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
        public function dispose() : Mesh {
            if (vertexBuffer) vertexBuffer.dispose();
            if (indexBuffer)  indexBuffer.dispose();
            vertexBuffer = null;
            indexBuffer = null;
            return this;
        }
        public function drawTriangles(context3D:Context3D) : Mesh {
            var i:int, o:int=0, f:Array = ["","float1","float2","float3","float4"];
            for (i=0; i<atl.length; o+=atl[i++]) context3D.setVertexBufferAt(i, vertexBuffer, o, f[atl[i]]);
            context3D.drawTriangles(indexBuffer, 0, faces.length);
            for (i=0; i<atl.length; i++) context3D.setVertexBufferAt(i, null, 0, "float1");
            return this;
        }
        public function clear() : Mesh { for (var i:int=0; i<faces.length; i++) Face.free(faces[i]); faces.length = 0; _indexDirty = true; return this; }
        public function face(i0:int, i1:int, i2:int) : Mesh { faces.push(Face.alloc(i0, i1, i2)); _indexDirty = true; return this; }
        public function qface(i0:int, i1:int, i2:int, i3:int) : Mesh { faces.push(Face.alloc(i0, i1, i2), Face.alloc(i3, i2, i1)); _indexDirty = true; return this; }
        public function flipFaces() : Mesh { for (var i:int=0,j:int; i<faces.length; i++) { j=faces[i].i0; faces[i].i0=faces[i].i1; faces[i].i1=faces[i].i2; faces[i].i2=j; } return this;}
        public function divideFaces(precision:int=1, shareVertex:Boolean=true) : Mesh {
            var prec:int, i:int, imax:int, i0:int, i1:int, i2:int, vindex:int = vertexCount, _vhash:*={};
            for (prec=0; prec<precision; prec++) for (i=0, imax=faces.length; i<imax; i++) {
                i0 = faces[i].i0; i1 = faces[i].i1; i2 = faces[i].i2;
                face(i0, _newvtx(i0, i1), _newvtx(i2, i0));
                face(_newvtx(i0, i1), i1, _newvtx(i1, i2));
                face(_newvtx(i2, i0), _newvtx(i1, i2), i2);
                faces[i].i0 = _newvtx(i0, i1); faces[i].i1 = _newvtx(i1, i2); faces[i].i2 = _newvtx(i2, i0);
            }
            return this;
            function _newvtx(i0:int, i1:int) : int {
                var vkey:uint = (i0<<16) | i1, idx:int;
                if (vkey in _vhash) return _vhash[vkey];
                vkey = (i1<<16) | i0; if (vkey in _vhash) return _vhash[vkey];
                i0 *= data32PerVertex; i1 *= data32PerVertex; idx = vertices.length; vertices.length += data32PerVertex;
                vertices[idx] = (vertices[i0] + vertices[i1]) * 0.5; idx++; i0++; i1++;
                vertices[idx] = (vertices[i0] + vertices[i1]) * 0.5; idx++; i0++; i1++;
                vertices[idx] = (vertices[i0] + vertices[i1]) * 0.5;
                if (shareVertex) _vhash[vkey] = vindex;
                return vindex++;
            }
        }
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
                //* normalize (ussualy normalizing by gpu).
                for (i=0, i0=3; i<vcount; i++, i0+=istep) {
                    x01 = vtx[i0]; i0++; y01 = vtx[i0]; i0++; z01 = vtx[i0]; i0-=2;
                    iw = 1 / Math.sqrt(x01*x01 + y01*y01 + z01*z01);
                    vtx[i0] = x01 * iw; i0++; vtx[i0] = y01 * iw; i0++; vtx[i0] = z01 * iw;
                } //*/
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
    
    
    /** Light */
    class Light extends Vector3D {
        public var lightVector:Vector.<Number>  = new Vector.<Number>(4, true), halfVector:Vector.<Number>  = new Vector.<Number>(4, true);
        private var _in :Vector.<Number> = new Vector.<Number>(6, true), _out:Vector.<Number> = new Vector.<Number>(6, true);
        private var _lv3d:Vector3D  = new Vector3D(), _hv3d:Vector3D  = new Vector3D();
        function Light(x:Number=1000, y:Number=1000, z:Number=1000) { super(x, y, z); halfVector[3] = lightVector[3] = 0; }
        public function transform(sigl:SiGLCore) : void {
            sigl.projectionMatrix.copyColumnTo(3, _hv3d);
            _in[0] = x; _in[1] = y; _in[2] = z; _in[3] = _hv3d.x; _in[4] = _hv3d.y; _in[5] = _hv3d.z;
            sigl.modelViewMatrix.inverted.transformVectors(_in, _out);
            _lv3d.setTo(_out[0], _out[1], _out[2]); _lv3d.normalize(); _hv3d.setTo(_out[3], _out[4], _out[5]); _hv3d.normalize();
            _hv3d.x += (lightVector[0] = _lv3d.x); _hv3d.y += (lightVector[1] = _lv3d.y); _hv3d.z += (lightVector[2] = _lv3d.z);
            _hv3d.normalize(); halfVector[0] = _hv3d.x; halfVector[1] = _hv3d.y; halfVector[2] = _hv3d.z;
        }
    }
    
    
    /** flat shading material */
    class FlatShadingMaterial {
        private var _col:int, _alp:Number, _amb:Number, _dif:Number, _spc:Number, _pow:Number;
        private var _specMap:BitmapData = new BitmapData(1024,1,false);
        private var _ambVector:Vector.<Number> = new Vector.<Number>(4, true);
        private var _difDifVector:Vector.<Number> = new Vector.<Number>(4, true);
        public function set color(c:int) : void { setColor(c, _alp, _amb, _dif); }
        public function get color() : int { return _col; }
        public function set alpha(a:Number) : void { setColor(_col, a, _amb, _dif); }
        public function get alpha() : Number { return _alp; }
        public function set ambient(a:Number) : void { setColor(_col, _alp, a, _dif); }
        public function get ambient() : Number { return _amb; }
        public function set diffuse(d:Number) : void { setColor(_col, _alp, _amb, d); }
        public function get diffuse() : Number { return _dif; }
        public function set specular(s:Number) : void { setSpecular(s, _pow); }
        public function get specular() : Number { return _spc; }
        public function set power(p:Number) : void { setSpecular(_spc, p); }
        public function get power() : Number { return _pow; }
        public function get ambientVector() : Vector.<Number> { return _ambVector; }
        public function get diffuseDifVector() : Vector.<Number> { return _difDifVector; }
        public function get specMap() : BitmapData { return _specMap; }
        function FlatShadingMaterial(color:int=0xffffff, alpha:Number=1, ambient:Number=0.25, diffuse:Number=0.75, specular:Number=0.75, power:Number=16) {
            setColor(color, alpha, ambient, diffuse);
            setSpecular(specular, power);
        }
        public function setColor(color:int, alpha:Number=1, ambient:Number=0.25, diffuse:Number=0.75) : FlatShadingMaterial {
            _col = color; _alp = alpha; _amb = ambient; _dif = diffuse;
            var r:Number = ((color>>16)&255)*0.00392156862745098, g:Number = ((color>>8)&255)*0.00392156862745098, b:Number = (color&255)*0.00392156862745098;
            _ambVector[0] = r * ambient; _ambVector[1] = g * ambient; _ambVector[2] = b * ambient; _ambVector[3] = alpha;
            _difDifVector[0] = r * diffuse - _ambVector[0]; _difDifVector[1] = g * diffuse - _ambVector[1]; _difDifVector[2] = b * diffuse - _ambVector[2]; _difDifVector[3] = alpha;
            return this;
        }
        private function setSpecular(specular:Number=0.75, power:Number=16) : FlatShadingMaterial {
            _spc = specular; _pow = power; specular *= 256;
            for (var i:int=0; i<1024; i++) {
                var c:int = int(Math.pow(i*0.0009775171065493646, power) * specular);
                _specMap.setPixel32(i, 0, ((c<255)?c:255)*0x10101);
            }
            return this;
        }
    }
}
