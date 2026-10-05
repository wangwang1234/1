
// ---------- 实例化部件 ----------
const PARTS={},PART_LIST=[];
function mkPart(name,mdl,max,cast=true){const o=uploadInst(mdl,max);o.cast=cast;o.name=name;PARTS[name]=o;PART_LIST.push(o);return o;}
const TC2={blue:['#3d8bff','#2a62c9','#9cc8ff'],red:['#e0443f','#b8302c','#ffb0b0']};
function buildHamParts(){
  const R=15,T=R*0.085,RES=[22,15],HR=[14,10],N=24;
  for(const sk in SKINS){const C=SKINS[sk];
    const B=new Mdl(T,RES,HR);B.ell(C.fur,-0.04*R,-0.22*R,0,0.72*R,0.6*R,0.7*R);B.ell(C.cream,0.3*R,-0.3*R,0,0.42*R,0.4*R,0.5*R,0,0,0,0);if(C.stripe)B.ell(C.stripe,-0.36*R,0.12*R,0,0.36*R,0.1*R,0.11*R,0,0,0.5,0);mkPart('h_body_'+sk,B,N);
    const Hd=new Mdl(T,RES,HR);Hd.ell(C.fur,0,0,0,0.88*R,0.82*R,0.92*R);Hd.ell(C.cream,0.4*R,-0.2*R,0,0.52*R,0.48*R,0.66*R,0,0,0,0);
    for(const z of [-1,1])Hd.ball('#ff8fa3',0.62*R,-0.1*R,z*0.52*R,0.16*R,0.09*R,0.12*R,-z*0.6,0,0,0);
    Hd.ball('#ff7f96',0.92*R,-0.04*R,0,0.09*R,0.07*R,0.1*R,0,0,0,0,-0.5);Hd.box('#3a2730',0.9*R,-0.15*R,0,0.02*R,0.05*R,0.13*R,0,0,0,0);
    for(const z of [-1,1]){Hd.box('#7a4a3a',0.8*R,-0.08*R,z*0.46*R,0.4*R,0.02*R,0.02*R,z*0.35,0,0.05,0);}
    mkPart('h_head_'+sk,Hd,N);
    const E=new Mdl(T,[14,10],[10,7]);E.ell(C.fur,0,0.16*R,0,0.13*R,0.3*R,0.28*R);E.ell('#ffb3c1',0.07*R,0.16*R,0,0.06*R,0.2*R,0.18*R,0,0,0,0);mkPart('h_ear_'+sk,E,N*2);
    const Tl=new Mdl(T,[12,8],[10,7]);Tl.ell(C.fur,-0.06*R,0,0,0.14*R,0.11*R,0.12*R);mkPart('h_tail_'+sk,Tl,N);}
  const Ey=new Mdl(R*0.03,[16,11],[10,7]);for(const z of [-1,1]){Ey.ell('#2a1d24',0,0,z*0.34*R,0.15*R,0.26*R,0.19*R,0,0,0,R*0.03,-0.95);Ey.ball('#ffffff',0.1*R,0.1*R,z*0.28*R,0.075*R,0.075*R,0.075*R,0,0,0,0,0.5);Ey.ball('#ffffff',0.12*R,-0.1*R,z*0.4*R,0.035*R,0.035*R,0.035*R,0,0,0,0,0.35);}mkPart('h_eyes',Ey,N);
  for(const [nm,z] of [['h_cheekL',-1],['h_cheekR',1]]){const C=new Mdl(0.1,[20,14],[12,8]);C.ell('#fff1e0',0,0,0,1,1,1,0,0,0,0.1,-0.15);C.ball('#ff9fb0',0.42,-0.1,z*0.7,0.28,0.18,0.18,0,0,0,0);mkPart(nm,C,N);}
  const F=new Mdl(R*0.07,[12,8],[10,7]);F.ell('#f7b2a8',0,0,0,0.25*R,0.1*R,0.16*R);for(const k of [-1,0,1])F.ball('#f7b2a8',0.22*R,-0.01*R,k*0.08*R,0.055*R,0.045*R,0.045*R,0,0,0,0);mkPart('h_foot',F,N*2);
  for(const tm of TEAMS){const c=TC2[tm],Cp=new Mdl(R*0.06,[20,14],[14,10]);Cp.ell(c[0],-0.06*R,0.6*R,0,0.68*R,0.42*R,0.66*R,0,0,0,R*0.06,-0.3);Cp.torus(c[1],-0.06*R,0.52*R,0,0.65*R,0.11*R,0,0,0,R*0.05,-0.2);Cp.ball('#ffffff',-0.1*R,1.06*R,0,0.2*R,0.18*R,0.2*R,0,0,0,R*0.05,0.15);mkPart('h_cap_'+tm,Cp,N);}
  const arms=(G,lp,rp)=>{G.rod('#ffe9d2',[-0.46*R,0.1*R,0.34*R],rp,0.13*R);G.rod('#ffe9d2',[-0.46*R,0.1*R,-0.62*R],lp,0.13*R);G.ball('#ffd9c0',rp[0],rp[1],rp[2],0.15*R,0.13*R,0.14*R);G.ball('#ffd9c0',lp[0],lp[1],lp[2],0.14*R,0.12*R,0.13*R);};
  let G=new Mdl(R*0.05,[12,8],[10,7]);
  G.box('#2b2d33',0.4*R,0.07*R,0,0.86*R,0.17*R,0.14*R,0,0,0,R*0.045,-0.6);G.box('#3a3d45',0.34*R,-0.05*R,0,0.7*R,0.1*R,0.13*R,0,0,0,R*0.04,-0.5);G.box('#24262b',0.03*R,-0.21*R,0,0.2*R,0.32*R,0.13*R,0,0,-0.25,R*0.04,-0.5);G.box('#5a5d66',0.83*R,0.07*R,0,0.05*R,0.09*R,0.09*R,0,0,0,0,-0.4);
  arms(G,[0.14*R,-0.14*R,-0.08*R],[0.02*R,-0.16*R,0.08*R]);mkPart('w_pistol',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#c9ced6',0.5*R,0.09*R,0,1.15*R,0.24*R,0.17*R,0,0,0,R*0.05,-0.25);G.box('#9aa0a8',0.55*R,0.23*R,0,1.0*R,0.05*R,0.09*R,0,0,0,0,-0.25);G.box('#2b2d33',0.38*R,-0.07*R,0,0.76*R,0.12*R,0.16*R,0,0,0,R*0.04,-0.5);G.box('#24262b',0.03*R,-0.25*R,0,0.24*R,0.38*R,0.15*R,0,0,-0.25,R*0.045,-0.5);G.box('#6e737c',1.09*R,0.09*R,0,0.05*R,0.2*R,0.14*R,0,0,0,0,-0.4);
  arms(G,[0.16*R,-0.16*R,-0.09*R],[0.02*R,-0.18*R,0.09*R]);mkPart('w_deagle',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#3a3d45',0.35*R,0.03*R,0,0.8*R,0.2*R,0.16*R,0,0,0,R*0.045,-0.5);G.box('#8a5a32',-0.34*R,-0.03*R,0,0.62*R,0.18*R,0.14*R,0,0,0.1,R*0.045,-0.15);G.box('#8a5a32',0.98*R,0.01*R,0,0.5*R,0.16*R,0.17*R,0,0,0,R*0.045,-0.15);G.box('#2b2d33',1.55*R,0.05*R,0,0.72*R,0.07*R,0.07*R,0,0,0,R*0.03,-0.7);G.box('#2b2d33',1.02*R,0.13*R,0,0.55*R,0.05*R,0.06*R,0,0,0,0,-0.6);
  G.box('#2b2d33',0.45*R,-0.22*R,0,0.17*R,0.3*R,0.12*R,0,0,-0.3,R*0.04,-0.6);G.box('#2b2d33',0.56*R,-0.45*R,0,0.17*R,0.24*R,0.12*R,0,0,-0.62,R*0.04,-0.6);G.box('#24262b',0.12*R,-0.17*R,0,0.12*R,0.24*R,0.11*R,0,0,-0.3,R*0.03,-0.5);G.box('#2b2d33',1.86*R,0.13*R,0,0.04*R,0.1*R,0.04*R,0,0,0,0,-0.6);
  arms(G,[0.98*R,-0.1*R,-0.12*R],[0.12*R,-0.22*R,0.08*R]);mkPart('w_ak47',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#33363e',0.4*R,0.04*R,0,0.85*R,0.22*R,0.17*R,0,0,0,R*0.045,-0.5);G.box('#2b2d33',0.94*R,0.05*R,0,0.25*R,0.08*R,0.08*R,0,0,0,R*0.03,-0.7);G.box('#24262b',0.24*R,-0.28*R,0,0.16*R,0.42*R,0.13*R,0,0,-0.12,R*0.04,-0.6);G.box('#4a4d55',-0.17*R,0.03*R,0,0.36*R,0.04*R,0.12*R,0,0,0,0,-0.4);G.box('#4a4d55',-0.34*R,-0.05*R,0,0.04*R,0.18*R,0.12*R,0,0,0,0,-0.4);
  arms(G,[0.62*R,-0.1*R,-0.12*R],[0.22*R,-0.22*R,0.08*R]);mkPart('w_smg',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#7a4a2a',-0.25*R,-0.04*R,0,0.7*R,0.22*R,0.15*R,0,0,0.06,R*0.045,-0.15);G.box('#33363e',0.3*R,0.03*R,0,0.52*R,0.2*R,0.16*R,0,0,0,R*0.045,-0.5);G.cyl('#2b2d33',1.12*R,0.08*R,0,0.07*R,0.07*R,1.3*R,0,0,Math.PI/2,R*0.03,-0.7);G.cyl('#33363e',1.0*R,-0.04*R,0,0.06*R,0.06*R,1.1*R,0,0,Math.PI/2,R*0.03,-0.6);G.box('#5a3a22',0.95*R,-0.04*R,0,0.42*R,0.14*R,0.17*R,0,0,0,R*0.04,-0.15);
  arms(G,[0.95*R,-0.1*R,-0.12*R],[0.1*R,-0.16*R,0.1*R]);mkPart('w_shotgun',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#3b4a3a',0.1*R,-0.02*R,0,0.9*R,0.24*R,0.22*R,0,0,0,R*0.05,-0.4);G.box('#2a2f2a',1.45*R,0.04*R,0,1.9*R,0.1*R,0.1*R,0,0,0,R*0.04,-0.7);G.box('#1d2229',2.42*R,0.04*R,0,0.18*R,0.15*R,0.15*R,0,0,0,R*0.04,-0.7);G.cyl('#1d2229',0.55*R,0.27*R,0,0.11*R,0.11*R,0.8*R,0,0,Math.PI/2,R*0.045,-0.8);G.cyl('#7fe3ff',0.96*R,0.27*R,0,0.09*R,0.09*R,0.02*R,0,0,Math.PI/2,0,0.9);G.box('#3b4a3a',-0.45*R,-0.05*R,0,0.35*R,0.3*R,0.2*R,0,0,0,R*0.045);G.rod('#1d2229',[0.35*R,0.06*R,0.12*R],[0.35*R,0.1*R,0.24*R],0.035*R,0);
  arms(G,[0.85*R,-0.06*R,-0.12*R],[0,-0.12*R,0.1*R]);mkPart('w_sniper',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#3a3d45',0.35*R,0.04*R,0,0.95*R,0.26*R,0.2*R,0,0,0,R*0.05,-0.5);G.box('#2b2d33',1.42*R,0.08*R,0,0.95*R,0.09*R,0.09*R,0,0,0,R*0.035,-0.7);G.box('#4b5530',0.3*R,-0.26*R,-0.05*R,0.36*R,0.3*R,0.3*R,0,0,0,R*0.05,-0.25);G.box('#24262b',-0.32*R,0,0,0.5*R,0.2*R,0.14*R,0,0,0.05,R*0.045,-0.5);G.box('#2b2d33',0.5*R,0.25*R,0,0.36*R,0.05*R,0.06*R,0,0,0,0,-0.5);
  G.rod('#2b2d33',[1.55*R,0.02*R,-0.05*R],[1.25*R,-0.2*R,-0.12*R],0.03*R,0);G.rod('#2b2d33',[1.55*R,0.02*R,0.05*R],[1.25*R,-0.2*R,0.12*R],0.03*R,0);G.box('#c9a44a',0.55*R,-0.05*R,0.2*R,0.12*R,0.05*R,0.18*R,0,0,0,0,0.1);
  arms(G,[0.92*R,-0.08*R,-0.14*R],[0.05*R,-0.16*R,0.1*R]);mkPart('w_lmg',G,N);
  G=new Mdl(R*0.06,[12,8],[10,7]);G.cyl('#4b5530',0.45*R,0.16*R,0,0.12*R,0.12*R,1.9*R,0,0,Math.PI/2,R*0.05,-0.3);G.cyl('#8a5a32',0.48*R,0.16*R,0,0.16*R,0.16*R,0.5*R,0,0,Math.PI/2,R*0.05,-0.15);G.cyl('#5d6b3a',1.62*R,0.16*R,0,0.05*R,0.21*R,0.38*R,0,0,-Math.PI/2,R*0.05,-0.3);G.cyl('#3a3f2a',1.36*R,0.16*R,0,0.1*R,0.1*R,0.16*R,0,0,Math.PI/2,R*0.04,-0.4);G.cyl('#2d3320',-0.55*R,0.16*R,0,0.18*R,0.12*R,0.2*R,0,0,Math.PI/2,R*0.05,-0.4);
  G.box('#2d3320',0.25*R,-0.08*R,0,0.12*R,0.26*R,0.1*R,0,0,-0.2,R*0.04);G.box('#2d3320',0.75*R,-0.06*R,0,0.1*R,0.22*R,0.1*R,0,0,-0.2,R*0.04);
  arms(G,[0.75*R,-0.12*R,-0.12*R],[0.25*R,-0.16*R,0.1*R]);mkPart('w_rocket',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.cyl('#2a2030',0.18*R,0,0,0.06*R,0.06*R,0.5*R,0,0,Math.PI/2,R*0.04);G.torus('#ffcf3a',0.45*R,0,0,0.11*R,0.03*R,0,0,Math.PI/2,R*0.03,-0.6);G.box('#e8eef6',1.45*R,0,0,1.9*R,0.05*R,0.15*R,0,0,0,R*0.035,-0.9);G.box('#bfe7ff',1.45*R,0.03*R,0,1.88*R,0.01*R,0.04*R,0,0,0,0,0.6);
  arms(G,[0.32*R,-0.02*R,-0.05*R],[0.05*R,-0.03*R,0.06*R]);mkPart('w_katana',G,N);
  G=new Mdl(R*0.06,[12,8],[10,7]);G.cyl('#d8423f',-0.05*R,0.2*R,-0.32*R,0.2*R,0.2*R,0.62*R,0,0,Math.PI/2,R*0.06,-0.4);G.torus('#ffd166',-0.05*R,0.2*R,-0.32*R,0.2*R,0.03*R,0,0,Math.PI/2,0,0.2);G.box('#3a3f48',0.35*R,0,0,0.7*R,0.24*R,0.22*R,0,0,0,R*0.06,-0.5);G.cyl('#2d3038',1.15*R,0.02*R,0,0.08*R,0.1*R,1.0*R,0,0,Math.PI/2,R*0.05,-0.6);G.ball('#7fb6ff',1.7*R,0.02*R,0,0.07*R,0.07*R,0.07*R,0,0,0,0,1);
  arms(G,[0.85*R,-0.08*R,-0.12*R],[0.1*R,-0.12*R,0.1*R]);mkPart('w_flame',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#3a3d45',0.3*R,0.02*R,0,0.8*R,0.3*R,0.28*R,0,0,0,R*0.05,-0.5);G.box('#4b5530',0.1*R,-0.3*R,0.08*R,0.4*R,0.3*R,0.3*R,0,0,0,R*0.05,-0.25);G.box('#24262b',0.05*R,0.26*R,0,0.3*R,0.08*R,0.1*R,0,0,0,0,-0.5);G.cyl('#2b2d33',0.78*R,0.02*R,0,0.16*R,0.16*R,0.14*R,0,0,Math.PI/2,R*0.04,-0.6);G.box('#c9a44a',0.35*R,-0.1*R,0.2*R,0.1*R,0.06*R,0.16*R,0,0,0,0,0.1);
  arms(G,[0.55*R,-0.12*R,-0.16*R],[0.1*R,-0.16*R,0.12*R]);mkPart('w_minigun',G,N);
  G=new Mdl(R*0.035,[10,7],[8,6]);for(let k=0;k<6;k++){const a=k/6*TAU;G.cyl('#2b2d33',0.55*R,Math.cos(a)*0.09*R,Math.sin(a)*0.09*R,0.035*R,0.035*R,1.1*R,0,0,Math.PI/2,R*0.025,-0.7);}G.torus('#55585f',0.95*R,0,0,0.12*R,0.025*R,0,0,Math.PI/2,0,-0.5);G.torus('#55585f',0.2*R,0,0,0.12*R,0.025*R,0,0,Math.PI/2,0,-0.5);mkPart('w_minigun_x',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#2f3238',0.35*R,0.04*R,0,1.0*R,0.26*R,0.2*R,0,0,0,R*0.05,-0.5);G.box('#24262b',-0.3*R,0,0,0.5*R,0.22*R,0.16*R,0,0,0.05,R*0.045,-0.5);G.cyl('#2b2d33',1.15*R,0.06*R,0,0.08*R,0.08*R,0.6*R,0,0,Math.PI/2,R*0.03,-0.7);G.cyl('#4b5530',0.42*R,-0.3*R,0,0.2*R,0.2*R,0.16*R,0,Math.PI/2,0,R*0.05,-0.25);G.box('#24262b',0.12*R,-0.2*R,0,0.12*R,0.24*R,0.11*R,0,0,-0.3,R*0.03,-0.5);
  arms(G,[0.85*R,-0.1*R,-0.13*R],[0.1*R,-0.2*R,0.1*R]);mkPart('w_autoshot',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#4a4f3a',0.2*R,0,0,1.1*R,0.28*R,0.22*R,0,0,0,R*0.05,-0.4);G.box('#2a2f2a',1.6*R,0.05*R,0,1.9*R,0.12*R,0.12*R,0,0,0,R*0.04,-0.7);G.box('#1d2229',2.62*R,0.05*R,0,0.28*R,0.22*R,0.2*R,0,0,0,R*0.04,-0.7);G.cyl('#1d2229',0.4*R,0.3*R,0,0.13*R,0.13*R,0.9*R,0,0,Math.PI/2,R*0.045,-0.8);G.cyl('#ff8a3d',0.86*R,0.3*R,0,0.1*R,0.1*R,0.02*R,0,0,Math.PI/2,0,0.9);G.box('#2b2d33',0.35*R,-0.26*R,0,0.2*R,0.26*R,0.14*R,0,0,0,R*0.04,-0.6);G.box('#4a4f3a',-0.55*R,-0.02*R,0,0.45*R,0.3*R,0.2*R,0,0,0,R*0.045);G.rod('#2b2d33',[1.9*R,0,-0.06*R],[1.6*R,-0.25*R,-0.16*R],0.035*R,0);G.rod('#2b2d33',[1.9*R,0,0.06*R],[1.6*R,-0.25*R,0.16*R],0.035*R,0);
  arms(G,[0.95*R,-0.08*R,-0.14*R],[0,-0.14*R,0.1*R]);mkPart('w_amr',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);for(const z of [-0.56,0.28]){G.box('#2b2d33',0.4*R,0.07*R,z*R,0.86*R,0.17*R,0.14*R,0,0,0,R*0.045,-0.6);G.box('#24262b',0.03*R,-0.17*R,z*R,0.2*R,0.3*R,0.13*R,0,0,-0.25,R*0.04,-0.5);G.box('#5a5d66',0.83*R,0.07*R,z*R,0.05*R,0.09*R,0.09*R,0,0,0,0,-0.4);}
  arms(G,[0.03*R,-0.12*R,-0.56*R],[0.03*R,-0.12*R,0.28*R]);mkPart('w_dual',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.cyl('#8f939b',0.75*R,0.08*R,0,0.07*R,0.07*R,0.75*R,0,0,Math.PI/2,R*0.035,-0.4);G.cyl('#6e737c',0.28*R,0.05*R,0,0.15*R,0.15*R,0.26*R,0,0,Math.PI/2,R*0.045,-0.4);G.box('#8f939b',0.18*R,0.08*R,0,0.36*R,0.16*R,0.12*R,0,0,0,R*0.04,-0.4);G.box('#7a4a2a',-0.02*R,-0.2*R,0,0.2*R,0.34*R,0.14*R,0,0,-0.3,R*0.045,-0.15);
  arms(G,[0.14*R,-0.14*R,-0.08*R],[0.02*R,-0.16*R,0.08*R]);mkPart('w_revolver',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.cyl('#4b5530',0.85*R,0.08*R,0,0.17*R,0.17*R,1.0*R,0,0,Math.PI/2,R*0.05,-0.3);G.box('#8a5a32',-0.15*R,-0.02*R,0,0.8*R,0.22*R,0.15*R,0,0,0.08,R*0.045,-0.15);G.box('#2b2d33',0.3*R,0.05*R,0,0.3*R,0.22*R,0.17*R,0,0,0,R*0.04,-0.5);G.torus('#2b2d33',1.35*R,0.08*R,0,0.17*R,0.03*R,0,0,Math.PI/2,0,-0.5);
  arms(G,[0.8*R,-0.12*R,-0.14*R],[0.12*R,-0.16*R,0.1*R]);mkPart('w_gl',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#d6dbe4',0.35*R,0.04*R,0,0.9*R,0.26*R,0.22*R,0,0,0,R*0.05,-0.2);for(const z of [-0.08,0.08])G.box('#3a4656',1.35*R,0.06*R,z*R,1.3*R,0.06*R,0.05*R,0,0,0,R*0.03,-0.5);for(let k=0;k<4;k++)G.torus('#5fe0ff',0.95*R+k*0.28*R,0.06*R,0,0.12*R,0.025*R,0,0,Math.PI/2,0,0.9);G.box('#24262b',0.1*R,-0.18*R,0,0.12*R,0.24*R,0.11*R,0,0,-0.3,R*0.03,-0.5);G.box('#5fe0ff',0.3*R,0.18*R,0,0.5*R,0.03*R,0.12*R,0,0,0,0,0.8);
  arms(G,[0.85*R,-0.1*R,-0.12*R],[0.1*R,-0.18*R,0.1*R]);mkPart('w_rail',G,N);
  G=new Mdl(R*0.05,[12,8],[10,7]);G.box('#ecebf2',0.4*R,0.03*R,0,0.95*R,0.24*R,0.2*R,0,0,0,R*0.05,-0.2);G.cyl('#3a4656',1.0*R,0.05*R,0,0.1*R,0.07*R,0.4*R,0,0,Math.PI/2,R*0.035,-0.4);G.ball('#ff5fa8',1.22*R,0.05*R,0,0.07*R,0.07*R,0.07*R,0,0,0,0,1);G.box('#ff5fa8',0.4*R,0.16*R,0,0.6*R,0.03*R,0.14*R,0,0,0,0,0.8);G.cyl('#3a4656',0.15*R,-0.22*R,0,0.1*R,0.1*R,0.24*R,0,0,0,R*0.04,-0.4);
  arms(G,[0.8*R,-0.1*R,-0.12*R],[0.1*R,-0.16*R,0.1*R]);mkPart('w_laser',G,N);
}
function buildCritterParts(){
  const R=11;for(const tm of TEAMS){const c=TC2[tm];const M=new Mdl(R*0.09,[14,10],[10,7]);
    M.ell('#d9a066',-0.05*R,0.85*R,0,0.85*R,0.78*R,0.8*R);M.ell('#fff2df',0.4*R,0.7*R,0,0.42*R,0.5*R,0.55*R,0,0,0,0);M.ell('#d9a066',0.35*R,1.55*R,0,0.62*R,0.56*R,0.62*R);
    M.ell(c[0],0.25*R,1.85*R,0,0.66*R,0.36*R,0.68*R,0,0,0,R*0.09,-0.4);M.box(c[1],0.75*R,1.7*R,0,0.3*R,0.08*R,0.9*R,0,0,0,0);
    for(const s of [-1,1]){M.ball('#2a1d1d',0.9*R,1.45*R,s*0.24*R,0.09*R,0.12*R,0.09*R,0,0,0,0,-0.9);M.ball('#f7b2a8',0.25*R,0.06*R,s*0.36*R,0.24*R,0.1*R,0.16*R,0,0,0,0);}
    M.box('#2d3846',0.95*R,0.75*R,0.25*R,0.9*R,0.22*R,0.2*R,0,0,0,R*0.06,-0.5);M.ball(c[0],1.42*R,0.75*R,0.25*R,0.08*R,0.08*R,0.08*R,0,0,0,0,0.8);mkPart('min_'+tm,M,64);}
  const r=19,T=r*0.07,RES=[16,11],HR=[12,8];
  const B=new Mdl(T,RES,HR);B.ell('#8f929e',-0.08*r,0,0,0.92*r,0.86*r,0.82*r);B.ell('#c9cbd4',0.4*r,-0.16*r,0,0.45*r,0.55*r,0.55*r,0,0,0,0);B.ell('#7b7e8a',-0.4*r,0.42*r,0,0.55*r,0.28*r,0.55*r,0,0,0,0);B.cyl('#d8423f',0.62*r,0.05*r,0,0.06*r,0.5*r,0.36*r,0,Math.PI,0);B.ell('#b8302c',0.3*r,0.42*r,0,0.2*r,0.14*r,0.52*r,0,0,0,0);mkPart('rat_body',B,24);
  const Hd=new Mdl(T,RES,HR);Hd.ell('#8f929e',0,0,0,0.6*r,0.56*r,0.6*r);Hd.ell('#b5b8c3',0.5*r,-0.13*r,0,0.44*r,0.26*r,0.3*r);Hd.ball('#ff7f96',0.9*r,-0.09*r,0,0.1*r,0.09*r,0.1*r,0,0,0,0,-0.6);
  for(const s of [-1,1]){Hd.box('#f6f2e8',0.8*r,-0.32*r,s*0.05*r,0.06*r,0.12*r,0.07*r,0,0,0,r*0.03,-0.4);Hd.box('#5d5f69',0.7*r,-0.1*r,s*0.36*r,0.5*r,0.02*r,0.02*r,s*0.5,0,0.1,0);Hd.ell('#8f929e',-0.18*r,0.47*r,s*0.52*r,0.12*r,0.38*r,0.36*r,0,s*0.2,0);Hd.ell('#f2a5b3',-0.12*r,0.47*r,s*0.52*r,0.05*r,0.26*r,0.24*r,0,s*0.2,0,0);Hd.ell('#ff2a44',0.56*r,0.15*r,s*0.2*r,0.025*r,0.055*r,0.11*r,0,0,0,0,0.85);}
  Hd.box('#16141c',0.48*r,0.15*r,0,0.14*r,0.2*r,0.86*r,0,0,0,T,-0.9);Hd.box('#ffffff',0.56*r,0.21*r,-0.22*r,0.02*r,0.04*r,0.2*r,0,0,0,0,1);
  Hd.ell('#2b3550',-0.08*r,0.36*r,0,0.5*r,0.3*r,0.52*r,0,0,0.25,T,-0.2);Hd.box('#232b42',-0.52*r,0.28*r,0,0.36*r,0.05*r,0.44*r,0,0,0.3,T);Hd.ball('#ff8c42',-0.1*r,0.66*r,0,0.07*r,0.05*r,0.07*r,0,0,0,0,0.25);mkPart('rat_head',Hd,24);
  const Tl=new Mdl(r*0.05);Tl.tube('#e59aa6',[[0,0,0],[-0.65*r,-0.12*r,0.35*r],[-1.25*r,0.05*r,-0.15*r],[-1.8*r,-0.1*r,0.3*r],[-2.2*r,0.05*r,0.05*r]],0.08*r);mkPart('rat_tail',Tl,24);
  const G=new Mdl(r*0.06,[12,8],[10,7]);G.box('#34343c',0.35*r,0,0,1.25*r,0.3*r,0.28*r,0,0,0,r*0.06,-0.5);G.box('#ff8c42',0.25*r,0.17*r,0,0.5*r,0.05*r,0.29*r,0,0,0,0,0.25);G.box('#22222a',1.12*r,0.02*r,0,0.42*r,0.17*r,0.17*r,0,0,0,r*0.06,-0.6);
  G.rod('#8f929e',[-0.52*r,0.2*r,0.31*r],[0,-0.08*r,0.1*r],0.11*r);G.rod('#8f929e',[-0.52*r,0.2*r,-0.61*r],[0.58*r,-0.06*r,-0.16*r],0.11*r);G.ball('#c9cbd4',0,-0.1*r,0.1*r,0.13*r,0.11*r,0.12*r);G.ball('#c9cbd4',0.6*r,-0.08*r,-0.16*r,0.12*r,0.1*r,0.11*r);mkPart('rat_gun',G,24);
  const F=new Mdl(T,[12,8],[10,7]);F.ell('#e8a1ad',0,0,0,0.25*r,0.1*r,0.16*r);for(const k of [-1,0,1])F.ball('#e8a1ad',0.22*r,-0.01*r,k*0.08*r,0.05*r,0.04*r,0.05*r,0,0,0,0);mkPart('rat_foot',F,48);
  const Cr=new Mdl(1.2,[12,8],[10,7]);Cr.torus('#ffcf3a',0,0,0,8,1.8,0,0,0,1.2,-0.8);for(let k=0;k<5;k++){const a=k/5*TAU;Cr.cyl('#ffcf3a',Math.cos(a)*8,4,Math.sin(a)*8,0.3,2.4,8,0,0,0,1,-0.8);Cr.ball('#ff3d6e',Math.cos(a)*8,8.6,Math.sin(a)*8,1.4,1.4,1.4,0,0,0,0,0.8);}mkPart('crown',Cr,2);
  const q=10,QT=q*0.09,QR=[12,8],QH=[10,7];const RB=new Mdl(QT,QR,QH);
  RB.ell('#5a3016',-0.6*q,0.42*q,0,0.72*q,0.34*q,0.6*q,0,0,0,QT,-0.4);RB.ell('#6a3a1c',-0.12*q,0.48*q,0,0.72*q,0.4*q,0.74*q,0,0,0,QT,-0.4);
  for(const s of [-1,1])RB.ell('#8a5226',-0.28*q,0.78*q,s*0.26*q,1.08*q,0.16*q,0.36*q,s*0.07,0,0,q*0.05,-0.8);
  RB.box('#2e170a',-0.28*q,0.94*q,0,2.0*q,0.03*q,0.05*q,0,0,0,0);RB.ell('#7a4522',0.62*q,0.6*q,0,0.42*q,0.2*q,0.56*q,0,0,0,QT,-0.55);RB.ell('#c08a55',0.66*q,0.7*q,0,0.3*q,0.08*q,0.4*q,0,0,0,0,-0.3);RB.ell('#43230f',1.08*q,0.4*q,0,0.36*q,0.32*q,0.4*q,0,0,0,QT,-0.45);
  for(const s of [-1,1]){RB.ball('#ffffff',1.3*q,0.56*q,s*0.2*q,0.15*q,0.15*q,0.15*q,0,0,0,q*0.05);RB.ball('#000000',1.4*q,0.58*q,s*0.2*q,0.075*q,0.075*q,0.075*q,0,0,0,0);RB.cyl('#2a1408',1.42*q,0.22*q,s*0.12*q,0.02*q,0.07*q,0.22*q,s*0.5,0,-1.9,0);RB.rod('#3a1f0f',[-1.15*q,0.4*q,s*0.12*q],[-1.6*q,0.52*q,s*0.32*q],0.04*q,0);}
  mkPart('roach_body',RB,48);
  const A=new Mdl(q*0.035);for(const s of [-1,1])A.tube('#3a1f0f',[[0,0,s*0.15*q],[0.6*q,0.42*q,s*0.48*q],[1.3*q,0.3*q,s*0.62*q],[1.85*q,0.1*q,s*0.52*q]],0.05*q);mkPart('roach_ant',A,48);
  const leg=(M,i,s)=>{const bx=i*0.5*q,kx=bx+i*0.28*q,fx=bx+i*0.45*q;M.rod('#3a1f0f',[bx,0.42*q,s*0.5*q],[kx,0.64*q,s*1.05*q],0.08*q,q*0.035,-0.4);M.rod('#3a1f0f',[kx,0.64*q,s*1.05*q],[fx,0.02*q,s*1.45*q],0.065*q,q*0.035,-0.4);};
  const LA=new Mdl(q*0.035),LB=new Mdl(q*0.035);leg(LA,1,-1);leg(LA,0,1);leg(LA,-1,-1);leg(LB,1,1);leg(LB,0,-1);leg(LB,-1,1);mkPart('roach_legsA',LA,48);mkPart('roach_legsB',LB,48);
  const C=new Mdl(0.9,[14,10],[10,7]);C.ell('#ffd23f',0,8,0,9,8,8.5);C.ell('#ffd23f',5,15,0,6.5,6,6);C.cyl('#ff8a3d',11.5,14.5,0,0.4,2.2,4,0,0,-Math.PI/2,0.6);for(const s of [-1,1]){C.ball('#2a1d1d',9.5,17,s*2.6,1,1.2,1,0,0,0,0,-0.9);C.ell('#ffc21a',-1,9,s*8,4,2.5,1.5,0,0,0,0);C.rod('#ff8a3d',[1,2,s*3],[1.5,0,s*3.5],0.6,0);}C.ell('#ffd23f',2,21,0,1.2,2.5,1.2,0,0,0.4,0);mkPart('pet_chick',C,24);
  const Fy=new Mdl(0.5,[10,7],[8,6]);Fy.ell('#2b2b36',0,0,0,3.5,2.6,2.6);Fy.ell('#d4ff6a',-4,0,0,3.4,2.8,2.8,0,0,0,0,1);for(const s of [-1,1])Fy.box('#e8f4ff',0.5,2.2,s*3.5,3.5,0.3,4,0,0,0,0,0.25);mkPart('pet_firefly',Fy,24);
  const Hh=new Mdl(0.9,[14,10],[10,7]);Hh.ell('#8a5a3a',-1,7,0,10,7,8.5);Hh.ell('#f0d9b5',7,6,0,5,4.5,5);Hh.ball('#2a1d1d',11.6,6.5,0,1.2,1.1,1.1,0,0,0,0,-0.8);for(const s of [-1,1])Hh.ball('#2a1d1d',9.6,8.4,s*2.4,0.9,1,0.9,0,0,0,0,-0.9);
  for(let k=0;k<12;k++){const a=-1.2+k/11*2.4,x=-3+Math.cos(a)*2,z=Math.sin(a)*7;Hh.cyl('#5e3a22',x-2,15,z,0.2,1.8,7,0,0.35*Math.sign(z||1),0.7,0);}mkPart('pet_hedgehog',Hh,24);
}
function buildMiscParts(){
  for(const tm of TEAMS){const c=TC2[tm];
    const Bt=new Mdl(1.6,[14,10],[12,8]);Bt.cyl('#8c8a99',0,22,0,32,36,44,0,0,0,1.6,-0.2);Bt.torus(c[0],0,30,0,34.5,3,0,0,0,0,0.35);Bt.cyl('#6e6c7c',0,46,0,26,30,6,0,0,0,1.4);mkPart('tur_base_'+tm,Bt,8);
    const Ht=new Mdl(1.4,[16,11],[12,8]);Ht.ell(c[1],0,0,0,20,16,20,0,0,0,1.4,-0.3);Ht.cyl('#2d3038',24,2,0,6,7,30,0,0,Math.PI/2,1.2,-0.5);Ht.torus(c[0],38,2,0,7.5,2,0,0,Math.PI/2,0,0.6);Ht.ell('#ffe8a0',8,10,0,6,3,8,0,0,0,0,0.5);mkPart('tur_head_'+tm,Ht,8);}
  const Cb=new Mdl(1.6);Cb.box('#c89359',0,17,0,40,34,40);Cb.box('#e04848',0,17,0,40.6,8,40.6,0,0,0,0);Cb.box('#fff4d6',0,34.4,0,22,0.6,16,0,0,0,0);mkPart('crate',Cb,24);
  const Cg=new Mdl(2);Cg.box('#e8b730',0,25,0,60,50,60,0,0,0,2,-0.5);Cg.box('#e04848',0,25,0,61,9,61,0,0,0,0);Cg.box('#e04848',0,25,0,9,51,61,0,0,0,0);Cg.ball('#e04848',0,52,0,10,6,10);mkPart('crate_big',Cg,2);
  const Gm=new Mdl(0.7,[10,7],[8,6]);Gm.ell('#b8ff5a',0,0,0,3.6,2.6,6,0,0,0,0.7,0.55);mkPart('gem',Gm,300,false);
  const Gb=new Mdl(0.8,[10,7],[8,6]);Gb.ell('#ffd23f',0,0,0,5,3.6,8,0,0,0,0.8,0.65);mkPart('gem_big',Gb,80,false);
  const Ch=new Mdl(1);Ch.cyl('#ffd23f',0,5,0,12,12,10,0,0,0,1,-0.2,3);Ch.disc('#e0a91a',2,10.3,-2,2.4,2.4);Ch.disc('#e0a91a',-3,10.3,3,1.8,1.8);mkPart('cheese',Ch,30,false);
  const pj=(nm,col,r,em,sx=1)=>{const M=new Mdl(r*0.2,[10,7],[8,6]);M.ell(col,0,0,0,r*sx,r,r,0,0,0,r*0.2,em);mkPart(nm,M,180,false);};
  pj('pea_b','#7fd4ff',4.6,0.9);pj('pea_r','#ff7f9a',4.6,0.9);pj('pel_b','#d8f0ff',3.4,0.9);pj('pel_r','#ffd9a8',3.4,0.9);pj('trc_b','#eaf6ff',2.2,1.2,3.2);pj('trc_r','#ffe6b8',2.2,1.2,3.2);pj('mpea_b','#6fb8ff',3.6,0.7);pj('mpea_r','#ff6f8a',3.6,0.7);
  pj('seed_b','#5fb0ff',7,1);pj('seed_r','#ff6070',7,1);pj('orb','#ff6fd0',6,1);pj('rat','#ff3d6e',5.5,1);pj('snipe','#bff4ff',2.4,1,6);
  const Rk=new Mdl(0.8,[10,7],[8,6]);Rk.cyl('#d8dde5',0,0,0,3.2,3.2,16,0,0,Math.PI/2,0.8,-0.5);Rk.cyl('#e0443f',10,0,0,0.3,3.2,5,0,0,-Math.PI/2,0.8);for(const s of [-1,1])Rk.box('#5d6b3a',-7,0,s*3.5,4,0.6,3,0,0,0,0);mkPart('rocket',Rk,40,false);
  const Sp=new Mdl(0.5,[8,6],[8,6]);Sp.cyl('#6a4428',0,0,0,0.3,2,9,0,0,-Math.PI/2,0.5);mkPart('spike',Sp,60,false);
  const Gn=new Mdl(0.6,[12,8],[10,7]);Gn.ell('#5d6b3a',0,0,0,5,4,4,0,0,0,0.6,-0.2);Gn.torus('#ffd166',0,0,0,4.2,0.8,0,0,Math.PI/2,0,0.2);mkPart('gnade',Gn,30);
  const Fg=new Mdl(0.6,[12,8],[10,7]);Fg.ell('#4f6b3a',0,0,0,4.6,5.6,4.6,0,0,0,0.6,-0.2);Fg.box('#b9c2cc',0,6,1.5,1.4,2.6,3,0,0,0,0.4);Fg.torus('#b9c2cc',2.4,6.5,0,1.4,0.4,0,0,0,0,-0.3);mkPart('frag',Fg,30);
  const Mo=new Mdl(0.6,[12,8],[10,7]);Mo.cyl('#3f7a4a',0,0,0,4,4.4,10,0,0,0,0.6,-0.3);Mo.cyl('#3f7a4a',0,7,0,1.6,2.6,5,0,0,0,0.5,-0.3);Mo.ell('#f2e2c0',0,11,0,2,3,2,0,0,0,0.4);Mo.ball('#ffb04a',0,13.5,0,1.8,1.8,1.8,0,0,0,0,1);mkPart('molo',Mo,30);
  const Fl=new Mdl(0.6,[12,8],[10,7]);Fl.cyl('#c9ced6',0,0,0,3.4,3.4,9,0,0,0,0.6,-0.4);Fl.torus('#5fb0ff',0,1,0,3.5,0.6,0,0,0,0,0.5);Fl.box('#9aa0a8',0,5.5,1.4,1.2,2,2.6,0,0,0,0.3);mkPart('flsh',Fl,30);
  const Mn=new Mdl(0.8,[14,8],[12,8]);Mn.cyl('#3a3f2a',0,1.5,0,11,12,3,0,0,0,0.8,-0.3);Mn.cyl('#5d6b3a',0,3.5,0,7,8,2,0,0,0,0.6,-0.3);Mn.ball('#ff3d4e',0,4.8,0,1.6,1.2,1.6,0,0,0,0,0.6);mkPart('mine',Mn,40);
  for(const tm of TEAMS){const c=TC2[tm];const Sb=new Mdl(0.8,[10,7],[8,6]);for(let k=0;k<3;k++){const a=k/3*TAU;Sb.rod('#55585f',[0,14,0],[Math.cos(a)*12,0,Math.sin(a)*12],1.4,0.6);}Sb.cyl(c[1],0,15,0,5,6,4,0,0,0,0.6);mkPart('sentry_base_'+tm,Sb,10);
    const Sh2=new Mdl(0.8,[12,8],[10,7]);Sh2.box(c[0],0,0,0,12,8,9,0,0,0,0.8,-0.3);Sh2.box('#2b2d33',9,1,0,10,2.6,2.6,0,0,0,0.5,-0.6);Sh2.box('#2b2d33',-2,5,0,6,2,6,0,0,0,0.4);Sh2.ball('#ffe8a0',4,2,4.6,1.4,1.4,0.6,0,0,0,0,0.8);mkPart('sentry_head_'+tm,Sh2,10);}
  const Lb=new Mdl(1,[14,10],[10,7]);Lb.cyl('#3a3f48',0,2,0,14,15,4,0,0,0,1,-0.3);Lb.cyl('#55585f',0,32,0,2.2,2.2,58,0,0,0,0.8,-0.5);Lb.cyl('#f2e2c0',0,62,0,8,17,16,0,0,0,1.2,0.05);Lb.ball('#55585f',0,71,0,3,2,3,0,0,0,0.6);mkPart('lamp_base',Lb,14);
  const Lu=new Mdl(0.5,[12,8],[10,7]);Lu.ball('#fff1c0',0,56,0,7,6,7,0,0,0,0,1);mkPart('lamp_bulb',Lu,14,false);
  const Br=new Mdl(1.2,[14,10],[12,8]);Br.cyl('#d8423f',0,20,0,16,16,36,0,0,0,1.2,-0.3);Br.ell('#d8423f',0,38,0,15,6,15,0,0,0,1);Br.cyl('#ffd23f',0,22,0,16.4,16.4,8,0,0,0,0,0.2);Br.cyl('#2b2d33',0,44,0,3,3,6,0,0,0,0.6,-0.5);Br.box('#2b2d33',3,46,0,8,2,2,0,0,0,0.4);Br.ball('#1d1d24',0,22,16.2,5,5,0.6,0,0,0,0);mkPart('barrel',Br,12);
  const Pb=new Mdl(1.6);Pb.box('#c89359',0,30,0,70,60,70);Pb.box('#e6c58a',0,60.4,0,70.4,0.6,12,0,0,0,0);Pb.box('#e6c58a',0,30,35.2,12,60,0.6,0,0,0,0);Pb.box('#d84a3a',-18,40,35.4,16,10,0.4,0,0,0,0);mkPart('pbox',Pb,16);
  const Pd=new Mdl(1.2,[14,10],[12,8]);Pd.box('#3a3f48',0,3,0,56,6,56,0,0,0,1.2,-0.3);for(let k=0;k<4;k++)Pd.torus('#ffd23f',0,9+k*4.5,0,13,2,0,0,0,0,-0.2);Pd.box('#55585f',0,27,0,46,4,46,0,0,0,1,-0.3);Pd.box('#ffd23f',2,29.4,0,26,0.6,7,0,0,0,0,0.6);Pd.box('#ffd23f',14,29.4,-5,12,0.6,3,-0.6,0,0,0,0.6);Pd.box('#ffd23f',14,29.4,5,12,0.6,3,0.6,0,0,0,0.6);mkPart('pad',Pd,8);
  {const R=15,M=(nm,f,n=24,cast=true)=>{const m=new Mdl(R*0.04,[12,8],[10,7]);f(m);mkPart(nm,m,n,cast);};
   M('h_vest',m=>{m.ell('#4b5530',-0.04*R,-0.16*R,0,0.76*R,0.5*R,0.74*R,0,0,0,R*0.04,-0.2);m.box('#3a4228',0.62*R,-0.16*R,0,0.12*R,0.26*R,0.34*R,0,0,0,R*0.03);for(const z of [-1,1])m.box('#3a4228',0.1*R,0.24*R,z*0.4*R,0.5*R,0.08*R,0.12*R,0,0,0,0);});
   M('h_bando',m=>{m.torus('#7a4a2a',-0.04*R,-0.14*R,0,0.74*R,0.06*R,0,0.7,0,0);for(let k=0;k<5;k++){const a=-0.6+k*0.3;m.box('#e8c45a',Math.cos(a)*0.74*R,-0.14*R+Math.sin(a)*0.45*R,Math.sin(a)*0.5*R,0.06*R,0.16*R,0.06*R,0,0.7,0,0,0.1);}});
   M('h_belt',m=>{m.torus('#5a3a22',-0.04*R,-0.44*R,0,0.7*R,0.07*R,0,0,0,0);for(const a of [-1.1,0,1.1])m.box('#6b4a2a',Math.cos(a)*0.72*R,-0.46*R,Math.sin(a)*0.72*R,0.16*R,0.2*R,0.16*R,-a,0,0,R*0.03);});
   M('h_magnet',m=>{for(const z of [-0.4,-0.16])m.box('#e0443f',-0.8*R,0.08*R,z*R,0.12*R,0.36*R,0.1*R,0,0,0,R*0.03);m.box('#e0443f',-0.8*R,0.3*R,-0.28*R,0.12*R,0.1*R,0.34*R,0,0,0,R*0.03);for(const z of [-0.4,-0.16])m.box('#c9ced6',-0.8*R,-0.12*R,z*R,0.13*R,0.08*R,0.11*R,0,0,0,0);});
   M('h_coilpack',m=>{m.cyl('#55585f',-0.8*R,0.12*R,0.3*R,0.09*R,0.12*R,0.42*R,0,0,0,R*0.03);m.torus('#5fe0ff',-0.8*R,0.36*R,0.3*R,0.14*R,0.04*R,0,0,0,0,0.9);m.ball('#bff4ff',-0.8*R,0.46*R,0.3*R,0.07*R,0.07*R,0.07*R,0,0,0,0,1);});
   for(const tm of TEAMS)M('h_banner_'+tm,m=>{m.cyl('#d9d4e2',-0.7*R,0.85*R,0,0.025*R,0.025*R,1.5*R,0,0,0,0);m.box(TC2[tm][0],-0.92*R,1.42*R,0,0.42*R,0.3*R,0.03*R,0,0,0,R*0.03,0.1);m.ball('#ffd166',-0.7*R,1.62*R,0,0.05*R,0.05*R,0.05*R,0,0,0,0,0.5);});
   M('h_jetpack',m=>{for(const z of [-0.18,0.18]){m.cyl('#8f939b',-0.82*R,0.1*R,z*R,0.13*R,0.13*R,0.52*R,0,0,0,R*0.03,-0.3);m.cyl('#2b2d33',-0.82*R,-0.22*R,z*R,0.1*R,0.06*R,0.12*R,0,0,0,0);}m.box('#55585f',-0.74*R,0.1*R,0,0.08*R,0.3*R,0.3*R,0,0,0,0);});
   M('h_glasses',m=>{for(const z of [-1,1])m.torus('#2b1d24',0.86*R,0.1*R,z*0.33*R,0.17*R,0.03*R,0,0,Math.PI/2,0);m.box('#2b1d24',0.9*R,0.12*R,0,0.03*R,0.03*R,0.3*R,0,0,0,0);});
   M('h_nvg',m=>{m.box('#2b2d33',0.42*R,0.74*R,0,0.16*R,0.12*R,0.62*R,0,0,0.5,R*0.03);for(const z of [-1,1])m.cyl('#2b2d33',0.56*R,0.8*R,z*0.2*R,0.09*R,0.09*R,0.26*R,0,0,Math.PI/2-0.5,R*0.03);for(const z of [-1,1])m.cyl('#7dff8a',0.68*R,0.88*R,z*0.2*R,0.075*R,0.075*R,0.02*R,0,0,Math.PI/2-0.5,0,1);});
   M('h_antenna',m=>{m.rod('#55585f',[-0.25*R,0.92*R,0.35*R],[-0.32*R,1.62*R,0.42*R],0.025*R,0);m.ball('#ff3d4e',-0.32*R,1.66*R,0.42*R,0.07*R,0.07*R,0.07*R,0,0,0,0,0.8);});
   M('h_rage',m=>{m.torus('#e0443f',0,0.36*R,0,0.8*R,0.07*R,0,0,-0.08,0);m.box('#e0443f',-0.86*R,0.3*R,0.1*R,0.08*R,0.3*R,0.06*R,0,0,-0.6,0);m.box('#e0443f',-0.86*R,0.3*R,-0.1*R,0.08*R,0.3*R,0.06*R,0,0,-0.9,0);});
   M('h_clover',m=>{for(let k=0;k<4;k++){const a=k/4*TAU;m.ell('#4caf50',0.2*R+Math.cos(a)*0.08*R,1.0*R,0.4*R+Math.sin(a)*0.08*R,0.07*R,0.03*R,0.07*R,0,0,0,0,0.1);}m.rod('#2e7d32',[0.2*R,0.98*R,0.4*R],[0.26*R,0.9*R,0.46*R],0.015*R,0);});
   M('h_fangs',m=>{for(const z of [-1,1])m.cyl('#ffffff',0.88*R,-0.27*R,z*0.07*R,0.04*R,0.005*R,0.11*R,0,0,0,R*0.02,0.2);});
   M('h_shoe',m=>{m.ell('#e0443f',0.02*R,0.01*R,0,0.3*R,0.13*R,0.19*R,0,0,0,R*0.04);m.box('#ffffff',0.02*R,-0.1*R,0,0.56*R,0.05*R,0.36*R,0,0,0,0);m.box('#ffffff',0.1*R,0.1*R,0,0.16*R,0.02*R,0.14*R,0,0,0,0,0.2);},48);
   const AT={scope:(m,c)=>{m.cyl('#1d2229',0,0,0,0.1*R,0.1*R,0.55*R,0,0,Math.PI/2,R*0.03);m.cyl(c,0.29*R,0,0,0.085*R,0.085*R,0.02*R,0,0,Math.PI/2,0,0.8);m.torus(c,-0.12*R,0,0,0.105*R,0.02*R,0,0,Math.PI/2,0,0.3);},
     muzzle:(m,c)=>{m.cyl('#2b2d33',0.14*R,0,0,0.11*R,0.11*R,0.28*R,0,0,Math.PI/2,R*0.03);m.torus(c,0.06*R,0,0,0.115*R,0.025*R,0,0,Math.PI/2,0,0.5);for(const y of [-1,1])m.box('#1d2229',0.18*R,y*0.09*R,0,0.06*R,0.03*R,0.14*R,0,0,0,0);},
     drum:(m,c)=>{m.cyl(c,0,0,0,0.2*R,0.2*R,0.15*R,0,Math.PI/2,0,R*0.03,0.15);m.cyl('#2b2d33',0,0,0,0.08*R,0.08*R,0.17*R,0,Math.PI/2,0,0);},
     tank:(m,c)=>{m.cyl(c,0,0,0,0.09*R,0.09*R,0.45*R,0,0,Math.PI/2,R*0.03,0.15);for(const x of [-0.23,0.23])m.cyl('#2b2d33',x*R,0,0,0.095*R,0.095*R,0.04*R,0,0,Math.PI/2,0);},
     coil:(m,c)=>{for(const x of [0,0.14,0.28])m.torus(c,x*R,0,0,0.12*R,0.025*R,0,0,Math.PI/2,0,0.9);},
     radar:(m,c)=>{m.cyl('#2b2d33',0,-0.08*R,0,0.025*R,0.025*R,0.16*R,0,0,0,0);m.cyl(c,0,0.04*R,0,0.2*R,0.05*R,0.06*R,0,0,-0.4,R*0.02,0.25);},
     torch:(m,c)=>{m.cyl('#2b2d33',0,0,0,0.065*R,0.065*R,0.28*R,0,0,Math.PI/2,R*0.02);m.cyl(c,0.15*R,0,0,0.07*R,0.07*R,0.02*R,0,0,Math.PI/2,0,1);},
     blade:(m,c)=>{m.box(c,1.45*R,0,0,1.94*R,0.07*R,0.18*R,0,0,0,0,0.85);}};
   for(const t in AT)for(let i=0;i<3;i++)M('att_'+t+'_'+i,m=>AT[t](m,PATHC[i]),24,t!=='blade');
   M('att_torchG',m=>{m.cyl('#d9d4e2',0,0,0,0.08*R,0.08*R,0.34*R,0,0,Math.PI/2,R*0.02);m.cyl('#fff6c2',0.18*R,0,0,0.09*R,0.09*R,0.02*R,0,0,Math.PI/2,0,1);});
   M('att_ice',m=>{for(let k=0;k<5;k++){const a=k/5*TAU;m.ell('#cfefff',0.05*R,Math.cos(a)*0.1*R,Math.sin(a)*0.1*R,0.05*R,0.09*R,0.05*R,0,0,a,0,0.4);}});
   M('att_ring',m=>{m.torus('#ffcf3a',0,0,0,0.13*R,0.03*R,0,0,Math.PI/2,0,0.5);});
   M('bomb',m=>{m.ell('#2b2d33',0,0,0,4,4,4);m.torus('#e0443f',0,0,0,4.1,0.7,0,0,0,0,0.4);},40,false);
   M('smk',m=>{m.cyl('#8f939b',0,0,0,3.4,3.4,9,0,0,0,0.6,-0.2);m.torus('#5d6b3a',0,2,0,3.5,0.6,0,0,0,0);},30,false);
   M('flr',m=>{m.cyl('#e0443f',0,0,0,1.6,1.6,10,0,0,0,0.5,0.2);m.ball('#ffd166',0,6,0,2,2,2,0,0,0,0,1);},30,false);
   M('frz',m=>{m.ell('#9fe8ff',0,0,0,4.6,5.2,4.6,0,0,0,0.6,0.3);m.box('#ffffff',0,5.8,0,1.6,2.4,1.6,0,0,0,0);},30,false);
   M('icecube',m=>{m.box('#bfefff',0,12,0,30,24,30,0.4,0,0,0.8,0.25);m.box('#e8f8ff',6,22,6,8,4,8,0.4,0,0,0,0.5);},40);
   M('beacon',m=>{m.cyl('#55585f',0,14,0,1.6,1.6,28,0,0,0,0.6);m.cyl('#3a3f48',0,2,0,8,9,4,0,0,0,0.8);m.ball('#7fe3ff',0,30,0,3,3,3,0,0,0,0,1);},20);}
  const Sh=new Mdl(0.5);Sh.box('#e8c45a',0,0,0,5,2.6,2.6,0,0,0,0.5,-0.7);mkPart('shell',Sh,140,false);
  const Shr=new Mdl(0.5);Shr.box('#d8423f',0,0,0,6,3.2,3.2,0,0,0,0.5,-0.3);Shr.box('#e8c45a',-2.4,0,0,1.6,3.4,3.4,0,0,0,0,-0.5);mkPart('shell_red',Shr,60,false);
  const Shb=new Mdl(0.5);Shb.box('#e8c45a',0,0,0,8.5,3.2,3.2,0,0,0,0.5,-0.7);mkPart('shell_big',Shb,40,false);
}

// ---------- 场景 ----------
let ENV=null,BASE3={},ROOTS=[],DYN={};
function obstacle(B,s){
  if(s.kind==='wall')return;
  if(s.c){const{x,y,r,ht}=s;
    if(s.kind==='can'){B.cyl('#b9c2cc',x,ht/2,y,r,r,ht,0,0,0,2,-0.5);B.cyl('#e0443f',x,ht*0.5,y,r+0.6,r+0.6,ht*0.38,0,0,0,0,-0.2);B.torus('#9aa3ad',x,ht,y,r*0.92,2.2,0,0,0,0,-0.6);B.disc('#c9d0d8',x,ht+0.3,y,r*0.85,r*0.85);}
    else{B.cyl('#c26a3d',x,ht*0.35,y,r,r*0.78,ht*0.7,0,0,0,2,-0.1);B.torus('#a8552c',x,ht*0.7,y,r,4,0,0,0,0);B.disc('#4a3020',x,ht*0.7+0.4,y,r*0.9,r*0.9);for(let k=0;k<6;k++){const a=k/6*TAU;B.ball(k%2?'#4caf50':'#6cc04a',x+Math.cos(a)*r*0.35,ht*0.7+14,y+Math.sin(a)*r*0.35,r*0.45,8,r*0.22,-a,0,0.6,1.6);}B.ball('#7bd35a',x,ht*0.7+22,y,10,14,10);}
    return;}
  const{x,y,w,h,ht}=s,x1=x+w,z1=y+h;
  if(s.kind==='counter'){B.bx('#6e452d',x+3,y+3,x1-3,z1-3,0,ht-12);B.bx('#b8875c',x-3,y-3,x1+3,z1+3,ht-12,ht,2.2,-0.2);const long=w>h,n=Math.max(1,Math.floor((long?w:h)/120));for(let k=0;k<n;k++){const t=(k+0.5)/n;if(long)B.ball('#e8d6b5',x+w*t,ht*0.5,z1+1,4.5,4.5,4.5,0,0,0,1);else B.ball('#e8d6b5',x1+1,ht*0.5,y+h*t,4.5,4.5,4.5,0,0,0,1);}}
  else if(s.kind==='books'){const pal=['#3d6fb5','#c0392b','#2e8b57','#d4a017','#7d3c98','#e67e22'],L=3,lh=ht/L;for(let k=0;k<L;k++){const ins=k*5,c=pal[(Math.abs(Math.floor(x/7+y/11))+k*2)%pal.length];B.bx(c,x+ins,y+ins*0.6,x1-ins*0.4,z1-ins,k*lh,(k+1)*lh-1,1.8);B.bx('#f4ead8',x+ins+4,z1-ins-1,x1-ins*0.4-4,z1-ins+0.6,k*lh+3,(k+1)*lh-4,0);}}
  else if(s.kind==='box'){B.bx('#c89359',x,y,x1,z1,0,ht);if(w>h)B.bx('#e6c58a',x+3,y+h/2-6,x1-3,y+h/2+6,ht,ht+1,0);else B.bx('#e6c58a',x+w/2-6,y+3,x+w/2+6,z1-3,ht,ht+1,0);}
  else if(s.kind==='bottles'){B.bx('#c89359',x+2,y+2,x1-2,z1-2,0,10,1.2);for(let bx=x+16;bx<=x1-14;bx+=30)for(let bz=y+16;bz<=z1-14;bz+=30){B.cyl('#8cc4ea',bx,10+(ht-24)/2,bz,13,13,ht-24,0,0,0,1.6,-0.6,12);B.cyl('#ffffff',bx,10+(ht-24)*0.4,bz,13.6,13.6,10,0,0,0,0,0,12);B.cyl('#f4f7fa',bx,ht-9,bz,5.5,6.5,10,0,0,0,1,0,10);}}
}
function buildEnv(){
  const B=new Mdl(2.2);
  B.bx('#8a7f73',0,0,WW,WH,-6,0,0);
  for(let j=0;j<WH/100;j++)for(let i=0;i<WW/100;i++)B.quad((i+j)&1?'#d6cab0':'#a9bcb0',(i+0.5)*100,0.2,(j+0.5)*100,98.4,98.4,0,-0.25);
  let lk=0;for(const ln of ['top','mid','bot']){const p=LANES[ln];for(let k=0;k<p.length-1;k++){const [ax,ay]=p[k],[bx,by]=p[k+1],dx=bx-ax,dy=by-ay,L=Math.hypot(dx,dy);B.quad('#c2ab86',(ax+bx)/2,0.32+(lk++)*0.012,(ay+by)/2,L+130,150,-Math.atan2(dy,dx),-0.15);}}
  for(const tm of TEAMS){const b=BASE_POS[tm];B.disc(tm==='blue'?'#2c4f86':'#86303a',b.x,0.6,b.y,440,440);B.disc(tm==='blue'?'#3a64a8':'#a83a46',b.x,0.65,b.y,390,390);for(let k=0;k<14;k++){const a=k/14*TAU;B.ball('#f2e8d8',b.x+Math.cos(a)*415,0.8,b.y+Math.sin(a)*415,8,0.4,8,0,0,0,0);}}
  for(const c of camps){const pts=[];for(let i=0;i<10;i++){const a=i/10*TAU,rr=34+((i*37)%17);pts.push([c.x+Math.cos(a)*rr*1.3,c.y+Math.sin(a)*rr*0.9]);}B.fan(c.type==='roach'?'#2b1d17':'#2a2a33',pts,0.6);B.disc('#120b09',c.x,0.8,c.y,12,9);}
  B.disc('#3a2a20',BOSS_POS.x,0.6,BOSS_POS.y,160,135);for(let k=0;k<16;k++){const a=k/16*TAU;B.ball('#ffd23f',BOSS_POS.x+Math.cos(a)*160,2,BOSS_POS.y+Math.sin(a)*135,6,3,6,0,0,0,0.8,0.2);}
  B.disc('#3a2a20',BIGCRATE_POS.x,0.6,BIGCRATE_POS.y,90,80);
  const WC='#3a3050',WT='#5a4c70';B.bx(WC,0,0,WW,60,0,160);B.bx(WT,-1,-1,WW+1,61,160,165,0);B.bx(WC,0,60,60,WH-60,0,120);B.bx(WT,-1,59,61,WH-59,120,125,0);B.bx(WC,WW-60,60,WW,WH-60,0,120);B.bx(WT,WW-61,59,WW+1,WH-59,120,125,0);B.bx(WC,0,WH-60,WW,WH,0,24);B.bx(WT,-1,WH-61,WW+1,WH+1,24,28,0);
  for(const s of solids)obstacle(B,s);
  ENV=new Node(upload(B),mkMat());
}
function buildBase(team){
  const b=BASE_POS[team],c=TC2[team],dir=team==='blue'?1:-1,M=new Mdl(2.4);
  M.bx('#7a5a3a',-112,-92,112,92,0,8,2);M.bx('#d9c3a0',-100,-80,100,80,8,128);
  M.box(c[0],0,152,-45,212,14,106,0,-0.507,0);M.box(c[0],0,152,45,212,14,106,0,0.507,0);
  M.cyl('#3a2416',dir*101,48,0,30,30,4,0,0,Math.PI/2,1.6);M.cyl('#ffcf7a',dir*103,48,0,22,22,1,0,0,Math.PI/2,0,0.6);
  M.bx('#ffcf7a',-62,79,-22,82,66,100,0,0.9);M.bx('#ffcf7a',22,79,62,82,66,100,0,0.9);M.bx('#9a6a44',36,-36,62,-10,150,206,2);
  M.cyl(c[1],0,104,81,18,18,3,0,Math.PI/2,0,1.6,0.25);
  const root=new Node();root.p=[b.x,0,b.y];const house=root.add(new Node(upload(M),mkMat()));
  const Pm=new Mdl(1.2);Pm.cyl('#e8e8e8',0,60,0,2.5,2.5,120,0,0,0,1.2,-0.5);Pm.ball('#ffd166',0,122,0,4,4,4,0,0,0,1,0.4);
  const pole=root.add(new Node(upload(Pm),mkMat()));pole.p=[-70,160,-50];
  const Fm=new Mdl(1.2);Fm.box(c[0],18,0,0,36,22,1.5,0,0,0,1.2,0.15);Fm.box('#ffffff',18,0,1,10,10,0.3,0,0,0,0,0.3);
  const flag=pole.add(new Node(upload(Fm),mkMat()));flag.p=[2,108,0];
  const Sm=new Mdl(0,[24,16]);Sm.ell(c[2],0,0,0,1,1,1);const bubble=root.add(new Node(upload(Sm),mkMat({op:0.18,cast:false})));bubble.p=[0,40,0];bubble.s=[170,150,170];
  return{root,house,flag,bubble,team};
}
function buildDyn(){DYN.ptN=dynBuf([[0,3],[1,2],[2,4]],1800);DYN.ptA=dynBuf([[0,3],[1,2],[2,4]],1800);DYN.streak=dynBuf([[0,3],[2,4]],7000);DYN.flat=dynBuf([[0,3],[2,4]],16000);}
function build3D(){buildEnv();for(const t of TEAMS)BASE3[t]=buildBase(t);buildHamParts();buildCritterParts();buildMiscParts();buildDyn();ROOTS=[ENV,BASE3.blue.root,BASE3.red.root];}

// ---------- 骨架与姿态 ----------
function mkNode(part,p,r){const n=new Node();n.part=part||null;if(p)n.p=p.slice();if(r)n.r=r.slice();return n;}
function makeHamRig(){const R=15,root=new Node(),pivot=root.add(mkNode(null,[0,R*0.82,0]));
  const body=pivot.add(mkNode('@body')),head=pivot.add(mkNode('@head',[0.1*R,0.62*R,0]));
  const earL=head.add(mkNode('@ear',[-0.12*R,0.5*R,-0.7*R],[0,-0.5,0])),earR=head.add(mkNode('@ear',[-0.12*R,0.5*R,0.7*R],[0,0.5,0]));
  const eyes=head.add(mkNode('h_eyes',[0.68*R,0.1*R,0])),cheekL=head.add(mkNode('h_cheekL')),cheekR=head.add(mkNode('h_cheekR'));head.add(mkNode('@cap'));for(const n of ['@glasses','@nvg','@antenna','@rage','@clover','@fangs'])head.add(mkNode(n));for(const n of ['@vest','@bando','@belt','@magnet','@coilpack','@banner','@jetpack'])pivot.add(mkNode(n));
  const footL=pivot.add(mkNode('@foot',[0.22*R,-0.8*R,-0.32*R])),footR=pivot.add(mkNode('@foot',[0.22*R,-0.8*R,0.32*R])),tail=pivot.add(mkNode('@tail',[-0.74*R,-0.42*R,0]));
  const scarf1=pivot.add(mkNode(null,[-0.5*R,0.34*R,0.16*R])),scarf2=scarf1.add(mkNode(null,[-0.42*R,0,0])),gun=pivot.add(mkNode('@gun',[0.86*R,0.02*R,0.14*R])),gunx=gun.add(mkNode('@gunx',[0.8*R,0.02*R,0]));
  return{root,pivot,body,head,earL,earR,eyes,cheekL,cheekR,footL,footR,tail,scarf1,scarf2,gun,gunx};}
function makeRatRig(boss){const r=19,root=new Node(),pivot=root.add(mkNode(null,[0,r*0.9,0]));
  const body=pivot.add(mkNode('rat_body')),head=pivot.add(mkNode('rat_head',[0.5*r,0.55*r,0])),tail=pivot.add(mkNode('rat_tail',[-0.85*r,-0.5*r,0])),gun=pivot.add(mkNode('rat_gun',[0.9*r,0,0.15*r])),footL=pivot.add(mkNode('rat_foot',[0.3*r,-0.84*r,-0.38*r])),footR=pivot.add(mkNode('rat_foot',[0.3*r,-0.84*r,0.38*r]));
  if(boss)head.add(mkNode('crown',[-0.05*r,0.62*r,0]));return{root,pivot,body,head,tail,gun,footL,footR};}
function makeRoachRig(){const q=10,root=new Node(),pivot=root.add(new Node());pivot.add(mkNode('roach_body'));const ant=pivot.add(mkNode('roach_ant',[1.36*q,0.6*q,0])),legsA=pivot.add(mkNode('roach_legsA')),legsB=pivot.add(mkNode('roach_legsB'));return{root,pivot,ant,legsA,legsB};}
function poseHam(h,S){
  const R=15,k=S.vr.v/15,sq=clamp(S.sq.v,0.6,1.5),sp=Math.hypot(S.vx,S.vy),run=S.moving&&S.rollT<=0?clamp(sp/SPEED0,0,1.3):0,ph=S.walk;
  const face=S.rollT>0?Math.atan2(S.rdy,S.rdx):S.aim,ma=Math.atan2(S.vy,S.vx),f=Math.cos(ma-face),l=Math.sin(ma-face);
  h.root.p[0]=S.x;h.root.p[1]=S.z||0;h.root.p[2]=S.y;h.root.r[0]=-face;h.root.s[0]=k*sq;h.root.s[1]=k*(2-sq);h.root.s[2]=k*sq;
  h.pivot.p[1]=R*0.82+(run>0?Math.abs(Math.sin(ph))*0.16*R*run:Math.sin(time*2.4)*0.35);
  let lean=-f*run*0.17-S.kick.v*0.012+(S.hurtT>0?S.hurtT*0.7:0),side=l*run*0.12+Math.sin(ph)*0.06*run;if(S.rollT>0){lean=-S.rollA;side=0;}if(S.air){lean=-Math.min(1,S.air.t/S.air.dur)*Math.PI*2;side=0;}
  h.pivot.r[0]=0;h.pivot.r[1]=side;h.pivot.r[2]=lean;
  h.body.s[1]=1+Math.sin(time*3.1)*0.02*(1-Math.min(1,run));
  const munch=S.munchT>0?Math.sin(S.munchT*48)*0.13:0;
  h.head.p[0]=0.1*R;h.head.p[1]=0.62*R+(run>0?Math.sin(ph*2)*0.03*R*run:0);
  h.head.r[0]=(1-Math.min(1,run))*Math.sin(time*0.6+S.id)*0.1;h.head.r[2]=munch+(run>0?Math.sin(ph*2)*0.05*run:0)-(S.hurtT>0?0.22:0);
  const twL=((time*0.7+S.id)%3.7)<0.12?0.4:0,twR=((time*0.7+S.id+1.3)%4.1)<0.1?0.4:0;
  h.earL.r[2]=-0.32*run*Math.abs(Math.sin(ph))-twL;h.earR.r[2]=-0.32*run*Math.abs(Math.cos(ph))-twR;{const ek=1+0.14*((S.ab&&S.ab.ears)||0);h.earL.s[0]=h.earL.s[1]=h.earL.s[2]=ek;h.earR.s[0]=h.earR.s[1]=h.earR.s[2]=ek;}
  h.eyes.s[1]=S.hurtT>0?0.28:((time+0.4+S.id*0.7)%3.3)<0.11?0.15:1;
  const pf=clamp(S.puff.v,0,1.1),cr=R*(0.24+0.24*pf),cz=R*(0.56+0.14*pf),jig=1+Math.sin(time*20)*0.025*run;
  h.cheekL.p[0]=h.cheekR.p[0]=0.36*R;h.cheekL.p[1]=h.cheekR.p[1]=-0.26*R;h.cheekL.p[2]=-cz;h.cheekR.p[2]=cz;
  for(const c of [h.cheekL,h.cheekR]){c.s[0]=cr;c.s[1]=cr*jig;c.s[2]=cr;}
  h.footL.p[0]=0.22*R+Math.sin(ph)*0.22*R*run;h.footL.p[1]=-0.8*R+Math.max(0,Math.cos(ph))*0.17*R*run;h.footR.p[0]=0.22*R-Math.sin(ph)*0.22*R*run;h.footR.p[1]=-0.8*R+Math.max(0,-Math.cos(ph))*0.17*R*run;
  h.tail.r[0]=Math.sin(time*14)*0.5*(0.3+run);
  h.scarf1.r[0]=Math.sin(time*6.3)*0.25*(0.4+run);h.scarf1.r[2]=0.9-0.7*Math.min(1,run)+Math.sin(time*9)*0.12*run;h.scarf2.r[0]=Math.sin(time*8+1)*0.3*(0.3+run);h.scarf2.r[2]=0.35-0.3*Math.min(1,run)+Math.sin(time*11+0.5)*0.25*run;
  h.gun.vis=S.rollT<=0;h.gun.p[0]=0.86*R+S.kick.v*0.6-(S.pumpT>0&&S.pumpT<0.3?Math.sin((0.3-S.pumpT)/0.3*Math.PI)*3:0);
  let gr2=0,gr1=0;if(S.reloadT>0&&S.reloadDur){const k=1-S.reloadT/S.reloadDur;gr2=-0.6*Math.sin(Math.min(1,k*1.25)*Math.PI);gr1=0.3*Math.sin(k*Math.PI);}
  if(S.flipT>0)gr2+=0.55*(S.flipT/0.22);if(S.boltT>0&&S.boltT<0.45)gr1+=0.14*Math.sin((0.45-S.boltT)/0.45*Math.PI);h.gun.r[1]=gr1;h.gun.r[2]=gr2;if(h.gunx)h.gunx.r[1]=S.spinA||0;
  h.gun.r[0]=S.weapon&&S.weapon.id==='katana'&&S.swingT>0?S.swingDir*(1.3-2.6*(1-S.swingT/0.22)):0;
}
function poseRat(rg,e,sc){const R=19,sp=Math.hypot(e.vx,e.vy),run=clamp(sp/125,0,1.2),ph=e.walk,ma=Math.atan2(e.vy,e.vx),f=Math.cos(ma-e.aim),l=Math.sin(ma-e.aim);
  rg.root.p[0]=e.x;rg.root.p[2]=e.y;rg.root.r[0]=-e.aim;rg.root.s[0]=rg.root.s[1]=rg.root.s[2]=sc;
  rg.pivot.p[1]=R*0.9+Math.abs(Math.sin(ph))*2.6*run-(e.tele>0?2.5:0);rg.pivot.r[1]=l*run*0.12+Math.sin(ph)*0.07*run;rg.pivot.r[2]=-f*run*0.14+e.recoil*0.15+(e.flash>0?0.22:0);
  rg.head.r[0]=!e.target?Math.sin(e.t*0.8)*0.3:0;rg.head.r[2]=(run<0.2&&!e.target?Math.sin(e.t*9)*0.06:0)+(e.tele>0?-0.08:0);
  rg.tail.r[0]=Math.sin(e.t*6)*0.35;rg.tail.r[2]=0.15*run;
  rg.footL.p[0]=0.3*R+Math.sin(ph)*0.25*R*run;rg.footL.p[1]=-0.84*R+Math.max(0,Math.cos(ph))*0.15*R*run;rg.footR.p[0]=0.3*R-Math.sin(ph)*0.25*R*run;rg.footR.p[1]=-0.84*R+Math.max(0,-Math.cos(ph))*0.15*R*run;
  rg.gun.p[0]=0.9*R-e.recoil*3;rg.gun.r[2]=e.tele>0?0.06:0;}
function poseRoach(rg,e){const mv=Math.hypot(e.vx,e.vy)>15,g=Math.sin(e.t*30);rg.root.p[0]=e.x;rg.root.p[2]=e.y;rg.root.r[0]=-e.heading;
  rg.legsA.r[0]=mv?g*0.32:0;rg.legsB.r[0]=mv?-g*0.32:0;rg.legsA.p[1]=mv?Math.max(0,g)*1.2:0;rg.legsB.p[1]=mv?Math.max(0,-g)*1.2:0;rg.ant.r[0]=Math.sin(e.t*7)*0.18;rg.ant.r[2]=Math.sin(e.t*5.3)*0.12;rg.pivot.p[1]=mv?Math.abs(g)*0.7:0;rg.pivot.r[1]=mv?g*0.05:0;}
function pushNode(n,h,e0,e1,e2){if(!n.vis)return;if(n.part){let nm=n.part;if(nm.charCodeAt(0)===64){const sk=h.skin||'gold';nm=nm==='@body'?'h_body_'+sk:nm==='@head'?'h_head_'+sk:nm==='@ear'?'h_ear_'+sk:nm==='@tail'?'h_tail_'+sk:nm==='@cap'?'h_cap_'+h.team:nm==='@foot'?((h.ab&&h.ab.speed)?'h_shoe':'h_foot'):nm==='@glasses'?(h.ab&&h.ab.scholar?'h_glasses':''):nm==='@nvg'?(h.ab&&h.ab.nvg?'h_nvg':''):nm==='@antenna'?(h.ab&&h.ab.recon?'h_antenna':''):nm==='@rage'?(h.ab&&h.ab.rage?'h_rage':''):nm==='@clover'?(h.ab&&h.ab.crit?'h_clover':''):nm==='@fangs'?(h.ab&&h.ab.vamp?'h_fangs':''):nm==='@vest'?(h.ab&&h.ab.armor?'h_vest':''):nm==='@bando'?(h.ab&&h.ab.scav?'h_bando':''):nm==='@belt'?(h.ab&&h.ab.gcd?'h_belt':''):nm==='@magnet'?(h.ab&&h.ab.magnet?'h_magnet':''):nm==='@coilpack'?(h.ab&&h.ab.chain?'h_coilpack':''):nm==='@banner'?(h.ab&&h.ab.banner?'h_banner_'+h.team:''):nm==='@jetpack'?(h.gadget&&h.gadget.id==='jetpack'?'h_jetpack':''):nm==='@gunx'?'w_'+h.weapon.id+'_x':nm==='@gun'?'w_'+h.weapon.id:'';}instPush(PARTS[nm],n.W,e0,e1,e2);}for(const c of n.ch)pushNode(c,h,e0,e1,e2);}

// ---------- 视图与相机 ----------
function mkView(h){const v={ham:h,camX:h?h.x:MIDX,camY:h?h.y:MIDY,ckx:0,cky:0,shx:0,shz:0,trauma:0,pulse:0,rect:{x:0,y:0,w:W,h:H},VP:new Float32Array(16),VPinv:new Float32Array(16),cp:new Float32Array(3),V:{hw:420,zn:260,zs:240},toastQ:[],toastCur:null,cardRects:[]};if(h)h.view=v;return v;}
function layoutViews(){if(VIEWS.length<=1){if(VIEWS[0])VIEWS[0].rect={x:0,y:0,w:W,h:H};}else{VIEWS[0].rect={x:0,y:0,w:W/2,h:H};VIEWS[1].rect={x:W/2,y:0,w:W/2,h:H};}}
function setCamera(v){
  const r=v.rect,asp=Math.max(0.3,r.w/Math.max(1,r.h)),tf=Math.tan(FOV/2);
  camDist=asp>=1?clamp(430*Math.sin(PITCH)/(2*tf),360,1500):clamp(420/(2*tf*asp),360,1700);
  const tx=v.camX+v.ckx+v.shx,tz=v.camY+v.cky+v.shz,h=camDist*Math.sin(PITCH),back=camDist*Math.cos(PITCH);
  camPos[0]=tx;camPos[1]=h;camPos[2]=tz+back;
  m4look(Vm,camPos,[tx,0,tz],[0,1,0]);m4persp(Pm,FOV,asp,20,5000);m4mul(VPm,Pm,Vm);m4inv(VPinv,VPm);v.VP.set(VPm);v.VPinv.set(VPinv);v.cp.set(camPos);
  v.V.hw=camDist*tf*asp;v.V.zn=h/Math.tan(PITCH-FOV/2)-back;v.V.zs=back-h/Math.tan(PITCH+FOV/2);
  const S=Math.max(v.V.hw,(v.V.zn+v.V.zs)/2)+220,cx=tx,cz=tz-(v.V.zn-v.V.zs)/2;
  m4look(LV,[WW/2+LDIR[0]*5000,LDIR[1]*5000,WH/2+LDIR[2]*5000],[WW/2,0,WH/2],[0,1,0]);
  const lx=LV[0]*cx+LV[8]*cz+LV[12],ly=LV[1]*cx+LV[9]*cz+LV[13],tex=2*S/SS,sx=Math.round(lx/tex)*tex,sy=Math.round(ly/tex)*tex;
  m4ortho(LP,sx-S,sx+S,sy-S,sy+S,1500,9500);m4mul(LVP,LP,LV);
}
function projV(v,x,h,z){const m=v.VP,w=m[3]*x+m[7]*h+m[11]*z+m[15];const px=(m[0]*x+m[4]*h+m[8]*z+m[12])/w,py=(m[1]*x+m[5]*h+m[9]*z+m[13])/w,r=v.rect;return{x:r.x+(px+1)*0.5*r.w,y:r.y+(1-py)*0.5*r.h,ok:w>0};}
function screenToGroundV(v,sx,sy,h){const r=v.rect,nx=(sx-r.x)/r.w*2-1,ny=1-(sy-r.y)/r.h*2,m=v.VPinv;
  const un=(z)=>{const x=m[0]*nx+m[4]*ny+m[8]*z+m[12],y=m[1]*nx+m[5]*ny+m[9]*z+m[13],zz=m[2]*nx+m[6]*ny+m[10]*z+m[14],w=m[3]*nx+m[7]*ny+m[11]*z+m[15];return[x/w,y/w,zz/w];};
  const a=un(-1),b=un(1),t=(h-a[1])/((b[1]-a[1])||1e-6);return{x:a[0]+(b[0]-a[0])*t,z:a[2]+(b[2]-a[2])*t};}
function waveScreen(){let best=VIEWS[0],bd=1e18;for(const v of VIEWS){const h=v.ham,d=h?d2(h.x,h.y,wave.x,wave.y):d2(v.camX,v.camY,wave.x,wave.y);if(d<bd){bd=d;best=v;}}return projV(best,wave.x,wave.h,wave.y);}
function clampView(v){const V=v.V;v.camX=2*V.hw-120>WW?WW/2:clamp(v.camX,V.hw-60,WW-V.hw+60);v.camY=V.zn+V.zs-200>WH?WH/2:clamp(v.camY,V.zn-140,WH-V.zs+20);}
function updCams(dt){for(const v of VIEWS){const h=v.ham;if(!h)continue;let tx,ty;
  if(h.alive){tx=h.x;ty=h.y-(h.z||0)*0.6;if(h.dev==='kbm'&&mouse.has){tx+=clamp((h.mwx-h.x)*0.22,-120,120);ty+=clamp((h.mwy-h.y)*0.22,-90,90);}else{tx+=Math.cos(h.aim)*50;ty+=Math.sin(h.aim)*50;}}
  else{const b=BASE_POS[h.team];tx=b.x+(h.team==='blue'?220:-220);ty=b.y;}
  v.camX=damp(v.camX,tx,h.alive?7:3,dt);v.camY=damp(v.camY,ty,h.alive?7:3,dt);clampView(v);
  v.trauma=Math.max(0,v.trauma-dt*1.7);v.ckx=damp(v.ckx,0,14,dt);v.cky=damp(v.cky,0,14,dt);v.pulse=Math.max(0,v.pulse-dt*2.5);v.hitT=Math.max(0,(v.hitT||0)-dt);v.flashT=Math.max(0,(v.flashT||0)-dt);}}

// ---------- 实例同步 ----------
const _M2=new Float32Array(16),_M3=new Float32Array(16),PATHC_RGB=PATHC.map(hexRGB);
function pushAtt(h){const g=h.rig&&h.rig.gun;if(!g||!g.vis)return;const id=h.weapon.id,ty=EVV[id],R=15,mz=(MUZ[id]||2)*R;let kb=-1,kl=0;
  for(let i=0;i<3;i++){const lv=eL(h,PK[i]);if(lv<3)continue;const t=ty[i];if(t==='blade'){if(lv>kl){kl=lv;kb=i;}continue;}const sc=lv>=9?1.2:lv>=6?1:0.8,em=lv>=9?0.5:0;let px=0,py=0,pz=0;
    if(t==='scope'){px=mz*0.45;py=0.32*R;}else if(t==='muzzle'){px=mz;py=0.04*R;}else if(t==='drum'){px=0.4*R;py=-0.32*R;}else if(t==='tank'){px=0.15*R;py=0.06*R;pz=-0.3*R;}else if(t==='coil'){px=mz*0.55;py=0.04*R;}else if(t==='radar'){px=0.05*R;py=0.36*R;}else{px=mz*0.62;py=-0.14*R;pz=0.12*R;}
    m4trs(_M2,px,py,pz,0,0,0,sc,sc,sc);m4mul(_M3,g.W,_M2);const c=PATHC_RGB[i];instPush(PARTS['att_'+t+'_'+i],_M3,c[0]*em,c[1]*em,c[2]*em);}
  if(kb>=0){const c=PATHC_RGB[kb],em=kl>=9?0.9:kl>=6?0.5:0.25;m4trs(_M2,0,0,0,0,0,0,1,1,1);m4mul(_M3,g.W,_M2);instPush(PARTS['att_blade_'+kb],_M3,c[0]*em,c[1]*em,c[2]*em);}
  if(h.ab.torch||h.ab.wide){const sc=1+0.15*((h.ab.torch||0)+(h.ab.wide||0));m4trs(_M2,mz*0.62,-0.14*R,-0.12*R,0,0,0,sc,sc,sc);m4mul(_M3,g.W,_M2);instPush(PARTS.att_torchG,_M3,0,0,0);}
  if(h.ab.frost){m4trs(_M2,mz,0.04*R,0,0,0,0,1,1,1);m4mul(_M3,g.W,_M2);instPush(PARTS.att_ice,_M3,0.1,0.2,0.3);}
  if(h.ab.rate){m4trs(_M2,mz*0.4,0.04*R,0,0,0,0,1,1,1);m4mul(_M3,g.W,_M2);instPush(PARTS.att_ring,_M3,0.3,0.22,0.05);}}
function syncInst(v){const T0=v&&v.ham?v.ham.team:null,me=v&&v.ham,see=e=>!T0||e.team===T0||VIS[T0].has(e);
  for(const o of PART_LIST)o.count=0;
  for(const h of hams){if(!h.alive||(h!==me&&!see(h)))continue;if(!h.rig)h.rig=makeHamRig();poseHam(h.rig,h);h.rig.root.upd(null);const f=((h.flash>0||h.hurtT>0.24)?0.6:(h.iframes>0&&h.rollT<=0)?0.12+0.1*Math.sin(time*30):0)+(T0&&h.team===T0?0.06:0);pushNode(h.rig.root,h,f,f,f);pushAtt(h);if(h.frozenUntil>G.t){m4trs(_M,h.x,0,h.y,0,0,0,h.r/14,h.r/14,h.r/14);instPush(PARTS.icecube,_M,0.1,0.15,0.2);}if(h.beacon&&(!T0||h.team===T0)){m4trs(_M,h.beacon.x,0,h.beacon.y,0,0,0,1,1,1);instPush(PARTS.beacon,_M,0,0,0);}}
  for(const d of decoys){if(d.dead||!see(d))continue;if(!d.rig)d.rig=makeHamRig();d.walk+=0.02;poseHam(d.rig,d);d.rig.root.p[1]=2+Math.sin(time*3+d.id)*2;d.rig.root.upd(null);const f=d.flash>0?0.6:0.12;pushNode(d.rig.root,d,f,f,f+0.08);}
  for(const L of [minions,mobs])for(const e of L)if(!e.dead&&e.frozenUntil>G.t&&see(e)){const k=e.r/14;m4trs(_M,e.x,0,e.y,0,0,0,k,k,k);instPush(PARTS.icecube,_M,0.1,0.15,0.2);}
  for(const m of minions){if(m.dead||!see(m))continue;const f=m.flash>0?0.7:0;m4trs(_M,m.x,Math.abs(Math.sin(m.walk))*2,m.y,-m.aim,0,Math.sin(m.walk)*0.08,1,1,1);instPush(PARTS['min_'+m.team],_M,f,f,f);}
  for(const e of mobs){if(e.dead||!see(e))continue;const f=e.flash>0?0.7:0;
    if(e.kind==='roach'){if(!e.rig)e.rig=makeRoachRig();poseRoach(e.rig,e);e.rig.root.upd(null);pushNode(e.rig.root,null,f,f,f);}
    else{if(!e.rig)e.rig=makeRatRig(e.kind==='boss');poseRat(e.rig,e,e.kind==='boss'?2.4:1);e.rig.root.upd(null);const te=e.tele>0?0.3+0.3*Math.sin(time*40):0;pushNode(e.rig.root,null,f+te,f,f+te*0.2);}}
  for(const p of pets){if(p.dead||!(p.owner===me||see(p.owner)))continue;if(p.px===undefined){p.px=p.x;p.py=p.y;p.hd=0;}if(p.x!==p.px||p.y!==p.py){p.hd=Math.atan2(p.y-p.py,p.x-p.px);p.px=p.x;p.py=p.y;}if(p.type==='firefly')m4trs(_M,p.x,p.h,p.y,-p.hd,0,Math.sin(p.t*20)*0.2,1,1,1);else m4trs(_M,p.x,p.type==='chick'?Math.abs(Math.sin(p.t*14))*3:0,p.y,-p.aim,0,0,1,1,1);instPush(PARTS['pet_'+p.type],_M,0,0,0);}
  for(const s of structs){if(s.dead||s.kind==='base')continue;if(s.kind==='sentry'){if(!see(s))continue;const f=s.flash>0?0.5:0;m4trs(_M,s.x,0,s.y,0,0,0,1,1,1);instPush(PARTS['sentry_base_'+s.team],_M,f,f,f);m4trs(_M,s.x,20,s.y,-s.aim,0,0,1,1,1);instPush(PARTS['sentry_head_'+s.team],_M,f,f,f);continue;}const f=s.flash>0?0.5:0;m4trs(_M,s.x,0,s.y,0,0,0,1,1,1);instPush(PARTS['tur_base_'+s.team],_M,f,f,f);m4trs(_M,s.x,50,s.y,-s.aim,0,0,1,1,1);instPush(PARTS['tur_head_'+s.team],_M,f,f,f);}
  for(const c of crates){if(c.dead)continue;const f=c.flash>0?0.6:0,k=1+(c.flash>0?0.06:0);m4trs(_M,c.x,0,c.y,(c.x*0.013+c.y*0.007)%TAU,0,0,k,k,k);instPush(PARTS[c.big?'crate_big':'crate'],_M,f,f,f);}
  for(const g of gems){m4trs(_M,g.x,g.z+6+1.5*Math.sin(time*3+g.ph),g.y,time*2.4+g.ph,0,0.5,1,1,1);instPush(PARTS[g.big?'gem_big':'gem'],_M,0,0,0);}
  for(const b of lobs){m4trs(_M,b.x,b.z+4,b.y,b.rot,b.rot*0.7,0,1,1,1);instPush(PARTS[b.kind],_M,0,0,0);}
  for(const p of props){if(p.dead)continue;const f=p.flash>0?0.5:0;m4trs(_M,p.x,0,p.y,p.kind==='box'?0:p.rot,0,0,1,1,1);if(p.kind==='lamp'){instPush(PARTS.lamp_base,_M,f,f,f);instPush(PARTS.lamp_bulb,_M,0,0,0);}else instPush(PARTS[p.kind==='box'?'pbox':'barrel'],_M,f,f,f);}
  for(const p of padSpots){const yaw=Math.atan2(p.ty-p.y,p.tx-p.x),sq=1-0.45*(p.anim/0.35);m4trs(_M,p.x,0,p.y,-yaw,0,0,1,sq,1);instPush(PARTS.pad,_M,0,0,0);}
  for(const m of mines){if(!see(m))continue;const bl=m.arm<=0&&(time*2+m.x*0.01)%1<0.15?0.9:0;m4trs(_M,m.x,0,m.y,0,0,0,1,1,1);instPush(PARTS.mine,_M,bl,0,0);}
  for(const p of pickups){m4trs(_M,p.x,p.z+4+1.5*Math.sin(time*3+p.ph),p.y,time*1.8+p.ph,0,0,1,1,1);instPush(PARTS.cheese,_M,0,0,0);}
  for(const b of bullets){const o=PARTS[b.kind];if(!o)continue;const a=-Math.atan2(b.vy,b.vx),st=b.kind==='snipe'||b.kind==='rocket'||b.kind==='spike'?1:1.6;m4trs(_M,b.x,b.h,b.y,a,0,b.kind==='rocket'?b.rot*2:0,st,1,1);instPush(o,_M,0,0,0);}
  for(const s of shells){m4trs(_M,s.x,s.z+1.3,s.y,s.rot,0,s.rot*0.6,1,1,1);instPush(PARTS[s.type==='red'?'shell_red':s.type==='big'?'shell_big':'shell'],_M,0,0,0);}
  for(const o of PART_LIST)instFlush(o);
  for(const t of TEAMS){const B=BASE3[t],s=structs.find(q=>q.kind==='base'&&q.team===t);B.root.vis=!!s&&!s.dead;if(!s)continue;B.flag.r[0]=Math.sin(time*3+(t==='red'?1:0))*0.25;B.bubble.vis=s.shielded;const f=s.flash>0?0.4:0;B.house.mat.em[0]=B.house.mat.em[1]=B.house.mat.em[2]=f;}
}
// ---------- 动态几何 ----------
const RGBC={};const rgbOf=c=>RGBC[c]||(RGBC[c]=hexRGB(c));
const HCACHE={};const hdrOf=(c,k)=>{const key=c+k;return HCACHE[key]||(HCACHE[key]=hexRGB(c).map(v=>v*k));};
function pushPt(o,x,y,z,size,shape,c,a){if(o.n>=o.max)return;const d=o.data,i=o.n*9;d[i]=x;d[i+1]=y;d[i+2]=z;d[i+3]=size;d[i+4]=shape;d[i+5]=c[0];d[i+6]=c[1];d[i+7]=c[2];d[i+8]=a;o.n++;}
function pushV(o,x,y,z,c,a){if(o.n>=o.max)return;const d=o.data,i=o.n*7;d[i]=x;d[i+1]=y;d[i+2]=z;d[i+3]=c[0];d[i+4]=c[1];d[i+5]=c[2];d[i+6]=a;o.n++;}
function pushTri(o,a,b,c,ca,cb,cc,aa,ab,ac){if(o.n+3>o.max)return;pushV(o,a[0],a[1],a[2],ca,aa);pushV(o,b[0],b[1],b[2],cb,ab);pushV(o,c[0],c[1],c[2],cc,ac);}
function pushStreak(o,x0,y0,z0,x1,y1,z1,w,c,a0,a1){
  if(o.n+6>o.max)return;let dx=x1-x0,dy=y1-y0,dz=z1-z0;const vx=camPos[0]-x0,vy=camPos[1]-y0,vz=camPos[2]-z0;
  let sx=dy*vz-dz*vy,sy=dz*vx-dx*vz,sz=dx*vy-dy*vx;const l=Math.hypot(sx,sy,sz)||1;sx=sx/l*w;sy=sy/l*w;sz=sz/l*w;
  pushV(o,x0+sx,y0+sy,z0+sz,c,a0);pushV(o,x0-sx,y0-sy,z0-sz,c,a0);pushV(o,x1-sx,y1-sy,z1-sz,c,a1);pushV(o,x0+sx,y0+sy,z0+sz,c,a0);pushV(o,x1-sx,y1-sy,z1-sz,c,a1);pushV(o,x1+sx,y1+sy,z1+sz,c,a1);}
function pushEll(o,x,y,z,rx,rz,rot,c,a,seg=14){const cr=Math.cos(rot),sr=Math.sin(rot);for(let i=0;i<seg;i++){const a0=i/seg*TAU,a1=(i+1)/seg*TAU,p=(t)=>{const u=Math.cos(t)*rx,v=Math.sin(t)*rz;return[x+u*cr-v*sr,z+u*sr+v*cr];},p0=p(a0),p1=p(a1);pushV(o,x,y,z,c,a);pushV(o,p0[0],y,p0[1],c,a);pushV(o,p1[0],y,p1[1],c,a);}}
const C_BLOB=[0.012,0.008,0.025];
function pushBlob(o,x,y,z,rx,rz,a,seg=14){for(let i=0;i<seg;i++){const a0=i/seg*TAU,a1=(i+1)/seg*TAU;pushV(o,x,y,z,C_BLOB,a);pushV(o,x+Math.cos(a0)*rx,y,z+Math.sin(a0)*rz,C_BLOB,0);pushV(o,x+Math.cos(a1)*rx,y,z+Math.sin(a1)*rz,C_BLOB,0);}}
function pushGlow(o,x,y,z,r,c,a,seg=20){for(let i=0;i<seg;i++){const a0=i/seg*TAU,a1=(i+1)/seg*TAU;pushV(o,x,y,z,c,a);pushV(o,x+Math.cos(a0)*r,y,z+Math.sin(a0)*r,c,0);pushV(o,x+Math.cos(a1)*r,y,z+Math.sin(a1)*r,c,0);}}
function pushRing(o,x,y,z,r,w,c,a,seg=32,dash=false){for(let i=0;i<seg;i++){if(dash&&i%2)continue;const a0=i/seg*TAU,a1=(i+1)/seg*TAU,c0=Math.cos(a0),s0=Math.sin(a0),c1=Math.cos(a1),s1=Math.sin(a1),ri=Math.max(0,r-w);
  pushV(o,x+c0*ri,y,z+s0*ri,c,a*0.25);pushV(o,x+c0*r,y,z+s0*r,c,a);pushV(o,x+c1*r,y,z+s1*r,c,a);pushV(o,x+c0*ri,y,z+s0*ri,c,a*0.25);pushV(o,x+c1*r,y,z+s1*r,c,a);pushV(o,x+c1*ri,y,z+s1*ri,c,a*0.25);}}
const C_FL_IN=[4.2,3.6,2.4],C_FL_OUT=[2.8,1.1,0.3];
function pushStar(o,x,y,z,size,rot,a,pts){const rx=Vm[0],ry=Vm[4],rz=Vm[8],ux=Vm[1],uy=Vm[5],uz=Vm[9],n=pts*2;const P_=(an,r)=>[x+(rx*Math.cos(an)+ux*Math.sin(an))*r,y+(ry*Math.cos(an)+uy*Math.sin(an))*r,z+(rz*Math.cos(an)+uz*Math.sin(an))*r];
  for(let i=0;i<n;i++){const a0=rot+i/n*TAU,a1=rot+(i+1)/n*TAU,r0=(i%2?0.32:1)*size,r1=((i+1)%2?0.32:1)*size;pushTri(o,[x,y,z],P_(a0,r0),P_(a1,r1),C_FL_IN,C_FL_OUT,C_FL_OUT,a,0,0);}}
function pushCone(o,x,y,z,dir,len,wid,a){const px=-Math.sin(dir),pz=Math.cos(dir);for(const k of [-1,0,1]){const an=dir+k*0.45,L=len*(k?0.5:1),tip=[x+Math.cos(an)*L,y,z+Math.sin(an)*L];pushTri(o,[x+px*wid*0.5,y,z+pz*wid*0.5],tip,[x-px*wid*0.5,y,z-pz*wid*0.5],C_FL_IN,C_FL_OUT,C_FL_IN,a,0,a);}}
const C_FIRE_A=[3.2,2.2,0.9],C_FIRE_B=[2.5,0.75,0.16],C_GLOW=[1.6,2.0,0.7],C_EM=[3.0,1.2,0.3],C_LASER=[3.4,0.18,0.35],C_MOTE=[1.5,1.35,1.05],C_LAMP=[1.25,0.9,0.5],C_ZAP=[1.2,2.6,3.4],C_SLASH=[2.4,2.9,3.4];
const BCOL={pea_b:[0.8,1.9,3.2],pea_r:[3.2,0.8,1.2],pel_b:[2.2,2.6,3.4],pel_r:[3.4,2.4,1.2],trc_b:[2.0,2.6,3.6],trc_r:[3.6,2.3,1.0],mpea_b:[0.6,1.4,2.6],mpea_r:[2.6,0.6,0.9],seed_b:[0.7,1.6,3.4],seed_r:[3.4,0.7,0.9],orb:[3.2,0.8,2.6],rat:[3.4,0.35,0.8],snipe:[1.6,3.2,3.6],spike:[1.2,0.9,0.6]};
const MOTES=[];for(let i=0;i<110;i++)MOTES.push({x:-9999,y:0,h:0,ph:Math.random()*TAU,sz:1.6+Math.random()*2.2,v:i%2});
function syncDyn(dt,v){const T0=v&&v.ham?v.ham.team:null,me=v&&v.ham,see=e=>!T0||e.team===T0||VIS[T0].has(e),vi=Math.max(0,VIEWS.indexOf(v));
  const N=DYN.ptN,A=DYN.ptA,S=DYN.streak,F=DYN.flat;N.n=A.n=S.n=F.n=0;
  let dy=0.5;
  for(const d of decals){const a=Math.min(1,d.life/d.max*2);dy+=0.01;if(d.type==='splat'){const c=rgbOf('#4a2a10');pushEll(F,d.x,dy,d.y,d.r,d.r*0.62,d.rot,c,0.6*a);}else if(d.type==='scorch')pushEll(F,d.x,dy,d.y,d.r,d.r*0.7,d.rot,rgbOf('#120a0c'),0.5*a);else pushEll(F,d.x,dy,d.y,d.r,d.r*0.5,d.rot,rgbOf('#5f5a68'),0.35*a);}
  for(const h of hams)if(h.alive&&(h===me||see(h))){pushBlob(F,h.x,0.42,h.y,h.r*1.5,h.r*1.2,0.45);pushRing(F,h.x,0.9,h.y,h.r*1.55,2.4,rgbOf(TCOL[h.team]),h.ctl==='ai'?0.55:0.95,28);}
  for(const m of minions)if(!m.dead&&see(m))pushBlob(F,m.x,0.42,m.y,m.r*1.4,m.r*1.1,0.4);
  for(const e of mobs)if(!e.dead&&see(e))pushBlob(F,e.x,0.42,e.y,e.r*1.4,e.r*1.1,0.42);
  for(const c of crates)if(!c.dead)pushBlob(F,c.x,0.42,c.y,c.r*1.3,c.r,0.32);
  for(const s of structs)if(!s.dead&&s.kind==='turret')pushBlob(F,s.x,0.42,s.y,46,40,0.4);
  for(const r of rings)pushRing(S,r.x,r.h+0.8,r.y,r.r,5,hdrOf(r.col,2),r.life/r.max);
  for(const p of parts){const k=p.life/p.max;
    switch(p.type){
      case'spark':pushStreak(S,p.x,p.h,p.y,p.x-p.vx*0.03,p.h-p.vh*0.03,p.y-p.vy*0.03,(p.size||1.4)*0.9,hdrOf(p.col,2.4),k,0);break;
      case'ember':pushStreak(S,p.x,p.h,p.y,p.x-p.vx*0.04,p.h-p.vh*0.04,p.y-p.vy*0.04,1.3,C_EM,Math.min(1,k*1.5),0);break;
      case'fire':pushPt(A,p.x,p.h,p.y,p.size*(0.55+0.45*k),2,k>0.5?C_FIRE_A:C_FIRE_B,Math.min(1,k*1.6));break;
      case'flash':{const fa=Math.min(1,k*1.5);pushStar(S,p.x,p.h,p.y,p.size*(0.7+0.6*k),p.rot||0,fa,p.star?4:6);if(!p.star&&p.dir!==undefined)pushCone(S,p.x,p.h,p.y,p.dir,p.size*(p.cone||2.5),p.size*0.9,fa);pushPt(A,p.x,p.h,p.y,p.size*3,2,hdrOf(p.col,1.5),0.55*k);break;}
      case'smoke':pushPt(N,p.x,p.h,p.y,p.size,2,rgbOf(p.col),k*0.5);break;
      case'star':if(p.glow)pushPt(A,p.x,p.h,p.y,p.size,1,hdrOf(p.col,2.6),Math.min(1,k*2));else pushPt(N,p.x,p.h,p.y,p.size,1,hdrOf(p.col,1.3),Math.min(1,k*2));break;
      default:pushPt(N,p.x,p.h,p.y,p.size,0,rgbOf(p.col),Math.min(1,k*2));}}
  for(const g of gems)pushPt(A,g.x,g.z+6,g.y,g.big?30:18,2,C_GLOW,0.16+0.07*Math.sin(time*4+g.ph));
  for(const b of bullets){const c=BCOL[b.kind];
    if(b.kind==='flame'||b.kind==='rocket')continue;if(!c)continue;
    const len=b.kind==='snipe'?0.07:b.kind.startsWith('seed')||b.kind==='orb'||b.kind==='rat'?0.06:0.045;pushStreak(S,b.x,b.h,b.y,b.x-b.vx*len,b.h,b.y-b.vy*len,b.kind==='snipe'?2.2:b.kind.startsWith('seed')?3.4:2.2,c,0.9,0);
    if(b.kind!=='spike')pushPt(A,b.x,b.h,b.y,b.kind.startsWith('seed')?30:b.kind==='orb'?28:b.kind.startsWith('m')||b.kind.startsWith('pel')?12:18,2,c,0.6);}
  for(const s of slashes){const k=s.t/s.life,a0=s.a-s.arc/2,seg=14,al=(1-k);for(let i=0;i<seg;i++){const t0=i/seg,t1=(i+1)/seg,q0=a0+s.arc*(s.dir>0?t0:1-t0),q1=a0+s.arc*(s.dir>0?t1:1-t1),r0=s.reach*0.45,r1=s.reach*(1+0.1*k),w0=Math.sin(t0*Math.PI),w1=Math.sin(t1*Math.PI);
      pushTri(S,[s.x+Math.cos(q0)*r0,s.h,s.y+Math.sin(q0)*r0],[s.x+Math.cos(q0)*r1,s.h,s.y+Math.sin(q0)*r1],[s.x+Math.cos(q1)*r1,s.h,s.y+Math.sin(q1)*r1],C_SLASH,C_SLASH,C_SLASH,0,al*w0*0.8,al*w1*0.8);
      pushTri(S,[s.x+Math.cos(q0)*r0,s.h,s.y+Math.sin(q0)*r0],[s.x+Math.cos(q1)*r1,s.h,s.y+Math.sin(q1)*r1],[s.x+Math.cos(q1)*r0,s.h,s.y+Math.sin(q1)*r0],C_SLASH,C_SLASH,C_SLASH,0,al*w1*0.8,0);}}
  for(const z of zaps){const a=1-z.t/z.life;let px=z.x0,py=z.h0,pz=z.y0;for(let i=1;i<=5;i++){const t=i/5,j=i<5?1:0,nx=lerp(z.x0,z.x1,t)+rand(-9,9)*j,ny=lerp(z.h0,z.h1,t)+rand(-6,6)*j,nz=lerp(z.y0,z.y1,t)+rand(-9,9)*j;pushStreak(S,px,py,pz,nx,ny,nz,1.6,C_ZAP,a,a);px=nx;py=ny;pz=nz;}pushPt(A,z.x1,z.h1,z.y1,20,2,C_ZAP,a*0.8);}
  for(const b of lobs){pushBlob(F,b.x,0.45,b.y,8,6,0.35);if(b.kind==='flsh')pushPt(A,b.x,b.z+6,b.y,10,2,[2.4,2.6,3],0.5);}
  for(const p of props)if(p.kind==='lamp'&&!p.dead){pushGlow(S,p.x,1.1,p.y,250,[0.55,0.42,0.24],0.32);pushPt(A,p.x,58,p.y,34,2,[3,2.4,1.4],0.85);}
  for(const p of padSpots)pushRing(S,p.x,1.3,p.y,32+3*Math.sin(time*5),3,[2.6,2.0,0.6],0.55,24);
  for(const m of mines)if(m.arm<=0&&see(m)&&(time*2+m.x*0.01)%1<0.15)pushPt(A,m.x,6,m.y,16,2,[3,0.4,0.5],0.9);
  for(const h of hams){if(!h.alive)continue;
    for(const b of (h.beams||(h.beam?[h.beam]:[]))){if(time-b.t>=0.15)continue;const c=h.team==='blue'?[1.2,2.6,3.6]:[3.6,0.9,2.0],w=b.side?0.6:1;pushStreak(S,b.x0,b.h,b.y0,b.x1,b.h,b.y1,4.5*w,c,0.4,0.4);pushStreak(S,b.x0,b.h,b.y0,b.x1,b.h,b.y1,1.4*w,[3.2,3.2,3.4],0.95,0.95);pushPt(A,b.x1,b.h,b.y1,b.hit?28*w:14,2,c,0.9);if(!b.side)pushPt(A,b.x0,b.h,b.y0,16,2,c,0.8);}
    if(see(h)||h===me){if(h.eshieldT>0){const k=Math.min(1,h.eshieldT);pushRing(S,h.x,h.r*0.9,h.y,h.r*1.9,3,[1.2,2.6,3.4],0.55*k,30);for(let j=0;j<6;j++){const an=time*1.5+j/6*TAU;pushPt(A,h.x+Math.cos(an)*h.r*1.9,h.r*(0.9+0.5*Math.sin(an*2)),h.y+Math.sin(an)*h.r*1.9,9,1,[1.2,2.6,3.4],0.7*k);}}
      if(h.st.aura>0)pushRing(S,h.x,1.2,h.y,220,3,[0.6,2.2,0.9],0.18,48,true);
      if(h.rollT>0&&h.ab.dash)for(let j=1;j<=3;j++)pushPt(A,h.x-h.rdx*16*j,h.r,h.y-h.rdy*16*j,22-j*4,2,hdrOf(TCOL[h.team],1.6),0.35-j*0.08);}
    if(h.charge>0){const c=Math.cos(h.aim),s=Math.sin(h.aim);pushPt(A,h.x+c*h.r*2.4,h.r,h.y+s*h.r*2.4,10+30*h.charge,2,[1.4,2.8,3.6],0.5+0.5*h.charge);}}
  for(const b of bullets){if(b.kind!=='swave')continue;const an=Math.atan2(b.vy,b.vx),rr=b.r*1.3,c=b.col==='#ff9ff0'?[3.4,1.6,3.0]:[2.2,1.8,3.4];let px=b.x+Math.cos(an-1.1)*rr*0.6,pz=b.y+Math.sin(an-1.1)*rr*0.6;for(let j=1;j<=8;j++){const q=an-1.1+2.2*j/8,bend=0.6+0.4*Math.sin(j/8*Math.PI),nx=b.x+Math.cos(q)*rr*bend,nz=b.y+Math.sin(q)*rr*bend;pushStreak(S,px,b.h,pz,nx,b.h,nz,2.2*(b.wr||1),c,0.9,0.9);px=nx;pz=nz;}pushPt(A,b.x,b.h,b.y,b.r*2.2,2,c,0.35);}
  for(const f of flares){pushPt(A,f.x,f.h,f.y,44,2,[3.4,1.6,1.0],0.9);pushGlow(S,f.x,1.2,f.y,320,[0.5,0.25,0.15],0.28);}
  for(const h of hams)if(h.beacon&&(!T0||h.team===T0))pushRing(S,h.beacon.x,1.3,h.beacon.y,22+6*Math.sin(time*5),3,[1.2,2.6,3.4],0.6,20);
  for(const r of beams){const k=r.t/r.life,c=r.col==='blue'?[1.4,2.8,3.6]:[3.6,1.2,2.2];pushStreak(S,r.x0,r.h,r.y0,r.x1,r.h,r.y1,r.w*(1+k*1.5),c,(1-k)*0.7,(1-k)*0.5);pushStreak(S,r.x0,r.h,r.y0,r.x1,r.h,r.y1,r.w*0.35,[3.4,3.4,3.6],1-k,(1-k)*0.8);}
  for(const t of trails){const k=t.t/t.life,a=(1-k)*0.4;pushStreak(F,t.x0,t.h+k*6,t.y0,t.x1,t.h+k*6,t.y1,1.4+k*6,[0.85,0.84,0.9],a,a*0.5);if(t.t<0.09)pushStreak(S,t.x0,t.h,t.y0,t.x1,t.h,t.y1,1.3,[2.2,2.9,3.4],1-t.t/0.09,0.25);}
  for(const e of mobs){if(e.dead||e.kind!=='rat'||e.tele<=0)continue;const k=1-e.tele/0.45,c=Math.cos(e.aim),s=Math.sin(e.aim),gh=e.r*0.95,gx=e.x+c*e.r*2.1,gy=e.y+s*e.r*2.1;let L=0;while(L<380&&!pointSolid(gx+c*L,gy+s*L,1))L+=10;const a=0.3+0.6*k;pushStreak(S,gx,gh,gy,gx+c*L,gh,gy+s*L,1.0+0.6*k,C_LASER,a,a*0.8);pushPt(A,gx+c*L,gh,gy+s*L,10+8*k,2,C_LASER,0.9);}
  for(const h of hams){if(!h.alive||state==='title')continue;const own=h===me,a=h.aim,R=h.r,lx=h.x+Math.cos(a)*R*1.9-Math.sin(a)*R*0.14,lz=h.y+Math.sin(a)*R*1.9+Math.cos(a)*R*0.14,lh=R*1.05+(h.z||0),fx=h.x+Math.cos(a)*260,fz=h.y+Math.sin(a)*260,rr=110,ca=own?0.09:0.05;
    for(let i=0;i<16;i++){const a0=i/16*TAU,a1=(i+1)/16*TAU;pushTri(S,[lx,lh,lz],[fx+Math.cos(a0)*rr,1.5,fz+Math.sin(a0)*rr*0.8],[fx+Math.cos(a1)*rr,1.5,fz+Math.sin(a1)*rr*0.8],C_LAMP,C_LAMP,C_LAMP,ca,0,0);}
    pushPt(A,lx,lh,lz,5,2,C_LAMP,0.55);if(!own)continue;
    {const W0=WEAPONS[h.weapon.id],c=Math.cos(a),s2=Math.sin(a),gh=R,ox=h.x+c*R*1.3,oy=h.y+s2*R*1.3;
      if((W0.kind==='bullet'||W0.kind==='flame'||W0.kind==='laser'||W0.kind==='rail')&&h.weapon.id!=='sniper'){const maxD=(W0.range||0)*h.st.rangeK,effD=maxD*(W0.eff||1);let L=0;while(L<maxD&&!pointSolid(ox+c*L,oy+s2*L,1))L+=20;L=Math.min(L,maxD);const e1=Math.min(L,effD);
        pushStreak(S,ox,gh,oy,ox+c*e1,gh,oy+s2*e1,0.7,[1.6,1.6,1.7],0.17,0.14);if(L>effD+4)pushStreak(S,ox+c*effD,gh,oy+s2*effD,ox+c*L,gh,oy+s2*L,0.7,[1.8,0.8,0.55],0.12,0.03);
        if(effD<L)pushPt(A,ox+c*effD,gh,oy+s2*effD,7,2,[2.2,2.2,2.4],0.6);pushPt(A,ox+c*L,gh,oy+s2*L,8,2,L<maxD-1?[2.4,1.2,0.6]:[2.2,2.2,2.4],0.5);}
      else if(W0.kind==='lob'){let tx=h.x+c*360,ty=h.y+s2*360;if(h.dev==='kbm'&&mouse.has&&h.mwx!==undefined){tx=h.mwx;ty=h.mwy;}const dx=tx-h.x,dy=ty-h.y,d=Math.hypot(dx,dy)||1,dd=clamp(d,90,W0.range*h.st.rangeK);pushRing(S,h.x+dx/d*dd,1.5,h.y+dy/d*dd,W0.aoe*(1+0.15*(h.weapon.lvl-1)),3,[2.4,1.6,0.6],0.35,32,true);}}
    if(h.weapon.id==='sniper'){const c=Math.cos(a),s=Math.sin(a);let L=0;while(L<900&&!pointSolid(h.x+c*(R*2+L),h.y+s*(R*2+L),1))L+=14;pushStreak(S,h.x+c*R*2,R,h.y+s*R*2,h.x+c*(R*2+L),R,h.y+s*(R*2+L),0.8,[0.6,1.6,2.2],0.35,0.05);}
    for(const st of structs){if(st.dead||st.team===h.team)continue;const d=Math.hypot(st.x-h.x,st.y-h.y);if(d<st.range+200)pushRing(S,st.x,1.6,st.y,st.range,4,[2.4,0.4,0.5],0.35*clamp(1-(d-st.range)/200,0,1),48,true);}}
  for(const s of structs){if(s.dead||s.kind!=='base'||!s.shielded)continue;pushRing(S,s.x,1.2,s.y,170,5,hdrOf(TC2[s.team][2],1.4),0.35+0.15*Math.sin(time*3),48);}
  for(const m of MOTES){if(VIEWS.length>1&&m.v!==vi)continue;const v=VIEWS[m.v]||VIEWS[0];if(!v)continue;const V=v.V;if(Math.abs(m.x-v.camX)>V.hw+60||m.y<v.camY-V.zn-60||m.y>v.camY+V.zs+60){m.x=v.camX+rand(-V.hw,V.hw);m.y=v.camY+rand(-V.zn,V.zs);m.h=rand(8,160);}
    m.x+=(Math.sin(time*0.37+m.ph)*7+3)*dt;m.y+=Math.cos(time*0.29+m.ph*1.3)*5*dt;m.h+=Math.sin(time*0.6+m.ph)*4*dt;let a=0.05;const h=v.ham;if(h&&h.alive){const d=Math.hypot(m.x-h.x,m.y-h.y);a+=0.6*clamp(1-d/340,0,1);}pushPt(A,m.x,m.h,m.y,m.sz,2,C_MOTE,a*(0.6+0.4*Math.sin(time*2.3+m.ph*5)));}
  flushDyn(N);flushDyn(A);flushDyn(S);flushDyn(F);
}
function sync3D(dt){
  for(const v of VIEWS){const shk=state==='pause'?0:Math.pow(v.trauma,1.6)*16;v.shx=shk*(Math.sin(time*47.3)*0.6+Math.sin(time*91.7+0.3)*0.4);v.shz=shk*(Math.sin(time*53.1+1.3)*0.6+Math.sin(time*77.9+0.7)*0.4);}
  if(VIEWS[0])setCamera(VIEWS[0]);
}

// ---------- 绘制 ----------
const PL=new Float32Array(32),PC=new Float32Array(24);
const LIT={sky:new Float32Array([0.07,0.08,0.14]),ground:new Float32Array([0.03,0.025,0.05]),moon:new Float32Array([0.32,0.38,0.62]),shT:new Float32Array([0.13,0.13,0.25]),fill:new Float32Array([0.07,0.07,0.12]),rim:new Float32Array([0.3,0.4,0.8]),lampK:0.62,lampR:270};
const PD=new Float32Array(32);
const DARK={sky:new Float32Array([0.035,0.04,0.075]),ground:new Float32Array([0.02,0.018,0.035]),moon:new Float32Array([0.13,0.15,0.28]),shT:new Float32Array([0.07,0.07,0.14]),fill:new Float32Array([0.035,0.035,0.06]),rim:new Float32Array([0.2,0.28,0.55])};
function setLights(v){
  PL.fill(0);PC.fill(0);PD.fill(0);for(let i=0;i<8;i++)PD[i*4+3]=-2;let n=0;const max=Math.min(8,Q.nl);
  const put=(x,y,z,r,c,k,dir)=>{if(n>=max)return;PL[n*4]=x;PL[n*4+1]=y;PL[n*4+2]=z;PL[n*4+3]=r;PC[n*3]=c[0]*k;PC[n*3+1]=c[1]*k;PC[n*3+2]=c[2]*k;if(dir){PD[n*4]=dir[0];PD[n*4+1]=dir[1];PD[n*4+2]=dir[2];PD[n*4+3]=dir[3];}n++;};
  const spot=h=>{const c=Math.cos(h.aim),s=Math.sin(h.aim),l=Math.hypot(1,0.3);return[c/l,-0.3/l,s/l,lightCos(h)];};
  const cx=v?v.camX:MIDX,cy=v?v.camY:MIDY,me=v&&v.ham;
  if(state==='title'||!me)put(cx,320,cy+80,1300,[1,0.72,0.45],0.5);
  if(me&&me.alive){const nv=me.tal.nightvision?1.6:1;put(me.x+Math.cos(me.aim)*me.r*1.7,me.r+4+(me.z||0),me.y+Math.sin(me.aim)*me.r*1.7,lightRange(me)*1.18,[1,0.8,0.55],1.4,spot(me));put(me.x,20+(me.z||0),me.y+46,105,[1,0.78,0.55],0.75);}
  for(const k of ['flash','boom','eflash']){const L=FLASH[k];if(L.t>0&&Math.hypot(L.x-cx,L.y-cy)<900)put(L.x,L.h,L.y,k==='boom'?-420:k==='eflash'?-190:-230,k==='boom'?[1,0.52,0.22]:k==='eflash'?[1,0.35,0.45]:[1,0.86,0.5],L.i*1.1*Math.max(0,L.t/L.max));}
  const cand=[];
  for(const h of hams)if(h.alive&&h!==me){const d=Math.hypot(h.x-cx,h.y-cy);if(d<1000)cand.push({d,f:()=>put(h.x+Math.cos(h.aim)*h.r*1.7,h.r+4+(h.z||0),h.y+Math.sin(h.aim)*h.r*1.7,lightRange(h)*1.07,[1,0.8,0.55],1.2,spot(h))});}
  for(const p of props)if(p.kind==='lamp'&&!p.dead){const d=Math.hypot(p.x-cx,p.y-cy);if(d<900)cand.push({d:d+80,f:()=>put(p.x,64,p.y,330,[1,0.82,0.55],0.95)});}
  for(const f of fires){const d=Math.hypot(f.x-cx,f.y-cy);if(d<900)cand.push({d:d+40,f:()=>put(f.x,30,f.y,f.r+150,[1,0.55,0.2],0.9)});}
  for(const s of structs)if(!s.dead&&(s.kind==='base'||s.kind==='turret')){const d=Math.hypot(s.x-cx,s.y-cy);if(d<1000)cand.push({d:d+200,f:()=>put(s.x,s.kind==='base'?120:70,s.y,s.kind==='base'?540:320,s.team==='blue'?[0.35,0.6,1]:[1,0.42,0.36],s.kind==='base'?0.8:0.55)});}
  if(G&&G.boss&&!G.boss.dead){const d=Math.hypot(G.boss.x-cx,G.boss.y-cy);if(d<900)cand.push({d:d+100,f:()=>put(G.boss.x,90,G.boss.y,320,[1,0.75,0.3],0.6)});}
  for(const f of flares){const d=Math.hypot(f.x-cx,f.y-cy);if(d<1000)cand.push({d:d+30,f:()=>put(f.x,f.h,f.y,480,[1,0.55,0.35],1.1)});}
  cand.sort((a,b)=>a.d-b.d);for(const c of cand){if(n>=max)break;c.f();}
}
function toonGlobals(pr,hero){
  const u=pr.u;gl.useProgram(pr.p);
  gl.uniformMatrix4fv(u.uVP,false,VPm);gl.uniformMatrix4fv(u.uLVP,false,LVP);
  const Lp=(hero||state==='title')?LIT:DARK;gl.uniform3fv(u.uSky,Lp.sky);gl.uniform3fv(u.uGround,Lp.ground);gl.uniform3fv(u.uLDir,LDIR);gl.uniform3fv(u.uLCol,Lp.moon);gl.uniform3fv(u.uShT,Lp.shT);
  gl.uniform3fv(u.uFillDir,FILL);gl.uniform3fv(u.uFillCol,Lp.fill);gl.uniform3fv(u.uRimCol,Lp.rim);gl.uniform3f(u.uFog,0.03,0.03,0.07);gl.uniform1f(u.uFogK,hero?1e6:640);
  gl.uniform3fv(u.uEye,camPos);gl.uniform1f(u.uShOn,shOn&&!hero?1:0);gl.uniform4fv(u.uPL,PL);gl.uniform3fv(u.uPC,PC);gl.uniform4fv(u.uPD,PD);gl.uniform1i(u.uNL,hero?2:Q.nl);
  gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,shTex);gl.uniform1i(u.uSh,0);
}
function drawNode(u,n){gl.uniformMatrix4fv(u.uM,false,n.W);gl.uniformMatrix3fv(u.uNM,false,nmat(_N9,n.W));gl.uniform3fv(u.uEm,n.mat.em);gl.uniform1f(u.uOp,n.mat.op);gl.bindVertexArray(n.mesh.vao);gl.drawArrays(gl.TRIANGLES,0,n.mesh.n);}
function drawHullN(u,n){if(!n.mesh.hvao)return;gl.uniformMatrix4fv(u.uM,false,n.W);gl.uniform4f(u.uCol,OLC[0],OLC[1],OLC[2],n.mat.op);gl.bindVertexArray(n.mesh.hvao);gl.drawArrays(gl.TRIANGLES,0,n.mesh.hn);}
const ZERO3=new Float32Array(3),ID9=new Float32Array([1,0,0,0,1,0,0,0,1]);
function shadowPass(opq){
  gl.bindFramebuffer(gl.FRAMEBUFFER,shFB);gl.viewport(0,0,SS,SS);gl.disable(gl.SCISSOR_TEST);gl.depthMask(true);gl.clear(gl.DEPTH_BUFFER_BIT);gl.enable(gl.DEPTH_TEST);gl.enable(gl.CULL_FACE);gl.cullFace(gl.FRONT);gl.disable(gl.BLEND);
  let pr=PRG.line;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,LVP);gl.uniform4f(pr.u.uCol,0,0,0,1);
  for(const n of opq){if(!n.mat.cast)continue;gl.uniformMatrix4fv(pr.u.uM,false,n.W);gl.bindVertexArray(n.mesh.vao);gl.drawArrays(gl.TRIANGLES,0,n.mesh.n);}
  pr=PRG.lineI;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,LVP);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniform4f(pr.u.uCol,0,0,0,1);
  for(const o of PART_LIST){if(!o.count||!o.cast)continue;gl.bindVertexArray(o.vao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.n,o.count);}
}
function scenePass(opq,trn,vh){
  gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);gl.enable(gl.CULL_FACE);gl.cullFace(gl.BACK);gl.disable(gl.BLEND);gl.depthMask(true);
  let pr=PRG.toon;toonGlobals(pr);for(const n of opq)drawNode(pr.u,n);
  pr=PRG.toonI;toonGlobals(pr);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniformMatrix3fv(pr.u.uNM,false,ID9);gl.uniform1f(pr.u.uOp,1);gl.uniform3fv(pr.u.uEm,ZERO3);
  for(const o of PART_LIST){if(!o.count)continue;gl.bindVertexArray(o.vao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.n,o.count);}
  gl.cullFace(gl.FRONT);
  pr=PRG.line;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);for(const n of opq)drawHullN(pr.u,n);
  pr=PRG.lineI;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniform4f(pr.u.uCol,OLC[0],OLC[1],OLC[2],1);
  for(const o of PART_LIST){if(!o.count||!o.hvao)continue;gl.bindVertexArray(o.hvao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.hn,o.count);}
  gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);gl.cullFace(gl.BACK);
  if(trn.length){gl.depthMask(false);pr=PRG.toon;toonGlobals(pr);for(const n of trn)drawNode(pr.u,n);}
  gl.disable(gl.CULL_FACE);gl.depthMask(false);
  pr=PRG.flat;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);if(DYN.flat.n){gl.bindVertexArray(DYN.flat.vao);gl.drawArrays(gl.TRIANGLES,0,DYN.flat.n);}
  pr=PRG.pt;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);gl.uniform1f(pr.u.uScale,vh/(2*Math.tan(FOV/2)));
  if(DYN.ptN.n){gl.bindVertexArray(DYN.ptN.vao);gl.drawArrays(gl.POINTS,0,DYN.ptN.n);}
  gl.blendFunc(gl.SRC_ALPHA,gl.ONE);if(DYN.ptA.n){gl.bindVertexArray(DYN.ptA.vao);gl.drawArrays(gl.POINTS,0,DYN.ptA.n);}
  pr=PRG.flat;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);if(DYN.streak.n){gl.bindVertexArray(DYN.streak.vao);gl.drawArrays(gl.TRIANGLES,0,DYN.streak.n);}
  gl.depthMask(true);gl.disable(gl.BLEND);gl.bindVertexArray(null);
}
function draw3D(){
  for(const r of ROOTS)r.upd(null);
  const list=[];for(const r of ROOTS)collect(r,list);const opq=list.filter(n=>n.mat.op>=0.999),trn=list.filter(n=>n.mat.op<0.999);
  const usePost=setupRT(),TW=usePost?RT.w:glc.width,TH=usePost?RT.h:glc.height;
  for(const v of VIEWS){
    setCamera(v);setLights(v);syncInst(v);syncDyn(RDT,v);if(shOn)shadowPass(opq);
    const sx=TW/W,sy=TH/H,r=v.rect,vx=Math.round(r.x*sx),vy=Math.round(TH-(r.y+r.h)*sy),vw=Math.max(1,Math.round(r.w*sx)),vh=Math.max(1,Math.round(r.h*sy));
    gl.bindFramebuffer(gl.FRAMEBUFFER,usePost?RT.ms:null);gl.viewport(vx,vy,vw,vh);gl.enable(gl.SCISSOR_TEST);gl.scissor(vx,vy,vw,vh);
    gl.clearColor(0.035,0.03,0.07,1);gl.depthMask(true);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
    scenePass(opq,trn,vh);gl.disable(gl.SCISSOR_TEST);
  }
  if(VIEWS[0])setCamera(VIEWS[0]);
  if(usePost){gl.bindFramebuffer(gl.READ_FRAMEBUFFER,RT.ms);gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER,RT.scF);gl.blitFramebuffer(0,0,RT.w,RT.h,0,0,RT.w,RT.h,gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT,gl.NEAREST);gl.bindFramebuffer(gl.FRAMEBUFFER,null);postFX();}
}
function renderHero(){
  let w=640,h=460;if(!gl)return null;if(glc.width<w||glc.height<h){w=320;h=230;}if(glc.width<w||glc.height<h)return null;
  const S={id:0,x:0,y:0,aim:Math.PI/2-0.42,vr:{v:15},sq:{v:1},puff:{v:0.55},walk:0,moving:false,rollT:0,rollA:0,rdx:1,rdy:0,alive:true,hurtT:0,kick:{v:0},vx:0,vy:0,munchT:0,swingT:0,swingDir:1,team:'blue',skin:'gold',weapon:{id:'pistol'}};
  const rig=makeHamRig(),t0=time;time=0.9;poseHam(rig,S);time=t0;rig.gun.vis=false;rig.root.upd(null);
  for(const o of PART_LIST)o.count=0;pushNode(rig.root,S,0,0,0);for(const o of PART_LIST)instFlush(o);
  const ec=[14,38,64];camPos.set(ec);m4persp(Pm,0.6,w/h,5,800);m4look(Vm,ec,[0,17,0],[0,1,0]);m4mul(VPm,Pm,Vm);
  PL.fill(0);PC.fill(0);PD.fill(0);for(let i=0;i<8;i++)PD[i*4+3]=-2;PL[0]=40;PL[1]=70;PL[2]=90;PL[3]=320;PC[0]=1.0;PC[1]=0.74;PC[2]=0.48;PL[4]=-60;PL[5]=40;PL[6]=30;PL[7]=260;PC[3]=0.3;PC[4]=0.38;PC[5]=0.7;
  gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.viewport(0,0,w,h);gl.enable(gl.SCISSOR_TEST);gl.scissor(0,0,w,h);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
  gl.enable(gl.DEPTH_TEST);gl.enable(gl.CULL_FACE);gl.cullFace(gl.BACK);gl.disable(gl.BLEND);gl.depthMask(true);
  let pr=PRG.toonI;toonGlobals(pr,true);gl.uniform3f(pr.u.uSky,0.36,0.34,0.46);gl.uniform3f(pr.u.uLCol,0.46,0.5,0.75);gl.uniform3f(pr.u.uFillCol,0.22,0.2,0.26);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniformMatrix3fv(pr.u.uNM,false,ID9);gl.uniform1f(pr.u.uOp,1);gl.uniform3fv(pr.u.uEm,ZERO3);
  for(const o of PART_LIST){if(!o.count)continue;gl.bindVertexArray(o.vao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.n,o.count);}
  gl.cullFace(gl.FRONT);pr=PRG.lineI;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniform4f(pr.u.uCol,OLC[0],OLC[1],OLC[2],1);
  for(const o of PART_LIST){if(!o.count||!o.hvao)continue;gl.bindVertexArray(o.hvao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.hn,o.count);}
  gl.disable(gl.SCISSOR_TEST);gl.cullFace(gl.BACK);gl.bindVertexArray(null);
  const c=document.createElement('canvas');c.width=320;c.height=230;const g=c.getContext('2d');g.imageSmoothingQuality='high';g.drawImage(glc,0,glc.height-h,w,h,0,0,320,230);
  for(const o of PART_LIST)o.count=0;return c.toDataURL();
}

// ---------- 图鉴快照 ----------
function snapshot(push,eye,tgt,size=128,fov=0.55){if(!gl)return '';const w=size,h=size;if(glc.width<w||glc.height<h)return '';
  for(const o of PART_LIST)o.count=0;push();for(const o of PART_LIST)instFlush(o);
  camPos.set(eye);m4persp(Pm,fov,1,2,900);m4look(Vm,eye,tgt,[0,1,0]);m4mul(VPm,Pm,Vm);
  PL.fill(0);PC.fill(0);PD.fill(0);for(let i=0;i<8;i++)PD[i*4+3]=-2;PL[0]=eye[0]+40;PL[1]=eye[1]+70;PL[2]=eye[2]+60;PL[3]=500;PC[0]=1.0;PC[1]=0.8;PC[2]=0.6;PL[4]=eye[0]-90;PL[5]=eye[1]*0.5;PL[6]=eye[2]-20;PL[7]=400;PC[3]=0.35;PC[4]=0.45;PC[5]=0.8;
  gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.viewport(0,0,w,h);gl.enable(gl.SCISSOR_TEST);gl.scissor(0,0,w,h);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
  gl.enable(gl.DEPTH_TEST);gl.enable(gl.CULL_FACE);gl.cullFace(gl.BACK);gl.disable(gl.BLEND);gl.depthMask(true);
  let pr=PRG.toonI;toonGlobals(pr,true);gl.uniform3f(pr.u.uSky,0.4,0.38,0.5);gl.uniform3f(pr.u.uLCol,0.5,0.54,0.78);gl.uniform3f(pr.u.uFillCol,0.24,0.22,0.28);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniformMatrix3fv(pr.u.uNM,false,ID9);gl.uniform1f(pr.u.uOp,1);gl.uniform3fv(pr.u.uEm,ZERO3);
  for(const o of PART_LIST){if(!o.count)continue;gl.bindVertexArray(o.vao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.n,o.count);}
  gl.cullFace(gl.FRONT);pr=PRG.lineI;gl.useProgram(pr.p);gl.uniformMatrix4fv(pr.u.uVP,false,VPm);gl.uniformMatrix4fv(pr.u.uM,false,IDM);gl.uniform4f(pr.u.uCol,OLC[0],OLC[1],OLC[2],1);
  for(const o of PART_LIST){if(!o.count||!o.hvao)continue;gl.bindVertexArray(o.hvao);gl.drawArraysInstanced(gl.TRIANGLES,0,o.hn,o.count);}
  gl.disable(gl.SCISSOR_TEST);gl.cullFace(gl.BACK);gl.bindVertexArray(null);
  const c=document.createElement('canvas');c.width=w;c.height=h;c.getContext('2d').drawImage(glc,0,glc.height-h,w,h,0,0,w,h);for(const o of PART_LIST)o.count=0;return c.toDataURL();}
function codexSnaps(){const out={};if(!gl)return out;const one=(part,y,ry,sc=1)=>{m4trs(_M,0,y,0,ry,0,0,sc,sc,sc);instPush(PARTS[part],_M,0,0,0);};
  const sh=(k,push,eye,tgt,fov)=>{try{out[k]=snapshot(push,eye,tgt,128,fov||0.55);}catch(e){console.error(e);}};
  sh('m_roach',()=>{const rg=makeRoachRig();poseRoach(rg,{x:0,y:0,vx:0,vy:0,heading:-0.6,t:0.4});rg.root.upd(null);pushNode(rg.root,null,0,0,0);},[34,40,46],[2,5,0]);
  const ratE={x:0,y:0,vx:0,vy:0,aim:Math.PI/2-0.55,walk:0,t:0.5,tele:0,recoil:0,flash:0,target:null};
  sh('m_rat',()=>{const rg=makeRatRig(false);poseRat(rg,ratE,1);rg.root.upd(null);pushNode(rg.root,null,0,0,0);},[30,40,62],[0,18,0]);
  sh('m_boss',()=>{const rg=makeRatRig(true);poseRat(rg,ratE,1);rg.root.upd(null);pushNode(rg.root,null,0,0,0);},[32,44,66],[0,21,0]);
  sh('m_minion',()=>one('min_blue',0,Math.PI/2-0.6),[26,36,48],[0,12,0]);
  sh('m_turret',()=>{one('tur_base_blue',0,0);m4trs(_M,0,50,0,Math.PI/2-0.5,0,0,1,1,1);instPush(PARTS.tur_head_blue,_M,0,0,0);},[70,96,130],[0,38,0]);
  sh('s_pad',()=>one('pad',0,0.6),[48,60,74],[0,12,0]);
  sh('s_barrel',()=>one('barrel',0,0.4),[40,52,66],[0,24,0]);
  sh('s_box',()=>one('pbox',0,0.5),[96,112,140],[0,30,0]);
  sh('s_lamp',()=>{one('lamp_base',0,0);one('lamp_bulb',0,0);},[54,70,96],[0,38,0]);
  sh('s_crate',()=>one('crate',0,0.5),[52,66,84],[0,18,0]);
  sh('s_bigcrate',()=>one('crate_big',0,0.5),[78,96,124],[0,26,0]);
  for(const sk in SKINS)sh('k_'+sk,()=>{const S={id:0,x:0,y:0,aim:Math.PI/2-0.42,vr:{v:15},sq:{v:1},puff:{v:0.4},walk:0,moving:false,rollT:0,rollA:0,rdx:1,rdy:0,alive:true,hurtT:0,kick:{v:0},vx:0,vy:0,munchT:0,swingT:0,swingDir:1,team:'blue',skin:sk,weapon:{id:'pistol'}};const rig=makeHamRig(),t0=time;time=0.9;poseHam(rig,S);time=t0;rig.gun.vis=false;rig.root.upd(null);pushNode(rig.root,S,0,0,0);},[14,38,64],[0,17,0]);
  return out;}
