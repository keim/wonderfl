package {
    import flash.display.Sprite;
    import org.si.sion.SiONDriver;
    import org.si.sound.*;
    
    public class FlashTest extends Sprite {
        public function FlashTest() {
              var driver:SiONDriver = new SiONDriver();
              var drum:DrumMachine = new DrumMachine();
                 
              driver.bpm = 132;
              driver.play();
              drum.play();  
        }
    }
}

