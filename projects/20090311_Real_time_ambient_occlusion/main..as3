// gouraud shading based ambient occlusion (PoC)
//   mouse move to move camera, mouse click to stop motion
//   press z key to switch ambient occlusion
//----------------------------------------------------------------------
package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;

    [SWF(width='465', height='465', backgroundColor='#000000', frameRate='60')]
    public class main extends Sprite {
        // settings
        private const aoBlendRatio:Number = 0.6; // blending ratio of a.o.
        private const aoRadius:Number = 8;       // pseudo radius for a.o. calculation
        private const divPlane:int = 16;         // partition number of plane
        private const divSphere:int = 24;        // partition number of sphere
        private const hcResolution:int = 3;      // log2 based hemi-cube resolusion 
        
        // 3D renders
        private var _materials:Vector.<Material> = new Vector.<Material>();
        private var _light:Light = new Light(1,1,1);
        private var _meshSphere:Mesh = new Mesh(_materials);

        private var _meshPlane :Mesh = new Mesh(_materials);

        private var _screen:BitmapData = new BitmapData(465, 465, false, 0);
        private var _matscr:Matrix = new Matrix(1, 0, 0, 1, 232.5, 232.5);
        private var gl:Render3D = new Render3D(250);
        // utils
        private var _timer:timer = new timer(10, "Total: ##[ms/frame]", "AO calc: ##[ms/frame]",  "Rendering: ##[ms/frame]");
        
        // objects
        private var camera:Vector3D;
        private var plane:AOPrimitive;
        private var spheres:Vector.<AOPrimitive> = new Vector.<AOPrimitive>(3);
        private var aoShade:Vector.<AOPrimitive> = new Vector.<AOPrimitive>(3);
        private var spheresProjected:Vector.<Point3D> = new Vector.<Point3D>(3);
        private var aoShadeProjected:Vector.<Point3D> = new Vector.<Point3D>(3);
        
        // motions
        private var motionRadius:Vector.<Number> = Vector.<Number>([  10,  -20,   32]);
        private var motionFreq  :Vector.<Number> = Vector.<Number>([0.20, 0.07,-0.12]);
        private var motionFreqY :Vector.<Number> = Vector.<Number>([0.12, 0.25, 0.05]);
        private var vertexCount:int;
        private var frame:int = 0;
        private var frameStep:int = 1;
        private var aoSwitch:Boolean = true;
        
        // entry point
        function main() {
            var sphereVerticesCount:int = ((divSphere>>1)-1)*divSphere+2,
                planeVerticesCount:int  = (divPlane+1)*(divPlane+1);
            vertexCount = planeVerticesCount + sphereVerticesCount*3;
            _timer.title = "Vertices: " + String(vertexCount) + "\n";
            
            camera = new Vector3D(0, -5, -50);
            plane  = new AOPrimitive(0, 0, 0, 0, planeVerticesCount);
            spheresProjected[0] = spheres[0] = new AOPrimitive(0, 5, 0, aoRadius, sphereVerticesCount);
            spheresProjected[1] = spheres[1] = new AOPrimitive(0, 5, 0, aoRadius, sphereVerticesCount);
            spheresProjected[2] = spheres[2] = new AOPrimitive(0, 5, 0, aoRadius, sphereVerticesCount);
            aoShadeProjected[0] = aoShade[0] = new AOPrimitive(0,-6, 0, aoRadius);
            aoShadeProjected[1] = aoShade[1] = new AOPrimitive(0,-6, 0, aoRadius);
            aoShadeProjected[2] = aoShade[2] = new AOPrimitive(0,-6, 0, aoRadius);
            plane.aoPrimitives.push(spheres[0], spheres[1], spheres[2]);
            spheres[0].aoPrimitives.push(aoShade[0], spheres[1], spheres[2]);
            spheres[1].aoPrimitives.push(spheres[0], aoShade[1], spheres[2]);
            spheres[2].aoPrimitives.push(spheres[0], spheres[1], aoShade[2]);

            _materials.push((new Material()).setColor(0xffffff, 0, 128, 32, 80));
            _createSphere(_meshSphere, 5, divSphere>>1, divSphere);
            _createPlane(_meshPlane, 80, 80, divPlane, divPlane);
            
            addChild(gl).visible = false;
            addChild(new Bitmap(_screen));
            addChild(_timer);
            addEventListener("enterFrame", _onEnterFrame);
            stage.addEventListener("click", _onClick);
            stage.addEventListener("keyUp", _onKeyUp);
        }

        private function _onEnterFrame(e:Event) : void {
            // motion
            for (var i:int=0; i<3; i++) {
                spheres[i].x = Math.cos(frame*motionFreq[i]) * motionRadius[i];
                spheres[i].y = Math.sin(frame*motionFreqY[i]) * 5 + 10;
                spheres[i].z = Math.sin(frame*motionFreq[i]) * motionRadius[i];
                aoShade[i].x = spheres[i].x;
                aoShade[i].y = -5;
                aoShade[i].z = spheres[i].z;
            }
            
            _timer.start(0);
            // clear screen
            _screen.fillRect(_screen.rect, 0);
            // camera
            gl.id().tv(camera).rx((400-mouseY)*0.15).ry((232-mouseX)*0.5);
            _light.transformBy(gl.matrix);
            // project all primitives
            gl.projectPoint3D(spheresProjected);
            gl.projectPoint3D(aoShadeProjected);
            spheresProjected.sort(function(v1:Point3D, v2:Point3D) : Number { return v1.world.z - v2.world.z; });
            // plane
            gl.push().tv(plane).project(_meshPlane);
            calculateVertexNormal(_meshPlane);
            if (frameStep) calculateAmbientOcclusion(_meshPlane, plane.aoPrimitives, plane.ao);
            calculateTexCoordByVertexNormal(_meshPlane, _light, plane.ao);
            _timer.start(2); 
            _screen.draw(gl.renderTexture(_materials[0]), _matscr);
            _timer.pause(2);
            gl.pop();
            // spheres
            for each (var v:Point3D in spheresProjected) {
                var p:AOPrimitive = AOPrimitive(v);
                gl.push().tv(p).project(_meshSphere);
                calculateVertexNormal(_meshSphere);
                if (frameStep) calculateAmbientOcclusion(_meshSphere, p.aoPrimitives, p.ao);
                calculateTexCoordByVertexNormal(_meshSphere, _light, p.ao);
                _timer.start(2);
                _screen.draw(gl.renderTexture(_materials[0]), _matscr);
                _timer.pause(2);
                gl.pop();
            }
            _timer.pause(0);
            
            frame += frameStep;
        }
        
        private function _onClick(e:Event) : void {
            frameStep = 1 - frameStep;
        }
        
        private function _onKeyUp(e:KeyboardEvent) : void {
            var inkey:String = String.fromCharCode(e.keyCode);
            if (inkey == "Z") aoSwitch = !aoSwitch;
        }
        
        private function _createSphere(mesh:Mesh, radius:Number, dlat:int, dlong:int) : Mesh {
            var ilat:int, ilong:int, lat:Number, long:Number, r:Number, vidx:int, 
            slat:Number = 3.141592653589793/dlat, slong:Number  = 6.283185307179586/dlong;
            mesh.vertices.push(0, radius, 0);
            mesh.texCoord.push(0, 0, 0);
            for (ilat=1, lat=slat; ilat<dlat; ilat++, lat+=slat) {
                r = Math.sin(lat) * radius;
                for (ilong=0, long=-ilat*slong*0.5; ilong<dlong; ilong++, long+=slong) {
                    mesh.vertices.push(Math.cos(long) * r, Math.cos(lat) * radius, Math.sin(long) * r);
                    mesh.texCoord.push(0, 0, 0);
                }
            }
            mesh.vertices.push(0, -radius, 0);
            mesh.texCoord.push(0, 0, 0);
            for (ilat=0; ilat<dlat-2; ilat++) {
                vidx = ilat * dlong + 1;
                for (ilong=1; ilong<dlong; ilong++, vidx++) {
                    mesh.qface(vidx+1, vidx, vidx+dlong+1, vidx+dlong, 0, true);
                }
                mesh.qface(vidx-dlong+1, vidx, vidx+1, vidx+dlong, 0, true);
            }
            vidx = dlong * (dlat-1) + 1;
            for (ilong=0; ilong<dlong-1; ilong++) {
                mesh.face(0, ilong+1, ilong+2, 0);
                mesh.face(vidx, vidx-(ilong+1), vidx-(ilong+2), 0);
            }
            mesh.face(0, ilong+1, 1, 0);
            mesh.face(vidx, vidx-(ilong+1), vidx-1, 0);
            mesh.updateFaces();
            
            mesh.vnormals = new Vector.<Vector3D>(mesh.verticesCount, true);
            for (var i:int=0; i<mesh.verticesCount; i++) mesh.vnormals[i] = new Vector3D();
            return mesh;
        }
        
        private function _createPlane(mesh:Mesh, w:Number, h:Number, divx:int, divy:int) : Mesh {
            var x:Number, y:Number, ix:int, iy:int, i:int, j:int, 
                hw:Number=w*0.5, hh:Number=h*0.5, dx:Number=1/divx, dy:Number=1/divy;
            for (y=0, iy=0; iy<=divy; y+=dy, iy++) {
                for (x=0, ix=0; ix<=divx; x+=dx, ix++) {
                    mesh.vertices.push(x*w-hw, 0, y*h-hh);
                    mesh.texCoord.push(x, y, 0);
                }
            }
            for (iy=0; iy<divy; iy++) {
                for (ix=0; ix<divx; ix++) {
                    i = iy*(divy+1)+ix;
                    j = i + divy+1;
                    mesh.qface(i, i+1, j, j+1, 0, true);
                }
            }
            mesh.updateFaces();
            
            mesh.vnormals = new Vector.<Vector3D>(mesh.verticesCount, true);
            for (i=0; i<mesh.verticesCount; i++) mesh.vnormals[i] = new Vector3D();
            return mesh;
        }
        
        public function calculateVertexNormal(mesh:Mesh) : void {
            var i:int, v:Vector3D, fn:Vector3D, n:Number, vnormals:Vector.<Vector3D>=mesh.vnormals;
            for each (v in vnormals) {
                v.x = v.y = v.z = v.w = 0;
            }
            for each (var face:Face in mesh.faces) {
                fn = face.normal.world;
                v = vnormals[face.i0]; v.x += fn.x; v.y += fn.y; v.z += fn.z; v.w += 1;
                v = vnormals[face.i1]; v.x += fn.x; v.y += fn.y; v.z += fn.z; v.w += 1;
                v = vnormals[face.i2]; v.x += fn.x; v.y += fn.y; v.z += fn.z; v.w += 1;
            }
            for each (v in vnormals) {
                if (v.w == 0) continue;
                n = 1/v.w;
                v.x *= n;
                v.y *= n;
                v.z *= n;
            }
            mesh.vnormals = vnormals;
        }
        
        private const bmdw:int = 1<<hcResolution;
        private var v0:Vector3D = new Vector3D(), v1:Vector3D = new Vector3D(), v:Vector3D = new Vector3D();
        private var hc0:BitmapData = new BitmapData(bmdw,bmdw,false);
        private var hcx:Vector.<BitmapData> = Vector.<BitmapData>([
            new BitmapData(bmdw, bmdw>>1, false), 
            new BitmapData(bmdw, bmdw>>1, false)
        ]);
        private var hcy:Vector.<BitmapData> = Vector.<BitmapData>([
            new BitmapData(bmdw, bmdw>>1, false), 
            new BitmapData(bmdw, bmdw>>1, false)
        ]);
        private var rect:Rectangle = new Rectangle();
        public function calculateAmbientOcclusion(mesh:Mesh, prims:Vector.<AOPrimitive>, aoBuffer:Vector.<Number>) : void {
            var x:Number, y:Number, z:Number, w:Number, t:Number, v2:Vector3D, p:AOPrimitive, 
                i:int=0, j:int=0, k:int, hci:int, ao:int, ix:int, iy:int, 
                hhc:int = bmdw>>1, hc0s:int = bmdw*bmdw, hcxs:int = hc0s>>1, hcxf:int = bmdw-1, 
                vnormals:Vector.<Vector3D> = mesh.vnormals, 
                vertices:Vector.<Number> = mesh.verticesOnWorld;
            _timer.start(1);
            for each (v2 in vnormals) {
                v1.x = 0.0;
                v1.y = 0.0;
                v1.z = 0.0;
                     if ((v2.y < 0.6) && (v2.y > -0.6)) v1.y = -1.0;
                else if ((v2.z < 0.6) && (v2.z > -0.6)) v1.z = 1.0;
                else v1.x = 1.0;
                v0.x = v1.y * v2.z - v1.z * v2.y;
                v0.y = v1.z * v2.x - v1.x * v2.z;
                v0.z = v1.x * v2.y - v1.y * v2.x;
                v0.normalize();
                v1.x = v2.y * v0.z - v2.z * v0.y;
                v1.y = v2.z * v0.x - v2.x * v0.z;
                v1.z = v2.x * v0.y - v2.y * v0.x;
                v1.normalize();
                // render on hemi-cubes
                hc0.fillRect(hc0.rect, 1);
                hcx[0].fillRect(hcx[0].rect, 1);
                hcx[1].fillRect(hcx[1].rect, 1);
                hcy[0].fillRect(hcy[0].rect, 1);
                hcy[1].fillRect(hcy[1].rect, 1);
                for each (p in prims) {
                    x = p.world.x - vertices[i];
                    y = p.world.y - vertices[i+1];
                    z = p.world.z - vertices[i+2];
                    v.x = x * v0.x + y * v0.y + z * v0.z;
                    v.y = x * v1.x + y * v1.y + z * v1.z;
                    v.z = x * v2.x + y * v2.y + z * v2.z;
                    // hemi-cube front
                    if (v.z > 0) {
                        t = hhc/v.z;
                        w = p.aoRadius * 0.8 * t;
                        rect.x = v.x * t - w + hhc;
                        rect.y = v.y * t - w + hhc;
                        rect.width = w + w;
                        rect.height = w + w;
                        hc0.fillRect(rect, 0);
                    }
                    // hemi-cube x direction
                    if (v.x != 0) {
                        if (v.x > 0) { hci = 0; t =  hhc/v.x; }
                        else         { hci = 1; t = -hhc/v.x; }
                        w = p.aoRadius * 0.65 * t;
                        rect.x = v.y * t - w + hhc;
                        rect.y = v.z * t - w;
                        rect.width = w + w;
                        rect.height = w + w;
                        hcx[hci].fillRect(rect, 0);
                    }
                    // hemi-cube y direction
                    if (v.y != 0) {
                        if (v.y > 0) { hci = 0; t =  hhc/v.y; }
                        else         { hci = 1; t = -hhc/v.y; }
                        w = p.aoRadius * 0.65 * t;
                        rect.x = v.x * t - w + hhc;
                        rect.y = v.z * t - w;
                        rect.width = w + w;
                        rect.height = w + w;
                        hcy[hci].fillRect(rect, 0);
                    }
                }
                ao = 0;
                for (k=0; k<hc0s; k++) {
                    ao += hc0.getPixel(k&hcxf, k>>hcResolution);
                }
                for (k=0; k<hcxs; k++) {
                    ix = k & hcxf;
                    iy = k >> hcResolution;
                    ao += hcx[0].getPixel(ix, iy) + hcx[1].getPixel(ix, iy) +
                          hcy[0].getPixel(ix, iy) + hcy[1].getPixel(ix, iy);
                }
                aoBuffer[j] = ao * 0.005208333333333333;
                i+=3;
                j++;
            }
            _timer.pause(1);
        }
        
        public function calculateTexCoordByVertexNormal(mesh:Mesh, light:Light, aoBuffer:Vector.<Number>) : void {
            var x:Number, y:Number, v:Vector3D, i:int=0, j:int=0, vnormals:Vector.<Vector3D>=mesh.vnormals,
                dir:Vector3D=light, hv:Vector3D=light.halfVector, 
                t:Number = aoBlendRatio, it:Number = 1-aoBlendRatio, offset:Number = 0;
            if (!aoSwitch) {
                t = 0;
                offset = aoBlendRatio*0.8;
                it = 1-offset;
            }
            for each (v in vnormals) {
                x = dir.x * v.x + dir.y * v.y + dir.z * v.z;
                y = hv.x  * v.x + hv.y  * v.y + hv.z  * v.z;
                if (x<0) x = 0;
                if (y<0) y = 0;
                mesh.texCoord[i] = x*it + aoBuffer[j]*t + offset; i++; j++;
                mesh.texCoord[i] = y; i+=2;
            }
        }
    }
}

import flash.display.*;
import flash.text.*;
import flash.geom.*;
import flash.events.*;

import flash.utils.getTimer;

class timer extends TextField {
    public var title:String = "";
    private var _time:Vector.<int>;
    private var _sum :Vector.<int>;
    private var _stat:Vector.<String>;
    private var _cnt :int;
    private var _avc:int;
    function timer(averagingCount:int, ...stat) : void {
        _avc  = averagingCount;
        _stat = Vector.<String>(stat);
        _time = new Vector.<int>(stat.length, true);
        _sum  = new Vector.<int>(stat.length, true);
        _cnt  = new Vector.<int>(stat.length, true);
        background = true;
        backgroundColor = 0x00ff00;
        autoSize = "left";
        multiline = true;
        addEventListener("enterFrame", _onEnterFrame);
    }
    public function start(slot:int=0) : void { _time[slot] = getTimer(); }
    public function pause(slot:int=0) : void { _sum[slot] += getTimer() - _time[slot]; }
    public function _onEnterFrame(e:Event) : void {
        if (++_cnt == _avc) {
            _cnt = 0;
            var str:String = "", line:String;
            for (var slot:int = 0; slot<_sum.length; slot++) {
                line = _stat[slot].replace("##", String(_sum[slot] / _avc));
                str += line + "\n";
                _sum[slot] = 0;
            }
            text = title + str;
        }
    }
}


// 3D Engine
//----------------------------------------------------------------------------------------------------
/** Core */
class Render3D extends Shape {
    /** model view matrix */
    public var matrix:Matrix3D;
    private var _meshProjected:Mesh = null;                              // projecting mesh
    private var _facesProjected:Vector.<Face> = new Vector.<Face>();     // projecting face
    private var _projectionMatrix:Matrix3D;                              // projection matrix
    private var _matrixStac:Vector.<Matrix3D> = new Vector.<Matrix3D>(); // matrix stac
    private var _cmdTriangle:Vector.<int> = Vector.<int>([1,2,2]);       // commands to draw triangle
    private var _cmdQuadrangle:Vector.<int> = Vector.<int>([1,2,2,2]);   // commands to draw quadrangle
    private var _data:Vector.<Number> = new Vector.<Number>(8, true);    // data to draw shape
    private var _clippingZ:Number;                                       // z value of clipping plane
    
    /** constructor */
    function Render3D(focus:Number=300, clippingZ:Number=0) {
        var projector:PerspectiveProjection = new PerspectiveProjection()
        projector.focalLength = focus;
        _projectionMatrix = projector.toMatrix3D();
        _clippingZ = -clippingZ;
        matrix = new Matrix3D();
        _matrixStac.length = 1;
        _matrixStac[0] = matrix;
    }

    // control matrix
    //--------------------------------------------------
    public function clear() : Render3D { matrix = _matrixStac[0]; _matrixStac.length = 1; return this; }
    public function push() : Render3D { _matrixStac.push(matrix.clone()); return this; }
    public function pop() : Render3D { matrix = (_matrixStac.length == 1) ? matrix : _matrixStac.pop(); return this; }
    public function id() : Render3D { matrix.identity(); return this; }
    public function t(x:Number, y:Number, z:Number) : Render3D { matrix.prependTranslation(x, y, z); return this; }
    public function tv(v:Vector3D) : Render3D { matrix.prependTranslation(v.x, v.y, v.z); return this; }
    public function s(x:Number, y:Number, z:Number) : Render3D { matrix.prependScale(x, y, z); return this; }
    public function sv(v:Vector3D) : Render3D { matrix.prependScale(v.x, v.y, v.z); return this; }
    public function r(angle:Number, axis:Vector3D) : Render3D { matrix.prependRotation(angle, axis); return this; }
    public function rv(v:Vector3D) : Render3D { matrix.prependRotation(v.w, v); return this; }
    public function rx(angle:Number) : Render3D { matrix.prependRotation(angle, Vector3D.X_AXIS); return this; }
    public function ry(angle:Number) : Render3D { matrix.prependRotation(angle, Vector3D.Y_AXIS); return this; }
    public function rz(angle:Number) : Render3D { matrix.prependRotation(angle, Vector3D.Z_AXIS); return this; }
    
    // projections
    //--------------------------------------------------
    /** project */
    public function project(mesh:Mesh) : Render3D {
        matrix.transformVectors(mesh.vertices, mesh.verticesOnWorld);
        var fn:Point3D, vs:Vector.<Number> = mesh.verticesOnWorld;
        var m:Vector.<Number> = matrix.rawData, 
            m00:Number = m[0], m01:Number = m[1], m02:Number = m[2], 
            m10:Number = m[4], m11:Number = m[5], m12:Number = m[6], 
            m20:Number = m[8], m21:Number = m[9], m22:Number = m[10];
        _facesProjected.length = 0;
        for each (var f:Face in mesh.faces) {
            var i0:int=(f.i0<<1)+f.i0, i1:int=(f.i1<<1)+f.i1, i2:int=(f.i2<<1)+f.i2,
                x0:Number=vs[i0++], x1:Number=vs[i1++], x2:Number=vs[i2++],
                y0:Number=vs[i0++], y1:Number=vs[i1++], y2:Number=vs[i2++],
                z0:Number=vs[i0],   z1:Number=vs[i1],   z2:Number=vs[i2];
            if (z0<_clippingZ && z1<_clippingZ && z2<_clippingZ) {
                fn = f.normal;
                fn.world.x = fn.x * m00 + fn.y * m10 + fn.z * m20;
                fn.world.y = fn.x * m01 + fn.y * m11 + fn.z * m21;
                fn.world.z = fn.x * m02 + fn.y * m12 + fn.z * m22;
                if (vs[f.pvi-2]*fn.world.x + vs[f.pvi-1]*fn.world.y + vs[f.pvi]*fn.world.z <= 0) {
                    _facesProjected.push(f);
                }
            }
        }
        _facesProjected.sort(function(f1:Face, f2:Face):Number{ return vs[f2.pvi] - vs[f1.pvi]; });
        _meshProjected = mesh;
        return this;
    }
    
    /** project slower than transformVectors() but Vector3D.w considerable. */
    public function projectPoint3D(points:Vector.<Point3D>) : Render3D {
        var m:Vector.<Number> = matrix.rawData, p:Point3D, 
            m00:Number = m[0],  m01:Number = m[1],  m02:Number = m[2], 
            m10:Number = m[4],  m11:Number = m[5],  m12:Number = m[6], 
            m20:Number = m[8],  m21:Number = m[9],  m22:Number = m[10], 
            m30:Number = m[12], m31:Number = m[13], m32:Number = m[14];
        for each (p in points) {
            p.world.x = p.x * m00 + p.y * m10 + p.z * m20 + p.w * m30;
            p.world.y = p.x * m01 + p.y * m11 + p.z * m21 + p.w * m31;
            p.world.z = p.x * m02 + p.y * m12 + p.z * m22 + p.w * m32;
        }
        return this;
    }

    // rendering
    //--------------------------------------------------
    /** render solid */
    public function renderSolid(light:Light) : Render3D {
        var idx:int, mat:Material, materials:Vector.<Material> = _meshProjected.materials,
            vout:Vector.<Number> = _meshProjected.verticesOnScreen;
        Utils3D.projectVectors(_projectionMatrix, _meshProjected.verticesOnWorld, vout, _meshProjected.texCoord);
        graphics.clear();
        for each (var face:Face in _facesProjected) {
            mat = materials[face.mat];
            graphics.beginFill(mat.getColor(light, face.normal.world), mat.alpha);
            idx = face.i0<<1;
            _data[0] = vout[idx]; idx++;
            _data[1] = vout[idx];
            idx = face.i1<<1;
            _data[2] = vout[idx]; idx++;
            _data[3] = vout[idx];
            idx = face.i2<<1;
            _data[4] = vout[idx]; idx++;
            _data[5] = vout[idx];
            if (face.i3 == -1) {
                graphics.drawPath(_cmdTriangle, _data);
            } else {
                idx = face.i3<<1;
                _data[6] = vout[idx]; idx++;
                _data[7] = vout[idx];
                graphics.drawPath(_cmdQuadrangle, _data);
            }
            graphics.endFill();
        }
        return this;
    }
    
    /** render with texture */
    private var _indices:Vector.<int> = new Vector.<int>(); // temporary index list
    public function renderTexture(texture:BitmapData) : Render3D {
        var idx:int, mat:Material, indices:Vector.<int> = _indices;
        indices.length = 0;
        for each (var face:Face in _facesProjected) { indices.push(face.i0, face.i1, face.i2); }
        Utils3D.projectVectors(_projectionMatrix, 
                               _meshProjected.verticesOnWorld, 
                               _meshProjected.verticesOnScreen, 
                               _meshProjected.texCoord);
        graphics.clear();
        graphics.beginBitmapFill(texture, null, false, true);
        graphics.drawTriangles(_meshProjected.verticesOnScreen, indices, _meshProjected.texCoord);
        graphics.endFill();
        return this;
    }
}

/** Point3D */
class Point3D extends Vector3D {
    public var world:Vector3D;
    function Point3D(x:Number=0, y:Number=0, z:Number=0, w:Number=1) { super(x,y,z,w); world=clone(); }
}

/** Face */
class Face {
    public var i0:int, i1:int, i2:int, i3:int, pvi:int, mat:int, normal:Point3D;
    static private var _freeList:Vector.<Face> = new Vector.<Face>();
    static public function free(face:Face) : void { _freeList.push(face); }
    static public function alloc(i0:int, i1:int, i2:int, i3:int, mat:int) : Face { 
        var f:Face = _freeList.pop() || new Face();
        f.i0=i0; f.i1=i1; f.i2=i2; f.i3=i3; f.pvi=0; f.mat=mat;
        return f;
    }
}

/** Mesh */
class Mesh {
    public var materials:Vector.<Material>;                 // material list
    public var verticesCount:int;
    public var vertices:Vector.<Number>;                    // vertex
    public var verticesOnWorld:Vector.<Number>;             // vertex on camera coordinate
    public var verticesOnScreen:Vector.<Number>;            // vertex on screen
    public var texCoord:Vector.<Number>;                    // texture coordinate
    public var faces:Vector.<Face> = new Vector.<Face>();   // face list
    public var vnormals:Vector.<Vector3D>;                  // vertex normal
    
    /** constructor */
    function Mesh(materials:Vector.<Material>) {
        this.materials = materials;
        this.vertices = new Vector.<Number>();
        this.texCoord = new Vector.<Number>();
        this.verticesOnWorld = new Vector.<Number>();
        this.verticesOnScreen = new Vector.<Number>();
        this.vnormals = null;
        this.verticesCount = 0;
    }
    
    /** clear all faces */
    public function clear() : Mesh {
        for each (var face:Face in faces) Face.free(face);
        faces.length = 0;
        return this;
    }
    
    /** register face */
    public function face(i0:int, i1:int, i2:int, mat:int=0) : Mesh {
        faces.push(Face.alloc(i0, i1, i2, -1, mat));
        return this;
    }
    
    /** register quadrangle face. set div=true to divide into 2 triangles. */
    public function qface(i0:int, i1:int, i2:int, i3:int, mat:int=0, div:Boolean=true) : Mesh {
        if (div) faces.push(Face.alloc(i0, i1, i2, -1, mat), Face.alloc(i3, i2, i1, -1, mat));
        else     faces.push(Face.alloc(i0, i1, i3, i2, mat));
        return this;
    }
    
    /** update face gravity point and normal */
    public function updateFaces() : Mesh {
        verticesCount = vertices.length/3;
        var vs:Vector.<Number> = vertices;
        for each (var f:Face in faces) {
            var i0:int=(f.i0<<1)+f.i0, i1:int=(f.i1<<1)+f.i1, i2:int=(f.i2<<1)+f.i2;
            var x01:Number=vs[i1]-vs[i0], x02:Number=vs[i2]-vs[i0];
            f.pvi = vs.length+2;
            vs.push((vs[i0++] + vs[i1++] + vs[i2++]) * 0.333333333333);
            var y01:Number=vs[i1]-vs[i0], y02:Number=vs[i2]-vs[i0];
            vs.push((vs[i0++] + vs[i1++] + vs[i2++]) * 0.333333333333);
            var z01:Number=vs[i1]-vs[i0], z02:Number=vs[i2]-vs[i0];
            vs.push((vs[i0++] + vs[i1++] + vs[i2++]) * 0.333333333333);
            f.normal = new Point3D(y02*z01-y01*z02, z02*x01-z01*x02, x02*y01-x01*y02, 0);
            f.normal.normalize();
            if (f.i3 != -1) {
                var i3:int = (f.i3<<1)+f.i3;
                vs[f.pvi-2] = vs[f.pvi-2]*0.75 + vs[i3++]*0.25;
                vs[f.pvi-1] = vs[f.pvi-1]*0.75 + vs[i3++]*0.25;
                vs[f.pvi]   = vs[f.pvi]  *0.75 + vs[i3]  *0.25;
            }
        }
        return this;
    }
}

/** Light */
class Light extends Point3D {
    public var halfVector:Vector3D = new Vector3D();
    
    /** constructor (set position) */
    function Light(x:Number=1, y:Number=1, z:Number=1) {
        super(x, y, z, 0);
        normalize();
    }

    /** projection */
    public function transformBy(matrix:Matrix3D) : void {
        world = matrix.deltaTransformVector(this);
        halfVector.x = world.x;
        halfVector.y = world.y;
        halfVector.z = world.z + 1; 
        halfVector.normalize();
    }
}

/** Material */
class Material extends BitmapData {
    public var alpha:Number = 1;    // The alpha value is available for renderSolid()
    public var doubleSided:int = 0; // set doubleSided=-1 if double sided material
    
    /** constructor */
    function Material(dif:int=128, spc:int=128) { super(dif, spc, false); }
    
    /** set color. */
    public function setColor(col:uint, amb:int=64, dif:int=192, spc:int=0,  pow:Number=8) : Material {
        fillRect(rect, col);
        var lmap:LightMap = new LightMap(width, height);
        draw(lmap.diffusion(amb, dif), null, null, "hardlight");
        draw(lmap.specular (spc, pow), null, null, "add");
        lmap.dispose();
        return this;
    }
    
    /** calculate color by light and normal vector. */
    public function getColor(l:Light, n:Vector3D) : uint {
        var dir:Vector3D = l.world, hv:Vector3D = l.halfVector;
        var ln:int = int((dir.x * n.x + dir.y * n.y + dir.z * n.z) * (width-1)),
            hn:int = int((hv.x  * n.x + hv.y  * n.y + hv.z  * n.z) * (height-1));
        if (ln<0) ln = (-ln) & doubleSided;
        if (hn<0) hn = (-hn) & doubleSided;
        return getPixel(ln, hn);
    }
}

class LightMap extends BitmapData {
    function LightMap(dif:int, spc:int) { super(dif, spc, false); }
    
    public function diffusion(amb:int, dif:int) : BitmapData {
        var col:int, rc:Rectangle = new Rectangle(0, 0, 1, height), ipk:Number = 1 / width;
        for (rc.x=0; rc.x<width; rc.x+=1) {
            col = ((rc.x * (dif - amb)) * ipk) + amb;
            fillRect(rc, (col<<16)|(col<<8)|col);
        }
        return this;
    }
    
    public function specular(spc:int, pow:Number) : BitmapData {
        var col:int, rc:Rectangle = new Rectangle(0, 0, width, 1),
            mpk:Number = (pow + 2) * 0.15915494309189534, ipk:Number = 1 / height;
        for (rc.y=0; rc.y<height; rc.y+=1) {
            col = Math.pow(rc.y * ipk, pow) * spc * mpk;
            if (col > 255) col = 255;
            fillRect(rc, (col<<16)|(col<<8)|col);
        }
        return this;
    }
}


// Ambient Occlusion Primitive
class AOPrimitive extends Point3D {
    public var aoPrimitives:Vector.<AOPrimitive> = new Vector.<AOPrimitive>();
    public var aoRadius:Number, ao:Vector.<Number>;
    function AOPrimitive(x:Number=0, y:Number=0, z:Number=0, r:Number=0, vc:int=0) {
        super(x, y, z, 1);
        aoRadius = r;
        ao = new Vector.<Number>(vc, true);
    }
}

