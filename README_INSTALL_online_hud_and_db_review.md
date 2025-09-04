# Online HUD & DB Review — Install Guide

## Files
- `content/online_hud_and_db_review/v1/theory.md`
- `content/online_hud_and_db_review/v1/demos.jsonl`
- `content/online_hud_and_db_review/v1/drills.jsonl`

## Быстрый старт (из корня репозитория)
```bash
# 1) Разzipуйте архив в корень репо (файлы попадут в ./content/...)
unzip -o online_hud_and_db_review_v1.zip

# 2) (опционально) отдельная ветка
git checkout -b feature/online-hud-and-db-review-v1

# 3) Добавьте и закоммитьте
git add content/online_hud_and_db_review/v1
git commit -m "Add online_hud_and_db_review v1 (theory, demos, drills)"
git push -u origin feature/online-hud-and-db-review-v1
```

## Альтернатива (если архив уже распакован в другое место)
```bash
# из папки с распакованным архивом
rsync -av content/ ./path/to/your/repo/content/

cd /path/to/your/repo
git add content/online_hud_and_db_review/v1
git commit -m "Add online_hud_and_db_review v1"
git push
```
