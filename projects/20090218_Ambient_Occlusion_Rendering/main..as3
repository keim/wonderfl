// Ambient Occlusion Bench Flash10 porting
//   Original version of AO bench was written by Syoyo Fujita.
//     http://lucille.atso-net.jp/aobench/
//   In original Flash10 porting, it takes 7 times slower than the Proce55ing.
//   (refer from http://lucille.atso-net.jp/blog/?p=638).
//   And now, it seems to be same speed as the Proce55ing does.
//----------------------------------------------------------------------
package {
    import flash.display.*;
    import flash.text.*;
    import flash.events.*;
    
    [SWF(frameRate = "1000", backgroundColor = "#808080")]
    public class main extends Sprite {
        private var _tf:TextField = new TextField();
        private var _screen:BitmapData = new BitmapData(WIDTH, HEIGHT, false, 0xffffff);
        private var _renderY:int;
        
        function main() { 
            _tf.autoSize = 'left';
            _tf.htmlText = "<font color='#ffffff'>Rendering...</font>";
            addChild(_tf);
            with(addChild(new Bitmap(_screen))){ x = y = 104.5; }
            
            _renderY = 0;
            
            addEventListener("enterFrame", _startRender);
        }
        
        private function _startRender(e:Event) : void {
            // rendering
            render.rasterRendering(_renderY);
            
            // copy pixels
            _screen.lock();
            for (var x:int=0; x<WIDTH; x++) _screen.setPixel(x, _renderY, render.output[x]);
            _screen.unlock();
            
            // increment
            _renderY++;
            if (_renderY == 256) {
                // finish rendering
                _tf.htmlText = "<font color='#ffffff'>Rendering time : " + String(render.renderingTime/1000) + "[sec]</font>";
                removeEventListener("enterFrame", _startRender);
            }
        }
    }
}




import flash.display.*;
import flash.geom.*;
import flash.utils.getTimer;


// global variables
//--------------------------------------------------------------------------------
const WIDTH :int = 256;
const HEIGHT:int = 256;
const NSUBSAMPLES:int = 2;
const NAO_SAMPLES:int = 8;

var render:Render = new Render();


// structures
//--------------------------------------------------------------------------------
class Isect {
    public var t:Number = 0;
    public var p:Vector3D = new Vector3D();
    public var n:Vector3D = new Vector3D();
    public var hit:int = 0;
}

class Ray {
    public var org:Vector3D = new Vector3D();
    public var dir:Vector3D = new Vector3D();
}

class Sphere {
    public var center:Vector3D;
    public var radius2:Number;
    function Sphere(center:Vector3D, radius:Number) {
        this.center = center;
        this.radius2 = radius*radius;
    }
}

class Plane {
    public var p:Vector3D;
    public var n:Vector3D;
    public var pn:Number;
    function Plane(p:Vector3D, n:Vector3D) {
        this.p = p;
        this.n = n;
        this.pn = n.x*p.x + n.y*p.y + n.z*p.z;
    }
}




// render
//--------------------------------------------------------------------------------
class Render {
// variables
//--------------------------------------------------
    public var output:Vector.<uint>;
    public var renderingTime:int;

    private var spheres:Vector.<Sphere> = new Vector.<Sphere>(3, true);
    private var plane:Plane;
    
    
// constructor
//--------------------------------------------------
    function Render() {
        _initScene();
        renderingTime = 0;
        output = new Vector.<uint>(WIDTH, true);
    }
    
    
// rendering
//--------------------------------------------------
    public function rasterRendering(y:int) : void {
        var t:int = getTimer();
        _render(output, WIDTH, HEIGHT, y);
        renderingTime += getTimer() - t;
    }

    
// privates
//--------------------------------------------------
    // initialize scene
    private function _initScene() : void {
        spheres[0] = new Sphere(new Vector3D(-2.0, 0.0, -3.5), 0.5);
        spheres[1] = new Sphere(new Vector3D(-0.5, 0.0, -3.0), 0.5);
        spheres[2] = new Sphere(new Vector3D( 1.0, 0.0, -2.2), 0.5);
        plane      = new Plane(new Vector3D(0.0, -0.5, 0.0), new Vector3D(0.0, 1.0, 0.0));
    }
    
    
    // render
    private var ray:Ray = new Ray();
    private var isect:Isect = new Isect();
    private function _render(line:Vector.<uint>, w:int, h:int, y:int) : void {
        var idx:int, x:int, u:int, v:int, du:Number, dv:Number, pixel:uint, ao:Vector3D, 
            hw :Number = w*0.5, hh :Number = h*0.5, 
            ihw:Number = 1/hw,  ihh:Number = 1/hh,
            step:Number = 1/NSUBSAMPLES, 
            occlusionPerPixel:Number = 1/(NSUBSAMPLES*NSUBSAMPLES),
            color:Vector3D = new Vector3D();

        // scan all pixels
        idx = 0;
        for (x = 0; x < w; x++) {
            // initialize pixel color
            color.x = 0;
            color.y = 0;
            color.z = 0;
            
            // sub samplings
            for (v = 0, dv = 0; v < NSUBSAMPLES; v++, dv += step) {
                for (u = 0, du = 0; u < NSUBSAMPLES; u++, du += step) {
                    // initialize ray vectors
                    ray.org.x = 0.0;
                    ray.org.y = 0.0;
                    ray.org.z = 0.0;
                    ray.dir.x =  (x + du - hw) * ihw;
                    ray.dir.y = -(y + dv - hh) * ihh;
                    ray.dir.z = -1.0;
                    ray.dir.normalize();

                    // check ray intersections
                    isect.p.x = isect.p.y = isect.p.z = 0.0;
                    isect.n.x = isect.n.y = isect.n.z = 0.0;
                    isect.t   = 1.0e+17;
                    isect.hit = 0;
                    _intersectBySphere(isect, ray, spheres[0]);
                    _intersectBySphere(isect, ray, spheres[1]);
                    _intersectBySphere(isect, ray, spheres[2]);
                    _intersectByPlane (isect, ray, plane);
                    // when the ray is intersected, calculate ambient occlusion color.
                    if (isect.hit) {
                        color.incrementBy(_ambientOcclusion(isect));
                    }
                }
            }
            
            // calculate gray scale
            color.scaleBy(occlusionPerPixel);
            pixel = 0xff000000;
            pixel |=  (color.x >= 1) ? 255 : (color.x <= 0) ? 0 : int(color.x * 255);
            pixel |= ((color.y >= 1) ? 255 : (color.y <= 0) ? 0 : int(color.x * 255)) << 8;
            pixel |= ((color.z >= 1) ? 255 : (color.z <= 0) ? 0 : int(color.x * 255)) << 16;
            output[idx] = pixel;
            
            // increment index
            idx++;
        }
    }
    
    
    // calculate ambient occlusion
    private var aoRay:Ray = new Ray();
    private var aoIsect:Isect = new Isect();
    private var aoColor:Vector3D = new Vector3D();
    private var basis0:Vector3D = new Vector3D();
    private var basis1:Vector3D = new Vector3D();
    private var basis2:Vector3D = new Vector3D();
    private function _ambientOcclusion(isect:Isect) : Vector3D {
        var i:int, j:int, th:Number, ph:Number,
            x:Number,  y:Number,  z:Number,
            rx:Number, ry:Number, rz:Number,
            ntheta:int = NAO_SAMPLES,
            nphi:int   = NAO_SAMPLES,
            occlusionPerSample:Number = 1 / (ntheta*nphi),
            eps:Number = 0.0001,
            occlusion:Number = 1.0;
        
        // calculate transform matrix from local to global.
        // the "local" coordinate is based on the normal vector at intersected point.
        basis2 = isect.n;
        basis1.x = 0.0;
        basis1.y = 0.0;
        basis1.z = 0.0;
             if ((isect.n.x < 0.6) && (isect.n.x > -0.6)) basis1.x = 1.0;
        else if ((isect.n.y < 0.6) && (isect.n.y > -0.6)) basis1.y = 1.0;
        else if ((isect.n.z < 0.6) && (isect.n.z > -0.6)) basis1.z = 1.0;
        else                                              basis1.x = 1.0;
        vcross(basis0, basis1, basis2).normalize();
        vcross(basis1, basis2, basis0).normalize();

        // calculate the origin of the second ray
        aoRay.org.x = isect.p.x + eps * isect.n.x;
        aoRay.org.y = isect.p.y + eps * isect.n.y;
        aoRay.org.z = isect.p.z + eps * isect.n.z;
        
        // calculate the ambient occlusion at intersected point
        for (j = 0; j < ntheta; j++) {
            for (i = 0; i < nphi; i++) {
                // calculate the direction of the second ray
                th = Math.sqrt(Math.random());
                ph = 6.283185307179586 * Math.random();
                x = Math.cos(ph) * th;
                y = Math.sin(ph) * th;
                z = Math.sqrt(1.0 - th * th);
                // transform second ray vector from local to global
                aoRay.dir.x = x * basis0.x + y * basis1.x + z * basis2.x;
                aoRay.dir.y = x * basis0.y + y * basis1.y + z * basis2.y;
                aoRay.dir.z = x * basis0.z + y * basis1.z + z * basis2.z;

                // check second ray intersections 
                aoIsect.p.x = aoIsect.p.y = aoIsect.p.z = 0.0;
                aoIsect.n.x = aoIsect.n.y = aoIsect.n.z = 0.0;
                aoIsect.t   = 1.0e+17;
                aoIsect.hit = 0;
                _intersectBySphere(aoIsect, aoRay, spheres[0]);
                _intersectBySphere(aoIsect, aoRay, spheres[1]);
                _intersectBySphere(aoIsect, aoRay, spheres[2]);
                _intersectByPlane (aoIsect, aoRay, plane);
                // when the second ray is intersected, increase the occlusion.
                if (aoIsect.hit) occlusion -= occlusionPerSample;
            }
        }

        // return result
        aoColor.x = occlusion;
        aoColor.y = occlusion;
        aoColor.z = occlusion;
        return aoColor;
        
        // cross product
        function vcross(c:Vector3D, v0:Vector3D, v1:Vector3D) : Vector3D {
            c.x = v0.y * v1.z - v0.z * v1.y;
            c.y = v0.z * v1.x - v0.x * v1.z;
            c.z = v0.x * v1.y - v0.y * v1.x;
            return c;
        }
    }
    
    
    // check ray intersection by sphere
    private function _intersectBySphere(isect:Isect, ray:Ray, sph:Sphere) : void {
        var rsx:Number = ray.org.x - sph.center.x,
            rsy:Number = ray.org.y - sph.center.y,
            rsz:Number = ray.org.z - sph.center.z,
            B:Number = rsx*ray.dir.x + rsy*ray.dir.y + rsz*ray.dir.z,
            C:Number = rsx*rsx + rsy*rsy + rsz*rsz - sph.radius2,
            D:Number = B * B - C;

        // when the ray is intersected by the sphere,
        if (D > 0.0) {
            var t:Number = -B - Math.sqrt(D);
            
            if ((t > 0.0) && (t < isect.t)) {
                // calculate cross point and normal vector.
                isect.t = t;
                isect.hit = 1;
                
                isect.p.x = ray.org.x + ray.dir.x * t;
                isect.p.y = ray.org.y + ray.dir.y * t;
                isect.p.z = ray.org.z + ray.dir.z * t;

                isect.n.x = isect.p.x - sph.center.x;
                isect.n.y = isect.p.y - sph.center.y;
                isect.n.z = isect.p.z - sph.center.z;
                isect.n.normalize();
            }
        }
    }
    

    // check ray intersection by plane
    private function _intersectByPlane(isect:Isect, ray:Ray, pln:Plane) : void {
        var v:Number = pln.n.x*ray.dir.x + pln.n.y*ray.dir.y + pln.n.z*ray.dir.z;
        
        // when parallel with plane
        if (v>-1.0e-17 && v<1.0e-17) return;
        
        var t:Number = -(pln.n.x*ray.org.x + pln.n.y*ray.org.y + pln.n.z*ray.org.z - pln.pn) / v;

        // when the ray is intersected by the plane,
        if ((t > 0.0) && (t < isect.t)) {
            // calculate cross point and normal vector.
            isect.t = t;
            isect.hit = 1;
            
            isect.p.x = ray.org.x + ray.dir.x * t;
            isect.p.y = ray.org.y + ray.dir.y * t;
            isect.p.z = ray.org.z + ray.dir.z * t;

            isect.n.x = pln.n.x;
            isect.n.y = pln.n.y;
            isect.n.z = pln.n.z;
        }
    }
}

