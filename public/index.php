<?php

declare(strict_types=1);

use Decanet\Application\LegacyPageController;
use Decanet\Application\CatalogController;
use Decanet\Http\Request;
use Decanet\Http\Response;
use Decanet\Http\Router;
use Decanet\Infrastructure\Config\AppConfig;
use Decanet\Infrastructure\ErrorHandler;
use Decanet\Repository\LocationRepository;
use Decanet\Repository\StoredProcedureLocationRepository;
use Decanet\Repository\StoredProcedureRepository;
use Decanet\Security\SessionManager;
use Decanet\View\TemplateRenderer;

require dirname(__DIR__) . '/vendor/autoload.php';

$config = AppConfig::fromEnvironment(dirname(__DIR__));
(new ErrorHandler($config->isDebug()))->register();
(new SessionManager($config))->start();

$router = new Router();
$router->get('/', static function (): never {
    header('Location: /login.php', true, 302);
    exit;
});

$session =& $_SESSION;
$catalogController = new CatalogController(
    static function () use ($config): LocationRepository {
        $connection = new \mysqli(
            $config->databaseHost,
            $config->databaseUser,
            $config->databasePassword,
            null,
            $config->databasePort,
        );
        if ($connection->connect_errno !== 0 || !$connection->set_charset('utf8')) {
            throw new \RuntimeException('Unable to connect to the catalog database.');
        }

        return new StoredProcedureLocationRepository(
            new StoredProcedureRepository($connection, $config->databaseName),
        );
    },
    new TemplateRenderer(dirname(__DIR__) . '/templates'),
    $session,
);
foreach (CatalogController::routes() as $route) {
    $router->get($route, $catalogController);
}

$legacyController = new LegacyPageController(dirname(__DIR__) . '/src');
foreach (LegacyPageController::routes() as $route) {
    $router->any($route, $legacyController);
}

$result = $router->dispatch(Request::fromGlobals());
if ($result instanceof Response) {
    http_response_code($result->status);
    foreach ($result->headers as $name => $value) {
        header($name . ': ' . $value, true);
    }
    echo $result->body;
} elseif (is_string($result)) {
    $page = $result;
    $GLOBALS['__routedurlpage__'] = Request::fromGlobals()->path;
    chdir(dirname($page));
    require $page;
}
