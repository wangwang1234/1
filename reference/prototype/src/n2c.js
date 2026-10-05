// ======== 武器进化：数据 ========
const PATHC=['#ff9a3c','#5fb0ff','#c77dff'],PK=['a','b','c'];
const EVO={
pistol:[['快枪手','射速 +7%','子弹飞得更快','弹匣 +4','扇射：每次扣扳机连发 3 枪'],['穿甲弹头','伤害 +7%','穿透 +1','穿透再 +1','暴击率 +25%'],['战术强光','手电更远 +10%','光束更宽','照到的敌人受伤 +10%','光里 200 内的敌人被晃瞎']],
deagle:[['重型弹','击退 +12%、伤害 +4%','命中减速','击退再 +30%','撞墙眩晕：打到墙上的敌人晕 0.8 秒'],['稳定握把','射速 +7%','开枪零散布','弹匣 +2','快速补枪：0.5 秒内第二枪伤害 +50%'],['处决者','打残血伤害 +8%','残血线提高到 50%','处决伤害再 +15%','击杀立即返还子弹并重置射击']],
ak47:[['特种弹药','伤害 +4%','燃烧弹：15% 几率点燃','穿甲弹：穿透 +1，打建筑 +30%','三种弹轮流装填：燃烧、穿甲、爆裂'],['大弹鼓','弹匣 +12%','换弹快 15%','弹匣再 +20%','压制火力：连射时伤害逐渐升高，最多 +40%'],['精准射手','散布 -7%、有效射程 +8%','子弹更快','暴击率 +10%','停顿后的第一枪伤害翻倍并穿透']],
smg:[['扇面扫射','覆盖更宽、射速 +3%','每次多射 1 发','再多射 1 发','子弹飞到一半分裂成两颗'],['跑射','开火时移速 +4%','换弹快 20%','翻滚冷却 -20%','翻滚瞬间换弹，之后 3 秒射速 +30%'],['跳弹','子弹撞墙反弹、伤害 +3%','反弹 2 次','反弹后伤害 +20%','反弹后自动追踪敌人']],
shotgun:[['鹿弹','弹丸更集中、伤害 +3%','+1 弹丸','再 +1 弹丸','弹丸穿透 1 个敌人'],['龙息弹','点燃几率 +7%','燃烧伤害 +50%','被点燃的敌人减速','每一枪都在前方留下一片火海'],['冲击弹','击退 +15%','命中短暂眩晕','击退再 +30%','贴脸一枪把人轰飞并眩晕']],
sniper:[['鹰眼','手电和视野更远 +12%','瞄准线上的敌人全队可见','瞄准视野更宽','命中的敌人全队可见 5 秒'],['贯穿','伤害 +5%','穿透 +1','穿透再 +1','能穿过薄障碍'],['屏息','静止瞄准伤害 +8%','瞄准蓄力更快','蓄满时暴击率 +15%','蓄满必暴击']],
lmg:[['弹链','弹匣 +12%、换弹快 6%','弹匣再 +15%','换弹再快 15%','站着不动开火不耗子弹'],['压制','命中减速更久','命中处周围也被减速','减速更强','被压制的敌人受到伤害 +20%'],['架枪','站定后伤害 +5%','架枪更快','架枪时射速 +15%','架枪时正面挡住子弹']],
rocket:[['追踪','火箭追踪更灵敏','目标死了自动换下一个','追踪范围更大','一次发射 3 枚火箭各锁一个目标'],['大当量','爆炸范围 +9%、伤害 +5%','爆炸击退更强','爆炸减速敌人','爆炸留下燃烧弹坑'],['集束','爆炸散出子炸弹、伤害 +8%','子炸弹 +1','子炸弹再 +1','一次发射两枚火箭']],
katana:[['弹反','格挡范围 +8%、反弹伤害 +10%','反弹的子弹追踪射手','翻滚时也能格挡','完美格挡：反弹伤害 ×3 并无敌 0.6 秒'],['剑气','挥刀放出剑气，射程 +30','剑气穿透','剑气变宽','第三刀放出十字巨型剑气'],['居合','翻滚斩伤害 +8%','翻滚冷却 -25%','翻滚距离 +25%','击杀刷新翻滚']],
flame:[['高压喷嘴','射程 +7%、喷得更宽','火焰伤害 +15%','火焰推开敌人','蓝色高温火柱：伤害 ×1.5'],['黏性燃料','燃烧时间 +0.3 秒','火焰尽头留下火洼','火洼更大','燃烧会传染给身边敌人'],['热浪','近处的敌方子弹被烧掉','烧子弹范围更大','整条火焰都能烧子弹','连喷 3 秒后火焰爆发']],
minigun:[['极速转管','预热快 9%、射速 +4%','射速再 +6%','预热再快 15%','松开后 3 秒不降速'],['移动堡垒','开火时移速 +5%','开火时不会被击退','开火时减伤 10%','开火时减伤 25%'],['曳光弹幕','命中的敌人短暂全队可见','5% 几率点燃','可见时间再 +1 秒','每第 10 发是爆炸弹']],
autoshot:[['大弹鼓','弹匣 +12%','换弹快 20%','弹匣再 +20%','翻滚补充一半弹匣'],['破片弹','命中小爆炸几率 +5%','爆炸范围更大','几率再 +10%','破片会弹跳'],['风暴','连射越来越快（上限 +4%）','加速更快','加速上限再 +10%','弹匣最后 5 发变成龙息弹']],
amr:[['穿甲王','伤害 +5%','穿透 +1','穿透再 +1','无视所有障碍贯穿全图'],['冲击波','命中时震退周围，范围 +6','冲击波眩晕','冲击波范围更大','对建筑伤害翻倍'],['侦察弹','弹道留下视野（时间 +0.3 秒）','视野更宽','视野更久','命中标记 8 秒']],
dual:[['连射','射速 +7%','子弹更快','弹匣 +6','翻滚时 360° 枪斗术'],['左右开弓','副手自动瞄第二个目标（+8%）','自动瞄准范围更大','副手伤害 +20%','两把枪各锁一个目标'],['快速装填','换弹快 8%','弹匣 +4','击杀补 25% 弹匣','弹匣打空时翻滚瞬间装满']],
revolver:[['跳弹大师','反弹伤害 +6%','多反弹 1 次','再多反弹 1 次','反弹后自动追踪'],['神枪手','按住标记目标、松开连射（伤害 +5%）','标记更快','标记的子弹穿透','标记速度翻倍且必暴击'],['重弹头','伤害 +6%，命中硬直','击退更强','打断对方换弹','每第 6 发必暴击']],
gl:[['弹跳','引信更长、弹得更远','榴弹更快','爆炸范围更大','第一次落地分裂成 3 颗'],['黏弹','伤害 +6%，榴弹会粘住','粘住的敌人减速','爆炸范围更大','再扣扳机手动引爆全部黏弹'],['特种弹','每 3 发一颗烟雾弹','加入闪光弹轮换','加入燃烧弹轮换','每颗都附带减速毒气']],
rail:[['超载','蓄力快 5%、伤害 +6%','蓄力再快 10%','伤害再 +10%','蓄满时电弧连锁'],['相位','伤害 +3%，光束能穿 1 层墙','能穿 2 层墙','穿透所有墙','碰到边界反射一次'],['磁暴','命中减速并拖慢换弹','让炮台停火 1 秒','减速更强','地面留下电流带']],
laser:[['聚焦','照同一目标伤害递增（上限 +10%）','递增更快','上限再 +20%','叠满时点燃并瞬间回能'],['棱镜','分出副光束（伤害 +3%）','副光束更强','再分出 1 道','光束在敌人之间折射'],['冷却','耗能 -6%、射程 +6%','耗能再 -10%','射程再 +10%','每 15 秒有 3 秒零耗能且伤害 +30%']]};
const EVV={pistol:['coil','muzzle','torch'],deagle:['muzzle','scope','radar'],ak47:['tank','drum','scope'],smg:['muzzle','drum','radar'],shotgun:['muzzle','tank','coil'],sniper:['scope','muzzle','radar'],lmg:['drum','coil','scope'],rocket:['radar','tank','drum'],katana:['blade','blade','blade'],flame:['muzzle','tank','coil'],minigun:['coil','drum','torch'],autoshot:['drum','tank','coil'],amr:['muzzle','coil','scope'],dual:['coil','scope','drum'],revolver:['radar','scope','muzzle'],gl:['drum','tank','radar'],rail:['coil','muzzle','radar'],laser:['scope','coil','tank']};
const MUZ={pistol:0.88,deagle:1.12,ak47:1.9,smg:1.07,shotgun:1.77,sniper:2.5,lmg:1.9,rocket:1.78,katana:2.4,flame:1.7,minigun:1.95,autoshot:1.45,amr:2.76,dual:0.88,revolver:1.12,gl:1.35,rail:2.0,laser:1.3};
function evText(id,i,lv){const p=EVO[id][i];return lv>=9?'质变：'+p[4]:lv===3?p[1]+'；'+p[2]:lv===6?p[1]+'；'+p[3]:p[1];}
function eL(h,k){return h.evo?(h.evo[k]||0):0;}
let smokes=[],flares=[],decoys=[],zones=[],corrs=[];

// ======== 武器进化：数值 ========
function evp(h){const id=h.weapon.id,a=eL(h,'a'),b=eL(h,'b'),c=eL(h,'c'),P={rate:1,dmg:1,spread:1,n:0,pierce:0,bounce:0,bounceK:0.85,spd:1,kb:1,range:1,eff:1,magMul:1,magAdd:0,rl:1,crit:0,ign:0,ignK:1,slow:0,stun:0,mark:0,home:0,homeAfter:0,splitAt:0,wp:0,aoe:1,aoeDmg:1};
  switch(id){
  case'pistol':P.rate+=0.07*a;if(a>=3)P.spd=1.25;if(a>=6)P.magAdd+=4;P.dmg+=0.07*b;P.pierce+=(b>=3)+(b>=6);if(b>=9)P.crit+=0.25;break;
  case'deagle':P.kb+=0.12*a+(a>=6?0.3:0);P.dmg+=0.04*a;if(a>=3)P.slow=0.5;P.rate+=0.07*b;if(b>=3)P.spread=0;if(b>=6)P.magAdd+=2;break;
  case'ak47':P.dmg+=0.04*a;if(a>=3)P.ign=0.15;if(a>=6)P.pierce+=1;P.magMul+=0.12*b+(b>=6?0.2:0);if(b>=3)P.rl*=0.85;P.spread*=Math.max(0.3,1-0.07*c);P.eff+=0.08*c;if(c>=3)P.spd*=1.2;if(c>=6)P.crit+=0.1;break;
  case'smg':P.spread*=1+0.06*a;P.rate+=0.03*a;P.n+=(a>=3)+(a>=6);if(a>=9)P.splitAt=150;if(b>=3)P.rl*=0.8;if(c>0){P.bounce+=c>=3?2:1;P.dmg+=0.03*c;if(c>=6)P.bounceK=1.2;if(c>=9)P.homeAfter=3.2;}break;
  case'shotgun':P.n+=(a>=3)+(a>=6);P.spread*=Math.max(0.5,1-0.04*a);P.dmg+=0.03*a;if(a>=9)P.pierce+=1;if(b>0){P.ign=0.15+0.07*b;if(b>=3)P.ignK=1.5;}P.kb+=0.15*c+(c>=6?0.3:0);if(c>=3)P.stun=0.25;break;
  case'sniper':P.range+=0.12*a;if(a>=9)P.mark=5;P.dmg+=0.05*b;P.pierce+=(b>=3)+(b>=6);if(b>=9)P.wp=1;break;
  case'lmg':P.magMul+=0.12*a+(a>=3?0.15:0);P.rl*=(1-0.06*a)*(a>=6?0.85:1);if(b>0)P.slow=0.35+0.06*b+(b>=6?0.3:0);break;
  case'rocket':if(a>0)P.home=1.4+0.35*a;P.aoe+=0.09*b;P.aoeDmg+=0.05*b;if(b>=3)P.kb+=0.4;break;
  case'flame':P.range+=0.07*a;P.spread*=1+0.05*a;if(a>=3)P.dmg*=1.15;if(a>=9)P.dmg*=1.5;break;
  case'minigun':P.rate+=0.04*a+(a>=3?0.06:0);if(c>0)P.mark=0.5+0.15*c+(c>=6?1:0);if(c>=3)P.ign=0.05;break;
  case'autoshot':P.magMul+=0.12*a+(a>=6?0.2:0);if(a>=3)P.rl*=0.8;break;
  case'amr':P.dmg+=0.05*a;P.pierce+=(a>=3)+(a>=6);if(c>=9)P.mark=8;break;
  case'dual':P.rate+=0.07*a;if(a>=3)P.spd*=1.2;if(a>=6)P.magAdd+=6;P.rl*=Math.max(0.3,1-0.08*c);if(c>=3)P.magAdd+=4;break;
  case'revolver':if(a>0){P.bounce+=(a>=3)+(a>=6);P.bounceK=1+0.06*a;if(a>=9)P.homeAfter=3.6;}P.dmg+=0.06*c;if(c>0)P.slow=0.3;if(c>=3)P.kb+=0.4;break;
  case'gl':P.dmg+=0.06*b;P.aoe+=(a>=6?0.2:0)+(b>=6?0.2:0);break;
  case'rail':P.dmg+=0.06*a+(a>=6?0.1:0)+0.03*b;break;
  case'laser':P.dmg+=0.03*b;P.range+=0.06*c+(c>=6?0.1:0);break;}
  return P;}
function magSize(h){const W=WEAPONS[h.weapon.id];if(!W.mag)return 0;const P=evp(h);return Math.max(1,Math.round(W.mag*P.magMul)+P.magAdd);}
function startReload(h){const W=WEAPONS[h.weapon.id];if(!W.mag||h.reloadT>0)return;noise(h.x,h.y,'step',0.4,h);h.reloadDur=W.rl*h.st.rl*evp(h).rl;h.reloadT=h.reloadDur;const q=hamSnd(h);GSFX.reload(q.pan,q.vol,h.reloadDur);}
function wRange(h){const W=WEAPONS[h.weapon.id];if(W.kind==='melee'){const b=eL(h,'b');return b>0?220+30*b:W.reach;}return(W.range||0)*evp(h).range;}
function lightRange(h){let r=540*(h.tal.nightvision?1.6:1)*(h.st.lightK||1);if(h.weapon.id==='pistol')r*=1+0.1*eL(h,'c');if(h.weapon.id==='sniper')r*=1+0.12*eL(h,'a');return r;}
function lightCos(h){return 0.82-0.05*(h.st.wideK||0)-(h.weapon.id==='pistol'&&eL(h,'c')>=3?0.06:0);}
function spinMul(h){const a=eL(h,'a');return Math.max(0.3,(1-0.09*a)*(a>=6?0.85:1));}
function railChargeMul(h){const a=eL(h,'a');return Math.max(0.4,(1-0.05*a)*(a>=3?0.9:1));}
function deployNeed(h){return eL(h,'c')>=3?0.25:0.4;}
function moveMul(h,inp){const id=h.weapon.id,W=WEAPONS[id],b=eL(h,'b');let m=1;const firing=inp.fire&&h.reloadT<=0;
  if(W.slow&&firing)m*=id==='minigun'?Math.min(0.95,W.slow+0.05*b):W.slow;
  if(W.spinup&&h.spin>0.2&&!inp.fire)m*=0.8;
  if(id==='smg'&&firing)m*=1+0.04*b;return m;}

// ======== 通用小工具 ========
function stunE(e,d){if(e.kind==='ham'){e.stunT=Math.max(e.stunT||0,d*0.5);}else if(e.kind!=='base'&&e.kind!=='turret'&&!e.isProp)e.stun=Math.max(e.stun||0,d);}
function slowE(e,d){e.slowT=Math.max(e.slowT||0,e.kind==='ham'?d*0.5:d);}
function markE(e,team,d){if(!e||e.team===team)return;e.markTeam=team;e.markUntil=Math.max(e.markUntil||0,G.t+d);}
function visibleTo(team,e){return e.team===team||VIS[team].has(e);}
function foesSorted(h,R,cone){const out=[];const V=VIS[h.team];for(const L of [hams,minions,mobs,decoys])for(const e of L){if(L===hams?!e.alive:e.dead)continue;if(e.team===h.team||!V.has(e))continue;const dx=e.x-h.x,dy=e.y-h.y,d=Math.hypot(dx,dy);if(d>R)continue;if(cone&&Math.abs(angDiff(h.aim,Math.atan2(dy,dx)))>cone)continue;out.push({e,d:d*(L===hams?0.7:1)});}out.sort((p,q)=>p.d-q.d);return out.map(o=>o.e);}
function altTarget(h,R){const l=foesSorted(h,R,0);return l.length>1?l[1]:l[0]||null;}
function multiTargets(h,n,R){return foesSorted(h,R,1.2).slice(0,n);}
function miniBlast(x,y,R,dmg,team,o){addP({type:'flash',x,y,h:14,life:0.07,size:R*0.5,col:'#ffd27a',rot:rand(0,TAU),star:1});for(let i=0;i<fxn(5);i++){const a=rand(0,TAU),s=rand(80,220);addP({type:'ember',x,y,h:12,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(40,140),life:rand(0.3,0.6),size:1.2,col:'#ffb04a'});}ring(x,y,3,6,R*2.2,0.2,'#ffb066');
  hashRange(x,y,R+40,e=>{if(!canHit(team,e))return;if(Math.hypot(e.x-x,e.y-y)-e.r>R)return;dealDmg(e,dmg,{team,owner:o,x,y},true);});}
function wallSlam(e,dx,dy,o){if(e.kind==='base'||e.kind==='turret'||e.isProp)return;const px=e.x+dx*(e.r+34),py=e.y+dy*(e.r+34);if(pointSolid(px,py,4)){stunE(e,0.8);dealDmg(e,20,{team:o.team,owner:o,x:e.x,y:e.y});sparks(px,py,e.r,'#ffffff',fxn(8));ring(px,py,e.r,6,120,0.2,'#ffffff');pop(e.x,e.y,e.r*2.6,'撞墙！','#ffd166',15,0.7);SFX.thud();}}
function homeB(b,dt){b.htT=(b.htT||0)-dt;let t=b.htgt;if(t&&(t.dead||(t.kind==='ham'&&!t.alive)))t=b.htgt=null;
  if(!t&&b.htT<=0){b.htT=0.15;const sp0=Math.atan2(b.vy,b.vx);let best=null,bd=520*520;hashRange(b.x,b.y,520,e=>{if(!canHit(b.team,e)||e.isProp||e.kind==='crate'||e.kind==='base'&&e.shielded)return;if(b.team!=='neutral'&&e.team!=='neutral'&&!VIS[b.team].has(e))return;const dx=e.x-b.x,dy=e.y-b.y,d=dx*dx+dy*dy;if(d<bd&&Math.abs(angDiff(sp0,Math.atan2(dy,dx)))<1.3){bd=d;best=e;}});b.htgt=t=best;}
  if(!t)return;const sp=Math.hypot(b.vx,b.vy),cur=Math.atan2(b.vy,b.vx),want=Math.atan2(t.y-b.y,t.x-b.x),na=turnTo(cur,want,b.home*dt);b.vx=Math.cos(na)*sp;b.vy=Math.sin(na)*sp;}
function splitB(b){const a=Math.atan2(b.vy,b.vx),sp=Math.hypot(b.vx,b.vy);for(const k of [-1,1]){const nb=Object.assign({},b);nb.vx=Math.cos(a+k*0.2)*sp;nb.vy=Math.sin(a+k*0.2)*sp;nb.dmg=b.dmg*0.7;nb.splitAt=0;nb.hit=new Set(b.hit);nb.x0=b.x0;nb.y0=b.y0;nb.fx=b.fx;bullets.push(nb);}sparks(b.x,b.y,b.h,'#ffe2a8',fxn(3));}
function teleFx(x,y,team){ring(x,y,3,8,240,0.4,'#7fe3ff');for(let i=0;i<fxn(14);i++){const a=rand(0,TAU),s=rand(60,200);addP({type:'star',x,y,h:rand(6,40),vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(60,200),life:rand(0.4,0.8),size:rand(5,8),col:'#9fe8ff',glow:1});}flashL('flash',x,y,30,2,0.2);}
function decoyPop(d){for(let i=0;i<fxn(12);i++){const a=rand(0,TAU),s=rand(80,240);addP({type:'dot',x:d.x,y:d.y,h:d.r*1.4,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(80,220),life:rand(0.4,0.8),size:3,col:TCOL[d.team]});}ring(d.x,d.y,d.r,8,160,0.25,'#ffffff');pop(d.x,d.y,d.r*3,'噗！','#ffffff',16,0.7);SFX.boing(false);}

// ======== 开火 ========
function fireWeapon(h,extra){
  const id=h.weapon.id,W=WEAPONS[id],st=h.st,P=evp(h),a=eL(h,'a'),b=eL(h,'b'),c=eL(h,'c'),a0=h.aim,co=Math.cos(a0),si=Math.sin(a0),rx=-si,ry=co,R=h.r,gh=R+(h.z||0),K=FXK,q=hamSnd(h);
  const berserk=h.tal.berserk&&h.hp<h.maxHp*0.4,still=h.steadyT>=(c>=3?0.4:0.6),deployed=h.deployT>=deployNeed(h);
  let rate=(W.spinup?6+(W.rate-6)*h.spin:W.rate)*st.rate*P.rate*(berserk?1.3:1)*(h.hasteT>0?1.3:1);
  if(id==='autoshot'&&c>0)rate*=1+Math.min(0.2+0.04*c+(c>=6?0.1:0),h.ramp*0.04*(c>=3?1.5:1));
  if(id==='lmg'&&c>=6&&deployed)rate*=1.15;
  if(!extra)h.fireCd=1/rate;
  if(W.dual)h.dualSide=-h.dualSide;
  const pause=G.t-h.lastShotT;
  let dmg=W.dmg*st.dmg*P.dmg*(berserk?1.4:1),critAdd=P.crit,forceCrit=false,pierce=(W.pierce||0)+P.pierce;
  if(id==='ak47'&&b>=9)dmg*=1+Math.min(0.4,h.ramp*0.02);
  if(id==='deagle'&&b>=9&&pause<0.5)dmg*=1.5;
  if(id==='sniper'&&c>0&&still){dmg*=1+0.08*c;if(c>=6)critAdd+=0.15;if(c>=9)forceCrit=true;}
  if(id==='lmg'&&c>0&&deployed)dmg*=1+0.05*c;
  if(id==='revolver'&&c>=9&&(h.shotN+1)%6===0)forceCrit=true;
  if(h.deadeyeShot){dmg*=1+0.05*b;if(b>=6)pierce+=1;if(b>=9)forceCrit=true;}
  if(id==='ak47'&&c>=9&&pause>0.5){dmg*=2;pierce+=2;}
  h.lastShotT=G.t;h.shotN++;if(id==='ak47'||id==='autoshot')h.ramp=Math.min(h.ramp+1,40);
  let use=!!W.mag;if(use&&h.tal.bottomless&&Math.random()<0.35)use=false;if(use&&id==='lmg'&&a>=9&&Math.hypot(h.vx,h.vy)<25)use=false;
  if(use&&W.kind!=='flame')h.ammo--;else if(use)h.ammo--;
  const so=W.dual?h.dualSide*0.42:0.14,ln=MUZ[id]||2,gx=h.x+co*R*ln+rx*R*so,gy=h.y+si*R*ln+ry*R*so,bx=h.x+co*R*0.8+rx*R*so,by=h.y+si*R*0.8+ry*R*so,tb=h.team==='blue'?'_b':'_r';
  let range=(W.range||0)*P.range;
  if(W.kind==='bullet'){
    const shotty=id==='shotgun'||id==='autoshot',n=(W.n||1)+st.multi+P.n,base=shotty?W.spread*P.spread:(W.spread+h.bloom)*P.spread*(id==='lmg'&&deployed?0.6:1),sp=n>1&&!shotty?base+0.06*(n-1):base;
    const kind=(id==='sniper'||id==='amr')?'snipe':shotty?'pel'+tb:'trc'+tb;
    let aim=a0;if(id==='dual'&&b>0&&h.dualSide<0&&Math.random()<(b>=9?1:0.25+0.08*b)){const t2=altTarget(h,b>=3?600:450);if(t2)aim=Math.atan2(t2.y-gy,t2.x-gx);}
    const mode=id==='ak47'&&a>=9?h.shotN%3:-1,dragon=id==='autoshot'&&c>=9&&h.ammo<5;
    if(id==='amr'&&a>=9)range=WW*1.2;
    for(let i=0;i<n;i++){const off=n===1?rand(-sp,sp):(i/(n-1)-0.5)*2*sp+rand(-0.03,0.03);
      const bl=mkBullet(kind,h,bx,by,gh,aim+off,W.spd*P.spd*rand(0.95,1.05),dmg*(i>0&&id==='smg'?0.85:1)*(id==='dual'&&h.dualSide<0&&b>=6?1.2:1),range,{eff:W.eff?Math.min(1,W.eff*P.eff):1,minF:W.minF,pierce:pierce+(mode===1?2:0),kb:W.kb*P.kb,r:(id==='sniper'||id==='amr')?5:4.5,bounce:(W.bounce||0)+P.bounce,wp:(id==='amr'&&a>=9)?2:((W.wallPierce||0)||P.wp)});
      bl.fx={src:id,lv:[a,b,c],ign:mode===0?1:P.ign+(dragon?0.6:0),ignK:P.ignK,slow:P.slow,stun:P.stun,mark:P.mark,crit:critAdd,force:forceCrit,expl:mode===2?1:0};bl.bounceK=P.bounceK;bl.homeAfter=P.homeAfter;if(P.splitAt)bl.splitAt=P.splitAt;
      if(id==='minigun'&&c>=9&&h.shotN%10===0)bl.fx.expl=1;
      bullets.push(bl);}
    gunFx(h,W,gx,gy,gh);GSFX.shot(W.snd,q.pan,q.vol);
    if(id==='shotgun'){GSFX.pump(q.pan,q.vol);h.vx-=co*120;h.vy-=si*120;if(b>=9)fires.push({x:h.x+co*170,y:h.y+si*170,r:70,t:0,life:2.5,team:h.team,owner:h,dps:16,tick:0});}
    else if(id==='sniper'){GSFX.bolt(q.pan,q.vol);sniperTrail(gx,gy,gh,a0,range);h.vx-=co*70;h.vy-=si*70;}
    else if(id==='deagle'){const fk=b>0?Math.max(0.3,1-0.08*b):1;h.flipT*=fk;h.vx-=co*60;h.vy-=si*60;}
    else if(id==='amr'){GSFX.bolt(q.pan,q.vol);sniperTrail(gx,gy,gh,a0,Math.min(range,2400));h.vx-=co*W.selfKb;h.vy-=si*W.selfKb;setWave(gx,gy,0.3,0.5,0.45);if(c>0){const L2=Math.min(range,2400);corrs.push({x0:gx,y0:gy,x1:gx+co*L2,y1:gy+si*L2,w:c>=3?90:60,until:G.t+2+0.3*c+(c>=6?1:0),team:h.team});}}
    if(id==='pistol'&&a>=9&&!extra){h.burstN=2;h.burstT=0.07;}
  }else if(W.kind==='rocket'){
    const aoe=W.aoe*P.aoe,aD=W.aoeDmg*P.aoeDmg*st.dmg;
    const mk=(ang,dm,tgt)=>{const r0=mkBullet('rocket',h,bx,by,gh,ang,W.spd*(a>0?0.85:1),dm,range,{aoe,aoeDmg:aD*(dm/dmg),kb:W.kb*P.kb,r:7});r0.fx={src:'rocket',lv:[a,b,c]};r0.home=P.home;r0.htgt=tgt||null;bullets.push(r0);};
    if(a>=9){const ts=multiTargets(h,3,820);for(let i=0;i<3;i++)mk(a0+(i-1)*0.25,dmg*0.6,ts[i]||null);h.fireCd*=1.3;}
    else if(c>=9){mk(a0-0.12,dmg,null);mk(a0+0.12,dmg,null);}else mk(a0,dmg,null);
    gunFx(h,W,gx,gy,gh);GSFX.rocket(q.pan,q.vol);h.vx-=co*90;h.vy-=si*90;
    for(let i=0;i<fxn(6);i++)addP({type:'smoke',x:h.x-co*R*1.2,y:h.y-si*R*1.2,h:gh,vx:-co*rand(80,200)+rand(-30,30),vy:-si*rand(80,200)+rand(-30,30),vh:rand(5,30),life:rand(0.5,0.9),size:rand(10,16),grow:34,col:'#9a94ac'});
    addP({type:'flash',x:h.x-co*R*1.4,y:h.y-si*R*1.4,h:gh,life:0.06,size:16,col:'#ffd27a',dir:a0+Math.PI,cone:2.2,rot:rand(0,TAU)});
  }else if(W.kind==='lob'){
    if(b>=9){const mine=lobs.filter(l=>l.owner===h&&l.sticky);if(mine.length){for(const l of mine)l.fuse=0.01;h.fireCd=0.25;return;}}
    let tx,ty;if(h.dev==='kbm'&&mouse.has&&h.view){tx=h.mwx;ty=h.mwy;}else{const t=h.ctl==='ai'?h.ai.target:autoAim(h,560);if(t){tx=t.x;ty=t.y;}else{tx=h.x+co*360;ty=h.y+si*360;}}
    const dx=tx-h.x,dy=ty-h.y,d=Math.hypot(dx,dy)||1,dd=clamp(d,90,W.range*P.range);
    let sp2=null;if(c>0){h.glN=(h.glN||0)+1;const rot=c>=6?['smoke','flash','fire']:c>=3?['smoke','flash']:['smoke'];sp2=c>=3||h.glN%3===0?rot[h.glN%rot.length]:null;}
    throwLob(h,'gnade',h.x+dx/d*dd,h.y+dy/d*dd,{sp:560*(a>=3?1.25:1),fuse:b>=9?6:W.fuse+0.15*a,aoe:W.aoe*P.aoe,dmg:W.aoeDmg*P.dmg*st.dmg,kb:W.kb,impact:b===0});
    const L0=lobs[lobs.length-1];L0.bounceN=a>0?1+Math.floor(a/3):0;L0.splitOnBounce=a>=9;L0.sticky=b>0;L0.slowStick=b>=3;L0.special=sp2;L0.gas=c>=9;L0.owner=h;
    gunFx(h,W,gx,gy,gh);GSFX.shot('gl',q.pan,q.vol);
  }else if(W.kind==='melee'){
    h.swingT=0.22;h.swingDir=-h.swingDir;h.swingN=(h.swingN||0)+1;h.swingStart=G.t;const reach=W.reach,arc=W.arc*(1+0.08*a);GSFX.swish(q.pan,q.vol);
    hashRange(h.x,h.y,reach+60,e=>{if(!canHit(h.team,e))return;const dx=e.x-h.x,dy=e.y-h.y,dd=Math.hypot(dx,dy)-e.r;if(dd>reach)return;if(Math.abs(angDiff(a0,Math.atan2(dy,dx)))>arc/2&&dd>e.r*0.5)return;
      if(dealDmg(e,dmg,{team:h.team,owner:h,x:h.x,y:h.y})>0){knock(e,dx,dy,W.kb);onHitFx(e.x,e.y,e.r,'#e8f4ff',true);hitMark(h,e);}});
    if(b>0){const big=b>=9&&h.swingN%3===0,wr=(b>=6?1.5:1)*(big?1.8:1),mkW=(ang)=>{const w=mkBullet('swave',h,h.x+co*R,h.y+si*R,R,ang,720,dmg*0.5*(1+0.06*b)*(big?1.5:1),220+30*b,{r:14*wr,kb:120,pierce:b>=3||big?99:0});w.fx={src:'katana',lv:[a,b,c]};w.wr=wr;w.col=big?'#ff9ff0':'#c9b8ff';bullets.push(w);};
      if(big){mkW(a0-0.5);mkW(a0+0.5);}else mkW(a0);}
    slashFx(h,a0,reach,arc);shakeAt(h.x,h.y,0.08*K,h);kickV(h,a0,-4);h.kick.w-=20;
  }else{
    const fr=W.range*P.range,spr=W.spread*P.spread,blue=a>=9;
    for(let i=0;i<1+Math.floor(st.multi/2);i++){const fb=mkBullet('flame',h,gx,gy,gh,a0+rand(-spr,spr),W.spd*rand(0.85,1.1)*(blue?1.25:1),dmg,fr,{r:11,kb:W.kb*(a>=6?4:1)});fb.fx={src:'flame',lv:[a,b,c],burn:2.5+0.3*b,spread:b>=9,blue};bullets.push(fb);}
    if(b>=3&&G.t-(h.puddleT||0)>0.8){h.puddleT=G.t;fires.push({x:h.x+co*fr*0.8,y:h.y+si*fr*0.8,r:b>=6?65:45,t:0,life:2,team:h.team,owner:h,dps:10,tick:0});}
    if(c>0){const rr=fr*(c>=6?1:0.5+0.04*c+(c>=3?0.15:0));for(let i=bullets.length-1;i>=0;i--){const bl=bullets[i];if(bl.team===h.team||bl.kind==='flame'||bl.kind==='rocket'||bl.kind==='swave')continue;const dx=bl.x-h.x,dy=bl.y-h.y,dd=Math.hypot(dx,dy);if(dd>rr||Math.abs(angDiff(a0,Math.atan2(dy,dx)))>0.5)continue;sparks(bl.x,bl.y,bl.h,'#ffb04a',2);bullets[i]=bullets[bullets.length-1];bullets.pop();}}
    if(c>=9){h.flameT+=1/rate;if(h.flameT>=3){h.flameT=0;blast(h.x,h.y,170,90*st.dmg,h.team,h,300);}}
    if(Math.random()<0.3)flashL('flash',gx,gy,gh+10,1.2*K,0.08);GSFX.flame(q.pan,q.vol);
  }
  h.heat=Math.min(1,h.heat+0.08);
}
function tryFire(h,inp,canShoot,dt){const id=h.weapon.id,W=WEAPONS[id];
  if(id==='revolver'&&eL(h,'b')>0){deadeye(h,inp,canShoot,dt);return;}
  if(inp.fire&&h.fireCd<=0&&canShoot&&(!W.spinup||h.spin>0.3))fireWeapon(h);}
function deadeyePick(h){const l=foesSorted(h,700,0.62);for(const e of l)if(!h.marks.includes(e))return e;return l[0]||null;}
function releaseDeadeye(h){const a0=h.aim;h.deadeyeShot=true;for(const t of h.marks){if(h.ammo<=0)break;if(t.dead||(t.kind==='ham'&&!t.alive))continue;h.aim=Math.atan2(t.y-h.y,t.x-h.x);fireWeapon(h,true);}h.deadeyeShot=false;h.aim=a0;h.marks=[];h.fireCd=0.45;h.markHold=0;h.markAcc=0;}
function deadeye(h,inp,canShoot,dt){const b=eL(h,'b');
  if(inp.fire&&canShoot){h.markHold+=dt;if(h.markHold>0.15){const iv=(b>=3?0.25:0.35)*(b>=9?0.5:1);h.markAcc=(h.markAcc||0)+dt;if(h.markAcc>=iv&&h.marks.length<Math.min(6,h.ammo)){h.markAcc=0;const t=deadeyePick(h);if(t){h.marks.push(t);pop(t.x,t.y,t.r*2.6,'◎','#ff5b5b',16,0.6);GSFX.hit(0,0.5);}}}
    if(h.markHold>1.6)releaseDeadeye(h);}
  else{if(h.markHold>0){if(h.marks.length)releaseDeadeye(h);else if(h.markHold<=0.15&&h.fireCd<=0&&canShoot)fireWeapon(h);}h.markHold=0;h.markAcc=0;}}

// ======== 命中 ========
function onBulletHit(b,e){
  if(b.kind==='rocket'){explode(b);return;}
  let dm=b.dmg;if(b.eff<1){const d=Math.hypot(b.x-b.x0,b.y-b.y0),e0=b.maxD*b.eff;if(d>e0)dm*=lerp(1,b.minF,clamp((d-e0)/Math.max(1,b.maxD-e0),0,1));}
  const f=b.fx||{},o=b.owner,lv=f.lv||[0,0,0];
  if(o&&o.kind==='ham'){
    if(f.src==='deagle'&&lv[2]>0&&e.hp<e.maxHp*(lv[2]>=3?0.5:0.4))dm*=(1+0.08*lv[2])*(lv[2]>=6?1.15:1);
    if(f.src==='pistol'&&lv[2]>=6&&VIS[o.team].has(e))dm*=1.1;
    if(f.src==='ak47'&&lv[0]>=6&&(e.kind==='turret'||e.kind==='base'))dm*=1.3;
    if(f.src==='amr'&&lv[1]>=9&&(e.kind==='turret'||e.kind==='base'))dm*=2;}
  if(dealDmg(e,dm,{team:b.team,owner:o,by:b.by,x:b.x,y:b.y,critAdd:f.crit||0,forceCrit:f.force})>0&&o)hitMark(o,e);
  const l=Math.hypot(b.vx,b.vy)||1,ux=b.vx/l,uy=b.vy/l;knock(e,ux,uy,b.kb);
  if(b.kind==='flame'){e.burnT=Math.max(e.burnT||0,f.burn||2.5);e.burnBy=o;if(f.spread)e.burnSpread=G.t+3;return;}
  if(b.kind==='swave'){onHitFx(b.x,b.y,b.h,'#d9c8ff',true);return;}
  const big=b.kind==='snipe'||b.kind.startsWith('trc')||b.kind.startsWith('seed');onHitFx(b.x,b.y,b.h,b.kind==='snipe'?'#bff4ff':b.team==='blue'?'#bfe0ff':b.team==='red'?'#ffc8c8':'#ffb3e6',big);SFX.hit();
  if(o&&o.kind==='ham'&&o.alive){
    if(f.ign&&Math.random()<f.ign){e.burnT=Math.max(e.burnT||0,2.2);e.burnBy=o;e.burnK=f.ignK||1;if(f.src==='shotgun'&&lv[1]>=6)slowE(e,1);}
    if(f.slow){slowE(e,f.slow);if(f.src==='lmg'){if(lv[1]>=9)e.suppT=G.t+1.2;if(lv[1]>=3)hashRange(b.x,b.y,70,q=>{if(q!==e&&canHit(o.team,q)&&!q.isProp&&q.kind!=='crate')slowE(q,f.slow*0.6);});}}
    if(f.stun)stunE(e,f.stun);
    if(f.mark)markE(e,o.team,f.mark);if(o.st.recon>0)markE(e,o.team,o.st.recon);
    if(f.expl)miniBlast(b.x,b.y,f.src==='minigun'?60:45,dm*(f.src==='minigun'?0.9:0.5),b.team,o);
    if(f.src==='deagle'&&lv[0]>=9)wallSlam(e,ux,uy,o);
    if(f.src==='shotgun'&&lv[2]>=9&&Math.hypot(e.x-o.x,e.y-o.y)<90+e.r){knock(e,ux,uy,520);stunE(e,0.8);}
    if(f.src==='autoshot'&&lv[1]>0&&Math.random()<0.1+0.05*lv[1]+(lv[1]>=6?0.1:0)){miniBlast(b.x,b.y,lv[1]>=3?45:32,dm*0.5,b.team,o);if(lv[1]>=9)for(const k of [-1,1]){const nb=mkBullet(b.kind,o,b.x,b.y,b.h,Math.atan2(uy,ux)+k*0.8,600,dm*0.4,160,{r:3.5,kb:20});nb.hit.add(e);bullets.push(nb);}}
    if(f.src==='revolver'&&lv[2]>=6&&e.kind==='ham'&&e.reloadT>0)e.reloadT+=0.5;
    if(o.st.frost>0)slowE(e,0.8+0.3*o.st.frost);
    if(o.st.chain>0&&Math.random()<o.st.chain)chainLightning(e,b.dmg*0.45,o);}
}
function explode(b){const f=b.fx||{},lv=f.lv||[0,0,0],R=b.aoe;rocketBoom(b.x,b.y,b.h,R);let hit=null;
  hashRange(b.x,b.y,R+60,e=>{if(!canHit(b.team,e))return;const d=Math.hypot(e.x-b.x,e.y-b.y)-e.r;if(d>R)return;const k=1-Math.max(0,d)/R*0.5;if(dealDmg(e,(b.aoeDmg+b.dmg)*k,{team:b.team,owner:b.owner,by:b.by,x:b.x,y:b.y})>0)hit=e;knock(e,e.x-b.x,e.y-b.y,b.kb*k);if(f.src==='rocket'&&lv[1]>=6)slowE(e,1.2);});
  if(f.src==='rocket'&&lv[2]>0){const n=Math.min(5,2+(lv[2]>=3)+(lv[2]>=6));for(let i=0;i<n;i++){const ang=i/n*TAU+rand(-0.3,0.3),dist=rand(70,130);throwLob({x:b.x,y:b.y,r:6,team:b.team,kind:'x'},'bomb',b.x+Math.cos(ang)*dist,b.y+Math.sin(ang)*dist,{sp:300,fuse:0.55,aoe:55,dmg:(b.aoeDmg+b.dmg)*0.25*(1+0.08*lv[2]),kb:120});lobs[lobs.length-1].owner=b.owner;}}
  if(f.src==='rocket'&&lv[1]>=9)fires.push({x:b.x,y:b.y,r:R*0.7,t:0,life:4,team:b.team,owner:b.owner,dps:18,tick:0});
  if(hit&&b.owner)hitMark(b.owner,hit);}

// ======== 武士刀 / 机枪 / 手枪 特殊 ========
function katanaDeflect(h,a,perfect){const W=WEAPONS.katana,reach=W.reach+12,arc=W.arc*(1+0.08*a),full=h.rollT>0&&h.swingT<=0,tb=h.team==='blue'?'_b':'_r';let n=0;
  for(const bl of bullets){if(bl.team===h.team||bl.kind==='flame'||bl.kind==='swave')continue;const dx=bl.x-h.x,dy=bl.y-h.y;if(dx*dx+dy*dy>reach*reach)continue;if(!full&&Math.abs(angDiff(h.aim,Math.atan2(dy,dx)))>arc/2)continue;
    const shooter=bl.by,sp=Math.hypot(bl.vx,bl.vy),ang=full?Math.atan2(dy,dx):h.aim;bl.vx=Math.cos(ang)*sp*1.1;bl.vy=Math.sin(ang)*sp*1.1;bl.team=h.team;bl.owner=h;bl.by=h;bl.dmg*=(1.2+0.1*a)*(perfect?3:1);bl.hit=new Set();bl.life=Math.max(bl.life,0.9);if(bl.kind==='orb'||bl.kind==='rat'||bl.kind.startsWith('mpea')||bl.kind.startsWith('seed'))bl.kind='trc'+tb;
    if(a>=3&&shooter&&shooter.kind){bl.home=3.5;bl.htgt=shooter;}sparks(bl.x,bl.y,bl.h,'#9fe8ff',3);n++;}
  if(n){const q=hamSnd(h);GSFX.ting(q.pan,q.vol);pop(h.x,h.y,h.r*3,perfect?'完美格挡！':'反弹！',perfect?'#ffd166':'#9fe8ff',perfect?17:13,0.5);if(perfect){h.iframes=Math.max(h.iframes,0.6);ring(h.x,h.y,h.r,h.r,200,0.3,'#ffd166');}}}
function iaido(h,c){const W=WEAPONS.katana,dmg=W.dmg*h.st.dmg*(0.4+0.08*c);hashRange(h.x,h.y,h.r+40,e=>{if(h.iaidoHit.has(e)||!canHit(h.team,e)||e.kind==='base'||e.kind==='turret'||e.isProp)return;if(Math.hypot(e.x-h.x,e.y-h.y)<h.r+e.r+10){h.iaidoHit.add(e);dealDmg(e,dmg,{team:h.team,owner:h,x:h.x,y:h.y});slashes.push({x:e.x,y:e.y,h:e.r,a:Math.atan2(h.rdy,h.rdx),reach:40,arc:1.2,dir:1,t:0,life:0.15});hitMark(h,e);}});}
function frontShield(h){for(let i=bullets.length-1;i>=0;i--){const bl=bullets[i];if(bl.team===h.team||bl.kind==='flame')continue;const dx=bl.x-h.x,dy=bl.y-h.y;if(dx*dx+dy*dy>52*52)continue;if(Math.abs(angDiff(h.aim,Math.atan2(dy,dx)))>0.9)continue;sparks(bl.x,bl.y,bl.h,'#9fe8ff',3);bullets[i]=bullets[bullets.length-1];bullets.pop();}}
function dazzle(h){const cs=Math.cos(h.aim),sn=Math.sin(h.aim);for(const L of [hams,minions,mobs])for(const e of L){if(L===hams?!e.alive:e.dead)continue;if(e.team===h.team)continue;const dx=e.x-h.x,dy=e.y-h.y,d=Math.hypot(dx,dy);if(d>200||d<1)continue;if((dx*cs+dy*sn)/d<0.8||!hasLOS(h.x,h.y,e.x,e.y))continue;if((e.dazzleUntil||0)>G.t)continue;e.dazzleUntil=G.t+2;
  if(e.kind==='ham'){if(e.view)e.view.flashT=Math.max(e.view.flashT||0,0.35);else e.blindT=Math.max(e.blindT,0.7);}else stunE(e,0.5);pop(e.x,e.y,e.r*2.6,'晃！','#fff6c2',13,0.5);}}
function evoTick(h,dt,inp){const id=h.weapon.id,a=eL(h,'a'),c=eL(h,'c');
  if(h.stunT>0){h.stunT-=dt;inp.fire=false;inp.dash=false;h.vx*=0.85;h.vy*=0.85;h.x+=h.vx*dt;h.y+=h.vy*dt;resolveCircle(h,h.r);if(Math.random()<dt*8)addP({type:'star',x:h.x+rand(-10,10),y:h.y+rand(-10,10),h:h.r*2.4,vh:20,life:0.4,size:6,col:'#ffd166',glow:1,grav:0});return true;}
  if(h.eshieldT>0){h.eshieldT-=dt;if(h.eshieldT<=0)h.eshield=0;}
  if(h.medT>0){h.medT-=dt;h.hp=Math.min(h.maxHp,h.hp+h.medRate*dt);h.munchT=Math.max(h.munchT,0.15);if(Math.random()<dt*6)addP({type:'star',x:h.x+rand(-12,12),y:h.y+rand(-12,12),h:rand(20,40),vh:50,life:0.6,size:6,col:'#8de0a6',glow:1,grav:0});}
  if(h.jetT>0){h.jetT-=dt;for(let i=0;i<2;i++)addP({type:'fire',x:h.x-Math.cos(h.aim)*h.r*0.8+rand(-4,4),y:h.y-Math.sin(h.aim)*h.r*0.8+rand(-4,4),h:(h.z||0)+h.r*1.2,vx:rand(-20,20),vy:rand(-20,20),vh:rand(-120,-60),life:0.25,size:rand(8,12)});}
  if(h.hasteT>0)h.hasteT-=dt;
  if(h.st.regen>0&&Math.random()<dt*3)addP({type:'star',x:h.x+rand(-14,14),y:h.y+rand(-14,14),h:rand(10,34),vh:30,life:0.6,size:4,col:'#8de0a6',glow:1,grav:0});
  const still=Math.hypot(h.vx,h.vy)<25&&inp.ml<0.1;h.steadyT=still?h.steadyT+dt:0;h.deployT=still?h.deployT+dt:0;
  if(!inp.fire){h.flameT=0;if(G.t-h.lastShotT>0.6)h.ramp=0;}
  if(h.burstN>0){h.burstT-=dt;if(h.ammo<=0)h.burstN=0;else if(h.burstT<=0){h.burstN--;h.burstT=0.07;fireWeapon(h,true);}}
  if(id==='katana'){if(h.swingT>0||(a>=6&&h.rollT>0))katanaDeflect(h,a,a>=9&&h.swingT>0&&(0.22-h.swingT)<0.08);if(c>0&&h.rollT>0&&h.iaidoHit)iaido(h,c);}
  if(id==='lmg'&&c>=9&&h.deployT>=deployNeed(h))frontShield(h);
  if(id==='pistol'&&c>=9){h.dazzleT-=dt;if(h.dazzleT<=0){h.dazzleT=0.3;dazzle(h);}}
  return false;}
function startDash(h,inp){let dx=inp.mx,dy=inp.my;if(Math.hypot(dx,dy)<0.2){dx=Math.cos(h.aim);dy=Math.sin(h.aim);}const l=Math.hypot(dx,dy)||1;h.rdx=dx/l;h.rdy=dy/l;h.rollT=0.3;
  const id=h.weapon.id,a=eL(h,'a'),b=eL(h,'b'),c=eL(h,'c'),W=WEAPONS[id];let cdm=1;if(id==='smg'&&b>=6)cdm*=0.8;if(id==='katana'&&c>=3)cdm*=0.75;h.dashCd=h.st.dashCd*cdm;h.dashSpd=id==='katana'&&c>=6?1.25:1;
  h.iframes=0.3;h.sq.v=0.75;h.sq.w=0;h.dashHit=new Set();h.iaidoHit=new Set();SFX.roll();if(h.tal.phantom)h.invisT=1.5;
  for(let i=0;i<fxn(6);i++)addP({type:'smoke',x:h.x+rand(-8,8),y:h.y+rand(-6,6),h:4,vx:-h.rdx*rand(30,90)+rand(-30,30),vy:-h.rdy*rand(30,90)+rand(-30,30),vh:rand(10,30),life:rand(0.3,0.5),size:rand(9,14),grow:22,col:'#e9dfcc'});
  if(id==='smg'&&b>=9){h.ammo=magSize(h);h.reloadT=0;h.hasteT=3;}
  if(id==='autoshot'&&a>=9){const m=magSize(h);h.ammo=Math.min(m,h.ammo+Math.ceil(m*0.5));h.reloadT=0;}
  if(id==='dual'&&c>=9&&h.ammo<=0){h.ammo=magSize(h);h.reloadT=0;}
  if(id==='dual'&&a>=9){const tb=h.team==='blue'?'_b':'_r';for(let k=0;k<8;k++){const bl=mkBullet('trc'+tb,h,h.x,h.y,h.r,k/8*TAU,1100,W.dmg*h.st.dmg,500,{r:4.5,kb:60});bl.fx={src:'dual',lv:[a,b,c]};bullets.push(bl);}const q=hamSnd(h);GSFX.shot('pistol',q.pan,q.vol);}}
function onKill(t,src){if(t.kind==='decoy'){t.dead=true;decoyPop(t);return;}const K=src.owner&&src.owner.kind==='ham'?src.owner:null;if(!K||t.team===K.team||t.kind==='crate'||t.isProp)return;const id=K.weapon.id;
  if(id==='deagle'&&eL(K,'c')>=9){K.ammo=Math.min(magSize(K),K.ammo+1);K.fireCd=0;}
  if(id==='katana'&&eL(K,'c')>=9)K.dashCd=0;
  if(id==='dual'&&eL(K,'c')>=6){const m=magSize(K);K.ammo=Math.min(m,K.ammo+Math.ceil(m*0.25));}}

// ======== 电磁炮 / 激光 ========
function fireRail(h){h.revealT=0.45;noise(h.x,h.y,'gun',1.1,h);const W=WEAPONS.rail,a=eL(h,'a'),b=eL(h,'b'),c=eL(h,'c'),P=evp(h),co=Math.cos(h.aim),si=Math.sin(h.aim),R=h.r,ch=h.charge;h.charge=0;h.chHold=0;h.ammo--;h.fireCd=0.3;
  const gh=R+(h.z||0),dmg=(W.dmg+140*ch)*P.dmg*h.st.dmg,range=W.range*P.range;let walls=b>=6?99:b>=3?2:b>=1?1:0,refl=b>=9?1:0,x=h.x+co*R*2.4,y=h.y+si*R*2.4,dx=co,dy=si,left=range;const segs=[];
  while(left>0&&segs.length<4){let L=0,inS=null,stop=false;while(L<left){const px=x+dx*L,py=y+dy*L,sd=pointSolid(px,py,1);if(sd&&sd!==inS){if(sd.prop)propHit(sd.prop,dmg*0.5,h);if(sd.kind==='wall'){if(refl>0){refl--;segs.push([x,y,px,py]);const nx=Math.abs(px-MIDX)>WW/2-80?-1:1,ny=Math.abs(py-MIDY)>WH/2-80?-1:1;x=px-dx*12;y=py-dy*12;if(nx<0)dx=-dx;if(ny<0)dy=-dy;left-=L;L=-1;break;}stop=true;break;}if(walls>0){walls--;inS=sd;}else{stop=true;break;}}else if(!sd)inS=null;L+=10;}
    if(L===-1)continue;segs.push([x,y,x+dx*Math.min(L,left),y+dy*Math.min(L,left)]);break;}
  const hitSet=new Set();let last=null;
  for(const sg of segs){const sx=sg[2]-sg[0],sy=sg[3]-sg[1],sl=Math.hypot(sx,sy)||1,ux=sx/sl,uy=sy/sl;
    for(const list of [hams,minions,mobs,structs,crates,decoys])for(const e of list){if(hitSet.has(e)||!canHit(h.team,e))continue;const t=clamp((e.x-sg[0])*ux+(e.y-sg[1])*uy,0,sl),px=sg[0]+ux*t,py=sg[1]+uy*t;if(Math.hypot(e.x-px,e.y-py)<e.r+10*(0.5+ch)){hitSet.add(e);if(dealDmg(e,dmg,{team:h.team,owner:h,x:px,y:py})>0)last=e;knock(e,ux,uy,W.kb*ch);onHitFx(e.x,e.y,e.r,'#bff4ff',true);
      if(c>0){slowE(e,0.6+0.1*c+(c>=6?0.4:0));if(e.kind==='ham'&&e.reloadT>0)e.reloadT+=0.4;if(c>=3&&e.kind==='turret')e.cd=Math.max(e.cd,1);}
      if(a>=9&&ch>=0.99)chainLightning(e,dmg*0.4,h);}}
    for(const p of props){if(p.dead)continue;const t=clamp((p.x-sg[0])*ux+(p.y-sg[1])*uy,0,sl);if(Math.hypot(p.x-sg[0]-ux*t,p.y-sg[1]-uy*t)<p.r+12)propHit(p,dmg,h);}
    beams.push({x0:sg[0],y0:sg[1],x1:sg[2],y1:sg[3],h:gh,t:0,life:0.4,w:3+6*ch,col:h.team});
    if(c>=9)zones.push({seg:sg,w:26,until:G.t+3,team:h.team,owner:h,dps:20,tick:0});
    for(let i=0;i<fxn(10*ch+4);i++){const k=Math.random()*sl;addP({type:'star',x:sg[0]+ux*k,y:sg[1]+uy*k,h:gh+rand(-4,4),vx:rand(-30,30),vy:rand(-30,30),vh:rand(10,50),life:rand(0.3,0.6),size:rand(4,7),col:'#9fe8ff',glow:1,grav:0});}}
  if(last)hitMark(h,last);const s0=segs[0];addP({type:'flash',x:s0[0],y:s0[1],h:gh,life:0.1,size:26+20*ch,col:'#bff4ff',dir:h.aim,cone:3,rot:rand(0,TAU)});flashL('flash',s0[0],s0[1],gh+12,3.5*FXK,0.12);
  shakeAt(h.x,h.y,(0.15+0.3*ch)*FXK,h);kickV(h,h.aim,6+10*ch);h.vx-=co*(80+180*ch);h.vy-=si*(80+180*ch);h.kick.w-=120;const q=hamSnd(h);GSFX.rail(q.pan,q.vol,ch);setWave(s0[0],s0[1],0.3,0.5*ch,0.5);}
function laserTick(h){h.revealT=0.3;if(Math.random()<0.3)noise(h.x,h.y,'gun',0.55,h);const W=WEAPONS.laser,a=eL(h,'a'),b=eL(h,'b'),c=eL(h,'c'),P=evp(h),R=h.r,gh=R+(h.z||0);
  const od=c>=9&&(G.t%15)<3,cost=od?0:Math.max(0.2,1-0.06*c-(c>=3?0.1:0));h.ammoF=(h.ammoF||0)+cost;while(h.ammoF>=1){h.ammoF-=1;h.ammo--;}
  const range=W.range*P.range,base=W.dmg*P.dmg*h.st.dmg*(od?1.3:1);const angs=[[0,1]];if(b>=1)angs.push([0.22,b>=3?0.6:0.4]);if(b>=6)angs.push([-0.22,b>=3?0.6:0.4]);
  h.beams=[];let mainHit=null;
  for(const [off,k] of angs){const an=h.aim+off,co=Math.cos(an),si=Math.sin(an),gx=h.x+co*R*2.3,gy=h.y+si*R*2.3;let d=0,hit=null;
    while(d<range){const x=gx+co*d,y=gy+si*d,sd=pointSolid(x,y,1);if(sd){if(sd.prop)propHit(sd.prop,base*k,h);break;}for(const e of hashAt(x,y)){if(!canHit(h.team,e)||e.isProp)continue;if(d2(x,y,e.x,e.y)<e.r*e.r){hit=e;break;}}if(hit)break;d+=8;}
    h.beams.push({x0:gx,y0:gy,x1:gx+co*d,y1:gy+si*d,h:gh,hit:!!hit,t:time,side:off!==0});
    if(hit){let dm=base*k;if(off===0){mainHit=hit;if(a>0){if(h.focusT===hit)h.focusN++;else{h.focusT=hit;h.focusN=0;}const cap=0.1*a+(a>=6?0.2:0),ramp=Math.min(cap,h.focusN*(a>=3?0.08:0.04));dm*=1+ramp;if(a>=9&&ramp>=cap-1e-6){hit.burnT=Math.max(hit.burnT||0,1.2);hit.burnBy=h;h.ammo=Math.min(magSize(h),h.ammo+1);}}}
      if(dealDmg(hit,dm,{team:h.team,owner:h,x:hit.x,y:hit.y},true)>0)hitMark(h,hit);sparks(gx+co*d,gy+si*d,gh,h.team==='blue'?'#9fe8ff':'#ff9fb4',fxn(1));}}
  if(b>=9&&mainHit){const o2=nearestFoe(h.team,mainHit.x,mainHit.y,200);if(o2&&o2!==mainHit){dealDmg(o2,base*0.5,{team:h.team,owner:h,x:o2.x,y:o2.y},true);h.beams.push({x0:mainHit.x,y0:mainHit.y,x1:o2.x,y1:o2.y,h:gh,hit:true,t:time,side:true});}}
  h.beam=h.beams[0];const q=hamSnd(h);GSFX.laser(q.pan,q.vol);flashL('flash',h.beam.x0,h.beam.y0,gh+10,0.8*FXK,0.12);}

// ======== 投掷物 ========
function updLobs(dt){
  for(let i=lobs.length-1;i>=0;i--){const b=lobs[i];b.t+=dt;b.rot+=dt*12;let boom=false;
    if(b.att){if(b.att.dead||(b.att.kind==='ham'&&!b.att.alive))b.att=null;else{b.x=b.att.x+b.ox;b.y=b.att.y+b.oy;b.z=b.att.r;if(b.slowStick)slowE(b.att,0.2);}}
    else if(!b.stuck){const nx=b.x+b.vx*dt,ny=b.y+b.vy*dt;
      if(solidAt(nx,ny,5)){if(b.sticky){b.stuck=true;b.vx=b.vy=0;}else{const hx=solidAt(nx,b.y,5),hy=solidAt(b.x,ny,5);if(hx||!hy)b.vx*=-0.5;if(hy||!hx)b.vy*=-0.5;if(b.kind==='molo')boom=true;}}else{b.x=nx;b.y=ny;}
      b.vz-=900*dt;b.z+=b.vz*dt;
      if(b.kind==='flr'&&b.vz<0&&b.t>0.3){flares.push({x:b.x,y:b.y,h:Math.max(120,b.z+40),t:0,life:10+2*((b.lvl||1)-1),team:b.team});lobs.splice(i,1);SFX.boing(false);continue;}
      if(b.z<=2){b.z=2;if(b.kind==='molo'||b.kind==='smk')boom=true;else if(b.sticky){b.stuck=true;b.vx=b.vy=0;b.vz=0;}
        else if(b.vz<-60){if(b.splitOnBounce){b.splitOnBounce=false;for(const k of [-1,1]){const nb=Object.assign({},b);const sp=Math.hypot(b.vx,b.vy),an=Math.atan2(b.vy,b.vx)+k*0.7;nb.vx=Math.cos(an)*sp;nb.vy=Math.sin(an)*sp;nb.vz=-b.vz*0.4;lobs.push(nb);}}
          b.vz=-b.vz*0.38;b.vx*=0.6;b.vy*=0.6;const q=sndAt(b.x,b.y);GSFX.clank(q.pan,q.vol*0.6);if(b.bounceN>0){b.bounceN--;b.vz=Math.max(b.vz,220);b.vx*=1.4;b.vy*=1.4;}}
        else{b.vz=0;const f=Math.exp(-6*dt);b.vx*=f;b.vy*=f;}}}
    if(b.impact&&!b.att&&b.z<40)for(const e of hashAt(b.x,b.y)){if(!canHit(b.team,e)||e.isProp)continue;if(d2(b.x,b.y,e.x,e.y)<(e.r+8)*(e.r+8)){boom=true;break;}}
    if(b.sticky&&!b.att&&!b.stuck&&b.z<50)for(const e of hashAt(b.x,b.y)){if(!canHit(b.team,e)||e.isProp||e.kind==='crate')continue;if(d2(b.x,b.y,e.x,e.y)<(e.r+8)*(e.r+8)){b.att=e;b.ox=b.x-e.x;b.oy=b.y-e.y;b.vx=b.vy=0;pop(e.x,e.y,e.r*2.6,'黏住！','#c9ff8a',13,0.5);break;}}
    if(b.fuse!=null){b.fuse-=dt;if(b.fuse<=0)boom=true;}
    if(b.t>8)boom=true;
    if(Math.random()<0.5)addP({type:'smoke',x:b.x,y:b.y,h:b.z,vx:rand(-10,10),vy:rand(-10,10),vh:rand(5,15),life:0.35,size:rand(3,5),grow:10,col:b.kind==='frz'?'#cfefff':'#b8b4c4'});
    if(b.kind==='molo'&&Math.random()<0.7)addP({type:'fire',x:b.x,y:b.y,h:b.z+12,vh:20,life:0.18,size:rand(5,8)});
    if(boom){lobs.splice(i,1);lobBoom(b);}}}
function lobBoom(b){
  if(b.kind==='gnade'||b.kind==='frag'||b.kind==='bomb'){blast(b.x,b.y,b.aoe,b.dmg,b.team,b.owner,b.kb);
    if(b.special==='smoke')smokes.push({x:b.x,y:b.y,r:120,t:0,life:6});else if(b.special==='flash')flashBang({x:b.x,y:b.y,team:b.team});else if(b.special==='fire')fires.push({x:b.x,y:b.y,r:80,t:0,life:3,team:b.team,owner:b.owner,dps:14,tick:0});
    if(b.gas)zones.push({x:b.x,y:b.y,r:110,until:G.t+3,team:b.team,owner:b.owner,dps:6,tick:0,gas:true});}
  else if(b.kind==='molo'){fires.push({x:b.x,y:b.y,r:95+10*(b.lvl-1),t:0,life:4.5+0.5*(b.lvl-1),team:b.team,owner:b.owner,dps:12*(1+0.25*(b.lvl-1)),tick:0});const q=sndAt(b.x,b.y);GSFX.glass(q.pan,q.vol);noise(b.x,b.y,'boom',0.8,null);flashL('boom',b.x,b.y,30,1.8*FXK,0.4);
    for(let k=0;k<fxn(14);k++){const a=rand(0,TAU),s=rand(60,200);addP({type:'fire',x:b.x,y:b.y,h:8,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(40,120),life:rand(0.3,0.6),size:rand(14,24)});}decal({type:'scorch',x:b.x,y:b.y,r:80,rot:rand(0,TAU),life:12,max:12});}
  else if(b.kind==='flsh')flashBang(b);
  else if(b.kind==='smk'){smokes.push({x:b.x,y:b.y,r:150*(1+0.1*((b.lvl||1)-1)),t:0,life:8+((b.lvl||1)-1)});const q=sndAt(b.x,b.y);GSFX.flame(q.pan,q.vol);}
  else if(b.kind==='frz'){const R=140+10*((b.lvl||1)-1),q=sndAt(b.x,b.y);GSFX.ting(q.pan,q.vol);GSFX.glass(q.pan,q.vol*0.6);ring(b.x,b.y,4,10,R*2.2,0.35,'#bfefff');flashL('flash',b.x,b.y,30,2,0.2);
    for(let k=0;k<fxn(20);k++){const a=rand(0,TAU),s=rand(60,260);addP({type:'star',x:b.x,y:b.y,h:rand(6,30),vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(40,160),life:rand(0.4,0.8),size:rand(5,9),col:'#cfefff',glow:1});}
    hashRange(b.x,b.y,R+40,e=>{if(!canHit(b.team,e)||e.isProp||e.kind==='crate'||e.kind==='base'||e.kind==='turret')return;if(Math.hypot(e.x-b.x,e.y-b.y)-e.r>R)return;stunE(e,1.5);e.frozenUntil=G.t+(e.kind==='ham'?0.75:1.5);dealDmg(e,20,{team:b.team,owner:b.owner,x:b.x,y:b.y});});}}

// ======== 道具 ========
function useGadget(h){const G0=GADGETS[h.gadget.id],L=h.gadget.lvl,q=hamSnd(h),id=h.gadget.id;h.gadget.cd=G0.cd*(1-0.15*(L-1))*h.st.gcd;
  switch(id){
    case'mine':placeMine(h);return;case'sentry':placeSentry(h);return;
    case'eshield':h.eshield=h.maxHp*(1+0.25*(L-1));h.eshieldT=5;ring(h.x,h.y,h.r,h.r,160,0.4,'#7fe3ff');GSFX.charge(q.pan,q.vol*0.7);toastH(h,'能量护盾！','#7fe3ff',1);return;
    case'medkit':h.medT=3;h.medRate=h.maxHp*0.4*(1+0.2*(L-1))/3;SFX.munch(0.6);toastH(h,'嚼嚼回血','#8de0a6',1);return;
    case'jetpack':{const p=gadgetTarget(h),dx=p.x-h.x,dy=p.y-h.y,d=Math.hypot(dx,dy)||1,dd=clamp(d,120,360+40*(L-1));h.air={t:0,dur:0.55,x0:h.x,y0:h.y,x1:h.x+dx/d*dd,y1:h.y+dy/d*dd,hgt:70};h.jetT=0.6;h.rollT=0;GSFX.rocket(q.pan,q.vol*0.6);return;}
    case'decoy':{const a=h.aim,d={kind:'decoy',id:UID++,team:h.team,owner:h,skin:h.skin,x:h.x+Math.cos(a)*40,y:h.y+Math.sin(a)*40,r:16,hp:80*(1+0.25*(L-1)),maxHp:0,t:0,life:8+(L-1),dead:false,flash:0,aim:a,vr:{v:16},sq:{v:1},puff:{v:0.3},walk:0,moving:false,rollT:0,rollA:0,rdx:1,rdy:0,vx:0,vy:0,alive:true,hurtT:0,kick:{v:0},munchT:0,spitT:0,swingT:0,swingDir:1,weapon:{id:h.weapon.id},z:0,ab:{},tal:{},evo:{a:0,b:0,c:0},st:{},rig:null};d.maxHp=d.hp;resolveCircle(d,16);decoys.push(d);SFX.boing(false);ring(d.x,d.y,3,8,140,0.3,TCOL[h.team]);return;}
    case'beacon':if(h.beacon){const bx=h.beacon.x,by=h.beacon.y;teleFx(h.x,h.y,h.team);h.x=bx;h.y=by;h.vx=h.vy=0;h.beacon=null;teleFx(bx,by,h.team);h.iframes=Math.max(h.iframes,0.5);GSFX.charge(q.pan,q.vol);}else{h.beacon={x:h.x,y:h.y,until:G.t+30};h.gadget.cd=1.5;GSFX.beep(q.pan,q.vol);toastH(h,'信标已插好，再按一次传送回来','#7fe3ff',1.6);}return;}
  const p=gadgetTarget(h);GSFX.throw(q.pan,q.vol);h.spitT=0.2;
  if(id==='frag')throwLob(h,'frag',p.x,p.y,{sp:420,fuse:1.5,aoe:130,dmg:70*(1+0.2*(L-1)),kb:380});
  else if(id==='molotov')throwLob(h,'molo',p.x,p.y,{sp:420,lvl:L});
  else if(id==='flash')throwLob(h,'flsh',p.x,p.y,{sp:460,fuse:1.0});
  else if(id==='smoke')throwLob(h,'smk',p.x,p.y,{sp:440,lvl:L});
  else if(id==='flare')throwLob(h,'flr',p.x,p.y,{sp:380,lvl:L});
  else if(id==='freeze')throwLob(h,'frz',p.x,p.y,{sp:440,fuse:1.0,lvl:L});}
function aiWantGadget(h,t){const gid=h.gadget.id,d=t?Math.hypot(t.x-h.x,t.y-h.y):9999;
  if(gid==='eshield')return h.hurtT>0&&h.hp<h.maxHp*0.7;if(gid==='medkit')return h.hp<h.maxHp*0.5;if(gid==='beacon')return !h.beacon?h.hp>h.maxHp*0.8:h.hp<h.maxHp*0.3;
  if(!t)return false;if(gid==='mine')return d<220;if(gid==='sentry')return d<460;if(gid==='jetpack')return d>260&&d<480;if(gid==='decoy')return d<520;return d>140&&d<480;}

// ======== 世界效果 ========
function zoneDist(z,e){if(z.seg){const s=z.seg,sx=s[2]-s[0],sy=s[3]-s[1],L2=sx*sx+sy*sy||1,t=clamp(((e.x-s[0])*sx+(e.y-s[1])*sy)/L2,0,1);return Math.hypot(e.x-s[0]-sx*t,e.y-s[1]-sy*t)-z.w;}return Math.hypot(e.x-z.x,e.y-z.y)-z.r;}
function updEvoWorld(dt){
  for(let i=smokes.length-1;i>=0;i--){const s=smokes[i];s.t+=dt;const k=s.t/s.life;if(Math.random()<dt*22*FXK){const a=rand(0,TAU),r=Math.sqrt(Math.random())*s.r;addP({type:'smoke',x:s.x+Math.cos(a)*r,y:s.y+Math.sin(a)*r*0.85,h:rand(10,60),vx:rand(-12,12),vy:rand(-12,12),vh:rand(4,14),life:rand(1.4,2.2),size:rand(46,70)*(1-k*0.3),grow:14,col:'#8d8a98'});}if(s.t>=s.life)smokes.splice(i,1);}
  for(let i=flares.length-1;i>=0;i--){const f=flares[i];f.t+=dt;f.h=Math.max(16,f.h-dt*18);if(Math.random()<dt*14)addP({type:'spark',x:f.x,y:f.y,h:f.h,vx:rand(-30,30),vy:rand(-30,30),vh:rand(-80,-20),life:rand(0.3,0.6),col:'#ff9a6a',size:1.3});if(f.t>=f.life)flares.splice(i,1);}
  for(let i=decoys.length-1;i>=0;i--){const d=decoys[i];if(d.dead){decoys.splice(i,1);continue;}d.t+=dt;d.flash=Math.max(0,d.flash-dt);d.stepT=(d.stepT||0)-dt;if(d.stepT<=0){d.stepT=0.45;noise(d.x,d.y,'step',0.6,d);}if(d.t>=d.life){d.dead=true;decoyPop(d);}}
  for(let i=zones.length-1;i>=0;i--){const z=zones[i];z.tick-=dt;if(z.tick<=0){z.tick=0.25;for(const L of [hams,minions,mobs])for(const e of L){if(L===hams?!e.alive:e.dead)continue;if(!canHit(z.team,e))continue;if(zoneDist(z,e)<e.r){dealDmg(e,z.dps*0.25,{team:z.team,owner:z.owner,x:e.x,y:e.y},true);if(z.gas)slowE(e,0.5);}}}
    if(Math.random()<dt*12){if(z.seg){const s=z.seg,k=Math.random();addP({type:'spark',x:lerp(s[0],s[2],k),y:lerp(s[1],s[3],k),h:4,vx:rand(-60,60),vy:rand(-60,60),vh:rand(40,120),life:0.2,col:'#9fe8ff',size:1.2});}else addP({type:'smoke',x:z.x+rand(-z.r,z.r)*0.7,y:z.y+rand(-z.r,z.r)*0.6,h:rand(4,20),vx:0,vy:0,vh:8,life:1,size:rand(30,44),grow:10,col:'#9bd36a'});}
    if(G.t>=z.until)zones.splice(i,1);}
  for(let i=corrs.length-1;i>=0;i--)if(G.t>=corrs[i].until)corrs.splice(i,1);
  for(const h of hams)h.bannerK=1;for(const h of hams)if(h.alive&&h.st.banner>0)for(const o of hams)if(o.alive&&o.team===h.team&&Math.hypot(o.x-h.x,o.y-h.y)<260)o.bannerK=Math.max(o.bannerK,1+h.st.banner);
  for(const h of hams)if(h.beacon&&G.t>h.beacon.until)h.beacon=null;
  for(const L of [hams,minions,mobs])for(const e of L){if(!(e.burnSpread>G.t)||!(e.burnT>0))continue;if(Math.random()<dt){hashRange(e.x,e.y,90,q=>{if(q===e||q.team===e.team||q.isProp||q.kind==='crate'||q.kind==='base'||q.kind==='turret')return;if(Math.hypot(q.x-e.x,q.y-e.y)<80+q.r){q.burnT=Math.max(q.burnT||0,1.5);q.burnBy=e.burnBy;}});}}}

// ======== 视野 ========
function smokeBlocks(x1,y1,x2,y2){for(const s of smokes){const dx=x2-x1,dy=y2-y1,L2=dx*dx+dy*dy||1,t=clamp(((s.x-x1)*dx+(s.y-y1)*dy)/L2,0,1);if(d2(x1+dx*t,y1+dy*t,s.x,s.y)<(s.r*0.8)*(s.r*0.8))return true;}return false;}
function litBy(L,e){for(const s of L){if(s.seg){const g=s.seg,sx=g[2]-g[0],sy=g[3]-g[1],L2=sx*sx+sy*sy||1,t=clamp(((e.x-g[0])*sx+(e.y-g[1])*sy)/L2,0,1);if(Math.hypot(e.x-g[0]-sx*t,e.y-g[1]-sy*t)<s.w+e.r)return true;continue;}
  const dx=e.x-s.x,dy=e.y-s.y,d=Math.hypot(dx,dy);if(d>s.r+e.r)continue;if(s.dir!==undefined&&d>e.r+24){const c=(dx*Math.cos(s.dir)+dy*Math.sin(s.dir))/(d||1);if(c<s.cos)continue;}
  if(s.los&&d>e.r+30){if(!hasLOS(s.x,s.y,e.x,e.y))continue;if(smokes.length&&smokeBlocks(s.x,s.y,e.x,e.y))continue;}return true;}return false;}
function computeVis(){const sh=[];for(const p of props)if(p.kind==='lamp'&&!p.dead)sh.push({x:p.x,y:p.y,r:300,los:true});for(const f of fires)sh.push({x:f.x,y:f.y,r:f.r+90,los:true});if(FLASH.boom.t>0)sh.push({x:FLASH.boom.x,y:FLASH.boom.y,r:340,los:true});
  for(const team of TEAMS){const V=VIS[team];V.clear();const L=sh.slice();
    for(const f of flares)if(f.team===team)L.push({x:f.x,y:f.y,r:470,los:true});
    for(const c of corrs)if(c.team===team)L.push({seg:[c.x0,c.y0,c.x1,c.y1],w:c.w});
    for(const h of hams)if(h.alive&&h.team===team){const nv=h.st.nvg||0,nr=Math.max((h.tal.nightvision?260:150),nv)+h.r;L.push({x:h.x,y:h.y,r:nr,los:!(nv||h.tal.nightvision)});L.push({x:h.x,y:h.y,r:lightRange(h),dir:h.aim,cos:lightCos(h),los:true});
      if(h.weapon.id==='sniper'&&eL(h,'a')>=3){const len=600+60*eL(h,'a');L.push({seg:[h.x,h.y,h.x+Math.cos(h.aim)*len,h.y+Math.sin(h.aim)*len],w:eL(h,'a')>=6?70:40});}}
    for(const s of structs)if(!s.dead&&s.team===team)L.push({x:s.x,y:s.y,r:s.kind==='base'?620:s.kind==='turret'?s.range+30:220,los:true});
    for(const m of minions)if(!m.dead&&m.team===team)L.push({x:m.x,y:m.y,r:120,los:true});
    const test=e=>{if(e.revealT>0||(e.markTeam===team&&G.t<e.markUntil)||litBy(L,e))V.add(e);};
    for(const h of hams)if(h.alive&&h.team!==team&&(h.invisT<=0||h.revealT>0))test(h);
    for(const m of minions)if(!m.dead&&m.team!==team)test(m);
    for(const e of mobs)if(!e.dead)test(e);
    for(const d of decoys)if(!d.dead&&d.team!==team)test(d);
    for(const s of structs)if(!s.dead&&s.kind==='sentry'&&s.team!==team)test(s);
    for(const m of mines)if(m.team!==team){m.r=10;test(m);}}}

// ======== 升级卡 ========
const GEN_VISION=['torch','wide','ears','nvg','recon'];
function rollChoices(h){
  if(h.talentPend>0){const tp=Object.keys(TALENTS).filter(k=>!h.tal[k]),o=[];while(o.length<3&&tp.length)o.push({t:'tal',id:tp.splice((Math.random()*tp.length)|0,1)[0]});if(o.length){h.choices=o;return;}h.talentPend=0;}
  const out=[],has=c=>out.some(x=>x.t===c.t&&x.id===c.id&&x.k===c.k),add=c=>{if(c&&!has(c))out.push(c);};
  const evs=PK.filter(k=>(h.evo[k]||0)<9).map(k=>({t:'evo',k,id:h.weapon.id}));
  const pickEvo=()=>{if(!evs.length)return null;let s=0;const w=evs.map(e=>{const v=1+0.35*(h.evo[e.k]||0);s+=v;return v;});let r=Math.random()*s;for(let i=0;i<evs.length;i++){r-=w[i];if(r<=0)return evs.splice(i,1)[0];}return evs.pop();};
  const gens=Object.keys(ABIL).filter(id=>(h.ab[id]||0)<ABIL[id].max);
  const pickGen=pref=>{const pool=pref?gens.filter(pref):gens;if(!pool.length)return null;const id=pool[(Math.random()*pool.length)|0];gens.splice(gens.indexOf(id),1);return{t:'abil',id};};
  add(pickEvo());add(pickGen());
  const evTot=eL(h,'a')+eL(h,'b')+eL(h,'c'),pW=evTot===0&&h.lvl<6?0.35:evTot<6?0.1:0.05,r=Math.random();
  if(r<pW){const ws=Object.keys(WEAPONS).filter(id=>id!==h.weapon.id);add({t:'weap',id:ws[(Math.random()*ws.length)|0]});}
  else if(r<pW+0.3){if(Math.random()<0.45&&h.gadget.lvl<4)add({t:'glvl',id:h.gadget.id});else{const gs=Object.keys(GADGETS).filter(id=>id!==h.gadget.id);add({t:'gad',id:gs[(Math.random()*gs.length)|0]});}}
  else if(r<pW+0.45){const ps=Object.keys(PETS).filter(id=>{const p=h.petList.find(q=>q.type===id);return !p||p.lvl<3;});if(ps.length)add({t:'pet',id:ps[(Math.random()*ps.length)|0]});}
  else if(r<pW+0.75)add(pickEvo());
  else add(pickGen(id=>GEN_VISION.includes(id))||pickGen());
  while(out.length<3){const c=pickEvo()||pickGen();if(!c)break;add(c);}
  h.choices=out.slice(0,3);}
function choiceLabel(h,c){
  if(c.t==='tal')return{type:'天赋',name:TALENTS[c.id].name,lv:'',desc:TALENTS[c.id].desc,rar:'l'};
  if(c.t==='evo'){const i=PK.indexOf(c.k),p=EVO[h.weapon.id][i],lv=eL(h,c.k)+1;return{type:'进化',name:p[0],lv:lv>=9?'质变':'',desc:evText(h.weapon.id,i,lv),evo:{i,lv,col:PATHC[i]}};}
  if(c.t==='weap')return{type:'换武器',name:WEAPONS[c.id].name,lv:'换上',desc:WDESC[c.id]+'（进化清零）'};
  if(c.t==='gad')return{type:'道具',name:GADGETS[c.id].name,lv:'换上',desc:GADGETS[c.id].desc};
  if(c.t==='glvl')return{type:'道具',name:GADGETS[c.id].name,lv:'',desc:'冷却更短，效果更强'};
  if(c.t==='abil'){const l=(h.ab[c.id]||0)+1;return{type:'强化',name:ABIL[c.id].name,lv:l>1?'':'新',desc:ABIL[c.id].desc};}
  const p=h.petList.find(q=>q.type===c.id);return{type:'宠物',name:PETS[c.id].name,lv:p?'':'新',desc:PETS[c.id].desc};}
function applyChoice(h,i){const c=h.choices&&h.choices[i];if(!c)return;const lab=choiceLabel(h,c);
  if(c.t==='evo'){if(eL(h,c.k)<9)h.evo[c.k]=eL(h,c.k)+1;}
  else if(c.t==='weap'){h.weapon={id:c.id,lvl:1};h.evo={a:0,b:0,c:0};h.spin=0;h.charge=0;h.chHold=0;h.beam=null;h.beams=null;h.marks=[];h.ramp=0;}
  else if(c.t==='gad'){h.gadget={id:c.id,lvl:1,cd:0};h.beacon=null;}else if(c.t==='glvl')h.gadget.lvl++;
  else if(c.t==='tal'){h.tal[c.id]=true;h.talentPend=Math.max(0,h.talentPend-1);}
  else if(c.t==='abil')h.ab[c.id]=(h.ab[c.id]||0)+1;
  else{const p=h.petList.find(q=>q.type===c.id);if(p)p.lvl++;else{const np=mkPet(c.id,h);h.petList.push(np);pets.push(np);}}
  h.pending=Math.max(0,h.pending-1);h.choices=null;calcStats(h);if(c.t==='tal'&&c.id==='aegis')h.shield=h.st.shield;
  if(c.t==='weap'){h.ammo=magSize(h);h.reloadT=0;h.bloom=0;}else if(c.t==='evo'){const m=magSize(h);h.ammo=Math.min(m,h.ammo+Math.ceil(m*0.3));}
  SFX.open();const col=lab.evo?lab.evo.col:'#ffd166';ring(h.x,h.y,3,h.r,180,0.35,col);for(let k=0;k<fxn(10);k++){const an=rand(0,TAU);addP({type:'star',x:h.x,y:h.y,h:30,vx:Math.cos(an)*110,vy:Math.sin(an)*110,vh:rand(60,180),life:0.7,size:7,col,glow:1});}
  toastH(h,`获得：${lab.type==='进化'?WEAPONS[h.weapon.id].name+'·':''}${lab.name}${lab.lv==='质变'?'（质变）':''}`,col,1.6);
  if(h.pending>0)rollChoices(h);}
function aiPick(h){let bi=0,bw=-1;const evTot=eL(h,'a')+eL(h,'b')+eL(h,'c');h.choices.forEach((c,i)=>{const w=(c.t==='evo'?3:c.t==='abil'?2:c.t==='glvl'?1.6:c.t==='gad'?1.1:c.t==='pet'?1.3:c.t==='weap'?(evTot===0?1.2:0.3):1)+Math.random()*1.5;if(w>bw){bw=w;bi=i;}});return bi;}
function calcStats(h){const a=h.ab,T=h.tal||{};
  h.st={speed:SPEED0*(1+0.08*(a.speed||0))*(T.giant?0.92:1),maxHp:(100*(1+0.15*(a.strong||0))+(h.lvl-1)*8)*(T.giant?1.6:1),regen:2*(a.regen||0),vamp:0.04*(a.vamp||0)+(T.vampire?0.15:0),crit:0.08*(a.crit||0),critDmg:2,multi:T.overdrive?1:0,split:0,
    dashCd:1.15*(1-0.15*(a.dash||0))*(T.phantom?0.5:1),dashDmg:(a.dash||0)*18,shield:T.aegis?2:0,shieldCd:3,magnet:95*(1+0.5*(a.magnet||0)),chain:0.1*(a.chain||0)+(T.storm?0.3:0),frost:a.frost||0,
    dmg:(1+0.1*(a.rage||0))*(1+0.03*(h.lvl-1))*(h.crownT>0?1.25:1)*(T.giant?1.15:1),rate:(1+0.08*(a.rate||0))*(T.overdrive?1.2:1),rl:T.bottomless?1/1.5:1,magK:1,pierce:0,incend:0,ric:0,
    armor:0.07*(a.armor||0),scav:0.25*(a.scav||0),runngun:false,xpK:1+0.12*(a.scholar||0),demo:1,hunter:1,gcd:1-0.15*(a.gcd||0),aura:2*(a.aura||0),rangeK:1,
    lightK:1+0.18*(a.torch||0),wideK:a.wide||0,hearK:1+0.3*(a.ears||0),nvg:a.nvg?60+60*a.nvg:0,recon:1.5*(a.recon||0),banner:0.06*(a.banner||0),scale:1+0.04*(a.strong||0)};
  h.r=(T.giant?21.6:16)*h.st.scale;
  const f=h.maxHp?h.hp/h.maxHp:1;h.maxHp=h.st.maxHp;h.hp=Math.min(h.maxHp,Math.max(1,f*h.maxHp));}
