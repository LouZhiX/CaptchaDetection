"""SpecKit 生成的计算器核心（Python 版本，用于单测）
这与前端 calculator.js 的逻辑等价，用 pytest 可直接验证。
"""


def add(a: float, b: float) -> float:
    return a + b


def sub(a: float, b: float) -> float:
    return a - b


def mul(a: float, b: float) -> float:
    return a * b


def div(a: float, b: float) -> float:
    if b == 0:
        raise ZeroDivisionError("division by zero")
    return a / b


def percent(a: float) -> float:
    return a / 100


def eval_op(op: str, a: float, b: float) -> float:
    return {"+": add, "-": sub, "*": mul, "/": div}[op](a, b)
