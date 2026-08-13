<?php

include "global.php";

unset($_SESSION['ref_doc_id']);

getdbrow("STUDENT_ITM({$_SESSION['co_student']})", $row);
//$_SESSION['co_earth'] = $row['EARTH_ID'];
$_SESSION['co_country'] = $row['COUNTRY_ID'];
$_SESSION['co_city'] = $row['CITY_ID'];
$_SESSION['co_school'] = $row['SCHOOL_ID'];
$_SESSION['co_facultet'] = $row['FACULTET_ID'];
$_SESSION['co_division'] = $row['DIVISION_ID'];
$_SESSION['co_sgroup'] = $row['SGROUP_ID'];

setobject();

$studstat = $row['STUDENT_ACTIVE'];
$stm = array('Студент:','личное','доп.свед.','успеваемость','контингент','документы','листы');
$MAIN .= menu('stm');

switch($_SESSION['stm']){
//личные данные студента / доп. свед
  case 0:
  case 1:

//    $form = false;
//    if(isset($_GET['change']) && !isset($_REQUEST['cancel']))
      $form = true;
    $dopsv = false;
    if($_SESSION['stm'] == 1)
      $dopsv = true;

    //читаем даные из базы
    getdbrow("STUDADD_ITM({$_SESSION['co_student']})", $row);
    $eduform = $row['EDUFORM_ID'];
    $persno = $row['STUDENT_PERSNO'];
    $zachno = $row['STUDENT_ZACHNO'];
    $strahno = $row['STUDENT_STRAHNO'];
    $fname = $row['STUDENT_FNAME'];
    $mname = $row['STUDENT_MNAME'];
    $lname = $row['STUDENT_LNAME'];
    $sex = $row['STUDENT_SEXID'];
    $paspno = $row['STUDENT_PASSPNO'];
    $city = $row['CITY_ID'];
    $postindex = $row['STUDENT_POSTINDEX'];
    $npunkt = $row['STUDENT_NPUNKT'];
    $street = $row['STUDENT_STREET'];
    $bldno = $row['STUDENT_BLDNO'];
    $fltno = $row['STUDENT_FLATNO'];
    $birtday = $row['STUDENT_BIRTHDAY'];b2d($birtday);
    $cnt_id = $row['COUNTRY_ID'];
    $famstate = $row['STUDENT_FAMSTATEID'];
    $father = $row['STUDENT_FATHER'];
    $fatherwork = $row['STUDENT_FATHERWORK'];
    $mother = $row['STUDENT_MOTHER'];
    $motherwork = $row['STUDENT_MOTHERWORK'];
    $email = $row['STUDENT_EMAIL'];
    $tel1 = $row['STUDENT_PHONE1'];
    $tel2 = $row['STUDENT_PHONE2'];
    $tel3 = $row['STUDENT_PHONE3'];
    $obadr = $row['STUDENT_OBADDR'];
    $foreignlan = $row['FOREIGNLAN_ID'];
    $firm = $row['STUDENT_FIRM'];
    $addwork = $row['STUDENT_ADDWORK'];
    $firstwork = $row['STUDENT_FIRSTWORK'];
    $photopath = $row['STUDENT_PHOTOPATH'];
    $desc = $row['STUDENT_DESC'];

    //читаем даные из $_GET
    getp('eduform');getp('persno');getp('zachno');
    getp('strahno');getp('fname');getp('mname');getp('lname');
    getp('sex');getp('paspno');getp('city');getp('postindex');
    getp('npunkt');getp('street');getp('bldno');getp('fltno');
    getp('birtday');getp('cnt_id');getp('famstate');getp('father');
    getp('fatherwork');getp('mother');getp('motherwork');getp('email');
    getp('tel1');getp('tel2');getp('tel3');getp('obadr');
    getp('foreignlan');getp('firm');getp('addwork');getp('firstwork');
    getp('photopath');getp('desc');
    getdt('gbirtday_x','birtday',1);

    if(isset($_REQUEST['cancel']))
      dcgoto("{$__routedurlpage__}");

    //сохранение личных данных студента
    if(isset($_REQUEST['ok']) || (isset($_REQUEST['setd'])) || (isset($_REQUEST['delf']))){
      //загрузка файла
      $uploadfile = '';
      if(isset($_FILES['userfile']['name']))
        if($_FILES['userfile']['name'] != ''){
// $uploaddir = 'c:\\decanet\\files';
        $uploaddir = 'files';
        if(!file_exists($uploaddir)) 
          mkdir($uploaddir);
        $uploaddir .= "/photo";
        if(!file_exists($uploaddir)) 
          mkdir($uploaddir);
        $uploaddir .= "/".$_SESSION['co_facultet'];
        if(!file_exists($uploaddir)) 
          mkdir($uploaddir);
        $path_parts = pathinfo($_FILES['userfile']['name']);
        $uploadfile = $uploaddir."/".$_SESSION['co_student'].".".@$path_parts['extension'];
        if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile))
          $MESS = "Файл загружен.";
        else{
          $ERMESS = "Ошибка! Невозможно загрузить файл.";
          $uploadfile = '';
        }
      }
      if($uploadfile != '')
        $photopath = $uploadfile;
      if(isset($_REQUEST['delf']) && $photopath){
        unlink($photopath);
        $photopath = '';
      }
      i2b($eduform);s2b($persno);s2b($zachno);
      s2b($strahno);s2b($fname);s2b($mname);s2b($lname);
      i2b($sex);s2b($paspno);i2b($city);i2b($postindex);
      s2b($npunkt);s2b($street);s2b($bldno);s2b($fltno);
      d2b($birtday);i2b($cnt_id);i2b($famstate);s2b($father);
      s2b($fatherwork);s2b($mother);s2b($motherwork);s2b($email);
      s2b($tel1);s2b($tel2);s2b($tel3);s2b($obadr);
      i2b($foreignlan);s2b($firm);s2b($addwork);s2b($firstwork);
      s2b($photopath);s2b($desc);
      //запись в базу
      getdbrow("STUDADD_CNG({$_SESSION['co_student']},$eduform,$persno,$zachno,$strahno,$fname,$mname,$lname,$sex,$paspno,$city,$postindex,$npunkt,$street,$bldno,$fltno,$birtday,$cnt_id,$famstate,$father,$fatherwork,$mother,$motherwork,$email,$tel1,$tel2,$tel3,$obadr,$foreignlan,$firm,$addwork,$firstwork,$photopath,$desc)", $row1);
      dcgoto("{$__routedurlpage__}");
    }

  //отображение личных данных студента
    $photo = '';
    $apic = $photopath;
    $src = '';
    if(!$apic)
      $apic = 'ФОТОГРАФИЯ ОТСУТСТВУЕТ';
    else
      $src = "src='$apic'";
    $MAIN .= "<table width=100%>";
    if($form)
      $MAIN .= "<form name=osn enctype=multipart/form-data method=post>";
    if(!$dopsv){ //основные данные
      $MAIN .= "<tr>";
      $MAIN .= "<td valign=top rowspan=17><img $src align=top width=150 alt='$apic'>";
      if($form){
        $MAIN .= "<input type=hidden name=MAX_FILE_SIZE value=1000000>";
        $MAIN .= "<br><br><span id=col4>смена фотографии</span><br><input size=6 name=userfile type=file><br>";
        $MAIN .= "<input type=submit name=delf value='Удалить фото'></td>";
      }
      $MAIN .= "</td>";
      $MAIN .= "<td width=30%></td><td width=70%></td>";
      $MAIN .= "</tr>";
      pole('Фамилия','lname',20,'','','',true,true,$form);
      pole('Имя','fname',20,'','','',true,true,$form);
      pole('Отчество','mname',20,'','','',true,true,$form);
      pole('Личный номер','persno',20,'','','',true,true,$form);
      pole('Зачетная книжка №','zachno',20,'','','',true,true,$form);
      pole('Страховой полис №','strahno',20,'','','',true,true,$form);
      pole('Паспорт №','paspno',20,'','','',true,true,$form);
      $add = '';
      if($form)
        $add = " <input type=image $P_CAL name=gbirtday>";
      pole('День рождения','birtday',10,'','','',true,true,$form,$add);
      pole('Пол','sex',3,'SEX_LST()','SEX','SEX_ID',true,true,$form);
      pole('Семейное положение','famstate',20,'FAMSTATE_LST()','FAMSTATE','FAMSTATE_ID',true,true,$form);
      pole('Иностранный язык','foreignlan',20,'FOREIGNLAN_LST()','FOREIGNLAN_NAME','FOREIGNLAN_ID',true,true,$form);
      pole('Гражданство','cnt_id',20,'COUNTRY_LST(1)','COUNTRY_SNAME','COUNTRY_ID',true,true,$form);
      pole('Форма обучения','eduform',20,'EDUFORM_LST()','EDUFORM_NAME','EDUFORM_ID',true,false,$form);
      pole('E-mail','email',20,'','','',true,true,$form);
    }
    else{ //дополнительные данные
      $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
      pole('Областной город','city',80,'ALLCITY_LST()','CITY_NAME','CITY_ID',true,true,$form);
      $MAIN .= "<tr><td align=center colspan=2>";
      pole('Индекс','postindex',3,'','','',false,true,$form);
      $MAIN .= "&nbsp";
      pole('Н.пункт','npunkt',15,'','','',false,true,$form);
      $MAIN .= "&nbsp";
      pole('Улица','street',20,'','','',false,true,$form);
      $MAIN .= "&nbsp";
      pole('Дом','bldno',3,'','','',false,true,$form);
      $MAIN .= "&nbsp";
      pole('Квартира','fltno',3,'','','',false,true,$form);
      $MAIN .= "</td></tr>";
      $MAIN .= "<tr><td align=center colspan=2>";
      pole('Телефон 1','tel1',20,'','','',false,true,$form);
      $MAIN .= "&nbsp";
      pole('Телефон 2','tel2',20,'','','',false,true,$form);
      $MAIN .= "&nbsp";
      pole('Телефон 3','tel3',20,'','','',false,true,$form);
      $MAIN .= "</td></tr>";
      pole('ФИО отца','father',80,'','','',true,true,$form);
      pole('Место работы отца','fatherwork',80,'','','',true,true,$form);
      pole('ФИО матери','mother',80,'','','',true,true,$form);
      pole('Место работы матери','motherwork',80,'','','',true,true,$form);
      pole('Адрес в общежитии','obadr',80,'','','',true,true,$form);
      pole('Предприятие-куратор','firm',80,'','','',true,true,$form);
      pole('Предприятие-работодатель1','firstwork',80,'','','',true,true,$form);
      pole('Предприятие-работодатель2','addwork',80,'','','',true,true,$form);
      pole('Разное','desc',80,'','','',true,true,$form);
    }
    if($form){
      $MAIN .= "<tr>";
      if($dopsv)
        $MAIN .= "<input type=hidden name=dopsv value=1>";
      $MAIN .= "<td align=right><input type=submit name=ok value='Принять'></td>";
      $MAIN .= "<td><input type=submit name=cancel value='Отменить'></td>";
      $MAIN .= "</tr></form>";
    }
    $MAIN .= "</table>";
//    $MENU .= "<a href='{$__routedurlpage__}?change=1'>Изменить</a><br>";
    $MENU .= "<a href='docum.php?sid={$_SESSION['co_student']}&type=9&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='docum.php?sid={$_SESSION['co_student']}&type=9'>\"Справка\"</a><br>";
    $MENU .= "<a href='docum.php?sid={$_SESSION['co_student']}&type=10&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='docum.php?sid={$_SESSION['co_student']}&type=10'>\"Справка_ПФ\"</a><br>";
    break;

  case 2:
  //удаление дисциплины из индивидуальной программы
  fdel('ppid_del','PERSPROG_DEL','Удалить пункт из индивидуальной программы?');

  //изменение дисциплины по выбору
    if(isset($_GET['ch_pp']) && isset($_GET['pp_id1']) && isset($_GET['mps_id']))
      getdbmass("PPROGSUBJ_CNG({$_GET['pp_id1']},{$_GET['mps_id']})", $mass);

    if(isset($_GET['change_pp']) && isset($_GET['pp_id']) && isset($_GET['mp_id'])){
      $pp_id = $_GET['pp_id'];
      $mp_id = $_GET['mp_id'];
      head('Выбор дисциплины из набора');
//      $cp = page($all, $MCNT, "change_pp=1&pp_id=$pp_id&mp_id=$mp_id");
      getdbmass("MPROGITEM_LST($mp_id)", $mass);
      messall($mass);
      $MAIN .= "<table width='100%'>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "<td>Дисциплина</td>";
      $MAIN .= "</tr>";
      $n=0;
      while(getrow($mass, $row)){
        $n++;
        $rcolor = "id=col2";
        if($n%2)
          $rcolor = "id=col1";
        $MAIN .= "<tr $rcolor>";
        getp('ret');
        $ch = '';
        if(!$ret)
          $ch = "&pp_id=$pp_id";
        $MAIN .= "<td><a href='student.php?ch_pp=1&pp_id1=$pp_id&mps_id={$row['MPROGSUBJ_ID']}$ch'>{$row['SUBJ_NAME']}</a></td>";
        $MAIN .= "</tr>";
        if(($n >= $MAXREC) && (!isset($_GET['allview'])))
          break;
      }
      $MAIN .= "</table>";
      mainpaint();
    }

  //академические данные студента

    getp('pp_id');
    getp('ppid_man');
    getp('ppid_man1');

    if($ppid_man){
      //перезачет
      fdel('ppid_man1','MANUALPPSYNC_CNG','Выполнить перезачет?',"$ppid_man,",'',0);

      head('Выбор прямого вариана перезачета:');
      getdbmass("MANUALPPSYNC_LST($ppid_man)", $mass);
      if(!$mass->num_rows){
        $MAIN .= "Прямых вариантов перезачета не найдено!";
      }
      else{
        messall($mass);
        $MAIN .= "<table width='100%'>";
        $MAIN .= "<tr id=head>";
        $MAIN .= "<td>Семестр</td>";
        $MAIN .= "<td>Вид контроля</td>";
        $MAIN .= "<td>Дисциплина</td>";
        $MAIN .= "<td>Часов</td>";
        $MAIN .= "<td>Оценка</td>";
        $MAIN .= "<td>Тип</td>";
        $MAIN .= "<td>№док.</td>";
        $MAIN .= "<td>Дата</td>";
        $MAIN .= "</tr>";
        $n=0;
        while(getrow($mass, $row))
        {
          $n++;
          if($n%2)
            $rcol = 1;
          else
            $rcol = 2;
          if(isset($row['RESULT_ABBR']))
            $rcol += 2;
          $MAIN .= "<tr id=col{$rcol}>";
          $MAIN .= "<td>{$row['SEMESTR']}</td>";
          $MAIN .= "<td>{$row['CONTROL_ABBR']}</td>";
          $MAIN .= "<td><a href='{$__routedurlpage__}?ppid_man=$ppid_man&ppid_man1={$row['PERSPROG_ID']}'>{$row['SUBJ_NAME']}</a></td>";
          $MAIN .= "<td>{$row['VOLUME']}</td>";
          $MAIN .= "<td>{$row['RESULT_ABBR']}</td>";
          $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
          $MAIN .= "<td>{$row['DOCUMENT_NO']}</td>";
          $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
          $MAIN .= "</tr>";
          if(($n >= $MAXREC) && (!isset($_GET['allview'])))
            break;
        }
        $MAIN .= "</table>";
      }

      head('Выбор варианта перезачета вручную:');
      getdbmass("ALLPPSYNC_LST($ppid_man)", $mass);
      if(!$mass->num_rows){
        $MAIN .= "Вариантов перезачета вручную не найдено!";
      }
      else{
        messall($mass);
        $MAIN .= "<table width='100%'>";
        $MAIN .= "<tr id=head>";
        $MAIN .= "<td>Семестр</td>";
        $MAIN .= "<td>Вид контроля</td>";
        $MAIN .= "<td>Дисциплина</td>";
        $MAIN .= "<td>Часов</td>";
        $MAIN .= "<td>Оценка</td>";
        $MAIN .= "<td>Тип</td>";
        $MAIN .= "<td>№док.</td>";
        $MAIN .= "<td>Дата</td>";
        $MAIN .= "</tr>";
        $n=0;
        while(getrow($mass, $row))
        {
          $n++;
          if($n%2)
            $rcol = 1;
          else
            $rcol = 2;
          if(isset($row['RESULT_ABBR']))
            $rcol += 2;
          $MAIN .= "<tr id=col{$rcol}>";
          $MAIN .= "<td>{$row['SEMESTR']}</td>";
          $MAIN .= "<td>{$row['CONTROL_ABBR']}</td>";
          $MAIN .= "<td><a href='{$__routedurlpage__}?ppid_man=$ppid_man&ppid_man1={$row['PERSPROG_ID']}'>{$row['SUBJ_NAME']}</a></td>";
          $MAIN .= "<td>{$row['VOLUME']}</td>";
          $MAIN .= "<td>{$row['RESULT_ABBR']}</td>";
          $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
          $MAIN .= "<td>{$row['DOCUMENT_NO']}</td>";
          $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
          $MAIN .= "</tr>";
          if(($n >= $MAXREC) && (!isset($_GET['allview'])))
            break;
        }
        $MAIN .= "</table>";
      }

      mainpaint();
    }




    if($pp_id && !isset($_GET['del'])){
      if($cancel)
        dcgoto("{$__routedurlpage__}");
  //данные по выбранной дисциплине
//    head('Данные академической успеваемости студента по дисциплине');
      getdbrow("STUDSEMACAD_ITM($pp_id)", $row);
      $cn =  $row['CONTROL_NAMED'];
      $pnn = $row['PERSNAME_NAME'];
      $vol = $row['VOLUME'];
      $cef = $row['CONTROL_ENDFLAG'];
      getp('pnn');
      getp('vol');
      if($ok){
      //изменение темы и часов
        s2b($pnn);
        s2b($vol);
        if($vol == 'NULL')
          $vol = 0;
        getdbmass("PPROGNAME_ADD($pp_id,$pnn)", $mass);
        getdbmass("PERSPROG_CNG($pp_id,$vol)", $mass);
        dcgoto("{$__routedurlpage__}");
/*
        getdbrow("STUDSEMACAD_ITM($pp_id)", $row);
        $pnn = $row['PERSNAME_NAME'];
        $vol = $row['VOLUME'];
*/
      }
      $MAIN .= "Дисциплина";
      $ndis; 
      if($cef)
        $MENU .= "<a href='docum.php?type=6&pp_id=$pp_id'>\"ГЭК\"</a><br>";
      else
        $MENU .= "<a href='docum.php?type=2&pp_id=$pp_id'>\"Лист\"</a><br>";
      if($row['SUBJSEL'] > 1){
        $MENU .= "<a href='student.php?change_pp=1&pp_id=$pp_id&mp_id={$row['MAINPROG_ID']}'>Выбор</a><br>";
        $MAIN .= " по выбору";
        $ndis = "<a href='student.php?change_pp=1&pp_id=$pp_id&mp_id={$row['MAINPROG_ID']}'>{$row['SUBJ_NAME']}</a> ";
        }
      else
        $ndis = $row['SUBJ_NAME'];
      $MAIN .= ": $ndis ({$row['SUBJ_ABBR']}) {$row['CONTROL_NAME']}<br>";

      getdbmass("STUDSEMACADITEM_LST($pp_id)", $mass);
      messall($mass);
      $MAIN .= "<br><table width='100%'>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "<td>Оценка</td>";
      $MAIN .= "<td>Тип док-та</td>";
      $MAIN .= "<td>Номер</td>";
      $MAIN .= "<td>Выдан</td>";
      $MAIN .= "<td>Введен</td>";
      $MAIN .= "</tr>";
      $n=0;
      while(getrow($mass, $row))
      {
        $n++;
        $dolg = false;
        if(!$row['RESULT_PASSFLAG'])
          $dolg = true;
        $rcolor = "id=col2";
        if($dolg)
          $rcolor = "id=col4";
        if($n%2){
          $rcolor = "id=col1";
          if($dolg)
            $rcolor = "id=col3";
        }
        $MAIN .= "<tr $rcolor>";
        $MAIN .= "<td>{$row['RESULT_NAME']}</td>";
        $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
        $MAIN .= "<td><a href='doc.php?ret=student.php&doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
        $MAIN .= "<td>{$row['DOCUMENT_OUTDATE']}</td>";
        $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
        $MAIN .= "</tr>";
        if(($n >= $MAXREC) && (!isset($_GET['allview'])))
          break;
      }
      $MAIN .= "</table>";
      formb();
      if($cn)
        pole('Тема','pnn',80);
      pole('Кол. часов','vol',10);
      forme();
      mainpaint();
    }

  //данные по семестрам
//    head('Данные академической успеваемости студента');

  //выбор текущего семестра
    setcursem();
    $curs = $_SESSION['cursem'] + 1;

    getdbrow("DSESS_ITM({$_SESSION['co_student']},$curs)",$row);
    $sess_id = $row['DSESSION_ID'];

//-----------проверить работу этого блока !!!
    getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
    $_SESSION['mpyear'] = $row['STREAM_FROMYEAR'];
//-----------конец блока

    getdbrow("DSESSION_ITM({$_SESSION['co_division']}, {$_SESSION['mpyear']}, $curs)", $row);
  
    b2d($row['DSESSION_BEGDATE']);
    b2d($row['DSESSION_ENDDATE']);
    if(!$row['DSESSION_BEGDATE'])
      $row['DSESSION_BEGDATE'] = 'не указано ';
    if(!$row['DSESSION_ENDDATE'])
      $row['DSESSION_ENDDATE'] = 'не указано ';
    $dstype = $uyear = '';
    if(isset($row['DSESSTYPE']))
      $dstype = $row['DSESSTYPE'];
    if(isset($row['UYEAR']))
      $uyear = $row['UYEAR'];
    $sess = "<b>$dstype сессия $uyear уч.года, начало:</b> {$row['DSESSION_BEGDATE']} <b>окончание:</b> {$row['DSESSION_ENDDATE']}<br>";
    if($sess_id){
      getdbrow("PROLONG_ITM($sess_id, {$_SESSION['co_student']})",$row);
      $ptype = $row['PROLTYPE_ID'] ?? "";
      $tdt = $row['PROLONG_TODATE'] ?? "";
    }
    b2d($tdt);

    getp('clear');
    getp('ptype');
    getp('tdt');
    getdt('gtdt_x','tdt',1);

    if($clear){
      getdbrow("PROLONG_CNG($sess_id, {$_SESSION['co_student']},NULL,NULL)",$row);
      $ptype = '';
      $tdt = '';
    }
    if($ok){
      $ptype1 = $ptype;
      $tdt1 = $tdt;
      i2b($ptype1);
      d2b($tdt1);
      getdbrow("PROLONG_CNG($sess_id, {$_SESSION['co_student']},$ptype1,$tdt1)",$row);
    }

    $MAIN .= "<form id=page1 method=post>";
    $MAIN .= "{$sess}<b>Продление:</b> ";
    pole('Причина','ptype',3,'PROLTYPE_LST()','PROLTYPE_NAME','PROLTYPE_ID',false);
    pole("Дата до:",'tdt',10,'','','',false,true,true," <input type=image $P_CAL name=gtdt>");
    $MAIN .= " <input type=submit name=ok value='Установить'>";
    $MAIN .= " <input type=submit name=clear value='Сброс'>";

    if(isset($_GET['sinhro'])){
      getdbmass("PERSPROGSYNC({$_SESSION['co_student']},$curs)", $mass);
    }
    $MENU .= "<a href='student.php?sinhro=1'>Синхро</a><br>";
    $MENU .= "<a href='karta.php?type=1&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='karta.php?type=1'>\"Карта1\"</a><br>";
    $MENU .= "<a href='karta.php?type=2&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='karta.php?type=2'>\"Карта2\"</a><br>";
    $MENU .= "<a href='karta.php?type=3&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='karta.php?type=3'>\"Карта3\"</a><br>";
    $MENU .= "<a href='karta.php?type=4&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='karta.php?type=4'>\"Карта4\"</a><br>";
    $MENU .= "<a href='karta.php?type=5&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='karta.php?type=5'>\"Карта5\"</a><br>";
    $MENU .= "<a href='docum.php?sid={$_SESSION['co_student']}&type=11&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='docum.php?sid={$_SESSION['co_student']}&type=11'>\"Копия_АС\"</a><br>";
    $MENU .= "<a href='vipiska.php?excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='vipiska.php'>\"Выписка\"</a><br>";

    $resm = array('Результаты:','последние','все');
    $m1 = menu('resm');
    $usp = array('Успеваемость:','текущая','основная');
    $MAIN .= menu('usp', $m1);
    if($_SESSION['usp'])
      $usp = 'FALSE';
    else
      $usp = 'TRUE';
    if($_SESSION['resm'])
      $resm1 = 'TRUE';
    else
      $resm1 = 'FALSE';

    getdbmass("STUDSEMACAD_LST({$_SESSION['co_student']},$curs,$resm1,$usp)", $mass);
    messall($mass);
    $MAIN .= "<table width='100%'>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>№</td>";
    $MAIN .= "<td>Название дисциплины</td>";
    $MAIN .= "<td>Аббр.</td>";
    $MAIN .= "<td>Выбор</td>";
    $MAIN .= "<td>Контроль</td>";
    $MAIN .= "<td>Часов</td>";
    $MAIN .= "<td>Оценка</td>";
    $MAIN .= "<td>Тип</td>";
    $MAIN .= "<td>№ док.</td>";
    $MAIN .= "<td>Дата</td>";
    $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
    $MAIN .= "</tr>";
    $n = $nn = $pid = 0;
    while(getrow($mass, $row))
    {
      $n++;
      $dolg = false;
      if(!$row['RESULT_PASSFLAG'])
        $dolg = true;
      $rcolor = "id=col2";
      if($dolg)
        $rcolor = "id=col4";
      if($n%2){
        $rcolor = "id=col1";
        if($dolg)
          $rcolor = "id=col3";
      }
      $ss = $nname = $subj = $contr = $sabbr = '';

      if($pid != $row['PERSPROG_ID']){
        $pid = $row['PERSPROG_ID'];
        $nn++;
        $subj = "<a href='{$__routedurlpage__}?pp_id=$pid'>{$row['SUBJ_NAME']}</a>";
        $nname = $nn;
        if($row['SUBJSEL'] > 1)
          $ss = "<a href='{$__routedurlpage__}?change_pp=1&pp_id=$pid&mp_id={$row['MAINPROG_ID']}&ret=1'><img $P_GRP alt='по выбору'></a>";
        $contr = $row['CONTROL_ABBR'];
        $sabbr = $row['SUBJ_ABBR'];
      }
      $MAIN .= "<tr $rcolor>";
      $tdcol = '';
      if($row['LEFTMPROG'])
        $MAIN .= "<td id=col7><a href='{$__routedurlpage__}?ppid_man={$row['PERSPROG_ID']}'>$nname</a></td>";
      else
        $MAIN .= "<td>$nname</td>";
      $MAIN .= "<td>$subj</td>";
      $MAIN .= "<td>$sabbr</td>";
      $del = '';
      if(!$row['RESULT_ABBR'])
        $del = "<a href='{$__routedurlpage__}?ppid_del={$row['PERSPROG_ID']}'><img $P_DEL alt='Удалить'></a>";
      $MAIN .= "<td id=c>$ss</td>";
      $MAIN .= "<td>$contr</td>";
      $MAIN .= "<td>{$row['VOLUME']}</td>";
      $MAIN .= "<td>{$row['RESULT_ABBR']}</td>";
      $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
      $MAIN .= "<td><a href='doc.php?ret=student.php&doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
      $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
      $MAIN .= "<td>$del</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }
    $MAIN .= "</table>";
    $MAIN .= "</form>";
    break;
  case 3: //контингент
    
//удаление студента
    fdel('delst','STUDENT_DEL',"<div id=redtext>ВНИМАНИЕ !!!<br>Студент будет удален без возможности восстановления !!!</div>",'','',1,1,0);
    getp('delst');
    getp('okd');
    if($delst && $okd){
      unset($_SESSION['co_student']);
      $MESS = 'Студент удален.';
      dcgoto('sgroup.php');
    }

//староста
    if(isset($_GET['star'])){
      getdbrow("SGROUPBOSS_CNG({$_SESSION['co_sgroup']},{$_SESSION['co_student']})",$row);
      $MESS = 'Староста назначен';
    }

//отчислить
    if(isset($_GET['otchisl'])){
      $MAIN = '';
      if(isset($_SESSION['otch_st']))
        $stat_id = $_SESSION['otch_st'];
      if(isset($_SESSION['otch_dt']))
        $fp = $_SESSION['otch_dt'];
      getp('newdoc');
      getp('doc_name');
      getp('doc_desc');
      getp('doc_id');
      getp('stat_id');
      getp('fp');
      getdt('gfp_x','fp');

      if($newdoc){
        head('Создание проекта приказа по личному составу');
        newdoc('&otchisl=1');
      }
      if(!$doc_id){
        head('Выбор проекта приказа по личному составу');
        getdoc('&otchisl=1');
      }
      head('Отчисление студента');
      if($cancel)
        dcgoto("{$__routedurlpage__}");
      if($ok){
        $_SESSION['otch_st'] = $stat_id;
        $_SESSION['otch_dt'] = $fp;
        i2b($doc_id);
        i2b($stat_id);
        d2b($fp);
        getdbrow("STUDOTCH({$_SESSION['co_student']}, $doc_id, $stat_id, $fp)", $row);
        if($row['RES'] == 1){
//          $_SESSION['sgrm1'] = 1;  //неактивные студенты
          $mess = urlencode('Студент включен в проект приказа по Л/С.');
          dcgoto("{$__routedurlpage__}?mess=$mess");
        }
        else{
          $mess = urlencode('Ошибка! Студент не включен в проект приказа по Л/С.');
          dcgoto("{$__routedurlpage__}?ermess=$mess");
        }
      }
      else{
        $MAIN .= "<table><form method=post>";
        $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
        pole('Причина','stat_id',20,'STUDSTATUS_LST(0)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
        pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
        $MAIN .= "<tr><td align=right><input type=submit name=ok value='Принять'> </td>";
        $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
        $MAIN .= "</tr></form></table>";
        mainpaint();
      }
    }
/*

//в приказ
    if(isset($_GET['vprik'])){
      $MAIN = '';
      if(isset($_SESSION['otch_st']))
        $stat_id = $_SESSION['otch_st'];
      if(isset($_SESSION['otch_dt']))
        $fp = $_SESSION['otch_dt'];
      getp('newdoc');
      getp('doc_name');
      getp('doc_desc');
      getp('doc_id');
      getp('stat_id');
      getp('fp');
      getdt('gfp_x','fp');

      if($newdoc){
        head('Создание проекта приказа по личному составу');
        newdoc('&vprik=1');
      }
      if(!$doc_id){
        head('Выбор проекта приказа по личному составу');
        getdoc('&vprik=1');
      }
      head('Отчисление студента');
      if($cancel)
        dcgoto("{$__routedurlpage__}");
      if($ok){
        $_SESSION['otch_st'] = $stat_id;
        $_SESSION['otch_dt'] = $fp;
        i2b($doc_id);
        i2b($stat_id);
        d2b($fp);
        getdbrow("STUDDOC_ADD({$_SESSION['co_student']}, $doc_id, $stat_id, $fp)", $row);
        if($row['RES'] == 1){
//          $_SESSION['sgrm1'] = 1;  //неактивные студенты
          $mess = urlencode('Студент включен в проект приказа по Л/С.');
          dcgoto("{$__routedurlpage__}?mess=$mess");
        }
        else{
          $mess = urlencode('Ошибка! Студент не включен в проект приказа по Л/С.');
          dcgoto("{$__routedurlpage__}?ermess=$mess");
        }
      }
      else{
        $MAIN .= "<table><form method=post>";
        $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
        pole('Причина','stat_id',20,'STUDSTATUS_LST(0)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
        pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
        $MAIN .= "<tr><td align=right><input type=submit name=ok value='Принять'> </td>";
        $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
        $MAIN .= "</tr></form></table>";
        mainpaint();
      }
    }
*/

//восстановить
    if(isset($_GET['vost'])){
      $MAIN = '';
      if(isset($_SESSION['zach_st']))
        $stat_id = $_SESSION['zach_st'];
      if(isset($_SESSION['zach_dt']))
        $fp = $_SESSION['zach_dt'];
      getp('newdoc');
      getp('doc_name');
      getp('doc_desc');
      getp('doc_id');
      getp('sgr_id');
      getp('stat_id');
      getp('fp');
      getdt('gfp_x','fp');
      if($newdoc){
        head('Создание проекта приказа по личному составу');
        newdoc('&vost=1');
      }
      if(!$doc_id){
        head('Выбор проекта приказа по личному составу');
        getdoc('&vost=1');
      }
      if(!$sgr_id){
        head('Выбор группы восстановления:');
        getdbmass("DIVISION_LST({$_SESSION['co_facultet']})", $mass);
        while(getrow($mass,$row)){
          $MAIN .= "<b>{$row['DIVISION_NAME']}</b><br>";
          getdbmass("SGROUP_LST({$row['DIVISION_ID']},TRUE)", $mass1);
          $MAIN .= "<table width=100%>";
          $n=0;
          $r=0;
          $mcol=3;
          $width = floor(100 / $mcol);
          while(getrow($mass1,$row1)){
            $n++;
            if(!(($n-1)%$mcol)){
              $r++;
              $MAIN .= '<tr>';
            }
            $rcolor = "id=col2";
            if($r%2)
              $rcolor = "id=col1";
            $MAIN .= "<td width=1% $rcolor>$n</td>";
            $MAIN .= "<td $rcolor width=$width%><a href='{$__routedurlpage__}?vost=1&doc_id=$doc_id&sgr_id={$row1['SGROUP_ID']}'>{$row1['SGROUP_AUTONAME']} ({$row1['SGROUP_PERIOD']})</a></td>";
            if(!($n%$mcol))
              $MAIN .= '</tr>';
          }
          while($n%$mcol){
            $MAIN .= "<td width=1% $rcolor></td>";
            $MAIN .= "<td width=$width% $rcolor></td>";
            $n++;
          }
          $MAIN .= '</table>';
        }
        mainpaint();
      }
      head('Восстановление студента');
      if($cancel)
        dcgoto("{$__routedurlpage__}");
      if($ok){
        $_SESSION['zach_st'] = $stat_id;
        $_SESSION['zach_dt'] = $fp;
        i2b($doc_id);
        i2b($stat_id);
        d2b($fp);
        getdbrow("STUDVOSST({$_SESSION['co_student']}, $sgr_id, $doc_id, $stat_id, $fp)", $row);
        if($row['RES'] == 1){
//          $_SESSION['sgrm1'] = 0;  //активные студенты
          $_SESSION['co_sgroup'] = $sgr_id;
          $mess = urlencode('Студент включен в проект приказа по Л/С.');
          dcgoto("{$__routedurlpage__}?mess=$mess");
        }
        else{
          $mess = urlencode('Ошибка! Студент НЕ включен в проект приказа по Л/С.');
          dcgoto("{$__routedurlpage__}?ermess=$mess");
        }
      }
      else{
        $MAIN .= "<table><form method=post>";
        $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
        $MAIN .= "<input type=hidden name=sgr_id value=$sgr_id>";
        pole('Причина','stat_id',20,'STUDSTATUS_LST(1)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
        pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
        $MAIN .= "<tr><td align=right><input type=submit name=ok value='Принять'> </td>";
        $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
        $MAIN .= "</tr></form></table>";
        mainpaint();
      }
    }


//перевод
    if(isset($_GET['perevod'])){
      $MAIN = '';
      head('Перевод студента в другую группу того же потока.');
      getp('sgr_id');
      if(!$sgr_id){
        head('Выбор группы для перевода:');
        getdbmass("STUDGROUP_LST({$_SESSION['co_student']})", $mass);
        $n=0;
        $r=0;
        $mcol=3;
        $width = floor(100 / $mcol);
        $MAIN .= "<table width=100%>";
        while(getrow($mass,$row)){
          $n++;
          if(!(($n-1)%$mcol)){
            $r++;
            $MAIN .= '<tr>';
          }
          $rcolor = "id=col2";
          if($r%2)
            $rcolor = "id=col1";
          $MAIN .= "<td width=1% $rcolor>$n</td>";
          $MAIN .= "<td $rcolor width=$width%><a href='{$__routedurlpage__}?perevod=1&sgr_id={$row['SGROUP_ID']}'>{$row['SGROUPAUTONAME']} ({$row['SGROUP_PERIOD']})</a></td>";
          if(!($n%$mcol))
            $MAIN .= '</tr>';
        }
        while($n%$mcol){
          $MAIN .= "<td width=1% $rcolor></td>";
          $MAIN .= "<td width=$width% $rcolor></td>";
          $n++;
        }
        $MAIN .= '</table>';
        mainpaint();
      }
      i2b($sgr_id);
      getdbrow("STUDGROUP_CNG({$_SESSION['co_student']}, $sgr_id)", $row);
      if($row['RES'] == 1){
        $_SESSION['co_sgroup'] = $sgr_id;
        $mess = urlencode('Студент переведен.');
        dcgoto("{$__routedurlpage__}?mess=$mess");
      }
    }
    
    
    getdbmass("STUDCONT_LST({$_SESSION['co_student']})", $mass);
    messall($mass);
    $MAIN .= "<table width='100%'>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>№</td>";
    $MAIN .= "<td>Дата</td>";
    $MAIN .= "<td>Статус</td>";
    $MAIN .= "<td>Значение</td>";
    $MAIN .= "<td>Состояние</td>";
    $MAIN .= "<td>Документ</td>";
    $MAIN .= "<td>Номер</td>";
    $MAIN .= "<td>Дата</td>";
    $MAIN .= "</tr>";

    $n = 0;
    while(getrow($mass, $row))
    {
      $n++;
      $ssa = false;
      if($row['STUDSTATUS_ACTIVE'])
        $ssa = true;

      $rcolor = "id=col2";
      if(!$ssa)
        $rcolor = "id=col4";
      if($n%2){
        $rcolor = "id=col1";
        if(!$ssa)
          $rcolor = "id=col3";
      }
      $MAIN .= "<tr $rcolor>";
      $MAIN .= "<td>$n</td>";
      b2d($row['CONTINGENT_DATE']);
      $MAIN .= "<td>{$row['CONTINGENT_DATE']}</td>";
      $MAIN .= "<td>{$row['STUDSTATUS_NAME']}</td>";
      $MAIN .= "<td>{$row['STUDSTATUS_VALUE']}</td>";
      $MAIN .= "<td>{$row['DOCUMENT_STATUS']}</td>";
      $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
      $MAIN .= "<td><a href='doc.php?doc_id={$row['DOCUMENT_ID']}&ret=student.php'>{$row['DOCUMENT_NO']}</a></td>";
      b2d($row['DOCUMENT_INDATE']);
      $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }
    $MAIN .= "</table>";
    $MENU .= "<a href='{$__routedurlpage__}?star=1'>Староста</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?perevod=1'>Группа</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?vost=1'>Восстановить</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?otchisl=1'>Отчислить</a><br>";
    $MENU .= "<hr><a href='{$__routedurlpage__}?delst={$_SESSION['co_student']}'>Удалить!</a><br>";
/*
    if($studstat){
      $MENU .= "<a href='{$__routedurlpage__}?star=1'>Староста</a><br>";
      $MENU .= "<a href='{$__routedurlpage__}?otchisl=1'>Отчислить</a><br>";
      $MENU .= "<a href='{$__routedurlpage__}?perevod=1'>Группа</a><br>";
    }
    else
      $MENU .= "<a href='{$__routedurlpage__}?vost=1'>Восстановить</a><br>";
      $MENU .= "<a href='{$__routedurlpage__}?vprik=1'>В приказ</a><br>";
      $MENU .= "<a href='{$__routedurlpage__}?delst={$_SESSION['co_student']}'>Удалить</a><br>";
*/
    break;
  case 4: //документы
    getdbmass("DOCSTUD_LST({$_SESSION['co_student']})", $mass);
    messall($mass);
    $MAIN .= "<table width='100%'>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>п/п</td>";
    $MAIN .= "<td>Документ</td>";
    $MAIN .= "<td>Состояние</td>";
    $MAIN .= "<td>Номер</td>";
    $MAIN .= "<td>Дата</td>";
    $MAIN .= "<td>Примечание</td>";
    $MAIN .= "</tr>";
    $n = 0;
    while(getrow($mass, $row))
    {
      $n++;
      if($n%2)
        $rcolor = "id=col1";
      else
        $rcolor = "id=col2";
      $MAIN .= "<tr $rcolor>";
      $MAIN .= "<td>$n</td>";
      b2d($row['CONTINGENT_DATE']);
      $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
      $MAIN .= "<td>{$row['DOCUMENT_STATUS']}</td>";
      $MAIN .= "<td><a href='doc.php?doc_id={$row['DOCUMENT_ID']}&ret=student.php'>{$row['DOCUMENT_NO']}</a></td>";
      b2d($row['DOCUMENT_INDATE']);
      $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
      $MAIN .= "<td>{$row['DOCUMENT_DESC']}</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }
    $MAIN .= "</table>";
    break;

  case 5: //листы
    head("Незавершенные индивидуальные академические документы:");
    getdbmass("ADOCSTUD_LST({$_SESSION['co_student']})", $mass);
    messall($mass);
    $MAIN .= "<table width='100%'>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>п/п</td>";
    $MAIN .= "<td>Тип</td>";
    $MAIN .= "<td>Номер</td>";
    $MAIN .= "<td>Дата</td>";
    $MAIN .= "<td>Семестр</td>";
    $MAIN .= "<td>Дисциплина</td>";
    $MAIN .= "<td>Контроль</td>";
    $MAIN .= "<td>Часов</td>";
    $MAIN .= "</tr>";
    $n = 0;
    while(getrow($mass, $row))
    {
      $n++;
      if($n%2)
        $rcolor = "id=col3";
      else
        $rcolor = "id=col4";
      $MAIN .= "<tr $rcolor>";
      $MAIN .= "<td>$n</td>";
      $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
      $MAIN .= "<td><a href='doc.php?doc_id={$row['DOCUMENT_ID']}&ret=student.php'>{$row['DOCUMENT_NO']}</a></td>";
//      b2d($row['DOCUMENT_OUTDATE']);
      $MAIN .= "<td>{$row['DOCUMENT_OUTDATE']}</td>";
      $row['SEMESTR'] = a2r($row['SEMESTR']);
      $MAIN .= "<td>{$row['SEMESTR']}</td>";
      $MAIN .= "<td>{$row['SUBJ_NAME']}</td>";
      $MAIN .= "<td>{$row['CONTROL_NAME']}</td>";
      $MAIN .= "<td>{$row['VOLUME']}</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }
    $MAIN .= "</table>";
    break;
  }
mainpaint();
?>