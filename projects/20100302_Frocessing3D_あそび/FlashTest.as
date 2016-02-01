package {
	import flash.display.*;
	import flash.geom.*;
    import frocessing.display.*;
    import org.si.sion.*;
    import org.si.sion.events.*;
    
    public class FlashTest extends F5MovieClip3D {
    		public var blocks:Vector.<Block> = new Vector.<Block>(54);
    		public var ball:Ball = new Ball();
    		public var padle:Padle = new Padle();

    		public function setup() : void {
    			$ = this;
    			stage.frameRate = 30;
    			colorMode(HSV, 1, 1, 1, 1);
    			imageMode(CENTER);
    			_createTexture();
    			for (var i:int = 0; i<9; i++) {
    				for (var j:int = 0; j<6; j++) {
    					blocks[i+j*9] = new Block(i*40-160, j*24-150, j/7);
    				}
    			}
    			breakSound = driver.compile("%5@7@v32,16l32o7gd");
    			reflectSound = driver.compile("%5@7@v32,16l32o6cfe-b-");
    			
    			ball.reset(-10, 0, -1, 6);
    			driver.addEventListener(SiONTrackEvent.BEAT, _onBeat);
    			driver.play("t150;#EFFECT1{delay};%5@0s24,-128v24o2l8q0$[c.c.cr|crc]c16c16rc;%2@f64,1@1l4q0s32$rc;%2@3l16v3s40q0$c;%5@2l16v6@f80,2o3q0s20$crfb-");
    		}
    		
    		public function draw() : void {
			var b:Block;
    			background(0, 0, 0);
    			translate(232.5, 232.5);
    			rotateX(0.5);
    			
    			ball.update();
    			padle.update();
    			for each (b in blocks) {
    				switch (b.eval(ball.x, ball.y)) {
    				case 0: break;
    				case 1: if (ball.vx>0) ball.vx = -ball.vx; break;
    				case 2: if (ball.vx<0) ball.vx = -ball.vx; break;
    				case 3: if (ball.vy>0) ball.vy = -ball.vy; break;
    				case 4: if (ball.vy<0) ball.vy = -ball.vy; break;
    				}
    			}
    			if (padle.eval(ball.x, ball.y)) {
    				driver.sequenceOn(reflectSound, null, 0, 0, 1);
    				ball.reflect(padle.angle);
    			}
    			
 	 	 	stroke(0, 0, 0.5);
  			strokeWeight(1);
    			padle.draw();
    			for each (b in blocks) b.draw();
    			noStroke();
			Particle.drawAll();
    			ball.draw();
    		}
    		
    		public function mousePressed() : void {
    			padle.hold();
    		}
    		
    		public function mouseReleased() : void {
    			padle.release();
    		}
    		
    		private function _onBeat(e:SiONTrackEvent) : void {
    			ball.size = 32;
    		}
    		
    		public var tex:Vector.<BitmapData> = new Vector.<BitmapData>(16);
    		private function _createTexture() : void {
    			for (var i:int=0; i<16; i++) {
    				var t:BitmapData = tex[i] = new BitmapData(32, 32, true, 0),
    				    c:uint = color(i*0.0625, 1, 1);
	    			t.draw(_radialGradientShape(32, [c,c], [1, 0], [0,255]));
    			}
    		}
    		
        private function _radialGradientShape(size:Number, color:Array, alpha:Array, ratio:Array) : Shape {
            mat.createGradientBox(size, size, 0, 0, 0);
            shp.graphics.clear();
            shp.graphics.beginGradientFill(GradientType.RADIAL, color, alpha, ratio, mat);
            shp.graphics.drawRect(0, 0, size, size);
            shp.graphics.endFill();
            return shp;
        }
        private var shp:Shape = new Shape(), mat:Matrix = new Matrix();
    }
}


import org.libspark.betweenas3.*;
import org.libspark.betweenas3.tweens.*;
import org.libspark.betweenas3.easing.*;
import org.si.sion.*;
import frocessing.core.F5C;

var $:FlashTest;
var driver:SiONDriver = new SiONDriver();
var breakSound:SiONData;
var reflectSound:SiONData;

class Background {
	public var scroll:Number;
	
	function Background() {
	}
	
	public function draw() : void {
		
	}
}


class Block {
	static public var w:Number=38, h:Number=20;
	static public var hw:Number=w*0.5, hh:Number=h*0.5;
	public var x:Number, y:Number, hue:Number, isAlive:Boolean;
	function Block(x:Number, y:Number, hue:Number){
		this.x = x;
		this.y = y;
		this.hue = hue;
		isAlive = true;
	}
	
	public function draw() : void {
		if (isAlive) {
			$.pushMatrix();
			$.translate(x, y);
  	  		$.fill(hue, 0.5, 1, 0.75);
			$.box(w, h, h);
			$.popMatrix();
		}
	}
	
	public function eval(bx:Number, by:Number) : int {
		if (isAlive && x-hw<bx && bx<x+hw && y-hh<by && by<y+hh) {
			driver.sequenceOn(breakSound, null, 0, 0, 1);
			isAlive = false;
			for (var i:int=0; i<8; i++) Particle.alloc(x, y, hue);
			if (bx<x-18) return 1;
			if (x+18<bx) return 2;
			if (by<y) return 3;
			return 4;
		}
		return 0;
	}
}

class Particle {
	public var x:Number, y:Number, z:Number, hue:Number;
	public var angle:Number, rot:Number, alpha:Number, da:Number;
	function Particle() {}
	
	public function draw() : void {
		$.pushMatrix();
  		$.fill(hue, 0.5, 1, alpha);
		$.beginShape(F5C.TRIANGLES);
		$.translate(x, y, z);
		$.rotateZ(angle);
    		$.vertex3d(10,-5,-5);
    		$.vertex3d(-5,10,-5);
    		$.vertex3d(-5,-5,10);
		$.endShape();
    		$.popMatrix();
    		angle += rot;
    		alpha -= da;
    		z -= 1;
	}
	
	static private var _freeList:Array = [], _activeList:Array = [];
	static public function alloc(x:Number, y:Number, hue:Number) : void {
		var inst:Particle = _freeList.pop() || new Particle();
		var time:Number = $.random(1,2);
		x+=$.random(-10,10);
		y+=$.random(-5,5);
		inst.x = x;
		inst.y = y;
		inst.z = 0;
		inst.hue = hue;
		inst.alpha = 0.6;
		inst.da = 0.58/(time*30);
		inst.rot = $.random(-0.1,0.1);
		inst.angle = $.random(-3.14,3.14);
		var t:ITween = BetweenAS3.to(inst, {x:x+$.random(-40,40), y:y+$.random(-20,20)}, time, Expo.easeOut);
		t.onComplete = inst.free;
		t.play();
		_activeList.push(inst);
	}
	
	public function free() : void {
		_activeList.splice(_activeList.indexOf(this), 1);
		_freeList.push(this);
	}
	
	static public function drawAll() : void {
		for each (var p:Particle in _activeList) {
			p.draw();
		}
	}
}

class Ball {
	public var x:Number=0, y:Number=0, vx:Number, vy:Number, size:Number=16;
	function Ball() {
	}
	
	public function reset(x:Number, y:Number, vx:Number, vy:Number) : void {
		this.x = x;
		this.y = y;
		this.vx = vx;
		this.vy = vy;
	}
	
	public function draw() : void {
		$.pushMatrix();
		$.translate(x, y);
    		$.image2d($.tex[0], 0, 0, 0, size, size);
    		$.popMatrix();
    		size *= 0.9;
	}
	
	public function update() : void {
		x += vx;
		y += vy;
		if (x<-200 && vx<0) { x=-200; vx=-vx; }
		if (x> 200 && vx>0) { x= 200; vx=-vx; }
		if (y<-230 && vy<0) { y=-230; vy=-vy; }
		if (y> 200 && vy>0) { y= 200; vy=-vy; }
	}
	
	public function reflect(angle:Number) : void {
		var nx:Number = -Math.cos(angle), ny:Number = Math.sin(angle), 
		    r:Number = (vx*ny + vy*nx) * 2;
		vx = vx - r * ny;
		vy = vy - r * nx;
		vx *= 1.05;
		vy *= 1.05;
		x += vx;
		y += vy;
		
	}
}

class Padle {
	public var x:Number=0, vx:Number=0, len:Number=50;
	public var angle:Number=0, power:Number=0, isHolding:Boolean=false;
	function Padle() {
	}
	
	public function draw() : void {
		$.pushMatrix();
		$.translate(x, 160);
		$.rotateZ(angle);
		$.translate(0, -power);
    		$.noFill();
		$.box(len*2, 10, 10);
    		$.popMatrix();
	}
	
	public function update() : void {
    		vx = (($.pmouseX - 232.5) - x) * 0.1;
		if (!isHolding) x += vx;
		angle = vx * 0.02;
	}
	
	public function eval(bx:Number, by:Number) : Boolean {
    		return (150 < by && by < 170 && x-len < bx && bx < x+len);
    	}
	
	public function hold() : void { isHolding = true; }
	public function release() : void { isHolding = false; }
}

