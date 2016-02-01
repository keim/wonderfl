// forked from uranodai's action_demo + type_demo
// 神速フォークで確認せざるを得なかった
// ラベル取得したら想像以上にアクションいっぱいだったんだけど，
// 何かインターナルな感じのとかあって，大丈夫かな．．． 
// front もあるなら back もあるのかなーと思ったら，やっぱりあった．
package
{
	import com.bit101.components.PushButton;
	import com.bit101.components.CheckBox;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.Security;
	
	[SWF(width="465",height="465",frameRate="24",backgroundColor="#FFFFFF")]
	
	public class action_demo extends Sprite
	{
		public var pets:*={};
		public var petsLoadingCount:int;
		public var _currentPetName:String;
		
		public var pet_btns:Vector.<PushButton> = new Vector.<PushButton>();
		public var act_btns:Vector.<PushButton> = new Vector.<PushButton>();
		public var front_check:CheckBox;
		
		public function action_demo()
		{
			petsLoadingCount = 0;
			loadPet("SHIBA", PetURL.SHIBA);
			loadPet("NEKO", PetURL.NEKO);
			loadPet("PANDA", PetURL.PANDA);
			loadPet("KAME", PetURL.KAME);
			loadPet("BOSTON", PetURL.BOSTON);
		}

		public function loadPet(name:String, url:String) : void 
		{
			with(addChild(pets[name] = new Pet(url))) {
				x = 230;
				y = 250;
				visible = false;
				onLoad = onLoaded;
			}
		}
		
		public function onLoaded() : void
		{
			if (++petsLoadingCount == 5) onLoadComplete();
		}
		
		public function onLoadComplete():void
		{
			var i:int, name:String;
			for (name in pets) {
				pet_btns.push(new PushButton(this, 20+(i&3)*110, 20+(i>>2)*30, name, onClickPet));
				i++;
			}
			for (i=0; i<32; i++) {
				act_btns.push(new PushButton(this, 20+(i&3)*110, 290+(i>>2)*21, "-----", onClickAct));
			}
			front_check = new CheckBox(this, 20, 80, "front", onFrontCheck);
			front_check.selected = true;
			currentPetName = "BOSTON";
		}
		
		public function onClickAct(e:Event) : void {
			pets[_currentPetName].playAction(PushButton(e.currentTarget).label);
		}
		
		public function onClickPet(e:Event) : void {
			currentPetName = PushButton(e.currentTarget).label;
		}
		
		public function onFrontCheck(e:Event) : void {
			pets[_currentPetName].isFront = front_check.selected;
		}
		
		public function set currentPetName(name:String) : void {
			var pet:Pet;
			for each (pet in pets) pet.visible = false;
			if (name in pets) {
				_currentPetName = name;
				pet = pets[name];
				pet.visible = true;
				for (var i:int=0; i<pet.sceneNames.length; i++) {
					act_btns[i].label = pet.sceneNames[i];
					act_btns[i].visible = true;
				}
				for (; i<32; i++) {
					act_btns[i].visible = false;
				}
				front_check.selected = pet.isFront;
			}
		}
	}
}

import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.FrameLabel;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;

class Pet extends Sprite
{
	public var sceneNames:Array = [];
	public var onLoad:Function;
	private var coreMovieClip:MovieClip;
	private var current:MovieClip;
	private var urlLoader:URLLoader;
	private var loader:Loader;
	private var _isFront:Boolean;
	
	public function Pet(url:String)
	{
		urlLoader = new URLLoader();
		urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		urlLoader.addEventListener(Event.COMPLETE, onLoad1);
		urlLoader.load(new URLRequest(url));	
		_isFront = false;
	}
	
	private function onLoad1(e:Event):void
	{
		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoad2);
		loader.loadBytes(urlLoader.data);
	}
	
	private function onLoad2(e:Event):void
	{
		var clazz:Class = loader.contentLoaderInfo.applicationDomain.getDefinition("Pet") as Class;
		coreMovieClip = new clazz();
		coreMovieClip.front.y = coreMovieClip.front.x = 0;
		coreMovieClip.back.y = coreMovieClip.back.x = 0;
		isFront = true;
		for each (var l:FrameLabel in current.currentLabels) {
			sceneNames.push(l.name);
		}
		if(onLoad != null) onLoad();
	}
	
	public function playAction(code:String):void
	{
		current.gotoAndPlay(code);
	}
	
	public function get isFront() : Boolean {
		return _isFront;
	}
	
	public function set isFront(f:Boolean) : void {
		if (_isFront != f) {
			_isFront = f;
			if (current) removeChild(current);
			current = (_isFront) ? coreMovieClip.front : coreMovieClip.back;
			addChild(current);
		}
	}
}

class PetURL
{
	public static var SHIBA:String = "http://stat.ameba.net/training2010/shiba.swf";
	public static var NEKO:String = "http://stat.ameba.net/training2010/neko.swf";
	public static var PANDA:String = "http://stat.ameba.net/training2010/panda.swf";
	public static var KAME:String = "http://stat.ameba.net/training2010/kame.swf";
	public static var BOSTON:String = "http://stat.ameba.net/training2010/boston.swf";
}