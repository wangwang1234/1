(() => {
'use strict';
const TAU=Math.PI*2;
const clamp=(v,a,b)=>v<a?a:v>b?b:v;
const lerp=(a,b,t)=>a+(b-a)*t;
const rand=(a,b)=>a+Math.random()*(b-a);
const randi=(a,b)=>Math.floor(a+Math.random()*(b-a+1));
const d2=(ax,ay,bx,by)=>{const dx=ax-bx,dy=ay-by;return dx*dx+dy*dy;};
const damp=(c,t,k,dt)=>c+(t-c)*(1-Math.exp(-k*dt));
function angDiff(a,b){let d=(b-a)%TAU;if(d>Math.PI)d-=TAU;else if(d<-Math.PI)d+=TAU;return d;}
function turnTo(a,b,m){return a+clamp(angDiff(a,b),-m,m);}
function spring(s,t,k,c,dt){s.w+=((t-s.v)*k-s.w*c)*dt;s.v+=s.w*dt;}
function mulberry32(a){return function(){a|=0;a=(a+0x6D2B79F5)|0;let t=Math.imul(a^(a>>>15),1|a);t=(t+Math.imul(t^(t>>>7),61|t))^t;return((t^(t>>>14))>>>0)/4294967296;};}
const FONT='"ZCOOL KuaiLe","PingFang SC","Hiragino Sans GB","Microsoft YaHei","Noto Sans SC",sans-serif';
const FONT_UI='"PingFang SC","Hiragino Sans GB","Microsoft YaHei","Noto Sans SC",system-ui,sans-serif';
const store={get(k,d){try{const v=localStorage.getItem(k);return v==null?d:JSON.parse(v);}catch(e){return d;}},set(k,v){try{localStorage.setItem(k,JSON.stringify(v));}catch(e){}}};

// ---------- 合成音效 ----------
const SFX=(()=>{
  let ac=null,out=null,nb=null,muted=false;const last={};
  function init(){try{if(!ac){const AC=window.AudioContext||window.webkitAudioContext;if(!AC)return;ac=new AC();const comp=ac.createDynamicsCompressor();comp.threshold.value=-14;comp.ratio.value=4;out=ac.createGain();out.gain.value=muted?0:0.6;out.connect(comp);comp.connect(ac.destination);const n=Math.floor(ac.sampleRate*1.2);nb=ac.createBuffer(1,n,ac.sampleRate);const d=nb.getChannelData(0);for(let i=0;i<n;i++)d[i]=Math.random()*2-1;const o=ac.createOscillator(),o2=ac.createOscillator(),g=ac.createGain();o.frequency.value=58;o2.type='triangle';o2.frequency.value=117;g.gain.value=0.016;o.connect(g);o2.connect(g);g.connect(out);o.start();o2.start();}if(ac.state==='suspended')ac.resume();}catch(e){ac=null;}}
  function ok(k,gap){if(!ac||muted)return false;if(k){const t=ac.currentTime;if(last[k]!=null&&t-last[k]<gap)return false;last[k]=t;}return true;}
  function tone(type,f0,f1,dur,vol,delay=0){const t0=ac.currentTime+delay,o=ac.createOscillator(),g=ac.createGain();o.type=type;o.frequency.setValueAtTime(f0,t0);if(f1!==f0)o.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t0+dur);g.gain.setValueAtTime(0.0001,t0);g.gain.exponentialRampToValueAtTime(vol,t0+0.004);g.gain.exponentialRampToValueAtTime(0.0001,t0+dur);o.connect(g);g.connect(out);o.start(t0);o.stop(t0+dur+0.03);}
  function noise(dur,vol,ft,f0,f1,q=1,delay=0){const t0=ac.currentTime+delay,s=ac.createBufferSource(),f=ac.createBiquadFilter(),g=ac.createGain();s.buffer=nb;f.type=ft;f.Q.value=q;f.frequency.setValueAtTime(f0,t0);if(f1!==f0)f.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t0+dur);g.gain.setValueAtTime(0.0001,t0);g.gain.exponentialRampToValueAtTime(vol,t0+0.004);g.gain.exponentialRampToValueAtTime(0.0001,t0+dur);s.connect(f);f.connect(g);g.connect(out);s.start(t0,Math.random()*0.5,dur+0.05);}
  return{init,
    get muted(){return muted;},get ac(){return ac;},get bus(){return out;},
    setMuted(m){muted=m;if(out)out.gain.value=m?0:0.6;},
    shoot(){if(!ok('shoot',0.03))return;const k=rand(0.92,1.08);noise(0.07,0.3,'bandpass',2600*k,700,0.8);tone('square',260*k,80,0.08,0.1);tone('sine',150,50,0.1,0.22);},
    empty(){if(ok('empty',0.15))tone('square',1800,1700,0.025,0.07);},
    reload(){if(!ok('reload',0.2))return;tone('square',900,700,0.03,0.07);noise(0.12,0.1,'highpass',3000,2000,0.7,0.07);},
    reloaded(){if(!ok('reloaded',0.2))return;tone('square',1200,900,0.03,0.09);tone('square',700,500,0.04,0.09,0.06);},
    hit(){if(ok('hit',0.035))tone('triangle',rand(850,1000),420,0.05,0.12);},
    ratDie(){if(!ok('die',0.05))return;tone('sine',1500,2400,0.07,0.15);tone('sine',2200,700,0.16,0.13,0.07);noise(0.12,0.14,'lowpass',1800,300,0.7);},
    roachDie(){if(!ok('die',0.05))return;noise(0.09,0.28,'lowpass',3000,400,1.2);tone('square',180,60,0.07,0.09);},
    hurt(){if(!ok('hurt',0.08))return;tone('sine',380,120,0.18,0.3);tone('triangle',1200,1800,0.06,0.07,0.02);noise(0.1,0.18,'lowpass',1200,200);},
    munch(f){if(!ok('munch',0.04))return;const b=260+f*520;tone('sine',b,b*1.6,0.07,0.2);noise(0.05,0.07,'bandpass',1500,900,2,0.01);},
    boing(up){if(!ok('boing',0.1))return;if(up){tone('sine',300,900,0.16,0.28);tone('triangle',600,1300,0.14,0.09,0.03);}else tone('sine',900,400,0.16,0.22);},
    spit(){if(!ok('spit',0.05))return;noise(0.08,0.26,'lowpass',2500,500,0.9);tone('sine',700,150,0.1,0.17);},
    coin(){if(!ok('coin',0.05))return;tone('square',1568,1568,0.08,0.06);tone('square',2093,2093,0.16,0.06,0.06);},
    fire(){if(!ok('fire',0.08))return;noise(0.45,0.3,'lowpass',1800,200,0.6);tone('sawtooth',120,60,0.3,0.07);},
    thud(){if(!ok('thud',0.06))return;tone('sine',140,45,0.22,0.4);noise(0.12,0.18,'lowpass',800,100,0.7);},
    roll(){if(ok('roll',0.1))noise(0.22,0.15,'bandpass',400,1600,1.2);},
    tick(){if(ok('tick',0.09))tone('square',2200,2200,0.015,0.035);},
    open(){if(!ok('open',0.1))return;tone('sine',500,900,0.08,0.18);tone('triangle',1320,1320,0.1,0.07,0.08);tone('triangle',1760,1760,0.14,0.07,0.14);},
    alert(){if(ok('alert',0.25))tone('square',880,1320,0.08,0.05);},
    eshot(){if(!ok('eshot',0.04))return;noise(0.06,0.11,'bandpass',1500,600,1);tone('square',420,200,0.05,0.05);},
    bite(){if(ok('bite',0.1))noise(0.05,0.2,'highpass',2000,1200,0.8);},
    stuck(){if(!ok('stuck',0.4))return;tone('sine',520,380,0.12,0.15);tone('sine',380,300,0.14,0.13,0.12);},
    full(){if(!ok('full',0.3))return;tone('square',300,280,0.08,0.07);tone('square',300,280,0.08,0.07,0.1);},
    beep(){if(ok(null))tone('square',880,880,0.06,0.06);},
    win(){if(ok(null))[523,659,784,1047].forEach((f,i)=>tone('triangle',f,f,0.22,0.13,i*0.09));},
    lose(){if(ok(null))[392,330,262,196].forEach((f,i)=>tone('triangle',f,f*0.98,0.25,0.11,i*0.13));},
    click(){if(ok('click',0.05))tone('sine',700,900,0.05,0.07);},
    ric(){if(ok('ric',0.05))tone('sine',2400,3400,0.08,0.05);},
    wall(){if(ok('wall',0.05))noise(0.04,0.07,'bandpass',3000,2000,1.5);},
    puff(){if(ok('puff',0.2))noise(0.12,0.08,'lowpass',900,300,0.7);}
  };
})();

// ---------- 地图 ----------
const SX=0.7,SY=0.86,OW=7200,OH=3600;
const WW=Math.round(OW*SX),WH=Math.round(OH*SY),MIDX=WW/2,MIDY=WH/2,SPEED0=230;
const qx=x=>x*SX,qy=y=>y*SY,LN=a=>a.map(p=>[qx(p[0]),qy(p[1])]);
const TEAMS=['blue','red'],ENEMY={blue:'red',red:'blue'};
const TCOL={blue:'#4fa3ff',red:'#ff5b5b',neutral:'#ffd166'},TNAME={blue:'蓝队',red:'红队'};
const BASE_POS={blue:{x:qx(560)+40,y:MIDY},red:{x:WW-qx(560)-40,y:MIDY}};
const LANES={top:LN([[760,1640],[930,960],[1450,640],[2600,520],[3600,500],[OW-2600,520],[OW-1450,640],[OW-930,960],[OW-760,1640]]),
  mid:LN([[780,1800],[3600,1800],[OW-780,1800]]),
  bot:LN([[760,OH-1640],[930,OH-960],[1450,OH-640],[2600,OH-520],[3600,OH-500],[OW-2600,OH-520],[OW-1450,OH-640],[OW-930,OH-960],[OW-760,OH-1640]])};
const LANE_REV={top:[...LANES.top].reverse(),mid:[...LANES.mid].reverse(),bot:[...LANES.bot].reverse()};
function lanePath(team,lane){return team==='blue'?LANES[lane]:LANE_REV[lane];}
const TURRETS={blue:LN([[1950,420],[2150,1650],[1950,OH-420]]),red:LN([[OW-1950,420],[OW-2150,OH-1650],[OW-1950,OH-420]])};
const OBS_Q=[[1180,800,560,80,'counter',72],[1960,760,110,250,'books',62],[2380,880,200,140,'box',56],[2820,780,250,120,'bottles',78],[1280,1440,460,70,'counter',56],[2160,1480,360,70,'books',52],[2960,1420,170,160,'box',56],[3330,880,110,400,'counter',74],[260,1180,320,70,'box',52],[820,1420,90,90,'box',56],[3060,180,160,120,'box',50]];
const CIRC_Q=[[2160,1180,46,'can',58],[3080,1120,40,'can',50],[1060,1160,52,'pot',62],[2480,330,44,'can',52],[1250,380,50,'pot',56],[1700,1650,38,'can',46]];
const CAMP_Q=[['roach',1560,1160],['rat',2620,1180]];
const CRATE_Q=[[1060,1330],[2060,1330],[3230,1660],[2300,280],[1700,960]];
const LAMP_Q=[[950,640],[2480,1330]],BARREL_Q=[[1850,1260],[3050,640]],BOX_Q=[[2250,1640],[1650,470],[3150,1000]],PAD_Q=[[1000,1350,2700,1100]];
const BOSS_POS={x:MIDX,y:qy(1130)},BIGCRATE_POS={x:MIDX,y:WH-qy(1130)};
const solids=[],camps=[],crateSpots=[],propSpots=[],padSpots=[];
const Q4=[[0,0],[1,0],[0,1],[1,1]];
function rect(x,y,w,h,kind,ht){solids.push({x,y,w,h,kind,ht});}
function circ(x,y,r,kind,ht){solids.push({c:true,x,y,r,kind,ht});}
function buildMap(){
  solids.length=0;camps.length=0;crateSpots.length=0;propSpots.length=0;padSpots.length=0;
  rect(0,0,WW,60,'wall',0);rect(0,WH-60,WW,60,'wall',0);rect(0,0,60,WH,'wall',0);rect(WW-60,0,60,WH,'wall',0);
  const mx=(f,x)=>f?OW-x:x,my=(f,y)=>f?OH-y:y;
  for(const o of OBS_Q)for(const [fx,fy] of Q4){const x=fx?OW-o[0]-o[2]:o[0],y=fy?OH-o[1]-o[3]:o[1];rect(qx(x),qy(y),o[2]*SX,o[3]*SY,o[4],o[5]);}
  for(const o of CIRC_Q)for(const [fx,fy] of Q4)circ(qx(mx(fx,o[0])),qy(my(fy,o[1])),o[2]*0.85,o[3],o[4]);
  for(const c of CAMP_Q)for(const [fx,fy] of Q4)camps.push({type:c[0],x:qx(mx(fx,c[1])),y:qy(my(fy,c[2])),alive:0,resp:0});
  for(const c of CRATE_Q)for(const [fx,fy] of Q4)crateSpots.push({x:qx(mx(fx,c[0])),y:qy(my(fy,c[1])),big:false,resp:0,cur:null});
  crateSpots.push({x:BIGCRATE_POS.x,y:BIGCRATE_POS.y,big:true,resp:45,cur:null});
  for(const [k,L] of [['lamp',LAMP_Q],['barrel',BARREL_Q],['box',BOX_Q]])for(const p of L)for(const [fx,fy] of Q4)propSpots.push({kind:k,x:qx(mx(fx,p[0])),y:qy(my(fy,p[1]))});
  propSpots.push({kind:'lamp',x:MIDX,y:qy(1580)},{kind:'lamp',x:MIDX,y:WH-qy(1580)});
  for(const p of PAD_Q)for(const [fx,fy] of Q4)padSpots.push({x:qx(mx(fx,p[0])),y:qy(my(fy,p[1])),tx:qx(mx(fx,p[2])),ty:qy(my(fy,p[3])),cd:0,anim:0});
}
// ---------- 物理 ----------
function overlapsSolid(x,y,r){for(const s of solids){if(s.off)continue;if(s.c){const rr=s.r+r;if(d2(x,y,s.x,s.y)<rr*rr-0.01)return true;}else{const cx=clamp(x,s.x,s.x+s.w),cy=clamp(y,s.y,s.y+s.h);if(d2(x,y,cx,cy)<r*r-0.01)return true;}}return false;}
function pointSolid(x,y,r){for(const s of solids){if(s.off)continue;if(s.c){const rr=s.r+r;if(d2(x,y,s.x,s.y)<rr*rr)return s;}else if(x>s.x-r&&x<s.x+s.w+r&&y>s.y-r&&y<s.y+s.h+r)return s;}return null;}
function resolveCircle(o,r){let any=false;for(let it=0;it<4;it++){let moved=false;for(const s of solids){if(s.off)continue;if(s.c){const dx=o.x-s.x,dy=o.y-s.y,dd=dx*dx+dy*dy,rr=r+s.r;if(dd<rr*rr){const d=Math.sqrt(dd)||0.0001,p=rr-d;o.x+=dx/d*p;o.y+=dy/d*p;moved=true;}}else{const cx=clamp(o.x,s.x,s.x+s.w),cy=clamp(o.y,s.y,s.y+s.h),dx=o.x-cx,dy=o.y-cy,dd=dx*dx+dy*dy;if(dd<r*r){if(dd>1e-8){const d=Math.sqrt(dd),p=r-d;o.x+=dx/d*p;o.y+=dy/d*p;}else{const l=o.x-s.x,rg=s.x+s.w-o.x,t=o.y-s.y,b=s.y+s.h-o.y,m=Math.min(l,rg,t,b);if(m===l)o.x=s.x-r;else if(m===rg)o.x=s.x+s.w+r;else if(m===t)o.y=s.y-r;else o.y=s.y+s.h+r;}moved=true;}}}if(!moved)break;any=true;}return any;}
function segRect(x1,y1,x2,y2,s){let t0=0,t1=1;const dx=x2-x1,dy=y2-y1;const p=[-dx,dx,-dy,dy],q=[x1-s.x,s.x+s.w-x1,y1-s.y,s.y+s.h-y1];for(let i=0;i<4;i++){if(p[i]===0){if(q[i]<0)return false;}else{const t=q[i]/p[i];if(p[i]<0){if(t>t1)return false;if(t>t0)t0=t;}else{if(t<t0)return false;if(t<t1)t1=t;}}}return true;}
function segCirc(x1,y1,x2,y2,c){const dx=x2-x1,dy=y2-y1,l2=dx*dx+dy*dy||1;const t=clamp(((c.x-x1)*dx+(c.y-y1)*dy)/l2,0,1);return d2(x1+dx*t,y1+dy*t,c.x,c.y)<c.r*c.r;}
function hasLOS(x1,y1,x2,y2){for(const s of solids){if(s.off)continue;if(s.c?segCirc(x1,y1,x2,y2,s):segRect(x1,y1,x2,y2,s))return false;}return true;}

// ---------- 寻路 ----------
const NAV={cell:50,gc:0,gr:0,pass:null,q:null};
function buildNav(){NAV.gc=Math.ceil(WW/NAV.cell);NAV.gr=Math.ceil(WH/NAV.cell);NAV.pass=new Uint8Array(NAV.gc*NAV.gr);NAV.q=new Int32Array(NAV.gc*NAV.gr);
  for(let j=0;j<NAV.gr;j++)for(let i=0;i<NAV.gc;i++)NAV.pass[j*NAV.gc+i]=overlapsSolid((i+0.5)*NAV.cell,(j+0.5)*NAV.cell,20)?0:1;}
const FCACHE=new Map();
function cellOf(x,y){return clamp(Math.floor(y/NAV.cell),0,NAV.gr-1)*NAV.gc+clamp(Math.floor(x/NAV.cell),0,NAV.gc-1);}
function fieldTo(x,y){
  let k=cellOf(x,y);const gc=NAV.gc,gr=NAV.gr,P=NAV.pass;
  if(!P[k]){const ci=k%gc,cj=(k/gc)|0;let best=-1,bd=1e9;for(let dj=-4;dj<=4;dj++)for(let di=-4;di<=4;di++){const i=ci+di,j=cj+dj;if(i<0||j<0||i>=gc||j>=gr)continue;const kk=j*gc+i;if(!P[kk])continue;const dd=di*di+dj*dj;if(dd<bd){bd=dd;best=kk;}}if(best<0)return null;k=best;}
  let F=FCACHE.get(k);if(F)return F;
  if(FCACHE.size>40)FCACHE.clear();
  F=new Int16Array(gc*gr).fill(-1);const Q=NAV.q;let h=0,t=0;F[k]=0;Q[t++]=k;
  while(h<t){const c=Q[h++],i=c%gc,j=(c/gc)|0,dv=F[c]+1;
    for(let dj=-1;dj<=1;dj++)for(let di=-1;di<=1;di++){if(!di&&!dj)continue;const ni=i+di,nj=j+dj;if(ni<0||nj<0||ni>=gc||nj>=gr)continue;const nk=nj*gc+ni;if(!P[nk]||F[nk]>=0)continue;if(di&&dj&&(!P[j*gc+ni]||!P[nj*gc+i]))continue;F[nk]=dv;Q[t++]=nk;}}
  FCACHE.set(k,F);return F;
}
function fieldDir(F,x,y,tx,ty){
  let dx,dy;
  if(F){const gc=NAV.gc,gr=NAV.gr,i=clamp(Math.floor(x/NAV.cell),0,gc-1),j=clamp(Math.floor(y/NAV.cell),0,gr-1),here=F[j*gc+i];
    let best=here<0?32767:here,bx=0,by=0,found=false;
    for(let dj=-1;dj<=1;dj++)for(let di=-1;di<=1;di++){if(!di&&!dj)continue;const ni=i+di,nj=j+dj;if(ni<0||nj<0||ni>=gc||nj>=gr)continue;const f=F[nj*gc+ni];if(f<0)continue;if(di&&dj&&(F[j*gc+ni]<0||F[nj*gc+i]<0))continue;if(f<best){best=f;bx=(ni+0.5)*NAV.cell;by=(nj+0.5)*NAV.cell;found=true;}}
    if(found&&best>1){dx=bx-x;dy=by-y;}else{dx=tx-x;dy=ty-y;}}
  else{dx=tx-x;dy=ty-y;}
  const l=Math.hypot(dx,dy)||1;return{x:dx/l,y:dy/l};
}
