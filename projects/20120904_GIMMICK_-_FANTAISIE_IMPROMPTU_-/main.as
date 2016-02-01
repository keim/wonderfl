package {
    import flash.net.*;
    import flash.geom.*;
    import flash.utils.*;
    import flash.events.*;
    import flash.display.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    import com.adobe.utils.*;
    import com.bit101.components.*;
    import org.libspark.betweenas3.*;
    import org.libspark.betweenas3.easing.*;
    import org.libspark.betweenas3.tweens.*;
    import org.si.sion.*;
    import org.si.sion.midi.*;
    import org.si.sion.events.*;
    import org.si.sion.effector.*;
    import org.si.sion.utils.soundfont.*;
    import org.si.sion.utils.soundloader.*;
    //import net.wonderfl.utils.*;

    [SWF(frameRate="30")]
    public class main extends Sprite {
    // parameters ----------
        private const TEST_MODE:Boolean = false;
        private const TITLE:String = "GIMMICK - FANTAISIE IMPROMPTU -";
        private const SPRING_STRENGTH:Number = 0.75;
        private const DAMPER_STRENGTH:Number = 0.25;
        private const CAMERA_SPRING_STRENGTH:Number = 0.1;
        private const CAMERA_DAMPER_STRENGTH:Number = 0.6;
        private const HIT_STRENGTH:Number = 16;
        private const BALL_SIZE:Number = 16;
        private const GRAVITY:Number = 2;
        private const BALL_REFLECTION:Number = 0.5;
        private const KEY_REFLECTION:Number = 0.5;
        private const DELAY_TIME:Number = 1200;
        private const SHUFFLE_ITEM:String = "Shuffle !!";
    // resource ----------
        private const domainURL:String = "http://soundimpulse.sakura.ne.jp/wonderfl/";
        private const cubeFile:String = "_cube.png";
        private const ssfFile:String  = "ssf.swf";
        private const midiFileList:Array = [
          "etude3.mid","fantaisie.mid","nocturne2.mid","polonaise6.mid","prelude7.mid","valse6.mid","etude12.mid"
        ];
    // SiON ----------
        private var driver:SiONDriver = new SiONDriver(4096);
        private var soundLoader:SoundLoader = new SoundLoader();
        private var smfData:* = {}, currentData:SMFData;
    // Prolemy ----------
        private var ptolemy:Ptolemy;
        private var asm:AGALMiniAssembler = new AGALMiniAssembler();
        private var programs:Vector.<Program3D> = new Vector.<Program3D>();
        private var _light:Light = new Light();
        private var _camera:Camera = new Camera();
        private var _cameraBall:Camera = new Camera();
        private var _cameraPos:Vector3D = new Vector3D();
        private var _cameraVel:Vector3D = new Vector3D();
        private var _mouseTarget:Point = new Point();
        private var _mouseRotation:Point = new Point();
    // models ----------
        private var _fader:Mesh, _text:Mesh, _back:Mesh, _ball:Mesh, _meshWK:Mesh, _meshBK:Mesh;
        private var _ballField:PointSpriteField;
        private var _specTex:Texture, _cubeTex:CubeTexture, _ballSprite:Texture, _textTex:Texture;
        private var _matWK:FlatShadingMaterial = new FlatShadingMaterial(0xffffff, 1, 0.75, 1);
        private var _matBK:FlatShadingMaterial = new FlatShadingMaterial(0x000000, 1, 0.75, 1);
    // keyboard ----------
        private const KEY_COUNT:int = 69;
        private var keyColors:Vector.<int> = new Vector.<int>(KEY_COUNT, true);
        private var keyMatrix:Vector.<Matrix3D> = new Vector.<Matrix3D>(KEY_COUNT, true);
        private var keyPosition:Vector.<Vector3D> = new Vector.<Vector3D>(KEY_COUNT, true);
        private var keyMesh:Vector.<Mesh> = new Vector.<Mesh>(KEY_COUNT, true);
        private var keyMaterial:Vector.<FlatShadingMaterial> = new Vector.<FlatShadingMaterial>(KEY_COUNT, true);
        private var keyRotate:Vector.<Vector3D> = new Vector.<Vector3D>(KEY_COUNT, true);
    // front screen ----------
        private var faderColor:Vector.<Number> = Vector.<Number>([1,1,1,1]);
        private var textColor:Vector.<Number> = Vector.<Number>([1,1,1,1]);
        private var textBitmap:Bitmap;
        private var textBD:BitmapData = new BitmapData(512,512,true,0);
        private var textBDMatrix:Matrix = new Matrix(1,0,0,1,0,0);
    // others ----------
        private var vc:Vector3D = new Vector3D();
        private var _prevTime:Number, _animStartTime:Number;
        private var _label:Label, _selector:ComboBox;
        private var dragStart:Point = new Point();
    // properties ----------
        public function get faderAlpha() : Number { return faderColor[3]; }
        public function set faderAlpha(f:Number) : void { faderColor[3] = f; }
        public function get textAlpha() : Number { return textColor[3]; }
        public function set textAlpha(f:Number) : void { textColor[3] = f; }
        
    // constructor ----------
        function main() {
            Wonderfl.disable_capture();
            //Wonderfl.capture_delay(30);
            ptolemy = new Ptolemy(this, 8, 8, 450, 450);
            ptolemy.sigl.setZRange(-300, 1500);
            ptolemy.addEventListener(Event.COMPLETE, onReady);
            clearText();
            drawText(210, TITLE, true, 2);
            drawText(240, "powered by SiON v0.652");
            textBitmap = new Bitmap(textBD);
            textBitmap.y = textBitmap.x = -23;
            addChild(textBitmap);
            _label = new Label(this, 200, 290, "loading ...");
        }
        
    // entry points ----------
        private function onReady(e:Event) : void {
            ptolemy.removeEventListener(Event.COMPLETE, onReady);
            soundLoader.addEventListener(Event.COMPLETE, setup);
            soundLoader.addEventListener(ProgressEvent.PROGRESS, _onLoadingProgress);
            for (var i:int=0; i<midiFileList.length; i++) {
                soundLoader.setURL(new URLRequest(domainURL + midiFileList[i]), midiFileList[i], "mid");
            }
            soundLoader.setURL(new URLRequest(domainURL + ssfFile),  "sondfont", "ssf", true);
            soundLoader.setURL(new URLRequest(domainURL + cubeFile), "cube", "img", true);
            soundLoader.loadAll();
        }
        
        private function setup(e:Event) : void {
            soundLoader.removeEventListener(Event.COMPLETE, setup);
            
            setupPtolemy();
            setupSiON();
            
            _label.text = "Click to start";
            stage.addEventListener(MouseEvent.CLICK, start);
        }
        
        private function start(e:Event) : void {
            stage.removeEventListener(MouseEvent.CLICK, start);
            // remove title objects
            removeChild(_label);
            removeChild(textBitmap);
            // initialize
            _cameraPos.setTo(0, 500, -1000);
            _cameraVel.setTo(0, 0, 0);
            _mouseTarget.setTo(0.3, 0);
            _mouseRotation.setTo(0, 0);
            _prevTime = getTimer();
            currentData = smfData["fantaisie.mid"];
            setupController();
            // set handlers
            addEventListener(Event.ENTER_FRAME, draw);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
            // start fadeout
            uploadText();
            titleFade();
        }
        
    // handlers ----------
        private function _onLoadingProgress(e:ProgressEvent) : void {
            _label.text = "loading (" + (soundLoader.bytesLoaded/soundLoader.bytesTotal*100).toFixed(0) + "%)";
        }
        private function _onSongSelected(e:Event) : void {
            if (_selector.selectedItem == SHUFFLE_ITEM) shufflePlayNext();
            else changeSong(String(_selector.selectedItem));
        }
        private function _onMouseDown(e:Event) : void {
            stage.addEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
            stage.addEventListener(MouseEvent.MOUSE_UP,   _onMouseUp);
            dragStart.setTo(mouseX, mouseY);
            _dragging();
        }
        private function _onMouseMove(e:Event) : void {
            _dragging();
        }
        private function _onMouseUp(e:Event) : void {
            _dragging();
            _mouseRotation.setTo(0, 0);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP,   _onMouseUp);
        }
        private function _dragging() : void {
            _mouseRotation.x = (mouseX - dragStart.x)/16000;
            _mouseRotation.y = (mouseY - dragStart.y)/1600;
        }
        private function _onNoteOn(e:SiONMIDIEvent) : void {
            if (e.note >= 24 && e.note < 24+KEY_COUNT) {
                Ball.create(keyPosition[e.note-24], e.note-24, e.value);
            }
        }
        private function _onFadeOut(e:SiONEvent) : void {
            driver.stop();
        }
        private function _onFinishSequence() : void {
            BetweenAS3.delay(func(shufflePlayNext), 4).play();
        }
        private function _onHit(keyIndex:int) : void {
            keyRotate[keyIndex].y = -HIT_STRENGTH;
        }
        
    // setup ----------
        private function setupPtolemy() : void {
            var i:int, j:int, k:int, n:Number, cm:Mesh, vi:int, prog:Program3D;
            var context3D:Context3D = ptolemy.context3D;
            var mat:Matrix3D = new Matrix3D();
            var tv:Vector.<Number> = new Vector.<Number>();
            
            // Ptolemy Setup
            context3D.enableErrorChecking = TEST_MODE;
            // meshes
            _fader = SolidFactory.plane (new Mesh("V3"),   512, 512, 0).allocateBuffer(context3D).upload();
            _text  = SolidFactory.plane (new Mesh("V3T2"), 512, 512, 0).allocateBuffer(context3D).updateBuffer("T", Vector.<Number>([0,1,1,1,0,0,1,0])).upload();
            _back  = SolidFactory.sphere(new Mesh("V3N3"), 1500, 1).allocateBuffer(context3D).updateFaceNormal(true).upload();
            _ball  = SolidFactory.sphere(new Mesh("V3N3"),  256, 2).allocateBuffer(context3D).updateFaceNormal(true).upload();
            _meshWK = keyModel(20, 12, 80, 75, 8);
            _meshBK = keyModel(14,  8, 56, 48, 8);
            // textures
            _specTex = context3D.createTexture(1024, 1, "bgra", false);
            _specTex.uploadFromBitmapData(_matWK.specMap);
            _cubeTex = createCubeTexture(context3D, soundLoader.hash["cube"].bitmapData);
            _textTex = context3D.createTexture(512, 512, "bgra", false);
            // shaders
            for (i=0; i<shaders.length; i++) {
                prog = context3D.createProgram();
                prog.upload(asm.assemble("vertex", shaders[i].vs), asm.assemble("fragment", shaders[i].fs));
                programs.push(prog);
            }
            // constants
            context3D.setProgramConstantsFromVector("vertex",  126, Vector.<Number>([ptolemy.sigl.pointSpriteFieldScale.x, ptolemy.sigl.pointSpriteFieldScale.y, 0, 0]));
            context3D.setProgramConstantsFromVector("vertex",  127, Vector.<Number>([0, 0.5, 1, 2]));
            context3D.setProgramConstantsFromVector("fragment", 27, Vector.<Number>([0, 0.5, 1, 2]));
            
            // balls
            _ballSprite = context3D.createTexture(256, 256, "bgra", true);
            _ballField = new PointSpriteField(context3D);
            Ball.texInfo = new PointSpriteTexInfo(0, 0, 1, 1, BALL_SIZE, BALL_SIZE);
            Ball.initialize(_onHit, GRAVITY, DELAY_TIME);
            // keyboard
            var ks:Array = [0,1,0,1,0,0,1,0,1,0,1,0], d2r:Number = Math.PI/180,
                rt:Array = [1,1,1,1,2,1,1,1,1,1,1,2], deg:Number = 0;
            for (i=0; i<KEY_COUNT; i++) {
                keyColors[i] = ks[i%12];
                keyMatrix[i] = new Matrix3D();
                keyMatrix[i].prependRotation(deg, Vector3D.Z_AXIS);
                keyMatrix[i].prependTranslation(0,180-keyColors[i]*10,keyColors[i]*10);
                keyMatrix[i].prependRotation(45, Vector3D.X_AXIS);
                keyPosition[i] = keyMatrix[i].transformVector(new Vector3D(0,70-keyColors[i]*20,20));
                deg += rt[i%12] * 4.5;
                if (keyColors[i]) {
                    keyMesh[i] = _meshBK;
                    keyMaterial[i] = _matBK;
                } else {
                    keyMesh[i] = _meshWK;
                    keyMaterial[i] = _matWK;
                }
                keyRotate[i] = new Vector3D(0,0,0);
            }
            
            // Mesh construction tool
            function keyModel(w:Number, w2:Number, h:Number, h2:Number, d:Number) : Mesh {
                var hw:Number=w*0.5, hw2:Number=w2*0.5, hd:Number=d*0.5;
                begin(new Mesh("V3N3"));
                if (!TEST_MODE) {
                    f4(-hw, 0,-hd,  hw, 0,-hd, -hw, h,-hd,  hw, h,-hd);
                    f4(-hw, 0,-hd, -hw, h,-hd,-hw2, 0, hd,-hw2,h2, hd);
                    f4( hw, 0,-hd, -hw, 0,-hd, hw2, 0, hd,-hw2, 0, hd);
                    f4(-hw, h,-hd,  hw, h,-hd,-hw2,h2, hd, hw2,h2, hd);
                    f4( hw, h,-hd,  hw, 0,-hd, hw2,h2, hd, hw2, 0, hd);
                }
                f4(hw2, 0, hd,-hw2, 0, hd, hw2,h2, hd,-hw2,h2, hd);
                return end();
            }
            function begin(m:Mesh) : void {
                i=0; tv.length = 0; cm = m; cm.clear(); cm.vertexCount = 0;
            }
            function f3(x0:Number, y0:Number, z0:Number, x1:Number, y1:Number, z1:Number, x2:Number, y2:Number, z2:Number) : void {
                cm.face(i++, i++, i++); tv.push(x0, y0, z0, x1, y1, z1, x2, y2, z2);
            }
            function f4(x0:Number, y0:Number, z0:Number, x1:Number, y1:Number, z1:Number, x2:Number, y2:Number, z2:Number, x3:Number, y3:Number, z3:Number) : void {
                cm.qface(i++, i++, i++, i++); tv.push(x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3);
            }
            function end() : Mesh {
                return cm.updateBuffer(Mesh.vertexAttributeName, tv).updateFaceNormal(true).allocateBuffer(context3D).upload();
            }
        }
        private function setupSiON() : void {
            var soundFont:SiONSoundFont = soundLoader.hash["sondfont"], i:int;
            for (i=0; i<midiFileList.length; i++) smfData[midiFileList[i]] = soundLoader.hash[midiFileList[i]];
            driver.addEventListener(SiONMIDIEvent.NOTE_ON,  _onNoteOn);
            driver.addEventListener(SiONEvent.FADE_OUT_COMPLETE, _onFadeOut);
            driver.midiModule.voiceSet[0] = soundFont.pcmVoices[0];
            driver.midiModule.setDefaultEffector(0,[new DelayLine(DELAY_TIME)]);
            driver.midiModule.onFinishSequence = _onFinishSequence;
            driver.volume = 0.25;
        }
        private function setupController() : void {
            _selector = new ComboBox(this, 12, 12, "fantaisie.mid", midiFileList);
            _selector.addItem(SHUFFLE_ITEM);
            _selector.numVisibleItems = midiFileList.length;
            _selector.addEventListener(Event.SELECT, _onSongSelected);
        }
        
    // operation ----------
        private function titleFade() : void {
            BetweenAS3.serial(fadeIn(2), func(startSong), textFadeOut(2), func(sideTitle), textFadeIn(1)).play();
        }
        private function changeFade() : void {
            BetweenAS3.serial(fadeOut(2), func(mainTitle), textFadeIn(2), BetweenAS3.delay(func(titleFade), 1)).play();
        }
        private function func(f:Function) : ITween { return BetweenAS3.func(f); }
        private function fadeIn(time:Number) : ITween { return BetweenAS3.to(this, {faderAlpha:0}, time); }
        private function fadeOut(time:Number) : ITween { return BetweenAS3.to(this, {faderAlpha:1, textAlpha:0}, time); }
        private function textFadeIn(time:Number) : ITween { return BetweenAS3.to(this, {textAlpha:1}, time); }
        private function textFadeOut(time:Number) : ITween { return BetweenAS3.to(this, {textAlpha:0}, time); }
        private function mainTitle() : void { clearText(); drawText(220, currentData.title, true, 2); uploadText(); }
        private function sideTitle() : void { clearText(); drawText(450, currentData.title, false); uploadText(); }
        private function startSong() : void {
            driver.play((TEST_MODE) ? null : currentData);
            _selector.enabled = true;
        }
        private function shufflePlayNext() : void {
            _selector.selectedItem = midiFileList[int(Math.random()*midiFileList.length)];
        }
        private function changeSong(song:String) : void {
            currentData = smfData[song];
            driver.fadeOut(4);
            changeFade();
            _selector.enabled = false;
        }
        
    // draw ----------
        private function draw(e:Event) : void {
            var context3D:Context3D = ptolemy.context3D, sigl:SiGLCore = ptolemy.sigl, 
                i:int, now:Number, damper:Number, a:Number, b:Number, tx:Number, ty:Number, tx2:Number, ty2:Number, tz:Number,
                sR:Number = 300, lR:Number = 700;

            // camera motion
            damper = 1-CAMERA_DAMPER_STRENGTH;
            _mouseTarget.x += _mouseRotation.x;
            _mouseTarget.y += _mouseRotation.y;
            _mouseTarget.y *= 0.8;
            tx = Math.cos(_mouseTarget.x * 3.1415926535897933);
            ty = Math.sin(_mouseTarget.x * 3.1415926535897933);
            tx2 = tx * tx;
            ty2 = ty * ty;
            a = (-lR * tx + Math.sqrt(lR*lR*tx2 - (tx2+ty2)*(sR*sR-lR*lR)*4)) / ((tx2+ty2)*2);
            b = (_mouseTarget.y*45+30) * 0.017453292519943295;
            a *= Math.cos(b);
            tx *= a;
            ty *= a;
            tz = lR * Math.sin(b);
            _cameraPos.incrementBy(_cameraVel);
            _cameraVel.x = (_cameraVel.x + (tx - _cameraPos.x) * CAMERA_SPRING_STRENGTH) * damper;
            _cameraVel.y = (_cameraVel.y + (ty - _cameraPos.y) * CAMERA_SPRING_STRENGTH) * damper;
            _cameraVel.z = (_cameraVel.z + (tz - _cameraPos.z) * CAMERA_SPRING_STRENGTH) * damper;
            
            // global
            _light.setTo(1000, 500, 1000);
            _camera.update(_cameraPos.x,_cameraPos.y,_cameraPos.z, 0,0,0, 0.2,0,1);
            sigl.id();

            // 1st drawing
            context3D.setRenderToTexture(_ballSprite);
            context3D.clear(0,0,0,0);
            // ball sprite
            _cameraBall.copyFrom(_camera);
            _cameraBall.copyColumnTo(3, vc);
            vc.normalize(); vc.x *= 260; vc.y *= 260; vc.z *= 260;
            _cameraBall.copyColumnFrom(3, vc);
            sigl.setCameraMatrix(_cameraBall);
            context3D.setProgram(programs[0]);
            context3D.setTextureAt(0, _specTex);
            context3D.setTextureAt(1, _cubeTex);
            context3D.setCulling("back");
            context3D.setDepthTest(true, "less");
            drawMesh(_ball, _matBK, BALL_REFLECTION);
            
            // 2nd drawing
            context3D.setRenderToBackBuffer();
            context3D.clear();
            // background
            sigl.setCameraMatrix(_camera);
            context3D.setProgram(programs[1]);
            context3D.setTextureAt(0, _cubeTex);
            context3D.setTextureAt(1, null);
            context3D.setCulling("front");
            context3D.setDepthTest(false, "always");
            context3D.setProgramConstantsFromMatrix("vertex", 0, sigl.modelViewProjectionMatrix, true);
            if (!TEST_MODE) _back.drawTriangles(context3D);
            // keyboard
            context3D.setProgram(programs[0]);
            context3D.setTextureAt(0, _specTex);
            context3D.setTextureAt(1, _cubeTex);
            context3D.setCulling("back");
            context3D.setDepthTest(true, "less");
            sigl.push();
            for (i=0; i<KEY_COUNT; i++) {
                sigl.push().m(keyMatrix[i]).r(keyRotate[i].x, Vector3D.X_AXIS);
                drawMesh(keyMesh[i], keyMaterial[i], KEY_REFLECTION);
                sigl.pop();
                keyRotate[i].x += keyRotate[i].y;
                keyRotate[i].y -= keyRotate[i].x * SPRING_STRENGTH;
                keyRotate[i].y *= 1-DAMPER_STRENGTH;
            }
            sigl.pop();
            
            // for test
            if (TEST_MODE && Math.random() < 0.2) {
                var idx:int = Math.random()*69;
                Ball.create(keyPosition[idx], idx, Math.random()*127);
            }

            // point sprite (balls)
            sigl.modelViewProjectionMatrix.copyColumnTo(2, vc);
            now = getTimer();
            Ball.update(_ballField, now - _prevTime, vc);
            _prevTime = now;
            context3D.setProgram(programs[2]);
            context3D.setTextureAt(0, _ballSprite);
            context3D.setTextureAt(1, null);
            context3D.setCulling("none");
            context3D.setDepthTest(false, "less");
            context3D.setProgramConstantsFromMatrix("vertex", 0, sigl.modelViewProjectionMatrix, true);
            _ballField.drawTriangles(context3D);

            // front screen
            sigl.setCameraMatrix(null).id();
            context3D.setTextureAt(0, null);
            context3D.setTextureAt(1, null);
            context3D.setCulling("none");
            context3D.setDepthTest(false, "always");
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            if (faderColor[3] > 0) {    // fader
                context3D.setProgram(programs[3]);
                context3D.setProgramConstantsFromVector("fragment", 0, faderColor);
                _fader.drawTriangles(context3D);
            }
            // text
            context3D.setProgram(programs[4]);
            context3D.setTextureAt(0, _textTex);
            context3D.setProgramConstantsFromVector("fragment", 0, textColor);
            _text.drawTriangles(context3D);
            
            //if(!_s){_s=new BitmapData(450,450,false,0);with(addChildAt(new Bitmap(_s),0)){x=y=8;}}context3D.drawToBitmapData(_s);
            context3D.present();
        }
        private var _s:BitmapData = null;
        
        private var _fc4:Vector.<Number> = Vector.<Number>([1, 0, 0, 0])
        private function drawMesh(mesh:Mesh, material:FlatShadingMaterial, ref:Number) : void {
            var context3D:Context3D = ptolemy.context3D, sigl:SiGLCore = ptolemy.sigl; 
            _fc4[0] = 1-ref; _fc4[1] = ref;
            _light.transform(sigl);
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            context3D.setProgramConstantsFromMatrix("vertex",   4, sigl.modelViewMatrix, true);
            context3D.setProgramConstantsFromVector("vertex",   8, _camera.cameraVector(sigl));
            context3D.setProgramConstantsFromVector("fragment", 0, _light.lightVector);
            context3D.setProgramConstantsFromVector("fragment", 1, _light.halfVector);
            context3D.setProgramConstantsFromVector("fragment", 2, material.ambientVector);
            context3D.setProgramConstantsFromVector("fragment", 3, material.diffuseDifVector);
            context3D.setProgramConstantsFromVector("fragment", 4, _fc4);
            mesh.drawTriangles(context3D);
        }
        
        private function clearText() : void { textBD.fillRect(textBD.rect, 0); }
        private function drawText(ty:Number, text:String, isCenter:Boolean=true, scale:Number=1) : void {
            var label:Label, dx:Number, dy:Number, tx:Number;
            Style.LABEL_TEXT = 0xffffffff;
            label = new Label(null, 0, 0, text);
            tx = (isCenter) ? (256-label.width*scale*0.5) : (470-label.width*scale);
            ty += 10;
            textBDMatrix.setTo(scale, 0, 0, scale, 0, 0);
            for (dy=-1; dy<=1; dy++) for (dx=-1; dx<=1; dx++) {
                textBDMatrix.tx = tx + dx;
                textBDMatrix.ty = ty + dy;
                textBD.draw(label, textBDMatrix);
            }
            Style.LABEL_TEXT = 0xff000000;
            textBDMatrix.tx = tx;
            textBDMatrix.ty = ty;
            textBD.draw(new Label(null, 0, 0, text), textBDMatrix);
        }
        private function uploadText() : void {
            _textTex.uploadFromBitmapData(textBD);
        }
    }
}

// Shaders
// reflection render ----------
var vs0:String = <agal><![CDATA[
m44 op, va0, vc0
mov v0, va1
sub vt0, va0, vc8
nrm vt0.xyz, vt0
dp3 vt1.x, vt0, va1
add vt1.x, vt1.x, vt1.x
mul vt1, va1, vt1.x
add vt0, vt0, vt1
m33 vt1.xyz, vt0, vc4
mov vt1.w, vc127.x
mov v1, vt1
]]></agal>;
var fs0:String = <agal><![CDATA[
dp3 ft0.x, v0, fc0
abs ft0.x, ft0.x
sat ft0.x, ft0.x
mul ft0, fc3, ft0.x
add ft0, ft0, fc2
dp3 ft1.x, v0, fc1
sat ft1.x, ft1.x
tex ft2, ft1.xx, fs0 <2d,clamp,nearest>
tex ft3, v1.xyz, fs1 <cube,linear,mipnearest>
mul ft0, ft0, fc4.x
mul ft3, ft3, fc4.y
add ft0, ft0, ft3
add oc, ft0, ft2
]]></agal>;
// background ----------
var vs1:String = <agal><![CDATA[
m44 op, va0, vc0
mov v0, va1
]]></agal>;
var fs1:String = <agal><![CDATA[
tex oc, v0.xyz, fs0 <cube,linear,mipnearest>
]]></agal>;
// point sprite ----------
var vs2:String = <agal><![CDATA[
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
var fs2:String = <agal><![CDATA[
tex ft0, v0.xy, fs0 <2d, clamp, nearest>
mul ft0, ft0, v1
add ft0, ft0, v2
sat oc, ft0
]]></agal>;
// fader ----------
var vs3:String = "m44 op, va0, vc0";
var fs3:String = "mov oc, fc0";
// text area ----------
var vs4:String = <agal><![CDATA[
m44 op, va0, vc0
mov v0, va1
]]></agal>;
var fs4:String = <agal><![CDATA[
tex ft0, v0.xy, fs0 <2d, clamp, nearest>
mul oc, ft0, fc0
]]></agal>;

var shaders:Array = [{"vs":vs0,"fs":fs0}, {"vs":vs1,"fs":fs1}, {"vs":vs2,"fs":fs2}, {"vs":vs3,"fs":fs3}, {"vs":vs4,"fs":fs4}];




import flash.geom.*;
import flash.display.*;
import flash.display3D.*;
import flash.display3D.textures.*;
import org.si.sion.effector.*;

// cube texture extractor
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

// Ball particle class
class Ball extends Vector3D {
    static public var callbackHit:Function, texInfo:PointSpriteTexInfo, halfGrav:Number, delayTime:Number;
    static private var _active:Ball, _free:Ball, _sorted:Ball=null;
    public var next:Ball, prev:Ball, start:Vector3D = new Vector3D(), vel:Vector3D = new Vector3D(), age:Number, keyIndex:int, projZ:Number;
    function Ball() { next = prev = this; }
    public function setup(x:Number, y:Number, z:Number, tx:Number, ty:Number, tz:Number, time:Number) : void {
        var invtime:Number = 1/time;
        setTo(x, y, z);
        start.setTo(x, y, z);
        vel.setTo((tx-x)*invtime, (ty-y)*invtime, (tz-z-halfGrav*time*time)*invtime);
        age = 0;
    }
// linked list operations ----------
    public function push(b:Ball) : void {
        b.next = this;
        b.prev = prev;
        b.prev.next = b;
        b.next.prev = b;
    }
    public function unshift(b:Ball) : void {
        b.next = next;
        b.prev = this;
        b.prev.next = b;
        b.next.prev = b;
    }
    public function shift() : Ball {
        if (next == this) return null;
        var inst:Ball = next;
        next = inst.next;
        next.prev = this;
        inst.next = inst.prev = inst;
        return inst;
    }
    public function insertSort(b:Ball) : void {
        for (var t:Ball=prev; t!=this; t=t.prev) {
            if (t.projZ<=b.projZ) break;
        }
        b.prev = t;
        b.next = t.next;
        b.prev.next = b;
        b.next.prev = b;
    }
// global operations ----------
    static public function initialize(hit:Function, gravity:Number, delay:Number) : void {
        _active = new Ball();
        _free   = new Ball();
        _sorted = new Ball();
        callbackHit = hit;
        halfGrav = -gravity * 0.5 / 1000;
        delayTime = delay;
    }
    static public function create(t:Vector3D, keyIndex:int, velocity:int) : void {
        var newBall:Ball = _free.shift() || new Ball();
        newBall.setup(0, 0, velocity-600, t.x, t.y, t.z, delayTime);
        newBall.keyIndex = keyIndex;
        _active.unshift(newBall);
    }
    static public function update(psf:PointSpriteField, dage:Number, v2:Vector3D) : void {
        var ball:Ball;
        // move and sort
        while (ball=_active.shift()) {
            ball.age += dage;
            ball.x = ball.start.x + ball.vel.x * ball.age;
            ball.y = ball.start.y + ball.vel.y * ball.age;
            ball.z = ball.start.z + ball.vel.z * ball.age + halfGrav * ball.age * ball.age;
            if (ball.z < -600) _free.push(ball);
            else {
                if (ball.age > delayTime) {
                    ball.x = ball.start.x + ball.vel.x * delayTime;
                    ball.y = ball.start.y + ball.vel.y * delayTime;
                    ball.z = ball.start.z + ball.vel.z * delayTime + halfGrav * delayTime * delayTime;
                    ball.setup(ball.x, ball.y, ball.z, 0, 0, -600, delayTime*0.75);
                    callbackHit(ball.keyIndex);
                }
                ball.projZ = ball.x * v2.x + ball.y * v2.y + ball.z * v2.z + v2.w;
                _sorted.insertSort(ball);
            }
        }
        // create sprite
        ball = _sorted; _sorted = _active; _active = ball;
        psf.clearSprites();
        for (ball=_active.next; ball!=_active; ball=ball.next) {
            psf.createSprite(texInfo, ball.x, ball.y, ball.z, 1,0,0,1, 1,1,1,(ball.z>-200)?1:((ball.z+600)*0.0025));
        }
    }
}

class DelayLine extends SiEffectBase {
    private var _buf:Vector.<Number>, _bufIndex:int;
    function DelayLine(length:Number) {  // length [ms]
        _buf = new Vector.<Number>(int(88.2 * length));
    }
    
    override public function prepareProcess() : int {
        var i:int, imax:int = _buf.length;
        for (i=0; i<imax; i++) _buf[i] = 0;
        _bufIndex = 0;
        return 2;
    }
    
    override public function process(channels:int, buffer:Vector.<Number>, startIndex:int, length:int) : int {
        startIndex <<= 1;
        length <<= 1;
        var i:int, imax:int = startIndex + length, bufLength:int=_buf.length;
        for (i=startIndex; i<imax; i++) {
            _buf[_bufIndex] = buffer[i];
            _bufIndex++;
            if (_bufIndex == bufLength) _bufIndex = 0;
            buffer[i] = _buf[_bufIndex];
        }
        return channels;
    }
}

class SolidFactory {
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
            //icosahedron(mesh, 1);
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
    
    static public function plane(mesh:Mesh, width:Number, height:Number, z:Number=0) : Mesh {
        _tv.length = 0;
        _tv.push(-width*0.5,-height*0.5,z, width*0.5,-height*0.5,z, -width*0.5,height*0.5,z, width*0.5,height*0.5,z);
        mesh.qface(0,1,2,3);
        return mesh.updateBuffer(Mesh.vertexAttributeName, _tv);
    }
    
// internal functions --------------------------------------------------
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
            _tv[0] = (rx*=rl); _tv[4] = (ry*=rl); _tv[8]  = (rz*=rl); _tv[12] = -(cx*rx+cy*ry+cz*rz) * w;
            _tv[2] = (dx*=dl); _tv[6] = (dy*=dl); _tv[10] = (dz*=dl); _tv[14] = -(cx*dx+cy*dy+cz*dz) * w;
            _tv[1] = (ux=dy*rz-dz*ry); _tv[5] = (uy=dz*rx-dx*rz); _tv[9] = (uz=dx*ry-dy*rx); _tv[13] = -(cx*ux+cy*uy+cz*uz) * w;
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
        static private var _out:Vector.<Number> = new Vector.<Number>();
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
        public function put(vtx:Vector.<Number>, idx:Vector.<uint>, mat:Matrix3D) : Mesh {
            var i:int, imax:int = idx.length, offset:int = vertexCount;
            mat.transformVectors(vtx, _out);
            vertexCount += vtx.length / 3;
            updateBuffer("V", _out, offset);
            for (i=0; i<imax;) face(idx[i++]+offset, idx[i++]+offset, idx[i++]+offset);
            return this;
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
    
    /** Camera */
    class Camera extends SiGLMatrix {
        public var fromVector:Vector.<Number> = new Vector.<Number>(4, true), toVector:Vector.<Number> = new Vector.<Number>(4, true);
        private var _in :Vector.<Number> = new Vector.<Number>(3, true), _out:Vector.<Number> = new Vector.<Number>(4, true), _cvdir:Boolean;
        function Camera(x:Number=0, y:Number=0, z:Number=-300) { update(x, y, z); }
        public function update(cx:Number, cy:Number, cz:Number, tx:Number=0, ty:Number=0, tz:Number=0, ux:Number=0, uy:Number=1, uz:Number=0) : Camera {
            _in[0]=fromVector[0]=cx; _in[1]=fromVector[1]=cy; _in[2]=fromVector[2]=cz; fromVector[3]=1;
            toVector[0]=tx;   toVector[1]=ty;   toVector[2]=tz;   toVector[3]=1;
            lookAt(cx, cy, cz, tx, ty, tz, ux, uy, uz, 1);
            _cvdir = true;
            return this;
        }
        public function cameraVector(sigl:SiGLCore) : Vector.<Number> {
            if (_cvdir) {
                sigl.modelViewMatrix.inverted.transformVectors(_in, _out);
                var l:Number = _out[0]*_out[0]+_out[1]*_out[1]+_out[2]*_out[2];
                if (l!=0) l=1/Math.sqrt(l);
                _out[0]*=l;_out[1]*=l;_out[2]*=l;_out[3]=1;
                _cvdir = false;
            }
            return _out;
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
    
    /** Point Sprite Field */
    class PointSpriteField extends Mesh {
    // variables --------------------------------------------------
        public var spriteCount:int, maxSpriteCount:int;
    // constructor --------------------------------------------------
        function PointSpriteField(context3D:Context3D, maxSpriteCount:int=1024) {
            super("V3S2T2C4O4");
            vertexCount = (this.maxSpriteCount = maxSpriteCount) * 4;
            spriteCount = 0;
            for (var i:int=0, j:int=0; i<maxSpriteCount; i++) qface(j++, j++, j++, j++);
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
                for (var i:int=0; i<5; i++) context3D.setVertexBufferAt(i, null, 0, "float1");
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