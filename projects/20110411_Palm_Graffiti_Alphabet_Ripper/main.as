package {
    import flash.display.*;
    import flash.events.*;
    import flash.text.*;
    
    public class main extends Sprite {
        public var gesturePad:GesturePad;
        public var gestureAnalyzer:GestureAnalyzer = new GestureAnalyzer();
        public var tf:TextField = new TextField();
        public var detected:TextField = new TextField();
        
        function main() {
            graphics.beginFill(0xc0c0d0);
            graphics.drawRect(0,0,465,465);
            graphics.endFill();
            gesturePad = new GesturePad(this, 82, 16, 400, onMouseDown, onMouseUp);
            
            // 432
            // 5*1
            // 678
            gestureAnalyzer.map("A", "28", 6, 8);
            gestureAnalyzer.map("B", "7321876518765");
            gestureAnalyzer.map("C", "56781");
            gestureAnalyzer.map("D", "73218765", 0, 6);
            gestureAnalyzer.map("E", "5678156781");
            gestureAnalyzer.map("F", "57", 2, 6);
            gestureAnalyzer.map("G", "567812341", 0, 1);
            gestureAnalyzer.map("H", "732187");
            gestureAnalyzer.map("I", "7", 3, 7);
            gestureAnalyzer.map("J", "765", 0, 6);
            gestureAnalyzer.map("K", "6573218");
            gestureAnalyzer.map("L", "71", 4, 8);
            gestureAnalyzer.map("M", "32187321187");
            gestureAnalyzer.map("N", "3218123");
            gestureAnalyzer.map("O", "56781234", 0, 3);
            gestureAnalyzer.map("P", "73218765", 0, 5);
            gestureAnalyzer.map("Q", "567812341", 0, 2);
            gestureAnalyzer.map("R", "732187658");
            gestureAnalyzer.map("S", "5678765");
            gestureAnalyzer.map("T", "17", 4, 0);
            gestureAnalyzer.map("U", "78123");
            gestureAnalyzer.map("V", "821", 4, 0);
            gestureAnalyzer.map("W", "7812378123");
            gestureAnalyzer.map("X", "8", 4, 8);
            gestureAnalyzer.map("Y", "781265432");
            gestureAnalyzer.map("Z", "161");
            gestureAnalyzer.map("0", "567812347");
            gestureAnalyzer.map("1", "27", 0, 7);
            gestureAnalyzer.map("2", "18761");
            gestureAnalyzer.map("3", "1876518765");
            gestureAnalyzer.map("4", "61");
            gestureAnalyzer.map("5", "5718765");
            gestureAnalyzer.map("6", "56781234", 0, 5);
            gestureAnalyzer.map("7", "16", 4, 0);
            gestureAnalyzer.map("8", "5678765432");
            gestureAnalyzer.map("9", "5678127");
            tf.width = 465;
            tf.height = 32;
            addChild(tf);
        }
        
        public function onMouseDown() : void {
        }
        
        public function onMouseUp() : void {
            var candidate:Array = gestureAnalyzer.analyze(gesturePad.head);
            tf.text = gestureAnalyzer.pattern.join("") + " / " + candidate.join(" ");
            gesturePad.textField.text = candidate[0].charAt(0);
            gesturePad.flush();
        }
    }
}




import flash.display.*;
import flash.filters.*;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import com.bit101.components.*;
import org.libspark.betweenas3.*;
import org.libspark.betweenas3.easing.*;


class TextDroppingField extends Sprite {
    public var surface:Sprite, front:Bitmap, field:Sprite, back:Bitmap;
    public var frontBase:BitmapData, textBitmap:BitmapData;
    public var textField:TextField = new TextField();
    public var bigShadow:DropShadowFilter = new DropShadowFilter(6, 45, 0, 0.375, 16, 16);
    public var littleShadow:DropShadowFilter = new DropShadowFilter(3, 45, 0, 0.375, 8, 8);
    
    function TextDroppingField(width:int, height:int) {
        super();
        var s:Shape = new Shape(), g:Graphics = s.graphics, mat:Matrix = new Matrix(), i:int;
        surface = new Sprite();
        field = new Sprite();
        front = new Bitmap(new BitmapData(width, height, true, 0xffffffff));
        back = new Bitmap(new BitmapData(width, height, false, 0xffffff));
        textBitmap = new BitmapData(width, height, false, 0);
        frontBase = new BitmapData(width, height, false, 0);
        g.clear();
        g.beginFill(0xf0f0f0);
        g.moveTo(-8, 0);
        g.lineTo(0, 8);
        g.lineTo(8, 0);
        g.lineTo(0, -8);
        g.endFill();
        for (mat.ty=-((height&15)+16)*0.5; mat.ty<height; mat.ty+=16) 
            for (mat.tx=-((width&15)+16)*0.5; mat.tx<width; mat.tx+=16) 
                back.bitmapData.draw(s, mat);
        frontBase.fillRect(new Rectangle(0, 0, width, height), 0xffcccccc);
        frontBase.fillRect(new Rectangle(2, 2, width-4, height-4), 0xffffffff);
        g.clear();
        g.lineStyle(1, 0xeeeeee);
        for (i=1; i<16; i++) {
            g.moveTo(2,       height * 0.0625 * i);
            g.lineTo(width-2, height * 0.0625 * i);
            g.moveTo(height * 0.0625 * i, 2);
            g.lineTo(height * 0.0625 * i, height-2);
        }
        frontBase.draw(s);
        frontBase.fillRect(new Rectangle(width*0.5-1, 0, 2, height), 0xffcccccc);
        frontBase.fillRect(new Rectangle(0, height*0.5-1, width, 2), 0xffcccccc);
        front.bitmapData.copyPixels(frontBase, frontBase.rect, frontBase.rect.topLeft);
        textField.defaultTextFormat = new TextFormat("_sans", 64, 0xff0000, null, null, null, null, null, "center");
        textField.autoSize = "center";
        textField.height = height;
        front.filters = [bigShadow];
        addChild(back);
        addChild(field);
        addChild(front);
        addChild(surface);
    }
    
    public function set text(str:String) : void {
        var frontPixels:BitmapData = front.bitmapData,
            w:Number = front.width, h:Number = front.height;
        textField.text = str;
        textBitmap.fillRect(textBitmap.rect, 0x00ff00);
        textBitmap.draw(textField, new Matrix(h*0.015625,0,0,h*0.015625,-w*0.55,-h*0.075));
        frontPixels.copyPixels(frontBase, frontBase.rect, frontBase.rect.topLeft);
        frontPixels.copyChannel(textBitmap, textBitmap.rect, textBitmap.rect.topLeft, 2, 8);
        
        var textParticlePixels:BitmapData = new BitmapData(w, h, true, 0xffffffff);
        textParticlePixels.copyPixels(frontBase, frontBase.rect, frontBase.rect.topLeft);
        textParticlePixels.copyChannel(textBitmap, textBitmap.rect, textBitmap.rect.topLeft, 1, 8);
        var textContainer:Sprite = _textSprite(textParticlePixels);
        var textContainerSurface:Sprite = _textSprite(textParticlePixels.clone());
        textContainer.filters = [littleShadow];
        field.addChild(textContainer);
        surface.addChild(textContainerSurface);
        BetweenAS3.serial(
            BetweenAS3.to(textContainerSurface, {alpha:0}, 0.5),
            BetweenAS3.removeFromParent(textContainerSurface),
            BetweenAS3.to(textContainer, {y:465+h*0.5, rotation:Math.random()*120-60}, 2.5, Cubic.easeIn),
            BetweenAS3.removeFromParent(textContainer)
        ).play();
    }
        
    private function _textSprite(bitmapData:BitmapData) : Sprite {
        var container:Sprite = new Sprite();
        var textbmp:Bitmap = new Bitmap(bitmapData);
        textbmp.x = -(container.x = bitmapData.width*0.5);
        textbmp.y = -(container.y = bitmapData.height*0.5);
        container.addChild(textbmp);
        return container;
    }
}


class GesturePad extends Component {
    public var back:Sprite, textField:TextDroppingField, _onMouseUp:Function, _onMouseDown:Function;
    
    private const MOVING_THRESHOLD_PER_FRAME:Number = 2*2;
    private const MOVING_THRESHOLD_PER_GESTURE:Number = 10*10;
    
    private var _prevMouseX:Number, _prevMouseY:Number, _iwidth:Number, _iheight:Number, _infoThres:Number;
    public var head:MouseGestureInfo, current:MouseGestureInfo;
    
    function GesturePad(parent:DisplayObjectContainer, xpos:Number, ypos:Number, size:Number, onMouseDown:Function, onMouseUp:Function) {
        super(parent, xpos, ypos);
        setSize(size*0.75, size);
        addChild(back = new Sprite());
        back.addChild(textField = new TextDroppingField(width, height));
        back.addEventListener(MouseEvent.MOUSE_DOWN, onDrag);
        current = head = new MouseGestureInfo();
        _iwidth = 1 / width;
        _iheight = 1 / height;
        _infoThres = MOVING_THRESHOLD_PER_GESTURE * _iheight * _iheight;
        _onMouseUp = onMouseUp;
        _onMouseDown = onMouseDown;
    }
    
    public function flush() : void {
        MouseGestureInfo.freeAll(head);
        current = head.init(0, mouseX*_iwidth, mouseY*_iheight, 0);
    }
    
    protected function onDrag(e:MouseEvent) : void {
        _updatePoint(0);
        _prevMouseX = mouseX;
        _prevMouseY = mouseY;
        _onMouseDown();
        addEventListener(Event.ENTER_FRAME, _capture);
        stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
    }
    
    protected function onDrop(e:MouseEvent) : void {
        stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
        removeEventListener(Event.ENTER_FRAME, _capture);
        _updatePoint(0);
        _onMouseUp();
    }
    
    private function _capture(e:Event) : void {
        var dx:Number, dy:Number, lx:Number, ly:Number;
        dx = mouseX - _prevMouseX, 
        dy = mouseY - _prevMouseY;
        if (dx * dx + dy * dy < MOVING_THRESHOLD_PER_FRAME) return;
        lx = mouseX*_iwidth - current.x;
        ly = mouseY*_iheight - current.y;
        current.dist2 = lx * lx + ly * ly;
        current.frames++;
        var a:Number = (dx==0) ? 10 : (-dy/dx), dir:int = 3;
             if (a > 3.732) dir = 3; // tan(75)
        else if (a > 0.364) dir = 2; // tan(20)
        else if (a >-0.364) dir = 1;
        else if (a >-3.732) dir = 4;
        if ((dir != 1 && dy > 0) || (dir == 1 && dx < 0)) dir += 4;
        if (current.dir != dir) {
            if (current.dir != 0 && current.dist2 < _infoThres) current.init(dir, mouseX*_iwidth, mouseY*_iheight, 0);
            else _updatePoint(dir);
        }
        _prevMouseX = mouseX;
        _prevMouseY = mouseY;
        invalidate();
    }
    
    private function _updatePoint(dir:int) : void {
        current = MouseGestureInfo.alloc(current, dir, mouseX*_iwidth, mouseY*_iheight);
    }
}


class MouseGestureInfo {
    public var dir:int=0, x:Number=0, y:Number=0, dist2:Number=0, frames:int=0, next:MouseGestureInfo=null;
    static private var _freeList:MouseGestureInfo = null;
    
    public function init(dir:int, x:Number, y:Number, frames:int) : MouseGestureInfo {
        this.dir = dir;
        this.x = x;
        this.y = y;
        this.frames = frames;
        this.dist2 = 0;
        return this;
    }
    
    static public function alloc(prev:MouseGestureInfo, dir:int, x:Number, y:Number) : MouseGestureInfo {
        prev.next = _freeList || new MouseGestureInfo();
        _freeList = prev.next.next;
        prev.next.next = null;
        prev.next.init(dir, x, y, 1);
        prev.next.dist2 = 0;
        return prev.next;
    }
    
    static public function freeAll(head:MouseGestureInfo) : void {
        for (var last:MouseGestureInfo = head; last.next != null;)  last = last.next;
        last.next = _freeList;
        _freeList = head.next;
        head.next = null;
    }
}

class GestureAnalyzer {
    static private const REP_COSTS:Vector.<int> = Vector.<int>([0,2,4,6,9,6,4,2, 5]);
    static private const DEL_COSTS:Vector.<int> = Vector.<int>([0,1,2,4,8,4,2,1, 4]);
    static private const INS_COSTS:Vector.<int> = Vector.<int>([0,1,2,4,8,4,2,1, 4]);
    static private const POS_COST:int = 5;
    static private const posFlag:Vector.<int> = Vector.<int>([4,3,2,5,0,1,6,7,8]);
    
    private var dict:* = {};
    
    function GestureAnalyzer() {}
    
    public function map(key:String, gesture:String, flagStartPos:int=0, flagEndPos:int=0) : void {
        dict[key] = new GestureAnalyzerInfo(gesture, flagStartPos, flagEndPos);
    }
    
    public var pattern:Vector.<int> = new Vector.<int>();
    public function analyze(head:MouseGestureInfo, threshold:int = 9999) : Array {
        var mincost:int = threshold, info:MouseGestureInfo, flagStartPos:int, flagEndPos:int,
            cost:int, candidates:Array, dictInfo:GestureAnalyzerInfo;
        pattern.length = 0;
        info = (head.next.dir == 0) ? head.next.next : head.next;
        for (; info.next!=null; info=info.next) pattern.push(info.dir);
        flagStartPos = _posFlag(head.next.x, head.next.y);
        flagEndPos   = _posFlag(info.x, info.y);
        for (var key:String in dict) {
            dictInfo = dict[key];
            cost = calcLevenshteinDistance(pattern, dictInfo.pattern);
            cost += (dictInfo.flagStartPos == 0 || dictInfo.flagStartPos == flagStartPos) ? 0 : POS_COST;
            cost += (dictInfo.flagEndPos   == 0 || dictInfo.flagEndPos   == flagEndPos)   ? 0 : POS_COST;
            if (cost < mincost) { 
                mincost = cost; 
                candidates = [key];
            } else if (cost == mincost) {
                candidates.push(key);
            }
        }
        return candidates;
        
        function _posFlag(x:Number, y:Number) : int {
            return posFlag[((x < 0.4) ? 0 : (x < 0.6) ? 1 : 2) + ((y < 0.4) ? 0 : (y < 0.6) ? 3 : 6)];
        }
    }
    
    static private var matrix:Vector.<int> = new Vector.<int>();
    static public function calcLevenshteinDistance(org:Vector.<int>, dst:Vector.<int>) : int {
        var colsize:int = org.length+1, rowsize:int = dst.length+1, matsize:int = colsize * rowsize,
            col:int, row:int, index:int, rep:int, ins:int, del:int, diff:int;
        if (matrix.length < matsize) matrix.length = matsize;
        for (col=0; col<colsize; col++) matrix[col] = col;
        for (row=0, index=0; row<rowsize; row++, index+=colsize) matrix[index] = row;
        colsize--; rowsize--;
        for (col=0; col<colsize; col++) for (row=0; row<rowsize; row++) {
            index = col + row * (colsize+1); // index of [col-1, row-1]
            if (org[col] == 0 || dst[row] == 0) {
                diff = (org[col] == dst[row]) ? 0 : 8;
            } else {
                diff = org[col] - dst[row];
                if (diff < 0) diff = -diff;
            }
            rep = matrix[index] + REP_COSTS[diff];
            index++; // index of [col, row-1]
            del = matrix[index] + DEL_COSTS[diff];
            index += colsize; // index of [col-1, row]
            ins = matrix[index] + INS_COSTS[diff];
            index++; // index of [col, row]
            matrix[index] = (rep < del) ? ((rep < ins) ? rep : ins) : ((del < ins) ? del : ins);
        }
        return matrix[matsize-1];
    }
}


class GestureAnalyzerInfo {
    public var pattern:Vector.<int>, flagStartPos:int, flagEndPos:int;
    function GestureAnalyzerInfo(gesture:String, flagStartPos:int, flagEndPos:int) {
        pattern = new Vector.<int>(gesture.length, true);
        for (var i:int = 0; i<pattern.length; i++) pattern[i] = parseInt(gesture.charAt(i), 16);
        this.flagStartPos = flagStartPos;
        this.flagEndPos = flagEndPos;
    }
}

