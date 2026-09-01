<?php
  
session_start();

//echo "SESSID: " . session_id() . "<br>";

if(!isset($_SESSION['du_themes'])){
  $_SESSION['du_themes'] = "1";
}

$themesdir =  "/themes/{$_SESSION['du_themes']}/";
$srcthemes = "src=" . $themesdir;

#echo __DIR__ . "     "  . $themesdir . "    " . $srcthemes;
#exit;


include __DIR__ . "/../public$themesdir" . "style.css";
$PIC_UC = $themesdir . "uc.gif";

$P_EXL =   $srcthemes . "excel.gif";
$P_DEL =   $srcthemes . "delete.gif";
$P_DELT =  $srcthemes . "deletet.gif";
$P_EDIT =  $srcthemes . "edit.gif";
$P_EDITT = $srcthemes . "edit_t.gif";
$P_UC =    $srcthemes . "uc.gif";
$P_UP =    $srcthemes . "up.gif";
$P_DIR =   $srcthemes . "folder.gif";
$P_GRP =   $srcthemes . "group.gif";
$P_ADD =   $srcthemes . "add.gif";
$P_BASK =  $srcthemes . "add.gif";
$P_CAL =   $srcthemes . "cal.gif";
$P_POK =   $srcthemes . "countval.gif";
$P_POKT =  $srcthemes . "countval_t.gif";
$P_COGS =  $srcthemes . "cogsbig.gif";

//глобальные переменные
$DEBUG = '';
$MAIN = '';
$MENU = '';
$MESS = '&nbsp';
$ERMESS = '&nbsp';
$DBN  = '';
$OBJECT = '';
$VERSION = '';
$HOST = 'localhost';
$MCNT = 17;
$GDB = NULL;
$GDBL = NULL;
$MAXREC = 100;


$M = array('январь','февраль','март','апрель','май','июнь',
           'июль','август','сентябрь','октябрь','ноябрь','декабрь');

$Mr = array('январе','феврале','марте','апреле','мае','июне',
           'июле','августе','сентябре','октябре','ноябре','декабре');

//глобальные функции
//штрихкод
include('bar.php');

//двухфакторка
include('dc2fa.php');

//заголовок окна
function head($s)
{
  global $MAIN;
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr><td id=prochead>$s</td></tr>";
  $MAIN .= "</table>";
}

//автопереход к выбраной странице
//(вызывается до посылки хедера, т.е. до любого вывода на странице!)
function dcgoto($name){
  global $nogoto, $MESS, $ERMESS, $__routedurlpage__;
  if($nogoto)
    return;
  if($MESS)
    $_SESSION['MESS'] = $MESS;
  if($ERMESS)
    $_SESSION['ERMESS'] = $ERMESS;

  //echo "DCGOTO: " . $name . " " . $__routedurlpage__ . "<br>";
  
  echo "<meta http-equiv=refresh content='0; URL=$name'></body></html>";
  exit;
}


function opendb(){
  global $HOST, $DBN, $GDB, $GDBL;
  $HOST = getenv('DB_HOST') ?: $HOST;
  $port = (int) (getenv('DB_PORT') ?: 3306);
  $user = isset($_SESSION['du_name']) ? dc_decrypt($_SESSION['du_name']) : getenv('DB_USER');
  $pass = isset($_SESSION['du_pass']) ? dc_decrypt($_SESSION['du_pass']) : getenv('DB_PASSWORD');

  $GDB = new mysqli($HOST, $user, $pass, null, $port);
  if(mysqli_connect_errno()){
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit;
  }
  if(!$GDB->set_charset("utf8")){
    printf("Error loading character set utf8: %s\n", $GDB->error);
    exit;
  }
  $GDBL = new mysqli($HOST, $user, $pass, null, $port);
  if(mysqli_connect_errno()){
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit;
  }

  if(!$GDBL->set_charset("utf8")){
    printf("Error loading character set utf8: %s\n", $GDBL->error);
    exit;
  }

}

function getdbrowproc($procedure, $parameters, &$row)
{
  global $DBN, $GDB, $ERMESS;

  if(!$GDB)
    opendb();
  if(!preg_match('/^[A-Z][A-Z0-9_]*$/', $procedure)){
    $ERMESS = 'Ошибка выполнения операции.';
    return false;
  }

  $placeholders = implode(',', array_fill(0, count($parameters), '?'));
  $statement = $GDB->prepare("CALL `$DBN`.`$procedure`($placeholders)");
  if(!$statement){
    $ERMESS = 'Ошибка выполнения операции.';
    return false;
  }
  if($parameters){
    $types = '';
    $values = array();
    foreach($parameters as $value){
      $types .= is_int($value) ? 'i' : 's';
      $values[] = $value;
    }
    $statement->bind_param($types, ...$values);
  }
  if(!$statement->execute()){
    $ERMESS = 'Ошибка выполнения операции.';
    $statement->close();
    return false;
  }
  $result = $statement->get_result();
  $row = $result ? $result->fetch_array(MYSQLI_ASSOC) : null;
  while($GDB->more_results() && $GDB->next_result());
  $statement->close();
  return is_array($row);
}

function csrf_token()
{
  $manager = new \Decanet\Security\CsrfTokenManager();
  return $manager->token();
}

function csrf_validate($token)
{
  $manager = new \Decanet\Security\CsrfTokenManager();
  $manager->validate($token);
}

//запрос к базе с получением массива ответа
function getdbmass($query, &$mass)
{
  global $DBN, $debug, $DEBUG, $GDB, $GDBL, $MESS, $ERMESS, $nogoto;

  //echo "GETDBMASS: " . $query . " GDB: " . isset($GDB) . "<br>"; 

  if((!$GDB) || (!$GDBL))
    opendb();

  if($debug){
    $DEBUG .= "CALL $DBN.$query; ";
    $tb = microtime(1);
  }
  $GDB->multi_query("CALL $DBN.$query;");
  $mass = $GDB->store_result();
  $ret = 'NULL';
  if($mass){
    $row = $mass->fetch_array(MYSQLI_ASSOC);
    $mass->data_seek(0);
    if(isset($row['RES']))
      $ret = $row['RES'];
  }

//  $mass1 = $GDB->store_result();
  $error = '';
  $errno = 0;
  if($GDB->errno){
    $errno = $GDB->errno;
    $error = $GDB->error;
//    $nogoto = true;
    if($GDB->errno == 1370)
      $ERMESS ="Доступ к операции запрещен.";
    else{
      $ERMESS ="Ошибка выполнения операции. Проверьте поля, обязательные для заполнения. <a href='error.php'>Подробно.</a>";
      $_SESSION['error'] = "CALL $DBN.$query;<br>{$GDB->error}";
    }
  }
  while($GDB->next_result());
  if($debug){
    $te = microtime(1);
    $t = number_format($te-$tb, 4, '.', '');
    $DEBUG .= "- $t <br>";
  }
//log
  $query = addslashes($query);
  $error = addslashes($error);
  if(isset($_SESSION['du_id'])){
    $GDBL->multi_query("CALL $DBN.SYSLOG_ADD({$_SESSION['du_id']},'$query',$errno,'$error',$ret);");
    $GDBL->store_result();
    while($GDBL->next_result());
  }
//end log
}

//внимание! в этой функции лог не ведется и вообще от нее надо избавляться
function getdbm($query, &$mass)
{

  global $DBN, $debug, $DEBUG, $GDB, $MESS, $ERMESS;

  if(!$GDB)
    opendb();
  if($debug)
    $DEBUG .= "CALL $DBN.$query;";
  if($GDB->more_results())
    $GDB->next_result();
  else
    $GDB->multi_query("CALL $DBN.$query;");
  $mass = $GDB->store_result();

  if($GDB->errno){
    if($GDB->errno == 1370){
      $ERMESS ="Доступ к операции запрещен.";
      $_SESSION['error'] = "CALL $DBN.$query;<br>{$GDB->error}"; 
    }
    else{
      $ERMESS ="Ошибка выполнения операции №{$GDB->errno} <a href='error.php'>Подробно.</a>";
      $_SESSION['error'] = "CALL $DBN.$query;<br>{$GDB->error}";
    }
  }

  return $GDB->more_results();
}

/*
function getdbmn(&$mass){
  $mass = $GDB->store_result();
}
*/

//взять строку из массива ответа
function getrow(&$mass, &$row, $ass=true)
{
  $ret = false;
  if($mass)
  {
    if($ass)
      $row = $mass->fetch_array(MYSQLI_ASSOC);
    else
      $row = $mass->fetch_array(MYSQLI_BOTH);
    if($row) 
      $ret = true;
  }
  return $ret;
}

//взять первую строку из базы
function getdbrow($query, &$row)
{

  //echo "GETDBROW: " . $_SESSION['du_name'] . " " . $_SESSION['du_pass'] . "<br>";

  getdbmass($query, $mass);
  $ret = getrow($mass, $row);
  return $ret;
}


//вывод главной таблицы
function mainpaint($exit=1)
{
  global $MAIN, $MENU, $OBJECT, $MESS, $ERMESS, $DEBUG, $LOGO, $COPYRIGHT, $VERSION, $GL_begintime, $debug;
  $user = "не зарегистр.";
  if(isset($_SESSION['du_lname'])){
    $Fn = $Mn = "";
// Получение первого символа строки
    if($_SESSION['du_fname'])
      $Fn = mb_substr($_SESSION['du_fname'], 0, 1).".";
    if($_SESSION['du_mname'])
      $Mn = mb_substr($_SESSION['du_mname'], 0, 1).".";
    $user = $_SESSION['du_lname']." ".$Fn.$Mn;
  }
//основная таблица
  echo "<table id=menu cellspacing=0 border height=100% width=100%>";
  echo "<tr>";
  echo "  <td>$LOGO</td>";
  echo "  <td width=100%>$OBJECT</td>";
  echo "</tr>";
  echo "<tr>";
  echo "  <td align=center>$VERSION</td>";
  // echo "  <td id=redtext>$MESS</td>";
  echo "  <td><span id=redtext>$ERMESS</span><span id=greentext>$MESS</span></td>";
  echo "</tr>";
  echo "<tr valign=top height=100%>";
  echo "  <td>$MENU</td>";
  echo "  <td>";
  echo "      <table id=main cellspacing=0 height=100% width=100%><tr>";
  echo "      <tr height=100%><td valign=top width='100%'>$MAIN</td></tr>";
  echo "      <tr><td align=right>$COPYRIGHT</td></tr></table>";
  echo "  </td>";
  echo "</tr>";
  echo "</table>";
  echo $DEBUG;
  if($debug){
    $timer = number_format(microtime(1) - $GL_begintime, 4, '.', '');
    echo $timer;
  }

  
// Vasso 20081004 begin
// Для статистика посещения страниц
/*
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-4434793-1";
urchinTracker();
</script> 
*/

/* // а что Vasso делать тому кто не в инете а например в ЦБ? 
echo "\n<script src=\"http://www.google-analytics.com/urchin.js\" type=\"text/javascript\">\n";
echo "</script>\n";
echo "<script type=\"text/javascript\">\n";
echo "_uacct = \"UA-4434793-1\";\n";
echo "urchinTracker();\n";
echo "</script>\n";
*/
// Vasso 20081004 end
  
  
  
  echo "</body></html>";
  if($exit)
    exit;
}


//меню
define('HORIZONTAL', 0);
define('VERTICAL', 1);
function menu($m, $add = '', $direct = HORIZONTAL, $qs='')
{
  global $$m, $__routedurlpage__;

  $mass = $$m;
  $head = $mass[0];
  $cur = 0;
  if(isset($_GET[$m]))
    $_SESSION[$m] = $_GET[$m];
  if(isset($_SESSION[$m]))
    $cur = $_SESSION[$m];
  $ch = "id=curhr";
  $br = $beg = $end = $ret = $end1 = '';
  if($direct == HORIZONTAL){
    $ret .= "<table width=100%><tr><td id=page><b>$head</b></td>";
    $beg = '<td id=page>';
    $end = '</td>';
    $end1 = "<td width=100% id=page>$add</td></tr></table>";
  }
  else{
    if($head)
      $ret .="<b>$head</b><hr>";
    $br = '<br>';
  }
  foreach($mass as $k => $v){
    if(!$k)
      continue;
    $kk = $k-1;
    if($kk == $cur)
      $ch = 'id=curhr';
    else
      $ch = '';
    if($v == ''){
      if($direct == VERTICAL)
        $ret .= '<hr>';
      else
        $ret .= '';
    }
    else
      //$ret .= "$beg<a $ch href='{$_SERVER['PHP_SELF']}?$m=$kk$qs'>$v</a>$br$end";
      $ret .= "$beg<a $ch href='{$__routedurlpage__}?$m=$kk$qs'>$v</a>$br$end";
  }
  $ret .= $end1;
  return $ret;
}


//проверка регистрации
function nsd()
{
  global $__routedurlpage__, $__logintimeout__;

  //echo "NSD: " . " " . $__routedurlpage__ . " " . $_SESSION['du_id'] . "<br>";
  //print_r($_SESSION); echo "<br>";

  //если пользователь зарегистрирован
  if(isset($_SESSION['du_id'])) {
    if(time() > $_SESSION['expire']){
      //session_destroy();
      $_SESSION['expired_du_id'] = $_SESSION['du_id'];
      unset($_SESSION['du_id']);
      //echo "NSD expire GOTO login!";
      dcgoto('login.php');
    } else {
      $_SESSION['expire'] = time() + $__logintimeout__;  
      //echo "NSD expire prolonged.";
    } 
    return;
  }

  //если незарегистрирован и это не login.php
  if(basename($__routedurlpage__) != 'login.php'){
    echo 'alarm! hacker attack!' . " " . basename($__routedurlpage__);
    exit;
  }
}


//постраничный вывод
function page($all, $max, $par='')
{
  global $MAIN;
  global $__routedurlpage__;

  $mpage = ceil($all/$max);
  if($mpage == 0)
    $mpage = 1;
  $cpage = 1;
  if($mpage == 1)
    return $cpage;
  if(isset($_GET['page']))
    $cpage = $_GET['page'];
  if($cpage > $mpage)
    $cpage = $mpage;
  if($cpage < 1)
    $cpage = 1;
  $ppage = $cpage - 1;
  $npage = $cpage + 1;
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr><td id=page>";
  if($cpage > 1){
    $MAIN .= "<a href={$__routedurlpage__}?$par&page=1><<</a> ";
    $MAIN .= "<a href={$__routedurlpage__}?$par&page=$ppage><</a> ";
  }
  else
    $MAIN .= "<< < ";
  $MAIN .="(стр $cpage из $mpage) ";
  if($cpage < $mpage)
  {
    $MAIN .= "<a href={$__routedurlpage__}?$par&page=$npage>></a> ";
    $MAIN .= "<a href={$__routedurlpage__}?$par&page=$mpage>>></a> ";
  }
  else
    $MAIN .= " > >>";
  $MAIN .= "</td></tr></table>";
  return $cpage;
}


function sst($par){
  global $MAIN;
  if(!(isset($_REQUEST['excel']) && ($_REQUEST['excel'] == 1))){
    $MAIN .= "<p id=notprint>";
    $MAIN .= "<a href='$par'>Вернуться</a> ";
    $MAIN .= "</p>";
  }
}


function b2d(&$par){
  if(!$par)
    $par = '';
  else{
    list($by, $bm, $bd) = sscanf($par, '%04d-%02d-%02d');
    $par = sprintf('%02d.%02d.%04d', $bd, $bm, $by);
  }
}

function b2l(&$par){
  if(!$par)
    $par = 'нет';
  else
    $par = 'да';
}

function l2b(&$par){
  if(!$par)
    $par = 0;
  else
    $par = 1;
}

function b2p(&$par){
  global $M;
  if(!$par)
    $par = '';
  else{
    list($by, $bm, $bd) = sscanf($par, '%04d-%02d-%02d');
    $par = sprintf("%s %04d", $M[$bm-1], $by);
  }
}

function d2b(&$par){
  if($par == '')
    $par = 'NULL';
  else{
    list($bd, $bm, $by) = sscanf($par, '%02d.%02d.%04d');
    if($by < 100)
      $by += 2000;
    $par = sprintf("'%04d-%02d-%02d'", $by, $bm, $bd);
  }
}

function p2b(&$par){
  global $M;
  if($par == '')
    $par = 'NULL';
  else{
    list($bmc, $by) = sscanf($par, '%s %04d');
    $bm = array_search($bmc, $M) + 1; 
    $par = sprintf("'%04d-%02d-%02d'", $by, $bm, 1);
  }
}

function i2b(&$par){
  if($par == '')
    $par = 'NULL';
  else{
    $par = str_replace(",", ".", $par);
//    $par = sprintf("%f",$par);
  }
}

function s2b(&$par){
  if($par == '')
    $par = 'NULL';
  else{
    $par = addslashes($par);
//    $par = htmlentities($par,ENT_QUOTES,'utf-8');
    $par = "'$par'";
  }
}


function getp($name,$conv=1){
  global $$name;
  if(!isset($$name))
    $$name = '';
  if(isset($_REQUEST[$name]))
    if($conv)
      $$name = htmlentities($_REQUEST[$name],ENT_QUOTES,'utf-8');
    else
      $$name = $_REQUEST[$name];
}



/*
$n - заголовок
$ngp - значение
$size - width
$func - list stored proc
$pn - что-то по выбору ?
$pid - object id from list stored proc
$tr - делать новую строку таблицы
$nn - добавлять ли пусто в спиское выбора
$edit - disable input box
$add -
$tab - tabindex ?
$pass - hidden text for password
*/
// pole('Введите одноразовый пароль:','',10,'','','',true,true,$add); 
function pole($n,$ngp,$size=10,$func='',$pn='',$pid='',$tr=true, $nn=true, $edit=true, $add='',$tab='',$pass=false){
  global $$ngp,$MAIN;
  $np = $$ngp;
//  if(isset($_REQUEST[$ngp]))
//    $np = $_REQUEST[$ngp]; 
  if($tr)
    $MAIN .= "<tr><td align=right>";
  if($tab)
    $tabli = "tabindex=$tab";
  else
    $tabli = '';
  $MAIN .= "<span id=col4>$n</span>";
  if($tr)
    $MAIN .="</td><td>";
  else
    $MAIN .=" ";
  if($edit)
    $disabl = '';
  else
    $disabl = 'disabled';

//  if($edit)
    if($func == ''){
      if($size == 1){
        $ch = '';
        if($np == 1)
          $ch = 'checked';
        $MAIN .= "<input $disabl $tabli type=checkbox name=$ngp value='1' $ch>";
      }
      elseif($pass)
        $MAIN .= "<input $disabl $tabli type=password size=$size name=$ngp value='$np'>".$add;
      elseif($size > 80)
        $MAIN .= "<textarea $disabl $tabli name=$ngp rows=3 cols=62>$np</textarea>".$add;
      else
        $MAIN .= "<input $disabl $tabli type=text size=$size name=$ngp value='$np'>".$add;
    }
    else{
      $MAIN .= "<select $disabl $tabli name=$ngp size=1>";
      if($nn)
        $MAIN .= "<option value=''>";
      getdbmass($func, $mass);  
      while(getrow($mass, $row1)){
        $sel = '';
        if($row1[$pid] == $np)
          $sel = 'selected';
        $MAIN .= "<option $sel value={$row1[$pid]}>{$row1[$pn]}";
      }
      $MAIN .= "</select> ".$add;
    }
/*
  else{
    if($func == ''){
      if($size == 1){
        if($np)
          $ch = 'да';
        else
          $ch = 'нет';
        $MAIN .= "<span id=polev$size>$ch</span>";
      }
      else
        $MAIN .= "<span id=polev$size>$np</span>".$add;
    }
    else{
      getdbmass($func, $mass);  
      $zn = '';
      while(getrow($mass, $row1))
        if($row1[$pid] == $np){
          $zn = $row1[$pn];
          break;
        }
      $MAIN .= "<span id=polev$size>$zn</span>";
    }
  }
*/
  if($tr)
    $MAIN .= "</td></tr>";
  else
    $MAIN .= " ";
}

function getdt($gdt, $dt, $type = 1,$add=''){
  global $MAIN, $$dt, $M;
  global $__routedurlpage__;
//  if(isset($_REQUEST['stype']))
//    $type = $_REQUEST['stype'];
  $par = '';
  if(!isset($_REQUEST[$gdt]))
    return;
  foreach($_REQUEST as $r => $k)
    if(($r != $gdt) && ($r != $dt) /* && ($r != 'stype') */){
      $k1 = urlencode($k);
      $par .= "&$r=$k1";
    }
  $par .= $add;
  list($cd, $cm, $cy) = sscanf(date("d.m.Y"), "%02d.%02d.%04d");
  $sdate = mktime(0,0,0,$cm,1,$cy);
  if($$dt){
    if($type == 3){
      p2b($$dt);
      b2d($$dt);
    }
    list($cd, $cm, $cy) = sscanf($$dt, "%02d.%02d.%04d");
    if(checkdate($cm,1,$cy))
      $sdate = mktime(0,0,0,$cm,1,$cy);
  }
  list($cd, $cm, $cy) = sscanf(date("d.m.Y", $sdate), "%02d.%02d.%04d");
  $fd = date("w", $sdate);
  if($fd == 0)
    $fd = 7;
  $z = array();
  for($i=1; $i<38; $i++){
    $z[$i] = $i-$fd+1;
    if($z[$i] < 1 || $z[$i] > 31)
      $z[$i] = '';
    else
      if(!checkdate($cm,$z[$i],$cy))
        $z[$i] = '';
    if($z[$i]){
      $sd = sprintf("%02d.%02d.%04d", $z[$i],$cm,$cy);
      $z[$i] = "<a href='{$__routedurlpage__}?$dt=$sd$par'>{$z[$i]}</a>";
    }
  }

  $ffyear = sprintf("%02d.%02d.%04d",$cd,$cm,$cy-10);
  $fyear = sprintf("%02d.%02d.%04d",$cd,$cm,$cy-1);
  $lyear = sprintf("%02d.%02d.%04d",$cd,$cm,$cy+1);
  $llyear = sprintf("%02d.%02d.%04d",$cd,$cm,$cy+10);
  $curdate = date("d.m.Y");

  if($cm == 1)
    $fm = sprintf("%02d.%02d.%04d",$cd,12,$cy-1);
  else
    $fm = sprintf("%02d.%02d.%04d",$cd,$cm-1,$cy);
  if($cm == 12)
    $lm = sprintf("%02d.%02d.%04d",$cd,1,$cy+1);
  else
    $lm = sprintf("%02d.%02d.%04d",$cd,$cm+1,$cy);

  $a = 'align=center';
  $x = "</td><td id=col2 $a>";
  $y = "</td><td id=col4 $a>";
  $w = 'width=14%';
  if($type == 1)
    $ncol = 7;
  else
    $ncol = 1;

//  $cdate1 = sprintf("%02d.%02d.%04d",1,$cm,$cy);
//  if($type == 1)
//    head("Выбор даты <a href='{$__routedurlpage__}?$gdt=1&$dt=$cdate1&stype=2$par'>периода</a>");
//  else
//    head("Выбор периода <a href='{$__routedurlpage__}?$gdt=1&$dt=$cdate1&stype=1$par'>даты</a>");

  head('Выбор даты');
  $MAIN .= "<table id=calendar>";
  if($type == 1)
    $MAIN .= "<tr><td width=16%></td><td $w></td><td $w></td><td $w></td><td $w></td><td $w></td><td $w></td></tr>";
  else
    $MAIN .= "<tr><td width=100%></td></tr>";
  $MAIN .= "<tr><td id=col2 $a colspan=$ncol><a href='{$__routedurlpage__}?$dt=$curdate$par'>сегодня: $curdate</a></td></tr>";
  $MAIN .= "<tr><td id=col2 $a colspan=$ncol>";
//  $MAIN .= "<a href='{$__routedurlpage__}?$gdt=1&$dt=$ffyear$par'><<</a> ";
  $MAIN .= "<a href='{$__routedurlpage__}?$gdt=1&$dt=$fyear$par'><</a> ";
  $MAIN .= "$cy ";
  $MAIN .= "<a href='{$__routedurlpage__}?$gdt=1&$dt=$lyear$par'>></a> ";
//  $MAIN .= "<a href='{$__routedurlpage__}?$gdt=1&$dt=$llyear$par'>>></a> ";
  $MAIN .= "</td></tr>";

  if($type == 1){
    $MAIN .= "<tr><td id=col2 $a colspan=$ncol>";
    $MAIN .= "<a href='{$__routedurlpage__}?$gdt=1&$dt=$fm$par'><</a> ";
    $MAIN .= "{$M[$cm-1]} ";
    $MAIN .= "<a href='{$__routedurlpage__}?$gdt=1&$dt=$lm$par'>></a> ";
    $MAIN .= "</td></tr>";
    $MAIN .= "<tr><td id=col2>ПН:$x{$z[1]}$x{$z[8]}$x{$z[15]}$x{$z[22]}$x{$z[29]}$x{$z[36]}</td></tr>";
    $MAIN .= "<tr><td id=col2>ВТ:$x{$z[2]}$x{$z[9]}$x{$z[16]}$x{$z[23]}$x{$z[30]}$x{$z[37]}</td></tr>";
    $MAIN .= "<tr><td id=col2>СР:$x{$z[3]}$x{$z[10]}$x{$z[17]}$x{$z[24]}$x{$z[31]}$x</td></tr>";
    $MAIN .= "<tr><td id=col2>ЧТ:$x{$z[4]}$x{$z[11]}$x{$z[18]}$x{$z[25]}$x{$z[32]}$x</td></tr>";
    $MAIN .= "<tr><td id=col2>ПТ:$x{$z[5]}$x{$z[12]}$x{$z[19]}$x{$z[26]}$x{$z[33]}$x</td></tr>";
    $MAIN .= "<tr><td id=col4>СБ:$y{$z[6]}$y{$z[13]}$y{$z[20]}$y{$z[27]}$y{$z[34]}$y</td></tr>";
    $MAIN .= "<tr><td id=col4>ВС:$y{$z[7]}$y{$z[14]}$y{$z[21]}$y{$z[28]}$y{$z[35]}$y</td></tr>";
  }
  else{
    for($i=1;$i<13;$i++){
      if($type == 3)
        $cdate = sprintf("%s %04d",$M[$i-1],$cy);
      else
        $cdate = sprintf("%02d.%02d.%04d",1,$i,$cy);
      $MAIN .= "<tr><td id=col2 align=center><a href='{$__routedurlpage__}?$dt=$cdate$par'>{$M[$i-1]}</td></tr>";
      }
  }
  $MAIN .= "</table>";
  mainpaint();
}

function getTFN($m){
  switch($m){
    case 0:
      $ret = 'TRUE';
      break;
    case 1:
      $ret = 'FALSE';
      break;
    case 2:
      $ret = 'NULL';
      break;
  }
  return $ret;
}


//преобразование цифр из арабского в римские
function a2r($par){
  $ret = $par;
  switch($par){
    case '1':
      $ret = 'I';
      break;
    case '2':
      $ret = 'II';
      break;
    case '3':
      $ret = 'III';
      break;
    case '4':
      $ret = 'IV';
      break;
    case '5':
      $ret = 'V';
      break;
    case '6':
      $ret = 'VI';
      break;
    case '7':
      $ret = 'VII';
      break;
    case '8':
      $ret = 'VIII';
      break;
    case '9':
      $ret = 'IX';
      break;
    case '10':
      $ret = 'X';
      break;
    case '11':
      $ret = 'XI';
      break;
    case '12':
      $ret = 'XII';
      break;
    case '13':
      $ret = 'XIII';
      break;
    case '14':
      $ret = 'XIV';
      break;
    case '15':
      $ret = 'XV';
      break;
    case '16':
      $ret = 'XVI';
      break;
    case '17':
      $ret = 'XVII';
      break;
    case '18':
      $ret = 'XVIII';
      break;
    case '19':
      $ret = 'XIX';
      break;
    case '20':
      $ret = 'XX';
      break;
  }
  return $ret;
}

function formb($metod='post', $type=''){
  global $MAIN;
  $MAIN .= "<form $type method=$metod>";
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr><td width=40%></td><td width=60%></td></tr>";
}

function forme($button=true){
  global $MAIN;
  if($button){
    $MAIN .= "<td align=right><input type=submit name=ok value='Принять'></td>";
    $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
  }
  $MAIN .= "</tr></table></form>";
}

function messall($mass){
 global $MESS, $ERMESS, $MAXREC, $__routedurlpage__;

 if($mass && ($mass->num_rows > $MAXREC) && (!isset($_GET['allview'])))
     $MESS .= " найдено {$mass->num_rows} записей, показано $MAXREC первых, <a href={$__routedurlpage__}?{$_SERVER['QUERY_STRING']}&allview=1>показать все</a>";
}

function fdel($del, $func, $messg, $add='', $add1='',$par=1,$par1=1,$gt=1){

  global $__routedurlpage__;

  if(!isset($_GET[$del]))
    return;
  global $MAIN;
  $param = '';
  if($par)
    foreach($_GET as $k=>$v)
      if($k != $del)
        if($param)
          $param .="&$k=$v";
        else
          $param ="?$k=$v";
  if(isset($_POST['canceld']))
    dcgoto("{$__routedurlpage__}$param");
//  if(isset($_GET["$del"])){
    if(isset($_POST["okd"])){
      if($par1)
        $gid = $_GET["$del"];
      else
        $gid = '';
      getdbrow("$func($add$gid$add1)", $row);
      if($gt)
        dcgoto("{$__routedurlpage__}$param");
    }
    else{
      $gid = $_GET["$del"];
      $MAIN .= "<form name=del method=post>";
      $MAIN .= "<table width=100%>";
      $MAIN .= "<tr><td width=50%></td><td width=50%></td></tr>";
      $MAIN .= "<tr><td colspan=2 align=center><span id=col4>$messg</span></td></tr>";
      $MAIN .= "<td align=right><input type=submit name=okd value='Принять'></td>";
      $MAIN .= "<td><input type=submit name=canceld value='Отменить'><td>";
      $MAIN .= "</tr></table></form>";
      mainpaint();
    }
//  }
}


function checkpass(){
  global $MESS, $ERMESS, $new_pass, $new_pass1, $old_pass;
  $ret = 1;
  if($new_pass != $new_pass1){
    $ERMESS = "Ошибка! Неверно введен новый пароль.";
    $ret = 0;
  }else
  if(strlen($new_pass) < 5){
    $ERMESS = "Ошибка! Длина пароля не может быть меньше 5 символов.";
    $ret = 0;
  }else
  if($old_pass == $new_pass){
    $ERMESS = "Ошибка! Старый и новый пароль совпадают.";
    $ret = 0;
  }
  return $ret;
}

function passgen($len){
  $ret = '';
  $gl = 'aeiouy';
  $sl = 'bcdfghkjlmnpqrstvwxz';
  srand((float)microtime() * 1000000);
  $m=floor(rand(0, 1));
  if($m)
    for($i=0;$i<($len/2);$i++){
      $ret .= $gl[floor(rand(0, 5))];
      $ret .= $sl[floor(rand(0, 19))];
    }
  else
    for($i=0;$i<($len/2);$i++){
      $ret .= $sl[floor(rand(0, 19))];
      $ret .= $gl[floor(rand(0, 5))];
    }
  $m = floor(rand(0, $len-1));
  $l = floor(rand(0, 9));
  while($l == 1)
    $l = floor(rand(0, 9));
  $ret[$m] = $l;
  return $ret;
}

function dc_encrypt($string) {
    $output = false;

    $encrypt_method = "AES-256-CBC";
    $secret_key = 'secret_key';
    $secret_iv = 'secret_iv';

    // hash
    $key = hash('sha256', $secret_key);
    
    // iv - encrypt method AES-256-CBC expects 16 bytes - else you will get a warning
    $iv = mb_substr(hash('sha256', $secret_iv), 0, 16);

    $output = openssl_encrypt($string, $encrypt_method, $key, 0, $iv);
    $output = base64_encode($output);

    return $output;
}

function dc_decrypt($string) {
    $output = false;

    $encrypt_method = "AES-256-CBC";
    $secret_key = 'secret_key';
    $secret_iv = 'secret_iv';

    // hash
    $key = hash('sha256', $secret_key);
    
    // iv - encrypt method AES-256-CBC expects 16 bytes - else you will get a warning
    $iv = mb_substr(hash('sha256', $secret_iv), 0, 16);

    $output = openssl_decrypt(base64_decode($string), $encrypt_method, $key, 0, $iv);

    return $output;
}

?>
