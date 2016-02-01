// forked from keim_at_Si's BrainF*ck interpreter challenge
package {
    import flash.events.*;
    import flash.display.*;
    import com.bit101.components.*;
    
    public class BFInterpreter extends Sprite {
        
        
        
        
// my current brainf*ck interpreter (192letters)----------------------------------------------------------------------------------------------------
function $(b,i){with(i){for(s=[x=k=0],p=-1,o=[];c=b[k<0?p--:++p];)k?k-=c>>6&&c-92:(c-=44)?c-2?c<2?s[x]-=c:c&1?c&2?s[x]?0:k=1:p+=k=-1:s[x+=c-17]||=0:o.push(s[x]):s[x]=shift()||(b={});return o}}
        
        
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
