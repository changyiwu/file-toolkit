# Excel 處理 recipe

套件：`openpyxl`（讀寫與格式）、`matplotlib`（統計圖）。一般成績工作不需要 `pandas`。

---

## E0. 動手前先看清楚表格長什麼樣

**不要假設欄位名稱**。先印出前幾列再寫邏輯：

```python
# -*- coding: utf-8 -*-
from openpyxl import load_workbook

workbook = load_workbook("grades.xlsx", data_only=True)   # data_only：讀公式的結果值
for name in workbook.sheetnames:
    sheet = workbook[name]
    print(f"[{name}] {sheet.max_row} 列 x {sheet.max_column} 欄")
    for row in sheet.iter_rows(min_row=1, max_row=5, values_only=True):
        print(row)
```

常見狀況：前幾列是標題／說明，真正的欄位名在第 2、3 列；有合併儲存格；
分數欄混著「缺考」「請假」等文字。寫程式前先跟使用者確認怎麼處理。

---

## E1. 總分、排名、不及格標紅、各班平均

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from openpyxl import load_workbook
from openpyxl.styles import Font, PatternFill

SUBJECTS = ["國文", "英文", "數學"]        # 依實際欄位調整
PASS_LINE = 60

workbook = load_workbook("grades.xlsx", data_only=True)
sheet = workbook.active
header = [str(c.value).strip() if c.value is not None else "" for c in sheet[1]]
column_of = {name: index + 1 for index, name in enumerate(header)}

red_fill = PatternFill(start_color="FFC7CE", end_color="FFC7CE", fill_type="solid")
red_font = Font(color="9C0006", bold=True)

total_column = sheet.max_column + 1
rank_column = total_column + 1
sheet.cell(row=1, column=total_column, value="總分")
sheet.cell(row=1, column=rank_column, value="排名")

totals = []
for row_index in range(2, sheet.max_row + 1):
    scores = []
    for subject in SUBJECTS:
        cell = sheet.cell(row=row_index, column=column_of[subject])
        value = cell.value if isinstance(cell.value, (int, float)) else None
        scores.append(value)
        if value is not None and value < PASS_LINE:      # 不及格標紅
            cell.fill, cell.font = red_fill, red_font
    total = sum(v for v in scores if v is not None)
    sheet.cell(row=row_index, column=total_column, value=total)
    totals.append((row_index, total))

# 同分同名次（1,2,2,4）
for row_index, total in totals:
    rank = sum(1 for _, other in totals if other > total) + 1
    sheet.cell(row=row_index, column=rank_column, value=rank)

# 平均列放最後
average_row = sheet.max_row + 1
sheet.cell(row=average_row, column=1, value="全班平均")
for subject in SUBJECTS:
    column = column_of[subject]
    values = [sheet.cell(row=r, column=column).value for r in range(2, average_row)]
    values = [v for v in values if isinstance(v, (int, float))]
    if values:
        sheet.cell(row=average_row, column=column, value=round(sum(values) / len(values), 2))

Path("output").mkdir(exist_ok=True)
workbook.save("output/grades_已計算.xlsx")     # 存新檔，不要覆蓋原始成績
```

缺考／請假等非數字一律當作「不列入計算」，並在回報時說明有幾筆。

---

## E2. 依欄位把大表拆成多個檔（各班、各導師）

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from collections import defaultdict
from openpyxl import load_workbook, Workbook

KEY = "班級"

sheet = load_workbook("全校成績.xlsx", data_only=True).active
rows = list(sheet.iter_rows(values_only=True))
header, body = rows[0], rows[1:]
key_index = header.index(KEY)

groups = defaultdict(list)
for row in body:
    if any(row):
        groups[row[key_index]].append(row)

output_dir = Path("output/依班級"); output_dir.mkdir(parents=True, exist_ok=True)
for key, group_rows in groups.items():
    workbook = Workbook()
    new_sheet = workbook.active
    new_sheet.title = str(key)
    new_sheet.append(list(header))
    for row in group_rows:
        new_sheet.append(list(row))
    new_sheet.freeze_panes = "A2"
    workbook.save(output_dir / f"{key}.xlsx")

print({key: len(value) for key, value in groups.items()})   # 驗收：各檔人數加總要等於原始列數
```

只複製值，不複製格式。使用者若要保留原本的欄寬與底色，改成「複製原檔再刪掉別班的列」。

---

## E3. 隨機座位表／分組

```python
# -*- coding: utf-8 -*-
import random
from openpyxl import load_workbook, Workbook
from openpyxl.styles import Alignment

ROWS, COLUMNS, SEED = 5, 6, 20260801        # 固定 seed 才能重現同一張表

sheet = load_workbook("名單.xlsx", data_only=True).active
students = [f"{r[0]} {r[1]}" for r in sheet.iter_rows(min_row=2, values_only=True) if r[0]]

random.Random(SEED).shuffle(students)
seats = students + [""] * (ROWS * COLUMNS - len(students))

workbook = Workbook()
new_sheet = workbook.active
new_sheet.title = "座位表"
new_sheet.append(["講台" if c == COLUMNS // 2 else "" for c in range(COLUMNS)])
for row_index in range(ROWS):
    new_sheet.append(seats[row_index * COLUMNS:(row_index + 1) * COLUMNS])
for row in new_sheet.iter_rows():
    for cell in row:
        cell.alignment = Alignment(horizontal="center", vertical="center")
for column in range(1, COLUMNS + 1):
    new_sheet.column_dimensions[chr(64 + column)].width = 14

workbook.save("output/座位表.xlsx")
```

分組同理：`groups = [students[i::group_count] for i in range(group_count)]`。
有特殊需求（不能同組、要平均分配男女）一定要先問清楚，別自己假設。

---

## E4. 各題答對率／分數分布圖

```python
# -*- coding: utf-8 -*-
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from openpyxl import load_workbook

# 中文一定要設字型，否則圖上是方框
plt.rcParams["font.sans-serif"] = ["Microsoft JhengHei", "Noto Sans TC", "DFKai-SB"]
plt.rcParams["axes.unicode_minus"] = False

sheet = load_workbook("答題明細.xlsx", data_only=True).active
header = [c.value for c in sheet[1]]
records = [row for row in sheet.iter_rows(min_row=2, values_only=True) if any(row)]

question_columns = [i for i, name in enumerate(header) if str(name).startswith("第")]
rates = []
for index in question_columns:
    answers = [row[index] for row in records]
    correct = sum(1 for a in answers if a == 1)          # 依實際編碼調整（1＝答對）
    rates.append(correct / len(answers) * 100)

figure, axes = plt.subplots(figsize=(10, 4))
axes.bar([header[i] for i in question_columns], rates, color="#4c78a8")
axes.axhline(60, color="crimson", linestyle="--", linewidth=1)
axes.set_ylabel("答對率 (%)"); axes.set_ylim(0, 100)
axes.set_title("各題答對率")
figure.tight_layout()
figure.savefig("output/答對率.png", dpi=150)
```

分數分布圖用 `axes.hist(scores, bins=range(0, 101, 10))`。
兩張圖都畫完後，回報時直接指出「第 N 題答對率最低」這種老師真正想知道的結論。
