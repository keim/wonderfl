// forked from bkzen's こするボタン
// なんの問題もありません．
package 
{
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.net.*;
	import flash.utils.*;
	import org.libspark.betweenas3.*;
	import com.bit101.components.*;

	/**
	 * ...
	 * こするぼたん
	 * こすった後に Click が効くようになる。
	 * @author jc at bk-zen.com
	 */
	public class RubButtonTest extends Sprite
	{
		private var txt: TextField;
		private var btn: RubButton;
		private var col: uint = 0xCCCCCC;
		private var shape:Shape = new Shape();

		public function RubButtonTest() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e: Event = null): void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//
			btn = new RubButton("こするボタン", "Complete！", 150, 30);
			btn.addEventListener(Event.COMPLETE, onComp);
			btn.x = (stage.stageWidth - btn.width) / 2;
			btn.y = (stage.stageHeight - btn.height) / 2;
			btn.addEventListener(MouseEvent.CLICK, onClick);
			addChild(btn);
			graphics.clear();
			graphics.beginFill(0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			shape.graphics.beginFill(0xffffff);
			shape.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			shape.alpha = 0;
			addChild(shape);
		}
		
		private function onClick(e: MouseEvent): void 
		{
		}
		
		private function onComp(e: Event): void 
		{
			BetweenAS3.tween(shape, {alpha:0}, {alpha:1}, 5).play();
			BetweenAS3.tween(btn, {rotation:45}, {rotation:-90}, 8).play();
			new PushButton(this, 200, 420, "tweet score", function(e:Event):void {
				var url: String = "http://twitter.com/home/?status=";
				url += escapeMultiByte("こするげーむ Time:") + btn.time;
				url += " http://wonderfl.net/code/9d18ad12d3ffe51bca012d969762c2551fe32257"
				navigateToURL(new URLRequest(url), "_blank");
			});
		}
		
	}

}
import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Dictionary;
import flash.utils.*;
import flash.display.*;
class RubButton extends Sprite
{
	private var _w: Number;
	private var _h: Number;
	private var _first: String;
	private var _complete: String;
	private var _label: TextField;
	private var _labelBitmap: Bitmap;
	private var percent: Number;
	private var invalid: Boolean;
	private var tf: TextFormat;
	private var clickEvents: Array = [];
	private var clickEventsDict: Dictionary = new Dictionary(true);
	private var _labelFirst: BitmapData;
	private var _labelComp: BitmapData;
	private var startTime:int = 0;
        public var time:String = "";
	
	function RubButton(first: String, complete: String, w: Number, h: Number)
	{
		_first = first;
		_complete = complete;
		_w = w;
		_h = h;
		_label = new TextField();
		_label.width = _label.height = 1000;
		_label.autoSize = TextFieldAutoSize.LEFT;
		_label.mouseEnabled = _label.selectable = false;
		tf = _label.getTextFormat();
		tf.bold = true;
		tf.color = 0x464E6A;
		_label.setTextFormat(tf);
		_label.text = _first;
		_labelFirst = new BitmapData(_label.width, _label.height, true);
		_labelFirst.draw(_label);
		_labelBitmap = new Bitmap(_labelFirst)
		_labelBitmap.x = (_w - _label.width) / 2;
		_labelBitmap.y = (_h - _label.height) / 2;
                _labelBitmap.smoothing = true;
		addChild(_labelBitmap);
		invalid = false;
		percent = 0;
		draw();
		buttonMode = true;
		addEventListener(Event.ENTER_FRAME, check);
		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		rotation = 45;
	}
	
	private function onDown(e: MouseEvent): void 
	{
		removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
		addEventListener(MouseEvent.MOUSE_UP, onUp);
		addEventListener(MouseEvent.MOUSE_MOVE, onMove);
		if (startTime == 0) startTime = getTimer();
	}
	
	private function onUp(e: MouseEvent): void 
	{
		removeEventListener(MouseEvent.MOUSE_UP, onUp);
		removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
	}
	
	private function onMove(e: MouseEvent): void 
	{
		if (percent >= 100) 
		{
			percent = 100;
			var t:int = getTimer() - startTime;
			time = String(t*0.001).substring(0,5) + "[sec]";

			_label.text = "Your Time : " + time;
			_labelComp = new BitmapData(_label.width, _label.height, true);
			_labelComp.draw(_label);
			_labelBitmap.bitmapData = _labelComp;
			_labelBitmap.x = (_w - _labelComp.width) / 2;
			_labelBitmap.y = (_h - _labelComp.height) / 2;
			_labelBitmap.smoothing = true;
		} else {
    			percent += 0.2;
                }
		invalid = false;
	}
	
	override public function get width(): Number { return _w; }
	
	override public function set width(value: Number): void 
	{
		if (_w == value) return;
		_w = value;
		invalid = false;
	}
	
	override public function get height(): Number { return _h; }
	
	override public function set height(value: Number): void 
	{
		if (_h == value) return;
		_h = value;
		invalid = false;
	}
	
	private function draw():void
	{
		var g: Graphics = graphics;
		g.clear();
		g.beginFill(0x3399CC);
		g.drawRect(0, 0, _w, _h);
		g.beginFill(0xFFFFFF);
		g.drawRect(1, 1, _w - 2, _h - 2);
		if (percent > 0)
		{
			//g.beginFill(0x33CCCC);
			var m: Matrix = new Matrix(), w: Number = (_w - 6) * percent / 100, h: Number = _h - 6,
			    color:int = ((int(153-percent*1.53)+51)*0x101) | ((int(percent*1.53)+51)<<16);
			g.beginFill(color);
			g.drawRect(3, 3, w, h);
			m.createGradientBox(w, h / 2, 90 * Math.PI / 180, 3, 3);
			g.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [0.8, 0.3], [0x00, 0xFF], m);
			g.drawRect(3, 3, w, h / 2);
			rotation = -percent*1.35+45;
			if (percent == 100)
			{
				removeEventListener(Event.ENTER_FRAME, check);
				dispatchEvent(new Event(Event.COMPLETE));
				while (clickEvents.length)
				{
					var listener: Function = clickEvents.pop();
					addEventListener.apply(null, clickEventsDict[listener]);
					delete clickEventsDict[listener];
				}
			}
		}
		invalid = true;
	}
	
	private function check(e: Event): void 
	{
		if (invalid) return;
		draw();
	}
	
	override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false): void 
	{
		if (percent < 100 && type == MouseEvent.CLICK && clickEvents.indexOf(listener) < 0) 
		{
			clickEvents.push(listener);
			clickEventsDict[listener] = [type, listener, useCapture, priority, useWeakReference];
		}
		else 
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
	}
	
	override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false): void 
	{
		var i: int;
		if ((i = clickEvents.indexOf(listener)) >= 0)
		{
			clickEvents.splice(i, 1);
			delete clickEventsDict[listener]
		}
		super.removeEventListener(type, listener, useCapture);
	}
}