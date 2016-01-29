// source code in 4084 bytes
package{public class w extends Sprite{function w(){_=this;$=stage;$[a$]("keyDown",function(e){ik|=1<<(e.keyCode&3)});$[a$]("keyUp",function(e){ik&=~(1<<(e.keyCode&3))});$=$.stage3Ds[0];$[a$]("context3DCreate",function(){_[a$]("enterFrame",function(){n=(tm-(tm=gt()));ra+=rt=(rt+((ik&8)/4-(ik&2))*n*.002)*.9;k=h(px,py)/8+3;if(pz<k)vz=(k-pz)/3;pz+=vz+=((ik&1)-pz/30)/10-.01;a=ra*.0175;m=Math;sp=(sp+(ik&4)/2000)*.9;n*=-(sp+.005);px+=(dx=m.cos(a))*n;py+=(dy=m.sin(a))*n;m3.copyFrom(pm);_=m3.prependRotation;_(pz-105,v.X_AXIS);_(rt*8,v.Y_AXIS);_(90-ra-rt*8,v.Z_AXIS);with($){a=setTextureAt;b=setVertexBufferAt;c=setProgramConstantsFromMatrix;d=drawTriangles;e=setProgram;clear(1/4,3/8,.5,1);e(p1);a(0,t2);a(1,f);b(0,sv,0,m="float3");b(1,sv,3,n="float2");c(v$,0,m3,t);d(si);_=m3.prependTranslation;_(-px,-py,-pz);e(p0);a(0,t0);a(1,t1);ix=px>>5;iy=py>>5;for(i=-7;i<8;i++)for(j=-7;j<8;j++){k=(ix+i)*32+16;l=(iy+j)*32+16;if((k-px)*dx+(l-py)*dy>-20){o=(ix+i&15)+(iy+j&15)*16;b(0,vb[o],0,m);b(1,vb[o],3,n);_(k,l,0);c(v$,0,m3,t);_(-k,-l,0);d(ib)}}present()}});p.perlinNoise(64,64,7,gt(),t,t,7,t);$=$.context3D;$.configureBackBuffer(450,450,0,t);c=$.createProgram;(p0=c()).upload(q("78da5d8c3b0ec0200c431dc8d04e59b958ef57d69e8b7b401ca88afa064b963fb700a82820965c1a264df062993ee18fa97cfd20871eac76ca093cfc995b55f7d7fa8d9c7dd97e3cefcc071a530a56"),q("78da6d8ed10d80200c44af05a37fe8160ea4fb49e2177339886d0141e325d0f25aae3d0840a415aac0726d1e5903e6453909a70f77c6bdf2c485d3735edca2fa70f6b137990fe0f24f6b2dfd3bff70ea386364c9cf3ab7c549d354f76c0a4e0a1777e406d8f508e6"));a=new AGALMiniAssembler().assemble;(p1=c()).upload(a(v$,"m44 op,va0,vc0\nmov v0,va1"),a(f$,"tex oc,v0,fs0<2d,repeat,linear,mipnearest>"));g([16512,2250086,10530992,13408563,32768,8934656,0xffffff],[1,1,1,1,1,1,1],[0,93,94,95,116,160,176],1024);c=p.clone();a=$.createVertexBuffer;e=$.createIndexBuffer;for(o=0;o<256;o++){vt=new<Number>[];for(iy=0;iy<33;iy++)for(ix=0;ix<33;ix++){i=(o&15)*32+ix;j=(o>>4)*32+iy;m=h(i,j);_=new Vector3D(h(i+1,j,0)-h(i-1,j,0),h(i,j+1,0)-h(i,j-1,0),1);_.normalize();for(k=1,n=0;k<128;k+=8){l=(h(i+k,j+k)-m)/k;if(n<l)n=l}l=(_.z-_.x*2-_.y*2)*.333;c.setPixel(i,j,((n<2?255:n<8?511/n:64)<<16)|((int(l<0?0:l*64)+191)<<8)|h(i,j,0));vt.push(ix-16,iy-16,m/8,i/512,j/512)}vb.push(_=a(1089,5));_[u$](vt,0,1089)}t0=r(c);t1=r(gb);g([4219008,0xffffff],[1,1],[128,192],256);for(i=0;i<256;i++){c=gb.getPixel(i,0);mr[i]=c&16711680;mg[i]=c&65280;mb[i]=c&255}d=p.clone();d.paletteMap(p,p.rect,new Point,mr,mg,mb);t2=r(d);for(i=0;i<32;i++)for(j=0;j<32;j++){k=i*33+j;id.push(k,k+33,k+1,k+33,k+34,k+1)}ib=e(6144);ib[u$](id,0,6144);c=1000;b=-160;(sv=a(5,5))[u$](new<Number>[0,0,40,1,1,-c,-c,b,0,0,c,-c,b,2,0,-c,c,b,0,2,c,c,b,2,2],0,5);(si=e(12))[u$](new<uint>[0,1,2,0,2,4,0,4,3,0,3,1],0,12);_=$.setProgramConstantsFromVector;_(v$,9,new<Number>[0,6,1/32,99]);_(f$,0,new<Number>[.05,.5,1,2]);$.setBlendFactors("sourceAlpha","oneMinusSourceAlpha");$.setCulling("back");pm.perspectiveFieldOfViewRH(.785,1,1,1024);tm=gt()});$.requestContext3D()}function r(x):*{_=$.createTexture(j=x.width,k=x.height,"bgra",0);for(i=0,l=1;k>0;i++,j>>=1,k>>=1,l/=2){b=new bd(j,k,f);b.draw(x,new Matrix(l,0,0,l),f,f,f,t);_.uploadFromBitmapData(b,i)}return _}function q(h):*{b=new ByteArray;b.endian="littleEndian";for(i=0;a=h.substr(i,2);i+=2)b.writeByte(parseInt(a,16));b.uncompress();return b}function g(c,a,r,t){m2.createGradientBox(t,1);with(s.graphics){clear();beginGradientFill("linear",c,a,r,m2);drawRect(0,0,t,1)}gb.draw(s)}function h(x,y,z=96):*{x=p.getPixel(x&511,y&511)&255;return x<z?z:x}var gt=getTimer,bd=BitmapData,v=Vector3D,$,_,a,b,c,d,e,i,j,k,l,m,n,o,t=1,f=null,s=new Shape,p=new bd(512,512,f),ix,iy,mr=[],mg=[],mb=[],gb=new bd(1024,1,f),vt=new Vector.<Number>(5445),id=new<uint>[],vb=[],ib,sv,si,p0,p1,t0,t1,t2,pm=new PerspectiveMatrix3D,m2=new Matrix,m3=new Matrix3D,rt=0,ra=0,sp=0,dx,dy,px=0,py=0,pz=38,vz=0,tm,ik=0,a$="addEventListener",u$="uploadFromVector",v$="vertex",f$="fragment"}import flash.utils.*;import flash.geom.*;import flash.display.*;import flash.display3D.*;import flash.display3D.textures.*;import com.adobe.utils.*}


/* with indent
package{public class w extends Sprite{
function w(){
    _=this;
    $=stage;
    $[a$]("keyDown",function(e){ik|=1<<(e.keyCode&3)});
    $[a$]("keyUp",function(e){ik&=~(1<<(e.keyCode&3))});
    $=$.stage3Ds[0];
    $[a$]("context3DCreate",function(){
        _[a$]("enterFrame",function(){
            n=(tm-(tm=gt()));
            ra+=rt=(rt+((ik&8)/4-(ik&2))*n*.002)*.9;
            k=h(px,py)/8+3;
            if(pz<k)vz=(k-pz)/3;
            pz+=vz+=((ik&1)-pz/30)/10-.01;
            a=ra*.0175;
            m=Math;
            sp=(sp+(ik&4)/2000)*.9;
            n*=-(sp+.005);
            px+=(dx=m.cos(a))*n;
            py+=(dy=m.sin(a))*n;
            m3.copyFrom(pm);
            _=m3.prependRotation;
            _(pz-105,v.X_AXIS);
            _(rt*8,v.Y_AXIS);
            _(90-ra-rt*8,v.Z_AXIS);
            with($){
                a=setTextureAt;
                b=setVertexBufferAt;
                c=setProgramConstantsFromMatrix;
                d=drawTriangles;
                e=setProgram;
                clear(1/4,3/8,.5,1);
                e(p1);
                a(0,t2);
                a(1,f);
                b(0,sv,0,m="float3");
                b(1,sv,3,n="float2");
                c(v$,0,m3,t);
                d(si);
                _=m3.prependTranslation;
                _(-px,-py,-pz);
                e(p0);
                a(0,t0);
                a(1,t1);
                ix=px>>5;
                iy=py>>5;
                for(i=-7;i<8;i++)for(j=-7;j<8;j++){
                    k=(ix+i)*32+16;
                    l=(iy+j)*32+16;
                    if((k-px)*dx+(l-py)*dy>-20){
                        o=(ix+i&15)+(iy+j&15)*16;
                        b(0,vb[o],0,m);
                        b(1,vb[o],3,n);
                        _(k,l,0);
                        c(v$,0,m3,t);
                        _(-k,-l,0);
                        d(ib)
                    }
                }
                present()
            }
        });
        p.perlinNoise(64,64,7,gt(),t,t,7,t);
        $=$.context3D;
        $.configureBackBuffer(450,450,0,t);
        c=$.createProgram;
        (p0=c()).upload(
            q("78da5d8c3b0ec0200c431dc8d04e59b958ef57d69e8b7b401ca88afa064b963fb700a82820965c1a264df062993ee18fa97cfd20871eac76ca093cfc995b55f7d7fa8d9c7dd97e3cefcc071a530a56"),
            q("78da6d8ed10d80200c44af05a37fe8160ea4fb49e2177339886d0141e325d0f25aae3d0840a415aac0726d1e5903e6453909a70f77c6bdf2c485d3735edca2fa70f6b137990fe0f24f6b2dfd3bff70ea386364c9cf3ab7c549d354f76c0a4e0a1777e406d8f508e6")
        );
        a=new AGALMiniAssembler().assemble;
        (p1=c()).upload(
            a(v$,"m44 op,va0,vc0\nmov v0,va1"),
            a(f$,"tex oc,v0,fs0<2d,repeat,linear,mipnearest>")
        );
        g([16512,2250086,10530992,13408563,32768,8934656,0xffffff],[1,1,1,1,1,1,1],[0,93,94,95,116,160,176],1024);
        c=p.clone();
        a=$.createVertexBuffer;
        e=$.createIndexBuffer;
        for(o=0;o<256;o++){
            vt=new<Number>[];
            for(iy=0;iy<33;iy++)for(ix=0;ix<33;ix++){
                i=(o&15)*32+ix;
                j=(o>>4)*32+iy;
                m=h(i,j);
                _=new Vector3D(h(i+1,j,0)-h(i-1,j,0),h(i,j+1,0)-h(i,j-1,0),1);
                _.normalize();
                for(k=1,n=0;k<128;k+=8){
                    l=(h(i+k,j+k)-m)/k;
                    if(n<l)n=l
                }
                l=(_.z-_.x*2-_.y*2)*.333;
                c.setPixel(i,j,((n<2?255:n<8?511/n:64)<<16)|((int(l<0?0:l*64)+191)<<8)|h(i,j,0));
                vt.push(ix-16,iy-16,m/8,i/512,j/512)
            }
            vb.push(_=a(1089,5));
            _[u$](vt,0,1089)
        }
        t0=r(c);
        t1=r(gb);
        g([4219008,0xffffff],[1,1],[128,192],256);
        for(i=0;i<256;i++){
            c=gb.getPixel(i,0);
            mr[i]=c&16711680;
            mg[i]=c&65280;
            mb[i]=c&255
        }
        d=p.clone();
        d.paletteMap(p,p.rect,new Point,mr,mg,mb);
        t2=r(d);
        for(i=0;i<32;i++)for(j=0;j<32;j++){k=i*33+j;id.push(k,k+33,k+1,k+33,k+34,k+1)}
        ib=e(6144);ib[u$](id,0,6144);
        c=1000;b=-160;
        (sv=a(5,5))[u$](new<Number>[0,0,40,1,1,-c,-c,b,0,0,c,-c,b,2,0,-c,c,b,0,2,c,c,b,2,2],0,5);
        (si=e(12))[u$](new<uint>[0,1,2,0,2,4,0,4,3,0,3,1],0,12);
        _=$.setProgramConstantsFromVector;
        _(v$,9,new<Number>[0,6,1/32,99]);
        _(f$,0,new<Number>[.05,.5,1,2]);
        $.setBlendFactors("sourceAlpha","oneMinusSourceAlpha");
        $.setCulling("back");
        pm.perspectiveFieldOfViewRH(.785,1,1,1024);
        tm=gt()
    });
    $.requestContext3D()
}
function r(x):*{
    _=$.createTexture(j=x.width,k=x.height,"bgra",0);
    for(i=0,l=1;k>0;i++,j>>=1,k>>=1,l/=2){
        b=new bd(j,k,f);
        b.draw(x,new Matrix(l,0,0,l),f,f,f,t);
        _.uploadFromBitmapData(b,i)
    }
    return _
}
function q(h):*{
    b=new ByteArray;
    b.endian="littleEndian";
    for(i=0;a=h.substr(i,2);i+=2)b.writeByte(parseInt(a,16));
    b.uncompress();
    return b
}
function g(c,a,r,t){
    m2.createGradientBox(t,1);
    with(s.graphics){
        clear();
        beginGradientFill("linear",c,a,r,m2);
        drawRect(0,0,t,1)
    }
    gb.draw(s)
}
function h(x,y,z=96):*{
    x=p.getPixel(x&511,y&511)&255;
    return x<z?z:x
}
var gt=getTimer,bd=BitmapData,v=Vector3D,
$,_,a,b,c,d,e,i,j,k,l,m,n,o,t=1,f=null,s=new Shape,p=new bd(512,512,f),
ix,iy,mr=[],mg=[],mb=[],gb=new bd(1024,1,f),
vt=new Vector.<Number>(5445),id=new<uint>[],vb=[],ib,sv,si,p0,p1,t0,t1,t2,
pm=new PerspectiveMatrix3D,m2=new Matrix,m3=new Matrix3D,rt=0,ra=0,sp=0,dx,dy,px=0,py=0,pz=38,vz=0,tm,ik=0,
a$="addEventListener",u$="uploadFromVector",v$="vertex",f$="fragment"}
import flash.utils.*;
import flash.geom.*;
import flash.display.*;
import flash.display3D.*;
import flash.display3D.textures.*;
import com.adobe.utils.*
}
*/
