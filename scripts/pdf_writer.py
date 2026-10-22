"""Small dependency-free PDF renderer for the A01 text and original vector scenes.

Uses standard PDF fonts. Only ASCII document text is emitted after punctuation
normalization; no downloaded font, image converter, browser, or LaTeX required.
"""
import math
import re
import textwrap
import unicodedata
from pathlib import Path


def ascii_text(value):
    value=str(value).replace('→',' -> ').replace('↔',' <-> ').replace('≤','<=').replace('≥','>=')
    for a,b in [('—',' - '),('–','-'),('’',"'"),('“','"'),('”','"'),('×','x'),('…','...')]:value=value.replace(a,b)
    return unicodedata.normalize('NFKD',value).encode('ascii','replace').decode('ascii')


def literal(value):
    return '('+ascii_text(value).replace('\\','\\\\').replace('(','\\(').replace(')','\\)')+')'


def color(hexcode):
    h=hexcode.lstrip('#');return ' '.join(f'{int(h[i:i+2],16)/255:.4f}' for i in [0,2,4])


def width(value,size=10,mono=False):
    if mono:return len(ascii_text(value))*size*.6
    total=0
    for c in ascii_text(value):
        if c in ' ilI.,:;!\'|':v=.28
        elif c in 'mwMW@%':v=.87
        elif c in 'ABCDEFGHKNOPQRSTUVXYZ':v=.72
        elif c in '()[]{}frt':v=.39
        else:v=.56
        total+=v*size
    return total


def wrap(value,space,size=10,mono=False):
    lines=[];line=''
    for word in ascii_text(value).split():
        if width((line+' '+word).strip(),size,mono)<=space:
            line=(line+' '+word).strip();continue
        if line:lines.append(line);line=''
        if width(word,size,mono)>space:
            chunk=''
            for c in word:
                if width(chunk+c,size,mono)>space:
                    lines.append(chunk);chunk=''
                chunk+=c
            line=chunk
        else:line=word
    if line:lines.append(line)
    return lines or ['']


class PDF:
    def __init__(self):
        self.pages=[];self.page=[];self.annots=[];self.all_annots=[];self.y=0
        self.new_page()

    def new_page(self):
        if self.page:
            self.pages.append(self.page);self.all_annots.append(self.annots)
        self.page=[];self.annots=[];self.y=63
        self.text(48,25,'FOREST SOKOBAN / A01 SPECIFICATION',8,bold=True,fill='#486156')
        self.line(48,44,547,44,'#C9D3CA',.7)

    def ensure(self,height):
        if self.y+height>790:self.new_page()

    def text(self,x,y,text,size=10,bold=False,mono=False,fill='#173B32'):
        font='F3' if mono else 'F2' if bold else 'F1'
        self.page.append(f'BT /{font} {size:.3f} Tf {color(fill)} rg 1 0 0 1 {x:.3f} {842-y-size*.85:.3f} Tm {literal(text)} Tj ET')

    def line(self,x1,y1,x2,y2,fill='#173B32',sw=1):
        self.page.append(f'{color(fill)} RG {sw:.3f} w {x1:.3f} {842-y1:.3f} m {x2:.3f} {842-y2:.3f} l S')

    def rect(self,x,y,w,h,fill=None,stroke=None,sw=1,radius=0):
        command=[]
        if fill:command.append(color(fill)+' rg')
        if stroke:command.append(color(stroke)+f' RG {sw:.3f} w')
        if radius:
            r=min(radius,w/2,h/2);bottom=842-y-h;top=bottom+h;k=.55228475
            command.append(f'{x+r} {bottom} m {x+w-r} {bottom} l')
            command.append(f'{x+w-r+k*r} {bottom} {x+w} {bottom+r-k*r} {x+w} {bottom+r} c')
            command.append(f'{x+w} {top-r} l {x+w} {top-r+k*r} {x+w-r+k*r} {top} {x+w-r} {top} c')
            command.append(f'{x+r} {top} l {x+r-k*r} {top} {x} {top-r+k*r} {x} {top-r} c')
            command.append(f'{x} {bottom+r} l {x} {bottom+r-k*r} {x+r-k*r} {bottom} {x+r} {bottom} c h')
        else:command.append(f'{x:.3f} {842-y-h:.3f} {w:.3f} {h:.3f} re')
        command.append('B' if fill and stroke else 'f' if fill else 'S')
        self.page.append(' '.join(command))

    def ellipse(self,x,y,w,h,fill=None,stroke=None,sw=1):
        cx=x+w/2;cy=842-y-h/2;rx=w/2;ry=h/2;k=.55228475
        parts=[]
        if fill:parts.append(color(fill)+' rg')
        if stroke:parts.append(color(stroke)+f' RG {sw} w')
        parts.append(f'{cx+rx} {cy} m')
        for pts in [(cx+rx,cy+k*ry,cx+k*rx,cy+ry,cx,cy+ry),(cx-k*rx,cy+ry,cx-rx,cy+k*ry,cx-rx,cy),(cx-rx,cy-k*ry,cx-k*rx,cy-ry,cx,cy-ry),(cx+k*rx,cy-ry,cx+rx,cy-k*ry,cx+rx,cy)]:
            parts.append(' '.join(f'{v:.3f}' for v in pts)+' c')
        parts.append('B' if fill and stroke else 'f' if fill else 'S');self.page.append(' '.join(parts))

    def paragraph(self,value,size=10,bold=False,mono=False,indent=0):
        value=plain(value)
        lines=wrap(value,499-indent,size,mono)
        for line in lines:
            self.ensure(size*1.5)
            self.text(48+indent,self.y,line,size,bold,mono)
            self.y+=size*1.45
        self.y+=5

    def heading(self,value,level=2):
        size={1:29,2:18,3:12.5}.get(level,11)
        self.ensure(size*2+30);self.y+=12
        for line in wrap(plain(value),499,size):
            self.text(48,self.y,line,size,True);self.y+=size*1.2
        self.y+=9

    def table(self,rows):
        count=len(rows[0]);weights=[1]*count
        if count==4 and rows[0][0]=='ID':weights=[.65,.65,1.7,4]
        elif count==5 and rows[0][0]=='Requirement':weights=[.8,1,1.2,2.6,.8]
        elif count>=6:weights=[1]*count
        elif count==3:weights=[1,2.6,2.6]
        widths=[499*w/sum(weights) for w in weights]
        def row(cells,header=False):
            size=8 if count<=5 else 7.5
            lines=[wrap(plain(cell),w-12,size) for cell,w in zip(cells,widths)]
            height=max(map(len,lines))*size*1.35+14
            if self.y+height>786:
                self.new_page()
                if not header:row(rows[0],True)
            x=48
            for content,w in zip(lines,widths):
                self.rect(x,self.y,w,height,'#E7EEDF' if header else '#FFFFFF','#CED7CD',.4)
                for i,line in enumerate(content):self.text(x+6,self.y+6+i*size*1.35,line,size,header)
                x+=w
            self.y+=height
        for i,cells in enumerate(rows):row(cells,i==0)
        self.y+=10

    def image(self,scene,caption):
        w=499;h=w*scene.height/scene.width
        if h>625:w*=625/h;h=625
        self.ensure(h+40);x=48+(499-w)/2;y=self.y;scale=w/scene.width
        self.page.append(f'q {x:.3f} {842-y-h:.3f} {w:.3f} {h:.3f} re W n')
        for op in scene.ops:
            k=op['kind']
            if k=='text':self.text(x+op['x']*scale,y+op['y']*scale,op['text'],op['size']*scale,op['bold'],fill=op['fill'])
            elif k in ['rect','ellipse']:
                method=self.rect if k=='rect' else self.ellipse
                args=[x+op['x']*scale,y+op['y']*scale,op['w']*scale,op['h']*scale,op.get('fill'),op.get('stroke'),op.get('sw',1)*scale]
                if k=='rect':args.append(op.get('radius',0)*scale)
                method(*args)
            else:self.line(x+op['x1']*scale,y+op['y1']*scale,x+op['x2']*scale,y+op['y2']*scale,op['stroke'],op['sw']*scale)
        self.page.append('Q')
        self.y+=h+6;self.paragraph(caption,8)

    def url(self,label,url):
        self.ensure(25);y=self.y
        self.paragraph(label,9)
        self.annots.append((48,y,499,14,url))

    def save(self,path):
        if self.page:self.pages.append(self.page);self.all_annots.append(self.annots);self.page=[]
        objects=[]
        def add(raw):objects.append(raw.encode('ascii') if isinstance(raw,str) else raw);return len(objects)
        catalog=add('');page_tree=add('')
        fonts=[add(f'<< /Type /Font /Subtype /Type1 /BaseFont /{name} /Encoding /WinAnsiEncoding >>') for name in ['Helvetica','Helvetica-Bold','Courier']]
        page_ids=[]
        for i,(commands,annotations) in enumerate(zip(self.pages,self.all_annots),1):
            commands=list(commands)
            commands.append(f'BT /F1 8 Tf 0.28 0.38 0.33 rg 1 0 0 1 48 26 Tm {literal("v1.0-draft | Research / Figma verification pending")} Tj ET')
            commands.append(f'BT /F1 8 Tf 1 0 0 1 510 26 Tm {literal(str(i))} Tj ET')
            stream='\n'.join(commands).encode('ascii')
            stream_id=add(f'<< /Length {len(stream)} >>\nstream\n'.encode()+stream+b'\nendstream')
            ids=[]
            for x,y,w,h,url in annotations:
                ids.append(add(f'<< /Type /Annot /Subtype /Link /Rect [{x} {842-y-h} {x+w} {842-y}] /Border [0 0 0] /A << /S /URI /URI {literal(url)} >> >>'))
            ann=' /Annots ['+' '.join(f'{n} 0 R' for n in ids)+']' if ids else ''
            page_ids.append(add(f'<< /Type /Page /Parent {page_tree} 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 {fonts[0]} 0 R /F2 {fonts[1]} 0 R /F3 {fonts[2]} 0 R >> >> /Contents {stream_id} 0 R{ann} >>'))
        objects[catalog-1]=f'<< /Type /Catalog /Pages {page_tree} 0 R >>'.encode()
        objects[page_tree-1]=f'<< /Type /Pages /Count {len(page_ids)} /Kids [{" ".join(f"{p} 0 R" for p in page_ids)}] >>'.encode()
        info=add('<< /Title (Forest Sokoban - Comprehensive Specification A01) /Author (Two-person team - AI-assisted draft) /Subject (A01 design baseline; research and Figma verification pending) >>')
        out=bytearray(b'%PDF-1.4\n');offsets=[0]
        for i,obj in enumerate(objects,1):
            offsets.append(len(out));out.extend(f'{i} 0 obj\n'.encode()+obj+b'\nendobj\n')
        xref=len(out);out.extend(f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode())
        for offset in offsets[1:]:out.extend(f'{offset:010} 00000 n \n'.encode())
        out.extend(f'trailer\n<< /Size {len(objects)+1} /Root {catalog} 0 R /Info {info} 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode())
        Path(path).write_bytes(out)
        return len(page_ids)


def plain(value):
    value=re.sub(r'\[([^\]]+)\]\([^)]+\)',r'\1',value)
    return re.sub(r'[*`]', '', value)


def render_markdown(source,scenes,path):
    pdf=PDF();lines=source.splitlines();i=0
    while i<len(lines):
        line=lines[i]
        if not line.strip():i+=1;continue
        if line.startswith('```'):
            i+=1
            while i<len(lines) and not lines[i].startswith('```'):
                # Preserve indentation for JSON/code; break long lines safely.
                code=ascii_text(lines[i]).expandtabs(2)
                for part in textwrap.wrap(code,100,replace_whitespace=False,drop_whitespace=False) or ['']:
                    pdf.ensure(12);pdf.rect(48,pdf.y,499,12,'#F0F3EC');pdf.text(55,pdf.y+1,part,8,mono=True);pdf.y+=12
                i+=1
            pdf.y+=8;i+=1;continue
        if line.startswith('|'):
            rows=[]
            while i<len(lines) and lines[i].startswith('|'):
                parts=[p.strip() for p in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\- ]+',p) for p in parts):rows.append(parts)
                i+=1
            pdf.table(rows);continue
        match=re.match(r'!\[([^\]]*)\]\(([^)]+)\)',line)
        if match:
            pdf.image(scenes[match[2]],match[1]);i+=1;continue
        if line.startswith('#'):
            level=len(line)-len(line.lstrip('#'));pdf.heading(line[level:].strip(),level);i+=1;continue
        if line.startswith('- '):
            for label,url in re.findall(r'\[([^\]]+)\]\((https?://[^)]+)\)',line):
                pdf.url(label,url)
            pdf.paragraph('- '+line[2:],9.5,indent=8);i+=1;continue
        if re.match(r'^\d+\. ',line):
            pdf.paragraph(line,10,indent=8);i+=1;continue
        para=line
        while i+1<len(lines) and lines[i+1].strip() and not re.match(r'^(#|\||!\[|```|- |\d+\. )',lines[i+1]):i+=1;para+=' '+lines[i]
        for label,url in re.findall(r'\[([^\]]+)\]\((https?://[^)]+)\)',para):pdf.url(label,url)
        if para.startswith('Figma prototype URL: https://') or para.startswith('**Figma prototype URL:** https://'):
            url=para.split('https://',1)[1];pdf.url('Open Figma prototype','https://'+url)
        pdf.paragraph(para);i+=1
    return pdf.save(path)
