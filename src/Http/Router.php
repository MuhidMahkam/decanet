<?php

declare(strict_types=1);

namespace Decanet\Http;

final class Router
{
    /** @var array<string, array<string, callable(Request): mixed>> */
    private array $routes = [];

    /** @param callable(Request): mixed $handler */
    public function get(string $path, callable $handler): void
    {
        $this->add($path, ['GET'], $handler);
    }

    /** @param callable(Request): mixed $handler */
    public function any(string $path, callable $handler): void
    {
        $this->add($path, ['GET', 'POST'], $handler);
    }

    /** @param list<string> $methods */
    /** @param callable(Request): mixed $handler */
    private function add(string $path, array $methods, callable $handler): void
    {
        foreach ($methods as $method) {
            $this->routes[$path][$method] = $handler;
        }
    }

    public function dispatch(Request $request): mixed
    {
        $handler = $this->routes[$request->path][$request->method] ?? null;
        if ($handler === null) {
            http_response_code(404);
            echo 'Not found';

            return null;
        }

        return $handler($request);
    }
}
