// An extension of ColorChooser in minimalcomps with the Gimp type selectors.
package {
    import flash.display.*;
    import flash.events.*;
    import com.bit101.components.*;
    
    public class ColorChooserExContainer extends Sprite {
        function ColorChooserExContainer() {
            if (stage) {
                new ColorChooserEx(this, 10, 10, 0x4488ff).alphaEnabled = true;
                new InputText(this, 8, 443, loaderInfo.url).setSize(450, 16);
            }
        }
        
        public function getClass() : Class { return ColorChooserEx; }
    }
}

import flash.display.*;
import flash.events.*;
import flash.filters.*;
import flash.geom.*;
import com.bit101.components.*;


function hsv2rgb(h:Number, s:Number, v:Number) : uint {
    var ht:Number=(h-int(h)+int(h<0))*6, hi:int=int(ht), vt:Number=v*255;
    switch(hi) {
        case 0: return 0xff000000|(vt<<16)|(int(vt*(1-(1-ht+hi)*s))<<8)|int(vt*(1-s));
        case 1: return 0xff000000|(vt<<8)|(int(vt*(1-(ht-hi)*s))<<16)|int(vt*(1-s));
        case 2: return 0xff000000|(vt<<8)|int(vt*(1-(1-ht+hi)*s))|(int(vt*(1-s))<<16);
        case 3: return 0xff000000|vt|(int(vt*(1-(ht-hi)*s))<<8)|(int(vt*(1-s))<<16);
        case 4: return 0xff000000|vt|(int(vt*(1-(1-ht+hi)*s))<<16)|(int(vt*(1-s))<<8);
        case 5: return 0xff000000|(vt<<16)|int(vt*(1-(ht-hi)*s))|(int(vt*(1-s))<<8);
    }
    return 0;
}

function rgb2hsv(r:int, g:int, b:int) : uint { // h:12bit,s:10bit,v:8bit
    var max:int, min:int, sv:int;
    if (r>g) { if (g>b) {min=b;max=r;} else {min=g;max=(r>b)?r:b;} } 
    else     { if (g<b) {max=b;min=r;} else {max=g;min=(r<b)?r:b;} }
    if (max == min) return max;
    sv = (int((max - min) * 1023 / max)<<8) | max;
    if (b==max) return (int((r-g)*682.6666666666666/(max-min)+2730.6666666666665)<<18)|sv;
    if (g==max) return (int((b-r)*682.6666666666666/(max-min)+1365.3333333333332)<<18)|sv;
    if (g>=b) return (int((g-b)*682.6666666666666/(max-min))<<18)|sv;
    return (int(4096+(g-b)*682.6666666666666/(max-min))<<18)|sv;
}

class ColorChooserEx extends ColorChooser {
//-------------------------------------------------- constants
    public static const PANEL_WIDTH:int = 160;
    public static const PANEL_HEIGHT:int = 134;
    
//-------------------------------------------------- variables
    protected var uniqueDefaultModel:Sprite = null;
    protected var originalDefaultModel:Sprite = null;
    protected var dummyBackground:Sprite;
    protected var mainPanel:Panel, tabLine:Shape = new Shape();
    protected var tabs:Array, models:Array = [];
    protected var _selectedTab:int = 0;
    protected var _changeImmediately:Boolean = true;
    protected var _alphaEnabled:Boolean = false;
    protected var _alpha:Number = 1;
    protected var _alphaBar:VColorBar;
    protected var _alphaMap:BitmapData;
    protected var _alphaTile:AlphaTile;
    protected var _alphaValue:InputText;
    
//-------------------------------------------------- properties
    public function get selectedTab() : int { return _selectedTab; }
    public function set selectedTab(idx:int) : void {
        _selectedTab = idx;
        for each (var model:Sprite in models) model.visible = false;
        models[_selectedTab].visible = true;
        models[_selectedTab].value = value;
        tabLine.x = _selectedTab * 40;
    }
    public function get changeImmediately() : Boolean { return _changeImmediately; }
    public function set changeImmediately(b:Boolean) : void { _changeImmediately = b; }
    public function get alphaEnabled() : Boolean { return _alphaEnabled; }
    public function set alphaEnabled(b:Boolean) : void { _showAlphaControler(_alphaEnabled = b); }
    public function get alphaValue() : Number { return (_alphaEnabled) ? _alpha: 1; }
    public function set alphaValue(n:Number) : void { _alpha = (n>1) ? 1 : (n<0) ? 0 : n; }
    override public function set value(u:uint) : void {
        var ua:int = u>>>24;
        super.value = u & 0xffffff;
        if (ua > 0) alphaValue = ua/255;
        if (_alphaEnabled)  _updateTextInputAlpha();
    }
    
//-------------------------------------------------- constructor
    function ColorChooserEx(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0, value:uint = 0xff0000, defaultHandler:Function = null) {
        super(parent, xpos, ypos, value, defaultHandler);
        usePopup = true;
    }
    
//-------------------------------------------------- modifications
    override protected function onColorsRemovedFromStage(e:Event) : void {
        dummyBackground.removeEventListener(MouseEvent.CLICK, onStageClick);
    }
    
    override protected function onColorsAddedToStage(e:Event) : void {
        _stage = stage;
        dummyBackground.graphics.clear();
        dummyBackground.graphics.beginFill(0, 0);
        dummyBackground.graphics.drawRect(-_stage.stageWidth, -_stage.stageHeight, _stage.stageWidth*2, _stage.stageHeight*2);
        dummyBackground.graphics.endFill();
        dummyBackground.addEventListener(MouseEvent.CLICK, onStageClick);
        models[_selectedTab].value = value;
    }

    override protected function onStageClick(e:MouseEvent):void {
        setColorChoiceEx();
    }
    
    override protected function drawColors(d:DisplayObject) : void {
        while (_colorsContainer.numChildren) _colorsContainer.removeChildAt(0);
        _colorsContainer.addChild(d); // currently always (d === _model)
        placeColors();
    }
    
    override public function set usePopup(b:Boolean):void {
        _usePopup = b;
        _swatch.buttonMode = true;
        _swatch.addEventListener(MouseEvent.CLICK, onSwatchClick);
        if (!_usePopup) {
            _swatch.buttonMode = false;
            _swatch.removeEventListener(MouseEvent.CLICK, onSwatchClick);
        }
    }
    
    override protected function placeColors():void{
        var point:Point = new Point(x, y);
        if (parent) point = parent.localToGlobal(point);
        switch (_popupAlign) {
            case TOP : 
            _colorsContainer.x = point.x;
            _colorsContainer.y = point.y - PANEL_HEIGHT - 4;
            break;
            case BOTTOM : 
            _colorsContainer.x = point.x;
            _colorsContainer.y = point.y + 22;
            break;
            default: 
            _colorsContainer.x = point.x;
            _colorsContainer.y = point.y + 22;
            break;
        }
    }
    
    override public function draw() : void {
        super.draw();
        if (_alphaEnabled) {
            _swatch.graphics.clear();
            _swatch.graphics.beginBitmapFill(_alphaTile.tile)
            _swatch.graphics.drawRect(0, 0, 16, 16);
            _swatch.graphics.endFill();
            _swatch.graphics.beginFill(_value, _alpha);
            _swatch.graphics.drawRect(0, 0, 16, 16);
            _swatch.graphics.endFill();
            _updateAlphaBar();
        }
    }
    

//-------------------------------------------------- for interactive selectors
    public function browseColorChoiceEx(col:uint, alp:Number=Number.NaN) : void {
        if (!isNaN(alp)) alphaValue = alp;
        value = _tmpColorChoice = col;
        if (_changeImmediately) dispatchEvent(new Event(Event.CHANGE));
    }
    //public function backToColorChoiceEx() : void { value = _oldColorChoice; }
    public function setColorChoiceEx() : void {
        models[3].memory(_oldColorChoice = value);
        dispatchEvent(new Event(Event.CHANGE));
        displayColors();
    }
    
//-------------------------------------------------- alpha selector
    protected function _showAlphaControler(show:Boolean) : void {
        mainPanel.setSize(PANEL_WIDTH+((show)?32:0), PANEL_HEIGHT);
        _swatch.x = (_input.width = (show)?60:45) + 5;
        _alphaBar.visible = show;
        _alphaValue.visible = show;
        _updateAlphaBar();
        invalidate();
    }
    
    protected function _onAlphaChanged(e:Event) : void {
        alphaValue = _alphaBar.valueY;
        _alphaValue.text = (int(_alpha*100)).toString();
        _updateTextInputAlpha();
        invalidate();
    }
    
    protected function _onAlphaEdit(e:Event) : void {
        alphaValue = Number(_alphaValue.text) * 0.01;
        _alphaBar.valueY = _alpha;
        _updateTextInputAlpha();
        invalidate();
    }
    
    protected function _updateAlphaBar() : void {
        var a:Number, rc:Rectangle = new Rectangle(0,0,12,1), col:uint = _value;
        for (a=1; rc.y<100; a-=0.01, rc.y+=1) _alphaMap.fillRect(rc, (a*255)<<24|col);
        _alphaBar.pixels.draw(_alphaTile);
        _alphaBar.pixels.draw(_alphaMap);
    }
    
    protected function _updateTextInputAlpha() : void {
        var str:String = (uint((_alpha*255)<<24|_value)).toString(16).toUpperCase();
        while(str.length < 8) str = "0" + str;
        _input.text = str;
    }
    
//-------------------------------------------------- exchange default model
    override protected function getDefaultModel() : Sprite {
        var x_:Number = 0;
        if (uniqueDefaultModel) return uniqueDefaultModel;
        originalDefaultModel = super.getDefaultModel();
        uniqueDefaultModel = new Sprite();
        dummyBackground = new Sprite();
        uniqueDefaultModel.addChild(dummyBackground);
        mainPanel = new Panel(uniqueDefaultModel);
        mainPanel.setSize(PANEL_WIDTH, PANEL_HEIGHT);
        tabs   = [newTab("Gimp"), newTab("Bars"), newTab("Hue"), newTab("Mem")];
        models = [new GimpModel(mainPanel.content, this), 
                  new BarsModel(mainPanel.content, this), 
                  new HueModel(mainPanel.content, this),
                  new MemoryModel(mainPanel.content, this)];
        mainPanel.content.addChild(tabLine = new Shape());
        tabLine.graphics.lineStyle(1, Style.PANEL);
        tabLine.graphics.moveTo(0,0);
        tabLine.graphics.lineTo(40,0);
        tabLine.y = 116;
        _alphaBar = new VColorBar(mainPanel.content, 168, 8, 12, 100, _onAlphaChanged);
        _alphaMap = new BitmapData(12, 100, true);
        _alphaTile = new AlphaTile(12, 100);
        _alphaValue = new InputText(mainPanel.content, 162, 116, "100", _onAlphaEdit);
        _alphaValue.restrict = "0123456789";
        _alphaValue.setSize(28, 18);
        selectedTab = 0;
        return uniqueDefaultModel;
        function newTab(label:String) : PushButton {
            var newButton:PushButton = new PushButton(mainPanel.content, x_, 116, label, _onTabClick);
            newButton.setSize(40, 18);
            x_ += 40;
            return newButton;
        }
    }

    protected function _onTabClick(e:Event) : void { selectedTab = int((e.target.x + 20) / 40); }
}

class ColorChooserExModel extends Sprite {
    protected static const $$:Number = 0.00392156862745098;
    protected var _h:Number, _s:Number, _v:Number, _r:uint, _g:uint, _b:uint, _a:uint;
    protected var _chooser:ColorChooserEx;
    
    public function get value() : uint { return (_a<<24)|(_r<<16)|(_g<<8)|_b; }
    public function set value(v:uint) : void {
        _a = (v >> 24) & 0xff;
        _r = (v >> 16) & 0xff;
        _g = (v >> 8) & 0xff;
        _b = v & 0xff;
        _RGBupdated();
        _setup();
    }
    
    function ColorChooserExModel(parent:DisplayObjectContainer, chooser:ColorChooserEx) {
        super();
        parent.addChild(this);
        visible = false;
        _chooser = chooser;
    }
    
    protected function _setup() : void {}
    
    protected function _HSVupdated() : void {
        var v:uint = hsv2rgb(_h, _s, _v);
        _r = (v >> 16) & 0xff;
        _g = (v >> 8) & 0xff;
        _b = v & 0xff;
    }
    
    protected function _RGBupdated() : void {
        var hsv:uint = rgb2hsv(_r, _g, _b);
        _h = (hsv >> 18) * 0.000244140625;
        _s = ((hsv >> 8) & 0x3ff) * 0.0009775171065493646;
        _v = (hsv & 0xff) * 0.00392156862745098;
    }
}

class ControlPad extends Panel {
    public var backBitmap:Bitmap, pixels:BitmapData;
    protected var _pointer:Shape, _pointerRange:Rectangle;
    
    public function get valueX() : Number { return _pointer.x / _pointerRange.width; }
    public function set valueX(p:Number) : void { _pointer.x = _pointerRange.width * p; }
    public function get valueY() : Number { return 1 - _pointer.y / _pointerRange.height; }
    public function set valueY(p:Number) : void { _pointer.y =  _pointerRange.height * (1-p); }
    public function valueXY(px:Number, py:Number) : void { 
        _pointer.x = _pointerRange.width * px;
        _pointer.y = _pointerRange.height * (1-py);
    }
    
    function ControlPad(parent:DisplayObjectContainer, xpos:Number, ypos:Number, width:Number, height:Number, defaultHandler:Function=null) {
        super(parent, xpos, ypos);
        setSize(width, height);
        backBitmap = new Bitmap(pixels = new BitmapData(width, height, false, 0x808080));
        _pointer = _addPointer();
        _pointerRange = pixels.rect;
        _background.addChild(backBitmap);
        addEventListener(MouseEvent.MOUSE_DOWN, _onDragStart);
        if (defaultHandler != null) addEventListener(Event.CHANGE, defaultHandler);
        buttonMode = true;
    }
    
    override public function draw() : void {
        dispatchEvent(new Event(Component.DRAW));
        _mask.graphics.clear();
        _mask.graphics.beginFill(0xff0000);
        _mask.graphics.drawRect(0, 0, _width, _height);
        _mask.graphics.endFill();
    }

    protected function _addPointer() : Shape {
        var pt:Shape = new Shape();
        pt.graphics.lineStyle(2, 0, 0.5);
        pt.graphics.beginFill(0xffffff, 1);
        pt.graphics.drawCircle(0, 0, 3);
        pt.graphics.endFill();
        content.addChild(pt);
        return pt;
    }
    
    protected function _onDragStart(e:MouseEvent) : void {
        stage.addEventListener(MouseEvent.MOUSE_MOVE, _onDragging);
        stage.addEventListener(MouseEvent.MOUSE_UP, _onDragEnd);
        _onDragging(e);
    }
    
    protected function _onDragging(e:MouseEvent) : void {
        _pointer.x = mouseX;
        _pointer.y = mouseY;
             if (_pointer.x < _pointerRange.left)   _pointer.x = _pointerRange.left;
        else if (_pointer.x > _pointerRange.right)  _pointer.x = _pointerRange.right;
             if (_pointer.y < _pointerRange.top)    _pointer.y = _pointerRange.top;
        else if (_pointer.y > _pointerRange.bottom) _pointer.y = _pointerRange.bottom;
        dispatchEvent(new Event(Event.CHANGE));
    }
    
    protected function _onDragEnd(e:MouseEvent) : void {
        _onDragging(e);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, _onDragging);
        stage.removeEventListener(MouseEvent.MOUSE_UP, _onDragEnd);
    }
}

class HueCircle extends ControlPad {
    protected var circleWidth:Number, circleRadius:Number, triangleSize:Number;
    protected var dragFunc:Function, _hpointer:Shape, _shadowx2:DropShadowFilter;
    protected var hCircle:BitmapData, svTriangle:BitmapData;
    protected var _h:Number=0, _s:Number=0, _v:Number=0;
    protected var svTriangleDrawMatrix:Matrix = new Matrix(0.5, 0, 0, 0.5);
    protected var baseMatrix:Matrix = new Matrix(0.8660254037844386, 0, 0.4330127018922193, 0.75, -0.4330127018922193, -0.25);
    protected var matrix:Matrix, invert:Matrix;
    
    public function get sat() : Number { return _s; }
    public function get val() : Number { return _v; }
    public function get hue() : Number { return _h; }
    public function setHSV(h:Number, s:Number, v:Number) : void {
        _h = h; _s = s; _v = v;
        _drawSVTriangle();
        invalidate();
    }
    
    function HueCircle(parent:DisplayObjectContainer, xpos:Number, ypos:Number, radius:Number, cwidth:Number, defaultHandler:Function=null) {
        super(parent, xpos, ypos, radius*2, radius*2, defaultHandler);
        filters = null;
        circleWidth  = cwidth;
        circleRadius = radius;
        triangleSize = (radius - cwidth) * 2;
        hCircle    = new BitmapData(radius*2, radius*2, true, 0);
        svTriangle = new BitmapData(triangleSize*2, triangleSize*2, true, 0);
        svTriangleDrawMatrix.translate(cwidth, cwidth);
        baseMatrix.scale(triangleSize, triangleSize);
        _shadowx2 = getShadow(4, true);
        _drawHCircle();
        _drawSVTriangle();
        _hpointer = _addPointer();
    }
    
    override public function draw() : void {
        super.draw();
        _updateHPointerPosition();
        _updateSVPointerPosition();
        pixels.copyPixels(hCircle, hCircle.rect, hCircle.rect.topLeft);
        pixels.draw(svTriangle, svTriangleDrawMatrix, null, null, null, true);
    }
    
    protected function _drawHCircle() : void {
        var px:int, py:int, rgb:uint, d:Number, pmax:int = circleRadius * 2, 
            r2:Number = pmax * pmax, w2:Number = triangleSize * triangleSize, 
            temp:BitmapData = new BitmapData(hCircle.width*2, hCircle.height*2, true, 0);
        for (py=-pmax; py<pmax; py++) for (px=-pmax; px<pmax; px++) {
            d = px * px + py * py;
            if (w2<=d && d<=r2) {
                rgb = hsv2rgb(Math.atan2(px, -py)*0.15915494309189534, 1, 1);
                temp.setPixel32(px+pmax, py+pmax, 0xff000000|rgb);
            }
        }
        temp.applyFilter(temp, temp.rect, temp.rect.topLeft, _shadowx2);
        hCircle.fillRect(hCircle.rect, 0xff000000|Style.PANEL);
        hCircle.draw(temp, new Matrix(0.5,0,0,0.5), null, null, null, true);
        temp.dispose();
    }
    
    protected function _drawSVTriangle() : void {
        matrix = baseMatrix.clone();
        matrix.rotate((_h+0.5)*6.283185307179586);
        invert = matrix.clone();
        invert.invert();
        svTriangle.fillRect(svTriangle.rect, 0);
        var px:int, py:int, rgb:uint, sx:Number, sy:Number, ss:Number, vv:Number, pmax:int = triangleSize, 
            a:Number = invert.a * 0.5, b:Number = invert.b * 0.5, 
            c:Number = invert.c * 0.5, d:Number = invert.d * 0.5, 
            tx:Number= invert.tx,      ty:Number= invert.ty;
        for (py=-pmax; py<pmax; py++) for (px=-pmax; px<pmax; px++) {
            sx = px * a + py * c + tx;
            sy = px * b + py * d + ty;
            if (sx+sy<=1 && sx>=0 && sy>=0) {
                vv = sx + sy;
                ss = (vv==0) ? 1 : (((sy - sx) / vv + 1) * 0.5);
                svTriangle.setPixel32(px+pmax, py+pmax, hsv2rgb(_h, ss, vv));
            }
        }
        svTriangle.applyFilter(svTriangle, svTriangle.rect, svTriangle.rect.topLeft, _shadowx2);
    }
    
    override protected function _onDragStart(e:MouseEvent) : void {
        var dx:Number = mouseX - circleRadius, dy:Number = mouseY - circleRadius,
            l2:Number = dx*dx + dy*dy, icr:Number = circleRadius - circleWidth;
        dragFunc = (l2 < icr * icr) ? _updateSVValue : _updateHValue;
        _onDragging(e);
        super._onDragStart(e);
    }
    
    protected function _updateHValue(dx:Number, dy:Number) : void {
        var len:Number = Math.sqrt(dx*dx + dy*dy), il:Number;
        if (len != 0) {
            il = (circleRadius - circleWidth * 0.5) / len;
            _h = Math.atan2(dx, -dy)*0.15915494309189534;
            if (_h<0) _h += 1;
            _drawSVTriangle();
            invalidate();
        }
    }
    
    protected function _updateHPointerPosition() : void {
        var radh:Number = (_h + 0.5) * 6.283185307179586;
        _hpointer.x = -Math.sin(radh) * (circleRadius - circleWidth * 0.5) + circleRadius;
        _hpointer.y = Math.cos(radh) * (circleRadius - circleWidth * 0.5) + circleRadius;
    }
    
    protected function _updateSVValue(dx:Number, dy:Number) : void {
        var sx:Number = dx * invert.a + dy * invert.c + invert.tx,
            sy:Number = dx * invert.b + dy * invert.d + invert.ty;
        sx = (sx<0) ? 0 : sx;
        sy = (sy<0) ? 0 : sy;
        if (sx+sy > 1) { 
            var iss:Number = 1/(sx + sy);
            sx *= iss;
            sy *= iss;
        }
        _v = sx + sy;
        _s = (_v==0) ? 1 : (((sy - sx) / _v + 1) * 0.5);
        _updateSVPointerPosition();
    }
    
    protected function _updateSVPointerPosition() : void {
        var sy:Number = _v * _s, sx:Number = _v - sy;
        _pointer.x = sx * matrix.a + sy * matrix.c + matrix.tx + circleRadius;
        _pointer.y = sx * matrix.b + sy * matrix.d + matrix.ty + circleRadius;
    }
    
    override protected function _onDragging(e:MouseEvent) : void {
        dragFunc(mouseX - circleRadius, mouseY - circleRadius);
        dispatchEvent(new Event(Event.CHANGE));
    }
}

class HColorBar extends ControlPad {
    function HColorBar(parent:DisplayObjectContainer, xpos:Number, ypos:Number, width:Number, height:Number, defaultHandler:Function=null) {
        super(parent, xpos, ypos, width, height, defaultHandler);
        _pointerRange = new Rectangle(0, height*0.5, width, 0);
        _pointer.y = _pointerRange.y;
    }
}

class VColorBar extends ControlPad {
    function VColorBar(parent:DisplayObjectContainer, xpos:Number, ypos:Number, width:Number, height:Number, defaultHandler:Function=null) {
        super(parent, xpos, ypos, width, height, defaultHandler);
        _pointerRange = new Rectangle(width*0.5, 0, 0, height);
        _pointer.x = _pointerRange.x;
    }
}

class AlphaTile extends Shape {
    public var tile:BitmapData = new BitmapData(16, 16, false);
    function AlphaTile(width:int=16, height:int=16, color0:uint=0xffffffff, color1:uint=0xffc0c0c0) {
        super();
        tile.fillRect(new Rectangle(0,0,8,8), color0);
        tile.fillRect(new Rectangle(0,8,8,8), color1);
        tile.fillRect(new Rectangle(8,0,8,8), color1);
        tile.fillRect(new Rectangle(8,8,8,8), color0);
        graphics.beginBitmapFill(tile, new Matrix(1,0,0,1,-((width&7)>>1),-((height&7)>>1)), true, false);
        graphics.drawRect(0, 0, width, height);
        graphics.endFill();
    }
}

class GimpModel extends ColorChooserExModel {
    private var ctrl:ControlPad, bar:VColorBar, tabs:Array, cursor:Shape, _selectedTab:int;
    
    public function get selectedTab() : int { return _selectedTab; }
    public function set selectedTab(idx:int) : void {
        _selectedTab = idx;
        cursor.y = _selectedTab * 18 + 4;
        _setup();
    }
    
    function GimpModel(parent:DisplayObjectContainer, chooser:ColorChooserEx) {
        var y_:Number = 4, me:Sprite = this;
        super(parent, chooser);
        ctrl = new ControlPad(me, 8, 8, 100, 100, _onCtrlChange);
        bar = new VColorBar(me, 112, 8, 12, 100, _onBarChange);
        tabs = [newTab("H"), newTab("S"), newTab("V"), newTab("R"), newTab("G"), newTab("B")];
        addChild(cursor = new Shape());
        cursor.graphics.beginFill(0x8080ff, 0.25);
        cursor.graphics.drawRect(0,0,26,18);
        cursor.graphics.endFill();
        cursor.x = 130;
        selectedTab = 0;
        function newTab(label:String) : PushButton {
            var newButton:PushButton = new PushButton(me, 130, y_, label, _onTabClick);
            newButton.setSize(26, 18);
            y_ += 18;
            return newButton;
        }
    }

    override protected function _setup() : void {
        _updateColors();
        _updatePointer();
    }
    
    protected function _onTabClick(e:Event) : void {
        selectedTab = int((e.target.y + 10) / 20);
    }
    
    protected function _onCtrlChange(e:Event) : void {
        switch (_selectedTab) {
        case 0:  _s=ctrl.valueX; _v=ctrl.valueY; _HSVupdated(); break;
        case 1:  _v=ctrl.valueX; _h=ctrl.valueY; _HSVupdated(); break;
        case 2:  _h=ctrl.valueX; _s=ctrl.valueY; _HSVupdated(); break;
        case 3:  _b=ctrl.valueX*255; _g=ctrl.valueY*255; _RGBupdated(); break;
        case 4:  _r=ctrl.valueX*255; _b=ctrl.valueY*255; _RGBupdated(); break;
        default: _g=ctrl.valueX*255; _r=ctrl.valueY*255; _RGBupdated(); break;
        }
        _updateColors(true, false);
        _chooser.browseColorChoiceEx(value);
    }
    
    protected function _onBarChange(e:Event) : void {
        switch (_selectedTab) {
        case 0:  _h=bar.valueY; _HSVupdated(); break;
        case 1:  _s=bar.valueY; _HSVupdated(); break;
        case 2:  _v=bar.valueY; _HSVupdated(); break;
        case 3:  _r=bar.valueY*255; _RGBupdated(); break;
        case 4:  _g=bar.valueY*255; _RGBupdated(); break;
        default: _b=bar.valueY*255; _RGBupdated(); break;
        }
        _updateColors(false, true);
        _chooser.browseColorChoiceEx(value);
    }
    
    protected function _updateColors(b:Boolean=true, c:Boolean=true) : void {
        var rc:Rectangle = new Rectangle(0,0,12,1), i:int;
        if (_selectedTab<3) {
            switch (_selectedTab) {
            case 0: _drawHSV(b,c); break;
            case 1: _drawSVH(b,c); break;
            case 2: _drawVHS(b,c); break;
            }
        } else _drawRGB(5-_selectedTab,b,c);
        for (rc.y=99, i=0; i<100; rc.y--, i++) bar.pixels.fillRect(rc, _bar[i]);
        ctrl.pixels.fillRect(ctrl.pixels.rect, 0);
        ctrl.pixels.setVector(ctrl.pixels.rect, _mtx);
    }
    
    protected function _updatePointer() : void {
        switch (_selectedTab) {
        case 0:  bar.valueY=_h; ctrl.valueX=_s; ctrl.valueY=_v; break;
        case 1:  bar.valueY=_s; ctrl.valueX=_v; ctrl.valueY=_h; break;
        case 2:  bar.valueY=_v; ctrl.valueX=_h; ctrl.valueY=_s; break;
        case 3:  bar.valueY=_r*$$; ctrl.valueX=_b*$$; ctrl.valueY=_g*$$; break;
        case 4:  bar.valueY=_g*$$; ctrl.valueX=_r*$$; ctrl.valueY=_b*$$; break;
        default: bar.valueY=_b*$$; ctrl.valueX=_g*$$; ctrl.valueY=_r*$$; break;
        }
    }
    
    private var _bar:Vector.<uint> = new Vector.<uint>(100);
    private var _mtx:Vector.<uint> = new Vector.<uint>(10000);
    private function _drawHSV(b:Boolean, c:Boolean) : void {
        var h:Number=_h, s:Number=_s, v:Number=_v, i:int;
        if (b) for (i=0; i<100; i++) _bar[i] = hsv2rgb(i*0.01, 1, 1);
        if (c) for (i=0, v=99; v>=0; v--) for (s=0; s<100; s++, i++) _mtx[i] = hsv2rgb(h, s*0.01, v*0.01);
    }
    private function _drawSVH(b:Boolean, c:Boolean) : void {
        var h:Number=_h, s:Number=_s, v:Number=_v, i:int;
        if (b) for (i=0; i<100; i++) _bar[i] = hsv2rgb(h, i*0.01, i*0.005+0.5);
        if (c) for (i=0, h=99; h>=0; h--) for (v=0; v<100; v++, i++) _mtx[i] = hsv2rgb(h*0.01, s, v*0.01);
    }
    private function _drawVHS(b:Boolean, c:Boolean) : void {
        var h:Number=_h, s:Number=_s, v:Number=_v, i:int;
        if (b) for (i=0; i<100; i++) _bar[i] = hsv2rgb(h, 1, i*0.01);
        if (c) for (i=0, s=99; s>=0; s--) for (h=0; h<100; h++, i++) _mtx[i] = hsv2rgb(h*0.01, s*0.01, v);
    }
    private function _drawRGB(rgbIndex:int, b:Boolean, c:Boolean) : void {
        var shift:int = rgbIndex*8, shiftx:int = [8,16,0][rgbIndex], shifty:int = [16,0,8][rgbIndex],
            rgb:uint = value, col:int = 0xff000000|rgb&~(0xff<<shift), i:int, x:int, y:int;
        if (b) for (i=0; i<100; i++) _bar[i] = 0xff000000 | (int(i*2.55)<<shift);
        if (c) {
            col = 0xff000000|rgb&~((0xff<<shiftx)|(0xff<<shifty));
            for (i=0, y=99; y>=0; y--) for (x=0; x<100; x++, i++) _mtx[i] = col | (int(x*2.55)<<shiftx)|(int(y*2.55)<<shifty);
        }
    }
}

class ColorChooser6Numbers extends ColorChooserExModel {
    protected var numbers:Array = [], _labelx:Number, _numbery:Number = 5;
    
    function ColorChooser6Numbers(parent:DisplayObjectContainer, chooser:ColorChooserEx) { super(parent, chooser); }
    
    protected function _createNumbers(labelx:Number) : void {
        _labelx = labelx;
        _newNumber("H", _onHSVChange, _onHSVTextChange);
        _newNumber("S", _onHSVChange, _onHSVTextChange);
        _newNumber("V", _onHSVChange, _onHSVTextChange);
        _newNumber("R", _onRGBChange, _onRGBTextChange);
        _newNumber("G", _onRGBChange, _onRGBTextChange);
        _newNumber("B", _onRGBChange, _onRGBTextChange);
    }
    
    protected function _newNumber(label:String, onChange:Function, onEdit:Function) : void {
        var input:InputText = new InputText(this, 128, _numbery, "0", onEdit);
        input.setSize(28, 18);
        input.restrict = "0-9";
        numbers.push(input);
        new Label(this, _labelx, _numbery, label);
        _numbery += 18;
    }
    
    protected function _onHSVChange(e:Event) : void {}
    protected function _onHSVTextChange(e:Event) : void {
        _h = Number(numbers[0].text) * 0.002777777777777778;
        _s = Number(numbers[1].text) * 0.01;
        _v = Number(numbers[2].text) * 0.01;
        if (_h<0) _h=0 else if (_h>1) _h=1;
        if (_s<0) _s=0 else if (_s>1) _s=1;
        if (_v<0) _v=0 else if (_v>1) _v=1;
        _updateColors();
        _updatePointer();
        _chooser.browseColorChoiceEx(value);
    }
    
    protected function _onRGBChange(e:Event) : void {}
    protected function _onRGBTextChange(e:Event) : void {
        _r = int(numbers[3].text);
        _g = int(numbers[4].text);
        _b = int(numbers[5].text);
        if (_r<0) _r=0 else if (_r>255) _r=255;
        if (_g<0) _g=0 else if (_g>255) _g=255;
        if (_b<0) _b=0 else if (_b>255) _b=255;
        _updateColors();
        _updatePointer();
        _chooser.browseColorChoiceEx(value);
    }
    
    protected function _updateColors() : void {}
    protected function _updatePointer() : void {}
    protected function _updateNumbers() : void {
        numbers[0].text = String(int(_h*360));
        numbers[1].text = String(int(_s*100));
        numbers[2].text = String(int(_v*100));
        numbers[3].text = String(_r);
        numbers[4].text = String(_g);
        numbers[5].text = String(_b);
    }
}

class BarsModel extends ColorChooser6Numbers {
    protected var bars:Array = [];
    
    function BarsModel(parent:DisplayObjectContainer, chooser:ColorChooserEx) {
        super(parent, chooser);
        _createNumbers(4);
    }

    override protected function _newNumber(label:String, onChange:Function, onEdit:Function) : void {
        bars.push(new HColorBar(this, 20, _numbery+4, 100, 10, onChange));
        return super._newNumber(label, onChange, onEdit);
    }
    
    override protected function _setup() : void {
        _updateColors();
        _updatePointer();
        _updateNumbers();
    }
    
    override protected function _onHSVChange(e:Event) : void {
        _h = bars[0].valueX;
        _s = bars[1].valueX;
        _v = bars[2].valueX;
        _HSVupdated();
        bars[3].valueX = _r * $$;
        bars[4].valueX = _g * $$;
        bars[5].valueX = _b * $$;
        _updateColors();
        _updateNumbers();
        _chooser.browseColorChoiceEx(value);
    }
    
    override protected function _onRGBChange(e:Event) : void {
        _r = bars[3].valueX * 255;
        _g = bars[4].valueX * 255;
        _b = bars[5].valueX * 255;
        _RGBupdated();
        bars[0].valueX = _h;
        bars[1].valueX = _s;
        bars[2].valueX = _v;
        _updateColors();
        _updateNumbers();
        _chooser.browseColorChoiceEx(value);
    }
    
    override protected function _updateColors() : void {
        var h:Number=_h, s:Number=_s, v:Number=_v, rgb:uint = value, i:int, rc:Rectangle = new Rectangle(0,0,1,10);
        for (rc.x=0, i=0; i<100; rc.x++, i++) {
            bars[0].pixels.fillRect(rc, hsv2rgb(i*0.01, s, v));
            bars[1].pixels.fillRect(rc, hsv2rgb(h, i*0.01, v));
            bars[2].pixels.fillRect(rc, hsv2rgb(h, s, i*0.01));
            bars[3].pixels.fillRect(rc, (rgb&0x00ffff)|((i*2.55)<<16));
            bars[4].pixels.fillRect(rc, (rgb&0xff00ff)|((i*2.55)<<8));
            bars[5].pixels.fillRect(rc, (rgb&0xffff00)|((i*2.55)<<0));
        }
    }
    
    override protected function _updatePointer() : void {
        bars[0].valueX = _h;
        bars[1].valueX = _s;
        bars[2].valueX = _v;
        bars[3].valueX = _r * $$;
        bars[4].valueX = _g * $$;
        bars[5].valueX = _b * $$;
    }
}

class HueModel extends ColorChooser6Numbers {
    protected var circle:HueCircle;
    
    function HueModel(parent:DisplayObjectContainer, chooser:ColorChooserEx) {
        super(parent, chooser);
        _createNumbers(114);
        circle = new HueCircle(this, 8, 8, 50, 12, _onHueCircleChanged);
    }
    
    protected function _onHueCircleChanged(e:Event) : void {
        _h = circle.hue;
        _s = circle.sat;
        _v = circle.val;
        _HSVupdated();
        _updateNumbers();
        _chooser.browseColorChoiceEx(value);
    }
    
    override protected function _setup() : void { circle.setHSV(_h, _s, _v); _updateNumbers(); }
    override protected function _updateColors() : void { circle.setHSV(_h, _s, _v); }
}

class MemoryModel extends ColorChooserExModel {
    protected var colors:Vector.<uint> = new Vector.<uint>(16);
    protected var pallet:Sprite = new Sprite();
    
    function MemoryModel(parent:DisplayObjectContainer, chooser:ColorChooserEx) {
        super(parent, chooser);
        addChild(pallet);
        pallet.filters = [new DropShadowFilter(2, 45, Style.DROPSHADOW, 1, 2, 2, .3, 1, true)];
        pallet.buttonMode = true;
        pallet.addEventListener(MouseEvent.CLICK, _onColorSelected);
    }
    
    override protected function _setup() : void {
        memory(value);
        _updateColors();
    }
    
    protected function _updateColors() : void { 
        var i:int, g:Graphics = pallet.graphics;
        g.clear();
        for (i=0; i<16; i++) {
            g.beginFill(colors[i]);
            g.drawRect((i&7)*19+5, (i>>3)*19+5, 16, 16);
            g.endFill();
        }
    }
    
    protected function _onColorSelected(e:Event) : void {
        var idx:int = (int((mouseX - 3) / 19) & 7) + (int((mouseY - 3) / 19) << 3);
        if (idx>=0 && idx<16) {
            memory(value);
            _chooser.browseColorChoiceEx(colors[idx]);
        }
    }
    
    public function memory(color:uint) : void {
        var i:int, j:int=15;
        for (i=0; i<16; i++) if (colors[i] == color) { j = i; break; }
        for (; j>0; j--) colors[j] = colors[j-1];
        colors[0] = color;
        _updateColors();
    }
}
