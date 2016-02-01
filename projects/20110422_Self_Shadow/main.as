package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;
    import flash.filters.*;
    import flash.text.*;

    [SWF(width='465', height='465', backgroundColor='#000000', frameRate='30')]
    public class main extends Sprite {
        private const WIDTH:int = 450;
        // 3D renders
        private var _materials:Vector.<Material> = new Vector.<Material>(13);
        private var _screen:BitmapData = new BitmapData(WIDTH, WIDTH, false, 0);
        private var _matbuf:Matrix = new Matrix(1, 0, 0, 1, 225, 225);
        private var _hexahedron:Mesh, _phexahedron:ProjectionMesh;
        private var _object:Mesh, _pobject:ProjectionMesh;
        private var _floor:Mesh,  _pfloor:ProjectionMesh;
        private var _light:Light = new Light(1,1,1);
        private var _camera:Vector3D = new Vector3D(0, 0, -250);
        private var angleH:Number=0, angleV:Number=0, rotH:Number=0, rotV:Number=0;
        private var gl:Render3D = new Render3D(500,1);
        private var tf:TextField = new TextField();
        private var frame:int = 0;
        
        private var _matsm:Matrix = new Matrix(1, 0, 0, 1, 256, 256);
        private var _shadowmap:BitmapData = new BitmapData(512, 512, false, 0);
        private var _shadowbuf:BitmapData = new BitmapData(WIDTH, WIDTH, false, 0);
        private var _shadowlayer:BitmapData = new BitmapData(WIDTH, WIDTH, false, 0);
        private var _shadowmapView:Bitmap = new Bitmap(_shadowlayer);
        
        // entry point
        function main() {
            stage.quality = "low";
            addChild(gl).visible = false;
            with(addChild(new Bitmap(_screen))){x=y=int((465-WIDTH)*0.5);}
            addChild(_shadowmapView);
            _shadowmapView.x = _shadowmapView.y = int((465-WIDTH)*0.5);
            _shadowmapView.visible = false;
            addEventListener(Event.ADDED_TO_STAGE, setup);
        }

        
        public function setup(e:Event) : void {
            var i:int, j:int, size:Number = 50, edge:Number = 4, width:Number = 8;
            removeEventListener(Event.ADDED_TO_STAGE, setup);
            stage.addEventListener(MouseEvent.CLICK, function(e:Event) : void {_shadowmapView.visible = !_shadowmapView.visible;});
            _materials[0] = new Material().setColor(0x80c060, 64, 160, 0, 0);
            _materials[1] = new Material().setColor(0xc0c0c0, 128, 128, 0, 0);
            _hexahedron = new Mesh(_materials);
            _object = new Mesh(_materials);
            _floor = new Mesh(_materials);
            var s:Number=size, t:Number=s-edge, r:Number=t-width, q:Number=r;
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?t:-t, ((i>>1)&1)?t:-t, (i>>2)?s:-s);
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?r:-r, ((i>>1)&1)?r:-r, (i>>2)?s:-s);
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?t:-t, ((i>>1)&1)?s:-s, (i>>2)?t:-t);
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?r:-r, ((i>>1)&1)?s:-s, (i>>2)?r:-r);
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?s:-s, ((i>>1)&1)?t:-t, (i>>2)?t:-t);
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?s:-s, ((i>>1)&1)?r:-r, (i>>2)?r:-r);
            for (i=0; i<8; i++) _hexahedron.vertices.push((i&1)?q:-q, ((i>>1)&1)?q:-q, (i>>2)?q:-q);
            _f(0, 1, 0); _f(1, 3, 0); _f(3, 2, 0); _f(2, 0, 0);
            _f(1, 0, 1); _f(0, 4, 1); _f(2, 3, 1); _f(5, 1, 1);
            _f(4, 0, 2); _f(3, 1, 2); _f(1, 5, 2); _f(0, 2, 2);
            _e(1, 0, 1); _e(3, 1, 2); _e2(20, 16);
            _c(0); _c(3); _c(5); _c(6); _d(1); _d(2); _d(4); _d(7);
            _hexahedron.updateFaces(179);
            _hexahedron.texCoord.length = _hexahedron.verticesCount * 3;
            _phexahedron = new ProjectionMesh(_hexahedron);
            s = size * 0.4;
            gl.id().t(s,s,s).project(_phexahedron);
            _object.put(_phexahedron);
            gl.id().t(-s,-s,-s).project(_phexahedron);
            _object.put(_phexahedron);
            _object.updateFaces(179);
            _pobject = new ProjectionMesh(_object);
            s = size * 2;
            for (i=0; i<25; i++) _floor.vertices.push((i%5-2)*s, (int(i/5)-2)*s, -s-40);
            for (i=0; i<16; i++) {
                j = (i&3)+(i>>2)*5;
                _floor.qface(j+1, j, j+6, j+5, 1);
            }
            _floor.updateFaces(179);
            _floor.texCoord.length = _floor.verticesCount * 3;
            _pfloor = new ProjectionMesh(_floor);
            addEventListener(Event.ENTER_FRAME, draw);
            function _f(i0:int, i1:int, plane:int) : void { 
                var l:int = plane << 4;
                _hexahedron.qface(i0+l,  i1+l,  i0+l+8, i1+l+8, 0).qface(7+l-i1, 7+l-i0, 7+l-i1+8, 7+l-i0+8, 0)
                           .qface(i1+48, i0+48, i1+l+8, i0+l+8, 0).qface(55-i0,  55-i1,  7+l-i0+8, 7+l-i1+8, 0);
            }
            function _e(i0:int, i1:int, con:int) : void {
                con <<= 4;
                _hexahedron.qface(  i0,   i1,   i0+con,   i1+con, 0).qface(7-i1, 7-i0, 7-i1+con, 7-i0+con, 0)
                           .qface(3-i0, 3-i1, 3-i0+con, 3-i1+con, 0).qface(4+i1, 4+i0, 4+i1+con, 4+i0+con, 0);
            }
            function _e2(i0:int, i1:int) : void {
                _hexahedron.qface(  i0,   i1, i0+16, i1+16, 0).qface(i1+1, i0+1, i1+17, i0+17, 0)
                           .qface(i1+2, i0+2, i1+18, i0+18, 0).qface(i0+3, i1+3, i0+19, i1+19, 0);
            }
            function _d(i:int) : void { _hexahedron.face(i,i+16,i+32); }
            function _c(i:int) : void { _hexahedron.face(i+16,i,i+32); }
            _light.transformBy(gl.id().matrix);
        }
        
        
        private function draw(e:Event) : void {
            frame++;
            _screen.fillRect(_screen.rect, 0xffffff);
            _shadowlayer.fillRect(_shadowlayer.rect, 0xffffff);
            _shadowbuf.fillRect(_shadowbuf.rect, 0);
            _shadowmap.fillRect(_shadowmap.rect, 0);
            
            var targetAngleH:Number = (232.5-mouseX) * 0.4, targetAngleV:Number = -mouseY * 0.2, i:int, imax:int, r:Number;
            rotH += (targetAngleH - angleH) * 0.01;
            rotV += (targetAngleV - angleV) * 0.01;
            angleH += (rotH *= 0.9);
            angleV += (rotV *= 0.9);
            gl.id().tv(_camera).ry(angleH).rx(angleV);
            gl.push().ry(-45).rx(45).project(_pobject).project(_pfloor).pop();
            _shadowmap.draw(gl.renderDepth(_pobject), _matsm);
            imax = _pobject.base.verticesCount;
            for (i=0; i<imax; i++) {
                _pobject.base.texCoord[i*3]   = _pobject.verticesOnScreen[i*2]*0.001953125+0.5;
                _pobject.base.texCoord[i*3+1] = _pobject.verticesOnScreen[i*2+1]*0.001953125+0.5;
                _pobject.base.texCoord[i*3+2] = 0;
            }
            gl.projectOnScreen(_pfloor);
            imax = _pfloor.base.verticesCount;
            for (i=0; i<imax; i++) {
                _pfloor.base.texCoord[i*3]   = _pfloor.verticesOnScreen[i*2]*0.001953125+0.5;
                _pfloor.base.texCoord[i*3+1] = _pfloor.verticesOnScreen[i*2+1]*0.001953125+0.5;
                _pfloor.base.texCoord[i*3+2] = 0;
            }
            gl.push().project(_pobject).project(_pfloor).pop();
            _shadowbuf.draw(gl.renderTexture(_pfloor,  _shadowmap), _matbuf);
            _shadowbuf.draw(gl.renderTexture(_pobject, _shadowmap), _matbuf);
            _shadowbuf.draw(gl.renderDepth(_pobject, false), _matbuf, null, "subtract");
            _shadowlayer.threshold(_shadowbuf, _shadowbuf.rect, _shadowbuf.rect.topLeft, ">", 0xff000010, 0xff808080, 0xff);
            _shadowbuf.applyFilter(_shadowlayer, _shadowlayer.rect, _shadowlayer.rect.topLeft, blur);
            _screen.draw(gl.renderSolid(_pfloor, _light), _matbuf);
            _screen.draw(gl.renderSolid(_pobject, _light), _matbuf);
            _screen.draw(_shadowbuf, null, null, "multiply");
            _pobject.screenProjected = false;
            _screen.draw(gl.renderDepth(_pobject), _matbuf, null, "multiply");
        }
        
        private var blur:BlurFilter = new BlurFilter(4, 4);
    }
}


import flash.display.*;
import flash.geom.*;


// 3D Engine
//----------------------------------------------------------------------------------------------------
/** Core */
class Render3D extends Shape {
    /** model view matrix */
    public var matrix:Matrix3D;
    private var _projectionMatrix:Matrix3D;                              // projection matrix
    private var _matrixStac:Vector.<Matrix3D> = new Vector.<Matrix3D>(); // matrix stac
    private var _cmdWire:Vector.<int> = Vector.<int>([1,2]);             // commands to draw wire
    private var _cmdTriangle:Vector.<int> = Vector.<int>([1,2,2]);       // commands to draw triangle
    private var _cmdQuadrangle:Vector.<int> = Vector.<int>([1,2,2,2]);   // commands to draw quadrangle
    private var _data:Vector.<Number> = new Vector.<Number>(8, true);    // data to draw shape
    private var _clippingZ:Number;                                       // clipping z value
    private var _depthMap:BitmapData = new BitmapData(256, 256, false);  // texture for depth buffer rendering
    
    public function get depthMap() : BitmapData { return _depthMap; }
    
    /** constructor */
    function Render3D(focus:Number=300, clippingZ:Number=-0.1) {
        var projector:PerspectiveProjection = new PerspectiveProjection()
        projector.focalLength = focus;
        _projectionMatrix = projector.toMatrix3D();
        _clippingZ = -clippingZ;
        matrix = new Matrix3D();
        _matrixStac.length = 1;
        _matrixStac[0] = matrix;
        var u:int, v:int;
        for (v=0; v<256; v++) 
            for (u=0; u<256; u++) 
                //_depthMap.setPixel(255-u, 255-v, (v<<8)|u);
                _depthMap.setPixel(255-u, 255-v, (u<<16)|(u<<8)|u);
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
    public function mult(mat:Matrix3D) : Render3D { matrix.prepend(mat); return this; }
    
    // projections
    //--------------------------------------------------
    /** project */
    public function project(mesh:ProjectionMesh) : Render3D {
        matrix.transformVectors(mesh.base.vertices, mesh.verticesOnWorld);
        var fn:Vector3D, fnw:Vector3D, vs:Vector.<Number> = mesh.verticesOnWorld,
            nearZ:Number = -Number.MAX_VALUE, farZ:Number = _clippingZ,
            flist:Vector.<Face> = mesh.base.faces;
        var m:Vector.<Number> = matrix.rawData, 
            m00:Number = m[0], m01:Number = m[1], m02:Number = m[2], 
            m10:Number = m[4], m11:Number = m[5], m12:Number = m[6], 
            m20:Number = m[8], m21:Number = m[9], m22:Number = m[10];
        mesh.facesProjected.length = 0;
        for each (var f:Face in flist) {
            var i0:int=(f.i0<<1)+f.i0, i1:int=(f.i1<<1)+f.i1, i2:int=(f.i2<<1)+f.i2,
                x0:Number=vs[i0++], x1:Number=vs[i1++], x2:Number=vs[i2++],
                y0:Number=vs[i0++], y1:Number=vs[i1++], y2:Number=vs[i2++],
                z0:Number=vs[i0],   z1:Number=vs[i1],   z2:Number=vs[i2];
            if (z0<_clippingZ && z1<_clippingZ && z2<_clippingZ) {
                fn  = f.normal;
                fnw = mesh.normalsProjected[f.index];
                fnw.x = fn.x * m00 + fn.y * m10 + fn.z * m20;
                fnw.y = fn.x * m01 + fn.y * m11 + fn.z * m21;
                fnw.z = fn.x * m02 + fn.y * m12 + fn.z * m22;
                if (vs[f.gpi-2]*fnw.x + vs[f.gpi-1]*fnw.y + vs[f.gpi]*fnw.z <= 0) {
                    if (nearZ < z0) nearZ = z0;
                    if (nearZ < z1) nearZ = z1;
                    if (nearZ < z2) nearZ = z2;
                    if (farZ  > z0) farZ  = z0;
                    if (farZ  > z1) farZ  = z1;
                    if (farZ  > z2) farZ  = z2;
                    mesh.facesProjected.push(f);
                }
            }
        }
        mesh.nearZ = nearZ;
        mesh.farZ  = farZ;
        mesh.facesProjected.sort(function(f1:Face, f2:Face):Number{ return vs[f1.gpi] - vs[f2.gpi]; });
        mesh.indexDirty = true;
        mesh.screenProjected = false;
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
    public function renderSolid(mesh:ProjectionMesh, light:Light) : Render3D {
        var idx:int, mat:Material, materials:Vector.<Material> = mesh.base.materials,
            vout:Vector.<Number> = mesh.verticesOnScreen;
        if (!mesh.screenProjected) projectOnScreen(mesh);
        graphics.clear();
        for each (var face:Face in mesh.facesProjected) {
            mat = materials[face.mat];
            graphics.beginFill(mat.getColor(light, mesh.normalsProjected[face.index]), mat.alpha);
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
    public function renderTexture(mesh:ProjectionMesh, texture:BitmapData) : Render3D {
        if (!mesh.screenProjected) projectOnScreen(mesh);
        graphics.clear();
        graphics.beginBitmapFill(texture, null, false, true);
        graphics.drawTriangles(mesh.verticesOnScreen, mesh.indicesProjected, mesh.base.texCoord);
        graphics.endFill();
        return this;
    }

    /** render depth buffer */
    public function renderDepth(mesh:ProjectionMesh, calcDepth:Boolean=true) : Render3D {
        var i:int, imax:int = mesh.vertexImax, 
            nearZ:Number = (_clippingZ < mesh.nearZ) ? _clippingZ : mesh.nearZ,
            r:Number = 1/(mesh.farZ - nearZ), duvt:Vector.<Number> = _depthUVT;
        if (calcDepth) {
            duvt.length = 0;
            for (i=2; i<imax; i+=3) duvt.push((mesh.verticesOnWorld[i]-nearZ)*r, 0, 0);
        }
        if (!mesh.screenProjected) projectOnScreen(mesh, duvt);
        graphics.clear();
        graphics.beginBitmapFill(_depthMap, null, false, true);
        graphics.drawTriangles(mesh.verticesOnScreen, mesh.indicesProjected, duvt);
        graphics.endFill();
        return this;
    }
    private var _depthUVT:Vector.<Number> = new Vector.<Number>();
    
    /** project on screen */
    public function projectOnScreen(mesh:ProjectionMesh, texCoord:Vector.<Number>=null) : void {
        Utils3D.projectVectors(_projectionMatrix, mesh.verticesOnWorld, mesh.verticesOnScreen, texCoord || mesh.base.texCoord);
        mesh.screenProjected = true;
    }
}

/** Point3D */
class Point3D extends Vector3D {
    public var world:Vector3D;
    function Point3D(x:Number=0, y:Number=0, z:Number=0, w:Number=1) { super(x,y,z,w); world=clone(); }
}

/** Face */
class Face {
    public var index:int, i0:int, i1:int, i2:int, i3:int, gpi:int, mat:int, normal:Vector3D;
    static private var _freeList:Vector.<Face> = new Vector.<Face>();
    static public function free(face:Face) : void { _freeList.push(face); }
    static public function alloc(index:int, i0:int, i1:int, i2:int, i3:int, mat:int) : Face { 
        var f:Face = _freeList.pop() || new Face();
        f.index=index; f.i0=i0; f.i1=i1; f.i2=i2; f.i3=i3; f.gpi=0; f.mat=mat;
        return f;
    }
}

/** Mesh */
class Mesh {
    public var materials:Vector.<Material>;                 // material list
    public var vertices:Vector.<Number>;                    // vertex
    public var verticesCount:int;                           // vertex count
    public var texCoord:Vector.<Number>;                    // texture coordinate
    public var faces:Vector.<Face> = new Vector.<Face>();   // face list
    
    /** constructor */
    function Mesh(materials:Vector.<Material>=null) {
        this.materials = materials;
        this.vertices = new Vector.<Number>();
        this.texCoord = new Vector.<Number>();
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
        faces.push(Face.alloc(faces.length, i0, i1, i2, -1, mat));
        return this;
    }
    
    /** register quadrangle face. set div=true to divide into 2 triangles. */
    public function qface(i0:int, i1:int, i2:int, i3:int, mat:int=0, div:Boolean=true) : Mesh {
        if (div) {
            faces.push(Face.alloc(faces.length,   i0, i1, i2, -1, mat), 
                       Face.alloc(faces.length+1, i3, i2, i1, -1, mat));
        }
        else faces.push(Face.alloc(faces.length, i0, i1, i3, i2, mat));
        return this;
    }
    
    /** put mesh on world coordinate. */
    public function put(src:ProjectionMesh, mat:int=-1) : Mesh {
        var i0:int=vertices.length, imax:int=src.vertexImax, flist:Vector.<Face>=src.base.faces;
        vertices.length += imax;
        for (var i:int=0; i<imax; i++) vertices[i0+i] = src.verticesOnWorld[i];
        i0 /= 3;
        for each (var f:Face in flist) {
            i = (mat == -1) ? f.mat : mat;
            if (f.i3==-1) face (f.i0+i0, f.i1+i0, f.i2+i0, i);
            else          qface(f.i0+i0, f.i1+i0, f.i3+i0, f.i2+i0, i, false);
        }
        return this;
    }
    
    /** update face gravity point and normal. create fireframe lines when createWire==true */
    public function updateFaces(facetAngle:Number = 180) : Mesh {
        verticesCount = vertices.length/3;
        var vs:Vector.<Number> = vertices;
        for each (var f:Face in faces) {
            f.gpi = vs.length+2;
            var i0:int=(f.i0<<1)+f.i0, i1:int=(f.i1<<1)+f.i1, i2:int=(f.i2<<1)+f.i2;
            var x01:Number=vs[i1]-vs[i0], x02:Number=vs[i2]-vs[i0];
            vs.push((vs[i0++] + vs[i1++] + vs[i2++]) * 0.333333333333);
            var y01:Number=vs[i1]-vs[i0], y02:Number=vs[i2]-vs[i0];
            vs.push((vs[i0++] + vs[i1++] + vs[i2++]) * 0.333333333333);
            var z01:Number=vs[i1]-vs[i0], z02:Number=vs[i2]-vs[i0];
            vs.push((vs[i0++] + vs[i1++] + vs[i2++]) * 0.333333333333);
            f.normal = new Point3D(y02*z01-y01*z02, z02*x01-z01*x02, x02*y01-x01*y02, 0);
            f.normal.normalize();
            if (f.i3 != -1) {
                var i3:int = (f.i3<<1)+f.i3;
                vs[f.gpi-2] = vs[f.gpi-2]*0.75 + vs[i3++]*0.25;
                vs[f.gpi-1] = vs[f.gpi-1]*0.75 + vs[i3++]*0.25;
                vs[f.gpi]   = vs[f.gpi]  *0.75 + vs[i3]  *0.25;
            }
        }
        return this;
    }
}

/** mesh for projection */
class ProjectionMesh {
    public var verticesOnWorld:Vector.<Number>;     // vertex on camera coordinate
    public var verticesOnScreen:Vector.<Number>;    // vertex on screen
    public var facesProjected:Vector.<Face>;        // projected face
    public var normalsProjected:Vector.<Vector3D>;  // projected normals
    public var vnormals:Vector.<Vector3D>;          // vertex normal
    public var nearZ:Number, farZ:Number;           // z buffer range
    public var screenProjected:Boolean = false;     // flag to projection on screen
    private var _projectedFaceIndices:Vector.<int> = new Vector.<int>();
    private var _base:Mesh;
    
    /** indices of projected faces */
    public function get indicesProjected() : Vector.<int> {
        var idx:Vector.<int> = _projectedFaceIndices;
        if (idx.length == 0) for each (var f:Face in facesProjected) idx.push(f.i0, f.i1, f.i2);
        return idx;
    }
    
    public function set indexDirty(b:Boolean) : void {
        if (b) _projectedFaceIndices.length = 0;
    }

    public function get base() : Mesh { return _base; }
    public function set base(m:Mesh) : void {
        if (m && normalsProjected.length < m.faces.length) {
            var i:int = normalsProjected.length, imax:int = m.faces.length;
            normalsProjected.length = imax;
            for (; i<imax; i++) normalsProjected[i] = new Vector3D();
        }
        _base = m;
    }
    
    public function get vertexImax() : int { return (_base.verticesCount<<1) + _base.verticesCount; }
    
    /** constructor */
    function ProjectionMesh(m:Mesh=null) {
        this.verticesOnWorld = new Vector.<Number>();
        this.verticesOnScreen = new Vector.<Number>();
        this.facesProjected = new Vector.<Face>();
        this.normalsProjected= new Vector.<Vector3D>();
        this.vnormals = null;
        this.base = m;
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
