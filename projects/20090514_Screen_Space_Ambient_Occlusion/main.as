// forked from keim_at_Si's Depth buffer test
// forked from keim_at_Si's Regular Solid Structures
// forked from keim_at_Si's Code based Structure Synth
// Code based Structure Synth
//  Structure Synth; http://structuresynth.sourceforge.net/
//------------------------------------------------------------
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
        private var _materials:Vector.<Material> = new Vector.<Material>();
        private var _light:Light = new Light(1,0.5,0.25);
        private var _screen:BitmapData = new BitmapData(WIDTH, WIDTH, false, 0);
        private var _matbuf:Matrix = new Matrix(1, 0, 0, 1, 225, 225);
        private var gl:Render3D = new Render3D(300,1);
        private var ss:StructureSynth = new StructureSynth();
        private var tf:TextField = new TextField();

        // objects
        private var camera:Vector3D;
        private var struct:Vector.<ProjectionMesh> = new Vector.<ProjectionMesh>(5, true);
        private var _depth:BitmapData;
        private var _ssao :BitmapData;
        private var _mask :BitmapData;
        
        // motions
        private var clicked:Boolean = false;
        private var frame:int = 0;
        
        // entry point
        function main() {
            stage.quality = "low";
            Wonderfl.capture_delay(3);
            
            camera = new Vector3D(0, 0, -50);
            _depth = new BitmapData(WIDTH, WIDTH, false, 0);
            _ssao  = new BitmapData(WIDTH, WIDTH, false, 0);
            _mask  = new BitmapData(WIDTH, WIDTH, false, 0);
            
            _materials.push((new Material()).setColor(0xff8080, 64, 192, 8, 40),
                            (new Material()).setColor(0xd0d080, 64, 192, 8, 40),
                            (new Material()).setColor(0x80ff80, 64, 192, 8, 40),
                            (new Material()).setColor(0x80c0c0, 64, 192, 8, 40),
                            (new Material()).setColor(0x8080ff, 64, 192, 8, 40));
            
            tf.autoSize = "left";
            tf.htmlText = "<font face='_typewriter'>Click to switch on/off ambient occlusion.</font>";
            addChild(gl).visible = false;
            with(addChild(new Bitmap(_screen))) { x = y = 7; }
            with(addChild(tf)) { x = y = 7; }
            addEventListener("enterFrame", _onEnterFrame);
            stage.addEventListener("click", _onClick);
            
            // register meshes
            ss.primitive("tetra",  SolidFactory.tetrahedron (new Mesh(), 1, 0));  // 4vertices/4triangles
            ss.primitive("box",    SolidFactory.hexahedron  (new Mesh(), 1, 1));  // 8vertices/12triangles
            ss.primitive("octa",   SolidFactory.octahedron  (new Mesh(), 1, 2));  // 6vertices/8triangles
            ss.primitive("dodeca", SolidFactory.dodecahedron(new Mesh(), 1, 3));  // 12vertices/36triangles
            ss.primitive("icosa",  SolidFactory.icosahedron (new Mesh(), 1, 4));  // 20vertices/20triangles
            
            // struct[0]
            ss.root("md6", "{s4}{x-4y-4z-4}s4rx");
            ss.rule("s4rx", "", "{s1.5}icosa{z2x2}s4rz{y2z2}s4ry{x2y2}s4rx");
            ss.rule("s4ry", "", "{s1.5}icosa{z2x2}s4rz{y2z2}s4ry");
            ss.rule("s4rz", "", "{s1.5}icosa{z2x2}s4rz");
            struct[0] = new ProjectionMesh(ss.exec(new Mesh(_materials)).updateFaces());
        }

        private function _onEnterFrame(e:Event) : void {
            frame++;
            
            // projection
            _light.transformBy(gl.id().tv(camera).rx((400-mouseY)*0.25).ry((232-mouseX)*0.75).matrix);
            gl.push().rx(frame).project(struct[0]).pop();
            struct[0].nearZ = -10;
            struct[0].farZ = -80;

            // calculate screen space mbient occlusion
            _depth.fillRect(_depth.rect, 0);
            _depth.draw(gl.renderDepth(struct[0]), _matbuf);
            _ssao.applyFilter(_depth, _depth.rect, _depth.rect.topLeft, blur);
            _ssao.draw(_depth, null, null, "subtract");
            _ssao.threshold(_depth, _depth.rect, _depth.rect.topLeft, "==", 0, 0, 255);
            
            // draw
            _screen.fillRect(_screen.rect, 0xffffff);
            _screen.draw(gl.renderSolid(struct[0], _light), _matbuf);
            if (!clicked) _screen.draw(_ssao, null, colt, "multiply");
        }
        private var blur:BlurFilter = new BlurFilter(64, 64);
        private var colt:ColorTransform = new ColorTransform(-8, -8, -8, 1, 255, 255, 255, 0);
        
        private function _onClick(e:Event) : void { clicked = !clicked; }
    }
}


import flash.display.*;
import flash.geom.*;

// Solid Factory
//----------------------------------------------------------------------------------------------------
class SolidFactory {
    // regular solids
    //--------------------------------------------------
    static public function tetrahedron(mesh:Mesh, size:Number, mat:int=0) : Mesh {
        mesh.vertices.push(size,size,size, size,-size,-size, -size,size,-size, -size,-size,size);
        mesh.qface(0,2,1,3,mat).qface(1,3,0,2,mat);
        return mesh.updateFaces(true);
    }
    
    static public function hexahedron(mesh:Mesh, size:Number, mat:int=0, div:Boolean=true) : Mesh {
        for (var i:int=0; i<8; i++) mesh.vertices.push((i&1)?size:-size, ((i>>1)&1)?size:-size, (i>>2)?size:-size);
        mesh.qface(0,1,2,3,mat,div).qface(1,0,5,4,mat,div).qface(0,2,4,6,mat,div);
        mesh.qface(2,3,6,7,mat,div).qface(3,1,7,5,mat,div).qface(5,4,7,6,mat,div);
        return mesh.updateFaces(true,179);
    }
    
    static public function octahedron(mesh:Mesh, size:Number, mat:int=0) : Mesh {
        mesh.vertices.push(0,0,-size, -size,0,0, 0,-size,0, size,0,0, 0,size,0, 0,0,size);
        mesh.qface(0,1,2,5,mat).qface(0,2,3,5,mat).qface(0,3,4,5,mat).qface(0,4,1,5,mat);
        return mesh.updateFaces(true);
    }
    
    static public function dodecahedron(mesh:Mesh, size:Number, mat:int=0, div:Boolean=true) : Mesh {
        var a:Number=size*0.149071198, b:Number=size*0.241202266, c:Number=size*0.283550269, 
            d:Number=size*0.390273464, e:Number=size*0.458793973, f:Number=size*0.631475730, 
            g:Number=size*0.742344243;
        mesh.vertices.push(c,f,d, e,f,-a, 0,f,-b-b, -e,f,-a, -c,f,d);
        mesh.vertices.push(e,a,f, g,a,-b, 0,a,-d-d, -g,a,-b, -e,a,f);
        mesh.vertices.push(0,-a,d+d, g,-a,b, e,-a,-f, -e,-a,-f, -g,-a,b);
        mesh.vertices.push(0,-f,b+b, e,-f,a, c,-f,-d, -c,-f,-d, -e,-f,a);
        mesh.qface(0,3,1,2,mat,div).face(0,4,3,mat).qface(4,5,9,10,mat,div).face(4,0,5,mat);
        mesh.qface(0,6,5,11,mat,div).face(0,1,6,mat).qface(1,7,6,12,mat,div).face(1,2,7,mat);
        mesh.qface(2,8,7,13,mat,div).face(2,3,8,mat).qface(3,9,8,14,mat,div).face(3,4,9,mat);
        mesh.qface(17,11,12,6,mat,div).face(17,16,11,mat).qface(16,10,11,5,mat,div).face(16,15,10,mat);
        mesh.qface(15,14,10,9,mat,div).face(15,19,14,mat).qface(19,13,14,8,mat,div).face(19,18,13,mat);
        mesh.qface(18,12,13,7,mat,div).face(18,17,12,mat).qface(16,18,15,19,mat,div).face(16,17,18,mat);
        return mesh.updateFaces(true,179);
    }
    
    static public function icosahedron(mesh:Mesh, size:Number, mat:int=0) : Mesh {
        var a:Number=size*0.276393202, b:Number=size*0.447213595, c:Number=size*0.525731112, 
            d:Number=size*0.723606798, e:Number=size*0.850650808;
        mesh.vertices.push(0,size,0, 0,b,b+b, e,b,a, c,b,-d, -c,b,-d, -e,b,a);
        mesh.vertices.push(e,-b,-a, c,-b,d, -c,-b,d, -e,-b,-a, 0,-b,-b-b, 0,-size,0);
        mesh.qface(0,2,1,7,mat).qface(0,3,2,6,mat).qface(0,4,3,10,mat).qface(0,5,4,9,mat).qface(0,1,5,8,mat);
        mesh.qface(1,7,8,11,mat).qface(2,6,7,11,mat).qface(3,10,6,11,mat).qface(4,9,10,11,mat).qface(5,8,9,11,mat);
        return mesh.updateFaces(true);
    }
    
    static public function sphere(mesh:Mesh, size:Number, mat:int=0) : Mesh {
        return icosahedron(mesh, size, mat);
    }
}


// Structure Synth
//----------------------------------------------------------------------------------------------------
class StructureSynth {
    private var _mesh:Mesh;
    private var _rules:* = new Object();
    private var _depthLimit:int, _objectsLimit:int;
    private var _maxDepth:int, _maxObjects:int;
    private var _depth:int, _objects:int;
    private var _core:Render3D = new Render3D();
    private var _rootSequence:SSRuleSequence = new SSRuleSequence(new Vector.<SSRuleCaller>());
    static private var _rexContent:RegExp = /((\d+)[\s*]*)?\{(.*?)\}\s*|([^{},\s]+)\s*/g;
    static private var _rexOption :RegExp = /([a-zA-Z]+|>)[\s=:()]*([\-\d.]+|\w+)/g;
    static private var _rexRootOpt:RegExp = /(set)?[\s=:()]*([a-z]+)[\s=:()]*([\-\d.]+)/g;
    static private var _rexOperate:RegExp = /(r?[x-z]|s)([\-\d.\s,:=()]*)/g;
    
    /** constructor. do nothing */
    function StructureSynth(depthLimit:int=512, objectsLimit:int=4096) {
        _depthLimit = depthLimit;
        _objectsLimit = objectsLimit;
    }
    
    /** register primitive */
    public function primitive(name:String, mesh:Mesh) : StructureSynth {
        if (!(name in _rules)) _rules[name] = new SSRule(name);
        _rules[name].newMesh(mesh);
        return this;
    }
    
    /** register rule */
    public function rule(name:String, option:String, content:String) : StructureSynth {
        var opt:* = new Object(), res:*;
        res = _rexOption.exec(option);
        while (res) {
            opt[res[1]] = res[2];
            res = _rexOption.exec(option);
        }
        if (!(name in _rules)) _rules[name] = new SSRule(name);
        _rules[name].newRule(parseContent(new Vector.<SSRuleCaller>(), content), opt);
        return this;
    }
    
    /** register root rule */
    public function root(option:String, content:String, initialize:Boolean=true) : StructureSynth {
        if (initialize) {
            _rootSequence.callers.length = 0;
            _maxDepth = _depthLimit;
            _maxObjects = _objectsLimit;
        }
        var opt:* = new Object(), res:*;
        res = _rexRootOpt.exec(option);
        while (res) {
            switch(res[2]) {
            case "maxdepth":   case "md":   _maxDepth   = int(res[3]); break;
            case "maxobjects": case "mo":   _maxObjects = int(res[3]); break;
            case "background": case "seed":  break;
            }
            res = _rexRootOpt.exec(option);
        }
        _rootSequence.callers = parseContent(_rootSequence.callers, content);
        return this;
    }

    /** execute */
    public function exec(mesh:Mesh) : Mesh {
        _mesh = mesh;
        for each (var rule:SSRule in _rules) rule.init();
        _depth = _objects = 0;
        _core.id();
        _exec(_rootSequence);
        return mesh;
    }
    
    /** parse contents of rule. */
    static public function parseContent(rcList:Vector.<SSRuleCaller>, content:String) : Vector.<SSRuleCaller> {
        var res:*, operations:Array = [];
        res = _rexContent.exec(content);
        while (res) {
            if (res[3]) {
                operations.unshift(new SSOperation(res[2]||1, parseOperation(new Matrix3D(), res[3])));
            } else if (res[4]) {
                rcList.push(new SSRuleCaller(res[4], operations));
                operations = [];
            }
            res = _rexContent.exec(content);
        }
        return rcList;
    }
    
    /** parse matrix opreations. */
    static public function parseOperation(matrix:Matrix3D, operation:String) : Matrix3D {
        var res:*, param:Array, p0:Number, p1:Number, p2:Number;
        res = _rexOperate.exec(operation);
        while(res) {
            param = res[2].match(/[\-\d.]+/g);
            if (param) {
                p0 = Number(param[0]);
                switch (res[1]) {
                case 'x':  matrix.prependTranslation(p0,0,0); break;
                case 'y':  matrix.prependTranslation(0,p0,0); break;
                case 'z':  matrix.prependTranslation(0,0,p0); break;
                case 'rx': matrix.prependRotation(p0, Vector3D.X_AXIS); break;
                case 'ry': matrix.prependRotation(p0, Vector3D.Y_AXIS); break;
                case 'rz': matrix.prependRotation(p0, Vector3D.Z_AXIS); break;
                case 's':
                    p1 = (param.length<2) ? p0 : Number(param[1]),
                    p2 = (param.length<3) ? p1 : Number(param[2]);
                    matrix.prependScale(p0, p1, p2);
                    break;
                case 'm':
                    if (param.length >= 9) {
                        matrix.prepend(new Matrix3D(Vector.<Number>([
                            Number(param[0]), Number(param[1]), Number(param[2]), 0,
                            Number(param[3]), Number(param[4]), Number(param[5]), 0,
                            Number(param[6]), Number(param[7]), Number(param[8]), 0,
                            0,0,0,1
                        ])));
                    }
                    break;
                }
            }
            res = _rexOperate.exec(operation);
        }
        return matrix;
    }
    
    private function _exec(seq:SSRuleSequence) : void {
        if (_depth < _maxDepth) {
            _depth++;
            if (seq.depth < seq.maxdepth) {
                seq.depth++;
                for each (var rc:SSRuleCaller in seq.callers) $s(rc, rc.operations.length-1);
                --seq.depth;
            } else {
                if (seq.finalRuleName) $r(seq.finalRuleName);
            }
            --_depth;
        }
        function $s(rc:SSRuleCaller, index:int) : void {
            var imax:int      = rc.operations[index].repeat, 
                mat :Matrix3D = rc.operations[index].matrix;
            _core.push();
            for (var i:int=0; i<imax; i++) {
                _core.mult(mat);
                if (index) $s(rc, index-1);
                else $r(rc.ruleName);
            }
            _core.pop();
        }
        function $r(ruleName:String) : void {
            var rule:SSRule = _rules[ruleName];
            if (rule.mesh) {
                if (++_objects == _maxObjects) _depth = int.MAX_VALUE;
                _core.project(rule.mesh);
                _mesh.put(rule.mesh);
            } else {
                _exec(rule.getSequence());
            }
        }
    }
}

class SSRule {
    public var name:String;
    public var mesh:ProjectionMesh = null;
    private var _totalWeight:Number = 0;
    private var _sequences:Vector.<SSRuleSequence> = new Vector.<SSRuleSequence>();
    
    function SSRule(name:String) { this.name = name; }
    
    public function newMesh(mesh:Mesh) : void {
        this.mesh = new ProjectionMesh(mesh);
    }
    
    public function newRule(callers:Vector.<SSRuleCaller>, option:*) : void {
        var seq:SSRuleSequence = new SSRuleSequence(callers, option);
        _sequences.push(seq);
        _totalWeight += seq.weight;
        mesh = null;
    }

    public function init() : void { 
        for each (var seq:SSRuleSequence in _sequences) seq.depth = 0;
    }
    
    public function getSequence() : SSRuleSequence {
        var w:Number = 0, rand:Number = Math.random() * _totalWeight;
        for each (var seq:SSRuleSequence in _sequences) {
            w += seq.weight;
            if (rand <= w) return seq;
        }
        throw new Error("no sequences in rule:" + name);
    }
}

class SSRuleSequence {
    public var callers:Vector.<SSRuleCaller>;
    public var weight:Number;
    public var maxdepth:int;
    public var finalRuleName:String;
    public var depth:int = 0;
    
    function SSRuleSequence(callers:Vector.<SSRuleCaller>, option:*=undefined) {
        option = option || new Object();
        this.callers = callers;
        this.weight = option["w"] || option["weight"] || 1;
        this.maxdepth = option["md"] || option["maxdepth"] || int.MAX_VALUE;
        this.finalRuleName = option[">"] || null;
    }
}

class SSRuleCaller {
    public var ruleName:String, operations:Vector.<SSOperation>;
    function SSRuleCaller(name:String, ope:Array) { 
        ruleName = name;
        if (ope.length == 0) ope = [new SSOperation(1, new Matrix3D())];
        operations = Vector.<SSOperation>(ope);
    }
}

class SSOperation {
    public var repeat:int, matrix:Matrix3D;
    function SSOperation(rep:int, mat:Matrix3D) { repeat=rep; matrix=mat; }
}

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
        if (!mesh.screenProjected) {
            Utils3D.projectVectors(_projectionMatrix, mesh.verticesOnWorld, vout, mesh.base.texCoord);
            mesh.screenProjected = true;
        }
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
    
    /** render wireframe */
    public function renderWire(mesh:ProjectionMesh, color:uint, alpha:Number=1, width:Number=1) : Render3D {
        var idx:int, vout:Vector.<Number> = mesh.verticesOnScreen;
        if (!mesh.screenProjected) {
            Utils3D.projectVectors(_projectionMatrix, mesh.verticesOnWorld, vout, mesh.base.texCoord);
            mesh.screenProjected = true;
        }
        graphics.clear();
        graphics.lineStyle(width, color, alpha);
        for each (var wire:Wire in mesh.base.wires) {
            idx = wire.i0<<1;
            _data[0] = vout[idx]; idx++;
            _data[1] = vout[idx];
            idx = wire.i1<<1;
            _data[2] = vout[idx]; idx++;
            _data[3] = vout[idx];
            graphics.drawPath(_cmdWire, _data);
        }
        return this;
    }
    
    /** render with texture */
    public function renderTexture(mesh:ProjectionMesh, texture:BitmapData) : Render3D {
        var vout:Vector.<Number> = mesh.verticesOnScreen;
        if (!mesh.screenProjected) {
            Utils3D.projectVectors(_projectionMatrix, mesh.verticesOnWorld, vout, mesh.base.texCoord);
            mesh.screenProjected = true;
        }
        graphics.clear();
        graphics.beginBitmapFill(texture, null, false, true);
        graphics.drawTriangles(vout, mesh.indicesProjected, mesh.base.texCoord);
        graphics.endFill();
        return this;
    }

    /** render depth buffer */
    public function renderDepth(mesh:ProjectionMesh) : Render3D {
        var i:int, imax:int = mesh.vertexImax, 
            nearZ:Number = (_clippingZ < mesh.nearZ) ? _clippingZ : mesh.nearZ,
            r:Number = 1/(mesh.farZ - nearZ), duvt:Vector.<Number> = _depthUVT;
        duvt.length = 0;
        for (i=2; i<imax; i+=3) duvt.push((mesh.verticesOnWorld[i]-nearZ)*r, 0, 0);
        Utils3D.projectVectors(_projectionMatrix, mesh.verticesOnWorld, mesh.verticesOnScreen, duvt);
        graphics.clear();
        graphics.beginBitmapFill(_depthMap, null, false, true);
        graphics.drawTriangles(mesh.verticesOnScreen, mesh.indicesProjected, duvt);
        graphics.endFill();
        return this;
    }
    private var _depthUVT:Vector.<Number> = new Vector.<Number>();
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

/** Line */
class Wire {
    public var index:int, i0:int, i1:int;
    static private var _freeList:Vector.<Wire> = new Vector.<Wire>();
    static public function free(wire:Wire) : void { _freeList.push(wire); }
    static public function alloc(index:int, i0:int, i1:int) : Wire { 
        var w:Wire = _freeList.pop() || new Wire();
        w.index=index; w.i0=i0; w.i1=i1;
        return w;
    }
}

/** Mesh */
class Mesh {
    public var materials:Vector.<Material>;                 // material list
    public var vertices:Vector.<Number>;                    // vertex
    public var verticesCount:int;                           // vertex count
    public var texCoord:Vector.<Number>;                    // texture coordinate
    public var faces:Vector.<Face> = new Vector.<Face>();   // face list
    public var wires:Vector.<Wire> = new Vector.<Wire>();   // wireframe list
    
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
    
    /** register wire */
    public function wire(i0:int, i1:int) : Mesh {
        wires.push(Wire.alloc(wires.length, i0, i1));
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
    public function updateFaces(createWire:Boolean = false, facetAngle:Number = 180) : Mesh {
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
        if (createWire) {
            var facetCos:Number = Math.cos((180-facetAngle)*57.29577951308232);
            for each (var f0:Face in faces) {
                _wire(f0, f0.i0, f0.i1);
                _wire(f0, f0.i1, f0.i2);
                if (f0.i3==-1) _wire(f0, f0.i2, f0.i0);
                else { _wire(f0, f0.i2, f0.i3); _wire(f0, f0.i3, f0.i0); }
            }
        }
        return this;
        
        function _wire(f0:Face, i0:int, i1:int) : void {
            var f1:Face = _findFace(i0, i1);
            if (f1==null || facetCos >= f0.normal.dotProduct(f1.normal)) {
                if (_findWire(i0, i1) == null) wire(i0, i1);
            }
        }
        function _findFace(i0:int, i1:int) : Face {
            for each (var f:Face in faces) {
                if ((f.i0==i0 && f.i1==i1) || (f.i0==i1 && f.i1==i0) ||
                    (f.i1==i0 && f.i2==i1) || (f.i1==i1 && f.i2==i0)) return f;
                if (f.i3==-1) if ((f.i2==i0 && f.i0==i1) || (f.i2==i1 && f.i0==i0)) return f;
                else if ((f.i2==i0 && f.i3==i1) || (f.i2==i1 && f.i3==i0) ||
                         (f.i3==i0 && f.i0==i1) || (f.i3==i1 && f.i0==i0)) return f;
            }
            return null;
        }
        function _findWire(i0:int, i1:int) : Wire {
            for each (var w:Wire in wires) {
                if ((w.i0==i0 && w.i1==i1) || (w.i0==i1 && w.i1==i0)) return w;
            }
            return null;
        }
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

