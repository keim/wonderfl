// SiON Kaoscillator for ver0.58
package {
    import flash.display.*;
    import flash.events.*;
    import flash.ui.Keyboard;
    import flash.text.TextField;
    import org.si.sion.*;
    import org.si.sion.events.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import org.si.sion.utils.SiONPresetVoice;
    import org.si.sion.utils.Scale;
    import org.si.sound.Arpeggiator;
    import com.bit101.components.*;
    
    
    [SWF(frameRate='30')]
    public class kaoscillator extends Sprite {
        // driver
        public var driver:SiONDriver = new SiONDriver();
        
        // preset voice
        public var presetVoice:SiONPresetVoice = new SiONPresetVoice();
        
        // MML data
        public var rythmLoop:SiONData;
        
        // control pad
        public var controlPad:ControlPad;
        
        // arpeggiator
        public var arpeggiator:Arpeggiator;
        
        
        // constructor
        function kaoscillator() {
            // compile mml. 
            var mml:String = "t132;";
            mml += "%6@0o3l8$c2cc.c.; %6@1o3$rcrc; %6@2v8l16$[crccrrcc]; %6@3v8o3$[rc8r8];";
            mml += "%6@4v8l16o3$aa<a8>a<ga>ararara<e8>;";
            rythmLoop = driver.compile(mml);
            
            // set voices of "%6@0-4" from preset
            rythmLoop.setVoice(0, presetVoice["valsound.percus1"]);
            rythmLoop.setVoice(1, presetVoice["valsound.percus28"]);
            rythmLoop.setVoice(2, presetVoice["valsound.percus17"]);
            rythmLoop.setVoice(3, presetVoice["valsound.percus23"]);
            rythmLoop.setVoice(4, presetVoice["valsound.bass3"]);
            
            // listen click
            driver.addEventListener(SiONEvent.STREAM,    _onStream);
            driver.addEventListener(SiONTrackEvent.BEAT, _onBeat);
            stage.addEventListener("mouseDown", _onMouseDown);
            stage.addEventListener("mouseUp",   _onMouseUp);
            stage.addEventListener("keyDown",   _onKeyDown);
            stage.addEventListener("keyUp",     _onKeyUp);
            
            // arpeggiator setting
            arpeggiator = new Arpeggiator(new Scale("o1Ajap"), 1, [0,1,2,5,4,3]);
            arpeggiator.voice = presetVoice["valsound.lead32"];
            arpeggiator.quantize = 4;
            arpeggiator.volume = 0.3;
            arpeggiator.noteQuantize = 8;
            
            // background
            var back:Shape = new Shape();
            back.graphics.beginFill(0);
            back.graphics.drawRect(0, 0, 465, 465);
            back.graphics.endFill();
            addChild(back);
            
            // control pad
            with(addChild(controlPad = new ControlPad(stage, 320, 320, 0.5, 0.5, 0x4040b0))){
                x = y = 56;
            }
            
            // labels
            Style.LABEL_TEXT = 0xffffff;
            new Label(this, 72, 396, "[Ctrl]:  Staccarto  /  [Shift]: Portament");
            
            // play rythmLoop
            driver.play(rythmLoop);
        }
        
        
        private function _onMouseDown(e:MouseEvent) : void
        {
            // set pitch and length
            arpeggiator.scaleIndex = controlPad.controlX * 32;
            arpeggiator.noteLength = [0.5,1,1,2,4][int(controlPad.controlY * 4 + 0.99)];
            // start arpeggio
            arpeggiator.play();
        }
        
        
        private function _onMouseUp(e:MouseEvent) : void
        {
            // stop arpeggio
            arpeggiator.stop();
        }
        
        
        private function _onKeyDown(e:KeyboardEvent) : void
        {
            switch (e.keyCode) {
            case Keyboard.SHIFT:   arpeggiator.portament = 4;    break;  // set portament
            case Keyboard.CONTROL: arpeggiator.gateTime = 0.25;  break;  // set staccart
            }
        }
        
        
        private function _onKeyUp(e:KeyboardEvent) : void
        {
            switch (e.keyCode) {
            case Keyboard.SHIFT:   arpeggiator.portament = 0; break;  // reset portament
            case Keyboard.CONTROL: arpeggiator.gateTime = 1;  break;  // reset staccart
            }
        }
        
        
        private function _onStream(e:SiONEvent) : void
        {
            // update arpeggiator pitch and length
            arpeggiator.scaleIndex = controlPad.controlX * 24 + 4;
            arpeggiator.noteLength = [0.5,1,1,2,4][int(controlPad.controlY * 4 + 0.99)];
        }
        
        
        private function _onBeat(e:SiONTrackEvent) : void 
        {
            controlPad.beat(6);
        }
    }
}



import flash.display.*;
import flash.events.*;
import flash.filters.BlurFilter;
import flash.geom.*;

class ControlPad extends Bitmap {
    public var controlX:Number;
    public var controlY:Number;
    public var isDragging:Boolean;
    public var color:int;
    
    private var buffer:BitmapData;
    private var ratX:Number,  ratY:Number;
    private var prevX:Number, prevY:Number, blurX:int;
    private var clsDrawer:Shape = new Shape();
    private var canvas:Shape = new Shape();
    private var blur:BlurFilter = new BlurFilter(2, 2);
    private var pointerSize:Number = 2;
    
    
    function ControlPad(stage:Stage, width:int, height:int, initialX:Number=0, initialY:Number=0, color:int=0x303090) {
        super(new BitmapData(width+32, height+32, false, 0));
        buffer = new BitmapData(width*0.125+4, height*0.125+4, false, 0);
        
        clsDrawer.graphics.clear();
        clsDrawer.graphics.lineStyle(1, 0xffffff);
        clsDrawer.graphics.drawRect(16, 16, width, height);
        
        bitmapData.draw(clsDrawer);
        buffer.fillRect(buffer.rect, 0);
        
        this.color = color;
        controlX = initialX;
        controlY = initialY;
        ratX = 1 / width;
        ratY = 1 / height;
        prevX = buffer.width * controlX;
        prevY = buffer.height * controlY;
        blurX = 0;
        addEventListener("enterFrame", _onEnterFrame);
        stage.addEventListener("mouseMove",  _onMouseMove);
        stage.addEventListener("mouseDown",  function(e:Event):void { isDragging = true; } );
        stage.addEventListener("mouseUp",    function(e:Event):void { isDragging = false; });
    }
    

    private var matrix:Matrix = new Matrix(8, 0, 0, 8, 0, 0);
    private function _onEnterFrame(e:Event) : void {
        var x:Number = (buffer.width  - 4) * controlX + 2;
        var y:Number = (buffer.height - 4) * (1-controlY) + 2;
        canvas.graphics.clear();
        canvas.graphics.lineStyle(pointerSize, color);
        canvas.graphics.moveTo(prevX, prevY);
        canvas.graphics.lineTo(x, y);
        buffer.applyFilter(buffer, buffer.rect, buffer.rect.topLeft, blur);
        buffer.draw(canvas, null, null, "add");
        bitmapData.draw(buffer, matrix);
        bitmapData.draw(clsDrawer);
        prevX = x + blurX;
        prevY = y;
        blurX = 1 - blurX;
        pointerSize *= 0.75;
    }
    
    
    private function _onMouseMove(e:MouseEvent) : void {
        if (isDragging) {
            controlX = (mouseX - 16) * ratX;
            controlY = 1 - (mouseY - 16) * ratY;
            if (controlX < 0) controlX = 0;
            else if (controlX > 1) controlX = 1;
            if (controlY < 0) controlY = 0;
            else if (controlY > 1) controlY = 1;
        }
    }
    
    
    public function beat(size:int) : void {
        pointerSize = size;
    }
}