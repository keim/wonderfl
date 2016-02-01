package {
    import flash.display.*;
    
    [SWF(width="465", height="465", backgroundColor="0xffffff", frameRate="30")]
    public class main extends Sprite {
        private var sceneSelect:SceneSelect = new SceneSelect();
        private var sceneGame  :SceneGame   = new SceneGame();
        
        function main() {
            WonderflAPI.apiKey = loaderInfo.parameters.open_api_key;
            sceneSelect.nextScene = sceneGame;
            Layer.initialize(this);
            sceneSelect.enterScene();
        }
    }
}


import com.adobe.serialization.json.JSON;
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.net.*;
import flash.system.*;
import flash.utils.*;
import com.bit101.components.*;
import org.libspark.betweenas3.*;
import org.libspark.betweenas3.tweens.*;
import org.libspark.betweenas3.easing.*;
import frocessing.utils.FLoadUtil;

// Layer
//--------------------------------------------------
class Layer {
    static public var back  :Sprite = new Sprite();
    static public var card  :Sprite = new Sprite();
    static public var window:Sprite = new Sprite();
    static public function initialize(main:Sprite) : void {
        main.addChild(back);
        main.addChild(card);
        main.addChild(window);
        WCard.drawBackImage();
    }
    static public function setCard(c:WCard, x:Number, y:Number, rev:Boolean=false) : WCard { 
        if (c.parent == null) card.addChild(c);
        return c.pos(x, y, rev);
    }
    static public function removeAllWindows() : void {
        while (window.numChildren>0) window.removeChildAt(0);
    }
}

// Scene
//--------------------------------------------------
class SceneSprite extends Sprite {
    public var operator:Panel = new Panel(null, 0, 440);
    public var windows:Vector.<DisplayObject> = null;
    public var nextScene:SceneSprite = null;
    function SceneSprite() {
        operator.setSize(465, 25);
        graphics.beginFill(0xeeeeff);
        graphics.drawRect(0, 0, 465, 465);
        graphics.endFill();
    }
    public function enterScene() : void {
        Layer.back.addChildAt(this, 0);
        Layer.window.addChild(operator);
        if (windows) for each (var d:DisplayObject in windows) Layer.window.addChild(d);
        onEnterScene();
    }
    public function exitScene(time:Number) : void {
        Layer.removeAllWindows();
        var t:ITween = BetweenAS3.serial(
            BetweenAS3.tween(this, {y:440}, {y:0}, time, Bounce.easeOut), 
            BetweenAS3.removeFromParent(this), BetweenAS3.func(onExitScene)
        );
        t.play();
        nextScene.enterScene();
    }
    protected function onEnterScene() : void { }
    protected function onExitScene() : void { }
    protected function button(x:Number, label:String, func:Function, width:Number) : PushButton {
        var b:PushButton = new PushButton(operator.content, x, 4, label, func);
        b.setSize(width, 16);
        return b;
    }
    protected function label(x:Number, label:String, width:Number) : Label {
        var l:Label = new Label(operator.content, x, 4, label)
        l.setSize(width, 16);
        return l;
    }
    protected function window(...wnds) : SceneSprite {
        windows = Vector.<DisplayObject>(wnds);
        return this;
    }
}

class SceneSelect extends SceneSprite {
    private var _selector:FloatingSelector = new FloatingSelector(_onSelected);
    function SceneSelect() { 
        window(_selector);
        label(72, "Input Project Team Members Name.", 240);
        button(4, "Game Start", _onStartGame, 64);
        button(377, "Sample Users", _onSelButton, 80);
        for (var i:int=0; i<4; i++) UserDisplay.displays[i] = new UserDisplay(this, i);
        UserDisplay.displays[0].setFocus();
/*
        for (i=0; i<4; i++) UserDisplay.displays[i].userName = "d";
*/    }
    private function _onSelButton(e:Event) : void { _selector.visible = !_selector.visible; }
    private function _onSelected(name:String) : void { if (UserDisplay.selected) UserDisplay.selected.userName = name; }
    private function _onStartGame(e:Event) : void { if (UserDisplay.startGame()) exitScene(2); }
}

class SceneGame extends SceneSprite {
    private var _message:MessageWindow = new MessageWindow();
    function SceneGame() {
        window(_message);
    }
    override protected function onEnterScene() : void { _message.popup("Loading AI ..."); }
    override protected function onExitScene() : void { }
}


// UI
//--------------------------------------------------
class UserDisplay extends Panel {
    static public var selected:UserDisplay = null;
    static public var displays:Vector.<UserDisplay> = new Vector.<UserDisplay>(4);
    static public function startGame() : Boolean { 
        var i:int;
        for (i=0; i<4; i++) if (!displays[i].userName) return false;
        for (i=0; i<4; i++) displays[i].startGame();
        return true; 
    }
    
    public var user:WUser = null, index:int;
    private var status:Label, message:Label, progBar:ProgressBar, nameInput:InputText, load:PushButton, back:Shape;
    
    public function get userName() : String { return (user && user.userData.isAvailable) ? user.userData.userName : null; }
    public function set userName(name:String) : void { nameInput.text = name; _onSetUser(null); }
    
    function UserDisplay(parent:DisplayObjectContainer, index:int) {
        super(parent, 0, index*110);
        this.index = index;
        setSize(465, 110);
        content.addChild(back = new Shape());
        back.graphics.beginFill(0x8080c0, 0.5);
        back.graphics.drawRect(0, 0, 465, 110);
        back.graphics.endFill();
        back.visible = false;
        status = new Label(content, 8, 72, "");
        message = new Label(content, 112, 52, "loading error !!");
        progBar = new ProgressBar(content, 8, 48);
        nameInput = new InputText(content, 8, 88);
        nameInput.setSize(64, 16);
        load = new PushButton(content, 76, 88, "load", _onSetUser);
        load.setSize(28, 16);
        message.visible = progBar.visible = false;
        addEventListener("focusIn", _onFocusIn);
        addEventListener("keyDown", _onKeyDown);
    }
    
    public function setFocus() : void { _onFocusIn(null); }
    public function startGame() : void {
        WUser.deleteCache(userName);
        for (var i:int = 0; i<user.suit.length; i++) 
            user.suit[i].to(40, 408, true, 0.5, (3-index+i*0.08)*0.5, !(index==0 && i==0));
    }
    
    private function _removeAll() : void {
        if (user) {
            content.removeChild(user.userData.userIcon);
            for each (var c:WCard in user.suit) if (c.parent) c.parent.removeChild(c);
            user = null;
        }
    }
    private function _onFocusIn(e:Event) : void { 
        for each(var d:UserDisplay in displays) d.back.visible = false;
        selected = this;
        back.visible = true;
    }
    private function _onKeyDown(e:KeyboardEvent) : void { if (e.keyCode == 13) _onSetUser(null); }
    private function _onSetUser(e:Event) : void {
        if (progBar.visible) return;
        message.visible = false;
        _removeAll();
        var name:String = nameInput.text;
        for each(var d:UserDisplay in displays) if (d.userName == name) { nameInput.text = ""; return; }
        user = WUser.getCache(name);
        if (user == null) {
            addEventListener("enterFrame", _onLoading);
            progBar.visible = true;
            status.text = "loading...";
            user = new WUser(name, _onFinished);
        } else _onFinished(true);
    }
    private function _onFinished(succ:Boolean) : void {
        removeEventListener("enterFrame", _onLoading);
        message.visible = progBar.visible = false;
        if (succ) {
            with (content.addChild(user.userData.userIcon)) { x=y=8; scaleX=scaleY=0.64; };
            status.text = "Gain:" + String(user.gain);
            for (var i:int = 0; i<user.suit.length; i++) {
                var cx:Number = this.x + (i%6)*55 + 154, cy:Number = this.y + ((i>=6)?82:27);
                Layer.setCard(user.suit[i], this.x + 100, this.y + 55, true).to(cx, cy, false, 0.8, 1-i*0.08);
            }
        } else {
            message.visible = true;
            user = null;
        }
    }
    private function _onLoading(e:Event) : void { progBar.value = user.userData.progress; }
}

class FloatingSelector extends Window {
    public var items:Vector.<PushButton> = new Vector.<PushButton>(12);
    public var slider:VSlider, sliderPos:int, _funcSelected:Function, close:PushButton;
    
    function FloatingSelector(funcSelected:Function) {
        super(null, 329, 16, "Sample Users");
        setSize(120, 212);
        close = new PushButton(this, 104, 4, "x", function(e:Event):void { visible = false; });
        close.setSize(14, 14)
        visible = false;
        for (var i:int = 0; i<12; i++) {
            items[i] = new PushButton(content, 0, i*16, "", _onSelected);
            items[i].setSize(108, 16);
        }
        slider = new VSlider(content, 108, 0, _onSlide);
        slider.setSize(12, 192);
        slider.value = 100;
        slider.backClick = true;
        _onSlide(null);
        _funcSelected = funcSelected;
    }
    
    private function _onSelected(e:Event) : void { _funcSelected(userList[int(e.target.y*0.0625+0.5)+sliderPos]); }
    private function _onSlide(e:Event) : void {
        sliderPos = 87 - int(slider.value * 0.87);
        for (var i:int = 0; i<12; i++) items[i].label = userList[i+sliderPos];
    }
}

class MessageWindow extends Window {
    private var _tf:Text, _by:PushButton, _bn:PushButton;
    function MessageWindow() {
        super(null, 132, 200, "Message Window");
        setSize(200, 80);
        _tf = new Text(content, 0, 0);
        _tf.editable = false;
        _tf.setSize(200, 80);
        (_by = new PushButton(content, 19,62,"YES")).setSize(80, 16);
        (_bn = new PushButton(content,101,62,"NO" )).setSize(80, 16);
        visible = false;
    }
    public function popup(msg:String, funcYes:Function=null, funcNo:Function=null) : void { 
        _tf.text = msg;
        visible = true;
        setSize(200, (funcYes != null) ? 80 : 60);
        _by.visible = (funcYes != null);
        _bn.visible = (funcNo  != null);
        _by.x = (funcNo != null) ? 19 : 60;
    }
}

// Cards
//--------------------------------------------------
class WUser {
    static private var _cache:* = {};
    static public function getCache(name:String) : WUser { return _cache[name]; }
    static public function deleteCache(name:String) : void { delete _cache[name]; }
    public var userData:WonderflUserData = new WonderflUserData();
    public var suit:Vector.<WCard> = new Vector.<WCard>();
    public var gain:int;
    private var _funcFinished:Function;
    
    function WUser(name:String, funcFinished:Function) {
        _funcFinished = funcFinished;
/**/
        if (name == 'd') userData.dummy(_onFinished);
        else userData.load(name, _onFinished);
    }
    
    private function _onFinished(data:WonderflUserData) : void {
        if (data != null) {
            var fav:int = 0;
            suit.length = 0;
            for each (var codeData:WonderflCodeData in userData.codes) {
                suit.push(new WCard(codeData));
                fav += codeData.favoriteCount + codeData.forkedCount;
                if (suit.length == 12) break;
            }
            gain = 30 - (fav >> 6) * 10 + ((fav == 0) ? 10 : 0);
            if (gain < 0) gain = 0;
            _cache[userData.userName] = this;
        }
        _funcFinished(data != null);
    }
}

class WCard extends Sprite {
    static public var libTables:Array = [
        ["tweener", "tweenlite", "tweenmax", "tweensy", "betweenas3", "box2d", "jiglib"], // motion (1)
        ["papervision3d", "sandy3d", "alternativa3d", "five3d"],                          // 3D (2)
        ["sion", "flashmedia"], ["frocessing", "stardust"],                               // media (3), drawing (4)
        ["union", "modestmaps", "googlemaps", "progression", "thread", "funnel"]          // service & framework (5)
    ];
    static public var libColor:Array = [0xc0c0c0, 0x80c080, 0xc08080, 0x8080c0, 0xc0c080, 0x80c0c0];
    static public var backImage:BitmapData = new BitmapData(54, 54, false);
    static public function drawBackImage() : void {
        backImage.fillRect(new Rectangle(0,0,54,54), 0xffffff);
        backImage.fillRect(new Rectangle(6,6,42,42), 0xc04040);
        Style.LABEL_TEXT = 0xffffff;
        var t:Label = new Label(null,0,0,"Wonderfl");
        t.draw();
        backImage.draw(t, new Matrix(1,0,0,1,8,16));
    }
    static public function newBackBitmap() : Bitmap {
        var back:Bitmap = new Bitmap(new BitmapData(54, 54, false));
        back.bitmapData.copyPixels(backImage, backImage.rect, backImage.rect.topLeft);
        return back;
    }
    
    public var codeData:WonderflCodeData;
    public var cost:int, value:int, isShort:Boolean, library:int, uniqueNum:int=0;
    public var iconLayer:BitmapData = new BitmapData(54, 54, true, 0);
    public var front:Sprite = new Sprite(), back:Bitmap;
    
    function WCard(codeData:WonderflCodeData) {
        this.codeData = codeData;
        var i:int, hex:String;
        cost  = int((codeData.favoriteCount+9.5)*0.1) * 10;
        value = codeData.favoriteCount+codeData.forkedCount;
        value = int(Math.sqrt(value)*0.9+0.2) * 10 + ((codeData.lineCount < 500) ? 10 : 0);
        isShort = (codeData.lineCount < 100);
        for (i=0, library=0; i<5; i++) if (codeData.checkLib(libTables[i])) library = i+1;
        if (library != 0 && value >= 20) value -= 10;
        if (cost  >= 100) cost  = 100;
        if (value >= 100) value = 100;
        for each(hex in codeData.id.match(/\w\w/g)) uniqueNum = (uniqueNum + parseInt(hex, 16)) & 255;
        front.graphics.beginFill(libColor[library], 1);
        front.graphics.drawRoundRect(0, 0, 54, 54, 4);
        front.graphics.endFill();
        with (front.addChild(codeData.thumbnail)) { 
            x = y = 4;
            scaleY = scaleX = 46/width; 
        }
        front.addChild(new Bitmap(iconLayer));
        _drawText( 0, -2, String(value) + "/" + String(cost) + ((isShort) ? "/S" : ""));
        if (library != 0) _drawText(40, 38, ["T","3D","M","D","SF"][library-1]);
        
        back = newBackBitmap();
        back.rotationY = 180;
        back.visible = false;
        
        with(addChild(front)){ x=y=-27; }
        with(addChild(back)){ x=-(y=-27); }
        
        buttonMode = true;
        addEventListener("click", function(e:Event): void { 
            navigateToURL(new URLRequest("http://wonderfl.net/code/" + codeData.id));
        });
    }
    
    public function pos(dx:Number, dy:Number, reversed:Boolean=false) : WCard {
        x = dx;
        y = dy;
        rotationY = (reversed) ? 180 : 0;
        return this;
    }
    public function to(x:Number, y:Number, reversed:Boolean=false, time:Number=1, delay:Number=0, andRemove:Boolean=false) : WCard {
        var t:ITween = BetweenAS3.to(this, {"x":x, "y":y, "rotationY":(reversed) ? 180 : 0}, time, Quad.easeInOut);
        t.onUpdate = _onUpdate;
        if (delay > 0) t = BetweenAS3.delay(t, delay);
        if (andRemove) t = BetweenAS3.serial(t, BetweenAS3.removeFromParent(this));
        t.play();
        return this;
    }
    
    private function _onUpdate() : void { front.visible = !(back.visible = (rotationY > 90)); }
    private function _drawText(x:Number, y:Number, text:String) : void {
        Style.LABEL_TEXT = 0xffffffff;
        if (!wtf) wtf = new Label(null, 0, 0, "");
        Style.LABEL_TEXT = 0xff000000;
        if (!btf) btf = new Label(null, 0, 0, "");
        btf.text = wtf.text = text; wtf.draw(); btf.draw(); 
        mat.tx = x;   mat.ty = y-1; iconLayer.draw(wtf, mat);
        mat.tx = x;   mat.ty = y+1; iconLayer.draw(wtf, mat);
        mat.tx = x-1; mat.ty = y;   iconLayer.draw(wtf, mat);
        mat.tx = x+1; mat.ty = y;   iconLayer.draw(wtf, mat);
        mat.tx = x;   mat.ty = y;   iconLayer.draw(btf, mat);
    }
    static private var wtf:Label=null, btf:Label=null, mat:Matrix = new Matrix(1,0,0,1,0,0);
}


// user samples
//--------------------------------------------------
var userList:Array = [ // fav>=50 @ 2009/11/16
"clockmaker","keim_at_Si","Saqoosha","tail_y","alumican_net","miyaoka","nutsu","sake","yd_niku","k3lab",
"Aquioux","makc3d","soundkitchen","k0rin","bkzen","psyark","keno42","nemu90kWw","uwi","shapevent",
"5ivestar","nitoyon","mrdoob","umhr","Nao_u","fumix","mtok","miniapp","HaraMakoto","coppieee",
"paq", "178ep3", "fladdict", "Hiiragi","yooKo","mash","9re","onedayitwillmake","beinteractive","a24",
"shotaicho","minon","demouth","ton","ABA","twistcube","yanbaka","rect","Murai","ll_koba_ll",
"naoto5959","knd","Kay","peko","northprint","hikipuro","enok","matsu4512","misty","wanson",
"zahir","set0","cellfusion","abakane","seyself", "tkinjo","szktkhr","osamX","muta244","milkmidi",
"heriet","dubfrog","flashrod","cda244","nulldesign","TX_298","yonatan","hiro_rec","katapad","enoeno",
"RoundRoom","Nicolas","dizgid","k__","gyuque","XELF","yshu","teageek","TheCoolMuseum","poiasd",
"y_tti","coppieeee","munegon","matsumos","KinkumaDesign","ish_xxxx","cjcat2266","kappaLab","runouw","iong"];


// Wonderfl API modules
//--------------------------------------------------
class WonderflAPI extends URLLoader {
    static public var apiKey:String = "", maxTrialCount:int = 3;
    static public function request(cmd:String, func:Function) : WonderflAPI { return new WonderflAPI(cmd, func); }
    
    private var _funcFinished:Function, _urlRequest:URLRequest, _trialCount:int=0;
    function WonderflAPI(cmd:String, func:Function) {
        super();
        _trialCount = maxTrialCount;
        _funcFinished = func;
        _urlRequest = new URLRequest("http://api.wonderfl.net/" + cmd + "?api_key=" + apiKey);
        addEventListener(Event.COMPLETE, _onComplete);
        addEventListener(IOErrorEvent.IO_ERROR, _onIOError);
        _request();
    }
    private function _request() : void {
        if (--_trialCount < 0) _onFinished(null);
        else load(_urlRequest);
    }
    private function _onComplete(e:Event) : void {
        var obj:* = JSON.decode(data as String);
        if (obj.stat=="fail") _request();
        else _onFinished(obj);
    }
    private function _onIOError(e:IOErrorEvent) : void { _onFinished(null); }
    private function _onFinished(obj:*) : void {
        removeEventListener(Event.COMPLETE, _onComplete);
        removeEventListener(IOErrorEvent.IO_ERROR, _onIOError);
        _funcFinished(obj);
    }
}

// User data
class WonderflUserData {
    private var _userName:String = "", _codes:Array = [];
    private var _requestedCount:int = -1, _loadedCount:int = 0, _progRate:Number = 1;
    private var _userIcon:Loader = new Loader();
    private var _funcFinished:Function = null;
    
    public function get isAvailable() : Boolean { return (_requestedCount == _loadedCount); }
    public function get progress() : Number { return _loadedCount * _progRate; }
    public function get userName() : String { return _userName; }
    public function get userIcon() : Loader { return _userIcon; }
    public function get codes() : Array { return _codes; }
    
    function WonderflUserData() { }
    
    public function clear() : void {
        if (_funcFinished != null) _funcFinished(null);
        _funcFinished = null;
        _userName = "";
        _codes = [];
        _requestedCount = -1;
        _progRate = 1;
        _loadedCount = 0;
    }
    
    public function load(name:String, funcFinished:Function=null) : void {
        clear();
        _funcFinished = funcFinished;
        WonderflAPI.request("user/" + name, _requestUserData);
    }
    
    private function _requestUserData(obj:*) : void {
        if (obj != null) {
            _userName = obj.user.name;
            FLoadUtil.load(obj.user.icon, _userIcon, _onLoaded, _onLoaded);
            WonderflAPI.request("user/" + _userName + "/codes", _requestCodeData); 
        } else clear();
    }
    
    private function _requestCodeData(obj:*) : void {
        if (obj!=null && obj.codes.length>0) {
            _requestedCount = obj.codes.length * 2 + 1; // length * (thumbnail + code) + icon
            _progRate = 1 / _requestedCount;
            for each (var c:* in obj.codes) { WonderflAPI.request("code/" + c.id, _recieveCodeData); }
        } else clear();
    }
    
    private function _recieveCodeData(obj:*) : void {
        if (obj != null && obj.code.compile_ok == 1) {
            var codeData:WonderflCodeData = new WonderflCodeData(this, obj.code);
            FLoadUtil.load(obj.code.thumbnail, codeData.thumbnail, _onLoaded, _onLoaded);
            _codes.push(codeData);
        } else {
            _loadedCount++; // thumbnail not read
        }
        _onLoaded();
    }
    
    private function _onLoaded() : void {
        _loadedCount++;
        if (isAvailable) {
            codes.sortOn("sortNum", Array.DESCENDING | Array.NUMERIC);
            if (_funcFinished != null) _funcFinished(this); 
            _funcFinished = null; 
        }
    }


/**/
    public function dummy(funcFinished:Function) : void {
        _userName = "dummy" + String(int(Math.random()*10000));
        var favBase:Number = Math.random()*0.5+0.2;
        for (var i:int=0; i<12; i++) {
            var fav:int = (Math.random()<favBase)?0:int((((Math.random()+Math.random()+Math.random())-1.5)*100));
            if (fav<0) fav = -(fav>>1);
            var data: WonderflCodeData = new WonderflCodeData(this, {
                "id": (int(Math.random()*0xffffff)).toString(16),
                "title":"card"+int(i),
                "diff":0,
                "favorite_count":fav,
                "forked_count":0,
                "modified_date":i,
                "as3":" \n \n \n"
            });
            data.lineCount = Math.random() * 1000;
            _codes.push(data);
        }
        _requestedCount = _loadedCount = 1;
        _progRate = 1;
        
        var t:Timer = new Timer(500, 1), me:WonderflUserData = this;
        t.addEventListener("timer", function(e:Event):void { funcFinished(me); } );
        t.start();
    }
}

// Code data
class WonderflCodeData {
    public var thumbnail:Loader = new Loader();
    public var user:WonderflUserData, id:String, title:String;
    public var code:String, sortNum:int, parentID:String;
    public var diff:int, favoriteCount:int, forkedCount:int;
    public var lineCount:int, nullLineCount:int, libraries:*;
    
    function WonderflCodeData(user:WonderflUserData, obj:*) {
        this.user     = user;
        id            = obj.id;
        title         = obj.title;
        parentID      = obj.parent || "";
        diff          = obj.diff;
        favoriteCount = obj.favorite_count;
        forkedCount   = obj.forked_count;
        sortNum       = obj.modified_date;
        code          = obj.as3;
        _analyze();
    }

    public function checkLib(nameList:Array) : Boolean {
        for each (var n:String in nameList) if (n in libraries) return true;
        return false;
    }
    
    private function _analyze() : void {
        lineCount = nullLineCount = 0;
        libraries = {};
        var nullLine:RegExp = new RegExp("^\\s*(//.*)?$"), importer:RegExp = new RegExp("^\\s*import");
        for each (var line:String in code.replace(/[\r\n]+/g, '\n').match(/^.*$/gm)) {
            if (nullLine.test(line)) nullLineCount++;
            else if (importer.test(line)) __analyzeLib(line);
            else lineCount++;
        }
    }
    
    private function __analyzeLib(path:String) : void {
        for (var key:String in libPathes) if (path.search(libPathes[key]) != -1) libraries[key] = true;
    }
    
    static public var libPathes:* = {
        "as3corelib":"com.adobe.",
        "tweener":"caurina.transitions.",
        "tweenlite":"gs.",
        "tweenmax":"com.greensock.",
        "tweensy":"com.flashdynamix.motion.",
        "betweenas3":"org.libspark.betweenas3.",
        "progression":"jp.progression.",
        "thread":"org.libspark.thread.",
        "frocessing":"frocessing.",
        "stats":"net.hires.debug.",
        "papervision3d":"org.papervision3d.",
        "sandy3d":"sandy.",
        "alternativa3d":"alternativa.",
        "five3d":"five3D.",
        "as3ds":"de.polygonal.ds.",
        "box2d":"Box2D.",
        "jiglib":"jiglib.",
        "swfassist":"org.libspark.swfassist.",
        "minimalcomps":"com.bit101.components.",
        "union":"net.user1.",
        "sion":"org.si.sion.",
        "stardust":"idv.cjcat.stardust.",
        "funnel":"funnel.",
        "modestmaps":"com.modestmaps.",
        "googlemaps":"com.google.maps.",
        "flashmedia":"flash.media.",
        "flashnet":"flash.net."
    };
}

