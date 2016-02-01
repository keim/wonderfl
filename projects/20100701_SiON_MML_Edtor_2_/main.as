// SiON MML Editor
// [USAGE] 
//   Write MML in the text field and Shift+Enter to play.
//   All MMLs in all pages are concatenated and play.
//   Ctrl+Z to undo, Ctrl+Y to redo (codes from psyark's Psycode)
//------------------------------------------------------------
package {
    import flash.display.*;
    import flash.events.*;
    import flash.ui.Keyboard;
    
    [SWF(backgroundColor="#ffffff", frameRate="20")]
    public class main extends Sprite {
        function main() {
            stage.scaleMode = "noScale";
            stage.align = "TL";
            stage.stageFocusRect = false;
            addEventListener("addedToStage", _onAddedToStage);
            stage.addEventListener("resize", _onResize);
            stage.addEventListener("keyDown", _onKeyDown);
            driver.addEventListener("error", _onError);
            control = new ControlPanel(this);
            mmlEditor = new MMLEditor(this, 0, 0, _onTextChange);
            pageSelector = new PageSelector(this);
            message = new MessageBox(this);
            searchWindow = new SearchWindow(this);
        }
        
        private function _onAddedToStage(event:Event) : void {
            _updateSize();
            loadCookie();
        }
        
        private function _onResize(event:Event) : void {
            _updateSize();
        }
        
        private function _onKeyDown(event:KeyboardEvent) : void {
            switch (event.keyCode) {
            case Keyboard.ENTER:
                if (event.shiftKey) togglePlay();
                break;
            }
        }

        private function _onTextChange(length:int) : void {
            textLength = length;
            control.updateTrackLabel(false);
        }
        
        private function _onError(e:ErrorEvent) : void {
            message.show(e.text);
        }
        
        private function _updateSize() : void {
            control.setSize(stage.stageWidth, 24);
            mmlEditor.y = 24;
            mmlEditor.setSize(stage.stageWidth, stage.stageHeight - 48);
            pageSelector.y = stage.stageHeight - 24;
            pageSelector.setSize(stage.stageWidth, 24);
        }
    }
}


import flash.display.*;
import flash.geom.Rectangle;
import flash.text.*;
import flash.events.*;
import flash.ui.Keyboard;
import flash.net.*;
import com.bit101.components.*;
import org.si.sion.*;
import org.si.sion.events.*;
import org.si.sion.utils.Translator;


// Global variables
//--------------------------------------------------
var cookieName:String = "savedData";
var driver:SiONDriver = new SiONDriver();
var message:MessageBox;
var mmlEditor:MMLEditor;
var control:ControlPanel;
var pageSelector:PageSelector;
var searchWindow:SearchWindow;
var pageIndex:int = 0;
var soloIndex:int = -1;
var textLength:int = 0;


// Global functions
//--------------------------------------------------
function loadCookie() : void {
    var so:SharedObject = SharedObject.getLocal(cookieName);
    mmlEditor.xml = so.data.mmlxml;
}

function saveCookie() : void {
    var so:SharedObject = SharedObject.getLocal(cookieName);
    so.data.mmlxml = mmlEditor.xml;
    so.flush();
}

function togglePlay() : void {
    if (driver.isPlaying) {
        driver.stop();
        control.cbPlay(false);
    } else {
        saveCookie();
        driver.position = control.position * 1000;
        driver.play(mmlEditor.mml);
        control.cbPlay(true);
    }
}

function selectPage(index:int) : void {
    if (pageIndex != index) {
        control.cbPageChanged(index);
        mmlEditor.cbPageChanged(index);
        pageSelector.cbPageChanged(index);
        pageIndex = index;
    }
}

function setMute(index:int, bool:Boolean) : void {
    mmlEditor.cbMuteChanged(index, bool);
    pageSelector.cbMuteChanged(index, bool);
    control.cbPageChanged(pageIndex);
    soloIndex = -1;
}

function setSolo(index:int, bool:Boolean) : void {
    var i:int, mute:Boolean, imax:int = MMLEditor.FIELD_COUNT;
    for (i=0; i<imax; i++) {
        mute = bool && (i != index);
        mmlEditor.cbMuteChanged(i, mute);
        pageSelector.cbMuteChanged(i, mute);
    }
    soloIndex = (bool) ? index : -1;
    control.cbPageChanged(pageIndex);
}


// Message box
//--------------------------------------------------
class MessageBox extends Window {
    private var _text:Text, _button:PushButton;
    function MessageBox(parent:DisplayObjectContainer=null, title:String="Error") {
        super(parent, 100, 100, title);
        setSize(200, 160);
        _text   = new Text(content, 0, 0, "");
        _text.setSize(200, 120);
        _button = new PushButton(content, 76, 122, "OK", function(e:Event):void{visible = false;});
        _button.setSize(48,16);
        visible = false;
    }
    
    public function show(message:String="") : void {
        _text.text = message;
        visible = true;
    }
}


// Menu window
//--------------------------------------------------
class MenuPopup extends Panel {
    function MenuPopup(parent:DisplayObjectContainer=null) {
        super(parent, 263, 0);
        var y:int = 4;
        
        newButton("clear", clear);
        newButton("load", load);
        newButton("save as xml", saveXML);
        newButton("save as mml", saveMML);
        newButton("translate from TSSCP MML", transTSSCP);
        newButton("show search window", showSearch);
        setSize(200, y+2);
        this.y = -y-4;
        visible = false;
        
        function newButton(label:String, func:Function) : PushButton {
            var newButton:PushButton = new PushButton(content, 4, y, label, func);
            newButton.setSize(193, 16);
            y += 18;
            return newButton;
        }
    }
    
    public function clear(e:Event) : void {
        mmlEditor.mml = "";
        visible = false;
    }
    
    public function load(e:Event) : void {
        var fr:FileReference = new FileReference();
        fr.addEventListener("select", function(e:Event) : void { fr.load(); });
        fr.addEventListener("complete", _onLoaded);
        fr.browse();
        visible = false;
    }
    
    private function _onLoaded(e:Event) : void {
        var text:String = String(e.target.data);
        if (/^<MMLList/.test(text)) mmlEditor.xml = new XML(text);
        else mmlEditor.mml = text;
    }
    
    public function saveXML(e:Event) : void {
        new FileReference().save(mmlEditor.xml, "sionmml.xml");
        visible = false;
    }
    
    public function saveMML(e:Event) : void {
        new FileReference().save(mmlEditor.mml, "sionmml.txt");
        visible = false;
    }
    
    public function transTSSCP(e:Event) : void {
        mmlEditor.mml = Translator.tsscp(mmlEditor.mml, false);
        visible = false;
    }
    
    public function showSearch(e:Event) : void {
        searchWindow.visible = true;
        visible = false;
    }
}


// Search window
//--------------------------------------------------
class SearchWindow extends Window {
    public var input:InputText, execute:PushButton, regexp:CheckBox;
    function SearchWindow(parent:DisplayObjectContainer=null) {
        super(parent, 160, 160, "Search Window");
        input = new InputText(content, 4, 4, "");
        input.setSize(192, 16);
        execute = new PushButton(content, 148, 24, "sreach", _onSearch);
        execute.setSize(48, 16);
        regexp = new CheckBox(content, 30, 26, "use regular expression");
        new PushButton(this, 182, 3, "X", _onClose).setSize(15, 15);
        setSize(200, 60);
        visible = false;
    }
    
    private function _onClose(e:Event) : void {
        visible = false;
    }
    
    private function _onSearch(e:Event) : void {
        mmlEditor.colorSearchResult(input.text, regexp.selected);
    }
}


// Control panel
//--------------------------------------------------
class ControlPanel extends Panel {
    public var playButton:PushButton;
    public var posLabel:Label, posInput:InputText;
    public var muteCheck:CheckBox, soloCheck:CheckBox;
    public var loadLabel:Label, trackLabel:Label;
    
    function ControlPanel(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0) {
        super(parent, xpos, ypos);
        playButton = new PushButton(content, 2, 5, "play", function(e:Event):void { togglePlay(); });
        playButton.setSize(40, 16);
        posLabel = new Label(content, 50, 2, "position");
        posInput = new InputText(content, 90, 5, "0");
        trackLabel = new Label(content, 250, 2, "");
        loadLabel = new Label(content, 300, 2, "");
        posInput.setSize(40, 16);
        muteCheck = new CheckBox(content, 150, 8, "mute", _onMuteClick);
        soloCheck = new CheckBox(content, 200, 8, "solo", _onSoloClick);
        driver.addEventListener(SiONEvent.STREAM, _onStream);
    }
    
    public function get position() : int {
        return int(posInput.text);
    }

    public function updateTrackLabel(isPlaying:Boolean) : void {
        if (isPlaying) trackLabel.text = "track:" + String(driver.trackCount);
        else trackLabel.text = "letters:" + String(textLength);
    }
    public function cbPlay(bool:Boolean) : void {
        playButton.label = (bool) ? "stop" : "play";
        loadLabel.visible = bool;
        updateTrackLabel(bool);
    }
    public function cbPageChanged(index:int) : void {
        muteCheck.selected = mmlEditor.getMute(index);
        soloCheck.selected = (index == soloIndex);
    }
    private function _onStream(e:SiONEvent) : void { loadLabel.text = "load:" + String(driver.processTime) + "[ms]"; }
    private function _onMuteClick(e:Event) : void { setMute(pageIndex, muteCheck.selected); }
    private function _onSoloClick(e:Event) : void { setSolo(pageIndex, soloCheck.selected); }
}


// Pager
//--------------------------------------------------
class PageSelector extends Panel {
    public var pageSelector:Vector.<PushButton> = new Vector.<PushButton>(MMLEditor.FIELD_COUNT);
    public var pageMute:Vector.<Shape> = new Vector.<Shape>(MMLEditor.FIELD_COUNT);
    public var mergedButton:PushButton, menuButton:PushButton, menuPopup:MenuPopup;
    
    function PageSelector(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0) {
        super(parent, xpos, ypos);
        for (var i:int=0; i<MMLEditor.FIELD_COUNT; i++) {
            pageSelector[i] = new PushButton(content, i*50+64, 5, "page"+String(i+1), _onPageSelected);
            pageSelector[i].toggle = true;
            pageSelector[i].setSize(48, 16);
            pageSelector[i].addChild(pageMute[i] = new Shape());
            pageSelector[i].doubleClickEnabled = true;
            pageSelector[i].addEventListener("doubleClick", _onDoubleClick);
            pageMute[i].graphics.beginFill(0x000000, 0.25);
            pageMute[i].graphics.drawRect(0, 0, 48, 16);
            pageMute[i].graphics.endFill();
            pageMute[i].visible = false;
        }
        pageSelector[0].selected = true;
        mergedButton = new PushButton(content, 2, 5, "merged", _onMergedSelected);
        mergedButton.setSize(48, 16);
        menuButton = new PushButton(content, 415, 5, "menu", _onMenu);
        menuButton.setSize(48, 16);
        menuPopup = new MenuPopup(this);
    }

    public function cbPageChanged(index:int) : void {
        for (var i:int=0; i<MMLEditor.FIELD_COUNT; i++) pageSelector[i].selected = (index == i);
    }
    public function cbMuteChanged(index:int, mute:Boolean) : void { 
        if (index < MMLEditor.FIELD_COUNT) pageMute[index].visible = mute;
    }

    private function _onMergedSelected(e:Event) : void {
        mmlEditor.updateMergedMML();
        selectPage(MMLEditor.FIELD_COUNT);
    }
    
    private function _onMenu(e:Event) : void {
        menuPopup.visible = !menuPopup.visible;
    }
    
    private function _onPageSelected(e:Event) : void {
        selectPage(int((e.target.x-39)/50));
    }
    
    private function _onDoubleClick(e:Event) : void {
        var index:int = int((e.target.x-39)/50);
        setMute(index, !mmlEditor.getMute(index));
    }
    
    override public function setSize(w:Number, h:Number) : void {
        super.setSize(w, h);
        if (menuButton) menuButton.x = width - 50;
        if (menuPopup) menuPopup.x = width - 202;
    }
}


// Editor
//--------------------------------------------------
class MMLEditor extends Sprite {
    static public const FIELD_COUNT:int = 5; 
    public var sion140:Boolean = true;
    private var mmlFields:Vector.<MMLField> = new Vector.<MMLField>(FIELD_COUNT+1);
    
    function MMLEditor(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, func:Function=null) {
        if (parent) parent.addChild(this);
        this.x = xpos;
        this.y = ypos;
        
        MMLTextField.defaultFormat.size  = 12;
        MMLTextField.defaultFormat.font  = "MS Gothic, Courier, _typewriter";
        MMLTextField.defaultFormat.color = 0x606060;
        MMLTextField.searchFormat.color = 0xc06060;
        MMLTextField.searchFormat.underline = true;
        for (var i:int=0; i<=FIELD_COUNT; i++) mmlFields[i] = new MMLField(this, (i==FIELD_COUNT), func);
        mmlFields[0].visible = true;
    }
    
    public function cbPageChanged(index:int) : void {
        for (var i:int=0; i<=FIELD_COUNT; i++) mmlFields[i].visible = false;
        mmlFields[index].visible = true;
        mmlFields[index].setFocus();
    }
    public function cbMuteChanged(index:int, mute:Boolean) : void {
        mmlFields[index].mute = mute;
    }
    
    public function getMute(index:int) : Boolean {
        return mmlFields[index].mute;
    }
    
    public function setSize(width:Number, height:Number) : void {
        for (var i:int=0; i<=FIELD_COUNT; i++) mmlFields[i].setSize(width, height);
    }
    
    public function set xml(list:XML) : void {
        if (list) {
            for (var i:int=0; i<FIELD_COUNT; i++) mmlFields[i].text = list.MML[i];
        }
    }
    
    public function get xml() : XML {
        var xml:XML = <MMLList version='1'/>, cont:String;
        for (var i:int=0; i<FIELD_COUNT; i++) {
            cont = "<![CDATA["+ mmlFields[i].text + "]]>";
            xml.appendChild(new XML("<MML field='" + String(i) + "'>" + cont + "</MML>"));
        }
        return xml;
    }
    
    public function set mml(text:String) : void {
        mmlFields[0].text = text;
        for (var i:int=1; i<FIELD_COUNT; i++) mmlFields[i].text = "";
    }
    
    public function get mml() : String {
        var i:int, result:String = "", text:String, rex:RegExp = /;\s*$/;
        for (i=0; i<FIELD_COUNT; i++) {
            text = mmlFields[i].text;
            if (!mmlFields[i].mute && text != "") {
                if (sion140) text = text.replace(/([A-Z]+(=|@?[0-9]*{))/g, "#$1").replace(/#+/g, "#"); //}
                if (rex.test(text)) result += text;
                else result += text + ";\n";
            }
        }
        return result;
    }
    
    public function updateMergedMML() : void {
        mmlFields[FIELD_COUNT].text = mml;
    }
    
    public function colorSearchResult(pattern:String, byRegExp:Boolean=false) : void {
        mmlFields[pageIndex].colorSearchResult(pattern, byRegExp);
    }
}


class MMLField extends Panel {
    private var textField:MMLTextField;
    private var scrollBar:CustomSlider;
    private var funcTextChange:Function;
    
    function MMLField(parent:DisplayObjectContainer, constant:Boolean=false, func:Function=null) {
        super(parent);
        funcTextChange = func;
        scrollBar = new CustomSlider("vertical", content, 0, 0, _onSliderChanged);
        scrollBar.backClick = true;
        textField = new MMLTextField(content, constant);
        textField.addEventListener("change", _onTextChanged);
        textField.addEventListener("scroll", _onTextScroll);
        visible = false;
    }
    
    public function get text() : String { return textField.text; }
    public function set text(mml:String) : void { textField.text = mml || ""; }
    
    public function get mute() : Boolean { return (textField.type == 'dynamic'); }
    public function set mute(bool:Boolean) : void {
        if (textField.constant || bool) {
            textField.type = 'dynamic';
            textField.backgroundColor = 0xc0c0c0;
        } else {
            textField.type = 'input';
            textField.backgroundColor = 0xffffff;
        }
    }
    
    override public function setSize(width:Number, height:Number) : void {
        super.setSize(width, height);
        if (textField) {
            textField.setSize(width - 15, height);
            scrollBar.setSize(15, height);
            scrollBar.x = width - 15;
            scrollBar.setRange(1, textField.maxScrollV, textField.scrollV, textField.numLines - textField.maxScrollV);
        }
    }
    
    public function setFocus() : void {
        stage.focus = textField;
    }
    
    private function _onSliderChanged(e:Event) : void {
        textField.scrollV = scrollBar.value;
    
    }
    
    private function _onTextChanged(e:Event) : void {
        scrollBar.setRange(1, textField.maxScrollV, textField.scrollV, textField.numLines - textField.maxScrollV);
        funcTextChange(textField.text.length);
    }
    
    private function _onTextScroll(e:Event) : void {
        scrollBar.setRange(1, textField.maxScrollV, textField.scrollV, textField.numLines - textField.maxScrollV);
    }
    
    public function colorSearchResult(pattern:String, byRegExp:Boolean=false) : void {
        textField.setTextFormat(MMLTextField.defaultFormat);
        
        var mml:String = textField.text;
        if (pattern != "") {
            if (byRegExp) {
                var res:*, rex:RegExp = new RegExp(pattern, "g");
                while (res = rex.exec(mml)) textField.setTextFormat(MMLTextField.searchFormat, res.index, res.index+res[0].length);
            } else {
                for (var i:int=0; i!=-1;) {
                    i = mml.indexOf(pattern, i);
                    if (i == -1) break;
                    textField.setTextFormat(MMLTextField.searchFormat, i, i+pattern.length);
                    i += pattern.length+1;
                }
            }
        }
    }
}


// Slider with stretching handle
//--------------------------------------------------
class CustomSlider extends Slider {
    protected var _handleLength:Number = 64, _isH:Boolean;
    function CustomSlider(orientation:String = "horizontal", parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0, defaultHandler:Function = null) {
        super(orientation, parent, xpos, ypos, defaultHandler);
        _isH = (_orientation == "horizontal");
    }

    public function setRange(min:Number, max:Number, value:Number, range:Number) : void {
        setSliderParams(min, max, value);
        if (visible = (_min < _max)) {
            _handleLength = range / (range + max - min) * ((_isH) ? _width : _height);
            invalidate();
        }
    }
    
    override protected function drawHandle() : void {   
        _handle.graphics.clear();
        _handle.graphics.beginFill(Style.BUTTON_FACE);
        if (_isH) _handle.graphics.drawRect(1, 1, _handleLength - 2, _height - 2);
        else      _handle.graphics.drawRect(1, 1, _width - 2,  _handleLength - 2);
        _handle.graphics.endFill();
        positionHandle();
    }
    
    override protected function onDrag(event:MouseEvent) : void {
        stage.addEventListener(MouseEvent.MOUSE_UP, onDrop);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onSlide);
        if (_isH) _handle.startDrag(false, new Rectangle(0, 0, width - _handleLength, 0));
        else      _handle.startDrag(false, new Rectangle(0, 0, 0, height - _handleLength));
    }
    
    override protected function positionHandle() : void {
        if (_isH) _handle.x = (_value - _min) / (_max - _min) * (_width  - _handleLength);
        else      _handle.y = (_value - _min) / (_max - _min) * (_height - _handleLength);
    }

    override protected function onBackClick(event:MouseEvent) : void {
        if (_isH) {
            _handle.x = mouseX - _height / 2;
            _handle.x = Math.max(_handle.x, 0);
            _handle.x = Math.min(_handle.x, _width - _handleLength);
            _value = _handle.x / (_width - _handleLength) * (_max - _min) + _min;
        } else {
            _handle.y = mouseY - _width / 2;
            _handle.y = Math.max(_handle.y, 0);
            _handle.y = Math.min(_handle.y, _height - _handleLength);
            _value = _handle.y / (_height - _handleLength) * (_max - _min) + _min;
        }
        dispatchEvent(new Event(Event.CHANGE));
    }
    
    override protected function onSlide(event:MouseEvent) : void {
        var oldValue:Number = _value;
        if (_isH) _value = _handle.x / (_width  - _handleLength) * (_max - _min + 1) + _min;
        else      _value = _handle.y / (_height - _handleLength) * (_max - _min + 1) + _min;
        if (_value != oldValue) dispatchEvent(new Event(Event.CHANGE));
    }
}


// undo and redo are from psyark's Psycode (modified)
//--------------------------------------------------
class MMLTextField extends TextField {
    public var constant:Boolean;
    private var _preventFollowingTextInput:Boolean = false;
    private var _prevText:String = "";
    private var _prevSBI:int;
    private var _prevSEI:int;
    private var _history:Vector.<HistoryItem> = new Vector.<HistoryItem>();
    private var _historyIndex:int;
    private var _ignoreChange:Boolean = false;
    
    static public var defaultFormat:TextFormat = new TextFormat();
    static public var searchFormat:TextFormat = new TextFormat();
    
    function MMLTextField(parent:DisplayObjectContainer, constant:Boolean) {
        this.constant = constant;
        
        selectable = true; 
        alwaysShowSelection = true;
        mouseEnabled = true;
        type = (constant) ? 'dynamic' : 'input';
        multiline = true;
        wordWrap = false;
        background = true;
        backgroundColor = (constant) ? 0xc0c0c0 : 0xffffff;
        defaultTextFormat = defaultFormat;
        
        if (!constant) {
            addEventListener("change", _onChange);
            addEventListener("textInput", _onTextInput);
            addEventListener("keyDown", _onKeyDown);
        }
        
        parent.addChild(this);
        
        clearHistory();
    }
    
    public function setSize(width:Number, height:Number) : void {
        this.width  = width;
        this.height = height;
    }
    
    public function clearHistory() : void {
        _history.length = 0;
        _historyIndex = 0;
        _prevText = text;
    }
    
    private function _onChange(event:Event) : void {
        var res:*;
        if (_prevText != text) {
            if (_preventFollowingTextInput) {
                res = StringComparator.compare(_prevText, text);
                replaceText(res.l, length - res.r, _prevText.substring(res.l, _prevText.length - res.r).replace(/\r/g, "\n"));
                setSelection(_prevSBI, _prevSEI);
            } else {
                if (!_ignoreChange) {
                    res = StringComparator.compare(_prevText, text);
                    var item:HistoryItem = new HistoryItem(res.l);
                    item.oldText = _prevText.substring(res.l, _prevText.length - res.r);
                    item.newText = text.substring(res.l, text.length - res.r);
                    _history.length = _historyIndex;
                    _history.push(item);
                    _historyIndex = _history.length;
                }
                _prevText = text;
                _prevSBI = selectionBeginIndex;
                _prevSEI = selectionEndIndex;
            }
        }
    }
        
    private function _onTextInput(event:Event) : void {
        if (_preventFollowingTextInput) event.preventDefault();
    }
        
    private function _onKeyDown(event:KeyboardEvent) : void {
        _preventFollowingTextInput = false;
        switch (event.keyCode) {
        case Keyboard.BACKSPACE:
            break;
        case 89: // Y
            if (event.ctrlKey) doCtrlY();
            break;
        case 90: // Z
            if (event.ctrlKey) doCtrlZ();
            break;
        }

        function doCtrlZ() : void {
            if (_history.length && _historyIndex > 0) {
                var item:HistoryItem = _history[_historyIndex - 1];
                replaceText(item.index, item.index + item.newText.length, item.oldText.replace(/\r/g, "\n"));
                setSelection(item.index + item.oldText.length, item.index + item.oldText.length);
                _historyIndex--;
                _dispatchIgnorableChangeEvent();
            }
            event.preventDefault();
            _preventFollowingTextInput = true;
        }

        function doCtrlY() : void {
            if (_history.length && _historyIndex < _history.length) {
                var item:HistoryItem = _history[_historyIndex];
                replaceText(item.index, item.index + item.oldText.length, item.newText.replace(/\r/g, "\n"));
                setSelection(item.index + item.newText.length, item.index + item.newText.length);
                _historyIndex++;
                _dispatchIgnorableChangeEvent();
            }
            event.preventDefault();
            _preventFollowingTextInput = true;
        }
    }
    
    private function _dispatchIgnorableChangeEvent():void {
        _ignoreChange = true;
        dispatchEvent(new Event("change"));
        _ignoreChange = false; 
    }
}

class HistoryItem {
    public var index:int;
    public var oldText:String;
    public var newText:String;
    
    public function HistoryItem(index:int=0, oldText:String="", newText:String="") {
        this.index   = index;
        this.oldText = oldText;
        this.newText = newText;
    }
}

class StringComparator {
    static public function compare(str1:String, str2:String) : * {
        var minLength:int = Math.min(str1.length, str2.length);
        var step:int, l:int, r:int;
        
        for (step=0x1000000; step>minLength;) step>>=1;
        for (l=0; l<minLength;) {
            if (str1.substr(0, l+step) != str2.substr(0, l+step)) {
                if (step == 1) { break; }
                step >>= 1;
            } else {
                l += step;
            }
        }
        l = Math.min(l, minLength);
        minLength -= l;
        
        for (step=0x1000000; step>minLength;) step>>=1;
        for (r=0; r<minLength;) {
            if (str1.substr(-r - step) != str2.substr(-r - step)) {
                if (step == 1) { break; }
                step >>= 1;
            } else {
                r += step;
            }
        }
        r = Math.min(r, minLength);
        
        return {"l":l, "r":r};
    }
}

