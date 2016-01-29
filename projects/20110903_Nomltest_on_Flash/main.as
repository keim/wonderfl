package {
    import flash.display.*;
    import flash.events.*;
    import org.si.b3.*;

    [SWF(width="465", height="465", frameRate="30")]
    public class main extends Sprite {
        function main() {
            resManager = new ResourceManager(onResourceLoaded, loaderInfo.parameters);
            scrManager = new ScoreManager();
            actManager = new ActorManager();
        }
        
        public function onResourceLoaded() : void {
            mc = new CMLMovieClip(this, 8, 8, 450, 450, 0xffffff, true, setup);
            mc.control.map(CMLMovieClip.KEY_ESCAPE, "Q");
            mc.scene.register("title",     new TitleScene());
            mc.scene.register("main",      new MainScene());
            mc.scene.register("gameover",  new GameoverScene());
            mc.scene.id = "title";
        }
        
        public function setup() : void {
            resManager.sionDriver.bpm = 152;
            resManager.sionDriver.play();
        }
    }
}


// import --------------------------------------------------------------------------------
import flash.net.*;
import flash.geom.*;
import flash.events.*;
import flash.display.*;
import flash.filters.*;
import flash.utils.*;
import org.si.sion.*;
import org.si.sion.utils.soundloader.*;
import org.si.cml.*;
import org.si.cml.extensions.*;
import org.si.cml.namespaces.*;
import org.si.b3.*;
import net.wonderfl.utils.WonderflAPI;

// constant variables --------------------------------------------------------------------------------
const extendScore:int = 200000;
const defaultLife:int = 3;
const RANKING_WINDOW_URL:String = "http://swf.wonderfl.net/swf/usercode/7/7a/7af0/7af0cf8f5b74242e7eb21337bfd241a9682d2407.swf";
const checkPolicyFile:Boolean = true;
//const CHARA_MAP_URL :String = "charactor.png";
const CHARA_MAP_URL :String = "http://assets.wonderfl.net/images/related_images/e/e4/e488/e4889d7b98486f0edf339bb45c0a4114255988c2";
//const SOUND_FONT_URL:String = "sound.png";
const SOUND_FONT_URL:String = "http://assets.wonderfl.net/images/related_images/a/aa/aa9a/aa9a00df008e71a100500b5c90da9b71734af5e8";

// global instance --------------------------------------------------------------------------------
var mc:CMLMovieClip;
var resManager:ResourceManager;
var scrManager:ScoreManager;
var actManager:ActorManager;

// Scenes -------------------------------------------------------------------------------- 
class TitleScene {
    private var menuIndex:int, startLevel:int;
    private var menu:Array = ["Press [Z] Key To Start", "Show Net Ranking", "Clear Cookie", "Debug Mode"];
    private var anim:Array = [0, 4, 7, 9, 10, 9, 7, 4];
    public function enter() : void {
        mc.fps.reset();
        menuIndex = 0;
        startLevel = 0;
        scrManager.reset(true);
        actManager.reset();
        scrManager.debugMode = false;
    }
    
    public function update() : void {
        if (!mc.pause) {
            if (mc.control.isHitted(CMLMovieClip.KEY_BUTTON0)) {
                if (menuIndex == 2) {
                    scrManager.clearCookie();
                    scrManager.reset(true);
                } else if (menuIndex == 1) {
                    mc.pause = true;
                    resManager.showRanking(function(e:Event) : void { mc.pause = false; });
                } else mc.scene.id = "main";
            } else if (mc.control.isHitted(CMLMovieClip.KEY_RIGHT)) {
                if (--menuIndex == -1) menuIndex = menu.length-1;
                resManager.sionDriver.noteOn(67, resManager.beep, 1);
            } else if (mc.control.isHitted(CMLMovieClip.KEY_LEFT)) {
                if (++menuIndex == menu.length) menuIndex = 0;
                resManager.sionDriver.noteOn(67, resManager.beep, 1);
            } else {
                startLevel -= mc.control.y * 5;
                if (startLevel < 0) startLevel = 0;
                else if (startLevel > 250) startLevel = 250;
            }
        }
    }
    
    public function draw() : void {
        var menuString:String = menu[menuIndex], width:int = menuString.length * 8, 
            frameCount:int = mc.fps.totalFrame;
        mc.copyPixels(resManager.background, 0, 0, 450, 450, -225, -225);
        scrManager.draw();
        resManager.print(-166, -56, "NOMLTEST FL", resManager.lfonttex, 32);
        resManager.print(-width, 160, menuString, resManager.fonttex, 16);
        resManager.print(-196-anim[frameCount&7], 160, "{", resManager.fonttex, 16);
        resManager.print( 180+anim[frameCount&7], 160, "}", resManager.fonttex, 16);
        resManager.print(-128, 90, "START LEVEL : " + startLevel.toString(), resManager.fonttex, 16); 
    }
    
    public function exit() : void {
        scrManager.startLevel = startLevel;
        scrManager.debugMode = (menuIndex == 3);
    }
}

class MainScene {
    public function enter() : void {
        mc.fps.reset();
        scrManager.reset(false);
        actManager.reset();
        actManager.start();
        resManager.sionDriver.play(resManager.bgm);
        resManager.sionDriver.playSound(6,1,0,0,2);
    }
    
    public function update() : void {
        scrManager.update();
        actManager.update();
        if (mc.control.getPressedFrame(CMLMovieClip.KEY_ESCAPE) > 15) {
            resManager.sionDriver.play();
            mc.scene.id = "title";
        }
    }
    
    public function draw() : void {
        var f:int, t:Number;
        mc.copyPixels(resManager.background, 0, 0, 450, 450, -225, -225);
        scrManager.draw();
        actManager.draw();
        if (mc.fps.totalFrame < 90) {
            f = mc.fps.totalFrame;
            if (f < 70) {
                t = (f<50) ? ((40-f) * (40-f) - 100) * 0.2 : 0;
                resManager.print(-102-t, -32, "ARE YOU", resManager.lfonttex, 32);
                resManager.print(-102+t,   0, "READY ?", resManager.lfonttex, 32);
            } else {
                resManager.print(-70, -16, "GO !!", resManager.lfonttex, 32);
            }
        }
    }

    public function exit() : void {}
}

class GameoverScene {
    private var referenceRecord:Boolean;
    public function enter() : void {
        referenceRecord = (scrManager.delayedFrames > mc.fps.totalFrame*0.1);
        mc.fps.reset();
        resManager.sionDriver.play(resManager.gameover);
        resManager.sionDriver.playSound(2,1,0,0,2);
    }
    
    public function update() : void {
        if (!mc.pause) {
            scrManager.update();
            actManager.update();
            if (mc.fps.totalFrame > 60 && mc.control.isHitted(CMLMovieClip.KEY_BUTTON0)) {
                if (!referenceRecord && scrManager.checkResult()) {
                    mc.pause = true;
                    resManager.registerRanking(function(e:Event) : void {
                        mc.pause = false;
                        mc.scene.id = "title";
                    });
                } else mc.scene.id = "title";
            }
        }
    }
    
    public function draw() : void {
        mc.copyPixels(resManager.background, 0, 0, 450, 450, -225, -225);
        scrManager.draw();
        actManager.draw();
        resManager.print(-136, -32, "GAME OVER", resManager.lfonttex, 32);
        if (referenceRecord) resManager.print(-96, 16, "REFERENCE=RECORD", resManager.numtex, 12, 48);
    }
    
    public function exit() : void {}
}

// Managers --------------------------------------------------------------------------------
class ResourceManager {
    public var bgangle:Number = -90, bgcolor1:uint = 0xf0f0ff, bgcolor2:uint = 0xb0b0cf;
    public var sionDriver:SiONDriver = new SiONDriver();
    public var damageColt:ColorTransform = new ColorTransform(1,1,1,1,-128,-128,-128,0);
    public var playerTexture:CMLMovieClipTexture, shotTexture:CMLMovieClipTexture;
    public var fonttex:CMLMovieClipTexture, lfonttex:CMLMovieClipTexture;
    public var numtex:CMLMovieClipTexture, lnumtex:CMLMovieClipTexture;
    public var scoreTextures:Array, explosionTextures:Array, enemyTextures:Array, bulletTextures:Array, enemyColors:Array;
    public var lifeUpTexture:CMLMovieClipTexture;
    public var background:BitmapData = new BitmapData(450, 450, false, 0xffffff);
    public var bgm:SiONData, gameover:SiONData, sequences:*, beep:SiONVoice;
    public var charactorMap:BitmapData, stageSequence:CMLSequence;
    public var groupID:Array = [0, 0, 0, 3, 3, 3, 6, 7, 7, 9, 10, 9, 0, 13, 0];
    public var shotSeq:Array, groupSeq:Array, enemySeq:Array;
    public var onResourceLoaded:Function, rankingMaker:*, loaderInfoParameters:*;
    function ResourceManager(onResourceLoaded:Function, loaderInfoParameters:*) {
        this.loaderInfoParameters = loaderInfoParameters;
        // Loader --------------------------------------------------
        var loader:SoundLoader = new SoundLoader();
        this.onResourceLoaded = onResourceLoaded;
        loader.setURL(new URLRequest(CHARA_MAP_URL), "cmap", "img", checkPolicyFile);
        loader.setURL(new URLRequest(SOUND_FONT_URL), "sample", "ssfpng", checkPolicyFile);
        loader.setURL(new URLRequest(RANKING_WINDOW_URL), "ranking", "swf");
        //loader.setURL(new URLRequest("nomltest.mml"), "bgm", "txt");
        //loader.setURL(new URLRequest("gameover.mml"), "gameover", "txt");
        //loader.setURL(new URLRequest("script.cml"), "script", "txt");
        loader.addEventListener(Event.COMPLETE, _onComplete);
        loader.loadAll();
    }
    private function _onComplete(e:Event) : void {
        var data:* = SoundLoader(e.target).hash, bmp:BitmapData = new BitmapData(128, 128, true, 0xffffffff),
            red:Array=[0.7,0.4,0.4], grn:Array=[0.4,0.7,0.4], blu:Array=[0.4,0.4,0.7], 
            i:int, j:int, c:int, mat:Matrix = new Matrix(), t:CMLMovieClipTexture, bd:BitmapData, lbl:String;
        
        // CannonML --------------------------------------------------
        CMLObject.setGlobalRankRange(0, 999);
        CMLSequence.registerUserCommand("rungroup",   _onRunGroup, 1);
        CMLSequence.registerUserCommand("groupbonus", _onGroupBonus, 1);
        
        // Textures --------------------------------------------------
        charactorMap = data["cmap"].bitmapData;
        bmp.copyChannel(charactorMap, bmp.rect, bmp.rect.topLeft, 1, 8);
        playerTexture = newTexture(bmp, 16, 0, 16, 16, 1, 2, blu, true, true);
        shotTexture   = newTexture(bmp, 56, 0,  8, 16, 1, 2, [0.7, 0.6, 0.4], false, false);
        fonttex  = newTexture(bmp, 0, 64, 8, 8, 96, 2, [0.375, 0.375, 0.5], true, false);
        lfonttex = newTexture(bmp, 0, 64, 8, 8, 96, 4, [0.375, 0.375, 0.5], true, false);
        numtex   = newTexture(bmp, 0, 112, 6, 6, 42, 2, [0.375, 0.375, 0.375], false, false);
        lnumtex  = newTexture(bmp, 0, 112, 6, 6, 42, 4, [0.75, 0.25, 0.25],    false, false);
        // text
        scoreTextures = [];
        for (i=0; i<=50; i++) scoreTextures.push(renderText(i.toString()+"0", numtex));
        for (i=1; i<4; i++) scoreTextures[i*100] = renderText(i.toString()+"000", lnumtex);
        lifeUpTexture = renderText("1UP", lnumtex);
        enemyTextures = [];
        enemyColors = [];
        // enemies
        for (i=0; i<4; i++) {
            enemyTextures.push(newTexture(bmp, i*16+64, 0, 16, 16, 1, 2, blu, true, true));
            enemyTextures.push(newTexture(bmp, i*16+64, 0, 16, 16, 1, 2, grn, true, true));
            enemyTextures.push(newTexture(bmp, i*16+64, 0, 16, 16, 1, 2, red, true, true));
            enemyColors.push(0x9999c3, 0x99c399, 0xc39999);
        }
        enemyTextures.push(newTexture(bmp,  64, 0, 16, 16, 1, 4, blu, true, true));
        enemyTextures.push(newTexture(bmp,  80, 0, 16, 16, 1, 4, grn, true, true));
        enemyTextures.push(newTexture(bmp,  96, 0, 16, 16, 1, 4, red, true, true));
        enemyTextures.push(newTexture(bmp, 112, 0, 16, 16, 1, 4, [0.7, 0.7, 0.4], true, true));
        enemyColors.push(0x9999c3, 0x99c399, 0xc39999, 0xc3c399);
        // explosions
        explosionTextures = [];
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 4, blu, true, false));
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 4, grn, true, false));
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 4, red, true, false));
        for (i=1; i<4; i++) explosionTextures.push(explosionTextures[0], explosionTextures[1], explosionTextures[2]);
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 6, blu, true, false));
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 6, grn, true, false));
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 6, red, true, false));
        explosionTextures.push(newTexture(bmp, 0, 32, 16, 16, 16, 6, [0.7, 0.7, 0.4], true, false));
        // bullets
        bulletTextures = [
            newTexture(bmp,  0, 16, 8, 8, 6, 2, blu, true, false),
            newTexture(bmp,  0, 24, 8, 8, 8, 2, grn, true, false),
            newTexture(bmp, 64, 16, 8, 8, 8, 2, red, true, false),
            newTexture(bmp, 64, 24, 8, 8, 8, 2, blu, true, false),
            newTexture(bmp, 64, 24, 8, 8, 8, 2, grn, true, false),
            newTexture(bmp, 64, 24, 8, 8, 8, 2, red, true, false),
            newTexture(bmp, 48, 16, 8, 8, 2, 2, red, true, false)
        ];
            
        // Background --------------------------------------------------
        var drawer:Shape = new Shape, g:Graphics = drawer.graphics;
        mat.createGradientBox(450, 450, (bgangle+90)*0.017453292519943295, 0, 0);
        g.clear();
        g.beginGradientFill(GradientType.LINEAR, [bgcolor1, bgcolor2], [1,1], [0,255], mat);
        g.drawRect(0, 0, 720, 480);
        g.endFill();
        background.draw(drawer);
        g.lineStyle(2, 0, 0.125);
        for (i=0; i<=450; i+=50) {
            g.moveTo(0,i);
            g.lineTo(450,i);
            g.moveTo(i,0);
            g.lineTo(i,450);
        }
        background.draw(drawer);
        
        // Sound --------------------------------------------------
        beep = new SiONVoice(0, 0, 63, 36, 4, 0, 0, -4);
        sionDriver.noteOnExceptionMode = SiONDriver.NEM_IGNORE;
        sionDriver.setSamplerTable(0, data["sample"].samplerTables[0]);
        //bgm = sionDriver.compile(data["bgm"]);
        bgm = sionDriver.compile(mmlMain);
        //gameover = sionDriver.compile(data["gameover"]);
        gameover = sionDriver.compile(mmlGameOver);
        
        // Sequences --------------------------------------------------
        //stageSequence = new CMLSequence(data["script"]);
        stageSequence = new CMLSequence(cmlScript);
        sequences = stageSequence.childSequence;
        shotSeq = [sequences["S1"],sequences["S2"],sequences["S3"]];
        groupSeq = [];
        enemySeq = [];
        for (i=0; i<32; i++) {
            if ((lbl = "G" + i.toString()) in sequences) groupSeq[i] = sequences[lbl];
            if ((lbl = "E" + i.toString()) in sequences) enemySeq[i] = sequences[lbl];
        }
        
        // Ranking window
        var param:* = {
            tweet:"Nomltest FL [SCORE:%SCORE%/LEVEL:%SCORE2%] #wonderfl", 
            scoreTitle:"SCORE", 
            title:"Nomltest FL Net Ranking"
        }
        rankingMaker = data["ranking"];
        rankingMaker.initialize(new WonderflAPI(loaderInfoParameters), param);
        rankingMaker.score2(12, "Lv.%SCORE%", "LEVEL");
        rankingMaker.score3(15, "%SCORE% eat", "EATEN");

        onResourceLoaded();
    }
    
    private var shadow:DropShadowFilter = new DropShadowFilter(3, 45, 0, 0.5, 4, 4);
    private function newTexture(bmp:BitmapData, x:Number, y:Number, w:Number, h:Number, a:int, scale:Number, c:Array, shd:Boolean, flash:Boolean) : CMLMovieClipTexture {
        var org:CMLMovieClipTexture = new CMLMovieClipTexture(bmp, x, y, w, h, false, a, int(bmp.width/w)*w-w), tex:CMLMovieClipTexture; // int(bmp.width/w)*w-w (for avoid bug)
        tex = org.cutout(scale, scale, 0, new ColorTransform(c[0],c[1],c[2],1), 0, (shd)?6:0);
        if (flash) {
            tex.animationPattern = new Vector.<CMLMovieClipTexture>(2, true);
            tex.animationPattern[0] = tex;
            tex.animationPattern[1] = org.cutout(scale, scale, 0, new ColorTransform(1-(1-c[0])*0.6,1-(1-c[1])*0.6,1-(1-c[2])*0.6,1), 0, (shd)?6:0);
        }
        if (shd) {
            var i:int, imax:int = tex.animationCount, bmd:BitmapData;
            for (i=0; i<imax; i++) {
                bmd = tex.animationPattern[i].bitmapData;
                bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft, shadow);
            }
        }
        return tex;
    }

    public function renderText(txt:String, font:CMLMovieClipTexture, asciiOffset:int=48) : CMLMovieClipTexture {
        var pt:Point = new Point(), i:int, imax:int=txt.length, t:CMLMovieClipTexture, 
            bd:BitmapData = new BitmapData(font.width*imax, font.height, true, 0);
        for (i=0; i<imax; i++) {
            t = font.animationPattern[txt.charCodeAt(i) - asciiOffset];
            bd.copyPixels(t.bitmapData, t.rect, pt);
            pt.x += font.width;
        }
        return new CMLMovieClipTexture(bd);
    }
    
    public function print(x:Number, y:Number, txt:String, font:CMLMovieClipTexture, pitch:int, asciiOffset:int=32) : void {
        var tx:Number=x+8, ty:Number=y+8, i:int, imax:int=txt.length;
        for (i=0; i<imax; i++) {
            mc.copyTexture(font, tx, ty, txt.charCodeAt(i)-asciiOffset);
            tx += pitch;
        }
    }
    
    public function showRanking(onClose:Function) : void {
        var window:* = rankingMaker.makeRankingWindow();
        window.addEventListener(Event.CLOSE, onClose);
        mc.parent.addChild(window);
    }
    
    public function registerRanking(onClose:Function) : void {
        var window:* = rankingMaker.makeScoreWindow(scrManager.score, scrManager.level, scrManager.eaten);
        window.addEventListener(Event.CLOSE, onClose);
        mc.parent.addChild(window);
    }
    
    // called from &rungroup command in CML
    private function _onRunGroup(fbr:CMLFiber, args:Array) : void {
        var enemyType:int = (args[0]==0) ? int(Math.random()*15) : (args[0]-1);
        Group.run(groupID[enemyType], enemyType);
    }
    
    // called from &groupbonus command in CML
    private function _onGroupBonus(fbr:CMLFiber, args:Array) : void {
        var g:Group = fbr.object as Group;
        if (g) {
            g.finished = true;
            g.bonus = args[0];
        }
    }
}

//--------------------------------------------------------------------------------
class ScoreManager {
    public var score:int, level:int, eaten:int, life:int, eatBonus:int, nextExtend:int, gameoverLevel:int;
    public var bestResult:*, startLevel:int, debugMode:Boolean, delayedFrames:int;
    private var _scoreDraw:int, _levelDraw:int, _eatenDraw:int, _lifeDraw:int;
    private var _scoreText:String, _levelText:String, _eatenText:String, _lifeText:String;

    function ScoreManager() {
        _loadCookie();
        reset(false);
    }
    
    public function reset(setHighScore:Boolean) : void {
        CMLObject.globalRank = startLevel;
        _scoreDraw = score = (setHighScore) ? bestResult.score : 0;
        _levelDraw = level = (setHighScore) ? bestResult.level : startLevel;
        _eatenDraw = eaten = (setHighScore) ? bestResult.eaten : 0;
        _scoreText = "SCORE:" + ("000000000" + _scoreDraw.toString()).substr(-10);
        _levelText = "LEVEL:" + ("00" + _levelDraw.toString()).substr(-3);
        _eatenText = "EATEN:" + ("00000" + _eatenDraw.toString()).substr(-6);
        _lifeText  = "LIFE :";
        _lifeDraw = 0;
        life = (debugMode) ? 0 : defaultLife;
        eatBonus = 2;
        nextExtend = extendScore;
        delayedFrames = 0;
    }
    
    public function update() : void {
        var dif:int = (score - _scoreDraw + 7) >> 3;
        level = int(CMLObject.globalRank);
        _scoreDraw += dif;
        if (dif > 0) {
            _scoreText = "SCORE:" + ("000000000" + _scoreDraw.toString()).substr(-10);
        }
        if (_levelDraw != level) {
            _levelDraw = level;
            _levelText = "LEVEL:" + ("00" + _levelDraw.toString()).substr(-3);
        }
        if (_eatenDraw != eaten) {
            _eatenDraw = eaten;
            _eatenText = "EATEN:" + ("00000" + _eatenDraw.toString()).substr(-6);
        }
        if (_lifeDraw != life) {
            _lifeDraw = life;
            if (debugMode) {
                _lifeText = "MISS :" + _lifeDraw.toString();
            } else {
                _lifeText = "LIFE :";
                for (var i:int=0; i<_lifeDraw; i++) _lifeText += "|";
            }
        }
        if (mc.fps.frameSkipLevel > 3) delayedFrames++;
    }
    
    public function draw() : void {
        resManager.print(-220, -220, _scoreText, resManager.fonttex, 16);
        resManager.print(-220, -204, _levelText, resManager.fonttex, 16);
        resManager.print(-220, -188, _eatenText, resManager.fonttex, 16);
        resManager.print(-220, -172, _lifeText,  resManager.fonttex, 16);
        if (debugMode) {
            resManager.print(-223, 190, "PRESS [Q] TO EXIT", resManager.fonttex, 16);
            resManager.print(-223, 209, "FRAME DELAY :"+mc.fps.delayedFrames.toFixed(2), resManager.fonttex, 16);
        }
    }
    
    public function checkResult() : Boolean {
        return _updateCookie();
    }
    
    public function destroyAll(groupBonus:int) : void {
        eatBonus += 3;
        if (eatBonus > 50) eatBonus = 50;
        addScore(groupBonus);
    }
    
    public function destroyAllFailed() : void {
        eatBonus -= 2;
        if (eatBonus < 1) eatBonus = 1;
    }
    
    public function miss() : Boolean {
        actManager.destroyAllEnemies();
        eatBonus>>= 1;
        if (eatBonus < 1) eatBonus = 1;
        if (debugMode) {
            life++;
        } else {
            if (--life < 0) {
                gameoverLevel = level;
                mc.scene.id = "gameover"
                return true;
            }
        }
        return false;
    }
    
    public function eat() : int {
        eaten++;
        addScore(eatBonus * 10);
        return eatBonus;
    }
    
    public function addScore(gain:int) : void {
        score += gain;
        if (score >= nextExtend) {
            nextExtend += extendScore;
            life++;
            resManager.sionDriver.playSound(5,1,0,0,3);
            Particle.$(actManager.player.x, actManager.player.y, 0, -10, 0, 0.75, 0, resManager.lifeUpTexture);
        }
    }
    
    public function clearCookie() : void {
        var so:SharedObject = SharedObject.getLocal("savedData");
        if (so) so.clear();
        bestResult = {"score":0, "level":0, "lines":0};
    }
    
    private function _loadCookie() : void {
        var so:SharedObject = SharedObject.getLocal("savedData");
        bestResult = (so && "bestResult" in so.data) ? (so.data.bestResult) : {"score":0, "level":0, "eaten":0};
    }
    
    private function _updateCookie() : Boolean {
        if (startLevel != 0 || debugMode) return false;
        var updated:Boolean = false, so:SharedObject, isHighScore:Boolean = (score > bestResult.score);
        if (score > bestResult.score) { updated = true; bestResult.score = score; }
        if (gameoverLevel > bestResult.level) { updated = true; bestResult.level = gameoverLevel; }
        if (eaten > bestResult.eaten) { updated = true; bestResult.eaten = eaten; }
        if (updated && (so = SharedObject.getLocal("savedData"))) {
            so.data.bestResult = bestResult;
            so.flush();
        }
        return (isHighScore);
    }
}

//--------------------------------------------------------------------------------
class ActorManager {
    public var shots:ActorFactory;
    public var enemies:ActorFactory;
    public var bullets:ActorFactory;
    public var player:Player;
    public var master:Group;
    public var frameCounter:int;
    public var groupID:int;
    public var pauseRoot:Boolean = false;
    
    function ActorManager() {
        shots     = new ActorFactory(Shot, 0, 0);
        enemies   = new ActorFactory(Enemy, 0, 1);
        bullets   = new ActorFactory(Bullet, 0, 2);
        player = new Player();
        player.evalIDNumber = 3;
        player.drawPriority = enemies.drawPriority;
        Particle.initialize(640);
    }
    
    public function reset() : void {
        CMLObject.destroyAll(0);
        Particle.reset();
    }
    
    public function start() : void {
        player.create(0, 180);
        master = new Group();
        master.create(0, 0);
        master.execute(resManager.stageSequence);
    }
    
    public function draw() : void {
        Particle.draw();
        Actor.draw();
    }
    
    public function update() : void {
        // Actor.update() is called from CMLMovieClip
        Particle.update();
        if (player.status != Player.STATUS_INVISIBLE) Actor.testf(bullets.evalIDNumber, player.evalIDNumber);
        Actor.testf(shots.evalIDNumber, enemies.evalIDNumber);
    }
    
    public function destroyAllEnemies() : void {
        eval(enemies.evalIDNumber, function(act:Actor) : void { 
            act.destroy(2); 
        });
        eval(bullets.evalIDNumber, function(act:Actor) : void { 
            Particle.$(act.x, act.y, Math.random()*8-4, Math.random()*6-4, 0, 0.4, 0xaaaac3);
            act.destroy(0);
        });
    }
    
    static public function eval(evalID:int, func:Function) : void {
        var act:Actor, list:Actor = Actor._cml_internal::_evalLayers[evalID];
        for (act=list._cml_internal::_nextEval; act!=list; act=act._cml_internal::_nextEval) func(act);
    }
}

// Actors --------------------------------------------------------------------------------
class Player extends Actor {
    static public const STATUS_TRANSPARENT:int = 0;
    static public const STATUS_NORMAL:int = 1;
    static public const STATUS_INVISIBLE:int = 2;
    public var status:int, statuFrameCount:int, animationCount:int, hitSize2:Number;
    public var shotFlag:int, eatRangeShape:Shape, eatRangeAngle:Number;
    public var eatRangeDraw:Number;
    public var playerSpeed:Array = [10, 9, 9, 5];
    public var eatRange:Array = [60, 45, 30, 55];
    
    public function Player() {
        scopeEnabled = false;
        eatRangeAngle = 0;
        size = 60;
        hitSize2 = 16;
        eatRangeDraw = 0;
        eatRangeShape = new Shape();
    }
    
    override public function onCreate() : void {
        animationCount = 0;
        shotFlag = 0;
        setAsDefaultTarget();
        expandScope(-16-mc.scopeMargin, -16-mc.scopeMargin);
        status = STATUS_INVISIBLE;
        statuFrameCount = 30;
    }
    
    override public function onUpdate() : void {
        var ix:int = mc.control.x, iy:int = mc.control.y,
            flg:uint = (mc.control.flag >> 4) & 3,
            dx:Number = ix * ((iy==0) ? 1 : 0.707), dy:Number = iy * ((ix==0) ? 1 : 0.707),
            spd:Number = playerSpeed[flg];
        if (status != STATUS_INVISIBLE) {
            x += dx * spd;
            y += dy * spd;
            limitScope();
            if (shotFlag != flg) {
                halt();
                shotFlag = flg;
                if (shotFlag > 0) execute(resManager.shotSeq[shotFlag-1]);
                size = eatRange[shotFlag];
            }
            eatRangeAngle += eatRangeDraw * 0.002;
                 if (size > eatRangeDraw) eatRangeDraw += 2;
            else if (size < eatRangeDraw) eatRangeDraw -= 2;
        }
        
        if (--statuFrameCount == 0) {
            if (status == STATUS_TRANSPARENT) status = STATUS_NORMAL;
            else setTransparent();
        }
    }

    override public function onDraw() : void {
        if (status != STATUS_INVISIBLE) {
            animationCount++;
            if ((status == STATUS_NORMAL) || (animationCount & 1)) {
                mc.copyTexture(resManager.playerTexture, x, y);
            }
            updateEatRange();
            mc.draw(eatRangeShape, x, y)
        } else {
            mc.copyTexture(resManager.playerTexture, x, y + ((statuFrameCount-6) * (statuFrameCount-6) - 36) * 0.4);
        }
    }
    
    override public function onFireObject(args:Array) : CMLObject {
        return actManager.shots.newInstance();
    }
    
    override public function onHit(act:Actor) : void {
        if (status == STATUS_TRANSPARENT) return;
        var dx:Number = act.x - x, dy:Number = act.y - y, i:int;
        if (dx * dx + dy * dy < hitSize2) {
            Particle.$(x, y, 0, 0, 0, 0, 0, resManager.explosionTextures[12]);
            for (i=0; i<32; i++) Particle.$(x, y, Math.random()*8-4, Math.random()*6-8, 0, 0.4, 0xaaaac3);
            setDestruction(scrManager.miss());
        }
    }
    
    public function setTransparent() : void {
        status = STATUS_TRANSPARENT;
        statuFrameCount = 60;
    }
    
    public function setDestruction(gameover:Boolean) : void {
        halt();
        status = STATUS_INVISIBLE;
        if (!gameover) {
            statuFrameCount = 30;
            resManager.sionDriver.playSound(2,1,0,0,2);
        } else {
            statuFrameCount = -1;
        }
    }
    
    private var cmd:Vector.<int> = Vector.<int>([1,2,2,2,2]);
    private var path:Vector.<Number> = new Vector.<Number>();
    private function updateEatRange() : void {
        var g:Graphics = eatRangeShape.graphics,
            sin:Number = Math.sin(eatRangeAngle) * eatRangeDraw,
            cos:Number = Math.cos(eatRangeAngle) * eatRangeDraw,
            asin:Number = (sin<0) ? -sin : sin,
            acos:Number = (cos<0) ? -cos : cos;
        path[0] =  cos; path[1] = sin;
        path[2] = -sin; path[3] = cos;
        path[4] = -cos; path[5] = -sin;
        path[6] =  sin; path[7] = -cos;
        path[8] =  cos; path[9] =  sin;
        g.clear();
        g.lineStyle(2, 0x4040c0, 0.5);
        g.drawPath(cmd, path);
        g.drawRect(-acos, -asin, acos*2, asin*2);
    }
}

//--------------------------------------------------------------------------------
class Shot extends Actor {
    public function Shot() { size = 10; }
    override public function onCreate() : void { }//scopeYmax = 400; }
    override public function onDraw() : void { mc.copyTexture(resManager.shotTexture, x, y); }
    override public function onHit(act:Actor) : void { destroy(1); }
}

//--------------------------------------------------------------------------------
class Group extends CMLObject {
    static private var _freeList:Array = [];
    static public function run(groupType:int, enemyType:int) : void { 
        var group:Group = _freeList.pop() || new Group();
        group.create(0, 0);
        group.execute(resManager.groupSeq[groupType]);
        group.enemyType = enemyType;
        group.bonus = group.childCount = 0;
        group.destroyAll = true;
        group.finished = false;
    }
    public var enemyType:int, childCount:int, finished:Boolean, destroyAll:Boolean, bonus:int;
    function Group() { }
    public function onChildDestroy(enemy:Enemy) : int {
        if (enemy.destructionStatus == 0) destroyAll = false;
        if (--childCount == 0 && finished) {
            if (bonus>0) {
                if (destroyAll) {
                    scrManager.destroyAll(bonus);
                    Particle.$(enemy.x, enemy.y, 0, -6, 0, 0.5, 0, resManager.scoreTextures[bonus]);
                } else {
                    scrManager.destroyAllFailed();
                }
            }
            destroy(0);
        }
        return 0;
    }
    override public function onDestroy() : void { _freeList.push(this); }
    override public function onNewObject(args:Array) : CMLObject {
        var enemy:Enemy = actManager.enemies.newInstance();
        enemy.type = enemyType;
        enemy.group = this;
        childCount++;
        return enemy;
    }
}

//--------------------------------------------------------------------------------
class Enemy extends Actor {
    private var flagDamage:int = 0;
    public  var type:int, group:Group, texture:CMLMovieClipTexture, bonus:int;
    public function Enemy() {}
    override public function onCreate() : void {
        var seq:CMLSequence = resManager.enemySeq[type];
        flagDamage = 0;
        life = seq.getParameter(0);
        bonus = seq.getParameter(1);
        texture = resManager.enemyTextures[type];
        size = texture.center.x;
        execute(seq);
    }
    override public function onDestroy() : void {
        group.onChildDestroy(this);
        if (destructionStatus > 0) {
            Particle.$(x, y, vx, vy, -vx*0.04, -vy*0.04, 0, resManager.explosionTextures[type]);
            if (destructionStatus == 1) {
                Particle.$(x, y, 0, -6, 0, 0.5, 0, resManager.scoreTextures[bonus]);
                var i:int, col:uint = resManager.enemyColors[type];
                for (i=0; i<6; i++) Particle.$(x, y, Math.random()*4-2+vx*0.3, Math.random()*4-2+vy*0.3, 0, 0.5, col);
            }
        }
    }
    override public function onDraw() : void { --flagDamage; mc.copyTexture(texture, x, y, isFlashing()); }
    override public function onFireObject(args:Array) : CMLObject { return actManager.bullets.newInstance().init(args); }
    override public function onHit(act:Actor) : void {
        flagDamage = 6;
        if (life != 0) {
            life -= 1;
            if (life > 5) Particle.$(x, y, Math.random()*4-2, Math.random()*4-2, 0, 0.5, resManager.enemyColors[type]);
            if (life <= 0) {
                destroy(1);
                resManager.sionDriver.playSound((size>24)?1:3,1,0,0,1);
                scrManager.addScore(bonus * 10);
            }
        }
    }
    private function isFlashing() : int {
        return (flagDamage>0) ? (flagDamage&1) : 0;
    }
}

//--------------------------------------------------------------------------------
class Bullet extends Actor {
    public var texture:CMLMovieClipTexture;
    public var ac:int = 0, acmax:int = 0, acspd:int = 0;
    public var shape:int = 0;
    
    public function Bullet() { size = 4; }
    public function init(args:Array) : Bullet { 
        shape = args[0];
        texture = resManager.bulletTextures[shape];
        acspd = 1;
        life = 1;
        acmax = texture.animationCount << acspd;
        return this;
    }
    override public function onCreate() : void { ac = (shape<3) ? 0 : ((angleOnStage*0.08888888888888889+8.5)&15); }
    override public function onUpdate()       : void { if (shape<3 && ++ac==acmax) ac = 0; super.onUpdate(); }
    override public function onDraw()         : void { mc.copyTexture(texture, x, y, ac>>acspd); }
    override public function onFireObject(args:Array) : CMLObject { return actManager.bullets.newInstance().init(args); }
    override public function onHit(act:Actor) : void {
        var dx:Number = (vx < 0) ? -vx : vx, dy:Number = (vy < 0) ? -vy : vy,
            v:Number = (dx > dy) ? (dx + dy * 0.2928932188134524) : (dy + dx * 0.2928932188134524);
        life -= v * 0.0125;
        if (life <= 0) {
            destroy(1);
            resManager.sionDriver.playSound(4,1,0,0,4);
            dx = actManager.player.x - x;
            dy = actManager.player.y - y;
            v = 3 / Math.sqrt(dx*dx+dy*dy);
            Particle.$(x, y, -dx*v, -dy*v, dx*v*0.18, dy*v*0.18, 0, resManager.scoreTextures[scrManager.eat()]);
        }
    }
}

//--------------------------------------------------------------------------------
class Particle {
    public var x:Number, y:Number, vx:Number, vy:Number, ax:Number, ay:Number, color:uint, anim:int, tex:CMLMovieClipTexture, next:Particle;
    public function Particle(next_:Particle) { next = next_; }
    static private var _freeList:Particle = null, _particles:Array = [new Particle(null), new Particle(null)];
    static private var _width:Number, _height:Number, _rc:Rectangle = new Rectangle(0, 0, 4, 4);
    static public function initialize(particleMax:int) : void {
        for (var i:int=0; i<particleMax; i++) _freeList = new Particle(_freeList);
        _width = 450;
        _height = 450;
    }
    static public function reset() : void {
        var i:int, p:Particle;
        for (i=0; i<2; i++) {
            p = _particles[i].next;
            if (p) {
                while (p.next != null) p = p.next;
                p.next = _freeList;
                _freeList = _particles[i].next;
                _particles[i].next = null;
            }
        }
    }
    static public function update() : void {
        var p:Particle, prev:Particle;
        for (var i:int=0; i<2; i++) {
            prev = _particles[i];
            for (p = prev.next; p != null; p = p.next) {
                p.x += (p.vx += p.ax);
                p.y += (p.vy += p.ay);
                if (p.y>_height || ++p.anim == 16) {
                    prev.next = p.next;
                    p.next = _freeList;
                    _freeList = p;
                    p = prev;
                } else {
                    prev = p;
                }
            }
        }
    }
    static public function draw() : void {
        var p:Particle, screen:BitmapData = mc.screen;
        for (p = _particles[0].next; p != null; p = p.next) {
            _rc.x = p.x;
            _rc.y = p.y;
            screen.fillRect(_rc, p.color);
        }
        for (p = _particles[1].next; p != null; p = p.next) {
            mc.copyTexture(p.tex, p.x, p.y, (p.tex.animationCount>1)?p.anim:0);
        }
    }
    static public function $(x:Number, y:Number, vx:Number, vy:Number, ax:Number, ay:Number, color:uint, tex:CMLMovieClipTexture=null) : void {
        if (!_freeList) return;
        var newParticle:Particle = _freeList, list:Particle;
        _freeList = _freeList.next;
        if (tex) {
            newParticle.x = x;
            newParticle.y = y;
            newParticle.anim = 0;
            list = _particles[1];
        } else {
            newParticle.x = x + _width * 0.5;
            newParticle.y = y + _height * 0.5;
            newParticle.anim = -256;
            list = _particles[0];
        }
        newParticle.vx = vx;
        newParticle.vy = vy;
        newParticle.ax = ax;
        newParticle.ay = ay;
        newParticle.tex = tex;
        newParticle.color = color;
        newParticle.next = list.next;
        list.next = newParticle;
    }
}

// scripts --------------------------------------------------------------------------------
var cmlScript:String = String(<cml><![CDATA[
w60[[w60-$l*5&rungroup0l$r+=0.5]10w70];
#S1{@{^f-12[q-14f{vx-6a0.3,-1}q14f{vx8a-0.4,-1}w2q-14f{vx-2a0.1,-1}q14f{vx4a-0.2,-1}w2q-14f{vx-8a0.4,-1}q14f{vx6a-0.3,-1}w2q-14f{vx-4a0.2,-1}q14f{vx2a-0.1,-1}w2]}
^f12{ay-1}[ha0q-12fq0fq12fw2q-14fq0fq14fw2ha0q-12fq0fq12fw2q-10fq0fq10fw2]};
#S2{ha0[[bm4,30+$l*10f30w2]3[bm4,60-$l*10f30w2]3]};
#S3{ha0[[qx$l*10-30f30]7w2]};
#G0{qy-225[?$?<0.4qx-$?*150-25n{}qx$?*150+25n{}:qx$??*175n{}]&groupbonus0};
#G3{l$1=$i?(3)[?$1==2{qx-225[qy-160n{}w5]5}{qx225[qy-160n{}w5]5}:qx$1*450-225[qy-160n{}w5]10]&groupbonus200};
#G6{l$1=$i?(3)[?$1==2{qx-225[qy-$l*20n{}w5]5}{qx225[qy-$l*20n{}w5]5}:qx$1*450-225[qy-$l*15n{}w5]10]&groupbonus200};
#G7{l$1=$i?(3)[?$1==2{qx-225[qy-120+$l*20n{}w5]5}{qx225[qy-120+$l*20n{}w5]5}:qx$1*450-225[qy-120+$l*15n{}w5]10]&groupbonus200};
#G9{qy-225[s?$i?(5)[qx$??*200n{}w3]10:1[qx$l*40-180n{}w3]10:2[qx180-$l*40n{}w3]10:3[qx180-$l*40n{}qx$l*40-180n{}w3]5:4[qx20+$l*40n{}qx-$l*40-20n{}w3]5]&groupbonus200};
#G10{qy-225[s?$i?(3)[qx$l*40-180n{}w3]10:1[qx180-$l*40n{}w3]10:2[qx180-$l*40n{}qx$l*40-180n{}]10]&groupbonus200};
#G13{q175,-225[?$?<0.4n{}w15n{}:n{}]&groupbonus0};
#E0{20,100#T{[bm$2,$1,,2bm2,2f$3{3}w$2*2bm$2,-$1,,2bm2,2f$3{3}w]3}i20py-120~ha180[s?$r&T 160,8,6:35&T 160,8,7:70&T 160,9,8:105&T 160,10,8:140&T 140,10,10:180&T 140,10,12]ay0.1};
#E1{16,100#B{bm$1,360bm$2,15,5,1}i20py-120~ha$?*360[s?$r&B 12,12:40&B 12,14:70&B 14,14:110&B 16,14:140&B 18,14:190&B 20,14]f7{1}w60ay0.1};
#E2{20,100i20py-120~bs37,10,,1bm2,,0.2^f{2}ha90[s?$rf4:30[hs180f4.5]2f:60[hs120f5]3:90[hs90f5]4:130[hs88f5.5]4]w90ay0.1};
#E3{9,5{l$1=$sx*-12l$2=$sx*6[v$1,0w6v$2,10w9v$1,0w6v$2,-10w9]} br1,40[s?$rw70-$r*0.4f3{0}:110w25f3{0}:250w22br1,40bm2,3f4{0}]};
#E4{9,5^f{4}{[s?$r[w45-$r*0.3f6+$r*0.08]:70[w15f12]:100[w15f13.5]:130[w15f15]:190[w12ht$??*10f16]]}{[csa10w]}l$1=$sx*270l$2=$sx*-90[i0ha$1rcw10i45ha$2rc~]};
#E5{9,5vx$sx*-5ha180[s?$rbr1,30,2^f4{2}:30br1,40,2^f4{2}:55br1,30,2^f4{2}:80br2,30,2^f4{2}:105br2,30,3^f6{2}:140br2,60,4bm2,20^f7{2}:220br2,30,3bm2,,0.8^f10{5}][vy-8ay0.8w22f4]};
#E6{7,3{[s?$rw30bm2,80-$r*0.4f6{0}:100w30bm4,160-$r*0.4f6{0}:200:w8bm4,90f6{0}w22f12{3}]}v$sx*-24,0i45v$sx*8,4~ay-0.5};
#E7{7,3{w$?*40+10ha[s?$r[f4{1ay0.2+$r*0.003}w80-$r*0.4]:120ha$??*30[f4{1ay0.5}w25]:220bm2,30,2ha$??*20[f4{1ay0.6}w20]]}v,-4i60px$sx*-200v$sx*6,4~htad-0.3};
#E8{7,3{w20[s?$rbr$r*0.02+1,120,2,2f4+$r*0.03{2}:210br4,120,2,2bm2,,2f14{5}]}v$sx*-12,-8i60p$sx*120,0v$sx*-12,4~ay-0.5};
#E9{3,1^f{0}{ht$??*5ad1.2w14ad-1.2}[s?$rbm2,,1{w25-$r*0.3f6+$r*0.12}w25[w18-$r*0.1f6+$r*0.12+$l]:80w10bm3,,2f14{3}w15[w10f16+$l]:140w10bm4,,3f16{3}w15[w10f18+$l*2]]};
#E10{3,1^f{1}vy48i12vy0~ha$?*360[s?$rbm2+$r*0.03,360:230bm10,360]f$?*1.5+3w5ay-0.12[w20ha$?*360f]};
#E11{3,1[s?$rvy24:85vy32:175vy40]i8vy0~[s?$rbm3,,1:30bm3,,1.5:60bm2,360bm3,,1.5:125bm3,240bm3,,1.5:260bm3,40bm3,,1.5]f-8{5hoad0.6}w5ad1};
#E12{35,300i20py-120~[s?$rl$1=75l$2=6:25l$1=60l$2=7:50l$1=45l$2=8:70l$1=30l$2=9:90l$1=25l$2=10:150l$1=15l$2=10][i0vx$i?(2)*8-4i12vx~bm12,360f40{wbm2,$1f$2{0}ko}$1,$2w12]5ay1};
#E13{35,300i20py-120~{w25[s?$rbm4,270:40bm5,360:80bm5,288:120bm7,309][ht-24bv0.5f4{4}hs4[f]5bv-0.5[f]7w50]6}i50[px-175v~px175v~]3ay1};
#E14{35,300i20py-120~vy-0.25[ht-90f8{5hoad-0.5ht-30*$1f6{2}hs$r*0.04*$1[w4f]7ko}1w30ht90f8{.}-1w]3ay1};
]]></cml>);

// mml --------------------------------------------------------------------------------
var mmlMain:String = String(<mml><![CDATA[#TITLE{Nomltest main theme};t152;
#A=v12c4v6c8;#C=e.f.dc4d;#B=C>a1rg4.<c4.;#T=s28dd8ff8gg8aa8<crd8s24[>d<c>d<cd8]20>d<c>d<c;
#S=s20[dfgagf]8s28aa8<cc8dd8ff8s25grars20[[a8gfd8]s25a8a8]a8gfdefgfedc>a<c>agfgfededc>a<c>agfaf<c;
%1r1r1$[@4q1s24o6l8[r4A(5)A(4)A(0)A(2)v12>a<rr4A(5)A(4)A(7)A(5)v12cr]|
@2q2s22l4[d2r8ef2rgf2rgfedc|d2ref2rga2rgagfer8]d2ref2rga2r<cdc>agf8
@3q3s20l8B>f4.e2.r<Ca1rg4.a4.<c1rr>Bf4.e2.re.f.dc.d.>ag.<c.>ag.a.fd.f.ab-.<d.f(c+.e.g ar4.
@2q2s22f2.ef2.rgf4e4d4c4>a2.rfg2.fag2.fecde4f4g4a4<c+4d4e4.f2.ef2.rga4g4f4e4c2.r>fg2.fal4gfec.d.a.<d.q5a2.r8]4
@3q0s20l16S[>a<c>a<cd8>a<c>a<cd8erf8]3Td8d8;
#A=v8a4v4a8;#B=degfgea4degf<c4d4>degf;#C=l8a.a.fe4f;#D=v10q0s24a8a8r4v8q3s20;#E=d>a<cd4>a<cd4>a<cdfecl4dc>ag;
%1r1r1$[@4q1s24v8l8[r4AAAAv8gr|r4AAA(2)A(3)v8gr]
v4q0o4l16a<(cdega<(cdl32s28edgeag<(c>a<dcedgeag<(cd>(a<c>gaegdecd>))a<c>gal16s24edc>))agedc|
v8s20o5l8[aB<c4>a4gaegde|f4B<c4d4cd>a<c>gec]f4B<e4f4egdecd>a
q3o5Cd1rl4c.f.d.c.DC<d1rl4c.d.e2.>DCd1rl4c.f.a.g.Dl8a.a.fe.f.dc.e.ec.e.c>a.<c.df.a.<d>(g.a.<d(er4.
v8o6Efedcl8d4ced4ced4cfe4c>ga b-<l4cdefab-<c+l8c+Eagfel8d4ced4cfl4edc>a.b-.<g.b-.<q5g2.l8r]4
@1v6q0l16r8.S[>a<c>a<cd8>a<c>a<v12crdrv6erf]3Td;
#A=v8d4v4d8;#B=[aaeeffdd];
%1l8r1r1$[@4q1s24v8l8[r4AA(-2)AA(3)v8err4AA(-2)AA(7)v8er]|
@1q1s32o7v8l16B32[B4[ggddeecc]3v10q0s24>c8c8<v8q1s32aacc]3B[ggddeecc]
@4q0s20o4v6l8f.g.a<d.g.ad.g.b<d.e.g
@4q1s24o5v8[a4A(3)A(2)AA(-2)v8drr4A(3)A(2)A(-2)A(-5)v8>a<rr4A(-7)A(-9)A(-5)A(-7)|
>v8efgl4ab-<c+defgl8g]v8grs20>l4f.<d.g.q5<d2.l8r]4
@4q1s24o5v8l8[r4AA(-2)AA(3)v8err4AA(-2)AA(7)v8gr]5;
#A=dd<d>d<d>d<cd>;#B=>b-b-<b->b-<b->b-<ab-;#C=>g8.g<g8>g8rrgg<g8g8;#D=dd<d8>dr<d8>;#M=[A]3d<cd>a<cd>a<c>;
%1@2v10q0s30o3l16M$[[M]4|[[B]3>b-<ab->b-<ab-ab-[B(2)]3c-b<c>cb-<c>c<c>[M]]
q1s24[[C(3)][C(2)]]3CC(2)l8>b-.b-.<b->e-.e-.<e-l8e.e.eq0s26(a.((a.((l16aa
v10[[D]4[D(-4)]4[D(-7)][D(-5)]|[D(-4)][D(-5)]][D(1)]4]4
[[>b-b-<b->b-<b->b-<ab-][cc<c>c<c>cb-<c>][dd<d>d<d>d<cd>]4]5;
#B=o2v10c;#W=o2v6c;#S=o4v12c;#H=o6v6g;#F=o4v10c))c(c(c(c(c(c;
#A=BHHWSHHBr))c)cHSHHB;#C=BS))cWSr))ccBF;#D=BHHWSHBrHrB))cSHBr;
%2@0q0s29l16AC$[[A]7C|[[D]7C][BrHHo2v8crHHSrv6cHrrHHo2v10rrcHrro2v7crSr|v10cHrrgg]4
o4v6crc((c((c((c[BrHHSrHHrHB))cSo2v10rcHBrHo2v8cSrHHrHB))cSrHH]3
BrHo2v12crHo4v10cro2v12crHo2v12crHSv9cs28(c8.s28(c8.s27(c8 s26c8 s29o2v12rc o4v10c(c(c(c
[[A]6|S8c8Brs27S4c8s29Brs27o4v13c4c8s29Brs27o4v15c4c8s29Bro4v13c((c]AC]4
[D]7C[BHHWSHBrHrB))cSrcH]3S))cWS))cWS))cWS))cWSrv14s27c8s29[[D]3C];
]]></mml>);

var mmlGameOver:String = String(<mml><![CDATA[#TITLE{Nomltest gameover};t152;
%1@3v12o6q6s26l8r2e.f.dc.d.>ag.<c.>ag.a.fe1;%1@4v8o5q6s26l8r2b-.b-.b-g.g.gf.f.fe.e.e >a1;
%1@4v6 o5q6s26l2r2fed>b-<c1;%1@2v10o3q0s26l8r2g.g.ga.a.ab-.b-.b-<c.c.c q6s18d1;
%2@0q0s28l16r4o4v14cv12c((c((co2v12co6v8rgg o2v10co6v8rgg o4v14crv8c o6v8g o6v8rrgg o2v12rrc o6v8grr o2v10cr o4v14cr v12c o6v8grrggq2s20 o6v5g1;
]]></mml>);
