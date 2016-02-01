package {
    import flash.display.*;
    import flash.events.*;
    import flash.text.*;
    import flash.utils.*;
    
    public class main extends Sprite {
        public const DETECTION_TIMEOUT:int = 1000;
        
        public var gesturePad:GesturePad;
        public var gestureAnalyzer:GestureAnalyzer = new GestureAnalyzer();
        public var tf:TextField = new TextField();
        public var detected:TextField = new TextField();
        public var detectionTimer:Timer = new Timer(DETECTION_TIMEOUT, 1);
        
        function main() {
            graphics.beginFill(0xc0c0d0);
            graphics.drawRect(0,0,465,465);
            graphics.endFill();
            gesturePad = new GesturePad(this, 32, 16, 400, onMouseDown, onMouseUp);
            addEventListener(Event.ADDED_TO_STAGE, setup);
            
            // 432
            // 5*1
            // 678
            gestureAnalyzer.map("あ", "10078007654321876");
            gestureAnalyzer.map("い", "78008");
            gestureAnalyzer.map("う", "18001876");
            gestureAnalyzer.map("え", "180016218781");
            gestureAnalyzer.map("お", "10076543218765008");
            gestureAnalyzer.map("か", "187600760087");
            gestureAnalyzer.map("き", "10010080081");
            gestureAnalyzer.map("く", "68");
            gestureAnalyzer.map("け", "7200210076");
            gestureAnalyzer.map("こ", "1800781");
            gestureAnalyzer.map("さ", "21007800781"); //せ
            gestureAnalyzer.map("し", "7812");
            gestureAnalyzer.map("す", "1007654321876"); //よ
            gestureAnalyzer.map("せ", "1007600781");
            gestureAnalyzer.map("そ", "1612678");
            gestureAnalyzer.map("た", "1006700210081");
            gestureAnalyzer.map("ち", "100621876");
            gestureAnalyzer.map("つ", "21876");
            gestureAnalyzer.map("て", "12678");
            gestureAnalyzer.map("と", "80056781");
            gestureAnalyzer.map("な", "100600850076543218"); //ま
            gestureAnalyzer.map("に", "700100781");
            gestureAnalyzer.map("ぬ", "8007654321876543218");
            gestureAnalyzer.map("ね", "70012621876543218");
            gestureAnalyzer.map("の", "654321876");
            gestureAnalyzer.map("は", "7200210076543218");
            gestureAnalyzer.map("ひ", "1267812381");
            gestureAnalyzer.map("ふ", "85007876540078008");
            gestureAnalyzer.map("へ", "218");
            gestureAnalyzer.map("ほ", "7200210010076543218");
            gestureAnalyzer.map("ま", "10010076543218");
            gestureAnalyzer.map("み", "126543218006");
            gestureAnalyzer.map("む", "1007654321878123008");
            gestureAnalyzer.map("め", "8007654321876");
            gestureAnalyzer.map("も", "78123001001");
            gestureAnalyzer.map("や", "21876500700800"); //か
            gestureAnalyzer.map("ゆ", "73218765400876");
            gestureAnalyzer.map("よ", "10076543218");
            gestureAnalyzer.map("ら", "8500621876"); //ち
            gestureAnalyzer.map("り", "72001876"); //い
            gestureAnalyzer.map("る", "12621876543218");
            gestureAnalyzer.map("れ", "7001262678");
            gestureAnalyzer.map("ろ", "12621876");
            gestureAnalyzer.map("わ", "70012621876");
            gestureAnalyzer.map("を", "10062187006781");
            gestureAnalyzer.map("ん", "621812");
            gestureAnalyzer.map("１", "27", 0, 7);
            gestureAnalyzer.map("２", "18761", 0, 8);
            gestureAnalyzer.map("３", "1876518765");
            gestureAnalyzer.map("４", "610067");
            gestureAnalyzer.map("５", "718765001");
            gestureAnalyzer.map("６", "67812345", 0, 5);
            gestureAnalyzer.map("７", "16", 0, 7);
            gestureAnalyzer.map("７'", "60016", 0, 7);
            gestureAnalyzer.map("８", "5678765432");
            gestureAnalyzer.map("９", "5678126");
            gestureAnalyzer.map("０", "67812345", 0, 3);
            
            tf.width = 465;
            tf.height = 32;
            addChild(tf);
        }
        
        public function setup(e:Event) : void {
            e.target.removeEventListener(e.type, arguments.callee);
            detectionTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { detect(); });
            detectionTimer.stop();
        }
        
        public function onMouseDown() : void {
            detectionTimer.stop();
        }
        
        public function onMouseUp() : void {
            detectionTimer.reset();
            detectionTimer.start();
        }
        
        public function detect() : void {
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
            g.moveTo(width * 0.0625 * i, 2);
            g.lineTo(width * 0.0625 * i, height-2);
        }
        frontBase.draw(s);
        frontBase.fillRect(new Rectangle(width*0.5-1, 0, 2, height), 0xffcccccc);
        frontBase.fillRect(new Rectangle(0, height*0.5-1, width, 2), 0xffcccccc);
        front.bitmapData.copyPixels(frontBase, frontBase.rect, frontBase.rect.topLeft);
        textField.defaultTextFormat = new TextFormat("_sans", 64, 0xff0000, null, null, null, null, null, "center");
        textField.autoSize = "center";
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
        textBitmap.draw(textField, new Matrix(h*0.015625,0,0,h*0.015625,-w*0.275,-h*0.075));
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
        setSize(size, size);
        addChild(back = new Sprite());
        back.addChild(textField = new TextDroppingField(size, size));
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
             if (a > 2.747) dir = 3; // tan(70)
        else if (a > 0.364) dir = 2; // tan(20)
        else if (a >-0.364) dir = 1;
        else if (a >-2.747) dir = 4;
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
        flagStartPos = _posFlag(head.x, head.y);
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

