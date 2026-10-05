let HSC=['#d8423f','#c0332f'];
const fmtTime=t=>`${Math.floor(t/60)}:${String(Math.floor(t%60)).padStart(2,'0')}`;
function show(id,on){$(id).classList.toggle('hidden',!on);}
function bar(g,x,y,w,h,f,col){g.fillStyle='rgba(20,12,30,.78)';rrPath(g,x-w/2-2,y-2,w+4,h+4,(h+4)/2);g.fill();g.fillStyle=col;rrPath(g,x-w/2,y,Math.max(h,w*clamp(f,0,1)),h,h/2);g.fill();}
function wrapLines(g,s,maxW){const out=[];let cur='';for(const ch of s){const t=cur+ch;if(g.measureText(t).width>maxW&&cur){out.push(cur);cur=ch;}else cur=t;}if(cur)out.push(cur);return out;}
function draw2DWeapon(g,id,x,y,s,rot=-0.25){
  g.save();g.translate(x,y);g.rotate(rot);g.lineJoin='round';g.strokeStyle='#1a1226';g.lineWidth=Math.max(1.2,s*0.08);
  const R=(x0,y0,w,h,c,r=0)=>{g.fillStyle=c;rrPath(g,x0*s,y0*s,w*s,h*s,r*s);g.fill();g.stroke();};
  const poly=(pts,c)=>{g.fillStyle=c;g.beginPath();pts.forEach((p,i)=>i?g.lineTo(p[0]*s,p[1]*s):g.moveTo(p[0]*s,p[1]*s));g.closePath();g.fill();g.stroke();};
  switch(id){
    case'pistol':R(-0.45,-0.2,0.95,0.2,'#2b2d33',0.04);poly([[-0.42,0],[-0.18,0],[-0.1,0.42],[-0.36,0.42]],'#24262b');break;
    case'deagle':R(-0.55,-0.26,1.25,0.26,'#c9ced6',0.04);R(-0.5,-0.32,1.1,0.07,'#9aa0a8');poly([[-0.5,0],[-0.2,0],[-0.1,0.5],[-0.42,0.5]],'#24262b');break;
    case'ak47':poly([[-1.0,-0.05],[-0.45,-0.12],[-0.45,0.08],[-0.95,0.2]],'#8a5a32');R(-0.45,-0.14,0.65,0.22,'#3a3d45',0.03);R(0.2,-0.12,0.45,0.18,'#8a5a32',0.04);R(0.65,-0.08,0.5,0.08,'#2b2d33');poly([[-0.05,0.08],[0.12,0.08],[0.24,0.5],[0.05,0.56]],'#2b2d33');break;
    case'smg':R(-0.5,-0.16,0.9,0.26,'#33363e',0.04);R(0.4,-0.1,0.25,0.1,'#2b2d33');R(-0.18,0.1,0.18,0.45,'#24262b',0.03);R(-0.85,-0.12,0.35,0.06,'#4a4d55');break;
    case'shotgun':R(-0.95,-0.12,0.6,0.24,'#7a4a2a',0.08);R(-0.35,-0.14,0.5,0.24,'#33363e',0.04);R(0.15,-0.14,0.95,0.1,'#2b2d33');R(0.2,0.0,0.5,0.14,'#5a3a22',0.04);break;
    case'sniper':R(-0.95,-0.1,0.85,0.24,'#3b4a3a',0.06);R(-0.1,-0.06,1.25,0.1,'#2a2f2a');R(1.1,-0.09,0.16,0.16,'#1d2229');R(-0.55,-0.36,0.65,0.16,'#1d2229',0.06);g.fillStyle='#7fe3ff';circle(g,0.1*s,-0.28*s,0.06*s);break;
    case'lmg':R(-0.95,-0.1,0.5,0.22,'#24262b',0.04);R(-0.45,-0.16,0.8,0.28,'#3a3d45',0.04);R(0.35,-0.1,0.85,0.1,'#2b2d33');R(-0.4,0.12,0.35,0.3,'#4b5530',0.04);break;
    case'rocket':R(-0.9,-0.12,1.55,0.24,'#4b5530',0.1);R(-0.45,-0.16,0.42,0.32,'#8a5a32',0.06);poly([[0.62,-0.2],[1.05,0],[0.62,0.2]],'#5d6b3a');R(-0.3,0.1,0.1,0.3,'#2d3320');break;
    case'minigun':R(-0.6,-0.2,0.7,0.36,'#3a3d45',0.06);for(let k=0;k<3;k++)R(0.1,-0.17+k*0.11,0.95,0.09,'#2b2d33');R(-0.45,0.12,0.4,0.3,'#4b5530',0.05);break;
    case'autoshot':R(-0.95,-0.12,0.55,0.22,'#24262b',0.05);R(-0.4,-0.16,0.85,0.28,'#2f3238',0.05);R(0.45,-0.1,0.55,0.12,'#2b2d33');g.fillStyle='#4b5530';circle(g,-0.05*s,0.28*s,0.22*s);g.stroke();break;
    case'amr':R(-1.0,-0.12,0.5,0.26,'#4a4f3a',0.06);R(-0.5,-0.14,0.75,0.26,'#4a4f3a',0.05);R(0.25,-0.07,1.0,0.12,'#2a2f2a');R(1.2,-0.11,0.2,0.2,'#1d2229');R(-0.4,-0.38,0.6,0.16,'#1d2229',0.06);g.fillStyle='#ff8a3d';circle(g,0.18*s,-0.3*s,0.06*s);break;
    case'dual':for(const dy of [-0.3,0.25]){R(-0.45,dy-0.1,0.95,0.18,'#2b2d33',0.04);poly([[-0.42,dy+0.08],[-0.2,dy+0.08],[-0.12,dy+0.36],[-0.36,dy+0.36]],'#24262b');}break;
    case'revolver':R(-0.1,-0.12,1.0,0.12,'#8f939b',0.04);g.fillStyle='#6e737c';ell(g,-0.15*s,-0.05*s,0.22*s,0.17*s);g.stroke();poly([[-0.42,0],[-0.2,0],[-0.06,0.45],[-0.34,0.45]],'#7a4a2a');break;
    case'gl':R(-0.95,-0.1,0.7,0.22,'#8a5a32',0.08);R(-0.3,-0.14,0.3,0.26,'#2b2d33',0.04);R(0,-0.18,0.95,0.32,'#4b5530',0.14);break;
    case'rail':R(-0.75,-0.16,0.8,0.3,'#d6dbe4',0.06);R(0.05,-0.12,1.0,0.07,'#3a4656');R(0.05,0.05,1.0,0.07,'#3a4656');g.strokeStyle='#5fe0ff';g.lineWidth=Math.max(1.5,s*0.08);for(let k=0;k<4;k++){g.beginPath();g.moveTo((0.25+k*0.22)*s,-0.18*s);g.lineTo((0.25+k*0.22)*s,0.16*s);g.stroke();}break;
    case'laser':R(-0.75,-0.15,0.95,0.28,'#ecebf2',0.08);R(0.2,-0.08,0.45,0.14,'#3a4656',0.04);g.fillStyle='#ff5fa8';circle(g,0.72*s,-0.01*s,0.1*s);g.fillRect(-0.55*s,-0.2*s,0.6*s,0.05*s);break;
    case'katana':R(-0.8,-0.07,0.48,0.14,'#2a2030',0.05);g.fillStyle='#ffcf3a';ell(g,-0.28*s,0,0.06*s,0.2*s);g.stroke();g.fillStyle='#e8eef6';g.beginPath();g.moveTo(-0.22*s,-0.07*s);g.lineTo(0.95*s,-0.05*s);g.quadraticCurveTo(1.12*s,0,0.95*s,0.06*s);g.lineTo(-0.22*s,0.07*s);g.closePath();g.fill();g.stroke();break;
    default:R(-0.72,-0.3,0.4,0.6,'#d8423f',0.15);R(-0.32,-0.1,0.62,0.2,'#3a3f48',0.05);R(0.3,-0.07,0.5,0.14,'#2d3038');g.fillStyle='#ffb04a';g.beginPath();g.moveTo(0.8*s,-0.13*s);g.quadraticCurveTo(1.3*s,0,0.8*s,0.13*s);g.closePath();g.fill();}
  g.restore();}
function draw2DPet(g,type,x,y,s){
  g.save();g.translate(x,y);g.strokeStyle='#1a1226';g.lineWidth=Math.max(1,s*0.12);
  if(type==='chick'){g.fillStyle='#ffd23f';circle(g,0,0,s);g.stroke();circle(g,s*0.55,-s*0.55,s*0.6);g.stroke();g.fillStyle='#ff8a3d';g.beginPath();g.moveTo(s*1.05,-s*0.62);g.lineTo(s*1.45,-s*0.47);g.lineTo(s*1.05,-s*0.35);g.closePath();g.fill();g.fillStyle='#2a1d1d';circle(g,s*0.75,-s*0.7,s*0.11);}
  else if(type==='firefly'){g.fillStyle='rgba(212,255,106,.35)';circle(g,-s*0.4,0,s*1.15);g.fillStyle='#d4ff6a';circle(g,-s*0.4,0,s*0.55);g.fillStyle='#2b2b36';ell(g,s*0.3,0,s*0.55,s*0.42);g.fillStyle='rgba(232,244,255,.85)';ell(g,0,-s*0.55,s*0.5,s*0.25,-0.3);ell(g,s*0.1,s*0.55,s*0.5,s*0.25,0.3);}
  else{g.fillStyle='#5e3a22';for(let k=0;k<7;k++){const a=Math.PI+k/6*Math.PI;g.beginPath();g.moveTo(Math.cos(a-0.22)*s*0.8,Math.sin(a-0.22)*s*0.6);g.lineTo(Math.cos(a)*s*1.38,Math.sin(a)*s*1.02);g.lineTo(Math.cos(a+0.22)*s*0.8,Math.sin(a+0.22)*s*0.6);g.fill();}g.fillStyle='#8a5a3a';ell(g,0,0,s*0.95,s*0.7);g.stroke();g.fillStyle='#f0d9b5';ell(g,s*0.65,s*0.1,s*0.45,s*0.38);g.fillStyle='#2a1d1d';circle(g,s*1.06,s*0.1,s*0.12);circle(g,s*0.7,-s*0.05,s*0.08);}
  g.restore();}
function draw2DGadget(g,id,x,y,s){g.save();g.translate(x,y);g.strokeStyle='#1a1226';g.lineWidth=Math.max(1,s*0.1);
  if(id==='frag'){g.fillStyle='#4f6b3a';ell(g,0,s*0.1,s*0.62,s*0.75);g.stroke();g.fillStyle='#b9c2cc';g.fillRect(-s*0.18,-s*0.85,s*0.36,s*0.3);g.strokeRect(-s*0.18,-s*0.85,s*0.36,s*0.3);g.beginPath();g.arc(s*0.35,-s*0.75,s*0.18,0,TAU);g.stroke();}
  else if(id==='molotov'){g.fillStyle='#3f7a4a';rrPath(g,-s*0.38,-s*0.2,s*0.76,s*0.95,s*0.15);g.fill();g.stroke();g.fillRect(-s*0.14,-s*0.6,s*0.28,s*0.42);g.fillStyle='#ffb04a';g.beginPath();g.moveTo(-s*0.2,-s*0.6);g.quadraticCurveTo(0,-s*1.25,s*0.22,-s*0.6);g.closePath();g.fill();}
  else if(id==='flash'){g.fillStyle='#c9ced6';rrPath(g,-s*0.35,-s*0.6,s*0.7,s*1.15,s*0.12);g.fill();g.stroke();g.fillStyle='#5fb0ff';g.fillRect(-s*0.35,-s*0.05,s*0.7,s*0.16);g.fillStyle='rgba(255,255,255,.9)';for(let k=0;k<6;k++){const a=k/6*TAU;g.fillRect(Math.cos(a)*s*0.85-1,Math.sin(a)*s*0.85-1,2.5,2.5);}}
  else if(id==='mine'){g.fillStyle='#3a3f2a';ell(g,0,s*0.15,s*0.85,s*0.4);g.stroke();g.fillStyle='#5d6b3a';ell(g,0,0,s*0.55,s*0.25);g.stroke();g.fillStyle='#ff3d4e';circle(g,0,-s*0.08,s*0.12);}
  else if(id==='eshield'){g.fillStyle='rgba(127,227,255,.35)';g.beginPath();for(let k=0;k<6;k++){const a=k/6*TAU+Math.PI/6;g.lineTo(Math.cos(a)*s*0.85,Math.sin(a)*s*0.85);}g.closePath();g.fill();g.strokeStyle='#7fe3ff';g.lineWidth=Math.max(1.5,s*0.12);g.stroke();}
  else if(id==='smoke'){g.fillStyle='#8f939b';rrPath(g,-s*0.32,-s*0.3,s*0.64,s*0.9,s*0.12);g.fill();g.stroke();g.fillStyle='rgba(200,200,210,.85)';circle(g,-s*0.3,-s*0.55,s*0.25);circle(g,s*0.1,-s*0.7,s*0.3);circle(g,s*0.42,-s*0.5,s*0.22);}
  else if(id==='flare'){g.fillStyle='rgba(255,180,90,.45)';circle(g,0,-s*0.48,s*0.5);g.fillStyle='#e0443f';rrPath(g,-s*0.14,-s*0.3,s*0.28,s*1.0,s*0.1);g.fill();g.stroke();g.fillStyle='#ffd166';circle(g,0,-s*0.48,s*0.24);}
  else if(id==='decoy'){g.fillStyle='#f2a54a';circle(g,-s*0.42,-s*0.55,s*0.2);g.stroke();circle(g,s*0.42,-s*0.55,s*0.2);g.stroke();circle(g,0,-s*0.1,s*0.55);g.stroke();g.beginPath();g.moveTo(0,s*0.45);g.quadraticCurveTo(s*0.2,s*0.7,0,s*0.95);g.stroke();g.fillStyle='#2a1d24';circle(g,-s*0.18,-s*0.15,s*0.07);circle(g,s*0.18,-s*0.15,s*0.07);}
  else if(id==='jetpack'){g.fillStyle='#ffb04a';for(const x of [-0.25,0.25]){g.beginPath();g.moveTo((x-0.12)*s,s*0.38);g.lineTo(x*s,s*0.88);g.lineTo((x+0.12)*s,s*0.38);g.closePath();g.fill();}g.fillStyle='#8f939b';for(const x of [-0.25,0.25]){rrPath(g,(x-0.18)*s,-s*0.55,s*0.36,s*0.95,s*0.16);g.fill();g.stroke();}}
  else if(id==='medkit'){g.fillStyle='#f2e2c0';rrPath(g,-s*0.5,-s*0.45,s*1.0,s*0.9,s*0.18);g.fill();g.stroke();g.fillStyle='#4caf50';g.fillRect(-s*0.1,-s*0.3,s*0.2,s*0.6);g.fillRect(-s*0.3,-s*0.1,s*0.6,s*0.2);}
  else if(id==='freeze'){g.fillStyle='#9fe8ff';ell(g,0,s*0.1,s*0.62,s*0.72);g.stroke();g.strokeStyle='#ffffff';g.lineWidth=Math.max(1,s*0.08);for(let k=0;k<3;k++){const a=k/3*Math.PI;g.beginPath();g.moveTo(Math.cos(a)*s*0.4,s*0.1+Math.sin(a)*s*0.4);g.lineTo(-Math.cos(a)*s*0.4,s*0.1-Math.sin(a)*s*0.4);g.stroke();}}
  else if(id==='beacon'){g.fillStyle='#55585f';g.fillRect(-s*0.06,-s*0.4,s*0.12,s*1.2);g.fillStyle='#7fe3ff';circle(g,0,-s*0.45,s*0.16);g.strokeStyle='#7fe3ff';g.lineWidth=Math.max(1,s*0.08);for(const r0 of [0.35,0.6]){g.beginPath();g.arc(0,-s*0.45,s*r0,-Math.PI*0.8,-Math.PI*0.2);g.stroke();}}
  else{g.strokeStyle='#55585f';g.lineWidth=Math.max(1.5,s*0.12);g.beginPath();g.moveTo(0,0);g.lineTo(-s*0.55,s*0.8);g.moveTo(0,0);g.lineTo(s*0.55,s*0.8);g.moveTo(0,0);g.lineTo(0,s*0.85);g.stroke();g.strokeStyle='#1a1226';g.lineWidth=Math.max(1,s*0.1);g.fillStyle='#5fb0ff';rrPath(g,-s*0.45,-s*0.45,s*0.8,s*0.5,s*0.1);g.fill();g.stroke();g.fillStyle='#2b2d33';g.fillRect(s*0.3,-s*0.3,s*0.6,s*0.16);}
  g.restore();}
function talIcon(g,id,x,y,r){g.fillStyle='rgba(255,111,208,.25)';circle(g,x,y,r);g.strokeStyle='#ff6fd0';g.lineWidth=1.8;g.beginPath();g.arc(x,y,r,0,TAU);g.stroke();txt(g,TALENTS[id].name[0],x,y+0.5,r*1.05,'#ffe0f6','center');}
function abilIcon(g,id,x,y,r,l){g.fillStyle='rgba(95,176,255,.22)';circle(g,x,y,r);g.strokeStyle='#5fb0ff';g.lineWidth=1.5;g.beginPath();g.arc(x,y,r,0,TAU);g.stroke();txt(g,ABIL[id].ic,x,y+0.5,r*1.05,'#e8f4ff','center');if(l>1)otxt(g,String(l),x+r*0.85,y+r*0.75,r*0.85,'#ffd166','center',2);}

// ---------- 分屏 HUD ----------
const NCOL={gun:'#ff9a3c',boom:'#ff4d5e',monster:'#ffd166',step:'#e8e8f0',pad:'#7fe3ff'},NRANGE={gun:1400,boom:2000,monster:900,step:340,pad:900};
function hearArcs(v){const h=v.ham,T=h.team,V=VIS[T],out=[],r=v.rect,vis=e=>e&&(e.team===T||V.has(e)),onScr=(x,y)=>{const p=projV(v,x,0,y);return p.x>r.x&&p.x<r.x+r.w&&p.y>r.y&&p.y<r.y+r.h;};
  for(const n of noises){if(n.team===T||n.src===h)continue;if(onScr(n.x,n.y)&&(!n.src||vis(n.src)))continue;const d=Math.hypot(n.x-h.x,n.y-h.y),R=NRANGE[n.type]*n.loud*(h.st.hearK||1);if(d>R||d<1)continue;out.push({x:n.x,y:n.y,k:(1-d/R)*(1-n.t/n.life),type:n.type,ping:n.type!=='step'});}
  for(const e of hams){if(!e.alive||e.team===T||e.air||vis(e))continue;const d=Math.hypot(e.x-h.x,e.y-h.y),sp=Math.hypot(e.vx,e.vy);const HR=340*(h.st.hearK||1);if(d>HR||sp<60)continue;out.push({x:e.x,y:e.y,k:(1-d/HR)*Math.min(1,sp/220)*(0.6+0.4*Math.abs(Math.sin(time*9+e.id))),type:'step'});}
  for(const e of mobs){if(e.dead||vis(e))continue;const d=Math.hypot(e.x-h.x,e.y-h.y),sp=Math.hypot(e.vx,e.vy);if(d>280||sp<40)continue;out.push({x:e.x,y:e.y,k:(1-d/280)*0.7,type:'monster'});}
  return out;}
function hexA(h,a){const n=parseInt(h.slice(1),16);return`rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${a})`;}
function perimPt(r,u){const Pm=2*(r.w+r.h);u=((u%Pm)+Pm)%Pm;if(u<r.w)return{x:r.x+u,y:r.y,nx:0,ny:1};u-=r.w;if(u<r.h)return{x:r.x+r.w,y:r.y+u,nx:-1,ny:0};u-=r.h;if(u<r.w)return{x:r.x+r.w-u,y:r.y+r.h,nx:0,ny:-1};u-=r.w;return{x:r.x,y:r.y+r.h-u,nx:1,ny:0};}
function perimU(r,cx,cy,ang){const dx=Math.cos(ang),dy=Math.sin(ang);let t=1e9,e=0;if(dx>1e-6){const q=(r.x+r.w-cx)/dx;if(q<t){t=q;e=1;}}if(dx<-1e-6){const q=(r.x-cx)/dx;if(q<t){t=q;e=3;}}if(dy>1e-6){const q=(r.y+r.h-cy)/dy;if(q<t){t=q;e=2;}}if(dy<-1e-6){const q=(r.y-cy)/dy;if(q<t){t=q;e=0;}}
  const x=cx+dx*t,y=cy+dy*t;return e===0?x-r.x:e===1?r.w+(y-r.y):e===2?r.w+r.h+(r.x+r.w-x):2*r.w+r.h+(r.y+r.h-y);}
function hearGlyph(g,type,x,y,s,col){g.save();g.translate(x,y);g.fillStyle=col;g.strokeStyle=col;g.lineCap='round';
  if(type==='gun')draw2DWeapon(g,'pistol',0,0,11*s,0);
  else if(type==='boom'){g.beginPath();for(let i=0;i<16;i++){const a=i/16*TAU,rr=(i%2?4:10)*s;g.lineTo(Math.cos(a)*rr,Math.sin(a)*rr);}g.closePath();g.fill();}
  else if(type==='step'){for(const [dx,dy,ro] of [[-4,3,-0.3],[4,-3,0.3]]){g.beginPath();g.ellipse(dx*s,dy*s,2.6*s,4.2*s,ro,0,TAU);g.fill();}}
  else if(type==='monster'){g.lineWidth=2.2*s;for(let k=-1;k<=1;k++){g.beginPath();g.moveTo((k*4-3)*s,-7*s);g.lineTo((k*4+3)*s,7*s);g.stroke();}}
  else{g.lineWidth=2.4*s;g.beginPath();g.moveTo(0,8*s);g.lineTo(0,-7*s);g.moveTo(-5*s,-2*s);g.lineTo(0,-8*s);g.lineTo(5*s,-2*s);g.stroke();}
  g.restore();}
function drawHearing(g,v){const h=v.ham;if(!h||!h.alive||state!=='play')return;const arcs=hearArcs(v);v.arcs=arcs;if(!arcs.length)return;
  const s=v.s||uiS,r=v.rect,c=projV(v,h.x,h.r+(h.z||0),h.y),mcx=r.x+r.w/2,mcy=r.y+r.h/2,base=Math.min(r.w,r.h),N=20;
  const SPEC={gun:[0.34,0.13,8],boom:[0.55,0.2,12],monster:[0.26,0.1,6],step:[0.2,0.08,5],pad:[0.3,0.11,7]};
  g.save();
  for(const a of arcs){const p=projV(v,a.x,0,a.y),ang=Math.atan2(p.y-c.y,p.x-c.x),k=clamp(a.k,0,1),sp=SPEC[a.type]||SPEC.gun,col=NCOL[a.type];
    const pulse=a.type==='step'?0.55+0.45*Math.abs(Math.sin(time*7+a.x*0.01)):1,A=(0.35+0.65*k)*pulse,L=base*sp[0]*(0.65+0.7*k),depth=base*sp[1]*(0.6+0.8*k),core=sp[2]*s*(0.7+0.6*k);
    const u0=perimU(r,mcx,mcy,ang);
    for(let i=0;i<N;i++){const t0=i/N,t1=(i+1)/N,q0=perimPt(r,u0-L/2+L*t0),q1=perimPt(r,u0-L/2+L*t1),tm=(t0+t1)/2*2-1,al=A*(1-tm*tm);if(al<=0.01)continue;
      const nx=q0.nx,ny=q0.ny,mx=(q0.x+q1.x)/2,my=(q0.y+q1.y)/2,gr=g.createLinearGradient(mx,my,mx+nx*depth,my+ny*depth);gr.addColorStop(0,hexA(col,al*0.85));gr.addColorStop(0.35,hexA(col,al*0.35));gr.addColorStop(1,hexA(col,0));
      g.fillStyle=gr;g.beginPath();g.moveTo(q0.x,q0.y);g.lineTo(q1.x,q1.y);g.lineTo(q1.x+q1.nx*depth,q1.y+q1.ny*depth);g.lineTo(q0.x+nx*depth,q0.y+ny*depth);g.closePath();g.fill();
      g.strokeStyle=hexA(col,Math.min(1,al*1.2));g.lineWidth=core;g.beginPath();g.moveTo(q0.x,q0.y);g.lineTo(q1.x,q1.y);g.stroke();}
    const q=perimPt(r,u0),bx=q.x+q.nx*(depth*0.55+20*s),by=q.y+q.ny*(depth*0.55+20*s),d=Math.hypot(a.x-h.x,a.y-h.y);
    g.globalAlpha=Math.min(1,0.45+0.6*k)*pulse;g.fillStyle='rgba(12,8,24,.78)';circle(g,bx,by,16*s);g.strokeStyle=col;g.lineWidth=2.2*s;g.beginPath();g.arc(bx,by,16*s,0,TAU);g.stroke();
    hearGlyph(g,a.type,bx,by,s,col);otxt(g,Math.max(1,Math.round(d/40))+'m',bx,by+26*s,11*s,col);g.globalAlpha=1;}
  g.restore();}
function drawCute2D(g,cx,cy,u,o){const C=SKINS[o.skin]||SKINS.gold,tc=TC2[o.team]||TC2.blue,OL='#3a2730',pf=clamp(o.puff||0,0,1);
  g.save();g.translate(cx,cy);g.lineJoin='round';g.lineCap='round';g.lineWidth=Math.max(1.2,2.4*u);g.strokeStyle=OL;
  const E=(x,y,rx,ry,fill,st=true)=>{g.beginPath();g.ellipse(x*u,y*u,rx*u,ry*u,0,0,TAU);g.fillStyle=fill;g.fill();if(st)g.stroke();};
  E(-16,70,10,6,'#ffb3b8');E(16,70,10,6,'#ffb3b8');E(0,44,36,30,C.fur);E(0,50,22,19,C.cream,false);E(-12,30,6,5,'#ffc9c9');E(12,30,6,5,'#ffc9c9');
  E(-33,-26,14,14,C.fur);E(-33,-26,8,8,'#ffb3c1',false);E(33,-26,14,14,C.fur);E(33,-26,8,8,'#ffb3c1',false);
  const cr=12+7*pf,co=33+5*pf;E(-co,12,cr+2,cr,C.cream);E(co,12,cr+2,cr,C.cream);
  E(0,0,40,40,C.fur);E(0,14,28,22,C.cream,false);
  g.beginPath();g.ellipse(0,-12*u,37*u,30*u,0,Math.PI,TAU);g.closePath();g.fillStyle=tc[0];g.fill();g.stroke();
  g.fillStyle=tc[1];rrPath(g,-40*u,-18*u,80*u,11*u,5.5*u);g.fill();g.stroke();E(0,-45,8,8,'#ffffff');
  const blink=((o.t||0)+0.4)%3.3<0.11;
  if(o.hurt){g.lineWidth=Math.max(1.2,2.6*u);for(const sx of [-15,15]){g.beginPath();g.moveTo((sx-5)*u,0);g.lineTo((sx+5)*u,8*u);g.moveTo((sx+5)*u,0);g.lineTo((sx-5)*u,8*u);g.stroke();}}
  else if(blink){g.lineWidth=Math.max(1.2,2.4*u);for(const sx of [-15,15]){g.beginPath();g.moveTo((sx-6)*u,5*u);g.quadraticCurveTo(sx*u,8*u,(sx+6)*u,5*u);g.stroke();}}
  else{E(-15,4,6.5,8.5,'#2a1d24',false);E(15,4,6.5,8.5,'#2a1d24',false);E(-17,0,2.8,2.8,'#ffffff',false);E(13,0,2.8,2.8,'#ffffff',false);E(-13,7,1.3,1.3,'#ffffff',false);E(17,7,1.3,1.3,'#ffffff',false);}
  E(-25,16,6,3.5,'#ff8fa3',false);E(25,16,6,3.5,'#ff8fa3',false);E(0,12,3.4,2.4,'#ff7f96',false);
  g.lineWidth=Math.max(1,1.8*u);g.beginPath();g.moveTo(-6*u,17*u);g.quadraticCurveTo(-3*u,21*u,0,17*u);g.quadraticCurveTo(3*u,21*u,6*u,17*u);g.stroke();
  g.restore();}
function drawPanel(g,v){
  const h=v.ham,s=v.s||uiS,r=v.rect,x=r.x+12*s,y=r.y+12*s,w=Math.min(318*s,VIEWS.length>1?r.w-Math.min(210*s,r.w*0.34)-44*s:r.w-24*s),ph=128*s,tc=TCOL[h.team];
  panel(g,x,y,w,ph,18*s);
  const pcx=x+60*s,pcy=y+ph/2;
  g.fillStyle=h.team==='blue'?'rgba(79,163,255,.16)':'rgba(255,91,91,.16)';circle(g,pcx,pcy,50*s);
  g.strokeStyle='rgba(255,255,255,.14)';g.lineWidth=5*s;g.beginPath();g.arc(pcx,pcy,50*s,0,TAU);g.stroke();
  const xf=h.lvl>=30?1:clamp(h.xp/h.xpNext,0,1);g.strokeStyle='#ffd166';g.lineCap='round';g.beginPath();g.arc(pcx,pcy,50*s,-Math.PI/2,-Math.PI/2+TAU*Math.max(0.001,xf));g.stroke();g.lineCap='butt';
  if(h.shield>0){g.strokeStyle='rgba(159,232,255,.9)';g.lineWidth=2*s;g.setLineDash([5*s,4*s]);g.beginPath();g.arc(pcx,pcy,43*s,0,TAU);g.stroke();g.setLineDash([]);}
  h.petList.forEach((p,i)=>draw2DPet(g,p.type,pcx-32*s+i*15*s,pcy+31*s+(i%2)*3*s,7.5*s));
  const R=20*s;HSC=TC2[h.team];g.save();if(!h.alive)g.globalAlpha=0.45;
  {const u=R*0.034;drawCute2D(g,pcx,pcy-9*u,u,{skin:h.skin,team:h.team,puff:clamp(h.puff.v,0,1),hurt:h.hurtT>0,t:time+h.id});}
  if(h.crownT>0){g.fillStyle='#ffcf3a';g.beginPath();const cx=pcx,cy=pcy-R*2.05;g.moveTo(cx-R*0.45,cy+R*0.22);g.lineTo(cx-R*0.45,cy-R*0.1);g.lineTo(cx-R*0.22,cy+R*0.06);g.lineTo(cx,cy-R*0.22);g.lineTo(cx+R*0.22,cy+R*0.06);g.lineTo(cx+R*0.45,cy-R*0.1);g.lineTo(cx+R*0.45,cy+R*0.22);g.closePath();g.fill();}
  g.restore();
  draw2DWeapon(g,h.weapon.id,pcx+R*0.42,pcy+R*0.72,R*0.85,-0.35);
  {const gd=h.gadget,G0=GADGETS[gd.id],gx=pcx+38*s,gy=pcy+36*s,ck=gd.cd>0?gd.cd/(G0.cd*(1-0.15*(gd.lvl-1))):0;g.fillStyle='rgba(22,16,38,.92)';circle(g,gx,gy,14*s);draw2DGadget(g,gd.id,gx,gy+s,9*s);if(ck>0){g.fillStyle='rgba(10,6,20,.62)';g.beginPath();g.moveTo(gx,gy);g.arc(gx,gy,14*s,-Math.PI/2,-Math.PI/2+TAU*ck);g.closePath();g.fill();}g.strokeStyle=ck>0?'rgba(255,255,255,.3)':'#c77dff';g.lineWidth=2*s;g.beginPath();g.arc(gx,gy,14*s,0,TAU);g.stroke();const key=h.dev==='pad'?'LB':h.dev==='keys2'?'.':h.dev==='touch'?'':'Q';if(key)otxt(g,key,gx+12*s,gy+11*s,10*s,'#fff3e0','center',2);}
  if(h.ab.speed){g.strokeStyle='rgba(255,209,102,.85)';g.lineWidth=2*s;for(let k=0;k<3;k++){g.beginPath();g.moveTo(pcx-R*1.25-k*2*s,pcy+R*(0.05+k*0.28));g.lineTo(pcx-R*1.25-(8+k*5)*s,pcy+R*(0.05+k*0.28));g.stroke();}}
  const bx=x+122*s,bw=x+w-14*s-bx;
  txt(g,fmtTime(G?G.t:0),bx,y+22*s,26*s,'#fff3e0');
  const lv='Lv '+h.lvl;g.font=`${14*s}px ${FONT}`;const lw=g.measureText(lv).width+18*s;g.fillStyle=tc;rrPath(g,x+w-14*s-lw,y+11*s,lw,23*s,11.5*s);g.fill();txt(g,lv,x+w-14*s-lw/2,y+23*s,14*s,'#fff','center');
  const hf=clamp(h.hp/h.maxHp,0,1);g.fillStyle='rgba(255,255,255,.12)';rrPath(g,bx,y+42*s,bw,10*s,5*s);g.fill();g.fillStyle=hf>0.35?'#7ee08a':'#ff6b5e';rrPath(g,bx,y+42*s,Math.max(10*s,bw*hf),10*s,5*s);g.fill();
  {const nm=WEAPONS[h.weapon.id].name;txt(g,nm,bx,y+64*s,13*s,'#ffd8a8');g.font=`${13*s}px ${FONT}`;const nw=g.measureText(nm).width;if(nw+62*s<bw-52*s)txt(g,'射程 '+Math.round(wRange(h)),bx+nw+7*s,y+64.5*s,10.5*s,'rgba(255,243,224,.55)');}{const mg=magSize(h);if(mg){if(h.reloadT>0){const k=1-h.reloadT/h.reloadDur;txt(g,'换弹中',x+w-14*s,y+64*s,12*s,'#ffd166','right');g.fillStyle='rgba(255,255,255,.12)';rrPath(g,bx,y+73*s,bw,3.5*s,1.75*s);g.fill();g.fillStyle='#ffd166';rrPath(g,bx,y+73*s,Math.max(3.5*s,bw*k),3.5*s,1.75*s);g.fill();}else txt(g,`${h.ammo} / ${mg}`,x+w-14*s,y+64*s,14*s,h.ammo<=mg*0.25?'#ff8a7a':'#fff3e0','right');}else txt(g,'∞',x+w-14*s,y+64*s,15*s,'#fff3e0','right');}
  let ax=bx;const ay=y+88*s;for(let i=0;i<3;i++){const lv=eL(h,PK[i]);if(!lv)continue;g.fillStyle=PATHC[i];circle(g,ax+10*s,ay,9*s);if(lv>=9){g.strokeStyle='#fff3e0';g.lineWidth=2*s;g.beginPath();g.arc(ax+10*s,ay,11*s,0,TAU);g.stroke();}txt(g,EVO[h.weapon.id][i][0][0],ax+10*s,ay+0.5,10*s,'#1a1226','center');ax+=24*s;}for(const id of Object.keys(h.tal)){talIcon(g,id,ax+10*s,ay,10*s);ax+=24*s;}for(const id of Object.keys(h.ab)){if(ax>x+w-26*s){txt(g,'…',ax,ay,14*s,'#fff');break;}abilIcon(g,id,ax+10*s,ay,10*s,0);ax+=24*s;}
  if(!Object.keys(h.ab).length&&!Object.keys(h.tal).length&&!(eL(h,'a')+eL(h,'b')+eL(h,'c')))txt(g,'还没有能力，升级来拿',bx,ay,11.5*s,'rgba(255,243,224,.45)');
  if(h.choices)txt(g,h.dev==='pad'?'按 X / Y / B 选升级':h.dev==='keys2'?'按 8 / 9 / 0 选升级':h.dev==='touch'?'点下方卡片选升级':'按 1 / 2 / 3 选升级',bx,y+113*s,12*s,'#ffd166');
  else txt(g,`击败 ${h.kills}   阵亡 ${h.deaths}`,bx,y+113*s,12*s,'rgba(255,243,224,.6)');
}
function drawCards(g,v){
  const h=v.ham;v.cardRects=[];if(!h||!h.choices||!h.alive)return;
  const s=v.s||uiS,r=v.rect,n=h.choices.length,gap=10*s,touch=h.dev==='touch',top=touch&&r.h<480,cw=Math.min(176*s,(top?r.w*0.52:r.w-40*s-gap*2)/3),ch=(top?96:108)*s,tw=n*cw+(n-1)*gap,x0=r.x+r.w/2-tw/2,y0=top?r.y+70*s:r.y+r.h-ch-(touch?150*s:VIEWS.length>1?66*s:22*s);
  const lbl=h.dev==='pad'?['X','Y','B']:h.dev==='keys2'?['8','9','0']:touch?['','','']:['1','2','3'];
  otxt(g,h.choices[0].t==='tal'?'天赋解锁！三选一':h.pending>1?`升级！选一个（还剩 ${h.pending} 次）`:'升级！选一个奖励',r.x+r.w/2,y0-14*s,15*s,'#ffd166');
  h.choices.forEach((c,i)=>{const L=choiceLabel(h,c),x=x0+i*(cw+gap),col=({进化:'#ff9a3c',强化:'#5fb0ff',道具:'#c77dff',天赋:'#ff6fd0',宠物:'#5fd38a',换武器:'#d9d4e2'})[L.type]||'#5fd38a';
    panel(g,x,y0,cw,ch,14*s,0.9);g.save();if(L.rar==='l'){g.shadowColor='#ffcf3a';g.shadowBlur=14*s;}g.strokeStyle=L.rar?RCOL[L.rar]:col;g.lineWidth=(L.rar==='l'?3:2)*s;rrPath(g,x,y0,cw,ch,14*s);g.stroke();g.restore();
    g.fillStyle=col;rrPath(g,x+10*s,y0+8*s,38*s,17*s,8.5*s);g.fill();txt(g,L.type,x+29*s,y0+17*s,11*s,'#1a1226','center');txt(g,L.lv,x+cw-10*s,y0+17*s,12*s,'#ffd166','right');
    const icx=x+28*s,icy=y0+52*s;if(c.t==='pet')draw2DPet(g,c.id,icx,icy,11*s);else if(c.t==='abil')abilIcon(g,c.id,icx,icy,14*s,0);else if(c.t==='gad'||c.t==='glvl')draw2DGadget(g,c.id,icx,icy,14*s);else if(c.t==='tal')talIcon(g,c.id,icx,icy,15*s);else if(c.t==='evo'){draw2DWeapon(g,h.weapon.id,icx,icy,16*s,-0.2);g.strokeStyle=L.evo.col;g.lineWidth=2*s;g.beginPath();g.arc(icx,icy,20*s,0,TAU);g.stroke();}else draw2DWeapon(g,c.id,icx,icy,19*s,-0.2);
    txt(g,L.name,x+54*s,y0+44*s,15*s,'#fff3e0');g.font=`${11.5*s}px ${FONT}`;wrapLines(g,L.desc,cw-62*s).slice(0,2).forEach((ln,k)=>txt(g,ln,x+54*s,y0+66*s+k*15*s,11.5*s,'rgba(255,243,224,.78)'));
    if(L.evo){g.fillStyle=L.evo.col;rrPath(g,x+12*s,y0+ch-16*s,26*s,5*s,2.5*s);g.fill();}
    if(c.t==='weap'){const W0=WEAPONS[c.id],rg=Math.round((W0.kind==='melee'?W0.reach:(W0.range||0))*h.st.rangeK);txt(g,'射程 '+rg+(W0.eff&&W0.eff<1?' · 有效 '+Math.round(rg*W0.eff):''),x+12*s,y0+ch-14*s,10.5*s,'rgba(255,243,224,.6)');}
    if(lbl[i]){g.fillStyle='#ffd166';circle(g,x+cw-16*s,y0+ch-16*s,11*s);txt(g,lbl[i],x+cw-16*s,y0+ch-15.5*s,12*s,'#1a1226','center');}
    v.cardRects.push({x,y:y0,w:cw,h:ch});});
}
function drawMinimap(g,v){
  if(VIEWS.length>1&&v.ham&&v.ham.choices)return;const myT=v.ham?v.ham.team:null,see=e=>!myT||e.team===myT||VIS[myT].has(e),s=v.s||uiS,r=v.rect,mw=Math.min(210*s,r.w*0.34),mh=mw*WH/WW,k=mw/WW,touch=v.ham&&v.ham.dev==='touch',x=r.x+r.w-mw-14*s,y=r.y+(VIEWS.length>1&&v!==VIEWS[0]?58:VIEWS.length>1?14:58)*s;
  panel(g,x-5*s,y-5*s,mw+10*s,mh+10*s,8*s,0.82);
  g.strokeStyle='rgba(194,171,134,.5)';g.lineWidth=3*s;g.lineJoin='round';for(const ln of ['top','mid','bot']){g.beginPath();LANES[ln].forEach((p,i)=>i?g.lineTo(x+p[0]*k,y+p[1]*k):g.moveTo(x+p[0]*k,y+p[1]*k));g.stroke();}
  g.fillStyle='rgba(255,255,255,.13)';for(const sd of solids){if(sd.kind==='wall'||sd.off)continue;if(sd.c)circle(g,x+sd.x*k,y+sd.y*k,Math.max(1,sd.r*k));else g.fillRect(x+sd.x*k,y+sd.y*k,Math.max(1,sd.w*k),Math.max(1,sd.h*k));}
  for(const c of camps)if(c.alive>0){g.fillStyle='rgba(255,209,102,.55)';circle(g,x+c.x*k,y+c.y*k,2.2*s);}
  if(G&&G.boss&&!G.boss.dead){g.fillStyle='#ffd166';circle(g,x+G.boss.x*k,y+G.boss.y*k,4.5*s);}
  for(const st of structs){if(st.kind==='sentry')continue;const px=x+st.x*k,py=y+st.y*k,sz=(st.kind==='base'?8:4.5)*s;g.fillStyle=st.dead?'rgba(120,120,130,.6)':TCOL[st.team];g.fillRect(px-sz/2,py-sz/2,sz,sz);if(st.kind==='base'&&st.shielded&&!st.dead){g.strokeStyle='#9fe8ff';g.lineWidth=1.2*s;g.strokeRect(px-sz/2-2*s,py-sz/2-2*s,sz+4*s,sz+4*s);}}
  for(const m of minions)if(!m.dead&&see(m)){g.fillStyle=TCOL[m.team];g.fillRect(x+m.x*k-s,y+m.y*k-s,2*s,2*s);}
  for(const h of hams)if(h.alive&&see(h)){const me=h===v.ham,rr=(me?4.4:3)*s;g.fillStyle=TCOL[h.team];circle(g,x+h.x*k,y+h.y*k,rr);if(h.ctl!=='ai'){g.strokeStyle='#fff';g.lineWidth=(me?1.8:1)*s;g.beginPath();g.arc(x+h.x*k,y+h.y*k,rr,0,TAU);g.stroke();}}
  if(v.arcs)for(const a of v.arcs){if(!a.ping)continue;g.globalAlpha=clamp(a.k,0.15,1);g.strokeStyle=NCOL[a.type];g.lineWidth=1.5*s;const rr=(3+5*(1-a.k))*s;g.beginPath();g.arc(x+a.x*k,y+a.y*k,rr,0,TAU);g.stroke();}g.globalAlpha=1;
  const V=v.V;g.strokeStyle='rgba(255,255,255,.45)';g.lineWidth=s;g.strokeRect(x+(v.camX-V.hw)*k,y+(v.camY-V.zn)*k,2*V.hw*k,(V.zn+V.zs)*k);
}
function drawWorldUI(g,v){
  const s=v.s||uiS,r=v.rect,inV=p=>p.ok&&p.x>r.x-40&&p.x<r.x+r.w+40&&p.y>r.y-40&&p.y<r.y+r.h+40,myTeam=v.ham?v.ham.team:'blue',see=e=>!v.ham||e.team===myTeam||VIS[myTeam].has(e);
  for(const st of structs){if(st.dead||(st.kind==='sentry'&&!see(st)))continue;const p=projV(v,st.x,st.kind==='base'?235:st.kind==='sentry'?52:108,st.y);if(!inV(p))continue;bar(g,p.x,p.y,(st.kind==='base'?120:st.kind==='sentry'?30:64)*s,(st.kind==='sentry'?4:7)*s,st.hp/st.maxHp,TCOL[st.team]);if(st.kind==='base'&&st.shielded)otxt(g,'护盾中：先拆掉一座炮台',p.x,p.y-13*s,11*s,'#9fe8ff');}
  for(const e of mobs){if(e.dead||!see(e)||(e.hp>=e.maxHp&&e.kind!=='boss'))continue;const p=projV(v,e.x,e.r*2.4+(e.kind==='boss'?80:6),e.y);if(!inV(p))continue;bar(g,p.x,p.y,(e.kind==='boss'?110:e.kind==='rat'?36:22)*s,(e.kind==='boss'?7:4)*s,e.hp/e.maxHp,'#ffd166');if(e.kind==='boss')otxt(g,'鼠王',p.x,p.y-13*s,13*s,'#ffd166');}
  for(const m of minions){if(m.dead||!see(m)||m.hp>=m.maxHp)continue;const p=projV(v,m.x,32,m.y);if(inV(p))bar(g,p.x,p.y,20*s,3.5*s,m.hp/m.maxHp,TCOL[m.team]);}
  for(const c of crates){if(c.dead||c.hp>=c.maxHp)continue;const p=projV(v,c.x,c.big?64:46,c.y);if(inV(p))bar(g,p.x,p.y,28*s,4*s,c.hp/c.maxHp,'#ffd8a8');}
  for(const h of hams){if(!h.alive||(h!==v.ham&&!see(h)))continue;const p=projV(v,h.x,h.r*3+6+(h.z||0),h.y);if(!inV(p))continue;bar(g,p.x,p.y,46*s,5.5*s,h.hp/h.maxHp,h.team===myTeam?'#7ee08a':'#ff6b5e');otxt(g,`${h.name} Lv${h.lvl}`,p.x,p.y-11*s,11*s,TCOL[h.team]);if(h.eshieldT>0){g.fillStyle='#7fe3ff';rrPath(g,p.x-23*s,p.y+7*s,Math.max(3*s,46*s*clamp(h.eshield/h.maxHp,0,1)),3*s,1.5*s);g.fill();}if(h.shield>0)txt(g,'◎'.repeat(h.shield),p.x+27*s,p.y+3*s,9*s,'#9fe8ff');}
  for(const h of hams){if(!h.alive||h.ctl==='ai'||h.reloadT<=0)continue;const p=projV(v,h.x,h.r*3+6,h.y);if(!inV(p))continue;const k=1-h.reloadT/h.reloadDur;g.strokeStyle='rgba(20,12,30,.8)';g.lineWidth=5*s;g.beginPath();g.arc(p.x,p.y-26*s,9*s,0,TAU);g.stroke();g.strokeStyle='#ffd166';g.lineWidth=3*s;g.beginPath();g.arc(p.x,p.y-26*s,9*s,-Math.PI/2,-Math.PI/2+TAU*k);g.stroke();}
  for(const L of [hams,minions,mobs,decoys])for(const e of L){if((L===hams?!e.alive:e.dead)||!(e.markTeam===myTeam&&G.t<e.markUntil))continue;const p=projV(v,e.x,e.r*3.6+(e.z||0)+14,e.y);if(!inV(p))continue;g.fillStyle='#ff4d5e';g.beginPath();g.moveTo(p.x,p.y-7*s);g.lineTo(p.x+5*s,p.y);g.lineTo(p.x,p.y+7*s);g.lineTo(p.x-5*s,p.y);g.closePath();g.fill();}
  for(const p of pops){const q=projV(v,p.x,p.h,p.y);if(!inV(q))continue;const k=p.life/p.max;g.save();g.globalAlpha=Math.min(1,k*2.2);otxt(g,p.text,q.x,q.y,p.size*s*(1+(1-k)*0.12),p.color);g.restore();}
}
function updToasts(v,dt){if(!v.toastCur&&v.toastQ.length)v.toastCur=v.toastQ.shift();if(v.toastCur){v.toastCur.t+=dt;if(v.toastCur.t>=v.toastCur.dur)v.toastCur=null;}}
function drawToastV(g,v){const t=v.toastCur;if(!t)return;const s=v.s||uiS,r=v.rect,k=Math.min(1,t.t/0.18,(t.dur-t.t)/0.3);g.save();g.globalAlpha=clamp(k,0,1);g.font=`${15*s}px ${FONT}`;const w=Math.min(r.w-30*s,g.measureText(t.text).width+32*s),x=r.x+r.w/2-w/2,y=v.ham&&v.ham.dev==='touch'?r.y+r.h-70*s:r.y+156*s;panel(g,x,y,w,32*s,16*s,0.86);txt(g,t.text,r.x+r.w/2,y+16.5*s,15*s,t.color,'center');g.restore();}
function drawViewHUD(g,v){
  v.s=VIEWS.length>1?uiS*0.82:uiS;const h=v.ham,s=v.s,r=v.rect;g.save();g.beginPath();g.rect(r.x,r.y,r.w,r.h);g.clip();
  drawWorldUI(g,v);
  if(v.hitT>0){let px,py;if(h.dev==='kbm'&&mouse.has){px=mouse.x;py=mouse.y;}else{const p=projV(v,v.hx,v.hh,v.hy);px=p.x;py=p.y;}const k=v.hitT/0.14,d1=(6+(1-k)*4)*s,d2_=(13+(1-k)*4)*s;g.save();g.globalAlpha=Math.min(1,k*1.6);g.strokeStyle=v.hk?'#ff4d5e':'#ffffff';g.lineWidth=2.6*s;g.lineCap='round';g.beginPath();for(const [dx,dy] of [[1,1],[1,-1],[-1,1],[-1,-1]]){g.moveTo(px+dx*d1,py+dy*d1);g.lineTo(px+dx*d2_,py+dy*d2_);}g.stroke();g.restore();}
  const low=h.alive&&h.hp/h.maxHp<0.3?0.22+0.14*Math.sin(time*6):0,a=Math.max(v.pulse*0.45,low);
  if(a>0.01){const gr=g.createRadialGradient(r.x+r.w/2,r.y+r.h/2,Math.min(r.w,r.h)*0.35,r.x+r.w/2,r.y+r.h/2,Math.max(r.w,r.h)*0.72);gr.addColorStop(0,'rgba(255,40,60,0)');gr.addColorStop(1,`rgba(255,40,60,${a})`);g.fillStyle=gr;g.fillRect(r.x,r.y,r.w,r.h);}
  if(v.flashT>0){g.fillStyle=`rgba(255,252,240,${Math.min(0.97,v.flashT/1.1)})`;g.fillRect(r.x,r.y,r.w,r.h);}
  if(!h.alive){g.fillStyle='rgba(10,6,20,.45)';g.fillRect(r.x,r.y,r.w,r.h);otxt(g,`${Math.max(0,h.respawnT).toFixed(1)} 秒后复活`,r.x+r.w/2,r.y+r.h/2,26*s,'#fff3e0');otxt(g,'回到自家仓鼠窝附近会快速回血',r.x+r.w/2,r.y+r.h/2+30*s,13*s,'rgba(255,243,224,.75)');}
  drawPanel(g,v);drawCards(g,v);drawMinimap(g,v);drawHearing(g,v);drawToastV(g,v);
  if(VIEWS.length>1&&!h.choices){otxt(g,h.name,r.x+r.w/2,r.y+r.h-62*s,14*s,TCOL[h.team]);}
  g.restore();
}
function pauseBtnRect(){const s=uiS,r=17*s;return{x:W-14*s-r,y:14*s+r,r};}
function drawGlobalHUD(g){
  const s=uiS;if(VIEWS.length>1){g.fillStyle='rgba(10,8,20,.95)';g.fillRect(W/2-2,0,4,H);}
  const split=VIEWS.length>1,bw=Math.min(220*s,W*0.18),cy=split?H-34*s:20*s;panel(g,W/2-bw-26*s,cy-14*s,bw*2+52*s,42*s,14*s,0.82);
  for(const t of TEAMS){const b=structs.find(q=>q.kind==='base'&&q.team===t),f=b&&!b.dead?b.hp/b.maxHp:0,left=t==='blue',x=left?W/2-bw-14*s:W/2+14*s;
    g.fillStyle='rgba(255,255,255,.12)';rrPath(g,x,cy+10*s,bw,9*s,4.5*s);g.fill();g.fillStyle=TCOL[t];const fw=Math.max(9*s,bw*f);rrPath(g,left?x+bw-fw:x,cy+10*s,fw,9*s,4.5*s);g.fill();
    const alive=structs.filter(q=>q.kind==='turret'&&q.team===t&&!q.dead).length;txt(g,(left?'蓝队仓鼠窝':'红队仓鼠窝')+(b&&b.shielded?' ◎':''),left?x:x+bw,cy,11.5*s,TCOL[t],left?'left':'right');
    for(let i=0;i<3;i++){g.fillStyle=i<alive?TCOL[t]:'rgba(255,255,255,.18)';const px=left?x+bw-5*s-i*11*s:x+5*s+i*11*s;g.fillRect(px-3.5*s,cy-3.5*s,7*s,7*s);}}
  txt(g,'VS',W/2,cy+8*s,12*s,'#fff3e0','center');
  if(G&&G.sudden)otxt(g,'加速决战：建筑双倍伤害',W/2,split?cy-26*s:cy+42*s,12*s,'#ff8a7a');
  const fl=split?feed.slice(-3):feed;let fy=split?H-(64+28*fl.length)*s:152*s;const fx=14*s;for(const f of fl){g.save();g.globalAlpha=clamp((6-f.t)/0.5,0,1);g.font=`${12.5*s}px ${FONT}`;const w=g.measureText(f.text).width+20*s;panel(g,fx,fy,w,24*s,12*s,0.75);txt(g,f.text,fx+10*s,fy+12.5*s,12.5*s,f.col);g.restore();fy+=28*s;}
  if(state==='play'){const b=pauseBtnRect();g.fillStyle='rgba(22,16,38,.7)';circle(g,b.x,b.y,b.r);g.fillStyle='#fff3e0';g.fillRect(b.x-6*s,b.y-7*s,4*s,14*s);g.fillRect(b.x+2*s,b.y-7*s,4*s,14*s);}
}
const TOUCH={move:{x:0,y:0,r:62},aim:{x:0,y:0,r:62},dash:{x:0,y:0,r:30},gad:{x:0,y:0,r:26}};
function touchLayout(){const s=uiS;TOUCH.move.r=TOUCH.aim.r=62*s;TOUCH.move.x=100*s;TOUCH.move.y=H-100*s;TOUCH.aim.x=W-100*s;TOUCH.aim.y=H-100*s;TOUCH.dash.r=30*s;TOUCH.dash.x=W-215*s;TOUCH.dash.y=H-58*s;TOUCH.gad.r=26*s;TOUCH.gad.x=W-282*s;TOUCH.gad.y=H-46*s;}
function drawTouch(g){const s=uiS,h=hams[0];
  for(const [st,b,lab] of [[TS.move,TOUCH.move,'移动'],[TS.aim,TOUCH.aim,'瞄准']]){const ox=st?st.ox:b.x,oy=st?st.oy:b.y;g.fillStyle='rgba(22,16,38,.4)';circle(g,ox,oy,b.r);g.strokeStyle='rgba(255,243,224,.3)';g.lineWidth=2*s;g.beginPath();g.arc(ox,oy,b.r,0,TAU);g.stroke();g.fillStyle=st?'rgba(255,209,102,.85)':'rgba(255,243,224,.4)';circle(g,ox+(st?st.vx*b.r:0),oy+(st?st.vy*b.r:0),b.r*0.42);if(!st)txt(g,lab,ox,oy+b.r+12*s,11*s,'rgba(255,243,224,.55)','center');}
  const d=TOUCH.dash,cd=h?clamp(h.dashCd/h.st.dashCd,0,1):0;g.fillStyle=BTN.dash.p?'rgba(70,52,104,.8)':'rgba(22,16,38,.62)';circle(g,d.x,d.y,d.r);g.strokeStyle='#8ecbff';g.lineWidth=2.5*s;g.beginPath();g.arc(d.x,d.y,d.r,-Math.PI/2,-Math.PI/2+TAU*(1-cd));g.stroke();txt(g,'滚',d.x,d.y+1,18*s,'#fff3e0','center');{const b=TOUCH.gad,gd=h?h.gadget:null,ck=gd&&gd.cd>0?gd.cd/(GADGETS[gd.id].cd*(1-0.15*(gd.lvl-1))):0;g.fillStyle=BTN.gad.p?'rgba(70,52,104,.8)':'rgba(22,16,38,.62)';circle(g,b.x,b.y,b.r);if(gd)draw2DGadget(g,gd.id,b.x,b.y,b.r*0.55);if(ck>0){g.fillStyle='rgba(10,6,20,.6)';g.beginPath();g.moveTo(b.x,b.y);g.arc(b.x,b.y,b.r,-Math.PI/2,-Math.PI/2+TAU*ck);g.closePath();g.fill();}g.strokeStyle='#c77dff';g.lineWidth=2.5*s;g.beginPath();g.arc(b.x,b.y,b.r,0,TAU);g.stroke();}}
function drawCross(g){if(!mouse.has)return;const s=uiS,x=mouse.x,y=mouse.y,h=hams[0],W0=h?WEAPONS[h.weapon.id]:null,sp=W0&&W0.kind==='bullet'?(W0.spread||0)+h.bloom:0,rr=(7+Math.min(0.45,sp)*110)*s;g.lineCap='round';
  for(let k=0;k<2;k++){g.strokeStyle=k?'#fff3e0':'rgba(20,12,30,.85)';g.lineWidth=(k?1.8:4)*s;g.beginPath();g.moveTo(x-rr-9*s,y);g.lineTo(x-rr,y);g.moveTo(x+rr,y);g.lineTo(x+rr+9*s,y);g.moveTo(x,y-rr-9*s);g.lineTo(x,y-rr);g.moveTo(x,y+rr);g.lineTo(x,y+rr+9*s);g.stroke();}
  g.fillStyle='#fff3e0';circle(g,x,y,1.6*s);if(h&&h.reloadT>0){const k=1-h.reloadT/h.reloadDur;g.strokeStyle='#ffd166';g.lineWidth=2.5*s;g.beginPath();g.arc(x,y,rr+14*s,-Math.PI/2,-Math.PI/2+TAU*k);g.stroke();}if(h&&h.spin>0&&h.weapon.id==='minigun'){g.strokeStyle='#ffb04a';g.lineWidth=2.5*s;g.beginPath();g.arc(x,y,rr+14*s,-Math.PI/2,-Math.PI/2+TAU*h.spin);g.stroke();}if(h&&h.charge>0){g.strokeStyle='#9fe8ff';g.lineWidth=3*s;g.beginPath();g.arc(x,y,rr+14*s,-Math.PI/2,-Math.PI/2+TAU*h.charge);g.stroke();}g.lineCap='butt';}

// ---------- 输入 ----------
const PADPREV=[];
function getPads(){try{return navigator.getGamepads?Array.from(navigator.getGamepads()):[];}catch(e){return [];}}
function firstPad(){const p=getPads();for(let i=0;i<p.length;i++)if(p[i]&&p[i].connected!==false)return i;return -1;}
function padBtn(gp,i){const b=gp.buttons[i];return !!b&&(typeof b==='object'?(b.pressed||b.value>0.45):b===1);}
function padEdge(i,gp,b){return padBtn(gp,b)&&!(PADPREV[i]&&PADPREV[i][b]);}
function padActive(gp){if(!gp)return false;for(let b=0;b<gp.buttons.length;b++)if(padBtn(gp,b))return true;for(const a of gp.axes)if(Math.abs(a)>0.5)return true;return false;}
function endPadFrame(){const p=getPads();for(let i=0;i<p.length;i++){const gp=p[i];if(!gp)continue;const pr=PADPREV[i]||(PADPREV[i]=[]);for(let b=0;b<gp.buttons.length;b++)pr[b]=padBtn(gp,b);}}
function autoAim(h,R=650){const V=VIS[h.team];let best=null,bd=R*R;for(const e of hams)if(e.alive&&e.team!==h.team&&V.has(e)){const d=d2(e.x,e.y,h.x,h.y);if(d<bd&&hasLOS(h.x,h.y,e.x,e.y)){bd=d;best=e;}}if(best)return best;bd=R*R*0.56;for(const L of [minions,mobs])for(const e of L){if(e.dead||e.team===h.team||!V.has(e))continue;const d=d2(e.x,e.y,h.x,h.y);if(d<bd&&hasLOS(h.x,h.y,e.x,e.y)){bd=d;best=e;}}if(best)return best;for(const s of structs)if(!s.dead&&s.team!==h.team&&!(s.kind==='base'&&s.shielded)){const d=d2(s.x,s.y,h.x,h.y);if(d<bd){bd=d;best=s;}}return best;}
function readLocal(h){
  const inp=h.inp;inp.card=-1;inp.dash=false;inp.fire=false;inp.reload=false;inp.gadget=false;let mx=0,my=0;
  if(h.dev==='kbm'){
    if(keys.KeyA)mx-=1;if(keys.KeyD)mx+=1;if(keys.KeyW)my-=1;if(keys.KeyS)my+=1;
    if(VIEWS.length===1){if(keys.ArrowLeft)mx-=1;if(keys.ArrowRight)mx+=1;if(keys.ArrowUp)my-=1;if(keys.ArrowDown)my+=1;}
    if(mouse.has&&h.view){const r=h.view.rect,gp=screenToGroundV(h.view,clamp(mouse.x,r.x,r.x+r.w),clamp(mouse.y,r.y,r.y+r.h),h.r);h.mwx=gp.x;h.mwy=gp.z;inp.aim=Math.atan2(gp.z-h.y,gp.x-h.x);}
    inp.fire=mouse.down;inp.dash=keyEdge.has('Space')||keyEdge.has('ShiftLeft');inp.reload=keyEdge.has('KeyR');inp.gadget=keyEdge.has('KeyQ');
    if(keyEdge.has('Digit1'))inp.card=0;else if(keyEdge.has('Digit2'))inp.card=1;else if(keyEdge.has('Digit3'))inp.card=2;
  }else if(h.dev==='keys2'){
    if(keys.ArrowLeft)mx-=1;if(keys.ArrowRight)mx+=1;if(keys.ArrowUp)my-=1;if(keys.ArrowDown)my+=1;
    inp.fire=!!(keys.Enter||keys.NumpadEnter);inp.dash=keyEdge.has('ShiftRight');inp.reload=keyEdge.has('Slash')||keyEdge.has('Quote');inp.gadget=keyEdge.has('Period');
    if(keyEdge.has('Digit8')||keyEdge.has('Numpad7'))inp.card=0;else if(keyEdge.has('Digit9')||keyEdge.has('Numpad8'))inp.card=1;else if(keyEdge.has('Digit0')||keyEdge.has('Numpad9'))inp.card=2;
    const t=inp.fire?autoAim(h):null;if(t)inp.aim=Math.atan2(t.y-h.y,t.x-h.x);else if(mx||my)inp.aim=Math.atan2(my,mx);
  }else if(h.dev==='pad'){
    const gp=getPads()[h.padIdx];
    if(gp){const dz=v=>Math.abs(v)<0.18?0:v;mx=dz(gp.axes[0]||0);my=dz(gp.axes[1]||0);const ax=gp.axes[2]||0,ay=gp.axes[3]||0,am=Math.hypot(ax,ay),rt=gp.buttons[7]?(gp.buttons[7].value||0):0;
      if(am>0.3)inp.aim=Math.atan2(ay,ax);inp.fire=rt>0.3||am>0.6;inp.reload=padEdge(h.padIdx,gp,5);
      if(inp.fire&&am<=0.3){const t=autoAim(h);if(t)inp.aim=Math.atan2(t.y-h.y,t.x-h.x);}
      if(am<=0.3&&!inp.fire&&(mx||my))inp.aim=Math.atan2(my,mx);
      inp.dash=padEdge(h.padIdx,gp,0);inp.gadget=padEdge(h.padIdx,gp,4);
      if(padEdge(h.padIdx,gp,2))inp.card=0;else if(padEdge(h.padIdx,gp,3))inp.card=1;else if(padEdge(h.padIdx,gp,1))inp.card=2;}
  }else if(h.dev==='touch'){
    if(TS.move){mx=TS.move.vx;my=TS.move.vy;}
    if(TS.aim&&TS.aim.mag>0.18){let a=TS.aim.ang;const t=autoAim(h,700);if(t){const ea=Math.atan2(t.y-h.y,t.x-h.x);if(Math.abs(angDiff(a,ea))<0.35)a=ea;}inp.aim=a;inp.fire=TS.aim.mag>0.35;}
    else if(mx||my)inp.aim=Math.atan2(my,mx);
    if(BTN.dash.edge){inp.dash=true;BTN.dash.edge=false;}if(BTN.gad.edge){inp.gadget=true;BTN.gad.edge=false;}
  }
  if(h.touchCard>=0){inp.card=h.touchCard;h.touchCard=-1;}
  let ml=Math.hypot(mx,my);if(ml>1){mx/=ml;my/=ml;ml=1;}inp.mx=mx;inp.my=my;inp.ml=ml;
}
function localXY(e){const r=cv.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top};}
function setDevP1(dev,idx){const h=hams[0];if(!h||LOBBY.mode!=='solo'||h.ctl!=='p1')return;if(h.dev!==dev){h.dev=dev;if(idx!==undefined)h.padIdx=idx;inputMode=dev==='touch'?'touch':dev==='pad'?'pad':'mouse';cv.style.cursor=dev==='kbm'&&state==='play'?'none':'default';}}
function stickSet(st,p,b){let dx=p.x-st.ox,dy=p.y-st.oy;const l=Math.hypot(dx,dy),R=b.r;if(l>R){st.ox+=dx/l*(l-R);st.oy+=dy/l*(l-R);dx=p.x-st.ox;dy=p.y-st.oy;}st.vx=dx/R;st.vy=dy/R;st.mag=Math.min(1,Math.hypot(dx,dy)/R);st.ang=Math.atan2(dy,dx);}
cv.addEventListener('pointerdown',e=>{
  SFX.init();const p=localXY(e);
  if(state!=='play')return;
  const pb=pauseBtnRect();if(d2(p.x,p.y,pb.x,pb.y)<pb.r*pb.r*1.8){pauseGame();e.preventDefault();return;}
  for(const v of VIEWS){const h=v.ham;if(!h||!h.choices||!v.cardRects)continue;for(let i=0;i<v.cardRects.length;i++){const c=v.cardRects[i];if(p.x>=c.x&&p.x<=c.x+c.w&&p.y>=c.y&&p.y<=c.y+c.h){h.touchCard=i;e.preventDefault();return;}}}
  if(e.pointerType==='mouse'){mouse.has=true;mouse.x=p.x;mouse.y=p.y;if(e.button===0)mouse.down=true;setDevP1('kbm');return;}
  e.preventDefault();setDevP1('touch');
  if(d2(p.x,p.y,TOUCH.gad.x,TOUCH.gad.y)<(TOUCH.gad.r*1.3)**2){BTN.gad.p=true;BTN.gad.id=e.pointerId;BTN.gad.edge=true;return;}if(d2(p.x,p.y,TOUCH.dash.x,TOUCH.dash.y)<(TOUCH.dash.r*1.3)**2){BTN.dash.p=true;BTN.dash.id=e.pointerId;BTN.dash.edge=true;return;}
  if(p.x<W/2){if(!TS.move){TS.move={id:e.pointerId,ox:p.x,oy:p.y,vx:0,vy:0,mag:0,ang:0};}}
  else if(!TS.aim){TS.aim={id:e.pointerId,ox:p.x,oy:p.y,vx:0,vy:0,mag:0,ang:0};}
},{passive:false});
cv.addEventListener('pointermove',e=>{const p=localXY(e);if(e.pointerType==='mouse'){mouse.x=p.x;mouse.y=p.y;if(!mouse.has){mouse.has=true;}if(state==='play')setDevP1('kbm');return;}
  if(TS.move&&TS.move.id===e.pointerId)stickSet(TS.move,p,TOUCH.move);if(TS.aim&&TS.aim.id===e.pointerId)stickSet(TS.aim,p,TOUCH.aim);});
function endPtr(e){if(e.pointerType==='mouse'){if(e.button===0||e.type==='pointercancel')mouse.down=false;return;}if(TS.move&&TS.move.id===e.pointerId)TS.move=null;if(TS.aim&&TS.aim.id===e.pointerId)TS.aim=null;if(BTN.dash.id===e.pointerId){BTN.dash.p=false;BTN.dash.id=null;}if(BTN.gad.id===e.pointerId){BTN.gad.p=false;BTN.gad.id=null;}}
cv.addEventListener('pointerup',endPtr);cv.addEventListener('pointercancel',endPtr);
cv.addEventListener('contextmenu',e=>e.preventDefault());
const GAME_KEYS=new Set(['KeyW','KeyA','KeyS','KeyD','Space','ArrowUp','ArrowDown','ArrowLeft','ArrowRight','ShiftLeft','ShiftRight','Enter','Slash','Period','Digit1','Digit2','Digit3','Digit8','Digit9','Digit0','KeyR','Quote','KeyQ']);
window.addEventListener('keydown',e=>{
  if(state!=='play'&&e.target&&e.target.tagName==='BUTTON'&&(e.code==='Space'||e.code==='Enter'))return;
  keys[e.code]=true;if(!e.repeat)keyEdge.add(e.code);
  if(state==='play'&&GAME_KEYS.has(e.code))e.preventDefault();
  if(e.code==='Escape'||e.code==='KeyP'){if(state==='play')pauseGame();else if(state==='pause')resumeGame();}
  else if(state==='play'&&!e.repeat&&hams[0]&&hams[0].dev!=='kbm'&&['KeyW','KeyA','KeyS','KeyD','Space'].includes(e.code))setDevP1('kbm');
});
window.addEventListener('keyup',e=>{keys[e.code]=false;});
window.addEventListener('blur',()=>{for(const k in keys)keys[k]=false;mouse.down=false;});
window.addEventListener('gamepadconnected',()=>{const h=hams.find(q=>q.ctl==='p2');if(h&&LOBBY.p2c==='pad'&&h.dev!=='pad'){h.dev='pad';h.padIdx=firstPad();toastH(h,'手柄已连接','#8de0a6',1.6);}});

// ---------- 流程 ----------
const LOBBY={mode:'solo',p1:'blue',p2:'red',p2c:'pad',s1:'gold',s2:'pudding',ai:{blue:2,red:3}};
const NAMES={blue:['小豆','阿瓜','团子','花卷','汤圆','芝麻','米糕'],red:['阿炸','布丁','麻薯','奶茶','卤蛋','锅巴','果冻']};
function updLobby(){
  $('rowP2').style.display=LOBBY.mode==='duo'?'':'none';$('rowS2').style.display=LOBBY.mode==='duo'?'':'none';const c=$('ctrlText');
  if(coarse&&LOBBY.mode==='solo')c.innerHTML='<div><span class="k">左半屏</span>拖动移动</div><div><span class="k">右半屏</span>拖动瞄准并射击</div><div><span class="k">滚</span>翻滚躲子弹</div><div><span class="k">道</span>扔道具</div><div><span class="k">卡片</span>升级时点一下</div>';
  else if(LOBBY.mode==='solo')c.innerHTML='<div><span class="k">WASD</span>移动</div><div><span class="k">鼠标</span>瞄准，左键射击</div><div><span class="k">空格</span>翻滚</div><div><span class="k">1 2 3</span>选升级卡片</div><div><span class="k">R</span>换弹</div><div><span class="k">Q</span>扔道具</div><div><span class="k">Esc</span>暂停</div><div><span class="k">手柄</span>按一下就能切换</div>';
  else c.innerHTML='<div style="grid-column:1/-1"><b>玩家1</b>　WASD 移动 · 鼠标瞄准射击 · 空格翻滚 · R 换弹 · Q 道具 · 1/2/3 选升级</div><div style="grid-column:1/-1"><b>玩家2 手柄</b>　左摇杆移动 · 右摇杆瞄准 · RT 射击 · A 翻滚 · RB 换弹 · LB 道具 · X/Y/B 选升级</div><div style="grid-column:1/-1"><b>玩家2 方向键</b>　方向键移动 · 回车射击（自动瞄准）· 右 Shift 翻滚 · / 换弹 · . 道具 · 8/9/0 选升级</div>';
}
function segInit(id,key){const el=$(id);el.querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{SFX.init();SFX.click();el.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));LOBBY[key]=b.dataset.v;updLobby();}));}
segInit('segMode','mode');segInit('segS1','s1');segInit('segS2','s2');segInit('segP1','p1');segInit('segP2','p2');segInit('segP2c','p2c');
document.querySelectorAll('.step').forEach(st=>st.querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{SFX.init();SFX.click();const t=st.dataset.t;LOBBY.ai[t]=clamp(LOBBY.ai[t]+(+b.dataset.d),0,6);$(t==='blue'?'aiBlue':'aiRed').textContent=LOBBY.ai[t];})));
if(coarse){const b=$('segMode').querySelector('[data-v="duo"]');if(b){b.disabled=true;b.title='双人同屏需要电脑键盘或手柄';b.style.opacity=0.45;}}
function startMatch(){
  SFX.init();setupWorld();keyEdge.clear();mouse.down=false;TS.move=TS.aim=null;
  const p1=makeHam(LOBBY.p1,'p1','玩家1',0,LOBBY.s1);p1.dev=coarse&&LOBBY.mode==='solo'?'touch':'kbm';p1.touchCard=-1;hams.push(p1);
  let p2=null;if(LOBBY.mode==='duo'){p2=makeHam(LOBBY.p2,'p2','玩家2',1,LOBBY.s2);const pi=firstPad();p2.dev=LOBBY.p2c==='pad'&&pi>=0?'pad':'keys2';p2.padIdx=Math.max(0,pi);p2.touchCard=-1;hams.push(p2);}
  let k=2;for(const t of TEAMS)for(let i=0;i<LOBBY.ai[t];i++){const h=makeHam(t,'ai',(t==='blue'?'蓝·':'红·')+NAMES[t][i%NAMES[t].length],k++);h.touchCard=-1;hams.push(h);}
  VIEWS=[mkView(p1)];if(p2)VIEWS.push(mkView(p2));layoutViews();for(const v of VIEWS){v.camX=v.ham.x;v.camY=v.ham.y;}
  state='play';show('title',false);show('menu',false);show('codex',false);show('pause',false);show('result',false);try{cv.focus({preventScroll:true});}catch(e){}cv.style.cursor=p1.dev==='kbm'?'none':'default';
  toastH(p1,'跟着兵线推进：先拆炮台，再打爆对方仓鼠窝！','#ffd166',3.2);
  if(p2){toastH(p2,'打爆对方的仓鼠窝！','#ffd166',3);if(LOBBY.p2c==='pad'&&p2.dev!=='pad')toastH(p2,'没检测到手柄，先用方向键，按手柄任意键可切换','#ffd8a8',4);}
}
function endMatch(w){
  state='result';cv.style.cursor='default';mouse.down=false;
  const locals=hams.filter(h=>h.ctl!=='ai'),mine=locals.length&&locals.every(h=>h.team===w);
  if(mine||locals.length>1)SFX.win();else SFX.lose();
  $('rRank').textContent=w==='blue'?'蓝':'红';$('rRank').style.color=TCOL[w];$('rTitle').textContent=`${TNAME[w]}胜利！`;
  let sub;if(locals.length>1&&locals[0].team!==locals[1].team)sub=(w===locals[0].team?'玩家1':'玩家2')+' 赢了这一局';else sub=mine?'你们打爆了对方的仓鼠窝':'自家的仓鼠窝被打爆了';
  $('rSub').textContent=`用时 ${fmtTime(G.t)} · ${sub}`;
  const rows=[...hams].sort((a,b)=>(a.team===b.team?b.kills-a.kills:a.team==='blue'?-1:1)).map(h=>`<tr${h.ctl!=='ai'?' style="font-weight:700"':''}><td style="color:${TCOL[h.team]}">${TNAME[h.team]}</td><td>${h.name}</td><td>${h.lvl}</td><td>${h.kills}</td><td>${h.deaths}</td><td>${Math.round(h.bdmg)}</td></tr>`).join('');
  $('rStats').innerHTML=`<table><tr><th>队伍</th><th>名字</th><th>等级</th><th>击败</th><th>阵亡</th><th>拆建筑</th></tr>${rows}</table>`;
  show('result',true);
}
function pauseGame(){if(state!=='play')return;state='pause';show('pause',true);mouse.down=false;cv.style.cursor='default';}
function resumeGame(){if(state!=='pause')return;state='play';show('pause',false);try{cv.focus({preventScroll:true});}catch(e){}if(hams[0]&&hams[0].dev==='kbm')cv.style.cursor='none';}
function toLobby(){state='title';setupWorld();VIEWS=[mkView(null)];layoutViews();show('pause',false);show('result',false);show('menu',false);show('codex',false);show('title',true);cv.style.cursor='default';}
function showMenu(){show('title',false);show('codex',false);show('menu',true);}
function openLobby(){SFX.init();SFX.click();show('menu',false);show('title',true);}
const CODEX={imgs:null,tab:'weapon'};
function iconURL(draw,size=96){const c=document.createElement('canvas');c.width=c.height=size;const g=c.getContext('2d');g.lineJoin='round';draw(g,size);return c.toDataURL();}
function codexImgs(){if(CODEX.imgs)return CODEX.imgs;const I={};
  for(const id in WEAPONS)I['w_'+id]=iconURL((g,S)=>draw2DWeapon(g,id,S/2,S/2,S*0.32,-0.25));
  for(const id in GADGETS)I['g_'+id]=iconURL((g,S)=>draw2DGadget(g,id,S/2,S/2+2,S*0.28));
  for(const id in ABIL)I['a_'+id]=iconURL((g,S)=>abilIcon(g,id,S/2,S/2,S*0.3,0));
  for(const id in TALENTS)I['t_'+id]=iconURL((g,S)=>talIcon(g,id,S/2,S/2,S*0.32));
  for(const id in PETS)I['p_'+id]=iconURL((g,S)=>draw2DPet(g,id,S/2,S/2,S*0.2));
  try{Object.assign(I,codexSnaps());}catch(e){console.error(e);}
  CODEX.imgs=I;return I;}
function codexList(tab){const I=codexImgs(),L=[],r0=n=>Math.round(n);
  if(tab==='weapon')for(const id in WEAPONS){const W=WEAPONS[id],st=[];
    if(W.kind==='bullet')st.push(`伤害 ${r0(W.dmg)}${(W.n||1)>1?' × '+W.n+' 发':''}　射速 ${W.rate}/秒`);
    else if(W.kind==='rocket'||W.kind==='lob')st.push(`爆炸伤害 ${r0(W.dmg+W.aoeDmg)}　半径 ${W.aoe}`);
    else if(W.kind==='melee')st.push(`伤害 ${W.dmg}　攻速 ${W.rate}/秒　距离 ${W.reach}`);
    else if(W.kind==='flame')st.push(`每发伤害 ${W.dmg}，会点燃敌人`);
    else if(W.kind==='rail')st.push(`蓄力伤害 ${W.dmg}～${W.dmg+140}，贯穿整条线`);
    else if(W.kind==='laser')st.push(`持续伤害约 ${r0(W.dmg*W.rate)}/秒`);
    if(W.mag)st.push(`弹匣 ${W.mag}　换弹 ${W.rl} 秒`);
    if(W.range&&W.kind!=='melee')st.push(W.eff&&W.eff<1?`射程 ${W.range}（有效 ${r0(W.range*W.eff)}，超出后伤害衰减）`:`射程 ${W.range}`);
    st.push('进化路线：'+EVO[id].map(p=>p[0]).join(' / '));L.push({img:I['w_'+id],name:W.name,desc:(id==='pistol'?'开局默认武器。':'')+WDESC[id],stats:st});}
  else if(tab==='gadget')for(const id in GADGETS){const G0=GADGETS[id];L.push({img:I['g_'+id],name:G0.name,desc:G0.desc+(id==='frag'?'。开局默认道具':''),stats:[`冷却 ${G0.cd} 秒`,'用升级卡可以升级：冷却更短、效果更强']});}
  else if(tab==='abil')for(const id in ABIL){const A=ABIL[id];L.push({img:I['a_'+id],name:A.name,desc:A.desc,stats:[`可以叠加 ${A.max} 次`]});}
  else if(tab==='talent')for(const id in TALENTS){const T0=TALENTS[id];L.push({img:I['t_'+id],name:T0.name,rar:'l',rarText:'天赋',desc:T0.desc,stats:['第 10、20、30 级三选一']});}
  else if(tab==='pet')for(const id in PETS)L.push({img:I['p_'+id],name:PETS[id].name,desc:PETS[id].desc,stats:['可以升级 3 次，伤害越来越高']});
  else if(tab==='mob'){
    L.push({img:I.m_roach,name:'蟑螂',desc:'成群住在野区的窝里，一靠近就整群冲上来咬人。',stats:['生命 28　速度很快','击败经验 6，有几率掉落瓜子']});
    L.push({img:I.m_rat,name:'鼠帮枪手',desc:'戴墨镜的老鼠，会蹲下瞄准（红色激光）后三连发，三只一伙守着野区。',stats:['生命 95','击败经验 16']});
    L.push({img:I.m_boss,name:'鼠王',rar:'l',rarText:'首领',desc:'开局 2 分钟后出现在地图上方中央。扇形弹幕、环形弹幕，还会召唤小弟。',stats:['生命 2600','击败后全队获得 60 秒王冠加成（伤害 +25%）','被击败后 150 秒重生']});
    L.push({img:I.m_minion,name:'小兵',desc:'双方每 30 秒在三条兵线各出 3 个，自动朝敌方推进。',stats:['生命 70','击败经验 7']});
    L.push({img:I.m_turret,name:'炮台',desc:'每方三座。优先打小兵，但你攻击敌方仓鼠时会被锁定。',stats:['生命 1700　射程 480','摧毁一座后，对方仓鼠窝的护盾消失']});}
  else if(tab==='scene'){
    L.push({img:I.s_pad,name:'超级弹射装置',desc:'踩上去翻着跟头飞进野区，空中可以开枪，落地有冲击波。',stats:['两边基地附近各两个']});
    L.push({img:I.s_barrel,name:'爆炸桶',desc:'打爆后范围爆炸，不分敌我，能连锁引爆。',stats:['50 秒后复原']});
    L.push({img:I.s_box,name:'纸箱掩体',desc:'挡子弹也挡视线，可以打碎。',stats:['60 秒后复原']});
    L.push({img:I.s_lamp,name:'落地灯',desc:'照亮周围一圈，被照到的敌人全队可见。打碎后这片区域变黑。',stats:['45 秒后修好']});
    L.push({img:I.s_crate,name:'零食箱',desc:'打开会掉落瓜子（经验），偶尔有回血奶酪。',stats:['40 秒后刷新']});
    L.push({img:I.s_bigcrate,name:'大礼箱',desc:'地图下方正中央，掉落一大堆经验和奶酪。',stats:['90 秒后刷新']});}
  else for(const sk in SKINS)L.push({img:I['k_'+sk],name:SKINS[sk].name,desc:{gold:'经典橙色配奶白肚皮。',pudding:'奶黄色的布丁仓鼠。',silver:'雪白带一点灰。',stripe:'灰色毛，背上有一道深色条纹。'}[sk],stats:['在开局设置里选择，AI 随机']});
  return L;}
function renderCodex(tab){CODEX.tab=tab;$('codexTabs').querySelectorAll('button').forEach(b=>b.classList.toggle('on',b.dataset.t===tab));const g=$('codexGrid');
  g.innerHTML=codexList(tab).map(e=>`<div class="ccard"><img src="${e.img||''}" alt="${e.name}"><div class="cinfo"><div class="cname">${e.name}${e.rar?`<span class="crar" style="background:${RCOL[e.rar]}">${e.rarText||RNAME[e.rar]}</span>`:''}</div><div class="cdesc">${e.desc||''}</div>${(e.stats||[]).map(x=>`<div class="cstat">${x}</div>`).join('')}</div></div>`).join('');g.scrollTop=0;}
function openCodex(){SFX.init();SFX.click();show('menu',false);show('codex',true);if(!CODEX.imgs){$('codexGrid').innerHTML='<div class="cload">正在准备图鉴…</div>';setTimeout(()=>renderCodex(CODEX.tab),30);}else renderCodex(CODEX.tab);}
$('codexTabs').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{SFX.click();renderCodex(b.dataset.t);}));
$('codexClose').addEventListener('click',()=>{SFX.click();showMenu();});
$('mPlay').addEventListener('click',openLobby);$('mCodex').addEventListener('click',openCodex);$('backMenu').addEventListener('click',()=>{SFX.click();showMenu();});
$('mMute').addEventListener('click',()=>{SFX.init();SFX.setMuted(!SFX.muted);store.set('mz_mute',SFX.muted?1:0);updateMuteLabel();});
$('mFx').addEventListener('click',()=>{fxLevel=(fxLevel+1)%3;store.set('mz_fx',fxLevel);applyFx();});
function updateMuteLabel(){const l=SFX.muted?'音效：关':'音效：开';$('muteBtn').textContent=l;$('mMute').textContent=l;}
const FX_LEVELS=[['标准',0.7],['强烈',1.0],['爆炸',1.5]];let fxLevel=clamp(+store.get('mz_fx',1)||0,0,2);
function applyFx(){FXK=FX_LEVELS[fxLevel][1];$('fxBtn').textContent='特效：'+FX_LEVELS[fxLevel][0];$('mFx').textContent='特效：'+FX_LEVELS[fxLevel][0];}
$('startBtn').addEventListener('click',startMatch);$('againBtn').addEventListener('click',startMatch);$('restartBtn').addEventListener('click',startMatch);
$('resumeBtn').addEventListener('click',resumeGame);$('lobbyBtn').addEventListener('click',toLobby);$('lobbyBtn2').addEventListener('click',toLobby);
$('muteBtn').addEventListener('click',()=>{SFX.init();SFX.setMuted(!SFX.muted);store.set('mz_mute',SFX.muted?1:0);updateMuteLabel();});
$('fxBtn').addEventListener('click',()=>{fxLevel=(fxLevel+1)%3;store.set('mz_fx',fxLevel);applyFx();});
let titleT=0;
function titleUpdate(dt){titleT+=dt;const v=VIEWS[0];if(!v)return;v.camX=MIDX+Math.sin(titleT*0.045)*1800;v.camY=MIDY+Math.sin(titleT*0.07+1)*700;clampView(v);for(const e of mobs)e.t+=dt;for(const s of structs)s.aim+=dt*0.3*(s.team==='blue'?1:-1);updFX(dt);}
let lastT=0,pfA=0,pfN=0,pfGood=0;
function frame(now){
  requestAnimationFrame(frame);
  const rdt=Math.min(0.05,Math.max(0.001,(now-(lastT||now))/1000));lastT=now;RDT=rdt;time+=rdt;
  pfA+=rdt;pfN++;if(pfA>=1){const fps=pfN/pfA;if(fps<44&&RS>0.6){RS=Math.max(0.6,RS-0.1);pfGood=0;}else if(fps>57){if(++pfGood>=3&&RS<1){RS=Math.min(1,RS+0.1);pfGood=0;}}else pfGood=0;pfA=0;pfN=0;}
  const pads=getPads();
  for(let i=0;i<pads.length;i++){const gp=pads[i];if(!gp)continue;if(padEdge(i,gp,9)){if(state==='play')pauseGame();else if(state==='pause')resumeGame();}
    if(state==='play'&&padActive(gp)){if(LOBBY.mode==='solo'&&hams[0]&&hams[0].dev!=='pad')setDevP1('pad',i);const p2=hams.find(q=>q.ctl==='p2');if(p2&&p2.dev==='keys2'&&LOBBY.p2c==='pad'){p2.dev='pad';p2.padIdx=i;}}}
  if(state==='play'){for(const h of hams)if(h.ctl!=='ai')readLocal(h);
    if(hitstop>0)hitstop-=rdt;else{if(slowT>0){slowT-=rdt;timeScale=slowT>0?0.35:1;}else timeScale=1;const dt=rdt*timeScale,n=dt>0.02?2:1;for(let i=0;i<n&&state==='play';i++)update(dt/n);}}
  else if(state==='title')titleUpdate(rdt);else if(state==='result')updFX(rdt*0.5);
  keyEdge.clear();endPadFrame();
  for(const v of VIEWS)updToasts(v,rdt);
  if(gl){try{sync3D(rdt);draw3D();}catch(e){console.error(e);gl=null;$('errText').hidden=false;$('errText').textContent='3D 渲染出错了：'+e.message;}}
  ctx.setTransform(DPR,0,0,DPR,0,0);ctx.clearRect(0,0,W,H);
  if(state==='play'||state==='pause'||state==='result'){for(const v of VIEWS)if(v.ham)drawViewHUD(ctx,v);drawGlobalHUD(ctx);
    const p1=hams[0];if(state==='play'&&p1&&p1.dev==='touch')drawTouch(ctx);if(state==='play'&&p1&&p1.dev==='kbm')drawCross(ctx);}
}
function init(){
  buildMap();buildNav();resize();
  let ok=false;try{ok=initGL()!==false&&!!gl;}catch(e){console.error(e);ok=false;}
  if(ok){try{build3D();}catch(e){console.error(e);gl=null;ok=false;}}
  setupWorld();VIEWS=[mkView(null)];layoutViews();touchLayout();
  try{makeHero();}catch(e){console.error(e);}
  try{$('menuHero').src=$('heroImg').src;}catch(e){}
  if(!ok){$('errText').hidden=false;$('errText').textContent='你的浏览器没能启动 WebGL2 3D 渲染，这一版暂时玩不了。换用最新版 Chrome / Edge / Safari 再试试。';$('startBtn').disabled=true;}
  if(+store.get('mz_mute',0))SFX.setMuted(true);
  updLobby();updateMuteLabel();applyFx();
  window.addEventListener('resize',()=>{resize();layoutViews();touchLayout();});
  requestAnimationFrame(frame);
}
init();
})();
