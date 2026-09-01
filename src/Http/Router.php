<?php

declare(strict_types=1);

namespace Decanet\Http;

final class Router
{
    /** @var array<string, array{methods: list<string>, handler: callable(Request): void}> */
    private array $routes = [];

    /** @param callable(Request): void $handler */
    public function get(string $path, callable $handler): void
    {
        $this->add($path, ['GET'], $handler);
    }

    /** @param callable(Request): void $handler */
    public function any(string $path, callable $handler): void
    {
        $this->add($path, ['GET', 'POST'], $handler);
    }

    /** @param list<string> $methods */
    /** @param callable(Request): void $handler */
    private function add(string $path, array $methods, callable $handler): void
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
