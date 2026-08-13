<?php
  #decanet routing index

  #echo 'URI: ' . $_SERVER['REQUEST_URI'];
  #echo $_REQUEST['edit'];

  $request = $_SERVER['REQUEST_URI'];

  $__routedurlpage__ = preg_replace('/^([^?]+)(\?.*?)?(#.*)?$/', '$1$3', $request);

  //echo $request . " " . $__routedurlpage__;
  //exit;

//$__routedurlpage__ = "/country.sit";

  switch ($__routedurlpage__) {

/*
    case $__routedurlpage__:
        require __DIR__ . '/../deca' . $__routedurlpage__;
        break;
*/

    case '/admin.sit':
        require __DIR__ . '/../deca/admin.sit';
        break;

    case '/bask.sit':
        require __DIR__ . '/../deca/bask.sit';
        break;

    case '/city.sit':
        require __DIR__ . '/../deca/city.sit';
        break;

    case '/country.sit':
        require __DIR__ . '/../deca/country.sit';
        break;

    case '/division.sit':
        require __DIR__ . '/../deca/division.sit';
        break;

    case '/dnhelp.html':
        require __DIR__ . '/../deca/dnhelp.html';
        break;

    case '/doc.sit':
        require __DIR__ . '/../deca/doc.sit';
        break;

    case '/docum.sit':
        require __DIR__ . '/../deca/docum.sit';
        break;

    case '/earth.sit':
        require __DIR__ . '/../deca/earth.sit';
        break;

    case '/error.sit':
        require __DIR__ . '/../deca/error.sit';
        break;

    case '/facultet.sit':
        require __DIR__ . '/../deca/facultet.sit';
        break;

    case '/find.sit':
        require __DIR__ . '/../deca/find.sit';
        break;

    case '/karta.sit':
        require __DIR__ . '/../deca/karta.sit';
        break;

    case '/listgrp.sit':
        require __DIR__ . '/../deca/listgrp.sit';
        break;

    case '/log.sit':
        require __DIR__ . '/../deca/log.sit';
        break;

    case '/login.sit':
        require __DIR__ . '/../deca/login.sit';
        break;

    case '/otchet.sit':
        require __DIR__ . '/../deca/otchet.sit';
        break;

    case '/protokol.sit':
        require __DIR__ . '/../deca/protokol.sit';
        break;

    case '/region.sit':
        require __DIR__ . '/../deca/region.sit';
        break;

    case '/school.sit':
        require __DIR__ . '/../deca/school.sit';
        break;

    case '/sgroup.sit':
        require __DIR__ . '/../deca/sgroup.sit';
        break;

    case '/student.sit':
        require __DIR__ . '/../deca/student.sit';
        break;

    case '/svodka.sit':
        require __DIR__ . '/../deca/svodka.sit';
        break;

    case '/vipiska.sit':
        require __DIR__ . '/../deca/vipiska.sit';
        break;

    case '/vvod.sit':
        require __DIR__ . '/../deca/vvod.sit';
        break;

    default:
        http_response_code(404);
        require __DIR__ . '/../deca/404.sit';
        break;

  }

?>
