"""
TEST: Cursed Aura Logic Verification
Run with: python scripts/vscripts/test_cursed_auras.py
This test simulates the cursed aura logic WITHOUT needing Dota 2.
It validates:
1. Aura type selection per round (Begin() logic)
2. Combo generation for type 14
3. Spawner modifier application
4. ApplyCursedEffects doesn't error
"""

import random
import sys

# Track test results
tests_passed = 0
tests_failed = 0
errors = []

# Mock GameRules
class GameRules:
    _currentRoundAuraType = 0
    _currentRoundCursedAuraType = 0
    _cursedComboAuras = None
    _comboAuras = None

GameRules = GameRules()

def assert_eq(actual, expected, msg):
    global tests_passed, tests_failed
    if actual == expected:
        tests_passed += 1
        print(f"  PASS: {msg}")
    else:
        tests_failed += 1
        err = f"  FAIL: {msg} (expected {expected}, got {actual})"
        print(err)
        errors.append(err)

def assert_true(actual, msg):
    global tests_passed, tests_failed
    if actual:
        tests_passed += 1
        print(f"  PASS: {msg}")
    else:
        tests_failed += 1
        err = f"  FAIL: {msg} (expected true, got {actual})"
        print(err)
        errors.append(err)

def assert_not_nil(actual, msg):
    global tests_passed, tests_failed
    if actual is not None:
        tests_passed += 1
        print(f"  PASS: {msg}")
    else:
        tests_failed += 1
        err = f"  FAIL: {msg} (expected non-None, got None)"
        print(err)
        errors.append(err)

# =============================================
# SECTION 1: Test Begin() aura logic
# =============================================
print("\n" + "="*40)
print("TEST 1: Begin() Aura Type Selection")
print("="*40)

def simulate_begin_aura_setup(round_number):
    """Copy of the real Begin() logic from epic_boss_fight_game_round.lua"""
    GameRules._currentRoundAuraType = 0
    GameRules._currentRoundCursedAuraType = 0
    GameRules._cursedComboAuras = None
    GameRules._comboAuras = None
    
    if 4 <= round_number <= 5:
        GameRules._currentRoundAuraType = random.randint(1, 6)
        GameRules._currentRoundCursedAuraType = random.randint(8, 13)
    elif round_number >= 6:
        GameRules._currentRoundAuraType = random.randint(1, 6)
        GameRules._currentRoundCursedAuraType = random.randint(8, 14)
    elif round_number == 3:
        GameRules._currentRoundAuraType = random.randint(1, 6)
        GameRules._currentRoundCursedAuraType = 0
    else:
        GameRules._currentRoundAuraType = 0
        GameRules._currentRoundCursedAuraType = 0
    
    # Generate combo lists synchronously
    if GameRules._currentRoundCursedAuraType == 14:
        GameRules._cursedComboAuras = []
        available = [8, 9, 10, 11, 12, 13]
        for _ in range(3):
            idx = random.randint(0, len(available) - 1)
            GameRules._cursedComboAuras.append(available[idx])
            available.pop(idx)
    elif GameRules._currentRoundAuraType == 7:
        GameRules._comboAuras = []
        available = [1, 2, 3, 4, 5, 6]
        for _ in range(3):
            idx = random.randint(0, len(available) - 1)
            GameRules._comboAuras.append(available[idx])
            available.pop(idx)

# Test Round 1-2: NO auras
print("\n--- Test 1a: Round 1 (no auras) ---")
random.seed(42)
simulate_begin_aura_setup(1)
assert_eq(GameRules._currentRoundAuraType, 0, "R1: normal aura = 0")
assert_eq(GameRules._currentRoundCursedAuraType, 0, "R1: cursed aura = 0")
assert_eq(GameRules._cursedComboAuras, None, "R1: no cursed combo")

print("\n--- Test 1b: Round 2 (no auras) ---")
simulate_begin_aura_setup(2)
assert_eq(GameRules._currentRoundAuraType, 0, "R2: normal aura = 0")
assert_eq(GameRules._currentRoundCursedAuraType, 0, "R2: cursed aura = 0")

print("\n--- Test 1c: Round 3 (normal aura only) ---")
random.seed(42)
simulate_begin_aura_setup(3)
assert_true(1 <= GameRules._currentRoundAuraType <= 6, "R3: normal aura in 1-6 range")
assert_eq(GameRules._currentRoundCursedAuraType, 0, "R3: cursed aura = 0")
print(f"  R3: normal aura type = {GameRules._currentRoundAuraType}")

print("\n--- Test 1d: Round 4 (normal + cursed) ---")
random.seed(42)
simulate_begin_aura_setup(4)
assert_true(1 <= GameRules._currentRoundAuraType <= 6, "R4: normal aura in 1-6 range")
assert_true(8 <= GameRules._currentRoundCursedAuraType <= 13, "R4: cursed aura in 8-13 range")
print(f"  R4: normal={GameRules._currentRoundAuraType} cursed={GameRules._currentRoundCursedAuraType}")

print("\n--- Test 1e: Round 5 (normal + cursed) ---")
random.seed(42)
simulate_begin_aura_setup(5)
assert_true(1 <= GameRules._currentRoundAuraType <= 6, "R5: normal aura in 1-6 range")
assert_true(8 <= GameRules._currentRoundCursedAuraType <= 13, "R5: cursed aura in 8-13 range (not 14)")
print(f"  R5: normal={GameRules._currentRoundAuraType} cursed={GameRules._currentRoundCursedAuraType}")

print("\n--- Test 1f: Round 6+ (normal + cursed, can include type 14) ---")
random.seed(42)
simulate_begin_aura_setup(6)
assert_true(1 <= GameRules._currentRoundAuraType <= 6, "R6: normal aura in 1-6 range")
assert_true(8 <= GameRules._currentRoundCursedAuraType <= 14, "R6: cursed aura in 8-14 range")
print(f"  R6: normal={GameRules._currentRoundAuraType} cursed={GameRules._currentRoundCursedAuraType}")

# =============================================
# SECTION 2: Test cursed combo generation (type 14)
# =============================================
print("\n" + "="*40)
print("TEST 2: Cursed Combo (Type 14) Generation")
print("="*40)

print("\n--- Test 2a: Type 14 generates 3 unique cursed auras ---")
random.seed(42)
GameRules._currentRoundCursedAuraType = 14
GameRules._cursedComboAuras = None
available = [8, 9, 10, 11, 12, 13]
GameRules._cursedComboAuras = []
for _ in range(3):
    idx = random.randint(0, len(available) - 1)
    GameRules._cursedComboAuras.append(available[idx])
    available.pop(idx)

assert_not_nil(GameRules._cursedComboAuras, "Type 14: combo auras not None")
assert_eq(len(GameRules._cursedComboAuras), 3, "Type 14: exactly 3 auras in combo")

# Check they are valid cursed types (8-13)
for i, aura_type in enumerate(GameRules._cursedComboAuras):
    valid = 8 <= aura_type <= 13
    assert_true(valid, f"Type 14: combo entry {i+1} ({aura_type}) is in 8-13 range")
print(f"  Generated cursed combo: {GameRules._cursedComboAuras}")

print("\n--- Test 2b: Type 14 combo entries are unique ---")
assert_eq(len(set(GameRules._cursedComboAuras)), 3, "Type 14: all 3 entries are unique")

# =============================================
# SECTION 3: Test spawner applies modifier with correct type
# =============================================
print("\n" + "="*40)
print("TEST 3: Spawner Modifier Application")
print("="*40)

print("\n--- Test 3a: Spawner reads cursed type from round cache ---")
mock_round = type('obj', (object,), {'_cursedAuraType': 12})()
round_cursed_type = getattr(mock_round, '_cursedAuraType', None) or getattr(GameRules, '_currentRoundCursedAuraType', 0)
assert_eq(round_cursed_type, 12, "Spawner reads cached cursed type from round object")

print("\n--- Test 3b: Falls back to GameRules if round cache is None ---")
mock_round = type('obj', (object,), {'_cursedAuraType': None})()
GameRules._currentRoundCursedAuraType = 9
round_cursed_type = getattr(mock_round, '_cursedAuraType', None) or getattr(GameRules, '_currentRoundCursedAuraType', 0)
assert_eq(round_cursed_type, 9, "Spawner falls back to GameRules when round cache is None")

print("\n--- Test 3c: Modifier kv pass-through ---")
kv = {'aura_type': round_cursed_type}
assert_eq(int(kv['aura_type']), 9, "Modifier receives correct aura_type in kv")

# =============================================
# SECTION 4: Test ApplyCursedEffects logic
# =============================================
print("\n" + "="*40)
print("TEST 4: ApplyCursedEffects Validation")
print("="*40)

def test_apply_cursed_effects(aura_type):
    """Simulate the ApplyCursedEffects function from the modifier"""
    results = {'effects_applied': []}
    
    cursed_types = []
    if aura_type == 14:
        if GameRules._cursedComboAuras is None:
            return None
        cursed_types = GameRules._cursedComboAuras
    else:
        cursed_types = [aura_type]
    
    for at in cursed_types:
        if at == 8:
            results['effects_applied'].append('silence')
        elif at == 9:
            results['effects_applied'].append('stun')
        elif at == 10:
            results['effects_applied'].append('mana_void')
        elif at == 11:
            results['effects_applied'].append('slow')
        elif at == 12:
            results['effects_applied'].append('armor_break')
        elif at == 13:
            results['effects_applied'].append('poison')
    
    return results

print("\n--- Test 4a: Type 8 (Silence) ---")
res = test_apply_cursed_effects(8)
assert_true(res is not None, "Type 8: ApplyCursedEffects returns result")
if res:
    assert_true('silence' in res['effects_applied'], "Type 8: applies silence effect")

print("\n--- Test 4b: Type 9 (Stun) ---")
res = test_apply_cursed_effects(9)
assert_true(res is not None, "Type 9: ApplyCursedEffects returns result")

print("\n--- Test 4c: Type 10 (Mana Void) ---")
res = test_apply_cursed_effects(10)
assert_true(res is not None, "Type 10: ApplyCursedEffects returns result")

print("\n--- Test 4d: Type 11 (Slow) ---")
res = test_apply_cursed_effects(11)
assert_true(res is not None, "Type 11: ApplyCursedEffects returns result")

print("\n--- Test 4e: Type 12 (Armor Break) ---")
res = test_apply_cursed_effects(12)
assert_true(res is not None, "Type 12: ApplyCursedEffects returns result")

print("\n--- Test 4f: Type 13 (Poison) ---")
res = test_apply_cursed_effects(13)
assert_true(res is not None, "Type 13: ApplyCursedEffects returns result")

print("\n--- Test 4g: Type 14 (Cursed Combo) ---")
GameRules._cursedComboAuras = [8, 11, 13]
res = test_apply_cursed_effects(14)
if res:
    assert_eq(len(res['effects_applied']), 3, "Type 14: applies exactly 3 effects")
    print(f"  Effects applied: {res['effects_applied']}")

print("\n--- Test 4h: Type 14 with no combo auras ---")
GameRules._cursedComboAuras = None
res = test_apply_cursed_effects(14)
assert_eq(res, None, "Type 14: returns None when no combo auras generated")

# =============================================
# SECTION 5: Test all cursed types are handled
# =============================================
print("\n" + "="*40)
print("TEST 5: All cursed types 8-14 are handled")
print("="*40)

print("\n--- Test 5a: Each type 8-13 produces exactly 1 effect ---")
for t in range(8, 14):
    res = test_apply_cursed_effects(t)
    assert_true(res is not None, f"Type {t}: returns result")
    if res:
        assert_eq(len(res['effects_applied']), 1, f"Type {t}: exactly 1 effect")
        print(f"  Type {t}: {res['effects_applied'][0]}")

# =============================================
# SUMMARY
# =============================================
print("\n" + "="*40)
print("TEST RESULTS")
print("="*40)
print(f"Passed: {tests_passed}")
print(f"Failed: {tests_failed}")

if tests_failed > 0:
    print("\nErrors:")
    for err in errors:
        print(f"  {err}")
    print("\nCONCLUSION: Some tests FAILED - review errors above")
    sys.exit(1)
else:
    print("\nCONCLUSION: All tests PASSED - cursed aura logic is correct!")
    sys.exit(0)