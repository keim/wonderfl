package {
    import flash.events.*;
    import flash.display.*;
    import com.bit101.components.*;
    import org.si.utils.ByteArrayExt;
    
    public class main extends Sprite {
        public function main() {
            var me:Sprite = this, imageWidth:Number = 0;
            new Label(me, 140, 4, "Image width (0 to autosize) :");
            new InputText(me, 270, 4, "0", function(e:Event) : void{
                imageWidth = Number(e.target.text);
            });
            new PushButton(me, 4, 4, "load" , function(e:Event) : void {
                new ByteArrayExt().browse(function(bae:ByteArrayExt) : void {
                    me.addChild(new Bitmap(bae.toBitmapData(imageWidth))).y = 30;
                    new PushButton(me, 4, 40, "save", function(e:Event) : void {
                        bae.toPNGData(imageWidth).save("ByteArray.png");
                    });
                });
            });
        }
    }
}
