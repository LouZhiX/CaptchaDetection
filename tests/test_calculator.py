"""计算器单测（真实 pytest 会跑这些）"""
import pytest
from calculator_core import add, sub, mul, div, percent, eval_op


def test_add():
    assert add(1, 2) == 3
    assert add(-1, 1) == 0


def test_sub():
    assert sub(10, 3) == 7


def test_mul():
    assert mul(3, 4) == 12
    assert mul(-2, 5) == -10


def test_div():
    assert div(10, 2) == 5


def test_div_by_zero():
    with pytest.raises(ZeroDivisionError):
        div(1, 0)


def test_percent():
    assert percent(50) == 0.5


def test_eval_op_all():
    assert eval_op("+", 2, 3) == 5
    assert eval_op("-", 5, 2) == 3
    assert eval_op("*", 2, 3) == 6
    assert eval_op("/", 6, 2) == 3
