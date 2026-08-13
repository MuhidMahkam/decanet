# Decanet

PHP/MariaDB проект для учета в деканате учебного заведения (учет контингента и успеваемости студентов)

## Описание

Decanet — это веб-приложение для автоматизации учета контингента и успеваемости студентов 

## Требования

- PHP 7.4 или выше
- MariaDB 10.3 или выше (или MySQL 5.7+)
- Composer
- Git

## Установка

### 1. Клонируйте репозиторий

```bash
git clone https://github.com/MuhidMahkam/decanet.git
cd decanet
```

### 2. Установите зависимости

```bash
composer install
```

### 3. Настройте окружение

```bash
cp .env.example .env
```

Отредактируйте `.env` с вашими параметрами базы данных и приложения.

### 4. Создайте базу данных

```bash
mysql -u root -p < database.sql
```

### 5. Запустите приложение

```bash
php -S localhost:8000 -t public/
```

Откройте в браузере: http://localhost:8000

## Структура проекта

```
decanet/
├── public/          # Публичные файлы (index.php, CSS, JS, изображения)
├── src/             # Исходный код приложения (PHP классы, логика)
├── templates/       # HTML шаблоны (представления)
├── vendor/          # Зависимости Composer (не коммитится)
├── .env             # Переменные окружения (не коммитится)
├── .gitignore       # Git конфигурация
├── composer.json    # Зависимости проекта
├── composer.lock    # Фиксированные версии зависимостей
├── LICENSE          # Лицензия проекта
└── README.md        # Этот файл
```

## Зависимости

- **chillerlan/php-qrcode** — Генерация QR кодов
- **chillerlan/php-authenticator** — 2FA аутентификация

Полный список см. в `composer.json`

## Использование

[Добавьте инструкции по использованию приложения]

## Разработка

### Запуск тестов

```bash
composer test
```

### Проверка кода

```bash
composer lint
```

## Лицензия

[Укажите лицензию из файла LICENSE]

## Контакты

- Автор: MuhidMahkam
- GitHub: https://github.com/MuhidMahkam

## TODO

- [ ] Добавить юнит тесты
- [ ] Добавить интеграционные тесты
- [ ] Документировать API
- [ ] Добавить CI/CD через GitHub Actions
