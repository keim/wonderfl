package {
    import flash.display.*;
    import flash.events.*;
    import flash.net.*;
    import flash.system.*;
    import flash.text.*;


    /** Yet Another Wonderfl API */
    public class YAWA extends Sprite {
    // constants
    //--------------------------------------------------
        public const API_VERSION:String = "0.16";
    
        // options
        public const DAYS_1DAY:String      = "days=1day";
        public const DAYS_7DAYS:String     = "days=7days";
        public const DAYS_ALL:String       = "days=all";
        public const DAYS_OPTIONS:Array    = [DAYS_1DAY, DAYS_7DAYS, DAYS_ALL];
        public const ORDER_PV:String       = "order=pv";
        public const ORDER_FAVORITE:String = "order=favorite";
        public const ORDER_FORKED:String   = "order=forked";
        public const ORDER_OPTIONS:Array   = [ORDER_PV, ORDER_FAVORITE, ORDER_FORKED];
        public const USER_INFO_ACTIVITY:String = "";
        public const USER_INFO_CODE:String     = "/codes";
        public const USER_INFO_FAVORITE:String = "/favorites";
        public const USER_INFO_FOLLOWER:String = "/followers";
        public const USER_INFO_OPTIONS:Array   = [USER_INFO_ACTIVITY, USER_INFO_CODE, USER_INFO_FAVORITE, USER_INFO_FOLLOWER];

        // access url
        public const USER_RANKING_URL:String = "http://wonderfl.net/users";
        public const CODE_RANKING_URL:String = "http://wonderfl.net/codes";
        public const TAG_CLOUD_URL:String    = "http://wonderfl.net/tags";
        public const USER_URL:String         = "http://wonderfl.net/user/";
        public const CODE_URL:String         = "http://wonderfl.net/c/";
        public const TAG_URL:String          = "http://wonderfl.net/tag/";
        
        // wonderfl constant
        public var USER_INFO_CODE_PAR_PAGE:int = 12;
        public var CODE_INFO_CODE_PAR_PAGE:int = 8;
        public var TAG_INFO_CODE_PAR_PAGE:int = 40;
        
        // bookmarks of user parser
        public var PROFILE_START:String        = '<section id="sectProfile"';
        public var PROFILE_END  :String        = '<!-- / #sectProfile --></section>';
        public var FOLLOWING_START:String      = '<section id="sectFollowing">';
        public var FOLLOWING_END  :String      = '<!-- / #sectFollowing --></section>';
        public var POSTED_CODES_START:String   = '<div class="unitCodeGroup';
        public var POSTED_CODES_END  :String   = '<!-- /.unitCodeGroup --></div>';
        public var FAVORITE_CODES_START:String = '<div class="unitCodeGroup';
        public var FAVORITE_CODES_END  :String = '<!-- /.unitCodeGroup --></div>';
        public var FOLLOWERS_START:String      = '<div class="follower_box';
        public var FOLLOWERS_END  :String      = '</div>';        
        // bookmarks of code parser
        public var CODE_HEADER_START:String = '<header>';
        public var CODE_HEADER_END:String   = '</header>';
        public var RAW_AS3_START:String     = '<textarea id="raw_as3" style="display:none;">';
        public var RAW_AS3_END:String       = '</textarea>';
        public var TALK_START:String        = '<div id="talk_container"';
        public var TALK_END:String          = '<!-- /.groupTalk.group --></div>';
        public var SWF_START:String         = '<div id="swf">';
        public var SWF_END:String           = '</div>';
        public var FAV_START:String         = '<section id="sectFavBy"';
        public var FAV_END:String           = '<!-- /#sectFavBy --></section>';
        public var TAG_START:String         = '<ul class="listTag group">';
        public var TAG_END:String           = '</ul>';
        public var KEYWORD_START:String     = '<ul class="listKeywords group">';
        public var KEYWORD_END:String       = '</ul>';
        public var FORKED_CODE_START:String = '<div id="boxForkedCode"';
        public var FORKED_CODE_END:String   = '<!-- /#boxForkedCode --></div>';
        // bookmarks of tag parser
        public var TAG_LIST_START:String  = '<div class="unitCodeGroup';
        public var TAG_LIST_END:String    = '<!-- /.unitCodeGroup --></div>';
        public var TAG_COUNT_START:String = '<p class="search_meta">';
        
        
        /** library pathes */
        static public var libraryPathes:* = {
            "com.adobe"               : "as3corelib",
            "caurina.transitions"     : "tweener",
            "com.greensock"           : "tweenmax",
            "com.flashdynamix.motion" : "tweensy",
            "org.libspark.betweenas3" : "betweenas3",
            "net.kawa.tween"          : "ktween",
            "jp.progression"          : "progression",
            "org.libspark.thread"     : "thread",
            "net.hires.debug"         : "stats",
            "org.papervision3d"       : "papervision3d",
            "sandy."                  : "sandy3d",
            "alternativa."            : "alternativa3d",
            "away3d."                 : "away3d",
            "net.badimon.five3d"      : "five3d",
            "Box2D."                  : "box2d",
            "jiglib."                 : "jiglib",
            "org.libspark.swfassist"  : "swfassist",
            "camo.core"               : "flashcamouflage",
            "com.bit101.components"   : "minimalcomps",
            "net.user1"               : "union",
            "org.si.sion"             : "sion",
            "idv.cjcat.stardust"      : "stardust",
            "funnel."                 : "funnel",
            "com.modestmaps"          : "modestmaps",
            "com.google.maps"         : "googlemaps",
            "com.afcomponents.umap"   : "umap",
            "com.sony.jp.felica"      : "felica",
            "org.as3lib.kitchensync"  : "kitchensync",
            "com.actionsnippet.qbox"  : "quickbox2d",
            "net.wonderfl.score"      : "scoreranking",
            "org.libspark.flartoolkit": "flartoolkit",
            "com.desuade.motion"      : "desuademotion",
            "com.desuade.partigen"    : "desuadepartigen",
            "frocessing"              : "frocessing",
            "org.flintparticles"      : "flint",
            "net.wonderfl.utils"      : "wonderflutils",
            "flupie.textanim"         : "textanim",
            "de.polygonal"            : "polygonal",
            "com.pblabs"              : "pushbuttonengine",
            "com.codeazur.as3swf"     : "as3swf",
            "ru.inspirit.surf"        : "assurf",
            "flash.geom.Bezier"       : "bezier",
            "sliz."                   : "miniui",
            "org.libspark.ukiuki"     : "ukiuki",
            "idv.cjcat.signals"       : "cjsignals",
            "com.useitbetter"         : "useitbetteranalytics",
            "com.demonsters.debugger" : "monsterdebugger",
            "org.si.cml"              : "cannonml",
            "org.flixel"              : "flixel"
        };
        /** regular expression for libraries, set null to reconstuct */
        static public var libraryPathesRegExp:RegExp = null;
        
        
        
        
    // variables & properties
    //--------------------------------------------------
        /** proxy url */
        public var proxyURL:String = 'http://www.gmodules.com/ig/proxy?url=';
        /** proxy domain */
        public var proxyDomain:String = 'www.gmodules.com';
        /** api entry in proxy surver */
        public var apiEntry:* = undefined;
        /** maximum trial count when error occurs. */
        public var maxTrialCount:int = 3;

        // suspend while loading api entry
        private var _suspendList:Array = [];
        
        // cache
        private var _userInfoCache:* = {};
        private var _codeInfoCache:* = {};
        private var _tagsInfoCache:* = {};
        
        // loaderInfo.url
        private var loaderInfo_url:String = "http://swf.wonderfl.net/swf/usercode/8/8f/8f46/8f46608d59b94c39bf42b94a89c1819f9e3bce61.swf";
        
        
        
    // constructor
    //--------------------------------------------------
        public function YAWA() {
            var domain:String = new LocalConnection().domain;

            if (domain == proxyDomain) {
                Security.allowDomain("*");
                // execute on proxy
                apiEntry = this;
                addEventListener(Event.ADDED_TO_STAGE, function (e:Event) : void {
                    var tf:TextField = new TextField();
                    tf.width = stage.stageWidth;
                    tf.text = "proxy available (ver" + API_VERSION + ")";
                    addChild(tf);
                });
            } else {
                // execute not on proxy
                var loader:Loader = new Loader();
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) : void {
                    apiEntry = loader.content;
                    for (var i:int=0; i<_suspendList.length; i++) apiEntry._loadOnProxy(_suspendList[i]);
                    _suspendList = [];
                });
                //loader.load(_proxyRequest(loaderInfo.url));
                loader.load(_proxyRequest(loaderInfo_url + "?v=" + API_VERSION));
                _suspendList = [];
                
                // test
                if (stage) _test(this);
            }
        }
        
        
        

    // interfaces
    //--------------------------------------------------
        /** Request to get global user ranking.
         *  @param responseHandler response handler, requires function(data:*) : void.
         *  @param days range to search
         *  @param order ranking order
         *  @param page page index, 10 users in 1 page
         *  @return URLLoader to load
         */
        public function requestUserRanking(responseHandler:Function, days:String=DAYS_7DAYS, order:String=ORDER_FAVORITE, page:int=1) : URLLoader {
            return load(getUserRankingURL(days, order, page), responseHandler, userRankingParser, [days, order, page]);
        }


        /** Request to get global code ranking.
         *  @param responseHandler response handler, requires function(data:*) : void.
         *  @param days range to search
         *  @param order ranking order
         *  @param page page index, 10 codes in 1 page
         *  @return URLLoader to load
         */
        public function requestCodeRanking(responseHandler:Function, days:String=DAYS_7DAYS, order:String=ORDER_FAVORITE, page:int=1) : URLLoader {
            return load(getCodeRankingURL(days, order, page), responseHandler, codeRankingParser, [days, order, page]);
        }


        /** Request to get tag cloud information.
         *  @param responseHandler response handler, requires function(data:*) : void.
         *  @return URLLoader to load
         */
        public function requestTagCloud(responseHandler:Function) : URLLoader {
            return load(getTagCloudURL(), responseHandler, tagCloudParser, null);
        }


        /** Request to get user information.
         *  @param responseHandler response handler, requires function(data:*) : void.
         *  @param userID user id
         *  @param infoType information type
         *  @param page page index of codes, valid when infoType is USER_INFO_CODES or USER_INFO_FAVORITE, 12 codes par 1 page
         *  @return URLLoader to load
         */
        public function requestUserInfo(responseHandler:Function, userID:String, infoType:String=USER_INFO_CODE, page:int=1) : URLLoader {
            return load(getUserURL(userID, infoType, page), responseHandler, userParser, [userID, infoType, page]);
        }


        /** Request to get code information.
         *  @param responseHandler response handler, requires function(data:*) : void.
         *  @param codeID code id
         *  @param order order of forked codes (N/A)
         *  @param page page index of forked codes, 12 codes par 1 page
         *  @return URLLoader to load
         */
        public function requestCodeInfo(responseHandler:Function, codeID:String, order:String=ORDER_FAVORITE, page:int=1) : URLLoader {
            return load(getCodeURL(codeID, order, page), responseHandler, codeParser, [codeID, order, page]);
        }


        /** Request to get user information.
         *  @param responseHandler response handler, requires function(data:*) : void.
         *  @param tag tag string
         *  @param page page index of codes, 40 codes par 1 page
         *  @return URLLoader to load
         */
        public function requestTagInfo(responseHandler:Function, tag:String, page:int=1) : URLLoader {
            return load(getTagURL(tag, page), responseHandler, tagParser, [tag, page]);
        }
        
        
        
        
    // cache operations
    //--------------------------------------------------
        /** get cached user info */
        public function getUserInfoCache(userID:String) : * { return _userInfoCache[userID]; }
        
        
        /** get cached code info */
        public function getCodeInfoCache(codeID:String) : * { return _codeInfoCache[codeID]; }
        
        
        /** get cached tag info */
        public function getTagsInfoCache(tag:String) : * { return _tagsInfoCache[tag]; }
        
        
        /** clear all cache */
        public function clearCache() : void {
            _userInfoCache = {};
            _codeInfoCache = {};
            _tagsInfoCache = {};
        }
        



    // url constructor
    //--------------------------------------------------
        public function getUserRankingURL(days:String=DAYS_7DAYS, order:String=ORDER_FAVORITE, page:int=1) : String { return USER_RANKING_URL + "?" + days + "&" + order + "&page=" + page.toString(); }
        public function getCodeRankingURL(days:String=DAYS_7DAYS, order:String=ORDER_FAVORITE, page:int=1) : String { return CODE_RANKING_URL + "?" + days + "&" + order + "&page=" + page.toString(); }
        public function getTagCloudURL() : String { return TAG_CLOUD_URL + "?a=0"; }
        public function getUserURL(userID:String, infoType:String=USER_INFO_CODE, page:int=1) : String { return USER_URL + userID + infoType + "?page=" + page.toString(); }
        public function getCodeURL(codeID:String, order:String=ORDER_FAVORITE, page:int=1) : String { return CODE_URL + codeID + "?" + order + "&page=" + page.toString(); }
        public function getTagURL(tag:String, page:int=1) : String { return TAG_URL + tag + "?page=" + page.toString(); }
        
        
        
        
    // XHTML parser
    //--------------------------------------------------
        /** user ranking parser, args=[days, order, page]; */
        public function userRankingParser(html:String, args:Array) : * {
            var list:XMLList = getElementByClass(_cutout(html)..div, "unitUserRank"),
                result:Array = [], i:int, imax:int = list.length(), j:int, jmax:int, elem:XML, codes:XMLList, 
                user:*, propName:String, codeInfo:Array, str:String;
            result["html"] = html;
            result.length = imax;
            switch (args[1]) {
            case ORDER_PV:       propName = "codes_count";     break;
            case ORDER_FAVORITE: propName = "favorited_count"; break;
            case ORDER_FORKED:   propName = "forked_count";    break;
            }
            for (i=0; i<imax; i++) {
                elem = list[i];
                codes = $class(elem.dl, 'unitRankCode');
                jmax = codes.length();
                codeInfo = new Array(jmax);
                for (j=0; j<jmax; j++) codeInfo[j] = _smallCodeInfo(codes[j].dt.a[0]);
                user = _smallUserInfo($class(elem.p, "user")[0]);
                user[propName] = getNumber(String($class(elem.ul, "data").li.a[0]));
                result[i] = {
                    "rank"  : int($class(elem.p, 'txtRank')),
                    "user"  : user,
                    "codes" : codeInfo};
            }
            return result;
        }
        
        
        /** code ranking parser, args=[days, order, page]; */
        public function codeRankingParser(html:String, args:Array) : * {
            var list:XMLList = getElementByClass(_cutout(html)..div, "unitRank"),
                result:Array = [], code:*, i:int, imax:int = list.length(), elem:XML, data:XMLList;
            result["html"] = html;
            result.length = imax;
            for (i=0; i<imax; i++) {
                elem = list[i];
                result[i] = {
                    "rank" : int($class(elem.p, 'txtRank')),
                    "user" : _smallUserInfo($class(elem.p, "user")[0]),
                    "code" : _codeInfo(elem)
                };
            }
            return result;
        }
        
        
        /** tag cloud parser, args=null; */
        public function tagCloudParser(html:String, args:Array) : * {
            var list:XMLList = $class(_cutout(html)..ul, "listTag").li,
                result:Array = [], i:int, imax:int = list.length(), elem:XML, count:String;
            result["html"] = html;
            for (i=0; i<imax; i++) {
                elem = list[i].a[0];
                count = String(elem.span);
                result[i] = {
                    "tag"   : String(elem.@title),
                    "url"   : "http://wonderfl.net/tag/" + encodeURIComponent(elem.@title),
                    "count" : int(count.substring(1,count.length-1))
                };
            }
            return result;
        }
        
        
        /** user info parser, args=[userID, infoType, page]; */
        public function userParser(html:String, args:Array) : * {
            var prof:XML, result:*, elem:XML, basic:XML, data:XMLList, i:int, imax:int, array:Array,
                userID:String = args[0], codeCount:int, favoritesCount:int;
            if (!(userID in _userInfoCache)) {
                prof = _cutout(html, PROFILE_START, PROFILE_END);
                if (!prof) return {"error" : "Invalid user ID"};
                basic = $id(prof.div, 'boxProfBasic')[0];
                data  = $class($id(prof.div, 'boxProfInfo').ul, 'data')[0].li;
                codeCount      = getNumber(data[0].a[0] || data[0]);
                favoritesCount = getNumber(data[2].a[0] || data[2]);
                _userInfoCache[userID] = {
                    "html" : html,
                    "name" : userID, 
                    "url"  : "http://wonderfl.net/user/" + userID,
                    "icon" : "http://wonderfl.net" + String(basic..img[0].@src),
                    "codes_count": codeCount,
                    "forked_count": getNumber(data[1].a[0] || data[1]),
                    "favorites_count" : favoritesCount,
                    "following_count" : getNumber(data[3].a[0] || data[3]),
                    "followers_count" : getNumber(data[4].a[0] || data[4]),
                    "codes_pages"     : int((codeCount + USER_INFO_CODE_PAR_PAGE - 1) / USER_INFO_CODE_PAR_PAGE),
                    "favorites_pages" : int((favoritesCount + USER_INFO_CODE_PAR_PAGE - 1) / USER_INFO_CODE_PAR_PAGE),
                    "external_url": String(data[5].a[0] || null),
                    "description": String(data[6]).replace(/<.+?>/g,""),
                    "cached_codes_count" : 0,
                    "cached_favorites_count" : 0
               };
            }
            result = _userInfoCache[userID];
            if ("current_page" in result) delete result["current_page"];

            switch(args[1]) {
            case USER_INFO_ACTIVITY:
                result = {error:"USER_INFO_ACTIVITY is not supported currently"};
                break;
            case USER_INFO_FOLLOWER:
                if (!("followers" in result)) result["followers"] = _getUserInfomations(html, FOLLOWERS_START, FOLLOWERS_END);
                break;
            case USER_INFO_CODE:
                result["cached_codes_count"] += _getCodeInfomations(html, POSTED_CODES_START, POSTED_CODES_END, result, "codes", args[2]);
                result["current_page"] = args[2];
                break;
            case USER_INFO_FAVORITE:
                result["cached_favorites_count"] += _getCodeInfomations(html, FAVORITE_CODES_START, FAVORITE_CODES_END, result, "favorites", args[2], true);
                result["current_page"] = args[2];
                break;
            }

            return result;
        }
        private function _getUserInfomations(html:String, start:String, end:String) : Array {
            var xhtml:XML = _cutout(html, start, end);
            if (!xhtml) return [];
            var data:XMLList = xhtml.ul.li.span.a, elem:XML; 
            var i:int, imax:int = data.length(), array:Array = new Array(imax);
            for (i=0; i<imax; i++) {
                elem = data[i];
                array[i] = {
                    "name" : String(elem.@title),
                    "url"  : String(elem.@href),
                    "icon" : "http://wonderfl.net" + String(elem.img.@src)
                };
            }
            return array;
        }
        private function _getCodeInfomations(html:String, start:String, end:String, result:*, prop:String, page:int, withUserInfo:Boolean=false) : int {
            var data:XMLList = $class(_cutout(html, start, end).div, "unitCode"), codeIndex:int, elem:XML, url:String, 
                i:int, imax:int = data.length(), codeList:Array = result[prop] || new Array();
            codeIndex = (page-1) * USER_INFO_CODE_PAR_PAGE;
            for (i=0; i<imax; i++, codeIndex++) {
                elem = data[i];
                codeList[codeIndex] = _codeInfo(elem);
                if (withUserInfo) {
                    elem = $class(elem.p, "user")[0];
                    url = String(elem.a[0].@href);
                    codeList[codeIndex]["user"] = {
                        "url"  : url,
                        "name" : url.substr(url.lastIndexOf("/") + 1),
                        "icon" : "http://wonderfl.net" + String(elem..img.@src)
                    };
                }
            }
            result[prop] = codeList;
            return imax;
        }
        
        
        /** code info parser, args=[codeID, order, page]; */
        public function codeParser(html:String, args:Array) : * {
            var header:XML, codeID:String = args[0], page:int = args[2], 
                swfCont:XML, tagCont:XML, keyCont:XML, frkCont:XML, forkList:XMLList, forkArray:Array, forkedCount:int, thumbBase:String, date:String, 
                tlkCont:XML, commentList:XMLList, comments:Array, favCont:XML, favUserList:XMLList, favUser:Array, userInfo:*, 
                result:*, divForkedFrom:XML, divHeaderInfo:XML, data:XMLList, parent:* = null, url:String, raw_as3:String = "", startIndex:int, endIndex:int,
                i:int, imax:int, codeIndex:int, userInfoList:XMLList;
               
            if (!(codeID in _codeInfoCache)) {
                header = _cutout(html, CODE_HEADER_START, CODE_HEADER_END);
                if (!header) return {"error" : "Invalid code ID. [" + codeID + "]"};

                divForkedFrom = $id(header.div, 'boxForked')[0];
                if (divForkedFrom) {
                    url = String(divForkedFrom..a[1].@href);
                    parent = {"title"    : String(divForkedFrom..a[1]),
                              "url"      : url,
                              "id"       : url.substr(url.lastIndexOf("/")+1),
                              "user"     : { "name":String(divForkedFrom..a[0].@title), "url":String(divForkedFrom..a[0].@href) },
                              "diff"     : getNumber(divForkedFrom..a[2])};
                }

                divHeaderInfo = getElementByClass(header.div, "headerInfo")[0];
                data = divHeaderInfo.ul[0].ul[0].li;
                startIndex = html.indexOf(RAW_AS3_START);
                if (startIndex >= 0) {
                    endIndex = html.indexOf(RAW_AS3_END, startIndex);
                    if (endIndex >= 0) raw_as3 = html.substring(startIndex+RAW_AS3_START.length, endIndex);
                }
                
                swfCont = _cutout(html, SWF_START, SWF_END);
                tlkCont = _cutout(html, TALK_START, TALK_END);
                favCont = _cutout(html, FAV_START, FAV_END);
                tagCont = _cutout(html, TAG_START, TAG_END);
                keyCont = _cutout(html, KEYWORD_START, KEYWORD_END);

                comments = [];
                if (tlkCont) {
                    commentList = getElementByClass(tlkCont.div, "unitTalk");
                    imax = commentList.length();
                    for (i=0; i<imax; i++) {
                        userInfoList = commentList[i].ul[0].li;
                        comments.push({"text" : decodeHtmlEscape(String(commentList[i].p[0]).replace(/<.+?>/g,"")),
                                       "user" : {"name" : String(userInfoList[0].a[0]),
                                                 "url"  : String(userInfoList[0].a[0].@href),
                                                 "icon" : "http://wonderfl.net" + String(userInfoList[0].span[0].a[0].img.@src)},
                                       "date" : String(userInfoList[1]).substr(3)});
                    }
                }

                favUser = [];
                if (favCont) {
                    favUserList = $class(favCont..div, "unitFavBy");
                    imax = favUserList.length();
                    for (i=0; i<imax; i++) favUser.push(_smallUserInfo(favUserList[i].span[0]));
                    favUserList = getElementByClass(favCont.div, "unitFavUserL");
                    imax = favUserList.length();
                    for (i=0; i<imax; i++) {
                        userInfo = _smallUserInfo(favUserList[i].p[0].span[0]);
                        userInfo["comment"] = String(favUserList[i].p[1].text()[0] || "");
                        userInfo["tags"] = _getTagsInFavComment(favUserList[i].p[1].a);
                        favUser.push(userInfo);
                    }
                }

                forkedCount = getNumber(data[0].a[0] || data[0]);
                thumbBase = _thumbBaseURL(swfCont.img.@src);
                date = date$;
                
                _codeInfoCache[codeID] = {
                    "html"        : html,
                    "id"          : codeID,
                    "url"         : "http://wonderfl.net/c/" + codeID,
                    "title"       : String(divHeaderInfo.h1[0]),
                    "description" : String($class(divHeaderInfo.p, "description")[0]).replace(/<.+?>/g,""),
                    "thumb"       : thumbBase + ".jpg?t=" + date,
                    "thumb_w"     : thumbBase + "_w.jpg?t=" + date,
                    "thumb_100"   : thumbBase + "_100.jpg?t=" + date,
                    "user"        : _smallUserInfo($class(divHeaderInfo.p, "user").span[0]),
                    "forked_count"    : forkedCount,
                    "favorited_count" : getNumber(data[1].a[0] || data[1]),
                    "lines"           : getNumber(data[2].a[0] || data[2]),
                    "license"         : String(data[3].a[0]) || getString(data[3]),
                    "modified"        : getString(data[4]),
                    "forked_pages"    : int((forkedCount + CODE_INFO_CODE_PAR_PAGE - 1) / CODE_INFO_CODE_PAR_PAGE),
                    "parent"          : parent,
                    "as3"             : decodeHtmlEscape(raw_as3), 
                    "comments"        : comments,
                    "favorited"       : favUser,
                    "tags"            : (tagCont) ? _tagInfo(tagCont.li) : [],
                    "keywords"        : (keyCont) ? _tagInfo(keyCont.li) : [],
                    "cached_forked_count" : 0
                };
            }
            result = _codeInfoCache[codeID];

            if (!("forked" in result)) result["forked"] = [];
            
            frkCont = _cutout(html, FORKED_CODE_START, FORKED_CODE_END);
            if (frkCont) {
                forkArray = result["forked"];
                forkList = $class(frkCont.div[0].div, "unitCode");
                imax = forkList.length();
                codeIndex = (page - 1) * CODE_INFO_CODE_PAR_PAGE;
                for (i=0; i<imax; i++, codeIndex++) forkArray[codeIndex] = _codeInfo(forkList[i], false);
                result["cached_forked_count"] += imax;
            }
            
            return result;
        }
        private function _getTagsInFavComment(atags:XMLList) : Array {
            var imax:int=atags.length(), res:Array=new Array(imax), i:int;
            for (i=0; i<imax; i++) res[i] = String(atags[i]);
            return res; 
        }

        
        /** tag info parser, args=[tag, page]; */
        public function tagParser(html:String, args:Array) : * {
            var list:XMLList = $class(_cutout(html)..div, "unitCode"), 
                tag:String = args[0], page:int = args[1],  
                i:int, imax:int = list.length(), codeIndex:int, result:*, codes:Array;
            if (!(tag in _tagsInfoCache)) {
                var tagCountStart:int = html.indexOf(TAG_COUNT_START);
                if (tagCountStart == -1) return {"error":"Invalid tag"};
                var count:int = int(html.substr(tagCountStart+TAG_COUNT_START.length, 30).match(/\d+/g)[2]);
                _tagsInfoCache[tag] = { "html"        : html,
                                        "tag"         : tag,
                                        "url"         : "http://wonderfl.net/tag/" + encodeURIComponent(tag),
                                        "codes_count" : count,
                                        "codes_pages" : int((count + TAG_INFO_CODE_PAR_PAGE - 1) / TAG_INFO_CODE_PAR_PAGE),
                                        "codes"       : [],
                                        "cached_codes_count" : 0};
            }
            result = _tagsInfoCache[tag];
            codes = result["codes"];
            codeIndex = (page-1) * TAG_INFO_CODE_PAR_PAGE;
            for (i=0; i<imax; i++, codeIndex++) codes[codeIndex] = _codeInfo(list[i]);
            result["cached_codes_count"] += imax;
            return result;
        }
        
        
        
        
    // html parser sub routines
    //--------------------------------------------------
        // small code information
        private function _smallCodeInfo(atag:XML) : * { 
            var url:String = String(atag.@href),
                thumbBase:String = _thumbBaseURL(atag.img[0].@src),
                date:String = date$;
            return {"thumb"     : thumbBase + ".jpg?t=" + date, 
                    "thumb_w"   : thumbBase + "_w.jpg?t=" + date, 
                    "thumb_100" : thumbBase + "_100.jpg?t=" + date, 
                    "title" : String(atag.@title),
                    "url"   : url,
                    "id"    : url.substr(url.lastIndexOf("/")+1)};
        }
        
        
        // code information
        private function _codeInfo(elem:XML, tag:Boolean=true) : * { 
            var data:XMLList = $class(elem..ul, 'data')[0].li;
            var code:* = _smallCodeInfo($class(elem..p, 'thumb')[0].a[0]);
            code["pv"]     = int($class(elem..p, 'pv').a.span[0]);
            code["forked_count"]    = getNumber(data[0].a[0] || data[0]);
            code["favorited_count"] = getNumber(data[1].a[0] || data[1]);
            code["lines"]           = getNumber(data[2].a[0] || data[2]);
            if (tag) code["tags"] = (data.length() == 4) ? _tagInfo(data[3].ul.li) : [];
            else     code["diff"] = getNumber(data[2].strong[0].a[0] || data[2].strong[0]);
            return code;
        }
        
        
        // small user information
        private function _smallUserInfo(ue:XML) : * {
            return {"name" : String(ue.a[0].@title), 
                    "url"  : String(ue.a[0].@href),
                    "icon" : "http://wonderfl.net" + String(ue..img.@src)};
        }
        
        
        // tag infomation
        private function _tagInfo(te:XMLList) : Array { 
            var imax:int = te.length(), res:Array = new Array(imax), i:int;
            for (i=0; i<imax; i++) res[i] = String(te[i].a[0]);
            return res; 
        }
        
        
        // normalize thumbnail url
        private function _thumbBaseURL(url:String) : String {
            return url.replace(/_?(100|w)\.jpg(\?t=\d+)?$/, "");
        }
        
        
        
        
    // utilities
    //--------------------------------------------------
        /** load over crossdomain policy
         *  @param url url to load
         *  @param responseHandler function to deal result, function(data:*) : void
         *  @param parser function to parse, function(html:String, parserArgs:Array) : *
         *  @param parserArgs arguments for parser.
         */
        public function load(url:String, responseHandler:Function, parser:Function=null, parserArgs:Array=null) : URLLoader {
            var req:RequestHandler = new RequestHandler(url, responseHandler, _onRequestError, parser, parserArgs);
            if (apiEntry) return apiEntry._loadOnProxy(req);
            _suspendList.push(req);
            return req.loader;
        }
        
                
        /** add indent to json text */
        public function jsonIndentor(json:String, tabIndent:int=2) : String { 
            var indent:int = 0, tab:String = "", i:int;
            return json.replace(/[,[\]{}]/g, function(str:String, idx:int, tgt:String) : String {
                switch (str) {
                case "[": case "{": 
                    indent += tabIndent;
                    for (tab="", i=0; i<indent; i++) tab += " ";
                    break;
                case "]": case "}": 
                    indent -= tabIndent;
                    for (tab="", i=0; i<indent; i++) tab += " ";
                    break;
                }
                return str + "\n" + tab;
            });
        }
        
        
        /** decode HTML escape */
        public function decodeHtmlEscape(str:String) : String { 
            if (!_htmlEscapeRex) {
                var keys:Array=[];
                for (var key:String in _htmlEscapeHash) keys.push(key);
                _htmlEscapeRex = new RegExp("&(" + keys.join("|") + ";)", "g");
            }
            return str.replace(_htmlEscapeRex, function(s:String, c:String, i:int, t:String) : String {
                return (c in _htmlEscapeHash) ? _htmlEscapeHash[c] : s;
            });
        }
        protected var _htmlEscapeHash:* = { "nbsp":" ", "lt":"<" , "gt":">", "amp":"&", "quot":'"', "apos":"'" };
        private   var _htmlEscapeRex:RegExp = null;
        
        
        /** analyze libraries */
        public function analyzeLibraries(as3code:String) : * {
            if (!libraryPathesRegExp) {
                var keys:Array = [];
                for (var key:String in libraryPathes) keys.push(key.replace(/\./g, "\\."));
                libraryPathesRegExp = new RegExp("^\\s*import\\s+(" + keys.join("|") + ")", "gm");
            }
            var res:*, libs:* = {};
            while (res = libraryPathesRegExp.exec(as3code)) libs[libraryPathes[res[1]]] = true;
            return libs;
        }
        
        
        /** Unix time String */
        public function get date$() : String { return String(uint(new Date().time)); }
        
        
        // XHTML operators
        public function getElementByClass(xhtml:XMLList, className:String) : XMLList { return xhtml.(attribute('class').toString().search(className) != -1); }
        public function getNumber(str:String) : int { return int(str.match(/\d+/)[0]); }
        public function getString(str:String) : String { return /:\s*(.+)/.exec(str)[1]; }
        public function $class(xhtml:XMLList, className:String) : XMLList { return xhtml.(attribute('class') == className); }
        public function $id(xhtml:XMLList, idName:String) : XMLList { return xhtml.(attribute('id') == idName); }
        
        
        
        
    // internal use
    //--------------------------------------------------
        // convert html to xhtml
        private function _cutout(html:String, start:String="<body", end:String="</body>") : XML {
            var startIndex:int = html.indexOf(start);
            if (startIndex == -1) return null;
            var endIndex:int = html.indexOf(end, startIndex);
            if (endIndex == -1) return null;
            return new XML(html.substring(startIndex, endIndex + end.length));
        }
        
        
        // Google proxy Copyright wh0 ( http://wonderfl.net/c/gJXA )
        private function _proxyRequest(url:String) : URLRequest {
            return new URLRequest(proxyURL + encodeURIComponent(url));
        }
        
        
        /** @private */
        public function _loadOnProxy(request:*) : URLLoader {
            request.loader.load(_proxyRequest(request.url+"&t=" + date$));
            return request.loader;
        }
        
        
        //
        private function _onRequestError(request:RequestHandler) : Boolean {
            if (++request.trialCount == maxTrialCount) return true;
            apiEntry._loadOnProxy(request);
            return false;
        }
    }
}



import flash.display.*;
import flash.events.*;
import flash.text.*;
import flash.net.URLLoader;
import com.bit101.components.*;


// request handler
class RequestHandler {
    public var url:String;
    public var trialCount:int = 0;
    public var loader:URLLoader = new URLLoader();
    private var _responseHandler:Function, _errorHandler:Function;
    private var _parser:Function;
    private var _parserArgs:Array;
    function RequestHandler(url:String, responseHandler:Function, errorHandler:Function, parser:Function, parserArgs:Array) {
        this.url = url;
        _responseHandler = responseHandler;
        _errorHandler = errorHandler;
        _parser = parser || _defaultParser;
        _parserArgs = parserArgs || [];
        loader.addEventListener(Event.COMPLETE, onLoaded);
        loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
        loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    }
    public function onLoaded(e:Event) : void {
        var data:* = _parser(e.target.data, _parserArgs);
        if ("error" in data) _error(data["error"]);
        else {
            _responseHandler(data);
            _removeAllHandlers();
        }
    }
    public function onError(e:ErrorEvent)  : void { _error(e.text); }
    private function _defaultParser(html:String, args:Array) : * { return html; }
    private function _error(errorText:String) : void {
         if (_errorHandler(this)) {
             _responseHandler({"error" : errorText, "trial_count" : trialCount});
             _removeAllHandlers();
         }
    }
    private function _removeAllHandlers() : void {
        loader.removeEventListener(Event.COMPLETE, onLoaded);
        loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
    }
}


// test
var apiIndex:int = 0;
var page:InputText;
var order:ComboBox;
var days:ComboBox;
var userID:InputText;
var type:ComboBox;
var codeID:InputText;
var tag:InputText;
var showhtml:CheckBox;
var getter:PushButton;

function _test(api:*) : void {
    var parent:Sprite = api, 
        tf:TextField, 
        p1:HBox = new HBox(parent, 60, 20), 
        p3:HBox = new HBox(parent, 60, 20), 
        p4:HBox = new HBox(parent, 60, 20),
        p5:HBox = new HBox(parent, 60, 20);
    p3.visible = p4.visible = p5.visible = !(p1.visible = true);
    Component.initStage(parent.stage);
    tf = new TextField();
    tf.y = 40;
    tf.width = parent.stage.stageWidth;
    tf.height = parent.stage.stageHeight - tf.y;
    tf.multiline = true;
    tf.defaultTextFormat = new TextFormat("_sans", 12);
    
    tf.text = parent.loaderInfo.url; //parent.proxyURL + encodeURIComponent(parent.loaderInfo.url);
    parent.addChild(tf);

    _hradio(parent, 0, 0, ["UserRanking", "CodeRanking", "TagCloud", "UserInfo", "CodeInfo", "TagInfo"], "api", function(e:Event) : void {
        switch (apiIndex = e.target.tag) {
        case 0: 
        case 1: p3.visible = p4.visible = p5.visible = !(p1.visible = true); break;
        case 2: p3.visible = p4.visible = p5.visible = p1.visible = false;   break;
        case 3: p1.visible = p4.visible = p5.visible = !(p3.visible = true); break;
        case 4: p3.visible = p1.visible = p5.visible = !(p4.visible = true); break;
        case 5: p3.visible = p4.visible = p1.visible = !(p5.visible = true); break;
        }
    });
    new Label(parent, 0, 20, "page");
    page = new InputText(parent, 24, 22, "1");
    page.width = 34;
    getter = new PushButton(parent, 400, 20, "getData", _getData);
    getter.width = 65;
    showhtml = new CheckBox(parent, 350, 24, "html");
    showhtml.width = 50;
    order = new ComboBox(p1, 0, 0, "ORDER_FAVORITE");
    order.items = ["ORDER_PV", "ORDER_FAVORITE", "ORDER_FORKED"];
    order.selectedIndex = 1;
    days  = new ComboBox(p1, 0, 0, "DAYS_7DAYS");
    days.items = ["DAYS_1DAY", "DAYS_7DAYS", "DAYS_ALL"];
    days.selectedIndex = 1;
    userID = new InputText(p3, 0, 0, parent.loaderInfo.parameters["viewer.displayName"]);
    type = new ComboBox(p3, 0, 0, "USER_INFO_ACTIVITY");
    type.items = ["USER_INFO_ACTIVITY", "USER_INFO_CODE", "USER_INFO_FAVORITE", "USER_INFO_FOLLOWER"];
    type.selectedIndex = 0;
    codeID = new InputText(p4, 0, 0, "krt3");
    tag    = new InputText(p5, 0, 0, "sion");
    
    function _hradio(doc:DisplayObjectContainer, xpos:Number, ypos:Number, labels:Array, groupName:String, selected:Function) : HBox {
        var hbox:HBox = new HBox(doc, xpos, ypos), i:int, imax:int = labels.length;
        for (i=0; i<imax; i++) {
            var rb:RadioButton = new RadioButton(hbox, 0, 0, labels[i], (i==0), selected);
            rb.groupName = groupName;
            rb.tag = i;
        }
        return hbox;
    }
    
    function _getData(e:Event) : void {
        var pageIndex:int = int(page.text) || 1;
        switch (apiIndex) {
        case 0: api.requestUserRanking(_response, api.DAYS_OPTIONS[days.selectedIndex], api.ORDER_OPTIONS[order.selectedIndex], pageIndex); break;
        case 1: api.requestCodeRanking(_response, api.DAYS_OPTIONS[days.selectedIndex], api.ORDER_OPTIONS[order.selectedIndex], pageIndex); break;
        case 2: api.requestTagCloud(_response); break;
        case 3: api.requestUserInfo(_response, userID.text, api.USER_INFO_OPTIONS[type.selectedIndex], pageIndex); break;
        case 4: api.requestCodeInfo(_response, codeID.text, api.ORDER_FAVORITE, pageIndex); break;
        case 5: api.requestTagInfo(_response, tag.text, pageIndex); break;
        }
    }
    
    function _response(data:*) : void {
        if (showhtml.selected) tf.text = data.html;
        else {
            delete data.html;
            if ("as3" in data) {
                data["library"] = api.analyzeLibraries(data["as3"]);
                data["as3"] = "...snip...";
            }
            tf.text = api.jsonIndentor(JSON.stringify(data));
        }
        api.clearCache();
    }
}
