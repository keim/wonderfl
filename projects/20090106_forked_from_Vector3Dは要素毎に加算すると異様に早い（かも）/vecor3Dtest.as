// forked from umhr's Vector3Dは要素毎に加算すると異様に早い（かも）
// forked from umhr's Array,Vector,Vector3D速度比較
/**
同じ長さ、値のArray,Vector,Vector3Dをaddと同じ処理を100万回実行した時の処理時間（ミリ/秒）
その２
MacBookPro2.4Gh,OSX 10.5.6
Array0:348//前回と同じ
Array1:320//決め打
Vector0:85//前回と同じ
Vector1:80//決め打
Vector3D0:623//前回と同じ
Vector3D1:17//要素毎に加算
Vector3D2:656//addの代わりの関数を作った
Vector3D3:625//addの代わりの関数を作った2
null:6//Vector3Dをnewしてforでまわすだけ。

Vector3Dを要素毎に加算すると異様に早い。
けど、早すぎてちょっと信じられない感じ。
いろいろ検証が必要。

add以外にもいろいろ試してみるといいかも。


--------------------------------------------------------
<fork元より>
->Array が Vector より非常に遅いのは，たぶん確定．
->関数呼出 と new が非常に遅いのも，たぶん確定．
->ループによるインデックス呼出とループ展開ではあまり差が無い可能性（×確定）．

<Vector3D0とVector3D1について>
->メンバアクセスよりインデックスアクセスの方が遅い？
  （クラス宣言による固定インデックスでのアクセスの方が，変数インデックスでのアクセスより最適化しやすい
   ->確かこれってAS3のAdobeの発表資料に書いてあった気がするな．未確認）
->ローカルで確保したVectorとVector3Dのメモリ空間の違い？
  （_v0c:Vectorはヒープ，_v3c:Vector3Dはスタック上に確保される形で最適化されてる可能性
   ->関数の外で参照されないインスタンスをスタック上に展開するのは割と良くある最適化手法．）
->VectorとVector3Dでキャッシュヒット率が違う
  （一般論．VectorもVector3Dも整然と固まってるだろうし，ループで回す分には同じ気がするけど．．．
   ->というか，fork元のルーチンだと同じ位置に100万回アクセスしてるので，今回の差には影響してないはず）
->素直に１００万個のVector x 3で計算すれば良いんだけどめんどい

<仮定の検証（下記ルーチンは計算順序を変えて複数回実行）>
1)Vector2:普通はスタックエリアに確保されるローカル変数を使用して計算
2)Vector3:スタックエリアに確保されてる可能性のある_v3c:Vector3Dで計算
->同程度高速化．
  ->メンバアクセスよりインデックスアクセスの方が遅い．メンバアクセスとローカル変数アクセスは同程度．
  ->Vector3D1の _v3c:Vector3D は new していてもスタックエリアに確保されている.
3)Vector4:普通はヒープエリアに確保されてる_v3d:Vector3Dを定義して計算
->やっぱり同程度高速化．ただし，たまに少し遅い事がある．．．なんだこりゃ???
  ->でもとりあえず，メモリ空間は関係ないっぽい？
->ただし，どの場合でもVector3D1には及ばない．
  ->やっぱりメンバアクセスよりインデックスアクセスの方が遅いとな？
  ->というか，Vector.<Vector3D>とVector.<Number>で比較しないと条件同じじゃない．
    (それでもインデックスアクセスの回数が1/3になるので多少は早くなるはず）．
->やっぱり素直に１００万個のVector x 3で計算すれば良いんだけどめんどい

<暫定>
メンバアクセスの方がインデックスアクセスより速い/最適化されている．っぽい．
ローカル変数アクセスとローカルインスタンスのメンバアクセスは同程度．っぽい．
今回の極端な高速化は，Vector3D1でその遅いインデックスアクセスが0回だったため．っぽい．
実際は，Vector.<Vector3D>で使うだろうから，インデックスアクセスが0回ってのは有り得ないような．
->結局，素直に１００万個のVector x 3で計算すれば良いんだけどめんどい．
*/

package {
	import flash.display.Sprite;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	public class vecor3Dtest extends Sprite {
		public var _a0a:Array =new Array(0.1,1.2,2.3);
		public var _a0b:Array =new Array(10,20,30);
		public var _v3a:Vector3D=new Vector3D(0.1,1.2,2.3);
		public var _v3b:Vector3D=new Vector3D(10,20,30);
		public var _v3d:Vector3D=new Vector3D(0,0,0);
		public var _v0a:Vector.<Number>=new Vector.<Number>(3);
		public var _v0b:Vector.<Number>=new Vector.<Number>(3);
		public var _v0d:Vector.<Number>=new Vector.<Number>(3);
		public function vecor3Dtest():void {
			var text_field:TextField = new TextField();
			text_field.width = stage.stageWidth;
			text_field.height = stage.stageHeight;
			stage.addChild(text_field);
			
			_v0a[0] = 0.1;
			_v0a[1] = 1.2;
			_v0a[2] = 2.3;			
			_v0b[0] = 10;
			_v0b[1] = 20;
			_v0b[2] = 30;

                        // 初期値が NaN だと遅くなる可能性があるので
                        _v0d[0] = _v0d[1] = _v0d[2] = 0;

			var _str:String = new String();
			_str = "同じ長さ、値のArray,Vector,Vector3Dをaddと同じ処理を100万回実行した時の処理時間（ミリ秒）\r";
			//_str += "Array0:" + benchMarkj(_a0) + "\r";//366
			//_str += "Array1:" + benchMarkj(_a1) + "\r";//366
			//_str += "Vector0:" + benchMarkj(_v0) + "\r";//88 
			//_str += "Vector1:" + benchMarkj(_v1) + "\r";//88 
			_str += "Vector2:" + benchMarkj(_v2) + "\r";//88 
			_str += "Vector3:" + benchMarkj(_v3) + "\r";//88 
			_str += "Vector4:" + benchMarkj(_v4) + "\r";//88 
			_str += "Vector3D0:" + benchMarkj(_30) + "\r";//615
			_str += "Vector3D1:" + benchMarkj(_31) + "\r";//615
			//_str += "Vector3D2:" + benchMarkj(_32) + "\r";//615
			//_str += "Vector3D3:" + benchMarkj(_32) + "\r";//615
			_str += "null:" + benchMarkj(_00) + "\r";//615
			text_field.text = _str;
		}
		
		//100万回関数を実行して、かかった時間をtrace 
		private function benchMarkj(_fn:Function):int {
			var time:Number = (new Date()).getTime();
			_fn(1000000);
			return (new Date()).getTime() - time;
		}
		
		private function _a0(n:uint):void {
			var _a0c:Array =new Array();
			for (var i:int = 0; i < n; i++) {
				for (var j:int = 0; j < 3; j++) {
					_a0c[j] = _a0a[j]+_a0b[j];
				}
			}
			//trace(_a0c);
		}
		
		private function _a1(n:uint):void {
			var _a0c:Array =new Array();
			for (var i:int = 0; i < n; i++) {
				_a0c[int(0)] = _a0a[int(0)]+_a0b[int(0)];
				_a0c[int(1)] = _a0a[int(1)]+_a0b[int(1)];
				_a0c[int(2)] = _a0a[int(2)]+_a0b[int(2)];
			}
			//trace(_a0c);
		}
		
		private function _v0(n:uint):void {
			var _v0c:Vector.<Number>=new Vector.<Number>(3);
			for (var i:int = 0; i < n; i++) {
                            for (var j:int = 0; j < 3; j++) {
					_v0c[j] = _v0a[j]+_v0b[j];
			    }
                        }
			//trace(_v0c);
		}
		
		private function _v1(n:uint):void {
			var _v0c:Vector.<Number>=new Vector.<Number>(3);
			for (var i:int = 0; i < n; i++) { 
				_v0c[0] = _v0a[0]+_v0b[0];
				_v0c[1] = _v0a[1]+_v0b[1];
				_v0c[2] = _v0a[2]+_v0b[2];
			}
			//trace(_v0c);
		}
		
		private function _v2(n:uint):void {
			var _v0c:Vector.<Number>=new Vector.<Number>(3);
                        var ax:Number, bx:Number, cx:Number, ay:Number, by:Number, cy:Number, az:Number, bz:Number, cz:Number;
			for (var i:int = 0; i < n; i++) {
/*
                                ax = _v0a[0]; bx = _v0b[0];
                                ay = _v0a[1]; by = _v0b[1];
                                az = _v0a[2]; bz = _v0b[2];
//*/
/*
				cx = ax + bx;
				cy = ay + by;
				cz = az + bz;
//*/
//*
                                cx = _v0a[0]+_v0b[0];
                                cy = _v0a[1]+_v0b[1];
                                cz = _v0a[2]+_v0b[2]; 
//*/
/*
                                _v0c[0] = cx;
                                _v0c[1] = cy;
                                _v0c[2] = cz;
//*/
			}
			//trace(_v0c);
		}
		
		private function _v3(n:uint):void {
			var _v3c:Vector3D=new Vector3D();
			for (var i:int = 0; i < n; i++) {
                                _v3c.x = _v0a[0]+_v0b[0];
                                _v3c.y = _v0a[1]+_v0b[1];
                                _v3c.z = _v0a[2]+_v0b[2]; 
			}
			//trace(_v0c);
		}

		private function _v4(n:uint):void {
			var _v3c:Vector3D=_v3d;
			for (var i:int = 0; i < n; i++) {
                                _v3c.x = _v0a[0]+_v0b[0];
                                _v3c.y = _v0a[1]+_v0b[1];
                                _v3c.z = _v0a[2]+_v0b[2]; 
			}
			//trace(_v0c);
		}

		private function _30(n:uint):void {
			var _v3c:Vector3D=new Vector3D();
			for (var i:int = 0; i < n; i++) {
				_v3c = _v3a.add(_v3b);
			}
			//trace(_v3c);
		}
		
		private function _31(n:uint):void {
			var _v3c:Vector3D=new Vector3D();
			for (var i:int = 0; i < n; i++) {
				_v3c.x = _v3a.x + _v3b.x;
				_v3c.y = _v3a.y + _v3b.y;
				_v3c.z = _v3a.z + _v3b.z;
			}
			//trace(_v3c);
		}
		private function _32(n:uint):void {
			var _v3c:Vector3D=new Vector3D();
			for (var i:int = 0; i < n; i++) {
				_v3c = vAdd2(_v3a,_v3b)
			}
		}
		
		private function vAdd2(_v0:Vector3D,_v1:Vector3D):Vector3D{
			var _v2:Vector3D=new Vector3D();
			_v2.x = _v0.x + _v1.x;
			_v2.y = _v0.y + _v1.y;
			_v2.z = _v0.z + _v1.z;
			return _v2;
		}		

		private function _33(n:uint):void {
			var _v3c:Vector3D=new Vector3D();
			for (var i:int = 0; i < n; i++) {
				vAdd3(_v3a,_v3b);
			}
		}
		
		private function vAdd3(_v0:Vector3D,_v1:Vector3D):void{
			_v0.x = _v0.x + _v1.x;
			_v0.y = _v0.y + _v1.y;
			_v0.z = _v0.z + _v1.z;
		}		

		private function _00(n:uint):void {
			var _v3c:Vector3D=new Vector3D();
			for (var i:int = 0; i < n; i++) {
			}
		}
		

	}
}

