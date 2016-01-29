package {
    import flash.display.*;
    import flash.desktop.*;
    import flash.events.*;
    import flash.media.*;
    import flash.utils.*;
    import flash.geom.*;
    import flash.text.*;
    import flash.net.*;
    
    import com.bit101.components.*;
    import org.si.utils.*;
    import org.si.sion.utils.*;
    import org.si.sion.utils.soundfont.*;
    import org.si.sion.*;
    import org.si.sion.module.*;
    
    
    public class main extends Sprite {
        private const SO_VERSION:String = "1";
        
        private var sampleCountIndex:int = 1;
        private var sampleCounts:Array = [32, 64];
        private var sampleCount:int = 64;
        private var barWidth:Number = 6; //384/sampleCount;
        
        private var bitCountIndex:int = 3;
        private var bitCounts:Array = [4,5,6,8];
        private var envelopeType:int = 1;
        private var pickupWidth:int = 6;
        
        private var sion:SiONDriver;
        private var envMML:Vector.<String> = new Vector.<String>();
        private var waveShape:Vector.<Number> = new Vector.<Number>(64);
        private var stacArea:Vector.<Vector.<Number>>;
        private var history:Array = [];
        
        private var mmlInput:InputText;
        private var hexWindow:Window;
        private var hexWindowText:TextField;
        private var hexWindowCopyButton:PushButton;
        private var hexWindowUpdateButton:PushButton;
        
        private var pixels:BitmapData;
        private var bitmap:Bitmap;
        private var screen:Sprite;
        private var shapeLayer:Shape;
        private var pointerIndex:int, pointerRange:int;
        private var pointerChanged:Boolean, screenDragMode:int;
        private var rangeOperator:Number, rangeFunction:Function;
        private var pickupStartPosition:Number;
        private var stacBitmaps:Vector.<Bitmap>;
        private var rc:Rectangle = new Rectangle();
        
        
        function main() {
            addEventListener(Event.ADDED_TO_STAGE, setup);
        }
        
    // main --------------------------------------------------
        private function setup(e:Event) : void {
            removeEventListener(e.type, arguments.callee);

            graphics.beginFill(0);
            graphics.drawRect(0,0,465,465);
            graphics.endFill();
            
            Style.BACKGROUND = 0x404040;
            Style.BUTTON_FACE = 0x606060;
            Style.LABEL_TEXT = 0xaaaaaa;
            Style.INPUT_TEXT = 0xaaaaaa;
            Style.DROPSHADOW = 0;
            Style.PANEL = 0x303030;
            Style.PROGRESS_BAR = 0x404040;
            
            var i:int, j:int;
            pixels = new BitmapData(384, 260, false);
            bitmap = new Bitmap(pixels);
            screen = new Sprite();
            stacBitmaps = new Vector.<Bitmap>(8);
            stacArea = new Vector.<Vector.<Number>>(8);
            for (i=0; i<8; i++) {
                stacArea[i] = new Vector.<Number>(64);
                stacBitmaps[i] = new Bitmap(new BitmapData(62, 18, false, 0));
                addChild(stacBitmaps[i]);
            }
            
            shapeLayer = new Shape();
            screen.addChild(bitmap);
            screen.addChild(shapeLayer);
            screen.x = 8;
            screen.y = 4;
            addChild(screen);
            addEventListener(Event.ENTER_FRAME, draw);
            
            screenDragMode = 0;
            pointerIndex = 0;
            pointerRange = 0;
            pointerChanged = true;
            pickupStartPosition = 0;
            rangeOperator = 0;
            rangeFunction = $offset;
            
            envMML.length = 5;
            envMML[0] = "%4@0,63,0,0,63,15";
            envMML[1] = "%4@0,63,16,16,16,15"; // long
            envMML[2] = "%4@0,63,24,24,24,15"; // middle
            envMML[3] = "%4@0,63,36,36,36,15"; // short
            envMML[4] = "%4@0,26,0,0,63,15";  // soft attack
            
            _loadSharedObject();
            for (i=0; i<sampleCount; i++) waveShape[i] = Math.sin((i+0.5)*Math.PI*2/sampleCount);
            
            _setButtons();
            screen.addEventListener(MouseEvent.MOUSE_DOWN, _onDragStart);
            
            sion = new SiONDriver();
        }
        
        
        private function draw(e:Event) : void {
            var sample:Vector.<Number> = _calcCurrentSample();
            var i:int, imin:int, imax:int, g:Graphics = shapeLayer.graphics;
            imin = pointerIndex + ((pointerRange < 0) ? pointerRange : 0);
            imax = pointerIndex + ((pointerRange > 0) ? pointerRange : 0) + 1;
            if (imin < 0) imin = 0;
            if (imax > sampleCount) imax = sampleCount;
            _rect(0, 0, 384, 260, 0x404040);
            for (i=1; i<4; i++) {
                _rect(i*96-1, 0, 1, 260, 0x408040);
            }
            for (i=0; i<sampleCount; i++) {
                _rect(i*barWidth, 130, barWidth-1, -sample[i]*128, 0x80f0c0);
                if (i<imin || imax<=i) _rect(i*barWidth, -sample[i]*128+128, barWidth-1, 4, 0xf08080);
            }
            _rect(imin*barWidth, -rangeOperator*128+128, (imax-imin)*barWidth-1, 4, 0x8080f0);
            if (pointerChanged) {
                g.clear();
                g.lineStyle(2, 0xff0000);
                g.beginFill(0xffffff, 0.25);
                g.drawRect(imin*barWidth-1, -1, (imax-imin)*barWidth-1, 262);
                pointerChanged = false;
            }
        }
        
        
    // drawing sub routines --------------------------------------------------
        private function _rect(x:Number, y:Number, w:Number, h:Number, c:uint) : void {
            if (h<0) y-=(h=-h);
            rc.setTo(x, y, w, h);
            pixels.fillRect(rc, c);
        }
        
        
        private function _drawMiniWaveImage(pix:BitmapData, wav:Vector.<Number>) : void {
            rc.setTo(0,0,62,18);
            pix.fillRect(rc, 0x808080);
            rc.setTo(1,1,60,16);
            pix.fillRect(rc, 0);
            var imin:int = (sampleCount==32) ? 1 : 2, imax:int = sampleCount-imin, 
                pitch:Number=64/sampleCount;
            for (var i:int=imin; i<imax; i++) {
                if (wav[i] < 0) rc.setTo((i-1)*pitch+1, 9,          pitch, -wav[i]*8);
                else            rc.setTo((i-1)*pitch+1, 9-wav[i]*8, pitch,  wav[i]*8);
                pix.fillRect(rc, 0x4080c0);
                rc.y  = 9 - wav[i]*8;
                rc.height = 1;
                pix.fillRect(rc, 0xc08040);
            }
        }
        
        
    // sub routines --------------------------------------------------
        private var _temp32:Vector.<Number> = new Vector.<Number>(32);
        private var _temp64:Vector.<Number> = new Vector.<Number>(64);
        private function _applyRangeFunction(func:Function) : void {
            var i:int, imin:int, imax:int, istart:int, iend:int;
            imin = pointerIndex + ((pointerRange < 0) ? pointerRange : 0);
            imax = pointerIndex + ((pointerRange > 0) ? pointerRange : 0) + 1;
            istart = (0>imin) ? 0 : imin;
            iend = (sampleCount<imax) ? sampleCount : imax;
            for (i=istart; i<iend; i++) {
                _temp64[i] = func(i, imin, imax);
                if (_temp64[i] > 1) _temp64[i] = 1;
                else if (_temp64[i] < -1) _temp64[i] = -1;
            }
            _stacHistory();
            for (i=istart; i<iend; i++) waveShape[i] = _temp64[i];
        }

        
        private function _loadSharedObject() : void {
            var so:SharedObject = SharedObject.getLocal("WMS_EDITOR"), i:int, si:int;
            if (so && so.data.version == SO_VERSION) {
                if (so.data.stacArea) {
                    for (si=0; si<8; si++) for (i=0; i<64; i++) stacArea[si][i] = so.data.stacArea[si][i];
                }
                if (so.data.sampleCountIndex) {
                    sampleCountIndex = so.data.sampleCountIndex;
                    sampleCount = sampleCounts[sampleCountIndex];
                    barWidth = 384/sampleCount;
                }
                if (so.data.bitCountIndex) bitCountIndex = so.data.bitCountIndex;
                if (so.data.envelopeType)  envelopeType = so.data.envelopeType;
            } else {
                for (si=0; si<8; si++) for (i=0; i<64; i++) stacArea[si][i] = 0;
            }
            for (si=0; si<8; si++) {
                _drawMiniWaveImage(stacBitmaps[si].bitmapData, stacArea[si]);
            }
        }
        
        private function _saveSampleData() : void {
            var so:SharedObject = SharedObject.getLocal("WMS_EDITOR");
            if (so) {
                so.data.version = SO_VERSION;
                so.data.stacArea = stacArea;
                so.flush();
            }
        }
        
        private function _saveSettings() : void {
            var so:SharedObject = SharedObject.getLocal("WMS_EDITOR");
            if (so) {
                so.data.sampleCountIndex = sampleCountIndex;
                so.data.bitCountIndex = bitCountIndex;
                so.data.envelopeType = envelopeType;
                so.flush();
            }
        }
        
        private function _stacHistory() : void {
            var s:Vector.<Number>, i:int;
            if (history.length > 0) {
                s = history[history.length-1];
                for (i=0; i<sampleCount; i++) if (s[i] != waveShape[i]) break;
                if (i == sampleCount) return;
            }
            s = new Vector.<Number>(sampleCount);
            for (i=0; i<sampleCount; i++) s[i] = waveShape[i];
            history.push(s);
        }
        
        private function _undo() : void {
            var s:Vector.<Number> = history.pop(), i:int;
            if (s) for (i=s.length-1; i>=0; i--) waveShape[i] = s[i];
            else   for (i=0; i<sampleCount; i++) waveShape[i] = 0;
        }
        
        private function _checkSound(e:Event) : void {
            sion.setWaveTable(0, _calcCurrentSample());
            sion.play(envMML[envelopeType] + mmlInput.text);
        }
        
        private function _calcCurrentSample() : Vector.<Number> {
            var i:int, imin:int, imax:int, t:Number, sample:Vector.<Number> = (sampleCount==32) ? _temp32 : _temp64;
            var resolution:Number = 1 << bitCounts[bitCountIndex];
            imin = pointerIndex + ((pointerRange < 0) ? pointerRange : 0);
            imax = pointerIndex + ((pointerRange > 0) ? pointerRange : 0) + 1;
            
            var func:Function = (screenDragMode == 1) ? $pickup : rangeFunction;
            for (i=0; i<sampleCount; i++) {
                t = (pointerRange==0 || i<imin || imax<=i) ? waveShape[i] : func(i, imin, imax);
                if (t > 1) t = 1;
                else if (t < -1) t = -1;
                sample[i] = (int((t+1)*0.5*resolution+0.5)) * 2 / resolution - 1;
            }
            
            return sample;
        }
        
        
    // mouse event --------------------------------------------------
        private function _onDragStart(e:MouseEvent) : void {
            var i:int, imin:int, imax:int, pos:Number;
            stage.addEventListener(MouseEvent.MOUSE_MOVE, _onDragging);
            stage.addEventListener(MouseEvent.MOUSE_UP, _onDragEnd);
            imin = pointerIndex + ((pointerRange < 0) ? pointerRange : 0);
            imax = pointerIndex + ((pointerRange > 0) ? pointerRange : 0) + 1;
            _calcCurrentPosition();
            pos = rangeOperator;
            if (pointerRange != 0 && imin <= currentIndex && currentIndex < imax && pos-0.15<currentValue && currentValue<pos+0.15) {
                screenDragMode = 2; // drag range operator
            } else {
                if (pointerRange != 0) _applyRangeFunction(rangeFunction);
                rangeOperator = 0;
                pos = waveShape[currentIndex];
                if (pos-0.15 < currentValue && currentValue < pos+0.15) {
                    screenDragMode = 1;  // pick up mode
                    rangeOperator = pickupStartPosition = pos;
                    pointerIndex = currentIndex - (pickupWidth>>1);
                    pointerRange = pickupWidth;
                    _stacHistory();
                } else {
                    screenDragMode = 3; // change range
                    if (imin-1 <= currentIndex && currentIndex <= imin+1) {
                        pointerIndex = imax - 1;
                        pointerRange = imin - imax;
                    } else 
                    if (imax-1 <= currentIndex && currentIndex <= imax+1) {
                        pointerIndex = imin;
                        pointerRange = imin - imax;
                    } else {
                        pointerIndex = currentIndex;
                        pointerRange = 0;
                    }
                }
            }
            pointerChanged = true;
            _onDragging(e);
        }
        
        
        private function _onDragging(e:MouseEvent) : void {
            _calcCurrentPosition();
            switch(screenDragMode) {
            case 1:
            case 2:
                rangeOperator = currentValue;
                break;
            case 3:
                pointerChanged = true;
                pointerRange = currentIndex - pointerIndex;
                break;
            }
        }
        
        
        private function _onDragEnd(e:MouseEvent) : void {
            _onDragging(e);
            switch(screenDragMode) {
            case 1:
                _applyRangeFunction($pickup);
                pickupStartPosition = rangeOperator = 0;
                pointerIndex += pickupWidth>>1;
                pointerRange = 0;
                break;
            case 3:
                pointerChanged = true;
                pointerRange = currentIndex - pointerIndex;
                break;
            }
            pointerChanged = true;
            screenDragMode = 0;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, _onDragging);
            stage.removeEventListener(MouseEvent.MOUSE_UP, _onDragEnd);
        }
        
        
        private var currentIndex:int, currentValue:Number;
        private function _calcCurrentPosition() : void {
            currentIndex = int(screen.mouseX / barWidth);
            currentValue = Number((screen.mouseY-128) * -0.0078125);
                 if (currentIndex < 0)  currentIndex = 0;
            else if (currentIndex > sampleCount-1) currentIndex = sampleCount-1;
                 if (currentValue < -1) currentValue = -1;
            else if (currentValue > 1)  currentValue = 1;
        }
        
        
        private function get hexString() : String {
            var str:String = "", i:int, s:int, wav:Vector.<Number> = _calcCurrentSample();
            for (i=0; i<sampleCount; i++) {
                s = (wav[i]+1) * 128;
                s = (s<128) ? (s+128) : (s<256) ? (s-128) : 127;
                str += ("0" + s.toString(16)).substr(-2, 2);
            }
            return str;
        }
        private function set hexString(str:String) : void {
            var hexLength:int = str.length >> 1, i:int, n:Number, 
                imax:int = (hexLength<64) ? hexLength : 64;
            for (i=0; i<imax; i++) {
                n = parseInt(str.substr(i*2, 2), 16); // 1/128                
                waveShape[i] = (n<128) ? (n * 0.0078125) : ((n-256) * 0.0078125);
            }
        }
        
        
    // interfaces --------------------------------------------------
        private var buttonSelector:Shape;
        private var buttonX:Number, buttonY:Number;
        private function _setButtons() : void {
            var i:int;
            
            var test:PushButton = new PushButton(this, 8, 268, "Check sound !!", _checkSound);
            test.width = 318;
            test.height = 22;
            mmlInput = new InputText(this, 328, 269, "cdefgab<c1");
            mmlInput.width = 126;
            mmlInput.height = 20;
            
            buttonX = 396;
            buttonY = 4;
            _label("[Sample count]");
            _radios($changeSampleCount, "Sample count", ["32samples", "64samples"], sampleCountIndex);
            _label("[Bit count]");
            _radios($changeBitCount, "Bit count", ["4 bits", "5 bits", "6 bits", "8 bits"], bitCountIndex);
            _label("[Envelop type]");
            _radios($changeEnvelopeType, "Envelop type", ["constant", "long", "middle", "short", "soft attack"], envelopeType);
            
            buttonX = 8;
            buttonY = 294;
            _buttonImm("zero fill ", $clear);
            _buttonImm("linear", $linear);
            _buttonImm("half cos", $cosine);
            _buttonImm("triangle", $triangle);
            _buttonImm("sine", $sine);
            _buttonImm("square", $square);
            _buttonImm("random", $random);
            
            buttonX = 8;
            buttonY += 24;
            _slider($pickupWidth, ["PW:1", "PW:3", "PW:5", "PW:7", "PW:9", "PW:11", "PW:13", "PW:15", "PW:17"], 3);
            _buttonImm("UNDO",   $undo);
            _buttonImm("SELECT_ALL", $selectAll, 128);
            _buttonImm("HEX WINDOW", $hexWindow, 128);

            buttonX = 8;
            buttonY += 20;
            _buttonImm("COPY",   $copy);
            _buttonImm("PASTE",  $paste);
            _buttonImm("INVERT",  $invert);
            _buttonImm("REVERSE", $reverse);
            _buttonImm("MAXIMIZE", $maximize);
            buttonX += 64;
            buttonY += 4;
            _buttonImm("Reset cbar", $barReset, 64, false);
            
            buttonX = 8;
            buttonY += 20;
            _buttonImm(">> Operator", $$stac(7));
            stacBitmaps[7].x = buttonX;
            stacBitmaps[7].y = buttonY;
            buttonX += 64;
            _slider($mult, ["ml=1", "ml=2", "ml=3", "ml=4", "ml=5", "ml=6", "ml=7", "ml=8"]);
            _button("Blend...",    $blend);
            _button("Ring mod...", $ring);
            _button("Freq.mod...", $phase);
            
            buttonX = 8;
            buttonY += 20;
            var offsetButton:PushButton = _button("Offset...",  $offset);
            _button("Scale...",   $scale);
            _button("Stretch...", $stretch);
            _button("Inflate...", $shaper);
            _button("Pinch...",   $pinch);
            _button("Rotate...",  $rotate);
            _button("Terrible...",$terrible);
            
            buttonX = 8;
            buttonY += 44;
            for (i=0; i<7; i++) {
                stacBitmaps[i].x = buttonX;
                stacBitmaps[i].y = buttonY-20;
                _buttonImm(">> Memory", $$stac(i));
            }
            buttonX = 8;
            buttonY += 20;
            for (i=0; i<7; i++) {
                _buttonImm("<< Remem.", $$pick(i));
            }
            
            hexWindow = new Window(this, 50, 150, "hex");
            hexWindow.visible = false;
            hexWindow.draggable = false;
            hexWindow.hasCloseButton = true;
            hexWindow.width  = 465-hexWindow.x*2;
            hexWindow.height = 465-hexWindow.y*2;
            hexWindow.addEventListener(Event.CLOSE, _onHexWindowClosed);
            hexWindowText = new TextField();
            hexWindowText.defaultTextFormat = new TextFormat("_sans", 12, Style.INPUT_TEXT);
            hexWindowText.x = 2;
            hexWindowText.y = 2;
            hexWindowText.width  = hexWindow.width - 4;
            hexWindowText.height = hexWindow.height - 66;
            hexWindowText.background = true;
            hexWindowText.backgroundColor = 0;
            hexWindowText.multiline = true;
            hexWindowText.wordWrap = true;
            hexWindowText.selectable = true;
            hexWindowText.type = TextFieldType.INPUT;
            hexWindow.content.addChild(hexWindowText);
            hexWindowUpdateButton = new PushButton(hexWindow.content, 2, hexWindow.height-62, "Update data from HEX", onUpdateHex);
            hexWindowCopyButton   = new PushButton(hexWindow.content, 2, hexWindow.height-42, "Send HEX to clipboard", onCopyHex);
            hexWindowUpdateButton.width  = hexWindowCopyButton.width = hexWindowText.width;
            hexWindowUpdateButton.height = hexWindowCopyButton.height = 20;
            
            buttonSelector = new Shape();
            buttonSelector.graphics.beginFill(0x4080ff, 0.25);
            buttonSelector.graphics.drawRect(0,0,62,20);
            buttonSelector.graphics.endFill();
            buttonSelector.x = offsetButton.x;
            buttonSelector.y = offsetButton.y;
            addChild(buttonSelector);
            
            _stac = stacArea[7];
        }
        private function _label(lbl:String) : Label {
            var label:Label = new Label(this, buttonX, buttonY, lbl);
            label.width = 64;
            label.height = 18;
            buttonY += 20;
            return label;
        }
        private function _button(lbl:String, func:Function) : PushButton {
            var pb:PushButton = new PushButton(this, buttonX, buttonY, lbl, $(func));
            buttonX += 64;
            pb.width = 62;
            pb.height = 18;
            return pb;
            function $(func:Function) : Function {
                return function(e:Event) : void {
                    if (pointerRange != 0) _applyRangeFunction(rangeFunction);
                    rangeOperator = 0;
                    buttonSelector.x = e.target.x;
                    buttonSelector.y = e.target.y;
                    rangeFunction = func;
                };
            }
        }
        private function _buttonImm(lbl:String, immidiateAction:Function, w:Number=64, applyRangeFunc:Boolean=true) : PushButton {
            var pb:PushButton = new PushButton(this, buttonX, buttonY, lbl, $(immidiateAction, applyRangeFunc));
            buttonX += w;
            pb.width = w - 2;
            pb.height = 18;
            return pb;
            function $(func:Function, apply:Boolean) : Function {
                return function(e:Event) : void {
                    if (apply && pointerRange != 0) {
                        _applyRangeFunction(rangeFunction);
                        rangeOperator = 0;
                    }
                    var imin:int = pointerIndex + ((pointerRange < 0) ? pointerRange : 0),
                        imax:int = pointerIndex + ((pointerRange > 0) ? pointerRange : 0) + 1;
                    immidiateAction(imin, imax);
                };
            }
        }
        private function _slider(action:Function, labels:Array, initValue:int=0) : HSlider {
            var slider:HSlider = new HSlider(this, buttonX+32, buttonY+1, $(action, new Label(this, buttonX+2, buttonY, labels[initValue])));
            slider.width = 94;
            slider.height = 16;
            slider.setSliderParams(0, labels.length-0.1, initValue);
            buttonX += 128;
            return slider;
            function $(func:Function, label:Label) : Function { 
                return function(e:Event) : void {
                    var index:int = int(e.target.value);
                    label.text = labels[index];
                    func(index);
                };
            }
        }
        private function _radios(action:Function, groupName:String, labels:Array, checkedIndex:int) : Array {
            var rad:RadioButton, handler:Function = $(action, labels), ret:Array = [];
            for (var i:int=0; i<labels.length; i++) {
                rad = new RadioButton(this, buttonX, buttonY, labels[i], (checkedIndex==i), handler);
                rad.groupName = groupName;
                rad.width = 64;
                rad.height = 16;
                buttonY += 18;
                ret.push(rad);
            }
            return ret;
            function $(action:Function, labels:Array) : Function {
                return function(e:Event) : void { 
                    var i:int, imax:int = labels.length;
                    for (i=0; i<imax; i++) if (e.target.label == labels[i]) {
                        action(i);
                        return;
                    }
                }
            };
        }
        
        
    // actions --------------------------------------------------
        // global
        private function $changeSampleCount(index:int) : void {
            if (sampleCountIndex != index) {
                sampleCountIndex = index;
                sampleCount = sampleCounts[index];
                barWidth = 384/sampleCount;
                if (pointerIndex > sampleCount) {
                    pointerIndex = sampleCount - 1;
                    pointerRange = 0;
                } else 
                if (pointerIndex + pointerRange >= sampleCount) {
                    pointerRange = sampleCount - pointerIndex - 1;
                }
                pointerChanged = true;
                
                for (var si:int=0; si<8; si++) {
                    _drawMiniWaveImage(stacBitmaps[si].bitmapData, stacArea[si]);
                }
                _saveSettings();
                _saveSampleData();
            }
        }
        private function $changeBitCount(index:int) : void {
            bitCountIndex = index;
            _saveSettings();
        }
        private function $changeEnvelopeType(index:int) : void {
            envelopeType = index;
            _saveSettings();
        }
        
        private function $pickup(i:int, imin:int, imax:int) : Number {
            var n:Number = rangeOperator - pickupStartPosition,
//              r:Number = 2/(imax-imin+1)*((i+i<=imax+imin)?(i-imin+1):(imax-i)); // linear
                r:Number = -Math.cos(Math.PI*2*(i-imin+1)/(imax-imin+1))*0.5+0.5; // cosine
            return waveShape[i] + n*r;
        }

        // actions controled by rangeOperator
        private function $offset(i:int, imin:int, imax:int) : Number { return waveShape[i] + rangeOperator; }
        private function $scale(i:int, imin:int, imax:int) : Number { return waveShape[i] * (rangeOperator+1); }
        private function $stretch(i:int, imin:int, imax:int) : Number {
            var imid:Number = (imax+imin-1)*0.5,
                c:Number = (i - imid) * Math.pow(8,rangeOperator) + imid, ic:int = int((c<0) ? (c-1) : c), 
                r:Number = c - ic, ic32:int = ic & (sampleCount - 1);
            return waveShape[ic32]*(1-r) + waveShape[(ic32+1)&(sampleCount-1)]*r;
        }
        private function $shaper(i:int, imin:int, imax:int) : Number {
            var r1:Number = rangeOperator+1.0000152587890625;
            return (waveShape[i]<0) ? -Math.pow(-waveShape[i],r1*r1) : Math.pow(waveShape[i],r1*r1);
        }
        private function $pinch(i:int, imin:int, imax:int) : Number {
            var pt:Number, hw:Number, n:Number, t:Number = (i-imin)/(imax-imin-1);
            if (rangeOperator<0) {
                pt = -rangeOperator*10;
                t = (t < 0.5) ? (t + 0.5) : (t - 0.5);
            } else {
                pt = rangeOperator*10;
            }
            hw = 1/(pt+2);
                 if (t < hw)   n = pt * (-0.5/hw * t + 1 - hw) * t;
            else if (t < 1-hw) n = pt * hw * (0.5 - t);
            else               n = pt * ((0.5/hw * t + 1 - hw - 1/hw) * t -1 + hw + 0.5/hw);
            var c:Number = i + n * sampleCount, ic:int = int((c<0) ? (c-1) : c), 
                r:Number = c - ic, ic32:int = ic & (sampleCount - 1);
            return waveShape[ic32]*(1-r) + waveShape[(ic32+1)&(sampleCount-1)]*r;
        }
        private function $rotate(i:int, imin:int, imax:int) : Number {
            var n:Number = i + (rangeOperator+0.0000152587890625) * (imax-imin);
            var index:int = int((n<0)?(n-1):n);
            if (index < imin) index += imax-imin;
            else if (index >= imax) index -= imax-imin;
            return waveShape[index];
        }
        private function $terrible(i:int, imin:int, imax:int) : Number {
            return waveShape[i] *(1+((rangeOperator<0)?rangeOperator:-rangeOperator)) + ((i&1)*2-1) * rangeOperator;
        }
        
        // immidiate actions
        private var _clip:Vector.<Number> = new Vector.<Number>();
        private function $clear (imin:int, imax:int) : void { for (var i:int=imin; i<imax; i++) waveShape[i] = 0; }
        private function $copy(imin:int, imax:int) : void {
            var i:int, ci:int, cimax:int = imax - imin;
            _clip.length = cimax;
            for (i=imin, ci=0; ci<cimax; i++, ci++) _clip[ci] = waveShape[i];
        }
        private function $paste(imin:int, imax:int) : void {
            var i:int, ci:int, cimax:int = _clip.length;
            if (cimax == 0) return;
            if (imax - imin < 2) imax = (imin+cimax<sampleCount) ? (imin+cimax) : sampleCount;
            for (i=imin, ci=0; i<imax; i++, ci++) waveShape[i] = _clip[ci%cimax];
        }
        private function $selectAll(imin:int, imax:int) : void {
            pointerIndex = 0;
            pointerRange = sampleCount - 1;
            pointerChanged = true;
        }
        private function $undo(imin:int, imax:int) : void {
            pointerRange = 0;
            pointerChanged = true;
            _undo();
        }
        private function $hexWindow(imin:int, imax:int) : void {
            hexWindowText.text = hexString;
            hexWindow.visible = true;
        }
        private function onUpdateHex(e:Event) : void {
            hexString = hexWindowText.text;
            hexWindow.visible = false;
        }
        private function onCopyHex(e:Event) : void {
            Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, hexWindowText.text);
            hexWindow.visible = false;
        }
        private function _onHexWindowClosed(e:Event): void {
            hexWindow.visible = false;
        }
        
        
        private function $invert(imin:int, imax:int) : void { for (var i:int=imin; i<imax; i++) waveShape[i] = -waveShape[i]; }
        private function $reverse(imin:int, imax:int) : void {
            var i:int, j:int=imax-1, n:Number;
            imax = ((imax - imin) >> 1) + imin;
            for (i=imin; i<imax; i++, j--) {
                n = waveShape[j];
                waveShape[j] = waveShape[i];
                waveShape[i] = n;
            }
        }
        private function $maximize(imin:int, imax:int) : void {
            var i:int, max:Number = 0;
            for (i=imin; i<imax; i++) {
                     if (max <  waveShape[i]) max =  waveShape[i];
                else if (max < -waveShape[i]) max = -waveShape[i];
            }
            max = (max == 0) ? 0 : (1/max);
            for (i=imin; i<imax; i++) waveShape[i] *= max;
        }
        private function $pickupWidth(index:int) : void {
            pickupWidth = index * 2;
        }
        
        private var _stac:Vector.<Number> // = stacArea[7];
        private var _mul:Number = 1;
        private function $blend(i:int, imin:int, imax:int) : Number {
            var si:int = (i * _mul) & (sampleCount - 1);
            return waveShape[i] * (1+((rangeOperator<0)?rangeOperator:-rangeOperator)) + _stac[si] * rangeOperator;
        }
        private function $ring(i:int, imin:int, imax:int) : Number {
            var si:int = (i * _mul) & (sampleCount - 1);
            return waveShape[i] * ((rangeOperator<0)?(1+(1+_stac[si])*rangeOperator):(1-(1-_stac[si])*rangeOperator));
        }
        private function $phase(i:int, imin:int, imax:int) : Number {
            var si:int = (i * _mul) & (sampleCount - 1),
                c:Number = i + _stac[si] * rangeOperator * sampleCount, ic:int = int((c<0) ? (c-1) : c), 
                r:Number = c - ic, ic32:int = ic & (sampleCount - 1);
            return waveShape[ic32]*(1-r) + waveShape[(ic32+1)&(sampleCount-1)]*r;
        }
        private function $mult(i:int) : void {
            _mul = i+1;
        }
        private function $barReset(imin:int, imax:int) : void {
            rangeOperator = 0;
        }

        // stac area operation
        private function $$stac(stacIndex:int) : Function {
            return function(imin:int, imax:int) : void {
                var i:int, s:Vector.<Number>=stacArea[stacIndex];
                for (i=0; i<sampleCount; i++) s[i] = waveShape[i];
                _saveSampleData();
                _drawMiniWaveImage(stacBitmaps[stacIndex].bitmapData, s);
            };
        }
        private function $$pick(stacIndex:int) : Function {
            return function(imin:int, imax:int) : void {
                _stacHistory();
                var i:int, s:Vector.<Number>=stacArea[stacIndex];
                for (i=0; i<sampleCount; i++) waveShape[i] = s[i];
            };
        }
        
        // patch wave
        private function $linear(imin:int, imax:int) : void {
            if (imax - imin < 2) return;
            var i:int, n:Number = 2/(imax-imin-1);
            for (i=imin; i<imax; i++) waveShape[i] = 1-((i-imin)*n);
            
        }
        private function $cosine(imin:int, imax:int) : void {
            if (imax - imin < 2) return;
            var i:int, n:Number = Math.PI/(imax-imin-1);
            for (i=imin; i<imax; i++) waveShape[i] = Math.cos((i-imin)*n);
        }
        private function $sine(imin:int, imax:int) : void {
            if (imax - imin < 2) return;
            var i:int, n:Number = Math.PI*2/(imax-imin);
            for (i=imin; i<imax; i++) waveShape[i] = Math.sin((i-imin+0.5)*n);
        }
        private function $triangle(imin:int, imax:int) : void {
            if (imax - imin < 2) return;
            var i:int, n:Number = 4/(imax-imin), m:Number;
            for (i=imin; i<imax; i++) {
                m = (i-imin+0.5) * n;
                waveShape[i] = (m<1)?m:(m<3)?(2-m):(m-4);
            }
        }
        private function $square(imin:int, imax:int) : void {
            var i:int, imid:int = (imax+imin)>>1;
            for (i=imin; i<imax; i++) waveShape[i] = (i<imid)? 1:-1;
        }
        private function $random(imin:int, imax:int) : void {
            for (var i:int=imin; i<imax; i++) waveShape[i] = Math.random() * 2 - 1;
        }
    }
}

