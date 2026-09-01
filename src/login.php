<?php

include "global.php";  //sesion started

//echo "LOGIN EXPIRED SESSFLAG: " . isset($_SESSION['expired_du_id']) . "<br>";

$body = '';

//if(!(isset($_POST['user']) && isset($_POST['password'])))
//  $body = "<body onload=this.document.vvod.user.focus()>";


// если не логин по бездействию то сбрасываем сессию
/*
if (!isset($_SESSION['expired_du_id'])) {
  $_SESSION = array();
  session_regenerate_id(true);
  session_unset();
  session_destroy();
  echo "SESS DESTROY.";
}
*/


$MENU = "<a href='//{$_SERVER['HTTP_HOST']}'>Выход</a>";

function setdefsess($rrow) {   
  global $GDB, $GDBL, $OBJ, $__logintimeout__;
  
  $_SESSION = array();

  $_SESSION['du_id'] = $rrow['DUSER_ID'];
  $_SESSION['du_name'] = dc_encrypt($rrow['BUNAME']);
  $_SESSION['du_pass'] = dc_encrypt($rrow['BUPASS']);

//  echo "SETDEFSESS du_id: " . $_SESSION['du_id'] . "<br>";
 
  $_SESSION['expire'] = time() + $__logintimeout__;

  $_SESSION['du_login']  = $_POST['user'];
  $_SESSION['du_lname']  = $rrow['DUSER_LNAME'];
  $_SESSION['du_fname']  = $rrow['DUSER_FNAME'];
  $_SESSION['du_mname']  = $rrow['DUSER_MNAME'];
  $_SESSION['du_type']   = $rrow['MANAGERTYPE_NAME'];
  $_SESSION['du_themes'] = $rrow['DESIGN_ID'];

  for($i=0; $i<8; $i++) {
    $np = strtoupper($OBJ[$i]);
    $_SESSION["co_{$OBJ[$i]}"] = $_SESSION["du_{$OBJ[$i]}"] = $rrow["{$np}_ID"];
  }
    
  #echo "<p> BUNAME: " . $rrow['BUNAME'] . " BUPASS: " . $rrow['BUPASS'] . " SUNAME: " . $_SESSION['du_name'] . " SUPASS: " . $_SESSION['du_pass'] . "</p>";     
  #exit;

  $_SESSION['facm'] = 0;       //состав факультета
  $_SESSION['fac1m'] = 0;      //активные отделения на факультете
  $_SESSION['divm'] = 0;       //состав отделения
  $_SESSION['div1m'] = 0;      //активные группы на отделении
  $_SESSION['sgrm'] = 0;       //состав группы
  $_SESSION['sgrm1'] = 0;      //активные студенты
  $_SESSION['fm'] = 0;         //поиск студентов

  $_SESSION['stm'] = 0;        //личные данные
  $_SESSION['mpcs'] = 0;       //начальный семестр mainprog
  $_SESSION['mpyear'] = 0;     //начальный год mainprog
  $_SESSION['sortsub'] = 0;    //сортировка предметов по областям
  $_SESSION['cursem'] = 0;     //текущий семестр
  $_SESSION['typedoc'] = 0;    //последний документ 
  $_SESSION['resm'] = 1;       //все результаты
  $_SESSION['baskc'] = 0;      //корзина пуста
  $_SESSION['bask'] = array(); //корзина
  $_SESSION['bask'][] = 0;
  $_SESSION['MPL'] = array();  // очищаем список предметов для сводки
  $_SESSION['MPL'][] = 0;
  $_SESSION['msubj'] = 0;      // дисциплины по ГОС
  $_SESSION['usp'] = 1;        //успеваемость: основная
  $_SESSION['glm'] = 1;        //объект
}

function dc_restore_session($rrow) {   
  global $GDB, $GDBL, $OBJ, $__logintimeout__;

  //echo "RESTORE SESS ROW du_id: " . $rrow['DUSER_ID'] . " EXPIRED FLAG: " . isset($_SESSION['expired_du_id']) . "<br>";

  if (isset($_SESSION['expired_du_id']) && ($_SESSION['expired_du_id'] == $rrow['DUSER_ID'])) {
    
    $_SESSION['du_id'] = $rrow['DUSER_ID'];
    $_SESSION['du_name'] = dc_encrypt($rrow['BUNAME']);
    $_SESSION['du_pass'] = dc_encrypt($rrow['BUPASS']);
    $_SESSION['expire'] = time() + $__logintimeout__;

    //echo 'EXPIRE process done: ' . $_SESSION['du_id'] . ' ' .  $_SESSION['du_name'] . "<br>";

  }
  else {
    setdefsess($rrow);
    //echo 'NON EXP process done: ' . $_SESSION['du_id'] . ' ' .  $_SESSION['du_name'] . "<br>";
  }

  //echo  'CALL VER: ' . $_SESSION['du_id'] . ' ' . $_SESSION['du_name'] . ' ' . "<br>"; 
  getdbrow("DBVER_ITM()", $rrow);
  $_SESSION['db_ver'] = "/{$rrow['DBVER']}";

//  echo 'UNSET EXPIREFLAG.' . "<br>";
  unset($_SESSION['expired_du_id']);  // завершена обработка логина по бездействию 
//  print_r($_SESSION); echo "<br>";

  selobj(); //автопереход к странице по умолчанию
  //dcgoto("student.php");
}

//первый вход
$first = true;
if($demouser)
  $_POST['user'] = $_POST['password'] = 'demo';

//если пользователь ввел имя и пароль
if(isset($_POST['user']) && isset($_POST['password'])){
  $first = false;
  try {
    csrf_validate(isset($_POST['_csrf']) ? $_POST['_csrf'] : null);
    getdbrowproc('GETRUINFO', array((string) $_POST['user'], (string) $_POST['password']), $row);
  } catch (\RuntimeException $exception) {
    $row = array();
  }

  $vrow = $row;

  unset($GDB);
  //echo "UNSET GDB: " . isset($GDB) . "<br>";
  //print_r($vrow); echo "<br>";

  //имя и пароль верны
  if(isset($vrow['DUSER_ID'])){
    
    if (isset($vrow['DU_2FA'])){  //если установлен ключ 2FA
      $options2fa = set2FAoptions();
      if (verify2FAcode($options2fa, $vrow['DU_2FA'], (string) ($_POST['code2fa'] ?? ''))) {

        dc_restore_session($vrow);

      } 
    } else {

      dc_restore_session($vrow);

    }
  }
}

//если пользователь незарегистрирован
if($first)
  head('Вход в систему:');
else
  head('Неверное имя, пароль или разовый код! Попытайтесь снова:');

$MAIN .= "<form name=vvod method=post>";
$MAIN .= "<input type=hidden name=_csrf value='".htmlspecialchars(csrf_token(), ENT_QUOTES, 'UTF-8')."'>";
$MAIN .= "<table>";
$MAIN .= "<tr><td>Имя:</td>";
$MAIN .= "<td><input type=text size=21 name=user></td></tr>";
$MAIN .= "<tr><td>Пароль:</td>";
$MAIN .= "<td><input type=password size=21 name=password></td></tr>";
$MAIN .= "<tr><td>Разовый код:</td>";
$MAIN .= "<td><input type=text size=21 name=code2fa></td></tr>";
$MAIN .= "<tr><td colspan=2 align=center>";
$MAIN .= "<input type=submit value='Принять'></td></tr>";
$MAIN .= "</table></form>";

mainpaint();
?>
