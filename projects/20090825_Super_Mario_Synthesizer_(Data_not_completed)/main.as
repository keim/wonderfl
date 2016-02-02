// BGMs are from TSSCP threads.
// SEs are from http://mmltalks.appspot.com/mml/e781c745d6bac989bc13ce18dd5f4ccfb09c78cf
// Translated from http://dic.nicovideo.jp/mml_id/1868
package {
    import flash.display.Sprite;
    import flash.events.*;
    import org.si.sion.*;
    import com.bit101.components.*;
    
    
    [SWF(backgroundColor='#ffffff', frameRate='30')]
    public class main extends Sprite {
        public var driver:SiONDriver = new SiONDriver();
        public var sounds:SuperMarioSound = new SuperMarioSound();
        
        function main() {
            new Label(this, 175, 10, "Super Mario Synthesizer");

            var y:int, parent:Sprite = this;
            y = 30;
            _bgm("1-1", sounds.mario1);
            _bgm("1-2start", sounds.mario2start);
            _bgm("1-2", sounds.mario2);
            _bgm("1-4", sounds.mario4);
            _bgm("2-2(N/A)", sounds.nosound);
            _bgm("star(N/A)", sounds.nosound);
            _bgm("hurry up", sounds.hurryup);
            _bgm("stage clear(N/A)", sounds.nosound);
            _bgm("area clear", sounds.areaclear);
            _bgm("all clear(N/A)", sounds.nosound);
            _bgm("miss", sounds.miss);
            _bgm("game over", sounds.gameover);
            
            y = 30;
            _se("jump", sounds.jump);
            _se("jump large", sounds.jumpl);
            _se("block broken", sounds.block);
            _se("block not broken", sounds.dom);
            _se("cion", sounds.cion);
            _se("item", sounds.item);
            _se("item large", sounds.iteml);
            _se("power up", sounds.powerup);
            _se("extend", sounds.extend);
            _se("kick", sounds.poke);
            _se("fumi", sounds.fumi);
            _se("fire", sounds.fire);
            _se("warp", sounds.warp);
            _se("goal", sounds.goal);
            _se("bonus", sounds.bonus);
            _se("firework", sounds.firework);
            
            driver.bpm = 200;
            driver.play(sounds.nosound);
    
            function _bgm(label:String, data:SiONData) : void {
                new PushButton(parent, 100, y, label, function():void { driver.play(data); });
                y += 20;
            }
            function _se(label:String, data:SiONData) : void {
                new PushButton(parent, 250, y, label, function():void { driver.sequenceOn(data, null, 0, 0, 0); });
                y += 20;
            }
        }
    }
}




import org.si.sion.*;

// this instanse have to be created after creating SiONDrivers instance.
// All SiONData are in bpm of 200.
class SuperMarioSound {
    public var nosound:SiONData;
    // bgm
    public var mario1:SiONData;
    public var mario2:SiONData;
    public var mario2start:SiONData;
    public var mario4:SiONData;
    public var areaclear:SiONData;
    public var hurryup:SiONData;
    public var miss:SiONData;
    public var gameover:SiONData;
    
    // sound effect
    public var block:SiONData;
    public var item:SiONData;
    public var iteml:SiONData;
    public var powerup:SiONData;
    public var jump:SiONData;
    public var jumpl:SiONData;
    public var poke:SiONData;
    public var fumi:SiONData;
    public var dom:SiONData;
    public var fire:SiONData;
    public var cion:SiONData;
    public var extend:SiONData;
    public var warp:SiONData;
    public var goal:SiONData;
    public var bonus:SiONData;
    public var firework:SiONData;
    
    
    function SuperMarioSound() {
        var driver:SiONDriver = SiONDriver.mutex;
        var header:String, mml:String;
        header = "t200;#EFFECT0{speaker20};";
        
        // The following 4 lines are avoiding bugs in curren version. 
        // In this version, the sequenceOn() function cannot refer tables in the SiONData, 
        // so we have to define all tables on main SiONData played by SiONDriver.play().
        // In new version(0.57), the sequenceOn() function can refer the tables in SiONData and following mmls are not requeired.
        header += "#TABLE0{(0,128)8};#TABLE1{(0,384)8};#TABLE2{(128,0)12,0};#TABLE3{(90,934)12};";
        header += "#TABLE4{(0,-1280)4};#TABLE5{(0,-1280)6};#TABLE6{(0,-2560)6};#TABLE7{(0,36)36};";
        header += "#TABLE8{14,0,13,0,13,0,12,0,12,,11,0,9,0,9,0,8,0,8,0,7,0,6,0,6,0,5,0,5}*8+31;";
        header += "#TABLE9{12,6,13,8,13,3,9,10,15,12,6,11,13,14};";
        
        nosound = driver.compile(header);
        
        // MML from TSSCP thread dtm 1-564 modifyed
        mml = header;
        mml += "#A=o6eerercer grrr>grrr;";
        mml += "#B=o6[2crr>grrer rarbra+ar gr24<er24gr24arfg rercd>brr];";
        mml += "#C=o6[2[2rrgf+fd+re r>g+a<cr>a<cd |rrgf+fd+re r<crccrrr]>rrd+rrdrr crr2.];";
        mml += "#D=o6[2ccrcrcdr ecr>agrrr |<ccrcrcde r1];";
        mml += "#E=o6[2ecr>grrg+r a<frf>arrr |br24<ar24ar24ar24gr24fr24 ecr>agrrr]b<frffr24er24dr24 crr2.;";
        mml += "#F=o5f+f+rf+rf+f+r brr2.;";
        mml += "#G=o5[2errcrr>gr r<crdrc+cr cr24gr24br24<cr>ab rarefdrr];";
        mml += "#H=o6[2[2rred+d>br<c r>efgrcef |<rred+d>br<c rfrffrrr]>rrg+rrfrr err2.<];";
        mml += "#I=o5[2g+g+rg+rg+a+r gerecrrr |g+g+rg+rg+a+g r1];";
        mml += "#J=o6[2c>arerrer f<crc>frrr |gr24<fr24fr24fr24er24dr24 c>arferrr]g<drddr24cr24>br24 gerecrrr;";
        mml += "#K=o4ddrdrddr <grrr>grrr;";
        mml += "#L=o4[2grrerrcr rfrgrf+fr er24<cr24er24frde rcr>abgrr];"
        mml += "#M=o4[2[2crrgrr<cr >frr<ccr>fr |crrerrg<c r<grggr>>gr]crg+rra+rr <crr>ggrcr];";
        mml += "#N=o3[3g+rr<d+rrg+r grrcrr>gr];";
        mml += "#O=o4[2crrf+gr<cr >frfr<cc>fr |drrfgrbr grgr<cc>gr]grrggr24ar24br24 <cr>grcrrr;";
        mml += "#X=v15o1q1s38g16r8.;#Y=v10o5q1s36c16;#Z=v8o5q5s34c8r8;";
        mml += "#P=ZYrZYrZZrrZYrYrYr;#Q=XYrrYZYrrY;#R=Yr4rYrZYr8.;";
        mml += "t200;%0@0l8v10q5s34A$BCDABEEDAE;%0@0l8v10q5s34F$GHIFGJJIFJ;%5@3l8v12q8s63K$LMNKLOONKO;";
        mml += "%2@0l16P$[Q]24[P]4[Q]8[R]16[P]4[R]8;";
        mario1 = driver.compile(mml);
        
        // MML from TSSCP thread dtm 1-115 modifyed
        mml = header;
        mml += "#A=[2c<c>>a<a>a+<a+r2.][2>f<f>d<d>d+<d+r2|r4]d+12d12c+12crd+rdr>g+rgr<c+rl12cf+fea+ag+.Rd+.R>b.Ra+.Ra.Rg+.Rr1.;";
        mml += "%1@4v10q5s34l8o5$A;%1@8v12q8s63l8o4$A;";
        mario2 = driver.compile(mml);

        // MML from TSSCP thread dtm 1-115 modifyed
        mml = header;
        mml += "#Y=v10q1s36c16r16; #Z=v8q5s38o5c8;";
        mml += "%1@4v10q5s34l8o6 eerercergrrr>g r2. s63q8l64o7[e>ad<e>ad>gc>f>a+r16]3;";
        mml += "%1@4v10q5s34l8o5 f+f+rf+rf+f+rb;";
        mml += "%1@8v12q8s63l8o4 ddrdrddr<grrr>g;";
        mml += "%2l8o5 ZrYZrYZrZrrZrYYY;";
        mario2start = driver.compile(mml);
        
        // MML from TSSCP thread dtm 1-115 modifyed
        mml = header;
        mml += "o6l8q1s29r64$r16[2dd-cd-de-dd-][2d-cd-dd-dd-c][2fg-fefee-|e]e16;";
        mml += "o5l16q1s31r64$[2gb-gaga-gagb-gbgb-ga][2f+af+a-f+af+b-f+af+b-f+af+a-]";
        mml += "[2a+<d>a+<e->a+<d>a+<d->a+<d>a+<d->a+<c>a+<d->];%5@0q8s63l2o4$e-1dg-f1eb-aee-e";
        mario4 = driver.compile(mml);
        
        // MML from TSSCP thread dtm 1-864 modifyed
        mml = header;
        mml += "%0s63o6l8c>ge<c>ge<c2.c+>g+f<c+>g+f<c+2.d+>a+g<d+>a+g<d+4.l6fffg1.;";
        mml += "%0s63o5l8ec>g<ec>g<ee16e16eeeefc+>g+<fc+>g+<ff16f16ffffgd+>a+<gd+>a+<gg16g16gl6aaab1.;";
        mml += "%5@3s63q6o4l8c2.cc16c16ccccc+2.c+c+16c+16c+c+c+c+a+gd+a+gd+a+a+16a+16a+<l6cccd1.;";
        areaclear = driver.compile(mml);

        // MML from TSSCP thread dtm 2-805 modifyed
        mml = header;
        mml += "l12%0v8s63q7o5 e<drddr> f<d+rd+d+r> f+<ereer fr f2>;";
        mml += "l12%0v8s63q7o5 >e<g+6g+g+6 >f<a6aa6 >f+<a+6a+a+6 br b2;";
        mml += "l12%3v8s63q6o5 >b<b6bb6 c<c6cc6> c+<c+6c+c+6> >g6 g2 <;";
        hurryup = driver.compile(mml);
        
        mml = header;
        mml += "%1@4s39v14q6l8r^2 b<frff6e6d6cr1;";
        mml += "%1@4s27,-45v14q0l8 o4<b16b16b16r16r^4g<drdd6c6>b6gerecr2;";
        mml += "%1@8s41v16q7l8r^2 o4gr4gg6a6b6<c>grgcr2;";
        miss = driver.compile(mml);
        
        mml = header + "#TABLE10{0,32,64,80,104,128};";
        mml += "%1@4s39v14q7l4na10,1o5e8rc8ro4go5f2f^2e8d8e2;";
        mml += "%1@4s63v14q8l4na10,1o6c8ro5g8rea8.b8a8.g+a+g+g2.;";
        mml += "%5@3s38v16q7l4o4g8re8rcs25f2c+2.c2..;";
        gameover = driver.compile(mml);

        mml = "t200;#TABLE8{14,0,13,0,13,0,12,0,12,,11,0,9,0,9,0,8,0,8,0,7,0,6,0,6,0,5,0,5}*8+31;";
        mml += "#TABLE9{12,6,13,8,13,3,9,10,15,12,6,11,13,14};";
        mml += "%1@9s63q8o0na8,1nt9,2c4.^32nantx128";
        block = driver.compile(mml);
        item = driver.compile("t200;#A=cggg+g+c+;%1@4s63q8l64o5A(0)A(1)A(2)A(3)");
        iteml = driver.compile("t200;#A=cggg+g+c+;%1@4s63q8l64o5A(0)A(1)A(2)A(3)A(4)A(5)A(6)A(7)");
        powerup = driver.compile("t200;%1@2s63q8l32o6c>g<ceg<c>g>g+<cd+g+d+g+b+<d+g+d+>>a+<dfa+fa+<dfa+f64");
        jump = driver.compile("t200;#TABLE2{(128,0)12,0};#TABLE3{(90,934)12};%1@4s63q8o5a32@2na2,2np3,2g2");
        jumpl = driver.compile("t200;#TABLE2{(128,0)12,0};#TABLE3{(90,934)12};%1@4s63q8o5d32@2na2,2np3,2c2");
        poke = driver.compile("t200;%1@4s63l128o5b-<cr16f64");
        fumi = driver.compile("t200;#TABLE0{(0,128)8};#TABLE1{(0,384)8};%1@4s63q8l10na0np1o5a<gnanp");
        dom = driver.compile("t200;#TABLE4{(0,-1280)4};%1@4s63q8l64np4,2o4a-16npc+&d+&f&f+");
        fire = driver.compile("t200;%1@4s63q8l64o4g<g<g<g<g");
        cion = driver.compile("t200;%1@4s63q8l16q0s22o6b<e");
        extend = driver.compile("t200;%1@4s63q0s24l9o7eg<ecdq8s63g");
        warp = driver.compile("t200;%1@4s63q8l64o7[e>ad<e>ad>gc>f>a+r16]3");
        goal = driver.compile("t200;#TABLE7{(0,36)36};%1@4s63q8o4nt7,2b-1");
        bonus = driver.compile("t200;%1@4s63q7l64o6[b]80");
        firework = driver.compile("t200;#TABLE5{(0,-1280)6};#TABLE6{(0,-2560)6};%1@4s63q8l64np5,2o4c+8<np6,2c+6np");
    }
}


