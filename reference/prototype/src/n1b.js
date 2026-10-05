// ---------- 合成枪声 ----------
const GSFX=(()=>{
  let ac=null,bus=null,revIn=null,noise=null,ready=false,voices=0;const last={};
  function setup(){if(ready)return true;ac=SFX.ac;bus=SFX.bus;if(!ac||!bus)return false;
    const len=Math.floor(ac.sampleRate*0.6);noise=ac.createBuffer(1,len,ac.sampleRate);const d=noise.getChannelData(0);for(let i=0;i<len;i++)d[i]=Math.random()*2-1;
    const il=Math.floor(ac.sampleRate*1.6),ir=ac.createBuffer(2,il,ac.sampleRate);
    for(let c=0;c<2;c++){const ch=ir.getChannelData(c);for(let i=0;i<il;i++){const t=i/ac.sampleRate;ch[i]=(Math.random()*2-1)*Math.pow(1-i/il,2.2)*Math.exp(-t*2.4)*(t<0.01?0.25:1);}}
    const rev=ac.createConvolver();rev.buffer=ir;revIn=ac.createGain();revIn.gain.value=0.85;const rl=ac.createBiquadFilter();rl.type='lowpass';rl.frequency.value=3400;revIn.connect(rev);rev.connect(rl);rl.connect(bus);
    ready=true;return true;}
  function ok(k,gap){if(SFX.muted||!setup()||ac.state!=='running')return false;const t=ac.currentTime;if(k){if(last[k]!=null&&t-last[k]<gap)return false;last[k]=t;}return voices<40;}
  function out(pan,vol,send){const g=ac.createGain();g.gain.value=vol;let n=g;if(ac.createStereoPanner){const p=ac.createStereoPanner();p.pan.value=clamp(pan,-1,1);g.connect(p);n=p;}n.connect(bus);if(send>0){const s=ac.createGain();s.gain.value=send;n.connect(s);s.connect(revIn);}return g;}
  function nz(t0,type,f,q,peak,decay,dst,attack=0.001){const s=ac.createBufferSource();s.buffer=noise;s.playbackRate.value=0.8+Math.random()*0.4;const fl=ac.createBiquadFilter();fl.type=type;fl.frequency.value=f;if(q)fl.Q.value=q;const g=ac.createGain();g.gain.setValueAtTime(0.0001,t0);g.gain.linearRampToValueAtTime(peak,t0+attack);g.gain.exponentialRampToValueAtTime(0.0001,t0+decay);s.connect(fl);fl.connect(g);g.connect(dst);s.start(t0,Math.random()*0.25);s.stop(t0+decay+0.03);voices++;s.onended=()=>{voices--;};return fl;}
  function tone(t0,f0,f1,dur,type,peak,dst){const o=ac.createOscillator();o.type=type;o.frequency.setValueAtTime(f0,t0);o.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t0+dur);const g=ac.createGain();g.gain.setValueAtTime(0.0001,t0);g.gain.linearRampToValueAtTime(peak,t0+0.003);g.gain.exponentialRampToValueAtTime(0.0001,t0+dur);o.connect(g);g.connect(dst);o.start(t0);o.stop(t0+dur+0.02);voices++;o.onended=()=>{voices--;};}
  const P={
    pistol:{hp:2600,cr:0.55,lp:1900,bd:0.10,bg:0.75,t0:170,t1:60,td:0.07,tg:0.55,rev:0.22,gap:0.05},
    deagle:{hp:2200,cr:0.75,lp:1250,bd:0.22,bg:1.05,t0:125,t1:36,td:0.15,tg:0.95,rev:0.45,gap:0.08},
    ak47:{hp:2400,cr:0.6,lp:1500,bd:0.13,bg:0.85,t0:150,t1:48,td:0.09,tg:0.7,rev:0.28,gap:0.045,mech:1},
    smg:{hp:3000,cr:0.42,lp:2300,bd:0.07,bg:0.55,t0:190,t1:80,td:0.05,tg:0.4,rev:0.16,gap:0.03},
    shotgun:{hp:1800,cr:0.75,lp:950,bd:0.3,bg:1.1,t0:110,t1:32,td:0.17,tg:1.0,rev:0.48,gap:0.1},
    sniper:{hp:3300,cr:0.9,lp:1100,bd:0.34,bg:1.05,t0:95,t1:28,td:0.2,tg:1.0,rev:0.8,gap:0.1},
    lmg:{hp:2300,cr:0.62,lp:1300,bd:0.13,bg:0.9,t0:130,t1:44,td:0.09,tg:0.75,rev:0.28,gap:0.05,mech:1},
    minion:{hp:3400,cr:0.22,lp:2600,bd:0.05,bg:0.28,t0:230,t1:110,td:0.035,tg:0.18,rev:0.08,gap:0.05},
    turret:{hp:1500,cr:0.35,lp:900,bd:0.16,bg:0.7,t0:110,t1:40,td:0.12,tg:0.7,rev:0.3,gap:0.08},
    rat:{hp:2800,cr:0.35,lp:2000,bd:0.07,bg:0.45,t0:180,t1:70,td:0.05,tg:0.35,rev:0.15,gap:0.05},
    minigun:{hp:3000,cr:0.38,lp:2100,bd:0.06,bg:0.5,t0:180,t1:75,td:0.045,tg:0.38,rev:0.14,gap:0.028},
    autoshot:{hp:1900,cr:0.65,lp:1050,bd:0.22,bg:0.95,t0:115,t1:36,td:0.13,tg:0.85,rev:0.38,gap:0.06},
    amr:{hp:2800,cr:1.0,lp:850,bd:0.42,bg:1.25,t0:80,t1:22,td:0.28,tg:1.2,rev:0.95,gap:0.12},
    revolver:{hp:2500,cr:0.8,lp:1500,bd:0.2,bg:0.95,t0:140,t1:40,td:0.13,tg:0.85,rev:0.5,gap:0.08},
    gl:{hp:1200,cr:0.2,lp:600,bd:0.12,bg:0.8,t0:160,t1:60,td:0.1,tg:0.9,rev:0.2,gap:0.08},
    sentry:{hp:3200,cr:0.28,lp:2400,bd:0.05,bg:0.32,t0:210,t1:100,td:0.035,tg:0.22,rev:0.1,gap:0.05}};
  function click(t,pan,vol,f,q,g,d){const o=out(pan,vol,0.05);nz(t,'bandpass',f,q,g,d,o);}
  return{
    shot(kind,pan,vol){const p=P[kind]||P.pistol;if(vol<0.04||!ok('g'+kind,p.gap))return;const t=ac.currentTime+0.002,o=out(pan,vol*0.85,p.rev*vol);
      nz(t,'highpass',p.hp,0.7,p.cr*1.6,0.028,o);nz(t,'lowpass',p.lp,0.8,p.bg,p.bd,o,0.002);tone(t,p.t0,p.t1,p.td,'sine',p.tg,o);
      if(p.mech)nz(t+0.03,'bandpass',2600,6,0.22,0.025,o);},
    rocket(pan,vol){if(vol<0.04||!ok('rk',0.1))return;const t=ac.currentTime,o=out(pan,vol,0.35);const f=nz(t,'bandpass',600,1.2,0.9,0.5,o,0.02);f.frequency.setValueAtTime(500,t);f.frequency.exponentialRampToValueAtTime(2400,t+0.4);tone(t,95,38,0.2,'sine',0.75,o);},
    boom(pan,vol,big){if(vol<0.04||!ok('boom',0.06))return;const t=ac.currentTime,o=out(pan,vol,0.7*vol);nz(t,'lowpass',big?360:520,0.7,1.3,big?1.15:0.8,o,0.004);nz(t,'highpass',1500,0.7,0.6,0.05,o);tone(t,72,24,big?0.6:0.4,'sine',1.1,o);},
    pump(pan,vol){if(vol<0.05||!ok(null))return;const t=ac.currentTime+0.3;click(t,pan,vol,1800,5,0.75,0.035);click(t+0.13,pan,vol,2500,6,0.85,0.03);},
    bolt(pan,vol){if(vol<0.05||!ok(null))return;const t=ac.currentTime+0.38;click(t,pan,vol,2100,7,0.65,0.03);click(t+0.17,pan,vol,2900,7,0.75,0.025);},
    reload(pan,vol,dur){if(vol<0.05||!ok(null))return;const t=ac.currentTime;click(t+0.03,pan,vol,1500,5,0.6,0.045);click(t+dur*0.55,pan,vol,2100,6,0.8,0.035);click(t+Math.max(0.1,dur-0.12),pan,vol,3000,7,0.75,0.025);},
    empty(pan,vol){if(vol<0.05||!ok('empty',0.2))return;click(ac.currentTime,pan,vol,4200,9,0.6,0.015);},
    tink(pan,vol){if(vol<0.05||!ok('tink',0.04))return;const t=ac.currentTime,o=out(pan,vol*0.4,0.08),f=rand(4200,6800);tone(t,f,f*0.97,0.06,'sine',0.35,o);tone(t+0.07,f*1.02,f,0.04,'sine',0.16,o);},
    swish(pan,vol){if(vol<0.05||!ok('sw',0.08))return;const t=ac.currentTime,o=out(pan,vol,0.1),f=nz(t,'bandpass',800,2,0.75,0.17,o,0.03);f.frequency.setValueAtTime(700,t);f.frequency.exponentialRampToValueAtTime(3800,t+0.14);},
    ting(pan,vol){if(vol<0.05||!ok('ting',0.06))return;const t=ac.currentTime,o=out(pan,vol*0.5,0.3);tone(t,2600,2500,0.25,'triangle',0.4,o);tone(t,3900,3850,0.18,'sine',0.25,o);},
    flame(pan,vol){if(vol<0.05||!ok('fl',0.07))return;const t=ac.currentTime,o=out(pan,vol*0.7,0.12);nz(t,'lowpass',1400,0.6,0.5,0.15,o,0.03);},
    hit(pan,vol){if(vol<0.05||!ok('hm',0.04))return;const t=ac.currentTime,o=out(pan,vol*0.4,0);tone(t,1800,1500,0.04,'square',0.14,o);},
    spin(pan,vol){if(vol<0.05||!ok('spin',0.3))return;const t=ac.currentTime,o=out(pan,vol*0.5,0.1);tone(t,180,900,0.6,'sawtooth',0.12,o);nz(t,'bandpass',1800,3,0.2,0.6,o,0.3);},
    charge(pan,vol){if(vol<0.05||!ok('chg',0.3))return;const t=ac.currentTime,o=out(pan,vol*0.5,0.2);tone(t,300,2400,1.0,'sine',0.25,o);tone(t,302,2420,1.0,'triangle',0.12,o);},
    rail(pan,vol,ch){if(vol<0.05||!ok('rail',0.1))return;const t=ac.currentTime,o=out(pan,vol,0.7*vol),k=0.5+ch;tone(t,3200,180,0.35,'sawtooth',0.35*k,o);nz(t,'highpass',2000,0.7,1.2,0.05,o);nz(t,'lowpass',700,0.7,1.0*k,0.5,o,0.003);tone(t,90,28,0.4,'sine',1.0*k,o);},
    laser(pan,vol){if(vol<0.05||!ok('lz',0.06))return;const t=ac.currentTime,o=out(pan,vol*0.45,0.08);tone(t,880,860,0.11,'sawtooth',0.12,o);tone(t,1320,1300,0.11,'square',0.05,o);},
    throw(pan,vol){if(vol<0.05||!ok('thr',0.1))return;const t=ac.currentTime,o=out(pan,vol*0.6,0.05),f=nz(t,'bandpass',600,1.5,0.5,0.2,o,0.05);f.frequency.setValueAtTime(400,t);f.frequency.exponentialRampToValueAtTime(1600,t+0.18);},
    clank(pan,vol){if(vol<0.05||!ok('clk',0.05))return;const t=ac.currentTime,o=out(pan,vol*0.5,0.1);tone(t,1400,1300,0.08,'triangle',0.3,o);nz(t,'bandpass',2600,4,0.3,0.04,o);},
    glass(pan,vol){if(vol<0.05||!ok('gls',0.1))return;const t=ac.currentTime,o=out(pan,vol,0.3);nz(t,'highpass',3000,0.7,1.0,0.25,o);for(let i=0;i<5;i++){const f=rand(3500,7000);tone(t+i*0.03,f,f*0.98,0.08,'sine',0.2,o);}nz(t+0.02,'lowpass',500,0.7,0.6,0.5,o,0.05);},
    bang(pan,vol){if(vol<0.05||!ok('bang',0.1))return;const t=ac.currentTime,o=out(pan,vol,0.9*vol);nz(t,'highpass',1800,0.7,1.6,0.06,o);nz(t,'lowpass',600,0.7,1.2,0.6,o,0.003);tone(t,70,25,0.4,'sine',1.1,o);const o2=out(0,vol*0.22,0);tone(t+0.05,3600,3550,2.0,'sine',0.25,o2);},
    beep(pan,vol){if(vol<0.05||!ok('bp',0.1))return;const t=ac.currentTime,o=out(pan,vol*0.4,0);tone(t,1600,1600,0.08,'square',0.15,o);tone(t+0.12,2100,2100,0.08,'square',0.15,o);},
    ric(pan,vol){if(vol<0.05||!ok('ric',0.08))return;const t=ac.currentTime,o=out(pan,vol*0.5,0.3);tone(t,2400,900,0.25,'sine',0.25,o);}};
})();
