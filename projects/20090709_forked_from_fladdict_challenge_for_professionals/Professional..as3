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
        private var alphabetIndex:int = 0;
        private var planeZ:Number = 0.5;
        private var angle:Number = 0;
        private var rot:Number = 0;
        private var matrix:Matrix = new Matrix();
        private var screen:BitmapData = new BitmapData(465, 465, false, 0);
        private var canvas:Shape = new Shape();
        
        public function Professional() {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            alphabet = [_build("7c2221227c"), _build("7f49494936"), _build("3e41414122"),                       // ABC
                        _build("7f4141423c"), _build("7f49494941"), _build("7f09090901"), _build("3e4149493a"), // DEFG
                        _build("7f0808087f"), _build("00417f4100"), _build("2040413f01"), _build("7f08142241"), // HIJK
                        _build("7f40404040"), _build("7f020c027f"), _build("7f0408107f"), _build("3e4141413e"), // LMNO
                        _build("7f09090906"), _build("3e4151215e"), _build("7f09192946"), _build("2649494932"), // PQRS
                        _build("01017f0101"), _build("3f4040403f"), _build("1f2040201f"), _build("1f601c601f"), // TUVW
                        _build("6314081463"), _build("0708700807"), _build("6151494543")];                      // XYZ
            addChild(new Bitmap(screen));
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        private function onEnterFrame(e:Event) : void {
            var g:Graphics = canvas.graphics, scale:Number;
            for (var i:int=0; i<6; i++) {
                scale = 1/(1-planeZ);
                matrix.identity();
                matrix.translate(-2.5, -3.5);
                matrix.rotate(angle+=(rot*=0.99));
                matrix.scale(scale, scale);
                matrix.translate(232.5, 232.5);
                g.clear();
                g.beginBitmapFill(alphabet[alphabetIndex], matrix);
                g.drawRect(0,0,465,465);
                g.endFill();
                screen.draw(canvas);
                planeZ += 0.005;
                if (planeZ >= 1) {
                    if (++alphabetIndex==26) alphabetIndex=0;
                    planeZ = 0.5;
                    rot += (Math.random()-0.5)*0.005;
                }
            }
        }
        
        private var color:uint = 0x18102040;
        private function _build(hex:String) : BitmapData {
            var x:int, y:int, pat:int,
                pixels:Array=[[0,0,0,0,0,0],[0,0,0,0,0,0],
                              [0,0,0,0,0,0],[0,0,0,0,0,0],
                              [0,0,0,0,0,0],[0,0,0,0,0,0],
                              [0,0,0,0,0,0],[0,0,0,0,0,0]];
            for (x=0; x<5; x++)
                for (y=0, pat=parseInt(hex.substr(x<<1, 2), 16); y<7; y++, pat>>=1) 
                    pixels[y][x] = pat&1;
            return BitmapPatternBuilder.build(pixels, [color, color^=0x00ffffff]);
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