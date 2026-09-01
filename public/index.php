<?php

declare(strict_types=1);

use Decanet\Application\LegacyPageController;
use Decanet\Http\Request;
use Decanet\Http\Router;
use Decanet\Infrastructure\Config\AppConfig;
use Decanet\Infrastructure\ErrorHandler;
use Decanet\Security\SessionManager;

require dirname(__DIR__) . '/vendor/autoload.php';

$config = AppConfig::fromEnvironment(dirname(__DIR__));
(new ErrorHandler($config->isDebug()))->register();
(new SessionManager($config))->start();

$router = new Router();
$router->get('/', static function (): never {
    header('Location: /login.sit', true, 302);
    exit;
});

$legacyController = new LegacyPageController(dirname(__DIR__) . '/src');
foreach (LegacyPageController::routes() as $route) {
    $router->any($route, $legacyController);
}

$router->dispatch(Request::fromGlobals());
