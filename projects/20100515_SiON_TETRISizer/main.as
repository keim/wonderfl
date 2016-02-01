//-------------------------------------------------------------------------------- 
//  TETRISiON ～ もし水口哲也がテトリスを作ったら
//-------------------------------------------------------------------------------- 
//  < controls >
//     move;[Left]-[Right]/  drop;[Down]/  hard-drop;[Up]/  L-turn;[Z]/  R-turn;[X]
//     swap;[C] = Swap current block and stocked block.
//  < special rules >
//     1) The level increases by 1 erasing.
//     2) The game is finished at level 32.
//     3) The field has only 8 rows.
//     4) You can erase lines with "chain combo".
//     5) You can stock 1 block and swap it wherever.
//     6) The bonus is doubled over level 24.
//     7) [bonus] = ([erased line count]^2 + [chain combo count]^2) * 100
//  < notice >
//     This flash uses cookie to keep hi-score.
//     If you do not want, please press "CLEAR COOKIE" button.
//-------------------------------------------------------------------------------- 

package {
    import flash.net.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.display.*;
    import flash.filters.GlowFilter;
    import flash.utils.escapeMultiByte;
    import frocessing.color.FColor;
    import frocessing.math.FMath;
    import org.libspark.betweenas3.BetweenAS3;
    import org.libspark.betweenas3.tweens.ITween;
    import com.bit101.components.*;
    import org.si.sion.events.*;
	import net.wonderfl.score.basic.*;
    
    public class main extends Sprite {
        private var sion:SiON, pv3d:PV3D;
        private var screen:BitmapData = new BitmapData(465,465,false), canvas:Shape = new Shape(), g:Graphics = canvas.graphics;
        private var blockTextures:Vector.<BitmapData> = new Vector.<BitmapData>(7, true), dropBlock:BitmapData = new BitmapData(200, 200, true); 
        private var scoreLabel:Label, levelLabel:Label, linesLabel:Label, msgb:Label, msgw:Label, msgs:Label, bsf:BasicScoreForm, bsrv:BasicScoreRecordViewer;
        private var msgbd:BitmapData = new BitmapData(200, 80, true, 0), mmat:Matrix=new Matrix(3,0,0,3), msg:Bitmap, messageTween:ITween;
        private var smat:Matrix=new Matrix(1.04,0,0,1.04,-4.65,-9.3), scolt:ColorTransform=new ColorTransform();
        private var idField:Vector.<uint>=new Vector.<uint>(200), stockID:uint, nextID:uint, dropID:uint;
        private var dropX:int, dropY:int, dropR:int, drawX:Number, drawY:Number, drawR:Number, speed:Number;
        private var frameCount:int, phase:int, score:int, level:int, lines:int, bestResult:*;
        private var pt:Point=new Point(), rc:Rectangle = new Rectangle(), mat:Matrix = new Matrix();
        private var keyPushed:int, keyPressed:int, slideCount:int;
        private var delLineFlag:int, delLines:int, delChains:int, lineBrghtness:Number, scaleEffect:int;
        private var tetromino:Array = [
            Vector.<int>([0x0660, 0x0660, 0x0660, 0x0660, 4]), Vector.<int>([0x2222, 0x0f00, 0x4444, 0x00f0, 4]),
            Vector.<int>([0x0622, 0x0740, 0x4460, 0x02e0, 4]), Vector.<int>([0x0264, 0x0063, 0x0132, 0x0630, 3]), 
            Vector.<int>([0x0644, 0x0470, 0x2260, 0x0e20, 4]), Vector.<int>([0x0462, 0x0036, 0x0231, 0x0360, 3]),
            Vector.<int>([0x0262, 0x0072, 0x0232, 0x0270, 3])
        ];
        public var backcolor:int; // controled by betweenas3
        
    //---------------------------------------- main
        function main() : void {
            pv3d = new PV3D();
            sion = new SiON(_onBeat, _onNoteOn);
            addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
            addEventListener(Event.ENTER_FRAME, _onEnterFrame);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
        }
        
    //---------------------------------------- handlers
        private function _onAddedToStage(e:Event) : void {
            stage.frameRate = 30;
            Style.LABEL_TEXT = 0x808080;
            Style.BUTTON_FACE = 0x404040;
            Style.PANEL = 0x404040;
            //Style.BACKGROUND
            addChild(new Bitmap(screen));
            _effectButton(225, 444).setSize(78, 18);
            _scoreButton(305, 444).setSize(78, 18);
            _tweetButton(385, 444).setSize(78, 18);
            _resetButton(2, 444).setSize(78, 18);
            new Label(this, 261,  32, "NEXT");
            new Label(this, 261, 182, "STOCK");
            levelLabel = _status(257, 322, "LEVEL :");
            scoreLabel = _status(257, 362, "SCORE :");
            linesLabel = _status(257, 402, "LINES :");
            msgs = new Label(this, 64, 260, ""); 
            msgs.scaleX = msgs.scaleY = 1.5;
            msgs.visible = false;
            msgs.filters = [new GlowFilter(0, 0.6, 2, 2)];
            Style.LABEL_TEXT = 0x404040; msgb = new Label(null, 64, 200, "");
            Style.LABEL_TEXT = 0xc0c0c0; msgw = new Label(null, 64, 200, "");
            addChild(msg = new Bitmap(msgbd));
            msg.x = 32;
            msg.alpha = 0;
            phase = TITLE;
            _loadCookie();
            _initialize();
            _startTitle();
        }
        
        private function _onEnterFrame(e:Event) : void {
            _drawBackground();
            phaseMain[phase]();
            _drawField();
            keyPushed = 0;
            lineBrghtness *= 0.9;
            ++frameCount;
        }
        
        private function _onKeyDown(e:KeyboardEvent) : void { keyPressed = keyPushed = e.keyCode; }
        private function _onKeyUp(e:KeyboardEvent) : void { keyPressed = 0; }
        
    //---------------------------------------- SiON events
        private function _onBeat(e:SiONTrackEvent) : void {
            lineBrghtness = 1;
            pv3d.tick();
        }
        
        private function _onNoteOn(e:SiONTrackEvent) : void {
            if (e.eventTriggerID == 1) _whiteOut();
        }
        
    //---------------------------------------- UI
        private function _status(x:Number, y:Number, label:String) : Label {
            var inst:Label = new Label(this, x, y, label);
            inst.scaleX = inst.scaleY = 2;
            inst = new Label(this, x+90, y, "");
            inst.scaleX = inst.scaleY = 2;
            return inst;
        }
        
        private function _resetButton(x:Number, y:Number) : PushButton {
            return new PushButton(this, x, y, "CLEAR COOKIE", function(e:Event) : void {
                var so:SharedObject = SharedObject.getLocal("savedData");
                if (so) so.clear();
                bestResult = {"score":0, "level":0, "lines":0};
                if (phase == TITLE) {
                    lines = level = score = 0;
                    _updateStatus();
                }
            });
        }
        
        private function _effectButton(x:Number, y:Number) : PushButton {
            return new PushButton(this, x, y, "EFFECT ON", function(e:Event) : void {
                e.target.label = _swapEffect() ? "EFFECT ON" : "EFFECT OFF";
            });
        }
        
        private function _scoreButton(x:Number, y:Number) : PushButton { return new PushButton(this, x, y, "SHOW RANKING", __showRanking); }
        private function __showRanking(e:Event) : void { new BasicScoreRecordViewer(this, 122.5, 112.5,'RANKING', 30, true); }
        
        private function _tweetButton(x:Number, y:Number) : PushButton {
            return new PushButton(this, x, y, "TWEET SCORE", function(e:Event) : void {
                navigateToURL(new URLRequest("http://twitter.com/home/?status=" + escapeMultiByte("[SiON TETRISizer] score:" + String(score) + " http://wonderfl.net/c/f5eX/ #TETRISizer")), "_blank");
            });
        }

    //---------------------------------------- drawings
        private function _drawBackground() : void {
            g.clear();
            var col:int = backcolor * 0x10101;
            if (scaleEffect > 0) {
                smat.tx = -4.65-scaleEffect*2+25;
                scolt.alphaMultiplier = ((scaleEffect>12) ? (25-scaleEffect) : scaleEffect)*0.04;
                screen.draw(screen, smat, scolt);
                --scaleEffect;
                g.beginFill(col, 0.1);
            } else g.beginFill(col, 0.25);
            g.drawRect(0, 0, 465, 465);
            g.endFill();
            if (backcolor > 0) {
                g.beginFill(0x000000, backcolor * 0.001953125);
                g.drawRect(32,  32, 200, 400);
                g.endFill();
            }
            pv3d.update();
            screen.draw(pv3d);
            col = (int(lineBrghtness*63))*0x20304;
            __drawVoidRect( 32,  32, 200, 400, col);
            __drawVoidRect(257,  32, 125, 125, col);
            __drawVoidRect(257, 182, 125, 125, col);
            screen.draw(canvas);
        }
        
        private function _drawField() : void {
            var dx:int, dy:int, x:int, y:int, f:int, id:uint, b:int, col:int;
            b = tetromino[col = (nextID & 7) - 1][dropR];
            dy = tetromino[col][4] * 12.5;
            for (f=1, y=0; y<4; y++) for (x=0; x<4; x++, f<<=1) if (b & f) __drawBlock(screen, col, x * 25 + 319.5 - dy, y * 25 + 94.5 - dy);
            col = (stockID & 7) - 1;
            b = tetromino[col][dropR];
            dy = tetromino[col][4] * 12.5;
            for (f=1, y=0; y<4; y++) for (x=0; x<4; x++, f<<=1) if (b & f) __drawBlock(screen, col, x * 25 + 319.5 - dy, y * 25 + 244.5 - dy);
            if (phase == MOVE) {
                dy = tetromino[(dropID & 7) - 1][4] * 12.5;
                mat.identity();
                mat.translate(-dy, -dy);
                mat.rotate(-drawR * 1.5707963267948965);
                mat.translate((drawX - 1) * 25 + dy + 32, (drawY - 1) * 25 + dy + 32);
                screen.draw(dropBlock, mat);
            }
            col = (int(lineBrghtness*63))*0x20304;
            for (y=0; y<16; y++) for (x=0; x<8; x++) {
                id = idField[y*10+x+31];
                __drawBlock(screen, (id & 7) - 1, dx = x * 25 + 32, dy = y * 25 + 32);
                if (id != idField[y*10+x+21] ) __drawRect(dx-1, dy-1, 27, 3, col);
                if (id != idField[y*10+x+30])  __drawRect(dx-1, dy-1, 3, 27, col);
            }
        }
        
        private function _updateDropBlock() : void {
            var x:int, y:int, f:int, col:int = (dropID&7)-1, b:int = tetromino[col][dropR];
            dropBlock.fillRect(dropBlock.rect, 0);
            for (f=1, y=0; y<4; y++) for (x=0; x<4; x++, f<<=1) if (b & f) __drawBlock(dropBlock, col, x * 25, y * 25);
        }
        
        private function __drawBlock(bd:BitmapData, col:int, dx:Number, dy:Number) : void {
            if (col == -1) return;
            pt.x = dx; pt.y = dy;
            bd.copyPixels(blockTextures[col], blockTextures[col].rect, pt);
        }
        
        private function __drawVoidRect(x:Number, y:Number, w:Number, h:Number, col:int) : void {
            __drawRect(x-1, y-1, w+2, 3, col);
            __drawRect(x-1, y-1, 3, h+2, col);
            __drawRect(x+1, y+h-1, w, 3, col);
            __drawRect(x+w-1, y+1, 3, h, col);
        }
        
        private function __drawRect(x:Number, y:Number, w:Number, h:Number, col:int) : void {
            rc.x = x; rc.y = y; rc.width = w; rc.height = h;
            screen.fillRect(rc, col);
        }
        
    //---------------------------------------- texts
        private function _updateStatus() : void {
            scoreLabel.text = ("0000000000"+String(score)).substr(-8, 8);
            levelLabel.text = ("0"+String(level)).substr(-2, 2) + "/32";
            linesLabel.text = ("00"+String(lines)).substr(-3, 3);
        }
        
        private function _message(text:String, subText:String=null, smallText:String=null) : void {
            msgbd.fillRect(msgbd.rect, 0);
            $(text, 0);
            if (subText) $(subText, 32);
            msg.y = (smallText) ? 160 : 200;
            if (messageTween && messageTween.isPlaying) messageTween.stop();
            messageTween = BetweenAS3.to(msg, {"alpha":1}, 0.3);
            messageTween.play();
            if (msgs.visible = (smallText != null)) {
                msgs.text = smallText;
                msgs.draw();
                msgs.x = 132 - msgs.width * 0.75;
                msgs.y = 280;
            }
            function $(text:String, y:Number) : void {
                msgb.text = msgw.text = text;
                msgb.draw();
                msgw.draw();
                var w:Number = msgw.width * 1.5;
                _(msgb, 103 - w, y);
                _(msgb,  97 - w, y);
                _(msgb, 100 - w, y - 3);
                _(msgb, 100 - w, y + 3);
                _(msgw, 100 - w, y);
                function _(l:Label, x:Number, y:Number) : void {
                    mmat.tx = x;
                    mmat.ty = y;
                    msgbd.draw(l, mmat);
                }
            }
        }
        
        private function _messageOff() : void {
            msgs.visible = false;
            if (messageTween && messageTween.isPlaying) messageTween.stop();
            messageTween = BetweenAS3.to(msg, {"alpha":0}, 0.3);
            messageTween.play();
        }
        
    //---------------------------------------- motions
        private function _slideAndRotate(dx:int, r:int) : void {
            if (_check(dx+dropX, dropY, (dropR + r) & 3) && (dropY-drawY<0.3 || _check(dx+dropX, dropY-1, (dropR + r) & 3))) {
                dropX += dx;
                dropR = (dropR + r) & 3;
                if (r != 0) _updateDropBlock()
            }
        }
        
        private function _stack() : void {
            var x:int, y:int, f:int, b:int = tetromino[(dropID&7)-1][dropR];
            for (f=1, y=0; y<4; y++) for (x=0; x<4; x++, f<<=1) if (b & f) idField[(y+dropY-1)*10+x+dropX+30] = dropID;
            sion.se(0);
            _changePhase(DELETE);
        }
        
    //---------------------------------------- evaluations
        private function _check(x_:int, y_:int, r_:int) : Boolean {
            var x:int, y:int, f:int, b:int = tetromino[(dropID&7)-1][r_];
            for (f=1, y=0; y<4; y++) for (x=0; x<4; x++, f<<=1) if ((b & f) && idField[(y+y_-1)*10+x+x_+30] != 0) return false;
            return true;
        }
        
        private function _checkLine() : int {
            var x:int, y:int;
            for (delLineFlag=0, y=0; y<16; y++) {
                for (x=0; x<8; x++) if (idField[y*10+x+31] == 0) break;
                if (x == 8) delLineFlag |= 1<<y;
            }
            return delLineFlag;
        }
        
        private function _dropLine() : Boolean {
            var x:int, y:int, ret:Boolean=false;
            for (y=15; y>=0; y--) for (x=0; x<8; x++) if (__checkDropBlock(y*10+x+31)) idField[y*10+x+31] |= 0x80000000;
            for (y=15; y>=0; y--) for (x=0; x<8; x++) if (idField[y*10+x+31] & 0x80000000) {
                idField[y*10+x+41] = idField[y*10+x+31] & 0x7fffffff;
                idField[y*10+x+31] = 0;
                ret = true;
            }
            return ret;
        }
        
        private function __checkDropBlock(idx:int) : Boolean {
            if (idField[idx] == 0) return false;
            var id:uint = idField[idx], ret:Boolean;
            idField[idx] |= 0x80000000;
            ret = ((idField[idx+10] == 0 || idField[idx+10] == idField[idx]) && 
                   (idField[idx-1]  != id || __checkDropBlock(idx-1)) && 
                   (idField[idx+1]  != id || __checkDropBlock(idx+1)) && 
                   ((id&7) == 1 || idField[idx-10] != id || __checkDropBlock(idx-10)));
            idField[idx] &= 0x7fffffff;
            return ret;
        }
        
    //---------------------------------------- procedures
        private function _loadCookie() : void {
            var so:SharedObject = SharedObject.getLocal("savedData");
            bestResult = (so && "bestResult" in so.data) ? (so.data.bestResult) : {"score":0, "level":0, "lines":0};
        }
        
        private function _initialize() : void {
            var i:int;
            for (i=0; i<200; i++) idField[i] = (i%10==0 || i%10==9 || i<10 || i>=190) ? 0xfffffff8 : 0;
            FMath.randomSeed(uint(new Date().getTime()));
            nextID = FMath.random(8, 1) + 16;
            stockID = FMath.random(8, 1) + 8;
            lines = level = score = 0;
            lineBrghtness = 1;
            scaleEffect = 0;
            backcolor = 0;
            __createTexture();
            _updateStatus();
        }
        
        private function __createTexture() : void {
            for (var i:int=0; i<7; i++) {
                mat.createGradientBox(25, 25, 0.7853981633974483, 0, 0);
                g.clear();
                g.beginGradientFill("linear", [FColor.HSVtoValue(45*i,0.25,1), FColor.HSVtoValue(45*i,0.75,0.75)], [0.375, 0.375], [0, 255], mat);
                g.drawRect(0, 0, 25, 25);
                blockTextures[i] = new BitmapData(25, 25, true, 0);
                blockTextures[i].draw(canvas);
            }
        }
        
        private function _nextBlock() : void {
            dropID = nextID;
            nextID = ((nextID & 0x7ffffff8) + 8) | FMath.random(8, 1);
            _updateDropBlock();
            dropX = drawX = 3;
            dropY = drawY = 0;
            speed = level * 0.01 - int(level/8) * 0.06 + 0.01;
            slideCount = 0;
            if (!_check(dropX, dropY, dropR)) _changePhase(GAMEOVER);
        }
        
        private function _flipBlock() : void {
            var id:uint = dropID;
            dropID = stockID;
            if (_check(dropX, dropY, dropR)) {
                stockID = id;
                _updateDropBlock();
            } else dropID = id;
            sion.se(0);
        }
        
        private function _swapEffect() : Boolean {
            _effect = !_effect;
            if (!_effect) pv3d.filters = null;
            return _effect;
        }
        
        private function _whiteOut() : void { BetweenAS3.to(this, {"backcolor":255}, 60/132*8).play(); }
        private function _blackOut() : void { BetweenAS3.to(this, {"backcolor":0}, 1.5).play(); }
        
    //---------------------------------------- phases
        private var TITLE:int=0, INTRO:int=1, MOVE:int=2, DELETE:int=3, GAMEOVER:int=4, CLEAR:int=5, RESULT:int=6, nextPhase:int = -1;
        private var phaseStart:Array = [_startTitle, _startIntro, _startMove, _startDelete, _startGameover, _startClear,    _startResult];
        private var phaseMain:Array  = [_phaseTitle, _phaseIntro, _phaseMove, _phaseDelete, _returnToTitle, _returnToTitle, _doNothing];
        private var phaseEnd:Array   = [_endTitle,   _endIntro,   _endMove,   _doNothing,   _doNothing,     _doNothing,     _doNothing];
        private function _doNothing() : void {}
        
        private function _changePhase(p:int) : void {
            if (nextPhase == -1) {
                nextPhase = p;
                phaseEnd[phase]();
                frameCount = 0;
                keyPushed = 0;
                do {
                    phase = nextPhase
                    phaseStart[phase]();
                } while (phase != nextPhase);
                nextPhase = -1;
            } else {
                nextPhase = p;
            }
        }
        
    //---------------------------------------- TITLE phase
        private function _startTitle() : void {
            sion.start();
            score = bestResult.score;
            level = bestResult.level;
            lines = bestResult.lines;
            _updateStatus();
            _message("TETRISizer", null, "Press any key to start");
        }
        private function _phaseTitle() : void { if (keyPushed) _changePhase(INTRO); }
        private function _endTitle() : void { _initialize(); }
        
    //---------------------------------------- INTRO phase
        private function _startIntro() : void { _message("? Ready ?"); }
        private function _phaseIntro() : void {
            if (frameCount == 36) _message("! Go !");
            else if (frameCount == 72) _changePhase(MOVE);
        }
        private function _endIntro() : void { _messageOff(); }
        
    //---------------------------------------- MOVE phase
        private function _startMove() : void { _nextBlock(); }
        private function _phaseMove() : void {
            drawY += (keyPressed==40) ? 0.5 : speed;
            var y:int = int(drawY + 0.9999847412109375);
            if (y != dropY) {
                if (_check(dropX, dropY+1, dropR)) dropY = y;
                else {
                    drawY = dropY = y - 1;
                    slideCount += (keyPressed==40) ? 10 : 1;
                    if (slideCount>30) _stack();
                }
            }
            if (keyPushed == 67) _flipBlock();
            else if (keyPushed == 38) {
                while(_check(dropX, dropY+1, dropR)) dropY++;
                score += 30-dropY;
                _updateStatus();
                _stack();
            } else if (keyPushed) {
                drawR = dropR;
                _slideAndRotate(int(keyPushed==39)-int(keyPushed==37), int(keyPushed==90)-int(keyPushed==88));
                drawR -= dropR;
                if (drawR == 3) drawR = -1;
                else if (drawR == -3) drawR = 1;
                sion.se(keyPushed, dropX*16-56);
            }
            drawX += (dropX - drawX) * 0.6;
            drawR *= 0.5;
        }
        private function _endMove() : void { delChains = delLines = 0; }
        
    //---------------------------------------- DELETE phase
        private function _startDelete() : void {
            if (_checkLine()) {
                for (var y:int=0; y<16; y++) if (delLineFlag & (1<<y)) {
                    delLines++;
                    for (var x:int=0; x<8; x++) idField[y*10+x+31] = 0;
                }
                delChains++;
                if (_effect) scaleEffect = 25;
                _message("! "+String(delLines)+" Lines !", String(delChains)+" Combo");
                sion.se(1, 0, 8, 4);
            } else {
                if (delLines > 0) {
                    score += (delLines * delLines + delChains * delChains) * ((level>23) ? 200 : 100);
                    lines += delLines;
                    sion.measure = ++level;
                    pv3d.measure = level;
                    _updateStatus();
                }
                _messageOff();
                if (level == 32) _changePhase(CLEAR);
                else _changePhase(MOVE);
            }
        }
        
        private function _phaseDelete() : void {
            if (frameCount < 16) for (var y:int=0; y<16; y++) if (delLineFlag & (1<<y)) {
                g.clear();
                g.beginFill(0xffffff, frameCount*0.0625);
                g.drawRect(32, y*25+32, 200, 25);
                screen.draw(canvas);
            }
            if (frameCount > 12 && !_dropLine()) _changePhase(DELETE);
        }
        
    //---------------------------------------- GAMEOVER phase
        private function _startGameover() : void {
            _blackOut();
            sion.end();
            pv3d.end();
            _message("GAME OVER", null, "Press any key");
        }
        
    //---------------------------------------- CLEAR phase
        private function _startClear() : void {
            _blackOut();
            sion.end();
            pv3d.end();
            _message("! FINISH !", null, "Press any key");
        }
        private function _returnToTitle() : void { if (frameCount>30 && keyPushed) _changePhase(RESULT); }
        
    //---------------------------------------- RESULT phase
        private function _startResult() : void {
            if (score > bestResult.score) {
                _messageOff();
                bestResult = {"score":score, "level":level, "lines":lines};
                var so:SharedObject = SharedObject.getLocal("savedData");
                if (so) {
                    so.data.bestResult = bestResult;
                    so.flush();
                }
                bsf = new BasicScoreForm(this, 92.5, 152.5, score, 'HI SCORE !', _onCloseBSF);
                bsf.onCloseClick = _onCloseBSF;
            } else _changePhase(TITLE);
        }
        
        private function _onCloseBSF(succeeded:Boolean=false) : void {
            if (bsf != null) removeChild(bsf);
            bsrv = new BasicScoreRecordViewer(this, 122.5, 112.5,'RANKING', 30, true, _onCloseBSRV);
            bsf = null;
        }
        
        private function _onCloseBSRV() : void {
            if (bsrv != null) removeChild(bsrv);
            bsrv = null;
            _changePhase(TITLE);
        }
    }
}



//---------------------------------------- global variables
var _effect:Boolean = true;


//---------------------------------------- SiON
import org.si.sion.*;
import org.si.sion.events.*;
import org.si.sion.effector.*;
import org.si.sion.sequencer.*;
import org.si.sound.*;
import org.si.sound.synthesizers.*;

class SiON extends SiONDriver {
    private var bs:BassSequencer = new BassSequencer("o3C", 15);
    private var dm:DrumMachine = new DrumMachine(0,0,0,2,2,2);
    private var back:SiONData, fill:SiONData, fill2:SiONData;
    private var analogSynth:AnalogSynth = new AnalogSynth();

    function SiON(onBeat:Function, onNoteOn:Function) : void {
        super();
        setVoice(0, new SiONVoice(5,2,63,63,-10,0,2,20));
        back = compile("#EFFECT1{delay312,30,1};%5@0,40@v64,32q1s24$o6b-r2.;");
        fill = compile("#A=o7[crgrfrcrgrfcrgfr];r1^1%6@0l16@v32,16q8$A(7)A(5);%2@f0,2,16q8s20@0,10%t1,1,0c1^1^8;%2q0s32l16v4[cc(]16;@v128%5@5q0s32,-128o3$c;");//)
        fill2= compile("#A=o7[drargrdrargaragr];%6@0l16@v16,8q8$AA");
        bpm = 132;
        setSamplerData(0, render("%2@v128q0s32o4g16"));
        setSamplerData(1, render("#A=%6@0q0s20o3c*<<<g;A;kt7A"));
        setSamplerData(37, render("%6@0o7q8l64cb-f"));
        setSamplerData(39, render("%6@0o7q8l64gcd"));
        setSamplerData(88, render("%6@0o4q8l32g*<<g"));
        setSamplerData(90, render("%6@0o4q8l32f*<<f"));
        addEventListener(SiONTrackEvent.BEAT, onBeat);
        addEventListener(SiONTrackEvent.NOTE_ON_FRAME, onNoteOn);
        addEventListener(SiONEvent.STREAM_STOP, _onStreamStop);
        dm.volume = 0.6;
        bs.synthesizer = analogSynth;
        bs.volume = 0.4;
        analogSynth.setVCAEnvelop(0,   0.3, 0.7, 0.2);
        analogSynth.setVCFEnvelop(0.4, 0.3, 0.1, 0.6, 0.7);
    }

    public function set measure(m:int) : void {
        switch (m) {
        case 1: dm.bass.mute = false; break;
        case 4: dm.hihat.mute = false; break;
        case 8: bs.mute = false; bs.fadeIn(16); break;
        case 10: bpm = 105; break;
        case 12: bpm = 110; analogSynth.setVCFEnvelop(0.45, 0.3, 0.1, 0.6, 0.75); break; 
        case 14: bpm = 115; analogSynth.setVCFEnvelop(0.5,  0.3, 0.1, 0.6, 0.8);  break;
        case 16: bpm = 120; analogSynth.setVCFEnvelop(0.55, 0.3, 0.1, 0.6, 0.85); break;
        case 18: bpm = 125; analogSynth.setVCFEnvelop(0.6,  0.3, 0.1, 0.6, 0.85); break;
        case 20: bpm = 132; dm.snare.mute = false; dm.hihatPatternNumber = 2; break;
        case 24: sequenceOn(fill, null, 0, 0, 16); break;
        case 28: sequenceOn(fill2, null, 0, 0, 16); break;
        }
    }

    public function start() : void {
        bpm = 100;
        fadeIn(4);
        play(back);
        dm.snarePatternNumber = 0;
        dm.hihatPatternNumber = 13;
        dm.snare.mute = true;
        dm.hihat.mute = true;
        dm.bass.mute = true;
        bs.mute = true;
        dm.play();
        bs.play();
    }
    
    public function end() : void {
        fadeOut(4);
    }
    
    public function se(i:int, pan:int=0, len:int=0, qnt:int=1) : void {
        var t:SiMMLTrack = playSound(i, len, 0, qnt);
        t.effectSend1 = 32;
        t.pan = pan;
    }
    
    private function _onStreamStop(e:SiONEvent) : void {
        bs.stop();
        dm.stop();
    }
}


//---------------------------------------- PV3D
import flash.events.Event;
import flash.filters.GlowFilter;
import org.libspark.betweenas3.BetweenAS3;
import org.libspark.betweenas3.tweens.ITween;
import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
import org.papervision3d.materials.utils.MaterialsList;
import org.papervision3d.lights.PointLight3D;
import org.papervision3d.objects.primitives.Cube;
import org.papervision3d.view.BasicView;
import org.papervision3d.core.math.Number3D;
import org.papervision3d.core.geom.renderables.*;

class PV3D extends BasicView {
    public var light:PointLight3D = new PointLight3D(), scale:Number, glows:Array = []; 
    public var cube:Cube = new Cube(new MaterialsList({all:new FlatShadeMaterial(light, 0x203040, 0x000000)}),60,60,60,3,3,3);
    public var nvs:Vector.<Number3D> = new Vector.<Number3D>(cube.geometry.vertices.length);
    public var cbs:Vector.<Number3D> = new Vector.<Number3D>(cube.geometry.vertices.length);
    public var s:Vector.<Number> = new Vector.<Number>(cube.geometry.vertices.length);
    public var omegaX:Number=0.2, omegaY:Number=0.4, omegaZ:Number=0.7, omegaTween:ITween=null;
    
    function PV3D() {
        glows.push(new GlowFilter(0x405080,1,4,4));
        glows.push(new GlowFilter(0x405080,1,8,8));
        glows.push(new GlowFilter(0x405080,1,16,16));
        glows.push(new GlowFilter(0x405080,1,32,32));
        super(465, 465);
        scene.addChild(cube);
        scale = 1;
        for (var i:int=0; i<nvs.length; i++) {
            var v:Vertex3D = cube.geometry.vertices[i];
            cbs[i] = new Number3D(v.x, v.y, v.z);
            nvs[i] = new Number3D(v.x, v.y, v.z);
            nvs[i].normalize();
            s[i] = 1;
        }
    }
    
    public function update() : void {
        cube.scale += (scale - cube.scale) * 0.05;
        cube.rotationX += omegaX;
        cube.rotationY += omegaY;
        cube.rotationZ += omegaZ;
        for (var i:int=0; i<nvs.length; i++) {
            var n:Number3D = nvs[i], c:Number3D = cbs[i], v:Vertex3D = cube.geometry.vertices[i], r:Number = s[i];
            v.x = n.x * r + c.x;
            v.y = n.y * r + c.y;
            v.z = n.z * r + c.z;
            s[i] += (1 - r) * 0.12;
        }
        for each(var f:Triangle3D in cube.geometry.faces) f.createNormal();
        singleRender();
    }
    
    public function end() : void {
        if (omegaTween && omegaTween.isPlaying) omegaTween.stop();
        omegaTween = BetweenAS3.to(this, {"omegaX":0.2 ,"omegaY":0.4 ,"omegaZ":0.7}, 2);
        omegaTween.play();
        scale = 1;
        filters = null;
    }
    
    public function tick() : void {
        for (var i:int=0; i<s.length; i++) s[i] += Math.random() * 6 * (scale - 1);
    }
    
    public function set measure(m:int) : void {
        scale = 1 + m*0.2;
        if (_effect && (m&7)==1) filters = [glows[m>>3]];
        if (omegaTween && omegaTween.isPlaying) omegaTween.stop();
        omegaTween = BetweenAS3.to(this, {"omegaX":$() ,"omegaY":$() ,"omegaZ":$()}, 4);
        omegaTween.play();
        function $():Number { return (Math.random() - 0.5) * scale; }
    }
}


