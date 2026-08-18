-- Make demo from real backup

USE decanet;


DROP TABLE IF EXISTS _tmp_delcnts;
CREATE TABLE _tmp_delcnts (TNAME varchar(50), DCNT int);


DROP TABLE IF EXISTS _div_del_lst;
CREATE TABLE _div_del_lst AS
SELECT D.DIVISION_ID, S.STREAM_ID, G.SGROUP_ID, SG.STUDENT_ID, SG.STUDSGRP_ID
  FROM division d LEFT JOIN
       stream S USING (DIVISION_ID) LEFT JOIN
       sgroup G USING (STREAM_ID) LEFT JOIN
       studsgrp SG USING (SGROUP_ID)
  WHERE D.FACULTET_ID > 1 OR
        -- S.STREAM_FROMYEAR < 2006;
        (S.STREAM_FROMYEAR < 2015 OR S.STREAM_FROMYEAR > 2025);

CREATE INDEX IDX_DIVDEL ON _div_del_lst(DIVISION_ID, STREAM_ID, SGROUP_ID, STUDENT_ID, STUDSGRP_ID);

SELECT COUNT(STUDSGRP_ID) FROM _div_del_lst INTO @div_del;

INSERT INTO _tmp_delcnts VALUES ('SELDIV', @div_del);


-- CREATE TABLE _div_del_lst AS
--  SELECT * FROM div_del_lst;
-- CREATE INDEX IDX_DIVDEL ON _div_del_lst(DIVISION_ID, STUDENT_ID, STUDSGRP_ID, STREAM_ID, DSESSION_ID, MAINPROG_ID, MPROGSUBJ_ID);

SET FOREIGN_KEY_CHECKS = 0;

-- DIVISION_ID, STREAM_ID, SGROUP_ID, STUDENT_ID, STUDSGRP_ID, DSESSION_ID
DELETE division
  FROM division JOIN
       _div_del_lst L USING (DIVISION_ID);

INSERT INTO _tmp_delcnts VALUES ('division',  ROW_COUNT());


-- добор подвисающих студентов - КОСТЫЛЬ
DROP TABLE IF EXISTS _1_div_del_lst;
CREATE TABLE _1_div_del_lst AS
SELECT SG.DIVISION_ID, NULL AS STREAM_ID, SG.SGROUP_ID, SG.STUDENT_ID, SG.STUDSGRP_ID
  FROM studsgrp SG LEFT JOIN
       division D USING (DIVISION_ID)
  WHERE D.DIVISION_ID IS NULL;

SELECT COUNT(STUDSGRP_ID) FROM _1_div_del_lst INTO @_1_div_del;

INSERT INTO _tmp_delcnts VALUES ('_+_SELDIV', @_1_div_del);

INSERT INTO _div_del_lst
  SELECT * FROM _1_div_del_lst;

DELETE stream
  FROM stream JOIN
       _div_del_lst L USING (STREAM_ID);

INSERT INTO _tmp_delcnts VALUES ('stream',  ROW_COUNT());

DELETE sgroup
  FROM sgroup JOIN
       _div_del_lst L USING (SGROUP_ID);

INSERT INTO _tmp_delcnts VALUES ('sgroup',  ROW_COUNT());

DELETE student
FROM student JOIN
     _div_del_lst L USING (STUDENT_ID);

INSERT INTO _tmp_delcnts VALUES ('student',  ROW_COUNT());

DELETE studadd
  FROM studadd JOIN
       _div_del_lst L USING (STUDENT_ID);

INSERT INTO _tmp_delcnts VALUES ('studadd',  ROW_COUNT());

DELETE studsgrp
  FROM studsgrp JOIN
       _div_del_lst L USING (STUDSGRP_ID);

INSERT INTO _tmp_delcnts VALUES ('studsgrp',  ROW_COUNT());

DELETE contingent
  FROM contingent JOIN
       _div_del_lst L USING (STUDSGRP_ID);

INSERT INTO _tmp_delcnts VALUES ('contingent',  ROW_COUNT());

DELETE document
  FROM document  JOIN
       studdoc USING (DOCUMENT_ID) JOIN
       _div_del_lst L USING (STUDSGRP_ID);

INSERT INTO _tmp_delcnts VALUES ('document studdoc',  ROW_COUNT());
DELETE studdoc
  FROM studdoc JOIN
       _div_del_lst L USING (STUDSGRP_ID);

INSERT INTO _tmp_delcnts VALUES ('studdoc',  ROW_COUNT());



-- MAINPROG_ID, PERSPROG_ID, ACAD_ID, MPROGSUBJ_ID

DROP TABLE IF EXISTS _acad_del_lst;
CREATE TABLE _acad_del_lst AS
SELECT PP.MAINPROG_ID, PP.PERSPROG_ID, A.ACAD_ID, J.MPROGSUBJ_ID, S.DSESSION_ID
  FROM _div_del_lst LEFT JOIN
       persprog PP USING (STUDSGRP_ID) LEFT JOIN
       mainprog M USING (MAINPROG_ID)LEFT JOIN
       acad A USING (PERSPROG_ID) LEFT JOIN
       mprogsubj J USING (MAINPROG_ID) LEFT JOIN
       dsession S USING (DSESSION_ID);

SELECT COUNT(PERSPROG_ID) FROM _acad_del_lst INTO @aca_del;

INSERT INTO _tmp_delcnts VALUES ('SELACAD', @aca_del);

CREATE INDEX IDX_ACADEL ON _acad_del_lst(MAINPROG_ID, PERSPROG_ID, ACAD_ID, MPROGSUBJ_ID, DSESSION_ID);

DELETE mainprog
  FROM mainprog JOIN
       _acad_del_lst L USING (MAINPROG_ID);

INSERT INTO _tmp_delcnts VALUES ('mainprog',  ROW_COUNT());

DELETE persprog
  FROM persprog JOIN
       _acad_del_lst L USING (PERSPROG_ID);

INSERT INTO _tmp_delcnts VALUES ('persprog',  ROW_COUNT());

DELETE acad
  FROM acad JOIN
       _acad_del_lst L USING (ACAD_ID);

INSERT INTO _tmp_delcnts VALUES ('acad',  ROW_COUNT());

DELETE mprogsubj
  FROM mprogsubj JOIN
       _acad_del_lst L USING (MPROGSUBJ_ID);

INSERT INTO _tmp_delcnts VALUES ('mprogsubj',  ROW_COUNT());

DELETE document
  FROM document  JOIN
       progdoc USING (DOCUMENT_ID) JOIN
       _acad_del_lst L USING (PERSPROG_ID);

INSERT INTO _tmp_delcnts VALUES ('document progdoc',  ROW_COUNT());

DELETE progdoc
  FROM progdoc JOIN
       _acad_del_lst L USING (PERSPROG_ID);

INSERT INTO _tmp_delcnts VALUES ('progdoc',  ROW_COUNT());

DELETE dsession
  FROM dsession JOIN
       _acad_del_lst L USING (DSESSION_ID);

INSERT INTO _tmp_delcnts VALUES ('dsession',  ROW_COUNT());

DELETE FROM facultet WHERE
  FACULTET_ID > 1;

INSERT INTO _tmp_delcnts VALUES ('facultet',  ROW_COUNT());

-- почистить документы
DELETE contingent, acad, progdoc, document
FROM document LEFT JOIN
     acad USING (DOCUMENT_ID) LEFT JOIN
     progdoc USING (DOCUMENT_ID) LEFT JOIN
     contingent USING (DOCUMENT_ID)
  WHERE (DOCUMENT_TEMPFLAG AND
        DOCUMENT_OUTDATE < CurDate() - INTERVAL 6 MONTH) OR
        FACULTET_ID > 1;


SET FOREIGN_KEY_CHECKS = 1;



DROP TEMPORARY TABLE IF EXISTS _fname;
DROP TEMPORARY TABLE IF EXISTS _mname;
DROP TEMPORARY TABLE IF EXISTS _lname;
DROP TEMPORARY TABLE IF EXISTS _tmp_stud;

CREATE TEMPORARY TABLE _fname(FNAME varchar(50), SEX int);
CREATE TEMPORARY TABLE _mname(MNAME varchar(50), SEX int);
CREATE TEMPORARY TABLE _lname(LNAME varchar(50), SEX int);
CREATE TEMPORARY TABLE _tmp_stud(FNAME varchar(50), MNAME varchar(50), LNAME varchar(50), SEX int);

INSERT INTO _fname VALUES ('Августа',0),('Августина',0),('Агата',0),('Агния',0),('Алевтина',0),('Алеандра',0),('Александр',1),('Александра',0),('Алексей',1),('Алена',0),('Алина',0),('Алиса',0),('Алла',0),('Альберт',1),('Альбина',0),('Альфия',0),('Анастасия',0),('Анатолий',1),('Ангелина',0),('Андрей',1),('Анжела',0),('Анжелика',0),('Анисья',0),('Анна',0),('Антон',1),('Апполинария',0),('Аркадий',1),('Арсений',1),('Артем',1),('Артур',1),('Афира',0),('Борис',1),('Булат',1),('Вагиз',1),('Вадим',1),('Валентин',1),('Валентина',0),('Валерий',1),('Вальдемар',1),('Варвара',0),('Василий',1),('Василина',0),('Василя',0),('Венер',1),('Венера',0),('Вениамин',1),('Венцислав',1),('Вера',0),('Вероника',0),('Виктор',1),('Виктория',0),('Вильгельм',1),('Винарис',1),('Виолетта',0),('Виталий',1),('Владимир',1),('Владислав',1),('Владлена',0),('Вячеслав',1),('Галина',0),('Гелий',1),('Гельмут',1),('Геннадий',1),('Георгий',1),('Григорий',1),('Гульшат',0),('Дамир',1),('Данат',1),('Даниил',1),('Данил',1),('Данила',1),('Дарий',1),('Дария',0),('Дарья',0),('Денис',1),('Диана',0),('Дина',0),('Динара',0),('Дмитрий',1),('Ева',0),('Евгений',1),('Евгения',0),('Евдокия',0),('Егор',1),('Екатерина',0),('Елена',0),('Елизавета',0),('Ефим',1),('Жанна',0),('Зинаида',0),('Зоя',0),('Иван',1),('Игорь',1),('Ида',0),('Изалия',0),('Ильмира',0),('Ильнар',1),('Илья',1),('Инга',0),('Инна',0),('Ираида',0),('Ирина',0),('Ия',0),('Казимир',1),('Капитолина',0),('Карина',0),('Кирилл',1),('Клавдия',0),('Клара',0),('Климентий',1),('Константин',1),('Кристина',0),('Ксения',0),('Лариса',0),('Лев',1),('Ленара',0),('Леонид',1),('Леся',0),('Лиана',0),('Лидия',0),('Лиза',0),('Лилия',0),('Линар',1),('Линда',0),('Луиза',0),('Лэйла',0),('Любава',0),('Любовь',0),('Людмила',0),('Люция',0),('Майя',0),('Максим',1),('Маргарита',0),('Марина',0),('Мария',0),('Михаил',1),('Надежда',0),('Наиль',0),('Наталия',0),('Наталья',0),('Неля',0),('Никита',1),('Николай',1),('Нина',0),('Оксана',0),('Олег',1),('Олесь',1),('Олеся',0),('Ольга',0),('Павел',1),('Павла',0),('Петр',1),('Полина',0),('Раиса',0),('Рамиль',0),('Рафаэль',0),('Регина',0),('Римма',0),('Ринат',1),('Роберт',1),('Роза',0),('Роман',1),('Рудольф',1),('Руслан',1),('Рустам',1),('Салават',1),('Светлана',0),('Святослав',1),('Семен',1),('Серафим',1),('Серафима',0),('Сергей',1),('Софья',0),('Станислав',1),('Степан',1),('Тамара',0),('Татьяна',0),('Тимофей',1),('Тимур',1),('Трофим',1),('Ульяна',0),('Федор',1),('Фидарис',1),('Филипп',1),('Эдвард',1),('Эдуард',1),('Элеонора',0),('Эльвина',0),('Эльвира',0),('Эльдар',1),('Эльза',0),('Эмилия',0),('Эмма',0),('Юлий',1),('Юлия',0),('Юрий',1),('Ялина',0),('Яна',0),('Янис',1);
INSERT INTO _mname VALUES ('Абдуловна',0),('Абировна',0),('Адгамовна',0),('Адольфовна',0),('Адыповна',0),('Азатовна',0),('Азифовна',0),('Акимович',1),('Александрович',1),('Александровна',0),('Алексеевич',1),('Алексеевна',0),('Аликович',1),('Аликовна',0),('Алмасович',1),('Альбертович',1),('Альбертовна',0),('Амирхановна',0),('Анасович',1),('Анасовна',0),('Анатольевич',1),('Анатольевна',0),('Анатоьевна',0),('Андреевич',1),('Андреевна',0),('Анисимовна',0),('Антиповна',0),('Антоновна',0),('Аркадьевич',1),('Аркадьевна',0),('Арнольдовна',0),('Артемьевич',1),('Артемьевна',0),('Артурович',1),('Афанасьевич',1),('Афанасьевна',0),('Ахматовна',0),('Ахметзяновна',0),('Ахметович',1),('Ахметовна',0),('Борисович',1),('Борисовна',0),('Булатович',1),('Булатовна',0),('Вадимович',1),('Вадимовна',0),('Валентинович',1),('Валентиновна',0),('Валерьевич',1),('Валерьевна',0),('Валиевич',1),('Васильевич',1),('Васильевна',0),('Вахилевна',0),('Вахитович',1),('Венерович',1),('Вениаминовна',0),('Викторович',1),('Викторовна',0),('Виниаминовна',0),('Витальевич',1),('Витальевна',0),('Владиленовна',0),('Владимирович',1),('Владимировна',0),('Владиславович',1),('Владиславовна',0),('Вольдемарович',1),('Всеволодович',1),('Всеволодовна',0),('Вячеславович',1),('Вячеславовна',0),('Габтулловна',0),('Гавриловна',0),('Газизович',1),('Гайдарович',1),('Гайнуллович',1),('Галактионовна',0),('Галимьянович',1),('Гаязович',1),('Гельмутович',1),('Геннадьевич',1),('Геннадьевна',0),('Генриховна',0),('Георгиевич',1),('Георгиевна',0),('Германовна',0),('Гилязовна',0),('Григорьевич',1),('Григорьевна',0),('Гусманович',1),('Давыдовна',0),('Дальевна',0),('Дамильевич',1),('Дамирович',1),('Данилович',1),('Даниловна',0),('Дарвиновна',0),('Дементьевна',0),('Демьянович',1),('Джамильевна',0),('Дмитриевич',1),('Дмитриевна',0),('Евгеньевич',1),('Евгеньевна',0),('Евдокимович',1),('Евдокимовна',0),('Евстегнеевич',1),('Евстегнеевна',0),('Егорович',1),('Егоровна',0),('Ефимович',1),('Ефимовна',0),('Жоржевич',1),('Зарифовна',0),('Захарович',1),('Зиновьевич',1),('Зотеевна',0),('Зуфарович',1),('Ибрагимович',1),('Ибрахимович',1),('Иванович',1),('Ивановна',0),('Игнатьевич',1),('Игнатьевна',0),('Игоревич',1),('Игоревна',0),('Идрисовна',0),('Илхамович',1),('Ильгизовна',0),('Ильгизяровна',0),('Ильинична',0),('Ильинишна',0),('Ильич',1),('Ильфатовна',0),('Иосифович',1),('Иосифовна',0),('Ирэкович',1),('Искандерович',1),('Ишханович',1),('Казаровна',0),('Калистратович',1),('Камаловна',0),('Камилевна',0),('Карлович',1),('Касимович',1),('Каюмовна',0),('Куприяновна',0),('Кириллович',1),('Константинович',1),('Константиновна',0),('Кузьмовна',0),('Лазаревна',0),('Леонидович',1),('Леонидовна',0),('Леоновна',0),('Леонтьевна',0),('Лукашевич',1),('Лукич',1),('Луффирович',1),('Львович',1),('Львовна',0),('Мавлитовна',0),('Магомедович',1),('Макарович',1),('Макаровна',0),('Максимова',0),('Максимович',1),('Максимовна',0),('Мансурович',1),('Мансуровна',0),('Маратович',1),('Маратовна',0),('Маркович',1),('Марксович',1),('Марсович',1),('Марсовна',0),('Матвеевич',1),('Матвеевна',0),('Митрофанович',1),('Митрофановна',0),('Михайлович',1),('Михайловна',0),('Михеевич',1),('Модестовна',0),('Мокеевна',0),('Мударисович',1),('Назиевна',0),('Назимович',1),('Наилевич',1),('Наилевна',0),('Наумович',1),('Наумовна',0),('Никитович',1),('Никифоровна',0),('Николаевич',1),('Николаевна',0),('Никонорович',1),('Никоноровна',0),('Ниловна',0),('Нургалеевич',1),('Нургалиевич',1),('Нургаянович',1),('Нурмамедовна',0),('Олегович',1),('Олеговна',0),('Павлович',1),('Павловна',0),('Петрович',1),('Петровна',0),('Поликарповна',0),('Прокопьевич',1),('Прокопьевна',0),('Равилевна',0),('Равильевич',1),('Равильевна',0),('Раисович',1),('Раисовна',0),('Рамилевна',0),('Рамильевна',0),('Рафаэльевич',1),('Робертович',1),('Романович',1),('Романовна',0),('Рудольфович',1),('Салаватович',1),('Салаватовна',0),('Салимьянович',1),('Сарварович',1),('Семенович',1),('Семёновна',0),('Семёнович',1),('Серафимовна',0),('Сергеевич',1),('Сергеевна',0),('Сиониевич',1),('Спиридоновна',0),('Станиславович',1),('Станиславовна',0),('Стапановна',0),('Степанович',1),('Степановна',0),('Сулейманович',1),('Сулеймановна',0),('Суфхатовна',0),('Табрисовна',0),('Талгатович',1),('Талгатовна',0),('Тахирович',1),('Тельмановна',0),('Тимофеевич',1),('Тимофеевна',0),('Тихоновна',0),('Трифоновна',0),('Трофимович',1),('Трофимовна',0),('Фавилович',1),('Федорович',1),('Федоровна',0),('Федотовна',0),('Феофанович',1),('Фигатович',1),('Фридрихович',1),('Фридриховна',0),('Фролович',1),('Христофорович',1),('Христофоровна',0),('Эдуардович',1),('Эдуардовна',0),('Эрнстович',1),('Юзикович',1),('Юлаевич',1),('Юльевич',1),('Юрьевич',1),('Юрьевна',0),('Юсупович',1),('Яковлевич',1),('Яковлевна',0),('Ярополовна',0);
INSERT INTO _lname VALUES ('Абрамов',1),('Абрамова',0),('Авдеев',1),('Авдеева',0),('Авдеенко',1),('Агафонов',1),('Агафонова',0),('Аксенов',1),('Аксенова',0),('Акулов',1),('Алабугин',1),('Алабугина',0),('Александров',1),('Александрова',0),('Алексеев',1),('Алексеева',0),('Алешин',1),('Алешкевич',1),('Алмазова',0),('Алтынова',0),('Андреев',1),('Андреева',0),('Андреевский',1),('Андреевских',1),('Анисимов',1),('Анисимова',0),('Анохин',1),('Арбузов',1),('Арбузова',0),('Артамонов',1),('Артамонова',0),('Артемьев',1),('Артемьева',0),('Архипенко',1),('Архипов',1),('Астафьев',1),('Астафьева',0),('Бабаева',0),('Бабкин',1),('Баженов',1),('Баженова',0),('Бакин',1),('Бакина',0),('Баранов',1),('Баранова',0),('Батраков',1),('Батракова',0),('Батурин',1),('Батурина',0),('Беззубова',0),('Безрукова',0),('Безуглов',1),('Безуглова',0),('Белобородов',1),('Белобородова',0),('Белов',1),('Белова',0),('Беляев',1),('Беляева',0),('Беляков',1),('Бердюгин',1),('Бердюгина',0),('Березин',1),('Березина',0),('Беркутов',1),('Беркутова',0),('Бессонов',1),('Бессонова',0),('Блинов',1),('Блохина',0),('Бобров',1),('Боброва',0),('Бобылев',1),('Бойко',1),('Боков',1),('Болдырев',1),('Болотников',1),('Болотникова',0),('Болотов',1),('Борзов',1),('Борисенко',1),('Борисов',1),('Борисова',0),('Брусницын',1),('Брызгалов',1),('Булатов',1),('Булатова',0),('Бушуев',1),('Бушуева',0),('Буянов',1),('Ваганов',1),('Ваганова',0),('Вдовин',1),('Вдовцев',1),('Ведерников',1),('Ведерникова',0),('Винокуров',1),('Винокурова',0),('Володин',1),('Володина',0),('Воронина',0),('Воронкова',0),('Воронова',0),('Воронцова',0),('Ворошилов',1),('Ворошилова',0),('Гаврилов',1),('Герасимов',1),('Герасимова',0),('Гладков',1),('Гладкова',0),('Глазунов',1),('Глазунова',0),('Добрынин',1),('Добрынина',0),('Евдокимов',1),('Евдокимова',0),('Евсеев',1),('Евсеева',0),('Елохов',1),('Елохова',0),('Епанчев',1),('Епанчева',0),('Ермолин',1),('Ермолина',0),('Жарков',1),('Жаркова',0),('Жданов',1),('Жданова',0),('Жуков',1),('Жукова',0),('Зайцев',1),('Зайцева',0),('Залесов',1),('Залесова',0),('Захаров',1),('Захарова',0),('Зинин',1),('Зинина',0),('Зотов',1),('Зотова',0),('Зуев',1),('Зуева',0),('Зыкин',1),('Зыкина',0),('Зыков',1),('Зыкова',0),('Иванов',1),('Иванова',0),('Игнатьев',1),('Игнатьева',0),('Исаев',1),('Исаева',0),('Казаков',1),('Казакова',0),('Казанцев',1),('Казанцева',0),('Климов',1),('Климова',0),('Козлов',1),('Козлова',0),('Коновалов',1),('Коновалова',0),('Корзунин',1),('Корзунина',0),('Коркин',1),('Коркина',0),('Королев',1),('Королева',0),('Коротков',1),('Короткова',0),('Корякин',1),('Корякина',0),('Кошкин',1),('Кошкина',0),('Краев',1),('Краева',0),('Лихачев',1),('Лихачева',0),('Малышев',1),('Малышева',0),('Медведев',1),('Медведева',0),('Носков',1),('Носкова',0),('Овчинников',1),('Овчинникова',0),('Орлов',1),('Орлова',0),('Отраднов',1),('Отраднова',0),('Ощепков',1),('Павлов',1),('Павлова',0),('Панов',1),('Пахомов',1),('Пахомова',0),('Пеньков',1),('Первитский',1),('Первухина',0),('Перевалов',1),('Перевалова',0),('Першин',1),('Першина',0),('Петров',1),('Петрова',0),('Пирогов',1),('Плаксин',1),('Подкорытова',0),('Полежаев',1),('Полежаева',0),('Поликарпов',1),('Попов',1),('Попова',0),('Пронин',1),('Пронина',0),('Романов',1),('Романова',0),('Рыбина',0),('Рыбникова',0),('Рыжков',1),('Рыжкова',0),('Рябинин',1),('Рябков',1),('Рябов',1),('Рябова',0),('Самсонова',0),('Санников',1),('Санникова',0),('Севастьянов',1),('Севастьянова',0),('Селиванов',1),('Селиванова',0),('Серов',1),('Серова',0),('Синицина',0),('Смирнов',1),('Смирнова',0),('Солдатова',0),('Солнцев',1),('Спиридонов',1),('Спиридонова',0),('Спирина',0),('Староверов',1),('Стародубцева',0),('Старостина',0),('Старцев',1),('Старцева',0),('Субботин',1),('Субботина',0),('Суботина',0),('Суслов',1),('Суслова',0),('Сухарев',1),('Сухарева',0),('Тимофеева',0),('Титов',1),('Титова',0),('Тихомиров',1),('Тихонов',1),('Тихонова',0),('Толмачев',1),('Толмачева',0),('Третьяков',1),('Третьякова',0),('Трифонова',0),('Троицкая',0),('Тюрин',1),('Тюрина',0),('Уткин',1),('Уткина',0),('Федоров',1),('Федорова',0),('Федосеев',1),('Федосеева',0),('Фомин',1),('Фомина',0),('Харитонов',1),('Харитонова',0),('Хомякова',0),('Храмцов',1),('Храмцова',0),('Чащин',1),('Чащина',0),('Чернов',1),('Чернова',0),('Шилов',1),('Шилова',0),('Ширяев',1),('Шубин',1),('Шубина',0),('Щукин',1),('Юдин',1),('Юдина',0),('Якимов',1),('Якимова',0),('Яковлев',1),('Яковлева',0),('Ярославцев',1),('Ярославцева',0);


DROP TEMPORARY TABLE IF EXISTS _xnames;
CREATE TEMPORARY TABLE _xnames(XID INT AUTO_INCREMENT,
                               PRIMARY KEY  (XID),
                               FNAME varchar(50),
                               MNAME varchar(50),
                               LNAME varchar(50),
                               SEX int);

DELIMITER $$

DROP PROCEDURE IF EXISTS MAKEXNAMES $$
CREATE PROCEDURE MAKEXNAMES()
BEGIN
  DECLARE done boolean;

  REPEAT
    DROP TEMPORARY TABLE IF EXISTS _id_fname;
    DROP TEMPORARY TABLE IF EXISTS _id_mname;
    DROP TEMPORARY TABLE IF EXISTS _id_lname;

    CREATE TEMPORARY TABLE _id_fname AS
      SELECT floor(1 + rand()*299) AS SORT, FNAME, SEX
        FROM _fname;

    CREATE TEMPORARY TABLE _id_mname AS
      SELECT floor(1 + rand()*299) AS SORT, MNAME, SEX
        FROM _mname;

    CREATE TEMPORARY TABLE _id_lname AS
      SELECT floor(1 + rand()*299) AS SORT, LNAME, SEX
        FROM _lname;

    INSERT INTO _tmp_stud
      SELECT X.FNAME, X.MNAME, X.LNAME, X.SEX
        FROM (SELECT floor(1 + rand()*299) AS SORT,
                     F.FNAME, M.MNAME, L.LNAME, F.SEX
                FROM _id_lname L JOIN
                     _id_fname F USING (SORT, SEX) JOIN
                     _id_mname M USING (SORT, SEX)
                ORDER BY 1) X;

    SET done = ((SELECT COUNT(SEX) FROM _tmp_stud) > 8000);

  UNTIL done END REPEAT;

END $$

DELIMITER ;

CALL MAKEXNAMES();

INSERT INTO _xnames(FNAME, MNAME, LNAME, SEX)
  SELECT * FROM _tmp_stud;

-- DECANET
  UPDATE student LEFT JOIN
         _xnames ON STUDENT_ID = XID
    SET student_fname  = fname,
        student_mname  = mname,
        student_lname  = lname,
        student_zachno  = (floor(10000 + rand()*89999)),
        student_persno  = student_id,
        student_strahno  = CONCAT(floor(10000 + rand()*89999), '-', floor(10000 + rand()*89999));


  UPDATE studadd LEFT JOIN
         _xnames ON STUDENT_ID = XID
    SET student_sex = IF(SEX = 0, 'Ж', 'М'),
        student_passpno     = CONCAT(floor(10 + rand()*99), 'АА №', floor(10000 + rand()*89999)),
        country_id          = 7,
        city_id             = null,
        foreignlan_id       = 1,
        student_postindex   = (floor(620000 + rand()*9999)),
        student_npunkt      = null,
        student_street      = null,
        student_bldno       = null,
        student_flatno      = null,
        student_birthday    = date_add('1970-01-01 00:00:00', interval (floor(rand()*20*365)) day),
        student_father      = null,
        student_fatherwork  = null,
        student_mother      = null,
        student_motherwork  = null,
        student_email       = null,
        student_phone1      = null,
        student_phone2      = null,
        student_phone3      = null,
        student_obaddr      = null,
        student_firm        = null,
        student_addwork     = null,
        student_firstwork   = null,
        student_photopath   = null,
        student_desc        = null;

  UPDATE studadd
    SET student_famstate = IF (STUDENT_SEX = 'М', 'холост', 'не замужем');

  UPDATE person LEFT JOIN
         _xnames ON PERSON_ID = XID
    SET person_fname  = fname,
        person_mname  = mname,
        person_lname  = lname;

DROP TEMPORARY TABLE IF EXISTS _fname;
DROP TEMPORARY TABLE IF EXISTS _mname;
DROP TEMPORARY TABLE IF EXISTS _lname;
DROP TEMPORARY TABLE IF EXISTS _tmp_stud;
DROP TEMPORARY TABLE IF EXISTS _xnames;

  UPDATE school
    SET SCHOOL_ABBR = 'УЛТИ',
        SCHOOL_NAME = 'Уральский лесотехнический институт',
        SCHOOL_STREET = NULL,
        SCHOOL_BLDNO = NULL
     WHERE SCHOOL_ID = 1;

  UPDATE facultet
    SET FACULTET_ABBR = 'ЛХФ',
        FACULTET_NAME = 'Лесохозяйственный факультет'
     WHERE FACULTET_ID = 1;

-- demo
-- DELETE FROM decanet.syslog;

DELETE FROM duser;
CALL CREATEUSER(3,'demo','demo','demo_db','demo_pass','', '','Anonimous', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);