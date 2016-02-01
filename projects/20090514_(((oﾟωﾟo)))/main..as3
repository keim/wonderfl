package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.filters.*;
    import flash.text.*;
    
    [SWF(width="240", height="240", backgroundColor="#406080", frameRate=30)]
    public class main extends Sprite
    {
        static public  var base:BitmapData   = new BitmapData(240, 240, false); // base image
        static private var pixels:BitmapData = new BitmapData(240, 240, false); // displaying image
        static private var screen:Bitmap     = new Bitmap(pixels);              // displaying image
        static private var balls:Vector.<ball>;                                 // meta-balls array

        static private var ptBallsCenter:Point = new Point();   // balls center position
        static private var matFace:Matrix      = new Matrix();  // face matrix

        static private var colt:ColorTransform    = new ColorTransform(32,4,1.6,1,-1280,-320,-320,0);
        static private var conv:ConvolutionFilter = new ConvolutionFilter(3, 3, [-2.5,-2.5,0,-2.5,0,2.5,0,2.5,2.5], 1, 128);
        
        static private var face:BitmapData;     // face image 
        
        public function main()
        {
            var i:int;
            
            // draw meta-ball gradation
            ball.pat = new BitmapData(ball.R*2,ball.R*2,false,0);
            var shp:Shape = new Shape(), mtx:Matrix = new Matrix();
            mtx.createGradientBox(ball.R*2,ball.R*2,0,0);
            shp.graphics.beginGradientFill(GradientType.RADIAL, [0x808080,0x000000], [1,1], [0,255], mtx);
            shp.graphics.drawRect(0,0,ball.R*2,ball.R*2);
            shp.graphics.endFill();
            base.draw(shp);
            base.draw(shp, null, null, BlendMode.MULTIPLY);
            ball.pat.applyFilter(base, ball.pat.rect, ball.pat.rect.topLeft, new BlurFilter(16, 16));

            // draw face
            face = new BitmapData(48, 16, true, 0x00000000);
            var tf:TextField = new TextField();
            tf.width = 48; 
            tf.height = 16;
            tf.defaultTextFormat = new TextFormat('MS Gothic', 12, 0, null, null, null, null, null, 'center');
            tf.text = "oﾟωﾟo";
            face.draw(tf);
            tf.width = 240;
            tf.textColor = 0x808080;
            tf.text = "Pinch this by mouse";
            
            // create ball instance
            balls = new Vector.<ball>(16, true);
            for (i=0; i<balls.length; i++) { balls[i] = new ball(); }

            // set sprite/event
            addChild(screen);
            addChild(tf);
            stage.doubleClickEnabled = true;
            stage.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
            stage.addEventListener(MouseEvent.MOUSE_UP,   _onMouseUp);
        }

        
        private function _onEnterFrame(event:Event) : void
        {
            var i:int, j:int;
            
            // execute
            ball.mouse.x = mouseX;
            ball.mouse.y = mouseY;
            for (i=0; i<balls.length; i++) { ball(balls[i]).gravity(); }
            for (i=0; i<balls.length-1; i++) for (j=i+1; j<balls.length; j++) { ball(balls[i]).interact(ball(balls[j])); }
            for (i=0; i<balls.length; i++) { ball(balls[i]).run(); }
            calcBallCenter();
            
            // draw
            base.fillRect(pixels.rect,0x000000);
            for (i=0; i<balls.length; i++) { ball(balls[i]).draw(base); }
            pixels.applyFilter(base, pixels.rect, pixels.rect.topLeft, conv);
            base.colorTransform(pixels.rect, colt);
            pixels.draw(base,null,null,BlendMode.MULTIPLY);
            drawFace();
        }

        private function _onMouseDown(event:MouseEvent) : void
        {
            for (var i:int=0; i<balls.length; i++) { ball(balls[i]).check_hold(event.localX, event.localY); }
        }
    
        private function _onMouseUp(event:MouseEvent) : void
        {
            for (var i:int=0; i<balls.length; i++) { ball(balls[i]).holding = false; }
        }
        
        private function calcBallCenter() : void
        {
            ptBallsCenter.x = 0;
            ptBallsCenter.y = 0;
            for (var i:int=0; i<balls.length; i++) { ptBallsCenter.offset(balls[i].pos.x, balls[i].pos.y); }
            var dv:Number=1/balls.length;
            ptBallsCenter.x *= dv;
            ptBallsCenter.y *= dv;
        }
        
        private function drawFace() : void
        {
            matFace.identity();
            matFace.translate(-24, -8);
            matFace.rotate(Math.atan2(balls[0].pos.y-ptBallsCenter.y, balls[0].pos.x-ptBallsCenter.x));
            matFace.translate(ptBallsCenter.x, ptBallsCenter.y);
            pixels.draw(face, matFace, null, null, null, true);
        }
    }
}


import flash.display.*;
import flash.geom.*;
class ball
{
    static internal var pat:BitmapData;
       
    static internal var R :Number = 48;       // radius
    static internal var K :Number = 0.025;    // spring
    static internal var K2:Number = 0.3;      // dumper
    static internal var D :Number = 48;       // comfortable distance
    static internal var G :Number = 1.2;      // gravity
    static internal var HR:Number = 32*32;    // holding radius ^ 2

    static internal var mouse:Point=new Point();
    
    internal var a:Point=new Point(), v:Point=new Point(), pos:Point=new Point(), hold:Point=new Point();
    internal var mat:Matrix = new Matrix();
    internal var holding:Boolean = false;
    
    function ball() { reset(); }
    
    internal function reset() : void {
        pos.x = Math.random()*R+120;
        pos.y = Math.random()*R;
        v.x=0; v.y=0; a.x=0; a.y=0;
        holding = false;
    }

    internal function run() : void {
        if (holding) {
            pos.x = mouse.x + hold.x;
            pos.y = mouse.y + hold.y;
        } else {
            pos.x += v.x + a.x * 0.5;
            pos.y += v.y + a.y * 0.5;
            v.x += a.x - v.x * K2;
            v.y += a.y - v.y * K2;
            if (pos.y>240) { v.y=-v.y; pos.y=480-pos.y; }
            if (pos.x<0)   { v.x=-v.x; pos.x=-pos.x; } else 
            if (pos.x>240) { v.x=-v.x; pos.x=480-pos.x; }
        }
        mat.identity();
        mat.translate(pos.x-R, pos.y-R);
    }
    
    internal function draw(base:BitmapData) : void { base.draw(pat, mat, null, BlendMode.ADD); }
    
    internal function gravity() : void { a.x = 0; a.y = G; }
    
    internal function interact(b:ball) : void {
        var dx:Number = b.pos.x - pos.x;
        var dy:Number = b.pos.y - pos.y;
        var l:Number = Math.sqrt(dx*dx+dy*dy);
        var f:Number = (D-l)*K/l;
        dx    *= f;   dy    *= f;
        a.x   -= dx;  a.y   -= dy;
        b.a.x += dx;  b.a.y += dy;
    }
    
    internal function check_hold(x_:Number, y_:Number) : void {
        hold.x = pos.x-x_; hold.y = pos.y-y_;
        holding = (hold.x*hold.x+hold.y*hold.y<HR);
    }
}

