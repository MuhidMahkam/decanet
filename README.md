Removed bundled composer artifacts from src/ and added instructions about demo DB import.

- Removed: src/composer.phar, src/composer.lock
- Updated .gitignore to ignore those files
- README: added note about demo DB archive at sql/decanet_demo.zip and example import command

How to import demo DB (example):

```bash
# unzip and import
unzip sql/decamet_demo.zip -d /tmp/decanet_demo
mysql -u $DB_USER -p $DB_NAME < /tmp/decanet_demo/decadet_demo.sql
```
