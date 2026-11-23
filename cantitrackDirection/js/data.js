// ===== Données d’exemple. À remplacer par des appels à l’API : fetch('/api/ecoles'), fetch('/api/produits') =====
const P=[['Riz','kg',50],['Haricot','kg',30],['Maïs','kg',30],['Huile','l',10],['Sel','kg',5]];
const C=['Commune 1','Commune 2','Commune 3'],PL=['Riz sauce tomate','Riz au haricot','Pâte de maïs et sauce'];
let seed=11;const R=()=>(seed=seed*16807%2147483647)/2147483647;
function mk(i){const e={id:i,nom:'EPP Exemple '+i,c:C[i%3],eff:80+Math.floor(R()*220),sy:R()<.2?4+Math.floor(R()*8):Math.floor(R()*3),rp:2+Math.floor(R()*4)};
e.st=P.map(p=>Math.round(p[2]*(.3+R()*2.2)));e.mv=[];
for(let k=0;k<6;k++){const t=['Entrée','Sortie','Sortie','Perte'][Math.floor(R()*4)],j=Math.floor(R()*5);e.mv.push({n:140-k,d:String(7-k).padStart(2,'0')+'/11/2026',t,p:P[j][0],q:Math.round(P[j][2]*(.2+R()*.8)),u:P[j][1]})}
return e}
const E=[];for(let i=1;i<=14;i++)E.push(mk(i));
