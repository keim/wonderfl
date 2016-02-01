package {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.filters.*;
    
    [SWF(backgroundColor='#ffffff', frameRate='60')]
    public class main extends Sprite {
        private const FB:Number = 0.98;
        private var smokeField:Sprite = new Sprite();
        private var screen:BitmapData = new BitmapData(465, 465, false, 0);
        private var feedback:ColorTransform = new ColorTransform(FB, FB, FB, 1);
        private var blur:BlurFilter = new BlurFilter(2, 2);
        private var text1:SmokyText = new SmokyText(232, 160, 0, "Smoky Light", 70, 0x404060, false);
        private var text2:SmokyText = new SmokyText(232, 320, 0, "click to disappear", 30, 0x404060, false);
        private var text3:SmokyText = new SmokyText(232, 350, 0, "and type to appear", 18, 0x404060, false);
        
        function main() {
            SmokyText.forceField.perlinNoise(465, 465, 4, Math.random()*10000, true, true);
            smokeField.addChild(text1);
            smokeField.addChild(text2);
            smokeField.addChild(text3);
            addEventListener("enterFrame", _onEnterFrame);
            stage.addEventListener("keyDown", _onKeyDown);
            stage.addEventListener("click", function(e:Event) : void { text3.isPlaying = text2.isPlaying = text1.isPlaying = true; });
            addChild(new Bitmap(screen));
        }
        
        private function _onKeyDown(e:KeyboardEvent) : void {
            if (smokeField.numChildren < 5) {
                smokeField.addChild(new SmokyText(r(200,232), r(200,232), r(180,-90), String.fromCharCode(e.keyCode), 70, 0x404060));
            }
        }
        
        private function _onEnterFrame(e:Event) : void {
            screen.colorTransform(screen.rect, feedback);
            screen.applyFilter(screen, screen.rect, screen.rect.topLeft, blur);
            screen.draw(smokeField, null, null, "add");
        }
        
        private function r(range:Number, offset:Number) : Number {
            return (Math.random()-Math.random()) * range + offset;
        }
    }
}




import flash.display.*;
import flash.text.*;
import flash.events.*;
import flash.geom.*;
import flash.filters.*;

class SmokyText extends Shape {
    static public const FORCE:Number = 0.5;
    static public const ATTEN:Number = 0.99;
    static public var forceField:BitmapData = new BitmapData(465, 465, false, 0);
    static public var blur:BlurFilter = new BlurFilter(1, 2);
    public var source:BitmapData;
    public var vel:Vector.<Number> = new Vector.<Number>();
    public var vtx:Vector.<Number> = new Vector.<Number>();
    public var idx:Vector.<int>    = new Vector.<int>();
    public var uvt:Vector.<Number> = new Vector.<Number>();
    public var isPlaying:Boolean = true;

    function SmokyText(x:Number, y:Number, rotation:Number, text:String, size:int=70, color:int=0xffffff, isPlaying:Boolean=true) {
        var tf:TextField = new TextField();
        tf.autoSize = "left";
        tf.htmlText = "<font size='"+String(size)+"' color='#"+color.toString(16)+"' face='_selif'>"+text+"</font>";
        source = new BitmapData(tf.width+32, tf.height+32, true, 0);
        source.draw(tf, new Matrix(1,0,0,1,16,16));
        var dv:Number=6, idv:Number=1/dv, u:int, v:int, i:int;
        vel.length = uvt.length = vtx.length = (dv+1)*(dv+1)*2;
        idx.length = dv*dv*6;
        for (i=0, u=0; u<=dv; u++) for (v=0; v<=dv; v++) {
            vtx[i] = ((uvt[i]=u*idv)-0.5) * source.width;
            vel[i++] = 0;
            vtx[i] = ((uvt[i]=v*idv)-0.5) * source.height;
            vel[i++] = 0;//(v*idv-1)*0.5;
        }
        for (i=0, u=0; u<dv; u++) for (v=0; v<dv; v++, i+=6) {
            idx[i+3]=(idx[i+4]=idx[i+2]=(idx[i+5]=idx[i+1]=(idx[i]=v*(dv+1)+u)+1)+dv)+1;
        }
        this.rotation = rotation;
        this.x = x;
        this.y = y;
        this.isPlaying = isPlaying;
        alpha = 1;
        addEventListener("enterFrame", _onEnterFrame);
    }
    
    private function _onEnterFrame(e:Event) : void {
        if (isPlaying) {
            source.applyFilter(source, source.rect, source.rect.topLeft, blur);
            _updateVertex();
            alpha *= ATTEN;
        }
        graphics.clear();
        graphics.beginBitmapFill(source);
        graphics.drawTriangles(vtx, idx, uvt);
        graphics.endFill();
        if (alpha < 0.01) {
            removeEventListener("enterFrame", _onEnterFrame);
            parent.removeChild(this);
        }
    }
        
    private function _updateVertex() : void {
        var i:int, imax:int = vtx.length;
        for (i=0; i<imax; i+=2) {
            var x:Number=vtx[i]+this.x, y:Number=vtx[i+1]+this.y;
            var c:uint = forceField.getPixel(x, y);
            vtx[i]   = x + (vel[i]   += (((c&255)      * 0.00390625) - 0.5) * FORCE)*0.2 - this.x;
            vtx[i+1] = y + (vel[i+1] += ((((c>>8)&255) * 0.00390625) - 0.5) * FORCE)*0.2 - this.y;
        }
    }
}

