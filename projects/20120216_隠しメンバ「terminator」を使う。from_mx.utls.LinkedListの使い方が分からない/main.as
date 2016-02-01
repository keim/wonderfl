package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import mx.utils.LinkedListNode;
    import mx.utils.LinkedList;
    public class main extends Sprite {
        public function main() {
            var linkedList:LinkedList = new LinkedList();
            var display:Array = [];
            var headTerminator:LinkedListNode; 
            var tailTerminator:LinkedListNode; 
            var node:LinkedListNode, nextNode:LinkedListNode;
            

            // 隠しメンバ terminator の取得
            display.push("//----- Get hidden terminator nodes"); 
            {
                linkedList.push("PUSH DUMMY !!!");
                headTerminator = linkedList.head.prev;
                tailTerminator = linkedList.tail.next;
                linkedList.pop(); // POP DUMMY !!!
            }
            
            
            // 要素数＝0 のときの、基本特性
            display.push(linkedList.length);                        // 0 elements
            display.push(headTerminator == tailTerminator);         // false (not ring-linked list)
            display.push(headTerminator == tailTerminator.prev);    // true
            // ↓重要な特性①
            display.push(headTerminator.next == tailTerminator);    // true
            
            
            // terminator を使った双方向リストの操作方法
            display.push("//----- basic iteration with terminators"); 
            {
                linkedList.push("a");
                linkedList.push("b");
                linkedList.push("c");
                
                // headTerminator.next が最初のノード
                node = headTerminator.next;         // headTerminator.next is the first element
                // node が tailTerminator ならループ終了（重要な特性① のおかげで要素数＝0でも問題なく動作）
                while (node != tailTerminator) {    // iteration with checking tail terminator
                    display.push("node=" + node + " node.value=" + node.value);
                    node = node.next;
                }
            }
            
            
            // terminator はループ内でノードを削除しても不変（重要な特性②）
            display.push("//----- terminators are stable after removing all elements during an iteration");
            {
                node = headTerminator.next;
                while (node != tailTerminator) {
                    display.push("[remove] node=" + node + " node.value=" + node.value);
                    nextNode = node.next;
                    linkedList.remove(node);
                    node = nextNode;
                }
            }
            
            
            // terminator は不変（重要な特性②）。一度取得しておけば、いつでも再利用可能
            display.push("//----- terminators are reusable whenever, once you get them");
            {
                linkedList.push("d");
                linkedList.push("e");
                linkedList.push("f");
                
                // for ループなら、こんなにシンプル（重要な特性③）
                // basic iteration with "for" loop
                for (node = headTerminator.next; node != tailTerminator; node = node.next) {
                    display.push("node=" + node + " node.value=" + node.value);
                }
            }
            
            
            var tf:TextField = new TextField();
            tf.width = 400;
            tf.height = 400;
            tf.text = display.join("\n");
            addChild(tf);
        }
    }
}