// The gradation colors are refered from psyrak's BumpyPlanet 
// and nemu90kWw's 水平線.
// arrows or [wasd] to move...
//------------------------------------------------------------
package
{
    import flash.display.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.utils.*;

    [SWF(width='465', height='465', backgroundColor='#103860', frameRate='30')]
    public class main extends Sprite
    {
        private var _base:Sprite = new Sprite();
        
        function main() {
            _key = new KeyMapper(stage);
            _key.map(0,37,65).map(1,38,87).map(2,39,68).map(3,40,83).map(4,17,90,78,16,88,77);
            
            _base.x = 232.5;
            _base.y = 232.5;
            addChild(_base);
            
            _landscape.rotationX = -85;
            _landscape.scaleX = 10;
            _landscape.scaleY = 8;
            _landscape.x = -1024-_base.x;
            _landscape.y = 280-_base.y;
            _landscape.z = 1800;
            _sky.scaleX = 5;
            _sky.scaleY = 5;
            _sky.x = -1440-_base.x;
            _sky.y = -1400-_base.y;
            _sky.z = 1800;
            _base.addChild(_landscape);
            _base.addChild(_sky);
            
            _pitch = 0;
            _roll = 0;
            
            addEventListener("enterFrame", _onEnterFrame);
        }

        private function _onEnterFrame(e:Event) : void {
            var inkey:uint = _key.keys;
            _roll  += ((inkey & 1)      - ((inkey & 4)>>2))*5 - _roll*0.1;
            _pitch += (((inkey & 2)>>1) - ((inkey & 8)>>3))*1 - _pitch*0.1;
            _base.rotationZ = _roll;
            _base.rotationX = _pitch;
        }
    }
}


// internal variables
var _key:KeyMapper;
var _landscape:Landscape = new Landscape(256, 256);
var _sky:Sky = new Sky();
var _pitch:Number, _roll:Number;

import flash.display.*;
import flash.geom.*;
import flash.events.*;
import flash.filters.*;
import flash.utils.*;

class KeyMapper {
    public  var keys:uint = 0;
    private var _map:Vector.<int> = new Vector.<int>(256, true);
    
    function KeyMapper(stage:Stage) : void { 
        for (var i:int=0; i<128; i++) _map[i]=32;
        stage.addEventListener("keyDown", function(e:KeyboardEvent) : void {
            keys |= 1<<_map[e.keyCode];
        });
        stage.addEventListener("keyUp",   function(e:KeyboardEvent) : void {
            keys &= ~(1<<_map[e.keyCode]);
        });
    }
    
    public function map(bit:int, ...args) : KeyMapper {
        for (var i:int=0; i<args.length; i++) _map[args[i]] = bit;
        return this;
    }
}

class Sky extends Shape {
    // This color gradation is refered from nemu90kWw's 水平線
    // http://wonderfl.kayac.com/code/2b527a2efe155b7f69330822a3c7f7733ab6ea7e
    public var gradation:* = {
        color:[0x103860,0x4070B8,0x60B0E0,0xD0F0F0,0x0033c0,0x0033c0], 
        alpha:[100, 100, 100, 100, 100, 0], 
        ratio:[0, 128, 192, 216, 224, 255]
    };
    function Sky() {
        var mat:Matrix = new Matrix();
        mat.createGradientBox(665, 380, Math.PI/2);
        graphics.beginGradientFill("linear", gradation.color, gradation.alpha, gradation.ratio, mat);
        graphics.drawRect(0, 0, 665, 380);
        graphics.endFill();
    }
}

class Landscape extends Bitmap {
    // This color gradation is refered from psyrak's BumpyPlanet 
    // http://wonderfl.kayac.com/code/d79cd85845773958620f42cb3e6cb363c2020c73
    public var gradation:* = {
        color:[0x000080,0x0066ff,0xcc9933,0x00cc00,0x996600,0xffffff], 
        alpha:[100, 100, 100, 100, 100, 100], 
        ratio:[0, 96, 96, 128, 168, 224]
    };
    public var pixels:BitmapData, texture:BitmapData, rect:Rectangle;
    function Landscape(w:int, h:int) {
        texture = new BitmapData(w*2, h*2, false, 0);
        pixels = new BitmapData(w, h, false, 0);
        rect = new Rectangle(0, 0, w, h);
        super(pixels);
        
        // height map
        var hmap:BitmapData = new BitmapData(w, h, false, 0);
        hmap.perlinNoise(w*0.5, h*0.5, 10, Math.random()*0xffffffff, true, false, 0, true);
        hmap.colorTransform(hmap.rect, new ColorTransform(1.5, 1.5, 1.5, 1, -64, -64, -64, 0));
        
        // texture
        var mapR:Array=new Array(256), mapG:Array=new Array(256), mapB:Array=new Array(256);
        var gmap:BitmapData = new BitmapData(256,1,false,0), render:Shape = new Shape(), mat:Matrix = new Matrix();
        mat.createGradientBox(256,1,0,0,0);
        render.graphics.clear();
        render.graphics.beginGradientFill("linear", gradation.color, gradation.alpha, gradation.ratio, mat);
        render.graphics.drawRect(0,0,256,1);
        render.graphics.endFill();
        gmap.draw(render);
        for (var i:int=0; i<256; i++) {
            var col:uint = gmap.getPixel(i, 0);
            mapR[i] = col & 0xff0000;
            mapG[i] = col & 0x00ff00;
            mapB[i] = col & 0x0000ff;
        }
        gmap.dispose();
        mat.identity();
        texture.paletteMap(hmap, hmap.rect, hmap.rect.topLeft, mapR, mapG, mapB);

        // shading
        var smap:BitmapData = new BitmapData(w, h, false, 0);
        smap.applyFilter(hmap, hmap.rect, hmap.rect.topLeft, new ConvolutionFilter(3,3,[-1,-1,0,-1,0,1,0,1,1],1,0,true,true));
        texture.draw(smap, null, new ColorTransform(4, 4, 4, 1, 160, 160, 160, 0), "multiply");
        
        pt.x = w; pt.y = h; texture.copyPixels(texture, hmap.rect, pt);
        pt.x = 0; pt.y = h; texture.copyPixels(texture, hmap.rect, pt);
        pt.x = w; pt.y = 0; texture.copyPixels(texture, hmap.rect, pt);
        pt.x = 0; pt.y = 0;
        addEventListener("enterFrame", _onEnterFrame);
    }
    
    private var pt:Point = new Point();
    private function _onEnterFrame(e:Event) : void {
        rect.x = (rect.x-_roll*0.1) & (pixels.width-1);
        rect.y = (rect.y-9) & (pixels.height-1);
        pixels.copyPixels(texture, rect, pt);
    }
}

