CBCS web interface (COMP 353 main project) - PHP 7.4 + MySQL

Files
  config.php        database connection settings (put the group password here)
  lib.php           shared helpers (connection, tables, forms, error messages)
  style.css         the look of the pages
  index.php         home
  locations.php     item 1
  personnel.php     item 2
  family.php        item 3 (primary and secondary family members)
  members.php       item 4
  teams.php         teams (needed to create team formations)
  sessions.php      items 5 and 6 (sessions, team formations, players)
  payments.php      item 7
  queries.php       items 8 to 19 (queries_data.php holds the SQL)
  triggers.php      items 20 and 21
  emails.php        item 22
  check.php         diagnostic page: PHP version, connection, number of tables and triggers

Install on AITS
  1. Build the database first: run the scripts 1, 2 and 3 of the sql folder (DBeaver, Alt+X).
  2. Open config.php and replace PUT_THE_GROUP_DATABASE_PASSWORD_HERE by the group
     database password from the AITS email.
  3. Copy all the files of this folder to /www/groups/x/xp_comp353_2/ on the ENCS server.
  4. Open https://xpc353.encs.concordia.ca/check.php (web user and password from the AITS
     email). It should say: Connection OK, 21 tables, 12 triggers.
  5. Open https://xpc353.encs.concordia.ca/index.php
