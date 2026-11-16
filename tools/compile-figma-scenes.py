"""Compile reviewed Figma MCP reference JSX into offline native scene definitions.
No JavaScript runs in the app; interactive actions are bound by CampaignApp.
"""
import json, re, html
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = json.loads((ROOT / 'tools/figma-contexts.json').read_text())
for extra in sorted((ROOT/'tools').glob('figma-*-context.json')):
    source.update(json.loads(extra.read_text()))
out = ROOT / 'app/assets/figma/scenes'
out.mkdir(parents=True, exist_ok=True)
assets = {}
scenes = {}

def number(classes, prefix, fallback=None):
    m = re.search(r'(?:^| )' + re.escape(prefix) + r'-\[(-?[\d.]+)px\]', classes)
    if m: return float(m[1])
    if re.search(r'(?:^| )' + re.escape(prefix) + r'-0(?: |$)', classes): return 0
    if re.search(r'(?:^| )' + re.escape(prefix) + r'-px(?: |$)', classes): return 1
    return fallback

def color(value):
    if value.startswith('#'):
        return int('ff' + value[1:], 16)
    vals = re.findall(r'[\d.]+', value)
    if len(vals) >= 3:
        rgb = [int(float(v)) for v in vals[:3]]
        alpha = round(float(vals[3])*255) if len(vals)>3 else 255
        return (alpha<<24)|(rgb[0]<<16)|(rgb[1]<<8)|rgb[2]
    raise ValueError(value)

def colors(classes,prefix):
    m = re.search(r'(?:^| )'+prefix+r'-\[(#[a-fA-F0-9]+|rgba?\([^\]]+\))\]',classes)
    return color(m[1]) if m else None

class Parser(HTMLParser):
    def __init__(self, urlmap):
        super().__init__(); self.stack=[]; self.root=None; self.urlmap=urlmap
    def handle_starttag(self,tag,attrs):
        a=dict(attrs); c=a.get('classname',''); n={'tag':tag,'id':a.get('data-node-id',''),'name':a.get('data-name',''),'children':[]}
        for k,p in [('x','left'),('y','top'),('w','w'),('h','h')]:
            v=number(c,p)
            if v is not None:n[k]=v
        z=number(c,'size')
        if z is not None:n['w']=n['h']=z
        if 'size-full' in c or 'inset-0' in c:n['fill']=True
        n['radius']=number(c,'rounded',0)
        for k,p in [('background','bg'),('border','border'),('color','text')]:
            v=colors(c,p)
            if v is not None:n[k]=v
        if 'border' in n:n['borderWidth']=number(c,'border',1 if ' border ' in ' '+c+' ' else .5)
        n['fontSize']=number(c,'text',14)
        inherited = self.stack[-1] if self.stack else {}
        n['font']='CormorantGaramond' if 'Cormorant_Garamond' in c else 'IBMPlexMono' if 'IBM_Plex_Mono' in c else 'DMSans' if 'DM_Sans' in c else inherited.get('font','DMSans')
        n['bold']=False if 'font-normal' in c or 'Regular' in c else ('Bold' in c or 'font-bold' in c or inherited.get('bold',False))
        n['italic']='Italic' in c or ('italic' in c and 'not-italic' not in c)
        n['tracking']=number(c,'tracking',0)
        n['clip']='overflow-clip' in c
        op=re.search(r'(?:^| )opacity-(\d+)',c)
        if op:n['opacity']=int(op[1])/100
        if 'bg-gradient-to-r' in c:
            grad=[colors(c,p) for p in ['from','via','to']]
            n['gradient']=[v for v in grad if v is not None]
            via=re.search(r'via-\[([\d.]+)%\]',c)
            if len(n['gradient'])==3:n['stops']=[0,float(via[1])/100 if via else .5,1]
        if a.get('data-gradient'):
            # get_design_context supplies explicit horizontal readability scrims.
            pairs=re.findall(r'(rgba?\([^\)]+\)) ([\d.]+)%',a['data-gradient'])
            if pairs:n['gradient']=[color(x) for x,_ in pairs];n['stops']=[float(x)/100 for _,x in pairs]
        if tag=='img':
            n['asset']=self.urlmap[a['src']]
        if self.stack:self.stack[-1]['children'].append(n)
        else:self.root=n
        if tag!='img':self.stack.append(n)
    def handle_startendtag(self,tag,attrs):
        self.handle_starttag(tag,attrs)
        if tag!='img':self.handle_endtag(tag)
    def handle_endtag(self,tag):
        if self.stack:self.stack.pop()
    def handle_data(self,data):
        if self.stack and data.strip():self.stack[-1]['text']=self.stack[-1].get('text','')+html.unescape(data.strip())

for id, code in source.items():
    mapping={}
    for name,url in re.findall(r'const (img\w+) = "([^"]+)";',code):
        filename=url.rsplit('/',1)[-1]; assets[filename]=url
        mapping[name]='assets/figma/scenes/'+filename
    functions={name:body for name,body in re.findall(r'function (\w+)\([^\n]*\) \{\s*return \(\s*(.*?)\s*\);\s*\}',code,re.S)}
    body=code.split('export default function',1)[1].split('return (',1)[1].rsplit(');',1)[0].strip()
    # Component instances receive their own className wrapper, same child layers.
    for name, component in functions.items():
        component=re.sub(r'className=\{className \|\| "([^"]+)"\}',r'className="\1"',component)
        root_tag = component[:component.index('>')]
        identity = ' '.join(re.findall(r'data-(?:name|node-id)="[^"]*"', root_tag))
        inner=component[component.index('>')+1:component.rfind('</div>')]
        body=re.sub(r'<'+name+r' className="([^"]+)"\s*/>',lambda m:'<div className="'+m[1]+'" '+identity+'>'+inner+'</div>',body)
    body=re.sub(r'style=\{\{ backgroundImage: "([^"]+)" \}\}',lambda m:'data-gradient="'+html.escape(m[1],quote=True)+'"',body)
    body=re.sub(r' style=\{\{.*?\}\}', '',body)
    body=re.sub(r'src=\{(img\w+)\}',lambda m:'src="'+mapping[m[1]]+'"',body)
    body=re.sub(r'\{`([^`]+)`\}',r'\1',body)
    parser=Parser({v:v for v in mapping.values()});parser.feed(body)
    def bind_undo(n):
        if n['id'] in ('24:2753', '24:8469'):
            label = dict(n, x=13, y=13)
            n.update(tag='a', name='Undo', x=48, y=293, w=104, h=48, children=[label])
            n.pop('text',None)
        else:
            for child in n['children']: bind_undo(child)
    bind_undo(parser.root)
    scenes[id.replace(':','-')]=parser.root
(ROOT/'docs/a02/figma-assets-manifest.json').write_text(json.dumps(assets,indent=2))
print(f'Compiled {len(source)} scenes; {len(assets)} assets to download.')
# Compile data once: navigation never depends on asynchronous asset JSON loading.
(ROOT/'app/lib/ui/figma_scenes.g.dart').write_text('// Generated by tools/compile-figma-scenes.py. Do not edit.\n// dart format off\nconst Map<String, dynamic> figmaScenes = '+json.dumps(scenes,separators=(',',':'))+';\n')
