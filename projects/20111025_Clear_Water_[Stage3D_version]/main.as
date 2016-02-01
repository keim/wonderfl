// forked from keim_at_Si's Clear Water with refraction rendering forked from: 3D水面 / Water 3D
// forked from saharan's 3D水面 / Water 3D
package {
    import flash.system.LoaderContext;
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.text.*;
    import flash.net.*;
    import com.bit101.components.*;
    import net.hires.debug.*;
    
    import com.adobe.utils.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    //import org.si.ptolemy.*;

    public class main extends Sprite {
        private const NUM_DETAILS:int = 48;
        private const INV_NUM_DETAILS:Number = 1 / NUM_DETAILS;
        private const MESH_SIZE:Number = 100;
        private const SURFACE_DETAILS:int = NUM_DETAILS-4;
        private const VCOUNT:int = SURFACE_DETAILS * SURFACE_DETAILS;
        private const VBUFFER_SIZE:int = 9;
        private var count:uint;
        private var bmd:BitmapData, bmd2:BitmapData;
        private var loader:Loader, loader2:Loader;
        private var vertices:Vector.<Number>;
        private var transformedVertices:Vector.<Number>;
        private var indices:Vector.<int>;
        private var uvt:Vector.<Number>, uvt2:Vector.<Number>;
        private var heights:Vector.<Number>;
        private var velocity:Vector.<Number>;
        
/*      // for local
        private var refractionTexture:String = "_env1.png";
        private var reflectionTexture:String = "_env2.png";
/*/     // for wonderfl
        private var refractionTexture:String = "http://assets.wonderfl.net/images/related_images/b/b2/b217/b2177f87d979a28b9bcbb6e0b89370e77ce22337";
        private var reflectionTexture:String = "http://assets.wonderfl.net/images/related_images/b/bb/bbf1/bbf12c60cf84e5ab43e059920783d036da25df48";
//*/
        private var container:Sprite;
        private var viewedAngleH:Number = 0;
        private var viewedAngleV:Number = -20 * 0.017453292519943295;
        private var rotH:Number = 0, rotV:Number = 0;
        private var cameraDistance:Number = MESH_SIZE;
        private var focalLength:Number = MESH_SIZE * 4;
        private var boxHeight:Number = MESH_SIZE*0.75;
        private var refractiveIndex:Number = 1.4;
        private var reflectionRatio:Number = 0.4;
        
        private var cameraPosition:Vector3D = new Vector3D();

        // molehill
        private var ptolemy:TinyPtolemy;
        private var projectionMatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
        private var modelviewMatrix:Matrix3D = new Matrix3D();
        private var matrix3D:Matrix3D = new Matrix3D();
        
        private var vertexBuffer:VertexBuffer3D;
        private var normalBuffer:VertexBuffer3D;
        private var indexBuffer:IndexBuffer3D;
        private var program:Program3D;
        private var tex:Texture, tex2:Texture;
        private var asm:AGALMiniAssembler = new AGALMiniAssembler();
        

        
        
    //-------------------------------------------------- constructor
        function main() : void {
            Wonderfl.disable_capture();
            // create surface
            var i:int, j:int, idx:int;
            vertices = new Vector.<Number>(VCOUNT * VBUFFER_SIZE, true);
            transformedVertices = new Vector.<Number>(VCOUNT * 2, true);
            uvt = new Vector.<Number>(VCOUNT * 2, true);
            uvt2 = new Vector.<Number>(VCOUNT * 2, true);
            for (i = 0; i < VCOUNT; i++) {
                vertices[i*VBUFFER_SIZE]   = ((int(i/SURFACE_DETAILS)+2) * INV_NUM_DETAILS - 0.5) * MESH_SIZE;
                vertices[i*VBUFFER_SIZE+1] = ((int(i%SURFACE_DETAILS)+2) * INV_NUM_DETAILS - 0.5) * MESH_SIZE;
                vertices[i*VBUFFER_SIZE+2] = 0;
            }
            indices = new Vector.<int>();
            for (i=1; i<SURFACE_DETAILS; i++) for (j=1; j<SURFACE_DETAILS; j++) {
                idx = j * SURFACE_DETAILS + i;
                indices.push(idx-SURFACE_DETAILS-1, idx-SURFACE_DETAILS, idx, 
                             idx-SURFACE_DETAILS-1, idx, idx-1);
            }
            
            // create field
            heights = new Vector.<Number>(NUM_DETAILS * NUM_DETAILS, true);
            velocity = new Vector.<Number>(NUM_DETAILS * NUM_DETAILS, true);
            for (i = 0; i < NUM_DETAILS * NUM_DETAILS; i++) velocity[i] = heights[i] = 0;
            
            addEventListener(Event.ADDED_TO_STAGE, setup);
        }

        private function setup(e:Event) : void {
            e.target.removeEventListener(e.type, arguments.callee);
            // load resource
            ptolemy = new TinyPtolemy(this, 8, 8, 450, 450);
            ptolemy.addEventListener(Event.CONTEXT3D_CREATE, loaded);
            loader = new Loader();
            loader.load(new URLRequest(refractionTexture), new LoaderContext(true));
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaded);
            loader2 = new Loader();
            loader2.load(new URLRequest(reflectionTexture), new LoaderContext(true));
            loader2.contentLoaderInfo.addEventListener(Event.COMPLETE, loaded);
        }
        
        private function loaded(e:Event) : void {
            e.target.removeEventListener(e.type, arguments.callee);
            if (loader.content && loader2.content && ptolemy.context3D) {
                bmd  = Bitmap(loader.content).bitmapData;
                bmd2 = Bitmap(loader2.content).bitmapData;
                
                // setup buffers
                var uindices:Vector.<uint> = new Vector.<uint>(indices.length, true);
                for (var i:int=0; i<uindices.length; i++) uindices[i] = indices[i];
                vertexBuffer = ptolemy.context3D.createVertexBuffer(VCOUNT, VBUFFER_SIZE);
                indexBuffer = ptolemy.context3D.createIndexBuffer(uindices.length);
                indexBuffer.uploadFromVector(uindices, 0, uindices.length);
                program = ptolemy.context3D.createProgram();
                program.upload(asm.assemble("vertex", vs), asm.assemble("fragment", fs));
                
                // setup textures
                tex = ptolemy.context3D.createTexture(512, 512, "bgra", false);
                tex.uploadFromBitmapData(bmd);

                tex2 = ptolemy.context3D.createTexture(512, 512, "bgra", false);
                tex2.uploadFromBitmapData(bmd2);

                
                projectionMatrix.perspectiveFieldOfViewLH(60/180*3.141592653589793, 1, 1, 200);
                
                addChild(container = new Sprite());
                container.x = container.y = 8;
                container.graphics.beginFill(0);
                container.graphics.drawRect(0,0,180,78);
                container.graphics.endFill();
                new HUISlider(container, 0,  0, "Angle", function(e:Event):void { viewedAngleV = -e.target.value*0.017453292519943295;}).setSliderParams(0, 80, 20);
                new HUISlider(container, 0, 20, "Rotation", function(e:Event):void { viewedAngleH = -e.target.value*0.017453292519943295;}).setSliderParams(-180, 180, 0);
                new HUISlider(container, 0, 40, "Refraction", function(e:Event):void { refractiveIndex = e.target.value;}).setSliderParams(1, 3, 1.4);
                new HUISlider(container, 0, 60, "Reflection", function(e:Event):void { reflectionRatio = e.target.value;}).setSliderParams(0, 1, 0.4);
                var driverInfo:TextField = new TextField();
                driverInfo.textColor = 0xffffff;
                driverInfo.width = 450;
                driverInfo.y = 435;
                driverInfo.text = ptolemy.context3D.driverInfo;
                container.addChild(driverInfo);
                addAllEventListeners();
            }
        }
        
        private function addAllEventListeners() : void {
            // add all listeners     
            stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
            addEventListener(Event.ENTER_FRAME, frame);
            count = 0;
        }
        
    //-------------------------------------------------- events
        private function mouseDown(e:MouseEvent) : void {
            stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseDrag);
            ripple((232.5 - mouseY) / 465, (mouseX -232.5) / 465, 20);
        }
        
        private function mouseUp(e:MouseEvent) : void {
            stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseDrag);
        }
        
        private function mouseDrag(e:MouseEvent) : void {
            ripple((232.5 - mouseY) / 465, (mouseX -232.5) / 465, 3);
        }
        
        private function ripple(mx:Number, my:Number, intensity:Number) : void {
            var i:int, j:int, idx:int, dx:Number, dy:Number, acc:Number, imin:int, jmin:int, imax:int, jmax:int,
                sin:Number = Math.sin(viewedAngleH), cos:Number = Math.cos(viewedAngleH);
            dx =  mx * cos + my * sin;
            dy = -mx * sin + my * cos;
            mx = (dx + 0.5) * NUM_DETAILS;
            my = (dy + 0.5) * NUM_DETAILS;
            imin = (mx > 5) ? int(mx - 3) : 2;
            jmin = (my > 5) ? int(my - 3) : 2;
            imax = (mx < NUM_DETAILS-5) ? int(mx + 4) : (NUM_DETAILS - 1);
            jmax = (my < NUM_DETAILS-5) ? int(my + 4) : (NUM_DETAILS - 1);
            for (i=imin; i<imax; i++) for (j=jmin; j<jmax; j++) {
                dx = mx - i;
                dy = my - j;
                acc = 3 - Math.sqrt(dx * dx + dy * dy);
                if (acc > 0) velocity[j*NUM_DETAILS+i] += acc*intensity;
            }
        }
        
    //-------------------------------------------------- on each frame
        private function frame(e:Event = null):void {
            count++;
            move();
            setMesh();
            molehill_draw();
        }

        private function move():void {
            // ---Water simulation---
            var i:int, j:int, idx:int, v:Number, imax:int, jmax:int;
            imax = jmax = NUM_DETAILS - 1;
            for (i=1; i<imax; i++) for (j=1; j<jmax; j++) {
                idx = j * NUM_DETAILS + i;
                heights[idx] += velocity[idx];
                if (heights[idx] > 100) heights[idx] = 100;
                else if (heights[idx] < -100) heights[idx] = -100;
            }
            for (i=1; i<imax; i++) for (j=1; j<jmax; j++) {
                idx = j * NUM_DETAILS + i;
                v = -heights[idx] * 4; idx-=NUM_DETAILS;
                v += heights[idx];     idx+=NUM_DETAILS-1;
                v += heights[idx];     idx+=2;
                v += heights[idx];     idx+=NUM_DETAILS-1;
                v += heights[idx];     idx-=NUM_DETAILS;
                velocity[idx] = (velocity[idx] + v * 0.5) * 0.9;
            }
            
            // change view
            /*
            var targetAngleH:Number = (mouseX -232.5) / 465 * 40 * 0.017453292519943295,
                targetAngleV:Number = -((mouseY -232.5) / 465 * 40 + 40) * 0.017453292519943295;
            rotH += (targetAngleH - viewedAngleH) * 0.01;
            rotV += (targetAngleV - viewedAngleV) * 0.01;
            viewedAngleH += (rotH *= 0.9);
            viewedAngleV += (rotV *= 0.9);
            */
            modelviewMatrix.identity();
            modelviewMatrix.prependTranslation(0, 0, cameraDistance);
            modelviewMatrix.prependRotation(-viewedAngleV*57.29577951308232, Vector3D.X_AXIS);
            modelviewMatrix.prependRotation(-viewedAngleH*57.29577951308232, Vector3D.Z_AXIS);
            _invmat.copyFrom(modelviewMatrix);
            _invmat.invert();
            _invmat.copyColumnTo(3, cameraPosition);
        }
        private var _invmat:Matrix3D = new Matrix3D();

        private function setMesh():void {
            var i:int, j:int, index:int, len:Number, u:Number, v:Number,
                t:Number, s:Number, r:Number, hitz:Number, sign:Number,
                vx:Number, vy:Number, vz:Number, 
                nx:Number, ny:Number, nz:Number, 
                dx:Number, dy:Number, dz:Number, 
                rimo:Number = refractiveIndex - 1,
                xymax:Number = MESH_SIZE * 0.45, //MESH_SIZE * 0.5,
                ixymax:Number = 1 / xymax;
            
            for (i = 0; i < SURFACE_DETAILS; i++) {
                for (j = 0; j < SURFACE_DETAILS; j++) {
                    index = (j * SURFACE_DETAILS + i) * VBUFFER_SIZE;
                    len = heights[(j+2)*NUM_DETAILS+i+2];
                    vx = vertices[index]; index++;
                    vy = vertices[index]; index++;
                    vz = vertices[index] = len * 0.25; index++;
                    
                    // Sphere map
                    nx = (len - heights[(j+2)*NUM_DETAILS+i+1]) * 0.25;
                    ny = (len - heights[(j+1)*NUM_DETAILS+i+2]) * 0.25;
                    nz = 1 / Math.sqrt(nx * nx + ny * ny + 1);
                    nx *= nz;
                    ny *= nz;
                    
                    // Refraction map
                    // incident vector (you can calculate them in the setup if you want faster)
                    dx = vx - cameraPosition.x;
                    dy = vy - cameraPosition.y;
                    dz = vz - cameraPosition.z;
                    len = 1 / Math.sqrt(dx * dx + dy * dy + dz * dz);
                    dx *= len;
                    dy *= len;
                    dz *= len;
                    // output vector
                    t = (dx * nx + dy * ny + dz) * rimo;
                    dx += nx * t;
                    dy += ny * t;
                    dz += nz * t;
                    // uv coordinate
                    if (dx == 0) {
                        if (dy == 0) {
                            u = v = 0.5;
                            sign = 0;
                        } else sign = (dy < 0) ? -1 : 1;
                    } else {
                        sign = (dx < 0) ? -1 : 1;
                        t = (sign * xymax - vx) / dx;
                        s = t * dy + vy;
                        if (-xymax < s && s < xymax) {
                            hitz = t * dz + vz;
                            if (hitz > boxHeight) {
                                r = (boxHeight-vz) / dz;
                                u = (dx * r + vx) * ixymax * 0.25 + 0.5;
                                v = (dy * r + vy) * ixymax * 0.25 + 0.5;
                            } else {
                                r = boxHeight / (hitz + boxHeight);
                                u = sign       * r * 0.5 + 0.5;
                                v = s * ixymax * r * 0.5 + 0.5;
                            }
                            sign = 0;
                        } else sign = (dy < 0) ? -1 : 1;
                    }
                    if (sign != 0) {
                        t = (sign * xymax - vy) / dy;
                        s = t * dx + vx;
                        hitz = t * dz + vz;
                        if (hitz > boxHeight) {
                            r = (boxHeight-vz) / dz;
                            u = (dx * r + vx) * ixymax * 0.25 + 0.5;
                            v = (dy * r + vy) * ixymax * 0.25 + 0.5;
                        } else {
                            r = boxHeight / (hitz + boxHeight);
                            u = s * ixymax * r * 0.5 + 0.5;
                            v = sign       * r * 0.5 + 0.5;
                        }
                    }
                    // set vertices
                    vertices[index] = nx * 0.5 + 0.5 + ((i - NUM_DETAILS * 0.5) * INV_NUM_DETAILS * 0.25); index++;
                    vertices[index] = ny * 0.5 + 0.5 + ((NUM_DETAILS * 0.5 - j) * INV_NUM_DETAILS * 0.25); index++;
                    vertices[index] = u; index++;
                    vertices[index] = v;
                }
            }
        }
        
        
        private function molehill_draw() : void {
            var context3D:Context3D = ptolemy.context3D;
            context3D.clear(0.2, 0.2, 0.2, 1);
            matrix3D.copyFrom(projectionMatrix);
            matrix3D.prepend(modelviewMatrix);
            
            vertexBuffer.uploadFromVector(vertices, 0, VCOUNT);
            context3D.setDepthTest(true, "less");
            context3D.setProgram(program);
            context3D.setTextureAt(0, tex);
            context3D.setTextureAt(1, tex2);
            context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
            context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setVertexBufferAt(2, vertexBuffer, 5, Context3DVertexBufferFormat.FLOAT_2);
            context3D.setProgramConstantsFromMatrix("vertex", 0, matrix3D, true);
            context3D.setProgramConstantsFromVector("vertex", 9, Vector.<Number>([0,0.5,1,2]));
            context3D.setProgramConstantsFromVector("fragment", 0, Vector.<Number>([reflectionRatio,1-reflectionRatio,0,1]));
            context3D.drawTriangles(indexBuffer, 0, indices.length/3);
            
            context3D.present();
        }
    }
}

var vs:String = <agalCode><![CDATA[
mov vt0.xyz, va0.xyz
mov vt0.w, vc9.z
m44 op, vt0, vc0
mov v0, va1
mov v1, va2
]]></agalCode>;

var fs:String = <agalCode><![CDATA[
tex ft0, v0.xy, fs0 <2d,clamp,nearest>
tex ft1, v1.xy, fs1 <2d,clamp,nearest>
mul ft0, ft0, fc0.x
mul ft1, ft1, fc0.y
add oc, ft0, ft1
]]></agalCode>;




import flash.events.*;
import flash.display.*;
import flash.display3D.*;

class TinyPtolemy extends EventDispatcher {
    public var context3D:Context3D;
    
    function TinyPtolemy(parent:DisplayObjectContainer, xpos:Number, ypos:Number ,width:int, height:int) : void {
        var stage:Stage = parent.stage, stage3D:Stage3D = stage.stage3Ds[0];
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.quality = StageQuality.LOW;
        stage3D.x = xpos;
        stage3D.y = ypos;
        stage3D.addEventListener(Event.CONTEXT3D_CREATE, function(e:Event):void{
            context3D = e.target.context3D;
            if (context3D) {
                context3D.enableErrorChecking = false;                  // check internal error
                context3D.configureBackBuffer(width, height, 0, true);  // disable AA/ enable depth/stencil
                context3D.setRenderToBackBuffer();
                context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
                context3D.setCulling(Context3DTriangleFace.BACK);         // culling back face
                dispatchEvent(e.clone());
            } else {
                dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Context3D not found"));
            }
        });
        stage3D.requestContext3D();
    }
}


