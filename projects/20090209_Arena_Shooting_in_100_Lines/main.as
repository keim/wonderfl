// Arena Shooting in 100 Lines.
//  Movement;[Arrow key], Shot;[Ctrl], Slow & Head fix;[Shift]
package {
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.text.*;
    import flash.geom.*;
    [SWF(width = "465", height = "465", frameRate = "30", backgroundColor = "#ffffff")]
    public class main extends Sprite {
        function main() {
            var i:int, ii:*, cnt:int=0, kf:uint=0, kmap:Array=[32,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,4,8],
                sb:TextField=new TextField(), tt:TextField=new TextField(), fld:Sprite=addChild(new Sprite()) as Sprite,
                ee:Array=[new GlowFilter(0xff0000)], oe:Array=[new GlowFilter(0x0000ff)], rc:Array=[1,2,2,2,2],
                me:MovieClip, pd:Point = new Point(1,0), _b:Array=[], _s:Array=[], score:int=0, level:int=0;
            $(tt,{x:180,y:230,htmlText:"<font color='#406080' size='40' face='_sans'>100Lines Arena</font>",width:282});
            stage.addEventListener("keyDown",function(e:KeyboardEvent) : void { kf |=  kmap[e.keyCode-16]; });
            stage.addEventListener("keyUp",  function(e:KeyboardEvent) : void { kf &= ~kmap[e.keyCode-16]; });
            addChild(sb).parent.addChild(tt).parent.addEventListener("enterFrame", function(e:Event) : void {
                sb.htmlText="<font color='#80c0ff' size='20' face='_sans'>Score:" + String(score) + "</font>";
                if (tt.visible && cnt>30 && kf!=0) tt.visible = Boolean(level = score = 0);
                if (!tt.visible && (tt.visible = !(me.visible = !hit(me, _b, 36)))) cnt = 0;
                if (!((++cnt)&31) && !tt.visible) {
                    var r:Number = Math.random()*32, 
                        x:Number = (r>=24)?0:(r>=16)?8:(r>=8)?(r-8):r, y:Number = (r<8)?0:(r<16)?8:(r<24)?(r-16):(r-24);
                    ii = {x:x*100-400, y:y*100-400, v:new Point(4-x,4-y), fn:_e, cnt:0, r:5, l:3, filters:ee};
                    $(fld.addChild(new MovieClip()), ii, 0xffff80, rc, [20,20,20,-20,-20,-20,-20,20,20,20]);
                }
            });
            for (i=-400; i<=400; i+=100) $(fld, {rotationX:-30}, 0x80c0ff, [1,2,1,2], [-400,i,400,i,i,-400,i,400]);
            $(fld.addChild(me=new MovieClip()), {fn:_p,l:0,filters:oe}, 0x80ffff, [1,2,2,2], [-9,6,-9,-6,9,0,-9,6]);
            function $(mc:*, props:*, color:uint=0, commands:Array=null, vertices:Array=null) : void {
                for (var p:String in props) mc[p] = props[p];
            	if (color)    mc.graphics.lineStyle(1, color, 1, false, "normal", null, null,3);
                if (commands) mc.graphics.drawPath(Vector.<int>(commands), Vector.<Number>(vertices), "nonZero");
                if (props.fn) mc.addEventListener("enterFrame", props.fn);
                if (props.ar) mc.ar.push(mc);
            }
            function _p(e:Event) : void {   // player
                var r:Number=(kf&32)?6:9, dir:Point = new Point((((kf&4)>>2)-(kf&1))*r, (((kf&8)>>3)-((kf&2)>>1))*r);
                me.x += (me.x+dir.x>-390 && me.x+dir.x<390) ? dir.x : 0;
                me.y += (me.y+dir.y>-390 && me.y+dir.y<390) ? dir.y : 0;
                fld.x += ((232-me.x) - fld.x)*0.1;
                fld.y += ((232-me.y) - fld.y)*0.1;
                if (!(kf&32)) {
                    pd.offset(dir.x*0.05, dir.y*0.05);
                    pd.normalize(1);
                    me.rotation = Math.atan2(pd.y, pd.x)*57.29577951308232;
                }
                if (!tt.visible && (kf&16) && (cnt&1)) {    // create shot
                    ii={x:me.x,y:me.y,v:new Point(pd.x*24,pd.y*24),rotation:me.rotation,r:0,filters:oe,fn:mv,ar:_s};
                    $(fld.addChild(new MovieClip()), ii, 0x80ffff, [1,2,1,2], [6,6,-6,6,6,-6,-6,-6]);
                }
            }
            function _e(e:Event) : void {   // enemy
                e.target.cnt++;
                if (!tt.visible && !(e.target.cnt % (80-level))) {  // create bullet
                    var v:Point = new Point(me.x - e.target.x, me.y - e.target.y);
                    v.normalize((Math.random()*0.06+0.03)*(50+level));
                    ii = {x:e.target.x, y:e.target.y, v:v, r:-5, fn:mv, ar:_b, filters:ee};
                    $(fld.addChild(new MovieClip()), ii, 0xffffff, rc, [3,3,-3,3,-3,-3,3,-3,3,3]);
                }
                if (hit(e.target, _s, 400)) {  // destruction
                    kill(e.target);
                    level = (++score<30) ? (score*2) : (score<60) ? (score*0.5+45) : 75;
                    for (i=0; i<8; i++) {   // create particles
                        v = new Point(Math.random()*16-8, Math.random()*16-8);
                        ii = {x:e.target.x, y:e.target.y, v:v, r:20, fn:_x, cnt:30, filters:oe};
                        $(fld.addChild(new MovieClip()), ii, 0x80ffff, rc, [5,5,5,-5,-5,-5,-5,5,5,5]);
                    }
                }
                mv(e);
            }
            function _x(e:Event) : void {   // explosion
                if ((e.target.alpha = (--e.target.cnt)*0.03) == 0) kill(e.target);
                else {
                    e.target.v.x *= 0.95;
                    e.target.v.y *= 0.95; 
                    mv(e);
                }
            }
            function mv(e:Event) : void {   // common motion
                e.target.rotation += e.target.r;
                e.target.x += e.target.v.x;
                e.target.y += e.target.v.y;
                if (e.target.x<-400 || e.target.y<-400 || e.target.x>400 || e.target.y>400) kill(e.target);
            }
            function hit(t:*, list:Array, r2:Number) : Boolean {   // hit evaluation
                for (i=0; i<list.length; i++)
                    if ((list[i].x-t.x)*(list[i].x-t.x)+(list[i].y-t.y)*(list[i].y-t.y) < r2) {
                        kill(list[i]);
                        if (--t.l <= 0) return true;
                    }
                return false;
            }
            function kill(mc:*) : void {   // kill object
                mc.parent.removeChild(mc).removeEventListener("enterFrame", mc.fn);
                if (mc.ar) mc.ar = mc.ar.splice(mc.ar.indexOf(mc), 1);
            }
        }
    }
}
