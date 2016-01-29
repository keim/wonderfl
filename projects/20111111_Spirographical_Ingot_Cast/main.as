package {
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import flash.geom.*;
    import flash.text.*;
    import flash.net.*;
    
    import com.adobe.utils.*;
    import com.adobe.crypto.SHA1;
    import com.bit101.components.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    import org.libspark.betweenas3.*;
    import org.libspark.betweenas3.easing.*;
    import org.libspark.betweenas3.tweens.*;
//    import org.si.ptolemy.*;
//    import org.si.ptolemy.core.*;

    public class main extends Sprite {
/*      // for local
        private const envURL:String = "_env1.png";
        private const partURL:String = "part.png";
/*/     // for wonderfl
        private const envURL:String = "http://assets.wonderfl.net/images/related_images/b/b2/b217/b2177f87d979a28b9bcbb6e0b89370e77ce22337";
        private const partURL:String = "http://assets.wonderfl.net/images/related_images/6/6a/6a2d/6a2dffe6da5745c6a74c28a52a163077689afdab";
//*/
        
        private var ptolemy:Ptolemy;
        
        private var asm:AGALMiniAssembler = new AGALMiniAssembler();
        private var programs:Vector.<Program3D> = new Vector.<Program3D>();

        private var _mesh:Mesh = new Mesh("V3N3");
        private var _trochoid:Trochoid3D = new Trochoid3D();
        
        private var sin:Vector.<Number> = new Vector.<Number>(), cos:Vector.<Number> = new Vector.<Number>();
        private var _nodeCount:int, _roundCount:int;

        private var _creatingTime:Number = 20000, _breakingTime:Number = 1000, iphase:Number;
        private var _ref:Number = 0.8;
        private var _material:FlatShadingMaterial = new FlatShadingMaterial(0xffffff, 1, 0.1, 0.8, 0.8, 16);
        private var _radius:Vector.<Number>, _radiusBuffer:VertexBuffer3D;
        private var _colors:Vector.<Number>, _colorsBuffer:VertexBuffer3D;
        private var _specTex:Texture, _shpereMap:BitmapData, _shpereTex:Texture;
        private var _partTex:Texture, _partMap:BitmapData;
        private var _emitterTex:PointSpriteTexInfo, _fireTex:PointSpriteTexInfo, _breakTex:PointSpriteTexInfo;
        private var _fireSetting:ParticleSetting, _breakSetting:ParticleSetting, _particleColor:Vector3D = new Vector3D(1,1,1,1);
        private var _psf:PointSpriteField;
        private var _light:Light = new Light();
        
        private var _freq1:Number=8,   _freq2:Number=7,   _zfreq:Number=1,   _hfreq:Number = 8;
        private var _zvar1:Number=1.2, _zvar2:Number=0.4, _radrt:Number=0.6, _width:Number = 8;
        private var _sliders:Array = [], _shapeInput:InputText;
        private var _cameraMatrix:SiGLMatrix = new SiGLMatrix();
        private var _trochoidMatrix:SiGLMatrix = new SiGLMatrix();
        
        private var _radpos:Vector.<Number>, _radvel:Vector.<Number>, _prevIndex:int;
        private var _startTime:Number, _animStartTime:Number, _isBreaking:Boolean, _restart:Boolean = false;
        private var _appID:String, _userID:String, _shapeTitle:Label, _title:String, _autoPlay:CheckBox;
        
        public function get title() : String { return _title; }
        public function set title(str:String) : void {
            _title = str;
            _shapeTitle.text = "#SPIROGRAPH{" + str + "}";
        }
        
        
        function main() {
            _appID = loaderInfo.parameters["appId"];
            _userID = loaderInfo.parameters["viewer.displayName"];
            Wonderfl.disable_capture();
            ptolemy = new Ptolemy(this, 8, 8, 450, 450);
            ptolemy.sigl.setZRange(-300, 3000);
            ptolemy.addEventListener(Event.COMPLETE, setup);
            ptolemy.load(new URLRequest(envURL),  "env",  "img", true);
            ptolemy.load(new URLRequest(partURL), "part", "img", true);
        }
        
        
        private function setup(e:Event) : void {
            var i:int, context3D:Context3D = ptolemy.context3D, prog:Program3D;
            removeEventListener(Event.COMPLETE, setup);
            
            context3D.enableErrorChecking = true;
            
            // create shape
            updateCount(4096, 8);
            //updateCount(512, 3);
            
            _shpereMap = ptolemy.resources["env"].bitmapData;
            _shpereTex = context3D.createTexture(_shpereMap.width, _shpereMap.height, "bgra", false);
            _shpereTex.uploadFromBitmapData(_shpereMap);
            _partMap = ptolemy.resources["part"].bitmapData;
            _partTex = context3D.createTexture(_partMap.width, _partMap.height, "bgra", false);
            _partTex.uploadFromBitmapData(_partMap);
            _specTex = context3D.createTexture(1024, 1, "bgra", false);
            _specTex.uploadFromBitmapData(_material.specMap);
            
            _trochoid.matrix3D = _trochoidMatrix;
            _fireTex    = new PointSpriteTexInfo(0,0.5,0.5,1,32,32);
            _breakTex   = new PointSpriteTexInfo(0.5,0,1,0.5,24,24);
            _emitterTex = new PointSpriteTexInfo(0.5,0.5,1,1,32,32);
            _fireSetting  = new ParticleSetting({texture:_fireTex,  gravity:new Vector3D(0,-600,0), speedVar:200, life:1, lifeVar:1, startColor:_particleColor});
            _breakSetting = new ParticleSetting({texture:_breakTex, gravity:new Vector3D(0, 400,0), speedVar:100, life:2, lifeVar:2, startColor:_particleColor, velocity:new Vector3D(0, -200,0), angleVar:360, rotationVar:360});
            _psf = new PointSpriteField(context3D, 4096);
            
            for (i=0; i<shaders.length; i++) {
                prog = context3D.createProgram();
                prog.upload(asm.assemble("vertex", shaders[i].vs), asm.assemble("fragment", shaders[i].fs));
                programs.push(prog);
            }
            
            context3D.setProgramConstantsFromVector("vertex",  126, Vector.<Number>([ptolemy.sigl.pointSpriteFieldScale.x, ptolemy.sigl.pointSpriteFieldScale.y, 0, 0]));
            context3D.setProgramConstantsFromVector("vertex",  127, Vector.<Number>([0, 0.5, 1, 2]));
            context3D.setProgramConstantsFromVector("fragment", 27, Vector.<Number>([0, 0.5, 1, 2]));
            
            _startTime = getTimer();
            setupControler();
            addEventListener(Event.ENTER_FRAME, firstScreen);
        }
        
        private function encodeParam() : String {
            var str:String = "";
            str += _freq1.toFixed(0) + ":" + _freq2.toFixed(0) + ":" + _zfreq.toFixed(0) + ":" + _hfreq.toFixed(0)+",";
            str += _zvar1.toFixed(1) + "," + _zvar2.toFixed(1) + "," + _radrt.toFixed(1) + "," + _width.toFixed(1);
            return str;
        }
        
        private function decodeParam(str:String) : Boolean {
            var res:* = (/s\{(.+?)\}/).exec(str);
            if (res && res[1]) str = res[1];
            var p:Array = str.split(/[:,]/);
            title = str;
            if (p.length != 8) {
                SHA1.hash(str);
                SHA1.digest.position = 0;
                var i:int, v:Array = [];
                for (i=0; i<18; i++) v.push(SHA1.digest.readUnsignedByte()&255);
                encrypto(v);
                return false;
            }
            for (i=0; i<8; i++) _sliders[i].value = Number(p[i]);
            _freq1 = _sliders[0].value; _freq2 = _sliders[1].value; _zfreq = _sliders[2].value; _hfreq = _sliders[3].value;
            _zvar1 = _sliders[4].value; _zvar2 = _sliders[5].value; _radrt = _sliders[6].value; _width = _sliders[7].value;
            return true;
        }
        
        private function randomize() : void {
            var i:int, v:Array = [];
            for (i=0; i<18; i++) v.push(int(Math.random()*256));
            encrypto(v);
            title = encodeParam();
        }
        
        private function encrypto(keys:Array) : void {
            var r:Number, rot:Array, keyIndex:int=0; // length=18
            _freq1 = _sliders[0].value = int($()*$()*32)+1;
            _freq2 = _sliders[1].value = int(($()+$())*32)-32;
            r = $();
            _zfreq = _sliders[2].value = int(r*r)*4+1; if (_zfreq>4) _zfreq=_sliders[6].value =0;
            r = int(Math.abs(_freq1+_freq2));
            rot = [1, _freq1-1, _freq1, _freq1+1, _freq2-1, _freq2, _freq2+1, r, r, int($()*32)+1];
            _hfreq = _sliders[3].value = rot[int($()*rot.length)]; if (_hfreq < 1) _hfreq = _sliders[3].value = 1;
            _zvar1 = _sliders[4].value = int(($()+$()+$())*20)*0.1-3;
            _zvar2 = _sliders[5].value = int(($()+$()+$())*20)*0.1-3;
            _radrt = _sliders[6].value = int(($()+$())*20)*0.03; if (_radrt>1) _radrt=_sliders[6].value =(_radrt-1)*10+1;
            r = ($()+$()+$())/3;
            _width = _sliders[7].value = int(r * r * 31) + 1;
            function $() : Number { return (keys[keyIndex++]&255) / 256; } 
        }
        
        private function _tweet(text:String) : void  {
            var url:String = escapeMultiByte("http://wonderfl.net/c/" + _appID);
            navigateToURL(new URLRequest("https://twitter.com/intent/tweet?" + 
                "text=" + escapeMultiByte(text) + "&related=keim_at_si&url=" + url + "&original_referer=" + url
            ));
        }
/*
        private function _searchTweet() : void {
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.addEventListener(Event.COMPLETE, _onCompleteSearchTweet);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, _onErrorSearchTweet);
            var xmlURL:String = "http://search.twitter.com/search.atom?q=" + encodeURIComponent("#spirograph3d");
            urlLoader.load(new URLRequest(xmlURL));
        }
        private function _onCompleteSearchTweet(e:Event) : void {
        }
        private function _onErrorSearchTweet(e:Event) : void {
        }
*/      
        
        private function setupControler() : void {
            addChild(_mouseCapture = new Sprite());
            _mouseCapture.graphics.beginFill(0, 0);
            _mouseCapture.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            _mouseCapture.graphics.endFill();
            _mouseCapture.visible = false;
            addChild(_ctrl = new Sprite()); _w=200; _h=0; 
            newSlider("ambient", 0, 1, _material.ambient, 0.1, 1, function(e:Event):void { _material.ambient = e.target.value; });
            newSlider("diffuse", 0, 1, _material.diffuse, 0.1, 1, function(e:Event):void { _material.diffuse = e.target.value; });
            newSlider("power",   0,64, _material.power,     1, 0, function(e:Event):void { _material.power = e.target.value;    _specTex.uploadFromBitmapData(_material.specMap);});
            newSlider("specular",0, 3, _material.specular,0.1, 1, function(e:Event):void { _material.specular = e.target.value; _specTex.uploadFromBitmapData(_material.specMap);});
            newSlider("refrect", 0, 1, _ref,              0.1, 1, function(e:Event):void { _ref = e.target.value; });
            setupControlPanel(0, "MATERIAL");
            addChild(_ctrl = new Sprite()); _w=360; _h=0;
            _sliders.push(newSlider("frequency1",   1, 32, _freq1,    1, 0, function(e:Event):void { _freq1 = e.target.value; updateMesh(); _autoPlay.selected = false; title = encodeParam(); }));
            _sliders.push(newSlider("frequency2", -31, 31, _freq2,    1, 0, function(e:Event):void { _freq2 = e.target.value; updateMesh(); _autoPlay.selected = false;  title = encodeParam(); }));
            _sliders.push(newSlider("z-freq.",      0,  4, _zfreq,    1, 0, function(e:Event):void { _zfreq = e.target.value; updateMesh(); _autoPlay.selected = false;  title = encodeParam(); }));
            _sliders.push(newSlider("hue-freq.",    1, 32, _hfreq,    1, 0, function(e:Event):void { _hfreq = e.target.value; updateColor(); _autoPlay.selected = false; title = encodeParam(); }));
            _sliders.push(newSlider("z-varience1", -3,  3, _zvar1,  0.1, 1, function(e:Event):void { _zvar1 = e.target.value; updateMesh(); _autoPlay.selected = false;  title = encodeParam(); }));
            _sliders.push(newSlider("z-varience2", -3,  3, _zvar2,  0.1, 1, function(e:Event):void { _zvar2 = e.target.value; updateMesh(); _autoPlay.selected = false;  title = encodeParam(); }));
            _sliders.push(newSlider("radius ratio", 0,  3, _radrt,  0.1, 1, function(e:Event):void { _radrt = e.target.value; updateMesh(); _autoPlay.selected = false;  title = encodeParam(); }));
            _sliders.push(newSlider("wire width",   1, 32, _width,    1, 0, function(e:Event):void { _width = e.target.value; _autoPlay.selected = false; title = encodeParam(); }));
            _shapeInput = new InputText(_ctrl, 4, _h+2, "");
            _shapeInput.setSize(276, 18);
            new PushButton(_ctrl, 282, _h+2, "SETUP",  function(e:Event):void { decodeParam(_shapeInput.text); _autoPlay.selected = false; _restart = true; reset(); }).setSize(76, 18); _h += 24;
            setupControlPanel(1, "SHAPE");
            _autoPlay = new CheckBox(this, 370, 465-70, "AUTO PLAY");
            _autoPlay.selected = true;
            new PushButton(this, 368, 465-54, "CLEAR",   function(e:Event):void { reset(); }).setSize(90, 18);
            new PushButton(this, 368, 465-36, "RESTART", function(e:Event):void { _restart = true; reset(); }).setSize(90, 18);
            new PushButton(this, 368, 465-18, "TWEET", function(e:Event):void { _tweet("Spirographical Ingot Cast s{"+title+"} #spirograph3d #wonderfl"); }).setSize(90, 18);
            //new PushButton(this, 368, 465, "RANDOM",  function(e:Event):void { randomize(); updateMesh(); }).setSize(90, 18);
            _shapeTitle = new Label(this, 10, 10, "");
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
        private function newSlider(label:String, min:Number, max:Number, val:Number, tick:Number, prec:int, func:Function) : HUISlider {
            var slider:HUISlider = new HUISlider(_ctrl, 4, _h, label, func);
            slider.setSliderParams(min, max, val); slider.tick = tick; slider.labelPrecision = prec;
            _h += 20; slider.width = _w;
            return slider;
        }
        private var _ctrl:Sprite, _h:Number, _w:Number, _mouseCapture:Sprite;
        
        private function updateCount(nodeCount:int, roundCount:int) : void {
            var vertexCount:int = nodeCount * roundCount;
            _nodeCount  = nodeCount;
            _roundCount = roundCount;
            _radius = new Vector.<Number>(vertexCount, true);
            _colors = new Vector.<Number>(vertexCount * 3, true);
            _radpos = new Vector.<Number>(_nodeCount, true);
            _radvel = new Vector.<Number>(_nodeCount, true);
            _mesh.vertexCount = vertexCount;
            if (_radiusBuffer) _radiusBuffer.dispose();
            if (_colorsBuffer) _colorsBuffer.dispose();
            _radiusBuffer = ptolemy.context3D.createVertexBuffer(vertexCount, 1);
            _colorsBuffer = ptolemy.context3D.createVertexBuffer(vertexCount, 3);
            cos.length = sin.length = _roundCount;
            var i:int, ang:Number, dang:Number = 6.283185307179586 / _roundCount;
            for (i=0, ang=0; i<_roundCount; i++, ang+=dang) {
                sin[i] = -Math.sin(ang);
                cos[i] =  Math.cos(ang);
            }
        }
        
        private function updateMesh() : void {
            var i:int, j:int, i0:int, v:Vector3D, nx:Number, ny:Number, nz:Number, imr:int, i0mr:int, gcd:int, 
                v0:Vector3D = new Vector3D(), v1:Vector3D = new Vector3D(),
                vx:Vector3D = new Vector3D(), vy:Vector3D = new Vector3D(), vz:Vector3D = new Vector3D(),
                context3D:Context3D = ptolemy.context3D, prog:Program3D, vtx:Vector.<Number> = _mesh.vertices,
                iNodeCount:Number = 1/_nodeCount, rcm1:int=_roundCount-1, hueFreq:Number=iNodeCount*(_freq1+_freq2)*3.141592653589793,
                rad1:Number = 100, rad2:Number = 100*_radrt;
            
            _trochoidMatrix.identity();
            for (gcd=i=1; i<=_freq1; i++) if ((int(_freq1))%i == 0 && (int(_freq2))%i == 0) gcd = i;
            if (_zvar1 == 0) _zvar1 = 0.0000152587890625;
            _trochoid.init(rad1, rad2, _zvar1*100, _freq1, _freq2, (_freq1+_freq2)*_zfreq + gcd-1);
            _trochoid.dr2 = (_zvar2/_zvar1-1) / (100*(1+_radrt));
            
            v0.copyFrom(_trochoid.calc(0));
            v1.copyFrom(_trochoid.calc(iNodeCount));
            for (i0=i=0; i<_nodeCount; i++) {
                v = _trochoid.calc((i+2)*iNodeCount);
                vz.setTo(v.x-v0.x, v.y-v0.y, v.z-v0.z);
                vx.copyFrom(v1);
                if (vx.x == 0 && vx.y == 0 && vx.z == 0) vx.copyFrom(v0);
                vy.setTo(vz.y*vx.z-vz.z*vx.y, vz.z*vx.x-vz.x*vx.z, vz.x*vx.y-vz.y*vx.x);
                vy.normalize();
                vx.setTo(vy.y*vz.z-vy.z*vz.y, vy.z*vz.x-vy.x*vz.z, vy.x*vz.y-vy.y*vz.x);
                vx.normalize();
                for (j=0; j<_roundCount; j++) {
                    nx = vx.x*cos[j] + vy.x*sin[j];
                    ny = vx.y*cos[j] + vy.y*sin[j];
                    nz = vx.z*cos[j] + vy.z*sin[j];
                    vtx[i0] = v1.x; i0++;
                    vtx[i0] = v1.y; i0++;
                    vtx[i0] = v1.z; i0++;
                    vtx[i0] = nx; i0++;
                    vtx[i0] = ny; i0++;
                    vtx[i0] = nz; i0++;
                }
                v0.copyFrom(v1);
                v1.copyFrom(v);
            }
            _mesh.clear();
            for (i0=_nodeCount-1, i=0; i<_nodeCount; i0=i, i++) {
                imr  = i  * _roundCount;
                i0mr = i0 * _roundCount;
                for (j=0; j<rcm1; j++) _mesh.qface(i0mr+j, i0mr+j+1, imr+j, imr+j+1);
                _mesh.qface(i0mr+rcm1, i0mr, imr+rcm1, imr);
            }
            _mesh.allocateBuffer(context3D);
            _mesh.upload();
            updateColor();
        }
        
        private function updateColor() : void {
            var i:int, j:int, rgb:Vector3D, ic:int, k:Number = _hfreq/_nodeCount;
            for (ic=i=0; i<_nodeCount; i++) {
                rgb = hsv2rgb(i*k, 1, 1);
                for (j=0; j<_roundCount; j++) {
                    _colors[ic] = rgb.x; ic++;
                    _colors[ic] = rgb.y; ic++;
                    _colors[ic] = rgb.z; ic++;
                }
            }
            _colorsBuffer.uploadFromVector(_colors, 0, _nodeCount*_roundCount);
        }
        
        private function start() : void {
            for (var i:int=0; i<_nodeCount; i++) _radvel[i] = _radpos[i] = 0;
            _animStartTime = getTimer();
            _prevIndex = 0;
            _isBreaking = false;
            iphase = 1/_creatingTime;
        }

        private function reset() : void {
            _animStartTime = getTimer();
            _prevIndex = 0;
            _isBreaking = true;
            iphase = 200/_breakingTime;
        }
        
        private var _firstScreen:Sprite, _firstInput:InputText;
        private function firstScreen(e:Event) : void {
            if (!_firstScreen) {
                addChild(_firstScreen = new Sprite());
                _firstScreen.graphics.beginFill(0xffffff, 0.75);
                _firstScreen.graphics.drawRect(0,0,465,465);
                _firstScreen.graphics.endFill();
                new Label(_firstScreen, 133, 213, "YOUR NAME : ");
                _firstInput = new InputText(_firstScreen, 213, 213, _userID);
                _firstInput.setSize(120, 18);
                new PushButton(_firstScreen, 158, 233, "CREATE YOUR SPIROGRAPH", function(e:Event) : void {
                    removeChild(_firstScreen);
                    removeEventListener(Event.ENTER_FRAME, firstScreen);
                    Particle.initialize();
                    decodeParam(_firstInput.text);
                    updateMesh();
                    start();
                    addEventListener(Event.ENTER_FRAME, draw);
                }).setSize(150, 18);
            }
        }
        
        private function draw(e:Event) : void {
            var context3D:Context3D = ptolemy.context3D,
                sigl:SiGLCore = ptolemy.sigl, 
                phase:Number = (getTimer() - _animStartTime) * iphase,
                rotPhase:Number = (getTimer() - _startTime) / 20000,
                cp:Vector3D, c:Vector3D = sigl.defaultCameraMatrix.position;
            
            var i:int, imax:int, ilimit:int, j:int, idx:int, n:Number, v:Vector3D, 
                vstep:int = _mesh.data32PerVertex, vtx:Vector.<Number> = _mesh.vertices;

            // object rotation
            _trochoidMatrix.identity();
            _trochoidMatrix.prependRotationXYZ(Math.sin(rotPhase*Math.PI*4)*Math.PI*0.25, 0, Math.sin(rotPhase*Math.PI)*Math.PI);
            cp = _trochoid.calc(phase);
            // object motions
            _psf.clearSprites();
            if (_isBreaking) {
                v = new Vector3D();
                n = phase * phase;
                for (i=0; i<_nodeCount; i++) {
                    if (_radpos[i] > 0) {
                        idx = i * _roundCount * 6;
                        v.setTo(vtx[idx], vtx[idx+1], vtx[idx+2]);
                        if (v.lengthSquared < n) {
                            _radpos[i] = 0;
                            idx = i * _roundCount;
                            for (j=0; j<_roundCount; j++,idx++) _radius[idx] = 0;
                            if (Math.random() < 0.25) {
                                idx = i * _roundCount * 3;
                                _particleColor.setTo(_colors[idx]*0.5+1, _colors[idx+1]*0.5+1, _colors[idx+2]*0.5+1);
                                _particleColor.w = 1;
                                _trochoidMatrix.transform(v);
                                Particle.alloc(_breakSetting, v.x, v.y, v.z);
                            }
                        }
                    }
                }
            } else {
                ilimit = int(_nodeCount * phase);
                if (ilimit < _nodeCount - 1) {
                    if (ilimit > _prevIndex) for (i=_prevIndex; i<ilimit; i++) _radpos[i] = _width / 64;
                    _prevIndex = ilimit;
                    idx = ilimit * _roundCount * 3;
                    _particleColor.setTo(_colors[idx]*1.5, _colors[idx+1]*1.5, _colors[idx+2]*1.5);
                    _particleColor.w = 1;
                    n = (_width + 8) * (Math.random() * 0.1 + 0.1);
                    _psf.createSprite(_emitterTex, cp.x, cp.y, cp.z, n, 0, 0, n);
                    Particle.alloc(_fireSetting, cp.x, cp.y, cp.z);
                } else {
                    ilimit = _nodeCount - 1;
                    _radvel[ilimit] += (_radpos[ilimit-1] + _radpos[0] - _radpos[ilimit]*2) * 0.005 - (_radpos[ilimit] - 1) * 0.2;
                    _radvel[0] += (_radpos[ilimit] + _radpos[1] - _radpos[0]*2) * 0.005 - (_radpos[0] - 1) * 0.2;
                }
                for (i=1; i<ilimit; i++) {
                    _radvel[i] += (_radpos[i-1] + _radpos[i+1] - _radpos[i]*2) * 0.005 - (_radpos[i] - 1) * 0.2;
                }
                for (idx=i=0; i<_nodeCount; i++) {
                    _radpos[i] += (_radvel[i] *= 0.96);
                    n = (_radpos[i]<0) ? 0 : _radpos[i] * _width * 0.5;
                    for (j=0; j<_roundCount; j++,idx++) _radius[idx] = n;
                }
            }
            _radiusBuffer.uploadFromVector(_radius, 0, _radius.length);
            

            // global motion
            sigl.id().r(rotPhase*360, Vector3D.Y_AXIS);
            // lighting vector
            _light.setTo(Math.cos(rotPhase*31.41592653589793), 1, Math.sin(rotPhase*31.41592653589793));
            _light.transform(sigl);
            
            // drawing
            context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
            context3D.clear(0,0,0,1);
            
            sigl.push().m(_trochoidMatrix);
            context3D.setProgram(programs[0]);
            context3D.setDepthTest(true, "less");
            context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
            context3D.setTextureAt(0, _specTex);
            context3D.setTextureAt(1, _shpereTex);
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            context3D.setProgramConstantsFromMatrix("vertex",   4, sigl.modelViewMatrix, true);
            context3D.setProgramConstantsFromVector("fragment", 0, _light.lightVector);
            context3D.setProgramConstantsFromVector("fragment", 1, _light.halfVector);
            context3D.setProgramConstantsFromVector("fragment", 2, _material.ambientVector);
            context3D.setProgramConstantsFromVector("fragment", 3, _material.diffuseDifVector);
            context3D.setProgramConstantsFromVector("fragment", 4, Vector.<Number>([_ref, 0, 0, 0]));
            context3D.setVertexBufferAt(2, _colorsBuffer, 0, "float3");
            context3D.setVertexBufferAt(3, _radiusBuffer, 0, "float1");
            _mesh.drawTriangles(context3D);
            sigl.pop();
            
            Particle.update(_psf);
            context3D.setProgram(programs[1]);
            context3D.setDepthTest(false, "less");
            context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
            context3D.setTextureAt(0, _partTex);
            context3D.setTextureAt(1, null);
            context3D.setProgramConstantsFromMatrix("vertex",   0, sigl.modelViewProjectionMatrix, true);
            _psf.drawTriangles(context3D);
//            if(!_s){_s=new BitmapData(450,450,false,0);with(addChildAt(new Bitmap(_s),0)){x=y=8;}}context3D.drawToBitmapData(_s);
            context3D.present();

            if (_autoPlay.selected) {
                if (_isBreaking) {
                    if (phase > 200) { if (!_restart) randomize(); _restart = false; updateMesh(); start(); }
                } else {
                    if (phase > 1.5) { reset(); }
                }
            } else {
                if (_isBreaking && _restart && phase > 200) { _restart = false; updateMesh(); start(); }
            }
        }
        private var _s:BitmapData = null;
    }
}


// wire
var vs0:String = <agal><![CDATA[
mov vt0.xyz, va1.xyz
mov vt0.w, vc127.x
mov v0, vt0
mul vt1, vt0, va3.xxx
add vt1, vt1, va0
m44 op,  vt1, vc0
m44 vt0, vt0, vc4
mul vt0, vt0, vc127.y
add v1,  vt0, vc127.y
mov v2, va2
mov v2.w, vc127.x
]]></agal>;
var fs0:String = <agal><![CDATA[
dp3 ft0, v0, fc0
mul ft0, ft0, v2
sat ft0, ft0
mul ft0, fc3, ft0
add ft0, ft0, fc2
dp3 ft1, v0, fc1
tex ft3, ft1.xy, fs0 <2d,clamp,nearest>
tex ft4, v1.xy, fs1 <2d,repeat,nearest>
mul ft4, ft4, fc27.w
sub ft4, ft4, fc27.z
mul ft4, ft4, fc4.x
sat ft2, ft4
add ft4, ft4, fc27.z
sat ft1, ft4
add ft0, ft0, ft2
mul ft0, ft0, ft1
add oc, ft0, ft3
]]></agal>;

// point particle
var vs1:String = <agal><![CDATA[
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
var fs1:String = <agal><![CDATA[
tex ft0, v0.xy, fs0 <2d, clamp, nearest>
mul ft0, ft0, v1
add ft0, ft0, v2
sat oc, ft0
]]></agal>;

var shaders:Array = [{"vs":vs0,"fs":fs0},{"vs":vs1,"fs":fs1}];



import flash.geom.*;
import flash.utils.*;
//import org.si.ptolemy.core.*;

var c:Vector3D = new Vector3D();
function hsv2rgb(h:Number, s:Number, v:Number) : Vector3D {
    var ht:Number=(h-int(h)+int(h<0))*6, hi:int=int(ht);
    switch(hi) {
        case 0: c.setTo(v, v*(1-(1-ht+hi)*s), v*(1-s)); break;
        case 1: c.setTo(v*(1-(ht-hi)*s), v, v*(1-s)); break;
        case 2: c.setTo(v*(1-s), v, v*(1-(1-ht+hi)*s)); break;
        case 3: c.setTo(v*(1-s), v*(1-(ht-hi)*s), v); break;
        case 4: c.setTo(v*(1-(1-ht+hi)*s), v*(1-s), v); break;
        case 5: c.setTo(v, v*(1-s), v*(1-(ht-hi)*s)); break;
    }
    return c;
}

class Trochoid3D {
    public var r0:Number, r1:Number, r2:Number, f0:Number, f1:Number, f2:Number, p0:Number, p1:Number, p2:Number, dr2:Number = 0;
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
            c0:Number = Math.cos(a0), c1:Number = Math.cos(a1), x:Number, y:Number;
        _in[0] = x = c0 * r0 + c1 * r1;
        _in[1] = y = s0 * r0 + s1 * r1;
        _in[2] = s2 * r2 * (1 + Math.sqrt(x*x+y*y) * dr2);
        matrix3D.transformVectors(_in, _out);
        $.setTo(_out[0], _out[1], _out[2]);
        return $;
    }
}


class ParticleSetting {
    public var positionVar:Vector3D = null, velocity:Vector3D = null, gravity:Vector3D = null, velocityVar:Number = 0;
    public var speed:Number = 0, speedVar:Number = 0, accel:Number = 0, accelVar:Number = 0;
    public var angle:Number = 0, angleVar:Number = 0, rotation:Number = 0, rotationVar:Number = 0;
    public var life:Number = 1, lifeVar:Number = 0, gradation:Vector.<Vector3D> = null;
    public var startColor:Vector3D = null, endColor:Vector3D = null;
    public var startSize:Number = 1, startSizeVar:Number = 0, endSize:Number = 0, endSizeVar:Number = 0;
    public var texture:PointSpriteTexInfo = new PointSpriteTexInfo(0,0,1,1,32,32);
    function ParticleSetting(param:* = null) {
        if (param) for (var key:String in param) this[key] = param[key];
    }
}

class Particle extends Vector3D {
    static private var s$:Vector.<Number>, c$:Vector.<Number>;
    static private var _vtemp:Vector3D = new Vector3D(), _ONE_VECTOR:Vector3D, _ZERO_VECTOR:Vector3D;
    static private var _activeList:Particle = null;
    static private var _freeList:Particle = null;
    static private var _prevTime:uint;
    public var next:Particle, texture:PointSpriteTexInfo, life:Number, ilife:Number, age:Number;
    public var vx:Number, vy:Number, vz:Number, ax:Number, ay:Number, az:Number;
    public var scale:Number, dscale:Number, angle:int, dangle:Number;
    public var color:Vector3D = new Vector3D(), dcolor:Vector3D = new Vector3D();
    static public function initialize() : void {
        if (!c$) {
            c$ = new Vector.<Number>(8192, true);
            s$ = new Vector.<Number>(8192, true);
            for (var i:int=0;i<8192;i++) c$[(i-2048)&8191] = s$[i] = Math.sin(i*0.0007669903939428206);
            _ONE_VECTOR = new Vector3D(1, 1, 1, 1);
            _ZERO_VECTOR = new Vector3D(0, 0, 0, 0);
        }
        _prevTime = getTimer();
    }
    static public function alloc(setting:ParticleSetting, x:Number, y:Number, z:Number, commonVelocity:Vector3D=null) : Particle {
        var newPart:Particle = _freeList || new Particle(), $:Function = Math.random, 
            speed:Number = setting.speed + setting.speedVar * ($()-0.5),
            accel:Number = setting.accel + setting.accelVar * ($()-0.5),
            velvr:Number = 1 + setting.velocityVar * ($()-0.5), 
            posv:Vector3D = setting.positionVar || _ZERO_VECTOR, 
            vel:Vector3D  = setting.velocity || commonVelocity || _ZERO_VECTOR, 
            grav:Vector3D = setting.gravity || _ZERO_VECTOR, 
            scol:Vector3D = setting.startColor || _ONE_VECTOR, 
            ecol:Vector3D = setting.endColor || scol;
        if (_freeList) _freeList = _freeList.next;
        _vtemp.setTo($()-0.5, $()-0.5, $()-0.5);
        _vtemp.normalize();
        newPart.setTo(x+posv.x*($()-0.5), y+posv.y*($()-0.5), z+posv.z*($()-0.5));
        newPart.texture = setting.texture;
        newPart.life = setting.life  + setting.lifeVar  * ($()-0.5);
        newPart.ilife = 1/newPart.life;
        newPart.age = 0;
        newPart.color.copyFrom(scol);
        newPart.color.w = scol.w;
        newPart.dcolor.setTo(ecol.x-scol.x, ecol.y-scol.y, ecol.z-scol.z);
        newPart.dcolor.w = ecol.w - scol.w;
        newPart.vx = vel.x * velvr + _vtemp.x * speed;
        newPart.vy = vel.y * velvr + _vtemp.y * speed;
        newPart.vz = vel.z * velvr + _vtemp.z * speed;
        newPart.ax = _vtemp.x * accel + grav.x;
        newPart.ay = _vtemp.y * accel + grav.y;
        newPart.az = _vtemp.z * accel + grav.z;
        newPart.scale  = setting.startSize + setting.startSizeVar*($()-0.5);
        newPart.dscale = setting.endSize   + setting.endSizeVar  *($()-0.5) - newPart.scale;
        newPart.angle  = (setting.angle    + setting.angleVar   *($()-0.5))*22.755555555555556; // 8192/360
        newPart.dangle = (setting.rotation + setting.rotationVar*($()-0.5))*22.755555555555556;
        if ($() < 0.5) newPart.dangle = -newPart.dangle;
        newPart.next = _activeList;
        return _activeList = newPart;
    }
    static public function update(psf:PointSpriteField) : void {
        var p:Particle, prev:Particle, t:Number, ang:int, scl:Number, sin:Number, cos:Number, 
            r:Number, g:Number, b:Number, a:Number, now:uint = getTimer(), dt:Number=(now-_prevTime)*0.001;
        _prevTime = now;
        for (p=_activeList; p;) {
            p.age += dt;
            if (p.age < p.life) {
                t = p.age * p.ilife;
                p.x += (p.vx + p.ax * dt * 0.5) * dt;
                p.y += (p.vy + p.ay * dt * 0.5) * dt;
                p.z += (p.vz + p.az * dt * 0.5) * dt;
                p.vx += p.ax * dt;
                p.vy += p.ay * dt;
                p.vz += p.az * dt;
                ang = (int(p.angle + p.dangle * t))&8191;
                scl = p.scale + p.dscale * t;
                sin = s$[ang];  cos = c$[ang];
                r = p.color.x + p.dcolor.x * t;
                g = p.color.y + p.dcolor.y * t;
                b = p.color.z + p.dcolor.z * t;
                a = p.color.w + p.dcolor.w * t;
                psf.createSprite(p.texture, p.x, p.y, p.z, scl*cos, -scl*sin, scl*sin, scl*cos, r, g, b, a);
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
                for (i=0,j=0; i<imax; j++) { f=faces[j]; idx[i]=f.i0; i++; idx[i]=f.i1; i++; idx[i]=f.i2; i++; }
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
            for (i=0; i<attributeList.length; i++) context3D.setVertexBufferAt(i, null, 0, "float1");
            return this;
        }
        public function clear() : Mesh { for (var i:int=0; i<faces.length; i++) Face.free(faces[i]); faces.length = 0; _indexDirty = true; return this; }
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
        private var _in :Vector.<Number> = new Vector.<Number>(6, true), _out:Vector.<Number> = new Vector.<Number>(6, true);
        private var _lv:Vector.<Number>  = new Vector.<Number>(4, true), _hv:Vector.<Number>  = new Vector.<Number>(4, true);
        private var _mvm:Matrix3D = new Matrix3D(), ZERO_VECTOR:Vector3D = new Vector3D();
        public function get lightVector() : Vector.<Number> { return _lv; }
        public function get halfVector() : Vector.<Number> { return _hv; }
        public function transform(sigl:SiGLCore) : void {
            var ilen:Number = 1/length, hx:Number, hy:Number, hz:Number;
            _mvm.copyFrom(sigl.modelViewMatrix); _mvm.copyRowFrom(3, ZERO_VECTOR); _mvm.invert();
            hx = _in[0] = x * ilen; hy = _in[1] = y * ilen; hz = (_in[2] = z * ilen) + 1;
            ilen = 1 / Math.sqrt(hx * hx + hy * hy + hz * hz);
            _in[3] = hx * ilen; _in[4] = hy * ilen; _in[5] = hz * ilen;
            _mvm.transformVectors(_in, _out);
            _lv[0] = _out[0]; _lv[1] = _out[1]; _lv[2] = _out[2];
            _hv[0] = _out[3]; _hv[1] = _out[4]; _hv[2] = _out[5];
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
                _specMap.setPixel32(i, 0, ((c<256)?c:255)*0x10101);
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

