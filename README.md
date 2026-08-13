cat > README.md <<'MD'
# Decanet — Быстрый старт (инструкции)

Этот репозиторий содержит legacy PHP приложение. Цель текущей ветки refactor/init — вынести schema+seed в SQL, добавить scaffold миграций (phinx) и CI.

Быстрый локальный запуск (пример):

1) Скопируйте .env и настроьте подключение к БД
   cp .env.example .env
   # Отредактируйте DB_* переменные в .env

2) Установите зависимости
   composer install

3) Импортируйте схему и seed (временное решение — пока sql/schema.sql и sql/seed.sql содержат заглушки)
   mysql -u $DB_USER -p $DB_NAME < sql/schema.sql
   mysql -u $DB_USER -p $DB_NAME < sql/seed.sql

4) (Опционально) Запустить phinx миграции (после настройки phinx.php)
   vendor/bin/phinx migrate -c phinx.php

Что сделано в этой ветке refactor/init:
- Добавлен phinx scaffold (phinx.php, db/migrations, db/seeds)
- Добавлены sql/schema.sql и sql/seed.sql (плейсхолдеры) — нужно заменить реальными SQL из decanet_demo.zip
- Добавлен базовый CI (.github/workflows/ci.yml)
- Обновлён .gitignore

Дальше:
- Я предлагаю заменить плейсхолдеры на реальные SQL — для этого распакую decanet_demo.zip и извлеку SQL, затем обновлю sql/schema.sql и sql/seed.sql в отдельном PR.
MD