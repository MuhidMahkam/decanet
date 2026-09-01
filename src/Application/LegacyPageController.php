<?php

declare(strict_types=1);

namespace Decanet\Application;

use Decanet\Http\Request;
use RuntimeException;

final class LegacyPageController
{
    /** @var array<string, string> */
    private const PAGES = [
        '/admin.php' => 'admin.php', '/bask.php' => 'bask.php', '/city.php' => 'city.php',
        '/country.php' => 'country.php', '/division.php' => 'division.php', '/doc.php' => 'doc.php',
        '/docum.php' => 'docum.php', '/earth.php' => 'earth.php', '/error.php' => 'error.php',
        '/facultet.php' => 'facultet.php', '/find.php' => 'find.php', '/karta.php' => 'karta.php',
        '/listgrp.php' => 'listgrp.php', '/log.php' => 'log.php', '/login.php' => 'login.php',
        '/otchet.php' => 'otchet.php', '/protokol.php' => 'protokol.php', '/region.php' => 'region.php',
        '/school.php' => 'school.php', '/sgroup.php' => 'sgroup.php', '/student.php' => 'student.php',
        '/svodka.php' => 'svodka.php', '/vipiska.php' => 'vipiska.php', '/vvod.php' => 'vvod.php',
        '/dnhelp.html' => 'dnhelp.html',
    ];

    public function __construct(private readonly string $legacyDirectory)
    {
    }

    /** @return list<string> */
    public static function routes(): array
    {
        return array_merge(
            array_keys(self::PAGES),
            array_map(
                static fn (string $route): string => str_ends_with($route, '.php')
                    ? substr($route, 0, -4) . '.sit'
                    : $route,
                array_keys(self::PAGES),
            ),
        );
    }

    public function __invoke(Request $request): void
    {
        if (str_ends_with($request->path, '.sit')) {
            $canonicalPath = substr($request->path, 0, -4) . '.php';
            $query = (string) ($_SERVER['QUERY_STRING'] ?? '');
            header('Location: ' . $canonicalPath . ($query === '' ? '' : '?' . $query), true, 308);

            return;
        }

        $route = str_ends_with($request->path, '.sit')
            ? substr($request->path, 0, -4) . '.php'
            : $request->path;
        $page = self::PAGES[$route] ?? null;
        if ($page === null) {
            throw new RuntimeException('Unknown legacy route.');
        }

        $file = $this->legacyDirectory . '/' . $page;
        if (!is_file($file)) {
            throw new RuntimeException('Legacy page is missing.');
        }

        $__routedurlpage__ = $request->path;
        $_SERVER['REQUEST_URI'] = $request->path . (isset($_SERVER['QUERY_STRING']) ? '?' . $_SERVER['QUERY_STRING'] : '');

        chdir($this->legacyDirectory);
        require $file;
    }
}
