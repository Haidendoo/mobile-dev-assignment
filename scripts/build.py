#!/usr/bin/env python3
"""Rebuild the complete English A01 package using the Python standard library."""
from pathlib import Path
import csv
import html
import json
import re
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from artwork import screens,diagrams
from contract import contract
from pdf_writer import render_markdown


def write(path,text):
    path=ROOT/path;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8')


def write_json(path,value):write(path,json.dumps(value,indent=2,ensure_ascii=True)+'\n')


def tables(source):
    tables=[];current=[]
    for line in source.splitlines()+['']:
        if line.startswith('|'):
            cells=[p.strip() for p in line.strip().strip('|').split('|')]
            if not all(re.fullmatch('[: -]+',c) for c in cells):current.append(cells)
        elif current:tables.append(current);current=[]
    return tables


def build_csv(source):
    ts=tables(source)
    req=next(t for t in ts if t[0][:2]==['ID','Priority'])
    trace=next(t for t in ts if t[0][0]=='Requirement')
    nfr_trace=next(t for t in ts if t[0][0]=='NFR')
    with (ROOT/'docs/traceability.csv').open('w',newline='') as f:csv.writer(f).writerows(trace+nfr_trace[1:])
    nfr=next(t for t in ts if t[0][:2]==['ID','Measurable requirement'])
    with (ROOT/'docs/nfr-verification.csv').open('w',newline='') as f:
        writer=csv.writer(f);writer.writerow(['requirement_id','target','verification_method','test_id','phase','execution_status','actual_result','evidence_path'])
        for row in nfr[1:]:writer.writerow(row+['VF-'+row[0][-2:],'A02','Not run','',''])
    with (ROOT/'docs/test-cases.csv').open('w',newline='') as f:
        writer=csv.writer(f);writer.writerow(['test_id','requirement_id','priority','given','when','then','phase','execution_status','actual_result','evidence_path'])
        for id,priority,requirement,ac in req[1:]:
            m=re.fullmatch(r'(AC-\d+): Given (.*), when (.*), then (.*)',ac)
            assert m,ac
            test,given,when,then=m.groups()
            writer.writerow([test,id,priority,given,when,then,'A02','Not run','',''])


def inline(value):
    value=html.escape(value)
    value=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',value)
    value=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',value)
    return re.sub(r'`([^`]+)`',r'<code>\1</code>',value)


def doc_html(source,scene_map):
    lines=source.splitlines();out=[];i=0
    while i<len(lines):
        line=lines[i]
        if not line.strip():i+=1;continue
        if line.startswith('```'):
            code=[];i+=1
            while i<len(lines) and not lines[i].startswith('```'):code.append(lines[i]);i+=1
            out.append('<pre><code>'+html.escape('\n'.join(code))+'</code></pre>');i+=1;continue
        if line.startswith('|'):
            rows=[]
            while i<len(lines) and lines[i].startswith('|'):
                parts=[p.strip() for p in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\- ]+',p) for p in parts):rows.append(parts)
                i+=1
            out.append('<table>')
            for j,row in enumerate(rows):
                tag='th' if j==0 else 'td';out.append('<tr>'+''.join(f'<{tag}>{inline(cell)}</{tag}>' for cell in row)+'</tr>')
            out.append('</table>');continue
        m=re.match(r'!\[([^\]]+)\]\(([^)]+)\)',line)
        if m:
            out.append('<figure>'+scene_map[m[2]].svg()+'<figcaption>'+html.escape(m[1])+'</figcaption></figure>');i+=1;continue
        if line.startswith('#'):
            level=len(line)-len(line.lstrip('#'));title=line[level:].strip()
            out.append(f'<h{level}>{inline(title)}</h{level}>');i+=1;continue
        if line.startswith('- '):
            out.append('<ul>')
            while i<len(lines) and lines[i].startswith('- '):out.append('<li>'+inline(lines[i][2:])+'</li>');i+=1
            out.append('</ul>');continue
        if re.match(r'^\d+\. ',line):
            out.append('<ol>')
            while i<len(lines) and re.match(r'^\d+\. ',lines[i]):
                out.append('<li>'+inline(re.sub(r'^\d+\. ','',lines[i]))+'</li>');i+=1
            out.append('</ol>');continue
        para=line
        while i+1<len(lines) and lines[i+1].strip() and not re.match(r'^(#|\||!\[|```|- |\d+\. )',lines[i+1]):i+=1;para+=' '+lines[i]
        out.append('<p>'+inline(para)+'</p>');i+=1
    css='''body{font:16px/1.6 system-ui,sans-serif;color:#173b32;background:#f3f5ef;margin:0}main{max-width:1100px;margin:30px auto;padding:45px;background:white}h1{font-size:48px}h2{margin-top:2em;border-bottom:2px solid #dce8b9}h3{margin-top:1.5em}a{color:#165b45}table{border-collapse:collapse;width:100%;font-size:13px;margin:24px 0}th,td{border:1px solid #ced7cd;padding:9px;text-align:left;vertical-align:top;overflow-wrap:anywhere}th{background:#e7eedf}pre{background:#f0f3ec;padding:18px;white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px}figure{margin:25px 0;break-inside:avoid}figure svg{width:100%;height:auto;max-height:85vh}figcaption{font-size:13px;color:#486156}code{font-size:.9em}.notice{background:#fff0c9;padding:16px}@media print{body{background:white}main{margin:0;padding:0}h2{break-after:avoid}table{font-size:9px}tr,figure{break-inside:avoid}figure svg{max-height:650px}a{color:inherit}}'''
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Forest Sokoban — A01 Specification</title><style>'+css+'</style><main><p class="notice">v1.0-draft — real research, Figma-runtime verification, and team approval remain pending.</p>'+''.join(out)+'</main></html>'


def preview(frame_data):
    # No fetch(): works from file://, including offline.
    data=json.dumps(frame_data,ensure_ascii=True).replace('</','<\\/')
    return '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Forest Sokoban — Design Walkthrough</title>
<style>*{box-sizing:border-box}body{margin:0;background:#102d25;color:#fff8e7;font-family:system-ui,sans-serif}header,footer{max-width:1400px;margin:auto;padding:18px 24px}header{display:flex;align-items:center;gap:16px;flex-wrap:wrap}h1{font-size:19px;margin:0}select,header button{font:inherit;min-height:44px;border:1px solid #b4cc75;border-radius:8px;padding:8px;background:#173b32;color:#fff8e7}label{font-size:14px}#stage{position:relative;width:min(100%,1400px);aspect-ratio:16/9;margin:auto;background:#dce8b9;overflow:hidden;border-radius:14px}#stage svg{width:100%;height:100%;display:block}.hotspot{position:absolute;border:0;background:transparent;color:transparent;cursor:pointer;border-radius:10px}.hotspot:hover{box-shadow:inset 0 0 0 3px #f4c766}.hotspot:focus-visible{outline:4px solid #8a3028;outline-offset:-4px}#stage.show-targets .hotspot{outline:2px dashed #8a3028}footer{font-size:14px;line-height:1.6;color:#dce8b9}#state-label{font-weight:700;color:white}.live{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0)}@media(max-width:650px){header{padding:12px}#stage{border-radius:0}footer{padding:12px}}</style></head>
<body><header><h1>Forest Sokoban</h1><label>Review state <select id="states" aria-label="Choose a design state"></select></label><button id="home">Start over</button><button id="targets" aria-pressed="false">Show touch areas</button></header><main><div id="stage" aria-label="Clickable prototype screen"></div><p id="announce" class="live" aria-live="polite"></p></main><footer><span id="state-label"></span><br>A01 design walkthrough • sample scores • scripted frame navigation, no live backend or game engine. Use the state menu to inspect errors, offline states, and level layouts. Main run: Play → Level 1 → Right → Right. Other directions outside the demonstrated routes are illustrative.<br>Design canvas: 1280 × 720 at 2×. Figma import instructions: <a style="color:#f4c766" href="figma/README.md">figma/README.md</a>.</footer>
<script>const FRAMES='''+data+''';
const stage=document.getElementById('stage'),select=document.getElementById('states');let timer=null;
for(const frame of FRAMES){const option=document.createElement('option');option.value=frame.id;option.textContent=frame.id+' — '+frame.title;select.append(option);}
function show(id){clearTimeout(timer);const frame=FRAMES.find(f=>f.id===id)||FRAMES[0];stage.innerHTML=frame.svg;stage.querySelector('svg').setAttribute('aria-label',frame.title);select.value=frame.id;document.getElementById('state-label').textContent=frame.id+' — '+frame.title;document.getElementById('announce').textContent=frame.title;
for(const link of frame.links){const button=document.createElement('button');button.className='hotspot';button.setAttribute('aria-label',link.label);button.title=link.label;Object.assign(button.style,{left:100*link.x/1280+'%',top:100*link.y/720+'%',width:100*link.w/1280+'%',height:100*link.h/720+'%'});button.addEventListener('click',()=>show(link.target));stage.append(button);}
history.replaceState(null,'','#'+frame.id);if(frame.id==='SCR-07l')timer=setTimeout(()=>show('SCR-07'),1200);}
select.addEventListener('change',()=>show(select.value));document.getElementById('home').addEventListener('click',()=>show('SCR-01'));document.getElementById('targets').addEventListener('click',event=>{const on=stage.classList.toggle('show-targets');event.currentTarget.setAttribute('aria-pressed',String(on));});window.addEventListener('hashchange',()=>show(location.hash.slice(1)));show(location.hash.slice(1)||'SCR-01');
</script></body></html>'''


def figma_plugin(frames):
    data=json.dumps(frames,ensure_ascii=True,separators=(',',':'))
    return '''// Generated by scripts/build.py. Run in Figma Design; no network access.
const SCREENS = '''+data+''';
function rgb(hex){const n=parseInt(hex.slice(1),16);return {r:((n>>16)&255)/255,g:((n>>8)&255)/255,b:(n&255)/255};}
function paint(hex){return [{type:'SOLID',color:rgb(hex)}];}
async function main(){
 await Promise.all([figma.loadFontAsync({family:'Inter',style:'Regular'}),figma.loadFontAsync({family:'Inter',style:'Bold'})]);
 const page=figma.createPage();page.name='Forest Sokoban - A01 draft';await figma.setCurrentPageAsync(page);const nodes={};
 for(let i=0;i<SCREENS.length;i++){
  const spec=SCREENS[i],frame=figma.createFrame();frame.name=spec.id+' / '+spec.title;frame.resize(1280,720);frame.x=(i%4)*1420;frame.y=Math.floor(i/4)*860;frame.clipsContent=true;frame.fills=paint('#DCE8B9');page.appendChild(frame);nodes[spec.id]=frame;
  for(const op of spec.ops){let node;
   if(op.kind==='text'){node=figma.createText();node.fontName={family:'Inter',style:op.bold?'Bold':'Regular'};node.fontSize=op.size;node.characters=op.text;node.textAutoResize='WIDTH_AND_HEIGHT';node.fills=paint(op.fill);frame.appendChild(node);node.x=op.x;node.y=op.y;}
   else if(op.kind==='line'){node=figma.createVector();const x=Math.min(op.x1,op.x2),y=Math.min(op.y1,op.y2);node.vectorPaths=[{windingRule:'NONZERO',data:'M '+(op.x1-x)+' '+(op.y1-y)+' L '+(op.x2-x)+' '+(op.y2-y)}];node.fills=[];node.strokes=paint(op.stroke);node.strokeWeight=op.sw;frame.appendChild(node);node.x=x;node.y=y;}
   else {node=op.kind==='ellipse'?figma.createEllipse():figma.createRectangle();node.resize(op.w,op.h);node.fills=op.fill?paint(op.fill):[];node.strokes=op.stroke?paint(op.stroke):[];node.strokeWeight=op.sw||1;if(op.kind==='rect')node.cornerRadius=op.radius||0;frame.appendChild(node);node.x=op.x;node.y=op.y;}
   node.name=op.kind==='text'?op.text:op.kind;
  }
 }
 for(const spec of SCREENS){const frame=nodes[spec.id];for(const link of spec.links){const hit=figma.createRectangle();hit.name='Tap: '+link.label;hit.resize(link.w,link.h);hit.fills=[{type:'SOLID',color:{r:1,g:1,b:1},opacity:0.001}];frame.appendChild(hit);hit.x=link.x;hit.y=link.y;await hit.setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:nodes[link.target].id,navigation:'NAVIGATE',transition:{type:'DISSOLVE',easing:{type:'EASE_OUT'},duration:0.15},preserveScrollPosition:false}]}]);}
  if(spec.id==='SCR-07l')await frame.setReactionsAsync([{trigger:{type:'AFTER_TIMEOUT',timeout:1.2},actions:[{type:'NODE',destinationId:nodes['SCR-07'].id,navigation:'NAVIGATE',transition:null,preserveScrollPosition:false}]}]);
 }
 page.selection=[nodes['SCR-01']];figma.viewport.scrollAndZoomIntoView([nodes['SCR-01']]);figma.closePlugin('Created '+SCREENS.length+' editable frames. Select SCR-01, add a flow starting point, then Present.');
}
main().catch(error=>{console.error(error);figma.closePlugin('Import failed: '+String(error.message||error));});
'''


def expanded_document(source,frame_map,api):
    links=json.loads((ROOT/'prototype/links.json').read_text())
    url=links['figma_url'] or 'PENDING — importer prepared; Figma runtime review and viewer-accessible share link required.'
    source=source.replace('{{FIGMA_URL}}',url)
    gallery='\n\n'.join(f'### {id} — {f["title"]}\n\n![{f["title"]}](../prototype/screens/{id}.svg)' for id,f in frame_map.items())
    source=source.replace('{{SCREEN_GALLERY}}',gallery)
    source=source.replace('{{API_CONTRACT}}','```json\n'+json.dumps(api,indent=2)+'\n```')
    report=ROOT/'deliverables/validation-report.md'
    source=source.replace('{{VALIDATION_REPORT}}',report.read_text() if report.exists() else 'Verification has not yet run. Run `python3 scripts/validate.py` and rebuild to embed the report.')
    return source


def build():
    for folder in ['docs/assets','docs/api','prototype/screens','prototype/figma','deliverables']:(ROOT/folder).mkdir(parents=True,exist_ok=True)
    levels=json.loads((ROOT/'data/levels.json').read_text())['levels']
    frame_map=screens(levels);diagram_map=diagrams(levels);scene_map={}
    for name,scene in diagram_map.items():
        path=f'assets/{name}.svg';write('docs/'+path,scene.svg());scene_map[path]=scene
    frame_data=[];manifest=[]
    for id,frame in frame_map.items():
        scene=frame['scene'];path=f'../prototype/screens/{id}.svg';write('prototype/screens/'+id+'.svg',scene.svg());scene_map[path]=scene
        frame_data.append(dict(id=id,title=frame['title'],width=1280,height=720,svg=scene.svg(),ops=scene.ops,links=scene.links))
        manifest.append(dict(id=id,title=frame['title'],screen_file='screens/'+id+'.svg',width=1280,height=720,links=scene.links))
    write_json('prototype/frames.json',manifest)
    write('prototype/index.html',preview(frame_data))
    write('prototype/figma/code.js',figma_plugin(frame_data))
    write_json('prototype/figma/manifest.template.json',{'name':'Forest Sokoban A01 Importer','id':'REPLACE_WITH_YOUR_FIGMA_GENERATED_PLUGIN_ID','api':'1.0.0','main':'code.js','editorType':['figma'],'documentAccess':'dynamic-page','networkAccess':{'allowedDomains':['none']}})
    api=contract();write_json('docs/api/openapi.json',api)
    source=(ROOT/'docs/A01-specification.md').read_text();build_csv(source)
    expanded=expanded_document(source,frame_map,api)
    write('deliverables/Forest-Sokoban-A01.md',expanded)
    write('deliverables/Forest-Sokoban-A01.html',doc_html(expanded,scene_map))
    pages=render_markdown(expanded,scene_map,ROOT/'deliverables/Forest-Sokoban-A01.pdf')
    archive=ROOT/'deliverables/Forest-Sokoban-A01-package.zip'
    paths=[ROOT/p for p in ['README.md','project-step.md','.gitignore']]
    for directory in ['docs','data','prototype','scripts','deliverables']:
        paths.extend(p for p in (ROOT/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts and p!=archive)
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as package:
        for path in sorted(paths):package.write(path,path.relative_to(ROOT))
    print(f'Built {len(frame_map)} screens, {len(diagram_map)} diagrams, API, traceability, prototype, Figma importer, and {pages}-page PDF.')
    return frame_map,diagram_map


if __name__=='__main__':build()
