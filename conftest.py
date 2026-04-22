"""pytest 配置：把项目根目录加入 sys.path，使得 test 能 import 根目录模块"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
