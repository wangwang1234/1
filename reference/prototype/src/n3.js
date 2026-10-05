
// ---------- 迷你 3D 渲染器（WebGL2，三渲二）----------
const $=id=>document.getElementById(id);
const glc=$('gl');
const coarse=!!(window.matchMedia&&window.matchMedia('(pointer: coarse)').matches);
let inputMode=coarse?'touch':'mouse';
const Q=coarse?{ss:1024,nl:6,bloom:4,dof:0.4}:{ss:2048,nl:8,bloom:5,dof:0.55};
let gl=null,SS=2048,shOn=true,shTex=null,shFB=null;
const PITCH=56*Math.PI/180,FOV=34*Math.PI/180,COTP=1/Math.tan(PITCH);
let camDist=640;
const camPos=new Float32Array(3),Vm=new Float32Array(16),Pm=new Float32Array(16),VPm=new Float32Array(16),VPinv=new Float32Array(16),LV=new Float32Array(16),LP=new Float32Array(16),LVP=new Float32Array(16),IDM=new Float32Array([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]);
const _M=new Float32Array(16),_N9=new Float32Array(9);
const nrm3=v=>{const l=Math.hypot(v[0],v[1],v[2]);return new Float32Array(v.map(a=>a/l));};
const LDIR=nrm3([-0.3,0.9,-0.6]),FILL=nrm3([0.25,0.4,1.0]);
const OLC=[0.11,0.075,0.16];

function m4mul(o,a,b){
  const a00=a[0],a01=a[1],a02=a[2],a03=a[3],a10=a[4],a11=a[5],a12=a[6],a13=a[7],a20=a[8],a21=a[9],a22=a[10],a23=a[11],a30=a[12],a31=a[13],a32=a[14],a33=a[15];
  for(let i=0;i<4;i++){const b0=b[i*4],b1=b[i*4+1],b2=b[i*4+2],b3=b[i*4+3];
    o[i*4]=b0*a00+b1*a10+b2*a20+b3*a30;o[i*4+1]=b0*a01+b1*a11+b2*a21+b3*a31;o[i*4+2]=b0*a02+b1*a12+b2*a22+b3*a32;o[i*4+3]=b0*a03+b1*a13+b2*a23+b3*a33;}
  return o;}
function m4persp(o,fy,asp,n,f){const t=1/Math.tan(fy/2),nf=1/(n-f);o.fill(0);o[0]=t/asp;o[5]=t;o[10]=(f+n)*nf;o[11]=-1;o[14]=2*f*n*nf;return o;}
function m4ortho(o,l,r,b,t,n,f){const lr=1/(l-r),bt=1/(b-t),nf=1/(n-f);o.fill(0);o[0]=-2*lr;o[5]=-2*bt;o[10]=2*nf;o[12]=(l+r)*lr;o[13]=(t+b)*bt;o[14]=(f+n)*nf;o[15]=1;return o;}
function m4look(o,e,c,u){
  let zx=e[0]-c[0],zy=e[1]-c[1],zz=e[2]-c[2],l=Math.hypot(zx,zy,zz);zx/=l;zy/=l;zz/=l;
  let xx=u[1]*zz-u[2]*zy,xy=u[2]*zx-u[0]*zz,xz=u[0]*zy-u[1]*zx;l=Math.hypot(xx,xy,xz)||1;xx/=l;xy/=l;xz/=l;
  const yx=zy*xz-zz*xy,yy=zz*xx-zx*xz,yz=zx*xy-zy*xx;
  o[0]=xx;o[1]=yx;o[2]=zx;o[3]=0;o[4]=xy;o[5]=yy;o[6]=zy;o[7]=0;o[8]=xz;o[9]=yz;o[10]=zz;o[11]=0;
  o[12]=-(xx*e[0]+xy*e[1]+xz*e[2]);o[13]=-(yx*e[0]+yy*e[1]+yz*e[2]);o[14]=-(zx*e[0]+zy*e[1]+zz*e[2]);o[15]=1;return o;}
function m4inv(o,a){
  const a00=a[0],a01=a[1],a02=a[2],a03=a[3],a10=a[4],a11=a[5],a12=a[6],a13=a[7],a20=a[8],a21=a[9],a22=a[10],a23=a[11],a30=a[12],a31=a[13],a32=a[14],a33=a[15];
  const b00=a00*a11-a01*a10,b01=a00*a12-a02*a10,b02=a00*a13-a03*a10,b03=a01*a12-a02*a11,b04=a01*a13-a03*a11,b05=a02*a13-a03*a12,b06=a20*a31-a21*a30,b07=a20*a32-a22*a30,b08=a20*a33-a23*a30,b09=a21*a32-a22*a31,b10=a21*a33-a23*a31,b11=a22*a33-a23*a32;
  let det=b00*b11-b01*b10+b02*b09+b03*b08-b04*b07+b05*b06;if(!det)return o;det=1/det;
  o[0]=(a11*b11-a12*b10+a13*b09)*det;o[1]=(a02*b10-a01*b11-a03*b09)*det;o[2]=(a31*b05-a32*b04+a33*b03)*det;o[3]=(a22*b04-a21*b05-a23*b03)*det;
  o[4]=(a12*b08-a10*b11-a13*b07)*det;o[5]=(a00*b11-a02*b08+a03*b07)*det;o[6]=(a32*b02-a30*b05-a33*b01)*det;o[7]=(a20*b05-a22*b02+a23*b01)*det;
  o[8]=(a10*b10-a11*b08+a13*b06)*det;o[9]=(a01*b08-a00*b10-a03*b06)*det;o[10]=(a30*b04-a31*b02+a33*b00)*det;o[11]=(a21*b02-a20*b04-a23*b00)*det;
  o[12]=(a11*b07-a10*b09-a12*b06)*det;o[13]=(a00*b09-a01*b07+a02*b06)*det;o[14]=(a31*b01-a30*b03-a32*b00)*det;o[15]=(a20*b03-a21*b01+a22*b00)*det;return o;}
function m4trs(o,px,py,pz,ry,rx,rz,sx,sy,sz){
  const cy=Math.cos(ry),sy_=Math.sin(ry),cx=Math.cos(rx),sx_=Math.sin(rx),cz=Math.cos(rz),sz_=Math.sin(rz);
  const r00=cy*cz+sy_*sx_*sz_,r01=-cy*sz_+sy_*sx_*cz,r02=sy_*cx,r10=cx*sz_,r11=cx*cz,r12=-sx_,r20=-sy_*cz+cy*sx_*sz_,r21=sy_*sz_+cy*sx_*cz,r22=cy*cx;
  o[0]=r00*sx;o[1]=r10*sx;o[2]=r20*sx;o[3]=0;o[4]=r01*sy;o[5]=r11*sy;o[6]=r21*sy;o[7]=0;o[8]=r02*sz;o[9]=r12*sz;o[10]=r22*sz;o[11]=0;o[12]=px;o[13]=py;o[14]=pz;o[15]=1;return o;}
function nmat(o,m){
  const ax=m[0],ay=m[1],az=m[2],bx=m[4],by=m[5],bz=m[6],cx=m[8],cy=m[9],cz=m[10];
  const n0x=by*cz-bz*cy,n0y=bz*cx-bx*cz,n0z=bx*cy-by*cx,n1x=cy*az-cz*ay,n1y=cz*ax-cx*az,n1z=cx*ay-cy*ax,n2x=ay*bz-az*by,n2y=az*bx-ax*bz,n2z=ax*by-ay*bx;
  let d=ax*n0x+ay*n0y+az*n0z;d=d?1/d:1;
  o[0]=n0x*d;o[1]=n0y*d;o[2]=n0z*d;o[3]=n1x*d;o[4]=n1y*d;o[5]=n1z*d;o[6]=n2x*d;o[7]=n2y*d;o[8]=n2z*d;return o;}
function hexRGB(c){const n=typeof c==='number'?c:parseInt(c.slice(1),16);return[((n>>16)&255)/255,((n>>8)&255)/255,(n&255)/255];}

// ---------- 几何体 ----------
const GCACHE={};
function mkG(key,fn){if(key&&GCACHE[key])return GCACHE[key];const P=[],N=[];fn(P,N);const g={P:new Float32Array(P),N:new Float32Array(N)};if(key)GCACHE[key]=g;return g;}
function tri(P,N,a,b,c,na,nb,nc){P.push(a[0],a[1],a[2],b[0],b[1],b[2],c[0],c[1],c[2]);N.push(na[0],na[1],na[2],nb[0],nb[1],nb[2],nc[0],nc[1],nc[2]);}
function gSphere(ws=18,hs=12){return mkG('s'+ws+'_'+hs,(P,N)=>{
  const v=(i,j)=>{const th=j/hs*Math.PI,ph=i/ws*TAU;return[Math.sin(th)*Math.cos(ph),Math.cos(th),Math.sin(th)*Math.sin(ph)];};
  for(let j=0;j<hs;j++)for(let i=0;i<ws;i++){const a=v(i,j),b=v(i+1,j),c=v(i+1,j+1),d=v(i,j+1);if(j>0)tri(P,N,a,b,c,a,b,c);if(j<hs-1)tri(P,N,a,c,d,a,c,d);}});}
function gBox(){return mkG('box',(P,N)=>{
  const f=(n,u,v)=>{const p=(a,b)=>[n[0]*0.5+u[0]*a*0.5+v[0]*b*0.5,n[1]*0.5+u[1]*a*0.5+v[1]*b*0.5,n[2]*0.5+u[2]*a*0.5+v[2]*b*0.5];const A=p(-1,-1),B=p(1,-1),C=p(1,1),D=p(-1,1);tri(P,N,A,B,C,n,n,n);tri(P,N,A,C,D,n,n,n);};
  f([1,0,0],[0,0,-1],[0,1,0]);f([-1,0,0],[0,0,1],[0,1,0]);f([0,1,0],[1,0,0],[0,0,-1]);f([0,-1,0],[1,0,0],[0,0,1]);f([0,0,1],[1,0,0],[0,1,0]);f([0,0,-1],[-1,0,0],[0,1,0]);});}
function gCyl(rt,rb,h,seg=18,caps=true){return mkG(`c${rt.toFixed(2)},${rb.toFixed(2)},${h.toFixed(2)},${seg},${caps}`,(P,N)=>{
  const y0=-h/2,y1=h/2,sl=(rb-rt)/h;
  for(let i=0;i<seg;i++){const a0=i/seg*TAU,a1=(i+1)/seg*TAU,c0=Math.cos(a0),s0=Math.sin(a0),c1=Math.cos(a1),s1=Math.sin(a1);
    const n0=(()=>{const l=Math.hypot(1,sl);return[c0/l,sl/l,s0/l];})(),n1=(()=>{const l=Math.hypot(1,sl);return[c1/l,sl/l,s1/l];})();
    const t0=[rt*c0,y1,rt*s0],t1=[rt*c1,y1,rt*s1],b0=[rb*c0,y0,rb*s0],b1=[rb*c1,y0,rb*s1];
    tri(P,N,t0,t1,b1,n0,n1,n1);tri(P,N,t0,b1,b0,n0,n1,n0);
    if(caps){if(rt>0.001)tri(P,N,[0,y1,0],t1,t0,[0,1,0],[0,1,0],[0,1,0]);if(rb>0.001)tri(P,N,[0,y0,0],b0,b1,[0,-1,0],[0,-1,0],[0,-1,0]);}}});}
function gTorus(R,r,rs=24,ts=8){return mkG(`t${R.toFixed(2)},${r.toFixed(2)},${rs},${ts}`,(P,N)=>{
  const v=(i,j)=>{const ph=i/rs*TAU,th=j/ts*TAU,cr=R+r*Math.cos(th);return[[cr*Math.cos(ph),r*Math.sin(th),cr*Math.sin(ph)],[Math.cos(th)*Math.cos(ph),Math.sin(th),Math.cos(th)*Math.sin(ph)]];};
  for(let i=0;i<rs;i++)for(let j=0;j<ts;j++){const a=v(i,j),b=v(i+1,j),c=v(i+1,j+1),d=v(i,j+1);tri(P,N,a[0],c[0],b[0],a[1],c[1],b[1]);tri(P,N,a[0],d[0],c[0],a[1],d[1],c[1]);}});}
function gLathe(pts,seg=16,key){return mkG(key,(P,N)=>{
  const nrm=pts.map((p,k)=>{const a=pts[Math.max(0,k-1)],b=pts[Math.min(pts.length-1,k+1)];let dr=b[0]-a[0],dy=b[1]-a[1];const l=Math.hypot(dr,dy)||1;return[dy/l,-dr/l];});
  const v=(i,k)=>{const ph=i/seg*TAU,c=Math.cos(ph),s=Math.sin(ph);return[[pts[k][0]*c,pts[k][1],pts[k][0]*s],[nrm[k][0]*c,nrm[k][1],nrm[k][0]*s]];};
  for(let i=0;i<seg;i++)for(let k=0;k<pts.length-1;k++){const a=v(i,k),b=v(i+1,k),c=v(i+1,k+1),d=v(i,k+1);tri(P,N,a[0],c[0],b[0],a[1],c[1],b[1]);tri(P,N,a[0],d[0],c[0],a[1],d[1],c[1]);}});}
function crSample(pts,n){const out=[];for(let i=0;i<pts.length-1;i++){const p0=pts[Math.max(0,i-1)],p1=pts[i],p2=pts[i+1],p3=pts[Math.min(pts.length-1,i+2)];for(let k=0;k<n;k++){const t=k/n,t2=t*t,t3=t2*t;out.push([0,1,2].map(j=>0.5*((2*p1[j])+(-p0[j]+p2[j])*t+(2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t2+(-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t3)));}}out.push(pts[pts.length-1].slice());return out;}
function gTube(path,r,rad=7){return mkG(null,(P,N)=>{
  const pts=crSample(path,6),n=pts.length,T=[],Nn=[],Bn=[];
  for(let k=0;k<n;k++){const a=pts[Math.max(0,k-1)],b=pts[Math.min(n-1,k+1)];let t=[b[0]-a[0],b[1]-a[1],b[2]-a[2]];const l=Math.hypot(...t)||1;T.push(t.map(x=>x/l));}
  let up=Math.abs(T[0][1])<0.9?[0,1,0]:[1,0,0];
  for(let k=0;k<n;k++){const t=T[k];let nn=k===0?up:Nn[k-1];const d=nn[0]*t[0]+nn[1]*t[1]+nn[2]*t[2];nn=[nn[0]-t[0]*d,nn[1]-t[1]*d,nn[2]-t[2]*d];const l=Math.hypot(...nn)||1;nn=nn.map(x=>x/l);Nn.push(nn);Bn.push([t[1]*nn[2]-t[2]*nn[1],t[2]*nn[0]-t[0]*nn[2],t[0]*nn[1]-t[1]*nn[0]]);}
  const v=(i,k)=>{const th=i/rad*TAU,c=Math.cos(th),s=Math.sin(th),nm=[c*Nn[k][0]+s*Bn[k][0],c*Nn[k][1]+s*Bn[k][1],c*Nn[k][2]+s*Bn[k][2]];return[[pts[k][0]+nm[0]*r,pts[k][1]+nm[1]*r,pts[k][2]+nm[2]*r],nm];};
  for(let k=0;k<n-1;k++)for(let i=0;i<rad;i++){const a=v(i,k),b=v(i+1,k),c=v(i+1,k+1),d=v(i,k+1);tri(P,N,a[0],b[0],c[0],a[1],b[1],c[1]);tri(P,N,a[0],c[0],d[0],a[1],c[1],d[1]);}});}
function gDisc(seg=20){return mkG('d'+seg,(P,N)=>{const u=[0,1,0];for(let i=0;i<seg;i++){const a0=i/seg*TAU,a1=(i+1)/seg*TAU;tri(P,N,[0,0,0],[Math.cos(a1),0,Math.sin(a1)],[Math.cos(a0),0,Math.sin(a0)],u,u,u);}});}
function gQuad(){return mkG('q',(P,N)=>{const u=[0,1,0];tri(P,N,[-0.5,0,-0.5],[-0.5,0,0.5],[0.5,0,0.5],u,u,u);tri(P,N,[-0.5,0,-0.5],[0.5,0,0.5],[0.5,0,-0.5],u,u,u);});}
function gFan(pts){return mkG(null,(P,N)=>{const u=[0,1,0];let cx=0,cz=0;for(const p of pts){cx+=p[0];cz+=p[1];}cx/=pts.length;cz/=pts.length;for(let i=0;i<pts.length;i++){const a=pts[i],b=pts[(i+1)%pts.length];tri(P,N,[cx,0,cz],[b[0],0,b[1]],[a[0],0,a[1]],u,u,u);}});}

// ---------- 模型构建器（合并顶点色 + 外描边壳）----------
function xform(g,m,oP,oN){const n9=nmat(_N9,m),P=g.P,N=g.N;
  for(let i=0;i<P.length;i+=3){const x=P[i],y=P[i+1],z=P[i+2];oP.push(m[0]*x+m[4]*y+m[8]*z+m[12],m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14]);
    if(oN){const a=N[i],b=N[i+1],c=N[i+2];const nx=n9[0]*a+n9[3]*b+n9[6]*c,ny=n9[1]*a+n9[4]*b+n9[7]*c,nz=n9[2]*a+n9[5]*b+n9[8]*c,l=Math.hypot(nx,ny,nz)||1;oN.push(nx/l,ny/l,nz/l);}}}
class Mdl{
  constructor(t=1.5,res,hres){this.P=[];this.N=[];this.C=[];this.H=[];this.t=t;this.res=res||[18,12];this.hres=hres||this.res;}
  addM(g,col,em,M,hg,HM){const n0=this.P.length;xform(g,M,this.P,this.N);const c=hexRGB(col),n=(this.P.length-n0)/3;for(let i=0;i<n;i++)this.C.push(c[0],c[1],c[2],em);if(hg)xform(hg,HM||M,this.H,null);return this;}
  add(g,col,em,px,py,pz,ry,rx,rz,sx,sy,sz,hg,hx,hy,hz){const M=m4trs(new Float32Array(16),px,py,pz,ry,rx,rz,sx,sy,sz);let HM=null;if(hg)HM=m4trs(new Float32Array(16),px,py,pz,ry,rx,rz,hx,hy,hz);return this.addM(g,col,em,M,hg,HM);}
  ell(col,x,y,z,a,b,c,ry=0,rx=0,rz=0,t=this.t,em=0){const g=gSphere(this.res[0],this.res[1]);return this.add(g,col,em,x,y,z,ry,rx,rz,a,b,c,t>0?gSphere(this.hres[0],this.hres[1]):null,a+t,b+t,c+t);}
  ball(col,x,y,z,a,b,c,ry=0,rx=0,rz=0,t=this.t,em=0){const g=gSphere(10,7);return this.add(g,col,em,x,y,z,ry,rx,rz,a,b,c,t>0?g:null,a+t,b+t,c+t);}
  box(col,x,y,z,w,h,d,ry=0,rx=0,rz=0,t=this.t,em=0){const g=gBox();return this.add(g,col,em,x,y,z,ry,rx,rz,w,h,d,t>0?g:null,w+2*t,h+2*t,d+2*t);}
  bx(col,x0,z0,x1,z1,y0,y1,t=this.t,em=0){return this.box(col,(x0+x1)/2,(y0+y1)/2,(z0+z1)/2,x1-x0,y1-y0,z1-z0,0,0,0,t,em);}
  cyl(col,x,y,z,rt,rb,h,ry=0,rx=0,rz=0,t=this.t,em=0,seg=18){const g=gCyl(rt,rb,h,seg);const hg=t>0?gCyl(rt+t,rb+t,h+2*t,seg):null;return this.add(g,col,em,x,y,z,ry,rx,rz,1,1,1,hg,1,1,1);}
  torus(col,x,y,z,R,r,ry=0,rx=0,rz=0,t=this.t,em=0){const g=gTorus(R,r);const hg=t>0?gTorus(R,r+t):null;return this.add(g,col,em,x,y,z,ry,rx,rz,1,1,1,hg,1,1,1);}
  tube(col,path,r,t=this.t,em=0){const g=gTube(path,r);const hg=t>0?gTube(path,r+t):null;return this.add(g,col,em,0,0,0,0,0,0,1,1,1,hg,1,1,1);}
  rod(col,a,b,r,t=this.t,em=0){
    const dx=b[0]-a[0],dy=b[1]-a[1],dz=b[2]-a[2],L=Math.hypot(dx,dy,dz)||1,Y=[dx/L,dy/L,dz/L];let X=Math.abs(Y[1])<0.95?[Y[2],0,-Y[0]]:[1,0,0];const xl=Math.hypot(...X);X=X.map(v=>v/xl);const Z=[X[1]*Y[2]-X[2]*Y[1],X[2]*Y[0]-X[0]*Y[2],X[0]*Y[1]-X[1]*Y[0]];
    const mk=(r_,l_)=>new Float32Array([X[0]*r_,X[1]*r_,X[2]*r_,0,Y[0]*l_,Y[1]*l_,Y[2]*l_,0,Z[0]*r_,Z[1]*r_,Z[2]*r_,0,(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2,1]);
    const g=gCyl(1,1,1,10);return this.addM(g,col,em,mk(r,L),t>0?g:null,mk(r+t,L+t*2));}
  quad(col,x,y,z,w,d,ry=0,em=0){return this.add(gQuad(),col,em,x,y,z,ry,0,0,w,1,d,null);}
  disc(col,x,y,z,rx_,rz_,ry=0,em=0){return this.add(gDisc(),col,em,x,y,z,ry,0,0,rx_,1,rz_,null);}
  fan(col,pts,y,em=0){return this.add(gFan(pts),col,em,0,y,0,0,0,0,1,1,1,null);}
}

// ---------- 着色器（HDR 三渲二 + 电影级后期）----------
const SH_TOON_V=`#version 300 es
layout(location=0) in vec3 aPos;layout(location=1) in vec3 aNor;layout(location=2) in vec4 aCol;
#ifdef INST
layout(location=3) in vec4 i0;layout(location=4) in vec4 i1;layout(location=5) in vec4 i2;layout(location=6) in vec4 i3;
#endif
uniform mat4 uVP,uM,uLVP;uniform mat3 uNM;
out vec3 vN;out vec4 vC;out vec3 vW;out vec4 vL;out vec3 vIE;
#ifdef INST
layout(location=7) in vec4 iE;
#endif
void main(){mat4 M=uM;mat3 NM=uNM;vIE=vec3(0.0);
#ifdef INST
mat4 I=mat4(i0,i1,i2,i3);M=uM*I;NM=uNM*mat3(I);vIE=iE.rgb;
#endif
vec4 w=M*vec4(aPos,1.0);vN=normalize(NM*aNor);vC=aCol;vW=w.xyz;vL=uLVP*vec4(w.xyz+vN*2.0,1.0);gl_Position=uVP*w;}`;
const SH_TOON_F=`#version 300 es
precision highp float;precision highp sampler2DShadow;
in vec3 vN;in vec4 vC;in vec3 vW;in vec4 vL;in vec3 vIE;
uniform vec3 uSky,uGround,uLDir,uLCol,uShT,uEye,uEm,uFillDir,uFillCol,uRimCol,uFog;
uniform float uOp,uShOn,uFogK;uniform int uNL;
uniform sampler2DShadow uSh;uniform vec4 uPL[8];uniform vec3 uPC[8];uniform vec4 uPD[8];
out vec4 o;
float shadow(){vec3 p=vL.xyz/vL.w*0.5+0.5;if(p.x<0.0||p.x>1.0||p.y<0.0||p.y>1.0||p.z>1.0)return 1.0;
 float t=0.6/float(textureSize(uSh,0).x);float z=p.z-0.0004;
 return 0.25*(texture(uSh,vec3(p.xy+vec2(-t,-t),z))+texture(uSh,vec3(p.xy+vec2(t,-t),z))+texture(uSh,vec3(p.xy+vec2(-t,t),z))+texture(uSh,vec3(p.xy+vec2(t,t),z)));}
void main(){
 vec3 N=normalize(vN);vec3 base=vC.rgb;float em=max(vC.a,0.0),gs=max(-vC.a,0.0);
 vec3 V=normalize(uEye-vW);
 float nl=dot(N,uLDir);float lit=smoothstep(0.0,0.06,nl);float sh=1.0;
 if(uShOn>0.5&&nl>0.0){sh=smoothstep(0.25,0.75,shadow());lit*=sh;}
 vec3 lt=mix(uGround,uSky,N.y*0.5+0.5)+uLCol*mix(uShT,vec3(1.0),lit)+uFillCol*smoothstep(0.0,0.12,dot(N,uFillDir));
 vec3 spec=vec3(0.0);
 for(int i=0;i<8;i++){if(i>=uNL)break;float r=abs(uPL[i].w);if(r<=0.0)continue;vec3 d=uPL[i].xyz-vW;float dl=length(d);float a=clamp(1.0-dl/r,0.0,1.0);if(a<=0.0)continue;vec3 Ld=d/max(dl,0.001);
  float b=uPL[i].w<0.0?a*a*a:smoothstep(0.02,0.14,a)*0.4+smoothstep(0.3,0.45,a)*0.6;if(uPD[i].w>-1.5)b*=smoothstep(uPD[i].w,uPD[i].w+0.07,dot(-Ld,uPD[i].xyz));lt+=uPC[i]*smoothstep(0.0,0.1,dot(N,Ld))*b;
  if(gs>0.0)spec+=uPC[i]*smoothstep(0.935,0.965,dot(N,normalize(Ld+V)))*gs*b*1.8;}
 if(gs>0.0)spec+=uLCol*smoothstep(0.95,0.975,dot(N,normalize(uLDir+V)))*gs*lit*1.6*(1.0-smoothstep(0.8,0.95,N.y));
 float rim=smoothstep(0.55,0.7,1.0-max(dot(N,V),0.0))*smoothstep(-0.15,0.35,nl)*mix(0.35,1.0,sh);
 float ao=N.y>0.85?1.0:mix(0.5,1.0,smoothstep(0.0,18.0,vW.y));
 vec3 col=base*lt*ao+uRimCol*rim+spec;
 if(em>0.0)col=base*(1.0+em*2.4);
 col=mix(col,uFog,smoothstep(uFogK,uFogK*1.9,length(vW-uEye))*0.4);
 o=vec4(col+uEm+vIE,uOp);}`;
const SH_LINE_V=`#version 300 es
layout(location=0) in vec3 aPos;
#ifdef INST
layout(location=3) in vec4 i0;layout(location=4) in vec4 i1;layout(location=5) in vec4 i2;layout(location=6) in vec4 i3;
#endif
uniform mat4 uVP,uM;
void main(){mat4 M=uM;
#ifdef INST
M=uM*mat4(i0,i1,i2,i3);
#endif
gl_Position=uVP*(M*vec4(aPos,1.0));}`;
const SH_LINE_F=`#version 300 es
precision mediump float;uniform vec4 uCol;out vec4 o;void main(){o=uCol;}`;
const SH_PT_V=`#version 300 es
layout(location=0) in vec3 aPos;layout(location=1) in vec2 aSz;layout(location=2) in vec4 aCol;
uniform mat4 uVP;uniform float uScale;out vec4 vC;out float vS;
void main(){vec4 c=uVP*vec4(aPos,1.0);gl_Position=c;gl_PointSize=clamp(aSz.x*uScale/c.w,1.0,256.0);vC=aCol;vS=aSz.y;}`;
const SH_PT_F=`#version 300 es
precision highp float;in vec4 vC;in float vS;out vec4 o;
void main(){vec2 p=gl_PointCoord*2.0-1.0;float d=dot(p,p);float a=vC.a;
if(vS<0.5){if(d>1.0)discard;}else if(vS<1.5){float s=sqrt(abs(p.x))+sqrt(abs(p.y));if(s>1.0)discard;a*=1.0-s*0.5;}else{if(d>1.0)discard;a*=pow(1.0-d,1.6);}
o=vec4(vC.rgb,a);}`;
const SH_FLAT_V=`#version 300 es
layout(location=0) in vec3 aPos;layout(location=2) in vec4 aCol;uniform mat4 uVP;out vec4 vC;void main(){vC=aCol;gl_Position=uVP*vec4(aPos,1.0);}`;
const SH_FLAT_F=`#version 300 es
precision highp float;in vec4 vC;out vec4 o;void main(){o=vC;}`;
const SH_TEX_V=`#version 300 es
layout(location=0) in vec3 aPos;layout(location=1) in vec2 aUV;uniform mat4 uVP;out vec2 vUV;void main(){vUV=aUV;gl_Position=uVP*vec4(aPos,1.0);}`;
const SH_TEX_F=`#version 300 es
precision mediump float;in vec2 vUV;uniform sampler2D uTex;uniform float uMul;out vec4 o;void main(){vec4 c=texture(uTex,vUV);if(c.a<0.05)discard;o=vec4(c.rgb*uMul,c.a);}`;
const SH_FS_V=`#version 300 es
out vec2 vUV;void main(){vec2 p=vec2(float((gl_VertexID<<1)&2),float(gl_VertexID&2));vUV=p;gl_Position=vec4(p*2.0-1.0,0.0,1.0);}`;
const SH_DOWN_F=`#version 300 es
precision highp float;in vec2 vUV;uniform sampler2D uTex;uniform vec2 uTexel;uniform float uThr,uKnee;out vec4 o;
vec3 tp(vec2 f){return texture(uTex,vUV+f*uTexel).rgb;}
float mx(vec3 c){return max(max(c.r,c.g),c.b);}
void main(){vec3 a=tp(vec2(-1.0,-1.0)),b=tp(vec2(1.0,-1.0)),c=tp(vec2(-1.0,1.0)),d=tp(vec2(1.0,1.0));vec3 col;
 if(uThr>0.0){float wa=1.0/(1.0+mx(a)),wb=1.0/(1.0+mx(b)),wc=1.0/(1.0+mx(c)),wd=1.0/(1.0+mx(d));col=(a*wa+b*wb+c*wc+d*wd)/(wa+wb+wc+wd);
  float br=mx(col);float sf=clamp(br-uThr+uKnee,0.0,2.0*uKnee);sf=sf*sf/(4.0*uKnee+1e-4);col*=max(sf,br-uThr)/max(br,1e-4);}
 else col=(a+b+c+d)*0.25;
 o=vec4(col,1.0);}`;
const SH_UP_F=`#version 300 es
precision highp float;in vec2 vUV;uniform sampler2D uTex;uniform vec2 uTexel;out vec4 o;
void main(){vec2 d=uTexel;
 vec3 c=texture(uTex,vUV+vec2(-d.x,-d.y)).rgb+texture(uTex,vUV+vec2(0.0,-d.y)).rgb*2.0+texture(uTex,vUV+vec2(d.x,-d.y)).rgb
 +texture(uTex,vUV+vec2(-d.x,0.0)).rgb*2.0+texture(uTex,vUV).rgb*4.0+texture(uTex,vUV+vec2(d.x,0.0)).rgb*2.0
 +texture(uTex,vUV+vec2(-d.x,d.y)).rgb+texture(uTex,vUV+vec2(0.0,d.y)).rgb*2.0+texture(uTex,vUV+vec2(d.x,d.y)).rgb;
 o=vec4(c/16.0,1.0);}`;
const SH_FIN_F=`#version 300 es
precision highp float;in vec2 vUV;
uniform sampler2D uScene,uBloom,uDof,uDepth;
uniform float uBloomK,uExpo,uTime,uGrain,uCA,uDofK,uFocus,uNear,uFar,uPulse;uniform vec2 uRes;uniform vec4 uWave;
out vec4 o;
float lin(float d){float z=d*2.0-1.0;return 2.0*uNear*uFar/(uFar+uNear-z*(uFar-uNear));}
vec3 tone(vec3 c){float l=max(max(c.r,c.g),c.b);float t=0.7;if(l>t){float nl=t+(1.0-t)*(1.0-exp(-(l-t)/(1.0-t)));c*=nl/l;}return c;}
void main(){
 vec2 uv=vUV;
 if(uWave.w>0.0){vec2 dv=uv-uWave.xy;float asp=uRes.x/uRes.y;dv.x*=asp;float d=length(dv);float rg=exp(-pow((d-uWave.z)/0.045,2.0));vec2 dir=dv/max(d,1e-4);dir.x/=asp;uv-=dir*rg*uWave.w;}
 vec2 cc=uv-0.5;float r2=dot(cc,cc);
 vec2 ca=cc*(uCA*(0.3+r2*2.0)+uPulse*0.01);
 vec3 col=vec3(texture(uScene,uv+ca).r,texture(uScene,uv).g,texture(uScene,uv-ca).b);
 float dep=lin(texture(uDepth,uv).r);
 float coc=smoothstep(60.0,240.0,abs(dep-uFocus))*uDofK;
 col=mix(col,texture(uDof,uv).rgb,coc);
 col+=texture(uBloom,uv).rgb*uBloomK;
 col*=uExpo;
 float l=max(max(col.r,col.g),col.b);
 col=mix(col,vec3(dot(col,vec3(0.3,0.59,0.11))),smoothstep(1.4,5.0,l)*0.5);
 col=tone(col);
 float lum=dot(col,vec3(0.299,0.587,0.114));
 col=mix(col*vec3(0.9,0.95,1.12)+vec3(0.006,0.01,0.03),col*vec3(1.06,1.0,0.9),smoothstep(0.12,0.8,lum));
 col=mix(vec3(lum),col,1.12);
 col=(col-0.45)*1.06+0.45;
 float v=1.0-smoothstep(0.16,0.78,r2*1.2);
 col*=mix(vec3(0.42,0.38,0.58),vec3(1.0),v);
 col=mix(col,col*vec3(1.3,0.62,0.62),uPulse*0.3*smoothstep(0.08,0.5,r2));
 float n=fract(sin(dot(floor(uv*uRes)+fract(uTime*7.0)*vec2(91.7,37.3),vec2(12.9898,78.233)))*43758.5453);
 col+=(n-0.5)*uGrain;
 o=vec4(clamp(col,0.0,1.0),1.0);}`;
const PRG={};
let HDR=false,MSN=4,RS=1,RT=null,FSVAO=null,POST=true;
function mkProg(vs,fs,defs){
  const p=gl.createProgram();
  for(const [t,s] of [[gl.VERTEX_SHADER,vs],[gl.FRAGMENT_SHADER,fs]]){const sh=gl.createShader(t);gl.shaderSource(sh,s.replace('#version 300 es','#version 300 es\n'+(defs||'')));gl.compileShader(sh);if(!gl.getShaderParameter(sh,gl.COMPILE_STATUS))throw new Error(gl.getShaderInfoLog(sh));gl.attachShader(p,sh);}
  gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw new Error(gl.getProgramInfoLog(p));
  const u={},n=gl.getProgramParameter(p,gl.ACTIVE_UNIFORMS);for(let i=0;i<n;i++){const inf=gl.getActiveUniform(p,i);u[inf.name.replace('[0]','')]=gl.getUniformLocation(p,inf.name);}
  return{p,u};}
function initGL(){
  try{gl=glc.getContext('webgl2',{antialias:false,alpha:true,premultipliedAlpha:true,powerPreference:'high-performance'});}catch(e){gl=null;}
  if(!gl)return false;
  try{
    PRG.toon=mkProg(SH_TOON_V,SH_TOON_F,'');PRG.toonI=mkProg(SH_TOON_V,SH_TOON_F,'#define INST\n');
    PRG.line=mkProg(SH_LINE_V,SH_LINE_F,'');PRG.lineI=mkProg(SH_LINE_V,SH_LINE_F,'#define INST\n');
    PRG.pt=mkProg(SH_PT_V,SH_PT_F,'');PRG.flat=mkProg(SH_FLAT_V,SH_FLAT_F,'');PRG.tex=mkProg(SH_TEX_V,SH_TEX_F,'');
  }catch(e){console.error(e);return false;}
  try{PRG.down=mkProg(SH_FS_V,SH_DOWN_F,'');PRG.up=mkProg(SH_FS_V,SH_UP_F,'');PRG.fin=mkProg(SH_FS_V,SH_FIN_F,'');}catch(e){console.error(e);POST=false;}
  HDR=!!gl.getExtension('EXT_color_buffer_float');MSN=Math.min(4,gl.getParameter(gl.MAX_SAMPLES)||0);FSVAO=gl.createVertexArray();
  SS=Q.ss;
  try{
    shTex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,shTex);gl.texStorage2D(gl.TEXTURE_2D,1,gl.DEPTH_COMPONENT24,SS,SS);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_COMPARE_MODE,gl.COMPARE_REF_TO_TEXTURE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_COMPARE_FUNC,gl.LEQUAL);
    shFB=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,shFB);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.TEXTURE_2D,shTex,0);gl.drawBuffers([gl.NONE]);gl.readBuffer(gl.NONE);
    shOn=gl.checkFramebufferStatus(gl.FRAMEBUFFER)===gl.FRAMEBUFFER_COMPLETE;gl.bindFramebuffer(gl.FRAMEBUFFER,null);
  }catch(e){shOn=false;}
  if(!shOn){shTex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,shTex);gl.texStorage2D(gl.TEXTURE_2D,1,gl.DEPTH_COMPONENT24,1,1);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_COMPARE_MODE,gl.COMPARE_REF_TO_TEXTURE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.NEAREST);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.NEAREST);}
  return true;
}
// ---------- 离屏渲染目标（MSAA + HDR）----------
function mkTex(w,h,fmt,filter){const t=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,t);gl.texStorage2D(gl.TEXTURE_2D,1,fmt,w,h);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,filter);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,filter);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);return t;}
function fbTex(tex,dep){const f=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,f);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,tex,0);if(dep)gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.TEXTURE_2D,dep,0);return f;}
function freeRT(){if(!RT)return;for(const x of RT.texs)gl.deleteTexture(x);for(const x of RT.fbs)gl.deleteFramebuffer(x);for(const x of RT.rbs)gl.deleteRenderbuffer(x);RT=null;}
function buildRT(w,h){
  const CF=HDR?gl.RGBA16F:gl.RGBA8,r={w,h,texs:[],fbs:[],rbs:[]};RT=r;
  r.msC=gl.createRenderbuffer();gl.bindRenderbuffer(gl.RENDERBUFFER,r.msC);gl.renderbufferStorageMultisample(gl.RENDERBUFFER,MSN,CF,w,h);
  r.msD=gl.createRenderbuffer();gl.bindRenderbuffer(gl.RENDERBUFFER,r.msD);gl.renderbufferStorageMultisample(gl.RENDERBUFFER,MSN,gl.DEPTH_COMPONENT24,w,h);r.rbs.push(r.msC,r.msD);
  r.ms=gl.createFramebuffer();r.fbs.push(r.ms);gl.bindFramebuffer(gl.FRAMEBUFFER,r.ms);gl.framebufferRenderbuffer(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.RENDERBUFFER,r.msC);gl.framebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.RENDERBUFFER,r.msD);
  if(gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE)return false;
  r.sc=mkTex(w,h,CF,gl.LINEAR);r.dp=mkTex(w,h,gl.DEPTH_COMPONENT24,gl.NEAREST);r.texs.push(r.sc,r.dp);r.scF=fbTex(r.sc,r.dp);r.fbs.push(r.scF);
  if(gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE)return false;
  const chain=(n)=>{const out=[];let bw=w,bh=h;for(let i=0;i<n;i++){bw=Math.max(2,bw>>1);bh=Math.max(2,bh>>1);const t=mkTex(bw,bh,CF,gl.LINEAR),f=fbTex(t,null);r.texs.push(t);r.fbs.push(f);out.push({t,f,w:bw,h:bh});}return out;};
  r.bl=chain(Q.bloom);r.df=chain(2);
  return gl.checkFramebufferStatus(gl.FRAMEBUFFER)===gl.FRAMEBUFFER_COMPLETE;
}
function setupRT(){
  if(!POST)return false;
  const w=Math.max(16,Math.round(glc.width*RS)),h=Math.max(16,Math.round(glc.height*RS));
  if(RT&&RT.w===w&&RT.h===h)return true;
  freeRT();
  let ok=false;
  for(const [hdr,ms] of [[HDR,MSN],[false,MSN],[false,0]]){HDR=hdr;MSN=ms;try{ok=buildRT(w,h);}catch(e){ok=false;}if(ok)break;freeRT();}
  gl.bindFramebuffer(gl.FRAMEBUFFER,null);
  if(!ok){POST=false;freeRT();}
  return ok;
}
function postFX(){
  const r=RT;gl.disable(gl.DEPTH_TEST);gl.disable(gl.CULL_FACE);gl.disable(gl.BLEND);gl.depthMask(false);gl.bindVertexArray(FSVAO);gl.activeTexture(gl.TEXTURE0);
  let pr=PRG.down;gl.useProgram(pr.p);gl.uniform1i(pr.u.uTex,0);
  let src=r.sc,sw=r.w,sh=r.h;
  for(let i=0;i<r.bl.length;i++){const d=r.bl[i];gl.bindFramebuffer(gl.FRAMEBUFFER,d.f);gl.viewport(0,0,d.w,d.h);gl.bindTexture(gl.TEXTURE_2D,src);gl.uniform2f(pr.u.uTexel,1/sw,1/sh);gl.uniform1f(pr.u.uThr,i===0?(HDR?LOOK.thr:0.82):0);gl.uniform1f(pr.u.uKnee,HDR?LOOK.knee:0.15);gl.drawArrays(gl.TRIANGLES,0,3);src=d.t;sw=d.w;sh=d.h;}
  pr=PRG.up;gl.useProgram(pr.p);gl.uniform1i(pr.u.uTex,0);gl.enable(gl.BLEND);gl.blendFunc(gl.ONE,gl.ONE);
  for(let i=r.bl.length-1;i>0;i--){const s=r.bl[i],d=r.bl[i-1];gl.bindFramebuffer(gl.FRAMEBUFFER,d.f);gl.viewport(0,0,d.w,d.h);gl.bindTexture(gl.TEXTURE_2D,s.t);gl.uniform2f(pr.u.uTexel,1/s.w,1/s.h);gl.drawArrays(gl.TRIANGLES,0,3);}
  gl.disable(gl.BLEND);
  pr=PRG.down;gl.useProgram(pr.p);gl.uniform1f(pr.u.uThr,0);src=r.sc;sw=r.w;sh=r.h;
  for(const d of r.df){gl.bindFramebuffer(gl.FRAMEBUFFER,d.f);gl.viewport(0,0,d.w,d.h);gl.bindTexture(gl.TEXTURE_2D,src);gl.uniform2f(pr.u.uTexel,1/sw,1/sh);gl.drawArrays(gl.TRIANGLES,0,3);src=d.t;sw=d.w;sh=d.h;}
  gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.viewport(0,0,glc.width,glc.height);
  pr=PRG.fin;gl.useProgram(pr.p);const u=pr.u;
  gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,r.sc);gl.uniform1i(u.uScene,0);
  gl.activeTexture(gl.TEXTURE1);gl.bindTexture(gl.TEXTURE_2D,r.bl[0].t);gl.uniform1i(u.uBloom,1);
  gl.activeTexture(gl.TEXTURE2);gl.bindTexture(gl.TEXTURE_2D,r.df[r.df.length-1].t);gl.uniform1i(u.uDof,2);
  gl.activeTexture(gl.TEXTURE3);gl.bindTexture(gl.TEXTURE_2D,r.dp);gl.uniform1i(u.uDepth,3);
  gl.uniform1f(u.uBloomK,HDR?LOOK.bloom:LOOK.bloom*0.8);gl.uniform1f(u.uExpo,LOOK.expo);gl.uniform1f(u.uTime,time);gl.uniform1f(u.uGrain,LOOK.grain);gl.uniform1f(u.uCA,LOOK.ca);
  gl.uniform1f(u.uDofK,state==='title'?Q.dof*0.6:Q.dof);gl.uniform1f(u.uFocus,camDist);gl.uniform1f(u.uNear,20);gl.uniform1f(u.uFar,5000);gl.uniform1f(u.uPulse,fxPulse);gl.uniform2f(u.uRes,glc.width,glc.height);
  if(wave){const p=waveScreen(),k=wave.t/wave.life;gl.uniform4f(u.uWave,p.x/W,1-p.y/H,0.02+k*0.3*wave.r,0.032*(1-k)*wave.s*(0.6+0.4*FXK));}else gl.uniform4f(u.uWave,0,0,0,0);
  gl.drawArrays(gl.TRIANGLES,0,3);
  gl.activeTexture(gl.TEXTURE0);gl.depthMask(true);gl.enable(gl.DEPTH_TEST);
}
const LOOK={expo:1.0,bloom:0.055,grain:0.026,ca:0.0013,thr:1.2,knee:0.4};
function vbuf(loc,data,size,usage){const b=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,b);gl.bufferData(gl.ARRAY_BUFFER,data,usage||gl.STATIC_DRAW);gl.enableVertexAttribArray(loc);gl.vertexAttribPointer(loc,size,gl.FLOAT,false,0,0);return b;}
function upload(m){
  const o={};o.vao=gl.createVertexArray();gl.bindVertexArray(o.vao);
  vbuf(0,new Float32Array(m.P),3);vbuf(1,new Float32Array(m.N),3);vbuf(2,new Float32Array(m.C),4);o.n=m.P.length/3;
  if(m.H.length){o.hvao=gl.createVertexArray();gl.bindVertexArray(o.hvao);vbuf(0,new Float32Array(m.H),3);o.hn=m.H.length/3;}
  gl.bindVertexArray(null);return o;}
function uploadInst(m,max){
  const o=upload(m);o.max=max;o.count=0;o.inst=new Float32Array(max*16);o.ie=new Float32Array(max*4);
  o.ib=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,o.ib);gl.bufferData(gl.ARRAY_BUFFER,o.inst.byteLength,gl.DYNAMIC_DRAW);
  o.eb=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,o.eb);gl.bufferData(gl.ARRAY_BUFFER,o.ie.byteLength,gl.DYNAMIC_DRAW);
  for(const v of [o.vao,o.hvao]){if(!v)continue;gl.bindVertexArray(v);gl.bindBuffer(gl.ARRAY_BUFFER,o.ib);for(let i=0;i<4;i++){gl.enableVertexAttribArray(3+i);gl.vertexAttribPointer(3+i,4,gl.FLOAT,false,64,i*16);gl.vertexAttribDivisor(3+i,1);}
    gl.bindBuffer(gl.ARRAY_BUFFER,o.eb);gl.enableVertexAttribArray(7);gl.vertexAttribPointer(7,4,gl.FLOAT,false,16,0);gl.vertexAttribDivisor(7,1);}
  gl.bindVertexArray(null);return o;}
function instPush(o,M,e0,e1,e2){if(!o||o.count>=o.max)return;o.inst.set(M,o.count*16);const j=o.count*4;o.ie[j]=e0;o.ie[j+1]=e1;o.ie[j+2]=e2;o.ie[j+3]=1;o.count++;}
function instFlush(o){if(!o.count)return;gl.bindBuffer(gl.ARRAY_BUFFER,o.ib);gl.bufferSubData(gl.ARRAY_BUFFER,0,o.inst,0,o.count*16);gl.bindBuffer(gl.ARRAY_BUFFER,o.eb);gl.bufferSubData(gl.ARRAY_BUFFER,0,o.ie,0,o.count*4);}
function dynBuf(layout,maxVerts){
  const o={stride:layout.reduce((a,l)=>a+l[1],0),max:maxVerts,n:0};o.data=new Float32Array(o.stride*maxVerts);o.vao=gl.createVertexArray();gl.bindVertexArray(o.vao);o.b=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,o.b);gl.bufferData(gl.ARRAY_BUFFER,o.data.byteLength,gl.DYNAMIC_DRAW);
  let off=0;for(const [loc,size] of layout){gl.enableVertexAttribArray(loc);gl.vertexAttribPointer(loc,size,gl.FLOAT,false,o.stride*4,off*4);off+=size;}
  gl.bindVertexArray(null);return o;}
function flushDyn(o){if(!o.n)return;gl.bindBuffer(gl.ARRAY_BUFFER,o.b);gl.bufferSubData(gl.ARRAY_BUFFER,0,o.data,0,o.n*o.stride);}

// ---------- 场景节点 ----------
class Node{
  constructor(mesh,mat){this.mesh=mesh||null;this.mat=mat||null;this.p=[0,0,0];this.r=[0,0,0];this.s=[1,1,1];this.ch=[];this.vis=true;this.W=new Float32Array(16);}
  add(n){this.ch.push(n);return n;}
  upd(pw){m4trs(this.W,this.p[0],this.p[1],this.p[2],this.r[0],this.r[1],this.r[2],this.s[0],this.s[1],this.s[2]);if(pw)m4mul(this.W,pw,this.W);for(const c of this.ch)c.upd(this.W);}
}
const mkMat=(o)=>Object.assign({em:[0,0,0],op:1,cast:true},o||{});
function collect(n,list){if(!n.vis)return;if(n.mesh)list.push(n);for(const c of n.ch)collect(c,list);}
