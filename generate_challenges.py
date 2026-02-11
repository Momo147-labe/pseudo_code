import json
import random
import uuid
from datetime import datetime
import re
import math

def map_difficulty(type_name):
    type_name = type_name.upper()
    if "BASES" in type_name: return "Easy", 25
    if "CONDITIONNELLES" in type_name: return "Medium", 50
    if "ITERATIVES" in type_name: return "Medium", 75
    if "TABLEAUX" in type_name and "2D" not in type_name: return "Hard", 150
    if "PROCEDURES" in type_name or "FONCTIONS" in type_name: return "Hard", 200
    if "RECURSIVES" in type_name or "MATRICES" in type_name or "APPROFONDISSEMENTS" in type_name: return "Expert", 500
    return "Medium", 100

def generate_test_cases(enonce, type_ex):
    low = enonce.lower()
    cases = []

    # 1. Simple Output
    if "bonjour" in low or "merci momo" in low:
        output = "Bonjour" if "bonjour" in low else "Merci MOMO"
        for _ in range(10): cases.append({"input": "", "output": output})
    
    # 2. Temperature
    elif "fahrenheit" in low and "celsius" in low:
        for _ in range(10):
            if "inverse" in low or "celsius en degrés fahrenheit" in enonce.lower():
                c = random.randint(-40, 100)
                f = (c * 9/5) + 32
                cases.append({"input": str(c), "output": str(round(f, 2))})
            else:
                f = random.randint(-40, 212)
                c = (f - 32) * 5/9
                cases.append({"input": str(f), "output": str(round(c, 2))})

    # 3. Geometry
    elif "rayon" in low and ("cercle" in low or "sphère" in low):
        for _ in range(10):
            r = random.randint(1, 100)
            p = 2 * math.pi * r
            s = math.pi * r * r
            v = (4/3) * math.pi * (r**3)
            cases.append({"input": str(r), "output": f"Périmètre: {round(p, 2)}\nSurface: {round(s, 2)}\nVolume: {round(v, 2)}"})

    # 4. Salary
    elif "salaire" in low:
        for _ in range(10):
            v1, v2, v3 = random.randint(100, 1000), random.randint(50, 100), round(random.uniform(0.05, 0.15), 2)
            cases.append({"input": f"{v1}\n{v2}\n{v3}", "output": str(round((v1*v2)*(1-v3), 2))})

    # 5. Swap
    elif "échange" in low or "échanger" in low:
        for _ in range(10):
            a, b = random.randint(1, 100), random.randint(1, 100)
            cases.append({"input": f"{a}\n{b}", "output": f"A={b}, B={a}"})

    # 6. Units
    elif "pouce" in low and "pied" in low:
        for _ in range(10):
            if "inverse" in low:
                p = random.randint(1, 100)
                cases.append({"input": str(p), "output": f"{p//12} pieds et {p%12} pouces"})
            else:
                pi, po = random.randint(1, 10), random.randint(0, 11)
                cases.append({"input": f"{pi}\n{po}", "output": f"{pi*12+po} pouces"})

    # 7. Math series / series
    elif "somme s =" in low or "somme" in low and "1 à n" in low:
        for _ in range(10):
            n = random.randint(1, 100)
            cases.append({"input": str(n), "output": str(sum(range(1, n+1)))})

    # 8. Tables
    elif "table de multiplication" in low:
        for _ in range(10):
            n = random.randint(1, 10)
            res = "\n".join([f"{n} * {j} = {n*j}" for j in range(1, 11)])
            cases.append({"input": str(n), "output": res})

    # 9. Parity
    elif "pair" in low or "impair" in low:
        for _ in range(10):
            n = random.randint(0, 100)
            cases.append({"input": str(n), "output": "pair" if n % 2 == 0 else "impair"})

    # 10. Max/Min
    elif any(w in low for w in ["grand", "petit", "maximum", "minimum"]):
        cnt = 3 if "trois" in low else 2
        for _ in range(10):
            nums = [random.randint(1, 100) for _ in range(cnt)]
            cases.append({"input": "\n".join(map(str, nums)), "output": str(max(nums) if "grand" in low or "maximum" in low else min(nums))})

    # 11. Physics
    elif "chute libre" in low:
        for _ in range(10):
            t = random.randint(1, 10)
            cases.append({"input": str(t), "output": str(round(0.5 * 9.81 * t * t, 2))})

    # 12. Arrays
    elif "tableau" in low:
        for _ in range(10):
            nums = [random.randint(1, 50) for _ in range(5)]
            cases.append({"input": "\n".join(map(str, nums)), "output": str(sum(nums))})

    # 13. Matrices
    elif "matrice" in low:
        for _ in range(10):
            cases.append({"input": "2", "output": "Identité 2x2"})

    # Catch All for anything else - Basic echo or simple math
    if not cases:
        for _ in range(10):
            num = random.randint(1, 100)
            # Default to sum of inputs if multiple required, or just echo
            cases.append({"input": f"{num}\n{num+5}", "output": str(num * 2 + 5)})

    return cases

def transform():
    with open("assets/exercices.json", "r", encoding="utf-8") as f:
        exercices = json.load(f)

    challenges = []
    for ex in exercices:
        num = ex.get("numero") or ex.get("titre") or "Exo"
        type_ex = ex.get("type", "GÉNÉRAL")
        enonce = ex.get("enonce", "")
        
        test_cases = generate_test_cases(enonce, type_ex)
        diff, xp = map_difficulty(type_ex)

        challenges.append({
            "id": str(uuid.uuid4()),
            "title": f"Exercice {num}: {type_ex}",
            "description": enonce,
            "instructions": f"Objectif : {enonce}",
            "difficulty": diff,
            "xp_reward": xp,
            "initial_code": "Algorithme Solution\nDébut\nFin",
            "test_cases": test_cases,
            "created_at": datetime.now().isoformat()
        })

    with open("assets/challenges.json", "w", encoding="utf-8") as f:
        json.dump(challenges, f, indent=2, ensure_ascii=False)
    print(f"Generated {len(challenges)} challenges.")

if __name__ == "__main__":
    transform()
