"""Original vector artwork shared by SVG, PDF, local preview, and Figma import."""
from html import escape
import math

INK = "#173B32"
FOREST = "#164A3A"
PAPER = "#FFF8E7"
MUTED = "#486156"
GOLD = "#F4C766"
FLOOR = "#B4CC75"
ERROR = "#8A3028"


class Scene:
    def __init__(self, width=1280, height=720):
        self.width, self.height = width, height
        self.ops, self.links = [], []

    def rect(self, x, y, w, h, fill=PAPER, stroke=None, sw=1, radius=0):
        self.ops.append(dict(kind="rect", x=x, y=y, w=w, h=h, fill=fill, stroke=stroke, sw=sw, radius=radius))

    def ellipse(self, x, y, w, h, fill=PAPER, stroke=None, sw=1):
        self.ops.append(dict(kind="ellipse", x=x, y=y, w=w, h=h, fill=fill, stroke=stroke, sw=sw))

    def line(self, x1, y1, x2, y2, color=INK, sw=2):
        self.ops.append(dict(kind="line", x1=x1, y1=y1, x2=x2, y2=y2, stroke=color, sw=sw))

    def text(self, x, y, value, size=28, fill=INK, bold=False):
        # x,y are the top-left of a line box, not a text baseline.
        self.ops.append(dict(kind="text", x=x, y=y, text=str(value), size=size, fill=fill, bold=bold))

    def arrow(self, x1, y1, x2, y2, color=INK):
        self.line(x1, y1, x2, y2, color, 2)
        a = math.atan2(y2-y1, x2-x1)
        for offset in [-.45, .45]:
            self.line(x2, y2, x2-12*math.cos(a+offset), y2-12*math.sin(a+offset), color, 2)

    def link(self, x, y, w, h, target, label):
        self.links.append(dict(x=x, y=y, w=w, h=h, target=target, label=label))

    def svg(self):
        out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}" role="img">']
        for op in self.ops:
            k = op["kind"]
            fill = op.get("fill") or "none"
            stroke = op.get("stroke") or "none"
            style = f'fill="{fill}" stroke="{stroke}" stroke-width="{op.get("sw",1)}"'
            if k == "rect":
                out.append(f'<rect x="{op["x"]}" y="{op["y"]}" width="{op["w"]}" height="{op["h"]}" rx="{op["radius"]}" {style}/>')
            elif k == "ellipse":
                out.append(f'<ellipse cx="{op["x"]+op["w"]/2}" cy="{op["y"]+op["h"]/2}" rx="{op["w"]/2}" ry="{op["h"]/2}" {style}/>')
            elif k == "line":
                out.append(f'<line x1="{op["x1"]}" y1="{op["y1"]}" x2="{op["x2"]}" y2="{op["y2"]}" stroke="{stroke}" stroke-width="{op["sw"]}"/>')
            else:
                out.append(f'<text x="{op["x"]}" y="{op["y"]+op["size"]*.85}" font-family="Arial, sans-serif" font-size="{op["size"]}" font-weight="{700 if op["bold"] else 400}" fill="{fill}">{escape(op["text"])}</text>')
        out.append('</svg>')
        return '\n'.join(out)


def tree(s, x, y, scale=1):
    s.rect(x+28*scale, y+66*scale, 20*scale, 42*scale, "#806044", radius=8*scale)
    s.ellipse(x-6*scale, y+5*scale, 92*scale, 90*scale, "#1D6651")
    s.ellipse(x+6*scale, y-10*scale, 68*scale, 88*scale, "#278268")
    s.ellipse(x+14*scale, y-5*scale, 42*scale, 30*scale, "#369277")


def backdrop(s):
    s.rect(0, 0, 1280, 720, "#DCE8B9")
    for x, y, scale in [(20,15,1.5),(1120,25,1.6),(25,490,1.7),(1125,490,1.8),(940,5,.8),(80,290,.65)]:
        tree(s, x, y, scale)
    for x, y in [(185,95),(1090,330),(182,590),(1065,615),(915,665),(325,665)]:
        s.ellipse(x,y,11,11,GOLD)
        s.ellipse(x+15,y+4,7,7,"#7B9752")


def button(s, x, y, w, label, target=None, primary=True, h=96):
    s.rect(x,y,w,h, FOREST if primary else PAPER, stroke=FOREST, sw=2, radius=20)
    # Compact deterministic centering; labels are intentionally short.
    size = 24 if w < 150 else 28
    s.text(x+max(8,(w-len(label)*size*.56)/2),y+(h-size)/2-2,label,size,PAPER if primary else INK,True)
    if target:
        s.link(x,y,w,h,target,label)


def heading(s, title, subtitle=None, back="SCR-01"):
    button(s,40,28,150,"Back",back,False)
    s.text(225,35,title,42,INK,True)
    if subtitle:s.text(227,88,subtitle,24,MUTED)


def panel(s, x=212, y=145, w=850, h=520):
    s.rect(x,y+8,w,h,"#B5C88E",radius=28)
    s.rect(x,y,w,h,PAPER,radius=28)


def draw_board(s, level, x, y, cell=60, state=None):
    rows=level["map"]
    if state:
        player,crates=state
    else:
        player=next((cx,cy) for cy,row in enumerate(rows) for cx,c in enumerate(row) if c in '@+')
        crates={(cx,cy) for cy,row in enumerate(rows) for cx,c in enumerate(row) if c in '$*'}
    for cy,row in enumerate(rows):
        for cx,c in enumerate(row):
            xx,yy=x+cx*cell,y+cy*cell
            if c=='#':
                s.rect(xx+1,yy+1,cell-2,cell-2,"#6F8554",radius=cell*.12)
                s.rect(xx+cell*.15,yy+cell*.12,cell*.68,cell*.28,"#8DA46B",radius=cell*.08)
                continue
            s.rect(xx,yy,cell,cell,FLOOR)
            s.ellipse(xx+cell*.15,yy+cell*.7,cell*.1,cell*.05,"#90AD5A")
            goal=c in '.*+'
            if goal:
                s.ellipse(xx+cell*.24,yy+cell*.24,cell*.52,cell*.52,GOLD,FOREST,2)
                s.line(xx+cell*.5,yy+cell*.30,xx+cell*.7,yy+cell*.5,FOREST,2)
                s.line(xx+cell*.7,yy+cell*.5,xx+cell*.5,yy+cell*.7,FOREST,2)
                s.line(xx+cell*.5,yy+cell*.7,xx+cell*.3,yy+cell*.5,FOREST,2)
                s.line(xx+cell*.3,yy+cell*.5,xx+cell*.5,yy+cell*.3,FOREST,2)
            if (cx,cy) in crates:
                s.rect(xx+cell*.10,yy+cell*.13,cell*.8,cell*.78,"#B67E47",FOREST if goal else "#78502F",2,cell*.10)
                s.rect(xx+cell*.18,yy+cell*.20,cell*.64,cell*.16,"#D9AC70",radius=cell*.04)
                if goal:
                    s.line(xx+cell*.25,yy+cell*.58,xx+cell*.43,yy+cell*.74,PAPER,cell*.08)
                    s.line(xx+cell*.43,yy+cell*.74,xx+cell*.77,yy+cell*.40,PAPER,cell*.08)
                else:
                    s.line(xx+cell*.23,yy+cell*.43,xx+cell*.76,yy+cell*.8,"#E8C18B",cell*.07)
                    s.line(xx+cell*.76,yy+cell*.43,xx+cell*.23,yy+cell*.8,"#E8C18B",cell*.07)
            if (cx,cy)==player:
                s.ellipse(xx+cell*.20,yy+cell*.73,cell*.6,cell*.15,"#78954E")
                s.rect(xx+cell*.30,yy+cell*.49,cell*.4,cell*.34,"#346C91",radius=cell*.1)
                s.ellipse(xx+cell*.26,yy+cell*.17,cell*.48,cell*.46,"#EBC59E")
                s.rect(xx+cell*.18,yy+cell*.18,cell*.66,cell*.16,FOREST,radius=cell*.04)
                s.rect(xx+cell*.30,yy+cell*.04,cell*.40,cell*.22,FOREST,radius=cell*.07)


def screens(levels):
    from levels import parse, move
    result={}
    def add(id,title,s):result[id]=dict(id=id,title=title,scene=s)
    for resumed in [False,True]:
        s=Scene();backdrop(s);panel(s,145,75,990,568)
        s.text(205,117,"A LITTLE BREAK. A CLEVER MOVE.",24,MUTED,True)
        s.text(202,164,"Forest",64,FOREST,True);s.text(202,230,"Sokoban",64,FOREST,True)
        s.text(205,321,"Five clearings. No rush.",28)
        button(s,205,377,290,"Play","SCR-02")
        button(s,525,377,290,"Continue","SCR-04r" if resumed else None,False)
        if not resumed:s.text(545,481,"No saved game yet",23,MUTED)
        else:s.text(545,481,"Level 1 - saved locally",23,MUTED)
        button(s,205,521,260,"How to Play","SCR-03",False)
        button(s,485,521,260,"Leaderboard","SCR-07l",False)
        button(s,765,521,270,"Settings","SCR-08",False)
        draw_board(s,levels[0],850,150,32)
        add("SCR-01r" if resumed else "SCR-01","Home - saved game" if resumed else "Home - first visit",s)

    s=Scene();backdrop(s);heading(s,"Choose a clearing","All levels are available offline.")
    for i,l in enumerate(levels):
        x=80+i*230
        s.rect(x,174,220,328,PAPER,radius=22)
        s.text(x+18,195,f'0{i+1}',42,FOREST,True)
        for j,word in enumerate(l['name'].split(' ')):
            s.text(x+18,254+j*30,word,27,INK,True)
        s.text(x+18,361,f'{len(l["map"][0])} x {len(l["map"])}',27,MUTED)
        s.text(x+18,407,"Best: --" if i else "Best: 2 steps",23,MUTED)
        button(s,x,525,220,"Play", "SCR-04" if i==0 else f"SCR-04L{i+1}")
    s.text(84,652,"Five puzzles. Choose any clearing.",23,MUTED)
    add("SCR-02","Select Level",s)

    s=Scene();backdrop(s);heading(s,"How to Play","Push each crate onto a marked goal.");panel(s,90,155,1100,480)
    lines=["1. Tap a direction to walk one cell.","2. Push one crate at a time. You cannot pull.","3. A ring and diamond mark each goal.","4. A check marks a correctly placed crate.","5. A corner can trap a crate: use Undo or Restart."]
    for i,line in enumerate(lines):s.text(130,195+i*58,line,29)
    button(s,130,516,310,"Got it","SCR-01")
    s.text(483,538,"No timer limit. Pauses stop the clock.",27,MUTED)
    add("SCR-03","How to Play",s)

    floor,goals,start=parse(levels[0]['map']);pushed=move(floor,start,'R')
    def game(id,title,level,state=None,steps=0,note="Push the crate onto the diamond.",targets=None):
        s=Scene();backdrop(s)
        s.rect(35,24,1210,110,PAPER,radius=22)
        s.text(68,44,f'{level["id"]} / {level["name"]}',32,INK,True)
        s.text(68,88,f'Steps  {steps}',27,MUTED)
        s.text(280,88,f'Time  00:0{min(steps+1,9)}',27,MUTED)
        button(s,1050,31,180,"Pause","SCR-05i" if id=='SCR-04' else "SCR-05",False)
        cell=min(66,480/len(level['map']),660/len(level['map'][0]))
        bx=300+(660-len(level['map'][0])*cell)/2;by=157+(470-len(level['map'])*cell)/2
        draw_board(s,level,bx,by,cell,state)
        targets=targets or {}
        for label,x,y,key in [('Up',130,315,'U'),('Left',30,415,'L'),('Right',230,415,'R'),('Down',130,515,'D')]:
            button(s,x,y,96,label,targets.get(key),False)
        button(s,1020,270,220,"Undo",targets.get('undo') if steps else None,False)
        button(s,1020,390,220,"Restart","SCR-05ci" if id=='SCR-04' else "SCR-05c",False)
        button(s,1020,510,220,"Home","SCR-01r",False)
        s.rect(350,640,640,58,PAPER,radius=14)
        s.text(370,657,note,24,ERROR if 'Blocked' in note else INK)
        add(id,title,s)
    game('SCR-04','Gameplay - initial',levels[0],start,targets={'R':'SCR-04p','U':'SCR-04w'})
    game('SCR-04p','Gameplay - first push',levels[0],pushed,1,targets={'R':'SCR-06','undo':'SCR-04u'})
    # Blocked fixture is at the top boundary: upward input has no effect.
    boundary=((2,1),start[1])
    game('SCR-04w','Gameplay - beside a wall',levels[0],boundary,1,'Try Up: the wall blocks this direction.',{'U':'SCR-04b','undo':'SCR-04u'})
    game('SCR-04b','Gameplay - blocked at wall',levels[0],boundary,1,'Blocked: a wall is in the way.',{'U':'SCR-04b','undo':'SCR-04u'})
    game('SCR-04u','Gameplay - undo restores board',levels[0],start,2,'Undo restored the board. Steps still count.',{'R':'SCR-04q'})
    game('SCR-04q','Gameplay - push after undo',levels[0],pushed,3,'One more push to finish.',{'R':'SCR-06u'})
    game('SCR-04r','Gameplay - restored save',levels[0],pushed,1,'Saved game restored. Continue your puzzle.',{'R':'SCR-06','undo':'SCR-04u'})
    for i,l in enumerate(levels[1:],2):
        game(f'SCR-04L{i}',f'Gameplay - Level {i} layout preview',l,note='Walk around crates to choose a push direction.')

    def modal(id,title,body,buttons,back='SCR-04p'):
        s=Scene();backdrop(s);draw_board(s,levels[0],400,170,66,pushed)
        s.rect(235,148,810,448,FOREST,radius=30)
        s.rect(250,138,780,448,PAPER,radius=30)
        s.text(302,181,title,42,INK,True)
        for i,line in enumerate(body):s.text(302,255+i*40,line,28,MUTED)
        for i,(label,target) in enumerate(buttons):
            button(s,302+i*344,423,320,label,target,i==0)
        add(id,title,s)
    modal('SCR-05','Take a breath',['Your board is saved locally.','The clock is paused.'],[('Resume','SCR-04r'),('Home','SCR-01r')])
    modal('SCR-05i','Take a breath',['Your board is saved locally.','The clock is paused.'],[('Resume','SCR-04'),('Home','SCR-01r')])
    # Pause restart is accessible through the gameplay action rail.
    modal('SCR-05c','Restart this level?',['This attempt will be replaced.','Your personal best will be kept.'],[('Restart','SCR-04'),('Cancel','SCR-04r')])
    modal('SCR-05ci','Restart this level?',['This attempt will be replaced.','Your personal best will be kept.'],[('Restart','SCR-04'),('Cancel','SCR-04')])
    modal('SCR-05x','Saved game unavailable',['This save is damaged or incompatible.','Keep your bests; start a fresh attempt.'],[('Discard save','SCR-02'),('Back','SCR-01r')])
    modal('SCR-05s','Could not save',['Play is paused to protect your progress.','Free device storage, then try again.'],[('Retry save','SCR-04r'),('Home','SCR-01r')])
    modal('SCR-02c','Replace saved attempt?',['Only one unfinished game is stored.','Your completed levels will be kept.'],[('Replace','SCR-04L2'),('Cancel','SCR-01r')])

    for id,state,message in [('SCR-06','pending','Saved on this device. Waiting to send.'),('SCR-06s','synced','Score synced. Your best is on the board.'),('SCR-06e','error','Could not send. Your result is safe here.'),('SCR-06u','after undo','Saved on this device. Waiting to send.')]:
        s=Scene();backdrop(s);panel(s,170,76,940,570)
        s.text(245,111,'CLEARING COMPLETE',25,MUTED,True)
        s.text(245,166,'Nicely placed!',62,FOREST,True)
        s.text(245,262,'Level 1 / First Steps',32,INK,True)
        s.text(245,328,'4 steps' if id=='SCR-06u' else '2 steps',32)
        s.text(470,328,'00:05' if id=='SCR-06u' else '00:03',32)
        s.text(685,328,'Personal best',32)
        s.rect(235,396,800,78,'#E8EED5',radius=16)
        s.text(256,421,message,27,ERROR if state=='error' else INK)
        button(s,235,505,240,'Replay','SCR-04')
        button(s,495,505,260,'Levels','SCR-02',False)
        button(s,775,505,260,'Rankings' if state in ['synced','after undo'] else 'Retry','SCR-07l' if state in ['synced','after undo'] else 'SCR-06s',False)
        add(id,f'Completion - {state}',s)

    rank_states=[('', 'Leaderboard - populated','populated'),('l','Leaderboard - loading','loading'),('n','Leaderboard - empty','empty'),('e','Leaderboard - error','error'),('o','Leaderboard - offline cached','offline'),('z','Leaderboard - offline no cache','offline_empty')]
    rank_states += [(str(i),f'Leaderboard - Level {i}',f'level{i}') for i in range(2,6)]
    for suffix,title,state in rank_states:
        id='SCR-07'+suffix;s=Scene();backdrop(s);heading(s,'Leaderboard','Fewest steps first. Time breaks a tie.');panel(s,190,155,900,480)
        selected=int(state[-1]) if state.startswith('level') else 1
        for i in range(1,6):
            button(s,225+(i-1)*162,177,150,f'Level {i}','SCR-07l' if i==1 else f'SCR-07{i}',selected==i)
        button(s,1040,28,200,'Refresh','SCR-07' if selected==1 else f'SCR-07{selected}',False)
        if state in ['populated','offline'] or state.startswith('level'):
            for xx,label in [(235,'RANK'),(357,'GUEST'),(790,'STEPS'),(925,'TIME')]:
                s.text(xx,301,label,25,MUTED,True)
            for i,(name,steps,time) in enumerate([('Guest-7F2A90C1D4',2,'00:03'),('Guest-39F012B440',3,'00:05'),('Guest-0C2E44AA01',4,'00:08')]):
                yy=349+i*63
                s.text(245,yy,str(i+1),28,FOREST,True);s.text(357,yy,name,27)
                s.text(804,yy,str(steps+[0,4,8,10,23][selected-1]),28);s.text(925,yy,time,28)
            s.text(235,572,'Offline - cached 21 Oct, 15:00' if state=='offline' else 'Updated 21 Oct, 15:00 / best result per guest',24,MUTED)
        else:
            msg={'loading':('Loading scores...','Finding the latest results.'),'empty':('No results yet','Finish this level to set the first score.'),'error':('Scores could not load','Try again. You can still play offline.'),'offline_empty':('You are offline','No cached scores for this level yet.')}[state]
            s.text(252,335,msg[0],42,ERROR if state=='error' else FOREST,True)
            s.text(252,410,msg[1],28,MUTED)
            button(s,252,485,320,'Back to levels' if state=='loading' else 'Try again','SCR-02' if state=='loading' else 'SCR-07',True)
        add(id,title,s)

    for enabled in [True,False]:
        s=Scene();backdrop(s);heading(s,'Settings','Preferences stay on this device.');panel(s)
        s.text(265,220,'Sound effects',40,INK,True)
        s.text(265,283,'Short feedback for valid crate pushes.',28,MUTED)
        button(s,265,363,360,'Sound: On' if enabled else 'Sound: Off','SCR-08m' if enabled else 'SCR-08',enabled)
        s.text(265,520,'No account or network needed.',28,MUTED)
        add('SCR-08' if enabled else 'SCR-08m','Settings - sound on' if enabled else 'Settings - sound off',s)
    return result


def box(s,x,y,w,h,title,lines=(),color=PAPER):
    s.rect(x,y,w,h,color,FOREST,2,14)
    s.text(x+18,y+16,title,26,INK,True)
    for i,line in enumerate(lines):s.text(x+18,y+56+i*29,line,22,MUTED)


def diagrams(levels):
    result={}
    def start(title,h=680):
        s=Scene(1200,h);s.rect(0,0,1200,h,'#FFFFFF');s.text(30,20,title,34,FOREST,True);return s
    s=start('System architecture')
    box(s,40,135,380,240,'Android application',['Flutter UI + ViewModels','Pure Dart puzzle rules','Packaged level JSON','SQLite + secure token store'])
    box(s,735,100,410,160,'Supabase Auth',['Anonymous user session','HTTPS / refresh / secure tokens'])
    box(s,735,365,410,180,'Supabase PostgreSQL',['submit_score / get_leaderboard','Guest-bound writes; public ranking','RLS + narrow function grants'])
    s.arrow(420,190,735,180);s.text(445,137,'Online identity only',22)
    s.arrow(420,325,735,425);s.text(445,360,'HTTPS RPC',24)
    s.text(50,465,'Offline path stays entirely inside the app.',26,INK,True)
    s.text(50,510,'No separate application server or real-time multiplayer.',24,MUTED)
    result['system-architecture']=s

    s=start('In-app architecture')
    box(s,35,112,320,125,'Views',['GameView / MenuViews'])
    box(s,440,112,320,125,'ViewModels',['ChangeNotifier; intent + state'])
    box(s,855,112,310,125,'GameRules',['Pure Dart board transitions'])
    s.arrow(355,174,440,174);s.arrow(760,174,855,174)
    box(s,90,350,470,150,'Local repositories',['Session / Progress / Settings','SQLite transactions; one save slot'])
    box(s,665,350,470,150,'ScoreRepository',['Outbox / selected-level cache','SupabaseService + SecureSessionStore'])
    s.arrow(565,237,340,350);s.arrow(640,237,850,350)
    s.text(80,565,'Views do not access SQL, tokens, or remote RPC directly.',26,INK,True)
    s.text(80,610,'Rules never depend on rendering, storage, or connectivity.',25,MUTED)
    result['app-architecture']=s

    s=start('Use cases - Forest Sokoban',780)
    s.rect(270,95,680,635,None,FOREST,2,12);s.text(480,110,'Application boundary',25,INK,True)
    def actor(x,y,label):
        s.ellipse(x+24,y,32,32,None,FOREST,2);s.line(x+40,y+32,x+40,y+95);s.line(x+8,y+53,x+72,y+53);s.line(x+40,y+95,x+10,y+135);s.line(x+40,y+95,x+70,y+135);s.text(x-3,y+145,label,23,INK,True)
    actor(60,300,'Player');actor(1030,210,'Auth');actor(1025,485,'Score service')
    cases=['UC-01 Choose/start','UC-02 Play/finish','UC-03 Undo/restart','UC-04 Pause/continue','UC-05 Publish result','UC-06 View rankings','UC-07 Guide/settings']
    for i,label in enumerate(cases):
        yy=160+i*78;s.ellipse(370,yy,475,60,PAPER,FOREST,2);s.text(405,yy+17,label,25,INK,True)
        s.line(140,370,370,yy+30,MUTED,1)
    s.line(845,502,1070,300,MUTED,1);s.line(845,502,1065,535,MUTED,1);s.line(845,580,1065,535,MUTED,1)
    result['use-cases']=s

    s=start('User flow and recovery paths',840)
    nodes=[(30,110,235,100,'Home',['Play / Continue']),(370,110,265,100,'Select Level',['L01-L05; all open']),(770,110,380,100,'Gameplay',['Move / push / undo']),
           (770,340,380,130,'Pause / Restart',['Resume or confirm reset','Home retains one save']),
           (370,340,300,130,'Completion',['Persist progress + outbox','Pending / synced / error']),
           (30,340,260,130,'Leaderboard',['Loading / empty / error','Offline cache + retry']),
           (30,630,420,120,'Guide / Settings',['Learn rules; persist sound']),
           (700,630,450,120,'Recover invalid save',['Explain; explicit discard','Keep bests and outbox'])]
    for x,y,w,h,t,l in nodes:box(s,x,y,w,h,t,l)
    s.arrow(265,160,370,160);s.arrow(635,160,770,160);s.arrow(960,210,960,340);s.arrow(770,430,670,430);s.arrow(770,220,670,340);s.arrow(370,405,290,405)
    s.arrow(130,210,130,340);s.arrow(130,470,130,630);s.arrow(1000,470,1000,630)
    s.text(390,545,'Resume / Retry preserve local state',24,INK,True)
    result['user-flow']=s

    s=start('Logical data model - location and cardinality',850)
    box(s,35,105,355,200,'Level (packaged + mirror)',['PK: id + version','map / dimensions / title','Immutable per version'])
    box(s,470,105,330,200,'GameSession (local)',['PK: slot = 1; attempt UUID','FK: level_id + version','positions / history / counters'])
    box(s,850,105,315,200,'Progress (local)',['PK/FK: level + version','completed / best pair'])
    box(s,35,410,355,170,'GuestProfile (remote)',['PK: auth_user_id','1:1 with Auth user','generated display name'])
    box(s,470,410,330,200,'ScoreReceipt (remote)',['FK: guest + level/version','UQ: guest + submission UUID','steps / time / received_at'])
    box(s,850,410,315,200,'ScoreSubmission (local)',['PK: submission UUID','attempt / level / score','pending / synced / rejected'])
    s.arrow(390,175,470,175);s.text(397,140,'1 : 0..1',18)
    s.arrow(800,175,850,175)
    s.arrow(210,305,520,410);s.text(258,345,'1 level : many receipts',22)
    s.arrow(390,500,470,500);s.text(392,463,'1 : N',20)
    s.arrow(850,540,800,540);s.text(820,570,'sync',18)
    s.text(40,690,'Local-only: LeaderboardCache(level/version, fetched_at, public rows)',25)
    s.text(40,740,'Local-only: Settings(sound_enabled). No access tokens in SQLite.',25)
    result['erd']=s

    def sequence(name,title,actors,events):
        s=start(title,940);xs=[110+i*(980/(len(actors)-1)) for i in range(len(actors))]
        for x,a in zip(xs,actors):
            s.rect(x-90,100,180,70,PAPER,FOREST,2,10);s.text(x-79,122,a,22,INK,True);s.line(x,170,x,850,'#B2C3B7',1)
        for i,(src,dst,label) in enumerate(events):
            y=218+i*73
            if src==dst:
                s.line(xs[src],y,xs[src]+55,y);s.line(xs[src]+55,y,xs[src]+55,y+25);s.arrow(xs[src]+55,y+25,xs[src],y+25)
                s.text(xs[src]+65,y-10,label,20)
            else:
                s.arrow(xs[src],y,xs[dst],y);s.text(min(xs[src],xs[dst])+12,y-29,label,20)
        result[name]=s
    sequence('sequence-play','Move, persist, undo, and complete',['Player','ViewModel','GameRules','Repository'],[
        (0,1,'Tap direction'),(1,2,'tryMove(board, direction)'),(2,1,'Blocked: unchanged / valid: new board'),(1,3,'Valid only: persist snapshot + counters'),(3,1,'Commit succeeds / pause on save error'),(0,1,'Undo: restore previous board; +1 action'),(1,3,'Persist undo without rewinding time'),(1,3,'If solved: result + outbox; clear save'),(1,0,'Render board or Completion')])
    sequence('sequence-resume','Pause, save, and restore',['Player / OS','ViewModel','LocalStore'],[
        (0,1,'Pause or background'),(1,1,'Freeze timer / audio / input'),(1,2,'Flush active time + current snapshot'),(0,1,'Reopen and choose Continue'),(1,2,'Load one unfinished attempt'),(2,1,'Saved session or missing/corrupt state'),(1,1,'Validate schema / level / positions'),(1,0,'Valid: resume; invalid: explicit discard')])
    sequence('sequence-online','Idempotent score sync and ranking read',['App / Outbox','Supabase Auth','Score RPC'],[
        (0,0,'Offline: retain local result; no request'),(0,1,'Online: anonymous session / refresh'),(1,0,'JWT or recoverable Auth error'),(0,2,'submit_score: same UUID on every retry'),(2,0,'Accepted / duplicate / conflict / failure'),(0,0,'Ack only on success; otherwise keep pending'),(0,2,'get_leaderboard(selected level/version)'),(2,0,'Top 20 or empty/error response'),(0,0,'Cache by level; discard stale responses')])

    s=start('Original level catalogue',1200)
    for i,l in enumerate(levels):
        x=40+(i%2)*590;y=110+(i//2)*350
        s.text(x,y,f'{l["id"]} / {l["name"]}',28,INK,True)
        draw_board(s,l,x,y+52,27)
        s.text(x+295,y+90,f'{len(l["solution"])} steps',25,FOREST,True)
        sol=l['solution']
        for j in range(0,len(sol),15):s.text(x+295,y+135+(j//15)*28,sol[j:j+15],22)
    result['level-catalogue']=s
    return result
