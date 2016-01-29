package {
    import flash.events.*;
    import flash.display.*;
    import flash.text.*;
    import com.bit101.components.*;
    
    public class FlashTest extends Sprite {
        private var YAWA:*, userID:String;
        
        private var tf:TextField;
        private var currentText:String;
        private var codes:Array;
        private var codeCount:int, cachedCodeCount:int;
        private var favorited:int, forked:int, totalPV:int, totalLines:int, diff1:int;
        private var finishAnalysisCount:int;
        
        public function FlashTest() {
            userID = loaderInfo.parameters["viewer.displayName"];
            useYAWA(setup);
        }
        
        
        private function setup(api:*) : void {
            YAWA = api;
            
            new InputText(this, 0, 0, userID, function(e:Event) : void { userID = e.target.text; });
            new PushButton(this, 360, 0, "Analyze", function(e:Event) : void { start(); });
            tf = new TextField();
            tf.y = 20;
            tf.width = stage.stageWidth;
            tf.height = stage.stageHeight - tf.y;
            tf.multiline = true;
            tf.wordWrap = true;
            tf.defaultTextFormat = new TextFormat("_sans", 12);
            addChild(tf);
        }
        
        
        private function start() : void {
            currentText = "";
            YAWA.requestUserInfo(responseCodeListFirst, userID, YAWA.USER_INFO_CODE, 1);
        }
            
        
        private function responseCodeListFirst(data:*) : void {
            codeCount = data.codes_count;
            print("user : " + userID);
            print("posted codes : " + String(codeCount));
            var p:int, pageMax:int = data.codes_pages;
            for (p=1; p<pageMax; p++) YAWA.requestUserInfo(responseCodeList, userID, YAWA.USER_INFO_CODE, p+1);
        }
        
        
        private function responseCodeList(data:*) : void {
            print$("get code list ... (" + String(data.cached_codes_count) + "/" + String(codeCount) + ")");
            if (data.cached_codes_count == codeCount) {
                codes = data.codes;
                totalLines = totalPV = forked = favorited = 0;
                var tagsHash:* = {}, tags:Array = [];
                cachedCodeCount = 0;
                for (var i:int=0; i<codes.length; i++) {
                    favorited  += codes[i].favorited_count;
                    forked     += codes[i].forked_count;
                    totalPV    += codes[i].pv;
                    totalLines += codes[i].lines;
                    for each (var tag:String in codes[i].tags) {
                        if (!(tag in tagsHash)) tags.push(tagsHash[tag] = new TagInfo(tag));
                        else tagsHash[tag].count++;
                    }
                    YAWA.requestCodeInfo(responseCode, codes[i].id, "", 1);
                }
                print("forked : " + String(forked));
                print("favorited : " + String(favorited));
                print("total pv : " + String(totalPV));
                print("total lines :" + String(totalLines));
                tags.sort(TagInfo.sorter);
                print("[tags]");
                print(tags.splice(0,32).join(", "));
            }
        }
        
        
        private function responseCode(data:*) : void {
            var p:int, i:int, data:*, key:String, 
                libList:*,     libsHash:*={}, libs:Array=[], 
                fanList:Array, fansHash:*={}, fans:Array=[];
            print$("get code ... (" + String(++cachedCodeCount) + "/" + String(codeCount) + ") [" + data.title + "]");
            if (cachedCodeCount == codeCount) {
                finishAnalysisCount = 0;
                diff1 = 0;
                for (i=0; i<codes.length; i++) {
                    data = YAWA.getCodeInfoCache(codes[i].id);
                    if (data) {
                        libList = YAWA.analyzeLibraries(data.as3);
                        for (key in libList) {
                            if (!(key in libsHash)) libs.push(libsHash[key] = new TagInfo(key));
                            else libsHash[key].count++;
                        }
                        fanList = data.favorited;
                        for (p=0; p<fanList.length; p++) {
                            key = fanList[p].name;
                            if (!(key in fansHash)) fans.push(fansHash[key] = new TagInfo(key));
                            else fansHash[key].count++;
                        }
                        responseFork(data);
                        for (p=1; p<data.forked_pages; p++) {
                            YAWA.requestCodeInfo(responseFork, codes[i].id, "", p+1);
                        }
                    } else {
                        print("error on " + codes[i].id);
                    }
                }
                libs.sort(TagInfo.sorter);
                fans.sort(TagInfo.sorter);
                print("[libs]");
                print(libs.join(", "));
                print("[fans]");
                print(fans.splice(0,32).join(", "));
                print$("forked code analysis finished : " + String(finishAnalysisCount) + "/" + String(codeCount));
            }
        }
        
        private function responseFork(data:*) : void {
            var i:int, imax:int, forked:Array;
            if (data.cached_forked_count >= data.forked_count) {
                finishAnalysisCount++;
                print$("forked code analysis finished : " + String(finishAnalysisCount) + "/" + String(codeCount));
                if (data.forked) {
                    forked = data.forked;
                    for (i=0; i<forked.length; i++) {
                        if (forked[i].diff == 1) diff1 += forked[i].favorited_count;
                    }
                }
                if (finishAnalysisCount == codeCount) {
                    print("\ndiff:1 codes forked from " + userID + "'s code get favs : " + diff1);
                }
            }
        }
        
        
        private function print$(str:String) : void { tf.text = currentText + str; }
        private function print (str:String) : void { tf.text = (currentText += str + "\n"); }
    }
}




import flash.net.*;
import flash.events.*;
import flash.display.*;

function useYAWA(onReady:Function, swfurl:String="http://swf.wonderfl.net/swf/usercode/8/8f/8f46/8f46608d59b94c39bf42b94a89c1819f9e3bce61.swf") : void {
    var loader:Loader = new Loader();
    loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) : void { onReady(e.target.content); });
    loader.load(new URLRequest(swfurl + "?t=" + String(int(new Date().time))));
}

class TagInfo {
    public var tag:String;
    public var count:int;
    function TagInfo(tag:String) {
        this.tag = tag;
        this.count = 1;
    }
    public function toString() : String { return tag + ":" + count; }
    static public function sorter(a:TagInfo, b:TagInfo) : Number { return b.count - a.count; }
}
