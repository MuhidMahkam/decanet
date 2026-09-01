<?php

declare(strict_types=1);

namespace Decanet\Security;

use Decanet\Infrastructure\Config\AppConfig;

final class SessionManager
{
    public function __construct(private readonly AppConfig $config)
    {
    }

    public function start(): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            return;
        }

        session_name('decanet_session');
        session_set_cookie_params([
            'lifetime' => 0,
            'path' => '/',
            'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        ini_set('session.use_strict_mode', '1');
        ini_set('session.gc_maxlifetime', (string) ($this->config->sessionLifetime * 60));
        session_start();
    }
}
