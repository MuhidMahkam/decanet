<?php
if(isset($_POST['excel']) && ($_POST['excel'] == 1) && isset($_POST['ok']))
  if(isset($_GET['cont']))
    header("Content-Disposition: attachment; filename=\"conting.xls\";");
  else
    header("Content-Disposition: attachment; filename=\"itogi.xls\";");

include "global.php";
getp('cont');
getp('itog');
getp('excel');
getp('divadd');

$fac1m = array('Отделения:','активные', 'выпущенные', 'все');


if($divadd){ //добавление нового отделения
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
    getdbrow("DIVISION_ADD({$_SESSION['co_facultet']},$agostid,$aedutypeid,NULL,$adivabbr,$adivname,$a1mon,$a2mon,$anmpfx,$anmalg,$adivdesc)", $row);
    $MESS = "Отделение $adivabbr добавлено";     
    dcgoto($__routedurlpage__);
  }
  else{
    head("Добавление нового отделения");
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
  }
}


if($cont){ //отчет контингент
  $MAIN = '';
  getp('fy');
  getdt('gfp_x','fy',2);

  if(isset($_POST['cancel']))
    dcgoto($__routedurlpage__);
  if(isset($_POST['ok'])){
    getp('fac_id');
    sst('facultet.php');
    $MAIN .= "<table id=tabotchet>";

    $numc = 5;
    $MAIN .= "<tr><td id=width8></td><td id=width1></td><td id=width1></td>";
    $MAIN .= "<td id=width1></td><td id=width1></td>";
    $MAIN .= "</tr>";

    getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
    $MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
    $MAIN .= "<tr><td id=big colspan=$numc>Сводка движения контингента студентов</td></tr>";
    getdbrow("FACULTET_ITM($fac_id)", $row);
    $MAIN .= "<tr><td id=left colspan=$numc>факультет: {$row['FACULTET_NAME']}</td></tr>";
    $MAIN .= "<tr><td id=left colspan=$numc>Период: $fy</td></tr>";

    $MAIN .= "<tr id=head>";
    $MAIN .= "</tr>";

    $MAIN .= "<tr id=head>";
    $MAIN .= "<td id=tcenter rowspan=2>Статус</td>";
    $MAIN .= "<td id=tcenter rowspan=2>общее кол-во</td>";
    $MAIN .= "<td id=tcenter colspan=3>В том числе</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td id=tcenter>муж.</td>";
    $MAIN .= "<td id=tcenter>женщ.</td>";
    $MAIN .= "<td id=tcenter>контр.</td>";
    $MAIN .= "</tr>";


    d2b($fy);
    getdbmass("REP_CONTINGENT($fy,$fac_id)", $mass);
    $n=0;
    $div = $kurs = '';
    while(getrow($mass, $row)){
      $n++;
      if($div != $row['DIVISION_NAME']){
        $div = $row['DIVISION_NAME'];
        $kurs = '';
        $MAIN .= "<tr><td id=podch colspan=$numc>отделение: $div</td></tr>";
      }
      if($kurs != $row['KURS']){
        $kurs = $row['KURS'];
        $MAIN .= "<tr><td colspan=$numc><b>курс $kurs</b></td></tr>";
      }
      $MAIN .= "<tr>";
      $MAIN .= "<td id=tleft>{$row['STATUSTYPE_NAME']}</td>";
      $MAIN .= "<td id=tright>{$row['MAINCNT']}</td>";
      $MAIN .= "<td id=tright>{$row['MANCNT']}</td>";
      $MAIN .= "<td id=tright>{$row['WOMANCNT']}</td>";
      $MAIN .= "<td id=tright>{$row['KONTRCNT']}</td>";
      $MAIN .= "</tr>";
    }
    $MAIN .= "</table>";

    $MAIN .= "<br><b>Приказы по личному составу:</b><table>";
    getdbmass("REP_CONTDOC_LST($fy,$fac_id)", $mass);
    $n=0;
    $div = $kurs = '';
    while(getrow($mass, $row)){
      $n++;
      $MAIN .= "<tr>";
      $MAIN .= "<td>$n.</td>";
      $MAIN .= "<td>Приказ № {$row['DOCUMENT_NO']}</td>";
      b2d($row['DOCUMENT_INDATE']);
      $MAIN .= "<td>от {$row['DOCUMENT_INDATE']}</td>";
      $MAIN .= "</tr>";
    }
    $MAIN .= "</table>";
    sst('facultet.php');
    echo $MAIN;
    echo $DEBUG;
    exit;
  }
  else{
    head("Сводка движения контингента студентов");
    formb();
    pole("Период",'fy',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
    $MAIN .= "<input type=hidden name=excel value=$excel>";
    $MAIN .= "<input type=hidden name=fac_id value={$_SESSION['co_facultet']}>";
    forme();
    mainpaint();
  }
}
elseif($itog){ //итоги
  $MAIN = '';

  if(isset($_POST['cancel']))
    dcgoto($__routedurlpage__);
  if(isset($_POST['ok'])){
    getp('fac_id');
    getp('stat');
    getp('year');
    sst('facultet.php');
    $MAIN .= "<table id=tabotchet>";

    $numc = 13;
    $MAIN .= "<tr>";
    $MAIN .= "<td id=width2></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "<td id=width1></td>";
    $MAIN .= "</tr>";

    getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
    $MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
    $MAIN .= "<tr><td id=big colspan=$numc>Итоги экзаменационной сессии</td></tr>";
    getdbrow("FACULTET_ITM($fac_id)", $row);
    $MAIN .= "<tr><td id=left colspan=$numc>факультет: {$row['FACULTET_NAME']}</td></tr>";
    $MAIN .= "<tr><td id=left colspan=$numc>Учебный год: $year</td></tr>";
    if($stat == 0)
      $sess = 'летняя';
    else
      $sess = 'зимняя';
    $MAIN .= "<tr><td id=left colspan=$numc>Сессия: $sess</td></tr>";

    $MAIN .= "<tr id=head>";
    $MAIN .= "</tr>";

    $MAIN .= "<tr id=head>";
    $MAIN .= "<td id=small>Группа</td>";
    $MAIN .= "<td id=small>Обязано сдавать</td>";
    $MAIN .= "<td id=small>В т.ч. контр.</td>";
    $MAIN .= "<td id=small>Сдавших на 5</td>";
    $MAIN .= "<td id=small>В т.ч. контр.</td>";
    $MAIN .= "<td id=small>Сдавших на 4 и 5</td>";
    $MAIN .= "<td id=small>В т.ч. контр.</td>";
    $MAIN .= "<td id=small>Сдавших на 3</td>";
    $MAIN .= "<td id=small>В т.ч. контр.</td>";
    $MAIN .= "<td id=small>Сдавших на 2</td>";
    $MAIN .= "<td id=small>В т.ч. контр.</td>";
    $MAIN .= "<td id=small>Имеющих долги</td>";
    $MAIN .= "<td id=small>В т.ч. контр.</td>";
    $MAIN .= "</tr>";


    getdbmass("REP_SESSITOG($fac_id,$year,$stat)", $mass);
    $n=0;
    $div = $kurs = '';
    while(getrow($mass, $row)){
      $n++;
      if($div != $row['DIVISION_NAME']){
        $div = $row['DIVISION_NAME'];
        $kurs = '';
        $MAIN .= "<tr><td id=podch colspan=$numc>отделение: $div</td></tr>";
      }
      $MAIN .= "<tr>";
      $MAIN .= "<td>{$row['SGNAME']}</td>";
      $MAIN .= "<td>{$row['ALLCNT']}</td>";
      $MAIN .= "<td>{$row['CONTRCNT']}</td>";
      $MAIN .= "<td>{$row['RES5']}</td>";
      $MAIN .= "<td>{$row['CRES5']}</td>";
      $MAIN .= "<td>{$row['RES4']}</td>";
      $MAIN .= "<td>{$row['CRES4']}</td>";
      $MAIN .= "<td>{$row['RES3']}</td>";
      $MAIN .= "<td>{$row['CRES3']}</td>";
      $MAIN .= "<td>{$row['RES2']}</td>";
      $MAIN .= "<td>{$row['CRES2']}</td>";
      $MAIN .= "<td>{$row['RESN']}</td>";
      $MAIN .= "<td>{$row['CRESN']}</td>";
      $MAIN .= "</tr>";
    }
    $MAIN .= "</table>";
    sst('facultet.php');
    echo $MAIN;
    echo $DEBUG;
    exit;
  }
  else{
    head("Итоги экзаменационной сессии:");
    formb();
    pole("Учебный год",'year',10);
    $MAIN .="<tr><td align=center colspan=2>";
    $MAIN .="<span id=col4>Зимняя</span> <input name=stat type=radio value=1 checked> ";
    $MAIN .="<span id=col4>Летняя</span><input name=stat type=radio value=0>";
    $MAIN .="</td></tr>";
    $MAIN .= "<input type=hidden name=excel value=$excel>";
    $MAIN .= "<input type=hidden name=fac_id value={$_SESSION['co_facultet']}>";
    forme();
    mainpaint();
  }
}

else{
  head('Отделения факультета');
  $MAIN .= menu('fac1m');
  listobj(5); // список отделений на факультете
}
$MENU .= "<a href='{$__routedurlpage__}?cont=1&excel=1'><img $P_EXL alt='excel'></a>";
$MENU .= "<a href='{$__routedurlpage__}?cont=1'>\"Контингент\"</a><br>";
$MENU .= "<a href='{$__routedurlpage__}?itog=1&excel=1'><img $P_EXL alt='excel'></a>";
$MENU .= "<a href='{$__routedurlpage__}?itog=1'>\"Итоги\"</a><br><br>";
$MENU .= "<a href='{$__routedurlpage__}?divadd=1'><img $P_ADD alt='Добавить'> отделение</a>";

mainpaint();
?>