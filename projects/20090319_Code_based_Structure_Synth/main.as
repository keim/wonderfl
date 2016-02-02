// Code based Structure Synth
//  Structure Synth; http://structuresynth.sourceforge.net/
//------------------------------------------------------------
package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;

    [SWF(width='465', height='465', backgroundColor='#000000', frameRate='30')]
    public class main extends Sprite {
        // 3D renders
        private var _materials:Vector.<Material> = new Vector.<Material>();
        private var _light:Light = new Light(1,0.2,0.4);
        private var _meshSS:Mesh = new Mesh(_materials);

        private var _screen:BitmapData = new BitmapData(465, 465, false, 0);
        private var _matscr:Matrix = new Matrix(1, 0, 0, 1, 232.5, 232.5);
        private var gl:Render3D = new Render3D(300,1);
        private var ss:StructureSynth;
        
        // objects
        private var camera:Vector3D;
        
        // entry point
        function main() {
            var i:int;
            
            camera = new Vector3D(0, -5, -50);
            _materials.push((new Material()).setColor(0x80c0ff, 64, 192, 32, 80));
            
            addChild(gl).visible = false;
            addChild(new Bitmap(_screen));
            addEventListener("enterFrame", _onEnterFrame);
            
            // create mesh by Structure Synth
            ss = new StructureSynth(gl);
            ss.mesh("box", _createHexahedron(new Mesh(), 1));
            ss.rule("r1", function() : void {
                ss.call("box");
                ss.call("{z 6 x 0.3 rx -45.6 s 1 0.99 0.99} r1");
            });
            ss.rule("r2", function() : void {
                ss.call("box");
                ss.call("{rx 45.6 z -6 x -0.3 s 1 0.99 0.99} r2");
            });
            ss.init(_meshSS, 200).call("r1");
            ss.init(_meshSS, 199).call("{rx 45.6 z -6 x -0.3 s 1 0.99 0.99} r2");
            _meshSS.updateFaces();
        }

        private function _onEnterFrame(e:Event) : void {
            _screen.fillRect(_screen.rect, 0);
            _light.transformBy(gl.id().tv(camera).rx((400-mouseY)*0.15).ry((232-mouseX)*0.75).matrix);
            _screen.draw(gl.push().t(0, 0, 0).project(_meshSS).renderSolid(_light).pop(), _matscr);
        }
        
        // create regular solids
        //--------------------------------------------------
        private function _createHexahedron(mesh:Mesh, size:Number) : Mesh {
            for (var i:int=0; i<8; i++) mesh.vertices.push((i&1)?size:-size, ((i>>1)&1)?size:-size, (i>>2)?size:-size);
            mesh.qface(0,1,2,3,0,false).qface(1,0,5,4,0,false).qface(0,2,4,6,0,false);
            mesh.qface(2,3,6,7,0,false).qface(3,1,7,5,0,false).qface(5,4,7,6,0,false);
            mesh.updateFaces();
            return mesh;
        }
    }
}


import flash.display.*;
import flash.geom.*;


// Structure Synth
//----------------------------------------------------------------------------------------------------
class StructureSynth {
    private var _mesh:Mesh;
    private var _functions:* = new Object();
    private var _meshes:* = new Object();
    private var _maxDepth:int;
    private var _depth:int;
    private var _core:Render3D;
    static private var _rexLine:RegExp = /((\d+)\s*\*)?\s*({(.*?)})?\s*([^{}\s]+)/;
    static private var _rexOperate:RegExp = /(r?[x-z]|s)\s*([\-\d.]+)\s*([\-\d.]+)?\s*([\-\d.]+)?/g;
    
    function StructureSynth(core:Render3D) { 
        _core = core;
    }
    
    /** register mesh to call in CFDG.
     *  @param name Mesh name to call.
     *  @param mesh Mesh data.
     */
    public function mesh(name:String, mesh:Mesh) : StructureSynth {
        _meshes[name] = mesh;
        return this;
    }
    
    /** register rule.
     *  @param name Rule name to call.
     *  @param func Function to execute. The type is "function(depth:int) : void".
     *  @param option Option["w"/"weight"] to set weight and the option["md"/"maxdepth"] to set maxdepth.
     */
    public function rule(name:String, func:Function, option:*=null) : StructureSynth {
        if (!(name in _functions)) _functions[name] = new SSFunctionList();
        _functions[name].rule(func, option||new Object());
        return this;
    }
    
    /** initialize to constructing structure */
    public function init(mesh:Mesh, maxDepth:int=512) : StructureSynth {
        for each (var func:SSFunctionList in _functions) func.init();
        _maxDepth = maxDepth;
        _depth = 0;
        _mesh = mesh;
        _core.id();
        return this;
    }
    
    /** command 1 line in CFDG. */
    public function call(line:String) : StructureSynth {
        var i:int, imax:int, res:*;
        res = _rexLine.exec(line);
        if (res) {
            _core.push();
            imax = (res[2]) ? int(res[2]) : 1;
            for (i=0; i<imax; i++) {
                operate(res[4]);
                if (res[5] in _functions) {
                    if (++_depth <= _maxDepth) _functions[res[5]].call();
                    _depth--;
                } else 
                if (res[5] in _meshes) {
                    _core.project(_meshes[res[5]]);
                    _mesh.put(_meshes[res[5]]);
                }
            }
            _core.pop();
        }
        return this;
    }
    
    /** opreate matrix */
    public function operate(ope:String) : void {
        //_rexOperate.lastIndex = 0;
        var res:* = _rexOperate.exec(ope);
        while(res) {
            var n:Number = Number(res[2]);
            switch (res[1]) {
            case 'x':  _core.t(n,0,0); break;
            case 'y':  _core.t(0,n,0); break;
            case 'z':  _core.t(0,0,n); break;
            case 'rx': _core.rx(n);    break;
            case 'ry': _core.ry(n);    break;
            case 'rz': _core.rz(n);    break;
            case 's':
                if (res[3]) _core.s(n, Number(res[3]), Number(res[4]));
                else _core.s(n, n, n);
                break;
            }
            res = _rexOperate.exec(ope);
        }
    }
}

class SSFunctionList {
    private var _totalWeight:Number = 0;
    private var _functions:Vector.<SSFunction> = new Vector.<SSFunction>();
    
    public function rule(func:Function, option:*) : void {
        var ssf:SSFunction = new SSFunction(func, option);
        _functions.push(ssf);
        _totalWeight += ssf.weight;
    }

    public function init() : void {
        for each (var ssf:SSFunction in _functions) ssf.depth = 0;
    }
    
    public function call() : void {
        var w:Number = 0, rand:Number = Math.random() * _totalWeight;
        for each (var ssf:SSFunction in _functions) {
            w += ssf.weight;
            if (rand <= w) {
                if (++ssf.depth <= ssf.maxdepth) ssf.func();
                ssf.depth--;
                return;
            }
        }
    }
}

class SSFunction {
    public var func:Function;
    public var weight:Number;
    public var maxdepth:int;
    public var depth:int = 0;
    
    function SSFunction(func:Function, option:*) {
        this.func = func;
        this.weight = option["w"] || option["weight"] || 1;
        this.maxdepth = option["md"] || option["maxdepth"] || int.MAX_VALUE;
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
    function Render3D(focus:Number=300, clippingZ:Number=0.1) {
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
        _facesProjected.sort(function(f1:Face, f2:Face):Number{ return vs[f1.pvi] - vs[f2.pvi]; });
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
    public var vertices:Vector.<Number>;                    // vertex
    public var verticesOnWorld:Vector.<Number>;             // vertex on camera coordinate
    public var verticesOnScreen:Vector.<Number>;            // vertex on screen
    public var verticesCount:int;                           // vertex count
    public var texCoord:Vector.<Number>;                    // texture coordinate
    public var faces:Vector.<Face> = new Vector.<Face>();   // face list
    public var vnormals:Vector.<Vector3D>;                  // vertex normal
    
    /** constructor */
    function Mesh(materials:Vector.<Material>=null) {
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
    
    /** put mesh on model coordinate. */
    public function put(src:Mesh, mat:int=-1) : Mesh {
        var i0:int = vertices.length, imax:int, i:int;
        imax = (src.verticesCount<<1) + src.verticesCount;
        vertices.length += imax;
        for (i=0; i<imax; i++) vertices[i0+i] = src.verticesOnWorld[i];
        i0 /= 3;
        for each (var f:Face in src.faces) {
            i = (mat == -1) ? f.mat : mat;
            if (f.i3==-1) face (f.i0+i0, f.i1+i0, f.i2+i0, i);
            else          qface(f.i0+i0, f.i1+i0, f.i3+i0, f.i2+i0, i, false);
        }
        return this;
    }
    
    /** update face gravity point and normal */
    public function updateFaces() : Mesh {
        verticesCount = vertices.length/3;
        var vs:Vector.<Number> = vertices;
        for each (var f:Face in faces) {
            f.pvi = vs.length+2;
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

