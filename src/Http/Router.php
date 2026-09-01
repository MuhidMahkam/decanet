<?php

declare(strict_types=1);

namespace Decanet\Http;

use Closure;

final class Router
{
    /** @var array<string, array{methods: list<string>, handler: Closure(Request): void}> */
    private array $routes = [];

    /** @param Closure(): never $handler */
    public function get(string $path, Closure $handler): void
    {
        $this->add($path, ['GET'], $handler);
    }

    /** @param Closure(Request): void $handler */
    public function any(string $path, Closure $handler): void
    {
        $this->add($path, ['GET', 'POST'], $handler);
    }

    /** @param list<string> $methods */
    /** @param Closure(Request): void $handler */
    private function add(string $path, array $methods, Closure $handler): void
    {
        $this->routes[$path] = ['methods' => $methods, 'handler' => $handler];
    }

    public function dispatch(Request $request): void
    {
        $route = $this->routes[$request->path] ?? null;
        if ($route === null || !in_array($request->method, $route['methods'], true)) {
            http_response_code(404);
            echo 'Not found';

            return;
        }

        ($route['handler'])($request);
    }
}
