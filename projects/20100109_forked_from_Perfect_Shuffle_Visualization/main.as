// forked from nitoyon's Perfect Shuffle Visualization
//------------------------------------------------------
// Perfect Shuffle Visualization
//------------------------------------------------------
// How many times does it requires for 15 cards to 
// go back to where one started?
//
// inspired by:
// http://d.hatena.ne.jp/nishiohirokazu/20100107/1262835414
//
//------------------------------------------------------------
// The Perfect Shuffle resets order when ...
//  cards = (1<<(n>>1))-((n&1)<<1);
//  steps = (n&~1)>>(n&1);
// Press left or right arrow to change the n value.
//------------------------------------------------------------

package {
    import flash.events.*;
    import flash.display.*;
    import flash.text.*;
    import flash.filters.BlurFilter;
    import frocessing.color.ColorHSV;

    [SWF(width="465",height="465",backgroundColor="0x000000")]
    public class main extends Sprite {
        private const RADIUS:Number = 230;
        private const HOLE:Number = 40;

        private var index:int = 12;
        private var canvas:Shape = new Shape();
        private var textField:TextField = new TextField();
        
        public function main() {
            stage.scaleMode = "noScale";

            graphics.beginFill(0x000000);
            graphics.drawRect(0, 0, 475, 475);
            graphics.endFill();
            
            with (addChild(canvas)) {
                filters = [new BlurFilter(2, 2)];
                y = x = 232;
            }
            addChild(textField);

            stage.addEventListener("keyDown", function(e:KeyboardEvent):void {
                index += (e.keyCode == 37) ? -1 : (e.keyCode == 39) ? 1 : 0;
                if (index == 0) index = 1;
                drawPerfectShuffle(canvas.graphics);
            });
            
            drawPerfectShuffle(canvas.graphics);
            function drawPerfectShuffle(g:Graphics) : void {
                var size:int = (1<<(index>>1))-((index&1)<<1);
                var step:int = (index&~1)>>(index&1);
                var angleStep:Number = 6.283185307179586/step;
                var thickness:Number = 16/index;
                var num:int, i:int, j:int;
                
                g.clear();
                for (i=0; i<size; i++) {
                    num = i;
                    g.lineStyle(thickness, new ColorHSV(i * 270 / size, .7).value, .7);
                    g.moveTo(0, num*(RADIUS-HOLE)/size+HOLE);
                    var th:Number = angleStep, cth:Number, dist:Number;
                    for (j=0; j<step; j++, th+=angleStep) {
                        num <<= 1;
                        num += (num < size) ? 1 : -size;
                        dist = num*(RADIUS-HOLE)/size+HOLE;
                        cth  = th - angleStep*0.3;
                        g.curveTo(Math.sin(cth) * dist, Math.cos(cth) * dist, Math.sin(th) * dist, Math.cos(th) * dist);
                    }
                }
                textField.htmlText = "<font color='#ffffff'>n=" + String(index) + "</font>";
            }
        }
    }
}
