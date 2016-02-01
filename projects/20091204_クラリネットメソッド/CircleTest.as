// forked from bkzen's 【問題】Graphics の drawCircle と drawRoundRect が壊れました
//--------------------------------------------------
// ドが壊れれば，レとミとファとソとラとシも壊れるものです．
// 【壊れ物リスト】
// - Number, Math 一式
// - var
// - 代入演算
// - 乗算, 除算
// - 比較演算
// - ループ関数
package 
{
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    
    /**
     * Graphics.drawCircle と drawRoundRect が壊れました。
     * 別の方法で、半径 CIRCLE_RADIUS の 円を書きなさい。
     * @mxmlc -o bin/CircleTest.swf -load-config+=obj\Alltest3Config.xml
     * @author jc at bk-zen.com
     */
    public class CircleTest extends Sprite
    {
        private const ANSWER_COLOR: uint = 0x003366;
        private const COLOR: uint = 0x3399CC;
        private const CIRCLE_RADIUS: Number = 50;
        
        public function CircleTest() 
        {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(e: Event = null): void 
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            //
            var centerX: Number = (stage.stageWidth - CIRCLE_RADIUS) / 2;
            var centerY: Number = (stage.stageHeight - CIRCLE_RADIUS) / 2;
            var g: Graphics = graphics;
            // 差を見るために解答として先に半径+1 の円を描いておきます。
            g.beginFill(ANSWER_COLOR); g.drawCircle(centerX, centerY, CIRCLE_RADIUS + 1);
            
            // 
            drawCircle(g, centerX, centerY, CIRCLE_RADIUS, COLOR);
        }
        
        /**
         * これを作る。
         * @param   g
         * @param   x
         * @param   y
         * @param   r
         * @param   color
         */
        public function drawCircle(g: Graphics, x: Number, y: Number, r: Number, color: uint): void
        {
            function m(o:int, i:int, r:int) : int {
                return i?m(o<<1,i>>1,r+(o&(~((i&1)-1)))):r;
            }
            
            function d(o:int, i:int, r:int, t:int) : int { 
                return t?d(o-(i-o-1>>>31?i:0),i>>1,(r+(i-o-1>>>31))<<1,t-1):r>>1;
            }
            
            function s(o:int, i:int, r:int) : int { 
                return (r-o>>>31)?s(o,i+2,r+i):_s(o<<8,i<<7,0);
            }
            
            function _s(o:int, i:int, t:int) : int {
                return t?_s(o,i+d(o,i<<8,0,17)>>1,t-1):i;
            }
            
            function render(i:int, t:int) : int {
                g.drawRect(x-i+1,y-t+1,i+i-2,t+t-2);
                return (r-t>>>31)?0:render(s(-m(t,t,-m(r,r,0)),1,0)>>8,t+1);
            }
            
            g.lineStyle(1, color);
            render(r, 1);
        }
    }
}