<?php

include "global.php";

if($demouser){
  $ERMESS .= 'Доступ запрещен.';
  mainpaint();
}

getp('old_pass');
getp('new_pass');
getp('new_pass1');
getp('npass');
getp('spass');
getp('_2FA');
getp('_2FAdel');
getp('code2fa');


if($spass || $npass){
  $ed = '';
  if($edit)
    $ed = "?edit=$edit";
  if($cancel)
    //dcgoto($_SERVER['PHP_SELF'].$ed);
    dcgoto($__routedurlpage__.$ed);
  if($ok){
    if(checkpass()){
      if($npass)
        getdbrow("DUSERPASS_CNG($edit, '$new_pass')", $row);
      if($spass)
        getdbrow("SELFPASS_CNG('$old_pass','$new_pass')", $row);
      if($row['RES']){
        $MESS = "Пароль успешно изменен!";
        if(($_SESSION['du_id'] == $edit) || $spass){
          //$_SESSION['du_pass'] = @mcrypt_ecb(MCRYPT_3DES, 'key', $row['NEWPASS'], MCRYPT_ENCRYPT);
          $_SESSION['du_pass'] = dc_encrypt($row['NEWPASS']);

          unset($GDB);
        }
      }
      else
        $ERMESS = "Ошибка смены пароля!";
    }
    //dcgoto($_SERVER['PHP_SELF'].$ed);
    dcgoto($__routedurlpage__.$ed);
  }
  else{
    if($spass){
      getdbrow("DUSER_ITM({$_SESSION['du_id']})",$row);
      head("Изменение собственного пароля ({$row['DUNAME']})");
    }
    if($npass){
      getdbrow("DUSER_ITM($edit)",$row);
      head("Изменение пароля пользователя ({$row['DUNAME']})");
    }
    formb();
    if($spass)
      pole('Старый пароль','old_pass',20,'','','',true,true,true,'','',true);
    pole('Новый пароль','new_pass',20,'','','',true,true,true,'','',true);
    pole('Повтор нового пароля','new_pass1',20,'','','',true,true,true,'','',true);
    forme();
  }
  mainpaint();
}

if($_2FAdel){
  $ed = '';
  if($edit)
    $ed = "?edit=$edit";
  getdbrow("DUSER_ITM($edit)",$row);
  $dusername = $row['DUNAME'];

  if($cancel)
    dcgoto($__routedurlpage__.$ed);
  if($ok){
    getdbrow("DUSER_2FA_DEL($edit)", $row);
      if($row['RES']){
        $MESS = "Cекретный ключ двухфакторной аутентификации сброшен.";           
        dcgoto($__routedurlpage__.$ed);
      } else
      $ERMESS = "Ошибка сброса секретного ключа двухфакторной аутентификации!";           
  }
  getdbrow("DUSER_ITM($edit)",$row);
  $dusername = $row['DUNAME'];
  head("Сбросить секретный ключ двухфакторной аутентификации для пользователя $dusername?");

  formb();

  forme();
  mainpaint();
}

if($_2FA){
  $ed = '';
  $options2fa = set2FAoptions();
  getdbrow("DUSER_ITM($edit)",$row);
  $dusername = $row['DUNAME'];
  $sec2faex = $row['DUSER_2FA_EXISTS'];
  if ($sec2faex){
    $ERMESS = "ВНИМАНИЕ: Cекретный ключ двухфакторной аутентификации уже существует!";           
  }
  if($edit)
    $ed = "?edit=$edit";
  if($cancel)
    //dcgoto($_SERVER['PHP_SELF'].$ed);
    dcgoto($__routedurlpage__.$ed);
  if($ok){
    if (verify2FAcode($options2fa, $_SESSION['secret2fa'], $code2fa)) {
      getdbrow("DUSER2FASEC_CNG($edit, '{$_SESSION['secret2fa']}')", $row);
      if($row['RES']){
        unset($_SESSION['secret2fa']);
        $MESS = "Cекретный ключ двухфакторной аутентификации установлен.";           
        dcgoto($__routedurlpage__.$ed);
      } else
      $ERMESS = "Ошибка установки секретного ключа!";           
    } else 
      $ERMESS = "Одноразовый пароль не верен!";     
  }
  
  head("Установить секретный ключ двухфакторной аутентификации для пользователя $dusername?");
  head("Не показывайте ключ посторонним!");

  if(isset($_SESSION['secret2fa']))
    $secret2fa = $_SESSION['secret2fa'];  
  else {
    $secret2fa = gen2FAsecret($options2fa);
    $_SESSION['secret2fa'] = $secret2fa;
    $code2fa='';
  }

  $svg = make2FAsvg($options2fa, $secret2fa);
   
  formb();

  $MAIN .= '<div id="authenticator-qrcode">' . $svg . '</div>';
            
  pole('Отсканируйте QR-код или введите вручную:','secret2fa',50,'','','',true,true,$add);
  pole('Для проверки введите разовый код:','code2fa',10,'','','',true,true,true);

  forme();
  mainpaint();
}


if($add || $edit){
  $cn = @$_SESSION['co_country'];
  $rg = @$_SESSION['co_region'];
  $ct = @$_SESSION['co_city'];
  $sc = @$_SESSION['co_school'];
  $fc = @$_SESSION['co_facultet'];
  $dv = @$_SESSION['co_division'];
  $gr = @$_SESSION['co_sgroup'];
  $st = @$_SESSION['co_student'];

  if($cancel)
    //dcgoto($_SERVER['PHP_SELF']);
    dcgoto($__routedurlpage__);
  if($edit){
    getdbrow("DUSER_ITM($edit)",$row);
    $type=$row['MANAGERTYPE_ID'];
    $dn=$row['DUNAME'];
    $fn=$row['DUSER_FNAME'];
    $mn=$row['DUSER_MNAME'];
    $ln=$row['DUSER_LNAME'];
    $ds=$row['DESIGN_ID'];
//    $ag=$row['AGENT_ID'];
    $phn1=$row['DUSER_PHONE1'];
    $phn2=$row['DUSER_PHONE2'];
    $em=$row['DUSER_EMAIL'];
    $icq=$row['DUSER_ICQ'];
    $desc=$row['DUSER_DESC'];
    getp('dostup');
    if(!$dostup){
      $cn = $row['COUNTRY_ID'];
      $rg = $row['REGION_ID'];
      $ct = $row['CITY_ID'];
      $sc = $row['SCHOOL_ID'];
      $fc = $row['FACULTET_ID'];
      $dv = $row['DIVISION_ID'];
      $gr = $row['SGROUP_ID'];
      $st = $row['STUDENT_ID'];
    }
  }
  getp('type');
  getp('dn');
  getp('fn');
  getp('mn');
  getp('ln');
  getp('ds');
  getp('ag');
  getp('phn1');
  getp('phn2');
  getp('em');
  getp('icq');
  
  getp('desc');
  getp('dostup');

  if($ok){
    i2b($type);
    s2b($dn);
    s2b($fn);
    s2b($mn);
    s2b($ln);
    i2b($ds);
    i2b($cn);
    i2b($rg);
    i2b($ct);
    i2b($sc);
    i2b($fc);
    i2b($dv);
    i2b($gr);
    i2b($st);
    s2b($phn1);
    s2b($phn2);
    s2b($em);
    s2b($icq);
    s2b($desc);
    if($add){
      if(checkpass()){
        s2b($new_pass);
        getdbrow("LOGINEXISTS($dn)",$row);
        if($row['DUNAME'] ?? FALSE)
          $ERMESS = "Ошибка! Логин занят.";
        else
          getdbrow("DUSER_ADD($type,$dn,$new_pass,$fn,$mn,$ln,$ds,$cn,$rg,$ct,$sc,$fc,$dv,$gr,$st)",$row);
      }
    }
    else
      getdbrow("DUSER_CNG($edit,$type,$fn,$mn,$ln,$phn1,$phn2,$em,$icq,$ds,$cn, $rg, $ct, $sc, $fc, $dv, $gr, $st, $desc)",$row);
    //dcgoto($_SERVER['PHP_SELF']);
    dcgoto($__routedurlpage__);
    }
  else{
    head('Параметры пользователя');
    formb();
    pole('Тип','type',10,'MANTYPE_LST()','MANAGERTYPE_NAME','MANAGERTYPE_ID');
    pole('Логин','dn',20,'','','',true,true,$add);
    if($add){
      pole('Пароль','new_pass',20,'','','',true,true,true,'','',true);
      pole('Повтор пароля','new_pass1',20,'','','',true,true,true,'','',true);
    }
    pole('Фамилия','ln',40);
    pole('Имя','fn',40);
    pole('Отчество','mn',40);
    pole('Схема','ds',10,'DESIGN_LST()','DESIGN_NAME','DESIGN_ID');
//    pole('Агент','ag',10,"AGENT_LST({$_SESSION['du_ag_city_id']})",'AGENT_NAME','AGENT_ID');
    if($edit){
      pole('Телефон1','phn1',40);
      pole('Телефон2','phn2',40);
      pole('Email','em',40);
      pole('ICQ','icq',40);
      pole('Примечание','desc',80);
      pole('Доступ к объекту','dostup',1);
    }
    forme();
    #$MENU .= "<a href='{$_SERVER['PHP_SELF']}?edit=$edit&npass=1'>Пароль</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?edit=$edit&npass=1'>Пароль</a><br>";
    #$MENU .= "<a href='{$_SERVER['PHP_SELF']}?edit=$edit&_2FA=1'>2FA</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?edit=$edit&_2FA=1'>Установ 2FA</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?edit=$edit&_2FAdel=1'>Сброс 2FA</a><br>";
  }
  mainpaint();
}

fdel('del', "DUSER_DEL", "Удалять пользователя?");

// Получение первого символа строки
if($_SESSION['du_fname'] ?? FALSE)
  $Fn = mb_substr($_SESSION['du_fname'], 0, 1).".";
if($_SESSION['du_mname'] ?? FALSE)
  $Mn = mb_substr($_SESSION['du_mname'], 0, 1).".";
head('Вы зашли как: '.@$_SESSION['du_login'].' ('.@$_SESSION['du_type'].') '.@$_SESSION['du_lname']." ".@$Fn.@$Mn);

if($_SESSION['du_type'] ?? "" == 'Администратор'){
  getp('mask');
  $MAIN .= "<form name=mask method=post>";
  $MAIN .= "Пользователи системы по маске: <input type=text name=mask value=$mask>";
  $MAIN .= "</form>";
  s2b($mask);
  getdbmass("DUSER_LST($mask)", $mass);
  messall($mass);
  $MAIN .= "<table width='100%'>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td>";
  $MAIN .= "<td>Логин</td>";
  $MAIN .= "<td>ФИО</td>";
  $MAIN .= "<td>Тип</td>";
  $MAIN .= "<td>2FA</td>";
  $MAIN .= "<td><img $P_DELT alt='Удалить'></td>";
  $MAIN .= "</tr>";
  $n=0;

  while(getrow($mass, $row)){
    $n++;
    $rcolor = "id=col2";
    if($n%2)
      $rcolor = "id=col1";
    $MAIN .= "<tr $rcolor>";
    $MAIN .= "<td>$n</td>";
    $MAIN .= "<td><a id=col2 href='admin.php?edit={$row['DUSER_ID']}'>";
    $MAIN .= "{$row['DUNAME']}</a></td>";
    $MAIN .= "<td>{$row['DUSER_LNAME']} {$row['DUSER_FNAME']} {$row['DUSER_MNAME']}</td>";
    $MAIN .= "<td>{$row['MANAGERTYPE_NAME']}</td>";
    if ($row['DUSER_2FA_EXISTS'])
      $MAIN .= "<td>+</td>";  
    else
      $MAIN .= "<td></td>";

    //$MAIN .= "<td align=center><a href='{$_SERVER['PHP_SELF']}?del={$row['DUSER_ID']}'><img $P_DEL alt='Удалить'></a></td>";
    $MAIN .= "<td align=center><a href='{$__routedurlpage__}?del={$row['DUSER_ID']}'><img $P_DEL alt='Удалить'></a></td>";
    $MAIN .= "</tr>";
    if(($n >= $MAXREC) && (!isset($_GET['allview'])))
      break;
  }
  $MAIN .= "</table>";
  if($_SESSION['du_type'] == 'Администратор')
    //$MENU .= "<a href='{$_SERVER['PHP_SELF']}?add=1'><img $P_ADD alt='Добавить'> пользователя</a><br>";
    $MENU .= "<a href='{$__routedurlpage__}?add=1'><img $P_ADD alt='Добавить'> пользователя</a><br>";
}
//$MENU .= "<a href='{$_SERVER['PHP_SELF']}?spass=1'>Пароль</a><br>";
$MENU .= "<a href='{$__routedurlpage__}?spass=1'>Пароль</a><br>";

if($_SESSION['du_type'] ?? "" == 'Администратор')
  $MENU .= "<a href='log.php'>Лог_файл</a><br>";

mainpaint();

?>