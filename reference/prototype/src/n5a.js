// ---------- HUD 画布 ----------
const cv=$('game'),ctx=cv.getContext('2d');
let W=800,H=600,DPR=1,uiS=1;
function resize(){
  const r=cv.getBoundingClientRect();W=Math.max(1,r.width);H=Math.max(1,r.height);
  DPR=Math.min(window.devicePixelRatio||1,2);cv.width=Math.round(W*DPR);cv.height=Math.round(H*DPR);
  let gd=Math.min(window.devicePixelRatio||1,coarse?1.5:2);while(gd>1&&W*H*gd*gd>3.6e6)gd-=0.25;
  glc.width=Math.max(1,Math.round(W*gd));glc.height=Math.max(1,Math.round(H*gd));
  uiS=clamp(Math.min(W,H)/480,0.78,1.2);
}

// ---------- 绘图工具 ----------
function rrPath(g,x,y,w,h,r){r=Math.max(0,Math.min(r,w/2,h/2));g.beginPath();g.moveTo(x+r,y);g.arcTo(x+w,y,x+w,y+h,r);g.arcTo(x+w,y+h,x,y+h,r);g.arcTo(x,y+h,x,y,r);g.arcTo(x,y,x+w,y,r);g.closePath();}
function ell(g,x,y,rx,ry,rot=0){g.beginPath();g.ellipse(x,y,Math.max(0.01,rx),Math.max(0.01,ry),rot,0,TAU);g.fill();}
function circle(g,x,y,r){g.beginPath();g.arc(x,y,Math.max(0.01,r),0,TAU);g.fill();}
function star(g,x,y,r,rot){g.beginPath();for(let i=0;i<8;i++){const a=rot+i*Math.PI/4,rr=i%2?r*0.38:r;g.lineTo(x+Math.cos(a)*rr,y+Math.sin(a)*rr);}g.closePath();g.fill();}

function drawItemIcon(g,t,x,y,s,rot=0){
  g.save();g.translate(x,y);g.rotate(rot);
  if(t==='seed'){g.fillStyle='#2b2b30';ell(g,0,0,s*0.55,s*0.95);g.strokeStyle='rgba(255,255,255,.45)';g.lineWidth=Math.max(1,s*0.1);g.stroke();g.strokeStyle='#e8e8e8';g.lineWidth=Math.max(1,s*0.12);g.beginPath();g.moveTo(-s*0.18,-s*0.7);g.lineTo(-s*0.22,s*0.6);g.moveTo(s*0.18,-s*0.7);g.lineTo(s*0.22,s*0.6);g.stroke();}
  else if(t==='coin'){g.fillStyle='#c9971c';circle(g,0,0,s*0.85);g.fillStyle='#f5c542';circle(g,0,0,s*0.72);g.strokeStyle='#d9a823';g.lineWidth=Math.max(1,s*0.1);g.beginPath();g.arc(0,0,s*0.48,0,TAU);g.stroke();g.fillStyle='rgba(255,255,255,.75)';ell(g,-s*0.25,-s*0.28,s*0.18,s*0.1,-0.6);}
  else if(t==='chili'){g.fillStyle='#e8452c';g.beginPath();g.moveTo(-s*0.9,-s*0.2);g.quadraticCurveTo(0,-s*0.75,s*0.9,s*0.1);g.quadraticCurveTo(s*0.1,s*0.15,-s*0.9,s*0.25);g.closePath();g.fill();g.fillStyle='#4caf50';ell(g,-s*0.88,0,s*0.22,s*0.3);g.fillStyle='rgba(255,255,255,.45)';ell(g,-s*0.1,-s*0.25,s*0.35,s*0.08,-0.2);}
  else{g.fillStyle='#b9793a';circle(g,0,0,s*0.95);g.fillStyle='#d99a55';circle(g,0,0,s*0.8);g.fillStyle='#5a3418';circle(g,-s*0.3,-s*0.2,s*0.14);circle(g,s*0.25,-s*0.32,s*0.12);circle(g,s*0.1,s*0.3,s*0.15);circle(g,-s*0.32,s*0.28,s*0.1);}
  g.restore();
}

// ---------- 角色 ----------
function drawHamGun(g,R,o,face){
  g.save();g.translate(face*R*0.5,-R*0.78);g.rotate(o.aim);if(face<0)g.scale(1,-1);g.translate(-o.kick,0);
  g.fillStyle='#2d3846';rrPath(g,-R*0.25,-R*0.2,R*1.3,R*0.38,R*0.12);g.fill();
  g.fillStyle='#4fae8f';rrPath(g,R*0.05,-R*0.3,R*0.62,R*0.14,R*0.06);g.fill();
  g.fillStyle='#1d242e';rrPath(g,R*1.0,-R*0.12,R*0.48,R*0.22,R*0.06);g.fill();
  g.fillStyle='#86d65b';circle(g,R*0.35,R*0.26,R*0.19);g.fillStyle='#b8f08a';circle(g,R*0.3,R*0.2,R*0.07);
  g.fillStyle='#ffe3c6';circle(g,-R*0.12,R*0.12,R*0.17);circle(g,R*0.62,R*0.08,R*0.14);
  g.restore();
}
function drawHamster(g,x,y,R,o){
  const face=Math.cos(o.aim)>=0?1:-1,fl=o.flash;
  g.save();g.translate(x,y);
  if(o.shadow!==false){g.fillStyle='rgba(0,0,0,.28)';ell(g,0,0,R*1.15,R*0.45);}
  const bob=o.moving?Math.abs(Math.sin(o.walk))*R*0.16:Math.sin(o.t*2.4)*R*0.03;
  g.translate(0,-bob);const sq=clamp(o.sq,0.6,1.5);g.scale(sq,2-sq);
  if(o.rollA){g.translate(0,-R*0.95);g.rotate(o.rollA);g.translate(0,R*0.95);}
  const aimUp=Math.sin(o.aim)<-0.35;
  if(o.gun&&aimUp)drawHamGun(g,R,o,face);
  const fp=o.moving?Math.sin(o.walk):0;
  g.fillStyle=fl?'#fff':'#f7b2a8';ell(g,-R*0.42,-R*0.1+fp*R*0.1,R*0.26,R*0.17);ell(g,R*0.42,-R*0.1-fp*R*0.1,R*0.26,R*0.17);
  g.fillStyle=fl?'#fff':'#eba557';ell(g,0,-R*0.98,R*1.08,R*0.98);
  g.fillStyle=fl?'#fff':'#d98b3f';ell(g,0,-R*1.55,R*0.78,R*0.38);
  for(const sx of[-1,1]){g.fillStyle=fl?'#fff':'#d98b3f';circle(g,sx*R*0.62,-R*1.72,R*0.3);g.fillStyle='#ffb2b0';circle(g,sx*R*0.62,-R*1.72,R*0.17);}
  g.fillStyle=fl?'#fff':'#fff2df';ell(g,0,-R*0.55,R*0.7,R*0.5);
  const pf=clamp(o.puff,0,1.25),cr=R*(0.3+0.5*pf),cx=R*(0.56+0.46*pf),cy=-R*(0.95-0.05*pf);
  g.fillStyle=fl?'#fff':'#ffe8cc';circle(g,-cx,cy,cr);circle(g,cx,cy,cr);
  g.strokeStyle='rgba(160,100,50,.35)';g.lineWidth=Math.max(1,R*0.05);g.beginPath();g.arc(-cx,cy,cr,0,TAU);g.stroke();g.beginPath();g.arc(cx,cy,cr,0,TAU);g.stroke();
  g.fillStyle='rgba(255,120,130,.42)';ell(g,-cx-cr*0.1,cy+cr*0.2,cr*0.45,cr*0.26);ell(g,cx+cr*0.1,cy+cr*0.2,cr*0.45,cr*0.26);
  g.fillStyle=fl?'#fff':'#fff2df';ell(g,0,-R*1.0,R*0.48,R*0.38);
  const lx=Math.cos(o.aim)*R*0.09,ly=Math.sin(o.aim)*R*0.07;
  g.lineCap='round';
  if(o.hurt){g.strokeStyle='#2a1d1d';g.lineWidth=R*0.09;for(const sx of[-1,1]){const ex=sx*R*0.36,ey=-R*1.24;g.beginPath();g.moveTo(ex-sx*R*0.12,ey-R*0.1);g.lineTo(ex+sx*R*0.04,ey);g.lineTo(ex-sx*R*0.12,ey+R*0.1);g.stroke();}}
  else for(const sx of[-1,1]){const ex=sx*R*0.36+lx,ey=-R*1.24+ly;g.fillStyle='#2a1d1d';ell(g,ex,ey,R*0.14,R*0.16);g.fillStyle='#fff';circle(g,ex-R*0.04,ey-R*0.06,R*0.05);}
  g.fillStyle='#ff8ea2';ell(g,lx*0.6,-R*1.04+ly*0.4,R*0.09,R*0.065);
  g.strokeStyle='#7a4a3a';g.lineWidth=Math.max(1,R*0.05);g.beginPath();
  const mx=lx*0.6,my=-R*0.93+ly*0.4;
  if(pf>0.55)g.arc(mx,my+R*0.03,R*0.06,0,TAU);else{g.moveTo(mx-R*0.14,my);g.quadraticCurveTo(mx-R*0.07,my+R*0.1,mx,my);g.quadraticCurveTo(mx+R*0.07,my+R*0.1,mx+R*0.14,my);}
  g.stroke();
  g.strokeStyle='rgba(90,60,40,.45)';g.lineWidth=Math.max(0.8,R*0.03);g.beginPath();for(const sx of[-1,1]){g.moveTo(sx*R*0.2,-R*1.0);g.lineTo(sx*R*0.62,-R*1.08);g.moveTo(sx*R*0.2,-R*0.96);g.lineTo(sx*R*0.6,-R*0.92);}g.stroke();
  if(o.gun&&!aimUp)drawHamGun(g,R,o,face);
  g.restore();
}
const ICON={};
function hamPose(extra){return Object.assign({aim:Math.PI/2,flash:false,moving:false,walk:0,t:time,sq:1,rollA:0,gun:false,puff:0,hurt:false,kick:0},extra);}
function makeIcons(){for(const t of ORDER){const c=document.createElement('canvas');c.width=c.height=64;drawItemIcon(c.getContext('2d'),t,32,32,t==='chili'||t==='cookie'?24:22,t==='chili'?-0.35:0);ICON[t]=c.toDataURL();}}
function makeHero(){let url=null;try{url=gl?renderHero():null;}catch(e){url=null;}if(!url){const c=document.createElement('canvas');c.width=320;c.height=214;drawHamster(c.getContext('2d'),160,176,74,hamPose({puff:1.1,t:0,shadow:false}));url=c.toDataURL();}$('heroImg').src=url;}

function panel(g,x,y,w,h,r,a=0.74){g.fillStyle=`rgba(22,16,38,${a})`;rrPath(g,x,y,w,h,r);g.fill();g.strokeStyle='rgba(255,243,224,.1)';g.lineWidth=1;g.stroke();}
function txt(g,s,x,y,size,col,align='left'){g.font=`${size}px ${FONT}`;g.textAlign=align;g.textBaseline='middle';g.fillStyle=col;g.fillText(s,x,y);}
function otxt(g,s,x,y,size,col,align='center',lw){g.font=`${size}px ${FONT}`;g.textAlign=align;g.textBaseline='middle';g.lineJoin='round';g.lineWidth=lw||Math.max(2,size*0.22);g.strokeStyle='rgba(20,12,30,.85)';g.strokeText(s,x,y);g.fillStyle=col;g.fillText(s,x,y);}
