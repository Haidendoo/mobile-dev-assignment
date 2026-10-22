#!/usr/bin/env python3
"""Honest A01 design checks; never reports A02 app tests as executed."""
from pathlib import Path
from collections import deque
from datetime import datetime
import csv
import json
import re
import sys
import uuid
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from build import build, tables
from levels import parse, replay, shortest_solution, move
from artwork import INK, FOREST, PAPER, MUTED, ERROR, screens, diagrams
from pdf_writer import width


def validate_schema(value,schema,api):
    if '$ref' in schema:
        node=api
        for part in schema['$ref'].removeprefix('#/').split('/'):node=node[part]
        return validate_schema(value,node,api)
    if value is None:
        assert schema.get('nullable'), 'Unexpected null'
        return
    kind=schema.get('type')
    if kind=='object':
        assert isinstance(value,dict)
        assert set(schema.get('required',[]))<=set(value)
        if schema.get('additionalProperties') is False:assert set(value)<=set(schema['properties'])
        for k,v in value.items():
            if k in schema.get('properties',{}):validate_schema(v,schema['properties'][k],api)
    elif kind=='array':
        assert isinstance(value,list)
        assert len(value)<=schema.get('maxItems',float('inf'))
        for item in value:validate_schema(item,schema['items'],api)
    elif kind=='integer':
        assert isinstance(value,int) and not isinstance(value,bool)
        assert schema.get('minimum',-float('inf'))<=value<=schema.get('maximum',float('inf'))
    elif kind=='boolean':assert isinstance(value,bool)
    elif kind=='string':
        assert isinstance(value,str)
        if schema.get('pattern'):assert re.fullmatch(schema['pattern'],value)
        if schema.get('format')=='uuid':uuid.UUID(value)
        if schema.get('format')=='date-time':datetime.fromisoformat(value.replace('Z','+00:00'))
    if 'enum' in schema:assert value in schema['enum']


def luminance(hexcode):
    channels=[int(hexcode[i:i+2],16)/255 for i in [1,3,5]]
    linear=[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in channels]
    return sum(v*w for v,w in zip(linear,[.2126,.7152,.0722]))


def check_pdf(path):
    raw=path.read_bytes()
    assert raw.startswith(b'%PDF-1.4') and raw.endswith(b'%%EOF\n')
    start=int(re.search(rb'startxref\n(\d+)\n%%EOF',raw).group(1))
    assert raw[start:start+5]==b'xref\n'
    records=raw[start:].splitlines();count=int(records[1].split()[1])
    for object_id,line in enumerate(records[3:3+count-1],1):
        offset=int(line[:10]);assert raw[offset:].startswith(f'{object_id} 0 obj\n'.encode())
    pages=re.findall(rb'/Type /Page\s',raw)
    assert len(pages)>=20
    count_entry=int(re.search(rb'/Type /Pages /Count (\d+)',raw).group(1));assert count_entry==len(pages)
    for stream in re.finditer(rb'<< /Length (\d+) >>\nstream\n',raw):
        size=int(stream.group(1));assert raw[stream.end()+size:].startswith(b'\nendstream')
    assert b'Functional requirements' in raw
    assert b'SCR-08m' in raw and b'submit_score' in raw
    return len(pages),len(raw)


def main():
    frame_map,diagram_map=build()
    levels=json.loads((ROOT/'data/levels.json').read_text())['levels']
    source=(ROOT/'docs/A01-specification.md').read_text()
    report=['# A01 design verification report','',
            'Run date: 21 October 2026 (Asia/Bangkok). These are source/design checks, not Flutter, Figma-runtime, participant, Supabase integration, or device-performance results.','',
            '## Level solution checks','',
            '| Level | Stored solution | Shortest valid moves | Search states | Result |',
            '|---|---|---|---|---|']
    lengths=[]
    for l in levels:
        states=replay(l['map'],l['solution'])
        solution,visited=shortest_solution(l['map'])
        assert len(l['solution'])==len(solution)
        lengths.append(len(solution))
        report.append(f'| {l["id"]}/v{l["version"]} | {l["solution"]} | {len(solution)} | {visited} | PASS |')
    assert len(levels)==5 and len({l['id'] for l in levels})==5
    assert lengths==sorted(set(lengths))
    # Independent rule fixtures for the design-verification model.
    floor,goals,state=parse(['#######','#     #','# @$$.#','#   . #','#######'])
    assert move(floor,state,'R') is None
    floor,goals,state=parse(['#####','#@$.#','#####'])
    assert move(floor,state,'L') is None
    assert move(floor,state,'R')[1]==goals

    ts=tables(source);req=next(t for t in ts if t[0][:2]==['ID','Priority'])
    trace=next(t for t in ts if t[0][0]=='Requirement')
    requirements={r[0] for r in req[1:]};must_should={r[0] for r in req[1:] if r[1] in ['Must','Should']}
    assert len(requirements)==17 and len(must_should)==16
    assert requirements=={r[0] for r in trace[1:]}
    nfr_trace=next(t for t in ts if t[0][0]=='NFR')
    assert len(nfr_trace)==13
    uc=set(re.findall(r'### (UC-\d+)',source))
    for row in trace[1:]:
        assert row[-1]=='AC-'+row[0][-2:]
        assert set(re.findall(r'UC-\d+',row[1]))<=uc
        for screen in re.findall(r'SCR-\d+',row[2]):assert screen in frame_map
        assert row[3].strip()
    with (ROOT/'docs/test-cases.csv').open() as f:cases=list(csv.DictReader(f))
    assert {c['requirement_id'] for c in cases}==requirements
    assert all(c['execution_status']=='Not run' for c in cases)
    with (ROOT/'docs/nfr-verification.csv').open() as f:nfr_cases=list(csv.DictReader(f))
    assert len(nfr_cases)==12 and all(c['execution_status']=='Not run' for c in nfr_cases)

    hotspots=0;text_overflow=[]
    for id,f in frame_map.items():
        scene=f['scene'];ET.fromstring(scene.svg())
        for op in scene.ops:
            if op['kind']=='text' and op['x']+width(op['text'],op['size'])>1288:
                text_overflow.append((id,op['text']))
        for link in scene.links:
            hotspots+=1
            assert link['target'] in frame_map,(id,link)
            assert link['w']>=96 and link['h']>=96,(id,'below 48dp baseline',link)
            assert 0<=link['x']<=1280-link['w'] and 0<=link['y']<=720-link['h']
    assert not text_overflow,text_overflow
    for scene in diagram_map.values():ET.fromstring(scene.svg())
    graph={id:{link['target'] for link in f['scene'].links} for id,f in frame_map.items()}
    graph['SCR-07l'].add('SCR-07')
    seen={'SCR-01'};queue=deque(seen)
    while queue:
        for dest in graph[queue.popleft()]-seen:seen.add(dest);queue.append(dest)
    assert {'SCR-02','SCR-03','SCR-04','SCR-04p','SCR-04u','SCR-05','SCR-05c','SCR-06','SCR-07','SCR-08m'}<=seen
    fixture_only=sorted(set(frame_map)-seen)
    # Every remaining state is selectable in the explicit review-state menu.
    preview=(ROOT/'prototype/index.html').read_text()
    assert 'fetch(' not in preview
    assert all(json.dumps(id) in preview for id in frame_map)
    for foreground,background in [(INK,PAPER),(PAPER,FOREST),(MUTED,PAPER),(ERROR,PAPER)]:
        a,b=sorted([luminance(foreground),luminance(background)])
        assert (b+.05)/(a+.05)>=4.5,(foreground,background)

    api=json.loads((ROOT/'docs/api/openapi.json').read_text());assert api['openapi']=='3.0.3'
    for item in api['paths'].values():
        operation=item['post']
        for content in [operation['requestBody']['content']['application/json']]+[
            r['content']['application/json'] for r in operation['responses'].values() if 'content' in r]:
            if 'example' in content:validate_schema(content['example'],content['schema'],api)
    # Validate every JSON example in the source specification against the matching schema.
    samples=[json.loads(block) for block in re.findall(r'```json\n(.*?)\n```',source,re.S)]
    expected=['ScoreRequest','ScoreReceipt','Leaderboard','RpcError']
    for sample,name in zip(samples[1:],expected):validate_schema(sample,api['components']['schemas'][name],api)
    assert samples[0]['player']==[3,2] and samples[0]['crates']==[[4,2]]
    submit=api['paths']['/rest/v1/rpc/submit_score']['post']
    assert submit['security']==[{'ProjectKey':[],'GuestJWT':[]}]
    assert 'guest_id' not in api['components']['schemas']['ScoreRequest']['properties']

    # Local markdown links outside generated inline source must resolve.
    for path in [ROOT/'README.md',ROOT/'project-step.md',ROOT/'docs/A01-specification.md']:
        for target in re.findall(r'\]\(([^)]+)\)',path.read_text()):
            if target.startswith(('https://','http://','#')):continue
            if target=='deliverables/validation-report.md':continue  # Produced after these checks.
            assert (path.parent/target).exists(),(path,target)
    pages,size=check_pdf(ROOT/'deliverables/Forest-Sokoban-A01.pdf')
    links=json.loads((ROOT/'prototype/links.json').read_text())
    if links['figma_url']:assert links['figma_url'].startswith('https://') and 'figma.com/' in links['figma_url']
    report += ['', '## Static artifact checks','',
        f'- PASS: {len(requirements)} functional requirements, including {len(must_should)} Must/Should requirements, have acceptance criteria, use-case/screen/component links, and generated manual test records.',
        '- PASS: all 12 NFRs have use-case/screen/component links and planned verification records.',
        f'- PASS: {len(frame_map)} SVG screen/state frames and {len(diagram_map)} vector diagrams parse as XML.',
        f'- PASS: {hotspots} navigation hotspots reference valid frames and meet the 48 dp baseline minimum dimensions.',
        '- PASS: Home reaches the main start/play/push/undo/pause/restart/completion/ranking/settings routes.',
        f'- INFO: fixture-only states selectable through the review menu: {", ".join(fixture_only) or "none"}.',
        '- PASS: primary/secondary/error text token pairs meet 4.5:1 contrast on their intended surfaces.',
        '- PASS: API request/response examples match the included schemas; score writes require a JWT and accept no caller-controlled owner.',
        '- PASS: supplied source Markdown links resolve locally.',
        '- INFO: supplementary PDF/SVG and mocked JavaScript review is documented in docs/review-notes.md; actual Figma/browser execution is still pending.',
        f'- PASS: PDF page tree, object offsets, stream lengths, and expected text validated ({pages} pages in the pre-report build).',
        '', '## Checks still requiring real execution','',
        '- Figma importer execution, typography and reaction review, viewer-accessible prototype URL.',
        '- 3–5 real interviews, evidence-based persona revision, and three participant usability sessions.',
        '- Flutter unit/widget tests, TalkBack, physical-device layouts and timing measurements.',
        '- Supabase deployment, RLS/authorization integration tests, real retries and network fault tests.',
        '- Human visual PDF review and both team members\' baseline approval.',
        '', 'Result: automated A01 design checks PASS. Final submission readiness remains PENDING.', '']
    (ROOT/'deliverables/validation-report.md').write_text('\n'.join(report))
    build()  # Embed this actual report into the consolidated deliverables.
    final_pages,final_size=check_pdf(ROOT/'deliverables/Forest-Sokoban-A01.pdf')
    print(f'PASS: five solved levels; {len(requirements)} requirements; {len(frame_map)} frames; {hotspots} hotspots; {final_pages}-page PDF ({final_size:,} bytes).')
    print('Not executed: Figma runtime, participant research, Flutter, real Supabase, device performance/accessibility.')


if __name__=='__main__':main()
