<?php

declare(strict_types=1);

namespace Decanet\Application;

use Decanet\Http\Request;
use RuntimeException;

final class LegacyPageController
{
    /** @var array<string, string> */
    private const PAGES = [
        '/admin.sit' => 'admin.php', '/bask.sit' => 'bask.php', '/city.sit' => 'city.php',
        '/country.sit' => 'country.php', '/division.sit' => 'division.php', '/doc.sit' => 'doc.php',
        '/docum.sit' => 'docum.php', '/earth.sit' => 'earth.php', '/error.sit' => 'error.php',
        '/facultet.sit' => 'facultet.php', '/find.sit' => 'find.php', '/karta.sit' => 'karta.php',
        '/listgrp.sit' => 'listgrp.php', '/log.sit' => 'log.php', '/login.sit' => 'login.php',
        '/otchet.sit' => 'otchet.php', '/protokol.sit' => 'protokol.php', '/region.sit' => 'region.php',
        '/school.sit' => 'school.php', '/sgroup.sit' => 'sgroup.php', '/student.sit' => 'student.php',
        '/svodka.sit' => 'svodka.php', '/vipiska.sit' => 'vipiska.php', '/vvod.sit' => 'vvod.php',
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
                static fn (string $route): string => str_ends_with($route, '.sit')
                    ? substr($route, 0, -4) . '.php'
                    : $route,
                array_keys(self::PAGES),
            ),
        );
    }

    public function __invoke(Request $request): void
    {
        if (str_ends_with($request->path, '.php')) {
            $canonicalPath = substr($request->path, 0, -4) . '.sit';
            $query = (string) ($_SERVER['QUERY_STRING'] ?? '');
            header('Location: ' . $canonicalPath . ($query === '' ? '' : '?' . $query), true, 308);

            return;
        }

        $route = str_ends_with($request->path, '.php')
            ? substr($request->path, 0, -4) . '.sit'
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
