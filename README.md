Этот репозиторий содержит legacy PHP приложение. Цель текущей ветки refactor/init — подготовить глубокий рефакторинг

Быстрый локальный запуск (пример):

1) Скопируйте .env и настройте подключение к БД
   cp .env.example .env
   # Отредактируйте DB_* переменные в .env

2) Установите зависимости
   composer install

3) Импортируйте схему и seed
   mysql -u $DB_USER -p $DB_NAME < sql/schema.sql
   mysql -u $DB_USER -p $DB_NAME < sql/dc_version.sql
   mysql -u $DB_USER -p $DB_NAME < sql/dc_procs_mardb_ux.sql
   mysql -u $DB_USER -p $DB_NAME < sql/seed.sql

Что сделано в этой ветке refactor/init:
- Добавлен phinx scaffold (phinx.php, db/migrations, db/seeds)
- Добавлены sql/schema.sql и sql/seed.sql
- Добавлен базовый CI (.github/workflows/ci.yml)
- Обновлён .gitignore
