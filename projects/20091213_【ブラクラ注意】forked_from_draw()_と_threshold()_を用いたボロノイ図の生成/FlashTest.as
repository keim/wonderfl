// forked from keim_at_Si's draw() と threshold() を用いたボロノイ図の生成
// forked from Nao_u's jump floodingアルゴリズムを用いたボロノイ図の生成
//
// 【ブラクラ注意】
// 100点 X 4倍精度 テスト with ボトルネック解析
// 
package {      
    import flash.display.Sprite;      
    import flash.events.*;      
    [SWF(width="465", height="465", backgroundColor="0xFFFFFF", frameRate="30")] 
         
    public class FlashTest extends Sprite {      
        public function FlashTest() {      
            Main = this;      
            initialize();      
            stage.addEventListener(Event.ENTER_FRAME,update);       
        }      
    }      
}          
    
   
import flash.display.Sprite;       
import flash.events.* 
import flash.geom.*; 
import flash.utils.getTimer; 
import frocessing.color.ColorHSV;
import org.si.utils.timer;
var Main:Sprite;      
var SCREEN_W:Number = 465; 
var SCREEN_H:Number = 465; 

var Tex:ProcTex; 
var BITMAP_W:int = 232; 
var BITMAP_H:int = 232; 
var Pnt:Vector.<ControlPoint> = new Vector.<ControlPoint>; 

// 初期化
function initialize():void{      
    Tex = new ProcTex( BITMAP_W, BITMAP_H ); 
    Tex.Bmp.x = 0; 
    Tex.Bmp.y = 0; 
     
    // 制御点の設置
    for (var i:int=0; i<100; i++) {
        newControlPoint(Math.random()*465, Math.random()*465);
    }

    timer.initialize(Main, 10, "total:##ms", "copyChannel:##ms", "draw(darken):##ms", "draw(diff):##ms", "threshold:##ms");
    timer.title = "Timers";

    // create new control point
    function newControlPoint(x:Number, y:Number) : void {
        Pnt.push(new ControlPoint(new Point(x, y)));
        Pnt[Pnt.length-1].color = new ColorHSV(Math.random()*360, 0.5, 1).value32;
    }
}

// 更新
function update(e :Event):void{      
    Tex.draw(); 
    for each (var cp:ControlPoint in Pnt) cp.move();
}   

import flash.display.Bitmap;  
import flash.display.BitmapData;  

// テクスチャ生成クラス
class ProcTex{ 
    public var BmpData:BitmapData;  
    public var TmpBmpData:BitmapData;  
    public var Bmp:Bitmap; 
    public var Width:int; 
    public var Height:int; 
    
    private var _distanceBuffer:BitmapData;
    
    public function ProcTex( w:int, h:int ){ 
        Width = w; 
        Height = h; 
        BmpData = new BitmapData(Width, Height, false, 0xffffff);  
        TmpBmpData = new BitmapData(Width, Height/3+1, false, 0xffffff);
        Bmp = new Bitmap(BmpData);  
        Bmp.scaleX = 465/Width;  //7.25*0.5;
        Bmp.scaleY = 465/Height; //7.25*0.5;
        Bmp.x = 232.5-Bmp.scaleX*Width*0.5;  // = 0.0;
        Bmp.y = 232.5-Bmp.scaleY*Height*0.5; // = 0.0;
        Main.addChild(Bmp);       

        _createDistanceMap();
    }

    public function draw():void{ 
        drawBmpData( BmpData ); 
    } 

    public function drawBmpData( bmpData:BitmapData ):void{ 
        var i:int, cp:ControlPoint, 
            dy:int = Height/3,
            iScaleX:Number = 1/Bmp.scaleX,
            iScaleY:Number = 1/Bmp.scaleY;
        bmpData.lock();
        TmpBmpData.lock();
        _distanceBuffer.lock();

        timer.start(0);
        _distanceBuffer.fillRect(_distanceBuffer.rect, 0xffffff);
        for each (cp in Pnt) {
            _pt.x = (cp.Sp.x - Bmp.x) * iScaleX - Width;
            _pt.y = (cp.Sp.y - Bmp.y) * iScaleY - Width;
            timer.start(1);
            TmpBmpData.fillRect(TmpBmpData.rect, 0xffffff);
            for (i=1; i<8; i<<=1, _pt.y-=dy) {
                TmpBmpData.copyChannel(_distanceMap, _distanceMap.rect, _pt, 4, i);
            }
            timer.pause(1);
            timer.start(2);
            _distanceBuffer.draw(TmpBmpData, null, null, "darken");
            timer.pause(2);
            timer.start(3);
            TmpBmpData.draw(_distanceBuffer, null, null, "difference");
            timer.pause(3);
            timer.start(4);
            for (i=0xff0000, _pt.x=_pt.y=0; i>0; i>>=8, _pt.y+=dy) {
                bmpData.threshold(TmpBmpData, TmpBmpData.rect, _pt, "==", 0, cp.color, i);
            }
            timer.pause(4);
        }
        timer.pause(0);
        
        bmpData.unlock();
        TmpBmpData.unlock();
        _distanceBuffer.unlock();
    }

    private var _pt:Point = new Point(); // for general purpose
    private var _rc:Rectangle = new Rectangle(); // for general purpose
    private var _distanceMap:BitmapData;
    private function _createDistanceMap() : void {
        var r:Number = 512/Width;
        _distanceBuffer = TmpBmpData.clone();
        _distanceMap = new BitmapData(Width*2, Width*2, false);
        for (var x:int=-Width; x<Width; x++)
        for (var y:int=-Width; y<Width; y++) {
            var dist:int = int(Math.sqrt(x*x+y*y)*r);
            _distanceMap.setPixel(x+Width, y+Width, (dist<255)?dist:255);
        }
    }
}

// 制御点マーカークラス
class ControlPoint{  
    public var Sp:Sprite;  
    public var isEnable:Boolean = false; 
    public var Pos:Point; 
    public var color:uint;
    public function ControlPoint( p:Point ){  
        Sp=new Sprite();    
        Pos = p;  
        Sp.x = Pos.x;  
        Sp.y = Pos.y; 
        Sp.buttonMode = true;
        setEnable( true ); 
        Main.addChild(Sp);   

        _vel = new Point(Math.random()*8-4, Math.random()*8-4);
        Sp.addEventListener(MouseEvent.MOUSE_UP,   function (event:MouseEvent):void{ Sp.stopDrag(); });  
        Sp.addEventListener(MouseEvent.MOUSE_DOWN, function (event:MouseEvent):void{ if( isEnable ) Sp.startDrag(); });      
    }  

    public function setEnable( flg:Boolean ):void{     
        if( flg == true && isEnable == false ){ 
            Sp.graphics.clear(); 
            Sp.graphics.lineStyle(1.4,0x000000);        
            Sp.graphics.beginFill(0xe0d000,1);    
            Sp.graphics.drawCircle(0,0,2.0);    
            Sp.graphics.endFill();    
        }else if( flg == false && isEnable == true ){ 
            Sp.graphics.clear(); 
        } 
        isEnable = flg; 
    } 
    
    private var _vel:Point;
    public function move() : void {
        Sp.x += _vel.x;
        Sp.y += _vel.y;
        if (Sp.x<0 || Sp.x>465) {
            _vel.x = -_vel.x;
            Sp.x += _vel.x;
        }
        if (Sp.y<0 || Sp.y>465) {
            _vel.y = -_vel.y;
            Sp.y += _vel.y;
        }
    }
}  
