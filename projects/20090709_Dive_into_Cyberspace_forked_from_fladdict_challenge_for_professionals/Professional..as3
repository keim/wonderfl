// forked from checkmate's fladdict challenge for professionals
/**
 * Theme:
 * Play with BitmapPatterBuilder.
 * Purpose of this trial is to find the possibility of the dot pattern.
 *
 * by Takayuki Fukatsu aka fladdict
 **/
package {
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.display.StageScaleMode;
    import flash.display.Shape;
    import flash.events.*;
    import flash.geom.*;
    
    public class Professional extends Sprite {
        private var alphabet:Array;
        private var alpCoord:Vector.<Point> = new Vector.<Point>();
        private var counter:int = 0;
        private var position:Vector3D = new Vector3D(0, 0, 0);
        private var angle:Number = 0;
        private var omega:Number = 0;
        private var matrix:Matrix = new Matrix();
        private var screen:BitmapData = new BitmapData(465, 465, false, 0);
        private var canvas:Shape = new Shape();
        private var field:BitmapData = new BitmapData(48, 48, true, 0);
        private var letter:BitmapData = new BitmapData(132, 8, true, 0);
        
        public function Professional() {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            alphabet = [_build("7c2221227c00"), _build("7f4949493600"), _build("3e4141412200"),                          // ABC
                        _build("7f4141423c00"), _build("7f4949494100"), _build("7f0909090100"), _build("3e4149493a00"),  // DEFG
                        _build("7f0808087f00"), _build("00417f410000"), _build("2040413f0100"), _build("7f0814224100"),  // HIJK
                        _build("7f4040404000"), _build("7f020c027f00"), _build("7f0408107f00"), _build("3e4141413e00"),  // LMNO
                        _build("7f0909090600"), _build("3e4151215e00"), _build("7f0919294600"), _build("264949493200"),  // PQRS
                        _build("01017f010100"), _build("3f4040403f00"), _build("1f2040201f00"), _build("1f601c601f00"),  // TUVW
                        _build("631408146300"), _build("070870080700"), _build("615149454300"), _build("000000000000")]; // XYZ
            for (var i:int=0; i<48; i++) {
                alpCoord.push(new Point(i*30%48, int(i*0.625)%6*8));
                field.copyPixels(alphabet[i%26], alphabet[0].rect, alpCoord[alpCoord.length-1]);
            }
            var a:Array = [22,4,11,2,14,12,4,26,19,14,26,2,24,1,4,17,18,15,0,2,4];
            for (i=0; i<21; i++) letter.copyPixels(alphabet[a[i]], alphabet[0].rect, new Point(i*6, 0));
            addChild(new Bitmap(screen));
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        private function onEnterFrame(e:Event) : void {
            var index:int=counter%26, speed:Number=counter*0.0002+0.005;
            for (var i:int=0; i<6; i++) {
                var scale:Number = 2/(1-position.z);
                matrix.identity();
                matrix.translate(-alpCoord[index].x-2.5, -alpCoord[index].y-3.5);
                matrix.scale(scale, scale);
                matrix.rotate(angle+=(omega*=0.998));
                matrix.translate((position.x*=0.998)+232.5, (position.y*=0.998)+232.5);
                _render(field, matrix);
                if ((position.z+=speed) >= 1) {
                    index = (++counter) % 26;
                    omega += (Math.random()-0.5)*0.01;
                    var range:Number = (counter>200) ? 0 : (200-counter)*0.5;
                    position.x = (Math.random()-0.5) * range;
                    position.y = (Math.random()-0.5) * range;
                    position.z = 0;
                }
            }
            if (Math.random()<(speed-0.01)*20) _render(letter, null);
        }
        
        private function _build(hex:String) : BitmapData {
            var x:int, y:int, pat:int, pixels:Array=[[],[],[],[],[],[],[],[]];
            for (x=0; x<6; x++)
                for (y=0, pat=parseInt(hex.substr(x<<1, 2), 16); y<8; y++, pat>>=1) 
                    pixels[y][x] = pat&1;
            return BitmapPatternBuilder.build(pixels, [0x18000000, 0x1020ffc0]);
        }

        private function _render(bitmap:BitmapData, matrix:Matrix) : void {
            var g:Graphics = canvas.graphics;
            g.clear();
            g.beginBitmapFill(bitmap, matrix);
            g.drawRect(0,0,465,465);
            g.endFill();
            screen.draw(canvas);
        }
    }
}


/**-----------------------------------------------------
 * Use following BitmapPatternBuilder class 
 * 
 * DO NOT CHANGE any codes below this comment.
 *
 * -----------------------------------------------------
*/
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
    
class BitmapPatternBuilder{
    /**
     * creates BitmapData filled with dot pattern.
     * First parameter is 2d array that contains color index for each pixels;
     * Second parameter contains color reference table.
     *
     * @parameter pattern:Array 2d array that contains color index for each pixel.
     * @parameter colors:Array 1d array that contains color table.
     * @returns BitmapData
     */
    public static function build(pattern:Array, colors:Array):BitmapData{
        var bitmapW:int = pattern[0].length;
        var bitmapH:int = pattern.length;
        var bmd:BitmapData = new BitmapData(bitmapW,bitmapH,true,0x000000);
        for(var yy:int=0; yy<bitmapH; yy++){
            for(var xx:int=0; xx<bitmapW; xx++){
                var color:int = colors[pattern[yy][xx]];
                bmd.setPixel32(xx, yy, color);
            }
        }
        return bmd;
    }
    
    /**
     * short cut function for Graphics.beginBitmapFill with pattern.
     */
    public static function beginBitmapFill(pattern:Array, colors:Array, graphics:Graphics):void{
        var bmd:BitmapData = build(pattern, colors);
        graphics.beginBitmapFill(bmd);
        bmd.dispose();        
    }
}