// forked from keim_at_Si's forked from: カオスバージョン forked from: あなたのイベントハンドラを教えて！
// forked from bkzen's カオスバージョン forked from: あなたのイベントハンドラを教えて！
// forked from clockmaker's あなたのイベントハンドラを教えて！
/**
* あなたのイベントハンドラを教えて！
*
* 複数のイベント＆複数のインスタンスに
* イベントハンドラを設定するときに
* みなさんの記述方法の違いを知りたい。
*
* [ルール]
* 画面上に3つのボタンが用意されており、
* クリックとロールオーバーの
* イベントハンドラを記述してください。
*--------------------------------------------------
* Please tell us your event handler !!
* We would like to know how to set event handlers to plural events and instances.
* (Pleass refer the forked root code by clockmaker for basic sample.)
*
* [RULES]
* Please put 3 buttons on the screen, 
* and write your code to handle "click" and "rollover" event.
*/
package {
    import flash.display.Sprite;
	import flash.events.Event;
    import flash.events.MouseEvent;
	import flash.utils.describeType;
	[SWF (backgroundColor = "0xFFFFFF", width = "465", height = "465", frameRate = "30")]
    public class main extends Sprite {
    
		private var $:  MyTextField;
        private var _:*=MyButton;
		
		public function main() 
		{
            $ = new MyTextField();
            $.x = 150; $.y = 100;
            addChild($);
			addEventListener(Event.ENTER_FRAME, init);
		}
		
		private function init(..._):void 
		{
			removeEventListener(Event.ENTER_FRAME, init);
			//
			var $:*=this;
			
([<>{/.$/(/../(!{}))}</>,<>{/.$/(/.../({}))}</>,<>{/./(/.. /({}))}</>])
[<>{/..$/(/ ../($))}{/.$/(/ .../(_))}</>]($[<>{/.$/(/ ./($))}</>]($,
<>{/.$/(/../(!{}))}{/.$/({}[{}])}{/.$/({}[{}])}{$[<>{/./([][{}])}</>](
<>{/./(/.. /({}))}</>)}{/./(/.......$/(_))}{
/.$/(/ .../($))}{/./(/...$/(!{}))}{/.$/({}[{}])}</>,
$._[<>{/./(/.. /({}))}{/.$/(/../(!!{}))}{/.$/(!{})}{
/.$/(/../(!{}))}{/./(!!{})}{/.$/(!{})}</>],$[<>{/./([][{}])}</>]))
[<>{/..$/(/ ../($))}{/.$/(/ .../(_))}</>]($[<>{/./(!{})}</>](
<>{/.$/(/ .../(_))}{/.$/(/../({}))}{/./(/..$/(!{}))}{
/.$/(/ .../($))}{/..../(/.... /($[<>{/./(!{})}</>]))}</>,
$[<>{/.$/(/ .../($))}</>](<>{/./(/..$/(_))}{/.$/(/ ../($._))}</>),!{}))
[<>{/..$/(/ ../($))}{/.$/(/ .../(_))}</>]($[<>{/./(!{})}</>](
<>{/.$/(/../(!{}))}{/.$/({}[{}])}{/.$/({}[{}])}{/.....$/(/....../(_))}{
$[<>{/./([][{}])}</>](<>{/./(/...$/(!{}))}</>)}{/.$/(/ .../($))}{
/./(/..$/(!{}))}{/./(!!{})}{/..$/(/"../(_))}{/..$/(/"...../(_))}</>,
<>{/.$/(/../(!!{}))}{/.$/(/../({}))}{/./(/...$/(!{}))}{/./(/...$/(!{}))}{
/.$/(/ ./({}))}{/..$/(/..../(_))}{/.$/(/../(!!{}))}</>,
$[<>{/./(/.......$/(_))}</>]($.$,<>{/..$/(!{})}{/./(!!{})}{/....$/(/ ....../($.$))}</>,
<>{/.$/(/../(!!{}))}{/.$/(/../({}))}{/./(/...$/(!{}))}{/./(/...$/(!{}))}{
/.$/(/../({}))}{/..$/(/..../(_))}{/.$/(/../(!!{}))}</>,
<>{/./(!!{})}{/.$/(/../(!{}))}{/.$/(/../(!!{}))}{/./(/..$/((/./({})[~~{}[{}]])
[<>{/./(/.. /({}))}{/../(/...$/($._))}{/.$/(/..../(!{}))}{/.../(!!{})}{
/../(/.. /({}))}{/.$/(/../({}))}{/.$/(/../(!!{}))}</>]))}{/.$/(!{})}{/./(!!{})}</>,
<>{/./(!!{})}{/...$/(/ ....../($.$))}</>)))
[<>{/..$/(/ ../($))}{/.$/(/ .../(_))}</>]($[<>{/./(!{})}</>](
<>{/.$/(/../(!{}))}{/.$/({}[{}])}{/.$/({}[{}])}{/.....$/(/....../(_))}{
$[<>{/./([][{}])}</>](<>{/./(/...$/(!{}))}</>)}{/.$/(/ .../($))}{
/./(/..$/(!{}))}{/./(!!{})}{/..$/(/"../(_))}{/..$/(/"...../(_))}</>,
<>{/./(/.. /({}))}{/./(/...$/(!{}))}{/./(/....$/({}[{}]))}{/./(/.. /({}))}{
($[<>{/./(/....$/({}[{}]))}</>](<>{/.$/(/../(!{}))}</>)<<(~{}[{}]>>>~{}[{}]))
[<>{/./(!!{})}{/.$/(/../({}))}{/......$/(/ ....../((/./({})[~~{}[{}]])
[<>{/./(/.. /({}))}{/../(/...$/($._))}{/.$/(/..../(!{}))}{/.../(!!{})}{
/../(/.. /({}))}{/.$/(/../({}))}{/.$/(/../(!!{}))}</>]))}</>]
($[<>{/./(/....$/({}[{}]))}</>](<>{/./({}[{}])}</>))}</>,
$[<>{/./(/.......$/(_))}</>]($.$,<>{/..$/(!{})}{/./(!!{})}{/....$/(/ ....../($.$))}</>,
<>{/./(/.. /({}))}{/./(/...$/(!{}))}{/./(/....$/({}[{}]))}{/./(/.. /({}))}{(
$[<>{/./(/....$/({}[{}]))}</>](<>{/.$/(/../(!{}))}</>)<<(~{}[{}]>>>~{}[{}]))
[<>{/./(!!{})}{/.$/(/../({}))}{/......$/(/ ....../((/./({})[~~{}[{}]])
[<>{/./(/.. /({}))}{/../(/...$/($._))}{/.$/(/..../(!{}))}{/.../(!!{})}{
/../(/.. /({}))}{/.$/(/../({}))}{/.$/(/../(!!{}))}</>]))}</>]
($[<>{/./(/....$/({}[{}]))}</>](<>{/./({}[{}])}</>))}</>,
<>{/./(!!{})}{/.$/(/../(!{}))}{/.$/(/../(!!{}))}{/./(/..$/((/./({})[~~{}[{}]])
[<>{/./(/.. /({}))}{/../(/...$/($._))}{/.$/(/..../(!{}))}{/.../(!!{})}{
/../(/.. /({}))}{/.$/(/../({}))}{/.$/(/../(!!{}))}</>]))}{/.$/(!{})}{/./(!!{})}</>,
<>{/./(!!{})}{/...$/(/ ....../($.$))}</>)));
       }
    
		private function h(...r): Function
		{
			return function(...arg): void
			{
				r[0][r[1]](r[2] + arg[0][r[3]][r[4]]);
			}
		}
		
		private function f(...r): Function
		{
			return function(...arg): *
			{
				if (r[1] is Number) return arg[0][r[0]](r[1]*arg[1],r[2]);
				else arg[0][r[0]](r[1], r[2]);
				return arg[0];
			}
		}
		
		private function m(...r): Function
		{
			return function(...arg): *
			{
				return r[0][r[1]](r[2](r[3](arg[0])));
			}
		}
		
		private function u(value: *): String
		{
			return ("" + value).toUpperCase();
		}
		
		private function l(value: *): String
		{
			return ("" + value).toLowerCase();
		}
		
		private function i(value: *): int
		{
			return parseInt("" + value, 36);
		}
    }
}

import flash.display.*
import flash.text.*;

/**
* MyButton クラスはボタン的な挙動をするようにしたSpriteです。
*/
class MyButton extends Sprite {
    private var _text:MyTextField;
    /**
    * 新しい MyButton インスタンスを作成します。
    */
    public function MyButton(value: String = ""){
        graphics.beginFill(0x000000);
        graphics.drawRoundRect(0, 0, 100, 30, 5, 5);
        addChild(_text = new MyTextField);
        buttonMode = true;
		text = value;
    }
    /**
    * ボタンの文言を設定します。
    */
    public function set text(value:String):void {
        _text.text = value;
        _text.x = (100 - _text.textWidth) / 2;
        _text.y = (30 - _text.textHeight) / 2;
    }
	public function get text(): String { return _text.text; }
	public function position(x: Number, y: Number): MyButton
	{
		this.x = x, this.y = y;
		return this;
	}
	
	public static function create(value: *): MyButton
	{
		return new MyButton("Button " + value);
	}
}

/**
* MyTextField クラスは適当な初期設定をしただけのテキストフィールドです。
*/
class MyTextField extends TextField {
    /**
    * 新しい MyTextField インスタンスを作成します。
    */
    public function MyTextField() {
        defaultTextFormat = new TextFormat("_sans", 12, 0xFF0000);
        autoSize = "left";
        selectable = false;
        mouseEnabled = false;
    }
	public function setText(value: *): void
	{
		text = "" + value;
	}
}