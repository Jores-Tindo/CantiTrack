// ===== Fonctions utilitaires =====
const $=s=>document.querySelector(s);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const crit=e=>P.filter((p,i)=>e.st[i]<=p[2]).map(p=>p[0]);
const stat=e=>e.sy>3?['Sans synchronisation','r']:crit(e).length?['Alerte de stock','r']:['À jour','g'];
const syn=e=>e.sy>=999?'Jamais':e.sy===0?'Aujourd’hui':e.sy===1?'Hier':'Il y a '+e.sy+' jours';
const row=e=>{const s=stat(e);return `<tr><td><a href="#ecole-${e.id}">${esc(e.nom)}</a></td><td>${esc(e.c)}</td><td>${crit(e).join(', ')||'Aucun'}</td><td>${syn(e)}</td><td class="${s[1]}">${s[0]}</td></tr>`};
const head=`<tr><th>École</th><th>Commune</th><th>Stock critique</th><th>Dernière synchronisation</th><th>Statut</th></tr>`;
let auth=false,F={q:'',c:'',s:''},Pd=7;
// ===== Vues =====
const V={};
V.connexion=()=>`<div class="box" style="max-width:380px;margin:40px auto"><h1>CantiTrack</h1><p class="m">Tableau de bord de la direction</p>
<label for="u">Identifiant</label><input id="u" autocomplete="username" style="width:100%"><label for="p">Mot de passe</label><input id="p" type="password" autocomplete="current-password" style="width:100%">
<div class="row"><button class="btn" onclick="login()">Se connecter</button></div><p class="m" style="font-size:14px">Connexion de démonstration : tout identifiant est accepté pour l’instant.</p></div>`;
V.accueil=()=>{const al=E.filter(e=>stat(e)[1]==='r'),ns=E.filter(e=>e.sy>3).length,sk=E.filter(e=>crit(e).length).length,rp=E.reduce((a,e)=>a+e.rp,0);
return `<h1>${al.length} école${al.length>1?'s ont':' a'} besoin d’attention</h1>
<p class="m">Sur ${E.length} écoles suivies, ${ns} n’ont pas synchronisé depuis plus de 3 jours et ${sk} ont un produit sous le seuil d’alerte. ${rp} repas ont été servis cette semaine.</p>
<h2>Écoles à surveiller</h2><div class="w"><table>${head}${al.map(row).join('')||'<tr><td colspan="5">Aucune école à surveiller.</td></tr>'}</table></div>
<h2>Stock consolidé</h2>${P.map((p,i)=>{const t=E.reduce((a,e)=>a+e.st[i],0),n=E.filter(e=>e.st[i]<=p[2]).length;return `<div class="ln"><b>${p[0]}</b><span>${t} ${p[1]} au total, <span class="${n?'r':'g'}">${n} école${n>1?'s':''} sous le seuil</span></span></div>`}).join('')}`};
const rows=()=>{const q=F.q.toLowerCase();return E.filter(e=>(!q||e.nom.toLowerCase().includes(q))&&(!F.c||e.c===F.c)&&(!F.s||stat(e)[0]===F.s)).map(row).join('')||'<tr><td colspan="5">Aucune école ne correspond à ces filtres.</td></tr>'};
V.ecoles=()=>`<h1>Écoles</h1><div class="row"><div><label for="q">Rechercher</label><input id="q" value="${esc(F.q)}" oninput="F.q=this.value;$('#tb').innerHTML=rows()"></div>
<div><label for="fc">Commune</label><select id="fc" onchange="F.c=this.value;$('#tb').innerHTML=rows()"><option value="">Toutes</option>${C.map(c=>`<option${F.c===c?' selected':''}>${c}</option>`).join('')}</select></div>
<div><label for="fs">Statut</label><select id="fs" onchange="F.s=this.value;$('#tb').innerHTML=rows()"><option value="">Tous</option>${['À jour','Alerte de stock','Sans synchronisation'].map(s=>`<option${F.s===s?' selected':''}>${s}</option>`).join('')}</select></div></div>
<div class="w"><table>${head}<tbody id="tb">${rows()}</tbody></table></div>`;
V.ecole=id=>{const e=E.find(x=>x.id===id);if(!e)return V.accueil();const s=stat(e);
return `<p><a href="#ecoles">Retour aux écoles</a></p><h1>${esc(e.nom)}</h1><p class="m">${esc(e.c)}, ${e.eff} élèves à la cantine. Dernière synchronisation : ${syn(e)}. <span class="${s[1]}">${s[0]}</span></p>
<h2>Stock actuel</h2><div class="w"><table><tr><th>Produit</th><th>Stock</th><th>Seuil d’alerte</th><th>Niveau</th></tr>${P.map((p,i)=>{const lo=e.st[i]<=p[2],w=Math.min(100,Math.round(e.st[i]/(p[2]*2)*100));return `<tr><td>${p[0]}</td><td class="${lo?'r':''}">${e.st[i]} ${p[1]}${lo?' (sous le seuil)':''}</td><td>${p[2]} ${p[1]}</td><td><div class="bar" role="img" aria-label="${w} %"><i class="${lo?'r':''}" style="width:${w}%"></i></div></td></tr>`}).join('')}</table></div>
<h2>Dernières opérations du registre</h2><div class="w"><table><tr><th>N°</th><th>Date</th><th>Opération</th><th>Produit</th><th>Quantité</th></tr>${e.mv.map(m=>`<tr><td>${String(m.n).padStart(4,'0')}</td><td>${m.d}</td><td>${m.t}</td><td>${m.p}</td><td>${m.t==='Entrée'?'+':'−'}${m.q} ${m.u}</td></tr>`).join('')||'<tr><td colspan="5">Aucune opération synchronisée pour cette école.</td></tr>'}</table></div>
<h2>Menus de la semaine</h2><div class="w"><table><tr><th>Jour</th><th>Plat</th><th>Effectif prévu</th><th>Situation</th></tr>${['Lundi','Mardi','Mercredi','Jeudi','Vendredi'].map((d,i)=>`<tr><td>${d}</td><td>${PL[(e.id+i)%3]}</td><td>${e.eff}</td><td>${i<e.rp?'Servi':'Prévu'}</td></tr>`).join('')}</table></div>`};
function rap(){const k=Pd/7;return C.map(c=>{const l=E.filter(e=>e.c===c);return [c,l.length,Math.round(l.reduce((a,e)=>a+e.rp,0)*k),Math.round(l.reduce((a,e)=>a+e.rp*e.eff*.9,0)*k),l.filter(e=>crit(e).length).length]})}
V.rapports=()=>{const d=rap(),csv='Commune;Écoles;Repas servis;Élèves servis;Écoles avec alerte de stock\n'+d.map(x=>x.join(';')).join('\n');
return `<h1>Rapports</h1><div class="row"><button class="btn${Pd===7?'':' o'}" onclick="Pd=7;go()">7 jours</button><button class="btn${Pd===30?'':' o'}" onclick="Pd=30;go()">30 jours</button></div>
<div class="w"><table><tr><th>Commune</th><th>Écoles</th><th>Repas servis</th><th>Élèves servis</th><th>Écoles avec alerte de stock</th></tr>${d.map(x=>`<tr>${x.map(v=>`<td>${v}</td>`).join('')}</tr>`).join('')}</table></div>
<h2>Exporter</h2><p class="m">Copiez le tableau pour le coller dans Excel. Le téléchargement direct de fichiers sera disponible quand le tableau de bord sera hébergé avec le serveur.</p>
<textarea id="csv" readonly rows="6" style="width:100%">${esc(csv)}</textarea><div class="row"><button class="btn" onclick="cp()">Copier le tableau</button><button class="btn o" onclick="window.print()">Imprimer</button></div>`};
V.admin=()=>`<h1>Administration</h1><h2>Seuils d’alerte par produit</h2><div class="w"><table><tr><th>Produit</th><th>Seuil d’alerte</th></tr>${P.map((p,i)=>`<tr><td><label for="s${i}" style="margin:0;color:inherit;font-size:inherit">${p[0]} (${p[1]})</label></td><td><input id="s${i}" type="number" min="0" value="${p[2]}" onchange="P[${i}][2]=Math.max(0,+this.value||0)"></td></tr>`).join('')}</table></div>
<p class="m">Les changements s’appliquent aux statuts des écoles et sont conservés jusqu’au rechargement de la page.</p>
<h2>Ajouter une école</h2><div class="box" style="max-width:420px"><label for="nn">Nom de l’école</label><input id="nn" style="width:100%"><label for="nc">Commune</label><select id="nc" style="width:100%">${C.map(c=>`<option>${c}</option>`).join('')}</select><label for="ne">Élèves à la cantine</label><input id="ne" type="number" min="1" value="100" style="width:100%"><div class="row"><button class="btn" onclick="addE()">Ajouter l’école</button></div><div id="ok" class="m" role="status"></div></div>`;
// ===== Actions =====
function login(){if(!$('#u').value.trim()){$('#u').focus();return}auth=true;location.hash='accueil'}
function out(){auth=false;location.hash='connexion'}
function cp(){const t=$('#csv');t.select();try{navigator.clipboard.writeText(t.value)}catch(e){document.execCommand('copy')}}
function addE(){const n=$('#nn').value.trim();if(!n){$('#ok').textContent='Indiquez le nom de l’école.';return}
E.push({id:E.length+1,nom:n,c:$('#nc').value,eff:+$('#ne').value||100,sy:999,rp:0,st:P.map(()=>0),mv:[]});$('#ok').textContent='École ajoutée : elle apparaît dans la liste des écoles.';$('#nn').value=''}
const L=[['accueil','Vue d’ensemble'],['ecoles','Écoles'],['rapports','Rapports'],['admin','Administration']];
function go(){let h=location.hash.slice(1)||'connexion';if(!auth&&h!=='connexion'){location.hash='connexion';return}
const m=h.match(/^ecole-(\d+)$/),k=m?'ecole':(V[h]?h:'accueil'),cur=k==='ecole'?'ecoles':k;
$('#h').innerHTML=auth?`<b>CantiTrack</b>${L.map(l=>`<a href="#${l[0]}"${l[0]===cur?' aria-current="page"':''}>${l[1]}</a>`).join('')}<a href="#connexion" onclick="auth=false">Se déconnecter</a>`:'<b>CantiTrack</b>';
$('#a').innerHTML=(auth?'<div class="note">Données d’exemple : ce tableau de bord sera relié au serveur central à l’étape suivante.</div>':'')+V[k](m?+m[1]:0);window.scrollTo(0,0)}
addEventListener('hashchange',go);go();
