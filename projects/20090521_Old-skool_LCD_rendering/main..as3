// Old-skool LCD rendering
//   click to display original image
//--------------------------------------------------
package {
    import flash.display.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.text.*;


    [SWF(width="465", height="465", backgroundColor="0", frameRate="10")]
    public class main extends Sprite {
        private var _lcd:LCDRender;
        private var _screen:BitmapData = new BitmapData(384, 384, false, 0xffffff);
        private var _bitmap:Bitmap = new Bitmap(_screen);
        private var _shape:Shape = new Shape();
        private var _vbuf:Vector.<Number> = new Vector.<Number>();
        private var _vout:Vector.<Number> = new Vector.<Number>();
        private var _uvt:Vector.<Number> = new Vector.<Number>();
        private var _ibuf:Vector.<int>    = new Vector.<int>();
        private var _projector:Matrix3D = new Matrix3D();
        private var _matrix:Matrix3D = new Matrix3D();
        private var _centering:Matrix = new Matrix(1,0,0,1,192,210);
        private var _rotation:Number = 20;
        private var _text:TextField = new TextField();
        
        function main() {
            // create cube
            for (var i:int=0; i<8; i++) {
                _vbuf.push(((i<<3)&32)-16, ((i<<4)&32)-16, ((i<<5)&32)-16);
                for (var j:int=0; j<3; j++) 
                    if ((((i>>2)+(i>>1)+i)&1)==0 && (i^(1<<j))<8) _ibuf.push(i, i^(1<<j));
            }
            _vout.length = _vbuf.length * 2 / 3;
            _uvt.length = _vbuf.length * 3;
            
            // create projector
            var proj:PerspectiveProjection = new PerspectiveProjection();
            proj.fieldOfView = 60;
            _projector = proj.toMatrix3D();
            
            // intializing
            addEventListener("enterFrame", _onEnterFrame);
            stage.addEventListener("click", _onClick);
            _text.autoSize = "left";
            _text.htmlText = "<font face='_sans' color='#ffffff' size='42px'><b><u>OLD-SKOOL LCD</u></b></font>"
            
            // LCDRender を addChild
            _lcd = new LCDRender();
            _bitmap.x = 40;
            _bitmap.y = 40;
            _bitmap.visible = false;
            addChild(_bitmap);
            addChild(_lcd);
        }

        private function _onEnterFrame(e:Event) : void {
            // rendering cube on _screen
            _rotation += 3;
            _matrix.identity();
            _matrix.appendRotation(_rotation, new Vector3D(0.707,0,0.707));
            _matrix.appendTranslation(0, 0, 5);
            _matrix.append(_projector);
            Utils3D.projectVectors(_matrix, _vbuf, _vout, _uvt);
            _shape.graphics.clear();
            _shape.graphics.lineStyle(3, 0xffffff);
            for (var i:int=0; i<_ibuf.length; i+=2) {
                var i0:int = _ibuf[i]<<1, i1:int = _ibuf[i+1]<<1;
                _shape.graphics.moveTo(_vout[i0], _vout[i0+1]);
                _shape.graphics.lineTo(_vout[i1], _vout[i1+1]);
            }
            _screen.fillRect(_screen.rect, 0);
            _screen.draw(_shape, _centering);
            _screen.draw(_text);
            
            // LCDRender.renderを呼ｄ双す．
            _lcd.render(_screen);
        }

        private function _onClick(e:MouseEvent) : void {
            _lcd.visible = !_lcd.visible;
            _bitmap.visible = !_bitmap.visible;
        }
    }
}


import flash.display.*;
import flash.geom.*;
import flash.filters.*;


/**
 * Display the BitmapData like a old-school LCD display.
 */
class LCDRender extends Bitmap {
    private var _screen:BitmapData = new BitmapData(384, 384, true, 0);
    private var _display:BitmapData = new BitmapData(400, 400, false, 0);
    private var _cls:BitmapData = new BitmapData(400, 400, false, 0);
    private var _matS2D:Matrix = new Matrix(1,0,0,1,8,8);
    private var _shadow:DropShadowFilter = new DropShadowFilter(4, 45, 0, 0.6, 6, 6);
    private var _data:BitmapData = new BitmapData(96, 96, false, 0);
    private var _residueMap:Vector.<Number> = new Vector.<Number>(9216, true);
    private var _toneFilter:uint;
    private var _dotColor:uint;
    private var _residue:Number;
    private var dot:Rectangle = new Rectangle(0,0,3,3);
    private var mat:Matrix = new Matrix();
    
    /**
     *  Create a new instance of the LCDBitmapOldSkool with setting.
     *  @param bit The bit count of shades of gray scale. the bit=2 sets 4 shades of gray scale.
     *  @param backColor The background color of display.
     *  @dot0Color The color for the pixel of 0.
     *  @dot0Color The color for the pixel of 1.
     *  @residue The ratio of residual image for 1 update.
     */
    function LCDRender(bit:int=2, 
                       backColor:uint = 0xb0c0b0, 
                       dot0Color:uint = 0xb0b0b0, 
                       dot1Color:uint = 0x000000, 
                       residue:Number = 0.5) {
        _toneFilter = 0xff00 >> bit;
        _dotColor = dot1Color;
        _cls.fillRect(_cls.rect, backColor);
        _residue = residue;
        for (dot.x=8; dot.x<392; dot.x+=4)
            for (dot.y=8; dot.y<392; dot.y+=4)
                _cls.fillRect(dot, dot0Color);
        super(_display);
        x = 32;
        y = 32;
    }
    
    
    /** 
     *  Rendering LCD Bitmap.
     *  @param source Source BitmapData rendering on the old-school LCD display.
     */
    public function render(src:BitmapData) : void {
        var x:int, y:int, rgb:uint, mask:uint, i:int, r:Number=96/src.width;
        _data.lock();
        _screen.lock();
        mat.identity();
        mat.scale(r, r);
        _data.draw(src, mat, null, null, null, true);
        _screen.fillRect(_screen.rect, 0);
        for (i=0, dot.y=0, y=0; y<96; dot.y+=4, y++)
            for (dot.x=0, x=0; x<96; dot.x+=4, x++, i++) {
                rgb = _data.getPixel(x, y);
                rgb = ((((rgb>>18)&63)+((rgb>>9)&127)+((rgb>>3)&31)) & _toneFilter) + int(_residueMap[i]);
                mask = rgb & 0x100;
                rgb |= mask - (mask>>8);
                _residueMap[i] = (rgb&0xff) * _residue;
                if (rgb) _screen.fillRect(dot, (rgb<<24) | _dotColor);
            }
        _screen.applyFilter(_screen, _screen.rect, _screen.rect.topLeft, _shadow);
        _display.copyPixels(_cls, _cls.rect, _cls.rect.topLeft);
        _display.draw(_screen, _matS2D);
        _data.unlock();
        _screen.unlock();
    }
}



