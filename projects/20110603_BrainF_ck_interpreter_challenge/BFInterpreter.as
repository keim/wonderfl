package {
    import flash.events.*;
    import flash.display.*;
    import com.bit101.components.*;
    
    public class BFInterpreter extends Sprite {
        
        
        
        
// my brainf*ck interpreter (currently in 262 letters) ----------------------------------------------------------------------------------------------------
function $(b,i){for(var s=[0],x=0,o=[],l=[],c,k,p=0;c=b[p];p++)if((c-43?c-44?c-45?c-46?c-60?c-62?c-91?(p=l.pop()-1):(s[x])?l.push(p):b:(s[++x]||=0):--x:o.push(s[x]):--s[x]:(s[x]=i.shift())?0:(p=-9):s[x]++)==b)for(k=1;k&&(c=b[++p]);)k-=c-93?c-91?0:-1:1;return o}
        
        
// User Interface ----------------------------------------------------------------------------------------------------
        function BFInterpreter() { addEventListener(Event.ADDED_TO_STAGE, _setup); }
        
        private function _setup(event:Event) : void {
            event.target.removeEventListener(event.type, arguments.callee);
            _source = _newTextArea("source :", 20,  200);
            _input  = _newTextArea("input :",  240, 18);
            _output = _newTextArea("output :", 280, 160);
            new PushButton(this, 132, 221, "execute", _execute).setSize(200, 18);
            
            // Hello, world! (72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33)
            _source.text = "+++++++++[>++++++++>+++++++++++>+++++<<<-]>.>++.+++++++..+++.>-.------------.<++++++++.--------.+++.------.--------.>+.";
        }
        
        private function _newTextArea(label:String, ypos:Number, height:Number) : TextArea {
            var textArea:TextArea = new TextArea(this, 32, ypos);
            textArea.setSize(400, height);
            new Label(this, 32, ypos-20, label);
            return textArea;
        }
        
        private function _execute(event:Event) : void {
            var sourceCode:String, sourceChars:Array=[], inputChars:Array=[], outputChars:Array, i:int;
            
            // translate input text to char[]
            sourceCode = _source.text.replace(/[^<>+\-.,[\]]/gm, "");
            for (i=0; i<sourceCode.length;  i++) sourceChars.push(sourceCode.charCodeAt(i));
            for (i=0; i<_input.text.length; i++) inputChars.push(_input.text.charCodeAt(i));
            // null for the end of char[]
            sourceChars.push(0);
            inputChars.push(0);
            
            // execute interpreter
            outputChars = $(sourceChars, inputChars);
            
            // translate output char[] to text
            for (i=0; i<outputChars.length; i++) _output.text += String.fromCharCode(outputChars[i]);
            _output.text += "\n";
        }

        private var _source:TextArea, _input:TextArea, _output:TextArea;
    }
}
