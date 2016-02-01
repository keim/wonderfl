// forked from bkzen's Wonderf Score 素材
package  
{
    import flash.display.*;
    import flash.text.TextField;
    import net.wonderfl.utils.WonderflAPI;
    import flash.events.*;
    import com.bit101.components.*;
    /**
     * ...
     * @author jc at bkzen
     */
    [SWF (backgroundColor = "0xFFFFFF", frameRate = "30", width = "465", height = "465")]
    public class WonderfScoreMain extends Sprite
    {
        
        public function WonderfScoreMain() 
        {
            if (stage) demo();
        }
        
        
        /** Setting parameters 
         *  @param api WonderflAPI instance
         *  @param param parameters
         */
        public function initialize(api:WonderflAPI, param:* = null) : void
        {
            _api = api;
            _title = ('title' in param) ? param['title'] : "SCORE";
            _denominator = ('denominator' in param) ? param['denominator'] : 1;
            _tweetFormat = ('tweet' in param) ? param['tweet'] : "";
            _scoreTitle = ('scoreTitle' in param) ? param['scoreTitle'] : "SCORE";
            _addScoreAfter = ('addScoreAfter' in param) ? param['addScoreAfter'] : "";
            _scoreLength = ('scoreLength' in param) ? param['scoreLength'] : 99;
            _scoreDescend = ('scoreDescend' in param) ? param['scoreDescend'] : 1;
            _tabWidth = ('_tabWidth' in param) ? param['_tabWidth'] : 55;
        }
        
        
        /** Setting score2 */
        public function score2(bits:int, format:String, title:String) : void
        {
            _score2Bits = bits;
            _score2Format = format;
            _score2Title = title;
        }
        
        
        /** Setting score3 */
        public function score3(bits:int, format:String, title:String) : void
        {
            _score3Bits = bits;
            _score3Format = format;
            _score3Title = title;
        }
        
        
        /** Score window */
        public function makeScoreWindow(score:int, score2:int, score3:int) : DisplayObject
        {
            _score = score;
            _score2 = score2;
            _score3 = score3;
            return new ScoreWindow(false);
        }
        
        
        /** Ranking window */
        public function makeRankingWindow() : DisplayObject
        {
            return new ScoreWindow(true);
        }
        
        
        /** 基本的な使い方はオリジナルと一緒．ただし、引数が多いのでinitialize()でパラメータ指定する形に変更．*/
        private function demo() : void {
            var param:* = {
                "tweet":"Score Window + [%SCORE%(Lv.%SCORE2%)]", 
                "denominator":10, 
                "title":"Score Window +"
            };
            
            // initialize() を最初に呼び出す。第２引数でパラメータ設定
            // Call initialize() first, 2nd argument sets all parameters.
            initialize(new WonderflAPI(loaderInfo.parameters), param);
            
            // score2(),score3() で複数種類のスコア設定．
            score2(10, "Lv%SCORE%", "Level");
            score3(14, "%SCORE%[pt]", "Bonus Point");
            
            // call makeScoreWindow() or makeRankingWindow() 
            new PushButton(this, 0, 0, "Score", function(e:Event) : void {
                addChild(makeScoreWindow(Math.random() * 1000000, Math.random() * 1000, Math.random() * 10000));
            });
            new PushButton(this, 0, 20, "Ranking", function(e:Event) : void {
                addChild(makeRankingWindow());
            });
        }
    }

}
import com.bit101.components.InputText;
import com.bit101.components.Label;
import com.bit101.components.PushButton;
import com.bit101.components.Style;
import com.bit101.components.VScrollBar;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Loader;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.net.navigateToURL;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.escapeMultiByte;
import net.wonderfl.data.APIScoreData;
import net.wonderfl.data.ScoreData;
import net.wonderfl.data.WonderflAPIData;
import net.wonderfl.utils.WonderflAPI;
import org.libspark.betweenas3.BetweenAS3;
import org.libspark.betweenas3.easing.Quad;
import org.libspark.betweenas3.tweens.IObjectTween;
import org.libspark.betweenas3.tweens.ITween;
import org.libspark.betweenas3.tweens.ITweenGroup;
var _api: WonderflAPI, _score: int, _title: String, _denominator: int, _tweet:String, _tweetFormat:String, _scoreTitle: String, _addScoreAfter: String, _scoreLength: uint, _scoreDescend: uint;
var _score2:int, _score2Bits:int = 0, _score2Title: String, _score2Format:String, _tabWidth:Number;
var _score3:int, _score3Bits:int = 0, _score3Title: String, _score3Format:String;

/**
 * 閉じられた時に出力されます。
 */
[Event(name="close", type="flash.events.Event")]
class ScoreWindow extends Sprite
{
    function ScoreWindow(rankingOnly:Boolean)
    {
        if (_tweetFormat) {
            _tweet = _tweetFormat.replace(/%SCORE%/g, (_score / _denominator)).replace(/%SCORE2%/g, _score2).replace(/%SCORE3%/g, _score3);
        }
        _rankingOnly = rankingOnly;
        if (stage) init();
        else addEventListener(Event.ADDED_TO_STAGE, init);
    }
    private var modalSp:Sprite;
    private var _rankingOnly:Boolean;
    
    private function init(e: Event = null): void 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        var window:* = (_rankingOnly) ? new RankingWindow() : new _ScoreWindow();
        window.closeHandler = onClose;
        window.x = stage.stageWidth  - window.width  >> 1;
        window.y = stage.stageHeight - window.height >> 1;
        addChild(modalSp = new Sprite());
        var g: Graphics = modalSp.graphics;
        g.beginFill(0xCCCCCC, 0.5);
        g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        addChild(window);
        stage.addEventListener(Event.RESIZE, onResize);
    }
    
    private function onResize(e:Event):void 
    {
        var g: Graphics = modalSp.graphics;
        g.clear();
        g.beginFill(0x333333, 0.3);
        g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        var i: int;
        for (i = 0; i < numChildren; i++) 
        {
            var d: DisplayObject = getChildAt(i);
            d.x = stage.stageWidth  - d.width  >> 1;
            d.y = stage.stageHeight - d.height >> 1;
        }
    }
    
    private function onClose():void 
    {
        while (numChildren > 0) removeChildAt(0);
        stage.removeEventListener(Event.RESIZE, onResize);
        parent.removeChild(this);
        dispatchEvent(new Event(Event.CLOSE));
    }
}

class _ScoreWindow extends Sprite
{
    private var iconLoader: Loader, input: InputText, registBtn: PushButton, closeBtn: PushButton, tweetBtn: PushButton;
    private var tween: IObjectTween;
    public var closeHandler: Function;
    
    function _ScoreWindow()
    {
        alpha = 0;
        var bg: Shape = new Shape();
        var g: Graphics = bg.graphics;
        g.beginFill(0x777777);
        g.drawRoundRectComplex(0, 0,  280, 180, 5, 5, 5, 5);
        g.beginFill(0xFFFFFF);
        g.drawRoundRectComplex(1, 1,  278,  20, 5, 5, 0, 0);
        g.drawRoundRectComplex(1, 22, 278, 157, 0, 0, 5, 5);
        bg.filters = [new DropShadowFilter(2, 45, 0, 1, 16, 16)];
        addChild(bg);
        BackupStyle.styleSet();
        new Label(this, 5, 3, _title);
        iconLoader = new Loader();
        iconLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompLoadIcon);
        iconLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorIcon);
        iconLoader.visible = false;
        iconLoader.x = 10, iconLoader.y = 60;
        addChild(iconLoader);
        var y:Number = 45;
        new Label(this, 75,  y, _scoreTitle + " :");
        new Label(this, 150, y, (_score / _denominator).toString() + " " + _addScoreAfter);
        y += 20;
        if (_score2Bits) {
            new Label(this, 75,  y, _score2Title + " :");
            new Label(this, 150, y, _score2.toString());
            y += 20;
        }
        if (_score3Bits) {
            new Label(this, 75,  y, _score3Title + " :");
            new Label(this, 150, y, _score3.toString());
            y += 20;
        }
        new Label(this, 75,  y, "PLAYER :");
        input = new InputText(this, 150, y, _api.viewerDisplayName);
        iconLoader.load(new URLRequest(_api.viewerIconURL));
        if (_tweet) tweetBtn = new PushButton(this, 10, 150, "TWEET", onClickTweet);
        registBtn = new PushButton(this, _tweet ? 100 : 35, 150, "REGISTER", onClickRegist);
        closeBtn = new PushButton(this, _tweet ? 190 : 145, 150, "CANCEL", onClickCancel);
        if (tweetBtn) tweetBtn.width = registBtn.width = closeBtn.width = 80;
        else registBtn.width = closeBtn.width = 100;
        tween = BetweenAS3.to(this, { alpha: 1 }, 1);
        tween.play();
        BackupStyle.styleBack();
    }
    
    private function onIOErrorIcon(e:IOErrorEvent):void 
    {
        iconLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompLoadIcon);
        iconLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorIcon);
    }
    
    private function onCompLoadIcon(e:Event):void 
    {
        iconLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompLoadIcon);
        iconLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorIcon);
        iconLoader.scaleX = iconLoader.scaleY = 0.5;
        iconLoader.visible = true;
    }
    
    private function onClickCancel(e: Event):void 
    {
        if (tween.isPlaying) tween.stop();
        tween = BetweenAS3.to(this, { alpha: 0 } );
        tween.onComplete = close;
        tween.play();
        btnDisable();
    }
    
    private function btnDisable(): void
    {
        if (tweetBtn) tweetBtn.enabled = false;
        registBtn.enabled = closeBtn.enabled = false;
    }
    
    private function close(): void
    {
        while (numChildren > 0) removeChildAt(0);
        input = null;
        if (tweetBtn) tweetBtn.removeEventListener(MouseEvent.CLICK, onClickTweet);
        registBtn.removeEventListener(MouseEvent.CLICK, onClickRegist);
        closeBtn.removeEventListener(MouseEvent.CLICK, onClickCancel);
        tweetBtn = registBtn = closeBtn = null;
        var f: Function = closeHandler;
        closeHandler = null;
        iconLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompLoadIcon);
        iconLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorIcon);
        iconLoader.unloadAndStop();
        iconLoader = null;
        if (f != null) f();
        if (parent) parent.removeChild(this);
    }
    
    private function onClickRegist(e: Event):void 
    {
        if (input.text == "") return;
        btnDisable();
        var window: RankingWindow = new RankingWindow(input.text);
        window.x = stage.stageWidth  - window.width  >> 1;
        window.y = stage.stageHeight - window.height >> 1;
        window.closeHandler = closeHandler;
        closeHandler = null;
        parent.addChild(window);
        tween.stop();
        tween = BetweenAS3.to(this, { alpha: 0 }, 0.5);
        tween.onComplete = close;
        tween.play();
    }
    
    private function onClickTweet(e: Event):void 
    {
        navigateToURL(new URLRequest("http://twitter.com/share?" + 
            "text=" + escapeMultiByte(_tweet) + "&url=" + escapeMultiByte("http://wonderfl.net/c/" + _api.appID)
        ));
    }
}
class RankingWindow extends Sprite
{
    private var _name: String;
    private var loader: URLLoader;
    private var bg: Shape, closeBtn:PushButton, loadingLabel:Label;
    private var tween: ITween;
    private var scoreData: APIScoreData;
    private var list: ScoreList;
    private var tweetBtn:PushButton;
    public var closeHandler: Function;
    function RankingWindow(name:String = null)
    {
        BackupStyle.styleSet();
        bg = new Shape();
        var g: Graphics = bg.graphics;
        g.beginFill(0x777777);
        g.drawRoundRectComplex(0, 0,  360, 340, 5, 5, 5, 5);
        g.beginFill(0xFFFFFF);
        g.drawRoundRectComplex(1, 1,  358, 20,  5, 5, 0, 0);
        g.drawRoundRectComplex(1, 22, 358, 317, 0, 0, 5, 5);
        g.beginFill(0x777777);
        g.drawRect(6, 27, 348, 282);
        g.beginFill(0xFFFFFF);
        g.drawRect(7, 28, 346, 280);
        bg.filters = [new DropShadowFilter(2, 45, 0, 1, 16, 16, 1)];
        addChild(bg);
        new Label(this, 5, 3, _title + " RANKING");
        var showTweetButton:Boolean = (_tweet && name);
        if (showTweetButton) tweetBtn = new PushButton(this, 75, 314, "TWEET", onClickTweet);
        closeBtn = new PushButton(this, showTweetButton ? 185 : 130, 314, "CLOSE", onClickClose);
        loadingLabel = new Label(this, 150, 160, "NOW LOADING...");
        BackupStyle.styleBack();
        
        alpha = 0;
        tween = BetweenAS3.to(this, {alpha: 1}, 0.5);
        tween.onComplete = check;
        tween.play();
        addEventListener(Event.ENTER_FRAME, loadingLoop);
        loader = new URLLoader();
        if (name) {
            _name = encode(name, _score2, _score3);
            loader.addEventListener(Event.COMPLETE, onCompSaveScore);
            var urlReq: URLRequest = _api.apiScorePostObject(_score, _name);
            urlReq.url = WonderflAPI.API_SCORE_SET.replace("%ID%", _api.appID);
            loader.load(urlReq);
        } else {
            loader.addEventListener(Event.COMPLETE, onCompLoadScore);
            loader.load(_api.apiScoreGet(_scoreLength, _scoreDescend));
        }
    }

    private function onClickTweet(e: Event):void 
    {
        navigateToURL(new URLRequest("http://twitter.com/share?" + 
            "text=" + escapeMultiByte(_tweet) + "&url=" + escapeMultiByte("http://wonderfl.net/c/" + _api.appID)
        ));
    }
    
    private function onClickClose(e: Event):void 
    {
        removeEventListener(Event.ENTER_FRAME, loadingLoop);
        closeBtn.removeEventListener(MouseEvent.CLICK, onClickClose);
        try { loader.close(); }
        catch (err: Error) { }
        
        if (tween && tween.isPlaying) tween.stop();
        tween = BetweenAS3.to(this, { alpha: 0 }, 0.5);
        tween.onComplete = close;
        tween.play();
    }
    
    private function close():void 
    {
        while (numChildren > 0) removeChildAt(0);
        var f: Function = closeHandler;
        closeHandler = null;
        list.clear();
        if (loader) 
        {
            loader.removeEventListener(Event.COMPLETE, onCompLoadScore);
            loader.removeEventListener(Event.COMPLETE, onCompSaveScore);
        }
        bg = null, closeBtn = null, loadingLabel = null, list = null;
        if (f != null) f();
        dispatchEvent(new Event(Event.CLOSE));
    }
    
    private function check():void 
    {
        if (scoreData && alpha == 1) 
        {
            removeEventListener(Event.ENTER_FRAME, loadingLoop);
            removeChild(loadingLabel);
            addChild(list = new ScoreList(7, 28, 346, 280));
            list.add(scoreData.scores, _name, _score)
        }
    }
    
    private function loadingLoop(e:Event):void 
    {
        loadingLabel.visible = !loadingLabel.visible;
    }
    
    private function onCompSaveScore(e:Event):void 
    {
        loader.removeEventListener(Event.COMPLETE, onCompSaveScore);
        var res: WonderflAPIData = new WonderflAPIData(JSON.parse(loader.data));
        if (res.isOK)
        {
            loader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onCompLoadScore);
            loader.load(_api.apiScoreGet(_scoreLength, _scoreDescend));
        }
        else 
        {
            removeEventListener(Event.ENTER_FRAME, loadingLoop);
            loadingLabel.visible = true;
            loadingLabel.text = "Score Save Error : " + res.stat + " : " + res.message;
        }
    }
    
    private function onCompLoadScore(e:Event):void 
    {
        loader.removeEventListener(Event.COMPLETE, onCompLoadScore);
        scoreData = new APIScoreData(JSON.parse(loader.data));
        if (scoreData.isOK)
        {
            check();
        }
        else 
        {
            removeEventListener(Event.ENTER_FRAME, loadingLoop);
            loadingLabel.visible = true;
            loadingLabel.text = "Score Load Error" + scoreData.stat + " : " + scoreData.message;
            scoreData = null;
            if (tweetBtn) tweetBtn.removeEventListener(MouseEvent.CLICK, onClickTweet); 
            tweetBtn = null;
        }
    }
}
class ScoreList extends Sprite
{
    private var container: Sprite;
    private var containerMask: Shape;
    private var scrollBar: VScrollBar;
    private var scoreLength: int;
    private var myScoreLCIndex: int;
    private var listChildren: Vector.<ListChild>;
    private var myScoreLC: ListChild;
    private var scrollValue: int;
    private var isClear: Boolean;
    private var highLightEffect:Shape;
    private var targetY: int;
    private var tween:ITweenGroup;
    private var w: int, h: int;
    function ScoreList(x: int, y: int, w: int, h: int)
    {
        this.x = x, this.y = y, this.w = w - 10, this.h = h;
        addChild(container = new Sprite());
        addChild(containerMask = new Shape());
        container.mask = containerMask;
        var g: Graphics = containerMask.graphics;
        g.beginFill(0xFFFFFF), g.drawRect(0, 0, this.w, h);
        scrollBar = new VScrollBar(this, this.w, 0);
        scrollBar.height = h;
    }
    
    public function add(scores: Vector.<ScoreData>, name: String, score: int): void 
    {
        scoreLength = scores.length, myScoreLCIndex = -1;
        listChildren = new Vector.<ListChild>(scoreLength, true);
        for ( var i: int = 0; i < scoreLength; i++ )
        {
            var s: ScoreData = scores[i];
            if (s.name == name && s.score == score) myScoreLCIndex = i;
            var listChild:ListChild = new ListChild(w, 21, _tabWidth, i + 1, decode(s));
            listChildren[i] = listChild;
            listChild.y = 20 * (i - (myScoreLCIndex < 0 ? 0 : 1));
            if (myScoreLCIndex == i) myScoreLC = listChild;
            else container.addChild(listChild);
        }
        var setScrollBar: Function = function(): void
        {
            scrollBar.setThumbPercent(13 / (scoreLength - 1));
            var max: int = scoreLength - 1 - 13;
            if (max < 0) max = 0;
            var now: int = myScoreLCIndex - 13;
            if (now < 0) now = 0;
            scrollBar.setSliderParams(0, max, now);
            scrollValue = now;
            scrollBar.addEventListener(Event.CHANGE, onChangeScroll);
            tween = null;
            if (isClear) clear();
        }
        if (myScoreLC) 
        {
            highLightEffect = new Shape();
            var g: Graphics = highLightEffect.graphics;
            g.beginFill(0x80FFFF);
            g.drawRect(- w >> 1, - 10, w, 21);
            myScoreLC.scaleX = myScoreLC.scaleY = 1.5;
            myScoreLC.alpha = 0;
            myScoreLC.x = w  - myScoreLC.width  >> 1;
            highLightEffect.x = w >> 1;
            if (myScoreLCIndex > 13) 
            {
                // 画面をスクロール
                myScoreLC.y = (targetY = 13 * 20) + (20 - myScoreLC.height >> 1);
                container.y = (13 - myScoreLCIndex) * 20;
            }
            else 
            {
                myScoreLC.y = (targetY = myScoreLCIndex * 20) + (20 - myScoreLC.height >> 1);
            }
            highLightEffect.y = targetY + 10;
            addChild(myScoreLC);
            var arr: Array = [];
            if (myScoreLCIndex != scoreLength - 1)
            {
                for (i = myScoreLCIndex + 1; i < scoreLength; i++ )
                {
                    arr.push(BetweenAS3.to(listChildren[i], { y: listChildren[i].y + 20 }, 0.5, Quad.easeInOut));
                }
            }
            arr.push(BetweenAS3.to(myScoreLC, { x: 0, y: targetY, scaleX: 1, scaleY:1 }, 0.5, Quad.easeOut));
            tween = BetweenAS3.serial(
                BetweenAS3.to(myScoreLC, { alpha: 1 }, 0.5),
                BetweenAS3.parallelTweens(arr),
                BetweenAS3.addChild(highLightEffect, this),
                BetweenAS3.to(highLightEffect, { alpha: 0, scaleX: 1.3, scaleY: 1.3 }, 0.5, Quad.easeOut),
                BetweenAS3.parallel(
                    BetweenAS3.removeFromParent(highLightEffect), BetweenAS3.removeFromParent(myScoreLC)
                )
            );
            tween.onComplete = function(): void
            {
                tween.onComplete = null;
                tween = null;
                myScoreLC.y = myScoreLCIndex * 20;
                container.addChildAt(myScoreLC, myScoreLCIndex);
                setScrollBar();
            }
            tween.play();
        }
        else 
        {
            setScrollBar();
        }
    }
    
    public function clear():void 
    {
        if (tween)
        {
            isClear = true;
        }
        else 
        {
            while (numChildren > 0) removeChildAt(0);
            while (container.numChildren > 0) container.removeChildAt(0);
            for (var i: int = 0; i < scoreLength; i ++ ) listChildren[i].clear();
            container.mask = null;
            container = null;
            containerMask = null;
            scrollBar = null;
            myScoreLC = null;
            highLightEffect = null;
        }
    }
    
    private function onChangeScroll(e:Event):void 
    {
        if (scrollValue == scrollBar.value) return;
        scrollValue = scrollBar.value;
        container.y = - scrollValue * 20;
    }
}
class ListChild extends Sprite
{
    private var indexLabel: Label;
    private var label: Label;
    private var scoreLabel: Label;
    private var scoreLabel2: Label;
    private var scoreLabel3: Label;
    function ListChild(w:int, h:int, tabWidth:int, index:int, scoreData:*)
    {
        BackupStyle.styleSet();
        var g: Graphics = graphics;
        g.beginFill(0xCCCCCC);
        g.drawRect(0, 0, w, h);
        g.drawRect(1, 1, w - 2, h - 2);
        g.beginFill(0xFFFFFF);
        g.drawRect(1, 1, w - 2, h - 2);
        indexLabel = new Label(this, 5, 0, String(index));
        label = new Label(this, 25, 0, scoreData.name);
        var align:Number = w - 5;
        if ("score3" in scoreData) {
            scoreLabel3 = new Label(this, 0, 0, scoreData.score3String);
            scoreLabel3.draw();
            scoreLabel3.x = align - scoreLabel3.width;
            align -= tabWidth;
        }
        if ("score2" in scoreData) {
            scoreLabel2 = new Label(this, 0, 0, scoreData.score2String);
            scoreLabel2.draw();
            scoreLabel2.x = align - scoreLabel2.width;
            align -= tabWidth;
        }
        scoreLabel = new Label(this, 0, 0, scoreData.scoreString);
        scoreLabel.draw();
        scoreLabel.x = align - scoreLabel.width;
        BackupStyle.styleBack();
    }
    
    public function clear():void 
    {
        graphics.clear();
        while (numChildren > 0) removeChildAt(0);
        indexLabel = null;
        label = null;
        scoreLabel = null;
    }
}
class BackupStyle
{
    public static var BACKGROUND: uint = 0xCCCCCC;
    public static var BUTTON_FACE: uint = 0xFFFFFF;
    public static var INPUT_TEXT: uint = 0x333333;
    public static var LABEL_TEXT: uint = 0x666666;
    public static var DROPSHADOW: uint = 0x000000;
    public static var PANEL: uint = 0xF3F3F3;
    public static var PROGRESS_BAR: uint = 0xFFFFFF;
    
    public static var embedFonts: Boolean = true;
    public static var fontName: String = "PF Ronda Seven";
    public static var fontSize: Number = 8;
    
    private static var b: Object;
    
    public static function styleSet(): void
    {
        b = {
            BACKGROUND:        Style.BACKGROUND,    BUTTON_FACE:    Style.BUTTON_FACE, 
            INPUT_TEXT:        Style.INPUT_TEXT,    LABEL_TEXT:        Style.LABEL_TEXT, 
            DROPSHADOW:        Style.DROPSHADOW,    PANEL:            Style.PANEL, 
            PROGRESS_BAR:    Style.PROGRESS_BAR,    embedFonts:        Style.embedFonts, 
            fontName:        Style.fontName,        fontSize:        Style.fontSize
        };
        Style.BACKGROUND = BACKGROUND,         Style.BUTTON_FACE = BUTTON_FACE;
        Style.INPUT_TEXT = INPUT_TEXT,         Style.LABEL_TEXT = LABEL_TEXT;
        Style.DROPSHADOW = DROPSHADOW,         Style.PANEL = PANEL;
        Style.PROGRESS_BAR = PROGRESS_BAR,     Style.embedFonts = embedFonts;
        Style.fontName = fontName,             Style.fontSize = fontSize;
    }
    
    public static function styleBack(): void
    {
        Style.BACKGROUND = b["BACKGROUND"], Style.BUTTON_FACE = b["BUTTON_FACE"];
        Style.INPUT_TEXT = b["INPUT_TEXT"], Style.LABEL_TEXT = b["LABEL_TEXT"];
        Style.DROPSHADOW = b["DROPSHADOW"], Style.PANEL = b["PANEL"];
        Style.PROGRESS_BAR = b["PROGRESS_BAR"], Style.embedFonts = b["embedFonts"];
        Style.fontName = b["fontName"], Style.fontSize = b["fontSize"];
    }
}

var b64Table:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function encode(name:String, score2:int, score3:int) : String {
    if (_score2Bits == 0 && _score3Bits == 0) return name;
    var data:int = ((score2 & ((1<<_score2Bits)-1)) << _score3Bits) | (score3 & ((1<<_score3Bits)-1)), i:int, 
        dstr:String = "", p:int=0;
    for (i=0; i<5; i++) {
        p ^= data & 63;
        dstr += b64Table.charAt(data & 63);
        data >>= 6;
    }
    dstr += b64Table.charAt(p);
    return name + dstr;
}

function decode(s:ScoreData) : * {
    var res:* = {"name":s.name, "score":s.score, "scoreString" : (s.score / _denominator).toString() + " " + _addScoreAfter};
    if (_score2Bits == 0 && _score3Bits == 0) return res;
    res["name"] = s.name.substr(0, s.name.length-6);
    var dstr:String = s.name.substr(-6), data:int=0, p:int=0, i:int, idx:int;
    p = b64Table.indexOf(dstr.charAt(5));
    for (i=4; i>=0; --i) {
        idx = b64Table.indexOf(dstr.charAt(i));
        if (idx == -1) return res;
        data = (data << 6) | idx;
        p ^= idx;
    }
    if (p != 0) return res;
    if (_score2Bits) {
        res["score2"] = p = (data>>_score3Bits) & ((1<<_score2Bits)-1);
        res["score2String"] = _score2Format.replace('%SCORE%', p.toString());
    }
    if (_score3Bits) {
        res["score3"] = p = data & ((1<<_score3Bits)-1);
        res["score3String"] = _score3Format.replace('%SCORE%', p.toString());
    }
    return res;
}
