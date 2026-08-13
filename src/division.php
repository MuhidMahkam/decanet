<?php
if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"prog.xls\";");

include "global.php";

unset($_SESSION['ref_doc_id']);
getp('sgid_del');
if($sgid_del){
  getdbrow("SGROUP_DEL($sgid_del)",$row);
  if($row['RES'] == 1){
    if(isset($_SESSION['co_sgroup']) && ($sgid_del == $_SESSION['co_sgroup']))
      unset($_SESSION['co_sgroup']);
    $mess = urlencode('Группа удалена.');
    dcgoto("{$__routedurlpage__}?mess=$mess");
  }
}

$divm = array('Отделение:','состав', 'программа');
$div1m = array('Группы:','активные', 'выпущенные', 'все');

//удаление в базовой программе
fdel('mpid_del','MAINPROG_DEL','Удалить пункт из программы?');


if(!isset($_GET['otch']) && !isset($_GET['rep']))
  $MAIN .= menu('divm');
switch($_SESSION['divm']){
  case 0: //состав
    getp('vipusk');
    getp('nextkurs');
    getp('dived');
    getp('excel');
    if($vipusk){ //выпуск на отделении
      $MAIN = '';
      getp('newdoc');
      getp('doc_name');
      getp('doc_desc');
      getp('doc_id');
      getp('fp');
      getdt('gfp_x','fp');

      if($newdoc){
        head('Ввод нового приказа по л/с для отчисления выпускников');
        newdoc('&vipusk=1');
      }
      if(!$doc_id){
        head('Выбор приказа по л/с для отчисления выпускников');
        getdoc('&vipusk=1');
      }
      if($cancel)
        dcgoto("{$__routedurlpage__}");
      if($ok){
        i2b($doc_id);
        d2b($fp);
        getdbrow("VIPUSK({$_SESSION['co_division']}, $doc_id, $fp)", $row);
        if($row['RES'] == 1){
          $mess = urlencode('Группы выпущены.');
          dcgoto("{$__routedurlpage__}?mess=$mess");
        }
      }
      else{
        head('Введите дату выпуска');
        formb();
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
        pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
        forme();
        mainpaint();
      }
    }
    elseif($nextkurs){ //перевод
      $MAIN = '';
      head('Перевод на следующий курс');
      getp('newdoc');
      getp('doc_name');
      getp('doc_desc');
      getp('doc_id');
      getp('fp');
      getdt('gfp_x','fp');

      if($newdoc){
        head('Ввод нового приказа по л/с для перевода на следующий курс');
        newdoc('&nextkurs=1');
      }
      if(!$doc_id){
        head('Выбор приказа по л/с для перевода на следующий курс');
        getdoc('&nextkurs=1');
      }
      if($cancel)
        dcgoto("{$__routedurlpage__}");
      if($ok){
        i2b($doc_id);
        d2b($fp);
        getdbrow("NEXTKURS({$_SESSION['co_division']}, $doc_id, $fp)", $row);
        if($row['RES'] == 1){
          $mess = urlencode('Студенты включены в приказ по л/с.');
          dcgoto("{$__routedurlpage__}?mess=$mess");
        }
      }
      else{
        head('Введите дату перевода');
        formb();
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
        pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
        forme();
        mainpaint();
      }
    }
    elseif($add){ //добавление новой группы
      $MAIN = '';
      getp('idx');
      getp('fy');
      getp('gdesc');
      if(isset($_POST['cancel']))
        dcgoto($__routedurlpage__);
      if(isset($_POST['ok'])){
        s2b($idx);
        i2b($fy);
        s2b($gdesc);
        getdbrow("SGROUP_ADD({$_SESSION['co_division']},$idx,$fy,$gdesc)", $row);
        dcgoto($__routedurlpage__);
      }
      else{
        head("Добавление новой группы");
        formb();
        pole('Индекс','idx',10);
        pole('Год поступления','fy',10);
        pole('Примечание','gdesc',80);
        forme();
        mainpaint();
      }
    }
    elseif($dived){  // редактирование параметров отделения
      $MAIN = '';
      getp('agostid');
      // getp('asspecid');
      getp('aedutypeid');
      getp('adivabbr');
      getp('adivname');
      getp('a1mon');
      getp('a2mon');
      getp('anmpfx');
      getp('anmalg');
      getp('adivdesc');

      if(isset($_POST['cancel']))
        dcgoto($__routedurlpage__);
      if(isset($_POST['ok'])){
        i2b($agostid);
        //i2b($asspecid);
        i2b($aedutypeid);
        s2b($adivabbr);
        s2b($adivname);
        i2b($a1mon);
        i2b($a2mon);
        s2b($anmpfx);
        i2b($anmalg);
        s2b($adivdesc);
        getdbrow("DIVISION_CNG({$_SESSION['co_division']},$agostid,$aedutypeid,NULL,$adivabbr,$adivname,$a1mon,$a2mon,$anmpfx,$anmalg,$adivdesc)", $row);
        $MESS = "Параметры отделения $adivabbr изменены";     
        dcgoto($__routedurlpage__);
      }
      else{

        head("Редактирование параметров отделения");

        //читаем даные из базы
        getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row);

        $agostid = $row['GOSTITLE_ID'];
        $asspec_id = $row['SUBSPEC_ID'];
        $aedutypeid = $row['EDUTYPE_ID'];
        $adivabbr = $row['DIVISION_ABBR'];
        $adivname = $row['DIVISION_NAME'];
        $a1mon = $row['DIVISION_UYEAR'];
        $a2mon = $row['DIVISION_HALFUYEAR'];
        $anmpfx = $row['DIVISION_NPREFIX'];
        $anmalg = $row['DIVISION_ALGNO'];
        $adivdesc = $row['DIVISION_DESC'];
        
        formb();
        pole('ГОС','agostid',80,"GOSTITLE_LST()",'GOSTITLE_CODENAME','GOSTITLE_ID');
    //    pole('Специализация','asspec_id',80,"SUBSPEC_LST(???)",'SUBSPEC_NAME','SUBSPEC_ID');
        pole('Форма обучения','aedutypeid',80,"EDUTYPE_LST()",'EDUTYPE_NAME','EDUTYPE_ID');
        pole('Аббревиатура','adivabbr',25);
        pole('Наименование','adivname',80);
        pole('Месяц начала первого полугодия','a1mon',2);
        pole('Месяц начала второго полугодия','a2mon',2);
        pole('Префикс имен групп','anmpfx',10);
        pole('Номер алгоритма именования групп','anmalg',2);
        pole('Примечание','adivdesc',120);
        forme();
        mainpaint();
        break;
      }
    }
    getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row);
    if($row['GOSTITLE_NAME'])
      $MAIN .= "Специальность: {$row['GOSTITLE_NAME']}<br>";
    if($row['SUBSPEC_NAME'])
      $MAIN .= "Специализация: {$row['SUBSPEC_NAME']}<br>";
    $MAIN .= menu('div1m');
    listobj(6); // список групп на отделении
    $MENU .= "<a href='{$__routedurlpage__}?add=1'><img $P_ADD alt='Добавить'> группу</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?vipusk=1'>Выпуск</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?nextkurs=1'>След. курс</a><br><br>";
    $MENU .= "<a href='{$__routedurlpage__}?dived=1'><img $P_EDIT alt='Изменить'> отделение</a><br>";
    break;
  case 1: //программа
    $tgr = getTFN($_SESSION['div1m']);
    if(!isset($_SESSION['mpcs']) || ($_SESSION['mpcs'] < 0))
      $_SESSION['mpcs'] = 0;
    $mpcs1 = $_SESSION['mpcs'] + 1;



    //удаление дисциплины из пункта базовой программы
    getp('mp_id');
    getp('sid');
    if(!isset($_POST['cancel']) && !isset($_POST['ok']))
      fdel('sid_del','MPROGITEM_DEL','Удалить дисциплину из пункта программы?');

    //оценки
    getp('rez');
    if($rez){
      getdbmass("MPROGITEM_LST($mp_id)", $mass);
      $nprog = '';
      while(getrow($mass, $row))
        $nprog .= $row['SUBJ_NAME'].' ';
      head("Оценки по пункту программы: $nprog:");
      getdbmass("MPROGACAD_LST($mp_id)", $mass);

      $MAIN .= "<table width=100%>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "<td>Группа</td>";
      $MAIN .= "<td>ФИО</td>";
      $MAIN .= "<td>Документ</td>";
      $MAIN .= "<td>№</td>";
      $MAIN .= "<td>Дата</td>";
      $MAIN .= "<td>Оценка</td>";
      $MAIN .= "</tr>";
      $n=0;
      while(getrow($mass, $row)){
        $n++;
        $rc = $n%2 + 1;
        $MAIN .= "<tr id=col{$rc}>";
        $MAIN .= "<td>{$row['SGROUP_AUTONAME']}</td>";
        $semtmp = $row['SEMESTR'] - 1;
        $MAIN .= "<td><a href='student.php?student_id={$row['STUDSGRP_ID']}&stm=2&cursem=$semtmp'>{$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}</a></td>";
        $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
        $MAIN .= "<td><a href='doc.php?doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
        b2d($row['DOCUMENT_INDATE']);
        $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
        $MAIN .= "<td>{$row['RESULT_ABBR']}</td>";
        $MAIN .= "</tr>";
      }
      $MAIN .= "</table>";
      mainpaint();
    }

    // изменение пункта программы отделения
    if($edit){
      if($mp_id){
        getdbrow("MPROGITEM_ITM($mp_id)", $row);
        $cid = $row['CONTROL_ID'];
        $vol = $row['VOLUME'];
        $hid = $row['MAINPROG_HIDFLAG'];
      }
      if($_SESSION['usp']){
        $usp = 'FALSE';
        $hid = 0;
      }
      else{
        $usp = 'TRUE';
        $hid = 1;
      }


      getp('cid');
      getp('vol');
      getp('hid');
      if($mp_id && $sid)
        getdbrow("MPROGITEM_ADD($mp_id,$sid)", $row);

      if(isset($_POST['ok'])){
        if(!isset($_POST['hid']))
          $hid = 0;
        i2b($vol);
        if($vol == 'NULL')
          $vol = 0;
        i2b($cid);
        if($mp_id)
          getdbrow("MAINPROG_CNG($mp_id,$cid,$vol,$hid)", $row);
        elseif($sid)
          getdbrow("MAINPROG_ADD({$_SESSION['co_division']},{$_SESSION['mpyear']},$mpcs1,$cid,$sid,$vol,$hid)",$row);
      }
      elseif(!isset($_POST['cancel'])){
        if($mp_id){
          $hdr = 'Корректировка';
          getdbmass("MPROGITEM_LST($mp_id)", $mass);
          $colp = $mass->num_rows;
        }
        else{
          $hdr = 'Добавление';
          getdbmass("SUBJ_ITM($sid)", $mass);
        }
        //$MAIN ='';
        head("$hdr пункта основной программы");
        $MAIN .= "<table width=100%>";
        $MAIN .= "<tr id=head>";
        $MAIN .= "<td>Наименование</td>";
        $MAIN .= "<td>Аббревиатура</td>";
        if($mp_id)
          $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
        $MAIN .= "</tr>";
        $n=0;
        while(getrow($mass, $row)){
          $n++;
          $rcolor = "id=col2";
          if($n%2)
            $rcolor = "id=col1";
          $MAIN .= "<tr $rcolor>";
          $MAIN .= "<td>{$row['SUBJ_NAME']}</td><td>{$row['SUBJ_ABBR']}</td>";
          if($mp_id)
            if($colp > 1)
              $MAIN .= "<td align=center><a href='{$__routedurlpage__}?sid_del={$row['MPROGSUBJ_ID']}&mp_id=$mp_id&edit=1'><img $P_DEL alt='Удалить'></a></td>";
            else
              $MAIN .= "<td></td>";
          $MAIN .= "</tr>";
        }
        $MAIN .= "</table><br>";
        formb();

        pole('Вид контроля','cid',10,"CONTROL_LST($usp)",'CONTROL_NAME','CONTROL_ID',true,false);
        pole('Кол-во часов','vol',10);
        pole('Скрыть','hid',1);
        forme();
        if($mp_id){
          $MENU .= "<a href='{$__routedurlpage__}?add=1&mp_id=$mp_id'><img $P_ADD alt='Добавить'> выбор</a><br>";
          $MENU .= "<a href='{$__routedurlpage__}?rez=1&mp_id=$mp_id'>Оценки</a><br>";
          $MENU .= "<a href='docum.php?type=8&mp_id=$mp_id'>\"Должники\"</a><br>";
        }
        mainpaint();
      }
    }

    //стандарт
    getp('std');
    getp('gid');
    getp('del_gsbj');
    getp('gsbj');
    if($std){
      //отчет по стандарту
      if(isset($_GET['rep'])){
        sst("{$__routedurlpage__}?std=1");
        $numc = 3;
        $MAIN .= "<table id=t_mprog>";
        $MAIN .= "<tr><td id=width2></td><td id=width13></td><td id=width2></td></tr>";
        $MAIN .= "<tr><td id=med colspan=$numc>Государственный образовательный стандарт</td></tr>";
        getdbrow("DIVGOS_ITM({$_SESSION['co_division']})",$row);
        $MAIN .= "<tr><td id=med colspan=$numc>{$row['GOSTITLE_CODE']} {$row['GOSTITLE_NAME']}</td></tr>";
        getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})",$row1);
        getdbrow("DIVISION_ITM({$_SESSION['co_division']})",$row2);
        $MAIN .= "<tr><td id=med colspan=$numc>Факультет: {$row1['FACULTET_NAME']} Отделение: {$row2['DIVISION_NAME']}</td></tr>";

        $gos_cod=1;
        getdbmass("GOS_REP({$_SESSION['co_division']})", $mass);

        $MAIN .= "<tr id=head><td>Код</td><td>Наименование дисциплины</td><td>Аббр.</td></tr>";
        while(getrow($mass, $row)){
          if($gos_cod != $row['GOS_CODE']){
            $gos_cod = $row['GOS_CODE'];
            $MAIN .= "<tr><td id=podch colspan=$numc>{$row['GOSCOMP_CODE']} {$row['GOSCYCLE_CODE']} {$row['GOS_CODE']} {$row['GOS_NAME']} ({$row['GOS_VOL']})</td></tr>";
          }
          $MAIN .= "<tr>";
//          $MAIN .= "<td id=tleft>$num</td>";
          $MAIN .= "<td id=tleft>{$row['GSUBJ_CODE']}</td>";
          $MAIN .= "<td id=tleft>{$row['SUBJ_NAME']}</td>";
          $MAIN .= "<td id=tleft>{$row['SUBJ_ABBR']}</td>";
          $MAIN .= "</tr>";
        }
        $MAIN .= "</table>";
        sst("{$__routedurlpage__}?std=1");
        echo $MAIN;
        echo $DEBUG;
        exit;
      }



      if($gid){
        if($gsbj){
          getdbrow("GSUBJ_ITM($gsbj)",$row);
          $name1 = $row['SUBJ_NAME'];
          $abbr = $row['SUBJ_ABBR'];
          $cod = $row['GSUBJ_CODE'];
          if(isset($_POST['ok'])){
            getp('cod');
            s2b($cod);
            i2b($gsbj);
            getdbrow("GSUBJ_CNG($gsbj,$cod)", $row);
            dcgoto("{$__routedurlpage__}?std=$std&gid=$gid");
          }
          elseif(!isset($_POST['cancel'])){
            head('Изменение кода дисциплины');
            formb();
            pole('Название','name1',80,'','','',true,true,false);
            pole('Аббревиатура','abbr',10,'','','',true,true,false);
            pole('Код','cod',10);
            forme();
            mainpaint();
          }
        
        
        }
        fdel('del_gsbj','GSUBJ_DEL','Удалить дисциплину из цикла?');
        if($del_gsbj)
          dcgoto("{$__routedurlpage__}?std=$std&gid=$gid");
        if($sid){
          getdbrow("GSUBJ_ADD({$_SESSION['co_facultet']},$gid,$sid)",$row);
          dcgoto("{$__routedurlpage__}?std=$std&gid=$gid");
        }
///*
        //список дисциплин для добавления 
        if($add){
          fdel('subj_del','SUBJ_DEL','Удалить дисциплину из общего списка?');
          getp('subj_del');
          if($subj_del)
            dcgoto("{$__routedurlpage__}?std=$std&gid=$gid&add=1");


          getp('subj_add');
          getp('subj_edit');
          if($subj_add || $subj_edit){
            if($subj_edit){
              getdbrow("SUBJ_ITM($subj_edit)", $row);
              $name1 = $row['SUBJ_NAME'];
              $abbr = $row['SUBJ_ABBR'];
//              $code = $row['SUBJ_CODE'];
            }
            getp('name1');
            getp('abbr');
//            getp('code');
            if(isset($_POST['cancel']))
              dcgoto("{$__routedurlpage__}?std=$std&gid=$gid&add=1");
              
            if(isset($_POST['ok'])){
              s2b($name1);
              s2b($abbr);
              s2b($code);
              if($subj_edit){
                getdbrow("SUBJ_CNG($subj_edit,$name1,$abbr,$code)", $row);
                dcgoto("{$__routedurlpage__}?std=$std&gid=$gid&add=1");
              }
              elseif($subj_add){
                getdbrow("SUBJ_ADD($abbr,$name1,$code)",$row);
                dcgoto("{$__routedurlpage__}?std=$std&gid=$gid&add=1");
              }
            }
            else{
              if($subj_edit)
                $hdr = 'Корректировка';
              else
                $hdr = 'Добавление';
              $MAIN = '';
              head("$hdr дисциплины");
              formb();
              pole('Название','name1',80);
              pole('Аббревиатура','abbr',10);
//              pole('Код','code',10);
              forme();
              mainpaint();
            }
          }
          $mpid = '';
          if($mp_id)
            $mpid = "&mp_id=$mp_id";
          getp('fnd');
          $MAIN = '';
          $MAIN .= "<form name=vvod method=post>";
          $MAIN .= "<input type=hidden name=add value=1>";
          head("Выбор дисциплины для добавления");
          $MAIN .= "<b>Ввести шаблон: <input tabindex=1 type=text name=fnd value=$fnd>";
          $MAIN .= " <input type=submit value='Поиск'></b>";
          i2b($sid);
          $fndd ='';
          if($fnd){
            $fndc = urlencode($fnd);
            $fndd = "&fnd=$fndc";
            s2b($fnd);
            getdbmass("FND_SUBJ_LST($fnd)", $mass);
          }
          else
            getdbmass("SUBJ_LST()", $mass);
//            getdbmass("SUBJ_LST($sid)", $mass);
          messall($mass);
          $MAIN .= "<table width=100%>";
          $MAIN .= "<tr id=head>";
          $MAIN .= "<td>№</td>";
          $MAIN .= "<td>Наименование [Выбор]</td>";
          $MAIN .= "<td>Аббревиатура [Правка]</td>";
//          $MAIN .= "<td>Код</td>";
          $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
          $MAIN .= "</tr>";
          $n = $nn = 0;
          if(isset($_REQUEST['sid']))
            $MAIN .= "<td><a href='{$__routedurlpage__}?std=$std&gid=$gid&add=1$mpid$fndd'><img $P_UP alt=наверх></a></td>";

          while(getrow($mass, $row)){
            $n++;
            $rcolor = "id=col2";
            if($n%2)
              $rcolor = "id=col1";
            $MAIN .= "<tr $rcolor>";
//            if($fnd || $row['EFLAG']){
              $nn++;
              $MAIN .= "<td>$nn</td>";
              $MAIN .= "<td><a href='{$__routedurlpage__}?std=$std&gid=$gid&sid={$row['SUBJ_ID']}$mpid'>{$row['SUBJ_NAME']}</a></td>";
//            }
//            else{
//              $MAIN .= "<td></td>";
//              $name = strtoupper($row['NAME']);
//              $MAIN .= "<td><img $P_DIR alt=каталог> <a href='{$__routedurlpage__}?std=$std&gid=$gid&add=1&sid={$row['SUBREG_ID']}$mpid'><b>$name</b></a></td>";
//            }
            $MAIN .= "<td><a href='{$__routedurlpage__}?std=$std&gid=$gid&add=1$mpid$fndd&subj_edit={$row['SUBJ_ID']}'>{$row['SUBJ_ABBR']}</a></td>";
//            $MAIN .= "<td>{$row['CODE']}</td>";
    //        if($_SESSION['du_type'] == 'Администратор'){
            if(!$row['NOTDEL'])
              $MAIN .= "<td><a href='{$__routedurlpage__}?std=$std&gid=$gid&add=1$mpid$fndd&subj_del={$row['SUBJ_ID']}'><img $P_DEL alt='Удалить'></a></td>";
            else
              $MAIN .= "<td></td>";
    //        }

            $MAIN .= '</tr>';
            if(($n >= $MAXREC) && (!isset($_GET['allview'])))
              break;
          }
          $MAIN .= "</table>";
          $MAIN .= "</form>";
          $MENU .= "<a href='{$__routedurlpage__}?std=$std&gid=$gid&add=1$mpid$fndd&subj_add=1'>Новая дисц.</a><br>";
          mainpaint();
        
        }
//*/
        getdbrow("DIVGOS_ITM({$_SESSION['co_division']})",$row);
        head("<a href='{$__routedurlpage__}?std=$std'>{$row['GOSTITLE_CODE']} {$row['GOSTITLE_NAME']}</a><br>");
        getdbrow("GOS_ITM($gid)",$row);
        head("Цикл: {$row['GOS_NAME']} Объем, час: {$row['GOS_VOL']}");
        getdbmass("GSUBJ_LST({$_SESSION['co_facultet']},$gid)", $mass);
        messall($mass);
        $MAIN .= "<table width=100%>";
        $MAIN .= "<tr id=head>";
        $MAIN .= "<td>№</td>";
        $MAIN .= "<td>Код</td>";
        $MAIN .= "<td>Дисциплина</td>";
        $MAIN .= "<td>Аббревиатура</td>";
        $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
        $MAIN .= "</tr>";
        $n = 0;
        while(getrow($mass, $row)){
          $n++;
          $rcolor = "id=col2";
          if($n%2)
            $rcolor = "id=col1";
          $MAIN .= "<tr $rcolor>";
          $MAIN .= "<td>$n</td>";
          $MAIN .= "<td><a href='{$__routedurlpage__}?std=1&gid=$gid&gsbj={$row['GSUBJ_ID']}'>{$row['GSUBJ_CODE']}</a></td>";
          $MAIN .= "<td>{$row['SUBJ_NAME']}</td>";
          $MAIN .= "<td>{$row['SUBJ_ABBR']}</td>";
          $MAIN .= "<td><a href='{$__routedurlpage__}?std=1&gid=$gid&del_gsbj={$row['GSUBJ_ID']}'><img $P_DEL alt='Удалить'></a></td>";
          $MAIN .= '</tr>';
          if(($n >= $MAXREC) && (!isset($_GET['allview'])))
            break;
        }
        $MAIN .= "</table>";
        $MENU .= "<a href='{$__routedurlpage__}?std=$std&gid=$gid&add=1'><img $P_ADD alt='Добавить'> дисциплину</a><br>";
        mainpaint();
      }
      getdbrow("DIVGOS_ITM({$_SESSION['co_division']})",$row);
      head("Государственный образовательный стандарт:<br>{$row['GOSTITLE_CODE']} {$row['GOSTITLE_NAME']}");
      getdbmass("GOS_LST({$row['GOSTITLE_ID']})", $mass);
      messall($mass);
      $MAIN .= "<table width=100%>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "<td>№</td>";
      $MAIN .= "<td>Компонент</td>";
      $MAIN .= "<td>Цикл</td>";
      $MAIN .= "<td>Наименование</td>";
      $MAIN .= "<td>Объем, час</td>";
      $MAIN .= "<td>Кол-во дисципл.</td>";
//      $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
      $MAIN .= "</tr>";
      $n = 0;
      while(getrow($mass, $row)){
        $n++;
        $rcolor = "id=col2";
        if($n%2)
          $rcolor = "id=col1";
        $MAIN .= "<tr $rcolor>";
        $MAIN .= "<td>$n</td>";
        $MAIN .= "<td>{$row['GOSCOMP_CODE']}</td>";
        $MAIN .= "<td><a href='{$__routedurlpage__}?std=1&gid={$row['GOS_ID']}'>{$row['GOS_CODE']}</a></td>";
        $MAIN .= "<td>{$row['GOS_NAME']}</td>";
        $MAIN .= "<td>{$row['GOS_VOL']}</td>";
        $MAIN .= "<td>{$row['GOS_CNT']}</td>";
//        $MAIN .= "<td><a href='{$__routedurlpage__}?std=1&del={$row['GOS_ID']}'><img $P_DEL alt='Удалить'></a></td>";
        $MAIN .= '</tr>';
        if(($n >= $MAXREC) && (!isset($_GET['allview'])))
          break;
      }
      $MAIN .= "</table>";
      $MENU .= "<a href='{$__routedurlpage__}?std=$std&rep=1&excel=1'><img $P_EXL alt='excel'></a>";
      $MENU .= "<a href='{$__routedurlpage__}?std=$std&rep=1'>\"Стандарт\"</a><br>";
      mainpaint();
    }

    
    //список дисциплин для добавления в базовую программу
    if(isset($_REQUEST['add'])){
      fdel('subj_del','SUBJ_DEL','Удалить дисциплину из общего списка?');
      getp('subj_del');
      if($subj_del)
        dcgoto("{$__routedurlpage__}?add=1");


      getp('subj_add');
      getp('subj_edit');
      if($subj_add || $subj_edit){
        if($subj_edit){
          getdbrow("SUBJ_ITM($subj_edit)", $row);
          $name1 = $row['SUBJ_NAME'];
          $abbr = $row['SUBJ_ABBR'];
          $desc = $row['SUBJ_DESC'];
        }
        getp('name1');
        getp('abbr');
        getp('desc');
        if(isset($_POST['cancel']))
          dcgoto("{$__routedurlpage__}?add=1");
          
        if(isset($_POST['ok'])){
          s2b($name1);
          s2b($abbr);
          s2b($desc);
          if($subj_edit){
            getdbrow("SUBJ_CNG($subj_edit,$name1,$abbr,$desc)", $row);
            dcgoto("{$__routedurlpage__}?add=1");
          }
          elseif($subj_add){
            getdbrow("SUBJ_ADD($abbr,$name1,$desc)",$row);
            dcgoto("{$__routedurlpage__}?add=1");
          }
        }
        else{
          if($subj_edit)
            $hdr = 'Корректировка';
          else
            $hdr = 'Добавление';
          $MAIN = '';
          head("$hdr дисциплины");
          formb();
          pole('Название','name1',80);
          pole('Аббревиатура','abbr',10);
          pole('Примечание','desc',80);
          forme();
          mainpaint();
        }
      }

      $mpid = '';
      if($mp_id)
        $mpid = "&mp_id=$mp_id";
      getp('fnd');
      $MAIN = '';
      $MAIN .= "<form name=vvod method=post>";
      $MAIN .= "<input type=hidden name=add value=1>";
      head("Выбор дисциплины для добавления");
      $MAIN .= "<b>Ввести шаблон: <input tabindex=1 type=text name=fnd value=$fnd>";
      $MAIN .= " <input type=submit value='Поиск'></b>";
      i2b($sid);
      $fndd ='';
      if($fnd){
        $fndc = urlencode($fnd);
        $fndd = "&fnd=$fndc";
//        s2b($fnd);
//        getdbmass("FND_GLOBSUBJ_LST($fnd)", $mass);
      }
      s2b($fnd);
    
      $msubj = array('Дисциплины:','ГОС', 'все');
      $MAIN .= menu('msubj','',HORIZONTAL,"$mpid&add=$add");
      switch($_SESSION['msubj']){
        case 0: //ГОС
          getdbmass("FND_GSUBJ_LST({$_SESSION['co_division']},$fnd)", $mass);
      break;
    case 1: //все
          getdbmass("FND_SUBJ_LST($fnd)", $mass);
      break;
    }
    
      messall($mass);
      $MAIN .= "<table width=100%>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "<td>№</td>";
    if($_SESSION['msubj'] == 0)
        $MAIN .= "<td>Код</td>";
      $MAIN .= "<td>Наименование [Выбор]</td>";
      $MAIN .= "<td>Аббревиатура [Правка]</td>";
      $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
      $MAIN .= "</tr>";
      $n = $nn = 0;
      if(isset($_REQUEST['sid']))
        $MAIN .= "<td><a href='{$__routedurlpage__}?add=1$mpid$fndd'><img $P_UP alt=наверх></a></td>";

      while(getrow($mass, $row)){
        $n++;
        $rcolor = "id=col2";
        if($n%2)
          $rcolor = "id=col1";
        $MAIN .= "<tr $rcolor>";
        if($fnd || $row['EFLAG']){
          $nn++;
          $MAIN .= "<td>$nn</td>";
          if($_SESSION['msubj'] == 0)
              $MAIN .= "<td>{$row['GSUBJ_CODE']}</td>";
          $MAIN .= "<td><a href='{$__routedurlpage__}?edit=1&sid={$row['SUBJ_ID']}$mpid'>{$row['SUBJ_NAME']}</a></td>";
        }
        else{
          $MAIN .= "<td></td>";
          if($_SESSION['msubj'] == 0)
              $MAIN .= "<td>{$row['GSUBJ_CODE']}</td>";
          $name = strtoupper($row['NAME']);
          $MAIN .= "<td><img $P_DIR alt=каталог> <a href='{$__routedurlpage__}?add=1&sid={$row['SUBREG_ID']}$mpid'><b>$name</b></a></td>";
        }
        $MAIN .= "<td><a href='{$__routedurlpage__}?add=1$mpid$fndd&subj_edit={$row['SUBJ_ID']}'>{$row['SUBJ_ABBR']}</a></td>";
        if($_SESSION['du_type'] == 'Администратор'){
          if(!$row['NOTDEL'])
            $MAIN .= "<td><a href='{$__routedurlpage__}?add=1$mpid$fndd&subj_del={$row['SUBJ_ID']}'><img $P_DEL alt='Удалить'></a></td>";
          else
            $MAIN .= "<td></td>";
        }

        $MAIN .= '</tr>';
        if(($n >= $MAXREC) && (!isset($_GET['allview'])))
          break;
      }
      $MAIN .= "</table>";
      $MAIN .= "</form>";
      $MENU .= "<a href='{$__routedurlpage__}?add=1$mpid$fndd&subj_add=1'><img $P_ADD alt='Добавить'> дисциплину</a><br>";
      mainpaint();
    }

    //удаление в базовой программе
//    fdel('mpid_del','MAINPROG_DEL','Удалить пункт из программы?');

    //отчет по программе
    if(isset($_GET['otch'])){
      sst($__routedurlpage__);
      $numc = 5;
      $MAIN .= "<table id=t_mprog>";
      $MAIN .= "<tr><td id=width1></td><td id=width10></td><td id=width2></td>
        <td id=width2></td><td id=width2></td></tr>";

      getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
      $MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
      getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);
      getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row1);
      $MAIN .= "<tr><td id=left colspan=$numc>факультет: {$row['FACULTET_NAME']}</td></tr>";
      $MAIN .= "<tr><td id=left colspan=$numc>отделение: {$row1['DIVISION_NAME']}</td></tr>";

      if($row1['GOSTITLE_NAME'])
        $MAIN .= "<tr><td id=left colspan=$numc>Специальность: {$row1['GOSTITLE_CODE']} {$row1['GOSTITLE_NAME']}</td></tr>";
      if($row1['SUBSPEC_NAME'])
        $MAIN .= "<tr><td id=left colspan=$numc>Специализация: {$row1['SUBSPEC_CODE']} {$row1['SUBSPEC_NAME']}</td></tr>";

      getdbmass("MPROGYEAR_LST({$_SESSION['co_division']}, $tgr)", $mass);
      while(getrow($mass,$row)){
        if($_SESSION['mpyear'] == $row['STREAM_FROMYEAR'])
          break;
      }
      $MAIN .= "<tr><td id=med colspan=$numc>Программа за {$_SESSION['mpyear']}-{$row['STREAM_TOYEAR']} гг.</td></tr>";
      $semestr = 0;
      $oldnum = 0;
      $n = 0;
      $mp_id = 0;
      getdbmass("REP_MPROG({$_SESSION['co_division']},{$_SESSION['mpyear']})", $mass);
      $MAIN .= "<tr id=head><td>№</td><td>Наименование дисциплины</td><td>Аббр.</td><td>Контроль</td><td>Часов</td></tr>";
      while(getrow($mass, $row)){
        if($semestr != $row['SEMESTR']){
          $semestr = $row['SEMESTR'];
          $MAIN .= "<tr><td id=podch colspan=$numc>Семестр: $semestr</td></tr>";
        }
        $num = $contr = $vol = '';
        if($mp_id != $row['MAINPROG_ID']){
          $mp_id = $row['MAINPROG_ID'];
          $n++;
          $num = $n;
          $contr = $row['CONTROL_ABBR'];
          $vol = $row['VOLUME'];
        }
        $MAIN .= "<tr>";
        $MAIN .= "<td id=tleft>$num</td>";
        $MAIN .= "<td id=tleft>{$row['SUBJ_NAME']}</td>";
        $MAIN .= "<td id=tleft>{$row['SUBJ_ABBR']}</td>";
        $MAIN .= "<td id=tleft>$contr</td>";
        $MAIN .= "<td id=tleft>$vol</td>";
        $MAIN .= "</tr>";

      }
      $MAIN .= "</table>";
      sst($__routedurlpage__);
      echo $MAIN;
//      echo $DEBUG;
      exit;
    }

    //отображение базовой программы

    //установка текущего года поступления для mainprog
    $tgr = getTFN($_SESSION['div1m']);

//    if(isset($_SESSION['co_sgroup'])){
//      getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
//      $_SESSION['mpyear'] = $row['STREAM_FROMYEAR'];
//    }
    if(isset($_POST['setcy']) && isset($_POST['mpyear']))
      $_SESSION['mpyear'] = $_POST['mpyear'];

    getdbmass("MPROGYEAR_LST({$_SESSION['co_division']}, $tgr)", $mass);
    $sfy = 0;
    $sty = 0;


    if(!$mass->num_rows){
      head('Не создано учебных групп. Работа с программой невозможна.');
      $MENU .= "<a href='{$__routedurlpage__}?std=1'>Стандарт</a><br>";
      mainpaint();
    }

    while(getrow($mass,$row))
      if(!$sfy || ($_SESSION['mpyear'] == $row['STREAM_FROMYEAR'])){
        $sfy = $row['STREAM_FROMYEAR'];
        $sty = $row['STREAM_TOYEAR'];
      }
    $_SESSION['mpyear'] = $sfy;

    $MAIN .= "<form id=page1 action='{$__routedurlpage__}' method=post>";
    $MAIN .= "<b>Поток: </b>$sfy-$sty уч.годы";
    $MAIN .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp';

    $MAIN .= " <input type=submit name=setcy value='Перейти в:'>";
    $MAIN .= "<select name=mpyear size=1>";
    getdbmass("MPROGYEAR_LST({$_SESSION['co_division']}, $tgr)", $mass);
    while(getrow($mass,$row)){
      $sel = '';
      if($_SESSION['mpyear'] == $row['STREAM_FROMYEAR'])
        $sel = "SELECTED";
      $MAIN .= "<option $sel value={$row['STREAM_FROMYEAR']}>{$row['STREAM_FROMYEAR']}-{$row['STREAM_TOYEAR']}";
    }
    $MAIN .= "</select>";
    $MAIN .= '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp';
    $MAIN .= " <input type=submit name=setmp value='Импорт из:'>";
    $MAIN .= "<select name=mpyeari size=1>";
    getdbmass("MPROGYEAR_LST({$_SESSION['co_division']}, $tgr)", $mass);
    while(getrow($mass,$row)){
      $sel = '';
      if(@$_SESSION['mpyeari'] == $row['STREAM_FROMYEAR'])
        $sel = "SELECTED";
      $MAIN .= "<option $sel value={$row['STREAM_FROMYEAR']}>{$row['STREAM_FROMYEAR']}-{$row['STREAM_TOYEAR']}";
    }
    $MAIN .= "</select>";
    $MAIN .= "</form>";


    //текущий семестр
    getdbrow("STREAMSEM_CNT({$_SESSION['co_division']}, {$_SESSION['mpyear']})", $row);
    $maxsem = $row['STREAM_SEMCOUNT'];

    //количество семестров
    $ns = "<form id=page1 method=post>";
    $ns .= "<b>Кол-во семестров: </b> ";
    $ns .= " <input type=text name=nsem size=3 value=$maxsem>";
    $ns .= " <input type=submit name=setnsem value='Установить'>";
    $ns .= "</form>";

    $mpcs = array();
    $mpcs[] = 'Семестр:';
    for($i=1; $i<=$maxsem; $i++)
      $mpcs[] = a2r($i);
    $MAIN .= menu('mpcs',$ns);
    if($_SESSION['mpcs'] > $maxsem - 1)
      $_SESSION['mpcs'] = $maxsem - 1;
    $mpcs1 = $_SESSION['mpcs'] + 1;


    getdbrow("DSESSION_ITM({$_SESSION['co_division']}, {$_SESSION['mpyear']}, $mpcs1)", $row);
    $dstype = $row['DSESSTYPE'] ?? "";
    $dyear = $row['UYEAR'] ?? "";
    $db = $row['DSESSION_BEGDATE'] ?? "";
    $de = $row['DSESSION_ENDDATE'] ?? "";
    $dsid = $row['DSESSION_ID'] ?? "";
    b2d($db);
    b2d($de);

    getp('dsid');
    getp('db');
    getp('de');
    getdt('dbf','db',1);
    getdt('def','de',1);

    //установить количество семестров
    if(isset($_POST['setnsem'])){
      getp('nsem');
      i2b($nsem);
      getdbrow("STREAM_CNG({$_SESSION['co_division']}, {$_SESSION['mpyear']},$nsem)", $row);
      dcgoto("{$__routedurlpage__}");
    }

    //установить начало/конец сессии
    if(isset($_POST['setsess'])){
      d2b($db);
      d2b($de);
      getdbrow("DSESSION_CNG($dsid,$db,$de)", $row);
      dcgoto("{$__routedurlpage__}");
    }

    if($dstype){
      $MAIN .= "<form id=page1 action='{$__routedurlpage__}' method=post>";
      $MAIN .= "<b>$dstype сессия $dyear уч.года, </b> ";
      $MAIN .= " <input type=submit name=dbf value='Начало'>";
      $MAIN .= " <input type=text size=7 name=db value=$db>";
      $MAIN .= " <input type=submit name=def value='Окончание'>";
      $MAIN .= " <input type=text size=7 name=de value=$de>";
      $MAIN .= " <input type=hidden name=dsid value=$dsid>";
      $MAIN .= " <input type=submit name=setsess value='Установить'>";
      $MAIN .= "</form>";
    }


    //импорт программы
    if(isset($_POST['setmp']) && isset($_POST['mpyeari'])){
      getdbmass("IMPORTMPROG({$_SESSION['co_division']}, $mpcs1,
        {$_POST['mpyeari']}, {$_SESSION['mpyear']})", $row);
      $_SESSION['mpyeari'] = $_POST['mpyeari'];
    }

    $usp = array('Успеваемость:','текущая','основная');
    $MAIN .= menu('usp');
    if($_SESSION['usp'])
      $usp = 'FALSE';
    else
      $usp = 'TRUE';


    getdbmass("MAINPROG_LST({$_SESSION['co_division']},{$_SESSION['mpyear']},$mpcs1,$usp)", $mass);
    messall($mass);
    $MAIN .= "<table width=100%>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>№</td>";
    $MAIN .= "<td>Наименование дисциплины</td>";
    $MAIN .= "<td>Аббр.</td>";
    $MAIN .= "<td>Контроль</td>";
    $MAIN .= "<td>Часов</td>";
    $MAIN .= "<td>Скрыть</td>";
    $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
    $MAIN .= "</tr>";

    $n = $nn = $mpid = 0;
    while(getrow($mass, $row)){
      $n++;
      $num = $contr = $vol = $hid = $del = '';
      $name = $row['SUBJ_NAME'];
      if($row['MAINPROG_ID'] != $mpid){
        $nn++;
        $num = $nn;
        $mpid = $row['MAINPROG_ID'];
        $name = "<a href='{$__routedurlpage__}?edit=1&mp_id=$mpid&vol={$row['VOLUME']}&hid={$row['MAINPROG_HIDFLAG']}'>".$name."</a>";
        $contr = $row['CONTROL_NAME'];
        $vol = $row['VOLUME'];
        $hid = $row['MAINPROG_HIDFLAG'];
        if($row['NOTDEL'] == 0)
          $del = "<a href='{$__routedurlpage__}?mpid_del={$row['MAINPROG_ID']}'><img $P_DEL alt='Удалить'></a>";
      }
      $rcolor = "id=col2";
      if($nn%2)
        $rcolor = "id=col1";
      $MAIN .= "<tr $rcolor>";
      $MAIN .= "<td>$num</td>";
      $MAIN .= "<td>$name</td>";
      $MAIN .= "<td>{$row['SUBJ_ABBR']}</td>";
      $MAIN .= "<td>$contr</td>";
      $MAIN .= "<td>$vol</td>";
      if($hid)
        $hid = 'Да';
      else  
        $hid = '';
      $MAIN .= "<td>$hid</td>";
      $MAIN .= "<td align=center>$del</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }

    $MAIN .= "</table>";
    $MENU .= "<a href='{$__routedurlpage__}?add=1'><img $P_ADD alt='Добавить'> пункт</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?std=1'>Стандарт</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?otch=1&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='{$__routedurlpage__}?otch=1'>\"Программа\"</a><br>";


    break;
}
mainpaint();
?>