// forked from Nao_u's jump floodingアルゴリズムを用いたボロノイ図の生成
//
// BitmapData.draw() と BitmapData.threshold() を用いたボロノイ図の生成
//
// 制御点をドラッグで移動
//
// http://wonderfl.net/code/13a64427311b17680c2743a08610096d461a354e
// 点の数が処理負荷は単純比例．GPU実装は容易，というか Z-buffer だけで実装できる
// ↑のは，同じアルゴリズムで 逆に Z-buffer "を" 実装した例
//
// とりあえず，10点くらいなら超速キレイだけど，多点は厳しいかも．
// Z-buffer 実装に応用するには，今のところ合成処理がネックで重い．
//
package {      
    import flash.display.Sprite;      
    import flash.events.*;      
    [SWF(width="465", height="465", backgroundColor="0xFFFFFF", frameRate="15")] 
         
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
import flash.text.TextField;      
import flash.geom.*; 
import flash.utils.getTimer; 
import frocessing.color.ColorHSV;
var Main:Sprite;      
var SCREEN_W:Number = 465; 
var SCREEN_H:Number = 465; 
var Text:TextField     
var Text2:TextField     

var Tex:ProcTex; 
var BITMAP_W:int = 128; 
var BITMAP_H:int = 128; 
var Pnt:Vector.<ControlPoint> = new Vector.<ControlPoint>; 

// 初期化
function initialize():void{      
    Tex = new ProcTex( BITMAP_W, BITMAP_H ); 
    Tex.Bmp.x = 0; 
    Tex.Bmp.y = 0; 
     
    Text = new TextField();      
    Text.text = "生成中...";    
    Text.autoSize = "left"; 
    Main.addChild(Text);       

    Text2 = new TextField();      
    Text2.text = "";    
    Text2.autoSize = "left"; 
    Text2.y = 16; 
    Main.addChild(Text2);       

    // 制御点の設置
    newControlPoint(SCREEN_W/2-70,  SCREEN_H/2+40);
    newControlPoint(SCREEN_W/2-150, SCREEN_H/2-120);
    newControlPoint(SCREEN_W/2+0,   SCREEN_H/2-50);
    newControlPoint(SCREEN_W/2+140, SCREEN_H/2-130);
    newControlPoint(SCREEN_W/2+100, SCREEN_H/2+120);
    newControlPoint(SCREEN_W/2-140, SCREEN_H/2+140);
    newControlPoint(SCREEN_W/2+10,  SCREEN_H/2+180);
    newControlPoint(SCREEN_W/2-40,  SCREEN_H/2-180);
    newControlPoint(SCREEN_W/2-140, SCREEN_H/2-10);
    newControlPoint(SCREEN_W/2+140, SCREEN_H/2-10);

    // create new control point
    function newControlPoint(x:Number, y:Number) : void {
        Pnt.push(new ControlPoint(new Point(x, y)));
        Pnt[Pnt.length-1].color = new ColorHSV(Pnt.length*36-18, 0.5, 1).value32;
    }
}

// 更新
function update(e :Event):void{      
    var time:int = getTimer();  
        
    Tex.draw(); 

    var endTime:int = getTimer() - time; 
    Text.text = " 生成時間：" + endTime + "[ms]";    
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
        
        _distanceBuffer.fillRect(_distanceBuffer.rect, 0xffffff);
        for each (cp in Pnt) {
            _pt.x = (cp.Sp.x - Bmp.x) * iScaleX - Width;
            _pt.y = (cp.Sp.y - Bmp.y) * iScaleY - Width;
            TmpBmpData.fillRect(TmpBmpData.rect, 0xffffff);
            for (i=1; i<8; i<<=1, _pt.y-=dy) {
                TmpBmpData.copyChannel(_distanceMap, _distanceMap.rect, _pt, 4, i);
            }
            _distanceBuffer.draw(TmpBmpData, null, null, "darken");
            TmpBmpData.draw(_distanceBuffer, null, null, "difference");
            for (i=0xff0000, _pt.x=_pt.y=0; i>0; i>>=8, _pt.y+=dy) {
                bmpData.threshold(TmpBmpData, TmpBmpData.rect, _pt, "==", 0, cp.color, i);
            }
        }
        
        bmpData.unlock();
        TmpBmpData.unlock();
        _distanceBuffer.unlock();
    }

    private var _pt:Point = new Point(); // for general purpose
    private var _distanceMap:BitmapData;
    private function _createDistanceMap() : void {
        var r:Number = 255*1.414/Width;
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
        Main.stage.addChild(Sp);   

        Sp.addEventListener(MouseEvent.MOUSE_UP,   function (event:MouseEvent):void{ Sp.stopDrag(); });  
        Sp.addEventListener(MouseEvent.MOUSE_DOWN, function (event:MouseEvent):void{ if( isEnable ) Sp.startDrag(); });      
    }  

    public function setEnable( flg:Boolean ):void{     
        if( flg == true && isEnable == false ){ 
            Sp.graphics.clear(); 
            Sp.graphics.lineStyle(1.4,0x000000);        
            Sp.graphics.beginFill(0xe0d000,1);    
            Sp.graphics.drawCircle(0,0,8.0);    
            Sp.graphics.endFill();    
        }else if( flg == false && isEnable == true ){ 
            Sp.graphics.clear(); 
        } 
        isEnable = flg; 
    } 
}  
