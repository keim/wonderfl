// forked from sakusan393's forked from: FTE（FlashTextEngine）を使ってみる on 2010-1-29
// forked from komatsu's FTE（FlashTextEngine）を使ってみる on 2010-1-29
// 
// 最も FlashTextEngine の真価が発揮される文章．
// 出典; http://beebee2see.appspot.com.nyud.net/d/agpiZWViZWUyc2VlchQLEgxJbWFnZUFuZFRleHQYweMgDA.jpg
// 勢いでやった．反省はしていない．
package {
	import flash.text.engine.TextLine;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.EastAsianJustifier;
	import flash.text.engine.LineJustification;
	import flash.text.engine.TextRotation;
    import flash.display.Sprite;
    import caurina.transitions.Tweener;
    public class main extends Sprite {
        public function main() {
           var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0x000000,0.1);
			sp.graphics.drawRect(0,0,465,400);
			sp.y = 32;
			addChild(sp);
            //表示したいテキスト
			var str:String = "　中学校での三年間は楽しい思い出ばかりでした。\n\n　特に書く事も見付からないので、好きな虫の話をしようと思う。蒼早苗（アオサナエ）というトンボがいる。空を飛ぶ姿はさながら星流のようで、とても美しい。オスもメスも共に頭部と胸部が翠玉石のように鮮やかな緑色をしている。その色彩から多種類との区別は容易に出来る。日本にいるトンボの中で最も美しい部類に入ると俺は思う。俺が初めてこのトンボを見たのは小学四年生の夏。長野のとある綺麗な川で美しく羽根を広げて飛ぶ２匹（多分オスとその嫁であろう）のトンボを見た。以来、俺は蒼早苗に獲り付かれた。\n\n　トンボの魅力の一つに、あの独特な飛び方がある。蝶や蜂等とは異なった飛び方、前にしか進まずに、後退しない飛び方。これは私論だが、だからこそトンボは美しいと感じるのだと思う。戦国武士は、決して退却しない飛び方をするトンボを、戦に勝てる縁起虫と認識して、武具の装備等にトンボ模様を好んで使用した。そんな厳めしく、神々しいトンボは、俺の憧れの存在だ。俺もトンボのような人間になりたい。そんな俺はいつもやる気だけがトンボ返りしている。";
			
			
			//フォント書式
			var fontDesc:FontDescription = new FontDescription();
			fontDesc.fontName = "ＭＳ 明朝";//"Kozuka Mincho Pro M";

			//エレメントのフォーマット
			var format:ElementFormat = new ElementFormat();
			format.locale = "ja";//テキストのロケール。jaだと日本語。
			format.fontSize=12; //18
			format.fontDescription = fontDesc;//FontDescription形式のデータを設定

			//テキストエレメントを作る
			var txtEle:TextElement = new TextElement(str , format);

			//テキストブロック
			var txtBlock:TextBlock = new TextBlock();
			txtBlock.textJustifier = new EastAsianJustifier("ja",LineJustification.UNJUSTIFIED);//ALL_BUT_LAST
			
			txtBlock.lineRotation = TextRotation.ROTATE_90;//縦書きにする
			txtBlock.content = txtEle;//テキストエレメントをコンテンツとして設定



			var txtW:uint = 365;//１行あたりのピクセル数にする予定
			var textLine:TextLine= txtBlock.createTextLine(null , txtW);
			var posX:uint = sp.width;//textLineのX座標用
			var posY:uint = 10;//textLineのY座標用
			var cnt:uint = 0;//各textLineの個別の条件を与えるための変数


			while(textLine != null){
				//TextLineオブジェクトを参照している、textLine
				//変数の参照粋ｫnullになるまで繰り返す。
				sp.addChild(textLine);
				cnt++;
				posX -= (textLine.width + 10);//12//textLineの幅＋マージン分、次座標を修正
				textLine.x = posX;
				textLine.y = posY+50;
				textLine.alpha = 0;
	
				Tweener.addTween(textLine , {y:posY , alpha:1  , time:0.5 ,delay:cnt/10, transition:"easeOutBack"});
	
				textLine = txtBlock.createTextLine(textLine , txtW);
				//現在のtextLineから、次のTextLineオブジェクトを参照
			}
            
            
            // マーカー
            var marker:Sprite = new Sprite();
            marker.graphics.beginFill(0xff0000,0.2);
            marker.graphics.drawRect(0,7,465,16);
            sp.addChild(marker);
            marker.alpha = 0;
            Tweener.addTween(marker, {alpha:1, time:8, delay:8, transition:"linear"});
        }
    }
}

