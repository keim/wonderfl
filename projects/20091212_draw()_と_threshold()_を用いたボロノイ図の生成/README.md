# [draw() と threshold() を用いたボロノイ図の生成](http://fl.corge.net/c/57Ng)

favorite:19 / forked:3

BitmapData.draw() と BitmapData.threshold() を用いたボロノイ図の生成  
制御点をドラッグで移動  
http://fl.corge.net/code/13a64427311b17680c2743a08610096d461a354e  
点の数が処理負荷は単純比例．GPU実装は容易，というか Z-buffer だけで実装できる  
↑のは，同じアルゴリズムで 逆に Z-buffer "を" 実装した例  
とりあえず，10点くらいなら超速キレイだけど，多点は厳しいかも．  
Z-buffer 実装に応用するには，今のところ合成処理がネックで重い．  
webpage; http://soundimpulse.sakura.ne.jp/voronoi-by-draw-and-threshold/

![thumbnail](./thumbnail.jpg)
