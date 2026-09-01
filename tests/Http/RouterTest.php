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

            public function __invoke(Request $request): void
            {
                $this->called = $request->path === '/login.php';
            }
        };
        $router->any('/login.php', $controller);

        $_SERVER['REQUEST_METHOD'] = 'GET';
        $_SERVER['REQUEST_URI'] = '/login.php';
        $router->dispatch(Request::fromGlobals());

        self::assertTrue($controller->called);
    }
}
