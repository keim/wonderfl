// forked from o8que's 朝青龍ゲーム
// リール回転＋モーションブラー
/* -------------------------------------------------------------------
 * いきおいで作ってしまった。反省はしていない。
 * 
 * [inspired by]
 * 昼青龍「朝青龍がやられたようだな・・・」:アルファルファモザイク
 * http://alfalfalfa.com/archives/384861.html
 * -------------------------------------------------------------------
 * [遊び方]
 * 真ん中のボタンをクリックして朝青龍を完成させてください。
 * （完成しても何も起きませんが、気持ちいいと思います）
 * -------------------------------------------------------------------
 * [いじりどころ]
 * SLOT_TEXTの中身を変えるだけで自分だけのスロットマシーンを作れます。
 * -------------------------------------------------------------------
 */
package {
	import com.bit101.components.PushButton;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class MorningBlueDragon extends Sprite {
		public static const SLOT_NUM:int = 3;
		public static const SLOT_SIZE:int = 140;
		private static const SLOT_TEXT:Array = 
		[["朝", "昼", "夕", "夜"],
		 ["青", "白", "朱", "玄"],
		 ["龍", "虎", "雀", "武"]];
		private var _slots:Array;
		private var _stopped:int;
		
		public function MorningBlueDragon() {
			_slots = [];
			for (var i:int = 0; i < SLOT_NUM; i++) {
				var slot:Slot = new Slot((i * SLOT_SIZE) + 10, 10);
				slot.setTextList(SLOT_TEXT[i]);
				_slots.push(slot);
				addChild(slot);
			}
			new PushButton(this, SLOT_SIZE + 30, SLOT_SIZE + 20, "click!", clickButton);
			addEventListener(Event.ENTER_FRAME, update);
		}
		
		private function clickButton(e:Event):void {
			if (_stopped == 3) for (var i:int=0; i<SLOT_NUM; i++) _slots[i].roll = true;
			else _slots[_stopped].roll = false;
		}
		
		private function update(e:Event):void {
			_stopped = 0;
			for (var i:int=0; i<SLOT_NUM; i++) _stopped += _slots[i].update();
		}
	}
}

import flash.display.*;
import flash.filters.*;
import flash.events.*;
import flash.geom.*;
import flash.text.*;

class Slot extends Sprite {
	public var roll:Boolean;
	private var _list:Vector.<BitmapData> = new Vector.<BitmapData>();
	private var _screen:BitmapData;
	private var _index:Number, _vel:Number;
	private var _pt:Point = new Point(0, 0);
	private var _blur:BlurFilter = new BlurFilter(1, 16);
	
	public function Slot(posx:int, posy:int) {
		var size:int = MorningBlueDragon.SLOT_SIZE;
		x = posx;
		y = posy;
		buttonMode = true;
		graphics.lineStyle(2, 0x808080);
		graphics.drawRect(0,0,size,size);
		addChild(new Bitmap(_screen = new BitmapData(size, size, false, 0xffffff)));
		addEventListener("click", function(e:Event) : void { roll = false; } );
		_index = 0;
		_vel = 0;
		roll =	false;
	}
	
	public function setTextList(texts:Array):void {
		var tf:TextField = new TextField();
		tf.defaultTextFormat = new TextFormat(null, _screen.width);
		tf.width = tf.height = _screen.width;
		_list.length = texts.length;
		for (var i:int=0; i<texts.length; i++) {
			tf.text = texts[i];
			_list[i] = new BitmapData(_screen.width, _screen.height, true, 0);
			_list[i].draw(tf, null, new ColorTransform(1,1,1,0.4,(i==0)?255:0));
		}
	}
	
	public function update() : int {
		var i0:int, i1:int, i:int;
		_screen.fillRect(_screen.rect, 0xffffff);
		for (i=0; i<6; i++) {
			i0 = int(_index);
			i1 = (i0+1) % _list.length;
			_pt.y = (_index - i0) * _screen.height;
			_screen.copyPixels(_list[i0], _screen.rect, _pt);
			_pt.y -= _screen.height;
			_screen.copyPixels(_list[i1], _screen.rect, _pt);
			_index += _vel;
			if (_index >= _list.length) _index -= _list.length;
			_vel += (roll) ? 0.001 : -0.01;
			if (_vel > 0.05) _vel = 0.05;
			else if (_vel < 0) {
				_vel = 0;
				_index = int(_index+0.5) % _list.length;
			}
		}
		if (_vel > 0.03) _screen.applyFilter(_screen, _screen.rect, _screen.rect.topLeft, _blur);
		return (roll) ? 0 : 1;
	}
}
