// blue="A", green="C", yellow="D", red="E", purple="G"
package{
    import flash.display.*;
    import flash.geom.*;
    import flash.events.Event;
    import frocessing.display.*;
    import com.actionsnippet.qbox.*;
    import Box2D.Collision.b2ContactPoint;
    import org.si.sion.*;
    import org.si.sion.utils.*;
    import org.si.sion.sequencer.SiMMLTrack;
    import com.bit101.components.*;

    [SWF(frameRate="30")]
    public class main extends F5MovieClip2D {
        // objects
        private var colors:Array = [0x8080c0, 0x80c080, 0xc0c060, 0xc08080, 0xc060c0];
        private var colts:Vector.<ColorTransform> = new Vector.<ColorTransform>();
        private var impacts:Vector.<Vector3D> = new Vector.<Vector3D>();
        
        // qb2d
        private var qb2d:QuickBox2D;
        private var contact:QuickContacts;
        private var wall:QuickObject;
        private var balls:Vector.<QuickObject> = new Vector.<QuickObject>();
        
        // draw
        private var canvas:MovieClip = new MovieClip(); 
        private var screen:BitmapData = new BitmapData(465, 465, false, 0);
        private var buffer:Vector.<BitmapData> = new Vector.<BitmapData>(4);
        private var bufferCount:int, scroll:Number, scrollMatrix:Matrix;
        private var mat:Matrix = new Matrix();
        private var flash:BitmapData = new BitmapData(128, 128, false, 0);
       
        // sion
        private var _driver:SiONDriver = new SiONDriver();
        private var _preset:SiONPresetVoice = new SiONPresetVoice();
        private var _scale:Scale = new Scale("Amp"); // A minor pentatonic
        private var _backing:SiONData, _voice:SiONVoice;
        private var _voiceList:Array = ["square","valsound.bell2","valsound.bell14","valsound.bell16",
        "valsound.brass4","valsound.brass19","valsound.lead2","valsound.lead17","valsound.lead19",
        "valsound.lead22","valsound.piano9","valsound.piano11","valsound.strpad23","valsound.strpad24",
        "valsound.wind2","valsound.wind6","valsound.wind8","valsound.world5","midi.piano1","midi.piano8",
        "midi.chrom5","midi.chrom6","midi.organ1","midi.strings1","midi.brass7","midi.reed1","midi.reed8","midi.pipe5"];
        
        // ui
        private var _tempo:Knob;
        private var _voiceSelect:PushButton;
        private var _voiceName:Label;
        
        // setup
        public function setup() : void {
            Wonderfl.capture_delay(8);
            
            var i:int, j:int, n:Number, r:Number, shp:Shape = new Shape(), mat:Matrix = new Matrix();
            addChild(new Bitmap(screen));

            // ui
            _tempo = new Knob(this, 20, 400, "BPM", _changeBPM);
            _tempo.minimum = 60;
            _tempo.maximum = 180;
            _tempo.value = 144;
            _tempo.radius = 10;
            _voiceSelect = new PushButton(this, 60, 434, "Change Voice", _changeVoice);
            _voiceSelect.setSize(80, 16);
            _voiceName = new Label(this, 60, 416, "");
            
            // qb2d
            qb2d = new QuickBox2D(canvas, {gravityY:20, bounds:[-100,-100,100,1000], iterations:4});
            qb2d.setDefault({lineThickness:4, radius:0.4, restitution:0.5});
            
            // qb2d objects
            randomSeed(uint(new Date().time));
            balls.length = impacts.length = colors.length;
            for (i=0; i<colors.length; i++) {
                balls[i] = qb2d.addCircle({x:random(1,14.5), y:random(2,5), fillColor:0, lineColor:colors[i]});
                colts[i] = new ColorTransform(((colors[i]>>16)&255)/255, ((colors[i]>>8)&255)/255, (colors[i]&255)/255);
                impacts[i] = new Vector3D(0, 0, 0);
            }
            qb2d.setDefault({fillColor:0, lineColor:0x202020, lineThickness:4, density:0});
            wall = qb2d.addGroup({x:0, y:0, objects:[
                qb2d.addBox({x:0,     y:7.25,  width:0.5, height:46.5}),
                qb2d.addBox({x:15.5,  y:7.25,  width:0.5, height:46.5}),
                qb2d.addBox({x:0.25,  y:0,     width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:6.25,  y:0,     width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:12.25, y:0,     width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:3.25,  y:7.25,  width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:9.25,  y:7.25,  width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:15.25, y:7.25,  width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:0.25,  y:15.5,  width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:6.25,  y:15.5,  width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:12.25, y:15.5,  width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:3.25,  y:22.75, width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:9.25,  y:22.75, width:3, height:3, angle:0.7853981633974483}),
                qb2d.addBox({x:15.25, y:22.75, width:3, height:3, angle:0.7853981633974483})
            ]});
            contact = qb2d.addContactListener();
            contact.addEventListener(QuickContacts.ADD, _onAdd);
            scroll = 7;
            scrollMatrix = new Matrix(1,0,0,1,0,0);
            bufferCount = 0;
            for (i=0; i<4; i++) buffer[i] = new BitmapData(465, 465, false, 0);

            // texture
            for (n=0; n<6.283185307179586; n+=0.004363323129985824) {
                r = (1-random(0,1) * random(0,1)) * 63;
                mat.createGradientBox(128-r-r, 128-r-r, 0, r, r);
                shp.graphics.clear();
                shp.graphics.lineStyle(1);
                shp.graphics.lineGradientStyle(GradientType.RADIAL, [0x808080,0], [1,1], [0,255], mat);
                shp.graphics.moveTo(63.5, 63.5);
                shp.graphics.lineTo(sin(n)*90+63.5, cos(n)*90+63.5);
                flash.draw(shp, null, null, "add");
            }

            // sion
            var mml:String = "t144;#EFFECT1{chorus delay625,,1};";
            mml += "%5v28q0s28,-128o3$c;%2@1@f64,2q0s32$[rc]3rc8.)6c16(6;%2@3q0v4l16$s44ccs28)cr(;";
            mml += "%5@1@f40,2,36,,,,72v10q8l8o2$[a<a>]4[f<f>]4[g<g>]4[e<e>]4;";
            _backing = _driver.compile(mml);
            _voice = _preset["valsound.lead2"];
            _driver.noteOnExceptionMode = SiONDriver.NEM_SHIFT;
            _driver.fadeIn(8);

            // ... and start
            qb2d.start();
            _driver.play(_backing);
        }

        public function draw() : void {
            var i:int, bx:Number, by:Number, maxy:Number = 0, imax:int = balls.length;
            for (i=0; i<imax; i++) {
                by = balls[i].y;
                if (maxy < by) maxy = by;
            }
            if (maxy > scroll) {
                scroll += (maxy - scroll) * 0.2;
                if (wall.y < scroll-20.625) wall.y += 15.5;
                for (i=0; i<imax; i++) {
                    bx = balls[i].x;
                    by = balls[i].y;
                    if (by < scroll-31 || by > scroll+31 || bx < 0 || bx > 15.5) {
                        balls[i].y = scroll - 15.5;
                        balls[i].x = random(1, 14.5);
                    }
                }
                if (scroll > 800) {
                    scroll -= 800;
                    wall.y -= 800;
                    for (i=0; i<balls.length; i++) balls[i].y -= 800;
                }
                scrollMatrix.ty = -(scroll-10) * 30;
            }
            buffer[bufferCount].fillRect(screen.rect, 0);
            buffer[bufferCount].draw(canvas, scrollMatrix);
            for (i=0; i<imax; i++) {
                if (impacts[i].z > 0.03125) {
                    mat.identity();
                    mat.translate(-64, -64);
                    mat.scale(impacts[i].z, impacts[i].z);
                    mat.rotate(random(0,6.28));
                    mat.translate(impacts[i].x, impacts[i].y);
                    colts[i].alphaMultiplier = impacts[i].z;
                    buffer[bufferCount].draw(flash, mat, colts[i], "add");
                    impacts[i].z *= 0.7;
                }
            }
            bufferCount = (bufferCount + 1) & 3;
            screen.copyPixels(buffer[bufferCount],screen.rect, screen.rect.topLeft);
        }
        
        private function _onAdd(e:Event) : void {
            var track:SiMMLTrack, vel:Number = (contact.currentPoint.velocity.LengthSquared() - 100) * 0.3;
            if (vel > 48) vel = 48;
            if (vel > 0) {
                for (var i:int=0; i<5; i++) {
                    if (contact.inCurrentContact(balls[i])) {
                        track = _driver.noteOn(_scale.getNote(i-5), _voice, 1, 0, 1);
                        track.velocity = vel+16;
                        track.pan = (contact.currentPoint.position.x - 7.75) * 8;
                        track.channel.setStreamSend(1, 0.25);
                        impacts[i].x = balls[i].x * 30;
                        impacts[i].y = balls[i].y * 30 + scrollMatrix.ty;
                        impacts[i].z = 2;
                    }
                }
            }
        }

        private function _changeBPM(e:Event) : void {
            _driver.bpm = _tempo.value;
        }

        private function _changeVoice(e:Event) : void {
            _voice = _preset[_voiceList[random(0,_voiceList.length)>>0]];
            _voiceName.text = _voice.name;
        }
    }
}
