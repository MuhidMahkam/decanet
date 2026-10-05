<?php

declare(strict_types=1);

namespace Decanet\Tests\Http;

use Decanet\Http\Request;
use Decanet\Http\Router;
use PHPUnit\Framework\TestCase;

final class RouterTest extends TestCase
{
    protected function tearDown(): void
    {
        $_SERVER = [];
        $_GET = [];
        $_POST = [];
    }

    public function testItAcceptsAnInvokableController(): void
    {
        $router = new Router();
        $controller = new class {
            public bool $called = false;

            public function __invoke(Request $request): string
            {
                $this->called = $request->path === '/login.php';

                return 'handled';
            }
        };
        $router->any('/login.php', $controller);

        $_SERVER['REQUEST_METHOD'] = 'GET';
        $_SERVER['REQUEST_URI'] = '/login.php';
        self::assertSame('handled', $router->dispatch(Request::fromGlobals()));

        self::assertTrue($controller->called);
    }

    public function testItKeepsTheLegacyPostHandlerWhenACatalogGetHandlerReplacesGet(): void
    {
        $router = new Router();
        $router->any('/division.php', static fn (): string => 'legacy');
        $router->get('/division.php', static fn (): string => 'catalog');

        $_SERVER['REQUEST_METHOD'] = 'GET';
        $_SERVER['REQUEST_URI'] = '/division.php';
        self::assertSame('catalog', $router->dispatch(Request::fromGlobals()));

        $_SERVER['REQUEST_METHOD'] = 'POST';
        self::assertSame('legacy', $router->dispatch(Request::fromGlobals()));
    }
}
