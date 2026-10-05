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
use Decanet\Repository\PdoStoredProcedureRepository;
use Decanet\Security\SessionManager;
use Decanet\Security\LegacySessionDatabaseCredentials;
use Decanet\View\TemplateRenderer;

require dirname(__DIR__) . '/vendor/autoload.php';

$config = AppConfig::fromEnvironment(dirname(__DIR__));
(new ErrorHandler($config->isDebug()))->register();
(new SessionManager($config))->start();
ob_start();

$router = new Router();
$router->get('/', static function (): never {
    header('Location: /login.php', true, 302);
    exit;
});

$legacyController = new LegacyPageController(dirname(__DIR__) . '/src');
foreach (LegacyPageController::routes() as $route) {
    $router->any($route, $legacyController);
}
foreach (LegacyPageController::formRoutes() as $route) {
    $router->any($route, static fn (Request $request): string => $legacyController->formFallback($request));
}

$session =& $_SESSION;
$catalogController = new CatalogController(
    static function () use ($config, &$session): LocationRepository {
        $credentials = LegacySessionDatabaseCredentials::fromSession($session);
        $connection = new \PDO(
            sprintf(
                'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
                $config->databaseHost,
                $config->databasePort,
                $config->databaseName,
            ),
            $credentials->user,
            $credentials->password,
            [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
                \PDO::ATTR_EMULATE_PREPARES => false,
                \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
            ],
        );

        return new StoredProcedureLocationRepository(
            new PdoStoredProcedureRepository($connection, $config->databaseName),
        );
    },
    new TemplateRenderer(dirname(__DIR__) . '/templates'),
    $session,
);
foreach (CatalogController::routes() as $route) {
    $router->get($route, static function (Request $request) use ($catalogController, $legacyController): Response|string {
        if ($catalogController->handles($request)) {
            return $catalogController($request);
        }

        return $legacyController->formFallback($request);
    });
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
