"""A01 design verification only. No mobile app or production game implementation."""
from collections import deque

DIRECTIONS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def parse(rows):
    assert rows and len({len(row) for row in rows}) == 1, "Map must be rectangular"
    assert len(rows) <= 8 and len(rows[0]) <= 10, "Map exceeds 10 x 8"
    assert all(c in "# .$@*+" for row in rows for c in row), "Unknown tile"
    assert all(c == "#" for c in rows[0] + rows[-1]), "Top/bottom must be walls"
    assert all(row[0] == row[-1] == "#" for row in rows), "Sides must be walls"
    cells = [(x, y, c) for y, row in enumerate(rows) for x, c in enumerate(row)]
    floor = frozenset((x, y) for x, y, c in cells if c != "#")
    goals = frozenset((x, y) for x, y, c in cells if c in ".*+")
    crates = frozenset((x, y) for x, y, c in cells if c in "$*")
    players = [(x, y) for x, y, c in cells if c in "@+"]
    assert len(players) == 1, "Exactly one player required"
    assert 1 <= len(crates) <= 4 and len(crates) == len(goals), "Crate/goal mismatch"
    assert crates != goals, "Initial map must not already be solved"
    return floor, goals, (players[0], crates)


def move(floor, state, direction):
    player, crates = state
    dx, dy = DIRECTIONS[direction]
    target = (player[0] + dx, player[1] + dy)
    if target not in floor:
        return None
    if target in crates:
        beyond = (target[0] + dx, target[1] + dy)
        if beyond not in floor or beyond in crates:
            return None
        crates = frozenset((crates - {target}) | {beyond})
    return target, crates


def replay(rows, solution):
    floor, goals, state = parse(rows)
    states = [state]
    for i, direction in enumerate(solution):
        assert direction in DIRECTIONS, "Invalid solution direction"
        state = move(floor, state, direction)
        assert state is not None, f"Blocked action {i + 1}: {direction}"
        states.append(state)
        assert state[1] != goals or i == len(solution) - 1, "Solution continues after win"
    assert state[1] == goals, "Solution does not complete the level"
    return states


def shortest_solution(rows, limit=1000000):
    floor, goals, start = parse(rows)
    queue = deque([start])
    parent = {start: None}
    while queue:
        state = queue.popleft()
        if state[1] == goals:
            result = []
            while parent[state] is not None:
                previous, direction = parent[state]
                result.append(direction)
                state = previous
            return "".join(reversed(result)), len(parent)
        for direction in DIRECTIONS:
            target = move(floor, state, direction)
            if target is None or target in parent:
                continue
            # Safe pruning: a non-goal crate in a wall corner can never leave it.
            if any(c not in goals and any(
                (c[0] + ax, c[1] + ay) not in floor and
                (c[0] + bx, c[1] + by) not in floor
                for (ax, ay), (bx, by) in [((1, 0), (0, 1)), ((1, 0), (0, -1)),
                                          ((-1, 0), (0, 1)), ((-1, 0), (0, -1))])
                   for c in target[1]):
                continue
            parent[target] = (state, direction)
            assert len(parent) <= limit, "Search bound exceeded"
            queue.append(target)
    raise AssertionError("Unsolvable map")
